#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <xs>

#define TIMER_NEXTTHINK 1.0 // Раз в сколько секунд проверять игроков на AFK
#define TIMER_ONLINE 31 // При каком онлайне кикать АФКшников

#define AFK_SPAWN 30.0 // Время AFK после спавна
#define AFK_TIME 90.0 // Время AFK после чего переводит за спектры

#define ADMIN_VIP ADMIN_LEVEL_H

#define FLAG_NOKICK (ADMIN_BAN|ADMIN_VIP) // С каким флагом запрещено кикать игроков с сервера

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))

new const g_szCMDsAct[][] = // Команды для детекта действия игрока
{
	"menuselect", "radio1", "radio2", "radio3", "drop",
	"showbriefing", "lastinv", "say", "say_team"
}

//Звук предупреждения
new const g_szSoundAttention[] = "fvox/beep.wav";
//Звук перевода
new const g_szSoundSectator[] = "fvox/flatline.wav"

new g_iMaxPlayers, g_iOnline;

enum
{
	PHASE_START,
	PHASE_20SEC,
	PHASE_10SEC
}

new g_iEntTimer = NULLENT;

new Float:g_flUserLastCmd[33], // Отметка времени о последней введённой команды игрока 
	g_iUserPhase[33], // Фаза кика игрока
	Float:g_flUserTime[33], //Точка времени, когда переведется игрок
	Float:g_flUserTimeType[33]; //Сколько секунд у игрока, через которые его переведут

new g_iBitUserAct, // Битсумма игроков которые двигаются
	g_iBitUserKick; // Битсумма игроков, которые были переведены в спектаторы АФК-системой

#define MsgId_SayText 76

#define TASK_UPDATEANGLES 143222

public plugin_init()
{
	register_plugin("AFK Kicker", "1.6", "Docaner");
	
	RegisterHam(Ham_Spawn, "player", "HM_Player_Spawn_Pre", false);

	for(new i; i < sizeof g_szCMDsAct; i++) register_clcmd(g_szCMDsAct[i], "CMDs_UserAct");

	g_iMaxPlayers = get_maxplayers();

	//Запускаем АФК-кикер
	start_timer();
}

public plugin_natives()
	register_native("get_user_afk", "get_user_afk", 1);

public get_user_afk(id)
	return IsSetBit(g_iBitUserKick, id) ? true : false;

public client_putinserver(id)
{
	++g_iOnline;
	SetBit(g_iBitUserAct, id);
}

public client_disconnected(id)
{
	if(is_user_connected(id)) g_iOnline--;
	ClearBit(g_iBitUserKick, id);
	remove_task(id+TASK_UPDATEANGLES);
}


public HM_Player_Spawn_Pre(id)
	if(!is_user_alive(id)) 
	{
		ClearBit(g_iBitUserKick, id);
		SetBit(g_iBitUserAct, id);
		set_user_afk_counter(id, AFK_SPAWN);
	}


public CMDs_UserAct(id)
	g_flUserLastCmd[id] = get_gametime() + TIMER_NEXTTHINK;


create_timer()
{
	new iEnt = rg_create_entity("info_target");

	if(is_nullent(iEnt)) return NULLENT;

	set_entvar(iEnt, var_nextthink, get_gametime() + TIMER_NEXTTHINK);

	SetThink(iEnt, "RG_Timer_Think")

	return iEnt;
}

stock start_timer()
{
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
		g_flUserTime[iPlayer] = 0.0;
		
	g_iEntTimer = is_nullent(g_iEntTimer) ? create_timer() : g_iEntTimer;
}

stock end_timer()
{
	if(!is_nullent(g_iEntTimer)) rg_remove_ent(g_iEntTimer);
	g_iEntTimer = NULLENT;
}

public RG_Timer_Think(iEnt)
{
	new Float:flGameTime = get_gametime();

	//Проверяем игроков на действия
	update_users_action(flGameTime);
	//Переводим АФК за спектров, если они долго не двигаются
	update_users_afk(flGameTime);
	//Переводим АФК обратно в игру, если они задвигались
	update_user_not_afk();
	//Кикаем АФК при высоком онлайне
	kick_at_hight_online();

	set_entvar(iEnt, var_nextthink, flGameTime + TIMER_NEXTTHINK);
}

//Проверяем игроков на действие
stock update_users_action(Float:flGameTime)
{
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_connected(iPlayer)) continue;
		
		if(is_user_act(iPlayer, flGameTime))
			SetBit(g_iBitUserAct, iPlayer);
		else if(IsSetBit(g_iBitUserAct, iPlayer))
			set_user_afk_counter(iPlayer, AFK_TIME);
	}
}

