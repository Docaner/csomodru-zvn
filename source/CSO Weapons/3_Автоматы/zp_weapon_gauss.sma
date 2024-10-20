public stock const PluginName[ ] =			"[ZP] Weapon: Gauss / Tau Cannon";
public stock const PluginVersion[ ] =		"1.0";
public stock const PluginAuthor[ ] =		"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <zombieplague>

// #include <zp_stocks>

/* ~ [ Plugin Settings ] ~ */
const WeaponUnicalIndex =					29082024;
new const WeaponReference[ ] =				"weapon_aug";
new const WeaponListDir[ ] =				"x_re/gauss_hud";
new const WeaponAnimation[ ] =				"m249";
new const WeaponModelView[ ] =				"models/x_re/v_gauss.mdl";
new const WeaponModelPlayer[ ] =			"models/p_gauss.mdl";
new const WeaponModelWorld[ ] =				"models/x_re/w_gauss.mdl";
new const WeaponSounds[ ][ ] = {
	"weapons/gauss2.wav",
	"weapons/electro4.wav",
	"weapons/electro5.wav",
	"weapons/electro6.wav",
	"ambience/pulsemachine.wav"
};
new const WeaponBeamSprite[ ] =				"sprites/white.spr"; // "sprites/smoke.spr";
new const WeaponGlowSprite[ ] =				"sprites/hotglow.spr";

const WeaponMaxClip =						100; // Max clip
const WeaponDefaultAmmo =					100; // Default ammo
const WeaponMaxAmmo =						100; // Max ammo

const Float: WeaponAmmoChargeTime =			0.15;

// Primary Attack
const Float: WeaponRate =					0.2;
const Float: WeaponBaseDamage =				20.0;

// Secondary Attack
const Float: WeaponRateCharge =				0.1;
const Float: WeaponBaseChargeDamage =		200.0;
const Float: WeaponFullChargeTime =			4.0; // https://github.com/ValveSoftware/halflife/blob/master/dlls/gauss.cpp#L46
const Float: WeaponChargeRate =				0.1; // https://github.com/ValveSoftware/halflife/blob/master/dlls/gauss.cpp#L236-L250
const Float: WeaponChargeMaxTime =			10.0; // https://github.com/ValveSoftware/halflife/blob/master/dlls/gauss.cpp#L284
const Float: WeaponChargeDamageHimSelf =	50.0; // https://github.com/ValveSoftware/halflife/blob/master/dlls/gauss.cpp#L295
new const WeaponBeamWidth[ ] =				{ 25, 10 }; // Secondary, Primary

/* ~ [ Weapon Animations ] ~ */
enum {
	WeaponAnim_Idle1 = 0,
	WeaponAnim_Idle2,
	WeaponAnim_Fidget,
	WeaponAnim_SpinUp,
	WeaponAnim_Spin,
	WeaponAnim_Fire1,
	WeaponAnim_Fire2,
	WeaponAnim_Holster,
	WeaponAnim_Draw,
};

const Float: WeaponAnim_Idle1_Time =		4.1;
const Float: WeaponAnim_Idle2_Time =		3.1;
const Float: WeaponAnim_Fidget_Time =		3.4;
const Float: WeaponAnim_SpinUp_Time =		1.0;
const Float: WeaponAnim_Spin_Time =			0.53;
const Float: WeaponAnim_Fire1_Time =		1.0;
const Float: WeaponAnim_Fire2_Time =		1.4;
const Float: WeaponAnim_Holster_Time =		0.69;
const Float: WeaponAnim_Draw_Time =			0.6;

/* ~ [ Params ] ~ */
new gl_iItemId;
new gl_iszModelIndex_Beam;
new gl_iszModelIndex_Glow;

enum {
	WeaponSound_Fire = 0,
	WeaponSound_Electro4,
	WeaponSound_Electro5,
	WeaponSound_Electro6,
	WeaponSound_Charge
};

/* ~ [ Macroses ] ~ */
#define IsCustomWeapon(%0,%1)				bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponClip(%0)					get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)				set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)				get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)				get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)				set_member( %0, m_rgAmmo, %1, %2 )
#define INSTANCE(%0)						( ( %0 == -1 ) ? 0 : %0 )

