#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>

/* ~ [ Extra Item ] ~ */
new const WEAPON_ITEM_NAME[] = "Inferno Cannon";
const WEAPON_ITEM_COST = 0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = "weapon_xm1014";
new const WEAPON_WEAPONLIST[] = "x/weapon_gatlingex";
new const WEAPON_NATIVE[] = "zp_give_user_gatlingex";
new const WEAPON_MODEL_VIEW[] = "models/x/v_gatlingex.mdl";
new const WEAPON_MODEL_PLAYER[] = "models/x/p_gatlingex.mdl";
new const WEAPON_MODEL_WORLD[] = "models/x/w_gatlingex.mdl";
new const WEAPON_DECAL_STAR_SPRITE[] = "sprites/x/ef_gatlingex_star.spr";
new const WEAPON_SOUNDS[][] =
{
	"weapons/gatlingex-1.wav",
	"weapons/gatlingex-2.wav"
};
new const WEAPON_RESOURCES[][] =
{
	// Custom resources precache, sprites for example
	"sprites/640hud7.spr",
	"sprites/x/640hud39.spr",
	"sprites/x/640hud199.spr"
};

const WEAPON_SPECIAL_CODE = 100720201;
const WEAPON_MODEL_WORLD_BODY = 0;

const WEAPON_MAX_CLIP = 30;
const WEAPON_DEFAULT_AMMO = 90;
const WEAPON_INFERNAL_FLAME_MAX = 1; // Max count of Infernal Flames
const WEAPON_SHOTS_COUNT = 20; // Need shoots for get one charge of Infernal Flame
const Float: WEAPON_RATE = 0.275;
const Float: WEAPON_PUNCHANGLE = 0.63;
const Float: WEAPON_DAMAGE = 1.13;

new const iWeaponList[] = 
{
	5,  32, -1, -1, 0, 12,5,  0 // weapon_xm1014
	//5, 32, -1, -1, 0, 5, 21, 0 // weapon_m3
};

/* ~ [ Entity: Infernal Flame ] ~ */
new const ENTITY_INFERNAL_CLASSNAME[] = "ent_infernalflame_x";
new const ENTITY_INFERNAL_MODEL[] = "sprites/x/ef_gatlingex_fireball.spr";
new const ENTITY_INFERNAL_SPRITE[] = "sprites/x/ef_gatlingex_explosion.spr";
new const ENTITY_INFERNAL_SOUND[] = "weapons/gatlingex-2_exp.wav";
const Float: ENTITY_INFERNAL_SPEED = 100.0;
const Float: ENTITY_INFERNAL_LIFETIME = 5.0;
const Float: ENTITY_INFERNAL_NEXTDAMAGE = 0.2; // Delay of damage in radius of Infernal Flame
const Float: ENTITY_INFERNAL_RADIUS = 100.0;
const Float: ENTITY_INFERNAL_DAMAGE = 175.0; // It's damage when Infernal Flame is flying
const Float: ENTITY_INFERNAL_DAMAGE_EXP = 750.0;
#define DMG_GRENADE (1<<24)
const ENTITY_INFERNAL_DMGTYPE = DMG_GRENADE;

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 151/30.0
#define WEAPON_ANIM_RELOAD_TIME 151/30.0
#define WEAPON_ANIM_DRAW_TIME 31/30.0
#define WEAPON_ANIM_SHOOT_TIME 21/30.0
#define WEAPON_ANIM_SHOOT_EX_TIME 31/30.0

#define WEAPON_ANIM_IDLE 0
#define WEAPON_ANIM_RELOAD 1
#define WEAPON_ANIM_DRAW 2
#define WEAPON_ANIM_SHOOT random_num(3,4)
#define WEAPON_ANIM_SHOOT_EX 5

