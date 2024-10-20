#include <amxmodx>
#include <reapi>
#include <api_json_smart_parser>
#include <zombieplague>
#include <gamecms5>

#if !defined zp_get_user_hero
native zp_get_user_hero(id)
#endif

new const g_szModelHero[] = "br_humans_hw24" // Модель героя;
#define BODY_HERO_PLAYER 18 // Боди героя
#define BODY_HERO_HAT 41 // Боди героя с шапкой

#define SKIN_DEF_MAX 5 // До какого пункта в меню идут бесплатные скины
#define SKIN_DEF random(SKIN_DEF_MAX) // Установка стандартного скина


new const g_szModelSurvivor[] = "br_humans_hw24" // Модель выжившего
#define BODY_SURVIVOR_PLAYER 20 // Боди выжившего

//Женские Die-звуки
new const g_szSoundGirlDie[][] = 
{
    "zp_br_cso/female_sounds/die_01.wav",
    "zp_br_cso/female_sounds/die_02.wav"
}

//Женские hit-звуки
new const g_szSoundGirlHit[][] =
{
    "zp_br_cso/female_sounds/hit_01.wav",
    "zp_br_cso/female_sounds/hit_02.wav"
}

/**
 * Прекеш player-моделей:
 * 
 * g_asModelKey 	   - char [32] 	   - Ключ модели
 * g_tiModelKey        - pModel        - Указатель модели
 * g_asModelPath 	   - char [32] 	   - Название модели
 * g_aiModelHumans 	   - int 		   - Количество субмоделей в группе BRHUMANS
 * g_aiModelConstumes  - int           - Количество субмоделей в группе COSTUMES
 * g_aiModelHats 	   - int 		   - Количество субмоделей в группе BTHATS
 * g_aiModelGirl       - int           - 1 - женские звуки; 0 - мужские звуки
 */

new const g_szPathHumanModels[] = "addons/amxmodx/configs/zpe_mode/addon_human_models.json"; // Путь до json
new Array:g_asModelKey, Trie:g_tiModelKey, Array:g_asModelPath, Array:g_aiModelHumans, Array:g_aiModelConstumes,
    Array:g_aiModelHats, Array:g_aiModelGirl;

/**
 * Загрузка скинов:
 * 
 * g_asSkinKey 			- char [32] 	- Ключ скина
 * g_tiSkinKey          - pSkin         - Указатель скина
 * g_asSkinName 		- char [64] 	- Название скина в меню
 * g_aiSkinModelKey 	- int 			- Указатель на player-модель
 * g_aiSkinBodyPlayer   - int           - body BRHUMANS
 * g_aiSkinBodyHat 		- int 			- body BTHATS с бронёй
 * g_aiSkinAll          - int           - Скин доступен для всех (1 - доступен для всех, 0 - только по покупке) 
 * g_asSkinBuy          - char [32]     - Сообщение в меню, о цене скина
 * g_flSkinArrmor       - Float         - Количество брони для скина
 */
new Array:g_asSkinKey, Trie:g_tiSkinKey, Array:g_asSkinName, Array:g_aiSkinModelKey, Array:g_aiSkinBodyPlayer, Array:g_aiSkinBodyHat, Array:g_aiSkinAll, Array:g_asSkinBuy, Array:g_flSkinArrmor;

/**
 * Выдача доступа:
 * g_taAccessNick        - Trie          - Доступ по нику (Ключ: Nick, Значение: Array со скинами)
 * g_taAccessSteamID     - Trie          - Доступ по SteamID (Ключ: SteamID, Значение: Array со скинами)
 * g_aiAccessFlag        - Array         - Доступ по Flags (Битсума админ-флага)
 * g_aaAccessFlag        - Array         - Доступ по Flags (Array-список со скинами)
 * g_taAccessService     - Trie          - Доступ по названию услуги GameCMS (Ключ: Nick, Значение: Array со скинами)
 */

new Trie:g_taAccessNick, Trie:g_taAccessSteamID, Array:g_aiAccessFlag, Array:g_aaAccessFlag, Trie:g_taAccessService;

new const g_szPathHumanUserSkins[] = "addons/amxmodx/configs/zpe_mode/addon_human_user_skins.json"; // Путь до json выдачи скинов

//Наименования AuthType из g_szPathHumanUserSkins
new const g_szTypeToEnum[] =
{
    'n', // Ник
    's', // SteamID
    'f', // Админ-Флаг
    'b' // Название услуги из GameCMS
};

enum
{
    T_NICK = 0,
    T_STEAMID,
    A_FLAG,
    T_SERVICE
}

enum _:FLAG_ARRAY
{
    FLAG_INT,
    Array:FLAG_SKINS
}

enum _:SERV_ARRAY
{
    SERV_STR[32],
    Array:SERV_SKINS
}

new bool:g_bUserSkinsLoad[33], g_pUserSetTmp[33];
new g_pUserChoose[33]; // Ссылка на выбранный скин игрока
new Trie:g_tUserSkins[33]; //Trie со всеми доступными скинами игрока

