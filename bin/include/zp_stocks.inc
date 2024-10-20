#if defined _zp_stocks_included
	#endinput
#endif
#define _zp_stocks_included

#if !defined _zp_const_included
	#include <zp_const>
#endif

#if !defined _zp_colored_print_included
	#include <zp_colored_print>
#endif

#if !defined _xs_included
	#include <xs>
#endif

#if !defined _fubentity_included
	#include <api_fubentity>
#endif

// https://github.com/s1lentq/ReGameDLL_CS/blob/f57d28fe721ea4d57d10c010d15d45f05f2f5bad/regamedll/engine/shake.h#L43
#define FFADE_IN							0x0000 // Just here so we don't pass 0 into the function
#define FFADE_OUT							0x0001 // Fade out (not in)
#define FFADE_MODULATE						0x0002 // Modulate (don't blend)
#define FFADE_STAYOUT						0x0004 // ignores the duration, stays faded out until new ScreenFade message received

/**
 * Level System
 */
stock ExperienceForNewLevel( const iLevel )
{
	static pCvarCached;
	if ( !pCvarCached )
		pCvarCached = get_cvar_pointer( "zp_exp_multiplier" );

	return ( iLevel * ( iLevel + 1 ) * get_pcvar_num( pCvarCached ) );
}
#define GetPercentExperience(%0,%1,%2)		Float: ( 100.0 / ExperienceForNewLevel( %1 ) * %2 )

/**
 * Macroses for works with bitsums
 */
#define BIT_PLAYER(%0)						( BIT( %0 - 1 ) )
#define BIT_ADD(%0,%1)						( %0 |= %1 )
#define BIT_SUB(%0,%1)						( %0 &= ~%1 )
#define BIT_VALID(%0,%1)					( ( %0 & %1 ) == %1 )
#define BIT_GET(%0,%1)						( %0 & %1 )
#define BIT_GET_BOOL(%0,%1)					( ( %0 & %1 ) ? true : false )
#define BIT_INVERT(%0,%1)					( %0 ^= %1 )
#define BIT_CLEAR(%0)						( %0 = 0 )
#define BIT_FILL(%0)						( %0 = -1 )

/**
 * Generaly Macroses
 */
#if !defined Vector3
	#define Vector3(%0)						Float: %0[ 3 ]
#endif
#define INSTANCE(%0)						( ( %0 == -1 ) ? 0 : %0 )
#define DebugVector(%0)						server_print( "%f %f %f", %0[ 0 ], %0[ 1 ], %0[ 2 ] )
#define IsNullVector(%0)					bool: ( ( %0[ 0 ] + %0[ 1 ] + %0[ 2 ] ) == 0.0 )
#define IsNullString(%0)					bool: ( %0[ 0 ] == EOS )
#define ClearString(%0)						( %0 = "^0" )
#define IsOnLadder(%0)						bool: ( get_entvar( %0, var_movetype ) == MOVETYPE_FLY )
#define IsValidTeam(%0)						bool: ( TEAM_TERRORIST <= %0 <= TEAM_CT )
#define IsUserValid(%0)						bool: ( 0 < %0 <= MaxClients )
#define IsValidPlayer						IsUserValid
#define IsUserAlive(%0)						BIT_VALID( gl_bitsUserAlive, BIT_PLAYER( %0 ) )
#define IsUserConnected(%0)					bool: ( IsUserValid( %0 ) && BIT_VALID( gl_bitsUserConnected, BIT_PLAYER( %0 ) ) )
#define SetFormatex(%0,%1,%2)				( %1 = formatex( %0, charsmax( %0 ), %2 ) )
#define AddFormatex(%0,%1,%2)				( %1 += formatex( %0[ %1 ], charsmax( %0 ) - %1, %2 ) )
#define ReduceNumByPercent(%0,%1)			( %0 * ( 1.0 - %1 / 100.0 ) )
#define mod(%0,%1)							( %0 % %1 )

// https://github.com/alliedmodders/amxmodx/blob/e17d37abe32c82314241a9e27140bee374746115/amxmodx/util.cpp#L185-L207
#define FixedUnsigned16(%0,%1)				clamp( floatround( %0 * %1 ), 0, 0xFFFF ) // 0xFFFF = 65535
#define FixedSigned16(%0,%1)				clamp( floatround( %0 * %1 ), -32768, 32767 )

/**
 * Weapon Macroses
 */
#define IsCustomWeapon(%0,%1)				bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponState(%0)					get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)				set_member( %0, m_Weapon_iWeaponState, %1 )
#define GetWeaponClip(%0)					get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)				set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)				get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)				get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)				set_member( %0, m_rgAmmo, %1, %2 )
#define AdjustDamage(%0,%1)					( %0 * ( 1.0 - floatmin( %1, 0.7 ) ) )

#define BITS_PRIMARY_WEAPONS				( BIT( CSW_SCOUT )|BIT( CSW_XM1014 )|BIT( CSW_MAC10 )|BIT( CSW_AUG )|BIT( CSW_UMP45 )|BIT( CSW_SG550 )|BIT( CSW_GALIL )|BIT( CSW_FAMAS )|BIT( CSW_AWP )|BIT( CSW_MP5NAVY )|BIT( CSW_M249 )|BIT( CSW_M3 )|BIT( CSW_M4A1 )|BIT( CSW_TMP )|BIT( CSW_G3SG1 )|BIT( CSW_SG552 )|BIT( CSW_AK47 )|BIT( CSW_P90 ) )
#define BITS_SECONDARY_WEAPONS				( BIT( CSW_P228 )|BIT( CSW_GLOCK )|BIT( CSW_ELITE )|BIT( CSW_FIVESEVEN )|BIT( CSW_USP )|BIT( CSW_GLOCK18 )|BIT( CSW_DEAGLE ) )
#define BITS_KNIFE							( BIT( CSW_KNIFE ) )
#define BITS_GRENADES						( BIT( CSW_HEGRENADE )|BIT( CSW_SMOKEGRENADE )|BIT( CSW_FLASHBANG ) )
#define BITS_C4								( BIT( CSW_C4 ) )

#define var_knockback_power					var_flFallVelocity

#define zp_get_user_infinity_ammo(%0)		get_member( %0, m_iWeaponInfiniteAmmo )

/**
 * Human Classes Macroses
 */
#define zp_human_class_id(%0)				( CD_HumanClasses + %0 )
#define zp_human_class_convert_id(%0)		( %0 - CD_HumanClasses )

#define zp_get_human_class_id(%0)			cd_get_if( CD_TempData, %0, eType_Integer )
#define zp_get_user_human_class(%0)			cd_get( %0, CD_kPlayer_HumanClass, eType_Integer )
// #define zp_get_human_class_gender(%0)		cd_get_if( %0, CD_kHumanClass_Gender, eType_Integer, 0 )
// #define zp_get_user_hand_body(%0)			zp_get_human_class_gender( zp_get_user_human_class( %0 ) )
#define zp_get_user_hand_body(%0)			cd_get( zp_get_user_player_skin( %0 ), CD_kSkin_Sex, eType_Integer )

stock zp_is_valid_human_class( const iHumanClassId )
{
	static iHumanClassesCount;
	if ( !iHumanClassesCount )
		iHumanClassesCount = cd_get( CD_TempData, CD_kHumanClass_Count, eType_Integer );

	return ( CD_HumanClasses <= iHumanClassId < zp_human_class_id( iHumanClassesCount ) )
}

/**
 * Human Classes Abilities Macroses
 */
#define zp_ability_id(%0)					( CD_HumanAbilities + %0 )
#define zp_ability_convert_id(%0)			( %0 - CD_HumanAbilities )

#define zp_get_ability_id(%0)				cd_get_if( CD_TempData, %0, eType_Integer )

stock zp_is_valid_ability( const iAbilityIndex )
{
	static iAbilitiesCount;
	if ( !iAbilitiesCount )
		iAbilitiesCount = cd_get( CD_TempData, CD_kAbility_Count, eType_Integer );

	return ( CD_HumanAbilities <= iAbilityIndex < zp_ability_id( iAbilitiesCount ) );
}

stock bool: zp_check_user_ability_level( const pPlayer, const iAbilityIndex )
{
	if ( cd_get( iAbilityIndex, CD_kAbility_Level, eType_Integer ) > zp_get_user_human_class_data( pPlayer, User_Level ) )
		return false;

	return true;
}

stock zp_set_user_ability_limits( const pPlayer, const iAbilityIndex, const bool: bUseForward = true, &iValue = -1 )
{
	if ( cd_isset( iAbilityIndex, CD_kAbility_Timer ) )
	{
		new Float: flTimer = get_gametime( ) + Float: cd_get( iAbilityIndex, CD_kAbility_Timer, eType_Float );
		iValue = floatround( flTimer, floatround_ceil );
		cd_set( pPlayer, fmt( "%s%i", CD_kPlayer_Ability_Timer, iAbilityIndex ), eType_Float, flTimer, bUseForward );
		
		return AbilityLimit_Timer;
	}

	if ( cd_isset( iAbilityIndex, CD_kAbility_Round ) )
	{
		iValue = get_member_game( m_iTotalRoundsPlayed ) + cd_get( iAbilityIndex, CD_kAbility_Round );
		cd_set( pPlayer, fmt( "%s%i", CD_kPlayer_Ability_Round, iAbilityIndex ), eType_Integer, iValue, bUseForward );
		
		return AbilityLimit_Round;
	}

	if ( cd_isset( iAbilityIndex, CD_kAbility_Map ) )
	{
		new szTempBuffer[ 16 ]; formatex( szTempBuffer, charsmax( szTempBuffer ), "%s%i", CD_kPlayer_Ability_Map, iAbilityIndex );
		iValue = cd_get( pPlayer, szTempBuffer ) + 1;
		cd_set( pPlayer, szTempBuffer, eType_Integer, iValue, bUseForward );

		return AbilityLimit_Map;
	}

	return AbilityLimit_Nothing;
}

stock zp_get_user_ability_limits( const pPlayer, const iAbilityIndex, &iValue = -1 )
{
	if ( cd_isset( iAbilityIndex, CD_kAbility_Map ) )
	{
		iValue = cd_get( pPlayer, fmt( "%s%i", CD_kPlayer_Ability_Map, iAbilityIndex ) );
		if ( iValue >= cd_get( iAbilityIndex, CD_kAbility_Map ) )
			return AbilityLimit_Map;
	}

	if ( cd_isset( iAbilityIndex, CD_kAbility_Round ) )
	{
		new iTotalRoundsPlayed = get_member_game( m_iTotalRoundsPlayed );
		iValue = cd_get( pPlayer, fmt( "%s%i", CD_kPlayer_Ability_Round, iAbilityIndex ) );

		if ( iValue > iTotalRoundsPlayed )
		{
			iValue -= iTotalRoundsPlayed;
			return AbilityLimit_Round;
		}
	}

	if ( cd_isset( iAbilityIndex, CD_kAbility_Timer ) )
	{
		new Float: flGameTime = get_gametime( );
		new Float: flTimer = Float: cd_get( pPlayer, fmt( "%s%i", CD_kPlayer_Ability_Timer, iAbilityIndex ), eType_Float );

		if ( flTimer > flGameTime )
		{
			iValue = floatround( flTimer - flGameTime, floatround_ceil );
			return AbilityLimit_Timer;
		}
	}

	iValue = -1;
	return AbilityLimit_Nothing;
}

#define zp_get_ability_attributes(%0)		cd_get( %0, CD_kAbility_Attributes, eType_Integer )
stock zp_get_ability_attribute_value( const iAbilityIndex, const iAttribute )
{
	if ( !zp_is_valid_ability( iAbilityIndex ) )
		return -1;

	if ( !zp_get_ability_attributes( iAbilityIndex ) )
		return -1;

	return cd_get_if( iAbilityIndex, fmt( "%s%i", CD_kAbility_Attributes, max( 0, iAttribute ) ), eType_Integer, -1 );
}

