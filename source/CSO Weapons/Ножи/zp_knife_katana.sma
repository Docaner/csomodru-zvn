/*
 * Last update (5.6.2021): Added WeaponKey for automaticly identity knife
 */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>

#define ADD_KNIFE_TO_EXTRA_ITEMS true // Add Knife to Extra-Item [true = Enable | false = Disable]
#define REMOVE_KNIFE_IF_INFECTED true // Remove knife if u infected [true = Enable | false = Disable]
#define ENABLE_WEAPON_LIST false // Enable Weapon List [true = Enable | false = Disable]

/* ~ [ Extra Item ] ~ */
#if ADD_KNIFE_TO_EXTRA_ITEMS == true
	new const WEAPON_ITEM_NAME[] = "Wakizashi Katana";
	const WEAPON_ITEM_COST = 0;
#endif

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = "weapon_knife";
#if ENABLE_WEAPON_LIST == true
	new const WEAPON_WEAPONLIST[] = "x/knife_katana";
#endif
new const WEAPON_ANIMATION[] = "knife";
new const WEAPON_MODEL_VIEW[] = "models/x/v_katana.mdl";
new const WEAPON_MODEL_PLAYER[] = "models/x/p_katana.mdl";
new const WEAPON_SOUNDS[][] =
{
	"weapons/katana_draw.wav", // 0
	"weapons/katana_midslash1.wav", // 1
	"weapons/katana_midslash2.wav", // 2
	"weapons/katana_stap.wav", // 3
	"weapons/katana_stapmiss.wav", // 4
	"weapons/mastercombat_hit1.wav", // 5
	"weapons/mastercombat_wall.wav" // 6
};

const Float: WEAPON_SLASH_DAMAGE = 150.0;
const Float: WEAPON_SLASH_DISTANCE = 150.0;
const Float: WEAPON_SLASH_KNOCKBACK = 0.0;
#define WEAPON_SLASH_NEXT_ATTACK_HIT 0.4
#define WEAPON_SLASH_NEXT_ATTACK_MISS (WEAPON_ANIM_SLASH_TIME - 0.2)

const Float: WEAPON_STAB_DAMAGE = 450.0;
const Float: WEAPON_STAB_DISTANCE = 150.0;
const Float: WEAPON_STAB_KNOCKBACK = 200.0;
#define WEAPON_STAB_NEXT_ATTACK 32/30.0
#define WEAPON_STAB_HIT_TIME 16/30.0

/* ~ [ TraceLine: Attack Angles ] ~ */
new Float: flAngles_Forward[] =
{ 
	0.0, 
	2.5, -2.5, 5.0, -5.0, 7.5, -7.5, 10.0, -10.0, 12.5, -12.5, 
	15.0, -15.0, 17.5, -17.5, 20.0, -20.0, 22.5, -22.5, 25.0, -25.0
};

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 120/15.0
#define WEAPON_ANIM_DRAW_TIME 46/30.0
#define WEAPON_ANIM_STAB_TIME 45/30.0
#define WEAPON_ANIM_SLASH_TIME 36/30.0

#define WEAPON_ANIM_IDLE 0
#define WEAPON_ANIM_DRAW 3
#define WEAPON_ANIM_STAB 4
#define WEAPON_ANIM_SLASH 6

/* ~ [ Params ] ~ */
new gl_iszAllocString_KnifeUID;
new gl_iszModelIndex_BloodSpray,
	gl_iszModelIndex_BloodDrop;

#if ADD_KNIFE_TO_EXTRA_ITEMS == true
	new gl_iItemID;
#endif

#if ENABLE_WEAPON_LIST == true
	new gl_iMsgID_WeapPickup,
		gl_iMsgID_Weaponlist;
#endif

/* ~ [ Macroses ] ~ */
#define DONT_BLEED -1
#define PDATA_SAFE 2
#define ACT_RANGE_ATTACK1 28

#define IsValidEntity(%1) (pev_valid(%1) == PDATA_SAFE)
#define IsCustomItem(%1) (pev(%1, pev_impulse) == gl_iszAllocString_KnifeUID)
#define get_WeaponState(%1) (get_pdata_int(%1, m_iWeaponState, linux_diff_weapon))
#define set_WeaponState(%1,%2) (set_pdata_int(%1, m_iWeaponState, %2, linux_diff_weapon))

