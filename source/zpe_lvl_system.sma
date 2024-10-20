#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <zombieplague>
#include <smart_effects>

#define INFECT_TO_EXP 1 // Сколько давать опыта за заражение
#define INFECT_BOOST_TO_EXP 3 // Сколько давать опыта за заражение при бусте

#define SURVIVOR_TO_EXP 15 // Сколько давать опыта за убийство выжившего
#define SURVIVOR_BOOST_TO_EXP 30 // Сколько давать опыта за убийство выжившего при бусте

#define NEMESIS_TO_EXP 20 // Сколько давать опыта за убийство немезиды
#define NEMESIS_BOOST_TO_EXP 40 // Сколько давать опыта за убийство немезиды при бусте

#define DAMAGE_TO_EXP 1000.0 // Сколько урона необходимо нанести, чтобы заработать 1 опыт
#define DAMAGE_BOOST_TO_EXP 900.0 // Сколько урона необходимо нанести, чтобы заработать 1 опыт при бусте

#define FLAG_BOOST 		ADMIN_LEVEL_C

new const g_szSndNewLvl[] = "sound/zp_br_cso/other/level_up.wav"; // Звук нового уровня
new const ExperienceWeaponList[] = "zp_br_cso/other/hud_experience"; // путь до веапон листа
const ExperienceAmmoID = 16; // 15-31 сюда эти значения ставишь, если конфликтует, меняешь значение

new const g_iExpToNextLVL[] =
{
	0,			// до 1 lvl
	25,			// до 2 lvl
	50,			// до 3 lvl
	100,		// до 4 lvl
	200,		// до 5 lvl
	400,		// до 6 lvl
	800,		// до 7 lvl
	1600,		// до 8 lvl
	3000,		// до 9 lvl
	6000,		// до 10 lvl
	9000,		// до 11 lvl
	12000,		// до 12 lvl
	16500,		// до 13 lvl
	23650,		// до 14 lvl
	32500,		// до 15 lvl
	38000,		// до 16 lvl
	52000,		// до 17 lvl
	64250,		// до 18 lvl
	76500,		// до 19 lvl
	91400,		// до 20 lvl
	112750,		// до 21 lvl
	135650,		// до 22 lvl
	150350,		// до 23 lvl
	185000,		// до 24 lvl
	255000		// до 25 lvl
}

#if !defined zp_is_round_end
native zp_is_round_end();
#endif

/*
	Опыт и лвл
*/
new g_iUserExp[33], g_iUserLVL[33];
new g_iUserOldExp[33];

// new g_iSyncHud;

/*
	Урон
*/
new Float:g_flUserDamage[33];

new g_iFwd_UserLvlUp;
new g_iFwd_UserExpUp;

#define TASK_EXP 4234326

public plugin_precache()
{
	precache_generic(g_szSndNewLvl);

	precache_generic(fmt("sprites/%s.txt", ExperienceWeaponList));
	precache_generic("sprites/zp_br_cso/other/640exp30.spr"); // спрайт из txt
}

public plugin_init()
{
	register_plugin("[ZPE] LVL System", "1.0", "Docaner");
	RegisterHam(Ham_TakeDamage, "player", "HM_PlayerTakeDamage_Post", true);
	RegisterHam(Ham_TakeDamage, "info_target", "HM_NPCTakeDamage_Post", true);
	RegisterHam(Ham_Killed, "player", "HM_PlayerKilled_Post", true);

	g_iFwd_UserLvlUp = CreateMultiForward("zpe_user_lvl_up_post", ET_IGNORE, FP_CELL);
	g_iFwd_UserExpUp = CreateMultiForward("zpe_user_exp_up_post", ET_IGNORE, FP_CELL)

	// g_iSyncHud = CreateHudSyncObj();
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	g_flUserDamage[id] = 0.0
	remove_task(TASK_EXP+id);
}

public HM_PlayerTakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage)
{
	if(zp_is_round_end() || iVictim == iAttacker || !is_user_connected(iAttacker) || zp_get_user_zombie(iAttacker) || !zp_get_user_zombie(iVictim))
		return;

	g_flUserDamage[iAttacker] += flDamage;
	
	if(get_user_flags(iAttacker) & FLAG_BOOST)
	{
		while(g_flUserDamage[iAttacker] >= DAMAGE_BOOST_TO_EXP)
		{
			zpe_set_user_exp(iAttacker, zpe_get_user_exp(iAttacker) + 2);
			g_flUserDamage[iAttacker] -= DAMAGE_BOOST_TO_EXP;
		}
	}
	else
	{
		while(g_flUserDamage[iAttacker] >= DAMAGE_TO_EXP)
		{
			zpe_set_user_exp(iAttacker, zpe_get_user_exp(iAttacker) + 1);
			g_flUserDamage[iAttacker] -= DAMAGE_TO_EXP;
		}
	}
}

