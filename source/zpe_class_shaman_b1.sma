#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <zombieplague>

new const g_szClassName[] = {"ML_SHAMAN_NAME"};			// Название класса 
new const g_szClassInfo[] = {"ML_SHAMAN_INFO"};			// Описание класса
new const g_szClassModel[] = "zp_br_voodoo_b10";			// Модель класса
new const g_szClassClawModel[] = "claws_shaman_b5.mdl";	// Модель рук класса
#define CLASS_HEALTH 2200								// Здоровье
#define CLASS_SPEED 235									// Скорость
#define CLASS_GRAVITY 0.85								// Гравитация
#define CLASS_KNOCKBACK 0.63							// Отбрасывание

#define ABILITY_BARTIME 1 	// На сколько секунд нужно зажать [E], чтобы активировать способность
#define ABILITY_RESTTIME 25.0 // Перезагрузка способности в секундах
#define ABILITY_DURATUON 3 // Длительность способности в секундах
#define ABILITY_RADIUS 120.0 // Радиус способности

new const g_szSoundScream[] = "zp_br_cso/zombie/male/shaman_skill.wav"; // Звук крика
new const g_szSpriteModel[] = "sprites/shockwave.spr"; // Спрайт колец

new const g_szWpnlistModel[] = "sprites/zp_br_cso/zombie/zmtimer2.txt" // Weaponlist таймер 
new const g_szWpnlistName[] = "zp_br_cso/zombie/zmtimer2" // Название weaponlist

#define TASK_ABILITY 2363434

#define UNIT_SECOND (1<<12)

#define MsgId_SayText 76

new g_iClassShaman, g_iShokwave;
new g_iMsgID_ScreanFade, g_iMsgID_ScreenShake, g_iMsgID_AmmoX, g_iMsgID_CurWeapon, g_iMsgID_WeaponList;

enum
{
	ABILITY_NO = 0,
	ABILITY_READY,
	ABILITY_THINK,
	ABILITY_RESTART
}

new Float:g_fUserWait[33];

public plugin_precache()
{
	g_iClassShaman = zp_register_zombie_class(g_szClassName, g_szClassInfo, g_szClassModel, 
		g_szClassClawModel, CLASS_HEALTH, CLASS_SPEED, CLASS_GRAVITY, CLASS_KNOCKBACK);

	precache_sound(g_szSoundScream);
	g_iShokwave = precache_model(g_szSpriteModel)

	precache_generic(g_szWpnlistModel);
	register_clcmd(g_szWpnlistName, "Command_HookWeapon");

}

public plugin_init()
{
	register_plugin("Pizdatiy Shaman", "1.0", "Docaner");

	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", 1);

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "HM_KnifeDeploy_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_knife", "HM_KnifePostFrame_Pre", 0);
	RegisterHam(Ham_Item_Holster, "weapon_knife", "HM_KnifeHolster_Post", 1);

	g_iMsgID_ScreanFade = get_user_msgid("ScreenFade");
	g_iMsgID_ScreenShake = get_user_msgid("ScreenShake");
	g_iMsgID_AmmoX = get_user_msgid("AmmoX");
	g_iMsgID_CurWeapon = get_user_msgid("CurWeapon");
	g_iMsgID_WeaponList = get_user_msgid("WeaponList");

	register_dictionary("zp_cso_classes.txt");
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	if(is_user_alive(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_iClassShaman)
		set_default_values(id);
}

public zp_user_humanized_pre(id, survivor)
{
	if(!zp_get_user_nemesis(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_iClassShaman)
		set_default_values(id);
}

public zp_user_infected_post(id, infector, nemesis)
{
	if(zp_get_user_zombie_class(id) == g_iClassShaman)
	{
		if(nemesis)
			set_default_values(id);
		else
		{
			new iWeapon = rg_find_weapon_bpack_by_name(id, "weapon_knife");
			if(!is_nullent(iWeapon)) set_member(iWeapon, m_Weapon_iWeaponState, ABILITY_READY);

			UTIL_SayText(id, "!g[ZOMBIE] !yСпособность !g[Шоковая Волна]!y | Кнопка: !g[R] !y(удерж.)")
			UTIL_SayText(id, "!g[ZOMBIE] !yВремя шоковой волны: !g3 сек. !y| Отсчёт: !g25 секунд!y")
		}

	}
}

public zp_round_ended(winteam)
{
	for(new i = 1; i <= get_maxplayers(); i++)
	{
		if(is_user_alive(i) && !zp_get_user_nemesis(i) && zp_get_user_zombie(i) && zp_get_user_zombie_class(i) == g_iClassShaman)
			set_default_values(i);
	}
}

public Command_HookWeapon(id)
{
	engclient_cmd(id, "weapon_knife");
	return PLUGIN_HANDLED;
}

public CBasePlayer_Killed_Post(iVictim)
{
	if(!zp_get_user_nemesis(iVictim) && zp_get_user_zombie(iVictim) && zp_get_user_zombie_class(iVictim) == g_iClassShaman)
		set_default_values(iVictim);
}

public HM_KnifeDeploy_Post(iEnt)
{
	new id = get_member(iEnt, m_pPlayer);

	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) || 
		zp_get_user_zombie_class(id) != g_iClassShaman) 
		return HAM_IGNORED;

	new iWeaponState = get_member(iEnt, m_Weapon_iWeaponState);
	switch(iWeaponState)
	{
		case ABILITY_RESTART: 
		{
			chek_user_ability_timer(id, iEnt, true);
		}
	}

	return HAM_IGNORED;
}

