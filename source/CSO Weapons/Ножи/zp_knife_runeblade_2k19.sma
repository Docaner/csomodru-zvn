/*
 * Last update (5.6.2021): Added WeaponKey for automaticly identity knife
 */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>

#define is_user_valid(%1) (0 < %1 < 33)
#define IsValidEntity(%0) (pev_valid(%0) == PDATA_SAFE)
#define IsCustomItem(%1) (pev(%1, pev_impulse) == gl_iszAllocString_KnifeUID)
#define get_WeaponState(%1) (get_pdata_int(%1, m_iWeaponState, linux_diff_weapon))
#define set_WeaponState(%1,%2) (set_pdata_int(%1, m_iWeaponState, %2, linux_diff_weapon))

#define DONT_BLEED -1
#define PDATA_SAFE 2
#define ACT_RANGE_ATTACK1 28
#define DMG_GRENADE (1<<24)

#define pev_flHoldTime pev_fuser1

enum _: eKnifeState
{
	KNIFESTATE_NULL = 0,
	KNIFESTATE_SLASH1,
	KNIFESTATE_SLASH2_START,
	KNIFESTATE_SLASH2_END,

	KNIFESTATE_PRESS_ATTACK2,

	KNIFESTATE_FAIL_START,
	KNIFESTATE_FAIL_END,

	KNIFESTATE_CHARGE_IDLE,
	KNIFESTATE_CHARGE_READY,
	KNIFESTATE_CHARGE_ATTACK_START,
	KNIFESTATE_CHARGE_ATTACK_END
};

enum _: eWeaponAnim
{
	WEAPON_ANIM_IDLE = 0,
	WEAPON_ANIM_SLASH1,
	WEAPON_ANIM_DRAW,
	WEAPON_ANIM_CH_START,
	WEAPON_ANIM_CH_FINISH,
	WEAPON_ANIM_CH_IDLE1,
	WEAPON_ANIM_CH_IDLE2,
	WEAPON_ANIM_CH_ATTACK1,
	WEAPON_ANIM_CH_ATTACK2,
	WEAPON_ANIM_SLASH2
};

#define WEAPON_ANIM_IDLE_TIME 151/30.0 // +charge
#define WEAPON_ANIM_DRAW_TIME 31/30.0
#define WEAPON_ANIM_SLASH1_TIME 61/30.0
#define WEAPON_ANIM_SLASH2_TIME 81/30.0
#define WEAPON_ANIM_CH_TIME 11/30.0 // start, finish
#define WEAPON_ANIM_CH_ATTACK_TIME 60/30.0

/* ~ [ Offset's ] ~ */
// Linux extra offsets
#define linux_diff_animating 4
#define linux_diff_weapon 4
#define linux_diff_player 5

// CBaseAnimating
#define m_flFrameRate 36
#define m_flGroundSpeed 37
#define m_flLastEventCheck 38
#define m_fSequenceFinished 39
#define m_fSequenceLoops 40

// CBasePlayerItem
#define m_pPlayer 41
#define m_iId 43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flTimeWeaponIdle 48
#define m_iWeaponState 74

// CBaseMonster
#define m_Activity 73
#define m_IdealActivity 74
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_flPainShock 108
#define m_iPlayerTeam 114
#define m_flLastAttackTime 220
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_szAnimExtention 492

/* ~ [ Weapon Setting's ] ~ */
#define ADD_KNIFE_TO_EXTRA_ITEMS true
#define REMOVE_KNIFE_IF_INFECTED false

