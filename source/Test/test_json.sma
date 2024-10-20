#include <amxmodx>
#include <json>

public plugin_init()
{
    register_plugin("JSON TEST", "1.0", "Docaner");

    new JSON:j = json_init_object();

    json_object_set_number(j, "tetNum", 10);
    json_object_set_string(j, "testStr", "Тестовая строка");
    
    new szJsonText[512]; json_serial_to_string(j, szJsonText, charsmax(szJsonText));

    json_free(j);

    console_print(0, "JsonText: ^"%s^"", szJsonText);
    
}