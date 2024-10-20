#if defined _gamecms5_included
	#endinput
#endif
#define _gamecms5_included

#if !defined MAX_PLAYERS
	const MAX_PLAYERS = 32;
#endif
#if !defined MAX_NAME_LENGTH
	const MAX_NAME_LENGTH =	32;
#endif

#define API54

#define MAX_STRING_LEN	33
#define MAX_INT_LEN			11
#define DUPLICATE_ENTRY		1062
#define DUPLICATE_COLUMN	1060
#define MAX_QUERY_MEDIUM_LEN 2048
#define MAX_QUERY_SMALL_LEN 512
#define AdminInfo eAdminInfo


#if AMXX_VERSION_NUM < 183
	#define client_disconnected client_disconnect
	#define socket_is_readable socket_change
	#include <colorchat>
	stock MaxClients;
	#define AMXX_182
#else
	#define client_disconnect client_disconnected
#endif

#define IsValidPlayer(%0) (0 < %0 <= MaxClients)
#define DestroyArray(%1)	if(%1 != Invalid_Array) ArrayDestroy(%1)
#define DestroyTrie(%1)		if(%1 != Invalid_Trie) TrieDestroy(%1)

/*Состояние услуги или параметра*/
enum _:eServiceStatus
{
	SERVICE_NOT_FOUND = -2,	/*Услуга не найдена*/
	SERVICE_NONE,
	SERVICE_INACTIVE,		/*Услуга не активна*/
	SERVICE_ACTIVE,			/*Услуга активна*/
	SERVICE_STOPPED			/*Услуга приостановлена*/
}

/*Время окончания действия услуги*/
enum _:eServiceTime
{
	TIME_TRACKING_STOPPED = -2,	/*Услуга остановлена, неактивна*/
	TIME_MAP_END_EXPIRING,		/*В конце карты*/
	TIME_NOT_EXPIRING			/*Время не ограничено*/
}

/*GagManager Проверка наличия блокировки*/
enum _:eBlockStatus
{
	BLOCK_STATUS_NONE = -1,		/*Нет блокировки*/
	BLOCK_STATUS_ALL,			/*Блокировка голос+чат*/
	BLOCK_STATUS_CHAT,			/*Блокировка чат*/
	BLOCK_STATUS_VOICE			/*Блокировка голос*/
}

/*GagManager Управление блокировкой*/
enum _:eBlockFunc
{
	BLOCK_FUNC_ADD = 1,		/*Добавить блокировку*/
	BLOCK_FUNC_CHANGE,		/*Изменить блокировку*/
	BLOCK_FUNC_REMOVE		/*Удалить блокировку*/
}

/*Адрес сайта. example: http://site.com*/
stock SiteUrl[MAX_STRING_LEN];

/*Указатели таблиц для получения их имен через cmsapi_get_table_name*/
enum TablePtr
{
	admins_services,
	dialogs,
	users_groups,
	services,
	services_tarifs,
	config_secondary,
	sortition,
	sortition__participants,
	users__friends,
	users__online,
	last_online
}

/*Названия таблиц в БД, которые нужно изменить при обновлении движка*/
stock const TABLE_NAMES[TablePtr][] = 
{
	"admins__services",
	"pm__dialogs",
	"users__groups",
	"services",
	"services__tarifs",
	"config__secondary",
	"sortition",
	"sortition__participants",
	"users__friends",
	"users__online",
	"last_online"
}

/*Массив для хранения информации об услуге*/
enum _:eAdminInfo
{
	AdminId,
	AdminAuthId[MAX_STRING_LEN],
	AdminPassword[MAX_STRING_LEN],
	AdminServiceFlags[MAX_STRING_LEN],
	AdminType[MAX_INT_LEN],
	AdminExpired[MAX_STRING_LEN],
	AdminReason[MAX_STRING_LEN*2],
	AdminActive,
	AdminPaused,
	AdminService,	
	AdminServiceId,
	AdminServiceName[MAX_STRING_LEN*2],
	AdminServiceTime
};

