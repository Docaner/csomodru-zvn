#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define weaponHasMaxHits(%0) (get_pdata_int(%0, m_iHitCount, linux_diff_weapon) >= WEAPON_HIT_COUNT_SHOOT)
#define weaponHasJanusMode(%0) (get_pdata_int(%0, m_iJanusMode, linux_diff_weapon))

#define PDATA_SAFE 2
#define m_iHitCount m_iGlock18ShotsFired
#define m_iJanusMode m_iFamasShotsFired

/*
 * ' ' - A mode
 * _B - B mode
 * _R - Ready to B
 */
enum _: eAnimList
{
	WEAPON_ANIM_IDLE = 0,
	WEAPON_ANIM_CHANGE_TO_B,
	WEAPON_ANIM_SHOOT,
	WEAPON_ANIM_INSERT,
	WEAPON_ANIM_END,
	WEAPON_ANIM_START,
	WEAPON_ANIM_DRAW,
	WEAPON_ANIM_IDLE_B,
	WEAPON_ANIM_SHOOT_B,
	WEAPON_ANIM_DRAW_B,
	WEAPON_ANIM_CHANGE_TO_A,
	WEAPON_ANIM_IDLE_R,
	WEAPON_ANIM_INSERT_R,
	WEAPON_ANIM_END_R,
	WEAPON_ANIM_START_R,
	WEAPON_ANIM_SHOOT_R,
	WEAPON_ANIM_DRAW_R
};

// From model: Frames/FPS
#define WEAPON_ANIM_IDLE_TIME 51/30.0
#define WEAPON_ANIM_SHOOT_TIME 31/30.0
#define WEAPON_ANIM_INSERT_TIME 14/30.0
#define WEAPON_ANIM_END_TIME 27/30.0
#define WEAPON_ANIM_START_TIME 16/30.0
#define WEAPON_ANIM_DRAW_TIME 41/30.0
#define WEAPON_ANIM_CHANGE_TIME 51/30.0

#define WEAPON_SPECIAL_CODE 207225
#define WEAPON_REFERENCE "weapon_m3"
#define WEAPON_NEW_NAME "x/weapon_janus11"

#define WEAPON_ITEM_NAME "JANUS-XI"
#define WEAPON_ITEM_COST 0

#define WEAPON_MODEL_VIEW "models/x/v_janus11.mdl"
#define WEAPON_MODEL_PLAYER "models/x/p_janus11.mdl"
#define WEAPON_MODEL_WORLD "models/x/w_janus11.mdl"
#define WEAPON_BODY 0

#define WEAPON_SOUND_SHOOT "weapons/janus11-1.wav"
#define WEAPON_SOUND_SHOOT_B "weapons/janus11-4.wav"

#define WEAPON_MAX_CLIP 15
#define WEAPON_DEFAULT_AMMO 32
#define WEAPON_RATE WEAPON_ANIM_SHOOT_TIME - 0.3
#define WEAPON_PUNCHANGLE 0.98
#define WEAPON_DAMAGE 1.13

#define WEAPON_RATE_B 0.45
#define WEAPON_PUNCHANGLE_B 0.78
#define WEAPON_DAMAGE_B WEAPON_DAMAGE * 1.5

#define WEAPON_HIT_COUNT_SHOOT 200 // Сколько нужно попасть для активации (1 попадание всеми пулями +9)
#define WEAPON_JANUS_MODE_TIME 10.0 // Время режима

new const iWeaponList[] = { 5, 32, -1, -1, 0, 5, 21, 0 };

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
#define m_fInSpecialReload 55
#define m_iGlock18ShotsFired 70
#define m_iFamasShotsFired 72

// CBaseMonster
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

new g_iszAllocString_Entity,
	g_iszAllocString_ModelView, 
	g_iszAllocString_ModelPlayer,

	g_iszModelIndex_BeamEnt,

	HamHook: g_HamHook_TraceAttack[4],

	g_iMsgID_Weaponlist,
	g_iItemID;

public plugin_init()
{
	register_plugin("[ZP] Weapon: JANUS-11", "1.0.1", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	g_iItemID = zp_register_extra_item(WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN);

	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);

	RegisterHam(Ham_Item_Holster,			WEAPON_REFERENCE,	"CWeapon__Holster_Post", true);
	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	WEAPON_REFERENCE,	"CWeapon__SecondaryAttack_Pre", false);
	
	g_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,		"func_breakable",	"CEntity__TraceAttack_Pre", false);
	g_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,		"info_target",		"CEntity__TraceAttack_Pre", false);
	g_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,		"player",			"CEntity__TraceAttack_Pre", false);
	g_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,		"hostage_entity",	"CEntity__TraceAttack_Pre", false);
	
	fm_ham_hook(false);

	g_iMsgID_Weaponlist = get_user_msgid("WeaponList");
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_NEW_NAME, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_NEW_NAME);
	
	// Precache sounds
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_SHOOT);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_SHOOT_B);

	UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW);

	// Other
	g_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	g_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	g_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);

	// Model Index
	g_iszModelIndex_BeamEnt = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr");
}

