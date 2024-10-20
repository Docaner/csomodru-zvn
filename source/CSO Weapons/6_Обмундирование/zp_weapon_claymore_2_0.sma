new const PluginName[ ] =					"[ZP] Weapon: Claymore Mine MDS";
new const PluginVersion[ ] =				"2.0";
new const PluginAuthor[ ] =					"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <xs>
#include <smart_effects>

// If you are not using ReAPI, delete or comment out this line.
#include <reapi>

/**
 * Automatically precache sounds from the model
 * 
 * If you have ReHLDS installed, you do not need this setting with a server cvar
 * `sv_auto_precache_sounds_in_models 1`
 */
// #define PrecacheSoundsFromModel

/* ~ [ Extra-Items ] ~ */
new const ExtraItem_Name[ ] =					"Claymore Mine MDS";
const ExtraItem_Cost =							0;

/* ~ [ Weapon Settings ] ~ */
/**
 * Use the creation of sprite effects when exploding using Entity
 * Otherwise, TE_EXPLOSION message will be used
 */
// #define UseEffectSpritesByEntity

/**
 * Use changing hands for v_ model
 * NB! Can use more server resources (CPU, RAM)
 * 
 * Comment 'EnableSubmodelSupport' if you don't use third-party arm body for the v_ model
 */
// #define EnableSubmodelSupport
#if defined EnableSubmodelSupport
	const WeaponHandSubmodel =					0; // Hand Submodel (0: Male / 1: Female)
#endif
const WeaponUnicalIndex =						27092022;
new const WeaponNative[ ] =						"zp_give_user_claymore";
new const WeaponReference[ ] =					"weapon_c4";
new const WeaponAnimation[ ][ ] = {
	"c4", // Claymore
	"knife" // Trigger
};
// Comment 'WeaponListDir' if u don't need custom weapon list
new const WeaponListDir[ ] =					"x_re/weapon_claymore";
new const WeaponViewModel[ ] =					"models/x_re/v_claymore.mdl";
new const WeaponPlayerModel[ ][ ] = {
	"models/x_re/p_claymore.mdl",
	"models/x_re/p_claymore_trigger.mdl"
};
new const WeaponWorldModel[ ] =					"models/x_re/w_claymore.mdl";
new const WeaponSounds[ ][ ] = {
	"weapons/claymore_exp.wav"
};
new const WeaponEffectSprites[ ][ ] = {
	"sprites/x_re/claymore_explosion1.spr",
	"sprites/x_re/claymore_explosion2.spr",
	"sprites/x_re/claymore_explosion3.spr"
};

/**
 * After what time will the mode of the delivered mine change
 */
const Float: WeaponSwitchTriggetTime =			0.75;

/**
 * After what time does the mine detonate after pressing the button
 */
const Float: WeaponActivateDetonate =			0.5;

/**
 * The radius in which it will cause damage to all enemies
 */
const Float: WeaponDetonateRadius =				200.0;

/**
 * The radius in which the players will shake the screen (including allies)
 */
const Float: WeaponDetonateShakeRadius =		500.0;
const Float: WeaponDetonateDamage =				3500.0;

#if !defined DMG_GRENADE
	#define DMG_GRENADE							(1<<24)
#endif

/**
 * DMG_GRENADE - the victim are not stopped on the spot when dealing damage
 * DMG_BULLET - the victim stops on the spot when dealing damage
 * DMG_ALWAYSGIB - after death, the victim is torn to pieces
 * DMG_NEVERGIB - after death, the victim is not torn to pieces
 */
const WeaponDetonateDamageType =				( DMG_GRENADE|DMG_ALWAYSGIB );

/* ~ [ Entity: Claymore ] ~ */
new const EntityClaymoreReference[ ] =			"info_target";
new const EntityClaymoreClassName[ ] =			"ent_claymore_x";

/* ~ [ Entity: Claymore Laser ] ~ */
new const EntityClaymoreLaserClassName[ ] =		"ent_claymore_laser_x";

/**
 * The radius of automatic mine activation
 */
const Float: EntityClaymoreLaserRadius =		64.0;

#if defined UseEffectSpritesByEntity
	/* ~ [ Entity: Effect Sprites ] ~ */
	new const EntityEffectReference[ ] =		"env_sprite";
	new const EntityEffectClassName[ ] =		"ent_claymore_eff_x";
	/**
	 * Update time of the sprite effect animation
	 */
	const Float: EntityEffectNextThink =		0.02;
#endif

/* ~ [ Weapon Anims ] ~ */
enum {
	WeaponAnim_Dummy = 0,
	WeaponAnim_Idle,
	WeaponAnim_Put,
	WeaponAnim_Draw,
	WeaponAnim_Idle_On,
	WeaponAnim_Idle_Off,
	WeaponAnim_Trigger_On,
	WeaponAnim_Trigger_Off,
	WeaponAnim_Launch_On,
	WeaponAnim_Launch_Off,
	WeaponAnim_Draw_On,
	WeaponAnim_Draw_Off
};

