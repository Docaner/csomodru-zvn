#if defined _zpe_lvl_included
    #endinput
#endif
#define _zpe_lvl_included

/**
 * Возвращает текущее количество опыта игрока
 *	
 * @param id	Индекс игрока
 * @return		Количество опыта
 */
native zpe_get_user_exp(id); 

/**
 * Необходимое количетсво опыта для повышения
 * уровня
 * 
 * @param id	Индекс игрок
 * @return		-1 если максимальный уровень, или количетсво опыта
 */
native zpe_get_user_next_exp(id);

/**
 * Возвращает текущий уровень игрока
 *	
 * @param id	Индекс игрока
 * @return		Номер уровня
 */
native zpe_get_user_lvl(id);

/**
 * Возвращает максимальный уровень
 *	
 * @return		Максимальный уровень
 */
native zpe_get_max_lvl() 

/**
 * Проверка соответствия опыта к уровню
 * 
 * @param id	Индекс игрока
 */
native zpe_check_user_lvl(id)


/**
 * Установка начальных значений игроку
 * 
 * @param id	Индекс игрока
 */
native zpe_set_user_new(id)

/**
 * Установка опыта игроку
 * 
 * @param id		Индекс игрока
 * @param iValue	Значение опыта
 * @param bHudUpd   Показывать обновление в худе
 */
native zpe_set_user_exp(id, iValue)

/**
 * Установка опыта игроку без вывода в худ
 * 
 * @param id        Индекс игрока
 * @param iValue    Значение опыта
 */
native zpe_set_user_exp_wohud(id, iValue)

/**
 * Установка уровна игроку
 * 
 * @param id		Индекс игрока
 * @param iValue	Значение уровня
 */
native zpe_set_user_lvl(id, iValue)


/**
 * Вызывается, когда игрок получает новый уровень
 * 
 * @param id    Индекс игрока
 * @noreturn
 */
forward zpe_user_lvl_up_post(id);