#if !defined Vector3
	#define Vector3(%0)						Float: %0[ 3 ]
#endif

#define m_Weapon_fInAttack					m_Weapon_iWeaponState // CWeapon

/**
 * Не юзаю свободные мемберы пушек, так как они конфликтуют с оружием (в зависимости от рефа пушки),
 * также многие мемберы вызываются всегда в ItemPostFrame вне зависимости от рефа пушки
 * https://github.com/s1lentq/ReGameDLL_CS/blob/dc16b12d7976f03d20b81f9a2491ee7dddbb9b8e/regamedll/dlls/weapons.cpp#L973
 */
#define var_flStartCharge					var_fuser1 // CWeapon
#define var_flAmmoStartCharge				var_fuser2 // CWeapon
#define var_flNextAmmoBurn					var_fuser3 // CWeapon
#define var_flPlayAftershock				var_fuser4 // CWeapon
#define var_flNextCharge					var_starttime // CWeapon
#define var_view_body						var_iuser1 // CWeapon

#define FFADE_IN							0x0000 // Just here so we don't pass 0 into the function

/* ~ [ AMX Mod X ] ~ */
public plugin_precache( )
{
	new i;

	/* -> Precache Models <- */
	engfunc( EngFunc_PrecacheModel, WeaponModelView );
	engfunc( EngFunc_PrecacheModel, WeaponModelPlayer );
	engfunc( EngFunc_PrecacheModel, WeaponModelWorld );

	/* -> Precache Sounds <- */
	for ( i = 0; i < sizeof WeaponSounds; i++ )
		engfunc( EngFunc_PrecacheSound, WeaponSounds[ i ] );

	/* -> Precache WeaponList <- */
	UTIL_PrecacheWeaponList( WeaponListDir );

	/* -> Hook Weapon <- */
	register_clcmd( WeaponListDir, "ClientCommand__HookWeapon" );

	/* -> Model Index <- */
	gl_iszModelIndex_Beam = engfunc( EngFunc_PrecacheModel, WeaponBeamSprite );
	gl_iszModelIndex_Glow = engfunc( EngFunc_PrecacheModel, WeaponGlowSprite );
}

public plugin_init( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

	/* -> Fakemeta <- */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

	/* -> ReGameDLL <- */
	RegisterHookChain( RG_CWeaponBox_SetModel, "RG_CWeaponBox_SetModel_Pre", false );

	/* -> HamSandwich <- */
	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_CBasePlayerWeapon__Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_CBasePlayerWeapon__Holster_Post", false );
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CBasePlayerWeapon__Reload_Pre", false );
	RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_CBasePlayerWeapon__PostFrame_Pre", false );
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Ham_CBasePlayerWeapon__AddToPlayer_Post", true );
	RegisterHam( Ham_Weapon_WeaponIdle, WeaponReference, "Ham_CBasePlayerWeapon__WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CBasePlayerWeapon__PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_CBasePlayerWeapon__SecondaryAttack_Pre", false );

	/* -> Register Extra-Item <- */
	gl_iItemId = zp_register_extra_item( "Gauss / Tau Cannon", 0, ZP_TEAM_HUMAN );
}

public ClientCommand__HookWeapon( const pPlayer )
{
	engclient_cmd( pPlayer, WeaponReference );
	return PLUGIN_HANDLED;
}

/* ~ [ Zombie Plague ] ~ */
public zp_extra_item_selected( pPlayer, iItemId )
{
	if ( iItemId != gl_iItemId )
		return PLUGIN_HANDLED;

	return CBasePlayer__GiveWeapon( pPlayer ) ? PLUGIN_CONTINUE : ZP_PLUGIN_HANDLED;
}

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

