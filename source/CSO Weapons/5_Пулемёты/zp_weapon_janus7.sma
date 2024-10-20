#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <xs>
#include <zpe_knokcback>


// #define DYNAMIC_CROSSHAIR 			// Commend this line if u dont need dynamic crosshair (With it not work's plugin Unlimited Clip)

#define IsValidEntity(%0) 			(pev_valid(%0) == PDATA_SAFE)
#define IsCustomItem(%0) 			(pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define weaponHasMaxHits(%0)		(get_pdata_int(%0, m_iHitCount, linux_diff_weapon) >= JANUS_MODE_HIT_COUNT)
#define weaponHasJanusMode(%0) 		(get_pdata_int(%0, m_iJanusMode, linux_diff_weapon))
#define pItem_iFakeClip(%0)			(get_pdata_int(%0, m_iFakeClip, linux_diff_weapon))

#define m_iFakeClip					m_fInSpecialReload
#define m_iHitCount					m_iGlock18ShotsFired
#define m_iJanusMode 				m_iFamasShotsFired

#define PDATA_SAFE 					2
#define DMG_DAMAGE					(1<<24)

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 		91/30.0
#define WEAPON_ANIM_RELOAD_TIME 	142/30.0
#define WEAPON_ANIM_DRAW_TIME 		34/30.0
#define WEAPON_ANIM_SHOOT_TIME 		31/30.0
#define WEAPON_ANIM_CHANGE1_TIME	61/30.0
#define WEAPON_ANIM_CHANGE2_TIME	61/30.0

enum _: eAnimList
{
	WEAPON_ANIM_IDLE1 = 0,
	WEAPON_ANIM_RELOAD,
	WEAPON_ANIM_DRAW1,
	WEAPON_ANIM_SHOOT1,
	WEAPON_ANIM_SHOOT2,
	WEAPON_ANIM_SHOOT_SIGNAL,
	WEAPON_ANIM_CHANGE_TO_2,

	WEAPON_ANIM_IDLE2,
	WEAPON_ANIM_DRAW2,
	WEAPON_ANIM_SHOOT1_2,
	WEAPON_ANIM_SHOOT2_2,
	WEAPON_ANIM_CHANGE_TO_1,
	WEAPON_ANIM_IDLE_SIGNAL,
	WEAPON_ANIM_RELOAD_SIGNAL,
	WEAPON_ANIM_DRAW_SIGNAL
};

/* ~ [ Extra Item ] ~ */
new const WEAPON_ITEM_NAME[] = 		"Janus-7";
const WEAPON_ITEM_COST = 			0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = 		"weapon_m249";
new const WEAPON_WEAPONLIST[] = 	"zp_br_cso/weapons4/weapon_janus7";
new const WEAPON_NATIVE[] = 		"zp_give_user_janus7";
new const WEAPON_MODEL_VIEW[] = 	"models/zp_br_cso/weapons4/v_janus7.mdl";

new const WEAPON_MODEL_WORLD[] = 	"models/zp_br_cso/other/w_weapons4.mdl";
new const WEAPON_SOUND_FIRE[][] =
{
	"weapons/janus7-1.wav",
	"weapons/janus7-2.wav",
	"common/null.wav"
};
new const WEAPON_RESOURCES[][] =
{
	"sprites/lgtning.spr",
	"sprites/zp_br_cso/weapons4/hud/ef_janus7_hit.spr"
};

const WEAPON_SPECIAL_CODE = 		1044;
const WEAPON_BODY = 				0;

const WEAPON_MAX_CLIP = 			200;
const WEAPON_DEFAULT_AMMO = 		400;
const Float: WEAPON_RATE = 			0.104;
const Float: WEAPON_PUNCHANGLE = 	0.93;
const Float: WEAPON_DAMAGE = 		1.465;

/* ~ [ Janus Mode ] ~ */
const Float: JANUS_MODE_TIME = 		10.0;
const Float: JANUS_MODE_DISTANCE =	220.0;
const Float: JANUS_MODE_DAMAGE =	67.0;
const JANUS_MODE_HIT_COUNT =		85; // In CSO choose random value (~80-140)

