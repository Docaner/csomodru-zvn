#include <amxmodx>
#include <reapi>
#include <sqlx>
#include <zp_system>
#include <zombieplague>
#include <zpe_lvl>
#include <zpe_key>
#include <human_models>
#include <zmcso/db>

#define get_bit(%1,%2)		((%1 & (1 << (%2 & 31))) ? 1 : 0)
#define set_bit(%1,%2)		%1 |= (1 << (%2 & 31))
#define reset_bit(%1,%2)	%1 &= ~(1 << (%2 & 31))

#define SQL_HOST 			"46.174.52.223" 			// IP/Host бд
#define SQL_USER 			"u7_sF22ZPNdCS" 			// Логин бд
#define SQL_PASSWORD 		"iBazVUvYhG46UE4JBt.dE@Pz" 			// Пароль бд
#define SQL_DATABASE 		"s7_zvn" 			// База данных

#define STARTMONEY 		20000
#define STARTAMMO 		5
#define STARTZMCLASS 	0
#define STARTKNIFE 		0
#define STARTMKEY		20
#define STARTAKEY		10
#define STARTXP 		0
#define STARTSKIN 		"magui"

new g_iUser_dbID[33] = { -1, ...}; 

new g_iBitUserConnected;

//Кортеж подключения
new Handle: g_hDBTuple; 

enum _:VALID_USER
{
	V_ID,
	V_STEAMID[34]
}

#define TASK_DELAYSAVE 42342323

// Раз в сколько минут переодически сохранять информацию об игроке
#define TIME_DELAYSAVE 7.0 
// Задержка между сохранениями игроков 
#define USERDELAY 5.0

new Float:g_flNextSave;

new g_iFwd_MySQLUserLoad, g_iFwd_MySQLDelaySave;

public plugin_natives()
{
	register_native("db_get_tuple", "@db_get_tuple", true);
	register_native("db_get_userid", "@db_get_userid", true);
}

/* Кортеж БД */
Handle:@db_get_tuple() return g_hDBTuple;

/* Идентификатор игрока в таблице */
@db_get_userid(id) return g_iUser_dbID[id];

public plugin_init( )
{
	register_plugin( "[ZC] DB Interface: Main", "1.0", "Docaner" );

	g_iFwd_MySQLUserLoad = CreateMultiForward("zpe_mysql_user_load_post", ET_IGNORE, FP_CELL);
	g_iFwd_MySQLDelaySave = CreateMultiForward("zpe_mysql_delay_save", ET_IGNORE, FP_CELL);

	g_flNextSave = get_gametime() + TIME_DELAYSAVE * 60.0;
}

public plugin_cfg( ) 
{
	g_hDBTuple = SQL_MakeDbTuple( SQL_HOST, SQL_USER, SQL_PASSWORD, SQL_DATABASE );
	SQL_SetCharset(g_hDBTuple, "utf8");
}

public plugin_end( ) if( g_hDBTuple ) SQL_FreeHandle( g_hDBTuple );

public client_putinserver(id) db_login_user(id);

stock db_login_user(id) {

	if(is_user_bot(id) || is_user_hltv(id))
		return false;

	new szSteamID[34]; get_user_authid(id, szSteamID, charsmax(szSteamID));

	if(equal(szSteamID, "ID_PENDING") || equal(szSteamID, ""))
		return false;

	new szIP[15]; get_user_ip(id, szIP, charsmax(szIP), true);
	
	new szName[32]; get_user_name(id, szName, charsmax(szName));
	new szConName[64]; SQL_QuoteString(Empty_Handle, szConName, charsmax(szConName), szName);

	new szQuery[1024];
	formatex(szQuery, charsmax(szQuery), "CALL zp_login_user(^"%s^", ^"%s^", ^"%s^", %d, %d, %d, %d, %d, %d, %d, ^"%s^")", szSteamID, szIP, szConName, STARTMONEY, STARTAMMO, STARTMKEY, STARTAKEY, STARTXP, STARTZMCLASS, STARTKNIFE, STARTSKIN);

	new szData[VALID_USER]; szData[V_ID] = id;
	copy(szData[V_STEAMID], charsmax(szData[V_STEAMID]), szSteamID);

	SQL_ThreadQuery(g_hDBTuple, "@db_login_result", szQuery, szData, sizeof szData);
	return true;
}

