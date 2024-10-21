/**
 * Weapon by xUnicorn aka t3rkecorejz
 *
 * Thanks a lot:
 *
 * Chrescoe1 & batcoh (Phenix) — First base code
 * KORD_12.7 & 406 (Nightfury) — I'm taken some functions from this authors
 * D34, 404 & fl0wer — Some help
 **/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <reapi>
#include <xs>

/* ~ [ Extra Item ] ~ */
new const EXTRA_ITEM_NAME[ ] = 				"Dual Kriss Super Vector";
const EXTRA_ITEM_COST = 					0;

/* ~ [ Weapon Settings ] ~ */
/**
 * If u don't needed one of this utilities, u can disable macro with comment line '//'
 * 
 * EJECT_BRASS -							EJECT BRASS (Shell)
 * CUSTOM_WEAPONLIST -						Custom WeaponList
 **/
#define EJECT_BRASS
#define CUSTOM_WEAPONLIST
#define WEAPON_KEY	1046228

new const WEAPON_REFERENCE[ ] = 			"weapon_mac10";
#if defined CUSTOM_WEAPONLIST
	new const WEAPON_WEAPONLIST[ ] = 		"x_re/weapon_dualkriss";
#endif
new const WEAPON_ANIMATION[ ] = 			"dualpistols";
new const WEAPON_NATIVE[ ] = 				"zp_give_user_dualkriss";
new const WEAPON_MODEL_VIEW[ ] = 			"models/x_re/v_dualkriss.mdl";
new const WEAPON_MODEL_PLAYER[ ] = 			"models/x_re/p_dualkriss.mdl";
new const WEAPON_MODEL_WORLD[ ] = 			"models/x_re/w_dualkriss.mdl";
#if defined EJECT_BRASS
	new const WEAPON_MODEL_SHELL[ ] = 		"models/pshell.mdl";
#endif
new const WEAPON_SOUNDS[ ][ ] =
{
	"weapons/kriss-1.wav",
	"weapons/dualkriss_clipin.wav",
	"weapons/dualkriss_clipout.wav",
	"weapons/dualkriss_draw.wav"
};

const WEAPON_MODEL_WORLD_BODY = 			0;


const WEAPON_MAX_CLIP = 					50;
const WEAPON_DEFAULT_AMMO = 				100;

const WEAPON_DAMAGE = 						36;
const WEAPON_SHOT_PENETRATION = 			2;
const Bullet: WEAPON_BULLET_TYPE = 			BULLET_PLAYER_45ACP;
const Float: WEAPON_SHOT_DISTANCE = 		8192.0;
const Float: WEAPON_RATE = 					0.0955;
const Float: WEAPON_ACCURACY = 				0.35;
const Float: WEAPON_RANGE_MODIFER = 		0.98;

/* ~ [ Weapon Animations ] ~ */
enum _: eWeaponAnimList {
	eWeaponAnim_Idle = 0,
	eWeaponAnim_IdleEmpty,
	eWeaponAnim_ShootLeft1,
	eWeaponAnim_ShootLeft2,
	eWeaponAnim_ShootLeftLast,
	eWeaponAnim_ShootRight1,
	eWeaponAnim_ShootRight2,
	eWeaponAnim_ShootRightLast,
	eWeaponAnim_Reload,
	eWeaponAnim_Draw
};

#define flWeaponAnim_Idle_Time 				( 41 / 10.0 )
#define flWeaponAnim_IdleEmpty_Time 		( 21 / 30.0 )
#define flWeaponAnim_Shoot_Time 			( 21 / 30.0 )
#define flWeaponAnim_Reload_Time 			( 101 / 30.0 )
#define flWeaponAnim_Draw_Time 				( 41 / 30.0 )

/* ~ [ Params ] ~ */
new gl_iItemId;

#if defined EJECT_BRASS
	new gl_iszModelIndex_Shell;
#endif
new HookChain: gl_HookChain_IsPenetrableEntity_Post;

