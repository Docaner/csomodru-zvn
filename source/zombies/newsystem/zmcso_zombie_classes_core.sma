#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <zombieplague>
#include <json>
#include <api_identifier>
#include <api_maxspeed>
#include <zc_addon_zclasses>

/**
 * Директория, где хранится вся информация о классах зомби
 */
new const g_szDirectoryClass[] = "addons/amxmodx/configs/zpe_mode/zombie_classes"

new Trie:g_tiClass_ShortName;								// key: ShortName - value: cell:iClassId

new Array:g_asClass_Name,									// char[32] - Название класса 
	Array:g_asClass_Info,									// char[128] - Описание класса
	Array:g_asClass_PlayerModel,							// char[32] - Модель зомби-класса
	Array:g_aiClass_PlayerModelIndex,						// int - МоделИндекс модели
	Array:g_asClass_Hands,									// char[32] - Модель рук зомби
	Array:g_afClass_Health,									// Float - начальное здоровье зомби
	Array:g_afClass_MaxHealth,								// Float - максимальное здоровье зомби
	Array:g_afClass_Speed, 									// Float - скорость
	Array:g_afClass_Gravity,								// Float - гравитация
	Array:g_aiClass_Sounds[sizeof g_szField_Sounds][2]; 	// int - стартовый и конечный индекс звуков

new Array:g_asList_Sounds; 									// char[64] - Список звуков

new g_fwReadZClass;

#define TASK_IDLE 545454

public plugin_natives()
{
	register_native("zc_find_zclass_by_shortname", 	"@zc_find_zclass_by_shortname", 	false);
	register_native("zc_get_zclasses_count", 		"@zc_get_zclasses_count", 			true);
	register_native("zc_get_zclass_name", 			"@zc_get_zclass_name", 				false);
	register_native("zc_get_zclass_info", 			"@zc_get_zclass_info", 				false);
	register_native("zc_get_zclass_playermodel", 	"@zc_get_zclass_playermodel", 		true);
	register_native("zc_get_zclass_modelindex", 	"@zc_get_zclass_modelindex", 		true);
	register_native("zc_get_zclass_hands", 			"@zc_get_zclass_hands", 			false);
	register_native("zc_get_zclass_health", 		"@zc_get_zclass_health", 			true);
	register_native("zc_get_zclass_maxhealth", 		"@zc_get_zclass_maxhealth", 		true);
	register_native("zc_get_zclass_speed", 			"@zc_get_zclass_speed", 			true);
	register_native("zc_get_zclass_gravity", 		"@zc_get_zclass_gravity", 			true);
	register_native("zc_get_zclass_sound", 			"@zc_get_zclass_sound", 			false);
}

public plugin_precache()
{
	register_plugin("[ZMCSO] Zombie Classes Core", "1.0", "Docaner");

	Alloc__Make();
	
	g_fwReadZClass = CreateMultiForward("zc_read_zclass", ET_IGNORE, FP_CELL);

	Directory__ReadClasses();
}

public plugin_init()
{
	RegisterHookChain(RG_CSGameRules_RestartRound, "@RG__RestartRound_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "@RG__Player_Killed_Post", true);
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "@RG__Player_Deploy_Pre", false);
	register_forward(FM_EmitSound, "@Meta__EmitSound_Pre", false);

	//forward zc_read_zclass(const JSON:jHandle);
}

public plugin_end()
{
	Alloc__Free();
}

public client_disconnected(id, bool:drop, message[], maxlen)
	remove_task(id+TASK_IDLE);

public zp_user_infected_post(id, infector, nemesis)
{
	new iClass = get_user_property(id, Field_User_Class);

	new szModel[ZMClassModelLen]; ArrayGetString(g_asClass_PlayerModel, iClass, szModel, charsmax(szModel));
	zp_override_user_model(id, szModel, 1);

	set_entvar(id, var_health, Float:ArrayGetCell(g_afClass_Health, iClass));
	set_entvar(id, var_max_health, Float:ArrayGetCell(g_afClass_MaxHealth, iClass));
	rg_set_user_maxspeed(id, Float:ArrayGetCell(g_afClass_Speed, iClass));
	set_entvar(id, var_gravity, Float:ArrayGetCell(g_afClass_Gravity, iClass));

	new szSound[ZMListSoundLen]; 

	if(zc_get_zombie_sound(iClass, ZMSoundType:e_SoundInfect, szSound, charsmax(szSound)))
		rh_emit_sound2(id, 0, CHAN_VOICE, szSound);

	if(zc_get_zombie_sound(iClass, ZMSoundType:e_SoundInfectAdvanced, szSound, charsmax(szSound)))
		rh_emit_sound2(id, 0, CHAN_AUTO, szSound);

	set_task(random_float(50.0, 70.0), "@Task__ClassIdleSound", id+TASK_IDLE, _, _, "b");
}

