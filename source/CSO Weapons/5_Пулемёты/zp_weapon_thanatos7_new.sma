/*
	 _______ _    _          _   _       _______ ____   _____            ______ 
	|__   __| |  | |   /\   | \ | |   /\|__   __/ __ \ / ____|          |____  |
	   | |  | |__| |  /  \  |  \| |  /  \  | | | |  | | (___    ______      / / 
	   | |  |  __  | / /\ \ | . ` | / /\ \ | | | |  | |\___ \  |______|    / /  
	   | |  | |  | |/ ____ \| |\  |/ ____ \| | | |__| |____) |            / /   
	   |_|  |_|  |_/_/    \_\_| \_/_/    \_\_|  \____/|_____/            /_/    

	[1.0 - 2017]
		- Первый релиз

	[2.0 - 2018]
		- Абсолютно новый код
		- Исправлены недочёты
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <zpe_knokcback>


#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define Get_WeaponState(%0) (get_pdata_int(%0, m_iWeaponState, linux_diff_weapon) == STATE_IN_MODE)
#define Set_WeaponState(%0,%1) set_pdata_int(%0, m_iWeaponState, %1, linux_diff_weapon)

#define PDATA_SAFE 2

enum
{
	WEAPON_ANIM_IDLE_A = 0,
	WEAPON_ANIM_IDLE_B,
	WEAPON_ANIM_IDLE_B2,
	WEAPON_ANIM_SHOOT_A,
	WEAPON_ANIM_SHOOT_B,
	WEAPON_ANIM_RELOAD_A = 7,
	WEAPON_ANIM_RELOAD_B,
	WEAPON_ANIM_SCYTHE_SHOOT,
	WEAPON_ANIM_SCYTHE_START,
	WEAPON_ANIM_DRAW_A,
	WEAPON_ANIM_DRAW_B
};

enum
{
	STATE_NONE = 0,
	STATE_IN_CHANGE,
	STATE_IN_MODE
};

// From model: Frames/FPS
#define WEAPON_ANIM_IDLE_TIME 91/30.0
#define WEAPON_ANIM_SHOOT_TIME 16/30.0
#define WEAPON_ANIM_RELOAD_TIME 96/30.0
#define WEAPON_ANIM_DRAW_TIME 61/30.0
#define WEAPON_ANIM_SCYTHE_START_TIME 91/30.0
#define WEAPON_ANIM_SCYTHE_SHOOT_TIME 121/30.0

#define WEAPON_SPECIAL_CODE 1047
#define WEAPON_REFERENCE "weapon_m249"
#define WEAPON_NEW_NAME "zp_br_cso/weapons4/weapon_thanatos7"

#define WEAPON_ITEM_NAME "Thanatos-7"
#define WEAPON_ITEM_COST 0

#define WEAPON_MODEL_VIEW "models/zp_br_cso/weapons4/v_thanatos7_fix.mdl"

#define WEAPON_MODEL_WORLD "models/zp_br_cso/other/w_weapons4.mdl"
#define WEAPON_BODY 2

#define WEAPON_SOUND_SHOOT "weapons/thanatos7-1.wav"
#define WEAPON_SOUND_SHOOT_B "weapons/thanatos7_scytheshoot.wav"

#define WEAPON_MAX_CLIP 100
#define WEAPON_DEFAULT_AMMO 200
#define WEAPON_RATE 0.1
#define WEAPON_PUNCHANGLE 0.948
#define WEAPON_DAMAGE 1.42

#define ENTITY_SCYTHE_CLASSNAME "ent_th7_scythe"
#define ENTITY_SCYTHE_MODEL "models/zp_br_cso/weapons4/thanatos7_scythe.mdl"
#define ENTITY_SCYTHE_SPEED 1500.0
#define ENTITY_SCYTHE_RADIUS 33.2
#define ENTITY_SCYTHE_DAMAGE random_float(130.0, 220.0)
#define ENTITY_SCYTHE_ALIVETIME 5.5
#define ENTITY_SCYTHE_DMGTIME 0.1
#define ENTITY_SCYTHE_DMGTYPE DMG_BURN

new const iWeaponList[] =
{
	3, 200,-1, -1, 0, 4, 20, 0 // weapon_m249
};

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
#define m_iWeaponState 74

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

new g_iszAllocString_Entity,
	g_iszAllocString_ModelView,

	g_iszAllocString_InfoTarget,
	g_iszAllocString_ScytheClass,

	HamHook: g_HamHook_TraceAttack[4],

	g_iMsgID_Weaponlist,
	g_iItemID;

public plugin_init()
{
	register_plugin("[ZP] Weapon: THANATOS-7", "2.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

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

	RegisterHam(Ham_Think,					"info_target",		"CScythe__Think_Pre", false);
	RegisterHam(Ham_Touch,					"info_target",		"CScythe__Touch_Pre", false);
	
	fm_ham_hook(false);

	g_iMsgID_Weaponlist = get_user_msgid("WeaponList");
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_NEW_NAME, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, ENTITY_SCYTHE_MODEL);

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_NEW_NAME);
	
	// Precache sounds
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_SHOOT);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_SHOOT_B);

	// Other
	g_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	g_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);

	g_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");
	g_iszAllocString_ScytheClass = engfunc(EngFunc_AllocString, ENTITY_SCYTHE_CLASSNAME);
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

	Set_WeaponState(iEntity, 0);

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
		case STATE_NONE, STATE_IN_CHANGE: set_pdata_int(iItem, m_iWeaponState, STATE_NONE, linux_diff_weapon);
		case STATE_IN_MODE: set_pdata_int(iItem, m_iWeaponState, STATE_IN_MODE, linux_diff_weapon);
	}
	
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

	UTIL_SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? WEAPON_ANIM_DRAW_B : WEAPON_ANIM_DRAW_A);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iButton; iButton = pev(iPlayer, pev_button);

	// reload
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

	// change mode
	if(get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon) == STATE_IN_CHANGE)
	{
		set_pdata_int(iItem, m_iWeaponState, STATE_IN_MODE, linux_diff_weapon);
		set_pdata_float(iPlayer, m_flNextAttack, 0.01, linux_diff_player);
	}

	// secondary attack
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

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInReload, 1, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? WEAPON_ANIM_RELOAD_B : WEAPON_ANIM_RELOAD_A);

	// set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	// set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!CustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? random_num(WEAPON_ANIM_IDLE_B2, WEAPON_ANIM_IDLE_B2) : WEAPON_ANIM_IDLE_A);
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
	vecPunchangle[0] *= WEAPON_PUNCHANGLE;
	vecPunchangle[1] *= WEAPON_PUNCHANGLE;
	vecPunchangle[2] *= WEAPON_PUNCHANGLE;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	UTIL_SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? WEAPON_ANIM_SHOOT_B : WEAPON_ANIM_SHOOT_A);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_SHOOT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

	if(get_pdata_int(iItem, m_iClip, linux_diff_weapon) == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextSecondaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	new Float: flTime;
	switch(get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon))
	{
		case STATE_NONE:
		{
			Set_WeaponState(iItem, STATE_IN_CHANGE);

			flTime = WEAPON_ANIM_SCYTHE_START_TIME;
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SCYTHE_START);
		}
		case STATE_IN_MODE:
		{
			Set_WeaponState(iItem, STATE_NONE);

			flTime = WEAPON_ANIM_SCYTHE_SHOOT_TIME;
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SCYTHE_SHOOT);
			emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_SHOOT_B, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			Create_Scythe(iPlayer);
		}
	}

	set_pdata_float(iItem, m_flNextPrimaryAttack, flTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, flTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, flTime, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, flTime, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float:flDamage)
{
	if(!is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(iItem <= 0 || !CustomItem(iItem)) return;

	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

public CScythe__Think_Pre(iEntity)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == g_iszAllocString_ScytheClass)
	{
		set_pev(iEntity, pev_flags, FL_KILLME);
	}

	return HAM_IGNORED;
}

public CScythe__Touch_Pre(iEntity, iVictim)
{
	if(pev_valid(iEntity) != PDATA_SAFE || pev(iVictim, pev_solid) == SOLID_TRIGGER) return HAM_IGNORED;

	if(pev(iEntity, pev_classname) == g_iszAllocString_ScytheClass)
	{
		/* По тимейтам не ебашит */
		if(is_user_connected(iVictim) && !zp_get_user_zombie(iVictim))
			return HAM_SUPERCEDE;

		new iOwner = pev(iEntity, pev_owner);
		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);

		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		if(iVictim == iOwner) return HAM_SUPERCEDE;

		static Float: flGameTime; flGameTime = get_gametime();
		static Float: flDmgTime; //pev(iVictim, pev_dmgtime, flDmgTime);

		set_pev(iEntity, pev_velocity, Float: { 0.0, 0.0, 0.0 });
		set_pev(iEntity, pev_movetype, MOVETYPE_NONE);

		iVictim = FM_NULLENT;
		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_SCYTHE_RADIUS)) > 0)
		{
			if(pev_valid(iVictim) != PDATA_SAFE) continue;
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
			pev(iVictim, pev_dmgtime, flDmgTime);
			if(flDmgTime <= flGameTime)
			{
				set_pev(iVictim, pev_dmgtime, flGameTime + 0.3);

				set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);
				ExecuteHamB(Ham_TakeDamage, iVictim, iOwner, iOwner, ENTITY_SCYTHE_DAMAGE, ENTITY_SCYTHE_DMGTYPE);
				zp_set_user_velocitymifier(iVictim, 0.32)
			}
			
		}	
	}

	return HAM_IGNORED;
}

