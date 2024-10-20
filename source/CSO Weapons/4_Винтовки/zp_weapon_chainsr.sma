/**
 * Weapon by xUnicorn (t3rkecorejz) 
 *
 * Thanks a lot:
 *
 * Chrescoe1 & batcoh (Phenix) — First base code
 * KORD_12.7 & 406 (Nightfury) — I'm taken some functions from this authors
 * D34, 404 & fl0wer — Some help
 * FosterZ - https://www.youtube.com/@fosterzrussian
 *
 * Download links:
 * 
 * api_muzzleflash.inc - https://github.com/YoshiokaHaruki/AMXX-API-Muzzle-Flash
 * api_smokewallpuff.inc - https://github.com/YoshiokaHaruki/AMXX-API-Smoke-WallPuff
 * beams.inc - https://forums.alliedmods.net/showthread.php?t=184780
 */

new const PluginName[ ] =					"[ZP] Weapon: Hecate II Umbra";
new const PluginVersion[ ] =				"1.1";
new const PluginAuthor[ ] =					"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <zombieplague>

#tryinclude <beams_reapi>
//#tryinclude <api_muzzleflash>
//#tryinclude <api_smokewallpuff>

#include <reapi>

native zp_is_round_end();
#define is_user_block_dmg(%0) ((zp_is_round_end() ||  get_entvar(%0, var_takedamage) == DAMAGE_NO))

#if !defined _reapi_included
	#include <non_reapi_support>
#endif

#if !defined DMG_GRENADE
	#define DMG_GRENADE						(1<<24)
#endif

/**
 * Automatically precache sounds from the model
 * 
 * If you have ReHLDS installed, you do not need this setting with a server cvar
 * `sv_auto_precache_sounds_in_models 1`
 */
// #define PrecacheSoundsFromModel

#if defined _zombieplague_included
	/* ~ [ Extra Item ] ~ */
	new const ExtraItem_Name[ ] =			"Hecate II Umbra";
	const ExtraItem_Cost =					0;
#endif

/* ~ [ Weapon Settings ] ~ */
const WeaponUnicalIndex =					19012023;
new const WeaponReference[ ] =				"weapon_aug";
new const WeaponListDir[ ] =				"x_re/weapon_chainsrfx";
new const WeaponNative[ ] =					"zp_give_user_chainsr";
new const WeaponModelView[ ] =				"models/x_re/v_chainsrfx.mdl";
new const WeaponModelPlayer[ ] =			"models/x_re/p_chainsr.mdl";
new const WeaponModelWorld[ ] =				"models/x_re/w_chainsr.mdl";
new const WeaponSounds[ ][ ] = {
	"weapons/chainsr-1.wav",
	"weapons/chainsr_exp.wav",
	"weapons/chainsr_smoke.wav"
};
new const WeaponEffects[ ][ ] = {
	"sprites/x_re/ef_chainsr_skill.spr",
	"sprites/x_re/ef_chainsr_skill2.spr"
};

const ModelWorldBody =						0; // w_ model body
const ModelViewZoomBody =					11; // v_ model body for zoom
const WeaponZoomFOV =						45; // Value from 41+

const WeaponMaxClip =						7; // Max clip
const WeaponDefaultAmmo =					140; // Default ammo
const WeaponMaxAmmo =						140; // Max ammo

#if defined _reapi_included
	const WeaponDamage =					295; // Base Damage
	const WeaponShotPenetration =			3; // Penetration
	const Float: WeaponShotDistance =		8192.0 // Max. shoot distance
	const Bullet: WeaponBulletType =		BULLET_PLAYER_338MAG; // Bullet Type
	const Float: WeaponRangeModifier =		1.0; // Range modifier (damage * 0.97 every 500 units)
#else
	const Float: WeaponDamage =				22.0; // Damage Multiplier (from WeaponReference)
#endif

const Float: WeaponRate =					1.565; // Shooting Rate
const Float: WeaponMaxSpeed =				220.0; // Max Speed with active weapon

// Slowdown debuff
const Float: WeaponDebuffTime =				2.0; // How long does debuff last
const Float: WeaponDebuffMultiplier =		0.9; // How much is the speed slowing down

// Reload
const Float: WeaponReloadExplodeTime =		0.7; // After how long will Reload Explode work
const Float: WeaponReloadExplodeDamage =	700.0; // Damage
const Float: WeaponReloadExplodeRadius =	171.0; // Radius
const Float: WeaponReloadExplodeKnockBack =	1000.0; // KnockBack
const WeaponReloadExplodeDamageType =		DMG_GRENADE; // Damage type (dont change)

// Shadow
const Float: WeaponShadowFindRadius =		400.0; // The radius in which the next victim will be found

/**
 * Works only if u have Zombie Plague 4.3 and better
 * Ignores cvar 'zp_zombie_armor', since each subsequent damage is multiplied by 0.75 (by default)
 */
//#define IgnoreZombieArmor

#if defined _beams_included
	/* ~ [ Beam ] ~ */
	new const BeamSprite[ ] =				"sprites/white.spr";
	const Float: BeamWidth =				16.0;
	const Float: BeamBrightness =			255.0; 
	new const Float: BeamColor[ ] =			{ 255.0, 255.0, 0.0 };
#endif

/* ~ [ Entity: Reload Explode ] ~ */
new const EntityExplodeReference[ ] =		"info_target";
new const EntityExplodeClassName[ ] =		"ent_chainsr_exp";
new const EntityExplodeModel[ ] =			"models/x_re/scorpion_hole.mdl";
const Float: EntityExplodeBrightness =		255.0;

/* ~ [ Entity: SlowDown Debuff ] ~ */
//new const EntitySlowDownReference[ ] =		"env_sprite";
//new const EntitySlowDownClassName[ ] =		"ent_chainsr_debuff";
//new const EntitySlowDownSprite[ ] =			"sprites/x_re/ef_sbmine_debuff.spr";
//const Float: EntitySlowDownScale =			0.5;
//const Float: EntitySlowDownNextThink =		0.05;

/* ~ [ Entity: Shadow ] ~ */
new const EntityShadowReference[ ] =		"info_target";
new const EntityShadowClassName[ ] =		"ent_chainsr_shadow";
new const EntityShadowModel[ ] =			"models/x_re/ef_chainsr_sniper.mdl";

/* ~ [ Entity: Shadow Muzzle ] ~ */
new const EntityShadowMuzzleReference[ ] =	"env_sprite";
new const EntityShadowMuzzleClassName[ ] =	"ent_chainsr_muzzle";
new const EntityShadowMuzzleSprite[ ] =		"sprites/x_re/muzzleflash270.spr";
const Float: EntityShadowMuzzleScale =		0.12;
const Float: EntityShadowMuzzleLifeTime =	0.7;
const Float: EntityShadowMuzzleNextThink =	0.05;

