#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <reapi>
#include <zombieplague>
#include <smart_effects>

new const g_szItemName[] = "Fire Grenade"; // Название
#define GRENADE_COST 10 // Цена
#define GRENADE_TEAM ZP_TEAM_HUMAN // Битсумма команд

#define GRENADE_RADIUS 200.0 // Радиус действия гранаты
#define GRENADE_MAXDAMAGE 850.0 // Максимальный урон со взрыва гранаты

//Модели
new const g_szModelGrenade_V[] = "models/zp_br_cso/grenade/v_firegrenade_b2.mdl";

new const g_szModelGrenade_W[] = "models/zp_br_cso/grenade/w_grenad_s3.mdl";
#define GRENADE_BODY 2

new const g_szSpriteExplode[] = "sprites/zp_br_cso/grenade/ef_fgrenade.spr"; // Спрайт взрыва
new const g_szSpriteCircle[] = "sprites/shockwave.spr"; // Спрайт круга

new const g_szSndExplode[] = "zp_br_cso/grenade/fire_explosion.wav"; // Звук взрыва


new const g_szSoundAmmoPurchase[] = "items/9mmclip1.wav";
new const g_szDefaulModel[] = "models/w_hegrenade.mdl";
new const g_szAmmoType[] = "HEGrenade";
#define WEAPON_REFERENCE WEAPON_HEGRENADE

new const g_szSprBurn[] = "sprites/zp_br_cso/zombie/flameplayer2.spr" // Спрайт горения
new const g_szSprGibs[] = "sprites/zp_br_cso/grenade/fire_gibs.spr"
#define BURN_TOTALFRAMES 37.0 // Количество кадров у стпрайта

#define NADE_TYPE_FLARE 2003
#define WEAPON_FIREGRENADE 5001

#define CustomWeaponBox(%1) (get_entvar(%1, var_flTimeStepSound) == NADE_TYPE_FLARE)
#define CustomWeapon(%1) (get_entvar(%1, var_impulse) == WEAPON_FIREGRENADE)

new g_iFireGrnd;
new g_pSriteExplode, g_pSpriteCircle, g_pSprFireGibs;

#if !defined zp_is_round_end
native zp_is_round_end()
#endif
/*#if !defined ZPE_SetUserBurn
native ZPE_SetUserBurn(id, iTime);
#endif*/

native zp_set_user_flame(const pVictim, const pAttacker, const Float:flSeconds);

public plugin_precache()
{
	precache_model(g_szModelGrenade_V);

	precache_model(g_szModelGrenade_W);
	
	g_pSriteExplode = precache_model(g_szSpriteExplode);
	g_pSpriteCircle = precache_model(g_szSpriteCircle);
	g_pSprFireGibs = precache_model(g_szSprGibs)
	precache_sound(g_szSndExplode);
	precache_sound(g_szSoundAmmoPurchase);

	precache_model(g_szSprBurn);
}

public plugin_init()
{
	register_plugin("[ZPE] Extra Item: Fire Grenade", "1.0", "Docaner")

	register_forward(FM_SetModel, "fw_SetModel_Pre", false);
	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "HM_HeDeploy_Post", true);

	RegisterHam(Ham_Think, "grenade", "HM_ThinkGrenade_Pre", false)

	g_iFireGrnd = zp_register_extra_item(g_szItemName, GRENADE_COST, GRENADE_TEAM)
}

public zp_extra_item_selected(id, itemid)
{
	if(g_iFireGrnd == itemid)
	{
		return give_grenade(id);
	}
	return PLUGIN_CONTINUE;
}

public fw_SetModel_Pre(iEnt, szModel[])
{
	if(!is_entity(iEnt) || !equal(szModel, g_szDefaulModel)) return FMRES_IGNORED;

	new id = get_entvar(iEnt, var_owner);

	if(!is_user_connected(id)) return FMRES_IGNORED;

	new iWeapon = rg_find_weapon_bpack_by_name(id, "weapon_hegrenade");

	if(!is_entity(iWeapon) || !CustomWeapon(iWeapon)) 
		return FMRES_IGNORED;

	engfunc(EngFunc_SetModel, iEnt, g_szModelGrenade_W);

	set_entvar(iEnt, var_body, GRENADE_BODY);
	set_entvar(iEnt, var_flTimeStepSound, NADE_TYPE_FLARE);
	fm_set_rendering(iEnt, kRenderFxGlowShell, 255, 165, 0, kRenderNormal, 0);

	return FMRES_SUPERCEDE;

}