new const WEAPON_REFERENCE[] = "weapon_knife";
new const WEAPON_ANIMATION[] = "knife";
new const WEAPON_MODEL_VIEW[] = "models/x/v_runeblade_d3f3.mdl";
new const WEAPON_MODEL_PLAYER[] = "models/x/p_runeblade_d3f3.mdl";
new const WEAPON_SOUNDS[][] =
{
	// usable sounds
	"weapons/runeblade-slash1.wav", // 0
	"weapons/runeblade-slash2.wav", // 1
	"weapons/runeblade_v_charge_attack1.wav", // 2
	"weapons/runeblade_v_charge_attack2.wav", // 3
	"weapons/tomahawk_slash1_hit.wav", // 4
	"weapons/tomahawk_slash2_hit.wav", // 5
	"weapons/combatknife_wall.wav", // 6
	"weapons/laserminigun_exp2.wav", // 7
	"weapons/runeblade_draw.wav", // 8
	"weapons/runeblade_finish1.wav", // 9

	// other
	"weapons/runeblade_charge_start1.wav", // 10
	"weapons/runeblade_charge_idle1.wav" // 11
};
new const WEAPON_SPRITES[][] = 
{
	"sprites/x/runeblade_ef_d3f3.spr", // 0, hit
	"sprites/x/runeblade_ef02_d3f3.spr" // 1, charge exp
};
new Float: WEAPON_CHARS[][] =
{
	// distance, damage, knockback
	{ 125.0, 500.0, 0.0 }, // slash1 hit
	{ 125.0, 750.0, 0.0 }, // slash2 hit
	{ 125.0, 750.0, 0.0 }, // charge fail hit
	{ 125.0, 1250.0, 200.0 } // charge attack hit
};
const Float: WEAPON_CHARGE_TIME = 1.0;
const Float: WEAPON_CHARGE_EXP_RADIUS = 75.0;
#define WEAPON_CHARGE_EXP_DAMAGE random_float(600.0, 850.0)

/* ~ [ TraceLine: Attack Angles ] ~ */
new Float: flAngles_Forward[] =
{ 
	0.0, 
	2.5, -2.5, 5.0, -5.0, 7.5, -7.5, 10.0, -10.0, 12.5, -12.5, 
	15.0, -15.0, 17.5, -17.5, 20.0, -20.0, 22.5, -22.5, 25.0, -25.0
};

new gl_iszAllocString_KnifeUID;
new gl_iszModelIndex_BloodSpray,
	gl_iszModelIndex_BloodDrop,
	gl_iszModelIndex_Explode[2];

#if ADD_KNIFE_TO_EXTRA_ITEMS == true
	new gl_iItemID;
#endif

public plugin_init()
{
	register_plugin("[ZP] Knife: Blade Runebreaker", "1.1 | 2019", "xUnicorn");

	#if ADD_KNIFE_TO_EXTRA_ITEMS == true
		gl_iItemID = zp_register_extra_item("Blade Runebreaker", 0, ZP_TEAM_HUMAN);
	#endif

	register_forward(FM_UpdateClientData, 	"FM_Hook_UpdateClientData_Post", true);

	// Weapon
	RegisterHam(Ham_Weapon_WeaponIdle, 		WEAPON_REFERENCE, 	"CKnife__Idle_Pre", false);
	RegisterHam(Ham_Item_Deploy, 			WEAPON_REFERENCE, 	"CKnife__Deploy_Post", true);
	RegisterHam(Ham_Item_Holster, 			WEAPON_REFERENCE, 	"CKnife__Holster_Post", true);
	RegisterHam(Ham_Item_PostFrame, 		WEAPON_REFERENCE, 	"CKnife__PostFrame_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack, 	WEAPON_REFERENCE, 	"CKnife__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	WEAPON_REFERENCE, 	"CKnife__SecondaryAttack_Pre", false);
}

public plugin_precache()
{
	new i;

	// Models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);

	// Sound
	for(i = 0; i < sizeof WEAPON_SOUNDS; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUNDS[i]);

	// Alloc String
	gl_iszAllocString_KnifeUID = engfunc(EngFunc_AllocString, "knife_runeblade");

	// Model Index
	gl_iszModelIndex_BloodSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
	gl_iszModelIndex_BloodDrop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");

	for(i = 0; i < sizeof WEAPON_SPRITES; i++)
		gl_iszModelIndex_Explode[i] = engfunc(EngFunc_PrecacheModel, WEAPON_SPRITES[i]);
}