/* ~ [ Weapon Animations ] ~ */
enum {
	WeaponAnim_Idle,
	WeaponAnim_Shoot1,
	WeaponAnim_Shoot2,
	WeaponAnim_Reload,
	WeaponAnim_Draw,
	WeaponAnim_Dummy,
	WeaponAnim_Zoom
};

const Float: WeaponAnim_Idle_Time =			3.7;
const Float: WeaponAnim_Shoot_Time =		2.0;
const Float: WeaponAnim_Reload_Time =		3.7;
const Float: WeaponAnim_Draw_Time =			1.03;
// const Float: WeaponAnim_Draw_Time =			1.25;

/* ~ [ Params ] ~ */
#if defined _zombieplague_included
	#if defined ExtraItem_Name
		new gl_iItemId;
	#endif
	#if defined IgnoreZombieArmor
		new Float: gl_flZombieArmor;
	#endif
#endif
new gl_iMaxPlayers;
#if defined _beams_included
	new gl_bitsUserLeftHanded;
#endif
#if defined _reapi_included
	new HookChain: gl_HookChain_IsPenetrableEntity_Post;
#else
	new HamHook: gl_HamHook_TraceAttack[ 4 ];
#endif
#if defined _api_muzzleflash_included
	new MuzzleFlash: gl_iMuzzleFlash;
#endif

enum {
	Sound_Shoot,
	Sound_ReloadExplode,
	Sound_Smoke
};

enum {
	ShadowState_StartHide = 1
};

enum any: eModelIndex {
	ModelIndex_ShadowShoot1,
	ModelIndex_ShadowShoot2
};
new gl_iszModelIndex[ eModelIndex ];

/* ~ [ Macroses ] ~ */
#if AMXX_VERSION_NUM <= 183
	#define DONT_BLEED						-1
#endif

#if AMXX_VERSION_NUM <= 182
	#define OBS_IN_EYE						4

	#define write_coord_f(%0)				engfunc( EngFunc_WriteCoord, %0 )
	stock message_begin_f( const iDest, const iMsgType, const Float: vecOrigin[ 3 ] = { 0.0, 0.0, 0.0 }, const pReceiver = 0 )
		engfunc( EngFunc_MessageBegin, iDest, iMsgType, vecOrigin, pReceiver );
#endif

#if !defined Vector3
	#define Vector3(%0)						Float: %0[ 3 ]
#endif

#if defined _beams_included
	#define BIT_PLAYER(%0)					( BIT( %0 - 1 ) )
	#define BIT_ADD(%0,%1)					( %0 |= %1 )
	#define BIT_SUB(%0,%1)					( %0 &= ~%1 )
	#define BIT_VALID(%0,%1)				( %0 & %1 )
#endif

#define IsNullVector(%0)					bool: ( ( %0[ 0 ] + %0[ 1 ] + %0[ 2 ] ) == 0.0 )
#define IsCustomWeapon(%0,%1)				bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponClip(%0)					get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)				set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)				get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)				get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)				set_member( %0, m_rgAmmo, %1, %2 )

#define var_last_hitgroup					var_iuser3
#define var_shadow_state					var_iuser4
#define var_body_cached						var_iuser2

#define var_max_frame						var_yaw_speed
#define var_last_time						var_pitch_speed

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( ) register_native( WeaponNative, "native_give_user_weapon" );
public plugin_precache( )
{
	new i;

	/* -> Precache Models <- */
	engfunc( EngFunc_PrecacheModel, WeaponModelView );
	engfunc( EngFunc_PrecacheModel, WeaponModelPlayer );
	engfunc( EngFunc_PrecacheModel, WeaponModelWorld );
	engfunc( EngFunc_PrecacheModel, EntityExplodeModel );
	//engfunc( EngFunc_PrecacheModel, EntitySlowDownSprite );
	engfunc( EngFunc_PrecacheModel, EntityShadowModel );
	engfunc( EngFunc_PrecacheModel, EntityShadowMuzzleSprite );

#if defined _beams_included
	engfunc( EngFunc_PrecacheModel, BeamSprite );
#endif

	/* -> Precache Sounds <- */
	for ( i = 0; i < sizeof WeaponSounds; i++ )
		engfunc( EngFunc_PrecacheSound, WeaponSounds[ i ] );

#if defined WeaponListDir
	/* -> Hook Weapon <- */
	register_clcmd( WeaponListDir, "ClientCommand__HookWeapon" );

	/* -> Precache WeaponList <- */
	UTIL_PrecacheWeaponList( WeaponListDir );
#endif

#if defined _api_muzzleflash_included
	gl_iMuzzleFlash = zc_muzzle_init( );
	{
		zc_muzzle_set_property( gl_iMuzzleFlash, ZC_MUZZLE_SPRITE, EntityShadowMuzzleSprite );
		zc_muzzle_set_property( gl_iMuzzleFlash, ZC_MUZZLE_SCALE, EntityShadowMuzzleScale );
		zc_muzzle_set_property( gl_iMuzzleFlash, ZC_MUZZLE_FRAMERATE_MLT, EntityShadowMuzzleLifeTime );
	}
#endif

	/* -> Model Index <- */
	for ( i = 0; i < eModelIndex; i++ )
		gl_iszModelIndex[ i ] = engfunc( EngFunc_PrecacheModel, WeaponEffects[ i ] );
}

public plugin_init( )
{
	// https://cso.fandom.com/wiki/Hecate_II_Umbra
	register_plugin( PluginName, PluginVersion, PluginAuthor );

	/* -> Fakemeta <- */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

#if !defined _reapi_included
	register_forward( FM_SetModel, "FM_Hook_SetModel_Pre", false );

	/* -> Events <- */
	register_event( "HLTV", "EV_RoundStart", "a", "1=0", "2=0" );
#else
	/* -> ReGameDLL <- */
	RegisterHookChain( RG_CSGameRules_CleanUpMap, "RG_CSGameRules__CleanUpMap_Post", true );
	RegisterHookChain( RG_CWeaponBox_SetModel, "RG_CWeaponBox__SetModel_Pre", false );

	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post =
		RegisterHookChain( RG_IsPenetrableEntity, "RG_IsPenetrableEntity_Post", true )
	);

	/* -> HamSandwich: Weapon <- */
	RegisterHam( Ham_Spawn, WeaponReference, "Ham_CWeapon_Spawn_Post", true );
#endif
	RegisterHam( Ham_CS_Item_GetMaxSpeed, WeaponReference, "Ham_CWeapon_GetMaxSpeed_Pre", false );
	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_CWeapon_Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_CWeapon_Holster_Post", true );
