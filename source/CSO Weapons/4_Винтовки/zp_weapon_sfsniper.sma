/**
 * Weapon by xUnicorn (t3rkecorejz) 
 *
 * Thanks a lot:
 *
 * Chrescoe1 & batcoh (Phenix) — First base code
 * KORD_12.7, wellasgood & 406 (Nightfury) — I'm taken some functions from this authors
 * D34, 404 & fl0wer — Some help
 * 
 * Download links:
 * 
 * beams.inc - https://forums.alliedmods.net/showthread.php?t=184780
 * api_smokewallpuff.inc - https://github.com/YoshiokaHaruki/AMXX-API-Smoke-WallPuff
 * non_reapi_support.inc - https://gist.github.com/YoshiokaHaruki/bcc9c6dbc6e23c69ea53d04c72a03cbd
 */

new const PluginName[ ] =					"[ZP] Weapon: Thunderbolt";
new const PluginVersion[ ] =				"1.0";
new const PluginAuthor[ ] =					"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague> // If you are not using ZombiePlague, just comment out this line
#include <reapi> // If you are not using ReAPI, delete or comment out this line

#tryinclude <beams_reapi>
#tryinclude <api_smokewallpuff> // If you don't need use this, just comment out this line

#if !defined _reapi_included
	#tryinclude <non_reapi_support>
#endif

/**
 * Automatically precache sounds from the model
 * 
 * If you have ReHLDS installed, you do not need this setting with a server cvar
 * `sv_auto_precache_sounds_in_models 1`
 */
#define PrecacheSoundsFromModel

/* ~ [ Extra-Items ] ~ */
#if defined _zombieplague_included
	new const ExtraItem_Name[ ] =			"Thunderbolt";
	const ExtraItem_Cost =					0;
#endif

/* ~ [ Weapon Settings ] ~ */
const WeaponUnicalIndex =					20112023;
new const WeaponReference[ ] =				"weapon_awp";
new const WeaponListDir[ ] =				"x_re/weapon_sfsniper";
new const WeaponNative[ ] =					"zp_give_user_sfsniper";
new const WeaponAnimation[ ] =				"rifle";
new const WeaponModelView[ ] =				"models/x_re/v_sfsniper_fx.mdl";
new const WeaponModelPlayer[ ] =			"models/x_re/p_sfsniper.mdl";
new const WeaponModelWorld[ ] =				"models/x_re/w_sfsniper.mdl";
new const WeaponSounds[ ][ ] = {
	"weapons/sfsniper-1.wav",
	"weapons/sfsniper_zoom.wav"
};
new const WeaponScanSound[ ] =				"sound/weapons/sfsniper_insight1.wav";

const ModelWorldBody = 						0;
const WeaponZoomFOV =						45;
new const WeaponZoomBodies[ ] =				{ 5, 8 };
const Float: WeaponScanTime =				0.5;

const WeaponMaxClip =						-1;
const WeaponDefaultAmmo =					20;

const Float: WeaponRate =					2.6; // Shooting Rate
const Float: WeaponMaxSpeed =				210.0; // Max Speed with active weapon

const WeaponDamage =						450;
const WeaponShotPenetration =				4;
const Float: WeaponRangeModifier =			0.99;
const Float: WeaponShotDistance =			8192.0;

#if defined _reapi_included
	// Settings for ReAPI
	const WeaponMaxAmmo =					20;
	const any: WeaponBulletType =			BULLET_PLAYER_338MAG;
#else
	// Settings for Non-ReAPI
	const Float: WeaponDamageMultiplier =	3.913; // Damage multiplier
#endif

/* ~ [ Beam ] ~ */
new const EntityBeamClassName[ ] =			"ent_beam_sfsniper";
new const EntityBeamSprite[ ] =				"sprites/laserbeam.spr";
const Float: EntityBeamWidth =				32.0;
const Float: EntityBeamBrightness =			255.0; 
const Float: EntityBeamDecrease =			5.0;
const Float: EntityBeamLifeTime =			1.5;
new const Float: EntityBeamColor[ ] =		{ 250.0, 60.0, 35.0 };

/* ~ [ Weapon Animations ] ~ */
enum {
	WeaponAnim_Dummy = 0,
	WeaponAnim_Idle,
	WeaponAnim_Shoot,
	WeaponAnim_Draw,
	WeaponAnim_Zoom
};

const Float: WeaponAnim_Idle_Time =			8.4;
const Float: WeaponAnim_Shoot_Time =		2.6;
const Float: WeaponAnim_Draw_Time =			1.4;
const Float: WeaponAnim_Zoom_Time =			1.5;

/* ~ [ Params ] ~ */
#if AMXX_VERSION_NUM <= 182
	new MaxClients;
	new Float: NULL_VECTOR[ 3 ];
#endif

#if defined _reapi_included
	new HookChain: gl_HookChain_IsPenetrableEntity_Post;
#else
	#if defined WeaponListDir
		new gl_iMsgHook_WeaponList;
		new gl_FM_Hook_RegUserMsg_Post;
		new gl_aWeaponListData[ 8 ];
	#endif
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
	new gl_iItemId;
#endif

new gl_bitsUserLeftHanded;
new Float: EntityBeamNextThink;

enum {
	Sound_Shoot = 0,
	Sound_ActivateZoom
};

/* ~ [ Macroses ] ~ */
#if AMXX_VERSION_NUM <= 183
	#define DONT_BLEED						-1
#endif

#if AMXX_VERSION_NUM <= 182
	#define OBS_IN_EYE						4
	#define MAX_PLAYERS						32
	#define MAX_NAME_LENGTH					32

	#define write_coord_f(%0)				engfunc( EngFunc_WriteCoord, %0 )
	stock message_begin_f( const iDest, const iMsgType, const Float: vecOrigin[ 3 ] = { 0.0, 0.0, 0.0 }, const pReceiver = 0 )
		engfunc( EngFunc_MessageBegin, iDest, iMsgType, vecOrigin, pReceiver );
#endif

#if !defined Vector3
	#define Vector3(%0)						Float: %0[ 3 ]
#endif

#define BIT_PLAYER(%0)						( BIT( %0 - 1 ) )
#define BIT_ADD(%0,%1)						( %0 |= %1 )
#define BIT_SUB(%0,%1)						( %0 &= ~%1 )
#define BIT_VALID(%0,%1)					( ( %0 & %1 ) == %1 )

