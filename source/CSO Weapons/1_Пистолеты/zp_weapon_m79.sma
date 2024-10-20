#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <zpe_knokcback>
#include <xs>

/* ~ [ Macroses ] ~ */
#define PDATA_SAFE 						2

#define GetWeaponClip(%0)				get_pdata_int( %0, m_Weapon_iClip, linux_diff_weapon )
#define SetWeaponClip(%0,%1)			set_pdata_int( %0, m_Weapon_iClip, %1, linux_diff_weapon )
#define GetWeaponAmmoType(%0)			get_pdata_int( %0, m_Weapon_iPrimaryAmmoType, linux_diff_weapon )
#define GetWeaponAmmo(%0,%1)			get_pdata_int( %0, m_rgAmmo + %1, linux_diff_player )
#define SetWeaponAmmo(%0,%1,%2)			set_pdata_int( %0, m_rgAmmo + %1, %2, linux_diff_player )

#define IsValidEntity(%0) 				bool: ( pev_valid( %0 ) == PDATA_SAFE )
#define IsCustomItem(%0) 				bool: ( pev( %0, pev_impulse ) == WEAPON_SPECIAL_CODE )
#define KillEntity(%0) 					( set_pev( %0, pev_flags, pev( %0, pev_flags ) | FL_KILLME ) )
#define PrecacheArray(%0,%1) 			for ( new i; i < sizeof %1; i++ ) engfunc( EngFunc_Precache%0, %1[ i ] )

// native zp_set_item_max_clip(iPlayer, iValue);
// native zp_set_item_max_ammo(iPlayer, iValue);
// forward zp_weapon_buyammo(iPlayer, iActiveItem);

/* ~ [ Extra Item ] ~ */
new const WEAPON_ITEM_NAME[ ] = 		"M79";
const WEAPON_ITEM_COST = 				0;

/* ~ [ Weapon Settings ] ~ */
new const WEAPON_REFERENCE[ ] = 		"weapon_deagle";
new const WEAPON_NATIVE[ ] = 			"zp_give_user_m79";
new const WEAPON_MODEL_VIEW[ ] = 		"models/zp_br_cso/weapons2/v_m79.mdl";

new const WEAPON_MODEL_WORLD[ ] = 		"models/zp_br_cso/other/w_weapons_b1.mdl";
new const WEAPON_SOUNDS[ ][ ] =
{
	"weapons/m79_fire1.wav" // 0
}

const WEAPON_SPECIAL_CODE = 			5005;
const WEAPON_MODEL_WORLD_BODY = 		5;

const WEAPON_MAX_CLIP = 				1;
const WEAPON_DEFAULT_AMMO = 			35;
const Float: WEAPON_RATE = 				0.7;

/* ~ [ Weapon List ] ~ */
new const WEAPON_WEAPONLIST[ ] = 	"zp_br_cso/weapons2/weapon_m79";
new const WEAPON_RESOURCES[ ][ ] =
{
	// Custom resources precache, sprites for example
	"sprites/zp_br_cso/weapons2/hud2/ammo1.spr",
	"sprites/zp_br_cso/weapons2/hud2/640hud42.spr"
};
new const iWeaponList[ ] = 
{
	8, 35, -1, -1, 1, 1, 26, 0 // weapon_deagle
};

/* ~ [ Entity: Grenade Missile ] ~ */
new const ENTITY_GRENADE_REFERENCE[ ] =	"info_target";
new const ENTITY_GRENADE_CLASSNAME[ ] =	"ent_m79_missile";
new const ENTITY_GRENADE_MODEL[ ] =		"models/zp_br_cso/weapons2/s_grenade_m79.mdl";
new const ENTITY_GRENADE_SPRITES[ ][ ] =
{
	"sprites/zp_br_cso/grenade/ef_fgrenade.spr", "sprites/laserbeam.spr"
};
const Float: ENTITY_GRENADE_SPEED = 	1300.0; // Max 2000.0
const Float: ENTITY_GRENADE_RADIUS =	150.75;
const Float: ENTITY_GRENADE_DAMAGE =	750.0;
const ENTITY_GRENADE_DMGTYPE =			DMG_GRENADE;

