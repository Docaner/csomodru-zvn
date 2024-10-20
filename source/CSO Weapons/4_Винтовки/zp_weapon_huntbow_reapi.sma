/**
 * Weapon by xUnicorn aka t3rkecorejz
 *
 * Thanks a lot:
 *
 * Chrescoe1 & batcoh (Phenix) — First base code
 * KORD_12.7 & 406 (Nightfury) — I'm taken some functions from this authors
 * D34, 404 & fl0wer — Some help
 **/

#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <reapi>
#include <xs>

/**
 * [INC] Beam Entities v1.3 by [INC] Beam Entities
 * 
 * Original: https://forums.alliedmods.net/showthread.php?t=184780
 * ReAPI edit: https://gist.github.com/YoshiokaHaruki/2f9d5115f18e9759ba929e962b2c918a
 **/
#include <beams_reapi>

/* ~ [ Extra Item ] ~ */
new const EXTRA_ITEM_NAME[ ] = 				"Failnaught";
const EXTRA_ITEM_COST = 					0;

/* ~ [ Weapon Settings ] ~ */
/**
 * If u don't needed one of this utilities, u can disable macro with comment line '//'
 * 
 * CUSTOM_WEAPONLIST -						Custom WeaponList
 * CUSTOM_MUZZLEFLASH -						Custom MuzzleFlash
 * DYNAMIC_CROSSHAIR -						Dynamic Crosshair. With this macro, 
 * 											plugin 'Unlimited Clip' not works.
 **/
#define CUSTOM_WEAPONLIST
#define CUSTOM_MUZZLEFLASH
#define DYNAMIC_CROSSHAIR

new const WEAPON_REFERENCE[ ] = 			"weapon_aug";
#if defined CUSTOM_WEAPONLIST
	new const WEAPON_WEAPONLIST[ ] = 		"x_re/weapon_huntbow";
#endif
new const WEAPON_ANIMATION[ ] = 			"m249"; // CSO: slingshot
new const WEAPON_NATIVE[ ] = 				"zp_give_user_huntbow";
new const WEAPON_MODEL_VIEW[ ] = 			"models/x_re/v_huntbow.mdl";
new const WEAPON_MODEL_PLAYER[ ][ ] = 
{
	"models/x_re/p_huntbow.mdl",
	"models/x_re/p_huntbow_empty.mdl"
}
new const WEAPON_MODEL_WORLD[ ] = 			"models/x_re/w_huntbow.mdl";
new const WEAPON_SOUNDS[ ][ ] =
{
	"weapons/failnaught-1.wav", // 0
	"weapons/failnaught-2.wav", // 1
	"weapons/failnaught-2_exp.wav", // 2
	
	"weapons/failnaught_charge_loop_fx.wav", // 3
	"weapons/failnaught_charge_shoot.wav", // 4
	"weapons/failnaught_charge_start_fx.wav", // 5
	"weapons/failnaught_loop_fx.wav", // 6
	"weapons/failnaught_shoot1_empty.wav" // 7

	/**
	 * If 'sv_auto_precache_sounds_in_models 1', these sounds not needed a precache
	 **/
	// "weapons/failnaught_charge_shoot1.wav", // 8
	// "weapons/failnaught_charge_shoot2.wav", // 9
	// "weapons/failnaught_charge_start1.wav", // 10
	// "weapons/failnaught_draw.wav", // 11
	// "weapons/failnaught_draw_empty.wav", // 12
	// "weapons/failnaught_shoot1.wav", // 13
};

const WEAPON_MODEL_WORLD_BODY = 			0;

const WEAPON_DEFAULT_AMMO = 				250;
const Float: WEAPON_RATE =					0.3;

/**
 * Damage params:
 * 
 * WEAPON_DAMAGE - 							Damage from default arrow
 * WEAPON_DAMAGE_ADD - 						How much damage to add with normal shots 
 * 											(WEAPON_DAMAGE + (WEAPON_DAMAGE_ADD * n), 
 * 											where 'n', is count of hits from default arrow
 * WEAPON_DAMAGE_EX -						Damage from charged arrow
 **/
const Float: WEAPON_DAMAGE =				50.0;
const Float: WEAPON_DAMAGE_ADD =			25.0;
const Float: WEAPON_DAMAGE_EX =				500.0;
const WEAPON_DMGTYPE = 						( DMG_BULLET | DMG_NEVERGIB );

/* ~ [ Entity: Arrow ] ~ */
new const ENTITY_ARROW_REFERENCE[ ] =		"info_target";
new const ENTITY_ARROW_CLASSNAME[ ] =		"ent_huntbow_arrow_x";
new const ENTITY_ARROW_MODEL[ ] =			"models/x_re/huntbow_arrow.mdl";

const Float: ENTITY_ARROW_SPEED =			1000.0;
const Float: ENTITY_ARROW_CHARGED_SPEED =	4000.0;
const Float: ENTITY_ARROW_DESTROY_TIME =	1.25;
#define ENTITY_ARROW_TRAIL_COLOR			{ 255, 255, 0 }
const ENTITY_ARROW_MAX_PENETRATION =		25; // Penetration count (only for charged arrow)

/* ~ [ Entity: Damage Counter ] ~ */
new const ENTITY_COUNTER_REFERENCE[ ] =		"info_target";
new const ENTITY_COUNTER_CLASSNAME[ ] =		"ent_huntbow_counter_x";
new const ENTITY_COUNTER_SPRITE[ ] =		"sprites/x_re/dmgreiteration_fx.spr";
const Float: ENTITY_COUNTER_LIFETIME =		1.0;

/* ~ [ Weapon Effects ] ~ */
new const WEAPON_EFFECTS_LIST[ ][ ] = {
	"sprites/x_re/ef_huntbow_explo_fx.spr",
	"sprites/x_re/ef_huntbow_trail_fx.spr",
	"sprites/laserbeam.spr"
};

/* ~ [ Entity: MuzzleFlash ] ~ */
#if defined CUSTOM_MUZZLEFLASH
	new const ENTITY_MUZZLE_REFERENCE[ ] =		"env_sprite";
	new const ENTITY_MUZZLE_CLASSNAME[ ] =		"ent_muzzle_huntbow_x";
	new const ENTITY_MUZZLE_SPRITES[ ][ ] =	{
		"sprites/x_re/muzzleflash208.spr",
		"sprites/x_re/muzzleflash209.spr",
		"sprites/x_re/muzzleflash210.spr",
		"sprites/x_re/muzzleflash211.spr",
		"sprites/x_re/muzzleflash212.spr"
	};
	const Float: ENTITY_MUZZLE_NEXTTHINK =		0.05;

	/**
	 * _Start - Start frame of sprite part
	 * _End - End frame of sprite part
	 * _Scale - Scale of sprite part
	 **/
	enum _: eMuzzleData {
		eMuzzle_ChargeIdle1_Sprite,
		eMuzzle_ChargeIdle2_Sprite,
		eMuzzle_ChargeFinish_Sprite,
		eMuzzle_Shoot_Sprite,
		eMuzzle_Draw_Sprite,

		Float: eMuzzle_ChargeIdle1_Scale = 0.05,
		Float: eMuzzle_ChargeIdle2_Scale = 0.3,
		Float: eMuzzle_ChargeFinish_Scale = 0.15,
		Float: eMuzzle_Shoot_Scale = 0.1,
		Float: eMuzzle_Draw_Scale = 0.05
	};