new g_iMenuPosition[33];

new g_iMaxPlayers;

#define DEF_INT_VALUE -1

#define PLAYERS_PER_PAGE 7

public plugin_precache()
{
    register_plugin("[ZPE] Human models", "1.1", "Docaner");

    precache_model_i(g_szModelHero, "Герой");
    precache_model_i(g_szModelSurvivor, "Выживший");
    precache_models_json();

    new i;

    for(i = 0; i < sizeof g_szSoundGirlDie; i++)
        precache_sound(g_szSoundGirlDie[i]);

    for(i = 0; i < sizeof g_szSoundGirlHit; i++)
        precache_sound(g_szSoundGirlHit[i]);
}

public plugin_init()
{
    register_event("Battery", "EV_Battery", "be")

    RegisterHookChain(RH_SV_StartSound, "@RH_StartSound_Pre", false);

    RegisterHookChain(RG_CSGameRules_RestartRound, "@RG_RestartRound_Post", true);
    RegisterHookChain(RG_CBasePlayer_Spawn, "@RG_PlayerSpawn_Post", true);

    register_clcmd("zpe_human_skins", "@CMD_HumanModelsMenu");

    register_menucmd(register_menuid("Show_HumanModelsMenu"), 1023, "@Handle_HumanModelsMenu")

    g_iMaxPlayers = get_maxplayers();

    arrayset(g_pUserSetTmp, -1, sizeof g_pUserSetTmp);

    for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
    {
        g_tUserSkins[iPlayer] = TrieCreate();
        @zp_set_user_human_skin_def(iPlayer);
    }
}

public plugin_cfg()
{
    load_users_skins_json();
}

public plugin_natives()
{
    //Обновить скин человека
    register_native("zp_update_user_human_model", "@zp_update_user_human_model", 1);
    //Получить строку с названием скина
    register_native("zp_get_user_human_skin_name", "@zp_get_user_human_skin_name");
    //Установить скин по skinkey
    register_native("zp_set_user_human_skin_key", "@zp_set_user_human_skin_key", 1);
    //Получить skin key выбранного скина
    register_native("zp_get_user_human_skin_key", "@zp_get_user_human_skin_key");
    //Установить скин по номеру
    register_native("zp_set_user_human_skin_id", "@zp_set_user_human_skin_id", 1);
    //Получить номер скина
    register_native("zp_get_user_human_skin_id", "@zp_get_user_human_skin_id", 1);
    //Установить стандартный скин
    register_native("zp_set_user_human_skin_def", "@zp_set_user_human_skin_def", 1);
    //Проверка на женский скин
    register_native("zp_is_user_girl_model", "@zp_is_user_girl_model", 1);
}

public plugin_end()
{
    arrays_destroy();
}

public OnAPIPostAdminCheck(const id, szFlags[MAX_STRING_LEN])
{
    TrieClear(g_tUserSkins[id]);

    give_user_access_skins_by_nick(id);
    give_user_access_skins_by_steamid(id);
    give_user_access_skins_by_gamecms(id);

    RequestFrame("@Request_CheckSkinFlags", id);
}

public zp_user_humanized_post(id, survivor)
{
    if(survivor) 
        return; 

    try_give_skin_armor(id);
}

@Request_CheckSkinFlags(id)
{
    give_user_access_skins_by_flags(id);
    check_user_access_to_choosen_skin(id);
    g_bUserSkinsLoad[id] = true;
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
    TrieClear(g_tUserSkins[id]);
    g_pUserChoose[id] = SKIN_DEF;
    g_bUserSkinsLoad[id] = false;
    g_pUserSetTmp[id] = -1;
}

stock add_user_skin_from_trie(id, Trie:tHandle, szAuthKey[])
{
    //TriePrint(tHandle);
    if(TrieKeyExists(tHandle, szAuthKey))
    {
        new Array:aSkinList; TrieGetCell(tHandle, szAuthKey, aSkinList);
        add_user_skins_from_skinlist(id, aSkinList);
    }
}

/*stock TriePrint(Trie:tHandle)
{
    if(tHandle == Invalid_Trie)
        return;

    new szName[32];

    new TrieIter:pIter;

    for(pIter = TrieIterCreate(tHandle); !TrieIterEnded(pIter); TrieIterNext(pIter))
    {
        TrieIterGetKey(pIter, szName, charsmax(szName));
        console_print(0, "szName iter = %s", szName);
    }

    TrieIterDestroy(pIter)
}*/

stock add_user_skins_from_skinlist(id, Array:aSkinList)
{
    new pSkin, szSkinKey[32];
    for(new i, iSize = ArraySize(aSkinList); i < iSize; i++)
    {
        pSkin = ArrayGetCell(aSkinList, i);
        ArrayGetString(g_asSkinKey, pSkin, szSkinKey, charsmax(szSkinKey));
        TrieSetCell(g_tUserSkins[id], szSkinKey, pSkin);
    }
}

