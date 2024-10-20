#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>
#include <zpe_knokcback>
#include <reapi>

// native zp_set_item_max_clip(iPlayer, iValue);
// native zp_set_item_max_ammo(iPlayer, iValue);
// forward zp_weapon_buyammo(iPlayer, iActiveItem);
native zp_get_user_hero(id);

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = "weapon_ak47";
new const WEAPON_WEAPONLIST[] = "zp_br_cso/weapons2/weapon_svdex_b2";
new const WEAPON_NATIVE[] = "zp_give_user_svdex";
new const WEAPON_MODEL_VIEW[] = "models/zp_br_cso/weapons2/v_svdex.mdl";
new const WEAPON_MODEL_PLAYER[] = "models/zp_br_cso/weapons2/p_svdex.mdl";
new const WEAPON_MODEL_WORLD[] = "models/zp_br_cso/other/w_weapons_b1.mdl";
new const WEAPON_SOUNDS[][] =
{
	"weapons/svdex_shoot1.wav",
	"weapons/svdex_shoot2.wav"
};
new const WEAPON_RESOURCES[][] =
{
	// Custom resources precache, sprites for example
	"sprites/zp_br_cso/weapons2/hud2/640hud42.spr",
	"sprites/zp_br_cso/weapons2/hud2/640hud51.spr"
};

const WEAPON_SPECIAL_CODE = 5004;
const WEAPON_MODEL_WORLD_BODY = 39;

const WEAPON_MAX_CLIP = 20;
const WEAPON_MAX_GRENADES = 5;
const WEAPON_DEFAULT_AMMO = 90;
const Float: WEAPON_RATE = 0.382;
const Float: WEAPON_DAMAGE = 3.95;

#define WEAPON_RECOIL -1.33, 0.0, 0.0

new const iWeaponList[] = 
{
	2, 90, -1, -1, 0, 1, 28, 0 // weapon_ak47
};

/* ~ [ Entity: Grenade Missile ] ~ */
new const ENTITY_GRENADE_CLASSNAME[] = "ent_svdex_gren_x";
new const ENTITY_GRENADE_MODEL[] = "models/zp_br_cso/weapons2/s_grenade_m79.mdl";
new const ENTITY_GRENADE_SOUND[] = "weapons/svdex_exp.wav";
new const ENTITY_GRENADE_SPRITE[] = "sprites/zp_br_cso/grenade/ef_fgrenade.spr";
new const ENTITY_GRENADE_TRAIL[] = "sprites/laserbeam.spr";
const Float: ENTITY_GRENADE_SPEED = 1000.0;
const Float: ENTITY_GRENADE_RADIUS = 150.0;
const Float: ENTITY_GRENADE_DAMAGE = 500.0;
#define DMG_GRENADE (1<<24)
const ENTITY_GRENADE_DMGTYPE = DMG_GRENADE;

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 2/16.0
#define WEAPON_ANIM_RELOAD_TIME 115/30.0
#define WEAPON_ANIM_DRAW_TIME 31/30.0
#define WEAPON_ANIM_SHOOT_TIME 31/30.0
#define WEAPON_ANIM_SHOOT_EX_TIME 85/30.0
#define WEAPON_ANIM_CHANGE_TIME 46/30.0

enum _: eAnimList
{
	WEAPON_ANIM_IDLE = 0,
	WEAPON_ANIM_RELOAD,
	WEAPON_ANIM_DRAW,
	WEAPON_ANIM_SHOOT,
	WEAPON_ANIM_SHOOT,
	WEAPON_ANIM_CHANGE_TO_EX,
	WEAPON_ANIM_IDLE_EX,
	WEAPON_ANIM_SHOOT_EX,
	WEAPON_ANIM_SHOOT_LAST_EX,
	WEAPON_ANIM_CHANGE
};

enum _: eWeaponState
{
	WPNSTATE_ASSAULT_RIFLE = 0,
	WPNSTATE_GRENADE_LAUNCHER
};

/* ~ [ Params ] ~ */
new gl_iszAllocString_Entity,
	gl_iszAllocString_ModelView,
	gl_iszAllocString_ModelPlayer,
	gl_iszAllocString_InfoTarget,
	gl_iszAllocString_Missile,

	gl_iszModelIndex_Trail,
	gl_iszModelIndex_Explode,

	HamHook: gl_HamHook_TraceAttack[4],

	gl_iMsgID_Weaponlist,
	gl_iMsgID_StatusIcon

/* ~ [ Macroses ] ~ */
#define PDATA_SAFE 2

#define m_iGrenades m_iGlock18ShotsFired

