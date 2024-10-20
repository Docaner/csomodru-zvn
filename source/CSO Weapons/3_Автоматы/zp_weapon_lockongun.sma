#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>

#define IsCustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define getRockets(%0) (get_pdata_int(%0, m_iRockets, linux_diff_weapon))
#define getMaxRockets(%0) (getRockets(%0) >= WEAPON_MAX_ROCKETS ? 1 : 0)
#define setRockets(%0,%1) (set_pdata_int(%0, m_iRockets, %1, linux_diff_weapon))

#define m_iRockets m_iGlock18ShotsFired
#define m_iZoomState m_iFamasShotsFired
#define pev_serial_num pev_iuser1 // CWeapon
#define pev_new_rocket pev_fuser1 // CWeapon

#define PDATA_SAFE 2
#define TASKID_HUD 8500
#define DMG_GRENADE (1<<24)

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 91/30.0
#define WEAPON_ANIM_SHOOT_TIME 31/30.0
#define WEAPON_ANIM_SHOOT_B_TIME 81/30.0
#define WEAPON_ANIM_RELOAD_TIME 61/30.0
#define WEAPON_ANIM_DRAW_TIME 31/30.0
#define WEAPON_ANIM_ZOOM_TIME 21/30.0 // scope_on, zoom_in, zoom_idle, zoom_out

enum
{
	WEAPON_ANIM_IDLE = 0,
	WEAPON_ANIM_SHOOT_A = 2,
	WEAPON_ANIM_SHOOT_B = 12,
	WEAPON_ANIM_RELOAD = 4,
	WEAPON_ANIM_DRAW = 6,
	WEAPON_ANIM_SCOPE_ON = 8,
	WEAPON_ANIM_ZOOM_IN,
	WEAPON_ANIM_ZOOM_IDLE,
	WEAPON_ANIM_ZOOM_OUT
};

enum // zoom state
{
	WPN_ZOOM_STATE_NONE = 0,
	WPN_ZOOM_STATE_IN,
	WPN_ZOOM_STATE_IDLE,
	WPN_ZOOM_STATE_OUT,
	WPN_ZOOM_STATE_SHOOT
};

/* ~ [ Extra Item ] ~ */
new const WEAPON_ITEM_NAME[] = "X-TRACKER";
const WEAPON_ITEM_COST = 0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = "weapon_famas";
new const WEAPON_WEAPONLIST[] = "x/weapon_lockongun";
new const WEAPON_NATIVE[] = "zp_give_user_xtracker";
new const WEAPON_MODEL_VIEW[] = "models/x/v_lockongun_fx.mdl";
new const WEAPON_MODEL_PLAYER[] = "models/x/p_lockongun.mdl";
new const WEAPON_MODEL_WORLD[] = "models/x/w_lockongun.mdl";
new const WEAPON_SOUND_FIRE[][] =
{
	"weapons/lockongun-1.wav",
	"weapons/lockongun_shootb.wav"
};
new const WEAPON_SOUND_VICTIM_ADD[] = "weapons/lockongun_lockon_beep.wav";

const WEAPON_SPECIAL_CODE = 12092019;
const WEAPON_BODY = 0;

const WEAPON_MAX_ROCKETS = 5;
const WEAPON_MAX_CLIP = 50;
const WEAPON_DEFAULT_AMMO = 100;
const Float: WEAPON_RATE = 0.1;
const Float: WEAPON_PUNCHANGLE = 0.96;
const Float: WEAPON_DAMAGE = 1.43;

new const iWeaponList[] = { 4,  90, -1, -1, 0, 18,15, 0 };
new const HITGROUP_NAMES[][] =
{
	"GENERIC",
	"HEAD",
	"CHEST", "CHEST",
	"ARM", "ARM",
	"LEG", "LEG"
}

new Float: flMissilePositions[10][3] = 
{
	{ 40.0, 15.0, 0.0 },
	{ 40.0, -15.0, 0.0 },
	{ 20.0, 15.0, -2.5 },
	{ 20.0, -15.0, -2.5 },
	{ 0.0, 15.0, -5.0 },
	{ 0.0, -15.0, -5.0 },
	{ 20.0, 15.0, -7.5 },
	{ 20.0, -15.0, -7.5 },
	{ 40.0, 15.0, -10.0 },
	{ 40.0, -15.0, -10.0 }
};