enum _: eWeaponState
{
	WPNSTATE_NONE = 0,
	WPNSTATE_STAB_HIT
};

/* ~ [ Offsets ] ~ */
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
#define m_flLastAttackTime 220
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_szAnimExtention 492

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
	register_plugin("[ZP] Knife: Wakizashi Katana", "1.1", "xUnicorn");

	// Events
	register_event("CurWeapon", "EV_CurWeapon", "be", "1=1");

	// Forwards
	register_forward(FM_UpdateClientData, 	"FM_Hook_UpdateClientData_Post", true);

	// Weapon
	RegisterHam(Ham_Weapon_WeaponIdle, 		WEAPON_REFERENCE, 	"CKnife__Idle_Pre", false);
	RegisterHam(Ham_Item_Deploy, 			WEAPON_REFERENCE, 	"CKnife__Deploy_Post", true);
	RegisterHam(Ham_Item_Holster, 			WEAPON_REFERENCE, 	"CKnife__Holster_Post", true);
	RegisterHam(Ham_Item_PostFrame, 		WEAPON_REFERENCE, 	"CKnife__PostFrame_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack, 	WEAPON_REFERENCE, 	"CKnife__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	WEAPON_REFERENCE, 	"CKnife__SecondaryAttack_Pre", false);

	// Register on Extra-Items
	#if ADD_KNIFE_TO_EXTRA_ITEMS == true
		gl_iItemID = zp_register_extra_item(WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN);
	#endif

	// Messages
	#if ENABLE_WEAPON_LIST == true
		gl_iMsgID_WeapPickup = get_user_msgid("WeapPickup");
		gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	#endif
}

public plugin_precache()
{
	new i;

	#if ENABLE_WEAPON_LIST == true
		// Hook weapon
		register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

		// Precache generic
		UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	#endif

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);

	// Precache sounds
	for(i = 0; i < sizeof WEAPON_SOUNDS; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUNDS[i]);

	// Alloc String
	gl_iszAllocString_KnifeUID = engfunc(EngFunc_AllocString, "knife_katana");

	// Model Index
	gl_iszModelIndex_BloodSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
	gl_iszModelIndex_BloodDrop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");
}

public plugin_natives()
{
	register_native("zp_get_user_katana", "_get_user_katana", 1);
	register_native("zp_give_user_katana", "_give_user_katana", 1);
	register_native("zp_delete_user_katana", "_delete_user_katana", 1);
}

#if ENABLE_WEAPON_LIST == true
	public Command_HookWeapon(const pPlayer)
	{
		engclient_cmd(pPlayer, WEAPON_REFERENCE);
		return PLUGIN_HANDLED;
	}
#endif

#if AMXX_VERSION_NUM < 183
	public client_disconnect(pPlayer) _delete_user_katana(pPlayer);
#else
	public client_disconnected(pPlayer) _delete_user_katana(pPlayer);
#endif

public _get_user_katana(const pPlayer)
{
	static pKnife; pKnife = get_pdata_cbase(pPlayer, m_rpgPlayerItems + 3, linux_diff_player);
	return (IsValidEntity(pKnife) && IsCustomItem(pKnife)) ? true : false;
}

public _give_user_katana(const pPlayer)
{
	if(!is_user_alive(pPlayer)) return false;

	static pKnife; pKnife = get_pdata_cbase(pPlayer, m_rpgPlayerItems + 3, linux_diff_player);
	if(IsValidEntity(pKnife))
	{
		set_pev(pKnife, pev_impulse, gl_iszAllocString_KnifeUID);

		#if ENABLE_WEAPON_LIST == true
			UTIL_WeapPickup(pPlayer, CSW_KNIFE);
			UTIL_SetWeaponList(pPlayer, WEAPON_WEAPONLIST, -1, -1, -1, -1, 2, 1, CSW_KNIFE, 0);
		#endif
	}

	static pActiveItem; pActiveItem = get_pdata_cbase(pPlayer, m_pActiveItem, linux_diff_player);
	if(IsValidEntity(pActiveItem) && IsCustomItem(pActiveItem))
	{
		ExecuteHamB(Ham_Item_Deploy, pActiveItem);
		EV_CurWeapon(pPlayer);
	}

	return true;
}

