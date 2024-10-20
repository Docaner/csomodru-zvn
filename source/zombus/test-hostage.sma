#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <xs>
#include <smart_effects>

new const playerModelOberon[] = "npc_oberon";

new const OBERON_REFERENCE[] = "hostage_entity";

#define IMPULSE_OBERON 1312343
new g_iModelIndex;

enum
{
    IDLE = 0,
    WALK,
    ATTACK_RHAND,
    ATTACK_LHAND,
    ATTACK_JUMP,
    ATTACK_BOMB,
    ATTACK_HOLE,
    IDLE_CLAWS,
    WALK_CLAWS,
    ATTACK_RHAND_CLAWS,
    ATTACK_LHAND_CLAWS,
    ATTACK_JUMP_CLAWS,
    ATTACK_BOMB_CLAWS,
    ATTACK_HOLE_CLAWS,
    SCENE_APPEAR,
    SCENE_CLAWS,
    SCENE_DEATH,
}

public plugin_precache() {
    g_iModelIndex = precache_model(fmt("models/player/%s/%s.mdl",playerModelOberon,playerModelOberon))
}

public plugin_init() {
    register_clcmd("testhost", "@ClCmd_TestHostage");
    RegisterHam(Ham_Touch, OBERON_REFERENCE, "@TouchHostage")
    RegisterHam(Ham_Use, OBERON_REFERENCE, "@UseHostage")
    RegisterHam(Ham_TakeDamage, OBERON_REFERENCE, "@OberonDamage", true);
    RegisterHam(Ham_Think, OBERON_REFERENCE, "@ThinkOberon", true);

    RegisterHookChain(RG_CBasePlayer_HintMessageEx, "@HintMessage");

    register_message(get_user_msgid("TextMsg"), "@Message_TextMsg");
}

@OberonDamage(iVictim, iInflictor, iAttacker, Float:flDamage, Damagebits) {
    client_print(0, print_chat, "iVictim: %d | iAttacker: %d | flDamage: %f | flHealth: %f", iVictim, iAttacker, flDamage, Float:get_entvar(iVictim, var_health));
    if(Float:get_entvar(iVictim, var_health) <= 0.0) {
        UTIL_SetEntityAnim(iVictim, SCENE_DEATH)
    }
}

/**
   TODO Блокировка DHUD-сообщений не работает
 */
new const g_szBlockHostageHUDMessages[][] = {
    "#Hint_rescue_the_hostages",
    "#Hint_press_use_so_hostage_will_follow",
    "#Hint_careful_around_hostages",
}
@HintMessage(const iPlayer, const message[], Float:duration, bool:bDisplayIfPlayerDead, bool:bOverride) {
    // client_print(0, print_chat, "iPlayer: %d | message: %s", iPlayer, message);

    for(new i; i < sizeof g_szBlockHostageHUDMessages; i++)
        if(strcmp(message, g_szBlockHostageHUDMessages[i]) == 0) {
            SetHookChainReturn(ATYPE_BOOL, false);
            return HC_BREAK;
        }
    
    return HC_CONTINUE;
}


/**
    Блокировка сообщений при ударе по заложнику и при его смерти
 */
new const g_szBlockHostageMessages[][] = {
    "#Injured_Hostage",
    "#Killed_Hostage",
}

@Message_TextMsg() {
    new szArg[32]; get_msg_arg_string(2, szArg, charsmax(szArg));

    for(new i; i < sizeof g_szBlockHostageMessages; i++)
        if(strcmp(szArg, g_szBlockHostageMessages[i]) == 0)
            return PLUGIN_HANDLED;
    
    return PLUGIN_CONTINUE;
}


@ClCmd_TestHostage(id) {
    new iEnt = rg_create_entity(OBERON_REFERENCE);
    new Float:vecOrigin[3]; get_entvar(id, var_origin, vecOrigin); vecOrigin[1] += 300.0;
    xs_vec_add(vecOrigin, Float:{300.0, 0.0, 0.0}, vecOrigin);
    engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);
    engfunc(EngFunc_SetSize, iEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
    engfunc(EngFunc_SetModel, iEnt, fmt("models/player/%s/%s.mdl",playerModelOberon,playerModelOberon))

    set_entvar(iEnt, var_impulse, IMPULSE_OBERON);

    set_entvar(iEnt, var_modelindex, g_iModelIndex);
    dllfunc(DLLFunc_Spawn, iEnt);

    
    get_entvar(id, var_origin, vecOrigin); vecOrigin[2] += 100.0;
    engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);
    engfunc(EngFunc_SetSize, iEnt, Float:{-40.0, -40.0, -40.0}, Float:{40.0, 40.0, 96.0});
    set_entvar(iEnt, var_velocity, Float:{0.0, 0.0, 0.0});
    UTIL_SetEntityAnim(iEnt, WALK)
}

/**
    Блокировка передвижения заложника при прикосновении к нему
 */
@TouchHostage(iEnt, iToucher) {
    if(get_entvar(iEnt, var_impulse) != IMPULSE_OBERON)
        return HAM_IGNORED;

    new Float:vecVelocity[3]; get_entvar(iEnt, var_velocity, vecVelocity);
    set_entvar(iEnt, var_velocity, Float:{0.0,0.0,0.0});
    
    return HAM_SUPERCEDE;
}

/**
    Блокировка приручения заложника
 */
@UseHostage(iEnt, iActivator) {
    if(get_entvar(iEnt, var_impulse) != IMPULSE_OBERON)
        return HAM_IGNORED;

    return HAM_SUPERCEDE;
}

@ThinkOberon(iEnt) {
    if(get_entvar(iEnt, var_impulse) != IMPULSE_OBERON)
        return HAM_IGNORED;

    client_print(0, print_chat, "%d think ONDEGROUND", get_entvar(iEnt, var_flags));
    if(get_entvar(iEnt, var_flags) & FL_ONGROUND)
    {
        client_print(0, print_chat, "%d think ONDEGROUND", iEnt);
        new Float:vecVelocity[3]; get_entvar(iEnt, var_velocity, vecVelocity);
        set_entvar(iEnt, var_velocity, Float:{100.0, 100.0, 100.0});
    }

    return HAM_IGNORED;
}