#endif

/* ~ [ Weapon Animations ] ~ */
enum _: eWeaponAnimList {
	eWeaponAnim_Dummy = 0,
	eWeaponAnim_Idle,
	eWeaponAnim_Idle_Empty,
	eWeaponAnim_Shoot,
	eWeaponAnim_Shoot_Empty,
	eWeaponAnim_Draw,
	eWeaponAnim_Draw_Empty,
	eWeaponAnim_ChargeStart,
	eWeaponAnim_ChargeFinish,
	eWeaponAnim_ChargeIdle1,
	eWeaponAnim_ChargeIdle2,
	eWeaponAnim_ChargeShoot1,
	eWeaponAnim_ChargeShoot1_Empty,
	eWeaponAnim_ChargeShoot2,
	eWeaponAnim_ChargeShoot2_Empty
};

#define flWeaponAnim_Idle_Time  			( 91 / 30.0 )
#define flWeaponAnim_Shoot_Time  			( 16 / 30.0 )
#define flWeaponAnim_Draw_Time  			( 51 / 30.0 )
#define flWeaponAnim_ChargeStart_Time  		( 21 / 30.0 )
#define flWeaponAnim_ChargeFinish_Time  	( 9 / 30.0 )
#define flWeaponAnim_ChargeIdle_Time  		( 14 / 30.0 )
#define flWeaponAnim_ChargeShoot_Time  		( 40 / 30.0 )

/* ~ [ Params ] ~ */
new gl_iItemId;
new gl_iAllocString_WeaponUId;

enum _: eModelIndex {
	eEffect_Explosion = 0,
	eEffect_ArrowTrail,
	eEffect_LaserBeam
};
new gl_iszModelIndex[ eModelIndex ];

enum _: eWeaponState {
	WPNSTATE_NONE = 0,
	WPNSTATE_CHARGING,
	WPNSTATE_CHARGED,
};

/* ~ [ Macroses ] ~ */
#define Vector3(%0) 						Float: %0[ 3 ]
#define IsCustomWeapon(%0,%1)				bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponState(%0)					get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)				set_member( %0, m_Weapon_iWeaponState, %1 )
#define GetWeaponClip(%0)					get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)				set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)				get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)				get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)				set_member( %0, m_rgAmmo, %1, %2 )

#define BIT_ADD(%0,%1)						( %0 |= BIT( %1 ) )
#define BIT_SUB(%0,%1)						( %0 &= ~BIT( %1 ) )
#define BIT_VALID(%0,%1)					( %0 & BIT( %1 ) )

#define WEAPON_NOCLIP						-1
#define LOWER_LIMIT_OF_ENTITIES				100

#define var_velocity_cached 				var_endpos // CEntity
#define var_penetration						var_light_level // CEntity
#define var_charged_shoot					var_colormap // CEntity
#define var_beam_index						var_button // CEntity
#define var_max_frame						var_yaw_speed // CEntity: env_sprite
#define var_last_time						var_pitch_speed // CEntity: env_sprite
#define var_next_sound						var_impacttime // CWeapon

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( ) register_native( WEAPON_NATIVE, "Native_GiveWeapon" );

public plugin_precache( ) 
{
	new i;

	/* -> Precache Models -> */
	engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_VIEW );
	engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_WORLD );

	for ( i = 0; i < sizeof WEAPON_MODEL_PLAYER; i++ )
		engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER[ i ] );

	engfunc( EngFunc_PrecacheModel, ENTITY_ARROW_MODEL );
	engfunc( EngFunc_PrecacheModel, ENTITY_COUNTER_SPRITE );

	#if defined CUSTOM_MUZZLEFLASH
		for ( i = 0; i < sizeof ENTITY_MUZZLE_SPRITES; i++ )
			engfunc( EngFunc_PrecacheModel, ENTITY_MUZZLE_SPRITES[ i ] );
	#endif

	for ( i = 0; i < eModelIndex; i++ )
		gl_iszModelIndex[ i ] = engfunc( EngFunc_PrecacheModel, WEAPON_EFFECTS_LIST[ i ] );

	/* -> Precache Sounds -> */
	for ( i = 0; i < sizeof WEAPON_SOUNDS; i++ )
		engfunc( EngFunc_PrecacheSound, WEAPON_SOUNDS[ i ] );

	#if defined CUSTOM_WEAPONLIST
		/* -> Hook Weapon -> */
		register_clcmd( WEAPON_WEAPONLIST, "Command_HookWeapon" );

		UTIL_PrecacheWeaponList( WEAPON_WEAPONLIST );
	#endif
	
	/* -> Alloc String -> */
	#if defined CUSTOM_WEAPONLIST
		gl_iAllocString_WeaponUId = engfunc( EngFunc_AllocString, WEAPON_WEAPONLIST );
	#else
		gl_iAllocString_WeaponUId = engfunc( EngFunc_AllocString, WEAPON_NATIVE );
	#endif
}

public plugin_init( ) 
{
	// Original: https://cso.fandom.com/wiki/Failnaught
	register_plugin( "[ZP] Weapon: Failnaught", "1.1", "Yoshioka Haruki" );

	/* -> Fakemeta -> */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

	/* -> ReAPI -> */
	RegisterHookChain( RG_CWeaponBox_SetModel, "CWeaponBox__SetModel_Pre", false );
	RegisterHookChain( RG_CSGameRules_CleanUpMap, "CSGameRules__CleanUpMap_Post", true );

	/* -> HamSandwich -> */
	RegisterHam( Ham_Spawn, WEAPON_REFERENCE, "CBasePlayerWeapon__Spawn_Post", true );
	RegisterHam( Ham_Item_Deploy, WEAPON_REFERENCE, "CBasePlayerWeapon__Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WEAPON_REFERENCE, "CBasePlayerWeapon__Holster_Post", true );
	#if defined CUSTOM_WEAPONLIST
		RegisterHam( Ham_Item_AddToPlayer, WEAPON_REFERENCE, "CBasePlayerWeapon__AddToPlayer_Post", true );
	#endif
	RegisterHam( Ham_Item_PostFrame, WEAPON_REFERENCE, "CBasePlayerWeapon__PostFrame_Pre", false );
	RegisterHam( Ham_Weapon_Reload, WEAPON_REFERENCE, "CBasePlayerWeapon__Reload_Pre", false );
	RegisterHam( Ham_Weapon_WeaponIdle, WEAPON_REFERENCE, "CBasePlayerWeapon__WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WEAPON_REFERENCE, "CBasePlayerWeapon__PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WEAPON_REFERENCE, "CBasePlayerWeapon__SecondaryAttack_Pre", false );

	/* -> Register on Extra-Items -> */
	gl_iItemId = zp_register_extra_item( EXTRA_ITEM_NAME, EXTRA_ITEM_COST, ZP_TEAM_HUMAN );
}

public plugin_cfg( )
{
	if ( get_cvar_num( "sv_maxvelocity" ) < floatround( ENTITY_ARROW_CHARGED_SPEED ) )
		set_cvar_num( "sv_maxvelocity", floatround( ENTITY_ARROW_CHARGED_SPEED ) );
}

public bool: Native_GiveWeapon( ) 
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !is_user_alive( pPlayer ) )
		return false;
	
	return UTIL_GiveCustomWeapon( pPlayer, WEAPON_REFERENCE, gl_iAllocString_WeaponUId, WEAPON_DEFAULT_AMMO );
}

