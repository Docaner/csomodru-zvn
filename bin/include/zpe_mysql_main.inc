#if defined _zpe_mysql_main_included
	#endinput
#endif
#define _zpe_mysql_main_included

/**
 * Вызывается, когда успешно загружены данные 
 * игрока из БД MySQL
 * 
 * @param iPlayer		Индекс игрока
 * @noreturn
 */ 
forward zpe_mysql_user_load_post(iPlayer);