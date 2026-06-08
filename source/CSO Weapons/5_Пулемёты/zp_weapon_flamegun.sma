#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>
#include <zp_system>
#include <zpe_knokcback>
#include <api_flame>

#define IsCustomItem(%0) 			(pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)

#define DONT_BLEED					-1
#define PDATA_SAFE 					2

#define MAX_CLIENTS			 32

// native zp_set_item_max_clip(iPlayer, iValue);
// native zp_set_item_max_ammo(iPlayer, iValue);
// forward zp_weapon_buyammo(iPlayer, iActiveItem);

/*#if !defined ZPE_SetUserBurn
native ZPE_SetUserBurn(id, iTime)
#endif*/


/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 		151/16.0
#define WEAPON_ANIM_SHOOT_TIME 		63/30.0
#define WEAPON_ANIM_RELOAD_TIME 	151/30.0
#define WEAPON_ANIM_DRAW_TIME 		37/30.0

#define WEAPON_ANIM_IDLE 			0
#define WEAPON_ANIM_SHOOT 			1
#define WEAPON_ANIM_SHOOT_END		2
#define WEAPON_ANIM_RELOAD 			3
#define WEAPON_ANIM_DRAW 			4

/* ~ [ Extra Item ] ~ */
const WEAPON_ITEM_COST = 			0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = 		"weapon_m249";
new const WEAPON_WEAPONLIST[] = 	"zp_br_cso/weapons/weapon_flamegun";
new const WEAPON_NATIVE[] = 		"zp_give_user_flamethrower";
new const WEAPON_MODEL_VIEW[] = 	"models/zp_br_cso/weapons/v_flamegun.mdl";


new const WEAPON_MODEL_WORLD[] = 	"models/zp_br_cso/other/w_weapons_b1.mdl";
new const WEAPON_SOUND_FIRE[][] = 
{
	"weapons/flamegun-1.wav",
	"weapons/flamegun-2.wav"
};

const WEAPON_SPECIAL_CODE = 		1023;
const WEAPON_BODY = 				40;

const WEAPON_MAX_CLIP = 			75;
const WEAPON_DEFAULT_AMMO = 		200;
const Float: WEAPON_RATE = 			0.11;

#define WEAPON_RECOIL -0.65, 0.0, 0.0

new const iWeaponList[] = 			{ 3, 200,-1, -1, 0, 4, 20, 0 };

/* ~ [ Entity: Flame ] ~ */
new const ENTITY_FLAME_CLASSNAME[] = "ent_flamegun";
new const ENTITY_FLAME_SPRITE[] = 	"sprites/eexplo.spr";
const Float: ENTITY_FLAME_SPEED = 	450.0;
const Float: ENTITY_FLAME_KNOCKBACK = 60.0;
const Float: ENTITY_FLAME_RADIUS = 	27.0;
#define ENTITY_FLAME_DAMAGE 		random_float(40.0, 55.0)
const ENTITY_FLAME_DMGTYPE =		DMG_BURN|DMG_NEVERGIB;

// FLAME DURATION
#define FLAME_COUNTDOWN 6.0

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
#define m_flNextReload 75

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_flPainShock 108
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

/* ~ [ Params ] ~ */
new gl_iszAllocString_Entity,
	gl_iszAllocString_ModelView,
	gl_iszAllocString_InfoTarget,
	gl_iszAllocString_Flame,

	gl_iszModelIndex_BloodSpray,
	gl_iszModelIndex_BloodDrop,

	gl_iMsgID_Weaponlist,
	gl_iItemID;

public plugin_init()
{
	register_plugin("[ZP] Weapon: Salamander", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	gl_iItemID = zp_register_extra_item("Flamegun", 31, ZP_TEAM_HUMAN);

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

	// Entity
	RegisterHam(Ham_Think,					"info_target",		"CEntity__Think_Pre", false);
	RegisterHam(Ham_Touch,					"info_target",		"CEntity__Touch_Pre", false);

	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	
	
	engfunc(EngFunc_PrecacheModel, ENTITY_FLAME_SPRITE);

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	
	// Precache sounds
	for(new i = 0; i < sizeof WEAPON_SOUND_FIRE; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_FIRE[i]);

	engfunc(EngFunc_PrecacheSound, "common/null.wav");

	// Other
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);

	gl_iszAllocString_InfoTarget = engfunc(EngFunc_AllocString, "info_target");
	gl_iszAllocString_Flame = engfunc(EngFunc_AllocString, ENTITY_FLAME_CLASSNAME);

	// Model Index
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

		if(iItem > 0 && IsCustomItem(iItem))
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
	if(!IsCustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	emit_sound(iPlayer, CHAN_WEAPON, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
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

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iButton; iButton = pev(iPlayer, pev_button);

	if(!(iButton & IN_ATTACK) && pev(iPlayer, pev_weaponanim) == WEAPON_ANIM_SHOOT)
	{
		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT_END);

		set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);
	}

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

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!IsCustomItem(iItem)) return HAM_IGNORED;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip <= 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	if(pev(iPlayer, pev_weaponanim) != WEAPON_ANIM_SHOOT)
		UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);

	new Float: flGameTime = get_gametime();
	new Float: flNextSound = get_pdata_float(iItem, m_flNextReload, linux_diff_weapon);
	if(flNextSound <= flGameTime)
	{
		emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		set_pdata_float(iItem, m_flNextReload, flGameTime + 0.8, linux_diff_weapon);
	}
	
	set_pev(iPlayer, pev_punchangle, Float: { WEAPON_RECOIL });

	CWeapon__CreateFlame(iPlayer);
	set_pdata_int(iItem, m_iClip, iClip - 1, linux_diff_weapon);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CEntity__Think_Pre(iEntity)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Flame)
	{
		new Float: flAmt; pev(iEntity, pev_renderamt, flAmt);
		if(pev(iEntity, pev_effects) & EF_NODRAW || flAmt <= 30.0)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		new Float: flNextThink;
		new Float: flGameTime = get_gametime();
		new Float: flFrame; pev(iEntity, pev_frame, flFrame); 

		flAmt -= 3.0;
		flFrame += 0.25;
		flNextThink = pev(iEntity, pev_movetype) == MOVETYPE_NONE ? 0.008 : 0.015;

		set_pev(iEntity, pev_frame, flFrame);
		set_pev(iEntity, pev_renderamt, flAmt);
		set_pev(iEntity, pev_nextthink, flGameTime + flNextThink);
	}

	return HAM_IGNORED;
}

