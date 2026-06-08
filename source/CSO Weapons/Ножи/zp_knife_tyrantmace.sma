new const PluginName[ ] =						"[ZP] Knife: Tyrant Mace";
new const PluginVersion[ ] =					"1.2";
new const PluginAuthor[ ] =						"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <zombieplague>

#include <reapi>

/**
 * API Weapon Player Model: Allows submodel for p_ model
 * 
 * Download link: https://github.com/YoshiokaHaruki/AMXX-API-Weapon-Player-Model/releases
 */
//#tryinclude <api_weapon_player_model>

#if !defined _reapi_included
	#include <non_reapi_support>
#endif

#if !defined DMG_GRENADE
	#define DMG_GRENADE							(1<<24)
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
	/**
	 * Problem: in default ZP, if you give out a custom knife model, then, at the beginning of a new round,
	 * if you had a knife in your hands, then the model becomes ordinary v_knife.mdl
	 * 
	 * Enable a fix for this problem
	 */
	#define FixDefaultKnifeModelAfterSpawn
#endif

#if defined _zombieplague_included
	/* ~ [ Extra-Items ] ~ */
	new const ExtraItem_Name[ ] =				"Knife: Tyrant Mace";
	const ExtraItem_Cost =						0;
#endif

/* ~ [ Weapon Settings ] ~ */
const WeaponUnicalIndex =						20062023;
new const WeaponReference[ ] =					"weapon_knife";
new const WeaponListDir[ ] =					"x_re/knife_tyrantmace";
new const WeaponAnimation[ ] =					"knife"; // Original: tomahawk
new const WeaponModelView[ ] =					"models/x_re/v_tyrantmacefx.mdl";
new const WeaponModelPlayer[ ] =				"models/x_re/p_tyrantmace.mdl";
new const WeaponSounds[ ][ ] = {
	"weapons/janus9_stone1.wav",
	"weapons/tyrantmace_hit1.wav",
	"weapons/tyrantmace_hit2.wav",
	"weapons/tyrantmace_slash1.wav",
	"weapons/tyrantmace_slash2.wav",
	"weapons/tyrantmace_skill.wav",
	"weapons/tyrantmace_skill_exp.wav",
	"weapons/tyrantmace_skill_ready.wav"
};
new const WeaponEffects[ ][ ] = {
#if defined UseOptimizedSprites
	"sprites/x_re/fx/ef_tyrantmace_bmode.spr", // B Mode Spawn
	"sprites/x_re/fx/ef_tyrantmace_hit.spr" // Hit Sprite
#else
	"sprites/x_re/ef_tyrantmace_bmode.spr", // B Mode Spawn
	"sprites/x_re/ef_tyrantmace_hit.spr" // Hit Sprite
#endif
};

const WeaponGeneralDamageType =					( DMG_BULLET|DMG_NEVERGIB );
new const Float: WeaponSlashDirection[ ] = {
	// Count, Start (Right), Step (Right), Start (Up), Step (Up)
	11.0, -25.0, 5.0, 0.0, 0.0
};

#if defined WeaponListDir
	const WeaponPrimaryAmmoIndex =				20; // 15-31 only. Change if conflict with another weapons
#else
	new const PrintMessagePattern[ ] =			"[ Tyrant Mace Charge: %i%% ]"; // %i - number / %% - percent symbol
#endif
const WeaponPrimaryAmmoMax =					100; // Max primary ammo
const WeaponPrimaryAmmoDefault =				5; // Default primary ammo when u buy weapon

// Primary Attack (ATTACK1)
const Float: WeaponPrimaryAmmoChargeTime =		0.7; // Once in how many seconds to give WeaponPrimaryAmmoGive
const WeaponPrimaryAmmoGive =					5; // How much to give % (ammo) after WeaponPrimaryAmmoChargeTime
const WeaponPrimaryAmmoHitGive =				29; // How much to give % (ammo) for hitting one opponent

const WeaponHitSpriteScale =					6; // Scale of hit sprite
const Float: WeaponHitSpriteFrameRate =			3.0; // Framerate of hit sprite

const Float: WeaponSlashHitTime =				0.2; // Slash hit time. After this time, damage to the victim will occur
const Float: WeaponSlashNextAttack =			0.55; // After this time, you can use any attack again (when use Secondary Attack)
const Float: WeaponSlashDistance =				150.0; // Distance for hit victim
const Float: WeaponSlashDamage =				500.0; // Damage of slash
const Float: WeaponSlashKnockBack =				250.0; // KnockBack of slash

// Secondary Attack (ATTACK2)
const Float: WeaponSkillNextAttack =			1.3; // After this time, you can use any attack again (when use Secondary Attack)
const Float: WeaponSkillIceDistance =			300.0; // Max. distance for create ice spikes (skill)
const Float: WeaponSkillHitTime =				0.27; // Stab/skill hit time. After this time, damage to the victim will occur
const Float: WeaponSkillHitDistance =			150.0; // Distance for hit victim
const Float: WeaponSkillHitDamage =				750.0; // Damage of stab/skill
const Float: WeaponSkillHitKnockBack =			350.0; // KncokBack of stab/skill

// Skill: ShockWave
const Float: WeaponSkillExpRadius =				100.0; // Skill Explosion radius
const Float: WeaponSkillExpDamage =				650.0; // Skill Explosion damage
const WeaponSkillExpDamageType =				( DMG_DROWN|DMG_GRENADE ); // DMG_DROWN - ice icon

// Skill: Victim's Ice Spike
const Float: WeaponIceVictimTime =				1.0; // LifeTime of ice spike
const Float: WeaponIceVictimSlowPower =			0.5; // How much is the speed slowing down
const Float: WeaponIceVictimDamageTime =		0.5; // Once in how many seconds will it deal damage
const Float: WeaponIceVictimDamage =			150.0; // Damage
const WeaponIceVictimDamageType =				( DMG_DROWN|DMG_GRENADE ); // DMG_DROWN - ice icon

// Skill: Hole
const Float: WeaponHoleRadius =					200.0; // Radius
const Float: WeaponHoleKnockBack =				750.0; // KnockBack power

/* ~ [ Entity: Global ] ~ */
new const EntityGlobalReferences[ ] =			"info_target";
new const EntityGlobalModel[ ] =				"models/x_re/ef_tyrantmace.mdl"; // Global model of effects
const Float: EntityGlobalFadeAmount =			10.0;
const Float: EntityGlobalFadeNextThink =		0.05;
const Float: EntityGlobalLifeTime =				1.5; // Life time of ALL entities

/* ~ [ Entity: ShockWave ] ~ */
new const EntityShockWaveClassName[ ] =			"ent_tyrantmace_shockwave";
const Float: EntityShockWaveLifeTime =			EntityGlobalLifeTime;
const EntityShockWaveSpriteScale =				8; // Scale of Shockwave sprite
const Float: EntityShockWaveSpriteFrameRate =	1.0; // Framerate of Shockwave sprite

/* ~ [ Entity: Ice Spike ] ~ */
new const EntityIceSpikeClassName[ ] =			"ent_tyrantmace_ice_spike";
new const Float: EntityIceSpikeSize[ ][ ] = {
	{ -10.0, -10.0, -1.0 }, { 10.0, 10.0, 10.0 }
}
const Float: EntityIceSpikeLifeTime =			EntityGlobalLifeTime;
const EntityIceSpikesCount =					3; // Count of small spikes in ice shockwave (just visual)

/* ~ [ Entity: Ice Spike Victim ] ~ */
new const EntityIceVictimClassName[ ] =			"ent_tyrantmace_ice_victim";
const Float: EntityIceVictimNextThink =			0.05; // Update time for victim's ice spike

