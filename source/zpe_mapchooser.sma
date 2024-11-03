#include <amxmodx>
#include <json>
#include <zpe_knokcback>
#include <api_top5cam>

new const g_szFile[] = "addons/amxmodx/configs/zpe_mode/addon_mapchooser.ini" // Файл с картами
new const g_szFileLast[] = "addons/amxmodx/data/vault/zpe_mapchooser_last.json" // Файл с последними картами
#define TIME_TOVOTE 15 // Время на голосование
#define MAP_MAX 7 // Максимальное количество карт для выбора в голосовании

#define LASTMAP_MAX 4 // После какой смены карты можно добавить в голосование сыгранную карту

#define RTV_TIMEENABLE 5.0 // Через сколько минут после начала карты включить возможность голосовать
#define RTV_NUMENABLE 0.6 // Какая доля проголосвавших должна набраться для смены карты?

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))

#define PLAYERS_PER_PAGE 7

#define TASK_VOTE 53342
#define TASK_COUNTDOWN 53342

#define MsgId_SayText 76

new g_iMsgID_ScreanFade

new g_pCvarTimeLimit/*, g_pCvarRoundTime*/, g_pCvarFreezeTime, g_pCvarTimeLeft,
	g_pCvarNextMap; 	

new Float:g_fOldTimeLimit, bool:g_bTimeLimit, Float:g_fOldFreezeTime, bool:g_bFreezeTime, 
	bool:g_bIsVote, g_szNextMap[32];

new bool:g_bIsLastRnd, g_iOnline, g_iUserVote[33], g_iTimes,
	g_iMenuPosition[33], g_iMenuVote;

new bool:g_bIsRTV, Float:g_flTimeRTV, g_iBitUserRTV, g_iNumRTV;

new Array:g_asMap, Array:g_aiMinOnline, Array:g_aiMaxOnline, Array:g_afKnockMulti, Array:g_afKnockMulDuck,
	Array:g_asMapVote, Array:g_aiVotes, g_iThisMap;

new g_aLastMaps[LASTMAP_MAX], g_iLastlen, g_blastMaps = true;

new g_iUserShuffle[33][MAP_MAX];

public plugin_init()
{
	register_plugin("Mapchooser", "1.0", "Docaner");

	register_event("HLTV", "Event_HLTV", "a", "1=0", "2=0")

	new const szTimeLeft[][] = {"timeleft", "say /timeleft", "say_team /timeleft", "say timeleft", "say_team timeleft"};
	for(new i; i < sizeof szTimeLeft; i++)
		register_clcmd(szTimeLeft[i], "ClCmd_TimeLeft");

	new const szRTV[][] = 
	{
		"rtv", "say rtv", "say_team rtv", "say /rtv", "say_team /rtv",
		"votemap", "say votemap", "say_team votemap", "say /votemap", "say_team /votemap"
	};

	for(new i; i < sizeof szRTV; i++)
		register_clcmd(szRTV[i], "ClCmd_RTV");


	new const iBitKeys = 0x3FF;
	register_menucmd(g_iMenuVote = register_menuid("Show_VoteMenu"), 	iBitKeys, 	"Handle_VoteMenu");

	g_iMsgID_ScreanFade = get_user_msgid("ScreenFade");
}

public plugin_cfg()
{
	pause ("dc", "nextmap.amxx")
	pause ("dc", "timeleft.amxx")
	pause ("dc", "mapchooser.amxx")

	g_pCvarTimeLimit = get_cvar_pointer("mp_timelimit");
	//g_pCvarRoundTime = get_cvar_pointer("mp_roundtime");
	g_pCvarFreezeTime = get_cvar_pointer("mp_freezetime");
	g_pCvarTimeLeft = get_cvar_pointer("mp_timeleft");
	
	g_pCvarNextMap = register_cvar("amx_nextmap", "", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY);

	load_maps();
	load_lastmaps();



	hook_cvar_change(g_pCvarTimeLeft, "Cvar_ChangeTimeLeft");

	new Float:flTimeRTV = RTV_TIMEENABLE*60.0
	g_flTimeRTV = get_gametime() + flTimeRTV;
	set_task(flTimeRTV, "task_TimeRTVEnable");
}