// [ Amxx ]
public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem == g_iItemID)
		Command_GiveWeapon(iPlayer);
}

public Command_HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

public Command_GiveWeapon(iPlayer)
{
	static iEntity; iEntity = engfunc(EngFunc_CreateNamedEntity, g_iszAllocString_Entity);
	if(iEntity <= 0) return 0;

	set_pev(iEntity, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, iEntity);
	UTIL_DropWeapon(iPlayer, 1);

	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iEntity))
	{
		set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
		return 0;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, iEntity, iPlayer);
	set_pdata_int(iEntity, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);

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
	if(pev_valid(iItem) != PDATA_SAFE || !CustomItem(iItem)) return;

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

		if(iItem > 0 && CustomItem(iItem))
		{
			engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
			set_pev(iEntity, pev_body, WEAPON_BODY);
			
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;

public FM_Hook_TraceLine_Post(const Float: flOrigin1[3], const Float: flOrigin2[3], iFrag, iAttacker, iTrace)
{
	if(iFrag & IGNORE_MONSTERS) return FMRES_IGNORED;

	static pHit; pHit = get_tr2(iTrace, TR_pHit);
	static Float: flvecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, flvecEndPos);

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(iItem || CustomItem(iItem))
	{
		if(weaponHasJanusMode(iItem))
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_BEAMPOINTS)
			engfunc(EngFunc_WriteCoord, flOrigin1[0]);
			engfunc(EngFunc_WriteCoord, flOrigin1[1]);
			engfunc(EngFunc_WriteCoord, flOrigin1[2]);
			engfunc(EngFunc_WriteCoord, flvecEndPos[0]);
			engfunc(EngFunc_WriteCoord, flvecEndPos[1]);
			engfunc(EngFunc_WriteCoord, flvecEndPos[2]);
			write_short(g_iszModelIndex_BeamEnt);
			write_byte(0); // start frame
			write_byte(0); // framerate
			write_byte(5); // life
			write_byte(5); // line width
			write_byte(0); // amplitude
			write_byte(220);
			write_byte(88);
			write_byte(0); // blue
			write_byte(255); // brightness
			write_byte(0); // speed
			message_end();
		}
	}

	if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, flvecEndPos, 0);
	write_byte(TE_GUNSHOTDECAL);
	engfunc(EngFunc_WriteCoord, flvecEndPos[0]);
	engfunc(EngFunc_WriteCoord, flvecEndPos[1]);
	engfunc(EngFunc_WriteCoord, flvecEndPos[2]);
	write_short(pHit > 0 ? pHit : 0);
	write_byte(random_num(41, 45));
	message_end();

	return FMRES_IGNORED;
}

