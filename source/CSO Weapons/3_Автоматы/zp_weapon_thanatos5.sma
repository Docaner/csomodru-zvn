#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <zpe_knokcback>
#include <xs>

#define is_user_valid(%0)			(%0 && 0 < %0 < 33)
#define IsCustomItem(%0) 			(pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define WeaponInMode(%0)			(get_pdata_int(%0, m_iWeaponState, linux_diff_weapon) == 2)

#define PDATA_SAFE 					2
#define DMG_GRENADE					(1<<24)

#define pev_nextdamage				pev_fuser4
#define pev_type 					pev_iuser4

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 		51/30.0
#define WEAPON_ANIM_SHOOT_TIME 		31/30.0
#define WEAPON_ANIM_SHOOT_EX_TIME	61/30.0
#define WEAPON_ANIM_RELOAD_TIME 	96/30.0
#define WEAPON_ANIM_DRAW_TIME 		31/30.0
#define WEAPON_ANIM_CHANGE_TIME		156/30.0

#define WEAPON_ANIM_IDLE_A 			0
#define WEAPON_ANIM_IDLE_B			1
#define WEAPON_ANIM_SHOOT_A 		random_num(2,4)
#define WEAPON_ANIM_SHOOT_B 		random_num(5,7)
#define WEAPON_ANIM_SHOOT_EX		8
#define WEAPON_ANIM_RELOAD_A		9
#define WEAPON_ANIM_RELOAD_B		10
#define WEAPON_ANIM_CHANGE 			11
#define WEAPON_ANIM_DRAW_A 			12
#define WEAPON_ANIM_DRAW_B 			13

/* ~ [ Extra Item ] ~ */
new const WEAPON_ITEM_NAME[] = 		"Thanatos-5";
const WEAPON_ITEM_COST = 			0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = 		"weapon_famas";
new const WEAPON_WEAPONLIST[] = 	"zp_br_cso/weapons4/weapon_thanatos5";
new const WEAPON_NATIVE[] = 		"zp_give_user_thanatos5";
new const WEAPON_MODEL_SHELL[] = 	"models/rshell.mdl";
new const WEAPON_MODEL_VIEW[] = 	"models/zp_br_cso/weapons4/v_thanatos5.mdl";
new const WEAPON_MODEL_WORLD[] = 	"models/zp_br_cso/other/w_weapons4.mdl";
new const WEAPON_SOUND_FIRE[][] =
{
	"weapons/thanatos5-1.wav",
	"weapons/thanatos5_shootb2_1.wav"
};

const WEAPON_SPECIAL_CODE = 		1048;
const WEAPON_BODY = 				4;

const WEAPON_MAX_CLIP = 			40;
const WEAPON_DEFAULT_AMMO = 		90;
const Float: WEAPON_RATE = 			0.102;
const Float: WEAPON_PUNCHANGLE = 	0.88;
const Float: WEAPON_DAMAGE = 		1.54;

new const iWeaponList[] = 			{ 4,  90, -1, -1, 0, 18,15, 0 };

/* ~ [ Entity: Missile ] ~ */
new const ENTITY_MISSILE_CLASSNAME[] = "ent_xt5_missile";
new const ENTITY_MISSILE_MODEL[] = "models/zp_br_cso/weapons4/thanatos5_bulleta.mdl";
new const ENTITY_MISSILE_SOUND[][] =
{
	"weapons/thanatos5_explode1.wav",
	"weapons/thanatos5_explode2.wav",
	"weapons/thanatos5_explode3.wav"
};
new const ENTITY_MISSILE_SPRITE[][] =
{
	"sprites/zp_br_cso/weapons4/hud/thanatos5_explode.spr",
	"sprites/zp_br_cso/weapons4/hud/thanatos5_explode2.spr"
};
new const ENTITY_MISSILE_TRAIL[] = "sprites/laserbeam.spr";
const Float: ENTITY_MISSILE_SPEED = 1000.0;
const Float: ENTITY_MISSILE_RADIUS = 75.0;
const ENTITY_MISSILE_DMGTYPE = DMG_GRENADE;
new const Float: ENTITY_MISSILE_DAMAGE[3][2] =
{
	// min, max
	{ 190.0, 240.0 }, // first explosion
	{ 145.0, 200.0 }, // second explosion
	{ 106.0, 135.0 } // third explosion
};

