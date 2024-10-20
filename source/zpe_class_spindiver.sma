#include < amxmodx >
#include < fakemeta_util >
#include < hamsandwich >
#include < zombieplague >
#include < zp_system >

#define linux_diff_weapon 		4
#define linux_diff_player 		5

#define MAX_CLIENT 32

// CBaseMonster
#define m_flNextAttack 83

// CBasePlayerItem
#define m_pPlayer 				41
#define MsgId_SayText 			76

#define TASK_POUNCE_WAIT 4201

#define ZM_CLASS_NAME 	"ML_SPINDIVER_NAME"
#define ZM_CLASS_INFO 	"ML_SPINDIVER_INFO"
#define ZM_CLASS_MODEL 	"zp_br_spindiver"
#define ZM_CLASS_CLAW 	"claws_spindiver.mdl"
#define ZM_CLASS_HEALTH 2600
#define ZM_CLASS_SPEED 235
#define ZM_CLASS_GRAVITY 0.92
#define ZM_CLASS_KNOCK 0.51

#define ZM_CLASS_POUNCE_TIME	1.0
#define ZM_CLASS_POUNCE_POWER 	400
#define ZM_CLASS_COUNTDOWN		20.0

new const SOUND_POUNCE[ ] = "zp_br_cso/zombie/male/spindiver_skill_start.wav";

#define ENABLE_WEAPONLIST		true // [ Таймер: true = Включено | false = Выключено ]

native zp_is_user_frozen(id);

new bool: g_bAbilityUse[MAX_CLIENT + 1 char],
	Float: g_flAbilityWait[MAX_CLIENT + 1],
	Float: g_flAbilityTime[MAX_CLIENT + 1],

	#if ENABLE_WEAPONLIST

		g_iMsgID_AmmoX,
		g_iMsgID_CurWeapon,
		g_iMsgID_WeaponList,

	#endif

	g_iszSpinDiver;

public plugin_init( ) 
{
	register_plugin( "[ZMO] ZClass: Spin Diver", "1.0", "xUnicorn / by TrueMan :3" );
	
	register_event( "HLTV", "EV_RoundStart", "a", "1=0", "2=0" );
	
	register_forward( FM_PlayerPreThink, "FM_Hook_PlayerPreThink_Pre" );
	
	#if ENABLE_WEAPONLIST
	
		RegisterHam(Ham_Spawn, "player", "CPlayer__Spawn_Post", true);

		RegisterHam(Ham_Item_Deploy, "weapon_knife", "CWeapon__Deploy_Post", true);
		RegisterHam(Ham_Item_PostFrame, "weapon_knife", "CKnife__PostFrame_Pre", false);

		g_iMsgID_AmmoX = get_user_msgid("AmmoX");
		g_iMsgID_CurWeapon = get_user_msgid("CurWeapon");
		g_iMsgID_WeaponList = get_user_msgid("WeaponList");

	#endif
	
	register_clcmd("drop", "Command_Ability");
	
	register_dictionary( "zp_cso_classes.txt" );
}

public plugin_precache( ) 
{
	engfunc( EngFunc_PrecacheSound, SOUND_POUNCE );
	
	g_iszSpinDiver = zp_register_zombie_class( ZM_CLASS_NAME, ZM_CLASS_INFO, ZM_CLASS_MODEL, ZM_CLASS_CLAW, ZM_CLASS_HEALTH, ZM_CLASS_SPEED, ZM_CLASS_GRAVITY, ZM_CLASS_KNOCK );
	
	#if ENABLE_WEAPONLIST

		engfunc(EngFunc_PrecacheGeneric, "sprites/zp_br_cso/zombie/zmtimer2.txt");
		register_clcmd("zp_br_cso/zombie/zmtimer2", "Command_HookWeapon");

	#endif
}

public plugin_natives()
	register_native("zp_is_class_spindriver", "zp_is_class_spindriver", 1);

public zp_is_class_spindriver() return g_iszSpinDiver;

public client_putinserver( iPlayer )
	ResetValue( iPlayer );

public client_disconnected( iPlayer )
	ResetValue( iPlayer );

public EV_RoundStart()
{
	for(new iPlayer = 1; iPlayer <= MAX_CLIENT; iPlayer++)
	{
		if(!is_user_connected(iPlayer)) continue;

		ResetValue(iPlayer);

		#if ENABLE_WEAPONLIST

			UTIL_SetWeaponList(iPlayer, "weapon_knife", -1, -1, -1, -1, 2, 1, 29, 0);

		#endif
	}
}

