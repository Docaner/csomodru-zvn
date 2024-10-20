/**
 * Аддон предназначен для удобного 
 * управления скоростью игрока
 */

#if defined _api_maxspeed_inclided
	#endinput
#endif

#define _api_maxspeed_included

/**
 * Тип выставления скорости
 */
 enum SpeedType:
 {
 	//Отключение действий плагина
 	e_SpeedDisable = 0,
 	//Статическая скорость
 	e_SpeedStatic,
 	//Множитель
 	e_SpeedMul
 }

/**
 * Выставление скорости игроку
 * 
 * @param pPlayer 		Индекс игрока
 * @param flValue 		Значение скорости
 * @param eSpeedType 	Тип скорости
 * 
 * @noreturn
 */
native rg_set_user_maxspeed(const pPlayer, const Float:flValue, SpeedType:eSpeedType = e_SpeedStatic);

/**
 * Получение скорости игрока
 * 
 * @param pPlayer 		Индекс игрока
 * @param eSpeedType 	Тип скорости (получение параметра по ссылке)
 * 
 * @return 				В зависимости от выставленного ранее значения eSpeedType, 
 * 						вовзращает либо множитель, либо статическое значение
 */
native Float:rg_get_user_maxspeed(const pPlayer, &SpeedType:eSpeedType = e_SpeedStatic);