/* ~ [ Macroses ] ~ */
#define WPNSTATE_LEFT_SHOOT					0
#define Vector3(%0) 						Float: %0[ 3 ]
#define IsCustomWeapon(%0,%1)				bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponClip(%0)					get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)				set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)				get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)				get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)				set_member( %0, m_rgAmmo, %1, %2 )
#define GetWeaponState(%0)					get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)				set_member( %0, m_Weapon_iWeaponState, %1 )

#define BIT_VALID(%0,%1)					( %0 & BIT( %1 ) )
#define BIT_INVERT(%0,%1)					( %0 ^= BIT( %1 ) )

/* ~ [ AMX Mod X ] ~ */
public plugin_precache( ) 
{
	new i;

	/* -> Precache Models -> */
	engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_VIEW );
	engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER );
	engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_WORLD );

	#if defined EJECT_BRASS
		gl_iszModelIndex_Shell = engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_SHELL );
	#endif
	
	/* -> Precache Sounds -> */
	for ( i = 0; i < sizeof WEAPON_SOUNDS; i++ )
		engfunc( EngFunc_PrecacheSound, WEAPON_SOUNDS[ i ] );

	#if defined CUSTOM_WEAPONLIST
		/* -> Hook Weapon -> */
		register_clcmd( WEAPON_WEAPONLIST, "Command_HookWeapon" );

		UTIL_PrecacheWeaponList( WEAPON_WEAPONLIST );
	#endif

	/* -> Alloc String -> */
	// #if defined CUSTOM_WEAPONLIST
	// 	WEAPON_KEY = engfunc( EngFunc_AllocString, WEAPON_WEAPONLIST );
	// #else
	// 	WEAPON_KEY = engfunc( EngFunc_AllocString, WEAPON_NATIVE );
	// #endif
}

public plugin_init( ) 
{
	// Original: https://cso.fandom.com/wiki/TDI_Kriss_Super_Vector
	register_plugin( "[ZP] Weapon: Dual Kriss Super Vector", "1.0", "xSparks" );

	/* -> Fakemeta -> */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

	/* -> ReAPI -> */
	RegisterHookChain( RG_CWeaponBox_SetModel, "CWeaponBox_SetModel_Pre", false );
	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post = RegisterHookChain( RG_IsPenetrableEntity, "CBasePlayerWeapon__IsPenetrableEntity_Post", true ) );

	/* -> HamSandwich -> */
	RegisterHam( Ham_Spawn, WEAPON_REFERENCE, "CBasePlayerWeapon__Spawn_Post", true );
	RegisterHam( Ham_Item_Deploy, WEAPON_REFERENCE, "CBasePlayerWeapon__Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WEAPON_REFERENCE, "CBasePlayerWeapon__Holster_Post", true );
	#if defined CUSTOM_WEAPONLIST
		RegisterHam( Ham_Item_AddToPlayer, WEAPON_REFERENCE, "CBasePlayerWeapon__AddToPlayer_Post", true );
	#endif
	RegisterHam( Ham_Weapon_Reload, WEAPON_REFERENCE, "CBasePlayerWeapon__Reload_Post", true );
	RegisterHam( Ham_Weapon_WeaponIdle, WEAPON_REFERENCE, "CBasePlayerWeapon__WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WEAPON_REFERENCE, "CBasePlayerWeapon__PrimaryAttack_Pre", false );

	/* -> Register on Extra-Items -> */
	gl_iItemId = zp_register_extra_item( EXTRA_ITEM_NAME, EXTRA_ITEM_COST, ZP_TEAM_HUMAN )
}

public plugin_natives( ) register_native( WEAPON_NATIVE, "Native_GiveWeapon" );

public bool: Native_GiveWeapon( ) 
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !is_user_alive( pPlayer ) )
		return false;
	
	return UTIL_GiveCustomWeapon( pPlayer, WEAPON_REFERENCE, WEAPON_KEY, WEAPON_DEFAULT_AMMO );
}

#if defined CUSTOM_WEAPONLIST
	public Command_HookWeapon( const pPlayer ) 
	{
		engclient_cmd( pPlayer, WEAPON_REFERENCE );
		return PLUGIN_HANDLED;
	}
#endif

