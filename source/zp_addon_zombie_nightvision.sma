public stock const PluginName[ ] =			"[ZP] Addon: Custom NightVision";
public stock const PluginVersion[ ] =		"1.0";
public stock const PluginAuthor[ ] =		"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <zp_stocks>

#include <zombieplague>
#include <custom_weather>

/* ~ [ Plugin Settings ] ~ */
new const NightVisionSounds[ ][ ] = {
	"sound/items/nvg_off.wav",
	"sound/items/nvg_on.wav"
};
new const MapLightLevelWithNV[ ] =			"v"; // Какое освещение будет при ВКЛЮЧЕНОМ найтвижене
new const NightVisionColors[ 2 ][ 3 ] = {
	// R, G, B
	{ 48, 255, 48 }, // Human
	{ 255, 48, 48 } // Zombie
};

/* ~ [ Params ] ~ */
new gl_bitsUserNightVision;
new bool: gl_bBlockNightVision = true;

enum eForwards {
	FW_USER_TRY_NIGHT_VISION,
	FW_USER_SET_NIGHT_VISION
};
new gl_fwForward[ eForwards ];

/* ~ [ Macroses ] ~ */
#define IsUserOnNightVision(%0)				BIT_VALID( gl_bitsUserNightVision, BIT_PLAYER( %0 ) )

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( )
{
	register_native( "zp_get_user_nightvision", "native_get_user_nightvision", 1 );
	register_native( "zp_set_user_nightvision", "native_set_user_nightvision", 1 );
}

public plugin_precache( )
{
	/* -> Forwards <- */
	gl_fwForward[ FW_USER_TRY_NIGHT_VISION ] = CreateMultiForward( "zp_user_try_nightvision", ET_CONTINUE, FP_CELL );
	gl_fwForward[ FW_USER_SET_NIGHT_VISION ] = CreateMultiForward( "zp_user_use_nightvision", ET_CONTINUE, FP_CELL, FP_CELL );

	/* -> Precache Generic <- */
	for ( new i; i < sizeof NightVisionSounds; i++ )
		engfunc( EngFunc_PrecacheGeneric, NightVisionSounds[ i ] );
}

public plugin_init( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

	/* -> ReGameDLL <- */
	RegisterHookChain( RG_CBasePlayer_Killed, "RG_CBasePlayer__Killed_Post", true );
	RegisterHookChain( RG_CSGameRules_RestartRound, "RG_CSGameRules__RestartRound_Post", true );

	/* -> Register Client Commands <- */
	register_clcmd( "nightvision", "ClientCommand__ToggleNightVision" );
}

public client_putinserver( pPlayer ) BIT_SUB( gl_bitsUserNightVision, BIT_PLAYER( pPlayer ) );

public ClientCommand__ToggleNightVision( const pPlayer )
{
	if ( is_user_alive( pPlayer ) && !gl_bBlockNightVision )
	{
		new fwReturn;
		ExecuteForward( gl_fwForward[ FW_USER_TRY_NIGHT_VISION ], fwReturn, pPlayer );

		if ( fwReturn == ZP_PLUGIN_HANDLED )
			return PLUGIN_HANDLED;

		BIT_INVERT( gl_bitsUserNightVision, BIT_PLAYER( pPlayer ) );
		CBasePlayer__UpdateNightVision( pPlayer );

		client_cmd( pPlayer, "spk ^"%s^"", NightVisionSounds[ IsUserOnNightVision( pPlayer ) ] );
	}

	return PLUGIN_HANDLED;
}

/* ~ [ Zombie Plague ] ~ */
public zp_round_started( iGameMode, pPlayer )
{
	gl_bBlockNightVision = false;

	if ( iGameMode != MODE_NEMESIS )
		return;

	BIT_CLEAR( gl_bitsUserNightVision );
	CBasePlayer__UpdateNightVision( 0 );

	BIT_ADD( gl_bitsUserNightVision, BIT_PLAYER( pPlayer ) );
}

public zp_round_ended( )
{
	gl_bBlockNightVision = true;

	BIT_CLEAR( gl_bitsUserNightVision );
	CBasePlayer__UpdateNightVision( 0 );
}

public zp_user_humanized_post( pPlayer )
{
	if ( !is_user_connected( pPlayer ) )
		return;

	BIT_SUB( gl_bitsUserNightVision, BIT_PLAYER( pPlayer ) );
	CBasePlayer__UpdateNightVision( pPlayer );
}

public zp_user_infected_post( pPlayer )
{
	if ( !is_user_connected( pPlayer ) )
		return;

	BIT_ADD( gl_bitsUserNightVision, BIT_PLAYER( pPlayer ) );
	set_task( 0.01, "CTask__UpdateNightVision", pPlayer );
}

/* ~ [ Tasks ] ~ */
public CTask__UpdateNightVision( const pPlayer )
	CBasePlayer__UpdateNightVision( pPlayer );

/* ~ [ ReGameDLL ] ~ */
public RG_CBasePlayer__Killed_Post( const pVictim )
{
	if ( !IsUserOnNightVision( pVictim ) )
		return;

	BIT_SUB( gl_bitsUserNightVision, BIT_PLAYER( pVictim ) );
	CBasePlayer__UpdateNightVision( pVictim );
}

public RG_CSGameRules__RestartRound_Post( )
{
	BIT_CLEAR( gl_bitsUserNightVision );
	CBasePlayer__UpdateNightVision( 0 );
}

/* ~ [ Other ] ~ */
public CBasePlayer__UpdateNightVision( const pPlayer )
{
	if ( pPlayer > 0 && !IsUserValid( pPlayer ) )
		return;

	new fwReturn;
	if ( IsUserOnNightVision( pPlayer ) )
	{
		ExecuteForward( gl_fwForward[ FW_USER_SET_NIGHT_VISION ], fwReturn, pPlayer, true );

		if ( fwReturn != ZP_PLUGIN_HANDLED )
			zc_set_lighting( pPlayer, MapLightLevelWithNV );

		UTIL_ScreenFade( pPlayer == 0 ? MSG_ALL : MSG_ONE, pPlayer, 255.0, 255.0, FFADE_STAYOUT, NightVisionColors[ zp_get_user_zombie( pPlayer ) ], 70 );
	}
	else
	{
		ExecuteForward( gl_fwForward[ FW_USER_SET_NIGHT_VISION ], fwReturn, pPlayer, false );

		if ( fwReturn != ZP_PLUGIN_HANDLED )
			zc_reset_lighting( pPlayer );

		UTIL_ScreenFade( pPlayer == 0 ? MSG_ALL : MSG_ONE, pPlayer, 0.0, 0.0, FFADE_OUT, { 0, 0, 0 }, 0 );
	}
}

/* ~ [ Natives ] ~ */
public bool: native_get_user_nightvision( const pPlayer )
{
	if ( !is_user_connected( pPlayer ) )
		return false;

	return IsUserOnNightVision( pPlayer );
}

public bool: native_set_user_nightvision( const pPlayer, const bool: bSet )
{
	if ( !is_user_connected( pPlayer ) )
		return false;

	( bSet ) ? BIT_ADD( gl_bitsUserNightVision, BIT_PLAYER( pPlayer ) ) : BIT_SUB( gl_bitsUserNightVision, BIT_PLAYER( pPlayer ) );
	return true;
}