/* ~ [ Offsets ] ~ */
// Linux extra offsets
#define linux_diff_weapon 4
#define linux_diff_player 5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CBasePlayerItem
#define m_pPlayer 41
#define m_pNext 42
#define m_iId 43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flTimeWeaponIdle 48
#define m_iPrimaryAmmoType 49
#define m_iClip 51
#define m_fInReload 54
#define m_iShellId 57
#define m_iWeaponState 74

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_flEjectBrass 111
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

/* ~ [ Params ] ~ */
new gl_iszAllocString_Entity,
	gl_iszAllocString_ModelView,
	gl_iszAllocString_Th5Missile,

	gl_iszModelIndex_Shell,
	gl_iszModelIndex_Trail,
	gl_iszModelIndex_Explode[2],

	HamHook: gl_HamHook_TraceAttack[4],

	gl_iMsgID_Weaponlist,
	gl_iItemID;

public plugin_init()
{
	register_plugin("[ZP] Weapon: THANATOS-5", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	// Forwards
	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);

	// Weapon
	RegisterHam(Ham_Item_Holster,			WEAPON_REFERENCE,	"CWeapon__Holster_Post", true);
	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	WEAPON_REFERENCE,	"CWeapon__SecondaryAttack_Pre", false);

	// Entity
	RegisterHam(Ham_Think,					"info_target",		"CEntity__Think_Pre", false);
	RegisterHam(Ham_Touch,					"info_target",		"CEntity__Touch_Pre", false);
	
	// Trace Attack
	gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,	"func_breakable",	"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",		"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",			"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",	"CEntity__TraceAttack_Pre", false);
	
	fm_ham_hook(false);

	// Register on Extra-Items
	gl_iItemID = zp_register_extra_item(WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN);

	// Messages
	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");

	// Alloc String
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	gl_iszAllocString_Th5Missile = engfunc(EngFunc_AllocString, ENTITY_MISSILE_CLASSNAME);
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, ENTITY_MISSILE_MODEL);

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	
	// Precache sounds
	new i = 0;

	for(i = 0; i < sizeof WEAPON_SOUND_FIRE; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_FIRE[i]);

	for(i = 0; i < sizeof ENTITY_MISSILE_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, ENTITY_MISSILE_SOUND[i]);

	// Model Index
	gl_iszModelIndex_Shell = engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_SHELL);
	gl_iszModelIndex_Trail = engfunc(EngFunc_PrecacheModel, ENTITY_MISSILE_TRAIL);

	for(i = 0; i < sizeof ENTITY_MISSILE_SPRITE; i++)
		gl_iszModelIndex_Explode[i] = engfunc(EngFunc_PrecacheModel, ENTITY_MISSILE_SPRITE[i]);
}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

// [ Amxx ]
public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem == gl_iItemID)
		Command_GiveWeapon(iPlayer);
}

public Command_HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

public Command_GiveWeapon(iPlayer)
{
	static iEntity; iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
	if(iEntity <= 0) return 0;

	set_pev(iEntity, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, iEntity);
	set_pdata_int(iEntity, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	UTIL_DropWeapon(iPlayer, 1);

	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iEntity))
	{
		set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
		return 0;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, iEntity, iPlayer);

	new iAmmoType = m_rgAmmo + get_pdata_int(iEntity, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, m_rgAmmo, linux_diff_player) < WEAPON_DEFAULT_AMMO)
		set_pdata_int(iPlayer, iAmmoType, WEAPON_DEFAULT_AMMO, linux_diff_player);

	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return 1;
}

