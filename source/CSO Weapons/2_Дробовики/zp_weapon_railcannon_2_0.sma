/*
 * Weapon by xUnicorn (t3rkecorejz) 
 *
 * Thanks a lot:
 *
 * Chrescoe1 & batcoh (Phenix) — First base code
 * KORD_12.7 & 406 (Nightfury) — I'm taken some functions from this authors
 * D34, 404 & fl0wer — Some help
 */

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <zombieplague>
#include <reapi>
#include <beams_reapi>

// #tryinclude <api_muzzleflash>
#tryinclude <api_smokewallpuff>

#define BeamFromCenter

/* ~ [ Extra Item ] ~ */
new const ExtraItem_Name[ ] =				"Rail Cannon";
const ExtraItem_Cost =						0;

/* ~ [ Weapon Settings ] ~ */
const WeaponUnicalIndex =					25891;
new const WeaponName[ ] =					"Rail Cannon";
new const WeaponReference[ ] =				"weapon_xm1014";
// Comment 'WeaponListDir' if u dont need custom weapon list
new const WeaponListDir[ ] =				"x/weapon_railcannon";
new const WeaponAnimation[ ] =				"m249";
new const WeaponNative[ ] =					"zp_give_user_railcannon";
new const WeaponModelView[ ] =				"models/x/v_railcannon.mdl";
new const WeaponModelPlayer[ ] =			"models/x/p_railcannon.mdl";
new const WeaponModelWorld[ ] =				"models/x/w_railcannon.mdl";
// Comment 'WeaponModelShell' if u dont need eject brass (shell) 
new const WeaponModelShell[ ] =				"models/shotgunshell.mdl"; 
new const WeaponSounds[ ][ ] = {
	"weapons/railcannon_shoot.wav",
	"weapons/railcannon_shoot_charge.wav",

	"weapons/railcannon_charge_start.wav",
	"weapons/railcannon_charge_loop.wav",
	"weapons/railcannon_charge_first.wav",
	"weapons/railcannon_charge_second.wav",
	"weapons/railcannon_charge_third.wav"
};

const ModelWorldBody =						0;

const WeaponMaxClip =						12;
const WeaponDefaultAmmo =					40;
const WeaponMaxAmmo =						80;

const WeaponDamage =						30;
const WeaponShotsCount =					6;
const Float: WeaponShotDistance =			3048.0;
const Float: WeaponRate =					0.35;
new const Float: WeaponSpread[ ][ ] = {
	{ 0.0825, 0.0825, 0.0 }, // Default
	{ 0.0725, 0.0725, 0.0 }, // Charge 1st
	{ 0.0425, 0.0425, 0.0 }, // Charge 2nd
	{ 0.0125, 0.0125, 0.0 } // Charge 3rd
};

const WeaponSecondaryMaxCharge =			3;
const Float: WeaponSecondaryNextCharge =	0.7;

/* ~ [ Entity: Beam ] ~ */
new const BeamSprite[ ] =					"sprites/laserbeam.spr";
const Float: BeamWidth =					24.0;
const Float: BeamBrightness =				255.0;
const Float: BeamScrollRate =				20.0;
new const Float: BeamColor[ ] =				{ 220.0, 80.0, 0.0 };

/* ~ [ Muzzle Flash ] ~ */
#if defined _api_muzzleflash_included
	new const MuzzleFlashSprite[ ] =		"sprites/x_re/muzzleflash19.spr";
#endif

/* ~ [ Weapon Animations ] ~ */
enum {
	WeaponAnim_Idle = 0,
	WeaponAnim_Idle1,
	WeaponAnim_Idle2,
	WeaponAnim_Idle3,
	WeaponAnim_Shoot1,
	WeaponAnim_Shoot2,
	WeaponAnim_Reload,
	WeaponAnim_Draw
};

const Float: WeaponAnim_Idle_Time = 	1.7;
const Float: WeaponAnim_Shoot_Time = 	1.0;
const Float: WeaponAnim_Reload_Time = 	2.9;
const Float: WeaponAnim_Draw_Time = 	1.1;

