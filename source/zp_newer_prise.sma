#include <amxmodx>
#include <zp_system>
#include <reapi>

#define DELAY 10.0 // Раз в сколько минут выдавать бонус

#define AMMO random_num(3, 6) // Сколько аммо выдавать
#define MONEY random_num(2000, 4000) // Сколько денег выдавать

new const NAME_PREFIX[] = "CSOMOD.RU |"; // Префикс в чате
new const SOUND_MESSAGE[] = "sound/zp_br_cso/other/level_up.wav";

native get_user_afk(id);

#define TASK_PRESENTS 434355
#define TASK_CONNECTION 342535

public plugin_precache()
	precache_generic(SOUND_MESSAGE);

public plugin_init()
{
	register_plugin("[ZP] Newer Presents", "1.0", "Docaner");
	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "@RG__SetClientUserInfoName_Post", true);
}

@RG__SetClientUserInfoName_Post(id, infobuffer[], szNewName[])
	checkNameForBonus(id, szNewName);

public client_putinserver(id)
	set_task(5.0, "@taskConnection", id+TASK_CONNECTION);

@taskConnection(id)
{
	id -= TASK_CONNECTION;
	checkNameForBonus(id);
}

public client_disconnected(id)
{
	remove_task(id+TASK_PRESENTS);
	remove_task(id+TASK_CONNECTION);
}

stock checkNameForBonus(id, szNewName[] = "^0")
{
	remove_task(id+TASK_PRESENTS);
	remove_task(id+TASK_CONNECTION);

	new szName[32];

	if(szNewName[0] == '^0')
		get_user_name(id, szName, charsmax(szName));
	else
		copy(szName, charsmax(szName), szNewName);

	if(contain(szName, NAME_PREFIX) != 0)
		return;

	client_print_color(id, id, "^4[БОНУС] ^1Вы выставили ник с приставкой ^4CSOMOD.RU^1. Бонус через ^4%d ^1мин.", floatround(DELAY));
	client_cmd(id, "spk ^"%s^"", SOUND_MESSAGE);
	
	set_task(DELAY * 60.0, "@taskPresents", id+TASK_PRESENTS, _, _, "b");
}

@taskPresents(id)
{
	id -= TASK_PRESENTS;

	if(is_nullent(id))
		return;

	new TeamName:team = get_member(id, m_iTeam);

	if (team == TEAM_SPECTATOR || team == TEAM_UNASSIGNED)
		return;

	new iRandomMoney = MONEY, iRandomAmmo = AMMO;

	zp_set_user_money(id, zp_get_user_money(id) + iRandomMoney);
	zp_set_user_ammo(id, zp_get_user_ammo(id) + iRandomAmmo);

	client_print_color(id, id, "^4[БОНУС] ^1Вам выдано ^4%d$ ^1и ^4%d аммо^1 за приставку ^4CSOMOD.RU", iRandomMoney, iRandomAmmo);
	client_cmd(id, "spk ^"%s^"", SOUND_MESSAGE);
}