const Float: WeaponAnim_Idle_Time =			1.7;
const Float: WeaponAnim_Idle_OnOff_Time =	2.0;
const Float: WeaponAnim_Draw_Time =			1.0;
const Float: WeaponAnim_Put_Time =			1.4;
const Float: WeaponAnim_Launch_Time =		1.2;
const Float: WeaponAnim_Trigger_Time =		1.0;

/* ~ [ Params ] ~ */
new gl_iItemId;
new gl_iszModelIndex[ sizeof WeaponEffectSprites ];
#if defined UseEffectSpritesByEntity
	new Float: gl_flSpritesMaxFrames[ sizeof WeaponEffectSprites ];
#endif

enum ( <<= 1 ) {
	WeaponState_OnTrigger = 1,
	WeaponState_TriggerActive,
	WeaponState_SwitchTrigger, 

	WeaponState_PutMine,
	WeaponState_LaunchMine
};

enum {
	Sound_Explode = 0
};

enum {
	SpriteEffect_Explode1 = 0,
	SpriteEffect_Explode2,
	SpriteEffect_Explode3
};

	enum {
		ClaymoreState_Idle = 0,
		ClaymoreState_Detonate,
		ClaymoreState_Destroy
	}

	#define var_mine_state					var_iuser1 // CEntity: info_target
#endif

/* ~ [ Macroses ] ~ */
#if AMXX_VERSION_NUM <= 182
	#define OBS_IN_EYE						4

	#define write_coord_f(%0)				engfunc( EngFunc_WriteCoord, %0 )
	stock message_begin_f( const iDest, const iMsgType, const Float: vecOrigin[ 3 ] = { 0.0, 0.0, 0.0 }, const pReceiver = 0 )
		engfunc( EngFunc_MessageBegin, iDest, iMsgType, vecOrigin, pReceiver );
#endif

#define BIT_ADD(%0,%1)						( %0 |= %1 )
#define BIT_SUB(%0,%1)						( %0 &= ~%1 )
#define BIT_VALID(%0,%1)					( %0 & %1 )
#define BIT_VALID_BOOL(%0,%1)				( ( %0 & %1 ) ? true : false )
#define BIT_INVERT(%0,%1)					( %0 ^= %1 )

#if !defined Vector3
	#define Vector3(%0)						Float: %0[ 3 ]
#endif
#define IsCustomWeapon(%0,%1)				bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponState(%0)					get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)				set_member( %0, m_Weapon_iWeaponState, %1 )
#define GetWeaponAmmoType(%0)				get_member( %0, m_Weapon_iPrimaryAmmoType )
#define FixedUnsigned16(%0,%1)				clamp( floatround( %0 * %1 ), 0, 0xFFFF )

#define WeaponOnTriggerMode(%0)				BIT_VALID( %0, WeaponState_OnTrigger )
#define WeaponOnActivedTrigger(%0)			BIT_VALID( %0, WeaponState_TriggerActive )
#define WeaponOnActivate(%0)				( BIT_VALID( %0, WeaponState_PutMine ) || BIT_VALID( %0, WeaponState_LaunchMine ) )

#define var_mine_entity						var_enemy // CWeapon
#define var_laser_entity					var_enemy // CEntity: info_target
#define var_max_frame						var_yaw_speed // CEntity: env_sprite
#define var_last_time						var_pitch_speed // CEntity: env_sprite

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( )
{
	register_native( WeaponNative, "native_give_user_weapon" );
	register_native( "zp_get_user_claymore", "native_get_user_claymore" );
	register_native( "zp_get_claymore_extraid", "native_get_claymore_extraid" );
}

public plugin_precache( )
{
	new i;

	/* -> Precache Models <- */
	engfunc( EngFunc_PrecacheModel, WeaponViewModel );
	engfunc( EngFunc_PrecacheModel, WeaponWorldModel );

	for ( i = 0; i < sizeof WeaponPlayerModel; i++ )
		engfunc( EngFunc_PrecacheModel, WeaponPlayerModel[ i ] );

	/* -> Precache Sounds <- */
	for ( i = 0; i < sizeof WeaponSounds; i++ )
		engfunc( EngFunc_PrecacheSound, WeaponSounds[ i ] );

#if defined PrecacheSoundsFromModel
	UTIL_PrecacheSoundsFromModel( WeaponViewModel );
#endif

#if defined WeaponListDir
	/* -> Precache WeaponList <- */
	UTIL_PrecacheWeaponList( WeaponListDir );

	/* -> Hook Weapon <- */
	register_clcmd( WeaponListDir, "ClientCommand__HookWeapon" );
#endif

	/* -> Model Index <- */
	for ( i = 0; i < sizeof WeaponEffectSprites; i++ )
	{
		gl_iszModelIndex[ i ] = engfunc( EngFunc_PrecacheModel, WeaponEffectSprites[ i ] );
	#if defined UseEffectSpritesByEntity
		gl_flSpritesMaxFrames[ i ] = float( engfunc( EngFunc_ModelFrames, gl_iszModelIndex[ i ] ) );
	#endif
	}
}

