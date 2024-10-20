#include <amxmodx>
#include <api_identifier>

/**
 * Пример использования плагина Player Identify System
 */

public plugin_init()
{
	register_plugin("[PIS] Example", "1.0", "Docaner");

	register_clcmd("set_identifier", "@set_identifier");
	register_clcmd("get_identifier", "@get_identifier");
}

@set_identifier(id)
{
	set_user_property(id, "example_int", random(255));
	set_user_property(id, "example_float", random_float(0.0, 1337.0), ValueFloat);

	new szText[Identifier_MaxValueLen]; generate_string(szText, charsmax(szText));
	set_user_property(id, "example_chars", szText, ValueChars);

	@get_identifier(id);

	console_print(id, "Example: OK");
}

@get_identifier(id)
{
	console_print(id, "Example int: %d", get_user_property(id, "example_int"));
	console_print(id, "Example float: %f", Float:get_user_property(id, "example_float", ValueFloat));
	new szText[Identifier_MaxValueLen]; get_user_property(id, "example_chars", ValueChars, szText, charsmax(szText));
	console_print(id, "Example chars: %s", szText);
}

stock generate_string(szText[], iLen)
{
	for(new i; i < iLen; i++)
	{
		switch(random(2)) 
		{
			case 0: szText[i] = random_num('A', 'Z');
			case 1: szText[i] = random_num('a', 'z');
		}
	}

	szText[iLen] = 0;
}