/* ~ [ Entity: Rocket ] ~ */
new const ENTITY_ROCKET_CLASSNAME[] = "ent_xrocket";
new const ENTITY_ROCKET_MODEL[] = "models/x/lockongun_bullet.mdl";
new const ENTITY_ROCKET_SOUND[] = "weapons/lockongun_exp.wav";
new const ENTITY_ROCKET_SPRITE[] = "sprites/x/ef_lockongun_explosion02.spr";
new const ENTITY_ROCKET_TRAIL[] = "sprites/x/ef_lockongun_trail.spr";
const Float: ENTITY_ROCKET_SPEED = 1500.0;
const Float: ENTITY_ROCKET_RADIUS = 75.0;
#define ENTITY_ROCKET_DAMAGE random_float(300.0, 600.0)
const ENTITY_ROCKET_DMGTYPE = DMG_GRENADE; 
const Float: ENTITY_ROCKET_NEW = 5.0;

/* ~ [ MuzzleFlash ] ~ */
const ENTITY_SPRITES_INTOLERANCE = 100;
const Float: ENTITY_MUZZLE_NEXTTHINK = 0.032;
new const ENTITY_MUZZLE_CLASSNAME[] = "mf_xtracker";
new const ENTITY_MUZZLE_SPRITE[] = "sprites/x/muzzleflash102.spr";

/* ~ [ Offsets ] ~ */
// Linux extra offsets
#define linux_diff_weapon 4
#define linux_diff_player 5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CSprite
#define m_maxFrame 35

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
#define m_iFamasShotsFired 72

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_iFOV 363
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

/* ~ [ Params ] ~ */
new gl_iszAllocString_Entity,
	gl_iszAllocString_ModelView,
	gl_iszAllocString_ModelPlayer,
	gl_iszAllocString_MuzzleKey,
	gl_iszAllocString_InfoTarget,
	gl_iszAllocString_Rocket,

	gl_iszModelIndex_Explode,
	gl_iszModelIndex_BeamFollow,

	HamHook: gl_HamHook_TraceAttack[4],

	gl_iMsgID_Weaponlist,
	gl_iMsgID_StatusIcon,
	gl_iMsgID_ScreenFade,

	gl_iMsgSync_HudVictims,
	gl_iMsgSync_HudLastHits,

	gl_iItemID;

public plugin_init()
{
	// https://cso.fandom.com/wiki/X-TRACKER
	register_plugin("[ZP] Weapon: X-TRACKER", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

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
	RegisterHam(Ham_Touch,					"info_target",		"CEntity__Touch_Pre", false);
	RegisterHam(Ham_Think,					"info_target",		"CEntity__Think_Pre", false);
	RegisterHam(Ham_Think,					"env_sprite",		"CMuzzleFlash__Think_Pre", false);

	// Player
	RegisterHam(Ham_Player_PreThink,		"player",			"CPlayer__PreThink_Pre", false);

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
	gl_iMsgID_ScreenFade = get_user_msgid("ScreenFade");

	// Hud Messages
	gl_iMsgSync_HudVictims = CreateHudSyncObj();
	gl_iMsgSync_HudLastHits = CreateHudSyncObj();

	// Alloc String
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);
	gl_iszAllocString_MuzzleKey = engfunc(EngFunc_AllocString, ENTITY_MUZZLE_CLASSNAME);
	gl_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");
	gl_iszAllocString_Rocket = engfunc(EngFunc_AllocString, ENTITY_ROCKET_CLASSNAME);
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);
	engfunc(EngFunc_PrecacheModel, ENTITY_ROCKET_MODEL);
	engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITE);

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	
	// Precache sounds
	for(new i = 0; i < sizeof WEAPON_SOUND_FIRE; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_FIRE[i]);

	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_VICTIM_ADD);
	engfunc(EngFunc_PrecacheSound, ENTITY_ROCKET_SOUND);

	UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW);

	// Model Index
	gl_iszModelIndex_Explode = engfunc(EngFunc_PrecacheModel, ENTITY_ROCKET_SPRITE);
	gl_iszModelIndex_BeamFollow = engfunc(EngFunc_PrecacheModel, ENTITY_ROCKET_TRAIL);
}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