/*Массив для хранения информации о пользователе*/
enum _:eMemberData
{
	MemberId,
	MemberLogin[MAX_NAME_LENGTH],
	MemberName[MAX_NAME_LENGTH*2],
	MemberBirth[MAX_INT_LEN + 1],
	MemberNick[MAX_NAME_LENGTH],
	Float:MemberMoney,
	Float:MemberMoneySaved,
	MemberGameTime,
	MemberPrefix[MAX_STRING_LEN],
	MemberGameMoney,
	MemberGameMoneySaved,
	MemberMessages,
	MemberGroup,
	MemberGroupName[MAX_NAME_LENGTH*2],
	MemberThanks,
	MemberAnswers,
	MemberRaiting,
	MemberRegDate[MAX_STRING_LEN],
	MemberLastActivity[MAX_INT_LEN],
	MemberDiscount
};

/*Статус запросов в БД*/
enum _:eQueryStatus
{
	LOAD_ALL,
	LOAD,
	UPDATE,
	SAVE,
	SET,
	ADD,
	RELOAD
}

/*Статус работы плагина cmsapi_get_api_status*/
enum _:eApiStatus(<<=1)	/*api status*/
{
	UseGameCms = 1,		/*плагин подключен к базе данных GameCMS*/
    UseGameCmsAdmins,	/*используется база данных GameCMS для загрузки админов*/
	UseGameCmsGroups,	/*используется группа пользователя на сайте для выдачи флагов админа*/
	UseAddAdmin			/*используется функция добавления услуги в базу сайта*/
}

/*статус авторизации клиента stock StGetUserAuthStatus(szAuth[])*/
enum eAuthStatus
{
	USER_AUTH_NOT,		/*клиент не авторизован*/
	USER_AUTH_BOT,		/*BOT*/
	USER_AUTH_HLTV,		/*HLTV*/
	USER_AUTH_VALID		/*клиент имеет допустимую авторизацию (STEAM or VALVE)*/
}


/**
* Получение версии плагина
* 
* @param iMajorVersion		Мажор версии
* @param iMinorVersion		Минор версии
*
* @noreturn
*/
native cmsapi_get_plugin_version(&iMajorVersion, &iMinorVersion);


/**
* Получение статуса работы плагина
*
* @return		Битсумма значения enum eApiStatus
*/
native cmsapi_get_api_status();


/**
* Получение имени таблицы в БД по ее указателю
* 
* @param Pointer		Указатель таблицы из TablePtr
* @param szTableName	Массив для записи имени таблицы
* @param iLen			максимальный размер массива
*
* @return				Количество ячеек, записанных в массив
*/

native cmsapi_get_table_name(TablePtr:Pointer, szTableName[], iLen);

/**
* Получение данных участника форума
* 
* @param id			id игрока
* @param szData		Массив с данными участника форума
* 	szData[0]		количество "спасибо"
* 	szData[1]		количество ответов на форуме
* 	szData[2]		рейтинг на форуме
* 	szData[3]		количество новых личных сообщений
* @param szName		Имя игрока, указанное в профиле
* @param iLen		Размер массива для записи имени
*
* @return			1 - При успешном получении данных об игроке
* 					0 - Если игрок не зарегистрирован или ошибка при получении данных
*/
native cmsapi_get_forum_data(id, szData[4], szName[]="", iLen=0);


/**
* Получение ника игрока, указанного в профиле форума
* 
* @param id		id игрока
* @param szNick	Ник игрока
* @param iLen	Размер массива
*
* @return		Количество ячеек, записанных в массив
* 				-1 - Если игрок не зарегистрирован или ошибка при получении данных
*/
native cmsapi_get_user_nick(id, szNick[], iLen);


