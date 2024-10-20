#if defined _json_smart_parser_included
	#endinput
#endif

#define _json_smart_parser_included

#include <json>

/**
 * Инклюд предназначен для более удобного парсинга json-формата
 */

#define JsonParser_DefIntValue 		0
#define JsonParser_DefFloatValue 	0.0
#define JsonParser_DefBoolValue		false

stock get_int_by_prop(const JSON:j, const szProperty[], iDefValue = JsonParser_DefIntValue, bool:bLog = true)
{
    if(json_object_has_value(j, szProperty, JSONNumber))
        return json_object_get_number(j, szProperty);

    if(bLog)
        log_amx("Не обноружено свойство ^"%s^"", szProperty);
    
    return iDefValue;
}

stock Float:get_float_by_prop(const JSON:j, const szProperty[], Float:flDefValue = JsonParser_DefFloatValue, bool:bLog = true)
{
    if(json_object_has_value(j, szProperty, JSONNumber))
        return json_object_get_real(j, szProperty);

    if(bLog)
        log_amx("Не обноружено свойство ^"%s^"", szProperty);
    
    return flDefValue;
}

stock bool:get_bool_by_prop(const JSON:j, const szProperty[], bool:bDefValue = JsonParser_DefBoolValue, bool:bLog = true)
{
    if(json_object_has_value(j, szProperty, JSONBoolean))
        return json_object_get_bool(j, szProperty);
    if(bLog)
        log_amx("Не обноружено свойство ^"%s^"", szProperty);
    
    return bDefValue;
}

stock bool:get_string_by_prop(const JSON:j, const szProperty[], szRet[], iLen, bool:bLog = true)
{
    if(json_object_has_value(j, szProperty, JSONString))
    {
        json_object_get_string(j, szProperty, szRet, iLen);
        return true;
    }

    if(bLog)
        log_amx("Не обноружено свойство ^"%s^"", szProperty);
    
    //endline symbol
    szRet[0] = 0;
    return false;
}