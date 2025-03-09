#include <amxmodx>
#include <sqlx>
#include <reapi>
#include <zpe_lvl>
#include <zpe_mysql_main>

new const g_szHost[] = "46.174.50.7";
new const g_szUser[] = "u35796_zombiecso";
new const g_szPass[] = "D9d6G1u7Y4";
new const g_szDB[] = "u35796_zombiecso";

#define FLAG_ACCESS ADMIN_BAN // Админ-флаг для доступа к меню
#define FLAG_IMMUNITY ADMIN_IMMUNITY // Иммунитет к блокировке от админа
#define FLAG_PRIVILEGES ADMIN_LEVEL_H // Иммунитет на проверку уровня у привилегированных игроков

#define ACCESS_LVL_CHAT 2 // С какого уровня доступен чат
#define ACCESS_LVL_VOICE 3 // С какого уровня доступен микрофон

#define DELAY_MESSAGE 5.0 // Раз в сколько секунд выводить сообщение о блокировке (антиспам)

new const g_iTimes[] = // Время в минутах для блокировки (0 - навсегда) (не более 9 значений)
{
	5,
	60,
	360,
	1440,
	10080,
	43200,
	0
}

new g_szTimes[][] = // Текст времени
{
	"5 минут",
	"1 час",
	"6 часов",
	"1 день",
	"1 неделя",
	"1 месяц",
	"Навсегда"
}

new const g_szLogFile[] = "addons/amxmodx/logs/" // Логирование ошибок запросов MySQL

/*============================================================================*/

//Количество допустимых элементов на одной странице в меню (не трогать)
#define PLAYERS_PER_PAGE 7

//Максимальное возможное количество игроков на сервере
new g_iMaxPlayers;

//Временная метка, после которой карта меняется
new g_iMapTimeEnd;

//Переменные для меню
new g_iMenuPlayers[33][32], g_iMenuPosition[33], g_iMenuTarget[33];

//Переменные для выбора блокировки
new g_iBlockType[33], g_iBlockTime[33];

//Переменные для блокировки игрока
enum _: DATA_PLAYER
{
	USERID,
	STEAMID[32],
	BLOCKTYPE, // 1 - микрофон, 2 - чат, 3 - микрофон+чат 
	UNBLOCKTIME,
}

#define BLOCK_VOICE (1<<0)
#define BLOCK_CHAT (1<<1)

new g_aUserInfo[33][DATA_PLAYER];

//Mysql

new Handle:g_hSqlTuple;

enum _:VALID_USER
{
	V_ID,
	V_STEAMID[32]
}


#define TASK_UNBLOCK 5423534

public plugin_init()
{
	register_plugin("Gag System", "1.0", "Docaner");

	register_clcmd("amx_gagmenu", "ClCmd_OpenGagMenu");

	register_clcmd("say", "ClCmd_CheckBlock");
	register_clcmd("say_team", "ClCmd_CheckBlock");

	register_menucmd(register_menuid("Show_MenuPlayers"), 1023, "Handle_MenuPlayers");
	
	register_menucmd(register_menuid("Show_MenuUserBlock"), 1023, "Handle_MenuUserBlock");
	register_menucmd(register_menuid("Show_MenuChangeTime"), 1023, "Handle_MenuChangeTime");

	register_menucmd(register_menuid("Show_MenuUserUnblock"), 1023, "Handle_MenuUserUnblock");

	g_iMaxPlayers = get_maxplayers();
}

public OnAutoConfigsBuffered()
{
	new iTimeLimit = get_cvar_num("mp_timelimit") * 3600;
	if(iTimeLimit)
		g_iMapTimeEnd = get_systime() + iTimeLimit;

	init_mysql();
	delete_left_gags();
}

public zpe_mysql_user_load_post(id)
{
	VTC_MuteClient(id);
	client_cmd(id, "-voicerecord");

	new szSteamID[32]; get_user_authid(id, szSteamID, charsmax(szSteamID));

	new szQuery[512]; 
	formatex(szQuery, charsmax(szQuery),
			"SELECT * FROM GagSystem WHERE `SteamID` = '%s'",
			szSteamID);

	new szData[VALID_USER]; 
	szData[V_ID] = id;
	copy(szData[V_STEAMID], charsmax(szData[V_STEAMID]), szSteamID);

	SQL_ThreadQuery(g_hSqlTuple, "Query_LoadBlock", szQuery, szData, charsmax(szData));
}