/* ~ [ Params ] ~ */
new gl_iszAllocString_Entity,
	gl_iszAllocString_ModelView,
	gl_iszAllocString_ModelPlayer,
	gl_iszAllocString_InfoTarget,
	gl_iszAllocString_StarSprite,
	gl_iszAllocString_Infernal,

	gl_iszModelIndex_Explode,

	HamHook: gl_HamHook_TraceAttack[4],

	gl_iMsgID_Weaponlist,
	gl_iMsgID_StatusIcon,
	gl_iItemID;

/* ~ [ Macroses ] ~ */
#define PDATA_SAFE 2

#define m_iShotsCount m_iGlock18ShotsFired
#define m_iInfernalFlames m_iFamasShotsFired

#define is_user_valid(%0) (%0 && 0 < %0 < 33)
#define IsValidEntity(%0) (pev_valid(%0) == PDATA_SAFE)
#define IsCustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define KillEntity(%0) (set_pev(%0, pev_flags, pev(%0, pev_flags) | FL_KILLME))

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
#define m_iFamasShotsFired 72

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
	register_plugin("[ZP] Weapon: Inferno Cannon", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	// Events
	register_event("HLTV", "EV_RoundStart", "a", "1=0", "2=0");

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
	RegisterHam(Ham_Think, 					"info_target",		"CEntity__Think_Pre", false);
	RegisterHam(Ham_Touch, 					"info_target",		"CEntity__Touch_Pre", false);
	
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
	gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);
	gl_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");
	gl_iszAllocString_StarSprite = engfunc(EngFunc_AllocString, "ent_stardecal_x");
	gl_iszAllocString_Infernal = engfunc(EngFunc_AllocString, ENTITY_INFERNAL_CLASSNAME);
}

public plugin_precache()
{
	new i;

	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);
	engfunc(EngFunc_PrecacheModel, WEAPON_DECAL_STAR_SPRITE);
	engfunc(EngFunc_PrecacheModel, ENTITY_INFERNAL_MODEL);

	// Precache generic
	new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/%s.txt", WEAPON_WEAPONLIST);
	engfunc(EngFunc_PrecacheGeneric, szWeaponList);

	for(i = 0; i < sizeof WEAPON_RESOURCES; i++)
		engfunc(EngFunc_PrecacheGeneric, WEAPON_RESOURCES[i]);
	
	// Precache sounds
	for(i = 0; i < sizeof WEAPON_SOUNDS; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUNDS[i]);

	engfunc(EngFunc_PrecacheSound, ENTITY_INFERNAL_SOUND);
	UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW);

	// Model Index
	gl_iszModelIndex_Explode = engfunc(EngFunc_PrecacheModel, ENTITY_INFERNAL_SPRITE);
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
	set_pdata_int(iWeapon, m_iShotsCount, 0, linux_diff_weapon);
	set_pdata_int(iWeapon, m_iInfernalFlames, 0, linux_diff_weapon);
	UTIL_DropWeapon(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));

	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iWeapon))
	{
		KillEntity(iWeapon);
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

// [ Events ]
public EV_RoundStart()
{
	new iEntity;
	iEntity = FM_NULLENT;
	while((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", ENTITY_INFERNAL_CLASSNAME)))
		if(IsValidEntity(iEntity)) KillEntity(iEntity);
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

	CWeapon__CheckShots(iItem, iPlayer);
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;

	static iInfernalFlames; iInfernalFlames = get_pdata_int(iItem, m_iInfernalFlames, linux_diff_weapon);
	if(!iInfernalFlames)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextSecondaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	CWeapon__Create_InfernalFlame(iPlayer);
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT_EX);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	UTIL_StatusIcon(iItem, iPlayer, 0);
	iInfernalFlames--;
	set_pdata_int(iItem, m_iInfernalFlames, iInfernalFlames, linux_diff_weapon);
	UTIL_StatusIcon(iItem, iPlayer, 1);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SHOOT_EX_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_SHOOT_EX_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_EX_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CEntity__Think_Pre(iEntity)
{
	if(!IsValidEntity(iEntity)) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_StarSprite)
	{
		KillEntity(iEntity);
	}
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Infernal)
	{
		new iOwner = pev(iEntity, pev_owner);
		if(!is_user_alive(iOwner) || zp_get_user_zombie(iOwner))
		{
			KillEntity(iEntity);
			return HAM_IGNORED;
		}

		static Float: flLifeTime;
		if(pev(iEntity, pev_ltime, flLifeTime) && flLifeTime < get_gametime())
		{
			CEntity__Infernal_Explode(iEntity, iOwner);
			return HAM_IGNORED;
		}

		// Animation
		static Float: flFrame; pev(iEntity, pev_frame, flFrame);
		flFrame = (flFrame >= 29.0) ? 0.0 : flFrame + 1.0;
		set_pev(iEntity, pev_frame, flFrame);

		// Damage
		static iItem; iItem = get_pdata_cbase(iOwner, m_rpgPlayerItems + 1, linux_diff_player);
		if(IsValidEntity(iItem) && IsCustomItem(iItem))
		{
			static iVictim = FM_NULLENT, Float: flDamage, Float: flDmgTime, Float: vecOrigin[3];
			pev(iEntity, pev_origin, vecOrigin);

			if(flDmgTime < get_gametime())
			{
				while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_INFERNAL_RADIUS)) > 0)
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
						set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);

					flDamage = ENTITY_INFERNAL_DAMAGE * random_float(0.75, 1.25);
					ExecuteHamB(Ham_TakeDamage, iVictim, iItem, iOwner, flDamage, ENTITY_INFERNAL_DMGTYPE);
				}

				flDmgTime = get_gametime() + ENTITY_INFERNAL_NEXTDAMAGE;
			}
		}

		set_pev(iEntity, pev_nextthink, get_gametime() + 0.05);
	}

	return HAM_IGNORED;
}