#define IsValidEntity(%0) (pev_valid(%0) == PDATA_SAFE)
#define IsCustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)

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
#define m_iGlock18ShotsFired 70
#define m_iWeaponState 74
#define m_flNextReload 75

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_iHideHUD 361
#define m_iClientHideHUD 362
#define m_iFOV 363
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
	register_plugin("[ZP] Weapon: SVDeX", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	// Forwards
	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);
	
	// Events
	register_event("HLTV", "EventHLTV", "a", "1=0", "2=0")

	// Weapon
	RegisterHam(Ham_Item_Holster,			WEAPON_REFERENCE,	"CWeapon__Holster_Post", true);
	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	WEAPON_REFERENCE,	"CWeapon__SecondaryAttack_Pre", false);
	
	// Killed Pre
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed", false);

	// Entity
	RegisterHam(Ham_Touch,					"info_target",		"CEntity__Touch_Pre", false);
	
	// Trace Attack
	gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,	"func_breakable",	"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",		"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",			"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",	"CEntity__TraceAttack_Pre", false);
	
	fm_ham_hook(false);

	// Messages
	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	gl_iMsgID_StatusIcon = get_user_msgid("StatusIcon");

	// Alloc String
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);
	gl_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");
	gl_iszAllocString_Missile = engfunc(EngFunc_AllocString, ENTITY_GRENADE_CLASSNAME);
}

public plugin_precache()
{
	new i;

	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, ENTITY_GRENADE_MODEL);

	// Precache generic
	new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/%s.txt", WEAPON_WEAPONLIST);
	engfunc(EngFunc_PrecacheGeneric, szWeaponList);

	for(i = 0; i < sizeof WEAPON_RESOURCES; i++)
		engfunc(EngFunc_PrecacheGeneric, WEAPON_RESOURCES[i]);
	
	// Precache sounds
	engfunc(EngFunc_PrecacheSound, ENTITY_GRENADE_SOUND);

	for(i = 0; i < sizeof WEAPON_SOUNDS; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUNDS[i]);

	// Model Index
	gl_iszModelIndex_Trail = engfunc(EngFunc_PrecacheModel, ENTITY_GRENADE_TRAIL);
	gl_iszModelIndex_Explode = engfunc(EngFunc_PrecacheModel, ENTITY_GRENADE_SPRITE);
}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

public Command_HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

public EventHLTV()
{
	for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++)
	{
		if(!is_user_alive(iPlayer) || !zp_get_user_hero(iPlayer)) continue;
	
		rg_remove_item(iPlayer, "weapon_ak47", true);
	}
}

// ReGameDLL
public CBasePlayer_Killed(iPlayer)
{
	if(zp_get_user_hero(iPlayer))
	{
		rg_remove_item(iPlayer, "weapon_ak47", true);
		rg_remove_item(iPlayer, "weapon_knife", true);
	}
}

public Command_GiveWeapon(iPlayer)
{
	static iWeapon; iWeapon = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
	if(!IsValidEntity(iWeapon)) return FM_NULLENT;

	set_pev(iWeapon, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, iWeapon);
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	set_pdata_int(iWeapon, m_iGrenades, WEAPON_MAX_GRENADES, linux_diff_weapon);
	UTIL_DropWeapon(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));

	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iWeapon))
	{
		set_pev(iWeapon, pev_flags, pev(iWeapon, pev_flags) | FL_KILLME);
		return 0;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, iWeapon, iPlayer);

	new iAmmoType = m_rgAmmo + get_pdata_int(iWeapon, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, m_rgAmmo, linux_diff_player) < WEAPON_DEFAULT_AMMO)
		set_pdata_int(iPlayer, iAmmoType, WEAPON_DEFAULT_AMMO, linux_diff_player);

	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return 1;
}

public zp_user_infected_pre(iPlayer)
{
	if(pev_valid(iPlayer) != 2 || !is_user_connected(iPlayer)) return;


	new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	UTIL_StatusIcon(iItem, iPlayer, 0);
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(pev_valid(iPlayer) != 2 || !is_user_connected(iPlayer)) return;

	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, 2.0);
}

