#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <custom_weather>
#include <smart_effects>

//Звуки включения отключения ночного виденья
new const g_szSounds[][] =
{
    "sound/items/nvg_off.wav",
	"sound/items/nvg_on.wav"
}

//Уровень света
//new const g_szVisionLevel[] = "f";

//Радиус свечения
#define LIGHT_RADIUS 25.5

//Цвет свечения
#define LIGHT_COLOR_ZOMBIE {255, 0, 0}
#define LIGHT_COLOR_HUMAN {0, 0, 255}

new g_iBitUserVision, g_iBitUserHasVision, g_iEnt_Light[33] = {NULLENT, ...};

new g_iItemID;

public plugin_natives()
{
    register_native("zp_has_user_vision", "@zp_has_user_vision", true);
    register_native("zp_get_extra_item_vision", "@zp_get_extra_item_vision", true);
}
/**
    Наличие ночного видения у клиента

    @param id : Индекс клиента
    @return : > 0 - Есть ПНВ, 0 - нет ПНВ
 */
@zp_has_user_vision(id) return IsSetBit(g_iBitUserHasVision, id);

/**
    Индекс Extra Item ПНВ

    @return : индекс
 */
@zp_get_extra_item_vision() return g_iItemID;

public plugin_precache()
{
    register_plugin("[ZC] Addon Zombie NightFision", "1.0", "Docaner");

    for(new i = 0, iSize = sizeof g_szSounds; i < iSize; i++)
        precache_generic(g_szSounds[i]);

} 

public plugin_init()
{
    RegisterHookChain(RG_CSGameRules_RestartRound, "@RG__RestartRound_Pre", false);
    RegisterHookChain(RG_CBasePlayer_Killed, "@RG__Player_Killed_Post", true);
    register_clcmd("nightvision", "@CMD__NightVision");

    g_iItemID = zp_register_extra_item("Human Vision", 0, ZP_TEAM_HUMAN);
}

public client_disconnected(pPlayer)
    setVisionAccess(pPlayer, 0);

public zp_user_humanized_post(pPlayer, iSurvivor)
    setVisionAccess(pPlayer, iSurvivor);

@RG__RestartRound_Pre()
{
    for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
    {
        if(!is_user_alive(iPlayer) || !zp_get_user_zombie(iPlayer))
            continue;
        
        setVisionAccess(iPlayer, 0);
    }
}

@RG__Player_Killed_Post(const pVictim)
    setVisionAccess(pVictim, 0);

@CMD__NightVision(const pPlayer)
{
    if(!is_user_alive(pPlayer) || !IsSetBit(g_iBitUserHasVision, pPlayer))
        return PLUGIN_CONTINUE;
    
    SetVision(pPlayer, !GetVision(pPlayer));

    return PLUGIN_CONTINUE;
}

public zp_user_infected_post(iPlayer)
{
    setVisionAccess(iPlayer, 1);
}

public zp_extra_item_selected(iPlayer, iItem) 
{
	if(iItem == g_iItemID) 
	{
		setVisionAccess(iPlayer, 1);
	}

	return PLUGIN_CONTINUE;
}

/**
    Устанавливает ночное виденье

    @param pPlayer      Индекс игрока
    @param bValue       true - Включить, false - выключить
    @param bSilent       true - без звука, false - со звуком
 */
stock SetVision(const pPlayer = 0, bool:bValue = true, bool:bSilent = false)
{
    if(bValue)
    {
        //zc_set_lighting(pPlayer, g_szVisionLevel);
        //zc_set_fog(pPlayer, {255, 255, 255}, 0.0001);
        if(pPlayer) 
            SetBit(g_iBitUserVision, pPlayer)
        else
            g_iBitUserVision = -1;  
    }
    else
    {
        //zc_reset_lighting(pPlayer);
        //zc_reset_fog(pPlayer);

        if(pPlayer) 
            ClearBit(g_iBitUserVision, pPlayer)
        else
            g_iBitUserVision = 0;  
    }

    SetUserDLight(pPlayer, bValue);
    if(!bSilent) client_cmd(pPlayer, "spk ^"%s^"", g_szSounds[bValue]);
}

