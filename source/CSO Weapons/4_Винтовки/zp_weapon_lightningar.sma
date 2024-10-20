/**
 * Weapon by xUnicorn (t3rkecorejz) 
 *
 * Thanks a lot:
 *
 * Chrescoe1 & batcoh (Phenix) — First base code
 * KORD_12.7 & 406 (Nightfury) — I'm taken some functions from this authors
 * D34, 404 & fl0wer — Some help
 */

new const PluginName[ ] =						"[ZP] Weapon: Electron-V";
new const PluginVersion[ ] =					"1.2";
new const PluginAuthor[ ] =						"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <zombieplague>

/**
 * If ur server can't use Re modules, just comment out or delete this line
 */
#include <reapi>

/**
 * If u don't want use custom Muzzle-Flash when shoot, just comment out or delete this line
 */
#tryinclude <api_muzzleflash>

/**
 * If u don't want use Smoke-WallPuff when hit, just comment out or delete this line
 */
#tryinclude <api_smokewallpuff>

/**
 * Allows submodel for p_ model
 */
#tryinclude <api_weapon_player_model>

#if !defined _reapi_included
	#include <non_reapi_support>
#endif

/**
 * Automatically precache sounds from the model
 * 
 * If you have ReHLDS installed, you do not need this setting with a server cvar
 * `sv_auto_precache_sounds_in_models 1`
 */
#define PrecacheSoundsFromModel

#if defined _zombieplague_included
	/* ~ [ Extra Item ] ~ */
	new const ExtraItem_Name[ ] =				"Electron-V";
	const ExtraItem_Cost =						0;
#endif

/* ~ [ Weapon Settings ] ~ */
const WeaponUnicalIndex =						16022023;
new const WeaponReference[ ] =					"weapon_aug";
// Comment 'WeaponListDir' if u dont need custom weapon list
new const WeaponListDir[ ] =					"x_re/weapon_lightningar";
new const WeaponAnimation[ ] =					"carbine";
new const WeaponNative[ ] =						"zp_give_user_lightningar";
new const WeaponModelView[ ] =					"models/x_re/v_lightningar.mdl";
new const WeaponModelPlayer[ ] =				"models/x_re/p_lightningar_fx.mdl";
#if defined _api_wpn_player_included
	/**
	 * How much to move attachments for Muzzle-Flash
	 * Works only when installed "API Weapon Player Model" version 1.1.0 and above
	 */
	new const Float: WeaponModelPlayerAttachments[ ] = {
		13.0, 0.0
	};
#endif
new const WeaponModelWorld[ ] =					"models/x_re/w_lightningar.mdl";
new const WeaponSounds[ ][ ] = {
	"weapons/lightningar-1.wav",
	"weapons/lightningar-2.wav",
	"weapons/lightningar-2_exp.wav",
	"weapons/lightningar-3.wav",
	"weapons/lightningar-3_exp.wav"
};

const ModelWorldBody =							0; // w_ submodel

const WeaponMaxClip =							50; // Max Clip
const WeaponDefaultAmmo =						200; // Default Ammo
const WeaponMaxAmmo =							200; // Max BP Ammo (reapi)

#if defined _api_muzzleflash_included
	/* ~ [ Muzzle-Flash ] ~ */
	new const MuzzleFlashSprite[ ] =			"sprites/x_re/muzzleflash215.spr";
	const Float: MuzzleFlashScale =				0.07; // Scale
	const Float: MuzzleFlashLifeTime =			0.35; // Life-Time
#endif

// Primary Attack
const Float: WeaponAccuracy =					0.2;
const Float: WeaponRate =						0.07; // Weapon shoot rate
const Float: WeaponNextShootTime =				0.3; // Next shoot after burst
const WeaponMaxShoots =							2; // Shoots in burst

#if defined _reapi_included
	// ReAPI
	const WeaponDamage =						40; // Base Damage
	const WeaponShotPenetration =				2; // Penetration
	const Bullet: WeaponBulletType =			BULLET_PLAYER_556MM; // Bullet Type
	const Float: WeaponShotDistance =			8192.0; // Max shoot distance
	const Float: WeaponRangeModifier =			0.96; // Range Modifier
#else
	// Non-ReAPI
	const Float: WeaponDamageMultiplier =		1.2; // Damage multiplier
#endif

// Secondary Attack
/**
 * Use ammo2 hud to display Secondary Ammo in Ammo HUD. Works only with custom WeaponList.
 * If you'r server have money hud, disable this setting.
 */
#define UseSecondaryAmmoHud

#if defined WeaponListDir && defined UseSecondaryAmmoHud
	const WeaponSecondaryAmmoIndex =			21; // 15-31 only. Change if conflict with another weapons
