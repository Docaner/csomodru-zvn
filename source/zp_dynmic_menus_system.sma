#include <amxmodx>
#include <reapi>
#include <api_json_smart_parser>
#include <zombieplague>
#include <api_identifier>
#include <zp_system>
#include <zp_buymenu>

native zp_get_user_hero(iPlayer);
native zpe_get_user_chainsaw(id);

/**
 * Json-строка менюшек
 */
new const g_szJsonPath[] = "addons/amxmodx/configs/zpe_mode/addon_dynamic_menus.json";

#define Dynamic_MaxCmdChars 		32
#define Dynamic_MaxTitleChars 		64
#define Dynamic_MaxItemNameChars	64

#define Dynamic_MoreMaxItems 7
#define Dynamic_LessMaxItems 9

/**
 * Префикс для api_identifier
 */
new const g_szPrefixProperty[] = "DM_";

/**
 * Статус десериализации
 */
enum _:JsonDeser
{
	NoFile = -1,
	NoMainProperty,
	DeserSuccess
}

/**
 * Бесплатный мод
 */
 enum _:FreeMode
 {
 	NotDonater = 0,
 	Denide,
 	ModeSuccess
 }

/**
 * Доступность предмета
 */
 enum _:ItemAccess
 {
 	BlockWeaponType = 0,
 	BlockZombie,
 	BlockFirstZombie,
 	BlockHuman,
 	BlockNemezis,
 	BlockSurvivor,
 	BlockHero,
 	BlockChainsaw,
 	BlockRoundType,
 	BlockDead,
 	BlockTimeLimit,
 	BlockAllMenusRoundLimit,
 	BLockMapLimit,
 	NoMoney,
 	NoAmmo,
 	ItemSuccess,
	BlockLastHuman,
	BlockLastZombie,
 }

#define FLAG_A      (1<<0)  /* flag "a" */
#define FLAG_B   	(1<<1)  /* flag "b" */
#define FLAG_C      (1<<2)  /* flag "c" */
#define FLAG_D      (1<<3)  /* flag "d" */
#define FLAG_E      (1<<4)  /* flag "e" */
#define FLAG_F      (1<<5)  /* flag "f" */
#define FLAG_G      (1<<6)  /* flag "g" */
#define FLAG_H      (1<<7)  /* flag "h" */
#define FLAG_I      (1<<8)  /* flag "i" */
#define FLAG_J      (1<<9)  /* flag "j" */
#define FLAG_K      (1<<10)  /* flag "k" */
#define FLAG_L      (1<<11)  /* flag "l" */
#define FLAG_M      (1<<12)  /* flag "m" */
#define FLAG_N      (1<<13)  /* flag "n" */

/**
 * Меню
 */
new	Array:g_asTitle, 	// Заголовки меню
	Array:g_asCmd,		// Команды вызова менюшек
	Array:g_aiFlags, 	// Админ-флаги для открытия
	Array:g_aiMaxMoney,	// Верхний предел денег
	Array:g_aiMaxAmmo,	// Верхний предел аммо
	Array:g_aiStartItemIndex,	// Стартовый индекс пункта меню
	Array:g_aiEndItemIndex;		// Конечный индекс пункта меню

/**
 * Пункты
 */
new Array:g_asItemName, 	// Наименование пункта
	Array:g_aiExtraIndex, 	// Индекс EI
	Array:g_aiWeaponType,	// Тип оружия
	Array:g_aiMoney,		// Цена в деньгах
	Array:g_aiAmmo,			// Цена в аммо
	Array:g_aiModeFlags,	// Флаги мода
	Array:g_afGlobalTimeLimit,	// Глобальный (на всех игроков) ременной лимит
	Array:g_aiAllMenusRoundsLimit, // Лимит в раундах на все менюшки при бесплатном моде
	Array:g_aiMapLimit,		// Лимит за карту
	Array:g_abFreeMod;		// Мод на бесплатное взятие 

new g_iUserMenu_ArrayIndex[33], g_iMenuPosition[33], g_iMenuMaxItems[33];

/**
 * Identifier System
 */

#define BACKUP_MONEY_FIELD 	"bm_backup_money" 	// Возврат денег
#define BACKUP_AMMO_FIELD	"bm_backup_ammo"	// Возврат аммо

public plugin_cfg()
{
	register_plugin("[ZP] Dynamic Menus System", "1.0", "Docaner");

	RegisterHookChain(RG_CSGameRules_RestartRound, "@RG_RestartRound_Post", true);

	InitData(g_szJsonPath);
}

