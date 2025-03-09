#include <amxmodx>
#include <regex>

//Какой флаг игнорировать при проверке?
#define FLAG_IGNORE ADMIN_IMMUNITY

//Выражение
new const expression[] = "(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?).+?(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?).+?(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?).+?(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)";

new Regex:ipRegex;

public plugin_init()
{
    register_plugin("Block IP Messages", "1.0", "Docaner")
    register_clcmd("say", "@checkSayIP");
    register_clcmd("say_team", "@checkSayIP");

    ipRegex = regex_compile(expression);
}

public plugin_end()
    regex_free(ipRegex)

@checkSayIP(id)
{
    if(get_user_flags(id) & FLAG_IGNORE)
        return PLUGIN_CONTINUE;

    new message[192]; read_args(message, charsmax(message));
    
    if(regex_match_c(message, ipRegex) <= 0)
        return PLUGIN_CONTINUE;

    client_print_color(id, id, "^4[Error] ^1Возникла ошибка! Попробуйте отправить сообщение позднее...");
    return PLUGIN_HANDLED_MAIN;
}