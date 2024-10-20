#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <reapi>
#include <xs>

#define IsCustomItem(%0) 				(pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define get_weaponState(%0)				(get_pdata_int(%0, m_iWeaponState, linux_diff_weapon))
#define set_weaponState(%0,%1)			(set_pdata_int(%0, m_iWeaponState, %1, linux_diff_weapon))
#define get_rocketClip(%0)				(get_pdata_int(%0, m_iClipRocket, linux_diff_weapon))

#define m_iShootState					m_iGlock18ShotsFired
#define m_iClipRocket					m_iFamasShotsFired

#define PDATA_SAFE 						2
#define DMG_GRENADE						(1<<24)

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 			51/30.0
#define WEAPON_ANIM_SHOOT_TIME 			31/30.0
#define WEAPON_ANIM_CHANGE12_TIME		41/30.0
#define WEAPON_ANIM_RELOAD_TIME 		91/30.0
#define WEAPON_ANIM_DRAW_TIME 			31/30.0
#define WEAPON_ANIM_SHOOT_B_TIME 		29/30.0
#define WEAPON_ANIM_RELOAD_B_TIME 		61/30.0
#define WEAPON_ANIM_CHANGE_TIME 		71/30.0

#define WEAPON_ANIM_IDLE 				0
#define WEAPON_ANIM_CHANGE 				0 // Change
enum // A
{
	// A
	WEAPON_ANIM_SHOOT = 1,
	WEAPON_ANIM_CHANGE1 = 4, // to b
	WEAPON_ANIM_CHANGE2, // from b
	WEAPON_ANIM_RELOAD,
	WEAPON_ANIM_DRAW
};

enum // B
{
	// B
	WEAPON_ANIM_IDLE2 = 1, // empty
	WEAPON_ANIM_SHOOT_START,
	WEAPON_ANIM_SHOOT_END,
	WEAPON_ANIM_CHANGE1_1, // to a
	WEAPON_ANIM_CHANGE1_2, // to a empty
	WEAPON_ANIM_CHANGE2_1, // to b
	WEAPON_ANIM_CHANGE2_2, // to b empty
	WEAPON_ANIM_RELOAD_B,
	WEAPON_ANIM_DRAW_B,
	WEAPON_ANIM_DRAW_B2 // empty
};

enum // State
{
	STATE_MODE_A = 0,
	STATE_CHANGE_TO_B_S,
	STATE_CHANGE_TO_B_E,

	STATE_MODE_B,
	STATE_CHANGE_TO_A_S,
	STATE_CHANGE_TO_A_E
};

/* ~ [ Extra Item ] ~ */
new const WEAPON_ITEM_NAME[] = 			"Brick Piece V2";
const WEAPON_ITEM_COST = 				0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = 			"weapon_galil";
new const WEAPON_WEAPONLIST[] = 		"x/weapon_blockar";
new const WEAPON_NATIVE[] = 			"zp_give_user_blockar";
new const WEAPON_MODEL_SHELL[] = 		"models/x/block_shell.mdl";
new const WEAPON_MODEL_VIEW[][] = 
{ 
	"models/x/v_blockar1.mdl",
	"models/x/v_blockar2.mdl",
	"models/x/v_blockchange.mdl"
};
new const WEAPON_MODEL_PLAYER[][] = 
{
	"models/x/p_blockar1.mdl",
	"models/x/p_blockar2.mdl",
	"" // don't delet this!
};
new const WEAPON_MODEL_WORLD[] = 		"models/x/w_blockar.mdl";
new const WEAPON_SOUND[][] = 
{
	"weapons/blockar1-1.wav",
	"weapons/blockar2-1.wav"
};
new const THIRD_PERSON_ANIMS[][] =		{ "rifle", "m249", "c4" }; // a, b, change

const WEAPON_SPECIAL_CODE = 			2244;
const WEAPON_BODY = 					0;
const WEAPON_BODY_B = 					1;

const WEAPON_MAX_CLIP = 				35;
const WEAPON_DEFAULT_AMMO = 			180;
const Float: WEAPON_RATE = 				0.102;
const Float: WEAPON_PUNCHANGLE = 		0.9;
const Float: WEAPON_DAMAGE = 			1.5;

new const iWeaponList[] = 				{ 4,  90, -1, -1, 0, 17,14, 0 };