// [ Fakemeta ]
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(!is_user_alive(iPlayer)) return;

	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
	static i, szClassName[32], iItem;
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

	for(i = 0; i < 6; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, linux_diff_weapon);

		if(pev_valid(iItem) == PDATA_SAFE && IsCustomItem(iItem))
		{
			engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
			set_pev(iEntity, pev_body, WEAPON_BODY);
			
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;
public FM_Hook_TraceLine_Post(const Float: vecOrigin1[3], const Float: vecOrigin2[3], iFlags, iAttacker, iTrace)
{
	if(iFlags & IGNORE_MONSTERS) return FMRES_IGNORED;

	static pHit; pHit = get_tr2(iTrace, TR_pHit);
	static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);

	if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;

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
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	
	if(get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon) == 1)
		set_pdata_int(iItem, m_iWeaponState, 0, linux_diff_weapon);

	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CWeapon__Deploy_Post(iItem)
{
	if(!IsCustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);

	UTIL_SendWeaponAnim(iPlayer, WeaponInMode(iItem) ? WEAPON_ANIM_DRAW_B : WEAPON_ANIM_DRAW_A);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(get_pdata_int(iItem, m_fInReload, linux_diff_weapon) == 1)
	{
		static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
		static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
		static j; j = min(WEAPON_MAX_CLIP - iClip, iAmmo);

		set_pdata_int(iItem, m_iClip, iClip + j, linux_diff_weapon);
		set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
		set_pdata_int(iItem, m_fInReload, 0, linux_diff_weapon);
	}

	if(get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon) == 1)
	{
		set_pdata_int(iItem, m_iWeaponState, 2, linux_diff_weapon);
	}

	return HAM_IGNORED;
}

public CWeapon__AddToPlayer_Post(iItem, iPlayer)
{
	if(IsCustomItem(iItem)) UTIL_WeaponList(iPlayer, true);
	else if(pev(iItem, pev_impulse) == 0) UTIL_WeaponList(iPlayer, false);
}

public CWeapon__Reload_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInReload, 1, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WeaponInMode(iItem) ? WEAPON_ANIM_RELOAD_B : WEAPON_ANIM_RELOAD_A);

	// set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	// set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!IsCustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WeaponInMode(iItem) ? WEAPON_ANIM_IDLE_B : WEAPON_ANIM_IDLE_A);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	if(get_pdata_int(iItem, m_iClip, linux_diff_weapon) == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
	static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
	fm_ham_hook(true);

	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);

	unregister_forward(FM_TraceLine, fw_TraceLine, true);
	unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
	fm_ham_hook(false);

	static Float: vecPunchangle[3];
	pev(iPlayer, pev_punchangle, vecPunchangle);
	vecPunchangle[0] *= WEAPON_PUNCHANGLE;
	vecPunchangle[1] *= WEAPON_PUNCHANGLE;
	vecPunchangle[2] *= WEAPON_PUNCHANGLE;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	UTIL_SendWeaponAnim(iPlayer, WeaponInMode(iItem) ? WEAPON_ANIM_SHOOT_B : WEAPON_ANIM_SHOOT_A);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_int(iItem, m_iShellId, gl_iszModelIndex_Shell, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flEjectBrass, get_gametime(), linux_diff_player);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	static Float: flTime, iWeaponState, iAnim;
	iWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);
	switch(iWeaponState)
	{
		case 0:
		{
			iWeaponState = 1;
			iAnim = WEAPON_ANIM_CHANGE;
			flTime = WEAPON_ANIM_CHANGE_TIME;
		}
		case 2:
		{
			iWeaponState = 0;
			iAnim = WEAPON_ANIM_SHOOT_EX;
			flTime = WEAPON_ANIM_SHOOT_EX_TIME;

			new Float: vecOrigin[3]; UTIL_GetPosition(iPlayer, 50.0, get_cvar_num("cl_righthand") ? 10.0 : -10.0, -7.0, vecOrigin);
			new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
			new Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

			CWeapon__CreateMissile(iPlayer, 0, vecOrigin, vecForward);
			emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	UTIL_SendWeaponAnim(iPlayer, iAnim);

	set_pdata_int(iItem, m_iWeaponState, iWeaponState, linux_diff_weapon);

	set_pdata_float(iPlayer, m_flNextAttack, flTime, linux_diff_player);
	set_pdata_float(iItem, m_flNextPrimaryAttack, flTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, flTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, flTime, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CEntity__Think_Pre(iEntity)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Th5Missile)
	{
		CWeapon__MissileExplode(iEntity);
	}

	return HAM_IGNORED;
}

public CEntity__Touch_Pre(iEntity, iTouch)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Th5Missile)
	{
		/* По тимейтам не ебашит */
		if(is_user_connected(iTouch) && !zp_get_user_zombie(iTouch))
			return HAM_SUPERCEDE;

		if(pev(iEntity, pev_nextdamage) < get_gametime())
		{
			static iOwner; iOwner = pev(iEntity, pev_owner);
			if(iTouch && iTouch != iOwner && 
				(is_user_valid(iTouch) || 
				pev(iTouch, pev_deadflag) == DEAD_NO && pev(iTouch, pev_flags) & FL_MONSTER) )
				CWeapon__MissileExplode(iEntity);
		}
	}

	return HAM_IGNORED;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
	if(!is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return;

	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

// [ Other ]
public CWeapon__CreateMissile(iPlayer, iMissileType, Float: vecOrigin[3], Float: vecDirection[3])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	if(!iEntity) return FM_NULLENT;

	new Float: vecVelocity[3];

	// Speed for missile
	if(!iMissileType)
	{
		xs_vec_copy(vecDirection, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, ENTITY_MISSILE_SPEED, vecVelocity);
	}
	else
		get_speed_vector(vecOrigin, vecDirection, 200.0, vecVelocity);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Th5Missile);
	set_pev(iEntity, pev_movetype, MOVETYPE_PUSHSTEP);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_velocity, vecVelocity);
	set_pev(iEntity, pev_gravity, 1.0);
	set_pev(iEntity, pev_type, iMissileType);
	if(iMissileType) set_pev(iEntity, pev_nextdamage, get_gametime() + 1.5);
	set_pev(iEntity, pev_nextthink, get_gametime() + 1.5);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_MISSILE_MODEL);
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	set_entity_anim(iEntity, 0);

	// https://github.com/baso88/SC_AngelScript/wiki/TE_BEAMFOLLOW
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(gl_iszModelIndex_Trail); // Model Index
	write_byte(4); // Life
	write_byte(1); // Width
	write_byte(0); // Red
	write_byte(200); // Green
	write_byte(200); // Blue
	write_byte(150); // Alpha
	message_end();

	return iEntity;
}