/**
 * Zombie Classes Macroses
 */
#define zp_zombie_class_id(%0)				( %0 - CD_ZombieClasses )
#define zp_zombie_class_convert_id(%0)		( CD_ZombieClasses + %0 )

/**
 * Buy Menu Macroses
 */
#define zp_bm_category_id(%0)				( CD_Category_Pistols + %0 )
#define zp_bm_category_convert_id(%0)		( %0 - CD_Category_Pistols )

/**
 * Weapon Upgrades Macroses
 */
#define zp_upgrade_id(%0)					( CD_UpgradeWeapons + %0 )
#define zp_upgrade_convert_id(%0)			( %0 - CD_UpgradeWeapons )

stock zp_get_user_weapon_level( const pPlayer, const iUpgradeIndex )
	return cd_get( pPlayer, fmt( "%s%i", CD_kPlayer_Upgrade_Level, iUpgradeIndex ), eType_Integer );

stock zp_get_user_weapon_progress( const pPlayer, const iUpgradeIndex )
	return cd_get( pPlayer, fmt( "%s%i", CD_kPlayer_Upgrade_Progress, iUpgradeIndex ), eType_Integer );

stock zp_is_valid_upgrade( const iUpgradeIndex )
{
	static iUpgradesCount;
	if ( !iUpgradesCount )
		iUpgradesCount = cd_get( CD_TempData, CD_kUpgrades_Count, eType_Integer );

	return ( CD_UpgradeWeapons <= iUpgradeIndex < zp_upgrade_id( iUpgradesCount ) )
}

stock zp_get_upgrade_max_level( const iUpgradeIndex )
	return cd_get( iUpgradeIndex, CD_kUpgrade_Weapon_MaxLevel, eType_Integer );

/**
 * Quests Macroses
 */
#define zp_quest_id(%0)						( CD_QuestsData + %0 )
#define zp_get_quest_id(%0)					cd_get_if( CD_TempData, %0, eType_Integer )

stock zp_is_valid_quest( const iQuestIndex )
{
	static iQuestsCount;
	if ( !iQuestsCount )
		iQuestsCount = cd_get( CD_TempData, CD_kQuests_Count, eType_Integer );

	return ( CD_QuestsData <= iQuestIndex < zp_quest_id( iQuestsCount ) );
}

stock zp_set_user_quest_progress( const pPlayer, const iQuestPosition, const iValue, const bool: bUseForward = true )
	zp_set_user_quest_data( pPlayer, CD_kPlayer_Quest_Progress, iQuestPosition, iValue, bUseForward );

stock zp_get_user_quest_progress( const pPlayer, const iQuestPosition )
	return zp_get_user_quest_data( pPlayer, CD_kPlayer_Quest_Progress, iQuestPosition );

stock zp_get_user_quest_goal( const pPlayer, const iQuestIndex, const iQuestPosition )
	return cd_get( iQuestIndex, fmt( "%s%i", CD_kQuest_Goal, zp_get_user_quest_data( pPlayer, CD_kPlayer_Quest_GoalIndex, iQuestPosition ) ), eType_Integer );

stock zp_set_user_quest_data( const pPlayer, const szKey[ ], const iQuestPosition, const iValue, const bool: bUseForward = true )
	cd_set( pPlayer, fmt( "%s%i", szKey, iQuestPosition ), eType_Integer, iValue, bUseForward );

stock zp_get_user_quest_data( const pPlayer, const szKey[ ], const iQuestPosition )
	return cd_get( pPlayer, fmt( "%s%i", szKey, iQuestPosition ), eType_Integer );

stock zp_reset_user_quest( const pPlayer, const iQuestPosition, const bool: bUseForward = true )
{
	zp_set_user_quest_data( pPlayer, CD_kPlayer_Quest, iQuestPosition, 0, bUseForward );
	zp_set_user_quest_data( pPlayer, CD_kPlayer_Quest_Progress, iQuestPosition, 0, bUseForward );
	zp_set_user_quest_data( pPlayer, CD_kPlayer_Quest_Update, iQuestPosition, 0, bUseForward );
	zp_set_user_quest_data( pPlayer, CD_kPlayer_Quest_GoalIndex, iQuestPosition, 0, bUseForward );
}

/**
 * Player Skins Macroses
 */
#define zp_player_skin_id(%0)				( CD_PlayerSkins + %0 )
#define zp_player_skin_convert_id(%0)		( %0 - CD_PlayerSkins )
#define zp_get_user_player_skin(%0)			cd_get( %0, CD_kPlayerSkin_Index, eType_Integer )
#define zp_get_user_player_skin_sql_index(%0,%1) cd_get( %0, fmt( "%s%s", %1, CD_kPlayerSkin_SqlIndex ), eType_Integer )
#define zp_get_player_skin_id(%0)			cd_get_if( CD_TempData, %0, eType_Integer )
#define zp_player_skin_loaded(%0)			cd_isset( CD_TempData, %0 )
stock bool: zp_player_skin_valid( const iPlayerSkinIndex )
{
	static iSkinsCount;
	if ( !iSkinsCount )
		iSkinsCount = cd_get( CD_TempData, CD_kSkins_Count, eType_Integer );

	return bool: ( CD_PlayerSkins <= iPlayerSkinIndex < zp_player_skin_id( iSkinsCount ) );
}

/**
 * SQL Macroses
 */
#define zp_sql_user_index(%0)				cd_get_if( %0, CD_kSQL_Player_Index, eType_Integer, 0 )
#define zp_sql_user_loaded(%0)				cd_get_if( %0, CD_kSQL_Player_Loaded, eType_Integer, false )

/**
 * Zombie Evolution
 */
#define zp_get_evolution_level(%0)			cd_get( %0, CD_kPlayer_ZmEvoLevel, eType_Integer )

stock zp_set_evolution_level( const pPlayer, const iValue, const bool: bUseForward = true )
	cd_set( pPlayer, CD_kPlayer_ZmEvoLevel, eType_Integer, iValue, bUseForward );

#define zp_get_evolution_progress(%0)		cd_get( %0, CD_kPlayer_ZmEvoProgress, eType_Integer )

stock zp_set_evolution_progress( const pPlayer, const iValue, const bool: bUseForward = true )
	cd_set( pPlayer, CD_kPlayer_ZmEvoProgress, eType_Integer, iValue, bUseForward );

/**
 * Zombie Ability
 */
stock Float: zp_get_ability_timer( const pPlayer, Float: flTime )
{
	flTime *= Float: ( zp_get_evolution_level( pPlayer ) ? EvolutionCoolDownMultiplier : 1.0 );
	flTime += get_gametime( );

	return flTime;
}

stock bool: zp_ability_in_cooldown( const Float: flTime, Float: flGameTime = -1.0 )
{
	if ( flGameTime <= 0.0 )
		flGameTime = get_gametime( );

	return bool: ( flTime > flGameTime );
}

stock Float: zp_get_ability_cooldown( const Float: flTime, Float: flGameTime = -1.0 )
{
	if ( flGameTime <= 0.0 )
		flGameTime = get_gametime( );

	return Float: ( flTime + 1.0 - flGameTime );
}

#define zp_set_zombie_timer(%0,%1,%2)		set_entvar( %1, var_ability_time, Float: zp_get_ability_timer( %0, %2 ) )

stock zp_remove_ability_hud( const pPlayer )
{
	if ( task_exists( pPlayer + TaskId_ZombieAbilityInformer ) )
		remove_task( pPlayer + TaskId_ZombieAbilityInformer );
}

stock zp_user_ability_hud( const pPlayer, const szHudInfo[ ], Float: flUpdateTime = 1.0 )
{
	if ( IsNullString( szHudInfo ) )
		return;

	flUpdateTime += 0.05;

	// set_dhudmessage(
	// 	255, 0, 0, 
	// 	0.75, 0.18, 
	// 	0,
	// 	0.0, flUpdateTime,
	// 	0.0, 0.0
	// );
	// show_dhudmessage( pPlayer, "%l", "ML_Zombie_Abilities" );

	set_hudmessage(
		// 255, 255, 255,
		// 0.75, 0.225,
		250, 180, 30, 0.75, 1.0,
		0,
		0.0, flUpdateTime,
		0.0, 0.0
	);
	show_hudmessage( pPlayer, "%s^n^n", szHudInfo );
}

/**
 * User Settings
 */
#define zp_get_user_tutor_flag(%0,%1)		bool: ( BIT_VALID( cd_get( %0, CD_kPlayer_Settings, eType_Integer ), %1 ) )
#define zp_get_user_setting					zp_get_user_tutor_flag

#if defined TutorAPI
	stock bool: zp_show_tutor( const pPlayer, const iTutorType = TutorTypeDefault, const Float: flTime = 0.0, const iSound = TutorSoundNone, const szMessage[ ], any:... )
	{
		new szBuffer[ MAX_TUTOR_LENGTH ];
		vformat( szBuffer, MAX_TUTOR_LENGTH - 1, szMessage, 6 );

		TutorShow( pPlayer, iTutorType, flTime, BIT_VALID( cd_get( pPlayer, CD_kPlayer_Settings, eType_Integer ), TutorFlag_Sounds ) ? iSound : TutorSoundNone, szBuffer );
		return true;
	}
#endif

/**
 * Other
 */
stock bool: zp_get_user_godmode( const pPlayer )
{
	if ( task_exists( TaskId_RemoveGodMode + pPlayer ) || get_entvar( pPlayer, var_takedamage ) == DAMAGE_NO )
		return true;

	return false;
}

stock zp_remove_user_godmode( const pPlayer, const bool: bSkipCheck = false )
{
	if ( !bSkipCheck && !zp_get_user_godmode( pPlayer ) )
		return;

	set_entvar( pPlayer, var_takedamage, DAMAGE_YES );
	UTIL_SetEntityRendering( pPlayer );

	remove_task( TaskId_RemoveGodMode + pPlayer );
}

/**
 * Register commands with static array
 * Original: https://dev-cs.ru/threads/222/post-76443
 */
#define register_cmd_list(%0,%1,%2)			for ( new i; i < sizeof %1; i++ ) register_%0( %1[ i ], %2 )

// https://dev-cs.ru/threads/222/page-12#post-101649
stock SERVER_PRINT( const szBuffer[ ] )
{
	for ( new i, iLen = strlen( szBuffer ); i < iLen; i += 255 ) {
		engfunc( EngFunc_ServerPrint, fmt( "%-255s", szBuffer[ i ] ) );
	}
	engfunc( EngFunc_ServerPrint, "" );
}

stock Entity_SetThink( const pEntity, const szCallBack[ ] = "", const Float: flNextThink = 0.0, const aData[ ] = "", const iDataLen = 0 )
{
	SetThink( pEntity, szCallBack, aData, iDataLen );
	set_entvar( pEntity, var_nextthink, flNextThink );
}

/* -> Precache player model and get model index <- */
stock zp_precache_player_model( const szPlayerModel[ ] )
{
	return engfunc( EngFunc_PrecacheModel, fmt( "models/player/%s/%s.mdl", szPlayerModel, szPlayerModel ) );
}

#define zp_get_user_skulls(%0)				cd_get( %0, CD_kPlayer_Skulls, eType_Integer )
#define zp_set_user_skulls(%0,%1)			cd_set( %0, CD_kPlayer_Skulls, eType_Integer, %1, true )

stock zp_get_user_money( const pPlayer )
{
	if ( !is_user_connected( pPlayer ) )
		return 0;

	return get_member( pPlayer, m_iAccount );
}

stock bool: zp_set_user_money( const pPlayer, const iValue )
{
	if ( !is_user_connected( pPlayer ) )
		return false;

	set_member( pPlayer, m_iAccount, max( 0, iValue ) );
	return true;
}

