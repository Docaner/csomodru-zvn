#include <amxmodx>
#include <zombieplague>
#include <zp_system>
#include <zpe_lvl>

#define MsgId_SayText 76

#define MESSAGE_LENGTH 173 // 192 - 19

new g_szMessage[MESSAGE_LENGTH]

new const g_TextChannels[][] = 
{
    "#Cstrike_Chat_All",
    "#Cstrike_Chat_AllDead",
    "#Cstrike_Chat_T",
    "#Cstrike_Chat_T_Dead",
    "#Cstrike_Chat_CT",
    "#Cstrike_Chat_CT_Dead",
    "#Cstrike_Chat_Spec",
    "#Cstrike_Chat_AllSpec"
}

public plugin_init()
{
	register_plugin("[ZP] Chat Prefix", "1.0", "Docaner")
	register_message(MsgId_SayText, "Hook__Msg_SayText")
	register_clcmd("say", "Hook__ClCmd_Say")
	register_clcmd("say_team", "Hook__ClCmd_SayTeam")
}

public Hook__Msg_SayText(iMsgId, iDest, iRecerver)
{
	if(get_msg_args() != 4)
		return PLUGIN_CONTINUE

	new str2[22], channel
	get_msg_arg_string(2, str2, charsmax(str2));
	channel = get_msg_channel(str2);

	if(!channel)
		return PLUGIN_CONTINUE

	new str3[2]
	get_msg_arg_string(3, str3, charsmax(str3))

	if(str3[0])
		return PLUGIN_CONTINUE

	set_msg_arg_string(2, "#Spec_PlayerItem");

	set_msg_arg_string(3, g_szMessage)
	set_msg_arg_string(4, "")

	return PLUGIN_CONTINUE
}

public Hook__ClCmd_SayTeam(id)
	return Hook__ClCmd_Say(id, true)

