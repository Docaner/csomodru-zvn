#include <amxmodx>
#include <reapi>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

#if !defined zp_get_user_hero 
native zp_get_user_hero(pPlayer);
#endif

#define IsCustomItem(%0) 			(pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)

#define PDATA_SAFE 					2

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 		15/7.0
#define WEAPON_ANIM_SHOOT_TIME 		64/30.0
#define WEAPON_ANIM_SHOOT_E_TIME	31/30.0
#define WEAPON_ANIM_RELOAD_TIME 	91/30.0
#define WEAPON_ANIM_DRAW_TIME 		31/30.0

#define WEAPON_ANIM_IDLE_TIME_HERO 		15/7.0
#define WEAPON_ANIM_SHOOT_TIME_HERO 	64/30.0
#define WEAPON_ANIM_SHOOT_E_TIME_HERO	31/30.0
#define WEAPON_ANIM_RELOAD_TIME_HERO 	61/30.0
#define WEAPON_ANIM_DRAW_TIME_HERO		31/30.0

#define WEAPON_ANIM_IDLE 			0
#define WEAPON_ANIM_SHOOT 			random_num(1,2)
#define WEAPON_ANIM_SHOOT_E 		3
#define WEAPON_ANIM_RELOAD 			4
#define WEAPON_ANIM_DRAW 			5

/* ~ [ Extra Item ] ~ */
new const WEAPON_ITEM_NAME[] = 		"Infinity Silver";
const WEAPON_ITEM_COST = 			0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = 		"weapon_usp";
new const WEAPON_WEAPONLIST[] = 	"zp_br_cso/weapons3/weapon_infinityr";
new const WEAPON_NATIVE[] = 		"zp_give_user_infinityr";
new const WEAPON_MODEL_SHELL[] = 	"models/pshell.mdl";
new const WEAPON_MODEL_VIEW[] = 	"models/zp_br_cso/weapons3/v_infinityss.mdl";
new const WEAPON_MODEL_VIEW_HERO[] = "models/zp_br_cso/weapons3/v_infinitysr.mdl";

new const WEAPON_MODEL_PLAYER_HERO[] = 	"models/zp_br_cso/weapons3/p_infinitysr.mdl";
new const WEAPON_MODEL_WORLD[] = 	"models/zp_br_cso/other/w_weapons_b1.mdl";
new const WEAPON_SOUND_FIRE[] = 	"weapons/infir-1.wav";

const WEAPON_SPECIAL_CODE = 		1039;
const WEAPON_BODY = 				1;

const WEAPON_MAX_CLIP = 			8;
const WEAPON_MAX_CLIP_HERO = 		15;
const WEAPON_DEFAULT_AMMO = 		100;
const Float: WEAPON_RATE = 			0.1;
const Float: WEAPON_RATE_EX = 			0.15;
const Float: WEAPON_PUNCHANGLE = 	0.93;
const Float: WEAPON_PUNCHANGLE_HERO = 0.87;
const Float: WEAPON_DAMAGE = 		1.3;
const Float: WEAPON_DAMAGE_HERO = 	1.7;

new const iWeaponList[] = 
{
	6,  100,-1, -1, 1, 4, 16, 0 // weapon_usp
};

/* ~ [ Offsets ] ~ */
// Linux extra offsets
#define linux_diff_weapon 4
#define linux_diff_player 5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CBaseAnimating
#define m_flLastEventCheck 38

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
#define m_iShotsFired 64

// CBaseMonster
#define m_flNextAttack 83

// CBasePlayer
#define m_flEjectBrass 111
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

/* ~ [ Params ] ~ */
new gl_iszAllocString_Entity,
	gl_iszAllocString_ModelView,
	gl_iszAllocString_ModelViewHero, 
	gl_iszAllocString_ModelPlayerHero,

	gl_iszModelIndex_Shell,

	HamHook: gl_HamHook_TraceAttack[4],

	gl_iMsgID_Weaponlist,
	gl_iItemID;

