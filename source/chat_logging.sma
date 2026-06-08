/*
	Plugin : Chat Logging (AMXX)
	Author : R4SAS

	Based on Chat Logger SQL (Version 0.5) by aake (aake4@hotmail.com)
	This plugin save chat messages to MySQL Database.
	Query is compatible with R1KO's Chat Logging plugin (SourceMod)
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <sqlx>

#define PLUGINNAME	"Chat Logging"
#define VERSION		"0.1.2"
#define AUTHOR		"R4SAS"
#define table		"servers__chatlog"

#if AMXX_VERSION_NUM < 190
	new g_charset[32];
#endif

new Handle:g_SqlX, Handle:g_SqlConnection, g_sid
new pcvar_sc_sql_host, pcvar_sc_sql_user, pcvar_sc_sql_pass, pcvar_sc_sql_db, pcvar_sc_sql_utf8, pcvar_sc_sql_sid

public check_sql()
{
	new host[64],user[64],pass[64],db[64],errorcode,error[512]

	get_pcvar_string(pcvar_sc_sql_host, host, charsmax(host))
	get_pcvar_string(pcvar_sc_sql_user, user, charsmax(user))
	get_pcvar_string(pcvar_sc_sql_pass, pass, charsmax(pass))
	get_pcvar_string(pcvar_sc_sql_db, db, charsmax(db))

	g_sid = get_pcvar_num(pcvar_sc_sql_sid)
	g_SqlX = SQL_MakeDbTuple(host, user, pass, db)

	if (get_pcvar_num(pcvar_sc_sql_utf8))
#if AMXX_VERSION_NUM < 190
		g_charset = "SET NAMES UTF8;"
#else
		SQL_SetCharset(g_SqlX, "utf8")
#endif

	g_SqlConnection = SQL_Connect(g_SqlX, errorcode, error, charsmax(error));

	if (!g_SqlConnection)
		return log_amx("Chat Logging: Could not connect to SQL database. Error: %s", error)

	new query_create[1000]
	format(query_create,charsmax(query_create),
		"CREATE TABLE IF NOT EXISTS %s (msg_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, \
			server_id INT UNSIGNED NOT NULL, \
			auth VARCHAR(65) NOT NULL, \
			ip VARCHAR(65) NOT NULL, \
			name VARCHAR(65) NOT NULL, \
			team TINYINT NOT NULL, \
			alive TINYINT NOT NULL, \
			timestamp INT UNSIGNED NOT NULL, \
			message VARCHAR(255) NOT NULL, \
			type VARCHAR(16) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8;", table)
	SQL_ThreadQuery(g_SqlX,"QueryHandle",query_create)
	return PLUGIN_CONTINUE
}

public chatlog_sql(id)
{
	if(is_user_bot(id) || !is_user_connected(id)) return

	new query[1000],message[192],cmd[16],authid[24],name[32],ip[16],team,timestamp

	read_argv(0,cmd,charsmax(cmd))
	read_args(message,charsmax(message))
	remove_quotes(message); trim(message);

	if(message[0] == EOS || message[0] == '/')
		return

	get_user_authid(id,authid,charsmax(authid))
	get_user_name(id,name,charsmax(name))
	get_user_ip(id,ip,charsmax(ip),1)
	timestamp = get_systime()

	// SourceMod compatability switch
	switch(cs_get_user_team(id)){
		case 0: {team = 0;}
		case 1: {team = 2;}
		case 2: {team = 3;}
		case 3: {team = 1;}
	}
#if AMXX_VERSION_NUM < 190
	format(query,charsmax(query),
		"%s INSERT INTO %s (server_id,auth,ip,name,team,alive,timestamp,message,type) VALUES ('%d','%s','%s','%s','%d','%d','%d','%s','%s')",
		g_charset,table,g_sid,authid,ip,name,team,is_user_alive(id),timestamp,message,cmd)
#else
	format(query,charsmax(query),
		"INSERT INTO %s (server_id,auth,ip,name,team,alive,timestamp,message,type) VALUES ('%d','%s','%s','%s','%d','%d','%d','%s','%s')",
		table,g_sid,authid,ip,name,team,is_user_alive(id),timestamp,message,cmd)
#endif
	SQL_ThreadQuery(g_SqlX,"QueryHandle",query)
}

public QueryHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
	return log_amx("Chat log SQL: Could not connect to SQL database.")

	else if(FailState == TQUERY_QUERY_FAILED)
	return log_amx("Chat log SQL: Query failed")

	if(Errcode)
	return log_amx("Chat log SQL: Error on query: %s",Error)

	new DataNum
	while(SQL_MoreResults(Query))
	{
		DataNum = SQL_ReadResult(Query,0)
		server_print("zomg, some data: %s",DataNum)
		SQL_NextRow(Query)
	}
	return PLUGIN_CONTINUE
}

public plugin_end()
{
	if( g_SqlX )
		SQL_FreeHandle( g_SqlX );

	if( g_SqlConnection )
		SQL_FreeHandle( g_SqlConnection );

	return
}

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHOR)
	register_cvar("sc_chat_logger",VERSION,FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)

	pcvar_sc_sql_host = register_cvar("sc_sql_host", "127.0.0.1");
	pcvar_sc_sql_user = register_cvar("sc_sql_user", "cms");
	pcvar_sc_sql_pass = register_cvar("sc_sql_pass", "");
	pcvar_sc_sql_db = register_cvar("sc_sql_db", "cms");
	pcvar_sc_sql_utf8 = register_cvar("sc_sql_utf8", "1");
	pcvar_sc_sql_sid = register_cvar("sc_sql_sid", "1");

	register_clcmd("say", "chatlog_sql")
	register_clcmd("say_team", "chatlog_sql")
	set_task(1.5, "check_sql")
}