public FM_Hook_SetModel_Pre(iEntity)
{
	if(pev_valid(iEntity) != 2) return FMRES_IGNORED;

	static i, szClassName[32], iItem;
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

	for(i = 0; i < 6; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, linux_diff_weapon);

		if(IsValidEntity(iItem) && IsCustomItem(iItem))
		{
			engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
			set_pev(iEntity, pev_body, WEAPON_MODEL_WORLD_BODY);
			
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;
public FM_Hook_TraceLine_Post(const Float: vecOrigin1[3], const Float: vecOrigin2[3], iFlags, iAttacker, iTrace)
{
	if(iFlags & IGNORE_MONSTERS) return FMRES_IGNORED;
	if(!is_user_alive(iAttacker)) return FMRES_IGNORED;

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

/* ~ [ HamSandwich ] ~ */
public CWeapon__Holster_Post(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem) ) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pdata_int(iPlayer, m_iFOV, 90, linux_diff_player);
	
	UTIL_StatusIcon(iItem, iPlayer, 0);
	set_pdata_int(iItem, m_iWeaponState, WPNSTATE_ASSAULT_RIFLE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CWeapon__Deploy_Post(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
	set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

	UTIL_StatusIcon(iItem, iPlayer, 0);
	UTIL_StatusIcon(iItem, iPlayer, 1);
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);

	if(get_pdata_int(iItem, m_fInReload, linux_diff_weapon) == 1)
	{
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
		static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
		static j; j = min(WEAPON_MAX_CLIP - iClip, iAmmo);

		set_pdata_int(iItem, m_iClip, iClip + j, linux_diff_weapon);
		set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
		set_pdata_int(iItem, m_fInReload, 0, linux_diff_weapon);
	}

	static iButton; iButton = pev(iPlayer, pev_button);
	if(iButton & IN_ATTACK2 && get_pdata_float(iItem, m_flNextSecondaryAttack, linux_diff_weapon) < 0.0)
	{
		ExecuteHamB(Ham_Weapon_SecondaryAttack, iItem);

		iButton &= ~IN_ATTACK2;
		set_pev(iPlayer, pev_button, iButton);
	}

	return HAM_IGNORED;
}

public CWeapon__AddToPlayer_Post(iItem, iPlayer)
{
	if(IsValidEntity(iItem) && IsCustomItem(iItem)) UTIL_WeaponList(iPlayer, true);
	else if(pev(iItem, pev_impulse) == 0) UTIL_WeaponList(iPlayer, false);
}

public CWeapon__Reload_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;
	if(get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon)) return HAM_SUPERCEDE;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInReload, 1, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_RELOAD);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iWeaponState; iWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, iWeaponState ? WEAPON_ANIM_IDLE_EX : WEAPON_ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(!iClip)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static Float: flIdleTime, Float: flNextAttackTime, iSound, iAnim;

	if(get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon))
	{
		static iGrenades; iGrenades = get_pdata_int(iItem, m_iGrenades, linux_diff_weapon);
		if(!iGrenades)
		{
			ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
			set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

			return HAM_SUPERCEDE;
		}

		iGrenades--;
		iSound = 1;
		iAnim = !iGrenades ? WEAPON_ANIM_SHOOT_LAST_EX : WEAPON_ANIM_SHOOT_EX;
		flIdleTime = flNextAttackTime = !iGrenades ? WEAPON_ANIM_SHOOT_TIME : WEAPON_ANIM_SHOOT_EX_TIME;

		UTIL_StatusIcon(iItem, iPlayer, 0);
		set_pdata_int(iItem, m_iGrenades, iGrenades, linux_diff_weapon);
		UTIL_StatusIcon(iItem, iPlayer, 1);

		CWeapon__Create_Grenade(iPlayer, iItem);
	}
	else
	{
		static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
		static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
		fm_ham_hook(true);

		ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);

		unregister_forward(FM_TraceLine, fw_TraceLine, true);
		unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
		fm_ham_hook(false);

		// static Float: vecPunchangle[3]; pev(iPlayer, pev_punchangle, vecPunchangle);
		// vecPunchangle[0] *= WEAPON_RECOIL;
		// vecPunchangle[1] *= WEAPON_RECOIL;
		// vecPunchangle[2] *= WEAPON_RECOIL;
		// set_pev(iPlayer, pev_punchangle, vecPunchangle);
		
		set_pev(iPlayer, pev_punchangle, Float: { WEAPON_RECOIL });

		iSound = 0;
		iAnim = WEAPON_ANIM_SHOOT;
		flIdleTime = WEAPON_ANIM_SHOOT_TIME;
		flNextAttackTime = WEAPON_RATE;
	}

	UTIL_SendWeaponAnim(iPlayer, iAnim);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[iSound], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_float(iItem, m_flNextPrimaryAttack, flNextAttackTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, flNextAttackTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, flIdleTime, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iWeaponState; iWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);
	if(!iWeaponState) if(!get_pdata_int(iItem, m_iGrenades, linux_diff_weapon)) return HAM_SUPERCEDE;

	iWeaponState = !iWeaponState;

	static iAnim; iAnim = !iWeaponState ? WEAPON_ANIM_CHANGE : WEAPON_ANIM_CHANGE_TO_EX;
	UTIL_SendWeaponAnim(iPlayer, iAnim);

	if(iWeaponState)
	{
		set_pdata_int(iPlayer, m_iFOV, 89, linux_diff_player);
	}
	else
	{
		set_pdata_int(iPlayer, m_iFOV, 90, linux_diff_player);
	}

	set_pdata_int(iItem, m_iWeaponState, iWeaponState, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CEntity__Touch_Pre(iEntity, iTouch)
{
	if(!IsValidEntity(iEntity)) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Missile)
	{
		new iOwner = pev(iEntity, pev_owner);
		if(iTouch == iOwner) return HAM_SUPERCEDE;
		if(pev(iTouch, pev_classname) == gl_iszAllocString_Missile) return HAM_SUPERCEDE;

		/* По тимейтам не ебашит */
		if(is_user_connected(iTouch) && !zp_get_user_zombie(iTouch))
			return HAM_SUPERCEDE;

		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		emit_sound(iEntity, CHAN_ITEM, ENTITY_GRENADE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_CreateExplosion(vecOrigin, random_float(20.0, 30.0), gl_iszModelIndex_Explode, random_num(16, 20), 32, 2|4|8);

		// new iItem = get_pdata_cbase(iOwner, m_rpgPlayerItems + 1, linux_diff_weapon);
		new iItem = pev(iEntity, pev_dmg_inflictor);
		if(IsValidEntity(iItem) && IsCustomItem(iItem))
		{
			new iVictim = FM_NULLENT;
			new Float: flDamage;
			while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_GRENADE_RADIUS)) > 0)
			{
				if(pev(iVictim, pev_takedamage) == DAMAGE_NO) 
					continue;

				if(is_user_alive(iVictim))
				{
					if(iVictim == iOwner || !zp_get_user_zombie(iVictim) || !is_wall_between_points(iEntity, iVictim))
						continue;
				}
				else if(pev(iVictim, pev_solid) == SOLID_BSP)
				{
					if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
						continue;
				}

				if(is_user_alive(iVictim) && zp_get_user_zombie(iVictim))
				{
					set_pev(iVictim, pev_punchangle, Float: { 10.0, 10.0, 10.0 });
					set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);
				}
				
				flDamage = ENTITY_GRENADE_DAMAGE * random_float(0.75, 1.25);
				ExecuteHamB(Ham_TakeDamage, iVictim, iItem, iOwner, flDamage, ENTITY_GRENADE_DMGTYPE);
				zp_set_user_velocitymifier(iVictim, 0.4)
			}
		}

		set_pev(iEntity, pev_flags, FL_KILLME);
	}

	return HAM_IGNORED;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
	if(!IsValidEntity(iAttacker) || !is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;

	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

/* ~ [ Other ] ~ */
public CWeapon__Create_Grenade(iPlayer, iItem)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!IsValidEntity(iEntity)) return FM_NULLENT;

	new Float: vecTemp[3]; pev(iPlayer, pev_view_ofs, vecTemp);
	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);

	xs_vec_add(vecOrigin, vecTemp, vecTemp);
	UTIL_GetWeaponPosition(iPlayer, 20.0, get_cvar_num("cl_righthand") ? 5.0 : -5.0, 0.0, vecOrigin);

	engfunc(EngFunc_TraceLine, vecTemp, vecOrigin, DONT_IGNORE_MONSTERS, iPlayer, 0);
	get_tr2(0, TR_vecEndPos, vecOrigin);

	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
	new Float: vecVelocity[3]; xs_vec_copy(vecForward, vecVelocity);

	// Speed for missile
	xs_vec_mul_scalar(vecVelocity, ENTITY_GRENADE_SPEED, vecVelocity);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Missile);
	set_pev(iEntity, pev_movetype, MOVETYPE_TOSS);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_dmg_inflictor, iItem);
	set_pev(iEntity, pev_velocity, vecVelocity);
	set_pev(iEntity, pev_gravity, 1.0);

	engfunc(EngFunc_VecToAngles, vecVelocity, vecAngles);
	set_pev(iEntity, pev_angles, vecAngles);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_GRENADE_MODEL);
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	// https://github.com/baso88/SC_AngelScript/wiki/TE_BEAMFOLLOW
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(gl_iszModelIndex_Trail); // Model Index
	write_byte(7); // Life
	write_byte(5); // Width
	write_byte(180); // Red
	write_byte(180); // Green
	write_byte(180); // Blue
	write_byte(220); // Alpha
	message_end();

	return iEntity;
}