public Hook__ClCmd_Say(id, bool:bTeam)
{
	if(is_user_bot(id))
		return PLUGIN_HANDLED
	
	new szMessage[MESSAGE_LENGTH]

	read_argv(0, szMessage, charsmax(szMessage))

	read_args(szMessage, charsmax(szMessage))
	remove_quotes(szMessage)
	replace_wrong_simbols(szMessage)
	trim(szMessage)

	new szNewMessage[MESSAGE_LENGTH]

	add(szNewMessage, charsmax(szNewMessage), "^1")

	if(!is_user_alive(id))
		add(szNewMessage, charsmax(szNewMessage), (get_user_team(id) == 3 && !bTeam) ? "*SPEC* " : "*DEAD* ")

	if(bTeam)
	{
		switch(get_user_team(id))
		{
			case 1: add(szNewMessage, charsmax(szNewMessage), "(Zombie) ")
			case 2: add(szNewMessage, charsmax(szNewMessage), "(Human) ")
			case 0, 3: add(szNewMessage, charsmax(szNewMessage), "(Spectator) ")
		}
	}
	
	
#define ADMIN_ADM ADMIN_BAN
#define ADMIN_AGENT ADMIN_LEVEL_G
#define ADMIN_PREMIUM ADMIN_LEVEL_D
#define ADMIN_VIP ADMIN_LEVEL_H
#define ADMIN_PLUS ADMIN_LEVEL_C

	new szSteamID[35]
	get_user_authid(id, szSteamID, 33)

	new szPriv[64];
	new iFlags = get_user_flags(id);
	
	//Артур
	if(equal(szSteamID, "STEAM_0:1:89327749"))
		formatex(szPriv, charsmax(szPriv), "LEGEND")
	//Данил
	else if(equal(szSteamID, "STEAM_0:1:105062208"))
		formatex(szPriv, charsmax(szPriv), "#")	
	//Максим
	else if(equal(szSteamID, "STEAM_1:0:2063031845"))
		formatex(szPriv, charsmax(szPriv), "Игрок")
	//Фир
	else if(equal(szSteamID, "STEAM_0:0:499315472"))
		formatex(szPriv, charsmax(szPriv), "Щенок")
	//Негативчик
	else if(equal(szSteamID, "STEAM_0:0:811892213"))
		formatex(szPriv, charsmax(szPriv), "NiGa")
	//MeatGreender
	else if(equal(szSteamID, "STEAM_0:0:177908902"))
		formatex(szPriv, charsmax(szPriv), "Cirno")
	//Destroer
	else if(equal(szSteamID, "STEAM_1:0:988578733"))
		formatex(szPriv, charsmax(szPriv), "BuRnInG")
	//тт (Алмаз)
	else if(equal(szSteamID, "STEAM_0:0:739258008"))
		formatex(szPriv, charsmax(szPriv), "tatar")
	// Sanzar - ID: 323
	//else if(equal(szSteamID, "STEAM_0:0:761732353"))
		//formatex(szPriv, charsmax(szPriv), "-^3S^1K^4i^3p^1p^4e^3R^1-")
		// formatex(szPriv, charsmax(szPriv), "Most-Valuable-Player")
	//	formatex(szPriv, charsmax(szPriv), "Clan-Leader")
	// kONDOR - ID: 323
	else if(equal(szSteamID, "STEAM_1:0:509514341"))
		formatex(szPriv, charsmax(szPriv), "Админ")
	// JOKER - ID: 168
	else if(equal(szSteamID, "STEAM_1:0:1456884354"))
		formatex(szPriv, charsmax(szPriv), "Админ")
	//kartez - ID: 	77
	else if(equal(szSteamID, "STEAM_0:0:635056945"))
		formatex(szPriv, charsmax(szPriv), "Кардинал")	
	//ЕвГеШа - ID:	ЕвГеШа
	else if(equal(szSteamID, "STEAM_1:0:2010763562"))
		//formatex(szPriv, charsmax(szPriv), "迪亚内索奇卡")	
		formatex(szPriv, charsmax(szPriv), "신성한 그림자")	
	//cheats - ID: 	3466
	// else if(equal(szSteamID, "STEAM_0:1:440633966"))
	// 	formatex(szPriv, charsmax(szPriv), "Шоумен")	
	//RED - ID: 151
	else if(equal(szSteamID, "STEAM_0:1:1346158"))
		formatex(szPriv, charsmax(szPriv), "Гл. модератор")
		// formatex(szPriv, charsmax(szPriv), "Модератор")
	else if(equal(szSteamID, "STEAM_0:0:545407467"))
		formatex(szPriv, charsmax(szPriv), "Модератор")
	//dANGERglebas - ID: 413	
	else if(equal(szSteamID, "STEAM_0:1:202385180"))
		formatex(szPriv, charsmax(szPriv), "Ветеран проекта")	
	else if(equal(szSteamID, "STEAM_1:0:871547697"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3")
	else if(equal(szSteamID, "STEAM_1:0:1776585478"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3")
	else if(equal(szSteamID, "STEAM_1:0:161788085"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3")
	else if(equal(szSteamID, "STEAM_1:0:1573956548"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3")
	else if(equal(szSteamID, "STEAM_1:0:1672230705"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3")
	else if(equal(szSteamID, "STEAM_0:0:585272832"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3")
	else if(equal(szSteamID, "STEAM_0:1:656028760"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3")
	else if(equal(szSteamID, "STEAM_0:0:146812817"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3")
	else if(equal(szSteamID, "STEAM_1:0:1959691891"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3")
	else if(equal(szSteamID, "STEAM_1:0:47741416"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3") 
	else if(equal(szSteamID, "STEAM_1:0:1225857686"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3") 	
	else if(equal(szSteamID, "STEAM_1:0:1983369447"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3") 	
	else if(equal(szSteamID, "STEAM_1:0:1829383221"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3")
	else if(equal(szSteamID, "STEAM_1:0:828206927"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3")
	else if(equal(szSteamID, "STEAM_1:0:1481944619"))
		formatex(szPriv, charsmax(szPriv), "Милая девушка <3")
	else if(equal(szSteamID, "STEAM_1:0:860109188"))
		formatex(szPriv, charsmax(szPriv), "Забивная <3") 
	else if(iFlags & ADMIN_ADM)
		formatex(szPriv, charsmax(szPriv), "Админ")
	else if(iFlags & ADMIN_AGENT)
	{
		if(iFlags & ADMIN_PLUS)
			formatex(szPriv, charsmax(szPriv), "AGENT+")
		else
			formatex(szPriv, charsmax(szPriv), "AGENT")

	}
	else if(iFlags & ADMIN_PREMIUM)
	{
		if(iFlags & ADMIN_PLUS)
			formatex(szPriv, charsmax(szPriv), "PREMIUM+")
		else
			formatex(szPriv, charsmax(szPriv), "PREMIUM")

	}
	else if(iFlags & ADMIN_VIP)
	{
		if(iFlags & ADMIN_PLUS)
			formatex(szPriv, charsmax(szPriv), "VIP+")
		else
			formatex(szPriv, charsmax(szPriv), "VIP")

	}
	else if(iFlags & ADMIN_PLUS)
		formatex(szPriv, charsmax(szPriv), "PLUS")
	else
		formatex(szPriv, charsmax(szPriv), "Игрок")

	add(szNewMessage, charsmax(szNewMessage), fmt("^1[^4%s^1] ", szPriv));
	
	add(szNewMessage, charsmax(szNewMessage), "^3")

	new szName[33]
	get_user_name(id, szName, charsmax(szName))
	add(szNewMessage, charsmax(szNewMessage), szName)
	
	//JOKER - ID: 168
	if(get_user_flags(id) & ADMIN_BAN || equal(szSteamID, "STEAM_1:0:1456884354"))
		add(szNewMessage, charsmax(szNewMessage), " ^1:^4 ")
	else
		add(szNewMessage, charsmax(szNewMessage), " ^1: ")
		
	add(szNewMessage, charsmax(szNewMessage), szMessage)

	copy(g_szMessage, charsmax(g_szMessage), szNewMessage)

	return PLUGIN_CONTINUE
}

stock replace_wrong_simbols(string[])
{
    new len = 0;
    for(new i; string[i] != EOS; i++) {
        if(/* string[i] == '%' || string[i] == '#' || */ 0x01 <= string[i] <= 0x04) {
            continue;
        }
        string[len++] = string[i];
    }
    string[len] = EOS;
}

get_msg_channel(str[])
{
    for(new i; i < sizeof(g_TextChannels); i++) {
        if(equal(str, g_TextChannels[i])) {
            return i + 1;
        }
    }
    return 0;
}