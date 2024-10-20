public stock const PluginName[ ] =			"[NPC] Fallen Titan";
public stock const PluginVersion[ ] =		"1.00";
public stock const PluginAuthor[ ] =		"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <xs>

#include <zp_stocks>

native zp_debug_show_bbox(iEnt, Float:flTime = 1.0, iWidth = 2);

/* ~ [ Plugin Settings ] ~ */

/* ~ [ Entity: Fallen Titan ] ~ */
new const EntityNPCReference[ ] =			"info_target";
new const EntityNPCClassName[ ] =			"npc_fallen_titan";
new const EntityNPCModel[ ] =				"models/x_re/npc/zbs_bossl_big07.mdl";
const Float: EntityNPCHealth =				500.0;

const Float: EntityNPCTurnSpeed =			25.0; // 35.0
const Float: EntityNPCMoveSpeed =			50.0;
const Float: EntityNPCFindNextEnemy =		15.0;
const Float: EntityNPCAttackDistance =		128.0;
const Float: EntityNPCFindDistance =		2048.0;

const Float: EntityNPCNextThink =			0.1;
const EntityNPCBloodColor =					BLOOD_COLOR_RED;

/* ~ [ Params ] ~ */
new gl_iszFallenTitanKey;

enum {
	ModelIndex_TitanModel,

	ModelIndex_List
};
new gl_iszModelIndex[ ModelIndex_List ];

enum {
	EntityAnim_Appear1 = 1, // 1.1
	EntityAnim_Appear2, // 0.93
	EntityAnim_Appear3, // 6.4
	EntityAnim_Howling, // 4.7
	EntityAnim_Idle, // 3.4
	EntityAnim_Walk, // 4.8
	EntityAnim_Run, // 3.0
	EntityAnim_Dash_Ready, // 1.3
	EntityAnim_Dash, // 0.63
	EntityAnim_Dash_End, // 1.8
	EntityAnim_Attack1, // 3.7 hit 1.47
	EntityAnim_Attack2, // 3.8 hit 1.03
	EntityAnim_Cannon_Ready, // 1.5
	EntityAnim_Cannon1, // 1.3
	EntityAnim_Cannon_End, // 1.5
	EntityAnim_Cannon2, // 6.5
	EntityAnim_LandMine1, // 4.9
	EntityAnim_LandMine2, // 4.7
	EntityAnim_Death // 13.0
};

/* ~ [ Macroses ] ~ */
#define IsAliveMonster(%0)					bool: ( get_entvar( %0, var_deadflag ) == DEAD_NO )
#define IsFallenTitan(%0)					bool: ( get_entvar( %0, var_impulse ) == gl_iszFallenTitanKey )

#define var_next_attack						var_fuser1
#define var_next_enemy						var_fuser2

/* ~ [ AMX Mod X ] ~ */
public plugin_precache( )
{
	gl_iszModelIndex[ ModelIndex_TitanModel ] = engfunc( EngFunc_PrecacheModel, EntityNPCModel );
	gl_iszFallenTitanKey = engfunc( EngFunc_AllocString, EntityNPCClassName );
}

public plugin_init( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

	RegisterHam( Ham_Killed, EntityNPCReference, "Ham_CBaseMonster__Killed_Pre", false );
	RegisterHam( Ham_Classify, EntityNPCReference, "Ham_CBaseMonster__Classify_Pre", false );
	RegisterHam( Ham_BloodColor, EntityNPCReference, "Ham_CBaseMonster__BloodColor_Pre", false );
	RegisterHam( Ham_TraceBleed, EntityNPCReference, "Ham_CBaseMonster__TraceBleed_Pre", false );
	RegisterHam( Ham_TakeDamage, EntityNPCReference, "Ham_CBaseMonster__TakeDamage_Post", true );

	register_clcmd( "say ft", "ClientCommand__FallenTitan" );
}