@db_login_result(iFailState, Handle:hQuery, szError[], iError, szData[])
{
	if(iFailState) 
		{SQL_ErrorlogThread(iFailState, hQuery, szError, iError); return;}

	new id = szData[V_ID];
	new szSteamID[32]; get_user_authid(id, szSteamID, charsmax(szSteamID));

	if(!is_user_connecting(id) && !is_user_connected(id) || !equal(szSteamID, szData[V_STEAMID]))
		return;

	g_iUser_dbID[id] = SQL_ReadResult( hQuery, SQL_FieldNameToNum(hQuery, "UserID") );
	zp_set_user_money_i( id, SQL_ReadResult( hQuery, SQL_FieldNameToNum(hQuery, "Money") ) );
	zp_set_user_ammo_i( id, SQL_ReadResult( hQuery, SQL_FieldNameToNum(hQuery, "Ammo") ) );
	zpe_set_user_moneykey_wohud(id, SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "MKey")));
	zpe_set_user_ammokey_wohud(id, SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "AKey")));

	zpe_set_user_lvl(id, 1); zpe_set_user_exp_wohud(id, SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "Experience")));
	
	zp_set_user_zombie_class( id, SQL_ReadResult( hQuery, SQL_FieldNameToNum(hQuery, "ZClass")) );
	ZPE_SetUserKnife( id, SQL_ReadResult( hQuery, SQL_FieldNameToNum(hQuery, "Knife") ) );

	new szSkinKey[32]; SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "SkinKey"), szSkinKey, charsmax(szSkinKey));
	zp_set_user_human_skin_key(id, szSkinKey);

	new iDummy; ExecuteForward(g_iFwd_MySQLUserLoad, iDummy, id);
	set_task(getUserDelay(id), "task_UserDelay", id+TASK_DELAYSAVE);

	set_bit(g_iBitUserConnected, id);
}

public task_UserDelay(id)
{
	id -= TASK_DELAYSAVE;

	db_set_zombiedata(id);

	new iDummy; ExecuteForward(g_iFwd_MySQLDelaySave, iDummy, id);

	set_task(getUserDelay(id), "task_UserDelay", id+TASK_DELAYSAVE);
}

public client_disconnected(id)
{
	if(db_set_zombiedata(id)) 
	{
		reset_bit(g_iBitUserConnected, id);
		remove_task(TASK_DELAYSAVE+id);
		g_iUser_dbID[id] = -1;
	}
}

stock db_set_zombiedata(id)
{
	if(!get_bit(g_iBitUserConnected, id)) return false;

	new szSteamID[34]; get_user_authid(id, szSteamID, charsmax(szSteamID));
	new szIP[15]; get_user_ip(id, szIP, charsmax(szIP), true);
	
	new szName[32]; get_user_name(id, szName, charsmax(szName));
	new szConName[64]; SQL_QuoteString(Empty_Handle, szConName, charsmax(szConName), szName);

	new szSkinKey[32]; zp_get_user_human_skin_key(id, szSkinKey, charsmax(szSkinKey));

	new szQuery[1024]; formatex(szQuery, charsmax(szQuery), "CALL zp_set_zombiedata(%d, ^"%s^", ^"%s^", %d, %d, %d, %d, %d, %d, %d, ^"%s^")", g_iUser_dbID[id], szIP, szConName, zp_get_user_money(id), zp_get_user_ammo(id), zpe_get_user_moneykey(id), zpe_get_user_ammokey(id), zpe_get_user_exp(id), zp_get_user_next_class(id), ZPE_GetUserKnife(id), szSkinKey);

	SQL_ThreadQuery(g_hDBTuple, "@db_set_zombiedata_result", szQuery);
	return true;
}

@db_set_zombiedata_result(iFailState, Handle:hQuery, szError[], iError)
{
	if(iFailState) 
		{SQL_ErrorlogThread(iFailState, hQuery, szError, iError); return;}

	new szTemp[1024]; SQL_GetQueryString(hQuery, szTemp, charsmax(szTemp));
	log_db_data(szTemp);
}

/**
	Функция получает задержку времени сохранения информации
 */
stock Float:getUserDelay(id)
{
	new Float:flGameTime = get_gametime();

	if(flGameTime >= g_flNextSave) 
		g_flNextSave = flGameTime + TIME_DELAYSAVE * 60.0;

	new Float:flNextTime = g_flNextSave + float(id) * USERDELAY;

	return flNextTime - flGameTime; 
}