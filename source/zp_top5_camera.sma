#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <reapi>
#include <api_top5cam>
// #include <dhudmessage>
// #include <non_reapi_support_v1>

//Камера от третьего лица
// native set_user_camera(id, iValue);
// native get_user_camera(id);

//Проверить видимость шапочки
// native zp_user_visible_hat(id);

//Женские руки
// native api_get_user_hand(id);

//Вызов эмоции по номеру
// native execute_player_emotion(id, iEmotion);

//Мгновеная смена модели
// native bool:zp_user_instant_model(id);

//Модель камеры
new const g_szModel[] = "models/rshell.mdl"; 

//Конфиг сохранений камеры
new const g_szPathSave[] = "addons/amxmodx/configs/zpe_mode/zp_top5_camera.ini";

//Команда открытия меню редактирования сцены
new const g_szClCmd[] = "top5pos";

//Флаг админа, который может открыть меню камеры
#define ADMIN_OPEN ADMIN_RCON 

//Стартовая дистанция камеры от ТОП1 игрока
#define CAM_START_DISTANCE 30.0

//Конечная дистанция камеры, к которой она движется
#define CAM_END_DISTANCE 100.0

//Время передвижения от стартовой позиции к конечной
#define CAM_MOVING_TIME 15.0

//Сколько дополнительно по времени должна камера должна показывать сцену
#define CAM_STATIC_TIME 5.0

//Сколько длится эффект
#define CAM_EFFECT_TIME 0.6

//Время отображения топ5 списком
#define TOP5_LIST_TIME CAM_MOVING_TIME + CAM_STATIC_TIME

//Номер эмоции, которая устанавливается для топ5 (номер в меню - 1)

//Список мужских эмоций
// new const g_iEmotionMan[] = { 35, 16 }
//Список женских эмоций
// new const g_iEmotionWoman[] = { 13, 14, 15, 16 }


//Список мужских эмоций для топ1
// new const g_iEmotionManTop1[] = { 35, 16 }
//Список женских эмоций для топ1
// new const g_iEmotionWomanTop1[] = { 47, 64, 8, 52, } 

#define CAM_EMOTION_DELAY 0.5

//Цвет эффекта
new const g_iColorAlpha[][4] = 
{
	//Чёрный
	{0, 0, 0, 255},

	//Белый
	{255, 255, 255, 255}
} 

//Звук
new const g_szSound[][] =
{
	"sound/zp_br_cso/mod/wins/bgm_result3.wav",
}

//Объект камеры
new g_iEntCam;

//Загружена ли сцена
new bool:g_bScene;

//Положение сцены в пространстве и угл её поворота
new Float:g_vecOrigin[3], Float:g_vecAngles[3];

//Максимальное количество игроков
new g_iMaxPlayers;

//Битсумма игроков, которые подключены к камере
#define var_viewers_bitsum var_iuser4

//Геттер/сеттер битсуммы игроков просматривающих камеру 
#define GetBitViewers get_entvar(g_iEntCam, var_viewers_bitsum)
#define SetBitViewers(%0) set_entvar(g_iEntCam, var_viewers_bitsum, %0)

//Стадия камеры
#define var_cam_state var_iuser1

//Выбранный цвет камеры
#define var_cam_color var_iuser2

//Положение сцены
#define var_cam_pos var_vuser1

//Угл камеры
#define var_cam_angles var_vuser2

//Временная метка конца сцены
#define var_cam_timeend var_ltime

//Геттер/Сеттер стадии камеры
#define GetCamState CamState:get_entvar(g_iEntCam, var_cam_state)
#define SetCamState(%0) set_entvar(g_iEntCam, var_cam_state, %0)

//Идентификация камеры
#define CAMERA_IMPULSE 248583


#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))

//Положение игроков в топе относительно остальных игроков
new const Float:g_vecTopPositions[][] =
{
	{0.0, 0.0, 0.0}, // Положение 1 игрока
	{-36.0, 36.0, 0.0}, // Положение 2 игрока
	{-36.0, -36.0, 0.0}, // Положение 3 игрока
	{-72.0, 72.0, 0.0}, // Положение 4 игрока
	{-72.0, -72.0, 0.0} // Положение 5 игрока
};