public CWeapon__MissileExplode(iEntity)
{
	static iOwner; iOwner = pev(iEntity, pev_owner);
	static iMissileType; iMissileType = pev(iEntity, pev_type);
	static Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);

	emit_sound(iEntity, CHAN_ITEM, ENTITY_MISSILE_SOUND[iMissileType], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	UTIL_CreateExplosion(gl_iszModelIndex_Explode[0], vecOrigin, _, 5, 30);
	UTIL_CreateExplosion(gl_iszModelIndex_Explode[1], vecOrigin, _, 5, 30);

	// Damage
	new iItem = get_pdata_cbase(iOwner, m_rpgPlayerItems + 1, linux_diff_player);
	if(pev_valid(iItem) == PDATA_SAFE && IsCustomItem(iItem))
	{
		new Float: flDamage = random_float(ENTITY_MISSILE_DAMAGE[iMissileType][0], ENTITY_MISSILE_DAMAGE[iMissileType][1]);
		new iVictim = FM_NULLENT;
		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_MISSILE_RADIUS)) > 0)
		{
			if(pev(iVictim, pev_takedamage) == DAMAGE_NO) continue;

			if(is_user_alive(iVictim))
			{
				if(iVictim == iOwner || !zp_get_user_zombie(iVictim))
					continue;
			}
			else if(pev(iVictim, pev_solid) == SOLID_BSP)
			{
				if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
					continue;
			}

			if(is_user_alive(iVictim) && zp_get_user_zombie(iVictim))
				set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);

			ExecuteHamB(Ham_TakeDamage, iVictim, iItem, iOwner, flDamage, ENTITY_MISSILE_DMGTYPE);
			zp_set_user_velocitymifier(iVictim, 0.22)
		}
	}

	set_pev(iEntity, pev_flags, FL_KILLME);

	if(iMissileType == 2) return;

	// create new missiles
	static Float: vecDirection[3];
	new const Float: vecDirections[4][3] =
	{
		{ 100.0, 0.0, 100.0 },
		{ -100.0, 0.0, 100.0 },
		{ 0.0, 100.0, 100.0 },
		{ 0.0, -100.0, 100.0 }
	};

	for(new i = 0; i < 4; i++)
	{
		UTIL_GetPosition(iEntity, vecDirections[i][0], vecDirections[i][1], vecDirections[i][2], vecDirection);

		CWeapon__CreateMissile(iOwner, iMissileType + 1, vecOrigin, vecDirection);
	}
}