/* ~ [ Params ] ~ */
new gl_iItemId;
new gl_bitsUserLeftHanded;
#if defined _api_muzzleflash_included
	new MuzzleFlash: gl_iMuzzleId;
#endif
#if defined WeaponModelShell
	new gl_iszModelIndex_Shell;
#endif

enum {
	Sound_Shoot = 0,
	Sound_Shoot_Charge,

	Sound_Charge_Start,
	Sound_Charge_Loop,
	Sound_Charge_1st,
	Sound_Charge_2nd,
	Sound_Charge_3rd
};

enum ( <<= 1 ) {
	WeaponState_Charge = 1
};

/* ~ [ Macroses ] ~ */
#if !defined Vector3
	#define Vector3(%0)					Float: %0[ 3 ]
#endif

#define BIT_PLAYER(%0)					( BIT( %0 - 1 ) )
#define BIT_ADD(%0,%1)					( %0 |= %1 )
#define BIT_SUB(%0,%1)					( %0 &= ~%1 )
#define BIT_VALID(%0,%1)				( %0 & %1 )
#define INSTANCE(%0)					( ( %0 == -1 ) ? 0 : %0 )

#define IsCustomWeapon(%0,%1)			bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponState(%0)				get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)			set_member( %0, m_Weapon_iWeaponState, %1 )
#define GetWeaponClip(%0)				get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)			set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)			get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)			get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)			set_member( %0, m_rgAmmo, %1, %2 )

#define var_charge_level				var_weaponanim 
#define var_next_sound 					var_impacttime

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( ) register_native( WeaponNative, "native_give_user_weapon" );
public plugin_precache( ) 
{
	new i;

	/* -> Precache Models <- */
	engfunc( EngFunc_PrecacheModel, WeaponModelView );
	engfunc( EngFunc_PrecacheModel, WeaponModelPlayer );
	engfunc( EngFunc_PrecacheModel, WeaponModelWorld );
	
	/* -> Precache Sounds <- */
	for ( i = 0; i < sizeof WeaponSounds; i++ )
		engfunc( EngFunc_PrecacheSound, WeaponSounds[ i ] );

#if defined WeaponListDir
	/* -> Hook Weapon <- */
	register_clcmd( WeaponListDir, "ClientCommand__HookWeapon" );

	UTIL_PrecacheWeaponList( WeaponListDir );
#endif

	/* -> MuzzleFlash <- */
#if defined _api_muzzleflash_included
	gl_iMuzzleId = zc_muzzle_init( );
	{
		zc_muzzle_set_property( gl_iMuzzleId, ZC_MUZZLE_SPRITE, MuzzleFlashSprite );
		zc_muzzle_set_property( gl_iMuzzleId, ZC_MUZZLE_SCALE, 0.1 );
		zc_muzzle_set_property( gl_iMuzzleId, ZC_MUZZLE_FRAMERATE_MLT, 0.5 );
	}
#endif

	/* -> Model Index <- */
#if defined WeaponModelShell
	gl_iszModelIndex_Shell = engfunc( EngFunc_PrecacheModel, WeaponModelShell );
#endif
}

public plugin_init( ) 
{
	register_plugin( "[ZP] Weapon: Test Weapon", "1.0", "Yoshioka Haruki" );

	/* -> Fakemeta <- */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

	/* -> ReGameDLL <- */
	RegisterHookChain( RG_CWeaponBox_SetModel, "RG_CWeaponBox__SetModel_Pre", false );

	/* -> HamSandwich: Weapon <- */
	RegisterHam( Ham_Spawn, WeaponReference, "Ham_CWeapon_Spawn_Post", true );
	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_CWeapon_Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_CWeapon_Holster_Post", true );
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Ham_CWeapon_AddToPlayer_Post", true );
	RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_CWeapon_PostFrame_Pre", false );
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Pre", false );
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Post", true );
	RegisterHam( Ham_Weapon_WeaponIdle, WeaponReference, "Ham_CWeapon_WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CWeapon_PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_CWeapon_SecondaryAttack_Pre", false );

	/* -> Register on Extra-Items <- */
	gl_iItemId = zp_register_extra_item( ExtraItem_Name, ExtraItem_Cost, ZP_TEAM_HUMAN );
}

