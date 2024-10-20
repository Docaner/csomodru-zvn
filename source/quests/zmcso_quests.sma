#include <amxmodx>
#include <json>

//NEW
#include <zmcso/db>
#include <zmcso/smart_effects>
#include <zmcso/quests>

//OLD
#include <zpe_lvl>
#include <zp_system>

/* =============================
    Квесты
=============================== */

//Флаг, который позволяет установить себе квест
#define FLAG_SET_QST ADMIN_RCON 

new Array:g_aQsts[Qst];

/**
    Геттер и сеттер хранилища квестов
 */
#define gQst(%0)        Array:g_aQsts[Qst:%0]
#define sQst(%0,%1)     g_aQsts[Qst:%0] = %1 

/**
    Идентификаторы квестов по категориям сложности
 */

new Array:g_aCat[Category];

#define gCat(%0)        Array:g_aCat[Category:%0]
#define sCat(%0,%1)     g_aCat[Category:%0] = %1 


/* =============================
    База данных
=============================== */

new Array:g_aUser[33][User];

/**
    Геттер и сеттер хранилища квестов игроков
 */
#define gUsr(%0,%1)        Array:g_aUser[%0][User:%1]
#define sUsr(%0,%1,%2)     g_aUser[%0][User:%1] = %2 

/* =============================
    Игроки
=============================== */

new g_iBitUserConnected;

// Звук завершения квеста
new const g_szSndComplete[] = "sound/zp_br_cso/other/level_up.wav";

/* ==============================
    Меню
================================ */

#define USERQUEST_ITEMS_ON_PAGE 6 
#define ALLQUEST_ITEMS_ON_PAGE 7

new g_iMenuPosition[33],    // Позиция меню
    g_iMenuQuest[33],       // Выбранный квест в меню
    g_iMenuCategory[33];    // Категория квеста

/* PRECACHE */

public plugin_precache()
{
    precache_generic(g_szSndComplete);
}

/* NATIVES */

public plugin_natives() 
{
    register_native("q_register", "@q_register", true);
    register_native("q_get_user_quest", "@q_get_user_quest", true);
    register_native("q_get_user_progress", "@q_get_user_progress", true);
    register_native("q_set_user_progress", "@q_set_user_progress", true);
}


//Регистрация квеста
@q_register(const key[], const name[], const desc[], Category:cat, finish, Rew:rewType, rewAmount) {
    
    param_convert(1);
    param_convert(2);
    param_convert(3);


    if(ArrayFindString(gQst(Key), key) != -1)
        return -1;

    new qId = ArrayPushString(gQst(Key), key);
    ArrayPushString(gQst(Name), name);
    ArrayPushString(gQst(Desc), desc);

    ArrayPushCell(gQst(Cat), cat);
    ArrayPushCell(gQst(Finish), finish);
    ArrayPushCell(gQst(RewType), rewType);
    ArrayPushCell(gQst(RewAmount), rewAmount);

    //Помещение в массив категорий
    ArrayPushCell(gCat(cat), qId);

    return qId;
}

//Получение активного квеста игрока по id-квеста
@q_get_user_quest(id, qstID) {
    new qstUsr;

    //Если квест не активен, то возвращаем -1
    if( (qstUsr = ArrayFindValue(gUsr(id, QstID), qstID)) == -1)
        return -1;

    new completed = ArrayGetCell(gUsr(id, Compl), qstUsr);

    //Если квест завершён, то -1
    return completed ? -1 : qstUsr;
}

//Получение прогресса игрока
@q_get_user_progress(id, qstUsr) {
    return ArrayGetCell(gUsr(id, Prog), qstUsr);
}

//Установка прогресса игроку
@q_set_user_progress(id, qstUsr, value) {
    new qstID = ArrayGetCell(gUsr(id, QstID), qstUsr),
        finish = ArrayGetCell(gQst(Finish), qstID),
        completed = ArrayGetCell(gUsr(id, Compl), qstUsr)

    if(!completed && value >= finish)
    {
        ArraySetCell(gUsr(id, Compl), qstUsr, 1)
        ArraySetCell(gUsr(id, Prog), qstUsr, finish);
       
        giveUsrPrize(id, qstID);
        return;
    }
    
    ArraySetCell(gUsr(id, Prog), qstUsr, value);
}

