/*
  _____  _                             _____                       _____                
 |  __ \(_)                        _  |  __ \                     / ____|               
 | |__) |_ _ __  _ __   ___ _ __  (_) | |__) |____      _____ _ _| (___   __ ___      __
 |  _  /| | '_ \| '_ \ / _ \ '__|     |  ___/ _ \ \ /\ / / _ \ '__\___ \ / _` \ \ /\ / /
 | | \ \| | |_) | |_) |  __/ |     _  | |  | (_) \ V  V /  __/ |  ____) | (_| |\ V  V / 
 |_|  \_\_| .__/| .__/ \___|_|    (_) |_|   \___/ \_/\_/ \___|_| |_____/ \__,_| \_/\_/  
          | |   | |                                                                     
          |_|   |_|                                                                     
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <reapi>
#include <xs>
#include <zp_system>
#include <zp_buymenu>
#include <smart_effects>

#define MONEY_KILL_SAW 7000 // Награда за убийство пилы
#define AMMO_KILL_SAW 10 // Награда за убийство пилы

#define CHAINSAW_START_HEALTH 420.0 // Сколько выдавать минимально HP пиле
#define CHAINSAW_ADD_TO_PLAYER_HEALTH 65.0 // Сколько выдавать дополнительно HP на 1 клиента

#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))


enum _: e_AnimList
{
	WEAPON_ANIM_IDLE = 0,
	WEAPON_ANIM_DRAW,
	WEAPON_ANIM_DRAW_EMPTY,
	WEAPON_ANIM_ATTACK_START,
	WEAPON_ANIM_ATTACK_LOOP,
	WEAPON_ANIM_ATTACK_END,
	WEAPON_ANIM_RELOAD,
	WEAPON_ANIM_SLASH1,
	WEAPON_ANIM_SLASH2,
	WEAPON_ANIM_SLASH3,
	WEAPON_ANIM_SLASH4,
	WEAPON_ANIM_IDLE_EMPTY
};

enum _: e_HitResultList
{
	SLASH_HIT_NONE = 0,
	SLASH_HIT_WORLD,
	SLASH_HIT_ENTITY
};

enum _: e_AttackState
{
	STATE_NONE = 0,
	STATE_IN_LOOP,
	STATE_IN_END
};

// From model: Frames/FPS
#define WEAPON_ANIM_IDLE_TIME 151/30.0
#define WEAPON_ANIM_DRAW_TIME 46/30.0
#define WEAPON_ANIM_ATTACK_START_TIME 16/30.0
#define WEAPON_ANIM_ATTACK_LOOP_TIME 16/30.0
#define WEAPON_ANIM_ATTACK_END_TIME 46/30.0
#define WEAPON_ANIM_RELOAD_TIME 94/30.0
#define WEAPON_ANIM_SLASH_TIME 46/30.0

#define WEAPON_SPECIAL_CODE 3000
#define WEAPON_REFERENCE "weapon_m249"
#define WEAPON_NEW_NAME "zp_br_cso/weapons/weapon_chainsaw2"

#define WEAPON_ITEM_NAME "Ripper (PowerSaw)"
#define WEAPON_ITEM_COST 0

#define WEAPON_MODEL_VIEW "models/zp_br_cso/weapons/v_chainsaw.mdl"
#define WEAPON_MODEL_PLAYER "models/zp_br_cso/weapons/p_chainsaw.mdl"
#define WEAPON_MODEL_WORLD "models/zp_br_cso/weapons/w_chainsaw.mdl"
#define WEAPON_BODY 0

#define WEAPON_SOUND_ATTACK_LOOP "zp_br_cso/weapons/chainsaw_attack1_loop.wav"
#define WEAPON_SOUND_ATTACK_HIT "zp_br_cso/weapons/chainsaw_hit1.wav"
#define WEAPON_SOUND_SLASH_HIT "zp_br_cso/weapons/chainsaw_hit2.wav"
#define WEAPON_SOUND_SLASH_HIT_EMPTY "zp_br_cso/weapons/chainsaw_hit3.wav"

#define WEAPON_MAX_CLIP 100
#define WEAPON_DEFAULT_AMMO 200
#define WEAPON_RATE 0.075

#define WEAPON_ANIM_EXTENSION_A "chainsaw" // Original CSO: chainsaw (aim, reload, shoot)
#define WEAPON_ANIM_EXTENSION_B "chainsaw" // Original CSO: chainsaw (shoot2)

//Settings Fake TraceLines
#define ATTACK_STEP 5.0 // Шаг TraceAttack

#define ATTACK_WIDTH 8.0 // Ширина атаки в градусах
#define ATTACK_HEIGHT 8.0 // Высота атаки в градусах
#define ATTACK_KNOCK 200.0 // Откидывание 
#define ATTACK_DISTANCE 70.0
#define ATTACK_DAMAGE 90.0

#define SLASH_WIDTH 40.0
#define SLASH_HEIGHT 10.0
#define SLASH_KNOCK 600.0
#define SLASH_DISTANCE 80.0
#define SLASH_DAMAGE 700.0

new const iWeaponList[] = 
{ 
	3, 200,-1, -1, 0, 4, 20, 0 // weapon_m249
};

#define DONT_BLEED -1
#define ACT_RANGE_ATTACK1 28

// Linux extra offsets
#define linux_diff_animating 4
#define linux_diff_weapon 4
#define linux_diff_player 5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CBaseAnimating
#define m_flFrameRate 36
#define m_flGroundSpeed 37
#define m_flLastEventCheck 38
#define m_fSequenceFinished 39
#define m_fSequenceLoops 40

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
#define m_Activity 73
#define m_IdealActivity 74
#define m_flNextAttack 83

// CBasePlayer
#define m_flPainShock 108
#define m_iPlayerTeam 114
#define m_flLastAttackTime 220
#define m_rpgPlayerItems 367
#define m_rgAmmo 376
#define m_szAnimExtention 492

new g_iszAllocString_Entity,
	g_iszAllocString_ModelView, 
	g_iszAllocString_ModelPlayer,

	g_iszModelIndexBloodSpray,
	g_iszModelIndexBloodDrop,

	g_iMsgID_Weaponlist,
	g_iItemID,
	g_iMaxPlayers;

public plugin_init()
{
	register_plugin("[ZP] Weapon: Ripper (PowerSaw)", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	g_iItemID = zp_register_extra_item(WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN);

	RegisterHookChain(RG_CSGameRules_RestartRound, "RG_CSGameRules_PlayerSpawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_PlayerKilled_Pre", false);
	//register_clcmd("Io2@dNs", "ClCmd_GetWeapon");

	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);

	RegisterHam(Ham_CS_Item_CanDrop, WEAPON_REFERENCE, "CWeapon__CanDrop_Pre", false);
	RegisterHam(Ham_Item_Holster,			WEAPON_REFERENCE,	"CWeapon__Holster_Post", true);
	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	WEAPON_REFERENCE,	"CWeapon__SecondaryAttack_Pre", false);

	RegisterHookChain(RG_CBasePlayer_Jump, "@RG__Player_Jump_Post", true);

	g_iMsgID_Weaponlist = get_user_msgid("WeaponList");

	g_iMaxPlayers = get_maxplayers();
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
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_ATTACK_LOOP);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_ATTACK_HIT);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_SLASH_HIT);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_SLASH_HIT_EMPTY);

	UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW);

	// Other
	g_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	g_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	g_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);

	// Model Index
	g_iszModelIndexBloodSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
	g_iszModelIndexBloodDrop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");
}

public plugin_natives()
{
	register_native("zpe_get_user_chainsaw", "zpe_get_user_chainsaw", 1);
}

//Проверка на пилу
public zpe_get_user_chainsaw(id)
{
	if(is_nullent(id)) 
		return 0;

	new iItem = get_member(id, m_rgpPlayerItems, PRIMARY_WEAPON_SLOT);

	if(is_nullent(iItem)) 
		return 0;

	return CustomItem(iItem);
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

public ClCmd_GetWeapon(iPlayer)
{
	if(!is_user_alive(iPlayer) || zp_get_user_zombie(iPlayer))
		return;

	Command_GiveWeapon(iPlayer);
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


	new iPlayers[4];
	rg_initialize_player_counts(iPlayers[0], iPlayers[1], iPlayers[2], iPlayers[3]);

	new iCount = iPlayers[0] + iPlayers[1] + iPlayers[2] + iPlayers[3];

	new Float:flHealth = CHAINSAW_START_HEALTH + CHAINSAW_ADD_TO_PLAYER_HEALTH * iCount;
	set_entvar(iPlayer, var_health, flHealth);

	rg_remove_items_by_slot(iPlayer, KNIFE_SLOT);

	zp_set_user_weapon_block(iPlayer, (BLOCK_PRIMARY|BLOCK_SECONDARY));

	return 1;
}

// [ Reapi ]
public RG_CSGameRules_PlayerSpawn_Post()
{
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_alive(iPlayer)) continue;

		remove_saw(iPlayer);
	}
}

public RG_PlayerKilled_Pre(iVictim, iKiller)
{
	if(!zpe_get_user_chainsaw(iVictim)) 
		return;

	remove_saw(iVictim);

	if(iVictim == iKiller || !is_user_connected(iKiller))
		return;

	zp_set_user_money( iKiller, zp_get_user_money(iKiller) + MONEY_KILL_SAW );
	zp_set_user_ammo( iKiller, zp_get_user_ammo(iKiller) + AMMO_KILL_SAW );

	new szKillerName[32]; get_user_name(iKiller, szKillerName, charsmax(szKillerName));		
	client_print_color(0, print_team_default, "^1* ^4%s ^1получил^4 %d$ ^1|^4 %d Ammo ^1за убийство Пилы!", szKillerName, MONEY_KILL_SAW, AMMO_KILL_SAW)
}

// [ Fakemeta ]
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(get_cd(CD_Handle, CD_DeadFlag) != DEAD_NO) return;

	static iItem; iItem = get_member(iPlayer, m_pActiveItem);
	if(iItem <= 0 || !CustomItem(iItem)) return;

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

// [ HamSandwich ]
public CWeapon__CanDrop_Pre(iItem)
{
	if(CustomItem(iItem)) 
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public CWeapon__Holster_Post(iItem)
{
	if(!CustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	
	emit_sound(iPlayer, CHAN_ITEM, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_pdata_int(iItem, m_iWeaponState, STATE_NONE, linux_diff_weapon);
}

public CWeapon__Deploy_Post(iItem)
{
	if(!CustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, g_iszAllocString_ModelView);
	set_pev_string(iPlayer, pev_weaponmodel2, g_iszAllocString_ModelPlayer);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
	set_pdata_string(iPlayer, m_szAnimExtention * 4, WEAPON_ANIM_EXTENSION_A, -1, linux_diff_player * linux_diff_animating);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	static iButton; iButton = pev(iPlayer, pev_button);
	static iWeaponState; iWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);

	switch(iWeaponState)
	{
		case STATE_NONE:
		{
			if(get_pdata_int(iItem, m_fInReload, linux_diff_weapon) == 1)
			{
				static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
				static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
				static j; j = min(WEAPON_MAX_CLIP - iClip, iAmmo);

				set_pdata_int(iItem, m_iClip, iClip + j, linux_diff_weapon);
				set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
				set_pdata_int(iItem, m_fInReload, 0, linux_diff_weapon);
			}

			if(iButton & IN_ATTACK2 && get_pdata_float(iItem, m_flNextSecondaryAttack, linux_diff_weapon) < 0.0)
			{
				ExecuteHamB(Ham_Weapon_SecondaryAttack, iItem);

				iButton &= ~IN_ATTACK2;
				set_pev(iPlayer, pev_button, iButton);
			}
		}
		case STATE_IN_LOOP:
		{
			if((pev(iPlayer, pev_weaponanim) == WEAPON_ANIM_ATTACK_START || pev(iPlayer, pev_weaponanim) == WEAPON_ANIM_ATTACK_LOOP) && !(iButton & IN_ATTACK) || !iClip)
			{
				set_pdata_int(iItem, m_iWeaponState, STATE_IN_END, linux_diff_weapon);
			}
		}
		case STATE_IN_END:
		{
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_ATTACK_END);

			set_pdata_int(iItem, m_iWeaponState, STATE_NONE, linux_diff_weapon);
			set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_ATTACK_END_TIME, linux_diff_player);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_ATTACK_END_TIME, linux_diff_weapon);
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
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInReload, 1, linux_diff_weapon);

	if(get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon) == STATE_IN_LOOP)
		set_pdata_int(iItem, m_iWeaponState, STATE_IN_END, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_RELOAD);

	static szAnimation[64];
	formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_reload_%s" : "ref_reload_%s", WEAPON_ANIM_EXTENSION_A);
	UTIL_PlayerAnimation(iPlayer, szAnimation);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!CustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	static iWeaponState; iWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);
	static szAnimation[64];

	if(iClip == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	switch(iWeaponState)
	{
		case STATE_NONE:
		{
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_ATTACK_START);

			set_pdata_int(iItem, m_iWeaponState, STATE_IN_LOOP, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_ATTACK_START_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_ATTACK_START_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_ATTACK_START_TIME, linux_diff_weapon);
		}
		case STATE_IN_LOOP:
		{
			if(pev(iPlayer, pev_weaponanim) != WEAPON_ANIM_ATTACK_LOOP)
				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_ATTACK_LOOP);

			FakeTraceLine(iPlayer, iItem, 0, ATTACK_DISTANCE, ATTACK_DAMAGE, ATTACK_WIDTH, ATTACK_HEIGHT, ATTACK_KNOCK);

			formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIM_EXTENSION_A);
			UTIL_PlayerAnimation(iPlayer, szAnimation);

			set_pdata_int(iItem, m_iClip, iClip - 1, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_ATTACK_LOOP_TIME, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_ATTACK_LOOP_TIME, linux_diff_weapon);
		}
	}

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	static Float: vecPunchangle[3];
	static szAnimation[64];

	switch(iClip)
	{
		case 0: UTIL_SendWeaponAnim(iPlayer, random_num(WEAPON_ANIM_SLASH3, WEAPON_ANIM_SLASH4));
		default: UTIL_SendWeaponAnim(iPlayer, random_num(WEAPON_ANIM_SLASH1, WEAPON_ANIM_SLASH2));
	}

	vecPunchangle[0] = -5.0;
	vecPunchangle[1] = random_float(-2.5, 2.5);
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	FakeTraceLine(iPlayer, iItem, 1, SLASH_DISTANCE, SLASH_DAMAGE, SLASH_WIDTH, SLASH_HEIGHT, SLASH_KNOCK);

	formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot2_%s" : "ref_shoot2_%s", WEAPON_ANIM_EXTENSION_B);
	UTIL_PlayerAnimation(iPlayer, szAnimation);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SLASH_TIME - 0.3, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_SLASH_TIME - 0.3, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SLASH_TIME - 0.3, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

@RG__Player_Jump_Post(const iPlayer)
{
	if(zp_get_user_zombie(iPlayer) || ~get_entvar(iPlayer, var_flags) & FL_ONGROUND || 
		~get_member(iPlayer, m_afButtonPressed) & IN_JUMP)
		return;

	new iItem = get_member(iPlayer, m_pActiveItem);

	if(is_nullent(iItem) || !CustomItem(iItem))
		return;

	new Float:vecVelocity[3];
	get_entvar(iPlayer, var_velocity, vecVelocity);
	vecVelocity[2] += 350.0;
	set_entvar(iPlayer, var_velocity, vecVelocity);
}

// [ Stocks ]
public FakeTraceLine(iPlayer, iItem, iSlash, Float: flDistance, Float: flDamage, const Float:flWidth, const Float:flHeight, const Float:flKnock)
{
	new iHitResult;

	iHitResult = Create_FakeAttack(iPlayer, flDistance, flDamage, flHeight, flWidth, flKnock);

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);

	switch(iHitResult)
	{
		case SLASH_HIT_NONE:
		{
			if(!iSlash) emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUND_ATTACK_LOOP, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		case SLASH_HIT_WORLD, SLASH_HIT_ENTITY:
		{
			if(iSlash)
			{
				if(iClip) emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_SLASH_HIT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				else emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_SLASH_HIT_EMPTY, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
			else
				emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_ATTACK_HIT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	static Float: vecPunchangle[3];
	vecPunchangle[0] = random_float(-1.7, 1.7);
	vecPunchangle[1] = random_float(-1.7, 1.7);
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

}

stock Create_FakeAttack(id, Float:flDistance, Float:flDamage, const Float:flMaxHeight, const Float:flMaxWidth, const Float:flKnock)
{
	new tr = create_tr2(), Trie:tEntsDamaged = TrieCreate(), iHitAim, iHitResult;

	new Float:flAttackHeight, Float:flAttackWidth;

	flAttackHeight = 0.0;
	iHitAim = Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, flAttackWidth, flAttackHeight, tEntsDamaged, flKnock);

	flAttackHeight = ATTACK_STEP;
	while(flAttackHeight < flMaxHeight / 2.0)
	{
		iHitResult = Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, flAttackWidth, flAttackHeight, tEntsDamaged, flKnock);
		iHitResult = Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, flAttackWidth, -flAttackHeight, tEntsDamaged, flKnock);
		flAttackHeight += ATTACK_STEP;
	}

	flAttackWidth = ATTACK_STEP;
	while(flAttackWidth < flMaxWidth / 2.0)
	{
		flAttackHeight = 0.0;
		iHitResult = Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, flAttackWidth, flAttackHeight, tEntsDamaged, flKnock);


		flAttackHeight = ATTACK_STEP;
		while(flAttackHeight < flMaxHeight / 2.0)
		{
			iHitResult = Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, flAttackWidth, flAttackHeight, tEntsDamaged, flKnock);
			iHitResult = Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, flAttackWidth, -flAttackHeight, tEntsDamaged, flKnock);
			flAttackHeight += ATTACK_STEP;
		}

		flAttackHeight = ATTACK_STEP;
		while(flAttackHeight < flMaxWidth / 2.0)
		{
			iHitResult = Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, -flAttackWidth, flAttackHeight, tEntsDamaged, flKnock);
			iHitResult = Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, -flAttackWidth, -flAttackHeight, tEntsDamaged, flKnock);
			flAttackHeight += ATTACK_STEP;
		}

		flAttackWidth += ATTACK_STEP;
	}

	free_tr2(tr);
	TrieDestroy(tEntsDamaged);

	return max(iHitAim, iHitResult);
}

//TraceAttack по углу flAttackWidth и flAttackHeight
stock Trace_FakeAttackByAngles(id, tr, Float:flDistance, Float:flDamage, Float:flAttackWidth, Float:flAttackHeight, Trie:tEntsDamaged, const Float:flKnock)
{
	new Float:vecOrigin[3]; get_entvar(id, var_origin, vecOrigin);
	new Float:vecViewOfs[3]; get_entvar(id, var_view_ofs, vecViewOfs);
	new Float:vecAngles[3]; get_entvar(id, var_v_angle, vecAngles);
	new Float:vecDir[3], Float:vecBack[3];
	new Float:vecStart[3], Float:vecEnd[3];

	vecAngles[0] += flAttackHeight;
	vecAngles[1] += flAttackWidth;

	//Получение вектора направления камеры
	angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecDir);

	xs_vec_add(vecViewOfs, vecOrigin, vecStart);
	
	//Получение конечного вектора
	xs_vec_mul_scalar(vecDir, flDistance, vecEnd);
	xs_vec_add(vecEnd, vecStart, vecEnd);

	//Получение начального вектора
	xs_vec_mul_scalar(vecDir, -10.0, vecBack)
	xs_vec_add(vecStart, vecBack, vecStart);

	//Trace Attack
	return Trace_AccrosPlayers(tEntsDamaged, flDamage, vecStart, vecEnd, DONT_IGNORE_MONSTERS, id, tr, flKnock)
}

stock Trace_AccrosPlayers(Trie:tEntsDamaged, Float:flDamage, Float:vecTraceStart[3], Float:vecTraceEnd[3], iMonsterIgnore, pPlayer, tr, const Float:flKnock)
{
	new iHitType = SLASH_HIT_NONE,
		Float:flCurrentDist,
		Float:flDist = get_distance_f(vecTraceStart, vecTraceEnd),
		Float:vecDir[3],
		pHit = pPlayer,
		Float:flFraction,
		Float:vecEndPos[3];

	xs_vec_sub(vecTraceEnd, vecTraceStart, vecDir);
	xs_vec_normalize(vecDir, vecDir);

	while(flCurrentDist < flDist)
	{
		engfunc(EngFunc_TraceLine, vecTraceStart, vecTraceEnd, iMonsterIgnore, pHit, tr);
		get_tr2(tr, TR_flFraction, flFraction);

		get_tr2(tr, TR_vecEndPos, vecEndPos);

		if(flFraction == 1.0) return max(SLASH_HIT_NONE, iHitType);

		flCurrentDist = flDist * flFraction;
		flDist -= flCurrentDist;

		xs_vec_add(vecEndPos, vecDir, vecTraceStart);
		pHit = get_tr2(tr, TR_pHit);

		//client_print(pPlayer, print_chat, "pHit: %d | is_null: %s | is_user_alive: %s", pHit, is_nullent(pHit) ? "true" : "flase", is_user_alive(pHit) ? "true" : "flase");

		if(is_nullent(pHit)) return max(SLASH_HIT_WORLD, iHitType);

		if(pHit == pPlayer) 
			continue;

		if(pev(pHit, pev_solid) == SOLID_BSP)
		{
			if(~pev(pHit, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY && Float:get_entvar(pHit, var_health) != 0.0) 
			{
				ExecuteHamB(Ham_TakeDamage, pHit, pPlayer, pPlayer, flDamage, DMG_NEVERGIB | DMG_CLUB);

				// client_print(0, print_chat, "pHit: %d | spawnflags: %d | health: %f", pHit, pev(pHit, pev_spawnflags), Float:get_entvar(pHit, var_health))

				iHitType = max(SLASH_HIT_WORLD, iHitType);
			}
			else	
				return max(SLASH_HIT_WORLD, iHitType);
		}
		
		if(FakeTraceAttack(tEntsDamaged, pHit, pPlayer, flDamage, vecDir, tr, DMG_CLUB, flKnock)) 
		{
			iHitType = max(SLASH_HIT_ENTITY, iHitType);
		}
	}
	return iHitType;
}


public FakeTraceAttack(Trie:tEntsDamaged, iVictim, iAttacker, Float:flDamage, Float:vecDirection[3], pTrace, bDamageBits, const Float:flKnock) 
{
	if(zp_is_round_end() || TrieKeyExists(tEntsDamaged, fmt("%d", iVictim)) || pev(iVictim, pev_takedamage) == DAMAGE_NO ||
		zp_get_user_zombie(iAttacker) || is_user_alive(iVictim) && !zp_get_user_zombie(iVictim) && !IsAliveNPC(iVictim)) 
		return 0;

	static iHitgroup; iHitgroup = get_tr2(pTrace, TR_iHitgroup);
	static Float:vecEndPos[3]; get_tr2(pTrace, TR_vecEndPos, vecEndPos);
	static iBloodColor; iBloodColor = ExecuteHamB(Ham_BloodColor, iVictim);
	
	if(IsPlayer(iVictim)) set_member(iVictim, m_LastHitGroup, iHitgroup)
	
	switch(iHitgroup) 
	{
		case HIT_HEAD:                  flDamage *= 1.5;
		case HIT_LEFTARM, HIT_RIGHTARM: flDamage *= 1.0;
		case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 1.0;
		case HIT_STOMACH:               flDamage *= 1.25;
	}
	
	ExecuteHamB(Ham_TakeDamage, iVictim, iAttacker, iAttacker, flDamage, bDamageBits);
	if(!IsNPC(iVictim)) FakeKnockBack(iVictim, vecDirection, flKnock);
	
	if(iBloodColor != DONT_BLEED) 
	{
		ExecuteHamB(Ham_TraceBleed, iVictim, flDamage, vecDirection, pTrace, bDamageBits);
		UTIL_BloodDrips(vecEndPos, iBloodColor, floatround(flDamage));
	}

	TrieSetCell(tEntsDamaged, fmt("%d", iVictim), 1);
	return 1;
}

public FakeKnockBack(iVictim, Float: vecDirection[3], Float: flKnockBack) 
{
	if(!(is_user_alive(iVictim) && zp_get_user_zombie(iVictim))) return 0;

	set_pdata_float(iVictim, m_flPainShock, 1.0, linux_diff_player);

	static Float:vecVelocity[3]; pev(iVictim, pev_velocity, vecVelocity);

	new iFlags = pev(iVictim, pev_flags);

	if(iFlags & FL_DUCKING) 
		flKnockBack *= 0.3;

	vecVelocity[0] = vecDirection[0] * flKnockBack;
	vecVelocity[1] = vecDirection[1] * flKnockBack;
	vecVelocity[2] = iFlags & FL_ONGROUND ? 200.0 : 0.0;

	set_pev(iVictim, pev_velocity, vecVelocity);
	
	return 1;
}

public UTIL_BloodDrips(Float:vecOrigin[3], iColor, iAmount)
{
	if(iAmount > 255) iAmount = 255;
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(g_iszModelIndexBloodSpray);
	write_short(g_iszModelIndexBloodDrop);
	write_byte(iColor);
	write_byte(min(max(3,iAmount/10),16));
	message_end();
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

stock UTIL_PlayerAnimation(const iPlayer, const szAnim[])
{
	new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
		
	if((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
	{
		iAnimDesired = 0;
	}
	
	new Float: flGameTime = get_gametime();

	set_pev(iPlayer, pev_frame, 0.0);
	set_pev(iPlayer, pev_framerate, 1.0);
	set_pev(iPlayer, pev_animtime, flGameTime);
	set_pev(iPlayer, pev_sequence, iAnimDesired);
	
	set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, linux_diff_animating);
	set_pdata_int(iPlayer, m_fSequenceFinished, 0, linux_diff_animating);
	
	set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, linux_diff_animating);
	set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, linux_diff_animating);
	set_pdata_float(iPlayer, m_flLastEventCheck, flGameTime , linux_diff_animating);
	
	set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_float(iPlayer, m_flLastAttackTime, flGameTime , linux_diff_player);
}

stock remove_saw(iPlayer)
{
	new iItem = get_member(iPlayer, m_rgpPlayerItems, PRIMARY_WEAPON_SLOT);

	if(is_nullent(iItem) || !CustomItem(iItem)) return 0;

	rg_remove_items_by_slot(iPlayer, PRIMARY_WEAPON_SLOT);
	rg_give_item(iPlayer, "weapon_knife")
	return 1;
}