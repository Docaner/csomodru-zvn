new const PLUGIN_VERSION[] = "1.0.0" // based on Mogel's original Walkguard plugin

// Default access flag (later can be changed in 'configs/cmdaccess.ini')
#define ACCESS_FLAG ADMIN_CFG

// Client editor menu chat commands
new const CLCMDS[][] = {
	"wgmenu"
}

// Configs folder in 'amxmodx/configs'
new const CFG_DIR[] = "walkguard"

// Actions log (comment to disable)
//new const LOG_FILENAME[] = "Walkguard.log"

/* -------------------- */

#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

new const ENT_CLASSNAME[] = "walkguard_zone"
new const ENT_MODEL[] = "models/pshell.mdl"
new const LINE_SPRITE[] = "sprites/dot.spr"

new const Float:DEF_MINS[3] = { -32.0, -32.0, -32.0 }
new const Float:DEF_MAXS[3] = { 32.0, 32.0, 32.0 }

const BOX_LINE_WIDTH = 5
const BOX_LINE_BRIGHTNESS = 200
new const BOX_LINE_COLOR_MAIN[3] = { 0, 255, 0 }
new const BOX_LINE_COLOR_RED[3] = { 255, 0, 0 }
new const BOX_LINE_COLOR_YELLOW[3] = { 255, 255, 0 }

#define ALL_KEYS 1023
#define chx charsmax
#define chx_len(%0) charsmax(%0) - iLen

new const MENU_IDENT_STRING[] = "WalkguardMenu"

enum { _KEY1_, _KEY2_, _KEY3_, _KEY4_, _KEY5_, _KEY6_, _KEY7_, _KEY8_, _KEY9_, _KEY0_ }

stock const SOUND__BLIP1[] = "sound/buttons/blip1.wav"
stock const SOUND__ERROR[] = "sound/buttons/button2.wav"

const TASKID__HIGHLIGHT = 1337

enum {
	MENU_MODE__MAIN,
	MENU_MODE__EDIT
}

new g_szMenu[MAX_MENU_LENGTH]
new g_iMenuMode[MAX_PLAYERS + 1]
new g_szCfgPath[PLATFORM_MAX_PATH]
new g_pEnt[MAX_PLAYERS + 1]
new g_iAxis[MAX_PLAYERS + 1] = { 1, ... }
new Float:g_fStepSize[MAX_PLAYERS + 1] = { 10.0, ... }
new g_iSpriteID
new g_pEditor
new g_szMapName[64]

/* -------------------- */

public plugin_init() {
	register_plugin("Walkguard", PLUGIN_VERSION, "mx?!")
	register_dictionary("walkguard.txt")

	/* --- */

	for(new i; i < sizeof(CLCMDS); i++) {
		register_clcmd(CLCMDS[i], "clcmd_OpenMainMenu", ACCESS_FLAG, .FlagManager = 1)
	}

	register_menucmd(register_menuid(MENU_IDENT_STRING), ALL_KEYS, "func_Menu_Handler")

	get_mapname(g_szMapName, chx(g_szMapName))
	func_LoadCfg()
}

/* -------------------- */

public clcmd_OpenMainMenu(pPlayer, bitAccess) {
	if(bitAccess && !(get_user_flags(pPlayer) & bitAccess)) {
		rg_send_audio(pPlayer, SOUND__ERROR)
		client_print_color(pPlayer, print_team_red, "%l", "WALKGUARD__NO_ACCESS")
		return PLUGIN_HANDLED
	}

	if(g_pEditor && g_pEditor != pPlayer) {
		rg_send_audio(pPlayer, SOUND__ERROR)
		client_print_color(pPlayer, print_team_red, "%l", "WALKGUARD__BUSY", g_pEditor)
		return PLUGIN_HANDLED
	}

	if(!g_pEditor) {
		g_pEditor = pPlayer

		set_task_ex(0.2, "task_Highlight", TASKID__HIGHLIGHT, .flags = SetTask_Repeat)

		new pEnt = MaxClients

		while((pEnt = rg_find_ent_by_class(pEnt, ENT_CLASSNAME, .useHashTable = false))) {
			set_entvar(pEnt, var_solid, SOLID_NOT)
			rg_set_entity_visibility(pEnt, .visible = 1)
		}
	}

	func_MainMenu(pPlayer)
	return PLUGIN_HANDLED
}

