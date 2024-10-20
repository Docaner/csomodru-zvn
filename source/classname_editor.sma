#include <amxmodx>
#include <reapi>
#include <json>
#include <smart_effects>

//========Class Names=========>

//Конфигурационный файл, откуда загружаются класснеймы
new const g_szJSONClassName[] = "addons/amxmodx/configs/zpe_mode/ce_classnames.json"

new Trie:g_tiClassName,         //Получить индекс Array по класснейму
    Array:g_asClassName,        //Название класснейма
    Array:g_asMenuName,         //Название в меню
    Array:g_asModel,            //Путь к модели
    Array:g_afSize,             //Размер бокса
    Array:g_aiSequence,          //Анимация
    Array:g_abLight             //Свет

#define ClassNameSize   32
#define MenuNameSize    32
#define ModelPathSize   128
#define BoxSizeSize     6

#define var_classnames_copy var_iuser1

//<========Class Names=========
//========Spawns=========>

//Файл спавнов
new const g_szJSONSPawns[] = "addons/amxmodx/configs/zpe_mode/ce_spawns.json";

//Флаг, который позволяет открыть меню редактора спавнов
#define ADMIN_OPEN ADMIN_RCON

new g_iClassName, g_iLastEnt = NULLENT, g_iStep;

new const Float:g_fSteps[] = { 1.0, 10.0, 50.0, 100.0 };

//<========Spawns=========

public plugin_precache()
{
    register_plugin("Classname Editor", "1.0", "Docaner");
    JSON_PrecacheClassNames(g_szJSONClassName);
}

public plugin_init()
{
    register_clcmd("open_classname_editor", "@ShowMenu_ClassNameEditor");
    register_menucmd(register_menuid("ShowMenu_ClassNameEditor"),   1023, "@Handle_ClassNameEditor");
    register_menucmd(register_menuid("ShowMenu_LastEntity"),        1023, "@Handle_LastEntity");

    JSON_SpawnsInit(g_szJSONSPawns);
}

public plugin_end()
{
    Alloc_ClassName_Free();
}

@ShowMenu_ClassNameEditor(id)
{
    if(~get_user_flags(id) & ADMIN_OPEN)
        return PLUGIN_HANDLED;

    if(!ArraySize(g_asClassName))
    {
        client_print_color(id, id, "^4[CE] ^1Нет классов для спавна");
        return PLUGIN_HANDLED;
    }

    new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), iLen;

    iLen = formatex(szMenu, charsmax(szMenu), "\yМеню редактора объектов^n^n")

    new szMenuName[ClassNameSize]; ArrayGetString(g_asMenuName, g_iClassName, szMenuName, charsmax(szMenuName));
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \wПоменять класс \y[%s]^n", szMenuName);
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \wСоздать объект^n");
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \wИзменить положение объекта^n");
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \wУдалить последний^n");
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5. \wСохранить спавны^n^n^n^n^n^n");

    formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wВыход");

    return show_menu(id, iKeys, szMenu, _, "@ShowMenu_ClassNameEditor");
}

@Handle_ClassNameEditor(id, iKey)
{
    switch(iKey)
    {
        //Смена класса объекта
        case 0:
        {
            if(++g_iClassName >= ArraySize(g_asClassName))
                g_iClassName = 0;
        }
        //Создание нового объекта
        case 1:
        {
            new Float:vecOrigin[3]; get_entvar(id, var_origin, vecOrigin);
            new Float:vecAngles[3]; get_entvar(id, var_angles, vecAngles);

            g_iLastEnt = ClassName_Spawn(g_iClassName, vecOrigin, vecAngles);
        }
        //Редактировать координаты
        case 2: return ShowMenu_LastEntity(id);
        //Удалить последний объект
        case 3:
        {
            new szClassName[ClassNameSize]; ArrayGetString(g_asClassName, g_iClassName, szClassName, charsmax(szClassName));           
            new pEntLast = Get_LastEntityByClassName(szClassName), iCopyEnt;
            
            if( ( pEntLast = Get_LastEntityByClassName(szClassName) ) != NULLENT)
            {
                iCopyEnt = get_entvar(pEntLast, var_classnames_copy);

                if(!is_nullent(iCopyEnt))
                    rg_remove_ent(iCopyEnt);
                
                rg_remove_ent(pEntLast);

                client_print_color(id, id, "^4[CE] ^1Объект удалён!");
            }    
            else client_print_color(id, id, "^4[CE] ^1Объектов данного класса ^3НЕТ^1!");
        }
        //Сохранение
        case 4:
        {
            if(JSON_SerializeSpawns(g_szJSONSPawns))
                client_print_color(id, id, "^4[CE] ^1Изменения успешно ^4сохранены^1!");
            else
                client_print_color(id, id, "^4[CE] ^1Во время сохранения возникла ^3ОШИБКА^1. Ничего не сохранено^1!");

        }
        case 9: return PLUGIN_HANDLED;
    }
    return @ShowMenu_ClassNameEditor(id);
}

