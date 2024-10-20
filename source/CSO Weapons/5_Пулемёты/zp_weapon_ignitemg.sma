new const PluginName[ ] =					"[ZP] Weapon: IGNITE-7";
new const PluginVersion[ ] =				"1.0";
new const PluginAuthor[ ] =					"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <zombieplague>

//#tryinclude <api_muzzleflash>
#tryinclude <api_smokewallpuff>

#include <reapi>

#if !defined _reapi_included
	#include <non_reapi_support>
#endif

#if !defined DMG_GRENADE
	#define DMG_GRENADE						(1<<24)
#endif

/**
 * Automatically precache sounds (to generic) from the model
 * 
 * If you have ReHLDS installed, you do not need this setting with a server cvar
 * `sv_auto_precache_sounds_in_models 1`
 */
#define PrecacheSoundsFromModel

/**
 * Use optimized sprites.
 * Implies to use sprites that are smaller, fewer extra/repeated frames.
 * Also, with these sprites, you are less likely to catch
 * the "Hunk_AllocName: failed on n bytes" error when starting the server.
 * Also use this setting if you can't set the '-heapsize' value for your server.
 */
// #define UseOptimizedSprites

#if defined _zombieplague_included
	/* ~ [ Extra-Items ] ~ */
	new const ExtraItem_Name[ ] =			"IGNITE-7";
	const ExtraItem_Cost =					0;
#endif

/* ~ [ Weapon Settings ] ~ */
const WeaponUnicalIndex =					16062023;
new const WeaponReference[ ] =				"weapon_m249";
new const WeaponListDir[ ] =				"x_re/weapon_ignitemg";
new const WeaponAnimation[ ] =				"m249"; // Original: m134
new const WeaponNative[ ] =					"zp_give_user_ignitemg";
new const WeaponModelView[ ] =				"models/x_re/v_ignitemg.mdl";
new const WeaponModelPlayer[ ] =			"models/x_re/p_ignitemg.mdl";
new const WeaponModelWorld[ ] =				"models/x_re/w_ignitemg.mdl";
new const WeaponSounds[ ][ ] = {
	"weapons/ignitemg-1.wav",
	"weapons/ignitemg_shoot2_loop.wav",
	"weapons/ignitemg_shoot2_loop_end.wav"
};

const ModelWorldBody =						0; // w_ model submodel body
const Float: WeaponMaxSpeed =				210.0; // Maxspeed with weapon

// Primary Attack (General settings)
const WeaponMaxClip =						120; // Max clip. Original: 150, but, cs 1.6 hud can't show AMMO Hud > 126
const WeaponDefaultAmmo =					200; // Default ammo
const WeaponReloadClip =					30; // How clip reload at once
const Float: WeaponRate =					0.13; // Weapon shoot rate
const Float: WeaponAccuracy =				0.2; // Start Accuracy
const Float: WeaponRecoil =					1.0; // Recoil multiplier

#if defined _reapi_included
	// Settings for ReAPI
	const WeaponMaxAmmo =					200; // Max backpack ammo
	const WeaponDamage =					41; // Base damage
	const WeaponShotPenetration =			2; // Penetration
	const Float: WeaponRangeModifier =		0.97; // Range modifier
	const Float: WeaponShotDistance =		8192.0; // Max shoot distance
	const Bullet: WeaponBulletType =		BULLET_PLAYER_556MM; // Bullet type
#else
	// Settings for Non-ReAPI
	const Float: WeaponDamageMultiplier =	1.11; // Damage multiplier
#endif

// Secondary Attack
/**
 * Use ammo2 hud to display Secondary Ammo in Ammo HUD. Works only with custom WeaponList.
 * If you'r server have money hud, disable this setting.
 */
#define UseSecondaryAmmoHud

#if defined WeaponListDir && defined UseSecondaryAmmoHud
	const WeaponSecondaryAmmoIndex =			19; // 15-31 only. Change if conflict with another weapons
#endif	

const WeaponSecondaryAmmoDefault =			0; // Default secondary ammo when u buy weapon
const WeaponSecondaryAmmoMax =				25; // Max secondary ammo
const Float: WeaponSecondaryChargeTime =	1.0; // Charge time for +1 secondary ammo

const Float: WeaponSecondaryRate =			0.25; // Secondary Mode shoot rate
const Float: WeaponSecondaryDistance =		175.0; // Distance + radius for search victims
const Float: WeaponSecondaryPainShock =		0.7; // Painshock (VelocityModifier) power for victim [From 0.0 to 1.0]
const Float: WeaponSecondaryDamage =		250.0; // Damage for laser
const WeaponSecondaryDamageType =			DMG_GRENADE;

new const WeaponSecondary_BeamSprite[ ] =	"sprites/laserbeam.spr"; // Beam sprite
new const WeaponSecondary_BeamColor[ 3 ] =	{ 243, 156, 18 }; // Color of beam
const WeaponSecondary_BeamWidth =			12; // Beam width
const WeaponSecondary_BeamNoise =			32; // Beam noise

new const WeaponSecondary_HitSprite[ ] =	"sprites/x_re/ef_ignitemg_hit_fx.spr"; // Hit sprite
const WeaponSecondary_HitScale =			4; // Hit sprite scale
const WeaponSecondary_HitFrameRate =		12; // Hit sprite framerate

