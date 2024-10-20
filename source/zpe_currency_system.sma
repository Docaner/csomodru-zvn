#include <amxmodx>
#include <hamsandwich>
#include <zombieplague>
#include <zp_service>
#include <reapi>
#include <smart_effects>

#define SOUND_LEVEL_UP "sound/zp_br_cso/other/level_up.wav"

native zp_is_round_end(); // Get round end

// Для цикла максимального количества игроков
#define MAX_CLIENTS		32

#define MsgId_SayText 76

#define LIMIT_FLAG 	 ADMIN_LEVEL_C	// Флаг Расширенного лимита

// Ограничения лимитов $, Ammo
#define LIMIT_USER_MONEY		80000 // Лимит $ (Обычный игрок)
#define LIMIT_USER_AMMO			350	// Лимит Ammo (Обычный игрок)

#define LIMIT_BOOSTED_MONEY		150000 // Лимит $ (Обычный игрок)
#define LIMIT_BOOSTED_AMMO		500	// Лимит Ammo (Обычный игрок)

// Бонусы $ за заражение, убийство зомби, убийство Немезиса и убийство Выжившего
#define MONEY_INFECT			1000 // За заражение
#define MONEY_KILL				1000 // За убийство зомби
#define MONEY_KILL_NEMESIS		12500 // За убийство Немезиса
#define MONEY_KILL_SURVIVOR		10000 // За убийство Выжившего

// Бонусы Ammo за заражение, нанесённый урон по Зомби 
#define AMMO_INFECT				2 // За заражение
#define AMMO_KILL_NEMESIS		50 // За убийство Немезиса 
#define AMMO_KILL_SURVIVOR		30 // За убийство Выжившего 
#define DAMAGE_AMMO				3500.0 // Урон на получение 1 Ammo (Обычный игрок)
#define AMMO_FROM_DAMAGE		1 // Количество Ammo даваемое за нанесённый урон

// TASK MONEY UPDATE
#define TASK_MONEYUPDATE 524234

// Регистрация переменных

new g_iAmmo[ MAX_CLIENTS + 1 ];
new Float: g_flUserDamage[ MAX_CLIENTS + 1 ];

public plugin_init()
{
	register_plugin( "[ZPE] Currency System", "1.0.1", "Docaner / by TrueMan :3" );

	RegisterHookChain(RG_CBasePlayer_AddAccount, "RG_Player_AddAccount_Pre", false);

	RegisterHookChain( RG_CBasePlayer_Killed, "CPlayer__Killed_Post", true);
	// RegisterHookChain( RG_CBasePlayer_TakeDamage, "CPlayer__TakeDamage_Post", true);
	RegisterHam( Ham_TakeDamage, "player", "CPlayer__TakeDamage_Post", true);
	RegisterHam( Ham_TakeDamage, "info_target", "CEntity__TakeDamage_Post", true);
}

public plugin_precache()
{
	precache_generic(SOUND_LEVEL_UP);
}

public plugin_natives() 
{
	register_native("zp_get_user_money", "native_get_money", 1);
	register_native("zp_set_user_money", "native_set_money", 1);
	register_native("zp_set_user_money_i", "native_set_money_i", 1);
	
	register_native("zp_get_user_ammo", "native_get_ammo", 1);
	register_native("zp_set_user_ammo", "native_set_ammo", 1);
	register_native("zp_set_user_ammo_i", "native_set_ammo_i", 1);

}

public client_disconnected(id)
{
	remove_task(TASK_MONEYUPDATE+id)
}

/*public client_putinserver(id)
{
	if(is_user_bot(id))
		RequestFrame("Request_RegisterBot", id);
}

public Request_RegisterBot(id)
{
	RegisterHamFromEntity(Ham_Killed, id, "CPlayer__Killed_Post", true);
	RegisterHamFromEntity(Ham_TakeDamage, id, "CPlayer__TakeDamage_Post", true);
}*/

// ZP
public zp_user_infected_post( iPlayer, iInfector )
{
	if( !is_user_connected( iPlayer ) || !is_user_connected( iInfector ) )
		return;
	

	Native_SetUserMoney( iInfector, native_get_money(iInfector) + MONEY_INFECT );
	Native_SetUserAmmo( iInfector, g_iAmmo[ iInfector ] + AMMO_INFECT );
}

public RG_Player_AddAccount_Pre(id, iAmount, RewardType:iReward, bool:bTrackChange)
	return iReward == RT_NONE ? HC_CONTINUE : HC_BREAK; 

// Ham
public CPlayer__Killed_Post( iVictim, iAttacker, iGib )
{
	if( !is_user_connected( iVictim ) || !is_user_connected( iAttacker ) || iVictim == iAttacker )
		return;

	new szKillerName[ 32 ];
	get_user_name( iAttacker, szKillerName, charsmax( szKillerName ) );
	
	Native_SetUserMoney( iAttacker, native_get_money(iAttacker) + MONEY_KILL );
	
	if( zp_get_user_nemesis( iVictim ) )
	{
		Native_SetUserMoney( iAttacker, native_get_money(iAttacker) + MONEY_KILL_NEMESIS );
		Native_SetUserAmmo( iAttacker, g_iAmmo[ iAttacker ] + AMMO_KILL_NEMESIS );
		
		UTIL_SayText(0, "!y* !g%s !yполучил !g12500$ !y| !g50 Ammo !yза убийство Немезиса!", szKillerName)
	}
	
	if( zp_get_user_zombie( iAttacker ) || zp_get_user_nemesis( iAttacker ))
	{
		Native_SetUserAmmo( iAttacker, g_iAmmo[ iAttacker ] + AMMO_INFECT );
	}

	if( zp_get_user_survivor( iVictim ) )
	{
		Native_SetUserMoney( iAttacker, native_get_money(iAttacker) + MONEY_KILL_SURVIVOR );
		Native_SetUserAmmo( iAttacker, g_iAmmo[ iAttacker ] + AMMO_KILL_SURVIVOR );
		
		UTIL_SayText(0, "!y* !g%s !yполучил !g10000$ !y| !g30 Ammo !yза убийство Выжившего!", szKillerName)
	}
	
	if( zp_get_user_survivor( iAttacker ) )
	{
		Native_SetUserAmmo( iAttacker, g_iAmmo[ iAttacker ] + AMMO_FROM_DAMAGE );
	}
}