/* ~ [ ReGameDLL ] ~ */
public RG_CWeaponBox_SetModel_Pre( const pWeaponBox ) 
{
	new pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
	if ( pItem == NULLENT || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HC_CONTINUE;

	SetHookChainArg( 2, ATYPE_STRING, WeaponModelWorld );
	set_entvar( pWeaponBox, var_body, 0 );
	set_entvar( pWeaponBox, var_sequence, 0 );

	return HC_CONTINUE;
}

public Ham_CBasePlayerWeapon__Deploy_Post( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	set_entvar( pPlayer, var_viewmodel, WeaponModelView );
	set_entvar( pPlayer, var_weaponmodel, WeaponModelPlayer );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Draw );

	set_entvar( pItem, var_flPlayAftershock, 0.0 );

	// Charge after deploy
	new iClip = GetWeaponClip( pItem );
	if ( 0 <= iClip < WeaponMaxClip )
	{
		new Float: flGameTime = get_gametime( );
		new Float: flNextCharge; get_entvar( pItem, var_flNextCharge, flNextCharge );

		if ( 0.0 < flNextCharge < flGameTime )
		{
			iClip = min( iClip + floatround( ( flGameTime - flNextCharge ) / WeaponAmmoChargeTime, floatround_floor ), WeaponMaxClip );
			SetWeaponClip( pItem, iClip );

			set_entvar( pItem, var_flNextCharge, ( iClip >= WeaponMaxClip ) ? 0.0 : flGameTime + WeaponAmmoChargeTime );
		}
		else
			set_entvar( pItem, var_flNextCharge, flGameTime + WeaponAmmoChargeTime );
	}

	set_member( pPlayer, m_szAnimExtention, WeaponAnimation );
	set_member( pPlayer, m_flNextAttack, WeaponAnim_Draw_Time );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponAnim_Draw_Time );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Draw_Time );
}

public Ham_CBasePlayerWeapon__Holster_Post( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

	set_entvar( pItem, var_flNextCharge, get_gametime( ) );

	set_member( pItem, m_Weapon_fInAttack, 0 );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

public Ham_CBasePlayerWeapon__Reload_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	set_member( pItem, m_Weapon_fInReload, 0 );
	return HAM_SUPERCEDE;
}

public Ham_CBasePlayerWeapon__PostFrame_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static iClip; iClip = GetWeaponClip( pItem );
	if ( iClip >= WeaponMaxClip )
		return HAM_IGNORED;

	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flNextCharge; get_entvar( pItem, var_flNextCharge, flNextCharge );

	if ( 0.0 < flNextCharge < flGameTime )
	{
		iClip += 1;

		SetWeaponClip( pItem, iClip );
		set_entvar( pItem, var_flNextCharge, ( iClip >= WeaponMaxClip ) ? 0.0 : flGameTime + WeaponAmmoChargeTime );
	}

	return HAM_IGNORED;
}

public Ham_CBasePlayerWeapon__AddToPlayer_Post( const pItem, const pPlayer )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	if ( get_entvar( pItem, var_owner ) <= 0 )
	{
		rg_set_iteminfo( pItem, ItemInfo_pszName, WeaponListDir );
		rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WeaponMaxAmmo );

		new iAmmoType = GetWeaponAmmoType( pItem );
		if ( GetWeaponAmmo( pPlayer, iAmmoType ) < WeaponDefaultAmmo )
			SetWeaponAmmo( pPlayer, WeaponDefaultAmmo, iAmmoType );
	}

	SetWeaponClip( pItem, WeaponMaxClip );

	UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
}

public Ham_CBasePlayerWeapon__WeaponIdle_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flPlayAftershock; flPlayAftershock = Float: get_entvar( pItem, var_flPlayAftershock );
	if ( 0.0 < flPlayAftershock <= flGameTime )
	{
		new iRandom = random( 4 );
		if ( 0 <= iRandom < 3 )
		{
			rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ WeaponSound_Electro4 + iRandom ], random_float( 0.7, 0.8 ) );
		}

		set_entvar( pItem, var_flPlayAftershock, 0.0 );
	}

	if ( Float: get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	if ( get_member( pItem, m_Weapon_fInAttack ) != 0 )
	{
		CGauss__StartFire( pItem, pPlayer, false );

		set_member( pItem, m_Weapon_fInAttack, 0 );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, 2.0 );

		return HAM_SUPERCEDE;
	}

	static iSequence, Float: flIdleTime;
	static Float: flRandom; flRandom = random_float( 0.0, 1.0 );

	if ( flRandom <= 0.5 )
		iSequence = WeaponAnim_Idle1, flIdleTime = WeaponAnim_Idle1_Time;
	else if ( flRandom <= 0.75 )
		iSequence = WeaponAnim_Idle2, flIdleTime = WeaponAnim_Idle2_Time;
	else
		iSequence = WeaponAnim_Fidget, flIdleTime = WeaponAnim_Fidget_Time;

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iSequence );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, flIdleTime );

	return HAM_SUPERCEDE;
}

