#if !defined HL_WEAPON_PHYSICS_CONST
	#define HL_WEAPON_PHYSICS_CONST
	
#pragma semicolon 1

/*
	<<< INCLUDING FILES >>>
*/	

#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>

#include <hl_weapon_physics_compile>
	
/*
	<<< END >>>
*/	
	
// Plugin values
#define VECTOR_SUB 				2.5		// vector sub value - [2], when ground check
#define SEARCHING_RADIUS 		5.0		// in aiming point
#define MAX_REFLECT_A_VELOCITY	192.0	// [0] && [2]
#define MAX_VELOCITY_MULTIPLE	2.5		// [0] && [1] - multiple, when angled(ground has angles) iEntity take dmg
#define MAX_DAMAGE_RECEIVED 	255.0
#define AVAILABLE_MOVETYPE		(1 << MOVETYPE_TOSS) // can be - (1 << MOVETYPE_TOSS | 1 << MOVETYPE_FLY) ...
#define MAX_REFLECT_VELOCITY 	192.0 	// max jump power (axis[2])
#define DAMAGE_DIVIDER 			0.032 	// damage multiple, on received damaged by shot
#define SOUND_HIT				0.5 	// volume
#define SOUND_TOUCH				0.25 	// volume
#define GROUND_TRACE_RESULT   	0.65 	// high angle ground - [2]
#define BLOCK_SOUND_BY_SPEED	128.0 	// min speed(vector_length) to emit sound (on touch)

// Entity data slot
#define PEV_DATA_SLOT pev_iuser2	// hl_extensions -> data, contain touch counts
#define PEV_GROUND_TYPE pev_iuser3	// ground type info -> '4' values, look -> // Ground type
#define PEV_JUMP_REDUCE pev_iuser4	// add velocity or not, depend from: 1)ground type 2)attacker
#define PEV_GROUND_DATA pev_vuser3	// entity ground data - contain ground trace result -> TR_vecPlaneNormal

// Linux diff
#define BROKEN_GLASS_LINUX_OFFSET 4
#define WEAPON_IN_BOX_LINUX_OFFSET 4
#define WEAPON_COUNT_LINUX_OFFSET 4

// Reflect
#define COUNTS_TO_RESET 6 // counts to enable hl_extensions code (physics reflect)

/*

	PRIVATE DATA - DO NOT MODIFY ! (below)

*/

// Some Const
#define GET_FULL_DATA 1

// (1 << 25) - O_O unknown dmg type
#define DMG_UNKNOWN 0x1000000 

// Plugin flags
#define flag_WPN_Mod 1
#define flag_Precache_OFF 2
#define flag_Glass_Status 4

// Grenade Type
#define FLASH_GRENADE 0x0
#define SMOKE_GRENADE 0x1a
#define HE_GRENADE 0x19

#define _class_Empty 0
#define _class_Change 1
#define _class_Blocked 2

// Entity type
#define is_Player 1
#define is_Monster 2
#define is_Breakable 4
#define is_Physics 8

// Check
#define _SpeedVectorCheck 0
#define _SpeedVectorMultiple 1
#define _DamageMultiple 2

// Ground type
#define Ground_Vertical 1
#define Ground_Horizontal 2
#define Ground_Angle_High 4
#define Ground_Angle 8

enum
{
	_Weapon_Mp5Navy = 0,
	_Weapon_Tmp,
	_Weapon_P90,
	_Weapon_Mac10,
	_Weapon_Ak47,
	_Weapon_Sg552,
	_Weapon_M4a1,
	_Weapon_Aug,
	_Weapon_Scout,
	_Weapon_G3sg1,
	_Weapon_Awp,
	_Weapon_M3,
	_Weapon_Xm1014,
	_Weapon_M249,
	_Weapon_Flashbang,
	_Weapon_Hegrenade,
	_Item_Kevlar,
	_Item_Assaultsuit,
	_Weapon_Smokegrenade,
	
	_All_Weapons
};

const _Bit_Weapon_Mp5Navy = 1 << _Weapon_Mp5Navy;
const _Bit_Weapon_Tmp = 1 << _Weapon_Tmp;
const _Bit_Weapon_P90 = 1 << _Weapon_P90;
const _Bit_Weapon_Mac10 = 1 << _Weapon_Mac10;
const _Bit_Weapon_Ak47 = 1 << _Weapon_Ak47;
const _Bit_Weapon_Sg552 = 1 << _Weapon_Sg552;
const _Bit_Weapon_M4a1 = 1 << _Weapon_M4a1;
const _Bit_Weapon_Aug = 1 << _Weapon_Aug;
const _Bit_Weapon_Scout = 1 << _Weapon_Scout;
const _Bit_Weapon_G3sg1 = 1 << _Weapon_G3sg1;
const _Bit_Weapon_Awp = 1 << _Weapon_Awp;
const _Bit_Weapon_M3 = 1 << _Weapon_M3;
const _Bit_Weapon_Xm1014 = 1 << _Weapon_Xm1014;
const _Bit_Weapon_M249 = 1 << _Weapon_M249;
const _Bit_Weapon_Flashbang = 1 << _Weapon_Flashbang;
const _Bit_Weapon_Hegrenade = 1 << _Weapon_Hegrenade;
const _Bit_Item_Kevlar = 1 << _Item_Kevlar;
const _Bit_Item_Assaultsuit = 1 << _Item_Assaultsuit;
const _Bit_Weapon_Smokegrenade = 1 << _Weapon_Smokegrenade;

const g_iConstBitAllWeapons =
(
		_Bit_Weapon_Mp5Navy
	| 
		_Bit_Weapon_Tmp 
	| 
		_Bit_Weapon_P90 
	| 
		_Bit_Weapon_Mac10 
	| 
		_Bit_Weapon_Ak47 
	| 
		_Bit_Weapon_Sg552 
	| 
		_Bit_Weapon_M4a1 
	| 
		_Bit_Weapon_Aug 
	| 
		_Bit_Weapon_Scout 
	| 
		_Bit_Weapon_G3sg1 
	| 
		_Bit_Weapon_Awp 
	| 
		_Bit_Weapon_M3 
	| 
		_Bit_Weapon_Xm1014 
	| 
		_Bit_Weapon_M249
	| 
		_Bit_Weapon_Flashbang 
	| 
		_Bit_Weapon_Hegrenade 
	| 
		_Bit_Item_Kevlar 
	| 
		_Bit_Item_Assaultsuit 
	| 
		_Bit_Weapon_Smokegrenade
);

#endif