/**
* Получение id группы пользователя
* 
* @param id			id игрока
* @param szGroup	Массив для записи названия группы пользователя
* @param iLen		Размер массива
*
* @return			id группы пользователя
* 					0 - пользователь не найден (не зарегистрирован)
*/
native cmsapi_get_user_group(id, szGroup[] = "", iLen = 0);


/**
* Установка группы пользователя на сайте
* 
* @param id				id игрока
* @param iGroupId		Номер (индекс) группы
* @param bool:bSetFlags	Выдать флаги группы
*
* @return				true- при удачном выполнении, иначе false
*/
native bool:cmsapi_set_user_group(id, iGroupId, bool:bSetFlags = true);

/**
* Получение даты окончания услуги
* 
* @param id			id игрока
* @param szDate		Дата истечения срока услуги в формате ГГГГ-ММ-ДД
* @param iLen		Размер массива szDate[]
* @param srvName	Флаги услуги
* @param part		Совпадение наименования услуги (флагов): true - частичное совпадение, false - полное совпадение
*
* @return			Время окончания в формате UNIX, если > 0 или состояние eServiceTime:
* 					TIME_MAP_END_EXPIRING - до смены карты
* 					TIME_NOT_EXPIRING - нет ограничений
* 					SERVICE_NOT_FOUND  услуга не найдена
* 					TIME_TRACKING_STOPPED - услуга не активна, остановлена
*/
native cmsapi_service_timeleft(id, szDate[]="", iLen=0, const srvName[]="", bool:part = false);


/**
* Проверка на активацию услуги
* 
* @param id			id игрока
* @param szReason	Причина отключения услуги, если она отключена
* @param iLen		Размер массива szReason[]
* @param srvName	Флаги услуги
* @param part		Совпадение наименования услуги (флагов): 
* 					true - частичное совпадение
* 					false - полное совпадение
*
* @return			true-  услуга активна
* 					false- услуга выключена
*/
native bool:cmsapi_is_admin_active(id, szReason[]="", iLen = 0, const srvName[]="", bool:part = false);


/**
* Проверка регистрации игрока на сайте
* 
* @param id	id игрока
*
* @return		id пользователя в БД
* 				0 - пользователь не найден (не зарегистрирован)
*/
native cmsapi_is_user_member(id);


/**
* Получение информации о балансе кошелька зарегистрированного игрока
* 
* @param id	id игрока
*
* @return		Баланс игрока на сайте
*/
native Float:cmsapi_get_user_money(id);


/**
* Установка баланса кошелька зарегистрированного игрока
* 
* @param id				id игрока
* @param Float:fAmmount	Новое значение баланса
*
* @return				1 в случае успеха
* 						0 в случае неудачи
*/
native cmsapi_set_user_money(id, Float:fAmmount);


/**
* Изменение баланса кошелька зарегистрированного игрока (добавить / отнять)
* 
* @param id				id игрока
* @param Float:fAmmount	Добавить значение к балансу
*
* @return				1 в случае успеха
* 						0 в случае неудачи
*/
native cmsapi_add_user_money(id, Float:fAmmount);


/**
* Получение данных всех имеющихся на сервере услуг
* 
* @return		New array handle or Invalid_Array if empty
*/
native Array:cmsapi_get_all_services();

/**
* Получение данных всех имеющихся на сервере админов
* 
* @return		New array handle or Invalid_Array if empty
*/
#pragma deprecated Use cmsapi_get_all_services()
native Array:cmsapi_get_alladmins();


/**
* Получение данных авторизовавшихся админов
* 
* @return		New Map handle or Invalid_Trie if empty
*/
native Trie:cmsapi_get_online_admins();


/**
* Получение данных о всех купленных доп. услугах
* 
* @return		New array handle or Invalid_Array if empty
*/
#pragma deprecated Use cmsapi_get_all_services()
native Array:cmsapi_get_all_purchases();