#endif

const WeaponSecondaryAmmoMax =					3; // Max Electron Storms
const Float: WeaponSecondaryHoldTime =			1.0; // Hold time for create flying Electron Storm

/* ~ [ Entity: Electron Storm ] ~ */
new const EntityElectronStormReference[ ] =		"info_target";
new const EntityElectronStormClassNames[ ][ ] = {
	"ent_electron_storm_mdl",
	"ent_electron_storm"
};
new const EntityElectronStormModel[ ] =			"models/x_re/ef_lightningar.mdl";
const Float: EntityElectronStormSize =			100.0; // Radius
const Float: EntityElectronStormSpeed =			500.0; // Flying speed
const Float: EntityElectronLifeTime =			3.75; // Life-Time
const Float: EntityElectronNextThink =			0.05;
const Float: EntityElectronStormDamageTime =	0.3; // Damage Time for victims
const Float: EntityElectronStormDamage =		150.0; // Damage in EntityElectronStormDamageTime
const EntityElectronDamageType =				( DMG_BULLET|DMG_NEVERGIB ); // Damage Type

/* ~ [ Weapon Animations ] ~ */
enum {
	WeaponAnim_Idle_Empty = 0,
	WeaponAnim_Idle,
	WeaponAnim_Charge1,
	WeaponAnim_Charge2,
	WeaponAnim_ChargeFinish,
	WeaponAnim_Reload_Empty,
	WeaponAnim_Reload,
	WeaponAnim_Draw_Empty,
	WeaponAnim_Draw,
	WeaponAnim_Shoot_Empty,
	WeaponAnim_Shoot,
	WeaponAnim_Shoot_Charge,
	WeaponAnim_Shoot_Charge_Last
};

const Float: WeaponAnim_Idle_Time = 			2.4;
const Float: WeaponAnim_Charge_Time =			0.4;
const Float: WeaponAnim_Reload_Time =			2.8; // Real time in model = 3.2
const Float: WeaponAnim_Draw_Time =				1.0;
const Float: WeaponAnim_Shoot_Time =			1.0;
const Float: WeaponAnim_Shoot_Charge_Time =		0.57;

/* ~ [ Params ] ~ */
#if AMXX_VERSION_NUM <= 182
	new MaxClients;
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
	new gl_iItemId;
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
	new MuzzleFlash: gl_pMuzzleFlash;
#endif

enum {
	Sound_Shoot,
	Sound_ShootB,
	Sound_ShootB_Exp,
	Sound_ShootC,
	Sound_ShootC_Exp
};

enum ( <<=1 ) {
	WeaponState_Charging = 1,
	WeaponState_Charged
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

#define IsUserValid(%0)							bool: ( 0 < %0 <= MaxClients )
#define IsNullVector(%0)						bool: ( ( %0[ 0 ] + %0[ 1 ] + %0[ 2 ] ) == 0.0 )
#define IsCustomWeapon(%0,%1)					bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponState(%0)						get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)					set_member( %0, m_Weapon_iWeaponState, %1 )
#define GetWeaponClip(%0)						get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)					set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)					get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)					get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)					set_member( %0, m_rgAmmo, %1, %2 )

#define WeaponHasElectronStorm(%0)				bool: ( get_entvar( %0, var_secondary_ammo ) > 0 )

#define var_secondary_ammo						var_gaitsequence
#define var_hold_time							var_starttime
#define m_Weapon_iShotsCount					m_Weapon_iGlock18ShotsFired

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( ) register_native( WeaponNative, "native_give_user_weapon" );
public plugin_precache( )
{
	new i;

	/* -> Precache Models <- */
	engfunc( EngFunc_PrecacheModel, WeaponModelView );
	engfunc( EngFunc_PrecacheModel, WeaponModelPlayer );
	engfunc( EngFunc_PrecacheModel, WeaponModelWorld );
	engfunc( EngFunc_PrecacheModel, EntityElectronStormModel );

	/* -> Precache Sounds <- */
	for ( i = 0; i < sizeof WeaponSounds; i++ )
		engfunc( EngFunc_PrecacheSound, WeaponSounds[ i ] );

#if defined PrecacheSoundsFromModel
	UTIL_PrecacheSoundsFromModel( WeaponModelView );
#endif

#if defined WeaponListDir
	/* -> Hook Weapon <- */
	register_clcmd( WeaponListDir, "ClientCommand__HookWeapon" );

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

#if defined _api_muzzleflash_included
	/* -> Muzzle-Flash <- */
	gl_pMuzzleFlash = zc_muzzle_init( );
	{
		zc_muzzle_set_property( gl_pMuzzleFlash, ZC_MUZZLE_SPRITE, MuzzleFlashSprite );
		zc_muzzle_set_property( gl_pMuzzleFlash, ZC_MUZZLE_SCALE, MuzzleFlashScale );
		zc_muzzle_set_property( gl_pMuzzleFlash, ZC_MUZZLE_FRAMERATE_MLT, MuzzleFlashLifeTime );
	}
#endif
}

public plugin_init( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

	/* -> Fakemeta <- */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

#if !defined _reapi_included
	register_forward( FM_SetModel, "FM_Hook_SetModel_Pre", false );

	/* -> Events <- */
	register_event( "HLTV", "EV_RoundStart", "a", "1=0", "2=0" );
#else
	/* -> ReGameDLL <- */
	RegisterHookChain( RG_CWeaponBox_SetModel, "RG_CWeaponBox__SetModel_Pre", false );
	RegisterHookChain( RG_CSGameRules_RestartRound, "RG_CSGameRules__RestartRound_Post", true );

	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post = 
		RegisterHookChain( RG_IsPenetrableEntity, "RG_IsPenetrableEntity_Post", true )
	);

