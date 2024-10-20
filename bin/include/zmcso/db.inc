#if defined _zmcsoDB_included
	#endinput
#endif
#define _zmcsoDB_included

#include <sqlx>

/**
  Получить кортеж к БД
  
  @return   Кортеж к БД
  */
native Handle:db_get_tuple();

#define TURPLE db_get_tuple()



/** 
    Идентификатор игрока в таблице 

    @param id       Индекс игрока
    @return         Идентификатор игрока в БД
*/
native db_get_userid(id);


/**
    Форвард вызывается, когда данные клиента
    успешно подгруженны из БД

    @param id - Индекс клиента
 */
forward zpe_mysql_user_load_post(id);


/**
	Форвард вызывается для переодического сохранения
	данных

	@param id - Индекс игрока
 */
forward zpe_mysql_delay_save(id);

// Папка, в которую логируются сохранения при дисконнекте
new stock const g_szLogFile[] = "addons/amxmodx/logs/zpe_sql_main"; 


stock SQL_ErrorlogThread(iFailState, Handle:hQuery, szError[], iError)
{
	new szTemp[1024]; 
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED: formatex(szTemp, charsmax(szTemp), "Connection Filed [%d] : %s", iError, szError);
		case TQUERY_QUERY_FAILED: formatex(szTemp, charsmax(szTemp), "Query Filed [%d] : %s", iError, szError);
	}
	log_db_data(szTemp);

	SQL_GetQueryString(hQuery, szTemp, charsmax(szTemp));
	log_db_data(szTemp);
}

stock log_db_data(const szBuffer[])
{
	new szLogPath[1024], szDateThis[25];
	format_time(szDateThis, charsmax(szDateThis), "%d_%m_%Y", get_systime());
	formatex(szLogPath, charsmax(szLogPath), "%s/sql_%s.log", g_szLogFile, szDateThis);
	log_to_file(szLogPath, szBuffer);
}