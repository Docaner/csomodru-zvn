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
#include <zpe_knokcback>

/* ~ [ Extra Item ] ~ */
new const EXTRA_ITEM_NAME[ ] = 			"AK-47 Paladin";
const EXTRA_ITEM_COST = 				0;

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
//#define DYNAMIC_CROSSHAIR

const WEAPON_SPECIAL_CODE =				22022022;
new const WEAPON_REFERENCE[ ] = 		"weapon_aug";
new const WEAPON_CONFIG_NAME[ ] = 		"weapon_ak47_paladin";
#if defined CUSTOM_WEAPONLIST
	new const WEAPON_WEAPONLIST[ ] = 	"x/weapon_buffak";
#endif
new const WEAPON_ANIMATION[ ] = 		"ak47";
new const WEAPON_NATIVE[ ] = 			"zp_give_user_buffak";
new const WEAPON_MODEL_VIEW[ ] = 		"models/x/v_buffak.mdl";
new const WEAPON_MODEL_PLAYER[ ] = 		"models/x/p_buffak.mdl";
new const WEAPON_MODEL_WORLD[ ] = 		"models/x/w_buffak.mdl";
#if defined EJECT_BRASS
	new const WEAPON_MODEL_SHELL[ ] = 	"models/rshell.mdl";
#endif
new const WEAPON_SOUNDS[ ][ ] =
{
	"weapons/ak47buff-1.wav",
	"weapons/ak47buff-2.wav",
};

const WEAPON_MODEL_WORLD_BODY = 		0;
const Bullet: WEAPON_BULLET_TYPE = 		BULLET_PLAYER_762MM;

/* ~ [ Entity: Blast ] ~ */
new const ENTITY_BLAST_CLASSNAME[ ] =	"ent_paladin_blast";
new const ENTITY_BLAST_SPRITE[ ] =		"sprites/x/ef_buffak_projectile1.spr";
new const ENTITY_BLAST_EXP_SPRITE[ ] =	"sprites/x/ef_buffak_hit.spr";
new const ENTITY_BLAST_EXP_SOUND[ ] =	"weapons/coilmg_exp1.wav";

/* ~ [ Weapon Animations ] ~ */
enum _: eWeaponAnimList {
	eWeaponAnim_Idle = 0,
	eWeaponAnim_Reload,
	eWeaponAnim_Draw,
	eWeaponAnim_Shoot1,
	eWeaponAnim_Shoot2,
	eWeaponAnim_Shoot3
};

#define flWeaponAnim_Idle_Time 			( 91 / 30.0 )
#define flWeaponAnim_Reload_Time 		( 61 / 30.0 )
#define flWeaponAnim_Draw_Time 			( 31 / 30.0 ) + 0.2
#define flWeaponAnim_Shoot_Time 		( 31 / 30.0 )

/* ~ [ Params ] ~ */
new gl_iItemId;
#if defined EJECT_BRASS
	new gl_iszModelIndex_Shell;
#endif
new gl_iszModelIndex_BlastExplode;
new HookChain: gl_HookChain_TakeDamage_Pre, HamHook: gl_HamHook_TakeDamage_Post,
	HookChain: gl_HookChain_IsPenetrableEntity_Post;

enum eCvars {
	eCvar_iMaxClip,
	eCvar_iDefaultAmmo,
	eCvar_iDamage,
	Float: eCvar_flRadiusMode,
	Float: eCvar_flDamageMode,
	Float: eCvar_flKnockBackMode,
	Float: eCvar_flSpeedMode,
	eCvar_iPenetration,
	Float: eCvar_flRate,
	Float: eCvar_flRateMode,
	Float: eCvar_flAccuracy,
	Float: eCvar_flRangeModifer,
	Float: eCvar_flShootDistance
};
new gl_pCvars[ eCvars ];

/* ~ [ Macroses ] ~ */
#define DEFAULT_FOV							90
#define Vector3(%0) 						Float: %0[ 3 ]
#define IsCustomWeapon(%0,%1)				bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponClip(%0)					get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)				set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)				get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)				get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)				set_member( %0, m_rgAmmo, %1, %2 )
#define PlayerInDefaultFOV(%0)				( get_member( %0, m_iFOV ) == DEFAULT_FOV )

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( ) register_native( WEAPON_NATIVE, "Native_GiveWeapon" );

