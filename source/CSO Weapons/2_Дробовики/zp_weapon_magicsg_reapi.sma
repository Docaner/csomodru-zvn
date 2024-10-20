#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <xs>
#include <reapi>
#include <zpe_knokcback>

#define IsValidEntity(%0) 				(!is_nullent(%0))
#define IsCustomItem(%0) 				(get_entvar(%0, var_impulse) == WEAPON_SPECIAL_CODE)

#define m_Weapon_iChargedAmmo			m_Weapon_iGlock18ShotsFired // CWeapon

#define var_charged_level				var_weaponanim // CEntity
#define var_star_color					var_chain // CEntity
#define var_muzzleloop					var_weaponanim // CSprite
#define var_flNextthink					var_teleport_time // CSprite
#define var_flHoldTime					var_teleport_time // CWeapon

stock bool: IsValidVictim(const pVictim, const pAttacker, pEntity = NULLENT)
{
	if(!IsValidEntity(pEntity)) pEntity = pAttacker;

	if(get_entvar(pVictim, var_takedamage) == DAMAGE_NO) return false;
	if(is_user_alive(pVictim) && (pVictim == pAttacker || get_member(pVictim, m_iTeam) == get_member(pAttacker, m_iTeam) || !zp_get_user_zombie(pVictim)))
		return false;
	else if(get_entvar(pVictim, var_solid) == SOLID_BSP && get_entvar(pVictim, var_spawnflags) & SF_BREAK_TRIGGER_ONLY)
		return false;

	return true;
}

enum
{
	WPNSTATE_NONE = 0,
	WPNSTATE_FAIL_CHARGE,
	WPNSTATE_START_CHARGE,
	WPNSTATE_IN_CHARGE
};

/* ~ [ Extra Item ] ~ */
new const EXTRA_ITEM_NAME[ ] = 			"Starlight Rolling";
const EXTRA_ITEM_COST = 				0;

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 			101/30.0
#define WEAPON_ANIM_CHARGE_TIME			41/30.0
#define WEAPON_ANIM_SHOOT_TIME 			31/30.0
#define WEAPON_ANIM_RELOAD_TIME 		121/30.0
#define WEAPON_ANIM_DRAW_TIME 			31/30.0

#define WEAPON_ANIM_IDLE 				0
#define WEAPON_ANIM_CHARGE				1
#define WEAPON_ANIM_SHOOT 				2
#define WEAPON_ANIM_RELOAD 				4
#define WEAPON_ANIM_DRAW 				5

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = 			"weapon_xm1014";
new const WEAPON_WEAPONLIST[] = 		"x/weapon_magicsg";
new const WEAPON_NATIVE[] = 			"zp_give_user_magicsg";
new const WEAPON_MODEL_VIEW[] = 		"models/x/v_magicsg.mdl";
new const WEAPON_MODEL_PLAYER[] = 		"models/x/p_magicsg.mdl";
new const WEAPON_MODEL_WORLD[] = 		"models/x/w_magicsg.mdl";
new const WEAPON_SOUND_FIRE[][] =
{
	"weapons/magicsg_shoot1.wav",
	"weapons/magicsg_shoot2.wav"
};
new const WEAPON_SOUND_CHARGE[][] = 
{
	"weapons/magicsg_idle_charge1.wav",
	"weapons/magicsg_idle_charge2.wav",
	"weapons/magicsg_idle_charge3.wav",
	"weapons/magicsg_idle_charge4.wav",
	"weapons/magicsg_idle_charge5.wav",

	"weapons/magicsg_idle_charge_loop.wav"
};

const WEAPON_SPECIAL_CODE = 			8032020;
const WEAPON_BODY = 					0;

const WEAPON_MAX_CLIP = 				10;
const WEAPON_DEFAULT_AMMO = 			80;
const Float: WEAPON_RATE = 				0.3;
const Float: WEAPON_PUNCHANGLE = 		0.892;
const Float: WEAPON_DAMAGE = 			1.42;

