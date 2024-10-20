#include <amxmodx>

/*
	Натив открытия выдачи админок:
	native zp_menu_admin_give(id);
*/
/*
	Команда для открытия меню:
	admin_give
*/

//Флаг доступа к меню выдачи привилегий
#define ACCESS_FLAG ADMIN_RCON

//Название привилегий
new const g_szNameAdmins[][] =
{
	"BOOST",
	"VIP-клиент",
	"PREMIUM-доступ",
	"AGENT",
}

//Флаги админов для привилегий
new const g_szFlags[][] =
{
	"o",
	"t",
	"pt",
	"pst"
}

#define MsgId_SayText 76

#define PLAYERS_PER_PAGE 7
#define PLAYERS_PER_PAGE_OTHER 6

new g_iMenuPosition[33], g_iMenuPlayers[33][32], g_iMenuChoose[33];

public plugin_init()
{
	register_plugin("Admin Give Menu", "1.0", "Docaner")
	
	new const iBitKeys = 0x3FF;
	register_menucmd(register_menuid("Show_MenuPlayers"), 	iBitKeys, 	"Handle_MenuPlayers");
	register_menucmd(register_menuid("Show_MenuAdmins"), 	iBitKeys, 	"Handle_MenuAdmins");

	// register_clcmd("admin_give", "CMD_MenuPlayers");
}

public plugin_natives()
	register_native("zp_menu_admin_give", "CMD_MenuPlayers", 1);

public CMD_MenuPlayers(id) 
{
	if(~get_user_flags(id) & ACCESS_FLAG)
	{
		UTIL_SayText(id, "!g[ZP] !yУ вас нет доступа.");
		return PLUGIN_HANDLED;
	}
	return Show_MenuPlayers(id, g_iMenuPosition[id] = 0);
}

Show_MenuPlayers(id, iPos)
{
	if(iPos < 0 || ~get_user_flags(id) & ACCESS_FLAG) return PLUGIN_HANDLED;

	new iStringsCount;
	for(new i = 1; i <= get_maxplayers(); i++)
	{
		if(!is_user_connected(i) || is_user_bot(i) || i == id) continue;
		g_iMenuPlayers[id][iStringsCount++] = i;
	}

	if(!iStringsCount)
	{
		UTIL_SayText(id, "!g[ZP] !yНа сервере отсутствуют игроки!");
		return PLUGIN_HANDLED;
	}

	new iPagesNum = (iStringsCount / PLAYERS_PER_PAGE_OTHER + ((iStringsCount % PLAYERS_PER_PAGE_OTHER) ? 1 : 0));
	
	if(iPos >= iPagesNum)
		return Show_MenuPlayers(id, iPagesNum - 1);

	new iStart = iPos * PLAYERS_PER_PAGE_OTHER;
	if(iStart > iStringsCount) iStart = iStringsCount;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE_OTHER);
	new iEnd = iStart + PLAYERS_PER_PAGE_OTHER;
	if(iEnd > iStringsCount) iEnd = iStringsCount;

	new szMenu[512], 
		iLen = formatex(szMenu, charsmax(szMenu), "\yКому выдать привилегию? \w[%d|%d]^n^n", iPos + 1, iPagesNum);

	new iKeys = (1<<6|1<<9), b, szName[32], szFlags[33];
	for(new a = iStart; a < iEnd; a++)
	{
		iKeys |= (1<<b);

		get_user_name(g_iMenuPlayers[id][a], szName, charsmax(szName));
		get_flags(get_user_flags(g_iMenuPlayers[id][a]), szFlags, charsmax(szFlags));
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s \r[%s]^n", ++b, szName, szFlags);
	}

	for(new i = b; i < PLAYERS_PER_PAGE_OTHER; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n")

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r7. \yВсем^n")

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
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wВыход")

	return show_menu(id, iKeys, szMenu, -1, "Show_MenuPlayers")
}

public Handle_MenuPlayers(id, iKey)
{
	if(~get_user_flags(id) & ACCESS_FLAG) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 6:
		{
			g_iMenuChoose[id] = 0;
			return CMD_MenuAdmins(id);
		}
		case 7: return Show_MenuPlayers(id, --g_iMenuPosition[id])
		case 8: return Show_MenuPlayers(id, ++g_iMenuPosition[id])
		case 9: return PLUGIN_HANDLED;
		default:
		{
			new iTarget = g_iMenuPosition[id] * PLAYERS_PER_PAGE_OTHER + iKey;

			if(!is_user_connected(g_iMenuPlayers[id][iTarget]) && is_user_bot(g_iMenuChoose[id]))
			{
				UTIL_SayText(id, "!g[ZP] !yИгрок вышел с сервера");
				return Show_MenuPlayers(id, g_iMenuPosition[id]);
			}
			
			g_iMenuChoose[id] = g_iMenuPlayers[id][iTarget];
			return CMD_MenuAdmins(id);
		}
	}
	return Show_MenuPlayers(id, g_iMenuPosition[id])
}