/* ~ [ Weapon Animations ] ~ */
enum _: eWeaponAnim
{
	WEAPON_ANIM_IDLE = 0,
	WEAPON_ANIM_SHOOT,
	WEAPON_ANIM_RELOAD,
	WEAPON_ANIM_DRAW
};

#define WEAPON_ANIM_IDLE_TIME 			2/16.0
#define WEAPON_ANIM_SHOOT_TIME 			31/30.0
#define WEAPON_ANIM_RELOAD_TIME 		75/30.0
#define WEAPON_ANIM_DRAW_TIME 			31/30.0

/* ~ [ Params ] ~ */
new gl_iszAllocString_Grenade;
new gl_iItemID;

enum _: eModelIndex {
	eModelIndex_Explode,
	eModelIndex_Trail
};
new gl_iszModelIndex[ eModelIndex ];

/* ~ [ Entity Offsets ] ~ */
const linux_diff_weapon = 				4;
const m_WeaponBox_rgpPlayerItems = 		34;
const m_pPlayer = 						41;
const m_pNext = 						42;
const m_iId = 							43;
const m_Weapon_flNextPrimaryAttack = 	46;
const m_Weapon_flNextSecondaryAttack = 	47;
const m_Weapon_flTimeWeaponIdle = 		48;
const m_Weapon_iPrimaryAmmoType = 		49;
const m_Weapon_iClip = 					51;
const m_Weapon_fInReload = 				54;
const m_Weapon_iShellId = 				57;
const m_Weapon_iDirection =				60;
const m_Weapon_iShotsFired =			64;
const m_Weapon_flNextReload = 			75;

/* ~ [ Player Offsets ] ~ */
const linux_diff_player = 				5;
const m_LastHitGroup =					75;
const m_flNextAttack = 					83;
const m_flPainShock = 					108;
const m_rgpPlayerItems = 				367;
const m_pActiveItem = 					373;
const m_rgAmmo = 						376;

/* ~ [ AMX Mod X ] ~ */
public plugin_init( )
{
	// https://cso.fandom.com/wiki/M79_Saw_off
	register_plugin( "[ZP] Weapon: M79 Saw off", "2.0", "xUnicorn (t3rkecorejz)" );

	/* -> Fakemeta: Forwards -> */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );
	register_forward( FM_SetModel, "FM_Hook_SetModel_Pre", false );

	/* -> Ham: Weapon -> */
	RegisterHam( Ham_Item_Holster, WEAPON_REFERENCE, "CWeapon__Holster_Post", true );
	RegisterHam( Ham_Item_Deploy, WEAPON_REFERENCE, "CWeapon__Deploy_Post", true );
	RegisterHam( Ham_Item_PostFrame, WEAPON_REFERENCE, "CWeapon__PostFrame_Pre", false );
	RegisterHam( Ham_Item_AddToPlayer, WEAPON_REFERENCE, "CWeapon__AddToPlayer_Post", true );
	RegisterHam( Ham_Weapon_Reload, WEAPON_REFERENCE, "CWeapon__Reload_Pre", false );
	RegisterHam( Ham_Weapon_WeaponIdle, WEAPON_REFERENCE, "CWeapon__WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WEAPON_REFERENCE, "CWeapon__PrimaryAttack_Pre", false );

	/* -> Ham: Entity -> */
	RegisterHam( Ham_Touch, ENTITY_GRENADE_REFERENCE, "CGrenade__Touch_Pre", false );

	/* -> Alloc String -> */
	gl_iszAllocString_Grenade = engfunc( EngFunc_AllocString, ENTITY_GRENADE_CLASSNAME );
	
	/* -> Register on Extra-Items -> */
	gl_iItemID = zp_register_extra_item( WEAPON_ITEM_NAME, WEAPON_ITEM_COST, ZP_TEAM_HUMAN );
}