new const ENTITY_STAR_CLASSNAME[] =		"ent_starx";
new const ENTITY_STAR_SPRITE[] = 		"sprites/x/ef_magicsg_star.spr";
const Float: ENTITY_STAR_RADIUS =		75.0;
new const Float: ENTITY_STAR_DAMAGE[] =
{
	190.0, 200.0, 210.0, 225.0, 320.0
};
const ENTITY_STAR_DMGTYPE =				DMG_CLUB;
new const Float: ENTITY_STAR_SPEED[] =
{
	500.0, 600.0, 750.0, 900.0, 1100.0
};
new const Float: ENTITY_STAR_COLOR[][] = 
{
	// NB! Don't delete this. U can only modify this.
	// More colors: https://htmlcolorcodes.com/
	{ 0.0, 128.0, 255.0 }, // 0. Blue
	{ 255.0, 0.0, 0.0 }, // 1. Red
	{ 0.0, 255.0, 0.0 }, // 2. Green
	{ 255.0, 255.0, 0.0 }, // 3. Yellow
	{ 255.0, 0.0, 255.0 } // 4. Purple
};
new const ENTITY_STAR_SOUND[] =			"weapons/magicsg_shoot2_exp.wav";
new const ENTITY_STAR_EXP_SPRITES[][] =
{
	"sprites/x/ef_magicsg_hit_blue.spr", // 0. Blue
	"sprites/x/ef_magicsg_hit_red.spr", // 1. Red
	"sprites/x/ef_magicsg_hit_green.spr", // 2. Green
	"sprites/x/ef_magicsg_hit_yellow.spr", // 3. Yellow
	"sprites/x/ef_magicsg_hit_fink.spr" // 4. Purple
}

/* ~ [ Muzzle Flash ] ~ */
const ENTITY_SPRITES_INTOLERANCE = 		100;
new const ENTITY_MUZZLE_CLASSNAME[] = 	"mf_magicsgx";
new const ENTITY_MUZZLE_SPRITES[][] =
{
	"sprites/x/muzzleflash107.spr",
	"sprites/x/muzzleflash108.spr"
};

/* ~ [ Params ] ~ */
new gl_iItemId;

new gl_iszModelIndex_Explosion[sizeof ENTITY_STAR_EXP_SPRITES],
	gl_iszModelIndex_BloodDrop,
	gl_iszModelIndex_BloodSpray;

new HamHook: gl_HamHook_TraceAttack[4];

new gl_iMsgID_Weaponlist,
	gl_iMsgID_StatusIcon;

public plugin_init()
{
	register_plugin("[ZP] Weapon: Starlight Rolling Shooter", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	// Forwards
	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	
	// Reapi
	RegisterHookChain(RG_CWeaponBox_SetModel, "CWeaponBox_SetModel_Pre", false);

	// Weapon
	RegisterHam(Ham_Item_Holster,			WEAPON_REFERENCE,	"CWeapon__Holster_Post", true);
	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);

	// Trace Attack
	gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,	"func_breakable",	"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",		"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",			"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",	"CEntity__TraceAttack_Pre", false);
	
	ToggleTraceAttack(false);

	// Messages
	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	gl_iMsgID_StatusIcon = get_user_msgid("StatusIcon");

	/* -> Register on Extra-Items -> */
	gl_iItemId = zp_register_extra_item( EXTRA_ITEM_NAME, EXTRA_ITEM_COST, ZP_TEAM_HUMAN )
}

public plugin_precache()
{
	new i;

	// Hook weapon
	//register_clcmd("say m", "Command_GiveWeapon");
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

	engfunc(EngFunc_PrecacheModel, ENTITY_STAR_SPRITE);

	for(i = 0; i < sizeof ENTITY_MUZZLE_SPRITES; i++)
		engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITES[i]);
	

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	
	// Precache sounds
	for(i = 0; i < sizeof WEAPON_SOUND_FIRE; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_FIRE[i]);

	for(i = 0; i < sizeof WEAPON_SOUND_CHARGE; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_CHARGE[i]);

	engfunc(EngFunc_PrecacheSound, "common/null.wav");
	engfunc(EngFunc_PrecacheSound, ENTITY_STAR_SOUND);

	UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW);

	// Model Index
	for(i = 0; i < sizeof ENTITY_STAR_EXP_SPRITES; i++)
		gl_iszModelIndex_Explosion[i] = engfunc(EngFunc_PrecacheModel, ENTITY_STAR_EXP_SPRITES[i]);

	gl_iszModelIndex_BloodDrop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");
	gl_iszModelIndex_BloodSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
}

public plugin_cfg()
{
	static iMaxSpeed; iMaxSpeed = floatround(ENTITY_STAR_SPEED[sizeof ENTITY_STAR_SPEED-1]);
	if(get_cvar_num("sv_maxvelocity") <= iMaxSpeed)
		set_cvar_num("sv_maxvelocity", iMaxSpeed);
}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

/* ~ [ Zombie Core ] ~ */
public zp_extra_item_selected( pPlayer, iItemId ) 
{
	if ( iItemId != gl_iItemId ) 
		return PLUGIN_HANDLED;

	return Command_GiveWeapon(pPlayer);
}

// [ Amxx ]
public Command_HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