#if defined _api_muzzleflash_included
	/* ~ [ Muzzle-Flash ] ~ */
	new const MuzzleFlashSprites[ ][ ] = {
	#if defined UseOptimizedSprites
		"sprites/x_re/fx/muzzleflash321.spr", // Mode A shoot
		"sprites/x_re/fx/muzzleflash322.spr" // Mode B shoot
	#else
		"sprites/x_re/muzzleflash321.spr", // Mode A shoot
		"sprites/x_re/muzzleflash322.spr" // Mode B shoot
	#endif
	};
#endif

/* ~ [ Weapon Animations ] ~ */
enum {
	WeaponAnim_Idle = 0,
	WeaponAnim_Shoot1,
	WeaponAnim_Shoot2,
	WeaponAnim_Reload,
	WeaponAnim_Draw1,
	WeaponAnim_Draw2,
	WeaponAnim_Shoot_Empty,
	WeaponAnim_ShootMode_Start = 8,
	WeaponAnim_ShootMode_Loop,	
	WeaponAnim_ShootMode_End,
	WeaponAnim_Dummy
};

const Float: WeaponAnim_Idle_Time =				2.4
const Float: WeaponAnim_Shoot_Time =			0.43
const Float: WeaponAnim_Reload_Time =			1.0
const Float: WeaponAnim_Draw_Time =				1.0
const Float: WeaponAnim_ShootMode_Start_Time =	0.37
const Float: WeaponAnim_ShootMode_Loop_Time =	1.0
const Float: WeaponAnim_ShootMode_End_Time =	0.7

/* ~ [ Params ] ~ */
#if defined _zombieplague_included && defined ExtraItem_Name
	new gl_iItemId;
#endif

#if AMXX_VERSION_NUM <= 182
	new MaxClients;
#endif

#if defined _reapi_included
	new HookChain: gl_HookChain_IsPenetrableEntity_Post;
#else
	new HamHook: gl_HamHook_TraceAttack[ 4 ];

	#if defined WeaponListDir
		new gl_iMsgHook_WeaponList;
		new gl_FM_Hook_RegUserMsg_Post;
		new gl_aWeaponListData[ 8 ];
	#endif
#endif

#if defined _api_muzzleflash_included
	enum eMuzzleFlashes {
		MuzzleFlash: Muzzle_ShootA,
		MuzzleFlash: Muzzle_ShootB_Loop
	};
	new MuzzleFlash: gl_iMuzzleId[ eMuzzleFlashes ];
#endif

enum eSounds {
	Sound_Shoot = 0,
	Sound_ShootMode_Loop,
	Sound_ShootMode_End
};

enum eModelIndex {
	ModelIndex_Trail,
	ModelIndex_Hit
};
new gl_iszModelIndex[ eModelIndex ];

enum ( <<= 1 ) {
	WeaponState_OnShootMode = 1
};

/* ~ [ Macroses ] ~ */
#if AMXX_VERSION_NUM <= 182
	#define OBS_IN_EYE							4

	#define write_coord_f(%0)					engfunc( EngFunc_WriteCoord, %0 )
	stock message_begin_f( const iDest, const iMsgType, const Float: vecOrigin[ 3 ] = { 0.0, 0.0, 0.0 }, const pReceiver = 0 )
		engfunc( EngFunc_MessageBegin, iDest, iMsgType, vecOrigin, pReceiver );
#endif

#if !defined Vector3
	#define Vector3(%0)							Float: %0[ 3 ]
#endif

#define BIT_ADD(%0,%1)							( %0 |= %1 )
#define BIT_SUB(%0,%1)							( %0 &= ~%1 )
#define BIT_VALID(%0,%1)						( ( %0 & %1 ) == %1 )

#define IsCustomWeapon(%0,%1)					bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponState(%0)						get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)					set_member( %0, m_Weapon_iWeaponState, %1 )
#define GetWeaponClip(%0)						get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)					set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)					get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)					get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)					set_member( %0, m_rgAmmo, %1, %2 )

#define var_secondary_ammo						var_gaitsequence // pWeapon
#define var_next_charge							var_starttime // pWeapon
#define var_next_sound 							var_impacttime // pWeapon

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( ) register_native( WeaponNative, "native_give_user_weapon" );

public plugin_precache( )
{
	/* -> Precache Models <- */
	engfunc( EngFunc_PrecacheModel, WeaponModelView );
	engfunc( EngFunc_PrecacheModel, WeaponModelPlayer );
	engfunc( EngFunc_PrecacheModel, WeaponModelWorld );

	/* -> Precache Sounds <- */
	for ( new i; i < sizeof WeaponSounds; i++ )
		engfunc( EngFunc_PrecacheSound, WeaponSounds[ i ] );

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

	/* -> Model Index <- */
	gl_iszModelIndex[ ModelIndex_Trail ] = engfunc( EngFunc_PrecacheModel, WeaponSecondary_BeamSprite );
	gl_iszModelIndex[ ModelIndex_Hit ] = engfunc( EngFunc_PrecacheModel, WeaponSecondary_HitSprite );

#if defined _api_muzzleflash_included
	/* -> Muzzle-Flash <- */
	gl_iMuzzleId[ Muzzle_ShootA ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ 0 ], 1, 0.08, Float: WeaponRate * 1.5 );
	gl_iMuzzleId[ Muzzle_ShootB_Loop ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ 1 ], 1, 0.08, Float: WeaponSecondaryRate * 2.0 );
