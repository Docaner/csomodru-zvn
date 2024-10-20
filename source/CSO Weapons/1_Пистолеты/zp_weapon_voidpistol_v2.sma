/*
 * Weapon by xUnicorn (t3rkecorejz) 
 *
 * Thanks a lot:
 *
 * Chrescoe1 & batcoh (Phenix) — First base code
 * KORD_12.7 & 406 (Nightfury) — I'm taken some functions from this authors
 * D34, 404 & fl0wer — Some help
 *
 * ┌─[ Latest versions of API's ]
 * │
 * └─┬─[ API: Muzzle-Flash ]
 *   └─ https://github.com/YoshiokaHaruki/AMXX-API-Muzzle-Flash
 *
 * ┌─[ Update 2.0 (02.08.2022) ]
 * │
 * ├─── Re-write full code
 * └─── Added ReAPI support
 */

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>

// If you don't use ZombiePlague, just comment this line
#include <zombieplague>

// If you are not using ReAPI, delete or comment out this line.
#include <reapi>

native zp_is_round_end();
#define is_user_block_dmg(%0) ((zp_is_round_end() ||  get_entvar(%0, var_takedamage) == DAMAGE_NO))

/**
 * For these APIs to work, they need to be installed on your server.
 * API plugins must be registered in plugins*.ini above those plugins where they are used.
 */
//#include <api_muzzleflash>

#if !defined DMG_GRENADE
	#define DMG_GRENADE (1<<24)
#endif

/* ~ [ Extra Item ] ~ */
#if defined _zombieplague_included
	new const ExtraItem_Name[ ] =				"Void Avenger";
	const ExtraItem_Cost =						0;
#endif

/* ~ [ Weapon Settings ] ~ */
const WeaponUnicalIndex = 						22072020;
new const WeaponName[ ] =						"Void Avenger";
new const WeaponNative[ ] =						"zp_give_user_voidpistol";
new const WeaponAnimation[ ] =					"onehanded";
new const WeaponReference[ ] =					"weapon_usp";
new const WeaponListDir[ ] =					"x/weapon_voidpistol";
new const WeaponModelView[ ] =					"models/x/v_voidpistol.mdl";
new const WeaponModelPlayer[ ] =				"models/x/p_voidpistol.mdl";
new const WeaponModelWorld[ ] =					"models/x/w_voidpistol.mdl";
new const WeaponSounds[ ][ ] = {
	"weapons/voidpistol-1.wav",
	"weapons/voidpistol-2.wav",
	"weapons/voidpistol_beep.wav"
};
new const WeaponStarDecalSprite[ ] =			"sprites/x/ef_blackhole_star.spr";

const WeaponModelWorldBody =					0;

const WeaponMaxClip =							50;
const WeaponDefaultAmmo =						150;
const WeaponMaxAmmo =							225;
const Float: WeaponRate =						0.25
const Float: WeaponAccuracy =					0.92;

#if defined _reapi_included
	const WeaponDamage =						40;
	const WeaponShotPenetration =				2;
	const Bullet: WeaponBulletType =			BULLET_PLAYER_9MM;
	const Float: WeaponShotDistance =			4096.0;
	const Float: WeaponRangeModifier =			0.8;
#else
	const Float: WeaponDamageMultiplier =		1.68;
#endif

const WeaponMaxScanningVictims =				9;
const WeaponHitCountForBlackHole =				35;
const Float: WeaponScanningDistance =			0.0;
const Float: WeaponScanningDamage =				120.0;
const WeaponScanningDmgType =					( DMG_CLUB );

/* ~ [ Entity: Black Hole ] ~ */
new const EntityBlackHoleReference[ ] =			"env_spark";
new const EntityBlackHoleClassName[ ] =			"ent_blackhole_x";
new const EntityBlackHoleModels[ ][ ] = {
	"models/x/ef_blackhole.mdl",
	"models/x/ef_blackhole_projectile.mdl"
};
new const EntityBlackHoleSounds[ ][ ] =  {
	"weapons/voidpistol_blackhole_start.wav",
	"weapons/voidpistol_blackhole_idle.wav",
	"weapons/voidpistol_blackhole_exp.wav"
};
const Float: EntityBlackHoleSpeed =				750.0;
const Float: EntityBlackHoleNextThink =			0.1;
const Float: EntityBlackHoleLifeTime =			1.0;
const Float: EntityBlackHoleRadius =			450.0;
const Float: EntityBlackHoleNextDamage =		0.15;
new const Float: EntityBlackHoleDamage[ ] = {
	220.0, // Catch Damage
	750.0 // Last Damage
};
// Only DMG_GRENADE does not stop enemies when dealing damage
const EntityBlackHoleDmgType =					DMG_GRENADE;

/* ~ [ Entity: Black Hole Sprite ] ~ */
new const EntityBlackHoleSpriteReference[ ] =	"env_sprite";
new const EntityBlackHoleSpriteClassName[ ] =	"ent_blackhole_spr_x";
new const EntityBlackHoleSprites[ ][ ] = {
	"sprites/x/ef_blackhole_start_fx.spr",
	"sprites/x/ef_blackhole_loop_fx.spr",
	"sprites/x/ef_blackhole_end_fx.spr",
	"sprites/x/ef_blackhole_projectile_fx.spr"
};

#if defined _api_muzzleflash_included
	/* ~ [ Muzzle-Flash ] ~ */
	new const MuzzleFlashSprites[ ][ ] = {
		"sprites/x/muzzleflash140_fx.spr",
		"sprites/x/muzzleflash141_fx.spr",
		"sprites/x/ef_blackhole04_fx.spr"
	};
#endif

/* ~ [ Weapon Animations ] ~ */
enum {
	WeaponAnim_Idle = 0,
	WeaponAnim_Shoot = 3,
	WeaponAnim_ShootB = 6,
	WeaponAnim_Reload = 8,
	WeaponAnim_Scan = 11,
	WeaponAnim_Change = 13,
	WeaponAnim_Draw = 15
};

const Float: WeaponAnim_Idle_Time =		6.0;
const Float: WeaponAnim_Shoot_Time =	1.0;
const Float: WeaponAnim_Reload_Time =	3.36;
const Float: WeaponAnim_Scan_Time =		0.7;
const Float: WeaponAnim_Draw_Time =		1.5;

/* ~ [ Params ] ~ */
enum {
	Sound_Shoot,
	Sound_ShootB,
	Sound_Beep
}

enum {
	BlackHoleSound_Start,
	BlackHoleSound_Idle,
	BlackHoleSound_Exp
};

enum {
	Sprite_Start,
	Sprite_Loop,
	Sprite_End,
	Sprite_Projectile
};

enum ( <<= 1 ) {
	WeaponState_Scanning = 1,
	WeaponState_HasBlackHole
};

enum ( <<= 1 ) {
	BlackHoleState_Start = 1,
	BlackHoleState_Loop,
	BlackHoleState_End
};

#if defined _zombieplague_included
	new gl_iItemId;
	new gl_bitsZombies;
#endif

new gl_iMaxPlayers;
new bool: gl_bRoundEnded = false;
new gl_iszModelIndex_StarDecal;
new Float: gl_flBlackHoleSpritesMaxFrames[ sizeof EntityBlackHoleSprites ];

#if defined _api_muzzleflash_included
	enum {
		MuzzleFlash: Muzzle_Shoot,
		MuzzleFlash: Muzzle_ShootB,
		MuzzleFlash: Muzzle_BlackHole,

		Muzzle_List
	};
	new MuzzleFlash: gl_iMuzzleFlash[ Muzzle_List ];
