/**
 * Данный аддон позволяет получать данные зомби-классов
 * включая информацию о моделях и звуках
 */

#if defined _zc_addon_zclasses_included
	#endinput
#endif
#define _zc_addon_zclasses_included

#include <api_identifier>
#include <json>

#define ZMNullClass 			-1
#define ZMNullIndexSound 		-1

#define ZMClassShortLen			32
#define ZMClassNameLen 			32
#define ZMClassInfoLen 			256
#define ZMClassModelLen 		32
#define ZMClassHandsLen 		64
#define ZMListSoundLen 			64

/**
 * Поле текущего зомби-класса (api_identifier)
 */
stock const Field_User_Class[] = "zc_zclass_current";

/**
 * Типы звуков
 */
enum _:ZMSoundType
{
	e_SoundInfect = 0, 				//Звук инфекции
	e_SoundInfectAdvanced,			//Звук инфекции при спавне
	e_SoundBurn,					//Звук горения
	e_SoundPain,					//Звук получения урона
	e_SoundDie,						//Звук смерти
	e_SoundIdle,					//Звук незанятый
	e_SoundMissSlash,				//Удары по воздуху
	e_SoundMissWall,				//Удары по стене
	e_SoundHitNormal,				//Удары по телу
	e_SoundMadness					//Бешенство зомби
}

/**
 * Поля json
 */
stock const g_szField_Sounds[][] =
{
	"infect",
	"infect advanced",
	"burn",
	"pain",
	"die",
	"idle",
	"miss slash",
	"miss wall",
	"hit normal",
	"madness"
}

stock const Field_ShortName[] 			= "short";
stock const Field_Name[] 				= "name";
stock const Field_Info[] 				= "info";
stock const Field_PlayerModel[] 		= "model";
stock const Field_Hands[] 				= "hands";
stock const Field_Health[] 				= "health";
stock const Field_MaxHealth[] 			= "max health";
stock const Field_Speed[] 				= "speed";
stock const Field_Gravity[] 			= "gravity";

/**
 * При помощи данного форворда возможно добавлять свои аддоны для
 * зомби-класс системы. Примером может послужить: граната джамп 
 * для с возможностью указать модель для каждого класса в json, 
 * звуки для каждого класса отдельно и многое другое...
 * 
 * @note	Не освобождайте указатель jHandle (json_free [X]). 
 * 			Это вызовет ошибки или остановку сервера.
 * 
 * @note 	В этом форварде возможно добавлять файлы в precache
 * 
 * @param jHandle	Указатель на json объект зомби-класса.
 * 					При помощи него можно читать все поля json-файла.
 */
forward zc_read_zclass(const JSON:jHandle);

/**
 * Поиск идентификатора зомби-класса по его ShortName.
 * 
 * @note Замена регистрации зомби-класса zombieplague
 * 
 * @param szShorName	Короткое имя класса. Указывается в json-файле класса.
 * 
 * @return	Возвращение идентификатора или ZMNullClass в противном случае.
 */
native zc_find_zclass_by_shortname(const szShorName[]);

/**
 * Получение количества зарегистрированных зомби-классов
 * 
 * @return Количестов зомби-классов
 */
native zc_get_zclasses_count();

/**
 * Получение полного названия зомби-класса
 * 
 * @param iClass 	Идентификатор класса
 * @param szName 	Строка, куда записывать результат
 * @param iLen 		Длинна строки
 */
native zc_get_zclass_name(const iClass, szName[], const iLen);

/**
 * Получение описания зомби-класса
 * 
 * @param iClass 	Идентификатор класса
 * @param szInfo 	Строка, куда записывать результат
 * @param iLen 		Длинна строки
 */
native zc_get_zclass_info(const iClass, szInfo[], const iLen);

/**
 * Получение player-модели зомби-класса
 * 
 * @param iClass 	Идентификатор класса
 * @param szModel 	Строка, куда записывать результат
 * @param iLen 		Длинна строки
 */
native zc_get_zclass_playermodel(const iClass, szModel[], const iLen);

/**
 * Получение modelindex player-модели зомби-класса
 * 
 * @param iClass 	Идентификатор класса
 * 
 * @return 			ModelIndex Player-модели
 */
native zc_get_zclass_modelindex(const iClass);

/**
 * Получение полного пути к моделям рук зомби
 * 
 * @param iClass 	Идентификатор класса
 * @param szModel 	Строка, куда записывать результат
 * @param iLen 		Длинна строки
 */
native zc_get_zclass_hands(const iClass, szHands[], const iLen);

/**
 * Получение здоровья зомби-класса
 * 
 * @param iClass 	Идентификатор класса
 * 
 * @return 			Количество здоровья
 */
native Float:zc_get_zclass_health(const iClass);

/**
 * Получение максимального здоровья зомби-класса
 * 
 * @param iClass 	Идентификатор класса
 * 
 * @return 			Максимальное здоровье
 */
native Float:zc_get_zclass_maxhealth(const iClass);

/**
 * Получение скорости зомби-класса
 * 
 * @param iClass 	Идентификатор класса
 * 
 * @return 			Скорость класса
 */
native Float:zc_get_zclass_speed(const iClass);

/** 
 * Получение гравитации зомби-класса
 * 
 * @param iClass 	Идентификатор класса
 * 
 * @return 			Гравитация
 */
native Float:zc_get_zclass_gravity(const iClass);

/**
 * Получение рандомного звука класса из выбранного типа
 * 
 * @param iClass 		Идентификатор класса
 * @param iSoundType	Тип звука (смотрите enum ZMSoundType)
 * @param szSound 		Строка, куда записывается результат
 * @param iLen 			Длинна строки
 * 
 * @return 				true если звук удалось найти, false в противном случае
 */
native bool:zc_get_zclass_sound(const iClass, const ZMSoundType:iSoundType, szSound[], const iLen);