#endif
}

public plugin_init( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

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

	/* -> HamSandwich <- */
	RegisterHam( Ham_CS_Item_GetMaxSpeed, WeaponReference, "Ham_CWeapon_GetMaxSpeed_Pre", false );
	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_CWeapon_Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_CWeapon_Holster_Post", true );
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Pre", false );
	RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_CWeapon_PostFrame_Pre", false );
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Ham_CWeapon_AddToPlayer_Post", true );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CWeapon_PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_CWeapon_SecondaryAttack_Pre", false );

#if !defined _reapi_included
	/* -> HamSandwich: Trace Attack <- */
	new const TraceAttack_CallBack[ ] = "Ham_CEntity_TraceAttack_Pre";

	gl_HamHook_TraceAttack[ 0 ] = RegisterHam( Ham_TraceAttack,	"func_breakable", TraceAttack_CallBack, false );
	gl_HamHook_TraceAttack[ 1 ] = RegisterHam( Ham_TraceAttack,	"info_target", TraceAttack_CallBack, false );
	gl_HamHook_TraceAttack[ 2 ] = RegisterHam( Ham_TraceAttack,	"player", TraceAttack_CallBack, false );
	gl_HamHook_TraceAttack[ 3 ] = RegisterHam( Ham_TraceAttack,	"hostage_entity", TraceAttack_CallBack, false );
	
	ToggleTraceAttack( false );
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
	/* -> Register on Extra-Items <- */
	gl_iItemId = zp_register_extra_item( ExtraItem_Name, ExtraItem_Cost, ZP_TEAM_HUMAN );
#endif

	/* -> Other <- */
#if AMXX_VERSION_NUM <= 182
	#if defined _reapi_included
		MaxClients = get_member_game( m_nMaxPlayers );
	#else
		MaxClients = get_maxplayers( );
	#endif
#endif

#if defined WeaponListDir && !defined _reapi_included
	if ( gl_FM_Hook_RegUserMsg_Post )
		unregister_forward( FM_RegUserMsg, gl_FM_Hook_RegUserMsg_Post, true );

	unregister_message( get_user_msgid( "WeaponList" ), gl_iMsgHook_WeaponList );
#endif
}

public bool: native_give_user_weapon( const iPluginId, const iParamsCount ) 
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !is_user_connected( pPlayer ) )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Invalid Player (%i)", pPlayer );
		return false;
	}

	return CPlayer_GiveWeapon( pPlayer );
}

#if defined WeaponListDir
	public ClientCommand_HookWeapon( const pPlayer )
	{
		engclient_cmd( pPlayer, WeaponReference );
		return PLUGIN_HANDLED;
	}
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
	/* ~ [ Zombie Plague ] ~ */
	public zp_extra_item_selected( pPlayer, iItemId ) 
	{
		if ( iItemId != gl_iItemId )
			return PLUGIN_HANDLED;

		return CPlayer_GiveWeapon( pPlayer ) ? PLUGIN_CONTINUE : ZP_PLUGIN_HANDLED;
	}
#endif

#if defined WeaponListDir && !defined _reapi_included
	/* ~ [ Messages ] ~ */
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

#if defined WeaponListDir && !defined _reapi_included
	public FM_Hook_RegUserMsg_Post( const szName[ ] )
	{
		// Method by wellasgood
		if ( strcmp( szName, "WeaponList" ) == 0 )
			gl_iMsgHook_WeaponList = register_message( get_orig_retval( ), "MsgHook_WeaponList" );
	}
#endif