/* ~ [ Rocket Mode ] ~ */
const WEAPON_MAX_ROCKET = 				5; // Rocket clip max
new const ENTITY_ROCKET_CLASSNAME[] = 	"ent_rocket";
new const ENTITY_ROCKET_MODEL[] = 		"models/x/w_blockar.mdl";
new const ENTITY_ROCKET_SPRITE[] =		"sprites/fexplo.spr";
new const ENTITY_ROCKET_GIBS[] = 		"models/x/block_shell_b.mdl"
const Float: ENTITY_ROCKET_SPEED = 		1500.0;
const Float: ENTITY_ROCKET_RADIUS = 	150.0;
#define ENTITY_ROCKET_DAMAGE			random_float(800.0, 1000.0)
const ENTITY_ROCKET_DMGTYPE = 			DMG_GRENADE;

/* ~ [ Offsets ] ~ */
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
#define m_fInReload 54
#define m_iShellId 57
#define m_iGlock18ShotsFired 70
#define m_iWeaponState 74
#define m_iFamasShotsFired 72

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_flEjectBrass 111
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376
#define m_szAnimExtention 492

/* ~ [ Params ] ~ */
new gl_iszAllocString_Entity,
	gl_iszAllocString_Rocket,
	gl_iszAllocString_InfoTarget,

	gl_iszModelIndex_Gibs,
	gl_iszModelIndex_Shell,
	gl_iszModelIndex_Explode,
	gl_iszModelIndex_BeamFollow,

	HamHook: gl_HamHook_TraceAttack[4],

	gl_iMsgID_Weaponlist,
	gl_iMsgID_StatusIcon,
	gl_iItemID;

public plugin_init()
{
	register_plugin("[ZP] Weapon: Brick Piece V2", "2.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	gl_iItemID = zp_register_extra_item(WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN);

	RegisterHookChain(RG_CSGameRules_RestartRound, "@RG_RestartRound_Post", true);

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

	RegisterHam(Ham_Touch,					"info_target",		"CEntity__Touch_Post", true);
	
	gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,	"func_breakable",	"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",		"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",			"CEntity__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",	"CEntity__TraceAttack_Pre", false);
	
	fm_ham_hook(false);

	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	gl_iMsgID_StatusIcon = get_user_msgid("StatusIcon");
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	for(new i = 0; i < sizeof WEAPON_MODEL_VIEW; i++)
	{
		engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW[i]);
		UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW[i]);
	}

	for(new i = 0; i < sizeof WEAPON_MODEL_PLAYER; i++)
		engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER[i]);

	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	
	// Precache sounds
	for(new i = 0; i < sizeof WEAPON_SOUND; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUND[i]);

	// Other
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_Rocket = engfunc(EngFunc_AllocString, ENTITY_ROCKET_CLASSNAME);
	gl_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");

	// Model Index
	gl_iszModelIndex_Gibs = engfunc(EngFunc_PrecacheModel, ENTITY_ROCKET_GIBS);
	gl_iszModelIndex_Shell = engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_SHELL);
	gl_iszModelIndex_Explode = engfunc(EngFunc_PrecacheModel, ENTITY_ROCKET_SPRITE);
	gl_iszModelIndex_BeamFollow = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr");
}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

@RG_RestartRound_Post()
{
	new iPrimaryEntity = NULLENT;

	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(!is_user_alive(iPlayer)) continue;

		iPrimaryEntity = get_member(iPlayer, m_rgpPlayerItems, PRIMARY_WEAPON_SLOT);

		if(is_nullent(iPrimaryEntity) || !IsCustomItem(iPrimaryEntity)) continue;

		set_pdata_int(iPrimaryEntity, m_iClipRocket, WEAPON_MAX_ROCKET, linux_diff_weapon);
	}
}

// [ Amxx ]
public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem == gl_iItemID)
		Command_GiveWeapon(iPlayer);
}