stock bool: zp_give_user_money( const pPlayer, const iAmount, const bool: bDrawHud = false )
{
	if ( !is_user_connected( pPlayer ) )
		return false;

	if ( iAmount == 0 )
		return false;

	if ( bDrawHud )
	{
		new bAddMoney = bool: ( iAmount > 0 );

		static bool: bYOffset[ MAX_PLAYERS + 1 ];
		bYOffset[ pPlayer ] = !bYOffset[ pPlayer ];

		set_dhudmessage(
			bAddMoney ? 0 : 255, bAddMoney ? 255 : 0, 0,
			-1.0, 0.53,
			2,
			6.0, 1.1,
			0.03, 0.2
		);

		new szMoney[ 16 ]; UTIL_FormatNumber( iAmount, szMoney, charsmax( szMoney ) );
		show_dhudmessage( pPlayer, "%s%s%s $", bYOffset[ pPlayer ] ? "^n" : "", bAddMoney ? "+" : "", szMoney );
	}

	rg_add_account( pPlayer, iAmount );
	return true;
}

/* -> Use ScreenFade message with NightVision check <- */
stock bool: zp_set_user_screen_fade( const pPlayer, const Float: flDuration = 0.0, const Float: flHoldTime = 0.0, const bitsFlags = FFADE_IN, const iColor[ 3 ] = { 0, 0, 0 }, const iAlpha = 255 )
{
	if ( zp_get_user_nightvision( pPlayer ) )
		return false;

	UTIL_ScreenFade( pPlayer == 0 ? MSG_ALL : MSG_ONE, pPlayer, flDuration, flHoldTime, bitsFlags, iColor, iAlpha );
	return true;
}

/* -> Menu buttons <- */
stock UTIL_MenuButton( const iNumber = -1, const bool: bActive = true, const szSpecialChar = '#' )
{
	new szButton[ 8 ];
	if ( iNumber == -1 )
		formatex( szButton, charsmax( szButton ), "\d%c", szSpecialChar );
	else if ( !bActive )
		formatex( szButton, charsmax( szButton ), "\d%i.", iNumber );
	else
		formatex( szButton, charsmax( szButton ), "%s%i.\w", MenuNumbersColor, iNumber );
	
	return szButton;
}

/* -> Set User Model Index <- */
stock rg_set_user_model_index( const pPlayer, const iModelIndex )
{
	if ( is_nullent( pPlayer ) )
		return;

	set_member( pPlayer, m_modelIndexPlayer, iModelIndex );
	set_entvar( pPlayer, var_modelindex, iModelIndex );
}

/* -> Auto-create newmenus <- */
stock zp_create_menu( const szMenuHandler[ ], const szMenuName[ ], any:... )
{
	new szBuffer[ MAX_INFO_LENGTH ];
	vformat( szBuffer, charsmax( szBuffer ), szMenuName, 3 );

	new iMenuIndex = menu_create( szBuffer, szMenuHandler );

	menu_setprop( iMenuIndex, MPROP_BACKNAME, fmt( "%l", "ML_Back" ) );
	menu_setprop( iMenuIndex, MPROP_NEXTNAME, fmt( "%l", "ML_Next" ) );
	menu_setprop( iMenuIndex, MPROP_EXITNAME, fmt( "%l", "ML_Exit" ) );
	menu_setprop( iMenuIndex, MPROP_NUMBER_COLOR, MenuNumbersColor );

	return iMenuIndex;
}

/* -> Format colors for menu <- */
stock format_color_for_menu( szBuffer[ ], const iLen )
{
	for ( new i = 0; i < iLen; i++ )
	{
		if ( szBuffer[ i ] != '!' )
			continue;

		switch ( szBuffer[ i + 1 ] )
		{
			case 'r', 'y', 'w', 'd': szBuffer[ i ] = '\';
			case 'n': szBuffer[ i ] = 94; // ^n
		}
	}
}

/* -> Remove tags <- */
stock format_replace_tags( szBuffer[ ], const iLen )
{
	for ( new i = 0, bool: bSlash = false, iCharIndex[ 2 ], iTempBuffer; i < iLen; i++ )
	{
		if ( szBuffer[ i ] != '!' && szBuffer[ i ] != '\' )
			continue;

		if ( szBuffer[ i ] == '\' )
			bSlash = true;

		// if ( szBuffer[ i + 1 ] != 'r' && szBuffer[ i + 1 ] != 'y' && szBuffer[ i + 1 ] != 'w' && szBuffer[ i + 1 ] != 'd' && ( bSlash && szBuffer[ i + 1 ] != 'n' ) && ( bSlash && szBuffer[ i + 1 ] != 't' ) )
		// 	continue;

		if ( !( szBuffer[ i + 1 ] == 'r' || szBuffer[ i + 1 ] == 'y' || szBuffer[ i + 1 ] == 'w' || szBuffer[ i + 1 ] == 'd' || bSlash && szBuffer[ i + 1 ] == 'n' || bSlash && szBuffer[ i + 1 ] == 't' ) )
			continue;

		iCharIndex[ 0 ] = i;
		iCharIndex[ 1 ] = i + 1;

		if ( iCharIndex[ 0 ] >= 0 && iCharIndex[ 0 ] < iLen && iCharIndex[ 1 ] >= 0 && iCharIndex[ 1 ] < iLen )
		{
			if ( iCharIndex[ 0 ] > iCharIndex[ 1 ] )
			{
				iTempBuffer = iCharIndex[ 0 ];
				iCharIndex[ 0 ] = iCharIndex[ 1 ];
				iCharIndex[ 1 ] = iTempBuffer;
			}

			iTempBuffer = ( iCharIndex[ 1 ] - iCharIndex[ 0 ] + 1 );

			for ( new j = iCharIndex[ 0 ]; j < iLen - iTempBuffer; j++ ) {
				szBuffer[ j ] = szBuffer[ j + iTempBuffer ];
			}

			szBuffer[ iLen - iTempBuffer ] = '^0';
		}

		bSlash = false;
	}
}

/* -> Format number to string with a special character <- */
stock UTIL_FormatNumber( iValue, szOutput[ ], iLen, const szSpecialChar = ' ' )
{
	new szBuffer[ 16 ], iOutputPos, iNumPos, iNumLen;
	// szBuffer[ 0 ] = '^0', iOutputPos = iNumPos = iNumLen = 0;
	if ( iValue < 0 )
	{
		szOutput[ iOutputPos++ ] = '-';
		iValue = abs( iValue );
	}

	iNumLen = num_to_str( iValue, szBuffer, charsmax( szBuffer ) );
	if ( iNumLen <= 3 ) 
		iOutputPos += copy( szOutput[ iOutputPos ], iLen, szBuffer );
	else
	{
		while ( ( iNumPos < iNumLen ) && ( iOutputPos < iLen ) )
		{
			szOutput[ iOutputPos++ ] = szBuffer[ iNumPos++ ];
			if ( ( iNumLen - iNumPos ) && !( ( iNumLen - iNumPos ) % 3 ) )
				szOutput[ iOutputPos++ ] = szSpecialChar;
		}
		szOutput[ iOutputPos ] = EOS;
	}

	return iOutputPos;
}

/* -> Get Spaces Count <- */
stock UTIL_GetSpacesCount( const iCount, const szSpace[ ], szBuffer[ ], const iLen )
{
	szBuffer[ 0 ] = EOS;
	for ( new iPos; iPos < iCount; iPos++ ) { strcat( szBuffer, szSpace, iLen ); }
}

/* -> Destroy Menu <- */
stock UTIL_DestroyMenu( const pPlayer )
{
	show_menu( pPlayer, 0, "^n", 1 );
	menu_cancel( pPlayer );
}

/* -> Returns alive players <- */
stock GetAlivePlayersCount( &iAliveHumans = 0, &iAliveZombies = 0 )
{
	iAliveHumans = iAliveZombies = 0;
	rg_initialize_player_counts( iAliveZombies, iAliveHumans );
}

/* -> Give Custom Item <- */
stock bool: UTIL_GiveCustomWeapon( const pPlayer, const szWeaponReference[ ], const iWeaponUId, const iDefaultAmmo, &pItem = NULLENT )
{
	pItem = rg_give_custom_item( pPlayer, szWeaponReference, GT_DROP_AND_REPLACE, iWeaponUId );
	if ( is_nullent( pItem ) )
		return false;

	if ( iDefaultAmmo )
	{
		new iAmmoType = GetWeaponAmmoType( pItem );

		if ( GetWeaponAmmo( pPlayer, iAmmoType ) < iDefaultAmmo )
			SetWeaponAmmo( pPlayer, iDefaultAmmo, iAmmoType );
	}

	return true;
}

/* -> Destroy All Entities by ClassName <- */
stock UTIL_DestroyEntitiesByClass( const szClassName[ ] )
{
	new pEntity = MaxClients;
	while ( ( pEntity = rg_find_ent_by_class( pEntity, szClassName ) ) > 0 )
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

/* -> Velocity by Aim <- */
stock UTIL_VelocityByAim( const pPlayer, const Float: flSpeed, Vector3( vecVelocity ) )
{
	new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );
	xs_vec_mul_scalar( vecAiming, flSpeed, vecVelocity );
}

/* -> Check Distance to Floor <- */
stock Float: UTIL_DistanceToFloor( const Vector3( vecOrigin ) )
{
	new Vector3( vecEndPos ); xs_vec_copy( vecOrigin, vecEndPos );
	vecEndPos[ 2 ] = -8191.0;

	engfunc( EngFunc_TraceLine, vecOrigin, vecEndPos, IGNORE_MONSTERS, 0, 0 );
	get_tr2( 0, TR_vecEndPos, vecEndPos );

	return Float: ( vecOrigin[ 2 ] - vecEndPos[ 2 ] );
}

/* -> Vector In World <- */
stock bool: UTIL_VectorInWorld( const Vector3( vecOrigin ) )
{
	// https://github.com/s1lentq/ReGameDLL_CS/blob/96e2121c4504d26376d655f036d32e2fd967e4e5/regamedll/dlls/cbase.cpp#L858-L866
	if ( vecOrigin[ 0 ] >= 4096.0 || vecOrigin[ 1 ] >= 4096.0 || vecOrigin[ 2 ] >= 4096.0 )
		return false;

	if ( vecOrigin[ 0 ] <= -4096.0 || vecOrigin[ 1 ] <= -4096.0 || vecOrigin[ 2 ] <= -4096.0 )
		return false;

	return true;
}

/* -> BuyClose <- */
stock UTIL_BuyClose( const iDest, const pReceiver )
{
	static iMsgId_BuyClose; if ( !iMsgId_BuyClose ) iMsgId_BuyClose = get_user_msgid( "BuyClose" );

	message_begin( iDest, iMsgId_BuyClose, .player = pReceiver );
	message_end( );
}

/* -> Flashlight <- */
stock UTIL_Flashlight( const iDest, const pReceiver, const bool: bEnabled = false, const iChargePercent = 100 )
{
	static iMsgId_Flashlight; if ( !iMsgId_Flashlight ) iMsgId_Flashlight = get_user_msgid( "Flashlight" );

	message_begin( iDest, iMsgId_Flashlight, .player = pReceiver );
	write_byte( bEnabled );
	write_byte( iChargePercent );
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

/* -> TE_PLAYERATTACHMENT <- */
stock UTIL_TE_PLAYERATTACHMENT( const iDest, const pReceiver, const pEntity, const iZOffset, const iszModelIndex, const iLife )
{
	message_begin( iDest, SVC_TEMPENTITY, .player = pReceiver );
	write_byte( TE_PLAYERATTACHMENT );
	write_byte( pEntity ); // Entity Attach
	write_coord( iZOffset ); // Z axis Offset
	write_short( iszModelIndex ); // Model Index
	write_short( iLife ); // Life in 0.1
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

/* -> All default hit wall effects <- */
stock UTIL_HitWallEffects( const pEntity, const Vector3( vecOrigin ), const bool: bSparks = true, Vector3( vecDirection ) = { 0.0, 0.0, 0.0 }, const iColor = 4 )
{
	if ( pEntity && is_nullent( pEntity ) || ( get_entvar( pEntity, var_flags ) & FL_KILLME ) || !ExecuteHam( Ham_IsBSPModel, pEntity ) )
		return;

	UTIL_GunshotDecalTrace( pEntity, vecOrigin );

	if ( bSparks && engfunc( EngFunc_PointContents, vecOrigin ) != CONTENTS_WATER )
	{
		xs_vec_mul_scalar( vecDirection, random_float( 25.0, 30.0 ), vecDirection );
		UTIL_TE_STREAK_SPLASH( MSG_PAS, vecOrigin, vecDirection, iColor, random_num( 10, 20 ), 3, 64 );
	}
}

stock UTIL_ResetTimingSound( const pPlayer, const pEntity, const iChannel = CHAN_WEAPON, const szSound[ ] )
{
	rh_emit_sound2( pPlayer, 0, iChannel, szSound, .flags = SND_STOP );
	set_entvar( pEntity, var_next_sound, 0.0 );
}

stock bool: UTIL_PlayTimingSound( const pPlayer, const pEntity, const iChannel = CHAN_WEAPON, const szSound[ ], const Float: flSoundTime )
{
	new Float: flGameTime = get_gametime( );
	new Float: flNextSound; get_entvar( pEntity, var_next_sound, flNextSound );
	if ( flNextSound > flGameTime )
		return false;

	rh_emit_sound2( pPlayer, 0, iChannel, szSound );
	set_entvar( pEntity, var_next_sound, flGameTime + flSoundTime );

	return true;
}

/* -> TE_MODEL <- */
stock UTIL_TE_MODEL( const iDest, const pReceiver, const Vector3( vecOrigin ), const Vector3( vecVelocity ), const Float: flYaw, const iszModelIndex, const iSound, const iLife )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin, pReceiver );
	write_byte( TE_MODEL );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_coord_f( vecVelocity[ 0 ] );
	write_coord_f( vecVelocity[ 1 ] );
	write_coord_f( vecVelocity[ 2 ] );
	write_angle_f( flYaw ); // Yaw
	write_short( iszModelIndex ); // Model Index
	write_byte( iSound ); // Bounce sound
	write_byte( iLife ); // Life time ( n * 0.1 sec )
	message_end( );
}

/* -> TE_TELEPORT <- */
stock UTIL_TE_TELEPORT( const iDest, const pReceiver, const Vector3( vecOrigin ), const Float: flUp = 0.0 )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin, pReceiver );
	write_byte( TE_TELEPORT ); // TE id
	write_coord_f( vecOrigin[ 0 ] ); // X
	write_coord_f( vecOrigin[ 1 ] ); // Y
	write_coord_f( vecOrigin[ 2 ] + flUp ); // Z
	message_end( );
}

