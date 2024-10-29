#include amxmodx
#include reapi
#include zombieplague
#include string
#include zp_system 

#if !defined(zp_get_user_hero)
native zp_get_user_hero(id);
#endif

#define AUTHOR "MG"
#define VERSION "1.0"
#define PLUGIN "[ZP] Math quiz"

#define TASK_TIMER 521471
#define TASK_QUIZ 522271

new const StrReward[][] =
{
    "HP", //0 Для зм и людей
    "броню", //1 для людей
    "набор гранат", //2 для людей
    "ammo", //3 для зомби, людей, босса, выжика
    "деньги", // 4 для зомби, людей, босса, выжика
    "Thunderbolt", //5 для людей 
    "босса", // 6 для зомби
    "гранату-шок" // 7 для зомби

    /* ХП для людей = 100, для зомби = 3500 */
    /* Если игроку, будучи человеком, выдается броня, то для зомби - хп*/
    /* Гранаты и шок должны выдаваться в одном блоке */
    /* Thunderbolt и босс должны выдаваться в одном блоке */ 

    /* Бесконечные патроны для людей, невидимость для кого-то,*/
    /* Thunderbolt'у нужно откидывание */
}

new Float: MINTIME = 2.0
new Float: MAXTIME = 3.0
new Float: DELAY_QUIZ
new iNumRan
new iStatus = 0
new iAnswer
new iPlayerSum = 6
new StrAnswer[64]
new szQuestion[20]
new const SoundQuiz[] = "sound/events/tutor_msg.wav"

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    register_clcmd("say", "CheckAnswer")
    register_clcmd("say_team", "CheckAnswer")

    register_clcmd("zp_quiz_win", "Win")
    register_clcmd("zp_quiz_givethunder", "GiveThunder")
    register_clcmd("zp_quiz_startquest", "StartQuest")

    register_clcmd("say /quiz", "ShowQuestion")
    register_clcmd("say_team /quiz", "ShowQuestion")


    StartTimer()
}

public StartQuest(id)
{
    if ((iStatus == 0) && (get_user_flags(id) & ADMIN_IMMUNITY ) )
    {  
        PrintQuestion(id)
    }
    else if ((iStatus == 1) && (get_user_flags(id) & ADMIN_IMMUNITY ) )
    {
        client_print_color(id, id, "^4[ZP] ^1Викторина в процессе.")
    }
    else
    {
        return
    }
}

public Win(id)
{
    if ((iStatus == 1) && (get_user_flags(id) & ADMIN_IMMUNITY ) )
    {  
        client_print_color(id, id, "^4[ZP] ^1Ответ: ^4%s", StrAnswer)
    }
    else if ((iStatus == 0) && (get_user_flags(id) & ADMIN_IMMUNITY ) )
    {
        client_print_color(id, id, "^4[ZP] ^1Викторина еще не началась.")
    }
    else
    {
        return
    }
}

public GiveThunder(id)
{
    if ((get_user_flags(id) & ADMIN_IMMUNITY ) && !zp_get_user_hero(id))
    {  
        zp_force_buy_extra_item(id, zp_get_extra_item_id("Thunderbolt"), 1)
    }
    else if ((get_user_flags(id) & ADMIN_IMMUNITY ) && zp_get_user_hero(id))
    {  
        client_print_color(id, id, "^4[ZP] ^1За героя нельзя брать Thunderbolt.")
    }
    else
    {
        return
    }
}

public ShowQuestion(id)
{
    if (get_playersnum(0) >= iPlayerSum)
    {
        /* set_dhudmessage(204, 0, 204, 0.75 , 0.55, 0, 0.0, 25.0, 0.2, 0.5) */
        if (iStatus == 0)
        {
            /* show_dhudmessage(id, "Викторина еще не началась.") */
            client_print_color(id, 0, "^4[ZP] ^1Викторина еще не началась")
        }
        else
        {
            /* show_dhudmessage(id, "Викторина: ^4%s = ?", szQuestion) */
            client_print_color(id, 0, "^4[ZP] ^1Викторина: ^4%s = ?", szQuestion)
        }
    } else 
    {
        client_print_color(id, 0, "^4[ZP] ^1Викторины недоступны. Требуется минимум %d игроков.", iPlayerSum)
    }
}