// [ Amxx ]
public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem == gl_iItemID)
		Command_GiveWeapon(iPlayer);
}

public zp_user_infected_post(iPlayer)
{
	new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);

	if(pev_valid(iItem))
		UTIL_StatusIcon(iItem, iPlayer, 0);
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
	setRockets(iEntity, WEAPON_MAX_ROCKETS);
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

	set_pdata_int(iEntity, m_iZoomState, WPN_ZOOM_STATE_NONE, linux_diff_weapon);

	new szVictimData[32] = { 255, ... };
	set_pev(iEntity, pev_noise, szVictimData);

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
	if(pev_valid(iItem) != PDATA_SAFE) return;
	if(!IsCustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_StatusIcon(iItem, iPlayer, 0);
	set_pdata_int(iPlayer, m_iFOV, 90, linux_diff_player);
	UTIL_ScreenFade(iPlayer, 0, 0, 0, 0, 0, 0, 255);
	
	set_pdata_int(iItem, m_iZoomState, WPN_ZOOM_STATE_NONE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CWeapon__Deploy_Post(iItem)
{
	if(!IsCustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_StatusIcon(iItem, iPlayer, 0);
	UTIL_StatusIcon(iItem, iPlayer, 1);

	set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
	set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW + getMaxRockets(iItem));

	set_pev(iItem, pev_new_rocket, get_gametime() + ENTITY_ROCKET_NEW);
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

	static iZoomState; iZoomState = get_pdata_int(iItem, m_iZoomState, linux_diff_weapon);
	switch(iZoomState)
	{
		case WPN_ZOOM_STATE_IN:
		{
			UTIL_ScreenFade(iPlayer, 0, 0, 0x0004, 55, 187, 179, 38);
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_ZOOM_IDLE);
			set_pdata_int(iItem, m_iZoomState, WPN_ZOOM_STATE_IDLE, linux_diff_weapon);
			set_pdata_int(iPlayer, m_iFOV, 80, linux_diff_player);

			CTask__StateHud(iPlayer + TASKID_HUD);
		}
		case WPN_ZOOM_STATE_OUT: set_pdata_int(iItem, m_iZoomState, WPN_ZOOM_STATE_NONE, linux_diff_weapon);
		case WPN_ZOOM_STATE_SHOOT:
		{
			new szVictimData[32]; pev(iItem, pev_noise, szVictimData, 31);
			new iVictim; //, iHitgroup;
			new Float: vecOrigin[3];
			for(new i = 0; i <= 9; i++)
			{
				iVictim = szVictimData[i];
				//iHitgroup = szVictimData[i+10];

				UTIL_GetWeaponPosition(iPlayer, flMissilePositions[i][0], flMissilePositions[i][1], flMissilePositions[i][2], vecOrigin);
				CWeapon__CreateRocket(iPlayer, iVictim, vecOrigin);
				szVictimData[i] = szVictimData[i+10] = 255;
			}

			set_pev(iItem, pev_noise, szVictimData);
			set_pev(iItem, pev_serial_num, 0);
			set_pev(iItem, pev_new_rocket, get_gametime() + ENTITY_ROCKET_NEW);

			UTIL_StatusIcon(iItem, iPlayer, 0);
			setRockets(iItem, 0);
			UTIL_StatusIcon(iItem, iPlayer, 1);

			set_pdata_int(iItem, m_iZoomState, WPN_ZOOM_STATE_NONE, linux_diff_weapon);
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
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP)
		return HAM_SUPERCEDE;
	
	if(get_pdata_int(iItem, m_iZoomState, linux_diff_weapon) != WPN_ZOOM_STATE_NONE)
		return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInReload, 1, linux_diff_weapon);
	set_pdata_int(iItem, m_iZoomState, WPN_ZOOM_STATE_NONE, linux_diff_weapon);
	set_pdata_int(iPlayer, m_iFOV, 90, linux_diff_player);
	UTIL_ScreenFade(iPlayer, 0, 0, 0, 0, 0, 0, 255);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_RELOAD + getMaxRockets(iItem));

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
	static iZoomState; iZoomState = get_pdata_int(iItem, m_iZoomState, linux_diff_weapon);

	if(iZoomState == WPN_ZOOM_STATE_NONE)
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE + getMaxRockets(iItem));
	else if(iZoomState == WPN_ZOOM_STATE_IDLE)
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_ZOOM_IDLE);

	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	if(get_pdata_int(iItem, m_iZoomState, linux_diff_weapon) == WPN_ZOOM_STATE_IDLE)
		CWeapon__GetAimVictims(iItem, iPlayer);

	if(get_pdata_int(iItem, m_iClip, linux_diff_weapon) == 0)
	{
		//ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

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
	vecPunchangle[0] *= WEAPON_PUNCHANGLE;
	vecPunchangle[1] *= WEAPON_PUNCHANGLE;
	vecPunchangle[2] *= WEAPON_PUNCHANGLE;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	if(get_pdata_int(iItem, m_iZoomState, linux_diff_weapon) == WPN_ZOOM_STATE_NONE)
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT_A + getMaxRockets(iItem));

	UTIL_CreateMuzzleFlash(iPlayer, ENTITY_MUZZLE_SPRITE, random_float(0.035, 0.06), 255.0, 1);

	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;
	if(!getMaxRockets(iItem)) return HAM_SUPERCEDE;

	new Float: flTime, Float: flCallPostFrame;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iZoomState; iZoomState = get_pdata_int(iItem, m_iZoomState, linux_diff_weapon);
	switch(iZoomState)
	{
		case WPN_ZOOM_STATE_NONE:
		{
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_ZOOM_IN);

			flCallPostFrame = flTime = WEAPON_ANIM_ZOOM_TIME;
			iZoomState = WPN_ZOOM_STATE_IN;
		}
		case WPN_ZOOM_STATE_IDLE:
		{
			if(checkValidMode(iItem))
			{
				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT_B);
				emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

				flCallPostFrame = 35/30.0;
				flTime = WEAPON_ANIM_SHOOT_B_TIME;
				iZoomState = WPN_ZOOM_STATE_SHOOT;
			}
			else
			{
				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_ZOOM_OUT);

				flCallPostFrame = flTime = WEAPON_ANIM_ZOOM_TIME;
				iZoomState = WPN_ZOOM_STATE_OUT;
			}

			set_pdata_int(iPlayer, m_iFOV, 90, linux_diff_player);
			UTIL_ScreenFade(iPlayer, 0, 0, 0, 0, 0, 0, 255);
		}
		default: return HAM_SUPERCEDE;
	}

	set_pdata_int(iItem, m_iZoomState, iZoomState, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, flTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, flTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, flTime, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, flCallPostFrame, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CEntity__Touch_Pre(iEntity, iTouch)
{
	if(pev_valid(iEntity) != PDATA_SAFE || pev(iTouch, pev_solid) == SOLID_TRIGGER) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Rocket)
	{
		new iOwner = pev(iEntity, pev_owner);
		if(iTouch == iOwner) return HAM_SUPERCEDE;
		if(pev(iTouch, pev_classname) == gl_iszAllocString_Rocket) return HAM_SUPERCEDE;

		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		emit_sound(iEntity, CHAN_ITEM, ENTITY_ROCKET_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_CreateExplosion(vecOrigin, random_float(0.0, 20.0), gl_iszModelIndex_Explode, random_num(3, 8), 32, 2|4|8);

		new iVictim = FM_NULLENT;
		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_ROCKET_RADIUS)) > 0)
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

			if(is_user_alive(iVictim))
				set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);

			ExecuteHamB(Ham_TakeDamage, iVictim, iOwner, iOwner, ENTITY_ROCKET_DAMAGE, ENTITY_ROCKET_DMGTYPE);
		}

		set_pev(iEntity, pev_flags, FL_KILLME);
	}

	return HAM_IGNORED;
}