/* -> TE_KILLBEAM <- */
stock UTIL_TE_KILLBEAM( const iDest, const pEntity )
{
	message_begin( iDest, SVC_TEMPENTITY );
	write_byte( TE_KILLBEAM ); 
	write_short( pEntity );
	message_end( );
}

/* -> TE_USERTRACER <- */
stock UTIL_TE_USERTRACER( const iDest, const Vector3( vecOrigin ), const Vector3( vecVelocity ), const iLife, const iColor, const iWidth )
{
	message_begin_f( iDest, SVC_TEMPENTITY );
	write_byte( TE_USERTRACER );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_coord_f( vecVelocity[ 0 ] );
	write_coord_f( vecVelocity[ 1 ] );
	write_coord_f( vecVelocity[ 2 ] );
	write_byte( iLife ); // Life
	write_byte( iColor ); // Color (0..11)
	write_byte( iWidth ); // Width
	message_end( );
}

/* -> TE_BEAMTORUS <- */
stock UTIL_TE_BEAMTORUS( const iDest, const Vector3( vecOrigin ), const Vector3( vecAxis ), const iRadius, const iszModelIndex, const iStartFrame, const iFrameRate, const iLife, const iWidth, const iNoise, const iColor[ 3 ], const iBrightness, const iScrollSpeed )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_BEAMTORUS );
	write_coord_f( vecOrigin[ 0 ] ); // Origin X
	write_coord_f( vecOrigin[ 1 ] ); // Origin Y
	write_coord_f( vecOrigin[ 2 ] ); // Origin Z
	write_coord_f( vecAxis[ 0 ] ); // Axis X
	write_coord_f( vecAxis[ 1 ] ); // Axis Y
	write_coord_f( vecAxis[ 2 ] + 16.0 + float( iRadius * 2 ) ); // Axis Z
	write_short( iszModelIndex ); // Model Index
	write_byte( iStartFrame ); // Start Frame
	write_byte( iFrameRate ); // Frame Rate in 0.1's
	write_byte( iLife ); // Life in 0.1's
	write_byte( iWidth ); // Width
	write_byte( iNoise ); // Noise in 0.01's
	write_byte( iColor[ 0 ] ); // Color R
	write_byte( iColor[ 1 ] ); // Color G
	write_byte( iColor[ 2 ] ); // Color B
	write_byte( iBrightness ); // Brightness
	write_byte( iScrollSpeed ); // Scroll Speed in 0.1's
	message_end( );
}

/* -> TE_BEAMDISK <- */
stock UTIL_TE_BEAMDISK( const iDest, const Vector3( vecOrigin ), const Vector3( vecAxis ), const iRadius, const iszModelIndex, const iStartFrame, const iFrameRate, const iLife, const iWidth, const iNoise, const iColor[ 3 ], const iBrightness, const iScrollSpeed )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_BEAMDISK );
	write_coord_f( vecOrigin[ 0 ] ); // Origin X
	write_coord_f( vecOrigin[ 1 ] ); // Origin Y
	write_coord_f( vecOrigin[ 2 ] + 2.0 ); // Origin Z
	write_coord_f( vecAxis[ 0 ] ); // Axis X
	write_coord_f( vecAxis[ 1 ] ); // Axis Y
	write_coord_f( vecAxis[ 2 ] + 16.0 + float( iRadius * 2 ) ); // Axis Z
	write_short( iszModelIndex ); // Model Index
	write_byte( iStartFrame ); // Start Frame
	write_byte( iFrameRate ); // Frame Rate in 0.1's
	write_byte( iLife ); // Life in 0.1's
	write_byte( iWidth ); // Width
	write_byte( iNoise ); // Noise in 0.01's
	write_byte( iColor[ 0 ] ); // Color R
	write_byte( iColor[ 1 ] ); // Color G
	write_byte( iColor[ 2 ] ); // Color B
	write_byte( iBrightness ); // Brightness
	write_byte( iScrollSpeed ); // Scroll Speed in 0.1's
	message_end( );
}

/* -> TE_BEAMCYLINDER <- */
stock UTIL_TE_BEAMCYLINDER( const iDest, const Vector3( vecOrigin ), const Float: flRadius, const iszModelIndex, const iStartFrame, const iFrameRate, const iLife, const iWidth, const iNoise, const iColor[ 3 ], const iBrightness, const iSpeed )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_BEAMCYLINDER ); // TE id
	write_coord_f( vecOrigin[ 0 ] ); // x
	write_coord_f( vecOrigin[ 1 ] ); // y
	write_coord_f( vecOrigin[ 2 ] ); // z
	write_coord_f( vecOrigin[ 0 ] ); // x axis
	write_coord_f( vecOrigin[ 1 ] ); // y axis
	write_coord_f( vecOrigin[ 2 ] + flRadius ); // z axis
	write_short( iszModelIndex ); // sprite
	write_byte( iStartFrame ); // startframe
	write_byte( iFrameRate ); // framerate
	write_byte( iLife ); // life
	write_byte( iWidth ); // width
	write_byte( iNoise ); // noise
	write_byte( iColor[ 0 ] ); // red
	write_byte( iColor[ 1 ] ); // green
	write_byte( iColor[ 2 ] ); // blue
	write_byte( iBrightness ); // brightness
	write_byte( iSpeed ); // speed
	message_end( );
}

/* -> TE_SMOKE <- */
stock UTIL_TE_SMOKE( const iDest, const iszModelIndex, const Vector3( vecOrigin ), const Float: flUp, const iScale, const iFrameRate )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_SMOKE );
	write_coord_f( vecOrigin[ 0 ] ); // Origin X
	write_coord_f( vecOrigin[ 1 ] ); // Origin Y
	write_coord_f( vecOrigin[ 2 ] + flUp ); // Origin Z
	write_short( iszModelIndex ); // Model Index
	write_byte( iScale ); // Scale
	write_byte( iFrameRate ); // Frame Rate in 0.1's
	message_end( );
}

/* -> TE_WORLDDECAL <- */
stock UTIL_TE_WORLDDECAL( const iDest, const Vector3( vecOrigin ), const iDecalIndex )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_WORLDDECAL );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_byte( iDecalIndex ); // ModelIndex
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

/* -> TE_IMPLOSION <- */
stock UTIL_TE_IMPLOSION( const iDest, const pReceiver, const Vector3( vecOrigin ), const iRadius = 128, const iCount = 20, const iLife = 5 )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin, pReceiver );
	write_byte( TE_IMPLOSION );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_byte( iRadius ); // Radius
	write_byte( iCount ); // Count
	write_byte( iLife ); // Life time ( n * 0.1 sec )
	message_end( );
}

/* -> TE_PARTICLEBURST <- */
stock UTIL_TE_PARTICLEBURST( const iDest, const Vector3( vecOrigin ), const iRadius = 128, const iColor = 250, const iLife = 5 )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_PARTICLEBURST );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_short( iRadius ); // Radius
	write_byte( iColor ); // Color
	write_byte( iLife ); // Life time ( n * 0.1 sec )
	message_end( );
}

/* -> TE_EXPLOSION2 <- */
stock UTIL_TE_EXPLOSION2( const iDest, const Vector3( vecOrigin ), const iColor = 0, const iCount = 10 )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_EXPLOSION2 );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_byte( iColor ); // Color
	write_byte( iCount ); // Count
	message_end( );
}

/* -> The target is behind the wall <- */
stock bool: UTIL_IsWallBetweenPoints( const pPlayer, const pTarget )
{
	if ( is_nullent( pPlayer ) || is_nullent( pTarget ) )
		return false;

	new Vector3( vecStart ); get_entvar( pPlayer, var_origin, vecStart );
	new Vector3( vecEnd ); get_entvar( pTarget, var_origin, vecEnd );

	engfunc( EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, pPlayer, 0 );
	get_tr2( 0, TR_vecEndPos, vecStart );

	return xs_vec_equal( vecEnd, vecStart );
}

stock UTIL_TE_DEBUGPOINTS( const iDest, const Vector3( vecStart ), const Vector3( vecEnd ), const iLife, const iWidth = 1, const iColor[ 3 ] = { 255, 255, 255 }, const iAlpha = 255 )
{
	static _iszModelIndex_LaserBeam;
	if ( !_iszModelIndex_LaserBeam )
		_iszModelIndex_LaserBeam = engfunc( EngFunc_ModelIndex, "sprites/laserbeam.spr" );

	UTIL_TE_BEAMPOINTS( iDest, vecStart, vecEnd, _iszModelIndex_LaserBeam, 0, 0, iLife, iWidth, 0, iColor, iAlpha, 0 );
}