public plugin_natives()
{
	register_native("zp_get_user_runeblade", "_get_user_runeblade", 1);
	register_native("zp_give_user_runeblade", "_give_user_runeblade", 1);
	register_native("zp_delete_user_runeblade", "_delete_user_runeblade", 1);
}

/* ~ [ AMX Mod X ] ~ */
#if AMXX_VERSION_NUM < 183
	public client_disconnect(iPlayer) _delete_user_runeblade(iPlayer);
#else
	public client_disconnected(iPlayer) _delete_user_runeblade(iPlayer);
#endif

public _get_user_runeblade(iPlayer)
{
	static pKnife; pKnife = get_pdata_cbase(iPlayer, m_rpgPlayerItems + 3, linux_diff_player);
	return (IsValidEntity(pKnife) && IsCustomItem(pKnife)) ? true : false;
}

public _give_user_runeblade(iPlayer)
{
	static pKnife; pKnife = get_pdata_cbase(iPlayer, m_rpgPlayerItems + 3, linux_diff_player);
	if(IsValidEntity(pKnife)) set_pev(pKnife, pev_impulse, gl_iszAllocString_KnifeUID);

	static pActiveItem; pActiveItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(IsValidEntity(pActiveItem) && IsCustomItem(pActiveItem))
		ExecuteHamB(Ham_Item_Deploy, pActiveItem);
}

public _delete_user_runeblade(iPlayer)
{
	static pKnife; pKnife = get_pdata_cbase(iPlayer, m_rpgPlayerItems + 3, linux_diff_player);
	if(IsValidEntity(pKnife) && IsCustomItem(pKnife)) set_pev(pKnife, pev_impulse, 0);
}

/* ~ [ Zombie Plague ] ~ */
#if ADD_KNIFE_TO_EXTRA_ITEMS == true
	public zp_extra_item_selected(iPlayer, iItem)
	{
		if(iItem != gl_iItemID) return PLUGIN_HANDLED;
		if(_get_user_runeblade(iPlayer))
		{
			client_print(iPlayer, print_center, "*** You have already [Runeblade] ***");
			return ZP_PLUGIN_HANDLED;
		}

		_give_user_runeblade(iPlayer);
		return PLUGIN_HANDLED;
	}
#endif

#if REMOVE_KNIFE_IF_INFECTED == true
	public zp_user_infected_post(iPlayer) _delete_user_runeblade(iPlayer);
#endif

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(!is_user_alive(iPlayer) || zp_get_user_zombie(iPlayer)) return;

	new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

