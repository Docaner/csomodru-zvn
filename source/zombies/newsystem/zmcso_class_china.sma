#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <zombieplague>
#include <zpe_knokcback>
#include <zc_addon_zclasses>
#include <zc_addon_zchoose>

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))

#define ABILITY_GRAVITY 0.5 // Гравитация во время использования способности
#define ABILITY_DURATION 5.0 // Длительность способности в секундах
#define ABILITY_DELAY 28.0 // Перезарядка способности
#define ABILITY_THINK 0.1 // Think способности
#define ABILITY_DELAY_AFTER_INFECT 10.0 // Откат способности после заражения

#define ABILITY_LIGHT_RADIUS 20 // Радиус света
new const Float:ABILITY_COLOR[3] = {150.0, 255.0, 100.0} // Цвет способности

new const g_szSndAbility[] = "zp_br_cso/mod/nemesis_start.wav"; // Звук способности

new const g_szWpnlistModel[] = "sprites/zp_br_cso/zombie/zmtimer2.txt" // Weaponlist таймер 
new const g_szWpnlistName[] = "zp_br_cso/zombie/zmtimer2" // Название weaponlist

new g_iClass, g_iBitUserClass, g_iMaxPlayers;

new Float:g_flClassGravity;

enum
{
	STATE_NO = 0,
	STATE_READY,
	STATE_THINK,
	STATE_RESTART
}

//=====Анимации=====

enum
{
	ANIM_IDLE = 0,
	ANIM_SLASH1,
	ANIM_SLASH2,
	ANIM_DRAW,
	ANIM_STAB,
	ANIM_STAB_MISS,
	ANIM_STAB_MIDSLASH1,
	ANIM_STAB_MIDSLASH2
}

#define ANIM_STAB_MISS_TIME 1.8

//=====Переменные ножа=====

//Объект ярости
#define var_ent_ability var_iuser1

//Таймер
//var_ltime

//NoSpam
//var_fuser1

//=====Переменные объекта ярости=====

//Таймер
//var_ltime

//===================================

public plugin_precache()
{
	register_plugin("[ZP] Zombie class: China", "0.1b", "Docaner");

	precache_sound(g_szSndAbility);

	precache_generic(g_szWpnlistModel);
	register_clcmd(g_szWpnlistName, "Command_HookWeapon");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_PlayerKilled_Post", true);

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "HM_KnifeDeploy_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_knife", "HM_KnifePostFrame_Pre", 0);

	register_clcmd("drop", "ClCmd_Drop");

	g_iMaxPlayers = get_maxplayers();

	g_iClass = zc_find_zclass_by_shortname("china");
}

public client_disconnected(id, bool:drop, message[], maxlen)
	disable_class(id);

public Command_HookWeapon(id)
{
	engclient_cmd(id, "weapon_knife");
	return PLUGIN_HANDLED;
}


public zp_user_infected_post(id, infector, nemesis)
{
	if(zc_get_user_zclass(id) != g_iClass) 
		return;

	if(nemesis)
	{
		disable_class(id);
		return;
	}

	//Выдача класса
	SetBit(g_iBitUserClass, id);

	if(!g_flClassGravity) g_flClassGravity = Float:get_entvar(id, var_gravity);

	start_delay(id, ABILITY_DELAY_AFTER_INFECT);

	/*new pItem = get_member(id, m_rgpPlayerItems, KNIFE_SLOT);

	if(!is_nullent(pItem)) 
	{
		//Делаем способность доступной
		set_member(pItem, m_Weapon_iWeaponState, STATE_READY);
	}*/
}

public zp_user_humanized_pre(id, survivor)
	disable_class(id);

public zp_round_ended()
{
	if(!g_iBitUserClass) return;

	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
		disable_class(iPlayer);
}

public RG_PlayerKilled_Post(iVictim)
	disable_class(iVictim);

public HM_KnifeDeploy_Post(pItem)
{
	new id = get_member(pItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserClass, id)) 
		return HAM_IGNORED;

	new iWeaponState = get_member(pItem, m_Weapon_iWeaponState);
	switch(iWeaponState)
	{
		case STATE_RESTART: 
		{
			chek_user_ability_timer(id, pItem, true);
		}
	}

	return HAM_IGNORED;
}

public HM_KnifePostFrame_Pre(pItem)
{
	new id = get_member(pItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserClass, id)) 
		return HAM_IGNORED;

	new iWeaponState = get_member(pItem, m_Weapon_iWeaponState);

	switch(iWeaponState)
	{
		case STATE_RESTART: chek_user_ability_timer(id, pItem);
	}

	return HAM_IGNORED;
}