/* -------------------- */

func_MainMenu(pPlayer) {
	SetGlobalTransTarget(pPlayer)

	if( !IsZoneValid( g_pEnt[pPlayer] ) ) {
		g_pEnt[pPlayer] = 0
	}

	new pEnt = g_pEnt[pPlayer]

	new iLastNumber = 'r', iLastItem = 'w'

	if(!pEnt) {
		iLastNumber = iLastItem = 'd'
	}

	new iNextNumber = 'r', iNextItem = 'w'

	if(!rg_find_ent_by_class(MaxClients, ENT_CLASSNAME, .useHashTable = false)) {
		iNextNumber = iNextItem = 'd'
	}

	new iEditNumber = 'r', iEditItem = 'w'

	if(!pEnt) {
		iEditNumber = iEditItem = 'd'
	}

	new iDelNumber = 'r', iDetItem = 'w'

	if(!pEnt) {
		iDelNumber = iDetItem = 'd'
	}

	formatex( g_szMenu, chx(g_szMenu),
		"\y%l^n\
		^n\
		\%c1. \%c%l^n\
		\%c2. \%c%l^n\
		^n\
		\%c3. \%c%l^n\
		^n\
		\r4. \w%l^n\
		^n\
		\%c6. \%c%l^n\
		^n\
		\r8. \w%l^n\
		^n\
		\r0. \w%l",

		"WALKGUARD__MAIN_MENU_TITLE",

		iLastNumber, iLastItem, "WALKGUARD__TO_LAST",
		iNextNumber, iNextItem, "WALKGUARD__TO_NEXT",

		iEditNumber, iEditItem, "WALKGUARD__EDIT",

		"WALKGUARD__CREATE_NEW",

		iDelNumber, iDetItem, "WALKGUARD__DEL_ZONE",

		"WALKGUARD__SAVE_CFG",

		"WALKGUARD__EXIT"
	);

	static const MENU_KEYS = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_6|MENU_KEY_8|MENU_KEY_0

	func_ShowMenu(pPlayer, MENU_KEYS, MENU_MODE__MAIN)
}

/* -------------------- */