public zp_user_infected_post(iPlayer)
{
	new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);

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
	ExecuteHam(Ham_Spawn, iEntity);
	set_pdata_int(iEntity, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	set_pdata_int(iEntity, m_iClipRocket, WEAPON_MAX_ROCKET, linux_diff_weapon);
	set_weaponState(iEntity, STATE_MODE_A);
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

		if(iItem > 0 && IsCustomItem(iItem))
		{
			engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
			switch(get_weaponState(iItem))
			{
				case STATE_MODE_A, STATE_CHANGE_TO_A_E, STATE_CHANGE_TO_A_S: set_pev(iEntity, pev_body, WEAPON_BODY);
				case STATE_MODE_B, STATE_CHANGE_TO_B_E, STATE_CHANGE_TO_B_S: set_pev(iEntity, pev_body, WEAPON_BODY_B);
			}
			
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
	if(!IsCustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	switch(get_weaponState(iItem))
	{
		case STATE_MODE_A, STATE_CHANGE_TO_B_S, STATE_CHANGE_TO_A_E: set_weaponState(iItem, STATE_MODE_A);
		case STATE_MODE_B, STATE_CHANGE_TO_A_S, STATE_CHANGE_TO_B_E: set_weaponState(iItem, STATE_MODE_B);
	}
	
	UTIL_StatusIcon(iItem, iPlayer, 0);
	set_pdata_int(iItem, m_iShootState, 0, linux_diff_weapon);

	// set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	// set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CWeapon__Deploy_Post(iItem)
{
	if(!IsCustomItem(iItem)) return;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	switch(get_weaponState(iItem))
	{
		case STATE_MODE_A, STATE_CHANGE_TO_A_S, STATE_CHANGE_TO_B_E:
		{
			set_weaponState(iItem, STATE_MODE_A);
			set_pdata_string(iPlayer, m_szAnimExtention * 4, THIRD_PERSON_ANIMS[0], -1, linux_diff_player * linux_diff_animating);
		}
		case STATE_MODE_B, STATE_CHANGE_TO_B_S, STATE_CHANGE_TO_A_E:
		{
			set_weaponState(iItem, STATE_MODE_B);
			set_pdata_string(iPlayer, m_szAnimExtention * 4, THIRD_PERSON_ANIMS[1], -1, linux_diff_player * linux_diff_animating);
		}
	}

	UTIL_StatusIcon(iItem, iPlayer, 0);
	UTIL_StatusIcon(iItem, iPlayer, 1);

	set_pev(iPlayer, pev_viewmodel2, WEAPON_MODEL_VIEW[get_weaponState(iItem) == STATE_MODE_B ? 1 : 0]);
	set_pev(iPlayer, pev_weaponmodel2, WEAPON_MODEL_PLAYER[get_weaponState(iItem) == STATE_MODE_B ? 1 : 0]);

	UTIL_SendWeaponAnim(iPlayer, get_weaponState(iItem) == STATE_MODE_B ? (get_rocketClip(iItem) ? WEAPON_ANIM_DRAW_B : WEAPON_ANIM_DRAW_B2) : WEAPON_ANIM_DRAW);

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

	if(get_weaponState(iItem) == STATE_MODE_B)
	{
		switch(get_pdata_int(iItem, m_iShootState, linux_diff_weapon))
		{
			case 1:
			{
				UTIL_StatusIcon(iItem, iPlayer, 0);
				set_pdata_int(iItem, m_iClipRocket, get_rocketClip(iItem) - 1, linux_diff_weapon);
				UTIL_StatusIcon(iItem, iPlayer, 1);

				set_pdata_int(iItem, m_iShootState, get_rocketClip(iItem) ? 2 : 0, linux_diff_weapon);

				Create_RocketMissile(iPlayer);

				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT_END);
				emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

				set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
			}
			case 2: // Reload if have rockets
			{
				set_pdata_int(iItem, m_iShootState, 0, linux_diff_weapon);

				UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_RELOAD_B);

				set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_B_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_B_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_B_TIME, linux_diff_weapon);
				set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_B_TIME, linux_diff_weapon);
			}
		}
	}

	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	switch(get_weaponState(iItem))
	{
		case STATE_CHANGE_TO_B_S:
		{
			CWeapon__ChangeMode(iPlayer, iItem, STATE_CHANGE_TO_B_E, WEAPON_ANIM_CHANGE, WEAPON_ANIM_CHANGE_TIME);
			
			UTIL_CreateBreakModel(vecOrigin, gl_iszModelIndex_Shell, random_num(5, 8));

			set_pev(iPlayer, pev_viewmodel2, WEAPON_MODEL_VIEW[2]);
			set_pev(iPlayer, pev_weaponmodel2, WEAPON_MODEL_PLAYER[2]);
			set_pdata_string(iPlayer, m_szAnimExtention * 4, THIRD_PERSON_ANIMS[2], -1, linux_diff_player * linux_diff_animating);
		}
		case STATE_CHANGE_TO_B_E: // go to B
		{
			CWeapon__ChangeMode(iPlayer, iItem, STATE_MODE_B, get_rocketClip(iItem) ? WEAPON_ANIM_CHANGE2_1 : WEAPON_ANIM_CHANGE2_2, WEAPON_ANIM_CHANGE12_TIME);

			set_pev(iPlayer, pev_viewmodel2, WEAPON_MODEL_VIEW[1]);
			set_pev(iPlayer, pev_weaponmodel2, WEAPON_MODEL_PLAYER[1]);
			set_pdata_string(iPlayer, m_szAnimExtention * 4, THIRD_PERSON_ANIMS[1], -1, linux_diff_player * linux_diff_animating);
		}
		case STATE_CHANGE_TO_A_S:
		{
			CWeapon__ChangeMode(iPlayer, iItem, STATE_CHANGE_TO_A_E, WEAPON_ANIM_CHANGE, WEAPON_ANIM_CHANGE_TIME);
			
			UTIL_CreateBreakModel(vecOrigin, gl_iszModelIndex_Shell, random_num(5, 8));

			set_pev(iPlayer, pev_viewmodel2, WEAPON_MODEL_VIEW[2]);
			set_pev(iPlayer, pev_weaponmodel2, WEAPON_MODEL_PLAYER[2]);
			set_pdata_string(iPlayer, m_szAnimExtention * 4, THIRD_PERSON_ANIMS[2], -1, linux_diff_player * linux_diff_animating);
		}
		case STATE_CHANGE_TO_A_E: // go to A
		{
			CWeapon__ChangeMode(iPlayer, iItem, STATE_MODE_A, WEAPON_ANIM_CHANGE2, WEAPON_ANIM_CHANGE12_TIME);

			set_pev(iPlayer, pev_viewmodel2, WEAPON_MODEL_VIEW[0]);
			set_pev(iPlayer, pev_weaponmodel2, WEAPON_MODEL_PLAYER[0]);
			set_pdata_string(iPlayer, m_szAnimExtention * 4, THIRD_PERSON_ANIMS[0], -1, linux_diff_player * linux_diff_animating);
		}
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
	if(IsCustomItem(iItem)) UTIL_WeaponList(iPlayer, true);
	else if(pev(iItem, pev_impulse) == 0) UTIL_WeaponList(iPlayer, false);
}

