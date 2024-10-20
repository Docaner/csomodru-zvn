#if defined _zpe_knokcback_included
	#endinput
#endif
#define _zpe_knokcback_included

/**
 * Установка VelocityModifier
 * @param iPlayer - id клиента, которому нужно установить замедление
 * @param Float:flModifier - занчение замедления (0.0 - клиента останавливает полностью | 1.0 - клиент спокойно бежит)
 * @return - вернёт true, если VelocityModifier будет  установлен
*/
native bool:zp_set_user_velocitymifier(iPlayer, Float:flModifier)

/**
 * Блокировка VelocityModifier
 * 
 * @param id            player id
 * @param iValue        true - заблокировать установку VelModif
 *                      false - разрешить установку VelModif
 * 
 * @noreturn
 */
native zp_set_user_block_velocitymifier(const id, const iValue);

/**
 * Получить блокировку VelocityModifier
 * 
 * @param id            player id
 * 
 * @return              true - VelModif заблокирован
 *                      false - VelModif разрешен
 */
native zp_get_user_block_velocitymifier(const id);

/**
 * Откидывание зомби по трейс-аттаке
 * @param iVictim 			- Жертва
 * @param iAttacker 		- Атакующий
 * @param pTrace 			- Указатель на трейс аттаку
 * @param Float:flRadius 	- Минимальное расстояние между жертвой и атакующим для работы откидывания (0.0 - если не нужно учитывать расстояние)
 * @param Float:flMulKnock 	- Множитель откидывания
 * 
 * @return 					- вернёт true, если кнокбек будет нанесён жертве 
 */
native bool:zp_set_user_knock_by_trace(iVictim, iAttacker, pTrace, Float:flRadius, Float:flMulKnock)

/**
 * Откидывание зомби (необходимо, если урон не детектится по трейс-аттаке)
 * @param iVictim 			- Жертва
 * @param iAttacker 		- Атакующий
 * @param Float:flRadius 	- Минимальное расстояние между жертвой и атакующим для работы откидывания (0.0 - если не нужно учитывать расстояние)
 * @param Float:flMulKnock 	- Множитель откидывания
 * 
 * @return 					- вернёт true, если кнокбек будет нанесён жертве 
 */
native bool:zp_set_user_knock_by_missile(iVictim, iAttacker, Float:flRadius, Float:flMulKnock)

/**
 * Установка knock лично игроку
 * @param id                - Игрок
 * @param Float:flValue     - Значение (по умолчанию 1.0)
 * @param Float:flRadius    - Минимальное расстояние между жертвой и атакующим для работы откидывания (0.0 - если не нужно учитывать расстояние)
 * 
 * @noreturn
 */
native zp_set_user_mul_knock(id, Float:flValue)


/**
 * Получение личного knock
 * @param id                - Игрок
 * 
 * @return                  - Значение личного knock
 */
native Float:zp_get_user_mul_knock(id)

/**
 *	Установка базового knock
 *	@param flKnock 		- Новый базовый кнок
 *
 *	@noreturn
 */
native zp_set_base_knock(Float:flKnock)

/**
 *	Получение базового knock
 *
 *	@return 		- Получение базового кнока
*/
native Float:zp_get_base_knock()

/**
 *	Установка множителя в присяде
 *	
 *	@param flKnock 		- Множитель
  */
native zp_set_mul_duck_knock(Float:flKnock)

/**
 *	Установка множителя в присяде
 *	
 *	@return 		- Множитель
  */
native Float:zp_get_mul_duck_knock() 