/* ~ [ Entity: Ice Spikes Road ] ~ */
new const EntityIceRoadClassName[ ] =			"ent_tyrantmace_ice_road";
const Float: EntityIceRoadLifeTime =			EntityGlobalLifeTime;

/* ~ [ Entity: Hole ] ~ */
new const EntityHoleClassName[ ] =				"ent_tyrantmace_hole";
const Float: EntityHoleLifeTime =				0.7; // Hole lifetime

/* ~ [ Entity: HitBox ] ~ */
new const EntityHitBoxClassName[ ] =			"ent_tyrantmace_hitbox";
new const Float: EntityHitBoxSize[ ][ ][ ] = {
	{
		// Hitbox size for Shockwave
		{ -75.0, -75.0, -75.0 }, { 75.0, 75.0, 75.0 }
	},
	{
		// Hitbox size for Ice Spikes Road
		{ -100.0, -100.0, -75.0 }, { 100.0, 100.0, 75.0 }
	}
};

/* ~ [ Weapon Animations ] ~ */
enum {
	WeaponAnim_Idle = 0,
	WeaponAnim_Draw,
	WeaponAnim_Slash1,
	WeaponAnim_Slash1_End,
	WeaponAnim_Slash2,
	WeaponAnim_Slash2_End,
	WeaponAnim_Skill_Start,
	WeaponAnim_Skill_End,
	WeaponAnim_Dummy
};

const Float: WeaponAnim_Idle_Time =				3.0;
const Float: WeaponAnim_Draw_Time =				1.0;
const Float: WeaponAnim_Slash_Time =			0.7;
const Float: WeaponAnim_Slash_End_Time =		0.97;
const Float: WeaponAnim_Skill_Start_Time =		0.57;
const Float: WeaponAnim_Skill_End_Time =		1.3;

/* ~ [ Params ] ~ */
new gl_bitsUserConnected;

#if AMXX_VERSION_NUM <= 182
	new MaxClients;
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
	new gl_iItemId;
#endif

#if !defined _reapi_included && defined WeaponListDir
	new gl_iMsgHook_WeaponList;
	new gl_FM_Hook_RegUserMsg_Post;
	new gl_aWeaponListData[ 8 ];
#endif

enum any: eModelIndex {
	ModelIndex_BMode_Explode = 0,
	ModelIndex_Hit_Victim
};
new gl_iszModelIndex[ eModelIndex ];
new gl_iModelIndex_Frames[ eModelIndex ];

enum ( <<= 1 ) {
	WeaponState_Slash_Hit = 1,
	WeaponState_Slash_End,
	WeaponState_Slash_Anim,

	WeaponState_HasImpact,
	WeaponState_Skill,
	WeaponState_Skill_End
};

enum ( <<= 1 ) {
	HitResult_None = 1,
	HitResult_World,
	HitResult_Entity
};

enum any: eSounds {
	Sound_HitWall = 0,
	Sound_Hit1,
	Sound_Hit2,
	Sound_Slash1,
	Sound_Slash2,
	Sound_Skill,
	Sound_Skill_Explode,
	Sound_Skill_Ready
};

enum any: eEntitiesList {
	Entity_Hole = 0,
	Entity_IceShockWave,
	Entity_IceSpike,
	Entity_IceHit,
	Entity_IceSpikesRoad
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
#define BIT_INVERT(%0,%1)					( %0 ^= %1 )

#define IsUserValid(%0)						bool: ( 0 < %0 <= MaxClients )
#define IsUserConnected(%0)					bool: ( IsUserValid( %0 ) && BIT_VALID( gl_bitsUserConnected, BIT_PLAYER( %0 ) ) )

#define IsUserHasTyrantMace(%1) (Get_Bit(gl_iBitUserHasTyrantMace, %1))

#define Get_Bit(%1,%2) ((%1 & (1 << (%2 & 31))) ? 1 : 0)
#define Set_Bit(%1,%2) %1 |= (1 << (%2 & 31))
#define Reset_Bit(%1,%2) %1 &= ~(1 << (%2 & 31))
/* #define IsCustomWeapon(%0,%1)				bool: ( get_entvar( %0, var_impulse ) == %1 ) */

#define GetWeaponState(%0)					get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)				set_member( %0, m_Weapon_iWeaponState, %1 )
#if defined WeaponListDir
	#define GetWeaponAmmoType(%0)			get_member( %0, m_Weapon_iPrimaryAmmoType )
	#define GetWeaponAmmo(%0,%1)			get_member( %0, m_rgAmmo, %1 )
	#define SetWeaponAmmo(%0,%1,%2)			set_member( %0, m_rgAmmo, %1, %2 )
#endif

#define WeaponHasMaxAmmo(%0)				bool: ( %0 >= WeaponPrimaryAmmoMax )
#define WeaponHasImpact(%0)					BIT_VALID( %0, WeaponState_HasImpact )

#define var_next_charge						var_starttime // pWeapon
#define var_charge_level					var_weaponanim // pWeapon

new g_iKnife, gl_iBitUserHasTyrantMace

native zp_register_knife(const szName[]);
forward zp_knife_selected(id, iKnife, iOldKnife);

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( )
{
	register_native( "zp_get_user_tyrantmace", "CPlayer_GetWeapon", 1 );
	register_native( "zp_give_user_tyrantmace", "CPlayer_GiveWeapon", 1 );
	register_native( "zp_delete_user_tyrantmace", "CPlayer_RemoveWeapon", 1 );
}

public plugin_precache( )
{
	new i;

	/* -> Precache Models <- */
	engfunc( EngFunc_PrecacheModel, WeaponModelView );
	engfunc( EngFunc_PrecacheModel, WeaponModelPlayer );
	engfunc( EngFunc_PrecacheModel, EntityGlobalModel );

	/* -> Precache Sounds <- */
	for ( i = 0; i < sizeof WeaponSounds; i++ )
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
	for ( i = 0; i < sizeof WeaponEffects; i++ )
	{
		gl_iszModelIndex[ i ] = engfunc( EngFunc_PrecacheModel, WeaponEffects[ i ] );
		gl_iModelIndex_Frames[ i ] = engfunc( EngFunc_ModelFrames, gl_iModelIndex_Frames[ i ] );
	}
}

public plugin_init( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

	/* -> Fakemeta <- */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

	/* -> Events <- */
	register_event( "HLTV", "EV_RoundStart", "a", "1=0", "2=0" );

#if defined _zombieplague_included && defined FixDefaultKnifeModelAfterSpawn
	register_event( "CurWeapon", "EV_CurWeapon", "be", "1=1" );
#endif

	/* -> HamSandwich: Weapon <- */
	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_CWeapon_Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_CWeapon_Holster_Post", true );
	RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_CWeapon_PostFrame_Pre", false );
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Ham_CWeapon_AddToPlayer_Post", true );
	RegisterHam( Ham_Weapon_WeaponIdle, WeaponReference, "Ham_CWeapon_WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CWeapon_PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_CWeapon_SecondaryAttack_Pre", false );

#if !defined _reapi_included
	/* -> HamSandwich: Entity <- */
	RegisterHam( Ham_Think, EntityGlobalReferences, "CEntity_Think_Post", true );
	RegisterHam( Ham_Touch, EntityGlobalReferences, "CEntity_Touch_Post", true );
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

	g_iKnife = zp_register_knife("Tyrant Mace");
}

public zp_knife_selected(iPlayer, iNew, iOld)
{
	if(g_iKnife == iNew && iNew != iOld)
		Set_Bit(gl_iBitUserHasTyrantMace, iPlayer);

	if(g_iKnife == iOld && iNew != iOld)
		Reset_Bit(gl_iBitUserHasTyrantMace, iPlayer);
}

public client_putinserver( pPlayer ) BIT_ADD( gl_bitsUserConnected, BIT_PLAYER( pPlayer ) );
public client_disconnected( pPlayer ) BIT_SUB( gl_bitsUserConnected, BIT_PLAYER( pPlayer ) );

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