#if !defined _reapi_included
	public FM_Hook_SetModel_Pre( const pWeaponBox )
	{
		if ( !FClassnameIs( pWeaponBox, "weaponbox" ) )
			return FMRES_IGNORED;

		static pItem; pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
		if ( pItem == NULLENT || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return FMRES_IGNORED;

		engfunc( EngFunc_SetModel, pWeaponBox, WeaponModelWorld );
		set_entvar( pWeaponBox, var_body, ModelWorldBody );

		return FMRES_SUPERCEDE;
	}

	public FM_Hook_PlaybackEvent_Pre( ) return FMRES_SUPERCEDE;
	public FM_Hook_TraceLine_Post( const Vector3( vecStart ), Vector3( vecEnd ), const bitsFlags, const pAttacker, const pTrace )
	{
		if ( bitsFlags & IGNORE_MONSTERS )
			return;

		static Float: flFraction; get_tr2( pTrace, TR_flFraction, flFraction );
		if ( flFraction == 1.0 )
			return;

		get_tr2( pTrace, TR_vecEndPos, vecEnd );

		static iPointContents; iPointContents = engfunc( EngFunc_PointContents, vecEnd );
		if ( iPointContents == CONTENTS_SKY )
			return;

		new pHit = ( pHit = get_tr2( pTrace, TR_pHit ) ) == -1 ? 0 : pHit;
		if ( pHit && is_nullent( pHit ) || ( get_entvar( pHit, var_flags ) & FL_KILLME ) || !ExecuteHam( Ham_IsBSPModel, pHit ) )
			return;

		UTIL_GunshotDecalTrace( pHit, vecEnd );

		if ( iPointContents == CONTENTS_WATER )
			return;

		static Vector3( vecPlaneNormal ); get_tr2( pTrace, TR_vecPlaneNormal, vecPlaneNormal );

	#if defined _api_smokewallpuff_included
		zc_smoke_wallpuff_draw( vecEnd, vecPlaneNormal );
	#endif

		xs_vec_mul_scalar( vecPlaneNormal, random_float( 25.0, 30.0 ), vecPlaneNormal );
		UTIL_TE_STREAK_SPLASH( MSG_PAS, vecEnd, vecPlaneNormal, 4, random_num( 10, 20 ), 3, 64 );
	}
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

	public RG_IsPenetrableEntity_Post( const Vector3( vecStart ), Vector3( vecEnd ), const pPlayer, const pHit )
	{
		static iPointContents; iPointContents = engfunc( EngFunc_PointContents, vecEnd );
		if ( iPointContents == CONTENTS_SKY )
			return;

		if ( pHit && is_nullent( pHit ) || ( get_entvar( pHit, var_flags ) & FL_KILLME ) || !ExecuteHam( Ham_IsBSPModel, pHit ) )
			return;

		UTIL_GunshotDecalTrace( pHit, vecEnd );

		if ( iPointContents == CONTENTS_WATER )
			return;

		static Vector3( vecPlaneNormal ); global_get( glb_trace_plane_normal, vecPlaneNormal );

	#if defined _api_smokewallpuff_included
		zc_smoke_wallpuff_draw( vecEnd, vecPlaneNormal );
	#endif

		xs_vec_mul_scalar( vecPlaneNormal, random_float( 25.0, 30.0 ), vecPlaneNormal );
		UTIL_TE_STREAK_SPLASH( MSG_PAS, vecEnd, vecPlaneNormal, 4, random_num( 10, 20 ), 3, 64 );
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

	new pPlayer;
	if ( ( pPlayer = get_member( pItem, m_pPlayer ) ) <= 0 )
		return;

	set_entvar( pPlayer, var_viewmodel, WeaponModelView );
	set_entvar( pPlayer, var_weaponmodel, WeaponModelPlayer );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, random_num( WeaponAnim_Draw1, WeaponAnim_Draw2 ) );

	// Charge After Deploy
	new iSecondaryAmmo = get_entvar( pItem, var_secondary_ammo );
	if ( iSecondaryAmmo < WeaponSecondaryAmmoMax )
	{
		new Float: flGameTime = get_gametime( );
		new Float: flNextCharge; get_entvar( pItem, var_next_charge, flNextCharge );

		if ( 0.0 < flNextCharge < flGameTime )
		{
			CWeapon_UpdateSecondaryAmmo( pItem, pPlayer, iSecondaryAmmo = min( iSecondaryAmmo + floatround( ( flGameTime - flNextCharge ) / WeaponSecondaryChargeTime, floatround_floor ), WeaponSecondaryAmmoMax ) );
			set_entvar( pItem, var_next_charge, ( iSecondaryAmmo >= WeaponSecondaryAmmoMax ) ? 0.0 : flGameTime + WeaponSecondaryChargeTime );
		}
	}

	set_member( pItem, m_Weapon_iShotsFired, 0 );
	set_member( pItem, m_Weapon_flAccuracy, WeaponAccuracy );
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

	new pPlayer;
	if ( ( pPlayer = get_member( pItem, m_pPlayer ) ) <= 0 )
		return;

#if defined _api_muzzleflash_included
	if ( is_user_connected( pPlayer ) && !is_user_bot( pPlayer ) )
		zc_muzzle_destroy( pPlayer );
#endif

	UTIL_ResetTimingSound( pPlayer, pItem, CHAN_WEAPON, WeaponSounds[ Sound_ShootMode_Loop ] );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_ShootMode_End ], .flags = SND_STOP );

	UTIL_TE_KILLBEAM( MSG_BROADCAST, pPlayer|0x1000 );

	SetWeaponState( pItem, 0 );
	set_entvar( pItem, var_next_charge, get_gametime( ) );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