public Command_GiveWeapon(const pPlayer)
{
	new pItem = rg_give_custom_item(pPlayer, WEAPON_REFERENCE, GT_DROP_AND_REPLACE, WEAPON_SPECIAL_CODE);
	if(!IsValidEntity(pItem)) return NULLENT;

	set_member(pPlayer, m_rgAmmo, WEAPON_DEFAULT_AMMO, get_member(pItem, m_Weapon_iPrimaryAmmoType));
	rg_set_iteminfo(pItem, ItemInfo_pszName, WEAPON_WEAPONLIST);
	rg_set_iteminfo(pItem, ItemInfo_iMaxClip, WEAPON_MAX_CLIP);
	set_member(pItem, m_Weapon_iClip, WEAPON_MAX_CLIP);

	UTIL_WeaponList(pPlayer, pItem);

	return pItem;
}

// [ Fakemeta ]
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(!is_user_alive(iPlayer)) return;

	static iItem; iItem = get_member(iPlayer, m_pActiveItem);
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

/* ~ [ ReAPI ] ~ */
public CWeaponBox_SetModel_Pre(const pWeaponBox)
{
	new pItem = UTIL_GetWeaponBoxItem(pWeaponBox);
	if(is_nullent(pItem) || !IsCustomItem(pItem)) return HC_CONTINUE;

	SetHookChainArg(2, ATYPE_STRING, WEAPON_MODEL_WORLD);
	set_entvar(pItem, var_body, WEAPON_BODY);

	return HC_CONTINUE;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;
public FM_Hook_TraceLine_Post(const Float: vecStart[3], const Float: vecEnd[3], iFlags, iAttacker, iTrace)
{
	if(iFlags & IGNORE_MONSTERS) return FMRES_IGNORED;
	if(!is_user_alive(iAttacker)) return FMRES_IGNORED;

	static pHit; pHit = get_tr2(iTrace, TR_pHit);
	static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	static Float: vecEndNew[3], Float: vecVector[3];

	xs_vec_sub(vecStart, vecEndPos, vecVector);
	xs_vec_normalize(vecVector, vecVector);
	xs_vec_mul_scalar(vecVector, -20.0, vecVector);
	xs_vec_sub(vecEndPos, vecVector, vecEndNew);

	CWeapon__Create_StarDecal(vecEndNew);

	if(pHit > 0) if(get_entvar(pHit, var_solid) != SOLID_BSP) return FMRES_IGNORED;

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
	write_byte(TE_GUNSHOTDECAL);
	engfunc(EngFunc_WriteCoord, vecEndPos[0]);
	engfunc(EngFunc_WriteCoord, vecEndPos[1]);
	engfunc(EngFunc_WriteCoord, vecEndPos[2]);
	write_short(pHit > 0 ? pHit : 0);
	write_byte(random_num(41, 45));
	message_end();

	return FMRES_IGNORED;
}

// [ HamSandwich ]
public CWeapon__Holster_Post(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;
	static iPlayer; iPlayer = get_member(iItem, m_pPlayer);

	CPlayer__Remove_MuzzleFlash(iPlayer);
	UTIL_StatusIcon(iItem, iPlayer, 0);
	set_entvar(iItem, var_flHoldTime, 0.0);

	set_member(iItem, m_Weapon_iWeaponState, WPNSTATE_NONE);
	set_member(iItem, m_Weapon_iChargedAmmo, 0);

	set_member(iItem, m_Weapon_flNextReload, 0.0);
	set_member(iItem, m_Weapon_flNextPrimaryAttack, 0.0);
	set_member(iItem, m_Weapon_flNextSecondaryAttack, 0.0);
	set_member(iItem, m_Weapon_flTimeWeaponIdle, 0.0);
	set_member(iPlayer, m_flNextAttack, 0.0);
}

public CWeapon__Deploy_Post(iItem)
{
	if(!IsCustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_member(iItem, m_pPlayer);

	set_entvar(iPlayer, var_viewmodel, WEAPON_MODEL_VIEW);
	set_entvar(iPlayer, var_weaponmodel, WEAPON_MODEL_PLAYER);

	UTIL_StatusIcon(iItem, iPlayer, 0);
	UTIL_StatusIcon(iItem, iPlayer, 1);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

	set_member(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME);
	set_member(iItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	// Reload
	static iClip; iClip = get_member(iItem, m_Weapon_iClip);
	static iPlayer; iPlayer = get_member(iItem, m_pPlayer);
	if(get_member(iItem, m_Weapon_fInReload) == 1)
	{
		new iPrimaryAmmoType = get_member(iItem, m_Weapon_iPrimaryAmmoType);
		new iAmmo = get_member(iPlayer, m_rgAmmo, iPrimaryAmmoType);
		new j = min(WEAPON_MAX_CLIP - iClip, iAmmo)
		set_member(iItem, m_Weapon_iClip, iClip + j);
		set_member(iItem, m_Weapon_fInReload, false);
		set_member(iPlayer, m_rgAmmo, iAmmo - j, iPrimaryAmmoType);
	}

	// Hook Secondary Attack
	static iButton, iWeaponState, iChargedAmmo;
	new Float: flNextAttackTime, Float: flIdleTime, Float: flHoldTime;

	get_entvar(iItem, var_flHoldTime, flHoldTime);
	iButton = get_entvar(iPlayer, var_button);
	iWeaponState = get_member(iItem, m_Weapon_iWeaponState);
	iChargedAmmo = get_member(iItem, m_Weapon_iChargedAmmo);

	switch(iWeaponState)
	{
		case WPNSTATE_NONE:
		{
			if(iButton & IN_ATTACK2 && iClip)
			{
				flNextAttackTime = 0.01;

				UTIL_CreateMuzzleFlash(iPlayer, ENTITY_MUZZLE_SPRITES[1], 1, 0.04, 0.07, 255.0, 1);
				set_member(iItem, m_Weapon_iWeaponState, WPNSTATE_START_CHARGE);
			}
		}
		case WPNSTATE_START_CHARGE:
		{
			if(iButton & IN_ATTACK2)
			{
				CWeapon__Create_LoopSound(iPlayer, iItem);

				flHoldTime += 0.1;
				flNextAttackTime = 0.1;
				flIdleTime = WEAPON_ANIM_CHARGE_TIME;

				if(flHoldTime < 1.0)
				{
					if(get_entvar(iPlayer, var_weaponanim) != WEAPON_ANIM_CHARGE)
						UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHARGE);
				}
				else
				{
					set_member(iItem, m_Weapon_iWeaponState, WPNSTATE_IN_CHARGE);
					flHoldTime = 0.0;
				}
			}
			
			if(!(iButton & IN_ATTACK2))
			{
				set_member(iItem, m_Weapon_iWeaponState, WPNSTATE_FAIL_CHARGE);
				flHoldTime = 0.0;
			}
		}
		case WPNSTATE_FAIL_CHARGE:
		{
			CPlayer__Remove_MuzzleFlash(iPlayer);

			UTIL_StatusIcon(iItem, iPlayer, 0);
			set_member(iItem, m_Weapon_iChargedAmmo, 0);
			UTIL_StatusIcon(iItem, iPlayer, 1);

			set_member(iItem, m_Weapon_iWeaponState, WPNSTATE_NONE);
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);

			flNextAttackTime = 1.0;
			flIdleTime = WEAPON_ANIM_IDLE_TIME;
		}
		case WPNSTATE_IN_CHARGE:
		{
			if(iButton & IN_ATTACK2)
			{
				CWeapon__Create_LoopSound(iPlayer, iItem);
				flIdleTime = WEAPON_ANIM_CHARGE_TIME;

				if(get_entvar(iPlayer, var_weaponanim) != WEAPON_ANIM_CHARGE)
					UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHARGE);

				if(iChargedAmmo == 5 || iClip == iChargedAmmo)
					flNextAttackTime = 0.1;
				else
				{
					emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_CHARGE[iChargedAmmo], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

					iChargedAmmo++;
					flNextAttackTime = 0.5;
				}

				UTIL_StatusIcon(iItem, iPlayer, 0);
				set_member(iItem, m_Weapon_iChargedAmmo, iChargedAmmo);
				UTIL_StatusIcon(iItem, iPlayer, 1);

				set_member(iItem, m_Weapon_iWeaponState, WPNSTATE_IN_CHARGE);
			}

			if(!(iButton & IN_ATTACK2))
			{
				CPlayer__Remove_MuzzleFlash(iPlayer);

				flNextAttackTime = flIdleTime = WEAPON_ANIM_SHOOT_TIME;
				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT + 1);
				emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

				CPlayer__Create_StarShoot(iPlayer, iChargedAmmo);

				UTIL_StatusIcon(iItem, iPlayer, 0);
				set_member(iItem, m_Weapon_iChargedAmmo, 0);
				UTIL_StatusIcon(iItem, iPlayer, 1);

				set_member(iItem, m_Weapon_iClip, iClip - iChargedAmmo);
				set_member(iItem, m_Weapon_iWeaponState, WPNSTATE_NONE);
			}
		}
	}

	if(iWeaponState != WPNSTATE_NONE) set_entvar(iItem, var_flHoldTime, flHoldTime);
	if(flNextAttackTime != 0.0)
	{
		set_member(iItem, m_Weapon_flNextPrimaryAttack, flNextAttackTime);
		set_member(iItem, m_Weapon_flNextSecondaryAttack, flNextAttackTime);
		set_member(iPlayer, m_flNextAttack, flNextAttackTime);
	}
	if(flIdleTime != 0.0) set_member(iItem, m_Weapon_flTimeWeaponIdle, flIdleTime);

	return HAM_IGNORED;
}