public fm_ham_hook(bool: bEnabled)
{
	if(bEnabled)
	{
		EnableHamForward(gl_HamHook_TraceAttack[0]);
		EnableHamForward(gl_HamHook_TraceAttack[1]);
		EnableHamForward(gl_HamHook_TraceAttack[2]);
		EnableHamForward(gl_HamHook_TraceAttack[3]);
	}
	else 
	{
		DisableHamForward(gl_HamHook_TraceAttack[0]);
		DisableHamForward(gl_HamHook_TraceAttack[1]);
		DisableHamForward(gl_HamHook_TraceAttack[2]);
		DisableHamForward(gl_HamHook_TraceAttack[3]);
	}
}

/* ~ [ Stocks ] ~ */
stock is_wall_between_points(iPlayer, iEntity)
{
	if(!is_user_alive(iEntity)) return 0;

	new iTrace = create_tr2();
	new Float: flStart[3], Float: flEnd[3], Float: flEndPos[3];

	pev(iPlayer, pev_origin, flStart);
	pev(iEntity, pev_origin, flEnd);

	engfunc(EngFunc_TraceLine, flStart, flEnd, IGNORE_MONSTERS, iPlayer, iTrace);
	get_tr2(iTrace, TR_vecEndPos, flEndPos);

	free_tr2(iTrace);

	return xs_vec_equal(flEnd, flEndPos);
}