#define IsNullVector(%0)					bool: ( ( %0[ 0 ] + %0[ 1 ] + %0[ 2 ] ) == 0.0 )
#define IsNullString(%0)					bool: ( %0[ 0 ] == EOS )
#define IsUserValid(%0)						bool: ( 0 < %0 <= MaxClients )
#define IsCustomWeapon(%0,%1)				bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponAmmoType(%0)				get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)				get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)				set_member( %0, m_rgAmmo, %1, %2 )
#define SetWeaponClip(%0,%1)				set_member( %0, m_Weapon_iClip, %1 )

#define m_Weapon_flNextUpdate				m_Weapon_flNextReload

#define var_body_cached						var_iuser1

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( )
{
	register_native( WeaponNative, "native_give_user_weapon" );
}

public plugin_precache( )
{
	new i;

	/* -> Precache Models <- */
	precache_model_ex( WeaponModelView );
	precache_model_ex( WeaponModelPlayer );
	precache_model_ex( WeaponModelWorld );

	/* -> Precache Sounds <- */
	for ( i = 0; i < sizeof WeaponSounds; i++ )
		precache_sound_ex( WeaponSounds[ i ] );

	precache_generic_ex( WeaponScanSound );

#if defined PrecacheSoundsFromModel
	UTIL_PrecacheSoundsFromModel( WeaponModelView );
#endif

#if defined WeaponListDir
	/* -> Hook Weapon <- */
	register_clcmd( WeaponListDir, "ClientCommand_HookWeapon" );

	/* -> Precache WeaponList <- */
	UTIL_PrecacheWeaponList( WeaponListDir );

	#if !defined _reapi_included
		/* -> Get MessageId < - */
		new iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

		if ( !iMsgId_Weaponlist )
			gl_FM_Hook_RegUserMsg_Post = register_forward( FM_RegUserMsg, "FM_Hook_RegUserMsg_Post", true );
		else
			gl_iMsgHook_WeaponList = register_message( iMsgId_Weaponlist, "MsgHook_WeaponList" );
	#endif
#endif
}

public plugin_init( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

#if !defined _reapi_included
	/* -> Messages <- */
	register_message( get_user_msgid( "CurWeapon" ), "MsgHook_CurWeapon" );
#endif

	/* -> Fakemeta <- */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

#if !defined _reapi_included
	register_forward( FM_SetModel, "FM_Hook_SetModel_Pre", false );
#else
	/* -> ReGameDLL <- */
	RegisterHookChain( RG_CWeaponBox_SetModel, "RG_CWeaponBox_SetModel_Pre", false );

	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post =
		RegisterHookChain( RG_IsPenetrableEntity, "RG_IsPenetrableEntity_Post", true )
	);
#endif

	/* -> HamSandwich: Weapon <- */
	RegisterHam( Ham_CS_Item_GetMaxSpeed, WeaponReference, "Ham_CWeapon_GetMaxSpeed_Pre", false );
	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_CWeapon_Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_CWeapon_Holster_Post", true );
	RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_CWeapon_PostFrame_Pre", false );
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Ham_CWeapon_AddToPlayer_Post", true );
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Pre", false );
	RegisterHam( Ham_Weapon_WeaponIdle, WeaponReference, "Ham_CWeapon_WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CWeapon_PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CWeapon_PrimaryAttack_Post", true );
	RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_CWeapon_SecondaryAttack_Pre", false );

#if !defined _reapi_included
	/* -> HamSandwich: Entity <- */
	RegisterHam( Ham_Think, "beam", "CBeam__Think", true );
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
	/* -> Register on Extra-Items <- */
	gl_iItemId = zp_register_extra_item( ExtraItem_Name, ExtraItem_Cost, ZP_TEAM_HUMAN );
#endif

#if !defined _reapi_included && defined WeaponListDir
	if ( gl_FM_Hook_RegUserMsg_Post )
		unregister_forward( FM_RegUserMsg, gl_FM_Hook_RegUserMsg_Post, true );

	unregister_message( get_user_msgid( "WeaponList" ), gl_iMsgHook_WeaponList );
#endif
}

public plugin_cfg( )
{
	/* -> Other <- */
#if AMXX_VERSION_NUM <= 182
	#if defined _reapi_included
		MaxClients = get_member_game( m_nMaxPlayers );
	#else
		MaxClients = get_maxplayers( );
	#endif
#endif

	EntityBeamNextThink = ( EntityBeamDecrease / EntityBeamBrightness ) * EntityBeamLifeTime;
}

public bool: native_give_user_weapon( const iPlugin, const iParams )
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !is_user_connected( pPlayer ) )
	{
		log_error( AMX_ERR_NATIVE, "[AMXX] Invalid Player (Id: %i)", pPlayer );
		return false;
	}

	return CPlayer_GiveWeapon( pPlayer );
}

public client_putinserver( pPlayer )
{
	if ( !is_user_bot( pPlayer ) )
		query_client_cvar( pPlayer, "cl_righthand", "CPlayer_CheckLeftHand" );
}

public client_disconnected( pPlayer ) BIT_SUB( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) );

public ClientCommand_HookWeapon( const pPlayer )
{
	engclient_cmd( pPlayer, WeaponReference );
	return PLUGIN_HANDLED;
}

#if defined _zombieplague_included && defined ExtraItem_Name
	/* ~ [ Zombie Plague ] ~ */
	public zp_extra_item_selected( pPlayer, iItemId )
	{
		if ( iItemId != gl_iItemId )
			return PLUGIN_HANDLED;

		return CPlayer_GiveWeapon( pPlayer ) ? PLUGIN_CONTINUE : ZP_PLUGIN_HANDLED;
	}
#endif

#if !defined _reapi_included
	/* ~ [ Messages ] ~ */
	#if defined WeaponListDir
		public MsgHook_WeaponList( const iMsgId, const iMsgDest, const pReceiver )
		{
			// Method by KORD_12.7
			if ( !pReceiver )
			{
				new szWeaponName[ MAX_NAME_LENGTH ];
				get_msg_arg_string( 1, szWeaponName, charsmax( szWeaponName ) );

				if ( !strcmp( szWeaponName, WeaponReference ) )
				{
					for ( new i, a = sizeof gl_aWeaponListData; i < a; i++ )
						gl_aWeaponListData[ i ] = get_msg_arg_int( i + 2 );
				}
			}
		}
	#endif

	public MsgHook_CurWeapon( const iMsgId, const iMsgDest, const pReceiver )
	{
		enum { arg_is_active = 1, arg_weapon_id, arg_clip_ammo };

		if ( !is_user_alive( pReceiver ) || is_user_bot( pReceiver ) || is_user_hltv( pReceiver ) )
			return;

		static pActiveItem; pActiveItem = get_member( pReceiver, m_pActiveItem );
		if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
			return;

		if ( get_msg_arg_int( arg_is_active ) == 0 )
			return;

		if ( get_msg_arg_int( arg_weapon_id ) != get_member( pActiveItem, m_iId ) )
			return;

		if ( get_msg_arg_int( arg_clip_ammo ) != WeaponMaxClip )
		{
			SetWeaponClip( pActiveItem, WeaponMaxClip );
			set_msg_arg_int( arg_clip_ammo, ARG_BYTE, WeaponMaxClip );
		}
	}