public plugin_natives()
{
	register_native("zp_check_vote", "zp_check_vote", 1);
	register_native("zp_start_mapchoosing", "prepare_to_vote", 1);
}

public plugin_end()
{
	if(g_bTimeLimit) set_pcvar_float(g_pCvarTimeLimit, g_fOldTimeLimit);
	if(g_bFreezeTime) set_pcvar_float(g_pCvarFreezeTime, g_fOldFreezeTime);

	ArrayDestroy(g_asMap);
	ArrayDestroy(g_aiMinOnline);
	ArrayDestroy(g_aiMaxOnline);
	ArrayDestroy(g_afKnockMulti);
	ArrayDestroy(g_afKnockMulDuck);
}

public client_putinserver(id)
	if(!is_user_bot(id)) g_iOnline++;

public client_disconnected(id, bool:drop, message[], maxlen)
{
	if(!is_user_bot(id))
	{
		if(is_user_connected(id)) g_iOnline--;

		if(g_bIsVote && g_iUserVote[id] != -1)
		{
			new iVotes = ArrayGetCell(g_aiVotes, g_iUserVote[id]);
			ArraySetCell(g_aiVotes, g_iUserVote[id], iVotes - 1);
			g_iUserVote[id] = -1;
		}
	}
}

public Event_HLTV()
{
	if(g_bIsLastRnd && !g_bIsVote)
	{
		if(g_iOnline) 
			prepare_to_vote();
		else 
			task_changelevel();
	}
}

public ClCmd_TimeLeft(id)
{
	if(g_bIsLastRnd) UTIL_SayText(id, "!g[ZP|MAP] !yВремя карты истекло: Последний раунд!");
	else
	{
		new szTimeLeft[16]; get_pcvar_string(g_pCvarTimeLeft, szTimeLeft, charsmax(szTimeLeft));
		UTIL_SayText(id, "!g[ZP|MAP] !yГолосование за карту произойдёт через: !g%s", szTimeLeft);
	}

	return PLUGIN_HANDLED_MAIN;
}

public prepare_to_vote()
{
	g_bIsVote = true;

	set_pcvar_float(g_pCvarTimeLimit, 0.0);

	g_fOldFreezeTime = get_pcvar_float(g_pCvarFreezeTime);
	g_bFreezeTime = true;

	set_pcvar_float(g_pCvarFreezeTime, float(TIME_TOVOTE) + 8.0);

	arrayset(g_iUserVote, -1, sizeof g_iUserVote);
	arrayset(g_iMenuPosition, 0, sizeof g_iMenuPosition);

	start_vote();
}


start_vote()
{
	new Array:asMaps = ArrayCreate(32);

	new szMap[32], iMin, iMax

	for(new i; i < ArraySize(g_asMap); i++)
	{
		if(g_iThisMap == i || g_blastMaps && array_find_value(g_aLastMaps, g_iLastlen, i) != -1) continue;

		iMin = ArrayGetCell(g_aiMinOnline, i);
		iMax = ArrayGetCell(g_aiMaxOnline, i);

		if(iMin == 0 && iMax == 0 || g_iOnline <= iMax && g_iOnline >= iMin)
		{
			ArrayGetString(g_asMap, i, szMap, charsmax(szMap));
			ArrayPushString(asMaps, szMap);
		}
	}

	if(ArraySize(asMaps) <= MAP_MAX)
		g_asMapVote = ArrayClone(asMaps);
	else if(ArraySize(asMaps))
	{
		g_asMapVote = ArrayCreate(32);

		new iRandom;

		for(new i; i < MAP_MAX; i++)
		{
			iRandom = random_num(0, ArraySize(asMaps) - 1);

			ArrayGetString(asMaps, iRandom, szMap, charsmax(szMap));
			ArrayPushString(g_asMapVote, szMap);

			ArrayDeleteItem(asMaps, iRandom);
		}
	}

	ArrayDestroy(asMaps);

	g_aiVotes = ArrayCreate();
	
	for(new i; i < ArraySize(g_asMapVote); i++)
		ArrayPushCell(g_aiVotes, 0);

	g_iTimes = TIME_TOVOTE + 1;

	shuffleAllUsers(ArraySize(g_asMapVote));
	top5_camera_start();
	task_vote();
	set_task(1.0, "task_vote", TASK_VOTE, _, _, "a", g_iTimes);
}