/**
    Выдача приза игроку

    @param id - индекс клиента
    @param qstID - индекс квеста

    @noreturn
 */
stock giveUsrPrize(id, qstID)
{
    new szNameQst[64], szKey[32], szDesc[512], Category:cat, iFinish, Rew:rew, iAmount;
    gQstInfo(qstID, szNameQst, charsmax(szNameQst), szKey, charsmax(szKey), szDesc, charsmax(szDesc), cat, iFinish, rew, iAmount);
    
    new szName[32]; get_user_name(id, szName, charsmax(szName));
    new szReward[8]; rewToStr(rew, szReward, charsmax(szReward));

    client_print_color(0, id, "^4[QST] ^3%s ^1выполнил квест ^4%s ^1(Награда: ^4%d%s^1)", szName, szNameQst, iAmount, szReward);
    client_cmd(id, "spk ^"%s^"", g_szSndComplete);

    switch(rew)
    {
        case Money: zp_set_user_money(id, zp_get_user_money(id) + iAmount);
        case Ammo: zp_set_user_ammo(id, zp_get_user_ammo(id) + iAmount);
        case Experience: zpe_set_user_exp(id, zpe_get_user_exp(id) + iAmount);
    }
}

/* PLUGIN INIT */

#define KEYS_ALL 1023

public plugin_init() 
{
    register_plugin("[ZMCSO] Quests", "1.0", "Docaner")

    register_menucmd(register_menuid("Show_MenuUserQuests"), KEYS_ALL, "@Handle_MenuUserQuests");
    register_menucmd(register_menuid("Show_ProgressQuest"), KEYS_ALL, "@Handle_ProgressQuest");
    
    register_menucmd(register_menuid("Show_AllQstTypes"), KEYS_ALL, "@Handle_AllQstTypes");
    register_menucmd(register_menuid("Show_AllQstCategory"), KEYS_ALL, "@Handle_AllQstCategory");
    register_menucmd(register_menuid("Show_AllQstInfo"), KEYS_ALL, "@Handle_AllQstInfo");

    register_clcmd("menu_quests", "@ClCmd_Quests");

    qstInit();
    usrsInit();    
}

@ClCmd_Quests(id) return Show_MenuUserQuests(id, g_iMenuPosition[id] = 0);

