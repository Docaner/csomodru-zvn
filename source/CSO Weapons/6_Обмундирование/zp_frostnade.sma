#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <reapi>
#include <zombieplague>

new const g_szItemName[] = "Frost"; // Название
#define GRENADE_COST 10 // Цена
#define GRENADE_TEAM ZP_TEAM_HUMAN // Битсумма команд

#define GRENADE_RADIUS 200.0 // Радиус действия гранаты
#define GRENADE_EXPLODE_TIME 1.0 // Через сколько секунд взрывать гранату, после того, как её выкинули
#define GRENADE_FROST_TIME 5.0 // На сколько секунд замораживать зомби

//Тип оружия на котором пишется граната
new const g_szDefaulModel[] = "models/w_flashbang.mdl"; // Путь модели
new const g_szAmmoType[] = "Flashbang"; // Тип патронов
new const g_szWeaponName[] = "weapon_flashbang" //Название оружия
#define WEAPON_REFERENCE WEAPON_FLASHBANG
// Ресурсы
new const g_szMdlGrenade_V[] = "models/zp_br_cso/grenade/v_fgrenade2.mdl";

new const g_szMdlGrenade_W[] = "models/zp_br_cso/grenade/w_grenad_s3.mdl";
#define GRENADE_BODY 1

new const g_szMdlGlass[] = "models/glassgibs.mdl";
new const g_szSprSnow[] = "sprites/zp_br_cso/grenade/frostgrenade_exp_gibs.spr";
new const g_szSprExplode[] = "sprites/zp_br_cso/grenade/frostgrenade_exp.spr";

new const g_szSndExplode[] = "zp_br_cso/grenade/frost_explode.wav";
new const g_szSndHit[] = "zp_br_cso/grenade/frost_hit_zombie.wav";
new const g_szSndUnhit[] = "zp_br_cso/grenade/frost_unhit_zombie.wav";

new const g_szSpriteCircle[] = "sprites/shockwave.spr"; // Спрайт круга

new const g_szSoundAmmoPurchase[] = "items/9mmclip1.wav";

#define NADE_TYPE_FROST 4322
#define WEAPON_FROSTNAME 6546

#define is_box_custom(%1) (get_entvar(%1, var_flTimeStepSound) == NADE_TYPE_FROST)
#define is_weapon_custom(%1) (get_entvar(%1, var_impulse) == WEAPON_FROSTNAME)
#define is_user_frozen(%1) (!is_nullent(g_iEntFrost[%1]))

#if !defined zp_is_round_end
native zp_is_round_end();
#endif

#define MsgId_ScreenFade 98

#define UNIT_SECOND (1<<12)

new g_iEntFrost[33];

new g_iExtraNade;

new g_pSpriteCircle, g_pModelGlass, g_pSprExplode, g_pSprSnow;

public plugin_precache()
{
	precache_model(g_szMdlGrenade_V);

	precache_model(g_szMdlGrenade_W);

	precache_sound(g_szSndExplode)
	precache_sound(g_szSndHit)
	precache_sound(g_szSndUnhit)

	precache_sound(g_szSoundAmmoPurchase);

	g_pSpriteCircle = precache_model(g_szSpriteCircle);
	g_pModelGlass = precache_model(g_szMdlGlass);
	g_pSprExplode = precache_model(g_szSprExplode);
	g_pSprSnow = precache_model(g_szSprSnow);
}

public plugin_init()
{
	register_plugin("[ZP] Frost Nade", "1.0", "Docaner");

	RegisterHookChain(RG_CBasePlayer_Killed, "RG_Player_Killed_Post", true);
	RegisterHookChain(RG_CBasePlayer_Jump, "RG_Player_Jump_Post", true);

	RegisterHam(Ham_Item_Deploy, g_szWeaponName, "HM_Nade_Deploy_Post", true);
	RegisterHam(Ham_Item_PreFrame, "player", "HM_Player_PreFrame_Post", true);
	
	register_forward(FM_SetModel, "FW_SetModel_Pre", false);

	g_iExtraNade = zp_register_extra_item(g_szItemName, GRENADE_COST, GRENADE_TEAM);

	arrayset(g_iEntFrost, NULLENT, sizeof g_iEntFrost);
}

public client_disconnected(id, bool:drop, message[], maxlen)
	remove_user_frozen(id);

public zp_extra_item_selected(id, itemid)
{
	if(g_iExtraNade == itemid)
		return give_grenade(id);
	return PLUGIN_CONTINUE;
}