/* ~ [ HamSandwich ] ~ */
public CKnife__Idle_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;
	if(get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(zp_get_user_zombie(iPlayer)) return HAM_IGNORED;

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CKnife__Deploy_Post(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(zp_get_user_zombie(iPlayer)) return;

	set_pev(iPlayer, pev_viewmodel2, WEAPON_MODEL_VIEW);
	set_pev(iPlayer, pev_weaponmodel2, WEAPON_MODEL_PLAYER);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
	set_pdata_string(iPlayer, m_szAnimExtention * 4, WEAPON_ANIMATION, -1, linux_diff_player * linux_diff_animating);
}

public CKnife__Holster_Post(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(zp_get_user_zombie(iPlayer)) return;

	set_pev(iItem, pev_flHoldTime, 0.0);
	set_WeaponState(iItem, KNIFESTATE_NULL);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CKnife__PostFrame_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(zp_get_user_zombie(iPlayer)) return HAM_IGNORED;

	new szAnimation[64];
	new iButton = pev(iPlayer, pev_button);
	new Float: flNextAttackTime, Float: flIdleTime, iKnifeState = -1;
	new Float: flHoldTime; pev(iItem, pev_flHoldTime, flHoldTime);
	switch(get_WeaponState(iItem))
	{
		case KNIFESTATE_NULL: return HAM_IGNORED;

		// HOOK IN_ATTACK2
		case KNIFESTATE_PRESS_ATTACK2:
		{
			if(iButton & IN_ATTACK2)
			{
				iKnifeState = KNIFESTATE_CHARGE_IDLE;
				flNextAttackTime = WEAPON_ANIM_CH_TIME;
				flIdleTime = WEAPON_ANIM_CH_TIME;

				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CH_START);
			}

			if(!(iButton & IN_ATTACK2))
			{
				iKnifeState = KNIFESTATE_SLASH2_START;
				flNextAttackTime = 0.01;
			}
		}

		// SLASH1
		case KNIFESTATE_SLASH1:
		{
			iKnifeState = KNIFESTATE_NULL;
			flNextAttackTime = 0.7;

			UTIL_FakeTraceLine(iPlayer, WEAPON_CHARS[0][0], WEAPON_CHARS[0][1], WEAPON_CHARS[0][2], flAngles_Forward, sizeof flAngles_Forward);
		}

		// SLASH2
		case KNIFESTATE_SLASH2_START:
		{
			iKnifeState = KNIFESTATE_SLASH2_END;
			flNextAttackTime = 34/30.0 - 16/30.0;

			formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIMATION);
			UTIL_PlayerAnimation(iPlayer, szAnimation);
			emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUNDS[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		case KNIFESTATE_SLASH2_END:
		{
			iKnifeState = KNIFESTATE_NULL;
			flNextAttackTime = 0.7;

			UTIL_FakeTraceLine(iPlayer, WEAPON_CHARS[1][0], WEAPON_CHARS[1][1], WEAPON_CHARS[1][2], flAngles_Forward, sizeof flAngles_Forward);
		}

		// FAIL CHARGE
		case KNIFESTATE_FAIL_START:
		{
			iKnifeState = KNIFESTATE_FAIL_END;
			flNextAttackTime = 11/30.0;
			flIdleTime = WEAPON_ANIM_CH_ATTACK_TIME;

			formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIMATION);
			UTIL_PlayerAnimation(iPlayer, szAnimation);
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CH_ATTACK1);
			emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUNDS[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		case KNIFESTATE_FAIL_END:
		{
			iKnifeState = KNIFESTATE_NULL;
			flNextAttackTime = 0.7;

			UTIL_FakeTraceLine(iPlayer, WEAPON_CHARS[2][0], WEAPON_CHARS[2][1], WEAPON_CHARS[2][2], flAngles_Forward, sizeof flAngles_Forward);
		}

		// ATTACK CHARGE
		case KNIFESTATE_CHARGE_ATTACK_START:
		{
			iKnifeState = KNIFESTATE_CHARGE_ATTACK_END;
			flNextAttackTime = 16/30.0;
			flIdleTime = WEAPON_ANIM_CH_ATTACK_TIME;

			formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIMATION);
			UTIL_PlayerAnimation(iPlayer, szAnimation);
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CH_ATTACK2);
			emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUNDS[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		case KNIFESTATE_CHARGE_ATTACK_END:
		{
			iKnifeState = KNIFESTATE_NULL;
			flNextAttackTime = 0.7;

			new Float: vecEndPos[3]; get_point_before_player(iPlayer, 35.0, vecEndPos);
			UTIL_CreateExplosion(vecEndPos, gl_iszModelIndex_Explode[0], 12, 48);
			emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUNDS[7], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			UTIL_FakeTraceLine(iPlayer, WEAPON_CHARS[3][0], WEAPON_CHARS[3][1], WEAPON_CHARS[3][2], flAngles_Forward, sizeof flAngles_Forward);
		
			new iVictim = FM_NULLENT;
			new Float: flDamage = WEAPON_CHARGE_EXP_DAMAGE;
			while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecEndPos, WEAPON_CHARGE_EXP_RADIUS)) > 0)
			{
				if(!is_user_alive(iVictim)) continue;
				if(iVictim == iPlayer) continue;
				if(!zp_get_user_zombie(iVictim)) continue;

				if(is_user_alive(iVictim))
					set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);

				ExecuteHamB(Ham_TakeDamage, iVictim, iPlayer, iPlayer, flDamage, DMG_GRENADE);
			}
		}

		// CHARGE STATE
		case KNIFESTATE_CHARGE_IDLE:
		{
			if(iButton & IN_ATTACK2)
			{
				if(pev(iPlayer, pev_weaponanim) != WEAPON_ANIM_CH_IDLE1)
					UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CH_IDLE1);

				flNextAttackTime = 0.1;
				flIdleTime = WEAPON_ANIM_IDLE_TIME;

				if(flHoldTime >= WEAPON_CHARGE_TIME)
				{
					iKnifeState = KNIFESTATE_CHARGE_READY;
					flIdleTime = WEAPON_ANIM_CH_TIME;

					UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CH_FINISH);
				}
				else 
				{
					iKnifeState = KNIFESTATE_CHARGE_IDLE;

					set_pev(iItem, pev_flHoldTime, flHoldTime + 0.1);
				}
			}
			
			if(!(iButton & IN_ATTACK2))
			{
				iKnifeState = KNIFESTATE_FAIL_START;
				flNextAttackTime = 0.01;
			}
		}
		case KNIFESTATE_CHARGE_READY:
		{
			if(iButton & IN_ATTACK2)
			{
				if(pev(iPlayer, pev_weaponanim) != WEAPON_ANIM_CH_IDLE2)
					UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CH_IDLE2);

				iKnifeState = KNIFESTATE_CHARGE_READY;
				flNextAttackTime = 0.1;
				flIdleTime = WEAPON_ANIM_IDLE_TIME;
			}

			if(!(iButton & IN_ATTACK2))
			{
				iKnifeState = KNIFESTATE_CHARGE_ATTACK_START;
				flNextAttackTime = 0.01;
			}
		}
	}

	if(iKnifeState != -1) set_WeaponState(iItem, iKnifeState);
	if(flNextAttackTime > 0.0)
	{
		set_pdata_float(iPlayer, m_flNextAttack, flNextAttackTime, linux_diff_player);
		set_pdata_float(iItem, m_flNextPrimaryAttack, flNextAttackTime, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, flNextAttackTime, linux_diff_weapon);
	}
	if(flIdleTime > 0.0) set_pdata_float(iItem, m_flTimeWeaponIdle, flIdleTime, linux_diff_weapon);

	return HAM_IGNORED;
}