#endif

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
	static iSpecMode, pTarget;
	pTarget = ( iSpecMode = get_entvar( pPlayer, var_iuser1 ) ) ? get_entvar( pPlayer, var_iuser2 ) : pPlayer;

	if ( !is_user_connected( pTarget ) )
		return;

	static pActiveItem; pActiveItem = get_member( pPlayer, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
		return;

	set_cd( CD_Handle, CD_flNextAttack, 2.0 );

	enum eSpecInfo {
		SPEC_MODE,
		SPEC_TARGET
	};
	static aSpecInfo[ MAX_PLAYERS + 1 ][ eSpecInfo ];

	if ( iSpecMode )
	{
		if ( aSpecInfo[ pPlayer ][ SPEC_MODE ] != iSpecMode )
		{
			aSpecInfo[ pPlayer ][ SPEC_MODE ] = iSpecMode;
			aSpecInfo[ pPlayer ][ SPEC_TARGET ] = 0;
		}

		if ( iSpecMode == OBS_IN_EYE && aSpecInfo[ pPlayer ][ SPEC_TARGET ] != pTarget )
			aSpecInfo[ pPlayer ][ SPEC_TARGET ] = pTarget;
	}

	static Float: flLastEventCheck; flLastEventCheck = get_member( pActiveItem, m_flLastEventCheck );
	if ( !flLastEventCheck )
	{
		set_cd( CD_Handle, CD_WeaponAnim, WeaponAnim_Dummy );
		return;
	}

	if ( flLastEventCheck <= get_gametime( ) )
	{
		UTIL_SendWeaponAnim( MSG_ONE, pTarget, pActiveItem, WeaponAnim_Draw );
		set_member( pActiveItem, m_flLastEventCheck, 0.0 );
	}
}

#if !defined _reapi_included
	public FM_Hook_SetModel_Pre( const pWeaponBox )
	{
		if ( !FClassnameIs( pWeaponBox, "weaponbox" ) )
			return FMRES_IGNORED;

		new pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
		if ( pItem == NULLENT || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return FMRES_IGNORED;

		engfunc( EngFunc_SetModel, pWeaponBox, WeaponModelWorld );
		set_entvar( pWeaponBox, var_body, ModelWorldBody );

		return FMRES_SUPERCEDE;
	}

	#if defined WeaponListDir
		public FM_Hook_RegUserMsg_Post( const szName[ ] )
		{
			// Method by wellasgood
			if ( strcmp( szName, "WeaponList" ) == 0 )
				gl_iMsgHook_WeaponList = register_message( get_orig_retval( ), "MsgHook_WeaponList" );
		}
	#endif
#else
	/* ~ [ ReGameDLL ] ~ */
	public RG_CWeaponBox_SetModel_Pre( const pWeaponBox ) 
	{
		new pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
		if ( pItem == NULLENT || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return HC_CONTINUE;

		SetHookChainArg( 2, ATYPE_STRING, WeaponModelWorld );
		set_entvar( pWeaponBox, var_body, ModelWorldBody );

		return HC_CONTINUE;
	}

	public RG_IsPenetrableEntity_Post( const Vector3( vecStart ), Vector3( vecEnd ), const pAttacker, const pHit )
	{
		static pActiveItem;
		if ( ( pActiveItem = get_member( pAttacker, m_pActiveItem ) ) && !is_nullent( pActiveItem ) && IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
			set_entvar( pActiveItem, var_endpos, vecEnd );

		static iPointContents; iPointContents = engfunc( EngFunc_PointContents, vecEnd );
		if ( iPointContents == CONTENTS_SKY )
			return;

		if ( pHit && is_nullent( pHit ) || ( get_entvar( pHit, var_flags ) & FL_KILLME ) || !ExecuteHam( Ham_IsBSPModel, pHit ) )
			return;

		static iRenderMode; iRenderMode = get_entvar( pHit, var_rendermode );
		if ( iRenderMode != kRenderTransAlpha )
		{
			static iDecalIndex; if ( !iDecalIndex ) iDecalIndex = engfunc( EngFunc_DecalIndex, "{gaussshot1" );
			UTIL_TE_GUNSHOTDECAL( MSG_PAS, vecEnd, pHit, iDecalIndex );
		}

		if ( iPointContents == CONTENTS_WATER )
			return;

		static Vector3( vecPlaneNormal ); global_get( glb_trace_plane_normal, vecPlaneNormal );

	#if defined _api_smokewallpuff_included
		zc_smoke_wallpuff_draw( vecEnd, vecPlaneNormal );
	#endif

		xs_vec_mul_scalar( vecPlaneNormal, random_float( 25.0, 30.0 ), vecPlaneNormal );
		UTIL_TE_STREAK_SPLASH( MSG_PAS, vecEnd, vecPlaneNormal, 7, random_num( 10, 20 ), 3, 64 );
	}
#endif

/* ~ [ HamSandwich ] ~ */
public Ham_CWeapon_GetMaxSpeed_Pre( const pItem )
{
	if ( is_nullent( pItem ) )
		return HAM_IGNORED;

	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
	{
		new Float: flWeaponSpeed; GetHamReturnFloat( flWeaponSpeed );
		if ( flWeaponSpeed != 0.0 )
		{
			SetHamReturnFloat( flWeaponSpeed );
			return HAM_OVERRIDE;
		}

		return HAM_IGNORED;
	}

	SetHamReturnFloat( Float: WeaponMaxSpeed );
	return HAM_OVERRIDE;
}

public Ham_CWeapon_Deploy_Post( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );
	if ( !IsUserValid( pPlayer ) )
		return;

	set_entvar( pPlayer, var_viewmodel, WeaponModelView );
	set_entvar( pPlayer, var_weaponmodel, WeaponModelPlayer );
	set_entvar( pItem, var_body, 0 ); // Here u can add native for get hands body
	set_entvar( pItem, var_body_cached, get_entvar( pItem, var_body ) );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Dummy );

	set_member( pItem, m_flLastEventCheck, get_gametime( ) + 0.1 );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Draw_Time );
	set_member( pPlayer, m_flNextAttack, WeaponAnim_Draw_Time );
#if defined _reapi_included
	set_member( pPlayer, m_szAnimExtention, WeaponAnimation );
#else
	set_pdata_string( pPlayer, m_szAnimExtention * 4, WeaponAnimation, -1, linux_diff_player * linux_diff_animating );
#endif
}