public HM_NPCTakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage)
{
	if(!is_user_connected(iAttacker) || !IsAliveNPC(iVictim))
		return;
	g_flUserDamage[iAttacker] += flDamage;
	while(g_flUserDamage[iAttacker] >= DAMAGE_TO_EXP)
	{
		zpe_set_user_exp(iAttacker, zpe_get_user_exp(iAttacker) + 1);
		g_flUserDamage[iAttacker] -= DAMAGE_TO_EXP;
	}
}

public HM_PlayerKilled_Post(iVictim, iKiller)
{
	if(iVictim == iKiller || !is_user_connected(iKiller))
		return;

	if(zp_get_user_zombie(iKiller))
	{
		if(!zp_get_user_zombie(iVictim))
		{
			if(zp_get_user_survivor(iVictim))
			{
				if(get_user_flags(iKiller) & FLAG_BOOST)
				{
					zpe_set_user_exp(iKiller, zpe_get_user_exp(iKiller) + SURVIVOR_BOOST_TO_EXP);
				}
				else
				{
					zpe_set_user_exp(iKiller, zpe_get_user_exp(iKiller) + SURVIVOR_TO_EXP);
				}
			}
			else
			{
				if(get_user_flags(iKiller) & FLAG_BOOST)
				{
					zpe_set_user_exp(iKiller, zpe_get_user_exp(iKiller) + INFECT_BOOST_TO_EXP);
				}
				else
				{
					zpe_set_user_exp(iKiller, zpe_get_user_exp(iKiller) + INFECT_TO_EXP);
				}
			}
		}
	}
	else
	{
		if(zp_get_user_zombie(iVictim) && zp_get_user_nemesis(iVictim))
		{
			if(get_user_flags(iKiller) & FLAG_BOOST)
			{
				zpe_set_user_exp(iKiller, zpe_get_user_exp(iKiller) + NEMESIS_BOOST_TO_EXP);
			}
			else
			{
				zpe_set_user_exp(iKiller, zpe_get_user_exp(iKiller) + NEMESIS_BOOST_TO_EXP);
			}
		}
	}
}

public zp_user_infected_post(id, infector, nemesis)
{
	if(infector)
	{
		if(get_user_flags(infector) & FLAG_BOOST)
		{
			zpe_set_user_exp(infector, zpe_get_user_exp(infector) + INFECT_BOOST_TO_EXP);
		}
		else
		{
			zpe_set_user_exp(infector, zpe_get_user_exp(infector) + INFECT_TO_EXP)
		}
	}
}

public plugin_natives()
{
	register_native("zpe_get_user_exp", "zpe_get_user_exp", 1);
	register_native("zpe_get_user_next_exp", "zpe_get_user_next_exp", 1);
	register_native("zpe_get_user_lvl", "zpe_get_user_lvl", 1);

	register_native("zpe_get_max_lvl", "zpe_get_max_lvl", 1);
	
	register_native("zpe_check_user_lvl", "zpe_check_user_lvl", 1);

	register_native("zpe_set_user_new", "zpe_set_user_new", 1);
	register_native("zpe_set_user_exp", "zpe_set_user_exp", 1);
	register_native("zpe_set_user_exp_wohud", "zpe_set_user_exp_wohud", 1);
	register_native("zpe_set_user_lvl", "zpe_set_user_lvl", 1);
}


/*
	Получить текущий опыт
*/
public zpe_get_user_exp(id) 
	return g_iUserExp[id];
/*
	Получить опыт до следующего уровня
	-1 - Максимальный уровень
*/
public zpe_get_user_next_exp(id) 
	return zpe_get_user_lvl(id) >= zpe_get_max_lvl() ? -1 : g_iExpToNextLVL[g_iUserLVL[id]];
/*
	Получить текущий уровень
*/
public zpe_get_user_lvl(id)
	return g_iUserLVL[id];

/*
	Получить максимальный уровень
*/
public zpe_get_max_lvl() 
	return sizeof g_iExpToNextLVL;

