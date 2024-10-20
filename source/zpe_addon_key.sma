#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <reapi>
#include <xs>
#include <zombieplague>

new const g_szModel[] = "models/zp_br_cso/supply_v5.mdl"; // Модель
new const g_szSndPickUp[] = "zp_br_cso/other/key.wav" // Звук подбора ключа

#define KEY_BODY 1 // Субмодель ключа
#define KEY_VELOCITY 200.0 // Ускорение ключа при выпадении

#define MAX_MONEYKEY 3 // Максимальное количество MoneyKey
#define MAX_AMMOKEY 3 // Максимальное количество AmmoKey

#define ADMIN_PLUS ADMIN_LEVEL_C
#define MAX_PLUS_MONEYKEY 6 // Максимальное количество MoneyKey
#define MAX_PLUS_AMMOKEY 6 // Максимальное количество AmmoKey

#define CHANCE_KEY 6 // Раз из скольки должен выпадать ключ случайным образом

#define CHANCE_MONEYKEY 2 // Шанс выпадения MoneyKey
#define CHANCE_AMMOKEY 1 // Шанс выпадения AmmoKey

#define WEAPON_MONEYKEY 	WEAPON_GLOCK
#define WEAPON_AMMOKEY		WEAPON_TMP

new const g_szClassName[] = "addonkey"
new const Float:g_vecMins[3] = {-1.0, -1.0, -1.0};
new const Float:g_vecMaxs[3] = {1.0, 1.0, 1.0};

new g_iUserMoneyKey[33], g_iUserAmmoKey[33];
// new g_iOldMoneyKey[33], g_iOldAmmoKey[33];

// new g_iSyncHud;

new const AmmoKeyWeaponList[] = "zp_br_cso/other/hud_keyammo"; // путь до веапон листа
new const MoneyKeyWeaponList[] = "zp_br_cso/other/hud_keymoney2"; // путь до веапон листа

enum
{
	MONEY_KEY = 0,
	AMMO_KEY
}

#define var_type var_iuser1

#define TASK_MONEYKEY 34244
#define TASK_AMMOKEY 433345

public plugin_precache()
{
	precache_model(g_szModel);
	precache_sound(g_szSndPickUp);
	
	precache_generic(fmt("sprites/%s.txt", AmmoKeyWeaponList));
	precache_generic(fmt("sprites/%s.txt", MoneyKeyWeaponList));
	precache_generic("sprites/zp_br_cso/other/640keys32.spr"); // спрайт из txt
}


public plugin_init()
{
	register_plugin("[ZPE] Addon : Key", "1.0", "Docaner")
	RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound_Post", true);
	RegisterHam(Ham_Killed, "player", "HM_PlayerKilled_Post", true);
	//RegisterHookChain(RG_CBasePlayer_TraceAttack, "CBasePlayer_TraceAttack_Post", true);
	//g_iSyncHud = CreateHudSyncObj();
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	remove_task(id+TASK_MONEYKEY);
	remove_task(id+TASK_AMMOKEY);
}

public CSGameRules_RestartRound_Post()
{
	//client_print(0, print_chat, "RESTART ROUND");

	new iEnt = NULLENT;
	while((iEnt = rg_find_ent_by_class(iEnt, g_szClassName)) > 0)
		rg_remove_ent(iEnt);
}

public HM_PlayerKilled_Post(pVictim, pKiller)
{
	if(pVictim == pKiller || !is_user_connected(pKiller) || !zp_get_user_zombie(pVictim))
		return;

	if(!random(CHANCE_KEY))
	{
		new Float:vecOrigin[3]; get_entvar(pVictim, var_origin, vecOrigin);
		new Float:vecKiller[3]; get_entvar(pKiller, var_origin, vecKiller)
		new Float:vecAngles[3]; get_entvar(pVictim, var_angles, vecAngles); vecAngles[2] = 0.0;
	
		new Float:vecVelocity[3];
		xs_vec_sub(vecOrigin, vecKiller, vecVelocity);
		xs_vec_normalize(vecVelocity, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, KEY_VELOCITY, vecVelocity);

		new iType = random(CHANCE_MONEYKEY+CHANCE_AMMOKEY) < CHANCE_MONEYKEY ? MONEY_KEY : AMMO_KEY;

		create_key(iType, vecOrigin, vecAngles, vecVelocity);
	}
}

create_key(iType, Float:vecOrigin[3], Float:vecAngles[3], Float:vecVelocity[3])
{
	new iEnt = rg_create_entity("info_target");

	if(is_nullent(iEnt)) return NULLENT;

	set_entvar(iEnt, var_classname, g_szClassName);
	set_entvar(iEnt, var_movetype, MOVETYPE_BOUNCE);
	set_entvar(iEnt, var_solid, SOLID_TRIGGER);
	set_entvar(iEnt, var_velocity, vecVelocity);
	set_entvar(iEnt, var_body, KEY_BODY);
	set_entvar(iEnt, var_angles, vecAngles);
	set_entvar(iEnt, var_type, iType);

	switch(iType)
	{
		case MONEY_KEY:
			fm_set_rendering(iEnt, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 1);
		case AMMO_KEY:
			fm_set_rendering(iEnt, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 1);
	}

	engfunc(EngFunc_SetModel, iEnt, g_szModel);
	engfunc(EngFunc_SetSize, iEnt, g_vecMins, g_vecMaxs);
	engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);

	SetTouch(iEnt, "RG_Touch_Key");

	return iEnt;
}

