#include <amxmodx>
#include <fakemeta_util>
#include <scp>
#include <hamsandwich>
#include <engine>
#include <xs>

//*******************************************************
//*                                                     *
//* CBaseDataInfo.                                      *
//*                                                     *
//*******************************************************

#define XO_CBaseAnimating               4
#define XO_CBaseMonster                 5

// #define HLDM
#if defined HLDM
    // CBaseAnimating
    #define m_flFrameRate               23    // Computed FPS for current sequence.
    #define m_flGroundSpeed             24    // Computed linear movement rate for current sequence.
    #define m_flLastEventCheck          25    // Last time the event list was checked.
    #define m_fSequenceFinished         26    // Flag set when StudioAdvanceFrame moves across a frame boundry.
    #define m_fSequenceLoops            27    // True if the sequence loops.

    // CBaseMonster
    #define m_LastHitGroup              90
    #define m_flNextAttack              148
    #define m_bloodColor                153
#else
    // CBaseAnimating
    #define m_flFrameRate               36
    #define m_flGroundSpeed             37
    #define m_flLastEventCheck          38
    #define m_fSequenceFinished         39
    #define m_fSequenceLoops            40

    // CBaseMonster
    #define m_LastHitGroup              75
    #define m_flNextAttack              83
    #define m_bloodColor                89
#endif

//*******************************************************
//*                                                     *
//* Monster DATA Things                                 *
//*                                                     *
//*******************************************************

#define ANIM_PASSIVE                116
#define ANIM_ACTIVE                 117

#define ANIM_SPAWN                  ANIM_PASSIVE//random_num(3, 4)
#define ANIM_KILLED                 random_num(101, 110)

#define ABILITY1_DAMAGE             15.0
#define ABILITY1_DAMAGETYPE         DMG_SLASH
#define ABILITY1_ANIM               123
#define ABILITY1_SPEED              1.0
#define ABILITY1_TIME               1.0


#define WATCH_RANGE_PASSIZE         600.0
#define WATCH_RANGE_ACTIVE          800.0
#define WATCH_RANGE_DEC_DUCK        490.0
#define WATCH_RANGE_DEC_STOP        540.0
#define WATCH_RANGE_DEC_SHIFT       440.0


#define TRIGGER_CHANGE_PASSIVE      80.0
#define TRIGGER_CHANGE_ACTIVE       600.0

#define MONSTER_RAGE_DURATION       3.0 + random_float(1.0, 4.0)

//Base reference class
#define MONSTER_REFERANCE           "env_explosion"
#define MONSTER_CLASSNAME           "monster_049-2"

//Monster settings
#define MONSTER_BLOODCOLOR          247
#define MONSTER_HEALTH              350.0

//Think MONSTER_UPDATERATE
#define MONSTER_UPDATERATE          0.025

//Model parameters
#define SEQ_MAX                            126 //111 128 //8
#define MONSTER_MODEL                     "models/player/scp_d_zm_b02/scp_d_zm_b02.mdl"
new const Float:MONSTER_MINS[3] =        {    -16.0   , -16.0    , -36.0    }
new const Float:MONSTER_MAXS[3] =        {     16.0   ,  16.0    ,  36.0    }



//*******************************************************
//*                                                     *
//* Monster DATA Things                                 *
//*                                                     *
//*******************************************************

// HLSDK Const
#define WALKMOVE_NORMAL                 0           // Normal walkmove
#define WALKMOVE_WORLDONLY              1           // Doesn't hit ANY entities, no matter what the solid type
#define WALKMOVE_CHECKONLY              2           // Move, but don't touch triggers

// Classify types
#define CLASS_NONE                  0
#define CLASS_MACHINE               1
#define CLASS_PLAYER                2
#define CLASS_HUMAN_PASSIVE         3
#define CLASS_HUMAN_MILITARY        4
#define CLASS_ALIEN_MILITARY        5
#define CLASS_ALIEN_PASSIVE         6
#define CLASS_ALIEN_MONSTER         7
#define CLASS_ALIEN_PREY            8
#define CLASS_ALIEN_PREDATOR        9
#define CLASS_INSECT                10
#define CLASS_PLAYER_ALLY           11
#define CLASS_PLAYER_BIOWEAPON      12         // bio weapons
#define CLASS_ALIEN_BIOWEAPON       13         // bio weapons (snarks, hornegun)

//Sound script keys
#define SCRIPT_EVENT_SOUND              1004    // Play named wave file (on CHAN_BODY).
#define SCRIPT_EVENT_SOUND_VOICE        1008    // Play named wave file (on CHAN_VOICE).
#define MONSTER_EVENT_BODYDROP_LIGHT    2001
#define MONSTER_EVENT_BODYDROP_HEAVY    2002
#define EVENT_STEPSOUND                 2003
#define SCRIPT_EVENT_SOUND_CLIENT       5004    // Play named wave file on client-side (on CHAN_BODY).
#define SCRIPT_EVENT_SOUND2             5005
#define SCRIPT_EVENT_STEP               5008


/*#define pevGetFParam(%0,%1) GetPevParam(%0,%1)

GetPevParam(iEntity, iParam)
{
    new Float:fValue;
    pev(iEntity, iParam, fValue);

    return fValue;
}
*/

//*******************************************************
//*                                                     *
//* Check                                               *
//*                                                     *
//*******************************************************
#define IsValid(%0)                         (%0>0&&pev_valid(%0))
#define IsMonster(%0)                       (GetMonsterKey(%0)==g_iMonsterKey)
#define IsAlive(%0)                         (entity_get_float(%0, EV_FL_health) > 0.0)



//*******************************************************
//*                                                     *
//* Monster DATA Things                                 *
//*                                                     *
//*******************************************************
#define GetMonsterAngle(%0)                 entity_get_float(%0,EV_FL_fuser1)
#define SetMonsterAngle(%0,%1)              set_pev(%0,pev_fuser1,%1)

#define Monster_GetNextAbilityTime(%0)      entity_get_float(%0,EV_FL_fuser2)
#define Monster_SetNextAbilityTime(%0,%1)   entity_set_float(%0,EV_FL_fuser2,%1)

#define Monster_GetRageTime(%0)             entity_get_float(%0,EV_FL_fuser3)
#define Monster_SetRageTime(%0,%1)          entity_set_float(%0,EV_FL_fuser3,%1)

#define Monster_GetBodyAngle(%0)            entity_get_float(%0,EV_FL_fuser4)
#define Monster_SetBodyAngle(%0,%1)         SetBodyAngle(%0,%1)////(entity_set_float(%0,EV_FL_fuser4,%1))

#define GetMonsterEnemy(%0)                 pev(%0,pev_enemy)
#define SetMonsterEnemy(%0,%1)              set_pev(%0,pev_enemy,%1)

#define GetMonsterState(%0)                 pev(%0,pev_iuser1)
#define SetMonsterState(%0,%1)              set_pev(%0,pev_iuser1,%1)

#define GetMonsterKey(%0)                   pev(%0,pev_impulse)
#define SetMonsterKey(%0,%1)                set_pev(%0,pev_impulse,%1)


stock SetBodyAngle(iEntity, Float:flAngle)
{
    set_pev(iEntity, pev_fuser4, flAngle);

    flAngle += 180.0;

    if(flAngle > 360.0)
        flAngle -= 360.0;

    set_pev(iEntity, pev_controller_2, floatround(255.0 / 360.0 * flAngle));
}

#define GetMonsterMoveLoc(%0,%1)        (pev(%0,pev_vuser1,%1))
#define SetMonsterMoveLoc(%0,%1)        (set_pev(%0,pev_vuser1,%1))


//*******************************************************
//*                                                     *
//* Custom data info                                    *
//*                                                     *
//*******************************************************
enum
{
    STATE_NONE,
    STATE_SCENE
}

#define LOCALMOVE_INVALID                       0     // move is not possible
#define LOCALMOVE_INVALID_DONT_TRIANGULATE      1     // move is not possible, don't try to triangulate
#define LOCALMOVE_VALID                         2     // move is possible
#define LOCALMOVE_FRIENDLY                      3     // move blocked with friendly entity


//*******************************************************
//*                                                     *
//* Monster DATA Things                                 *
//*                                                     *
//*******************************************************

new g_iReferance, g_iMonsterKey, g_iMaxPlayers, g_iCounter,
    mdl_gib_head , mdl_gib_flesh;



//*******************************************************
//*                                                     *
//* Messages stuff.                                     *
//*                                                     *
//*******************************************************

// Break Model Defines
#define BREAK_TYPEMASK      0x4F
#define BREAK_GLASS         0x01
#define BREAK_METAL         0x02
#define BREAK_FLESH         0x04
#define BREAK_WOOD          0x08
#define BREAK_SMOKE         0x10
#define BREAK_TRANS         0x20
#define BREAK_CONCRETE      0x40
#define BREAK_2             0x80