public Ham_CBasePlayerWeapon__PrimaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );
	if ( get_entvar( pPlayer, var_waterlevel ) == 3 )
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );

		set_member( pItem, m_Weapon_flNextPrimaryAttack, 0.15 );
		set_member( pItem, m_Weapon_flNextSecondaryAttack, 0.15 );

		return HAM_SUPERCEDE;
	}

	new iClip = GetWeaponClip( pItem );
	if ( iClip < 2 )
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pPlayer, m_flNextAttack, 0.5 );

		return HAM_SUPERCEDE;
	}

	CGauss__StartFire( pItem, pPlayer, true );

	iClip -= 2;
	SetWeaponClip( pItem, iClip );
	set_member( pItem, m_Weapon_fInAttack, 0 );
	set_member( pPlayer, m_flNextAttack, WeaponRate );

	return HAM_SUPERCEDE;
}

public Ham_CBasePlayerWeapon__SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	new fInAttack = get_member( pItem, m_Weapon_fInAttack );

	new pPlayer = get_member( pItem, m_pPlayer );
	if ( get_entvar( pPlayer, var_waterlevel ) == 3 )
	{
		if ( fInAttack != 0 )
		{
			rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ WeaponSound_Electro4 ], .pitch = 80 + random_num( 0, 0x3f ) );

			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Idle1 );

			set_member( pItem, m_Weapon_fInAttack, fInAttack = 0 );
			set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Idle1_Time );
		}
		else
		{
			ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		}

		set_member( pItem, m_Weapon_flNextPrimaryAttack, 0.5 );
		set_member( pItem, m_Weapon_flNextSecondaryAttack, 0.5 );

		return HAM_SUPERCEDE;
	}

	new iClip = GetWeaponClip( pItem );
	new Float: flGameTime = get_gametime( );

	if ( fInAttack == 0 )
	{
		if ( iClip <= 0 )
		{
			ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
			set_member( pPlayer, m_flNextAttack, 0.2 );

			return HAM_SUPERCEDE;
		}

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_SpinUp );
		rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ WeaponSound_Charge ], .pitch = 110 );

		set_entvar( pItem, var_flNextAmmoBurn, flGameTime );
		set_entvar( pItem, var_flStartCharge, flGameTime );
		set_entvar( pItem, var_flAmmoStartCharge, flGameTime + WeaponFullChargeTime );
		set_entvar( pItem, var_flNextCharge, 0.0 );

		iClip -= 1;
		SetWeaponClip( pItem, iClip );

		set_member( pItem, m_Weapon_fInAttack, 1 );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, 0.5 );
		// set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_SpinUp_Time );
		set_member( pPlayer, m_flNextAttack, 0.5 );
	}
	else if ( fInAttack == 1 )
	{
		if ( Float: get_member( pItem, m_Weapon_flTimeWeaponIdle ) < flGameTime )
		{
			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Spin );

			set_member( pItem, m_Weapon_fInAttack, 2 );
			// set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Spin_Time );
			// set_member( pPlayer, m_flNextAttack, WeaponAnim_Spin_Time );
		}
	}
	else
	{
		new Float: flNextAmmoBurn = Float: get_entvar( pItem, var_flNextAmmoBurn );
		if ( iClip > 0 && flGameTime >= flNextAmmoBurn && flNextAmmoBurn != 1000.0 )
		{
			set_entvar( pItem, var_flNextAmmoBurn, flGameTime + WeaponChargeRate );

			iClip -= 1;
			SetWeaponClip( pItem, iClip );
		}

		if ( iClip <= 0 )
		{
			CGauss__StartFire( pItem, pPlayer, false );

			set_member( pItem, m_Weapon_fInAttack, 0 );
			set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
			set_member( pPlayer, m_flNextAttack, 1.0 );

			return HAM_SUPERCEDE;
		}

		if ( flGameTime >= Float: get_entvar( pItem, var_flAmmoStartCharge ) )
		{
			set_entvar( pItem, var_flNextAmmoBurn, flNextAmmoBurn = 1000.0 );
		}

		new Float: flStartCharge = floatmin( flGameTime, Float: get_entvar( pItem, var_flStartCharge ) );
		new Float: flPitch = floatmin( 250.0, ( flGameTime - flStartCharge ) * ( 150.0 / WeaponFullChargeTime ) + 100.0 );

		rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ WeaponSound_Charge ], .flags = SND_CHANGE_PITCH, .pitch = floatround( flPitch ) );

		// Charge too long, damage himself
		if ( flStartCharge < flGameTime - WeaponChargeMaxTime )
		{
			rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ WeaponSound_Electro4 ], .pitch = 80 + random_num( 0, 0x3f ) );
			rh_emit_sound2( pPlayer, 0, CHAN_ITEM, WeaponSounds[ WeaponSound_Electro6 ], .pitch = 75 + random_num( 0, 0x03f ) );

			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Idle1 );
			UTIL_ScreenFade( MSG_ONE, pPlayer, 2.0, 0.5, FFADE_IN, { 255, 128, 0 }, 128 );

			ExecuteHamB( Ham_TakeDamage, pPlayer, pItem, pPlayer, WeaponChargeDamageHimSelf, DMG_RADIATION /*DMG_SHOCK*/ );

			set_member( pItem, m_Weapon_fInAttack, 0 );
			set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Idle1_Time );
			set_member( pPlayer, m_flNextAttack, 1.0 );

			return HAM_SUPERCEDE;
		}

		set_member( pPlayer, m_flNextAttack, WeaponRateCharge );
	}

	return HAM_SUPERCEDE;
}

