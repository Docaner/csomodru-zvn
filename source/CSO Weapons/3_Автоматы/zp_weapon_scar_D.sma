/*
 *		[1.0] - First release
 */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <zpe_knokcback>
#include <xs>
#include <reapi>

// native zp_set_item_max_clip(iPlayer, iValue);
// native zp_set_item_max_ammo(iPlayer, iValue);
// forward zp_weapon_buyammo(iPlayer, iActiveItem);

/* ~ [ Extra Item ] ~ */
new const WEAPON_ITEM_NAME[] = "SCAR OZ-D";
const WEAPON_ITEM_COST = 0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = "weapon_ak47";
new const WEAPON_WEAPONLIST[] = "zp_br_cso/weapons2/weapon_y20s2scard";
new const WEAPON_NATIVE[] = "zp_give_user_scard";
new const WEAPON_MODEL_VIEW[] = "models/zp_br_cso/weapons2/v_y20s2scard.mdl";

new const WEAPON_MODEL_WORLD[] = "models/zp_br_cso/weapons2/w_scarsub.mdl";
new const WEAPON_SOUNDS[][] =
{
	"weapons/y20s2scard-1.wav",
	"weapons/y20s2scard-2.wav"
};
new const WEAPON_RESOURCES[][] =
{
	// Custom resources precache, sprites for example
	"sprites/zp_br_cso/weapons2/hud/640hud198.spr"
};
new const WEAPON_SPRITE_HIT[] = "sprites/zp_br_cso/weapons2/hud/ef_y20s2scarhit.spr";

const WEAPON_SPECIAL_CODE = 1013;
const WEAPON_MODEL_WORLD_BODY = 2;

const WEAPON_MAX_CLIP = 40;
const WEAPON_DEFAULT_AMMO = 90;
const WEAPON_GRENADES_COUNT = 5;
const Float: WEAPON_RATE = 0.102;
const Float: WEAPON_PUNCHANGLE = 0.88;
const Float: WEAPON_DAMAGE = 1.395;

new const iWeaponList[] = 
{
	2, 90, -1, -1, 0, 1, 28, 0 // weapon_ak47
};

/* ~ [ Custom MuzzleFlash ] ~ */
// When used, may cause performance problems on the server system
// If u don't need custom MuzzleFlash, just comment line from below (// #define CUSTOM_MUZZLEFLASH_ENABLED)
// #define CUSTOM_MUZZLEFLASH_ENABLED
#if defined CUSTOM_MUZZLEFLASH_ENABLED
	new const ENTITY_MUZZLE_CLASSNAME[] = "muzzle_scard";
	new const ENTITY_MUZZLE_SPRITE[] = "sprites/zp_br_cso/weapons2/hud/muzzleflash132.spr";
	const Float: ENTITY_MUZZLE_NEXTTHINK = 0.2;
#endif

/* ~ [ Entity: Grenade Missile ] ~ */
new const ENTITY_GRENADE_CLASSNAME[] = "ent_scargrenade_x";
// Im not use here grenade, bcz model of grenade is have in WEAPON_MODEL_WORLD
new const ENTITY_GRENADE_SPRITE[] = "sprites/zp_br_cso/weapons2/hud/ef_y20s2scar.spr";
new const ENTITY_GRENADE_SOUND[] = "weapons/y20s2scard-2_exp.wav";
const Float: ENTITY_GRENADE_SPEED = 1000.0;
const Float: ENTITY_GRENADE_RADIUS = 100.0;
const Float: ENTITY_GRENADE_DAMAGE_HIT = 230.0;
const Float: ENTITY_GRENADE_DAMAGE_EXP = 300.0;
#define DMG_GRENADE (1<<24)
const ENTITY_GRENADE_DMGTYPE = DMG_GRENADE;

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 91/30.0
#define WEAPON_ANIM_SHOOT_TIME 21/30.0
#define WEAPON_ANIM_RELOAD_TIME 86/30.0
#define WEAPON_ANIM_DRAW_TIME 31/30.0

