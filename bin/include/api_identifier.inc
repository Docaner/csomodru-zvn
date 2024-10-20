/**
 * Player Identify System - это система сохранения данных игрока по определённому 
 * идентификатору (SteamId/IP). При помощи данной системы можно реализовать 
 * сохранения различных счётчиков (оружие на 3 раунда, способность раз в 30 
 * секунд). При reconnect данные счётчиков не обнуляются и не действуют на другого
 * игрока, который зайдет с тем же player-id. 
 */

#if defined _identifier_included
	#endinput
#endif

#define _identifier_included


/**
 * Тип данных
 */
enum _:ValueType
{
	ValueInt = 0,
	ValueFloat,
	ValueChars
}

#define Identifier_MaxIdLen 34
#define Identifier_MaxKeyLen 64
#define Identifier_MaxValueLen 128

/**
 * Неизвестный arrayindex индификатора игрока
 */
#define INVALID_INDEX -1


/**
 * Устанавливает значение для определённых свойств по
 * идентификатору игрока
 * 
 * @param id			id игрока
 * @param szProperty	свойство
 * @param ... 			any:value - новое значение
 *                      ValueType:type - тип данных значения
 * 						Если type не будет указан, то по умолчаню
 * 						будет выбран ValueInt
 * 
 * @noreturn 
 */
native set_user_property(const id, const szProperty[], any:...);

/**
 * Получает значение для определённых свойств по
 * идентификатору игрока
 * 
 * @param id			id игрока
 * @param szProperty	свойство
 * @param type 			тип данных значения (ValueType)
 * @param ...			ValueType:type - тип данных значения
 * 						Если type не будет указан, то по умолчаню
 * 						будет выбран ValueInt
 * 						iLen - длина строки для типпа данных ValueChars
 * 
 * @return 				Если type == ValueInt, то вернёт значение int
 * 						Если type == ValueFloat, то вернёт значение float
 * 						В противном случае вернёт false
 *
 */
native any:get_user_property(const id, const szProperty[], any:...);


/**
 * Количество кешированных идентификаторов.
 * Необходим для перебора всех индетификаторов
 * через функции set_arrayindex_property/get_arrayindex_property
 * 
 * @return              количество сохраненных индетификаторов
 */
native get_identifiers_size();

/**
 * Получить индекс идентификатора игрока.
 * Необходим для более быстрого обращения к памяти.
 * 
 * @param id            id игрока
 * 
 * @return              номер идентификатора хеш-таблицы
 */
native get_user_arrayindex(const id);


/**
 * Устанавливает значение для определённых свойств по
 * идентификатору игрока
 * 
 * @param iArrayIndex   Индекс идентификатора
 * @param szProperty    свойство
 * @param ...           any:value - новое значение
 *                      ValueType:type - тип данных значения
 *                      Если type не будет указан, то по умолчаню
 *                      будет выбран ValueInt
 * 
 * @noreturn 
 */
native set_arrayindex_property(const iArrayIndex, const szProperty[], any:...);

/**
 * Получает значение для определённых свойств по
 * идентификатору игрока
 * 
 * @param iArrayIndex   Индекс идентификатора
 * @param szProperty    свойство
 * @param type          тип данных значения (ValueType)
 * @param ...           ValueType:type - тип данных значения
 *                      Если type не будет указан, то по умолчаню
 *                      будет выбран ValueInt
 *                      iLen - длина строки для типпа данных ValueChars
 * 
 * @return              Если type == ValueInt, то вернёт значение int
 *                      Если type == ValueFloat, то вернёт значение float
 *                      В противном случае вернёт false
 *
 */
native any:get_arrayindex_property(const iArrayIndex, const szProperty[], any:...);