public CKnife__PrimaryAttack_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(zp_get_user_zombie(iPlayer)) return HAM_IGNORED;

	set_WeaponState(iItem, KNIFESTATE_SLASH1);
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SLASH1);
	emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	// Player animation
	static szAnimation[64];
	formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIMATION);
	UTIL_PlayerAnimation(iPlayer, szAnimation);

	set_pdata_float(iPlayer, m_flNextAttack, 9/30.0, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SLASH1_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CKnife__SecondaryAttack_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(zp_get_user_zombie(iPlayer)) return HAM_IGNORED;
	if(get_WeaponState(iItem) != KNIFESTATE_NULL) return HAM_SUPERCEDE;

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SLASH2);

	set_pev(iItem, pev_flHoldTime, 0.0);
	set_WeaponState(iItem, KNIFESTATE_PRESS_ATTACK2);
	set_pdata_float(iPlayer, m_flNextAttack, 16/30.0, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SLASH2_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

/* ~ [ Stock's ] ~ */
stock UTIL_SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_PlayerAnimation(iPlayer, szAnim[], Float: flFrame = 1.0)
{
	new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
		
	if((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
		iAnimDesired = 0;
	
	new Float: flGameTime = get_gametime();

	set_entity_anim(iPlayer, iAnimDesired, flFrame);
	
	set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, linux_diff_animating);
	set_pdata_int(iPlayer, m_fSequenceFinished, 0, linux_diff_animating);
	
	set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, linux_diff_animating);
	set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, linux_diff_animating);
	set_pdata_float(iPlayer, m_flLastEventCheck, flGameTime , linux_diff_animating);
	
	set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_float(iPlayer, m_flLastAttackTime, flGameTime , linux_diff_player);
}