/**
* Получение данных о купленных услугах игрока
* 
* @Note	Запрос информации обо всех услугах игрока: (szService[] = "" И serviceID = 0)
*		Запрос информации о конкретной услуге: (szService[] = "`services`.`rights`" ИЛИ serviceID = `services`.`id`)
*
* @param index		id игрока
* @param szAuth		steamID игрока
* @param szService	Название услуги
* @param serviceID	Номер услуги
* @param part		Совпадение наименования услуги (флагов)
* 					true - частичное совпадение
* 					false - полное совпадение
*
* @return			New array handle or Invalid_Array if empty
*/
native Array:cmsapi_get_user_services(const index, const szAuth[] = "", const szService[] = "", serviceID = 0, bool:part = false);

/**
* Удаление услуги игрока
* 
* @param iClient			id игрока
* @param iServiceId			Номер услуги
* @param iAdminServiceId	Номер услуги админа `admins__services`.`id`
* @param bUpdateDB			Отправить запрос в базу данных. Если false, то услуга будет удалена только на сервере (для удаления временных услуг, которых нет в БД и у которых нет автоудаления)
*
* @return			true- при удачном удалении услуги, иначе false
*
* @Note		Если игрок на сервере, можно использовать его индекс (iClient) и номер услуги iServiceId (Идентификатор AdminService).
*			Если игрока нет, то нужно использовать индекс услуги админа iAdminServiceId, это `id` строки из таблицы `admins_services` (Идентификатор AdminServiceId).
* @Note		При отправке запроса в БД плагин не удаляет услугу физически. Услуге устанавливается текущее время окончания, дальнейшее удаление производится движком на общих условиях.
*/
native bool:cmsapi_remove_user_service(iClient, iServiceId, iAdminServiceId = 0, bool:bUpdateDB = false);

/**
* Общее время, проведенное игроком на всех серверах проекта
* 
* @param index	Индекс игрока
*
* @return		Время в секундах
*/
native cmsapi_get_user_gametime(index);


/**
* Получение ID аккаунта админа, под которым игрок авторизовался
*
* @param index	Индекс игрока
* @param szAuth	Массив для записи идентификатора услуги (ник / steamid)
* @param iLen	Размер массива
*
* @return		ID админа в базе
* 				0 - если игрок не имеет флагов или ошибка при получении данных
*/
native cmsapi_get_admin_ident(index, szAuth[] = "", iLen = 0);

/**
* @deprecated
*/
#pragma deprecated Use cmsapi_get_info_by_admin_id()
native Trie:cmsapi_get_admin_info(aID);


/**
* Получение данных об услуге по индексу админа
* 
* @param iAdminIndex	ID администратора в БД сайта
* @param aAdminData		массив для записи данных
*
* @return				ArrayIndex массива
* 						SERVICE_NOT_FOUND, если данные не найдены
*/
native cmsapi_get_info_by_admin_id(iAdminIndex, aAdminData[eAdminInfo] = "");


/**
* Получение данных об услуге по индексу услуги
* 
* @param iAdminServicе	ID услуги в БД сайта
* @param aAdminData		массив для записи данных
* 
* @return				ArrayIndex массива
* 						SERVICE_NOT_FOUND, если данные не найдены
*/
native cmsapi_get_info_by_admin_service(iAdminService, aAdminData[eAdminInfo] = "");


/**
* Получение идентификатора текущего сервера в БД сайта
*
* @return		Идентификатор (колонка id таблицы servers) текущего сервера
*/
native cmsapi_get_server_id();


/**
* Получение информации о балансе БАНКА ИГРОВЫХ ДЕНЕГ зарегистрированного игрока
*
* @param id		Индекс игрока
*
* @return		Значение баланса игровых денег
*/
native cmsapi_get_user_bank(id);


/**
* Установка баланса БАНКА ИГРОВЫХ ДЕНЕГ зарегистрированного игрока
* 
* @param id			Индекс игрока
* @param ammount	Новое значение баланса
*
* @return			1 в случае успеха
* 					0 в случае неудачи
*/
native cmsapi_set_user_bank(id, ammount);


