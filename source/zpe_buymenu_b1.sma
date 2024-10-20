#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <zombieplague>
#include <reapi>
#include <zp_system>
#include <zpe_lvl>
#include <zpe_key>
#include <zp_buymenu>
#include <api_identifier>

native zp_check_vote();
native zp_get_autorr();

native zp_get_user_claymore(pPlayer);
native zp_get_claymore_extraid();

//Identifier System
#define BACKUP_MONEY_FIELD 	"bm_backup_money" 	// Возврат денег
#define BACKUP_AMMO_FIELD	"bm_backup_ammo"	// Возврат аммо
#define BACKUP_MKEY_FIELD	"bm_backup_mkey"	// Возврат монейкей
#define BACKUP_AKEY_FIELD	"bm_backup_akey"	// Возврат аммокей


#define PREMIUM_FLAG ADMIN_LEVEL_D // PREMIUM-статус
#define VIP_FLAG ADMIN_LEVEL_H // VIP-статус
new const g_szFileSettings[] = "addons/amxmodx/configs/zpe_mode/addon_buymenu.ini"

#define DISK_HOUR_START 	0	//Во сколько часов скидка активируется
#define DISK_HOUR_END 		9	//Во сколько часов скидка закончится
#define DISKOUNT			10 //Процент скидки

#define BLOCK_BUY // Блокировать повторуную покупку первичного и вторичного оружия за раунд

#define STEPSOUND_GRENADEJUMP 1212191626 // Идентификатор гранаты джамп

#define PLAYERS_PER_PAGE 8

#define MsgId_StatusIcon 107
#define MsgId_SayText 76

#define EXTRA_MADNESS 2 // ExtraID madness

#define MAX_CLIENTS 	32

#define linux_diff_player 5

#if !defined zp_get_user_hero
native zp_get_user_hero(iPlayer);
#endif
native zp_get_user_harpy(id);
native zp_get_extraitem_harpy();

native zp_get_extra_jump();
native zp_get_jump_left_sec(id);


//ПНВ
native zp_has_user_vision(id);
native zp_get_extra_item_vision();


//Пила
native zpe_get_user_chainsaw(id);

new g_iDiscount;

new const g_szBuyCommands[][] =
{
	"usp", "glock", "deagle", "p228", "elites",
	"fn57", "m3", "xm1014", "mp5", "tmp", "p90",
	"mac10", "ump45", "ak47", "galil", "famas",
	"sg552", "m4a1", "aug", "scout", "awp", "g3sg1",
	"sg550", "m249", "vest", "vesthelm", "flash",
	"hegren", "sgren", "defuser", "nvgs", "shield",
	"primammo", "secammo", "km45", "9x19mm", "nighthawk",
	"228compact", "fiveseven", "12gauge", "autoshotgun",
	"mp", "c90", "cv47", "defender", "clarion", "krieg552",
	"bullpup", "magnum", "d3au1", "krieg550",
	"buy", "buyequip", "client_buy_open", "cl_rebuy",
	"cl_setrebuy", "cl_autobuy", "cl_setautobuy"
}

new const WeaponIdType:g_wGrenadeType[] =
{
	WEAPON_HEGRENADE,
	WEAPON_FLASHBANG,
	WEAPON_SMOKEGRENADE
}

enum
{
	PISTOLS = 0,
	SHOOTGUNS,
	AUTOMATE,
	RIFLES,
	MACHINES,
	ADDEQUIP,
	ZOMBIE,
	MAXMENUS
}

#if defined BLOCK_BUY
//Блокировка покупки в раунд
#define BLOCK_PRIMARY 		(1<<0) 	//Блокировка покупки основного оружия
#define BLOCK_SECONDARY 	(1<<1)	//Блокировка покупки пистолетов

new g_iUserGunsBlock[33];
#endif

new g_iMaxPlayers;

new g_iMenuPosition[33], g_iUserMenuType[33], g_iIdMenus[2], g_iOnline, g_iMsgID_BuyClose;
new Array:g_aszGunsMenu[MAXMENUS], Array:g_aiGunsItem[MAXMENUS], Array:g_aiGunsMoney[MAXMENUS], Array:g_aiAmmo[MAXMENUS], Array:g_aiLvl[MAXMENUS],
	Array:g_aiGunsLimRound[MAXMENUS], Array:g_atGunsUserLimRound[MAXMENUS], Array:g_aiGunsLimMap[MAXMENUS], Array:g_atGunsUserLimMap[MAXMENUS],
	Array:g_aiGunsOnline[MAXMENUS], Array:g_aiGunsPremium[MAXMENUS], Array:g_aiGunsVip[MAXMENUS], Array:g_aiGunsGrenade[MAXMENUS], Array:g_aiGunsStartR[MAXMENUS], Array:g_aiMax[MAXMENUS],
	Array:g_aiMaxGrnd[MAXMENUS], 

	Array:g_aiArmorLimit[MAXMENUS], Array:g_aiNemRnd[MAXMENUS], Array:g_aiSurvRnd[MAXMENUS],
	Array:g_aiPlagRnd[MAXMENUS], Array:g_aiSurvCount[MAXMENUS], Array:g_aiNemCount[MAXMENUS], Array:g_aiLifeLimit[MAXMENUS], Array:g_amLifeLimit[MAXMENUS], Array:g_aiLastHuman[MAXMENUS], 
	Array:g_aiZombieCount[MAXMENUS], Array:g_aiHero[MAXMENUS], Array:g_aiBlockSeconds[MAXMENUS], Array:g_aflBlockTime[MAXMENUS];