chek_user_ability_timer(id, iWeapon, bool:bReloadWpnlist = false)
{
	new Float:flGameTime = get_gametime(), 
		Float:flTime = Float:get_entvar(iWeapon, var_ltime);

	if(flGameTime < flTime)
	{
		if(bReloadWpnlist)
		{
			UTIL_SetWeaponList(id, g_szWpnlistName, 15, floatround(ABILITY_DELAY, floatround_ceil), -1, -1, 2, 1, CSW_KNIFE, 0);
			CURWEAPON(id, 1, CSW_KNIFE, -1);
		}

		AMMOX(id, 15, floatround(flTime - flGameTime, floatround_ceil));
	}
	else 
	{
		UTIL_SetWeaponList(id, g_szWpnlistName, -1, -1, -1, -1, 2, 1, CSW_KNIFE, 0);
		set_member(iWeapon, m_Weapon_iWeaponState, STATE_READY);
	}
}

public ClCmd_Drop(id)
{
	if(!IsSetBit(g_iBitUserClass, id))
		return PLUGIN_CONTINUE;

	new pActiveItem = get_member(id, m_pActiveItem);

	if(is_nullent(pActiveItem) || get_member(pActiveItem, m_iId) != WEAPON_KNIFE)
		return PLUGIN_CONTINUE;

	new iState = get_member(pActiveItem, m_Weapon_iWeaponState);

	if(iState != STATE_READY)
		return PLUGIN_HANDLED;
	
	new iEnt = CreateAbilityEnt(id, pActiveItem);

	if(is_nullent(iEnt))
		return PLUGIN_HANDLED;

	set_member(pActiveItem, m_Weapon_iWeaponState, STATE_THINK);
	set_entvar(pActiveItem, var_ent_ability, iEnt);

	return PLUGIN_HANDLED;
}

stock CreateAbilityEnt(id, pItem)
{
	new iEnt = rg_create_entity("info_target");

	if(is_nullent(iEnt)) return NULLENT;

	new Float:flGameTime = get_gametime();

	set_entvar(iEnt, var_owner, id);
	set_entvar(iEnt, var_nextthink, flGameTime + ABILITY_DURATION);

	rh_emit_sound2(id, 0, CHAN_STREAM, g_szSndAbility);
	set_entvar(id, var_gravity, ABILITY_GRAVITY);
	zp_set_user_mul_knock(id, 0.1);
	zp_set_user_block_velocitymifier(id, 1);
	UTIL_SetRendering(id, 19, ABILITY_COLOR, kRenderNormal, 0.0);
	SCREEN_FADE(id, floatround(ABILITY_DURATION), 0, SF_FADE_IN, floatround(ABILITY_COLOR[0]), floatround(ABILITY_COLOR[1]), floatround(ABILITY_COLOR[2]), 125);

	UTIL_WeaponAnimation(id, ANIM_STAB_MISS);
	set_member(pItem, m_Weapon_flTimeWeaponIdle, ANIM_STAB_MISS_TIME);
	set_member(pItem, m_Weapon_flPrevPrimaryAttack, ANIM_STAB_MISS_TIME);
	set_member(pItem, m_Weapon_flNextSecondaryAttack, ANIM_STAB_MISS_TIME);
	rg_set_animation(id, PLAYER_ATTACK1);

	SetThink(iEnt, "@RG_Think_Ability");

	return iEnt;
}

@RG_Think_Ability(iEnt)
{
	new id = get_entvar(iEnt, var_owner);

	disble_ability(id);
	SCREEN_FADE(id, 1, 0, 0, floatround(ABILITY_COLOR[0]), floatround(ABILITY_COLOR[1]), floatround(ABILITY_COLOR[2]), 125);

	start_delay(id, ABILITY_DELAY);
	rg_remove_ent(iEnt);
}


//Установка таймера
stock start_delay(id, Float:flTime)
{
	new pItem = get_member(id, m_rgpPlayerItems, KNIFE_SLOT);

	if(is_nullent(pItem)) return;

	set_member(pItem, m_Weapon_iWeaponState, STATE_RESTART);
	set_entvar(pItem, var_ltime, get_gametime() + flTime);

	if(pItem == get_member(id, m_pActiveItem))
		chek_user_ability_timer(id, pItem, true)
}