public client_putinserver( pPlayer )
{
	if ( !is_user_bot( pPlayer ) )
		query_client_cvar( pPlayer, "cl_righthand", "CBasePlayer__CheckLeftHand" );
}

public client_disconnected( pPlayer ) BIT_SUB( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) );

public bool: native_give_user_weapon( ) 
{
	enum { arg_player = 1 };

	return CPlayer__GiveWeapon( get_param( arg_player ) );
}

#if defined WeaponListDir
	public ClientCommand__HookWeapon( const pPlayer ) 
	{
		engclient_cmd( pPlayer, WeaponReference );
		return PLUGIN_HANDLED;
	}
#endif

/* ~ [ Zombie Plague ] ~ */
public zp_extra_item_selected( pPlayer, iItemId ) 
{
	if ( iItemId != gl_iItemId )
		return PLUGIN_HANDLED;

	return CPlayer__GiveWeapon( pPlayer ) ? PLUGIN_CONTINUE : ZP_PLUGIN_HANDLED;
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
	if ( !is_user_alive( pPlayer ) )
		return;

	static pActiveItem; pActiveItem = get_member( pPlayer, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
		return;

	set_cd( CD_Handle, CD_flNextAttack, 2.0 );
}

public FM_Hook_TraceLine_Post( const Vector3( vecSrc ), const Vector3( vecEnd ), const bitsFlags, const pInflictor, const pTrace )
{
	if ( bitsFlags & IGNORE_MONSTERS )
		return;

	new Float: flFraction; get_tr2( pTrace, TR_flFraction, flFraction );
	if ( flFraction == 1.0 )
		return;

	new Vector3( vecEndPos ); get_tr2( pTrace, TR_vecEndPos, vecEndPos );

	new iPointContents = engfunc( EngFunc_PointContents, vecEndPos );
	if ( iPointContents == CONTENTS_SKY )
		return;

	CBeam__SpawnEntity( pInflictor, vecEndPos );

	new pHit = INSTANCE( get_tr2( pTrace, TR_pHit ) );
	if ( pHit && is_nullent( pHit ) || ( get_entvar( pHit, var_flags ) & FL_KILLME ) || !ExecuteHam( Ham_IsBSPModel, pHit ) )
		return;

	UTIL_GunshotDecalTrace( pHit, vecEndPos );

	new Vector3( vecPlaneNormal ); get_tr2( pTrace, TR_vecPlaneNormal, vecPlaneNormal );

#if defined _api_smokewallpuff_included
	zc_smoke_wallpuff_draw( vecEndPos, vecPlaneNormal );
#endif

	xs_vec_mul_scalar( vecPlaneNormal, random_float( 25.0, 30.0 ), vecPlaneNormal );
	UTIL_TE_STREAK_SPLASH( MSG_PAS, vecEndPos, vecPlaneNormal, 7, random_num( 10, 20 ), 3, 64 );
}

/* ~ [ ReGameDLL ] ~ */
public RG_CWeaponBox__SetModel_Pre( const pWeaponBox, const szModel[ ] ) 
{
	new pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
	if ( pItem == NULLENT || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HC_CONTINUE;

	SetHookChainArg( 2, ATYPE_STRING, WeaponModelWorld );
	set_entvar( pWeaponBox, var_body, ModelWorldBody );

	return HC_CONTINUE;
}

/* ~ [ HamSandwich ] ~ */
public Ham_CWeapon_Spawn_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	SetWeaponClip( pItem, WeaponMaxClip );

	set_member( pItem, m_Weapon_iDefaultAmmo, WeaponDefaultAmmo );
	set_member( pItem, m_Weapon_bHasSecondaryAttack, true );

#if defined WeaponListDir
	rg_set_iteminfo( pItem, ItemInfo_pszName, WeaponListDir );
#endif
	rg_set_iteminfo( pItem, ItemInfo_iMaxClip, WeaponMaxClip );
	rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WeaponMaxAmmo );

	set_entvar( pItem, var_netname, WeaponName );
}

