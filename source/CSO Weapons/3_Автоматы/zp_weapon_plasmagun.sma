#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <xs>
#include <zpe_knokcback>
#include <zp_system>

#define IsCustomItem(%0) 			(pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)

#define PDATA_SAFE 					2

// native zp_set_item_max_clip(iPlayer, iValue);
// native zp_set_item_max_ammo(iPlayer, iValue);
// forward zp_weapon_buyammo(iPlayer, iActiveItem);

/* ~ [ Weapon Animations ] ~ */
#define WEAPON_ANIM_IDLE_TIME 		201/30.0
#define WEAPON_ANIM_SHOOT_TIME 		31/30.0
#define WEAPON_ANIM_RELOAD_TIME 	101/30.0
#define WEAPON_ANIM_DRAW_TIME 		31/30.0

#define WEAPON_ANIM_IDLE 			0
#define WEAPON_ANIM_SHOOT 			random_num(3,5)
#define WEAPON_ANIM_RELOAD 			1
#define WEAPON_ANIM_DRAW 			2

/* ~ [ Extra Item ] ~ */
const WEAPON_ITEM_COST = 			0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = 		"weapon_aug";
new const WEAPON_WEAPONLIST[] = 	"zp_br_cso/weapons/weapon_plasmagun";
new const WEAPON_NATIVE[] = 		"zp_give_user_plasmagun";
new const WEAPON_MODEL_VIEW[] = 	"models/zp_br_cso/weapons/v_plasmagun_b2.mdl";

new const WEAPON_MODEL_WORLD[] = 	"models/zp_br_cso/other/w_weapons_b1.mdl";
new const WEAPON_SOUND_FIRE[] = 	"weapons/plasmagun-1.wav";

const WEAPON_SPECIAL_CODE = 		1012;
const WEAPON_BODY = 				42;

const WEAPON_MAX_CLIP = 			40;
const WEAPON_DEFAULT_AMMO = 		90;
// const Float: WEAPON_RATE = 			0.14;
const Float: WEAPON_RATE = 			0.18;

new const iWeaponList[] = { 4,  90, -1, -1, 0, 14, 8,  0 };

/* ~ [ Plasma Mode ] ~ */
new const ENTITY_PLASMABALL_CLASSNAME[] = "ent_plasmaball";
new const ENTITY_PLASMABALL_SPRITE[] = "sprites/zp_br_cso/weapons/plasmaball.spr";
new const ENTITY_PLASMABALL_EXPLODE[] = "sprites/zp_br_cso/weapons/plasmabomb.spr";
new const ENTITY_PLASMABALL_SOUND[] = "weapons/plasmagun_exp.wav";
const Float: ENTITY_PLASMABALL_RADIUS = 78.0;
const Float: ENTITY_PLASMABALL_SPEED = 1650.0;
#define ENTITY_PLASMABALL_DAMAGE random_float(65.0, 85.0)
const ENTITY_PLASMABALL_DMGTYPE = DMG_BURN|DMG_NEVERGIB;

/* ~ [ MuzzleFlash ] ~ */
const ENTITY_SPRITES_INTOLERANCE =		100;
const Float: ENTITY_MUZZLE_NEXTTHINK = 	0.2;
new const ENTITY_MUZZLE_CLASSNAME[] = 	"mf_plasmagun";
new const ENTITY_MUZZLE_SPRITE[] =		"sprites/zp_br_cso/weapons/muzzleflash_plasma.spr";

/* ~ [ Offsets ] ~ */
// Linux extra offsets
#define linux_diff_weapon 4
#define linux_diff_player 5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CSprite
#define m_maxFrame 35

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

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

/* ~ [ Params ] ~ */
new gl_iszAllocString_Entity,
	gl_iszAllocString_ModelView,

	gl_iszAllocString_MuzzleKey,
	gl_iszAllocString_PlasmaBall,
	gl_iszAllocString_EnvSprite,

	gl_iszModelIndex_Explode,

	gl_iMsgID_Weaponlist,
	gl_iItemID;

