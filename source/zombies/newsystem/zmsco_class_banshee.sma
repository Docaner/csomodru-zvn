public stock const PluginName[ ] =			"[ZP] Zombie Class: Banshee";
public stock const PluginVersion[ ] =		"1.0";
public stock const PluginAuthor[ ] =		"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <zombieplague>

// zp_addon_zombie_claws
native bool: zp_update_zombie_timer_state( const pPlayer, const pKnife = NULLENT, const bool: bShow = false );

/* ~ [ Plugin Settings ] ~ */
const Float: AbilityBatsTimer =				20.0;

enum {
	WeaponAnim_Skill = 2,
	WeaponAnim_Skill_End = 5
}

const Float: WeaponAnim_Skill_Time =		7.4;
const Float: WeaponAnim_Skill_End_Time =	2.0;

/* ~ [ Entity: Bats ] ~ */
new const EntityBatsReference[ ] =			"info_target";
new const EntityBatsClassName[ ] =			"ent_banshee_bats";
new const EntityBatsModel[ ] =				"models/x_re/bat_witch.mdl";
new const EntityBatsSprite[ ] =				"sprites/x_re/ef_bat.spr";
new const EntityBatsSounds[ ][ ] = {
	"x_re/zm/banshee/zombi_banshee_laugh.wav",
	"x_re/zm/banshee/zombi_banshee_pulling_fail.wav",
	"x_re/zm/banshee/zombi_banshee_pulling_fire.wav"
};
const Float: EntityBatsSpeed =				600.0;
const Float: EntityBatsCatchSpeed =			200.0;
const Float: EntityBatsCatchRadius =		75.0;
const Float: EntityBatsLifeTime =			2.7;
const Float: EntityBatsCatchLifeTime =		4.7;
const Float: EntityBatsNextThink =			0.075;

/* ~ [ Params ] ~ */
new gl_iZombieClassId;
new gl_bitsUserBanshee;
new gl_iszModelIndex_BatsEffect;

enum _: HOOK_CHAINS {
	HookChain: HookChain_PM_Move_Pre,
	HookChain: HookChain_Player_Killed_Post,
	HookChain: HookChain_Player_SetAnimation_Pre
};
new HookChain: gl_HookChains[ HOOK_CHAINS ];
new HamHook: gl_HamHook_CanHolster_Pre;

enum ( <<= 1 ) {
	WeaponState_OnAbility = 1,
	WeaponState_Catch
};

enum {
	Sound_Laugh = 0,
	Sound_Fail,
	Sound_Fire
};

/* ~ [ Macroses ] ~ */
#if !defined Vector3
	#define Vector3(%0)						Float: %0[ 3 ]
#endif

#define BIT_PLAYER(%0)						( BIT( %0 - 1 ) )
#define BIT_ADD(%0,%1)						( %0 |= %1 )
#define BIT_SUB(%0,%1)						( %0 &= ~%1 )
#define BIT_VALID(%0,%1)					( ( %0 & %1 ) == %1 )
#define BIT_CLEAR(%0)						( %0 = 0 )

#define IsBansheeZombieClass(%0)			BIT_VALID( gl_bitsUserBanshee, BIT_PLAYER( %0 ) )
#define zp_set_zombie_timer(%0,%1)			set_entvar( %0, var_ability_time, get_gametime( ) + Float: %1 )

#define GetWeaponState(%0)					get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)				set_member( %0, m_Weapon_iWeaponState, %1 )

#define var_ability_time					var_starttime // CWeapon: weapon_knife

// stock zp_set_zombie_timer( const pItem, const Float: flTime ) set_entvar( pItem, var_ability_time, get_gametime( ) + Float: flTime );