#if defined WeaponListDir
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Ham_CWeapon_AddToPlayer_Post", true );
#endif
	RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_CWeapon_PostFrame_Pre", false );
#if !defined _reapi_included
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Pre", false );
#else
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Post", true );
#endif
	RegisterHam( Ham_Weapon_WeaponIdle, WeaponReference, "Ham_CWeapon_WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CWeapon_PrimaryAttack_Pre", false );
#if defined _beams_included
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CWeapon_PrimaryAttack_Post", true );
#endif
	RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_CWeapon_SecondaryAttack_Pre", false );

	/* -> HamSandwich: Player <- */
	RegisterHam( Ham_TakeDamage, "player", "Ham_CPlayer_TakeDamage_Post", true );

#if !defined _reapi_included
	/* -> HamSandwich: Trace Attack <- */
	new const TraceAttack_CallBack[ ] = "Ham_CEntity_TraceAttack_Pre";

	gl_HamHook_TraceAttack[ 0 ] = RegisterHam( Ham_TraceAttack,	"func_breakable", TraceAttack_CallBack, false );
	gl_HamHook_TraceAttack[ 1 ] = RegisterHam( Ham_TraceAttack,	"info_target", TraceAttack_CallBack, false );
	gl_HamHook_TraceAttack[ 2 ] = RegisterHam( Ham_TraceAttack,	"player", TraceAttack_CallBack, false );
	gl_HamHook_TraceAttack[ 3 ] = RegisterHam( Ham_TraceAttack,	"hostage_entity", TraceAttack_CallBack, false );
	
	ToggleTraceAttack( false );

	/* -> HamSandwich: Entity <- */
	RegisterHam( Ham_Think, "env_sprite", "CEnvSprite__Think_Post", true );
	RegisterHam( Ham_Think, "info_target", "CInfoTarget__Think_Post", true );
	#if defined _beams_included
		RegisterHam( Ham_Think, "beam", "CBeam__Think", true );
	#endif
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
	/* -> Register on Extra-Items <- */
	gl_iItemId = zp_register_extra_item( ExtraItem_Name, ExtraItem_Cost, ZP_TEAM_HUMAN );
#endif

	/* -> Other <- */
#if defined _reapi_included
	gl_iMaxPlayers = get_member_game( m_nMaxPlayers );
#else
	gl_iMaxPlayers = get_maxplayers( );
#endif
}

#if defined _zombieplague_included && defined IgnoreZombieArmor
	public plugin_cfg( )
		gl_flZombieArmor = get_cvar_float( "zp_zombie_armor" );
#endif

#if defined _beams_included
	public client_putinserver( pPlayer )
	{
		if ( !is_user_bot( pPlayer ) )
			query_client_cvar( pPlayer, "cl_righthand", "CPlayer__CheckLeftHand" );
	}

	public client_disconnected( pPlayer ) BIT_SUB( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) );
#endif

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
#if defined _zombieplague_included
	#if defined ExtraItem_Name
		public zp_extra_item_selected( pPlayer, iItemId )
		{
			if ( iItemId == gl_iItemId )
				return CPlayer__GiveWeapon( pPlayer ) ? PLUGIN_CONTINUE : ZP_PLUGIN_HANDLED;

			return PLUGIN_HANDLED;
		}
	#endif
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
		//if ( get_member( pActiveItem, m_Weapon_fInReload ) )
		//{
			static Float: flGameTime; flGameTime = get_gametime( );
			if ( 0.0 < Float: get_member( pActiveItem, m_Weapon_flNextReload ) < flGameTime )
			{
				CWeapon_ReloadExplode( pActiveItem, pPlayer );
				set_member( pActiveItem, m_Weapon_flNextReload, 0.0 );
			}
		//}

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

		static pItem; pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
		if ( pItem == NULLENT || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return FMRES_IGNORED;

		engfunc( EngFunc_SetModel, pWeaponBox, WeaponModelWorld );
		set_entvar( pWeaponBox, var_body, ModelWorldBody );

		return FMRES_SUPERCEDE;
	}

	public FM_Hook_PlaybackEvent_Pre( ) return FMRES_SUPERCEDE;
	public FM_Hook_TraceLine_Post( const Vector3( vecSrc ), Vector3( vecEnd ), const bitsFlags, const pAttacker, const pTrace )
	{
		if ( bitsFlags & IGNORE_MONSTERS )
			return;

		static Float: flFraction; get_tr2( pTrace, TR_flFraction, flFraction );
		if ( flFraction == 1.0 )
			return;

		get_tr2( pTrace, TR_vecEndPos, vecEnd );

	#if defined _beams_included
		static pActiveItem;
		if ( ( pActiveItem = get_member( pAttacker, m_pActiveItem ) ) && !is_nullent( pActiveItem ) && IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
			set_entvar( pActiveItem, var_endpos, vecEnd );
	#endif
		
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

	/* ~ [ Events ] ~ */
	public EV_RoundStart( )
	{
		UTIL_DestroyEntitiesByClass( EntityExplodeClassName );
		UTIL_DestroyEntitiesByClass( EntityShadowClassName );
		UTIL_DestroyEntitiesByClass( EntityShadowMuzzleClassName );
	}
#else
	/* ~ [ ReGameDLL ] ~ */
	public RG_CSGameRules__CleanUpMap_Post( )
	{
		UTIL_DestroyEntitiesByClass( EntityExplodeClassName );
		UTIL_DestroyEntitiesByClass( EntityShadowClassName );
		UTIL_DestroyEntitiesByClass( EntityShadowMuzzleClassName );
	}

	public RG_CWeaponBox__SetModel_Pre( const pWeaponBox, const szModel[ ] ) 
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
	#if defined _beams_included
		static pActiveItem;
		if ( ( pActiveItem = get_member( pAttacker, m_pActiveItem ) ) && !is_nullent( pActiveItem ) && IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
			set_entvar( pActiveItem, var_endpos, vecEnd );
	#endif

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
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
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

public Ham_CWeapon_GetMaxSpeed_Pre( const pItem )
{
	if ( IsCustomWeapon( pItem, WeaponUnicalIndex ) )
	{
		SetHamReturnFloat( WeaponMaxSpeed );
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public Ham_CWeapon_Deploy_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	set_entvar( pPlayer, var_viewmodel, WeaponModelView );
	set_entvar( pPlayer, var_weaponmodel, WeaponModelPlayer );
	set_entvar( pItem, var_body, 0 );
	set_entvar( pItem, var_body_cached, get_entvar( pItem, var_body ) );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Dummy );

	set_member( pItem, m_flLastEventCheck, get_gametime( ) + 0.1 );
	set_member( pItem, m_Weapon_flNextReload, 0.0 );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Draw_Time + 0.1 );
	set_member( pPlayer, m_flNextAttack, WeaponAnim_Draw_Time );
}

public Ham_CWeapon_Holster_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

#if defined _beams_included || defined _api_muzzleflash_included
	if ( is_user_connected( pPlayer ) && !is_user_bot( pPlayer ) )
	{
	#if defined _beams_included
		query_client_cvar( pPlayer, "cl_righthand", "CPlayer__CheckLeftHand" );
	#endif

	#if defined _api_muzzleflash_included
		zc_muzzle_destroy( pPlayer, gl_iMuzzleFlash );
	#endif
	}
#endif

	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

#if defined WeaponListDir
	public Ham_CWeapon_AddToPlayer_Post( const pItem, const pPlayer ) 
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

	#if defined _reapi_included
		UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
	#else
		UTIL_WeaponList( MSG_ONE, pPlayer, pItem, WeaponListDir );
	#endif
	}
#endif

public Ham_CWeapon_PostFrame_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
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
	}
