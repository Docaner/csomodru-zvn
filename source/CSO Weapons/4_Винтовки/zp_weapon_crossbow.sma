#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <zp_system>
#include <zpe_knokcback>
#include <xs>

#define IsCustomItem(%0) 			(pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)

#define PDATA_SAFE 					2
#define DMG_GRENADE					(1<<24)

// native zp_set_item_max_clip(iPlayer, iValue);
// native zp_set_item_max_ammo(iPlayer, iValue);
// forward zp_weapon_buyammo(iPlayer, iActiveItem);

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 		31/16.0
#define WEAPON_ANIM_SHOOT_TIME 		31/30.0
#define WEAPON_ANIM_RELOAD_TIME 	111/30.0
#define WEAPON_ANIM_DRAW_TIME 		31/30.0

#define WEAPON_ANIM_IDLE 			0
#define WEAPON_ANIM_SHOOT 			random_num(1,2)
#define WEAPON_ANIM_RELOAD 			3
#define WEAPON_ANIM_DRAW 			4

/* ~ [ Extra Item ] ~ */
const WEAPON_ITEM_COST = 			0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = 		"weapon_aug";
new const WEAPON_WEAPONLIST[] = 	"zp_br_cso/weapons/weapon_crossbow";
new const WEAPON_NATIVE[] = 		"zp_give_user_crossbow";
new const WEAPON_MODEL_VIEW[] = 	"models/zp_br_cso/weapons/v_crossbow.mdl";

new const WEAPON_MODEL_WORLD[] = 	"models/zp_br_cso/other/w_weapons_b1.mdl";
new const WEAPON_SOUND_FIRE[] = 	"weapons/crossbow-1.wav";

const WEAPON_SPECIAL_CODE = 		1018;
const WEAPON_BODY = 				41;

const WEAPON_MAX_CLIP = 			50;
const WEAPON_DEFAULT_AMMO = 		90;
const Float: WEAPON_RATE = 			0.135;

new const iWeaponList[] = 			{ 4,  90, -1, -1, 0, 14,8,  0 };

/* ~ [ Entity: Arrow ] ~ */
new const ENTITY_ARROW_CLASSNAME[] = "ent_xarrow";
new const ENTITY_ARROW_MODEL[] = 	"models/zp_br_cso/weapons/s_arrow.mdl";
new const ENTITY_ARROW_TRAIL[] =	"sprites/laserbeam.spr";
const Float: ENTITY_ARROW_SPEED = 	3000.0;
#define ENTITY_ARROW_DAMAGE 		random_float(40.0, 55.0)
const ENTITY_ARROW_DMGTYPE = 		DMG_BURN|DMG_NEVERGIB;

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
	gl_iszAllocString_InfoTarget,
	gl_iszAllocString_Arrow,

	gl_iszModelIndex_Trail,
	gl_iszModelIndex_BloodSpray,
	gl_iszModelIndex_BloodDrop,

	gl_iMsgID_Weaponlist,
	gl_iItemID;

public plugin_init()
{
	register_plugin("[ZP] Weapon: Crossbow", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

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
	
	// Register on Extra-Items
	gl_iItemID = zp_register_extra_item("Crossbow", 31, ZP_TEAM_HUMAN);

	// Messages
	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");

	// Alloc String
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	gl_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");
	gl_iszAllocString_Arrow = engfunc(EngFunc_AllocString, ENTITY_ARROW_CLASSNAME);
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, ENTITY_ARROW_MODEL);

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	
	// Precache sounds
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_FIRE);

	// Model Index
	gl_iszModelIndex_Trail = engfunc(EngFunc_PrecacheModel, ENTITY_ARROW_TRAIL);
	gl_iszModelIndex_BloodSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
	gl_iszModelIndex_BloodDrop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");
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

public Command_GiveWeapon(iPlayer)
{
	static iEntity; iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Entity);
	if(iEntity <= 0) return 0;

	set_pev(iEntity, pev_impulse, WEAPON_SPECIAL_CODE);
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

// [ HamSandwich ]
public CWeapon__Holster_Post(iItem)
{
	if(pev_valid(iItem) != PDATA_SAFE) return;
	if(!IsCustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	
	set_pdata_int(iPlayer, m_iFOV, 90, linux_diff_player);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 0.0, linux_diff_player);
}