stock shuffleAllUsers(iSize) 
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		shuffleUser(iPlayer, iSize)

stock shuffleUser(iPlayer, iSize)
{
	arrayset(g_iUserShuffle[iPlayer], -1, sizeof g_iUserShuffle[]);
	
	new left = iSize, iRandom, iShuffleIndex;

	for(new i; i < iSize; i++, left--, iShuffleIndex = 0)
	{
		iRandom = random(left);
		
		for(new j = 0; j <= iRandom; j++, iShuffleIndex++) 
			if(g_iUserShuffle[iPlayer][iShuffleIndex] != -1) j--;

		iShuffleIndex--;

		g_iUserShuffle[iPlayer][iShuffleIndex] = i;
	}
}

public task_vote()
{
	if(--g_iTimes)
	{
		for(new i = 1; i <= get_maxplayers(); i++)
		{
			if(!is_user_connected(i)) continue;
			Show_VoteMenu(i, g_iMenuPosition[i]);
		}

		// if(g_iTimes <= 5) client_cmd(0, "spk %s", g_szEndingSounds[g_iTimes - 1]);

		// SCREEN_FADE(0, 1, 1, 4, 0, 0, 0, 255)
	}
	else
	{
		new iMenu, iKeys
		for(new i = 1; i <= get_maxplayers(); i++)
		{
			if(!is_user_connected(i)) continue;
			
			get_user_menu(i, iMenu, iKeys);
		
			if(g_iMenuVote == iMenu) 
				show_menu(i, 0, "^n");
		}

		// SCREEN_FADE(0, 4096, 1024, 2, 0, 0, 0, 255)

		new iMax = 0, iVotes, i;

		for(i = 0; i < ArraySize(g_aiVotes); i++)
		{
			iVotes = ArrayGetCell(g_aiVotes, i)
			if(iMax < iVotes)
				iMax = iVotes;
		}

		new Array:aMapsWin = ArrayCreate(32), szMap[32];
		
		for(i = 0; i < ArraySize(g_aiVotes); i++)
		{
			iVotes = ArrayGetCell(g_aiVotes, i)
			if(iMax == iVotes)
			{
				ArrayGetString(g_asMapVote, i, szMap, charsmax(szMap));
				ArrayPushString(aMapsWin, szMap);
			}
		}

		new iNextMap = random_num(0, ArraySize(aMapsWin) - 1);
		ArrayGetString(aMapsWin, iNextMap, g_szNextMap, charsmax(g_szNextMap));
		set_pcvar_string(g_pCvarNextMap, g_szNextMap);

		g_bIsVote = false;

		ArrayDestroy(aMapsWin);
		ArrayDestroy(g_asMapVote);
		ArrayDestroy(g_aiVotes);

		UTIL_SayText(0, "!g[ZP|MAP] !yГолосование завершено! Следующая карта: !g%s", g_szNextMap);

		// message_begin(MSG_ALL, SVC_INTERMISSION);
		// message_end();

		// client_cmd(0, "spk %s", g_szEndSounds[random_num(0, charsmax(g_szEndSounds))]);

		set_task(5.0, "task_changelevel");
	}
}