/**
* Изменение баланса ИГРОВЫХ ДЕНЕГ зарегистрированного игрока  (добавить / отнять)
* 
* @param id			Индекс игрока
* @param ammount	Добавить значение к балансу
*
* @return			1 в случае успеха
* 					0 в случае неудачи
*/
native cmsapi_add_user_bank(id, ammount);


/**
* Получение даты  регистрации игрока на сайте
*
* @param id			Индекс игрока
* @param shortTime	true- короткий формат даты ДД-ММ-ГГГГ
* 					false - ГГГГ-ММ-ДД Ч:М:С
* @param szDate		Дата регистрации в формате @shortTime
* @param iLen		Размер массива szDate
*
* @return			Время в формате UNIX
* 					0 - пользователь не найден (не зарегистрирован)
*/
native cmsapi_get_user_regdate(id, szDate[] = "", iLen = 0, bool:shortTime = true);


/**
* Получение даты  последней активности пользователя на сайте
*
* @param id			Индекс игрока
* @param szDate		Дата последней активности в формате ГГГГ-ММ-ДД
* @param iLen		Размер массива szDate[]
*
* @return			Время в формате UNIX
* 					0 - пользователь не найден (не зарегистрирован)
*/
native cmsapi_get_user_lastactiv(id, szDate[]="", iLen=0);


/**
* Получение величины персональной скидки на сайте
*
* @param id	Индекс игрока
*
* @return		Cкидка в %
*/
native cmsapi_get_user_discount(id);


/**
* Динамическая перепроверка прав доступа у игрока
*
* @param id	Индекс игрока
*
* @noreturn
*/
native cmsapi_reaccess_admin(id);


/**
* Получение szAuthId игрока в формате steamid64 (profileID)
* 
* @param index		Индекс игрока
* @param auth64		Массив для записи steamID64 игрока
* @param iLen		Размер массива auth64[]
*
* @return			Количество ячеек, записанных в массив
*/
native cmsapi_get_user_authid64(index, auth64[], iLen);


/**
* Изменение баланса на сайте с перезагрузкой значения из БД. Синхронизация балансов на сайте и на сервере.
*
* @param index		Индекс игрока
* @param flValue	Сумма для добавления/списания (value / -value)
* @param full_update	true - после сохранения изменений будет произведена полная перезагрузка данных пользователя из БД
*						false - изменения будет учтены в базе, но новая информация о пользователе загружаться не будет
*
* @iMoneyAction		Тип операции. Создается в таблице money__actions вручную!!!
* @noreturn
*/
native cmsapi_reload_wallet(index, Float:flValue, bool:full_update = false, iMoneyAction = 0);


/**
* Добавление флагов пользователю на текущую сессию до смены карты
* 
* @note	Добавляет данные в массив аккаунтов, для последующей авторизации игрока
* 		Если bAuthorize = false, то авторизацию для выдачи флагов необходимо произвести через cmsapi_reaccess_admin(index)
*
* @param index			Индекс игрока
* @param szFlags		Флаги доступа
* @param iTime			Срок действия флагов, секунд (-1 - на карту)
* @param szServiceName	Название услуги (например, "вип за стим", "ночной вип" и т.п.)
* @param bAuthorize		Авторизовать пользователя сразу
*
* @return				индекс ячейки, добавленной в массив админов (Array:cmsapi_get_all_services)
						-1 - если услуга с этими флагами уже есть.
*/
native cmsapi_set_user_flags(index, const szFlags[], iTime = -1, const szServiceName[] = "", bAuthorize = true);