//Установить отсчет игрока до перевода
stock set_user_afk_counter(const pPlayer, Float:flTime)
{
	g_flUserTime[pPlayer] = get_gametime() + flTime;
	g_flUserTimeType[pPlayer] = flTime;

	if(AFK_TIME <= 10.0)
		g_iUserPhase[pPlayer] = PHASE_10SEC;
	else if(AFK_TIME <= 20.0)
		g_iUserPhase[pPlayer] = PHASE_20SEC;
	else
		g_iUserPhase[pPlayer] = PHASE_START;

	ClearBit(g_iBitUserAct, pPlayer);
}

//Двигается ли игрок
stock is_user_act(iPlayer, Float:flGameTime)
{
	//Использовал ли игрок команды для декта
	if(g_flUserLastCmd[iPlayer] >= flGameTime)
		return true;

	static pUsersOldButtons[33];

	new iButtons = get_entvar(iPlayer, var_button),
		//Имеется ли различия в нажатых кнопках
		bool:iCompare = iButtons != pUsersOldButtons[iPlayer];

	pUsersOldButtons[iPlayer] = iButtons;

	return iCompare;
}

//Переводим АФК за спектров, если они долго не двигаются
stock update_users_afk(Float:flGameTime)
{
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_alive(iPlayer) || IsSetBit(g_iBitUserAct, iPlayer))
			continue;

		switch(g_iUserPhase[iPlayer])
		{
			case PHASE_START:
			{
				if(g_flUserTime[iPlayer] - flGameTime <= 20.0)
				{
					UTIL_SayText(iPlayer, "!g[AFK] !yЧерез !g20 !yсекунд Вы будете переведены за бездействие");
					g_iUserPhase[iPlayer] = PHASE_20SEC;
					client_cmd(iPlayer, "spk ^"%s^"", g_szSoundAttention);
				}
			}
			case PHASE_20SEC:
			{
				if(g_flUserTime[iPlayer] - flGameTime <= 10.0)
				{
					UTIL_SayText(iPlayer, "!g[AFK] !yЧерез !g10 !yсекунд Вы будете переведены за бездействие");
					g_iUserPhase[iPlayer] = PHASE_10SEC;
					client_cmd(iPlayer, "spk ^"%s^"", g_szSoundAttention);
				}
			}
			case PHASE_10SEC:
			{
				if(g_flUserTime[iPlayer] - flGameTime <= 0.0)
				{
					static szName[32]; get_user_name(iPlayer, szName, charsmax(szName))

					ExecuteHamB(Ham_Killed, iPlayer, 0, 0);
					rg_join_team(iPlayer, TEAM_SPECTATOR);

					
					SetBit(g_iBitUserKick, iPlayer);
					client_cmd(iPlayer, "spk ^"%s^"", g_szSoundSectator);	

					UTIL_SayText(0, "!g[AFK] !yИгрок !g%s !yбыл переведён за бездействие в течение !g%d !yс", szName, floatround(g_flUserTimeType[iPlayer]));
				}
			}
		}
	}
}


//Переводим АФК обратно в игру, если они задвигались
stock update_user_not_afk()
{
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!IsSetBit(g_iBitUserKick, iPlayer) || !IsSetBit(g_iBitUserAct, iPlayer))
			continue;

		ClearBit(g_iBitUserKick, iPlayer);
		rg_join_team(iPlayer, TEAM_CT);

		//Пытаемся возродить игрока
		client_cmd(iPlayer, "check_res");
	}
}

//Кик рандомного при высоком онлайне
stock kick_at_hight_online()
{
	if(g_iOnline < TIMER_ONLINE || !g_iBitUserKick)
		return;

	//Массив клиентов AFK и их количество
	new iAFKs[32], iCount;

	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!IsSetBit(g_iBitUserKick, iPlayer) || get_user_flags(iPlayer) & FLAG_NOKICK) continue;
		iAFKs[iCount++] = iPlayer;
	}

	new iKickCount, iRandomChoose, id;

	while(g_iOnline - iKickCount >= TIMER_ONLINE && iCount)
	{
		//Выбираем случайного АФК
		iRandomChoose = random(iCount);
		//Получение id клиента
		id = iAFKs[iRandomChoose];
		//На место случайного id, ставим крайнего и уменьшаем iCount
		iAFKs[iRandomChoose] = iAFKs[--iCount]

		rh_drop_client(id, "[AFK] Вы были кикнуты за бездействие");
		iKickCount++;
	}

}
stock rg_remove_ent(iEnt) 
{
	set_entvar(iEnt, var_flags, FL_KILLME); 
	set_entvar(iEnt, var_nextthink, get_gametime());
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
			for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
			{
				if(!is_user_connected(iPlayer)) continue;
				message_begin(MSG_ONE_UNRELIABLE, MsgId_SayText, _, iPlayer);
				write_byte(iPlayer);
				write_string(szBuffer);
				message_end();
			}
		}
		default:
		{
			message_begin(MSG_ONE_UNRELIABLE, MsgId_SayText, _, pPlayer);
			write_byte(pPlayer);
			write_string(szBuffer);
			message_end();
		}
	}
}