public plugin_end()
	DestroyDynamicData();

@RG_RestartRound_Post()
{
	new iAllMenusRounds; 
	new szPropertyAllMenusRounds[64]; formatex(szPropertyAllMenusRounds, charsmax(szPropertyAllMenusRounds), "%sAllMenusRoundLimit", g_szPrefixProperty);
	
	for(new i, iSizeIdentifiers = get_identifiers_size(); i < iSizeIdentifiers; i++)
	{
		iAllMenusRounds = get_arrayindex_property(i, szPropertyAllMenusRounds);
		if(iAllMenusRounds) set_arrayindex_property(i, szPropertyAllMenusRounds, iAllMenusRounds - 1);
	}
}

/**
 * Инициализация данных
 */

stock InitData(const szJsonPath[])
{
	InitDynamicData();
	
	if(JsonDeserialize(szJsonPath) != JsonDeser:DeserSuccess)
		return;

	InitClCmds(g_asCmd);
}

stock InitDynamicData()
{
	g_asTitle = ArrayCreate(Dynamic_MaxTitleChars);
	g_asCmd = ArrayCreate(Dynamic_MaxCmdChars);
	g_aiFlags = ArrayCreate();
	g_aiMaxMoney = ArrayCreate();
	g_aiMaxAmmo = ArrayCreate();
	g_aiStartItemIndex = ArrayCreate();
	g_aiEndItemIndex = ArrayCreate();

	g_asItemName = ArrayCreate(Dynamic_MaxItemNameChars);
	g_aiExtraIndex = ArrayCreate();
	g_aiWeaponType = ArrayCreate();
	g_aiMoney = ArrayCreate();
	g_aiAmmo = ArrayCreate();
	g_aiModeFlags = ArrayCreate();
	g_afGlobalTimeLimit = ArrayCreate();
	g_aiAllMenusRoundsLimit = ArrayCreate();
	g_aiMapLimit = ArrayCreate();
	g_abFreeMod = ArrayCreate();
}

stock DestroyDynamicData()
{
	ArrayDestroy(g_asTitle);
	ArrayDestroy(g_asCmd);
	ArrayDestroy(g_aiFlags);
	ArrayDestroy(g_aiMaxMoney);
	ArrayDestroy(g_aiMaxAmmo);
	ArrayDestroy(g_aiStartItemIndex);
	ArrayDestroy(g_aiEndItemIndex);

	ArrayDestroy(g_asItemName);
	ArrayDestroy(g_aiExtraIndex);
	ArrayDestroy(g_aiWeaponType);
	ArrayDestroy(g_aiMoney);
	ArrayDestroy(g_aiAmmo);
	ArrayDestroy(g_aiModeFlags);
	ArrayDestroy(g_afGlobalTimeLimit);
	ArrayDestroy(g_aiAllMenusRoundsLimit);
	ArrayDestroy(g_aiMapLimit);
	ArrayDestroy(g_abFreeMod);
}

stock JsonDeser:JsonDeserialize(const szJsonPath[])
{
	if(!file_exists(szJsonPath))
	{
		log_amx("Не найден файл ^"%s^"", szJsonPath);
		return JsonDeser:NoFile;
	}

	new JSON:jHandle = json_parse(szJsonPath, true, true);

	if(!json_is_object(jHandle))
	{
		log_amx("Файл ^"%s^" не является JSON-объектом", szJsonPath);
		return JsonDeser:NoMainProperty;
	}

	new JsonDeser:jValue = JsonDeserMenus(jHandle);
	json_free(jHandle);
	return jValue;
}