//Main functions
public plugin_init()
{
	register_plugin("[ZP] BuyMenu (OldMenus)", "1.0", "Docaner / by TrueMan :3")

	for(new i; i <= charsmax(g_szBuyCommands); i++)
		register_clcmd(g_szBuyCommands[i], "Hook__ClCmd_Buy")

	register_menucmd(g_iIdMenus[0] = register_menuid("Show_BuyMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_BuyMenu")
	register_menucmd(g_iIdMenus[1] = register_menuid("Show_BuyItemMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_BuyItemMenu")

	RegisterHam(Ham_Killed, "player",  "Hook__PlayerKilled_Post", true);

	register_message(MsgId_StatusIcon, "Hook__Msg_StatusIcon")
	register_event("HLTV", "Hook__event_HLTV", "a", "1=0", "2=0")
	
	g_iMsgID_BuyClose = get_user_msgid("BuyClose");
	g_iMaxPlayers = get_maxplayers();
}

public plugin_precache()
{
	set_buyzone_fullsize()
}

public plugin_cfg()
	Load_FileINI()


public plugin_end()
{
	new Trie:tTrie
	for(new i; i < MAXMENUS; i++)
	{
		ArrayDestroy(g_aszGunsMenu[i])
		ArrayDestroy(g_aiGunsItem[i])
		ArrayDestroy(g_aiGunsMoney[i])
		ArrayDestroy(g_aiAmmo[i])
		ArrayDestroy(g_aiLvl[i])
		
		ArrayDestroy(g_aiGunsLimRound[i])

		if(ArraySize(g_atGunsUserLimRound[i]))
		{
			for(new j; j < ArraySize(g_atGunsUserLimRound[i]); j++)
			{
				tTrie = Trie:ArrayGetCell(g_atGunsUserLimRound[i], j)
				TrieDestroy(tTrie)
			}
		}
		ArrayDestroy(g_atGunsUserLimRound[i])

		ArrayDestroy(g_aiGunsLimMap[i])

		if(ArraySize(g_atGunsUserLimMap[i]))
		{
			for(new j; j < ArraySize(g_atGunsUserLimMap[i]); j++)
			{
				tTrie = Trie:ArrayGetCell(g_atGunsUserLimMap[i], j)
				TrieDestroy(tTrie)
			}
		}
		ArrayDestroy(g_atGunsUserLimMap[i])

		ArrayDestroy(g_aiGunsOnline[i])
		ArrayDestroy(g_aiGunsPremium[i])
		ArrayDestroy(g_aiGunsVip[i])
		ArrayDestroy(g_aiGunsGrenade[i])
		ArrayDestroy(g_aiGunsStartR[i])
		ArrayDestroy(g_aiMax[i])
		ArrayDestroy(g_aiMaxGrnd[i])

		ArrayDestroy(g_aiArmorLimit[i])

		ArrayDestroy(g_aiNemRnd[i])
		ArrayDestroy(g_aiSurvRnd[i])
		ArrayDestroy(g_aiPlagRnd[i])
		ArrayDestroy(g_aiSurvCount[i])
		ArrayDestroy(g_aiNemCount[i])

		ArrayDestroy(g_aiLifeLimit[i])
		ArrayDestroy(g_amLifeLimit[i])
		
		ArrayDestroy(g_aiLastHuman[i])
		ArrayDestroy(g_aiZombieCount[i])
		ArrayDestroy(g_aiHero[i])
		ArrayDestroy(g_aiBlockSeconds[i])
		ArrayDestroy(g_aflBlockTime[i])
	}
}

public plugin_natives()
{
	register_native("zp_get_user_weapon_block", "@zp_get_user_weapon_block", 1);
	register_native("zp_set_user_weapon_block", "@zp_set_user_weapon_block", 1);
}

#if defined BLOCK_BUY
@zp_get_user_weapon_block(id) return g_iUserGunsBlock[id];
@zp_set_user_weapon_block(id, iValue) g_iUserGunsBlock[id] = iValue;
#else
@zp_get_user_weapon_block(id) return 0;
@zp_set_user_weapon_block(id, iValue) return;
#endif

public client_putinserver(id)
	if(!is_user_bot(id)) g_iOnline++

public client_disconnected(id)
{
	new j, iUserLifeLimit[33];
	for(new i; i < MAXMENUS; i++)
	{
		if(ArraySize(g_aszGunsMenu[i]))
		{
			for(j = 0; j < ArraySize(g_aszGunsMenu[i]); j++)
			{
				ArrayGetArray(g_amLifeLimit[i], j, iUserLifeLimit, charsmax(iUserLifeLimit));

				if(iUserLifeLimit[id])
				{
					iUserLifeLimit[id] = 0;
					ArraySetArray(g_amLifeLimit[i], j, iUserLifeLimit, charsmax(iUserLifeLimit));
				}
			}
		}
	}

	if(is_user_connected(id) && !is_user_bot(id)) g_iOnline--
	#if defined BLOCK_BUY
	g_iUserGunsBlock[id] = 0;
	#endif
}


//Mod Functions
public zp_user_infected_pre(id)
{
	new iIdMenu, iKeys
	get_user_menu(id, iIdMenu, iKeys)
	for(new i; i <= charsmax(g_iIdMenus); i++)
		if(g_iIdMenus[i] == iIdMenu)
			show_menu(id, 0, "^n")
}

public zp_user_infected_post(id, infector, nemesis)
{
	new j, iUserLifeLimit[33];
	for(new i; i < MAXMENUS; i++)
	{
		if(ArraySize(g_aszGunsMenu[i]))
		{
			for(j = 0; j < ArraySize(g_aszGunsMenu[i]); j++)
			{
				ArrayGetArray(g_amLifeLimit[i], j, iUserLifeLimit, charsmax(iUserLifeLimit));

				if(iUserLifeLimit[id])
				{
					iUserLifeLimit[id] = 0;
					ArraySetArray(g_amLifeLimit[i], j, iUserLifeLimit, charsmax(iUserLifeLimit));
				}
			}
		}
	}
	#if defined BLOCK_BUY
	g_iUserGunsBlock[id] = 0;
	#endif
}

public zp_user_humanized_post(id, survivor)
{
	new j, iUserLifeLimit[33];
	for(new i; i < MAXMENUS; i++)
	{
		if(ArraySize(g_aszGunsMenu[i]))
		{
			for(j = 0; j < ArraySize(g_aszGunsMenu[i]); j++)
			{
				ArrayGetArray(g_amLifeLimit[i], j, iUserLifeLimit, charsmax(iUserLifeLimit));

				if(iUserLifeLimit[id])
				{
					iUserLifeLimit[id] = 0;
					ArraySetArray(g_amLifeLimit[i], j, iUserLifeLimit, charsmax(iUserLifeLimit));
				}
			}
		}
	}
}

//Engine functions
public Hook__ClCmd_Buy(id)
{
	message_begin(	MSG_ONE, g_iMsgID_BuyClose, _, id )
	message_end()
	
	if(zp_get_user_nemesis(id) || zp_get_user_survivor(id))
		return PLUGIN_HANDLED
	
	if(zp_check_vote())
	{
		UTIL_SayText(id, "!g[BuyMenu] !yНевозможно открыть во время !gГолосования за карту!y!")
		return PLUGIN_HANDLED
	}
		
	if(zp_get_autorr())
	{
		UTIL_SayText(id, "!g[BuyMenu] !yНевозможно открыть во время !gАвто-рестарта!y!")
		return PLUGIN_HANDLED
	}
	
	if(zp_is_round_end())
	{
		UTIL_SayText(id, "!g[BuyMenu] !yНевозможно открыть когда !gРаунд закончился!y!")
		return PLUGIN_HANDLED
	}
	
	new iHour, iMin; time(iHour, iMin)

	if(is_valid_hour(iHour, DISK_HOUR_START, DISK_HOUR_END))
		g_iDiscount = DISKOUNT;
	else
		g_iDiscount = 0

	if(zp_has_round_started())
	{
		if(zp_get_user_zombie(id))
			g_iUserMenuType[id] = ZOMBIE;
		else
			return Show_BuyMenu(id);
	}
	else 
		return Show_BuyMenu(id);

	return CMD_BuyItemMenu(id);
}

public Hook__PlayerKilled_Post(iVictim)
{
	new j, iUserLifeLimit[33];
	for(new i; i < MAXMENUS; i++)
	{
		if(ArraySize(g_aszGunsMenu[i]))
		{
			for(j = 0; j < ArraySize(g_aszGunsMenu[i]); j++)
			{
				ArrayGetArray(g_amLifeLimit[i], j, iUserLifeLimit, charsmax(iUserLifeLimit));

				if(iUserLifeLimit[iVictim])
				{
					iUserLifeLimit[iVictim] = 0;
					ArraySetArray(g_amLifeLimit[i], j, iUserLifeLimit, charsmax(iUserLifeLimit));
				}
			}
		}
	}
}

public Hook__Msg_StatusIcon(id)
{
	if(get_msg_args() != 5) 
		return
	new szSpriteName[10]
	get_msg_arg_string(2, szSpriteName, charsmax(szSpriteName))
	if(equal(szSpriteName, "buyzone"))
	{
		set_msg_arg_int(3, ARG_BYTE, 0)
		set_msg_arg_int(4, ARG_BYTE, 0)
		set_msg_arg_int(5, ARG_BYTE, 0)
	}
}

public Hook__event_HLTV()
{
	new Trie:tLimitRound, j, iUserLifeLimit[33];
	for(new i; i < MAXMENUS; i++)
	{
		if(ArraySize(g_aszGunsMenu[i]))
		{
			for(j = 0; j < ArraySize(g_aszGunsMenu[i]); j++)
			{
				tLimitRound = Trie:ArrayGetCell(g_atGunsUserLimRound[i], j)
				TrieClear(tLimitRound)

				ArraySetArray(g_amLifeLimit[i], j, iUserLifeLimit, charsmax(iUserLifeLimit));
			}
		}
	}
	
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		#if defined BLOCK_BUY
		g_iUserGunsBlock[iPlayer] = 0;
		#endif
	}

	for(new i, iSize = get_identifiers_size(); i < iSize; i++)
	{
		set_arrayindex_property(i, BACKUP_MONEY_FIELD, 0);
		set_arrayindex_property(i, BACKUP_MKEY_FIELD, 0);
		set_arrayindex_property(i, BACKUP_AMMO_FIELD, 0);
		set_arrayindex_property(i, BACKUP_AKEY_FIELD, 0);
	}
}

public zp_round_started(iGameMode, iEntity)
{
	new iMoney, iMKey, iAmmo, iAKey
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(is_user_alive(iPlayer))
		{
			if(zp_get_user_zombie(iPlayer) || zp_get_user_survivor(iPlayer) || zp_get_user_hero(iPlayer))
			{
				if( (iMoney = get_user_property(iPlayer, BACKUP_MONEY_FIELD)) )
				{

					if( (iMKey = get_user_property(iPlayer, BACKUP_MKEY_FIELD)) )
					{
						UTIL_SayText(iPlayer, "!g[BuyMenu] !yВам возвращено: !g%d$ !yи !g%d MKEY", iMoney, iMKey)
						zpe_set_user_moneykey_wohud(iPlayer, zpe_get_user_moneykey(iPlayer) + iMKey)
					}
					else
						UTIL_SayText(iPlayer, "!g[BuyMenu] !yВам возвращено: !g%d$", iMoney)
					
					zp_set_user_money(iPlayer, zp_get_user_money(iPlayer) + iMoney);
					
					set_user_property(iPlayer, BACKUP_MONEY_FIELD, 0)
					set_user_property(iPlayer, BACKUP_MKEY_FIELD, 0)
				}
				
				if( (iAmmo = get_user_property(iPlayer, BACKUP_AMMO_FIELD)) )
				{
					if( (iAKey = get_user_property(iPlayer, BACKUP_AKEY_FIELD)) )
					{
						UTIL_SayText(iPlayer, "!g[BuyMenu] !yВам возвращено: !g%d Ammo !yи !g%d AKEY", iAmmo, iAKey)
						zpe_set_user_ammokey_wohud(iPlayer, zpe_get_user_ammokey(iPlayer) + iAKey)
					}
					else
						UTIL_SayText(iPlayer, "!g[BuyMenu] !yВам возвращено: !g%d Ammo", iAmmo)
					
					zp_set_user_ammo(iPlayer, zp_get_user_ammo(iPlayer) + iAmmo);
										
					set_user_property(iPlayer, BACKUP_AMMO_FIELD, 0)
					set_user_property(iPlayer, BACKUP_AKEY_FIELD, 0)
				}
			}
		}
	}
	return PLUGIN_CONTINUE
}