public plugin_init()
{
	register_plugin("[ZP] Weapon: Plasma Gun", "2.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	gl_iItemID = zp_register_extra_item("PlasmaGun", 31, ZP_TEAM_HUMAN);

	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);

	RegisterHam(Ham_Item_Holster,			WEAPON_REFERENCE,	"CWeapon__Holster_Post", true);
	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);

	RegisterHam(Ham_Touch,					"env_sprite",		"CSprite__Touch_Post", true);
	RegisterHam(Ham_Think,					"env_sprite",		"CMuzzleFlash__Think_Pre", false);

	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);

	engfunc(EngFunc_PrecacheModel, ENTITY_PLASMABALL_SPRITE);
	engfunc(EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITE);

	// Precache generic
	UTIL_PrecacheSpritesFromTxt(WEAPON_WEAPONLIST);
	
	// Precache sounds
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_FIRE);
	engfunc(EngFunc_PrecacheSound, ENTITY_PLASMABALL_SOUND);
	engfunc(EngFunc_PrecacheSound, "common/null.wav");

	// Other
	gl_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	gl_iszAllocString_MuzzleKey = engfunc(EngFunc_AllocString, ENTITY_MUZZLE_CLASSNAME);
	gl_iszAllocString_EnvSprite = engfunc(EngFunc_AllocString, "env_sprite");
	gl_iszAllocString_PlasmaBall = engfunc(EngFunc_AllocString, ENTITY_PLASMABALL_CLASSNAME);

	// Model Index
	gl_iszModelIndex_Explode = engfunc(EngFunc_PrecacheModel, ENTITY_PLASMABALL_EXPLODE);
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

	emit_sound(iPlayer, CHAN_WEAPON, "common/null.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	
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

	emit_sound(iPlayer, CHAN_WEAPON, "common/null.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);

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
	
	set_pev(iPlayer, pev_punchangle, Float: { -5.0, 0.0, 0.0});

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_FIRE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	UTIL_CreateMuzzleFlash(iPlayer, ENTITY_MUZZLE_SPRITE, random_float(0.1, 0.12), 200.0, 1);

	set_pdata_int(iItem, m_iClip, iClip - 1, linux_diff_weapon);
	Create_PlasmaBall(iPlayer);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CSprite__Touch_Post(iEntity, iTouch)
{
	if(pev_valid(iEntity) != PDATA_SAFE) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_PlasmaBall)
	{
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
		set_pev(iEntity, pev_velocity, Float: {0.0, 0.0, 0.0});

		emit_sound(iEntity, CHAN_ITEM, ENTITY_PLASMABALL_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0);
		write_byte(TE_EXPLOSION); // TE
		engfunc(EngFunc_WriteCoord, vecOrigin[0]); // Position X
		engfunc(EngFunc_WriteCoord, vecOrigin[1]); // Position Y
		engfunc(EngFunc_WriteCoord, vecOrigin[2] + 20.0); // Position Z
		write_short(gl_iszModelIndex_Explode); // Model Index
		write_byte(8); // Scale
		write_byte(32); // Framerate
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES); // Flags
		message_end();

		new iVictim = FM_NULLENT;
		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_PLASMABALL_RADIUS)) > 0)
		{
			if(pev(iVictim, pev_takedamage) == DAMAGE_NO) 
				continue;

			if(is_user_alive(iVictim))
			{
				if(zp_is_round_end() || iVictim == iOwner || !zp_get_user_zombie(iVictim) || !is_wall_between_points(iEntity, iVictim))
					continue;

				set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player);
				zp_set_user_knock_by_missile(iVictim, iOwner, 260.0, 0.2);
			}
			else if(pev(iVictim, pev_solid) == SOLID_BSP)
			{
				if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
					continue;
			}

			ExecuteHamB(Ham_TakeDamage, iVictim, iOwner, iOwner, ENTITY_PLASMABALL_DAMAGE, ENTITY_PLASMABALL_DMGTYPE)
		}

		set_pev(iEntity, pev_flags, FL_KILLME);
	}

	return HAM_IGNORED;
}