public client_disconnected(id)
	set_user_unblock(id)

public ClCmd_OpenGagMenu(id)
{
	if(~get_user_flags(id) & FLAG_ACCESS)
	{
		client_print_color(id, id, "^4[GAG] ^1У Вас нет доступа");
		return PLUGIN_HANDLED;
	}

	return CMD_MenuPlayer(id);
}

public ClCmd_CheckBlock(id)
{
	static Float:flLastCheck[33];

	if(zpe_get_user_lvl(id) < ACCESS_LVL_CHAT)
	{
		new Float:flGameTime = get_gametime();
		if(flLastCheck[id] <= flGameTime)
		{
			client_print_color(id, id, "^4[CHAT] ^1Общение через чат доступно с ^3%d ^1уровня", ACCESS_LVL_CHAT)
			flLastCheck[id] = flGameTime + DELAY_MESSAGE;
		}
		return PLUGIN_HANDLED_MAIN;
	}

	if(g_aUserInfo[id][BLOCKTYPE] & BLOCK_CHAT)
	{
		new Float:flGameTime = get_gametime();
		if(flLastCheck[id] <= flGameTime)
		{
			if(g_aUserInfo[id][UNBLOCKTIME])
			{
				new szTime[17];
				format_time(szTime, charsmax(szTime), "%d.%m.%y %H:%M", g_aUserInfo[id][UNBLOCKTIME])
				client_print_color(id, id, "^4[GAG] ^1Вам выдана блокировка до ^3%s", szTime)
			}
			else
			{
				client_print_color(id, id, "^4[GAG] ^1Вам выдана блокировка навсегда")
			}
			flLastCheck[id] = flGameTime + DELAY_MESSAGE;
		} 
		
		return PLUGIN_HANDLED_MAIN;
	}

	return PLUGIN_CONTINUE;
}

