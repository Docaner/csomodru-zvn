#include <amxmodx>
#include <reapi>
#include <zmcso/quests>
#include <zombieplague>

//Уникальный ключ
new const g_qstKey[] =          "killchinese";
//Название
new const g_qstName[] =         "Отправляйся к Хуан-ди,^n ублюдок..."; 
//Описание
new const g_qstDesc[] =         "Убейте определёное количество^nзомби-китайцев"
//Категория
#define CAT                     Category:Hard
//Какое количество очков надо набрать
#define FINISH                  3
//Тип награды
#define REWARD_TYPE             Rew:Experience
//Количество награды
#define AMOUNT                  150

//=============

//Название класса
new const g_szChineseName[] = "ML_CHINA_NAME"

new g_iQst;

new g_iZombie_Chinese;

public plugin_init()
{
    register_plugin("[QST] Kill Chinese", "1.0", "Docaner");

    RegisterHookChain(RG_CBasePlayer_Killed, "@RG__PlayerKilled_Post", true);

    g_iQst = q_register(g_qstKey, g_qstName, g_qstDesc, CAT, FINISH, REWARD_TYPE, AMOUNT);

    g_iZombie_Chinese = zp_get_zombie_class_id(g_szChineseName);

    
    //console_print(0, "CLASS: %d [%s]", g_iZombie_Chinese, g_szChineseName);
}

@RG__PlayerKilled_Post(pVictim, pAttacker, iGibs)
{
    if(!zp_get_user_zombie(pVictim) || zp_get_user_zombie_class(pVictim) != g_iZombie_Chinese)
        return;

    if(!is_user_connected(pAttacker) || zp_get_user_zombie(pAttacker))
        return;

    new qstUser;

    //Если у игрока нет этого квеста, то скип
    if( (qstUser = q_get_user_quest(pAttacker, g_iQst)) == -1)
        return;

    //Прибавляем прогресс
    q_set_user_progress(pAttacker, qstUser, q_get_user_progress(pAttacker, qstUser) + 1);
}