public EV_Battery(id)
{
    if(zp_get_user_zombie(id) || zp_get_user_survivor(id))
        return;

    update_user_body(id);
}

@RH_StartSound_Pre(const pRecipients, const pEntity, const iChannel, const szSample[ ], const iVolume, const Float: flAttenuation, const bitsFlags, const iPitch)
{
    if(!is_user_connected(pEntity) || zp_get_user_zombie(pEntity) || zp_get_user_survivor(pEntity) || zp_get_user_hero(pEntity) || !@zp_is_user_girl_model(pEntity))
        return HC_CONTINUE;

    if(szSample[0] != 'p' || szSample[1] != 'l' || szSample[2] != 'a' || szSample[3] != 'y' || szSample[4] != 'e' || szSample[5] != 'r' || szSample[6] != '/')
        return HC_CONTINUE;

    //Die
    if(szSample[7] == 'd')
        SetHookChainArg(4, ATYPE_STRING, g_szSoundGirlDie[random(sizeof g_szSoundGirlDie)]);

    //Hit
    if(szSample[7] == 'b' && szSample[8] == 'h' && szSample[12] == 'f' || 
        szSample[7] == 'h' || 
        szSample[7] == 'p' && szSample[8] == 'l' && szSample[9] == '_' && 
            (szSample[10] == 'd' && szSample[11] == 'i' && szSample[12] == 'e' || szSample[10] == 'p' || szSample[10] == 's' && szSample[11] == 'h' && szSample[12] == 'o'))
                SetHookChainArg(4, ATYPE_STRING, g_szSoundGirlHit[random(sizeof g_szSoundGirlHit)]);

    return HC_CONTINUE;
}

@RG_RestartRound_Post()
{
    for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
    {
        if(!is_user_alive(iPlayer)) 
            continue;

        try_give_skin_armor(iPlayer);
    }
}

@RG_PlayerSpawn_Post(const pPlayer)
{
    if(!is_user_alive(pPlayer)) 
        return;

    try_give_skin_armor(pPlayer);
}


@CMD_HumanModelsMenu(id) return Show_HumanModelsMenu(id, g_iMenuPosition[id] = 0);
Show_HumanModelsMenu(id, iPos)
{
    if(iPos < 0) return PLUGIN_HANDLED;

    new iStringsCount = ArraySize(g_asSkinKey);

    if(!iStringsCount)
    {
        client_print_color(id, id, "^4[Skins] ^1Скины отсутствуют");
        return PLUGIN_HANDLED;
    }

    new iPagesNum = (iStringsCount / PLAYERS_PER_PAGE + ((iStringsCount % PLAYERS_PER_PAGE) ? 1 : 0));

    if(iPos >= iPagesNum)
        return Show_HumanModelsMenu(id, iPagesNum - 1);

    new iStart = iPos * PLAYERS_PER_PAGE;
    if(iStart > iStringsCount) iStart = iStringsCount;
    iStart = iStart - (iStart % PLAYERS_PER_PAGE);
    new iEnd = iStart + PLAYERS_PER_PAGE;
    if(iEnd > iStringsCount) iEnd = iStringsCount;

    new szMenu[512], 
        iLen = formatex(szMenu, charsmax(szMenu), "\yВыберите скин \w[%d|%d]^n^n", iPos + 1, iPagesNum);

    new iKeys = (1<<9), b,
        szSkinName[64], szSkinKey[32], szBuy[32];

    for(new a = iStart; a < iEnd; a++)
    {
        ArrayGetString(g_asSkinName, a, szSkinName, charsmax(szSkinName));
        iKeys |= (1<<b);

        if(ArrayGetCell(g_aiSkinAll, a))
            iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s%s^n", ++b, szSkinName, g_pUserChoose[id] == a ? " \r[*]" : "");
        else
        {
            ArrayGetString(g_asSkinKey, a, szSkinKey, charsmax(szSkinKey));
            if(TrieKeyExists(g_tUserSkins[id], szSkinKey))
                iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s%s^n", ++b, szSkinName, g_pUserChoose[id] == a ? " \r[*]" : "");
            else
            {
                ArrayGetString(g_asSkinBuy, a, szBuy, charsmax(szBuy));
                iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \d%s \r[%s]^n", ++b, szSkinName, szBuy);
            }
        }
    }

    for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n")

    if(iPos > 0)
    {
        iKeys |= (1<<7)
        iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r8. \wНазад^n")
    }
    else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r8. \dНазад^n")
    if(iPos < iPagesNum - 1)
    {
        iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9. \wДалее^n")
        iKeys |= (1<<8)
    }
    else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9. \dДалее^n")
    formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wВыход")

    return show_menu(id, iKeys, szMenu, -1, "Show_HumanModelsMenu")
}