//Menus
Show_BuyMenu(id)
{
	new szMenu[512], iLen, iKeys = (1<<5|1<<8|1<<9);

	new iHour, iMin; time(iHour, iMin)

	iLen = formatex(szMenu, charsmax(szMenu), 
			"\r[CSO] \wМагазин^n\
			Скидки: \r%d%% \w| \r%02d:00 \w- \r%02d:59 \w(по МСК)^n\
			Ваша скидка: \r%d%% \w| Сейчас: \r%02d:%02d^n\
			\wMoneyKey: \r%d/%d \w| AmmoKey: \r%d/%d^n^n", 
			DISKOUNT, DISK_HOUR_START, DISK_HOUR_END, g_iDiscount, iHour, iMin, 
			zpe_get_user_moneykey(id), zpe_get_max_moneykey(id), zpe_get_user_ammokey(id), zpe_get_max_ammokey(id));

	if(zp_get_user_hero(id))
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \dПистолеты^n")
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \dДробовики^n")
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \dАвтоматы^n")
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \dВинтовки^n")
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5. \dПулемёты^n^n")
	}
	else
	{
		#if defined BLOCK_BUY
		if(~g_iUserGunsBlock[id] & BLOCK_SECONDARY)
		#endif
		{
			iKeys |= (1<<0);		
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \wПистолеты^n");
		}
		#if defined BLOCK_BUY
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \dПистолеты^n");

		if(~g_iUserGunsBlock[id] & BLOCK_PRIMARY)
		#endif
		{
			iKeys |= (1<<1|1<<2|1<<3|1<<4);
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \wДробовики^n")
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \wАвтоматы^n")
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \wВинтовки^n")
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5. \wПулемёты^n^n")
		}
		#if defined BLOCK_BUY
		else
		{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \dДробовики^n")
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \dАвтоматы^n")
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \dВинтовки^n")
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5. \dПулемёты^n^n")
		}
		#endif
	}
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6. \wОбмундирование^n^n")
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9. \wВыбрать нож^n")
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0. \wВыход")
	return show_menu(id, iKeys, szMenu, -1, "Show_BuyMenu")
}

public Handle_BuyMenu(id, iKey)
{		
	if(0 <= iKey <= 5)
	{
		g_iUserMenuType[id] = iKey
		return CMD_BuyItemMenu(id)
	}
	switch(iKey)
	{
		case 8: 
		{
			client_cmd(id, "zpe_knifemenu")
			return PLUGIN_HANDLED
		}
		
		case 9: return PLUGIN_HANDLED
	}
	return Show_BuyMenu(id)
}