public zp_user_infected_pre(id, infector, nemesis)
	remove_user_frozen(id);

public zp_user_humanized_pre(id, survivor)
	remove_user_frozen(id);

public zp_round_ended(winteam)
	for(new i = 1; i <= MaxClients; i++)
		remove_user_frozen(i);


public RG_Player_Jump_Post(id)
{
	if(!is_user_frozen(id)) return HC_CONTINUE;

	set_entvar(id, var_oldbuttons, get_entvar(id, var_oldbuttons) | IN_JUMP);

	return HC_BREAK;
}

public RG_Player_Killed_Post(iVictim)
	remove_user_frozen(iVictim);

public HM_Nade_Deploy_Post(iEnt)
{
	if(!is_weapon_custom(iEnt)) return;

	new id = get_member(iEnt, m_pPlayer);

	set_entvar(id, var_viewmodel, g_szMdlGrenade_V);
}

public HM_Player_PreFrame_Post(id)
{
	if(is_user_frozen(id))
		set_entvar(id, var_maxspeed, 1.0);
}

public FW_SetModel_Pre(iEnt, szModel[])
{
	if(is_nullent(iEnt) || !equal(szModel, g_szDefaulModel)) 
		return FMRES_IGNORED;

	new id = get_entvar(iEnt, var_owner);

	if(!is_user_connected(id))
		return FMRES_IGNORED;

	new iWeapon = rg_find_weapon_bpack_by_name(id, g_szWeaponName);

	if(is_nullent(iWeapon) || !is_weapon_custom(iWeapon))
		return FMRES_IGNORED;

	engfunc(EngFunc_SetModel, iEnt, g_szMdlGrenade_W);

	set_entvar(iEnt, var_body, GRENADE_BODY);
	set_entvar(iEnt, var_flTimeStepSound, NADE_TYPE_FROST);

	fm_set_rendering(iEnt, kRenderFxGlowShell, 0, 127, 255, kRenderNormal, 0);

	SetThink(iEnt, "RG_Think_Grenade");

	return FMRES_SUPERCEDE;
}

public RG_Think_Grenade(iEnt)
{
	new Float:flDamage = Float:get_entvar(iEnt, var_dmgtime);

	if(flDamage > get_gametime())
	{
		set_entvar(iEnt, var_nextthink, flDamage);
		return HC_CONTINUE;
	}

	custom_explode(iEnt);
	rg_remove_ent(iEnt);

	return HC_BREAK;
}

custom_explode(iEnt)
{
	new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin);
	CREATE_BEAMCYLINDER(vecOrigin, floatround(GRENADE_RADIUS) * 3, g_pSpriteCircle, _, _, 4, 20, _, 0, 127, 255, 200, _);

	new Float:vecExp[3]; xs_vec_copy(vecOrigin, vecExp);
	vecExp[2] += 80;
	CREATE_SPRITE(vecExp, g_pSprExplode, 20, 200);
	CREATE_SPRITETRAIL(vecExp, g_pSprSnow);

	rh_emit_sound2(iEnt, 0, CHAN_WEAPON, g_szSndExplode);

	if(zp_is_round_end()) return;

	new Float:vecEnemy[3];

	for(new iEnemy = 1; iEnemy <= MaxClients; iEnemy++)
	{
		if(!is_user_alive(iEnemy) || !zp_get_user_zombie(iEnemy) || 
			zp_get_user_nemesis(iEnemy) || zp_get_user_first_zombie(iEnemy) || Float:get_entvar(iEnemy, var_takedamage) == DAMAGE_NO)
			continue;

		get_entvar(iEnemy, var_origin, vecEnemy);

		if(get_distance_f(vecOrigin, vecEnemy) > GRENADE_RADIUS)
			continue;


		zp_set_user_frost(iEnemy, GRENADE_FROST_TIME);
	}
}

zp_set_user_frost(id, Float:flTime)
{
	if(is_nullent(g_iEntFrost[id]))
	{
		g_iEntFrost[id] = create_frost(id, flTime);

		SCREEN_FADE(id, UNIT_SECOND, UNIT_SECOND*floatround(flTime), SF_FADE_IN, 0, 127, 255, 50)

		fm_set_rendering(id, kRenderFxGlowShell, 0, 127, 255, kRenderNormal, 0);

		rh_emit_sound2(id, 0, CHAN_ITEM, g_szSndHit);

		set_entvar(id, var_takedamage, DAMAGE_NO);

		ExecuteHamB(Ham_Item_PreFrame, id);
	}	
	else
		set_entvar(g_iEntFrost[id], var_nextthink, get_gametime() + flTime);
}