public CWeapon__AddToPlayer_Post(const pItem, const pPlayer)
{
	new iWeaponKey = get_entvar(pItem, var_impulse);
	if(iWeaponKey != 0 && iWeaponKey != WEAPON_SPECIAL_CODE) return;

	UTIL_WeaponList(pPlayer, pItem);
}

public CWeapon__Reload_Pre(const pItem)
{
	if(!IsCustomItem(pItem)) return HAM_IGNORED;

	new pPlayer = get_member(pItem, m_pPlayer);
	new iBpAmmo = get_member(pPlayer, m_rgAmmo, get_member(pItem, m_Weapon_iPrimaryAmmoType));
	if(!iBpAmmo) return HAM_SUPERCEDE;

	new iClip = get_member(pItem, m_Weapon_iClip);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	set_member(pItem, m_Weapon_iClip, 0);
	ExecuteHam(Ham_Weapon_Reload, pItem);
	set_member(pItem, m_Weapon_iClip, iClip);

	UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_RELOAD);

	set_member(pPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME - 1.0);
	set_member(pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME);
	set_member(pItem, m_Weapon_fInReload, true);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!IsCustomItem(iItem) || get_member(iItem, m_Weapon_flTimeWeaponIdle) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_member(iItem, m_pPlayer);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);
	set_member(iItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;
	if(get_member(iItem, m_Weapon_iClip) == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_member(iItem, m_Weapon_flNextPrimaryAttack, 0.2);

		return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_member(iItem, m_pPlayer);

	DefaultWeaponAttack(iItem);

	static Float: vecPunchangle[3];
	get_entvar(iPlayer, var_punchangle, vecPunchangle);
	vecPunchangle[0] *= WEAPON_PUNCHANGLE;
	vecPunchangle[1] *= WEAPON_PUNCHANGLE;
	vecPunchangle[2] *= WEAPON_PUNCHANGLE;
	set_entvar(iPlayer, var_punchangle, vecPunchangle);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	UTIL_CreateMuzzleFlash(iPlayer, ENTITY_MUZZLE_SPRITES[0], 0, 0.032, 0.1, 255.0, 1);

	set_member(iItem, m_Weapon_flNextPrimaryAttack, WEAPON_RATE);
	set_member(iItem, m_Weapon_flNextSecondaryAttack, WEAPON_RATE);
	set_member(iItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME);

	return HAM_SUPERCEDE;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
	if(!is_user_connected(iAttacker)) return;

	static iItem; iItem = get_member(iAttacker, m_pActiveItem);
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;

	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

public CEntity__BigStar_Touch(iEntity, iTouch)
{
	if(!IsValidEntity(iEntity)) return;

	new iOwner = get_entvar(iEntity, var_owner);
	if(iTouch == iOwner) return;
	if(FClassnameIs(iTouch, ENTITY_STAR_CLASSNAME)) return;


	/* По тимейтам не ебашит */
	if(is_user_connected(iTouch) && !zp_get_user_zombie(iTouch))
		return;

	new Float: vecOrigin[3]; get_entvar(iEntity, var_origin, vecOrigin);
	if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
	{
		set_entvar(iEntity, var_flags, FL_KILLME);
		return;
	}

	emit_sound(iEntity, CHAN_ITEM, ENTITY_STAR_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_EXPLOSION); // TE
	engfunc(EngFunc_WriteCoord, vecOrigin[0]); // Position X
	engfunc(EngFunc_WriteCoord, vecOrigin[1]); // Position Y
	engfunc(EngFunc_WriteCoord, vecOrigin[2]); // Position Z
	write_short(gl_iszModelIndex_Explosion[get_entvar(iEntity, var_star_color)]); // Model Index
	write_byte(14); // Scale
	write_byte(24); // Framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // Flags
	message_end();

	new iChargedLevel = get_entvar(iEntity, var_charged_level);
	new iLastHitGroup = iChargedLevel >= 5 ? HIT_HEAD : HIT_GENERIC;
	new Float: flDamage = ENTITY_STAR_DAMAGE[iChargedLevel-1] * random_float(0.75, 1.25);
	if(iTouch && is_user_alive(iTouch) && get_member(iTouch, m_iTeam) != get_member(iOwner, m_iTeam))
		UTIL_BloodDrips(vecOrigin, iTouch, floatround(flDamage));

	// Explode Damage
	new iVictim = FM_NULLENT;
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_STAR_RADIUS)) > 0)
	{
		if(!IsValidVictim(iVictim, iOwner)) continue;

		if(is_user_alive(iVictim))
		{
			zp_set_user_knock_by_missile(iVictim, iOwner, 300.0, 2.75);
			set_member(iVictim, m_LastHitGroup, iLastHitGroup);
		}

		ExecuteHamB(Ham_TakeDamage, iVictim, iOwner, iOwner, flDamage, ENTITY_STAR_DMGTYPE);
	}

	set_entvar(iEntity, var_flags, FL_KILLME);
}

