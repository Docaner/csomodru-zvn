#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <reapi>

#define IsCustomItem(%0) 			(pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define IsBalrogMode(%0)			(get_pdata_int(%0, m_iWeaponState, linux_diff_weapon))

#define PDATA_SAFE 					2

// native zp_set_item_max_clip(iPlayer, iValue);
// native zp_set_item_max_ammo(iPlayer, iValue);
// forward zp_weapon_buyammo(iPlayer, iActiveItem);

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 		51/30.0
#define WEAPON_ANIM_SHOOT_TIME 		31/30.0
#define WEAPON_ANIM_SHOOT_B_TIME 	91/30.0
#define WEAPON_ANIM_RELOAD_TIME 	68/30.0
#define WEAPON_ANIM_RELOAD_B_TIME 	90/30.0
#define WEAPON_ANIM_DRAW_TIME 		31/30.0
#define WEAPON_ANIM_CHANGE_A_TIME 	61/30.0
#define WEAPON_ANIM_CHANGE_B_TIME 	39/30.0

enum _: eAnimList
{
	WEAPON_ANIM_IDLE_A = 0,
	WEAPON_ANIM_IDLE_B,
	WEAPON_ANIM_SHOOT_A,
	WEAPON_ANIM_SHOOT_B,
	WEAPON_ANIM_RELOAD,
	WEAPON_ANIM_DRAW,
	WEAPON_ANIM_CHANGE_A, // from a to b
	WEAPON_ANIM_CHANGE_B, // from b to a
	WEAPON_ANIM_RELOAD_B
};

/* ~ [ Extra Item ] ~ */
const WEAPON_ITEM_COST = 			0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = 		"weapon_usp";
new const WEAPON_WEAPONLIST[] = 	"zp_br_cso/weapons/weapon_balrog1";
new const WEAPON_NATIVE[] = 		"zp_give_user_balrog1";
new const WEAPON_MODEL_SHELL[] = 	"models/pshell.mdl";
new const WEAPON_MODEL_VIEW[] = 	"models/zp_br_cso/weapons/v_balrog1.mdl";

new const WEAPON_MODEL_WORLD[] = 	"models/zp_br_cso/other/w_weapons_b1.mdl";
new const WEAPON_SOUND_FIRE[][] =
{
	"weapons/balrog1-1.wav",
	"weapons/balrog1-2.wav"
};

const WEAPON_SPECIAL_CODE = 		1002;
const WEAPON_BODY = 				4;

const WEAPON_MAX_CLIP = 			12;
const WEAPON_DEFAULT_AMMO = 		100;
const Float: WEAPON_RATE = 			0.2;
#define WEAPON_RATE_EX				WEAPON_ANIM_SHOOT_B_TIME - 0.3
const Float: WEAPON_PUNCHANGLE = 	0.98;
const Float: WEAPON_DAMAGE = 		1.84;

new const iWeaponList[] =			{ 6,  100,-1, -1, 1, 4, 16, 0 };

/* ~ [ Balrog Explosion ] ~ */
new const BALROG_EXP_SPRITE[] = 	"sprites/zp_br_cso/weapons/balrog5stack.spr";
const Float: BALROG_EXP_RADIUS =	109.0;
#define BALROG_EXP_DAMAGE			random_float(750.0, 1050.0) 	

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
#define m_iShellId 57
#define m_iShotsFired 64
#define m_iWeaponState 74

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

	gl_iszModelIndex_Shell,
	gl_iszModelIndex_Explosion,

	HamHook: gl_HamHook_TraceAttack[4],

	gl_iMsgID_Weaponlist,
	gl_iItemID;

public plugin_init()
{
	register_plugin("[ZP] Weapon: Balrog-I", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	// Forwards
	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);
	
	// Events
	//register_event("HLTV", "EventHLTV", "a", "1=0", "2=0")

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
	//RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed", false);
	
	// Trace Attack
	gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,	"func_breakable",	"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",		"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",			"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",	"CEntity__TraceAttack_Pre", false);
	
	fm_ham_hook(false);

	// Register on Extra-Items
	gl_iItemID = zp_register_extra_item("Balrog-1", 0, ZP_TEAM_HUMAN);

	// Messages
	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");

	// Alloc String
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	
	// Precache sounds
	for(new i = 0; i < sizeof WEAPON_SOUND_FIRE; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_FIRE[i]);

	// Model Index
	gl_iszModelIndex_Shell = engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_SHELL);
	gl_iszModelIndex_Explosion = engfunc(EngFunc_PrecacheModel, BALROG_EXP_SPRITE);
}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

// [ Amxx ]
public zp_extra_item_selected(iPlayer, iItemID)
{
	if(iItemID == gl_iItemID)
		Command_GiveWeapon(iPlayer);
}

public Command_HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