@Handle_HumanModelsMenu(id, iKey)
{
    switch(iKey)
    {
        case 7: return Show_HumanModelsMenu(id, --g_iMenuPosition[id])
        case 8: return Show_HumanModelsMenu(id, ++g_iMenuPosition[id])
        case 9: return PLUGIN_HANDLED;
        default:
        {
            new iTarget = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;
            
            if(!ArrayGetCell(g_aiSkinAll, iTarget))
            {
                new szSkinKey[32]; ArrayGetString(g_asSkinKey, iTarget, szSkinKey, charsmax(szSkinKey));
                if(!TrieKeyExists(g_tUserSkins[id], szSkinKey))
                {
                    client_print_color(id, id, "^4[SKINS] ^1Нет доступа. Купить: ^3csomod.ru");
                    return PLUGIN_HANDLED;
                }
            }

            //Присваиваем выбранный скин игроку
            g_pUserChoose[id] = iTarget;

            update_user_skini(id);
        }
    }
    return Show_HumanModelsMenu(id, g_iMenuPosition[id]);
}

precache_model_i(const szModel[], const szName[])
{
    new szModelAllPath[64]; formatex(szModelAllPath, charsmax(szModelAllPath), "models/player/%s/%s.mdl", szModel, szModel);

    if(!file_exists(szModelAllPath))
    {
        set_fail_state("Не обноружена модель %s ^"%s^"", szName, szModel);
    }

    precache_model(szModelAllPath);
}