/* ~ [ AMX Mod X ] ~ */
public plugin_precache( )
{
	/* -> Precache Model <- */
	engfunc( EngFunc_PrecacheModel, EntityBatsModel );

	/* -> Precache Sound <- */
	for ( new i = 0; i < sizeof EntityBatsSounds; i++ )
		engfunc( EngFunc_PrecacheSound, EntityBatsSounds[ i ] );

	/* -> Model Index <- */
	gl_iszModelIndex_BatsEffect = engfunc( EngFunc_PrecacheModel, EntityBatsSprite );

	/* -> Register Zombie-Class <- */
	gl_iZombieClassId = zp_register_zombie_class(
		"Banshee",
		"Pull Bats",
		"banshee_xre",
		"v_knife_banshee.mdl",
		2200,
		255,
		0.9,
		1.2
	);
}

public plugin_init( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

	/* -> ReGameDLL <- */
	RegisterHookChain( RG_CSGameRules_RestartRound, "RG_CSGameRules__RestartRound_Post", true );

	DisableHookChain( gl_HookChains[ HookChain_PM_Move_Pre ] =
		RegisterHookChain( RG_PM_Move, "RG_PM__Move_Pre", false )
	);

	DisableHookChain( gl_HookChains[ HookChain_Player_Killed_Post ] =
		RegisterHookChain( RG_CBasePlayer_Killed, "RG_CBasePlayer__Killed_Post", true )
	);
	
	DisableHookChain( gl_HookChains[ HookChain_Player_SetAnimation_Pre ] =
		RegisterHookChain( RG_CBasePlayer_SetAnimation, "RG_CBasePlayer__SetAnimation_Pre", false )
	);

	/* -> HamSandwich <- */
	DisableHamForward( gl_HamHook_CanHolster_Pre =
		RegisterHam( Ham_Item_CanHolster, "weapon_knife", "Ham_CBasePlayerWeapon__CanHolster_Pre", false )
	);

	/* -> Regsiter Client Commands <- */
	register_clcmd( "drop", "ClientCommand__HookDrop" );
}

public client_disconnected( pPlayer )
{
	BIT_SUB( gl_bitsUserBanshee, BIT_PLAYER( pPlayer ) );
	ToggleForwards( bool: ( gl_bitsUserBanshee ) );
}

public ClientCommand__HookDrop( const pPlayer )
{
	if ( !is_user_alive( pPlayer ) || !IsBansheeZombieClass( pPlayer ) )
		return PLUGIN_CONTINUE;

	new pActiveItem = get_member( pPlayer, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || get_member( pActiveItem, m_iId ) != WEAPON_KNIFE )
		return PLUGIN_HANDLED;

	SetGlobalTransTarget( pPlayer );

	// In Ladder
	if ( get_entvar( pPlayer, var_movetype ) == MOVETYPE_FLY )
	{
		client_print( pPlayer, print_center, "*** The ability is not available on the stairs ***" );
		return PLUGIN_HANDLED;
	}

	if ( !( get_entvar( pPlayer, var_flags ) & FL_ONGROUND ) )
	{
		client_print( pPlayer, print_center, "*** The ability is not available in the air ***" );
		return PLUGIN_HANDLED;
	}

	new Float: flGameTime = get_gametime( );
	if ( Float: get_entvar( pActiveItem, var_ability_time ) >= flGameTime )
	{
		client_print( pPlayer, print_center, "*** Ability in cooldown ***" );
		return PLUGIN_HANDLED;
	}

	new bitsWeaponState;
	if ( ( bitsWeaponState = GetWeaponState( pActiveItem ) ) )
	{
		client_print( pPlayer, print_center, "*** You are already using the ability ***" );
		return PLUGIN_HANDLED;
	}

	CBats__SpawnEntity( pPlayer );

	// UTIL_PlayerAnimation( pPlayer, "skill1" );
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pActiveItem, WeaponAnim_Skill );

	set_member( pPlayer, m_flNextAttack, 9999.0 );
	set_member( pActiveItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Skill_Time );

	BIT_ADD( bitsWeaponState, WeaponState_OnAbility );
	SetWeaponState( pActiveItem, bitsWeaponState );

	return PLUGIN_HANDLED;
}