stock bool:GetVision(const pPlayer)
    return IsSetBit(g_iBitUserVision, pPlayer) ? true : false;


/**
    Даёт возможность устанавливать ПНВ

    @param pPlayer : индекс игрока
    @param iValue : 0 - забрать ПНВ, 1 - Выдать ПНВ
 */
stock setVisionAccess(const pPlayer, iValue)
{
    if(iValue) 
    {
        if(pPlayer)
            SetBit(g_iBitUserHasVision, pPlayer);
        else
            g_iBitUserHasVision = -1;
    }
    else 
    {
        if(pPlayer) 
            ClearBit(g_iBitUserHasVision, pPlayer);
        else 
            g_iBitUserHasVision = 0;

        SetVision(pPlayer, false, true);
    }
}


stock SetUserDLight(const pPlayer, bool:bValue)
{
    if(bValue)
    {
        if(pPlayer) EnableUserLight(pPlayer);
        else
        {
            for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
                if(is_user_connected(iPlayer)) EnableUserLight(iPlayer);
        }
    }
    else
    {
        if(pPlayer) DisableUserLight(pPlayer);
        else
        {
            for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
                DisableUserLight(iPlayer);
        }
    }
}

stock EnableUserLight(const pPlayer)
{
    if(!is_nullent(g_iEnt_Light[pPlayer]))
        return;

    g_iEnt_Light[pPlayer] = CreateLight(pPlayer);
}

stock DisableUserLight(const pPlayer)
{
    if(is_nullent(g_iEnt_Light[pPlayer]))
        return;

    rg_remove_ent(g_iEnt_Light[pPlayer]);
    g_iEnt_Light[pPlayer] = NULLENT;
}

stock CreateLight(const pPlayer)
{
    new pEnt = rg_create_entity("info_target");
    
    if(is_nullent(pEnt)) return NULLENT;

    set_entvar(pEnt, var_owner, pPlayer);
    set_entvar(pEnt, var_nextthink, get_gametime());

    SetThink(pEnt, "@RG__Think_DLight");

    return pEnt;
}

@RG__Think_DLight(const pEnt)
{
    new pPlayer = get_entvar(pEnt, var_owner); 
    new Float:vecOrigin[3]; get_entvar(pPlayer, var_origin, vecOrigin);

    //MSG_DLight(MSG_ONE_UNRELIABLE, pPlayer, vecOrigin, 25.5, {255, 215, 0}, 0.2, 0);
    //MSG_DLight(MSG_ONE_UNRELIABLE, pPlayer, vecOrigin, LIGHT_RADIUS, LIGHT_COLOR_ZOMBIE, 0.2, 0);
    MSG_DLight(MSG_ONE_UNRELIABLE, pPlayer, vecOrigin, LIGHT_RADIUS, zp_get_user_zombie(pPlayer) ? LIGHT_COLOR_ZOMBIE : LIGHT_COLOR_HUMAN, 0.2, 0);

    set_entvar(pEnt, var_nextthink, get_gametime() + 0.1);
}


/**
    Динамическое освещение

    @param iMsgType        Тип сообщения MSG_* (Инклюд message_consts.inc)
    @param pPlayer      Индекс клиента
    @param vecOrigin    Точка излучения света
    @param flRadius     Радиус освещения
    @param iColor       Цвет
    @param flTime       Время освещения
    @param iFadeSpeed   Скорость затухания

    @noreturn
 */
stock MSG_DLight(iMsgType, pPlayer, Float:vecOrigin[3], Float:flRadius, iColor[3], Float:flTime, iFadeSpeed)
{
    message_begin_f(iMsgType, SVC_TEMPENTITY, vecOrigin, pPlayer);
    write_byte(TE_DLIGHT);
    write_coord_f(vecOrigin[0]);
    write_coord_f(vecOrigin[1]);
    write_coord_f(vecOrigin[2]);
    write_byte(floatround(flRadius * 10));
    write_byte(iColor[0]);
    write_byte(iColor[1]);
    write_byte(iColor[2]);
    write_byte(floatround(flTime * 10));
    write_byte(iFadeSpeed);
    message_end();
}