#endif

	if ( get_member( pPlayer, m_bResumeZoom ) )
	{
		set_entvar( pItem, var_body, ModelViewZoomBody );
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Zoom );
	}

	return HAM_IGNORED;
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
		if ( iClip >= WeaponMaxClip )
			return HAM_SUPERCEDE;

		SetWeaponClip( pItem, 0 );
		ExecuteHam( Ham_Weapon_Reload, pItem );
		SetWeaponClip( pItem, iClip );

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Reload );

		set_member( pItem, m_Weapon_fInReload, true );
		set_member( pItem, m_Weapon_flNextReload, get_gametime( ) + WeaponReloadExplodeTime );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time );
		set_member( pPlayer, m_flNextAttack, WeaponAnim_Reload_Time );

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

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Reload );

		set_member( pItem, m_Weapon_flNextReload, get_gametime( ) + WeaponReloadExplodeTime );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponAnim_Reload_Time );
		set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponAnim_Reload_Time );
		set_member( pPlayer, m_flNextAttack, WeaponReloadExplodeTime );
	}
#endif

public Ham_CWeapon_WeaponIdle_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( Float: get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, get_member( pPlayer, m_iFOV ) == DEFAULT_NO_ZOOM ? WeaponAnim_Idle : WeaponAnim_Zoom );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Idle_Time );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PrimaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	new iClip = GetWeaponClip( pItem );
	if ( !iClip )
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, 0.2 );

		return HAM_SUPERCEDE;
	}

	new pPlayer = get_member( pItem, m_pPlayer );

	static iFOV;
	if ( ( iFOV = get_member( pPlayer, m_iFOV ) ) && iFOV != DEFAULT_NO_ZOOM )
	{
		set_entvar( pItem, var_body, get_entvar( pItem, var_body_cached ) );

		set_member( pPlayer, m_bResumeZoom, true );
		set_member( pPlayer, m_iLastZoom, iFOV );

		set_member( pPlayer, m_iFOV, DEFAULT_NO_ZOOM );
	}

#if defined _reapi_included
	EnableHookChain( gl_HookChain_IsPenetrableEntity_Post );
	{
		new Vector3( vecSrc ); UTIL_GetEyePosition( pPlayer, vecSrc );
		new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );

		rg_fire_bullets3( pItem, pPlayer, vecSrc, vecAiming, 0.0, WeaponShotDistance, WeaponShotPenetration, WeaponBulletType, WeaponDamage, WeaponRangeModifier, false, get_member( pPlayer, random_seed ) );
	}
	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post );
	rg_set_animation( pPlayer, PLAYER_ATTACK1 );

	SetWeaponClip( pItem, --iClip );
#else
	static _FM_Hook_PlayBackEvent_Pre; _FM_Hook_PlayBackEvent_Pre = register_forward( FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false );
	static _FM_Hook_TraceLine_Post; _FM_Hook_TraceLine_Post = register_forward( FM_TraceLine, "FM_Hook_TraceLine_Post", true );
	ToggleTraceAttack( true );

	ExecuteHam( Ham_Weapon_PrimaryAttack, pItem );

	unregister_forward( FM_PlaybackEvent, _FM_Hook_PlayBackEvent_Pre );
	unregister_forward( FM_TraceLine, _FM_Hook_TraceLine_Post, true );
	ToggleTraceAttack( false );
#endif

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, random_num( WeaponAnim_Shoot1, WeaponAnim_Shoot2 ) );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_Shoot ] );

#if defined _api_muzzleflash_included
	zc_muzzle_draw( pPlayer, gl_iMuzzleFlash );
#endif

	set_entvar( pPlayer, var_punchangle, Float: { -5.0, 0.0, 0.0 } );

	set_member( pPlayer, m_flNextAttack, WeaponRate );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponRate)
	// set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponRate)
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Shoot_Time );

	return HAM_SUPERCEDE;
}

#if defined _beams_included
	public Ham_CWeapon_PrimaryAttack_Post( const pItem )
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

		static Vector3( vecEndPos ); get_entvar( pItem, var_endpos, vecEndPos );
		if ( IsNullVector( vecEndPos ) )
			return;

		static pPlayer; pPlayer = get_member( pItem, m_pPlayer );

		static Vector3( vecStartPos );
		UTIL_GetWeaponPosition( pPlayer, 20.0, BIT_VALID( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) ) ? -5.0 : 5.0, -5.0, vecStartPos );

		new pBeam = Beam_Create( BeamSprite, BeamWidth );
		if ( !is_nullent( pBeam ) )
		{
			Beam_PointsInit( pBeam, vecStartPos, vecEndPos );
			Beam_SetBrightness( pBeam, BeamBrightness );
			Beam_SetColor( pBeam, BeamColor );
			Beam_SetFlags( pBeam, BEAM_FSHADEIN );

		#if defined _reapi_included
			SetThink( pBeam, "CBeam__Think" );
		#else
			set_entvar( pBeam, var_impulse, WeaponUnicalIndex );
		#endif
			set_entvar( pBeam, var_nextthink, get_gametime( ) );
		}

		set_entvar( pItem, var_endpos, Float: { 0.0, 0.0, 0.0 } );
	}
#endif

public Ham_CWeapon_SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );
	new bool: bUseZoom = bool: ( get_member( pPlayer, m_iFOV ) == DEFAULT_NO_ZOOM );

	set_entvar( pItem, var_body, bUseZoom ? ModelViewZoomBody : get_entvar( pItem, var_body_cached ) );
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, bUseZoom ? WeaponAnim_Zoom : WeaponAnim_Idle );

	set_member( pPlayer, m_iFOV, bUseZoom ? WeaponZoomFOV : DEFAULT_NO_ZOOM );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, 0.2 );

	return HAM_SUPERCEDE;
}