public Ham_CWeapon_Reload_Pre( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	new pPlayer;
	if ( ( pPlayer = get_member( pItem, m_pPlayer ) ) <= 0 )
		return HAM_IGNORED;

	if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
		return HAM_SUPERCEDE;

	new iClip = GetWeaponClip( pItem );
#if defined _reapi_included
	if ( iClip >= rg_get_iteminfo( pItem, ItemInfo_iMaxClip ) )
#else
	if ( iClip >= WeaponMaxClip )
#endif
		return HAM_SUPERCEDE;

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Reload );

	set_member( pItem, m_Weapon_iShotsFired, 0 );
	set_member( pItem, m_Weapon_fInReload, true );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time );
	set_member( pPlayer, m_flNextAttack, WeaponAnim_Reload_Time );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PostFrame_Pre( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	if ( pPlayer <= 0 )
		return HAM_IGNORED;

	static bitsButton; bitsButton = get_entvar( pPlayer, var_button );

	// Reload
	if ( get_member( pItem, m_Weapon_fInReload ) )
	{
		new iAmmoType = GetWeaponAmmoType( pItem );
		new iAmmo = GetWeaponAmmo( pPlayer, iAmmoType );
		new iClip = GetWeaponClip( pItem );
		new iReloadClip = min( WeaponReloadClip, ( iAmmo < WeaponReloadClip && ( iClip + iAmmo ) < WeaponMaxClip ) ? iAmmo : WeaponMaxClip - iClip );

		SetWeaponClip( pItem, iClip + iReloadClip );
		SetWeaponAmmo( pPlayer, max( 0, iAmmo - iReloadClip ), iAmmoType );
		set_member( pItem, m_Weapon_fInReload, false );

		return HAM_IGNORED;
	}

#if !defined _reapi_included
	// Force SecondaryAttack when press ATTACK2
	if ( bitsButton & IN_ATTACK2 && Float: get_member( pItem, m_Weapon_flNextSecondaryAttack ) < 0.0 )
	{
		ExecuteHamB( Ham_Weapon_SecondaryAttack, pItem );

		bitsButton &= ~IN_ATTACK2;
		set_entvar( pPlayer, var_button, bitsButton );

		return HAM_IGNORED;
	}
#endif

	// Charge
	static iSecondaryAmmo; iSecondaryAmmo = get_entvar( pItem, var_secondary_ammo );
	if ( iSecondaryAmmo < WeaponSecondaryAmmoMax )
	{
		static Float: flGameTime; flGameTime = get_gametime( );
		static Float: flNextCharge; get_entvar( pItem, var_next_charge, flNextCharge );

		if ( 0.0 < flNextCharge < flGameTime )
		{
			CWeapon_UpdateSecondaryAmmo( pItem, pPlayer, ++iSecondaryAmmo );
			set_entvar( pItem, var_next_charge, flGameTime + WeaponSecondaryChargeTime );
		}
	}

	// Weapon State
	static bitsWeaponState;
	if ( ( bitsWeaponState = GetWeaponState( pItem ) ) && BIT_VALID( bitsWeaponState, WeaponState_OnShootMode ) && ( ~bitsButton & IN_ATTACK2 || !iSecondaryAmmo ) )
	{
		CWeapon_ShootModeEnd( pItem, pPlayer, bitsWeaponState );
	}

	return HAM_IGNORED;
}

public Ham_CWeapon_AddToPlayer_Post( const pItem, const pPlayer )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	if ( get_entvar( pItem, var_owner ) <= 0 )
	{
	#if defined _reapi_included
		set_member( pItem, m_Weapon_bHasSecondaryAttack, true );

		rg_set_iteminfo( pItem, ItemInfo_iMaxClip, WeaponMaxClip );
		rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WeaponMaxAmmo );
	#endif

	#if defined WeaponListDir
		rg_set_iteminfo( pItem, ItemInfo_pszName, WeaponListDir );
	#endif

	#if defined WeaponListDir && defined UseSecondaryAmmoHud
		set_member( pItem, m_Weapon_iSecondaryAmmoType, WeaponSecondaryAmmoIndex );

		#if defined _reapi_included
			rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo2, WeaponSecondaryAmmoMax );
		#endif
	#endif

		new iAmmoType = GetWeaponAmmoType( pItem );
		if ( GetWeaponAmmo( pPlayer, iAmmoType ) < WeaponDefaultAmmo )
			SetWeaponAmmo( pPlayer, WeaponDefaultAmmo, iAmmoType );

		SetWeaponClip( pItem, WeaponMaxClip );

		set_entvar( pItem, var_secondary_ammo, WeaponSecondaryAmmoDefault );
		set_entvar( pItem, var_next_charge, get_gametime( ) );
	}

	CWeapon_UpdateSecondaryAmmo( pItem, pPlayer, get_entvar( pItem, var_secondary_ammo ) );

#if defined WeaponListDir
	#if defined _reapi_included
		UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
	#else
		static iSecondaryAmmoType, iSecondaryAmmoMax;

		if ( iSecondaryAmmoType == 0 && iSecondaryAmmoMax == 0 )
		{
		#if defined UseSecondaryAmmoHud
			iSecondaryAmmoType = WeaponSecondaryAmmoIndex;
			iSecondaryAmmoMax = WeaponSecondaryAmmoMax;
		#else
			iSecondaryAmmoType = iSecondaryAmmoMax = -2;
		#endif
		}

		UTIL_WeaponList( MSG_ONE, pPlayer, WeaponListDir, _, _, iSecondaryAmmoType, iSecondaryAmmoMax );
	#endif
#endif
}

public Ham_CWeapon_PrimaryAttack_Pre( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static iClip; iClip = GetWeaponClip( pItem );
	if ( !iClip )
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, 0.2 );

		return HAM_SUPERCEDE;
	}

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	if ( pPlayer <= 0 )
		return HAM_IGNORED;

	static bitsFlags; bitsFlags = get_entvar( pPlayer, var_flags );
	static Vector3( vecVelocity ); get_entvar( pPlayer, var_velocity, vecVelocity );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, random_num( WeaponAnim_Shoot1, WeaponAnim_Shoot2 ) );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_Shoot ] );

#if defined _api_muzzleflash_included
	zc_muzzle_draw( pPlayer, gl_iMuzzleId[ Muzzle_ShootA ] );
#endif

