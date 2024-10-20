#include <amxmodx>
#include <api_identifier>

/**
 * Player Identify System - это система сохранения данных игрока по определённому 
 * идентификатору (SteamId/IP). При помощи данной системы можно реализовать 
 * сохранения различных счётчиков (оружие на 3 раунда, способность раз в 30 
 * секунд). При reconnect данные счётчиков не обнуляются и не действуют на другого
 * игрока, который зайдет с тем же player-id. 
 */

/**
 * IDENTIFY_METHOD - cпособ идентификации:
 * 0 - STEAM_ID
 * 1 - IP-адресс
 */
#define IDENTIFY_METHOD 0

#if IDENTIFY_METHOD == 0
	#define get_user_identifier(%0,%1,%2) get_user_authid(%0, %1, %2) 
#elseif IDENTIFY_METHOD == 1
	#define get_user_identifier(%0,%1,%2) get_user_ip(%0, %1, %2, 1) 
#endif

//Массивы идентификаторов и хеш-таблиц
new Array:g_aIdentifiers, Array:g_aHashTabels;

//Индекс массива g_aIdentifiers для быстрого перебора значений
new g_iUser_ArrayIndex[33];

public plugin_init()
{
	register_plugin("Player Identify System", "1.0", "Docaner");
	
	g_aIdentifiers = ArrayCreate(Identifier_MaxIdLen);
	g_aHashTabels = ArrayCreate();

	arrayset(g_iUser_ArrayIndex, INVALID_INDEX, sizeof g_iUser_ArrayIndex);
}

public plugin_natives()
{
	register_native("set_user_property", "@set_user_property", 0);
	register_native("get_user_property", "@get_user_property", 0);

	register_native("get_identifiers_size", "@get_identifiers_size", 1);

	register_native("get_user_arrayindex", "@get_user_arrayindex", 1);

	register_native("set_arrayindex_property", "@set_arrayindex_property", 0);
	register_native("get_arrayindex_property", "@get_arrayindex_property", 0);
}

public plugin_end()
{
	destroy_identifiers();
}

public client_disconnected(id)
	g_iUser_ArrayIndex[id] = INVALID_INDEX;

//native set_user_property(const id, const szProperty[], any:...);
@set_user_property(const iPlugin, const iParamsCount)
{
	enum {Arg_Id = 1, Arg_Property, Arg_Value, Arg_ValueType}

	new id = get_param(Arg_Id);
	new szProperty[Identifier_MaxIdLen]; get_string(Arg_Property, szProperty, charsmax(szProperty));

	new ValueType:type = (iParamsCount < Arg_ValueType) ? (ValueType:ValueInt) : (ValueType:get_param_byref(Arg_ValueType));

	new Trie:tValue; get_user_hashtable(id, tValue);

	switch(type)
	{
		case ValueInt: TrieSetCell(tValue, szProperty, get_param_byref(Arg_Value));
		case ValueFloat: TrieSetCell(tValue, szProperty, get_float_byref(Arg_Value));
		case ValueChars:
		{
			new szValue[Identifier_MaxValueLen]; get_string(Arg_Value, szValue, charsmax(szValue));
			TrieSetString(tValue, szProperty, szValue);
		}
	}
}

//native any:get_user_property(const id, const szProperty[], any:...);
any:@get_user_property(const iPlugin, const iParamsCount)
{
	enum {Arg_Id = 1, Arg_Property, Arg_ValueType, Arg_Value, Arg_Len}

	new id = get_param(Arg_Id);

	if(!is_user_hashtable(id)) return false;

	new szProperty[Identifier_MaxIdLen]; get_string(Arg_Property, szProperty, charsmax(szProperty));
	new ValueType:type = (iParamsCount < Arg_ValueType) ? (ValueType:ValueInt) : (ValueType:get_param_byref(Arg_ValueType));
	new Trie:tValue; get_user_hashtable(id, tValue);

	switch(type)
	{
		case ValueInt: 
		{
			new iValue;
			TrieGetCell(tValue, szProperty, iValue);
			return iValue;
		}
		case ValueFloat: 
		{
			new Float:flValue;
			TrieGetCell(tValue, szProperty, flValue);
			return flValue;
		}
		case ValueChars:
		{
			new szValue[Identifier_MaxValueLen], iLen = get_param_byref(Arg_Len);
			TrieGetString(tValue, szProperty, szValue, iLen);
			set_string(Arg_Value, szValue, iLen);
		}
	}

	return false;
}

//native get_identifiers_size();
@get_identifiers_size() return ArraySize(g_aIdentifiers);