Show_VoteMenu(id, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;

	new iStringsCount = ArraySize(g_asMapVote);

	new iPagesNum = (iStringsCount / PLAYERS_PER_PAGE + ((iStringsCount % PLAYERS_PER_PAGE) ? 1 : 0));
	
	if(iPos >= iPagesNum)
		return Show_VoteMenu(id, iPagesNum - 1);

	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iStringsCount) iStart = iStringsCount;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iStringsCount) iEnd = iStringsCount;

	new szPage[8]; 

	if(iPagesNum > 1) 
		formatex(szPage, charsmax(szPage), " \w[%d|%d]", iPos + 1, iPagesNum)

	new szMenu[512], 
		iLen = formatex(szMenu, charsmax(szMenu), "\yГолосование за карту:%s^n\wДо конца голосования осталось \r%d с^n^n", szPage, g_iTimes);

	new iKeys = (1<<10), b, szMap[32], iVotes;
	for(new a = iStart; a < iEnd; a++)
	{
		ArrayGetString(g_asMapVote, g_iUserShuffle[id][a], szMap, charsmax(szMap));
		iVotes = ArrayGetCell(g_aiVotes, g_iUserShuffle[id][a]);

		if(g_iUserVote[id] == -1)
		{
			iKeys |= (1<<b);
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s \r[%d]^n", ++b, szMap, iVotes);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. %s%s \r[%d]^n", ++b, g_iUserVote[id] == g_iUserShuffle[id][a] ? "\y" : "\d", szMap, iVotes);
	}

	if(iPagesNum > 1)
	{
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
	}

	//Если указать битсуму iKeys = 0, то тогда меню не откроется
	//Поэтому iKeys = (1<<10) - Бит который не используется в меню
	return show_menu(id, iKeys, szMenu, -1, "Show_VoteMenu")
}

public Handle_VoteMenu(id, iKey)
{
	switch(iKey)
	{
		case 7: return Show_VoteMenu(id, --g_iMenuPosition[id])
		case 8: return Show_VoteMenu(id, ++g_iMenuPosition[id])
		default:
		{			
			new iTarget = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
			new iMap = g_iUserShuffle[id][iTarget];

			g_iUserVote[id] = iMap;
			
			new iVotes = ArrayGetCell(g_aiVotes, iMap);
			ArraySetCell(g_aiVotes, iMap, iVotes + 1);

			new szName[32]; get_user_name(id, szName, charsmax(szName));
			new szMap[32]; ArrayGetString(g_asMapVote, iMap, szMap, charsmax(szMap));

			UTIL_SayText(0, "!g[ZP|MAP] !yИгрок !g%s !yпроголосовал за карту !g%s", szName, szMap);
		}
	}
	return Show_VoteMenu(id, g_iMenuPosition[id]);
}

public task_changelevel() 
	server_cmd("changelevel %s", g_szNextMap);

public Cvar_ChangeTimeLeft(pCvar, const szOldValue[], const szNewValue[])
{
	if(equal(szNewValue, "00:00"))
	{
		set_last_round();
	}
}

public ClCmd_RTV(id)
{
	if(g_bIsLastRnd)
	{
		UTIL_SayText(id, "!g[ZP|MAP] !yПоследний раунд!");
		return;
	}

	if(!g_bIsRTV)
	{
		new szTime[8]; format_time(szTime, charsmax(szTime), "%M:%S", floatround(g_flTimeRTV - get_gametime(), floatround_ceil));

		UTIL_SayText(id, "!g[ZP|MAP] !yВозможность проголосовать будет доступна через !g%s!y.", szTime);
		return;
	}

	new iNeedTotalVotes = floatround(float(g_iOnline) * RTV_NUMENABLE);
	
	if(IsSetBit(g_iBitUserRTV, id))
	{
		if(g_iNumRTV >= iNeedTotalVotes)
		{
			set_last_round();
			return;
		}

		UTIL_SayText(id, "!g[ZP|MAP] !yВы уже проголосавали! Не хватает !t%d !yголосов", iNeedTotalVotes - g_iNumRTV);
		return;
	}

	SetBit(g_iBitUserRTV, id);
	g_iNumRTV++;

	if(g_iNumRTV >= iNeedTotalVotes)
	{
		set_last_round(true);
		return;
	}
	else UTIL_SayText(id, "!g[ZP|MAP] !yВы успешно проголосовали! Не хватает !t%d !yголосов", iNeedTotalVotes - g_iNumRTV);
}


public task_TimeRTVEnable()
{
	g_bIsRTV = true;

	UTIL_SayText(0, "!g[ZP|MAP] !yВключено досрочное голосование за смену карты!")
	UTIL_SayText(0, "!g[ZP|MAP] !yДля голосования введите в чат команду: !trtv")
}