func_MainMenu_SubHandler(pPlayer, iKey) {
	switch(iKey) {
		case _KEY1_: {
			new pOldEnt = g_pEnt[pPlayer]
			new pEnt = func_GetLastZone(pPlayer)

			if(pEnt) {
				g_pEnt[pPlayer] = pEnt
				func_MoveToEntity(pPlayer, pEnt)
			}
			else if(IsZoneValid(pOldEnt)) {
				func_MoveToEntity(pPlayer, pOldEnt)
			}

			func_MainMenu(pPlayer)
		}
		case _KEY2_: {
			new pOldEnt = g_pEnt[pPlayer]
			new pEnt = func_GetNextZone(pPlayer)

			if(pEnt) {
				g_pEnt[pPlayer] = pEnt
				func_MoveToEntity(pPlayer, pEnt)
			}
			else if(IsZoneValid(pOldEnt)) {
				func_MoveToEntity(pPlayer, pOldEnt)
			}

			func_MainMenu(pPlayer)
		}
		case _KEY3_: {
			if( !IsZoneValid( g_pEnt[pPlayer] ) ) {
				g_pEnt[pPlayer] = 0
				func_MainMenu(pPlayer)
				return
			}

			func_EditMenu(pPlayer)
		}
		case _KEY4_: {
			new Float:fOrigin[3]
			get_entvar(pPlayer, var_origin, fOrigin)

			new pEnt = func_CreateZone(fOrigin, DEF_MINS, DEF_MAXS, 1)

			if(!pEnt) {
				rg_send_audio(pPlayer, SOUND__ERROR)
				client_print_color(pPlayer, print_team_red, "%l", "WALKGUARD__ERROR")
				func_MainMenu(pPlayer)
				return
			}

			g_pEnt[pPlayer] = pEnt
			func_EditMenu(pPlayer)
		}
		case _KEY6_: {
			if( !IsZoneValid( g_pEnt[pPlayer] ) ) {
				g_pEnt[pPlayer] = 0
				func_MainMenu(pPlayer)
				return
			}

			new pEnt = g_pEnt[pPlayer]

			g_pEnt[pPlayer] = func_GetLastZone(pPlayer)

			engfunc(EngFunc_RemoveEntity, pEnt) // don't replace with FL_KILLME!

			rg_send_audio(pPlayer, SOUND__BLIP1)
			client_print_color(pPlayer, print_team_red, "%l", "WALKGUARD__REMOVED")

			func_MainMenu(pPlayer)
		}
		case _KEY8_: {
			new iCount = func_SaveCfg(pPlayer)

			rg_send_audio(pPlayer, SOUND__BLIP1)
			client_print_color(pPlayer, print_team_red, "%l", iCount ? "WALKGUARD__SAVED" : "WALKGUARD__DELETED")

			func_MainMenu(pPlayer)
		}
		case _KEY0_: {
			g_pEditor = 0
			func_OverWork()
		}
	}
}

/* -------------------- */

func_EditMenu(pPlayer) {
	SetGlobalTransTarget(pPlayer)

	static const VECTOR_CHAR[3] = { any:'X', any:'Y', any:'Z' }

	new iAxis = g_iAxis[pPlayer]

	formatex( g_szMenu, chx(g_szMenu),
		"\y%l^n\
		^n\
		\r2. \w%l \y%c\
		^n      \r3. \w<- %l      \r4. \w-> %l\
		^n      \y5. \w<- %l      \y6. \w-> %l^n\
		^n\
		\r7. \w%l: \y%.0f^n\
		^n\
		\r0. \w%l",

		"WALKGUARD__EDIT_MENU_TITLE",

		"WALKGUARD__CHANGE_AXIS", VECTOR_CHAR[iAxis],
		"WALKGUARD__TIGHTER", "WALKGUARD__WIDER",
		"WALKGUARD__TIGHTER", "WALKGUARD__WIDER",

		"WALKGUARD__CHANGE_STEP", g_fStepSize[pPlayer],

		"WALKGUARD__BACK"
	);

	const MENU_KEYS = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_0

	func_ShowMenu(pPlayer, MENU_KEYS, MENU_MODE__EDIT)
}

/* -------------------- */

func_EditMenu_SubHandler(pPlayer, iKey) {
	if( !IsZoneValid( g_pEnt[pPlayer] ) ) {
		g_pEnt[pPlayer] = 0
		func_MainMenu(pPlayer)
		return
	}

	switch(iKey) {
		case _KEY2_: {
			if(++g_iAxis[pPlayer] == 3) {
				g_iAxis[pPlayer] = 0
			}

			func_EditMenu(pPlayer)
		}
		case _KEY7_: {
			g_fStepSize[pPlayer] = (g_fStepSize[pPlayer] != 100.0) ? g_fStepSize[pPlayer] * 10.0 : 1.0;
			func_EditMenu(pPlayer)
		}
		case _KEY0_: {
			func_MainMenu(pPlayer)
		}
		default: { // _KEY3_, _KEY4_, _KEY5_, _KEY6_
			func_ChangeSize(pPlayer, iKey)
			func_EditMenu(pPlayer)
		}
	}
}

/* -------------------- */

public func_Menu_Handler(pPlayer, iKey) {
	if(!is_user_connected(pPlayer)) {
		return
	}

	switch(g_iMenuMode[pPlayer]) {
		case MENU_MODE__MAIN: func_MainMenu_SubHandler(pPlayer, iKey)
		case MENU_MODE__EDIT: func_EditMenu_SubHandler(pPlayer, iKey)
	}
}

