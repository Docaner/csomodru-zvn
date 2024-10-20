#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <beams_reapi>
// #include <zp_stocks>
// #include <easy_profiler>

new const LaserSprite[ ] = "sprites/laserbeam.spr";

#define Vector3(%0) Float:%0[3]

new Vector3( gl_vecLaserStart );
new Vector3( gl_vecLaserEnd );
new gl_pLaser;

public plugin_init( )
{
	register_clcmd( "say p1", "ClientCommand__PointA" );
	register_clcmd( "say p2", "ClientCommand__PointB" );
	register_clcmd( "say l", "ClientCommand__SpawnLaser" );
	register_clcmd( "say d", "ClientCommand__Drop" );
}

public plugin_precache( )
{
	engfunc( EngFunc_PrecacheModel, LaserSprite );
	engfunc( EngFunc_PrecacheModel, "models/w_ak47.mdl" );
}

public ClientCommand__PointA( const pPlayer )
{
	UTIL_GetEyePointAiming( pPlayer, 8192.0, gl_vecLaserStart );
	gl_vecLaserStart[ 2 ] += 16.0;

	if ( gl_pLaser )
	{
		Beam_SetStartPos( gl_pLaser, gl_vecLaserStart );
	}
}

public ClientCommand__PointB( const pPlayer )
{
	UTIL_GetEyePointAiming( pPlayer, 8192.0, gl_vecLaserEnd );
	gl_vecLaserEnd[ 2 ] += 16.0;

	if ( gl_pLaser )
	{
		Beam_SetEndPos( gl_pLaser, gl_vecLaserEnd );
	}
}

public ClientCommand__SpawnLaser( const pPlayer )
{
	if ( !is_nullent( gl_pLaser ) )
	{
		UTIL_KillEntity( gl_pLaser );
		gl_pLaser = NULLENT;
	}

	gl_pLaser = Beam_Create( LaserSprite, 16.0 );
	if ( !gl_pLaser )
		return;

	Beam_PointsInit( gl_pLaser, gl_vecLaserStart, gl_vecLaserEnd );
	// Beam_SetColor( gl_pLaser, Float: { 255.0, 0.0, 0.0 } );

	set_entvar( gl_pLaser, var_nextthink, get_gametime( ) + 0.5 );
	SetThink( gl_pLaser, "CLaser__Think" );

	// ep_calibrate();
}

stock calculateInitialVelocity( Vector3( vecStart ), Vector3( vecEnd ), const Float: flTime, const Float: flFreeFall, Vector3( vecVelocity ) )
{
	new Vector3( vecFreeFall ); vecFreeFall[ 2 ] = -flFreeFall;

	vecVelocity[ 0 ] = ( vecEnd[ 0 ] - vecStart[ 0 ] - 0.5 * vecFreeFall[ 0 ] * flTime * flTime ) / flTime;
	vecVelocity[ 1 ] = ( vecEnd[ 1 ] - vecStart[ 1 ] - 0.5 * vecFreeFall[ 1 ] * flTime * flTime ) / flTime;
	vecVelocity[ 2 ] = ( vecEnd[ 2 ] - vecStart[ 2 ] - 0.5 * vecFreeFall[ 2 ] * flTime * flTime ) / flTime;
}

stock UTIL_GetSpeedVectorByGravity(const Float:vecStartPos[3], const Float:vecEndPos[3], const Float:flTime, Float:vecVelocity[3], const Float:flGravity = 800.0)
{
    new Float:vecGravity[3]; vecGravity[2] = -flGravity;

    for(new i = 0; i < 3; i++)
        vecVelocity[i] = (vecEndPos[i] - vecStartPos[i] - 0.5 * vecGravity[i] * flTime * flTime) / flTime;
}

// std::array<double, 3> calculateInitialVelocity(const std::array<double, 3>& r0,
//                                                const std::array<double, 3>& r1,
//                                                double t, double g) {
//     std::array<double, 3> v0;
    
//     // Ускорение свободного падения в виде вектора
//     std::array<double, 3> a = {0, -g, 0};
    
//     // Вычисление начальной скорости по компонентам
//     for (int i = 0; i < 3; i++) {
//         v0[i] = (r1[i] - r0[i] - 0.5 * a[i] * t * t) / t;
//     }
    
//     return v0;
// }

// int main() {
//     std::array<double, 3> r0 = {0.0, 0.0, 0.0};  // начальная точка
//     std::array<double, 3> r1 = {10.0, 10.0, 0.0}; // конечная точка
//     double t = 2.0;  // время в секундах
//     double g = 9.8;  // ускорение свободного падения

//     std::array<double, 3> v0 = calculateInitialVelocity(r0, r1, t, g);

//     std::cout << "Начальная скорость: (" << v0[0] << ", " << v0[1] << ", " << v0[2] << ")" << std::endl;