public Ham_CPlayer_TakeDamage_Post( const pVictim, pInflictor, const pAttacker, const Float: flDamage, const bitsDamageType )
{
	if ( !is_user_alive( pAttacker ) || pVictim == pAttacker )
		return;

#if defined _reapi_included
	if ( pInflictor == pAttacker )
		return;
#else
	if ( pInflictor == pAttacker )
		pInflictor = get_member( pAttacker, m_rgpPlayerItems, PRIMARY_WEAPON_SLOT );
#endif

	if ( is_nullent( pInflictor ) || !IsCustomWeapon( pInflictor, WeaponUnicalIndex ) )
		return;

	if ( !is_user_alive( pVictim ) )
	{
		new Vector3( vecOrigin ); get_entvar( pVictim, var_origin, vecOrigin );
		CShadow__SpawnEntity( pAttacker, pInflictor, vecOrigin, flDamage, get_member( pVictim, m_LastHitGroup ) );
	}
	/*else
	{
	#if !defined _reapi_included
		if ( get_member( pAttacker, m_pActiveItem ) != pInflictor )
			return;
	#endif

		if ( ~bitsDamageType & DMG_GRENADE )
			CSlowDown__SpawnEntity( pVictim );
	}*/
}

#if !defined _reapi_included
	public Ham_CEntity_TraceAttack_Pre( const pVictim, const pAttacker, const Float: flDamage )
	{
		if ( !is_user_connected( pAttacker ) )
			return HAM_IGNORED;

		static pActiveItem; pActiveItem = get_member( pAttacker, m_pActiveItem );
		if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
			return HAM_IGNORED;

		SetHamParamFloat( 3, flDamage * WeaponDamage );
		return HAM_IGNORED;
	}

	public CEnvSprite__Think_Post( const pEntity )
	{
		if ( is_nullent( pEntity ) )
			return;

		if ( FClassnameIs( pEntity, EntitySlowDownClassName ) )
			CSlowDown__Think( pEntity );

		if ( FClassnameIs( pEntity, EntityShadowMuzzleClassName ) )
			CShadowMuzzle__Think( pEntity );
	}

	public CInfoTarget__Think_Post( const pEntity )
	{
		if ( is_nullent( pEntity ) )
			return;

		if ( FClassnameIs( pEntity, EntityExplodeClassName ) )
			CReloadExplode__Think( pEntity );

		if ( FClassnameIs( pEntity, EntityShadowClassName ) )
			CShadow__Think( pEntity );
	}
#endif

/* ~ [ Other ] ~ */
public bool: CPlayer__GiveWeapon( const pPlayer )
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

CWeapon_DoRadiusDamage( const pPlayer, const pItem, const Vector3( vecOrigin ), const Float: flCachedDamage, const Float: flRadius, const bitsDamageType, const Float: flKnockBack = 0.0, const bool: bShowBlood = false )
{
	new Vector3( vecVictimOrigin ), Float: flDistance, Float: flDamage;

	for ( new pVictim = 1; pVictim <= gl_iMaxPlayers; pVictim++ )
	{
		if ( !is_user_alive( pVictim ) )
			continue;

		if ( !zp_get_user_zombie( pVictim ) )
			continue;

		if ( !UTIL_IsWallBetweenPoints( pPlayer, pVictim ) )
			continue;

		if(is_user_block_dmg(pVictim))
			continue;

		get_entvar( pVictim, var_origin, vecVictimOrigin );
		flDistance = xs_vec_distance_2d( vecOrigin, vecVictimOrigin );
		if ( flDistance > flRadius )
			continue;

		flDamage = flCachedDamage;
		flDamage *= ( 1.0 - floatclamp( flDistance / flRadius, 0.1, 0.99 ) );

		set_member( pVictim, m_LastHitGroup, HIT_GENERIC );
		CPlayer__TakeDamage( pVictim, pItem, pPlayer, flDamage, bitsDamageType, flKnockBack, bShowBlood );
	}
}

CPlayer__TakeDamage( const pVictim, const pInflictor, const pAttacker, const Float: flDamage, const bitsDamageType, const Float: flKnockBack = 0.0, const bool: bShowBlood = true )
{
	ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pAttacker, flDamage, bitsDamageType );

	if ( flKnockBack != 0.0 )
		UTIL_PlayerKnockBack( pVictim, pAttacker, flKnockBack, 1.0 );

	if ( bShowBlood )
	{
		static iBloodColor;
		if ( ( iBloodColor = ExecuteHamB( Ham_BloodColor, pVictim ) ) != DONT_BLEED )
		{
			static Vector3( vecVictimOrigin ); get_entvar( pVictim, var_origin, vecVictimOrigin );
			UTIL_TE_BLOODSPRITE( MSG_PVS, vecVictimOrigin, iBloodColor, floatround( flDamage ) );
		}

	#if !defined _reapi_included
		CSlowDown__SpawnEntity( pVictim );
	#endif
	}
}

public CWeapon_ReloadExplode( const pItem, const pPlayer )
{
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_ReloadExplode ] );

	new Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	CWeapon_DoRadiusDamage( pPlayer, pItem, vecOrigin, WeaponReloadExplodeDamage, WeaponReloadExplodeRadius, WeaponReloadExplodeDamageType, WeaponReloadExplodeKnockBack );

	vecOrigin[ 2 ] -= ( get_entvar( pPlayer, var_flags ) & FL_DUCKING ) ? 16.0 : 32.0;
	CReloadExplode__SpawnEntity( vecOrigin );

	set_member( pItem, m_Weapon_flNextReload, 0.0 );
}

public CReloadExplode__SpawnEntity( Vector3( vecOrigin ) )
{
	new pEntity = rg_create_entity( EntityExplodeReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	engfunc( EngFunc_SetModel, pEntity, EntityExplodeModel );
	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );

	set_entvar( pEntity, var_classname, EntityExplodeClassName );
	set_entvar( pEntity, var_nextthink, get_gametime( ) + 0.5 );

	set_entvar( pEntity, var_rendermode, kRenderTransAdd );
	set_entvar( pEntity, var_renderamt, EntityExplodeBrightness );

	UTIL_SetEntityAnim( pEntity );

#if defined _reapi_included
	SetThink( pEntity, "CReloadExplode__Think" );
#endif

	return pEntity;
}

public CReloadExplode__Think( const pEntity ) UTIL_KillEntity( pEntity );