/*
	Проверка соответствия опыта к лвл
*/
public zpe_check_user_lvl(id)
{
	new iOldLvl = g_iUserLVL[id];

	zpe_check_user_lvl_wohud(id);

	if(g_iUserLVL[id] > iOldLvl)
	{
		new szName[32]; get_user_name(id, szName, charsmax(szName));

		for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if(iPlayer == id) continue;
			client_print_color(iPlayer, iPlayer, "^4[LEVEL] ^1Игрок ^3%s ^1достиг ^4%d ^1уровня!", szName, g_iUserLVL[id]);
		}

		client_print_color(id, id, "^4[LEVEL] ^1Поздравляем! Вы достигли ^4%d ^1уровня!", g_iUserLVL[id])
		client_cmd(id, "spk ^"%s^"", g_szSndNewLvl);

		new iDummy;
		ExecuteForward(g_iFwd_UserLvlUp, iDummy, id);
	}
}

zpe_check_user_lvl_wohud(id)
{
	while(g_iUserLVL[id] < zpe_get_max_lvl() && g_iUserExp[id] >= g_iExpToNextLVL[g_iUserLVL[id]])
		g_iUserLVL[id]++;
}

/*
	Установка начального значения новичкам
*/
public zpe_set_user_new(id)
{
	g_iUserLVL[id] = 1;
	g_iUserExp[id] = g_iExpToNextLVL[g_iUserLVL[id] - 1];
}

/*
	Установка опыта
*/
public zpe_set_user_exp(id, iValue)
{
	if(!task_exists(id+TASK_EXP))
	{
		set_task(0.2, "task_Exp", TASK_EXP+id);
		g_iUserOldExp[id] = g_iUserExp[id];
	}

	g_iUserExp[id] = iValue;
	zpe_check_user_lvl(id);
}
/*
	Установка exp без вывода в худ
*/
public zpe_set_user_exp_wohud(id, iValue)
{
	g_iUserExp[id] = iValue;
	zpe_check_user_lvl_wohud(id);
}

public task_Exp(id)
{
	id -= TASK_EXP;

	new iDiffrens = g_iUserExp[id] - g_iUserOldExp[id];

	ExecuteForward(g_iFwd_UserExpUp, iDiffrens, id)

	UTIL_DrawCustomAmmoPickup(id, ExperienceWeaponList, ExperienceAmmoID, g_iUserExp[id] - g_iUserOldExp[id]);
}

/*
	Установка уровня
*/
public zpe_set_user_lvl(id, iValue)
{
	g_iUserLVL[id] = iValue;
}

/**
 * Стоки
 */
stock UTIL_AmmoPickup( const iDest, const pReceiver, const iAmmoType, const iAmount )
{
	static iMsgId_AmmoPickup; if ( !iMsgId_AmmoPickup ) iMsgId_AmmoPickup = get_user_msgid( "AmmoPickup" );

	message_begin( iDest, iMsgId_AmmoPickup, .player = pReceiver );
	write_byte( iAmmoType );
	write_byte( clamp( iAmount, 1, 255 ) );
	message_end( );
}

/* -> Weapon List <- */
stock UTIL_WeaponList( const iDest, const pReceiver, const szWeaponName[ ], const iPrimaryAmmoType, const iMaxPrimaryAmmo, const iSecondaryAmmoType, const iMaxSecondaryAmmo, const iSlot, const iPosition, const iWeaponId, const iFlags ) 
{
	static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

	message_begin( iDest, iMsgId_Weaponlist, .player = pReceiver );
	write_string( szWeaponName );
	write_byte( iPrimaryAmmoType );
	write_byte( iMaxPrimaryAmmo );
	write_byte( iSecondaryAmmoType );
	write_byte( iMaxSecondaryAmmo );
	write_byte( iSlot );
	write_byte( iPosition );
	write_byte( iWeaponId );
	write_byte( iFlags );
	message_end( );
}

stock UTIL_DrawCustomAmmoPickup( const pReceiver, const szHudPath[ ], const iCustomAmmoID, const iValue )
{
	new iDest;
	if ( pReceiver <= 0 )
		iDest = MSG_ALL;
	else if ( is_user_connected( pReceiver ) )
		iDest = MSG_ONE;
	else
	{
		log_amx( "[ZP] Invalid Player (%i)", pReceiver );
		return false;
	}

	UTIL_WeaponList( iDest, pReceiver, szHudPath, iCustomAmmoID, -1, -1, -1, 0, 20, _: WEAPON_NONE, 0 );
	UTIL_AmmoPickup( iDest, pReceiver, iCustomAmmoID, iValue );

	return true;
}