public RG_Touch_Key(iEnt, iOther)
{
	//client_print(0, print_chat, "TOUCH");

	if(is_user_alive(iOther))
	{
		if(!zp_get_user_zombie(iOther))
		{
			switch(get_entvar(iEnt, var_type))
			{
				case AMMO_KEY:
				{
					if(zpe_get_max_ammokey(iOther) <= zpe_get_user_ammokey(iOther))
						return;

					zpe_set_user_ammokey(iOther, zpe_get_user_ammokey(iOther) + 1);
				}
				case MONEY_KEY:
				{
					if(zpe_get_max_moneykey(iOther) <= zpe_get_user_moneykey(iOther))
						return;

					zpe_set_user_moneykey(iOther, zpe_get_user_moneykey(iOther) + 1);
				}
			}

			//client_print(iOther, print_chat, "AMMO KEY: %d/%d | MONEY KEY: %d/%d", zpe_get_user_ammokey(iOther), zpe_get_max_ammokey(), zpe_get_user_moneykey(iOther), zpe_get_max_moneykey());

			rh_emit_sound2(iOther, 0, CHAN_AUTO, g_szSndPickUp);
			rg_remove_ent(iEnt);
		}
	}
	else
	{
		new Float:vecVelocity[3]; get_entvar(iEnt, var_velocity, vecVelocity);
		xs_vec_div_scalar(vecVelocity, 1.5, vecVelocity);
		set_entvar(iEnt, var_velocity, vecVelocity);
	}
}


stock rg_remove_ent(iEnt)
{
	set_entvar(iEnt, var_flags, FL_KILLME);
	set_entvar(iEnt, var_nextthink, get_gametime());
}

public plugin_natives()
{
	register_native("zpe_get_user_moneykey", "zpe_get_user_moneykey", 1);
	register_native("zpe_get_max_moneykey", "zpe_get_max_moneykey", 1);
	
	register_native("zpe_get_user_ammokey", "zpe_get_user_ammokey", 1);
	register_native("zpe_get_max_ammokey", "zpe_get_max_ammokey", 1);

	register_native("zpe_set_user_moneykey", "zpe_set_user_moneykey", 1);
	register_native("zpe_set_user_ammokey", "zpe_set_user_ammokey", 1);
	
	register_native("zpe_set_user_moneykey_wohud", "zpe_set_user_moneykey_wohud", 1);
	register_native("zpe_set_user_ammokey_wohud", "zpe_set_user_ammokey_wohud", 1);
}

public zpe_get_user_moneykey(id) return g_iUserMoneyKey[id];
public zpe_get_max_moneykey(id) return get_user_flags(id) & ADMIN_PLUS ? MAX_PLUS_MONEYKEY : MAX_MONEYKEY;

public zpe_get_user_ammokey(id) return g_iUserAmmoKey[id];
public zpe_get_max_ammokey(id) return get_user_flags(id) & ADMIN_PLUS ? MAX_PLUS_AMMOKEY : MAX_AMMOKEY;

public zpe_set_user_moneykey(id, iValue) 
{
	/*if(!task_exists(id+TASK_MONEYKEY))
	{
		g_iOldMoneyKey[id] = g_iUserMoneyKey[id];
		set_task(0.5, "task_MoneyKey", id+TASK_MONEYKEY);
	}*/
	
	UTIL_DrawCustomAmmoPickup(id, MoneyKeyWeaponList, WEAPON_MONEYKEY);
	zpe_set_user_moneykey_wohud(id, iValue)
}

public zpe_set_user_ammokey(id, iValue) 
{
	/*if(!task_exists(id+TASK_AMMOKEY))
	{
		g_iOldAmmoKey[id] = g_iUserAmmoKey[id];
		set_task(0.5, "task_AmmoKey", id+TASK_AMMOKEY);
	}*/
	
	UTIL_DrawCustomAmmoPickup(id, AmmoKeyWeaponList, WEAPON_AMMOKEY)
	zpe_set_user_ammokey_wohud(id, iValue);
}

public zpe_set_user_moneykey_wohud(id, iValue) g_iUserMoneyKey[id] = iValue;
public zpe_set_user_ammokey_wohud(id, iValue) g_iUserAmmoKey[id] = iValue;

/**
 * Стоки
 */
stock UTIL_WeapPickup( const iDest, const pReceiver, const iWeaponId )
{
	static iMsgId_WeapPickup; if ( !iMsgId_WeapPickup ) iMsgId_WeapPickup = get_user_msgid( "WeapPickup" );

	message_begin( iDest, iMsgId_WeapPickup, .player = pReceiver );
	write_byte( iWeaponId );
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

stock UTIL_DrawCustomAmmoPickup( const pReceiver, const szHudPath[ ], const any: iWeaponID )
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

	UTIL_WeaponList( iDest, pReceiver, szHudPath, -1, -1, -1, -1, 0, 20, iWeaponID, 0 );
	UTIL_WeapPickup( iDest, pReceiver, iWeaponID );

	return true;
}