// Phys: https://github.com/ValveSoftware/halflife/blob/master/dlls/gauss.cpp#L312
CGauss__StartFire( const pItem, const pPlayer, const bool: bPrimaryFire = false )
{
	new Float: flDamage;
	new Float: flGameTime = get_gametime( );
	new Vector3( vecSrc ); UTIL_GetEyePosition( pPlayer, vecSrc );
	new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );

	if ( bPrimaryFire )
	{
		flDamage = WeaponBaseDamage;

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Fire2 );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Fire2_Time );
	}
	else
	{
		new Float: flStartCharge = Float: get_entvar( pItem, var_flStartCharge );
		flStartCharge = floatmin( flStartCharge, flGameTime );

		set_entvar( pItem, var_flStartCharge, flStartCharge );

		flDamage = floatmin( WeaponBaseChargeDamage, WeaponBaseChargeDamage * ( ( flGameTime - flStartCharge ) / WeaponFullChargeTime ) );

		if ( get_member( pItem, m_Weapon_fInAttack ) != 3 )
		{
			new Vector3( vecVelocity ); get_entvar( pPlayer, var_velocity, vecVelocity );

			xs_vec_sub_scaled( vecVelocity, vecAiming, 5.0 * flDamage, vecVelocity );
			set_entvar( pPlayer, var_velocity, vecVelocity );
		}

		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Fire1 );

		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Fire1_Time );
		set_member( pPlayer, m_flNextAttack, WeaponAnim_Fire1_Time );
	}

	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ WeaponSound_Fire ] );
	rg_set_animation( pPlayer, PLAYER_ATTACK1 );

	set_entvar( pItem, var_flNextCharge, flGameTime + 1.0 );
	set_entvar( pItem, var_flPlayAftershock, flGameTime + random_float( 0.3, 0.8 ) );
	set_entvar( pPlayer, var_punchangle, Float: { -2.0, 0.0, 0.0 } );

	CGauss__Fire( pItem, pPlayer, bPrimaryFire, vecSrc, vecAiming, flDamage );

	set_member( pItem, m_Weapon_fInAttack, 0 );
}