public Ham_CWeapon_Holster_Post( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );
	if ( !IsUserValid( pPlayer ) )
		return;

	if ( is_user_connected( pPlayer ) && !is_user_bot( pPlayer ) )
		query_client_cvar( pPlayer, "cl_righthand", "CPlayer_CheckLeftHand" );

	set_entvar( pItem, var_enemy, NULLENT );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pItem, m_Weapon_flNextUpdate, 0.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

public Ham_CWeapon_PostFrame_Pre( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	if ( !IsUserValid( pPlayer ) )
		return HAM_IGNORED;

	if ( get_member( pPlayer, m_bResumeZoom ) )
	{
		set_entvar( pItem, var_body, WeaponZoomBodies[ 0 ] );
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Zoom );
	}

	if ( get_member( pPlayer, m_iFOV ) != DEFAULT_NO_ZOOM )
	{
		static Float: flGameTime; flGameTime = get_gametime( );
		if ( 0.0 < Float: get_member( pItem, m_Weapon_flNextUpdate ) <= flGameTime )
		{
			static pTarget, bool: bTargetFinded, Vector3( vecEndPos );
			bTargetFinded = false;

			if ( ( pTarget = UTIL_GetEyePointAiming( pPlayer, WeaponShotDistance, vecEndPos ) ) && IsUserValid( pTarget ) )
			{
			#if defined _zombieplague_included
				if ( zp_get_user_zombie( pTarget ) )
			#else
				if ( !IsSimilarPlayersTeam( pPlayer, pTarget ) )
			#endif
					bTargetFinded = true;
			}

			if ( bTargetFinded )
				client_cmd( pPlayer, "spk ^"%s^"", WeaponScanSound );

			set_entvar( pItem, var_body, WeaponZoomBodies[ bTargetFinded ] );

			static pEnemy; pEnemy = get_entvar( pItem, var_enemy );
			if ( IsUserValid( pEnemy ) && !bTargetFinded || !IsUserValid( pEnemy ) && bTargetFinded )
				set_member( pItem, m_Weapon_flTimeWeaponIdle, 0.0 );

			set_entvar( pItem, var_enemy, bTargetFinded ? pTarget : NULLENT );
			set_member( pItem, m_Weapon_flNextUpdate, flGameTime + Float: WeaponScanTime );
		}
	}

	return HAM_IGNORED;
}

public Ham_CWeapon_AddToPlayer_Post( const pItem, const pPlayer )
{
	if ( is_nullent( pItem ) )
		return;

	new iWeaponKey = get_entvar( pItem, var_impulse );
	if ( iWeaponKey != WeaponUnicalIndex )
	{
	#if defined WeaponListDir
		#if defined _reapi_included
			UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
		#else
			if ( iWeaponKey == 0 )
				UTIL_WeaponList( MSG_ONE, pPlayer, WeaponReference );
		#endif
	#endif
		return;
	}

	if ( get_entvar( pItem, var_owner ) <= 0 )
	{
		SetWeaponClip( pItem, WeaponMaxClip );

	#if defined _reapi_included
		rg_set_iteminfo( pItem, ItemInfo_iMaxClip, WeaponMaxClip );
		rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WeaponMaxAmmo );
	#endif

		new iAmmoType = GetWeaponAmmoType( pItem );
		if ( GetWeaponAmmo( pPlayer, iAmmoType ) < WeaponDefaultAmmo )
			SetWeaponAmmo( pPlayer, WeaponDefaultAmmo, iAmmoType );
	}

#if defined WeaponListDir
	#if defined _reapi_included
		rg_set_iteminfo( pItem, ItemInfo_pszName, WeaponListDir );
		UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
	#else
		UTIL_WeaponList( MSG_ONE, pPlayer, WeaponListDir );
	#endif
#endif
}

public Ham_CWeapon_Reload_Pre( const pItem ) return ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) ) ? HAM_IGNORED : HAM_SUPERCEDE;

public Ham_CWeapon_WeaponIdle_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( Float: get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	static bool: bUseZoom; bUseZoom = bool: ( get_member( pPlayer, m_iFOV ) != DEFAULT_NO_ZOOM );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, bUseZoom ? WeaponAnim_Zoom : WeaponAnim_Idle );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, bUseZoom ? WeaponAnim_Zoom_Time : WeaponAnim_Idle_Time );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PrimaryAttack_Pre( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );
	if ( !IsUserValid( pPlayer ) )
		return HAM_IGNORED;

	static iAmmoType; if ( !iAmmoType ) iAmmoType = get_member( pItem, m_Weapon_iPrimaryAmmoType );
	new iAmmo = GetWeaponAmmo( pPlayer, iAmmoType );
	if ( !iAmmo )
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, 0.2 );

		return HAM_SUPERCEDE;
	}

	static iFOV;
	if ( ( iFOV = get_member( pPlayer, m_iFOV ) ) && iFOV != DEFAULT_NO_ZOOM )
	{
		set_entvar( pItem, var_body, get_entvar( pItem, var_body_cached ) );

		set_member( pPlayer, m_bResumeZoom, true );
		set_member( pPlayer, m_iLastZoom, iFOV );
		set_member( pPlayer, m_iFOV, DEFAULT_NO_ZOOM );
	}

	new Vector3( vecVelocity ); get_entvar( pPlayer, var_velocity, vecVelocity );
	new Float: flSpread, Float: flVelocityLen = xs_vec_len_2d( vecVelocity );

	// https://github.com/s1lentq/ReGameDLL_CS/blob/master/regamedll/dlls/wpn_shared/wpn_awp.cpp#L97-L116
	new bitsUserFlags = get_entvar( pPlayer, var_flags );
	if ( ~bitsUserFlags & FL_ONGROUND )
		flSpread = 0.85
	else if ( flVelocityLen > 140.0 )
		flSpread = 0.25;
	else if ( flVelocityLen > 10.0 )
		flSpread = 0.1;
	if ( bitsUserFlags & FL_DUCKING )
		flSpread = 0.0;
	else
		flSpread = 0.001;