	/* -> HamSandwich: Weapon <- */
	RegisterHam( Ham_Spawn, WeaponReference, "Ham_CWeapon_Spawn_Post", true );
#endif
	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_CWeapon_Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_CWeapon_Holster_Post", true );
	RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_CWeapon_PostFrame_Pre", false );
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Ham_CWeapon_AddToPlayer_Post", true );
#if !defined _reapi_included
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Pre", false );
#else
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Post", true );
#endif
	RegisterHam( Ham_Weapon_WeaponIdle, WeaponReference, "Ham_CWeapon_WeaponIdle_Pre", false );
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

	/* -> HamSandwich: Entity <- */
	RegisterHam( Ham_Think, EntityElectronStormReference, "Ham_CInfoTarget_Think_Post", true );
	RegisterHam( Ham_Touch, EntityElectronStormReference, "Ham_CInfoTarget_Touch_Post", true );
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

	/* -> Other <- */
#if AMXX_VERSION_NUM <= 182
	#if defined _reapi_included
		MaxClients = get_member_game( m_nMaxPlayers );
	#else
		MaxClients = get_maxplayers( );
	#endif
#endif
}

public bool: native_give_user_weapon( ) 
{
	enum { arg_player = 1 };

	return CPlayer_GiveWeapon( get_param( arg_player ) );
}

#if defined WeaponListDir
	public ClientCommand__HookWeapon( const pPlayer ) 
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

	#if defined WeaponListDir
		public FM_Hook_RegUserMsg_Post( const szName[ ] )
		{
			// Method by wellasgood
			if ( strcmp( szName, "WeaponList" ) == 0 )
				gl_iMsgHook_WeaponList = register_message( get_orig_retval( ), "MsgHook_WeaponList" );
		}
	#endif

	/* ~ [ Events ] ~ */
	public EV_RoundStart( )
	{
		UTIL_DestroyEntitiesByClass( EntityElectronStormClassNames[ 0 ] );
		UTIL_DestroyEntitiesByClass( EntityElectronStormClassNames[ 1 ] );
	}
#else
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

	public RG_CSGameRules__RestartRound_Post( )
	{
		UTIL_DestroyEntitiesByClass( EntityElectronStormClassNames[ 0 ] );
		UTIL_DestroyEntitiesByClass( EntityElectronStormClassNames[ 1 ] );
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

	/* ~ [ HamSandwich ] ~ */
	public Ham_CWeapon_Spawn_Post( const pItem ) 
	{
		if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

		SetWeaponClip( pItem, WeaponMaxClip );

		set_member( pItem, m_Weapon_iDefaultAmmo, WeaponDefaultAmmo );

	#if defined WeaponListDir
		rg_set_iteminfo( pItem, ItemInfo_pszName, WeaponListDir );
	#endif
		rg_set_iteminfo( pItem, ItemInfo_iMaxClip, WeaponMaxClip );
		rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WeaponMaxAmmo );
	}
#endif

public Ham_CWeapon_Deploy_Post( const pItem ) 
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );
	new bool: bWeaponHasElectronStorm = WeaponHasElectronStorm( pItem );

	set_entvar( pPlayer, var_viewmodel, WeaponModelView );
#if !defined _api_wpn_player_included
	set_entvar( pPlayer, var_weaponmodel, WeaponModelPlayer );
#else
	set_entvar( pPlayer, var_weaponmodel, "" );
	api_wpn_player_model_set( pPlayer, WeaponModelPlayer, any: bWeaponHasElectronStorm, .iSequence = any: bWeaponHasElectronStorm, .flAttachment = WeaponModelPlayerAttachments );