#define WEAPON_ANIM_IDLE 0
#define WEAPON_ANIM_RELOAD 1
#define WEAPON_ANIM_DRAW 2
#if defined CUSTOM_MUZZLEFLASH_ENABLED
	#define WEAPON_ANIM_SHOOT 6
#else
	#define WEAPON_ANIM_SHOOT 3
#endif
#define WEAPON_ANIM_SHOOT_EX 9

/* ~ [ Params ] ~ */
new gl_iszAllocString_Entity,
	gl_iszAllocString_ModelView,
	gl_iszAllocString_InfoTarget,
	gl_iszAllocString_ExplodePlayer,
	gl_iszAllocString_GrenMissile,

	#if defined CUSTOM_MUZZLEFLASH_ENABLED
		gl_iszAllocString_MuzzleFlash,
	#endif

	gl_iszModelIndex_Explode,
	gl_iszModelIndex_HitSprite,

	HamHook: gl_HamHook_TraceAttack[4],

	gl_iMsgID_Weaponlist,
	gl_iMsgID_StatusIcon,
	gl_iItemID;

/* ~ [ Macroses ] ~ */
#define PDATA_SAFE 2
#define DMG_GRENADE (1<<24)

#define is_user_valid(%0) (%0 && 0 < %0 < 33)
#define IsValidEntity(%0) (pev_valid(%0) == PDATA_SAFE)
#define IsCustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define GetGrenadesCount(%0) (get_pdata_int(%0, m_iGrenadesCount, linux_diff_weapon))

#define m_iGrenadesCount m_iWeaponState
#define pev_victims_attached pev_iuser1

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
#define m_iWeaponState 74
#define m_flNextReload 75

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
	register_plugin("[ZP] Weapon: SCAR OZ-D", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	// Forwards
	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);

	RegisterHookChain(RG_CSGameRules_RestartRound, "@RG_RestartRound_Post", true);

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
	RegisterHam(Ham_Touch,					"info_target",		"CEntity__Touch_Pre", false);
	RegisterHam(Ham_Think,					"info_target",		"CEntity__Think_Pre", false);

	#if defined CUSTOM_MUZZLEFLASH_ENABLED
		RegisterHam(Ham_Think,					"env_sprite",		"CMuzzleFlash__Think_Pre", false);
	#endif
	
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
	gl_iMsgID_StatusIcon = get_user_msgid("StatusIcon");

	// Alloc String
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	gl_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");
	gl_iszAllocString_ExplodePlayer = engfunc(EngFunc_AllocString, "ent_expplayer_x");
	gl_iszAllocString_GrenMissile = engfunc(EngFunc_AllocString, ENTITY_GRENADE_CLASSNAME);

	#if defined CUSTOM_MUZZLEFLASH_ENABLED
		gl_iszAllocString_MuzzleFlash = engfunc(EngFunc_AllocString, ENTITY_MUZZLE_CLASSNAME);
	#endif
}

@RG_RestartRound_Post()
{
	new iPrimaryEntity = NULLENT;

	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(!is_user_alive(iPlayer)) continue;

		iPrimaryEntity = get_member(iPlayer, m_rgpPlayerItems, PRIMARY_WEAPON_SLOT);

		if(is_nullent(iPrimaryEntity) || !IsCustomItem(iPrimaryEntity)) continue;

		set_pdata_int(iPrimaryEntity, m_iGrenadesCount, WEAPON_GRENADES_COUNT, linux_diff_weapon);
	}
}

public plugin_precache()
{
	new i;

	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

	#if defined CUSTOM_MUZZLEFLASH_ENABLED
		engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITE);
	#endif

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
	gl_iszModelIndex_Explode = engfunc(EngFunc_PrecacheModel, ENTITY_GRENADE_SPRITE);
	gl_iszModelIndex_HitSprite = engfunc(EngFunc_PrecacheModel, WEAPON_SPRITE_HIT);
}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

