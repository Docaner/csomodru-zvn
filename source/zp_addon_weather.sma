#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <smart_effects>

new g_pEnt_Weather = NULLENT;

/*public plugin_precache()
	@weather(0);
*/

public plugin_init()
{
	register_plugin("[ZP] Weather", "1.0", "Docaner");
	register_clcmd("weather", "@weather");
}

@weather(id)
{
	new pEnt = g_pEnt_Weather;
	
	if(is_nullent(pEnt) && ( pEnt = Create_Weather() ) == NULLENT )
		return PLUGIN_HANDLED;

	g_pEnt_Weather = pEnt;

	//m_iMode

	//UTIL_SetRendering(pEnt, _, Float:{255.0, 0.0, 0.0}, _, 255.0);

	ExecuteHamB(Ham_Spawn, pEnt);

	client_print(0, print_chat, "Дождь")

	return PLUGIN_HANDLED;
}

stock Create_Weather()
{
	new pEnt = rg_create_entity("env_rain");

	if(is_nullent(pEnt))
		return NULLENT;

	return pEnt;
}