public plugin_precache( )
{
	/* -> Hook Weapon -> */
	register_clcmd( WEAPON_WEAPONLIST, "Command_HookWeapon" );

	/* -> Precache Generic -> */
	new szWeaponList[ 128 ]; formatex( szWeaponList, charsmax( szWeaponList ), "sprites/%s.txt", WEAPON_WEAPONLIST );
	engfunc( EngFunc_PrecacheGeneric, szWeaponList );

	PrecacheArray(Generic, WEAPON_RESOURCES);

	/* -> Precache Models -> */
	engfunc( EngFunc_PrecacheModel, WEAPON_MODEL_VIEW );
	engfunc( EngFunc_PrecacheModel, ENTITY_GRENADE_MODEL );
	
	/* -> Precache Sounds -> */
	
	PrecacheArray(Sound, WEAPON_SOUNDS);

	/* -> Model Index -> */
	for ( new i = 0; i < eModelIndex; i++ )
		gl_iszModelIndex[ i ] = engfunc( EngFunc_PrecacheModel, ENTITY_GRENADE_SPRITES[ i ] );
}

public plugin_natives( ) register_native( WEAPON_NATIVE, "Command_GiveWeapon", 1 );

public Command_HookWeapon( const pPlayer )
{
	engclient_cmd( pPlayer, WEAPON_REFERENCE );
	return PLUGIN_HANDLED;
}

public Command_GiveWeapon( const pPlayer )
{
	static pItem, iszAllocStringCached;
	if ( iszAllocStringCached || ( iszAllocStringCached = engfunc( EngFunc_AllocString, WEAPON_REFERENCE ) ) )
		pItem = engfunc( EngFunc_CreateNamedEntity, iszAllocStringCached );

	if ( !IsValidEntity( pItem ) ) return FM_NULLENT;

	set_pev( pItem, pev_impulse, WEAPON_SPECIAL_CODE );
	ExecuteHam( Ham_Spawn, pItem );
	SetWeaponClip( pItem, WEAPON_MAX_CLIP );
	UTIL_DropWeapon( pPlayer, ExecuteHamB( Ham_Item_ItemSlot, pItem ) );

	if ( !ExecuteHamB( Ham_AddPlayerItem, pPlayer, pItem ) )
	{
		KillEntity( pItem );
		return FM_NULLENT;
	}

	ExecuteHamB( Ham_Item_AttachToPlayer, pItem, pPlayer );
	SetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ), WEAPON_DEFAULT_AMMO );
	emit_sound( pPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

	return pItem;
}

/* ~ [ Zombie Plague ] ~ */
public zp_extra_item_selected( pPlayer, iItemID )
{
	if ( iItemID == gl_iItemID )
		Command_GiveWeapon( pPlayer );
}

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle )
{
	if (pev_valid(pPlayer) != PDATA_SAFE ||  !is_user_alive( pPlayer ) )
		return;

	static pActiveItem; pActiveItem = get_pdata_cbase( pPlayer, m_pActiveItem, linux_diff_player );
	if ( !IsValidEntity( pActiveItem ) || !IsCustomItem( pActiveItem ) )
		return;

	set_cd( CD_Handle, CD_flNextAttack, 2.0 );
}

public FM_Hook_SetModel_Pre( const pEntity )
{
	if(pev_valid(pEntity) != PDATA_SAFE) return FMRES_IGNORED;
	static i, szClassName[ 32 ], pItem;
	pev( pEntity, pev_classname, szClassName, charsmax( szClassName ) );
	if ( !equal( szClassName, "weaponbox" ) ) return FMRES_IGNORED;

	for ( i = 0; i < 6; i++ )
	{
		pItem = get_pdata_cbase( pEntity, m_WeaponBox_rgpPlayerItems + i, linux_diff_weapon );
		if ( IsValidEntity( pItem ) && IsCustomItem( pItem ) )
		{
			engfunc( EngFunc_SetModel, pEntity, WEAPON_MODEL_WORLD );
			set_pev( pEntity, pev_body, WEAPON_MODEL_WORLD_BODY );
			
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

/* ~ [ HamSandwich ] ~ */
public CWeapon__Holster_Post( const pItem )
{
	if ( !IsValidEntity( pItem ) || !IsCustomItem( pItem ) )
		return;

	new pPlayer = get_pdata_cbase( pItem, m_pPlayer, linux_diff_weapon );
	
	set_pdata_int( pItem, m_Weapon_fInReload, false, linux_diff_weapon );
	set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, 1.0, linux_diff_weapon );
	set_pdata_float( pPlayer, m_flNextAttack, 1.0, linux_diff_player );
}

public CWeapon__Deploy_Post( const pItem )
{
	if ( !IsValidEntity( pItem ) || !IsCustomItem( pItem ) )
		return;

	new pPlayer = get_pdata_cbase( pItem, m_pPlayer, linux_diff_weapon );

	static iszAllocStringViewModel;
	if ( iszAllocStringViewModel || ( iszAllocStringViewModel = engfunc( EngFunc_AllocString, WEAPON_MODEL_VIEW ) ) )
		set_pev_string( pPlayer, pev_viewmodel2, iszAllocStringViewModel );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, WEAPON_ANIM_DRAW );

	set_pdata_float( pPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player );
	set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon );
}

