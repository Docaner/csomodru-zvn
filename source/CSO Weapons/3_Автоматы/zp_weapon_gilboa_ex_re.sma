/*
 * Weapon by xUnicorn (t3rkecorejz)
 *
 * Thanks a lot:
 *
 * Chrescoe1 & batcoh (Phenix) — First base code
 * KORD_12.7 & 406 (Nightfury) — I'm taken some functions from this authors
 * D34, 404 & fl0wer — Some help
 */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <reapi>
#include <zombieplague>

/* ~ [ Macroses ] ~ */
#define EJECT_BRASS						// Comment this line if u dont need eject brass (shell)
#define CUSTOM_WEAPONLIST 				// Comment this line if u dont need weapon list
//#define CUSTOM_MUZZLEFLASH				// Comment this line if u dont need custom muzzle flash
//#define WALLPUFF_SMOKE					// Comment this line if u dont need wallpuff smoke
#define DYNAMIC_CROSSHAIR 				// Comment this line if u dont need dynamic crosshair (With it not work's plugin Unlimited Clip)

#define LOWER_LIMIT_OF_ENTITIES			100

#define IsCustomWeapon(%0) 				(get_entvar(%0, var_impulse) == WEAPON_KEY)
#define GetItemClip(%0) 				get_member(%0, m_Weapon_iClip)
#define PrecacheArray(%0,%1)			for(new i; i < sizeof %1; i++) engfunc(EngFunc_Precache%0, %1[i])

/* ~ [ Extra Item ] ~ */
new const EXTRA_ITEM_NAME[] = 			"Gilboa Viper";
const EXTRA_ITEM_COST = 				0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[] = 			"weapon_ak47";
new const WEAPON_ANIMATION[] = 			"rifle";
new const WEAPON_NATIVE[] = 			"zp_give_user_gilboaex";
new const WEAPON_MODEL_VIEW[] = 		"models/x_re/v_gilboaex.mdl";
new const WEAPON_MODEL_PLAYER[] = 		"models/x_re/p_gilboaex.mdl";
new const WEAPON_MODEL_WORLD[] = 		"models/x_re/w_gilboaex.mdl";
#if defined EJECT_BRASS
	new const WEAPON_MODEL_SHELL[] = 		"models/rshell.mdl";
#endif
new const WEAPON_SOUNDS[][] =
{
	"weapons/gilboaex-1.wav",
	"weapons/gilboaex-2.wav"
};
#if defined CUSTOM_WEAPONLIST
	new const WEAPON_WEAPONLIST[] = 	"x_re/weapon_gilboaex";
	new const WEAPON_RESOURCES[][] =
	{
		// Custom resources precache, sprites for example
		"sprites/x_re/640hud7.spr",
		"sprites/x_re/640hud116.spr"
	};
#endif
#if defined CUSTOM_MUZZLEFLASH
	#define var_max_frame var_yaw_speed
	new const MUZZLEFLASH_REFERENCE[] = "env_sprite";
	new const MUZZLEFLASH_CLASSNAME[] =	"ent_muzzleflash";
	new const MUZZLEFLASH_SPRITE[] = 	"sprites/x/muzzleflash107.spr";
#endif
#if defined WALLPUFF_SMOKE
	new const SMOKE_REFERENCE[] = 		"env_sprite";
	new const SMOKE_CLASSNAME[] = 		"ent_smokepuff";
#endif

const WEAPON_MODEL_WORLD_BODY = 		0;
const WEAPON_MAX_CLIP = 				60;
const WEAPON_DEFAULT_AMMO = 			200;
const WEAPON_SHOT_PENETRATION = 		2;
const Bullet: WEAPON_BULLET_TYPE = 		BULLET_PLAYER_556MM;
const Float: WEAPON_SHOT_DISTANCE = 	8192.0;
const Float: WEAPON_RATE = 				0.0955;
const Float: WEAPON_RATE_EX = 			0.20;
const Float: WEAPON_DAMAGE = 			38.0;
const Float: WEAPON_ACCURACY = 			0.35;
const Float: WEAPON_RANGE_MODIFER = 	0.98;

/* ~ [ Weapon Animations ] ~ */
enum _: eAnimList
{
	WEAPON_ANIM_IDLE = 0,
	WEAPON_ANIM_RELOAD,
	WEAPON_ANIM_DRAW,
	WEAPON_ANIM_SHOOT1,
	WEAPON_ANIM_SHOOT2,
	WEAPON_ANIM_SHOOT3
};

#define WEAPON_ANIM_IDLE_TIME 			301/30.0
#define WEAPON_ANIM_RELOAD_TIME 		91/30.0
#define WEAPON_ANIM_DRAW_TIME 			31/30.0
#define WEAPON_ANIM_SHOOT_TIME 			26/30.0