/* -> TE_BREAKMODEL <- */
stock UTIL_TE_BREAKMODEL( const iDest, const Vector3( vecOrigin ), const Vector3( vecSize ), const Vector3( vecVelocity ), const iRandomVelocity, const iszModelIndex, const iCount, const iLife, const bitsFlags )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_BREAKMODEL );
	write_coord_f( vecOrigin[ 0 ] ); // Origin X
	write_coord_f( vecOrigin[ 1 ] ); // Origin Y
	write_coord_f( vecOrigin[ 2 ] ); // Origin Z
	write_coord_f( vecSize[ 0 ] ); // Size X
	write_coord_f( vecSize[ 1 ] ); // Size Y
	write_coord_f( vecSize[ 2 ] ); // Size Z
	write_coord_f( vecVelocity[ 0 ] ); // Velocity X
	write_coord_f( vecVelocity[ 1 ] ); // Velocity Y
	write_coord_f( vecVelocity[ 2 ] ); // Velocity Z
	write_byte( iRandomVelocity ); // Random Velocity in 10's
	write_short( iszModelIndex ); // Model Index
	write_byte( iCount ); // Count
	write_byte( iLife ); // Life in 0.1's
	write_byte( bitsFlags ); // Flags
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

/* -> Get speed Vector to 2 points <- */
stock UTIL_GetSpeedVector( const Vector3( vecStartOrigin ), const Vector3( vecEndOrigin ), Float: flSpeed = 0.0, Float: flTime = 1.0, Vector3( vecVelocity ) )
{
	if ( flSpeed <= 0.0 )
		flSpeed = xs_vec_distance( vecStartOrigin, vecEndOrigin ) / flTime;
	else
		flSpeed /= flTime;

	xs_vec_sub( vecEndOrigin, vecStartOrigin, vecVelocity );
	xs_vec_normalize( vecVelocity, vecVelocity );
	xs_vec_mul_scalar( vecVelocity, flSpeed, vecVelocity );
}

stock Float: UTIL_AngleMod( Float: flAngle )
{
	if ( flAngle < 0.0 )
		flAngle = flAngle + 360.0 * ( ( flAngle / 360.0 ) + 1.0 );
	else if ( flAngle >= 360.0 )
		flAngle = flAngle - 360.0 * ( ( flAngle / 360.0 ) );
	
	return flAngle;
}

/* -> Player KnockBack <- */
stock UTIL_PlayerKnockBack( const pVictim, const pAttacker, const Float: flForce, const Float: flVelocityModifier = 0.0 )
{
	if ( flForce == 0.0 )
		return;

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

/* -> Get weapon Spread by Action <- */
stock Float: UTIL_GetSpreadByAction( const pPlayer, const Float: flSpreadInActions[ 4 ], const Float: flMoveSpeed = 140.0 )
{
	enum {
		Act_OnAir = 0,
		Act_OnMove,
		Act_Ducking,
		Act_None
	};

	new bitsFlags = get_entvar( pPlayer, var_flags );
	new Vector3( vecVelocity ); get_entvar( pPlayer, var_velocity, vecVelocity );

	if ( ~bitsFlags & FL_ONGROUND )
		return Float: flSpreadInActions[ Act_OnAir ];
	else if ( xs_vec_len_2d( vecVelocity ) > flMoveSpeed )
		return Float: flSpreadInActions[ Act_OnMove ];
	else if ( bitsFlags & FL_DUCKING )
		return Float: flSpreadInActions[ Act_Ducking ];
	
	return Float: flSpreadInActions[ Act_None ];
}

/* -> TE_BEAMENTS <- */
stock UTIL_TE_BEAMENTS( const iDest, const pPlayer, const pTarget, const iszModelIndex, const iStartFrame = 0, const iFrameRate = 1, const iLife = 1, const iWidth = 1, const iNoise = 0, const iColor[ 3 ] = { 255, 255, 255 }, const iBrightness = 255, const iScroll = 0 )
{
	message_begin_f( iDest, SVC_TEMPENTITY );
	write_byte( TE_BEAMENTS );
	write_short( pPlayer );
	write_short( pTarget );
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

/* -> TE_BEAMFOLLOW <- */
stock UTIL_TE_BEAMFOLLOW( const iDest, const pEntity, const iszModelIndex, const iLife, const iWidth, const iColor[ 3 ], const iBrightness )
{
	message_begin_f( iDest, SVC_TEMPENTITY );
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

/* -> TE_SPARKS <- */
stock UTIL_TE_SPARKS( const iDest, const Vector3( vecOrigin ) )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_SPARKS );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	message_end( );
}

/* -> ScoreAttrib <- */
stock UTIL_ScoreAttrib( const iDest, const pReceiver, const pPlayer, const bitsAttribute = SCORE_STATUS_NONE )
{
	static iMsgId_ScoreAttrib; if ( !iMsgId_ScoreAttrib ) iMsgId_ScoreAttrib = get_user_msgid( "ScoreAttrib" );

	message_begin( iDest, iMsgId_ScoreAttrib, .player = pReceiver );
	write_byte( pPlayer ); // Player
	write_byte( bitsAttribute ); // Attribute
	message_end( );
}

/* -> Damage <- */
stock UTIL_Damage( const iDest, const pReceiver, const iDamageSave, const iDamageTake, const bitsDamageType, const iCoords[ 3 ] = { 0, 0, 0 } )
{
	static iMsgId_Damage; if ( !iMsgId_Damage ) iMsgId_Damage = get_user_msgid( "Damage" );

	message_begin( iDest, iMsgId_Damage, .player = pReceiver );
	write_byte( iDamageSave ); // DamageSave
	write_byte( iDamageTake ); // DamageTake
	write_long( bitsDamageType ); // DamageType
	write_coord( iCoords[ 0 ] ); // Coord X
	write_coord( iCoords[ 1 ] ); // Coord Y
	write_coord( iCoords[ 2 ] ); // Coord Z
	message_end( );
}

/* -> DeathMsg <- */
stock UTIL_DeathMsg( const iDest, const pReceiver, const pAttacker, const pVictim, const iHeadshot, const szIcon[ ] )
{
	static iMsgId_DeathMsg; if ( !iMsgId_DeathMsg ) iMsgId_DeathMsg = get_user_msgid( "DeathMsg" );
	
	message_begin( iDest, iMsgId_DeathMsg, .player = pReceiver );
	write_byte( pAttacker ); // Attacker
	write_byte( pVictim ); // Victim
	write_byte( iHeadshot ); // Headshot?
	write_string( szIcon ); // Icon in killfeed ( hud.txt d_* )
	message_end( );
}

/* -> AmmoX <- */
stock UTIL_AmmoX( const iDest, const pReceiver, const iAmmoType, const iValue )
{
	static iMsgId_AmmoX; if ( !iMsgId_AmmoX ) iMsgId_AmmoX = get_user_msgid( "AmmoX" );

	message_begin( iDest, iMsgId_AmmoX, .player = pReceiver );
	write_byte( iAmmoType );
	write_byte( iValue );
	message_end( );
}

/* -> AmmoPickup <- */
stock UTIL_AmmoPickup( const iDest, const pReceiver, const iAmmoType, const iAmount )
{
	static iMsgId_AmmoPickup; if ( !iMsgId_AmmoPickup ) iMsgId_AmmoPickup = get_user_msgid( "AmmoPickup" );

	message_begin( iDest, iMsgId_AmmoPickup, .player = pReceiver );
	write_byte( iAmmoType );
	write_byte( clamp( iAmount, 1, 255 ) );
	message_end( );
}

/* -> WeapPickup <- */
stock UTIL_WeapPickup( const iDest, const pReceiver, const iWeaponId )
{
	static iMsgId_WeapPickup; if ( !iMsgId_WeapPickup ) iMsgId_WeapPickup = get_user_msgid( "WeapPickup" );

	message_begin( iDest, iMsgId_WeapPickup, .player = pReceiver );
	write_byte( iWeaponId );
	message_end( );
}

stock UTIL_DrawCustomAmmoPickup( const pReceiver, szHudPath[ MAX_NAME_LENGTH ] = "", const iValue )
{
	new iDest;
	if ( pReceiver <= 0 )
		iDest = MSG_ALL;
	else if ( is_user_connected( pReceiver ) )
		iDest = MSG_ONE;
	else
	{
		log_amx( "[ZP] Invalid Player (%i)", pReceiver );
		return false;
	}

	UTIL_WeaponList( iDest, pReceiver, NULLENT, szHudPath, AMMO_ExpBonus, -1, -1, -1, 0, 20, _: WEAPON_NONE, 0 );
	UTIL_AmmoPickup( iDest, pReceiver, AMMO_ExpBonus, iValue );

	return true;
}

/* -> Set Entity Rendering <- */
stock UTIL_SetEntityRendering( const pEntity, const iRenderFx = kRenderFxNone, const Float: flRenderColor[ 3 ] = { 255.0, 255.0, 255.0 }, const iRenderMode = kRenderNormal, const Float: flRenderAmount = 16.0 )
{
	set_entvar( pEntity, var_renderfx, iRenderFx );
	set_entvar( pEntity, var_rendercolor, flRenderColor );
	set_entvar( pEntity, var_rendermode, iRenderMode );
	set_entvar( pEntity, var_renderamt, flRenderAmount );
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
	new Float: flGameTime = get_gametime( );
	new Float: flFrame = Float: get_entvar( pEntity, var_frame );
	flFrame += ( Float: get_entvar( pEntity, var_framerate ) * ( flGameTime - Float: get_entvar( pEntity, var_last_time ) ) );
	if ( flFrame > get_entvar( pEntity, var_max_frame ) )
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

/* -> Player Animation <- */
stock UTIL_PlayerAnimation( const pPlayer, const szAnim[ ], const Float: flFrame = 0.0, const Activity: iActivity = ACT_RANGE_ATTACK1 ) 
{
	new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
	if ( ( iAnimDesired = lookup_sequence( pPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed ) ) == -1 ) 
		iAnimDesired = 0;

	new Float: flGameTime = get_gametime( );

	UTIL_SetEntityAnim( pPlayer, iAnimDesired, flFrame );

	set_member( pPlayer, m_fSequenceLoops, bLoops );
	set_member( pPlayer, m_fSequenceFinished, 0 );
	set_member( pPlayer, m_flFrameRate, flFrameRate );
	set_member( pPlayer, m_flGroundSpeed, flGroundSpeed );
	set_member( pPlayer, m_flLastEventCheck, flGameTime );
	set_member( pPlayer, m_Activity, iActivity );
	set_member( pPlayer, m_IdealActivity, iActivity );
	set_member( pPlayer, m_flLastFired, flGameTime );
}

/* -> Weapon Animation <- */
/*stock UTIL_SendWeaponAnim( const iDest, const pReceiver, const pItem, const iAnim ) 
{
#if defined WeaponAnim_Dummy
	static iBody; iBody = get_entvar( pItem, var_body );
#else
	#pragma unused pItem

	#define iBody 0
#endif

	set_entvar( pReceiver, var_weaponanim, iAnim );

	message_begin( iDest, SVC_WEAPONANIM, .player = pReceiver );
	write_byte( iAnim );
	write_byte( iBody );
	message_end( );

#if defined WeaponAnim_Dummy
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
#endif
}*/

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

/* -> Set weapon time offsets <- */
stock UTIL_WeaponSetTiming( const pItem, const Float: flIdleTime, Float: flNextAttack = 0.0 )
{
	flNextAttack = ( !flNextAttack ? flIdleTime : flNextAttack ) + 0.01;

	set_member( pItem, m_Weapon_flTimeWeaponIdle, flIdleTime );
	set_member( pItem, m_Weapon_flNextPrimaryAttack, flNextAttack );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, flNextAttack );
}

/* -> Get player end eye position of aiming (w/o Trace) <- */
stock UTIL_GetEyePointAiming( const pPlayer, const Float: flDistance, Vector3( vecEndPos ), const iIgnoreId = 0/*DONT_IGNORE_MONSTERS*/ )
{
	new Vector3( vecStart ); UTIL_GetEyePosition( pPlayer, vecStart );
	new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );
	new Vector3( vecEnd ); xs_vec_add_scaled( vecStart, vecAiming, flDistance, vecEnd );

	engfunc( EngFunc_TraceLine, vecStart, vecEnd, iIgnoreId, pPlayer, 0 );
	get_tr2( 0, TR_vecEndPos, vecEndPos );

	return get_tr2( 0, TR_pHit );
}

