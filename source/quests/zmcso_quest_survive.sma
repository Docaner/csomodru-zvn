#include <amxmodx>
#include <reapi>
#include <zmcso/quests>
#include <zombieplague>

//Уникальный ключ
new const g_qstKey[] =          "survive";
//Название
new const g_qstName[] =         "Выживание"; 
//Описание
new const g_qstDesc[] =         "Выжить определённое количество^nраундов играя за человека"
//Категория
#define CAT                     Category:Easy
//Какое количество очков надо набрать
#define FINISH                  5
//Тип награды
#define REWARD_TYPE             Rew:Money
//Количество награды
#define AMOUNT                  15000

new g_iQst;

public plugin_init()
{
    register_plugin("[QST] Survive", "1.0", "Docaner");

    g_iQst = q_register(g_qstKey, g_qstName, g_qstDesc, CAT, FINISH, REWARD_TYPE, AMOUNT);
}

public zp_round_ended(eWinTeam)
{
    switch(eWinTeam)
    {
        case WIN_NO_ONE, WIN_HUMANS:
        {
            new qstUser;

            for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
            {
                if(!is_user_alive(iPlayer) || zp_get_user_zombie(iPlayer))
                    continue;

                //Если у игрока нет этого квеста, то скип
                if( (qstUser = q_get_user_quest(iPlayer, g_iQst)) == -1)
                    continue;

                //Прибавляем прогресс
                q_set_user_progress(iPlayer, qstUser, q_get_user_progress(iPlayer, qstUser) + 1);
            }
        }
    }
}