public plugin_precache()
{
    precache_sound(SoundQuiz)
}

stock StartTimer()
{
    DELAY_QUIZ = random_float(MINTIME, MAXTIME)
    set_task(DELAY_QUIZ * 60.0, "PrintQuestion", TASK_QUIZ, _, _, "b")
}

public PrintQuestion(id)
{   
    if (get_playersnum(0) >= iPlayerSum)
    {
        new iNum[3]
        new Simbol[2]

        iNum[0] = random_num( 1, 200 )
        iNum[1] = random_num( 1, 200 )
        iNum[2] = random_num( 1, 200 )

        Simbol[0] = random_num( 0, 1 ) ? '+' : '-'
        Simbol[1] = random_num( 0, 1 ) ? '+' : '-'

        if( Simbol[0] == '+' && Simbol[1] == '+' )
            iAnswer = iNum[0] + iNum[1] + iNum[2]
        else if( Simbol[0] == '+' && Simbol[1] == '-' )
            iAnswer = iNum[0] + iNum[1] - iNum[2]
        else if( Simbol[0] == '-' && Simbol[1] == '+' )
            iAnswer = iNum[0] - iNum[1] + iNum[2]
        else
            iAnswer = iNum[0] - iNum[1] - iNum[2]

        num_to_str(iAnswer, StrAnswer, 63)	
        formatex( szQuestion, charsmax( szQuestion ), "%i %c %i %c %i", iNum[0], Simbol[0], iNum[1], Simbol[1], iNum[2] )

        /* set_dhudmessage(204, 0, 204, 0.75 , 0.65, 0, 0.0, 25.0, 0.2, 0.5)
        show_dhudmessage(0, "Викторина: ^4%s = ?", szQuestion) */
        client_print_color(0, 0, "^4[ZP] ^1Викторина: ^4%s = ?", szQuestion)
        client_cmd(0, "spk ^"%s^"", SoundQuiz);

        iStatus = 1
        iPlayerSum = 6
    } else 
    {
        client_print_color(0, 0, "^4[ZP] ^1Викторины недоступны. Требуется минимум %d игроков.", iPlayerSum)
    }
    
}

public CheckAnswer(id)
{
    new szChat[128]
    read_args(szChat, charsmax(szChat));
    remove_quotes(szChat);
        
    if ((iStatus == 1) && (get_user_team(id) == 3))
    {
        while ( iStatus == 1 )
        {
            if ( strcmp(szChat, StrAnswer) == 0)
            {
                client_print_color(id, id, "^4[ZP] ^1Наблюдатели не могут учавствовать в викторине.")
                return
            } else {
                return
            }
        }
    } else if ((iStatus == 1) && ((get_user_team(id) == 1) || (get_user_team(id) == 2)) && (is_user_alive(id)))
    {
        while ( iStatus == 1 )
        {
            if ( strcmp(szChat, StrAnswer) == 0)
            {
                RollReward(id)
                iStatus = 0
            } else {
                return
            }
        }
    } else if ((iStatus == 1) && ((get_user_team(id) == 1) || (get_user_team(id) == 2)) && !(is_user_alive(id)))
    {
        while ( iStatus == 1 )
        {
            if ( strcmp(szChat, StrAnswer) == 0)
            {
                client_print_color(id, id, "^4[ZP] ^1Мертвые не могут учавствовать в викторине.")
                return
            } else {
                return
            }
        }
    }
}

public RollReward(id)
{
    if (zp_get_user_nemesis(id) || zp_get_user_survivor(id))
    {
        iNumRan = random_num(86,97)
    } else
    {
        iNumRan = random_num(0,100)
    }
    RewardQuiz(id)
}