// Phys: https://github.com/ValveSoftware/halflife/blob/master/dlls/gauss.cpp#L372
// Effects: https://github.com/ValveSoftware/halflife/blob/b59688c56da0919c3780b8c60e5c6a3e80ef6587/cl_dll/ev_hldm.cpp#L864
CGauss__Fire( const pItem, const pPlayer, const bool: bPrimaryFire, Vector3( vecSrc ), Vector3( vecDirection ), Float: flDamage )
{
	new Vector3( vecEndPos ), Vector3( vecPlaneNormal ), Vector3( vecTemp ), Vector3( vecTemp2 );
	new Vector3( vecDest ); xs_vec_add_scaled( vecSrc, vecDirection, 8192.0, vecDest );
	new pEntToSkip = pPlayer;
	new iMaxHits = 10;
	new Float: flValue;
	new bool: bHasPunched = false;
	new bool: bFirstBeam = true;
	new pTrace = create_tr2( );
	new pBeamTrace = create_tr2( );
	new pHit;
	new iBeamColor[ 3 ];

	if ( bPrimaryFire )
		iBeamColor = { 255, 128, 0 };
	else
		iBeamColor = { 255, 255, 255 };

	UTIL_TE_DLIGHT( MSG_PVS, vecSrc, 20, iBeamColor, 6, 24 );

	while ( flDamage > 10.0 && iMaxHits > 0 )
	{
		iMaxHits -= 1;

		engfunc( EngFunc_TraceLine, vecSrc, vecDest, DONT_IGNORE_MONSTERS, pEntToSkip, pTrace );

		if ( get_tr2( pTrace, TR_AllSolid ) ) 
			break;

		pHit = INSTANCE( get_tr2( pTrace, TR_pHit ) );
		if ( pHit == NULLENT ) // ?
			break;

		get_tr2( pTrace, TR_vecEndPos, vecEndPos );

		if ( bFirstBeam )
		{
			UTIL_TE_BEAMENTPOINT( MSG_BROADCAST, ( pPlayer|0x1000 ), gl_iszModelIndex_Beam, vecEndPos, 0, 1, 1, WeaponBeamWidth[ _: bPrimaryFire ], 0, iBeamColor, 255, 0 );

			bFirstBeam = false;
		}
		else
		{
			UTIL_TE_BEAMPOINTS( MSG_BROADCAST, vecSrc, vecEndPos, gl_iszModelIndex_Beam, 0, 1, 1, WeaponBeamWidth[ _: bPrimaryFire ], 0, iBeamColor, 255, 0 );
		}

		if ( get_entvar( pHit, var_takedamage ) != DAMAGE_NO /*&& is_user_alive( pHit ) && zp_get_user_zombie( pHit )*/ )
		{
			rg_multidmg_clear( );

			if ( pHit == pPlayer ) // ?
				set_tr2( pTrace, TR_iHitgroup, HIT_GENERIC );

			ExecuteHamB( Ham_TraceAttack, pHit, pPlayer, flDamage, vecDirection, pTrace, DMG_BULLET );

			rg_multidmg_apply( pItem, pPlayer );
		}

		if ( ExecuteHam( Ham_IsBSPModel, pHit ) && get_entvar( pHit, var_takedamage ) == DAMAGE_NO )
		{
			pEntToSkip = NULLENT;

			get_tr2( pTrace, TR_vecPlaneNormal, vecPlaneNormal );
			flValue = -xs_vec_dot( vecPlaneNormal, vecDirection );

			if ( flValue < 0.5 )
			{
				vecTemp[ 0 ] = 2.0 * vecPlaneNormal[ 0 ] * flValue + vecDirection[ 0 ];
				vecTemp[ 1 ] = 2.0 * vecPlaneNormal[ 1 ] * flValue + vecDirection[ 1 ];
				vecTemp[ 2 ] = 2.0 * vecPlaneNormal[ 2 ] * flValue + vecDirection[ 2 ];

				vecDirection = vecTemp;

				// xs_vec_add_scaled( vecEndPos, vecDirection, 8.0, vecSrc );
				xs_vec_add( vecEndPos, vecDirection, vecSrc );
				xs_vec_add_scaled( vecSrc, vecDirection, 8192.0, vecDest );

				UTIL_TE_GLOWSPRITE( MSG_PVS, vecEndPos, gl_iszModelIndex_Glow, 2, 3 /*floatround( flDamage * flValue * 0.5 * 0.1 )*/, 155 );

				xs_vec_add( vecEndPos, vecPlaneNormal, vecTemp );

				UTIL_TE_SPRITETRAIL( MSG_BROADCAST, vecEndPos, vecTemp, gl_iszModelIndex_Glow, 3, 1, 1, 25, 25 );
				UTIL_RadiusDamage( vecEndPos, pItem, pPlayer, flDamage * flValue, DMG_BLAST );

				flDamage *= ( 1.0 - floatmax( 0.1, flValue ) );
			}
			else
			{
				// Конец луча
				UTIL_GunshotDecalTrace( pHit, vecEndPos );
				UTIL_TE_GLOWSPRITE( MSG_PVS, vecEndPos, gl_iszModelIndex_Glow, 6, 10, 155 );
				UTIL_TE_DLIGHT( MSG_PVS, vecEndPos, 20, iBeamColor, 6, 24 );

				if ( bHasPunched )
					break;

				bHasPunched = true;

				if ( !bPrimaryFire )
				{
					// xs_vec_add_scaled( vecEndPos, vecDirection, 8.0, vecTemp );
					xs_vec_add( vecEndPos, vecDirection, vecSrc );
					engfunc( EngFunc_TraceLine, vecTemp, vecDest, DONT_IGNORE_MONSTERS, pEntToSkip, pBeamTrace );

					if ( !get_tr2( pBeamTrace, TR_AllSolid ) )
					{
						get_tr2( pBeamTrace, TR_vecEndPos, vecTemp );
						engfunc( EngFunc_TraceLine, vecTemp, vecEndPos, DONT_IGNORE_MONSTERS, pEntToSkip, pBeamTrace );

						xs_vec_sub( vecTemp, vecEndPos, vecTemp2 );
						flValue = xs_vec_len( vecTemp2 );

						if ( flValue < flDamage )
						{
							if ( flValue == 0.0 ) flValue = 1.0;
							flDamage -= flValue;

							xs_vec_sub( vecEndPos, vecDirection, vecTemp2 );
							UTIL_TE_SPRITETRAIL( MSG_BROADCAST, vecEndPos, vecTemp2, gl_iszModelIndex_Glow, 3, 1, 1, 25, 25 );

							UTIL_GunshotDecalTrace( INSTANCE( get_tr2( pBeamTrace, TR_pHit ) ), vecTemp );
							UTIL_TE_GLOWSPRITE( MSG_PVS, vecTemp, gl_iszModelIndex_Glow, 6, 1, 155 );
							UTIL_TE_DLIGHT( MSG_PVS, vecTemp, 20, iBeamColor, 6, 24 );

							xs_vec_sub( vecTemp, vecDirection, vecTemp2 );
							UTIL_TE_SPRITETRAIL( MSG_BROADCAST, vecTemp, vecTemp2, gl_iszModelIndex_Glow, 3, 1, 1, 25, 25 );

							xs_vec_add( vecTemp, vecDirection, vecSrc );
						}
					}
					else
					{
						flDamage = 0.0
					}
				}
				else
				{
					if ( bPrimaryFire )
					{
						UTIL_TE_GLOWSPRITE( MSG_PVS, vecEndPos, gl_iszModelIndex_Glow, 3, 2, 155 );

						xs_vec_add( vecEndPos, vecPlaneNormal, vecTemp );
						UTIL_TE_SPRITETRAIL( MSG_BROADCAST, vecEndPos, vecTemp, gl_iszModelIndex_Glow, 3, 1, 1, 25, 25 );
					}

					flDamage = 0.0;
				}
			}
		}
		else
		{
			xs_vec_add( vecEndPos, vecDirection, vecSrc );
			pEntToSkip = pHit;
		}
	}

	free_tr2( pTrace );
	free_tr2( pBeamTrace );
}

