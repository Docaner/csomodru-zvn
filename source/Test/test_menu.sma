#include <amxmodx>

public plugin_init() {
    register_menucmd(register_menuid("@Show_TestMenu"), 1023, "@Handle_TestMenu");

    register_clcmd("open", "@Show_TestMenu");
}

@Show_TestMenu(id)
{
    static nums; 
    nums += 1;
    new szMenu[512]; 
    formatex(szMenu, charsmax(szMenu), "\w[Счётчик]: \y%d", nums);
    return show_menu(id, 1023, szMenu, 1, "@Show_TestMenu");
}

@Handle_TestMenu(id, key)
{
    client_print(id, print_chat, "id: %d, key: %d", id, key);
    return @Show_TestMenu(id);
}