public plugin_init( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

	/* -> Fakemeta <- */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

#if defined _reapi_included
	/* -> ReGameDLL <- */
	RegisterHookChain( RG_CSGameRules_CleanUpMap, "RG_CSGameRules_CleanUpMap_Post", true );
#else
	/* -> Events <- */
	register_event( "HLTV", "EV_RoundStart", "a", "1=0", "2=0" );
#endif

	/* -> HamSandwich: Weapon <- */
	RegisterHam( Ham_CS_Item_CanDrop, WeaponReference, "Ham_Weapon_CanDrop_Pre", false );
	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_Weapon_Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_Weapon_Holster_Post", true );
	RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_Weapon_PostFrame_Pre", false );
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Ham_Weapon_AddToPlayer_Post", true );
	RegisterHam( Ham_Weapon_WeaponIdle, WeaponReference, "Ham_Weapon_WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_Weapon_PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_Weapon_SecondaryAttack_Pre", false );

#if !defined _reapi_included
	/* -> HamSandwich: Entity <- */
	#if defined UseEffectSpritesByEntity
		RegisterHam( Ham_Think, EntityEffectReference, "Ham_Sprite_Think_Post", true );
	#endif
	RegisterHam( Ham_Think, EntityClaymoreReference, "Ham_InfoTarget_Think_Post", true );
	RegisterHam( Ham_Touch, EntityClaymoreReference, "Ham_InfoTarget_Touch_Post", true );
#endif

	/* -> Register on Extra-Items <- */
	gl_iItemId = zp_register_extra_item( ExtraItem_Name, ExtraItem_Cost, ZP_TEAM_HUMAN );

	/* -> Other <- */
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

	return CBasePlayer__GiveClaymore( pPlayer ) ? PLUGIN_CONTINUE : ZP_PLUGIN_HANDLED;
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
#if !defined EnableSubmodelSupport
	if ( !is_user_alive( pPlayer ) )
		return;

	static pActiveItem; pActiveItem = get_member( pPlayer, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
		return;

	set_cd( CD_Handle, CD_flNextAttack, 2.0 );
#else
	static iSpecMode, pTarget;
	pTarget = ( iSpecMode = get_entvar( pPlayer, var_iuser1 ) ) ? get_entvar( pPlayer, var_iuser2 ) : pPlayer;

	if ( !is_user_connected( pTarget ) )
		return;

	static pActiveItem; pActiveItem = get_member( pTarget, m_pActiveItem );
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
		static bitsWeaponState; bitsWeaponState = GetWeaponState( pActiveItem );

		UTIL_SendWeaponAnim( MSG_ONE, pTarget, pActiveItem, 
			WeaponOnTriggerMode( bitsWeaponState ) ? ( WeaponOnActivedTrigger( bitsWeaponState ) ? WeaponAnim_Draw_On : WeaponAnim_Draw_Off ) : WeaponAnim_Draw
		);
		set_member( pActiveItem, m_flLastEventCheck, 0.0 );
	}
#endif
}

#if defined _reapi_included
	/* ~ [ ReGameDLL ] ~ */
	public RG_CSGameRules_CleanUpMap_Post( )
	{
		static pEntity, pInflictor; pEntity = pInflictor = NULLENT;
		while ( ( pEntity = fm_find_ent_by_class( pEntity, EntityClaymoreClassName ) ) > 0 )
		{
			pInflictor = get_entvar( pEntity, var_dmg_inflictor );
			if ( !is_nullent( pInflictor ) && IsCustomWeapon( pInflictor, WeaponUnicalIndex ) )
				SetWeaponState( pInflictor, 0 );

			CClaymore__Destroy( pEntity );
		}
	}
#else
	/* ~ [ Events ] ~ */
	public EV_RoundStart( )
	{
		static pEntity, pInflictor; pEntity = pInflictor = NULLENT;
		while ( ( pEntity = fm_find_ent_by_class( pEntity, EntityClaymoreClassName ) ) > 0 )
		{
			pInflictor = get_entvar( pEntity, var_dmg_inflictor );
			if ( !is_nullent( pInflictor ) && IsCustomWeapon( pInflictor, WeaponUnicalIndex ) )
				SetWeaponState( pInflictor, 0 );

			CClaymore__Destroy( pEntity );
		}
	}
#endif

/* ~ [ HamSandwich ] ~ */
public Ham_Weapon_CanDrop_Pre( const pItem ) return IsCustomWeapon( pItem, WeaponUnicalIndex ) ? HAM_SUPERCEDE : HAM_IGNORED;