@Task__ClassIdleSound(pPlayer)
{
	pPlayer -= TASK_IDLE;

	new szSound[ZMListSoundLen]; 
	if(zc_get_zombie_sound(get_user_property(pPlayer, Field_User_Class), ZMSoundType:e_SoundIdle, szSound, charsmax(szSound)))
		rh_emit_sound2(pPlayer, 0, CHAN_VOICE, szSound);
}

public zp_user_humanized_pre(id, survivor)
	remove_task(id+TASK_IDLE);

@RG__RestartRound_Post()
{
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		remove_task(iPlayer+TASK_IDLE);
}

@RG__Player_Killed_Post(const pVictim)
	remove_task(pVictim+TASK_IDLE);

@RG__Player_Deploy_Pre(const pItem, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal)
{
	if(get_member(pItem, m_iId) != WEAPON_KNIFE)
		return;

	new pPlayer = get_member(pItem, m_pPlayer);

	if(!zp_get_user_zombie(pPlayer))
		return;

	new iClass = get_user_property(pPlayer, Field_User_Class);

	new szHands[ZMClassHandsLen]; ArrayGetString(g_asClass_Hands, iClass, szHands, charsmax(szHands)) 

	SetHookChainArg(2, ATYPE_STRING, szHands);
	SetHookChainArg(3, ATYPE_STRING, "");
}