#if defined _reapi_included
	static iShotsFired; iShotsFired = get_member( pItem, m_Weapon_iShotsFired ); iShotsFired++;
	static Float: flAccuracy; flAccuracy = get_member( pItem, m_Weapon_flAccuracy );
	static Float: flSpread;

	if ( ~bitsFlags & FL_ONGROUND )
		flSpread = 0.135 + ( 0.5 * flAccuracy );
	else if ( xs_vec_len_2d( vecVelocity ) > 140.0 )
		flSpread = 0.0265 + ( 0.095 * flAccuracy );
	else flSpread = 0.0 * flAccuracy;

	if ( flAccuracy )
		flAccuracy = floatmin( ( ( iShotsFired * iShotsFired * iShotsFired ) / 175.0 ) + 0.4, 0.9 );

	EnableHookChain( gl_HookChain_IsPenetrableEntity_Post );
	{
		static Vector3( vecSrc ); UTIL_GetEyePosition( pPlayer, vecSrc );
		static Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );

		rg_fire_bullets3( pItem, pPlayer, vecSrc, vecAiming, flSpread, WeaponShotDistance, WeaponShotPenetration, WeaponBulletType, WeaponDamage, WeaponRangeModifier, false, get_member( pPlayer, random_seed ) );
	}
	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post );

	rg_set_animation( pPlayer, PLAYER_ATTACK1 );

	SetWeaponClip( pItem, --iClip );
	set_member( pItem, m_Weapon_iShotsFired, iShotsFired );
	set_member( pItem, m_Weapon_flAccuracy, flAccuracy );
#else
	static _FM_Hook_PlayBackEvent_Pre; _FM_Hook_PlayBackEvent_Pre = register_forward( FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false );
	static _FM_Hook_TraceLine_Post; _FM_Hook_TraceLine_Post = register_forward( FM_TraceLine, "FM_Hook_TraceLine_Post", true );
	ToggleTraceAttack( true );

	ExecuteHam( Ham_Weapon_PrimaryAttack, pItem );

	unregister_forward( FM_PlaybackEvent, _FM_Hook_PlayBackEvent_Pre );
	unregister_forward( FM_TraceLine, _FM_Hook_TraceLine_Post, true );
	ToggleTraceAttack( false );
#endif

	if ( ~bitsFlags & FL_ONGROUND )
		UTIL_WeaponKickBack( pItem, pPlayer, 1.15, 0.65, 0.35, 0.035, 4.75, 3.75, 4 );
	else if ( xs_vec_len_2d( vecVelocity ) > 0.0 )
		UTIL_WeaponKickBack( pItem, pPlayer, 0.95, 0.425, 0.235, 0.025, 4.35, 3.95, 9 );
	else if ( bitsFlags & FL_DUCKING )
		UTIL_WeaponKickBack( pItem, pPlayer, 0.65, 0.425, 0.215, 0.025, 4.0, 3.35, 14 );
	else
		UTIL_WeaponKickBack( pItem, pPlayer, 0.85, 0.475, 0.265, 0.025, 4.05, 3.6, 12 );

	set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponRate );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponRate );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Shoot_Time );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_SecondaryAttack_Pre( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	if ( pPlayer <= 0 )
		return HAM_IGNORED;

	static iSecondaryAmmo; iSecondaryAmmo = get_entvar( pItem, var_secondary_ammo );
	if ( !iSecondaryAmmo )
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pItem, m_Weapon_flNextSecondaryAttack, 0.2 );

		return HAM_SUPERCEDE;
	}

	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	static iWeaponAnimIndex, Float: flIdleTime, Float: flNextAttack;

	if ( BIT_VALID( bitsWeaponState, WeaponState_OnShootMode ) )
	{
		iWeaponAnimIndex = WeaponAnim_ShootMode_Loop;
		flIdleTime = WeaponAnim_ShootMode_Loop_Time;
		flNextAttack = WeaponSecondaryRate;

	#if defined _reapi_included
		rg_set_animation( pPlayer, PLAYER_ATTACK1 );
	#else
		static szPlayerAnim[ 32 ]; formatex( szPlayerAnim, charsmax( szPlayerAnim ), "%s_shoot_%s", get_entvar( pPlayer, var_flags ) & FL_DUCKING ? "crouch" : "ref", WeaponAnimation );
		UTIL_PlayerAnimation( pPlayer, szPlayerAnim );
	#endif

		UTIL_PlayTimingSound( pPlayer, pItem, CHAN_WEAPON, WeaponSounds[ Sound_ShootMode_Loop ], 1.5 );
		CWeapon_UpdateSecondaryAmmo( pItem, pPlayer, --iSecondaryAmmo );

	#if defined _api_muzzleflash_included
		zc_muzzle_draw( pPlayer, gl_iMuzzleId[ Muzzle_ShootB_Loop ] );
	#endif

		static bool: bCheckAttachment;
		static Vector3( vecSrc ); UTIL_GetEyePointAiming( pPlayer, WeaponSecondaryDistance, vecSrc );
		static iBeamLifeTime; if ( iBeamLifeTime <= 0 ) iBeamLifeTime = floatround( WeaponSecondaryRate * 10.0 );

		for ( new pVictim = 1, Vector3( vecEndPos ); pVictim <= MaxClients; pVictim++ )
		{
			if ( !is_user_alive( pVictim ) || pVictim == pPlayer )
				continue;

			if ( get_entvar( pVictim, var_takedamage ) == DAMAGE_NO )
				continue;

		#if defined _zombieplague_included
			if ( !zp_get_user_zombie( pVictim ) )
		#else
			if ( IsSimilarPlayersTeam( pVictim, pPlayer ) )
		#endif
				continue;

			get_entvar( pVictim, var_origin, vecEndPos );
			if ( xs_vec_distance( vecSrc, vecEndPos ) >= WeaponSecondaryDistance )
				continue;

			bCheckAttachment = true;

			UTIL_TE_BEAMENTPOINT( MSG_BROADCAST, pPlayer|0x1000, gl_iszModelIndex[ ModelIndex_Trail ], vecEndPos, 0, 0, iBeamLifeTime, WeaponSecondary_BeamWidth, WeaponSecondary_BeamNoise, WeaponSecondary_BeamColor, 255, 64 );
			UTIL_TE_EXPLOSION( MSG_BROADCAST, gl_iszModelIndex[ ModelIndex_Hit ], vecEndPos, 0.0, WeaponSecondary_HitScale, WeaponSecondary_HitFrameRate );

			set_member( pVictim, m_LastHitGroup, HIT_GENERIC );
			ExecuteHamB( Ham_TakeDamage, pVictim, pItem, pPlayer, WeaponSecondaryDamage, WeaponSecondaryDamageType );

			set_member( pVictim, m_flVelocityModifier, WeaponSecondaryPainShock );
		}

		if ( !bCheckAttachment )
			UTIL_TE_BEAMENTPOINT( MSG_BROADCAST, pPlayer|0x1000, gl_iszModelIndex[ ModelIndex_Trail ], vecSrc, 0, 0, iBeamLifeTime, WeaponSecondary_BeamWidth, WeaponSecondary_BeamNoise, WeaponSecondary_BeamColor, 255, 64 );

		bCheckAttachment = false;
	}
	else
	{
		iWeaponAnimIndex = WeaponAnim_ShootMode_Start;
		flIdleTime = flNextAttack = WeaponAnim_ShootMode_Start_Time;

		set_entvar( pItem, var_next_charge, 0.0 );
		BIT_ADD( bitsWeaponState, WeaponState_OnShootMode );
	}

	if ( iWeaponAnimIndex != -1 && get_entvar( pPlayer, var_weaponanim ) != iWeaponAnimIndex )
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iWeaponAnimIndex );

	iWeaponAnimIndex = -1;

	SetWeaponState( pItem, bitsWeaponState );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, flNextAttack );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, flNextAttack );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flIdleTime );

	return HAM_SUPERCEDE;
}