new const iWeaponList[] = 
{
	3, 200,-1, -1, 0, 4, 20, 0 // weapon_m249
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
#define m_fInSpecialReload 55
#define m_iGlock18ShotsFired 70
#define m_iFamasShotsFired 72
#define m_flNextReload 75

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

/* ~ [ Params ] ~ */
new gl_iszModelIndex_Resources[sizeof WEAPON_RESOURCES];
new gl_iszAllocString_Entity,
	gl_iszAllocString_ModelView;
new gl_iFakeDefaultAmmo,
	gl_iFakeMaxClip;
new HamHook: gl_HamHook_TraceAttack[4];
new gl_iMsgID_Weaponlist,
	#if defined DYNAMIC_CROSSHAIR
	gl_iMsgID_CurWeapon,
	#endif
	gl_iItemID;

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
	register_plugin("[ZP] Weapon: JANUS-7", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

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
	#if defined DYNAMIC_CROSSHAIR
	gl_iMsgID_CurWeapon = get_user_msgid("CurWeapon");
	#endif

	// Alloc String
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
}

public plugin_precache()
{
	new i;

	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	
	// Precache sounds
	for(i = 0; i < sizeof WEAPON_SOUND_FIRE; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_FIRE[i]);

	// Model Index
	for(i = 0; i < sizeof WEAPON_RESOURCES; i++)
		gl_iszModelIndex_Resources[i] = engfunc(EngFunc_PrecacheModel, WEAPON_RESOURCES[i]);

	// Other
	gl_iFakeDefaultAmmo = floatround(WEAPON_DEFAULT_AMMO/2.0, floatround_ceil);
	gl_iFakeMaxClip = floatround(WEAPON_MAX_CLIP/2.0, floatround_ceil);
}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

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

	set_pdata_int(iEntity, m_iFakeClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	set_pdata_int(iEntity, m_iClip, gl_iFakeMaxClip, linux_diff_weapon);
	UTIL_DropWeapon(iPlayer, 1);

	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iEntity))
	{
		set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
		return 0;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, iEntity, iPlayer);

	new iAmmoType = m_rgAmmo + get_pdata_int(iEntity, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, m_rgAmmo, linux_diff_player) < gl_iFakeDefaultAmmo)
		set_pdata_int(iPlayer, iAmmoType, gl_iFakeDefaultAmmo, linux_diff_player);

	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return 1;
}

/* ~ [ Zombie Plague ] ~ */
public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem == gl_iItemID)
		Command_GiveWeapon(iPlayer);
}

// [ Fakemeta ]
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