			if ( strcmp( szWeaponName, WeaponReference ) != 0 )
				return;
			
			for ( new i, a = sizeof gl_aWeaponListData; i < a; i++ )
				gl_aWeaponListData[ i ] = get_msg_arg_int( i + 2 );
		}
	}
#endif

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
	static iSpecMode, pTarget;
	pTarget = ( iSpecMode = get_entvar( pPlayer, var_iuser1 ) ) ? get_entvar( pPlayer, var_iuser2 ) : pPlayer;

	if ( !IsUserConnected( pTarget ) )
		return;

	static pActiveItem; pActiveItem = get_member( pTarget, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsUserHasTyrantMace(pPlayer) )
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

#if defined WeaponListDir && !defined _reapi_included
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
	UTIL_DestroyEntitiesByClass( EntityShockWaveClassName );
	UTIL_DestroyEntitiesByClass( EntityIceSpikeClassName );
	UTIL_DestroyEntitiesByClass( EntityIceVictimClassName );
	UTIL_DestroyEntitiesByClass( EntityIceRoadClassName );
	UTIL_DestroyEntitiesByClass( EntityHoleClassName );
	UTIL_DestroyEntitiesByClass( EntityHitBoxClassName );
}

#if defined _zombieplague_included && defined FixDefaultKnifeModelAfterSpawn
	public EV_CurWeapon( const pPlayer )
	{
		if ( !is_user_alive( pPlayer ) || zp_get_user_zombie( pPlayer ) )
			return;

		static pActiveItem; pActiveItem = get_member( pPlayer, m_pActiveItem );
		if ( is_nullent( pActiveItem ) || !IsUserHasTyrantMace(pPlayer) )
			return;

		static szViewModel[ 64 ]; get_entvar( pPlayer, var_viewmodel, szViewModel, charsmax( szViewModel ) );
		if ( strcmp( szViewModel, WeaponModelView ) != 0 )
			return;

		ExecuteHamB( Ham_Item_Deploy, pActiveItem );
	}
#endif

/* ~ [ HamSandwich ] ~ */
public Ham_CWeapon_Deploy_Post( const pItem )
{
	if ( is_nullent( pItem ) )
		return;

	new pPlayer
	if ( ( pPlayer = get_member( pItem, m_pPlayer ) ) <= 0 || zp_get_user_zombie(pPlayer) || !IsUserHasTyrantMace(pPlayer))
		return;

	// Charge after deploy
	new bitsWeaponState = GetWeaponState( pItem );
	CWeapon_ChargeAfterDeploy( pItem, pPlayer, bitsWeaponState );

	set_entvar( pPlayer, var_viewmodel, WeaponModelView );
#if defined _api_wpn_player_included
	set_entvar( pPlayer, var_weaponmodel, "" );
	api_wpn_player_model_set( pPlayer, WeaponModelPlayer, WeaponHasImpact( bitsWeaponState ) ? 1 : 0 );
#else
	set_entvar( pPlayer, var_weaponmodel, WeaponModelPlayer );
#endif
	set_entvar( pItem, var_body, WeaponHasImpact( bitsWeaponState ) ? 6 : 0 );

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
	new pPlayer;

	if ( is_nullent( pItem ) || !IsUserHasTyrantMace(pPlayer) )
		return;

	if ( ( pPlayer = get_member( pItem, m_pPlayer ) ) <= 0 )
		return;

	new bitsWeaponState;
	if ( ( bitsWeaponState = GetWeaponState( pItem ) ) )
	{
		BIT_SUB( bitsWeaponState, WeaponState_Slash_Hit );
		BIT_SUB( bitsWeaponState, WeaponState_Slash_End );
		BIT_SUB( bitsWeaponState, WeaponState_Slash_Anim );
		BIT_SUB( bitsWeaponState, WeaponState_Skill );
		BIT_SUB( bitsWeaponState, WeaponState_Skill_End );

		SetWeaponState( pItem, bitsWeaponState );
	}

	set_entvar( pItem, var_next_charge, get_gametime( ) );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

public Ham_CWeapon_PostFrame_Pre( const pItem )
{
	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	if ( is_nullent( pItem ) || !IsUserHasTyrantMace(pPlayer) )
		return HAM_IGNORED;

	if ( pPlayer <= 0 )
		return HAM_IGNORED;

	// Weapon State
	static bitsWeaponState;
	if ( ( bitsWeaponState = GetWeaponState( pItem ) ) )
	{
		static iHitCount; iHitCount = 0;

		// Skill
		if ( BIT_VALID( bitsWeaponState, WeaponState_Skill ) )
		{
			BIT_SUB( bitsWeaponState, WeaponState_HasImpact );
			BIT_SUB( bitsWeaponState, WeaponState_Skill );
			BIT_ADD( bitsWeaponState, WeaponState_Skill_End );

			CWeapon_HitSound(
				pPlayer,
				UTIL_FakeTraceLine( pPlayer, pItem, Float: WeaponSlashDirection, WeaponSkillHitDistance, WeaponSkillHitDamage, WeaponSkillHitKnockBack, WeaponGeneralDamageType, iHitCount )
			);

			new Vector3( vecSrc ); get_entvar( pPlayer, var_punchangle, vecSrc );
			new Vector3( vecAngles ); get_entvar( pPlayer, var_angles, vecAngles );

			new Vector3( vecDirection );
			xs_vec_add( vecAngles, vecSrc, vecDirection );
			angle_vector( vecDirection, ANGLEVECTOR_FORWARD, vecDirection );

			UTIL_GetEyePosition( pPlayer, vecSrc );
			new Vector3( vecEndPos ); xs_vec_add_scaled( vecSrc, vecDirection, WeaponSkillIceDistance, vecEndPos );

			new pTrace = create_tr2( );
			engfunc( EngFunc_TraceLine, vecSrc, vecEndPos, IGNORE_MONSTERS, pPlayer, pTrace );
			get_tr2( pTrace, TR_vecEndPos, vecEndPos );
			free_tr2( pTrace );

			if ( !UTIL_GetEdgeOfVectors( vecSrc, vecEndPos, vecEndPos ) )
			{
				xs_vec_copy( vecSrc, vecEndPos );
				UTIL_DropVectorToFloor( vecEndPos );
			}

			UTIL_TE_DLIGHT( MSG_PAS, vecEndPos, 24, { 0, 128, 255 }, 30, 32 );

			// Not too close to the wall
			if ( xs_vec_distance( vecSrc, vecEndPos ) >= 128.0 )
			{
				new Vector3( vecCentre ); xs_vec_add( vecSrc, vecEndPos, vecCentre );
				xs_vec_div_scalar( vecCentre, 2.0, vecCentre );

				vecCentre[ 2 ] = vecSrc[ 2 ];
				UTIL_DropVectorToFloor( vecCentre );

				vecAngles[ 0 ] = 0.0;
				vecAngles[ 1 ] -= 180.0;

				CIceRoad__SpawnEntity( vecCentre, vecEndPos, vecAngles, true );
				CIceRoad__SpawnEntity( vecCentre, vecEndPos, vecAngles, false );
				CHitBox__SpawnEntity( pPlayer, pItem, vecCentre, true );
			}

			CHitBox__SpawnEntity( pPlayer, pItem, vecEndPos, false );
			CShockWave__SpawnEntity( pPlayer, pItem, vecEndPos );
			CHole__SpawnEntity( pPlayer );

		#if defined _api_wpn_player_included
			api_wpn_player_model_set( pPlayer, WeaponModelPlayer, 0 );
		#endif

			set_entvar( pItem, var_body, 0 );
			SetWeaponState( pItem, bitsWeaponState );
			CWeapon_SetChargeLevel( pItem, pPlayer, 0 );
			set_member( pPlayer, m_flNextAttack, WeaponAnim_Skill_Start_Time - WeaponSkillHitTime );
		}

		// Skill End (only for update animation with new body)
		else if ( BIT_VALID( bitsWeaponState, WeaponState_Skill_End ) )
		{
			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Skill_End );
			BIT_SUB( bitsWeaponState, WeaponState_Skill_End );

			SetWeaponState( pItem, bitsWeaponState );
			set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Skill_End_Time );
		}

		// Slash Hit
		else if ( BIT_VALID( bitsWeaponState, WeaponState_Slash_Hit ) )
		{
			CWeapon_HitSound(
				pPlayer,
				UTIL_FakeTraceLine( pPlayer, pItem, Float: WeaponSlashDirection, WeaponSlashDistance, WeaponSlashDamage, WeaponSlashKnockBack, WeaponGeneralDamageType, iHitCount )
			);

			BIT_ADD( bitsWeaponState, WeaponState_Slash_End );
			BIT_SUB( bitsWeaponState, WeaponState_Slash_Hit );

			if ( iHitCount && !WeaponHasImpact( bitsWeaponState ) )
			{
				static iAmmo; iAmmo = CWeapon_GetChargeLevel( pItem, pPlayer );
				if ( !WeaponHasMaxAmmo( iAmmo ) )
				{
					CWeapon_SetChargeLevel( pItem, pPlayer, iAmmo = min( iAmmo + ( WeaponPrimaryAmmoHitGive * iHitCount ), WeaponPrimaryAmmoMax ) );

					if ( WeaponHasMaxAmmo( iAmmo ) || !WeaponHasImpact( bitsWeaponState ) )
						CWeapon_CheckGlacialImpact( pItem, pPlayer, iAmmo, bitsWeaponState );
				}
			}

			SetWeaponState( pItem, bitsWeaponState );
			set_member( pPlayer, m_flNextAttack, WeaponSlashNextAttack - WeaponSlashHitTime );
		}

		// Slash End (only for update animation with new body)
		else if ( BIT_VALID( bitsWeaponState, WeaponState_Slash_End ) )
		{
			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Slash1_End + ( ( BIT_VALID( bitsWeaponState, WeaponState_Slash_Anim ) ? 1 : 0 ) * 2 ) );

			BIT_SUB( bitsWeaponState, WeaponState_Slash_End );
			BIT_INVERT( bitsWeaponState, WeaponState_Slash_Anim );

			SetWeaponState( pItem, bitsWeaponState );
			set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Slash_End_Time );
		}
	}

	// Charge
	CWeapon_Charge( pItem, pPlayer, bitsWeaponState );

	return HAM_IGNORED;
}