public CEntity__BigStar_Think(iEntity)
{
	if(!IsValidEntity(iEntity)) return;

	if(get_entvar(iEntity, var_charged_level))
	{
		new Float: flGameTime = get_gametime();
		new Float: vecAngles[3]; get_entvar(iEntity, var_angles, vecAngles);

		vecAngles[1] += 15.0;
		vecAngles[2] += 15.0;

		set_entvar(iEntity, var_angles, vecAngles);
		set_entvar(iEntity, var_nextthink, flGameTime + 0.05);
	}
	else set_entvar(iEntity, var_flags, FL_KILLME);
}

public CMuzzleFlash__Think_Pre(iSprite)
{
	if(!IsValidEntity(iSprite)) return;

	new Float: flFrame; get_entvar(iSprite, var_frame, flFrame);
	new Float: flNextThink; get_entvar(iSprite, var_flNextthink, flNextThink);
	new iMuzzleLoop = get_entvar(iSprite, var_muzzleloop);

	switch(iMuzzleLoop)
	{
		case 0:
		{
			if(flFrame < 14)
			{
				flFrame++;
				set_entvar(iSprite, var_frame, flFrame);
				set_entvar(iSprite, var_nextthink, get_gametime() + flNextThink);
				
				return;
			}

			set_entvar(iSprite, var_flags, FL_KILLME);
		}
		case 1:
		{
			if(flFrame - 1.0 >= 44)
			{
				flFrame = 0.0;
				set_entvar(iSprite, var_frame, flFrame);
				set_entvar(iSprite, var_nextthink, get_gametime() + flNextThink);
			}
			else
			{
				flFrame++;
				set_entvar(iSprite, var_frame, flFrame);
				set_entvar(iSprite, var_nextthink, get_gametime() + flNextThink);
			}
		}
	}
}