public plugin_precache( ) 
{
	new i;

	/* -> Precache Models -> */
	engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_VIEW );
	engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER );
	engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_WORLD );
	engfunc( EngFunc_PrecacheModel, ENTITY_BLAST_SPRITE );

	gl_iszModelIndex_BlastExplode = engfunc( EngFunc_PrecacheModel, ENTITY_BLAST_EXP_SPRITE );

	#if defined EJECT_BRASS
		gl_iszModelIndex_Shell = engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_SHELL );
	#endif
	
	/* -> Precache Sounds -> */
	for ( i = 0; i < sizeof WEAPON_SOUNDS; i++ )
		engfunc( EngFunc_PrecacheSound, WEAPON_SOUNDS[ i ] );

	engfunc( EngFunc_PrecacheSound, ENTITY_BLAST_EXP_SOUND );

	#if defined CUSTOM_WEAPONLIST
		/* -> Hook Weapon -> */
		register_clcmd( WEAPON_WEAPONLIST, "Command_HookWeapon" );

		UTIL_PrecacheWeaponList( WEAPON_WEAPONLIST );
	#endif
}

public plugin_init( ) 
{
	register_plugin( "[ZP] Weapon: AK-47 Paladin", "1.0 (ReAPI)", "Yoshioka Haruki" );

	/* -> Fakemeta -> */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

	/* -> ReAPI -> */
	RegisterHookChain( RG_CWeaponBox_SetModel, "CWeaponBox__SetModel_Pre", false );
	DisableHookChain( gl_HookChain_TakeDamage_Pre = RegisterHookChain( RG_CBasePlayer_TakeDamage, "CBasePlayerWeapon__TakeDamage_Pre", false ) );
	DisableHamForward( gl_HamHook_TakeDamage_Post = RegisterHam( Ham_TakeDamage, "player", "CBasePlayerWeapon__TakeDamage_Post", true ) );
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

public plugin_cfg( )
{
	bind_pcvar_num( create_cvar( "wpn_ak_paladin_max_clip", "30", FCVAR_NONE, "Кол-во патрон в магазине", true, 1.0 ),
		gl_pCvars[ eCvar_iMaxClip ] );

	bind_pcvar_num( create_cvar( "wpn_ak_paladin_default_ammo", "150", FCVAR_NONE, "Кол-во патрон в запасе", true, 1.0 ),
		gl_pCvars[ eCvar_iDefaultAmmo ] );

	bind_pcvar_num( create_cvar( "wpn_ak_paladin_damage", "38.0", FCVAR_NONE, "Урон" ),
		gl_pCvars[ eCvar_iDamage ] );

	bind_pcvar_float( create_cvar( "wpn_ak_paladin_radius_mode", "150.0", FCVAR_NONE, "Радиус урона во втором режиме" ),
		gl_pCvars[ eCvar_flRadiusMode ] );

	bind_pcvar_float( create_cvar( "wpn_ak_paladin_damage_mode", "320.0", FCVAR_NONE, "Урон во втором режиме" ),
		gl_pCvars[ eCvar_flDamageMode ] );

	bind_pcvar_float( create_cvar( "wpn_ak_paladin_knockback_mode", "750.0", FCVAR_NONE, "Сила отталкивания во втором режиме" ),
		gl_pCvars[ eCvar_flKnockBackMode ] );

	bind_pcvar_float( create_cvar( "wpn_ak_paladin_speed_mode", "1900.0", FCVAR_NONE, "Скорость полета взрыва во втором режиме" ),
		gl_pCvars[ eCvar_flSpeedMode ] );

	bind_pcvar_num( create_cvar( "wpn_ak_paladin_penetration", "2", FCVAR_NONE, "Кол-во простреливаний", true, 1.0 ),
		gl_pCvars[ eCvar_iPenetration ] );

	bind_pcvar_float( create_cvar( "wpn_ak_paladin_rate", "0.105", FCVAR_NONE, "Скорость стрельбы" ),
		gl_pCvars[ eCvar_flRate ] );

	bind_pcvar_float( create_cvar( "wpn_ak_paladin_rate_mode", "0.5", FCVAR_NONE, "Скорость стрельбы во втором режиме" ),
		gl_pCvars[ eCvar_flRateMode ] );

	bind_pcvar_float( create_cvar( "wpn_ak_paladin_accuracy", "0.2", FCVAR_NONE, "Точность оружия", true, 0.0, true, 1.0 ),
		gl_pCvars[ eCvar_flAccuracy ] );

	bind_pcvar_float( create_cvar( "wpn_ak_paladin_range_modifer", "0.98", FCVAR_NONE, "Модификатор диапазона (Изменение урона от диапазона)" ),
		gl_pCvars[ eCvar_flRangeModifer ] );

	bind_pcvar_float( create_cvar( "wpn_ak_paladin_shoot_distance", "8192.0", FCVAR_NONE, "Максимальная дистанция выстрела", true, 256.0, true, 8192.0 ),
		gl_pCvars[ eCvar_flShootDistance ] );

	AutoExecConfig( true, WEAPON_CONFIG_NAME, "custom_weapons" );
}

public bool: Native_GiveWeapon( ) 
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !is_user_alive( pPlayer ) )
		return false;
	
	return UTIL_GiveCustomWeapon( pPlayer, WEAPON_REFERENCE, WEAPON_SPECIAL_CODE, gl_pCvars[ eCvar_iDefaultAmmo ] );
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

	return UTIL_GiveCustomWeapon( pPlayer, WEAPON_REFERENCE, WEAPON_SPECIAL_CODE, gl_pCvars[ eCvar_iDefaultAmmo ] );
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
	if ( !is_user_alive( pPlayer ) )
		return;

	static pActiveItem; pActiveItem = get_member( pPlayer, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WEAPON_SPECIAL_CODE ) )
		return;

	set_cd( CD_Handle, CD_flNextAttack, 2.0 );
}