#if defined CUSTOM_WEAPONLIST
	public Command_HookWeapon( const pPlayer ) 
	{
		engclient_cmd( pPlayer, WEAPON_REFERENCE );
		return PLUGIN_HANDLED;
	}
#endif

/* ~ [ Zombie Plague ] ~ */
public zp_extra_item_selected( pPlayer, iItemId ) 
{
	if ( iItemId != gl_iItemId ) 
		return PLUGIN_HANDLED;

	return UTIL_GiveCustomWeapon( pPlayer, WEAPON_REFERENCE, gl_iAllocString_WeaponUId, WEAPON_DEFAULT_AMMO ) ? PLUGIN_CONTINUE : ZP_PLUGIN_HANDLED;
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
	if ( !is_user_alive( pPlayer ) )
		return;

	static pActiveItem; pActiveItem = get_member( pPlayer, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, gl_iAllocString_WeaponUId ) )
		return;

	set_cd( CD_Handle, CD_flNextAttack, 2.0 );
}

/* ~ [ ReAPI ] ~ */
public CWeaponBox__SetModel_Pre( const pWeaponBox, const szModel[ ] ) 
{
	if ( !IsCustomWeapon( UTIL_GetWeaponBoxItem( pWeaponBox ), gl_iAllocString_WeaponUId ) )
		return HC_CONTINUE;

	SetHookChainArg( 2, ATYPE_STRING, WEAPON_MODEL_WORLD );
	set_entvar( pWeaponBox, var_body, WEAPON_MODEL_WORLD_BODY );

	return HC_CONTINUE;
}

public CSGameRules__CleanUpMap_Post( )
{
	new pEntity = NULLENT;
	while ( ( pEntity = rg_find_ent_by_class( pEntity, ENTITY_ARROW_CLASSNAME ) ) )
		UTIL_KillEntity( pEntity );

	pEntity = NULLENT;
	while ( ( pEntity = rg_find_ent_by_class( pEntity, ENTITY_COUNTER_CLASSNAME ) ) )
		UTIL_KillEntity( pEntity );

	pEntity = NULLENT;
	while ( ( pEntity = rg_find_ent_by_class( pEntity, "beam" ) ) )
		UTIL_KillEntity( pEntity );

	#if defined CUSTOM_MUZZLEFLASH
		pEntity = NULLENT;
		while ( ( pEntity = rg_find_ent_by_class( pEntity, ENTITY_MUZZLE_CLASSNAME ) ) )
			UTIL_KillEntity( pEntity );
	#endif
}

/* ~ [ HamSandwich ] ~ */
public CBasePlayerWeapon__Spawn_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, gl_iAllocString_WeaponUId ) )
		return;

	SetWeaponClip( pItem, WEAPON_NOCLIP );
	set_member( pItem, m_Weapon_iDefaultAmmo, WEAPON_DEFAULT_AMMO );
	set_member( pItem, m_Weapon_bHasSecondaryAttack, true );

	#if defined CUSTOM_WEAPONLIST
		rg_set_iteminfo( pItem, ItemInfo_pszName, WEAPON_WEAPONLIST );
	#endif
	rg_set_iteminfo( pItem, ItemInfo_iMaxClip, WEAPON_NOCLIP );
	rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WEAPON_DEFAULT_AMMO );
}

public CBasePlayerWeapon__Deploy_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, gl_iAllocString_WeaponUId ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );
	static iAmmoType, iAmmo; GetPlayerWeaponAmmo( pPlayer, pItem, iAmmo, iAmmoType );

	set_entvar( pPlayer, var_viewmodel, WEAPON_MODEL_VIEW );
	set_entvar( pPlayer, var_weaponmodel, WEAPON_MODEL_PLAYER[ iAmmo ? 0 : 1 ] );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, eWeaponAnim_Draw + ( !iAmmo ? 1 : 0 ) );
	#if defined CUSTOM_MUZZLEFLASH
		UTIL_DrawMuzzleFlash( pPlayer, ENTITY_MUZZLE_CLASSNAME, ENTITY_MUZZLE_SPRITES[ eMuzzle_Draw_Sprite ], .flScale = Float: eMuzzle_Draw_Scale );
	#endif

	SetWeaponState( pItem, WPNSTATE_NONE );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flWeaponAnim_Draw_Time );
	set_member( pPlayer, m_flNextAttack, 0.3 ); // Idk, why in CSO u can use weapon so fast after deploy
	set_member( pPlayer, m_szAnimExtention, WEAPON_ANIMATION );
}

public CBasePlayerWeapon__Holster_Post( const pItem )
{
	if ( !IsCustomWeapon( pItem, gl_iAllocString_WeaponUId ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	UTIL_ResetTimingSound( pPlayer, pItem );

	#if defined CUSTOM_MUZZLEFLASH
		new pMuzzleFlash = NULLENT;
		if ( rg_find_ent_by_owner( pMuzzleFlash, ENTITY_MUZZLE_CLASSNAME, pPlayer ) && !is_nullent( pMuzzleFlash ) )
			UTIL_KillEntity( pMuzzleFlash ); 
	#endif
}

#if defined CUSTOM_WEAPONLIST
	public CBasePlayerWeapon__AddToPlayer_Post( const pItem, const pPlayer ) 
	{
		new iWeaponUId = get_entvar( pItem, var_impulse );
		if ( iWeaponUId != 0 && iWeaponUId != gl_iAllocString_WeaponUId )
			return;

		UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
	}
#endif

public CBasePlayerWeapon__PostFrame_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, gl_iAllocString_WeaponUId ) )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );

	#if defined DYNAMIC_CROSSHAIR
		UTIL_ResetCrosshair( pPlayer, pItem );
	#endif

	if ( ~get_entvar( pPlayer, var_button ) & IN_ATTACK2 )
	{
		new bitsWeaponState = GetWeaponState( pItem )
		if ( !bitsWeaponState )
			return HAM_IGNORED;

		if ( BIT_VALID( bitsWeaponState, WPNSTATE_CHARGED ) )
		{
			static iAmmo, iAmmoType; GetPlayerWeaponAmmo( pPlayer, pItem, iAmmo, iAmmoType );
			if ( iAmmo )
				CBasePlayerWeapon__Fire( pPlayer, pItem, eWeaponAnim_ChargeShoot2, WEAPON_SOUNDS[ 1 ], flWeaponAnim_ChargeShoot_Time, flWeaponAnim_ChargeShoot_Time, iAmmo, iAmmoType, true );
		}
		else ExecuteHamB( Ham_Weapon_PrimaryAttack, pItem );

		SetWeaponState( pItem, 0 );
	}

	return HAM_IGNORED;
}