set_last_round(bool:bRTV = false)
{
	if(g_bIsLastRnd) return false;

	g_bIsLastRnd = true;

	new Float:fTimeLimit = get_pcvar_float(g_pCvarTimeLimit);
	// new Float:fRoundTime = get_pcvar_float(g_pCvarRoundTime);
	set_pcvar_float(g_pCvarTimeLimit, 0.0);

	g_fOldTimeLimit = fTimeLimit;
	g_bTimeLimit = true;
	
	if(bRTV)
		UTIL_SayText(0, "!g[ZP|MAP] !yНабрано нужное количество голосов! Голосование будет проведено в следующем раунде!");
	else	
		UTIL_SayText(0, "!g[ZP|MAP] !yВремя карты истекло! Голосование будет проведено в следующем раунде!");
	
	set_hudmessage(50, 255, 50, -1.0, 0.2, 0, 0.0, 5.0, 1.0, 1.0 );
	show_hudmessage(0, "Последний раунд!^nИграем из последних сил!");

	return true;
}

load_maps()
{
	if(!file_exists(g_szFile))
		set_fail_state("Файл ^"%s^" не был найден. Плагин остановлен.", g_szFile)

	g_asMap = ArrayCreate(32);
	g_aiMinOnline = ArrayCreate();
	g_aiMaxOnline = ArrayCreate();
	g_afKnockMulti = ArrayCreate();
	g_afKnockMulDuck = ArrayCreate();


	new szThisMap[32]; get_mapname(szThisMap, charsmax(szThisMap));
	new Array:aTempMap = ArrayCreate(32);

	new szBuffer[512], iLine, iLen, 
		szMap[32], szMinOnline[4], szMaxOnline[4], szKnockMul[16], szKnockMulDuck[16], iMin, iMax, Float:flKnockMul, Float:flKnockMulDuck;
	while(read_file(g_szFile, iLine++, szBuffer, charsmax(szBuffer), iLen))
	{
		if(!iLen || szBuffer[0] == ';')
			continue
		
		szMinOnline = "";
		szMaxOnline = "";
		szKnockMul = "";
		szKnockMulDuck = "";

		parse(szBuffer, szMap, charsmax(szMap), szMinOnline, charsmax(szMinOnline), szMaxOnline, charsmax(szMaxOnline), szKnockMul, charsmax(szKnockMul), szKnockMulDuck, charsmax(szKnockMulDuck));

		formatex(szBuffer, charsmax(szBuffer), "maps/%s.bsp", szMap)

		if(!file_exists(szBuffer))
		{
			log_amx("Карта ^"%s^" не была найдена", szMap);
			continue;
		}

		if(ArrayFindString(g_asMap, szMap) != -1)
		{
			log_amx("Карта ^"%s^" прописана в ini несколько раз", szMap);
			continue;
		}

		iMin = is_str_num(szMinOnline) ? str_to_num(szMinOnline) : 0;
		iMax = is_str_num(szMaxOnline) ? str_to_num(szMaxOnline) : 0;
		
		flKnockMul = str_to_float(szKnockMul);
		if(flKnockMul == 0.0) flKnockMul = 1.0;

		flKnockMulDuck = str_to_float(szKnockMulDuck);

		ArrayPushString(g_asMap, szMap);
		ArrayPushCell(g_aiMinOnline, iMin);
		ArrayPushCell(g_aiMaxOnline, iMax);
		ArrayPushCell(g_afKnockMulti, flKnockMul);
		ArrayPushCell(g_afKnockMulDuck, flKnockMulDuck);


		if(equal(szThisMap, szMap))
		{
			g_iThisMap = ArraySize(g_asMap) - 1;
			zp_set_base_knock(zp_get_base_knock() * flKnockMul);

			if(flKnockMulDuck > 0.0) zp_set_mul_duck_knock(flKnockMulDuck);
			//console_print(0, "THIS MAP: %s | flKnockMul: %f | flKnockMulDuck: %f", szThisMap, zp_get_base_knock(), zp_get_mul_duck_knock());
		}

		//console_print(0, "szMap: %s | flKnockMul: %f | flKnockMulDuck: %f", szMap, flKnockMul, flKnockMulDuck);

		if(iMin == 0)
			ArrayPushString(aTempMap, szMap);	
	}

	if(!ArraySize(g_asMap))
	{
		ArrayDestroy(g_asMap);
		ArrayDestroy(g_aiMinOnline);
		ArrayDestroy(g_aiMaxOnline);
		ArrayDestroy(g_afKnockMulti);
		ArrayDestroy(aTempMap);

		set_fail_state("Карты не были найдены. Плагин остановлен")
	}

	if(!ArraySize(aTempMap))
	{
		ArrayDestroy(g_asMap);
		ArrayDestroy(g_aiMinOnline);
		ArrayDestroy(g_aiMaxOnline);
		ArrayDestroy(g_afKnockMulti);
		ArrayDestroy(aTempMap);

		set_fail_state("Добавьте минимум 2 карты для 0-го онлайна. Плагин остановлен")
	}

	new iRandom = random_num(0, ArraySize(aTempMap) - 1);
	ArrayGetString(aTempMap, iRandom, g_szNextMap, charsmax(g_szNextMap));
	set_pcvar_string(g_pCvarNextMap, g_szNextMap);

	ArrayDestroy(aTempMap)
}