#endif

#if !defined _reapi_included
	new HamHook: gl_HamHook_TraceAttack[ 4 ];

	new const iWeaponList[ ] = {
		//9, 52, -1, -1, 1, 3, 1, 0 // weapon_p228
		//10, 120,-1, -1, 1, 5, 10, 0 // weapon_elite
		//7, 100,-1, -1, 1, 6, 11, 0 // weapon_fiveseven
		6, 100,-1, -1, 1, 4, 16, 0 // weapon_usp
		//10, 120,-1, -1, 1, 2, 17, 0 // weapon_glock18
		//8, 35, -1, -1, 1, 1, 26, 0 // weapon_deagle
	};
#endif

/* ~ [ Macroses ] ~ */
#if !defined _reapi_included
	#include <non_reapi_support>
#endif

#define BIT_ADD(%0,%1)					( %0 |= %1 )
#define BIT_SUB(%0,%1)					( %0 &= ~%1 )
#define BIT_VALID(%0,%1)				( %0 & %1 )

#if !defined Vector3
	#define Vector3(%0)					Float: %0[ 3 ]
#endif
#define IsNullString(%0)				bool: ( %0[ 0 ] == EOS )
#define IsVectorNull(%0)				bool: ( ( %0[ 0 ] + %0[ 1 ] + %0[ 2 ] ) == 0.0 )
#define IsCustomWeapon(%0,%1)			bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponState(%0)				get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)			set_member( %0, m_Weapon_iWeaponState, %1 )
#define GetWeaponClip(%0)				get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)			set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)			get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)			get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)			set_member( %0, m_rgAmmo, %1, %2 )
#define WeaponOnScanning(%0)			BIT_VALID( %0, WeaponState_Scanning )
#define WeaponHasBlackHole(%0)			BIT_VALID( %0, WeaponState_HasBlackHole )
#define PrepareAnimation(%0)			( WeaponHasBlackHole( %0 ) ? 2 : WeaponOnScanning( %0 ) ? 1 : 0 )

#define m_Weapon_iHitCount				m_Weapon_iGlock18ShotsFired // CWeapon
#define m_Weapon_flNextScanTime			m_Weapon_flDecreaseShotsFired // CWeapon

#define var_state						var_weaponanim // CEntity
#define var_next_state					var_fuser1 // CEntity
#define var_next_damage					var_fuser2 // CEntity
#define var_next_sound					var_impacttime // CWeapon, CEntity
#define var_last_time					var_pitch_speed // CEntity: env_sprite
#define var_max_frame					var_yaw_speed // CEntity: env_sprite
#define var_cached_entity				var_iuser2 // CWeapon, CEntity

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( ) register_native( WeaponNative, "native_give_user_weapon" );
public plugin_precache( )
{
	new i;

	/* -> Precache Models <- */
	engfunc( EngFunc_PrecacheModel, WeaponModelView );
	engfunc( EngFunc_PrecacheModel, WeaponModelPlayer );
	engfunc( EngFunc_PrecacheModel, WeaponModelWorld );

	for ( i = 0; i < sizeof EntityBlackHoleModels; i++ )
		engfunc( EngFunc_PrecacheModel, EntityBlackHoleModels[ i ] );

	for ( i = 0; i < sizeof EntityBlackHoleSprites; i++ )
	{
		new iModelIndex = engfunc( EngFunc_PrecacheModel, EntityBlackHoleSprites[ i ] );
		gl_flBlackHoleSpritesMaxFrames[ i ] = float( engfunc( EngFunc_ModelFrames, iModelIndex ) );
	}

	/* -> Precache Sounds <- */
	for ( i = 0; i < sizeof WeaponSounds; i++ )
		engfunc( EngFunc_PrecacheSound, WeaponSounds[ i ] );

	for ( i = 0; i < sizeof EntityBlackHoleSounds; i++ )
		engfunc( EngFunc_PrecacheSound, EntityBlackHoleSounds[ i ] );

#if defined WeaponListDir
	UTIL_PrecacheWeaponList( WeaponListDir );

	register_clcmd( WeaponListDir, "ClientCommand__HookWeapon" );
#endif

#if defined _api_muzzleflash_included
	/* -> Muzzle Flash <- */
	gl_iMuzzleFlash[ Muzzle_Shoot ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_Shoot ], 0.05, 1, Float: WeaponRate );
	gl_iMuzzleFlash[ Muzzle_ShootB ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_ShootB ], 0.05, 1, 0.35 );
	gl_iMuzzleFlash[ Muzzle_BlackHole ] = UTIL_MuzzleFlashInit( MuzzleFlashSprites[ Muzzle_BlackHole ], 0.08, 2, 1.0, MuzzleFlashFlag_Cyclical );
#endif

	/* -> Model Index <- */
	gl_iszModelIndex_StarDecal = engfunc( EngFunc_PrecacheModel, WeaponStarDecalSprite );
}

public plugin_init( )
{
	register_plugin( "[ZP] Weapon: Void Avenger", "2.0", "Yoshioka Haruki" );

	/* -> Fakemeta <- */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

#if !defined _reapi_included
	register_forward( FM_SetModel, "FM_Hook_SetModel_Pre", false );

	/* -> Events <- */
	register_event( "HLTV", "EV_RoundStart", "a", "1=0", "2=0" );
#endif

	register_logevent( "EV_RoundEnd", 2, "1=Round_End" );

#if defined _reapi_included
	/* -> ReGameDLL <- */
	RegisterHookChain( RG_CWeaponBox_SetModel, "RG_CWeaponBox__SetModel_Pre", false );
	RegisterHookChain( RG_CSGameRules_CleanUpMap, "RG_CSGameRules__CleanUpMap_Post", true );

	/* -> HamSandWich: Weapon <- */
	RegisterHam( Ham_Spawn, WeaponReference, "Ham_CWeapon_Spawn_Post", true );
#endif
	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_CWeapon_Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_CWeapon_Holster_Post", true );
#if defined WeaponListDir
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Ham_CWeapon_AddToPlayer_Post", true );
#endif
	//RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_CWeapon_PostFrame_Pre", false );
#if !defined _reapi_included
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Pre", false );
#else
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Post", true );
#endif
	RegisterHam( Ham_Weapon_WeaponIdle, WeaponReference, "Ham_CWeapon_WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CWeapon_PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_CWeapon_SecondaryAttack_Pre", false );

#if !defined _reapi_included
	/* -> HamSandWich: Entites <- */
	RegisterHam( Ham_Think, EntityBlackHoleSpriteReference, "Ham_CSprite_Think_Post", true );
	RegisterHam( Ham_Think, EntityBlackHoleReference, "Ham_CEntity_Think_Post", true );
	RegisterHam( Ham_Touch, EntityBlackHoleReference, "Ham_CEntity_Touch_Pre", false );

	/* -> HamSandWich: TraceAttack <- */
	gl_HamHook_TraceAttack[ 0 ] = RegisterHam( Ham_TraceAttack,	"func_breakable", "Ham_CEntity_TraceAttack_Pre", false );
	gl_HamHook_TraceAttack[ 1 ] = RegisterHam( Ham_TraceAttack,	"info_target", "Ham_CEntity_TraceAttack_Pre", false );
	gl_HamHook_TraceAttack[ 2 ] = RegisterHam( Ham_TraceAttack,	"player", "Ham_CEntity_TraceAttack_Pre", false );
	gl_HamHook_TraceAttack[ 3 ] = RegisterHam( Ham_TraceAttack,	"hostage_entity", "Ham_CEntity_TraceAttack_Pre", false );
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

public bool: native_give_user_weapon( const iPlugin, const iParams )
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !is_user_alive( pPlayer ) )
		return false;

	return CPlayer__GiveWeapon( pPlayer, WeaponReference, WeaponUnicalIndex ) ? true : false;
}