// Меню выбора действующих квестов
stock Show_MenuUserQuests(id, iPos)
{
    if(iPos < 0) return PLUGIN_HANDLED;

    new iStringsCount = ArraySize(gUsr(id, ID));

    if(!iStringsCount)
    {
        client_print_color(id, id, "^4[QST] ^1Квесты не были загружены");
        return PLUGIN_HANDLED;
    }

    new iStart = iPos * USERQUEST_ITEMS_ON_PAGE
    if(iStart > iStringsCount) iStart = iStringsCount
    iStart = iStart - (iStart % USERQUEST_ITEMS_ON_PAGE)
    new iEnd = iStart + USERQUEST_ITEMS_ON_PAGE
    if(iEnd > iStringsCount) iEnd = iStringsCount

    new szMenu[512], iLen, iPagesNum = (iStringsCount / USERQUEST_ITEMS_ON_PAGE + ((iStringsCount % USERQUEST_ITEMS_ON_PAGE) ? 1 : 0))

    iLen = formatex(szMenu, charsmax(szMenu), "Ваши квесты на сегодня: \y[%d|%d]^n^n", iPos + 1, iPagesNum);

    new iKeys = (1<<6|1<<9), b;

    new iQID, szQstName[64], iProgress, iFinish, iComplete

    for(new a = iStart; a < iEnd; a++)
    {
        iQID = ArrayGetCell(gUsr(id, QstID), a);
        ArrayGetString(gQst(Name), iQID, szQstName, charsmax(szQstName));
        iProgress = ArrayGetCell(gUsr(id, Prog), a);
        iFinish = ArrayGetCell(gQst(Finish), iQID);
        iComplete = ArrayGetCell(gUsr(id, Compl), a);

        iKeys |= (1<<b);

        if(iComplete)
            iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s \y[Завершён]^n", ++b, szQstName);
        else
            iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s \r[%d/%d]^n", ++b, szQstName, iProgress, iFinish);
    }

    for(new i = b; i < USERQUEST_ITEMS_ON_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n")

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r7. \wСписок всех квестов^n")

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

    formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wВыход");

    return show_menu(id, iKeys, szMenu, -1, "Show_MenuUserQuests");
}

@Handle_MenuUserQuests(id, iKey) 
{
    switch(iKey)
	{
        case 6: return Show_AllQstTypes(id);
		case 7: return Show_MenuUserQuests(id, --g_iMenuPosition[id]);
		case 8: return Show_MenuUserQuests(id, ++g_iMenuPosition[id]);
		case 9: return PLUGIN_HANDLED;
		default:
		{
            new iChoose = g_iMenuPosition[id] * USERQUEST_ITEMS_ON_PAGE + iKey;

            g_iMenuQuest[id] = iChoose;

            return Show_ProgressQuest(id);
        }
    }
    return Show_MenuUserQuests(id, g_iMenuPosition[id]);
}

// Меню прогресса квеста
stock Show_ProgressQuest(id)
{
    new dbId, qId, szStartTime[32], szEndTime[32], iProgress, bComplete;
    gUsrInfo(id, g_iMenuQuest[id], dbId, qId, szStartTime, charsmax(szStartTime), szEndTime, charsmax(szEndTime), iProgress, bComplete);

    new szName[64], szKey[32], szDesc[512], Category:cat, iFinish, Rew:rew, iAmount;
    gQstInfo(qId, szName, charsmax(szName), szKey, charsmax(szKey), szDesc, charsmax(szDesc), cat, iFinish, rew, iAmount);
    
    new szReward[8]; rewToStr(rew, szReward, charsmax(szReward));
    new szCategory[16]; catToStr(cat, szCategory, charsmax(szCategory));

    new szMenu[512], iLen;

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y%s^n^n", szName);

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\wСтатус: %s^n", bComplete ? "\yзавершён" : "\rвыполняется");
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\wСложность: \r%s^n", szCategory);
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\wПрогресс: \r%d/%d^n", iProgress, iFinish);
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\wДата: \r%s \d- \r%s^n", szStartTime, szEndTime);
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\wНаграда: \r%d%s^n", iAmount, szReward);

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\yОписание^n^n");

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\w%s^n^n", szDesc);

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \wОбновить^n");
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0. \wНазад");

    return show_menu(id, (1<<0|1<<9), szMenu, -1, "Show_ProgressQuest");
}

@Handle_ProgressQuest(id, iKey)
{
    switch(iKey)
    {
        case 0: return Show_ProgressQuest(id);
        case 9: return Show_MenuUserQuests(id, g_iMenuPosition[id]);
    }
    return PLUGIN_HANDLED;
}

stock Show_AllQstTypes(id)
{
    new szMenu[512], iLen;

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\yСписок всех квестов (Сложность)^n^n");

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \wНизкая^n");
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \wСредняя^n");
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \wВысокая^n");

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n^n^n^n^n^n\r0. \wНазад");

    return show_menu(id, (1<<0|1<<1|1<<2|1<<9), szMenu, -1, "Show_AllQstTypes");
}

@Handle_AllQstTypes(id, iKey)
{
    if(iKey >= 0 && iKey < 3)
    {
        g_iMenuCategory[id] = iKey;
        return CMD_AllQstCategory(id);   
    }
        
    return @ClCmd_Quests(id);
}


stock CMD_AllQstCategory(id) return Show_AllQstCategory(id, g_iMenuPosition[id] = 0);
stock Show_AllQstCategory(id, iPos)
{
    if(iPos < 0) return PLUGIN_HANDLED;

    new iStringsCount = ArraySize(gCat(g_iMenuCategory[id]) );

    if(!iStringsCount)
    {
        client_print_color(id, id, "^4[QST] ^1Квесты не были загружены");
        return PLUGIN_HANDLED;
    }

    new iStart = iPos * ALLQUEST_ITEMS_ON_PAGE
    if(iStart > iStringsCount) iStart = iStringsCount
    iStart = iStart - (iStart % ALLQUEST_ITEMS_ON_PAGE)
    new iEnd = iStart + ALLQUEST_ITEMS_ON_PAGE
    if(iEnd > iStringsCount) iEnd = iStringsCount

    new szMenu[512], iLen, iPagesNum = (iStringsCount / ALLQUEST_ITEMS_ON_PAGE + ((iStringsCount % ALLQUEST_ITEMS_ON_PAGE) ? 1 : 0))

    new szCategory[32]; catToStr(Category:g_iMenuCategory[id], szCategory, charsmax(szCategory));

    iLen = formatex(szMenu, charsmax(szMenu), "Квесты (%s) \y[%d|%d]^n^n", szCategory, iPos + 1, iPagesNum);

    new iKeys = (1<<9), b;

    new iQID, szQstName[64];

    for(new a = iStart; a < iEnd; a++)
    {
        iQID = ArrayGetCell(gCat(g_iMenuCategory[id]), a);
        ArrayGetString(gQst(Name), iQID, szQstName, charsmax(szQstName));

        iKeys |= (1<<b);
        iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. \w%s^n", ++b, szQstName);
    }

    for(new i = b; i < ALLQUEST_ITEMS_ON_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");

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

    formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wВыход");

    return show_menu(id, iKeys, szMenu, -1, "Show_AllQstCategory");
}

@Handle_AllQstCategory(id, iKey) 
{
    switch(iKey)
	{
		case 7: return Show_AllQstCategory(id, --g_iMenuPosition[id]);
		case 8: return Show_AllQstCategory(id, ++g_iMenuPosition[id]);
		case 9: return Show_AllQstTypes(id);
		default:
		{
            new iChoose = g_iMenuPosition[id] * ALLQUEST_ITEMS_ON_PAGE + iKey;

            g_iMenuQuest[id] = iChoose;

            return Show_AllQstInfo(id);
        }
    }
    return Show_AllQstCategory(id, --g_iMenuPosition[id]);
}

stock Show_AllQstInfo(id)
{
    new iQID = ArrayGetCell(gCat(g_iMenuCategory[id]), g_iMenuQuest[id]);

    new szName[64], szKey[32], szDesc[512], Category:cat, iFinish, Rew:rew, iAmount;
    gQstInfo(iQID, szName, charsmax(szName), szKey, charsmax(szKey), szDesc, charsmax(szDesc), cat, iFinish, rew, iAmount);
    
    new szReward[8]; rewToStr(rew, szReward, charsmax(szReward));
    new szCategory[16]; catToStr(cat, szCategory, charsmax(szCategory));

    new szMenu[512], iKeys = (1<<9), iLen;

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y%s^n^n", szName);

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\wСложность: \r%s^n", szCategory);
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\wПрогресс: \r%d^n", iFinish);
    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\wНаграда: \r%d%s^n", iAmount, szReward);

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\yОписание^n^n");

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\w%s^n^n", szDesc);

    if(get_user_flags(id) & FLAG_SET_QST)
    {
        iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r1. \wУстановить квест \y(СРАЗУ)^n^n");
        iKeys |= (1<<0);
    }

    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r0. \wНазад");

    return show_menu(id, iKeys, szMenu, -1, "Show_AllQstInfo");
}

@Handle_AllQstInfo(id, iKey)
{
    switch(iKey)
    {
        case 0:
        {
            if(~get_user_flags(id) & FLAG_SET_QST) return CMD_AllQstCategory(id);

            new iUQST;

            if((iUQST = findUsrByCat(id, Category:g_iMenuCategory[id])) == -1)
            {
                client_print_color(id, id, "^4[QST] ^1Произошла ошибка! Квест не установлен.");
                return CMD_AllQstCategory(id);
            }

            new iQID = ArrayGetCell(gCat(g_iMenuCategory[id]), g_iMenuQuest[id]);

            ArraySetCell(gUsr(id, QstID), iUQST, iQID);
            ArraySetCell(gUsr(id, Prog), iUQST, 0);
            ArraySetCell(gUsr(id, Compl), iUQST, 0);
            
            client_print_color(id, id, "^4[QST] ^1Квест успешно установлен!");
        }
        case 9: return CMD_AllQstCategory(id);
    }
    return Show_AllQstInfo(id);
}

stock findUsrByCat(id, Category:cat)
{
    new iQID, Category:tempCat;
    for(new i; i < ArraySize(gUsr(id, QstID)); i++)
    {
        iQID = ArrayGetCell(gUsr(id, QstID), i);

        tempCat = ArrayGetCell(gQst(Cat), iQID);

        if(tempCat == cat) return i;
    }
    return -1;
}

// enum User {
//     ID = 0,     // Идентификатор квеста в БД
//     QstID,      // Идентификатор квеста в системе
//     StartTime,  // Начало времени
//     EndTime,    // Конец времени
//     Prog,       // Прогресс квеста
//     Compl       // Выполнен ли квест
// }
// enum Qst{
//     Key = 0,      // Ключ
//     Name,         // Название
//     Desc,         // Описание 
//     Cat,          // Сложность
//     Finish,       // Количество действий для получения награды
//     RewType,      // Тип награды
//     RewAmount     // Количество награды
// }

stock gUsrInfo(iPlayer, iUserQuest, &dbId, &qID, szStartTime[], iStartLen, szEndTime[], iEndLen, &iProgress, &bComplete)
{
    dbId = ArrayGetCell(gUsr(iPlayer, ID), iUserQuest);
    qID = ArrayGetCell(gUsr(iPlayer, QstID), iUserQuest);

    ArrayGetString(gUsr(iPlayer, StartTime), iUserQuest, szStartTime, iStartLen);
    ArrayGetString(gUsr(iPlayer, EndTime), iUserQuest, szEndTime, iEndLen);

    iProgress = ArrayGetCell(gUsr(iPlayer, Prog), iUserQuest);
    bComplete = ArrayGetCell(gUsr(iPlayer, Compl), iUserQuest);
}

stock gQstInfo(qID, szName[], iNameLen, szKey[], iKeyLen, szDesc[], iDescLen, &Category:cat, &iFinish, &Rew:iRew, &iAmount)
{
    ArrayGetString(gQst(Name), qID, szName, iNameLen);
    ArrayGetString(gQst(Key), qID, szKey, iKeyLen);
    ArrayGetString(gQst(Desc), qID, szDesc, iDescLen);

    cat = ArrayGetCell(gQst(Cat), qID);
    iFinish = ArrayGetCell(gQst(Finish), qID);
    iRew = ArrayGetCell(gQst(RewType), qID);
    iAmount = ArrayGetCell(gQst(RewAmount), qID);
}

//Инициализация массивов
stock qstInit() {
    sQst(ID, ArrayCreate());
    sQst(Key, ArrayCreate(32));
    sQst(Name, ArrayCreate(64));
    sQst(Desc, ArrayCreate(512));
    sQst(Cat, ArrayCreate());
    sQst(Finish, ArrayCreate());
    sQst(RewType, ArrayCreate());
    sQst(RewAmount, ArrayCreate());

    sCat(Easy, ArrayCreate());
    sCat(Medium, ArrayCreate());
    sCat(Hard, ArrayCreate());
}

//Инициализация массивов
stock usrsInit() {
    for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
        sUsr(iPlayer, ID, ArrayCreate());
        sUsr(iPlayer, QstID, ArrayCreate());
        sUsr(iPlayer, StartTime, ArrayCreate(20));
        sUsr(iPlayer, EndTime, ArrayCreate(20));
        sUsr(iPlayer, Prog, ArrayCreate());
        sUsr(iPlayer, Compl, ArrayCreate());
    }
}

/* SQL MAIN EVENT */
//Получение данных из БД
public zpe_mysql_user_load_post(id) {
    dbLoginQuests(id);
}

enum dbQstData
{
    sId, // Серверный ID
    dUserId // ID из БД
}

/**
    Отправляем запрос к БД на получение квестов
 */
stock dbLoginQuests(id) {
    //Получаем идентификатор игрока из БД
    new iUserID;

    if((iUserID = db_get_userid(id)) == -1)
        return false;

    //Формируем запрос
    new szJSON[512]; qGenerateQuests(szJSON, charsmax(szJSON));
    new szQuery[1024]; formatex(szQuery, charsmax(szQuery), "CALL zp_login_quests(%d, ^"%s^")", iUserID, szJSON);

    //Запоминаем USER ID (БД), ID (Серверный)
    new szData[dbQstData]; 
    
    szData[sId] = id;
    szData[dUserId] = iUserID;

    SQL_ThreadQuery(TURPLE, "@dbLoginQuestsResult", szQuery, szData, sizeof szData);
    return true;
}

@dbLoginQuestsResult(iFailState, Handle:hQuery, szError[], iError, szData[])
{
    //Обрабатываем ошибки
    if(iFailState) 
        {SQL_ErrorlogThread(iFailState, hQuery, szError, iError); return;}

    //Сверяем Id-шники
    new id = szData[sId], iUserID = db_get_userid(id);

    if(!is_user_connecting(id) && !is_user_connected(id) || iUserID != szData[dUserId])
        return;

    new iSysID, szQstKey[32], szStartTime[20], szEndTime[20];

    //Перебор записей
    for(new iRows; iRows < SQL_AffectedRows(hQuery); iRows++, SQL_NextRow(hQuery))
    {
        SQL_ReadResult( hQuery, SQL_FieldNameToNum(hQuery, "QuestKey"), szQstKey, charsmax(szQstKey));

        //Если по ключу не неайден квест, то мы его скипаем
        if((iSysID = ArrayFindString(gQst(Key), szQstKey)) == -1) continue;

        SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "StartTime"), szStartTime, charsmax(szStartTime));
        SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "EndTime"), szEndTime, charsmax(szEndTime));

        // ID = 0,     // Идентификатор квеста в БД
        // QstID,      // Идентификатор квеста в системе
        // StartTime,  // Начало времени
        // EndTime,    // Конец времени
        // Prog,       // Прогресс квеста
        // Compl       // Выполнен ли квест

        ArrayPushCell(gUsr(id, ID), SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "ID")));
        ArrayPushCell(gUsr(id, QstID), iSysID);
        ArrayPushString(gUsr(id, StartTime), szStartTime);
        ArrayPushString(gUsr(id, EndTime), szEndTime);
        ArrayPushCell(gUsr(id, Prog), SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "Progress")));
        ArrayPushCell(gUsr(id, Compl), SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery, "Complete")));
    }

    //Данные загружены
    SetBit(g_iBitUserConnected, id);
}