// [ Other ]
public CPlayer__Remove_MuzzleFlash(iPlayer)
{
	emit_sound(iPlayer, CHAN_ITEM, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	// Remove other's muzzleflashes
	new iMuzzleFlash = FM_NULLENT;
	while((iMuzzleFlash = fm_find_ent_by_owner(iMuzzleFlash, ENTITY_MUZZLE_CLASSNAME, iPlayer)) > 0) // rg_find_ent_by_owner
		set_entvar(iMuzzleFlash, var_flags, FL_KILLME);
	
}

public CPlayer__Create_StarShoot(iPlayer, iChargedAmmo)
{
	if(!iChargedAmmo) return;

	new iCycleCount, iColor;
	new Float: flRight = -150.0, Float: flStep = flRight * -1.0;
	switch(iChargedAmmo)
	{
		case 1: { iCycleCount = 1; iColor = 2; flRight = 0.0; }
		case 2: { iCycleCount = 3; iColor = 3; }
		case 3: { iCycleCount = 3; iColor = 0; }
		case 4: { iCycleCount = 3; iColor = 4; }
		case 5: { iCycleCount = 5; iColor = -1; flRight = -300.0; flStep = flRight / -2.0; }
	}

	static Float: vecOrigin[3]; get_entvar(iPlayer, var_origin, vecOrigin);
	static Float: vecViewOfs[3]; get_entvar(iPlayer, var_view_ofs, vecViewOfs);
	static Float: vecAngles[3]; get_entvar(iPlayer, var_v_angle, vecAngles);
	static Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
	static Float: vecRight[3]; angle_vector(vecAngles, ANGLEVECTOR_RIGHT, vecRight);
	static Float: vecVelocity[3]; xs_vec_copy(vecForward, vecVelocity);

	// Start Origin
	vecOrigin[0] += vecViewOfs[0] + vecForward[0] * 20.0;
	vecOrigin[1] += vecViewOfs[1] + vecForward[1] * 20.0;
	vecOrigin[2] += vecViewOfs[2] + vecForward[2] * 20.0;

	for(new i = 0; i < iCycleCount; i++)
	{
		if(iCycleCount == 5) iColor = i;

		xs_vec_mul_scalar(vecForward, ENTITY_STAR_SPEED[iChargedAmmo-1], vecVelocity);

		vecVelocity[0] += vecRight[0] * flRight;
		vecVelocity[1] += vecRight[1] * flRight;
		vecVelocity[2] += vecRight[2] * flRight;
		flRight += flStep;

		CWeapon__Create_StarShoot(iPlayer, iChargedAmmo, iColor, vecOrigin, vecVelocity);
	}
}

public CWeapon__Create_LoopSound(iPlayer, iItem)
{
	if(get_member(iItem, m_Weapon_flNextReload) <= get_gametime())
	{
		emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUND_CHARGE[5], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_member(iItem, m_Weapon_flNextReload, get_gametime() + 1.5);
	}
}

public CWeapon__Create_StarShoot(iPlayer, iChargedLevel, iColor, Float: vecOrigin[3], Float: vecVelocity[3])
{
	new iEntity = rg_create_entity("info_target");
	if(!IsValidEntity(iEntity)) return FM_NULLENT;

	set_entvar(iEntity, var_classname, ENTITY_STAR_CLASSNAME);
	set_entvar(iEntity, var_solid, SOLID_TRIGGER);
	set_entvar(iEntity, var_movetype, MOVETYPE_FLY);
	set_entvar(iEntity, var_owner, iPlayer);
	set_entvar(iEntity, var_velocity, vecVelocity);
	set_entvar(iEntity, var_nextthink, get_gametime() + 0.1);
	set_entvar(iEntity, var_scale, 0.2);
	set_entvar(iEntity, var_charged_level, iChargedLevel);
	set_entvar(iEntity, var_star_color, iColor);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_STAR_SPRITE);
	engfunc(EngFunc_SetSize, iEntity, {-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0});
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	static Float: flColor[3]; xs_vec_copy(ENTITY_STAR_COLOR[iColor], flColor);
	Sprite_SetTransparency(iEntity, kRenderTransAdd, flColor, 255.0);

	SetTouch(iEntity, "CEntity__BigStar_Touch");
	SetThink(iEntity, "CEntity__BigStar_Think");

	return iEntity;
}

