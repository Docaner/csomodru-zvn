#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <reapi>
#include <xs>

/* ~ [ Extra Item ] ~ */
new const WEAPON_ITEM_NAME[ ] = 		"RPG-7";
const WEAPON_ITEM_COST = 				0;

/* ~ [ Weapon Settings ] ~ */
const WEAPON_SPECIAL_CODE = 			45112854;
new const WEAPON_REFERENCE[ ] = 		"weapon_aug";
new const WEAPON_WEAPONLIST[ ] = 		"x/weapon_rpg7";
new const WEAPON_MODEL_VIEW[ ] = 		"models/x/v_rpg7.mdl";
new const WEAPON_MODEL_PLAYER[ ] = 		"models/x/p_rpg7.mdl";
new const WEAPON_MODEL_WORLD[ ] = 		"models/x/w_rpg7.mdl";
new const WEAPON_SOUND_SHOOT[ ] = 		"weapons/rpg7_shoot.wav";

const WEAPON_MODEL_WORLD_BODY = 		0;

const WEAPON_MAX_CLIP = 				1;
const WEAPON_DEFAULT_AMMO = 			5;
const Float: WEAPON_RATE = 				0.85;
const Float: WEAPON_PUNCHANGLE = 		0.98;
const Float: WEAPON_DAMAGE = 			1.13;

/* ~ [ Entity: Rocket ] ~ */
new const ENTITY_ROCKET_CLASSNAME[ ] =	"ent_rpg7_rocket";
new const ENTITY_ROCKET_MODEL[ ] = 		"models/x/s_rpg7.mdl";
new const ENTITY_ROCKET_SOUND[ ] = 		"weapons/explode3.wav";
const Float: ENTITY_ROCKET_SPEED = 		1500.0;
const Float: ENTITY_ROCKET_DAMAGE = 	1000.0;
const Float: ENTITY_ROCKET_RADIUS = 	200.0;
const ENTITY_ROCKET_DMGTYPE = 			( DMG_GRENADE | DMG_NEVERGIB );

new const WEAPON_MODEL_INDEX[ ][ ] = {
	"sprites/laserbeam.spr",
	"sprites/fexplo.spr"
};

/* ~ [ Weapon Animations ] ~ */
enum _: eAnimList
{
	WEAPON_ANIM_IDLE = 0,
	WEAPON_ANIM_IDLE2,
	WEAPON_ANIM_IDLE_EMPTY,
	WEAPON_ANIM_IDLE2_EMPTY,
	WEAPON_ANIM_SHOOT,
	WEAPON_ANIM_SHOOT2,
	WEAPON_ANIM_RELOAD,
	WEAPON_ANIM_DRAW,
	WEAPON_ANIM_DRAW_EMPTY,
	WEAPON_ANIM_CHANGE1,
	WEAPON_ANIM_CHANGE2
};

#define WEAPON_ANIM_IDLE_TIME 		( 51 / 30.0 )
#define WEAPON_ANIM_SHOOT_TIME 		( 31 / 45.0 )
#define WEAPON_ANIM_RELOAD_TIME 	( 61 / 30.0 )
#define WEAPON_ANIM_DRAW_TIME 		( 31 / 30.0 )
#define WEAPON_ANIM_CHANGE_TIME 	( 11 / 30.0 )

/* ~ [ Params ] ~ */
new gl_iItemId;
new HookChain: gl_HookChain_TakeDamage_Pre;

enum _: eModelIndex {
	eModelIndex_Trail,
	eModelIndex_Explode
};
new gl_iszModelIndex[ eModelIndex ];

/* ~ [ Macroses ] ~ */
#define IsCustomWeapon(%0,%1)				bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponState(%0)					get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)				set_member( %0, m_Weapon_iWeaponState, %1 )
#define GetWeaponClip(%0)					get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)				set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)				get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)				get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)				set_member( %0, m_rgAmmo, %1, %2 )

/* ~ [ AMX Mod X ] ~ */
public plugin_precache( )
{
	// Precache models
	engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_VIEW );
	engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER );
	engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_WORLD );
	engfunc( EngFunc_PrecacheModel, ENTITY_ROCKET_MODEL );

	// Hook weapon
	register_clcmd( WEAPON_WEAPONLIST, "Command_HookWeapon" );

	UTIL_PrecacheWeaponList( WEAPON_WEAPONLIST );
	
	// Precache sounds
	engfunc( EngFunc_PrecacheSound, WEAPON_SOUND_SHOOT );
	engfunc( EngFunc_PrecacheSound, ENTITY_ROCKET_SOUND );

	// Model Index
	for ( new i; i < eModelIndex; i++ )
		gl_iszModelIndex[ i ] = engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_INDEX[ i ] );
}