/* ~ [ Params ] ~ */
#define WEAPON_KEY 928538

new gl_iItemID;
#if defined CUSTOM_MUZZLEFLASH || defined WALLPUFF_SMOKE
	new gl_iMaxEntities;
#endif
new Array: gl_aDecals;
new gl_FmHook_DecalIndex;
/* new gl_iAllocString_WeaponUID; */
#if defined EJECT_BRASS
	new gl_iszModelIndex_Shell;
#endif
#if defined CUSTOM_WEAPONLIST || defined DYNAMIC_CROSSHAIR
	new gl_iMsgID_Weaponlist;
#endif
#if defined DYNAMIC_CROSSHAIR
	new gl_iMsgID_CurWeapon;
#endif

/* ~ [ AMX Mod X ] ~ */
public plugin_init()
{
	register_plugin("[ZP] Weapon: Gilboa Viper", "2.0", "xUnicorn (t3rkecorejz)");

	/* -> Fakemeta -> */
	unregister_forward(FM_DecalIndex, gl_FmHook_DecalIndex, true);
	register_forward(FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true);

	/* -> ReAPI -> */
	RegisterHookChain(RG_CWeaponBox_SetModel, "CWeaponBox_SetModel_Pre", false);

	/* -> HamSandiwch -> */
	RegisterHam(Ham_Spawn, WEAPON_REFERENCE, "CWeapon_Spawn_Post", true);

	RegisterHam(Ham_Item_Deploy, WEAPON_REFERENCE, "CWeapon_Deploy_Post", true);
	RegisterHam(Ham_Item_Holster, WEAPON_REFERENCE, "CWeapon_Holster_Post", true);

	#if defined CUSTOM_WEAPONLIST
		RegisterHam(Ham_Item_AddToPlayer, WEAPON_REFERENCE, "CWeapon_AddToPlayer_Post", true);
	#endif
	#if defined DYNAMIC_CROSSHAIR
		RegisterHam(Ham_Item_PostFrame, WEAPON_REFERENCE, "CWeapon_PostFrame_Pre", false);
	#endif

	RegisterHam(Ham_Weapon_Reload, WEAPON_REFERENCE, "CWeapon_Reload_Post", true);
	RegisterHam(Ham_Weapon_WeaponIdle, WEAPON_REFERENCE, "CWeapon_WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_REFERENCE, "CWeapon_PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_REFERENCE, "CWeapon_SecondaryAttack_Pre", false);

	#if defined CUSTOM_MUZZLEFLASH || defined WALLPUFF_SMOKE
		RegisterHam(Ham_Think, "env_sprite", "CSprite_Think_Post", true);
	#endif

	/* -> Register on Extra-Items -> */
	gl_iItemID = zp_register_extra_item(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, ZP_TEAM_HUMAN);

	/* -> Messages -> */
	#if defined CUSTOM_WEAPONLIST || defined DYNAMIC_CROSSHAIR
		gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	#endif
	#if defined DYNAMIC_CROSSHAIR
		gl_iMsgID_CurWeapon = get_user_msgid("CurWeapon");
	#endif

	/* -> Other -> */
	#if defined CUSTOM_MUZZLEFLASH || defined WALLPUFF_SMOKE
		gl_iMaxEntities = global_get(glb_maxEntities);
	#endif
	/* #if defined CUSTOM_WEAPONLIST
		gl_iAllocString_WeaponUID = engfunc(EngFunc_AllocString, WEAPON_WEAPONLIST);
	#else
		gl_iAllocString_WeaponUID = engfunc(EngFunc_AllocString, WEAPON_NATIVE);
	#endif */
}

public plugin_precache()
{
	#if defined CUSTOM_WEAPONLIST
		/* -> Hook Weapon -> */
		register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");

		/* -> Precache Generic -> */
		engfunc(EngFunc_PrecacheGeneric, fmt("sprites/%s.txt", WEAPON_WEAPONLIST));

		PrecacheArray(Generic, WEAPON_RESOURCES);
	#endif

	/* -> Precache Models -> */
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

	#if defined CUSTOM_MUZZLEFLASH
		engfunc(EngFunc_PrecacheModel, MUZZLEFLASH_SPRITE);
	#endif
	
	/* -> Precache Sounds -> */
	PrecacheArray(Sound, WEAPON_SOUNDS);

	#if defined EJECT_BRASS
		/* -> Model Index -> */
		gl_iszModelIndex_Shell = engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_SHELL);
	#endif

	/* -> Decals -> */
	gl_aDecals = ArrayCreate(1, 1);
	gl_FmHook_DecalIndex = register_forward(FM_DecalIndex, "FM_Hook_DecalIndex_Post", true);
}
public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);