#if defined _beams_included
	public CPlayer__CheckLeftHand( const pPlayer, const szCvar[ ], const szValue[ ] )
	{
		equal( szValue, "1" ) ? BIT_SUB( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) ) : BIT_ADD( gl_bitsUserLeftHanded, BIT_PLAYER( pPlayer ) );
	}

	public CBeam__Think( const pBeam )
	{
		#if !defined _reapi_included
			if ( is_nullent( pBeam ) || get_entvar( pBeam, var_impulse ) != WeaponUnicalIndex )
				return;
		#endif

		set_entvar( pBeam, var_nextthink, get_gametime( ) + 0.05 );

		static Float: flBrightness; flBrightness = Beam_GetBrightness( pBeam );
		if ( ( flBrightness -= 15.0 ) && flBrightness <= 0.0 )
		{
			UTIL_KillEntity( pBeam );
			return;
		}

		Beam_SetBrightness( pBeam, flBrightness );
	}
#endif
/*
public CSlowDown__SpawnEntity( const pPlayer )
{
	new pEntity = NULLENT;
	pEntity = fm_find_ent_by_owner( pEntity, EntitySlowDownClassName, pPlayer );

	if ( !is_nullent( pEntity ) )
		return pEntity;

	pEntity = rg_create_entity( EntitySlowDownReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	new Float: flGameTime = get_gametime( );

	engfunc( EngFunc_SetModel, pEntity, EntitySlowDownSprite );

	set_entvar( pEntity, var_classname, EntitySlowDownClassName );
	set_entvar( pEntity, var_movetype, MOVETYPE_FOLLOW );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_aiment, pPlayer );
	set_entvar( pEntity, var_scale, EntitySlowDownScale );
	set_entvar( pEntity, var_ltime, flGameTime + WeaponDebuffTime );

	new Float: flMaxSpeed; get_entvar( pPlayer, var_maxspeed, flMaxSpeed );
	flMaxSpeed *= WeaponDebuffMultiplier;
	set_entvar( pEntity, var_maxspeed, flMaxSpeed );

	set_entvar( pEntity, var_renderamt, 255.0 );
	set_entvar( pEntity, var_rendermode, kRenderTransAdd );

	static Float: flMaxFrames;
	if ( !flMaxFrames )
		flMaxFrames = float( engfunc( EngFunc_ModelFrames, engfunc( EngFunc_ModelIndex, EntitySlowDownSprite ) ) );

	set_entvar( pEntity, var_framerate, flMaxFrames );
	set_entvar( pEntity, var_max_frame, flMaxFrames - 1.0 );
	set_entvar( pEntity, var_last_time, flGameTime );
	set_entvar( pEntity, var_nextthink, flGameTime );

#if defined _reapi_included
	SetThink( pEntity, "CSlowDown__Think" );
#endif

	return pEntity;
}

public CSlowDown__Think( const pEntity )
{
	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( !is_user_alive( pOwner ) || !zp_get_user_zombie( pOwner ) )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	UTIL_SetEntitySpriteAnim( pEntity, true );

	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flLifeTime; get_entvar( pEntity, var_ltime, flLifeTime );
	static Float: flMaxSpeed; get_entvar( pEntity, var_maxspeed, flMaxSpeed );

	if ( flLifeTime < flGameTime )
	{
		static Float: flRenderAmt; get_entvar( pEntity, var_renderamt, flRenderAmt );
		if ( ( flRenderAmt -= 15.0 ) && flRenderAmt <= 0.0 )
		{
			flMaxSpeed /= WeaponDebuffMultiplier;
			set_entvar( pOwner, var_maxspeed, flMaxSpeed );

			UTIL_KillEntity( pEntity );
			return;
		}

		set_entvar( pEntity, var_renderamt, flRenderAmt );
	}
	else set_entvar( pOwner, var_maxspeed, flMaxSpeed );

	set_entvar( pEntity, var_nextthink, flGameTime + EntitySlowDownNextThink );
}
*/

public CShadow__SpawnEntity( const pPlayer, const pInflictor, Vector3( vecOrigin ), Float: flDamage, const iLastHitGroup )
{
	new pEntity = rg_create_entity( EntityShadowReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	UTIL_DropVectorToFloor( vecOrigin );

	engfunc( EngFunc_SetModel, pEntity, EntityShadowModel );
	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );

	set_entvar( pEntity, var_classname, EntityShadowClassName );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_dmg_inflictor, pInflictor );
	set_entvar( pEntity, var_effects, get_entvar( pEntity, var_effects ) | EF_NODRAW );
	set_entvar( pEntity, var_nextthink, get_gametime( ) + 1.0 );

#if defined _zombieplague_included && defined IgnoreZombieArmor
	flDamage /= gl_flZombieArmor;
#endif

	set_entvar( pEntity, var_dmg, flDamage );
	set_entvar( pEntity, var_last_hitgroup, iLastHitGroup );

	set_entvar( pEntity, var_renderamt, 255.0 );
	set_entvar( pEntity, var_rendermode, kRenderTransTexture );

#if defined _reapi_included
	SetThink( pEntity, "CShadow__Think" );
#endif

	return pEntity;
}

public CShadow__Think( const pEntity )
{
	new pOwner = get_entvar( pEntity, var_owner );
	if ( !is_user_alive( pOwner ) || zp_get_user_zombie( pOwner ) )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	new Float: flGameTime = get_gametime( );

	if ( get_entvar( pEntity, var_shadow_state ) == ShadowState_StartHide )
	{
		set_entvar( pEntity, var_nextthink, flGameTime + 0.05 );

		static Float: flRenderAmt; get_entvar( pEntity, var_renderamt, flRenderAmt );
		if ( ( flRenderAmt -= 15.0 ) && flRenderAmt <= 0.0 )
		{
			UTIL_KillEntity( pEntity );
			return;
		}

		set_entvar( pEntity, var_renderamt, flRenderAmt );
	}
	else
	{
		set_entvar( pEntity, var_effects, get_entvar( pEntity, var_effects ) & ~EF_NODRAW );
		set_entvar( pEntity, var_shadow_state, ShadowState_StartHide );
		set_entvar( pEntity, var_nextthink, flGameTime + 1.0 );

		rh_emit_sound2( pEntity, 0, CHAN_ITEM, WeaponSounds[ Sound_Smoke ] );

		new Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
		new pVictim = UTIL_FindClosestVictim( vecOrigin, WeaponShadowFindRadius );

		if ( pVictim == NULLENT || !is_user_alive( pVictim ) )
		{
			CShadow__Effects( vecOrigin );
			return;
		}
		
		rh_emit_sound2( pEntity, 0, CHAN_WEAPON, WeaponSounds[ Sound_Shoot ] );
		UTIL_SetEntityAnim( pEntity, 1 );

		new Vector3( vecVictimOrigin ); get_entvar( pVictim, var_origin, vecVictimOrigin );

		new Vector3( vecTemp );

		// Rotate ent to target
		xs_vec_sub( vecVictimOrigin, vecOrigin, vecTemp );
		engfunc( EngFunc_VecToAngles, vecTemp, vecTemp );
		vecTemp[ 0 ] = vecTemp[ 2 ] = 0.0;	
		set_entvar( pEntity, var_angles, vecTemp );

		// Move ent to origin
		if ( xs_vec_distance( vecOrigin, vecVictimOrigin ) >= 16.0 )
		{
			angle_vector( vecTemp, ANGLEVECTOR_FORWARD, vecTemp );
			xs_vec_mul_scalar( vecTemp, 32.0, vecTemp );
			xs_vec_add( vecOrigin, vecTemp, vecOrigin );
			engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );
		}

		// Effects
		CShadow__Effects( vecOrigin );
		CShadowMuzzle__SpawnEntity( pEntity )

		// Damage next victim
		new Float: flDamage; get_entvar( pEntity, var_dmg, flDamage );

		set_member( pVictim, m_LastHitGroup, get_entvar( pEntity, var_last_hitgroup ) );
		CPlayer__TakeDamage( pVictim, get_entvar( pEntity, var_dmg_inflictor ), pOwner, flDamage, DMG_CLUB, 0.0, true );
	}
}