precache_models_json()
{
    new JSON:jHandle = json_parse(g_szPathHumanModels, true, true);

    if(!json_is_object(jHandle))
        set_fail_state("Неудалось распарсить ^"%s^"", g_szPathHumanModels);

    if(!json_object_has_value(jHandle, "models", JSONArray))
    {
        json_free(jHandle);
        set_fail_state("В JSON ^"%s^" не обнаружено поле 'models'", g_szPathHumanModels);
    }

    if(!json_object_has_value(jHandle, "skins", JSONArray))
    {
        json_free(jHandle);
        set_fail_state("В JSON ^"%s^" не обнаружено поле 'skins'", g_szPathHumanModels);
    }

    g_asModelKey = ArrayCreate(32);
    g_tiModelKey = TrieCreate();
    g_asModelPath = ArrayCreate(32);
    g_aiModelHumans = ArrayCreate();
    g_aiModelConstumes = ArrayCreate();
    g_aiModelHats = ArrayCreate();
    g_aiModelGirl = ArrayCreate();

    new JSON:jTemp;
    new i;

    new JSON:jArrayModels = json_object_get_value(jHandle, "models");
    new iModelsCount = json_array_get_count(jArrayModels);

    new szModelKey[32], szModelPath[32], szModelAllPath[64], iHumasn, iCostumes, iHats, iGirl; 

    for(i = 0; i < iModelsCount; json_free(jTemp), i++)
    {
        jTemp = json_array_get_value(jArrayModels, i);

        if(!json_is_object(jTemp)) continue;

        if(!get_string_by_prop(jTemp, "model_key", szModelKey, charsmax(szModelKey))) continue;
        
        if(TrieKeyExists(g_tiModelKey, szModelKey))
        {
            log_amx("model_key ^"%s^" уже существует", szModelKey);
            continue;
        }

        if(!get_string_by_prop(jTemp, "model_path", szModelPath, charsmax(szModelPath))) continue;

        formatex(szModelAllPath, charsmax(szModelAllPath), "models/player/%s/%s.mdl", szModelPath, szModelPath);

        if(!file_exists(szModelAllPath))
        {
            log_amx("Не обноружена модель ^"%s^"", szModelPath);
            continue;
        }

        if((iHumasn = get_int_by_prop(jTemp, "model_submodels_humas")) == DEF_INT_VALUE) continue;
        if((iCostumes = get_int_by_prop(jTemp, "model_submodels_costumes", _, false)) == DEF_INT_VALUE) iCostumes = 0;
        if((iHats = get_int_by_prop(jTemp, "model_submodels_hats")) == DEF_INT_VALUE) continue;
        if((iGirl = get_int_by_prop(jTemp, "model_girl")) == DEF_INT_VALUE) continue;

        precache_model(szModelAllPath);

        ArrayPushString(g_asModelKey, szModelKey);
        TrieSetCell(g_tiModelKey, szModelKey, ArraySize(g_asModelKey) - 1);
        ArrayPushString(g_asModelPath, szModelPath);
        ArrayPushCell(g_aiModelHumans, iHumasn);
        ArrayPushCell(g_aiModelConstumes, iCostumes);
        ArrayPushCell(g_aiModelHats, iHats);
        ArrayPushCell(g_aiModelGirl, iGirl)
    }

    json_free(jArrayModels);

    if(!ArraySize(g_asModelKey))
    {
        json_free(jHandle);
        arrays_destroy();
        set_fail_state("Нет ни одной доступной модели");
    }

    g_asSkinKey = ArrayCreate(32);
    g_tiSkinKey = TrieCreate();
    g_asSkinName = ArrayCreate(64);
    g_aiSkinModelKey = ArrayCreate();
    g_aiSkinBodyPlayer = ArrayCreate();
    g_aiSkinBodyHat = ArrayCreate();
    g_aiSkinAll = ArrayCreate();
    g_asSkinBuy = ArrayCreate(32);
    g_flSkinArrmor = ArrayCreate();


    new JSON:jArraySkins = json_object_get_value(jHandle, "skins");
    new iSkinsCount = json_array_get_count(jArraySkins);

    new szSkinKey[32], 
        szSkinName[64], 
        szSkinModelKey[32], pSkinModelKey, 
        iSkinSMPlayer, iSkinBodyPlayer,
        iSkinSMCostume, iSkinBodyCostume, 
        iSkinSMHat, iSkinBodyHat, Float:flArmor,
        iSkinAll,
        szBuy[32];

    new iBodyMaxs[3];

    for(i = 0; i < iSkinsCount; json_free(jTemp), i++)
    {
        jTemp = json_array_get_value(jArraySkins, i);
        
        if(!json_is_object(jTemp)) continue;

        if(!get_string_by_prop(jTemp, "skin_key", szSkinKey, charsmax(szSkinKey))) continue;
        
        if(TrieKeyExists(g_tiSkinKey, szSkinKey))
        {
            log_amx("skin_key ^"%s^" уже существует", szSkinKey);
            continue;
        }

        if(!get_string_by_prop(jTemp, "skin_name", szSkinName, charsmax(szSkinName))) continue;
        if(!get_string_by_prop(jTemp, "skin_modelkey", szSkinModelKey, charsmax(szSkinModelKey))) continue;

        if(!TrieKeyExists(g_tiModelKey, szSkinModelKey))
        {
            log_amx("skin_modelkey ^"%s^" не найден", szSkinModelKey);
            continue;
        }

        if((iSkinSMPlayer = get_int_by_prop(jTemp, "skin_submodelplayer")) == DEF_INT_VALUE) continue;

        iSkinSMCostume = get_int_by_prop(jTemp, "skin_submodelcostume", 1, false)

        if((iSkinSMHat = get_int_by_prop(jTemp, "skin_submodelhat")) == DEF_INT_VALUE) continue;

        flArmor = get_float_by_prop(jTemp, "armor");

        if((iSkinAll = get_int_by_prop(jTemp, "skin_all")) == DEF_INT_VALUE) iSkinAll = 1;

        if(!get_string_by_prop(jTemp, "skin_buy", szBuy, charsmax(szBuy), false)) szBuy[0] = '^0';

        TrieGetCell(g_tiModelKey, szSkinModelKey, pSkinModelKey);

        iBodyMaxs[0] = ArrayGetCell(g_aiModelHumans, pSkinModelKey);
        iBodyMaxs[1] = ArrayGetCell(g_aiModelConstumes, pSkinModelKey);
        iBodyMaxs[2] = ArrayGetCell(g_aiModelHats, pSkinModelKey);

        iSkinBodyPlayer = iSkinSMPlayer - 1;

        if(iBodyMaxs[1])
        {
            //Если значение костюма не выставлено
            if(iSkinSMCostume == DEF_INT_VALUE)
                iSkinSMCostume = 1;

            iSkinBodyCostume = (iSkinSMCostume - 1) * digit_body(2, iBodyMaxs);

            //Необходимо объеденить костюм с основой
            iSkinBodyPlayer += iSkinBodyCostume;
        }

        iSkinBodyHat = (iSkinSMHat - 1) * digit_body(3, iBodyMaxs);

        ArrayPushString(g_asSkinKey, szSkinKey);
        TrieSetCell(g_tiSkinKey, szSkinKey, ArraySize(g_asSkinKey) - 1);
        ArrayPushString(g_asSkinName, szSkinName);
        ArrayPushCell(g_aiSkinModelKey, pSkinModelKey);
        ArrayPushCell(g_aiSkinBodyPlayer, iSkinBodyPlayer);
        ArrayPushCell(g_aiSkinBodyHat, iSkinBodyHat);
        ArrayPushCell(g_flSkinArrmor, flArmor);
        ArrayPushCell(g_aiSkinAll, iSkinAll);
        ArrayPushString(g_asSkinBuy, szBuy)
    }

    json_free(jArraySkins);
    json_free(jHandle);

    if(!ArraySize(g_asSkinKey))
    {
        arrays_destroy();
        set_fail_state("Не подгруженны скины");
    }
}

stock digit_body(iGroup, const iBodyMaxs[])
{
    new iResault = 1;

    for(new i; i < iGroup - 1; i++)
        if(iBodyMaxs[i])
            iResault *= iBodyMaxs[i];

    return iResault;
}