stock ShowMenu_LastEntity(id)
{
    if(~get_user_flags(id) & ADMIN_OPEN)
        return PLUGIN_HANDLED;

    if(!get_valid_prop(g_iLastEnt))
    {
        client_print_color(id, id, "^4[CE] ^1Объект текущего класса не найден");
        return @ShowMenu_ClassNameEditor(id);
    }

    new szMenu[512], iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9), iLen;

    iLen = formatex(szMenu, charsmax(szMenu), "\yПоложение объекта \w[%d]^n^n", g_iLastEnt);

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \wШаг изменения \y[%.2f]^n^n", g_fSteps[g_iStep]);

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \wX += \y%.2f^n", g_fSteps[g_iStep]);
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \wX -= \y%.2f^n^n", g_fSteps[g_iStep]);
    
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \wY += \y%.2f^n", g_fSteps[g_iStep]);
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5. \wY -= \y%.2f^n^n", g_fSteps[g_iStep]);
    
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6. \wZ += \y%.2f^n", g_fSteps[g_iStep]);
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r7. \wZ -= \y%.2f^n^n", g_fSteps[g_iStep]);

    formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wНазад");

    return show_menu(id, iKeys, szMenu, _, "ShowMenu_LastEntity");
}

@Handle_LastEntity(id, iKey)
{
    if(is_nullent(g_iLastEnt))
        return ShowMenu_LastEntity(id);

    switch(iKey)
    {
        case 0:
        {
            if(++g_iStep >= sizeof g_fSteps)
                g_iStep = 0;
        }

        case 9:
            return @ShowMenu_ClassNameEditor(id);

        default:
        {
            new Float:vecOrigin[3]; get_entvar(g_iLastEnt, var_origin, vecOrigin);

            switch(iKey)
            {
                case 1: vecOrigin[0] += g_fSteps[g_iStep];
                case 2: vecOrigin[0] -= g_fSteps[g_iStep];

                case 3: vecOrigin[1] += g_fSteps[g_iStep];
                case 4: vecOrigin[1] -= g_fSteps[g_iStep];
                
                case 5: vecOrigin[2] += g_fSteps[g_iStep];
                case 6: vecOrigin[2] -= g_fSteps[g_iStep];
            }

            engfunc(EngFunc_SetOrigin, g_iLastEnt, vecOrigin);

            new iCopyEnt = get_entvar(g_iLastEnt, var_classnames_copy);

            if(!is_nullent(iCopyEnt))
                engfunc(EngFunc_SetOrigin, iCopyEnt, vecOrigin);
        }
    }

    return ShowMenu_LastEntity(id)
}

//Получает валидный последний объект выбранного класса
stock get_valid_prop(&iEnt)
{
    new szClassName[ClassNameSize]; ArrayGetString(g_asClassName, g_iClassName, szClassName, charsmax(szClassName));

    if(is_nullent(iEnt) || !FClassnameIs(iEnt, szClassName))
        iEnt = Get_LastEntityByClassName(szClassName);

    return !is_nullent(iEnt);
}

//Получить последний entity
stock Get_LastEntityByClassName(const szClassName[])
{
    new pEnt = MaxClients, pEntLast = NULLENT;

    while( ( pEnt = rg_find_ent_by_class(pEnt, szClassName) ) > 0 ) 
        pEntLast = pEnt;
    
    return pEntLast;
}

//Кеширует класснеймы
stock bool:JSON_PrecacheClassNames(const szPath[])
{
    if(!file_exists(szPath))
    {
        set_fail_state("Файл класснеймов не найден ^"%s^"", szPath);
        return false;
    }

    new JSON:jHandle;

    if( ( jHandle = json_parse(szPath, true, true) ) == Invalid_JSON)
    {
        set_fail_state("Неверный формат JSON-строки ^"%s^"", szPath);
        return false;
    }

    Alloc_ClassName_Make();

    new JSON:jClassNames =  json_object_get_value(jHandle, "classnames"),
        iCount = json_object_get_count(jClassNames);

    new szClassName[ClassNameSize];

    new JSON:jIter;

    //console_print(0, "iCount: %d", iCount);

    for(new i = 0; i < iCount; i++)
    {
        json_object_get_name(jClassNames, i, szClassName, charsmax(szClassName));
        
        if(!szClassName[0]) continue;

        if(TrieKeyExists(g_tiClassName, szClassName))
        {
            log_amx("ClassName [%s] уже занесен в систему", szClassName);
            continue;
        }

        jIter = json_object_get_value(jClassNames, szClassName);

        JSON_ClassName_Append(jIter, szClassName);

        json_free(jIter);
    }

    json_free(jHandle);
    
    return true;
}