public ClientCommand__FallenTitan( const pPlayer )
{
	new Vector3( vecEndPos ); UTIL_GetEyePointAiming( pPlayer, 2048.0, vecEndPos );

	if ( engfunc( EngFunc_PointContents, vecEndPos ) == CONTENTS_SKY )
	{
		client_print( pPlayer, print_center, "В небе нельзя заспавнить" );
		return PLUGIN_HANDLED;
	}

	if ( !CFallenTitan__SpawnEntity( vecEndPos ) )
		client_print( pPlayer, print_center, "Не удалось создать NPC" );

	return PLUGIN_HANDLED;
}

public Ham_CBaseMonster__Killed_Pre( const pMonster, const pAttacker, const iShouldGIB )
{
	if ( !IsFallenTitan( pMonster ) )
		return HAM_IGNORED;

	if ( !IsAliveMonster( pMonster ) )
		return HAM_SUPERCEDE;

	set_entvar( pMonster, var_solid, SOLID_NOT );
	set_entvar( pMonster, var_movetype, MOVETYPE_NONE );
	set_entvar( pMonster, var_deadflag, DEAD_DYING );
	set_entvar( pMonster, var_flags, get_entvar( pMonster, var_flags ) & ~FL_MONSTER );

	set_entvar( pMonster, var_rendermode, kRenderTransTexture );
	set_entvar( pMonster, var_renderamt, 255.0 );

	UTIL_SetEntityAnim( pMonster, EntityAnim_Death );

	SetThink( pMonster, "CFallenTitan__DeathThink" );
	set_entvar( pMonster, var_nextthink, get_gametime( ) + 13.0 );

	return HAM_SUPERCEDE;
}

public Ham_CBaseMonster__Classify_Pre( const pMonster )
{
	if ( is_nullent( pMonster ) || !IsFallenTitan( pMonster ) )
		return HAM_IGNORED;
	
	SetHamReturnInteger( CLASS_ALIEN_MONSTER );
	return HAM_OVERRIDE;
}

public Ham_CBaseMonster__BloodColor_Pre( const pMonster )
{
	if ( is_nullent( pMonster ) || !IsFallenTitan( pMonster ) )
		return HAM_IGNORED;

	SetHamReturnInteger( EntityNPCBloodColor );
	return HAM_SUPERCEDE;
}

public Ham_CBaseMonster__TraceBleed_Pre( const pMonster ) return ( !is_nullent( pMonster ) && IsFallenTitan( pMonster ) ) ? HAM_SUPERCEDE : HAM_IGNORED;

public Ham_CBaseMonster__TakeDamage_Post( const pMonster, const pInflictor, const pAttacker, const Float: flDamage, const bitsDamageType )
{
	if ( !IsFallenTitan( pMonster ) )
		return;

	client_print( pAttacker, print_center, "Health: %f / Damage: %f", Float: get_entvar( pMonster, var_health ), flDamage );
}

public CFallenTitan__SpawnEntity( Vector3( vecOrigin ) )
{
	new pMonster = rg_create_entity( EntityNPCReference );
	if ( is_nullent( pMonster ) )
		return NULLENT;

	vecOrigin[ 2 ] += 32.0;

	set_entvar( pMonster, var_classname, EntityNPCClassName );
	set_entvar( pMonster, var_solid, SOLID_BBOX );
	set_entvar( pMonster, var_movetype, MOVETYPE_TOSS );
	set_entvar( pMonster, var_takedamage, DAMAGE_NO );
	set_entvar( pMonster, var_impulse, gl_iszFallenTitanKey );
	set_entvar( pMonster, var_flags, FL_MONSTER );
	set_entvar( pMonster, var_deadflag, DEAD_NO );
	set_entvar( pMonster, var_health, EntityNPCHealth );
	set_entvar( pMonster, var_max_health, EntityNPCHealth );
	set_entvar( pMonster, var_modelindex, gl_iszModelIndex[ ModelIndex_TitanModel ] );

	// engfunc( EngFunc_SetModel, pMonster, EntityNPCModel );
	engfunc( EngFunc_SetSize, pMonster, Float: { -48.0, -48.0, -28.0 }, Float: { 48.0, 48.0, 112.0 } );
	engfunc( EngFunc_SetOrigin, pMonster, vecOrigin );

	zp_debug_show_bbox( pMonster, 10.0, 5 );

	UTIL_SetEntityAnim( pMonster, EntityAnim_Idle );

	SetThink( pMonster, "CFallenTitan__Start" );
	set_entvar( pMonster, var_nextthink, get_gametime( ) + 1.0 );

	return pMonster;
}