public Ham_CWeapon_AddToPlayer_Post( const pItem, const pPlayer )
{
	if ( is_nullent( pItem ) )
		return;

/* #if defined WeaponListDir
	if ( IsCustomWeapon( pItem, 0 ) )
	{
	#if defined _reapi_included
		UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
	#else
		UTIL_WeaponList( MSG_ONE, pPlayer, WeaponReference );
	#endif

		return;
	}
#endif */

	if ( !IsUserHasTyrantMace(pPlayer) )
		return;

	if ( get_entvar( pItem, var_owner ) <= 0 )
	{
	#if defined WeaponListDir
		set_member( pItem, m_Weapon_iPrimaryAmmoType, WeaponPrimaryAmmoIndex );

		#if defined _reapi_included
			rg_set_iteminfo( pItem, ItemInfo_pszName, WeaponListDir );
			rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WeaponPrimaryAmmoMax );
		#endif

		SetWeaponAmmo( pPlayer, WeaponPrimaryAmmoDefault, WeaponPrimaryAmmoIndex );
	#endif

		set_entvar( pItem, var_next_charge, get_gametime( ) + WeaponPrimaryAmmoChargeTime );
	}

#if defined WeaponListDir
	#if defined _reapi_included
		UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
	#else
		UTIL_WeaponList( MSG_ONE, pPlayer, WeaponListDir, WeaponPrimaryAmmoIndex, WeaponPrimaryAmmoMax );
	#endif
#endif
}

public Ham_CWeapon_WeaponIdle_Pre( const pItem )
{
	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	if ( is_nullent( pItem ) || !IsUserHasTyrantMace(pPlayer) )
		return HAM_IGNORED;

	if ( Float: get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	if ( pPlayer <= 0 )
		return HAM_IGNORED;

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Idle );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Idle_Time );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PrimaryAttack_Pre( const pItem )
{
	static pPlayer; pPlayer = get_member( pItem, m_pPlayer )

	if ( is_nullent( pItem ) || zp_get_user_zombie(pPlayer) || !IsUserHasTyrantMace(pPlayer) )
		return HAM_IGNORED;

	if ( pPlayer <= 0 )
		return HAM_IGNORED;

	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	static iSecondarySlashAnim; iSecondarySlashAnim = BIT_VALID( bitsWeaponState, WeaponState_Slash_Anim ) ? 1 : 0;

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Slash1 + ( iSecondarySlashAnim * 2 ) );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_Slash1 + iSecondarySlashAnim ] );
#if defined _reapi_included
	rg_set_animation( pPlayer, PLAYER_ATTACK1 );
#else
	static szPlayerAnim[ 32 ]; formatex( szPlayerAnim, charsmax( szPlayerAnim ), "%s_shoot_%s", get_entvar( pPlayer, var_flags ) & FL_DUCKING ? "crouch" : "ref", WeaponAnimation );
	UTIL_PlayerAnimation( pPlayer, szPlayerAnim );
#endif

	BIT_ADD( bitsWeaponState, WeaponState_Slash_Hit );

	SetWeaponState( pItem, bitsWeaponState );
	set_member( pPlayer, m_flNextAttack, WeaponSlashHitTime );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Slash_Time );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponSlashNextAttack );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponSlashNextAttack );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_SecondaryAttack_Pre( const pItem )
{
	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );

	if ( is_nullent( pItem ) || zp_get_user_zombie(pPlayer) || !IsUserHasTyrantMace(pPlayer) )
		return HAM_IGNORED;

	if ( pPlayer <= 0 )
		return HAM_IGNORED;

	static bitsWeaponState; bitsWeaponState = GetWeaponState( pItem );
	if ( !WeaponHasImpact( bitsWeaponState ) )
		return HAM_SUPERCEDE;

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Skill_Start );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_Skill ] );
#if defined _reapi_included
	rg_set_animation( pPlayer, PLAYER_ATTACK1 );
#else
	static szPlayerAnim[ 32 ]; formatex( szPlayerAnim, charsmax( szPlayerAnim ), "%s_shoot_%s", get_entvar( pPlayer, var_flags ) & FL_DUCKING ? "crouch" : "ref", WeaponAnimation );
	UTIL_PlayerAnimation( pPlayer, szPlayerAnim );
#endif

	BIT_ADD( bitsWeaponState, WeaponState_Skill );

	SetWeaponState( pItem, bitsWeaponState );
	set_member( pPlayer, m_flNextAttack, WeaponSkillHitTime );
	set_entvar( pItem, var_next_charge, get_gametime( ) + WeaponPrimaryAmmoChargeTime );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Skill_Start_Time );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponSkillNextAttack );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponSkillNextAttack );

	return HAM_SUPERCEDE;
}