public HM_HeDeploy_Post(iEnt)
{
	if(!CustomWeapon(iEnt)) return;

	new id = get_member(iEnt, m_pPlayer);

	set_entvar(id, var_viewmodel, g_szModelGrenade_V);
}

public HM_ThinkGrenade_Pre(iEnt)
{
	if(!is_entity(iEnt)) return HAM_IGNORED;

	new Float:fDmgTime;
	get_entvar(iEnt, var_dmgtime, fDmgTime);

	if(fDmgTime > get_gametime())
		return HAM_IGNORED;

	if(!CustomWeaponBox(iEnt))
		return HAM_IGNORED;

	custom_explode(iEnt);
	set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);

	return HAM_SUPERCEDE;
}

custom_explode(iEnt)
{
	new Float:fOrigin[3]
	get_entvar(iEnt, var_origin, fOrigin);
	CREATE_BEAMCYLINDER(fOrigin, floatround(GRENADE_RADIUS) * 3, g_pSpriteCircle, _, _, 4, 20, _, 255, 165, 0, 200, _);

	new Float:fOriginSprite[3];
	fOriginSprite = fOrigin;
	fOriginSprite[2] += 80.0;
	CREATE_SPRITE(fOriginSprite, g_pSriteExplode, 20, 200);
	CREATE_SPRITETRAIL(fOriginSprite, g_pSprFireGibs)

	emit_sound(iEnt, CHAN_WEAPON, g_szSndExplode, 1.0, ATTN_NORM, 0, PITCH_NORM);

	if(zp_is_round_end()) return;

	new iVictim = NULLENT, Float:fDistance, Float:fDamage,
		Float:fOriginVic[3], iOwner = get_entvar(iEnt, var_owner), Float:fPerCent; 
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, fOrigin, GRENADE_RADIUS)) > 0)
	{
		if(is_nullent(iVictim) || Float:get_entvar(iVictim, var_takedamage) == DAMAGE_NO) 
			continue;

		if((!is_user_alive(iVictim) || !zp_get_user_zombie(iVictim)) && !IsAliveNPC(iVictim))
			continue;

		get_entvar(iVictim, var_origin, fOriginVic);

		fDistance = get_distance_f(fOrigin, fOriginVic);

		fPerCent = GRENADE_RADIUS - fDistance;
		fPerCent = fPerCent < 0.0 ? -fPerCent : fPerCent;
		fPerCent = fPerCent / GRENADE_RADIUS;
		fPerCent = fPerCent + 0.1 > 1.0 ? 1.0 : fPerCent + 0.1; 

		fDamage = GRENADE_MAXDAMAGE * fPerCent;

		if(IsPlayer(iVictim)) zp_set_user_flame(iVictim, iOwner, 8.0);
		ExecuteHamB(Ham_TakeDamage, iVictim, iEnt, iOwner, fDamage, DMG_GRENADE);
	}
}

public give_grenade(id)
{
	if(rg_get_user_bpammo(id, WEAPON_REFERENCE) >= 2)
		return ZP_PLUGIN_HANDLED;
	new iWeapon = rg_find_weapon_bpack_by_name(id, "weapon_hegrenade");
	if(is_entity(iWeapon) && CustomWeapon(iWeapon))
	{
		ExecuteHamB(Ham_GiveAmmo, id, 1, g_szAmmoType, charsmax(g_szAmmoType));
		emit_sound(id, CHAN_ITEM, g_szSoundAmmoPurchase, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
	else
	{
		new iEnt = rg_give_custom_item(id, "weapon_hegrenade", GT_APPEND, WEAPON_FIREGRENADE);
		if(is_nullent(iEnt))
			return ZP_PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

/*stock CREATE_WORLDDECAL(Float:fOrigin[3], pDecal)
{
	message_begin_f(MSG_PAS, SVC_TEMPENTITY, fOrigin)
	write_byte(TE_WORLDDECAL)
	write_coord_f(fOrigin[0])
	write_coord_f(fOrigin[1])
	write_coord_f(fOrigin[2])
	write_byte(pDecal)
	message_end()
}*/

stock CREATE_SPRITE(Float:fOrigin[3], pSprite, iScale, iAlpha)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	write_coord_f(fOrigin[0])
	write_coord_f(fOrigin[1])
	write_coord_f(fOrigin[2])
	write_short(pSprite)
	write_byte(iScale) // 0.1
	write_byte(iAlpha)
	message_end()
}

stock CREATE_BEAMCYLINDER(Float:vecOrigin[3], iRadius, pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0)
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_BEAMCYLINDER);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2]);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2] + iRadius);
	write_short(pSprite);
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