public Ham_Weapon_Deploy_Post( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem ); 

	set_entvar( pPlayer, var_viewmodel, WeaponViewModel );
	set_entvar( pPlayer, var_weaponmodel, WeaponPlayerModel[ WeaponOnTriggerMode( bitsWeaponState ) ] );

#if defined EnableSubmodelSupport
	set_entvar( pItem, var_body, WeaponHandSubmodel );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Dummy );

	set_member( pItem, m_flLastEventCheck, get_gametime( ) + 0.1 );
#else
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, 
		WeaponOnTriggerMode( bitsWeaponState ) ? ( WeaponOnActivedTrigger( bitsWeaponState ) ? WeaponAnim_Draw_On : WeaponAnim_Draw_Off ) : WeaponAnim_Draw
	);
#endif

	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Draw_Time + 0.1 );
	set_member( pPlayer, m_flNextAttack, Float: WeaponAnim_Draw_Time );
#if defined _reapi_included
	set_member( pPlayer, m_szAnimExtention, WeaponAnimation[ WeaponOnTriggerMode( bitsWeaponState ) ] );
#else
	set_pdata_string( pPlayer, m_szAnimExtention * 4, WeaponAnimation[ WeaponOnTriggerMode( bitsWeaponState ) ], -1, linux_diff_player * linux_diff_animating );
#endif
}

public Ham_Weapon_Holster_Post( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );

	BIT_SUB( bitsWeaponState, WeaponState_PutMine );
	BIT_SUB( bitsWeaponState, WeaponState_LaunchMine );
	BIT_SUB( bitsWeaponState, WeaponState_SwitchTrigger );

	SetWeaponState( pItem, bitsWeaponState );

	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

public Ham_Weapon_PostFrame_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static bitsWeaponState;
	if ( ( bitsWeaponState = GetWeaponState( pItem ) ) )
	{
		static pPlayer; pPlayer = get_member( pItem, m_pPlayer );

	#if !defined _reapi_included
		if ( WeaponOnTriggerMode( bitsWeaponState ) )
		{
			static bitsButton;
			if ( ( bitsButton = get_entvar( pPlayer, var_button ) ) && ( bitsButton & IN_ATTACK2 ) && Float: get_member( pItem, m_Weapon_flNextSecondaryAttack ) < 0.0 )
			{
				ExecuteHamB( Ham_Weapon_SecondaryAttack, pItem );
				set_entvar( pPlayer, var_button, bitsButton & ~IN_ATTACK2 );
			}
		}
	#endif

		if ( BIT_VALID( bitsWeaponState, WeaponState_LaunchMine ) )
		{
			UTIL_StripWeaponByIndex( pPlayer, pItem );
		}
		else if ( BIT_VALID( bitsWeaponState, WeaponState_PutMine ) )
		{
			set_entvar( pItem, var_mine_entity, CClaymore__SpawnEntity( pPlayer, pItem ) );

			BIT_ADD( bitsWeaponState, WeaponState_OnTrigger );
			BIT_SUB( bitsWeaponState, WeaponState_PutMine );
			SetWeaponState( pItem, bitsWeaponState );

		#if defined _reapi_included
			set_member( pItem, m_Weapon_bHasSecondaryAttack, true );
		#endif
			set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponAnim_Draw_Time );
			set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponAnim_Draw_Time );

			ExecuteHamB( Ham_Item_Deploy, pItem );
		}
		else if ( BIT_VALID( bitsWeaponState, WeaponState_SwitchTrigger ) )
		{
			BIT_SUB( bitsWeaponState, WeaponState_SwitchTrigger );
			BIT_INVERT( bitsWeaponState, WeaponState_TriggerActive );

			SetWeaponState( pItem, bitsWeaponState );

			static pClaymore; pClaymore = get_entvar( pItem, var_mine_entity );
			if ( !is_nullent( pClaymore ) )
				CClaymore__UpdateState( pClaymore, BIT_VALID_BOOL( bitsWeaponState, WeaponState_TriggerActive ) );
		}
	}

	return HAM_IGNORED;
}

public Ham_Weapon_AddToPlayer_Post( const pItem, const pPlayer )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	if ( get_entvar( pItem, var_owner ) == -1 )
	{
	#if defined _reapi_included
		#if defined WeaponListDir
			rg_set_iteminfo( pItem, ItemInfo_pszName, WeaponListDir );
		#endif
		set_member( pItem, m_Weapon_bHasSecondaryAttack, false );
	#endif
		set_entvar( pItem, var_mine_entity, NULLENT );
	}

#if defined WeaponListDir
	#if defined _reapi_included
		UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
	#else
		UTIL_WeaponList( MSG_ONE, pPlayer, WeaponListDir );
	#endif
#endif
}