public CPlayer__TakeDamage_Post( iVictim, iInflictor, iAttacker, Float: flDamage )
{
	if( !is_user_connected( iVictim ) || !is_user_connected( iAttacker ) || iVictim == iAttacker )
		return;
		
	if(zp_is_round_end())
		return;
		
	//Если атакующий - зомби
	if(zp_get_user_zombie(iAttacker) && !zp_get_user_zombie(iVictim))
	{
		Native_SetUserMoney(iAttacker, native_get_money(iAttacker) + min(floatround(flDamage) * 5, 2000))
	}
	//Если атакующий - человек
	else if(!zp_get_user_zombie( iAttacker ) && zp_get_user_zombie( iVictim ) )
	{
		if(!zp_get_user_survivor( iAttacker ) )
		{
			g_flUserDamage[ iAttacker ] += flDamage;
			
			if( g_flUserDamage[ iAttacker ] >= DAMAGE_AMMO )
			{
				while( g_flUserDamage[ iAttacker ] >= DAMAGE_AMMO )
				{
					g_flUserDamage[ iAttacker ] -= DAMAGE_AMMO
					Native_SetUserAmmo( iAttacker, g_iAmmo[ iAttacker ] + AMMO_FROM_DAMAGE );
				}
			}
			Native_SetUserMoney( iAttacker, native_get_money(iAttacker) + floatround( flDamage )) 
		}
		else
		{
			Native_SetUserMoney( iAttacker, native_get_money(iAttacker) + floatround( flDamage / 5.0 ) )
		}
	}	
}

public CEntity__TakeDamage_Post(iVictim, iInflictor, iAttacker, Float: flDamage)
{
	if( !is_user_connected( iAttacker ) || !IsAliveNPC(iVictim))
		return;
		
	if(zp_is_round_end())
		return;
	
	g_flUserDamage[ iAttacker ] += flDamage;
			
	if( g_flUserDamage[ iAttacker ] >= DAMAGE_AMMO )
	{
		while( g_flUserDamage[ iAttacker ] >= DAMAGE_AMMO )
		{
			g_flUserDamage[ iAttacker ] -= DAMAGE_AMMO
			Native_SetUserAmmo( iAttacker, g_iAmmo[ iAttacker ] + AMMO_FROM_DAMAGE );
		}
	}
	Native_SetUserMoney( iAttacker, native_get_money(iAttacker) + floatround( flDamage / 5.0 ) ) 
}

// Натив для выдачи $
Native_SetUserMoney(iPlayer, iAmount) 
{
	if(!is_user_connected(iPlayer)) 
		return;
	
	new iLimit = get_user_flags(iPlayer) & LIMIT_FLAG ? LIMIT_BOOSTED_MONEY : LIMIT_USER_MONEY; // 80000
	
	new iMoney = native_get_money(iPlayer) // 82000

	new iMaxMoney = max(iMoney, iLimit);
	iAmount = min(iMaxMoney, iAmount);

	set_member(iPlayer, m_iAccount, iAmount);

	if(task_exists(iPlayer+TASK_MONEYUPDATE))
		change_task(iPlayer+TASK_MONEYUPDATE, 0.01);
	else
		set_task(0.01, "task_SetUserMoney", iPlayer+TASK_MONEYUPDATE);
}

public task_SetUserMoney(iPlayer)
{
	iPlayer -= TASK_MONEYUPDATE;
	rg_add_account(iPlayer, native_get_money(iPlayer), AS_SET, true);
	
}

// Натив для выдачи Ammo
Native_SetUserAmmo( iPlayer, iAmount ) 
{
	if(is_nullent(iPlayer)) 
		return;
	
	new iLimit = get_user_flags(iPlayer) & LIMIT_FLAG ? LIMIT_BOOSTED_AMMO : LIMIT_USER_AMMO;
	
	new iAmmo = g_iAmmo[iPlayer]

	new iMaxAmmo = max(iAmmo, iLimit);

	iAmount = min(iMaxAmmo, iAmount);
	
	g_iAmmo[ iPlayer ] = iAmount;
}

// Общие нативы для регистрации в include zp_system.inc
public native_set_money( iPlayer, iValue )
	Native_SetUserMoney( iPlayer, iValue )

public native_set_money_i(iPlayer, iValue)
	rg_add_account(iPlayer, iValue, AS_SET, false);

public native_get_money( iPlayer )
{
	if(!is_user_connected(iPlayer)) return 0;
	return get_member(iPlayer, m_iAccount);
}	
	
public native_set_ammo(iPlayer, iValue)
	Native_SetUserAmmo(iPlayer, iValue)

public native_set_ammo_i(iPlayer, iValue)
	g_iAmmo[iPlayer] = iValue;

public native_get_ammo( iPlayer )
	return g_iAmmo[ iPlayer ]

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