//Перечисление для сортировки
enum _:e_UserStats
{
	//Индекс клиента
	e_iUserId = 0,
	//Количество фрагов
	Float:e_iUserFrags,
	//Количество смертей
	e_iUserDeath
};

//Hamsandwich хуки
new HamHook:g_hThinkCamera, HamHook:g_hPlayerKilled;

new g_iFwdCamStart;

public plugin_precache()
{
	for(new i; i < sizeof g_szSound; i++) 
		precache_generic(g_szSound[i]);
	
	precache_model(g_szModel);
}

public plugin_init()
{
	register_plugin("[ZP] TOP5 Camera", "1.0", "Docaner"); 

	register_menucmd(register_menuid("Show_Top5Position"), 1023, "Handle_Top5Position");
	register_clcmd(g_szClCmd, "Show_Top5Position");

	DisableHamForward( (g_hThinkCamera = RegisterHam(Ham_Think, "trigger_camera", "HM__CamThink_Post", true)) );
	DisableHamForward( (g_hPlayerKilled = RegisterHam(Ham_Killed, "player", "HM__PlayerKilled_Pre", false)) );

	g_iFwdCamStart = CreateMultiForward("top5cam_started", ET_IGNORE);

	g_iMaxPlayers = get_maxplayers();
}

public plugin_cfg()
{
	CamGetPos();
}

public plugin_natives()
{
	register_native("top5_camera_start", "native_top5_camera_start", 1);
	register_native("get_top5camera_time", "native_get_top5camera_time", 1);
	register_native("get_top5camera_state", "native_get_top5camera_state", 1);
}

public Show_Top5Position(id)
{
	if(~get_user_flags(id) & ADMIN_OPEN)
		return PLUGIN_HANDLED;

	new szMenu[512], iLen;

	iLen = formatex(szMenu, charsmax(szMenu), "\yМеню сцены^n^n");

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[1] \wУстановить позицию^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[2] \wЗагрузить позицию из файла^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[3] \wПросмотреть сцену^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[4] \wСохранить^n^n");

	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[0] \wВыход");

	return show_menu(id, (1<<0|1<<1|1<<2|1<<3|1<<9), szMenu, _, "Show_Top5Position");
}

public Handle_Top5Position(id, iKey)
{
	if(~get_user_flags(id) & ADMIN_OPEN)
		return PLUGIN_HANDLED;

	static Float:vecOrigin[3], Float:vecAngles[3], Float:vecNull[3];
	
	if(g_bScene && xs_vec_equal(vecOrigin, vecNull) && xs_vec_equal(vecAngles, vecNull))
	{
		xs_vec_copy(g_vecOrigin, vecOrigin);
		xs_vec_copy(g_vecAngles, vecAngles);
	}	
	
	switch(iKey)
	{
		case 0:
		{
			new Float:vecViewOfs[3]
			get_entvar(id, var_view_ofs, vecViewOfs);
			get_entvar(id, var_origin, vecOrigin);
			xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);

			get_entvar(id, var_v_angle, vecAngles);
			
			client_print(0, print_chat, "%f %f %f", vecViewOfs[0], vecViewOfs[1], vecViewOfs[2])
			client_print(0, print_chat, "%f %f %f", vecOrigin[0], vecOrigin[1], vecOrigin[2])
			client_print(0, print_chat, "%f %f %f", vecAngles[0], vecAngles[1], vecAngles[2])
		}
		case 1:
		{
			if(CamLoad(g_szPathSave))
			{
				xs_vec_copy(g_vecOrigin, vecOrigin);
				xs_vec_copy(g_vecAngles, vecAngles);
			}
		}
		case 2:
			if(!xs_vec_equal(vecOrigin, vecNull) || !xs_vec_equal(vecAngles, vecNull))
				CamPlay(vecOrigin, vecAngles);
		case 3:
			if(!xs_vec_equal(vecOrigin, vecNull) || !xs_vec_equal(vecAngles, vecNull))
				CamSave(g_szPathSave, vecOrigin, vecAngles);
		case 9:
			return PLUGIN_HANDLED;
	}	

	return Show_Top5Position(id);
}

stock CamGetPos(bool:bLog = true)
{
	g_bScene = CamLoad(g_szPathSave);

	if(!g_bScene && bLog)
	{
		log_amx("Координаты сцены не были загружены:");
		log_amx("Не удалось открыть файл: ^"%s^"", g_szPathSave);
	}
}