#if defined CUSTOM_WEAPONLIST
	public Command_HookWeapon(const pPlayer)
	{
		engclient_cmd(pPlayer, WEAPON_REFERENCE);
		return PLUGIN_HANDLED;
	}
#endif

public Command_GiveWeapon(const pPlayer)
{
	new pItem = rg_give_custom_item(pPlayer, WEAPON_REFERENCE, GT_DROP_AND_REPLACE, WEAPON_KEY);
	if(is_nullent(pItem)) return NULLENT;

	return pItem;
}

/* ~ [ Zombie Plague ] ~ */
public zp_extra_item_selected(pPlayer, iItemID)
{
	if(iItemID == gl_iItemID)
		Command_GiveWeapon(pPlayer);
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post(const pPlayer, const iSendWeapons, const CD_Handle)
{
	if(!is_user_alive(pPlayer)) return;

	static pActiveItem; pActiveItem = get_member(pPlayer, m_pActiveItem);
	if(is_nullent(pActiveItem) || !IsCustomWeapon(pActiveItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_DecalIndex_Post() ArrayPushCell(gl_aDecals, get_orig_retval());

public FM_Hook_TraceLine_Post(const Float: vecSrc[3], const Float: vecEnd[3], const bitsFlags, const pEntToSkip, const pTrace)
{
	if(bitsFlags & IGNORE_MONSTERS) return

	new Float: flFraction; get_tr2(pTrace, TR_flFraction, flFraction);
	if(flFraction == 1.0) return;

	UTIL_GunshotDecalTrace(pTrace, true);
}

/* ~ [ ReAPI ] ~ */
public CWeaponBox_SetModel_Pre(const pWeaponBox)
{
	if(is_nullent(pWeaponBox)) return HC_CONTINUE;

	new pItem = UTIL_GetWeaponBoxItem(pWeaponBox);
	if(is_nullent(pItem) || !IsCustomWeapon(pItem)) return HC_CONTINUE;

	SetHookChainArg(2, ATYPE_STRING, WEAPON_MODEL_WORLD);
	set_entvar(pWeaponBox, var_body, WEAPON_MODEL_WORLD_BODY);

	return HC_CONTINUE;
}

/* ~ [ HamSandwich ] ~ */
public CWeapon_Spawn_Post(const pItem)
{
	if(is_nullent(pItem) || !IsCustomWeapon(pItem)) return;

	set_member(pItem, m_Weapon_iClip, WEAPON_MAX_CLIP);
	set_member(pItem, m_Weapon_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
	set_member(pItem, m_Weapon_bHasSecondaryAttack, true);
	rg_set_iteminfo(pItem, ItemInfo_iMaxClip, WEAPON_MAX_CLIP);
	rg_set_iteminfo(pItem, ItemInfo_iMaxAmmo1, WEAPON_DEFAULT_AMMO);

	#if defined CUSTOM_WEAPONLIST
		rg_set_iteminfo(pItem, ItemInfo_pszName, WEAPON_WEAPONLIST);
	#endif

}

public CWeapon_Deploy_Post(const pItem)
{
	new pPlayer;
	if(!CheckItem(pItem, pPlayer)) return;

	set_entvar(pPlayer, var_viewmodel, WEAPON_MODEL_VIEW);
	set_entvar(pPlayer, var_weaponmodel, WEAPON_MODEL_PLAYER);

	UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_DRAW);

	set_member(pItem, m_Weapon_flAccuracy, WEAPON_ACCURACY);
	set_member(pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME);
	set_member(pPlayer, m_szAnimExtention, WEAPON_ANIMATION);
	set_member(pPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME);
}

public CWeapon_Holster_Post(const pItem)
{
	new pPlayer;
	if(!CheckItem(pItem, pPlayer)) return;

	#if defined CUSTOM_MUZZLEFLASH
		new pSprite = NULLENT;
		if(rg_find_ent_by_owner(pSprite, MUZZLEFLASH_CLASSNAME, pPlayer) && !is_nullent(pSprite))
			UTIL_KillEntity(pSprite);
	#endif
	
	set_member(pItem, m_Weapon_flTimeWeaponIdle, 1.0);
	set_member(pPlayer, m_flNextAttack, 1.0);
}

#if defined CUSTOM_WEAPONLIST
	public CWeapon_AddToPlayer_Post(const pItem, const pPlayer)
	{
		new iWeaponUID = get_entvar(pItem, var_impulse);
		if(iWeaponUID != 0 && iWeaponUID != WEAPON_KEY) return;

		UTIL_WeaponList(pPlayer, pItem);
	}
#endif

#if defined DYNAMIC_CROSSHAIR
	public CWeapon_PostFrame_Pre(const pItem)
	{
		new pPlayer;
		if(!CheckItem(pItem, pPlayer)) return HAM_IGNORED;

		UTIL_ResetCrosshair(pPlayer, pItem);
		return HAM_IGNORED;
	}
#endif

public CWeapon_Reload_Post(const pItem)
{
	new pPlayer;
	if(!CheckItem(pItem, pPlayer)) return;

	if(!get_member(pPlayer, m_rgAmmo, get_member(pItem, m_Weapon_iPrimaryAmmoType))) return;
	if(GetItemClip(pItem) >= rg_get_iteminfo(pItem, ItemInfo_iMaxClip)) return;

	UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_RELOAD);

	set_member(pPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME);
	set_member(pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME);
}

public CWeapon_WeaponIdle_Pre(const pItem)
{
	static pPlayer;
	if(!CheckItem(pItem, pPlayer)) return HAM_IGNORED;
	if(get_member(pItem, m_Weapon_flTimeWeaponIdle) > 0.0) return HAM_IGNORED;

	UTIL_SendWeaponAnim(pPlayer, WEAPON_ANIM_IDLE);
	set_member(pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME);

	return HAM_SUPERCEDE;
}

public CWeapon_PrimaryAttack_Pre(const pItem)
{
	static pPlayer;
	if(!CheckItem(pItem, pPlayer)) return HAM_IGNORED;
	if(!GetItemClip(pItem))
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, pItem);
		set_member(pItem, m_Weapon_flNextPrimaryAttack, 0.2);

		return HAM_SUPERCEDE;
	}
	
	CWeapon_Fire(pPlayer, pItem, WEAPON_SOUNDS[0], random_num(WEAPON_ANIM_SHOOT1, WEAPON_ANIM_SHOOT3), WEAPON_RATE);

	return HAM_SUPERCEDE;
}

public CWeapon_SecondaryAttack_Pre(const pItem)
{
	static pPlayer;
	if(!CheckItem(pItem, pPlayer)) return HAM_IGNORED;
	if(!GetItemClip(pItem))
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, pItem);
		set_member(pItem, m_Weapon_flNextSecondaryAttack, 0.2);

		return HAM_SUPERCEDE;
	}

	new iCycles = (GetItemClip(pItem) >= 2) ? 2 : 1;
	for(new i = 0; i < (iCycles); i++)
		CWeapon_Fire(pPlayer, pItem, WEAPON_SOUNDS[1], WEAPON_ANIM_SHOOT2, WEAPON_RATE_EX);

	return HAM_SUPERCEDE;
}