#endif

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Draw_Empty + any: bWeaponHasElectronStorm );

	SetWeaponState( pItem, 0 );
	set_entvar( pItem, var_hold_time, 0.0 );
	set_member( pItem, m_Weapon_iShotsFired, 0 );
	set_member( pItem, m_Weapon_iFamasShotsFired, 0 );
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

	new pPlayer = get_member( pItem, m_pPlayer );

#if defined _api_muzzleflash_included
	if ( is_user_connected( pPlayer ) && !is_user_bot( pPlayer ) )
		zc_muzzle_destroy( pPlayer, gl_pMuzzleFlash );
#endif

	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

public Ham_CWeapon_PostFrame_Pre( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );

#if !defined _reapi_included
	if ( get_member( pItem, m_Weapon_fInReload ) )
	{
		new iClip = GetWeaponClip( pItem );
		new iAmmoType = GetWeaponAmmoType( pItem );
		new iAmmo = GetWeaponAmmo( pPlayer, iAmmoType );
		new iReloadClip = min( WeaponMaxClip - iClip, iAmmo );

		SetWeaponClip( pItem, iClip + iReloadClip );
		SetWeaponAmmo( pPlayer, iAmmo - iReloadClip, iAmmoType );
		set_member( pItem, m_Weapon_fInReload, false );

		return HAM_IGNORED;
	}
#endif

	// Add your shit burst code here...
	static iFamasShotsFired;
	if ( ( iFamasShotsFired = get_member( pItem, m_Weapon_iFamasShotsFired ) ) )
	{
		static iClip; iClip = GetWeaponClip( pItem );
		if ( iClip )
		{
			if ( ++iFamasShotsFired >= WeaponMaxShoots )
				iFamasShotsFired = 0;

			CWeapon_Fire( pItem, pPlayer, iClip, Float: ( iFamasShotsFired ) ? WeaponRate : WeaponNextShootTime );
			set_member( pPlayer, m_flNextAttack, WeaponRate );
		}
		else iFamasShotsFired = 0;

		set_member( pItem, m_Weapon_iFamasShotsFired, iFamasShotsFired );
	}

	static bitsButton; bitsButton = get_entvar( pPlayer, var_button );
	static bitsWeaponState;
	if ( ( bitsWeaponState = GetWeaponState( pItem ) ) && ~bitsButton & IN_ATTACK2 )
	{
		static iSecondaryAmmo; iSecondaryAmmo = get_entvar( pItem, var_secondary_ammo );
		static bool: bChargedShoot; bChargedShoot = BIT_VALID( bitsWeaponState, WeaponState_Charged );

		CWeapon_UpdateSecondaryAmmo( pItem, pPlayer, --iSecondaryAmmo );

	#if defined _api_wpn_player_included
		if ( !iSecondaryAmmo )
			api_wpn_player_model_set( pPlayer, WeaponModelPlayer, .flAttachment = WeaponModelPlayerAttachments );
	#endif

	#if defined _reapi_included
		rg_set_animation( pPlayer, PLAYER_ATTACK1 );
	#else
		static szPlayerAnim[ 32 ]; formatex( szPlayerAnim, charsmax( szPlayerAnim ), "%s_shoot_%s", get_entvar( pPlayer, var_flags ) & FL_DUCKING ? "crouch" : "ref", WeaponAnimation );
		UTIL_PlayerAnimation( pPlayer, szPlayerAnim );
	#endif

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, ( iSecondaryAmmo ) ? WeaponAnim_Shoot_Charge : WeaponAnim_Shoot_Charge_Last );
		rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ bChargedShoot ? Sound_ShootC : Sound_ShootB ] );
	
		CElectronStorm__SpawnEntity( pPlayer, pItem, bChargedShoot );
	
		SetWeaponState( pItem, bitsWeaponState = 0 );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Shoot_Charge_Time );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponAnim_Shoot_Charge_Time );
		set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponAnim_Shoot_Charge_Time );
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
	#if defined WeaponListDir && defined UseSecondaryAmmoHud
		set_member( pItem, m_Weapon_iSecondaryAmmoType, WeaponSecondaryAmmoIndex );

		#if defined _reapi_included
			rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo2, WeaponSecondaryAmmoMax );
		#endif
	#endif

		set_entvar( pItem, var_secondary_ammo, 0 );
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