public CBasePlayerWeapon__Reload_Pre( const pItem ) return ( !IsCustomWeapon( pItem, gl_iAllocString_WeaponUId ) ) ? HAM_IGNORED : HAM_SUPERCEDE;

public CBasePlayerWeapon__WeaponIdle_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, gl_iAllocString_WeaponUId ) || get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );
	static iAmmoType, iAmmo; GetPlayerWeaponAmmo( pPlayer, pItem, iAmmo, iAmmoType );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, eWeaponAnim_Idle + ( !iAmmo ? 1 : 0 ) );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flWeaponAnim_Idle_Time );

	return HAM_SUPERCEDE;
}

public CBasePlayerWeapon__PrimaryAttack_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, gl_iAllocString_WeaponUId ) )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );
	static iAmmoType, iAmmo; GetPlayerWeaponAmmo( pPlayer, pItem, iAmmo, iAmmoType );
	if ( !iAmmo ) 
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, 0.2 );

		return HAM_SUPERCEDE;
	}

	CBasePlayerWeapon__Fire( pPlayer, pItem, eWeaponAnim_Shoot, WEAPON_SOUNDS[ 0 ], WEAPON_RATE, flWeaponAnim_Shoot_Time, iAmmo, iAmmoType, false );

	return HAM_SUPERCEDE;
}

public CBasePlayerWeapon__SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, gl_iAllocString_WeaponUId ) )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );
	new bitsWeaponState = GetWeaponState( pItem );

	if ( BIT_VALID( bitsWeaponState, WPNSTATE_CHARGING ) )
	{
		if ( BIT_VALID( bitsWeaponState, WPNSTATE_CHARGED ) )
		{
			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, eWeaponAnim_ChargeFinish );
			UTIL_WeaponSetTiming( pPlayer, pItem, flWeaponAnim_ChargeFinish_Time );
			UTIL_ResetTimingSound( pPlayer, pItem );
			#if defined CUSTOM_MUZZLEFLASH
				UTIL_DrawMuzzleFlash( pPlayer, ENTITY_MUZZLE_CLASSNAME, ENTITY_MUZZLE_SPRITES[ eMuzzle_ChargeFinish_Sprite ],.flScale = Float: eMuzzle_ChargeFinish_Scale, .flFramerateMlt = 2.0 );
			#endif

			BIT_SUB( bitsWeaponState, WPNSTATE_CHARGING );
		}
		else
		{
			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, eWeaponAnim_ChargeIdle1 );
			UTIL_WeaponSetTiming( pPlayer, pItem, flWeaponAnim_ChargeIdle_Time );
			UTIL_PlayTimingSound( pPlayer, pItem, WEAPON_SOUNDS[ 6 ], CHAN_WEAPON, 4.0 );
			#if defined CUSTOM_MUZZLEFLASH
				UTIL_DrawMuzzleFlash( pPlayer, ENTITY_MUZZLE_CLASSNAME, ENTITY_MUZZLE_SPRITES[ eMuzzle_ChargeIdle1_Sprite ], .flScale = Float: eMuzzle_ChargeIdle1_Scale );
			#endif

			BIT_ADD( bitsWeaponState, WPNSTATE_CHARGED );
		}
	}
	else if ( BIT_VALID( bitsWeaponState, WPNSTATE_CHARGED ) )
	{
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, eWeaponAnim_ChargeIdle2 );
		UTIL_WeaponSetTiming( pPlayer, pItem, flWeaponAnim_ChargeIdle_Time, 0.1 );
		UTIL_PlayTimingSound( pPlayer, pItem, WEAPON_SOUNDS[ 3 ], CHAN_WEAPON, 4.0 );
		#if defined CUSTOM_MUZZLEFLASH
			UTIL_DrawMuzzleFlash( pPlayer, ENTITY_MUZZLE_CLASSNAME, ENTITY_MUZZLE_SPRITES[ eMuzzle_ChargeIdle2_Sprite ], .flScale = Float: eMuzzle_ChargeIdle2_Scale, .flBrightness = 200.0 );
		#endif

		new szPlayers[ MAX_CLIENTS ], iPlayersNum;
		get_players_ex( szPlayers, iPlayersNum, GetPlayers_ExcludeDead|GetPlayers_MatchTeam|GetPlayers_ExcludeHLTV, "TERRORIST" );
		for ( new i, pVictim = NULLENT; i < iPlayersNum; i++ )
		{
			pVictim = szPlayers[ i ];
			if ( !is_user_alive( pVictim ) || !zp_get_user_zombie( pVictim ) )
				continue;

			if ( ExecuteHam( Ham_FInViewCone, pPlayer, pVictim ) && !UTIL_IsWallBetweenPoints( pPlayer, pVictim ) )
			{
				/**
				 * From Lite ESP
				 * Source: https://goldsrc.ru/resources/200/
				 **/
				static Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
				static Vector3( vecVictimOrigin ); get_entvar( pVictim, var_origin, vecVictimOrigin );

				static Float: flDistance; flDistance = xs_vec_distance( vecOrigin, vecVictimOrigin );
				if ( flDistance >= 1000.0 )
					continue;

				static pTrace; pTrace = create_tr2( );
				engfunc( EngFunc_TraceLine, vecOrigin, vecVictimOrigin, IGNORE_MONSTERS, -1, pTrace );
				static Vector3( vecEndPos ); get_tr2( pTrace, TR_vecEndPos, vecEndPos );
				free_tr2( pTrace );

				static Float: flDistanceToEndPos; flDistanceToEndPos = xs_vec_distance( vecOrigin, vecEndPos );
				if ( floatcmp( flDistance, flDistanceToEndPos ) == 0 )
					continue;

				static Vector3( vecCentre ); xs_vec_sub( vecVictimOrigin, vecOrigin, vecCentre );
				static Vector3( vecOffset ); xs_vec_copy( vecCentre, vecOffset );
				xs_vec_div_scalar( vecOffset, xs_vec_len( vecCentre ), vecOffset );
				xs_vec_mul_scalar( vecOffset, flDistanceToEndPos - 10.0, vecOffset );

				static Vector3( vecEyeLevel ); xs_vec_copy( vecOrigin, vecEyeLevel );
				vecEyeLevel[ 2 ] += 17.5; xs_vec_add( vecOffset, vecEyeLevel, vecOffset );
				static Vector3( vecStart ); xs_vec_copy( vecOffset, vecStart );
				static Vector3( vecEnd ); xs_vec_copy( vecOffset, vecEnd );
				static Float: flScaledBoneLen; flScaledBoneLen = flDistanceToEndPos / flDistance * 50.0;
				vecEnd[ 2 ] -= flScaledBoneLen;

				message_begin_f( MSG_ONE, SVC_TEMPENTITY, .player = pPlayer );
				UTIL_TE_BEAMPOINTS( vecStart, vecEnd, gl_iszModelIndex[ eEffect_LaserBeam ], 3, 0, floatround( flWeaponAnim_ChargeIdle_Time * 10.0 ), floatround( flScaledBoneLen * 3.0 ), 0, { 255, 0, 0 }, 128, 0 );
			}
			else continue;
		}
	}
	else
	{
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, eWeaponAnim_ChargeStart );
		UTIL_WeaponSetTiming( pPlayer, pItem, flWeaponAnim_ChargeStart_Time );

		BIT_ADD( bitsWeaponState, WPNSTATE_CHARGING );
	}

	SetWeaponState( pItem, bitsWeaponState );

	return HAM_SUPERCEDE;
}