#if !defined _reapi_included
	public CEntity_Think_Post( const pEntity )
	{
		if ( is_nullent( pEntity ) )
			return;

		static szClassName[ 32 ];
		get_entvar( pEntity, var_classname, szClassName, charsmax( szClassName ) );

		if ( equal( szClassName, EntityShockWaveClassName ) || equal( szClassName, EntityIceSpikeClassName ) || equal( szClassName, EntityIceRoadClassName ) )
		{
			CEntity_FadeDestroy( pEntity );
			return;
		}

		if ( equal( szClassName, EntityHoleClassName ) )
		{
			CHole__Think( pEntity );
			return;
		}

		if ( equal( szClassName, EntityHitBoxClassName ) )
		{
			CHitBox__Think( pEntity );
			return;
		}

		if ( equal( szClassName, EntityIceVictimClassName ) )
		{
			CIceVictim__Think( pEntity );
			return;
		}
	}

	public CEntity_Touch_Post( const pEntity, const pTouch )
	{
		if ( is_nullent( pEntity ) )
			return;

		if ( FClassnameIs( pEntity, EntityHitBoxClassName ) )
		{
			CHitBox__Touch( pEntity, pTouch );
			return;
		}
	}
#endif

/* ~ [ Other ] ~ */
public bool: CPlayer_GiveWeapon( const pPlayer )
{
	if ( !IsUserConnected( pPlayer ) )
		return false;

	if ( CPlayer_GetWeapon( pPlayer ) )
		return false;

	new pItem = rg_give_custom_item( pPlayer, WeaponReference, GT_REPLACE, WeaponUnicalIndex );
	if ( is_nullent( pItem ) )
		return false;

	return true;
}

public bool: CPlayer_GetWeapon( const pPlayer )
{
	if ( !IsUserConnected( pPlayer ) )
		return false;

	new pItem = get_member( pPlayer, m_rgpPlayerItems, KNIFE_SLOT );
	if ( is_nullent( pItem ) || !IsUserHasTyrantMace(pPlayer) )
		return false;

	return true;
}

public bool: CPlayer_RemoveWeapon( const pPlayer )
{
	if ( !IsUserConnected( pPlayer ) )
		return false;

	new pItem = get_member( pPlayer, m_rgpPlayerItems, KNIFE_SLOT );
	if ( is_nullent( pItem ) || !IsUserHasTyrantMace(pPlayer) )
		return false;

	return is_nullent( rg_give_item( pPlayer, WeaponReference, GT_REPLACE ) ) ? false : true;
}

public CWeapon_HitSound( const pPlayer, const bitsHitResult )
{
	if ( !bitsHitResult )
		return;

	if ( BIT_VALID( bitsHitResult, HitResult_Entity ) )
		rh_emit_sound2( pPlayer, 0, CHAN_STATIC, WeaponSounds[ random_num( Sound_Hit1, Sound_Hit2 ) ] );
	else if ( BIT_VALID( bitsHitResult, HitResult_World ) )
		rh_emit_sound2( pPlayer, 0, CHAN_STATIC, WeaponSounds[ Sound_HitWall ] );
}

public CWeapon_Charge( const pItem, const pPlayer, &bitsWeaponState )
{
	if ( WeaponHasImpact( bitsWeaponState ) )
		return;

	static iAmmo; iAmmo = CWeapon_GetChargeLevel( pItem, pPlayer );
	if ( WeaponHasMaxAmmo( iAmmo ) )
	{
		CWeapon_CheckGlacialImpact( pItem, pPlayer, iAmmo, bitsWeaponState );
		SetWeaponState( pItem, bitsWeaponState );

		return;
	}

	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flNextCharge; get_entvar( pItem, var_next_charge, flNextCharge );

	if ( 0.0 < flNextCharge < flGameTime )
	{
		CWeapon_SetChargeLevel( pItem, pPlayer, iAmmo = min( iAmmo + WeaponPrimaryAmmoGive, WeaponPrimaryAmmoMax ) );
		CWeapon_CheckGlacialImpact( pItem, pPlayer, iAmmo, bitsWeaponState );

		SetWeaponState( pItem, bitsWeaponState );
	}
}

public CWeapon_ChargeAfterDeploy( const pItem, const pPlayer, &bitsWeaponState )
{
	if ( WeaponHasImpact( bitsWeaponState ) )
		return;

	new iAmmo = CWeapon_GetChargeLevel( pItem, pPlayer );
	if ( WeaponHasMaxAmmo( iAmmo ) )
	{
		CWeapon_CheckGlacialImpact( pItem, pPlayer, iAmmo, bitsWeaponState );
		
		if ( WeaponHasImpact( bitsWeaponState ) )
			SetWeaponState( pItem, bitsWeaponState );

		return;
	}

	new Float: flGameTime = get_gametime( );
	new Float: flNextCharge; get_entvar( pItem, var_next_charge, flNextCharge );

	if ( flNextCharge == 0.0 || flNextCharge > flGameTime )
		return;

	CWeapon_SetChargeLevel( pItem, pPlayer, iAmmo = min( iAmmo + ( floatround( ( flGameTime - flNextCharge ) / WeaponPrimaryAmmoChargeTime, floatround_floor ) * WeaponPrimaryAmmoGive ), WeaponPrimaryAmmoMax ) );
	CWeapon_CheckGlacialImpact( pItem, pPlayer, iAmmo, bitsWeaponState );

	if ( WeaponHasImpact( bitsWeaponState ) )
		SetWeaponState( pItem, bitsWeaponState );
}

public CWeapon_CheckGlacialImpact( const pItem, const pPlayer, const iAmmo, &bitsWeaponState )
{
	if ( WeaponHasImpact( bitsWeaponState ) )
		return;

	if ( !WeaponHasMaxAmmo( iAmmo ) )
	{
		set_entvar( pItem, var_next_charge, get_gametime( ) + WeaponPrimaryAmmoChargeTime );
		return;
	}

	BIT_ADD( bitsWeaponState, WeaponState_HasImpact );

	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_Skill_Ready ] );
	set_entvar( pItem, var_body, 6 );
	set_entvar( pItem, var_next_charge, 0.0 );

#if defined _api_wpn_player_included
	api_wpn_player_model_set( pPlayer, WeaponModelPlayer, 1 );
#endif

	if ( get_entvar( pPlayer, var_weaponanim ) == WeaponAnim_Idle )
		set_member( pItem, m_Weapon_flTimeWeaponIdle, 0.0 );
}

public CShockWave__SpawnEntity( const pAttacker, const pInflictor, const Vector3( vecOrigin ) )
{
	new pEntity = rg_create_entity( EntityGlobalReferences );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	engfunc( EngFunc_SetModel, pEntity, EntityGlobalModel );
	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );
	engfunc( EngFunc_SetSize, pEntity, EntityHitBoxSize[ 0 ][ 0 ], EntityHitBoxSize[ 0 ][ 1 ] );

	set_entvar( pEntity, var_classname, EntityShockWaveClassName );
	set_entvar( pEntity, var_body, Entity_IceShockWave );
	set_entvar( pEntity, var_rendermode, kRenderTransAdd );
	set_entvar( pEntity, var_renderamt, 255.0 );
	set_entvar( pEntity, var_nextthink, get_gametime( ) + EntityShockWaveLifeTime );

	UTIL_SetEntityAnim( pEntity, Entity_IceShockWave );
	rh_emit_sound2( pEntity, 0, CHAN_WEAPON, WeaponSounds[ Sound_Skill_Explode ] );

	static iFrameRate; if ( !iFrameRate ) iFrameRate = floatround( gl_iszModelIndex[ ModelIndex_BMode_Explode ] / Float: EntityShockWaveSpriteFrameRate );

	UTIL_TE_EXPLOSION( MSG_BROADCAST, gl_iszModelIndex[ ModelIndex_BMode_Explode ], vecOrigin, 0.0, EntityShockWaveSpriteScale, iFrameRate );

#if defined _reapi_included
	SetThink( pEntity, "CGlobalEntity__Think" );