stock UTIL_GetWeaponPosition(iPlayer, Float: flForward, Float: flRight, Float: flUp, Float: vecStart[]) 
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

	if(pev(iPlayer, pev_iuser1))
		return;

	static i, iCount, pSpectator, aSpectators[MAX_PLAYERS];
	get_players(aSpectators, iCount, "bch");

	for(i = 0; i < iCount; i++)
	{
		pSpectator = aSpectators[ i ];

		if(pev(pSpectator, pev_iuser1) != OBS_IN_EYE)
			continue;

		if(pev(pSpectator, pev_iuser2) != iPlayer)
			continue;

		set_pev(pSpectator, pev_weaponanim, iAnim);

		message_begin(MSG_ONE, SVC_WEAPONANIM, .player = pSpectator);
		write_byte(iAnim);
		write_byte(0);
		message_end();
	}
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

stock UTIL_CreateExplosion(Float: vecOrigin[3], Float: flUp, iszModelIndex, iScale, iFrameRate, iFlags)
{
	// https://github.com/baso88/SC_AngelScript/wiki/TE_EXPLOSION
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_EXPLOSION); // TE
	engfunc(EngFunc_WriteCoord, vecOrigin[0]); // Position X
	engfunc(EngFunc_WriteCoord, vecOrigin[1]); // Position Y
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + flUp); // Position Z
	write_short(iszModelIndex); // Model Index
	write_byte(iScale); // Scale
	write_byte(iFrameRate); // Framerate
	write_byte(iFlags); // Flags
	message_end();
}

stock UTIL_StatusIcon(iItem, iPlayer, iUpdateMode)
{
	new szSprite[33];
	new iClip = get_pdata_int(iItem, m_iGrenades, linux_diff_weapon);
	new iStatus = 1;
	if(iClip > 9)
	{
		format(szSprite, charsmax(szSprite), "number_9");
		iStatus = 2;
	}
	else format(szSprite, charsmax(szSprite), "number_%d", iClip);

	message_begin(MSG_ONE, gl_iMsgID_StatusIcon, { 0, 0, 0 }, iPlayer);
	if(iUpdateMode && iClip > 0) write_byte(iStatus);
	else write_byte(0);
	write_string(szSprite);
	write_byte(0);
	write_byte(128);
	write_byte(255);
	message_end();
}


/*public UTIL_UpdateHideWeapon(iPlayer, iFlags)
{
	message_begin(MSG_ONE, gl_iMsgID_HideWeapon, _, iPlayer);
	write_byte(iFlags);
	message_end();

	set_pdata_int(iPlayer, m_iHideHUD, iFlags, linux_diff_player);
	set_pdata_int(iPlayer, m_iClientHideHUD, iFlags, linux_diff_player);
}*/

stock UTIL_DropWeapon(iPlayer, iSlot)
{
	if(pev_valid(iPlayer) != 2 ) return;
	static iEntity, szWeaponName[32];
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot);
	while ( pev_valid( iEntity ) == 2 )
	{
		pev( iEntity, pev_classname, szWeaponName, charsmax( szWeaponName ) );
		engclient_cmd( iPlayer, "drop", szWeaponName );

		iEntity = get_pdata_cbase( iEntity, m_pNext, 4 );
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