public plugin_init( )
{
	register_plugin( "[ZP] Weapon: RPG-7", "2.0 (ReAPI)", "xUnicorn (t3rkecorejz) / Batcoh: Code base" );

	/* -> Fakemeta -> */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

	/* -> ReAPI -> */
	RegisterHookChain( RG_CWeaponBox_SetModel, "CWeaponBox__SetModel_Pre", false );
	DisableHookChain( gl_HookChain_TakeDamage_Pre = RegisterHookChain( RG_CBasePlayer_TakeDamage, "CBasePlayer__TakeDamage_Pre", false ) );

	/* -> HamSandwich -> */
	RegisterHam( Ham_CS_Item_GetMaxSpeed, WEAPON_REFERENCE, "CBasePlayerWeapon__GetMaxSpeed_Pre", false );
	RegisterHam( Ham_Item_Holster, WEAPON_REFERENCE, "CBasePlayerWeapon__Holster_Post", true );
	RegisterHam( Ham_Item_Deploy, WEAPON_REFERENCE,	"CBasePlayerWeapon__Deploy_Post", true );
	RegisterHam( Ham_Item_AddToPlayer, WEAPON_REFERENCE, "CBasePlayerWeapon__AddToPlayer_Post", true );
	RegisterHam( Ham_Weapon_Reload, WEAPON_REFERENCE, "CBasePlayerWeapon__Reload_Post", true );
	RegisterHam( Ham_Weapon_WeaponIdle, WEAPON_REFERENCE, "CBasePlayerWeapon__WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WEAPON_REFERENCE, "CBasePlayerWeapon__PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WEAPON_REFERENCE, "CBasePlayerWeapon__SecondaryAttack_Pre", false );

	/* -> Register on Extra-Items -> */
	gl_iItemId = zp_register_extra_item( WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN );
}

public Command_HookWeapon( const pPlayer )
{
	engclient_cmd( pPlayer, WEAPON_REFERENCE );
	return PLUGIN_HANDLED;
}

public zp_extra_item_selected( pPlayer, iItemId ) 
{
	if ( iItemId != gl_iItemId ) 
		return PLUGIN_HANDLED;

	return UTIL_GiveCustomWeapon( pPlayer, WEAPON_REFERENCE, WEAPON_SPECIAL_CODE );
}

// [ Fakemeta ]
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
	if ( !is_user_alive( pPlayer ) )
		return;

	static pActiveItem; pActiveItem = get_member( pPlayer, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WEAPON_SPECIAL_CODE ) )
		return;

	set_cd( CD_Handle, CD_flNextAttack, 2.0 );
}

// [ ReAPI ]
public CWeaponBox__SetModel_Pre( const pWeaponBox, const szModel[ ] ) 
{
	static pItem; pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
	if ( pItem == NULLENT || !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return HC_CONTINUE;

	SetHookChainArg( 2, ATYPE_STRING, WEAPON_MODEL_WORLD );
	set_entvar( pWeaponBox, var_body, WEAPON_MODEL_WORLD_BODY );

	return HC_CONTINUE;
}

public CBasePlayer__TakeDamage_Pre( const pVictim, const pInflictor, const pAttacker, const Float: flDamage )
{
	if ( is_nullent( pInflictor ) || !IsCustomWeapon( pInflictor, WEAPON_SPECIAL_CODE ) )
	{
		SetHookChainReturn( ATYPE_INTEGER, 0 );
		return HC_SUPERCEDE;
	}

	if ( is_nullent( pVictim ) || is_nullent( pAttacker ) || pVictim == pAttacker )
	{
		SetHookChainReturn( ATYPE_INTEGER, 0 );
		return HC_SUPERCEDE;
	}

	if ( !zp_get_user_zombie( pVictim ) || get_member( pVictim, m_iTeam ) == get_member( pAttacker, m_iTeam ) )
	{
		SetHookChainReturn( ATYPE_INTEGER, 0 );
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

// [ HamSandwich ]
public CBasePlayerWeapon__GetMaxSpeed_Pre( pItem )
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );
	UTIL_UpdateHideWeapon( MSG_ONE, pPlayer, get_member( pPlayer, m_iHideHUD ) | HIDEHUD_CROSSHAIR );
	
	return HAM_IGNORED;
}

public CBasePlayerWeapon__Holster_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );
	UTIL_UpdateHideWeapon( MSG_ONE, pPlayer, get_member( pPlayer, m_iHideHUD ) & ~HIDEHUD_CROSSHAIR );
	
	SetWeaponState( pItem, 0 );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

