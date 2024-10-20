#if defined _zp_buymenu_included
	#endinput
#endif

#define _zp_buymenu_included

#define BLOCK_PRIMARY 		(1<<0) 	//Блокировка покупки основного оружия
#define BLOCK_SECONDARY 	(1<<1)	//Блокировка покупки пистолетов

/**
 * Получить уровень блокировки покупки
 * 
 * @param id 			player-id
 * 
 * @return				битусмма блокировок
 */
native zp_get_user_weapon_block(id);

/**
 * Установить уровень блокировки покупки
 * 
 * @param id 			player-id
 * @param iValue		битсумма блокировок
 * 
 * @noreturn
 */
native zp_set_user_weapon_block(id, iValue);