#if defined WeaponListDir
	public ClientCommand__HookWeapon( const pPlayer )
	{
		engclient_cmd( pPlayer, WeaponReference );
		return PLUGIN_HANDLED;
	}
#endif

#if defined _zombieplague_included
	public client_disconnected( pPlayer ) BIT_SUB( gl_bitsZombies, BIT( pPlayer ) );

	/* ~ [ Zombie Plague ] ~ */
	public zp_user_humanized_post( pPlayer )
	{
		if ( !is_user_connected( pPlayer ) )
			return;

		BIT_SUB( gl_bitsZombies, BIT( pPlayer ) )
	}

	public zp_user_infected_post( pPlayer )
	{
		if ( !is_user_connected( pPlayer ) )
			return;

		BIT_ADD( gl_bitsZombies, BIT( pPlayer ) );
	}

	#if defined ExtraItem_Name
		public zp_extra_item_selected( pPlayer, iItemId )
		{
			if ( iItemId != gl_iItemId )
				return PLUGIN_HANDLED;

			return CPlayer__GiveWeapon( pPlayer, WeaponReference, WeaponUnicalIndex ) ? PLUGIN_CONTINUE : ZP_PLUGIN_HANDLED;
		}
	#endif
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
		static szClassName[ 32 ];
		get_entvar( pWeaponBox, var_classname, szClassName, charsmax( szClassName ) );

		if ( !equal( szClassName, "weaponbox" ) )
			return FMRES_IGNORED;

		static pItem; pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
		if ( pItem == NULLENT || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return FMRES_IGNORED;

		engfunc( EngFunc_SetModel, pWeaponBox, WeaponModelWorld );
		set_entvar( pWeaponBox, var_body, WeaponModelWorldBody );

		return FMRES_SUPERCEDE;
	}

	public FM_Hook_PlaybackEvent_Pre( ) return FMRES_SUPERCEDE;
#endif

public FM_Hook_TraceLine_Post( const Vector3( vecSrc ), const Vector3( vecEnd ), const bitsFlags, const pEntToSkip, const pTrace )
{
	if ( bitsFlags & IGNORE_MONSTERS )
		return;

	static Float: flFraction; get_tr2( pTrace, TR_flFraction, flFraction );
	if ( flFraction == 1.0 )
		return;

	static Vector3( vecEndPos ); get_tr2( pTrace, TR_vecEndPos, vecEndPos );
	
	static iPointContents; iPointContents = engfunc( EngFunc_PointContents, vecEndPos );
	if ( iPointContents == CONTENTS_SKY )
		return;


	static pHit; pHit = ( pHit = get_tr2( pTrace, TR_pHit ) ) == -1 ? 0 : pHit;

	if(is_user_alive(pHit) && zp_get_user_zombie(pHit) || pHit <= 0 || pHit > MaxClients)
		UTIL_TE_SPRITETRAIL( MSG_BROADCAST, vecEndPos, vecEndPos, gl_iszModelIndex_StarDecal, 1, 1, 1, 25, 1 );
	
	if ( is_user_alive( pHit ) )
	{
		static pAttacker, pActiveItem;
	#if defined _reapi_included
		pActiveItem = pEntToSkip;
		pAttacker = get_member( pActiveItem, m_pPlayer );
	#else
		pAttacker = pEntToSkip;
		pActiveItem = get_member( pAttacker, m_pActiveItem );
	#endif
		if ( !is_nullent( pActiveItem ) && IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
		{
		#if defined _zombieplague_included
			if ( BIT_VALID( gl_bitsZombies, BIT( pHit ) ) )
		#else
			if ( !IsSimilarPlayersTeam( pAttacker, pHit ) )
		#endif
				CWeapon__CheckHitCount( pAttacker, pActiveItem );
		}
	}
	#if defined _reapi_included
	if(get_entvar(pHit, var_deadflag) == DEAD_NO && get_entvar(pHit, var_flags) & FL_MONSTER)
	{
		static pAttacker, pActiveItem;
		pActiveItem = pEntToSkip;
		pAttacker = get_member( pActiveItem, m_pPlayer );
		if ( !is_nullent( pActiveItem ) && IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
			CWeapon__CheckHitCount( pAttacker, pActiveItem );
	}
	#endif

	if ( pHit && is_nullent( pHit ) || ( get_entvar( pHit, var_flags ) & FL_KILLME ) || !ExecuteHam( Ham_IsBSPModel, pHit ) )
		return;

	UTIL_GunshotDecalTrace( pHit, vecEndPos );

	if ( iPointContents == CONTENTS_WATER )
		return;

	static Vector3( vecPlaneNormal ); get_tr2( pTrace, TR_vecPlaneNormal, vecPlaneNormal );

	xs_vec_mul_scalar( vecPlaneNormal, random_float( 25.0, 30.0 ), vecPlaneNormal );
	UTIL_TE_STREAK_SPLASH( MSG_PAS, vecEndPos, vecPlaneNormal, 4, random_num( 10, 20 ), 3, 64 );
}

#if defined _reapi_included
	/* ~ [ ReGameDLL ] ~ */
	public RG_CWeaponBox__SetModel_Pre( const pWeaponBox, const szModel[ ] ) 
	{
		static pItem; pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
		if ( pItem == NULLENT || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return HC_CONTINUE;

		SetHookChainArg( 2, ATYPE_STRING, WeaponModelWorld );
		set_entvar( pWeaponBox, var_body, WeaponModelWorldBody );

		return HC_CONTINUE;
	}

	public RG_CSGameRules__CleanUpMap_Post( )
	{
		gl_bRoundEnded = false;

		UTIL_DestroyEntitiesByClass( EntityBlackHoleClassName );
	}
#else
	/* ~ [ Events ] ~ */
	public EV_RoundStart( )
	{
		gl_bRoundEnded = false;

		UTIL_DestroyEntitiesByClass( EntityBlackHoleClassName );
	}
#endif

public EV_RoundEnd( )
{
	gl_bRoundEnded = true;
	gl_bitsZombies = 0;
}

/* ~ [ HamSandwich ] ~ */
#if defined _reapi_included
	public Ham_CWeapon_Spawn_Post( const pItem )
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

		SetWeaponClip( pItem, WeaponMaxClip );

		set_member( pItem, m_Weapon_bHasSecondaryAttack, true );
		set_member( pItem, m_Weapon_iDefaultAmmo, WeaponDefaultAmmo );

		rg_set_iteminfo( pItem, ItemInfo_iMaxClip, WeaponMaxClip );
		rg_set_iteminfo( pItem, ItemInfo_pszName, WeaponListDir );
		rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WeaponMaxAmmo );

		set_entvar( pItem, var_netname, WeaponName );
	}
#endif

public Ham_CWeapon_Deploy_Post( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );

	set_entvar( pPlayer, var_viewmodel, WeaponModelView );
	set_entvar( pPlayer, var_weaponmodel, WeaponModelPlayer );

	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Draw + PrepareAnimation( bitsWeaponState ) );

#if defined _api_muzzleflash_included
	if ( WeaponHasBlackHole( bitsWeaponState ) )
		zc_muzzle_draw( pPlayer, gl_iMuzzleFlash[ Muzzle_BlackHole ] );
#endif

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
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );

#if defined _api_muzzleflash_included
	if ( is_user_connected( pPlayer ) )
		zc_muzzle_destroy( pPlayer );
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
		UTIL_WeaponList( MSG_ONE, pPlayer, pItem, WeaponListDir, .iMaxPrimaryAmmo = WeaponMaxAmmo );
	#endif
	}
#endif

/*public Ham_CWeapon_PostFrame_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
#if !defined _reapi_included
	if ( get_member( pItem, m_Weapon_fInReload ) )
	{
		static iClip; iClip = GetWeaponClip( pItem );
		static iAmmoType; iAmmoType = GetWeaponAmmoType( pItem );
		static iAmmo; iAmmo = GetWeaponAmmo( pPlayer, iAmmoType );
		static iReloadClip; iReloadClip = min( WeaponMaxClip - iClip, iAmmo );

		SetWeaponClip( pItem, iClip + iReloadClip );
		SetWeaponAmmo( pPlayer, iAmmo - iReloadClip, iAmmoType );
		set_member( pItem, m_Weapon_fInReload, false );
	}
#endif

	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flNextScanTime; flNextScanTime = Float: get_member( pItem, m_Weapon_flNextScanTime );
	if ( flNextScanTime < flGameTime )
	{
		static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
		static iScanReturn; iScanReturn = CWeapon__SphereDamage( pPlayer, pItem, 1, false );
		static iAnim; iAnim = -1;

		if ( iScanReturn && !WeaponOnScanning( bitsWeaponState ) )
		{
			iAnim = WeaponAnim_Scan;
			BIT_ADD( bitsWeaponState, WeaponState_Scanning );
			SetWeaponState( pItem, bitsWeaponState );
		}
		else if ( !iScanReturn && WeaponOnScanning( bitsWeaponState ) )
		{
			iAnim = WeaponAnim_Scan + 1;
			BIT_SUB( bitsWeaponState, WeaponState_Scanning );
			SetWeaponState( pItem, bitsWeaponState );
		}

		if ( iAnim != -1 && !WeaponHasBlackHole( bitsWeaponState ) )
		{
			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iAnim );
			set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Scan_Time );
		}

		set_member( pItem, m_Weapon_flNextScanTime, flGameTime + 0.2 );
	}

	return HAM_IGNORED;
}*/

#if !defined _reapi_included
	public Ham_CWeapon_Reload_Pre( const pItem )
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return HAM_IGNORED;

		static iClip; iClip = GetWeaponClip( pItem );
		if ( iClip >= WeaponMaxClip )
			return HAM_SUPERCEDE;

		static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
		if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
			return HAM_SUPERCEDE;

		SetWeaponClip( pItem, 0 );
		ExecuteHam( Ham_Weapon_Reload, pItem );
		SetWeaponClip( pItem, iClip );
		set_member( pItem, m_Weapon_fInReload, true );

		static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Reload + PrepareAnimation( bitsWeaponState ) );

		if ( WeaponOnScanning( bitsWeaponState ) )
		{
			BIT_SUB( bitsWeaponState, WeaponState_Scanning );
			SetWeaponState( pItem, bitsWeaponState );
		}

		set_member( pPlayer, m_flNextAttack, WeaponAnim_Reload_Time );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time );

		return HAM_SUPERCEDE;
	}
#else
	public Ham_CWeapon_Reload_Post( const pItem )
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

		if ( GetWeaponClip( pItem ) >= rg_get_iteminfo( pItem, ItemInfo_iMaxClip ) )
			return;

		static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
		if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
			return;

		rg_set_animation( pPlayer, PLAYER_RELOAD );

		static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Reload + PrepareAnimation( bitsWeaponState ) );

		if ( WeaponOnScanning( bitsWeaponState ) )
		{
			BIT_SUB( bitsWeaponState, WeaponState_Scanning );
			SetWeaponState( pItem, bitsWeaponState );
		}

		set_member( pPlayer, m_flNextAttack, WeaponAnim_Reload_Time );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time );
	}
#endif

public Ham_CWeapon_WeaponIdle_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( Float: get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );

	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Idle + PrepareAnimation( bitsWeaponState ) );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Idle_Time );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PrimaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static iClip; iClip = GetWeaponClip( pItem );
	if ( !iClip ) 
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, 0.2 );

		return HAM_SUPERCEDE;
	}

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );

#if defined _api_muzzleflash_included
	zc_muzzle_draw( pPlayer, gl_iMuzzleFlash[ Muzzle_Shoot ] );
#endif

#if defined _reapi_included
	rg_set_animation( pPlayer, PLAYER_ATTACK1 );
#endif
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Shoot + PrepareAnimation( bitsWeaponState ) );
	rg_emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_Shoot ] );

	new Vector3( vecPunchAngle );
	if ( WeaponOnScanning( bitsWeaponState ) )
	{
		iClip -= CWeapon__SphereDamage( pPlayer, pItem, iClip, true );
		SetWeaponClip( pItem, iClip );
		rg_emit_sound( pPlayer, CHAN_ITEM, WeaponSounds[ Sound_Beep ] );

		xs_vec_set( vecPunchAngle, random_float( -3.0, -5.0 ), 0.0, 0.0 );

	#if !defined _reapi_included
		static szPlayerAnimation[ 32 ];
		formatex( szPlayerAnimation, charsmax( szPlayerAnimation ), "%s_shoot_%s", get_entvar( pPlayer, var_bInDuck ) ? "crouch" : "ref", WeaponAnimation );
		UTIL_PlayerAnimation( pPlayer, szPlayerAnimation );
	#endif
	}
	else
	{
	#if defined _reapi_included
		vecPunchAngle[ 0 ] = -2.0;
	#endif

		DefaultWeaponAttack( pItem, pPlayer, iClip );
	}

	if ( !IsVectorNull( vecPunchAngle ) )
		set_entvar( pPlayer, var_punchangle, vecPunchAngle );

	set_member( pItem, m_Weapon_iShotsFired, 0 );
	UTIL_WeaponSetTiming( pItem, WeaponAnim_Shoot_Time, WeaponRate );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( gl_bRoundEnded )
		return HAM_SUPERCEDE;

	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	if ( !WeaponHasBlackHole( bitsWeaponState ) )
		return HAM_SUPERCEDE;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );

	CBlackHole__SpawnEntity( pPlayer, pItem );

#if defined _api_muzzleflash_included
	zc_muzzle_destroy( pPlayer, gl_iMuzzleFlash[ Muzzle_BlackHole ] );
	zc_muzzle_draw( pPlayer, gl_iMuzzleFlash[ Muzzle_ShootB ] );
#endif

#if defined _reapi_included
	rg_set_animation( pPlayer, PLAYER_ATTACK1 );
#else
	static szPlayerAnimation[ 32 ];
	formatex( szPlayerAnimation, charsmax( szPlayerAnimation ), "%s_shoot_%s", get_entvar( pPlayer, var_bInDuck ) ? "crouch" : "ref", WeaponAnimation );
	UTIL_PlayerAnimation( pPlayer, szPlayerAnimation );
#endif
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_ShootB + _: WeaponOnScanning( bitsWeaponState ) );
	rg_emit_sound( pPlayer, CHAN_WEAPON, WeaponSounds[ Sound_ShootB ] );

	BIT_SUB( bitsWeaponState, WeaponState_HasBlackHole );
	SetWeaponState( pItem, bitsWeaponState );

	UTIL_WeaponSetTiming( pItem, WeaponAnim_Shoot_Time );

	return HAM_SUPERCEDE;
}