#endif

	for ( new i = 0, Float: flYAngle = 0.0, Float: flAngleAdd = float( 360 / EntityIceSpikesCount ); i < EntityIceSpikesCount; i++ )
	{
		CIceSpike__SpawnEntity( vecOrigin, flYAngle );
		flYAngle += flAngleAdd;
	}

	for ( new pVictim = 1, Vector3( vecVictimOrigin ); pVictim <= MaxClients; pVictim++ )
	{
		if ( !is_user_alive( pVictim ) || pVictim == pAttacker )
			continue;

	#if defined _zombieplague_included
		if ( !zp_get_user_zombie( pVictim ) )
	#else
		if ( IsSimilarPlayersTeam( pVictim, pAttacker ) )
	#endif
			continue;

		get_entvar( pVictim, var_origin, vecVictimOrigin );
		if ( xs_vec_distance( vecOrigin, vecVictimOrigin ) >= WeaponSkillExpRadius )
			continue;

		set_member( pVictim, m_LastHitGroup, HIT_GENERIC );
		ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pAttacker, WeaponSkillExpDamage, WeaponSkillExpDamageType );
	}

	return pEntity;
}

public CIceSpike__SpawnEntity( const Vector3( vecOrigin ), const Float: flYAngle )
{
	new pEntity = rg_create_entity( EntityGlobalReferences );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	engfunc( EngFunc_SetModel, pEntity, EntityGlobalModel );
	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );
	engfunc( EngFunc_SetSize, pEntity, EntityIceSpikeSize[ 0 ], EntityIceSpikeSize[ 1 ] );

	new Vector3( vecAngles ); vecAngles[ 1 ] = flYAngle;

	set_entvar( pEntity, var_classname, EntityIceSpikeClassName );
	set_entvar( pEntity, var_body, Entity_IceSpike );
	set_entvar( pEntity, var_angles, vecAngles );
	set_entvar( pEntity, var_rendermode, kRenderTransAdd );
	set_entvar( pEntity, var_renderamt, 255.0 );
	set_entvar( pEntity, var_nextthink, get_gametime( ) + EntityIceSpikeLifeTime );

	UTIL_SetEntityAnim( pEntity, Entity_IceSpike );

#if defined _reapi_included
	SetThink( pEntity, "CGlobalEntity__Think" );
#endif

	return pEntity;
}

public CIceRoad__SpawnEntity( const Vector3( vecCentre ), const Vector3( vecOrigin ), const Vector3( vecAngles ), const bool: bRoad )
{
	new pEntity = rg_create_entity( EntityGlobalReferences );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	new Vector3( vecNewPos ); xs_vec_copy( vecOrigin, vecNewPos );
	if ( vecCentre[ 2 ] != vecNewPos[ 2 ] )
		vecNewPos[ 2 ] = vecCentre[ 2 ];

	engfunc( EngFunc_SetModel, pEntity, EntityGlobalModel );
	engfunc( EngFunc_SetOrigin, pEntity, vecNewPos );
	engfunc( EngFunc_SetSize, pEntity, Float: { -250.0, -250.0, -250.0 }, Float: { 250.0, 250.0, 250.0 } );

	set_entvar( pEntity, var_classname, EntityIceRoadClassName );
	set_entvar( pEntity, var_body, Entity_IceSpikesRoad + any: bRoad );
	set_entvar( pEntity, var_angles, vecAngles );
	set_entvar( pEntity, var_rendermode, kRenderTransAdd );
	set_entvar( pEntity, var_renderamt, 255.0 );
	set_entvar( pEntity, var_nextthink, get_gametime( ) + EntityIceRoadLifeTime );

	UTIL_SetEntityAnim( pEntity, Entity_IceSpikesRoad );

#if defined _reapi_included
	SetThink( pEntity, "CGlobalEntity__Think" );
#endif

	return pEntity;
}

public CHole__SpawnEntity( const pPlayer )
{
	new pEntity = rg_create_entity( EntityGlobalReferences );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	new Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	vecOrigin[ 2 ] -= ( get_entvar( pPlayer, var_flags ) & FL_DUCKING ) ? 16.0 : 30.0;

	engfunc( EngFunc_SetModel, pEntity, EntityGlobalModel );
	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );

	set_entvar( pEntity, var_classname, EntityHoleClassName );
	set_entvar( pEntity, var_body, Entity_Hole );
	set_entvar( pEntity, var_rendermode, kRenderTransAdd );
	set_entvar( pEntity, var_renderamt, 255.0 );
	set_entvar( pEntity, var_nextthink, get_gametime( ) + EntityHoleLifeTime );

	UTIL_SetEntityAnim( pEntity, Entity_Hole, .flFrameRate = 0.9 );

#if defined _reapi_included
	SetThink( pEntity, "CHole__Think" );
#endif

	for ( new pVictim = 1, Vector3( vecVictimOrigin ); pVictim <= MaxClients; pVictim++ )
	{
		if ( !is_user_alive( pVictim ) || pVictim == pPlayer )
			continue;

	#if defined _zombieplague_included
		if ( !zp_get_user_zombie( pVictim ) )
	#else
		if ( IsSimilarPlayersTeam( pVictim, pPlayer ) )
	#endif
			continue;

		get_entvar( pVictim, var_origin, vecVictimOrigin );
		if ( xs_vec_distance( vecOrigin, vecVictimOrigin ) >= WeaponHoleRadius )
			continue;

		UTIL_PlayerKnockBack( pVictim, pPlayer, WeaponHoleKnockBack, 1.0 );
	}

	return pEntity;
}

public CHole__Think( const pEntity ) UTIL_KillEntity( pEntity );

public CHitBox__SpawnEntity( const pPlayer, const pInflictor, const Vector3( vecOrigin ), const bool: bBigSize )
{
	new pEntity = rg_create_entity( EntityGlobalReferences );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );
	engfunc( EngFunc_SetSize, pEntity, EntityHitBoxSize[ bBigSize ][ 0 ], EntityHitBoxSize[ bBigSize ][ 1 ] );

	set_entvar( pEntity, var_classname, EntityHitBoxClassName );
	set_entvar( pEntity, var_movetype, MOVETYPE_TOSS );
	set_entvar( pEntity, var_solid, SOLID_TRIGGER );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_dmg_inflictor, pInflictor );
	set_entvar( pEntity, var_nextthink, get_gametime( ) + EntityGlobalLifeTime );

#if defined _reapi_included
	SetThink( pEntity, "CHitBox__Think" );
	SetTouch( pEntity, "CHitBox__Touch" );
#endif

	return pEntity;
}

public CHitBox__Think( const pEntity ) UTIL_KillEntity( pEntity );
public CHitBox__Touch( const pEntity, const pTouch )
{
	if ( !IsUserValid( pTouch ) )
		return;

	static pOwner; pOwner = get_entvar( pEntity, var_owner );
	if ( pTouch == pOwner )
		return;

	if ( get_entvar( pTouch, var_takedamage ) == DAMAGE_NO )
		return;

#if defined _zombieplague_included
	if ( !zp_get_user_zombie( pTouch ) )
#else
	if ( IsSimilarPlayersTeam( pTouch, pOwner ) )
#endif
		return;

	if ( !CIceVictim__SpawnEntity( pTouch, pOwner, get_entvar( pEntity, var_dmg_inflictor ) ) )
		return;
}

