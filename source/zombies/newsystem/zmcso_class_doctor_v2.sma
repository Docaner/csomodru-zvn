#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <zp_system>
#include <zc_addon_zclasses>
#include <zc_addon_zchoose>

#define linux_diff_weapon 		4
#define linux_diff_player 		5

// CBasePlayerItem
#define m_pPlayer				41
#define MsgId_SayText 			76

#define MAX_CLIENTS			32

new g_iszModelIndexSpriteBeam;
new g_iszModelIndexSpriteHeal;
new g_iszModelIndexSpriteHealZombie;

#define ZM_CLASS_HEALING_TIME	1.0
#define ZM_CLASS_COUNTDOWN		30.0

#define HEAL_START_SOUND		"zp_br_cso/zombie/male/healer_skill_start.wav"

#define ENABLE_WEAPONLIST		true // [ Таймер: true = Включено | false = Выключено ]

new bool: g_bAbilityUse[MAX_CLIENTS + 1 char],
	Float: g_flAbilityWait[MAX_CLIENTS + 1],
	Float: g_flAbilityTime[MAX_CLIENTS + 1],

	#if ENABLE_WEAPONLIST

		g_iMsgID_AmmoX,
		g_iMsgID_CurWeapon,
		g_iMsgID_WeaponList,

	#endif

	g_iMaxPlayers,
	g_iZClassHeal;

public plugin_init( )
{
	register_plugin("[ZM] ZClass: Doctor", "1.0", "xUnicorn / by TrueMan :3");
	
	register_event("HLTV", "EV_RoundStart", "a", "1=0", "2=0");
	
	register_forward(FM_PlayerPreThink, "FM_Hook_PlayerPreThink_Pre", false);
	
	#if ENABLE_WEAPONLIST
	
		RegisterHam(Ham_Spawn, "player", "CPlayer__Spawn_Post", true);

		RegisterHam(Ham_Item_Deploy, "weapon_knife", "CWeapon__Deploy_Post", true);
		RegisterHam(Ham_Item_PostFrame, "weapon_knife", "CKnife__PostFrame_Pre", false);

		g_iMsgID_AmmoX = get_user_msgid("AmmoX");
		g_iMsgID_CurWeapon = get_user_msgid("CurWeapon");
		g_iMsgID_WeaponList = get_user_msgid("WeaponList");

	#endif

	g_iMaxPlayers = get_maxplayers();

	g_iZClassHeal = zc_find_zclass_by_shortname("healer");
	
	register_clcmd( "drop", "Command_Ability" );
	
	register_dictionary( "zp_cso_classes.txt" );
}

public plugin_precache( )
{
	engfunc( EngFunc_PrecacheSound, HEAL_START_SOUND );

	g_iszModelIndexSpriteBeam = engfunc( EngFunc_PrecacheModel, "sprites/shockwave.spr" );
	g_iszModelIndexSpriteHeal = engfunc( EngFunc_PrecacheModel, "sprites/zp_br_cso/zombie/zombiehealer.spr" );
	g_iszModelIndexSpriteHealZombie = engfunc( EngFunc_PrecacheModel, "sprites/zp_br_cso/zombie/zombieheal_head.spr" );
	
	#if ENABLE_WEAPONLIST

		engfunc(EngFunc_PrecacheGeneric, "sprites/zp_br_cso/zombie/zmtimer2.txt");
		register_clcmd("zp_br_cso/zombie/zmtimer2", "Command_HookWeapon");

	#endif
}

public client_putinserver(iPlayer) ResetValue(iPlayer);
public client_disconnected(iPlayer) ResetValue(iPlayer);

public zp_user_infected_post(iPlayer, iInfector, iNemesis) 
{
	if(zp_get_user_zombie(iPlayer) && zc_get_user_zclass(iPlayer) == g_iZClassHeal && !zp_get_user_nemesis(iPlayer))
	{
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yСпособность !g[Лечение]!y | Кнопка: !g[G]!y")
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yВремя лечения: !gМоментально !y| Отсчёт: !g30 секунд!y")
	}
	
	ResetValue(iPlayer);

	#if ENABLE_WEAPONLIST

		UTIL_SetWeaponList(iPlayer, "weapon_knife", -1, -1, -1, -1, 2, 1, 29, 0);
		return;

	#endif
}