/*stock get_int_by_prop(const JSON:j, const szProperty[], iDefValue = DEF_INT_VALUE, bool:bLog = true)
{
    if(json_object_has_value(j, szProperty, JSONNumber))
        return json_object_get_number(j, szProperty);
    if(bLog)
        log_amx("Не обноружено свойство ^"%s^"", szProperty);
    
    return iDefValue;
}

stock bool:get_string_by_prop(const JSON:j, const szProperty[], szRet[], iLen, bool:bLog = true)
{
    if(json_object_has_value(j, szProperty, JSONString))
    {
        json_object_get_string(j, szProperty, szRet, iLen);
        return true;
    }

    if(bLog)
        log_amx("Не обноружено свойство ^"%s^"", szProperty);
    
    return false;
}
*/

load_users_skins_json()
{
    new JSON:jHandle = json_parse(g_szPathHumanUserSkins, true, true);

    if(!json_is_object(jHandle))
        set_fail_state("Неудалось распарсить ^"%s^"", g_szPathHumanUserSkins);

    if(!json_object_has_value(jHandle, "users", JSONArray))
    {
        json_free(jHandle);
        set_fail_state("В JSON ^"%s^" не обнаружено поле 'users'", g_szPathHumanUserSkins);
    }


    g_taAccessNick = TrieCreate();
    g_taAccessSteamID = TrieCreate();
    g_aiAccessFlag = ArrayCreate();
    g_aaAccessFlag = ArrayCreate();
    g_taAccessService = TrieCreate();

    new JSON:jTemp;
    new i;

    new JSON:jArrayUsers = json_object_get_value(jHandle, "users");
    new iUsersCount = json_array_get_count(jArrayUsers);

    new szAuthType[2], iAuthType, szAuthKey[64], szSkinKey[32], pSkin; 

    for(i = 0; i < iUsersCount; json_free(jTemp), i++)
    {
        jTemp = json_array_get_value(jArrayUsers, i);

        if(!get_string_by_prop(jTemp, "auth_type", szAuthType, charsmax(szAuthType)))
            continue;

        if((iAuthType = get_auth_type(szAuthType)) == -1)
        {
            log_amx("auth_type ^"%s^" не определено", szAuthType);
            continue;
        }

        if(!get_string_by_prop(jTemp, "auth_key", szAuthKey, charsmax(szAuthKey)))
            continue;

        if(!get_string_by_prop(jTemp, "skin_key", szSkinKey, charsmax(szSkinKey)))
            continue;

        if(!TrieKeyExists(g_tiSkinKey, szSkinKey))
        {
            log_amx("skin_key ^"%s^" не определен", szSkinKey);
            continue;
        }

        TrieGetCell(g_tiSkinKey, szSkinKey, pSkin);


        set_access_to_skin(iAuthType, szAuthKey, pSkin);
    }

    json_free(jArrayUsers);
    json_free(jHandle);
}

stock get_auth_type(szAuthType[])
{
    for(new i; i < sizeof g_szTypeToEnum; i++)
        if(szAuthType[0] == g_szTypeToEnum[i])
            return i;

    return -1;
}

stock set_access_to_skin(iAuthType, szAuthKey[], pSkin)
{
    switch(iAuthType)
    {
        case T_NICK:
        {
            strtolower(szAuthKey);
            trie_push_skin(g_taAccessNick, szAuthKey, pSkin);
        }
        case T_STEAMID:
            trie_push_skin(g_taAccessSteamID, szAuthKey, pSkin);
        case A_FLAG:
            array_push_skin(g_aiAccessFlag, g_aaAccessFlag, pSkin, .iFlags = read_flags(szAuthKey));
        case T_SERVICE:
            trie_push_skin(g_taAccessService, szAuthKey, pSkin);
    }
}

stock trie_push_skin(Trie:tHandle, szKey[], pSkin)
{
    new Array:aSkinList;

    if(TrieKeyExists(tHandle, szKey))
        TrieGetCell(tHandle, szKey, aSkinList)
    else
        TrieSetCell(tHandle, szKey, (aSkinList = ArrayCreate()));


    ArrayPushCell(aSkinList, pSkin);
}

stock array_push_skin(Array:aHandleKey, Array:aHandleList, pSkin, iFlags = 0, szKey[] = "")
{
    new Array:aSkinList, iReference;

    if((iReference = (iFlags ? ArrayFindValue(aHandleKey, iFlags) : ArrayFindString(aHandleKey, szKey))) == -1)
    {
        iFlags ? ArrayPushCell(aHandleKey, iFlags) : ArrayPushString(aHandleKey, szKey);
        ArrayPushCell(aHandleList, (aSkinList = ArrayCreate()));
    }
    else aSkinList = ArrayGetCell(aHandleList, iReference);

    ArrayPushCell(aSkinList, pSkin);
}

//Обновить скин человека
@zp_update_user_human_model(id)
    return update_user_skin(id);