/* -> Get player end eye position of aiming (Trace) <- */
stock UTIL_GetTraceEyePointAiming( const pPlayer, const Float: flDistance, Vector3( vecEndPos ), const iIgnoreId = 0/*DONT_IGNORE_MONSTERS*/ )
{
	new Vector3( vecStart ); UTIL_GetEyePosition( pPlayer, vecStart );
	new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );
	new Vector3( vecEnd ); xs_vec_add_scaled( vecStart, vecAiming, flDistance, vecEnd );

	new pTrace = create_tr2( );

	engfunc( EngFunc_TraceLine, vecStart, vecEnd, iIgnoreId, pPlayer, pTrace );
	get_tr2( pTrace, TR_vecEndPos, vecEndPos );

	return pTrace;
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

/* -> Get Distance on 2 entities <- */
stock Float: UTIL_GetEntitiesDistance( const pEntity, const pTarget )
{
	new Vector3( vecOrigin ); get_entvar( pEntity, var_origin, vecOrigin );
	new Vector3( vecTargetOrigin ); get_entvar( pTarget, var_origin, vecTargetOrigin );

	return xs_vec_distance_2d( vecOrigin, vecTargetOrigin );
}

/* -> Get Weapon Position <- */
stock UTIL_GetWeaponPosition( const pPlayer, const Float: flForward, const Float: flRight, const Float: flUp, Vector3( vecStart ) ) 
{
	new Vector3( vecOrigin ); UTIL_GetEyePosition( pPlayer, vecOrigin );
	new Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	new Vector3( vecForward ), Vector3( vecRight ), Vector3( vecUp );
	engfunc( EngFunc_AngleVectors, vecViewAngle, vecForward, vecRight, vecUp );

	xs_vec_add_scaled( vecOrigin, vecForward, flForward, vecOrigin );
	xs_vec_add_scaled( vecOrigin, vecRight, flRight, vecOrigin );
	xs_vec_add_scaled( vecOrigin, vecUp, flUp, vecOrigin );
	xs_vec_copy( vecOrigin, vecStart );
}

/* -> Custom Eject Brass <- */
stock UTIL_EjectBrass( const pPlayer, const iszModelShellIndex, const Float: flRightDirection, const Float: flUpScale = -9.0, const Float: flForwardScale = 16.0, const Float: flRightScale = 0.0, const bool: bShotgunSound = false )
{
	new Vector3( vecOrigin ); UTIL_GetEyePosition( pPlayer, vecOrigin );
	new Vector3( vecVelocity ); get_entvar( pPlayer, var_velocity, vecVelocity );
	new Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	new Vector3( vecPunchAngle ); get_entvar( pPlayer, var_punchangle, vecPunchAngle );

	xs_vec_add( vecViewAngle, vecPunchAngle, vecViewAngle );

	new Vector3( vecForward ), Vector3( vecRight ), Vector3( vecUp );
	engfunc( EngFunc_AngleVectors, vecViewAngle, vecForward, vecRight, vecUp );
	
	new i;
	for ( i = 0; i < 3; i++ )
	{
		vecOrigin[ i ] = vecOrigin[ i ] + vecForward[ i ] * flForwardScale + vecUp[ i ] * flUpScale + vecRight[ i ] * flRightScale;
		vecVelocity[ i ] = vecVelocity[ i ] + vecForward[ i ] * 25.0 + vecUp[ i ] * random_float( 100.0, 150.0 ) + vecRight[ i ] * flRightDirection;
	}
	
	UTIL_TE_MODEL( MSG_ONE, pPlayer, vecOrigin, vecVelocity, vecViewAngle[ 1 ], iszModelShellIndex, bShotgunSound ? 2 : 1, 15 );
}

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
				format( szSoundPath, charsmax( szSoundPath ), "sound/%s", szSoundPath );
				engfunc( EngFunc_PrecacheGeneric, szSoundPath );
			}
		}
	}
	
	fclose( pFile );
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

/* -> StatusIcon <- */
enum {
	STATUS_HIDE,
	STATUS_SHOW,
	STATUS_FLASH
};

stock UTIL_StatusIcon( const iDest, const pReceiver, iStatus, const szSprite[ ], const iColor[ 3 ] = { 255, 255, 255 } )
{
	static iMsgId_StatusIcon; if ( !iMsgId_StatusIcon ) iMsgId_StatusIcon = get_user_msgid( "StatusIcon" );

	message_begin( iDest, iMsgId_StatusIcon, .player = pReceiver );
	write_byte( iStatus = clamp( iStatus, STATUS_HIDE, STATUS_FLASH ) );
	write_string( szSprite );
	if ( iStatus != STATUS_HIDE )
	{
		write_byte( iColor[ 0 ] );
		write_byte( iColor[ 1 ] );
		write_byte( iColor[ 2 ] );
	}
	message_end( );
}

/* -> Scenario <- */
stock UTIL_Scenario( const iDest, const pReceiver, const bool: bActive = false, const szSprite[ ] = "", const iAlpha = 255, const iFlashRate = 0, const iFlashDelay = 0 )
{
	static iMsgId_Scenario; if ( !iMsgId_Scenario ) iMsgId_Scenario = get_user_msgid( "Scenario" );

	message_begin( iDest, iMsgId_Scenario, .player = pReceiver );
	write_byte( bActive );
	write_string( szSprite );
	write_byte( iAlpha );
	write_short( iFlashRate );
	write_short( iFlashDelay );
	message_end( );
}

/* -> BarTime <- */
stock UTIL_BarTime( const iDest, const pReceiver, const iTime )
{
	static iMsgId_BarTime; if ( !iMsgId_BarTime ) iMsgId_BarTime = get_user_msgid( "BarTime" );

	message_begin( iDest, iMsgId_BarTime, .player = pReceiver );
	write_short( iTime );
	message_end( );
}

/* -> ScreenFade <- */
stock UTIL_ScreenFade( const iDest, const pReceiver, Float: flDuration = 0.0, Float: flHoldTime = 0.0, const bitsFlags = FFADE_IN, const iColor[ 3 ] = { 0, 0, 0 }, const iAlpha = 255 )
{
	static iMsgId_ScreenFade; if ( !iMsgId_ScreenFade ) iMsgId_ScreenFade = get_user_msgid( "ScreenFade" );

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

/* -> TE_LAVASPLASH <- */
stock UTIL_TE_LAVASPLASH( const iDest, const Vector3( vecOrigin ) )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_LAVASPLASH );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	message_end( );
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

/* -> CurWeapon <- */
stock UTIL_CurWeapon( const iDest, const pReceiver, const bool: bIsActive, const iWeaponId, const iClipAmmo )
{
	static iMsgId_CurWeapon; if ( !iMsgId_CurWeapon ) iMsgId_CurWeapon = get_user_msgid( "CurWeapon" );

	message_begin( iDest, iMsgId_CurWeapon, .player = pReceiver );
	write_byte( bIsActive );
	write_byte( iWeaponId );
	write_byte( iClipAmmo );
	message_end( );
}

/* -> HostagePos <- */
stock UTIL_HostagePos( const iDest, const pReceiver, const iFlag, const iHostageIndex, const Vector3( vecOrigin ) )
{
	static iMsgId_HostagePos; if ( !iMsgId_HostagePos ) iMsgId_HostagePos = get_user_msgid( "HostagePos" );

	message_begin( iDest, iMsgId_HostagePos, .player = pReceiver );
	write_byte( iFlag );
	write_byte( iHostageIndex );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	message_end( );
}

/* -> HostageK <- */
stock UTIL_HostageK( const iDest, const pReceiver, const iHostageIndex )
{
	static iMsgId_HostageK; if ( !iMsgId_HostageK ) iMsgId_HostageK = get_user_msgid( "HostageK" );

	message_begin( iDest, iMsgId_HostageK, .player = pReceiver );
	write_byte( iHostageIndex );
	message_end( );
}

/* -> BombDrop <- */
stock UTIL_BombDrop( const iDest, const pReceiver, const Vector3( vecOrigin ), const iFlag )
{
	static iMsgId_BombDrop; if ( !iMsgId_BombDrop ) iMsgId_BombDrop = get_user_msgid( "BombDrop" );

	message_begin( iDest, iMsgId_BombDrop, .player = pReceiver );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_byte( iFlag );
	message_end( );
}

/* -> BombPickup <- */
stock UTIL_BombPickup( const iDest, const pReceiver )
{
	static iMsgId_BombPickup; if ( !iMsgId_BombPickup ) iMsgId_BombPickup = get_user_msgid( "BombPickup" );

	message_begin( iDest, iMsgId_BombPickup, .player = pReceiver );
	message_end( );
}