public HM_KnifePostFrame_Pre(iEnt)
{
	new id = get_member(iEnt, m_pPlayer);

	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) ||
		zp_get_user_zombie_class(id) != g_iClassShaman)
		return HAM_IGNORED;

	new iWeaponState = get_member(iEnt, m_Weapon_iWeaponState);

	switch(iWeaponState)
	{
		case ABILITY_NO: {}
		case ABILITY_RESTART: chek_user_ability_timer(id, iEnt);
		default:
		{
			static Float:flBarTime[33];

			if(get_member(id, m_afButtonPressed) & IN_RELOAD)
			{
				iWeaponState = ABILITY_THINK; set_member(iEnt, m_Weapon_iWeaponState, iWeaponState);
				flBarTime[id] = get_gametime() + float(ABILITY_BARTIME);

				rg_send_bartime(id, ABILITY_BARTIME, false);
			}

			if(get_member(id, m_afButtonReleased) & IN_RELOAD)
			{
				iWeaponState = ABILITY_READY; set_member(iEnt, m_Weapon_iWeaponState, iWeaponState);
				rg_send_bartime(id, 0, false);
			}

			if(flBarTime[id] <= get_gametime() && iWeaponState == ABILITY_THINK)
			{
				g_fUserWait[id] = get_gametime() + ABILITY_RESTTIME;
				iWeaponState = ABILITY_RESTART; set_member(iEnt, m_Weapon_iWeaponState, iWeaponState);

				UTIL_SetWeaponList(id, g_szWpnlistName, 15, floatround(ABILITY_RESTTIME, floatround_ceil), -1, -1, 2, 1, CSW_KNIFE, 0);
				CURWEAPON(id, 1, CSW_KNIFE, -1);
				AMMOX(id, 15, floatround(ABILITY_RESTTIME, floatround_ceil));

				start_user_ability(id);
			}
		}
	}

	

	return HAM_IGNORED;
}

public HM_KnifeHolster_Post(iEnt)
{
	new id = get_member(iEnt, m_pPlayer);

	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) ||
		zp_get_user_zombie_class(id) != g_iClassShaman)
		return HAM_IGNORED;

	new iWeaponState; get_member(iEnt, m_Weapon_iWeaponState);
	if(iWeaponState == ABILITY_THINK)
	{
		iWeaponState = ABILITY_READY; set_member(iEnt, m_Weapon_iWeaponState, iWeaponState);
		rg_send_bartime(id, 0, false);
	}

	return HAM_IGNORED;
}

start_user_ability(id)
{
	emit_sound(id, CHAN_AUTO, g_szSoundScream, 1.0, ATTN_NORM, 0, PITCH_NORM);

	new Float:fOrigin[3];
	get_entvar(id, var_origin, fOrigin);
	CREATE_LAVASPLASH(fOrigin);

	set_task(0.1, "task_Scream", TASK_ABILITY+id, _, _, "a", ABILITY_DURATUON * 10);
}