public Ham_CWeapon_Deploy_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	set_entvar( pPlayer, var_viewmodel, WeaponModelView );
	set_entvar( pPlayer, var_weaponmodel, WeaponModelPlayer );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Draw );

	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Draw_Time );
	set_member( pPlayer, m_flNextAttack, WeaponAnim_Draw_Time );
	set_member( pPlayer, m_szAnimExtention, WeaponAnimation );
}

public Ham_CWeapon_Holster_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	if ( is_user_connected( pPlayer ) )
	{
		if ( !is_user_bot( pPlayer ) )
			query_client_cvar( pPlayer, "cl_righthand", "CBasePlayer__CheckLeftHand" );

#if defined _api_muzzleflash_included
		zc_muzzle_destroy( pPlayer, gl_iMuzzleId );
#endif
	}

	new iChargeLevel = get_entvar( pItem, var_charge_level );
	if ( iChargeLevel )
	{
		set_entvar( pItem, var_charge_level, 0 );
		SetWeaponClip( pItem, GetWeaponClip( pItem ) + iChargeLevel );
	}

	SetWeaponState( pItem, 0 );

	CBasePlayerWeapon__StopSounds( pPlayer, pItem );
	
	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

#if defined WeaponListDir
	public Ham_CWeapon_AddToPlayer_Post( const pItem, const pPlayer ) 
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

		UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
	}
#endif

public Ham_CWeapon_PostFrame_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( GetWeaponState( pItem ) )
	{
		static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
		if ( get_member( pPlayer, m_afButtonReleased ) & IN_ATTACK2 )
		{
			CBasePlayerWeapon__StopSounds( pPlayer, pItem );
			CBasePlayerWeapon__Fire( pItem, get_entvar( pItem, var_charge_level ) );
		}
	}

	return HAM_IGNORED;
}

public Ham_CWeapon_Reload_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( get_entvar( pItem, var_charge_level ) )
		return HAM_SUPERCEDE;

	set_member( pItem, m_Weapon_fInReload, true );
	return HAM_SUPERCEDE;
}

public Ham_CWeapon_Reload_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
		return;

	new iClip = GetWeaponClip( pItem );
	if ( iClip >= rg_get_iteminfo( pItem, ItemInfo_iMaxClip ) )
		return;

	new iChargeLevel = get_entvar( pItem, var_charge_level );
	if ( iChargeLevel )
	{
		set_entvar( pItem, var_charge_level, 0 );
		SetWeaponClip( pItem, iClip + iChargeLevel );
	}

	SetWeaponState( pItem, 0 );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Reload );

	set_member( pPlayer, m_flNextAttack, WeaponAnim_Reload_Time );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time );
}