/* -------------------- */

func_ShowMenu(pPlayer, iKeys, iMenuMode) {
	g_iMenuMode[pPlayer] = iMenuMode
	show_menu(pPlayer, iKeys, g_szMenu, -1, MENU_IDENT_STRING)
}

/* -------------------- */

bool:IsZoneValid(pEnt) {
	return FClassnameIs(pEnt, ENT_CLASSNAME)
}

/* -------------------- */

func_GetNextZone(pPlayer) {
	if( !IsZoneValid( g_pEnt[pPlayer] ) ) {
		g_pEnt[pPlayer] = 0
	}

	return rg_find_ent_by_class(g_pEnt[pPlayer], ENT_CLASSNAME, .useHashTable = false)
}

/* -------------------- */

func_GetLastZone(pPlayer) {
	if( !IsZoneValid( g_pEnt[pPlayer] ) ) {
		g_pEnt[pPlayer] = 0
		return 0
	}

	new pLastEnt, pEnt = MaxClients

	while((pEnt = rg_find_ent_by_class(pEnt, ENT_CLASSNAME, .useHashTable = false))) {
		if(pEnt == g_pEnt[pPlayer]) {
			return pLastEnt
		}

		pLastEnt = pEnt
	}

	return 0
}

/* -------------------- */

func_MoveToEntity(pPlayer, pEnt) {
	new Float:fOrigin[3]
	get_entvar(pEnt, var_origin, fOrigin)
	engfunc(EngFunc_SetOrigin, pPlayer, fOrigin)
	set_entvar(pPlayer, var_velocity, NULL_VECTOR)
	set_member(pPlayer, m_flVelocityModifier, 0.5)
}

/* -------------------- */

func_ChangeSize(pPlayer, iKey) {
	new pEnt = g_pEnt[pPlayer]
	new iAxis = g_iAxis[pPlayer]
	new Float:fStepSize = g_fStepSize[pPlayer]

	new Float:fOrigin[3], Float:fMins[3], Float:fMaxs[3]

	get_entvar(pEnt, var_origin, fOrigin)
	get_entvar(pEnt, var_mins, fMins)
	get_entvar(pEnt, var_maxs, fMaxs)

	if(
		(iKey == _KEY3_ || iKey == _KEY5_)
			&&
		((floatabs(fMins[iAxis]) + fMaxs[iAxis]) < fStepSize + 1.0)
	) {
		rg_send_audio(pPlayer, SOUND__ERROR)
		return
	}

	new Float:fSizeStep = fStepSize / 2.0

	switch(iKey) {
		case _KEY3_: {
			fMins[iAxis] += fSizeStep
			fMaxs[iAxis] -= fSizeStep
			fOrigin[iAxis] += fSizeStep
		}
		case _KEY4_: {
			fMins[iAxis] -= fSizeStep
			fMaxs[iAxis] += fSizeStep
			fOrigin[iAxis] -= fSizeStep
		}
		case _KEY5_: {
			fMins[iAxis] += fSizeStep
			fMaxs[iAxis] -= fSizeStep
			fOrigin[iAxis] -= fSizeStep
		}
		case _KEY6_: {
			fMins[iAxis] -= fSizeStep
			fMaxs[iAxis] += fSizeStep
			fOrigin[iAxis] += fSizeStep
		}
	}

	engfunc(EngFunc_SetOrigin, pEnt, fOrigin)
	engfunc(EngFunc_SetSize, pEnt, fMins, fMaxs)
}

/* -------------------- */