public CEntity__Think_Pre(iEntity)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Rocket)
	{
		new Float: flGameTime = get_gametime();
		new iVictim = pev(iEntity, pev_enemy);
		if(iVictim != 0 || iVictim != 255)
		{
			if(pev_valid(iVictim) == PDATA_SAFE)
			{
				if(is_user_alive(iVictim) && zp_get_user_zombie(iVictim) || iVictim > MaxClients && pev(iVictim, pev_deadflag) == DEAD_NO && pev(iVictim, pev_flags) & FL_MONSTER)
				{
					CEntity__TurnToTarget(iEntity, iVictim);
					CEntity__VelocityToTarget(iEntity, iVictim, ENTITY_ROCKET_SPEED);
					
					set_pev(iEntity, pev_nextthink, flGameTime + 0.011);
				}
			}
		}
	}

	return HAM_IGNORED;
}

public CMuzzleFlash__Think_Pre(iSprite)
{
	if(pev_valid(iSprite) != PDATA_SAFE || pev(iSprite, pev_impulse) != gl_iszAllocString_MuzzleKey) return HAM_IGNORED;

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

public CPlayer__PreThink_Pre(iPlayer)
{
	if(!is_user_alive(iPlayer)) return HAM_IGNORED;

	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return HAM_IGNORED;

	new Float: flGameTime = get_gametime();
	new Float: flNextRocket; pev(iItem, pev_new_rocket, flNextRocket);

	if(flNextRocket < flGameTime && !getMaxRockets(iItem))
	{
		if(getRockets(iItem) == 9 && !get_pdata_int(iItem, m_fInReload, linux_diff_weapon))
		{
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SCOPE_ON);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_ZOOM_TIME, linux_diff_weapon);
		}

		UTIL_StatusIcon(iItem, iPlayer, 0);
		setRockets(iItem, getRockets(iItem) + 1);
		UTIL_StatusIcon(iItem, iPlayer, 1);

		set_pev(iItem, pev_new_rocket, flGameTime + ENTITY_ROCKET_NEW);
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

public CWeapon__CreateRocket(iPlayer, iVictim, Float: vecOrigin[3])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!iEntity) return FM_NULLENT;

	new Float: flGameTime = get_gametime();
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
	new Float: vecVelocity[3]; xs_vec_copy(vecForward, vecVelocity);

	// Speed for missile
	xs_vec_mul_scalar(vecVelocity, ENTITY_ROCKET_SPEED, vecVelocity);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Rocket);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_enemy, iVictim);
	set_pev(iEntity, pev_velocity, vecVelocity);
	set_pev(iEntity, pev_nextthink, flGameTime);

	engfunc(EngFunc_VecToAngles, vecVelocity, vecAngles);
	set_pev(iEntity, pev_angles, vecAngles);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_ROCKET_MODEL);
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	// https://github.com/baso88/SC_AngelScript/wiki/TE_BEAMFOLLOW
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(gl_iszModelIndex_BeamFollow); // Model Index
	write_byte(7); // Life
	write_byte(1); // Width
	write_byte(180); // Red
	write_byte(180); // Green
	write_byte(180); // Blue
	write_byte(220); // Alpha
	message_end();

	return iEntity;
}