//native get_user_arrayindex(const id)
@get_user_arrayindex(const id)
{
	if(!is_user_connected(id)) return INVALID_INDEX;

	if(g_iUser_ArrayIndex[id] == INVALID_INDEX)
	{
		new szIdentifier[Identifier_MaxIdLen]; get_user_identifier(id, szIdentifier, charsmax(szIdentifier));
		g_iUser_ArrayIndex[id] = ArrayFindString(g_aIdentifiers, szIdentifier);
	} 
	
	return g_iUser_ArrayIndex[id];
}

//native set_arrayindex_property(const iArrayIndex, const szProperty[], any:...);
@set_arrayindex_property(const iPlugin, const iParamsCount)
{
	enum {Arg_ArrayIndex = 1, Arg_Property, Arg_Value, Arg_ValueType}

	new iArrayIndex = get_param(Arg_ArrayIndex);
	new szProperty[Identifier_MaxIdLen]; get_string(Arg_Property, szProperty, charsmax(szProperty));

	new ValueType:type = (iParamsCount < Arg_ValueType) ? (ValueType:ValueInt) : (ValueType:get_param_byref(Arg_ValueType));

	new Trie:tValue = ArrayGetCell(g_aHashTabels, iArrayIndex);

	switch(type)
	{
		case ValueInt: TrieSetCell(tValue, szProperty, get_param_byref(Arg_Value));
		case ValueFloat: TrieSetCell(tValue, szProperty, get_float_byref(Arg_Value));
		case ValueChars:
		{
			new szValue[Identifier_MaxValueLen]; get_string(Arg_Value, szValue, charsmax(szValue));
			TrieSetString(tValue, szProperty, szValue);
		}
	}
}

//native any:get_arrayindex_property(const id, const szProperty[], any:...);
any:@get_arrayindex_property(const iPlugin, const iParamsCount)
{
	enum {Arg_ArrayIndex = 1, Arg_Property, Arg_ValueType, Arg_Value, Arg_Len}

	new iArrayIndex = get_param(Arg_ArrayIndex);
	new szProperty[Identifier_MaxIdLen]; get_string(Arg_Property, szProperty, charsmax(szProperty));
	new ValueType:type = (iParamsCount < Arg_ValueType) ? (ValueType:ValueInt) : (ValueType:get_param_byref(Arg_ValueType));
	new Trie:tValue = ArrayGetCell(g_aHashTabels, iArrayIndex);

	switch(type)
	{
		case ValueInt: 
		{
			new iValue;
			TrieGetCell(tValue, szProperty, iValue);
			return iValue;
		}
		case ValueFloat: 
		{
			new Float:flValue;
			TrieGetCell(tValue, szProperty, flValue);
			return flValue;
		}
		case ValueChars:
		{
			new szValue[Identifier_MaxValueLen], iLen = get_param_byref(Arg_Len);
			TrieGetString(tValue, szProperty, szValue, iLen);
			set_string(Arg_Value, szValue, iLen);
		}
	}

	return false;
}

/**
 * Получение хеш-таблицы свойств по player-id
 */
stock get_user_hashtable(id, &Trie:tValue)
{
	switch(g_iUser_ArrayIndex[id])
	{
		//Если индекс игрока неизвестен
		case INVALID_INDEX:
		{
			new szIdentifier[Identifier_MaxIdLen]; get_user_identifier(id, szIdentifier, charsmax(szIdentifier));

			new iArrayIndex = ArrayFindString(g_aIdentifiers, szIdentifier);

			if(iArrayIndex == -1)
			{
				ArrayPushString(g_aIdentifiers, szIdentifier);
				ArrayPushCell(g_aHashTabels, (tValue = TrieCreate()));
				iArrayIndex = ArraySize(g_aIdentifiers) - 1;
			}
			else tValue = ArrayGetCell(g_aHashTabels, iArrayIndex);
		
			g_iUser_ArrayIndex[id] = iArrayIndex;
		}
		default: tValue = ArrayGetCell(g_aHashTabels, g_iUser_ArrayIndex[id]);
	}
}

/**
 * Существует ли хеш-таблица для данного player-id
 */
stock bool:is_user_hashtable(id)
{
	if(g_iUser_ArrayIndex[id] == INVALID_INDEX)
	{
		new szIdentifier[Identifier_MaxIdLen]; get_user_identifier(id, szIdentifier, charsmax(szIdentifier));
		g_iUser_ArrayIndex[id] = ArrayFindString(g_aIdentifiers, szIdentifier);
	}

	return g_iUser_ArrayIndex[id] != INVALID_INDEX;
}

/**
 * Высвобождение из памяти
 */
stock destroy_identifiers()
{
	for(new i, Trie:tValue, iArraySize = ArraySize(g_aHashTabels); i < iArraySize; i++)
	{
		tValue = ArrayGetCell(g_aHashTabels, i);
		TrieDestroy(tValue);
	}

	ArrayDestroy(g_aIdentifiers);
	ArrayDestroy(g_aHashTabels);
}