public CWeapon_Fire(const pPlayer, const pItem, const szShootSound[], const iAnim, const Float: flNextAttack)
{
	new Float: vecVelocity[3]; get_entvar(pPlayer, var_velocity, vecVelocity);
	new Float: vecOrigin[3]; get_entvar(pPlayer, var_origin, vecOrigin);
	new Float: vecViewOfs[3]; get_entvar(pPlayer, var_view_ofs, vecViewOfs);
	new Float: vecSrc[3]; xs_vec_add(vecOrigin, vecViewOfs, vecSrc);
	new Float: vecAiming[3]; UTIL_GetVectorAiming(pPlayer, vecAiming);
	new Float: flSpread;
	new Float: flAccuracy = get_member(pItem, m_Weapon_flAccuracy);
	new iShotsFired = get_member(pItem, m_Weapon_iShotsFired);
	new bitsFlags = get_entvar(pPlayer, var_flags);
	new iClip = GetItemClip(pItem);
	iShotsFired++;
	iClip--;

	if(~bitsFlags & FL_ONGROUND)
		flSpread = 0.2 * flAccuracy;
	else flSpread = 0.08 * flAccuracy;

	if(flAccuracy != 0.0)
	{
		flAccuracy = ((iShotsFired * iShotsFired) / 220.0) + 0.30;
		if(flAccuracy > 1.0) flAccuracy = 1.0;
	}

	new FmHook_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
	rg_fire_bullets3(pItem, pPlayer, vecSrc, vecAiming, flSpread, WEAPON_SHOT_DISTANCE, WEAPON_SHOT_PENETRATION, WEAPON_BULLET_TYPE, floatround(WEAPON_DAMAGE), WEAPON_RANGE_MODIFER, false, get_member(pPlayer, random_seed));
	unregister_forward(FM_TraceLine, FmHook_TraceLine, true);

	#if defined CUSTOM_MUZZLEFLASH
		UTIL_DrawMuzzleFlash(pPlayer, MUZZLEFLASH_SPRITE, .flScale = 0.1, .flFramerateMlt = 3.0);
	#endif
	#if defined DYNAMIC_CROSSHAIR
		UTIL_IncreaseCrosshair(pPlayer, pItem);
	#endif
	UTIL_SendWeaponAnim(pPlayer, iAnim);
	UTIL_SendPlayerAnim(pPlayer, WEAPON_ANIMATION);
	rh_emit_sound2(pPlayer, 0, CHAN_WEAPON, szShootSound);

	if(xs_vec_len_2d(vecVelocity) > 0)
		UTIL_WeaponKickBack(pItem, pPlayer, 1.0, 0.45, 0.28, 0.04, 4.25, 2.5, 7);
	else if(~bitsFlags & FL_ONGROUND)
		UTIL_WeaponKickBack(pItem, pPlayer, 1.25, 0.45, 0.22, 0.18, 6.0, 4.0, 5);
	else if(bitsFlags & FL_DUCKING)
		UTIL_WeaponKickBack(pItem, pPlayer, 0.6, 0.35, 0.2, 0.0125, 3.7, 2.0, 10);
	else
		UTIL_WeaponKickBack(pItem, pPlayer, 0.625, 0.375, 0.25, 0.0125, 4.0, 2.25, 9);

	#if defined EJECT_BRASS
		set_member(pItem, m_Weapon_iShellId, gl_iszModelIndex_Shell);
		set_member(pPlayer, m_flEjectBrass, get_gametime());
	#endif

	set_member(pItem, m_Weapon_iClip, iClip);
	set_member(pItem, m_Weapon_flAccuracy, flAccuracy);
	set_member(pItem, m_Weapon_iShotsFired, iShotsFired);
	set_member(pItem, m_Weapon_flNextPrimaryAttack, flNextAttack);
	set_member(pItem, m_Weapon_flNextSecondaryAttack, flNextAttack);
	set_member(pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME);
}