public CWeapon__PostFrame_Pre( const pItem )
{
	if ( !IsValidEntity( pItem ) || !IsCustomItem( pItem ) )
		return HAM_IGNORED;

	new pPlayer = get_pdata_cbase( pItem, m_pPlayer, linux_diff_weapon );

	if ( get_pdata_int( pItem, m_Weapon_fInReload, linux_diff_weapon ) )
	{
		static iAmmoType; if ( !iAmmoType ) iAmmoType = GetWeaponAmmoType( pItem );
		static iAmmo; iAmmo = GetWeaponAmmo( pPlayer, iAmmoType );
		static iClip; iClip = GetWeaponClip( pItem );
		static iAmount; iAmount = min( WEAPON_MAX_CLIP - iClip, iAmmo );

		SetWeaponClip( pItem, iClip + iAmount );
		set_pdata_int( pItem, m_Weapon_fInReload, false, linux_diff_weapon );
		SetWeaponAmmo( pPlayer, iAmmoType, iAmmo - iAmount );
	}

	return HAM_IGNORED;
}

public CWeapon__AddToPlayer_Post( const pItem, const pPlayer )
{
	new iWeaponUId = pev( pItem, pev_impulse );
	if ( iWeaponUId != 0 && iWeaponUId != WEAPON_SPECIAL_CODE )
		return;

	UTIL_WeaponList( MSG_ONE, pPlayer, WEAPON_WEAPONLIST, .iMaxPrimaryAmmo = WEAPON_DEFAULT_AMMO );
}

