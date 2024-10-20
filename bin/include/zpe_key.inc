
/**
 * Получение количества MoneyKey
 * 
 * @param id 		Индекс игрока
 * @return 			Количество MoneyKey
 */
native zpe_get_user_moneykey(id)

/**
 * Получение максимального количества MoneyKey
 */
native zpe_get_max_moneykey(id)

/**
 * Получение количества AmmoKey
 * 
 * @param id 		Индекс игрока
 * @return 			Количество AmmoKey
 */
native zpe_get_user_ammokey(id)

/**
 * Получение максимального количества AmmoKey
 */
native zpe_get_max_ammokey(id)

/**
 * Установка количества MoneyKey
 * 
 * @param id 		Индекс игрока
 * @param iValue 	Количество MoneyKey
 */
native zpe_set_user_moneykey(id, iValue) 

/**
 * Установка количества AmmoKey
 * 
 * @param id 		Индекс игрока
 * @param iValue 	Количество AmmoKey
 */
native zpe_set_user_ammokey(id, iValue) 

/**
 * Установка количества MoneyKey
 * без вывода сообщения в худ
 * 
 * @param id 		Индекс игрока
 * @param iValue 	Количество MoneyKey
 */
native zpe_set_user_moneykey_wohud(id, iValue)

/**
 * Установка количества AmmoKey
 * без вывода сообщения в худ
 * 
 * @param id 		Индекс игрока
 * @param iValue 	Количество AmmoKey
 */
native zpe_set_user_ammokey_wohud(id, iValue)