/* ~ [ ReAPI ] ~ */
public CWeaponBox__SetModel_Pre( const pWeaponBox, const szModel[ ] ) 
{
	if ( !IsCustomWeapon( UTIL_GetWeaponBoxItem( pWeaponBox ), WEAPON_SPECIAL_CODE ) )
		return HC_CONTINUE;

	SetHookChainArg( 2, ATYPE_STRING, WEAPON_MODEL_WORLD );
	set_entvar( pWeaponBox, var_body, WEAPON_MODEL_WORLD_BODY );

	return HC_CONTINUE;
}

public CBasePlayerWeapon__TakeDamage_Pre( const pVictim, const pInflictor, const pAttacker, const Float: flDamage )
{
	if ( is_nullent( pInflictor ) || !IsCustomWeapon( pInflictor, WEAPON_SPECIAL_CODE ) )
	{
		SetHookChainReturn( ATYPE_INTEGER, 0 );
		return HC_SUPERCEDE;
	}

	if ( pVictim == pAttacker || is_nullent( pAttacker ) )
	{
		SetHookChainReturn( ATYPE_INTEGER, 0 );
		return HC_SUPERCEDE;
	}

	if ( !zp_get_user_zombie( pVictim ) || get_member( pVictim, m_iTeam ) == get_member( pAttacker, m_iTeam ) )
	{
		SetHookChainReturn( ATYPE_INTEGER, 0 );
		return HC_SUPERCEDE;
	}
	
	//UTIL_FakeKnockBack( pAttacker, pVictim, gl_pCvars[ eCvar_flKnockBackMode ] );
	return HC_CONTINUE;
}