public CBasePlayer__GiveWeapon( const pPlayer )
{
	if ( !is_user_alive( pPlayer ) || zp_get_user_zombie( pPlayer ) )
		return false;

	new pItem = rg_give_custom_item( pPlayer, WeaponReference, GT_DROP_AND_REPLACE, WeaponUnicalIndex );
	if ( pItem <= 0 )
		return false;

	return true;
}

/* ~ [ Stocks ] ~ */
// https://github.com/ValveSoftware/halflife/blob/master/dlls/combat.cpp#L1119
stock UTIL_RadiusDamage( const Vector3( vecSrc ), const pInflictor, const pAttacker, const Float: flDamage, const bitsDamageType )
{
	new Vector3( vecVictimOrigin );
	new Float: flRadius = flDamage * 2.5;

	for ( new pVictim = 1; pVictim <= MaxClients; pVictim++ )
	{
		if ( pVictim == pAttacker )
			continue;

		if ( !is_user_alive( pVictim ) )
			continue;

		if ( get_entvar( pVictim, var_takedamage ) == DAMAGE_NO )
			continue;

		get_entvar( pVictim, var_origin, vecVictimOrigin );
		if ( xs_vec_distance( vecSrc, vecVictimOrigin ) > flRadius )
			continue;

		set_member( pVictim, m_LastHitGroup, HIT_GENERIC );
		ExecuteHamB( Ham_TakeDamage, pVictim, pInflictor, pAttacker, flDamage, bitsDamageType );
	}
}