public CEntity__Touch_Pre(iEntity, iTouch)
{
	if(!IsValidEntity(iEntity)) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Infernal)
	{
		new iOwner = pev(iEntity, pev_owner);
		if(iTouch == iOwner) return HAM_SUPERCEDE;
		if(pev(iTouch, pev_classname) == gl_iszAllocString_Infernal) return HAM_SUPERCEDE;

		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		if(!iTouch || !is_user_valid(iTouch))
			CEntity__Infernal_Explode(iEntity, iOwner);
	}

	return HAM_IGNORED;
}

public CEntity__Infernal_Explode(iEntity, iOwner)
{
	if(!IsValidEntity(iEntity)) return false;
	if(pev(iEntity, pev_classname) != gl_iszAllocString_Infernal) return false;

	new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
	emit_sound(iEntity, CHAN_ITEM, ENTITY_INFERNAL_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	UTIL_CreateExplosion(vecOrigin, 0.0, gl_iszModelIndex_Explode, random_num(10, 14), 32, 2|4|8);

	// Damage
	static iItem; iItem = get_pdata_cbase(iOwner, m_rpgPlayerItems + 1, linux_diff_player);
	if(IsValidEntity(iItem) && IsCustomItem(iItem))
	{
		static iVictim = FM_NULLENT, Float: flDamage;
		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_INFERNAL_RADIUS)) > 0)
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
				set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);

			flDamage = Float: ENTITY_INFERNAL_DAMAGE_EXP * random_float(0.75, 1.25);
			ExecuteHamB(Ham_TakeDamage, iVictim, iItem, iOwner, flDamage, ENTITY_INFERNAL_DMGTYPE);
		}
	}

	KillEntity(iEntity);
	return true;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
	if(!is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;

	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

/* ~ [ Other ] ~ */
public CWeapon__CheckShots(iItem, iPlayer)
{
	static iInfernalFlames; iInfernalFlames = get_pdata_int(iItem, m_iInfernalFlames, linux_diff_weapon);
	if(iInfernalFlames < WEAPON_INFERNAL_FLAME_MAX)
	{
		static iShotsCount; iShotsCount = get_pdata_int(iItem, m_iShotsCount, linux_diff_weapon);
		iShotsCount++;
		if(iShotsCount >= WEAPON_SHOTS_COUNT)
		{
			iInfernalFlames++;
			iShotsCount = 0;

			UTIL_StatusIcon(iItem, iPlayer, 0);
			set_pdata_int(iItem, m_iInfernalFlames, iInfernalFlames, linux_diff_weapon);
			UTIL_StatusIcon(iItem, iPlayer, 1);
		}

		set_pdata_int(iItem, m_iShotsCount, iShotsCount, linux_diff_weapon);
	}
}

public CWeapon__Create_InfernalFlame(iPlayer)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!IsValidEntity(iEntity)) return FM_NULLENT;

	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
	new Float: vecVelocity[3]; xs_vec_copy(vecForward, vecVelocity);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);

	// Create start position
	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);
	xs_vec_mul_scalar(vecForward, 20.0, vecForward);
	xs_vec_add(vecOrigin, vecForward, vecOrigin);

	// Speed for missile
	xs_vec_mul_scalar(vecVelocity, ENTITY_INFERNAL_SPEED, vecVelocity);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Infernal);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_velocity, vecVelocity);
	set_pev(iEntity, pev_scale, 0.5);
	set_pev(iEntity, pev_ltime, get_gametime() + ENTITY_INFERNAL_LIFETIME);
	set_pev(iEntity, pev_nextthink, get_gametime());

	engfunc(EngFunc_VecToAngles, vecVelocity, vecAngles);
	set_pev(iEntity, pev_angles, vecAngles);

	Sprite_SetTransparency(iEntity, kRenderTransAdd, 250.0);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_INFERNAL_MODEL);
	engfunc(EngFunc_SetSize, iEntity, { -1.0, -1.0, -1.0 }, { 1.0, 1.0, 1.0 });
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	return iEntity;
}