public zp_user_humanized_post(iPlayer) 
{
	ResetValue(iPlayer);

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
		if(zc_get_user_zclass(iPlayer) != g_iZClassHeal) return HAM_IGNORED;

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
		if(zc_get_user_zclass(iPlayer) != g_iZClassHeal) return HAM_IGNORED;

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

public Command_Ability( iPlayer )
{
	if(!is_user_alive(iPlayer) || !zp_get_user_zombie(iPlayer) || zp_get_user_nemesis(iPlayer))
		return PLUGIN_CONTINUE;
		
	if(zp_is_round_end())
		return PLUGIN_HANDLED;
	
	new iWeapon = get_user_weapon(iPlayer)
	new iGrenade = check_grenade(iWeapon)
	
	if(zc_get_user_zclass(iPlayer) == g_iZClassHeal)
	{	
		static Float: flGameTime; flGameTime = get_gametime();

		if(g_bAbilityUse{iPlayer})
		{
			client_print(iPlayer, print_center, "Способность уже используется.");
		}
		else
		{
			if(g_flAbilityWait[iPlayer] <= flGameTime)
			{
				if(iGrenade)
					return PLUGIN_HANDLED;
				
				g_bAbilityUse{iPlayer} = true;

				g_flAbilityTime[iPlayer] = flGameTime + ZM_CLASS_HEALING_TIME;
				g_flAbilityWait[iPlayer] = flGameTime + ZM_CLASS_COUNTDOWN;
				
				new szName[ 32 ];
				get_user_name( iPlayer, szName, 31 );
			
				new Float: vecOrigin[ 3 ];
				pev( iPlayer, pev_origin, vecOrigin );
			
				static iVictim;
				iVictim = -1;
			
				while( ( iVictim = engfunc( EngFunc_FindEntityInSphere, iVictim, vecOrigin, 200.0 ) ) )
				{
					if( iPlayer == iVictim || !is_user_alive( iVictim ) || !zp_get_user_zombie( iVictim ) )
						continue;

					new Float: flCurrentHealth, Float: flMaximumHealth;
				
					pev( iVictim, pev_health, flCurrentHealth );
					pev( iVictim, pev_max_health, flMaximumHealth );

					if( flCurrentHealth < flMaximumHealth )
					{
						new Float: flSetHealth;
						flSetHealth = floatmin( flMaximumHealth, ( flCurrentHealth + 500 ) );

						set_pev( iVictim, pev_health, flSetHealth );

						// UTIL_PlayVoiceSound( iVictim, HEAL_START_SOUND );

						new iOrigin[ 3 ];
						get_user_origin( iVictim, iOrigin, 1 );

						new Float: vecEnd[ 3 ];

						vecEnd[ 0 ] = float( iOrigin[ 0 ] );
						vecEnd[ 1 ] = float( iOrigin[ 1 ] );
						vecEnd[ 2 ] = float( iOrigin[ 2 ] );

						engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEnd, 0 );
						write_byte( TE_SPRITE );
						engfunc( EngFunc_WriteCoord, vecEnd[ 0 ] );
						engfunc( EngFunc_WriteCoord, vecEnd[ 1 ] );
						engfunc( EngFunc_WriteCoord, vecEnd[ 2 ] + 25.0 );
						write_short( g_iszModelIndexSpriteHealZombie );
						write_byte( 10 );
						write_byte( 255 );
						message_end( );

						client_print( iVictim, print_center, "%L %s", iVictim, "HEALER_ABILITY_INFO_2", szName );
						
						zp_set_user_money( iPlayer, zp_get_user_money( iPlayer ) + 250 )
					}
				}

				new Float: flHealth, Float: flMaxHealth;

				pev( iPlayer, pev_health, flHealth );
				pev( iPlayer, pev_max_health, flMaxHealth );

				if( flHealth < flMaxHealth ) set_pev( iPlayer, pev_health, floatmin( flHealth + flMaxHealth * 0.1, flMaxHealth ) );

				engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0 );
				write_byte( TE_SPRITE );
				engfunc( EngFunc_WriteCoord, vecOrigin[ 0 ] );
				engfunc( EngFunc_WriteCoord, vecOrigin[ 1 ] );
				engfunc( EngFunc_WriteCoord, vecOrigin[ 2 ] + 10.0 );
				write_short( g_iszModelIndexSpriteHeal );
				write_byte( 12 );
				write_byte( 255 );
				message_end( );
			
				engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0 );
				write_byte ( TE_BEAMCYLINDER );
				engfunc( EngFunc_WriteCoord, vecOrigin [ 0 ] );
				engfunc( EngFunc_WriteCoord, vecOrigin [ 1 ] );
				engfunc( EngFunc_WriteCoord, vecOrigin [ 2 ] );
				engfunc( EngFunc_WriteCoord, vecOrigin [ 0 ] );
				engfunc( EngFunc_WriteCoord, vecOrigin [ 1 ] );
				engfunc( EngFunc_WriteCoord, vecOrigin [ 2 ] + 200.0 );
				write_short( g_iszModelIndexSpriteBeam );
				write_byte( 0 );
				write_byte( 0 );
				write_byte( 4 );
				write_byte( 60 );
				write_byte( 0 );
				write_byte( 0 );
				write_byte( 255 );
				write_byte( 0 );
				write_byte( 200 );
				write_byte( 0 );
				message_end( );
				
				emit_sound(iPlayer, CHAN_AUTO, HEAL_START_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

				client_print( iPlayer, print_center, "%L", iPlayer, "HEALER_ABILITY_INFO" );

				#if ENABLE_WEAPONLIST

					UTIL_SetWeaponList(iPlayer, "zp_br_cso/zombie/zmtimer2", 15, floatround(ZM_CLASS_COUNTDOWN), -1, -1, 2, 1, 29, 0);

					engfunc(EngFunc_MessageBegin, MSG_ONE, g_iMsgID_CurWeapon, {0, 0, 0}, iPlayer);
					write_byte(1);
					write_byte(CSW_KNIFE);
					write_byte(-1);
					message_end();

				#endif
			}
		}

		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public FM_Hook_PlayerPreThink_Pre(iPlayer)
{
	if(!is_user_alive(iPlayer) || !zp_get_user_zombie(iPlayer) || zp_get_user_nemesis(iPlayer)) return FMRES_IGNORED;
	if(zc_get_user_zclass(iPlayer) != g_iZClassHeal) return FMRES_IGNORED;
	
	static Float: flGameTime; flGameTime = get_gametime();
	
	if(g_flAbilityTime[iPlayer] <= flGameTime)
	{
		g_bAbilityUse{iPlayer} = false;
	}
	
	return FMRES_IGNORED;
}

ResetValue(iPlayer)
{
	g_bAbilityUse{iPlayer} = false;

	g_flAbilityTime[iPlayer] = 0.0;
	g_flAbilityWait[iPlayer] = 0.0;
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