public CBasePlayerWeapon__Fire( const pPlayer, const pItem, iWeaponAnim, const szSound[ ], const Float: flNextAttack, const Float: flAnimationTime, iAmmo, const iAmmoType, const bool: bChargedShoot )
{
	#if defined DYNAMIC_CROSSHAIR
		UTIL_IncreaseCrosshair( pPlayer, pItem );
	#endif
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, iWeaponAnim );
	rg_set_animation( pPlayer, PLAYER_ATTACK1 );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, szSound );

	#if defined CUSTOM_MUZZLEFLASH
		UTIL_DrawMuzzleFlash( pPlayer, ENTITY_MUZZLE_CLASSNAME, ENTITY_MUZZLE_SPRITES[ eMuzzle_Shoot_Sprite ], .flScale = Float: eMuzzle_Shoot_Scale, .flFramerateMlt = 2.75, .flBrightness = 200.0, .bShowOnlyOwner = false );
	#endif

	CArrow_SpawnEntity( pPlayer, pItem, bChargedShoot );

	new bitsFlags = get_entvar( pPlayer, var_flags );
	new Vector3( vecVelocity ); get_entvar( pPlayer, var_velocity, vecVelocity );

	if ( xs_vec_len_2d( vecVelocity ) > 0 ) 
		UTIL_WeaponKickBack( pItem, pPlayer, 1.0, 0.45, 0.28, 0.04, 4.25, 2.5, 7 );
	else if ( ~bitsFlags & FL_ONGROUND ) 
		UTIL_WeaponKickBack( pItem, pPlayer, 1.25, 0.45, 0.22, 0.18, 6.0, 4.0, 5 );
	else if ( bitsFlags & FL_DUCKING ) 
		UTIL_WeaponKickBack( pItem, pPlayer, 0.6, 0.35, 0.2, 0.0125, 3.7, 2.0, 10 );
	else
		UTIL_WeaponKickBack( pItem, pPlayer, 0.625, 0.375, 0.25, 0.0125, 4.0, 2.25, 9 );

	SetWeaponAmmo( pPlayer, --iAmmo, iAmmoType );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, flNextAttack );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, flNextAttack );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flAnimationTime );

	if ( !iAmmo )
		set_entvar( pPlayer, var_weaponmodel, WEAPON_MODEL_PLAYER[ 1 ] );

	return true;
}

public CArrow_SpawnEntity( const pOwner, const pInflictor, const bool: bChargedShoot )
{
	new pEntity = rg_create_entity( ENTITY_ARROW_REFERENCE );

	if ( is_nullent( pEntity ) )
		return false;

	new Vector3( vecOrigin ); get_entvar( pOwner, var_origin, vecOrigin );
	new Vector3( vecViewOfs ); get_entvar( pOwner, var_view_ofs, vecViewOfs );
	new Vector3( vecViewAngle ); get_entvar( pOwner, var_v_angle, vecViewAngle );
	new Vector3( vecForward ); angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecForward );
	new Vector3( vecVelocity ); xs_vec_copy( vecForward, vecVelocity );
	new Vector3( vecAngles );

	xs_vec_add( vecViewOfs, vecForward, vecViewOfs );
	xs_vec_add( vecOrigin, vecViewOfs, vecOrigin );

	xs_vec_mul_scalar( vecVelocity, bChargedShoot ? ENTITY_ARROW_CHARGED_SPEED : ENTITY_ARROW_SPEED, vecVelocity );
	engfunc( EngFunc_VecToAngles, vecVelocity, vecAngles );

	set_entvar( pEntity, var_classname, ENTITY_ARROW_CLASSNAME );
	set_entvar( pEntity, var_solid, SOLID_TRIGGER );
	set_entvar( pEntity, var_movetype, MOVETYPE_FLY );
	set_entvar( pEntity, var_owner, pOwner );
	set_entvar( pEntity, var_dmg_inflictor, pInflictor );
	set_entvar( pEntity, var_rendermode, kRenderTransAdd );
	set_entvar( pEntity, var_renderamt, 200.0 );
	set_entvar( pEntity, var_velocity, vecVelocity );
	set_entvar( pEntity, var_velocity_cached, vecVelocity );
	set_entvar( pEntity, var_angles, vecAngles );
	set_entvar( pEntity, var_origin, vecOrigin );
	set_entvar( pEntity, var_startpos, vecOrigin );
	set_entvar( pEntity, var_penetration, 0 );
	set_entvar( pEntity, var_enemy, 0 );
	set_entvar( pEntity, var_charged_shoot, bChargedShoot );
	set_entvar( pEntity, var_beam_index, NULLENT );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );

	engfunc( EngFunc_SetModel, pEntity, ENTITY_ARROW_MODEL );
	engfunc( EngFunc_SetSize, pEntity, Float: { -2.0, -2.0, -2.0 }, Float: { 2.0, 2.0, 2.0 } );

	if ( bChargedShoot )
	{
		new pBeam = Beam_Create( WEAPON_EFFECTS_LIST[ eEffect_ArrowTrail ], 158.0 )
		if ( !is_nullent( pBeam ) )
		{
			Beam_PointEntInit( pBeam, vecOrigin, pEntity );
			Beam_SetScrollRate( pBeam, 32.0 );

			set_entvar( pEntity, var_beam_index, pBeam );
		}
	}
	else
	{
		message_begin_f( MSG_ALL, SVC_TEMPENTITY );
		UTIL_TE_BEAMFOLLOW( pEntity, gl_iszModelIndex[ eEffect_ArrowTrail ], 2, 1, ENTITY_ARROW_TRAIL_COLOR, 255 );
	}

	SetThink( pEntity, "CArrow__Think" );
	SetTouch( pEntity, "CArrow__Touch" );

	return pEntity;
}

