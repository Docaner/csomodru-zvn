#if defined _api_flame_included
	#endinput
#endif

#define _api_flame_included

#include <reapi>

/**
 * Скорость бега при горении
 */
#define FLAME_SPEED 145.0

/**
 * Переменые entity, которые содержат индекс entity-спрайтов
 */
new stock const EntVars:g_iVarsFlames[] =
{
	var_iuser1,
	var_iuser2
}

/**
 * Переменная, хранящая предыдущий тип скорости
 */
#define var_base_speedtype var_iuser4

/**
 * Переменная, хранящая предыдущее значение скорости
 */
#define var_base_speedvalue var_fuser1

/**
 * Переменная, хранящая индекс врага
 */
#define var_base_attacker var_enemy

/**
 * Переменная для перезарядки звука горения
 */
#define var_base_delaysound var_fuser2

/**
 * Переменная, хранящая скорость игрока при горении
 */
#define var_base_speedflame var_fuser3

/**
 * Переменная, хранящая индекс родительской entity
 */
#define var_child_baseent var_iuser1

/**
 * Переменная, хранящая индекс entity в массиве плагина
 */
#define var_child_cacheindex var_iuser2 

/**
 * Функция, поджигающая клиента
 * 
 * @note Если указать время flSeconds <= 0.0, то действие огня прекратится
 * 
 * @param pVictim 		Жертва
 * @param pAttacker 	Атакующий
 * @param flSeconds 	Время действия поджёга в секундах
 *
 * @return 				true, если огонь успешно запущен; false - в остальных случаях
 */
native zp_set_user_flame(const pVictim, const pAttacker, const Float:flSeconds);

/**
 * Функция вернет индекс поджигающего entity клиента
 * 
 * @param pVictim 		Индекс клиента, которого подожгли
 * 
 * @return 				Индекс, поджигающего entity;
 * 						NULLENT, если игрок не подожжен
 */
native zp_get_user_flame(const pVictim);

/**
 * Форвард вызывается после создания базового entity
 * 
 * @note    В базовое Entity может быть не занесена следующая информация:
 *          var_base_attacker, время эффекта горения (var_ltime)
 * 
 * @param pEntBase      Индекс базового Entity
 * @param pVictim       Жертва
 */ 
forward zp_flame_create_post(const pEntBase, const pVictim);

/**
 * Форвард вызывается, при изменении параметров нативом zp_set_user_flame
 * 
 * @note    Если в натив был передан flSeconds <= 0, то форвард не
 *          будет вызываться.
 * 
 * @param pEntBase          Индекс базового Entity
 * @param pVictim           Индекс жертвы
 * @param pAttacker         Индекс атакующего
 * @param flSeconds         Время горения
 */
forward zp_flame_params_change_post(const pEntBase, const pVictim, const pAttacker, const Float:flSeconds);

/**
 * Форвард вызывается после удаления эффекта огня
 * 
 * @note pEntBase еще является валидным
 * 
 * @param pEntBase      Индекс базового Entity
 * @param pVictim       Жертва  
 */
forward zp_flame_disable_post(const pEntBase, const pVictim);