stock set_entity_anim(iEntity, iSequence, Float: flFrame)
{
	set_pev(iEntity, pev_frame, flFrame);
	set_pev(iEntity, pev_framerate, 1.0);
	set_pev(iEntity, pev_animtime, get_gametime());
	set_pev(iEntity, pev_sequence, iSequence);
}

stock get_point_before_player(iPlayer, Float: flForward, Float: vecEndPos[3])
{
	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);

	vecEndPos[0] += vecOrigin[0] + vecViewOfs[0] + vecForward[0] * flForward;
	vecEndPos[1] += vecOrigin[1] + vecViewOfs[1] + vecForward[1] * flForward;
	vecEndPos[2] += vecOrigin[2] + vecViewOfs[2] + vecForward[2] * flForward;

	return 1;
}

stock UTIL_FakeTraceLine(iPlayer, Float: flDistance, Float: flDamage, Float: flKnockBack, Float: flSendAngles[], iSendAngles)
{
	enum
	{
		SLASH_HIT_NONE = 0,
		SLASH_HIT_WORLD,
		SLASH_HIT_ENTITY
	};

	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);

	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);

	new Float: vecForward[3], Float: vecRight[3], Float: vecUp[3];
	engfunc(EngFunc_AngleVectors, vecAngles, vecForward, vecRight, vecUp);
		
	new iTrace = create_tr2();

	new Float: flTan, Float: flMul;
	new iHitList[10], iHitCount = 0;

	new bool: bSpriteCreated = false;
	new Float: vecEnd[3];
	new Float: flFraction;
	new pHit, pHitEntity = SLASH_HIT_NONE;
	new iHitResult = SLASH_HIT_NONE;

	for(new i; i < iSendAngles; i++)
	{
		flTan = floattan(flSendAngles[i], degrees);

		vecEnd[0] = (vecForward[0] * flDistance) + (vecRight[0] * flTan * flDistance) + vecUp[0];
		vecEnd[1] = (vecForward[1] * flDistance) + (vecRight[1] * flTan * flDistance) + vecUp[1];
		vecEnd[2] = (vecForward[2] * flDistance) + (vecRight[2] * flTan * flDistance) + vecUp[2];
			
		flMul = (flDistance/vector_length(vecEnd));
		xs_vec_mul_scalar(vecEnd, flMul, vecEnd);
		xs_vec_add(vecEnd, vecOrigin, vecEnd);

		engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
		get_tr2(iTrace, TR_flFraction, flFraction);

		if(flFraction == 1.0)
		{
			engfunc(EngFunc_TraceHull, vecOrigin, vecEnd, HULL_HEAD, iPlayer, iTrace);
			get_tr2(iTrace, TR_flFraction, flFraction);
		
			engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
			pHit = get_tr2(iTrace, TR_pHit);
		}
		else pHit = get_tr2(iTrace, TR_pHit);

		if(pHit == iPlayer) continue;

		static bool: bStop; bStop = false;
		for(new iHit = 0; iHit < iHitCount; iHit++)
		{
			if(iHitList[iHit] == pHit)
			{
				bStop = true;
				break;
			}
		}
		if(bStop == true) continue;

		iHitList[iHitCount] = pHit;
		iHitCount++;

		if(flFraction != 1.0)
			if(!iHitResult) iHitResult = SLASH_HIT_WORLD;

		static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);
		if(pHit > 0 && pHitEntity != pHit)
		{
			if(pev(pHit, pev_solid) == SOLID_BSP && !(pev(pHit, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
			{
				ExecuteHamB(Ham_TakeDamage, pHit, iPlayer, iPlayer, flDamage, DMG_NEVERGIB|DMG_CLUB);
			}
			else
			{
				UTIL_FakeTraceAttack(pHit, iPlayer, flDamage, vecForward, iTrace, DMG_NEVERGIB|DMG_CLUB);
				if(flKnockBack > 0.0) UTIL_FakeKnockBack(pHit, vecForward, flKnockBack);
			}

			iHitResult = SLASH_HIT_ENTITY;
			pHitEntity = pHit;

			UTIL_CreateExplosion(vecEndPos, gl_iszModelIndex_Explode[1], 3, 64);
		}

		switch(iHitResult)
		{
			case SLASH_HIT_WORLD:
			{
				if(!bSpriteCreated && i == 0)
				{
					UTIL_CreateExplosion(vecEndPos, gl_iszModelIndex_Explode[1], 3, 64);
					bSpriteCreated = true;
				}
			}
		}
	}

	free_tr2(iTrace);

	static iSound; iSound = -1;
	switch(iHitResult)
	{
		case SLASH_HIT_WORLD: iSound = 6;
		case SLASH_HIT_ENTITY: iSound = random_num(4, 5);
	}

	if(iSound != -1)
		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[iSound], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

stock UTIL_FakeTraceAttack(iVictim, iAttacker, Float: flDamage, Float: vecDirection[3], iTrace, ibitsDamageBits)
{
	static Float: flTakeDamage; pev(iVictim, pev_takedamage, flTakeDamage);

	if(flTakeDamage == DAMAGE_NO) return 0; 
	if(!(is_user_alive(iVictim))) return 0;

	if(is_user_connected(iVictim)) 
	{
		if(get_pdata_int(iVictim, m_iPlayerTeam, linux_diff_player) == get_pdata_int(iAttacker, m_iPlayerTeam, linux_diff_player)) 
			return 0;
	}

	static iHitgroup; iHitgroup = get_tr2(iTrace, TR_iHitgroup);
	static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	static iBloodColor; iBloodColor = ExecuteHamB(Ham_BloodColor, iVictim);
	
	if(is_user_alive(iVictim))
		set_pdata_int(iVictim, m_LastHitGroup, iHitgroup, linux_diff_player);

	switch(iHitgroup) 
	{
		case HIT_HEAD:                  flDamage *= 3.0;
		case HIT_LEFTARM, HIT_RIGHTARM: flDamage *= 0.75;
		case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 0.75;
		case HIT_STOMACH:               flDamage *= 1.5;
	}
	
	ExecuteHamB(Ham_TakeDamage, iVictim, iAttacker, iAttacker, flDamage, ibitsDamageBits);

	if(zp_get_user_zombie(iVictim)) 
	{
		if(iBloodColor != DONT_BLEED) 
		{
			ExecuteHamB(Ham_TraceBleed, iVictim, flDamage, vecDirection, iTrace, ibitsDamageBits);
			UTIL_BloodDrips(vecEndPos, iBloodColor, floatround(flDamage));
		}
	}

	return 1;
}

stock UTIL_FakeKnockBack(iVictim, Float: vecDirection[3], Float: flKnockBack) 
{
	if(!(is_user_alive(iVictim))) return 0;
	if(!zp_get_user_zombie(iVictim)) return 0;

	set_pdata_float(iVictim, m_flPainShock, 1.0, linux_diff_player);

	static Float: vecVelocity[3]; pev(iVictim, pev_velocity, vecVelocity);
	if(pev(iVictim, pev_flags) & FL_DUCKING) flKnockBack *= 0.7;

	vecVelocity[0] = vecDirection[0] * flKnockBack;
	vecVelocity[1] = vecDirection[1] * flKnockBack;
	vecVelocity[2] = 200.0;

	set_pev(iVictim, pev_velocity, vecVelocity);
	
	return 1;
}

public UTIL_BloodDrips(Float: vecOrigin[3], iColor, iAmount)
{
	if(iAmount > 255) iAmount = 255;
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(gl_iszModelIndex_BloodSpray);
	write_short(gl_iszModelIndex_BloodDrop);
	write_byte(iColor);
	write_byte(min(max(3, iAmount / 10), 16));
	message_end();
}

stock UTIL_CreateExplosion(Float: vecEndPos[3], iszModelIndex, iScale, iFramerate)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecEndPos[0]);
	engfunc(EngFunc_WriteCoord, vecEndPos[1]);
	engfunc(EngFunc_WriteCoord, vecEndPos[2]);
	write_short(iszModelIndex);
	write_byte(iScale); // Scale
	write_byte(iFramerate); // Framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES);
	message_end();
}