/* ~ [ Zombie Plague ] ~ */
public zp_user_humanized_post( pPlayer )
{
	BIT_SUB( gl_bitsUserBanshee, BIT_PLAYER( pPlayer ) );
	ToggleForwards( bool: ( gl_bitsUserBanshee ) );
}

public zp_user_infected_post( pPlayer, pInfector, bNemesis )
{
	if ( zp_get_user_zombie_class( pPlayer ) == gl_iZombieClassId && !bNemesis )
		BIT_ADD( gl_bitsUserBanshee, BIT_PLAYER( pPlayer ) );
	else
		BIT_SUB( gl_bitsUserBanshee, BIT_PLAYER( pPlayer ) );

	ToggleForwards( bool: ( gl_bitsUserBanshee ) );
}

/* ~ [ ReGameDLL ] ~ */
public RG_CSGameRules__RestartRound_Post( )
{
	BIT_CLEAR( gl_bitsUserBanshee );
	ToggleForwards( false );
}

public RG_PM__Move_Pre( const pPlayer )
{
	if ( get_pmove( pm_dead ) || !IsBansheeZombieClass( pPlayer ) )
		return HC_CONTINUE;

	static pKnife; pKnife = get_member( pPlayer, m_rgpPlayerItems, KNIFE_SLOT );
	if ( is_nullent( pKnife ) || !GetWeaponState( pKnife ) )
		return HC_CONTINUE;

	set_pmove( pm_velocity, NULL_VECTOR );
	set_pmove( pm_maxspeed, 1.0 );
	set_pmove( pm_clientmaxspeed, 1.0 );

	return HC_CONTINUE;
}

public RG_CBasePlayer__Killed_Post( const pVictim )
{
	if ( !IsBansheeZombieClass( pVictim ) )
		return;

	BIT_SUB( gl_bitsUserBanshee, BIT_PLAYER( pVictim ) );
	ToggleForwards( bool: ( gl_bitsUserBanshee ) );
}

