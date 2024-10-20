#include <amxmodx>
#include <hamsandwich>
#include <reapi>

public plugin_init()
{
    register_plugin("Player Touch", "1.0", "Docaner");
    register_clcmd("get_entity", "@GetEntity");
}

@GetEntity(const iPlayer)
{
    new iTouched; get_user_aiming(iPlayer, iTouched);
 
    if(is_nullent(iTouched))
    {
        client_print(iPlayer, print_chat, "Не обнаружен");
        return;
    }

    new szClassName[32]; get_entvar(iTouched, var_classname, szClassName, charsmax(szClassName));
    client_print(iPlayer, print_chat, "iToucher: %d | ClassName: %s", iTouched, szClassName);
}