/**
    Генерация квестов
 */
stock qGenerateQuests(szJSON[], iLen)
{
    new JSON:jArray = json_init_array();

    jsonArrayAppendByCat(jArray, Category:Easy);
    jsonArrayAppendByCat(jArray, Category:Medium);
    jsonArrayAppendByCat(jArray, Category:Hard);

    //Образование JSON-строки
    json_serial_to_string(jArray, szJSON, iLen);
    SQL_QuoteString(Empty_Handle, szJSON, iLen, szJSON);
    // console_print(0, "JSON: ^"%s^"", szJSON);
    json_free(jArray);
}

/**
    Выбор рандомного квеста по категории

    @param jArray - JSON-Массив куда будет добавляться значение
    @param cat - категория квестов

    @noreturn

 */
stock jsonArrayAppendByCat(JSON:jArray, Category:cat)
{
    new iRand, JSON:jQuest;
    if((iRand = qGetRandomCategory(cat)) != -1)
    {
        jQuest = qGenerateJSON(iRand, 1);
        json_array_append_value(jArray, jQuest);
        json_free(jQuest);
    }
}

/*
    Возвращает объект JSON представляющий новый квест для БД
    @note           Дескриптор JSON необходимо освобождать
    @param qID      Идентификатор квеста в системе
    @param iDays    Количество дней действия квеста
*/
stock JSON:qGenerateJSON(qID, iDays) {
    new JSON:jQuest = json_init_object();

    //Помещаем ключевое название квеста
    new szKey[32]; ArrayGetString(gQst(Key), qID, szKey, charsmax(szKey));
    json_object_set_string(jQuest, "questKey", szKey);

    //Количество дней
    json_object_set_number(jQuest, "days", iDays);
    return jQuest;
}