#if !defined _reapi_included
	public Ham_CWeapon_Reload_Pre( const pItem )
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return HAM_IGNORED;

		new pPlayer = get_member( pItem, m_pPlayer );

		if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
			return HAM_SUPERCEDE;

		new iClip = GetWeaponClip( pItem );
		if ( GetWeaponClip( pItem ) >= WeaponMaxClip )
			return HAM_SUPERCEDE;

		SetWeaponClip( pItem, 0 );
		ExecuteHam( Ham_Weapon_Reload, pItem );
		SetWeaponClip( pItem, iClip );

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Reload_Empty + any: WeaponHasElectronStorm( pItem ) );

		set_member( pItem, m_Weapon_fInReload, true );
		set_member( pItem, m_Weapon_iShotsFired, 0 );
		set_member( pItem, m_Weapon_iFamasShotsFired, 0 );
		set_member( pItem, m_Weapon_flAccuracy, WeaponAccuracy );
		set_member( pPlayer, m_flNextAttack, WeaponAnim_Reload_Time );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time );

		return HAM_SUPERCEDE;
	}
#else
	public Ham_CWeapon_Reload_Post( const pItem )
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

		new pPlayer = get_member( pItem, m_pPlayer );

		if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
			return;

		if ( GetWeaponClip( pItem ) >= rg_get_iteminfo( pItem, ItemInfo_iMaxClip ) )
			return;

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Reload_Empty + any: WeaponHasElectronStorm( pItem ) );

		set_member( pItem, m_Weapon_iShotsFired, 0 );
		set_member( pItem, m_Weapon_iFamasShotsFired, 0 );
		set_member( pItem, m_Weapon_flAccuracy, WeaponAccuracy );
		set_member( pPlayer, m_flNextAttack, WeaponAnim_Reload_Time );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time );
	}
#endif

public Ham_CWeapon_WeaponIdle_Pre( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( Float: get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Idle_Empty + any: WeaponHasElectronStorm( pItem ) );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Idle_Time );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PrimaryAttack_Pre( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( get_member( pItem, m_Weapon_iFamasShotsFired ) )
		return HAM_SUPERCEDE;

	static iClip; iClip = GetWeaponClip( pItem );
	if ( !iClip )
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, 0.2 );

		return HAM_SUPERCEDE;
	}

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	
	CWeapon_Fire( pItem, pPlayer, iClip, WeaponRate );

#if defined _api_muzzleflash_included
	zc_muzzle_draw( pPlayer, gl_pMuzzleFlash );
#endif

	set_member( pPlayer, m_flNextAttack, WeaponRate );
	set_member( pItem, m_Weapon_iFamasShotsFired, 1 );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_SecondaryAttack_Pre( const pItem )
{
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static iSecondaryAmmo; iSecondaryAmmo = get_entvar( pItem, var_secondary_ammo );
	if ( !iSecondaryAmmo )
		return HAM_SUPERCEDE;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	static iWeaponAnimIndex, Float: flIdleTime, Float: flNextAttack;
	static Float: flGameTime; flGameTime = get_gametime( );

	// Charged
	if ( BIT_VALID( bitsWeaponState, WeaponState_Charged ) )
	{
		iWeaponAnimIndex = WeaponAnim_Charge2;
		flIdleTime = flNextAttack = WeaponAnim_Charge_Time;
	}

	// Charging now
	else if ( BIT_VALID( bitsWeaponState, WeaponState_Charging ) )
	{
		// Finish
		static Float: flHoldTime; get_entvar( pItem, var_hold_time, flHoldTime );
		if ( flHoldTime < flGameTime )
		{
			iWeaponAnimIndex = WeaponAnim_ChargeFinish;

			BIT_SUB( bitsWeaponState, WeaponState_Charging );
			BIT_ADD( bitsWeaponState, WeaponState_Charged );
		}
		else iWeaponAnimIndex = WeaponAnim_Charge2;

		flIdleTime = flNextAttack = WeaponAnim_Charge_Time;
	}

	// Start Charging
	else
	{
		iWeaponAnimIndex = WeaponAnim_Charge1;
		flIdleTime = flNextAttack = WeaponAnim_Charge_Time;
		set_entvar( pItem, var_hold_time, flGameTime + WeaponSecondaryHoldTime );

		BIT_ADD( bitsWeaponState, WeaponState_Charging );
	}

	if ( iWeaponAnimIndex != -1 && get_entvar( pPlayer, var_weaponanim ) != iWeaponAnimIndex )
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iWeaponAnimIndex );

	SetWeaponState( pItem, bitsWeaponState );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flIdleTime );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, flNextAttack );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, flNextAttack );

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

	public Ham_CInfoTarget_Think_Post( const pEntity )
	{
		if ( is_nullent( pEntity ) )
			return;

		if ( FClassnameIs( pEntity, EntityElectronStormClassNames[ 0 ] ) )
			CElectronStorm__Think( pEntity );
	}

	public Ham_CInfoTarget_Touch_Post( const pEntity, const pTouch )
	{
		if ( is_nullent( pEntity ) )
			return;

		if ( FClassnameIs( pEntity, EntityElectronStormClassNames[ 0 ] ) )
			CElectronStorm__Touch( pEntity, pTouch );

		if ( FClassnameIs( pEntity, EntityElectronStormClassNames[ 1 ] ) )
			CElectronRadius__Touch( pEntity, pTouch );
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

	new iAmmoType = GetWeaponAmmoType( pItem );
	if ( GetWeaponAmmo( pPlayer, iAmmoType ) < WeaponDefaultAmmo )
		SetWeaponAmmo( pPlayer, WeaponDefaultAmmo, iAmmoType );

#if !defined _reapi_included
	SetWeaponClip( pItem, WeaponMaxClip );
#endif

	return true;
}