/* ~ [ Zombie Core ] ~ */
public zp_extra_item_selected( pPlayer, iItemId ) 
{
	if ( iItemId != gl_iItemId ) 
		return PLUGIN_HANDLED;

	return UTIL_GiveCustomWeapon( pPlayer, WEAPON_REFERENCE, WEAPON_KEY, WEAPON_DEFAULT_AMMO );
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
	if ( !is_user_alive( pPlayer ) )
		return;

	static pActiveItem; pActiveItem = get_member( pPlayer, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WEAPON_KEY ) )
		return;

	set_cd( CD_Handle, CD_flNextAttack, 2.0 );
}

/* ~ [ ReAPI ] ~ */
public CWeaponBox_SetModel_Pre( const pWeaponBox, const szModel[ ] ) 
{
	if ( !IsCustomWeapon( UTIL_GetWeaponBoxItem( pWeaponBox ), WEAPON_KEY ) )
		return HC_CONTINUE;

	SetHookChainArg( 2, ATYPE_STRING, WEAPON_MODEL_WORLD );
	set_entvar( pWeaponBox, var_body, WEAPON_MODEL_WORLD_BODY );

	return HC_CONTINUE;
}

public CBasePlayerWeapon__IsPenetrableEntity_Post( const Vector3( vecStart ), Vector3( vecEnd ), const pPlayer, const pHit )
{
	new iPointContents = engfunc( EngFunc_PointContents, vecEnd );
	if ( iPointContents == CONTENTS_SKY )
		return;

	if ( pHit && is_nullent( pHit ) || ( get_entvar( pHit, var_flags ) & FL_KILLME ) || !ExecuteHam( Ham_IsBSPModel, pHit ) )
		return;

	UTIL_GunshotDecalTrace( pHit, vecEnd );

	if ( iPointContents == CONTENTS_WATER )
		return;

	new Vector3( vecPlaneNormal ); global_get( glb_trace_plane_normal, vecPlaneNormal );

	xs_vec_mul_scalar( vecPlaneNormal, random_float( 25.0, 30.0 ), vecPlaneNormal );
	message_begin_f( MSG_PAS, SVC_TEMPENTITY, vecEnd );
	UTIL_TE_STREAK_SPLASH( vecEnd, vecPlaneNormal, 4, random_num( 10, 20 ), 3, 64 );
}
 
/* ~ [ HamSandwich ] ~ */
public CBasePlayerWeapon__Spawn_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_KEY ) )
		return;

	SetWeaponClip( pItem, WEAPON_MAX_CLIP );
	set_member( pItem, m_Weapon_iDefaultAmmo, WEAPON_DEFAULT_AMMO );
	// set_member( pItem, m_Weapon_bHasSecondaryAttack, true );

	#if defined CUSTOM_WEAPONLIST
		rg_set_iteminfo( pItem, ItemInfo_pszName, WEAPON_WEAPONLIST );
	#endif
	rg_set_iteminfo( pItem, ItemInfo_iMaxClip, WEAPON_MAX_CLIP );
	rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WEAPON_DEFAULT_AMMO );
}

public CBasePlayerWeapon__Deploy_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_KEY ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	set_entvar( pPlayer, var_viewmodel, WEAPON_MODEL_VIEW );
	set_entvar( pPlayer, var_weaponmodel, WEAPON_MODEL_PLAYER );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, eWeaponAnim_Draw );

	set_member( pItem, m_Weapon_flAccuracy, WEAPON_ACCURACY );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flWeaponAnim_Draw_Time );
	set_member( pPlayer, m_flNextAttack, flWeaponAnim_Draw_Time );
	set_member( pPlayer, m_szAnimExtention, WEAPON_ANIMATION );
}

public CBasePlayerWeapon__Holster_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_KEY ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );
	
	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

#if defined CUSTOM_WEAPONLIST
	public CBasePlayerWeapon__AddToPlayer_Post( const pItem, const pPlayer ) 
	{
		new iWeaponUId = get_entvar( pItem, var_impulse );
		if ( iWeaponUId != 0 && iWeaponUId != WEAPON_KEY )
			return;

		UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
	}