public Ham_Weapon_WeaponIdle_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( Float: get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );

	UTIL_SendWeaponAnim( MSG_ONE, get_member( pItem, m_pPlayer ), pItem,
		WeaponOnTriggerMode( bitsWeaponState ) ? ( WeaponOnActivedTrigger( bitsWeaponState ) ? WeaponAnim_Idle_On : WeaponAnim_Idle_Off ) : WeaponAnim_Idle
	);
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponOnTriggerMode( bitsWeaponState ) ? WeaponAnim_Idle_OnOff_Time : WeaponAnim_Idle_Time );

	return HAM_SUPERCEDE;
}

public Ham_Weapon_PrimaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	if ( WeaponOnActivate( bitsWeaponState ) )
		return HAM_SUPERCEDE;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	static iAnim, Float: flAnimTime;

	if ( WeaponOnTriggerMode( bitsWeaponState ) )
	{
		static pClaymore; pClaymore = get_entvar( pItem, var_mine_entity );
		if ( !is_nullent( pClaymore ) )
		{
		#if defined _reapi_included
			SetThink( pClaymore, "CClaymore__ThinkDetonate" );
		#else
			set_entvar( pClaymore, var_mine_state, ClaymoreState_Detonate );
		#endif
			set_entvar( pClaymore, var_nextthink, get_gametime( ) + Float: WeaponActivateDetonate );
		}

		iAnim = WeaponOnActivedTrigger( bitsWeaponState ) ? WeaponAnim_Launch_On : WeaponAnim_Launch_Off;
		flAnimTime = WeaponAnim_Launch_Time;
		BIT_ADD( bitsWeaponState, WeaponState_LaunchMine );
	}
	else
	{
		iAnim = WeaponAnim_Put;
		flAnimTime = WeaponAnim_Put_Time;
		BIT_ADD( bitsWeaponState, WeaponState_PutMine );
	}

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iAnim );

	SetWeaponState( pItem, bitsWeaponState );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flAnimTime );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, flAnimTime );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, flAnimTime );
	set_member( pPlayer, m_flNextAttack, flAnimTime );

	return HAM_SUPERCEDE;
}

public Ham_Weapon_SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	if ( !WeaponOnTriggerMode( bitsWeaponState ) || WeaponOnActivate( bitsWeaponState ) )
		return HAM_SUPERCEDE;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponOnActivedTrigger( bitsWeaponState ) ? WeaponAnim_Trigger_Off : WeaponAnim_Trigger_On );

	BIT_ADD( bitsWeaponState, WeaponState_SwitchTrigger );
	SetWeaponState( pItem, bitsWeaponState );

	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Trigger_Time );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponAnim_Trigger_Time );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponAnim_Trigger_Time );
	set_member( pPlayer, m_flNextAttack, WeaponSwitchTriggetTime );

	return HAM_SUPERCEDE;
}

#if !defined _reapi_included
	#if defined UseEffectSpritesByEntity
		public Ham_Sprite_Think_Post( const pEntity )
		{
			if ( is_nullent( pEntity ) )
				return;

			if ( FClassnameIs( pEntity, EntityEffectClassName ) )
				CClaymoreEffect__Think( pEntity );
		}
	#endif

	public Ham_InfoTarget_Think_Post( const pEntity )
	{
		if ( is_nullent( pEntity ) )
			return;

		if ( FClassnameIs( pEntity, EntityClaymoreClassName ) )
		{
			static iMineState; iMineState = get_entvar( pEntity, var_mine_state );
			if ( iMineState == ClaymoreState_Idle )
				return;

			if ( iMineState == ClaymoreState_Detonate )
				CClaymore__ThinkDetonate( pEntity );
			else if ( iMineState == ClaymoreState_Destroy )
				CClaymore__ThinkDestroy( pEntity );
		}
	}

	public Ham_InfoTarget_Touch_Post( const pEntity, const pTouch )
	{
		if ( is_nullent( pEntity ) )
			return;

		if ( FClassnameIs( pEntity, EntityClaymoreLaserClassName ) )
			CClaymoreLaser__Touch( pEntity, pTouch );
	}
#endif