public CWeapon__Create_StarDecal(Float: vecOrigin[3])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!iEntity) return FM_NULLENT;

	new Float: vecVelocity[3];
	vecVelocity[0] = random_float(-150.0, 150.0);
	vecVelocity[1] = random_float(-150.0, 150.0);
	vecVelocity[2] = random_float(-150.0, 150.0) + random_float(25.0, 100.0);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_StarSprite);
	set_pev(iEntity, pev_solid, SOLID_NOT);
	set_pev(iEntity, pev_movetype, MOVETYPE_PUSHSTEP);
	set_pev(iEntity, pev_velocity, vecVelocity);
	set_pev(iEntity, pev_nextthink, get_gametime() + 1.5);
	set_pev(iEntity, pev_scale, 0.05);

	engfunc(EngFunc_SetModel, iEntity, WEAPON_DECAL_STAR_SPRITE);
	engfunc(EngFunc_SetSize, iEntity, {-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0});
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	Sprite_SetTransparency(iEntity, kRenderTransAdd, 255.0);

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
stock Sprite_SetTransparency(const iSprite, const iRendermode, const Float: flAmt, const iFx = kRenderFxNone)
{
	set_pev(iSprite, pev_rendermode, iRendermode);
	set_pev(iSprite, pev_renderamt, flAmt);
	set_pev(iSprite, pev_renderfx, iFx);
}

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
	new szSprite[33], iStatus;
	new iClip = get_pdata_int(iItem, m_iInfernalFlames, linux_diff_weapon);
	if(iClip >= WEAPON_INFERNAL_FLAME_MAX || iClip > 9)
		format(szSprite, charsmax(szSprite), "number_%i", (iClip >= 9) ? 9 : WEAPON_INFERNAL_FLAME_MAX), iStatus = 2;
	else format(szSprite, charsmax(szSprite), "number_%d", iClip), iStatus = 1;

	message_begin(MSG_ONE, gl_iMsgID_StatusIcon, { 0, 0, 0 }, iPlayer);
	write_byte((iUpdateMode && iClip > 0) ? iStatus : 0);
	write_string(szSprite);
	write_byte(255);
	write_byte(128);
	write_byte(0);
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
