#include <amxmodx>
#include <zombieplague>
#include <api_flame>

public zp_flame_params_change_post(const pEntBase, const pVictim, const pAttacker, const Float:flSeconds)
{
    if(!zp_get_user_first_zombie(pVictim))
        return;

    set_entvar(pEntBase, var_ltime, get_gametime() + flSeconds / 15.0);

}