#endif

public CBasePlayerWeapon__Reload_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_KEY ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
		return;

	if ( GetWeaponClip( pItem ) >= rg_get_iteminfo( pItem, ItemInfo_iMaxClip ) )
		return;

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, eWeaponAnim_Reload );

	set_member( pPlayer, m_flNextAttack, flWeaponAnim_Reload_Time );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flWeaponAnim_Reload_Time );
}

public CBasePlayerWeapon__WeaponIdle_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_KEY ) || get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, eWeaponAnim_Idle );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flWeaponAnim_Idle_Time );

	return HAM_SUPERCEDE;
}

public CBasePlayerWeapon__PrimaryAttack_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_KEY ) )
		return HAM_IGNORED;

	new iClip = GetWeaponClip( pItem );
	if ( !iClip ) 
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, 0.2 );

		return HAM_SUPERCEDE;
	}

	new pPlayer = get_member( pItem, m_pPlayer );
	new bitsWeaponState = GetWeaponState( pItem );

	UTIL_SendWeaponAnim( MSG_ONE, 
		pPlayer, 
		BIT_VALID( bitsWeaponState, WPNSTATE_LEFT_SHOOT ) ? 
			( iClip <= 1 ? eWeaponAnim_ShootRightLast : random_num( eWeaponAnim_ShootRight1, eWeaponAnim_ShootRight2 ) ) :
			( iClip <= 1 ? eWeaponAnim_ShootLeftLast : random_num( eWeaponAnim_ShootLeft1, eWeaponAnim_ShootLeft2 ) ) 
	);
	rg_set_animation( pPlayer, BIT_VALID( bitsWeaponState, WPNSTATE_LEFT_SHOOT ) ? PLAYER_ATTACK2 : PLAYER_ATTACK1 );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WEAPON_SOUNDS[ 0 ] );

	new bitsFlags = get_entvar( pPlayer, var_flags );
	new iShotsFired = get_member( pItem, m_Weapon_iShotsFired ); iShotsFired++;

	new Vector3( vecVelocity ); get_entvar( pPlayer, var_velocity, vecVelocity );
	new Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	new Vector3( vecViewOfs ); get_entvar( pPlayer, var_view_ofs, vecViewOfs );
	new Vector3( vecSrc ); xs_vec_add( vecOrigin, vecViewOfs, vecSrc );
	new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );
	new Float: flAccuracy = get_member( pItem, m_Weapon_flAccuracy );
	new Float: flSpread = ( ( ~bitsFlags & FL_ONGROUND ) ? 0.2 : 0.08 ) * flAccuracy;

	if ( flAccuracy ) 
		flAccuracy = floatmin( ( ( iShotsFired * iShotsFired ) / 220.0 ) + 0.30, 1.0 );

	EnableHookChain( gl_HookChain_IsPenetrableEntity_Post );
	rg_fire_bullets3( pItem, pPlayer, vecSrc, vecAiming, flSpread, WEAPON_SHOT_DISTANCE, WEAPON_SHOT_PENETRATION, WEAPON_BULLET_TYPE, WEAPON_DAMAGE, WEAPON_RANGE_MODIFER, false, get_member( pPlayer, random_seed ) );
	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post );

	if ( xs_vec_len_2d( vecVelocity ) > 0 ) 
		UTIL_WeaponKickBack( pItem, pPlayer, 1.0, 0.45, 0.28, 0.04, 4.25, 2.5, 7 );
	else if ( ~bitsFlags & FL_ONGROUND ) 
		UTIL_WeaponKickBack( pItem, pPlayer, 1.25, 0.45, 0.22, 0.18, 6.0, 4.0, 5 );
	else if ( bitsFlags & FL_DUCKING ) 
		UTIL_WeaponKickBack( pItem, pPlayer, 0.6, 0.35, 0.2, 0.0125, 3.7, 2.0, 10 );
	else
		UTIL_WeaponKickBack( pItem, pPlayer, 0.625, 0.375, 0.25, 0.0125, 4.0, 2.25, 9 );

	#if defined EJECT_BRASS
		UTIL_EjectBrass( pPlayer, gl_iszModelIndex_Shell, 
			random_float( -10.0, -50.0 ) * ( BIT_VALID( bitsWeaponState, WPNSTATE_LEFT_SHOOT ) ? -1.0 : 1.0 ),
			.flRightScale = 8.0 * ( BIT_VALID( bitsWeaponState, WPNSTATE_LEFT_SHOOT ) ? -1.0 : 1.0 ) );
	#endif

	BIT_INVERT( bitsWeaponState, WPNSTATE_LEFT_SHOOT );

	SetWeaponClip( pItem, --iClip );
	SetWeaponState( pItem, bitsWeaponState );
	set_member( pItem, m_Weapon_flAccuracy, flAccuracy );
	set_member( pItem, m_Weapon_iShotsFired, iShotsFired );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, WEAPON_RATE );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, WEAPON_RATE );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flWeaponAnim_Shoot_Time );

	return HAM_SUPERCEDE;
}

