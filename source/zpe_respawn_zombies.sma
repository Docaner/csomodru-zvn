#include < amxmodx >
#include < zombieplague >
#include < hamsandwich >
#include < cstrike >
#include < fun >
#include < fakemeta >
#include < reapi >

#define PLUGIN  "[ZP]: Custom respawn"
#define VERSION "1.0"
#define AUTHOR  "Weltgericht"

enum (+= 100)
{
	TASK_SPAWN
}

new kill_head[33]

new g_iOnline;

#if !defined zp_is_round_end
native zp_is_round_end();
#endif

#define ID_SPAWN (taskid - TASK_SPAWN)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Spawn, "player", "HM_PlayerSpawn_Post", true)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	
	register_clcmd("check_res", "@CheckRes");
}

public plugin_natives()
	//Воскресить игрока
	register_native("zp_user_try_respawn", "zp_user_try_respawn", 1);

@CheckRes(id)
{
	if(is_nullent(id)) return;
	switch(get_member(id, m_iTeam))
	{
		case TEAM_UNASSIGNED, TEAM_SPECTATOR:
		{
			rg_join_team(id, TEAM_CT);
			zp_user_try_respawn(id);
		}
	}
}

public client_putinserver(id)
{
	g_iOnline++

	zp_user_try_respawn(id);
}

public client_disconnected(id)
{
	remove_task(id+TASK_SPAWN)

	if(is_user_connected(id)) g_iOnline--
}

public HM_PlayerSpawn_Post(id)
{
	if(!is_user_alive(id))
		return;
		
	remove_task(id+TASK_SPAWN)
	return
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if(zp_is_nemesis_round() || zp_is_survivor_round() || zp_is_plague_round() || zp_is_swarm_round())
		return;
	
	if(is_user_res(victim))
	{
		set_task(5.0, "respawn_player_task", victim+TASK_SPAWN)
	}
}

public respawn_player_task(taskid)
{
	if(!is_user_connected(ID_SPAWN) || zp_is_round_end() || kill_head[ID_SPAWN] || is_user_alive(ID_SPAWN))
	{
		remove_task(ID_SPAWN+TASK_SPAWN)
		return
	}
	
	//client_print(ID_SPAWN, print_chat, "hasrndstarted: %d", zp_has_round_started());
	if(cs_get_user_team(ID_SPAWN) != CS_TEAM_SPECTATOR && cs_get_user_team(ID_SPAWN) != CS_TEAM_UNASSIGNED)
	{
		if(zp_has_round_started() != 1)
		{
			zp_respawn_user(ID_SPAWN, ZP_TEAM_HUMAN)
		}
		else
		{
			UTIL_SetRendering(ID_SPAWN, 19, 255.0, 69.0, 9.0, 0, 0.0);
			zp_respawn_user(ID_SPAWN, ZP_TEAM_ZOMBIE)
			
			if(zp_get_user_zombie_class(ID_SPAWN) == 4)
			{
				set_user_godmode(ID_SPAWN, 0)
				UTIL_SetRendering(ID_SPAWN)
			}
			else
			{
				set_user_godmode(ID_SPAWN, 1)
				set_task(5.0, "End_Glow", ID_SPAWN)
			}
		}
	}
	
	return
}

//Воскрешение игрока
public zp_user_try_respawn(id)
{
	if(!zp_is_nemesis_round() && !zp_is_survivor_round() && !zp_is_plague_round() && !zp_is_swarm_round())
		set_task(5.0, "respawn_player_task", id+TASK_SPAWN)
		
	if(zp_is_round_end())
		remove_task(id+TASK_SPAWN)
	
	is_user_res(id)
}

stock is_user_res(id)
{
	new iHumans = zp_get_human_count();

	//console_print(0, "iHumans: %d | kill_head = %d",iHumans, kill_head[id]);

	if(iHumans == 1) 
	{
		kill_head[id] = true;
		remove_task(id+TASK_SPAWN);
		return false;
	}

	switch(g_iOnline)
	{
		case 11..20:
		{
			if(iHumans <= 2)
			{
				kill_head[id] = true
				remove_task(id+TASK_SPAWN)
				return false
			}
		}
		case 21..32:
		{
			if(iHumans <= 3)
			{
				kill_head[id] = true
				remove_task(id+TASK_SPAWN)
				return false
			}
		}
	}

	return true;
}

public End_Glow(id)
{
	if(is_user_alive(id))
	{
		UTIL_SetRendering(id)
		set_user_godmode(id, 0)
	}
}
public zp_round_started()
	arrayset(kill_head, false, sizeof kill_head);

stock UTIL_SetRendering(iPlayer, iFx = 0, Float: flRed = 255.0, Float: flGreen = 255.0, Float: flBlue = 255.0, iRender = 0, Float: flAmount = 16.0)
{
	static Float: flColor[3];
	
	flColor[0] = flRed;
	flColor[1] = flGreen;
	flColor[2] = flBlue;
	
	set_pev(iPlayer, pev_renderfx, iFx);
	set_pev(iPlayer, pev_rendercolor, flColor);
	set_pev(iPlayer, pev_rendermode, iRender);
	set_pev(iPlayer, pev_renderamt, flAmount);
}