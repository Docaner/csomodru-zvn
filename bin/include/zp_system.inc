#if defined _zp_system_included
	#endinput
#endif

#define _zp_system_included

/* [ CUSTOM SYSTEMS ] */
native zp_get_user_money( iPlayer ); // Get user money
native zp_set_user_money( iPlayer, iAmount ); // Set user money
native zp_set_user_money_i( iPlayer, iAmount ); // Set user money

native zp_get_user_ammo( iPlayer ); // Get user ammo
native zp_set_user_ammo( iPlayer, iAmount ); // Set user ammo
native zp_set_user_ammo_i( iPlayer, iAmount ); // Set user ammo

native zp_get_user_freewpns( iPlayer ); // Get user freewpns menu
native zp_set_user_freewpns( iPlayer, iValue ); // Set user freewpns menu

native zp_get_user_edamage( iPlayer ); // Get E-Damage level

native zp_is_round_end( ) // Get round end;

native zp_open_service_menu(id) // Services menu

native ZP_GetUserData( iPlayer, iType ); // Get user data (iType: 0 - level | 1 - exp)
native ZP_GetUserExpForNextLevel( iPlayer ); // Get exp for next level getting
native ZP_SetUserData( iPlayer, iType, iAmount ); // Set user data (iType: 0 - level | 1 - exp)
native ZP_GiveUserExp( iPlayer, iAmount ); // Give user exp
native ZP_CheckUserNextLevel( iPlayer ); // Check user has been level up or not

/* [ KNIFE SYSTEMS ] */

native ZPE_SetUserKnifeStrong( iPlayer, bool: bState ); // Set user knife: Strong
native ZPE_SetUserKnifeHammer( iPlayer, iValue ); // Set user knife: Hammer
native ZPE_SetUserKnifeWarHammer( iPlayer, bool: bState ); // Set user knife: Stormgiant Warhammer

native ZPE_GetUserKnife( iPlayer ); // Get user knife
native ZPE_SetUserKnife( iPlayer, iValue ); // Set user knife