// [ HamSandwich ]
public CWeapon__Holster_Post(iItem)
{
	if(!CustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	
	set_pdata_int(iItem, m_fInSpecialReload, 0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CWeapon__Deploy_Post(iItem)
{
	if(!CustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, g_iszAllocString_ModelView);
	set_pev_string(iPlayer, pev_weaponmodel2, g_iszAllocString_ModelPlayer);

	UTIL_SendWeaponAnim(iPlayer, weaponHasJanusMode(iItem) ? WEAPON_ANIM_DRAW_B : weaponHasMaxHits(iItem) ? WEAPON_ANIM_DRAW_R : WEAPON_ANIM_DRAW);

	set_pdata_int(iItem, m_fInSpecialReload, 0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
	static iButton; iButton = pev(iPlayer, pev_button);
	static Float: flGameTime; flGameTime = get_gametime();
	static Float: flJanusTime; pev(iItem, pev_fuser4, flJanusTime);

	if(weaponHasJanusMode(iItem) && flJanusTime < flGameTime)
	{
		set_pdata_int(iItem, m_iJanusMode, 0, linux_diff_weapon);

		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHANGE_TO_A);

		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
	}

	if(get_pdata_int(iItem, m_fInSpecialReload, linux_diff_weapon) == 1)
	{
		if(get_pdata_float(iItem, m_flNextSecondaryAttack, linux_diff_weapon) > 0.0) return HAM_IGNORED;

		if(iAmmo <= 0 || iClip == WEAPON_MAX_CLIP)
		{
			set_pdata_int(iItem, m_fInSpecialReload, 0, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_END_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_END_TIME, linux_diff_weapon);

			UTIL_SendWeaponAnim(iPlayer, weaponHasMaxHits(iItem) ? WEAPON_ANIM_END_R : WEAPON_ANIM_END);
		}
		else
		{
			set_pdata_int(iItem, m_iClip, iClip + 1, linux_diff_weapon);
			set_pdata_int(iPlayer, iAmmoType, iAmmo - 1, linux_diff_player);
			set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_INSERT_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_INSERT_TIME, linux_diff_weapon);

			UTIL_SendWeaponAnim(iPlayer, weaponHasMaxHits(iItem) ? WEAPON_ANIM_INSERT_R : WEAPON_ANIM_INSERT);
		}
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
	switch(pev(iItem, pev_impulse))
	{
		case WEAPON_SPECIAL_CODE: UTIL_WeaponList(iPlayer, true);
		case 0: UTIL_WeaponList(iPlayer, false);
	}
}

public CWeapon__Reload_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;
	if(get_pdata_int(iItem, m_fInSpecialReload, linux_diff_weapon) != 0) return HAM_SUPERCEDE;
	if(weaponHasJanusMode(iItem)) return HAM_SUPERCEDE;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInSpecialReload, 1, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, weaponHasMaxHits(iItem) ? WEAPON_ANIM_START_R : WEAPON_ANIM_START);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_START_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_START_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_START_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_START_TIME, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!CustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, weaponHasJanusMode(iItem) ? WEAPON_ANIM_IDLE_B : weaponHasMaxHits(iItem) ? WEAPON_ANIM_IDLE_R : WEAPON_ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);

	if(!weaponHasJanusMode(iItem))
	{
		if(iClip == 0)
		{
			ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
			set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

			return HAM_SUPERCEDE;
		}
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
	static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
	fm_ham_hook(true);

	if(weaponHasJanusMode(iItem)) set_pdata_int(iItem, m_iClip, iClip + 1, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);

	unregister_forward(FM_TraceLine, fw_TraceLine, true);
	unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
	fm_ham_hook(false);

	static Float:vecPunchangle[3];
	pev(iPlayer, pev_punchangle, vecPunchangle);
	vecPunchangle[0] *= weaponHasJanusMode(iItem) ? WEAPON_PUNCHANGLE_B : WEAPON_PUNCHANGLE;
	vecPunchangle[1] *= weaponHasJanusMode(iItem) ? WEAPON_PUNCHANGLE_B : WEAPON_PUNCHANGLE;
	vecPunchangle[2] *= weaponHasJanusMode(iItem) ? WEAPON_PUNCHANGLE_B : WEAPON_PUNCHANGLE;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	set_pdata_int(iItem, m_fInSpecialReload, 0, linux_diff_weapon);

	if(weaponHasJanusMode(iItem))
	{
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT_B);
		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_SHOOT_B, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	}
	else
	{
		UTIL_SendWeaponAnim(iPlayer, weaponHasMaxHits(iItem) ? WEAPON_ANIM_SHOOT_R : WEAPON_ANIM_SHOOT);
		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_SHOOT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}

	set_pdata_float(iItem, m_flNextPrimaryAttack, weaponHasJanusMode(iItem) ? WEAPON_RATE_B : WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, weaponHasJanusMode(iItem) ? WEAPON_RATE_B : WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;
	if(!weaponHasMaxHits(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static Float: flGameTime; flGameTime = get_gametime();

	set_pdata_int(iItem, m_iHitCount, 0, linux_diff_weapon);
	set_pdata_int(iItem, m_iJanusMode, 1, linux_diff_weapon);
	set_pev(iItem, pev_fuser4, flGameTime + WEAPON_JANUS_MODE_TIME);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHANGE_TO_B);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);

	return HAM_IGNORED;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float:flDamage)
{
	if(!is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(iItem <= 0 || !CustomItem(iItem)) return;

	if(is_user_alive(iVictim) && zp_get_user_zombie(iVictim) && !weaponHasMaxHits(iItem) && !weaponHasJanusMode(iItem))
		set_pdata_int(iItem, m_iHitCount, get_pdata_int(iItem, m_iHitCount, linux_diff_weapon) + 1, linux_diff_weapon);

	SetHamParamFloat(3, flDamage * (weaponHasJanusMode(iItem) ? WEAPON_DAMAGE_B : WEAPON_DAMAGE));
}

// [ Other ]
public fm_ham_hook(bool: bEnabled)
{
	if(bEnabled)
	{
		EnableHamForward(g_HamHook_TraceAttack[0]);
		EnableHamForward(g_HamHook_TraceAttack[1]);
		EnableHamForward(g_HamHook_TraceAttack[2]);
		EnableHamForward(g_HamHook_TraceAttack[3]);
	}
	else 
	{
		DisableHamForward(g_HamHook_TraceAttack[0]);
		DisableHamForward(g_HamHook_TraceAttack[1]);
		DisableHamForward(g_HamHook_TraceAttack[2]);
		DisableHamForward(g_HamHook_TraceAttack[3]);
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
	static iEntity, iNext, szWeaponName[32];
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

	if(iEntity > 0)
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
	message_begin(MSG_ONE, g_iMsgID_Weaponlist, _, iPlayer);
	write_string(bEnabled ? WEAPON_NEW_NAME : WEAPON_REFERENCE);
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