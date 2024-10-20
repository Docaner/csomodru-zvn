#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
#include < zombieplague >
#include <zc_addon_zclasses>
#include <zc_addon_zchoose>

#define linux_diff_weapon 		4
#define linux_diff_player 		5

// CBasePlayerItem
#define MsgId_SayText 76

new g_iZClassInvis;

public plugin_init( )
{
	register_plugin("[ZM] ZClass: Fast", "1.0", "by TrueMan :3");
	register_dictionary( "zp_cso_classes.txt" )
	g_iZClassInvis = zc_find_zclass_by_shortname("fast");
}

public plugin_precache()
{
}

public zp_user_infected_post(iPlayer, infector)
{
	if(zp_get_user_zombie(iPlayer) && zc_get_user_zclass(iPlayer) == g_iZClassInvis && !zp_get_user_nemesis(iPlayer))
	{
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yСпособность !g[Увеличенная скорость]!y")
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yВремя увеличенной скорости: !gВсегда активно!y")
	}
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