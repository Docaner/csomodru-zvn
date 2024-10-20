#include <amxmodx>
#include <reapi>
#include <zmcso/quests>
#include <zombieplague>

//Уникальный ключ
new const g_qstKey[] =          "knife";
//Название
new const g_qstName[] =         "Достал нож - режь"; 
//Описание
new const g_qstDesc[] =         "Убейте определёное количество^nзомби холодным оружием"
//Категория
#define CAT                     Category:Medium
//Какое количество очков надо набрать
#define FINISH                  5
//Тип награды
#define REWARD_TYPE             Rew:Ammo
//Количество награды
#define AMOUNT                  150

//==================

#define IMPULSE_SAW 3000


new g_iQst;

public plugin_init()
{
    register_plugin("[QST] Saw", "1.0", "Docaner");

    RegisterHookChain(RG_CBasePlayer_Killed, "@RG__PlayerKilled_Post", true);

    g_iQst = q_register(g_qstKey, g_qstName, g_qstDesc, CAT, FINISH, REWARD_TYPE, AMOUNT);
}

@RG__PlayerKilled_Post(pVictim, pAttacker, iGibs)
{
    if(!zp_get_user_zombie(pVictim) || !(get_member(pVictim, m_bitsDamageType) & (DMG_NEVERGIB|DMG_CLUB)))
        return;

    if(!is_user_connected(pAttacker) || zp_get_user_zombie(pAttacker))
        return;

    new pActiveItem;

    if( (pActiveItem = get_member(pAttacker, m_pActiveItem)) == NULLENT || get_entvar(pActiveItem, var_impulse) != IMPULSE_SAW)
        return;

    new qstUser;

    //Если у игрока нет этого квеста, то скип
    if( (qstUser = q_get_user_quest(pAttacker, g_iQst)) == -1)
        return;

    //Прибавляем прогресс
    q_set_user_progress(pAttacker, qstUser, q_get_user_progress(pAttacker, qstUser) + 1);
}