// [ HamSandwich ]
public CWeapon__Holster_Post(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pev(iItem, pev_fuser3, 0.0);
	set_pev(iItem, pev_enemy, FM_NULLENT);
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

	static iAnim;
	if(weaponHasJanusMode(iItem)) iAnim = WEAPON_ANIM_DRAW2;
	else
	{
		if(weaponHasMaxHits(iItem)) iAnim = WEAPON_ANIM_DRAW_SIGNAL;
		else iAnim = WEAPON_ANIM_DRAW1;
	}

	UTIL_SendWeaponAnim(iPlayer, iAnim);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);

	#if defined DYNAMIC_CROSSHAIR
	UTIL_ResetCrosshair(iPlayer, iItem, iClip);
	#endif

	static Float: flJanusTime; pev(iItem, pev_fuser4, flJanusTime);
	if(weaponHasJanusMode(iItem) && flJanusTime < get_gametime())
	{
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHANGE_TO_1);
		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		set_pdata_int(iItem, m_iJanusMode, 0, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_CHANGE2_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_CHANGE2_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_CHANGE2_TIME, linux_diff_weapon);
	}

	if(get_pdata_int(iItem, m_fInReload, linux_diff_weapon) == 1)
	{
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
		static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
		static j; j = min(gl_iFakeMaxClip - iClip, iAmmo);

		iClip = iClip + j;
		set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
		set_pdata_int(iItem, m_iFakeClip, floatround(iClip * 2.0), linux_diff_weapon)
		set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
		set_pdata_int(iItem, m_fInReload, 0, linux_diff_weapon);

		#if defined DYNAMIC_CROSSHAIR
		message_begin(MSG_ONE, gl_iMsgID_CurWeapon, _, iPlayer);
		write_byte(true);
		write_byte(iWeaponList[6]);
		write_byte(iClip);
		message_end();
		#endif
	}

	static iButton; iButton = pev(iPlayer, pev_button);
	if(!(iButton & IN_ATTACK) && pev(iPlayer, pev_weaponanim) == WEAPON_ANIM_SHOOT1_2)
	{
		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_pev(iItem, pev_fuser3, 0.0);
		set_pev(iItem, pev_enemy, FM_NULLENT);
	}

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
	if(weaponHasJanusMode(iItem)) return HAM_SUPERCEDE;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= gl_iFakeMaxClip) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInReload, 1, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, weaponHasMaxHits(iItem) ? WEAPON_ANIM_RELOAD_SIGNAL : WEAPON_ANIM_RELOAD);

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

	static iAnim;
	if(weaponHasJanusMode(iItem)) iAnim = WEAPON_ANIM_IDLE2;
	else
	{
		if(weaponHasMaxHits(iItem)) iAnim = WEAPON_ANIM_IDLE_SIGNAL;
		else iAnim = WEAPON_ANIM_IDLE1;
	}

	UTIL_SendWeaponAnim(iPlayer, iAnim);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if( !IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon)
	if(!weaponHasJanusMode(iItem) && !iClip)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	if(weaponHasJanusMode(iItem))
	{
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT1_2);

		static Float: flNextSound; pev(iItem, pev_fuser3, flNextSound);
		if(flNextSound <= get_gametime())
		{
			set_pev(iItem, pev_fuser3, get_gametime() + 1.0);
			emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}

		CWeapon__CreateElectro(iPlayer, iItem);
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

		static Float: vecPunchangle[3];
		pev(iPlayer, pev_punchangle, vecPunchangle);
		vecPunchangle[0] *= WEAPON_PUNCHANGLE;
		vecPunchangle[1] *= WEAPON_PUNCHANGLE;
		vecPunchangle[2] *= WEAPON_PUNCHANGLE;
		set_pev(iPlayer, pev_punchangle, vecPunchangle);

		#if defined DYNAMIC_CROSSHAIR
		UTIL_IncreaseCrosshair(iPlayer, iItem, iClip);
		#endif
		UTIL_SendWeaponAnim(iPlayer, weaponHasMaxHits(iItem) ? WEAPON_ANIM_SHOOT_SIGNAL : WEAPON_ANIM_SHOOT1 + random_num(0, 1));
		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		iClip = floatround(pItem_iFakeClip(iItem)/2.0, floatround_ceil);
		set_pdata_int(iItem, m_iFakeClip, pItem_iFakeClip(iItem)-1, linux_diff_weapon);
		set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	}

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;
	if(!weaponHasMaxHits(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pdata_int(iItem, m_iHitCount, 0, linux_diff_weapon);
	set_pdata_int(iItem, m_iJanusMode, 1, linux_diff_weapon);
	set_pev(iItem, pev_fuser4, get_gametime() + JANUS_MODE_TIME);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHANGE_TO_2);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_CHANGE1_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_CHANGE1_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_CHANGE1_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
	if(!is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;

	if((is_user_alive(iVictim) && zp_get_user_zombie(iVictim) || pev(iVictim, pev_deadflag) == DEAD_NO && pev(iVictim, pev_flags) & FL_MONSTER) && !weaponHasMaxHits(iItem) && !weaponHasJanusMode(iItem))
		set_pdata_int(iItem, m_iHitCount, get_pdata_int(iItem, m_iHitCount, linux_diff_weapon) + 1, linux_diff_weapon);

	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

// [ Other ]
public CWeapon__CreateElectro(iPlayer, iItem)
{
	new Float: vecEndPos[3];
	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

	xs_vec_mul_scalar(vecForward, 150.0, vecForward);
	xs_vec_add(vecViewOfs, vecForward, vecViewOfs);
	xs_vec_add(vecOrigin, vecViewOfs, vecEndPos);

	{
		new iTrace = create_tr2();
		engfunc(EngFunc_TraceLine, vecOrigin, vecEndPos, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
		get_tr2(iTrace, TR_vecEndPos, vecEndPos);
		free_tr2(iTrace);
	}

	UTIL_CreateBeamEntPoint(iPlayer, vecEndPos, 0x1000, gl_iszModelIndex_Resources[0], 50, 24, { 243, 156, 18 });

	new Float: vecVictimOrigin[3], iVictim = FM_NULLENT;
	static Float: flDamage; flDamage = JANUS_MODE_DAMAGE * random_float(0.75, 1.25);
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, JANUS_MODE_DISTANCE)) > 0)
	{
		if(pev(iVictim, pev_takedamage) == DAMAGE_NO) continue;
		if(is_user_alive(iVictim))
		{
			if(iVictim == iPlayer || !zp_get_user_zombie(iVictim) || !is_wall_between_points(iPlayer, iVictim))
				continue;
		}
		else if(pev(iVictim, pev_solid) == SOLID_BSP)
		{
			if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
				continue;
		}

		pev(iVictim, pev_origin, vecVictimOrigin);
		if(pev(iItem, pev_enemy))
		{
			static iAttachedVictim; iAttachedVictim = pev(iItem, pev_enemy);
			static Float: vecAttachedOrigin[3]; pev(iAttachedVictim, pev_origin, vecAttachedOrigin);
			if(!is_user_alive(pev(iItem, pev_enemy)) || get_distance_f(vecOrigin, vecAttachedOrigin) >= JANUS_MODE_DISTANCE)
				set_pev(iItem, pev_enemy, FM_NULLENT);
		}

		if(!pev(iItem, pev_enemy))
		{
			if(fm_is_in_viewcone(iPlayer, vecVictimOrigin))
				set_pev(iItem, pev_enemy, iVictim);
		}
		
		if(pev(iItem, pev_enemy) == iVictim)
		{
			UTIL_CreateExplosion(vecVictimOrigin, 0.0, gl_iszModelIndex_Resources[1], 8, 48, 2|4|8);
			UTIL_CreateBeamPoints(vecEndPos, vecVictimOrigin, gl_iszModelIndex_Resources[0], 75, 58, { 243, 156, 18 });

			if(is_user_alive(iVictim))
				set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);

			ExecuteHamB(Ham_TakeDamage, iVictim, iItem, iPlayer, flDamage, DMG_DAMAGE);
			zp_set_user_velocitymifier(iVictim, 0.8);
		}
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

// [ Stocks ]
stock is_wall_between_points(iPlayer, iEntity)
{
	if(!is_user_alive(iEntity))
		return 0;

	new iTrace = create_tr2();
	new Float: vecStart[3], Float: vecEnd[3], Float: vecEndPos[3];

	pev(iPlayer, pev_origin, vecStart);
	pev(iEntity, pev_origin, vecEnd);

	engfunc(EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, iPlayer, iTrace);
	get_tr2(iTrace, TR_vecEndPos, vecEndPos);

	free_tr2(iTrace);

	return xs_vec_equal(vecEnd, vecEndPos);
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

#if defined DYNAMIC_CROSSHAIR
	stock UTIL_IncreaseCrosshair(iPlayer, iItem, iClip)
	{
		set_msg_block(gl_iMsgID_CurWeapon, BLOCK_ONCE);

		message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, iPlayer);
		write_string(WEAPON_WEAPONLIST);
		write_byte(iWeaponList[0]);
		write_byte(gl_iFakeDefaultAmmo);
		write_byte(iWeaponList[2]);
		write_byte(iWeaponList[3]);
		write_byte(iWeaponList[4]);
		write_byte(13);
		write_byte(7);
		write_byte(iWeaponList[7]);
		message_end();

		message_begin(MSG_ONE, gl_iMsgID_CurWeapon, _, iPlayer);
		write_byte(true);
		write_byte(7);
		write_byte(iClip);
		message_end();

		set_pdata_float(iItem, m_flNextReload, get_gametime() + 0.04, linux_diff_weapon);
	}

	stock UTIL_ResetCrosshair(iPlayer, iItem, iClip)
	{
		if(get_pdata_float(iItem, m_flNextReload, linux_diff_weapon) && get_pdata_float(iItem, m_flNextReload, linux_diff_weapon) <= get_gametime())
		{
			message_begin(MSG_ONE, gl_iMsgID_CurWeapon, _, iPlayer);
			write_byte(true);
			write_byte(iWeaponList[6]);
			write_byte(iClip);
			message_end();

			set_pdata_float(iItem, m_flNextReload, 0.0, linux_diff_weapon);
		}
	}
#endif

stock UTIL_CreateBeamEntPoint(iPlayer, Float: vecEnd[3], iAttachment, iszModelIndex, iWidth, iNoise, iColor[3])
{
	// https://github.com/baso88/SC_AngelScript/wiki/TE_BEAMENTPOINT
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT); // TE
	write_short(iPlayer | iAttachment); // Attachment
	engfunc(EngFunc_WriteCoord, vecEnd[0]); // Postion X
	engfunc(EngFunc_WriteCoord, vecEnd[1]); // Postion Y
	engfunc(EngFunc_WriteCoord, vecEnd[2]); // Postion Z
	write_short(iszModelIndex); // Model Index
	write_byte(0); // Framestart
	write_byte(0); // Framerate
	write_byte(1); // Life
	write_byte(iWidth); // Width
	write_byte(iNoise); // Noise
	write_byte(iColor[0]); // Red
	write_byte(iColor[1]); // Green
	write_byte(iColor[2]); // Blue
	write_byte(250); // Alpha
	write_byte(50); // Speed
	message_end();
}