/* ~ [ Stocks ] ~ */

/* -> Weapon Animation <- */
stock UTIL_SendWeaponAnim( const iDest, const pPlayer, const iAnim ) 
{
	set_entvar( pPlayer, var_weaponanim, iAnim );

	message_begin( iDest, SVC_WEAPONANIM, .player = pPlayer );
	write_byte( iAnim );
	write_byte( 0 );
	message_end( );
}

/* -> Automaticly precache WeaponList <- */
stock UTIL_PrecacheWeaponList( const szWeaponList[ ] )
{
	new szBuffer[ 128 ], pFile;

	format( szBuffer, charsmax( szBuffer ), "sprites/%s.txt", szWeaponList );
	engfunc( EngFunc_PrecacheGeneric, szBuffer );

	if ( !( pFile = fopen( szBuffer, "rb" ) ) )
		return;

	new szSprName[ MAX_RESOURCE_PATH_LENGTH ], iPos;

	while ( !feof( pFile ) ) 
	{
		fgets( pFile, szBuffer, charsmax( szBuffer ) );
		trim( szBuffer );

		if ( !strlen( szBuffer ) ) 
			continue;

		if ( ( iPos = containi( szBuffer, "640" ) ) == -1 )
			continue;
				
		format( szBuffer, charsmax( szBuffer ), "%s", szBuffer[ iPos + 3 ] );		
		trim( szBuffer );

		strtok( szBuffer, szSprName, charsmax( szSprName ), szBuffer, charsmax( szBuffer ), ' ', 1 );
		trim( szSprName );

		engfunc( EngFunc_PrecacheGeneric, fmt( "sprites/%s.spr", szSprName ) );
	}

	fclose( pFile );
}

/* -> Give Custom Item <- */
stock bool: UTIL_GiveCustomWeapon( const pPlayer, const szWeaponName[ ], const iWeaponUId, const iAmmo = 0 )
{
	new bool: bKnife = bool: ( equal( szWeaponName, "weapon_knife" ) );
	new pItem = rg_give_custom_item( pPlayer, szWeaponName, bKnife ? GT_REPLACE : GT_DROP_AND_REPLACE, iWeaponUId );

	if ( is_nullent( pItem ) )
		return false;

	if ( !bKnife || iAmmo )
	{
		new iAmmoType = GetWeaponAmmoType( pItem );
		if ( GetWeaponAmmo( pPlayer, iAmmoType ) > iAmmo ) SetWeaponAmmo( pPlayer, iAmmo, iAmmoType );
	}

	return true;
}

/* -> Get Weapon Box Item <- */
stock UTIL_GetWeaponBoxItem( const pWeaponBox )
{
	for ( new iSlot, pItem; iSlot < MAX_ITEM_TYPES; iSlot++ )
	{
		if ( !is_nullent( ( pItem = get_member( pWeaponBox, m_WeaponBox_rgpPlayerItems, iSlot ) ) ) )
			return pItem;
	}
	return NULLENT;
}