public CWeapon__Reload_Pre( const pItem )
{
	if ( !IsValidEntity( pItem ) || !IsCustomItem( pItem ) )
		return HAM_IGNORED;

	new iClip = GetWeaponClip( pItem );
	if ( iClip >= WEAPON_MAX_CLIP )
		return HAM_SUPERCEDE;

	new pPlayer = get_pdata_cbase( pItem, m_pPlayer, linux_diff_weapon );
	if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
		return HAM_SUPERCEDE;

	SetWeaponClip( pItem, 0 );
	ExecuteHam( Ham_Weapon_Reload, pItem );
	SetWeaponClip( pItem, iClip );
	
	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, WEAPON_ANIM_RELOAD );

	set_pdata_int( pItem, m_Weapon_fInReload, true, linux_diff_weapon );
	set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon );
	set_pdata_float( pPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player );

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre( const pItem )
{
	if ( !IsValidEntity( pItem ) || !IsCustomItem( pItem ) || get_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, linux_diff_weapon ) > 0.0 )
		return HAM_IGNORED;

	new pPlayer = get_pdata_cbase( pItem, m_pPlayer, linux_diff_weapon );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, WEAPON_ANIM_IDLE );
	set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon );

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre( const pItem )
{
	if ( !IsValidEntity( pItem ) || !IsCustomItem( pItem ) )
		return HAM_IGNORED;

	new iClip = GetWeaponClip( pItem );
	if ( !iClip )
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_pdata_float( pItem, m_Weapon_flNextPrimaryAttack, 0.2, linux_diff_weapon );

		return HAM_SUPERCEDE;
	}

	new pPlayer = get_pdata_cbase( pItem, m_pPlayer, linux_diff_weapon );

	CGrenade__SpawnEntity( pPlayer, pItem );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, WEAPON_ANIM_SHOOT );
	emit_sound( pPlayer, CHAN_WEAPON, WEAPON_SOUNDS[ 0 ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

	new Float: vecPunchangle[ 3 ]; pev( pPlayer, pev_punchangle, vecPunchangle );
	vecPunchangle[ 0 ] -= ( pev( pPlayer, pev_flags ) & FL_ONGROUND ) ? random_float( 3.0, 5.0 ) : random_float( 7.0, 10.0 );
	set_pev( pPlayer, pev_punchangle, vecPunchangle );

	SetWeaponClip( pItem, --iClip );
	set_pdata_float( pItem, m_Weapon_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon );
	set_pdata_float( pItem, m_Weapon_flNextSecondaryAttack, WEAPON_RATE, linux_diff_weapon );
	set_pdata_float( pItem, m_Weapon_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon );

	return HAM_SUPERCEDE;
}

public CGrenade__Touch_Pre( const pEntity, const pTouch )
{
	if ( !IsValidEntity( pEntity ) || pev( pEntity, pev_classname ) != gl_iszAllocString_Grenade )
		return HAM_IGNORED;

	new pOwner = pev( pEntity, pev_owner );
	if ( pTouch == pOwner || pev( pTouch, pev_classname ) == gl_iszAllocString_Grenade )
		return HAM_SUPERCEDE;

	/* По тимейтам не ебашит */
	if(is_user_connected(pTouch) && !zp_get_user_zombie(pTouch))
		return HAM_SUPERCEDE;

	new Float: vecOrigin[ 3 ]; pev( pEntity, pev_origin, vecOrigin );
	if ( engfunc( EngFunc_PointContents, vecOrigin ) == CONTENTS_SKY )
	{
		UTIL_KillEntity( pEntity );
		return HAM_IGNORED;
	}

	message_begin_f( MSG_PVS, SVC_TEMPENTITY, vecOrigin );
	UTIL_TE_EXPLOSION( gl_iszModelIndex[ eModelIndex_Explode ], vecOrigin, 10.0, random_num( 16, 20 ), 32, TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOPARTICLES );

	message_begin_f( MSG_PVS, SVC_TEMPENTITY, vecOrigin );
	UTIL_TE_WORLDDECAL( "{scorch1", vecOrigin );

	new pInflictor = pev( pEntity, pev_dmg_inflictor );
	if ( IsValidEntity( pInflictor ) && IsCustomItem( pInflictor ) )
	{
		new pVictim = FM_NULLENT, Float: flDamage = ENTITY_GRENADE_DAMAGE;
		set_pev( pEntity, pev_classname, "grenade" ); // 'grenade' icon

		while ( ( pVictim = engfunc( EngFunc_FindEntityInSphere, pVictim, vecOrigin, ENTITY_GRENADE_RADIUS ) ) > 0 )
		{
			if ( pev( pVictim, pev_takedamage ) == DAMAGE_NO )
				continue;

			if ( is_user_alive( pVictim ) )
			{
				if ( pVictim == pOwner || !zp_get_user_zombie( pVictim ) || !is_wall_between_points( pEntity, pVictim ) )
					continue;
			}
			else if ( pev( pVictim, pev_solid ) == SOLID_BSP )
			{
				if ( pev( pVictim, pev_spawnflags ) & SF_BREAK_TRIGGER_ONLY )
					continue;
			}

			if ( is_user_alive( pVictim ) && zp_get_user_zombie( pVictim ) )
			{
				set_pev( pVictim, pev_punchangle, Float: { 10.0, 10.0, 10.0 } );
				set_pdata_float( pVictim, m_flPainShock, 1.0, linux_diff_player );
				set_pdata_int( pVictim, m_LastHitGroup, HIT_GENERIC, linux_diff_player );
			}

			flDamage *= random_float( 0.75, 1.25 );
			ExecuteHamB( Ham_TakeDamage, pVictim, pEntity, pOwner, flDamage, ENTITY_GRENADE_DMGTYPE )
			zp_set_user_velocitymifier(pVictim, 0.4)
		}
	}

	UTIL_KillEntity( pEntity );

	return HAM_IGNORED;
}

/* ~ [ Other ] ~ */
public CGrenade__SpawnEntity( const pPlayer, const pItem )
{
	static pEntity, iszAllocStringCached;
	if ( iszAllocStringCached || ( iszAllocStringCached = engfunc( EngFunc_AllocString, ENTITY_GRENADE_REFERENCE ) ) )
		pEntity = engfunc( EngFunc_CreateNamedEntity, iszAllocStringCached );

	if ( !IsValidEntity( pEntity ) )
		return false;

	new Float: vecOrigin[ 3 ]; pev( pPlayer, pev_origin, vecOrigin );
	new Float: vecViewOfs[ 3 ]; pev( pPlayer, pev_view_ofs, vecViewOfs );
	new Float: vecViewAngle[ 3 ]; pev( pPlayer, pev_v_angle, vecViewAngle );
	new Float: vecForward[ 3 ]; angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecForward );
	new Float: vecVelocity[ 3 ]; xs_vec_copy( vecForward, vecVelocity );
	new Float: vecAngles[ 3 ];

	xs_vec_mul_scalar( vecForward, 10.0, vecForward );
	xs_vec_add( vecViewOfs, vecForward, vecViewOfs );
	xs_vec_add( vecOrigin, vecViewOfs, vecOrigin );

	xs_vec_mul_scalar( vecVelocity, ENTITY_GRENADE_SPEED, vecVelocity );
	engfunc( EngFunc_VecToAngles, vecVelocity, vecAngles );

	set_pev_string( pEntity, pev_classname, gl_iszAllocString_Grenade );
	set_pev( pEntity, pev_movetype, MOVETYPE_TOSS );
	set_pev( pEntity, pev_solid, SOLID_TRIGGER );
	set_pev( pEntity, pev_owner, pPlayer );
	set_pev( pEntity, pev_dmg_inflictor, pItem );
	set_pev( pEntity, pev_velocity, vecVelocity );
	set_pev( pEntity, pev_gravity, 1.0 );
	set_pev( pEntity, pev_angles, vecAngles );

	engfunc( EngFunc_SetModel, pEntity, ENTITY_GRENADE_MODEL );
	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );

	// https://github.com/baso88/SC_AngelScript/wiki/TE_BEAMFOLLOW
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMFOLLOW );
	write_short( pEntity );
	write_short( gl_iszModelIndex[ eModelIndex_Trail ] ); // Model Index
	write_byte( 7 ); // Life
	write_byte( 5 ); // Width
	write_byte( 180 ); // Red
	write_byte( 180 ); // Green
	write_byte( 180 ); // Blue
	write_byte( 220 ); // Alpha
	message_end( );

	return pEntity;
} 