#if !defined _reapi_included
	public Ham_CSprite_Think_Post( const pEntity )
	{
		if ( is_nullent( pEntity ) )
			return;

		if ( FClassnameIs( pEntity, EntityBlackHoleSpriteClassName ) )
			CBlackHoleSprite__Think( pEntity );
	}

	public Ham_CEntity_Think_Post( const pEntity )
	{
		if ( is_nullent( pEntity ) )
			return;

		if ( FClassnameIs( pEntity, EntityBlackHoleClassName ) )
			CBlackHole__Think( pEntity );
	}

	public Ham_CEntity_Touch_Pre( const pEntity, const pTouch )
	{
		if ( is_nullent( pEntity ) )
			return HAM_IGNORED;

		if ( FClassnameIs( pEntity, EntityBlackHoleClassName ) )
			CBlackHole__Touch( pEntity, pTouch );

		return HAM_IGNORED;
	}

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
public bool: CPlayer__GiveWeapon( const pPlayer, const szWeaponReference[ ], const iWeaponUId )
{
	if ( !is_user_alive( pPlayer ) )
		return false;

	new pItem = NULLENT;
#if defined _reapi_included
	pItem = rg_give_custom_item( pPlayer, szWeaponReference, GT_DROP_AND_REPLACE, iWeaponUId );

	if ( is_nullent( pItem ) )
		return false;
#else
	pItem = fm_create_entity( szWeaponReference );
	if ( is_nullent( pItem ) )
		return false;

	set_entvar( pItem, var_netname, WeaponName );
	set_entvar( pItem, var_impulse, iWeaponUId );
	ExecuteHam( Ham_Spawn, pItem );
	SetWeaponClip( pItem, WeaponMaxClip );

	UTIL_DropWeapon( pPlayer, ExecuteHamB( Ham_Item_ItemSlot, pItem ) );

	if ( !ExecuteHamB( Ham_AddPlayerItem, pPlayer, pItem ) )
	{
		UTIL_KillEntity( pItem );
		return false;
	}

	ExecuteHamB( Ham_Item_AttachToPlayer, pItem, pPlayer );
	emit_sound( pPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

	new iAmmoType = GetWeaponAmmoType( pItem );
	if ( GetWeaponAmmo( pPlayer, iAmmoType ) < WeaponDefaultAmmo )
		SetWeaponAmmo( pPlayer, WeaponDefaultAmmo, iAmmoType );
#endif

	return true;
}

public CWeapon__SphereDamage( const pPlayer, const pInflictor, iClip, const bool: bDoDamage )
{
	static iCount, iBloodColor; iCount = 0;
	static Vector3( vecEndPos );
	static Vector3( vecSrc ); get_entvar( pPlayer, var_origin, vecSrc );
	static Float: flDamage, Float: flDistance, Float: flFraction;

	for ( new pVictim = 1; pVictim <= gl_iMaxPlayers; pVictim++ )
	{
		if ( iCount >= WeaponMaxScanningVictims )
			break;

		if ( !is_user_alive( pVictim ) || pVictim == pPlayer )
			continue;

	#if defined _zombieplague_included
		if ( !BIT_VALID( gl_bitsZombies, BIT( pVictim ) ) )
	#else
		if ( IsSimilarPlayersTeam( pPlayer, pVictim ) )
	#endif
			continue;

		if ( !UTIL_IsWallBetweenPoints( pPlayer, pVictim ) )
			continue;

		get_entvar( pVictim, var_origin, vecEndPos );
		flDistance = xs_vec_distance_2d( vecSrc, vecEndPos );
		if ( flDistance > WeaponScanningDistance )
			continue;

		iCount++;
		if ( !bDoDamage )
			break;

		if ( get_entvar( pVictim, var_takedamage ) == DAMAGE_NO )
			continue;

		flFraction = floatclamp( flDistance / WeaponScanningDistance, 0.0, 0.99 );
		flDamage = WeaponScanningDamage * ( 1.0 - flFraction );
		set_member( pVictim, m_LastHitGroup, HIT_GENERIC );
		ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pPlayer, flDamage, WeaponScanningDmgType );

		CWeapon__CheckHitCount( pPlayer, pInflictor );

		if ( ( iBloodColor = ExecuteHamB( Ham_BloodColor, pVictim ) ) != DONT_BLEED )
			UTIL_TE_BLOODSPRITE( MSG_PVS, vecEndPos, iBloodColor, floatround( flDamage ) );

		iClip--;
		if ( iClip <= 0 )
			break;
	}

	return iCount;
}

public CWeapon__CheckHitCount( const pPlayer, const pItem )
{
	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	if ( WeaponHasBlackHole( bitsWeaponState ) )	
		return;

	static iHitCount; iHitCount = get_member( pItem, m_Weapon_iHitCount );
	if ( ++iHitCount && iHitCount >= WeaponHitCountForBlackHole )
	{
	#if defined _api_muzzleflash_included
		zc_muzzle_draw( pPlayer, gl_iMuzzleFlash[ Muzzle_BlackHole ] );
	#endif

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Change + _: WeaponOnScanning( bitsWeaponState ) );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponOnScanning( bitsWeaponState ) ? 0.99 : 1.7 );

		BIT_ADD( bitsWeaponState, WeaponState_HasBlackHole );
		SetWeaponState( pItem, bitsWeaponState );

		iHitCount = 0;
	}

	set_member( pItem, m_Weapon_iHitCount, iHitCount );
}

public CBlackHole__SpawnEntity( const pPlayer, const pInflictor )
{
	new pEntity = rg_create_entity( EntityBlackHoleReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	static Vector3( vecOrigin ); UTIL_GetEyePosition( pPlayer, vecOrigin );
	static Vector3( vecForward ); UTIL_GetVectorAiming( pPlayer, vecForward );
	static Vector3( vecVelocity ); xs_vec_copy( vecForward, vecVelocity );

	xs_vec_add( vecOrigin, vecForward, vecOrigin );
	xs_vec_mul_scalar( vecVelocity, EntityBlackHoleSpeed, vecVelocity );

	set_entvar( pEntity, var_classname, EntityBlackHoleClassName );
	set_entvar( pEntity, var_movetype, MOVETYPE_FLY );
	set_entvar( pEntity, var_solid, SOLID_TRIGGER );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_dmg_inflictor, pInflictor );
	set_entvar( pEntity, var_velocity, vecVelocity );
	set_entvar( pEntity, var_origin, vecOrigin );
	set_entvar( pEntity, var_state, 0 );
	set_entvar( pEntity, var_nextthink, get_gametime( ) + 1.0 );

	engfunc( EngFunc_SetModel, pEntity, EntityBlackHoleModels[ 1 ] );
	CBlackHoleSprite__SpawnEntity( pEntity, EntityBlackHoleSprites[ Sprite_Projectile ], Float: gl_flBlackHoleSpritesMaxFrames[ Sprite_Projectile ], 0.1, 255.0 );

	UTIL_SetEntityAnim( pEntity );

#if defined _reapi_included
	SetThink( pEntity, "CBlackHole__Think" );
	SetTouch( pEntity, "CBlackHole__Touch" );
#endif

	return pEntity;
}