//Загрузка координат из файла szPath
stock bool:CamLoad(const szPath[])
{
	new iFile = fopen(szPath, "r");

	if(!iFile)
		return false;

	new szMap[32]; get_mapname(szMap, charsmax(szMap));
	new szBuffer[512], szCompMap[32], bool:bFind;
	
	while(!feof(iFile))
	{
		fgets(iFile, szBuffer, charsmax(szBuffer));
		strtok(szBuffer, szCompMap, charsmax(szCompMap), szBuffer, charsmax(szBuffer), '=');
		trim(szCompMap);

		if(strcmp(szMap, szCompMap)) continue;

		trim(szBuffer);
		
		//Чтение координат
		str_to_vector(szBuffer, charsmax(szBuffer), g_vecOrigin);
		str_to_vector(szBuffer, charsmax(szBuffer), g_vecAngles);
		
		bFind = true;
		break;
	}

	fclose(iFile);
	return bFind;
}

//Преобразует текстовое значение вектора в бинарный вид
//Прочитаная часть отрезается
stock str_to_vector(szSource[], iLen, Float:vecOut[3])
{
	new szNumber[32];
	
	for(new i; i < 3; i++)
	{
		strtok(szSource, szNumber, charsmax(szNumber), szSource, iLen, ' ', 1);
		vecOut[i] = str_to_float(szNumber);
	}
}

//Сохранение координат в файл
stock CamSave(const szFile[], const Float:vecOrigin[3], const Float:vecAngles[3])
{
	new szMap[32]; get_mapname(szMap, charsmax(szMap));

	new iLine = f_getline_by_prefix(szFile, szMap);

	new szText[128]; formatex(szText, charsmax(szText), "%s = %f %f %f %f %f %f", szMap, vecOrigin[0], vecOrigin[1], vecOrigin[2], vecAngles[0], vecAngles[1], vecAngles[2]);
	write_file(szFile, szText, iLine);

	xs_vec_copy(vecOrigin, g_vecOrigin);
	xs_vec_copy(vecAngles, g_vecAngles);
	g_bScene = true;
}

//Получает номер строки из файла в которой находится карта
//В противном случае вернётся -1
stock f_getline_by_prefix(const szFile[], const szMap[])
{
	new iFile = fopen(szFile, "r");

	if(!iFile) return -1;

	new szBuffer[512], szCompMap[32], bool:bFind, iLine = -1;

	while(!feof(iFile))
	{
		iLine++;

		fgets(iFile, szBuffer, charsmax(szBuffer));
		strtok(szBuffer, szCompMap, charsmax(szCompMap), szBuffer, charsmax(szBuffer), '=', 1);
		trim(szCompMap);

		if(strcmp(szMap, szCompMap)) continue;
		
		trim(szBuffer);
		bFind = true;
		break;
	}

	fclose(iFile);
	return bFind ? iLine : -1;

}

//Создаёт объект камеры
stock CreateCamera()
{
	new iEnt = rg_create_entity("trigger_camera")

	if(is_nullent(iEnt)) return NULLENT;

	set_entvar(iEnt, var_impulse, CAMERA_IMPULSE)
	engfunc(EngFunc_SetModel, iEnt, g_szModel);

	set_entvar(iEnt, var_movetype, MOVETYPE_NOCLIP);
	set_entvar(iEnt, var_rendermode, kRenderTransColor);

	return iEnt;
}

//Установить простмотр камеры клиенту
stock bool:ViewCamera(id) 
{
	if(is_nullent(g_iEntCam)) return false;

	new iBitViewers = GetBitViewers;

	engfunc(EngFunc_SetView, id, g_iEntCam);
	SetBit(iBitViewers, id);

	SetBitViewers(iBitViewers);
	return true;
}

//Установить клиенту свою камеру
stock bool:ViewYourself(id) 
{
	if(is_nullent(g_iEntCam)) return false;

	new iBitViewers = GetBitViewers;

	if(is_user_alive(id)) 
		engfunc(EngFunc_SetView, id, id);
	
	ClearBit(iBitViewers, id);

	SetBitViewers(iBitViewers);
	return true;
}

