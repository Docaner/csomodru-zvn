#if !defined HL_WEAPON_PHYSICS_DATA
	#define HL_WEAPON_PHYSICS_DATA
	
#include <hl_weapon_physics_const>	
	
#if defined SOUNDS_ON
new const g_sTouchSounds[][] =
{
	"misc/wp_touch1.wav",
	"misc/wp_touch2.wav",
	"misc/wp_touch3.wav"
};
	
new const g_sHitSounds[][] =
{
	"misc/wp_bullet1.wav",
	"misc/wp_bullet2.wav",
	"misc/wp_bullet3.wav",
	"misc/wp_bullet4.wav"
};
#endif		
	
new const Float:g_fReduceSpeed[][] = // Change physics jump reflect
{
	// X : Y : Z
		
	{0.25, 0.25, 0.25}, // Ground_Vertical
	{0.5, 0.5, 0.35}, // Ground_Horizontal
	{0.0, 0.0, 0.5}, // Ground_Angle_High
	{0.32, 0.32, 0.32} // Ground_Angle
};	

#if defined PUSH_MONSTERS || defined BREAKABLE_REFLECT
new const Float:g_fMultiple[3][3] = // Reflect Dependency
{
	// 1 - _SpeedVectorCheck
	// 2 - _SpeedVectorMultiple
	// 3 - _DamageMultiple
	
	{32.0, 0.075, 0.1},		// Player
	{32.0, 0.075, 0.25},	// Monster
	{7.5, 0.1, 0.1}			// Breakable
};
#endif

new 

g_iMaxPlayers,
g_iMaxPlayersSizeOf,
g_iPluginFlags,
g_iBitAlive,
Trie:g_TrieBlockedClasses,
Float:g_fMaxDamageMultiple,
Float:g_fClientDamage[32],
g_iClientEntity[32],
g_iClientMenuChoice[32],
cvar_PhysicsEntitySpawnGravity;

#if !defined Half_Life
new 

HamHook:g_HamSpawnPostOFF,
Trie:g_TrieWeaponPos,
g_iArmouryEntityCounter = 0;

#if defined SHOOT_GRENADES_ON
new g_iClientGrenade[32];
#endif

#if defined ARMOURY_ENTITY_RANDOMIZER
new 

g_iRandomWeapons_Enum[_All_Weapons],
g_iWeaponsCounter,
cvar_iWeaponsCount,
cvar_iWeaponsCountCheck,
HamHook:g_HamSpawnPreOFF,
g_iBitWeaponList,
g_sMapName[64];
#endif
#endif

#if defined WEAPON_THROWING_ON
new cvar_WeaponThrowSpeedMultiple;

#if defined TRAILS_ON
new g_SpriteTrail;
#endif
#endif

#if defined SOUNDS_ON
const g_iPrecacheHitSoundSizeOf = sizeof g_sHitSounds;
const g_iPrecacheTouchSoundSizeOf = sizeof g_sTouchSounds;	
#endif

#endif