/**
 * Позволяет управлять зомби-классами для отдельного игрока
 */
#if defined _zc_addon_zchoose_included
	#endinput
#endif
#define _zc_addon_zchoose_included

#include <api_identifier>

new const stock Field_Class_Current[] = 	"zc_zclass_current";
new const stock Field_Class_Next[] 	= 		"zc_zclass_next";
new const stock Field_Class_Menu[]	= 		"zc_zclass_menu";
//new const stock Field_Class_MenuPos[]	= "zc_zclass_menupos";

/**
 * Получить зомби-класс по player-id
 */
#define zc_get_user_zclass(%0)					get_user_property(%0, Field_Class_Current)

/**
 * Получить следующий зомби-класс по player-id
 */
#define zc_get_user_next_zclass(%0)				get_user_property(%0, Field_Class_Next)

/**
 * Получить просматриваемый зомби-класс по player-id
 */
#define zc_get_user_menu_zclass(%0)				get_user_property(%0, Field_Class_Menu)

//#define zc_get_user_menupos_zclass(%0)			get_user_property(%0, Field_Class_MenuPos)

/**
 * Установить зомби-класс по player-id
 */
#define zc_set_user_zclass(%0,%1)				set_user_property(%0, Field_Class_Current, %1)

/**
 * Установить следующий зомби-класс по player-id
 */
#define zc_set_user_next_zclass(%0,%1)			set_user_property(%0, Field_Class_Next, %1)

/**
 * Установить просматриваемый зомби-класс по player-id
 */
 #define zc_set_user_menu_zclass(%0,%1)			set_user_property(%0, Field_Class_Menu, %1)

//#define zc_set_user_menupos_zclass(%0,%1)		set_user_property(%0, Field_Class_MenuPos, %1)