public CBasePlayerWeapon__TakeDamage_Post( const pVictim, const pInflictor, const pAttacker, const Float: flDamage, iBitDamage )
{
	if ( is_nullent( pInflictor ) || !IsCustomWeapon( pInflictor, WEAPON_SPECIAL_CODE ) )
	{
		//SetHookChainReturn( ATYPE_INTEGER, 0 );
		return HAM_IGNORED;
	}

	if ( pVictim == pAttacker || is_nullent( pAttacker ) )
	{
		//SetHookChainReturn( ATYPE_INTEGER, 0 );
		return HAM_IGNORED;
	}

	if ( !zp_get_user_zombie( pVictim ) || get_member( pVictim, m_iTeam ) == get_member( pAttacker, m_iTeam ) )
	{
		//SetHookChainReturn( ATYPE_INTEGER, 0 );
		return HAM_IGNORED;
	}
	
	if(~iBitDamage & DMG_CLUB)
		zp_set_user_knock_by_missile(pVictim, pAttacker, 260.0, 3.75);
	
	//UTIL_FakeKnockBack( pAttacker, pVictim, gl_pCvars[ eCvar_flKnockBackMode ] );
	return HAM_IGNORED;
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
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return;

	SetWeaponClip( pItem, gl_pCvars[ eCvar_iMaxClip ] );
	set_member( pItem, m_Weapon_iDefaultAmmo, gl_pCvars[ eCvar_iDefaultAmmo ] );
	set_member( pItem, m_Weapon_bHasSecondaryAttack, true );

	#if defined CUSTOM_WEAPONLIST
		rg_set_iteminfo( pItem, ItemInfo_pszName, WEAPON_WEAPONLIST );
	#endif
	rg_set_iteminfo( pItem, ItemInfo_iMaxClip, gl_pCvars[ eCvar_iMaxClip ] );
	rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, gl_pCvars[ eCvar_iDefaultAmmo ] );

	set_entvar( pItem, var_netname, EXTRA_ITEM_NAME );
}

public CBasePlayerWeapon__Deploy_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	set_entvar( pPlayer, var_viewmodel, WEAPON_MODEL_VIEW );
	set_entvar( pPlayer, var_weaponmodel, WEAPON_MODEL_PLAYER );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, eWeaponAnim_Draw );

	set_member( pItem, m_Weapon_flAccuracy, gl_pCvars[ eCvar_flAccuracy ] );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flWeaponAnim_Draw_Time );
	set_member( pPlayer, m_flNextAttack, flWeaponAnim_Draw_Time );
	set_member( pPlayer, m_szAnimExtention, WEAPON_ANIMATION );
}

public CBasePlayerWeapon__Holster_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );
	
	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

#if defined CUSTOM_WEAPONLIST
	public CBasePlayerWeapon__AddToPlayer_Post( const pItem, const pPlayer ) 
	{
		new iWeaponUId = get_entvar( pItem, var_impulse );
		if ( iWeaponUId != 0 && iWeaponUId != WEAPON_SPECIAL_CODE )
			return;

		UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
	}
#endif

#if defined DYNAMIC_CROSSHAIR
	public CBasePlayerWeapon__PostFrame_Pre( const pItem ) 
	{
		if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
			return HAM_IGNORED;

		new pPlayer = get_member( pItem, m_pPlayer );

		UTIL_ResetCrosshair( pPlayer, pItem );
		return HAM_IGNORED;
	}
#endif

public CBasePlayerWeapon__Reload_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
		return;

	if ( GetWeaponClip( pItem ) >= rg_get_iteminfo( pItem, ItemInfo_iMaxClip ) )
		return;

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, eWeaponAnim_Reload );

	set_member( pPlayer, m_flNextAttack, flWeaponAnim_Reload_Time );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flWeaponAnim_Reload_Time );
}

public CBasePlayerWeapon__WeaponIdle_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) || get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, eWeaponAnim_Idle );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flWeaponAnim_Idle_Time );

	return HAM_SUPERCEDE;
}