public CWeapon__Reload_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;
	if(get_weaponState(iItem) != STATE_MODE_A) return HAM_SUPERCEDE;

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
	if(!IsCustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, get_weaponState(iItem) == STATE_MODE_B ? (get_rocketClip(iItem) ? WEAPON_ANIM_IDLE : WEAPON_ANIM_IDLE2) : WEAPON_ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;
	switch(get_weaponState(iItem))
	{
		case STATE_CHANGE_TO_A_E, STATE_CHANGE_TO_B_S, STATE_CHANGE_TO_B_E, STATE_CHANGE_TO_A_S: return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(get_weaponState(iItem) == STATE_MODE_A)
	{
		static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
		if(iClip <= 0)
		{
			ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
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

		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);
		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		set_pdata_int(iItem, m_iShellId, gl_iszModelIndex_Shell, linux_diff_weapon);
		set_pdata_float(iPlayer, m_flEjectBrass, get_gametime(), linux_diff_player);

		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_RATE, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
	}
	else if(get_weaponState(iItem) == STATE_MODE_B)
	{
		if(get_pdata_int(iItem, m_iShootState, linux_diff_weapon) >= 1) return HAM_SUPERCEDE;
		if(get_rocketClip(iItem) <= 0)
		{
			ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
			set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

			return HAM_SUPERCEDE;
		}

		set_pdata_int(iItem, m_iShootState, 1, linux_diff_weapon);
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT_START);

		set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	switch(get_weaponState(iItem))
	{
		case STATE_MODE_A:
		{
			set_weaponState(iItem, STATE_CHANGE_TO_B_S);
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_CHANGE1);
		}
		case STATE_MODE_B:
		{
			set_weaponState(iItem, STATE_CHANGE_TO_A_S);
			UTIL_SendWeaponAnim(iPlayer, get_rocketClip(iItem) ? WEAPON_ANIM_CHANGE1_1 : WEAPON_ANIM_CHANGE1_2);
		}
		default: return HAM_SUPERCEDE;
	}

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_CHANGE12_TIME - 0.1, linux_diff_player);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_CHANGE12_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_CHANGE12_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_CHANGE12_TIME, linux_diff_weapon);

	return HAM_IGNORED;
}