public VTC_OnClientStartSpeak(const id)
{
	static Float:flLastCheck[33];

	if(zpe_get_user_lvl(id) < ACCESS_LVL_VOICE)
	{
		new Float:flGameTime = get_gametime();
		if(flLastCheck[id] <= flGameTime)
		{	
			client_print_color(id, id, "^4[VOICE] ^1Общение через микрофон доступно с ^3%d ^1уровня", ACCESS_LVL_VOICE)
			client_print_color(id, id, "^4[VOICE] ^1Помните, что пользоваться микрофоном можно только с^4 14 лет^1!")
			flLastCheck[id] = flGameTime + DELAY_MESSAGE;
		}

		return PLUGIN_HANDLED;
	}

	if(g_aUserInfo[id][BLOCKTYPE] & BLOCK_VOICE)
	{
		new Float:flGameTime = get_gametime();
		if(flLastCheck[id] <= flGameTime)
		{
			if(g_aUserInfo[id][UNBLOCKTIME])
			{
				new szTime[17];
				format_time(szTime, charsmax(szTime), "%d.%m.%y %H:%M", g_aUserInfo[id][UNBLOCKTIME])
				client_print_color(id, id, "^4[GAG] ^1Вам выдана блокировка до ^3%s", szTime)
			}
			else
			{
				client_print_color(id, id, "^4[GAG] ^1Вам выдана блокировка навсегда")
			}
			flLastCheck[id] = flGameTime + DELAY_MESSAGE;
		} 

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_user_lvl_up_post(id)
{
	if(zpe_get_user_lvl(id) == ACCESS_LVL_VOICE && ~g_aUserInfo[id][BLOCKTYPE] & BLOCK_VOICE)
		VTC_UnmuteClient(id);
}

CMD_MenuPlayer(id) return Show_MenuPlayers(id, g_iMenuPosition[id] = 0);
Show_MenuPlayers(id, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;

	new iStringsCount;

	for(new i = 1; i <= g_iMaxPlayers; i++)
	{
		if(!is_user_connected(i) || is_user_bot(i) || is_user_hltv(i)) continue;
		g_iMenuPlayers[id][iStringsCount++] = i;
	}

	if(!iStringsCount)
	{
		client_print_color(id, id, "^4[GAG] ^1Подходящие игроки для блокировки не найдены на сервере");
		return PLUGIN_HANDLED;
	}

	new iStart = iPos * PLAYERS_PER_PAGE
	if(iStart > iStringsCount) iStart = iStringsCount
	iStart = iStart - (iStart % PLAYERS_PER_PAGE)
	new iEnd = iStart + PLAYERS_PER_PAGE
	if(iEnd > iStringsCount) iEnd = iStringsCount

	new szMenu[512], iLen, iPagesNum = (iStringsCount / PLAYERS_PER_PAGE + ((iStringsCount % PLAYERS_PER_PAGE) ? 1 : 0))

	iLen = formatex(szMenu, charsmax(szMenu), "Выберете игрока для блокировки: \y[%d|%d]^n^n", iPos + 1, iPagesNum);

	new iKeys = (1<<9), b, szUserName[32], iTarget, szTypeBlock[32], szImmunity[8];

	for(new a = iStart; a < iEnd; a++)
	{
		iKeys |= (1<<b);

		iTarget = g_iMenuPlayers[id][a];
		get_user_name(iTarget, szUserName, charsmax(szUserName));

		switch(g_aUserInfo[iTarget][BLOCKTYPE])
		{
			case 1: szTypeBlock = " \r[Микрофон]";
			case 2: szTypeBlock = " \r[Чат]";
			case 3: szTypeBlock = " \r[Микрофон|Чат]"
		}

		if(get_user_flags(iTarget) & FLAG_IMMUNITY)
			szImmunity = " \r*";

		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s%s%s^n", ++b, szUserName, szTypeBlock, szImmunity)
		szTypeBlock = "";
		szImmunity = "";
	}

	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n")

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

	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wВыход");

	return show_menu(id, iKeys, szMenu, -1, "Show_MenuPlayers");
}

public Handle_MenuPlayers(id, iKey)
{
	switch(iKey)
	{
		case 7: return Show_MenuPlayers(id, --g_iMenuPosition[id]);
		case 8: return Show_MenuPlayers(id, ++g_iMenuPosition[id]);
		case 9: return PLUGIN_HANDLED;
		default:
		{
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];

			if(!is_user_connected(iTarget) || is_user_bot(iTarget) || is_user_hltv(iTarget))
			{
				client_print_color(id, id, "^4[GAG] ^1Игрок вышел с сервера");
				return Show_MenuPlayers(id, g_iMenuPosition[id]);
			}	

			g_iMenuTarget[id] = iTarget;

			if(g_aUserInfo[iTarget][BLOCKTYPE])
				return Show_MenuUserUnblock(id);
			
			g_iBlockType[id] = 1;
			g_iBlockTime[id] = 0;

			return Show_MenuUserBlock(id);
		}
	}
	return Show_MenuPlayers(id, g_iMenuPosition[id]);
}

Show_MenuUserBlock(id)
{
	new szUserName[32]; get_user_name(g_iMenuTarget[id], szUserName, charsmax(szUserName))
	
	new iKeys = (1<<1|1<<2|1<<3|1<<4), szMenu[512], 
		iLen = formatex(szMenu, charsmax(szMenu), "Выдать блокировку:^n^n");

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \wНик: \r%s^n", szUserName);

	new szBlockType[32];
	switch(g_iBlockType[id])
	{
		case 1: szBlockType = "Микрофон";
		case 2: szBlockType = "Чат";
		case 3: szBlockType = "Микрофон и Чат"
	}

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \wБлокировка: \r%s^n", szBlockType);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \wВремя: \r%s^n^n", g_szTimes[g_iBlockTime[id]]);

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \wВыдать блокировку^n");
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5. \wОтменить^n");

	return show_menu(id, iKeys, szMenu, -1, "Show_MenuUserBlock");
}