func_SaveCfg(pPlayer) {
	new hFile = fopen(g_szCfgPath, "w")

	if(!hFile) {
		abort(AMX_ERR_GENERAL, "Can't write to '%s'", g_szCfgPath)
	}

	new iCount, Float:fOrigin[3], Float:fMins[3], Float:fMaxs[3], pEnt = MaxClients;

	fputs(hFile, "; Walkguard zone file. Params: Origin<3> Mins<3> Maxs<3>^n")

	while((pEnt = rg_find_ent_by_class(pEnt, ENT_CLASSNAME, .useHashTable = false))) {
		get_entvar(pEnt, var_origin, fOrigin)
		get_entvar(pEnt, var_mins, fMins)
		get_entvar(pEnt, var_maxs, fMaxs)

		fprintf( hFile, "wgz_block_all %f %f %f %f %f %f %f %f %f^n",
			fOrigin[0],
			fOrigin[1],
			fOrigin[2],
			fMins[0],
			fMins[1],
			fMins[2],
			fMaxs[0],
			fMaxs[1],
			fMaxs[2]
		);

		iCount++
	}

	fclose(hFile)

	if(!iCount) {
		delete_file(g_szCfgPath)
	}

	/* --- */

	new szAuthID[MAX_AUTHID_LENGTH], szIP[MAX_IP_LENGTH]
	get_user_authid(pPlayer, szAuthID, chx(szAuthID))
	get_user_ip(pPlayer, szIP, chx(szIP), .without_port = 1)

#if defined LOG_FILENAME
	log_to_file( LOG_FILENAME, "<%n><%s><%s> %s config on '%s'",
		pPlayer, szAuthID, szIP, iCount ? "save" : "delete", g_szMapName );
#endif

	return iCount
}

/* -------------------- */

func_LoadCfg() {
	new iLen = get_configsdir(g_szCfgPath, chx(g_szCfgPath))

	iLen += formatex(g_szCfgPath[iLen], chx_len(g_szCfgPath), "/%s", CFG_DIR)

	if(!dir_exists(g_szCfgPath)) {
		mkdir(g_szCfgPath)
	}

	formatex(g_szCfgPath[iLen], chx_len(g_szCfgPath), "/%s.wgz", g_szMapName)

	new hFile = fopen(g_szCfgPath, "r")

	if(!hFile) {
		if(file_exists(g_szCfgPath)) {
			abort(AMX_ERR_GENERAL, "Can't read '%s'", g_szCfgPath)
		}

		return
	}

	new szText[256], szType[32], szOrigin[3][10], szMins[3][10], szMaxs[3][10],
		Float:fOrigin[3], Float:fMins[3], Float:fMaxs[3], pEnt;

	while(fgets(hFile, szText, chx(szText))) {
		trim(szText)

		if(!szText[0] || szText[0] == ';') {
			continue
		}

		parse( szText,
			szType, chx(szType),
			szOrigin[0], chx(szOrigin[]),
			szOrigin[1], chx(szOrigin[]),
			szOrigin[2], chx(szOrigin[]),
			szMins[0], chx(szMins[]),
			szMins[1], chx(szMins[]),
			szMins[2], chx(szMins[]),
			szMaxs[0], chx(szMins[]),
			szMaxs[1], chx(szMins[]),
			szMaxs[2], chx(szMins[])
		);

		if(!equal(szType, "wgz_block_all")) {
			continue
		}

		for(new i; i < 3; i++) {
			fOrigin[i] = str_to_float(szOrigin[i])
			fMins[i] = str_to_float(szMins[i])
			fMaxs[i] = str_to_float(szMaxs[i])
		}

		pEnt = func_CreateZone(fOrigin, fMins, fMaxs, 0)

		if(!pEnt) {
			fclose(hFile)
			abort(AMX_ERR_GENERAL, "Can't create entity in func_LoadCfg() !")
		}
	}

	fclose(hFile)
}

