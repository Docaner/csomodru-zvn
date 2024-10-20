#include <amxmodx>
#include <reapi>
#include <zombieplague>
#include <zp_armor>
#include <zpe_lvl>
#include <zpe_mysql_main>

#define ITEM_NAME "Armor"				// Название
#define ITEM_COST 0						// Цена
#define ITEM_TEAM ZP_TEAM_HUMAN			// Команда

#define ARRMOR_MAX 150.0				// Максимальное количество брони
#define ARRMOR_AMOUNT 50.0 				// Сколько выдавать брони при покупке

//=========Выдача брони привам============

//Админ флаги
new const g_iFlags[] = 
{
	ADMIN_LEVEL_G, 	// AGENT
	ADMIN_LEVEL_D, 	// PREMIUM
	ADMIN_LEVEL_H 	// VIP
}

//Количество
new const Float:g_flArmor[] = 
{
	70.0,
	60.0,
	50.0
}
//=========Выдача брони новичкам=============

new const Float:g_flArmorLVL[] =
{
	50.0,
	40.0,
	30.0,
	20.0,
	10.0
}

//===========================================

new const g_szSoundArrmor[] = "items/tr_kevlar.wav"; // Звук брони

new g_iExtraItem;

new g_iMaxPlayers;

public plugin_precache()
{
	register_plugin("[ZP] EI : Armor", "1.0", "Docaner");
	precache_sound(g_szSoundArrmor);
}

public plugin_init()
{
	RegisterHookChain(RG_CSGameRules_RestartRound, "@RG_RestartRound_Post", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "@RG_PlayerSpawn_Post", true);

	g_iExtraItem = zp_register_extra_item(ITEM_NAME, ITEM_COST, ITEM_TEAM);
	g_iMaxPlayers = get_maxplayers();
}

public plugin_natives()
{
	register_native("zp_set_user_arrmor", "@zp_set_user_armor", 1);
}

public zp_user_humanized_post(id, survivor)
{
	if(survivor) 
	{
		@zp_set_user_armor(id, 0.0);
		return; 
	}

	try_give_armor(id);
}

public zpe_mysql_user_load_post(pPlayer) if(is_user_alive(pPlayer)) try_give_armor(pPlayer);

@RG_RestartRound_Post()
{
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_alive(iPlayer)) 
			continue;

		try_give_armor(iPlayer);
	}
}

@RG_PlayerSpawn_Post(const pPlayer)
{
	if(!is_user_alive(pPlayer)) 
		return;

	try_give_armor(pPlayer);
}


public zp_extra_item_selected(pPlayer, iItem)
{
	if(iItem == g_iExtraItem)
	{
		new iRet = zp_set_user_arrmor(pPlayer, Float:get_entvar(pPlayer, var_armorvalue) + ARRMOR_AMOUNT);

		return iRet == PLUGIN_HANDLED ? ZP_PLUGIN_HANDLED : iRet;
	}

	return PLUGIN_CONTINUE;
}

//native zp_set_user_armor(const pPlayer, Float:flAmount)
@zp_set_user_armor(const pPlayer, Float:flAmount)
{
	if(Float:get_entvar(pPlayer, var_armorvalue) >= ARRMOR_MAX)
		return PLUGIN_HANDLED;

	if(flAmount > ARRMOR_MAX)
		flAmount = ARRMOR_MAX;

	if(flAmount > 0.0)
		rh_emit_sound2(pPlayer, 0, CHAN_ITEM, g_szSoundArrmor);
	
	set_entvar(pPlayer, var_armorvalue, flAmount);

	return PLUGIN_CONTINUE;
}

stock try_give_armor(const pPlayer)
{
	//client_print(pPlayer, print_chat, "Zombie: %d | Survivor: %d", zp_get_user_zombie(pPlayer), zp_get_user_survivor(pPlayer));

	if(zp_get_user_zombie(pPlayer) || zp_get_user_survivor(pPlayer))
		return;

	if(try_give_donate_armor(pPlayer)) 
		return;

	if(try_give_newer_armor(pPlayer))
		client_print_color(pPlayer, pPlayer, "^4[ZP] ^1Вам выдана бонусная ^3броня^1, так как Вы - ^4новичок^1!");
}

stock try_give_newer_armor(const pPlayer)
{
	new iLVL = zpe_get_user_lvl(pPlayer) - 1;

	if(iLVL < 0 || iLVL >= sizeof g_flArmorLVL)
		return false;

	new Float:flAmount = g_flArmorLVL[iLVL];

	if(Float:get_entvar(pPlayer, var_armorvalue) >= flAmount)
		return false;

	set_entvar(pPlayer, var_armorvalue, flAmount);
	return true;
}

//Попытка выдачи брони привилегированым игрокам
//true - броня выдана / false - броня не выдана
stock bool:try_give_donate_armor(const pPlayer)
{
	for(new i, Float:flAmount; i < sizeof g_iFlags; i++)
	{
		if(~get_user_flags(pPlayer) & g_iFlags[i]) continue;

		flAmount = g_flArmor[i]

		if(Float:get_entvar(pPlayer, var_armorvalue) < flAmount)
		{
			set_entvar(pPlayer, var_armorvalue, flAmount);
			return true;
		}

		return false;
	}

	return false
}