/* -> Radar <- */
stock UTIL_Radar( const iDest, const pReceiver, const iTeammateIndex, const Vector3( vecOrigin ) )
{
	static iMsgId_Radar; if ( !iMsgId_Radar ) iMsgId_Radar = get_user_msgid( "Radar" );

	message_begin( iDest, iMsgId_Radar, .player = pReceiver );
	write_byte( iTeammateIndex );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
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

/* -> Set user FOV <- */
stock UTIL_SetUserFOV( const iDest, const pReceiver, const iFOV = DEFAULT_NO_ZOOM )
{
	static iMsgId_SetFOV; if( !iMsgId_SetFOV ) iMsgId_SetFOV = get_user_msgid( "SetFOV" );

	message_begin( iDest, iMsgId_SetFOV, .player = pReceiver );
	write_byte( iFOV );
	message_end( );

	set_entvar( pReceiver, var_fov, float( iFOV ) );
	// set_member( pReceiver, m_iFOV, iFOV );
}

/* -> Update HideWeapon <- */
stock UTIL_UpdateHideWeapon( const iDest, const pReceiver, const bitsFlags )
{
	static iMsgId_HideWeapon; if( !iMsgId_HideWeapon ) iMsgId_HideWeapon = get_user_msgid( "HideWeapon" );

	message_begin( iDest, iMsgId_HideWeapon, .player = pReceiver );
	write_byte( bitsFlags );
	message_end( );

	set_member( pReceiver, m_iHideHUD, bitsFlags );
	set_member( pReceiver, m_iClientHideHUD, bitsFlags );
}

/* -> Weapon Kick Back <- */
stock UTIL_WeaponKickBack( const pItem, const pPlayer, Float: flUpBase, Float: flLateralBase, Float: flUpModifier, Float: flLateralModifier, Float: flUpMax, Float: flLateralMax, iDirectionChange ) 
{
	new Float: flKickUp, Float: flKickLateral;
	new iShotsFired = get_member( pItem, m_Weapon_iShotsFired );
	new iDirection = get_member( pItem, m_Weapon_iDirection );
	new Vector3( vecPunchAngle ); get_entvar( pPlayer, var_punchangle, vecPunchAngle );

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

	vecPunchAngle[ 0 ] -= flKickUp;

	if ( vecPunchAngle[ 0 ] < -flUpMax ) 
		vecPunchAngle[ 0 ] = -flUpMax;

	if ( iDirection ) 
	{
		vecPunchAngle[ 1 ] += flKickLateral;
		if ( vecPunchAngle[ 1 ] > flLateralMax ) 
			vecPunchAngle[ 1 ] = flLateralMax;
	}
	else
	{
		vecPunchAngle[ 1 ] -= flKickLateral;
		if ( vecPunchAngle[ 1 ] < -flLateralMax ) 
			vecPunchAngle[ 1 ] = -flLateralMax;
	}

	if ( iDirectionChange != 0 && !random_num( 0, iDirectionChange ) ) 
		set_member( pItem, m_Weapon_iDirection, !iDirection );

	set_entvar( pPlayer, var_punchangle, vecPunchAngle );
}

stock UTIL_PlaySound( const pPlayer, const szSoundPath[ ] )
{
	if ( szSoundPath[ strlen( szSoundPath ) - 1 ] == '3' )
		client_cmd( pPlayer, "mp3 play ^"sound/%s^"", szSoundPath );
	else client_cmd( pPlayer, "spk ^"%s^"", szSoundPath );
}

/* -> Work with UNIX time (by ТОЛИК) <- */
enum {
	ULD_Second = (1<<0),
	ULD_Minute = (1<<1),
	ULD_Hour = (1<<2),
	ULD_Day = (1<<3),
	ULD_Year = (1<<4),
	
	ULD_Timer = ( ULD_Minute|ULD_Second ),
	ULD_PlayTime = ( ULD_Hour|ULD_Minute|ULD_Second ),
	ULD_AllOnly = ( ULD_Day|ULD_Hour|ULD_Minute|ULD_Second ),
	ULD_All = ( ULD_Year|ULD_Day|ULD_Hour|ULD_Minute|ULD_Second )
};

stock UTIL_UNIXToLastData( const bitsType, const iUNIXTime )
{
	new szBuffer[ 128 ], iLen;
	if ( bitsType & ULD_Year )
		AddFormatex( szBuffer, iLen, "%d %l, ", ( iUNIXTime / 31536000 ), "ML_Other_Year" );

	if ( bitsType & ULD_Day )
		AddFormatex( szBuffer, iLen, "%d %l, ", ( iUNIXTime / UNIX_Seconds_On_Day ) % 29, "ML_Other_Days" );

	if ( bitsType & ULD_Hour )
		AddFormatex( szBuffer, iLen, "%d %l, ", ( iUNIXTime / UNIX_Seconds_On_Hour ) % 24, "ML_Other_Hours" );

	if ( bitsType & ULD_Minute )
		AddFormatex( szBuffer, iLen, "%d %l, ", ( iUNIXTime / UNIX_Seconds_On_Minute ) % UNIX_Seconds_On_Minute, "ML_Other_Minutes" );

	if ( bitsType & ULD_Second )
		AddFormatex( szBuffer, iLen, "%02d %l, ", ( iUNIXTime % UNIX_Seconds_On_Minute ), "ML_Other_Seconds" );

	szBuffer[ iLen - 2 ] = '^0';
	return szBuffer;
}

stock bool: UTIL_StripWeaponByIndex( const pPlayer, const pItem )
{
	if ( is_nullent( pItem ) )
		return false;

	if ( get_member( pPlayer, m_pActiveItem ) == pItem )
		ExecuteHamB( Ham_Weapon_RetireWeapon, pItem );

	if ( !ExecuteHamB( Ham_RemovePlayerItem, pPlayer, pItem ) )
		return false;

	ExecuteHamB( Ham_Item_Kill, pItem );
	set_entvar( pPlayer, var_weapons, get_entvar( pPlayer, var_weapons ) & ~( 1<<( get_member( pItem, m_iId ) ) ) );

	return true;
}

stock bool: CBasePlayer_RemovePlayerItemEx( const pPlayer, const szItemName[ ] )
{
	if ( !is_user_alive( pPlayer ) )
		return false;

	if ( IsNullString( szItemName ) )
		return false;

	new pItem = UTIL_GetItemByName( pPlayer, szItemName );
	if ( is_nullent( pItem ) )
		return false;

	if ( pItem == get_member( pPlayer, m_pActiveItem ) )
		ExecuteHamB( Ham_Weapon_RetireWeapon, pItem );

	if ( !ExecuteHamB( Ham_RemovePlayerItem, pPlayer, pItem ) )
		return false;

	ExecuteHamB( Ham_Item_Kill, pItem );
	set_member( pPlayer, m_rgAmmo, 0, get_member( pItem, m_Weapon_iPrimaryAmmoType ) );
	set_entvar( pPlayer, var_weapons, get_entvar( pPlayer, var_weapons ) & ~( 1<<( get_member( pItem, m_iId ) ) ) );

	return true;
}

stock UTIL_GetItemByName( const pPlayer, const szItemName[ ] )
{
	for ( new i, pItem = NULLENT; i < MAX_ITEM_TYPES; i++ )
	{
		pItem = get_member( pPlayer, m_rgpPlayerItems, i );
		while ( !is_nullent( pItem ) )
		{
			if ( FClassnameIs( pItem, szItemName ) )
				return pItem;

			pItem = get_member( pItem, m_pNext );
		}
	}
	return NULLENT;
}

/* -> Shotgun Idle <- */
stock bool: UTIL_ShotgunIdle( const pItem, const iAnimIdle, const Float: flAnimIdleTime, const iAnimReloadEnd, const Float: flAnimReloadEndTime, const szSoundReloadEnd[ ] = "" )
{
	new pPlayer = get_member( pItem, m_pPlayer );
	new iClip = GetWeaponClip( pItem );
	new iAmmoType = GetWeaponAmmoType( pItem );
	new iAmmo = GetWeaponAmmo( pPlayer, iAmmoType );
	new iSpecialReload = get_member( pItem, m_Weapon_fInSpecialReload );

	if ( iClip == 0 && iSpecialReload == 0 && iAmmo ) ExecuteHamB( Ham_Weapon_Reload, pItem );
	else if ( iSpecialReload )
	{
		if ( iClip != rg_get_iteminfo( pItem, ItemInfo_iMaxClip ) && iAmmo ) ExecuteHamB( Ham_Weapon_Reload, pItem );
		else
		{
			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iAnimReloadEnd );

			if ( !IsNullString( szSoundReloadEnd ) )
				rh_emit_sound2( pPlayer, 0, CHAN_ITEM, szSoundReloadEnd, .pitch = 85 + random_num( 0, 31 ) );

			set_member( pItem, m_Weapon_fInSpecialReload, 0 );
			set_member( pItem, m_Weapon_flTimeWeaponIdle, flAnimReloadEndTime );
		}
	}
	else
	{
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iAnimIdle );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, flAnimIdleTime );
	}
}

/* -> Shotgun Reload <- */
stock bool: UTIL_ShotgunReload( const pItem, const iAnimReloadStart, const Float: flReloadStartDelay, const szSoundReloadStart[ ] = "", const iAnimReload, const Float: flReloadDelay, const szSoundReload[ ] = "" )
{
	new pPlayer = get_member( pItem, m_pPlayer );
	new iClip = GetWeaponClip( pItem );
	new iAmmoType = GetWeaponAmmoType( pItem );
	new iAmmo = GetWeaponAmmo( pPlayer, iAmmoType );
	new iSpecialReload = get_member( pItem, m_Weapon_fInSpecialReload );

	if ( iAmmo <= 0 || iClip == rg_get_iteminfo( pItem, ItemInfo_iMaxClip ) || get_member( pItem, m_Weapon_flNextPrimaryAttack ) > 0.0 )
		return false;

	switch ( iSpecialReload )
	{
		case 0:
		{
			rg_set_animation( pPlayer, PLAYER_RELOAD );
			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iAnimReloadStart );

			if ( !IsNullString( szSoundReloadStart ) )
				rh_emit_sound2( pPlayer, 0, CHAN_ITEM, szSoundReloadStart, .pitch = 85 + random_num( 0, 31 ) );

			iSpecialReload = 1;
			set_member( pPlayer, m_flNextAttack, flReloadStartDelay );
			set_member( pItem, m_Weapon_flNextPrimaryAttack, flReloadStartDelay );
			set_member( pItem, m_Weapon_flNextSecondaryAttack, flReloadStartDelay );
			set_member( pItem, m_Weapon_flTimeWeaponIdle, flReloadStartDelay );
		}
		case 1:
		{
			if ( get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
				return false;

			UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, iAnimReload );

			if ( !IsNullString( szSoundReload ) )
				rh_emit_sound2( pPlayer, 0, CHAN_ITEM, szSoundReload, .pitch = 85 + random_num( 0, 31 ) );

			iSpecialReload = 2;
			set_member( pItem, m_Weapon_flTimeWeaponIdle, flReloadDelay );
		}
		case 2:
		{
			if ( get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
				return false;

			iSpecialReload = 1;
			SetWeaponClip( pItem, ++iClip );
			SetWeaponAmmo( pPlayer, --iAmmo, iAmmoType );
		}
	}

	set_member( pItem, m_Weapon_fInSpecialReload, iSpecialReload );
	return true;
}

/* -> Check entity is stuck <- */
stock bool: UTIL_IsHullVacant( const pPlayer, const Vector3( vecOrigin ), const pHull )
{
	engfunc( EngFunc_TraceHull, vecOrigin, vecOrigin, 0, pHull, pPlayer, 0 );
	if ( get_tr2( 0, TR_StartSolid ) || get_tr2( 0, TR_AllSolid ) || !get_tr2( 0, TR_InOpen ) )
		return false;

	return true;
}

/* -> Find Best Point (by FosterZ) <- */
stock bool: UTIL_FindBestPoint( const pPlayer, const Float: flMaxRadius, Vector3( vecOrigin ) )
{
	if ( !is_user_alive( pPlayer ) )
		return false;

	new pHull = ( get_entvar( pPlayer, var_flags ) & FL_DUCKING ) ? HULL_HEAD : HULL_HUMAN;
	if ( UTIL_IsHullVacant( pPlayer, vecOrigin, pHull ) )
		return true;

	new Float: flRadius, Float: flRadiusIncrease;
	flRadius = flRadiusIncrease = 17.0;

	new Float: vec2DStartCheck[ 2 ];
	vec2DStartCheck[ 0 ] = vec2DStartCheck[ 1 ] = flRadius;

	new Vector3( vecTemp ); get_entvar( pPlayer, var_angles, vecTemp );
	new Float: flLastAngleCheck = Float: ( ( -1.0 * vecTemp[ 1 ] ) / 180 * M_PI ); // Convert to Radian

	new Float: flAngleCos, Float: flAngleSin, Float: vec2DNewCheck[ 2 ];
	new i, bool: bPlayerIsStuck = true;
	vecTemp[ 2 ] = vecOrigin[ 2 ];

	while ( bPlayerIsStuck )
	{
		if ( flRadius >= flMaxRadius )
			break;

		for ( i = 0; i < 10; i++ )
		{
			flLastAngleCheck += 0.1;
			if ( flLastAngleCheck >= M_PI ) flLastAngleCheck = -M_PI;

			flAngleCos = floatcos( flLastAngleCheck );
			flAngleSin = floatsin( flLastAngleCheck );

			vec2DNewCheck[ 0 ] = flAngleCos * vec2DStartCheck[ 0 ] - flAngleSin * vec2DStartCheck[ 1 ];
			vec2DNewCheck[ 1 ] = flAngleSin * vec2DStartCheck[ 0 ] + flAngleCos * vec2DStartCheck[ 1 ];

			vec2DStartCheck[ 0 ] = vec2DNewCheck[ 0 ];
			vec2DStartCheck[ 1 ] = vec2DNewCheck[ 1 ];

			vecTemp[ 0 ] = vecOrigin[ 0 ] + vec2DStartCheck[ 0 ];
			vecTemp[ 1 ] = vecOrigin[ 1 ] + vec2DStartCheck[ 1 ];

			if ( UTIL_IsHullVacant( pPlayer, vecTemp, pHull ) )
			{
				bPlayerIsStuck = false;
				break;
			}
		}

		flRadius += flRadiusIncrease;
	}

	xs_vec_copy( vecTemp, vecOrigin );
	return !bPlayerIsStuck;
}

#define Matrix3x4(%0)	Float: %0[ 3 ][ 4 ]