#if !defined _reapi_included
	public Ham_CEntity_TraceAttack_Pre( const pVictim, const pAttacker, const Float: flDamage )
	{
		if ( !is_user_connected( pAttacker ) )
			return HAM_IGNORED;

		static pActiveItem; pActiveItem = get_member( pAttacker, m_pActiveItem );
		if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
			return HAM_IGNORED;

		SetHamParamFloat( 3, flDamage * WeaponDamageMultiplier );
		return HAM_IGNORED;
	}
#endif

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

public bool: CWeapon_ShootModeEnd( const pItem, const pPlayer, &bitsWeaponState )
{
	if ( !BIT_VALID( bitsWeaponState, WeaponState_OnShootMode ) )
		return false;

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_ShootMode_End );
	UTIL_ResetTimingSound( pPlayer, pItem, CHAN_WEAPON, WeaponSounds[ Sound_ShootMode_Loop ] );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_ShootMode_End ] );

	BIT_SUB( bitsWeaponState, WeaponState_OnShootMode );

	SetWeaponState( pItem, bitsWeaponState );
	set_entvar( pItem, var_next_charge, get_gametime( ) + WeaponSecondaryChargeTime );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponAnim_ShootMode_End_Time );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponAnim_ShootMode_End_Time );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_ShootMode_End_Time );

	return true;
}

public CWeapon_UpdateSecondaryAmmo( const pItem, const pPlayer, const iSecondaryAmmo )
{
	set_entvar( pItem, var_secondary_ammo, iSecondaryAmmo );

#if defined WeaponListDir && defined UseSecondaryAmmoHud
	SetWeaponAmmo( pPlayer, iSecondaryAmmo, WeaponSecondaryAmmoIndex );
#else
	client_print( pPlayer, print_center, "[ Ignite Force: %i ]", iSecondaryAmmo );
#endif
}

#if !defined _reapi_included
	ToggleTraceAttack( const bool: bEnabled )
	{
		for ( new i; i < sizeof gl_HamHook_TraceAttack; i++ )
			bEnabled ? EnableHamForward( gl_HamHook_TraceAttack[ i ] ) : DisableHamForward( gl_HamHook_TraceAttack[ i ] );
	}
#endif

/* ~ [ Stocks ] ~ */
#if defined _api_muzzleflash_included
	/* -> Simple initalize Muzzle-Flash <- */
	stock MuzzleFlash: UTIL_MuzzleFlashInit( const szSpritePath[ ], const iAttachment, const Float: flScale, const Float: flFramerateMlt = 1.0, const Float: flStartTime = 0.0 )
	{
		new MuzzleFlash: iMuzzleId = zc_muzzle_init( );
		{
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_SPRITE, szSpritePath );
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_ATTACHMENT, iAttachment );
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_SCALE, flScale );
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_FRAMERATE_MLT, flFramerateMlt );
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_START_TIME, flStartTime );
		}

		return iMuzzleId;
	}
#endif