public Handle_MenuUserBlock(id, iKeys)
{
	new iTarget = g_iMenuTarget[id];

	if(!is_user_connected(iTarget))
	{
		client_print_color(id, id, "^4[GAG] ^1Игрок вышел с сервера");
		return Show_MenuPlayers(id, g_iMenuPosition[id]);
	}

	if(g_aUserInfo[iTarget][BLOCKTYPE])
	{
		client_print_color(id, id, "^4[GAG] ^1Игроку уже выдали блокировку");
		return Show_MenuPlayers(id, g_iMenuPosition[id]);
	}

	switch(iKeys)
	{
		case 1: 
		{
			g_iBlockType[id]++;
			if(g_iBlockType[id] > 3) g_iBlockType[id] = 1;
			return Show_MenuUserBlock(id);
		}
		case 2: return Show_MenuChangeTime(id);
		case 3:
		{
			set_user_block(iTarget, g_iBlockType[id], g_iTimes[g_iBlockTime[id]], true);

			new szBlockType[32];
			switch(g_iBlockType[id])
			{
				case 1: szBlockType = "микрофон";
				case 2: szBlockType = "чат";
				case 3: szBlockType = "микрофон и чат"
			}

			new szAdminName[32]; get_user_name(id, szAdminName, charsmax(szAdminName));
			new szUserName[32]; get_user_name(iTarget, szUserName, charsmax(szUserName));

			client_print_color(0, 0, "^4[GAG] ^1Админ ^4%s ^1заблокировал ^4%s ^1игроку ^3%s^1. Срок: ^4%s", szAdminName, szBlockType, szUserName, g_szTimes[g_iBlockTime[id]]);
		}
		case 4: return Show_MenuPlayers(id, g_iMenuPosition[id]);
	}	
	return PLUGIN_HANDLED;
}

public Show_MenuChangeTime(id)
{
	new iKeys = (1<<9), szMenu[512], 
		iLen = formatex(szMenu, charsmax(szMenu), "Выберете время:^n^n");

	for(new i; i < 9; i++)
	{
		if(i < sizeof g_iTimes)
		{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s%s^n", i + 1, g_szTimes[i], g_iBlockTime[id] == i ? " \r[x]" : "")
			iKeys |= (1<<i);
		}
		else
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	}

	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wНазад");

	return show_menu(id, iKeys, szMenu, -1, "Show_MenuChangeTime");
}

public Handle_MenuChangeTime(id, iKey)
{
	if(0 <= iKey <= 8)
		g_iBlockTime[id] = iKey;

	return Show_MenuUserBlock(id);
}

public Show_MenuUserUnblock(id)
{
	new iTarget = g_iMenuTarget[id];
	new szUserName[32]; get_user_name(iTarget, szUserName, charsmax(szUserName))
	
	new iKeys = (1<<3|1<<4), szMenu[512], 
		iLen = formatex(szMenu, charsmax(szMenu), "Разблокировать:^n^n");

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \wНик: \r%s^n", szUserName);

	new szBlockType[32];
	switch(g_aUserInfo[iTarget][BLOCKTYPE])
	{
		case 1: szBlockType = "Микрофон";
		case 2: szBlockType = "Чат";
		case 3: szBlockType = "Микрофон и Чат"
	}

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \wБлокировка: \r%s^n", szBlockType);
	
	new szTime[17];
	if(g_aUserInfo[iTarget][UNBLOCKTIME])
		format_time(szTime, charsmax(szTime), "%d.%m.%y %H:%M", g_aUserInfo[iTarget][UNBLOCKTIME])
	else 
		szTime = "Навсегда";

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \wБлокировка действует до: \r%s^n^n", szTime);

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \wРазблокировать^n");
	
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5. \wОтменить^n");

	return show_menu(id, iKeys, szMenu, -1, "Show_MenuUserUnblock");
}

public Handle_MenuUserUnblock(id, iKeys)
{
	new iTarget = g_iMenuTarget[id];

	if(!is_user_connected(iTarget) || is_user_bot(iTarget) || is_user_hltv(iTarget))
	{
		client_print_color(id, id, "^4[GAG] ^1Игрок вышел с сервера");
		return Show_MenuPlayers(id, g_iMenuPosition[id]);
	}

	if(!g_aUserInfo[iTarget][BLOCKTYPE])
	{
		client_print_color(id, id, "^4[GAG] ^1У игрока уже сняли блокировку");
		return Show_MenuPlayers(id, g_iMenuPosition[id]);
	}

	switch(iKeys)
	{
		case 3:
		{
			new szBlockType[32];
			switch(g_aUserInfo[iTarget][BLOCKTYPE])
			{
				case 1: szBlockType = "микрофон";
				case 2: szBlockType = "чат";
				case 3: szBlockType = "микрофон и чат"
			}

			new szAdminName[32]; get_user_name(id, szAdminName, charsmax(szAdminName));
			new szUserName[32]; get_user_name(iTarget, szUserName, charsmax(szUserName));

			client_print_color(0, 0, "^4[GAG] ^1Админ ^4%s ^1разблокировал ^4%s ^1игроку ^3%s^1", szAdminName, szBlockType, szUserName);
		
			set_user_unblock(iTarget, true);
		}
		case 4: return Show_MenuPlayers(id, g_iMenuPosition[id]);
	}	
	return PLUGIN_HANDLED;
}

