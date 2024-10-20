#include <amxmodx>
#include <reapi>
#include <zmcso/quests>
#include <zombieplague>

//Уникальный ключ
new const g_qstKey[] =          "survive_surv_round";
//Название
new const g_qstName[] =         "Окружен, но не сломлен"; 
//Описание
new const g_qstDesc[] =         "Выиграть раунд выжившего,^n играя за него"
//Категория
#define CAT                     Category:Hard
//Какое количество очков надо набрать
#define FINISH                  1
//Тип награды
#define REWARD_TYPE             Rew:Experience
//Количество награды
#define AMOUNT                  150

new g_iQst;

public plugin_init()
{
    register_plugin("[QST] Survive as Survivor", "1.0", "Docaner");

    g_iQst = q_register(g_qstKey, g_qstName, g_qstDesc, CAT, FINISH, REWARD_TYPE, AMOUNT);
}

public zp_round_ended(eWinTeam)
{
    switch(eWinTeam)
    {
        case WIN_HUMANS:
        {
            if(!zp_is_survivor_round()) return

            new qstUser;

            for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
            {
                if(!is_user_alive(iPlayer) || !zp_get_user_survivor(iPlayer))
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