stock disable_class(id)
{
	if(!IsSetBit(g_iBitUserClass, id)) 
		return;
	
	ClearBit(g_iBitUserClass, id);

	//Убираем режим установки ловушки
	new pItem = get_member(id, m_rgpPlayerItems, KNIFE_SLOT);

	if(is_nullent(pItem))
		return;

	switch(get_member(pItem, m_Weapon_iWeaponState))
	{
		case STATE_THINK:
		{
			new iEnt = get_entvar(pItem, var_ent_ability);

			if(!is_nullent(iEnt)) rg_remove_ent(iEnt);

			disble_ability(id);
		}
		case STATE_RESTART:
		{
			UTIL_SetWeaponList(id, "weapon_knife", -1, -1, -1, -1, 2, 1, 29, 0);
		}
	}

	set_member(pItem, m_Weapon_iWeaponState, STATE_NO);
}	

stock disble_ability(id)
{
	set_entvar(id, var_gravity, g_flClassGravity);

	zp_set_user_mul_knock(id, 1.0);
	zp_set_user_block_velocitymifier(id, 0);
	UTIL_SetRendering(id);
}

stock rg_remove_ent(iEnt)
{
	set_entvar(iEnt, var_flags, FL_KILLME);
	set_entvar(iEnt, var_nextthink, get_gametime());
}

stock UTIL_SetWeaponList(iPlayer, const szWeaponName[], iPrimaryAmmoID, iPrimaryAmmoMaxAmount, iSecondaryAmmoID, iSecondaryAmmoMaxAmount, iSlotID, iNumberInSlot, iWeaponID, iFlags)
{
	static iMsg_WeaponList; if(!iMsg_WeaponList) iMsg_WeaponList = get_user_msgid("WeaponList");
	
	message_begin(MSG_ONE, iMsg_WeaponList, _, iPlayer);
	write_string(szWeaponName);
	write_byte(iPrimaryAmmoID);
	write_byte(iPrimaryAmmoMaxAmount);
	write_byte(iSecondaryAmmoID);
	write_byte(iSecondaryAmmoMaxAmount);
	write_byte(iSlotID);
	write_byte(iNumberInSlot);
	write_byte(iWeaponID);
	write_byte(iFlags);
	message_end();
}

stock AMMOX(id, iAmmoId, iAmount)
{
	static iMsg_AmmoX; if(!iMsg_AmmoX) iMsg_AmmoX = get_user_msgid("AmmoX");

	message_begin(MSG_ONE, iMsg_AmmoX, _, id);
	write_byte(iAmmoId);
	write_byte(iAmount);
	message_end();
}

stock CURWEAPON(id, IsActive, iWeaponID, iClipAmmo)
{
	static iMsg_CurWeapon; if(!iMsg_CurWeapon) iMsg_CurWeapon = get_user_msgid("CurWeapon");

	engfunc(EngFunc_MessageBegin, MSG_ONE, iMsg_CurWeapon, {0, 0, 0}, id);
	write_byte(IsActive);
	write_byte(iWeaponID);
	write_byte(iClipAmmo);
	message_end();
}

stock CREATE_DLIGHT(Float:vecOrigin[3], radius, iColor[3], life)
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_DLIGHT);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2]);
	write_byte(radius);
	write_byte(iColor[0]); 
	write_byte(iColor[1]);
	write_byte(iColor[2]);
	write_byte(life);
	write_byte(0);
	message_end();
}

stock UTIL_SetRendering(iPlayer, iFx = 0, const Float:flColor[3] = {255.0, 255.0, 255.0}, iRender = 0, Float: flAmount = 16.0)
{	
	set_entvar(iPlayer, var_renderfx, iFx);
	set_entvar(iPlayer, var_rendercolor, flColor);
	set_entvar(iPlayer, var_rendermode, iRender);
	set_entvar(iPlayer, var_renderamt, flAmount);
}

#define UNIT_SECOND (1<<12)

stock SCREEN_FADE(id, iDuration, iHoldtime, iFadeType, iRed, iGreen, iBlue, iAlpha)
{
	static iMsg_ScreenFade; if(!iMsg_ScreenFade) iMsg_ScreenFade = get_user_msgid("ScreenFade");

	message_begin(MSG_ONE_UNRELIABLE, iMsg_ScreenFade, _, id)
	write_short(UNIT_SECOND*iDuration) // duration
	write_short(UNIT_SECOND*iHoldtime) // hold time
	write_short(iFadeType) // fade type
	write_byte(iRed) // r
	write_byte(iGreen) // g
	write_byte(iBlue) // b
	write_byte(iAlpha) // alpha
	message_end()
}

stock UTIL_WeaponAnimation(pPlayer, iAnimation)
{
	set_entvar(pPlayer, var_weaponanim, iAnimation);
	
	message_begin_f(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, pPlayer)
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}