public CWeapon__GetAimVictims(iItem, iPlayer)
{
	new Float: vecForward[3], Float: vecEnd[3];
	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

	// Start Origin
	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);

	// End Origin
	xs_vec_mul_scalar(vecForward, 4096.0, vecForward);
	xs_vec_add(vecEnd, vecForward, vecEnd);
	xs_vec_add(vecEnd, vecOrigin, vecEnd);

	new iTrace = create_tr2();
	engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);

	new pHit = get_tr2(iTrace, TR_pHit);
	new iHitgroup = get_tr2(iTrace, TR_iHitgroup);

	free_tr2(iTrace);

	if(is_user_alive(pHit) && zp_get_user_zombie(pHit) || pHit > MaxClients && pev(pHit, pev_deadflag) == DEAD_NO && pev(pHit, pev_flags) & FL_MONSTER)
	{
		new iSerialNum = pev(iItem, pev_serial_num);
		new szVictimData[32]; pev(iItem, pev_noise, szVictimData, 31);

		szVictimData[iSerialNum] = pHit;
		szVictimData[iSerialNum + 10] = iHitgroup;

		if(iSerialNum >= 9) iSerialNum = 0;
		else iSerialNum++;

		set_pev(iItem, pev_serial_num, iSerialNum);
		set_pev(iItem, pev_noise, szVictimData);

		client_cmd(iPlayer, "spk ^"%s^"", WEAPON_SOUND_VICTIM_ADD);
	}
}