public CBasePlayerWeapon__PrimaryAttack_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
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
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, random_num( eWeaponAnim_Shoot1, eWeaponAnim_Shoot3 ) );
	rg_set_animation( pPlayer, PLAYER_ATTACK1 );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WEAPON_SOUNDS[ PlayerInDefaultFOV( pPlayer ) ? 0 : 1 ] );

	new bitsFlags = get_entvar( pPlayer, var_flags );
	new Vector3( vecVelocity ); get_entvar( pPlayer, var_velocity, vecVelocity );
	new Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	new Vector3( vecViewOfs ); get_entvar( pPlayer, var_view_ofs, vecViewOfs );
	new Vector3( vecSrc ); xs_vec_add( vecOrigin, vecViewOfs, vecSrc );

	if ( PlayerInDefaultFOV( pPlayer ) )
	{
		new iShotsFired = get_member( pItem, m_Weapon_iShotsFired ); iShotsFired++;
		new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );
		new Float: flAccuracy = get_member( pItem, m_Weapon_flAccuracy );
		new Float: flSpread;

		if ( ~bitsFlags & FL_ONGROUND )
			flSpread = 0.04 + ( 0.4 * flAccuracy );
		else if ( xs_vec_len_2d( vecVelocity ) > 140.0 )
			flSpread = 0.04 + ( 0.07 * flAccuracy );
		else flSpread = 0.0275 * flAccuracy;

		if ( flAccuracy ) 
			flAccuracy = floatmin( ( ( iShotsFired * iShotsFired * iShotsFired ) / 200.0 ) + 0.35, 1.25 );

		EnableHookChain( gl_HookChain_IsPenetrableEntity_Post );
		rg_fire_bullets3( pItem, pPlayer, vecSrc, vecAiming, flSpread, gl_pCvars[ eCvar_flShootDistance ], gl_pCvars[ eCvar_iPenetration ], WEAPON_BULLET_TYPE, gl_pCvars[ eCvar_iDamage ], gl_pCvars[ eCvar_flRangeModifer ], false, get_member( pPlayer, random_seed ) );
		DisableHookChain( gl_HookChain_IsPenetrableEntity_Post );

		set_member( pItem, m_Weapon_flAccuracy, flAccuracy );
		set_member( pItem, m_Weapon_iShotsFired, iShotsFired );
		
		SetWeaponClip( pItem, --iClip );
	}
	else 
	{
		CBlast__SpawnEntity( pPlayer, pItem, vecSrc );
		iClip -= 3;
		SetWeaponClip( pItem, iClip > 0 ? iClip : 0 );
	}

	if ( xs_vec_len_2d( vecVelocity ) > 0 ) 
		UTIL_WeaponKickBack( pItem, pPlayer, 1.5, 0.45, 0.225, 0.05, 6.5, 2.5, 7 );
	else if ( ~bitsFlags & FL_ONGROUND ) 
		UTIL_WeaponKickBack( pItem, pPlayer, 2.0, 1.0, 0.5, 0.35, 9.0, 6.0, 5 );
	else if ( bitsFlags & FL_DUCKING ) 
		UTIL_WeaponKickBack( pItem, pPlayer, 0.9, 0.35, 0.15, 0.025, 5.5, 1.5, 9 );
	else
		UTIL_WeaponKickBack( pItem, pPlayer, 1.0, 0.375, 0.175, 0.0375, 5.75, 1.75, 8 );

	#if defined EJECT_BRASS
		set_member( pItem, m_Weapon_iShellId, gl_iszModelIndex_Shell );
		set_member( pPlayer, m_flEjectBrass, get_gametime( ) );
	#endif

	set_member( pItem, m_Weapon_flNextPrimaryAttack, gl_pCvars[ PlayerInDefaultFOV( pPlayer ) ? eCvar_flRate : eCvar_flRateMode ] );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, gl_pCvars[ PlayerInDefaultFOV( pPlayer ) ? eCvar_flRate : eCvar_flRateMode ] );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flWeaponAnim_Shoot_Time );

	return HAM_SUPERCEDE;
}

public CBasePlayerWeapon__SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );

	set_member( pPlayer, m_iFOV, PlayerInDefaultFOV( pPlayer ) ? 85 : DEFAULT_FOV );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, 0.3 );

	return HAM_SUPERCEDE;
}

public CBlast__SpawnEntity( const pPlayer, const pItem, Vector3( vecSrc ) )
{
	new pEntity = rg_create_entity( "info_target" );

	if ( is_nullent( pEntity ) )
		return NULLENT;

	new Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	new Vector3( vecForward ); angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecForward );
	new Vector3( vecVelocity ); xs_vec_copy( vecForward, vecVelocity );

	xs_vec_mul_scalar( vecForward, 20.0, vecForward );
	xs_vec_add( vecSrc, vecForward, vecSrc );
	xs_vec_mul_scalar( vecVelocity, gl_pCvars[ eCvar_flSpeedMode ], vecVelocity );

	set_entvar( pEntity, var_classname, ENTITY_BLAST_CLASSNAME );
	set_entvar( pEntity, var_solid, SOLID_TRIGGER );
	set_entvar( pEntity, var_movetype, MOVETYPE_FLY );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_dmg_inflictor, pItem );
	set_entvar( pEntity, var_scale, random_float( 0.05, 0.1 ) );
	set_entvar( pEntity, var_rendermode, kRenderTransAdd );
	set_entvar( pEntity, var_renderamt, 255.0 );
	set_entvar( pEntity, var_velocity, vecVelocity );
	set_entvar( pEntity, var_origin, vecSrc );

	engfunc( EngFunc_SetModel, pEntity, ENTITY_BLAST_SPRITE );
	engfunc( EngFunc_SetSize, pEntity, Float: { -1.0, -1.0, -1.0 }, Float: { 1.0, 1.0, 1.0 } );

	SetTouch( pEntity, "CBlast__Touch" );

	return pEntity;
}