#if defined _reapi_included
	EnableHookChain( gl_HookChain_IsPenetrableEntity_Post );
	{
		new Vector3( vecSrc ); UTIL_GetEyePosition( pPlayer, vecSrc );
		new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );

		// https://github.com/s1lentq/ReGameDLL_CS/blob/master/regamedll/dlls/wpn_shared/wpn_awp.cpp#L173
		rg_fire_bullets3( pItem, pPlayer, vecSrc, vecAiming, flSpread, WeaponShotDistance, WeaponShotPenetration, WeaponBulletType, WeaponDamage, WeaponRangeModifier, false, get_member( pPlayer, random_seed ) );

		rg_set_animation( pPlayer, PLAYER_ATTACK1 );
	}
	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post );
#else
	UTIL_FakeFireBullets3( pItem, pPlayer, flSpread, WeaponShotDistance, WeaponShotPenetration, float( WeaponDamage ), WeaponRangeModifier, true, 7 );

	#if !defined _reapi_included
		static szPlayerAnim[ 32 ]; formatex( szPlayerAnim, charsmax( szPlayerAnim ), "%s_shoot_%s", get_entvar( pPlayer, var_flags ) & FL_DUCKING ? "crouch" : "ref", WeaponAnimation );
		UTIL_PlayerAnimation( pPlayer, szPlayerAnim );
	#endif
#endif

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Shoot );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_Shoot ] );

	SetWeaponAmmo( pPlayer, --iAmmo, iAmmoType );
	set_member( pPlayer, m_flNextAttack, WeaponRate );
	set_entvar( pItem, var_enemy, NULLENT );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Shoot_Time );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PrimaryAttack_Post( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new Vector3( vecEndPos ); get_entvar( pItem, var_endpos, vecEndPos );
	if ( IsNullVector( vecEndPos ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );
	if ( !IsUserValid( pPlayer ) )
		return;

	new Vector3( vecStartPos );
	UTIL_GetWeaponPosition( pPlayer, 40.0, BIT_VALID( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) ) ? -5.0 : 5.0, -5.0, vecStartPos );

	new pBeam = Beam_Create( EntityBeamSprite, EntityBeamWidth );
	if ( !is_nullent( pBeam ) )
	{
		set_entvar( pBeam, var_classname, EntityBeamClassName );

		Beam_PointsInit( pBeam, vecStartPos, vecEndPos );
		Beam_SetBrightness( pBeam, EntityBeamBrightness );
		Beam_SetColor( pBeam, EntityBeamColor );
		// Beam_SetFlags( pBeam, BEAM_FSHADEIN );

		set_entvar( pBeam, var_nextthink, get_gametime( ) );

	#if defined _reapi_included
		SetThink( pBeam, "CBeam__Think" );
	#else
		set_entvar( pBeam, var_impulse, WeaponUnicalIndex );
	#endif
	}

	set_entvar( pItem, var_endpos, NULL_VECTOR );
}

public Ham_CWeapon_SecondaryAttack_Pre( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );
	if ( !IsUserValid( pPlayer ) )
		return HAM_IGNORED;

	new bool: bUseZoom = bool: ( get_member( pPlayer, m_iFOV ) == DEFAULT_NO_ZOOM );

	set_entvar( pItem, var_body, bUseZoom ? WeaponZoomBodies[ 0 ] : get_entvar( pItem, var_body_cached ) );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, bUseZoom ? WeaponAnim_Zoom : WeaponAnim_Idle );
	rh_emit_sound2( pPlayer, 0, CHAN_ITEM, WeaponSounds[ Sound_ActivateZoom ] );

	set_member( pPlayer, m_iFOV, bUseZoom ? WeaponZoomFOV : DEFAULT_NO_ZOOM );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, 0.3 );
	set_member( pItem, m_Weapon_flNextUpdate, bUseZoom ? 0.001 : 0.0 );

	return HAM_SUPERCEDE;
}

/* ~ [ Other ] ~ */
public bool: CPlayer_GiveWeapon( const pPlayer )
{
	if ( !is_user_alive( pPlayer ) )
		return false;

	new pItem = rg_give_custom_item( pPlayer, WeaponReference, GT_DROP_AND_REPLACE, WeaponUnicalIndex );
	if ( is_nullent( pItem ) )
		return false;

	return true;
}

public CPlayer_CheckLeftHand( const pPlayer, const szCvar[ ], const szValue[ ] )
{
	equal( szValue, "1" ) ? BIT_SUB( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) ) : BIT_ADD( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) );
}

public CBeam__Think( const pBeam )
{
#if !defined _reapi_included
	if ( is_nullent( pBeam ) || get_entvar( pBeam, var_impulse ) != WeaponUnicalIndex )
		return;
#endif

	set_entvar( pBeam, var_nextthink, get_gametime( ) + EntityBeamNextThink );

	static Float: flBrightness; flBrightness = Float: Beam_GetBrightness( pBeam );
	if ( ( flBrightness -= EntityBeamDecrease ) && flBrightness <= 0.0 )
	{
		UTIL_KillEntity( pBeam );
		return;
	}

	Beam_SetBrightness( pBeam, flBrightness );
}

/* ~ [ Stocks ] ~ */
#if !defined _zombieplague_included
	stock bool: IsSimilarPlayersTeam( const pPlayer, const pTarget )
	{
		if ( get_member( pPlayer, m_iTeam ) == get_member( pTarget, m_iTeam ) )
			return true;

		return false;
	}
#endif