public CWeapon__Deploy_Post(iItem)
{
	if(!IsCustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
	
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

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
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;
	set_pdata_int(iPlayer, m_iFOV, 90, linux_diff_player);

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
	if(!IsCustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	new Float: vecPunchAngle[3];
	vecPunchAngle[0] = random_float(-0.15, -1.75);
	vecPunchAngle[1] = random_float(1.0, -1.0);
	vecPunchAngle[2] = 0.0;
	set_pev(iPlayer, pev_punchangle, vecPunchAngle);

	CWeapon__CreateArrow(iPlayer);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_int(iItem, m_iClip, iClip - 1, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pdata_int(iPlayer, m_iFOV, get_pdata_int(iPlayer, m_iFOV, linux_diff_player) == 90 ? 40 : 90, linux_diff_player);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.3, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public ArrowHitToWall(iEntity)
{
	new Float: flGameTime = get_gametime();

	set_pev(iEntity, pev_movetype, MOVETYPE_NONE);
	set_pev(iEntity, pev_solid, SOLID_NOT);
	set_pev(iEntity, pev_velocity, Float: {0.0, 0.0, 0.0});
	set_pev(iEntity, pev_nextthink, flGameTime + 1.0);
}

#define IsPlayer(%0) bool: (0 < %0 <= MaxClients)
public CEntity__Touch_Pre(iEntity, iTouch)
{
	if(pev_valid(iEntity) != PDATA_SAFE || pev(iTouch, pev_solid) == SOLID_TRIGGER) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Arrow)
	{
		new iOwner = pev(iEntity, pev_owner);
		if(iTouch == iOwner) return HAM_SUPERCEDE;
		if(pev(iTouch, pev_classname) == gl_iszAllocString_Arrow) return HAM_SUPERCEDE;

		/* По тимейтам не ебашит */
		if(is_user_connected(iTouch) && !zp_get_user_zombie(iTouch))
			return HAM_SUPERCEDE;

		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		new Float: vecVelocity[3]; pev(iEntity, pev_velocity, vecVelocity);

		if(iTouch)
		{
			if(pev(iTouch, pev_takedamage) == DAMAGE_NO)
			{
				ArrowHitToWall(iEntity);
				return HAM_IGNORED;
			}

			if(is_user_alive(iTouch) || pev(iTouch, pev_deadflag) == DEAD_NO)
			{
				if(IsPlayer(iTouch) && zp_get_user_zombie(iTouch) || pev(iTouch, pev_flags) & FL_MONSTER)
				{
					new iTrace = create_tr2();
					engfunc(EngFunc_TraceLine, vecOrigin, vecVelocity, DONT_IGNORE_MONSTERS, iOwner, iTrace);

					new Float: flDamage = ENTITY_ARROW_DAMAGE;
					new iHitgroup = get_tr2(iTrace, TR_iHitgroup);
					set_pdata_int(iTouch, m_LastHitGroup, iHitgroup, linux_diff_player);

					switch(iHitgroup)
					{
						case HIT_HEAD:					flDamage *= 3.0;
						case HIT_LEFTARM, HIT_RIGHTARM:	flDamage *= 0.75;
						case HIT_LEFTLEG, HIT_RIGHTLEG:	flDamage *= 0.75;
						case HIT_STOMACH:				flDamage *= 1.5;
					}
					
					if(!zp_is_round_end())
					{
						ExecuteHamB(Ham_TakeDamage, iTouch, iOwner, iOwner, flDamage, ENTITY_ARROW_DMGTYPE);
						zp_set_user_knock_by_missile(iTouch, iOwner, 260.0, 2.54)
						UTIL_BloodDrips(vecOrigin, iTouch, floatround(flDamage));
					}

					free_tr2(iTrace);
					set_pev(iEntity, pev_flags, FL_KILLME);
				}
			}
			else if(pev(iTouch, pev_solid) == SOLID_BSP)
			{
				ArrowHitToWall(iEntity);
			}
		}
		else ArrowHitToWall(iEntity);
	}

	return HAM_IGNORED;
}

public CEntity__Think_Pre(iEntity)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Arrow)
	{
		set_pev(iEntity, pev_flags, FL_KILLME);
	}

	return HAM_IGNORED;
}

// [ Other ]
public CWeapon__CreateArrow(iPlayer)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!iEntity) return FM_NULLENT;

	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
	new Float: vecVelocity[3]; xs_vec_copy(vecForward, vecVelocity);

	// Start point of arrow
	xs_vec_mul_scalar(vecForward, 20.0, vecForward);
	xs_vec_add(vecViewOfs, vecForward, vecViewOfs);
	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);

	// Speed for arrow
	xs_vec_mul_scalar(vecVelocity, ENTITY_ARROW_SPEED, vecVelocity);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Arrow);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_enemy, 0);
	set_pev(iEntity, pev_velocity, vecVelocity);

	engfunc(EngFunc_VecToAngles, vecVelocity, vecAngles);
	set_pev(iEntity, pev_angles, vecAngles);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_ARROW_MODEL);
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	// https://github.com/baso88/SC_AngelScript/wiki/TE_BEAMFOLLOW
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(gl_iszModelIndex_Trail); // Model Index
	write_byte(1); // Life
	write_byte(1); // Width
	write_byte(180); // Red
	write_byte(180); // Green
	write_byte(180); // Blue
	write_byte(220); // Alpha
	message_end();

	return iEntity;
}

// [ Stocks ]
public UTIL_BloodDrips(Float: vecOrigin[3], iVictim, iAmount)
{
	if(iAmount > 255) iAmount = 255;
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(gl_iszModelIndex_BloodSpray);
	write_short(gl_iszModelIndex_BloodDrop);
	write_byte(ExecuteHamB(Ham_BloodColor, iVictim));
	write_byte(min(max(3, iAmount / 10), 16));
	message_end();
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