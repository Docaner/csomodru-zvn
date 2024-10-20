#include <amxmodx>
#include <reapi>
#include <zmcso/quests>
#include <zombieplague>

//Уникальный ключ
new const g_qstKey[] =          "killspin";
//Название
new const g_qstName[] =         "Остановим кручение"; 
//Описание
new const g_qstDesc[] =         "Убейте определёное количество^nспин дайверов"
//Категория
#define CAT                     Category:Medium
//Какое количество очков надо набрать
#define FINISH                  3
//Тип награды
#define REWARD_TYPE             Rew:Ammo
//Количество награды
#define AMOUNT                  85

//=============

//Название класса
new const g_szSpinName[] = "ML_SPINDIVER_NAME"

new g_iQst;

new g_iZombie_Spin;

public plugin_init()
{
    register_plugin("[QST] Kill Spin Diver", "1.0", "Docaner");

    RegisterHookChain(RG_CBasePlayer_Killed, "@RG__PlayerKilled_Post", true);

    g_iQst = q_register(g_qstKey, g_qstName, g_qstDesc, CAT, FINISH, REWARD_TYPE, AMOUNT);

    g_iZombie_Spin = zp_get_zombie_class_id(g_szSpinName);

    
    //console_print(0, "CLASS: %d [%s]", g_iZombie_Spin, g_szSpinName);
}

@RG__PlayerKilled_Post(pVictim, pAttacker, iGibs)
{
    if(!zp_get_user_zombie(pVictim) || zp_get_user_zombie_class(pVictim) != g_iZombie_Spin)
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