create_frost(id, Float:flTime)
{
	new iEnt = rg_create_entity("info_target");

	if(is_nullent(iEnt)) return NULLENT;

	set_entvar(iEnt, var_owner, id);

	SetThink(iEnt, "RG_Think_Frost");

	set_entvar(iEnt, var_nextthink, get_gametime() + flTime);

	return iEnt;
}

public RG_Think_Frost(iEnt)
{
	new id = get_entvar(iEnt, var_owner);

	rg_remove_ent(iEnt);

	g_iEntFrost[id] = NULLENT;

	set_entvar(id, var_takedamage, DAMAGE_AIM);

	SCREEN_FADE(id, UNIT_SECOND, UNIT_SECOND, 0, 0, 127, 255, 50)

	new Float:vecOrigin[3]; get_entvar(id, var_origin, vecOrigin);
	CREATE_BREAKMODEL(vecOrigin, _, _, 10, g_pModelGlass, 10, 25, 0x01);

	fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);

	rh_emit_sound2(id, 0, CHAN_ITEM, g_szSndUnhit);

	ExecuteHamB(Ham_Item_PreFrame, id);
}

remove_user_frozen(id)
{
	if(is_user_frozen(id))
	{
		rg_remove_ent(g_iEntFrost[id]);
		g_iEntFrost[id] = NULLENT;
		set_entvar(id, var_takedamage, DAMAGE_AIM);
		SCREEN_FADE(id, 0, 0, 0, 0, 0, 0, 0);
		fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
		ExecuteHamB(Ham_Item_PreFrame, id);
	}
}

public give_grenade(id)
{
	if(rg_get_user_bpammo(id, WEAPON_REFERENCE) >= 2)
		return ZP_PLUGIN_HANDLED;

	new iWeapon = rg_find_weapon_bpack_by_name(id, g_szWeaponName);

	if(!is_nullent(iWeapon) && is_weapon_custom(iWeapon))
	{
		ExecuteHamB(Ham_GiveAmmo, id, 1, g_szAmmoType, charsmax(g_szAmmoType));
		emit_sound(id, CHAN_ITEM, g_szSoundAmmoPurchase, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
	else
	{
		new iEnt = rg_give_custom_item(id, g_szWeaponName, GT_APPEND, WEAPON_FROSTNAME);
		if(is_nullent(iEnt))
			return ZP_PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public plugin_natives()
{
	register_native("zp_is_user_frozen", "zp_is_user_frozen", 1);
}

public zp_is_user_frozen(id) return is_user_frozen(id);

stock rg_remove_ent(iEnt)
{
	set_entvar(iEnt, var_flags, FL_KILLME);
	set_entvar(iEnt, var_nextthink, get_gametime());
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

stock CREATE_BREAKMODEL(Float:vecOrigin[3], Float:vecSize[3] = {16.0, 16.0, 16.0}, Float:vecVelocity[3] = {25.0, 25.0, 25.0}, iRandomVelocity, pModel, iCount, iLife, iFlags)
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_BREAKMODEL);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2] + 24);
	write_coord_f(vecSize[0]);
	write_coord_f(vecSize[1]);
	write_coord_f(vecSize[2]);
	write_coord_f(vecVelocity[0]);
	write_coord_f(vecVelocity[1]);
	write_coord_f(vecVelocity[2]);
	write_byte(iRandomVelocity);
	write_short(pModel);
	write_byte(iCount); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iFlags); // BREAK_GLASS 0x01, BREAK_METAL 0x02, BREAK_FLESH 0x04, BREAK_WOOD 0x08
	message_end();
}

stock SCREEN_FADE(id, iDuration, iHoldtime, iFadeType, iRed, iGreen, iBlue, iAlpha)
{
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, id)
	write_short(iDuration) // duration
	write_short(iHoldtime) // hold time
	write_short(iFadeType) // fade type
	write_byte(iRed) // r
	write_byte(iGreen) // g
	write_byte(iBlue) // b
	write_byte(iAlpha) // alpha
	message_end()
}

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

stock CREATE_SPRITETRAIL(Float:vecOrigin[3], pSprite, iCount = 30, iLife = 15, iScale = 2, iSpeed = 50, iSpeedNoise = 10)
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