stock JSON_ClassName_Append(const JSON:jObj, const szClassName[])
{
    new szMenuName[MenuNameSize]; json_object_get_string(jObj, "menu", szMenuName, charsmax(szMenuName));

    new szModel[ModelPathSize]; json_object_get_string(jObj, "model", szModel, charsmax(szModel));

    if(!file_exists(szModel))
    {
        log_amx("Модель ^"%s^" не найдена. ClassName [%s] пропущен", szModel, szClassName);
        return false;
    }

    precache_model(szModel);

    new Float:flBoxSize[BoxSizeSize]; JSON_ObjectGetFloatArray(jObj, "boxsize", flBoxSize, sizeof flBoxSize);

    new iSequence = json_object_get_number(jObj, "sequence");

    new bool:bLight = json_object_get_bool(jObj, "light");

    new iArrayIndex = ArrayPushString(g_asClassName, szClassName);
    ArrayPushString(g_asMenuName, szMenuName);
    ArrayPushString(g_asModel, szModel);
    ArrayPushArray(g_afSize, flBoxSize);
    ArrayPushCell(g_aiSequence, iSequence);
    ArrayPushCell(g_abLight, bLight);

    TrieSetCell(g_tiClassName, szClassName, iArrayIndex);

    return true;
}

/*
    Получить массив float
*/
stock JSON_ObjectGetFloatArray(const JSON:jObj, const szField[], any:aArray[], iArraySize)
{
    new JSON:jArray = json_object_get_value(jObj, szField);

    for(new i, iSize = json_array_get_count(jArray); i < iSize && i < iArraySize; i++)
        aArray[i] = json_array_get_real(jArray, i);

    json_free(jArray);
}

//Создает спавны из JSON
stock bool:JSON_SpawnsInit(const szPath[])
{
    if(!file_exists(szPath))
        return false;

    new JSON:jHandle;

    if( ( jHandle = json_parse(szPath, true, true) ) == Invalid_JSON)
    {
        log_amx("Неверный формат JSON-строки ^"%s^"", szPath);
        return false;
    }


    if(!json_object_has_value(jHandle, "maps"))
    {
        json_free(jHandle);
        return false;
    }

    new JSON:jMaps = json_object_get_value(jHandle, "maps");
    new szMap[32]; rh_get_mapname(szMap, charsmax(szMap));

    if(!json_object_has_value(jMaps, szMap))
    {
        json_free(jHandle);
        json_free(jMaps);
        return false;
    }

    new JSON:jArray = json_object_get_value(jMaps, szMap),
        iSize = json_array_get_count(jArray);

    for(new i, JSON:jIter; i < iSize; i++)
    {
        jIter = json_array_get_value(jArray, i);

        JSON_Spawn_Add(jIter);
        
        json_free(jIter);
    }

    json_free(jHandle);
    json_free(jMaps);
    json_free(jArray);

    return true;
}


/*
    По JSON-объекту создает entity
*/
stock bool:JSON_Spawn_Add(JSON:jObj)
{
    new szClassName[ClassNameSize]; json_object_get_string(jObj, "classname", szClassName, charsmax(szClassName));

    if(!TrieKeyExists(g_tiClassName, szClassName))
    {
        log_amx("ClassName [%s] не обноружен. Спавн пропущен", szClassName);
        return false;
    }

    new iClassName; TrieGetCell(g_tiClassName, szClassName, iClassName);
    new Float:vecPoint[3]; JSON_ObjectGetFloatArray(jObj, "point", vecPoint, sizeof vecPoint);
    new Float:vecAngles[3]; JSON_ObjectGetFloatArray(jObj, "angles", vecAngles, sizeof vecAngles);

    return ClassName_Spawn(iClassName, vecPoint, vecAngles) != NULLENT;
}

/*
    Создание entity
*/
stock ClassName_Spawn(const iClassName, const Float:vecOrigin[3], const Float:vecAngles[3])
{
    new pEnt = rg_create_entity("info_target");

    if(is_nullent(pEnt)) return NULLENT;

    new szClassName[ClassNameSize]; ArrayGetString(g_asClassName, iClassName, szClassName, charsmax(szClassName));
    set_entvar(pEnt, var_classname, szClassName);

    set_entvar(pEnt, var_angles, vecAngles);

    set_entvar(pEnt, var_solid, SOLID_TRIGGER);

    new szModel[ModelPathSize]; ArrayGetString(g_asModel, iClassName, szModel, charsmax(szModel));
    engfunc(EngFunc_SetModel, pEnt, szModel);
	
    engfunc(EngFunc_SetOrigin, pEnt, vecOrigin);
    
    new vecSize[BoxSizeSize]; ArrayGetArray(g_afSize, iClassName, vecSize);
    engfunc(EngFunc_SetSize, pEnt, vecSize[0], vecSize[3]);

    UTIL_SetEntityAnim(pEnt, ArrayGetCell(g_aiSequence, iClassName));

    set_entvar(pEnt, var_classnames_copy, ArrayGetCell(g_abLight, iClassName) ? ClassName_Copy(pEnt) : NULLENT);

    return pEnt;
}

