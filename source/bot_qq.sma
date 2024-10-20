#include <amxmodx>
#include <reapi>
#include <fakemeta>

#define BOT_THINKDELAY 0.01
#define BOT_THINKKEY 213125 
#define BOT_THINKJOINTEAM 1312321

public plugin_init()
{
    register_plugin("FAKE BOTS", "1.0", "Docaner");

    register_clcmd("say qq", "@CMD_CreateFakeBot");
    register_clcmd("model_anim", "@CMD_ModelAnim")
}

public client_disconnected(id) {
    if(is_user_bot(id)) {
        remove_task(id+BOT_THINKKEY);
        remove_task(id+BOT_THINKJOINTEAM);
        remove_task(id+BOT_THINKKEY);
    }
}

@CMD_ModelAnim(id) {
    new szAnimName[64]; read_argv(1, szAnimName, charsmax(szAnimName));
    UTIL_PlayerAnimation(id, szAnimName);
}

/* -> Player Animation <- */
stock UTIL_PlayerAnimation( const pPlayer, const szAnim[ ], const Activity: iActivity = ACT_RANGE_ATTACK1 ) 
{
	new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
	if ( ( iAnimDesired = lookup_sequence( pPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed ) ) == -1 ) 
		iAnimDesired = 0;

	new Float: flGameTime = get_gametime( );

	UTIL_SetEntityAnim( pPlayer, iAnimDesired );

	set_member( pPlayer, m_fSequenceLoops, bLoops );
	set_member( pPlayer, m_fSequenceFinished, 0 );
	set_member( pPlayer, m_flFrameRate, flFrameRate );
	set_member( pPlayer, m_flGroundSpeed, flGroundSpeed );
	set_member( pPlayer, m_flLastEventCheck, flGameTime );
	set_member( pPlayer, m_Activity, iActivity );
	set_member( pPlayer, m_IdealActivity, iActivity );
	set_member( pPlayer, m_flLastFired, flGameTime );
}

stock UTIL_SetEntityAnim( const pEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0 )
{
	set_entvar( pEntity, var_frame, flFrame );
	set_entvar( pEntity, var_framerate, flFrameRate );
	set_entvar( pEntity, var_animtime, get_gametime( ) );
	set_entvar( pEntity, var_sequence, iSequence );
}

@CMD_CreateFakeBot(id)
{
    new iEnt = engfunc(EngFunc_CreateFakeClient, "BOT")
    
    if(!iEnt) 
    {
        client_print_color(id, id, "Невозможно добавить ботов (Полный сервер?)")
        return PLUGIN_HANDLED
    }
 
    engfunc(EngFunc_FreeEntPrivateData, iEnt)
    dllfunc( MetaFunc_CallGameEntity, "player", iEnt)
    applyBotSettings(iEnt);

    new szRejectReason[128];
    dllfunc(DLLFunc_ClientConnect, iEnt, "BOT", "127.0.0.1", szRejectReason)
    if(!is_user_connected(iEnt)) 
        return PLUGIN_HANDLED;
 
    dllfunc(DLLFunc_ClientPutInServer,iEnt)
    set_entvar(iEnt, var_spawnflags, get_entvar(iEnt, var_spawnflags) | FL_FAKECLIENT)
    set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_FAKECLIENT)
    dllfunc(DLLFunc_Spawn, iEnt);
 

    client_print_color(id, id, "Бот создан - ID: %d | NAME: BOT", iEnt);
    
    set_task(BOT_THINKDELAY, "@ThinkBot", iEnt+BOT_THINKKEY, _, _, "b");
    set_task(1.0, "@SetBotTeam", iEnt+BOT_THINKJOINTEAM);
    return PLUGIN_HANDLED;
}

@SetBotTeam(iEnt) {
    iEnt -= BOT_THINKJOINTEAM
    rg_set_user_team(iEnt, TEAM_CT);
    rg_join_team(iEnt, TEAM_CT);
    rg_round_respawn(iEnt)

}

@ThinkBot(iEnt) {
    iEnt -= BOT_THINKKEY;
    // client_print(0, print_chat, "BOT_THINK: %d", iEnt);
    engfunc( EngFunc_RunPlayerMove, iEnt, Float:{0.0,0.0,0.0}, 0.0, 0.0, 0.0, 0, 0, 100 )
}

applyBotSettings(id) 
{
    set_user_info( id, "rate", "3500" )
    set_user_info( id, "cl_updaterate", "25" )
    set_user_info( id, "cl_lw", "1" )
    set_user_info( id, "cl_lc", "1" )
    set_user_info( id, "cl_dlmax", "128" )
    set_user_info( id, "cl_righthand", "1" )
    set_user_info( id, "_vgui_menus", "0" )
    set_user_info( id, "_ah", "0" )
    set_user_info( id, "dm", "0" )
    set_user_info( id, "tracker", "0" )
    set_user_info( id, "friends", "0" )
    set_user_info( id, "*bot", "1" )
    set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FAKECLIENT )
    set_pev( id, pev_colormap, id )
}