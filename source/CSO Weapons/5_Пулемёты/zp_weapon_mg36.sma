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
new const EXTRA_ITEM_NAME[ ] = 				"MG36";
const EXTRA_ITEM_COST = 					0;

/* ~ [ Weapon Settings ] ~ */
/**
 * If u don't needed one of this utilities, u can disable macro with comment line '//'
 * 
 * EJECT_BRASS -							EJECT BRASS (Shell)
 * CUSTOM_WEAPONLIST -						Custom WeaponList
 * DYNAMIC_CROSSHAIR -						Dynamic Crosshair. With this macro, 
 * 											plugin 'Unlimited Clip' not works.
 **/
#define EJECT_BRASS
#define CUSTOM_WEAPONLIST
#define DYNAMIC_CROSSHAIR
#define WEAPON_KEY	124590

new const WEAPON_REFERENCE[ ] = 			"weapon_m249";
#if defined CUSTOM_WEAPONLIST
	new const WEAPON_WEAPONLIST[ ] = 		"x_re/weapon_mg36";
#endif
new const WEAPON_ANIMATION[ ] = 			"rifle";
new const WEAPON_NATIVE[ ] = 				"zp_give_user_mg36";
new const WEAPON_MODEL_VIEW[ ] = 			"models/x_re/v_mg36.mdl";
new const WEAPON_MODEL_PLAYER[ ] = 			"models/x_re/p_mg36.mdl";
new const WEAPON_MODEL_WORLD[ ] = 			"models/x_re/w_mg36.mdl";
#if defined EJECT_BRASS
	new const WEAPON_MODEL_SHELL[ ] = 		"models/rshell.mdl";
#endif
new const WEAPON_SOUNDS[ ][ ] =
{
	"weapons/mg36-1.wav",
	"weapons/mg36_boltfull.wav",
	"weapons/mg36_clipin.wav",
	"weapons/mg36_clipout.wav",
	"weapons/mg36_draw.wav"
};

const WEAPON_MODEL_WORLD_BODY = 			0;

const WEAPON_MAX_CLIP = 					100;
const WEAPON_DEFAULT_AMMO = 				200;

const WEAPON_DAMAGE = 						30;
const WEAPON_SHOT_PENETRATION = 			2;
const Bullet: WEAPON_BULLET_TYPE = 			BULLET_PLAYER_556MM;
const Float: WEAPON_SHOT_DISTANCE = 		8192.0;
const Float: WEAPON_RATE = 					0.0955;
const Float: WEAPON_ACCURACY = 				0.2;
const Float: WEAPON_RANGE_MODIFER = 		0.98;

/* ~ [ Weapon Animations ] ~ */
enum _: eWeaponAnimList {
	eWeaponAnim_Idle = 0,
	eWeaponAnim_Shoot1,
	eWeaponAnim_Shoot2,
	eWeaponAnim_Reload,
	eWeaponAnim_Draw
};

#define flWeaponAnim_Idle_Time 				( 61 / 16.0 )
#define flWeaponAnim_Shoot_Time 			( 31 / 30.0 )
#define flWeaponAnim_Reload_Time 			( 118 / 30.0 )
#define flWeaponAnim_Draw_Time 				( 31 / 30.0 )

/* ~ [ Params ] ~ */
new gl_iItemId;
#if defined EJECT_BRASS
	new gl_iszModelIndex_Shell;
#endif
new HookChain: gl_HookChain_IsPenetrableEntity_Post;

/* ~ [ Macroses ] ~ */
#define WEAPON_IMPULSE 867532
#define Vector3(%0) 						Float: %0[ 3 ]
#define DEFAULT_FOV							90
#define IsCustomWeapon(%0,%1)				bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponClip(%0)					get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)				set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)				get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)				get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)				set_member( %0, m_rgAmmo, %1, %2 )

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

	/*  -> Alloc String ->
	#if defined CUSTOM_WEAPONLIST
		WEAPON_KEY = engfunc( EngFunc_AllocString, WEAPON_WEAPONLIST );
	#else
		WEAPON_KEY = engfunc( EngFunc_AllocString, WEAPON_NATIVE );
	#endif */
}