//     return 0;
// }

public ClientCommand__Drop( const pPlayer )
{
	new Float: flSpeed = xs_vec_distance( gl_vecLaserStart, gl_vecLaserEnd );

	new Vector3( vecVelocity );
	// calculateInitialVelocity( gl_vecLaserStart, gl_vecLaserEnd, 2.0, 800.0, vecVelocity );
	UTIL_GetSpeedVectorByGravity( gl_vecLaserStart, gl_vecLaserEnd, 2.0, vecVelocity, 800.0 );
	// vecVelocity[ 2 ] = 500.0;

	// UTIL_GetSpeedVector( gl_vecLaserStart, gl_vecLaserEnd, flSpeed, 1.0, vecVelocity );
	// vecVelocity[ 2 ] = 500.0;

	server_print( "%f %f %f / len: %f", vecVelocity[0],vecVelocity[1],vecVelocity[2], xs_vec_len(vecVelocity));

	new pEntity = rg_create_entity( "info_target" );
	if ( pEntity )
	{
		set_entvar( pEntity, var_solid, SOLID_TRIGGER );
		set_entvar( pEntity, var_movetype, MOVETYPE_TOSS );
		set_entvar( pEntity, var_velocity, vecVelocity );

		engfunc( EngFunc_SetOrigin, pEntity, gl_vecLaserStart );
		engfunc( EngFunc_SetModel, pEntity, "models/w_ak47.mdl" );
	}
}

public CLaser__Think( const pEntity )
{
	// ep_start();

	set_entvar( pEntity, var_nextthink, get_gametime( ) + 0.5 );

	static pTrace; pTrace = create_tr2( );
	static Vector3( vecStart );
	vecStart = gl_vecLaserStart;

	static pSkipEntity; pSkipEntity = pEntity;

	static iTracesCount; iTracesCount = MaxClients;
	static Float: flFraction;

	while ( iTracesCount-- )
	{
		engfunc( EngFunc_TraceLine, vecStart, gl_vecLaserEnd, DONT_IGNORE_MONSTERS, pSkipEntity, pTrace );

		get_tr2( pTrace, TR_flFraction, flFraction );

		if ( flFraction == 1.0 )
			break;
			
		get_tr2( pTrace, TR_vecEndPos, vecStart );

		pSkipEntity = get_tr2( pTrace, TR_pHit );
		if ( pSkipEntity == NULLENT )
			continue;

		// server_print( "pHit: %i", pSkipEntity );
	}

	free_tr2( pTrace );

	// UTIL_TE_DEBUGPOINTS( MSG_BROADCAST, gl_vecLaserStart, gl_vecLaserEnd, 5, 16, { 255, 0, 0 }, 255 );

	static Vector3( vecAbsMin ), Vector3( vecAbsMax );

	for ( new pPlayer = 1; pPlayer <= MaxClients; pPlayer++ )
	{
		if ( !is_user_alive( pPlayer ) )
			continue;

		get_entvar( pPlayer, var_absmin, vecAbsMin );
		get_entvar( pPlayer, var_absmax, vecAbsMax );

		// server_print( "[%n] start-end %i", pPlayer, UTIL_IsLineThroughCube( gl_vecLaserStart, gl_vecLaserEnd, vecAbsMin, vecAbsMax ) );
	}

	// ep_end(1, "Time is %.17f");
}

stock UTIL_GetEyePointAiming( const pPlayer, const Float: flDistance, Vector3( vecEndPos ), const iIgnoreId = 0/*DONT_IGNORE_MONSTERS*/ )
{
	new Vector3( vecStart ); UTIL_GetEyePosition( pPlayer, vecStart );
	new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );
	new Vector3( vecEnd ); xs_vec_add_scaled( vecStart, vecAiming, flDistance, vecEnd );

	engfunc( EngFunc_TraceLine, vecStart, vecEnd, iIgnoreId, pPlayer, 0 );
	get_tr2( 0, TR_vecEndPos, vecEndPos );

	return get_tr2( 0, TR_pHit );
}

/* -> Get player eye position <- */
stock UTIL_GetEyePosition( const pPlayer, Vector3( vecEyeLevel ) )
{
	new Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	new Vector3( vecViewOfs ); get_entvar( pPlayer, var_view_ofs, vecViewOfs );

	xs_vec_add( vecOrigin, vecViewOfs, vecEyeLevel );
}

/* -> Get Player vector Aiming <- */
stock UTIL_GetVectorAiming( const pPlayer, Vector3( vecAiming ) ) 
{
	new Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	new Vector3( vecPunchAngle ); get_entvar( pPlayer, var_punchangle, vecPunchAngle );

	xs_vec_add( vecViewAngle, vecPunchAngle, vecViewAngle );
	angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecAiming );
}

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity )
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );
}