public Command_HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

public Command_GiveWeapon(iPlayer)
{
	static iWeapon; iWeapon = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
	if(!IsValidEntity(iWeapon)) return FM_NULLENT;

	set_pev(iWeapon, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, iWeapon);
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	UTIL_DropWeapon(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));

	set_pdata_int(iWeapon, m_iGrenadesCount, WEAPON_GRENADES_COUNT, linux_diff_weapon);

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

/* ~ [ Zombie Plague ] ~ */
public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem == gl_iItemID)
		Command_GiveWeapon(iPlayer);
}

public zp_user_infected_pre(iPlayer)
{
	if(!is_user_connected(iPlayer)) return;

	new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(IsValidEntity(iItem) && IsCustomItem(iItem))
		UTIL_StatusIcon(iItem, iPlayer, 0);
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(!is_user_alive(iPlayer)) return;

	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
	static szClassName[32];
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

	static i, iItem;
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

	if(is_user_alive(pHit) && zp_get_user_zombie(pHit))
	{
		static Float: vecOrigin[3]; pev(pHit, pev_origin, vecOrigin);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2]);
		write_short(gl_iszModelIndex_HitSprite);
		write_byte(3); // Scale
		write_byte(random_num(16, 24)); // Framerate
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES);
		message_end();
	}

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
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	
	UTIL_StatusIcon(iItem, iPlayer, 0);
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

	// set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	// set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);
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

	#if defined CUSTOM_MUZZLEFLASH_ENABLED
		UTIL_CreateMuzzleFlash(iPlayer, ENTITY_MUZZLE_SPRITE, random_float(0.05, 0.07), 200.0, 1);
	#endif

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT + random_num(0, 2));
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;
	if(!GetGrenadesCount(iItem))
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextSecondaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT_EX);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	UTIL_StatusIcon(iItem, iPlayer, 0);
	set_pdata_int(iItem, m_iGrenadesCount, GetGrenadesCount(iItem) - 1, linux_diff_weapon);
	UTIL_StatusIcon(iItem, iPlayer, 1);

	CWeapon__Create_GrenadeMissile(iPlayer, iItem);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CEntity__Touch_Pre(iEntity, iTouch)
{
	if(!IsValidEntity(iEntity)) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_GrenMissile)
	{
		new iOwner = pev(iEntity, pev_owner);
		if(iTouch == iOwner) return HAM_SUPERCEDE;

		/* По тимейтам не ебашит */
		if(is_user_connected(iTouch) && !zp_get_user_zombie(iTouch))
			return HAM_SUPERCEDE;

		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		new iItem = pev(iEntity, pev_dmg_inflictor);
		if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;

		if(is_user_valid(iTouch))
		{
			if(is_user_alive(iTouch))
			{
				new bitVictimsAttached = pev(iEntity, pev_victims_attached);
				if(zp_get_user_zombie(iTouch) && !(bitVictimsAttached & (1<<iTouch)))
				{
					bitVictimsAttached |= (1<<iTouch);
					set_pev(iEntity, pev_victims_attached, bitVictimsAttached);

					CPlayer__Create_ExplodePlayer(iOwner, iTouch, iItem);

					set_pdata_int(iTouch, m_LastHitGroup, HIT_GENERIC, linux_diff_player);
					ExecuteHamB(Ham_TakeDamage, iTouch, iItem, iOwner, ENTITY_GRENADE_DAMAGE_HIT, ENTITY_GRENADE_DMGTYPE);
					zp_set_user_velocitymifier(iTouch, 0.6)
				}
			}

			return HAM_SUPERCEDE;
		}
		else set_pev(iEntity, pev_nextthink, get_gametime());
	}

	return HAM_IGNORED;
}

