#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define Weapon_InMode(%0) (get_pdata_int(%0, m_iWeaponState, linux_diff_weapon) == STATE_IN_MODE)

#define PDATA_SAFE 2

// native zp_set_item_max_clip(iPlayer, iValue);
// native zp_set_item_max_ammo(iPlayer, iValue);
// forward zp_weapon_buyammo(iPlayer, iActiveItem);

#define WEAPON_ANIM_IDLE 0
#define WEAPON_ANIM_SHOOT random_num(1, 2)
#define WEAPON_ANIM_INSERT 3
#define WEAPON_ANIM_RELOAD_END 4
#define WEAPON_ANIM_RELOAD_START 5
#define WEAPON_ANIM_DRAW 6
#define WEAPON_ANIM_SHOOT_2 7
#define WEAPON_ANIM_CHANGE1 8
#define WEAPON_ANIM_CHANGE2 9
#define WEAPON_ANIM_IDLE_2 10
#define WEAPON_ANIM_INSERT_2 11
#define WEAPON_ANIM_RELOAD_END_2 12
#define WEAPON_ANIM_RELOAD_START_2 13
#define WEAPON_ANIM_DRAW_2 14

// From model: Frames/FPS
#define WEAPON_ANIM_IDLE_TIME 51/30.0
#define WEAPON_ANIM_SHOOT_TIME 38/30.0
#define WEAPON_ANIM_INSERT_TIME 16/30.0
#define WEAPON_ANIM_RELOAD_END_TIME 30/30.0
#define WEAPON_ANIM_RELOAD_START_TIME 15/30.0
#define WEAPON_ANIM_DRAW_TIME 31/30.0
#define WEAPON_ANIM_CHANGE_TIME 61/30.0

#define WEAPON_SPECIAL_CODE 1027
#define WEAPON_REFERENCE "weapon_xm1014"
#define WEAPON_NEW_NAME "zp_br_cso/weapons2/weapon_spas12"

#define WEAPON_ITEM_NAME "SPAS-12"
#define WEAPON_ITEM_COST 0

#define WEAPON_MODEL_VIEW "models/zp_br_cso/weapons2/v_spas12.mdl"
#define WEAPON_MODEL_WORLD "models/zp_br_cso/other/w_weapons_b1.mdl"
#define WEAPON_BODY 11

#define WEAPON_SOUND_SHOOT "weapons/spas12-1.wav"
#define WEAPON_SOUND_SHOOT_2 "weapons/spas12-2.wav"

#define WEAPON_MAX_CLIP 8
#define WEAPON_DEFAULT_AMMO 32
#define WEAPON_RATE 0.915
#define WEAPON_RATE_2 0.3
#define WEAPON_PUNCHANGLE 0.7
#define WEAPON_PUNCHANGLE_2 1.0
#define WEAPON_DAMAGE 1.375
#define WEAPON_DAMAGE_2 1.485
#define WEAPON_RELOAD_BLOCK 1.0

new const iWeaponList[] = 
{
	5,  32, -1, -1, 0, 12,5,  0 // weapon_xm1014
};

enum _: eWeaponState
{
	STATE_NONE = 0,
	STATE_IN_CHANGE1,
	STATE_IN_MODE,
	STATE_IN_CHANGE2
};

// Linux extra offsets
#define linux_diff_animating 4
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
#define m_iWeaponState 74

// CBaseMonster
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376
#define m_szAnimExtention 492

new g_iszAllocString_Entity,
	g_iszAllocString_ModelView, 

	HamHook: g_HamHook_TraceAttack[4],

	g_iMsgID_Weaponlist,
	g_iItemID;

public plugin_init()
{
	register_plugin("[ZP] Weapon: SPAS-12 EX", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

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

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_NEW_NAME);
	
	// Precache sounds
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_SHOOT);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_SHOOT_2);

	// Other
	g_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	g_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
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