public CBlackHole__Think( const pEntity )
{
	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( UTIL_InvalidEntityOwner( pEntity, pOwner ) )
		return;

	static bitsBlackHokeState; bitsBlackHokeState = get_entvar( pEntity, var_state );
	if ( !bitsBlackHokeState )
	{
		CBlackHole__Transform( pEntity );
		return;
	}
	else
	{
		static Float: flNextState; get_entvar( pEntity, var_next_state, flNextState );
		if ( !flNextState )
			return;

		static Float: flGameTime; flGameTime = get_gametime( );
		static pSprite; pSprite = get_entvar( pEntity, var_cached_entity );

		if ( BIT_VALID( bitsBlackHokeState, BlackHoleState_End ) )
		{
			if ( flNextState < flGameTime )
			{
				UTIL_KillEntity( pEntity );
				return;
			}

			if ( CBlackHole__DoDamage( pEntity, pOwner, EntityBlackHoleDamage[ 1 ], EntityBlackHoleDmgType ) )
				set_entvar( pEntity, var_next_damage, 0.0 );
		}
		else if ( BIT_VALID( bitsBlackHokeState, BlackHoleState_Loop ) )
		{
			if ( flNextState < flGameTime )
			{
				BIT_ADD( bitsBlackHokeState, BlackHoleState_End );
				flNextState = flGameTime + 1.6;

				rg_emit_sound( pEntity, CHAN_ITEM, EntityBlackHoleSounds[ BlackHoleSound_Exp ] );
				UTIL_SetEntityAnim( pEntity, 2 );
				set_entvar( pEntity, var_next_damage, flGameTime + 1.0 );

				if ( !is_nullent( pSprite ) ) set_entvar( pSprite, var_ltime, flGameTime + 0.1 );
				CBlackHoleSprite__SpawnEntity( pEntity, EntityBlackHoleSprites[ Sprite_End ], Float: gl_flBlackHoleSpritesMaxFrames[ Sprite_End ], 0.75, 200.0 );
			}
			else
			{
				UTIL_PlayTimingSound( pEntity, pEntity, EntityBlackHoleSounds[ BlackHoleSound_Idle ], CHAN_ITEM, 1.7 );

				if ( get_entvar( pEntity, var_sequence ) != 1 )
					UTIL_SetEntityAnim( pEntity, 1 );

				if ( CBlackHole__DoDamage( pEntity, pOwner, EntityBlackHoleDamage[ 0 ], EntityBlackHoleDmgType ) )
					set_entvar( pEntity, var_next_damage, flGameTime + EntityBlackHoleNextDamage );
			}
		}
		else if ( BIT_VALID( bitsBlackHokeState, BlackHoleState_Start ) )
		{
			if ( flNextState < flGameTime )
			{
				BIT_ADD( bitsBlackHokeState, BlackHoleState_Loop );
				flNextState = flGameTime + EntityBlackHoleLifeTime;

				if ( !is_nullent( pSprite ) ) set_entvar( pSprite, var_ltime, flGameTime + 0.1 );
				CBlackHoleSprite__SpawnEntity( pEntity, EntityBlackHoleSprites[ Sprite_Loop ], Float: gl_flBlackHoleSpritesMaxFrames[ Sprite_Loop ], 0.75, 200.0 );
			}
		}

		set_entvar( pEntity, var_state, bitsBlackHokeState );
		set_entvar( pEntity, var_next_state, flNextState );
		set_entvar( pEntity, var_nextthink, flGameTime + EntityBlackHoleNextThink );
	}
}

public CBlackHole__Touch( const pEntity, const pTouch )
{
	new pOwner = get_entvar( pEntity, var_owner );
	if ( pTouch == pOwner || FClassnameIs( pTouch, EntityBlackHoleClassName ) )
		return;

	/* По тимейтам не ебашит */
	if(is_user_connected(pTouch) && !zp_get_user_zombie(pTouch))
		return;

	new Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	if ( engfunc( EngFunc_PointContents, vecOrigin ) == CONTENTS_SKY )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	CBlackHole__Transform( pEntity );
}

public CBlackHole__Transform( const pEntity )
{
	static Float: flGameTime; flGameTime = get_gametime( );

	set_entvar( pEntity, var_movetype, MOVETYPE_NONE );
	set_entvar( pEntity, var_solid, SOLID_NOT );
	set_entvar( pEntity, var_velocity, NULL_VECTOR );
	set_entvar( pEntity, var_state, get_entvar( pEntity, var_state ) | BlackHoleState_Start );
	set_entvar( pEntity, var_nextthink, flGameTime );
	set_entvar( pEntity, var_next_state, flGameTime + 1.3 );
	set_entvar( pEntity, var_next_damage, 1.0 );

	engfunc( EngFunc_SetModel, pEntity, EntityBlackHoleModels[ 0 ] );
	UTIL_SetEntityAnim( pEntity, 0 );

	CBlackHoleSprite__SpawnEntity( pEntity, EntityBlackHoleSprites[ Sprite_Start ], Float: gl_flBlackHoleSpritesMaxFrames[ Sprite_Start ], 0.75, 200.0 );

	rg_emit_sound( pEntity, CHAN_ITEM, EntityBlackHoleSounds[ BlackHoleSound_Start ] );

#if defined _reapi_included
	SetTouch( pEntity, "" );
#endif
}

public bool: CBlackHole__DoDamage( const pEntity, const pOwner, const Float: flDamage, const bitsDamageType )
{
	static pInflictor; pInflictor = get_entvar( pEntity, var_dmg_inflictor );
	if ( is_nullent( pInflictor ) || !IsCustomWeapon( pInflictor, WeaponUnicalIndex ) )
		return false;

	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flNextDamage; get_entvar( pEntity, var_next_damage, flNextDamage );
	if ( !flNextDamage || flNextDamage >= flGameTime )
		return false;

	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	static Vector3( vecVictimOrigin ), Vector3( vecVelocity ), Float: flDistance;

	for ( new pVictim = 1; pVictim <= gl_iMaxPlayers; pVictim++ )
	{
		if ( !is_user_alive( pVictim ) || pVictim == pOwner || is_user_block_dmg(pVictim))
			continue;

	#if defined _zombieplague_included
		if ( !BIT_VALID( gl_bitsZombies, BIT( pVictim ) ) )
	#else
		if ( IsSimilarPlayersTeam( pOwner, pVictim ) )
	#endif
			continue;

		if ( !UTIL_IsWallBetweenPoints( pEntity, pVictim ) )
			continue;

		get_entvar( pVictim, var_origin, vecVictimOrigin );
		flDistance = xs_vec_distance_2d( vecOrigin, vecVictimOrigin );
		if ( flDistance > EntityBlackHoleRadius )
			continue;

		UTIL_GetSpeedVector( vecVictimOrigin, vecOrigin, ( flDistance <= 16.0 ) ? 2.0 : flDistance * 5.0, vecVelocity );
		if ( !IsVectorNull( vecVelocity ) )
			set_entvar( pVictim, var_velocity, vecVelocity );

		set_member( pVictim, m_LastHitGroup, HIT_GENERIC );
		ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pOwner, flDamage, bitsDamageType );
	}

	return true;
}

stock CBlackHoleSprite__SpawnEntity( const pEntity, const szSpritePath[ ], const Float: flMaxFrames, const Float: flScale, const Float: flBrightness, const Float: flFrameRateMlt = 1.0 )
{
	new pSprite = rg_create_entity( EntityBlackHoleSpriteReference );
	if ( is_nullent( pSprite ) )
		return NULLENT;

	static Float: flGameTime; flGameTime = get_gametime( );

	set_entvar( pEntity, var_cached_entity, pSprite );

	set_entvar( pSprite, var_classname, EntityBlackHoleSpriteClassName );
	set_entvar( pSprite, var_spawnflags, SF_SPRITE_STARTON );

	set_entvar( pSprite, var_rendermode, kRenderTransAdd );
	set_entvar( pSprite, var_renderamt, flBrightness );

	set_entvar( pSprite, var_scale, flScale );
	set_entvar( pSprite, var_owner, pEntity );
	set_entvar( pSprite, var_aiment, pEntity );

	set_entvar( pSprite, var_last_time, flGameTime );
	set_entvar( pSprite, var_nextthink, flGameTime );
	// set_entvar( pSprite, var_ltime, flGameTime + 1.0 );

	engfunc( EngFunc_SetModel, pSprite, szSpritePath );
	dllfunc( DLLFunc_Spawn, pSprite );

	set_entvar( pSprite, var_frame, 0.0 );
	set_entvar( pSprite, var_max_frame, flMaxFrames - 1.0 );
	set_entvar( pSprite, var_framerate, flMaxFrames / flFrameRateMlt );

#if defined _reapi_included
	SetThink( pSprite, "CBlackHoleSprite__Think" );
#endif

	return pSprite;
}