public CBasePlayerWeapon__Deploy_Post( const pItem )
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return HAM_IGNORED;
	
	new pPlayer = get_member( pItem, m_pPlayer );

	set_entvar( pPlayer, var_viewmodel, WEAPON_MODEL_VIEW );
	set_entvar( pPlayer, var_weaponmodel, WEAPON_MODEL_PLAYER );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, GetWeaponClip( pItem ) ? WEAPON_ANIM_DRAW : WEAPON_ANIM_DRAW_EMPTY );

	set_member( pPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME );

	return HAM_IGNORED;
}

public CBasePlayerWeapon__AddToPlayer_Post( const pItem, const pPlayer)
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return;

	if ( get_entvar( pItem, var_owner ) <= 0 )
	{
		new iAmmoType = GetWeaponAmmoType( pItem );
		if ( GetWeaponAmmo( pPlayer, iAmmoType ) < WEAPON_DEFAULT_AMMO )
			SetWeaponAmmo( pPlayer, WEAPON_DEFAULT_AMMO, iAmmoType );

		SetWeaponClip( pItem, WEAPON_MAX_CLIP );

		rg_set_iteminfo( pItem, ItemInfo_pszName, WEAPON_WEAPONLIST );
		rg_set_iteminfo( pItem, ItemInfo_iMaxClip, WEAPON_MAX_CLIP );
		rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WEAPON_DEFAULT_AMMO );
	}

	UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
}

public CBasePlayerWeapon__Reload_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
		return;

	if ( GetWeaponClip( pItem ) >= rg_get_iteminfo( pItem, ItemInfo_iMaxClip ) )
		return;

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, WEAPON_ANIM_RELOAD );

	set_member( pPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME );
}

public CBasePlayerWeapon__WeaponIdle_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return HAM_IGNORED;

	if ( get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	static iAnim;
	if ( GetWeaponClip( pItem ) )
		iAnim = GetWeaponState( pItem ) ? WEAPON_ANIM_IDLE2 : WEAPON_ANIM_IDLE;
	else iAnim = GetWeaponState( pItem ) ? WEAPON_ANIM_IDLE2_EMPTY : WEAPON_ANIM_IDLE_EMPTY;

	UTIL_SendWeaponAnim( MSG_ONE, get_member( pItem, m_pPlayer ), iAnim);
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME );

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

	CRocket__SpawnEntity( pPlayer, pItem, GetWeaponState( pItem ) ? true : false );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, GetWeaponState( pItem ) ? WEAPON_ANIM_SHOOT2 : WEAPON_ANIM_SHOOT );
	emit_sound( pPlayer, CHAN_WEAPON, WEAPON_SOUND_SHOOT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

	SetWeaponClip( pItem, --iClip );
	SetWeaponState( pItem, 0 );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, WEAPON_RATE );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME );

	return HAM_SUPERCEDE;
}

public CBasePlayerWeapon__SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WEAPON_SPECIAL_CODE ) )
		return HAM_IGNORED;

	if ( !GetWeaponClip( pItem ) )
		return HAM_SUPERCEDE;

	new pPlayer = get_member( pItem, m_pPlayer );

	SetWeaponState( pItem, !GetWeaponState( pItem ) );
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, GetWeaponState( pItem ) ? WEAPON_ANIM_CHANGE1 : WEAPON_ANIM_CHANGE2 );

	set_member( pItem, m_Weapon_flNextPrimaryAttack, WEAPON_ANIM_CHANGE_TIME );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, WEAPON_ANIM_CHANGE_TIME );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_CHANGE_TIME );

	return HAM_SUPERCEDE;
}

// [ Other ]
public CRocket__SpawnEntity( const pPlayer, const pInflictor, const bool: bMode )
{
	new pEntity = rg_create_entity( "info_target" );

	if ( is_nullent( pEntity ) )
		return NULLENT;

	new Float: vecOrigin[ 3 ]; get_entvar( pPlayer, var_origin, vecOrigin );
	new Float: vecViewOfs[ 3 ]; get_entvar( pPlayer, var_view_ofs, vecViewOfs );
	new Float: vecViewAngle[ 3 ]; get_entvar( pPlayer, var_v_angle, vecViewAngle );
	new Float: vecForward[ 3 ]; angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecForward );
	new Float: vecVelocity[ 3 ]; xs_vec_copy( vecForward, vecVelocity );
	new Float: vecAngles[ 3 ];

	xs_vec_mul_scalar( vecForward, 20.0, vecForward );
	xs_vec_add( vecViewOfs, vecForward, vecViewOfs );
	xs_vec_add( vecOrigin, vecViewOfs, vecOrigin );

	xs_vec_mul_scalar( vecVelocity, ENTITY_ROCKET_SPEED, vecVelocity );
	engfunc( EngFunc_VecToAngles, vecVelocity, vecAngles );

	set_entvar( pEntity, var_classname, ENTITY_ROCKET_CLASSNAME );
	set_entvar( pEntity, var_solid, SOLID_TRIGGER );
	set_entvar( pEntity, var_movetype, bMode ? MOVETYPE_FLY : MOVETYPE_TOSS );
	set_entvar( pEntity, var_owner, pPlayer );
	set_entvar( pEntity, var_dmg_inflictor, pInflictor );

	if ( !bMode )
		set_entvar( pEntity, var_gravity, -0.3 );

	set_entvar( pEntity, var_velocity, vecVelocity );
	set_entvar( pEntity, var_angles, vecAngles );

	engfunc( EngFunc_SetModel, pEntity, ENTITY_ROCKET_MODEL );
	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMFOLLOW );
	write_short( pEntity );
	write_short( gl_iszModelIndex[ eModelIndex_Trail ] );
	write_byte( 5 ); // life
	write_byte( 3 ); // width
	write_byte( 255 ); // red
	write_byte( 255 ); // green
	write_byte( 255 ); // blue
	write_byte( 255 ); // brightness
	message_end( );

	SetTouch( pEntity, "CRocket__Touch" );

	return pEntity;
}