CMD_BuyItemMenu(id) return Show_BuyItemMenu(id, g_iMenuPosition[id] = 0)
Show_BuyItemMenu(id, iPos)
{
	if(iPos < 0) 
		return PLUGIN_HANDLED

	new iArraySize = ArraySize(g_aiGunsItem[g_iUserMenuType[id]])
	if(!iArraySize)
		return PLUGIN_HANDLED

	new iStart = iPos * PLAYERS_PER_PAGE
	if(iStart > iArraySize) iStart = iArraySize

	iStart = iStart - (iStart % PLAYERS_PER_PAGE)
	//g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE

	new iEnd = iStart + PLAYERS_PER_PAGE
	if(iEnd > iArraySize) iEnd = iArraySize

	new szMenu[512], iLen, szType[64],
	iPagesNum = iArraySize / PLAYERS_PER_PAGE + ((iArraySize % PLAYERS_PER_PAGE) ? 1 : 0)

	switch(g_iUserMenuType[id])
	{
		case PISTOLS: szType = "Пистолеты"
		case SHOOTGUNS: szType = "Дробовики"
		case AUTOMATE: szType = "Автоматы"
		case RIFLES: szType = "Винтовки"
		case MACHINES: szType = "Пулемёты"
		case ADDEQUIP: szType = "Снаряжение"
		case ZOMBIE: szType = "Зомби"
	}
	iLen = formatex(szMenu, charsmax(szMenu), "\y%s \w[%d|%d]^n\wMKey: \r%d/%d \w| AKey: \r%d/%d^n^n", szType, iPos + 1, iPagesNum,zpe_get_user_moneykey(id), zpe_get_max_moneykey(id), zpe_get_user_ammokey(id), zpe_get_max_ammokey(id))
	new iKeys = (1<<9), b, szNameMenu[64], bool:bAccess, iMoney, iAmmo, iLvl, szBlock[32], 
		szSteamId[32], iOnline, iPremium, iVip, iGrenade, iRoundStart, iMax,
		Trie:tLimitRound, iUserLimitRound, iLimitRound,
		Trie:tLimitMap, iUserLimitMap, iLimitMap, iMaxGrnd, iCountGrnd, iEnt,
		iArmorLimit, iNemRnd, iSurvRnd, iPlagRnd, iSurvCont, iNemCont, iLifeLimit, iUserLifeLimit[33], 
		iLastHuman, iZombieCount, iHero, iExtraItem, iTime, iMoneyKey = zpe_get_user_moneykey(id), iAmmoKey = zpe_get_user_ammokey(id), 
		iBlockSeconds, Float:flBlockTime, Float:flGameTime = get_gametime(), szTime[16];
	
	new Float:flNewCost;
	if(g_iDiscount)
		flNewCost = (100.0 - float(g_iDiscount)) / 100.0;

	get_user_authid(id, szSteamId, charsmax(szSteamId))
	for(new a = iStart; a < iEnd; a++)
	{
		ArrayGetString(g_aszGunsMenu[g_iUserMenuType[id]], a, szNameMenu, charsmax(szNameMenu))
		iMoney = ArrayGetCell(g_aiGunsMoney[g_iUserMenuType[id]], a)
		iAmmo = ArrayGetCell(g_aiAmmo[g_iUserMenuType[id]], a)
		iLvl = ArrayGetCell(g_aiLvl[g_iUserMenuType[id]], a)
		iOnline = ArrayGetCell(g_aiGunsOnline[g_iUserMenuType[id]], a)
		iPremium = ArrayGetCell(g_aiGunsPremium[g_iUserMenuType[id]], a)
		iVip = ArrayGetCell(g_aiGunsVip[g_iUserMenuType[id]], a)
		iGrenade = ArrayGetCell(g_aiGunsGrenade[g_iUserMenuType[id]], a)
		iRoundStart = ArrayGetCell(g_aiGunsStartR[g_iUserMenuType[id]], a)
		iLimitRound = ArrayGetCell(g_aiGunsLimRound[g_iUserMenuType[id]], a)
		iMax = ArrayGetCell(g_aiMax[g_iUserMenuType[id]], a)
		iMaxGrnd = ArrayGetCell(g_aiMaxGrnd[g_iUserMenuType[id]], a)
		iExtraItem = ArrayGetCell(g_aiGunsItem[g_iUserMenuType[id]], a);
		iArmorLimit = ArrayGetCell(g_aiArmorLimit[g_iUserMenuType[id]], a)
		iNemRnd = ArrayGetCell(g_aiNemRnd[g_iUserMenuType[id]], a)
		iSurvRnd = ArrayGetCell(g_aiSurvRnd[g_iUserMenuType[id]], a)
		iPlagRnd = ArrayGetCell(g_aiPlagRnd[g_iUserMenuType[id]], a)
		iSurvCont = ArrayGetCell(g_aiSurvCount[g_iUserMenuType[id]], a)
		iNemCont = ArrayGetCell(g_aiNemCount[g_iUserMenuType[id]], a)
		iLifeLimit = ArrayGetCell(g_aiLifeLimit[g_iUserMenuType[id]], a)
		iLastHuman = ArrayGetCell(g_aiLastHuman[g_iUserMenuType[id]], a)
		iZombieCount = ArrayGetCell(g_aiZombieCount[g_iUserMenuType[id]], a)
		iHero = ArrayGetCell(g_aiHero[g_iUserMenuType[id]], a)
		iBlockSeconds = ArrayGetCell(g_aiBlockSeconds[g_iUserMenuType[id]], a)
		flBlockTime = Float:ArrayGetCell(g_aflBlockTime[g_iUserMenuType[id]], a)

		if(flNewCost != 0.0)
		{
			if(iMoney) iMoney = floatround(float(iMoney) * flNewCost);
			if(iAmmo) iAmmo = floatround(float(iAmmo) * flNewCost);
		}

		if(iLimitRound)
		{
			tLimitRound = Trie:ArrayGetCell(g_atGunsUserLimRound[g_iUserMenuType[id]], a)
			if(TrieKeyExists(tLimitRound, szSteamId))
				TrieGetCell(tLimitRound, szSteamId, iUserLimitRound)
			else
				iUserLimitRound = 0
		}

		iLimitMap = ArrayGetCell(g_aiGunsLimMap[g_iUserMenuType[id]], a)
		if(iLimitMap)
		{
			tLimitMap = Trie:ArrayGetCell(g_atGunsUserLimMap[g_iUserMenuType[id]], a)
			if(TrieKeyExists(tLimitMap, szSteamId))
				TrieGetCell(tLimitMap, szSteamId, iUserLimitMap)
			else
				iUserLimitMap = 0
		}

		if(iLifeLimit)
			ArrayGetArray(g_amLifeLimit[g_iUserMenuType[id]], a, iUserLifeLimit, charsmax(iUserLifeLimit));

		if(iMaxGrnd)
		{
			iCountGrnd = 0;
			if(user_has_weapon(id, cell:g_wGrenadeType[iGrenade - 1]))
				iCountGrnd = fm_get_user_bpammo(id, cell:g_wGrenadeType[iGrenade - 1])

			iEnt = NULLENT;
			while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "grenade")) > 0)
			{
				if(get_entvar(iEnt, var_owner) != id || GetGrenadeType(iEnt) != g_wGrenadeType[iGrenade - 1])
					continue;
				
				iCountGrnd++;
			}
		}

		if(iExtraItem == zp_get_extra_jump())
			iTime = zp_get_jump_left_sec(id);

		if(iPremium && ~get_user_flags(id) & PREMIUM_FLAG)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(PREMIUM)")
		}
		else if(iVip && ~get_user_flags(id) & VIP_FLAG)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(VIP)")
		}
		else if(iRoundStart && !zp_has_round_started())
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Not Started)")
		}
		else if(iLimitRound && iLimitRound <= iUserLimitRound)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Max Round: %d)", iLimitRound)
		}
		else if(iLimitMap && iLimitMap <= iUserLimitMap)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Max Map: %d)", iLimitMap)
		}
		else if(iOnline && iOnline > g_iOnline)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Online: %d)", iOnline)
		}
		else if(iGrenade && iMax && fm_get_user_bpammo(id, cell:g_wGrenadeType[iGrenade - 1]) >= iMax)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Max: %d)", iMax);
		}
		else if(iGrenade && iMaxGrnd && iCountGrnd >= iMaxGrnd)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Max: %d)", iMaxGrnd);
		}
		else if(iArmorLimit && get_user_armor(id) >= iArmorLimit)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Max Armor: %d)", iArmorLimit);
		}
		else if(iNemRnd && zp_is_nemesis_round())
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Round: Nemesis)");
		}
		else if(iSurvRnd && zp_is_survivor_round())
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Round: Survivor)");
		}
		else if(iPlagRnd && zp_is_plague_round())
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Round: Plague)");
		}
		else if(iSurvCont && zp_get_survivor_count() >= iSurvCont)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Max Survivor: %d)", iSurvCont);
		}
		else if(iNemCont && zp_get_nemesis_count() >= iNemCont)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Max Boss: %d)", iNemCont);
		}
		else if(iLifeLimit && iUserLifeLimit[id] >= iLifeLimit)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Max: %d)", iLifeLimit);
		}
		else if(iLastHuman && zp_get_human_count() <= iLastHuman)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Last Human)");
		}
		else if(iZombieCount && zp_get_zombie_count() <= iZombieCount)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Few Zombies)");
		}
		else if(iHero && zp_get_user_hero(id))
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(You are hero)");
		}
		else if(iBlockSeconds && flBlockTime > flGameTime)
		{
			bAccess = false
			clock_format(flGameTime, flBlockTime, szTime, charsmax(szTime));
			formatex(szBlock, charsmax(szBlock), " \r(Delay %s)", szTime)
		}
		else if(iExtraItem == zp_get_extraitem_harpy() && zp_get_user_harpy(id))
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Already have)");
		}
		else if(iExtraItem == zp_get_claymore_extraid() && zp_get_user_claymore(id))
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Already have)");
		}
		else if(iExtraItem == zp_get_extra_item_vision() && zp_has_user_vision(id))
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Already have)");
		}
		else if(iExtraItem == zp_get_extra_jump() && iTime > 0)
		{
			bAccess = false
			formatex(szBlock, charsmax(szBlock), " \r(Delay: %ds)", iTime);
		}
		else if(iMoney)
		{
			if(iMoney > zp_get_user_money(id))
			{
				bAccess = false
				
				if(iPremium && get_user_flags(id) & PREMIUM_FLAG)
					formatex(szBlock, charsmax(szBlock), " \r($: %d) (PREMIUM)", iMoney)	
				else if(iVip && get_user_flags(id) & VIP_FLAG)
					formatex(szBlock, charsmax(szBlock), " \r($: %d) (VIP)", iMoney)
				else if(iLvl && iLvl > zpe_get_user_lvl(id))
				{
					if(iMoneyKey)
						formatex(szBlock, charsmax(szBlock), " \r($: %d | MKEY)", iMoney);
					else
						formatex(szBlock, charsmax(szBlock), " \r(LVL: %d)", iLvl);
				}
				else
					formatex(szBlock, charsmax(szBlock), " \r($: %d)", iMoney)
			}
			else
			{
				bAccess = true
				
				if(iPremium && get_user_flags(id) & PREMIUM_FLAG)
					formatex(szBlock, charsmax(szBlock), " \y($: %d) \r(PREMIUM)", iMoney)	
				else if(iVip && get_user_flags(id) & VIP_FLAG)
					formatex(szBlock, charsmax(szBlock), " \y($: %d) \r(VIP)", iMoney)
				else if(iLvl && iLvl > zpe_get_user_lvl(id))
				{
					if(iMoneyKey)
						formatex(szBlock, charsmax(szBlock), " \y($: %d | \wMKEY\y)", iMoney);
					else
					{
						bAccess = false
						formatex(szBlock, charsmax(szBlock), " \r(LVL: %d)", iLvl);
					}
				}
				else
					formatex(szBlock, charsmax(szBlock), " \y($: %d)", iMoney)
			}
		}
		else if(iAmmo)
		{
			
			if(iAmmo > zp_get_user_ammo(id))
			{
				bAccess = false
				
				if(iPremium && get_user_flags(id) & PREMIUM_FLAG)
					formatex(szBlock, charsmax(szBlock), " \r(Ammo: %d) (PREMIUM)", iAmmo)
				else if(iVip && get_user_flags(id) & VIP_FLAG)
					formatex(szBlock, charsmax(szBlock), " \r(Ammo: %d) (VIP)", iAmmo)
				else if(iLvl && iLvl > zpe_get_user_lvl(id))
				{
					if(iAmmoKey)
						formatex(szBlock, charsmax(szBlock), " \r(Ammo: %d | AKEY)", iAmmo);
					else
						formatex(szBlock, charsmax(szBlock), " \r(LVL: %d)", iLvl);
				}
				else
					formatex(szBlock, charsmax(szBlock), " \r(Ammo: %d)", iAmmo)
			}
			else
			{
				bAccess = true
				
				if(iPremium && get_user_flags(id) & PREMIUM_FLAG)
					formatex(szBlock, charsmax(szBlock), " \y(Ammo: %d) \r(PREMIUM)", iAmmo)
				else if(iVip && get_user_flags(id) & VIP_FLAG)
					formatex(szBlock, charsmax(szBlock), " \y(Ammo: %d) \r(VIP)", iAmmo)
				else if(iLvl && iLvl > zpe_get_user_lvl(id))
				{
					if(iAmmoKey)
						formatex(szBlock, charsmax(szBlock), " \y(Ammo: %d | \wAKEY\y)", iAmmo);
					else
					{
						bAccess = false
						formatex(szBlock, charsmax(szBlock), " \r(LVL: %d)", iLvl);
					}
				}
				else
					formatex(szBlock, charsmax(szBlock), " \y(Ammo: %d)", iAmmo)
			}
		}
		else
		{
			bAccess = true
			szBlock = ""
		}

		iKeys |= (1<<b)
		++b

		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. %s%s%s^n", b, bAccess ? "\w" : "\d", szNameMenu, szBlock)
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n")
	if(iEnd < iArraySize)
	{
		iKeys |= (1<<8)
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r9. \wДалее^n\r0. \w%s", iPos ? "Назад" : "Выход")
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r0. \w%s", iPos ? "Назад" : "Выход")

	return show_menu(id, iKeys, szMenu, -1, "Show_BuyItemMenu")
}