// Получить индетификатор рандомного по категории сложности
stock qGetRandomCategory(Category:cat) {
    new iSize;

    //Проверка есть ли квест данной сложности
    if((iSize = ArraySize(gCat(cat))) <= 0)
        return -1;

    return ArrayGetCell(gCat(cat), random(iSize));
}

/* CLIENT EVENTS */
//Отключение игрока
public client_disconnected(id) {

    //Запрос на сохранение данных отправлен
    if(dbSaveQuests(id))
    {
        ClearBit(g_iBitUserConnected, id);
        usrClear(id);
    }
}

public zpe_mysql_delay_save(id) {
    dbSaveQuests(id);
}

//Очистка квестов
stock usrClear(id)
{
    ArrayClear(gUsr(id, ID));
    ArrayClear(gUsr(id, QstID));
    ArrayClear(gUsr(id, StartTime));
    ArrayClear(gUsr(id, EndTime));
    ArrayClear(gUsr(id, Prog));
    ArrayClear(gUsr(id, Compl));
}

stock dbSaveQuests(id)
{
    //Если данные игрока не загружены, то скип
    if(!IsSetBit(g_iBitUserConnected, id)) 
        return false;
    
    for(new i; i < ArraySize(gUsr(id, ID)); i++)
        dbSaveQuset(id, i);
    
    return true;
}