//Получить строку с названием скина
@zp_get_user_human_skin_name(id, szSkinName[], iLen)
{
    id = get_param(1);
    //szSkinName
    iLen = get_param(3);

    ArrayGetString(g_asSkinName, g_pUserChoose[id], szSkinName, iLen);
    set_string(2, szSkinName, iLen);
}

//Установить скин по skinkey
bool:@zp_set_user_human_skin_key(id, szSkinKey[])
{
    param_convert(2);
    //Есть ли скин в списке скинов
    if(!TrieKeyExists(g_tiSkinKey, szSkinKey))
        return false;

    new pSkin; TrieGetCell(g_tiSkinKey, szSkinKey, pSkin);

    //Если скин не для всех...
    if(!ArrayGetCell(g_aiSkinAll, pSkin))
    {
        //Если скины еще не подгруженны, то во временную переменную устанавливаем выбор
        if(!g_bUserSkinsLoad[id])
        {
            g_pUserSetTmp[id] = pSkin
            return true;
        }

        //Проверяем доступ к личному скину
        if(!TrieKeyExists(g_tUserSkins[id], szSkinKey))
            return false;
    }

    g_pUserChoose[id] = pSkin;

    update_user_skini(id);

    return true;
}

//Получить skin key выбранного скина
@zp_get_user_human_skin_key(id, szSkinKey[], iLen)
{
    id = get_param(1);
    //szSkinKey
    iLen = get_param(3);

    ArrayGetString(g_asSkinKey, g_pUserChoose[id], szSkinKey, iLen);
    set_string(2, szSkinKey, iLen);
}

//Установить скин по номеру
bool:@zp_set_user_human_skin_id(id, pSkin)
{
    //Проверяем диапазон pSkin
    if(pSkin < 0 || pSkin >= ArraySize(g_asSkinKey))
        return false;

    //Если скин не для всех...
    if(!ArrayGetCell(g_aiSkinAll, pSkin))
    {
        //Если скины еще не подгруженны, то во временную переменную устанавливаем выбор
        if(!g_bUserSkinsLoad[id])
        {
            g_pUserSetTmp[id] = pSkin
            return true;
        }

        //Проверяем доступ к личному скину
        new szSkinKey[32]; ArrayGetString(g_asSkinKey, pSkin, szSkinKey, charsmax(szSkinKey));
        if(!TrieKeyExists(g_tUserSkins[id], szSkinKey))
            return false;
    }

    g_pUserChoose[id] = pSkin;

    update_user_skini(id);

    return true;

}

//Получить номер скина
@zp_get_user_human_skin_id(id)
    return g_pUserChoose[id];

//Установить стандартный скин
@zp_set_user_human_skin_def(id)
{
    g_pUserChoose[id] = SKIN_DEF;
    update_user_skini(id);
}

//Текущая модель игрока является ли женской
// 1 - да
// 0 - нет
bool:@zp_is_user_girl_model(id)
    return ArrayGetCell(g_aiModelGirl, ArrayGetCell(g_aiSkinModelKey, g_pUserChoose[id]));

stock update_user_skini(id)
{
    if(!is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_survivor(id) || zp_get_user_hero(id))
        return false;

    return update_user_skin(id);
}

stock update_user_skin(id)
{
    new szModel[32];
    
    if(zp_get_user_survivor(id))
        copy(szModel, charsmax(szModel), g_szModelSurvivor)
    else if(zp_get_user_hero(id))
        copy(szModel, charsmax(szModel), g_szModelHero);
    else
    { 
        //Получение ссылки на модель
        new pModel = ArrayGetCell(g_aiSkinModelKey, g_pUserChoose[id]);

        //Получение строку модели по ссылке
        ArrayGetString(g_asModelPath, pModel, szModel, charsmax(szModel));
    }

    //Установка модели
    new iValue;
    if(!(iValue = zp_override_user_model(id, szModel, 1)))
        return iValue;

    update_user_body(id);

    return iValue;
}

stock update_user_body(id)
{
    if(zp_get_user_survivor(id))
    {
        set_entvar(id, var_body, BODY_SURVIVOR_PLAYER);
    }
    else if(zp_get_user_hero(id))
    {
        set_entvar(id, var_body, Float:get_entvar(id, var_armorvalue) > 0.0 ?
            BODY_HERO_HAT : BODY_HERO_PLAYER);
    }
    else
    {
        //Установка шапки в зависимости есть ли броня
        new iPlayerBody = ArrayGetCell(g_aiSkinBodyPlayer, g_pUserChoose[id]);

        set_entvar(id, var_body, Float:get_entvar(id, var_armorvalue) > 0.0 ?
            ArrayGetCell(g_aiSkinBodyHat, g_pUserChoose[id]) + iPlayerBody : iPlayerBody);
    }
}

give_user_access_skins_by_steamid(const id)
{
    new szSteamID[32]; get_user_authid(id, szSteamID, charsmax(szSteamID));
    add_user_skin_from_trie(id, g_taAccessSteamID, szSteamID);
}