public CIceVictim__SpawnEntity( const pVictim, const pAttacker, const pInflictor )
{
	new Float: flGameTime = get_gametime( );

	new pEntity = MaxClients;
	pEntity = fm_find_ent_by_owner( pEntity, EntityIceVictimClassName, pVictim );

	if ( !is_nullent( pEntity ) )
	{
		set_entvar( pEntity, var_renderamt, 255.0 );
		set_entvar( pEntity, var_ltime, flGameTime + WeaponIceVictimTime );

		return pEntity;
	}

	pEntity = rg_create_entity( EntityGlobalReferences );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	new Vector3( vecOrigin ); get_entvar( pVictim, var_origin, vecOrigin );

	if ( get_entvar( pVictim, var_flags ) & FL_DUCKING )
		vecOrigin[ 2 ] += 18.0;

	engfunc( EngFunc_SetModel, pEntity, EntityGlobalModel );
	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );
	engfunc( EngFunc_SetSize, pEntity, EntityIceSpikeSize[ 0 ], EntityIceSpikeSize[ 1 ] );

	set_entvar( pEntity, var_classname, EntityIceVictimClassName );
	set_entvar( pEntity, var_movetype, MOVETYPE_NOCLIP );
	set_entvar( pEntity, var_owner, pVictim );
	set_entvar( pEntity, var_enemy, pAttacker );
	set_entvar( pEntity, var_body, Entity_IceHit );
	set_entvar( pEntity, var_dmg_inflictor, pInflictor );
	set_entvar( pEntity, var_rendermode, kRenderTransAdd );
	set_entvar( pEntity, var_renderamt, 255.0 );
	set_entvar( pEntity, var_dmgtime, WeaponIceVictimDamageTime );
	set_entvar( pEntity, var_ltime, flGameTime + WeaponIceVictimTime );
	set_entvar( pEntity, var_nextthink, flGameTime + EntityIceVictimNextThink );

	new Float: flMaxSpeed; get_entvar( pVictim, var_maxspeed, flMaxSpeed );
	flMaxSpeed *= WeaponIceVictimSlowPower;
	set_entvar( pEntity, var_maxspeed, flMaxSpeed );

	UTIL_SetEntityAnim( pEntity, Entity_IceHit );

#if defined _reapi_included
	SetThink( pEntity, "CIceVictim__Think" );
#endif

	return pEntity;
}

public CIceVictim__Think( const pEntity )
{
	// Victim not valid
	static pVictim; pVictim = get_entvar( pEntity, var_owner );
	if ( !is_user_alive( pVictim ) )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	static pAttacker; pAttacker = get_entvar( pEntity, var_enemy );
#if defined _zombieplague_included
	if ( !zp_get_user_zombie( pVictim ) )
#else
	if ( IsSimilarPlayersTeam( pVictim, pAttacker ) )
#endif
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	static Float: flGameTime; flGameTime = get_gametime( );
	set_entvar( pEntity, var_nextthink, flGameTime + EntityIceVictimNextThink );

	// Move model
	static Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	static Vector3( vecVictimOrigin ); get_entvar( pVictim, var_origin, vecVictimOrigin );

	if ( get_entvar( pVictim, var_flags ) & FL_DUCKING )
		vecVictimOrigin[ 2 ] += 18.0;

	UTIL_GetSpeedVector( vecOrigin, vecVictimOrigin, 0.0, EntityIceVictimNextThink, vecOrigin );

	if ( xs_vec_len( vecOrigin ) > 0.0 )
		set_entvar( pEntity, var_velocity, vecOrigin );

	// Fade out destroy
	static Float: flLifeTime; get_entvar( pEntity, var_ltime, flLifeTime );
	if ( flLifeTime < flGameTime )
	{
		if ( CEntity_FadeDestroy( pEntity, 0.0 ) )
			rg_reset_maxspeed( pVictim );

		return;
	}

	// Update maxspeed (slowdown)
	static Float: flMaxSpeed; get_entvar( pEntity, var_maxspeed, flMaxSpeed );
	set_entvar( pVictim, var_maxspeed, flMaxSpeed );

	// Damage
	static Float: flDamageTime; get_entvar( pEntity, var_dmgtime, flDamageTime );
	if ( 0.0 < flDamageTime < flGameTime )
	{
		if ( !is_user_alive( pAttacker ) )
		{
			set_entvar( pEntity, var_dmgtime, 0.0 );
			return;
		}

	#if defined _zombieplague_included
		if ( zp_get_user_zombie( pAttacker ) )
		{
			set_entvar( pEntity, var_dmgtime, 0.0 );
			return;
		}
	#endif

		static pInflictor; pInflictor = get_entvar( pEntity, var_dmg_inflictor );
		if ( is_nullent( pInflictor ) )
			pInflictor = pEntity;

		set_member( pVictim, m_LastHitGroup, HIT_GENERIC );
		ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pAttacker, WeaponIceVictimDamage, WeaponIceVictimDamageType );

		set_entvar( pEntity, var_dmgtime, flGameTime + WeaponIceVictimDamageTime );
	}
}

#if defined _reapi_included
	public CGlobalEntity__Think( const pEntity ) CEntity_FadeDestroy( pEntity );
#endif

bool: CEntity_FadeDestroy( const pEntity, const Float: flNextThink = EntityGlobalFadeNextThink )
{
	static Float: flRenderAmt; get_entvar( pEntity, var_renderamt, flRenderAmt );
	if ( ( flRenderAmt -= EntityGlobalFadeAmount ) && flRenderAmt <= EntityGlobalFadeAmount )
	{
		UTIL_KillEntity( pEntity );
		return true;
	}

	set_entvar( pEntity, var_renderamt, flRenderAmt );

	if ( flNextThink > 0.0 )
		set_entvar( pEntity, var_nextthink, get_gametime( ) + flNextThink );

	return false;
}

CWeapon_GetChargeLevel( const pItem, const pPlayer )
{
#if defined WeaponListDir
	#pragma unused pItem

	return GetWeaponAmmo( pPlayer, WeaponPrimaryAmmoIndex );
#else
	#pragma unused pPlayer

	return get_entvar( pItem, var_charge_level );
#endif
}

bool: CWeapon_SetChargeLevel( const pItem, const pPlayer, const iValue )
{
#if defined WeaponListDir
	#pragma unused pItem

	SetWeaponAmmo( pPlayer, iValue, WeaponPrimaryAmmoIndex );
#else
	#pragma unused pPlayer

	set_entvar( pItem, var_charge_level, iValue );
	client_print( pPlayer, print_center, PrintMessagePattern, iValue );
#endif
	
	return true;
}