//Проигрывание анимации камеры
stock bool:CamPlay(const Float:vecStartOrigin[3], const Float:vecStartAngles[3])
{
	if(is_nullent(g_iEntCam)) g_iEntCam = CreateCamera();

	if(GetCamState != CAM_DISABLED) 
		return false;

	SetCamState(CAM_EFFECT);
	SwitchToggle(true);

	new Float:flGameTime = get_gametime(),
		Float:flFadeTime =  CAM_EFFECT_TIME/2.0,
		Float:flBlockTime = flFadeTime + CAM_MOVING_TIME + CAM_STATIC_TIME;

	set_entvar(g_iEntCam, var_cam_pos, vecStartOrigin);
	set_entvar(g_iEntCam, var_cam_angles, vecStartAngles);
	set_entvar(g_iEntCam, var_cam_timeend, flGameTime + flBlockTime);

	new iColor = random(sizeof g_iColorAlpha);
	set_entvar(g_iEntCam, var_cam_color, iColor);

	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_alive(iPlayer)) continue;
		
		// if(get_user_camera(iPlayer)) set_user_camera(iPlayer, 0);

		SCREEN_FADE(iPlayer, flFadeTime, flFadeTime, SF_FADE_IN, g_iColorAlpha[iColor]);
		//SetBlockAttackTime(iPlayer, flBlockTime);
		// zp_user_visible_hat(iPlayer);
	}

	//client_cmd(0, "spk ^"%s^"", g_szSound[random(sizeof g_szSound)]);

	set_entvar(g_iEntCam, var_nextthink, flGameTime + flFadeTime);

	new iRet;
	ExecuteForward(g_iFwdCamStart, iRet);

	return true;
}

stock SwitchToggle(bool:bValue)
{
	if(bValue)
	{
		EnableHamForward(g_hThinkCamera);
		EnableHamForward(g_hPlayerKilled);
	}
	else
	{
		DisableHamForward(g_hThinkCamera);
		DisableHamForward(g_hPlayerKilled);
	}
}


//Строит сцену из игроков
//const Float:vecStartOrigin[3], 
//const Float:vecStartAngles[3] - позиция и угл камеры первого игрока
//iUser - массив с топ игроками
//iCount - количество игроков в топе
stock BuildScene(const Float:vecStartOrigin[3], const Float:vecStartAngles[3], const iUsers[], const iCount)
{
	//Угл преобразованный в вектор (направление)
	//new Float:vecDir[3]; angle_vector(vecStartAngles, ANGLEVECTOR_FORWARD, vecDir);
	//Делаем направление в противоположную сторону
	//xs_vec_neg(vecDir, vecDir);

	new Float:vecPositionOrigin[3];
	new Float:vecPointRotate[3];
	new Float:vecUserStayPos[3]; xs_vec_copy(vecStartOrigin, vecUserStayPos); vecUserStayPos[2] -= 17.0;

	for(new i; i < iCount; i++)
	{
		// zp_user_instant_model(iUsers[i]);

		point_rotate(g_vecTopPositions[i], vecStartAngles[1], vecPointRotate)
		xs_vec_copy(vecPointRotate, vecPositionOrigin)
		xs_vec_add(vecPositionOrigin, vecUserStayPos, vecPositionOrigin);

		engfunc(EngFunc_SetOrigin, iUsers[i], vecPositionOrigin);

		set_entvar(iUsers[i], var_v_angle, vecStartAngles)
		set_entvar(iUsers[i], var_angles, vecStartAngles)
		set_entvar(iUsers[i], var_fixangle, 1);

		set_entvar(iUsers[i], var_velocity, Float:{0.0, 0.0, 0.0});

		engfunc(EngFunc_DropToFloor, iUsers[i]);
		//execute_player_emotion(iUsers[i], api_get_user_hand(iUsers[i]) ? g_iEmotionWoman[random(sizeof g_iEmotionWoman)] : g_iEmotionMan[random(sizeof g_iEmotionMan)]);
	}

	//Скрываем игроков, кто не входит в топ
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_connected(iPlayer) || find_int_in_array(iUsers, iCount, iPlayer) != -1)
			continue;

		set_entvar(iPlayer, var_effects, get_entvar(iPlayer, var_effects) | EF_NODRAW);
	}
}