public CArrow__Touch( const pEntity, const pTouch )
{
	if ( is_nullent( pEntity ) )
		return;

	new pOwner = get_entvar( pEntity, var_owner );
	if ( is_nullent( pOwner ) )
	{
		CArrow_HideBeam( pEntity );

		UTIL_KillEntity( pEntity );
		return;
	}

	if ( pTouch == pOwner || FClassnameIs( pTouch, ENTITY_ARROW_CLASSNAME ) )
		return;

	new pInflictor = get_entvar( pEntity, var_dmg_inflictor );
	if ( is_nullent( pInflictor ) || !IsCustomWeapon( pInflictor, gl_iAllocString_WeaponUId ) )
	{
		CArrow_HideBeam( pEntity );

		UTIL_KillEntity( pEntity );
		return;
	}

	new Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	new iPointContents = engfunc( EngFunc_PointContents, vecOrigin );
	if ( iPointContents == CONTENTS_SKY )
	{
		CArrow_HideBeam( pEntity );

		UTIL_KillEntity( pEntity );
		return;
	}

	new Vector3( vecVelocity ); get_entvar( pEntity, var_velocity, vecVelocity );
	// new Vector3( vecDirection ); xs_vec_copy( vecVelocity, vecDirection );
	xs_vec_add( vecVelocity, vecOrigin, vecVelocity );

	new pTrace = create_tr2( );
	engfunc( EngFunc_TraceLine, vecOrigin, vecVelocity, DONT_IGNORE_MONSTERS, pEntity, pTrace );

	new iPenetration = get_entvar( pEntity, var_penetration );
	new bool: bChargedShoot = get_entvar( pEntity, var_charged_shoot );
	new Float: flDamage = bChargedShoot ? WEAPON_DAMAGE_EX : WEAPON_DAMAGE;

	new Vector3( vecEndPos ); get_tr2( pTrace, TR_vecEndPos, vecEndPos );

	if ( !is_user_alive( pTouch ) )
	{
		new Vector3( vecPlaneNormal ); get_tr2( pTrace, TR_vecPlaneNormal, vecPlaneNormal );
		UTIL_HitWallEffects( pTouch, vecEndPos, true, vecPlaneNormal );

		if ( !bChargedShoot || bChargedShoot && iPenetration >= ENTITY_ARROW_MAX_PENETRATION )
		{
			set_entvar( pEntity, var_solid, SOLID_NOT );
			set_entvar( pEntity, var_movetype, MOVETYPE_NONE );
			set_entvar( pEntity, var_nextthink, get_gametime( ) + ENTITY_ARROW_DESTROY_TIME );
		}
		else if ( bChargedShoot )
		{
			if ( iPointContents != CONTENTS_SOLID )
			{
				rh_emit_sound2( pEntity, 0, CHAN_ITEM, WEAPON_SOUNDS[ 2 ] );

				message_begin_f( MSG_PVS, SVC_TEMPENTITY, vecOrigin );
				UTIL_TE_EXPLOSION( gl_iszModelIndex[ eEffect_Explosion ], vecOrigin, 0.0, 8, 16 );
			}

			set_entvar( pEntity, var_penetration, ++iPenetration );
			set_entvar( pEntity, var_movetype, MOVETYPE_NOCLIP );
			set_entvar( pEntity, var_nextthink, get_gametime( ) );
		}
	}
	else if ( is_user_alive( pTouch ) && !bChargedShoot )
	{
		if ( get_member( pTouch, m_iTeam ) != get_member( pOwner, m_iTeam ) )
		{
			new Float: flFrame = -1.0;
			new pCounter = NULLENT; rg_find_ent_by_owner( pCounter, ENTITY_COUNTER_CLASSNAME, pTouch );

			if ( is_nullent( pCounter ) )
				pCounter = CCounter__SpawnEntity( pTouch );
			else
			{
				flFrame = get_entvar( pCounter, var_frame );

				set_entvar( pCounter, var_ltime, get_gametime( ) + ENTITY_COUNTER_LIFETIME );
				set_entvar( pCounter, var_frame, flFrame >= 4.0 ? 0.0 : flFrame + 1.0 );
			}

			flDamage += WEAPON_DAMAGE_ADD * ( flFrame + 1.0 );
		}
	}

	new bitsVictims = get_entvar( pEntity, var_enemy );
	if ( !BIT_VALID( bitsVictims, pTouch ) )
	{
		rg_multidmg_clear( );
		ExecuteHamB( Ham_TraceAttack, pTouch, pOwner, flDamage, NULL_VECTOR, pTrace, WEAPON_DMGTYPE );
		rg_multidmg_apply( pInflictor, pOwner );

		if ( is_user_alive( pTouch ) )
		{
			if ( bChargedShoot )
			{
				rh_emit_sound2( pEntity, 0, CHAN_ITEM, WEAPON_SOUNDS[ 2 ] );

				message_begin_f( MSG_PVS, SVC_TEMPENTITY, vecOrigin );
				UTIL_TE_EXPLOSION( gl_iszModelIndex[ eEffect_Explosion ], vecOrigin, 0.0, 8, 16 );

				BIT_ADD( bitsVictims, pTouch );
				set_entvar( pEntity, var_enemy, bitsVictims );
			}
			else
			{
				CArrow_HideBeam( pEntity );
				UTIL_KillEntity( pEntity );
			}
		}
	}

	free_tr2( pTrace );
}

public CArrow__Think( const pEntity )
{
	if ( is_nullent( pEntity ) )
		return;

	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	static Vector3( vecStartPos ); get_entvar( pEntity, var_startpos, vecStartPos );
	static iPointContents; iPointContents = engfunc( EngFunc_PointContents, vecOrigin );

	if ( xs_vec_distance( vecOrigin, vecStartPos ) >= 3072.0 || iPointContents == CONTENTS_SKY )
	{
		CArrow_HideBeam( pEntity );

		UTIL_KillEntity( pEntity );
		return;
	}

	switch ( get_entvar( pEntity, var_movetype ) )
	{
		case MOVETYPE_NONE:
		{
			CArrow_HideBeam( pEntity );

			UTIL_KillEntity( pEntity );
			return;
		}
		case MOVETYPE_NOCLIP:
		{
			static Vector3( vecVelocity ); get_entvar( pEntity, var_velocity_cached, vecVelocity );
			set_entvar( pEntity, var_velocity, vecVelocity );

			if ( !UTIL_IsHullVacant( pEntity, vecOrigin, HULL_HUMAN ) )
				set_entvar( pEntity, var_movetype, MOVETYPE_FLY );
		}
	}

	set_entvar( pEntity, var_nextthink, get_gametime( ) + 0.1 );
}

public CArrow_HideBeam( const pEntity )
{
	if ( is_nullent( pEntity ) || !get_entvar( pEntity, var_beam_index ) )
		return;

	static pBeam; pBeam = get_entvar( pEntity, var_beam_index );
	if ( !is_nullent( pBeam ) )
	{
		set_entvar( pBeam, var_nextthink, get_gametime( ) );
		SetThink( pBeam, "CBeam__Think" );
	}
}