set_user_block(id, iBitBlockType, iBlockTime, bool:bSQL = false)
{
	get_user_authid(id, g_aUserInfo[id][STEAMID], charsmax(g_aUserInfo[][STEAMID]));
	g_aUserInfo[id][BLOCKTYPE] = iBitBlockType;
	g_aUserInfo[id][UNBLOCKTIME] = iBlockTime ? (get_systime() + 60 * iBlockTime) : 0;

	set_user_mute(id);

	if(bSQL)
	{
		new szQuery[512]; 
		formatex(szQuery, charsmax(szQuery), 
			"INSERT INTO GagSystem (SteamID, BlockType, UnblockTime) VALUES ('%s', %d, %d)",
			g_aUserInfo[id][STEAMID],
			g_aUserInfo[id][BLOCKTYPE],
			g_aUserInfo[id][UNBLOCKTIME]
		);

		new szData[VALID_USER];
		szData[V_ID] = id;
		copy(szData[V_STEAMID], charsmax(szData[V_STEAMID]), g_aUserInfo[id][STEAMID]);

		SQL_ThreadQuery(g_hSqlTuple, "Query_NewBlock", szQuery, szData, charsmax(szData));
	}
}

set_user_mute(id)
{
	if(!task_exists(id+TASK_UNBLOCK) && g_aUserInfo[id][UNBLOCKTIME] < g_iMapTimeEnd && g_aUserInfo[id][UNBLOCKTIME])
		set_task(float(g_aUserInfo[id][UNBLOCKTIME] - get_systime()), "task_UnBlock", id+TASK_UNBLOCK);

	if(g_aUserInfo[id][BLOCKTYPE] & BLOCK_VOICE)
	{
		VTC_MuteClient(id);
		client_cmd(id, "-voicerecord");
	}
}

public task_UnBlock(id)
{
	id -= TASK_UNBLOCK;
	client_print_color(id, id, "^4[GAG] ^1Ваша блокировка истекла!");
	set_user_unblock(id, true);
}

set_user_unblock(id, bool:bSQL = false)
{
	remove_task(id+TASK_UNBLOCK);

	if(g_aUserInfo[id][BLOCKTYPE] & BLOCK_VOICE)
		VTC_UnmuteClient(id);

	if(bSQL && g_aUserInfo[id][USERID])
	{
		new szQuery[512]; 
		formatex(szQuery, charsmax(szQuery), 
			"DELETE FROM GagSystem WHERE `UserID` = %d",
			g_aUserInfo[id][USERID]
		);

		SQL_ThreadQuery(g_hSqlTuple, "Query_Unblock", szQuery);
	}

	g_aUserInfo[id][STEAMID] = ""
	g_aUserInfo[id][BLOCKTYPE] = 0;
	g_aUserInfo[id][UNBLOCKTIME] = 0;
}

init_mysql()
{
	g_hSqlTuple = SQL_MakeDbTuple(g_szHost, g_szUser, g_szPass, g_szDB)
	
	if(g_hSqlTuple == Empty_Handle)
		set_fail_state("Неудалось образовать кортеж");

	new Handle:hSqlConnection = create_mysql_connect()

	if(hSqlConnection == Empty_Handle) 
		set_fail_state("Нет подключения к БД");

	new szBuffer[512];

	szBuffer = 
		"CREATE TABLE IF NOT EXISTS GagSystem\
		( \
			UserID INT UNSIGNED UNIQUE AUTO_INCREMENT, \
			SteamID VARCHAR(32) UNIQUE, \
			BlockType TINYINT UNSIGNED NOT NULL, \
			UnblockTime INT UNSIGNED NOT NULL, \
			PRIMARY KEY(UserID) \
		)"

	new Handle:hQuery = SQL_PrepareQuery(hSqlConnection, szBuffer)

	if(!create_sql_execute(hQuery))
	{
		SQL_FreeHandle(hQuery)
		SQL_FreeHandle(hSqlConnection)
		
		set_fail_state("Не далось отправить запрос к БД");
	}

	SQL_FreeHandle(hQuery)
	SQL_FreeHandle(hSqlConnection)
}