//Отключение камеры
stock DisableCamera()
{
	new iBitViewers = GetBitViewers;
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!IsSetBit(iBitViewers, iPlayer)) continue;
		ViewYourself(iPlayer);
	}

	//Отображаем всех игроков после конца сцены
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_connected(iPlayer))
			continue;

		set_entvar(iPlayer, var_effects, get_entvar(iPlayer, var_effects) & ~EF_NODRAW);
		set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) & ~FL_FROZEN);
	}

	SwitchToggle(false);

	set_entvar(g_iEntCam, var_velocity, Float:{0.0, 0.0, 0.0});
	SetCamState(CAM_DISABLED);
}

//Запуск камеры
//const Float:vecStartOrigin[3]
//const Float:vecStartAngles[3] - позиция и угл камеры первого игрока
//iUser - массив с топ игроками
//iCount - количество игроков в топе
stock CamLaunch(const Float:vecStartOrigin[3], const Float:vecStartAngles[3], const iUsers[], const iCount)
{
	//Угл в вектор
	new Float:vecDir[3]; angle_vector(vecStartAngles, ANGLEVECTOR_FORWARD, vecDir);

	//Конечное положение камеры
	new Float:vecEnd[3];
	vec_add_scaled(vecStartOrigin, vecDir, CAM_END_DISTANCE, vecEnd);

	//Стартовое положение камеры
	new Float:vecStart[3];
	vec_add_scaled(vecStartOrigin, vecDir, CAM_START_DISTANCE, vecStart);

	//Velocity камепы
	new Float:vecVelocity[3]; 
	xs_vec_mul_scalar(vecDir, (CAM_END_DISTANCE - CAM_START_DISTANCE) / CAM_MOVING_TIME, vecVelocity);

	//Угол камеры
	new Float:vecAngles[3], Float:vecNegDir[3];
	xs_vec_neg(vecDir, vecNegDir);
	//vector_to_angle(vecNegDir, vecAngles);
	angle_opposite(vecStartAngles, vecAngles)

	//Установка камеры в нужное положение
	set_entvar(g_iEntCam, var_origin, vecStart);
	set_entvar(g_iEntCam, var_angles, vecAngles);
	//client_print(0, print_chat, "vecStartAngles: %f %f %f | vecAngles: %f %f %f", vecStartAngles[0], vecStartAngles[1], vecStartAngles[2], vecAngles[0], vecAngles[1], vecAngles[2])
	set_entvar(g_iEntCam, var_velocity, vecVelocity);

	new iColor = get_entvar(g_iEntCam, var_cam_color);

	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_alive(iPlayer)) continue;

		ViewCamera(iPlayer);
		
		SCREEN_FADE(iPlayer, CAM_EFFECT_TIME/2, CAM_EFFECT_TIME/2, 0, g_iColorAlpha[iColor]);
		set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) | FL_FROZEN);
	}

	client_cmd(0, "spk ^"%s^"", g_szSound[random(sizeof g_szSound)]);

	new szTopStrings[2][512]; get_string_top_users(iUsers, iCount, szTopStrings, charsmax(szTopStrings[]));

	//set_hudmessage(255, 255, 255, 0.78, 0.2, _, _, CAM_MOVING_TIME + CAM_STATIC_TIME);
	//show_hudmessage(0, szTopString);

	for(new i = 0; i < sizeof szTopStrings; i++)
	{
		if(szTopStrings[i][0] == '^0') continue;

		set_dhudmessage(255, 255, 255, 0.78, 0.2, _, _, TOP5_LIST_TIME);
		show_dhudmessage(0, szTopStrings[i]);

	}
}