public CWeapon_Fire( const pItem, const pPlayer, iClip, const Float: flNextAttack )
{
	static bitsFlags; bitsFlags = get_entvar( pPlayer, var_flags );
	static Vector3( vecVelocity ); get_entvar( pPlayer, var_velocity, vecVelocity );
	static iShotsFired; iShotsFired = get_member( pItem, m_Weapon_iShotsFired );

	static iShotsCount; iShotsCount = get_member( pItem, m_Weapon_iShotsCount ) + 1;
	// Update m_Weapon_iShotsFired for KickBack and Spread (reapi)
	if ( !( iShotsCount % 7 ) )
		iShotsFired++;

	// Clear m_Weapon_iShotsCount for add Secondary Ammo
	if ( !( iShotsCount % 10 ) )
	{
		iShotsCount = 0;

		new iSecondaryAmmo = get_entvar( pItem, var_secondary_ammo );
		if ( iSecondaryAmmo < WeaponSecondaryAmmoMax )
			CWeapon_UpdateSecondaryAmmo( pItem, pPlayer, ++iSecondaryAmmo );

	#if defined _api_wpn_player_included
		new pWeaponModel = api_wpn_player_model_get( pPlayer );
		if ( !is_nullent( pWeaponModel ) && get_entvar( pWeaponModel, var_body ) != 1 )
			api_wpn_player_model_set( pPlayer, WeaponModelPlayer, 1, .iSequence = 1, .flAttachment = WeaponModelPlayerAttachments );
	#endif
	}

	set_member( pItem, m_Weapon_iShotsCount, iShotsCount );
	set_member( pItem, m_Weapon_iShotsFired, iShotsFired );

#if defined _reapi_included
	static Float: flAccuracy; flAccuracy = get_member( pItem, m_Weapon_flAccuracy );
	static Float: flSpread;

	if ( ~bitsFlags & FL_ONGROUND )
		flSpread = 0.04 + ( 0.3 * flAccuracy );
	else if ( xs_vec_len_2d( vecVelocity ) > 140.0 )
		flSpread = 0.04 + ( 0.07 * flAccuracy );
	else flSpread = 0.0375 * flAccuracy;

	if ( flAccuracy ) 
		flAccuracy = floatmin( ( ( iShotsFired * iShotsFired * iShotsFired ) / 200.0 ) + 0.35, 1.25 );

	EnableHookChain( gl_HookChain_IsPenetrableEntity_Post );
	{
		static Vector3( vecSrc ); UTIL_GetEyePosition( pPlayer, vecSrc );
		static Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );

		rg_fire_bullets3( pItem, pPlayer, vecSrc, vecAiming, flSpread, WeaponShotDistance, WeaponShotPenetration, WeaponBulletType, WeaponDamage, WeaponRangeModifier, false, get_member( pPlayer, random_seed ) );
	}
	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post );

	rg_set_animation( pPlayer, PLAYER_ATTACK1 );

	SetWeaponClip( pItem, --iClip );
	set_member( pItem, m_Weapon_flAccuracy, flAccuracy );
#else
	static _FM_Hook_PlayBackEvent_Pre; _FM_Hook_PlayBackEvent_Pre = register_forward( FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false );
	static _FM_Hook_TraceLine_Post; _FM_Hook_TraceLine_Post = register_forward( FM_TraceLine, "FM_Hook_TraceLine_Post", true );
	ToggleTraceAttack( true );

	ExecuteHam( Ham_Weapon_PrimaryAttack, pItem );

	unregister_forward( FM_PlaybackEvent, _FM_Hook_PlayBackEvent_Pre );
	unregister_forward( FM_TraceLine, _FM_Hook_TraceLine_Post, true );
	ToggleTraceAttack( false );

	set_member( pItem, m_Weapon_iShotsFired, iShotsFired );