/* -------------------- */
func_CreateZone(const Float:fOrigin[3], const Float:fMins[3], const Float:fMaxs[3], iVisible) {
	new pEnt = rg_create_entity("info_target", .useHashTable = false)

	if(!pEnt) {
		return 0
	}

	set_entvar(pEnt, var_classname, ENT_CLASSNAME)
	set_entvar(pEnt, var_solid, g_pEditor ? SOLID_NOT : SOLID_TRIGGER)
	
	engfunc(EngFunc_SetModel, pEnt, ENT_MODEL)
	engfunc(EngFunc_SetSize, pEnt, fMins, fMaxs)
	engfunc(EngFunc_SetOrigin, pEnt, fOrigin)


	// good: with this we don't need to reload cfg to aply new zone size
	// bad: with this push will work and other entities can push zone entity
	//set_entvar(pEnt, var_movetype, MOVETYPE_FLY)

	rg_set_entity_visibility(pEnt, .visible = iVisible)
	SetTouch(pEnt, "@Touch__Zone");

	return pEnt
}

//Скорость откидывания от заблокированной зоны
#define TOUCH_VELOCITY 200.0

@Touch__Zone(const pEnt, const pToucher)
{
	if(is_nullent(pToucher))
		return;

	if(!is_user_connected(pToucher) && !FClassnameIs(pToucher, "weaponbox"))
		return;

	//Получаем местоположение и размеры entity
	//vecEntSize index: 0-2 -> var_mins; 3-5 -> var_maxs;
	new Float:vecEnt[3], Float:vecEntSize[6]
	get_ent_sizepos(pEnt, vecEnt, vecEntSize);

	//Получаем местоположение, размеры и velocity player
	//vecPlayerSize index: 0-2 -> var_mins; 3-5 -> var_maxs;
	new Float:vecPlayer[3], Float:vecPlayerSize[6], Float:vecPlayerVel[3];
	get_ent_sizepos(pToucher, vecPlayer, vecPlayerSize);
	get_entvar(pToucher, var_velocity, vecPlayerVel)

	//Находим разницу между соприкосающимися гранями
	new iSize = sizeof vecEntSize, Float:vecEntEdge, Float:vecPlayerEdge, Float:vecDifEdges[6];

	for(new i, iVec, iAposite; i < iSize; i++)
	{
		//Индекс оси вектора
		iVec = i % 3;

		//Противоположный индекс вектора
		iAposite = (i + 3) % 6;

		//Находим соответствующие положения соприкосающихся граней box ent и box player
		vecEntEdge = vecEnt[iVec] + vecEntSize[i];
		vecPlayerEdge = vecPlayer[iVec] + vecPlayerSize[iAposite];

		//Записываем разницу между гранью entity и человека
		vecDifEdges[i] = floatabs(vecEntEdge - vecPlayerEdge)
	}

	//Находим грань с минимальной разницей
	new iMinEdge = 0;
	for(new i = 1; i < iSize; i++)
	{
		if(vecDifEdges[i] < vecDifEdges[iMinEdge])
			iMinEdge = i;
	}

	//По соответствующей оси выставляем нужную нам скорость с соответствующим знаком
	vecPlayerVel[iMinEdge % 3] =  (iMinEdge / 3) ? TOUCH_VELOCITY : -TOUCH_VELOCITY;
	set_entvar(pToucher, var_velocity, vecPlayerVel);
}

stock get_ent_sizepos(const pEnt, Float:vecOrigin[], Float:vecSize[])
{
	get_entvar(pEnt, var_origin, vecOrigin);
	get_entvar(pEnt, var_mins, vecSize[0])
	get_entvar(pEnt, var_maxs, vecSize[3])
}

/* -------------------- */

func_OverWork() {
	remove_task(TASKID__HIGHLIGHT)

	new pEnt = MaxClients

	while((pEnt = rg_find_ent_by_class(pEnt, ENT_CLASSNAME, .useHashTable = false))) {
		/*set_entvar(pEnt, var_solid, SOLID_BBOX)
		rg_set_entity_visibility(pEnt, .visible = 0)*/

		set_entvar(pEnt, var_flags, FL_KILLME) // new
	}

	arrayset(g_pEnt, 0, sizeof(g_pEnt)) // new

	// new, reload cfg to apply new sizes, as we don't use MOVETYPE_FLY anymore
	func_LoadCfg()
}