public CShadow__Effects( const Vector3( vecOrigin ) )
{
	UTIL_TE_EXPLOSION( MSG_PVS, gl_iszModelIndex[ ModelIndex_ShadowShoot1 ], vecOrigin, 16.0, 8, 32 );
	UTIL_TE_EXPLOSION( MSG_PVS, gl_iszModelIndex[ ModelIndex_ShadowShoot2 ], vecOrigin, 0.0, 16, 32 );
}

public CShadowMuzzle__SpawnEntity( const pOwner )
{
	new pEntity = rg_create_entity( EntityShadowMuzzleReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	new Vector3( vecOrigin ), Vector3( vecAngles );
	engfunc( EngFunc_GetAttachment, pOwner, 0, vecOrigin, vecAngles );

	engfunc( EngFunc_SetModel, pEntity, EntityShadowMuzzleSprite );
	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );

	set_entvar( pEntity, var_classname, EntityShadowMuzzleClassName );
	set_entvar( pEntity, var_scale, EntityShadowMuzzleScale );
	set_entvar( pEntity, var_frame, 0.0 );

	set_entvar( pEntity, var_renderamt, 255.0 );
	set_entvar( pEntity, var_rendermode, kRenderTransAdd );

	// dllfunc( DLLFunc_Spawn, pEntity );

	new Float: flGameTime = get_gametime( );

	static Float: flMaxFrames;
	if ( !flMaxFrames )
		flMaxFrames = float( engfunc( EngFunc_ModelFrames, engfunc( EngFunc_ModelIndex, EntityShadowMuzzleSprite ) ) );

	set_entvar( pEntity, var_framerate, flMaxFrames / EntityShadowMuzzleLifeTime );
	set_entvar( pEntity, var_max_frame, flMaxFrames - 1.0 );
	set_entvar( pEntity, var_last_time, flGameTime );
	set_entvar( pEntity, var_nextthink, flGameTime );

#if defined _reapi_included
	SetThink( pEntity, "CShadowMuzzle__Think" );
#endif

	return pEntity;
}

public CShadowMuzzle__Think( const pEntity )
{
	UTIL_SetEntitySpriteAnim( pEntity );
	set_entvar( pEntity, var_nextthink, get_gametime( ) + EntityShadowMuzzleNextThink );
}

/* ~ [ Stocks ] ~ */
stock UTIL_FindClosestVictim( const Vector3( vecOrigin ), const Float: flMaxDistance )
{
	static pFindedVictim; pFindedVictim = NULLENT;
	static Float: flDistance; flDistance = 0.0;
	static Float: flFraction; flFraction = 0.0
	static Float: flCurrentDistance; flCurrentDistance = flMaxDistance;
	static Vector3( vecVictimOrigin );

	for ( new pVictim = 1; pVictim <= gl_iMaxPlayers; pVictim++ )
	{
		if ( !is_user_alive( pVictim ) )
			continue;

		if ( !zp_get_user_zombie( pVictim ) )
			continue;

		get_entvar( pVictim, var_origin, vecVictimOrigin );

		flDistance = xs_vec_distance_2d( vecOrigin, vecVictimOrigin );
		if ( flDistance < flCurrentDistance )
		{
			engfunc( EngFunc_TraceLine, vecOrigin, vecVictimOrigin, IGNORE_MONSTERS, 0, 0 );
			get_tr2( 0, TR_flFraction, flFraction );

			if ( flFraction != 1.0 )
				continue;

			flCurrentDistance = flDistance;
			pFindedVictim = pVictim;
		}
	}

	return pFindedVictim;
}