public CFallenTitan__Think( const pMonster )
{
	if ( !IsAliveMonster( pMonster ) )
	{
		SetThink( pMonster, "" );
		return;
	}

	static Float: flGameTime; flGameTime = get_gametime( );
	set_entvar( pMonster, var_nextthink, flGameTime + EntityNPCNextThink );

	CFallenTitan__FindEnemy( pMonster );

	if ( get_entvar( pMonster, var_enemy ) )
		CFallenTitan__Move( pMonster );
	else
		UTIL_SetEntityAnim( pMonster, EntityAnim_Idle );
}

public CFallenTitan__Start( const pMonster )
{
	SetThink( pMonster, "CFallenTitan__Think" );

	set_entvar( pMonster, var_takedamage, DAMAGE_AIM );
	set_entvar( pMonster, var_nextthink, get_gametime( ) );
}

public CFallenTitan__DeathThink( const pMonster )
{
	static Float: flGameTime; flGameTime = get_gametime( );
	set_entvar( pMonster, var_nextthink, flGameTime + EntityNPCNextThink );

	static Float: flRenderAmt; flRenderAmt = get_entvar( pMonster, var_renderamt );
	if ( ( flRenderAmt -= 10.0 ) && flRenderAmt < 10.0 )
	{
		UTIL_KillEntity( pMonster );
		return;
	}

	set_entvar( pMonster, var_renderamt, flRenderAmt );
}

public CFallenTitan__Move( const pMonster )
{
	static Vector3( vecTemp );
	static Vector3( vecOrigin ); get_entvar( pMonster, var_origin, vecOrigin );
	static Vector3( vecAngles ); get_entvar( pMonster, var_angles, vecAngles );
	static Vector3( vecEndPos ); get_entvar( pMonster, var_endpos, vecEndPos );

	xs_vec_sub( vecEndPos, vecOrigin, vecTemp );

	static Float: flIdealYaw; engfunc( EngFunc_VecToYaw, vecTemp, flIdealYaw );
	static Float: flCurrentYaw; flCurrentYaw = UTIL_AngleMod( vecAngles[ 1 ] );

	if ( flCurrentYaw != flIdealYaw )
	{
		static Float: flSpeed; flSpeed = EntityNPCTurnSpeed;
		static Float: flMove; flMove = flIdealYaw - flCurrentYaw;

		if ( flIdealYaw > flCurrentYaw )
		{
			if ( flMove >= 180.0 )
				flMove = flMove - 360.0;
		}
		else
		{
			if ( flMove <= -180.0 )
				flMove = flMove + 360.0;
		}
		
		if ( flMove > 0.0 )
		{
			if ( flMove > flSpeed )
				flMove = flSpeed;
		}
		else
		{
			if ( flMove < -flSpeed )
				flMove = -flSpeed;
		}
		
		vecAngles[ 1 ] = UTIL_AngleMod( flCurrentYaw + flMove );
		set_entvar( pMonster, var_angles, vecAngles );
	}

	if ( !xs_vec_len( vecEndPos ) )
		return;

	static Float: flGameTime; flGameTime = get_gametime( );
	if ( Float: get_entvar( pMonster, var_next_attack ) >= flGameTime )
		return;

	UTIL_SetEntityAnim( pMonster, EntityAnim_Walk );
	// engfunc( EngFunc_MoveToOrigin, pMonster, vecEndPos, 10.0, 3 );
}