public FM_Hook_TraceLine_Post(const Float:flOrigin1[3], const Float:flOrigin2[3], iFrag, iAttacker, iTrace)
{
	if(iFrag & IGNORE_MONSTERS) return FMRES_IGNORED;

	static pHit; pHit = get_tr2(iTrace, TR_pHit);
	static Float:flvecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, flvecEndPos);

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

	switch(get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon))
	{
		case STATE_NONE, STATE_IN_CHANGE1: set_pdata_int(iItem, m_iWeaponState, STATE_NONE, linux_diff_weapon);
		case STATE_IN_MODE, STATE_IN_CHANGE2: set_pdata_int(iItem, m_iWeaponState, STATE_IN_MODE, linux_diff_weapon);
	}
	
	set_pdata_int(iItem, m_fInSpecialReload, 0, linux_diff_weapon)
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

	UTIL_SendWeaponAnim(iPlayer, Weapon_InMode(iItem) ? WEAPON_ANIM_DRAW_2 : WEAPON_ANIM_DRAW);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
	set_pdata_string(iPlayer, m_szAnimExtention * 4, "shotgun", -1, linux_diff_player * linux_diff_animating);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iButton; iButton = pev(iPlayer, pev_button);

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);

	if(get_pdata_int(iItem, m_fInSpecialReload, linux_diff_weapon) == 1)
	{
		if(get_pdata_float(iItem, m_flNextSecondaryAttack, linux_diff_weapon) > 0.0) return HAM_IGNORED;

		if(iAmmo <= 0 || iClip == WEAPON_MAX_CLIP)
		{
			set_pdata_int(iItem, m_fInSpecialReload, 0, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_END_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_END_TIME, linux_diff_weapon);

			UTIL_SendWeaponAnim(iPlayer, Weapon_InMode(iItem) ? WEAPON_ANIM_RELOAD_END_2 : WEAPON_ANIM_RELOAD_END);
		}
		else
		{
			set_pdata_int(iItem, m_iClip, iClip + 1, linux_diff_weapon);
			set_pdata_int(iPlayer, iAmmoType, iAmmo - 1, linux_diff_player);
			set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_INSERT_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_INSERT_TIME, linux_diff_weapon);

			UTIL_SendWeaponAnim(iPlayer, Weapon_InMode(iItem) ? WEAPON_ANIM_INSERT_2 : WEAPON_ANIM_INSERT);
		}
	}

	switch(get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon))
	{
		case STATE_NONE:
		{
			if(iButton & IN_ATTACK2 && ~iButton & IN_ATTACK)
			{
				set_pdata_int(iItem, m_iWeaponState, STATE_IN_CHANGE1, linux_diff_weapon);
				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHANGE1);

				set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
				set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_CHANGE_TIME, linux_diff_player);

				iButton &= ~IN_ATTACK2;
				set_pev(iPlayer, pev_button, iButton);
			}
		}
		case STATE_IN_CHANGE1:
		{
			set_pdata_int(iItem, m_iWeaponState, STATE_IN_MODE, linux_diff_weapon);
			set_pdata_float(iPlayer, m_flNextAttack, 0.01, linux_diff_player);
		}
		case STATE_IN_MODE:
		{
			if(iButton & IN_ATTACK2 && ~iButton & IN_ATTACK)
			{
				set_pdata_int(iItem, m_iWeaponState, STATE_IN_CHANGE2, linux_diff_weapon);
				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHANGE2);

				set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_CHANGE_TIME, linux_diff_weapon);
				set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_CHANGE_TIME, linux_diff_player);

				iButton &= ~IN_ATTACK2;
				set_pev(iPlayer, pev_button, iButton);
			}
		}
		case STATE_IN_CHANGE2:
		{
			set_pdata_int(iItem, m_iWeaponState, STATE_NONE, linux_diff_weapon);
			set_pdata_float(iPlayer, m_flNextAttack, 0.01, linux_diff_player);
		}
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

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInSpecialReload, 1, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, Weapon_InMode(iItem) ? WEAPON_ANIM_RELOAD_START_2 : WEAPON_ANIM_RELOAD_START);

	// set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_START_TIME, linux_diff_weapon);
	// set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_START_TIME, linux_diff_weapon);
	// set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_START_TIME, linux_diff_weapon);
	// set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_START_TIME, linux_diff_player);
	
	// new Float:flBlockAttack = Weapon_InMode(iItem) ? WEAPON_RATE_2 : WEAPON_RATE;
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_START_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_START_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_START_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_START_TIME, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!CustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, Weapon_InMode(iItem) ? WEAPON_ANIM_IDLE_2 : WEAPON_ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

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

	static Float:vecPunchangle[3];
	pev(iPlayer, pev_punchangle, vecPunchangle);
	vecPunchangle[0] *= Weapon_InMode(iItem) ? WEAPON_PUNCHANGLE_2 : WEAPON_PUNCHANGLE;
	vecPunchangle[1] *= Weapon_InMode(iItem) ? WEAPON_PUNCHANGLE_2 : WEAPON_PUNCHANGLE;
	vecPunchangle[2] *= Weapon_InMode(iItem) ? WEAPON_PUNCHANGLE_2 : WEAPON_PUNCHANGLE;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	UTIL_SendWeaponAnim(iPlayer, Weapon_InMode(iItem) ? WEAPON_ANIM_SHOOT_2 : WEAPON_ANIM_SHOOT);
	emit_sound(iPlayer, CHAN_WEAPON, Weapon_InMode(iItem) ? WEAPON_SOUND_SHOOT_2 : WEAPON_SOUND_SHOOT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_int(iItem, m_fInSpecialReload, 0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, Weapon_InMode(iItem) ? WEAPON_RATE_2 : WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float:flDamage)
{
	if(!is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(iItem <= 0 || !CustomItem(iItem)) return;

	SetHamParamFloat(3, flDamage * (Weapon_InMode(iItem) ? WEAPON_DAMAGE_2 : WEAPON_DAMAGE));
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