stock JsonDeser:JsonDeserMenus(JSON:jHandle)
{
	if(!json_object_has_value(jHandle, "menus", JSONArray))
	{
		log_amx("Нет поля ^"menu^"");
		return JsonDeser:NoMainProperty;
	}

	new JSON:jArray = json_object_get_value(jHandle, "menus");

	new szTitle[Dynamic_MaxTitleChars], 
		szCmd[Dynamic_MaxCmdChars],
		iBitFlags, szFlags[27],
		iMaxMoney,
		iMaxAmmo,
		iStartItem,
		iEndItem;

	for(new i, JSON:jTemp, jArrayCount = json_array_get_count(jArray);
		i < jArrayCount;
		json_free(jTemp), i++)
	{
		jTemp = json_array_get_value(jArray, i);

		if(!get_string_by_prop(jTemp, "title", szTitle, charsmax(szTitle)))
			continue;

		if(!get_string_by_prop(jTemp, "cmd", szCmd, charsmax(szCmd)))
			continue;

		get_string_by_prop(jTemp, "adminflags", szFlags, charsmax(szFlags), false);
		iBitFlags = read_flags(szFlags);

		iMaxMoney = get_int_by_prop(jTemp, "free_maxmoney", _, false);
		iMaxAmmo = get_int_by_prop(jTemp, "free_maxammo", _, false);

		if(JsonDeserItems(jTemp, iStartItem, iEndItem) != JsonDeser:DeserSuccess)
		{
			log_amx("Не удалось десериализовать items");
			continue;
		}

		ArrayPushString(g_asTitle, szTitle);
		ArrayPushString(g_asCmd, szCmd);
		ArrayPushCell(g_aiFlags, iBitFlags);
		ArrayPushCell(g_aiMaxMoney, iMaxMoney);
		ArrayPushCell(g_aiMaxAmmo, iMaxAmmo);
		ArrayPushCell(g_aiStartItemIndex, iStartItem);
		ArrayPushCell(g_aiEndItemIndex, iEndItem);
	}

	json_free(jArray);
	return JsonDeser:DeserSuccess;
}

stock JsonDeser:JsonDeserItems(JSON:jHandle, &iStartItem, &iEndItem)
{
	if(!json_object_has_value(jHandle, "items", JSONArray))
	{
		log_amx("Нет поля ^"items^"");
		return JsonDeser:NoMainProperty;
	}

	new JSON:jArray = json_object_get_value(jHandle, "items");

	new szName[Dynamic_MaxItemNameChars],
		iExtra, szExtra[Dynamic_MaxItemNameChars],
		iWeaponType, szWeaponType[27],
		iMoney,
		iAmmo,
		iModFlags, szModFlags[27],
		Float:flGlobalTimeLimit,
		iAllMenusRoundsLimit,
		iMapLimit,
		bFreeMode;

	iStartItem = -1;

	for(new i, JSON:jTemp, jArrayCount = json_array_get_count(jArray);
		i < jArrayCount;
		json_free(jTemp), i++)
	{
		jTemp = json_array_get_value(jArray, i);

		if(!get_string_by_prop(jTemp, "name", szName, charsmax(szName)))
			continue;

		if(!get_string_by_prop(jTemp, "extraitem", szExtra, charsmax(szExtra)))
			continue;


		if((iExtra = zp_get_extra_item_id(szExtra)) == -1)
		{
			log_amx("ExtraItem ^"%s^" не найден", szExtra);
			continue;
		}

		get_string_by_prop(jTemp, "weapontype", szWeaponType, charsmax(szWeaponType), false)

		iWeaponType = read_flags(szWeaponType);

		iMoney = get_int_by_prop(jTemp, "money", _, false);
		iAmmo = get_int_by_prop(jTemp, "ammo", _, false);

		get_string_by_prop(jTemp, "modeflags", szModFlags, charsmax(szModFlags), false)

		iModFlags = read_flags(szModFlags);

		flGlobalTimeLimit = get_float_by_prop(jTemp, "global_timelimit", _, false);
		iAllMenusRoundsLimit = get_int_by_prop(jTemp, "free_allmenus_roundslimit", _, false);
		iMapLimit = get_int_by_prop(jTemp, "maplimit", _, false);
		bFreeMode = get_bool_by_prop(jTemp, "freemode", true, false);

		ArrayPushString(g_asItemName, szName);
		ArrayPushCell(g_aiExtraIndex, iExtra);
		ArrayPushCell(g_aiWeaponType, iWeaponType);
		ArrayPushCell(g_aiMoney, iMoney);
		ArrayPushCell(g_aiAmmo, iAmmo);
		ArrayPushCell(g_aiModeFlags, iModFlags);
		ArrayPushCell(g_afGlobalTimeLimit, flGlobalTimeLimit);
		ArrayPushCell(g_aiAllMenusRoundsLimit, iAllMenusRoundsLimit);
		ArrayPushCell(g_aiMapLimit, iMapLimit);
		ArrayPushCell(g_abFreeMod, bFreeMode);

		if(iStartItem == -1)
			iStartItem = ArraySize(g_asItemName) - 1;
	}

	iEndItem = ArraySize(g_asItemName) - 1;
	json_free(jArray);

	return iStartItem == -1 ? (JsonDeser:NoMainProperty) : (JsonDeser:DeserSuccess);
}

