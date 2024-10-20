#if !defined HL_WEAPON_PHYSICS_COMPILE
    #define HL_WEAPON_PHYSICS_COMPILE

// Options

#define Half_Life    // hl || cs/csz    

#define BREAKABLE_REFLECT    // "func_breakable" take dmg on monsters touch (&players)
//#define PUSH_MONSTERS    // push monsters on physics touch

//#define ADMIN_FLAGS ADMIN_RCON    // Admin Flags For - Menu Using, Can Be - (ADMIN_IMMUNITY | ADMIN_BAN) ...

#define SOUNDS_ON    // enable sounds
#define WEAPON_THROWING_ON    // enable weapon throwing (RECOMMENDED! :D)
//#define SPRITE "sprites/arrow1.spr"    // sprite - WEAPON_THROWING_ON
//#define TRAILS_ON    // add trail to throwing entity - WEAPON_THROWING_ON

// Works only in: Cs/Csz
#if !defined Half_Life

//#define zBot_on_server    // enable this if you have zBot on server! (works on "cs/csz" ONLY!) *NEED`s* - "hamsandwich_zBot_FIX" - PLUGIN!
//#define CLCMD_COMMAND     "hl_WeaponPhysics_Menu"    // Create Menu

#define ARMOURY_ENTITY_RANDOMIZER    // enable armoury entity randomizer
#define PHYSICS_RENDERING    // enable rendering    
//#define SHOOT_GRENADES_ON    // enable grenades shooting Works in Cs - Csz Only!
//#define MESSAGE_ON    // enable messages Works in Cs - Csz Only! (shoot grenades)

#endif

// End options
#endif