public zp_user_infected_post(iPlayer, iInfector, iNemesis) 
{
	if(zp_get_user_zombie(iPlayer) && zp_get_user_zombie_class(iPlayer) == g_iszSpinDiver && !zp_get_user_nemesis(iPlayer))
	{
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yСпособность !g[Рывок]!y | Кнопка: !g[G]!y")
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yВремя рывка: !gМоментально !y| Отсчёт: !g22 секунды!y")
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
	for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++)
	{
		if(!is_user_connected(iPlayer))
			continue;
		
		ResetValue(iPlayer);
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
		if(zp_get_user_zombie_class(iPlayer) != g_iszSpinDiver) return HAM_IGNORED;

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
		if(zp_get_user_zombie_class(iPlayer) != g_iszSpinDiver) return HAM_IGNORED;

		new Float: flGameTime; flGameTime = get_gametime();

		if(flGameTime < g_flAbilityWait[iPlayer])
		{
			message_begin(MSG_ONE, g_iMsgID_AmmoX, _, iPlayer);
			write_byte(15);
			write_byte(floatround(g_flAbilityWait[iPlayer] - flGameTime));
			message_end();
		}
		else
		{
			UTIL_SetWeaponList(iPlayer, "zp_br_cso/zombie/zmtimer2", -1, -1, -1, -1, 2, 1, 29, 0);
		}

		return HAM_IGNORED;
	}

#endif

public Command_Ability(iPlayer)
{
	if(!is_user_alive(iPlayer) || !zp_get_user_zombie(iPlayer) || zp_get_user_nemesis(iPlayer))
		return PLUGIN_CONTINUE;
	
	if(zp_is_user_frozen(iPlayer))
		return PLUGIN_HANDLED;

	new iWeapon = get_user_weapon(iPlayer)
	new iGrenade = check_grenade(iWeapon)
	
	if(zp_get_user_zombie_class(iPlayer) == g_iszSpinDiver)
	{
		//static Flags; 
		new Float: g_flVel[3];
		
		//Flags = pev(iPlayer, pev_flags); 
		pev(iPlayer, pev_velocity, g_flVel);
		
		static Float: flGameTime; flGameTime = get_gametime();
		
		if(g_bAbilityUse{iPlayer})
		{
			client_print(iPlayer, print_center, "Способность уже используется.");
		}
		else
		{
			//if(Flags & FL_ONGROUND) 
			//{
				if(g_flAbilityWait[iPlayer] <= flGameTime)
				{
					if(iGrenade)
					{
						client_print(iPlayer, print_center, "Нельзя использовать способность. В руках граната.");
						return PLUGIN_HANDLED;
					}
				
					g_bAbilityUse{iPlayer} = true;
					
					g_flAbilityTime[iPlayer] = flGameTime + ZM_CLASS_POUNCE_TIME;
					g_flAbilityWait[iPlayer] = flGameTime + ZM_CLASS_COUNTDOWN;

					emit_sound(iPlayer, CHAN_AUTO, SOUND_POUNCE, 1.0, ATTN_NORM, 0, PITCH_NORM);
					
					velocity_by_aim(iPlayer, ZM_CLASS_POUNCE_POWER, g_flVel);
					set_pev(iPlayer, pev_velocity, g_flVel);

					#if ENABLE_WEAPONLIST

						UTIL_SetWeaponList(iPlayer, "zp_br_cso/zombie/zmtimer2", 15, floatround(ZM_CLASS_COUNTDOWN), -1, -1, 2, 1, 29, 0);

						engfunc(EngFunc_MessageBegin, MSG_ONE, g_iMsgID_CurWeapon, {0, 0, 0}, iPlayer);
						write_byte(1);
						write_byte(CSW_KNIFE);
						write_byte(-1);
						message_end();

					#endif
				}
				else
				{
					client_print(iPlayer, print_center, "Способность не готова. Подождите %...1f", g_flAbilityWait[iPlayer] - flGameTime);
				}
			//}
		}
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public FM_Hook_PlayerPreThink_Pre(iPlayer)
{
	if(!is_user_alive(iPlayer) || !zp_get_user_zombie(iPlayer) || zp_get_user_nemesis(iPlayer)) return FMRES_IGNORED;
	if(zp_get_user_zombie_class(iPlayer) != g_iszSpinDiver) return FMRES_IGNORED;
	
	static Float: flGameTime; flGameTime = get_gametime();
	
	if(g_flAbilityTime[iPlayer] <= flGameTime)
	{
		g_bAbilityUse{iPlayer} = false;
	}
	
	return FMRES_IGNORED;
}

public UTIL_WeaponAnim( iPlayer, iSequence ) 
{ 
	set_pev( iPlayer, pev_weaponanim, iSequence );
	message_begin( MSG_ONE, SVC_WEAPONANIM, { 0, 0, 0 }, iPlayer );
	write_byte( iSequence );
	write_byte( 0 );
	message_end( );
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