stock dbSaveQuset(id, iUserQst)
{
    new iQID = ArrayGetCell(gUsr(id, QstID), iUserQst);
    new szQstKey[32]; ArrayGetString(gQst(Key), iQID, szQstKey, charsmax(szQstKey));
    new szQuery[1024]; formatex(szQuery, charsmax(szQuery), "CALL zp_set_quest(%d, ^"%s^", %d, %d)", 
        ArrayGetCell(gUsr(id, ID), iUserQst),
        szQstKey,
        ArrayGetCell(gUsr(id, Prog), iUserQst), 
        ArrayGetCell(gUsr(id, Compl), iUserQst)
    );

    SQL_ThreadQuery(TURPLE, "@dbSaveQusetResult", szQuery);
}

@dbSaveQusetResult(iFailState, Handle:hQuery, szError[], iError)
{
    if(iFailState) 
		{SQL_ErrorlogThread(iFailState, hQuery, szError, iError); return;}
}

/*PLUGIN END*/

public plugin_end() {
    qstFree();
    usrsFree();
}

//Освобождение памяти, хранимое для квестов
stock qstFree() {
    ArrayDestroy(gQst(ID));
    ArrayDestroy(gQst(Key));
    ArrayDestroy(gQst(Name));
    ArrayDestroy(gQst(Desc));
    ArrayDestroy(gQst(Cat));
    ArrayDestroy(gQst(Finish));
    ArrayDestroy(gQst(RewType));
    ArrayDestroy(gQst(RewAmount));

    ArrayDestroy(gCat(Easy));
    ArrayDestroy(gCat(Medium));
    ArrayDestroy(gCat(Hard));
}

//Освобождение памяти, хранимое для игроков
stock usrsFree() {
    for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
        ArrayDestroy(gUsr(iPlayer, ID));
        ArrayDestroy(gUsr(iPlayer, QstID));
        ArrayDestroy(gUsr(iPlayer, StartTime));
        ArrayDestroy(gUsr(iPlayer, EndTime));
        ArrayDestroy(gUsr(iPlayer, Prog));
        ArrayDestroy(gUsr(iPlayer, Compl));
    }
}