public Ham_CWeapon_WeaponIdle_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( Float: get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );
	new iChargeLevel;

	if ( ( iChargeLevel = get_entvar( pItem, var_charge_level ) ) && iChargeLevel )
		UTIL_PlayTimingSound( pPlayer, pItem, CHAN_WEAPON, WeaponSounds[ Sound_Charge_Loop ], 1.0 );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Idle + iChargeLevel );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Idle_Time );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PrimaryAttack_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( BIT_VALID( GetWeaponState( pItem ), WeaponState_Charge ) )
		return HAM_SUPERCEDE;

	if ( !CBasePlayerWeapon__Fire( pItem, 0 ) )
		return HAM_SUPERCEDE;

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	new iClip = GetWeaponClip( pItem );
	new iChargeLevel = get_entvar( pItem, var_charge_level );
	if ( !iClip && !iChargeLevel )
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pItem, m_Weapon_flNextSecondaryAttack, 0.2 );

		return HAM_SUPERCEDE;
	}

	new pPlayer = get_member( pItem, m_pPlayer );
	new bitsWeaponState = GetWeaponState( pItem );

	if ( !iChargeLevel && !BIT_VALID( bitsWeaponState, WeaponState_Charge ) )
	{
		UTIL_PlayTimingSound( pPlayer, pItem, CHAN_WEAPON, WeaponSounds[ Sound_Charge_Start ], 1.0 );

		iChargeLevel = -1;
		iClip += 1;

		BIT_ADD( bitsWeaponState, WeaponState_Charge );
		SetWeaponState( pItem, bitsWeaponState );
	}

	if ( iClip && iChargeLevel < WeaponSecondaryMaxCharge )
	{
		set_entvar( pItem, var_charge_level, ++iChargeLevel );

		if ( iChargeLevel )
			rh_emit_sound2( pPlayer, 0, CHAN_ITEM, WeaponSounds[ Sound_Charge_1st + iChargeLevel - 1 ] );

		SetWeaponClip( pItem, --iClip );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, 0.0 );
		ExecuteHamB( Ham_Weapon_WeaponIdle, pItem );
	}

	set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponSecondaryNextCharge );
	return HAM_SUPERCEDE;
}

/* ~ [ Other ] ~ */
public bool: CPlayer__GiveWeapon( const pPlayer )
{
	if ( !is_user_alive( pPlayer ) )
		return false;

	if ( UTIL_GiveCustomWeapon( pPlayer, WeaponReference, WeaponUnicalIndex, WeaponDefaultAmmo ) )
		return true;

	return false;
}

public CBasePlayerWeapon__StopSounds( const pPlayer, const pItem )
{
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_Charge_Start ], .flags = SND_STOP );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_Charge_Loop ], .flags = SND_STOP );

	set_entvar( pItem, var_next_sound, get_gametime( ) );
}

public bool: CBasePlayerWeapon__Fire( const pItem, const iChargeLevel )
{
	new iClip = GetWeaponClip( pItem );
	if ( !iClip && !iChargeLevel )
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, 0.2 );

		return false;
	}

	new pPlayer = get_member( pItem, m_pPlayer );
	new Vector3( vecSrc ); UTIL_GetEyePosition( pPlayer, vecSrc );
	new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );
	new bool: bChargedShoot = iChargeLevel > 0 ? true : false;

	new iMul = iChargeLevel ? iChargeLevel : 1;
	new iDamage = WeaponDamage * iMul;

	static FM_Hook_TraceLine_Post; FM_Hook_TraceLine_Post = register_forward( FM_TraceLine, "FM_Hook_TraceLine_Post", true );
	rg_fire_buckshots( pItem, pPlayer, WeaponShotsCount, vecSrc, vecAiming, Float: WeaponSpread[ iChargeLevel ], WeaponShotDistance, false, iDamage);
	unregister_forward( FM_TraceLine, FM_Hook_TraceLine_Post, true );

#if defined _api_muzzleflash_included
	zc_muzzle_draw( pPlayer, gl_iMuzzleId );
#endif

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Shoot1 + ( bChargedShoot ? 1 : 0 ) );
	rg_set_animation( pPlayer, PLAYER_ATTACK1 );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ bChargedShoot ] );

	static Vector3( vecPunchAngle ); get_entvar( pPlayer, var_punchangle, vecPunchAngle );
	vecPunchAngle[ 0 ] -= ( get_entvar( pPlayer, var_flags ) & FL_ONGROUND ) ? random_float( 3.0, 5.0 ) : random_float( 7.0, 10.0 );
	set_entvar( pPlayer, var_punchangle, vecPunchAngle );

#if defined WeaponModelShell
	set_member( pItem, m_Weapon_iShellId, gl_iszModelIndex_Shell );
	set_member( pPlayer, m_flEjectBrass, get_gametime( ) );