public CTask__StateHud(iTask)
{
	new iPlayer = iTask - TASKID_HUD;

	if(!is_user_alive(iPlayer))
	{
		CPlayer__ResetHud(iPlayer);
		return;
	}

	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem))
	{
		CPlayer__ResetHud(iPlayer);
		return;
	}

	if(get_pdata_int(iItem, m_iZoomState, linux_diff_weapon) != WPN_ZOOM_STATE_IDLE)
	{
		CPlayer__ResetHud(iPlayer);
		return;
	}

	// Victim's name
	new iVictim = FM_NULLENT, ibitDoubleData, iLen;
	new szText[512], szName[32], szVictimData[32];
	pev(iItem, pev_noise, szVictimData, 31);
	
	for(new i = 0; i <= 9; i++)
	{
		iVictim = szVictimData[i];

		if(iVictim == 255) continue;
		if(!is_user_alive(iVictim) || !zp_get_user_zombie(iVictim)) continue;

		if(ibitDoubleData & (1<<iVictim)) continue;
		ibitDoubleData |= (1<<iVictim);

		get_user_name(iVictim, szName, charsmax(szName));
		iLen += formatex(szText[iLen], charsmax(szText) - iLen, "%s (%i)^n", szName, userCount(iVictim, iItem));
	}

	set_hudmessage(52, 146, 235, 0.17, 0.27, 0, WEAPON_RATE, WEAPON_RATE+0.2, 0.0, 0.0, -1);
	ShowSyncHudMsg(iPlayer, gl_iMsgSync_HudVictims, szText);

	// Last Hits
	new iLastHit; iLen = 0;
	new szHitBox[512];

	for(new i = 0; i <= 9; i++)
	{
		iVictim = szVictimData[i];
		iLastHit = szVictimData[i+10];

		if(iVictim == 255 || iLastHit == 255) continue;
		if(!is_user_alive(iVictim) || !zp_get_user_zombie(iVictim)) continue;

		iLen += formatex(szHitBox[iLen], charsmax(szHitBox) - iLen, "[%s] ", HITGROUP_NAMES[iLastHit]);
	}

	set_hudmessage(52, 146, 235, -1.0, 0.75, 0, WEAPON_RATE, WEAPON_RATE+0.2, 0.0, 0.0, -1);
	ShowSyncHudMsg(iPlayer, gl_iMsgSync_HudLastHits, szHitBox);

	set_task(WEAPON_RATE, "CTask__StateHud", iTask);
}

public CPlayer__ResetHud(iPlayer)
{
	set_hudmessage(0, 0, 0, -1.0, -1.0);
	ShowSyncHudMsg(iPlayer, gl_iMsgSync_HudVictims, "");

	set_hudmessage(0, 0, 0, -1.0, -1.0);
	ShowSyncHudMsg(iPlayer, gl_iMsgSync_HudLastHits, "");

	remove_task(iPlayer + TASKID_HUD);
}

public CEntity__TurnToTarget(iEntity, iVictim)
{
	new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
	new Float: vecVOrigin[3]; pev(iVictim, pev_origin, vecVOrigin);
	new Float: vecAngles[3]; pev(iEntity, pev_angles, vecAngles);
	new Float: vecOffsetX; vecVOrigin[0] - vecOrigin[0];
	new Float: vecOffsetY; vecVOrigin[1] - vecOrigin[1];
	new Float: flRadian = floatatan(vecOffsetY / vecOffsetX, radian);
	vecAngles[1] = flRadian * (180 / 3.14);

	if(vecVOrigin[0] < vecOrigin[0])
		vecAngles[1] -= 180.0;

	set_pev(iEntity, pev_angles, vecAngles);
}

public CEntity__VelocityToTarget(iEntity, iVictim, Float: flSpeed)
{
	static Float: vecVelocity[3];
	new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
	new Float: vecVOrigin[3]; pev(iVictim, pev_origin, vecVOrigin);
	new Float: flDistance = get_distance_f(vecOrigin, vecVOrigin);
	new Float: flTime = flDistance / flSpeed;

	vecVelocity[0] = (vecVOrigin[0] - vecOrigin[0]) / flTime;
	vecVelocity[1] = (vecVOrigin[1] - vecOrigin[1]) / flTime;
	vecVelocity[2] = (vecVOrigin[2] - vecOrigin[2]) / flTime;

	set_pev(iEntity, pev_velocity, vecVelocity);
}