public CBlackHoleSprite__Think( const pSprite )
{
	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flLifeTime; get_entvar( pSprite, var_ltime, flLifeTime );
	static pOwner; pOwner = get_entvar( pSprite, var_owner );
	if ( flLifeTime != 0.0 && flLifeTime < flGameTime || is_nullent( pOwner ) )
	{
		UTIL_KillEntity( pSprite );
		return;
	}

	static Float: flFrame; get_entvar( pSprite, var_frame, flFrame );
	static Float: flMaxFrames; get_entvar( pSprite, var_max_frame, flMaxFrames );
	static Float: flFrameRate; get_entvar( pSprite, var_framerate, flFrameRate );
	static Float: flLastTime; get_entvar( pSprite, var_last_time, flLastTime );

	flFrame += ( flFrameRate * ( flGameTime - flLastTime ) );
	if ( flFrame > flMaxFrames )
		flFrame = 0.0;

	set_entvar( pSprite, var_frame, flFrame );
	set_entvar( pSprite, var_last_time, flGameTime );
	set_entvar( pSprite, var_nextthink, flGameTime + 0.035 );
}

#if !defined _reapi_included
	ToggleTraceAttack( const bool: bEnabled )
	{
		for ( new i; i < sizeof gl_HamHook_TraceAttack; i++ )
			bEnabled ? EnableHamForward( gl_HamHook_TraceAttack[ i ] ) : DisableHamForward( gl_HamHook_TraceAttack[ i ] );
	}
#endif

DefaultWeaponAttack( const pItem, const pPlayer, iClip )
{
	static fw_TraceLine; fw_TraceLine = register_forward( FM_TraceLine, "FM_Hook_TraceLine_Post", true );
#if !defined _reapi_included
	#pragma unused pPlayer, iClip

	static fw_PlayBackEvent; fw_PlayBackEvent = register_forward( FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false );
	ToggleTraceAttack( true );

	ExecuteHam( Ham_Weapon_PrimaryAttack, pItem );

	unregister_forward( FM_PlaybackEvent, fw_PlayBackEvent );
	ToggleTraceAttack( false );
#else
	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flLastFire; flLastFire = get_member( pItem, m_Weapon_flLastFire );
	static Float: flAccuracy; flAccuracy = get_member( pItem, m_Weapon_flAccuracy );
	static Float: flSpread; flSpread = UTIL_GetSpreadByAction( pPlayer, Float: { 1.5, 0.225, 0.075, 0.15 }, 0.0 );
	flSpread *= ( 1.0 - flAccuracy );

	if ( flLastFire != 0.0 )
	{
		flAccuracy -= ( 0.325 - ( flGameTime - flLastFire ) ) * 0.3;
		flAccuracy = floatclamp( flAccuracy, 0.6, 0.9 );
	}

	static Vector3( vecSrc ); UTIL_GetEyePosition( pPlayer, vecSrc );
	static Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );

	rg_fire_bullets3( pItem, pPlayer, vecSrc, vecAiming, flSpread, WeaponShotDistance, WeaponShotPenetration, WeaponBulletType, WeaponDamage, WeaponRangeModifier, true, get_member( pPlayer, random_seed ) );

	set_member( pItem, m_Weapon_flAccuracy, flAccuracy );
	set_member( pItem, m_Weapon_flLastFire, flGameTime );

	SetWeaponClip( pItem, --iClip );
#endif
	unregister_forward( FM_TraceLine, fw_TraceLine, true );
}

/* ~ [ Stocks ] ~ */
#if defined _api_muzzleflash_included
	stock MuzzleFlash: UTIL_MuzzleFlashInit( const szSprite[ ], const Float: flScale, const iAttachment, const Float: flFramerateMlt, const iFlag = MuzzleFlashFlag_Once )
	{
		new MuzzleFlash: iMuzzleId = zc_muzzle_init( );
		{
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_SPRITE, szSprite );
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_SCALE, flScale );
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_ATTACHMENT, iAttachment );
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_FRAMERATE_MLT, flFramerateMlt );
			zc_muzzle_set_property( iMuzzleId, ZC_MUZZLE_FLAGS, iFlag );
		}

		return iMuzzleId;
	}
#endif

stock bool: IsSimilarPlayersTeam( const pPlayer, const pTarget )
{
	if ( get_member( pPlayer, m_iTeam ) == get_member( pTarget, m_iTeam ) )
		return true;

	return false;
}

/* -> Weapon Animation <- */
stock UTIL_SendWeaponAnim( const iDest, const pReceiver, const pItem, const iAnim ) 
{
	static iBody; iBody = is_nullent( pItem ) ? 0 : get_entvar( pItem, var_body );
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

stock bool: UTIL_InvalidEntityOwner( const pEntity, const pOwner )
{
	if ( is_user_alive( pOwner ) )
		return false;

#if defined _zombieplague_included
	if ( !zp_get_user_zombie( pOwner ) )
		return false;
#endif

	UTIL_KillEntity( pEntity );
	return true;
}

stock rg_emit_sound( const pEntity, const iChannel, const szSound[ ] )
{
#if defined _reapi_included
	rh_emit_sound2( pEntity, 0, iChannel, szSound );
#else
	emit_sound( pEntity, iChannel, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
#endif
}

stock bool: UTIL_PlayTimingSound( const pPlayer, const pEntity, const szSound[ ], const iChannel = CHAN_WEAPON, const Float: flSoundTime )
{
	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flNextSound; get_entvar( pEntity, var_next_sound, flNextSound );
	if ( flNextSound > flGameTime )
		return false;

	rg_emit_sound( pPlayer, iChannel, szSound );
	set_entvar( pEntity, var_next_sound, flGameTime + flSoundTime );

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

#if !defined _reapi_included
	/* -> Drop weapon from slot <- */
	stock UTIL_DropWeapon( const pPlayer, const iSlot )
	{
		static pItem, szWeaponName[ 32 ];
		pItem = get_pdata_cbase( pPlayer, m_rgpPlayerItems + iSlot, linux_diff_player );
		while ( !is_nullent( pItem ) )
		{
			get_entvar( pItem, var_classname, szWeaponName, charsmax( szWeaponName ) );
			engclient_cmd( pPlayer, "drop", szWeaponName );

			pItem = get_pdata_cbase( pItem, m_pNext, linux_diff_weapon );
		}
	}
#endif

#if defined WeaponListDir
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

		#if AMXX_VERSION_NUM <= 183
			format( szBuffer, charsmax( szBuffer ), "sprites/%s.spr", szSprName );
			engfunc( EngFunc_PrecacheGeneric, szBuffer );
		#else
			engfunc( EngFunc_PrecacheGeneric, fmt( "sprites/%s.spr", szSprName ) );
		#endif
		}

		fclose( pFile );
	}
#endif

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

/* -> TE_SPRITETRAIL <- */
stock UTIL_TE_SPRITETRAIL( const iDest, const Vector3( vecStart ), const Vector3( vecEnd ), const iszModelIndex, const iCount, const iLife, const iScale, const iSpeedNoise, const iSpeed )
{
	message_begin_f( iDest, SVC_TEMPENTITY );
	write_byte( TE_SPRITETRAIL );
	write_coord_f( vecStart[ 0 ] );
	write_coord_f( vecStart[ 1 ] );
	write_coord_f( vecStart[ 2 ] );
	write_coord_f( vecEnd[ 0 ] );
	write_coord_f( vecEnd[ 1 ] );
	write_coord_f( vecEnd[ 2 ] );
	write_short( iszModelIndex );
	write_byte( iCount );
	write_byte( iLife );
	write_byte( iScale );
	write_byte( iSpeedNoise );
	write_byte( iSpeed );
	message_end( );
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

/* -> Set weapon time offsets <- */
stock UTIL_WeaponSetTiming( const pItem, const Float: flIdleTime, Float: flNextAttack = 0.0 )
{
	flNextAttack = ( !flNextAttack ? flIdleTime : flNextAttack ) + 0.01;

	set_member( pItem, m_Weapon_flTimeWeaponIdle, flIdleTime );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, flNextAttack );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, flNextAttack );
}