give_user_access_skins_by_nick(const id)
{
    new szName[32]; get_user_name(id, szName, charsmax(szName)); strtolower(szName);
    add_user_skin_from_trie(id, g_taAccessNick, szName);
}

give_user_access_skins_by_flags(const id, iUserFlags = 0)
{
    if(!iUserFlags) iUserFlags = get_user_flags(id);

    new iFlags, Array:aSkinList;
    for(new i, iSize = ArraySize(g_aiAccessFlag); i < iSize; i++)
    {
        iFlags = ArrayGetCell(g_aiAccessFlag, i);

        if(~iUserFlags & iFlags) continue;

        aSkinList = ArrayGetCell(g_aaAccessFlag, i);
        add_user_skins_from_skinlist(id, aSkinList);
    }
}

give_user_access_skins_by_gamecms(const id)
{
    //Получение всех услуг клиента по названию услуги GameCMS
    new szServiceInfo[eAdminInfo], Array:aServices = cmsapi_get_user_services(id), Array:aSkinList;
    if(aServices != Invalid_Array)
    {
        for(new i, iSize = ArraySize(aServices); i < iSize; i++)
        {
            ArrayGetArray(aServices, i, szServiceInfo, sizeof szServiceInfo);

            if(!TrieKeyExists(g_taAccessService, szServiceInfo[AdminServiceName])) continue;

            TrieGetCell(g_taAccessService, szServiceInfo[AdminServiceName], aSkinList);
            add_user_skins_from_skinlist(id, aSkinList);
        }
    }
}

check_user_access_to_choosen_skin(id)
{
    if(!g_bUserSkinsLoad[id] && g_pUserSetTmp[id] != -1)
    {
        g_pUserChoose[id] = g_pUserSetTmp[id];
        g_pUserSetTmp[id] = -1;
    }

    if(g_pUserChoose[id] < SKIN_DEF_MAX)
        return;

    if(ArrayGetCell(g_aiSkinAll, g_pUserChoose[id]))
        return;

    new szSkinKey[32]; ArrayGetString(g_asSkinKey, g_pUserChoose[id], szSkinKey, charsmax(szSkinKey));

    if(TrieKeyExists(g_tUserSkins[id], szSkinKey))
        return;

    g_pUserChoose[id] = SKIN_DEF;

    update_user_skini(id);
}


arrays_destroy()
{
    ArrayDestroy(g_asModelKey);
    ArrayDestroy(g_asModelPath);
    ArrayDestroy(g_aiModelHumans);
    ArrayDestroy(g_aiModelConstumes);
    ArrayDestroy(g_aiModelHats);
    ArrayDestroy(g_aiModelGirl);

    ArrayDestroy(g_asSkinKey);
    TrieDestroy(g_tiSkinKey);
    ArrayDestroy(g_asSkinName);
    ArrayDestroy(g_aiSkinModelKey);
    ArrayDestroy(g_aiSkinBodyPlayer);
    ArrayDestroy(g_aiSkinBodyHat);
    ArrayDestroy(g_aiSkinAll);
    ArrayDestroy(g_asSkinBuy);
    ArrayDestroy(g_flSkinArrmor);

    arrays_destroy_from_trie(g_taAccessNick);
    TrieDestroy(g_taAccessNick);

    arrays_destroy_from_trie(g_taAccessSteamID);
    TrieDestroy(g_taAccessSteamID);

    ArrayDestroy(g_aiAccessFlag);
    arrays_destroy_from_array(g_aaAccessFlag);
    ArrayDestroy(g_aaAccessFlag);

    arrays_destroy_from_trie(g_taAccessService);
    TrieDestroy(g_taAccessService);

    for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
    {
        if(g_tUserSkins[iPlayer] != Invalid_Trie)
            TrieDestroy(g_tUserSkins[iPlayer]);
    }
}

stock arrays_destroy_from_trie(Trie:tHandle)
{
    if(tHandle == Invalid_Trie)
        return;

    new TrieIter:pIter, Array:a

    for(pIter = TrieIterCreate(tHandle); !TrieIterEnded(pIter); TrieIterNext(pIter))
    {
        TrieIterGetCell(pIter, a);
        ArrayDestroy(a);
    }

    TrieIterDestroy(pIter);
}

stock arrays_destroy_from_array(Array:aHandle)
{
    if(aHandle == Invalid_Array)
        return;

    new iSize = ArraySize(aHandle);

    if(!iSize)
        return;

    for(new i, Array:a; i < iSize; i++)
    {
        a = ArrayGetCell(aHandle, i);
        ArrayDestroy(a);
    }
}

stock try_give_skin_armor(const pPlayer)
{
    new Float:flArmor = ArrayGetCell(g_flSkinArrmor, g_pUserChoose[pPlayer]);

    if(flArmor <= 0.0 || Float:get_entvar(pPlayer, var_armorvalue) >= flArmor) return false;

    set_entvar(pPlayer, var_armorvalue, flArmor);
    return true;
}