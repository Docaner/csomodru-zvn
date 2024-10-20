#include <amxmodx>
#include <reapi>
#include <zmcso/quests>
#include <zombieplague>

//Уникальный ключ
new const g_qstKey[] =          "killzm";
//Название
new const g_qstName[] =         "Машина-убийца"; 
//Описание
new const g_qstDesc[] =         "Убейте определёное количество^nзомби"
//Категория
#define CAT                     Category:Easy
//Какое количество очков надо набрать
#define FINISH                  5
//Тип награды
#define REWARD_TYPE             Rew:Money
//Количество награды
#define AMOUNT                  21000

new g_iQst;

public plugin_init()
{
    register_plugin("[QST] Kill ZM", "1.0", "Docaner");

    RegisterHookChain(RG_CBasePlayer_Killed, "@RG__PlayerKilled_Post", true);

    g_iQst = q_register(g_qstKey, g_qstName, g_qstDesc, CAT, FINISH, REWARD_TYPE, AMOUNT);
}

@RG__PlayerKilled_Post(pVictim, pAttacker, iGibs)
{
    if(!zp_get_user_zombie(pVictim))
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