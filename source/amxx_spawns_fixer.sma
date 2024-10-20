#include < amxmodx >
#include < hamsandwich >
#include < fakemeta >
#include < reapi >
#include < xs >

#pragma semicolon 1

#define TEAM_SPAWNPOINTS_COUNT			32

public plugin_init( )
{
	register_plugin( "Spawns Fixer", "1.3.3.7.", "fl0wer" );

	AddSpawnPoints( "info_player_deathmatch" );
	AddSpawnPoints( "info_player_start" );
}


AddSpawnPoints( const sClassname[ ] )
{
	new Float: vecOrigin[ 3 ];
	new Float: vecAngles[ 3 ];

	new Float: vecOriginLast[ 2 ];
	new Float: vecMidOrigin[ 2 ];
	new Float: vecMidAngles[ 3 ];

	new Array: aSpawnPoints = ArrayCreate( 1 );

	new iSpot = MaxClients;

	while( ( iSpot = rg_find_ent_by_class( iSpot, sClassname, true ) ) > 0 )
	{
		ArrayPushCell( aSpawnPoints, iSpot );

		get_entvar( iSpot, var_origin, vecOrigin );
		get_entvar( iSpot, var_angles, vecAngles );

		//console_print(0, "ORIG (%s) - ID %d | vecOrigin %f %f %f | vecAngles %f %f %f", sClassname, iSpot, vecOrigin[0], vecOrigin[1], vecOrigin[2], vecAngles[0], vecAngles[1], vecAngles[2]);

		vecMidOrigin[ 0 ] += vecOrigin[ 0 ] - vecOriginLast[ 0 ];
		vecMidOrigin[ 1 ] += vecOrigin[ 1 ] - vecOriginLast[ 1 ];

		vecMidAngles[ 0 ] += vecAngles[ 0 ];
		vecMidAngles[ 1 ] += vecAngles[ 1 ];

		vecOriginLast[ 0 ] = vecOrigin[ 0 ];
		vecOriginLast[ 1 ] = vecOrigin[ 1 ];
	}

	new iSpotsCount = ArraySize( aSpawnPoints );

	if( iSpotsCount >= TEAM_SPAWNPOINTS_COUNT )
		return;

	new Float: flSpotsCount = float( iSpotsCount );

	vecMidOrigin[ 0 ] /= flSpotsCount;
	vecMidOrigin[ 1 ] /= flSpotsCount;
	//console_print(0, "vecMidOrigin: %f %f", vecMidOrigin[0], vecMidOrigin[1]);


	vecMidAngles[ 0 ] /= flSpotsCount;
	vecMidAngles[ 1 ] /= flSpotsCount;
	//console_print(0, "vecMidAngles: %f %f", vecMidAngles[0], vecMidAngles[1]);

	new iAllSpawns = iSpotsCount;
	new Float: flDistance = floatsqroot( vecMidOrigin[ 0 ] * vecMidOrigin[ 0 ] + vecMidOrigin[ 1 ] * vecMidOrigin[ 1 ] );
	//console_print(0, "flDistance: %f", flDistance);

	for( new iIndex = 0; iIndex < ArraySize( aSpawnPoints ); iIndex++ )
	{
		iSpot = ArrayGetCell( aSpawnPoints, iIndex );

		get_entvar( iSpot, var_origin, vecOrigin );

		iSpot = CreateSpawnPoint( sClassname, vecOrigin, vecMidAngles, flDistance, aSpawnPoints );

		if( iSpot == NULLENT )
			continue;

		ArrayPushCell( aSpawnPoints, iSpot );

		if( ++iAllSpawns >= TEAM_SPAWNPOINTS_COUNT )
			break;
	}

	ArrayDestroy( aSpawnPoints );

	if( iAllSpawns >= TEAM_SPAWNPOINTS_COUNT )
		return;

	server_print( "FAILED: not all ^"%s^". Added %d", sClassname, TEAM_SPAWNPOINTS_COUNT - iAllSpawns );
}

CreateSpawnPoint( const sClassname[ ], Float: vecOrigin[ 3 ], Float: vecAngles[ 3 ], Float: flDistance, Array:aSpawnPoints )
{
	new Float: vecOffset[ 8 ][ 2 ] = { { -1.0, 0.0 }, { 1.0, 0.0 }, { 0.0, -1.0 }, { 0.0, 1.0 }, { -1.0, -1.0 }, { 1.0, 1.0 }, { -1.0, 1.0 }, { 1.0, -1.0 } };

	new Float: flRange;
	new Float: flFraction;
	new Float: vecSelect[ 3 ];

	new Float: flCorrectDist = floatclamp(flDistance, 64.0, 128.0);

	vecSelect[ 2 ] = vecOrigin[ 2 ];

	for( new iDeepLevel = 0, j; iDeepLevel <= 4; iDeepLevel++ )
	{
		switch( iDeepLevel )
		{
			case 0: flRange = flCorrectDist;
			case 1: flRange = flCorrectDist * 0.5;
			case 2: flRange = flCorrectDist * 1.5;
			case 3: flRange = flCorrectDist * 2.0;
			case 4: flRange = flCorrectDist * 2.5;
		}

		for( j = 0; j < sizeof vecOffset; j++ )
		{
			vecSelect[ 0 ] = vecOrigin[ 0 ] + flRange * vecOffset[ j ][ 0 ];
			vecSelect[ 1 ] = vecOrigin[ 1 ] + flRange * vecOffset[ j ][ 1 ];

			engfunc( EngFunc_TraceLine, vecOrigin, vecSelect, DONT_IGNORE_MONSTERS, -1, 0 );

			get_tr2( 0, TR_flFraction, flFraction );

			if( flFraction != 1.0 )
				continue;

			engfunc( EngFunc_TraceHull, vecSelect, vecSelect, 0, HULL_HUMAN, -1, 0 );

			if( get_tr2( 0, TR_StartSolid ) || get_tr2( 0, TR_AllSolid ) || !get_tr2( 0, TR_InOpen ) )
				continue;

			if( findCloseSpawn(aSpawnPoints, vecSelect) != -1 )
				continue;

			new iEntity = rg_create_entity( sClassname, true );

			if( is_nullent( iEntity ) )
				continue;

			engfunc( EngFunc_SetOrigin, iEntity, vecSelect );
			set_entvar( iEntity, var_angles, vecAngles );

			//console_print(0, "FAKE (%s) - ID %d | vecSelect %f %f %f | vecAngles %f %f %f", sClassname, iEntity, vecSelect[0], vecSelect[1], vecSelect[2], vecAngles[0], vecAngles[1], vecAngles[2]);

			return iEntity;
		}
	}

	return NULLENT;
}


stock findCloseSpawn(Array:aSpawnPoints, const Float:vecCurOrigin[3], Float:flDist = 64.0)
{
	new Float:vecEntOrigin[3], pEnt;
	for(new i; i < ArraySize(aSpawnPoints); i++)
	{
		pEnt = ArrayGetCell(aSpawnPoints, i);
		get_entvar(pEnt, var_origin, vecEntOrigin);

		if(xs_vec_distance(vecEntOrigin, vecCurOrigin) <= flDist) return i;
	}
	return -1;
}