public RG_CBasePlayer__SetAnimation_Pre( const pPlayer )
{
	if ( !is_user_alive( pPlayer ) || !IsBansheeZombieClass( pPlayer ) )
		return HC_CONTINUE;

	static pKnife; pKnife = get_member( pPlayer, m_rgpPlayerItems, KNIFE_SLOT );
	if ( is_nullent( pKnife ) )
		return HC_CONTINUE;

	static bitsWeaponState;
	if ( ( bitsWeaponState = GetWeaponState( pKnife ) ) )
	{
		static Float: flGameTime; flGameTime = get_gametime( );
		static Float: flNextAnimTime[ MAX_PLAYERS + 1 ];

		if ( flNextAnimTime[ pPlayer ] > flGameTime )
			return HC_SUPERCEDE;

		if ( BIT_VALID( bitsWeaponState, WeaponState_Catch ) )
		{
			UTIL_PlayerAnimation( pPlayer, "skill1_loop" );
			flNextAnimTime[ pPlayer ] = flGameTime + Float: EntityBatsCatchLifeTime;
		}
		else
		{
			UTIL_PlayerAnimation( pPlayer, "skill1" );
			flNextAnimTime[ pPlayer ] = flGameTime + Float: EntityBatsLifeTime;
		}

		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

/* ~ [ HamSandwich ] ~ */
public Ham_CBasePlayerWeapon__CanHolster_Pre( const pItem )
{
	new pPlayer = get_member( pItem, m_pPlayer );
	if ( !IsBansheeZombieClass( pPlayer ) )
		return HAM_IGNORED;

	if ( GetWeaponState( pItem ) )
	{
		SetHamReturnInteger( false );
		return HAM_SUPERCEDE;
	}

	SetHamReturnInteger( true );
	return HAM_IGNORED;
}

/* ~ [ Other ] ~ */
ToggleForwards( const bEnabled )
{
	if ( bEnabled )
	{
		EnableHookChain( gl_HookChains[ HookChain_PM_Move_Pre ] );
		EnableHookChain( gl_HookChains[ HookChain_Player_Killed_Post ] );
		EnableHookChain( gl_HookChains[ HookChain_Player_SetAnimation_Pre ] );
		EnableHamForward( gl_HamHook_CanHolster_Pre );
	}
	else
	{
		DisableHookChain( gl_HookChains[ HookChain_PM_Move_Pre ] );
		DisableHookChain( gl_HookChains[ HookChain_Player_Killed_Post ] );
		DisableHookChain( gl_HookChains[ HookChain_Player_SetAnimation_Pre ] );
		DisableHamForward( gl_HamHook_CanHolster_Pre );
	}
}

public CBats__SpawnEntity( const pPlayer )
{
	new pEntity = rg_create_entity( EntityBatsReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	new Vector3( vecTemp ); UTIL_GetEyePosition( pPlayer, vecTemp );
	new Vector3( vecVelocity ); UTIL_GetVectorAiming( pPlayer, vecVelocity );

	xs_vec_add_scaled( vecTemp, vecVelocity, 10.0, vecTemp );
	xs_vec_mul_scalar( vecVelocity, EntityBatsSpeed, vecVelocity );

	engfunc( EngFunc_SetModel, pEntity, EntityBatsModel );
	engfunc( EngFunc_SetSize, pEntity, Float: { -10.0, -10.0, -1.0 }, Float: { 10.0, 10.0, 1.0 } );

	set_entvar( pEntity, var_classname, EntityBatsClassName );
	set_entvar( pEntity, var_solid, SOLID_TRIGGER );
	set_entvar( pEntity, var_movetype, MOVETYPE_FLY );
	set_entvar( pEntity, var_owner, pPlayer );

	set_entvar( pEntity, var_velocity, vecVelocity );
	set_entvar( pEntity, var_origin, vecTemp );

	engfunc( EngFunc_VecToAngles, vecVelocity, vecTemp );
	set_entvar( pEntity, var_angles, vecTemp );

	new Float: flGameTime = get_gametime( );
	set_entvar( pEntity, var_ltime, flGameTime + Float: EntityBatsLifeTime );
	set_entvar( pEntity, var_nextthink, flGameTime + Float: EntityBatsLifeTime );

	UTIL_SetEntityAnim( pEntity );

	SetThink( pEntity, "CBats__Think" );
	SetTouch( pEntity, "CBats__Touch" );

	rh_emit_sound2( pEntity, 0, CHAN_WEAPON, EntityBatsSounds[ Sound_Fire ] );

	return pEntity;
}

public CBatsCatch__SpawnEntity( const pOwner, const pEnemy )
{
	new pEntity = rg_create_entity( EntityBatsReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	set_entvar( pEntity, var_classname, EntityBatsClassName );
	set_entvar( pEntity, var_solid, SOLID_NOT );
	set_entvar( pEntity, var_movetype, MOVETYPE_FOLLOW );
	set_entvar( pEntity, var_owner, pOwner );
	set_entvar( pEntity, var_aiment, pEnemy );
	set_entvar( pEntity, var_effects, get_entvar( pEntity, var_effects ) | EF_NODRAW );

	new Float: flGameTime = get_gametime( );
	set_entvar( pEntity, var_ltime, flGameTime + Float: EntityBatsCatchLifeTime );
	set_entvar( pEntity, var_nextthink, flGameTime );

	UTIL_SetEntityAnim( pEntity, 1 );

	SetThink( pEntity, "CBats__Think" );

	return pEntity;
}

public CBats__Think( const pEntity )
{
	static Float: flGameTime; flGameTime = get_gametime( );
	set_entvar( pEntity, var_nextthink, flGameTime + Float: EntityBatsNextThink );

	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( !is_user_alive( pOwner ) || !zp_get_user_zombie( pOwner ) )
	{
		CBats__Destroy( pEntity, pOwner );
		return;
	}

	if ( Float: get_entvar( pEntity, var_ltime ) < flGameTime )
	{
		CBats__Destroy( pEntity, pOwner );
		return;
	}

	static pEnemy; pEnemy = get_entvar( pEntity, var_aiment );
	if ( !pEnemy || !is_user_alive( pEnemy ) )
		return;

	if ( zp_get_user_zombie( pEnemy ) )
	{
		CBats__Destroy( pEntity, pOwner );
		return;
	}

	static Vector3( vecOrigin ); get_entvar( pOwner, var_origin, vecOrigin );
	static Vector3( vecEnemyOrigin ); get_entvar( pEnemy, var_origin, vecEnemyOrigin );

	if ( xs_vec_distance( vecOrigin, vecEnemyOrigin ) <= 64.0 )
	{
		CBats__Destroy( pEntity, pOwner );
		return;
	}
	else
	{
		static Vector3( vecVelocity );

		UTIL_GetSpeedVector( vecEnemyOrigin, vecOrigin, EntityBatsCatchSpeed, 1.0, vecVelocity );
		set_entvar( pEnemy, var_velocity, vecVelocity );
	}
}

public CBats__Touch( const pEntity, const pTouch )
{
	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( pTouch == pOwner || FClassnameIs( pTouch, EntityBatsClassName ) )
		return;

	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	if ( !is_user_alive( pTouch ) || engfunc( EngFunc_PointContents, vecOrigin ) == CONTENTS_SKY )
	{
		CBats__Destroy( pEntity, pOwner );
		return;
	}

	if ( is_user_alive( pTouch ) && !zp_get_user_zombie( pTouch ) )
	{
		new pKnife = get_member( pOwner, m_rgpPlayerItems, KNIFE_SLOT );
		if ( !is_nullent( pKnife ) )
			SetWeaponState( pKnife, GetWeaponState( pKnife ) | WeaponState_Catch );

		new Float: flGameTime = get_gametime( );

		set_entvar( pEntity, var_solid, SOLID_NOT );
		set_entvar( pEntity, var_movetype, MOVETYPE_FOLLOW );
		set_entvar( pEntity, var_aiment, pTouch );
		set_entvar( pEntity, var_ltime, flGameTime + Float: EntityBatsCatchLifeTime );
		set_entvar( pEntity, var_nextthink, flGameTime );

		UTIL_SetEntityAnim( pEntity, 1 );

		rh_emit_sound2( pEntity, 0, CHAN_ITEM, EntityBatsSounds[ Sound_Laugh ] );

		SetTouch( pEntity, "" );

		new Vector3( vecVictimOrigin );

		for ( new pVictim = 1; pVictim <= MaxClients; pVictim++ )
		{
			if ( !is_user_alive( pVictim ) || zp_get_user_zombie( pVictim ) )
				continue;

			if ( pVictim == pTouch )
				continue;

			get_entvar( pVictim, var_origin, vecVictimOrigin );
			if ( xs_vec_distance( vecOrigin, vecVictimOrigin ) > Float: EntityBatsCatchRadius )
				continue;

			if ( is_nullent( CBatsCatch__SpawnEntity( pOwner, pVictim ) ) )
				continue;
		}
	}
}

public CBats__Destroy( pEntity, const pOwner )
{
	new Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	UTIL_TE_EXPLOSION( MSG_BROADCAST, gl_iszModelIndex_BatsEffect, vecOrigin, 0.0, 16, 32 );

	rh_emit_sound2( pEntity, 0, CHAN_WEAPON, EntityBatsSounds[ Sound_Fire ], .flags = SND_STOP );
	rh_emit_sound2( pEntity, 0, CHAN_WEAPON, EntityBatsSounds[ Sound_Fail ] );

	UTIL_KillEntity( pEntity );

	pEntity = NULLENT;
	while ( ( pEntity = fm_find_ent_by_owner( pEntity, EntityBatsClassName, pOwner ) ) > 0 )
		UTIL_KillEntity( pEntity );

	if ( !is_user_alive( pOwner ) )
		return;

	rg_reset_maxspeed( pOwner );
	UTIL_PlayerAnimation( pOwner, "idle1" );
	set_member( pOwner, m_flNextAttack, 0.0 );

	if ( !zp_get_user_zombie( pOwner ) )
		return;

	new pKnife = get_member( pOwner, m_rgpPlayerItems, KNIFE_SLOT );
	if ( !is_nullent( pKnife ) )
	{
		SetWeaponState( pKnife, 0 );
		zp_set_zombie_timer( pKnife, AbilityBatsTimer );

		if ( get_member( pOwner, m_pActiveItem ) == pKnife )
		{
			UTIL_SendWeaponAnim( MSG_ONE, pOwner, pKnife, WeaponAnim_Skill_End );
			set_member( pKnife, m_Weapon_flTimeWeaponIdle, WeaponAnim_Skill_End_Time );

			zp_update_zombie_timer_state( pOwner, pKnife, true );
		}
	}
}

/* ~ [ Stocks ] ~ */
/* -> Entity Animation <- */
stock UTIL_SetEntityAnim( const pEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0 )
{
	set_entvar( pEntity, var_frame, flFrame );
	set_entvar( pEntity, var_framerate, flFrameRate );
	set_entvar( pEntity, var_animtime, get_gametime( ) );
	set_entvar( pEntity, var_sequence, iSequence );
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

/* -> Weapon Animation <- */
stock UTIL_SendWeaponAnim( const iDest, const pReceiver, const pItem, const iAnim ) 
{
#if defined WeaponAnim_Dummy
	static iBody; iBody = get_entvar( pItem, var_body );
#else
	#pragma unused pItem

	#define iBody 0
#endif

	set_entvar( pReceiver, var_weaponanim, iAnim );

	message_begin( iDest, SVC_WEAPONANIM, .player = pReceiver );
	write_byte( iAnim );
	write_byte( iBody );
	message_end( );

#if defined WeaponAnim_Dummy
	if ( get_entvar( pReceiver, var_iuser1 ) )
		return;

	static i, iCount, pSpectator, aSpectators[ MAX_PLAYERS ];
	get_players( aSpectators, iCount, "bch" );

	for ( i = 0; i < iCount; i++ )
	{
		pSpectator = aSpectators[ i ];

		if ( get_entvar( pSpectator, var_iuser1 ) != OBS_IN_EYE )
			continue;

		if ( get_entvar( pSpectator, var_iuser2 ) != pReceiver )
			continue;

		set_entvar( pSpectator, var_weaponanim, iAnim );

		message_begin( iDest, SVC_WEAPONANIM, .player = pSpectator );
		write_byte( iAnim );
		write_byte( iBody );
		message_end( );
	}
#endif
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

/* -> Get speed Vector to 2 points <- */
stock UTIL_GetSpeedVector( const Vector3( vecStartOrigin ), const Vector3( vecEndOrigin ), Float: flSpeed = 0.0, Float: flTime = 1.0, Vector3( vecVelocity ) )
{
	if ( !flSpeed )
		flSpeed = xs_vec_distance( vecStartOrigin, vecEndOrigin ) / flTime;
	else flSpeed /= flTime;

	xs_vec_sub( vecEndOrigin, vecStartOrigin, vecVelocity );
	xs_vec_normalize( vecVelocity, vecVelocity );
	xs_vec_mul_scalar( vecVelocity, flSpeed, vecVelocity );
}

/* -> TE_EXPLOSION <- */
stock UTIL_TE_EXPLOSION( const iDest, const iszModelIndex, const Vector3( vecOrigin ), const Float: flUp, const iScale, const iFramerate, const bitsFlags = TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_EXPLOSION );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] + flUp );
	write_short( iszModelIndex );
	write_byte( iScale ); // Scale
	write_byte( iFramerate ); // Framerate
	write_byte( bitsFlags ); // Flags
	message_end( );
}

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity )
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );
}