delete_left_gags()
{
	new szQuery[512]; 
	formatex(szQuery, charsmax(szQuery),
			"DELETE FROM GagSystem WHERE `UnblockTime` != 0 AND `UnblockTime` < %d",
			get_systime());

	SQL_ThreadQuery(g_hSqlTuple, "Query_DeleteLeftGags", szQuery);
}


Handle:create_mysql_connect()
{
	new iError, szError[1024], Handle:hConnection;

	hConnection = SQL_Connect(g_hSqlTuple, iError, szError, charsmax(szError));

	if(hConnection == Empty_Handle)
		sql_log_error(szError);

	return hConnection;
}

bool:create_sql_execute(Handle:hQuery)
{
	if(SQL_Execute(hQuery)) return true;
	
	new szTemp[1024];
	SQL_QueryError(hQuery, szTemp, charsmax(szTemp))
	sql_log_error(szTemp);

	SQL_GetQueryString(hQuery, szTemp, charsmax(szTemp));
	sql_log_error(szTemp);
	
	return false;
}

sql_log_error(const szBuffer[])
{
	new szLogPath[1024], szDateThis[25];
	format_time(szDateThis, charsmax(szDateThis), "%Y%m%d", get_systime());
	formatex(szLogPath, charsmax(szLogPath), "%s/error_%s.log", g_szLogFile, szDateThis);
	log_to_file(szLogPath, szBuffer);
}

public Query_NewBlock(iFailState, Handle:hQuery, szError[], iError, szData[])
{
	if(iFailState) 
		{SQL_ErrorlogThread(iFailState, hQuery, szError, iError); return;}

	new id = szData[V_ID];
	new szSteamID[32]; get_user_authid(id, szSteamID, charsmax(szSteamID));

	if(!is_user_connecting(id) && !is_user_connected(id) || !equal(szSteamID, szData[V_STEAMID]))
		return;

	g_aUserInfo[id][USERID] = SQL_GetInsertId(hQuery);
}

public Query_Unblock(iFailState, Handle:hQuery, szError[], iError, szData[])
{
	if(iFailState) 
		{SQL_ErrorlogThread(iFailState, hQuery, szError, iError); return;}
}

public Query_LoadBlock(iFailState, Handle:hQuery, szError[], iError, szData[])
{
	if(iFailState) 
		{SQL_ErrorlogThread(iFailState, hQuery, szError, iError); return;}

	new id = szData[V_ID];
	new szSteamID[32]; get_user_authid(id, szSteamID, charsmax(szSteamID));

	if(!is_user_connecting(id) && !is_user_connected(id) || !equal(szSteamID, szData[V_STEAMID]))
		return;

	new iRows = SQL_NumResults(hQuery);

	if(iRows)
	{
		g_aUserInfo[id][USERID] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "UserID"));
		copy(g_aUserInfo[id][STEAMID], charsmax(g_aUserInfo[][STEAMID]), szSteamID);
		g_aUserInfo[id][BLOCKTYPE] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "BlockType"));
		g_aUserInfo[id][UNBLOCKTIME] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "UnblockTime"));
	
		if(g_aUserInfo[id][UNBLOCKTIME] < get_systime() && g_aUserInfo[id][UNBLOCKTIME])
			set_user_unblock(id, true);
		
		if(g_aUserInfo[id][BLOCKTYPE] & BLOCK_VOICE)
			set_user_mute(id);
	}

	if( (zpe_get_user_lvl(id) >= ACCESS_LVL_VOICE || get_user_flags(id) & FLAG_PRIVILEGES) && ~g_aUserInfo[id][BLOCKTYPE] & BLOCK_VOICE)
		VTC_UnmuteClient(id);
}

public Query_DeleteLeftGags(iFailState, Handle:hQuery, szError[], iError, szData[])
{
	if(iFailState) 
		{SQL_ErrorlogThread(iFailState, hQuery, szError, iError); return;}
}

SQL_ErrorlogThread(iFailState, Handle:hQuery, szError[], iError)
{
	new szTemp[1024]; 
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED: formatex(szTemp, charsmax(szTemp), "Connection Filed [%d] : %s", iError, szError);
		case TQUERY_QUERY_FAILED: formatex(szTemp, charsmax(szTemp), "Query Filed [%d] : %s", iError, szError);
	}
	sql_log_error(szTemp);

	SQL_GetQueryString(hQuery, szTemp, charsmax(szTemp));
	sql_log_error(szTemp);
}