public fm_ham_hook(bool: bEnabled)
{
	for(new i = 0; i < 4; i++)
	{
		if(bEnabled)
			EnableHamForward(gl_HamHook_TraceAttack[i]);
		else DisableHamForward(gl_HamHook_TraceAttack[i]);
	}
}

// [ Stocks ]
stock set_entity_anim(iEntity, iSequence)
{
	set_pev(iEntity, pev_frame, 1.0);
	set_pev(iEntity, pev_framerate, 1.0);
	set_pev(iEntity, pev_animtime, get_gametime());
	set_pev(iEntity, pev_sequence, iSequence);
}

stock get_speed_vector(const Float: vecOrigin1[3], const Float: vecOrigin2[3], Float: flSpeed, Float: vecVelocity[3]) 
{
	vecVelocity[0] = vecOrigin2[0] - vecOrigin1[0]; 
	vecVelocity[1] = vecOrigin2[1] - vecOrigin1[1]; 
	vecVelocity[2] = vecOrigin2[2] - vecOrigin1[2]; 

	new Float: flNum = floatsqroot(flSpeed * flSpeed / (vecVelocity[0]*vecVelocity[0] + vecVelocity[1]*vecVelocity[1] + vecVelocity[2]*vecVelocity[2])) 

	vecVelocity[0] *= flNum; 
	vecVelocity[1] *= flNum; 
	vecVelocity[2] *= flNum; 

	return 1; 
}

stock UTIL_CreateExplosion(iszModelIndex, Float: vecOrigin[3], Float: flUp = 0.0, iScale, iFramerate)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + flUp);
	write_short(iszModelIndex);
	write_byte(iScale); // Scale
	write_byte(iFramerate); // Framerate
	write_byte(TE_EXPLFLAG_NOSOUND); // Flags
	message_end();
}

stock UTIL_GetPosition(iPlayer, Float: flForward, Float: flRight, Float: flUp, Float: vecStart[]) 
{
	static Float: vecOrigin[3], Float: vecAngle[3], Float: vecForward[3], Float: vecRight[3], Float: vecUp[3];
	
	pev(iPlayer, pev_origin, vecOrigin);
	pev(iPlayer, pev_view_ofs, vecUp);
	xs_vec_add(vecOrigin, vecUp, vecOrigin);
	pev(iPlayer, pev_v_angle, vecAngle);
	
	angle_vector(vecAngle, ANGLEVECTOR_FORWARD, vecForward);
	angle_vector(vecAngle, ANGLEVECTOR_RIGHT, vecRight);
	angle_vector(vecAngle, ANGLEVECTOR_UP, vecUp);
	
	vecStart[0] = vecOrigin[0] + vecForward[0] * flForward + vecRight[0] * flRight + vecUp[0] * flUp;
	vecStart[1] = vecOrigin[1] + vecForward[1] * flForward + vecRight[1] * flRight + vecUp[1] * flUp;
	vecStart[2] = vecOrigin[2] + vecForward[2] * flForward + vecRight[2] * flRight + vecUp[2] * flUp;
}
 
stock UTIL_SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_DropWeapon(iPlayer, iSlot)
{
	static iEntity, iNext, szWeaponName[32];
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

	if(pev_valid(iEntity) == PDATA_SAFE)
	{
		do
		{
			iNext = get_pdata_cbase(iEntity, m_pNext, linux_diff_weapon);

			if(get_weaponname(get_pdata_int(iEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
				engclient_cmd(iPlayer, "drop", szWeaponName);
		}
		
		while((iEntity = iNext) > 0);
	}
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
				
				if (strlen(szSoundPath))
				{
					format(szSoundPath, charsmax(szSoundPath), "sound/%s", szSoundPath);
					engfunc(EngFunc_PrecacheGeneric, szSoundPath);
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

stock UTIL_WeaponList(iPlayer, bool: bEnabled)
{
	message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, iPlayer);
	write_string(bEnabled ? WEAPON_WEAPONLIST : WEAPON_REFERENCE);
	write_byte(iWeaponList[0]);
	write_byte(bEnabled ? WEAPON_DEFAULT_AMMO : iWeaponList[1]);
	write_byte(iWeaponList[2]);
	write_byte(iWeaponList[3]);
	write_byte(iWeaponList[4]);
	write_byte(iWeaponList[5]);
	write_byte(iWeaponList[6]);
	write_byte(iWeaponList[7]);
	message_end();
}