/* ~ [ Other ] ~ */
public bool: CBasePlayer__GiveClaymore( const pPlayer )
{
	if ( !is_user_alive( pPlayer ) )
		return false;

	new pItem = get_member( pPlayer, m_rgpPlayerItems, C4_SLOT );
	if ( is_nullent( pItem ) )
	{
		pItem = rg_give_custom_item( pPlayer, WeaponReference, GT_REPLACE, WeaponUnicalIndex );
		if ( is_nullent( pItem ) )
			return false;
	}
	else
	{
		if ( IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			client_print( pPlayer, print_center, "*** You already have 'Claymore Mine MDS' ***" );
		else
			client_print( pPlayer, print_center, "*** You already have any weapon in 5'th slot ***" );

		return false;
	}

	return true;
}

public CClaymore__SpawnEntity( const pPlayer, const pInflictor )
{
	new pEntity = rg_create_entity( EntityClaymoreReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	static Vector3( vecOrigin ); UTIL_GetEyePosition( pPlayer, vecOrigin );
	static Vector3( vecAngles ); get_entvar( pPlayer, var_angles, vecAngles );
	static Vector3( vecForward ); angle_vector( vecAngles, ANGLEVECTOR_FORWARD, vecForward );
	static Vector3( vecEndPos ); xs_vec_add_scaled( vecOrigin, vecForward, 50.0, vecEndPos );

	engfunc( EngFunc_TraceLine, vecOrigin, vecEndPos, IGNORE_MONSTERS, pPlayer, 0 );
	get_tr2( 0, TR_vecEndPos, vecEndPos );

	new Float: flFraction; get_tr2( 0, TR_flFraction, flFraction );
	if ( flFraction != 1.0 )
		xs_vec_copy( vecOrigin, vecEndPos );

	UTIL_DropVectorToFloor( vecEndPos );

	engfunc( EngFunc_SetModel, pEntity, WeaponWorldModel );
	engfunc( EngFunc_SetSize, pEntity, Float: { -5.0, -5.0, -1.0 }, Float: { 5.0, 5.0, 5.0 } );
	engfunc( EngFunc_SetOrigin, pEntity, vecEndPos );

	set_entvar( pEntity, var_classname, EntityClaymoreClassName );
	set_entvar( pEntity, var_movetype, MOVETYPE_TOSS );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_dmg_inflictor, pInflictor );
	set_entvar( pEntity, var_body, 0 );

#if !defined _reapi_included
	set_entvar( pEntity, var_mine_state, ClaymoreState_Idle );
#endif

	get_entvar( pEntity, var_origin, vecOrigin );
	xs_vec_add_scaled( vecOrigin, vecForward, EntityClaymoreLaserRadius, vecOrigin );

	set_entvar( pEntity, var_laser_entity, CClaymoreLaser__SpawnEntity( pEntity, vecOrigin ) );

	vecAngles[ 0 ] = vecAngles[ 2 ] = 0.0;
	set_entvar( pEntity, var_angles, vecAngles );

	return pEntity;
}

public CClaymore__ThinkDetonate( const pEntity ) CClaymore__Detonate( pEntity );

public CClaymore__ThinkDestroy( const pEntity )
{
	static pInflictor;
	if ( ( pInflictor = get_entvar( pEntity, var_dmg_inflictor ) ) && !is_nullent( pInflictor ) && IsCustomWeapon( pInflictor, WeaponUnicalIndex ) )
	{
		static pOwner;
		if ( ( pOwner = get_entvar( pEntity, var_owner ) ) && is_user_alive( pOwner ) )
			UTIL_StripWeaponByIndex( pOwner, pInflictor );
	}

	CClaymore__Destroy( pEntity );
}

public CClaymore__UpdateState( const pEntity, const bool: bState )
{
	set_entvar( pEntity, var_body, bState ? 1 : 0 );

	static pLaser; pLaser = get_entvar( pEntity, var_laser_entity );
	if ( !is_nullent( pLaser ) )
		set_entvar( pLaser, var_solid, bState ? SOLID_TRIGGER : SOLID_NOT );
}

public CClaymore__Detonate( const pEntity )
{
	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( !is_user_alive( pOwner ) || zp_get_user_zombie( pOwner ) )
	{
		CClaymore__Destroy( pEntity );
		return;
	}

	static Float: flDistance;
	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	static Vector3( vecTargetOrigin );

	new pVictim = NULLENT;
	while((pVictim = engfunc(EngFunc_FindEntityInSphere, pVictim, vecOrigin, WeaponDetonateRadius)) > 0)
	{
		if ( !is_user_alive( pVictim ) && !IsAliveNPC( pVictim ))
			continue;

		get_entvar( pVictim, var_origin, vecTargetOrigin );
		flDistance = xs_vec_distance( vecOrigin, vecTargetOrigin );
		if ( flDistance <= WeaponDetonateRadius && ( IsPlayer(pVictim) && zp_get_user_zombie( pVictim ) || IsNPC( pVictim ) ) && get_entvar( pVictim, var_takedamage ) != DAMAGE_NO )
		{
			set_member( pVictim, m_LastHitGroup, HIT_GENERIC );
			ExecuteHamB( Ham_TakeDamage, pVictim, pEntity, pOwner, WeaponDetonateDamage * ( 1.0 - floatclamp( flDistance / WeaponDetonateRadius, 0.1, 0.99 ) ), WeaponDetonateDamageType );
		}

		if ( !IsPlayer(pVictim) ||  flDistance >= WeaponDetonateShakeRadius)
			continue;

		UTIL_ScreenShake( MSG_ONE, pVictim, 128.0, 5.0, 128.0 );
	}

	rh_emit_sound2( pEntity, 0, CHAN_ITEM, WeaponSounds[ Sound_Explode ] );
	UTIL_TE_WORLDDECAL( MSG_BROADCAST, "{scorch1", vecOrigin );

#if defined UseEffectSpritesByEntity
	// Origin, Effect Sprite, Z axis up, Scale, Lifetime
	CClaymoreEffect__SpawnEntity( vecOrigin, SpriteEffect_Explode1, 128.0, 2.0, 3.0 );
	CClaymoreEffect__SpawnEntity( vecOrigin, SpriteEffect_Explode2, 350.0, 3.0, 2.0 );
	CClaymoreEffect__SpawnEntity( vecOrigin, SpriteEffect_Explode3, 350.0, 3.0, 1.0 );
#else
	// Message Dest, Model Index (Sprite), Origin, Z axis up, Scale, FrameRate
	UTIL_TE_EXPLOSION( MSG_BROADCAST, gl_iszModelIndex[ SpriteEffect_Explode1 ], vecOrigin, 128.0, 16, 24 );
	UTIL_TE_EXPLOSION( MSG_BROADCAST, gl_iszModelIndex[ SpriteEffect_Explode2 ], vecOrigin, 350.0, 32, 16 );
	UTIL_TE_EXPLOSION( MSG_BROADCAST, gl_iszModelIndex[ SpriteEffect_Explode3 ], vecOrigin, 350.0, 32, 8 );
#endif

	set_entvar( pEntity, var_effects, EF_NODRAW );

#if defined _reapi_included
	SetThink( pEntity, "CClaymore__ThinkDestroy" );
#else
	set_entvar( pEntity, var_mine_state, ClaymoreState_Destroy );
#endif

	set_entvar( pEntity, var_nextthink, get_gametime( ) + 0.5 );
}

public CClaymore__Destroy( const pEntity )
{
	static pLaser; pLaser = get_entvar( pEntity, var_laser_entity );
	if ( !is_nullent( pLaser ) )
		UTIL_KillEntity( pLaser );

	UTIL_KillEntity( pEntity );
}

public CClaymoreLaser__SpawnEntity( const pClaymore, const Vector3( vecOrigin ) )
{
	new pEntity = rg_create_entity( EntityClaymoreReference );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	new Vector3( vecMins ), Vector3( vecMaxs );
	vecMins[ 0 ] = vecMins[ 1 ] = -EntityClaymoreLaserRadius;
	vecMaxs[ 0 ] = vecMaxs[ 1 ] = vecMaxs[ 2 ] = EntityClaymoreLaserRadius;

	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );
	engfunc( EngFunc_SetSize, pEntity, vecMins, vecMaxs );

	set_entvar( pEntity, var_classname, EntityClaymoreLaserClassName );
	set_entvar( pEntity, var_movetype, MOVETYPE_NOCLIP );
	set_entvar( pEntity, var_owner, pClaymore );

#if defined _reapi_included
	SetTouch( pEntity, "CClaymoreLaser__Touch" );
#endif

	return pEntity;
}