public CBlast__Touch( const pEntity, const pTouch )
{
	if ( is_nullent( pEntity ) )
		return;

	new pOwner = get_entvar( pEntity, var_owner );
	if ( !is_user_alive( pOwner ) || zp_get_user_zombie( pOwner ) )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	if ( pTouch == pOwner || FClassnameIs( pTouch, ENTITY_BLAST_CLASSNAME ) )
		return;

	/* По тимейтам не ебашит */
	if(is_user_connected(pTouch) && !zp_get_user_zombie(pTouch))
		return;

	new pInflictor = get_entvar( pEntity, var_dmg_inflictor );
	if ( is_nullent( pInflictor ) || !IsCustomWeapon( pInflictor, WEAPON_SPECIAL_CODE ) )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	new Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	if ( engfunc( EngFunc_PointContents, vecOrigin ) == CONTENTS_SKY )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	EnableHookChain( gl_HookChain_TakeDamage_Pre );
	EnableHamForward( gl_HamHook_TakeDamage_Post );
	rg_dmg_radius( vecOrigin, pInflictor, pOwner, gl_pCvars[ eCvar_flDamageMode ], gl_pCvars[ eCvar_flRadiusMode ], 0, DMG_CLUB );
	DisableHookChain( gl_HookChain_TakeDamage_Pre );
	DisableHamForward( gl_HamHook_TakeDamage_Post );

	message_begin_f( MSG_PVS, SVC_TEMPENTITY, vecOrigin );
	UTIL_TE_EXPLOSION( gl_iszModelIndex_BlastExplode, vecOrigin, 0.0, 8, 48 );

	rh_emit_sound2( pEntity, 0, CHAN_ITEM, ENTITY_BLAST_EXP_SOUND );

	UTIL_KillEntity( pEntity );
}

/* ~ [ Stocks ] ~ */

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity ) 
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );

	SetTouch( pEntity, "" );
	SetThink( pEntity, "" );
}

/* -> Weapon Animation <- */
stock UTIL_SendWeaponAnim( const iDest, const pPlayer, const pItem, const iAnim ) 
{
	set_entvar( pPlayer, var_weaponanim, iAnim );

	message_begin( iDest, SVC_WEAPONANIM, .player = pPlayer );
	write_byte( iAnim );
	write_byte( get_entvar( pItem, var_body ) );
	message_end( );

	if ( get_entvar( pPlayer, var_iuser1 ) )
		return;

	static i, iCount, pSpectator, iszSpectators[ MAX_PLAYERS ];
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
		write_byte( get_entvar( pItem, var_body ) );
		message_end( );
	}
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

/* -> Fake KnockBack <- */
stock UTIL_FakeKnockBack( const pAttacker, const pVictim, Float: flKnockBack )
{
	if ( get_entvar( pVictim, var_flags ) & FL_DUCKING )
		flKnockBack *= 0.7;

	static Vector3( vecViewAngle ); get_entvar( pAttacker, var_v_angle, vecViewAngle );
	static Vector3( vecForward ); angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecForward );
	xs_vec_mul_scalar( vecForward, gl_pCvars[ eCvar_flKnockBackMode ], vecForward );

	static Vector3( vecVelocity ); get_entvar( pVictim, var_velocity, vecVelocity );
	xs_vec_add_scaled( vecVelocity, vecForward, flKnockBack, vecVelocity );

	set_entvar( pVictim, var_velocity, vecForward );
	set_member( pVictim, m_flVelocityModifier, 1.0 );
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

/* -> TE_EXPLOSION <- */
stock UTIL_TE_EXPLOSION( const iszModelIndex, const Float: vecOrigin[ 3 ], const Float: flUp, const iScale, const iFramerate, const iFlags = TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES )
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