@Meta__EmitSound_Pre(const pEntity, const iChannel, const szSample[ ], const Float:flVolume, const Float:flAttenuation, const bitsFlags, const iPitch)
{
	if(!is_user_connected(pEntity) || !zp_get_user_zombie(pEntity))
		return FMRES_IGNORED;

	new szSound[ZMListSoundLen];

	if(!contain(szSample, "player"))
	{
		//player/bhit
		if(!contain(szSample[7], "bhit"))
			zc_get_zombie_sound(zp_get_user_zombie_class(pEntity), ZMSoundType:e_SoundPain, szSound, charsmax(szSound));
		//player/die | player/death
		else if(!contain(szSample[7], "die") || !contain(szSample[7], "death"))
			zc_get_zombie_sound(zp_get_user_zombie_class(pEntity), ZMSoundType:e_SoundDie, szSound, charsmax(szSound));
	}
	else if(!contain(szSample, "weapons/knife"))
	{
		//weapons/knife_slash
		if(!contain(szSample[14], "slash"))
			zc_get_zombie_sound(zp_get_user_zombie_class(pEntity), ZMSoundType:e_SoundMissSlash, szSound, charsmax(szSound));
		else if(!contain(szSample[14], "hit"))
		{
			//weapons/knife_hitwall
			if(!contain(szSample[17], "wall"))
				zc_get_zombie_sound(zp_get_user_zombie_class(pEntity), ZMSoundType:e_SoundMissWall, szSound, charsmax(szSound));
			else
			//weapons/knife_hit
				zc_get_zombie_sound(zp_get_user_zombie_class(pEntity), ZMSoundType:e_SoundHitNormal, szSound, charsmax(szSound));
		}
		//weapons/knife_stab
		else if(!contain(szSample[14], "stab"))
			zc_get_zombie_sound(zp_get_user_zombie_class(pEntity), ZMSoundType:e_SoundHitNormal, szSound, charsmax(szSound));
	}

	if(szSound[0] != 0)
	{
		//emit_sound(pEntity, iChannel, szSound, flVolume, flAttenuation, bitsFlags, iPitch)
		rh_emit_sound2(pEntity, 0, iChannel, szSound, flVolume, flAttenuation, bitsFlags, iPitch);
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}


//==============================>
// Natives
//==============================>

//native zc_find_zclass_by_shortname(const szShorName[]);
@zc_find_zclass_by_shortname(const iPlugin, const iParamsCount)
{
	enum{Arg_szShortName = 1}

	new szShortName[ZMClassShortLen]; get_string(Arg_szShortName, szShortName, charsmax(szShortName));

	console_print(0, "szShortName: %s", szShortName);
	if(!TrieKeyExists(g_tiClass_ShortName, szShortName))
		return ZMNullClass;

	new iValue; TrieGetCell(g_tiClass_ShortName, szShortName, iValue);

	console_print(0, "iValue: %d", iValue);
	return iValue;
}

//native zc_get_zclasses_count();
@zc_get_zclasses_count()
	return ArraySize(g_asClass_Name);

//native zc_get_zclass_name(const iClass, szName[], const iLen);
@zc_get_zclass_name(const iPlugin, const iParamsCount)
{
	enum {Arg_iClass = 1, Arg_szName, Arg_iLen}

	new iClass = get_param(Arg_iClass),
		iLen = get_param(Arg_iLen);

	new szName[ZMClassNameLen]; ArrayGetString(g_asClass_Name, iClass, szName, charsmax(szName));

	set_string(Arg_szName, szName, iLen);
}

//native zc_get_zclass_info(const iClass, szInfo[], const iLen);
@zc_get_zclass_info(const iPlugin, const iParamsCount)
{
	enum {Arg_iClass = 1, Arg_szInfo, Arg_iLen}

	new iClass = get_param(Arg_iClass),
		iLen = get_param(Arg_iLen);

	new szInfo[ZMClassInfoLen]; ArrayGetString(g_asClass_Info, iClass, szInfo, charsmax(szInfo));

	set_string(Arg_szInfo, szInfo, iLen);
}

//native zc_get_zclass_playermodel(const iClass, szModel[], const iLen);
@zc_get_zclass_playermodel(const iPlugin, const iParamsCount)
{
	enum {Arg_iClass = 1, Arg_szModel, Arg_iLen}

	new iClass = get_param(Arg_iClass),
		iLen = get_param(Arg_iLen);

	new szModel[ZMClassModelLen]; ArrayGetString(g_asClass_PlayerModel, iClass, szModel, charsmax(szModel));

	set_string(Arg_szModel, szModel, iLen);
}


//native zc_get_zclass_modelindex(const iClass);
@zc_get_zclass_modelindex(const iClass)
	return ArrayGetCell(g_aiClass_PlayerModelIndex, iClass);

//native zc_get_zclass_hands(const iClass, szHands[], const iLen);
@zc_get_zclass_hands(const iPlugin, const iParamsCount)
{
	enum {Arg_iClass = 1, Arg_szHands, Arg_iLen}

	new iClass = get_param(Arg_iClass),
		iLen = get_param(Arg_iLen);

	new szHands[ZMClassModelLen]; ArrayGetString(g_asClass_Hands, iClass, szHands, charsmax(szHands));

	set_string(Arg_szHands, szHands, iLen);
}

//native Float:zc_get_zclass_health(const iClass);
Float:@zc_get_zclass_health(const iClass)
	return ArrayGetCell(g_afClass_Health, iClass);

//native Float:zc_get_zclass_maxhealth(const iClass);
Float:@zc_get_zclass_maxhealth(const iClass)
	return ArrayGetCell(g_afClass_MaxHealth, iClass);

//native Float:zc_get_zclass_speed(const iClass);
Float:@zc_get_zclass_speed(const iClass)
	return ArrayGetCell(g_afClass_Speed, iClass);

//native Float:zc_get_zclass_gravity(const iClass);
Float:@zc_get_zclass_gravity(const iClass)
	return ArrayGetCell(g_afClass_Gravity, iClass);

//native bool:zc_get_zclass_sound(const iClass, const ZMSoundType:iSoundType, szSound[], const iLen);
bool:@zc_get_zclass_sound(const iPlugin, const iParamsCount)
{
	enum {Arg_iClass = 1, Arg_iSoundType, Arg_szSound, Arg_iLen}

	new iClass = get_param(Arg_iClass),
		ZMSoundType:iSoundType = ZMSoundType:get_param(Arg_iSoundType),
		szSound[ZMListSoundLen],
		iLen = get_param(Arg_iLen);

	if(!zc_get_zombie_sound(iClass, iSoundType, szSound, charsmax(szSound)))
		return false;

	set_string(Arg_szSound, szSound, iLen);
	return true;
}

//<==============================
// Natives
//<==============================

/**
 * Получение звука по типу
 */
stock bool:zc_get_zombie_sound(const iClass, const ZMSoundType:iSoundType, szSound[], const iLen)
{
	new iStart; 

	if( (iStart = ArrayGetCell(g_aiClass_Sounds[cell:iSoundType][0], iClass)) == ZMNullIndexSound )
		return false;

	new	iEnd = ArrayGetCell(g_aiClass_Sounds[cell:iSoundType][1], iClass),
		iRandom = random_num(iStart, iEnd);

	ArrayGetString(g_asList_Sounds, iRandom, szSound, iLen);
	return true;
}

/**
 * Десериализация JSON-файлов из определенной директории в зомби-классы
 */
stock Directory__ReadClasses()
{
	if(!dir_exists(g_szDirectoryClass))
		return;

	new iDir, FileType:iType, szDir[sizeof g_szDirectoryClass], szFile[64];

	copy(szDir, charsmax(szDir), g_szDirectoryClass);

	if( !(iDir = open_dir(szDir, szFile, charsmax(szFile), iType)) )
		return;

	new Array:aFiles = ArrayCreate(sizeof szFile);

	do
	{
		if(iType != FileType_File)
			continue;

		ArrayPushString(aFiles, szFile);
	} 
	while(next_file(iDir, szFile, charsmax(szFile), iType))

	close_dir(iDir);	

	ArraySort(aFiles, "@Array__FilesCompare");

	new szFullPath[128];

	for(new i, iSize = ArraySize(aFiles); i < iSize; i++)
	{
		ArrayGetString(aFiles, i, szFile, charsmax(szFile));

		formatex(szFullPath, charsmax(szFullPath), "%s/%s", szDir, szFile);

		if(Json__DeserializeClass(szFullPath) == ZMNullClass)
			log_amx("Не удалось прочесть файл ^"%s^"", szFullPath);
	}

	ArrayDestroy(aFiles);
}

@Array__FilesCompare(Array:aArray, iItem1, iItem2)
{
	new szFile1[64]; ArrayGetString(aArray, iItem1, szFile1, charsmax(szFile1));
	new szFile2[64]; ArrayGetString(aArray, iItem2, szFile2, charsmax(szFile2));

	return strcmp(szFile1, szFile2);
} 	

/**
 * Десериализация JSON отдельного файла в зомби-класс
 */
stock Json__DeserializeClass(const szPath[])
{
	new JSON:jHandle = json_parse(szPath, true, true);

	if(jHandle == Invalid_JSON)
	{
		log_amx("Неверный формат JSON-строки");
		return ZMNullClass;
	}

	new szShortName[ZMClassShortLen]; json_object_get_string(jHandle, Field_ShortName, szShortName, charsmax(szShortName));

	if(TrieKeyExists(g_tiClass_ShortName, szShortName))
	{
		json_free(jHandle);

		log_amx("Зомби-класс с ShortName ^"%s^" уже присутствует", szShortName);
		return ZMNullClass;
	}

	new szName[ZMClassNameLen]; json_object_get_string(jHandle, Field_Name, szName, charsmax(szName));
	new szInfo[ZMClassInfoLen]; json_object_get_string(jHandle, Field_Info, szInfo, charsmax(szInfo));

	new szModel[ZMClassModelLen], szPathModel[128];
	json_object_get_string(jHandle, Field_PlayerModel, szModel, charsmax(szModel));
	formatex(szPathModel, charsmax(szPathModel), "models/player/%s/%s.mdl", szModel, szModel);
	
	if(!try_file_exist(szPathModel)) 
	{
		json_free(jHandle);
		
		log_amx("Player-model ^"%s^" не найдена", szModel);
		return ZMNullClass;
	}

	new szHands[ZMClassHandsLen];
	json_object_get_string(jHandle, Field_Hands, szHands, charsmax(szHands));
	
	if(!try_file_exist(szHands))
	{
		json_free(jHandle);

		log_amx("Hands-model ^"%s^" не найдена", szHands);
		return ZMNullClass;
	}

	new iModelIndex = precache_model(szPathModel);

	precache_model(szHands);

	new Float:flHealth = json_object_get_real(jHandle, Field_Health),
		Float:flMaxHealth = json_object_get_real(jHandle, Field_MaxHealth),
		Float:flSpeed = json_object_get_real(jHandle, Field_Speed),
		Float:flGravity = json_object_get_real(jHandle, Field_Gravity);

	new iClass = ArrayPushString(g_asClass_Name, szName);
	ArrayPushString(g_asClass_Info, szInfo);
	ArrayPushString(g_asClass_PlayerModel, szModel);
	ArrayPushCell(g_aiClass_PlayerModelIndex, iModelIndex);
	ArrayPushString(g_asClass_Hands, szHands);
	ArrayPushCell(g_afClass_Health, flHealth);
	ArrayPushCell(g_afClass_MaxHealth, flMaxHealth);
	ArrayPushCell(g_afClass_Speed, flSpeed);
	ArrayPushCell(g_afClass_Gravity, flGravity);

	TrieSetCell(g_tiClass_ShortName, szShortName, iClass);

	new iStart, iEnd, i, iArraySize, szSound[ZMListSoundLen];

	for(new JSON:jArray, iSound, iSize = sizeof g_szField_Sounds; iSound < iSize; json_free(jArray), iSound++)
	{
		jArray = json_object_get_value(jHandle, g_szField_Sounds[iSound]);

		if(!json_is_array(jArray)) 
		{
			ArrayPushCell(g_aiClass_Sounds[iSound][0], ZMNullIndexSound);
			ArrayPushCell(g_aiClass_Sounds[iSound][1], ZMNullIndexSound);

			continue;
		}

		iStart = ZMNullIndexSound; 
		iEnd = ZMNullIndexSound;

		for(i = 0, iArraySize = json_array_get_count(jArray); i < iArraySize; i++)
		{
			json_array_get_string(jArray, i, szSound, charsmax(szSound));

			if(!try_file_exist(fmt("sound/%s", szSound))) continue;

			precache_sound(szSound);

			iEnd = ArrayPushString(g_asList_Sounds, szSound);
		
			if(iStart == ZMNullIndexSound) iStart = iEnd;
		}

		ArrayPushCell(g_aiClass_Sounds[iSound][0], iStart);
		ArrayPushCell(g_aiClass_Sounds[iSound][1], iEnd);
	}

	ExecuteForward(g_fwReadZClass, _, jHandle);
	
	json_free(jHandle);
	return iClass;
}

/**
 * Выделение памяти
 */
stock Alloc__Make()
{
	g_tiClass_ShortName = TrieCreate();
	
	g_asClass_Name = ArrayCreate(ZMClassNameLen);
	g_asClass_Info = ArrayCreate(ZMClassInfoLen);
	g_asClass_PlayerModel = ArrayCreate(ZMClassModelLen);
	g_aiClass_PlayerModelIndex = ArrayCreate();
	g_asClass_Hands = ArrayCreate(ZMClassHandsLen);
	g_afClass_Health = ArrayCreate();
	g_afClass_MaxHealth = ArrayCreate();
	g_afClass_Speed = ArrayCreate();
	g_afClass_Gravity = ArrayCreate();

	for(new i, iSize = sizeof g_szField_Sounds; i < iSize; i++)
	{
		g_aiClass_Sounds[i][0] = ArrayCreate();
		g_aiClass_Sounds[i][1] = ArrayCreate();
	}
	
	g_asList_Sounds = ArrayCreate(ZMListSoundLen);
}

/**
 * Высвобождение памяти
 */
stock Alloc__Free()
{
	TrieDestroy(g_tiClass_ShortName);

	ArrayDestroy(g_asClass_Name);
	ArrayDestroy(g_asClass_Info);
	ArrayDestroy(g_asClass_PlayerModel);
	ArrayDestroy(g_aiClass_PlayerModelIndex);
	ArrayDestroy(g_asClass_Hands);
	ArrayDestroy(g_afClass_Health);
	ArrayDestroy(g_afClass_MaxHealth);
	ArrayDestroy(g_afClass_Speed);
	ArrayDestroy(g_afClass_Gravity);

	for(new i, iSize = sizeof g_szField_Sounds; i < iSize; i++)
	{
		ArrayDestroy(g_aiClass_Sounds[i][0]);
		ArrayDestroy(g_aiClass_Sounds[i][1]);
	}
		
	ArrayDestroy(g_asList_Sounds);
}

/**
 * Проверка файла на существование
 */
stock bool:try_file_exist(const szFile[], bool:bLog = true)
{
	if(szFile[0] == 0)
	{
		if(bLog) log_amx("Пустая строка");
		return false;
	}

	if(!file_exists(szFile))
	{
		if(bLog) log_amx("Модель не обнаружена ^"%s^"", szFile)
		return false;
	}

	return true;
}