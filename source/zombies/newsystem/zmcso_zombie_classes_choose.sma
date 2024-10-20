#include <amxmodx>
#include <zombieplague>
#include <api_identifier>
#include <zc_addon_zclasses>
#include <zc_addon_zchoose>

#define PLAYERS_PER_PAGE 7

new g_iMenuPosition[33];

public plugin_init()
{
	register_plugin("[ZC] Addon ZClasses: Choose", "1.0", "Docaner");
	register_clcmd("zclassmenu", "@ClCmd_ZClassMenu");

	register_menucmd(register_menuid("Show_ZClassMenu"), 1023, "@Handle_ZClassMenu")
	register_menucmd(register_menuid("Show_ZClassInfo"), 1023, "@Handle_ZClassInfo")
}

public zp_user_infected_pre(id, infector, nemesis)
{
	new iClass = zc_get_user_zclass(id),
		iNextClass = zc_get_user_next_zclass(id);

	if(iClass != iNextClass)
		zc_set_user_zclass(id, iNextClass);
}

@ClCmd_ZClassMenu(id) return Show_ZClassMenu(id, g_iMenuPosition[id] = 0);
stock Show_ZClassMenu(id, iPos)
{
    if(iPos < 0) return PLUGIN_HANDLED;

    new iStringsCount = zc_get_zclasses_count();

    if(!iStringsCount)
    {
        client_print_color(id, id, "^4[ZP] ^1Классы не загружены");
        return PLUGIN_HANDLED;
    }

    new iPagesNum = (iStringsCount / PLAYERS_PER_PAGE + ((iStringsCount % PLAYERS_PER_PAGE) ? 1 : 0));

    if(iPos >= iPagesNum)
        return Show_ZClassMenu(id, iPagesNum - 1);

    new iStart = iPos * PLAYERS_PER_PAGE;
    if(iStart > iStringsCount) iStart = iStringsCount;
    iStart = iStart - (iStart % PLAYERS_PER_PAGE);
    new iEnd = iStart + PLAYERS_PER_PAGE;
    if(iEnd > iStringsCount) iEnd = iStringsCount;

    new szMenu[512], 
        iLen = formatex(szMenu, charsmax(szMenu), "\y• Выберете зомби класс • \w[%d|%d]^n^n", iPos + 1, iPagesNum);

    new iKeys = (1<<9), b, 
    	iClass = zc_get_user_next_zclass(id),
    	szName[ZMClassNameLen];

    for(new a = iStart; a < iEnd; a++)
    {
        zc_get_zclass_name(a, szName, charsmax(szName));
        iKeys |= (1<<b);

        iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s%s^n", ++b, szName, (iClass == a) ? " \r«" : "");
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
    formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wВыход")

    return show_menu(id, iKeys, szMenu, -1, "Show_ZClassMenu")
}

@Handle_ZClassMenu(id, iKey)
{
 	switch(iKey)
    {
        case 7: return Show_ZClassMenu(id, --g_iMenuPosition[id])
        case 8: return Show_ZClassMenu(id, ++g_iMenuPosition[id])
        case 9: return PLUGIN_HANDLED;
        default:
        {
            new iTarget = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;

            zc_set_user_menu_zclass(id, iTarget);

            return Show_ZClassInfo(id, iTarget);
        }
    }
	return Show_ZClassMenu(id, g_iMenuPosition[id]);
}

stock Show_ZClassInfo(id, iClass)
{
	new szMenu[512], iLen, iKeys = (1<<0|1<<7|1<<9);
	
	new szName[ZMClassNameLen]; zc_get_zclass_name(iClass, szName, charsmax(szName));

	new iHealth = floatround(zc_get_zclass_health(iClass)),
		iMaxHealth = floatround(zc_get_zclass_maxhealth(iClass)),
		iSpeed = floatround(zc_get_zclass_speed(iClass)),
		Float:flGravity = zc_get_zclass_gravity(iClass);

	iLen = formatex(szMenu, charsmax(szMenu), "\y• Зомби-класс • : \w%s^n^n", szName);

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\wЗдоровье: \y%d \w| Макс. здоровье: \y%d^n", iHealth, iMaxHealth);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\wСкорость: \y%d \w| Гравитация: \y%.2f^n^n", iSpeed, flGravity);

	new szInfo[ZMClassInfoLen]; zc_get_zclass_info(iClass, szInfo, charsmax(szInfo));

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "%s^n^n", szInfo);

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \wВыбрать класс^n^n")

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r8. \wНазад^n")
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wВыход")

	return show_menu(id, iKeys, szMenu, _, "Show_ZClassInfo");
}

@Handle_ZClassInfo(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			new iMenuClass = zc_get_user_menu_zclass(id);
			zc_set_user_next_zclass(id, iMenuClass);

			new szName[ZMClassNameLen]; zc_get_zclass_name(iMenuClass, szName, charsmax(szName));
			client_print_color(id, id, "^4[CSOMOD] ^1Ваш класс после заражения: ^3%s", szName);
			
			return PLUGIN_HANDLED;
		}
		case 7: return Show_ZClassMenu(id, g_iMenuPosition[id]);
	}

	return PLUGIN_HANDLED;
}