#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
#include < zombieplague >

#define PLUGIN 		"[ZPE] Addon: WpnLevel"
#define VERSION		"1.0"
#define AUTHOR 		"DesortioN"	

#define is_player(%0)		(0<%0<33)
#define MAX_LEVEL			5
#define MAX_CLIENT			32

#define WPNLVL_DAMAGE 		9000.0

#define MsgId_SayText 		76

new iWpnLevel[33]
new Float:g_iDamageTaked[MAX_CLIENT +1]

new Float:User_Damage[] = {1.0, 1.15, 1.25, 1.35, 1.45, 1.55}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKiled")
}

public plugin_natives()
{
	register_native("zp_get_user_wpnlvl", "Native_Get_User_WpnLevel", 1)
	register_native("zp_user_wpnlvl_progress", "Native_User_WpnLevel_Progress", 1)
}

public plugin_precache()
{
	precache_generic("sound/zp_br_cso/other/level_up.wav")
}

public client_connect(id)
{
	iWpnLevel[id] = 0;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, iBitsDamage)
{
	if(!is_player(victim) || !is_user_alive(victim) || !is_player(attacker) || zp_get_user_survivor(attacker) || zp_get_user_zombie(attacker))
		return HAM_IGNORED;
		
	if(get_user_weapon(attacker) == CSW_KNIFE)
		return HAM_IGNORED;
		
	if(!(iBitsDamage & (DMG_BULLET | DMG_NEVERGIB)))
		return HAM_IGNORED;
	
	g_iDamageTaked[attacker] += damage;
	
	SetHamParamFloat(4, damage * User_Damage[iWpnLevel[attacker]])
	
	if(iWpnLevel[attacker] == MAX_LEVEL)
		return HAM_IGNORED;
	
	if(g_iDamageTaked[attacker] > WPNLVL_DAMAGE)
	{
		new szName[32]; 
		get_user_name(attacker, szName, 31);
				
		iWpnLevel[attacker]++;
		g_iDamageTaked[attacker] -= WPNLVL_DAMAGE;
			
		if(iWpnLevel[attacker] <= MAX_LEVEL-1) 
		{
			UTIL_SayText(attacker, "!g[Weapon] !yВы достигли !g[%d] !yуровня!", iWpnLevel[attacker]);
			client_cmd(attacker, "spk sound/zp_br_cso/other/level_up.wav")
		} 
		else 
		{
			UTIL_SayText(0, "!g[Weapon] !yИгрок !g%s !yдостиг !g[%d] !yуровня!", szName, iWpnLevel[attacker]);
			UTIL_SayText(0, "!g[Weapon] !yИгрок !g%s !yдостиг !g[%d] !yуровня!", szName, iWpnLevel[attacker]);
			UTIL_SayText(0, "!g[Weapon] !yИгрок !g%s !yдостиг !g[%d] !yуровня!", szName, iWpnLevel[attacker]);
			client_cmd(attacker, "spk sound/zp_br_cso/other/level_up.wav")
		}
	}
	
	return HAM_IGNORED;
}

public fw_PlayerKiled(victim, attacker, corpse)
{
	g_iDamageTaked[victim] = 0.0;
	iWpnLevel[victim] = 0;
}

public zp_user_infected_post(id, infector)
{
	g_iDamageTaked[id] = 0.0;
	iWpnLevel[id] = 0;
}

public zp_user_humanized_post(id, survivor)
{
	if(zp_get_user_survivor(id))
	{
		g_iDamageTaked[id] = 0.0;
		iWpnLevel[id] = 0;
	}
}

public Native_Get_User_WpnLevel(id)
{
	return iWpnLevel[id];
}

public Native_User_WpnLevel_Progress(id)
{
	return floatround(g_iDamageTaked[id] / WPNLVL_DAMAGE * 100.0)
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