load_lastmaps()
{
	new JSON:j = json_parse(g_szFileLast, true);

	new szThisMap[33]; get_mapname(szThisMap, charsmax(szThisMap));

	if(j == Invalid_JSON)
	{
		j = json_init_object();
		json_object_set_string(j, "map1", szThisMap);
		json_serial_to_file(j, g_szFileLast, true);
		json_free(j);
		return;
	}

	new szKey[8], szMap[32], a;

	for(new i = 1; i <= LASTMAP_MAX; i++)
	{
		formatex(szKey, charsmax(szKey), "map%d", i);

		json_object_get_string(j, szKey, szMap, charsmax(szMap));

		a = ArrayFindString(g_asMap, szMap);

		if(a != -1)
			g_aLastMaps[g_iLastlen++] = a;
	}
	json_free(j);

	new JSON:jnew = json_init_object();

	json_object_set_string(jnew, "map1", szThisMap);
	new iNum = 2

	for(new a; a < g_iLastlen && iNum <= LASTMAP_MAX; a++)
	{
		formatex(szKey, charsmax(szKey), "map%d", iNum++);

		ArrayGetString(g_asMap, g_aLastMaps[a], szMap, charsmax(szMap));

		json_object_set_string(jnew, szKey, szMap);
	}

	if(ArraySize(g_asMap) <= g_iLastlen + 1)
		g_blastMaps = false;
	else
		g_blastMaps = true;

	json_serial_to_file(jnew, g_szFileLast, true);
	json_free(jnew);
	return;
}


stock array_find_value(aArray[], iLen, iValue)
{
	for(new i; i < iLen; i++)
		if(aArray[i] == iValue) 
			return i;

	return -1;
}

public zp_check_vote() return g_bIsVote;

stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190]
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3)
	else copy(szBuffer, charsmax(szBuffer), szMessage)
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	switch(pPlayer)
	{
		case 0:
		{
			for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++)
			{
				if(!is_user_connected(iPlayer)) continue
				message_begin_f(MSG_ONE_UNRELIABLE, MsgId_SayText, Float:{0.0, 0.0, 0.0}, iPlayer)
				write_byte(iPlayer)
				write_string(szBuffer)
				message_end()
			}
		}
		default:
		{
			message_begin_f(MSG_ONE_UNRELIABLE, MsgId_SayText, Float:{0.0, 0.0, 0.0}, pPlayer)
			write_byte(pPlayer)
			write_string(szBuffer)
			message_end()
		}
	}
}
stock SCREEN_FADE(id, iDuration, iHoldtime, iFadeType, iRed, iGreen, iBlue, iAlpha)
{
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_ALL, g_iMsgID_ScreanFade, _, id)
	write_short(iDuration) // duration
	write_short(iHoldtime) // hold time
	write_short(iFadeType) // fade type
	write_byte(iRed) // r
	write_byte(iGreen) // g
	write_byte(iBlue) // b
	write_byte(iAlpha) // alpha
	message_end()

}