public CWeapon__Create_StarDecal(Float: vecOrigin[3])
{
	new iEntity = rg_create_entity("info_target");
	if(!iEntity) return FM_NULLENT;

	new Float: vecVelocity[3];
	vecVelocity[0] = random_float(-150.0, 150.0);
	vecVelocity[1] = random_float(-150.0, 150.0);
	vecVelocity[2] = random_float(-150.0, 150.0) + random_float(25.0, 100.0);

	set_entvar(iEntity, var_classname, ENTITY_STAR_CLASSNAME);
	set_entvar(iEntity, var_solid, SOLID_NOT);
	set_entvar(iEntity, var_movetype, MOVETYPE_PUSHSTEP);
	set_entvar(iEntity, var_velocity, vecVelocity);
	set_entvar(iEntity, var_nextthink, get_gametime() + 1.5);
	set_entvar(iEntity, var_scale, 0.05);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_STAR_SPRITE);
	engfunc(EngFunc_SetSize, iEntity, {-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0});
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	static Float: flColor[3];
	flColor[0] = random_float(0.0, 255.0);
	flColor[1] = random_float(0.0, 255.0);
	flColor[2] = random_float(0.0, 255.0);

	Sprite_SetTransparency(iEntity, kRenderTransAdd, flColor, 255.0);

	SetThink(iEntity, "CEntity__BigStar_Think");

	return iEntity;
}

DefaultWeaponAttack(const pItem)
{
	static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
	static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
	ToggleTraceAttack(true);

	ExecuteHam(Ham_Weapon_PrimaryAttack, pItem);

	unregister_forward(FM_TraceLine, fw_TraceLine, true);
	unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
	ToggleTraceAttack(false);
}

ToggleTraceAttack(const bool: bEnabled)
{
	for(new i; i < sizeof gl_HamHook_TraceAttack; i++)
		bEnabled ? EnableHamForward(gl_HamHook_TraceAttack[i]) : DisableHamForward(gl_HamHook_TraceAttack[i]);
}

// [ Stocks ]
stock UTIL_CreateMuzzleFlash(iPlayer, const szMuzzleSprite[], const iMuzzleLoop, Float: flNextThink, Float: flScale, Float: flBrightness, iAttachment)
{
	if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < ENTITY_SPRITES_INTOLERANCE) return FM_NULLENT;
	
	static iSprite, iszAllocStringCached;
	if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
		iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	
	if(!IsValidEntity(iSprite)) return FM_NULLENT;
	
	set_entvar(iSprite, var_model, szMuzzleSprite);
	set_entvar(iSprite, var_spawnflags, SF_SPRITE_ONCE);
	
	set_entvar(iSprite, var_classname, ENTITY_MUZZLE_CLASSNAME);
	set_entvar(iSprite, var_owner, iPlayer);
	set_entvar(iSprite, var_aiment, iPlayer);
	set_entvar(iSprite, var_body, iAttachment);
	set_entvar(iSprite, var_muzzleloop, iMuzzleLoop);
	set_entvar(iSprite, var_flNextthink, flNextThink);
	
	Sprite_SetTransparency(iSprite, kRenderTransAdd, Float: {0.0, 0.0, 0.0}, flBrightness);
	set_entvar(iSprite, var_scale, flScale);
	
	dllfunc(DLLFunc_Spawn, iSprite);

	SetThink(iSprite, "CMuzzleFlash__Think_Pre");

	return iSprite;
}