public HM__CamThink_Post(iEnt)
{
	if(get_entvar(iEnt, var_impulse) != CAMERA_IMPULSE)
		return;

	static iTopPlayers[32], iCount

	switch(GetCamState)
	{
		case CAM_EFFECT:
		{
			new Float:vecStartOrigin[3], Float:vecStartAngles[3];

			GetArrayUsers(iTopPlayers, sizeof g_vecTopPositions, iCount);

			get_entvar(iEnt, var_cam_pos, vecStartOrigin);
			get_entvar(iEnt, var_cam_angles, vecStartAngles);

			BuildScene(vecStartOrigin, vecStartAngles, iTopPlayers, iCount);
			CamLaunch(vecStartOrigin, vecStartAngles, iTopPlayers, iCount);

			SetCamState(CAM_EMOTION);

			set_entvar(iEnt, var_nextthink, get_gametime() + CAM_EMOTION_DELAY);
		}
		case CAM_EMOTION:
		{
			// for(new i; i < iCount; i++)
			// {
			// 	if(!is_user_alive(iTopPlayers[i])) continue;

			// 	if(i == 0)
			// 		execute_player_emotion(iTopPlayers[i], api_get_user_hand(iTopPlayers[i]) ? g_iEmotionWomanTop1[random(sizeof g_iEmotionWomanTop1)] : g_iEmotionManTop1[random(sizeof g_iEmotionManTop1)]);
			// 	else
			// 		execute_player_emotion(iTopPlayers[i], api_get_user_hand(iTopPlayers[i]) ? g_iEmotionWoman[random(sizeof g_iEmotionWoman)] : g_iEmotionMan[random(sizeof g_iEmotionMan)]);
			// }

			SetCamState(CAM_MOVING);
			set_entvar(iEnt, var_nextthink, get_gametime() + CAM_MOVING_TIME - CAM_EMOTION_DELAY);
		}
		case CAM_MOVING:
		{
			set_entvar(iEnt, var_velocity, Float:{0.0, 0.0, 0.0});

			for(new i; i < iCount; i++)
			{
				if(!is_user_alive(iTopPlayers[i])) continue;
				
				set_dhudmessage(255, 255, 255, -1.0, 0.17, _, _, CAM_MOVING_TIME);
				show_dhudmessage(iTopPlayers[i], "YOU ARE THE CHAMPIONS!");
			}

			SetCamState(CAM_STATIC);
			set_entvar(iEnt, var_nextthink, get_gametime() + CAM_STATIC_TIME);
		}
		case CAM_STATIC:
		{
			DisableCamera();
		}
	}
}

public HM__PlayerKilled_Pre(iVictim)
	set_entvar(iVictim, var_flags, get_entvar(iVictim, var_flags) & ~FL_FROZEN);

//native bool:native_top5_camera_start()
public bool:native_top5_camera_start()
{
	if(!g_bScene) return false;

	CamPlay(g_vecOrigin, g_vecAngles);
	return true;
}

//native Float:native_get_top5camera_time()
public Float:native_get_top5camera_time()
	return CAM_EFFECT_TIME/2.0 + CAM_MOVING_TIME + CAM_STATIC_TIME;

//native CamState:get_top5camera_state()
public CamState:native_get_top5camera_state()
	return is_nullent(g_iEntCam) ? CAM_DISABLED : GetCamState;

//Противоположный угол
stock angle_opposite(const Float:vecAngles[3], Float:vecRet[3])
{
	vecRet[0] = -vecAngles[0];
	vecRet[1] = vecAngles[1] + 180.0;
	vecRet[2] = vecAngles[2];
}

//Поворот точки на flAngles градусов в 2d пространстве
stock point_rotate(const Float:vecOrigin[], const Float:flAngle, Float:vecRet[])
{
	vecRet[0] = vecOrigin[0] * xs_cos(flAngle, degrees) - vecOrigin[1] * xs_sin(flAngle, degrees);
	vecRet[1] = vecOrigin[0] * xs_sin(flAngle, degrees) + vecOrigin[1] * xs_cos(flAngle, degrees);
	vecRet[2] = vecOrigin[2];
}

/**
 * Получает массив топ-игроков
 * iUsers[] - массив, куда заполняются id игроков
 * iNesCount - необходимое количество
 * iTotal - всего помещенных в массив
*/
stock GetArrayUsers(iUsers[], const iNesCount, &iTotal)
{
	//Массив игроков с фрагами и количество живых	
	new iUsers2D[32][e_UserStats], iCountConnected;

	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_connected(iPlayer)) continue;

		iUsers2D[iCountConnected][e_iUserId] = iPlayer;
		iUsers2D[iCountConnected][e_iUserFrags] = Float:get_entvar(iPlayer, var_frags)
		iUsers2D[iCountConnected][e_iUserDeath] = get_user_deaths(iPlayer);

		//client_print(0, print_console, "Death: %d", iUsers2D[iCountConnected][e_iUserDeath]);

		iCountConnected++;
	}

	SortCustom2D(iUsers2D, iCountConnected, "CompareUsers");

	iTotal = min(iNesCount, iCountConnected);

	for(new i; i < iTotal; i++)
		iUsers[i] = iUsers2D[i][e_iUserId];

}