/* ~ [ Stocks ] ~ */
#if !defined _reapi_included
	ToggleTraceAttack( const bool: bEnabled )
	{
		for ( new i; i < sizeof gl_HamHook_TraceAttack; i++ )
			bEnabled ? EnableHamForward( gl_HamHook_TraceAttack[ i ] ) : DisableHamForward( gl_HamHook_TraceAttack[ i ] );
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
		new const iWeaponList[ ][ ] = {
			{ 9, 52, -1, -1, 1, 3, 1, 0 }, // weapon_p228
			{ -1, -1, -1, -1, 0, 20, 2, 0 }, // dummy
			{ 2, 90, -1, -1, 0, 9, 3, 0 }, // weapon_scout
			{ 12, 1, -1, -1, 3, 1, 4, 24 }, // weapon_hegrenade
			{ 5, 32, -1, -1, 0, 12,5, 0 }, // weapon_xm1014
			{ 14, 1, -1, -1, 4, 3, 6, 24 }, // weapon_c4
			{ 6, 100,-1, -1, 0, 13,7, 0 }, // weapon_mac10
			{ 4, 90, -1, -1, 0, 14,8, 0 }, // weapon_aug
			{ 13, 1, -1, -1, 3, 3, 9, 24 }, // weapon_smokegrenade
			{ 10, 120,-1, -1, 1, 5, 10, 0 }, // weapon_elite
			{ 7, 100,-1, -1, 1, 6, 11, 0 }, // weapon_fiveseven
			{ 6, 100,-1, -1, 0, 15,12, 0 }, // weapon_ump45
			{ 4, 90, -1, -1, 0, 16,13, 0 }, // weapon_sg550
			{ 4, 90, -1, -1, 0, 17,14, 0 }, // weapon_galil
			{ 4, 90, -1, -1, 0, 18,15, 0 }, // weapon_famas
			{ 6, 100,-1, -1, 1, 4, 16, 0 }, // weapon_usp
			{ 10, 120,-1, -1, 1, 2, 17, 0 }, // weapon_glock18
			{ 1, 30, -1, -1, 0, 2, 18, 0 }, // weapon_awp
			{ 10, 120,-1, -1, 0, 7, 19, 0 }, // weapon_mp5navy
			{ 3, 200,-1, -1, 0, 4, 20, 0 }, // weapon_m249
			{ 5, 32, -1, -1, 0, 5, 21, 0 }, // weapon_m3
			{ 4, 90, -1, -1, 0, 6, 22, 0 }, // weapon_m4a1
			{ 10, 120,-1, -1, 0, 11,23, 0 }, // weapon_tmp
			{ 2, 90, -1, -1, 0, 3, 24, 0 }, // weapon_g3sg1
			{ 11, 2, -1, -1, 3, 2, 25, 24 }, // weapon_flashbang
			{ 8, 35, -1, -1, 1, 1, 26, 0 }, // weapon_deagle
			{ 4, 90, -1, -1, 0, 10,27, 0 }, // weapon_sg552
			{ 2, 90, -1, -1, 0, 1, 28, 0 }, // weapon_ak47
			{ -1, -1, -1, -1, 2, 1, 29, 0 }, // weapon_knife
			{ 7, 100, -1, -1, 0, 8, 30, 0 } // weapon_p90
		};

		/* -> Weapon List <- */
		stock UTIL_WeaponList( const iDist, const pReceiver, const pItem, const szWeaponName[ ], const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
		{
			static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );
			static iId; iId = get_member( pItem, m_iId ) - 1;

			message_begin( iDist, iMsgId_Weaponlist, .player = pReceiver );
			write_string( szWeaponName );
			write_byte( ( iPrimaryAmmoType <= -2 ) ? iWeaponList[ iId ][ 0 ] : iPrimaryAmmoType );
			write_byte( ( iMaxPrimaryAmmo <= -2 ) ? iWeaponList[ iId ][ 1 ] : iMaxPrimaryAmmo );
			write_byte( ( iSecondaryAmmoType <= -2 ) ? iWeaponList[ iId ][ 2 ] : iSecondaryAmmoType );
			write_byte( ( iMaxSecondaryAmmo <= -2 ) ? iWeaponList[ iId ][ 3 ] : iMaxSecondaryAmmo );
			write_byte( ( iSlot <= -2 ) ? iWeaponList[ iId ][ 4 ] : iSlot );
			write_byte( ( iPosition <= -2 ) ? iWeaponList[ iId ][ 5 ] : iPosition );
			write_byte( ( iWeaponId <= -2 ) ? iWeaponList[ iId ][ 6 ] : iWeaponId );
			write_byte( ( iFlags <= -2 ) ? iWeaponList[ iId ][ 7 ] : iFlags );
			message_end( );
		}
	#endif
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

/* -> Drop Vector to floor <- */
stock UTIL_DropVectorToFloor( Vector3( vecOrigin ) )
{
	new Vector3( vecStart ); xs_vec_copy( vecOrigin, vecStart );
	vecOrigin[ 2 ] = -4096.0;

	engfunc( EngFunc_TraceLine, vecStart, vecOrigin, IGNORE_MONSTERS, 0, 0 );
	get_tr2( 0, TR_vecEndPos, vecOrigin );
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

/* -> The target is behind the wall <- */
stock bool: UTIL_IsWallBetweenPoints( const pPlayer, const pTarget )
{
	if ( is_nullent( pPlayer ) || is_nullent( pTarget ) )
		return false;

	static Vector3( vecStart ); get_entvar( pPlayer, var_origin, vecStart );
	static Vector3( vecEnd ); get_entvar( pTarget, var_origin, vecEnd );

	engfunc( EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, pPlayer, 0 );
	get_tr2( 0, TR_vecEndPos, vecStart );

	return xs_vec_equal( vecEnd, vecStart );
}

/* -> Player KnockBack <- */
stock UTIL_PlayerKnockBack( const pVictim, const pAttacker, const Float: flForce, const Float: flVelocityModifier = 0.0 )
{
	static Vector3( vecOrigin ); get_entvar( pVictim, var_origin, vecOrigin );
	static Vector3( vecVelocity ); get_entvar( pVictim, var_velocity, vecVelocity );
	static Vector3( vecAttackerOrigin ); get_entvar( pAttacker, var_origin, vecAttackerOrigin );
	static Vector3( vecDirection ); xs_vec_sub( vecOrigin, vecAttackerOrigin, vecDirection );
	static Float: flLen; flLen = xs_vec_len_2d( vecDirection );

	new iFlgas = get_entvar(pVictim, var_flags);

	for ( new i = 0; i < 2; ++i )
	{
		vecVelocity[ i ] = ( vecDirection[ i ] / flLen ) * flForce;
		if(iFlgas & FL_DUCKING) vecVelocity[ i ] *= 0.5;
	}

	set_entvar( pVictim, var_velocity, vecVelocity );

	if ( flVelocityModifier )
		set_member( pVictim, m_flVelocityModifier, flVelocityModifier );
}

/* -> Entity Animation <- */
stock UTIL_SetEntityAnim( const pEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0 )
{
	set_entvar( pEntity, var_frame, flFrame );
	set_entvar( pEntity, var_framerate, flFrameRate );
	set_entvar( pEntity, var_animtime, get_gametime( ) );
	set_entvar( pEntity, var_sequence, iSequence );
}

/* -> Entity Sprite Animation <- */
stock UTIL_SetEntitySpriteAnim( const pEntity, const bool: bLoopSprite = false )
{
	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flFrame; get_entvar( pEntity, var_frame, flFrame );
	static Float: flFrameRate; get_entvar( pEntity, var_framerate, flFrameRate );
	static Float: flLastTime; get_entvar( pEntity, var_last_time, flLastTime );
	static Float: flMaxFrames; get_entvar( pEntity, var_max_frame, flMaxFrames );

	flFrame += ( flFrameRate * ( flGameTime - flLastTime ) );
	if ( flFrame > flMaxFrames )
	{
		if ( bLoopSprite )
			flFrame = 0.0;
		else
		{
			UTIL_KillEntity( pEntity );
			return;
		}
	}

	set_entvar( pEntity, var_frame, flFrame );
	set_entvar( pEntity, var_last_time, flGameTime );
}

/* -> TE_BLOODSPRITE < - */
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