stock fm_get_user_bpammo(pPlayer, iWeaponId)
{
	new iOffset;
	switch(iWeaponId)
	{
		case CSW_AWP: iOffset = 377; // ammo_338magnum
		case CSW_SCOUT, CSW_AK47, CSW_G3SG1: iOffset = 378; // ammo_762nato
		case CSW_M249: iOffset = 379; // ammo_556natobox
		case CSW_FAMAS, CSW_M4A1, CSW_AUG, CSW_SG550, CSW_GALI, CSW_SG552: iOffset = 380; // ammo_556nato
		case CSW_M3, CSW_XM1014: iOffset = 381; // ammo_buckshot
		case CSW_USP, CSW_UMP45, CSW_MAC10: iOffset = 382; // ammo_45acp
		case CSW_FIVESEVEN, CSW_P90: iOffset = 383; // ammo_57mm
		case CSW_DEAGLE: iOffset = 384; // ammo_50ae
		case CSW_P228: iOffset = 385; // ammo_357sig
		case CSW_GLOCK18, CSW_MP5NAVY, CSW_TMP, CSW_ELITE: iOffset = 386; // ammo_9mm
		case CSW_FLASHBANG: iOffset = 387;
		case CSW_HEGRENADE: iOffset = 388;
		case CSW_SMOKEGRENADE: iOffset = 389;
		case CSW_C4: iOffset = 390;
		default: return 0;
	}
	return get_pdata_int(pPlayer, iOffset);
}

stock fm_set_user_bpammo(pPlayer, iWeaponId, iAmount)
{
	new iOffset;
	switch(iWeaponId)
	{
		case CSW_AWP: iOffset = 377; // ammo_338magnum
		case CSW_SCOUT, CSW_AK47, CSW_G3SG1: iOffset = 378; // ammo_762nato
		case CSW_M249: iOffset = 379; // ammo_556natobox
		case CSW_FAMAS, CSW_M4A1, CSW_AUG, CSW_SG550, CSW_GALI, CSW_SG552: iOffset = 380; // ammo_556nato
		case CSW_M3, CSW_XM1014: iOffset = 381; // ammo_buckshot
		case CSW_USP, CSW_UMP45, CSW_MAC10: iOffset = 382; // ammo_45acp
		case CSW_FIVESEVEN, CSW_P90: iOffset = 383; // ammo_57mm
		case CSW_DEAGLE: iOffset = 384; // ammo_50ae
		case CSW_P228: iOffset = 385; // ammo_357sig
		case CSW_GLOCK18, CSW_MP5NAVY, CSW_TMP, CSW_ELITE: iOffset = 386; // ammo_9mm
		case CSW_FLASHBANG: iOffset = 387;
		case CSW_HEGRENADE: iOffset = 388;
		case CSW_SMOKEGRENADE: iOffset = 389;
		case CSW_C4: iOffset = 390;
		default: return;
	}
	set_pdata_int(pPlayer, iOffset, iAmount);
}

stock CREATE_SPRITETRAIL(Float:vecOrigin[3], pSprite, iCount = 15, iLife = 15, iScale = 2, iSpeed = 50, iSpeedNoise = 10)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPRITETRAIL);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2] - 10.0);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2] + 30.0);
	write_short(pSprite);
	write_byte(iCount);
	write_byte(iLife); // 0,1 sec
	write_byte(iScale); // 0,1
	write_byte(iSpeed); // Начальная скорость (направление = начало -> конец). Не действует, если начальная и конечная точки совпадают.
	write_byte(iSpeedNoise); // Сумма для рандомизации скорости и направления
	message_end()
}