//Функция сортировки массива игроков с фрагами
public CompareUsers(const iElem1[], const iElem2[])
{
	if(iElem1[e_iUserFrags] > iElem2[e_iUserFrags])
		return -1;

	if(iElem1[e_iUserFrags] < iElem2[e_iUserFrags])
		return 1;

	if(iElem1[e_iUserDeath] > iElem2[e_iUserDeath])
		return 1;

	if(iElem1[e_iUserDeath] < iElem2[e_iUserDeath])
		return -1;

	return 0;
}

//Умножение каждой компоненты вектора на вторую
stock vec_mul_vec(const Float:vecIn1[], const Float:vecIn2[], Float:vecOut[])
{
	vecOut[0] = vecIn1[0] * vecIn2[0];
	vecOut[1] = vecIn1[1] * vecIn2[1];
	vecOut[2] = vecIn1[2] * vecIn2[2];
}

stock vec_add_scaled(const Float:in1[], const Float:in2[], Float:scalar, Float:out[])
{
	out[0] = in1[0] + in2[0] * scalar;
	out[1] = in1[1] + in2[1] * scalar;
	out[2] = in1[2] + in2[2] * scalar;
}

/*
	Получение строки TOP-5 игроков
	iUsers[]		Массив с player-id
	iCount 			Количество игроков в массиве
	szOutStrs		Выходная отформатированная строка
	iStrLen 			Длина строки
*/
stock get_string_top_users(const iUsers[], const iCount, szOutStrs[][], const iStrLen)
{
	new iLenFirst = formatex(szOutStrs[0], iStrLen, "TOP5 за карту:^n");
	new szName[32], iFirstPath = min(iCount, 3);

	for(new i; i < iFirstPath; i++)
	{
		get_user_name(iUsers[i], szName, charsmax(szName));
		iLenFirst += formatex(szOutStrs[0][iLenFirst], iStrLen - iLenFirst, "%s %.0f уб.^n", szName, Float:get_entvar(iUsers[i], var_frags));
	}

	if(iCount <= iFirstPath) return;

	new iLenSecond = 0;

	for(new i = 0; i < iFirstPath + 1; i++)
		iLenSecond += formatex(szOutStrs[1][iLenSecond], iStrLen - iLenSecond, "^n");

	for(new i = iFirstPath; i < iCount; i++)
	{
		get_user_name(iUsers[i], szName, charsmax(szName));
		iLenSecond += formatex(szOutStrs[1][iLenSecond], iStrLen - iLenSecond, "%s %.0f уб.^n", szName, Float:get_entvar(iUsers[i], var_frags));
	}
}

/*
	Находит число в массиве
	array - массив
	size - размер
	iValue - число, которое необходимо найти
	ret индекс массива или -1, если число не найдено
*/
stock find_int_in_array(const array[], size, iValue)
{
	for(new i; i < size; i++)
	{
		if(array[i] == iValue)
			return i;
	}
	return -1;
}

#define UNIT_SECOND 4096.0

stock SCREEN_FADE(id, Float:flDuration, Float:flHoldtime, iFadeType, iColorAlpha[4])
{
	static iMsg_ScreenFade; if(!iMsg_ScreenFade) iMsg_ScreenFade = get_user_msgid("ScreenFade");

	new iDuration = floatround(UNIT_SECOND * flDuration),
		iHoldtime = floatround(UNIT_SECOND * flHoldtime);

	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iMsg_ScreenFade, _, id)
	write_short(iDuration) // duration
	write_short(iHoldtime) // hold time
	write_short(iFadeType) // fade type
	write_byte(iColorAlpha[0]) // r
	write_byte(iColorAlpha[1]) // g
	write_byte(iColorAlpha[2]) // b
	write_byte(iColorAlpha[3]) // alpha
	message_end()
}

stock SetBlockAttackTime(const pPlayer, Float:flBlockTime, pItem = 0)
{
	set_member(pPlayer, m_flNextAttack, flBlockTime);

	if(is_nullent(pItem) && is_nullent( (pItem = get_member(pPlayer, m_pActiveItem)) )) 
		return;

	set_member(pItem, m_Weapon_flNextPrimaryAttack, flBlockTime);
	set_member(pItem, m_Weapon_flNextSecondaryAttack, flBlockTime);
}