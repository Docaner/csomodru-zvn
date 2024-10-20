#if defined _zp_arrmor_included
	#endinput
#endif

#define _zp_arrmor_included

/**
 * Установка брони игроку со звуком
 * 
 * @param pPlayer			player-id
 * @param flAmount			Количество брони
 * 
 * @return                  PLUGIN_CONTINUE - броня выдана
 *                          PLAGIN_HANDLED - броня не выдана
 */
native zp_set_user_arrmor(const pPlayer, Float:flAmount);