public CMD_MenuAdmins(id) return Show_MenuAdmins(id, g_iMenuPosition[id] = 0);
Show_MenuAdmins(id, iPos)
{
	if(iPos < 0 || ~get_user_flags(id) & ACCESS_FLAG) return PLUGIN_HANDLED;

	new iStringsCount = sizeof g_szNameAdmins;

	if(!iStringsCount)
	{
		UTIL_SayText(id, "!g[ZP] !yПривилегии не загружены!");
		return PLUGIN_HANDLED;
	}

	new iPagesNum = (iStringsCount / PLAYERS_PER_PAGE + ((iStringsCount % PLAYERS_PER_PAGE) ? 1 : 0));
	
	if(iPos >= iPagesNum)
		return Show_MenuAdmins(id, iPagesNum - 1);

	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iStringsCount) iStart = iStringsCount;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iStringsCount) iEnd = iStringsCount;

	new szTmp[128]; 

	if(g_iMenuChoose[id])
	{
		new szName[32], szFlags[32];
		get_user_name(g_iMenuChoose[id], szName, charsmax(szName));
		get_flags(get_user_flags(g_iMenuChoose[id]), szFlags, charsmax(szFlags));
		formatex(szTmp, charsmax(szTmp), "\yНик: \w%s \r[%s]\y", szName, szFlags);
	}
	else 
		szTmp = "\yВыдать всем";

	new szMenu[512], 
		iLen = formatex(szMenu, charsmax(szMenu), "\yКакую привилегию выдать? \w[%d|%d]^n%s^n^n", iPos + 1, iPagesNum, szTmp);

	new iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s \r[%s]^n", ++b, g_szNameAdmins[a], g_szFlags[a]);
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
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wИзменить выбор")

	return show_menu(id, iKeys, szMenu, -1, "Show_MenuAdmins")
}

public Handle_MenuAdmins(id, iKey)
{
	if(~get_user_flags(id) & ACCESS_FLAG) return PLUGIN_HANDLED;
	switch(iKey)
	{
		case 7: return Show_MenuAdmins(id, --g_iMenuPosition[id])
		case 8: return Show_MenuAdmins(id, ++g_iMenuPosition[id])
		case 9: return CMD_MenuPlayers(id);
		default:
		{
			if(g_iMenuChoose[id] && !is_user_connected(g_iMenuChoose[id]) && is_user_bot(g_iMenuChoose[id]))
			{
				UTIL_SayText(id, "!g[ZP] !yИгрок вышел с сервера");
				return CMD_MenuPlayers(id);
			}
			
			new iTarget = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
			new iBitFlags = read_flags(g_szFlags[iTarget]);
			
			new szNameAdmin[32]; get_user_name(id, szNameAdmin, charsmax(szNameAdmin));

			if(g_iMenuChoose[id])
			{
				new szNameUser[32]; get_user_name(g_iMenuChoose[id], szNameUser, charsmax(szNameUser));
				
				if(~get_user_flags(g_iMenuChoose[id]) & iBitFlags)
				{
					remove_user_flags(g_iMenuChoose[id], ADMIN_USER);
					set_user_flags(g_iMenuChoose[id], iBitFlags);
				
					set_dhudmessage(0, 125, 200, -1.0, 0.4, 0, 0.0, 5.0, 1.0, 1.0 );
					show_dhudmessage(g_iMenuChoose[id], "Админ %s выдал Вам %s на карту!", szNameAdmin, g_szNameAdmins[iTarget]);

					UTIL_SayText(0, "!g[ZP] !yАдмин !g%s !yвыдал !g%s !yигроку !g%s !yна карту", szNameAdmin, g_szNameAdmins[iTarget], szNameUser);
				}
				else UTIL_SayText(id, "!g[ZP] !yИгрок !g%s !yуже имеет !g%s", szNameUser, g_szNameAdmins[iTarget]);

				return CMD_MenuPlayers(id);
			}
			else
			{
				for(new i = 1; i < get_maxplayers(); i++)
				{
					if(!is_user_connected(i) || i == id || get_user_flags(i) & iBitFlags) continue;

					remove_user_flags(i, ADMIN_USER);
					set_user_flags(i, iBitFlags);

					set_dhudmessage(0, 125, 200, -1.0, 0.4, 0, 0.0, 5.0, 1.0, 1.0 );
					show_dhudmessage(i, "Админ %s выдал Вам %s на карту!", szNameAdmin, g_szNameAdmins[iTarget]);
				}

				UTIL_SayText(0, "!g[ZP] !yАдмин !g%s !yвыдал !g%s !yвсем на карту", szNameAdmin, g_szNameAdmins[iTarget]);
			
				return PLUGIN_HANDLED;
			}
		}
	}
	return Show_MenuAdmins(id, g_iMenuPosition[id]);
}


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