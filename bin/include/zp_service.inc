// Инклюд для плагина Custom SERVICE System
//
// Service-флаги:

#define SERVICE_ALL					0		/* everyone */
#define SERVICE_LEVEL_A				(1<<0)	/* flag "a" */
#define SERVICE_LEVEL_B				(1<<1)	/* flag "b" */
#define SERVICE_LEVEL_C				(1<<2)	/* flag "c" */
#define SERVICE_LEVEL_D				(1<<3)	/* flag "d" */
#define SERVICE_LEVEL_E				(1<<4)	/* flag "e" */
#define SERVICE_LEVEL_F				(1<<5)	/* flag "f" */
#define SERVICE_LEVEL_G				(1<<6)	/* flag "g" */
#define SERVICE_LEVEL_H				(1<<7)	/* flag "h" */
#define SERVICE_LEVEL_I				(1<<8)	/* flag "i" */
#define SERVICE_LEVEL_J				(1<<9)	/* flag "j" */
#define SERVICE_LEVEL_K				(1<<10)	/* flag "k" */
#define SERVICE_LEVEL_L				(1<<11)	/* flag "l" */
#define SERVICE_LEVEL_M				(1<<12)	/* flag "m" */
#define SERVICE_LEVEL_N				(1<<13)	/* flag "n" */
#define SERVICE_LEVEL_O				(1<<14)	/* flag "o" */
#define SERVICE_LEVEL_P				(1<<15)	/* flag "p" */
#define SERVICE_LEVEL_Q				(1<<16)	/* flag "q" */
#define SERVICE_LEVEL_R				(1<<17)	/* flag "r" */
#define SERVICE_LEVEL_S				(1<<18)	/* flag "s" */
#define SERVICE_LEVEL_T				(1<<19)	/* flag "t" */
#define SERVICE_LEVEL_U				(1<<20)	/* flag "u" */

#define SERVICE_LEVEL_Y				(1<<24)	/* flag "y" */
#define SERVICE_LEVEL_Z				(1<<25)	/* flag "z" */


/* Функция получает битовое значение service-флагов игрока
 *
 * Parameters:
 * id 	- ID игрока на сервере
 *
 * Return:
 * Вернёт битовое значение service-флагов
 *  
 */
native service_get_user_flags(id)


/* Функция получает время окончания service-услуги в UNIX
 *
 * Parameters:
 * id 			- ID игрока на сервере
 * iBitFlags	- Бит флагов, которые указаны выше. 
 *		  		  Допускаются также использование комбинаций флагов
 *
 * Return:
 * Вернёт время окончания услуги в UNIX
 *  
 */
native service_get_user_timeend(id, iBitFlags)