public CRocket__Touch( const pEntity, const pTouch )
{
	new Float: vecOrigin[ 3 ]; get_entvar( pEntity, var_origin, vecOrigin );
	if ( engfunc( EngFunc_PointContents, vecOrigin ) == CONTENTS_SKY )
	{
		UTIL_KillEntity( pEntity );
		return;
	}

	new pOwner = get_entvar( pEntity, var_owner );
	if ( pTouch == pOwner || FClassnameIs( pTouch, ENTITY_ROCKET_CLASSNAME ) )
		return;

	new pInflictor = get_entvar( pEntity, var_dmg_inflictor );
	if ( is_nullent( pInflictor ) || !IsCustomWeapon( pInflictor, WEAPON_SPECIAL_CODE ) )
		return;

	rh_emit_sound2( pEntity, 0, CHAN_ITEM, ENTITY_ROCKET_SOUND );

	message_begin_f( MSG_PVS, SVC_TEMPENTITY, vecOrigin );
	UTIL_TE_EXPLOSION( gl_iszModelIndex[ eModelIndex_Explode ], vecOrigin, 20.0, random_num( 16, 20 ), 32, TE_EXPLFLAG_NOSOUND );

	message_begin_f( MSG_PVS, SVC_TEMPENTITY, vecOrigin );
	UTIL_TE_WORLDDECAL( "{scorch1", vecOrigin );

	EnableHookChain( gl_HookChain_TakeDamage_Pre );
	rg_dmg_radius( vecOrigin, pInflictor, pOwner, ENTITY_ROCKET_DAMAGE, ENTITY_ROCKET_RADIUS, 0, ENTITY_ROCKET_DMGTYPE );
	DisableHookChain( gl_HookChain_TakeDamage_Pre );

	UTIL_KillEntity( pEntity );
}

// [ Stocks ]

/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity ) 
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );

	SetTouch( pEntity, "" );
	SetThink( pEntity, "" );
}

/* -> Weapon Animation <- */
stock UTIL_SendWeaponAnim( const iDest, const pPlayer, const iAnim ) 
{
	set_entvar( pPlayer, var_weaponanim, iAnim );

	message_begin( iDest, SVC_WEAPONANIM, .player = pPlayer );
	write_byte( iAnim );
	write_byte( 0 );
	message_end( );
}

stock UTIL_UpdateHideWeapon( const iDest, const pPlayer, const bitsFlags )
{
	static iMsgId_HideWeapon; if ( !iMsgId_HideWeapon ) iMsgId_HideWeapon = get_user_msgid( "HideWeapon" );

	message_begin( iDest, iMsgId_HideWeapon, .player = pPlayer );
	write_byte( bitsFlags );
	message_end( );

	set_member( pPlayer, m_iHideHUD, bitsFlags );
	set_member( pPlayer, m_iClientHideHUD, bitsFlags );
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

/* -> Give Custom Item <- */
stock bool: UTIL_GiveCustomWeapon( const pPlayer, const szWeaponName[ ], const iWeaponUId )
{
	new pItem = rg_give_custom_item( pPlayer, szWeaponName, GT_DROP_AND_REPLACE, iWeaponUId );
	if ( is_nullent( pItem ) )
		return false;

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

stock UTIL_TE_EXPLOSION( const iszModelIndex, const Float: vecOrigin[ 3 ], const Float: flUp, const iScale, const iFramerate, const bitsFlags = TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES )
{
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

stock UTIL_TE_WORLDDECAL( const szDecalName[ ], const Float: vecOrigin[ 3 ] )
{
	static iDecalIndex; iDecalIndex = engfunc( EngFunc_DecalIndex, szDecalName );

	write_byte( TE_WORLDDECAL );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_byte( iDecalIndex ); // ModelIndex
	message_end( );
}