#endif

	if ( xs_vec_len_2d( vecVelocity ) > 0.0 )
		UTIL_WeaponKickBack( pItem, pPlayer, 1.0, 0.45, 0.28, 0.045, 3.75, 3.0, 7 );
	else if ( ~bitsFlags & FL_ONGROUND )
		UTIL_WeaponKickBack( pItem, pPlayer, 1.2, 0.5, 0.23, 0.15, 5.5, 3.5, 6 );
	else if ( bitsFlags & FL_DUCKING )
		UTIL_WeaponKickBack( pItem, pPlayer, 0.6, 0.3, 0.2, 0.0125, 3.25, 2.0, 7 );
	else
		UTIL_WeaponKickBack( pItem, pPlayer, 0.65, 0.35, 0.25, 0.015, 3.5, 2.25, 7 );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Shoot_Empty + any: WeaponHasElectronStorm( pItem ) );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_Shoot ] );

	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Shoot_Time );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, flNextAttack );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, flNextAttack );
}

public CWeapon_UpdateSecondaryAmmo( const pItem, const pPlayer, const iSecondaryAmmo )
{
	set_entvar( pItem, var_secondary_ammo, iSecondaryAmmo );

#if defined WeaponListDir && defined UseSecondaryAmmoHud
	SetWeaponAmmo( pPlayer, iSecondaryAmmo, WeaponSecondaryAmmoIndex );
#else
	client_print( pPlayer, print_center, "[ Electron Storm: %i ]", iSecondaryAmmo );
#endif

	return true;
}

public CElectronStorm__SpawnEntity( const pPlayer, const pInflictor, const bool: bFlying )
{
	new pEntity = rg_create_entity( EntityElectronStormReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	new Vector3( vecOrigin ); UTIL_GetEyePosition( pPlayer, vecOrigin );
	new Vector3( vecDirection ); UTIL_GetVectorAiming( pPlayer, vecDirection );

	xs_vec_add_scaled( vecOrigin, vecDirection, 20.0, vecOrigin );

	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );
	engfunc( EngFunc_SetModel, pEntity, EntityElectronStormModel );
	engfunc( EngFunc_SetSize, pEntity, Float: { -1.0, -1.0, -1.0 }, Float: { 1.0, 1.0, 1.0 } );

	set_entvar( pEntity, var_classname, EntityElectronStormClassNames[ 0 ] );
	set_entvar( pEntity, var_solid, SOLID_TRIGGER );
	set_entvar( pEntity, var_movetype, bFlying ? MOVETYPE_FLY : MOVETYPE_NONE );
	set_entvar( pEntity, var_owner, pPlayer );

	if ( bFlying )
	{
		xs_vec_mul_scalar( vecDirection, EntityElectronStormSpeed, vecDirection );
		set_entvar( pEntity, var_velocity, vecDirection );
	}

	engfunc( EngFunc_VecToAngles, vecDirection, vecDirection );
	set_entvar( pEntity, var_angles, vecDirection );

	set_entvar( pEntity, var_rendermode, kRenderTransAdd );
	set_entvar( pEntity, var_renderamt, 255.0 );

	UTIL_SetEntityAnim( pEntity );

	new pRadiusEnt = CElectronRadius__SpawnEntity( pPlayer, pInflictor );
	if ( !is_nullent( pRadiusEnt ) )
	{
		set_entvar( pEntity, var_enemy, pRadiusEnt );
		set_entvar( pRadiusEnt, var_aiment, pEntity );
	}

	set_entvar( pEntity, var_nextthink, get_gametime( ) + EntityElectronLifeTime );

#if defined _reapi_included
	SetThink( pEntity, "CElectronStorm__Think" );
	SetTouch( pEntity, "CElectronStorm__Touch" );
#endif

	rh_emit_sound2( pEntity, 0, CHAN_ITEM, WeaponSounds[ bFlying ? Sound_ShootC_Exp : Sound_ShootB_Exp ] );

	return pEntity;
}

public CElectronStorm__Think( const pEntity )
{
	static pRadiusEnt; pRadiusEnt = get_entvar( pEntity, var_enemy );
	if ( !is_nullent( pRadiusEnt ) )
	{
		set_entvar( pEntity, var_owner, NULLENT );
		UTIL_KillEntity( pRadiusEnt );
	}
	else
	{
		// Fade Effect
		static Float: flRenderAmt; get_entvar( pEntity, var_renderamt, flRenderAmt );
		if ( ( flRenderAmt -= 25.0 ) && flRenderAmt <= 0.0 )
		{
			UTIL_KillEntity( pEntity );
			return;
		}

		set_entvar( pEntity, var_renderamt, flRenderAmt );
	}

	set_entvar( pEntity, var_nextthink, get_gametime( ) + EntityElectronNextThink );
}