/** 
* Добаление аккаунтов в базу данных
*
* @note	При отключеной функции check_params существует вероятность ошибок со стороны пользователя
* @note	Пример:
*		cmsapi_add_account(id, "a", "180", "parol", "prt", 0, false)
*		игроку №id с его ником выданы флаги "prt" на 180 минут, пароль- "parol"
*
* @param iClient		Индекс игрока
* @param szAuthType		Тип авторизации (смотри amxconst.inc: Admin authentication behavior flags)
* @param szFlags		Флаги (уровни) доступа (смотри amxconst.inc: Admin level constants)
* @param iTime			Время в минутах, 0- навсегда (если время не указано, значит 0)
* @param szPasswd		Пароль доступа (если нужен)
* @param iServiceId		Номер услуги на сайте (если известен)
* @param check_params	Проверка введенных данных (true- включить). 
* 
* @noreturn
*/
native cmsapi_add_account(iClient, szAuthType[], iTime = 0,  szPasswd[] = "", szFlags[] = "", iServiceId = 0, check_params = false);

/** 
* Получение настроек пользователя из базы данных
*
* @param iClient		Индекс игрока
* @param szSettingName	Идентификатор настройки (название)
* @param szValue			Массив для записи значения настройки
* @param value_length	Размер массива для записи значения настройки
*
* @return				- размер записанного массива, если передается массив для записи значения
* 						- цифровое значение настройки, если массив не передан
* 						- -1, если идентификатор настройки не найден
*/
native cmsapi_get_user_setting(iClient, szSettingName[], szValue[] = "", value_length = 0);

/** 
* Сохранение настроек пользователя в базу данных
*
* @param iClient		Индекс игрока
* @param szSettingName	Идентификатор настройки (название)
* @param szValue		Массив со значением настройки
* @param delete			Удалить настройку
*
* @param return			true - при успешном изменении (удалении)
						false- при неудаче
*/
native bool:cmsapi_set_user_setting(iClient, szSettingName[], szValue[], bool:delete = false);


/**
* Проверка доступа игрока к услуге (проверка пароля, если она предсмотрена типом авторизации)
*
* @param iClient	Индекс игрока
* @param szService	Название услуги
*
* @return			1- при наличии доступа, иначе- 0
*/
native cmsapi_check_service_password(iClient, szServiceName[]);

/**
* Получение данных пользователя из массива eMemberData
* 
* @param iClient		Индекс игрока
* @param iIdentifier	Идентификатор массива eMemberData
* @param szUserData		Массив для записи строкового значения идентификатора
* @param iLen			Размер массива для записи
*
* @return				Целочисленное значение идентификатора массива eMemberData, если параметр szUserData не указано.
*						Если указан параметр szUserData, то вернет количество записанных ячеек.
*/
native cmsapi_get_user_data(iClient, eMemberData:iIdentifier, szUserData[] = "", iUserDataLen = 0);

/**
* Выполняется при заходе зарегистрированного игрока
*
* @param id			id игрока
* @param memberId	id профиля на сайте
* @param memberName	Имя пользователя на сайте
*
* @noreturn
*/
forward OnAPIMemberConnected(id, memberId, memberName[]);

/**
* Выполняется перед проверкой наличия услуг игрока
*
* @param id					id игрока
* @param bRemoveFlags		Удалить имеющиеся у игрока флаги, true- по-умолчанию
* @param bSetDefFlags		Установить игроку дефолтные флаги, true- по-умолчанию
* @return		PLUGIN_HANDLED, если нужно пропустить проверку имеющихся услуг. В этом случае, будут применены параметры bRemoveFlags и bSetDefFlags.
* @note			Параметры bRemoveFlags и bSetDefFlags действуют только при условии возврата PLUGIN_HANDLED
*/
forward OnAPIPreAdminCheck(const id, &bRemoveFlags, &bSetDefFlags);

/**
* v5.5.5
* Выполняется после проверки наличия услуг игрока и их записи в массив админов, находящихся на сервере (native Trie:cmsapi_get_online_admins())
*
* @param id			id игрока
* @param szFlags	Флаги, полученные в результате поиска и суммирования всех услуг с флагами. Не включаются дополнительные услуги через "_"
* @note				Параметр szFlags может быть перезаписан. В этом случае, игроку будут выданы заданные флаги, вместо флагов услуги.
*					Данные массива админов изменены не будут!
* @note				Выполняется непосредственно перед авторизацией игрока и вызовом форварда OnAPIAdminConnected
* @noreturn
*/
forward OnAPIPostAdminCheck(const id, szFlags[MAX_STRING_LEN]);