public _delete_user_katana(const pPlayer)
{
	static pKnife; pKnife = get_pdata_cbase(pPlayer, m_rpgPlayerItems + 3, linux_diff_player);
	if(IsValidEntity(pKnife) && IsCustomItem(pKnife))
	{
		set_pev(pKnife, pev_impulse, 0);

		#if ENABLE_WEAPON_LIST == true
			UTIL_SetWeaponList(pPlayer, WEAPON_REFERENCE, -1, -1, -1, -1, 2, 1, CSW_KNIFE, 0);
		#endif
	}
}

/* ~ [ Zombie Plague ] ~ */
#if ADD_KNIFE_TO_EXTRA_ITEMS == true
	public zp_extra_item_selected(pPlayer, iItemID)
	{
		if(iItemID != gl_iItemID) return PLUGIN_HANDLED;

		if(_get_user_katana(pPlayer))
		{
			client_print(pPlayer, print_center, "*** You have already [Katana] ***");
			return ZP_PLUGIN_HANDLED;
		}

		_give_user_katana(pPlayer);
		return PLUGIN_HANDLED;
	}
#endif

#if REMOVE_KNIFE_IF_INFECTED == true
	public zp_user_infected_pre(pPlayer) _delete_user_katana(pPlayer);
#endif

/* ~ [ Events ] ~ */
public EV_CurWeapon(const pPlayer)
{
	if(!is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer)) return;

	static pActiveItem; pActiveItem = get_pdata_cbase(pPlayer, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(pActiveItem) || !IsCustomItem(pActiveItem)) return;

	CKnife__SwitchModel(pPlayer);
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(const pPlayer, const iSendWeapons, const CD_Handle)
{
	if(!is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer)) return;

	static pActiveItem; pActiveItem = get_pdata_cbase(pPlayer, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(pActiveItem) || !IsCustomItem(pActiveItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

/* ~ [ HamSandwich ] ~ */
public CKnife__Idle_Pre(const pItem)
{
	if(!IsValidEntity(pItem) || !IsCustomItem(pItem)) return HAM_IGNORED;
	if(get_pdata_float(pItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;

	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
	if(zp_get_user_zombie(pPlayer)) return HAM_IGNORED;

	UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_IDLE);
	set_pdata_float(pItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CKnife__Deploy_Post(const pItem)
{
	if(!IsValidEntity(pItem) || !IsCustomItem(pItem)) return;

	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
	if(zp_get_user_zombie(pPlayer)) return;

	CKnife__SwitchModel(pPlayer);
	UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_DRAW);
	emit_sound(pPlayer, CHAN_WEAPON, WEAPON_SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_float(pItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
	set_pdata_float(pItem, m_flNextPrimaryAttack, 0.8, linux_diff_weapon);
	set_pdata_float(pItem, m_flNextSecondaryAttack, 0.8, linux_diff_weapon);
}

public CKnife__Holster_Post(const pItem)
{
	if(!IsValidEntity(pItem) || !IsCustomItem(pItem)) return;

	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
	if(zp_get_user_zombie(pPlayer)) return;

	set_pdata_float(pItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(pItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(pItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(pPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CKnife__PostFrame_Pre(const pItem)
{
	if(!IsCustomItem(pItem)) return HAM_IGNORED;

	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
	if(zp_get_user_zombie(pPlayer)) return HAM_IGNORED;

	switch(get_WeaponState(pItem))
	{
		case WPNSTATE_NONE: return HAM_IGNORED;
		case WPNSTATE_STAB_HIT:
		{
			static Float: flNextAttackTime; flNextAttackTime = (WEAPON_STAB_NEXT_ATTACK - WEAPON_STAB_HIT_TIME);
			UTIL_FakeTraceLine(pPlayer, pItem, WEAPON_STAB_DISTANCE, WEAPON_STAB_DAMAGE, WEAPON_STAB_KNOCKBACK, flAngles_Forward, sizeof flAngles_Forward, true);

			set_WeaponState(pItem, WPNSTATE_NONE);
			set_pdata_float(pPlayer, m_flNextAttack, flNextAttackTime, linux_diff_player);
			set_pdata_float(pItem, m_flNextPrimaryAttack, flNextAttackTime, linux_diff_weapon);
			set_pdata_float(pItem, m_flNextSecondaryAttack, flNextAttackTime, linux_diff_weapon);
		}
	}

	return HAM_IGNORED;
}

public CKnife__PrimaryAttack_Pre(const pItem)
{
	if(!IsValidEntity(pItem) || !IsCustomItem(pItem)) return HAM_IGNORED;

	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
	if(zp_get_user_zombie(pPlayer)) return HAM_IGNORED;

	new Float: flNextAttackTime, Float: flIdleTime, iSound, iHit;
	iHit = UTIL_FakeTraceLine(pPlayer, pItem, WEAPON_SLASH_DISTANCE, WEAPON_SLASH_DAMAGE, WEAPON_SLASH_KNOCKBACK, flAngles_Forward, 7, true);
	static iAnim; iAnim = !iAnim;
	iSound = iAnim ? 2 : 1;
	flNextAttackTime = iHit ? WEAPON_SLASH_NEXT_ATTACK_HIT : WEAPON_SLASH_NEXT_ATTACK_MISS;
	flIdleTime = WEAPON_ANIM_SLASH_TIME;

	UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_SLASH + iAnim);
	emit_sound(pPlayer, CHAN_WEAPON, WEAPON_SOUNDS[iSound], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	// Player animation
	static szAnimation[64];
	formatex(szAnimation, charsmax(szAnimation), pev(pPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIMATION);
	UTIL_PlayerAnimation(pPlayer, szAnimation);

	set_pdata_float(pPlayer, m_flNextAttack, flNextAttackTime, linux_diff_player);
	set_pdata_float(pItem, m_flNextPrimaryAttack, flNextAttackTime, linux_diff_weapon);
	set_pdata_float(pItem, m_flNextSecondaryAttack, flNextAttackTime, linux_diff_weapon);
	set_pdata_float(pItem, m_flTimeWeaponIdle, flIdleTime, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CKnife__SecondaryAttack_Pre(const pItem)
{
	if(!IsValidEntity(pItem) || !IsCustomItem(pItem)) return HAM_IGNORED;

	static pPlayer; pPlayer = get_pdata_cbase(pItem, m_pPlayer, linux_diff_weapon);
	if(zp_get_user_zombie(pPlayer)) return HAM_IGNORED;

	new Float: flNextAttackTime, Float: flIdleTime, iAnim, iSound;
	iAnim = WEAPON_ANIM_STAB;
	iSound = 4;
	flNextAttackTime = WEAPON_STAB_HIT_TIME;
	flIdleTime = WEAPON_ANIM_STAB_TIME;

	set_WeaponState(pItem, WPNSTATE_STAB_HIT);

	UTIL_SendWeaponAnim(pPlayer, iAnim);
	emit_sound(pPlayer, CHAN_WEAPON, WEAPON_SOUNDS[iSound], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	// Player animation
	static szAnimation[64];
	formatex(szAnimation, charsmax(szAnimation), pev(pPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIMATION);
	UTIL_PlayerAnimation(pPlayer, szAnimation);

	set_pdata_float(pPlayer, m_flNextAttack, flNextAttackTime, linux_diff_player);
	set_pdata_float(pItem, m_flNextPrimaryAttack, flNextAttackTime, linux_diff_weapon);
	set_pdata_float(pItem, m_flNextSecondaryAttack, flNextAttackTime, linux_diff_weapon);
	set_pdata_float(pItem, m_flTimeWeaponIdle, flIdleTime, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

/* ~ [ Other ] ~ */
public CKnife__SwitchModel(const pPlayer)
{
	set_pev(pPlayer, pev_viewmodel2, WEAPON_MODEL_VIEW);
	set_pev(pPlayer, pev_weaponmodel2, WEAPON_MODEL_PLAYER);

	set_pdata_string(pPlayer, m_szAnimExtention * 4, WEAPON_ANIMATION, -1, linux_diff_player * linux_diff_animating);
}

/* ~ [ Stock's ] ~ */
stock UTIL_SendWeaponAnim(const pPlayer, const iAnim)
{
	set_pev(pPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, pPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_PlayerAnimation(const pPlayer, const szAnim[], const Float: flFrame = 1.0)
{
	new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
	if((iAnimDesired = lookup_sequence(pPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
		iAnimDesired = 0;

	set_entity_anim(pPlayer, iAnimDesired, flFrame);
	
	set_pdata_int(pPlayer, m_fSequenceLoops, bLoops, linux_diff_animating);
	set_pdata_int(pPlayer, m_fSequenceFinished, 0, linux_diff_animating);
	
	set_pdata_float(pPlayer, m_flFrameRate, flFrameRate, linux_diff_animating);
	set_pdata_float(pPlayer, m_flGroundSpeed, flGroundSpeed, linux_diff_animating);
	set_pdata_float(pPlayer, m_flLastEventCheck, get_gametime(), linux_diff_animating);
	
	set_pdata_int(pPlayer, m_Activity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_int(pPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_float(pPlayer, m_flLastAttackTime, get_gametime(), linux_diff_player);
}

stock set_entity_anim(const iEntity, const iSequence, const Float: flFrame)
{
	set_pev(iEntity, pev_frame, flFrame);
	set_pev(iEntity, pev_framerate, 1.0);
	set_pev(iEntity, pev_animtime, get_gametime());
	set_pev(iEntity, pev_sequence, iSequence);
}

stock UTIL_FakeTraceLine(const pAttacker, const pInflictor, const Float: flDistance, const Float: flDamage, const Float: flKnockBack, const Float: flSendAngles[], const iSendAngles, const bool: bDoDamage)
{
	enum
	{
		SLASH_HIT_NONE = 0,
		SLASH_HIT_WORLD,
		SLASH_HIT_ENTITY
	};

	new Float: vecOrigin[3]; pev(pAttacker, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(pAttacker, pev_v_angle, vecAngles);
	new Float: vecViewOfs[3]; pev(pAttacker, pev_view_ofs, vecViewOfs);

	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);

	new Float: vecForward[3], Float: vecRight[3], Float: vecUp[3];
	engfunc(EngFunc_AngleVectors, vecAngles, vecForward, vecRight, vecUp);
		
	new iTrace = create_tr2();

	new Float: flTan, Float: flMul;
	new iHitList[10], iHitCount = 0;

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

		engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, DONT_IGNORE_MONSTERS, pAttacker, iTrace);
		get_tr2(iTrace, TR_flFraction, flFraction);

		if(flFraction == 1.0)
		{
			engfunc(EngFunc_TraceHull, vecOrigin, vecEnd, HULL_HEAD, pAttacker, iTrace);
			get_tr2(iTrace, TR_flFraction, flFraction);
		
			engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, DONT_IGNORE_MONSTERS, pAttacker, iTrace);
			pHit = get_tr2(iTrace, TR_pHit);
		}
		else pHit = get_tr2(iTrace, TR_pHit);

		if(pHit == pAttacker) continue;

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
			if(bDoDamage)
			{
				if(pev(pHit, pev_solid) == SOLID_BSP && !(pev(pHit, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
				{
					ExecuteHamB(Ham_TakeDamage, pHit, pInflictor, pAttacker, flDamage, DMG_NEVERGIB|DMG_CLUB);
				}
				else
				{
					UTIL_FakeTraceAttack(pHit, pInflictor, pAttacker, flDamage, vecForward, iTrace, DMG_NEVERGIB|DMG_CLUB);
					if(flKnockBack > 0.0) UTIL_FakeKnockBack(pHit, vecForward, flKnockBack);
				}
			}

			iHitResult = SLASH_HIT_ENTITY;
			pHitEntity = pHit;
		}
	}

	free_tr2(iTrace);

	static iSound; iSound = -1;
	switch(iHitResult)
	{
		case SLASH_HIT_WORLD: iSound = 6;
		case SLASH_HIT_ENTITY: iSound = 5;
	}

	if(bDoDamage && iSound != -1)
		emit_sound(pAttacker, CHAN_ITEM, WEAPON_SOUNDS[iSound], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	return iHitResult == SLASH_HIT_NONE ? false : true;
}

stock UTIL_FakeTraceAttack(const pVictim, const pInflictor, const pAttacker, Float: flDamage, const Float: vecDirection[3], const pTrace, iBitsDamageType)
{
	if(pev(pVictim, pev_takedamage) == DAMAGE_NO) return;
	if(is_user_alive(pVictim))
	{
		if(!zp_get_user_zombie(pVictim))
			return;
	}

	static Float: vecEndPos[3]; get_tr2(pTrace, TR_vecEndPos, vecEndPos);
	static iHitGroup; iHitGroup = get_tr2(pTrace, TR_iHitgroup);
	static Float: vecPunchAngle[3];
	switch(iHitGroup)
	{
		case HIT_HEAD:
		{
			flDamage *= 4.0;
			vecPunchAngle[0] = flDamage * -0.5;
			if(vecPunchAngle[0] < -12.0) vecPunchAngle[0] = -12.0;

			vecPunchAngle[2] = flDamage * random_float(-1.0, 1.0);
			if(vecPunchAngle[2] < -9.0) vecPunchAngle[2] = -9.0;
			else if(vecPunchAngle[2] > 9.0) vecPunchAngle[2] = 9.0;

			set_pev(pVictim, pev_punchangle, vecPunchAngle);
		}
		case HIT_CHEST:
		{
			flDamage *= 1.0;
			vecPunchAngle[0] = flDamage * -0.1;
			if(vecPunchAngle[0] < -4.0) vecPunchAngle[0] = -4.0;

			set_pev(pVictim, pev_punchangle, vecPunchAngle);
		}
		case HIT_STOMACH:
		{
			flDamage *= 1.25;
			vecPunchAngle[0] = flDamage * -0.1;
			if(vecPunchAngle[0] < -4.0) vecPunchAngle[0] = -4.0;

			set_pev(pVictim, pev_punchangle, vecPunchAngle);
		}
		case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 0.75;
	}

	set_pdata_int(pVictim, m_LastHitGroup, iHitGroup, linux_diff_player);
	ExecuteHamB(Ham_TakeDamage, pVictim, pInflictor, pAttacker, flDamage, iBitsDamageType);

	static iBloodColor;
	if((iBloodColor = ExecuteHamB(Ham_BloodColor, pVictim)) != DONT_BLEED)
	{
		xs_vec_sub_scaled(vecEndPos, vecDirection, 4.0, vecEndPos);
		UTIL_BloodDrips(vecEndPos, iBloodColor, floatround(flDamage));
		ExecuteHamB(Ham_TraceBleed, pVictim, flDamage, vecDirection, pTrace, iBitsDamageType);
	}
}

stock UTIL_FakeKnockBack(const pVictim, const Float: vecDirection[3], Float: flKnockBack) 
{
	if(!is_user_alive(pVictim) || !zp_get_user_zombie(pVictim)) return false;

	set_pdata_float(pVictim, m_flPainShock, 1.0, linux_diff_player);

	static Float: vecVelocity[3]; pev(pVictim, pev_velocity, vecVelocity);
	if(pev(pVictim, pev_flags) & FL_DUCKING) flKnockBack *= 0.7;

	vecVelocity[0] = vecDirection[0] * flKnockBack;
	vecVelocity[1] = vecDirection[1] * flKnockBack;
	vecVelocity[2] = 200.0;

	set_pev(pVictim, pev_velocity, vecVelocity);
	return true;
}

public UTIL_BloodDrips(const Float: vecOrigin[3], const iColor, iAmount)
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

#if ENABLE_WEAPON_LIST == true
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

	stock UTIL_WeapPickup(const pPlayer, const iId)
	{
		message_begin(MSG_ONE, gl_iMsgID_WeapPickup, _, pPlayer);
		write_byte(iId);
		message_end();
	}

	stock UTIL_SetWeaponList(const pPlayer, const szWeaponName[], const iPrimaryAmmoID, const iPrimaryAmmoMaxAmount, const iSecondaryAmmoID, const iSecondaryAmmoMaxAmount, const iSlotID, const iNumberInSlot, const iWeaponID, const iFlags)
	{
		message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, pPlayer);
		write_string(szWeaponName);
		write_byte(iPrimaryAmmoID);
		write_byte(iPrimaryAmmoMaxAmount);
		write_byte(iSecondaryAmmoID);
		write_byte(iSecondaryAmmoMaxAmount);
		write_byte(iSlotID);
		write_byte(iNumberInSlot);
		write_byte(iWeaponID);
		write_byte(iFlags);
		message_end();
	}
#endif