public task_Scream(id)
{
	id -= TASK_ABILITY;

	new Float:fOrigin[3];
	get_entvar(id, var_origin, fOrigin);

	CREATE_BEAMCYLINDER(fOrigin, floatround(ABILITY_RADIUS * 2.5), g_iShokwave, _, _, 4, 25, _, 255, 0, 0, 200, _);
	SCREEN_FADE(id, 1, 1, SF_FADE_MODULATE, 200, 0, 0, 125);
	SCREEN_SHAKE(id, 5, 1, 5);

	new iVictim, Float:fHealth;
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, fOrigin, ABILITY_RADIUS)))
	{
		if(!is_user_alive(iVictim) || is_nullent(iVictim) || zp_get_user_zombie(iVictim)) continue;

		SCREEN_FADE(iVictim, 1, 1, SF_FADE_MODULATE, 200, 0, 0, 125);
		SCREEN_SHAKE(iVictim, 5, 1, 5);

		get_entvar(iVictim, var_health, fHealth);
		fHealth -= 1.5;
		if(fHealth > 0.0) set_entvar(iVictim, var_health, fHealth);
		else if(zp_is_swarm_round() || zp_is_plague_round() || zp_is_survivor_round() || 
			!zp_infect_user(iVictim, id, 0, 1))
		{
			ExecuteHamB(Ham_Killed, iVictim, id, GIB_NEVER);
		} 

	}
}

set_default_values(id)
{
	if(is_user_connected(id))
	{
		new iWeapon = rg_find_weapon_bpack_by_name(id, "weapon_knife");
		if(!is_nullent(iWeapon))
		{
			new iWeaponState = get_member(iWeapon, m_Weapon_iWeaponState);
			if(iWeaponState == ABILITY_THINK) rg_send_bartime(id, 0, false);
			iWeaponState = ABILITY_NO; set_member(iWeapon, m_Weapon_iWeaponState, iWeaponState);
		}
		UTIL_SetWeaponList(id, "weapon_knife", -1, -1, -1, -1, 2, 1, 29, 0);
	}

	remove_task(TASK_ABILITY+id);
	g_fUserWait[id] = 0.0;
}

chek_user_ability_timer(id, iWeapon, bool:bReloadWpnlist = false)
{
	new Float:flGameTime = get_gametime();

	if(flGameTime < g_fUserWait[id])
	{
		if(bReloadWpnlist)
		{
			UTIL_SetWeaponList(id, g_szWpnlistName, 15, floatround(ABILITY_RESTTIME, floatround_ceil), -1, -1, 2, 1, CSW_KNIFE, 0);
			CURWEAPON(id, 1, CSW_KNIFE, -1);
		}

		AMMOX(id, 15, floatround(g_fUserWait[id] - flGameTime, floatround_ceil));
	}
	else 
	{
		UTIL_SetWeaponList(id, g_szWpnlistName, -1, -1, -1, -1, 2, 1, CSW_KNIFE, 0);
		set_member(iWeapon, m_Weapon_iWeaponState, ABILITY_READY);
	}
}

stock CREATE_LAVASPLASH(Float:fOrigin[3])
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin);
	write_byte(TE_LAVASPLASH);
	write_coord_f(fOrigin[0]);
	write_coord_f(fOrigin[1]);
	write_coord_f(fOrigin[2]);
	message_end()
}

stock CREATE_BEAMCYLINDER(Float:vecOrigin[3], iRadius, pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0)
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_BEAMCYLINDER);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2]);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2] + iRadius);
	write_short(pSprite);
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

stock SCREEN_FADE(id, iDuration, iHoldtime, iFadeType, iRed, iGreen, iBlue, iAlpha)
{
	message_begin(MSG_ONE_UNRELIABLE, g_iMsgID_ScreanFade, _, id)
	write_short(UNIT_SECOND*iDuration) // duration
	write_short(UNIT_SECOND*iHoldtime) // hold time
	write_short(iFadeType) // fade type
	write_byte(iRed) // r
	write_byte(iGreen) // g
	write_byte(iBlue) // b
	write_byte(iAlpha) // alpha
	message_end()
}

stock SCREEN_SHAKE(id, iAmplitude, iDuration, iFrequency)
{
	message_begin(MSG_ONE_UNRELIABLE, g_iMsgID_ScreenShake, _, id)
	write_short(UNIT_SECOND*iAmplitude) // amplitude
	write_short(UNIT_SECOND*iDuration) // duration
	write_short(UNIT_SECOND*iFrequency) // frequency
	message_end()
}

stock AMMOX(id, iAmmoId, iAmount)
{
	message_begin(MSG_ONE, g_iMsgID_AmmoX, _, id);
	write_byte(iAmmoId);
	write_byte(iAmount);
	message_end();
}

stock CURWEAPON(id, IsActive, iWeaponID, iClipAmmo)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE, g_iMsgID_CurWeapon, {0, 0, 0}, id);
	write_byte(IsActive);
	write_byte(iWeaponID);
	write_byte(iClipAmmo);
	message_end();
}

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