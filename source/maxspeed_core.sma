#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <api_maxspeed>

new SpeedType:g_eUser_SpeedType[33], Float:g_flUser_SpeedValue[33];

public plugin_init()
{
	register_plugin("MaxSpeed Core", "1.0", "Docaner");
	register_clcmd("maxspeed", "@ClCmd_SetMaxSpeed");

	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "@RG__Player_ResetMaxSpeed_Post", true);
}

public plugin_natives()
{
	register_native("rg_set_user_maxspeed", "@rg_set_user_maxspeed", false);
	register_native("rg_get_user_maxspeed", "@rg_get_user_maxspeed", false);
}

@ClCmd_SetMaxSpeed(const pPlayer)
{
	enum {Arg_flValue = 1}

	rg_set_user_maxspeed(pPlayer, read_argv_float(Arg_flValue));
}

@RG__Player_ResetMaxSpeed_Post(const pPlayer)
{
	if(get_member_game(m_bFreezePeriod))
		return;

	switch(g_eUser_SpeedType[pPlayer])
	{
		case e_SpeedStatic: set_entvar(pPlayer, var_maxspeed, g_flUser_SpeedValue[pPlayer]);
		case e_SpeedMul: set_entvar(pPlayer, var_maxspeed, Float:get_entvar(pPlayer, var_maxspeed) * g_flUser_SpeedValue[pPlayer]);
	}
}


@rg_set_user_maxspeed(const iPlugin, const iParams)
{
	enum { Arg_pPlayer = 1, Arg_flValue, Arg_eSpeedType }

	new pPlayer = get_param(Arg_pPlayer),
		Float:flValue = get_param_f(Arg_flValue),
		SpeedType:eSpeedType = iParams >= Arg_eSpeedType ? (SpeedType:get_param(Arg_eSpeedType)) : (SpeedType:e_SpeedStatic);

	//client_print(0, print_chat, "pPlayer: %d | flValue: %f | eSpeedType: %d", pPlayer, flValue, eSpeedType);

	if(pPlayer) core_set_user_maxspeed(pPlayer, flValue, eSpeedType);
	else
	{
		for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			core_set_user_maxspeed(iPlayer, flValue, eSpeedType);
	}
}

/**
 * Установка скорости игроку
 */
stock core_set_user_maxspeed(const pPlayer, const Float:flValue, SpeedType:eSpeedType = e_SpeedStatic)
{
	g_eUser_SpeedType[pPlayer] = eSpeedType;
	g_flUser_SpeedValue[pPlayer] = flValue;
	if(is_user_connected(pPlayer)) rg_reset_maxspeed(pPlayer);
}

Float:@rg_get_user_maxspeed(const iPlugin, const iParams)
{
	enum { Arg_pPlayer = 1, Arg_eSpeedType }

	new pPlayer = get_param(Arg_pPlayer);

	if(iParams >= Arg_eSpeedType)
		set_param_byref(Arg_eSpeedType, cell:g_eUser_SpeedType[pPlayer]);

	return g_flUser_SpeedValue[pPlayer];
}