#if !defined _zombieplague_included
	stock bool: IsSimilarPlayersTeam( const pPlayer, const pTarget )
	{
		if ( get_member( pPlayer, m_iTeam ) == get_member( pTarget, m_iTeam ) )
			return true;

		return false;
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
					engfunc( EngFunc_PrecacheGeneric, szSoundPath );
				#else
					engfunc( EngFunc_PrecacheGeneric, fmt( "sound/%s", szSoundPath ) );
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

		#if AMXX_VERSION_NUM < 190
			formatex( szBuffer, charsmax( szBuffer ), "sprites/%s.spr", szSprName );
			engfunc( EngFunc_PrecacheGeneric, szBuffer );
		#else
			engfunc( EngFunc_PrecacheGeneric, fmt( "sprites/%s.spr", szSprName ) );
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

/* -> TE_KILLBEAM <- */
stock UTIL_TE_KILLBEAM( const iDest, const pEntity )
{
	message_begin( iDest, SVC_TEMPENTITY );
	write_byte( TE_KILLBEAM ); 
	write_short( pEntity );
	message_end( );
}

/* -> TE_BEAMENTPOINT <- */
stock UTIL_TE_BEAMENTPOINT( const iDest, const pEntity, const iszModelIndex, const Vector3( vecOrigin ), const iStartFrame, const iFrameRate, const iLife, const iWidth, const iNoise, const iColor[ 3 ], const iBrightness, const iScroll )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_BEAMENTPOINT );
	write_short( pEntity );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_short( iszModelIndex ); // Model Index
	write_byte( iStartFrame ); // Start Frame
	write_byte( iFrameRate ); // FrameRate
	write_byte( iLife ); // Life in 0.1's
	write_byte( iWidth ); // Width
	write_byte( iNoise ); // Noise
	write_byte( iColor[ 0 ] ); // Red
	write_byte( iColor[ 1 ] ); // Green
	write_byte( iColor[ 2 ] ); // Blue
	write_byte( iBrightness ); // Brightness
	write_byte( iScroll ); // Scroll speed in 0.1's
	message_end( );
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

/* -> Weapon Kick Back <- */
stock UTIL_WeaponKickBack( const pItem, const pPlayer, Float: flUpBase, Float: flLateralBase, Float: flUpModifier, Float: flLateralModifier, Float: flUpMax, Float: flLateralMax, iDirectionChange ) 
{
	new Float: flKickUp, Float: flKickLateral;
	new iShotsFired = get_member( pItem, m_Weapon_iShotsFired );
	new iDirection = get_member( pItem, m_Weapon_iDirection );
	new Vector3( vecPunchAngle ); get_entvar( pPlayer, var_punchangle, vecPunchAngle );

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

	vecPunchAngle[ 0 ] -= flKickUp;

	if ( vecPunchAngle[ 0 ] < -flUpMax ) 
		vecPunchAngle[ 0 ] = -flUpMax;

	if ( iDirection ) 
	{
		vecPunchAngle[ 1 ] += flKickLateral;
		if ( vecPunchAngle[ 1 ] > flLateralMax ) 
			vecPunchAngle[ 1 ] = flLateralMax;
	}
	else
	{
		vecPunchAngle[ 1 ] -= flKickLateral;
		if ( vecPunchAngle[ 1 ] < -flLateralMax ) 
			vecPunchAngle[ 1 ] = -flLateralMax;
	}

	if ( iDirectionChange != 0 && !random_num( 0, iDirectionChange ) ) 
		set_member( pItem, m_Weapon_iDirection, !iDirection );

#if defined WeaponRecoil
	xs_vec_mul_scalar( vecPunchAngle, WeaponRecoil, vecPunchAngle );
#endif

	set_entvar( pPlayer, var_punchangle, vecPunchAngle );
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

/* -> Get player end eye position of aiming (w/o Trace) <- */
stock UTIL_GetEyePointAiming( const pPlayer, const Float: flDistance, Vector3( vecEndPos ), const iIgnoreId = DONT_IGNORE_MONSTERS )
{
	new Vector3( vecStart ); UTIL_GetEyePosition( pPlayer, vecStart );
	new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );
	new Vector3( vecEnd ); xs_vec_add_scaled( vecStart, vecAiming, flDistance, vecEnd );

	engfunc( EngFunc_TraceLine, vecStart, vecEnd, iIgnoreId, pPlayer, 0 );
	get_tr2( 0, TR_vecEndPos, vecEndPos );

	return get_tr2( 0, TR_pHit );
}

stock UTIL_ResetTimingSound( const pPlayer, const pEntity, const iChannel = CHAN_WEAPON, const szSound[ ] )
{
	rh_emit_sound2( pPlayer, 0, iChannel, szSound, .flags = SND_STOP );
	set_entvar( pEntity, var_next_sound, 0.0 );
}

stock bool: UTIL_PlayTimingSound( const pPlayer, const pEntity, const iChannel = CHAN_WEAPON, const szSound[ ], const Float: flSoundTime )
{
	new Float: flGameTime = get_gametime( );
	new Float: flNextSound; get_entvar( pEntity, var_next_sound, flNextSound );
	if ( flNextSound > flGameTime )
		return false;

	rh_emit_sound2( pPlayer, 0, iChannel, szSound );
	set_entvar( pEntity, var_next_sound, flGameTime + flSoundTime );

	return true;
}