public CEntity__Think_Pre(iEntity)
{
	if(!IsValidEntity(iEntity)) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_GrenMissile)
	{
		new iItem = pev(iEntity, pev_dmg_inflictor);
		if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;

		new iOwner = pev(iEntity, pev_owner);
		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		emit_sound(iEntity, CHAN_ITEM, ENTITY_GRENADE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_CreateExplosion(gl_iszModelIndex_Explode, vecOrigin, _, 12, 32);

		CWeapon__ExplodeGrenade(iOwner, iItem, vecOrigin);

		set_pev(iEntity, pev_flags, FL_KILLME);
		return HAM_IGNORED;
	}
	if(pev(iEntity, pev_classname) == gl_iszAllocString_ExplodePlayer)
	{
		new iItem = pev(iEntity, pev_dmg_inflictor);
		if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;
		
		new iVictim = pev(iEntity, pev_enemy);
		if(!is_user_valid(iVictim) || !is_user_alive(iVictim) || !zp_get_user_zombie(iVictim))
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		new iOwner = pev(iEntity, pev_owner);
		new Float: vecOrigin[3]; pev(iVictim, pev_origin, vecOrigin);

		emit_sound(iEntity, CHAN_ITEM, ENTITY_GRENADE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_CreateExplosion(gl_iszModelIndex_Explode, vecOrigin, _, 8, 32);

		CWeapon__ExplodeGrenade(iOwner, iItem, vecOrigin);

		set_pev(iEntity, pev_flags, FL_KILLME);
		return HAM_IGNORED;
	}

	return HAM_IGNORED;
}

#if defined CUSTOM_MUZZLEFLASH_ENABLED
	public CMuzzleFlash__Think_Pre(iSprite)
	{
		if(!IsValidEntity(iSprite)) return HAM_IGNORED;
		if(pev(iSprite, pev_classname) == gl_iszAllocString_MuzzleFlash)
		{
			#define m_maxFrame 35

			static Float: flFrame;
			if(pev(iSprite, pev_frame, flFrame) && ++flFrame - 1.0 < get_pdata_float(iSprite, m_maxFrame, linux_diff_weapon))
			{
				set_pev(iSprite, pev_frame, flFrame);
				set_pev(iSprite, pev_nextthink, get_gametime() + ENTITY_MUZZLE_NEXTTHINK);
				
				return HAM_SUPERCEDE;
			}

			set_pev(iSprite, pev_flags, FL_KILLME);
			return HAM_SUPERCEDE;
		}

		return HAM_IGNORED;
	}
#endif

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
	if(!is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;

	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

/* ~ [ Other ] ~ */
public CPlayer__Create_ExplodePlayer(iPlayer, iVictim, iItem)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!IsValidEntity(iEntity)) return FM_NULLENT;

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_ExplodePlayer);
	set_pev(iEntity, pev_solid, SOLID_NOT);
	set_pev(iEntity, pev_movetype, MOVETYPE_NONE);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_enemy, iVictim);
	set_pev(iEntity, pev_dmg_inflictor, iItem);
	set_pev(iEntity, pev_nextthink, get_gametime() + 0.7);

	return iEntity;
}

public CWeapon__Create_GrenadeMissile(iPlayer, iItem)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!IsValidEntity(iEntity)) return FM_NULLENT;

	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
	new Float: vecVelocity[3]; xs_vec_copy(vecForward, vecVelocity);

	// Start Origin
	xs_vec_mul_scalar(vecForward, 20.0, vecForward);
	xs_vec_add(vecViewOfs, vecForward, vecViewOfs);
	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);

	// Speed for missile
	xs_vec_mul_scalar(vecVelocity, ENTITY_GRENADE_SPEED, vecVelocity);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_GrenMissile);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_dmg_inflictor, iItem);
	set_pev(iEntity, pev_body, 0);
	set_pev(iEntity, pev_victims_attached, 0);
	set_pev(iEntity, pev_velocity, vecVelocity);
	set_pev(iEntity, pev_nextthink, get_gametime() + 0.7);

	engfunc(EngFunc_VecToAngles, vecVelocity, vecAngles);
	vecAngles[0] -= 90.0; vecAngles[2] += 90.0;
	set_pev(iEntity, pev_angles, vecAngles);

	engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
	engfunc(EngFunc_SetSize, iEntity, {-2.0, -2.0, -2.0}, {2.0, 2.0, 2.0});
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	return iEntity;
}