/* -> The target is behind the wall <- */
stock bool: UTIL_IsWallBetweenPoints( const pPlayer, const pTarget )
{
	if ( is_nullent( pPlayer ) || is_nullent( pTarget ) )
		return false;

	static Vector3( vecStart ); get_entvar( pPlayer, var_origin, vecStart );
	static Vector3( vecEnd ); get_entvar( pTarget, var_origin, vecEnd );

	static pTrace; pTrace = create_tr2( );
	engfunc( EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, pPlayer, pTrace );
	static Vector3( vecEndPos ); get_tr2( pTrace, TR_vecEndPos, vecEndPos );
	free_tr2( pTrace );

	return xs_vec_equal( vecEnd, vecEndPos );
}

/* -> Get player eye position <- */
stock UTIL_GetEyePosition( const pPlayer, Vector3( vecEyeLevel ) )
{
	static Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	static Vector3( vecViewOfs ); get_entvar( pPlayer, var_view_ofs, vecViewOfs );

	xs_vec_add( vecOrigin, vecViewOfs, vecEyeLevel );
}

/* -> Get player vector aiming <- */
stock UTIL_GetVectorAiming( const pPlayer, Vector3( vecAiming ) ) 
{
	static Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	static Vector3( vecPunchangle ); get_entvar( pPlayer, var_punchangle, vecPunchangle );

	xs_vec_add( vecViewAngle, vecPunchangle, vecViewAngle );
	angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecAiming );
}

#if !defined _reapi_included
	/* -> Player Animation <- */
	stock UTIL_PlayerAnimation( const pPlayer, const szAnim[ ] ) 
	{
		new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
		if ( ( iAnimDesired = lookup_sequence( pPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed ) ) == -1 ) 
			iAnimDesired = 0;

		UTIL_SetEntityAnim( pPlayer, iAnimDesired );

		static Float: flGameTime; flGameTime = get_gametime( );

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

/* -> Entity Animation <- */
stock UTIL_SetEntityAnim( const pEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0 )
{
	set_entvar( pEntity, var_frame, flFrame );
	set_entvar( pEntity, var_framerate, flFrameRate );
	set_entvar( pEntity, var_animtime, get_gametime( ) );
	set_entvar( pEntity, var_sequence, iSequence );
}

/* -> Get speed Vector with 2 points <- */
stock UTIL_GetSpeedVector( const Vector3( vecStartOrigin ), const Vector3( vecEndOrigin ), const Float: flSpeed = 0.0, Vector3( vecVelocity ) )
{
	xs_vec_sub( vecEndOrigin, vecStartOrigin, vecVelocity );
	xs_vec_normalize( vecVelocity, vecVelocity );
	xs_vec_mul_scalar( vecVelocity, flSpeed, vecVelocity );
}

#if defined WeaponListDir
	stock UTIL_WeaponList( const iDest, const pReceiver, const pItem, const szWeaponName[ ] = "", const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
	{
		static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

		message_begin( iDest, iMsgId_Weaponlist, .player = pReceiver );

	#if defined _reapi_included
		static szWeaponList[ MAX_NAME_LENGTH ];
		if ( IsNullString( szWeaponName ) )
			rg_get_iteminfo( pItem, ItemInfo_pszName, szWeaponList, charsmax( szWeaponList ) );

		write_string( szWeaponList );
		write_byte( ( iPrimaryAmmoType <= -2 ) ? GetWeaponAmmoType( pItem ) : iPrimaryAmmoType );
		write_byte( ( iMaxPrimaryAmmo <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iMaxAmmo1 ) : iMaxPrimaryAmmo );
		write_byte( ( iSecondaryAmmoType <= -2 ) ? get_member( pItem, m_Weapon_iSecondaryAmmoType ) : iSecondaryAmmoType );
		write_byte( ( iMaxSecondaryAmmo <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iMaxAmmo2 ) : iMaxSecondaryAmmo );
		write_byte( ( iSlot <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iSlot ) : iSlot );
		write_byte( ( iPosition <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iPosition ) : iPosition );
		write_byte( ( iWeaponId <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iId ) : iWeaponId );
		write_byte( ( iFlags <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iFlags ) : iFlags );
	#else
		#pragma unused pItem

		write_string( szWeaponName );
		write_byte( ( iPrimaryAmmoType <= -2 ) ? iWeaponList[ 0 ] : iPrimaryAmmoType );
		write_byte( ( iMaxPrimaryAmmo <= -2 ) ? iWeaponList[ 1 ] : iMaxPrimaryAmmo );
		write_byte( ( iSecondaryAmmoType <= -2 ) ? iWeaponList[ 2 ] : iSecondaryAmmoType );
		write_byte( ( iMaxSecondaryAmmo <= -2 ) ? iWeaponList[ 3 ] : iMaxSecondaryAmmo );
		write_byte( ( iSlot <= -2 ) ? iWeaponList[ 4 ] : iSlot );
		write_byte( ( iPosition <= -2 ) ? iWeaponList[ 5 ] : iPosition );
		write_byte( ( iWeaponId <= -2 ) ? iWeaponList[ 6 ] : iWeaponId );
		write_byte( ( iFlags <= -2 ) ? iWeaponList[ 7 ] : iFlags );
	#endif

		message_end( );
	}
#endif

#if defined _reapi_included
	/* -> Get weapon Spread by Action <- */
	stock Float: UTIL_GetSpreadByAction( const pPlayer, const Float: flSpreadInActions[ 4 ], const Float: flMoveSpeed = 140.0 )
	{
		enum {
			Act_OnAir = 0,
			Act_OnMove,
			Act_Ducking,
			Act_None
		};

		static bitsFlags; bitsFlags = get_entvar( pPlayer, var_flags );
		static Vector3( vecVelocity ); get_entvar( pPlayer, var_velocity, vecVelocity );

		if ( ~bitsFlags & FL_ONGROUND )
			return Float: flSpreadInActions[ Act_OnAir ];
		else if ( xs_vec_len_2d( vecVelocity ) > flMoveSpeed )
			return Float: flSpreadInActions[ Act_OnMove ];
		else if ( bitsFlags & FL_DUCKING )
			return Float: flSpreadInActions[ Act_Ducking ];
		else return Float: flSpreadInActions[ Act_None ];
	}
#endif