public CFallenTitan__FindEnemy( const pMonster )
{
	static pEnemy, bool: bFindTarget;
	bFindTarget = false;

	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flNextEnemy; flNextEnemy = get_entvar( pMonster, var_next_enemy );
	if ( flNextEnemy == 0.0 || flNextEnemy < flGameTime )
		bFindTarget = true;

	if ( !( pEnemy = get_entvar( pMonster, var_enemy ) ) && !( pEnemy = CFallenTitan__FindBestEnemy( pMonster, EntityNPCFindDistance ) ) )
	{
		set_entvar( pMonster, var_enemy, 0 );
		return;
	}

	if ( IsUserValid( pEnemy ) )
		CFallenTitan__CheckEnemy( pMonster, pEnemy );
	else
		pEnemy = CFallenTitan__FindBestEnemy( pMonster, EntityNPCFindDistance );

	if ( UTIL_GetEntitiesDistance( pMonster, pEnemy ) > 768.0 )
		bFindTarget = true;

	if ( bFindTarget )
	{
		new pNewEnemy = CFallenTitan__FindBestEnemy( pMonster, EntityNPCFindDistance );
		if ( pNewEnemy && pNewEnemy != pEnemy )
			pEnemy = pNewEnemy;
	}

	if ( flNextEnemy < flGameTime )
		set_entvar( pMonster, var_next_enemy, flGameTime + EntityNPCFindNextEnemy );

	static Vector3( vecEnemyPos ); get_entvar( pEnemy, var_origin, vecEnemyPos );

	set_entvar( pMonster, var_endpos, vecEnemyPos );
	set_entvar( pMonster, var_enemy, pEnemy );
}

public CFallenTitan__FindBestEnemy( const pMonster, Float: flDistance )
{
	new pEnemy = NULLENT;
	new Float: flCurrentDistance;
	new Vector3( vecOrigin ); get_entvar( pMonster, var_origin, vecOrigin );

	for ( new pPlayer = 1, Vector3( vecEnemyPos ); pPlayer <= MaxClients; pPlayer++ )
	{
		if ( !is_user_alive( pPlayer ) )
			continue;

		if ( get_entvar( pPlayer, var_takedamage ) == DAMAGE_NO )
			continue;

		if ( !fm_is_ent_visible( pMonster, pPlayer ) )
			continue;

		get_entvar( pPlayer, var_origin, vecEnemyPos );
		flCurrentDistance = xs_vec_distance_2d( vecOrigin, vecEnemyPos );
		if ( flCurrentDistance < flDistance )
		{
			flDistance = flCurrentDistance;
			pEnemy = pPlayer;
		}
	}

	return pEnemy;
}

public CFallenTitan__CheckEnemy( const pMonster, const pEnemy )
{
	static Vector3( vecDirection );
	static Vector3( vecOrigin ); get_entvar( pMonster, var_origin, vecOrigin );
	static Vector3( vecEnemyPos ); get_entvar( pEnemy, var_origin, vecEnemyPos );

	xs_vec_sub( vecEnemyPos, vecOrigin, vecDirection );
	xs_vec_normalize( vecDirection, vecDirection );

	static Vector3( vecAngles ); get_entvar( pMonster, var_angles, vecAngles );
	static Vector3( vecForward ); angle_vector( vecAngles, ANGLEVECTOR_FORWARD, vecForward );

	CFallenTitan__CheckAttack( pMonster, pEnemy, xs_vec_dot( vecDirection, vecForward ), xs_vec_distance( vecEnemyPos, vecOrigin ) );
}

public CFallenTitan__CheckAttack( const pMonster, const pEnemy, const Float: flDot, const Float: flDistance )
{
	static Float: flGameTime; flGameTime = get_gametime( );
	if ( Float: get_entvar( pMonster, var_next_attack ) >= flGameTime )
		return;

	// server_print( "flDot: %f, flDistance: %f", flDot, flDistance );
	if ( flDot >= 0.7 && flDistance <= EntityNPCAttackDistance )
	{
		// server_print( "attack" );
		// damage

		UTIL_SetEntityAnim( pMonster, EntityAnim_Attack1 );
		set_entvar( pMonster, var_next_attack, flGameTime + 3.7 );
		set_entvar( pMonster, var_next_enemy, 0.0 );
	}
}