#if defined PrecacheSoundsFromModel
	/* -> Automaticly precache Sounds from Model <- */
	/**
	 * This stock is not needed if you use ReHLDS
	 * with this console command 'sv_auto_precache_sounds_in_models 1'
	 **/
	stock UTIL_PrecacheSoundsFromModel( const szModelPath[ ] )
	{
		new pFile;
		if ( !( pFile = fopen( szModelPath, "rt" ) ) )
			return;
		
		new szSoundPath[ 64 ];
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek( pFile, 164, SEEK_SET );
		fread( pFile, iNumSeq, BLOCK_INT );
		fread( pFile, iSeqIndex, BLOCK_INT );
		
		for ( new i = 0; i < iNumSeq; i++ )
		{
			fseek( pFile, iSeqIndex + 48 + 176 * i, SEEK_SET );
			fread( pFile, iNumEvents, BLOCK_INT );
			fread( pFile, iEventIndex, BLOCK_INT );
			fseek( pFile, iEventIndex + 176 * i, SEEK_SET );
			
			for ( new k = 0; k < iNumEvents; k++ )
			{
				fseek( pFile, iEventIndex + 4 + 76 * k, SEEK_SET );
				fread( pFile, iEvent, BLOCK_INT );
				fseek( pFile, 4, SEEK_CUR );
				
				if ( iEvent != 5004 )
					continue;
				
				fread_blocks( pFile, szSoundPath, 64, BLOCK_CHAR );
				
				if ( strlen( szSoundPath ) )
				{
					strtolower( szSoundPath );
				#if AMXX_VERSION_NUM < 190
					format( szSoundPath, charsmax( szSoundPath ), "sound/%s", szSoundPath );
					precache_generic_ex( szSoundPath );
				#else
					precache_generic_ex( fmt( "sound/%s", szSoundPath ) );
				#endif
				}
			}
		}
		
		fclose( pFile );
	}
#endif