#define GIB_HEAD     "models/GIB_Skull.mdl"
#define GIB_FLESH    "models/GIB_B_Gib.mdl"

new Array:pepega;

//*******************************************************
//*                                                     *
//* Weapons for noize detect                            *
//*                                                     *
//*******************************************************
static DumpString1[][] = {
    "weapon_p228",          "weapon_scout",         "weapon_xm1014",    "weapon_c4",        "weapon_mac10",
    "weapon_aug",           "weapon_elite",         "weapon_fiveseven", "weapon_ump45",     "weapon_sg550",
    "weapon_galil",         "weapon_famas",         "weapon_usp",       "weapon_glock18",   "weapon_awp",
    "weapon_m249",          "weapon_m3",            "weapon_m4a1",      "weapon_tmp",       "weapon_g3sg1", 
    "weapon_deagle",        "weapon_sg552",         "weapon_ak47",      "weapon_p90",       "weapon_mp5navy",
}

static Float:lowNoize[][] =
{
    "weapon_knife",         "weapon_smokegrenade",  "weapon_hegrenade", "weapon_flashbang",
}


//*******************************************************
//*                                                     *
//* AMXMODX EVENTS                                      *
//*                                                     *
//*******************************************************
public plugin_precache()
{
    register_plugin("SCP 049-2", "4.1", "Chrescoe1");

    precache_model(MONSTER_MODEL);
    Animation_ParseSequences(MONSTER_MODEL);

    mdl_gib_head = engfunc(EngFunc_PrecacheModel, GIB_HEAD)
    mdl_gib_flesh = engfunc(EngFunc_PrecacheModel, GIB_FLESH)
}

public plugin_init()
{
    g_iMaxPlayers = get_maxplayers();
    g_iReferance = engfunc(EngFunc_AllocString, MONSTER_REFERANCE);
    g_iMonsterKey = engfunc(EngFunc_AllocString, MONSTER_CLASSNAME);

    register_ham();
    register_clcmds();
    register_logevent("logevent_round_start", 2, "1=Round_Start")
}

public logevent_round_start()
{
    remove_all_npc049();
    Cmd_CreateDefaultMonsters();
}

remove_all_npc049()
{
    new Float:scpOrigin[3];
    new iEntity = -1;
    while ((iEntity = fm_find_ent_in_sphere(iEntity, scpOrigin, 20000.0)) > 0)
    {
        if(IsMonster(iEntity))
        {
            ExecuteHamB(Ham_TakeDamage, iEntity, iEntity, iEntity, 9999.0, DMG_SLASH);
        }
    }
}


//*******************************************************
//*                                                     *
//* CLIENT COMMANDS                                     *
//*                                                     *
//*******************************************************
register_clcmds()
{
    register_clcmd("sinfo", "Cmd_MonstersExistInfo");
    register_clcmd("create_049-2", "Cmd_Create");

}

public Cmd_Create(const iPlayer)
{
    new Float:vOrigin[3]; pev(iPlayer, pev_origin, vOrigin);
    new Float:vecFow[3]; velocity_by_aim(iPlayer, 128, vecFow);
    vOrigin[0] += vecFow[0];
    vOrigin[1] += vecFow[1];
    vOrigin[2] += vecFow[2] - MONSTER_MINS[2] + 36.0;
    //client_print(0,print_chat,"Event called");
    Monster_Create(vOrigin);
    return PLUGIN_HANDLED;
}

//*******************************************************
//*                                                     *
//* HAMSANDWICTCH                                       *
//*                                                     *
//*******************************************************
register_ham()
{
    spawnOrigins = ArrayCreate(3, 1);
    RegisterHam(Ham_Player_PreThink, "player", "HookHam_Player_PreThink", false);

    RegisterHam(Ham_Think,         MONSTER_REFERANCE,    "HAM_MonsterThink",       false);
    RegisterHam(Ham_Killed,        MONSTER_REFERANCE,    "HAM_MonsterKilled",      false);
    RegisterHam(Ham_TakeDamage,    MONSTER_REFERANCE,    "HAM_MonsterTakeDamage",  false);
    RegisterHam(Ham_Classify,      MONSTER_REFERANCE,    "HAM_MonsterClassify",    false);
}

public HookHam_Player_PreThink() 
{
    //secretThing();
    return HAM_IGNORED;
}

public HAM_MonsterThink(const iMonster)
{
    if(!IsValid(iMonster) || !IsMonster(iMonster))
        return HAM_IGNORED;

    static Float:fGameTime;
    fGameTime = get_gametime();

    set_pev(iMonster, pev_nextthink, fGameTime + MONSTER_UPDATERATE);

    static Float:flInterval;
    flInterval = Animation_StudioFrameAdvance(iMonster);     // Animate.
    Animation_DispatchAnimEvents(iMonster, flInterval);      // Take care about animation events.

    static bool:IsSequenceFinished;
    IsSequenceFinished = (get_pdata_int(iMonster, m_fSequenceFinished, XO_CBaseAnimating) ? true :false);

    if(!IsAlive(iMonster))
    {
        //Set dying state :(
        if(IsSequenceFinished)
        {
            static Float:vOrigin[3];
            pev(iMonster, pev_origin, vOrigin);

            set_pev(iMonster, pev_flags, pev(iMonster, pev_flags) | FL_KILLME);

            //Throw head gib
            engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0);
            write_byte(TE_BREAKMODEL);
            engfunc(EngFunc_WriteCoord, vOrigin[0]);
            engfunc(EngFunc_WriteCoord, vOrigin[1]);
            engfunc(EngFunc_WriteCoord, vOrigin[2] + 16.0);
            engfunc(EngFunc_WriteCoord, 16.0);
            engfunc(EngFunc_WriteCoord, 16.0);
            engfunc(EngFunc_WriteCoord, 16.0);
            engfunc(EngFunc_WriteCoord, 0.0);
            engfunc(EngFunc_WriteCoord, 0.0);
            engfunc(EngFunc_WriteCoord, 100.0);
            write_byte(0);
            write_short(mdl_gib_head);
            write_byte(1);
            write_byte(65);
            write_byte(BREAK_FLESH);
            message_end();

            //Throw meats
            for(new i = 0; i < 16; i++)
            {
                engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0);
                write_byte(TE_BREAKMODEL);
                engfunc(EngFunc_WriteCoord, vOrigin[0]);
                engfunc(EngFunc_WriteCoord, vOrigin[1]);
                engfunc(EngFunc_WriteCoord, vOrigin[2]);
                engfunc(EngFunc_WriteCoord, 2.0);
                engfunc(EngFunc_WriteCoord, 2.0);
                engfunc(EngFunc_WriteCoord, 2.0);
                engfunc(EngFunc_WriteCoord, random_float(-80.0, 80.0));
                engfunc(EngFunc_WriteCoord, random_float(-80.0, 80.0));
                engfunc(EngFunc_WriteCoord, random_float(40.0, 60.0));
                write_byte(16);
                write_short(mdl_gib_flesh);
                write_byte(1);
                write_byte(45);
                write_byte(BREAK_FLESH);
                message_end();
            }

        }
        return HAM_IGNORED;
    }

    /*static iState;
    iState = GetMonsterState(iMonster);
    if(iState==STATE_SCENE)
        if(!IsSequenceFinished)
            return HAM_IGNORED;
        //else
        //    SetMonsterState(iMonster,STATE_NONE);*/

    new iAnim = pev(iMonster, pev_sequence);
    new Float:abilityTime = Monster_GetNextAbilityTime(iMonster) ;
    if(/*!IsSequenceFinished &&*/ abilityTime > fGameTime) // && iAnim == ABILITY1_ANIM)
    {
        return HAM_IGNORED;
    }

    if(iAnim != ANIM_ACTIVE && iAnim != ANIM_PASSIVE) /*is idle sequence*/
    {
        iAnim = ANIM_ACTIVE;
        Animation_SetAnim(iMonster, iAnim, 1.0, true);    //idle
    }

    new iEnemy = TryFindBestEnemy(iMonster, iAnim == ANIM_PASSIVE ? WATCH_RANGE_PASSIZE : WATCH_RANGE_ACTIVE);

    if(iEnemy <= 0)
    {
        if(Monster_GetRageTime(iMonster) > fGameTime)
        {
            iEnemy = GetMonsterEnemy(iMonster);
            if(iEnemy <= 0 || !is_user_connected(iEnemy) || !is_user_alive(iEnemy))
            {
                Monster_SetRageTime(iMonster, 0.0);
                iEnemy = 0;
                SetMonsterEnemy(iMonster, 0);
            }
        }
    }
    if(iEnemy > 0) Monster_MoveToEnemy(iMonster, iEnemy, flInterval);
    else Monster_Move(iMonster, flInterval);
    return HAM_IGNORED;
}