// [ Other ]
public Create_Scythe(iPlayer)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, g_iszAllocString_InfoTarget);
	if(!pev_valid(iEntity)) return 0;

	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecVelocity[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecVelocity);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);

	vecOrigin[0] += vecViewOfs[0] + vecVelocity[0] * 20.0;
	vecOrigin[1] += vecViewOfs[1] + vecVelocity[1] * 20.0;
	vecOrigin[2] += vecViewOfs[2] + vecVelocity[2] * 20.0;

	vecVelocity[0] *= ENTITY_SCYTHE_SPEED;
	vecVelocity[1] *= ENTITY_SCYTHE_SPEED;
	vecVelocity[2] *= ENTITY_SCYTHE_SPEED;

	new Float: flGameTime = get_gametime();

	set_pev_string(iEntity, pev_classname, g_iszAllocString_ScytheClass);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_velocity, vecVelocity);
	set_pev(iEntity, pev_nextthink, flGameTime + ENTITY_SCYTHE_ALIVETIME);

	engfunc(EngFunc_VecToAngles, vecVelocity, vecAngles);
	set_pev(iEntity, pev_angles, vecAngles);

	set_pev(iEntity, pev_animtime, flGameTime);
	set_pev(iEntity, pev_framerate, 1.0);
	set_pev(iEntity, pev_frame, 1.0);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_SCYTHE_MODEL);
	engfunc(EngFunc_SetSize, iEntity, Float: { -1.0, -1.0, -1.0 }, Float: { 1.0, 1.0, 1.0 });
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	return iEntity;
}

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
/*stock is_wall_between_points(iPlayer, iEntity)
{
	// vector
	#define Vector_Equal(%0,%1) ((%1[0] == %0[0]) && (%1[1] == %0[1]) && (%1[2] == %0[2]))

	if(!is_user_alive(iEntity))
		return 0;

	new iTrace = create_tr2();
	new Float: flStart[3], Float: flEnd[3], Float: flEndPos[3];

	pev(iPlayer, pev_origin, flStart);
	pev(iEntity, pev_origin, flEnd);

	engfunc(EngFunc_TraceLine, flStart, flEnd, IGNORE_MONSTERS, iPlayer, iTrace);
	get_tr2(iTrace, TR_vecEndPos, flEndPos);

	free_tr2(iTrace);

	return Vector_Equal(flEnd, flEndPos);
}*/

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