public CClaymoreLaser__Touch( const pEntity, const pTouch )
{
	static pClaymore; pClaymore = get_entvar( pEntity, var_owner );
	if ( is_nullent( pClaymore ) )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	if ( !is_user_alive( pTouch ) || !zp_get_user_zombie( pTouch ) )
		return;

	CClaymore__Detonate( pClaymore );
	set_entvar( pEntity, var_solid, SOLID_NOT );
}

#if defined UseEffectSpritesByEntity
	public CClaymoreEffect__SpawnEntity( const Vector3( vecSrc ), const iEffect, const Float: flZAxisUp, const Float: flScale, const Float: flLifeTime )
	{
		new pEntity = rg_create_entity( EntityEffectReference );
		if ( is_nullent( pEntity ) )
			return NULLENT;

		static Vector3( vecOrigin ); xs_vec_copy( vecSrc, vecOrigin );
		vecOrigin[ 2 ] += flZAxisUp;

		static Float: flGameTime; flGameTime = get_gametime( );

		set_entvar( pEntity, var_classname, EntityEffectClassName );
		set_entvar( pEntity, var_origin, vecOrigin );

		set_entvar( pEntity, var_scale, flScale );
		set_entvar( pEntity, var_framerate, gl_flSpritesMaxFrames[ iEffect ] / flLifeTime );
		set_entvar( pEntity, var_max_frame, gl_flSpritesMaxFrames[ iEffect ] - 1.0 );

		set_entvar( pEntity, var_rendermode, kRenderTransAdd );
		set_entvar( pEntity, var_renderamt, 255.0 );

		set_entvar( pEntity, var_last_time, flGameTime );
		set_entvar( pEntity, var_modelindex, gl_iszModelIndex[ iEffect ] );

	#if defined _reapi_included
		SetThink( pEntity, "CClaymoreEffect__Think" );
	#endif

		set_entvar( pEntity, var_nextthink, flGameTime );

		return pEntity;
	}

	public CClaymoreEffect__Think( const pEntity )
	{
		static Float: flGameTime; flGameTime = get_gametime( );
		set_entvar( pEntity, var_nextthink, flGameTime + EntityEffectNextThink );

		static Float: flFrame; get_entvar( pEntity, var_frame, flFrame );
		static Float: flFrameRate; get_entvar( pEntity, var_framerate, flFrameRate );
		static Float: flLastTime; get_entvar( pEntity, var_last_time, flLastTime );
		static Float: flMaxFrame; get_entvar( pEntity, var_max_frame, flMaxFrame );

		flFrame += ( flFrameRate ) * ( flGameTime - flLastTime );
		if ( flFrame > flMaxFrame )
		{
			UTIL_KillEntity( pEntity );
			return;
		}

		set_entvar( pEntity, var_frame, flFrame );
		set_entvar( pEntity, var_last_time, flGameTime );
	}
