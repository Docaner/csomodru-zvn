#if defined _human_models_included
  #endinput
#endif
#define _human_models_included

/**
 * Обновление показа скина человека
 * 
 * @param id	id клиента
 * 
 * @noreturn
 */
native zp_update_user_human_model(id);

/**
 * Получить строку с названием выбранного скина
 * клиента
 * 
 * @param id			id клиента
 * @param szSkinName	Строка, куда запишется название скина
 * @param iLen			Длина строки
 * 
 * @noreturn
 */
native zp_get_user_human_skin_name(id, szSkinName[], iLen);

/**
 * Установить клиенту скин по SkinKey
 * 
 * @param id			id клиента
 * @param szSkinKey		skinkey, который необходимо установить
 * 
 * @return 				true  - скин установлен
 * 						flase - скин не установлен
 */
native bool:zp_set_user_human_skin_key(id, szSkinKey[]);

/**
 * Получить SkinKey выбранного скина клиента
 * 
 * @param id			id клиента
 * @param szSkinKey		Строка, куда запишится текущий SkinKey
 * @param iLen			Lлина строки
 * 
 * @noreturn
 */
native zp_get_user_human_skin_key(id, szSkinKey[], iLen);

/**
 * Установить клиенту скин по номеру
 * 
 * @param id			id клиента
 * @param pSkin			Номер скина, который необходимо установить
 * 
 * @return 				true  - скин установлен
 * 						flase - скин не установлен
 */
native bool:zp_set_user_human_skin_id(id, pSkin)

/**
 * Получить выбранный номер скина клиента
 * 
 * @param id			id клиента
 * 
 * @return 				Номер скина клиента
 */
native zp_get_user_human_skin_id(id);

/**
 * Установить стандартный скин игроку
 * 
 * @param id			id клиента
 * 
 * @noreturn
 */
native zp_set_user_human_skin_def(id);

/**
 * Пол выбранной модели
 * 
 * @param id      id клиента
 * 
 * @return        true - если выбранная модель женская
 *                false - мужская
 */
native bool:zp_is_user_girl_model(id);