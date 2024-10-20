#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <api_flame>
#include <zc_addon_zclasses>
#include <zc_addon_zchoose>

// CBasePlayerItem
#define MsgId_SayText 76

new g_iZClassClassic;

public plugin_init()
{
	register_plugin("[ZM] ZClass: Classic", "1.0", "by TrueMan :3");
	register_dictionary( "zp_cso_classes.txt" )
	g_iZClassClassic = zc_find_zclass_by_shortname("classic");
}

public zp_user_infected_post(iPlayer, infector)
{
	if(zp_get_user_zombie(iPlayer) && zc_get_user_zclass(iPlayer) == g_iZClassClassic && !zp_get_user_nemesis(iPlayer))
	{
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yСпособность !g[Время горения снижено]!y")
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yВремя горения: !gСнижено в 2 раза!y | Активно: !gвсегда")
	}
}

public zp_flame_params_change_post(const pEntBase, const pVictim, const pAttacker, const Float:flSeconds)
{
	if(!zp_get_user_zombie(pVictim) || zc_get_user_zclass(pVictim) != g_iZClassClassic)
		return;

	set_entvar(pEntBase, var_ltime, get_gametime() + flSeconds / 2.0);
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