public CWeapon__ExplodeGrenade(iAttacker, iInflictor, Float: vecOrigin[3])
{
	new Float: flDamage, iVictim = FM_NULLENT;
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_GRENADE_RADIUS)) > 0)
	{
		if(pev(iVictim, pev_takedamage) == DAMAGE_NO) 
			continue;

		if(is_user_alive(iVictim))
		{
			if(iVictim == iAttacker || !zp_get_user_zombie(iVictim))
				continue;
		}
		else if(pev(iVictim, pev_solid) == SOLID_BSP)
		{
			if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
				continue;
		}

		if(is_user_alive(iVictim))
			set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);

		flDamage = ENTITY_GRENADE_DAMAGE_EXP * random_float(0.75, 1.25);
		ExecuteHamB(Ham_TakeDamage, iVictim, iInflictor, iAttacker, flDamage, ENTITY_GRENADE_DMGTYPE);
		zp_set_user_velocitymifier(iVictim, 0.6)
	}
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
#if defined CUSTOM_MUZZLEFLASH_ENABLED

	stock Sprite_SetTransparency(iSprite, iRendermode, Float: flAmt, iFx = kRenderFxNone)
	{
		set_pev(iSprite, pev_rendermode, iRendermode);
		set_pev(iSprite, pev_renderamt, flAmt);
		set_pev(iSprite, pev_renderfx, iFx);
	}

	stock UTIL_CreateMuzzleFlash(iPlayer, const szMuzzleSprite[], Float: flScale, Float: flBrightness, iAttachment)
	{
		#define ENTITY_SPRITES_INTOLERANCE 100
		if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < ENTITY_SPRITES_INTOLERANCE) return FM_NULLENT;
		
		static iSprite, iszAllocStringCached;
		if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
			iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
		
		if(!IsValidEntity(iSprite)) return FM_NULLENT;
		
		set_pev(iSprite, pev_model, szMuzzleSprite);
		set_pev(iSprite, pev_spawnflags, SF_SPRITE_ONCE);
		
		set_pev_string(iSprite, pev_classname, gl_iszAllocString_MuzzleFlash);
		set_pev(iSprite, pev_owner, iPlayer);
		set_pev(iSprite, pev_aiment, iPlayer);
		set_pev(iSprite, pev_body, iAttachment);
		
		Sprite_SetTransparency(iSprite, kRenderTransAdd, flBrightness);
		set_pev(iSprite, pev_scale, flScale);
		
		dllfunc(DLLFunc_Spawn, iSprite);

		return iSprite;
	}

#endif

stock UTIL_SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
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

stock UTIL_StatusIcon(iItem, iPlayer, iUpdateMode)
{
	new szSprite[33];
	new iClip = GetGrenadesCount(iItem);
	if(iClip > 9) format(szSprite, charsmax(szSprite), "escape");
	else format(szSprite, charsmax(szSprite), "number_%d", iClip);

	message_begin(MSG_ONE, gl_iMsgID_StatusIcon, { 0, 0, 0 }, iPlayer);
	write_byte((iUpdateMode && iClip > 0) ? 1 : 0);
	write_string(szSprite);
	write_byte(0);
	write_byte(128);
	write_byte(255);
	message_end();
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

stock UTIL_DropWeapon(iPlayer, iSlot)
{
	static iEntity, iNext, szWeaponName[32];
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

	if(IsValidEntity(iEntity))
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