// [ Stocks ]
stock userCount(iPlayer, iItem)
{
	new iFindPlayer, iCount = 0;
	new szVictimData[32]; pev(iItem, pev_noise, szVictimData, 31);

	for(new i = 0; i <= 9; i++)
	{
		iFindPlayer = szVictimData[i];
		if(iFindPlayer == 0 || iFindPlayer == 255) continue;
		if(iFindPlayer == iPlayer) iCount++;
	}

	return iCount;
}

stock checkValidMode(iItem)
{
	new iVictim, iReturn = 0;
	new szVictimData[32]; pev(iItem, pev_noise, szVictimData, 31);
	for(new i = 0; i <= 9; i++)
	{
		iVictim = szVictimData[i];
		if(iVictim == 0 || iVictim == 255) continue;
		if((!is_user_alive(iVictim) || !zp_get_user_zombie(iVictim)) && 
		(iVictim <= MaxClients || pev(iVictim, pev_deadflag) != DEAD_NO || ~pev(iVictim, pev_flags) & FL_MONSTER)) continue;

		iReturn++;
	}

	return iReturn ? 1 : 0;
}

stock is_wall_between_points(iPlayer, iEntity)
{
	if(!is_user_alive(iEntity))
		return 0;

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

stock Sprite_SetTransparency(iSprite, iRendermode, Float: flAmt, iFx = kRenderFxNone)
{
	set_pev(iSprite, pev_rendermode, iRendermode);
	set_pev(iSprite, pev_renderamt, flAmt);
	set_pev(iSprite, pev_renderfx, iFx);
}

stock UTIL_CreateMuzzleFlash(iPlayer, const szMuzzleSprite[], Float: flScale, Float: flBrightness, iAttachment)
{
	if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < ENTITY_SPRITES_INTOLERANCE) return FM_NULLENT;
	
	static iSprite, iszAllocStringCached;
	if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
		iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	
	if(pev_valid(iSprite) != PDATA_SAFE) return FM_NULLENT;
	
	set_pev(iSprite, pev_model, szMuzzleSprite);
	set_pev(iSprite, pev_spawnflags, SF_SPRITE_ONCE);
	
	set_pev(iSprite, pev_classname, ENTITY_MUZZLE_CLASSNAME);
	set_pev(iSprite, pev_impulse, gl_iszAllocString_MuzzleKey);
	set_pev(iSprite, pev_owner, iPlayer);
	set_pev(iSprite, pev_aiment, iPlayer);
	set_pev(iSprite, pev_body, iAttachment);
	
	Sprite_SetTransparency(iSprite, kRenderTransAdd, flBrightness);
	set_pev(iSprite, pev_scale, flScale);
	
	dllfunc(DLLFunc_Spawn, iSprite)

	return iSprite;
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
	new szSprite[33], iColor[3];
	new iClip = getRockets(iItem);
	
	if(iClip >= 10)
	{
		iColor = { 255, 30, 30 };
		format(szSprite, charsmax(szSprite), "escape");
	}
	else
	{
		iColor = { 55, 187, 179 };
		format(szSprite, charsmax(szSprite), "number_%d", iClip);
	}
	
	message_begin(MSG_ONE, gl_iMsgID_StatusIcon, { 0, 0, 0 }, iPlayer);
	if(iUpdateMode && iClip > 0) write_byte(1);
	else write_byte(0);
	write_string(szSprite); 
	write_byte(iColor[0]);
	write_byte(iColor[1]); 
	write_byte(iColor[2]);
	message_end();
}

stock UTIL_ScreenFade(iPlayer, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{
	if(!iPlayer)
		message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, gl_iMsgID_ScreenFade);
	else message_begin(iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, gl_iMsgID_ScreenFade, _, iPlayer);

	write_short(iDuration);
	write_short(iHoldTime);
	write_short(iFlags);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}