/**
 * Инициализация клиентских команд
 */

stock InitClCmds(Array:asCmds)
{
	for(new i, szCmd[Dynamic_MaxCmdChars], iArraySize = ArraySize(asCmds);
		i < iArraySize;
		i++)
	{
		ArrayGetString(asCmds, i, szCmd, charsmax(szCmd));
		register_clcmd(szCmd, "@ClCmd_DynamicMenu");
	}

	register_menucmd(register_menuid("Show_DynamicMenu"), 1023, "@Handle_DynamicMenu");
}

@ClCmd_DynamicMenu(id)
{
	enum {Arg_Cmd = 0}

	new szCmd[Dynamic_MaxCmdChars]; read_argv(Arg_Cmd, szCmd, charsmax(szCmd));

	g_iUserMenu_ArrayIndex[id] = ArrayFindString(g_asCmd, szCmd);

	if(g_iUserMenu_ArrayIndex[id] == -1)
		return PLUGIN_HANDLED;

	return @CMD_DynamicMenu(id);
}

@CMD_DynamicMenu(id) return Show_DynamicMenu(id, g_iMenuPosition[id] = 0);
Show_DynamicMenu(id, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;

	//Стартовый и конечный индекс предметов для текущего меню
	new iArray_StartItemIndex = ArrayGetCell(g_aiStartItemIndex, g_iUserMenu_ArrayIndex[id]),
	iArray_EndItemIndex = ArrayGetCell(g_aiEndItemIndex, g_iUserMenu_ArrayIndex[id]);

	//Подсчёт всех строк в меню и максимально отбражаемых элеметнов в меню
	new iStringsCount = iArray_EndItemIndex - iArray_StartItemIndex + 1;
	new iStringsMax = iStringsCount <= Dynamic_LessMaxItems ? Dynamic_LessMaxItems : Dynamic_MoreMaxItems;

	g_iMenuMaxItems[id] = iStringsMax;

	if(!iStringsCount)
	{
		client_print_color(id, id, "^4[ZP] ^1Меню не доступно");
		return PLUGIN_HANDLED;
	}

	new iPagesNum = (iStringsCount / iStringsMax + ((iStringsCount % iStringsMax) ? 1 : 0));

	if(iPos >= iPagesNum)
		return Show_DynamicMenu(id, iPagesNum - 1);

	new iStart = iPos * iStringsMax;
	if(iStart > iStringsCount) iStart = iStringsCount;
	iStart = iStart - (iStart % iStringsMax);
	new iEnd = iStart + iStringsMax;
	if(iEnd > iStringsCount) iEnd = iStringsCount;

	//Title

	new szTitle[Dynamic_MaxTitleChars]; ArrayGetString(g_asTitle, g_iUserMenu_ArrayIndex[id], szTitle, charsmax(szTitle));
	new szPageCounter[16];

	if(iStringsMax == Dynamic_MoreMaxItems) formatex(szPageCounter, charsmax(szPageCounter), " \w[%d|%d]", iPos + 1, iPagesNum);

	new szMenu[512], 
	iLen = formatex(szMenu, charsmax(szMenu), "\y%s%s^n^n", szTitle, szPageCounter);

	//Header
	new FreeMode:iModeType = is_usermenu_free(id, g_iUserMenu_ArrayIndex[id]);
	
	switch(iModeType)
	{
		case NotDonater:
		{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[!] Нет прав. Купить: CSOMOD.RU^n^n");
		}
		case Denide:
		{
			new iMaxMoney = ArrayGetCell(g_aiMaxMoney, g_iUserMenu_ArrayIndex[id]);
			new iMaxAmmo = ArrayGetCell(g_aiMaxAmmo, g_iUserMenu_ArrayIndex[id]);

			new szMax[32]; formatex(szMax, charsmax(szMax), "%s%s%s",
			iMaxMoney ? fmt("\r%d $", iMaxMoney) : "",
			iMaxMoney && iMaxAmmo ? " \yи " : "",
			iMaxAmmo ? fmt("\r%d аммо", iMaxAmmo) : "");

			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\yБесплатный мод доступен, если^nна вашем счету меньше %s^n^n", szMax);
		}
	}

	//Items

	new iKeys = (1<<9), b, iItem,
	szItemName[Dynamic_MaxItemNameChars],
	ItemAccess:iItemAccess,
	szReason[32];

	for(new a = iStart; a < iEnd; a++)
	{
		iItem = iArray_StartItemIndex + a;
		ArrayGetString(g_asItemName, iItem, szItemName, charsmax(szItemName));
		
		switch(iModeType)
		{
			case NotDonater:
			{
				iKeys |= (1<<b);
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \d%s^n", ++b, szItemName);
			}
			case Denide, ModeSuccess:
			{
				iItemAccess = is_useritem_access(id, iItem, iModeType);
				get_user_blockreason_menu(id, iItem, iModeType, iItemAccess, szReason, charsmax(szReason));

				iKeys |= (1<<b);
				iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. %s%s%s^n", ++b, iItemAccess == ItemAccess:ItemSuccess ? "\w" : "\d", szItemName, szReason);
			}
		}


	}

	for(new i = b; i < iStringsMax; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n")

	if(iStringsMax == Dynamic_MoreMaxItems)
	{
		if(iPos > 0)
		{
			iKeys |= (1<<7)
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r8. \wНазад^n")
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r8. \dНазад^n")
		if(iPos < iPagesNum - 1)
		{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9. \wДалее^n")
			iKeys |= (1<<8)
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9. \dДалее^n")
	}

	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wВыход")

	return show_menu(id, iKeys, szMenu, -1, "Show_DynamicMenu")
}

@Handle_DynamicMenu(id, iKey)
{
	switch(g_iMenuMaxItems[id])
	{
		case Dynamic_MoreMaxItems:
		{
			switch(iKey)
			{
				case 7: return Show_DynamicMenu(id, --g_iMenuPosition[id]);
				case 8: return Show_DynamicMenu(id, ++g_iMenuPosition[id]);
				case 9: return PLUGIN_HANDLED;
			}
		}
		case Dynamic_LessMaxItems:
		{
			if(iKey == 9)
				return PLUGIN_HANDLED;
		}
	}

	new iMenuItem = g_iMenuPosition[id] * g_iMenuMaxItems[id] + iKey;
	GiveItem(id, g_iUserMenu_ArrayIndex[id], iMenuItem);
	return Show_DynamicMenu(id, g_iMenuPosition[id]);
}

stock GiveItem(const id, const iMenuIndex, const iMenuItem)
{
	new FreeMode:iModeType = is_usermenu_free(id, iMenuIndex);
	switch(iModeType)
	{
		case NotDonater: client_print_color(id, id, "^4[ZP] ^1Нет прав. Купить: ^4CSOMOD.RU");
		case Denide, ModeSuccess:
		{
			new iItem = ArrayGetCell(g_aiStartItemIndex, iMenuIndex) + iMenuItem;
			new ItemAccess:iItemAccess = is_useritem_access(id, iItem, iModeType);

			if(iItemAccess != ItemAccess:ItemSuccess)
			{
				new szReason[128];
				get_user_blockreason_chat(id, iItem, iModeType, iItemAccess, szReason, charsmax(szReason));
				client_print_color(id, id, "^4[ZP] %s", szReason);
				return;
			}


			new iWeaponType = ArrayGetCell(g_aiWeaponType, iItem);
			if(iWeaponType) zp_set_user_weapon_block(id, (zp_get_user_weapon_block(id) | iWeaponType));

			new Float:flGlobalTimeLimit = ArrayGetCell(g_afGlobalTimeLimit, iItem);
			if(flGlobalTimeLimit > 0.0) set_item_timelimit(iItem, get_gametime() + flGlobalTimeLimit);

			new iMapLimit = ArrayGetCell(g_aiMapLimit, iItem);
			if(iMapLimit) set_user_maplimit(id, iItem, get_user_maplimit(id, iItem) + 1);

			if(iModeType == FreeMode:ModeSuccess)
			{
				new iAllMenusRounds = ArrayGetCell(g_aiAllMenusRoundsLimit, iItem)
				if(iAllMenusRounds) set_user_allmenus_roundlimit(id, iAllMenusRounds);				
			}



			new bool:bFreeModeItem = ArrayGetCell(g_abFreeMod, iItem);
			if(iModeType == FreeMode:Denide || !bFreeModeItem)
			{
				new iItemMoney = ArrayGetCell(g_aiMoney, iItem);
				if(iItemMoney) 
				{
					zp_set_user_money(id, zp_get_user_money(id) - iItemMoney);
					set_user_property(id, BACKUP_MONEY_FIELD, get_user_property(id, BACKUP_MONEY_FIELD) + iItemMoney);
				}

				new iItemAmmo = ArrayGetCell(g_aiAmmo, iItem);
				if(iItemAmmo) 
				{
					zp_set_user_ammo(id, zp_get_user_ammo(id) - iItemAmmo);
					set_user_property(id, BACKUP_AMMO_FIELD, get_user_property(id, BACKUP_AMMO_FIELD) + iItemAmmo);
				}
			}

			zp_force_buy_extra_item(id, ArrayGetCell(g_aiExtraIndex, iItem), 1);
		}
	}

}

/**
 * Проверка меню на бесплатный мод
 */
stock FreeMode:is_usermenu_free(const id, const iMenuIndex)
{
	if(~get_user_flags(id) & ArrayGetCell(g_aiFlags, iMenuIndex))
		return FreeMode:NotDonater;

	new iMaxMoney = ArrayGetCell(g_aiMaxMoney, g_iUserMenu_ArrayIndex[id]);
	new iMaxAmmo = ArrayGetCell(g_aiMaxAmmo, g_iUserMenu_ArrayIndex[id]);

	if(!iMaxMoney && !iMaxAmmo) 
		return FreeMode:ModeSuccess;

	new iMoney = zp_get_user_money(id), iAmmo = zp_get_user_ammo(id);

	if(iMoney > iMaxMoney || iAmmo > iMaxAmmo)
		return FreeMode:Denide;

	return FreeMode:ModeSuccess;
}

/**
 * Проверка предмета меню на доступность
 */
stock ItemAccess:is_useritem_access(const id, const iItemIndex, const FreeMode:iModeMenu)
{
	new iMapLimit = ArrayGetCell(g_aiMapLimit, iItemIndex);
	if(iMapLimit && iMapLimit <= get_user_maplimit(id, iItemIndex))
		return ItemAccess:BLockMapLimit;

	new Float:flGlobalTimeLimit = ArrayGetCell(g_afGlobalTimeLimit, iItemIndex);
	if(flGlobalTimeLimit > 0.0)
	{
		if(get_gametime() < get_item_timelimit(iItemIndex))
			return ItemAccess:BlockTimeLimit;
	}

	if(iModeMenu == FreeMode:ModeSuccess && 
		ArrayGetCell(g_aiAllMenusRoundsLimit, iItemIndex) && 
		get_user_allmenus_roundlimit(id))
		return ItemAccess:BlockAllMenusRoundLimit;

	new iWeaponType = ArrayGetCell(g_aiWeaponType, iItemIndex);
	if(zp_get_user_weapon_block(id) & iWeaponType)
		return ItemAccess:BlockWeaponType;

	new iModeFlags = ArrayGetCell(g_aiModeFlags, iItemIndex);

	if(iModeFlags & FLAG_K && !is_user_alive(id))
		return ItemAccess:BlockDead;

	if(iModeFlags & FLAG_A && zp_get_user_zombie(id))
		return ItemAccess:BlockZombie;

	if(iModeFlags & FLAG_L && zp_get_user_first_zombie(id))
		return ItemAccess:BlockFirstZombie;
	
	if(iModeFlags & FLAG_M && zp_get_human_count() <= 1)
		return ItemAccess:BlockLastHuman;

	if(iModeFlags & FLAG_N && zp_get_zombie_count() <= 1)
		return ItemAccess:BlockLastZombie;

	if(iModeFlags & FLAG_B && !zp_get_user_zombie(id))
		return ItemAccess:BlockHuman;

	if(iModeFlags & FLAG_C && zp_get_user_nemesis(id))
		return ItemAccess:BlockNemezis;

	if(iModeFlags & FLAG_D && zp_get_user_survivor(id))
		return ItemAccess:BlockSurvivor;

	if(iModeFlags & FLAG_E && zp_get_user_hero(id))
		return ItemAccess:BlockHero;

	if(iModeFlags & FLAG_F && zpe_get_user_chainsaw(id))
		return ItemAccess:BlockChainsaw;

	if(iModeFlags & FLAG_G && zp_is_nemesis_round())
		return ItemAccess:BlockRoundType;

	if(iModeFlags & FLAG_H && zp_is_survivor_round())
		return ItemAccess:BlockRoundType;

	if(iModeFlags & FLAG_I && zp_is_swarm_round())
		return ItemAccess:BlockRoundType;

	if(iModeFlags & FLAG_J && zp_is_plague_round())
		return ItemAccess:BlockRoundType;

	if(iModeMenu == FreeMode:Denide || !ArrayGetCell(g_abFreeMod, iItemIndex))
	{
		new iItemMoney = ArrayGetCell(g_aiMoney, iItemIndex);
		if(iItemMoney && zp_get_user_money(id) < iItemMoney)
			return ItemAccess:NoMoney

		new iItemAmmo = ArrayGetCell(g_aiAmmo, iItemIndex);
		if(iItemAmmo && zp_get_user_ammo(id) < iItemAmmo)
			return ItemAccess:NoAmmo
	}

	return ItemAccess:ItemSuccess;
}

/**
 * Получение причины блокировки в меню
 */
stock get_user_blockreason_menu(const id, const iItemIndex, const FreeMode:iModeType, const ItemAccess:iItemAccess, szText[], const iLen)
{
	switch(iItemAccess)
	{
		case BlockWeaponType: formatex(szText, iLen, " \r(Сл. раунд)");
 		case BlockZombie: formatex(szText, iLen, " \r(Зомби)");
 		case BlockFirstZombie: formatex(szText, iLen, " \r(Первый)");
 		case BlockLastHuman: formatex(szText, iLen, " \r(Последний чел)");
 		case BlockLastZombie: formatex(szText, iLen, " \r(Последний зм)");
 		case BlockHuman: formatex(szText, iLen, " \r(Человек)");
 		case BlockNemezis:	formatex(szText, iLen, " \r(Босс)");
 		case BlockSurvivor: formatex(szText, iLen, " \r(Выживший)");
 		case BlockHero: formatex(szText, iLen, " \r(Герой)");
 		case BlockChainsaw: formatex(szText, iLen, " \r(Пила)");
 		case BlockRoundType: formatex(szText, iLen, " \r(Мод раунд)");
 		case BlockDead: formatex(szText, iLen, " \r(Мёртв)");
 		case BlockTimeLimit: 
 		{
 			new szTime[8]; clock_format(get_gametime(), get_item_timelimit(iItemIndex), szTime, charsmax(szTime));
 			formatex(szText, iLen, " \r(%s)", szTime);
 		}
 		case BlockAllMenusRoundLimit: formatex(szText, iLen, " \r(%d рнд)", get_user_allmenus_roundlimit(id));
 		case BLockMapLimit: formatex(szText, iLen, " \r(Сл. карта)");
 		case NoMoney, NoAmmo, ItemSuccess:
 		{
 			if(iItemAccess == ItemAccess:ItemSuccess && iModeType == FreeMode:ModeSuccess)
 			{
 				//Обрыв строки
 				szText[0] = 0;
 				return;
 			}

 			new iItemMoney = ArrayGetCell(g_aiMoney, iItemIndex);
 			new szItemMoney[16]; if(iItemMoney) formatex(szItemMoney, charsmax(szItemMoney), "%d$", iItemMoney);

 			new iItemAmmo = ArrayGetCell(g_aiAmmo, iItemIndex);
 			new szItemAmmo[16]; if(iItemAmmo) formatex(szItemAmmo, charsmax(szItemAmmo), "%d ammo", iItemAmmo);

 			formatex(szText, iLen, " \y(%s%s%s)",
			szItemMoney,
			iItemMoney && iItemAmmo ? "|" : "",
			szItemAmmo);
 		}
	}
}

/**
 * Получение причины блокировки в чате
 */
stock get_user_blockreason_chat(const id, const iItemIndex, const FreeMode:iModeType, const ItemAccess:iItemAccess, szText[], const iLen)
{
	switch(iItemAccess)
	{
		case BlockWeaponType: formatex(szText, iLen, "^1Вы уже брали оружие данного типа в этом раунде");
 		case BlockZombie: formatex(szText, iLen, "^1Недоступно для зомби");
 		case BlockFirstZombie: formatex(szText, iLen, "^1Недоступно для первого зомби");
 		case BlockLastHuman: formatex(szText, iLen, "^1Недоступно: последний человек");
 		case BlockLastZombie: formatex(szText, iLen, "^1Недоступно: последний зомби");
 		case BlockHuman: formatex(szText, iLen, "^1Недоступно для людей");
 		case BlockNemezis:	formatex(szText, iLen, "^1Недоступно для Босса");
 		case BlockSurvivor: formatex(szText, iLen, "^1Недоступно для Выжившего");
 		case BlockHero: formatex(szText, iLen, "^1Недоступно для Героя");
 		case BlockChainsaw: formatex(szText, iLen, "^1Недоступно для Пилы");
 		case BlockRoundType: formatex(szText, iLen, "^1Недоступно в текущем раунде");
 		case BlockDead: formatex(szText, iLen, "^1Недоступно для мёртвых");
 		case BlockTimeLimit: 
 		{
 			new szTime[8]; clock_format(get_gametime(), get_item_timelimit(iItemIndex), szTime, charsmax(szTime));
 			formatex(szText, iLen, "^1Подождите ^4%s ^1(мин : с)", szTime);
 		}
 		case BlockAllMenusRoundLimit: formatex(szText, iLen, "^1Подождите ^4%d ^1раундов", get_user_allmenus_roundlimit(id));
 		case BLockMapLimit: formatex(szText, iLen, "^1Вы исчерпали лимит за карту: ^4%d", ArrayGetCell(g_aiMapLimit, iItemIndex));
 		case NoMoney, NoAmmo, ItemSuccess:
 		{
 			if(iItemAccess == ItemAccess:ItemSuccess && iModeType == FreeMode:ModeSuccess)
 				return;

 			new iItemMoney = ArrayGetCell(g_aiMoney, iItemIndex);
 			new szItemMoney[16]; if(iItemMoney) formatex(szItemMoney, charsmax(szItemMoney), "%d$", iItemMoney);

 			new iItemAmmo = ArrayGetCell(g_aiAmmo, iItemIndex);
 			new szItemAmmo[16]; if(iItemAmmo) formatex(szItemAmmo, charsmax(szItemAmmo), "%d ammo", iItemAmmo);

	 		new szCost[32];	
	 		formatex(szCost, charsmax(szCost), "%s%s%s",
			szItemMoney,
			iItemMoney && iItemAmmo ? " и " : "",
			szItemAmmo);

			formatex(szText, iLen, "^1Недостаточно средств. Цена: ^4%s", szCost);
 		}
	}
}

/**
 * Формат в виде цифровых частов 00:00
 */
stock clock_format(const Float:flGameTime, const Float:flTimeEnd, szOutLine[], const iLen)
{
	new iTimeLost = floatround(flTimeEnd - flGameTime, floatround_ceil);
	new iMinutes = iTimeLost / 60;
	new iSeconds = iTimeLost - iMinutes * 60;
	formatex(szOutLine, iLen, "%02d:%02d", iMinutes, iSeconds);
}

/**
 * Глобальный временной лимит
 */
stock Float:get_item_timelimit(const iItemIndex)
{
	new szItemName[Dynamic_MaxItemNameChars]; 
	ArrayGetString(g_asItemName, iItemIndex, szItemName, charsmax(szItemName));
	return get_user_property(0, fmt("%s%sTimeLimit", g_szPrefixProperty, szItemName), ValueFloat);
}

stock set_item_timelimit(const iItemIndex, Float:flValue)
{
	new szItemName[Dynamic_MaxItemNameChars]; 
	ArrayGetString(g_asItemName, iItemIndex, szItemName, charsmax(szItemName));
	return set_user_property(0, fmt("%s%sTimeLimit", g_szPrefixProperty, szItemName), flValue, ValueFloat);
}

/**
 * Лимит в раундах на все меню при бесплатном моде
 */
stock get_user_allmenus_roundlimit(const id)
	return get_user_property(id, fmt("%sAllMenusRoundLimit", g_szPrefixProperty));

stock set_user_allmenus_roundlimit(const id, iValue)
	set_user_property(id, fmt("%sAllMenusRoundLimit", g_szPrefixProperty), iValue);

/**
 * Лимит за карту
 */
stock get_user_maplimit(const id, const iItemIndex)
{
	new szItemName[Dynamic_MaxItemNameChars]; 
	ArrayGetString(g_asItemName, iItemIndex, szItemName, charsmax(szItemName));
	return get_user_property(id, fmt("%s%sMapLimit", g_szPrefixProperty, szItemName));
}

stock set_user_maplimit(const id, const iItemIndex, iValue)
{
	new szItemName[Dynamic_MaxItemNameChars]; 
	ArrayGetString(g_asItemName, iItemIndex, szItemName, charsmax(szItemName));
	set_user_property(id, fmt("%s%sMapLimit", g_szPrefixProperty, szItemName), iValue);
}