public CMuzzleFlash__Think_Pre(iSprite)
{
	if(pev_valid(iSprite) != PDATA_SAFE || pev(iSprite, pev_impulse) != gl_iszAllocString_MuzzleKey) return HAM_IGNORED;

	static Float: flFrame;
	if(pev(iSprite, pev_frame, flFrame) && ++flFrame - 1.0 < get_pdata_float(iSprite, m_maxFrame, linux_diff_weapon))
	{
		set_pev(iSprite, pev_frame, flFrame);
		set_pev(iSprite, pev_nextthink, get_gametime() + ENTITY_MUZZLE_NEXTTHINK);
		
		return HAM_SUPERCEDE;
	}

	set_pev(iSprite, pev_flags, FL_KILLME);

	return HAM_SUPERCEDE;
}

// [ Other ]
public Create_PlasmaBall(iPlayer)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_EnvSprite);
	if(!iEntity) return 0;

	new Float: flGameTime = get_gametime();
	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
	new Float: vecVelocity[3]; xs_vec_copy(vecForward, vecVelocity);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);

	vecOrigin[0] += vecViewOfs[0] + vecForward[0] * 20.0;
	vecOrigin[1] += vecViewOfs[1] + vecForward[1] * 20.0;
	vecOrigin[2] += vecViewOfs[2] + vecForward[2] * 20.0;

	vecVelocity[0] *= ENTITY_PLASMABALL_SPEED;
	vecVelocity[1] *= ENTITY_PLASMABALL_SPEED;
	vecVelocity[2] *= ENTITY_PLASMABALL_SPEED;

	engfunc(EngFunc_SetModel, iEntity, ENTITY_PLASMABALL_SPRITE);
	set_pev_string(iEntity, pev_classname, gl_iszAllocString_PlasmaBall);
	set_pev(iEntity, pev_spawnflags, SF_SPRITE_STARTON);
	set_pev(iEntity, pev_animtime, flGameTime);
	set_pev(iEntity, pev_framerate, 32.0);
	set_pev(iEntity, pev_frame, 1.0);
	set_pev(iEntity, pev_rendermode, kRenderTransAdd);
	set_pev(iEntity, pev_renderamt, 200.0);
	set_pev(iEntity, pev_scale, random_float(0.2, 0.4));

	dllfunc(DLLFunc_Spawn, iEntity);

	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_owner, iPlayer);
	set_pev(iEntity, pev_velocity, vecVelocity);

	engfunc(EngFunc_SetSize, iEntity, Float: {-1.0, -1.0, -1.0}, Float: {1.0, 1.0, 1.0});
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

	return iEntity;
}

// [ Stocks ]
stock Sprite_SetTransparency(const iSprite, const iRendermode, const Float: flAmt, const iFx = kRenderFxNone)
{
	set_pev(iSprite, pev_rendermode, iRendermode);
	set_pev(iSprite, pev_renderamt, flAmt);
	set_pev(iSprite, pev_renderfx, iFx);
}

stock UTIL_CreateMuzzleFlash(const iPlayer, const szMuzzleSprite[], const Float: flScale, const Float: flBrightness, const iAttachment)
{
	if(global_get(glb_maxEntities) - engfunc(EngFunc_NumberOfEntities) < ENTITY_SPRITES_INTOLERANCE) return FM_NULLENT;
	
	static iSprite, iszAllocStringCached;
	if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "env_sprite")))
		iSprite = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	
	if(pev_valid(iSprite) != PDATA_SAFE) return FM_NULLENT;
	
	set_pev(iSprite, pev_model, szMuzzleSprite);
	set_pev(iSprite, pev_spawnflags, SF_SPRITE_ONCE);
	
	set_pev(iSprite, pev_classname, ENTITY_MUZZLE_CLASSNAME);
	set_pev(iSprite, pev_impulse, gl_iszAllocString_MuzzleKey);
	set_pev(iSprite, pev_owner, iPlayer);
	set_pev(iSprite, pev_aiment, iPlayer);
	set_pev(iSprite, pev_body, iAttachment);
	
	Sprite_SetTransparency(iSprite, kRenderTransAdd, flBrightness);
	set_pev(iSprite, pev_scale, flScale);
	
	dllfunc(DLLFunc_Spawn, iSprite)

	return iSprite;
}

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