#endif

/* ~ [ Natives ] ~ */
public bool: native_give_user_weapon( const iPlugin, const iParams )
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !is_user_connected( pPlayer ) )
	{
		log_error( AMX_ERR_NATIVE, "Invalid Player (%i)", pPlayer );
		return false;
	}

	return CBasePlayer__GiveClaymore( pPlayer );
}

public native_get_user_claymore( const iPlugin, const iParams )
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !is_user_connected( pPlayer ) )
	{
		log_error( AMX_ERR_NATIVE, "[Claymore] Invalid Player (%i)", pPlayer );
		return false;
	}

	new pItem = UTIL_GetItemByName( pPlayer, WeaponReference );
	if ( is_nullent( pItem ) || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return false;

	return true;
}

public native_get_claymore_extraid() return gl_iItemId;

/* ~ [ Stocks ] ~ */
/* -> Find item by ClassName <- */

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

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity )
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );
}

/* -> Strip weapon from player by Weapon Index <- */


/* -> Get player eye position <- */
stock UTIL_GetEyePosition( const pPlayer, Vector3( vecEyeLevel ) )
{
	static Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	static Vector3( vecViewOfs ); get_entvar( pPlayer, var_view_ofs, vecViewOfs );

	xs_vec_add( vecOrigin, vecViewOfs, vecEyeLevel );
}

/* -> ScreenShake <- */
stock UTIL_ScreenShake( const iDest, const pReceiver, const Float: flAmplitude, const Float: flDuration, const Float: flFrequency )
{
	static iMsgId_ScreenShake; if ( !iMsgId_ScreenShake ) iMsgId_ScreenShake = get_user_msgid( "ScreenShake" );

	message_begin( iDest, iMsgId_ScreenShake, .player = pReceiver );
	write_short( FixedUnsigned16( flAmplitude, (1<<12) ) ); // Amplitude
	write_short( FixedUnsigned16( flDuration, (1<<12) ) ); // Duration
	write_short( FixedUnsigned16( flFrequency, (1<<12) ) ); // Frequency
	message_end( );
}

/* -> TE_WORLDDECAL <- */
stock UTIL_TE_WORLDDECAL( const iDest, const szDecalName[ ], const Vector3( vecOrigin ) )
{
	static iDecalIndex; iDecalIndex = engfunc( EngFunc_DecalIndex, szDecalName );

	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_WORLDDECAL );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_byte( iDecalIndex ); // ModelIndex
	message_end( );
}

/* -> Drop Vector to floor <- */


#if !defined UseEffectSpritesByEntity
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
		stock UTIL_WeaponList( const iDist, const pReceiver, const szWeaponName[ ], const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
		{
			static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );
			static const iWeaponList[ ] = {
				14, 1, -1, -1, 4, 3, 6, 24 // weapon_c4
			};

			message_begin( iDist, iMsgId_Weaponlist, .player = pReceiver );
			write_string( szWeaponName );
			write_byte( ( iPrimaryAmmoType <= -2 ) ? iWeaponList[ 0 ] : iPrimaryAmmoType );
			write_byte( ( iMaxPrimaryAmmo <= -2 ) ? iWeaponList[ 1 ] : iMaxPrimaryAmmo );
			write_byte( ( iSecondaryAmmoType <= -2 ) ? iWeaponList[ 2 ] : iSecondaryAmmoType );
			write_byte( ( iMaxSecondaryAmmo <= -2 ) ? iWeaponList[ 3 ] : iMaxSecondaryAmmo );
			write_byte( ( iSlot <= -2 ) ? iWeaponList[ 4 ] : iSlot );
			write_byte( ( iPosition <= -2 ) ? iWeaponList[ 5 ] : iPosition );
			write_byte( ( iWeaponId <= -2 ) ? iWeaponList[ 6 ] : iWeaponId );
			write_byte( ( iFlags <= -2 ) ? iWeaponList[ 7 ] : iFlags );
			message_end( );
		}
	#endif
#endif