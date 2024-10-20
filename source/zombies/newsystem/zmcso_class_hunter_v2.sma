/*
	[1.0] 
		- Первый релиз

		[1.1] 
			- Пофикшенны баги с выбросом оружия у людей
			- Для локальных серверов пофикшен вылет из за ботов

*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <zombieplague>
#include <zp_system>
#include <api_maxspeed>
#include <api_flame>
#include <zc_addon_zclasses>
#include <zc_addon_zchoose>

native zp_get_user_burn(id);
native Float:zp_get_mul_burn(id);

#define linux_diff_weapon 		4
#define linux_diff_player 		5

// CBasePlayerItem
#define m_pPlayer				41
#define MsgId_SayText 76

// CBasePlayer
#define m_iFOV					363

#define ENABLE_WEAPONLIST		true // [ true = Включение WeaponList + Таймер | false = Выключено ]
#define ENABLE_FOV_EFFECT		true // [ true = Плавный переход FOV | false = моментальный переход FOV ]

#define ZM_CLASS_SPRINT_TIME	2.5
#define ZM_CLASS_COUNTDOWN		25.0
#define ZM_CLASS_SPEED_FASTRUN 	400.0
#define ZM_CLASS_SPEED_FASTRUN_BURN 	300.0

#define SPRINT_SOUND_START		"zp_br_cso/zombie/male/hunter_skill_b1.wav"

#define TASK_ABILITY 			5325235

#define MAX_CLIENTS				32

new bool: g_bAbilityUse[MAX_CLIENTS + 1 char],
	Float: g_flAbilityWait[MAX_CLIENTS + 1],
	Float: g_flAbilityTime[MAX_CLIENTS + 1],

	//Ham: Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame,

	#if ENABLE_WEAPONLIST

		g_iMsgID_AmmoX,
		g_iMsgID_CurWeapon,
		g_iMsgID_WeaponList,

	#endif

	g_iMaxPlayers,
	g_iZClassID,
	Float:g_flClass_MaxSpeed;

public plugin_init()
{
	register_plugin("[X-CSO] Class: Hunter", "1.1", "xUnicorn (t3rkecorejz)");

	//register_forward(FM_PlayerPreThink, "FM_Hook_PlayerPreThink_Pre", false);

	//RegisterHam(Ham_Player_ResetMaxSpeed, "player", "CPlayer__ResetMaxSpeed_Post", true);

	RegisterHam(Ham_Killed, "player", "CPlayer__Killed_Pre", false);

	#if ENABLE_WEAPONLIST

		RegisterHam(Ham_Spawn, "player", "CPlayer__Spawn_Post", true);

		RegisterHam(Ham_Item_Deploy, "weapon_knife", "CWeapon__Deploy_Post", true);
		RegisterHam(Ham_Item_PostFrame, "weapon_knife", "CKnife__PostFrame_Pre", false);

		g_iMsgID_AmmoX = get_user_msgid("AmmoX");
		g_iMsgID_CurWeapon = get_user_msgid("CurWeapon");
		g_iMsgID_WeaponList = get_user_msgid("WeaponList");

	#endif

	g_iMaxPlayers = get_maxplayers();
	g_iZClassID = zc_find_zclass_by_shortname("hunter");

	register_clcmd("drop", "Command_Ability");
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheSound, SPRINT_SOUND_START);

	#if ENABLE_WEAPONLIST

		engfunc(EngFunc_PrecacheGeneric, "sprites/zp_br_cso/zombie/zmtimer2.txt");
		register_clcmd("zp_br_cso/zombie/zmtimer2", "Command_HookWeapon");

	#endif

}

public client_putinserver(iPlayer) ResetValue(iPlayer);
public client_disconnected(iPlayer) ResetValue(iPlayer);

public CPlayer__Killed_Pre(iVictim)
{
	ResetValue(iVictim);
	ResetStats(iVictim);
}

public zp_user_infected_post(iPlayer, iInfector, iNemesis) 
{
	if(zp_get_user_zombie(iPlayer) && zc_get_user_zclass(iPlayer) == g_iZClassID && !zp_get_user_nemesis(iPlayer))
	{
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yСпособность !g[Разгон]!y | Кнопка: !g[G]!y")
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yВремя разгона: !g3 секунды !y| Отсчёт: !g20 секунд!y")
	}
	
	ResetValue(iPlayer);

	if(g_flClass_MaxSpeed == 0.0) g_flClass_MaxSpeed = Float:get_entvar(iPlayer, var_maxspeed);
	
	#if ENABLE_WEAPONLIST

		UTIL_SetWeaponList(iPlayer, "weapon_knife", -1, -1, -1, -1, 2, 1, 29, 0);
		return;

	#endif

}



public zp_user_humanized_pre(iPlayer) 
{
	ResetValue(iPlayer);
	UTIL_SetFov(iPlayer);
	ResetStats(iPlayer);

	#if ENABLE_WEAPONLIST

		UTIL_SetWeaponList(iPlayer, "weapon_knife", -1, -1, -1, -1, 2, 1, 29, 0);

	#endif
}

public zp_round_ended(winteam)
{
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_connected(iPlayer))
			continue;
		
		ResetValue(iPlayer);
		ResetStats(iPlayer);
	}
}

public EV_RoundStart()
{
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_connected(iPlayer)) continue;

		ResetValue(iPlayer);

		#if ENABLE_WEAPONLIST

			UTIL_SetWeaponList(iPlayer, "weapon_knife", -1, -1, -1, -1, 2, 1, 29, 0);

		#endif
	}
}

#if ENABLE_WEAPONLIST

	public Command_HookWeapon(iPlayer)
	{
		engclient_cmd(iPlayer, "weapon_knife");
		return PLUGIN_HANDLED;
	}

	public CPlayer__Spawn_Post(iPlayer)
	{
		if(!is_user_connected(iPlayer)) return HAM_IGNORED;
		
		UTIL_SetWeaponList(iPlayer, "weapon_knife", -1, -1, -1, -1, 2, 1, 29, 0);

		return HAM_IGNORED;
	}

	public CWeapon__Deploy_Post(iItem)
	{
		if(pev_valid(iItem) != 2)
			return HAM_IGNORED;

		static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

		if(!zp_get_user_zombie(iPlayer) || zp_get_user_nemesis(iPlayer)) return HAM_IGNORED;
		if(zc_get_user_zclass(iPlayer) != g_iZClassID) return HAM_IGNORED;

		new Float: flGameTime; flGameTime = get_gametime();

		if(flGameTime < g_flAbilityWait[iPlayer])
		{
			UTIL_SetWeaponList(iPlayer, "zp_br_cso/zombie/zmtimer2", 15, floatround(ZM_CLASS_COUNTDOWN), -1, -1, 2, 1, 29, 0);

			message_begin(MSG_ONE, g_iMsgID_AmmoX, _, iPlayer);
			write_byte(15);
			write_byte(floatround(g_flAbilityWait[iPlayer] - flGameTime));
			message_end();
		}
		else UTIL_SetWeaponList(iPlayer, "zp_br_cso/zombie/zmtimer2", -1, -1, -1, -1, 2, 1, 29, 0);

		return HAM_IGNORED;
	}

	public CKnife__PostFrame_Pre(iItem)
	{
		if(pev_valid(iItem) != 2)
			return HAM_IGNORED;
			
		static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

		if(!zp_get_user_zombie(iPlayer) || zp_get_user_nemesis(iPlayer)) return HAM_IGNORED;
		if(zc_get_user_zclass(iPlayer) != g_iZClassID) return HAM_IGNORED;

		new Float: flGameTime; flGameTime = get_gametime();

		if(flGameTime < g_flAbilityWait[iPlayer])
		{
			message_begin(MSG_ONE, g_iMsgID_AmmoX, _, iPlayer);
			write_byte(15);
			write_byte(floatround(g_flAbilityWait[iPlayer] - flGameTime));
			message_end();
		}
		else UTIL_SetWeaponList(iPlayer, "zp_br_cso/zombie/zmtimer2", -1, -1, -1, -1, 2, 1, 29, 0);

		return HAM_IGNORED;
	}

#endif

public Command_Ability(iPlayer)
{
	if(!is_user_alive(iPlayer) || !zp_get_user_zombie(iPlayer) || zp_get_user_nemesis(iPlayer))
		return PLUGIN_CONTINUE;
		
	if(zp_is_round_end())
		return PLUGIN_HANDLED;
	
	new iWeapon = get_user_weapon(iPlayer)
	new iGrenade = check_grenade(iWeapon)

	if(zc_get_user_zclass(iPlayer) == g_iZClassID)
	{	
		static Float: flGameTime; flGameTime = get_gametime();

		if(g_bAbilityUse{iPlayer})	client_print(iPlayer, print_center, "Способность уже используется.");
		else
		{
			if(g_flAbilityWait[iPlayer] <= flGameTime)
			{
				if(iGrenade)
					return PLUGIN_HANDLED;

				g_bAbilityUse{iPlayer} = true;
				g_flAbilityWait[iPlayer] = flGameTime + ZM_CLASS_COUNTDOWN;

				#if ENABLE_WEAPONLIST

					UTIL_SetWeaponList(iPlayer, "zp_br_cso/zombie/zmtimer2", 15, floatround(ZM_CLASS_COUNTDOWN), -1, -1, 2, 1, 29, 0);

					engfunc(EngFunc_MessageBegin, MSG_ONE, g_iMsgID_CurWeapon, {0, 0, 0}, iPlayer);
					write_byte(1);
					write_byte(CSW_KNIFE);
					write_byte(-1);
					message_end();

				#endif

				emit_sound(iPlayer, CHAN_AUTO, SPRINT_SOUND_START, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				UTIL_SetRendering(iPlayer, kRenderFxGlowShell, 255.0, 0.0, 0.0, 0, 0.0);
				UTIL_SetFov(iPlayer, 110);


				Class__SetSpeed(iPlayer, true, zp_get_user_flame(iPlayer));
				set_task(ZM_CLASS_SPRINT_TIME, "task_DisableAbility", iPlayer+TASK_ABILITY);
			}
		}

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

stock Class__SetSpeed(const iPlayer, bool:bFastSpeed, pEntBase = NULLENT)
{
	switch(bFastSpeed)
	{
		case true:
		{
			if(pEntBase == NULLENT)
			{
				rg_set_user_maxspeed(iPlayer, ZM_CLASS_SPEED_FASTRUN);
				return;
			}

			set_entvar(pEntBase, var_base_speedflame, ZM_CLASS_SPEED_FASTRUN_BURN)
			rg_set_user_maxspeed(iPlayer, ZM_CLASS_SPEED_FASTRUN_BURN);
		}
		case false:
		{
			if(pEntBase == NULLENT)
			{
				rg_set_user_maxspeed(iPlayer, g_flClass_MaxSpeed);
				return;
			}

			set_entvar(pEntBase, var_base_speedflame, FLAME_SPEED);
			rg_set_user_maxspeed(iPlayer, FLAME_SPEED);
		}
	}
}

public zp_flame_create_post(const pEntBase, const pVictim)
{
	if(!zp_get_user_zombie(pVictim) || zc_get_user_zclass(pVictim) != g_iZClassID)
		return;

	if(task_exists(pVictim+TASK_ABILITY))
		Class__SetSpeed(pVictim, true, pEntBase);
	else
		Class__SetSpeed(pVictim, false, pEntBase);

}

public zp_flame_disable_post(const pEntBase, const pVictim)
{
	if(!zp_get_user_zombie(pVictim) || zc_get_user_zclass(pVictim) != g_iZClassID)
		return;

	if(task_exists(pVictim+TASK_ABILITY))
		Class__SetSpeed(pVictim, true);
	else
		Class__SetSpeed(pVictim, false);
}

public task_DisableAbility(iPlayer)
{
	iPlayer -= TASK_ABILITY;

	ResetStats(iPlayer);
	g_bAbilityUse{iPlayer} = false;


}

public plugin_natives()
{
	register_native("zp_get_hunter_class", "zp_get_hunter_class", 1);
	register_native("zp_is_hunter_ability", "zp_is_hunter_ability", 1);
}

public zp_get_hunter_class()
	return g_iZClassID;

public zp_is_hunter_ability(id)
	return g_bAbilityUse{id};

ResetValue(iPlayer)
{
	g_bAbilityUse{iPlayer} = false;

	g_flAbilityTime[iPlayer] = 0.0;
	g_flAbilityWait[iPlayer] = 0.0;

	remove_task(iPlayer+TASK_ABILITY);

}

ResetStats(iPlayer)
{
	if(!zp_get_user_zombie(iPlayer) || zc_get_user_zclass(iPlayer) != g_iZClassID)
		return;

	UTIL_SetRendering(iPlayer);
	UTIL_SetFov(iPlayer);
	
	Class__SetSpeed(iPlayer, false, zp_get_user_flame(iPlayer));
}

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

stock UTIL_SetFov( iPlayer, iDegrees = 90 )
{
	message_begin( MSG_ONE_UNRELIABLE, 95, _, iPlayer );
	write_byte( iDegrees );
	message_end( );
}

#if ENABLE_WEAPONLIST

	stock UTIL_SetWeaponList(iPlayer, const szWeaponName[], iPrimaryAmmoID, iPrimaryAmmoMaxAmount, iSecondaryAmmoID, iSecondaryAmmoMaxAmount, iSlotID, iNumberInSlot, iWeaponID, iFlags)
	{
		message_begin(MSG_ONE, g_iMsgID_WeaponList, _, iPlayer);
		write_string(szWeaponName);
		write_byte(iPrimaryAmmoID);
		write_byte(iPrimaryAmmoMaxAmount);
		write_byte(iSecondaryAmmoID);
		write_byte(iSecondaryAmmoMaxAmount);
		write_byte(iSlotID);
		write_byte(iNumberInSlot);
		write_byte(iWeaponID);
		write_byte(iFlags);
		message_end();
	}

#endif
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/

stock check_grenade(iWeapon)
{
	new iGrenade

	switch( iWeapon )
	{
		case CSW_HEGRENADE: 	iGrenade = 1
		case CSW_FLASHBANG:  	iGrenade = 2
		case CSW_SMOKEGRENADE:	iGrenade = 3
	}

	return iGrenade
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