#if defined CUSTOM_MUZZLEFLASH || defined WALLPUFF_SMOKE
	public CSprite_Think_Post(const pSprite)
	{
		if(is_nullent(pSprite)) return;

		#if defined CUSTOM_MUZZLEFLASH
			if(FClassnameIs(pSprite, MUZZLEFLASH_CLASSNAME))
			{
				static Float: flFrame; get_entvar(pSprite, var_frame, flFrame);
				if(flFrame >= get_entvar(pSprite, var_max_frame))
				{
					UTIL_KillEntity(pSprite);
					return;
				}

				set_entvar(pSprite, var_nextthink, get_gametime());
			}
		#endif

		#if defined WALLPUFF_SMOKE
			if(FClassnameIs(pSprite, SMOKE_CLASSNAME))
			{
				static Float: flFrame; get_entvar(pSprite, var_frame, flFrame);
				if(flFrame >= get_entvar(pSprite, var_framerate))
				{
					UTIL_KillEntity(pSprite);
					return;
				}

				static Float: vecVelocity[3]; get_entvar(pSprite, var_velocity, vecVelocity);
				if(flFrame > 7.0)
				{
					xs_vec_mul_scalar(vecVelocity, 0.97, vecVelocity);
					vecVelocity[2] += 0.7;

					if(vecVelocity[2] > 70.0) vecVelocity[2] = 70.0;
				}

				if(flFrame > 6.0)
				{
					static bool: bDirection[2] = { true, true };
					static Float: flMagnitude[2];

					for(new i; i < 2; i++)
					{
						flMagnitude[i] += 0.075;

						if(flMagnitude[i] > 5.0) flMagnitude[i] = 5.0;

						if(bDirection[i]) vecVelocity[i] += flMagnitude[i];
						else vecVelocity[i] -= flMagnitude[i];

						if(!random_num(0, 10) && flMagnitude[i] > 3.0)
						{
							flMagnitude[i] = 0.0;
							bDirection[i] = !bDirection[i];
						}
					}
				}

				set_entvar(pSprite, var_velocity, vecVelocity);
				set_entvar(pSprite, var_nextthink, get_gametime());
			}
		#endif
	}
#endif

/* ~ [ Stocks ] ~ */
bool: CheckItem(const pItem, &pPlayer)
{
	if(is_nullent(pItem) || !IsCustomWeapon(pItem)) return false;

	pPlayer = get_member(pItem, m_pPlayer);
	if(is_nullent(pPlayer) || !is_user_connected(pPlayer)) return false;

	return true;
}

stock UTIL_KillEntity(const pEntity)
{
	set_entvar(pEntity, var_flags, FL_KILLME);
	set_entvar(pEntity, var_nextthink, get_gametime());
}