/* ~ [ Stocks ] ~ */
stock UTIL_FakeTraceLine( const pPlayer, const pItem, const Float: flSendAngles[ 5 ], const Float: flDistance, const Float: flDamage = 0.0, const Float: flKnockBack = 0.0, const bitsDamageType = DMG_GENERIC, &iHitCount )
{
	new bitsHitResult, bitsVictims;
	new Vector3( vecStart ); UTIL_GetEyePosition( pPlayer, vecStart );

#if AMXX_VERSION_NUM >= 183
	new Array: arEntityVictims = ArrayCreate( .reserved = 1 );
#endif

	new Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	new Vector3( vecForward ), Vector3( vecRight ), Vector3( vecUp );
	engfunc( EngFunc_AngleVectors, vecViewAngle, vecForward, vecRight, vecUp );

	new Float: flTan, Vector3( vecEnd );
	new pTrace = create_tr2( ), pHit, Float: flFraction;

	for ( new i; i < floatround( flSendAngles[ 0 ] ); i++ )
	{
		flTan = floattan( flSendAngles[ 1 ] + ( flSendAngles[ 2 ] * i ), degrees );
		vecEnd[ 0 ] = ( vecForward[ 0 ] * flDistance ) + ( vecRight[ 0 ] * flTan * flDistance );
		vecEnd[ 1 ] = ( vecForward[ 1 ] * flDistance ) + ( vecRight[ 1 ] * flTan * flDistance );
		vecEnd[ 2 ] = ( vecForward[ 2 ] * flDistance ) + ( vecRight[ 2 ] * flTan * flDistance );

		if ( flSendAngles[ 3 ] )
			xs_vec_add_scaled( vecEnd, vecUp, flSendAngles[ 3 ] + ( flSendAngles[ 4 ] * i ), vecEnd );

		xs_vec_add_scaled( vecStart, vecEnd, flDistance / xs_vec_len( vecEnd ), vecEnd );

		engfunc( EngFunc_TraceLine, vecStart, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTrace );
		get_tr2( pTrace, TR_flFraction, flFraction );

		if ( flFraction == 1.0 )
		{
			BIT_ADD( bitsHitResult, HitResult_None );
			continue;
		}
		
		pHit = get_tr2( pTrace, TR_pHit );

		if ( is_nullent( pHit ) )
		{
			BIT_ADD( bitsHitResult, HitResult_World );
			continue;
		}

		BIT_ADD( bitsHitResult, HitResult_Entity );

		if ( IsUserValid( pHit ) )
		{
			if ( BIT_VALID( bitsVictims, BIT_PLAYER( pHit ) ) )
				continue;
		}
	#if AMXX_VERSION_NUM >= 183
		else
		{
			if ( ArrayFindValue( arEntityVictims, pHit ) != -1 )
				continue;

			ArrayPushCell( arEntityVictims, pHit );
		}
	#endif

		if ( flDamage )
		{
		#if defined _reapi_included
			rg_multidmg_clear( );
			ExecuteHamB( Ham_TraceAttack, pHit, pPlayer, flDamage * ( 1.0 - floatmin( flFraction, 0.7 ) ), vecForward, pTrace, bitsDamageType );
			rg_multidmg_apply( pItem, pPlayer );
		#else
			UTIL_FakeTraceAttack( pHit, pItem, pPlayer, flDamage * ( 1.0 - floatmin( flFraction, 0.7 ) ), vecForward, pTrace, bitsDamageType );
		#endif
		}

		if ( is_user_alive( pHit ) )
		{
			BIT_ADD( bitsVictims, BIT_PLAYER( pHit ) );

		#if defined _zombieplague_included
			if ( zp_get_user_zombie( pHit ) )
		#else
			if ( !IsSimilarPlayersTeam( pHit, pPlayer ) )
		#endif
			{
				if ( flKnockBack )
					UTIL_PlayerKnockBack( pHit, pPlayer, flKnockBack, 1.0 );

				get_entvar( pHit, var_origin, vecEnd );

				static iFrameRate; if ( !iFrameRate ) iFrameRate = floatround( gl_iszModelIndex[ ModelIndex_Hit_Victim ] / Float: WeaponHitSpriteFrameRate );
				UTIL_TE_EXPLOSION( MSG_BROADCAST, gl_iszModelIndex[ ModelIndex_Hit_Victim ], vecEnd, 0.0, WeaponHitSpriteScale, iFrameRate );

				iHitCount++;
			}
		}
	}

#if AMXX_VERSION_NUM >= 183
	ArrayDestroy( arEntityVictims );
#endif
	free_tr2( pTrace );

	return bitsHitResult;
}

#if !defined _reapi_included
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
		static Vector3( vecEndPos ); get_tr2( pTrace, TR_vecEndPos, vecEndPos );
		static iHitGroup; iHitGroup = get_tr2( pTrace, TR_iHitgroup );
		static Float: flDamage; flDamage = flBaseDamage;

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

/* -> Get player eye position <- */
stock UTIL_GetEyePosition( const pPlayer, Vector3( vecEyeLevel ) )
{
	new Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	new Vector3( vecViewOfs ); get_entvar( pPlayer, var_view_ofs, vecViewOfs );

	xs_vec_add( vecOrigin, vecViewOfs, vecEyeLevel );
}

/* -> Drop Vector to floor <- */
stock UTIL_DropVectorToFloor( Vector3( vecOrigin ) )
{
	new Vector3( vecStart ); xs_vec_copy( vecOrigin, vecStart );
	vecOrigin[ 2 ] = -4096.0;

	engfunc( EngFunc_TraceLine, vecStart, vecOrigin, IGNORE_MONSTERS, 0, 0 );
	get_tr2( 0, TR_vecEndPos, vecOrigin );
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

/* -> Player KnockBack <- */
stock UTIL_PlayerKnockBack( const pVictim, const pAttacker, const Float: flForce, const Float: flVelocityModifier = 0.0 )
{
	new Vector3( vecOrigin ); get_entvar( pVictim, var_origin, vecOrigin );
	new Vector3( vecVelocity ); get_entvar( pVictim, var_velocity, vecVelocity );
	new Vector3( vecAttackerOrigin ); get_entvar( pAttacker, var_origin, vecAttackerOrigin );
	new Vector3( vecDirection ); xs_vec_sub( vecOrigin, vecAttackerOrigin, vecDirection );
	new Float: flLen = xs_vec_len_2d( vecDirection );

	for ( new i = 0; i < 2; ++i )
		vecVelocity[ i ] = ( vecDirection[ i ] / flLen ) * flForce;

	set_entvar( pVictim, var_velocity, vecVelocity );

	if ( flVelocityModifier )
		set_member( pVictim, m_flVelocityModifier, flVelocityModifier );
}

/* -> Get speed Vector to 2 points <- */
stock UTIL_GetSpeedVector( const Vector3( vecStartOrigin ), const Vector3( vecEndOrigin ), Float: flSpeed = 0.0, Float: flTime = 1.0, Vector3( vecVelocity ) )
{
	if ( !flSpeed )
		flSpeed = xs_vec_distance( vecStartOrigin, vecEndOrigin ) / flTime;
	else flSpeed /= flTime;

	xs_vec_sub( vecEndOrigin, vecStartOrigin, vecVelocity );
	xs_vec_normalize( vecVelocity, vecVelocity );
	xs_vec_mul_scalar( vecVelocity, flSpeed, vecVelocity );
}

/* -> Get Edge of two Vectors <- */
stock bool: UTIL_GetEdgeOfVectors( const Vector3( vecIn1 ), const Vector3( vecIn2 ), Vector3( vecOutPut ) )
{
	new pTrace = create_tr2( );
	new Vector3( vecTemp ), Float: flFraction;
	new Float: flUpNow, Float: flUpStart;
	flUpStart = flUpNow = vecIn1[ 2 ];

	xs_vec_copy( vecIn2, vecTemp );

	while ( ( ( flUpStart - flUpNow ) < 256.0 ) )
	{
		engfunc( EngFunc_TraceLine, vecIn1, vecTemp, IGNORE_MONSTERS, 0, pTrace );
		get_tr2( pTrace, TR_flFraction, flFraction );

		if ( flFraction != 1.0 )
		{
			get_tr2( pTrace, TR_vecEndPos, vecOutPut );
			free_tr2( pTrace );
			
			return true;
		}

		flUpNow -= 8.0;
		vecTemp[ 2 ] = flUpNow
	}

	free_tr2( pTrace );
	return false;
}

/* -> Destroy All Entities by ClassName <- */
stock UTIL_DestroyEntitiesByClass( const szClassName[ ] )
{
	new pEntity = MaxClients;
	while ( ( pEntity = fm_find_ent_by_class( pEntity, szClassName ) ) > 0 )
		UTIL_KillEntity( pEntity );
}

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity )
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );
}

/* -> TE_DLIGHT <- */
stock UTIL_TE_DLIGHT( const iDest, const Vector3( vecOrigin ), const iRadius, const iColor[ 3 ], const iLife, const iDecayRate )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_DLIGHT );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_byte( iRadius ); // Radius 
	write_byte( iColor[ 0 ] ); // Red
	write_byte( iColor[ 1 ] ); // Green
	write_byte( iColor[ 2 ] ); // Blue
	write_byte( iLife ); // Life in 0.1's
	write_byte( iDecayRate ); // Decay rate 
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