public CBeam__Think( const pBeam )
{
	if ( is_nullent( pBeam ) )
		return;

	static Float: flBrightness; flBrightness = Beam_GetBrightness( pBeam );
	if ( ( flBrightness -= 20.0 ) && flBrightness < 20.0 )
	{
		UTIL_KillEntity( pBeam );
		return;
	}

	Beam_SetBrightness( pBeam, flBrightness );
	set_entvar( pBeam, var_nextthink, get_gametime( ) + 0.075 );
}

public CCounter__SpawnEntity( const pVictim )
{
	new pEntity = rg_create_entity( ENTITY_COUNTER_REFERENCE );

	if ( is_nullent( pEntity ) )
		return false;

	new Vector3( vecOrigin ); get_entvar( pVictim, var_origin, vecOrigin );

	set_entvar( pEntity, var_classname, ENTITY_COUNTER_CLASSNAME );
	set_entvar( pEntity, var_movetype, MOVETYPE_FOLLOW );
	set_entvar( pEntity, var_solid, SOLID_NOT );
	set_entvar( pEntity, var_frame, 0.0 );
	set_entvar( pEntity, var_scale, 0.5 );
	set_entvar( pEntity, var_owner, pVictim );
	set_entvar( pEntity, var_aiment, pVictim );
	set_entvar( pEntity, var_origin, vecOrigin );
	set_entvar( pEntity, var_rendermode, kRenderTransAdd );
	set_entvar( pEntity, var_renderamt, 255.0 );
	set_entvar( pEntity, var_ltime, get_gametime( ) + ENTITY_COUNTER_LIFETIME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );

	engfunc( EngFunc_SetModel, pEntity, ENTITY_COUNTER_SPRITE );

	SetThink( pEntity, "CCounter__Think" );

	return pEntity;
}

public CCounter__Think( const pEntity )
{
	if ( is_nullent( pEntity ) )
		return;

	if ( get_entvar( pEntity, var_ltime ) < get_gametime( ) )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	new pOwner = get_entvar( pEntity, var_owner );
	if ( !is_user_alive( pOwner ) )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	set_entvar( pEntity, var_nextthink, get_gametime( ) + 0.1 );
}

#if defined CUSTOM_MUZZLEFLASH
	stock UTIL_DrawMuzzleFlash( const pPlayer, const szClassName[ ], const szSprite[ ], const iAttachment = 1, const Float: flScale = 0.05, const Float: flFramerateMlt = 1.0, const Float: flColor[ 3 ] = { 0.0, 0.0, 0.0 }, const Float: flBrightness = 255.0, const bool: bShowOnlyOwner = true )
	{
		if ( !strlen( szSprite ) )
			return NULLENT;

		static iMaxEntities; if ( !iMaxEntities ) iMaxEntities = global_get( glb_maxEntities );
		if ( iMaxEntities - engfunc( EngFunc_NumberOfEntities ) <= LOWER_LIMIT_OF_ENTITIES )
			return NULLENT;

		new pSprite = NULLENT; rg_find_ent_by_owner( pSprite, szClassName, pPlayer );
		if ( is_nullent( pSprite ) )
		{
			if ( ( pSprite = rg_create_entity( ENTITY_MUZZLE_REFERENCE ) ) && is_nullent( pSprite ) )
				return NULLENT;
		}

		new Float: flMaxFrames = float( engfunc( EngFunc_ModelFrames, engfunc( EngFunc_ModelIndex, szSprite ) ) );

		set_entvar( pSprite, var_classname, szClassName );
		set_entvar( pSprite, var_spawnflags, SF_SPRITE_ONCE );
		set_entvar( pSprite, var_frame, 0.0 );
		set_entvar( pSprite, var_framerate, flMaxFrames * flFramerateMlt );
		set_entvar( pSprite, var_max_frame, flMaxFrames );
		set_entvar( pSprite, var_rendermode, kRenderTransAdd );
		set_entvar( pSprite, var_rendercolor, flColor );
		set_entvar( pSprite, var_renderamt, flBrightness );
		set_entvar( pSprite, var_scale, flScale );
		set_entvar( pSprite, var_owner, pPlayer );
		set_entvar( pSprite, var_aiment, pPlayer );
		set_entvar( pSprite, var_body, iAttachment );
		set_entvar( pSprite, var_last_time, get_gametime( ) );

		if ( bShowOnlyOwner )
			set_entvar( pSprite, var_effects, EF_FORCEVISIBILITY | EF_OWNER_VISIBILITY );
		
		engfunc( EngFunc_SetModel, pSprite, szSprite );

		if ( flFramerateMlt )
			SetThink( pSprite, "CMuzzleFlash__Think" );

		return pSprite;
	}

	public CMuzzleFlash__Think( const pSprite )
	{
		if ( is_nullent( pSprite ) )
			return;

		static Float: flFrame; flFrame = get_entvar( pSprite, var_frame );
		static Float: flFrameRate; flFrameRate = get_entvar( pSprite, var_framerate );
		static Float: flLastTime; flLastTime = get_entvar( pSprite, var_last_time );
		static Float: flGameTime; flGameTime = get_gametime( );

		flFrame += ( flFrameRate * ( flGameTime - flLastTime ) );
		set_entvar( pSprite, var_frame, flFrame );

		if ( flFrame > get_entvar( pSprite, var_max_frame ) )
		{
			UTIL_KillEntity( pSprite );
			return;
		}

		set_entvar( pSprite, var_last_time, flGameTime );
		set_entvar( pSprite, var_nextthink, flGameTime + ENTITY_MUZZLE_NEXTTHINK );
	}
#endif

/* ~ [ Stocks ] ~ */

/* -> Weapon Animation <- */
stock UTIL_SendWeaponAnim( const iDest, const pPlayer, const iAnim, const iBody = 0 ) 
{
	set_entvar( pPlayer, var_weaponanim, iAnim );

	message_begin( iDest, SVC_WEAPONANIM, .player = pPlayer );
	write_byte( iAnim );
	write_byte( iBody );
	message_end( );

	if ( iBody )
	{
		static i, iCount, pSpectator, iszSpectators[ MAX_PLAYERS ];

		if ( get_entvar( pPlayer, var_iuser1 ) )
			return;

		get_players( iszSpectators, iCount, "bch" );

		for ( i = 0; i < iCount; i++ )
		{
			pSpectator = iszSpectators[ i ];

			if ( get_entvar( pSpectator, var_iuser1 ) != OBS_IN_EYE )
				continue;

			if ( get_entvar( pSpectator, var_iuser2 ) != pPlayer )
				continue;

			set_entvar( pSpectator, var_weaponanim, iAnim );

			message_begin( iDest, SVC_WEAPONANIM, .player = pSpectator );
			write_byte( iAnim );
			write_byte( iBody );
			message_end( );
		}
	}
}

/* -> Set weapon time offsets <- */
stock UTIL_WeaponSetTiming( const pPlayer, const pItem, const Float: flWeaponTime, const Float: flNextAttack = 0.0 )
{
	set_member( pPlayer, m_flNextAttack, ( !flNextAttack ? flWeaponTime : flNextAttack ) + 0.01 );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flWeaponTime );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, flWeaponTime );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, flWeaponTime );
}