/**
* Выполняется при заходе зарегистрированного именинника
* 
* @param id				id игрока
* @param const szLogin	Имя игрока на сайте
* @param const SITE_URL	Адрес сайта (квар "cms_url") для вывода поздравительного Motd
*
* @noreturn
*/
forward OnAPIBirthdayMember(id, const szLogin[], const SITE_URL[]);


/**
* Выполняется при успешной проверке соединения с БД
*
* @param Handle:sqlTuple	Кешированные данные о соединении с БД
* @param version[]			Версия плагина
* @param serverID			Номер сервера в БД сайта (столбец `servers`.id`)
*
* @noreturn
*/
forward OnAPIPluginLoaded(Handle:sqlTuple, version[], serverID);


/**
* Выполняется при неудачной инициализации БД.
*
* @note	После выполнения, плагин останавливается.
*
* @noreturn
*/
forward OnAPIPluginStop();


/**
* Выполняется после успешной загрузки данных об услугах из базы
*
* @param eQueryStatus:status	Статус загрузки списка (LOAD_ALL- загрузка, RELOAD - перезагрузка)
* @param iAdminIndex			Индекс админа (0, если статус LOAD_ALL)
* @noreturn
*/
forward OnAPIAdminsLoaded(eQueryStatus:status, iAdminIndex);


/**
* Установка префикса в чат из БД
* 
* @param id			id игрока
* @param prefix[]	Префикс игрока в чате
* @param type		Тип префикса:
* 					1- личный префикс
* 					2- префикс группы (админ, вип и т.п.)
*
* @noreturn
*/
forward OnAPISendChatPrefix(id, prefix[], type);

/**
* Выполняется при выдаче флагов игроку (авторизация админа)
* 
* @param id				id игрока
* @param const szName	Ник админа
* @param adminID		ID админа в БД сайта
* @param Flags			Bitflag value- битсумма флагов
*
* @noreturn
*/
forward OnAPIAdminConnected(id, const szName[], adminID, Flags);

/**
* Выполняется при выходе админа (игрока с флагами доступа) с сервера
* 
* @param id	Индекс игрока
*
* @noreturn
*/
forward OnAPIAdminDisconnected(id);


/**
* Проверка текущего блока от Админа
*
* @param index	Индекс игрока
*
* @return		0-	voice + chat
* 				1-	chat
* 				2-	voice
* 				-1- not blocked
*/
native cmsgag_is_user_blocked(index);


/**
* Проверка текущего блока от игрока
*
* @param sender	Индекс отправителя 
* @param receiver	Индекс получателя
*
* @return			1- получатель заблокировал отправителя
* 					0- нет блокировки игрока
*/
native cmsgag_is_user_muted_by(receiver, sender);


/**
* Добавление блока игроку
*
* @param id			Индекс игрока
* @param typeFunc	Тип операции блокировки
* 					1- создание
* 					2- удаление
* @param blType		Тип блока (чат / голос)
* @param blReason[]	Причина
* @param blTime		Время
* @param printChat	Оповестить в чат об операции, false- нет, true- стандартное оповещение о блокировке/разблокировке
*
* @return			0 - блокировка не установлена
* 					>0 - установлена
*/
native cmsgag_add_user_block(id, typeFunc, blType = 0, blReason[] = "", blTime = 0, bool:printChat = true);

/**
* Общее время, проведенное игроком на всех серверах проекта
* 
* @param index	Индекс игрока
*
* @return		Время игры в секундах
*/
native cmsta_get_user_realtime(index);


#include gamecms_stocks.inc