#endif

	set_entvar( pItem, var_charge_level, 0 );
	SetWeaponState( pItem, 0 );

	if ( !bChargedShoot )
		SetWeaponClip( pItem, --iClip );

	set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponRate + ( bChargedShoot ? 0.5 : 0.0 ) );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponRate + ( bChargedShoot ? 0.5 : 0.0 ) );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Shoot_Time );

	return true;
}

public CBasePlayer__CheckLeftHand( const pPlayer, const szCvar[ ], const szValue[ ] )
{
	equal( szValue, "1" ) ? BIT_SUB( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) ) : BIT_ADD( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) );
}

public CBeam__SpawnEntity( const pInflictor, const Vector3( vecEndPos ) )
{
	if ( is_nullent( pInflictor ) || !IsCustomWeapon( pInflictor, WeaponUnicalIndex ) )
		return;

	if ( !get_entvar( pInflictor, var_charge_level ) )
		return;

	new pBeam = Beam_Create( BeamSprite, BeamWidth );
	if ( !is_nullent( pBeam ) )
	{
		new pPlayer = get_member( pInflictor, m_pPlayer );
		new Vector3( vecStartPos );

	#if defined BeamFromCenter
		new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );
		UTIL_GetEyePosition( pPlayer, vecStartPos );

		xs_vec_add_scaled( vecStartPos, vecAiming, 20.0, vecStartPos );
	#else
		UTIL_GetWeaponPosition( pPlayer, 40.0, BIT_VALID( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) ) ? -5.0 : 5.0, -5.0, vecStartPos );
	#endif

		Beam_PointsInit( pBeam, vecStartPos, vecEndPos );
		Beam_SetBrightness( pBeam, BeamBrightness );
		Beam_SetColor( pBeam, BeamColor );
		Beam_SetScrollRate( pBeam, BeamScrollRate );

		SetThink( pBeam, "CBeam__Think" );
		set_entvar( pBeam, var_nextthink, get_gametime( ) );
	}
}

public CBeam__Think( const pBeam )
{
	set_entvar( pBeam, var_nextthink, get_gametime( ) + 0.04 );

	static Float: flBrightness; flBrightness = Beam_GetBrightness( pBeam );
	if ( ( flBrightness -= 15.0 ) && flBrightness <= 15.0 )
	{
		UTIL_KillEntity( pBeam );
		return;
	}

	Beam_SetBrightness( pBeam, flBrightness );
}