public CElectronStorm__Touch( const pEntity, const pTouch )
{
#if !defined _reapi_included
	if ( get_entvar( pEntity, var_movetype ) == MOVETYPE_NONE )
		return;
#endif

	if ( FClassnameIs( pTouch, EntityElectronStormClassNames[ 0 ] ) || FClassnameIs( pTouch, EntityElectronStormClassNames[ 1 ] ) )
		return;

	if ( pTouch == get_entvar( pEntity, var_owner ) )
		return;

	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	if ( engfunc( EngFunc_PointContents, vecOrigin ) == CONTENTS_SKY )
	{
		static pRadiusEnt; pRadiusEnt = get_entvar( pEntity, var_enemy );
		if ( !is_nullent( pRadiusEnt ) )
			UTIL_KillEntity( pRadiusEnt );

		UTIL_KillEntity( pEntity );
		return;
	}

	set_entvar( pEntity, var_movetype, MOVETYPE_NONE );

#if defined _reapi_included
	SetTouch( pEntity, "" );
#endif
}

public CElectronRadius__SpawnEntity( const pPlayer, const pInflictor )
{
	new pEntity = rg_create_entity( EntityElectronStormReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	static Vector3( vecMins ), Vector3( vecMaxs );
	if ( IsNullVector( vecMins ) && IsNullVector( vecMaxs ) )
	{
		vecMins[ 0 ] = vecMins[ 1 ] = vecMins[ 2 ] = -EntityElectronStormSize;
		vecMaxs[ 0 ] = vecMaxs[ 1 ] = vecMaxs[ 2 ] = EntityElectronStormSize;
	}

	engfunc( EngFunc_SetSize, pEntity, vecMins, vecMaxs );

	set_entvar( pEntity, var_classname, EntityElectronStormClassNames[ 1 ] );
	set_entvar( pEntity, var_solid, SOLID_TRIGGER );
	set_entvar( pEntity, var_movetype, MOVETYPE_FOLLOW );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_dmg_inflictor, pInflictor );

#if defined _reapi_included
	SetTouch( pEntity, "CElectronRadius__Touch" );
#endif

	return pEntity;
}

public CElectronRadius__Touch( const pEntity, const pTouch )
{
	if ( pTouch == get_entvar( pEntity, var_aiment ) || !IsUserValid( pTouch ) )
		return;

	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( pTouch == pOwner )
		return;

#if defined _zombieplague_included
	if ( !zp_get_user_zombie( pTouch ) )
#else
	if ( IsSimilarPlayersTeam( pTouch, pOwner ) )
#endif
		return;

	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flDamageTime; get_entvar( pTouch, var_dmgtime, flDamageTime );
	if ( flDamageTime < flGameTime )
	{
		static pInflictor; pInflictor = get_entvar( pEntity, var_dmg_inflictor );
		if ( is_nullent( pInflictor ) || !IsCustomWeapon( pInflictor, WeaponUnicalIndex ) )
			pInflictor = pEntity;

		set_member( pTouch, m_LastHitGroup, HIT_GENERIC );
		ExecuteHamB( Ham_TakeDamage, pTouch, pInflictor, pOwner, EntityElectronStormDamage, EntityElectronDamageType );

		set_entvar( pTouch, var_dmgtime, flGameTime + EntityElectronStormDamageTime );
	}
}

#if !defined _reapi_included
	ToggleTraceAttack( const bool: bEnabled )
	{
		for ( new i; i < sizeof gl_HamHook_TraceAttack; i++ )
			bEnabled ? EnableHamForward( gl_HamHook_TraceAttack[ i ] ) : DisableHamForward( gl_HamHook_TraceAttack[ i ] );
	}
#endif

/* ~ [ Stocks ] ~ */
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

/* -> Destroy All Entities by ClassName <- */
stock UTIL_DestroyEntitiesByClass( const szClassName[ ] )
{
	static pEntity; pEntity = NULLENT;
	while ( ( pEntity = fm_find_ent_by_class( pEntity, szClassName ) ) > 0 )
		UTIL_KillEntity( pEntity );
}

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity )
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );
}

/* -> Entity Animation <- */
stock UTIL_SetEntityAnim( const pEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0 )
{
	set_entvar( pEntity, var_frame, flFrame );
	set_entvar( pEntity, var_framerate, flFrameRate );
	set_entvar( pEntity, var_animtime, get_gametime( ) );
	set_entvar( pEntity, var_sequence, iSequence );
}

#if !defined _reapi_included
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

	set_entvar( pPlayer, var_punchangle, vecPunchAngle );
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