public Handle_BuyItemMenu(id, iKey)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;

	if(zp_has_round_started())
	{
		if(zp_get_user_zombie(id))
		{
			if(zp_get_user_nemesis(id) || g_iUserMenuType[id] != ZOMBIE)
				return PLUGIN_HANDLED;
		}
		else
		{
			if(zp_get_user_hero(id) && g_iUserMenuType[id] != ADDEQUIP || zp_get_user_survivor(id) || g_iUserMenuType[id] == ZOMBIE)
				return PLUGIN_HANDLED;
		}
	}
	else if(g_iUserMenuType[id] == ZOMBIE) 
		return PLUGIN_HANDLED;
	
	#if defined BLOCK_BUY
	if((g_iUserGunsBlock[id] & BLOCK_PRIMARY) && SHOOTGUNS <= g_iUserMenuType[id] <= MACHINES)
		return PLUGIN_HANDLED;

	if((g_iUserGunsBlock[id] & BLOCK_SECONDARY) && g_iUserMenuType[id] == PISTOLS)
		return PLUGIN_HANDLED;
	#endif

	switch(iKey)
	{
		case 8: return Show_BuyItemMenu(id, ++g_iMenuPosition[id])
		case 9: return Show_BuyItemMenu(id, --g_iMenuPosition[id])
		default:
		{
			iKey = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey
			zp_buy_item(id, iKey, g_iUserMenuType[id])
		}
	}
	return PLUGIN_HANDLED
}