public HAM_MonsterKilled(const iMonster)
{
    if(!IsValid(iMonster) || !IsMonster(iMonster))
        return HAM_IGNORED;

    if (pev(iMonster, pev_deadflag) >= DEAD_DYING)
        return HAM_SUPERCEDE;    // Already dying?

    g_iCounter--;
    //client_print(0, print_chat, "%i monsters remain", g_iCounter);

    SetHamParamInteger(3, 1);    // Never gib such huge monster.
    set_pev(iMonster, pev_flags, pev(iMonster, pev_flags) & ~FL_MONSTER);    // Remove monster flag to avoid some problems.
    set_pev(iMonster, pev_solid, SOLID_NOT);
    set_pev(iMonster, pev_takedamage, DAMAGE_NO);

    set_pev(iMonster, pev_deadflag, DEAD_DYING);    // Time to die :'(

    Animation_SetAnim(iMonster, ANIM_KILLED, 1.0, true);
    return HAM_SUPERCEDE;
}

public HAM_MonsterTakeDamage(const iMonster, const iInflictor, const iAttacker, const Float:fDamage, const DMG_BYTES)
{
    if(!IsValid(iMonster) || !IsMonster(iMonster) || !(0 < iAttacker <= g_iMaxPlayers))
        return HAM_IGNORED;

    static Float:fGameTime, Float:lastHit;
    fGameTime = get_gametime();
    if(lastHit == fGameTime)
        return HAM_SUPERCEDE;

    switch(random_num(0, 5))
    {
        case 0:{ emit_sound(iMonster, CHAN_VOICE, "player/pain1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );}
        case 1:{ emit_sound(iMonster, CHAN_VOICE, "player/pain2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );}
        case 2:{ emit_sound(iMonster, CHAN_VOICE, "player/pain3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );}
        case 3:{ emit_sound(iMonster, CHAN_VOICE, "player/pain4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );}
        case 4:{ emit_sound(iMonster, CHAN_VOICE, "player/pain5.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );}
        case 5:{ emit_sound(iMonster, CHAN_VOICE, "player/pain6.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );}
    }

    lastHit = fGameTime;
    //static Float:flHealth; flHealth = entity_get_float(iMonster, EV_FL_health);

    //client_print(iAttacker, print_center, "Damage %..1f; Hitbox:%i; Health:%..1f", fDamage, get_pdata_int(iMonster, m_LastHitGroup, XO_CBaseMonster), flHealth - fDamage);

    if(scp_get_user_group(iAttacker) != GROUP_SCP)
    {
        Monster_SetRageTime(iMonster, fGameTime + MONSTER_RAGE_DURATION);
        SetMonsterEnemy(iMonster, iAttacker);
    }

    if(pev(iMonster, pev_sequence) == ANIM_PASSIVE)
        Animation_SetAnim(iMonster, ANIM_ACTIVE, 1.0, true);
    return HAM_IGNORED;
}

public HAM_MonsterClassify(const iMonster)
{
    SetHamReturnInteger(CLASS_ALIEN_MONSTER);
    return HAM_OVERRIDE;
}

//Stuff
Monster_Create(const Float:vOrigin[3])
{
    new iMonster = engfunc(EngFunc_CreateNamedEntity, g_iReferance);
    if(!iMonster || !IsValid(iMonster))
    {
        //client_print(0, print_chat, "INVALID");
        return 0;
    }

    engfunc(EngFunc_SetModel, iMonster, MONSTER_MODEL);
    engfunc(EngFunc_SetSize, iMonster, MONSTER_MINS, MONSTER_MAXS);
    engfunc(EngFunc_SetOrigin, iMonster, vOrigin);
    set_pev(iMonster, pev_flags, FL_MONSTER);

    set_pev(iMonster, pev_movetype, MOVETYPE_STEP);
    set_pev(iMonster, pev_solid, SOLID_SLIDEBOX);

    engfunc(EngFunc_DropToFloor, iMonster);
    if (!engfunc(EngFunc_WalkMove, iMonster, 0.0, 0.0, WALKMOVE_NORMAL))
    {
        //client_print(0, print_chat, "Monster stuck in wall!");
        engfunc(EngFunc_RemoveEntity, iMonster);
        return 0;
    }
    g_iCounter++;
    //client_print(0,print_chat,"Fine");

    set_pev(iMonster, pev_gravity, 1.0);
    set_pev(iMonster, pev_takedamage, DAMAGE_YES);


    set_pev(iMonster, pev_health, MONSTER_HEALTH);
    set_pev(iMonster, pev_max_health, MONSTER_HEALTH);
    //set_pev(iMonster,pev_speed,MONSTER_SPEED);
    //set_pev(iMonster,pev_maxspeed,MONSTER_SPEED);

    set_pev(iMonster, pev_classname, MONSTER_CLASSNAME);
    SetMonsterKey(iMonster, g_iMonsterKey);

    new race = random_num(0, 7);
    set_pev(iMonster, pev_skin, race);
    set_pev(iMonster, pev_body, race);
    set_pev(iMonster, pev_nextthink, get_gametime());
    set_pev(iMonster, pev_gamestate, 1);

    Monster_SetNextAbilityTime(iMonster, get_gametime());
    set_pdata_int(iMonster, m_bloodColor, MONSTER_BLOODCOLOR, XO_CBaseMonster);

    SetMonsterState(iMonster, STATE_SCENE);

    SetMonsterAngle(iMonster, random_float(0.0, 360.0));
    set_pev(iMonster, pev_controller_0, 127);

    //random_num(13, 18) - idle
    Animation_SetAnim(iMonster, ANIM_SPAWN, 1.0, true);

    return iMonster;
}

//*******************************************************
//*                                                     *
//* Bolvan AI.                                          *
//*                                                     *
//*******************************************************
TryFindBetterEnemy(const iMonster, const iBest){
    static i, Float:fDist;
    static Float:sOrigin[3]; pev(iMonster, pev_origin, sOrigin); sOrigin[2] += MONSTER_MINS[2];
    static Float:eOrigin[3]; pev(iBest, pev_origin, eOrigin);

    static Float:bestDist; bestDist = (fDist = get_distance_f(eOrigin, sOrigin));
    static bestEnemy; bestEnemy = iBest;

    for(i = 1; i <= g_iMaxPlayers; i++){
        if(i == iBest) continue;
        if(!is_user_connected(i) || !is_user_alive(i)) continue;
        if(scp_get_user_group(i) == GROUP_SCP) continue;

        pev(i, pev_origin, eOrigin);
        fDist = get_distance_f(sOrigin, eOrigin);
        if(fDist < bestDist)
            bestDist = fDist,
            bestEnemy = i;
    }
    return bestEnemy;

}

TryFindBestEnemy(const iMonster, Float:flSearchDist){
    static Float:vOrigin[3];
    pev(iMonster, pev_origin, vOrigin);

    static Float:flDist, i, Float:bestDist, bestEnemy, Float:eOrigin[3], Float:vecTargetEye[3];
    bestDist = flSearchDist;
    bestEnemy = 0;

    new bool:isInRage = Monster_GetRageTime(iMonster) > get_gametime();
    static Float:vecMonsterEye[3];
    pev(iMonster, pev_view_ofs, vecMonsterEye);
    xs_vec_add(vOrigin, vecMonsterEye, vecMonsterEye);

    for(i = 1; i <= g_iMaxPlayers; i++){
        if(!is_user_connected(i) || !is_user_alive(i)) continue;
        if(scp_get_user_group(i) == GROUP_SCP) continue;

        pev(i, pev_origin, eOrigin);
        flDist = get_distance_f(vOrigin, eOrigin);

        new Float:flSpeed = fm_get_user_speed(i);

        if(!isInRage && flDist > TRIGGER_CHANGE_PASSIVE)
        {
            if(flSpeed == 0.0)
                flDist += WATCH_RANGE_DEC_STOP;

            if(pev(i, pev_flags) & FL_DUCKING)
                flDist += WATCH_RANGE_DEC_DUCK;
            else
            if(flSpeed < 180.0)
                flDist += WATCH_RANGE_DEC_SHIFT;
        }

        if(flDist < bestDist)
        {
            pev(i, pev_view_ofs, vecTargetEye);
            xs_vec_add(eOrigin, vecTargetEye, vecTargetEye);

            if(!CheckLine(vecMonsterEye, vecTargetEye, iMonster, i))
            {
                continue;
            }

            bestDist = flDist;

            bestEnemy = i;

        }
    }

    new Float:fGameTime = get_gametime();
    //client_print(0,print_chat,"dist:%..1f",bestDist);

    if(Monster_GetRageTime(iMonster) < fGameTime)
    {
        if(bestEnemy == 0 || bestDist == flDist || bestDist > TRIGGER_CHANGE_ACTIVE)
        {
            if(pev(iMonster, pev_sequence) == ANIM_ACTIVE)
                Animation_SetAnim(iMonster, ANIM_PASSIVE, 1.0, true);
        }
        else
        {
            if(bestDist < TRIGGER_CHANGE_PASSIVE)
                if(pev(iMonster, pev_sequence) == ANIM_PASSIVE)
                {
                    Animation_SetAnim(iMonster, ANIM_ACTIVE, 1.0, true);
                    Monster_SetRageTime(iMonster,  fGameTime + MONSTER_RAGE_DURATION);
                    SetMonsterEnemy(iMonster, bestEnemy);
                }
        }
    }else if(bestEnemy > 0) Monster_SetRageTime(iMonster, fGameTime + MONSTER_RAGE_DURATION);



    return bestEnemy;
}

/*Monster_FindBestEnemy(const iMonster, const Float:flDistance)
{
    static iEnemy;iEnemy=0;
    static iEntity;iEntity=0;

    static Float:flDist; flDist=0.0;
    static Float:flNearest ;flNearest = 8192.0;

    static Float:vecSrc[3];
    pev(iMonster, pev_origin, vecSrc);vecSrc[2]+=MONSTER_MINS[2];

    while ((iEntity = find_ent_in_sphere(iEntity, vecSrc, flDistance)))
    {
        if (iEntity != iMonster && !IsMonster(iEntity) && IsAlive(iEntity) && entity_get_float(iEntity, EV_FL_takedamage) != DAMAGE_NO)//&& is_visible(iEntity, iMonster))
        {
            if ((flDist = entity_range(iMonster, iEntity)) < flNearest)
            {
                iEnemy = iEntity;
                flNearest = flDist;
            }
        }
    }

    return iEnemy;
}*/

stock Monster_Move(iMonster, Float:flInterval)
{
    new Float:flIdealYaw = GetMonsterAngle(iMonster);
    new Float:flTotal = get_pdata_float(iMonster, m_flGroundSpeed, XO_CBaseAnimating) * entity_get_float(iMonster, EV_FL_framerate) * flInterval;

    static iRand = 1;//(random_num(0, 1) == 1 ? 1:-1);
    if (flTotal >= 1.0)
    {
        new Float:flStep = floatmin(8.0, flTotal);

        if (!engfunc(EngFunc_WalkMove, iMonster, flIdealYaw, flStep, WALKMOVE_NORMAL))
        {
            //client_print(0,print_chat,"Try to Change Ideal Yaw... %..1f",get_gametime())
            for(new Float:pushYaw = 15.0; pushYaw < 75.0; pushYaw += 15.0)
            {
                new Float:value1 = UTIL_AngleMod(flIdealYaw + pushYaw * iRand);
                if(engfunc(EngFunc_WalkMove, iMonster, value1, flStep, WALKMOVE_NORMAL)){
                    //client_print(0,print_chat,"Yaw switch1:%..1f",pushYaw*iRand);
                    Monster_UpdateAngles(iMonster, value1);
                    return;
                }
                
                new Float:value2 = UTIL_AngleMod(flIdealYaw - pushYaw * iRand);
                if(engfunc(EngFunc_WalkMove, iMonster, value2, flStep, WALKMOVE_NORMAL))
                {
                    //client_print(0,print_chat,"Yaw switch2:%..1f",-pushYaw*iRand);
                    Monster_UpdateAngles(iMonster, value2);
                    return;
                }
            }
        }
        else
        {
            Monster_UpdateAngles(iMonster, flIdealYaw);
            return;
        }
    }

    flIdealYaw = UTIL_AngleMod(flIdealYaw + random_float(90.0, 270.0));
    //engfunc(EngFunc_WalkMove, iMonster, flIdealYaw, WALKMOVE_NORMAL);
    Monster_UpdateAngles(iMonster, flIdealYaw);
}

Monster_Move2(const iMonster, const Float:flInterval, Float:idealAngle)
{
    new Float:flIdealYaw = idealAngle;//GetMonsterAngle(iMonster);
    new Float:flTotal = get_pdata_float(iMonster, m_flGroundSpeed, XO_CBaseAnimating) * entity_get_float(iMonster, EV_FL_framerate) * flInterval;
    //client_print(0,print_chat,"Speed:%..1f",flTotal);

    //static Float:vecOrigin[3];
    //pev(iMonster, pev_origin, vecOrigin);
    /*static Float:vEnd[3]; pev(iMonster, pev_origin, vEnd);
    new Float:fAngles = GetMonsterAngle(iMonster);
    new Float:Vel[3];
    //pev(iMonster,pev_velocity,Vel);
    Vel[0] = floatcos(fAngles, grades) * flTotal;
    Vel[1] = floatsin(fAngles, grades) * flTotal;
    //set_pev(iMonster,pev_velocity,Vel);
    pev(iMonster, pev_origin, vEnd);
    engfunc(EngFunc_MoveToOrigin, iMonster, vEnd, 0.0, WALKMOVE_WORLDONLY);
    */

    //vEnd[0] += Vel[0];
    //vEnd[1] += Vel[1];
    new iRand = 1;//(random_num(0, 1) == 1 ? 1:-1);
    while (flTotal > 0.001)
    {
        new Float:flStep = floatmin(8.0, flTotal);
        flTotal -= 8.0;
        //engfunc(EngFunc_WalkMove, iMonster, flIdealYaw, flStep, WALKMOVE_CHECKONLY)
        if (!engfunc(EngFunc_WalkMove, iMonster, flIdealYaw, flStep, WALKMOVE_NORMAL))
        {
            //client_print(0,print_chat,"Try to Change Ideal Yaw... %..1f",get_gametime())
            new trHit = get_global_edict(GL_trace_ent);
            if(trHit > 0 && trHit <= g_iMaxPlayers)
            {
                if(MonsterAttack(iMonster, trHit))
                    return;
            }
            for(new Float:pushYaw = 10.0; pushYaw < 120.0; pushYaw += 10.0)
            {
                if(engfunc(EngFunc_WalkMove, iMonster, flIdealYaw + pushYaw * iRand, flStep, WALKMOVE_NORMAL))
                {
                    flIdealYaw += pushYaw * iRand;
                    Monster_UpdateAngles(iMonster, flIdealYaw);
                    
                    if(flIdealYaw > 360.0) 
                        flIdealYaw -= 360.0;
                    else 
                    if(flIdealYaw < 0.0) 
                        flIdealYaw += 360.0;

                    return;
                }
                else 
                if(engfunc(EngFunc_WalkMove, iMonster, flIdealYaw - pushYaw * iRand, flStep, WALKMOVE_NORMAL))
                {
                    flIdealYaw -= pushYaw * iRand;
                    Monster_UpdateAngles(iMonster, flIdealYaw);
                    
                    if(flIdealYaw > 360.0) 
                        flIdealYaw -= 360.0;
                    else 
                    if(flIdealYaw < 0.0) 
                        flIdealYaw += 360.0;

                    return;
                }
            }
        }
        //if(!CheckLocalMoveResult)client_print(0,print_chat,"ERRRO %..1f",get_gametime());
    }

    Monster_UpdateAngles(iMonster, flIdealYaw);
    //engfunc(EngFunc_SetOrigin, iMonster, vecOrigin);

}

Monster_MoveToEnemy(const iMonster, const iEnemy, const Float:flInterval)
{

    static Float:vecStart[3];
    pev(iMonster, pev_origin, vecStart);

    static Float:vecEnd[3];
    pev(iEnemy, pev_origin, vecEnd);

    static Float:vecLocation[3];
    xs_vec_copy(vecEnd, vecLocation);

    static Float:vecDirToPoint[3];

    new Float:flCheckDist = get_distance_f(vecLocation, vecStart);

    xs_vec_sub(vecLocation, vecStart, vecDirToPoint);
    xs_vec_normalize(vecDirToPoint, vecDirToPoint);
    xs_vec_mul_scalar(vecDirToPoint, flCheckDist, vecDirToPoint);
    xs_vec_add(vecStart, vecDirToPoint, vecDirToPoint);

    new CheckLocalMoveResult = Monster_CheckLocalMove(iMonster, vecStart, vecDirToPoint, iEnemy, flCheckDist);
    if ( CheckLocalMoveResult != LOCALMOVE_VALID )
        if (!FTriangulate(iMonster, vecStart, vecLocation, flCheckDist, iEnemy, vecEnd))
        {
            //pev(iEnemy, pev_origin, vecEnd);
            Monster_Move(iMonster, flInterval);
            //client_print(0,print_chat,"RANDOM WALK");
            return;
        }
        else
        {
            //client_print(0,print_chat,"TRIANGLE %..1f %..1f", vecEnd[0], vecEnd[1]);
        }
    else
    {
        //client_print(0,print_chat,"FREE PATH");
        pev(iEnemy, pev_origin, vecEnd);
    }

    pev(iMonster, pev_origin, vecStart);
    
    static Float:vecPoint[3]; 
    xs_vec_sub(vecEnd, vecStart, vecPoint);
    
    static Float:flYaw; 
    engfunc(EngFunc_VecToYaw, vecPoint, flYaw);

    Monster_Move2(iMonster, flInterval, flYaw);
}

bool:MonsterAttack(const iMonster, const iEnemy)
{
    if(scp_get_user_group(iEnemy) == GROUP_SCP) 
        return false;
    
    new Float:flGameTime = get_gametime();
    if(Monster_GetNextAbilityTime(iMonster) < flGameTime)
    {
        Monster_SetNextAbilityTime(iMonster, flGameTime + ABILITY1_TIME);
        Animation_SetAnim(iMonster, ABILITY1_ANIM, ABILITY1_SPEED, true);

        new bool:headShot = false;//;random_num(0, 6) == 0;
        set_pdata_int(iEnemy, m_LastHitGroup, headShot ? HIT_HEAD : HIT_GENERIC, XO_CBaseMonster);
        ExecuteHamB(Ham_TakeDamage, iEnemy, iMonster, iMonster, headShot ? ABILITY1_DAMAGE * 3 : ABILITY1_DAMAGE, ABILITY1_DAMAGETYPE);
        Monster_SetRageTime(iMonster, get_gametime() + MONSTER_RAGE_DURATION);
        SetMonsterEnemy(iMonster, iEnemy);
    }
    return true;
}


//*******************************************************
//*                                                     *
//* FIND THE WAY.                                       *
//*                                                     *
//*******************************************************
Monster_GetWayToPos(const iMonster, const Float:vecEnd[3], const iEnemy)
{
    static Float:vecOrigin[3];
    pev(iMonster, pev_origin, vecOrigin);

    static Float:vecLocation[3]; 
    xs_vec_copy(vecEnd, vecLocation);
    
    
    new Float:flCheckDist = get_distance_f(vecLocation, vecOrigin);

    static Float:vecDirToPoint[3];
    xs_vec_sub(vecLocation, vecOrigin, vecDirToPoint);

    xs_vec_normalize(vecDirToPoint, vecDirToPoint);
    xs_vec_mul_scalar(vecDirToPoint, flCheckDist, vecDirToPoint);
    xs_vec_add(vecOrigin, vecDirToPoint, vecDirToPoint);

    new CheckLocalMoveResult = Monster_CheckLocalMove(iMonster, vecOrigin, vecDirToPoint, iEnemy, flCheckDist);
    if ( CheckLocalMoveResult == LOCALMOVE_VALID){
        SetMonsterMoveLoc(iMonster, vecLocation);
        return true;
    }else{
        static Float:vecApex[3];
        if (FTriangulate(iMonster, vecOrigin, vecLocation, flCheckDist, iEnemy, vecApex)){
            SetMonsterMoveLoc(iMonster, vecApex);
            //client_print(0,print_chat,"[WAY CREATE]");
            return true;
        }
        /*else{
            if(CheckLocalMoveResult==LOCALMOVE_FRIENDLY){
                SetMonsterMoveLoc(iMonster,vecLocation);
                //client_print(0,print_chat,"[LOCAL FRIEND]");
                return true;
            }
            //else
                //client_print(0,print_chat,("[NO WAY]");
        }*/
    }
    return false;
}

Monster_CheckLocalMove(const iMonster, const Float:vecStart[3], const Float:vecEnd[3], const iTarget, & Float:pflDist = -1.0)
{
    new iReturn = LOCALMOVE_VALID;

    static Float:vecStartPos[3];
    pev(iMonster, pev_origin, vecStartPos);

    static Float:vecPoint[3];
    xs_vec_sub(vecEnd, vecStart, vecPoint);

    static Float:flYaw;
    engfunc(EngFunc_VecToYaw, vecPoint, flYaw);

    engfunc(EngFunc_SetOrigin, iMonster, vecStart);
    engfunc(EngFunc_DropToFloor, iMonster);

    new Float:flDist = xs_vec_len(vecPoint);

    // this loop takes single steps to the goal.
    static Float:stepSize, trHit;
    for (new Float:flStep = 0.0; flStep < flDist; flStep += 16.0)
    {
        stepSize = 16.0;
        if ((flStep + 16.0) >= (flDist - 1.0)){
            stepSize = (flDist - flStep) - 1.0;
            iReturn = LOCALMOVE_VALID;
            break;
        }
        if (!engfunc(EngFunc_WalkMove, iMonster, flYaw, stepSize, WALKMOVE_CHECKONLY)){

            // can't take the next step, fail!
            if (pflDist != -1.0)
                pflDist = flStep;

            trHit = get_global_edict(GL_trace_ent);
            if(trHit > 0){

                // if this step hits target ent, the move is legal
                if (iTarget && iTarget == trHit)
                    iReturn = LOCALMOVE_VALID;
                else
                // If we're going toward an entity, and we're almost getting there, it's OK.
                if(is_valid_ent(trHit) && IsMonster(trHit)){
//                    if ( pTarget && fabs( flDist - iStep ) < LOCAL_STEP_SIZE )
//                        fReturn = TRUE;
//                    else
                    if(!iTarget || GetMonsterEnemy(trHit) == iTarget)
                        iReturn = LOCALMOVE_FRIENDLY;
                    else
                        iReturn = LOCALMOVE_INVALID;
                }
                else
                    iReturn = LOCALMOVE_INVALID;
            }
            else
                iReturn = LOCALMOVE_INVALID;
            break;

        }
    }

    //DEBUG Z LOCATION
    /*if (iReturn == LOCALMOVE_VALID && (!iTarget || (pev(iTarget, pev_flags) & FL_ONGROUND)))
    {
        new Float:vecOrigin[3];pev(iMonster, pev_origin, vecOrigin);
        new Float:fabs=floatabs(vecEnd[2] - vecOrigin[2]);
        if (fabs >128.0)
        {
            //client_print(0,print_chat,"Z Invalid %..1f",fabs);
            iReturn = LOCALMOVE_INVALID_DONT_TRIANGULATE;
        }
    }*/

    // since we've actually moved the monster during the check, undo the move.
    engfunc(EngFunc_SetOrigin, iMonster, vecStartPos);

    return iReturn;
}

FTriangulate(const iMonster, const Float:vecStart[3], const Float:vecEnd[3], const Float:flDist, const iTarget, Float:vecApex[3])
{
    static Float:vecFarSide[3];// the spot that we'll move to after hitting the triangulated point, before moving on to our normal goal.
    pev(iMonster, pev_size, vecFarSide);

    new Float:sizeX = vecFarSide[0];

    if (sizeX < 24.0)
    {
        sizeX = 24.0;
    }
    else if (sizeX > 48.0)
    {
        sizeX = 48.0;
    }

    static Float:vecForward[3];
    xs_vec_sub(vecEnd, vecStart, vecForward);
    xs_vec_normalize(vecForward, vecForward);

    static Float:vecDir[3];
    xs_vec_cross(vecForward, Float:{0.0, 0.0, 1.0}, vecDir);

    // start checking right about where the object is, picking two equidistant starting points, one on
    // the left, one on the right. As we progress through the loop, we'll push these away from the obstacle,
    // hoping to find a way around on either side. pev->size.x is added to the ApexDist in order to help select
    // an apex point that insures that the monster is sufficiently past the obstacle before trying to turn back
    // onto its original course.

    static Float:vecLeft[3];// the spot we'll try to triangulate to on the left
    xs_vec_mul_scalar(vecDir, sizeX * 4.0, vecLeft);
    xs_vec_sub(vecStart, vecLeft, vecLeft);
    xs_vec_mul_scalar(vecForward, flDist + sizeX, vecFarSide);
    xs_vec_add(vecFarSide, vecLeft, vecLeft);


    static Float:vecRight[3];// the spot we'll try to triangulate to on the right
    xs_vec_mul_scalar(vecDir, sizeX * 4.0, vecRight);
    xs_vec_add(vecStart, vecRight, vecRight);
    xs_vec_mul_scalar(vecForward, flDist + sizeX, vecFarSide);
    xs_vec_add(vecFarSide, vecRight, vecRight);

    xs_vec_copy(vecEnd, vecFarSide);
    xs_vec_mul_scalar(vecDir, sizeX * 2.0, vecDir);

    for (new i = 0; i < 8; i++ )
    {
        if (Monster_CheckLocalMove(iMonster, vecStart, vecRight, iTarget) == LOCALMOVE_VALID)
        {
            if (Monster_CheckLocalMove(iMonster, vecRight, vecFarSide, iTarget) == LOCALMOVE_VALID)
            {
                xs_vec_copy(vecRight, vecApex);

                return 1;
            }
        }
        if (Monster_CheckLocalMove(iMonster, vecStart, vecLeft, iTarget) == LOCALMOVE_VALID)
        {
            if (Monster_CheckLocalMove(iMonster, vecLeft, vecFarSide, iTarget) == LOCALMOVE_VALID)
            {
                xs_vec_copy(vecLeft, vecApex);

                return 1;
            }
        }

        xs_vec_add(vecRight, vecDir, vecRight);
        xs_vec_sub(vecLeft, vecDir, vecLeft);
    }
    return 0;
}

//*******************************************************
//*                                                     *
//* Animation stuff.                                    *
//*                                                     *
//*******************************************************
enum
{
    mstudioseqdesc_label[32],        // Sequence label.
    mstudioseqdesc_numframes,        // Number of frames per sequence.
    Array:mstudioseqdesc_events,        // Handle to array with events.
    mstudioseqdesc
};
enum
{
    mstudioevent_frame,
    mstudioevent_event,
    mstudioevent_options[64],
    mstudioevent,
};
new g_Animations[SEQ_MAX][mstudioseqdesc];

bool:Animation_SetAnim(const iEntity, const iSequence, const Float:fFrameRate, const bool:bForce)
{
    if(!bForce && pev(iEntity, pev_sequence) == iSequence)
        return false;

    //client_print(0,print_chat,"CHANGE SEQUENCE: %i", iSequence);

    static bool:bLoops, Float:flGameTime, Float:flFramerate, Float:flGroundSpeed;

    set_pev(iEntity, pev_sequence, iSequence);
    set_pev(iEntity, pev_frame, 0.0);
    set_pev(iEntity, pev_framerate, fFrameRate);
    set_pev(iEntity, pev_animtime, (flGameTime = get_gametime()));

    lookup_sequence(iEntity, g_Animations[iSequence][mstudioseqdesc_label], flFramerate, bLoops, flGroundSpeed);

    set_pdata_int(iEntity, m_fSequenceFinished, 0, XO_CBaseAnimating);
    set_pdata_int(iEntity, m_fSequenceLoops, bLoops, XO_CBaseAnimating);

    set_pdata_float(iEntity, m_flFrameRate, flFramerate, XO_CBaseAnimating);
    set_pdata_float(iEntity, m_flGroundSpeed, flGroundSpeed, XO_CBaseAnimating);
    set_pdata_float(iEntity, m_flLastEventCheck, flGameTime, XO_CBaseAnimating);
    return true;
}

Animation_ParseSequences(const szModelPath[])
{
    new iFile = fopen(szModelPath, "rt");

    if (!iFile)
    {
        fclose(iFile);
        set_fail_state("Failed to parse monster model!");
    }

    new iNumSeq;
    new iSeqIndex;
    new iNumEvents;
    new iEventIndex;

    new EventDesc[mstudioevent];

    fseek(iFile, 164, SEEK_SET);
    fread(iFile, iNumSeq, BLOCK_INT);
    fread(iFile, iSeqIndex, BLOCK_INT);
    if (iNumSeq != SEQ_MAX)
    {
        fclose(iFile);
        server_print("Failed to parse monster model seq count! %i %i", iNumSeq, SEQ_MAX);
        set_fail_state("Failed to parse monster model seq count! %i %i", iNumSeq, SEQ_MAX);
    }


    for (new k, i = 0; i < iNumSeq; i++)
    {
        fseek(iFile, iSeqIndex  + 176 * i, SEEK_SET);
        fread_blocks(iFile, g_Animations[i][mstudioseqdesc_label], 32, BLOCK_CHAR);
        fseek(iFile, 16, SEEK_CUR);
        fread(iFile, iNumEvents, BLOCK_INT);
        fread(iFile, iEventIndex, BLOCK_INT);
        fread(iFile, g_Animations[i][mstudioseqdesc_numframes], BLOCK_INT);
        fseek(iFile, iEventIndex + 172 * i, SEEK_SET);
        for (k = 0; k < iNumEvents; k++)
        {
            if (g_Animations[i][mstudioseqdesc_events] == Invalid_Array) 
                g_Animations[i][mstudioseqdesc_events] = _:ArrayCreate(mstudioevent, 1);
            
            fseek(iFile, iEventIndex + 76 * k, SEEK_SET);
            fread(iFile, EventDesc[mstudioevent_frame], BLOCK_INT);
            fread(iFile, EventDesc[mstudioevent_event], BLOCK_INT);
            fseek(iFile, 4, SEEK_CUR);
            fread_blocks(iFile, EventDesc[mstudioevent_options], 64, BLOCK_CHAR);
            
            if (
                EventDesc[mstudioevent_event] == 5010
                || EventDesc[mstudioevent_event] == SCRIPT_EVENT_SOUND2
                || EventDesc[mstudioevent_event] == SCRIPT_EVENT_SOUND
                || EventDesc[mstudioevent_event] == SCRIPT_EVENT_SOUND_VOICE
                || EventDesc[mstudioevent_event] == SCRIPT_EVENT_SOUND_CLIENT
                || EventDesc[mstudioevent_event] == EVENT_STEPSOUND)
            {
                engfunc(EngFunc_PrecacheSound, EventDesc[mstudioevent_options]);
                //log_amx("Precache sound:%s", EventDesc[mstudioevent_options])
            }

            ArrayPushArray(g_Animations[i][mstudioseqdesc_events], EventDesc);
        }
    }
    fclose(iFile);

    /*
    for (new EventDesc[mstudioevent], k, i = 0; i < SEQ_MAX; i++)
    {
        log_amx("Sequance #%d:", i);
        log_amx(" --- Label:%s, frames:%d", g_Animations[i][mstudioseqdesc_label], g_Animations[i][mstudioseqdesc_numframes]);

        if (g_Animations[i][mstudioseqdesc_events])
        {
            for (k = 0; k < ArraySize(g_Animations[i][mstudioseqdesc_events]); k++)
            {
                ArrayGetArray(g_Animations[i][mstudioseqdesc_events], k, EventDesc);

                //log_amx("   Event #%d:%d, frame:%d, options:%s", k, EventDesc[mstudioevent_event], EventDesc[mstudioevent_frame], EventDesc[mstudioevent_options]);
            }
        }
        log_amx("");
    }*/
}

Float:Animation_StudioFrameAdvance(const iEntity,  Float:flInterval = 0.0)
{
    new Float:flTime = get_gametime();
    new Float:flAnimtime = entity_get_float(iEntity, EV_FL_animtime);
    if (flInterval == 0.0)
    {
        flInterval = flTime - flAnimtime;
        if (flInterval < 0.0)
        {
            set_pev(iEntity, pev_animtime, flTime);
            return 0.0;
        }
    }

    if (!flAnimtime) flInterval = 0.0;
    new iFrame = floatround(
        entity_get_float(iEntity, EV_FL_frame) + flInterval *
        get_pdata_float(iEntity, m_flFrameRate, XO_CBaseAnimating) *
        entity_get_float(iEntity, EV_FL_framerate)
    );

    if (iFrame < 0 || iFrame >= 256)
        if (get_pdata_int(iEntity, m_fSequenceLoops, XO_CBaseAnimating))
            iFrame -= (iFrame / 256) * 256;
        else
            iFrame = (iFrame < 0) ? 0 :255;

    if (!get_pdata_int(iEntity, m_fSequenceLoops, XO_CBaseAnimating) && iFrame == 255)
        flTime -= 0.05;// WTF?


    set_pev(iEntity, pev_frame, float(iFrame));
    set_pev(iEntity, pev_animtime, flTime);

    return flInterval;
}

Animation_DispatchAnimEvents(const iEntity, const Float:flInterval = 0.1)
{
    static iSequence;
    if ((iSequence = pev(iEntity, pev_sequence)) < 0 || iSequence >= SEQ_MAX)
    {
        //client_print(0,print_chat,"Sequence out of array");
        return;
    }
    
    if (g_Animations[iSequence][mstudioseqdesc_events] == Invalid_Array)
    {
        //client_print(0,print_chat,"Invalid sequence array");
        return;
    }

    new Float:flFrame = entity_get_float(iEntity, EV_FL_frame);
    new Float:flAnimtime = entity_get_float(iEntity, EV_FL_animtime);
    new Float:flFrameRate = get_pdata_float(iEntity, m_flFrameRate, XO_CBaseAnimating) * entity_get_float(iEntity, EV_FL_framerate);

    new iEnd = floatround(flFrame + flInterval * flFrameRate);
    new iStart = floatround(flFrame + (get_pdata_float(iEntity, m_flLastEventCheck, XO_CBaseAnimating) - flAnimtime) * flFrameRate);

    if (0 <= iEnd <= 256)
        set_pdata_int(iEntity, m_fSequenceFinished, 0, XO_CBaseAnimating);
    else
        set_pdata_int(iEntity, m_fSequenceFinished, 1, XO_CBaseAnimating);

    set_pdata_float(iEntity, m_flLastEventCheck, flAnimtime + flInterval, XO_CBaseAnimating);

    if (g_Animations[iSequence][mstudioseqdesc_numframes] <= 1)
        iStart = 0,
        iEnd = 1;
    else
    {
        iStart = (iStart * (g_Animations[iSequence][mstudioseqdesc_numframes] - 1)) / 256;
        iEnd = (iEnd * (g_Animations[iSequence][mstudioseqdesc_numframes] - 1)) / 256;
    }
    static iEvent, iArraySize, EventDesc[mstudioevent];
    for (iEvent = 0, iArraySize = ArraySize(g_Animations[iSequence][mstudioseqdesc_events]); iEvent < iArraySize ; iEvent++)
    {
        ArrayGetArray(g_Animations[iSequence][mstudioseqdesc_events], iEvent, EventDesc);
        if (iStart <= EventDesc[mstudioevent_frame] < iEnd)
            Animation_HandleAnimEvent(iEntity, EventDesc[mstudioevent_event], EventDesc[mstudioevent_options]);
    }
}



//*******************************************************
//*                                                     *
//* Utils.                                              *
//*                                                     *
//*******************************************************

Animation_HandleAnimEvent(const iEntity, const iEvent, const szEventsOptions[])
{
    //client_print(0,print_chat,"CALLEVENT:%s; ID:%i",szEventsOptions,iEvent);
    switch (iEvent)
    {
        case SCRIPT_EVENT_SOUND_CLIENT:{
            emit_sound(iEntity, CHAN_BODY, szEventsOptions, 1.0, ATTN_NORM, 0, PITCH_NORM);
        }
        case SCRIPT_EVENT_SOUND:
            emit_sound(iEntity, CHAN_BODY, szEventsOptions, 1.0, ATTN_NORM, 0, PITCH_NORM);

        case SCRIPT_EVENT_SOUND_VOICE:
            emit_sound(iEntity, CHAN_VOICE, szEventsOptions, 1.0, ATTN_IDLE, 0, PITCH_NORM);

        case SCRIPT_EVENT_SOUND2:
            emit_sound(iEntity, CHAN_BODY, szEventsOptions, 1.0, ATTN_NORM, 0, PITCH_NORM);
        case SCRIPT_EVENT_STEP:
            emit_sound(iEntity, CHAN_BODY, szEventsOptions, 1.0, ATTN_NORM, 0, PITCH_NORM);
            //emit_sound(iEntity, CHAN_BODY, random(2) == 0 ? "Zombi/boss_footstep_1.wav":"Zombi/boss_footstep_2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
        case 5010:
            emit_sound(iEntity, CHAN_BODY, szEventsOptions, 1.0, ATTN_NORM, 0, PITCH_NORM);
        case EVENT_STEPSOUND:
        {
            //client_print
            emit_sound(iEntity, CHAN_BODY, szEventsOptions, 1.0, ATTN_NORM, 0, PITCH_NORM);
            /*switch(random_num(0, 3))
            {
                case 0:emit_sound(iEntity, CHAN_BODY, "common/npc_step1.wav", 1.0, ATTN_IDLE , 0, PITCH_NORM);
                case 1:emit_sound(iEntity, CHAN_BODY, "common/npc_step2.wav", 1.0, ATTN_IDLE , 0, PITCH_NORM);
                case 2:emit_sound(iEntity, CHAN_BODY, "common/npc_step3.wav", 1.0, ATTN_IDLE , 0, PITCH_NORM);
                case 3:emit_sound(iEntity, CHAN_BODY, "common/npc_step4.wav", 1.0, ATTN_IDLE , 0, PITCH_NORM);
            }*/
        }
        default:
            Monster_HandleAnimEvent(iEntity, iEvent, szEventsOptions);
    }
}

Monster_HandleAnimEvent(const iEntity, const iEvent, const szEventsOptions[])
{
    #pragma unused szEventsOptions
    #pragma unused iEntity
    switch (iEvent)
    {
        default:
        {
            //client_print(0, print_chat, "Unhandled animation event %d for %s (Entity %i)", iEvent, MONSTER_CLASSNAME, iEntity);
        }
    }
}

Monster_UpdateAngles(const iMonster, const Float:flIdealYaw)
{
    SetMonsterAngle(iMonster, flIdealYaw);

    new Float:flAngles = Monster_GetBodyAngle(iMonster);
    new Float:flCurrentYaw = UTIL_AngleMod(flAngles);

    if (flCurrentYaw != flIdealYaw)
    {
        // new Float:flSpeed = /*(float)yawSpeed*/ 20.0/* * get_global_float(GL_frametime) * 10.0*/;

        #define MONSTER_TURNSPEED   5.0

        new Float:flMove = flIdealYaw - flCurrentYaw;

        if (flIdealYaw > flCurrentYaw)
        {
            if (flMove >= 180.0)
            {
                flMove = flMove - 360.0;
            }
        }
        else
        {
            if (flMove <= -180.0)
            {
                flMove = flMove + 360.0;
            }
        }

        if (flMove > 0.0)
        {
            if (flMove > MONSTER_TURNSPEED)
            {
                flMove = MONSTER_TURNSPEED;
            }
        }
        else
        {
            if (flMove < -MONSTER_TURNSPEED)
            {
                flMove = -MONSTER_TURNSPEED;
            }
        }

        flAngles = UTIL_AngleMod(flCurrentYaw + flMove);
        Monster_SetBodyAngle(iMonster, flAngles)
    }
}

stock Float:UTIL_AngleMod(Float:a)
{
    if (a < 0.0) a = a + 360.0 * ((a / 360.0) + 1.0);
    else if (a >= 360.0) a = a - 360.0 * ((a / 360.0));
    return a;
}


//=========================================================
// CheckEnemy - part of the Condition collection process,
// gets and stores data and conditions pertaining to a monster's
// enemy. Returns TRUE if Enemy LKP was updated.
//=========================================================

    //*******************************************************
    //*                                                     *
    //* Messages                                            *
    //*                                                     *
    //*******************************************************

#define MESSAGE_BEGIN(%0,%1,%2,%3)  engfunc(EngFunc_MessageBegin,%0,%1,%2,%3)
#define WRITE_COORD(%0)             engfunc(EngFunc_WriteCoord,%0)
#define WRITE_BYTE(%0)              write_byte(%0)
#define WRITE_SHORT(%0)             write_short(%0)
#define MESSAGE_END()               message_end()
#define MODEL_INDEX(%0)             engfunc(EngFunc_ModelIndex,%0)

stock MSG_Sparks(const Float:vecPos[3])
{
    MESSAGE_BEGIN(MSG_ALL, SVC_TEMPENTITY, vecPos, 0);
    WRITE_BYTE(TE_SPARKS);
    WRITE_COORD(vecPos[0]);
    WRITE_COORD(vecPos[1]);
    WRITE_COORD(vecPos[2]);
    MESSAGE_END();
}

stock MSG_BeamFollow(const iEntity, const iSprId, const iLife, const iWidth, const RGB[3], iAlpha)
{
    MESSAGE_BEGIN(MSG_BROADCAST, SVC_TEMPENTITY, {0.0, 0.0, 0.0}, 0);
    WRITE_BYTE(TE_BEAMFOLLOW);
    WRITE_SHORT(iEntity);
    WRITE_SHORT(iSprId);
    WRITE_BYTE(iLife);    //life
    WRITE_BYTE(iWidth);    //wiWdth
    WRITE_BYTE(RGB[0]);
    WRITE_BYTE(RGB[1]);
    WRITE_BYTE(RGB[2]);
    WRITE_BYTE(iAlpha);
    MESSAGE_END();
}

stock MSG_KillBeam(const iEntity)
{
    MESSAGE_BEGIN(MSG_BROADCAST, SVC_TEMPENTITY, {0.0, 0.0, 0.0}, 0);
    WRITE_BYTE( TE_KILLBEAM );
    WRITE_SHORT(iEntity);
    MESSAGE_END();
}

/*
UTIL_ScreenShake(const iEntity, const Float:flAmplitude, const Float:flFrequency, const Float:flDuration, const Float:flRadius)
{
    for (new Float:flLocalAmplitude, iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++ )
    {
        if (!is_user_connected(iPlayer) || ~pev(iPlayer, pev_flags) & FL_ONGROUND)
        {
            continue;
        }

        flLocalAmplitude = 0.0;

        if (flRadius <= 0.0 || entity_range(iEntity, iPlayer) < flRadius)
        {
            flLocalAmplitude = flAmplitude;
        }

        if (flLocalAmplitude)
        {
            static msgScreenShake;
            if (msgScreenShake || (msgScreenShake = get_user_msgid("ScreenShake")))
            {
                MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, msgScreenShake, {0.0, 0.0, 0.0}, iPlayer);
                WRITE_SHORT(FixedUnsigned16(flAmplitude, 1 << 12));
                WRITE_SHORT(FixedUnsigned16(flDuration, 1 << 12));
                WRITE_SHORT(FixedUnsigned16(flFrequency, 1 << 8));
                MESSAGE_END();
            }
        }
    }
}*/

stock MSG_ShockWave(const iSprId, const Float:vecPos[3], const iLife, const iWidth, const Float:flRadius, const Color[3])
{
    MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, vecPos, 0);
    WRITE_BYTE(TE_BEAMCYLINDER) // TE id
    WRITE_COORD(vecPos[0]);
    WRITE_COORD(vecPos[1]);
    WRITE_COORD(vecPos[2]);
    WRITE_COORD(vecPos[0]);
    WRITE_COORD(vecPos[1]);
    WRITE_COORD(vecPos[2] + flRadius);
    WRITE_SHORT(iSprId); // sprite
    WRITE_BYTE(0) // startframe
    WRITE_BYTE(0) // framerate
    WRITE_BYTE(iLife) // life (4)
    WRITE_BYTE(iWidth) // width (20)
    WRITE_BYTE(0) // noise
    WRITE_BYTE(Color[0]) // red
    WRITE_BYTE(Color[1]) // green
    WRITE_BYTE(Color[2]) // blue
    WRITE_BYTE(255) // brightness
    WRITE_BYTE(0) // speed
    MESSAGE_END()
}

stock FixedUnsigned16(const Float:flValue, const iScale)
{
    new iOutput = floatround(flValue * iScale);

    if (iOutput < 0)
    {
        iOutput = 0;
    }

    if (iOutput > 0xFFFF)
    {
        iOutput = 0xFFFF;
    }

    return iOutput;
}

stock UTIL_BloodDrips(const Float:vecSpot[3], const iBloodColor, Float:flAmount)
{
    if (iBloodColor == -1 || flAmount <= 0.0)
    {
        return;
    }

    flAmount *= 2;

    if (flAmount > 255.0)
    {
        flAmount = 255.0;
    }

    static iBloodIndex;
    static iBloodSprayIndex;

    if (!iBloodIndex)
    {
        iBloodIndex = MODEL_INDEX("sprites/blood.spr");
    }

    if (!iBloodSprayIndex)
    {
        iBloodSprayIndex = MODEL_INDEX("sprites/bloodspray.spr");
    }

    MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, vecSpot, 0);
    WRITE_BYTE(TE_BLOODSPRITE);
    WRITE_COORD(vecSpot[0]);
    WRITE_COORD(vecSpot[1]);
    WRITE_COORD(vecSpot[2]);
    WRITE_SHORT(iBloodSprayIndex);
    WRITE_SHORT(iBloodIndex);
    WRITE_BYTE(iBloodColor);
    WRITE_BYTE(min(max(3, floatround(flAmount) / 10), 16));
    MESSAGE_END();
}

stock FX_Line(Float:S1, Float:S2, Float:S3, Float:E1, Float:E2, Float:E3)
{
    static _mLaserBeam;
    if(!_mLaserBeam)
        _mLaserBeam = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr");

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMPOINTS);
    engfunc(EngFunc_WriteCoord, S1);
    engfunc(EngFunc_WriteCoord, S2);
    engfunc(EngFunc_WriteCoord, S3);
    engfunc(EngFunc_WriteCoord, E1);
    engfunc(EngFunc_WriteCoord, E2);
    engfunc(EngFunc_WriteCoord, E3);
    write_short(_mLaserBeam);
    write_byte(1);       // framestart
    write_byte(1);       // framerate
    write_byte(10);      // life in 0.1's
    write_byte(10);      // width
    write_byte(0);       // noise
    write_byte(0);       // r, g, b
    write_byte(255);     // r, g, b
    write_byte(0);       // r, g, b
    write_byte(255);     // brightness
    write_byte(0);       // speed
    message_end();
}



//*******************************************************
//*                                                     *
//* Stocks                                              *
//*                                                     *
//*******************************************************

stock Float:fm_get_user_speed(id)
{
    static Float:fVelocity[3];
    pev(id, pev_velocity, fVelocity);

    fVelocity[2] = 0.0;

    return vector_length(fVelocity);
}

stock bool:CheckLine(const Float:vecFrom[3], const Float:vecTo[3], const iMonster, const iTarget)
{
    static iTr;
    iTr = create_tr2();

    engfunc(EngFunc_TraceLine, vecFrom, vecTo, DONT_IGNORE_MONSTERS, iMonster, iTr);
    //engfunc(EngFunc_TraceHull, vecFrom, vecTo, IGNORE_MONSTERS, HULL_POINT, iMonster, iTr);

    static Float:flFraction;
    get_tr2(iTr, TR_flFraction, flFraction);

    static iHit;
    iHit = get_tr2(iTr, TR_pHit);

    free_tr2(iTr);
    if(flFraction == 1.0 || iHit == iTarget)
    {
        return true;
    }
    return false;
}

stock TraceBleed(const iPlayer, Float:fDamage, Float:vecDir[3], iTr, iBitsDamageType)
{
    new Float:vecTraceDir[3]
    new Float:fNoise
    new iCount, iBloodTr

    if (fDamage < 10)
    {
        fNoise = 0.1
        iCount = 1
    }
    else if (fDamage < 25)
    {
        fNoise = 0.2
        iCount = 2
    }
    else
    {
        fNoise = 0.3
        iCount = 4
    }

    for (new i = 0; i < iCount; i++)
    {
        xs_vec_mul_scalar(vecDir, -1.0, vecTraceDir)

        vecTraceDir[0] += random_float(-fNoise, fNoise)
        vecTraceDir[1] += random_float(-fNoise, fNoise)
        vecTraceDir[2] += random_float(-fNoise, fNoise)

        static Float:vecEndPos[3]
        get_tr2(iTr, TR_vecEndPos, vecEndPos)
        xs_vec_mul_scalar(vecTraceDir, -0.5, vecTraceDir)
        xs_vec_add(vecTraceDir, vecEndPos, vecTraceDir)
        engfunc(EngFunc_TraceLine, vecEndPos, vecTraceDir, IGNORE_MONSTERS, iPlayer, iBloodTr)

        static Float:flFraction
        get_tr2(iBloodTr, TR_flFraction, flFraction)

        if (flFraction != -1.0)
            BloodDecalTrace(iBloodTr, ExecuteHam(Ham_BloodColor, iPlayer))
    }
}

stock BloodDecalTrace(iTrace, iBloodColor)
{
    switch (random_num(0, 5))
    {
        case 0:DecalTrace(iTrace, engfunc(EngFunc_DecalIndex, (iBloodColor == BLOOD_COLOR_RED) ? "{blood1" :"{yblood1"))
        case 1:DecalTrace(iTrace, engfunc(EngFunc_DecalIndex, (iBloodColor == BLOOD_COLOR_RED) ? "{blood2" :"{yblood2"))
        case 2:DecalTrace(iTrace, engfunc(EngFunc_DecalIndex, (iBloodColor == BLOOD_COLOR_RED) ? "{blood3" :"{yblood3"))
        case 3:DecalTrace(iTrace, engfunc(EngFunc_DecalIndex, (iBloodColor == BLOOD_COLOR_RED) ? "{blood4" :"{yblood4"))
        case 4:DecalTrace(iTrace, engfunc(EngFunc_DecalIndex, (iBloodColor == BLOOD_COLOR_RED) ? "{blood5" :"{yblood5"))
        case 5:DecalTrace(iTrace, engfunc(EngFunc_DecalIndex, (iBloodColor == BLOOD_COLOR_RED) ? "{blood6" :"{yblood6"))
    }
}

stock DecalTrace(const iTrace, iDecalNumber)
{
    if (iDecalNumber < 0)
        return

    static Float:flFraction
    get_tr2(iTrace, TR_flFraction, flFraction)

    if (flFraction == 1.0)
        return

    new iHit = get_tr2(iTrace, TR_pHit)

    if (iHit > 0)
    {
        if ((pev(iHit, pev_solid) != SOLID_BSP && pev(iHit, pev_movetype) != MOVETYPE_PUSHSTEP))
            return
    }
    else
        iHit = 0

    new iMessage = TE_DECAL
    if (iHit != 0)
    {
        if (iDecalNumber > 255)
        {
            iDecalNumber -= 256
            iMessage = TE_DECALHIGH
        }
    }
    else
    {
        iMessage = TE_WORLDDECAL
        if (iDecalNumber > 255)
        {
            iDecalNumber -= 256
            iMessage = TE_WORLDDECALHIGH
        }
    }

    static Float:vecEndPos[3]
    get_tr2(iTrace, TR_vecEndPos, vecEndPos)

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(iMessage)
    engfunc(EngFunc_WriteCoord, vecEndPos[0])
    engfunc(EngFunc_WriteCoord, vecEndPos[1])
    engfunc(EngFunc_WriteCoord, vecEndPos[2])
    write_byte(iDecalNumber)
    if (iHit) write_short(iHit)
    message_end()
}
