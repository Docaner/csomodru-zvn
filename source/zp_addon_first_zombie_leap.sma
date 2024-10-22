#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <xs>
#include <hamsandwich>

new Float:g_lastleaptime[33]

public plugin_init()
{
    register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
}

public fw_PlayerPreThink(pVictim)
{
    static Float:cooldown, Float:current_time
    current_time = get_gametime()

    if(!zp_get_user_first_zombie(pVictim))
        return;
	
	// Cooldown not over yet
    if (current_time - g_lastleaptime[pVictim] < cooldown)
        return;
		
	if (!(pev(pVictim, pev_button) & (IN_JUMP | IN_DUCK) == (IN_JUMP | IN_DUCK)))
		return;
	
	// Not on ground or not enough speed
	if (!(pev(pVictim, pev_flags) & FL_ONGROUND) || fm_get_speed(pVictim) < 80)
		return;
	
	static Float:fzmvelocity[3]
    new Float:fzmcurvelocity[3]

    pev(pVictim, pev_velocity, fzmcurvelocity)
	
    client_print_color(0, 0, "%f %f %f", fzmcurvelocity[0],fzmcurvelocity[1],fzmcurvelocity[2])
    client_print_color(0, 0, "%f %f %f", fzmvelocity[0],fzmvelocity[1],fzmvelocity[2])
	// Make fzmvelocity vector
	/* velocity_by_aim(pVictim, 1.2, fzmcurvelocity[0])
    velocity_by_aim(pVictim, 1.2, fzmcurvelocity[1]) */
	
    fzmvelocity[0] = fzmcurvelocity[0]
    fzmvelocity[1] = fzmcurvelocity[1]
	// Set custom height
	fzmvelocity[2] =  fzmcurvelocity [2] + 300.0
	
	// Apply the new fzmvelocity
	set_pev(pVictim, pev_velocity, fzmvelocity)
	
	// Update last leap time
	g_lastleaptime[pVictim] = current_time
}

stock fm_get_speed(entity)
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	
	return floatround(vector_length(velocity));
}