/* -> Angle to Matrix <- */
stock UTIL_AngleMatrix(const Vector3( angles ), Matrix3x4( matrix ) )
{
	new Float: angle;
	new Float: sr, Float: sp, Float: sy, Float: cr, Float: cp, Float: cy;

	angle = angles[XS_YAW] * (M_PI * 2.0 / 360.0);
	sy = floatsin(angle);
	cy = floatcos(angle);
	angle = angles[XS_PITCH] * (M_PI * 2.0 / 360.0);
	sp = floatsin(angle);
	cp = floatcos(angle);
	angle = angles[XS_ROLL] * (M_PI * 2.0 / 360.0);
	sr = floatsin(angle);
	cr = floatcos(angle);

	// matrix = (YAW * PITCH) * ROLL
	matrix[0][0] = cp * cy;
	matrix[1][0] = cp * sy;
	matrix[2][0] = -sp;
	matrix[0][1] = sr * sp * cy + cr * -sy;
	matrix[1][1] = sr * sp * sy + cr * cy;
	matrix[2][1] = sr * cp;
	matrix[0][2] = (cr * sp * cy + -sr * -sy);
	matrix[1][2] = (cr * sp * sy + -sr * cy);
	matrix[2][2] = cr * cp;
	matrix[0][3] = 0.0;
	matrix[1][3] = 0.0;
	matrix[2][3] = 0.0;
}

/* -> Rotate Vector by Angle <- */
stock UTIL_VectorRotate(const Vector3( in1 ), const Matrix3x4( in2 ), Vector3( out ) )
{
	out[0] = xs_vec_dot(in1, in2[0]);
	out[1] = xs_vec_dot(in1, in2[1]);
	out[2] = xs_vec_dot(in1, in2[2]);
}

// https://github.com/thomaseichhorn/cs16-client/blob/d09d4ace1e3978b6fce244e463d69c935f813d05/cl_dll/hud/message.cpp#L465
stock UTIL_FakeHintMessageEx( const pReceiver, const iColor[ 3 ], const szMessage[ ], any:... )
{
	new szBuffer[ 191 ];
	vformat( szBuffer, charsmax( szBuffer ), szMessage, 4 );

	set_dhudmessage( 
		iColor[ 0 ], iColor[ 1 ], iColor[ 2 ],
		-1.0, 0.7, 2, 0.25, 5.0, 0.01, 1.5
	);
	show_dhudmessage( pReceiver, szBuffer );
}

/* -> Move controller by values from model <- */
stock bool: UTIL_MoveController( const pEntity, const iController, Float: flValue = 0.0, const Float: flMinMaxValue[ 2 ] = { 0.0, 255.0 } )
{
	if ( is_nullent( pEntity ) )
		return false;

	flValue = floatclamp( flValue, flMinMaxValue[ 0 ], flMinMaxValue[ 1 ] );

	new Float: flLength = floatabs( flMinMaxValue[ 0 ] ) + flMinMaxValue[ 1 ];
	flValue = ( ( flLength / 2.0 + flValue ) / flLength ) * 255.0;

	set_entvar( pEntity, var_controller, floatround( flValue ), iController );
	return true;
}

// https://dev-cs.ru/threads/222/page-10#post-85087
stock UTIL_HUEtoRGB( const Float: flHUE, Float: flColor[ 3 ] )
{
	flColor[ 0 ] = ( flHUE / 360.0 ) + 1.0 / 3.0;
	flColor[ 1 ] = ( flHUE / 360.0 );
	flColor[ 2 ] = ( flHUE / 360.0 ) - 1.0 / 3.0;

	for ( new i = 0; i < 3; i++ )
	{
		if ( flColor[ i ] < 0.0 )
			flColor[ i ] += 1.0;

		if ( flColor[ i ] > 1.0 )
			flColor[ i ] -= 1.0;

		if ( 6.0 * flColor[ i ] < 1.0 )
		{
			flColor[ i ] = flColor[ i ] * 6.0;
			continue;
		}

		if ( 2.0 * flColor[ i ] < 1.0 )
		{
			flColor[ i ] = 1.0;
			continue;
		}

		if ( 3.0 * flColor[ i ] < 2.0 )
		{
			flColor[ i ] = ( ( 2.0 / 3.0 ) - flColor[ i ] ) * 6.0;
			continue;
		}

		flColor[ i ] = 0.0;
	}

	flColor[ 0 ] *= 255.0;
	flColor[ 1 ] *= 255.0;
	flColor[ 2 ] *= 255.0;
}

stock Float: UTIL_RGBtoHUE( const Float: flColor[ 3 ] )
{
	new Float: flCachedColor[ 3 ];
	flCachedColor[ 0 ] = flColor[ 0 ] / 255.0;
	flCachedColor[ 1 ] = flColor[ 1 ] / 255.0;
	flCachedColor[ 2 ] = flColor[ 2 ] / 255.0;

	new Float: flColorMin = floatmin( flCachedColor[ 0 ], floatmin( flCachedColor[ 1 ], flCachedColor[ 2 ] ) );
	new Float: flColorMax = floatmax( flCachedColor[ 0 ], floatmax( flCachedColor[ 1 ], flCachedColor[ 2 ] ) );
	new Float: flDelta = flColorMax - flColorMin;

	if ( !flDelta )
		return 0.0;

	new Float: flHUE = 1.0;
	if ( flCachedColor[ 0 ] == flColorMax )
		flHUE = ( flCachedColor[ 1 ] - flCachedColor[ 2 ] ) / flDelta;
	else if ( flCachedColor[ 1 ] == flColorMax )
		flHUE = 2.0 + ( flCachedColor[ 2 ] - flCachedColor[ 0 ]) / flDelta;
	else
		flHUE = 4.0 + ( flCachedColor[ 0 ] - flCachedColor[ 1 ] ) / flDelta;

	flHUE /= 6.0;

	if ( flHUE < 0.0 )
		flHUE += 1.0;

	return Float: ( flHUE * 360.0 );
}

stock Float: fmod( Float: flNumerator, Float: flDenominator )
{
	if ( flDenominator == 0.0 )
		log_amx( "Trying to divide by 0" );

	return flNumerator - ( floatround( flNumerator / flDenominator, floatround_tozero ) * flDenominator );
}

stock Float: UTIL_Lerp( Float: flA, Float: flB, const Float: flT )
	return ( flA + ( flB - flA ) * floatclamp( flT, 0.0, 1.0 ) );

stock UTIL_VectorLerp( const Vector3( vecStart ), const Vector3( vecEnd ), Float: flT, Vector3( vecOut ) )
{
	flT = floatclamp( flT, 0.0, 1.0 );

	vecOut[ 0 ] = vecStart[ 0 ] + ( vecEnd[ 0 ] - vecStart[ 0 ] ) * flT;
	vecOut[ 1 ] = vecStart[ 1 ] + ( vecEnd[ 1 ] - vecStart[ 1 ] ) * flT;
	vecOut[ 2 ] = vecStart[ 2 ] + ( vecEnd[ 2 ] - vecStart[ 2 ] ) * flT;
}

stock _random( const iMax )
{
	if ( iMax <= 0 )
		return 0;

	return random_num( 0, iMax - 1 );
}

// by Nordic Warrior
stock precache_model_ex( const szFileName[ ] )
{
	if ( IsNullString( szFileName ) )
		return 0;

	if ( file_exists( szFileName, true ) )
		return engfunc( EngFunc_PrecacheModel, szFileName );

	set_fail_state( "Model <%s> not found. The plugin has been stopped.", szFileName );
	return 0;
}

stock precache_sound_ex( const szFileName[ ], const bool: bStopPlugin = false )
{
	if ( IsNullString( szFileName ) )
		return 0;

	if ( file_exists( fmt( "sound/%s", szFileName ), true ) )
		return engfunc( EngFunc_PrecacheSound, szFileName );

	if ( bStopPlugin )
		set_fail_state( "Sound <%s> not found. The plugin has been stopped.", szFileName );
	else
		log_amx( "Sound <%s> not found.", szFileName );

	return 0;
}

stock precache_generic_ex( const szFileName[ ], const bool: bStopPlugin = false )
{
	if ( IsNullString( szFileName ) )
		return 0;
	
	if ( file_exists( szFileName, true ) )
		return engfunc(EngFunc_PrecacheGeneric, szFileName);

	if ( bStopPlugin )
		set_fail_state( "Generic file <%s> not found. The plugin has been stopped.", szFileName );
	else
		log_amx( "Generic file <%s> not found.", szFileName );

	return 0;
}

// by Ragamafona
stock bool: UTIL_IsPointInBox( const Vector3( vecMins ), const Vector3( vecMaxs ), const Vector3( vecMins2 ), const Vector3( vecMaxs2 ) )
{
	return bool: (
		( vecMins2[ 0 ] <= vecMaxs[ 0 ] && vecMaxs2[ 0 ] >= vecMins[ 0 ] ) &&
		( vecMins2[ 1 ] <= vecMaxs[ 1 ] && vecMaxs2[ 1 ] >= vecMins[ 1 ] ) &&
		( vecMins2[ 2 ] <= vecMaxs[ 2 ] && vecMaxs2[ 2 ] >= vecMins[ 2 ] )
	);
}

// by Ragamafona
stock bool: UTIL_IsLineThroughCube( const Vector3( vecPointA ), const Vector3( vecPointB ), const Vector3( vecCubeAbsMins ), const Vector3( vecCubeAbsMaxs ) )
{
	new Vector3( vecDir );
	new Vector3( vecMin );
	new Vector3( vecMax );

	for ( new i; i < 3; i++ )
	{
		vecDir[ i ] = 1.0 / ( vecPointB[ i ] - vecPointA[ i ] );
		vecMin[ i ] = ( vecCubeAbsMins[ i ] - vecPointA[ i ] ) * vecDir[ i ];
		vecMax[ i ] = ( vecCubeAbsMaxs[ i ] - vecPointA[ i ] ) * vecDir[ i ];
	}

	new Float: flEnter = floatmax( floatmax( floatmin( vecMin[ 0 ], vecMax[ 0 ] ), floatmin( vecMin[ 1 ], vecMax[ 1 ] ) ), floatmin( vecMin[ 2 ], vecMax[ 2 ] ) );
	new Float: flExit = floatmin( floatmin( floatmax( vecMin[ 0 ], vecMax[ 0 ] ), floatmax( vecMin[ 1 ], vecMax[ 1 ] ) ), floatmax( vecMin[ 2 ], vecMax[ 2 ] ) );

	server_print( "flEnter: %f, flExit: %f", flEnter, flExit );

	return bool: ( flExit >= 0.0 && flEnter <= flExit );
}

// by Ragamafona (надеюсюь это вообще работает)
stock UTIL_ClearDhudChannels( const pPlayer )
{
	for ( new i; i <= 8; i++ )
		show_dhudmessage( pPlayer, "" );
}

stock UTIL_IsAttackInBack( const pVictim, const pAttacker )
{
	new Vector3( vecSrc ); UTIL_GetCenter( pVictim, vecSrc );
	new Vector3( vecDirection ); UTIL_GetCenter( pAttacker, vecDirection );

	xs_vec_sub( vecDirection, vecSrc, vecDirection );
	xs_vec_normalize( vecDirection, vecDirection );

	new Vector3( vecAngles );
	get_entvar( pVictim, var_angles, vecAngles );
	engfunc( EngFunc_MakeVectors, vecAngles );

	new Vector3( vecForward );
	global_get( glb_v_forward, vecForward );
	xs_vec_mul_scalar( vecDirection, -1.0, vecDirection );

	return ( xs_vec_dot( vecForward, vecDirection ) > 0.8 ) ? true : false;
}

stock UTIL_GetCenter( const pPlayer, Vector3( vecSrc ) )
{
	new Vector3( vecAbsMax ); get_entvar( pPlayer, var_absmax, vecAbsMax );
	new Vector3( vecAbsMin ); get_entvar( pPlayer, var_absmin, vecAbsMin );
   
	xs_vec_add( vecAbsMax, vecAbsMin, vecSrc );
	xs_vec_mul_scalar( vecSrc, 0.5, vecSrc );
}