/* -> Get Vector Aiming <- */
stock UTIL_GetVectorAiming( const pPlayer, Vector3( vecAiming ) ) 
{
	new Vector3( vecPunchangle ); get_entvar( pPlayer, var_punchangle, vecPunchangle );
	new Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	xs_vec_add( vecViewAngle, vecPunchangle, vecViewAngle );
	angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecAiming );
}

/* -> Gunshot Decal Trace <- */
stock UTIL_GunshotDecalTrace( const pEntity, const Vector3( vecOrigin ) )
{	
	new iDecalId = UTIL_DamageDecal( pEntity );
	if ( iDecalId == -1 )
		return;

	message_begin_f( MSG_PAS, SVC_TEMPENTITY, vecOrigin );
	UTIL_TE_GUNSHOTDECAL( vecOrigin, pEntity, iDecalId );
}

stock UTIL_DamageDecal( const pEntity )
{
	new iRenderMode = get_entvar( pEntity, var_rendermode );
	if ( iRenderMode == kRenderTransAlpha )
		return -1;

	static iGlassDecalId; if ( !iGlassDecalId ) iGlassDecalId = engfunc( EngFunc_DecalIndex, "{bproof1" );
	if ( iRenderMode != kRenderNormal )
		return iGlassDecalId;

	static iShotDecalId; if ( !iShotDecalId ) iShotDecalId = engfunc( EngFunc_DecalIndex, "{shot1" );
	return ( iShotDecalId - random_num( 0, 4 ) );
}

stock UTIL_TE_GUNSHOTDECAL( const Vector3( vecOrigin ), const pEntity, const iDecalId )
{
	write_byte( TE_GUNSHOTDECAL );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_short( pEntity );
	write_byte( iDecalId );
	message_end( );
}

/* -> Weapon Kick Back <- */
stock UTIL_WeaponKickBack( const pItem, const pPlayer, Float: flUpBase, Float: flLateralBase, Float: flUpModifier, Float: flLateralModifier, Float: flUpMax, Float: flLateralMax, iDirectionChange ) 
{
	new Float: flKickUp, Float: flKickLateral;
	new iShotsFired = get_member( pItem, m_Weapon_iShotsFired );
	new iDirection = get_member( pItem, m_Weapon_iDirection );
	new Vector3( vecPunchangle ); get_entvar( pPlayer, var_punchangle, vecPunchangle );

	if ( iShotsFired == 1 ) 
	{
		flKickUp = flUpBase;
		flKickLateral = flLateralBase;
	}
	else
	{
		flKickUp = iShotsFired * flUpModifier + flUpBase;
		flKickLateral = iShotsFired * flLateralModifier + flLateralBase;
	}

	vecPunchangle[ 0 ] -= flKickUp;

	if ( vecPunchangle[ 0 ] < -flUpMax ) 
		vecPunchangle[ 0 ] = -flUpMax;

	if ( iDirection ) 
	{
		vecPunchangle[ 1 ] += flKickLateral;
		if ( vecPunchangle[ 1 ] > flLateralMax ) 
			vecPunchangle[ 1 ] = flLateralMax;
	}
	else
	{
		vecPunchangle[ 1 ] -= flKickLateral;
		if ( vecPunchangle[ 1 ] < -flLateralMax ) 
			vecPunchangle[ 1 ] = -flLateralMax;
	}

	if ( !random_num( 0, iDirectionChange ) ) 
		set_member( pItem, m_Weapon_iDirection, iDirection );

	set_entvar( pPlayer, var_punchangle, vecPunchangle );
}