/* -------------------- */

public task_Highlight() {
	static Float:fEntOrigin[3], Float:fUserOrigin[3], Float:fMins[3], Float:fMaxs[3]

	if( !IsZoneValid( g_pEnt[g_pEditor] ) ) {
		return
	}

	new pEnt = g_pEnt[g_pEditor]

	get_entvar(pEnt, var_origin, fEntOrigin)
	get_entvar(pEnt, var_mins, fMins)
	get_entvar(pEnt, var_maxs, fMaxs)

	get_entvar(g_pEditor, var_origin, fUserOrigin)
	fUserOrigin[2] -= 16.0

	func_DrawLine(g_pEditor, fUserOrigin[0], fUserOrigin[1], fUserOrigin[2],
		fEntOrigin[0], fEntOrigin[1], fEntOrigin[2], BOX_LINE_COLOR_MAIN );

	fMins[0] += fEntOrigin[0]
	fMins[1] += fEntOrigin[1]
	fMins[2] += fEntOrigin[2]
	fMaxs[0] += fEntOrigin[0]
	fMaxs[1] += fEntOrigin[1]
	fMaxs[2] += fEntOrigin[2]

	func_DrawLine(g_pEditor, fMaxs[0], fMaxs[1], fMaxs[2], fMins[0], fMaxs[1], fMaxs[2], BOX_LINE_COLOR_MAIN)
	func_DrawLine(g_pEditor, fMaxs[0], fMaxs[1], fMaxs[2], fMaxs[0], fMins[1], fMaxs[2], BOX_LINE_COLOR_MAIN)
	func_DrawLine(g_pEditor, fMaxs[0], fMaxs[1], fMaxs[2], fMaxs[0], fMaxs[1], fMins[2], BOX_LINE_COLOR_MAIN)
	func_DrawLine(g_pEditor, fMins[0], fMins[1], fMins[2], fMaxs[0], fMins[1], fMins[2], BOX_LINE_COLOR_MAIN)
	func_DrawLine(g_pEditor, fMins[0], fMins[1], fMins[2], fMins[0], fMaxs[1], fMins[2], BOX_LINE_COLOR_MAIN)
	func_DrawLine(g_pEditor, fMins[0], fMins[1], fMins[2], fMins[0], fMins[1], fMaxs[2], BOX_LINE_COLOR_MAIN)
	func_DrawLine(g_pEditor, fMins[0], fMaxs[1], fMaxs[2], fMins[0], fMaxs[1], fMins[2], BOX_LINE_COLOR_MAIN)
	func_DrawLine(g_pEditor, fMins[0], fMaxs[1], fMins[2], fMaxs[0], fMaxs[1], fMins[2], BOX_LINE_COLOR_MAIN)
	func_DrawLine(g_pEditor, fMaxs[0], fMaxs[1], fMins[2], fMaxs[0], fMins[1], fMins[2], BOX_LINE_COLOR_MAIN)
	func_DrawLine(g_pEditor, fMaxs[0], fMins[1], fMins[2], fMaxs[0], fMins[1], fMaxs[2], BOX_LINE_COLOR_MAIN)
	func_DrawLine(g_pEditor, fMaxs[0], fMins[1], fMaxs[2], fMins[0], fMins[1], fMaxs[2], BOX_LINE_COLOR_MAIN)
	func_DrawLine(g_pEditor, fMins[0], fMins[1], fMaxs[2], fMins[0], fMaxs[1], fMaxs[2], BOX_LINE_COLOR_MAIN)

	new iAxis = g_iAxis[g_pEditor]

	if(iAxis == 0) {
		func_DrawLine(g_pEditor, fMaxs[0], fMaxs[1], fMaxs[2], fMaxs[0], fMins[1], fMins[2], BOX_LINE_COLOR_YELLOW)
		func_DrawLine(g_pEditor, fMaxs[0], fMaxs[1], fMins[2], fMaxs[0], fMins[1], fMaxs[2], BOX_LINE_COLOR_YELLOW)
		func_DrawLine(g_pEditor, fMins[0], fMaxs[1], fMaxs[2], fMins[0], fMins[1], fMins[2], BOX_LINE_COLOR_RED)
		func_DrawLine(g_pEditor, fMins[0], fMaxs[1], fMins[2], fMins[0], fMins[1], fMaxs[2], BOX_LINE_COLOR_RED)
		return
	}

	if(iAxis == 1) {
		func_DrawLine(g_pEditor, fMins[0], fMins[1], fMins[2], fMaxs[0], fMins[1], fMaxs[2], BOX_LINE_COLOR_RED)
		func_DrawLine(g_pEditor, fMaxs[0], fMins[1], fMins[2], fMins[0], fMins[1], fMaxs[2], BOX_LINE_COLOR_RED)
		func_DrawLine(g_pEditor, fMins[0], fMaxs[1], fMins[2], fMaxs[0], fMaxs[1], fMaxs[2], BOX_LINE_COLOR_YELLOW)
		func_DrawLine(g_pEditor, fMaxs[0], fMaxs[1], fMins[2], fMins[0], fMaxs[1], fMaxs[2], BOX_LINE_COLOR_YELLOW)
		return
	}

	if(iAxis == 2) {
		func_DrawLine(g_pEditor, fMaxs[0], fMaxs[1], fMaxs[2], fMins[0], fMins[1], fMaxs[2], BOX_LINE_COLOR_YELLOW)
		func_DrawLine(g_pEditor, fMaxs[0], fMins[1], fMaxs[2], fMins[0], fMaxs[1], fMaxs[2], BOX_LINE_COLOR_YELLOW)
		func_DrawLine(g_pEditor, fMaxs[0], fMaxs[1], fMins[2], fMins[0], fMins[1], fMins[2], BOX_LINE_COLOR_RED)
		func_DrawLine(g_pEditor, fMaxs[0], fMins[1], fMins[2], fMins[0], fMaxs[1], fMins[2], BOX_LINE_COLOR_RED)
	}
}

