#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <api_flame>

#define linux_diff_weapon 		4
#define linux_diff_player 		5

// CBasePlayerItem
#define MsgId_SayText 76

#define ZM_CLASS_NAME		"ML_CLASSIC_NAME"
#define ZM_CLASS_INFO		"ML_CLASSIC_INFO"
#define ZM_CLASS_MODEL		"zp_br_classic_b10"
#define ZM_CLASS_CLAW		"claws_classic_b11.mdl"
#define ZM_CLASS_HEALTH		1750
#define ZM_CLASS_SPEED		240
#define ZM_CLASS_GRAVITY	0.90
#define ZM_CLASS_KNOCK		0.47

new g_iZClassClassic;

public plugin_init( )
{
	register_plugin("[ZM] ZClass: Classic", "1.0", "by TrueMan :3");
	register_dictionary( "zp_cso_classes.txt" )
}

public plugin_precache()
{
	g_iZClassClassic = zp_register_zombie_class( ZM_CLASS_NAME, ZM_CLASS_INFO, ZM_CLASS_MODEL, ZM_CLASS_CLAW, ZM_CLASS_HEALTH, ZM_CLASS_SPEED, ZM_CLASS_GRAVITY, ZM_CLASS_KNOCK );
}

public zp_user_infected_post(iPlayer, infector)
{
	if(zp_get_user_zombie(iPlayer) && zp_get_user_zombie_class(iPlayer) == g_iZClassClassic && !zp_get_user_nemesis(iPlayer))
	{
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yСпособность !g[Время горения снижено]!y")
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yВремя горения: !gСнижено в 2 раза!y | Активно: !gвсегда")
	}
}

public zp_flame_params_change_post(const pEntBase, const pVictim, const pAttacker, const Float:flSeconds)
{
	if(!zp_get_user_zombie(pVictim) || zp_get_user_zombie_class(pVictim) != g_iZClassClassic)
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