public plugin_init()
{
	register_plugin("[ZP] Weapon: SVI Infinity Red", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	gl_iItemID = zp_register_extra_item(WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN);

	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);
	
	// Events
	register_event("HLTV", "EventHLTV", "a", "1=0", "2=0")

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
	
	gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,		"func_breakable",	"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,		"info_target",		"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,		"player",			"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,		"hostage_entity",	"CEntity__TraceAttack_Pre", false);
	
	fm_ham_hook(false);

	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW_HERO);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER_HERO)

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	
	// Precache sounds
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_FIRE);

	// Other
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	gl_iszAllocString_ModelViewHero = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW_HERO);
	gl_iszAllocString_ModelPlayerHero = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER_HERO);

	// Model Index
	gl_iszModelIndex_Shell = engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_SHELL);
}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem == gl_iItemID)
		Command_GiveWeapon(iPlayer);
}

public EventHLTV()
{
	for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++)
	{
		if(!is_user_alive(iPlayer) || !zp_get_user_hero(iPlayer)) continue;
	
		rg_remove_item(iPlayer, "weapon_usp", true);
	}
}

public CBasePlayer_Killed(iPlayer)
{
	if(zp_get_user_hero(iPlayer))
	{
		rg_remove_item(iPlayer, "weapon_usp", true);
		rg_remove_item(iPlayer, "weapon_knife", true);
	}
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
	
	if(zp_get_user_hero(iPlayer))
	{
		set_pdata_int(iEntity, m_iClip, WEAPON_MAX_CLIP_HERO, linux_diff_weapon);
	}
	else
	{
		set_pdata_int(iEntity, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	}
	
	UTIL_DropWeapon(iPlayer, 2);

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
	if(pev_valid(iPlayer) != PDATA_SAFE || !is_user_alive(iPlayer)) return;

	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return FMRES_IGNORED;

	static i, szClassName[32], iItem;
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

	for(i = 0; i < 6; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, linux_diff_weapon);

		if(iItem > 0 && IsCustomItem(iItem))
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
	
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CWeapon__Deploy_Post(iItem)
{
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, zp_get_user_hero(iPlayer) == 1 ? gl_iszAllocString_ModelViewHero : gl_iszAllocString_ModelView);
	
	if(zp_get_user_hero(iPlayer))
	{
		set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME_HERO, linux_diff_player);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME_HERO, linux_diff_weapon);
		
		set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayerHero);
	}
	else
	{
		set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
	}

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

	/*
	if(zp_get_user_hero(iPlayer))
	{
		set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayerHero);
		
		set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME_HERO, linux_diff_player);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME_HERO, linux_diff_weapon);
	}
	else
	{
		set_pev(iPlayer, pev_weaponmodel2, NULL_STRING);
		api_wpn_player_model_set(iPlayer, WEAPON_MODEL_PLAYER_GENERAL, BODY_MODEL_PLAYER, _, SEQUECE_MODEL_PLAYER);
		
		set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
	}
	*/
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return HAM_IGNORED;

	if(get_pdata_int(iItem, m_fInReload, linux_diff_weapon) == 1)
	{
		static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
		
		static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
		static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
		static j; j = min(WEAPON_MAX_CLIP - iClip, iAmmo);
		static h; h = min(WEAPON_MAX_CLIP_HERO - iClip, iAmmo);

		if(zp_get_user_hero(iPlayer))
		{
			set_pdata_int(iItem, m_iClip, iClip + h, linux_diff_weapon);
			set_pdata_int(iPlayer, iAmmoType, iAmmo - h, linux_diff_player);
			set_pdata_int(iItem, m_fInReload, 0, linux_diff_weapon);
		}
		else
		{
			set_pdata_int(iItem, m_iClip, iClip + j, linux_diff_weapon);
			set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
			set_pdata_int(iItem, m_fInReload, 0, linux_diff_weapon);
		}
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
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	
	if(zp_get_user_hero(iPlayer))
	{
		if(iClip >= WEAPON_MAX_CLIP_HERO) 
			return HAM_SUPERCEDE;
	}
	else
	{
		if(iClip >= WEAPON_MAX_CLIP)
		return HAM_SUPERCEDE
	}
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInReload, 1, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_RELOAD);
	
	if(zp_get_user_hero(iPlayer))
	{
		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME_HERO, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME_HERO, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME_HERO, linux_diff_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME_HERO, linux_diff_player);
	}
	else
	{
		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);
	}

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);
	
	if(zp_get_user_hero(iPlayer))
	{
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME_HERO, linux_diff_weapon);
	}
	else
	{
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);
	}

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return HAM_IGNORED;
	if(get_pdata_int(iItem, m_iShotsFired, linux_diff_weapon) != 0) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(get_pdata_int(iItem, m_iClip, linux_diff_weapon) == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);

		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT_E);
		
		if(zp_get_user_hero(iPlayer))
		{
			set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SHOOT_E_TIME_HERO, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_E_TIME_HERO, linux_diff_weapon);
		}
		else
		{
			set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SHOOT_E_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_E_TIME, linux_diff_weapon);
		}

		return HAM_SUPERCEDE;
	}

	static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
	static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
	fm_ham_hook(true);

	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);

	unregister_forward(FM_TraceLine, fw_TraceLine, true);
	unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
	fm_ham_hook(false);

	static Float: vecPunchangle[3];
	pev(iPlayer, pev_punchangle, vecPunchangle);
	if(zp_get_user_hero(iPlayer))
	{
		vecPunchangle[0] *= WEAPON_PUNCHANGLE_HERO;
		vecPunchangle[1] *= WEAPON_PUNCHANGLE_HERO;
		vecPunchangle[2] *= WEAPON_PUNCHANGLE_HERO;
	}
	else
	{
		vecPunchangle[0] *= WEAPON_PUNCHANGLE;
		vecPunchangle[1] *= WEAPON_PUNCHANGLE;
		vecPunchangle[2] *= WEAPON_PUNCHANGLE;
	}
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_int(iItem, m_iShellId, gl_iszModelIndex_Shell, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flEjectBrass, get_gametime(), linux_diff_player);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_RATE, linux_diff_weapon);
	
	if(zp_get_user_hero(iPlayer))
	{
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME_HERO, linux_diff_weapon);
	}
	else
	{
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
	}

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	if(get_pdata_int(iItem, m_iClip, linux_diff_weapon) <= 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float( iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon );
		set_pdata_float( iItem, m_flNextSecondaryAttack, 0.2, linux_diff_weapon );
	}

	ExecuteHamB( Ham_Weapon_PrimaryAttack, iItem );
	set_pdata_int( iItem, m_iShotsFired, 0, linux_diff_weapon );

	set_pdata_float( iItem, m_flNextPrimaryAttack, WEAPON_RATE_EX, linux_diff_weapon );
	set_pdata_float( iItem, m_flNextSecondaryAttack, WEAPON_RATE_EX, linux_diff_weapon );

	return HAM_SUPERCEDE;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
	if(pev_valid(iAttacker) != PDATA_SAFE || !is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(iItem <= 0 || !IsCustomItem(iItem)) return;
	
	if(zp_get_user_hero(iAttacker))
		SetHamParamFloat(3, flDamage * WEAPON_DAMAGE_HERO);
	else
		SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

// [ Other ]
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

// [ Stocks ]
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
	if(pev_valid(iPlayer) != PDATA_SAFE ) return;
	static iEntity, szWeaponName[32];
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);
	while ( pev_valid( iEntity ) == 2 )
	{
		pev( iEntity, pev_classname, szWeaponName, charsmax( szWeaponName ) );
		engclient_cmd( iPlayer, "drop", szWeaponName );

		iEntity = get_pdata_cbase( iEntity, m_pNext, linux_diff_weapon );
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