/* -------------------- */

func_DrawLine(pPlayer, Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2, const iColor[3]) {
	static Float:fStart[3], Float:fEnd[3]

	fStart[0] = x1; fStart[1] = y1; fStart[2] = z1
	fEnd[0] = x2; fEnd[1] = y2; fEnd[2] = z2

	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, .player = pPlayer)
	write_byte(TE_BEAMPOINTS)
	write_coord_f(fStart[0])
	write_coord_f(fStart[1])
	write_coord_f(fStart[2])
	write_coord_f(fEnd[0])
	write_coord_f(fEnd[1])
	write_coord_f(fEnd[2])
	write_short(g_iSpriteID)
	write_byte(1) // starting frame
	write_byte(0) // frame rate in 0.1's
	write_byte(4) // life in 0.1's
	write_byte(BOX_LINE_WIDTH)
	write_byte(0) // noise amplitude in 0.01's
	write_byte(iColor[0]) // R
	write_byte(iColor[1]) // G
	write_byte(iColor[2]) // B
	write_byte(BOX_LINE_BRIGHTNESS) // brightness
	write_byte(0) // scroll speed in 0.1's
	message_end()
}

/* -------------------- */

public plugin_precache() {
	precache_model(ENT_MODEL)

	g_iSpriteID = precache_model(LINE_SPRITE)
}

/* -------------------- */

public client_disconnected(pPlayer) {
	if(pPlayer == g_pEditor) {
		g_pEditor = 0
		func_OverWork()
	}
}

/* -------------------- */

stock rg_set_entity_visibility(entity, visible = 1) {
	set_entvar(entity, var_effects, visible == 1 ? get_entvar(entity, var_effects) & ~EF_NODRAW : get_entvar(entity, var_effects) | EF_NODRAW);
}