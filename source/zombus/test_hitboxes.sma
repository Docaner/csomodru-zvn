public stock const PluginName[ ] =			"Plugin Name";
public stock const PluginVersion[ ] =		"1.0";
public stock const PluginAuthor[ ] =		"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <zp_stocks>

native zp_debug_show_bbox(iEnt, Float:flTime = 1.0, iWidth = 2);

// #define Vector3(%0) Float:%0[3]

new const NpcClassName[ ] = "npc_oberon";
new const NpcModel[ ] = "models/x_re/npc/npc_oberon.mdl";

/* ~ [ Plugin Settings ] ~ */
/* ~ [ Params ] ~ */
new gl_iszModelIndex;
new gl_szOberonBoss;

/* ~ [ Macroses ] ~ */
#define IsOberonBoss(%0)					bool: ( get_entvar( %0, var_impulse ) == gl_szOberonBoss )

/* ~ [ AMX Mod X ] ~ */
public plugin_precache( )
{
	gl_iszModelIndex = engfunc( EngFunc_PrecacheModel, NpcModel );
	gl_szOberonBoss = engfunc( EngFunc_AllocString, NpcClassName );
}

public plugin_init( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

	RegisterHam( Ham_BloodColor, "info_target", "Ham_CBaseMonster__BloodColor_Pre", false );
	RegisterHam( Ham_TraceBleed, "info_target", "Ham_CBaseMonster__TraceBleed_Pre", false );
	RegisterHam( Ham_TakeDamage, "info_target", "Ham_CBaseMonster__TakeDamage_Post", true );
	RegisterHam( Ham_TraceAttack, "info_target", "Ham_CBaseMonster__TraceAttack_Post", true );

	register_clcmd( "say npc", "ClientCommand__SpawnNPC" );
}

public ClientCommand__SpawnNPC( const pPlayer )
{
	new Vector3( vecOrigin );
	UTIL_GetEyePointAiming( pPlayer, 8192.0, vecOrigin );
	vecOrigin[ 2 ] += 100.0;

	UTIL_DropVectorToFloor( vecOrigin );

	COberonNPC__SpawnEntity( vecOrigin );
}

public Ham_CBaseMonster__BloodColor_Pre( const pMonster )
{
	if ( is_nullent( pMonster ) || !IsOberonBoss( pMonster ) )
		return HAM_IGNORED;

	SetHamReturnInteger( 195 );
	return HAM_SUPERCEDE;
}

public Ham_CBaseMonster__TraceBleed_Pre( const pMonster ) return ( !is_nullent( pMonster ) && IsOberonBoss( pMonster ) ) ? HAM_SUPERCEDE : HAM_IGNORED;

public Ham_CBaseMonster__TakeDamage_Post( const pMonster, const pInflictor, const pAttacker, const Float: flDamage, const bitsDamageType )
{
	if ( !IsOberonBoss( pMonster ) )
		return;

	client_print( pAttacker, print_center, "Health: %f / Damage: %f", Float: get_entvar( pMonster, var_health ), flDamage );
}

public Ham_CBaseMonster__TraceAttack_Post( this, idattacker, Float:damage, Float:direction[3], tracehandle, damagebits )
{
	if ( !IsOberonBoss( this ) )
		return;

	static const HITGROUPS_NAMES[ ][ ] = {
		"HIT_GENERIC",
		"HIT_HEAD",
		"HIT_CHEST",
		"HIT_STOMACH",
		"HIT_LEFTARM",
		"HIT_RIGHTARM",
		"HIT_LEFTLEG",
		"HIT_RIGHTLEG",
		"HIT_SHIELD"
	};

	server_print( "HIT: %s", HITGROUPS_NAMES[ get_tr2( tracehandle, TR_iHitgroup ) ] );
}

public COberonNPC__SpawnEntity( const Vector3( vecOrigin ) )
{
	new pEntity = rg_create_entity( "info_target" );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	set_entvar( pEntity, var_classname, "npc_oberon" );
	set_entvar( pEntity, var_impulse, gl_szOberonBoss );
	set_entvar( pEntity, var_solid, SOLID_BBOX );
	set_entvar( pEntity, var_movetype, MOVETYPE_PUSHSTEP );
	set_entvar( pEntity, var_takedamage, DAMAGE_AIM );
	set_entvar( pEntity, var_gamestate, 1 );
	set_entvar( pEntity, var_health, 100000.0 );
	set_entvar( pEntity, var_deadflag, DEAD_NO );
	set_entvar( pEntity, var_max_health, 100000.0 );
	set_entvar( pEntity, var_modelindex, gl_iszModelIndex );

	// engfunc( EngFunc_SetModel, pEntity, NpcModel );
	// engfunc( EngFunc_SetSize, pEntity, Float: { -32.0, -32.0, -285.0 }, Float: { 32.0, 32.0, 96.0 } );
	engfunc( EngFunc_SetSize, pEntity, Float: { -48.0, -48.0, -28.0 }, Float: { 48.0, 48.0, 112.0 } );
	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );

	zp_debug_show_bbox( pEntity );

	return pEntity;
}