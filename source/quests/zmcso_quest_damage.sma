#include <amxmodx>
#include <reapi>
#include <zmcso/quests>
#include <zombieplague>

//Уникальный ключ
new const g_qstKey[] =          "damage";
//Название
new const g_qstName[] =         "Есть пробитие"; 
//Описание
new const g_qstDesc[] =         "Нанесите определёное количество^nурона по зомби"
//Категория
#define CAT                     Category:Easy
//Какое количество очков надо набрать
#define FINISH                  20000
//Тип награды
#define REWARD_TYPE             Rew:Money
//Количество награды
#define AMOUNT                  20000

new g_iQst;

public plugin_init()
{
    register_plugin("[QST] Damage", "1.0", "Docaner");

    RegisterHookChain(RG_CBasePlayer_TakeDamage, "@RG__TakeDamage_Post", true);

    g_iQst = q_register(g_qstKey, g_qstName, g_qstDesc, CAT, FINISH, REWARD_TYPE, AMOUNT);
}

@RG__TakeDamage_Post(pVictim, pInflictor, pAttacker, Float:flDamage, bDamageType)
{
    if(!is_user_connected(pAttacker) || pVictim == pAttacker)
        return;

    if(zp_get_user_zombie(pAttacker) || !zp_get_user_zombie(pVictim))
        return;

    new qstUser;

    //Если у игрока нет этого квеста, то скип
    if( (qstUser = q_get_user_quest(pAttacker, g_iQst)) == -1)
        return;

    //Прибавляем прогресс
    q_set_user_progress(pAttacker, qstUser, q_get_user_progress(pAttacker, qstUser) + floatround(flDamage));
}