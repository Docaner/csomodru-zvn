#include <zpe_lvl>
#include <amxmodx>

public plugin_init(){
    register_clcmd("lvldown", "lvldown")
    register_clcmd("lvlup10", "lvlup10")
    register_clcmd("lvlup15", "lvlup15")
}

public lvldown(id)
{
    zpe_set_user_lvl(id, 0)
}

public lvlup10(id)
{
    zpe_set_user_lvl(id, 10)
}

public lvlup15(id)
{
    zpe_set_user_lvl(id, 15)
}