public plugin_init( ) 
{
	// Original: https://cso.fandom.com/wiki/MG36
	register_plugin( "[ZP] Weapon: MG36", "1.0", "xSparks" );

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
	#if defined DYNAMIC_CROSSHAIR
		RegisterHam( Ham_Item_PostFrame, WEAPON_REFERENCE, "CBasePlayerWeapon__PostFrame_Pre", false );
	#endif
	RegisterHam( Ham_Weapon_Reload, WEAPON_REFERENCE, "CBasePlayerWeapon__Reload_Post", true );
	RegisterHam( Ham_Weapon_WeaponIdle, WEAPON_REFERENCE, "CBasePlayerWeapon__WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WEAPON_REFERENCE, "CBasePlayerWeapon__PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WEAPON_REFERENCE, "CBasePlayerWeapon__SecondaryAttack_Pre", false );

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
	set_member( pItem, m_Weapon_bHasSecondaryAttack, true );

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

#if defined DYNAMIC_CROSSHAIR
	public CBasePlayerWeapon__PostFrame_Pre( const pItem ) 
	{
		if ( !IsCustomWeapon( pItem, WEAPON_KEY ) )
			return HAM_IGNORED;

		new pPlayer = get_member( pItem, m_pPlayer );

		UTIL_ResetCrosshair( pPlayer, pItem );
		return HAM_IGNORED;
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

	set_member( pPlayer, m_iFOV, DEFAULT_FOV );
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

	#if defined DYNAMIC_CROSSHAIR
		UTIL_IncreaseCrosshair( pPlayer, pItem );
	#endif
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, random_num( eWeaponAnim_Shoot1, eWeaponAnim_Shoot2 ) );
	rg_set_animation( pPlayer, PLAYER_ATTACK1 );
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
		UTIL_WeaponKickBack( pItem, pPlayer, 1.1, 0.5, 0.3, 0.06, 4.0, 3.0, 8 );
	else if ( ~bitsFlags & FL_ONGROUND ) 
		UTIL_WeaponKickBack( pItem, pPlayer, 1.8, 0.65, 0.45, 0.125, 5.0, 3.5, 8 );
	else if ( bitsFlags & FL_DUCKING ) 
		UTIL_WeaponKickBack( pItem, pPlayer, 0.75, 0.325, 0.25, 0.025, 3.5, 2.5, 9 );
	else
		UTIL_WeaponKickBack( pItem, pPlayer, 0.8, 0.35, 0.3, 0.03, 3.75, 3.0, 9 );

	#if defined EJECT_BRASS
		set_member( pItem, m_Weapon_iShellId, gl_iszModelIndex_Shell );
		set_member( pPlayer, m_flEjectBrass, get_gametime( ) );
	#endif

	SetWeaponClip( pItem, --iClip );
	set_member( pItem, m_Weapon_flAccuracy, flAccuracy );
	set_member( pItem, m_Weapon_iShotsFired, iShotsFired );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, WEAPON_RATE );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, WEAPON_RATE );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flWeaponAnim_Shoot_Time );

	return HAM_SUPERCEDE;
}

public CBasePlayerWeapon__SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WEAPON_KEY ) )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );

	if ( get_member( pPlayer, m_iFOV ) == DEFAULT_FOV ) 
		set_member( pPlayer, m_iFOV, 55 );
	else 
		set_member( pPlayer, m_iFOV, DEFAULT_FOV );

	set_member( pItem, m_Weapon_flNextSecondaryAttack, 0.3 );

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

/* -> Dynamic Crosshair <- */
stock UTIL_IncreaseCrosshair( const pPlayer, const pItem ) 
{
	static iMsgId_CurWeapon; if ( !iMsgId_CurWeapon ) iMsgId_CurWeapon = get_user_msgid( "CurWeapon" );

	set_msg_block( iMsgId_CurWeapon, BLOCK_ONCE );

	UTIL_WeaponList( MSG_ONE, pPlayer, pItem, .iPosition = 13, .iWeaponId = any: WEAPON_MAC10 );
	UTIL_CurWeapon( MSG_ONE, pPlayer, true, any: WEAPON_MAC10, GetWeaponClip( pItem ) );

	set_member( pItem, m_Weapon_flNextReload, get_gametime( ) + 0.04 );
}

stock UTIL_ResetCrosshair( const pPlayer, const pItem ) 
{
	if ( get_member( pItem, m_Weapon_flNextReload ) && get_member( pItem, m_Weapon_flNextReload ) <= get_gametime( ) ) 
	{
		UTIL_CurWeapon( MSG_ONE, pPlayer, true, get_member( pItem, m_iId ), GetWeaponClip( pItem ) );

		set_member( pItem, m_Weapon_flNextReload, 0.0 );
	}
}

stock UTIL_CurWeapon( const iDest, const pPlayer, const bool: bIsActive, const iWeaponId, const iClipAmmo )
{
	static iMsgId_CurWeapon; if ( !iMsgId_CurWeapon ) iMsgId_CurWeapon = get_user_msgid( "CurWeapon" );

	message_begin( iDest, iMsgId_CurWeapon, .player = pPlayer );
	write_byte( bIsActive );
	write_byte( iWeaponId );
	write_byte( iClipAmmo );
	message_end( );
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