/* -> Weapon List <- */
stock UTIL_WeaponList( const iDest, const pPlayer, const pItem, const szWeaponName[ MAX_NAME_LENGTH ] = "", const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
{
	new szBuffer[ sizeof szWeaponName ];
	szWeaponName[ 0 ] == EOS ? rg_get_iteminfo( pItem, ItemInfo_pszName, szBuffer, charsmax( szBuffer ) ) : copy( szBuffer, charsmax( szBuffer ), szWeaponName );

	static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

	message_begin( iDest, iMsgId_Weaponlist, .player = pPlayer );
	write_string( szBuffer );
	write_byte( ( iPrimaryAmmoType <= -2 ) ? GetWeaponAmmoType( pItem ) : iPrimaryAmmoType );
	write_byte( ( iMaxPrimaryAmmo <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iMaxAmmo1 ) : iMaxPrimaryAmmo );
	write_byte( ( iSecondaryAmmoType <= -2 ) ? get_member( pItem, m_Weapon_iSecondaryAmmoType ) : iSecondaryAmmoType );
	write_byte( ( iMaxSecondaryAmmo <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iMaxAmmo2 ) : iMaxSecondaryAmmo );
	write_byte( ( iSlot <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iSlot ) : iSlot );
	write_byte( ( iPosition <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iPosition ) : iPosition );
	write_byte( ( iWeaponId <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iId ) : iWeaponId );
	write_byte( ( iFlags <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iFlags ) : iFlags );
	message_end( );
}

stock UTIL_TE_STREAK_SPLASH( const Vector3( vecOrigin ), const Vector3( vecDirection ), const iColor, const iCount, const iSpeed, const iNoise )
{
	write_byte( TE_STREAK_SPLASH );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_coord_f( vecDirection[ 0 ] );
	write_coord_f( vecDirection[ 1 ] );
	write_coord_f( vecDirection[ 2 ] );
	write_byte( iColor );
	write_short( iCount );
	write_short( iSpeed );
	write_short( iNoise );
	message_end( );
}

/* -> TE_MODEL <- */
stock UTIL_TE_MODEL( const Vector3( vecOrigin ), const Vector3( vecVelocity ), const Float: flYaw, const iszModelShellIndex, const iSound, const iLife )
{
	write_byte( TE_MODEL );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_coord_f( vecVelocity[ 0 ] );
	write_coord_f( vecVelocity[ 1 ] );
	write_coord_f( vecVelocity[ 2 ] );
	write_angle_f( flYaw ); // Yaw
	write_short( iszModelShellIndex ); // Model Index
	write_byte( iSound ); // Bounce sound
	write_byte( iLife ); // Life time ( n * 0.1 sec )
	message_end( );
}

/* -> Custom Eject Brass <- */
stock UTIL_EjectBrass( const pPlayer, const iszModelShellIndex, const Float: flRightDirection, const Float: flUpScale = -9.0, const Float: flForwardScale = 16.0, const Float: flRightScale = 0.0, const bool: bShotgunSound = false )
{
	new Vector3( vecViewAngle ); pev( pPlayer, pev_v_angle, vecViewAngle );
	new Vector3( vecPunchangle ); pev( pPlayer, pev_punchangle, vecPunchangle );

	xs_vec_add( vecViewAngle, vecPunchangle, vecViewAngle );
	engfunc( EngFunc_MakeVectors, vecViewAngle );

	new Vector3( vecOrigin ); pev( pPlayer, pev_origin, vecOrigin );
	new Vector3( vecViewOfs ); pev( pPlayer, pev_view_ofs, vecViewOfs );
	new Vector3( vecVelocity ); pev( pPlayer, pev_velocity, vecVelocity );
	
	new Vector3( vecUp ); global_get( glb_v_up, vecUp );
	new Vector3( vecRight ); global_get( glb_v_right, vecRight );
	new Vector3( vecForward ); global_get( glb_v_forward, vecForward );
	
	new i;
	for ( i = 0; i < 3; i++ )
	{
		vecOrigin[ i ] = vecOrigin[ i ] + vecViewOfs[ i ] + vecForward[ i ] * flForwardScale + vecUp[ i ] * flUpScale + vecRight[ i ] * flRightScale;
		vecVelocity[ i ] = vecVelocity[ i ] + vecForward[ i ] * 25.0 + vecUp[ i ] * random_float( 100.0, 150.0 ) + vecRight[ i ] * flRightDirection;
	}
	
	message_begin_f( MSG_ONE, SVC_TEMPENTITY, vecOrigin, pPlayer );
	UTIL_TE_MODEL( vecOrigin, vecVelocity, vecViewAngle[ 1 ], iszModelShellIndex, bShotgunSound ? 2 : 1, 15 );
}