/*
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
*/
public Command_GiveWeapon(iPlayer)
{
	static iEntity; iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
	if(iEntity <= 0) return 0;

	set_pev(iEntity, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, iEntity);
	set_pdata_int(iEntity, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
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
	if(pev_valid(iPlayer) != 2 || !is_user_alive(iPlayer)) return;

	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
	if(pev_valid(iEntity) != 2 ) return FMRES_IGNORED;

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
	if(pev_valid(iAttacker) != 2 ) return FMRES_IGNORED;
	if(iFlags & IGNORE_MONSTERS) return FMRES_IGNORED;

	static pHit; pHit = get_tr2(iTrace, TR_pHit);
	static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) == PDATA_SAFE && IsCustomItem(iItem))
	{
		if(IsBalrogMode(iItem))
		{
			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEndPos, 0);
			write_byte(TE_EXPLOSION);
			engfunc(EngFunc_WriteCoord, vecEndPos[0]);
			engfunc(EngFunc_WriteCoord, vecEndPos[1]);
			engfunc(EngFunc_WriteCoord, vecEndPos[2] + 40.0);
			write_short(gl_iszModelIndex_Explosion);
			write_byte(16); // Scale
			write_byte(16); // Framerate
			write_byte(0); // Flags
			message_end();

			new iVictim = FM_NULLENT;
			while((iVictim = fm_find_ent_in_sphere(iVictim, vecEndPos, BALROG_EXP_RADIUS)) != 0)
			{
				static Float: vecOriginV[3], Float: flDist, Float: flDamage;
				pev(iVictim, pev_origin, vecOriginV);
				flDist = get_distance_f(vecEndPos, vecOriginV);
				flDamage = BALROG_EXP_DAMAGE - (BALROG_EXP_DAMAGE/BALROG_EXP_RADIUS) * flDist;
				if(flDamage > 0.0)
				{
					if(is_user_connected(iVictim) && is_user_alive(iVictim) && (pev_valid(iVictim) == PDATA_SAFE) && zp_get_user_zombie(iVictim) && pev(iVictim, pev_takedamage) != DAMAGE_NO)
					{
						ExecuteHamB(Ham_TakeDamage, iVictim, iAttacker, iAttacker, flDamage, DMG_BULLET);
					}
				}
			}
		}
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

// [ HamSandwich ]
public CWeapon__Holster_Post(iItem)
{
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	
	// set_pdata_int(iItem, m_iWeaponState, 0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CWeapon__Deploy_Post(iItem)
{
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
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

		set_pdata_int(iItem, m_iClip, iClip + j, linux_diff_weapon);
		set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
		set_pdata_int(iItem, m_fInReload, 0, linux_diff_weapon);
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
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInReload, 1, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, IsBalrogMode(iItem) ? WEAPON_ANIM_RELOAD_B : WEAPON_ANIM_RELOAD);

	static Float: flNextTime; flNextTime = IsBalrogMode(iItem) ? WEAPON_ANIM_RELOAD_B_TIME : WEAPON_ANIM_RELOAD_TIME;

	set_pdata_int(iItem, m_iWeaponState, 0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, flNextTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, flNextTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, flNextTime, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, flNextTime, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, IsBalrogMode(iItem) ? WEAPON_ANIM_IDLE_B : WEAPON_ANIM_IDLE_A);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return HAM_IGNORED;
	if(get_pdata_int(iItem, m_iShotsFired, linux_diff_weapon) != 0) return HAM_SUPERCEDE;

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

	static Float: vecPunchangle[3];
	pev(iPlayer, pev_punchangle, vecPunchangle);
	vecPunchangle[0] *= WEAPON_PUNCHANGLE;
	vecPunchangle[1] *= WEAPON_PUNCHANGLE;
	vecPunchangle[2] *= WEAPON_PUNCHANGLE;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	UTIL_SendWeaponAnim(iPlayer, IsBalrogMode(iItem) ? WEAPON_ANIM_SHOOT_B : WEAPON_ANIM_SHOOT_A);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[IsBalrogMode(iItem) ? 1 : 0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_int(iItem, m_iShellId, gl_iszModelIndex_Shell, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flEjectBrass, get_gametime(), linux_diff_player);

	set_pdata_float(iItem, m_flNextPrimaryAttack, IsBalrogMode(iItem) ? WEAPON_RATE_EX : WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, IsBalrogMode(iItem) ? WEAPON_RATE_EX : WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, IsBalrogMode(iItem) ? WEAPON_ANIM_SHOOT_B_TIME : WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
	set_pdata_int(iItem, m_iWeaponState, 0, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return HAM_IGNORED;
	if(get_pdata_int(iItem, m_iClip, linux_diff_weapon) == 0) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static Float: flNextTime; flNextTime = IsBalrogMode(iItem) ? WEAPON_ANIM_CHANGE_B_TIME : WEAPON_ANIM_CHANGE_A_TIME;

	UTIL_SendWeaponAnim(iPlayer, IsBalrogMode(iItem) ? WEAPON_ANIM_CHANGE_B : WEAPON_ANIM_CHANGE_A);
	
	set_pdata_int(iItem, m_iWeaponState, IsBalrogMode(iItem) ? 0 : 1, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, flNextTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, flNextTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, flNextTime, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
	if(pev_valid(iAttacker) != PDATA_SAFE || !is_user_connected(iAttacker)) return;

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