#if defined WeaponListDir
	/* -> Automaticly precache WeaponList <- */
	stock UTIL_PrecacheWeaponList( const szWeaponList[ ] )
	{
		new szBuffer[ 128 ], pFile;

		format( szBuffer, charsmax( szBuffer ), "sprites/%s.txt", szWeaponList );
		precache_generic_ex( szBuffer );

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

		#if AMXX_VERSION_NUM < 190
			formatex( szBuffer, charsmax( szBuffer ), "sprites/%s.spr", szSprName );
			precache_generic_ex( szBuffer );
		#else
			precache_generic_ex( fmt( "sprites/%s.spr", szSprName ) );
		#endif
		}

		fclose( pFile );
	}

	/* -> Weapon List <- */
	#if defined _reapi_included
		stock UTIL_WeaponList( const iDest, const pReceiver, const pItem, szWeaponName[ MAX_NAME_LENGTH ] = "", const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
		{
			if ( szWeaponName[ 0 ] == EOS )
				rg_get_iteminfo( pItem, ItemInfo_pszName, szWeaponName, charsmax( szWeaponName ) )

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
	#else
		/* -> Weapon List <- */
		stock UTIL_WeaponList( const iDist, const pReceiver, const szWeaponName[ ], const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
		{
			static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );
			
			message_begin( iDist, iMsgId_Weaponlist, .player = pReceiver );
			write_string( szWeaponName );
			write_byte( ( iPrimaryAmmoType <= -2 ) ? gl_aWeaponListData[ 0 ] : iPrimaryAmmoType );
			write_byte( ( iMaxPrimaryAmmo <= -2 ) ? gl_aWeaponListData[ 1 ] : iMaxPrimaryAmmo );
			write_byte( ( iSecondaryAmmoType <= -2 ) ? gl_aWeaponListData[ 2 ] : iSecondaryAmmoType );
			write_byte( ( iMaxSecondaryAmmo <= -2 ) ? gl_aWeaponListData[ 3 ] : iMaxSecondaryAmmo );
			write_byte( ( iSlot <= -2 ) ? gl_aWeaponListData[ 4 ] : iSlot );
			write_byte( ( iPosition <= -2 ) ? gl_aWeaponListData[ 5 ] : iPosition );
			write_byte( ( iWeaponId <= -2 ) ? gl_aWeaponListData[ 6 ] : iWeaponId );
			write_byte( ( iFlags <= -2 ) ? gl_aWeaponListData[ 7 ] : iFlags );
			message_end( );
		}
	#endif
#endif

#if !defined _reapi_included
	/* -> Fake firebullets3 <- */
	// https://gist.github.com/YoshiokaHaruki/56c65fbe8352646e754905f70837ef22
	// https://github.com/s1lentq/ReGameDLL_CS/blob/e199b164635d5237d3ae7c6a4f0bdabd8c7c2a7e/regamedll/dlls/cbase.cpp#L1232
	stock UTIL_FakeFireBullets3( const pItem, const pPlayer, const Float: flSpread = 0.0, Float: flDistance = 8192.0, iPenetration = 0, Float: flDamage, const Float: flRangeModifier, const bool: bSparks = false, const iSparksColor = 4 )
	{
		new Vector3( vecOrigin ); UTIL_GetEyePosition( pPlayer, vecOrigin );

		new Vector3( vecPunchAngle ); get_entvar( pPlayer, var_punchangle, vecPunchAngle );
		new Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
		xs_vec_add( vecViewAngle, vecPunchAngle, vecViewAngle );

		new Vector3( vecForward ), Vector3( vecRight ), Vector3( vecUp );
		engfunc( EngFunc_AngleVectors, vecViewAngle, vecForward, vecRight, vecUp );

		new Float: flX, Float: flY, Float: flZ;
		do
		{
			flX = random_float( -0.5, 0.5 ) + random_float( -0.5, 0.5 );
			flY = random_float( -0.5, 0.5 ) + random_float( -0.5, 0.5 );
			flZ = flX * flX + flY * flY;
		}
		while ( flZ > 1.0 );

		new Vector3( vecDirection ), Vector3( vecEnd );
		vecDirection[ 0 ] = vecForward[ 0 ] + flX * flSpread * vecRight[ 0 ] + flY * flSpread * vecUp[ 0 ];
		vecDirection[ 1 ] = vecForward[ 1 ] + flX * flSpread * vecRight[ 1 ] + flY * flSpread * vecUp[ 1 ];
		vecDirection[ 2 ] = vecForward[ 2 ] + flX * flSpread * vecRight[ 2 ] + flY * flSpread * vecUp[ 2 ];

		vecEnd[ 0 ] = vecOrigin[ 0 ] + vecDirection[ 0 ] * flDistance;
		vecEnd[ 1 ] = vecOrigin[ 1 ] + vecDirection[ 1 ] * flDistance;
		vecEnd[ 2 ] = vecOrigin[ 2 ] + vecDirection[ 2 ] * flDistance;

		// BULLET_PLAYER_338MAG
		new Float: flPenetrationPower = 45.0;
		new Float: flPenetrationDistance = 8000.0;

		new Float: flCurrentDistance;
		new Float: flDamageModifier = 0.5;
		new Float: flDistanceModifier;

		new pTrace = create_tr2( ), pHit, bool: bIsBSP, iPointContents;
		new Float: flFraction, Vector3( vecEndPos ), Vector3( vecPlaneNormal );

		while ( iPenetration )
		{
			engfunc( EngFunc_TraceLine, vecOrigin, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTrace );
			get_tr2( pTrace, TR_flFraction, flFraction );

			new szTextureName[ 64 ]; engfunc( EngFunc_TraceTexture, 0, vecOrigin, vecEnd, szTextureName, charsmax( szTextureName ) );
			new cTextureType = dllfunc( DLLFunc_PM_FindTextureType, szTextureName );

			switch ( cTextureType )
			{
				case 'M': flPenetrationPower *= 0.15, flDamageModifier = 0.2; // CHAR_TEX_METAL
				case 'C': flPenetrationPower *= 0.25; // CHAR_TEX_CONCRETE
				case 'G': flPenetrationPower *= 0.5, flDamageModifier = 0.4; // CHAR_TEX_GRATE
				case 'V': flPenetrationPower *= 0.5, flDamageModifier = 0.45; // CHAR_TEX_VENT
				case 'T': flPenetrationPower *= 0.65, flDamageModifier = 0.3; // CHAR_TEX_TILE
				case 'P': flPenetrationPower *= 0.4, flDamageModifier = 0.45; // CHAR_TEX_COMPUTER
				case 'W': flDamageModifier = 0.6; // CHAR_TEX_WOOD
			}

			if ( flFraction != 1.0 )
			{
				pHit = get_tr2( pTrace, TR_pHit );
				pHit = pHit > 0 ? pHit : 0;
				bIsBSP = bool: ( get_entvar( pHit, var_solid ) == SOLID_BSP );

				iPenetration--;

				flCurrentDistance = flFraction * flDistance;
				flDamage *= floatpower( flRangeModifier, flCurrentDistance / 500.0 );

				if ( flCurrentDistance > flPenetrationDistance ) iPenetration = 0;

				if ( !bIsBSP || !iPenetration )
				{
					flPenetrationPower = 42.0;
					flDamageModifier = 0.75;
					flDistanceModifier = 0.75;
				}
				else flDistanceModifier = 0.5

				get_tr2( pTrace, TR_vecEndPos, vecEndPos );
				set_entvar( pItem, var_endpos, vecEndPos );

				iPointContents = engfunc( EngFunc_PointContents, vecEndPos );
				if ( bIsBSP && iPointContents != CONTENTS_SKY )
				{
					static iRenderMode; iRenderMode = get_entvar( pHit, var_rendermode );
					if ( iRenderMode != kRenderTransAlpha )
					{
						static iDecalIndex; if ( !iDecalIndex ) iDecalIndex = engfunc( EngFunc_DecalIndex, "{gaussshot1" );
						UTIL_TE_GUNSHOTDECAL( MSG_PAS, vecEndPos, pHit, iDecalIndex );
					}

					if ( bSparks && iPointContents != CONTENTS_WATER )
					{
						get_tr2( pTrace, TR_vecPlaneNormal, vecPlaneNormal );

					#if defined _api_smokewallpuff_included
						zc_smoke_wallpuff_draw( vecEndPos, vecPlaneNormal );
					#endif

						xs_vec_mul_scalar( vecPlaneNormal, random_float( 25.0, 30.0 ), vecPlaneNormal );
						UTIL_TE_STREAK_SPLASH( MSG_PVS, vecEndPos, vecPlaneNormal, iSparksColor, random_num( 10, 20 ), 3, 64 );
					}
				}

				vecOrigin[ 0 ] = vecEndPos[ 0 ] + vecDirection[ 0 ] * flPenetrationPower;
				vecOrigin[ 1 ] = vecEndPos[ 1 ] + vecDirection[ 1 ] * flPenetrationPower;
				vecOrigin[ 2 ] = vecEndPos[ 2 ] + vecDirection[ 2 ] * flPenetrationPower;

				flDistance = ( flDistance - flCurrentDistance ) * flDistanceModifier;

				vecEnd[ 0 ] = vecOrigin[ 0 ] + vecDirection[ 0 ] * flDistance;
				vecEnd[ 1 ] = vecOrigin[ 1 ] + vecDirection[ 1 ] * flDistance;
				vecEnd[ 2 ] = vecOrigin[ 2 ] + vecDirection[ 2 ] * flDistance;
				
				UTIL_FakeTraceAttack( pHit, pItem, pPlayer, flDamage, /*vecEndPos,*/ vecDirection, pTrace, DMG_BULLET|DMG_NEVERGIB );
				flDamage *= flDamageModifier;
			}
			else iPenetration = 0;
		}

		free_tr2( pTrace );
	}

	/* -> Fake TraceAttack <- */
	stock UTIL_FakeTraceAttack( const pVictim, const pInflictor, const pAttacker, const Float: flBaseDamage, const Vector3( vecDirection ), const pTrace, bitsDamageType )
	{
		if ( get_entvar( pVictim, var_takedamage ) == DAMAGE_NO )
			return false;

		if ( is_user_alive( pVictim ) )
		{
			#if defined _zombieplague_included
				if ( !zp_get_user_zombie( pVictim ) )
			#else
				if ( IsSimilarPlayersTeam( pVictim, pAttacker ) )
			#endif
					return false;
		}

		new Vector3( vecPunchAngle );
		new Vector3( vecEndPos ); get_tr2( pTrace, TR_vecEndPos, vecEndPos );
		new iHitGroup = get_tr2( pTrace, TR_iHitgroup );
		new Float: flDamage = flBaseDamage;

		switch ( iHitGroup )
		{
			case HIT_HEAD:
			{
				flDamage *= 4.0;
				vecPunchAngle[ 0 ] = floatmax( flDamage * -0.5, -12.0 );
				vecPunchAngle[ 2 ] = floatclamp( flDamage * random_float( -1.0, 1.0 ), -9.0, 9.0 );
			}
			case HIT_CHEST:
			{
				flDamage *= 1.0;
				vecPunchAngle[ 0 ] = floatmax( flDamage * -0.1, -4.0 );
			}
			case HIT_STOMACH:
			{
				flDamage *= 1.25;
				vecPunchAngle[ 0 ] = floatmax( flDamage * -0.1, -4.0 );
			}
			case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 0.75;
		}

		if ( xs_vec_len( vecPunchAngle ) )
			set_entvar( pVictim, var_punchangle, vecPunchAngle );

		set_member( pVictim, m_LastHitGroup, iHitGroup );
		ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pAttacker, flDamage, bitsDamageType );

		static iBloodColor;
		if ( ( iBloodColor = ExecuteHamB( Ham_BloodColor, pVictim ) ) != DONT_BLEED )
		{
			UTIL_TE_BLOODSPRITE( MSG_PVS, vecEndPos, iBloodColor, floatround( flDamage ) );
			ExecuteHamB( Ham_TraceBleed, pVictim, flDamage, vecDirection, pTrace, bitsDamageType );
		}

		return true;
	}

	/* -> TE_BLOODSPRITE <- */
	stock UTIL_TE_BLOODSPRITE( const iDest, const Vector3( vecOrigin ), const iColor, iAmount )
	{
		if ( iColor == DONT_BLEED || !iAmount )
			return;

		iAmount = clamp( iAmount * 2, 1, 255 );

		static _iszModelIndex_BloodSpray;
		if ( !_iszModelIndex_BloodSpray )
			_iszModelIndex_BloodSpray = engfunc( EngFunc_ModelIndex, "sprites/bloodspray.spr" );

		static _iszModelIndex_BloodDrop;
		if ( !_iszModelIndex_BloodDrop )
			_iszModelIndex_BloodDrop = engfunc( EngFunc_ModelIndex, "sprites/blood.spr" );
		
		message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
		write_byte( TE_BLOODSPRITE );
		write_coord_f( vecOrigin[ 0 ] );
		write_coord_f( vecOrigin[ 1 ] );
		write_coord_f( vecOrigin[ 2 ] );
		write_short( _iszModelIndex_BloodSpray );
		write_short( _iszModelIndex_BloodDrop );
		write_byte( iColor );
		write_byte( clamp( iAmount / 10, 3, 16 ) );
		message_end( );
	}
#endif

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

/* -> Get player end eye position of aiming (w/o Trace) <- */
stock UTIL_GetEyePointAiming( const pPlayer, const Float: flDistance, Vector3( vecEndPos ), const iIgnoreId = 0/*DONT_IGNORE_MONSTERS*/ )
{
	new Vector3( vecStart ); UTIL_GetEyePosition( pPlayer, vecStart );
	new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );
	new Vector3( vecEnd ); xs_vec_add_scaled( vecStart, vecAiming, flDistance, vecEnd );

	engfunc( EngFunc_TraceLine, vecStart, vecEnd, iIgnoreId, pPlayer, 0 );
	get_tr2( 0, TR_vecEndPos, vecEndPos );

	return get_tr2( 0, TR_pHit );
}

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity )
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );
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