//Копитует энтити для свечения
stock ClassName_Copy(const pEntMain)
{
    new pEnt = rg_create_entity("info_target");

    if(is_nullent(pEnt)) return NULLENT;

    new Float:vecAngles[3]; get_entvar(pEntMain, var_angles, vecAngles);
    set_entvar(pEnt, var_angles, vecAngles);

    set_entvar(pEnt, var_solid, SOLID_TRIGGER);

    new szModel[ModelPathSize]; get_entvar(pEntMain, var_model, szModel, charsmax(szModel));
    engfunc(EngFunc_SetModel, pEnt, szModel);
	
    new Float:vecOrigin[3]; get_entvar(pEntMain, var_origin, vecOrigin);
    engfunc(EngFunc_SetOrigin, pEnt, vecOrigin);
    
    new vecSize[BoxSizeSize]; 
    get_entvar(pEntMain, var_mins, vecSize[0]);
    get_entvar(pEntMain, var_maxs, vecSize[3]);
    engfunc(EngFunc_SetSize, pEnt, vecSize[0], vecSize[3]);

    UTIL_SetEntityAnim(pEnt, get_entvar(pEntMain, var_sequence));

    UTIL_SetRendering(pEnt, .iRender=kRenderTransAdd, .flAmount=100.0);
    
    return pEnt;
}

stock bool:JSON_SerializeSpawns(const szPath[])
{
    new JSON:jFile;
    
    if(!file_exists(szPath))
        jFile = json_init_object();
    else if( ( jFile = json_parse(szPath, true, true) ) == Invalid_JSON )
    {
        log_amx("Неверный формат JSON-строки ^"%s^"", szPath);
        return false;
    }

    new JSON:jArray = json_init_array();
    
    new szClassName[ClassNameSize], pEnt;
    
    new JSON:jObject, JSON:jVecArray;
    new Float:vecOrigin[3], Float:vecAngles[3];

    for(new i, iSize = ArraySize(g_asClassName); i < iSize; i++)
    {
        ArrayGetString(g_asClassName, i, szClassName, charsmax(szClassName));
        
        pEnt = MaxClients;
        while( ( pEnt = rg_find_ent_by_class(pEnt, szClassName) ) > 0 ) 
        {
            jObject = json_init_object();

            json_object_set_string(jObject, "classname", szClassName);

            jVecArray = json_init_array();
            
            get_entvar(pEnt, var_origin, vecOrigin);

            for(new j; j < sizeof vecOrigin; j++)
                json_array_append_real(jVecArray, vecOrigin[j]);

            json_object_set_value(jObject, "point", jVecArray);

            json_free(jVecArray);

            jVecArray = json_init_array();

            get_entvar(pEnt, var_angles, vecAngles);
            
            for(new j; j < sizeof vecAngles; j++)
                json_array_append_real(jVecArray, vecAngles[j]);

            json_object_set_value(jObject, "angles", jVecArray);

            json_free(jVecArray);

            json_array_append_value(jArray, jObject);

            json_free(jObject);
        }
    }

    new JSON:jMaps, szMap[32];

    rh_get_mapname(szMap, charsmax(szMap))

    if(json_object_has_value(jFile, "maps"))
        jMaps = json_object_get_value(jFile, "maps");
    else
        jMaps = json_init_object();

    json_object_set_value(jMaps, szMap, jArray);
    json_object_set_value(jFile, "maps", jMaps);

    json_serial_to_file(jFile, szPath, true);

    json_free(jFile);
    json_free(jMaps);
    json_free(jArray);

    return true;
}


/*
    Операции с памятью
*/

stock Alloc_ClassName_Make()
{
    g_tiClassName = TrieCreate();
    g_asClassName = ArrayCreate(ClassNameSize);
    g_asMenuName = ArrayCreate(MenuNameSize);
    g_asModel = ArrayCreate(ModelPathSize); 
    g_afSize = ArrayCreate(BoxSizeSize);
    g_aiSequence = ArrayCreate();
    g_abLight = ArrayCreate();
}

stock Alloc_ClassName_Free()
{
    TrieDestroy(g_tiClassName);
    ArrayDestroy(g_asClassName);
    ArrayDestroy(g_asMenuName);
    ArrayDestroy(g_asModel);
    ArrayDestroy(g_afSize);
    ArrayDestroy(g_aiSequence);
    ArrayDestroy(g_abLight);
}