stock UTIL_SendWeaponAnim(const pPlayer, const iAnim)
{
	set_entvar(pPlayer, var_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, .player = pPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_PlayerAnimation(const pPlayer, const szAnim[])
{
	new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
	if((iAnimDesired = lookup_sequence(pPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
		iAnimDesired = 0;

	set_entvar(pPlayer, var_frame, 0.0);
	set_entvar(pPlayer, var_framerate, 1.0);
	set_entvar(pPlayer, var_animtime, get_gametime());
	set_entvar(pPlayer, var_sequence, iAnimDesired);
	
	set_member(pPlayer, m_fSequenceLoops, bLoops);
	set_member(pPlayer, m_fSequenceFinished, 0);
	set_member(pPlayer, m_flFrameRate, flFrameRate);
	set_member(pPlayer, m_flGroundSpeed, flGroundSpeed);
	set_member(pPlayer, m_flLastEventCheck, get_gametime());
	set_member(pPlayer, m_Activity, ACT_RANGE_ATTACK1);
	set_member(pPlayer, m_IdealActivity, ACT_RANGE_ATTACK1);
	set_member(pPlayer, m_flLastFired, get_gametime());
}

stock UTIL_SendPlayerAnim(const pPlayer, const szAnim[])
{
	static szAnimation[64];
	formatex(szAnimation, charsmax(szAnimation), get_entvar(pPlayer, var_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", szAnim);
	UTIL_PlayerAnimation(pPlayer, szAnimation);
}

#if defined CUSTOM_WEAPONLIST
	stock UTIL_WeaponList(const pPlayer, const pItem)
	{
		new szWeaponName[32]; rg_get_iteminfo(pItem, ItemInfo_pszName, szWeaponName, charsmax(szWeaponName));

		message_begin(MSG_ONE, gl_iMsgID_Weaponlist, .player = pPlayer);
		write_string(szWeaponName);
		write_byte(get_member(pItem, m_Weapon_iPrimaryAmmoType));
		write_byte(rg_get_iteminfo(pItem, ItemInfo_iMaxAmmo1));
		write_byte(get_member(pItem, m_Weapon_iSecondaryAmmoType));
		write_byte(rg_get_iteminfo(pItem, ItemInfo_iMaxAmmo2));
		write_byte(rg_get_iteminfo(pItem, ItemInfo_iSlot));
		write_byte(rg_get_iteminfo(pItem, ItemInfo_iPosition));
		write_byte(rg_get_iteminfo(pItem, ItemInfo_iId));
		write_byte(rg_get_iteminfo(pItem, ItemInfo_iFlags));
		message_end();
	}
#endif

#if defined CUSTOM_MUZZLEFLASH
	stock UTIL_DrawMuzzleFlash(const pPlayer, const szModel[], const iAttachment = 1, const Float: flScale = 0.08, const Float: flFramerateMlt = 2.0, const Float: flColor[3] = { 0.0, 0.0, 0.0 }, const Float: flBrightness = 255.0)
	{
		if(!strlen(szModel)) return NULLENT;
		if(gl_iMaxEntities - engfunc(EngFunc_NumberOfEntities) <= LOWER_LIMIT_OF_ENTITIES) return NULLENT;

		static pSprite; pSprite = NULLENT;
		rg_find_ent_by_owner(pSprite, MUZZLEFLASH_CLASSNAME, pPlayer);
		if(!is_nullent(pSprite))
		{
			set_entvar(pSprite, var_frame, 0.0);
			return NULLENT;
		}

		pSprite = rg_create_entity(MUZZLEFLASH_REFERENCE);
		if(is_nullent(pSprite)) return NULLENT;

		new Float: flFrames = float(engfunc(EngFunc_ModelFrames, engfunc(EngFunc_ModelIndex, szModel)));

		set_entvar(pSprite, var_classname, MUZZLEFLASH_CLASSNAME);
		set_entvar(pSprite, var_spawnflags, SF_SPRITE_ONCE);
		set_entvar(pSprite, var_frame, 0.0);
		set_entvar(pSprite, var_framerate, flFrames * flFramerateMlt);
		set_entvar(pSprite, var_max_frame, flFrames - 1.0);
		set_entvar(pSprite, var_rendermode, kRenderTransAdd);
		set_entvar(pSprite, var_rendercolor, flColor);
		set_entvar(pSprite, var_renderamt, flBrightness);
		set_entvar(pSprite, var_scale, flScale);
		set_entvar(pSprite, var_owner, pPlayer);
		set_entvar(pSprite, var_aiment, pPlayer);
		set_entvar(pSprite, var_body, iAttachment);
		
		engfunc(EngFunc_SetModel, pSprite, szModel);
		dllfunc(DLLFunc_Spawn, pSprite);

		return pSprite;
	}
#endif

#if defined WALLPUFF_SMOKE
	stock UTIL_SmokeWallpuff(Float: vecEndPos[3], Float: vecPlaneNormal[3], szModel[MAX_RESOURCE_PATH_LENGTH] = "", const Float: flScale = 0.5, const Float: flColor[3] = { 40.0, 40.0, 40.0 })
	{
		if(gl_iMaxEntities - engfunc(EngFunc_NumberOfEntities) <= LOWER_LIMIT_OF_ENTITIES) return NULLENT;
		
		new pSprite = rg_create_entity(SMOKE_REFERENCE);
		if(is_nullent(pSprite)) return NULLENT;

		if(!strlen(szModel)) formatex(szModel, charsmax(szModel), "sprites/wall_puff%i.spr", random_num(1, 4));

		xs_vec_add_scaled(vecEndPos, vecPlaneNormal, 3.0, vecEndPos);
		xs_vec_mul_scalar(vecPlaneNormal, random_float(25.0, 30.0), vecPlaneNormal);

		set_entvar(pSprite, var_classname, SMOKE_CLASSNAME);
		set_entvar(pSprite, var_spawnflags, SF_SPRITE_ONCE);
		set_entvar(pSprite, var_framerate, float(engfunc(EngFunc_ModelFrames, engfunc(EngFunc_ModelIndex, szModel))));
		set_entvar(pSprite, var_rendermode, kRenderTransAdd);
		set_entvar(pSprite, var_rendercolor, flColor);
		set_entvar(pSprite, var_renderamt, random_float(100.0, 180.0));
		set_entvar(pSprite, var_scale, flScale);
		set_entvar(pSprite, var_velocity, vecPlaneNormal);

		engfunc(EngFunc_SetModel, pSprite, szModel);
		engfunc(EngFunc_SetOrigin, pSprite, vecEndPos);
		dllfunc(DLLFunc_Spawn, pSprite);

		set_entvar(pSprite, var_movetype, MOVETYPE_NOCLIP);

		return pSprite;
	}
#endif

#if defined DYNAMIC_CROSSHAIR
	stock UTIL_IncreaseCrosshair(const pPlayer, const pItem)
	{
		new szWeaponName[32]; rg_get_iteminfo(pItem, ItemInfo_pszName, szWeaponName, charsmax(szWeaponName));

		set_msg_block(gl_iMsgID_CurWeapon, BLOCK_ONCE);

		message_begin(MSG_ONE, gl_iMsgID_Weaponlist, .player = pPlayer);
		write_string(szWeaponName);
		write_byte(get_member(pItem, m_Weapon_iPrimaryAmmoType));
		write_byte(rg_get_iteminfo(pItem, ItemInfo_iMaxAmmo1));
		write_byte(get_member(pItem, m_Weapon_iSecondaryAmmoType));
		write_byte(rg_get_iteminfo(pItem, ItemInfo_iMaxAmmo2));
		write_byte(rg_get_iteminfo(pItem, ItemInfo_iSlot));
		write_byte(13);
		write_byte(any: WEAPON_MAC10);
		write_byte(rg_get_iteminfo(pItem, ItemInfo_iFlags));
		message_end();

		message_begin(MSG_ONE, gl_iMsgID_CurWeapon, .player = pPlayer);
		write_byte(true);
		write_byte(any: WEAPON_MAC10);
		write_byte(GetItemClip(pItem));
		message_end();

		set_member(pItem, m_Weapon_flNextReload, get_gametime() + 0.04);
	}

	stock UTIL_ResetCrosshair(const pPlayer, const pItem)
	{
		if(get_member(pItem, m_Weapon_flNextReload) && get_member(pItem, m_Weapon_flNextReload) <= get_gametime())
		{
			message_begin(MSG_ONE, gl_iMsgID_CurWeapon, .player = pPlayer);
			write_byte(true);
			write_byte(get_member(pItem, m_iId));
			write_byte(GetItemClip(pItem));
			message_end();

			set_member(pItem, m_Weapon_flNextReload, 0.0);
		}
	}
#endif

stock UTIL_WeaponKickBack(const pItem, const pPlayer, Float: flUpBase, Float: flLateralBase, Float: flUpModifier, Float: flLateralModifier, Float: flUpMax, Float: flLateralMax, iDirectionChange)
{
	new Float: flKickUp;
	new Float: flKickLateral;
	new iShotsFired = get_member(pItem, m_Weapon_iShotsFired);
	new iDirection = get_member(pItem, m_Weapon_iDirection);
	new Float: vecPunchangle[3]; get_entvar(pPlayer, var_punchangle, vecPunchangle);

	if(iShotsFired == 1)
	{
		flKickUp = flUpBase;
		flKickLateral = flLateralBase;
	}
	else
	{
		flKickUp = iShotsFired * flUpModifier + flUpBase;
		flKickLateral = iShotsFired * flLateralModifier + flLateralBase;
	}

	vecPunchangle[0] -= flKickUp;

	if(vecPunchangle[0] < -flUpMax)
		vecPunchangle[0] = -flUpMax;

	if(iDirection)
	{
		vecPunchangle[1] += flKickLateral;
		if(vecPunchangle[1] > flLateralMax)
			vecPunchangle[1] = flLateralMax;
	}
	else
	{
		vecPunchangle[1] -= flKickLateral;
		if(vecPunchangle[1] < -flLateralMax)
			vecPunchangle[1] = -flLateralMax;
	}

	if(!random_num(0, iDirectionChange))
		set_member(pItem, m_Weapon_iDirection, iDirection);

	set_entvar(pPlayer, var_punchangle, vecPunchangle);
}

stock UTIL_GetWeaponBoxItem(const pWeaponBox)
{
	new pItem;
	for(new iSlot = 0; iSlot < MAX_ITEM_TYPES; iSlot++)
	{
		pItem = get_member(pWeaponBox, m_WeaponBox_rgpPlayerItems, iSlot);
		if(!is_nullent(pItem))
			return pItem;
	}

	return 0;
}

stock UTIL_GetVectorAiming(const pPlayer, Float: vecAiming[3])
{
	new Float: vecPunchangle[3]; get_entvar(pPlayer, var_punchangle, vecPunchangle);
	new Float: vecViewAngle[3]; get_entvar(pPlayer, var_v_angle, vecViewAngle);
	xs_vec_add(vecViewAngle, vecPunchangle, vecViewAngle);
	angle_vector(vecViewAngle, ANGLEVECTOR_FORWARD, vecAiming);
}

stock UTIL_GunshotDecalTrace(const pTrace, const bool: bIsGunshot = false)
{
	new Float: vecEndPos[3]; get_tr2(pTrace, TR_vecEndPos, vecEndPos);
	new iPointContents = engfunc(EngFunc_PointContents, vecEndPos);
	if(iPointContents == CONTENTS_SKY) return;

	new pHit = (pHit = get_tr2(pTrace, TR_pHit)) == -1 ? 0 : pHit;
	
	if(pHit && is_nullent(pHit) || (get_entvar(pHit, var_flags) & FL_KILLME)) return;
	if(get_entvar(pHit, var_solid) != SOLID_BSP && get_entvar(pHit, var_movetype) != MOVETYPE_PUSHSTEP) return;

	new iDecalIndex = ExecuteHamB(Ham_DamageDecal, pHit, 0);
	if(iDecalIndex < 0 || iDecalIndex >= ArraySize(gl_aDecals)) return;
	
	iDecalIndex = ArrayGetCell(gl_aDecals, iDecalIndex);
	if(iDecalIndex < 0) return;
	
	new iMessage;
	if(bIsGunshot)
		iMessage = TE_GUNSHOTDECAL;
	else
	{
		iMessage = TE_DECAL;
		if(pHit != 0)
		{
			if(iDecalIndex > 255)
			{
				iMessage = TE_DECALHIGH;
				iDecalIndex -= 256;
			}
		}
		else
		{
			iMessage = TE_WORLDDECAL;
			if(iDecalIndex > 255)
			{
				iMessage = TE_WORLDDECALHIGH;
				iDecalIndex -= 256;
			}
		}
	}

	message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecEndPos);
	write_byte(iMessage);
	write_coord_f(vecEndPos[0]);
	write_coord_f(vecEndPos[1]);
	write_coord_f(vecEndPos[2]);
	
	if(bIsGunshot)
	{
		write_short(pHit);
		write_byte(iDecalIndex);
	}
	else 
	{
		write_byte(iDecalIndex);
		if(pHit) write_short(pHit);
	}

	message_end();

	if(bIsGunshot && iPointContents != CONTENTS_WATER)
	{
		new Float: vecPlaneNormal[3]; get_tr2(pTrace, TR_vecPlaneNormal, vecPlaneNormal);

		message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecEndPos);
		write_byte(TE_STREAK_SPLASH);
		write_coord_f(vecEndPos[0]);
		write_coord_f(vecEndPos[1]);
		write_coord_f(vecEndPos[2]);
		write_coord_f(vecPlaneNormal[0] * random_float(25.0, 30.0));
		write_coord_f(vecPlaneNormal[1] * random_float(25.0, 30.0));
		write_coord_f(vecPlaneNormal[2] * random_float(25.0, 30.0));
		write_byte(4); // Color
		write_short(22); // Count
		write_short(3); // Speed
		write_short(65); // Noise
		message_end();

		#if defined WALLPUFF_SMOKE
			UTIL_SmokeWallpuff(vecEndPos, vecPlaneNormal);
		#endif
	}
}