/* -> Get Player Weapon Ammo <- */
stock GetPlayerWeaponAmmo( const pPlayer, const pItem, &iAmmo, &iAmmoType )
{
	iAmmoType = GetWeaponAmmoType( pItem );
	iAmmo = GetWeaponAmmo( pPlayer, iAmmoType );

	return true;
}

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity ) 
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );

	SetTouch( pEntity, "" );
	SetThink( pEntity, "" );
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

/* -> Check entity is stuck <- */
stock bool: UTIL_IsHullVacant( const pPlayer, const Vector3( vecOrigin ), const pHull )
{
	engfunc( EngFunc_TraceHull, vecOrigin, vecOrigin, 0, pHull, pPlayer, 0 );
 	if ( get_tr2( 0, TR_StartSolid ) || get_tr2( 0, TR_AllSolid ) || !get_tr2( 0, TR_InOpen ) )
		return false;

	return true;
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

/* -> Reset CHAN_WEAPON sound <- */
stock UTIL_ResetTimingSound( const pPlayer, const pItem )
{
	set_entvar( pItem, var_next_sound, get_gametime( ) );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, "common/null.wav" );
}

/* -> Play sound with timing <- */
stock UTIL_PlayTimingSound( const pPlayer, const pItem, const szSound[ ], const iChannel, const Float: flSoundTime )
{
	static Float: flGameTime; flGameTime = get_gametime( );
	if ( get_entvar( pItem, var_next_sound ) < flGameTime )
	{
		rh_emit_sound2( pPlayer, 0, iChannel, szSound );
		set_entvar( pItem, var_next_sound, flGameTime + flSoundTime );
	}
}

/* -> The target is behind the wall <- */
stock bool: UTIL_IsWallBetweenPoints( const pPlayer, const pTarget )
{
	if ( is_nullent( pPlayer) || is_nullent( pTarget ) )
		return false;

	new pTrace = create_tr2( );
	new Float: vecStart[ 3 ], Float: vecEnd[ 3 ], Float: vecEndPos[ 3 ];

	pev( pPlayer, pev_origin, vecStart );
	pev( pTarget, pev_origin, vecEnd );

	engfunc( EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, pPlayer, pTrace );
	get_tr2( pTrace, TR_vecEndPos, vecEndPos );

	free_tr2( pTrace );

	return xs_vec_equal( vecEnd, vecEndPos );
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

/* -> Weapon List <- */
stock UTIL_WeaponList( const iDest, const pPlayer, const pItem, szWeaponName[ MAX_NAME_LENGTH ] = "", const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
{
	if ( szWeaponName[ 0 ] == EOS )
		rg_get_iteminfo( pItem, ItemInfo_pszName, szWeaponName, charsmax( szWeaponName ) )

	static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

	message_begin( iDest, iMsgId_Weaponlist, .player = pPlayer );
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

/* -> Cur Weapon <- */
stock UTIL_CurWeapon( const iDest, const pPlayer, const bool: bIsActive, const iWeaponId, const iClipAmmo )
{
	static iMsgId_CurWeapon; if ( !iMsgId_CurWeapon ) iMsgId_CurWeapon = get_user_msgid( "CurWeapon" );

	message_begin( iDest, iMsgId_CurWeapon, .player = pPlayer );
	write_byte( bIsActive );
	write_byte( iWeaponId );
	write_byte( iClipAmmo );
	message_end( );
}

/* -> All default hit wall effects <- */
stock UTIL_HitWallEffects( const pEntity, const Vector3( vecOrigin ), const bool: bSparks = true, Vector3( vecDirection ) = { 0.0, 0.0, 0.0 }, const iColor = 4 )
{
	if ( pEntity && is_nullent( pEntity ) || ( get_entvar( pEntity, var_flags ) & FL_KILLME ) || !ExecuteHam( Ham_IsBSPModel, pEntity ) )
		return;

	UTIL_GunshotDecalTrace( pEntity, vecOrigin );

	if ( bSparks && engfunc( EngFunc_PointContents, vecOrigin ) != CONTENTS_WATER )
	{
		xs_vec_mul_scalar( vecDirection, random_float( 25.0, 30.0 ), vecDirection );
		message_begin_f( MSG_PAS, SVC_TEMPENTITY, vecOrigin );
		UTIL_TE_STREAK_SPLASH( vecOrigin, vecDirection, iColor, random_num( 10, 20 ), 3, 64 );
	}
}

/* -> TE_BEAMPOINTS <- */
stock UTIL_TE_BEAMPOINTS( Vector3( vecStart ), Vector3( vecEnd ), const iszModelIndex, const iStartFrame, const iFrameRate, const iLife, const iWidth, const iNoise, const iColor[ 3 ], const iBrightness, const iScroll )
{
	write_byte( TE_BEAMPOINTS );
	write_coord_f( vecStart[ 0 ] );
	write_coord_f( vecStart[ 1 ] );
	write_coord_f( vecStart[ 2 ] );
	write_coord_f( vecEnd[ 0 ] );
	write_coord_f( vecEnd[ 1 ] );
	write_coord_f( vecEnd[ 2 ] );
	write_short( iszModelIndex ); // Model Index
	write_byte( iStartFrame ); // Start Frame
	write_byte( iFrameRate ); // FrameRate
	write_byte( iLife ); // File in 0.1's
	write_byte( iWidth ); // Line width in 0.1's
	write_byte( iNoise ); // Noise
	write_byte( iColor[ 0 ] ); // Red
	write_byte( iColor[ 1 ] ); // Green
	write_byte( iColor[ 2 ] ); // Blue
	write_byte( iBrightness ); // Brightness
	write_byte( iScroll ); // Scroll speed in 0.1's
	message_end();
}

/* -> TE_BEAMFOLLOW <- */
stock UTIL_TE_BEAMFOLLOW( const pEntity, const iszModelIndex, const iLife, const iWidth, const iColor[ 3 ], const iBrightness )
{
	write_byte( TE_BEAMFOLLOW );
	write_short( pEntity ); // Entity: attachment to follow
	write_short( iszModelIndex ); // Model Index
	write_byte( iLife ); // Life in 0.1's
	write_byte( iWidth ); // Line width in 0.1's
	write_byte( iColor[ 0 ] ); // Red
	write_byte( iColor[ 1 ] ); // Green
	write_byte( iColor[ 2 ] ); // Blue
	write_byte( iBrightness ); // Brightness
	message_end( );
}

/* -> TE_GUNSHOTDECAL <- */
stock UTIL_TE_EXPLOSION( const iszModelIndex, const Vector3( vecOrigin ), const Float: flUp, const iScale, const iFramerate, const iFlags = TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES )
{
	write_byte( TE_EXPLOSION );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] + flUp );
	write_short( iszModelIndex );
	write_byte( iScale ); // Scale
	write_byte( iFramerate ); // Framerate
	write_byte( iFlags ); // Flags
	message_end( );
}

/* -> TE_STREAK_SPLASH <- */
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

/* -> TE_GUNSHOTDECAL <- */
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