public RewardQuiz(id)
{
    new WinnerNick[128]
    new iReward
    get_user_name(id, WinnerNick, 127)
    
    if (0 <= iNumRan <= 35) /* 35 */
    {
        new Float: CurHealth
        new Float: GivenHealth = 100.0
        
        if (zp_get_user_zombie(id))
        {
            CurHealth = get_entvar(id, var_health)
            set_entvar(id, var_health, CurHealth + 3500.0)
            iReward = 0 // тут хп для зомби
        } else 
        {
            if (get_entvar(id, var_health) == 600.0)
            {
                iReward = 0
            } 
            else if (500.0 >= get_entvar(id, var_health))
            {
                CurHealth = get_entvar(id, var_health)
                set_entvar(id, var_health, CurHealth + GivenHealth)
                iReward = 0 // тут хп для людей
            }
            else if (500.0 <= get_entvar(id, var_health) < 600.0)
            {
                CurHealth = get_entvar(id, var_health)
                GivenHealth = 600.0 - CurHealth
                set_entvar(id, var_health, CurHealth + GivenHealth)
                iReward = 0 // тут хп для людей
            } 
        }
    }
    if ((36 <= iNumRan <= 56)) /* 20 */
    {
        new Float: CurArmor
        new Float: CurHealth
        new Float: GivenArmor = 100.0

        if (zp_get_user_zombie(id))
        {
            CurHealth = get_entvar(id, var_health)
            set_entvar(id, var_health, CurHealth + 3500.0)
            iReward = 0 // тут хп для зомби
        } else 
        {
            if (get_entvar(id, var_armorvalue) == 150.0)
            {
                iReward = 1
            } 
            else if (50.0 >= get_entvar(id, var_armorvalue))
            {
                CurArmor = get_entvar(id, var_armorvalue)
                set_entvar(id, var_armorvalue, CurArmor + GivenArmor)
                iReward = 1 // тут броня
            }
            else if (50.0 <= get_entvar(id, var_armorvalue) < 150.0)
            {   
                CurArmor = get_entvar(id, var_armorvalue)
                GivenArmor = 150.0 - CurArmor
                set_entvar(id, var_armorvalue, CurArmor + GivenArmor)
                iReward = 1 // тут броня
            }
        }
    }
    if ((57 <= iNumRan <= 72)) /* 15% */
    {
        if (zp_get_user_zombie(id))
        {
            zp_force_buy_extra_item(id, zp_get_extra_item_id("Shock"), 1)
            iReward = 7 // тут для зомби шок
        } else 
        {
            zp_force_buy_extra_item(id, zp_get_extra_item_id("Fire Grenade"), 1)
            zp_force_buy_extra_item(id, zp_get_extra_item_id("Frost"), 1)
            zp_force_buy_extra_item(id, zp_get_extra_item_id("Pumpkin Grenade"), 1)
            iReward = 2 // тут для гранат людей
        } 
    }
    if ((73 <= iNumRan <= 83)) /* 10% */
    {
        zp_set_user_ammo(id, zp_get_user_ammo(id) + random_num(5, 10))
        iReward = 3 // тут аммо
    }
    if ((84 <= iNumRan <= 94)) /* 10% */
    {
        zp_set_user_money(id, zp_get_user_money(id) + random_num(5000, 10000))
        iReward = 4 // тут деньги
    }
    if ( (95 <= iNumRan <= 100) ) /* 5% */
    {
        if (zp_get_user_zombie(id))
        {
            zp_force_buy_extra_item(id, zp_get_extra_item_id("Buy Nemesis"), 1)
            iReward = 6 // тут босс
        } else if (!zp_get_user_hero(id))
        {
            zp_force_buy_extra_item(id, zp_get_extra_item_id("Thunderbolt"), 1)
            iReward = 5 // тут thunderbolt
        } else if (zp_get_user_hero(id))
        {
            zp_set_user_ammo(id, zp_get_user_ammo(id) + random_num(20, 25))
            iReward = 3 // тут аммо
        } 
    }
    client_print_color(0, 0, "^4[ZP] ^4%s ^1победил в викторине и получил ^4%s!", WinnerNick, StrReward[iReward])
    /* set_dhudmessage(204, 0, 204, 0.61 , 0.35, 0, 0.0, 4.0, 0.2, 0.5)
    show_dhudmessage(0, "%s победил в викторине и получил %s!", WinnerNick, StrReward[iReward]) */
}