stock UTIL_CreateBeamPoints(Float: vecStart[3], Float: vecEnd[3], iszModelIndex, iWidth, iNoise, iColor[3])
{
	// https://github.com/baso88/SC_AngelScript/wiki/TE_BEAMPOINTS
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS); // TE
	engfunc(EngFunc_WriteCoord, vecStart[0]); // Postion X
	engfunc(EngFunc_WriteCoord, vecStart[1]); // Postion Y
	engfunc(EngFunc_WriteCoord, vecStart[2]); // Postion Z
	engfunc(EngFunc_WriteCoord, vecEnd[0]); // Postion X
	engfunc(EngFunc_WriteCoord, vecEnd[1]); // Postion Y
	engfunc(EngFunc_WriteCoord, vecEnd[2]); // Postion Z
	write_short(iszModelIndex); // Model Index
	write_byte(0); // Framestart
	write_byte(0); // Framerate
	write_byte(1); // Life
	write_byte(iWidth); // Width
	write_byte(iNoise); // Noise
	write_byte(iColor[0]); // Red
	write_byte(iColor[1]); // Green
	write_byte(iColor[2]); // Blue
	write_byte(250); // Alpha
	write_byte(50); // Speed
	message_end();
}

stock UTIL_CreateExplosion(Float: vecOrigin[3], Float: flSpriteUp, iszModelIndex, iScale, iFrameRate, iFlags)
{
	// https://github.com/baso88/SC_AngelScript/wiki/TE_EXPLOSION
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_EXPLOSION); // TE
	engfunc(EngFunc_WriteCoord, vecOrigin[0]); // Position X
	engfunc(EngFunc_WriteCoord, vecOrigin[1]); // Position Y
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + flSpriteUp); // Position Z
	write_short(iszModelIndex); // Model Index
	write_byte(iScale); // Scale
	write_byte(iFrameRate); // Framerate
	write_byte(iFlags); // Flags
	message_end();
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
	write_byte(bEnabled ? gl_iFakeDefaultAmmo : iWeaponList[1]);
	write_byte(iWeaponList[2]);
	write_byte(iWeaponList[3]);
	write_byte(iWeaponList[4]);
	write_byte(iWeaponList[5]);
	write_byte(iWeaponList[6]);
	write_byte(iWeaponList[7]);
	message_end();
}