/* ~ [ Stocks ] ~ */
stock is_wall_between_points( const pPlayer, const pEntity )
{
	if ( !is_user_alive( pEntity ) )
		return false;

	new pTrace = create_tr2( );
	new Float: vecStart[ 3 ], Float: vecEnd[ 3 ], Float: vecEndPos[ 3 ];

	pev( pPlayer, pev_origin, vecStart );
	pev( pEntity, pev_origin, vecEnd );

	engfunc( EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, pPlayer, pTrace );
	get_tr2( pTrace, TR_vecEndPos, vecEndPos );

	free_tr2( pTrace );

	return xs_vec_equal( vecEnd, vecEndPos );
}

stock UTIL_KillEntity( const pEntity )
{
	set_pev( pEntity, pev_flags, pev( pEntity, pev_flags ) | FL_KILLME );
	set_pev( pEntity, pev_nextthink, get_gametime( ) );
}

stock UTIL_SendWeaponAnim( const iDest, const pPlayer, const iAnim )
{
	set_pev( pPlayer, pev_weaponanim, iAnim );

	message_begin( iDest, SVC_WEAPONANIM, .player = pPlayer );
	write_byte( iAnim );
	write_byte( 0 );
	message_end( );
}

stock UTIL_DropWeapon( const pPlayer, const iSlot )
{
	if(pev_valid(pPlayer) != 2) return;

	static pItem, szWeaponName[ 32 ];
	pItem = get_pdata_cbase( pPlayer, m_rgpPlayerItems + iSlot, linux_diff_player );
	while ( IsValidEntity( pItem ) )
	{
		pev( pItem, pev_classname, szWeaponName, charsmax( szWeaponName ) );
		engclient_cmd( pPlayer, "drop", szWeaponName );

		pItem = get_pdata_cbase( pItem, m_pNext, linux_diff_weapon );
	}
}

stock UTIL_WeaponList( const iDist, const pPlayer, const szWeaponName[ ], const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
{
	static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

	message_begin( iDist, iMsgId_Weaponlist, .player = pPlayer );
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