public CEntity__Touch_Post(iEntity, iTouch)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Rocket)
	{
		new iOwner = pev(iEntity, pev_owner);
		if(iTouch == iOwner) return HAM_SUPERCEDE;

		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		set_pev(iEntity, pev_solid, SOLID_NOT);
		set_pev(iEntity, pev_velocity, Float: {0.0, 0.0, 0.0});
		engfunc(EngFunc_SetModel, iEntity, "");

		UTIL_CreateBreakModel(vecOrigin, gl_iszModelIndex_Gibs, random_num(5, 8));
		UTIL_CreateExplosion(vecOrigin, 20.0, gl_iszModelIndex_Explode, 16, 32, TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOPARTICLES);

		new iVictim = FM_NULLENT;
		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_ROCKET_RADIUS)) > 0)
		{
			if(pev(iVictim, pev_takedamage) == DAMAGE_NO) 
				continue;

			if(is_user_alive(iVictim))
			{
				if(iVictim == iOwner || !zp_get_user_zombie(iVictim) || !is_wall_between_points(iOwner, iVictim))
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

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float: flDamage)
{
	if(!is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(iItem <= 0 || !IsCustomItem(iItem)) return;

	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

public CWeapon__ChangeMode(iPlayer, iItem, iState, iAnim, Float: flTime)
{
	set_weaponState(iItem, iState); // change mode

	UTIL_SendWeaponAnim(iPlayer, iAnim); // play anim

	// set delay
	set_pdata_float(iPlayer, m_flNextAttack, flTime, linux_diff_player);
	set_pdata_float(iItem, m_flNextPrimaryAttack, flTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, flTime, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, flTime, linux_diff_weapon);
}

// [ Other ]
public Create_RocketMissile(iPlayer)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!iEntity) return 0;

	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
	new Float: vecVelocity[3]; xs_vec_copy(vecForward, vecVelocity);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);

	vecOrigin[0] += vecViewOfs[0] + vecForward[0] * 20.0;
	vecOrigin[1] += vecViewOfs[1] + vecForward[1] * 20.0;
	vecOrigin[2] += vecViewOfs[2] + vecForward[2] * 20.0;

	vecVelocity[0] *= ENTITY_ROCKET_SPEED;
	vecVelocity[1] *= ENTITY_ROCKET_SPEED;
	vecVelocity[2] *= ENTITY_ROCKET_SPEED;

	engfunc(EngFunc_SetModel, iEntity, ENTITY_ROCKET_MODEL);
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Rocket);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_velocity, vecVelocity);
	set_pev(iEntity, pev_body, 2);

	engfunc(EngFunc_VecToAngles, vecVelocity, vecAngles);
	set_pev(iEntity, pev_angles, vecAngles);

	// https://github.com/baso88/SC_AngelScript/wiki/TE_BEAMFOLLOW
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(gl_iszModelIndex_BeamFollow); // Model Index
	write_byte(5); // Width
	write_byte(2); // Life
	write_byte(210); // Red
	write_byte(210); // Green
	write_byte(210); // Blue
	write_byte(150); // Alpha
	message_end();

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

// [ Stocks ]
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
	new szSprite[33], iColor[3];
	new iClip = get_pdata_int(iItem, m_iClipRocket, linux_diff_weapon);
	
	if(iClip >= 10)
	{
		iColor = { 255, 30, 30 };
		format(szSprite, charsmax(szSprite), "escape");
	}
	else
	{
		iColor = { 30, 144, 255 };
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

stock UTIL_CreateBreakModel(Float: vecOrigin[3], iszModelIndex, iCount)
{
	for(new i = 0; i <= iCount; i++)
	{
		// https://github.com/baso88/SC_AngelScript/wiki/TE_BREAKMODEL
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BREAKMODEL);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2] + 2.0);
		engfunc(EngFunc_WriteCoord, 16);
		engfunc(EngFunc_WriteCoord, 16);
		engfunc(EngFunc_WriteCoord, 16);
		engfunc(EngFunc_WriteCoord, random_num(-25, 25));
		engfunc(EngFunc_WriteCoord, random_num(-25, 25));
		engfunc(EngFunc_WriteCoord, 32);
		write_byte(16);
		write_short(iszModelIndex);
		write_byte(random_num(6, 10));
		write_byte(6);
		write_byte(0);
		message_end();
	}
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