/* ~ [ Stocks ] ~ */
/* -> Automaticly precache WeaponList <- */
stock UTIL_PrecacheWeaponList( const szWeaponList[ ] )
{
	new szBuffer[ 128 ], pFile;

	format( szBuffer, charsmax( szBuffer ), "sprites/%s.txt", szWeaponList );
	engfunc( EngFunc_PrecacheGeneric, szBuffer );

	if ( !( pFile = fopen( szBuffer, "rb" ) ) )
		return;

	new szSprName[ 64 ], iPos;
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

/* -> Weapon List <- */
stock UTIL_WeaponList( const iDest, const pReceiver, const pItem, szWeaponName[ MAX_NAME_LENGTH ] = "", const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
{
	if ( szWeaponName[ 0 ] == EOS )
		rg_get_iteminfo( pItem, ItemInfo_pszName, szWeaponName, charsmax( szWeaponName ) );

	static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

	message_begin( iDest, iMsgId_Weaponlist, .player = pReceiver );
	write_string( szWeaponName );
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

/* -> Weapon Animation <- */
stock UTIL_SendWeaponAnim( const iDest, const pReceiver, const pItem, const iAnim ) 
{
	static iBody; iBody = get_entvar( pItem, var_body );
	set_entvar( pReceiver, var_weaponanim, iAnim );

	message_begin( iDest, SVC_WEAPONANIM, .player = pReceiver );
	write_byte( iAnim );
	write_byte( iBody );
	message_end( );

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
}

/* -> Gunshot Decal Trace <- */
stock UTIL_GunshotDecalTrace( const pEntity, const Vector3( vecOrigin ) )
{	
	new iDecalId = UTIL_DamageDecal( pEntity );
	if ( iDecalId == -1 )
		return;

	UTIL_TE_GUNSHOTDECAL( MSG_PAS, vecOrigin, pEntity, iDecalId );
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

/* -> TE_GUNSHOTDECAL <- */
stock UTIL_TE_GUNSHOTDECAL( const iDest, const Vector3( vecOrigin ), const pEntity, const iDecalId )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_GUNSHOTDECAL );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_short( pEntity );
	write_byte( iDecalId );
	message_end( );
}

/* -> TE_STREAK_SPLASH <- */
stock UTIL_TE_STREAK_SPLASH( const iDest, const Vector3( vecOrigin ), const Vector3( vecDirection ), const iColor, const iCount, const iSpeed, const iNoise )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
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

stock UTIL_ResetTimingSound( const pPlayer, const pEntity, const iChannel = CHAN_WEAPON, const szSound[ ] )
{
	set_entvar( pEntity, var_next_sound, get_gametime( ) );
	rh_emit_sound2( pPlayer, 0, iChannel, szSound, .flags = SND_STOP );
}

stock bool: UTIL_PlayTimingSound( const pPlayer, const pEntity, const iChannel = CHAN_WEAPON, const szSound[ ], const Float: flSoundTime )
{
	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flNextSound; get_entvar( pEntity, var_next_sound, flNextSound );
	if ( flNextSound > flGameTime )
		return false;

	rh_emit_sound2( pPlayer, 0, iChannel, szSound );
	set_entvar( pEntity, var_next_sound, flGameTime + flSoundTime );

	return true;
}

/* -> Give Custom Item <- */
stock bool: UTIL_GiveCustomWeapon( const pPlayer, const szWeaponReference[ ], const iWeaponUId, const iDefaultAmmo, &pItem = NULLENT )
{
	pItem = rg_give_custom_item( pPlayer, szWeaponReference, GT_DROP_AND_REPLACE, iWeaponUId );
	if ( is_nullent( pItem ) )
		return false;

	if ( iDefaultAmmo )
	{
		new iAmmoType = GetWeaponAmmoType( pItem );

		if ( GetWeaponAmmo( pPlayer, iAmmoType ) < iDefaultAmmo )
			SetWeaponAmmo( pPlayer, iDefaultAmmo, iAmmoType );
	}

	return true;
}

/* -> Get player eye position <- */
stock UTIL_GetEyePosition( const pPlayer, Vector3( vecEyeLevel ) )
{
	static Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	static Vector3( vecViewOfs ); get_entvar( pPlayer, var_view_ofs, vecViewOfs );

	xs_vec_add( vecOrigin, vecViewOfs, vecEyeLevel );
}

/* -> Get Player vector Aiming <- */
stock UTIL_GetVectorAiming( const pPlayer, Vector3( vecAiming ) ) 
{
	static Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	static Vector3( vecPunchAngle ); get_entvar( pPlayer, var_punchangle, vecPunchAngle );

	xs_vec_add( vecViewAngle, vecPunchAngle, vecViewAngle );
	angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecAiming );
}

/* -> Get Weapon Position <- */
stock UTIL_GetWeaponPosition( const pPlayer, const Float: flForward, const Float: flRight, const Float: flUp, Vector3( vecStart ) ) 
{
	static Vector3( vecOrigin ); UTIL_GetEyePosition( pPlayer, vecOrigin );
	static Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	static Vector3( vecForward ), Vector3( vecRight ), Vector3( vecUp );
	engfunc( EngFunc_AngleVectors, vecViewAngle, vecForward, vecRight, vecUp );

	xs_vec_add_scaled( vecOrigin, vecForward, flForward, vecOrigin );
	xs_vec_add_scaled( vecOrigin, vecRight, flRight, vecOrigin );
	xs_vec_add_scaled( vecOrigin, vecUp, flUp, vecOrigin );
	xs_vec_copy( vecOrigin, vecStart );
}

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity )
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );
}