stock Sprite_SetTransparency(const iSprite, const iRendermode, const Float: vecColor[3], const Float: flAmt, const iFx = kRenderFxNone)
{
	set_entvar(iSprite, var_rendermode, iRendermode);
	set_entvar(iSprite, var_rendercolor, vecColor);
	set_entvar(iSprite, var_renderamt, flAmt);
	set_entvar(iSprite, var_renderfx, iFx);
}

stock UTIL_SendWeaponAnim(iPlayer, iAnim)
{
	set_entvar(iPlayer, var_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_GetWeaponBoxItem(const pWeaponBox)
{
	new pItem;
	for(new iSlot = 0; iSlot < MAX_ITEM_TYPES; iSlot++)
	{
		pItem = get_member(pWeaponBox, m_WeaponBox_rgpPlayerItems, iSlot);
		if(!is_nullent(pItem))
			return pItem;
	}

	return 0;
}

stock UTIL_PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;
	
	if((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for(new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);
			
			for(k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if(iEvent != 5004)
					continue;
				
				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if(strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					engfunc(EngFunc_PrecacheSound, szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}

stock UTIL_PrecacheSpritesFromTxt(const szWeaponList[])
{
	new szTxtDir[64], szSprDir[64]; 
	new szFileData[128], szSprName[48], temp[1];

	format(szTxtDir, charsmax(szTxtDir), "sprites/%s.txt", szWeaponList);
	engfunc(EngFunc_PrecacheGeneric, szTxtDir);

	new iFile = fopen(szTxtDir, "rb");
	while(iFile && !feof(iFile)) 
	{
		fgets(iFile, szFileData, charsmax(szFileData));
		trim(szFileData);

		if(!strlen(szFileData)) 
			continue;

		new pos = containi(szFileData, "640");	
			
		if(pos == -1)
			continue;
			
		format(szFileData, charsmax(szFileData), "%s", szFileData[pos+3]);		
		trim(szFileData);

		strtok(szFileData, szSprName, charsmax(szSprName), temp, charsmax(temp), ' ', 1);
		trim(szSprName);
		
		format(szSprDir, charsmax(szSprDir), "sprites/%s.spr", szSprName);
		engfunc(EngFunc_PrecacheGeneric, szSprDir);
	}

	if(iFile) fclose(iFile);
}

stock UTIL_WeaponList(const pPlayer, const pItem)
{
	new szWeaponName[32]; rg_get_iteminfo(pItem, ItemInfo_pszName, szWeaponName, charsmax(szWeaponName));

	message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, pPlayer);
	write_string(szWeaponName);
	write_byte(get_member(pItem, m_Weapon_iPrimaryAmmoType));
	write_byte(rg_get_iteminfo(pItem, ItemInfo_iMaxAmmo1));
	write_byte(get_member(pItem, m_Weapon_iSecondaryAmmoType));
	write_byte(rg_get_iteminfo(pItem, ItemInfo_iMaxAmmo2));
	write_byte(rg_get_iteminfo(pItem, ItemInfo_iSlot));
	write_byte(rg_get_iteminfo(pItem, ItemInfo_iPosition));
	write_byte(rg_get_iteminfo(pItem, ItemInfo_iId));
	write_byte(rg_get_iteminfo(pItem, ItemInfo_iFlags));
	message_end();
}

public UTIL_BloodDrips(Float: vecOrigin[3], iVictim, iAmount)
{
	if(iAmount > 255) iAmount = 255;
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(gl_iszModelIndex_BloodSpray);
	write_short(gl_iszModelIndex_BloodDrop);
	write_byte(ExecuteHamB(Ham_BloodColor, iVictim));
	write_byte(min(max(3, iAmount / 10), 16));
	message_end();
}

stock UTIL_StatusIcon(iItem, iPlayer, iUpdateMode)
{
	new szSprite[33];
	new iClip = get_member(iItem, m_Weapon_iChargedAmmo);
	if(iClip > 9) format(szSprite, charsmax(szSprite), "escape");
	else format(szSprite, charsmax(szSprite), "number_%d", iClip);

	message_begin(MSG_ONE, gl_iMsgID_StatusIcon, { 0, 0, 0 }, iPlayer);
	if(iUpdateMode && iClip > 0) write_byte(1);
	else write_byte(0);
	write_string(szSprite);
	write_byte(0);
	write_byte(128);
	write_byte(255);
	message_end();
}