/* -> Get Weapon Position <- */
stock UTIL_GetWeaponPosition( const pPlayer, const Float: flForward, const Float: flRight, const Float: flUp, Vector3( vecStart ) ) 
{
	new Vector3( vecOrigin ); UTIL_GetEyePosition( pPlayer, vecOrigin );
	new Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	new Vector3( vecForward ), Vector3( vecRight ), Vector3( vecUp );
	engfunc( EngFunc_AngleVectors, vecViewAngle, vecForward, vecRight, vecUp );

	xs_vec_add_scaled( vecOrigin, vecForward, flForward, vecOrigin );
	xs_vec_add_scaled( vecOrigin, vecRight, flRight, vecOrigin );
	xs_vec_add_scaled( vecOrigin, vecUp, flUp, vecOrigin );
	xs_vec_copy( vecOrigin, vecStart );
}

#if !defined _reapi_included
	/* -> Entity Animation <- */
	stock UTIL_SetEntityAnim( const pEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0 )
	{
		set_entvar( pEntity, var_frame, flFrame );
		set_entvar( pEntity, var_framerate, flFrameRate );
		set_entvar( pEntity, var_animtime, get_gametime( ) );
		set_entvar( pEntity, var_sequence, iSequence );
	}

	/* -> Player Animation <- */
	stock UTIL_PlayerAnimation( const pPlayer, const szAnim[ ] ) 
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
		set_member( pPlayer, m_Activity, ACT_RANGE_ATTACK1 );
		set_member( pPlayer, m_IdealActivity, ACT_RANGE_ATTACK1 );
		set_member( pPlayer, m_flLastFired, flGameTime );
	}
#endif

// by Nordic Warrior
stock precache_model_ex( const szFileName[ ] )
{
	if ( IsNullString( szFileName ) )
		return 0;

	if ( file_exists( szFileName ) )
		return engfunc( EngFunc_PrecacheModel, szFileName );

#if AMXX_VERSION_NUM <= 182
	new szError[ 128 ]; formatex( szError, charsmax( szError ), "Model <%s> not found. The plugin has been stopped.", szFileName );
	set_fail_state( szError );
#else
	set_fail_state( "Model <%s> not found. The plugin has been stopped.", szFileName );
#endif

	return 0;
}

stock precache_sound_ex( const szFileName[ ], const bool: bStopPlugin = false )
{
	if ( IsNullString( szFileName ) )
		return 0;

#if AMXX_VERSION_NUM <= 182
	new szTempBuffer[ 64 ]; format( szTempBuffer, charsmax( szTempBuffer ), "sound/%s", szFileName );
	if ( file_exists( szTempBuffer ) )
#else
	if ( file_exists( fmt( "sound/%s", szFileName ) ) )
#endif
		return engfunc( EngFunc_PrecacheSound, szFileName );

	if ( bStopPlugin )
	{
	#if AMXX_VERSION_NUM <= 182
		new szError[ 128 ]; formatex( szError, charsmax( szError ), "Sound <%s> not found. The plugin has been stopped.", szFileName );
		set_fail_state( szError );
	#else
		set_fail_state( "Sound <%s> not found. The plugin has been stopped.", szFileName );
	#endif
	}
	else
		log_amx( "Sound <%s> not found.", szFileName );

	return 0;
}

stock precache_generic_ex( const szFileName[ ], const bool: bStopPlugin = false )
{
	if ( IsNullString( szFileName ) )
		return 0;

	if ( file_exists( szFileName ) )
		return engfunc( EngFunc_PrecacheGeneric, szFileName );

	if ( bStopPlugin )
	{
	#if AMXX_VERSION_NUM <= 182
		new szError[ 128 ]; formatex( szError, charsmax( szError ), "Generic file <%s> not found. The plugin has been stopped.", szFileName );
		set_fail_state( szError );
	#else
		set_fail_state( "Generic file <%s> not found. The plugin has been stopped.", szFileName );
	#endif
	}
	else
		log_amx( "Generic file <%s> not found.", szFileName );

	return 0;
}
