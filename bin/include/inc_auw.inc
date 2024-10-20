#if defined _auw_included
	#endinput
#endif
#define _auw_included

#if 1
	#define __auw__native_str__get_weapon_uid		"auw_get_weapon_uid"
	#define __auw__native_str__give_weapon			"auw_give_weapon"
	#define __auw__native_str__valid_weapon			"auw_valid_weapon"
	#define __auw__native_str__get_weapons_data		"auw_get_weapons_data"


	#define __auw__native__auw_get_weapon_uid		auw_get_weapon_uid
	#define __auw__native__auw_give_weapon			auw_give_weapon
	#define __auw__native__auw_valid_weapon			auw_valid_weapon
	#define __auw__native__auw_get_weapons_data		auw_get_weapons_data
#endif

#define AUW_IMPULSE_OFFSET 128381

enum _:eAUWData
{
	eAUWData_WEAPON_REFERENCE[32],
	WeaponIdType: eAUWData_WEAPON_ID,
	InventorySlotType: eAUWData_WEAPON_SLOT,
	eAUWData_MENU_NAME_ITEM[64],
	eAUWData_WEAPON_COST,
	eAUWData_WEAPON_AMMO,
	eAUWData_WEAPON_BPAMMO,
	Float: eAUWData_WEAPON_DAMAGE,
	eAUWData_WEAPON_ALLOW_ROUND,
	eAUWData_WEAPON_TRACE,
	eAUWData_MENU_WEAPON_ADD,
	eAUWData_WEAPON_ACCESS_FLAGS,
	eAUWData_WEAPON_MODEL_VIEW_TT[64],
	eAUWData_WEAPON_MODEL_VIEW_CT[64],
	eAUWData_WEAPON_MODEL_PLAYER[64],
	eAUWData_WEAPON_MODEL_WORLD[64],
	eAUWData_WEAPON_MODEL_WORLD_NUM,
	eAUWData_WEAPON_KEY
};

enum eAUWForwards
{
	eAUWForwards_OnGiveItemPre,
	eAUWForwards_OnParseEnd,
};

enum eAUWWeaponIdReturn
{
	eAUWWeaponIdReturn_InvalidId = -1
};

enum eAUWGiveItemTypes
{
	eAUWGiveItemTypes_AdminCmd,
	eAUWGiveItemTypes_PlayerCmd,
	eAUWGiveItemTypes_Native,
	eAUWGiveItemTypes_ShopMenu
};

/**
* Retrieves UID by weapon name
*
* @param sWeaponName				Weapon Name
* @param iUidWithOffset				Is UID contain internal offset	
* @return							UID otherwise eAUWWeaponIdReturn_InvalidId
*/

native __auw__native__auw_get_weapon_uid(const sWeaponName[], const bool: iUidWithOffset = true);

/**
* Give weapon by weapon name
*
* @param iPlayer					id
* @param sWeaponName				Weapon Name
* @param notification				Show chat notification's
* @param uid						Weapon UID
* @param iUidWithOffset				Is UID contain internal offset
* @param iBuy						Buy
*	
* @return							true/false
*/

native __auw__native__auw_give_weapon(iPlayer, const sWeaponName[], const bool: notification = true, const uid = -1, const iUidWithOffset = true, const iBuy = 0);

/**
* Checks if the weapon is custom
*
* @param iItem						Weapon Index
* @param iKey						UID
* @param iKeyWithOffset				Is UID contain internal offset
*	
* @return							true/false
*/

native __auw__native__auw_valid_weapon(iItem, iKey, const bool: iKeyWithOffset = true);

/**
* Writes weapon data to array
*
* @param iKey						UID
* @param aData						Array Data
* @param iKeyWithOffset				Is UID contain internal offset
*	
* @return							true/false
*/

native __auw__native__auw_get_weapons_data(iKey, aData[eAUWData], const bool: iKeyWithOffset = true);

/**
* Called before item given, before any internal checks
*
* Return 0 - to continue, any other values to break
*
* @param eGiveItemType				eAUWGiveItemTypes
* @param iPlayer					Player index
* @param iWeaponKey					Weapon raw index (UID - AUW_IMPULSE_OFFSET), can be used with weapons_get_weapons_data + AUW_IMPULSE_OFFSET
* @param iBuy						Is weapon buying, possible should be deprecated due eAUWGiveItemTypes
*	
* @return							nothing
*/

forward auw_on_give_item_pre(const eAUWGiveItemTypes: eGiveItemType, const iPlayer, const iWeaponKey, const iBuy);

/**
* Called after .ini parsing
*
* @param iCount						Parsed weapons count
*	
* @return							nothing
*/

forward auw_on_parse_end(const iCount);