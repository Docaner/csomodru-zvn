#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
#include < zombieplague >
#include < zp_system >

#define linux_diff_weapon 		4
#define linux_diff_player 		5

// CBasePlayerItem
#define m_pPlayer				41
#define MsgId_SayText 76

#define MAX_CLIENTS		32

#define NEMESIS_EXPLODE_RADIUS	350.0
#define NEMESIS_EXPLODE_DAMAGE	75.0

#define NEMESIS_EFFECTS_COLOR1	0 // Red
#define NEMESIS_EFFECTS_COLOR2	128 // Green
#define NEMESIS_EFFECTS_COLOR3	255 // Blue

#define NEMESIS_EXPLODE_TIME	1.0
#define NEMESIS_COUNTDOWN		12.0

#define NEMESIS_EXPLODE_SOUND	"zp_br_cso/zombie/male/nemesis_skill_start_b2.wav"

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
	g_iszModelIndexSpriteBeam;

public plugin_init()
{
	register_plugin("[ZP] Nemesis Ability: Metatronic", "1.0", "xUnicorn / by TrueMan :3");

	register_event("HLTV", "EV_RoundStart", "a", "1=0", "2=0");

	RegisterHam(Ham_Killed, "player", "CPlayer__Killed_Pre", .Post = 0);
	
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

	register_clcmd("drop", "Command_Ability");
	
	register_dictionary("zp_cso_classes.txt");
}

public plugin_precache()
{
	g_iszModelIndexSpriteBeam = engfunc(EngFunc_PrecacheModel, "sprites/shockwave.spr");

	engfunc(EngFunc_PrecacheSound, NEMESIS_EXPLODE_SOUND);
}

public client_putinserver(iPlayer)  ResetValue(iPlayer);
public client_disconnected(iPlayer) ResetValue(iPlayer);

public EV_RoundStart()
{
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_connected(iPlayer))
			continue;

		ResetValue(iPlayer);
		
		#if ENABLE_WEAPONLIST

			UTIL_SetWeaponList(iPlayer, "weapon_knife", -1, -1, -1, -1, 2, 1, 29, 0);

		#endif
	}
}

public CPlayer__Killed_Pre(iVictim, iAttacker, iGib)
{
	if(!is_user_connected(iVictim))
		return;

	ResetValue(iVictim);
}

public zp_user_infected_post(iPlayer) 
{
	if(zp_get_user_nemesis(iPlayer))
	{
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yСпособность !g[Взрывная Волна]!y | Кнопка: !g[G]!y")
		UTIL_SayText(iPlayer, "!g[ZOMBIE] !yВремя запуска волны: !gМоментально !y| Отсчёт: !g12 секунд!y")
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
		static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

		if(zp_get_user_nemesis(iPlayer))
		{
			new Float: flGameTime; flGameTime = get_gametime();

			if(flGameTime < g_flAbilityWait[iPlayer])
			{
				UTIL_SetWeaponList(iPlayer, "zp_br_cso/zombie/zmtimer2", 15, floatround(NEMESIS_COUNTDOWN), -1, -1, 2, 1, 29, 0);

				message_begin(MSG_ONE, g_iMsgID_AmmoX, _, iPlayer);
				write_byte(15);
				write_byte(floatround(g_flAbilityWait[iPlayer] - flGameTime));
				message_end();
			}
			else UTIL_SetWeaponList(iPlayer, "zp_br_cso/zombie/zmtimer2", -1, -1, -1, -1, 2, 1, 29, 0);
		}

		return HAM_IGNORED;
	}

	public CKnife__PostFrame_Pre(iItem)
	{
		static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

		if(zp_get_user_nemesis(iPlayer))
		{
			new Float: flGameTime; flGameTime = get_gametime();

			if(flGameTime < g_flAbilityWait[iPlayer])
			{
				message_begin(MSG_ONE, g_iMsgID_AmmoX, _, iPlayer);
				write_byte(15);
				write_byte(floatround(g_flAbilityWait[iPlayer] - flGameTime));
				message_end();
			}
			else UTIL_SetWeaponList(iPlayer, "zp_br_cso/zombie/zmtimer2", -1, -1, -1, -1, 2, 1, 29, 0);
		}

		return HAM_IGNORED;
	}

#endif

public Command_Ability(iPlayer)
{
	if(!is_user_alive(iPlayer) || !zp_get_user_zombie(iPlayer) || !zp_get_user_nemesis(iPlayer)) 
		return PLUGIN_CONTINUE;
		
	if(zp_is_round_end())
		return PLUGIN_HANDLED;

	new Float: vecOrigin[3];
	pev(iPlayer, pev_origin, vecOrigin);
	
	if(zp_get_user_nemesis(iPlayer))
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
				static iVictim = -1;
				
				g_bAbilityUse{iPlayer} = true;

				g_flAbilityTime[iPlayer] = flGameTime + NEMESIS_EXPLODE_TIME;
				g_flAbilityWait[iPlayer] = flGameTime + NEMESIS_COUNTDOWN;

				while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, NEMESIS_EXPLODE_RADIUS)))
				{
					if(iPlayer == iVictim || !is_user_alive(iVictim) || zp_get_user_zombie(iVictim))
						continue;

					ExecuteHamB(Ham_TakeDamage, iVictim, 0, iPlayer, NEMESIS_EXPLODE_DAMAGE, DMG_BURN | DMG_NEVERGIB);
				}
	
				engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
				write_byte(TE_BEAMCYLINDER); // TE id
				engfunc(EngFunc_WriteCoord, vecOrigin[0]); // x
				engfunc(EngFunc_WriteCoord, vecOrigin[1]); // y
				engfunc(EngFunc_WriteCoord, vecOrigin[2]); // z
				engfunc(EngFunc_WriteCoord, vecOrigin[0]); // x axis
				engfunc(EngFunc_WriteCoord, vecOrigin[1]); // y axis
				engfunc(EngFunc_WriteCoord, vecOrigin[2] + NEMESIS_EXPLODE_RADIUS); // z axis
				write_short(g_iszModelIndexSpriteBeam); // sprite
				write_byte(0); // startframe
				write_byte(0); // framerate
				write_byte(6); // life
				write_byte(60); // width
				write_byte(0); // noise
				write_byte(NEMESIS_EFFECTS_COLOR1); // red
				write_byte(NEMESIS_EFFECTS_COLOR2); // green
				write_byte(NEMESIS_EFFECTS_COLOR3); // blue
				write_byte(200); // brightness
				write_byte(0); // speed
				message_end();

				emit_sound(iPlayer, CHAN_AUTO, NEMESIS_EXPLODE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

				#if ENABLE_WEAPONLIST

					UTIL_SetWeaponList(iPlayer, "zp_br_cso/zombie/zmtimer2", 15, floatround(NEMESIS_COUNTDOWN), -1, -1, 2, 1, 29, 0);

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
	if(!is_user_alive(iPlayer) || !zp_get_user_zombie(iPlayer) || !zp_get_user_nemesis(iPlayer)) return FMRES_IGNORED;
	
	if(zp_get_user_nemesis(iPlayer))
	{
		static Float: flGameTime; flGameTime = get_gametime();
	
		if(g_flAbilityTime[iPlayer] <= flGameTime)
		{
			g_bAbilityUse{iPlayer} = false;
		}
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