/* -> Weapon Animation <- */
stock UTIL_SendWeaponAnim( const iDest, const pReceiver, const pItem, const iAnim ) 
{
	static iBody; iBody = get_entvar( pItem, var_view_body );

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

		engfunc( EngFunc_PrecacheGeneric, fmt( "sprites/%s.spr", szSprName ) );
	}

	fclose( pFile );
}

/* -> Weapon List <- */
stock UTIL_WeaponList( const iDest, const pReceiver, const pItem, szWeaponName[ MAX_NAME_LENGTH ] = "", const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
{
	if ( szWeaponName[ 0 ] == EOS )
		rg_get_iteminfo( pItem, ItemInfo_pszName, szWeaponName, charsmax( szWeaponName ) );

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

/* -> ScreenFade <- */
stock UTIL_ScreenFade( const iDest, const pReceiver, Float: flDuration = 0.0, Float: flHoldTime = 0.0, const bitsFlags = FFADE_IN, const iColor[ 3 ] = { 0, 0, 0 }, const iAlpha = 255 )
{
	static iMsgId_ScreenFade; if ( !iMsgId_ScreenFade ) iMsgId_ScreenFade = get_user_msgid( "ScreenFade" );

	// https://github.com/alliedmodders/amxmodx/blob/e17d37abe32c82314241a9e27140bee374746115/amxmodx/util.cpp#L185-L207
	#define FixedUnsigned16(%0,%1) clamp( floatround( %0 * %1 ), 0, 0xFFFF ) // 0xFFFF = 65535

	message_begin( iDest, iMsgId_ScreenFade, .player = pReceiver );
	write_short( FixedUnsigned16( flDuration, (1<<12) ) ); // Duration
	write_short( FixedUnsigned16( flHoldTime, (1<<12) ) ); // Hold Time
	write_short( bitsFlags ); // Flags
	write_byte( iColor[ 0 ] ); // Red
	write_byte( iColor[ 1 ] ); // Green
	write_byte( iColor[ 2 ] ); // Blue
	write_byte( iAlpha ); // Alpha
	message_end( );
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

/* -> TE_BEAMPOINTS <- */
stock UTIL_TE_BEAMPOINTS( const iDest, const Vector3( vecStart ), const Vector3( vecEnd ), const iszModelIndex, const iStartFrame, const iFrameRate, const iLife, const iWidth, const iNoise, const iColor[ 3 ], const iBrightness, const iScroll )
{
	message_begin_f( iDest, SVC_TEMPENTITY );
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
	write_byte( iLife ); // Life in 0.1's
	write_byte( iWidth ); // Line width in 0.1's
	write_byte( iNoise ); // Noise
	write_byte( iColor[ 0 ] ); // Red
	write_byte( iColor[ 1 ] ); // Green
	write_byte( iColor[ 2 ] ); // Blue
	write_byte( iBrightness ); // Brightness
	write_byte( iScroll ); // Scroll speed in 0.1's
	message_end( );
}

/* -> TE_GLOWSPRITE <- */
stock UTIL_TE_GLOWSPRITE( const iDest, const Vector3( vecOrigin ), const iszModelIndex, const iLife, const iScale, const iBrightness )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_GLOWSPRITE ); // Temp.entity ID
	write_coord_f( vecOrigin[ 0 ] ); // Position X
	write_coord_f( vecOrigin[ 1 ] ); // Position Y
	write_coord_f( vecOrigin[ 2 ] ); // Position Z
	write_short( iszModelIndex ); // Sprite index
	write_byte( iLife ); // Life in 0.1's
	write_byte( iScale ); // Scale
	write_byte( iBrightness ); // Brightness
	message_end( );
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