stock clock_format(Float:flGameTime, Float:flTimeEnd, szOutLine[], iLen)
{
	new iTimeLost = floatround(flTimeEnd - flGameTime, floatround_ceil);
	new iMinutes = iTimeLost / 60;
	new iSeconds = iTimeLost - iMinutes * 60;
	formatex(szOutLine, iLen, "%02d:%02d", iMinutes, iSeconds);
}

//Add functions
set_buyzone_fullsize()
{
	new iEntity = engfunc( EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"))
	dllfunc(DLLFunc_Spawn, iEntity)
	engfunc(EngFunc_SetSize, iEntity, Float:{-8192.0, -8192.0, -8192.0}, Float:{8192.0, 8192.0, 8192.0})
	set_pev(iEntity, pev_team, 0)
}

Load_FileINI()
{
	for(new i; i < MAXMENUS; i++)
	{
		g_aszGunsMenu[i] = ArrayCreate(64)
		g_aiGunsItem[i] = ArrayCreate()
		g_aiGunsMoney[i] = ArrayCreate()
		g_aiAmmo[i] = ArrayCreate()
		g_aiLvl[i] = ArrayCreate()

		g_aiGunsLimRound[i] = ArrayCreate()
		g_atGunsUserLimRound[i] = ArrayCreate()

		g_aiGunsLimMap[i] = ArrayCreate()
		g_atGunsUserLimMap[i] = ArrayCreate()

		g_aiGunsOnline[i] = ArrayCreate()
		g_aiGunsPremium[i] = ArrayCreate()
		g_aiGunsVip[i] = ArrayCreate()
		g_aiGunsGrenade[i] = ArrayCreate()
		g_aiGunsStartR[i] = ArrayCreate()
		g_aiMax[i] = ArrayCreate()
		g_aiMaxGrnd[i] = ArrayCreate()

		g_aiArmorLimit[i] = ArrayCreate()
		g_aiNemRnd[i] = ArrayCreate()
		g_aiSurvRnd[i] = ArrayCreate()
		g_aiPlagRnd[i] = ArrayCreate()
		g_aiSurvCount[i] = ArrayCreate()
		g_aiNemCount[i] = ArrayCreate()

		g_aiLifeLimit[i] = ArrayCreate()
		g_amLifeLimit[i] = ArrayCreate(33)
		
		g_aiLastHuman[i] = ArrayCreate()
		g_aiZombieCount[i] = ArrayCreate()
		g_aiHero[i] = ArrayCreate()

		g_aiBlockSeconds[i] = ArrayCreate();
		g_aflBlockTime[i] = ArrayCreate();
	}
	if(file_exists(g_szFileSettings))
	{
		new szBuffer[512], szNameMenu[64], szNameItem[64], szMoney[16], szAmmo[16], szLvl[16],
			szLimRound[16], szLimMap[16], szOnline[4], szPremium[4], szVip[4], szGrenade[4], szRoundStart[4], 
			szMax[4], szMaxGrnd[4], szArmorLimit[4], szNemRnd[4], szSurvRnd[4], szPlagRnd[4], 
			szSurvCount[8], szNemCount[8], szLifeLimit[16], iUserLifeLimit[33], szLastHuman[4], szZombieCount[4], szHero[4], szBlockSeconds[16],
			iLine, iLen, i, iType = -1
		while(read_file(g_szFileSettings, iLine++, szBuffer, charsmax(szBuffer), iLen))
		{
			if(!iLen || szBuffer[0] == ';')
				continue

			if(szBuffer[0] == '[')
			{
				iType++
				continue
			}
			if(PISTOLS > iType || iType >= MAXMENUS)
				break

			parse(szBuffer, szNameMenu, charsmax(szNameMenu), szNameItem, charsmax(szNameItem), szMoney, charsmax(szMoney), 
			 szAmmo, charsmax(szAmmo), szLvl, charsmax(szLvl), szLimRound, charsmax(szLimRound), szLimMap, charsmax(szLimMap), szOnline, charsmax(szOnline),
			 szPremium, charsmax(szPremium), szVip, charsmax(szVip), szGrenade, charsmax(szGrenade), szRoundStart, charsmax(szRoundStart), 
			 szMax, charsmax(szMax), szMaxGrnd, charsmax(szMaxGrnd), szArmorLimit, charsmax(szArmorLimit), szNemRnd, charsmax(szNemRnd), 
			 szSurvRnd, charsmax(szSurvRnd), szPlagRnd, charsmax(szPlagRnd), szSurvCount, charsmax(szSurvCount), szNemCount, charsmax(szNemCount),
			 szLifeLimit, charsmax(szLifeLimit), szLastHuman, charsmax(szLastHuman), szZombieCount, charsmax(szZombieCount), szHero, charsmax(szHero), 
			 szBlockSeconds, charsmax(szBlockSeconds));

			i = zp_get_extra_item_id(szNameItem)

			if(i == -1)
			{
				console_print(0, "[BuyMenu] ExtraItem '%s' not found ", szNameItem)
				continue
			}

			ArrayPushCell(g_aiGunsItem[iType], i)
			ArrayPushString(g_aszGunsMenu[iType], szNameMenu)
			ArrayPushCell(g_aiGunsMoney[iType], str_to_num(szMoney))
			ArrayPushCell(g_aiAmmo[iType], str_to_num(szAmmo))
			ArrayPushCell(g_aiLvl[iType], str_to_num(szLvl))

			ArrayPushCell(g_aiGunsLimRound[iType], str_to_num(szLimRound))
			ArrayPushCell(g_atGunsUserLimRound[iType], cell:TrieCreate())

			ArrayPushCell(g_aiGunsLimMap[iType], str_to_num(szLimMap))
			ArrayPushCell(g_atGunsUserLimMap[iType], cell:TrieCreate())

			ArrayPushCell(g_aiGunsOnline[iType], str_to_num(szOnline))
			ArrayPushCell(g_aiGunsPremium[iType], str_to_num(szPremium))
			ArrayPushCell(g_aiGunsVip[iType], str_to_num(szVip))
			ArrayPushCell(g_aiGunsGrenade[iType], str_to_num(szGrenade))
			ArrayPushCell(g_aiGunsStartR[iType], str_to_num(szRoundStart))
			ArrayPushCell(g_aiMax[iType], str_to_num(szMax))
			ArrayPushCell(g_aiMaxGrnd[iType], str_to_num(szMaxGrnd))

			ArrayPushCell(g_aiArmorLimit[iType], str_to_num(szArmorLimit))

			ArrayPushCell(g_aiNemRnd[iType], str_to_num(szNemRnd))
			ArrayPushCell(g_aiSurvRnd[iType], str_to_num(szSurvRnd))
			ArrayPushCell(g_aiPlagRnd[iType], str_to_num(szPlagRnd))
			ArrayPushCell(g_aiSurvCount[iType], str_to_num(szSurvCount))
			ArrayPushCell(g_aiNemCount[iType], str_to_num(szNemCount))

			ArrayPushCell(g_aiLifeLimit[iType], str_to_num(szLifeLimit))
			ArrayPushArray(g_amLifeLimit[iType], iUserLifeLimit, charsmax(iUserLifeLimit))
			
			ArrayPushCell(g_aiLastHuman[iType], str_to_num(szLastHuman))
			ArrayPushCell(g_aiZombieCount[iType], str_to_num(szZombieCount))
			ArrayPushCell(g_aiHero[iType], str_to_num(szHero))

			ArrayPushCell(g_aiBlockSeconds[iType], str_to_num(szBlockSeconds))
			ArrayPushCell(g_aflBlockTime[iType], 0.0);
		}
		return 1
	}
	return 0
}

zp_buy_item(id, iItem, iType)
{
	new szNameMenu[64], 
		iMoney = ArrayGetCell(g_aiGunsMoney[iType], iItem),
		iAmmo = ArrayGetCell(g_aiAmmo[iType], iItem),
		iPremium = ArrayGetCell(g_aiGunsPremium[iType], iItem),
		iVip = ArrayGetCell(g_aiGunsVip[iType], iItem);


	new Float:flNewCost; if(g_iDiscount) flNewCost = (100.0 - float(g_iDiscount)) / 100.0;
	if(flNewCost != 0.0)
	{
		if(iMoney) iMoney = floatround(float(iMoney) * flNewCost);
		if(iAmmo) iAmmo = floatround(float(iAmmo) * flNewCost);
	}

	ArrayGetString(g_aszGunsMenu[iType], iItem, szNameMenu, charsmax(szNameMenu))
	
	if(zp_get_autorr())
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Авто-рестарт!", szNameMenu)
		return PLUGIN_HANDLED
	}
	
	if(zp_check_vote())
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Голосование за карту!", szNameMenu)
		return PLUGIN_HANDLED
	}
	
	if(zp_is_round_end())
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Раунд завершён!", szNameMenu)
		return PLUGIN_HANDLED
	}

	if(iPremium && ~get_user_flags(id) & PREMIUM_FLAG)
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Не куплен PREMIUM-статус!", szNameMenu)
		return PLUGIN_HANDLED
	}
	
	if(iVip && ~get_user_flags(id) & VIP_FLAG)
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Не куплен VIP-статус!", szNameMenu)
		return PLUGIN_HANDLED
	}

	new iRoundStart = ArrayGetCell(g_aiGunsStartR[iType], iItem)
	if(iRoundStart && !zp_has_round_started())
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Мод не начался!", szNameMenu)
		return PLUGIN_HANDLED
	}

	new iLimitRound = ArrayGetCell(g_aiGunsLimRound[iType], iItem), Trie:tLimitRound, 
		iUserLimitRound, szSteamId[32]
	if(iLimitRound)
	{
		get_user_authid(id, szSteamId, charsmax(szSteamId))

		tLimitRound = Trie:ArrayGetCell(g_atGunsUserLimRound[iType], iItem)

		if(TrieKeyExists(tLimitRound, szSteamId))
			TrieGetCell(tLimitRound, szSteamId, iUserLimitRound)

		if(iLimitRound <= iUserLimitRound)
		{
			UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Достигнут лимит за раунд!", szNameMenu)
			return PLUGIN_HANDLED
		}
	}

	new iLimitMap = ArrayGetCell(g_aiGunsLimMap[iType], iItem), Trie:tLimitMap, 
		iUserLimitMap
	if(iLimitMap)
	{
		get_user_authid(id, szSteamId, charsmax(szSteamId))

		tLimitMap = Trie:ArrayGetCell(g_atGunsUserLimMap[iType], iItem)

		if(TrieKeyExists(tLimitMap, szSteamId))
			TrieGetCell(tLimitMap, szSteamId, iUserLimitMap)

		if(iLimitMap <= iUserLimitMap)
		{
			UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Достигнут лимит за карту!", szNameMenu)
			return PLUGIN_HANDLED
		}
	}

	new iOnline = ArrayGetCell(g_aiGunsOnline[iType], iItem)
	if(iOnline && iOnline > g_iOnline)
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Необходимый онлайн %d!", szNameMenu, iOnline)
		return PLUGIN_HANDLED
	}


	new iGrenade = ArrayGetCell(g_aiGunsGrenade[iType], iItem),
		iMax = ArrayGetCell(g_aiMax[iType], iItem)

	if(iGrenade && iMax && fm_get_user_bpammo(id, cell:g_wGrenadeType[iGrenade - 1]) >= iMax)
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Максимально можно иметь %d гранаты!", szNameMenu, iMax)
		return PLUGIN_HANDLED
	}

	new iMaxGrnd = ArrayGetCell(g_aiMaxGrnd[iType], iItem);

	if(iGrenade && iMaxGrnd)
	{
		new iCountGrnd = 0;
		if(user_has_weapon(id, cell:g_wGrenadeType[iGrenade - 1]))
			iCountGrnd = fm_get_user_bpammo(id, cell:g_wGrenadeType[iGrenade - 1])


		new iEnt = NULLENT;
		while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "grenade")) > 0)
		{
			if(get_entvar(iEnt, var_owner) != id || GetGrenadeType(iEnt) != g_wGrenadeType[iGrenade - 1])
				continue;
			
			iCountGrnd++;
		}

		if(iCountGrnd >= iMaxGrnd)
		{
			UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Куплено максимальное кол-во гранат!", szNameMenu, iOnline)
			return PLUGIN_HANDLED
		}
	}

	new iArmorLimit = ArrayGetCell(g_aiArmorLimit[iType], iItem);
	if(iArmorLimit && get_user_armor(id) >= iArmorLimit)
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: У вас максимум брони!", szNameMenu)
		return PLUGIN_HANDLED
	}

	new iNemRnd = ArrayGetCell(g_aiNemRnd[iType], iItem);
	if(iNemRnd && zp_is_nemesis_round())
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Раунд - Немезис!", szNameMenu)
		return PLUGIN_HANDLED
	}

	new iSurvRnd = ArrayGetCell(g_aiSurvRnd[iType], iItem);
	if(iSurvRnd && zp_is_survivor_round())
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Раунд - Выживший!", szNameMenu)
		return PLUGIN_HANDLED
	}

	new iPlagRnd = ArrayGetCell(g_aiPlagRnd[iType], iItem);
	if(iPlagRnd && zp_is_plague_round())
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Режим - Чума!", szNameMenu)
		return PLUGIN_HANDLED
	}

	new iSurvCont = ArrayGetCell(g_aiSurvCount[iType], iItem);
	if(iSurvCont && zp_get_survivor_count() >= iSurvCont)
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: уже есть %d Выживших!", szNameMenu, iSurvCont)
		return PLUGIN_HANDLED
	}
	
	new iNemCont = ArrayGetCell(g_aiNemCount[iType], iItem);
	if(iNemCont && zp_get_nemesis_count() >= iNemCont)
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: уже есть %d Босса!", szNameMenu, iNemCont)
		return PLUGIN_HANDLED
	}

	new iLifeLimit = ArrayGetCell(g_aiLifeLimit[iType], iItem), iUserLifeLimit[33]; 
	if(iLifeLimit)
	{
		ArrayGetArray(g_amLifeLimit[iType], iItem, iUserLifeLimit, charsmax(iUserLifeLimit));
		if(iUserLifeLimit[id] >= iLifeLimit)
		{
			UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Максимум %d за жизнь!", szNameMenu, iLifeLimit)
			return PLUGIN_HANDLED
		}

	}
	
	new iLastHuman = ArrayGetCell(g_aiLastHuman[iType], iItem);
	if(iLastHuman && zp_get_human_count() <= iLastHuman)
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: В игре последний человек!", szNameMenu)
		return PLUGIN_HANDLED
	}
	
	new iZombieCount = ArrayGetCell(g_aiZombieCount[iType], iItem);
	if(iZombieCount && zp_get_zombie_count() <= iZombieCount)
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: В игре мало зомби!", szNameMenu)
		return PLUGIN_HANDLED
	}
	
	new iHero = ArrayGetCell(g_aiHero[iType], iItem);
	if(iHero && zp_get_user_hero(id))
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Вы - Герой!", szNameMenu)
		return PLUGIN_HANDLED
	}

	new iBlockTime = ArrayGetCell(g_aiBlockSeconds[iType], iItem),
		Float:flBlockTime = Float:ArrayGetCell(g_aflBlockTime[iType], iItem),
		Float:flGameTime = get_gametime()

	if(iBlockTime && flBlockTime > flGameTime)
	{
		new szTime[16]; clock_format(flGameTime, flBlockTime, szTime, charsmax(szTime));
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: ждите !t%s!y!", szNameMenu, szTime);
		return PLUGIN_HANDLED
	}


	new iLvl = ArrayGetCell(g_aiLvl[iType], iItem), iMoneyKey = zpe_get_user_moneykey(id), iAmmoKey = zpe_get_user_ammokey(id);
	if(iLvl && iLvl > zpe_get_user_lvl(id) && (iMoney && !iMoneyKey || iAmmo && !iAmmoKey))
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: у Вас низкий LVL!", szNameMenu);
		return PLUGIN_HANDLED
	}

	if(iMoney && iMoney > zp_get_user_money(id))
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Недостаточно $!", szNameMenu)
		return PLUGIN_HANDLED
	}

	if(iAmmo && iAmmo > zp_get_user_ammo(id))
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Недостаточно Ammo!", szNameMenu)
		return PLUGIN_HANDLED
	}
	
	new iExtraItem = ArrayGetCell(g_aiGunsItem[iType], iItem)

	if(iExtraItem == zp_get_extraitem_harpy() && zp_get_user_harpy(id) || 
	iExtraItem == zp_get_claymore_extraid() && zp_get_user_claymore(id) || 
	iExtraItem == zp_get_extra_item_vision() && zp_has_user_vision(id))
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: У Вас уже есть!", szNameMenu)
		return PLUGIN_HANDLED
	}

	
	if(iExtraItem == EXTRA_MADNESS && Float:get_entvar(id, var_takedamage) == DAMAGE_NO)
	{
		UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Вы заморожены!", szNameMenu);
		return PLUGIN_HANDLED;
	}

	if(iExtraItem == zp_get_extra_jump())
	{
		new iTime = zp_get_jump_left_sec(id);
		if(iTime > 0)
		{
			UTIL_SayText(id, "!g[BuyMenu] !yВы не можете купить !g%s!y: Подождите !t%d !yс!", szNameMenu, iTime);
			return PLUGIN_HANDLED;
		}
	}

	if(zp_force_buy_extra_item(id, ArrayGetCell(g_aiGunsItem[iType], iItem), 1))
	{
		if(iLimitRound)
			TrieSetCell(tLimitRound, szSteamId, iUserLimitRound + 1)

		if(iLimitMap)
			TrieSetCell(tLimitMap, szSteamId, iUserLimitMap + 1)

		if(iLifeLimit)
		{
			iUserLifeLimit[id]++;
			ArraySetArray(g_amLifeLimit[iType], iItem, iUserLifeLimit, charsmax(iUserLifeLimit));
		}

		if(iBlockTime)
			ArraySetCell(g_aflBlockTime[iType], iItem, flGameTime + float(iBlockTime));

		if(iMoney)
		{
			if(iLvl && iLvl > zpe_get_user_lvl(id))
			{
				set_user_property(id, BACKUP_MKEY_FIELD, get_user_property(id, BACKUP_MKEY_FIELD) + 1);
				zpe_set_user_moneykey_wohud(id, iMoneyKey - 1);
			}

			zp_set_user_money(id, zp_get_user_money(id) - iMoney)
			set_user_property(id, BACKUP_MONEY_FIELD, get_user_property(id, BACKUP_MONEY_FIELD) + iMoney);
		}
		else if (iAmmo)
		{
			if(iLvl && iLvl > zpe_get_user_lvl(id))
			{
				set_user_property(id, BACKUP_AKEY_FIELD, get_user_property(id, BACKUP_AKEY_FIELD) + 1);
				zpe_set_user_ammokey_wohud(id, iAmmoKey - 1);
			}

			zp_set_user_ammo(id, zp_get_user_ammo(id) - iAmmo)
			set_user_property(id, BACKUP_AMMO_FIELD, get_user_property(id, BACKUP_AMMO_FIELD) + iAmmo);
		}


		#if defined BLOCK_BUY
		switch(iType)
		{
			case PISTOLS: 
				g_iUserGunsBlock[id] |= BLOCK_SECONDARY;
			case SHOOTGUNS..MACHINES:
				g_iUserGunsBlock[id] |= BLOCK_PRIMARY; 
		}
		#endif
	}
	
	return PLUGIN_HANDLED
}

stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	switch(pPlayer)
	{
		case 0:
		{
			for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++)
			{
				if(!is_user_connected(iPlayer)) continue;
				engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, iPlayer);
				write_byte(iPlayer);
				write_string(szBuffer);
				message_end();
			}
		}
		default:
		{
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, pPlayer);
			write_byte(pPlayer);
			write_string(szBuffer);
			message_end();
		}
	}
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
	return get_pdata_int(pPlayer, iOffset, linux_diff_player);
}

stock get_weektime(&hour, &week)
{
	new szTimeParse[5]; get_time("%H %w", szTimeParse, charsmax(szTimeParse));

	new szHour[3], szWeek[3]; 
	parse(szTimeParse, szHour, charsmax(szHour), szWeek, charsmax(szWeek));

	hour = str_to_num(szHour);
	week = str_to_num(szWeek);
}

stock bool:is_valid_hour(iHour, iMin, iMax)
{
	if(iMin == iMax) 
		return true
	
	if(iMin > iMax && (iMin <= iHour <= 23 || 0 <= iHour <= iMax))
		return true;

	if(iMin < iMax && iMin <= iHour <= iMax)
		return true;

	return false;
} 

stock is_valid_week(iWeek, iMin, iMax)
{
	if(iMin == iMax) 
		return true
	
	if(iMin > iMax && (iMin <= iWeek <= 6 || 0 <= iWeek <= iMax))
		return true;

	if(iMin < iMax && iMin <= iWeek <= iMax)
		return true;

	return false;
}