public CEntity__Touch_Pre(iEntity, iTouch)
{
	if(pev_valid(iEntity) != PDATA_SAFE || pev(iTouch, pev_solid) == SOLID_TRIGGER) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Flame)
	{
		if(pev(iTouch, pev_classname) == gl_iszAllocString_Flame) return HAM_SUPERCEDE;
		
		new iOwner = pev(iEntity, pev_owner);
		if(iTouch == iOwner) return HAM_SUPERCEDE;

		/* По тимейтам не ебашит */
		if(is_user_connected(iTouch) && !zp_get_user_zombie(iTouch))
			return HAM_SUPERCEDE;

		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		set_pev(iEntity, pev_solid, SOLID_NOT);
		set_pev(iEntity, pev_movetype, MOVETYPE_NONE);
		set_pev(iEntity, pev_velocity, Float: {0.0, 0.0, 0.0});

		new iBloodColor;
		new iVictim = FM_NULLENT;

		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_FLAME_RADIUS)) > 0)
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

			ExecuteHamB(Ham_TakeDamage, iVictim, iOwner, iOwner, ENTITY_FLAME_DAMAGE, ENTITY_FLAME_DMGTYPE);

			if(is_user_alive(iVictim) && zp_get_user_zombie(iVictim))
			{
				if(!zp_is_round_end())
				{
					iBloodColor = ExecuteHamB(Ham_BloodColor, iVictim);
					if(iBloodColor != DONT_BLEED)
					{
						new Float: vecEnd[3]; pev(iVictim, pev_origin, vecEnd);
						UTIL_BloodDrips(vecEnd, iBloodColor, floatround(ENTITY_FLAME_DAMAGE * 1.5));
					}
				
					zp_set_user_flame(iVictim, iOwner, 1.6)
					// zp_set_user_knock_by_missile(iVictim, iOwner, 160.0, 0.65);

					// set_pdata_float(iVictim, m_flPainShock, 1.0, linux_diff_player);

					 
					//velocity_by_aim(iOwner, floatround(ENTITY_FLAME_KNOCKBACK), vecVelocity);
					//set_pev(iVictim, pev_velocity, vecVelocity);
				}
			}
		}
	}

	return HAM_IGNORED;
}

// [ Other ]
CWeapon__CreateFlame(iPlayer)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_InfoTarget);
	if(!iEntity) return FM_NULLENT;

	new Float: flGameTime = get_gametime();
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
	xs_vec_mul_scalar(vecVelocity, ENTITY_FLAME_SPEED, vecVelocity);

	engfunc(EngFunc_SetModel, iEntity, ENTITY_FLAME_SPRITE);
	engfunc(EngFunc_SetSize, iEntity, Float: {-1.0, -1.0, -1.0}, Float: {1.0, 1.0, 1.0});
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Flame);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_velocity, vecVelocity);
	set_pev(iEntity, pev_scale, random_float(0.5, 1.0));
	set_pev(iEntity, pev_nextthink, flGameTime);

	set_pev(iEntity, pev_rendermode, kRenderTransAdd);
	set_pev(iEntity, pev_renderamt, 250.0);
	set_pev(iEntity, pev_renderfx, kRenderFxNone);

	return iEntity;
}

// [ Stocks ]
stock is_wall_between_points(iPlayer, iEntity)
{
	if(!is_user_alive(iEntity))
		return 0;

	new iTrace = create_tr2();
	new Float: flStart[3], Float: vecEnd[3], Float: vecEndPos[3];

	pev(iPlayer, pev_origin, flStart);
	pev(iEntity, pev_origin, vecEnd);

	engfunc(EngFunc_TraceLine, flStart, vecEnd, IGNORE_MONSTERS, iPlayer, iTrace);
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

public UTIL_BloodDrips(Float:vecOrigin[3], iColor, iAmount)
{
	if(iAmount > 255) iAmount = 255;
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(gl_iszModelIndex_BloodSpray);
	write_short(gl_iszModelIndex_BloodDrop);
	write_byte(iColor);
	write_byte(min(max(3, iAmount / 10), 16));
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