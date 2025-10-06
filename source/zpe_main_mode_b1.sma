/* GameMode: Zombie Plague Evolution (за основу взят ZP 4.3 Fix5a) */
/* Version: 1.0 beta */
/* Author: DesortioN */

#define FIRSTZOMBIE_PERCENT 0.14 // Процент от живых людей первых зомби

enum _:TypeRandom
{
	//Обычный рандом
	e_RandomDef = 0,

	//Рандом с приоритетом
	e_RandomPriority
}

new const ZP_CUSTOMIZATION_FILE[] = "main_mode.ini"
new const ZP_EXTRAITEMS_FILE[] = "addon_extraitems.ini"
new const ZP_ZOMBIECLASSES_FILE[] = "addon_zclasses.ini"

const MAX_CSDM_SPAWNS = 128
const MAX_STATS_SAVED = 64

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <zp_system>
#include <reapi>
#include <zpe_lvl>
#include <human_models>
#include <api_maxspeed>
#include <api_identifier>


// CUSTOM CSO NATIVES
native zp_check_vote()
native zp_get_autorr()
native zp_menu_admin_give(id)
native zp_get_user_wpnlvl(id)
native zp_user_wpnlvl_progress(id)

// WEAPONS FOR HERO
native zp_give_user_svdex(id);
native zp_give_user_infinityr(id);

//Пила
native zpe_get_user_chainsaw(id);


// CUSTOM CSO DEFINES
#define m_pNext 42
#define m_iId 43
#define m_rpgPlayerItems 367
#define MsgId_SayText 76

#define MsgId_ScreenFade 98

// VERSION OF CSO MODE
new const PLUGIN_VERSION[] = "1.1"

// Customization file sections
enum
{
	SECTION_NONE = 0,
	SECTION_ACCESS_FLAGS,
	SECTION_PLAYER_MODELS,
	SECTION_WEAPON_MODELS,
	SECTION_GRENADE_SPRITES,
	SECTION_SOUNDS,
	SECTION_AMBIENCE_SOUNDS,
	SECTION_BUY_MENU_WEAPONS,
	SECTION_EXTRA_ITEMS_WEAPONS,
	SECTION_HARD_CODED_ITEMS_COSTS,
	SECTION_WEATHER_EFFECTS,
	SECTION_SKY,
	SECTION_ZOMBIE_DECALS,
	SECTION_OBJECTIVE_ENTS,
	SECTION_SVC_BAD
}

// Access flags
enum
{
	ACCESS_ENABLE_MOD = 0,
	ACCESS_ADMIN_MENU,
	ACCESS_MODE_INFECTION,
	ACCESS_MODE_NEMESIS,
	ACCESS_MODE_SURVIVOR,
	ACCESS_MODE_SWARM,
	ACCESS_MODE_MULTI,
	ACCESS_MODE_PLAGUE,
	ACCESS_MAKE_ZOMBIE,
	ACCESS_MAKE_HUMAN,
	ACCESS_MAKE_NEMESIS,
	ACCESS_MAKE_SURVIVOR,
	ACCESS_RESPAWN_PLAYERS,
	MAX_ACCESS_FLAGS
}

// Task offsets
enum (+= 100)
{
	TASK_MODEL = 2000,
	TASK_TEAM,
	TASK_SPAWN,
	TASK_BLOOD,
	TASK_AURA,
	TASK_NVISION,
	TASK_FLASH,
	TASK_CHARGE,
	TASK_SHOWHUD,
	TASK_MAKEZOMBIE,
	TASK_AMBIENCESOUNDS,
	TASK_THUNDER,
	TASK_COUNTDOWN
}

// IDs inside tasks
#define ID_MODEL (taskid - TASK_MODEL)
#define ID_TEAM (taskid - TASK_TEAM)
#define ID_SPAWN (taskid - TASK_SPAWN)
#define ID_BLOOD (taskid - TASK_BLOOD)
#define ID_AURA (taskid - TASK_AURA)
#define ID_NVISION (taskid - TASK_NVISION)
#define ID_FLASH (taskid - TASK_FLASH)
#define ID_CHARGE (taskid - TASK_CHARGE)
#define ID_SHOWHUD (taskid - TASK_SHOWHUD)

// BP Ammo Refill task
#define REFILL_WEAPONID args[0]

// For weapon buy menu handlers
#define WPN_STARTID g_menu_data[id][1]
#define WPN_MAXIDS ArraySize(g_primary_items)
#define WPN_SELECTION (g_menu_data[id][1]+key)
#define WPN_AUTO_ON g_menu_data[id][2]
#define WPN_AUTO_PRI g_menu_data[id][3]
#define WPN_AUTO_SEC g_menu_data[id][4]

// For player list menu handlers
#define PL_ACTION g_menu_data[id][0]

// For remembering menu pages
#define MENU_PAGE_ZCLASS g_menu_data[id][5]
#define MENU_PAGE_EXTRAS g_menu_data[id][6]
#define MENU_PAGE_PLAYERS g_menu_data[id][7]

// For extra items menu handlers
#define EXTRAS_CUSTOM_STARTID (EXTRA_WEAPONS_STARTID + ArraySize(g_extraweapon_names))

// Menu selections
const MENU_KEY_AUTOSELECT = 7
const MENU_KEY_BACK = 7
const MENU_KEY_NEXT = 8
const MENU_KEY_EXIT = 9

// Hard coded extra items
enum
{
	EXTRA_NVISION = 0,
	EXTRA_ANTIDOTE,
	EXTRA_MADNESS,
	EXTRA_WEAPONS_STARTID
}

// Game modes
enum
{
	MODE_NONE = 0,
	MODE_INFECTION,
	MODE_NEMESIS,
	MODE_SURVIVOR,
	MODE_SWARM,
	MODE_MULTI,
	MODE_PLAGUE
}

// ZP Teams
const ZP_TEAM_NO_ONE = 0
const ZP_TEAM_ANY = 0
const ZP_TEAM_ZOMBIE = (1<<0)
const ZP_TEAM_HUMAN = (1<<1)
const ZP_TEAM_NEMESIS = (1<<2)
const ZP_TEAM_SURVIVOR = (1<<3)
new const ZP_TEAM_NAMES[][] = { "ZOMBIE , HUMAN", "ZOMBIE", "HUMAN", "ZOMBIE , HUMAN", "NEMESIS",
			"ZOMBIE , NEMESIS", "HUMAN , NEMESIS", "ZOMBIE , HUMAN , NEMESIS",
			"SURVIVOR", "ZOMBIE , SURVIVOR", "HUMAN , SURVIVOR", "ZOMBIE , HUMAN , SURVIVOR",
			"NEMESIS , SURVIVOR", "ZOMBIE , NEMESIS , SURVIVOR", "HUMAN, NEMESIS, SURVIVOR",
			"ZOMBIE , HUMAN , NEMESIS , SURVIVOR" }

// Zombie classes
const ZCLASS_NONE = 0

// HUD messages
const Float:HUD_EVENT_X = -1.0
const Float:HUD_EVENT_Y = 0.17
const Float:HUD_INFECT_X = 0.05
const Float:HUD_INFECT_Y = 0.45
const Float:HUD_SPECT_X = 0.6
const Float:HUD_SPECT_Y = 0.8
const Float:HUD_STATS_X = 0.02
const Float:HUD_STATS_Y = 0.9


// CS Player PData Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_PAINSHOCK = 108 // ConnorMcLeod
const OFFSET_CSTEAMS = 114
const OFFSET_CSMONEY = 115
const OFFSET_CSMENUCODE = 205
const OFFSET_FLASHLIGHT_BATTERY = 244
const OFFSET_CSDEATHS = 444
const OFFSET_MODELINDEX = 491

// CS Player CBase Offsets (win32)
const OFFSET_ACTIVE_ITEM = 373

// CS Weapon CBase Offsets (win32)
const OFFSET_WEAPONOWNER = 41

// Linux diff's
const OFFSET_LINUX = 5 // offsets 5 higher in Linux builds
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux

// CS Teams
enum
{
	TEAM_UNASSIGNED = 0,
	TEAM_TERRORIST,
	TEAM_CT,
	TEAM_SPECTATOR
}
//new const CS_TEAM_NAMES[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }

// Some constants
const HIDE_MONEY = (1<<5)
const UNIT_SECOND = (1<<12)
const DMG_HEGRENADE = (1<<24)
const IMPULSE_FLASHLIGHT = 100
const USE_USING = 2
const USE_STOPPED = 0
const STEPTIME_SILENT = 999
const FFADE_IN = 0x0000
const FFADE_STAYOUT = 0x0004
const PEV_SPEC_TARGET = pev_iuser2

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

// Max Clip for weapons
/*new const MAXCLIP[] = { -1, 13, -1, 10, -1, 7, -1, 30, 30, -1, 30, 20, 25, 30, 35, 25, 12, 20,
			10, 30, 100, 8, 30, 30, 20, -1, 7, 30, 30, -1, 50 }
*/
// Ammo IDs for weapons
new const AMMOID[] = { -1, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10,
			1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 }			

// Ammo Type Names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

// Weapon IDs for ammo types
/*new const AMMOWEAPON[] = { 0, CSW_AWP, CSW_SCOUT, CSW_M249, CSW_AUG, CSW_XM1014, CSW_MAC10, CSW_FIVESEVEN, CSW_DEAGLE,
			CSW_P228, CSW_ELITE, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_C4 }
*/
// Primary and Secondary Weapon Names
new const WEAPONNAMES[][] = { "", "P228 Compact", "", "Schmidt Scout", "", "Дробовик \r[XM1014]", "", "Ingram MAC-10", "Steyr AUG A1",
			"", "Пистолет \r[Dual Berettas]", "FiveseveN", "UMP 45", "SG-550 Auto-Sniper", "IMI Galil", "Famas",
			"Пистолет \r[USP]", "Пистолет \r[GLOCK-18]", "AWP Magnum Sniper", "MP5 Navy", "M249 Para Machinegun",
			"M3 Super 90", "Автомат \r[M4A1]", "Schmidt TMP", "G3SG1 Auto-Sniper", "", "Пистолет \r[Deagle]",
			"SG-552 Commando", "Автомат \r[AK-47]", "", "ES P90" }

// Weapon entity names
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", 
			"weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90" }

// CS sounds
new const sound_flashlight[] = "items/flashlight1.wav"
new const sound_buyammo[] = "items/9mmclip1.wav"
new const sound_armorhit[] = "player/bhit_helmet-1.wav"

// Explosion radius for custom grenades
const Float:NADE_EXPLOSION_RADIUS = 240.0

// HACK: pev_ field used to store additional ammo on weapons
const PEV_ADDITIONAL_AMMO = pev_iuser1

// HACK: pev_ field used to store custom nade types and their values
// const PEV_NADE_TYPE = pev_flTimeStepSound
// const NADE_TYPE_NAPALM = 1111

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

// Allowed weapons for zombies (added grenades/bomb for sub-plugin support, since they shouldn't be getting them anyway)
const ZOMBIE_ALLOWED_WEAPONS_BITSUM = (1<<CSW_KNIFE)|(1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)

// Classnames for separate model entities
new const MODEL_ENT_CLASSNAME[] = "player_model"
new const WEAPON_ENT_CLASSNAME[] = "weapon_model"

// Menu keys
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

// Ambience Sounds
enum
{
	AMBIENCE_SOUNDS_INFECTION = 0,
	AMBIENCE_SOUNDS_NEMESIS,
	AMBIENCE_SOUNDS_SURVIVOR,
	AMBIENCE_SOUNDS_SWARM,
	AMBIENCE_SOUNDS_PLAGUE,
	MAX_AMBIENCE_SOUNDS
}

// Admin menu actions
enum
{
	ACTION_ZOMBIEFY_HUMANIZE = 0,
	ACTION_MAKE_NEMESIS,
	ACTION_MAKE_SURVIVOR,
	ACTION_RESPAWN_PLAYER,
	ACTION_MODE_SWARM,
	ACTION_MODE_MULTI,
	ACTION_MODE_PLAGUE
}

// Custom forward return values
const ZP_PLUGIN_HANDLED = 97

/*================================================================================
 [Global Variables]
=================================================================================*/
//Menus
new g_iMenuPosition[33];
#define PLAYERS_PER_PAGE 7

// Player vars
new g_zombie[33] // is zombie
new g_nemesis[33] // is nemesis
new g_survivor[33] // is survivor
new g_hero[33] // is hero
new g_firstzombie[33] // is first zombie
new g_lastzombie[33] // is last zombie
new g_lasthuman[33] // is last human
new g_respawn_as_zombie[33] // should respawn as zombie
new g_nvision[33] // has night vision
new g_nvisionenabled[33] // has night vision turned on
new g_zombieclass[33] // zombie class
new g_zombieclassnext[33] // zombie class for next infection
new g_flashlight[33] // has custom flashlight turned on
new g_flashbattery[33] = { 100, ... } // custom flashlight battery
new g_canbuy[33] // is allowed to buy a new weapon through the menu
new g_ammopacks[33] // ammo pack count
new g_damagedealt_human[33] // damage dealt as human (used to calculate ammo packs reward)
new g_damagedealt_zombie[33] // damage dealt as zombie (used to calculate ammo packs reward)
new Float:g_lastleaptime[33] // time leap was last used
new Float:g_lastflashtime[33] // time flashlight was last toggled
new g_playermodel[33][32] // current model's short name [player][model]
new g_menu_data[33][8] // data for some menu handlers
new g_ent_playermodel[33] // player model entity
new g_ent_weaponmodel[33] // weapon model entity
new Float:g_buytime[33] // used to calculate custom buytime

// Game vars
new g_pluginenabled // ZP enabled
new g_newround // new round starting
new g_endround // round ended
new g_nemround // nemesis round
new g_survround // survivor round
new g_swarmround // swarm round
new g_plagueround // plague round
new g_modestarted // mode fully started
new g_lastmode // last played mode
new g_scorezombies, g_scorehumans, g_gamecommencing // team scores
new g_spawnCount, g_spawnCount2 // available spawn points counter
new Float:g_spawns[MAX_CSDM_SPAWNS][3], Float:g_spawns2[MAX_CSDM_SPAWNS][3] // spawn points data
new g_lights_i // lightning current lights counter
new g_lights_cycle[32] // current lightning cycle
new g_lights_cycle_len // lightning cycle length
new Float:g_models_targettime // for adding delays between Model Change messages
//new Float:g_teams_targettime // for adding delays between Team Change messages
new g_MsgSync, g_MsgSync2, g_MsgSync3 // message sync objects
//new g_flameSpr, g_flameSprWater, g_smokeSpr // grenade sprites
new g_modname[32] // for formatting the mod name
new g_freezetime // whether CS's freeze time is on
new g_maxplayers // max players counter
new g_czero // whether we are running on a CZ server
new g_hamczbots // whether ham forwards are registered for CZ bots
new g_fwSpawn, g_fwPrecacheSound // spawn and precache sound forward handles
new g_antidotecounter, g_madnesscounter // to limit buying some items
new g_arrays_created // to prevent stuff from being registered before initializing arrays
new g_lastplayerleaving // flag for whenever a player leaves and another takes his place
//new g_switchingteam // flag for whenever a player's team change emessage is sent
new g_buyzone_ent // custom buyzone entity

// Message IDs vars
new g_msgScoreInfo, g_msgNVGToggle, g_msgScoreAttrib, g_msgAmmoPickup, g_msgScreenFade,
g_msgDeathMsg, g_msgFlashlight, g_msgFlashBat, /*g_msgTeamInfo,*/ g_msgDamage, 
g_msgSayText, g_msgScreenShake//, g_msgCurWeapon

// Some forward handlers
new g_fwRoundStart, g_fwRoundEnd, g_fwUserInfected_pre, g_fwUserInfected_post,
g_fwUserHumanized_pre, g_fwUserHumanized_post, g_fwUserInfect_attempt,
g_fwUserHumanize_attempt, g_fwExtraItemSelected, g_fwUserLastZombie, g_fwUserLastHuman, g_fwDummyResult

// Temporary Database vars (used to restore players stats in case they get disconnected)
new db_name[MAX_STATS_SAVED][32] // player name
new db_ammopacks[MAX_STATS_SAVED] // ammo pack count
new db_zombieclass[MAX_STATS_SAVED] // zombie class
new db_slot_i // additional saved slots counter (should start on maxplayers+1)

// Extra Items vars
new Array:g_extraitem_name // caption
new Array:g_extraitem_cost // cost
new Array:g_extraitem_team // team
new g_extraitem_i // loaded extra items counter

// For extra items file parsing
new Array:g_extraitem2_realname, Array:g_extraitem2_name, Array:g_extraitem2_cost,
Array:g_extraitem2_team, Array:g_extraitem_new

// Zombie Classes vars
new Array:g_zclass_name // caption
new Array:g_zclass_info // description
new Array:g_zclass_modelsstart // start position in models array
new Array:g_zclass_modelsend // end position in models array
new Array:g_zclass_playermodel // player models array
new Array:g_zclass_modelindex // model indices array
new Array:g_zclass_clawmodel // claw model
new Array:g_zclass_hp // health
new Array:g_zclass_maxhp // max health
new Array:g_zclass_spd // speed
new Array:g_zclass_grav // gravity
new Array:g_zclass_kb // knockback
new g_zclass_i // loaded zombie classes counter

// For zombie classes file parsing
new Array:g_zclass2_realname, Array:g_zclass2_name, Array:g_zclass2_info,
Array:g_zclass2_modelsstart, Array:g_zclass2_modelsend, Array:g_zclass2_playermodel,
Array:g_zclass2_modelindex, Array:g_zclass2_clawmodel, Array:g_zclass2_hp, Array:g_zclass2_maxhp,
Array:g_zclass2_spd, Array:g_zclass2_grav, Array:g_zclass2_kb, Array:g_zclass_new

// Zombie sounds
new Array:class_sound_infect, Array:class_sound_infect_adv, Array:class_sound_pain, Array:class_sound_idle,
Array:class_sound_idle_last, Array:class_sound_die, Array:class_sound_fall,
Array:class_sound_madness, Array:class_sound_burn, Array:class_sound_miss_slash,
Array:class_sound_miss_wall, Array:class_sound_hit_normal, Array:class_sound_hit_stab,
Array:pointer_class_sound_infect, Array:pointer_class_sound_infect_adv, Array:pointer_class_sound_pain, Array:pointer_class_sound_idle,
Array:pointer_class_sound_idle_last, Array:pointer_class_sound_die, Array:pointer_class_sound_fall,
Array:pointer_class_sound_madness, Array:pointer_class_sound_burn, Array:pointer_class_sound_miss_slash,
Array:pointer_class_sound_miss_wall, Array:pointer_class_sound_hit_normal, Array:pointer_class_sound_hit_stab

// Nemesis sounds
new Array:nemesis_pain, Array:nemesis_idle, Array:nemesis_die,
Array:nemesis_fall, Array:nemesis_miss_slash, Array:nemesis_miss_wall,
Array:nemesis_hit_normal, Array:nemesis_hit_stab

// Customization vars
new g_access_flag[MAX_ACCESS_FLAGS], Array:model_nemesis, Array:g_modelindex_nemesis, g_same_models_for_all, model_vknife_nemesis[64], 
Array:sound_win_zombies, Array:sound_win_humans, Array:sound_win_no_one, Array:sound_win_zombies_ismp3,
Array:sound_win_humans_ismp3, Array:sound_win_no_one_ismp3, g_ambience_rain, Array:sound_nemesis, Array:sound_survivor,
Array:sound_swarm, Array:sound_multi, Array:sound_plague, Array:sound_antidote, g_ambience_sounds[MAX_AMBIENCE_SOUNDS],
Array:sound_ambience1, Array:sound_ambience2, Array:sound_ambience3, Array:sound_ambience4,
Array:sound_ambience5, Array:sound_ambience1_duration, Array:sound_ambience2_duration, Array:sound_ambience3_duration, Array:sound_ambience4_duration,
Array:sound_ambience5_duration, Array:sound_ambience1_ismp3, Array:sound_ambience2_ismp3,
Array:sound_ambience3_ismp3, Array:sound_ambience4_ismp3, Array:sound_ambience5_ismp3,
Array:g_primary_items, Array:g_secondary_items, Array:g_primary_weaponids, Array:g_secondary_weaponids, Array:g_extraweapon_names,
Array:g_extraweapon_items, Array:g_extraweapon_costs, g_extra_costs2[EXTRA_WEAPONS_STARTID],
g_ambience_snow, g_ambience_fog, g_fog_density[10], g_fog_color[12], g_sky_enable,
Array:g_sky_names, Array:zombie_decals, Array:g_objective_ents,
Float:g_modelchange_delay, g_set_modelindex_offset, g_handle_models_on_separate_ent,
g_force_consistency, sprite_grenade_fire[64], sprite_grenade_smoke[64], sprite_fire_watergun[64]

// CVAR pointers
new cvar_lighting, cvar_plague, cvar_plaguechance, cvar_zombiefirsthp,
cvar_zombiebonushp, cvar_zombiebonushp_vip, cvar_nemhp, cvar_nem, cvar_surv,
cvar_nemchance, cvar_deathmatch, cvar_customnvg, cvar_humanhp, cvar_hitzones, 
cvar_nemgravity, cvar_flashsize, cvar_ammodamage_human, cvar_ammodamage_zombie,
cvar_zombiearmor, cvar_survpainfree, cvar_nempainfree, cvar_nemspd, cvar_survchance,
cvar_survhp, cvar_survspd, cvar_humanspd, cvar_swarmchance, cvar_flashdrain,
cvar_zombiebleeding, cvar_removedoors, cvar_customflash, cvar_randspawn, cvar_multi,
cvar_multichance, cvar_infammo, cvar_swarm, cvar_ammoinfect, cvar_toggle, cvar_triggered, cvar_flashcharge, cvar_survgravity,
cvar_humangravity, cvar_nvgsize, cvar_extraitems, 
cvar_humanlasthp, cvar_nemignorefrags, cvar_warmup,
cvar_flashdist, cvar_survignorefrags, cvar_multiratio, cvar_spawndelay, cvar_extraantidote, cvar_extramadness,
cvar_extraweapons, cvar_extranvision, cvar_nvggive, cvar_preventconsecutive, cvar_botquota,
cvar_buycustom, cvar_zombiepainfree, cvar_survbasehp, cvar_survaura,
cvar_nemignoreammo, cvar_survignoreammo, cvar_nemaura,
cvar_fragsinfect, cvar_fragskill, cvar_humanarmor, cvar_zombiesilent, cvar_plagueratio, cvar_blocksuicide, 
cvar_nemdamage, cvar_nemdamage2, cvar_leapzombies,
cvar_leapzombiesforce, cvar_leapzombiesheight, cvar_leapzombiescooldown, cvar_leapnemesis,
cvar_leapnemesisforce, cvar_leapnemesisheight, cvar_leapnemesiscooldown, cvar_leapsurvivor,
cvar_leapsurvivorforce, cvar_leapsurvivorheight, cvar_nemminplayers, cvar_survminplayers,
cvar_respawnonsuicide, cvar_respawnafterlast, cvar_leapsurvivorcooldown, cvar_statssave,
cvar_swarmminplayers, cvar_multiminplayers, cvar_plagueminplayers, cvar_nembasehp, cvar_blockpushables, cvar_respawnworldspawnkill,
cvar_madnessduration, cvar_plaguenemnum, cvar_plaguenemhpmulti, cvar_plaguesurvhpmulti,
cvar_plaguesurvnum, cvar_infectionscreenfade, cvar_infectionscreenshake,
cvar_infectionsparkle, cvar_infectiontracers, cvar_infectionparticles,
cvar_allowrespawnsurv, cvar_flashshowall, cvar_allowrespawninfection, cvar_allowrespawnnem,
cvar_allowrespawnswarm, cvar_allowrespawnplague, cvar_survinfammo,
cvar_nvgcolor[3], cvar_nemnvgcolor[3], cvar_flashcolor[3],
cvar_hudicons, cvar_respawnzomb, cvar_respawnhum, cvar_respawnnem, cvar_respawnsurv,
cvar_startammopacks, cvar_randweapons, cvar_antidotelimit, cvar_madnesslimit, cvar_keephealthondisconnect,
cvar_buyzonetime, cvar_huddisplay

// Cached stuff for players
new g_isconnected[33] // whether player is connected
new g_isalive[33] // whether player is alive
new g_isbot[33] // whether player is a bot
new g_currentweapon[33] // player's current weapon id
new g_playername[33][32] // player's name
new Float:g_zombie_spd[33] // zombie class speed
//new Float:g_zombie_knockback[33] // zombie class knockback
new g_zombie_classname[33][32] // zombie class name
#define is_user_valid_connected(%1) (1 <= %1 <= g_maxplayers && g_isconnected[%1])
#define is_user_valid_alive(%1) (1 <= %1 <= g_maxplayers && g_isalive[%1])
#define is_user_valid(%1) (1 <= %1 <= g_maxplayers)

// Cached CVARs
new g_cached_customflash, g_cached_zombiesilent, g_cached_leapzombies, g_cached_leapnemesis,
g_cached_leapsurvivor, Float:g_cached_leapzombiescooldown, Float:g_cached_leapnemesiscooldown,
Float:g_cached_leapsurvivorcooldown, Float:g_cached_buytime

/*================================================================================
 [CUSTOM FOR CSO MODE]
=================================================================================*/

new START_ROUND_SOUND[5][] =
{
	"sound/zp_br_cso/countdown/round_start_1.wav",
	"sound/zp_br_cso/countdown/round_start_2.wav",
	"sound/zp_br_cso/countdown/round_start_3.wav",
	"sound/zp_br_cso/countdown/round_start_4.wav",
	"sound/zp_br_cso/countdown/round_start_5.wav"
};

new g_countdown
/*new cvar_fireslowdown, cvar_firedamage*/

new gModelV1[] = "models/zp_br_cso/zombie/grenade/grenade_classic_b11.mdl"
new gModelV2[] = "models/zp_br_cso/zombie/grenade/grenade_fast.mdl"
new gModelV3[] = "models/zp_br_cso/zombie/grenade/grenade_healer_b6.mdl"
new gModelV4[] = "models/zp_br_cso/zombie/grenade/grenade_heavy.mdl"
new gModelV5[] = "models/zp_br_cso/zombie/grenade/grenade_hunter.mdl"
new gModelV6[] = "models/zp_br_cso/zombie/grenade/grenade_shaman_b5.mdl"
new gModelV7[] = "models/zp_br_cso/zombie/grenade/grenade_tesla_b8.mdl"
new gModelV8[] = "models/zp_br_cso/zombie/grenade/grenade_spindiver.mdl"
new gModelV9[] = "models/zp_br_cso/zombie/grenade/grenade_china_2.mdl"

new iPlayerAimInfo[35]

/*================================================================================
 [Natives, Precache and Init]
=================================================================================*/

public plugin_natives()
{
	// Player specific natives
	register_native("zp_get_user_zombie", "native_get_user_zombie", 1)
	register_native("zp_get_user_nemesis", "native_get_user_nemesis", 1)
	register_native("zp_get_user_survivor", "native_get_user_survivor", 1)
	register_native("zp_get_user_hero", "native_get_user_hero", 1)
	register_native("zp_get_user_first_zombie", "native_get_user_first_zombie", 1)
	register_native("zp_get_user_last_zombie", "native_get_user_last_zombie", 1)
	register_native("zp_get_user_last_human", "native_get_user_last_human", 1)
	register_native("zp_get_user_zombie_class", "native_get_user_zombie_class", 1)
	register_native("zp_get_user_next_class", "native_get_user_next_class", 1)
	register_native("zp_set_user_zombie_class", "native_set_user_zombie_class", 1)
	register_native("zp_get_user_ammo_packs", "native_get_user_ammo_packs", 1)
	register_native("zp_set_user_ammo_packs", "native_set_user_ammo_packs", 1)
	register_native("zp_get_zombie_maxhealth", "native_get_zombie_maxhealth", 1)
	register_native("zp_get_user_batteries", "native_get_user_batteries", 1)
	register_native("zp_set_user_batteries", "native_set_user_batteries", 1)
	register_native("zp_get_user_nightvision", "native_get_user_nightvision", 1)
	register_native("zp_set_user_nightvision", "native_set_user_nightvision", 1)
	register_native("zp_infect_user", "native_infect_user", 1)
	register_native("zp_disinfect_user", "native_disinfect_user", 1)
	register_native("zp_make_user_nemesis", "native_make_user_nemesis", 1)
	register_native("zp_make_user_survivor", "native_make_user_survivor", 1)
	register_native("zp_respawn_user", "native_respawn_user", 1)
	register_native("zp_force_buy_extra_item", "native_force_buy_extra_item", 1)
	register_native("zp_override_user_model", "native_override_user_model", 1)

	register_native("zp_get_random_burn_sound", "@zp_get_random_burn_sound", false);
	
	// Round natives
	register_native("zp_has_round_started", "native_has_round_started", 1)
	register_native("zp_is_nemesis_round", "native_is_nemesis_round", 1)
	register_native("zp_is_survivor_round", "native_is_survivor_round", 1)
	register_native("zp_is_swarm_round", "native_is_swarm_round", 1)
	register_native("zp_is_plague_round", "native_is_plague_round", 1)
	register_native("zp_get_zombie_count", "native_get_zombie_count", 1)
	register_native("zp_get_human_count", "native_get_human_count", 1)
	register_native("zp_get_nemesis_count", "native_get_nemesis_count", 1)
	register_native("zp_get_survivor_count", "native_get_survivor_count", 1)
	register_native("zp_is_round_end", "native_is_round_end", 1)
	
	// External additions natives
	register_native("zp_register_extra_item", "native_register_extra_item", 1)
	register_native("zp_register_zombie_class", "native_register_zombie_class", 1)
	register_native("zp_get_extra_item_id", "native_get_extra_item_id", 1)
	register_native("zp_get_zombie_class_id", "native_get_zombie_class_id", 1)
	register_native("zp_get_zombie_class_info", "native_get_zombie_class_info", 1)
	
	
	register_native("zp_roundstart", "native_zp_roundstart", 1)
}

public plugin_precache()
{
	// Register earlier to show up in plugins list properly after plugin disable/error at loading
	register_plugin("ZP Evolution", PLUGIN_VERSION, "MeRcyLeZZ")
	
	// To switch plugin on/off
	register_concmd("zp_toggle", "cmd_toggle", _, "<1/0> - Enable/Disable Zombie Plague (will restart the current map)", 0)
	cvar_toggle = register_cvar("zp_on", "1")
	
	// Plugin disabled?
	if (!get_pcvar_num(cvar_toggle)) return;
	g_pluginenabled = true
	
	// Initialize a few dynamically sized arrays (alright, maybe more than just a few...)
	model_nemesis = ArrayCreate(32, 1)
	g_modelindex_nemesis = ArrayCreate(1, 1)
	sound_win_zombies = ArrayCreate(64, 1)
	sound_win_zombies_ismp3 = ArrayCreate(1, 1)
	sound_win_humans = ArrayCreate(64, 1)
	sound_win_humans_ismp3 = ArrayCreate(1, 1)
	sound_win_no_one = ArrayCreate(64, 1)
	sound_win_no_one_ismp3 = ArrayCreate(1, 1)
	sound_nemesis = ArrayCreate(64, 1)
	sound_survivor = ArrayCreate(64, 1)
	sound_swarm = ArrayCreate(64, 1)
	sound_multi = ArrayCreate(64, 1)
	sound_plague = ArrayCreate(64, 1)
	sound_antidote = ArrayCreate(64, 1)
	sound_ambience1 = ArrayCreate(64, 1)
	sound_ambience2 = ArrayCreate(64, 1)
	sound_ambience3 = ArrayCreate(64, 1)
	sound_ambience4 = ArrayCreate(64, 1)
	sound_ambience5 = ArrayCreate(64, 1)
	sound_ambience1_duration = ArrayCreate(1, 1)
	sound_ambience2_duration = ArrayCreate(1, 1)
	sound_ambience3_duration = ArrayCreate(1, 1)
	sound_ambience4_duration = ArrayCreate(1, 1)
	sound_ambience5_duration = ArrayCreate(1, 1)
	sound_ambience1_ismp3 = ArrayCreate(1, 1)
	sound_ambience2_ismp3 = ArrayCreate(1, 1)
	sound_ambience3_ismp3 = ArrayCreate(1, 1)
	sound_ambience4_ismp3 = ArrayCreate(1, 1)
	sound_ambience5_ismp3 = ArrayCreate(1, 1)
	g_primary_items = ArrayCreate(32, 1)
	g_secondary_items = ArrayCreate(32, 1)
	g_primary_weaponids = ArrayCreate(1, 1)
	g_secondary_weaponids = ArrayCreate(1, 1)
	g_extraweapon_names = ArrayCreate(32, 1)
	g_extraweapon_items = ArrayCreate(32, 1)
	g_extraweapon_costs = ArrayCreate(1, 1)
	g_sky_names = ArrayCreate(32, 1)
	zombie_decals = ArrayCreate(1, 1)
	g_objective_ents = ArrayCreate(32, 1)
	g_extraitem_name = ArrayCreate(32, 1)
	g_extraitem_cost = ArrayCreate(1, 1)
	g_extraitem_team = ArrayCreate(1, 1)
	g_extraitem2_realname = ArrayCreate(32, 1)
	g_extraitem2_name = ArrayCreate(32, 1)
	g_extraitem2_cost = ArrayCreate(1, 1)
	g_extraitem2_team = ArrayCreate(1, 1)
	g_extraitem_new = ArrayCreate(1, 1)
	g_zclass_name = ArrayCreate(32, 1)
	g_zclass_info = ArrayCreate(32, 1)
	g_zclass_modelsstart = ArrayCreate(1, 1)
	g_zclass_modelsend = ArrayCreate(1, 1)
	g_zclass_playermodel = ArrayCreate(32, 1)
	g_zclass_modelindex = ArrayCreate(1, 1)
	g_zclass_clawmodel = ArrayCreate(32, 1)
	g_zclass_hp = ArrayCreate(1, 1)
	g_zclass_maxhp = ArrayCreate(1, 1)
	g_zclass_spd = ArrayCreate(1, 1)
	g_zclass_grav = ArrayCreate(1, 1)
	g_zclass_kb = ArrayCreate(1, 1)
	g_zclass2_realname = ArrayCreate(32, 1)
	g_zclass2_name = ArrayCreate(32, 1)
	g_zclass2_info = ArrayCreate(32, 1)
	g_zclass2_modelsstart = ArrayCreate(1, 1)
	g_zclass2_modelsend = ArrayCreate(1, 1)
	g_zclass2_playermodel = ArrayCreate(32, 1)
	g_zclass2_modelindex = ArrayCreate(1, 1)
	g_zclass2_clawmodel = ArrayCreate(32, 1)
	g_zclass2_hp = ArrayCreate(1, 1)
	g_zclass2_maxhp = ArrayCreate(1, 1)
	g_zclass2_spd = ArrayCreate(1, 1)
	g_zclass2_grav = ArrayCreate(1, 1)
	g_zclass2_kb = ArrayCreate(1, 1)
	g_zclass_new = ArrayCreate(1, 1)
	nemesis_pain = ArrayCreate(64, 1)
	nemesis_idle = ArrayCreate(64, 1)
	nemesis_die = ArrayCreate(64, 1)
	nemesis_fall = ArrayCreate(64, 1)
	nemesis_miss_slash = ArrayCreate(64, 1)
	nemesis_miss_wall = ArrayCreate(64, 1)
	nemesis_hit_normal = ArrayCreate(64, 1)
	nemesis_hit_stab = ArrayCreate(64, 1)
	class_sound_infect = ArrayCreate(64, 1)
	class_sound_infect_adv = ArrayCreate(64, 1)
	class_sound_pain = ArrayCreate(64, 1)
	class_sound_idle = ArrayCreate(64, 1)
	class_sound_idle_last = ArrayCreate(64, 1)
	class_sound_die = ArrayCreate(64, 1)
	class_sound_fall = ArrayCreate(64, 1)
	class_sound_madness = ArrayCreate(64, 1)
	class_sound_burn = ArrayCreate(64, 1)
	class_sound_miss_slash = ArrayCreate(64, 1)
	class_sound_miss_wall = ArrayCreate(64, 1)
	class_sound_hit_normal = ArrayCreate(64, 1)
	class_sound_hit_stab = ArrayCreate(64, 1)
	pointer_class_sound_infect = ArrayCreate(10, 1)
	pointer_class_sound_infect_adv = ArrayCreate(10, 1)
	pointer_class_sound_pain = ArrayCreate(10, 1)
	pointer_class_sound_idle = ArrayCreate(10, 1)
	pointer_class_sound_idle_last = ArrayCreate(10, 1)
	pointer_class_sound_die = ArrayCreate(10, 1)
	pointer_class_sound_fall = ArrayCreate(64, 1)
	pointer_class_sound_madness = ArrayCreate(10, 1)
	pointer_class_sound_burn = ArrayCreate(10, 1)
	pointer_class_sound_miss_slash = ArrayCreate(64, 1)
	pointer_class_sound_miss_wall = ArrayCreate(64, 1)
	pointer_class_sound_hit_normal = ArrayCreate(64, 1)
	pointer_class_sound_hit_stab = ArrayCreate(64, 1)
	
	// Allow registering stuff now
	g_arrays_created = true
	
	// Load customization data
	load_customization_from_files()
	
	new i, buffer[100]
	
	// Load up the hard coded extra items
	native_register_extra_item2("NightVision", g_extra_costs2[EXTRA_NVISION], ZP_TEAM_HUMAN)
	native_register_extra_item2("T-Virus Antidote", g_extra_costs2[EXTRA_ANTIDOTE], ZP_TEAM_ZOMBIE)
	native_register_extra_item2("Zombie Madness", g_extra_costs2[EXTRA_MADNESS], ZP_TEAM_ZOMBIE)
	
	// Extra weapons
	for (i = 0; i < ArraySize(g_extraweapon_names); i++)
	{
		ArrayGetString(g_extraweapon_names, i, buffer, charsmax(buffer))
		native_register_extra_item2(buffer, ArrayGetCell(g_extraweapon_costs, i), ZP_TEAM_HUMAN)
	}
	
	// Custom player models
	for (i = 0; i < ArraySize(model_nemesis); i++)
	{
		ArrayGetString(model_nemesis, i, buffer, charsmax(buffer))
		format(buffer, charsmax(buffer), "models/player/%s/%s.mdl", buffer, buffer)
		ArrayPushCell(g_modelindex_nemesis, engfunc(EngFunc_PrecacheModel, buffer))
		if (g_force_consistency == 1) force_unmodified(force_model_samebounds, {0,0,0}, {0,0,0}, buffer)
		if (g_force_consistency == 2) force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, buffer)
		// Precache modelT.mdl files too
		copy(buffer[strlen(buffer)-4], charsmax(buffer) - (strlen(buffer)-4), "T.mdl")
		if (file_exists(buffer)) engfunc(EngFunc_PrecacheModel, buffer)
	}
	
	// Custom weapon models
	engfunc(EngFunc_PrecacheModel, model_vknife_nemesis)
	
	// Custom sprites
	//g_flameSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_fire)
	//g_flameSprWater = engfunc(EngFunc_PrecacheModel, sprite_fire_watergun)
	//g_smokeSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_smoke)
	
	// Custom sounds
	for (i = 0; i < ArraySize(sound_win_zombies); i++)
	{
		ArrayGetString(sound_win_zombies, i, buffer, charsmax(buffer))
		if (ArrayGetCell(sound_win_zombies_ismp3, i))
		{
			format(buffer, charsmax(buffer), "sound/%s", buffer)
			engfunc(EngFunc_PrecacheGeneric, buffer)
		}
		else
		{
			engfunc(EngFunc_PrecacheSound, buffer)
		}
	}
	for (i = 0; i < ArraySize(sound_win_humans); i++)
	{
		ArrayGetString(sound_win_humans, i, buffer, charsmax(buffer))
		if (ArrayGetCell(sound_win_humans_ismp3, i))
		{
			format(buffer, charsmax(buffer), "sound/%s", buffer)
			engfunc(EngFunc_PrecacheGeneric, buffer)
		}
		else
		{
			engfunc(EngFunc_PrecacheSound, buffer)
		}
	}
	for (i = 0; i < ArraySize(sound_win_no_one); i++)
	{
		ArrayGetString(sound_win_no_one, i, buffer, charsmax(buffer))
		if (ArrayGetCell(sound_win_no_one_ismp3, i))
		{
			format(buffer, charsmax(buffer), "sound/%s", buffer)
			engfunc(EngFunc_PrecacheGeneric, buffer)
		}
		else
		{
			engfunc(EngFunc_PrecacheSound, buffer)
		}
	}
	for (i = 0; i < ArraySize(sound_nemesis); i++)
	{
		ArrayGetString(sound_nemesis, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(sound_survivor); i++)
	{
		ArrayGetString(sound_survivor, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(sound_swarm); i++)
	{
		ArrayGetString(sound_swarm, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(sound_multi); i++)
	{
		ArrayGetString(sound_multi, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(sound_plague); i++)
	{
		ArrayGetString(sound_plague, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(sound_antidote); i++)
	{
		ArrayGetString(sound_antidote, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(nemesis_pain); i++)
	{
		ArrayGetString(nemesis_pain, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(nemesis_idle); i++)
	{
		ArrayGetString(nemesis_idle, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(nemesis_die); i++)
	{
		ArrayGetString(nemesis_die, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(nemesis_fall); i++)
	{
		ArrayGetString(nemesis_fall, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(nemesis_miss_slash); i++)
	{
		ArrayGetString(nemesis_miss_slash, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(nemesis_miss_wall); i++)
	{
		ArrayGetString(nemesis_miss_wall, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(nemesis_hit_normal); i++)
	{
		ArrayGetString(nemesis_hit_normal, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(nemesis_hit_stab); i++)
	{
		ArrayGetString(nemesis_hit_stab, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_infect); i++)
	{
		ArrayGetString(class_sound_infect, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_infect_adv); i++)
	{
		ArrayGetString(class_sound_infect_adv, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_pain); i++)
	{
		ArrayGetString(class_sound_pain, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_idle); i++)
	{
		ArrayGetString(class_sound_idle, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_idle_last); i++)
	{
		ArrayGetString(class_sound_idle_last, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_die); i++)
	{
		ArrayGetString(class_sound_die, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_fall); i++)
	{
		ArrayGetString(class_sound_fall, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_madness); i++)
	{
		ArrayGetString(class_sound_madness, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_burn); i++)
	{
		ArrayGetString(class_sound_burn, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_miss_slash); i++)
	{
		ArrayGetString(class_sound_miss_slash, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_miss_wall); i++)
	{
		ArrayGetString(class_sound_miss_wall, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_hit_normal); i++)
	{
		ArrayGetString(class_sound_hit_normal, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(class_sound_hit_stab); i++)
	{
		ArrayGetString(class_sound_hit_stab, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	
	// Ambience Sounds
	if (g_ambience_sounds[AMBIENCE_SOUNDS_INFECTION])
	{
		for (i = 0; i < ArraySize(sound_ambience1); i++)
		{
			ArrayGetString(sound_ambience1, i, buffer, charsmax(buffer))
			
			if (ArrayGetCell(sound_ambience1_ismp3, i))
			{
				format(buffer, charsmax(buffer), "sound/%s", buffer)
				engfunc(EngFunc_PrecacheGeneric, buffer)
			}
			else
			{
				engfunc(EngFunc_PrecacheSound, buffer)
			}
		}
	}
	if (g_ambience_sounds[AMBIENCE_SOUNDS_NEMESIS])
	{
		for (i = 0; i < ArraySize(sound_ambience2); i++)
		{
			ArrayGetString(sound_ambience2, i, buffer, charsmax(buffer))
			
			if (ArrayGetCell(sound_ambience2_ismp3, i))
			{
				format(buffer, charsmax(buffer), "sound/%s", buffer)
				engfunc(EngFunc_PrecacheGeneric, buffer)
			}
			else
			{
				engfunc(EngFunc_PrecacheSound, buffer)
			}
		}
	}
	if (g_ambience_sounds[AMBIENCE_SOUNDS_SURVIVOR])
	{
		for (i = 0; i < ArraySize(sound_ambience3); i++)
		{
			ArrayGetString(sound_ambience3, i, buffer, charsmax(buffer))
			
			if (ArrayGetCell(sound_ambience3_ismp3, i))
			{
				format(buffer, charsmax(buffer), "sound/%s", buffer)
				engfunc(EngFunc_PrecacheGeneric, buffer)
			}
			else
			{
				engfunc(EngFunc_PrecacheSound, buffer)
			}
		}
	}
	if (g_ambience_sounds[AMBIENCE_SOUNDS_SWARM])
	{
		for (i = 0; i < ArraySize(sound_ambience4); i++)
		{
			ArrayGetString(sound_ambience4, i, buffer, charsmax(buffer))
			
			if (ArrayGetCell(sound_ambience4_ismp3, i))
			{
				format(buffer, charsmax(buffer), "sound/%s", buffer)
				engfunc(EngFunc_PrecacheGeneric, buffer)
			}
			else
			{
				engfunc(EngFunc_PrecacheSound, buffer)
			}
		}
	}
	if (g_ambience_sounds[AMBIENCE_SOUNDS_PLAGUE])
	{
		for (i = 0; i < ArraySize(sound_ambience5); i++)
		{
			ArrayGetString(sound_ambience5, i, buffer, charsmax(buffer))
			
			if (ArrayGetCell(sound_ambience5_ismp3, i))
			{
				format(buffer, charsmax(buffer), "sound/%s", buffer)
				engfunc(EngFunc_PrecacheGeneric, buffer)
			}
			else
			{
				engfunc(EngFunc_PrecacheSound, buffer)
			}
		}
	}
	
	// CS sounds (just in case)
	engfunc(EngFunc_PrecacheSound, sound_flashlight)
	engfunc(EngFunc_PrecacheSound, sound_buyammo)
	engfunc(EngFunc_PrecacheSound, sound_armorhit)
	
	new ent
	
	// Fake Hostage (to force round ending)
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"))
	if (pev_valid(ent))
	{
		engfunc(EngFunc_SetOrigin, ent, Float:{8192.0,8192.0,8192.0})
		dllfunc(DLLFunc_Spawn, ent)
	}
	
	// Weather/ambience effects
	if (g_ambience_fog)
	{
		ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
		if (pev_valid(ent))
		{
			fm_set_kvd(ent, "density", g_fog_density, "env_fog")
			fm_set_kvd(ent, "rendercolor", g_fog_color, "env_fog")
		}
	}
	if (g_ambience_rain) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"))
	if (g_ambience_snow) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"))
	
	// Custom buyzone for all players
	g_buyzone_ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"))
	if (pev_valid(g_buyzone_ent))
	{
		dllfunc(DLLFunc_Spawn, g_buyzone_ent)
		set_pev(g_buyzone_ent, pev_solid, SOLID_NOT)
	}
	
	// Prevent some entities from spawning
	g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn")
	
	// Prevent hostage sounds from being precached
	g_fwPrecacheSound = register_forward(FM_PrecacheSound, "fw_PrecacheSound")
	
	// CUSTOM FOR CSO MODE 
	precache_generic("sound/zp_br_cso/countdown/10.wav")
	precache_generic("sound/zp_br_cso/countdown/9.wav")
	precache_generic("sound/zp_br_cso/countdown/8.wav")
	precache_generic("sound/zp_br_cso/countdown/7.wav")
	precache_generic("sound/zp_br_cso/countdown/6.wav")
	precache_generic("sound/zp_br_cso/countdown/5.wav")
	precache_generic("sound/zp_br_cso/countdown/4.wav")
	precache_generic("sound/zp_br_cso/countdown/3.wav")
	precache_generic("sound/zp_br_cso/countdown/2.wav")
	precache_generic("sound/zp_br_cso/countdown/1.wav")
	
	precache_generic("sound/zp_br_cso/countdown/countdown_battle_1.wav")
	precache_generic("sound/zp_br_cso/countdown/countdown_battle_2.wav")
	
	engfunc(EngFunc_PrecacheGeneric, START_ROUND_SOUND[0]);
	engfunc(EngFunc_PrecacheGeneric, START_ROUND_SOUND[1]);
	engfunc(EngFunc_PrecacheGeneric, START_ROUND_SOUND[2]);
	engfunc(EngFunc_PrecacheGeneric, START_ROUND_SOUND[3]);
	engfunc(EngFunc_PrecacheGeneric, START_ROUND_SOUND[4]);
	
	engfunc(EngFunc_PrecacheModel, gModelV1)
	engfunc(EngFunc_PrecacheModel, gModelV2)
	engfunc(EngFunc_PrecacheModel, gModelV3)
	engfunc(EngFunc_PrecacheModel, gModelV4)
	engfunc(EngFunc_PrecacheModel, gModelV5)
	engfunc(EngFunc_PrecacheModel, gModelV6)
	engfunc(EngFunc_PrecacheModel, gModelV7)
	engfunc(EngFunc_PrecacheModel, gModelV8)
	engfunc(EngFunc_PrecacheModel, gModelV9)
	
	precache_generic("sprites/zp_br_cso/grenade/weapon_firegrenade.txt");
	precache_generic("sprites/zp_br_cso/grenade/weapon_frostgrenade.txt");
	precache_generic("sprites/zp_br_cso/grenade/weapon_pumpkin.txt");
	precache_generic("sprites/zp_br_cso/grenade/weapon_jumpgrenade.txt");
	
	precache_generic("sprites/zp_br_cso/grenade/640hud7.spr");
	precache_generic("sprites/zp_br_cso/grenade/640hud7x.spr");
	precache_generic("sprites/zp_br_cso/grenade/640hud7sc.spr");
	precache_generic("sprites/zp_br_cso/grenade/640hud28sc.spr");
	precache_generic("sprites/zp_br_cso/grenade/640hud32sc.spr");
	precache_generic("sprites/zp_br_cso/grenade/640hud36sc.spr");
	precache_generic("sprites/zp_br_cso/grenade/640brcso1.spr");
	precache_generic("sprites/zp_br_cso/grenade/640hud61sc.spr");
	
	
	register_clcmd("zp_br_cso/grenade/weapon_firegrenade", "Hook_Fire_SelectWeapon")
	register_clcmd("zp_br_cso/grenade/weapon_frostgrenade", "Hook_He_SelectWeapon")
	register_clcmd("zp_br_cso/grenade/weapon_jumpgrenade", "Hook_Flare_SelectWeapon")
	register_clcmd("zp_br_cso/grenade/weapon_pumpkin", "Hook_Flare_SelectWeapon")
}

public plugin_init()
{
	// Plugin disabled?
	if (!g_pluginenabled) return;
	
	// No zombie classes?
//	if (!g_zclass_i) set_fail_state("No zombie classes loaded!")
	
	// Language files
	register_dictionary("zombie_plague.txt")
	
	// Events
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	//register_event("AmmoX", "event_ammo_x", "be")
	if(g_ambience_sounds[AMBIENCE_SOUNDS_INFECTION] || g_ambience_sounds[AMBIENCE_SOUNDS_NEMESIS] || g_ambience_sounds[AMBIENCE_SOUNDS_SURVIVOR] || g_ambience_sounds[AMBIENCE_SOUNDS_SWARM] || g_ambience_sounds[AMBIENCE_SOUNDS_PLAGUE])
		register_event("30", "event_intermission", "a")
	
	// HAM Forwards
	//RegisterHookChain(RG_CBasePlayer_RoundRespawn, "RG_RoundRespawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoModel, "RG_SetClientUserInfoModel_Pre", false);

	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_pushable", "fw_UsePushable")
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	RegisterHam(Ham_AddPlayerItem, "player", "fw_AddPlayerItem")
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	
	// FM Forwards
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	register_forward(FM_ClientKill, "fw_ClientKill")
	register_forward(FM_EmitSound, "fw_EmitSound")
	//if (!g_handle_models_on_separate_ent) register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue")
	//register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged")
	register_forward(FM_GetGameDescription, "fw_GetGameDescription")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_PlayerPreThink, "fw_itPreThink");
	unregister_forward(FM_Spawn, g_fwSpawn)
	unregister_forward(FM_PrecacheSound, g_fwPrecacheSound)
	
	// Client commands
	register_clcmd("amx_adminmenu", "clcmd_adminmenu");
	register_clcmd("say zpmenu", "clcmd_saymenu")
	register_clcmd("say /zpmenu", "clcmd_saymenu")
	register_clcmd("nightvision", "clcmd_nightvision")
	register_clcmd("drop", "clcmd_drop")
	register_clcmd("buyammo1", "clcmd_buyammo1")
	register_clcmd("buyammo2", "clcmd_buyammo2")
	register_clcmd("chooseteam", "clcmd_changeteam")
	register_clcmd("jointeam", "clcmd_changeteam")
	
	// Menus
	register_menu("Game Menu", KEYSMENU, "menu_game")
	register_menu("show_options_menu", KEYSMENU, "handle_options_menu")
	register_menu("show_privilegies_menu", KEYSMENU, "handle_privilegies_menu")
	register_menu("Buy Menu 1", KEYSMENU, "menu_buy1")
	register_menu("Buy Menu 2", KEYSMENU, "menu_buy2")
	register_menu("Admin Mod Menu", KEYSMENU, "menu_mod_admin")
	register_menu("ADMININFO", KEYSMENU, "menu_admin")
	register_menu("ADMINPLAYERS", KEYSMENU, "menu_admin_players")
	register_menu("CONTACTSCHIEF", KEYSMENU, "menu_contacts_chief")
	register_menu("CONTACTSINFO", KEYSMENU, "menu_contacts")
	register_menu("FREEVIP", KEYSMENU, "menu_freevip")
	register_menu("VIPINFO", KEYSMENU, "menu_vipinfo")
	register_menu("PREMINFO", KEYSMENU, "menu_preminfo")
	register_menu("AGENTINFO", KEYSMENU, "menu_agentinfo")
	register_menu("BOOSTINFO", KEYSMENU, "menu_boostinfo")
	register_menucmd(register_menuid("Show_ClassMenu"), 1023, "Handle_ClassMenu")

	
	// CS Buy Menus (to prevent zombies/survivor from buying)
	/*register_menucmd(register_menuid("#Buy", 1), 511, "menu_cs_buy")
	register_menucmd(register_menuid("BuyPistol", 1), 511, "menu_cs_buy")
	register_menucmd(register_menuid("BuyShotgun", 1), 511, "menu_cs_buy")
	register_menucmd(register_menuid("BuySub", 1), 511, "menu_cs_buy")
	register_menucmd(register_menuid("BuyRifle", 1), 511, "menu_cs_buy")
	register_menucmd(register_menuid("BuyMachine", 1), 511, "menu_cs_buy")
	register_menucmd(register_menuid("BuyItem", 1), 511, "menu_cs_buy")
	register_menucmd(-28, 511, "menu_cs_buy")
	register_menucmd(-29, 511, "menu_cs_buy")
	register_menucmd(-30, 511, "menu_cs_buy")
	register_menucmd(-32, 511, "menu_cs_buy")
	register_menucmd(-31, 511, "menu_cs_buy")
	register_menucmd(-33, 511, "menu_cs_buy")
	register_menucmd(-34, 511, "menu_cs_buy")*/
	
	// Admin commands
	register_concmd("zp_zombie", "cmd_zombie", _, "<target> - Turn someone into a Zombie", 0)
	register_concmd("zp_human", "cmd_human", _, "<target> - Turn someone back to Human", 0)
	register_concmd("zp_nemesis", "cmd_nemesis", _, "<target> - Turn someone into a Nemesis", 0)
	register_concmd("zp_survivor", "cmd_survivor", _, "<target> - Turn someone into a Survivor", 0)
	register_concmd("zp_respawn", "cmd_respawn", _, "<target> - Respawn someone", 0)
	register_concmd("zp_swarm", "cmd_swarm", _, " - Start Swarm Mode", 0)
	register_concmd("zp_multi", "cmd_multi", _, " - Start Multi Infection", 0)
	register_concmd("zp_plague", "cmd_plague", _, " - Start Plague Mode", 0)
	
	// Message IDs
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	//g_msgTeamInfo = get_user_msgid("TeamInfo")
	g_msgDeathMsg = get_user_msgid("DeathMsg")
	g_msgScoreAttrib = get_user_msgid("ScoreAttrib")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_msgNVGToggle = get_user_msgid("NVGToggle")
	g_msgFlashlight = get_user_msgid("Flashlight")
	g_msgFlashBat = get_user_msgid("FlashBat")
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
	g_msgDamage = get_user_msgid("Damage")

	g_msgSayText = get_user_msgid("SayText")
	//g_msgCurWeapon = get_user_msgid("CurWeapon")
	
	// Message hooks
	//register_message(g_msgCurWeapon, "message_cur_weapon")
	register_message(get_user_msgid("Health"), "message_health")
	register_message(g_msgFlashBat, "message_flashbat")
	register_message(g_msgScreenFade, "message_screenfade")
	register_message(g_msgNVGToggle, "message_nvgtoggle")
	//if (g_handle_models_on_separate_ent) register_message(get_user_msgid("ClCorpse"), "message_clcorpse")
	register_message(get_user_msgid("WeapPickup"), "message_weappickup")
	register_message(g_msgAmmoPickup, "message_ammopickup")
	register_message(get_user_msgid("Scenario"), "message_scenario")
	register_message(get_user_msgid("HostagePos"), "message_hostagepos")
	register_message(get_user_msgid("TextMsg"), "message_textmsg")
	register_message(get_user_msgid("SendAudio"), "message_sendaudio")
	register_message(get_user_msgid("TeamScore"), "message_teamscore")
	//register_message(g_msgTeamInfo, "message_teaminfo")
	register_message(get_user_msgid("ShowMenu"), "message_showmenu");
	register_message(get_user_msgid("VGUIMenu"), "message_vguimenu");

	register_message(get_user_msgid("StatusValue"), "msgStatusValue")

	// CVARS - General Purpose
	cvar_warmup = register_cvar("zp_delay", "10")
	cvar_lighting = register_cvar("zp_lighting", "a")
	cvar_triggered = register_cvar("zp_triggered_lights", "1")
	cvar_removedoors = register_cvar("zp_remove_doors", "0")
	cvar_blockpushables = register_cvar("zp_blockuse_pushables", "1")
	cvar_blocksuicide = register_cvar("zp_block_suicide", "1")
	cvar_randspawn = register_cvar("zp_random_spawn", "1")
	cvar_respawnworldspawnkill = register_cvar("zp_respawn_on_worldspawn_kill", "1")
	cvar_buycustom = register_cvar("zp_buy_custom", "1")
	cvar_buyzonetime = register_cvar("zp_buyzone_time", "0.0")
	cvar_randweapons = register_cvar("zp_random_weapons", "0")
	cvar_statssave = register_cvar("zp_stats_save", "1")
	cvar_startammopacks = register_cvar("zp_starting_ammo_packs", "5")
	cvar_preventconsecutive = register_cvar("zp_prevent_consecutive_modes", "1")
	cvar_keephealthondisconnect = register_cvar("zp_keep_health_on_disconnect", "1")
	cvar_huddisplay = register_cvar("zp_hud_display", "1")
	
	// CVARS - Deathmatch
	cvar_deathmatch = register_cvar("zp_deathmatch", "0")
	cvar_spawndelay = register_cvar("zp_spawn_delay", "5")
	cvar_respawnonsuicide = register_cvar("zp_respawn_on_suicide", "0")
	cvar_respawnafterlast = register_cvar("zp_respawn_after_last_human", "1")
	cvar_allowrespawninfection = register_cvar("zp_infection_allow_respawn", "1")
	cvar_allowrespawnnem = register_cvar("zp_nem_allow_respawn", "0")
	cvar_allowrespawnsurv = register_cvar("zp_surv_allow_respawn", "0")
	cvar_allowrespawnswarm = register_cvar("zp_swarm_allow_respawn", "0")
	cvar_allowrespawnplague = register_cvar("zp_plague_allow_respawn", "0")
	cvar_respawnzomb = register_cvar("zp_respawn_zombies", "1")
	cvar_respawnhum = register_cvar("zp_respawn_humans", "1")
	cvar_respawnnem = register_cvar("zp_respawn_nemesis", "1")
	cvar_respawnsurv = register_cvar("zp_respawn_survivors", "1")
	
	// CVARS - Extra Items
	cvar_extraitems = register_cvar("zp_extra_items", "1")
	cvar_extraweapons = register_cvar("zp_extra_weapons", "1")
	cvar_extranvision = register_cvar("zp_extra_nvision", "1")
	cvar_extraantidote = register_cvar("zp_extra_antidote", "1")
	cvar_antidotelimit = register_cvar("zp_extra_antidote_limit", "999")
	cvar_extramadness = register_cvar("zp_extra_madness", "1")
	cvar_madnesslimit = register_cvar("zp_extra_madness_limit", "999")
	cvar_madnessduration = register_cvar("zp_extra_madness_duration", "5.0")
	
	// CVARS - Flashlight and Nightvision
	cvar_nvggive = register_cvar("zp_nvg_give", "1")
	cvar_customnvg = register_cvar("zp_nvg_custom", "1")
	cvar_nvgsize = register_cvar("zp_nvg_size", "80")
	cvar_nvgcolor[0] = register_cvar("zp_nvg_color_R", "0")
	cvar_nvgcolor[1] = register_cvar("zp_nvg_color_G", "150")
	cvar_nvgcolor[2] = register_cvar("zp_nvg_color_B", "0")
	cvar_nemnvgcolor[0] = register_cvar("zp_nvg_nem_color_R", "150")
	cvar_nemnvgcolor[1] = register_cvar("zp_nvg_nem_color_G", "0")
	cvar_nemnvgcolor[2] = register_cvar("zp_nvg_nem_color_B", "0")
	cvar_customflash = register_cvar("zp_flash_custom", "0")
	cvar_flashsize = register_cvar("zp_flash_size", "10")
	cvar_flashdrain = register_cvar("zp_flash_drain", "1")
	cvar_flashcharge = register_cvar("zp_flash_charge", "5")
	cvar_flashdist = register_cvar("zp_flash_distance", "1000")
	cvar_flashcolor[0] = register_cvar("zp_flash_color_R", "100")
	cvar_flashcolor[1] = register_cvar("zp_flash_color_G", "100")
	cvar_flashcolor[2] = register_cvar("zp_flash_color_B", "100")
	cvar_flashshowall = register_cvar("zp_flash_show_all", "1")
	
	// CVARS - Leap
	cvar_leapzombies = register_cvar("zp_leap_zombies", "0")
	cvar_leapzombiesforce = register_cvar("zp_leap_zombies_force", "500")
	cvar_leapzombiesheight = register_cvar("zp_leap_zombies_height", "300")
	cvar_leapzombiescooldown = register_cvar("zp_leap_zombies_cooldown", "5.0")
	cvar_leapnemesis = register_cvar("zp_leap_nemesis", "1")
	cvar_leapnemesisforce = register_cvar("zp_leap_nemesis_force", "500")
	cvar_leapnemesisheight = register_cvar("zp_leap_nemesis_height", "300")
	cvar_leapnemesiscooldown = register_cvar("zp_leap_nemesis_cooldown", "5.0")
	cvar_leapsurvivor = register_cvar("zp_leap_survivor", "0")
	cvar_leapsurvivorforce = register_cvar("zp_leap_survivor_force", "500")
	cvar_leapsurvivorheight = register_cvar("zp_leap_survivor_height", "300")
	cvar_leapsurvivorcooldown = register_cvar("zp_leap_survivor_cooldown", "5.0")
	
	// CVARS - Humans
	cvar_humanhp = register_cvar("zp_human_health", "100")
	cvar_humanlasthp = register_cvar("zp_human_last_extrahp", "0")
	cvar_humanspd = register_cvar("zp_human_speed", "240")
	cvar_humangravity = register_cvar("zp_human_gravity", "1.0")
	cvar_humanarmor = register_cvar("zp_human_armor_protect", "1")
	cvar_infammo = register_cvar("zp_human_unlimited_ammo", "0")
	cvar_ammodamage_human = register_cvar("zp_human_damage_reward", "500")
	cvar_fragskill = register_cvar("zp_human_frags_for_kill", "1")
	
	// CVARS - Custom Cvars
	//cvar_firedamage = register_cvar("zp_fire_damage", "20")
	//cvar_fireslowdown = register_cvar("zp_fire_slowdown", "0.5")
	
	// CVARS - Zombies
	cvar_zombiefirsthp = register_cvar("zp_zombie_first_hp", "600")
	cvar_zombiearmor = register_cvar("zp_zombie_armor", "0.75")
	cvar_hitzones = register_cvar("zp_zombie_hitzones", "0")
	cvar_zombiebonushp = register_cvar("zp_zombie_infect_health", "300")
	cvar_zombiebonushp_vip = register_cvar("zp_zombie_infect_health_vip", "600")
	cvar_zombiesilent = register_cvar("zp_zombie_silent", "1")
	cvar_zombiepainfree = register_cvar("zp_zombie_painfree", "2")
	cvar_zombiebleeding = register_cvar("zp_zombie_bleeding", "1")
	cvar_ammoinfect = register_cvar("zp_zombie_infect_reward", "1")
	cvar_ammodamage_zombie = register_cvar("zp_zombie_damage_reward", "0")
	cvar_fragsinfect = register_cvar("zp_zombie_frags_for_infect", "1")
	
	// CVARS - Special Effects
	cvar_infectionscreenfade = register_cvar("zp_infection_screenfade", "1")
	cvar_infectionscreenshake = register_cvar("zp_infection_screenshake", "1")
	cvar_infectionsparkle = register_cvar("zp_infection_sparkle", "1")
	cvar_infectiontracers = register_cvar("zp_infection_tracers", "1")
	cvar_infectionparticles = register_cvar("zp_infection_particles", "1")
	cvar_hudicons = register_cvar("zp_hud_icons", "1")
	
	// CVARS - Nemesis
	cvar_nem = register_cvar("zp_nem_enabled", "1")
	cvar_nemchance = register_cvar("zp_nem_chance", "20")
	cvar_nemminplayers = register_cvar("zp_nem_min_players", "0")
	cvar_nemhp = register_cvar("zp_nem_health", "0")
	cvar_nembasehp = register_cvar("zp_nem_base_health", "0")
	cvar_nemspd = register_cvar("zp_nem_speed", "250")
	cvar_nemgravity = register_cvar("zp_nem_gravity", "0.5")
	cvar_nemdamage = register_cvar("zp_nem_damage", "75")
	cvar_nemdamage2 = register_cvar("zp_nem_damage2", "150")
	cvar_nemaura = register_cvar("zp_nem_aura", "1")	
	cvar_nempainfree = register_cvar("zp_nem_painfree", "0")
	cvar_nemignorefrags = register_cvar("zp_nem_ignore_frags", "1")
	cvar_nemignoreammo = register_cvar("zp_nem_ignore_rewards", "1")
	
	// CVARS - Survivor
	cvar_surv = register_cvar("zp_surv_enabled", "1")
	cvar_survchance = register_cvar("zp_surv_chance", "20")
	cvar_survminplayers = register_cvar("zp_surv_min_players", "0")
	cvar_survhp = register_cvar("zp_surv_health", "0")
	cvar_survbasehp = register_cvar("zp_surv_base_health", "0")
	cvar_survspd = register_cvar("zp_surv_speed", "230")
	cvar_survgravity = register_cvar("zp_surv_gravity", "1.25")
	cvar_survaura = register_cvar("zp_surv_aura", "1")
	cvar_survpainfree = register_cvar("zp_surv_painfree", "1")
	cvar_survignorefrags = register_cvar("zp_surv_ignore_frags", "1")
	cvar_survignoreammo = register_cvar("zp_surv_ignore_rewards", "1")
	cvar_survinfammo = register_cvar("zp_surv_unlimited_ammo", "2")
	
	// CVARS - Swarm Mode
	cvar_swarm = register_cvar("zp_swarm_enabled", "1")
	cvar_swarmchance = register_cvar("zp_swarm_chance", "20")
	cvar_swarmminplayers = register_cvar("zp_swarm_min_players", "0")
	
	// CVARS - Multi Infection
	cvar_multi = register_cvar("zp_multi_enabled", "1")
	cvar_multichance = register_cvar("zp_multi_chance", "20")
	cvar_multiminplayers = register_cvar("zp_multi_min_players", "0")
	cvar_multiratio = register_cvar("zp_multi_ratio", "0.15")
	
	// CVARS - Plague Mode
	cvar_plague = register_cvar("zp_plague_enabled", "1")
	cvar_plaguechance = register_cvar("zp_plague_chance", "30")
	cvar_plagueminplayers = register_cvar("zp_plague_min_players", "0")
	cvar_plagueratio = register_cvar("zp_plague_ratio", "0.5")
	cvar_plaguenemnum = register_cvar("zp_plague_nem_number", "1")
	cvar_plaguenemhpmulti = register_cvar("zp_plague_nem_hp_multi", "0.5")
	cvar_plaguesurvnum = register_cvar("zp_plague_surv_number", "1")
	cvar_plaguesurvhpmulti = register_cvar("zp_plague_surv_hp_multi", "0.5")
	
	// CVARS - Others
	cvar_botquota = get_cvar_pointer("bot_quota")
	register_cvar("zp_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("zp_version", PLUGIN_VERSION)
	
	// Custom Forwards
	g_fwRoundStart = CreateMultiForward("zp_round_started", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwRoundEnd = CreateMultiForward("zp_round_ended", ET_IGNORE, FP_CELL)
	g_fwUserInfected_pre = CreateMultiForward("zp_user_infected_pre", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_fwUserInfected_post = CreateMultiForward("zp_user_infected_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_fwUserHumanized_pre = CreateMultiForward("zp_user_humanized_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwUserHumanized_post = CreateMultiForward("zp_user_humanized_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwUserInfect_attempt = CreateMultiForward("zp_user_infect_attempt", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_fwUserHumanize_attempt = CreateMultiForward("zp_user_humanize_attempt", ET_CONTINUE, FP_CELL, FP_CELL)
	g_fwExtraItemSelected = CreateMultiForward("zp_extra_item_selected", ET_CONTINUE, FP_CELL, FP_CELL)
	g_fwUserLastZombie = CreateMultiForward("zp_user_last_zombie", ET_IGNORE, FP_CELL)
	g_fwUserLastHuman = CreateMultiForward("zp_user_last_human", ET_IGNORE, FP_CELL)
	
	// Collect random spawn points
	load_spawns()
	
	// Set a random skybox?
	if (g_sky_enable)
	{
		new sky[32]
		ArrayGetString(g_sky_names, random_num(0, ArraySize(g_sky_names) - 1), sky, charsmax(sky))
		set_cvar_string("sv_skyname", sky)
	}
	
	// Disable sky lighting so it doesn't mess with our custom lighting
	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)
	
	// Create the HUD Sync Objects
	g_MsgSync = CreateHudSyncObj()
	g_MsgSync2 = CreateHudSyncObj()
	g_MsgSync3 = CreateHudSyncObj()
	
	// Format mod name
	formatex(g_modname, charsmax(g_modname), "VIP БЕСПЛАТНО")
	
	// Get Max Players
	g_maxplayers = get_maxplayers()
	
	// Reserved saving slots starts on maxplayers+1
	db_slot_i = g_maxplayers+1
	
	// Check if it's a CZ server
	new mymod[6]
	get_modname(mymod, charsmax(mymod))
	if (equal(mymod, "czero")) g_czero = 1
}

public plugin_cfg()
{
	// Plugin disabled?
	if (!g_pluginenabled) return;
	
	// Get configs dir
	new cfgdir[32]
	get_configsdir(cfgdir, charsmax(cfgdir))
	
	// Execute config file (zombieplague.cfg)
	server_cmd("exec %s/zpe_mode/main_mode.cfg", cfgdir)
	
	// Prevent any more stuff from registering
	g_arrays_created = false
	
	// Save customization data
	save_customization()
	
	// Lighting task
	// set_task(1.0, "lighting_effects", _, _, _, "b")
	
	// Cache CVARs after configs are loaded / call roundstart manually
	// set_task(0.5, "cache_cvars")
	// set_task(0.5, "event_round_start")
	// set_task(0.5, "logevent_round_start")
	cache_cvars()
	event_round_start()
	logevent_round_start()
}

public Hook_Fire_SelectWeapon(id)
{
	engclient_cmd(id, "weapon_hegrenade")
	return PLUGIN_HANDLED
}

public Hook_He_SelectWeapon(id)
{
	engclient_cmd(id, "weapon_flashbang")
	return PLUGIN_HANDLED
}

public Hook_Flare_SelectWeapon(id)
{
	engclient_cmd(id, "weapon_smokegrenade")
	return PLUGIN_HANDLED
}

/*================================================================================
 [Main Events]
=================================================================================*/

// Event Round Start
public event_round_start()
{
	// Remove doors/lights?
	set_task(0.1, "remove_stuff")
	
	// New round starting
	g_newround = true
	g_endround = false
	g_survround = false
	g_nemround = false
	g_swarmround = false
	g_plagueround = false
	g_modestarted = false
	
	// Reset bought infection bombs counter
	g_antidotecounter = 0
	g_madnesscounter = 0
	
	// Freezetime begins
	g_freezetime = true
	
	if(!zp_get_autorr())
	{
		if(!zp_check_vote())
		{
			// Set a new "Make Zombie Task"
			remove_task(TASK_MAKEZOMBIE)
			set_task(2.0 + get_pcvar_float(cvar_warmup), "make_zombie_task", TASK_MAKEZOMBIE)
	
			g_countdown = floatround(1.0 + get_pcvar_float(cvar_warmup))
	
			remove_task(TASK_COUNTDOWN)
			set_task(1.0, "countdown", TASK_COUNTDOWN, _, _, "b")
		}
	}

	//Перевести всех теров за ct
	set_all_team_ct();
}

// Log Event Round Start
public logevent_round_start()
{
	// Freezetime ends
	g_freezetime = false
}

// Log Event Round End
public logevent_round_end()
{
	// Prevent this from getting called twice when restarting (bugfix)
	static Float:lastendtime, Float:current_time
	current_time = get_gametime()
	if (current_time - lastendtime < 0.5) return;
	lastendtime = current_time
	
	// Temporarily save player stats?
	if (get_pcvar_num(cvar_statssave))
	{
		static id, TeamName:team
		for (id = 1; id <= g_maxplayers; id++)
		{
			// Not connected
			if (!g_isconnected[id])
				continue;
			
			team = zp_get_user_team(id)
			
			// Not playing
			if (team == TEAM_SPECTATOR || team == TEAM_UNASSIGNED)
				continue;
			
			save_stats(id)
		}
	}
	
	// Round ended
	g_endround = true
	

	// Stop old tasks (if any)
	remove_task(TASK_MAKEZOMBIE);
	remove_task(TASK_COUNTDOWN);
	
	// Stop ambience sounds
	if ((g_ambience_sounds[AMBIENCE_SOUNDS_NEMESIS] && g_nemround) || (g_ambience_sounds[AMBIENCE_SOUNDS_SURVIVOR] && g_survround) || (g_ambience_sounds[AMBIENCE_SOUNDS_SWARM] && g_swarmround) || (g_ambience_sounds[AMBIENCE_SOUNDS_PLAGUE] && g_plagueround) || (g_ambience_sounds[AMBIENCE_SOUNDS_INFECTION] && !g_nemround && !g_survround && !g_swarmround && !g_plagueround))
	{
		remove_task(TASK_AMBIENCESOUNDS)
		ambience_sound_stop()
	}
	
	// Show HUD notice, play win sound, update team scores...
	static sound[64]
	if (!fnGetZombies())
	{
		static id;
		for (id = 1; id <= g_maxplayers; id++)
		{
			// Not connected
			if (!g_isconnected[id] || zp_get_user_team(id) == TEAM_UNASSIGNED || zp_get_user_team(id) == TEAM_SPECTATOR)
				continue;
			
			// Dhud Messages
			if(!zp_get_autorr())
			{
				if(g_zombie[id])
				{
					set_dhudmessage(0, 210, 210, -1.0, 0.20, 2, 0.07, 1.5, 0.07, 0.35)
					show_dhudmessage(id, "%L", LANG_PLAYER, "HUMAN_WIN_DHUD_1")
					zp_set_user_money(id, zp_get_user_money(id) + 1000)
				}
				else
				{
					set_dhudmessage(0, 210, 210, -1.0, 0.20, 2, 0.07, 1.5, 0.07, 0.35)
					show_dhudmessage(id, "%L", LANG_PLAYER, "HUMAN_WIN_DHUD_2")
					zp_set_user_money(id, zp_get_user_money(id) + 2000)
				}
			}
		}
		
		// Play win sound and increase score, unless game commencing
		ArrayGetString(sound_win_humans, random_num(0, ArraySize(sound_win_humans) - 1), sound, charsmax(sound))
		PlaySound(sound)
		
		if (!g_gamecommencing) g_scorehumans++
		
		// Round end forward
		ExecuteForward(g_fwRoundEnd, g_fwDummyResult, ZP_TEAM_HUMAN);
	}
	else if (!fnGetHumans())
	{
		static id;
		for (id = 1; id <= g_maxplayers; id++)
		{
			// Not connected
			if (!g_isconnected[id] || zp_get_user_team(id) == TEAM_UNASSIGNED || zp_get_user_team(id) == TEAM_SPECTATOR)
				continue;
			
			if(!zp_get_autorr())
			{
				if(g_zombie[id])
				{
					set_dhudmessage(180, 0, 0, -1.0, 0.20, 2, 0.07, 1.5, 0.07, 0.35)
					show_dhudmessage(id, "%L", LANG_PLAYER, "ZOMBIE_WIN_DHUD_1")
					zp_set_user_money(id, zp_get_user_money(id) + 2000)
				}
				else
				{
					set_dhudmessage(180, 0, 0, -1.0, 0.20, 2, 0.07, 1.5, 0.07, 0.35)
					show_dhudmessage(id, "%L", LANG_PLAYER, "ZOMBIE_WIN_DHUD_2")
					zp_set_user_money(id, zp_get_user_money(id) + 1000)
				}
			}
		}
		
		// Play win sound and increase score, unless game commencing
		ArrayGetString(sound_win_zombies, random_num(0, ArraySize(sound_win_zombies) - 1), sound, charsmax(sound))
		PlaySound(sound)
		
		if (!g_gamecommencing) g_scorezombies++
		
		// Round end forward
		ExecuteForward(g_fwRoundEnd, g_fwDummyResult, ZP_TEAM_ZOMBIE);
		
	}
	else
	{
		static id;
		for (id = 1; id <= g_maxplayers; id++)
		{
			// Not connected
			if (!g_isconnected[id] || zp_get_user_team(id) == TEAM_UNASSIGNED || zp_get_user_team(id) == TEAM_SPECTATOR)
				continue;
			
			set_dhudmessage(192, 192, 192, -1.0, 0.20, 2, 0.07, 1.5, 0.07, 0.35)
			show_dhudmessage(id, "%L", LANG_PLAYER, "NO_ONE_WIN_DHUD")
			zp_set_user_money(id, zp_get_user_money(id) + 500)
		}
		
		// Play win sound
		ArrayGetString(sound_win_no_one, random_num(0, ArraySize(sound_win_no_one) - 1), sound, charsmax(sound))
		PlaySound(sound)
		
		// Round end forward
		ExecuteForward(g_fwRoundEnd, g_fwDummyResult, ZP_TEAM_NO_ONE);
	}

	// Game commencing triggers round end
	g_gamecommencing = false
	
	// Balance the teams
	//balance_teams()
}

// Event Map Ended
public event_intermission()
{
	// Remove ambience sounds task
	remove_task(TASK_AMBIENCESOUNDS)
}

// BP Ammo update
/*public event_ammo_x(id)
{
	// Humans only
	if (g_zombie[id])
		return;
	
	// Get ammo type
	static type
	type = read_data(1)
	
	// Unknown ammo type
	if (type >= sizeof AMMOWEAPON)
		return;
	
	// Get weapon's id
	static weapon
	weapon = AMMOWEAPON[type]
	
	// Primary and secondary only
	if (MAXBPAMMO[weapon] <= 2)
		return;
	
	// Get ammo amount
	static amount
	amount = read_data(2)
	
	// Unlimited BP Ammo?
	if (g_survivor[id] ? get_pcvar_num(cvar_survinfammo) : get_pcvar_num(cvar_infammo))
	{
		if (amount < MAXBPAMMO[weapon])
		{
			// The BP Ammo refill code causes the engine to send a message, but we
			// can't have that in this forward or we risk getting some recursion bugs.
			// For more info see: https://bugs.alliedmods.net/show_bug.cgi?id=3664
			static args[1]
			args[0] = weapon
			set_task(0.1, "refill_bpammo", id, args, sizeof args)
		}
	}

	else if (g_isbot[id] && amount <= BUYAMMO[weapon])
	{
		// Task needed for the same reason as above
		set_task(0.1, "clcmd_buyammo", id)
	}
}*/

/*================================================================================
 [Main Forwards]
=================================================================================*/

// Entity Spawn Forward
public fw_Spawn(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return FMRES_IGNORED;
	
	// Get classname
	new classname[32], objective[32], size = ArraySize(g_objective_ents)
	pev(entity, pev_classname, classname, charsmax(classname))
	
	// Check whether it needs to be removed
	for (new i = 0; i < size; i++)
	{
		ArrayGetString(g_objective_ents, i, objective, charsmax(objective))
		
		if (equal(classname, objective))
		{
			engfunc(EngFunc_RemoveEntity, entity)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

// Sound Precache Forward
public fw_PrecacheSound(const sound[])
{
	// Block all those unneeeded hostage sounds
	if (equal(sound, "hostage", 7))
		return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
}

// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !zp_get_user_team(id))
		return;
	
	// Player spawned
	g_isalive[id] = true
	
	// Remove previous tasks
	remove_task(id+TASK_SPAWN)
	remove_task(id+TASK_MODEL)
	remove_task(id+TASK_BLOOD)
	remove_task(id+TASK_AURA)
	remove_task(id+TASK_CHARGE)
	remove_task(id+TASK_FLASH)
	remove_task(id+TASK_NVISION)
	
	// Spawn at a random location?
	if (get_pcvar_num(cvar_randspawn)) do_random_spawn(id)
	
	// Respawn player if he dies because of a worldspawn kill?
	if (get_pcvar_num(cvar_respawnworldspawnkill))
		set_task(2.0, "respawn_player_check_task", id+TASK_SPAWN)
	
	// Spawn as zombie?
	if (g_respawn_as_zombie[id] && !g_newround)
	{
		reset_vars(id, 0) // reset player vars
		zombieme(id, 0, g_plagueround, 0, 0) // make him zombie right away
		
		return;
	}
	if(g_plagueround) 
	{
		reset_vars(id, 0);
		humanme(id, 0, 1, 0);

		return;
	}

	// Reset player vars
	reset_vars(id, 0)
	g_buytime[id] = get_gametime()

	new iInfiniteAmmo = g_survivor[id] ? get_pcvar_num(cvar_survinfammo) : get_pcvar_num(cvar_infammo);
	if(iInfiniteAmmo)
		set_member(id, m_iWeaponInfiniteAmmo, iInfiniteAmmo);
	
	// Show custom buy menu?
	if (get_pcvar_num(cvar_buycustom))
	{
		//set_task(0.2, "show_menu_buy1", id+TASK_SPAWN)
	}
	
	// Set health and gravity
	fm_set_user_health(id, get_pcvar_num(cvar_humanhp))
	set_pev(id, pev_gravity, get_pcvar_float(cvar_humangravity))
	
	// Set human maxspeed
	set_player_maxspeed(id);
	
	// Switch to CT if spawning mid-round
	if (!g_newround) // need to change team?
		zp_set_user_team(id, TEAM_CT)
	
	// Custom models stuff
	zp_set_user_human_model(id);
	
	// Bots stuff
	if (g_isbot[id])
	{
		// Turn off NVG for bots
		cs_set_user_nvg(id, 0)
		
		// Automatically buy extra items/weapons after first zombie is chosen
		if (get_pcvar_num(cvar_extraitems))
		{
			if (g_newround) set_task(10.0 + get_pcvar_float(cvar_warmup), "bot_buy_extras", id+TASK_SPAWN)
			else set_task(10.0, "bot_buy_extras", id+TASK_SPAWN)
		}
	}
	
	// Turn off his flashlight (prevents double flashlight bug/exploit)
	turn_off_flashlight(id)
	
	// Set the flashlight charge task to update battery status
	if (g_cached_customflash)
		set_task(1.0, "flashlight_charge", id+TASK_CHARGE, _, _, "b")
	
	// Replace weapon models (bugfix)
	static weapon_ent
	weapon_ent = fm_cs_get_current_weapon_ent(id)
	if (pev_valid(weapon_ent)) replace_weapon_models(id, cs_get_weapon_id(weapon_ent))
	
	// Last Zombie Check
	fnCheckLastZombie()
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Player killed
	g_isalive[victim] = false
	// Disable nodamage mode after we die to prevent spectator nightvision using zombie madness colors bug
	//set_entvar(victim, var_takedamage, DAMAGE_AIM)
	
	// Enable dead players nightvision
	set_task(0.1, "spec_nvision", victim)
	
	// Disable nightvision when killed (bugfix)
	if (get_pcvar_num(cvar_nvggive) == 0 && g_nvision[victim])
	{
		if (get_pcvar_num(cvar_customnvg)) remove_task(victim+TASK_NVISION)
		else if (g_nvisionenabled[victim]) set_user_gnvision(victim, 0)
		g_nvision[victim] = false
		g_nvisionenabled[victim] = false
	}
	
	// Turn off nightvision when killed (bugfix)
	if (get_pcvar_num(cvar_nvggive) == 2 && g_nvision[victim] && g_nvisionenabled[victim])
	{
		if (get_pcvar_num(cvar_customnvg)) remove_task(victim+TASK_NVISION)
		else set_user_gnvision(victim, 0)
		g_nvisionenabled[victim] = false
	}
	
	// Turn off custom flashlight when killed
	if (g_cached_customflash)
	{
		// Turn it off
		g_flashlight[victim] = false
		g_flashbattery[victim] = 100
		
		// Remove previous tasks
		remove_task(victim+TASK_CHARGE)
		remove_task(victim+TASK_FLASH)
	}
	
	// Stop bleeding/burning/aura when killed
	if (g_zombie[victim])
	{
		remove_task(victim+TASK_BLOOD)
		remove_task(victim+TASK_AURA)
		fm_cs_set_user_deaths(victim, cs_get_user_deaths(victim) - 1)
	}
	
	// Determine whether the player killed himself
	static selfkill
	selfkill = (victim == attacker || !is_user_valid_connected(attacker)) ? true : false
	
	// Killed by a non-player entity or self killed
	if(selfkill) return;
	
	// Ignore Nemesis/Survivor Frags?
	if ((g_nemesis[attacker] && get_pcvar_num(cvar_nemignorefrags)) || (g_survivor[attacker] && get_pcvar_num(cvar_survignorefrags)))
		RemoveFrags(attacker, victim)
	
	// Zombie/nemesis killed human, reward ammo packs
	if (g_zombie[attacker] && (!g_nemesis[attacker] || !get_pcvar_num(cvar_nemignoreammo)))
		g_ammopacks[attacker] += get_pcvar_num(cvar_ammoinfect)
	
	// Human killed zombie, add up the extra frags for kill
	if (!g_zombie[attacker] && get_pcvar_num(cvar_fragskill) > 1)
		UpdateFrags(attacker, victim, get_pcvar_num(cvar_fragskill) - 1, 0, 0)
	
	// Zombie killed human, add up the extra frags for kill
	if (g_zombie[attacker] && get_pcvar_num(cvar_fragsinfect) > 1)
		UpdateFrags(attacker, victim, get_pcvar_num(cvar_fragsinfect) - 1, 0, 0)
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Last Zombie Check
	fnCheckLastZombie()
	
	// Determine whether the player killed himself
	static selfkill
	selfkill = (victim == attacker || !is_user_valid_connected(attacker)) ? true : false
	
	if(g_plagueround) 
	{
		g_respawn_as_zombie[victim] = g_zombie[victim];
		set_task(get_pcvar_float(cvar_spawndelay), "respawn_player_task", victim+TASK_SPAWN)
	}

	// Respawn if deathmatch is enabled
	if (get_pcvar_num(cvar_deathmatch))
	{
		// Respawn on suicide?
		if (selfkill && !get_pcvar_num(cvar_respawnonsuicide))
			return;
		
		// Respawn if human/zombie/nemesis/survivor?
		if ((g_zombie[victim] && !g_nemesis[victim] && !get_pcvar_num(cvar_respawnzomb)) || (!g_zombie[victim] && !g_survivor[victim] && !get_pcvar_num(cvar_respawnhum)) || (g_nemesis[victim] && !get_pcvar_num(cvar_respawnnem)) || (g_survivor[victim] && !get_pcvar_num(cvar_respawnsurv)))
			return;
		
		// Set the respawn task
		set_task(get_pcvar_float(cvar_spawndelay), "respawn_player_task", victim+TASK_SPAWN)
	}

}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_valid_connected(attacker))
		return HAM_IGNORED;
	
	// New round starting or round ended
	if (g_newround || g_endround)
		return HAM_SUPERCEDE;
	
	// Prevent friendly fire
	if (g_zombie[attacker] == g_zombie[victim])
		return HAM_SUPERCEDE;
	
	// Attacker is human...
	if (!g_zombie[attacker])
	{
		// Armor multiplier for the final damage on normal zombies
		if (!g_nemesis[victim])
		{
			damage *= get_pcvar_float(cvar_zombiearmor)
			SetHamParamFloat(4, damage)
		}
		
		// Reward ammo packs to humans for damaging zombies?
		if ((get_pcvar_num(cvar_ammodamage_human) > 0) && (!g_survivor[attacker] || !get_pcvar_num(cvar_survignoreammo)))
		{
			// Store damage dealt
			g_damagedealt_human[attacker] += floatround(damage)
			
			// Reward ammo packs for every [ammo damage] dealt
			while (g_damagedealt_human[attacker] > get_pcvar_num(cvar_ammodamage_human))
			{
				g_ammopacks[attacker]++
				g_damagedealt_human[attacker] -= get_pcvar_num(cvar_ammodamage_human)
			}
		}
		
		return HAM_IGNORED;
	}
	
	// Attacker is zombie...
	
	// Prevent infection/damage by HE grenade (bugfix)
	if (damage_type & DMG_HEGRENADE)
		return HAM_SUPERCEDE;
	
	// Nemesis?
	if (g_nemesis[attacker])
	{
		// Ignore nemesis damage override if damage comes from a 3rd party entity
		// (to prevent this from affecting a sub-plugin's rockets e.g.)
		if(inflictor == attacker)
		{
			static Button;
			Button = pev( attacker, pev_button );
			
			if(Button & IN_ATTACK)
			{
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_nemdamage))
			}
			else if(Button & IN_ATTACK2)
			{
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_nemdamage2))
			}
		}
		
		return HAM_IGNORED;
	}
	
	// Reward ammo packs to zombies for damaging humans?
	if (get_pcvar_num(cvar_ammodamage_zombie) > 0)
	{
		// Store damage dealt
		g_damagedealt_zombie[attacker] += floatround(damage)
		
		// Reward ammo packs for every [ammo damage] dealt
		while (g_damagedealt_zombie[attacker] > get_pcvar_num(cvar_ammodamage_zombie))
		{
			g_ammopacks[attacker]++
			g_damagedealt_zombie[attacker] -= get_pcvar_num(cvar_ammodamage_zombie)
		}
	}
	
	// Last human or not an infection round
	if (g_survround || g_nemround || g_swarmround || g_plagueround || fnGetHumans() == 1)
		return HAM_IGNORED; // human is killed
		
	if(g_survivor[victim] || zpe_get_user_chainsaw(victim))
		return HAM_IGNORED; // human is killed
	
	// Does human armor need to be reduced before infecting?
	if (get_pcvar_num(cvar_humanarmor))
	{
		// Get victim armor
		static Float:armor
		pev(victim, pev_armorvalue, armor)
		
		// If he has some, block the infection and reduce armor instead
		if (armor > 0.0)
		{
		
			emit_sound(victim, CHAN_BODY, sound_armorhit, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			if (armor - damage > 0.0)
			{
				set_pev(victim, pev_armorvalue, armor - damage)
			}
			else
			{
				cs_set_user_armor(victim, 0, CS_ARMOR_NONE)
			}
			
			return HAM_SUPERCEDE;
		}
	}
	
	// Infection allowed
	zombieme(victim, attacker, 0, 0, 1) // turn into zombie
	return HAM_SUPERCEDE;
}

// Ham Take Damage Post Forward
public fw_TakeDamage_Post(victim)
{
	// --- Check if victim should be Pain Shock Free ---
	
	// Check if proper CVARs are enabled
	if (g_zombie[victim])
	{
		if (g_nemesis[victim])
		{
			if (!get_pcvar_num(cvar_nempainfree)) return;
		}
		else
		{
			switch (get_pcvar_num(cvar_zombiepainfree))
			{
				case 0: return;
				case 2: if (!g_lastzombie[victim]) return;
				case 3: if (!g_firstzombie[victim]) return;
			}
		}
	}
	else
	{
		if(g_survivor[victim] || zpe_get_user_chainsaw(victim))
		{
			if (!get_pcvar_num(cvar_survpainfree)) return;
		}
		else return;
	}
	
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(victim) != PDATA_SAFE)
		return;
	
	// Set pain shock free offset
	set_pdata_float(victim, OFFSET_PAINSHOCK, 1.0, OFFSET_LINUX)
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_valid_connected(attacker))
		return HAM_IGNORED;
	
	// New round starting or round ended
	if (g_newround || g_endround)
		return HAM_SUPERCEDE;
	
	// Prevent friendly fire
	if (g_zombie[attacker] == g_zombie[victim])
		return HAM_SUPERCEDE;
	
	// Victim isn't a zombie or not bullet damage, nothing else to do here
	if (!g_zombie[victim] || !(damage_type & DMG_BULLET))
		return HAM_IGNORED;
	
	// If zombie hitzones are enabled, check whether we hit an allowed one
	if (get_pcvar_num(cvar_hitzones) && !g_nemesis[victim] && !(get_pcvar_num(cvar_hitzones) & (1<<get_tr2(tracehandle, TR_iHitgroup))))
		return HAM_SUPERCEDE;
		
	return HAM_IGNORED;
}

/*public Ham_Take_Damage_Post(victim, inflicator, attacker, Float:flDamage, bitsDamageType)
{
	if(!is_user_connected(attacker) || victim == attacker)
		return;
	
	if(!g_survround && !g_swarmround && !g_plagueround && !g_nemround)
	{	
		if(g_isalive[victim] && !g_zombie[victim] && !g_survivor[victim] && fnGetHumans() == 1)
		{
			ExecuteHamB(Ham_Killed, victim, attacker, 0);
		}

	}
}*/

// Ham Use Stationary Gun Forward
public fw_UseStationary(entity, caller, activator, use_type)
{
	// Prevent zombies from using stationary guns
	if (use_type == USE_USING && is_user_valid_connected(caller))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Use Pushable Forward
public fw_UsePushable()
{
	// Prevent speed bug with pushables?
	if (get_pcvar_num(cvar_blockpushables))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Weapon Touch Forward
public fw_TouchWeapon(weapon, id)
{
	// Not a player
	if (!is_user_valid_connected(id))
		return HAM_IGNORED;
	
	// Dont pickup weapons if zombie or survivor (+PODBot MM fix)
	if (g_zombie[id] || (g_survivor[id] || g_hero[id] && !g_isbot[id]))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Weapon Pickup Forward
public fw_AddPlayerItem(id, weapon_ent)
{
	// HACK: Retrieve our custom extra ammo from the weapon
	static extra_ammo
	extra_ammo = pev(weapon_ent, PEV_ADDITIONAL_AMMO)
	
	// If present
	if (extra_ammo)
	{
		// Get weapon's id
		static weaponid
		weaponid = cs_get_weapon_id(weapon_ent)
		
		// Add to player's bpammo
		ExecuteHamB(Ham_GiveAmmo, id, extra_ammo, AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
		set_pev(weapon_ent, PEV_ADDITIONAL_AMMO, 0)
	}
}

// Ham Weapon Deploy Forward
public fw_Item_Deploy_Post(weapon_ent)
{
	// Get weapon's owner
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	// Valid owner?
	if (!pev_valid(owner))
		return;
	
	// Get weapon's id
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	// Store current weapon's id for reference
	g_currentweapon[owner] = weaponid
	
	// Replace weapon models with custom ones
	replace_weapon_models(owner, weaponid)
	
	// Zombie not holding an allowed weapon for some reason
	if (g_zombie[owner] && !((1<<weaponid) & ZOMBIE_ALLOWED_WEAPONS_BITSUM))
	{
		// Switch to knife
		g_currentweapon[owner] = CSW_KNIFE
		engclient_cmd(owner, "weapon_knife")
	}
}

// WeaponMod bugfix
//forward wpn_gi_reset_weapon(id);
public wpn_gi_reset_weapon(id)
{
	// Replace knife model
	replace_weapon_models(id, CSW_KNIFE)
}

// Client joins the game
public client_putinserver(id)
{
	// Plugin disabled?
	if (!g_pluginenabled) return;
	
	// Player joined
	g_isconnected[id] = true
	iPlayerAimInfo[id] = true
	
	// Cache player's name
	get_user_name(id, g_playername[id], charsmax(g_playername[]))
	
	// Initialize player vars
	reset_vars(id, 1)
	
	// Load player stats?
	if (get_pcvar_num(cvar_statssave)) load_stats(id)
	
	// Set some tasks for humans only
	if (!is_user_bot(id))
	{
		// Set the custom HUD display task if enabled
		if (get_pcvar_num(cvar_huddisplay))
			set_task(1.0, "ShowHUD", id+TASK_SHOWHUD, _, _, "b")
		
		// Disable minmodels for clients to see zombies properly
		set_task(5.0, "disable_minmodels", id)
	}
	else
	{
		// Set bot flag
		g_isbot[id] = true
		
		// CZ bots seem to use a different "classtype" for player entities
		// (or something like that) which needs to be hooked separately
		if (!g_hamczbots && cvar_botquota)
		{
			// Set a task to let the private data initialize
			set_task(0.1, "register_ham_czbots", id)
		}
	}
}

// Client leaving
public fw_ClientDisconnect(id)
{
	// Check that we still have both humans and zombies to keep the round going
	if (g_isalive[id]) check_round(id)
	
	// Temporarily save player stats?
	if (get_pcvar_num(cvar_statssave)) save_stats(id)
	
	// Remove previous tasks
	remove_task(id+TASK_TEAM)
	remove_task(id+TASK_MODEL)
	remove_task(id+TASK_FLASH)
	remove_task(id+TASK_CHARGE)
	remove_task(id+TASK_SPAWN)
	remove_task(id+TASK_BLOOD)
	remove_task(id+TASK_AURA)
	remove_task(id+TASK_NVISION)
	remove_task(id+TASK_SHOWHUD)
	
	if (g_handle_models_on_separate_ent)
	{
		// Remove custom model entities
		fm_remove_model_ents(id)
	}
	
	// Player left, clear cached flags
	g_isconnected[id] = false
	g_isbot[id] = false
	g_isalive[id] = false
}

// Client left
public fw_ClientDisconnect_Post()
{
	// Last Zombie Check
	fnCheckLastZombie()
}

// Client Kill Forward
public fw_ClientKill()
{
	// Prevent players from killing themselves?
	if (get_pcvar_num(cvar_blocksuicide))
		return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
}

// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Block all those unneeeded hostage sounds
	if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;
	
	// Replace these next sounds for zombies only
	if (!is_user_valid_connected(id) || !g_zombie[id])
		return FMRES_IGNORED;
	
	static sound[64]
	
	// Zombie being hit
	if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
	{
		if (g_nemesis[id])
		{
			ArrayGetString(nemesis_pain, random_num(0, ArraySize(nemesis_pain) - 1), sound, charsmax(sound))
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
		}
		else
		{
			static pointers[10], end
			ArrayGetArray(pointer_class_sound_pain, g_zombieclass[id], pointers)
			
			for (new i; i < 10; i++)
			{
				if (pointers[i] != -1)
				end = i
			}
			ArrayGetString(class_sound_pain, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
		}
		return FMRES_SUPERCEDE;
	}
	
	// Zombie attacks with knife
	if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
		{
			if(g_nemesis[id])
				ArrayGetString(nemesis_miss_slash, random_num(0, ArraySize(nemesis_miss_slash) - 1), sound, charsmax(sound))
			else {
				static pointers[10], end
				ArrayGetArray(pointer_class_sound_miss_slash, g_zombieclass[id], pointers)
	
				for (new i; i < 10; i++)
				{
					if (pointers[i] != -1)
						end = i
				}
				ArrayGetString(class_sound_miss_slash, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
			}
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
		{
			if (sample[17] == 'w') // wall
			{
				if(g_nemesis[id])
					ArrayGetString(nemesis_miss_wall, random_num(0, ArraySize(nemesis_miss_wall) - 1), sound, charsmax(sound))
				else {
					static pointers[10], end
					ArrayGetArray(pointer_class_sound_miss_wall, g_zombieclass[id], pointers)
			
					for (new i; i < 10; i++)
					{
						if (pointers[i] != -1)
							end = i
					}
					ArrayGetString(class_sound_miss_wall, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
				}
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			else
			{
				if(g_nemesis[id])
					ArrayGetString(nemesis_hit_normal, random_num(0, ArraySize(nemesis_hit_normal) - 1), sound, charsmax(sound))
				else {				
					static pointers[10], end
					ArrayGetArray(pointer_class_sound_hit_normal, g_zombieclass[id], pointers)
			
					for (new i; i < 10; i++)
					{
						if (pointers[i] != -1)
							end = i
					}
					ArrayGetString(class_sound_hit_normal, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
				}
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
		{
			if(g_nemesis[id])
				ArrayGetString(nemesis_hit_stab, random_num(0, ArraySize(nemesis_hit_stab) - 1), sound, charsmax(sound))
			else {	
				static pointers[10], end
				ArrayGetArray(pointer_class_sound_hit_stab, g_zombieclass[id], pointers)
			
				for (new i; i < 10; i++)
				{
					if (pointers[i] != -1)
						end = i
				}
				ArrayGetString(class_sound_hit_stab, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
			}
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}
	
	// Zombie dies
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		if(g_nemesis[id])
			ArrayGetString(nemesis_die, random_num(0, ArraySize(nemesis_die) - 1), sound, charsmax(sound))
		else {	
			static pointers[10], end
			ArrayGetArray(pointer_class_sound_die, g_zombieclass[id], pointers)
			
			for (new i; i < 10; i++)
			{
				if (pointers[i] != -1)
					end = i
			}
			ArrayGetString(class_sound_die, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
		}
		emit_sound(id, channel, sound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}

	// Zombie falls off
	if (sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l')
	{
		if(g_nemesis[id])
			ArrayGetString(nemesis_fall, random_num(0, ArraySize(nemesis_fall) - 1), sound, charsmax(sound))
		else {
			static pointers[10], end
			ArrayGetArray(pointer_class_sound_fall, g_zombieclass[id], pointers)
			
			for (new i; i < 10; i++)
			{
				if (pointers[i] != -1)
				end = i
			}
			ArrayGetString(class_sound_fall, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
		}
		emit_sound(id, channel, sound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

// Forward Client User Info Changed -prevent players from changing models-
public RG_SetClientUserInfoModel_Pre(const id, infobuffer[], new_model[])
{
	SetHookChainArg(3, ATYPE_STRING, g_playermodel[id]);
}

// Forward Set ClientKey Value -prevent CS from changing player models-
/*public fw_SetClientKeyValue(id, const infobuffer[], const key[])
{
	// Block CS model changes
	if (key[0] == 'm' && key[1] == 'o' && key[2] == 'd' && key[3] == 'e' && key[4] == 'l')
		return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
}

// Forward Client User Info Changed -prevent players from changing models-
public fw_ClientUserInfoChanged(id)
{
	// Cache player's name
	get_user_name(id, g_playername[id], charsmax(g_playername[]))
	
	if (!g_handle_models_on_separate_ent)
	{
		// Get current model
		static currentmodel[32]
		fm_cs_get_user_model(id, currentmodel, charsmax(currentmodel))
		
		// If they're different, set model again
		if (!equal(currentmodel, g_playermodel[id]) && !task_exists(id+TASK_MODEL))
			fm_cs_set_user_model(id+TASK_MODEL)
	}
}
*/

// Forward Get Game Description
public fw_GetGameDescription()
{
	// Return the mod name so it can be easily identified
	forward_return(FMV_STRING, g_modname)
	
	return FMRES_SUPERCEDE;
}

// Forward CmdStart
public fw_CmdStart(id, handle)
{
	// Not alive
	if (!g_isalive[id])
		return;
	
	// This logic looks kinda weird, but it should work in theory...
	// p = g_zombie[id], q = g_survivor[id], r = g_cached_customflash
	// ¬(p v q v (¬p ^ r)) <==> ¬p ^ ¬q ^ (p v ¬r)
	if (!g_zombie[id] && !g_survivor[id] && (g_zombie[id] || !g_cached_customflash))
		return;
	
	// Check if it's a flashlight impulse
	if (get_uc(handle, UC_Impulse) != IMPULSE_FLASHLIGHT)
		return;
	
	// Block it I say!
	set_uc(handle, UC_Impulse, 0)
	
	// Should human's custom flashlight be turned on?
	if (!g_zombie[id] && !g_survivor[id] && g_flashbattery[id] > 2 && get_gametime() - g_lastflashtime[id] > 1.2)
	{
		// Prevent calling flashlight too quickly (bugfix)
		g_lastflashtime[id] = get_gametime()
		
		// Toggle custom flashlight
		g_flashlight[id] = !(g_flashlight[id])
		
		// Play flashlight toggle sound
		emit_sound(id, CHAN_ITEM, sound_flashlight, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		// Update flashlight status on the HUD
		message_begin(MSG_ONE, g_msgFlashlight, _, id)
		write_byte(g_flashlight[id]) // toggle
		write_byte(g_flashbattery[id]) // battery
		message_end()
		
		// Remove previous tasks
		remove_task(id+TASK_CHARGE)
		remove_task(id+TASK_FLASH)
		
		// Set the flashlight charge task
		set_task(1.0, "flashlight_charge", id+TASK_CHARGE, _, _, "b")
		
		// Call our custom flashlight task if enabled
		if (g_flashlight[id]) set_task(0.1, "set_user_flashlight", id+TASK_FLASH, _, _, "b")
	}
}

// Forward Player PreThink
public fw_PlayerPreThink(id)
{
	// Not alive
	if (!g_isalive[id])
		return;
	
	//new Float:vecVelocity[3]; get_entvar(id, var_velocity, vecVelocity);
	//client_print(id, print_chat, "Velocity len = %f", xs_vec_len(vecVelocity))

	if(g_isbot[id])
		return;
	
	// Enable custom buyzone for player during buytime, unless zombie or survivor or time expired
	if (g_cached_buytime > 0.0 && !g_zombie[id] && !g_survivor[id] && (get_gametime() < g_buytime[id] + g_cached_buytime))
	{
		if (pev_valid(g_buyzone_ent))
			dllfunc(DLLFunc_Touch, g_buyzone_ent, id)
	}
	
	// Silent footsteps for zombies?
	if (g_cached_zombiesilent && g_zombie[id] && !g_nemesis[id])
		set_pev(id, pev_flTimeStepSound, STEPTIME_SILENT)
	
	// --- Check if player should leap ---
	
	// Don't allow leap during freezetime
	if (g_freezetime)
		return;
	
	// Check if proper CVARs are enabled and retrieve leap settings
	static Float:cooldown, Float:current_time
	if (g_zombie[id])
	{
		if (g_nemesis[id])
		{
			if (!g_cached_leapnemesis) return;
			cooldown = g_cached_leapnemesiscooldown
		}
		else
		{
			switch (g_cached_leapzombies)
			{
				case 0: return;
				case 2: if (!g_firstzombie[id]) return;
				case 3: if (!g_lastzombie[id]) return;
			}
			cooldown = g_cached_leapzombiescooldown
		}
	}
	else
	{
		if (g_survivor[id])
		{
			if (!g_cached_leapsurvivor) return;
			cooldown = g_cached_leapsurvivorcooldown
		}
		else return;
	}
	
	current_time = get_gametime()
	
	// Cooldown not over yet
	if (current_time - g_lastleaptime[id] < cooldown)
		return;
	
	// Not doing a longjump (don't perform check for bots, they leap automatically)
	if(g_isbot[id])
		return;
		
	if (!g_isbot[id] && !(pev(id, pev_button) & (IN_JUMP | IN_DUCK) == (IN_JUMP | IN_DUCK)))
		return;
	
	// Not on ground or not enough speed
	if (!(pev(id, pev_flags) & FL_ONGROUND) || fm_get_speed(id) < 80)
		return;
	
	static Float:velocity[3]
	
	// Make velocity vector
	velocity_by_aim(id, g_survivor[id] ? get_pcvar_num(cvar_leapsurvivorforce) : g_nemesis[id] ? get_pcvar_num(cvar_leapnemesisforce) : get_pcvar_num(cvar_leapzombiesforce), velocity)
	
	// Set custom height
	velocity[2] = g_survivor[id] ? get_pcvar_float(cvar_leapsurvivorheight) : g_nemesis[id] ? get_pcvar_float(cvar_leapnemesisheight) : get_pcvar_float(cvar_leapzombiesheight)
	
	// Apply the new velocity
	set_pev(id, pev_velocity, velocity)
	
	// Update last leap time
	g_lastleaptime[id] = current_time
}

/*================================================================================
 [Client Commands]
=================================================================================*/

public clcmd_adminmenu(id)
{
	if(get_user_flags(id) & ADMIN_BAN)
		show_menu_admin_players(id);
}

// Say "/zpmenu"
public clcmd_saymenu(id)
{
	show_menu_game(id) // show game menu
}

// Nightvision toggle
public clcmd_nightvision(id)
{
	// Nightvision available to player?
	if (g_nvision[id] || (g_isalive[id] && cs_get_user_nvg(id)))
	{
		// Enable-disable
		g_nvisionenabled[id] = !(g_nvisionenabled[id])
		
		// Custom nvg?
		if (get_pcvar_num(cvar_customnvg))
		{
			remove_task(id+TASK_NVISION)
			if (g_nvisionenabled[id]) set_task(0.1, "set_user_nvision", id+TASK_NVISION, _, _, "b")
		}
		else
			set_user_gnvision(id, g_nvisionenabled[id])
	}
	
	return PLUGIN_CONTINUE;
}

// Weapon Drop
public clcmd_drop(id)
{
	// Survivor should stick with its weapon
	if (g_survivor[id] || g_hero[id])
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

// Buy BP Ammo
public clcmd_buyammo1()
	return PLUGIN_HANDLED

public clcmd_buyammo2()
	return PLUGIN_HANDLED

// Block Team Change
public clcmd_changeteam(id)
{
	static TeamName:team
	team = zp_get_user_team(id)
	
	// Unless it's a spectator joining the game
	if (team == TEAM_UNASSIGNED)
		return PLUGIN_CONTINUE;
	
	// Pressing 'M' (chooseteam) ingame should show the main menu instead
	show_menu_game(id)
	return PLUGIN_HANDLED;
}

/*================================================================================
 [Menus]
=================================================================================*/

// Game Menu
show_menu_game(id)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return;
	
	new menu[512], len = 0, userflags = get_user_flags(id);

	// Title
	len += formatex(menu[len], charsmax(menu) - len, "%L^n^n", id, "SERVER_MENU_TITLE_1")
	
	// 1. Zombie Classes
	len += formatex(menu[len], charsmax(menu) - len, "\r1. \w%L^n", id, "MENU_CHIEF_ZM_CLASS")
		
	// 2. Unstuck
	if (g_isalive[id])
		len += formatex(menu[len], charsmax(menu) - len, "\r2. \w%L^n^n", id, "MENU_CHIEF_UNSTUCK")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d2. %L^n^n", id, "MENU_CHIEF_UNSTUCK")
	
	// 3. Contacts
	len += formatex(menu[len], charsmax(menu) - len, "\r3. \w%L^n", id, "MENU_CONTACTS_CHIEF_TITLE")
	
	// 4. Rules
	len += formatex(menu[len], charsmax(menu) - len, "\r4. \w%L^n^n", id, "MENU_CHIEF_RULES")

	// 5. Настройки
	len += formatex(menu[len], charsmax(menu) - len, "\r5. \w%L^n", id, "MENU_CHIEF_OPTIONS")

	// 6. Меню привилегий
	len += formatex(menu[len], charsmax(menu) - len, "\r6. \wМеню привилегий^n")

	// 7. Квесты [NEW]
	len += formatex(menu[len], charsmax(menu) - len, "\r7. \wКвесты \r[NEW]^n^n")
	
	// 7. Вход в игру
	new TeamName:tTeam = get_member(id, m_iTeam);
	if(tTeam == TEAM_UNASSIGNED || tTeam == TEAM_SPECTATOR)
		len += formatex(menu[len], charsmax(menu) - len, "\r8. \wВойти в игру^n^n")

	// 9. Admin menu
	if (userflags & ADMIN_BAN)
		len += formatex(menu[len], charsmax(menu) - len, "\r9. \w%L^n^n", id, "MENU_CHIEF_ADMIN")

	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "\r0. \w%L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, KEYSMENU, menu, -1, "Game Menu")
}

show_options_menu(id)
{
	new szMenu[512], szSkinName[32], iLen = formatex(szMenu, charsmax(szMenu), "\w%L^n^n", id, "MENU_OPTIONS_TITLE");

	zp_get_user_human_skin_name(id, szSkinName, charsmax(szSkinName));

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \w%L \d[\y%s\d]^n", id, "MENU_OPTIONS_SKIN", szSkinName);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \wМут меню \r(/mute)^n", id, "MENU_OPTIONS_SKIN", szSkinName);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \wМеню дамагера \r(/damager)^n", id, "MENU_OPTIONS_SKIN", szSkinName);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \wТОП15 \r(/top15)^n", id, "MENU_OPTIONS_SKIN", szSkinName);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5. \wВаша статистика \r(/rank)^n", id, "MENU_OPTIONS_SKIN", szSkinName);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6. \wСменить карту \r(/rtv)^n", id, "MENU_OPTIONS_SKIN", szSkinName);

	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r0. \w%L", id, "MENU_EXIT");

	return show_menu(id, KEYSMENU, szMenu, -1, "show_options_menu")
}

public handle_options_menu(id, iKey)
{
	switch(iKey)
	{
		case 0: client_cmd(id, "zpe_human_skins");
		case 1: client_cmd(id, "say /mute");
		case 2: client_cmd(id, "say /damager");
		case 3: client_cmd(id, "say /top15");
		case 4: client_cmd(id, "say /rank");
		case 5: client_cmd(id, "say /rtv");
	}
	
	return PLUGIN_HANDLED;
}

public show_privilegies_menu(id)
{
	new szMenu[512], szSkinName[32], iLen = formatex(szMenu, charsmax(szMenu), "\wМеню привилегий^n^n");

	zp_get_user_human_skin_name(id, szSkinName, charsmax(szSkinName));

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \wVIP-меню^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \wPREMIUM-меню^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \wAGENT-меню^n^n^n^n^n^n^n");

	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \w%L", id, "MENU_EXIT");

	return show_menu(id, KEYSMENU, szMenu, -1, "show_privilegies_menu")
}

public handle_privilegies_menu(id, iKey)
{
	switch(iKey)
	{
		case 0: client_cmd(id, "vipmenu");
		case 1: client_cmd(id, "premiummenu");
		case 2: client_cmd(id, "agentmenu");
		case 9: {}

		default: return show_privilegies_menu(id);
	}
	return PLUGIN_HANDLED;
}

// Buy Menu 1
public show_menu_buy1(taskid)
{
	// Get player's id
	static id
	(taskid > g_maxplayers) ? (id = ID_SPAWN) : (id = taskid);
	
	// Player dead?
	if (!g_isalive[id])
		return;
	
	// Zombies or survivors get no guns
	if (g_zombie[id] || g_survivor[id])
		return;
	
	// Bots pick their weapons randomly / Random weapons setting enabled
	if (get_pcvar_num(cvar_randweapons) || g_isbot[id])
	{
		buy_primary_weapon(id, random_num(0, ArraySize(g_primary_items) - 1))
		menu_buy2(id, random_num(0, ArraySize(g_secondary_items) - 1))
		return;
	}
	
	// Automatic selection enabled for player and menu called on spawn event
	if (WPN_AUTO_ON && taskid > g_maxplayers)
	{
		buy_primary_weapon(id, WPN_AUTO_PRI)
		menu_buy2(id, WPN_AUTO_SEC)
		return;
	}
	
	static menu[300], len, weap, maxloops
	len = 0
	maxloops = min(WPN_STARTID+7, WPN_MAXIDS)
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y%L \r[%d-%d]^n^n", id, "MENU_BUY1_TITLE", WPN_STARTID+1, min(WPN_STARTID+7, WPN_MAXIDS))
	
	// 1-7. Weapon List
	for (weap = WPN_STARTID; weap < maxloops; weap++)
		len += formatex(menu[len], charsmax(menu) - len, "\r%d.\w %s^n", weap-WPN_STARTID+1, WEAPONNAMES[ArrayGetCell(g_primary_weaponids, weap)])
	
	// 8. Auto Select
	// len += formatex(menu[len], charsmax(menu) - len, "^n\r8.\w %L \y[%L]", id, "MENU_AUTOSELECT", id, (WPN_AUTO_ON) ? "MENU_AUTOSELECT_ON" : "MENU_AUTOSELECT_OFF")
	
	// 9. Next/Back - 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, KEYSMENU, menu, -1, "Buy Menu 1")
}

// Buy Menu 2
show_menu_buy2(id)
{
	// Player dead?
	if (!g_isalive[id])
		return;
	
	static menu[250], len, weap, maxloops
	len = 0
	maxloops = ArraySize(g_secondary_items)
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y%L^n", id, "MENU_BUY2_TITLE")
	
	// 1-6. Weapon List
	for (weap = 0; weap < maxloops; weap++)
		len += formatex(menu[len], charsmax(menu) - len, "^n\r%d.\w %s", weap+1, WEAPONNAMES[ArrayGetCell(g_secondary_weaponids, weap)])
	
	// 8. Auto Select
	// len += formatex(menu[len], charsmax(menu) - len, "^n^n\r8.\w %L \y[%L]", id, "MENU_AUTOSELECT", id, (WPN_AUTO_ON) ? "MENU_AUTOSELECT_ON" : "MENU_AUTOSELECT_ON")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0.\w %L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, KEYSMENU, menu, -1, "Buy Menu 2")
}

// CONTACTS MENU
show_menu_contacts_chief(id)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return;
		
	new menu[512], len, iKeys = 1023;
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\w%L^n^n", id, "MENU_CONTACTS_CHIEF_TITLE")
		
	// 1. BOOST INFO
	len += formatex(menu[len], charsmax(menu) - len, "\r1. \w%L^n", id, "MENU_CONTACTS_CHIEF_BOOST")
	
	// 2. VIP INFO
	len += formatex(menu[len], charsmax(menu) - len, "\r2. \w%L^n", id, "MENU_CONTACTS_CHIEF_VIP")
	
	// 3. PREMIUM INFO
	len += formatex(menu[len], charsmax(menu) - len, "\r3. \w%L^n", id, "MENU_CONTACTS_CHIEF_PREMIUM")

	// 4. AGENT INFO
	len += formatex(menu[len], charsmax(menu) - len, "\r4. \w%L^n^n^n^n", id, "MENU_CONTACTS_CHIEF_AGENT")
	
	
	// 8. FREE VIP
	len += formatex(menu[len], charsmax(menu) - len, "\r8. \w%L^n", id, "MENU_FREEVIP_TITLE")
	
	// 9. CONTACTS INFO
	len += formatex(menu[len], charsmax(menu) - len, "\r9. \w%L^n", id, "MENU_CONTACTS_CHIEF_INFO")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n\r0. \w%L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, iKeys, menu, -1, "CONTACTSCHIEF")
}

show_menu_vipinfo(id)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return;
		
	new menu[512], len, iKeys = 1023;
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\w%L^n^n", id, "MENU_VIPINFO_TITLE")
		
	// 1. VIP INFO 1
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_VIPINFO_1")
	
	// 2. VIP INFO 2
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_VIPINFO_2")
	
	// 3. VIP INFO 3
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_VIPINFO_3")
		
	// 4. VIP INFO 4
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_VIPINFO_4")	
	
	// 5. VIP INFO 5
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_VIPINFO_5")
	
	// 6. VIP INFO 6
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_VIPINFO_6")
	
	// 7. VIP INFO 7
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n^n", id, "MENU_VIPINFO_7")
	
	// 8. VIP INFO 8
	len += formatex(menu[len], charsmax(menu) - len, "\r>> \w%L", id, "MENU_VIPINFO_8")
	
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0. \w%L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, iKeys, menu, -1, "VIPINFO")
}

show_menu_preminfo(id)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return;
		
	new menu[512], len, iKeys = 1023;
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\w%L^n^n", id, "MENU_PREMINFO_TITLE")
		
	// 1. PREMIUM INFO 1
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_PREMINFO_1")
	
	// 2. PREMIUM INFO 2
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_PREMINFO_2")
	
	// 3. PREMIUM INFO 3
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_PREMINFO_3")
		
	// 4. PREMIUM INFO 4
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_PREMINFO_4")
	
	// 5. PREMIUM INFO 5
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_PREMINFO_5")
	
	// 6. PREMIUM INFO 5
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n^n", id, "MENU_PREMINFO_6")
	
	// 7. PREMIUM INFO 6
	len += formatex(menu[len], charsmax(menu) - len, "\r>> \w%L", id, "MENU_PREMINFO_7")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0. \w%L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, iKeys, menu, -1, "PREMINFO")
}

show_menu_agentinfo(id)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return;
		
	new menu[512], len, iKeys = 1023;
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\w%L^n^n", id, "MENU_AGENTINFO_TITLE")
		
	// 1. BOOST INFO 1
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_AGENTINFO_1")
	
	// 2. BOOST INFO 2
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_AGENTINFO_2")
	
	// 3. BOOST INFO 3
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_AGENTINFO_3")
		
	// 4. BOOST INFO 4
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_AGENTINFO_4")
	
	// 5. BOOST INFO 5
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_AGENTINFO_5")
	
	// 6. BOOST INFO 6
	len += formatex(menu[len], charsmax(menu) - len, "\r>> \w%L", id, "MENU_AGENTINFO_6")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0. \w%L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, iKeys, menu, -1, "AGENTINFO")
}

show_menu_boostinfo(id)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return;
		
	new menu[512], len, iKeys = 1023;
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\w%L^n^n", id, "MENU_BOOSTINFO_TITLE")
		
	// 1. BOOST INFO 1
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_BOOSTINFO_1")
	
	// 2. BOOST INFO 2
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_BOOSTINFO_2")
	
	// 3. BOOST INFO 3
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_BOOSTINFO_3")
		
	// 4. BOOST INFO 4
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n^n", id, "MENU_BOOSTINFO_4")
	
	// 5. BOOST INFO 5
	len += formatex(menu[len], charsmax(menu) - len, "\r>> \w%L^n", id, "MENU_BOOSTINFO_5")
	
	// 6. BOOST INFO 6
	len += formatex(menu[len], charsmax(menu) - len, "\r>> \w%L", id, "MENU_BOOSTINFO_6")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0. \w%L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, iKeys, menu, -1, "BOOSTINFO")
}

show_menu_contacts(id)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return;
		
	new menu[512], len, iKeys = 1023;
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\w%L^n^n", id, "MENU_CONTACTS_TITLE")
		
	// 1. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_CONTACTS_1")
	
	// 2. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n^n", id, "MENU_CONTACTS_2")
	
	// 3. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r• \w%L^n", id, "MENU_CONTACTS_3")
	
	// 4. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r>> %L", id, "MENU_CONTACTS_4")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n^n\r0. \w%L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, iKeys, menu, -1, "CONTACTSINFO")
}

show_menu_freevip(id)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return;
		
	new menu[512], len, iKeys = 1023;
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\w%L^n^n", id, "MENU_FREEVIP_TITLE")
		
	// Info
	len += formatex(menu[len], charsmax(menu) - len, "%L", id, "MENU_FREEVIP_INFO")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n\r0. \w%L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, iKeys, menu, -1, "FREEVIP")
}

// Extra Items Menu
/*show_menu_extras(id)
{
	// Player dead?
	if (!g_isalive[id])
		return;
	
	static menuid, menu[128], item, team, buffer[32]
	
	// Title
	formatex(menu, charsmax(menu), "%L [%L]\r", id, "MENU_EXTRA_TITLE", id, g_zombie[id] ? g_nemesis[id] ? "CLASS_NEMESIS" : "CLASS_ZOMBIE" : g_survivor[id] ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
	menuid = menu_create(menu, "menu_extras")
	
	// Item List
	for (item = 0; item < g_extraitem_i; item++)
	{
		// Retrieve item's team
		team = ArrayGetCell(g_extraitem_team, item)
		
		// Item not available to player's team/class
		if ((g_zombie[id] && !g_nemesis[id] && !(team & ZP_TEAM_ZOMBIE)) || (!g_zombie[id] && !g_survivor[id] && !(team & ZP_TEAM_HUMAN)) || (g_nemesis[id] && !(team & ZP_TEAM_NEMESIS)) || (g_survivor[id] && !(team & ZP_TEAM_SURVIVOR)))
			continue;
		
		// Check if it's one of the hardcoded items, check availability, set translated caption
		switch (item)
		{
			case EXTRA_NVISION:
			{
				if (!get_pcvar_num(cvar_extranvision)) continue;
				formatex(buffer, charsmax(buffer), "%L", id, "MENU_EXTRA1")
			}
			case EXTRA_ANTIDOTE:
			{
				if (!get_pcvar_num(cvar_extraantidote) || g_antidotecounter >= get_pcvar_num(cvar_antidotelimit)) continue;
				formatex(buffer, charsmax(buffer), "%L", id, "MENU_EXTRA2")
			}
			case EXTRA_MADNESS:
			{
				if (!get_pcvar_num(cvar_extramadness) || g_madnesscounter >= get_pcvar_num(cvar_madnesslimit)) continue;
				formatex(buffer, charsmax(buffer), "%L", id, "MENU_EXTRA3")
			}
			default:
			{
				if (item >= EXTRA_WEAPONS_STARTID && item <= EXTRAS_CUSTOM_STARTID-1 && !get_pcvar_num(cvar_extraweapons)) continue;
				ArrayGetString(g_extraitem_name, item, buffer, charsmax(buffer))
			}
		}
		
		// Add Item Name and Cost
		formatex(menu, charsmax(menu), "%s \y%d %L", buffer, ArrayGetCell(g_extraitem_cost, item), id, "AMMO_PACKS2")
		buffer[0] = item
		buffer[1] = 0
		menu_additem(menuid, menu, buffer)
	}
	
	// No items to display?
	if (menu_items(menuid) <= 0)
	{
		zp_colored_print(id, "^x04[ZP]^x01 %L", id ,"CMD_NOT_EXTRAS")
		menu_destroy(menuid)
		return;
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%L", id, "MENU_BACK")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
		
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_EXTRAS = min(MENU_PAGE_EXTRAS, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	menu_display(id, menuid, MENU_PAGE_EXTRAS)
}*/

// Zombie Class Menu

public CMD_ClassMenu(id) return Show_ClassMenu(id, g_iMenuPosition[id] = 0);
public Show_ClassMenu(id, iPos)
{
	// Player disconnected
	if (!g_isconnected[id])
		return PLUGIN_HANDLED;

	// Bots pick their zombie class randomly
	if (g_isbot[id])
	{
		g_zombieclassnext[id] = random_num(0, g_zclass_i - 1)
		return PLUGIN_HANDLED;
	}

	if(iPos < 0) return PLUGIN_HANDLED;

	new iStringsCount = g_zclass_i;

	if(!iStringsCount)
	{
	    client_print_color(id, id, "^4[ZP] ^1Классы отсутствуют");
	    return PLUGIN_HANDLED;
	}

	new iPagesNum = (iStringsCount / PLAYERS_PER_PAGE + ((iStringsCount % PLAYERS_PER_PAGE) ? 1 : 0));

	if(iPos >= iPagesNum)
	    return Show_ClassMenu(id, iPagesNum - 1);

	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iStringsCount) iStart = iStringsCount;
	iStart = iStart - (iStart % PLAYERS_PER_PAGE);
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iStringsCount) iEnd = iStringsCount;


	new szMenu[512], 
	    iLen = formatex(szMenu, charsmax(szMenu), "\y%L \w[%d|%d]^n^n", id, "MENU_ZCLASS_TITLE", iPos + 1, iPagesNum);

	new iKeys = (1<<9), b, buffer[256], buffer2[256]

	// Class List
	for(new a = iStart; a < iEnd; a++)
	{
		// Retrieve name and info
		ArrayGetString(g_zclass_name, a, buffer, charsmax(buffer))
		ArrayGetString(g_zclass_info, a, buffer2, charsmax(buffer2))
		
		if(contain(buffer, "ML_") != -1)
			format(buffer, charsmax(buffer), "%L", id, buffer[3])

		if(contain(buffer2, "ML_") != -1)
			format(buffer2, charsmax(buffer2), "%L", id, buffer2[3])
		
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r%d. %s%s \y%s^n", ++b, a == g_zombieclassnext[id] ? "\d" : "\w", buffer, buffer2);
	}

	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n")

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	
	if(iPos > 0)
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r8. \wНазад^n");
		iKeys |= (1<<7);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r8. \dНазад^n")

	if(iPos < iPagesNum - 1)
	{
	    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9. \wДалее^n")
	    iKeys |= (1<<8)
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9. \dДалее^n")


	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wВыход")

	return show_menu(id, iKeys, szMenu, -1, "Show_ClassMenu")
}

// Admin Mod Menu
show_menu_mod_admin(id)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return;
	
	static menu[250], len, userflags
	len = 0
	userflags = get_user_flags(id)
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y%L^n^n", id, "MENU_MOD_ADMIN_TITLE")
	
	// 1. Zombiefy/Humanize command
	if (userflags & (g_access_flag[ACCESS_MODE_INFECTION] | g_access_flag[ACCESS_MAKE_ZOMBIE] | g_access_flag[ACCESS_MAKE_HUMAN]))
		len += formatex(menu[len], charsmax(menu) - len, "\r1.\w %L^n", id, "MENU_MOD_ADMIN_1")
	else if(zp_get_autorr())
		len += formatex(menu[len], charsmax(menu) - len, "\d1. %L^n", id, "MENU_MOD_ADMIN_1")
	else if(zp_check_vote())
		len += formatex(menu[len], charsmax(menu) - len, "\d1. %L^n", id, "MENU_MOD_ADMIN_1")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d1. %L^n", id, "MENU_MOD_ADMIN_1")
	
	// 2. Nemesis command
	if (userflags & (g_access_flag[ACCESS_MODE_NEMESIS] | g_access_flag[ACCESS_MAKE_NEMESIS]))
		len += formatex(menu[len], charsmax(menu) - len, "\r2.\w %L^n", id, "MENU_MOD_ADMIN_2")
	else if(zp_get_autorr())
		len += formatex(menu[len], charsmax(menu) - len, "\d2. %L^n", id, "MENU_MOD_ADMIN_2")
	else if(zp_check_vote())
		len += formatex(menu[len], charsmax(menu) - len, "\d2. %L^n", id, "MENU_MOD_ADMIN_2")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d2. %L^n", id, "MENU_MOD_ADMIN_2")
	
	// 3. Survivor command
	if (userflags & (g_access_flag[ACCESS_MODE_SURVIVOR] | g_access_flag[ACCESS_MAKE_SURVIVOR]))
		len += formatex(menu[len], charsmax(menu) - len, "\r3.\w %L^n", id, "MENU_MOD_ADMIN_3")
	else if(zp_get_autorr())
		len += formatex(menu[len], charsmax(menu) - len, "\d3. %L^n", id, "MENU_MOD_ADMIN_3")
	else if(zp_check_vote())
		len += formatex(menu[len], charsmax(menu) - len, "\d3. %L^n", id, "MENU_MOD_ADMIN_3")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d3. %L^n", id, "MENU_MOD_ADMIN_3")
	
	// 4. Respawn command
	if (userflags & g_access_flag[ACCESS_RESPAWN_PLAYERS])
		len += formatex(menu[len], charsmax(menu) - len, "\r4.\w %L^n", id, "MENU_MOD_ADMIN_4")
	else if(zp_get_autorr())
		len += formatex(menu[len], charsmax(menu) - len, "\d4. %L^n", id, "MENU_MOD_ADMIN_4")
	else if(zp_check_vote())
		len += formatex(menu[len], charsmax(menu) - len, "\d4. %L^n", id, "MENU_MOD_ADMIN_4")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d4. %L^n", id, "MENU_MOD_ADMIN_4")
	
	// 5. Swarm mode command
	if ((userflags & g_access_flag[ACCESS_MODE_SWARM]) && allowed_swarm())
		len += formatex(menu[len], charsmax(menu) - len, "\r5.\w %L^n", id, "MENU_MOD_ADMIN_5")
	else if(zp_get_autorr())
		len += formatex(menu[len], charsmax(menu) - len, "\d5. %L^n", id, "MENU_MOD_ADMIN_5")
	else if(zp_check_vote())
		len += formatex(menu[len], charsmax(menu) - len, "\d5. %L^n", id, "MENU_MOD_ADMIN_5")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d5. %L^n", id, "MENU_MOD_ADMIN_5")
	
	// 6. Multi infection command
	if ((userflags & g_access_flag[ACCESS_MODE_MULTI]) && allowed_multi())
		len += formatex(menu[len], charsmax(menu) - len, "\r6.\w %L^n", id, "MENU_MOD_ADMIN_6")
	else if(zp_get_autorr())
		len += formatex(menu[len], charsmax(menu) - len, "\d6. %L^n", id, "MENU_MOD_ADMIN_6")
	else if(zp_check_vote())
		len += formatex(menu[len], charsmax(menu) - len, "\d6. %L^n", id, "MENU_MOD_ADMIN_6")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d6. %L^n", id, "MENU_MOD_ADMIN_6")
	
	// 7. Plague mode command
	if ((userflags & g_access_flag[ACCESS_MODE_PLAGUE]) && allowed_plague())
		len += formatex(menu[len], charsmax(menu) - len, "\r7.\w %L^n", id, "MENU_MOD_ADMIN_7")
	else if(zp_get_autorr())
		len += formatex(menu[len], charsmax(menu) - len, "\d7. %L^n", id, "MENU_MOD_ADMIN_7")
	else if(zp_check_vote())
		len += formatex(menu[len], charsmax(menu) - len, "\d7. %L^n", id, "MENU_MOD_ADMIN_7")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d7. %L^n", id, "MENU_MOD_ADMIN_7")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n\r0.\w %L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, KEYSMENU, menu, -1, "Admin Mod Menu")
}

// Admin Menu
show_menu_admin(id)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return;
		
	new menu[512], len, userflags, iKeys = (1<<0|1<<1|1<<2|1<<3|1<<9);
	userflags = get_user_flags(id)
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\w%L^n^n", id, "MENU_ADMIN_TITLE")
		
	// 1. Point
	if(zp_get_autorr())
		len += formatex(menu[len], charsmax(menu) - len, "\d1. %L^n", id, "MENU_MOD_ADMIN_TITLE")
	else if(zp_check_vote())
		len += formatex(menu[len], charsmax(menu) - len, "\d1. %L^n", id, "MENU_MOD_ADMIN_TITLE")
	else if(userflags & g_access_flag[ACCESS_ADMIN_MENU])
		len += formatex(menu[len], charsmax(menu) - len, "\r1. \w%L^n", id, "MENU_MOD_ADMIN_TITLE")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d1. %L^n", id, "MENU_MOD_ADMIN_TITLE")
	
	// 2. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r2. \w%L^n", id, "MENU_PL_ADMIN_TITLE")

	// 3. Point
	if(userflags & g_access_flag[ACCESS_ADMIN_MENU])
		len += formatex(menu[len], charsmax(menu) - len, "\r3. \w%L", id, "MENU_PR_ADMIN_TITLE")
	else
		len += formatex(menu[len], charsmax(menu) - len, "\d3. %L", id, "MENU_PR_ADMIN_TITLE")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n^n\r0. \w%L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, iKeys, menu, -1, "ADMININFO")
}

// Admin Players Menu
show_menu_admin_players(id)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return;
		
	new menu[512], len, iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<9);
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\w%L^n^n", id, "MENU_PL_ADMIN_TITLE")
		
	// 1. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r1. \w%L^n", id, "MENU_PL_ADMIN_1")
	
	// 2. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r2. \w%L^n", id, "MENU_PL_ADMIN_2")

	// 3. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r3. \wОффлайн бан^n")

	// 4. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r4. \wБлок микрофона/чата^n")
	
	// 5. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r5. \w%L^n", id, "MENU_PL_ADMIN_3")
	
	// 6. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r6. \wКоманда игрока^n")
	
	// 7. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r7. \w%L^n", id, "MENU_PL_ADMIN_4")
	
	// 8. Point
	len += formatex(menu[len], charsmax(menu) - len, "\r8. \w%L", id, "MENU_PL_ADMIN_5")
	
	// 0. Exit
	len += formatex(menu[len], charsmax(menu) - len, "^n^n^n\r0. \w%L", id, "MENU_EXIT")
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	show_menu(id, iKeys, menu, -1, "ADMINPLAYERS")
}


// Player List Menu
show_menu_player_list(id)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return;
	
	static menuid, menu[128], player, userflags, buffer[2]
	userflags = get_user_flags(id)
	
	// Title
	switch (PL_ACTION)
	{
		case ACTION_ZOMBIEFY_HUMANIZE: formatex(menu, charsmax(menu), "%L\r", id, "MENU_MOD_ADMIN_1")
		case ACTION_MAKE_NEMESIS: formatex(menu, charsmax(menu), "%L\r", id, "MENU_MOD_ADMIN_2")
		case ACTION_MAKE_SURVIVOR: formatex(menu, charsmax(menu), "%L\r", id, "MENU_MOD_ADMIN_3")
		case ACTION_RESPAWN_PLAYER: formatex(menu, charsmax(menu), "%L\r", id, "MENU_MOD_ADMIN_4")
	}
	menuid = menu_create(menu, "menu_player_list")
	
	// Player List
	for (player = 0; player <= g_maxplayers; player++)
	{
		// Skip if not connected
		if (!g_isconnected[player])
			continue;
		
		// Format text depending on the action to take
		switch (PL_ACTION)
		{
			case ACTION_ZOMBIEFY_HUMANIZE: // Zombiefy/Humanize command
			{
				if (g_zombie[player])
				{
					if (allowed_human(player) && (userflags & g_access_flag[ACCESS_MAKE_HUMAN]))
						formatex(menu, charsmax(menu), "%s \r[%L]", g_playername[player], id, g_nemesis[player] ? "CLASS_NEMESIS" : "CLASS_ZOMBIE")
					else
						formatex(menu, charsmax(menu), "\d%s [%L]", g_playername[player], id, g_nemesis[player] ? "CLASS_NEMESIS" : "CLASS_ZOMBIE")
				}
				else
				{
					if (allowed_zombie(player) && (g_newround ? (userflags & g_access_flag[ACCESS_MODE_INFECTION]) : (userflags & g_access_flag[ACCESS_MAKE_ZOMBIE])))
						formatex(menu, charsmax(menu), "%s \y[%L]", g_playername[player], id, g_survivor[player] ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
					else
						formatex(menu, charsmax(menu), "\d%s [%L]", g_playername[player], id, g_survivor[player] ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
				}
			}
			case ACTION_MAKE_NEMESIS: // Nemesis command
			{
				if (allowed_nemesis(player) && (g_newround ? (userflags & g_access_flag[ACCESS_MODE_NEMESIS]) : (userflags & g_access_flag[ACCESS_MAKE_NEMESIS])))
				{
					if (g_zombie[player])
						formatex(menu, charsmax(menu), "%s \r[%L]", g_playername[player], id, g_nemesis[player] ? "CLASS_NEMESIS" : "CLASS_ZOMBIE")
					else
						formatex(menu, charsmax(menu), "%s \y[%L]", g_playername[player], id, g_survivor[player] ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
				}
				else
					formatex(menu, charsmax(menu), "\d%s [%L]", g_playername[player], id, g_zombie[player] ? g_nemesis[player] ? "CLASS_NEMESIS" : "CLASS_ZOMBIE" : g_survivor[player] ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
			}
			case ACTION_MAKE_SURVIVOR: // Survivor command
			{
				if (allowed_survivor(player) && (g_newround ? (userflags & g_access_flag[ACCESS_MODE_SURVIVOR]) : (userflags & g_access_flag[ACCESS_MAKE_SURVIVOR])))
				{
					if (g_zombie[player])
						formatex(menu, charsmax(menu), "%s \r[%L]", g_playername[player], id, g_nemesis[player] ? "CLASS_NEMESIS" : "CLASS_ZOMBIE")
					else
						formatex(menu, charsmax(menu), "%s \y[%L]", g_playername[player], id, g_survivor[player] ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
				}
				else
					formatex(menu, charsmax(menu), "\d%s [%L]", g_playername[player], id, g_zombie[player] ? g_nemesis[player] ? "CLASS_NEMESIS" : "CLASS_ZOMBIE" : g_survivor[player] ? "CLASS_SURVIVOR" : "CLASS_HUMAN")
			}
			case ACTION_RESPAWN_PLAYER: // Respawn command
			{
				if (allowed_respawn(player) && (userflags & g_access_flag[ACCESS_RESPAWN_PLAYERS]))
					formatex(menu, charsmax(menu), "%s", g_playername[player])
				else
					formatex(menu, charsmax(menu), "\d%s", g_playername[player])
			}
		}
		
		// Add player
		buffer[0] = player
		buffer[1] = 0
		menu_additem(menuid, menu, buffer)
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%L", id, "MENU_BACK")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_PLAYERS = min(MENU_PAGE_PLAYERS, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	if (pev_valid(id) == PDATA_SAFE)
		set_pdata_int(id, OFFSET_CSMENUCODE, 0, OFFSET_LINUX)
	
	menu_display(id, menuid, MENU_PAGE_PLAYERS)
}

/*================================================================================
 [Menu Handlers]
=================================================================================*/

// Game Menu
public menu_game(id, key)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return PLUGIN_HANDLED;
	
	switch (key)
	{
		case 0: // Z-Classes
		{
			CMD_ClassMenu(id);
			//client_cmd(id, "zclassmenu");
		}
		case 1: // Unstuck!
		{
			// Check if player is stuck
			if (g_isalive[id])
			{
				if (is_player_stuck(id))
				{
					zp_user_spawn(id);
				}
				else
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_STUCK")
			}
			else
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
		}
		case 2: // Cabinet
		{
			show_menu_contacts_chief(id);
		}
		case 3: // Rules
		{
			show_motd(id, "rules.txt", "Правила сервера")
		}
		case 4: // Настройки
		{
			show_options_menu(id);
		}
		case 5:
		{
			show_privilegies_menu(id);
		}
		case 6:
		{
			client_cmd(id, "menu_quests");
		}
		case 7: client_cmd(id, "check_res");
		case 8: // Admin Menu
		{
			new iFlags = get_user_flags(id)
			
			if(iFlags & g_access_flag[ACCESS_ADMIN_MENU])
				show_menu_admin(id);
			else if(iFlags & ADMIN_BAN)
				show_menu_admin_players(id);
		}
	}
	
	return PLUGIN_HANDLED;
}


public menu_contacts_chief(id, key)
{
	// Player disconnected?
	if (!g_isconnected[id])
	return PLUGIN_HANDLED;
	
	switch(key)
	{
		case 0: // BOOST-Info
		{
			show_menu_boostinfo(id);
		}
		case 1: // VIP-Info
		{
			show_menu_vipinfo(id);
		}
		case 2: // PREMIUM-Info
		{
			show_menu_preminfo(id);
		}
		case 3: // Agent-Info
		{
			show_menu_agentinfo(id);
		}
		case 7: // Free Vip
		{
			show_menu_freevip(id);
		}
		case 8: // Contacts
		{
			show_menu_contacts(id);
		}
	}
	
	return PLUGIN_HANDLED;
}

public menu_vipinfo(id, key)
{
	if(key < 9) 
		show_menu_vipinfo(id);	
	
	return PLUGIN_HANDLED;
}

public menu_preminfo(id, key)
{
	if(key < 9) 
		show_menu_preminfo(id);	

	return PLUGIN_HANDLED;
}

public menu_agentinfo(id, key)
{
	if(key < 9) 
		show_menu_agentinfo(id);	
	
	return PLUGIN_HANDLED;
}

public menu_boostinfo(id, key)
{
	if(key < 9) 
		show_menu_boostinfo(id);	
	
	return PLUGIN_HANDLED;
}

public menu_contacts(id, key)
{
	if(key < 9) 
		show_menu_contacts(id);	
	
	return PLUGIN_HANDLED;
}

public menu_freevip(id, key)
{
	if(key < 9) 
		show_menu_freevip(id);	
	
	return PLUGIN_HANDLED;
}

// Buy Menu 1
public menu_buy1(id, key)
{
	// Player dead?
	if (!g_isalive[id])
		return PLUGIN_HANDLED;
	
	// Zombies or survivors get no guns
	if (g_zombie[id] || g_survivor[id])
		return PLUGIN_HANDLED;
	
	// Special keys / weapon list exceeded
	if (key >= MENU_KEY_AUTOSELECT || WPN_SELECTION >= WPN_MAXIDS)
	{
		switch (key)
		{
			case MENU_KEY_AUTOSELECT: // toggle auto select
			{
				show_menu_buy1(id);
			}
			case MENU_KEY_NEXT: // next/back
			{
				show_menu_buy1(id);
			}
			case MENU_KEY_EXIT: // exit
			{
				return PLUGIN_HANDLED;
			}
		}
		
		// Show buy menu again
		show_menu_buy1(id)
		return PLUGIN_HANDLED;
	}
	
	// Store selected weapon id
	WPN_AUTO_PRI = WPN_SELECTION
	
	// Buy primary weapon
	buy_primary_weapon(id, WPN_AUTO_PRI)
	
	// Show pistols menu
	show_menu_buy2(id)
	
	return PLUGIN_HANDLED;
}

// Buy Primary Weapon
buy_primary_weapon(id, selection)
{
	// Drop previous weapons
	drop_weapons(id, 1)
	drop_weapons(id, 2)
	
	// Strip off from weapons
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	
	// Get weapon's id and name
	static weaponid, wname[32]
	weaponid = ArrayGetCell(g_primary_weaponids, selection)
	ArrayGetString(g_primary_items, selection, wname, charsmax(wname))
	
	// Give the new weapon and full ammo
	fm_give_item(id, wname)
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
	
	// Weapons bought
	g_canbuy[id] = false
}

// Buy Menu 2
public menu_buy2(id, key)
{
	// Player dead?
	if (!g_isalive[id])
		return PLUGIN_HANDLED;
	
	// Zombies or survivors get no guns
	if (g_zombie[id] || g_survivor[id])
		return PLUGIN_HANDLED;
	
	// Special keys / weapon list exceeded
	if (key >= ArraySize(g_secondary_items))
	{
		// Press auto select
		if(key == MENU_KEY_AUTOSELECT)
			show_menu_buy2(id);
			
		// Reshow menu unless user exited
		if (key != MENU_KEY_EXIT)
			show_menu_buy2(id)
		
		return PLUGIN_HANDLED;
	}
	
	// Store selected weapon
	WPN_AUTO_SEC = key
	
	// Drop secondary gun again, in case we picked another (bugfix)
	drop_weapons(id, 2)
	
	// Get weapon's id
	static weaponid, wname[32]
	weaponid = ArrayGetCell(g_secondary_weaponids, key)
	ArrayGetString(g_secondary_items, key, wname, charsmax(wname))
	
	// Give the new weapon and full ammo
	fm_give_item(id, wname)
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
	
	return PLUGIN_HANDLED;
}

// Extra Items Menu
public menu_extras(id, menuid, item)
{
	// Player disconnected?
	if (!is_user_connected(id))
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Remember player's menu page
	static menudummy
	player_menu_info(id, menudummy, menudummy, MENU_PAGE_EXTRAS)
	
	// Menu was closed
	if (item == MENU_EXIT)
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Dead players are not allowed to buy items
	if (!g_isalive[id])
	{
		zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Retrieve extra item id
	static buffer[2], dummy, itemid
	menu_item_getinfo(menuid, item, dummy, buffer, charsmax(buffer), _, _, dummy)
	itemid = buffer[0]
	
	// Attempt to buy the item
	buy_extra_item(id, itemid)
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

// Buy Extra Item
buy_extra_item(id, itemid, ignorecost = 0)
{
	// Retrieve item's team
	static team
	team = ArrayGetCell(g_extraitem_team, itemid)
	
	// Check for team/class specific items
	if ((g_zombie[id] && !g_nemesis[id] && !(team & ZP_TEAM_ZOMBIE)) || (!g_zombie[id] && !g_survivor[id] && !(team & ZP_TEAM_HUMAN)) || (g_nemesis[id] && !(team & ZP_TEAM_NEMESIS)) || (g_survivor[id] && !(team & ZP_TEAM_SURVIVOR)))
	{
		zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
		return;
	}
	
	// Check for unavailable items
	if ((itemid == EXTRA_NVISION && !get_pcvar_num(cvar_extranvision))
	|| (itemid == EXTRA_ANTIDOTE && (!get_pcvar_num(cvar_extraantidote) || g_antidotecounter >= get_pcvar_num(cvar_antidotelimit)))
	|| (itemid == EXTRA_MADNESS && (!get_pcvar_num(cvar_extramadness) || g_madnesscounter >= get_pcvar_num(cvar_madnesslimit)))
	|| (itemid >= EXTRA_WEAPONS_STARTID && itemid <= EXTRAS_CUSTOM_STARTID-1 && !get_pcvar_num(cvar_extraweapons)))
	{
		zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
		return;
	}
	
	// Check for hard coded items with special conditions
	if ((itemid == EXTRA_ANTIDOTE && (g_endround || g_swarmround || g_nemround || g_survround || g_plagueround || fnGetZombies() <= 1 || (get_pcvar_num(cvar_deathmatch) && !get_pcvar_num(cvar_respawnafterlast) && fnGetHumans() == 1)))
	|| (itemid == EXTRA_MADNESS && Float:get_entvar(id, var_takedamage) == DAMAGE_NO))
	{
		zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_CANTUSE")
		return;
	}
	
	// Ignore item's cost?
	if (!ignorecost)
	{
		// Check that we have enough ammo packs
		if (g_ammopacks[id] < ArrayGetCell(g_extraitem_cost, itemid))
		{
			zp_colored_print(id, "^x04[ZP]^x01 %L", id, "NOT_ENOUGH_AMMO")
			return;
		}
		
		// Deduce item cost
		g_ammopacks[id] -= ArrayGetCell(g_extraitem_cost, itemid)
	}
	
	// Check which kind of item we're buying
	switch (itemid)
	{
		case EXTRA_NVISION: // Night Vision
		{
			g_nvision[id] = true
			
			if (!g_isbot[id])
			{
				g_nvisionenabled[id] = true
				
				// Custom nvg?
				if (get_pcvar_num(cvar_customnvg))
				{
					remove_task(id+TASK_NVISION)
					set_task(0.1, "set_user_nvision", id+TASK_NVISION, _, _, "b")
				}
				else
					set_user_gnvision(id, 1)
			}
			else
				cs_set_user_nvg(id, 1)
		}
		case EXTRA_ANTIDOTE: // Antidote
		{
			// Increase antidote purchase count for this round
			g_antidotecounter++
			
			new szName[32]
			get_user_name(id, szName, 31)
			
			UTIL_SayText(0, "!g[ZP] !yPREMIUM-игрок !g%s !yкупил !gАнтидот!y!", szName)
			
			humanme(id, 0, 0, 0)
		}
		case EXTRA_MADNESS: // Zombie Madness
		{
			// Increase madness purchase count for this round
			g_madnesscounter++
			
			set_entvar(id, var_takedamage, DAMAGE_NO);
			set_task(0.1, "zombie_aura", id+TASK_AURA, _, _, "b")
			set_task(get_pcvar_float(cvar_madnessduration), "madness_over", id+TASK_BLOOD)
			
			/*static sound[64]
			static pointers[10], end
			ArrayGetArray(pointer_class_sound_madness, g_zombieclass[id], pointers)
			
			for (new i; i < 10; i++)
			{
				if (pointers[i] != -1)
				end = i
			}
			ArrayGetString(class_sound_madness, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
			emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)*/
		}
		default:
		{
			if (itemid >= EXTRA_WEAPONS_STARTID && itemid <= EXTRAS_CUSTOM_STARTID-1) // Weapons
			{
				// Get weapon's id and name
				static weaponid, wname[32]
				ArrayGetString(g_extraweapon_items, itemid - EXTRA_WEAPONS_STARTID, wname, charsmax(wname))
				weaponid = cs_weapon_name_to_id(wname)
				
				// If we are giving a primary/secondary weapon
				if (MAXBPAMMO[weaponid] > 2)
				{
					// Make user drop the previous one
					if ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)
						drop_weapons(id, 1)
					else
						drop_weapons(id, 2)
					
					// Give full BP ammo for the new one
					ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weaponid], AMMOTYPE[weaponid], MAXBPAMMO[weaponid])
				}
				// If we are giving a grenade which the user already owns
				else if (user_has_weapon(id, weaponid))
				{
					// Increase BP ammo on it instead
					cs_set_user_bpammo(id, weaponid, cs_get_user_bpammo(id, weaponid) + 1)
					
					// Flash ammo in hud
					message_begin(MSG_ONE_UNRELIABLE, g_msgAmmoPickup, _, id)
					write_byte(AMMOID[weaponid]) // ammo id
					write_byte(1) // ammo amount
					message_end()
					
					// Play clip purchase sound
					emit_sound(id, CHAN_ITEM, sound_buyammo, 1.0, ATTN_NORM, 0, PITCH_NORM)
					
					return; // stop here
				}
				
				// Give weapon to the player
				fm_give_item(id, wname)
			}
			else // Custom additions
			{
				// Item selected forward
				ExecuteForward(g_fwExtraItemSelected, g_fwDummyResult, id, itemid);
				
				// Item purchase blocked, restore buyer's ammo packs
				if (g_fwDummyResult >= ZP_PLUGIN_HANDLED && !ignorecost)
					g_ammopacks[id] += ArrayGetCell(g_extraitem_cost, itemid)
			}
		}
	}
}


// Zombie Class Menu
public Handle_ClassMenu(id, iKey)
{
	switch(iKey)
    {
    	case 7: return Show_ClassMenu(id, --g_iMenuPosition[id]);
        case 8: return Show_ClassMenu(id, ++g_iMenuPosition[id]);
        case 9: return PLUGIN_HANDLED;
        default:
        {
			new iTarget = g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey;

			// Store selection for the next infection
			g_zombieclassnext[id] = iTarget
			
			if(g_zombieclassnext[id] == 6 && ~get_user_flags(id) & ADMIN_LEVEL_H)
			{
				zp_colored_print(id, "^x04[ZP]^x01 Нет доступа. Купить ^x04VIP^x01 - csomod.ru/store")
				g_zombieclassnext[id] = 0
				CMD_ClassMenu(id);
				return PLUGIN_HANDLED;
			}
			
			if(g_zombieclassnext[id] == 7 && ~get_user_flags(id) & ADMIN_LEVEL_D)
			{
				zp_colored_print(id, "^x04[ZP]^x01 Нет доступа. Купить ^x04PREMIUM^x01 - csomod.ru/store")
				g_zombieclassnext[id] = 0
				CMD_ClassMenu(id);
				return PLUGIN_HANDLED;
			}
			
			if(g_zombieclassnext[id] == 8 && ~get_user_flags(id) & ADMIN_LEVEL_G)
			{
				zp_colored_print(id, "^x04[ZP]^x01 Нет доступа. Купить^x04 AGENT^x01 - csomod.ru/store")
				g_zombieclassnext[id] = 0
				CMD_ClassMenu(id);
				return PLUGIN_HANDLED;
			}

			static name[32]
			ArrayGetString(g_zclass_name, g_zombieclassnext[id], name, charsmax(name))
			
			if (contain(name, "ML_") != -1)
				format(name, charsmax(name), "%L", id, name[3])
			
			// Show selected zombie class info and stats
			zp_colored_print(id, "^x04[ZP]^x01 %L: ^x04%s", id, "ZOMBIE_SELECT", name)
			zp_colored_print(id, "^x04[ZP]^x01 %L: ^x04%d ^x01| %L: ^x04%d ^x01| %L: ^x04%d ^x01| %L: ^x04%d%%", id, "ZOMBIE_ATTRIB1", ArrayGetCell(g_zclass_hp, g_zombieclassnext[id]), id, "ZOMBIE_ATTRIB2", ArrayGetCell(g_zclass_spd, g_zombieclassnext[id]),
			id, "ZOMBIE_ATTRIB3", floatround(Float:ArrayGetCell(g_zclass_grav, g_zombieclassnext[id]) * 800.0), id, "ZOMBIE_ATTRIB4", floatround(Float:ArrayGetCell(g_zclass_kb, g_zombieclassnext[id]) * 100.0))
			return PLUGIN_HANDLED;
	    }
    }
	return Show_ClassMenu(id, g_iMenuPosition[id]);
}

public menu_admin(id, key)
{
	// Player disconnected?
	if (!g_isconnected[id])
	return PLUGIN_HANDLED;
	
	new userflags
	userflags = get_user_flags(id)
	
	switch(key)
	{
		case 0: // VIP-Info
		{
			if(zp_get_autorr())
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
			else if(zp_check_vote())
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
			else if(userflags & g_access_flag[ACCESS_ADMIN_MENU])
				show_menu_mod_admin(id)
			else
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
		}
		case 1: // PREMIUM-Info
		{
			show_menu_admin_players(id);
		}
		case 2: // Contacts
		{
			zp_menu_admin_give(id);
		}
	}
	
	return PLUGIN_HANDLED;
}

// Admin Mod Menu
public menu_mod_admin(id, key)
{
	// Player disconnected?
	if (!g_isconnected[id])
		return PLUGIN_HANDLED;
	
	static userflags
	userflags = get_user_flags(id)
	
	switch (key)
	{
		case ACTION_ZOMBIEFY_HUMANIZE: // Zombiefy/Humanize command
		{
			if(zp_get_autorr())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
			}
			else if(zp_check_vote())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
			}
			else if (userflags & (g_access_flag[ACCESS_MODE_INFECTION] | g_access_flag[ACCESS_MAKE_ZOMBIE] | g_access_flag[ACCESS_MAKE_HUMAN]))
			{
				// Show player list for admin to pick a target
				PL_ACTION = ACTION_ZOMBIEFY_HUMANIZE
				show_menu_player_list(id)
			}
			else
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
			}
		}
		case ACTION_MAKE_NEMESIS: // Nemesis command
		{
			if(zp_get_autorr())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
			}
			else if(zp_check_vote())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
			}
			else if (userflags & (g_access_flag[ACCESS_MODE_NEMESIS] | g_access_flag[ACCESS_MAKE_NEMESIS]))
			{
				// Show player list for admin to pick a target
				PL_ACTION = ACTION_MAKE_NEMESIS
				show_menu_player_list(id)
			}			
			else
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
			}
		}
		case ACTION_MAKE_SURVIVOR: // Survivor command
		{
			if(zp_get_autorr())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
			}
			else if(zp_check_vote())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
			}
			else if (userflags & (g_access_flag[ACCESS_MODE_SURVIVOR] | g_access_flag[ACCESS_MAKE_SURVIVOR]))
			{
				// Show player list for admin to pick a target
				PL_ACTION = ACTION_MAKE_SURVIVOR
				show_menu_player_list(id)
			}
			else
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
			}
		}
		case ACTION_RESPAWN_PLAYER: // Respawn command
		{
			if(zp_get_autorr())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
			}
			else if(zp_check_vote())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
			}
			else if (userflags & g_access_flag[ACCESS_RESPAWN_PLAYERS])
			{
				// Show player list for admin to pick a target
				PL_ACTION = ACTION_RESPAWN_PLAYER
				show_menu_player_list(id)
			}
			else
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
			}
		}
		case ACTION_MODE_SWARM: // Swarm Mode command
		{
			if(zp_get_autorr())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
			}
			else if(zp_check_vote())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
			}
			if (userflags & g_access_flag[ACCESS_MODE_SWARM])
			{
				if (allowed_swarm())
					command_swarm(id)
				else
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
			}
			else
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
		}
		case ACTION_MODE_MULTI: // Multiple Infection command
		{
			if(zp_get_autorr())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
			}
			else if(zp_check_vote())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
			}
			else if (userflags & g_access_flag[ACCESS_MODE_MULTI])
			{
				if (allowed_multi())
					command_multi(id)
				else
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
			}
			else
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
		}
		case ACTION_MODE_PLAGUE: // Plague Mode command
		{
			if(zp_get_autorr())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
			}
			else if(zp_check_vote())
			{
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
			}
			else if (userflags & g_access_flag[ACCESS_MODE_PLAGUE])
			{
				if (allowed_plague())
					command_plague(id)
				else
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
			}
			else
				zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
		}
	}
	
	return PLUGIN_HANDLED;
}

public menu_admin_players(id, key)
{
	// Player disconnected?
	if (!g_isconnected[id])
	return PLUGIN_HANDLED;
	
	switch(key)
	{
		case 0: // Kick menu
		{
			client_cmd(id, "amx_kickmenu")
		}
		case 1: // Ban menu
		{
			client_cmd(id, "amx_banmenu")
		}
		case 2: //Offban
		{
			client_cmd(id, "amx_offbanmenu")
		}
		case 3: // Gag menu
		{
			client_cmd(id, "amx_gagmenu")
		}
		case 4: // Slap menu
		{
			client_cmd(id, "amx_slapmenu")
		}
		case 5: //Team menu
		{
			client_cmd(id, "amx_teammenu")
		}
		case 6: // Map menu
		{
			client_cmd(id, "amx_mapmenu")
		}
		case 7: // Vote Map menu
		{
			client_cmd(id, "amx_votemapmenu")
		}
	}
	
	return PLUGIN_HANDLED;
}

// Player List Menu
public menu_player_list(id, menuid, item)
{
	// Player disconnected?
	if (!is_user_connected(id))
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Remember player's menu page
	static menudummy
	player_menu_info(id, menudummy, menudummy, MENU_PAGE_PLAYERS)
	
	// Menu was closed
	if (item == MENU_EXIT)
	{
		menu_destroy(menuid)
		show_menu_mod_admin(id)
		return PLUGIN_HANDLED;
	}
	
	// Retrieve player id
	static buffer[2], dummy, playerid
	menu_item_getinfo(menuid, item, dummy, buffer, charsmax(buffer), _, _, dummy)
	playerid = buffer[0]
	
	// Perform action on player
	
	// Get admin flags
	static userflags
	userflags = get_user_flags(id)
	
	// Make sure it's still connected
	if (g_isconnected[playerid])
	{
		// Perform the right action if allowed
		switch (PL_ACTION)
		{
			case ACTION_ZOMBIEFY_HUMANIZE: // Zombiefy/Humanize command
			{
				if (g_zombie[playerid])
				{
					if(zp_get_autorr())
						zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
					else if(zp_check_vote())
						zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
					else if (userflags & g_access_flag[ACCESS_MAKE_HUMAN])
					{
						if (allowed_human(playerid))
							command_human(id, playerid)
						else
							zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
					}
					else
						zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
				}
				else
				{
					if(zp_get_autorr())
						zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
					else if(zp_check_vote())
						zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
					else if (g_newround ? (userflags & g_access_flag[ACCESS_MODE_INFECTION]) : (userflags & g_access_flag[ACCESS_MAKE_ZOMBIE]))
					{
						if (allowed_zombie(playerid))
							command_zombie(id, playerid)
						else
							zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
					}
					else
						zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
				}
			}
			case ACTION_MAKE_NEMESIS: // Nemesis command
			{
				if(zp_get_autorr())
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
				else if(zp_check_vote())
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
				else if (g_newround ? (userflags & g_access_flag[ACCESS_MODE_NEMESIS]) : (userflags & g_access_flag[ACCESS_MAKE_NEMESIS]))
				{
					if (allowed_nemesis(playerid))
						command_nemesis(id, playerid)
					else
						zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
				}
				else
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
			}
			case ACTION_MAKE_SURVIVOR: // Survivor command
			{
				if(zp_get_autorr())
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
				else if(zp_check_vote())
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
				if (g_newround ? (userflags & g_access_flag[ACCESS_MODE_SURVIVOR]) : (userflags & g_access_flag[ACCESS_MAKE_SURVIVOR]))
				{
					if (allowed_survivor(playerid))
						command_survivor(id, playerid)
					else
						zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
				}
				else
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
			}
			case ACTION_RESPAWN_PLAYER: // Respawn command
			{
				if(zp_get_autorr())
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_RESTART")
				else if(zp_check_vote())
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_CHECK_VOTE")
				else if (userflags & g_access_flag[ACCESS_RESPAWN_PLAYERS])
				{
					if (allowed_respawn(playerid))
						command_respawn(id, playerid)
					else
						zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
				}
				else
					zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT_ACCESS")
			}
		}
	}
	else
		zp_colored_print(id, "^x04[ZP]^x01 %L", id, "CMD_NOT")
	
	menu_destroy(menuid)
	show_menu_player_list(id)
	return PLUGIN_HANDLED;
}

// CS Buy Menus
/*public menu_cs_buy(id, key)
{
	// Prevent buying if zombie/survivor (bugfix)
	if (g_zombie[id] || g_survivor[id])
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}*/

/*================================================================================
 [Admin Commands]
=================================================================================*/

// zp_toggle [1/0]
public cmd_toggle(id, level, cid)
{
	// Check for access flag - Enable/Disable Mod
	if (!cmd_access(id, g_access_flag[ACCESS_ENABLE_MOD], cid, 2))
		return PLUGIN_HANDLED;
	
	// Retrieve arguments
	new arg[2]
	read_argv(1, arg, charsmax(arg))
	
	// Mod already enabled/disabled
	if (str_to_num(arg) == g_pluginenabled)
		return PLUGIN_HANDLED;
	
	// Set toggle cvar
	set_pcvar_num(cvar_toggle, str_to_num(arg))
	client_print(id, print_console, "Zombie Plague %L.", id, str_to_num(arg) ? "MOTD_ENABLED" : "MOTD_DISABLED")
	
	// Retrieve map name
	new mapname[32]
	get_mapname(mapname, charsmax(mapname))
	
	// Restart current map
	server_cmd("changelevel %s", mapname)
	
	return PLUGIN_HANDLED;
}

// zp_zombie [target]
public cmd_zombie(id, level, cid)
{
	// Check for access flag depending on the resulting action
	if (g_newround)
	{
		// Start Mode Infection
		if (!cmd_access(id, g_access_flag[ACCESS_MODE_INFECTION], cid, 2))
			return PLUGIN_HANDLED;
	}
	else
	{
		// Make Zombie
		if (!cmd_access(id, g_access_flag[ACCESS_MAKE_ZOMBIE], cid, 2))
			return PLUGIN_HANDLED;
	}
	
	// Retrieve arguments
	static arg[32], player
	read_argv(1, arg, charsmax(arg))
	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF))
	
	// Invalid target
	if (!player) return PLUGIN_HANDLED;
	
	// Target not allowed to be zombie
	if (!allowed_zombie(player))
	{
		client_print(id, print_console, "[ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED
	}
	
	command_zombie(id, player)
	
	return PLUGIN_HANDLED;
}

// zp_human [target]
public cmd_human(id, level, cid)
{
	// Check for access flag - Make Human
	if (!cmd_access(id, g_access_flag[ACCESS_MAKE_HUMAN], cid, 2))
		return PLUGIN_HANDLED;
	
	// Retrieve arguments
	static arg[32], player
	read_argv(1, arg, charsmax(arg))
	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF))
	
	// Invalid target
	if (!player) return PLUGIN_HANDLED;
	
	// Target not allowed to be human
	if (!allowed_human(player))
	{
		client_print(id, print_console, "[ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED;
	}
	
	command_human(id, player)
	
	return PLUGIN_HANDLED;
}

// zp_survivor [target]
public cmd_survivor(id, level, cid)
{
	// Check for access flag depending on the resulting action
	if (g_newround)
	{
		// Start Mode Survivor
		if (!cmd_access(id, g_access_flag[ACCESS_MODE_SURVIVOR], cid, 2))
			return PLUGIN_HANDLED;
	}
	else
	{
		// Make Survivor
		if (!cmd_access(id, g_access_flag[ACCESS_MAKE_SURVIVOR], cid, 2))
			return PLUGIN_HANDLED;
	}
	
	// Retrieve arguments
	static arg[32], player
	read_argv(1, arg, charsmax(arg))
	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF))
	
	// Invalid target
	if (!player) return PLUGIN_HANDLED;
	
	// Target not allowed to be survivor
	if (!allowed_survivor(player))
	{
		client_print(id, print_console, "[ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED;
	}
	
	command_survivor(id, player)
	
	return PLUGIN_HANDLED;
}

// zp_nemesis [target]
public cmd_nemesis(id, level, cid)
{
	// Check for access flag depending on the resulting action
	if (g_newround)
	{
		// Start Mode Nemesis
		if (!cmd_access(id, g_access_flag[ACCESS_MODE_NEMESIS], cid, 2))
			return PLUGIN_HANDLED;
	}
	else
	{
		// Make Nemesis
		if (!cmd_access(id, g_access_flag[ACCESS_MAKE_NEMESIS], cid, 2))
			return PLUGIN_HANDLED;
	}
	
	// Retrieve arguments
	static arg[32], player
	read_argv(1, arg, charsmax(arg))
	player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF))
	
	// Invalid target
	if (!player) return PLUGIN_HANDLED;
	
	// Target not allowed to be nemesis
	if (!allowed_nemesis(player))
	{
		client_print(id, print_console, "[ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED;
	}
	
	command_nemesis(id, player)
	
	return PLUGIN_HANDLED;
}

// zp_respawn [target]
public cmd_respawn(id, level, cid)
{
	// Check for access flag - Respawn
	if (!cmd_access(id, g_access_flag[ACCESS_RESPAWN_PLAYERS], cid, 2))
		return PLUGIN_HANDLED;
	
	// Retrieve arguments
	static arg[32], player
	read_argv(1, arg, charsmax(arg))
	player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF)
	
	// Invalid target
	if (!player) return PLUGIN_HANDLED;
	
	// Target not allowed to be respawned
	if (!allowed_respawn(player))
	{
		client_print(id, print_console, "[ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED;
	}
	
	command_respawn(id, player)
	
	return PLUGIN_HANDLED;
}

// zp_swarm
public cmd_swarm(id, level, cid)
{
	// Check for access flag - Mode Swarm
	if (!cmd_access(id, g_access_flag[ACCESS_MODE_SWARM], cid, 1))
		return PLUGIN_HANDLED;
	
	// Swarm mode not allowed
	if (!allowed_swarm())
	{
		client_print(id, print_console, "[ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED;
	}
	
	command_swarm(id)
	
	return PLUGIN_HANDLED;
}

// zp_multi
public cmd_multi(id, level, cid)
{
	// Check for access flag - Mode Multi
	if (!cmd_access(id, g_access_flag[ACCESS_MODE_MULTI], cid, 1))
		return PLUGIN_HANDLED;
	
	// Multi infection mode not allowed
	if (!allowed_multi())
	{
		client_print(id, print_console, "[ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED;
	}
	
	command_multi(id)
	
	return PLUGIN_HANDLED;
}

// zp_plague
public cmd_plague(id, level, cid)
{
	// Check for access flag - Mode Plague
	if (!cmd_access(id, g_access_flag[ACCESS_MODE_PLAGUE], cid, 1))
		return PLUGIN_HANDLED;
	
	// Plague mode not allowed
	if (!allowed_plague())
	{
		client_print(id, print_console, "[ZP] %L", id, "CMD_NOT")
		return PLUGIN_HANDLED;
	}
	
	command_plague(id)
	
	return PLUGIN_HANDLED;
}

/*================================================================================
 [Message Hooks]
=================================================================================*/

// Current Weapon info
/*public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
	// Not alive or zombie
	if (!g_isalive[msg_entity] || g_zombie[msg_entity])
		return;
	
	// Not an active weapon
	if (get_msg_arg_int(1) != 1)
		return;
	
	// Unlimited clip disabled for class
	if (g_survivor[msg_entity] ? get_pcvar_num(cvar_survinfammo) <= 1 : get_pcvar_num(cvar_infammo) <= 1)
		return;
	
	// Get weapon's id
	static weapon
	weapon = get_msg_arg_int(2)
	
	// Unlimited Clip Ammo for this weapon?
	if (MAXBPAMMO[weapon] > 2)
	{
		// Max out clip ammo
		static weapon_ent
		weapon_ent = fm_cs_get_current_weapon_ent(msg_entity)
		if (pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])
		
		// HUD should show full clip all the time
		set_msg_arg_int(3, get_msg_argtype(3), MAXCLIP[weapon])
	}
}*/

// Fix for the HL engine bug when HP is multiples of 256
public message_health(msg_id, msg_dest, msg_entity)
{
	// Get player's health
	static health
	health = get_msg_arg_int(1)
	
	// Don't bother
	if (health < 256) return;
	
	// Check if we need to fix it
	if (health % 256 == 0)
		fm_set_user_health(msg_entity, pev(msg_entity, pev_health) + 1)
	
	// HUD can only show as much as 255 hp
	set_msg_arg_int(1, get_msg_argtype(1), 255)
}

// Block flashlight battery messages if custom flashlight is enabled instead
public message_flashbat()
{
	if (g_cached_customflash)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

// Flashbangs should only affect zombies
public message_screenfade(msg_id, msg_dest, msg_entity)
{
	if (get_msg_arg_int(4) != 255 || get_msg_arg_int(5) != 255 || get_msg_arg_int(6) != 255 || get_msg_arg_int(7) < 200)
		return PLUGIN_CONTINUE;
	
	// Nemesis shouldn't be FBed
	if (g_zombie[msg_entity] && !g_nemesis[msg_entity])
	{
		// Set flash color to nighvision's
		set_msg_arg_int(4, get_msg_argtype(4), get_pcvar_num(cvar_nvgcolor[0]))
		set_msg_arg_int(5, get_msg_argtype(5), get_pcvar_num(cvar_nvgcolor[1]))
		set_msg_arg_int(6, get_msg_argtype(6), get_pcvar_num(cvar_nvgcolor[2]))
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_HANDLED;
}

// Prevent spectators' nightvision from being turned off when switching targets, etc.
public message_nvgtoggle()
{
	return PLUGIN_HANDLED;
}

/*// Set correct model on player corpses
public message_clcorpse()
{
	set_msg_arg_string(1, g_playermodel[get_msg_arg_int(12)])
}*/

// Prevent zombies from seeing any weapon pickup icon
public message_weappickup(msg_id, msg_dest, msg_entity)
{
	if(g_zombie[msg_entity])
	{
		if( get_msg_arg_int( 1 ) == CSW_KNIFE || get_msg_arg_int( 1 ) == CSW_GLOCK18 )
			return PLUGIN_HANDLED;
	}
	if( get_msg_arg_int( 1 ) == CSW_FLASHBANG )
		UTIL_SetWeaponList( msg_entity, g_zombie[msg_entity] ? "weapon_flashbang" : "zp_br_cso/grenade/weapon_frostgrenade", 11, 1, -1, -1, 3, 2, 25, 24 );
	else if( get_msg_arg_int( 1 ) == CSW_HEGRENADE )
		UTIL_SetWeaponList( msg_entity, g_zombie[msg_entity] ? "weapon_hegrenade" : "zp_br_cso/grenade/weapon_firegrenade", 12, 1, -1, -1, 3, 1, 4, 24 );
	else if( get_msg_arg_int( 1 ) == CSW_SMOKEGRENADE )
		UTIL_SetWeaponList( msg_entity, g_zombie[msg_entity] ? "zp_br_cso/grenade/weapon_jumpgrenade" : "zp_br_cso/grenade/weapon_pumpkin", 13, 1, -1, -1, 3, 3, 9, 24 );
	
	return PLUGIN_CONTINUE;
}

// Prevent zombies from seeing any ammo pickup icon
public message_ammopickup(msg_id, msg_dest, msg_entity)
{
	if (g_zombie[msg_entity])
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

// Block hostage HUD display
public message_scenario()
{
	if (get_msg_args() > 1)
	{
		static sprite[8]
		get_msg_arg_string(2, sprite, charsmax(sprite))
		
		if (equal(sprite, "hostage"))
			return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

// Block hostages from appearing on radar
public message_hostagepos()
{
	return PLUGIN_HANDLED;
}

// Block some text messages
public message_textmsg()
{
	static textmsg[22]
	get_msg_arg_string(2, textmsg, charsmax(textmsg))
	
	// Game restarting, reset scores and call round end to balance the teams
	if (equal(textmsg, "#Game_will_restart_in"))
	{
		logevent_round_end()
		g_scorehumans = 0
		g_scorezombies = 0
	}
	// Game commencing, reset scores only (round end is automatically triggered)
	else if (equal(textmsg, "#Game_Commencing"))
	{
		g_gamecommencing = true
		g_scorehumans = 0
		g_scorezombies = 0
		client_cmd(0, "stopsound")
	}
	// Block round end related messages
	else if (equal(textmsg, "#Hostages_Not_Rescued") || equal(textmsg, "#Round_Draw") || equal(textmsg, "#Terrorists_Win") || equal(textmsg, "#CTs_Win"))
	{
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

// Block CS round win audio messages, since we're playing our own instead
public message_sendaudio()
{
	static audio[17]
	get_msg_arg_string(2, audio, charsmax(audio))
	
	if(equal(audio[7], "terwin") || equal(audio[7], "ctwin") || equal(audio[7], "rounddraw"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

// Send actual team scores (T = zombies // CT = humans)
public message_teamscore()
{
	static team[2]
	get_msg_arg_string(1, team, charsmax(team))
	
	switch (team[0])
	{
		// CT
		case 'C': set_msg_arg_int(2, get_msg_argtype(2), g_scorehumans)
		// Terrorist
		case 'T': set_msg_arg_int(2, get_msg_argtype(2), g_scorezombies)
	}
}
/*
// Team Switch (or player joining a team for first time)
public message_teaminfo(msg_id, msg_dest)
{
	// Only hook global messages
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST) return;
	
	// Don't pick up our own TeamInfo messages for this player (bugfix)
	if (g_switchingteam) return;
	
	// Get player's id
	static id
	id = get_msg_arg_int(1)
	
	// Invalid player id? (bugfix)
	if (!(1 <= id <= g_maxplayers)) return;
	
	// Enable spectators' nightvision if not spawning right away
	set_task(0.2, "spec_nvision", id)
	
	// Round didn't start yet, nothing to worry about
	if (g_newround) return;
	
	// Get his new team
	static team[2]
	get_msg_arg_string(2, team, charsmax(team))
	
	// Perform some checks to see if they should join a different team instead
	switch (team[0])
	{
		case 'C': // CT
		{
			if (g_survround && fnGetHumans()) // survivor alive --> switch to T and spawn as zombie
			{
				g_respawn_as_zombie[id] = true;
				remove_task(id+TASK_TEAM)
				zp_set_user_team(id, TEAM_TERRORIST)
				set_msg_arg_string(2, "TERRORIST")
			}
			else if (!fnGetZombies()) // no zombies alive --> switch to T and spawn as zombie
			{
				g_respawn_as_zombie[id] = true;
				remove_task(id+TASK_TEAM)
				zp_set_user_team(id, TEAM_TERRORIST)
				set_msg_arg_string(2, "TERRORIST")
			}
		}
		case 'T': // Terrorist
		{
			if ((g_swarmround || g_survround) && fnGetHumans()) // survivor alive or swarm round w/ humans --> spawn as zombie
			{
				g_respawn_as_zombie[id] = true;
			}
			else if (fnGetZombies()) // zombies alive --> switch to CT
			{
				remove_task(id+TASK_TEAM)
				zp_set_user_team(id, TEAM_CT)
				set_msg_arg_string(2, "CT")
			}
		}
	}
}*/

/*public message_teaminfo(msg_id, msg_dest)
{
	//Получаем id клиента
	new id = get_msg_arg_int(1);

	client_print(0, print_chat, "id: %d | team: %d", id, cell:zp_get_user_team(id))

	//Если его команда не определена, то выставляем ему команду CT
	if(zp_get_user_team(id) != TEAM_UNASSIGNED)
		return PLUGIN_CONTINUE;

	zp_set_user_team(id, TEAM_CT);
	set_msg_arg_string(2, "CT");
	return PLUGIN_HANDLED;
}*/

#define ShowMenu_TeamMenu 19
#define ShowMenu_TeamSpectMenu 51
#define ShowMenu_IgTeamMenu 531
#define ShowMenu_IgTeamSpectMenu 563
#define ShowMenu_ClassMenu 31

public message_showmenu(iMsgId, iMsgDest, iReceiver)
{
	switch(get_msg_arg_int(1))
	{
		case ShowMenu_TeamMenu, ShowMenu_TeamSpectMenu, ShowMenu_ClassMenu, ShowMenu_IgTeamMenu, ShowMenu_IgTeamSpectMenu:
		{
			if(zp_get_user_team(iReceiver) != TEAM_CT)
				RequestFrame("Request_JoinTeam", iReceiver)
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

#define VGUIMenu_TeamMenu 2
#define VGUIMenu_ClassMenuTe 26
#define VGUIMenu_ClassMenuCt 27
public message_vguimenu(iMsgId, iMsgDest, iReceiver)
{

	switch(get_msg_arg_int(1))
	{
		case VGUIMenu_TeamMenu, VGUIMenu_ClassMenuTe, VGUIMenu_ClassMenuCt:
		{
			if(zp_get_user_team(iReceiver) != TEAM_CT)
				RequestFrame("Request_JoinTeam", iReceiver)
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public Request_JoinTeam(id)
{
	//zp_set_user_team(id, TEAM_CT);
	rg_join_team(id, TEAM_CT);
}

/*================================================================================
 [Main Functions]
=================================================================================*/

// Make Zombie Task
public make_zombie_task()
{
	// Call make a zombie with no specific mode
	make_a_zombie(MODE_NONE, 0)
}

// Make a Zombie Function
make_a_zombie(mode, id)
{
	// Get alive players count
	static iPlayersnum
	iPlayersnum = fnGetAlive()
	
	// Not enough players, come back later!
	if (iPlayersnum < 1 || zp_get_autorr())
	{
		set_task(2.0, "make_zombie_task", TASK_MAKEZOMBIE)
		return;
	}
	
	// Round started!
	g_newround = false
	
	// Set up some common vars
	static forward_id, sound[64], iHeroes
	
	if ((mode == MODE_NONE && (!get_pcvar_num(cvar_preventconsecutive) || g_lastmode != MODE_SURVIVOR) && random_num(1, get_pcvar_num(cvar_survchance)) == get_pcvar_num(cvar_surv) && iPlayersnum >= get_pcvar_num(cvar_survminplayers)) || mode == MODE_SURVIVOR)
	{
		// Survivor Mode
		g_survround = true
		g_lastmode = MODE_SURVIVOR
		
		// Choose player randomly?
		if (mode == MODE_NONE)
			id = fnGetRandomAlive(random_num(1, iPlayersnum))
		
		// Remember id for calling our forward later
		forward_id = id
		
		// Turn player into a survivor
		humanme(id, 0, 1, 0)
		
		// Turn the remaining players into zombies
		for (id = 1; id <= g_maxplayers; id++)
		{
			// Not alive
			if (!g_isalive[id])
				continue;
			
			// Survivor or already a zombie
			if (g_survivor[id] || g_zombie[id])
				continue;
			
			// Turn into a zombie
			zombieme(id, 0, 0, 1, 0)
		}
		
		// Play survivor sound
		ArrayGetString(sound_survivor, random_num(0, ArraySize(sound_survivor) - 1), sound, charsmax(sound))
		PlaySound(sound);
		
		set_hudmessage(200, 255, 255, -1.0, 0.28, 2, 2.0, 1.0, 0.08, 2.5, -1)
		ShowSyncHudMsg(0, g_MsgSync, "%L", LANG_PLAYER, "NOTICE_SURVIVOR", g_playername[forward_id])
		
		// Mode fully started!
		g_modestarted = true
		
		// Round start forward
		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_SURVIVOR, forward_id);
	}
	else if ((mode == MODE_NONE && (!get_pcvar_num(cvar_preventconsecutive) || g_lastmode != MODE_SWARM) && random_num(1, get_pcvar_num(cvar_swarmchance)) == get_pcvar_num(cvar_swarm) && iPlayersnum >= get_pcvar_num(cvar_swarmminplayers)) || mode == MODE_SWARM)
	{		
		// Swarm Mode
		g_swarmround = true
		g_lastmode = MODE_SWARM
		
		// Make sure there are alive players on both teams (BUGFIX)
		/*if (!fnGetAliveTs())
		{
			// Move random player to T team
			id = fnGetRandomAlive(random_num(1, iPlayersnum))
			zp_set_user_team(id, TEAM_TERRORIST)
		}
		else if (!fnGetAliveCTs())
		{
			// Move random player to CT team
			id = fnGetRandomAlive(random_num(1, iPlayersnum))
			zp_set_user_team(id, TEAM_CT)
		}
		
		// Turn every T into a zombie
		for (id = 1; id <= g_maxplayers; id++)
		{
			// Not alive
			if (!g_isalive[id])
				continue;
			
			// Not a Terrorist
			if (zp_get_user_team(id) != TEAM_TERRORIST)
				continue;
			
			// Turn into a zombie
			zombieme(id, 0, 0, 1, 0)
		}*/

		//Инфекция случайных людей 50%
		new iPlayersRandom[32], iNums = get_random_alive_players_by_ratio(TEAM_CT, 0.5, iPlayersRandom, TypeRandom:e_RandomPriority);
		for(new i; i < iNums; i++) zombieme(iPlayersRandom[i], 0, 0, 1, 0, 1)
		
		// Play swarm sound
		ArrayGetString(sound_swarm, random_num(0, ArraySize(sound_swarm) - 1), sound, charsmax(sound))
		PlaySound(sound);
		
		// Show Swarm HUD notice
		set_hudmessage(200, 255, 255, -1.0, 0.28, 2, 2.0, 1.0, 0.08, 2.5, -1)
		ShowSyncHudMsg(0, g_MsgSync, "%L", LANG_PLAYER, "NOTICE_SWARM")
		
		// Mode fully started!
		g_modestarted = true
		
		// Round start forward
		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_SWARM, 0);
	}
	else if ((mode == MODE_NONE && (!get_pcvar_num(cvar_preventconsecutive) || g_lastmode != MODE_MULTI) && random_num(1, get_pcvar_num(cvar_multichance)) == get_pcvar_num(cvar_multi) && floatround(iPlayersnum*get_pcvar_float(cvar_multiratio), floatround_ceil) >= 2 && floatround(iPlayersnum*get_pcvar_float(cvar_multiratio), floatround_ceil) < iPlayersnum && iPlayersnum >= get_pcvar_num(cvar_multiminplayers)) || mode == MODE_MULTI)
	{
		// Multi Infection Mode
		g_lastmode = MODE_MULTI
		
		// iMaxZombies is rounded up, in case there aren't enough players
		/*iMaxZombies = floatround(iPlayersnum*get_pcvar_float(cvar_multiratio), floatround_ceil)
		iZombies = 0
		
		// Randomly turn iMaxZombies players into zombies
		while (iZombies < iMaxZombies)
		{
			// Keep looping through all players
			if (++id > g_maxplayers) id = 1
			
			// Dead or already a zombie
			if (!g_isalive[id] || g_zombie[id])
				continue;
			
			// Random chance
			if (random_num(0, 1))
			{
				// Turn into a zombie
				zombieme(id, 0, 0, 1, 0)
				iZombies++
			}
		}
		
		// Turn the remaining players into humans
		for (id = 1; id <= g_maxplayers; id++)
		{
			// Only those of them who aren't zombies
			if (!g_isalive[id] || g_zombie[id])
				continue;
			
			// Switch to CT
			zp_set_user_team(id, TEAM_CT)
		}*/

		//Мульти-инфекция
		new iPlayersRandom[32], iNums = get_random_alive_players_by_ratio(TEAM_CT, get_pcvar_float(cvar_multiratio), iPlayersRandom, TypeRandom:e_RandomPriority);
		for(new i; i < iNums; i++) zombieme(iPlayersRandom[i], 0, 0, 1, 0, 1)
		
		iHeroes = 0
		
		while (iHeroes < 1 && fnGetAlive() >= 3)
		{
			id = fnGetRandomAlive(random_num(1, fnGetAlive()))
				
			// Dead or already a zombie or survivor
			if (!g_isalive[id] || g_zombie[id] || g_survivor[id] || g_hero[id])
				continue;
				
			// Turn into a hero
			humanme(id, 1, 0, 0)
			iHeroes++
			
			set_dhudmessage(0, 255, 0, 0.04, 0.5, 1, 0.0, 5.0, 1.0, 1.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "NOTICE_HERO", g_playername[id])				
		}
		
		// Play multi infection sound
		ArrayGetString(sound_multi, random_num(0, ArraySize(sound_multi) - 1), sound, charsmax(sound))
		PlaySound(sound);
		
		// Show Multi Infection notice
		set_hudmessage(200, 255, 255, -1.0, 0.28, 2, 2.0, 1.0, 0.08, 2.5, -1)
		ShowSyncHudMsg(0, g_MsgSync, "%L", LANG_PLAYER, "NOTICE_MULTI")
		
		// Mode fully started!
		g_modestarted = true
		
		// Round start forward
		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_MULTI, 0);
	}
	else if ((mode == MODE_NONE && (!get_pcvar_num(cvar_preventconsecutive) || g_lastmode != MODE_PLAGUE) && random_num(1, get_pcvar_num(cvar_plaguechance)) == get_pcvar_num(cvar_plague) && floatround((iPlayersnum-(get_pcvar_num(cvar_plaguenemnum)+get_pcvar_num(cvar_plaguesurvnum)))*get_pcvar_float(cvar_plagueratio), floatround_ceil) >= 1
	&& iPlayersnum-(get_pcvar_num(cvar_plaguesurvnum)+get_pcvar_num(cvar_plaguenemnum)+floatround((iPlayersnum-(get_pcvar_num(cvar_plaguenemnum)+get_pcvar_num(cvar_plaguesurvnum)))*get_pcvar_float(cvar_plagueratio), floatround_ceil)) >= 1 && iPlayersnum >= get_pcvar_num(cvar_plagueminplayers)) || mode == MODE_PLAGUE)
	{
		// Plague Mode
		g_plagueround = true
		g_lastmode = MODE_PLAGUE

		//Инфекция чумы по проценту
		//Получаем массив игроков, которые будут зомби
		new iPlayersNem[32], iNems = get_random_alive_players_by_ratio(TEAM_CT, get_pcvar_float(cvar_plagueratio), iPlayersNem, TypeRandom:e_RandomPriority);

		//Инфекция немезид
		for(new i; i < iNems; i++)
		{
			zombieme(iPlayersNem[i], 0, 1, 0, 0, 1)
			fm_set_user_health(iPlayersNem[i], floatround(float(pev(iPlayersNem[i], pev_health)) * get_pcvar_float(cvar_plaguenemhpmulti)))
		}

		//Делаем нужное количество выживших
		new iPlayersSurv[32], iSurvs = get_alive_players_by_team(TEAM_CT, iPlayersSurv, sizeof iPlayersSurv)
		for(new i; i < iSurvs; i++)
		{
			humanme(iPlayersSurv[i], 0, 1, 0)
			fm_set_user_health(iPlayersSurv[i], floatround(float(pev(iPlayersSurv[i], pev_health)) * get_pcvar_float(cvar_plaguesurvhpmulti)))
		}
		
		// Play plague sound
		ArrayGetString(sound_plague, random_num(0, ArraySize(sound_plague) - 1), sound, charsmax(sound))
		PlaySound(sound);
		
		// Show Plague notice
		set_hudmessage(200, 255, 255, -1.0, 0.28, 2, 2.0, 1.0, 0.08, 2.5, -1)
		ShowSyncHudMsg(0, g_MsgSync, "%L", LANG_PLAYER, "NOTICE_PLAGUE")
		
		// Mode fully started!
		g_modestarted = true
		
		// Round start forward
		ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_PLAGUE, 0);
	}
	else
	{
		// Single Infection Mode or Nemesis Mode
		
		// Choose player randomly?
		if (mode == MODE_NONE)
			id = fnGetRandomAlive(random_num(1, iPlayersnum))
		
		// Remember id for calling our forward later
		forward_id = id
		
		if ((mode == MODE_NONE && (!get_pcvar_num(cvar_preventconsecutive) || g_lastmode != MODE_NEMESIS) && random_num(1, get_pcvar_num(cvar_nemchance)) == get_pcvar_num(cvar_nem) && iPlayersnum >= get_pcvar_num(cvar_nemminplayers)) || mode == MODE_NEMESIS)
		{
			// Nemesis Mode
			g_nemround = true
			g_lastmode = MODE_NEMESIS
			
			// Turn player into nemesis
			zombieme(id, 0, 1, 0, 0, 1)
		}
		else
		{
			// Single Infection Mode
			g_lastmode = MODE_INFECTION
			
			if(mode == MODE_NONE)
			{
				//Обычная инфекция
				new iPlayersRandom[32], iNums = get_random_alive_players_by_ratio(TEAM_CT, FIRSTZOMBIE_PERCENT, iPlayersRandom, TypeRandom:e_RandomPriority);
				for(new i; i < iNums; i++)
					zombieme(iPlayersRandom[i], 0, 0, 0, 0, 1, true)
			}
			else
			{
				// Turn player into the first zombie
				zombieme(id, 0, 0, 0, 0, 1)
			}
		}
		
		// Remaining players should be humans (CTs)
		for (id = 1; id <= g_maxplayers; id++)
		{
			// Not alive
			if (!g_isalive[id])
				continue;
			
			// First zombie/nemesis
			if (g_zombie[id])
				continue;
			
			// Switch to CT
			zp_set_user_team(id, TEAM_CT)
		}
		
		if (g_nemround)
		{
			// Play Nemesis sound
			ArrayGetString(sound_nemesis, random_num(0, ArraySize(sound_nemesis) - 1), sound, charsmax(sound))
			PlaySound(sound);
			
			// Show Nemesis notice
			set_hudmessage(200, 255, 255, -1.0, 0.28, 2, 2.0, 1.0, 0.08, 2.5, -1)
			ShowSyncHudMsg(0, g_MsgSync, "%L", LANG_PLAYER, "NOTICE_NEMESIS", g_playername[forward_id])
			
			// Mode fully started!
			g_modestarted = true
			
			// Round start forward
			ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_NEMESIS, forward_id);
		}
		else
		{
			iHeroes = 0
			
			while (iHeroes < 1 && fnGetAlive() >= 3)
			{
				id = fnGetRandomAlive(random_num(1, fnGetAlive()))
				
				// Dead or already a zombie or survivor
				if (!g_isalive[id] || g_zombie[id] || g_survivor[id] || g_hero[id])
					continue;
				
				// Turn into a hero
				humanme(id, 1, 0, 0)
				iHeroes++
			
				set_dhudmessage(0, 255, 0, 0.04, 0.5, 1, 0.0, 5.0, 1.0, 1.0)
				show_dhudmessage(0, "%L", LANG_PLAYER, "NOTICE_HERO", g_playername[id])				
			}
			
			// Mode fully started!
			g_modestarted = true
			
			// Round start forward
			ExecuteForward(g_fwRoundStart, g_fwDummyResult, MODE_INFECTION, forward_id);
		}
	}
	
	// Start ambience sounds after a mode begins
	if ((g_ambience_sounds[AMBIENCE_SOUNDS_NEMESIS] && g_nemround) || (g_ambience_sounds[AMBIENCE_SOUNDS_SURVIVOR] && g_survround) || (g_ambience_sounds[AMBIENCE_SOUNDS_SWARM] && g_swarmround) || (g_ambience_sounds[AMBIENCE_SOUNDS_PLAGUE] && g_plagueround) || (g_ambience_sounds[AMBIENCE_SOUNDS_INFECTION] && !g_nemround && !g_survround && !g_swarmround && !g_plagueround))
	{
		remove_task(TASK_AMBIENCESOUNDS)
		set_task(2.0, "ambience_sound_effects", TASK_AMBIENCESOUNDS)
	}
}

// Zombie Me Function (player id, infector, turn into a nemesis, silent mode, deathmsg and rewards)
zombieme(id, infector, nemesis, silentmode, rewards, teleport = 0, bool:first = false)
{
	// User infect attempt forward
	ExecuteForward(g_fwUserInfect_attempt, g_fwDummyResult, id, infector, nemesis)
	
	// One or more plugins blocked the infection. Only allow this after making sure it's
	// not going to leave us with no zombies. Take into account a last player leaving case.
	// BUGFIX: only allow after a mode has started, to prevent blocking first zombie e.g.
	if (g_fwDummyResult >= ZP_PLUGIN_HANDLED && g_modestarted && fnGetZombies() > g_lastplayerleaving)
		return;
	
	// Pre user infect forward
	ExecuteForward(g_fwUserInfected_pre, g_fwDummyResult, id, infector, nemesis)
	
	// Set selected zombie class
	g_zombieclass[id] = g_zombieclassnext[id]
	
	if(is_user_bot(id))
	{
		g_zombieclass[id] = random_num(0, 5)
	}
	
	if(g_zombieclass[id] == 6 && !(get_user_flags(id) & ADMIN_LEVEL_H))
	{
		g_zombieclass[id] = 0;
	}
	
	if(g_zombieclass[id] == 7 && !(get_user_flags(id) & ADMIN_LEVEL_D))
	{
		g_zombieclass[id] = 0;
	}
	
	// Way to go...
	g_zombie[id] = true
	g_nemesis[id] = false
	g_survivor[id] = false
	g_hero[id] = false
	g_firstzombie[id] = first

	//Телепортация на спавн, если нету инфектора
	if(teleport) zp_user_spawn(id);

	
	// Remove survivor's aura (bugfix)
	set_pev(id, pev_effects, pev(id, pev_effects) &~ EF_BRIGHTLIGHT)
	
	// Set zombie max health
	set_pev(id, pev_max_health, float(ArrayGetCell(g_zclass_maxhp, g_zombieclass[id])))
	
	// Remove spawn protection (bugfix)
	set_entvar(id, var_takedamage, DAMAGE_AIM);
	
	// Reset burning duration counter (bugfix)
	//g_burning_duration[id] = 0
	
	// Show deathmsg and reward infector?
	if (rewards && infector)
	{
		// Send death notice and fix the "dead" attrib on scoreboard
		SendDeathMsg(infector, id)
		FixDeadAttrib(id)
		
		// Reward frags, deaths, health, and ammo packs
		UpdateFrags(infector, id, get_pcvar_num(cvar_fragsinfect), 1, 1)
		g_ammopacks[infector] += get_pcvar_num(cvar_ammoinfect)
		
		if(get_user_flags(infector) & ADMIN_LEVEL_H)
			fm_set_user_health(infector, pev(infector, pev_health) + get_pcvar_num(cvar_zombiebonushp_vip))
		else
			fm_set_user_health(infector, pev(infector, pev_health) + get_pcvar_num(cvar_zombiebonushp))
	}
	
	// Cache speed, knockback, and name for player's classname
	g_zombie_spd[id] = float(ArrayGetCell(g_zclass_spd, g_zombieclass[id]))
	//g_zombie_knockback[id] = Float:ArrayGetCell(g_zclass_kb, g_zombieclass[id])
	ArrayGetString(g_zclass_name, g_zombieclass[id], g_zombie_classname[id], charsmax(g_zombie_classname[]))
	
	// Set zombie attributes based on the mode
	static sound[64]
	if (!silentmode)
	{
		if (nemesis)
		{
			// Nemesis
			g_nemesis[id] = true
			
			// Set health [0 = auto]
			if (get_pcvar_num(cvar_nemhp) == 0)
			{
				if (get_pcvar_num(cvar_nembasehp) == 0)
					//fm_set_user_health(id, ArrayGetCell(g_zclass_hp, 0) * fnGetAlive())
					fm_set_user_health(id, 1000 * fnGetAlive())
				else
					fm_set_user_health(id, get_pcvar_num(cvar_nembasehp) * fnGetAlive())
			}
			else
				fm_set_user_health(id, get_pcvar_num(cvar_nemhp))
			
			// Set gravity
			set_pev(id, pev_gravity, get_pcvar_float(cvar_nemgravity))
		}
		else if (g_firstzombie[id])
		{
			// First zombie
			// g_firstzombie[id] = true
			
			// Set health
			fm_set_user_health(id, floatround(float(ArrayGetCell(g_zclass_hp, g_zombieclass[id])) + get_pcvar_num(cvar_zombiefirsthp) * fnGetAlive()))
			set_pev(id, pev_max_health, float(ArrayGetCell(g_zclass_maxhp, g_zombieclass[id])))
			
			// Set gravity
			set_pev(id, pev_gravity, Float:ArrayGetCell(g_zclass_grav, g_zombieclass[id]))
			
			// Infection sound
			static pointers[10], end
			ArrayGetArray(pointer_class_sound_infect, g_zombieclass[id], pointers)
			
			for (new i; i < 10; i++)
			{
				if (pointers[i] != -1)
				end = i
			}
			ArrayGetString(class_sound_infect, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
			emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		else
		{
			// Infected by someone
			
			// Set health
			fm_set_user_health(id, ArrayGetCell(g_zclass_hp, g_zombieclass[id]))
			set_pev(id, pev_max_health, float(ArrayGetCell(g_zclass_maxhp, g_zombieclass[id])))
			
			// Set gravity
			set_pev(id, pev_gravity, Float:ArrayGetCell(g_zclass_grav, g_zombieclass[id]))
			
			// Infection sound
			static pointers[10], end
			ArrayGetArray(pointer_class_sound_infect, g_zombieclass[id], pointers)
			
			for (new i; i < 10; i++)
			{
				if (pointers[i] != -1)
				end = i
			}
			ArrayGetString(class_sound_infect, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
			emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			// Infection sound advanced
			static pointers_adv[10], end_adv
			ArrayGetArray(pointer_class_sound_infect_adv, g_zombieclass[id], pointers_adv)
			
			for (new i_adv; i_adv < 10; i_adv++)
			{
				if (pointers_adv[i_adv] != -1)
				end_adv = i_adv
			}
			ArrayGetString(class_sound_infect_adv, random_num(pointers_adv[0], pointers_adv[end_adv]), sound, charsmax(sound))
			emit_sound(id, CHAN_AUTO, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			// Show Infection HUD notice
			//set_hudmessage(255, 0, 0, HUD_INFECT_X, HUD_INFECT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
		}
	}
	else
	{
		// Silent mode, no HUD messages, no infection sounds
		
		// Set health
		fm_set_user_health(id, ArrayGetCell(g_zclass_hp, g_zombieclass[id]))
		set_pev(id, pev_max_health, float(ArrayGetCell(g_zclass_maxhp, g_zombieclass[id])))
		
		// Set gravity
		set_pev(id, pev_gravity, Float:ArrayGetCell(g_zclass_grav, g_zombieclass[id]))
	}

	// Set zombie maxspeed
	//set_player_maxspeed(id);
	
	// Remove previous tasks
	remove_task(id+TASK_MODEL)
	remove_task(id+TASK_BLOOD)
	remove_task(id+TASK_AURA)

	// Switch to T
	zp_set_user_team(id, TEAM_TERRORIST)
	
	// Custom models stuff
	zp_set_user_zombie_model(id);
	
	// Remove any zoom (bugfix)
	cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
	
	// Remove armor
	cs_set_user_armor(id, 0, CS_ARMOR_NONE)
	
	// Drop weapons when infected
	// drop_weapons(id, 1)
	// drop_weapons(id, 2)
	
	// UTIL_StripWeapon(id, 1)
	// UTIL_StripWeapon(id, 2)	
	
	// Strip zombies from guns and give them a knife
	//fm_strip_user_weapons(id)
	//fm_give_item(id, "weapon_knife")
	new const InventorySlotType:g_iRemoveSlots[] = {PRIMARY_WEAPON_SLOT, PISTOL_SLOT, GRENADE_SLOT, C4_SLOT}
	for(new iSlot, iSize = sizeof g_iRemoveSlots; iSlot < iSize; iSlot++)
		rg_remove_items_by_slot(id, g_iRemoveSlots[iSlot]);
	
	//Показать нож
	new pItem = get_member(id, m_rgpPlayerItems, KNIFE_SLOT)
	if(!is_nullent(pItem)) ExecuteHamB(Ham_Item_Deploy, pItem);

	// Fancy effects
	infection_effects(id)
	
	// Nemesis aura task
	if (g_nemesis[id] && get_pcvar_num(cvar_nemaura))
		set_task(0.1, "zombie_aura", id+TASK_AURA, _, _, "b")
	
	// Remove CS nightvision if player owns one (bugfix)
	if (cs_get_user_nvg(id))
	{
		cs_set_user_nvg(id, 0)
		if (get_pcvar_num(cvar_customnvg)) remove_task(id+TASK_NVISION)
		else if (g_nvisionenabled[id]) set_user_gnvision(id, 0)
	}
	
	// Give Zombies Night Vision?
	if (get_pcvar_num(cvar_nvggive))
	{
		g_nvision[id] = true
		
		if (!g_isbot[id])
		{
			// Turn on Night Vision automatically?
			if (get_pcvar_num(cvar_nvggive) == 1)
			{
				g_nvisionenabled[id] = true
				
				// Custom nvg?
				if (get_pcvar_num(cvar_customnvg))
				{
					remove_task(id+TASK_NVISION)
					set_task(0.1, "set_user_nvision", id+TASK_NVISION, _, _, "b")
				}
				else
					set_user_gnvision(id, 1)
			}
			// Turn off nightvision when infected (bugfix)
			else if (g_nvisionenabled[id])
			{
				if (get_pcvar_num(cvar_customnvg)) remove_task(id+TASK_NVISION)
				else set_user_gnvision(id, 0)
				g_nvisionenabled[id] = false
			}
		}
		else
			cs_set_user_nvg(id, 1); // turn on NVG for bots
	}
	// Disable nightvision when infected (bugfix)
	else if (g_nvision[id])
	{
		if (get_pcvar_num(cvar_customnvg)) remove_task(id+TASK_NVISION)
		else if (g_nvisionenabled[id]) set_user_gnvision(id, 0)
		g_nvision[id] = false
		g_nvisionenabled[id] = false
	}
	
	// Call the bloody task
	if (!g_nemesis[id] && get_pcvar_num(cvar_zombiebleeding))
		set_task(0.7, "make_blood", id+TASK_BLOOD, _, _, "b")
	
	// Idle sounds task
	if (!g_nemesis[id])
		set_task(random_float(50.0, 70.0), "zombie_play_idle", id+TASK_BLOOD, _, _, "b")
	
	// Turn off zombie's flashlight
	turn_off_flashlight(id)
	
	// Post user infect forward
	ExecuteForward(g_fwUserInfected_post, g_fwDummyResult, id, infector, nemesis)
	
	// Last Zombie Check
	fnCheckLastZombie()
}

// Function Human Me (player id, turn into a survivor, silent mode)
humanme(id, hero, survivor, silentmode)
{
	// User humanize attempt forward
	ExecuteForward(g_fwUserHumanize_attempt, g_fwDummyResult, id, survivor)
	
	// One or more plugins blocked the "humanization". Only allow this after making sure it's
	// not going to leave us with no humans. Take into account a last player leaving case.
	// BUGFIX: only allow after a mode has started, to prevent blocking first survivor e.g.
	if (g_fwDummyResult >= ZP_PLUGIN_HANDLED && g_modestarted && fnGetHumans() > g_lastplayerleaving)
		return;
	
	// Pre user humanize forward
	ExecuteForward(g_fwUserHumanized_pre, g_fwDummyResult, id, survivor)
	
	// Remove previous tasks
	remove_task(id+TASK_MODEL)
	remove_task(id+TASK_BLOOD)
	remove_task(id+TASK_AURA)
	remove_task(id+TASK_NVISION)
	
	// Reset some vars
	g_zombie[id] = false
	g_nemesis[id] = false
	g_survivor[id] = false
	g_firstzombie[id] = false
	g_hero[id] = false
	g_canbuy[id] = true
	g_buytime[id] = get_gametime()
	
	// Remove survivor's aura (bugfix)
	set_pev(id, pev_effects, pev(id, pev_effects) &~ EF_BRIGHTLIGHT)
	
	// Remove spawn protection (bugfix)
	set_entvar(id, var_takedamage, DAMAGE_AIM)
	
	// Reset burning duration counter (bugfix)
	//g_burning_duration[id] = 0
	
	// Remove CS nightvision if player owns one (bugfix)
	if (cs_get_user_nvg(id))
	{
		cs_set_user_nvg(id, 0)
		if (get_pcvar_num(cvar_customnvg)) remove_task(id+TASK_NVISION)
		else if (g_nvisionenabled[id]) set_user_gnvision(id, 0)
	}
	
	// Drop previous weapons
	// drop_weapons(id, 1)
	// drop_weapons(id, 2)
	
	// Strip off from weapons
	// fm_strip_user_weapons(id)
	// fm_give_item(id, "weapon_knife")
	new const InventorySlotType:g_iRemoveSlots[] = {PRIMARY_WEAPON_SLOT, PISTOL_SLOT}
	for(new iSlot, iSize = sizeof g_iRemoveSlots; iSlot < iSize; iSlot++)
		rg_remove_items_by_slot(id, g_iRemoveSlots[iSlot]);


	// Set human attributes based on the mode
	if (survivor)
	{
		// Survivor
		g_survivor[id] = true

		new const InventorySlotType:g_iRemoveSlots[] = {GRENADE_SLOT, C4_SLOT}
		for(new iSlot, iSize = sizeof g_iRemoveSlots; iSlot < iSize; iSlot++)
			rg_remove_items_by_slot(id, g_iRemoveSlots[iSlot]);
		
		// Set Health [0 = auto]
		if (get_pcvar_num(cvar_survhp) == 0)
		{
			if (get_pcvar_num(cvar_survbasehp) == 0)
				fm_set_user_health(id, get_pcvar_num(cvar_humanhp) * fnGetAlive())
			else
				fm_set_user_health(id, get_pcvar_num(cvar_survbasehp) * fnGetAlive())
		}
		else
			fm_set_user_health(id, get_pcvar_num(cvar_survhp))
		
		// Set gravity
		set_pev(id, pev_gravity, get_pcvar_float(cvar_survgravity))
		
		// Turn off his flashlight
		turn_off_flashlight(id)
		
		// Give the survivor a bright light
		if (get_pcvar_num(cvar_survaura)) set_pev(id, pev_effects, pev(id, pev_effects) | EF_BRIGHTLIGHT)
		
		// Survivor bots will also need nightvision to see in the dark
		if (g_isbot[id])
		{
			g_nvision[id] = true
			cs_set_user_nvg(id, 1)
		}

		set_member(id, m_iWeaponInfiniteAmmo, get_pcvar_num(cvar_survinfammo));
	}
	else if (hero)
	{
		g_hero[id] = true
				
		// Set Health
		fm_set_user_health(id, 200)
		
		if(pev(id, pev_armorvalue) < 50.0)
			set_pev(id, pev_armorvalue, 50.0)
		
		// Set gravity, if frozen set the restore gravity value instead
		set_pev(id, pev_gravity, get_pcvar_float(cvar_humangravity))
		
		// Give weapons
		zp_give_user_svdex(id);
		zp_give_user_infinityr(id);

		set_member(id, m_iWeaponInfiniteAmmo, get_pcvar_num(cvar_infammo));
	}
	else
	{
		
		// Set health
		fm_set_user_health(id, get_pcvar_num(cvar_humanhp))
		
		// Set gravity
		set_pev(id, pev_gravity, get_pcvar_float(cvar_humangravity))
		
		// Set human maxspeed
		set_player_maxspeed(id);
		
		// Show custom buy menu?
		/*if(get_pcvar_num(cvar_buycustom))
		{
			set_task(0.2, "show_menu_buy1", id+TASK_SPAWN)
		}*/
		
		// Silent mode = no HUD messages, no antidote sound
		if (!silentmode)
		{
			// Antidote sound
			static sound[64]
			ArrayGetString(sound_antidote, random_num(0, ArraySize(sound_antidote) - 1), sound, charsmax(sound))
			emit_sound(id, CHAN_ITEM, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}

		set_member(id, m_iWeaponInfiniteAmmo, get_pcvar_num(cvar_infammo));
	}
	
	// Set survivor maxspeed
	set_player_maxspeed(id);

	// Switch to CT
	zp_set_user_team(id, TEAM_CT)
	
	// Custom models stuff
	zp_set_user_human_model(id);
	
	// Disable nightvision when turning into human/survivor (bugfix)
	if (g_nvision[id])
	{
		if (get_pcvar_num(cvar_customnvg)) remove_task(id+TASK_NVISION)
		else if (g_nvisionenabled[id]) set_user_gnvision(id, 0)
		g_nvision[id] = false
		g_nvisionenabled[id] = false
	}

	// Post user humanize forward
	ExecuteForward(g_fwUserHumanized_post, g_fwDummyResult, id, survivor)
	
	// Last Zombie Check
	fnCheckLastZombie()
}

/*================================================================================
 [Other Functions and Tasks]
=================================================================================*/

public cache_cvars()
{
	g_cached_zombiesilent = get_pcvar_num(cvar_zombiesilent)
	g_cached_customflash = get_pcvar_num(cvar_customflash)
	g_cached_leapzombies = get_pcvar_num(cvar_leapzombies)
	g_cached_leapzombiescooldown = get_pcvar_float(cvar_leapzombiescooldown)
	g_cached_leapnemesis = get_pcvar_num(cvar_leapnemesis)
	g_cached_leapnemesiscooldown = get_pcvar_float(cvar_leapnemesiscooldown)
	g_cached_leapsurvivor = get_pcvar_num(cvar_leapsurvivor)
	g_cached_leapsurvivorcooldown = get_pcvar_float(cvar_leapsurvivorcooldown)
	g_cached_buytime = get_pcvar_float(cvar_buyzonetime)
}

load_customization_from_files()
{
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/zpe_mode/%s", path, ZP_CUSTOMIZATION_FILE)
	
	// File not present
	if (!file_exists(path))
	{
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
		set_fail_state(error)
		return;
	}
	
	// Set up some vars to hold parsing info
	new linedata[1024], key[64], value[960], section, teams
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	while (file && !feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// New section starting
		if (linedata[0] == '[')
		{
			section++
			continue;
		}
		
		// Get key and value(s)
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
		
		// Trim spaces
		trim(key)
		trim(value)
		
		switch (section)
		{
			case SECTION_ACCESS_FLAGS:
			{
				if (equal(key, "ENABLE/DISABLE MOD"))
					g_access_flag[ACCESS_ENABLE_MOD] = read_flags(value)
				else if (equal(key, "ADMIN MENU"))
					g_access_flag[ACCESS_ADMIN_MENU] = read_flags(value)
				else if (equal(key, "START MODE INFECTION"))
					g_access_flag[ACCESS_MODE_INFECTION] = read_flags(value)
				else if (equal(key, "START MODE NEMESIS"))
					g_access_flag[ACCESS_MODE_NEMESIS] = read_flags(value)
				else if (equal(key, "START MODE SURVIVOR"))
					g_access_flag[ACCESS_MODE_SURVIVOR] = read_flags(value)
				else if (equal(key, "START MODE SWARM"))
					g_access_flag[ACCESS_MODE_SWARM] = read_flags(value)
				else if (equal(key, "START MODE MULTI"))
					g_access_flag[ACCESS_MODE_MULTI] = read_flags(value)
				else if (equal(key, "START MODE PLAGUE"))
					g_access_flag[ACCESS_MODE_PLAGUE] = read_flags(value)
				else if (equal(key, "MAKE ZOMBIE"))
					g_access_flag[ACCESS_MAKE_ZOMBIE] = read_flags(value)
				else if (equal(key, "MAKE HUMAN"))
					g_access_flag[ACCESS_MAKE_HUMAN] = read_flags(value)
				else if (equal(key, "MAKE NEMESIS"))
					g_access_flag[ACCESS_MAKE_NEMESIS] = read_flags(value)
				else if (equal(key, "MAKE SURVIVOR"))
					g_access_flag[ACCESS_MAKE_SURVIVOR] = read_flags(value)
				else if (equal(key, "RESPAWN PLAYERS"))
					g_access_flag[ACCESS_RESPAWN_PLAYERS] = read_flags(value)
			}
			case SECTION_PLAYER_MODELS:
			{
				if (equal(key, "NEMESIS"))
				{
					// Parse models
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to models array
						ArrayPushString(model_nemesis, key)
					}
				}
				else if (equal(key, "FORCE CONSISTENCY"))
					g_force_consistency = str_to_num(value)
				else if (equal(key, "SAME MODELS FOR ALL"))
					g_same_models_for_all = str_to_num(value)
				else if (g_same_models_for_all && equal(key, "ZOMBIE"))
				{
					// Parse models
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to models array
						ArrayPushString(g_zclass_playermodel, key)
						
						// Precache model and retrieve its modelindex
						formatex(linedata, charsmax(linedata), "models/player/%s/%s.mdl", key, key)
						ArrayPushCell(g_zclass_modelindex, engfunc(EngFunc_PrecacheModel, linedata))
						if (g_force_consistency == 1) force_unmodified(force_model_samebounds, {0,0,0}, {0,0,0}, linedata)
						if (g_force_consistency == 2) force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, linedata)
						// Precache modelT.mdl files too
						copy(linedata[strlen(linedata)-4], charsmax(linedata) - (strlen(linedata)-4), "T.mdl")
						if (file_exists(linedata)) engfunc(EngFunc_PrecacheModel, linedata)
					}
				}
			}
			case SECTION_WEAPON_MODELS:
			{
				if (equal(key, "V_KNIFE NEMESIS"))
					copy(model_vknife_nemesis, charsmax(model_vknife_nemesis), value)
			}
			case SECTION_GRENADE_SPRITES:
			{
				if (equal(key, "FIRE"))
					copy(sprite_grenade_fire, charsmax(sprite_grenade_fire), value)
				else if (equal(key, "SMOKE"))
					copy(sprite_grenade_smoke, charsmax(sprite_grenade_smoke), value)
				else if (equal(key, "WATERGUN FIRE"))
					copy(sprite_fire_watergun, charsmax(sprite_fire_watergun), value)
			}
			case SECTION_SOUNDS:
			{
				if (equal(key, "WIN ZOMBIES"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_win_zombies, key)
						ArrayPushCell(sound_win_zombies_ismp3, equal(key[strlen(key)-4], ".mp3") ? 1 : 0)
					}
				}
				else if (equal(key, "WIN HUMANS"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_win_humans, key)
						ArrayPushCell(sound_win_humans_ismp3, equal(key[strlen(key)-4], ".mp3") ? 1 : 0)
					}
				}
				else if (equal(key, "WIN NO ONE"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_win_no_one, key)
						ArrayPushCell(sound_win_no_one_ismp3, equal(key[strlen(key)-4], ".mp3") ? 1 : 0)
					}
				}
				else if (equal(key, "NEMESIS PAIN"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
								
						// Add to sounds array
						ArrayPushString(nemesis_pain, key)
					}
				}
				else if (equal(key, "NEMESIS IDLE"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
								
						// Add to sounds array
						ArrayPushString(nemesis_idle, key)
					}
				}
				else if (equal(key, "NEMESIS DIE"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
								
						// Add to sounds array
						ArrayPushString(nemesis_die, key)
					}
				}
				else if (equal(key, "NEMESIS FALL"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
								
						// Add to sounds array
						ArrayPushString(nemesis_fall, key)
					}
				}
				else if (equal(key, "NEMESIS MISS SLASH"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
								
						// Add to sounds array
						ArrayPushString(nemesis_miss_slash, key)
					}
				}
				else if (equal(key, "NEMESIS MISS WALL"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
								
						// Add to sounds array
						ArrayPushString(nemesis_miss_wall, key)
					}
				}
				else if (equal(key, "NEMESIS HIT NORMAL"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
								
						// Add to sounds array
						ArrayPushString(nemesis_hit_normal, key)
					}
				}
				else if (equal(key, "NEMESIS HIT STAB"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
								
						// Add to sounds array
						ArrayPushString(nemesis_hit_stab, key)
					}
				}
				else if (equal(key, "ROUND NEMESIS"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_nemesis, key)
					}
				}
				else if (equal(key, "ROUND SURVIVOR"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_survivor, key)
					}
				}
				else if (equal(key, "ROUND SWARM"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_swarm, key)
					}
				}
				else if (equal(key, "ROUND MULTI"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_multi, key)
					}
				}
				else if (equal(key, "ROUND PLAGUE"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_plague, key)
					}
				}
				else if (equal(key, "ANTIDOTE"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_antidote, key)
					}
				}
			}
			case SECTION_AMBIENCE_SOUNDS:
			{
				if (equal(key, "INFECTION ENABLE"))
					g_ambience_sounds[AMBIENCE_SOUNDS_INFECTION] = str_to_num(value)
				else if (g_ambience_sounds[AMBIENCE_SOUNDS_INFECTION] && equal(key, "INFECTION SOUNDS"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_ambience1, key)
						ArrayPushCell(sound_ambience1_ismp3, equal(key[strlen(key)-4], ".mp3") ? 1 : 0)
					}
				}
				else if (g_ambience_sounds[AMBIENCE_SOUNDS_INFECTION] && equal(key, "INFECTION DURATIONS"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushCell(sound_ambience1_duration, str_to_num(key))
					}
				}
				else if (equal(key, "NEMESIS ENABLE"))
					g_ambience_sounds[AMBIENCE_SOUNDS_NEMESIS] = str_to_num(value)
				else if (g_ambience_sounds[AMBIENCE_SOUNDS_NEMESIS] && equal(key, "NEMESIS SOUNDS"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_ambience2, key)
						ArrayPushCell(sound_ambience2_ismp3, equal(key[strlen(key)-4], ".mp3") ? 1 : 0)
					}
				}
				else if (g_ambience_sounds[AMBIENCE_SOUNDS_NEMESIS] && equal(key, "NEMESIS DURATIONS"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushCell(sound_ambience2_duration, str_to_num(key))
					}
				}
				else if (equal(key, "SURVIVOR ENABLE"))
					g_ambience_sounds[AMBIENCE_SOUNDS_SURVIVOR] = str_to_num(value)
				else if (g_ambience_sounds[AMBIENCE_SOUNDS_SURVIVOR] && equal(key, "SURVIVOR SOUNDS"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_ambience3, key)
						ArrayPushCell(sound_ambience3_ismp3, equal(key[strlen(key)-4], ".mp3") ? 1 : 0)
					}
				}
				else if (g_ambience_sounds[AMBIENCE_SOUNDS_SURVIVOR] && equal(key, "SURVIVOR DURATIONS"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushCell(sound_ambience3_duration, str_to_num(key))
					}
				}
				else if (equal(key, "SWARM ENABLE"))
					g_ambience_sounds[AMBIENCE_SOUNDS_SWARM] = str_to_num(value)
				else if (g_ambience_sounds[AMBIENCE_SOUNDS_SWARM] && equal(key, "SWARM SOUNDS"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_ambience4, key)
						ArrayPushCell(sound_ambience4_ismp3, equal(key[strlen(key)-4], ".mp3") ? 1 : 0)
					}
				}
				else if (g_ambience_sounds[AMBIENCE_SOUNDS_SWARM] && equal(key, "SWARM DURATIONS"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushCell(sound_ambience4_duration, str_to_num(key))
					}
				}
				else if (equal(key, "PLAGUE ENABLE"))
					g_ambience_sounds[AMBIENCE_SOUNDS_PLAGUE] = str_to_num(value)
				else if (g_ambience_sounds[AMBIENCE_SOUNDS_PLAGUE] && equal(key, "PLAGUE SOUNDS"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_ambience5, key)
						ArrayPushCell(sound_ambience5_ismp3, equal(key[strlen(key)-4], ".mp3") ? 1 : 0)
					}
				}
				else if (g_ambience_sounds[AMBIENCE_SOUNDS_PLAGUE] && equal(key, "PLAGUE DURATIONS"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushCell(sound_ambience5_duration, str_to_num(key))
					}
				}
			}
			case SECTION_BUY_MENU_WEAPONS:
			{
				if (equal(key, "PRIMARY"))
				{
					// Parse weapons
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(g_primary_items, key)
						ArrayPushCell(g_primary_weaponids, cs_weapon_name_to_id(key))
					}
				}
				else if (equal(key, "SECONDARY"))
				{
					// Parse weapons
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(g_secondary_items, key)
						ArrayPushCell(g_secondary_weaponids, cs_weapon_name_to_id(key))
					}
				}
			}
			case SECTION_EXTRA_ITEMS_WEAPONS:
			{
				if (equal(key, "NAMES"))
				{
					// Parse weapon items
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(g_extraweapon_names, key)
					}
				}
				else if (equal(key, "ITEMS"))
				{
					// Parse weapon items
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(g_extraweapon_items, key)
					}
				}
				else if (equal(key, "COSTS"))
				{
					// Parse weapon items
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushCell(g_extraweapon_costs, str_to_num(key))
					}
				}
			}
			case SECTION_HARD_CODED_ITEMS_COSTS:
			{
				if (equal(key, "NIGHT VISION"))
					g_extra_costs2[EXTRA_NVISION] = str_to_num(value)
				else if (equal(key, "ANTIDOTE"))
					g_extra_costs2[EXTRA_ANTIDOTE] = str_to_num(value)
				else if (equal(key, "ZOMBIE MADNESS"))
					g_extra_costs2[EXTRA_MADNESS] = str_to_num(value)
			}
			case SECTION_WEATHER_EFFECTS:
			{
				if (equal(key, "RAIN"))
					g_ambience_rain = str_to_num(value)
				else if (equal(key, "SNOW"))
					g_ambience_snow = str_to_num(value)
				else if (equal(key, "FOG"))
					g_ambience_fog = str_to_num(value)
				else if (equal(key, "FOG DENSITY"))
					copy(g_fog_density, charsmax(g_fog_density), value)
				else if (equal(key, "FOG COLOR"))
					copy(g_fog_color, charsmax(g_fog_color), value)
			}
			case SECTION_SKY:
			{
				if (equal(key, "ENABLE"))
					g_sky_enable = str_to_num(value)
				else if (equal(key, "SKY NAMES"))
				{
					// Parse sky names
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to skies array
						ArrayPushString(g_sky_names, key)
						
						// Preache custom sky files
						formatex(linedata, charsmax(linedata), "gfx/env/%sbk.tga", key)
						engfunc(EngFunc_PrecacheGeneric, linedata)
						formatex(linedata, charsmax(linedata), "gfx/env/%sdn.tga", key)
						engfunc(EngFunc_PrecacheGeneric, linedata)
						formatex(linedata, charsmax(linedata), "gfx/env/%sft.tga", key)
						engfunc(EngFunc_PrecacheGeneric, linedata)
						formatex(linedata, charsmax(linedata), "gfx/env/%slf.tga", key)
						engfunc(EngFunc_PrecacheGeneric, linedata)
						formatex(linedata, charsmax(linedata), "gfx/env/%srt.tga", key)
						engfunc(EngFunc_PrecacheGeneric, linedata)
						formatex(linedata, charsmax(linedata), "gfx/env/%sup.tga", key)
						engfunc(EngFunc_PrecacheGeneric, linedata)
					}
				}
			}
			case SECTION_ZOMBIE_DECALS:
			{
				if (equal(key, "DECALS"))
				{
					// Parse decals
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to zombie decals array
						ArrayPushCell(zombie_decals, str_to_num(key))
					}
				}
			}
			case SECTION_OBJECTIVE_ENTS:
			{
				if (equal(key, "CLASSNAMES"))
				{
					// Parse classnames
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to objective ents array
						ArrayPushString(g_objective_ents, key)
					}
				}
			}
			case SECTION_SVC_BAD:
			{
				if (equal(key, "MODELCHANGE DELAY"))
					g_modelchange_delay = str_to_float(value)
				else if (equal(key, "HANDLE MODELS ON SEPARATE ENT"))
					g_handle_models_on_separate_ent = str_to_num(value)
				else if (equal(key, "SET MODELINDEX OFFSET"))
					g_set_modelindex_offset = str_to_num(value)
			}
		}
	}
	if (file) fclose(file)
	
	// Build zombie classes file path
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/zpe_mode/%s", path, ZP_ZOMBIECLASSES_FILE)
	
	// Parse if present
	if (file_exists(path))
	{
		// Open zombie classes file for reading
		file = fopen(path, "rt")
		
		while (file && !feof(file))
		{
			static pos, temparr[64]

			// Read one line at a time
			fgets(file, linedata, charsmax(linedata))
			
			// Replace newlines with a null character to prevent headaches
			replace(linedata, charsmax(linedata), "^n", "")
			
			// Blank line or comment
			if (!linedata[0] || linedata[0] == ';') continue;
			
			// New class starting
			if (linedata[0] == '[')
			{
				// Remove first and last characters (braces)
				linedata[strlen(linedata) - 1] = 0
				copy(linedata, charsmax(linedata), linedata[1])
				
				// Store its real name for future reference
				ArrayPushString(g_zclass2_realname, linedata)
				continue;
			}
			
			// Get key and value(s)
			strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
			
			// Trim spaces
			trim(key)
			trim(value)
			
			if (equal(key, "NAME"))
				ArrayPushString(g_zclass2_name, value)
			else if (equal(key, "INFO"))
				ArrayPushString(g_zclass2_info, value)
			else if (equal(key, "MODELS"))
			{
				// Set models start index
				ArrayPushCell(g_zclass2_modelsstart, ArraySize(g_zclass2_playermodel))
				
				// Parse class models
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					// Add to class models array
					ArrayPushString(g_zclass2_playermodel, key)
					ArrayPushCell(g_zclass2_modelindex, -1)
				}
				
				// Set models end index
				ArrayPushCell(g_zclass2_modelsend, ArraySize(g_zclass2_playermodel))
			}
			else if (equal(key, "CLAWMODEL"))
				ArrayPushString(g_zclass2_clawmodel, value)
			else if (equal(key, "HEALTH"))
				ArrayPushCell(g_zclass2_hp, str_to_num(value))
			else if (equal(key, "MAX HEALTH"))
				ArrayPushCell(g_zclass2_maxhp, str_to_num(value))
			else if (equal(key, "SPEED"))
				ArrayPushCell(g_zclass2_spd, str_to_num(value))
			else if (equal(key, "GRAVITY"))
				ArrayPushCell(g_zclass2_grav, str_to_float(value))
			else if (equal(key, "KNOCKBACK"))
				ArrayPushCell(g_zclass2_kb, str_to_float(value))
			else if (equal(key, "INFECT"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
			
					ArrayPushString(class_sound_infect, key)
					temparr[pos++] = ArraySize(class_sound_infect) - 1
				}
				ArrayPushArray(pointer_class_sound_infect, temparr)
			}
			else if (equal(key, "INFECT ADVANCED"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
			
					ArrayPushString(class_sound_infect_adv, key)
					temparr[pos++] = ArraySize(class_sound_infect_adv) - 1
				}
				ArrayPushArray(pointer_class_sound_infect_adv, temparr)
			}
			else if (equal(key, "BURN"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					ArrayPushString(class_sound_burn, key)
					temparr[pos++] = ArraySize(class_sound_burn) - 1
				}
				ArrayPushArray(pointer_class_sound_burn, temparr)
			}
			else if (equal(key, "PAIN"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					ArrayPushString(class_sound_pain, key)
					temparr[pos++] = ArraySize(class_sound_pain) - 1
				}
				ArrayPushArray(pointer_class_sound_pain, temparr)
			}
			else if (equal(key, "DIE"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					ArrayPushString(class_sound_die, key)
					temparr[pos++] = ArraySize(class_sound_die) - 1
				}
				ArrayPushArray(pointer_class_sound_die, temparr)
			}
			else if (equal(key, "IDLE"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					ArrayPushString(class_sound_idle, key)
					temparr[pos++] = ArraySize(class_sound_idle) - 1
				}
				ArrayPushArray(pointer_class_sound_idle, temparr)
			}
			else if (equal(key, "IDLE LAST"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					ArrayPushString(class_sound_idle_last, key)
					temparr[pos++] = ArraySize(class_sound_idle_last) - 1
				}
				ArrayPushArray(pointer_class_sound_idle_last, temparr)
			}
			else if (equal(key, "MISS SLASH"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					ArrayPushString(class_sound_miss_slash, key)
					temparr[pos++] = ArraySize(class_sound_miss_slash) - 1
				}
				ArrayPushArray(pointer_class_sound_miss_slash, temparr)
			}
			else if (equal(key, "MISS WALL"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					ArrayPushString(class_sound_miss_wall, key)
					temparr[pos++] = ArraySize(class_sound_miss_wall) - 1
				}
				ArrayPushArray(pointer_class_sound_miss_wall, temparr)
			}
			else if (equal(key, "HIT NORMAL"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					ArrayPushString(class_sound_hit_normal, key)
					temparr[pos++] = ArraySize(class_sound_hit_normal) - 1
				}
				ArrayPushArray(pointer_class_sound_hit_normal, temparr)
			}
			else if (equal(key, "HIT STAB"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					ArrayPushString(class_sound_hit_stab, key)
					temparr[pos++] = ArraySize(class_sound_hit_stab) - 1
				}
				ArrayPushArray(pointer_class_sound_hit_stab, temparr)
			}
			else if (equal(key, "FALL"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					ArrayPushString(class_sound_fall, key)
					temparr[pos++] = ArraySize(class_sound_fall) - 1
				}
				ArrayPushArray(pointer_class_sound_fall, temparr)
			}
			else if (equal(key, "MADNESS"))
			{
				pos = 0
				arrayset(temparr, -1, sizeof(temparr))
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					ArrayPushString(class_sound_madness, key)
					temparr[pos++] = ArraySize(class_sound_madness) - 1
				}
				ArrayPushArray(pointer_class_sound_madness, temparr)
			}
		}
		if (file) fclose(file)
	}
	
	// Build extra items file path
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/zpe_mode/%s", path, ZP_EXTRAITEMS_FILE)
	
	// Parse if present
	if (file_exists(path))
	{
		// Open extra items file for reading
		file = fopen(path, "rt")
		
		while (file && !feof(file))
		{
			// Read one line at a time
			fgets(file, linedata, charsmax(linedata))
			
			// Replace newlines with a null character to prevent headaches
			replace(linedata, charsmax(linedata), "^n", "")
			
			// Blank line or comment
			if (!linedata[0] || linedata[0] == ';') continue;
			
			// New item starting
			if (linedata[0] == '[')
			{
				// Remove first and last characters (braces)
				linedata[strlen(linedata) - 1] = 0
				copy(linedata, charsmax(linedata), linedata[1])
				
				// Store its real name for future reference
				ArrayPushString(g_extraitem2_realname, linedata)
				continue;
			}
			
			// Get key and value(s)
			strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
			
			// Trim spaces
			trim(key)
			trim(value)
			
			if (equal(key, "NAME"))
				ArrayPushString(g_extraitem2_name, value)
			else if (equal(key, "COST"))
				ArrayPushCell(g_extraitem2_cost, str_to_num(value))
			else if (equal(key, "TEAMS"))
			{
				// Clear teams bitsum
				teams = 0
				
				// Parse teams
				while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
				{
					// Trim spaces
					trim(key)
					trim(value)
					
					if (equal(key, ZP_TEAM_NAMES[ZP_TEAM_ZOMBIE]))
						teams |= ZP_TEAM_ZOMBIE
					else if (equal(key, ZP_TEAM_NAMES[ZP_TEAM_HUMAN]))
						teams |= ZP_TEAM_HUMAN
					else if (equal(key, ZP_TEAM_NAMES[ZP_TEAM_NEMESIS]))
						teams |= ZP_TEAM_NEMESIS
					else if (equal(key, ZP_TEAM_NAMES[ZP_TEAM_SURVIVOR]))
						teams |= ZP_TEAM_SURVIVOR
				}
				
				// Add to teams array
				ArrayPushCell(g_extraitem2_team, teams)
			}
		}
		if (file) fclose(file)
	}
}

save_customization()
{
	new i, k, buffer[512], file, size
	
	// Build zombie classes file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/zpe_mode/%s", path, ZP_ZOMBIECLASSES_FILE)
	
	// Open zombie classes file for appending data
	file = fopen(path, "at"); size = ArraySize(g_zclass_name)
	
	// Add any new zombie classes data at the end if needed
	for (i = 0; i < size; i++)
	{
		if (ArrayGetCell(g_zclass_new, i))
		{
			// Add real name
			ArrayGetString(g_zclass_name, i, buffer, charsmax(buffer))
			format(buffer, charsmax(buffer), "^n[%s]", buffer)
			fputs(file, buffer)
			
			// Add caption
			ArrayGetString(g_zclass_name, i, buffer, charsmax(buffer))
			format(buffer, charsmax(buffer), "^nNAME = %s", buffer)
			fputs(file, buffer)
			
			// Add info
			ArrayGetString(g_zclass_info, i, buffer, charsmax(buffer))
			format(buffer, charsmax(buffer), "^nINFO = %s", buffer)
			fputs(file, buffer)
			
			// Add models
			for (k = ArrayGetCell(g_zclass_modelsstart, i); k < ArrayGetCell(g_zclass_modelsend, i); k++)
			{
				if (k == ArrayGetCell(g_zclass_modelsstart, i))
				{
					// First model, overwrite buffer
					ArrayGetString(g_zclass_playermodel, k, buffer, charsmax(buffer))
				}
				else
				{
					// Successive models, append to buffer
					ArrayGetString(g_zclass_playermodel, k, path, charsmax(path))
					format(buffer, charsmax(buffer), "%s , %s", buffer, path)
				}
			}
			format(buffer, charsmax(buffer), "^nMODELS = %s", buffer)
			fputs(file, buffer)
			
			// Add clawmodel
			ArrayGetString(g_zclass_clawmodel, i, buffer, charsmax(buffer))
			format(buffer, charsmax(buffer), "^nCLAWMODEL = %s", buffer)
			fputs(file, buffer)
			
			// Add health
			formatex(buffer, charsmax(buffer), "^nHEALTH = %d", ArrayGetCell(g_zclass_hp, i))
			fputs(file, buffer)
			
			// Add Max health
			formatex(buffer, charsmax(buffer), "^nMAX HEALTH = %d", ArrayGetCell(g_zclass_maxhp, i))
			fputs(file, buffer)
			
			// Add speed
			formatex(buffer, charsmax(buffer), "^nSPEED = %d", ArrayGetCell(g_zclass_spd, i))
			fputs(file, buffer)
			
			// Add gravity
			formatex(buffer, charsmax(buffer), "^nGRAVITY = %.2f", Float:ArrayGetCell(g_zclass_grav, i))
			fputs(file, buffer)
			
			// Add knockback
			formatex(buffer, charsmax(buffer), "^nKNOCKBACK = %.2f^n", Float:ArrayGetCell(g_zclass_kb, i))
			fputs(file, buffer)
			
			// Add infect sound
			fputs(file, "^nINFECT = zombie_plague/zombie_infec1.wav , zombie_plague/zombie_infec2.wav , zombie_plague/zombie_infec3.wav")
			
			// Add infect sound
			fputs(file, "^nINFECT ADVANCED = zombie_plague/zombie_infec1.wav")
				
			// Add burn sound
			fputs(file, "^nBURN = zombie_plague/zombie_burn3.wav , zombie_plague/zombie_burn4.wav , zombie_plague/zombie_burn5.wav , zombie_plague/zombie_burn6.wav , zombie_plague/zombie_burn7.wav")
				
			// Add pain sound
			fputs(file, "^nPAIN = zombie_plague/zombie_pain1.wav , zombie_plague/zombie_pain2.wav , zombie_plague/zombie_pain3.wav , zombie_plague/zombie_pain4.wav , zombie_plague/zombie_pain5.wav")
				
			// Add die sound
			fputs(file, "^nDIE = zombie_plague/zombie_die1.wav , zombie_plague/zombie_die2.wav , zombie_plague/zombie_die3.wav , zombie_plague/zombie_die4.wav , zombie_plague/zombie_die5.wav")
			
			// Add idle sound
			fputs(file, "^nIDLE = zombie_plague/zombie_brains1.wav , zombie_plague/zombie_brains2.wav")
				
			// Add idle last sound
			fputs(file, "^nIDLE LAST = zombie_plague/zombie_brains1.wav , zombie_plague/zombie_brains2.wav")
				
			// Add miss slash sound
			fputs(file, "^nMISS SLASH = weapons/knife_slash1.wav , weapons/knife_slash2.wav")
				
			// Add miss wall sound
			fputs(file, "^nMISS WALL = weapons/knife_hitwall1.wav")
				
			// Add hit normal sound
			fputs(file, "^nHIT NORMAL = weapons/knife_hit1.wav , weapons/knife_hit2.wav , weapons/knife_hit3.wav , weapons/knife_hit4.wav")
				
			// Add hit stab sound
			fputs(file, "^nHIT STAB = weapons/knife_stab.wav")

			// Add fall sound
			fputs(file, "^nFALL = zombie_plague/zombie_fall1.wav")

			// Add madness sound
			fputs(file, "^nMADNESS = zombie_plague/zombie_madness1.wav^n")
		}
	}
	fclose(file)
	
	// Build extra items file path
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/zpe_mode/%s", path, ZP_EXTRAITEMS_FILE)
	
	// Open extra items file for appending data
	file = fopen(path, "at")
	size = ArraySize(g_extraitem_name)
	
	// Add any new extra items data at the end if needed
	for (i = EXTRAS_CUSTOM_STARTID; i < size; i++)
	{
		if (ArrayGetCell(g_extraitem_new, i))
		{
			// Add real name
			ArrayGetString(g_extraitem_name, i, buffer, charsmax(buffer))
			format(buffer, charsmax(buffer), "^n[%s]", buffer)
			fputs(file, buffer)
			
			// Add caption
			ArrayGetString(g_extraitem_name, i, buffer, charsmax(buffer))
			format(buffer, charsmax(buffer), "^nNAME = %s", buffer)
			fputs(file, buffer)
			
			// Add cost
			formatex(buffer, charsmax(buffer), "^nCOST = %d", ArrayGetCell(g_extraitem_cost, i))
			fputs(file, buffer)
			
			// Add team
			formatex(buffer, charsmax(buffer), "^nTEAMS = %s^n", ZP_TEAM_NAMES[ArrayGetCell(g_extraitem_team, i)])
			fputs(file, buffer)
		}
	}
	fclose(file)
	
	// Free arrays containing class/item overrides
	ArrayDestroy(g_zclass2_realname)
	ArrayDestroy(g_zclass2_name)
	ArrayDestroy(g_zclass2_info)
	ArrayDestroy(g_zclass2_modelsstart)
	ArrayDestroy(g_zclass2_modelsend)
	ArrayDestroy(g_zclass2_playermodel)
	ArrayDestroy(g_zclass2_modelindex)
	ArrayDestroy(g_zclass2_clawmodel)
	ArrayDestroy(g_zclass2_hp)
	ArrayDestroy(g_zclass2_maxhp)
	ArrayDestroy(g_zclass2_spd)
	ArrayDestroy(g_zclass2_grav)
	ArrayDestroy(g_zclass2_kb)
	ArrayDestroy(g_zclass_new)
	ArrayDestroy(g_extraitem2_realname)
	ArrayDestroy(g_extraitem2_name)
	ArrayDestroy(g_extraitem2_cost)
	ArrayDestroy(g_extraitem2_team)
	ArrayDestroy(g_extraitem_new)
}

// Register Ham Forwards for CZ bots
public register_ham_czbots(id)
{
	// Make sure it's a CZ bot and it's still connected
	if (g_hamczbots || !g_isconnected[id] || !get_pcvar_num(cvar_botquota))
		return;
	
	RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled")
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage_Post", 1)
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	
	// Ham forwards for CZ bots succesfully registered
	g_hamczbots = true
	
	// If the bot has already spawned, call the forward manually for him
	if (is_user_alive(id)) fw_PlayerSpawn_Post(id)
}

// Disable minmodels task
public disable_minmodels(id)
{
	if (!g_isconnected[id]) return;
	client_cmd(id, "cl_minmodels 0")
}

// Bots automatically buy extra items
public bot_buy_extras(taskid)
{
	// Nemesis or Survivor bots have nothing to buy by default
	if (!g_isalive[ID_SPAWN] || g_survivor[ID_SPAWN] || g_nemesis[ID_SPAWN])
		return;
	
	if (!g_zombie[ID_SPAWN]) // human bots
	{
		// Attempt to buy Night Vision
		buy_extra_item(ID_SPAWN, EXTRA_NVISION)
		
		// Attempt to buy a weapon
		buy_extra_item(ID_SPAWN, random_num(EXTRA_WEAPONS_STARTID, EXTRAS_CUSTOM_STARTID-1))
	}
	else // zombie bots
	{
		// Attempt to buy an Antidote
		buy_extra_item(ID_SPAWN, EXTRA_ANTIDOTE)
	}
}

// Refill BP Ammo Task
/*public refill_bpammo(const args[], id)
{
	// Player died or turned into a zombie
	if (!g_isalive[id] || g_zombie[id])
		return;
	
	set_msg_block(g_msgAmmoPickup, BLOCK_ONCE)
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[REFILL_WEAPONID], AMMOTYPE[REFILL_WEAPONID], MAXBPAMMO[REFILL_WEAPONID])
}*/

// Balance Teams Task
/*balance_teams()
{
	// Get amount of users playing
	static iPlayersnum
	iPlayersnum = fnGetPlaying()
	
	// No players, don't bother
	if (iPlayersnum < 1) return;
	
	// Split players evenly
	static iTerrors, iMaxTerrors, id, team[33]
	iMaxTerrors = iPlayersnum/2
	iTerrors = 0
	
	// First, set everyone to CT
	for (id = 1; id <= g_maxplayers; id++)
	{
		// Skip if not connected
		if (!g_isconnected[id])
			continue;
		
		team[id] = zp_get_user_team(id)
		
		// Skip if not playing
		if (team[id] == TEAM_SPECTATOR || team[id] == TEAM_UNASSIGNED)
			continue;
		
		// Set team
		remove_task(id+TASK_TEAM)
		zp_set_user_team(id, TEAM_CT)
		team[id] = TEAM_CT
	}
	
	// Then randomly set half of the players to Terrorists
	while (iTerrors < iMaxTerrors)
	{
		// Keep looping through all players
		if (++id > g_maxplayers) id = 1
		
		// Skip if not connected
		if (!g_isconnected[id])
			continue;
		
		// Skip if not playing or already a Terrorist
		if (team[id] != TEAM_CT)
			continue;
		
		// Random chance
		if (random_num(0, 1))
		{
			zp_set_user_team(id, TEAM_TERRORIST)
			team[id] = TEAM_TERRORIST
			iTerrors++
		}
	}
}*/

// Respawn Player Task (deathmatch)
public respawn_player_task(taskid)
{
	// Already alive or round ended
	if (g_isalive[ID_SPAWN] || g_endround)
		return;
	
	// Get player's team
	static TeamName:team
	team = zp_get_user_team(ID_SPAWN)
	
	// Player moved to spectators
	if (team == TEAM_SPECTATOR || team == TEAM_UNASSIGNED)
		return;
	
	// Respawn player automatically if allowed on current round
	if ((!g_survround || get_pcvar_num(cvar_allowrespawnsurv)) && (!g_swarmround || get_pcvar_num(cvar_allowrespawnswarm)) && (!g_nemround || get_pcvar_num(cvar_allowrespawnnem)) && (!g_plagueround || get_pcvar_num(cvar_allowrespawnplague)))
	{
		// Infection rounds = none of the above
		if (!get_pcvar_num(cvar_allowrespawninfection) && !g_survround && !g_nemround && !g_swarmround && !g_plagueround)
			return;
		
		// Respawn if only the last human is left? (ignore this setting on survivor rounds)
		if (!g_survround && !get_pcvar_num(cvar_respawnafterlast) && fnGetHumans() <= 1)
			return;
		
		// Respawn as zombie?
		if (get_pcvar_num(cvar_deathmatch) == 2 || (get_pcvar_num(cvar_deathmatch) == 3 && random_num(0, 1)) || (get_pcvar_num(cvar_deathmatch) == 4 && fnGetZombies() < fnGetAlive()/2))
			g_respawn_as_zombie[ID_SPAWN] = true
		
		// Override respawn as zombie setting on nemesis and survivor rounds
		if (g_survround) g_respawn_as_zombie[ID_SPAWN] = true
		else if (g_nemround) g_respawn_as_zombie[ID_SPAWN] = false
		
		respawn_player_manually(ID_SPAWN)
	}
}

// Respawn Player Check Task (if killed by worldspawn)
public respawn_player_check_task(taskid)
{
	// Successfully spawned or round ended
	if (g_isalive[ID_SPAWN] || g_endround)
		return;
	
	// Get player's team
	static TeamName:team
	team = zp_get_user_team(ID_SPAWN)
	
	// Player moved to spectators
	if (team == TEAM_SPECTATOR || team == TEAM_UNASSIGNED)
		return;
	
	// If player was being spawned as a zombie, set the flag again
	if (g_zombie[ID_SPAWN]) g_respawn_as_zombie[ID_SPAWN] = true
	else g_respawn_as_zombie[ID_SPAWN] = false
	
	respawn_player_manually(ID_SPAWN)
}

// Respawn Player Manually (called after respawn checks are done)
respawn_player_manually(id)
{
	// Set proper team before respawning, so that the TeamInfo message that's sent doesn't confuse PODBots
	if (g_respawn_as_zombie[id])
		zp_set_user_team(id, TEAM_TERRORIST)
	else
		zp_set_user_team(id, TEAM_CT)
	
	// Respawning a player has never been so easy
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}

// Check Round Task -check that we still have both zombies and humans on a round-
check_round(leaving_player)
{
	// Round ended or make_a_zombie task still active
	if (g_endround || task_exists(TASK_MAKEZOMBIE))
		return;
	
	// Get alive players count
	static iPlayersnum, id
	iPlayersnum = fnGetAlive()
	
	// Last alive player, don't bother
	if (iPlayersnum < 2)
		return;
	
	// Last zombie disconnecting
	if (g_zombie[leaving_player] && fnGetZombies() == 1)
	{
		// Only one CT left, don't bother
		if (fnGetHumans() == 1 && fnGetCTs() == 1)
			return;
		
		// Pick a random one to take his place
		while ((id = fnGetRandomAlive(random_num(1, iPlayersnum))) == leaving_player ) { /* keep looping */ }
		
		// Show last zombie left notice
		zp_colored_print(0, "^x04[ZP]^x01 %L", LANG_PLAYER, "LAST_ZOMBIE_LEFT", g_playername[id])
		
		// Set player leaving flag
		g_lastplayerleaving = true
		
		// Turn into a Nemesis or just a zombie?
		if (g_nemesis[leaving_player])
			zombieme(id, 0, 1, 0, 0)
		else
			zombieme(id, 0, 0, 0, 0)
		
		// Remove player leaving flag
		g_lastplayerleaving = false
		
		// If Nemesis, set chosen player's health to that of the one who's leaving
		if (get_pcvar_num(cvar_keephealthondisconnect) && g_nemesis[leaving_player])
			fm_set_user_health(id, pev(leaving_player, pev_health))
	}
	
	// Last human disconnecting
	else if (!g_zombie[leaving_player] && fnGetHumans() == 1)
	{
		// Only one T left, don't bother
		if (fnGetZombies() == 1 && fnGetTs() == 1)
			return;
		
		// Pick a random one to take his place
		while ((id = fnGetRandomAlive(random_num(1, iPlayersnum))) == leaving_player ) { /* keep looping */ }
		
		// Show last human left notice
		zp_colored_print(0, "^x04[ZP]^x01 %L", LANG_PLAYER, "LAST_HUMAN_LEFT", g_playername[id])
		
		// Set player leaving flag
		g_lastplayerleaving = true
		
		// Turn into a Survivor or just a human?
		if (g_survivor[leaving_player])
			humanme(id, 0, 1, 0)
		else
			humanme(id, 0, 0, 0)
		
		// Remove player leaving flag
		g_lastplayerleaving = false
		
		// If Survivor, set chosen player's health to that of the one who's leaving
		if (get_pcvar_num(cvar_keephealthondisconnect) && g_survivor[leaving_player])
			fm_set_user_health(id, pev(leaving_player, pev_health))
	}
}

// Lighting Effects Task
public lighting_effects()
{
	// Cache some CVAR values at every 5 secs
	cache_cvars()
	
	// Get lighting style
	static lighting[2]
	get_pcvar_string(cvar_lighting, lighting, charsmax(lighting))
	strtolower(lighting)
	
	// Lighting disabled? ["0"]
	if (lighting[0] == '0')
		return;

	engfunc(EngFunc_LightStyle, 0, lighting)
}

// Thunderclap task
public thunderclap()
{
	// Set lighting
	static light[2]
	light[0] = g_lights_cycle[g_lights_i]
	engfunc(EngFunc_LightStyle, 0, light)
	
	g_lights_i++
	
	// Lighting cycle end?
	if (g_lights_i >= g_lights_cycle_len)
	{
		remove_task(TASK_THUNDER)
		lighting_effects()
	}
	
	// Lighting cycle start?
	else if (!task_exists(TASK_THUNDER))
		set_task(0.1, "thunderclap", TASK_THUNDER, _, _, "b")
}

// Ambience Sound Effects Task
public ambience_sound_effects(taskid)
{
	// Play a random sound depending on the round
	static sound[64], iRand, duration
	
	if (g_nemround) // Nemesis Mode
	{
		iRand = random_num(0, ArraySize(sound_ambience2) - 1)
		ArrayGetString(sound_ambience2, iRand, sound, charsmax(sound))
		duration = ArrayGetCell(sound_ambience2_duration, iRand)
	}
	else if (g_survround) // Survivor Mode
	{
		iRand = random_num(0, ArraySize(sound_ambience3) - 1)
		ArrayGetString(sound_ambience3, iRand, sound, charsmax(sound))
		duration = ArrayGetCell(sound_ambience3_duration, iRand)
	}
	else if (g_swarmround) // Swarm Mode
	{
		iRand = random_num(0, ArraySize(sound_ambience4) - 1)
		ArrayGetString(sound_ambience4, iRand, sound, charsmax(sound))
		duration = ArrayGetCell(sound_ambience4_duration, iRand)
	}
	else if (g_plagueround) // Plague Mode
	{
		iRand = random_num(0, ArraySize(sound_ambience5) - 1)
		ArrayGetString(sound_ambience5, iRand, sound, charsmax(sound))
		duration = ArrayGetCell(sound_ambience5_duration, iRand)
	}
	else // Infection Mode
	{
		iRand = random_num(0, ArraySize(sound_ambience1) - 1)
		ArrayGetString(sound_ambience1, iRand, sound, charsmax(sound))
		duration = ArrayGetCell(sound_ambience1_duration, iRand)
	}
	
	// Play it on clients
	PlaySound(sound)
	
	// Set the task for when the sound is done playing
	set_task(float(duration), "ambience_sound_effects", TASK_AMBIENCESOUNDS)
}

// Ambience Sounds Stop Task
ambience_sound_stop()
{
	client_cmd(0, "mp3 stop; stopsound")
}

// Flashlight Charge Task
public flashlight_charge(taskid)
{
	// Drain or charge?
	if (g_flashlight[ID_CHARGE])
		g_flashbattery[ID_CHARGE] -= get_pcvar_num(cvar_flashdrain)
	else
		g_flashbattery[ID_CHARGE] += get_pcvar_num(cvar_flashcharge)
	
	// Battery fully charged
	if (g_flashbattery[ID_CHARGE] >= 100)
	{
		// Don't exceed 100%
		g_flashbattery[ID_CHARGE] = 100
		
		// Update flashlight battery on HUD
		message_begin(MSG_ONE, g_msgFlashBat, _, ID_CHARGE)
		write_byte(100) // battery
		message_end()
		
		// Task not needed anymore
		remove_task(taskid);
		return;
	}
	
	// Battery depleted
	if (g_flashbattery[ID_CHARGE] <= 0)
	{
		// Turn it off
		g_flashlight[ID_CHARGE] = false
		g_flashbattery[ID_CHARGE] = 0
		
		// Play flashlight toggle sound
		emit_sound(ID_CHARGE, CHAN_ITEM, sound_flashlight, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		// Update flashlight status on HUD
		message_begin(MSG_ONE, g_msgFlashlight, _, ID_CHARGE)
		write_byte(0) // toggle
		write_byte(0) // battery
		message_end()
		
		// Remove flashlight task for this player
		remove_task(ID_CHARGE+TASK_FLASH)
	}
	else
	{
		// Update flashlight battery on HUD
		message_begin(MSG_ONE_UNRELIABLE, g_msgFlashBat, _, ID_CHARGE)
		write_byte(g_flashbattery[ID_CHARGE]) // battery
		message_end()
	}
}

// Turn Off Flashlight and Restore Batteries
turn_off_flashlight(id)
{
	// Restore batteries for the next use
	fm_cs_set_user_batteries(id, 100)
	
	// Check if flashlight is on
	if (pev(id, pev_effects) & EF_DIMLIGHT)
	{
		// Turn it off
		set_pev(id, pev_impulse, IMPULSE_FLASHLIGHT)
	}
	else
	{
		// Clear any stored flashlight impulse (bugfix)
		set_pev(id, pev_impulse, 0)
	}
	
	// Turn off custom flashlight
	if (g_cached_customflash)
	{
		// Turn it off
		g_flashlight[id] = false
		g_flashbattery[id] = 100
		
		// Update flashlight HUD
		message_begin(MSG_ONE, g_msgFlashlight, _, id)
		write_byte(0) // toggle
		write_byte(100) // battery
		message_end()
		
		// Remove previous tasks
		remove_task(id+TASK_CHARGE)
		remove_task(id+TASK_FLASH)
	}
}

// Added Fixed
public msgStatusValue(msgid, dest, id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_CONTINUE

	if(!iPlayerAimInfo[id])
		return PLUGIN_CONTINUE

	new iFlag = get_msg_arg_int(1)
	new iOwner = get_msg_arg_int(2)
    
	if(!iOwner)
		return PLUGIN_CONTINUE

	if(!is_user_alive(iOwner) || !is_user_connected(iOwner))
		return PLUGIN_CONTINUE
    
	if(iFlag != 2 )
		return PLUGIN_CONTINUE

	new szText[512]
	
	new iColor[3]

	if(g_zombie[iOwner])
	{
		if(g_nemesis[iOwner])
		{
			iColor[0] = 255
			iColor[1] = 100
			iColor[2] = 50	
		}
		else
		{
			iColor[0] = 255
			iColor[1] = 215
			iColor[2] = 0				
		}
	}
	else
	{
		if(g_survivor[iOwner])
		{
			iColor[0] = 0
			iColor[1] = 127
			iColor[2] = 255	
		}
		else if(g_hero[iOwner])
		{
			iColor[0] = 70
			iColor[1] = 80
			iColor[2] = 250			
		}
		else
		{
			iColor[0] = 0
			iColor[1] = 205
			iColor[2] = 50
		}
	}

	new szName[32]
	get_user_name(iOwner, szName, charsmax( szName ))
	
	new iNextExp = zpe_get_user_next_exp(iOwner);
	new szSkinName[32]; zp_get_user_human_skin_name(iOwner, szSkinName, charsmax(szSkinName))

	if(g_zombie[iOwner])
	{
		if(!g_zombie[id])
			return PLUGIN_CONTINUE	
		
		if(iNextExp == -1)
		{
			formatex(szText, charsmax( szText ), "%L", id, "AIMINFO_TEAM_ZOMBIE_LVLMAX", szName, zp_get_user_money(iOwner), zp_get_user_ammo(iOwner), zpe_get_user_lvl(iOwner))
		}
		else
		{
			formatex(szText, charsmax( szText ), "%L", id, "AIMINFO_TEAM_ZOMBIE", szName, zp_get_user_money(iOwner), zp_get_user_ammo(iOwner), zpe_get_user_lvl(iOwner))
		}
	}
	else
	{
		if(g_zombie[id])
			return PLUGIN_CONTINUE

		if(g_hero[iOwner] || g_survivor[iOwner])
		{
			if(iNextExp == -1)
			{
				formatex(szText, charsmax( szText ), "%L", id, "AIMINFO_TEAM_HERO_LVLMAX", szName, zp_get_user_money(iOwner), zp_get_user_ammo(iOwner), zpe_get_user_lvl(iOwner))
			}
			else
			{
				formatex(szText, charsmax( szText ), "%L", id, "AIMINFO_TEAM_HERO", szName, zp_get_user_money(iOwner), zp_get_user_ammo(iOwner), zpe_get_user_lvl(iOwner))
			}
		}
		else
		{
			if(iNextExp == -1)
			{
				formatex(szText, charsmax( szText ), "%L", id, "AIMINFO_TEAM_HUMAN_LVLMAX", szName, zp_get_user_money(iOwner), zp_get_user_ammo(iOwner), zpe_get_user_lvl(iOwner), szSkinName)
			}
			else
			{
				formatex(szText, charsmax( szText ), "%L", id, "AIMINFO_TEAM_HUMAN", szName, zp_get_user_money(iOwner), zp_get_user_ammo(iOwner), zpe_get_user_lvl(iOwner), szSkinName)
			}
		}
	}
	
	set_hudmessage(iColor[0], iColor[1], iColor[2], -1.0, 0.60, 1, 0.01, 1.0, 0.01, 0.01, -1)
	ShowSyncHudMsg(id, g_MsgSync3, szText)

	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), _, id)
	write_byte(0)
	write_string("")
	message_end()

	return PLUGIN_CONTINUE
}

// Remove Stuff Task
public remove_stuff()
{
	static ent
	
	// Remove rotating doors
	if (get_pcvar_num(cvar_removedoors) > 0)
	{
		ent = -1;
		while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_door_rotating")) != 0)
			engfunc(EngFunc_SetOrigin, ent, Float:{8192.0 ,8192.0 ,8192.0})
	}
	
	// Remove all doors
	if (get_pcvar_num(cvar_removedoors) > 1)
	{
		ent = -1;
		while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_door")) != 0)
			engfunc(EngFunc_SetOrigin, ent, Float:{8192.0 ,8192.0 ,8192.0})
	}
	
	// Triggered lights
	if (!get_pcvar_num(cvar_triggered))
	{
		ent = -1
		while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "light")) != 0)
		{
			dllfunc(DLLFunc_Use, ent, 0); // turn off the light
			set_pev(ent, pev_targetname, 0) // prevent it from being triggered
		}
	}
}

// Set Custom Weapon Models
replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_KNIFE: // Custom knife models
		{
			if (g_zombie[id])
			{
				if (g_nemesis[id]) // Nemesis
				{
					set_pev(id, pev_viewmodel2, model_vknife_nemesis)
					set_pev(id, pev_weaponmodel2, "")
				}
				else // Zombies
				{
					static clawmodel[100]
					ArrayGetString(g_zclass_clawmodel, g_zombieclass[id], clawmodel, charsmax(clawmodel))
					format(clawmodel, charsmax(clawmodel), "models/zp_br_cso/zombie/claws/%s", clawmodel)
					set_pev(id, pev_viewmodel2, clawmodel)
					set_pev(id, pev_weaponmodel2, "")
				}
			}
		}
		case CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE:
		{
			if (g_zombie[id])
			{
				switch(g_zombieclass[id])
				{
					case 0: set_pev(id, pev_viewmodel2, gModelV1)
					case 1: set_pev(id, pev_viewmodel2, gModelV2)
					case 2: set_pev(id, pev_viewmodel2, gModelV3)
					case 3: set_pev(id, pev_viewmodel2, gModelV4)
					case 4: set_pev(id, pev_viewmodel2, gModelV5)
					case 5: set_pev(id, pev_viewmodel2, gModelV6)
					case 6: set_pev(id, pev_viewmodel2, gModelV7)
					case 7: set_pev(id, pev_viewmodel2, gModelV8)
					case 8: set_pev(id, pev_viewmodel2, gModelV9)
				}
			}
		}
	}
	
	// Update model on weaponmodel ent
	if (g_handle_models_on_separate_ent) fm_set_weaponmodel_ent(id)
}

// Reset Player Vars
reset_vars(id, resetall)
{
	g_zombie[id] = false
	g_nemesis[id] = false
	g_survivor[id] = false
	g_hero[id] = false
	g_firstzombie[id] = false
	g_lastzombie[id] = false
	g_lasthuman[id] = false
	//set_entvar(id, var_takedamage, DAMAGE_AIM)
	g_respawn_as_zombie[id] = false
	g_nvision[id] = false
	g_nvisionenabled[id] = false
	g_flashlight[id] = false
	g_flashbattery[id] = 100
	g_canbuy[id] = true
	//g_burning_duration[id] = 0
	
	if (resetall)
	{
		g_ammopacks[id] = get_pcvar_num(cvar_startammopacks)
		g_zombieclass[id] = ZCLASS_NONE
		g_zombieclassnext[id] = ZCLASS_NONE
		g_damagedealt_human[id] = 0
		g_damagedealt_zombie[id] = 0
		WPN_AUTO_ON = 0
		WPN_STARTID = 0
		PL_ACTION = 0
		MENU_PAGE_ZCLASS = 0
		MENU_PAGE_EXTRAS = 0
		MENU_PAGE_PLAYERS = 0
	}
}

// Set spectators nightvision
public spec_nvision(id)
{
	// Not connected, alive, or bot
	if (!g_isconnected[id] || g_isalive[id] || g_isbot[id])
		return;
	
	// Give Night Vision?
	if (get_pcvar_num(cvar_nvggive))
	{
		g_nvision[id] = true
		
		// Turn on Night Vision automatically?
		if (get_pcvar_num(cvar_nvggive) == 1)
		{
			g_nvisionenabled[id] = true
			
			// Custom nvg?
			if (get_pcvar_num(cvar_customnvg))
			{
				remove_task(id+TASK_NVISION)
				set_task(0.1, "set_user_nvision", id+TASK_NVISION, _, _, "b")
			}
			else
				set_user_gnvision(id, 1)
		}
	}
}

// Show HUD Task
/*public ShowHUD(taskid)
{
	static id
	id = ID_SHOWHUD;
	
	// Player died?
	if (!g_isalive[id])
	{
		// Get spectating target
		id = pev(id, PEV_SPEC_TARGET)
		
		// Target not alive
		if (!g_isalive[id]) return;
	}
	
	// Format classname
	static class[32]
	
	if (g_zombie[id]) // zombies
	{
		if (g_nemesis[id])
			formatex(class, charsmax(class), "%L", ID_SHOWHUD, "CLASS_NEMESIS")
		else
		{
			copy(class, charsmax(class), g_zombie_classname[id])
			
			if (contain(class, "ML_") != -1)
				format(class, charsmax(class), "%L", ID_SHOWHUD, class[3])
		}
	}
	else // humans
	{
		if(g_survivor[id])
			formatex(class, charsmax(class), "%L", ID_SHOWHUD, "CLASS_SURVIVOR")
		else if(g_hero[id])
			formatex(class, charsmax(class), "%L", ID_SHOWHUD, "CLASS_HERO")
		else
			formatex(class, charsmax(class), "%L", ID_SHOWHUD, "CLASS_HUMAN")
	}
	
	new szLvl[32];

	// Spectating someone else?
	if (id != ID_SHOWHUD)
	{
		convert_lvl_to_text(id, szLvl, charsmax(szLvl));
		// Show name, health, class, and ammo packs
		set_hudmessage(200, 255, 255, -1.0, 0.75, 0, 0.0, 1.0, 0.0, 0.0, -1)
		
		if(g_nemesis[id] || g_survivor[id])
		{
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "%s^n$: %d | Ammo: %d | %s", g_playername[id], zp_get_user_money(id), zp_get_user_ammo(id), szLvl)
		}
		else
		{
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "%s^nHP: %d | $: %d | Ammo: %d | %s", g_playername[id], pev(id, pev_health), zp_get_user_money(id), zp_get_user_ammo(id), szLvl)
		}
	}
	else
	{
		new color[3]
		
		if(g_nemesis[id])
		{
			color[0] = 255
			color[1] = 100
			color[2] = 50
		}	
		else if(g_survivor[id])
		{
			color[0] = 0
			color[1] = 255
			color[2] = 255
		}
		else if(g_hero[id])
		{
			color[0] = 70
			color[1] = 80
			color[2] = 250
		}
		else if(g_zombie[id])
		{
			color[0] = 255
			color[1] = 215
			color[2] = 0
		}
		else
		{
			color[0] = 0
			color[1] = 205
			color[2] = 50
		}
		
		convert_lvl_to_text(ID_SHOWHUD, szLvl, charsmax(szLvl));

		set_hudmessage(color[0], color[1], color[2], 0.02, 0.924, 0, 0.0, 0.70, 0.405, 0.405, -1)
		
		// Show health, class and ammo packs
		if(g_survivor[ID_SHOWHUD] || g_zombie[ID_SHOWHUD])
		{
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "[%L: %d | %L: %s]^n[%L: %d] [%s]^n^n", ID_SHOWHUD, "HUD_HP", pev(ID_SHOWHUD, pev_health), ID_SHOWHUD, "HUD_ZCLASS", class, ID_SHOWHUD, "HUD_AMMO", zp_get_user_ammo(ID_SHOWHUD), szLvl)
		}
		else
		{
			new szSkinName[32]; zp_get_user_human_skin_name(ID_SHOWHUD, szSkinName, charsmax(szSkinName));
			
			if(g_hero[ID_SHOWHUD])
			{
				if(zp_get_user_wpnlvl(ID_SHOWHUD) < 5)
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "[%L: %d | %s • %L: %d|3]^n[%L: %d] [%s] [%L: %d/%d%%]^n^n", ID_SHOWHUD, "HUD_HP", pev(ID_SHOWHUD, pev_health), class, ID_SHOWHUD, "HUD_BUFFPOINT", zp_get_user_buffpoint(ID_SHOWHUD), ID_SHOWHUD, "HUD_AMMO", zp_get_user_ammo(ID_SHOWHUD), szLvl, ID_SHOWHUD, "HUD_WL", zp_get_user_wpnlvl(ID_SHOWHUD), zp_user_wpnlvl_progress(ID_SHOWHUD))
				}
				else
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "[%L: %d | %s • %L: %d|3]^n[%L: %d] [%s] [%L: Max]^n^n", ID_SHOWHUD, "HUD_HP", pev(ID_SHOWHUD, pev_health), class, ID_SHOWHUD, "HUD_BUFFPOINT", zp_get_user_buffpoint(ID_SHOWHUD), ID_SHOWHUD, "HUD_AMMO", zp_get_user_ammo(ID_SHOWHUD), szLvl, ID_SHOWHUD, "HUD_WL")
				}
			}
			else
			{
				if(zp_get_user_wpnlvl(ID_SHOWHUD) < 5)
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "[%L: %d | %s • %L: %d|3]^n[%L: %d] [%s] [%L: %d/%d%%]^n^n", ID_SHOWHUD, "HUD_HP", pev(ID_SHOWHUD, pev_health), szSkinName, ID_SHOWHUD, "HUD_BUFFPOINT", zp_get_user_buffpoint(ID_SHOWHUD), ID_SHOWHUD, "HUD_AMMO", zp_get_user_ammo(ID_SHOWHUD), szLvl, ID_SHOWHUD, "HUD_WL", zp_get_user_wpnlvl(ID_SHOWHUD), zp_user_wpnlvl_progress(ID_SHOWHUD))
				}
				else
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "[%L: %d | %s • %L: %d|3]^n[%L: %d] [%s] [%L: Max]^n^n", ID_SHOWHUD, "HUD_HP", pev(ID_SHOWHUD, pev_health), szSkinName, ID_SHOWHUD, "HUD_BUFFPOINT", zp_get_user_buffpoint(ID_SHOWHUD), ID_SHOWHUD, "HUD_AMMO", zp_get_user_ammo(ID_SHOWHUD), szLvl, ID_SHOWHUD, "HUD_WL")
				}
			}
		}
	}
}*/

// Show HUD Task
public ShowHUD(taskid)
{
	static id
	id = ID_SHOWHUD;
	
	// Player died?
	if (!g_isalive[id])
	{
		// Get spectating target
		id = pev(id, PEV_SPEC_TARGET)
		
		// Target not alive
		if (!g_isalive[id]) return;
	}
	
	// Format classname
	static class[32]
	
	if (g_zombie[id]) // zombies
	{
		if (g_nemesis[id])
			formatex(class, charsmax(class), "%L", ID_SHOWHUD, "CLASS_NEMESIS")
		else
		{
			copy(class, charsmax(class), g_zombie_classname[id])
			
			if (contain(class, "ML_") != -1)
				format(class, charsmax(class), "%L", ID_SHOWHUD, class[3])
		}
	}
	else // humans
	{
		if(g_survivor[id])
			formatex(class, charsmax(class), "%L", ID_SHOWHUD, "CLASS_SURVIVOR")
		else if(g_hero[id])
			formatex(class, charsmax(class), "%L", ID_SHOWHUD, "CLASS_HERO")
		else
			formatex(class, charsmax(class), "%L", ID_SHOWHUD, "CLASS_HUMAN")
	}
	
	new szLvl[32];

	// Spectating someone else?
	if (id != ID_SHOWHUD)
	{
		convert_lvl_to_text(id, szLvl, charsmax(szLvl));
		// Show name, health, class, and ammo packs
		set_hudmessage(200, 255, 255, -1.0, 0.75, 0, 0.0, 1.0, 0.0, 0.0, -1)
		
		if(g_nemesis[id] || g_survivor[id])
		{
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "%s^n$: %d | Ammo: %d | %s", g_playername[id], zp_get_user_money(id), zp_get_user_ammo(id), szLvl)
		}
		else
		{
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "%s^nHP: %d | $: %d | Ammo: %d | %s", g_playername[id], pev(id, pev_health), zp_get_user_money(id), zp_get_user_ammo(id), szLvl)
		}
	}
	else
	{
		new color[3]
		
		if(g_nemesis[id])
		{
			color[0] = 255
			color[1] = 100
			color[2] = 50
		}	
		else if(g_survivor[id])
		{
			color[0] = 0
			color[1] = 255
			color[2] = 255
		}
		else if(g_hero[id])
		{
			color[0] = 70
			color[1] = 80
			color[2] = 250
		}
		else if(g_zombie[id])
		{
			color[0] = 255
			color[1] = 215
			color[2] = 0
		}
		else
		{
			color[0] = 0
			color[1] = 205
			color[2] = 50
		}
		
		convert_lvl_to_text(ID_SHOWHUD, szLvl, charsmax(szLvl));

		set_hudmessage(color[0], color[1], color[2], 0.02, 0.924, 0, 0.0, 0.70, 0.405, 0.405, -1)
		
		// Show health, class and ammo packs
		if(g_survivor[ID_SHOWHUD] || g_zombie[ID_SHOWHUD])
		{
			ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "[%L: %d | %L: %s]^n[%L: %d] [%s]^n^n", ID_SHOWHUD, "HUD_HP", pev(ID_SHOWHUD, pev_health), ID_SHOWHUD, "HUD_ZCLASS", class, ID_SHOWHUD, "HUD_AMMO", zp_get_user_ammo(ID_SHOWHUD), szLvl)
		}
		else
		{
			new szSkinName[32]; zp_get_user_human_skin_name(ID_SHOWHUD, szSkinName, charsmax(szSkinName));
			
			if(g_hero[ID_SHOWHUD])
			{
				if(zp_get_user_wpnlvl(ID_SHOWHUD) < 5)
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "[%L: %d | %s]^n[%L: %d] [%s] [%L: %d/%d%%]^n^n", ID_SHOWHUD, "HUD_HP", pev(ID_SHOWHUD, pev_health), class, ID_SHOWHUD, "HUD_AMMO", zp_get_user_ammo(ID_SHOWHUD), szLvl, ID_SHOWHUD, "HUD_WL", zp_get_user_wpnlvl(ID_SHOWHUD), zp_user_wpnlvl_progress(ID_SHOWHUD))
				}
				else
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "[%L: %d | %s]^n[%L: %d] [%s] [%L: Max]^n^n", ID_SHOWHUD, "HUD_HP", pev(ID_SHOWHUD, pev_health), class, ID_SHOWHUD, "HUD_AMMO", zp_get_user_ammo(ID_SHOWHUD), szLvl, ID_SHOWHUD, "HUD_WL")
				}
			}
			else
			{
				if(zp_get_user_wpnlvl(ID_SHOWHUD) < 5)
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "[%L: %d | %s]^n[%L: %d] [%s] [%L: %d/%d%%]^n^n", ID_SHOWHUD, "HUD_HP", pev(ID_SHOWHUD, pev_health), szSkinName, ID_SHOWHUD, "HUD_AMMO", zp_get_user_ammo(ID_SHOWHUD), szLvl, ID_SHOWHUD, "HUD_WL", zp_get_user_wpnlvl(ID_SHOWHUD), zp_user_wpnlvl_progress(ID_SHOWHUD))
				}
				else
				{
					ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync2, "[%L: %d | %s]^n[%L: %d] [%s] [%L: Max]^n^n", ID_SHOWHUD, "HUD_HP", pev(ID_SHOWHUD, pev_health), szSkinName, ID_SHOWHUD, "HUD_AMMO", zp_get_user_ammo(ID_SHOWHUD), szLvl, ID_SHOWHUD, "HUD_WL")
				}
			}
		}
	}
}


stock convert_lvl_to_text(id, szBuffer[], iLen)
{
	new iNextExp = zpe_get_user_next_exp(id);

	if(iNextExp == -1)
		formatex(szBuffer, iLen, "EXP: %d", zpe_get_user_exp(id));
	else
		formatex(szBuffer, iLen, "LVL: %d | EXP: %d/%d", zpe_get_user_lvl(id), zpe_get_user_exp(id), iNextExp);
}

// Play idle zombie sounds
public zombie_play_idle(taskid)
{
	// Round ended/new one starting
	if (g_endround || g_newround)
		return;
	
	static sound[64]
	
	// Last zombie?
	if (g_lastzombie[ID_BLOOD])
	{
		static pointers[10], end
		ArrayGetArray(pointer_class_sound_idle_last, g_zombieclass[ID_BLOOD], pointers)
		
		for (new i; i < 10; i++)
		{
			if (pointers[i] != -1)
			end = i
		}
		ArrayGetString(class_sound_idle_last, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
		emit_sound(ID_BLOOD, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else if(g_nemesis[ID_BLOOD])
	{
		ArrayGetString(nemesis_idle, random_num(0, ArraySize(nemesis_idle) - 1), sound, charsmax(sound))
		emit_sound(ID_BLOOD, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else
	{
		static pointers[10], end
		ArrayGetArray(pointer_class_sound_idle, g_zombieclass[ID_BLOOD], pointers)

		for (new i; i < 10; i++)
		{
			if (pointers[i] != -1)
			end = i
		}
		ArrayGetString(class_sound_idle, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
		emit_sound(ID_BLOOD, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

// Madness Over Task
public madness_over(taskid)
{
	set_entvar(ID_BLOOD, var_takedamage, DAMAGE_AIM);
}

// Place user at a random spawn
do_random_spawn(id, regularspawns = 0)
{
	static hull, sp_index, i
	
	// Get whether the player is crouching
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	// Use regular spawns?
	if (!regularspawns)
	{
		// No spawns?
		if (!g_spawnCount)
			return;
		
		// Choose random spawn to start looping at
		sp_index = random_num(0, g_spawnCount - 1)
		
		// Try to find a clear spawn
		for (i = sp_index + 1; /*no condition*/; i++)
		{
			// Start over when we reach the end
			if (i >= g_spawnCount) i = 0
			
			// Free spawn space?
			if (is_hull_vacant(g_spawns[i], hull))
			{
				// Engfunc_SetOrigin is used so ent's mins and maxs get updated instantly
				engfunc(EngFunc_SetOrigin, id, g_spawns[i])
				break;
			}
			
			// Loop completed, no free space found
			if (i == sp_index) break;
		}
	}
	else
	{
		// No spawns?
		if (!g_spawnCount2)
			return;
		
		// Choose random spawn to start looping at
		sp_index = random_num(0, g_spawnCount2 - 1)
		
		// Try to find a clear spawn
		for (i = sp_index + 1; /*no condition*/; i++)
		{
			// Start over when we reach the end
			if (i >= g_spawnCount2) i = 0
			
			// Free spawn space?
			if (is_hull_vacant(g_spawns2[i], hull))
			{
				// Engfunc_SetOrigin is used so ent's mins and maxs get updated instantly
				engfunc(EngFunc_SetOrigin, id, g_spawns2[i])
				break;
			}
			
			// Loop completed, no free space found
			if (i == sp_index) break;
		}
	}
}


// Get Zombies -returns alive zombies number-
fnGetZombies()
{
	static iZombies, id
	iZombies = 0
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (g_isalive[id] && g_zombie[id])
			iZombies++
	}
	
	return iZombies;
}

// Get Humans -returns alive humans number-
fnGetHumans()
{
	static iHumans, id
	iHumans = 0
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (g_isalive[id] && !g_zombie[id])
			iHumans++
	}
	
	return iHumans;
}

// Get Nemesis -returns alive nemesis number-
fnGetNemesis()
{
	static iNemesis, id
	iNemesis = 0
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (g_isalive[id] && g_nemesis[id])
			iNemesis++
	}
	
	return iNemesis;
}

// Get Survivors -returns alive survivors number-
fnGetSurvivors()
{
	static iSurvivors, id
	iSurvivors = 0
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (g_isalive[id] && g_survivor[id])
			iSurvivors++
	}
	
	return iSurvivors;
}

// Get Alive -returns alive players number-
fnGetAlive()
{
	static iAlive, id
	iAlive = 0
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (g_isalive[id])
			iAlive++
	}
	
	return iAlive;
}

// Get Random Alive -returns index of alive player number n -
fnGetRandomAlive(n)
{
	static iAlive, id
	iAlive = 0
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (g_isalive[id])
			iAlive++
		
		if (iAlive == n)
			return id;
	}
	
	return -1;
}

// Get Playing -returns number of users playing-
/*fnGetPlaying()
{
	static iPlaying, id, team
	iPlaying = 0
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (g_isconnected[id])
		{
			team = zp_get_user_team(id)
			
			if (team != TEAM_SPECTATOR && team != TEAM_UNASSIGNED)
				iPlaying++
		}
	}
	
	return iPlaying;
}*/

// Get CTs -returns number of CTs connected-
fnGetCTs()
{
	static iCTs, id
	iCTs = 0
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (g_isconnected[id])
		{			
			if (zp_get_user_team(id) == TEAM_CT)
				iCTs++
		}
	}
	
	return iCTs;
}

// Get Ts -returns number of Ts connected-
fnGetTs()
{
	static iTs, id
	iTs = 0
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (g_isconnected[id])
		{			
			if (zp_get_user_team(id) == TEAM_TERRORIST)
				iTs++
		}
	}
	
	return iTs;
}

// Get Alive CTs -returns number of CTs alive-
/*fnGetAliveCTs()
{
	static iCTs, id
	iCTs = 0
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (g_isalive[id])
		{			
			if (zp_get_user_team(id) == TEAM_CT)
				iCTs++
		}
	}
	
	return iCTs;
}

// Get Alive Ts -returns number of Ts alive-
fnGetAliveTs()
{
	static iTs, id
	iTs = 0
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (g_isalive[id])
		{			
			if (zp_get_user_team(id) == TEAM_TERRORIST)
				iTs++
		}
	}
	
	return iTs;
}*/

// Last Zombie Check -check for last zombie and set its flag-
fnCheckLastZombie()
{
	static id
	for (id = 1; id <= g_maxplayers; id++)
	{
		// Last zombie
		if (g_isalive[id] && g_zombie[id] && !g_nemesis[id] && fnGetZombies() == 1)
		{
			if (!g_lastzombie[id])
			{
				// Last zombie forward
				ExecuteForward(g_fwUserLastZombie, g_fwDummyResult, id);
			}
			g_lastzombie[id] = true
		}
		else
		{
			g_lastzombie[id] = false
		}
		
		// Last human
		if (g_isalive[id] && !g_zombie[id] && !g_survivor[id] && fnGetHumans() == 1)
		{
			if (!g_lasthuman[id])
			{
				// Last human forward
				ExecuteForward(g_fwUserLastHuman, g_fwDummyResult, id);
				
				// Reward extra hp
				fm_set_user_health(id, pev(id, pev_health) + get_pcvar_num(cvar_humanlasthp))
			}
			g_lasthuman[id] = true
		}
		else
		{
			g_lasthuman[id] = false
		}
	}
}

// Save player's stats to database
save_stats(id)
{
	// Check whether there is another record already in that slot
	if (db_name[id][0] && !equal(g_playername[id], db_name[id]))
	{
		// If DB size is exceeded, write over old records
		if (db_slot_i >= sizeof db_name)
			db_slot_i = g_maxplayers+1
		
		// Move previous record onto an additional save slot
		copy(db_name[db_slot_i], charsmax(db_name[]), db_name[id])
		db_ammopacks[db_slot_i] = db_ammopacks[id]
		db_zombieclass[db_slot_i] = db_zombieclass[id]
		db_slot_i++
	}
	
	// Now save the current player stats
	copy(db_name[id], charsmax(db_name[]), g_playername[id]) // name
	db_ammopacks[id] = g_ammopacks[id]  // ammo packs
	db_zombieclass[id] = g_zombieclassnext[id] // zombie class
}

// Load player's stats from database (if a record is found)
load_stats(id)
{
	// Look for a matching record
	static i
	for (i = 0; i < sizeof db_name; i++)
	{
		if (equal(g_playername[id], db_name[i]))
		{
			// Bingo!
			g_ammopacks[id] = db_ammopacks[i]
			g_zombieclass[id] = db_zombieclass[i]
			g_zombieclassnext[id] = db_zombieclass[i]
			return;
		}
	}
}

// Checks if a player is allowed to be zombie
allowed_zombie(id)
{
	if ((g_zombie[id] && !g_nemesis[id]) || g_endround || !g_isalive[id] ||  (!g_newround && !g_zombie[id] && fnGetHumans() == 1))
		return false;
	
	return true;
}

// Checks if a player is allowed to be human
allowed_human(id)
{
	if ((!g_zombie[id] && !g_survivor[id]) || g_endround || !g_isalive[id] || (!g_newround && g_zombie[id] && fnGetZombies() == 1))
		return false;
	
	return true;
}

// Checks if a player is allowed to be survivor
allowed_survivor(id)
{
	if (g_endround || g_survivor[id] || !g_isalive[id] || (!g_newround && g_zombie[id] && fnGetZombies() == 1))
		return false;
	
	return true;
}

// Checks if a player is allowed to be nemesis
allowed_nemesis(id)
{
	if (g_endround || g_nemesis[id] || !g_isalive[id] || (!g_newround && !g_zombie[id] && fnGetHumans() == 1))
		return false;
	
	return true;
}

// Checks if a player is allowed to respawn
allowed_respawn(id)
{
	static TeamName:team
	team = zp_get_user_team(id)
	
	if (g_endround || team == TEAM_SPECTATOR || team == TEAM_UNASSIGNED || g_isalive[id])
		return false;
	
	return true;
}

// Checks if swarm mode is allowed
allowed_swarm()
{
	if (g_endround || !g_newround)
		return false;
	
	return true;
}

// Checks if multi infection mode is allowed
allowed_multi()
{
	if (g_endround || !g_newround || floatround(fnGetAlive()*get_pcvar_float(cvar_multiratio), floatround_ceil) < 2 || floatround(fnGetAlive()*get_pcvar_float(cvar_multiratio), floatround_ceil) >= fnGetAlive())
		return false;
	
	return true;
}

// Checks if plague mode is allowed
allowed_plague()
{
	if (g_endround || !g_newround || floatround((fnGetAlive()-(get_pcvar_num(cvar_plaguenemnum)+get_pcvar_num(cvar_plaguesurvnum)))*get_pcvar_float(cvar_plagueratio), floatround_ceil) < 1
	|| fnGetAlive()-(get_pcvar_num(cvar_plaguesurvnum)+get_pcvar_num(cvar_plaguenemnum)+floatround((fnGetAlive()-(get_pcvar_num(cvar_plaguenemnum)+get_pcvar_num(cvar_plaguesurvnum)))*get_pcvar_float(cvar_plagueratio), floatround_ceil)) < 1)
		return false;
	
	return true;
}

// Admin Command. zp_zombie
command_zombie(id, player)
{
	zp_colored_print(0, "^x04[ZP]^x01 Админ ^x04%s ^x01превратил ^x04%s^x01 %L", g_playername[id], g_playername[player], id, "CMD_INFECT")
	
	// New round?
	if (g_newround)
	{
		// Set as first zombie
		remove_task(TASK_MAKEZOMBIE)
		make_a_zombie(MODE_INFECTION, player)
	}
	else
	{
		// Just infect
		zombieme(player, 0, 0, 0, 0)
	}
}

// Admin Command. zp_human
command_human(id, player)
{
	zp_colored_print(0, "^x04[ZP]^x01 Админ ^x04%s ^x01%L ^x04%s", g_playername[id], id, "CMD_DISINFECT", g_playername[player])
	
	// Turn to human
	humanme(player, 0, 0, 0)
}

// Admin Command. zp_survivor
command_survivor(id, player)
{
	zp_colored_print(0, "^x04[ZP]^x01 Админ ^x04%s ^x01%L ^x04%s", g_playername[id], id, "CMD_SURVIVAL", g_playername[player])
	
	// New round?
	if (g_newround)
	{
		// Set as first survivor
		remove_task(TASK_MAKEZOMBIE)
		make_a_zombie(MODE_SURVIVOR, player)
	}
	else
	{
		// Turn player into a Survivor
		humanme(player, 0, 1, 0)
	}
}

// Admin Command. zp_nemesis
command_nemesis(id, player)
{
	zp_colored_print(0, "^x04[ZP]^x01 Админ ^x04%s ^x01превратил ^x04%s^x01 %L", g_playername[id], g_playername[player], id, "CMD_NEMESIS")
	
	// New round?
	if (g_newround)
	{
		// Set as first nemesis
		remove_task(TASK_MAKEZOMBIE)
		make_a_zombie(MODE_NEMESIS, player)
	}
	else
	{
		// Turn player into a Nemesis
		zombieme(player, 0, 1, 0, 0)
	}
}

// Admin Command. zp_respawn
command_respawn(id, player)
{
	zp_colored_print(0, "^x04[ZP]^x01 Админ ^x04%s ^x01%L ^x04%s", g_playername[id], id, "CMD_RESPAWN", g_playername[player])
	
	// Respawn as zombie?
	if (get_pcvar_num(cvar_deathmatch) == 2 || (get_pcvar_num(cvar_deathmatch) == 3 && random_num(0, 1)) || (get_pcvar_num(cvar_deathmatch) == 4 && fnGetZombies() < fnGetAlive()/2))
		g_respawn_as_zombie[player] = true
	
	// Override respawn as zombie setting on nemesis and survivor rounds
	if (g_survround) g_respawn_as_zombie[player] = true
	else if (g_nemround) g_respawn_as_zombie[player] = false
	
	respawn_player_manually(player);
}

// Admin Command. zp_swarm
command_swarm(id)
{
	zp_colored_print(0, "^x04[ZP]^x01 Админ ^x04%s ^x01%L", g_playername[id], id, "CMD_SWARM")
	
	// Call Swarm Mode
	remove_task(TASK_MAKEZOMBIE)
	make_a_zombie(MODE_SWARM, 0)
}

// Admin Command. zp_multi
command_multi(id)
{
	zp_colored_print(0, "^x04[ZP]^x01 Админ ^x04%s ^x01%L", g_playername[id], id, "CMD_MULTI")
	
	// Call Multi Infection
	remove_task(TASK_MAKEZOMBIE)
	make_a_zombie(MODE_MULTI, 0)
}

// Admin Command. zp_plague
command_plague(id)
{
	zp_colored_print(0, "^x04[ZP]^x01 Админ ^x04%s ^x01%L", g_playername[id], id, "CMD_PLAGUE")
	
	// Call Plague Mode
	remove_task(TASK_MAKEZOMBIE)
	make_a_zombie(MODE_PLAGUE, 0)
}

// Set proper maxspeed for player
set_player_maxspeed(id)
{
	if (g_zombie[id])
	{
		if (g_nemesis[id])
			rg_set_user_maxspeed(id, get_pcvar_float(cvar_nemspd));
		else
			rg_set_user_maxspeed(id, g_zombie_spd[id]);
	}
	else
	{
		//rg_set_user_maxspeed(id, 1.0, e_SpeedMul);
		if (g_survivor[id])
			rg_set_user_maxspeed(id, get_pcvar_float(cvar_survspd));
		else if (get_pcvar_float(cvar_humanspd) > 0.0)
			rg_set_user_maxspeed(id, get_pcvar_float(cvar_humanspd));
	}
}

/*================================================================================
 [Custom Natives]
=================================================================================*/

// Native: zp_get_user_zombie
public native_get_user_zombie(id)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_zombie[id];
}

// Native: zp_get_user_nemesis
public native_get_user_nemesis(id)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_nemesis[id];
}

// Native: zp_get_user_survivor
public native_get_user_survivor(id)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_survivor[id];
}

public native_get_user_hero(id)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_hero[id];
}

public native_get_user_first_zombie(id)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_firstzombie[id];
}

// Native: zp_get_user_last_zombie
public native_get_user_last_zombie(id)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_lastzombie[id];
}

// Native: zp_get_user_last_human
public native_get_user_last_human(id)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_lasthuman[id];
}

// Native: zp_get_user_zombie_class
public native_get_user_zombie_class(id)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_zombieclass[id];
}

// Native: zp_get_user_next_class
public native_get_user_next_class(id)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_zombieclassnext[id];
}

// Native: zp_set_user_zombie_class
public native_set_user_zombie_class(id, classid)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
/*	if (classid < 0 || classid >= g_zclass_i)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}
*/	
	if(classid == 6 && ~get_user_flags(id) & ADMIN_LEVEL_H)
	{
		g_zombieclassnext[id] = 0;
		return true;
	}
	
	if(classid == 7 && ~get_user_flags(id) & ADMIN_LEVEL_D)
	{
		g_zombieclassnext[id] = 0;
		return true;
	}

	if(classid == 8 && ~get_user_flags(id) & ADMIN_LEVEL_G)
	{
		g_zombieclassnext[id] = 0;
		return true;
	}

	g_zombieclassnext[id] = classid
	return true;
}

// Native: zp_get_user_ammo_packs
public native_get_user_ammo_packs(id)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_ammopacks[id];
}

// Native: zp_set_user_ammo_packs
public native_set_user_ammo_packs(id, amount)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	g_ammopacks[id] = amount;
	return true;
}

// Native: zp_get_zombie_maxhealth
public native_get_zombie_maxhealth(id)
{
	// ZP disabled
	if (!g_pluginenabled)
		return -1;
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	if (!g_zombie[id] || g_nemesis[id])
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player not a normal zombie (%d)", id)
		return -1;
	}
	
	if (g_firstzombie[id])
		return floatround(float(ArrayGetCell(g_zclass_hp, g_zombieclass[id])) + get_pcvar_num(cvar_zombiefirsthp) * fnGetAlive());
	
	return ArrayGetCell(g_zclass_hp, g_zombieclass[id]);
}

// Native: zp_get_user_batteries
public native_get_user_batteries(id)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_flashbattery[id];
}

// Native: zp_set_user_batteries
public native_set_user_batteries(id, value)
{
	// ZP disabled
	if (!g_pluginenabled)
		return false;
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	g_flashbattery[id] = clamp(value, 0, 100);
	
	if (g_cached_customflash)
	{
		// Set the flashlight charge task to update battery status
		remove_task(id+TASK_CHARGE)
		set_task(1.0, "flashlight_charge", id+TASK_CHARGE, _, _, "b")
	}
	return true;
}

// Native: zp_get_user_nightvision
public native_get_user_nightvision(id)
{
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_nvision[id];
}

// Native: zp_set_user_nightvision
public native_set_user_nightvision(id, set)
{
	// ZP disabled
	if (!g_pluginenabled)
		return false;
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (set)
	{
		g_nvision[id] = true
		
		if (!g_isbot[id])
		{
			g_nvisionenabled[id] = true
			
			// Custom nvg?
			if (get_pcvar_num(cvar_customnvg))
			{
				remove_task(id+TASK_NVISION)
				set_task(0.1, "set_user_nvision", id+TASK_NVISION, _, _, "b")
			}
			else
				set_user_gnvision(id, 1)
		}
		else
			cs_set_user_nvg(id, 1)
	}
	else
	{
		// Remove CS nightvision if player owns one (bugfix)
		cs_set_user_nvg(id, 0)
		
		if (get_pcvar_num(cvar_customnvg)) remove_task(id+TASK_NVISION)
		else if (g_nvisionenabled[id]) set_user_gnvision(id, 0)
		g_nvision[id] = false
		g_nvisionenabled[id] = false
	}
	return true;
}

// Native: zp_infect_user
public native_infect_user(id, infector, silent, rewards)
{
	// ZP disabled
	if (!g_pluginenabled)
		return false;
	
	if (!is_user_valid_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	// Not allowed to be zombie
	if (!allowed_zombie(id))
		return false;
	
	// New round?
	if (g_newround)
	{
		// Set as first zombie
		remove_task(TASK_MAKEZOMBIE)
		make_a_zombie(MODE_INFECTION, id)
	}
	else
	{
		// Just infect (plus some checks)
		zombieme(id, is_user_valid_alive(infector) ? infector : 0, 0, (silent == 1) ? 1 : 0, (rewards == 1) ? 1 : 0)
	}
	return true;
}

// Native: zp_disinfect_user
public native_disinfect_user(id, silent)
{
	// ZP disabled
	if (!g_pluginenabled)
		return false;
	
	if (!is_user_valid_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	// Not allowed to be human
	if (!allowed_human(id))
		return false;
	
	// Turn to human
	humanme(id, 0, (silent == 1) ? 1 : 0, 0)
	return true;
}

// Native: zp_make_user_nemesis
public native_make_user_nemesis(id)
{
	// ZP disabled
	if (!g_pluginenabled)
		return false;
	
	if (!is_user_valid_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	// Not allowed to be nemesis
	if (!allowed_nemesis(id))
		return false;
	
	// New round?
	if (g_newround)
	{
		// Set as first nemesis
		remove_task(TASK_MAKEZOMBIE)
		make_a_zombie(MODE_NEMESIS, id)
	}
	else
	{
		// Turn player into a Nemesis
		zombieme(id, 0, 1, 0, 0)
	}
	return true;
}

// Native: zp_make_user_survivor
public native_make_user_survivor(id)
{
	// ZP disabled
	if (!g_pluginenabled)
		return false;
	
	if (!is_user_valid_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	// Not allowed to be survivor
	if (!allowed_survivor(id))
		return false;
	
	// New round?
	if (g_newround)
	{
		// Set as first survivor
		remove_task(TASK_MAKEZOMBIE)
		make_a_zombie(MODE_SURVIVOR, id)
	}
	else
	{
		// Turn player into a Survivor
		humanme(id, 0, 1, 0)
	}
	
	return true;
}

// Native: zp_respawn_user
public native_respawn_user(id, team)
{
	// ZP disabled
	if (!g_pluginenabled)
		return false;
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	// Respawn not allowed
	if (!allowed_respawn(id))
		return false;
	
	// Respawn as zombie?
	g_respawn_as_zombie[id] = (team == ZP_TEAM_ZOMBIE) ? true : false
	
	// Respawnish!
	respawn_player_manually(id)
	return true;
}

// Native: zp_force_buy_extra_item
public native_force_buy_extra_item(id, itemid, ignorecost)
{
	// ZP disabled
	if (!g_pluginenabled)
		return false;
	
	if (!is_user_valid_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (itemid < 0 || itemid >= g_extraitem_i)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid extra item id (%d)", itemid)
		return false;
	}
	
	buy_extra_item(id, itemid, ignorecost)
	return true;
}

// Native: zp_override_user_model
public native_override_user_model(id, const newmodel[], modelindex)
{
	// ZP disabled
	if (!g_pluginenabled)
		return false;
	
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	// Strings passed byref
	param_convert(2)
	
	// Remove previous tasks
	remove_task(id+TASK_MODEL)
	
	// Custom models stuff
	zp_set_user_model(id, newmodel, modelindex);

	return true;
}
/**
 * Получение рандомного звука горения по класс иду
 */
// native bool:zp_get_random_burn_sound(const pClassId, szSound[], iLen)
bool:@zp_get_random_burn_sound(iPlugin, iParamsCount)
{
	enum {Arg_pClassId = 1, Arg_szSound, Arg_iLen};

	if(iParamsCount < Arg_iLen) return false;

	new pClassId = get_param(Arg_pClassId), iLen = get_param(Arg_iLen);

	new sound[64], pointers[10], end
	ArrayGetArray(pointer_class_sound_burn, pClassId, pointers)
			
	for (new i; i < 10; i++)
	{
		if (pointers[i] != -1)
		end = i
	}

	ArrayGetString(class_sound_burn, random_num(pointers[0], pointers[end]), sound, charsmax(sound))
	set_string(Arg_szSound, sound, iLen);
	return true;
	//emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

// Native: zp_has_round_started
public native_has_round_started()
{
	if (g_newround) return 0; // not started
	if (g_modestarted) return 1; // started
	return 2; // starting
}

// Native: zp_is_nemesis_round
public native_is_nemesis_round()
{
	return g_nemround;
}

// Native: zp_is_survivor_round
public native_is_survivor_round()
{
	return g_survround;
}

// Native: zp_is_swarm_round
public native_is_swarm_round()
{
	return g_swarmround;
}

// Native: zp_is_plague_round
public native_is_plague_round()
{
	return g_plagueround;
}

// Native: zp_is_round_end
public native_is_round_end()
{
	return g_endround;
}

// Native: zp_get_zombie_count
public native_get_zombie_count()
{
	return fnGetZombies();
}

// Native: zp_get_human_count
public native_get_human_count()
{
	return fnGetHumans();
}

// Native: zp_get_nemesis_count
public native_get_nemesis_count()
{
	return fnGetNemesis();
}

// Native: zp_get_survivor_count
public native_get_survivor_count()
{
	return fnGetSurvivors();
}

// Native: zp_register_extra_item
public native_register_extra_item(const name[], cost, team)
{
	// ZP disabled
	if (!g_pluginenabled)
		return -1;
	
	// Strings passed byref
	param_convert(1)
	
	// Arrays not yet initialized
	if (!g_arrays_created)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register extra item yet (%s)", name)
		return -1;
	}
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register extra item with an empty name")
		return -1;
	}
	
	new index, extraitem_name[32]
	for (index = 0; index < g_extraitem_i; index++)
	{
		ArrayGetString(g_extraitem_name, index, extraitem_name, charsmax(extraitem_name))
		if (equali(name, extraitem_name))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Extra item already registered (%s)", name)
			return -1;
		}
	}
	
	// For backwards compatibility
	if (team == ZP_TEAM_ANY)
		team = (ZP_TEAM_ZOMBIE|ZP_TEAM_HUMAN)
	
	// Add the item
	ArrayPushString(g_extraitem_name, name)
	ArrayPushCell(g_extraitem_cost, cost)
	ArrayPushCell(g_extraitem_team, team)
	
	// Set temporary new item flag
	ArrayPushCell(g_extraitem_new, 1)
	
	// Override extra items data with our customizations
	new i, buffer[32], size = ArraySize(g_extraitem2_realname)
	for (i = 0; i < size; i++)
	{
		ArrayGetString(g_extraitem2_realname, i, buffer, charsmax(buffer))
		
		// Check if this is the intended item to override
		if (!equal(name, buffer))
			continue;
		
		// Remove new item flag
		ArraySetCell(g_extraitem_new, g_extraitem_i, 0)
		
		// Replace caption
		ArrayGetString(g_extraitem2_name, i, buffer, charsmax(buffer))
		ArraySetString(g_extraitem_name, g_extraitem_i, buffer)
		
		// Replace cost
		buffer[0] = ArrayGetCell(g_extraitem2_cost, i)
		ArraySetCell(g_extraitem_cost, g_extraitem_i, buffer[0])
		
		// Replace team
		buffer[0] = ArrayGetCell(g_extraitem2_team, i)
		ArraySetCell(g_extraitem_team, g_extraitem_i, buffer[0])
	}
	
	// Increase registered items counter
	g_extraitem_i++
	
	// Return id under which we registered the item
	return g_extraitem_i-1;
}

// Function: zp_register_extra_item (to be used within this plugin only)
native_register_extra_item2(const name[], cost, team)
{
	// Add the item
	ArrayPushString(g_extraitem_name, name)
	ArrayPushCell(g_extraitem_cost, cost)
	ArrayPushCell(g_extraitem_team, team)
	
	// Set temporary new item flag
	ArrayPushCell(g_extraitem_new, 1)
	
	// Increase registered items counter
	g_extraitem_i++
}

// Native: zp_register_zombie_class

public native_register_zombie_class(const name[], const info[], const model[], const clawmodel[], hp, speed, Float:gravity, Float:knockback)
{
	// ZP disabled
	if (!g_pluginenabled)
		return -1;
	
	// Strings passed byref
	param_convert(1)
	param_convert(2)
	param_convert(3)
	param_convert(4)
	
	// Arrays not yet initialized
	if (!g_arrays_created)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register zombie class yet (%s)", name)
		return -1;
	}
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register zombie class with an empty name")
		return -1;
	}
	
	new index, zombieclass_name[32]
	for (index = 0; index < g_zclass_i; index++)
	{
		ArrayGetString(g_zclass_name, index, zombieclass_name, charsmax(zombieclass_name))
		if (equali(name, zombieclass_name))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Zombie class already registered (%s)", name)
			return -1;
		}
	}
	
	// Add the class
	ArrayPushString(g_zclass_name, name)
	ArrayPushString(g_zclass_info, info)
	
	// Using same zombie models for all classes?
	if (g_same_models_for_all)
	{
		ArrayPushCell(g_zclass_modelsstart, 0)
		ArrayPushCell(g_zclass_modelsend, ArraySize(g_zclass_playermodel))
	}
	else
	{
		ArrayPushCell(g_zclass_modelsstart, ArraySize(g_zclass_playermodel))
		ArrayPushString(g_zclass_playermodel, model)
		ArrayPushCell(g_zclass_modelsend, ArraySize(g_zclass_playermodel))
		ArrayPushCell(g_zclass_modelindex, -1)
	}
	
	ArrayPushString(g_zclass_clawmodel, clawmodel)
	ArrayPushCell(g_zclass_hp, hp)
	ArrayPushCell(g_zclass_maxhp, 5000)
	ArrayPushCell(g_zclass_spd, speed)
	ArrayPushCell(g_zclass_grav, gravity)
	ArrayPushCell(g_zclass_kb, knockback)
	
	// Set temporary new class flag
	ArrayPushCell(g_zclass_new, 1)
	
	// Override zombie classes data with our customizations
	new i, k, buffer[32], Float:buffer2, nummodels_custom, nummodels_default, prec_mdl[100], size = ArraySize(g_zclass2_realname)
	for (i = 0; i < size; i++)
	{
		ArrayGetString(g_zclass2_realname, i, buffer, charsmax(buffer))
		
		// Check if this is the intended class to override
		if (!equal(name, buffer))
			continue;
		
		// Remove new class flag
		ArraySetCell(g_zclass_new, g_zclass_i, 0)
		
		// Replace caption
		ArrayGetString(g_zclass2_name, i, buffer, charsmax(buffer))
		ArraySetString(g_zclass_name, g_zclass_i, buffer)
		
		// Replace info
		ArrayGetString(g_zclass2_info, i, buffer, charsmax(buffer))
		ArraySetString(g_zclass_info, g_zclass_i, buffer)
		
		// Replace models, unless using same models for all classes
		if (!g_same_models_for_all)
		{
			nummodels_custom = ArrayGetCell(g_zclass2_modelsend, i) - ArrayGetCell(g_zclass2_modelsstart, i)
			nummodels_default = ArrayGetCell(g_zclass_modelsend, g_zclass_i) - ArrayGetCell(g_zclass_modelsstart, g_zclass_i)
			
			// Replace each player model and model index
			for (k = 0; k < min(nummodels_custom, nummodels_default); k++)
			{
				ArrayGetString(g_zclass2_playermodel, ArrayGetCell(g_zclass2_modelsstart, i) + k, buffer, charsmax(buffer))
				ArraySetString(g_zclass_playermodel, ArrayGetCell(g_zclass_modelsstart, g_zclass_i) + k, buffer)
				
				// Precache player model and replace its modelindex with the real one
				formatex(prec_mdl, charsmax(prec_mdl), "models/player/%s/%s.mdl", buffer, buffer)
				ArraySetCell(g_zclass_modelindex, ArrayGetCell(g_zclass_modelsstart, g_zclass_i) + k, engfunc(EngFunc_PrecacheModel, prec_mdl))
				if (g_force_consistency == 1) force_unmodified(force_model_samebounds, {0,0,0}, {0,0,0}, prec_mdl)
				if (g_force_consistency == 2) force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, prec_mdl)
				// Precache modelT.mdl files too
				copy(prec_mdl[strlen(prec_mdl)-4], charsmax(prec_mdl) - (strlen(prec_mdl)-4), "T.mdl")
				if (file_exists(prec_mdl)) engfunc(EngFunc_PrecacheModel, prec_mdl)
			}
			
			// We have more custom models than what we can accommodate,
			// Let's make some space...
			if (nummodels_custom > nummodels_default)
			{
				for (k = nummodels_default; k < nummodels_custom; k++)
				{
					ArrayGetString(g_zclass2_playermodel, ArrayGetCell(g_zclass2_modelsstart, i) + k, buffer, charsmax(buffer))
					ArrayInsertStringAfter(g_zclass_playermodel, ArrayGetCell(g_zclass_modelsstart, g_zclass_i) + k - 1, buffer)
					
					// Precache player model and retrieve its modelindex
					formatex(prec_mdl, charsmax(prec_mdl), "models/player/%s/%s.mdl", buffer, buffer)
					ArrayInsertCellAfter(g_zclass_modelindex, ArrayGetCell(g_zclass_modelsstart, g_zclass_i) + k - 1, engfunc(EngFunc_PrecacheModel, prec_mdl))
					if (g_force_consistency == 1) force_unmodified(force_model_samebounds, {0,0,0}, {0,0,0}, prec_mdl)
					if (g_force_consistency == 2) force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, prec_mdl)
					// Precache modelT.mdl files too
					copy(prec_mdl[strlen(prec_mdl)-4], charsmax(prec_mdl) - (strlen(prec_mdl)-4), "T.mdl")
					if (file_exists(prec_mdl)) engfunc(EngFunc_PrecacheModel, prec_mdl)
				}
				
				// Fix models end index for this class
				ArraySetCell(g_zclass_modelsend, g_zclass_i, ArrayGetCell(g_zclass_modelsend, g_zclass_i) + (nummodels_custom - nummodels_default))
			}
			
			// --- Not needed since classes can't have more than 1 default model for now ---
			// We have less custom models than what this class has by default,
			// Get rid of those extra entries...
			if (nummodels_custom < nummodels_default)
			{
				for (k = nummodels_custom; k < nummodels_default; k++)
				{
					ArrayDeleteItem(g_zclass_playermodel, ArrayGetCell(g_zclass_modelsstart, g_zclass_i) + nummodels_custom)
				}
				
				// Fix models end index for this class
				ArraySetCell(g_zclass_modelsend, g_zclass_i, ArrayGetCell(g_zclass_modelsend, g_zclass_i) - (nummodels_default - nummodels_custom))
			}
			
		}
		
		// Replace clawmodel
		ArrayGetString(g_zclass2_clawmodel, i, buffer, charsmax(buffer))
		ArraySetString(g_zclass_clawmodel, g_zclass_i, buffer)
		
		// Precache clawmodel
		formatex(prec_mdl, charsmax(prec_mdl), "models/zp_br_cso/zombie/claws/%s", buffer)
		engfunc(EngFunc_PrecacheModel, prec_mdl)
		
		// Replace health
		buffer[0] = ArrayGetCell(g_zclass2_hp, i)
		ArraySetCell(g_zclass_hp, g_zclass_i, buffer[0])
		
		// Replace max health
		buffer[0] = ArrayGetCell(g_zclass2_maxhp, i)
		ArraySetCell(g_zclass_maxhp, g_zclass_i, buffer[0])
		
		// Replace speed
		buffer[0] = ArrayGetCell(g_zclass2_spd, i)
		ArraySetCell(g_zclass_spd, g_zclass_i, buffer[0])
		
		// Replace gravity
		buffer2 = Float:ArrayGetCell(g_zclass2_grav, i)
		ArraySetCell(g_zclass_grav, g_zclass_i, buffer2)
		
		// Replace knockback
		buffer2 = Float:ArrayGetCell(g_zclass2_kb, i)
		ArraySetCell(g_zclass_kb, g_zclass_i, buffer2)
	}
	
	// If class was not overriden with customization data
	if (ArrayGetCell(g_zclass_new, g_zclass_i))
	{
		// If not using same models for all classes
		if (!g_same_models_for_all)
		{
			// Precache default class model and replace modelindex with the real one
			formatex(prec_mdl, charsmax(prec_mdl), "models/player/%s/%s.mdl", model, model)
			ArraySetCell(g_zclass_modelindex, ArrayGetCell(g_zclass_modelsstart, g_zclass_i), engfunc(EngFunc_PrecacheModel, prec_mdl))
			if (g_force_consistency == 1) force_unmodified(force_model_samebounds, {0,0,0}, {0,0,0}, prec_mdl)
			if (g_force_consistency == 2) force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, prec_mdl)
			// Precache modelT.mdl files too
			copy(prec_mdl[strlen(prec_mdl)-4], charsmax(prec_mdl) - (strlen(prec_mdl)-4), "T.mdl")
			if (file_exists(prec_mdl)) engfunc(EngFunc_PrecacheModel, prec_mdl)
		}
		
		// Precache default clawmodel
		formatex(prec_mdl, charsmax(prec_mdl), "models/zp_br_cso/zombie/claws/%s", clawmodel)
		engfunc(EngFunc_PrecacheModel, prec_mdl)
	}
	
	// Increase registered classes counter
	g_zclass_i++
	
	// Return id under which we registered the class
	return g_zclass_i-1;
}

// Native: zp_get_extra_item_id
public native_get_extra_item_id(const name[])
{
	// ZP disabled
	if (!g_pluginenabled)
		return -1;
	
	// Strings passed byref
	param_convert(1)
	
	// Loop through every item (not using Tries since ZP should work on AMXX 1.8.0)
	static i, item_name[32]
	for (i = 0; i < g_extraitem_i; i++)
	{
		ArrayGetString(g_extraitem_name, i, item_name, charsmax(item_name))
		
		// Check if this is the item to retrieve
		if (equali(name, item_name))
			return i;
	}
	
	return -1;
}

// Native: zp_get_zombie_class_id
public native_get_zombie_class_id(const name[])
{
	// ZP disabled
	if (!g_pluginenabled)
		return -1;
	
	// Strings passed byref
	param_convert(1)
	
	// Loop through every class (not using Tries since ZP should work on AMXX 1.8.0)
	static i, class_name[32]
	for (i = 0; i < g_zclass_i; i++)
	{
		ArrayGetString(g_zclass_name, i, class_name, charsmax(class_name))
		
		// Check if this is the class to retrieve
		if (equali(name, class_name))
			return i;
	}
	
	return -1;
}

// Native: zp_get_zombie_class_info
public native_get_zombie_class_info(classid, info[], len)
{
	// ZP disabled
	if (!g_pluginenabled)
		return false;
	
	// Invalid class
	/*if (classid < 0 || classid >= g_zclass_i)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid zombie class id (%d)", classid)
		return false;
	}*/
	
	// Strings passed byref
	/*param_convert(2)
	
	// Fetch zombie class info
	ArrayGetString(g_zclass_info, classid, info, len)
	return true;*/

	return false;
}

stock SCREEN_FADE(id, iDuration, iHoldtime, iFadeType, iRed, iGreen, iBlue, iAlpha)
{
	message_begin(MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, id)
	write_short(iDuration) // duration
	write_short(iHoldtime) // hold time
	write_short(iFadeType) // fade type
	write_byte(iRed) // r
	write_byte(iGreen) // g
	write_byte(iBlue) // b
	write_byte(iAlpha) // alpha
	message_end()
}

stock message_Smoke(Float:vecOrigin[3], pSprite, iScale, iFrameRate)
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin)
	write_byte(TE_SMOKE) // TE id
	write_coord_f(vecOrigin[0]) // x
	write_coord_f(vecOrigin[1]) // y
	write_coord_f(vecOrigin[2]) // z
	write_short(pSprite) // sprite
	write_byte(iScale) // scale
	write_byte(iFrameRate) // framerate
	message_end()
}

stock rg_remove_ent(iEnt)
{
	set_entvar(iEnt, var_flags, FL_KILLME);
	set_entvar(iEnt, var_nextthink, get_gametime());
}

public native_zp_roundstart()
{
	remove_task(TASK_MAKEZOMBIE)
	set_task(2.0 + get_pcvar_float(cvar_warmup), "make_zombie_task", TASK_MAKEZOMBIE)
	
	g_countdown = floatround(1.0 + get_pcvar_float(cvar_warmup))
				
	remove_task(TASK_COUNTDOWN)
	set_task(1.0, "countdown", TASK_COUNTDOWN, _, _, "b")
}


/*================================================================================
 [Custom Messages]
=================================================================================*/

public countdown()
{
	if(!g_countdown || g_modestarted)
	{
		remove_task(TASK_COUNTDOWN)
		return;
	}
	
	if(zp_check_vote())
	{
		remove_task(TASK_COUNTDOWN)
		remove_task(TASK_MAKEZOMBIE)
		return;
	}
	
	new szSound[32];
	
	if(g_countdown == 25)
	{
		zp_colored_print(0, "^x04[ZP]^x01 %L", LANG_PLAYER, "CMD_INFO_1")
		
		set_dhudmessage(0, 255, 0, -1.0, 0.78, 2, 0.125, 5.0, 0.125, 0.4)
		show_dhudmessage(0, "%L", LANG_PLAYER, "CMD_INFO_DHUD")
		
		PlaySound(START_ROUND_SOUND[random_num(0, 4)]);
	}
	else if(g_countdown == 12)
	{
		switch(random_num(0, 1))
		{
			case 0:
			{
				client_print(0, print_center, "%L", LANG_PLAYER, "COUNTDOWN_BATTLE_READY")
				PlaySound("sound/zp_br_cso/countdown/countdown_battle_2.wav");
			}
			case 1:
			{
				client_print(0, print_center, "%L", LANG_PLAYER, "COUNTDOWN_BATTLE_READY_2")
				PlaySound("sound/zp_br_cso/countdown/countdown_battle_1.wav");
			}
		}
	}
	else if(g_countdown <= 10)
	{
		client_print(0, print_center, "%L", LANG_PLAYER, "COUNTDOWN_SECONDS", g_countdown)
		
		format(szSound, 31, "sound/zp_br_cso/countdown/%d.wav", g_countdown)
		PlaySound(szSound)
	}
	
	g_countdown -= 1
}

// Custom Night Vision
public set_user_nvision(taskid)
{
	// Get player's origin
	static origin[3]
	get_user_origin(ID_NVISION, origin)
	
	// Nightvision message
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, ID_NVISION)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(get_pcvar_num(cvar_nvgsize)) // radius
	
	// Nemesis / Madness / Spectator in nemesis round
	if (g_nemesis[ID_NVISION] || (g_zombie[ID_NVISION] && Float:get_entvar(ID_NVISION, var_takedamage) == DAMAGE_NO) || (!g_isalive[ID_NVISION] && g_nemround))
	{
		write_byte(get_pcvar_num(cvar_nemnvgcolor[0])) // r
		write_byte(get_pcvar_num(cvar_nemnvgcolor[1])) // g
		write_byte(get_pcvar_num(cvar_nemnvgcolor[2])) // b
	}
	// Zombie
	else
	{
		write_byte(get_pcvar_num(cvar_nvgcolor[0])) // r
		write_byte(get_pcvar_num(cvar_nvgcolor[1])) // g
		write_byte(get_pcvar_num(cvar_nvgcolor[2])) // b
	}
	
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

// Game Nightvision
set_user_gnvision(id, toggle)
{
	// Toggle NVG message
	message_begin(MSG_ONE, g_msgNVGToggle, _, id)
	write_byte(toggle) // toggle
	message_end()
}

// Custom Flashlight
public set_user_flashlight(taskid)
{
	// Get player and aiming origins
	static Float:originF[3], Float:destoriginF[3]
	pev(ID_FLASH, pev_origin, originF)
	fm_get_aim_origin(ID_FLASH, destoriginF)
	
	// Max distance check
	if (get_distance_f(originF, destoriginF) > get_pcvar_float(cvar_flashdist))
		return;
	
	// Send to all players?
	if (get_pcvar_num(cvar_flashshowall))
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, destoriginF, 0)
	else
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, ID_FLASH)
	
	// Flashlight
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, destoriginF[0]) // x
	engfunc(EngFunc_WriteCoord, destoriginF[1]) // y
	engfunc(EngFunc_WriteCoord, destoriginF[2]) // z
	write_byte(get_pcvar_num(cvar_flashsize)) // radius
	write_byte(get_pcvar_num(cvar_flashcolor[0])) // r
	write_byte(get_pcvar_num(cvar_flashcolor[1])) // g
	write_byte(get_pcvar_num(cvar_flashcolor[2])) // b
	write_byte(3) // life
	write_byte(0) // decay rate
	message_end()
}

// Infection special effects
infection_effects(id)
{
	if (get_pcvar_num(cvar_infectionscreenfade))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, _, id)
		write_short(UNIT_SECOND) // duration
		write_short(0) // hold time
		write_short(FFADE_IN) // fade type
		if (g_nemesis[id])
		{
			write_byte(get_pcvar_num(cvar_nemnvgcolor[0])) // r
			write_byte(get_pcvar_num(cvar_nemnvgcolor[1])) // g
			write_byte(get_pcvar_num(cvar_nemnvgcolor[2])) // b
		}
		else
		{
			write_byte(get_pcvar_num(cvar_nvgcolor[0])) // r
			write_byte(get_pcvar_num(cvar_nvgcolor[1])) // g
			write_byte(get_pcvar_num(cvar_nvgcolor[2])) // b
		}
		write_byte (255) // alpha
		message_end()
	}
	
	// Screen shake?
	if (get_pcvar_num(cvar_infectionscreenshake))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
		write_short(UNIT_SECOND*4) // amplitude
		write_short(UNIT_SECOND*2) // duration
		write_short(UNIT_SECOND*10) // frequency
		message_end()
	}
	
	// Infection icon?
	if (get_pcvar_num(cvar_hudicons))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, id)
		write_byte(0) // damage save
		write_byte(0) // damage take
		write_long(DMG_NERVEGAS) // damage type - DMG_RADIATION
		write_coord(0) // x
		write_coord(0) // y
		write_coord(0) // z
		message_end()
	}
	
	// Get player's origin
	static origin[3]
	get_user_origin(id, origin)
	
	// Tracers?
	if (get_pcvar_num(cvar_infectiontracers))
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_IMPLOSION) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]) // z
		write_byte(128) // radius
		write_byte(20) // count
		write_byte(3) // duration
		message_end()
	}
	
	// Particle burst?
	if (get_pcvar_num(cvar_infectionparticles))
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_PARTICLEBURST) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]) // z
		write_short(50) // radius
		write_byte(70) // color
		write_byte(3) // duration (will be randomized a bit)
		message_end()
	}
	
	// Light sparkle?
	if (get_pcvar_num(cvar_infectionsparkle))
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_DLIGHT) // TE id
		write_coord(origin[0]) // x
		write_coord(origin[1]) // y
		write_coord(origin[2]) // z
		write_byte(20) // radius
		write_byte(get_pcvar_num(cvar_nvgcolor[0])) // r
		write_byte(get_pcvar_num(cvar_nvgcolor[1])) // g
		write_byte(get_pcvar_num(cvar_nvgcolor[2])) // b
		write_byte(2) // life
		write_byte(0) // decay rate
		message_end()
	}
}

// Nemesis/madness aura task
public zombie_aura(taskid)
{
	// Not nemesis, not in zombie madness
	if (!g_nemesis[ID_AURA] && Float:get_entvar(ID_AURA, var_takedamage) != DAMAGE_NO)
	{
		// Task not needed anymore
		remove_task(taskid);
		return;
	}
	
	// Get player's origin
	static origin[3]
	get_user_origin(ID_AURA, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(get_pcvar_num(cvar_nemnvgcolor[0])) // r
	write_byte(get_pcvar_num(cvar_nemnvgcolor[1])) // g
	write_byte(get_pcvar_num(cvar_nemnvgcolor[2])) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

// Make zombies leave footsteps and bloodstains on the floor
public make_blood(taskid)
{
	// Only bleed when moving on ground
	if (!(pev(ID_BLOOD, pev_flags) & FL_ONGROUND) || fm_get_speed(ID_BLOOD) < 80)
		return;
	
	// Get user origin
	static Float:originF[3]
	pev(ID_BLOOD, pev_origin, originF)
	
	// If ducking set a little lower
	if (pev(ID_BLOOD, pev_bInDuck))
		originF[2] -= 18.0
	else
		originF[2] -= 36.0
	
	// Send the decal message
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_WORLDDECAL) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_byte(ArrayGetCell(zombie_decals, random_num(0, ArraySize(zombie_decals) - 1)) + (g_czero * 12)) // random decal number (offsets +12 for CZ)
	message_end()
}

// Fix Dead Attrib on scoreboard
FixDeadAttrib(id)
{
	message_begin(MSG_BROADCAST, g_msgScoreAttrib)
	write_byte(id) // id
	write_byte(0) // attrib
	message_end()
}

// Send Death Message for infections
SendDeathMsg(attacker, victim)
{
	message_begin(MSG_ALL, g_msgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(0) // headshot flag
	write_string("teammate") // killer's weapon
	message_end()
}

// Update Player Frags and Deaths
UpdateFrags(attacker, victim, frags, deaths, scoreboard)
{
	// Set attacker frags
	set_pev(attacker, pev_frags, float(pev(attacker, pev_frags) + frags))
	
	// Set victim deaths
	fm_cs_set_user_deaths(victim, cs_get_user_deaths(victim) + deaths)
	
	// Update scoreboard with attacker and victim info
	if (scoreboard)
	{
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(attacker) // id
		write_short(pev(attacker, pev_frags)) // frags
		write_short(cs_get_user_deaths(attacker)) // deaths
		write_short(0) // class?
		write_short(cell:zp_get_user_team(attacker)) // team
		message_end()
		
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(victim) // id
		write_short(pev(victim, pev_frags)) // frags
		write_short(cs_get_user_deaths(victim)) // deaths
		write_short(0) // class?
		write_short(cell:zp_get_user_team(victim)) // team
		message_end()
	}
}

// Remove Player Frags (when Nemesis/Survivor ignore_frags cvar is enabled)
RemoveFrags(attacker, victim)
{
	// Remove attacker frags
	set_pev(attacker, pev_frags, float(pev(attacker, pev_frags) - 1))
	
	// Remove victim deaths
	fm_cs_set_user_deaths(victim, cs_get_user_deaths(victim) - 1)
}

// Plays a sound on clients
PlaySound(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}

// Prints a colored message to target (use 0 for everyone), supports ML formatting.
// Note: I still need to make something like gungame's LANG_PLAYER_C to avoid unintended
// argument replacement when a function passes -1 (it will be considered a LANG_PLAYER)
zp_colored_print(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	
	// Send to everyone
	if (!target)
	{
		static player
		for (player = 1; player <= g_maxplayers; player++)
		{
			// Not connected
			if (!g_isconnected[player])
				continue;
			
			// Remember changed arguments
			static changed[5], changedcount // [5] = max LANG_PLAYER occurencies
			changedcount = 0
			
			// Replace LANG_PLAYER with player id
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			// Format message for player
			vformat(buffer, charsmax(buffer), message, 3)
			
			// Send it
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			// Replace back player id's with LANG_PLAYER
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	// Send to specific target
	else
	{
		/*
		// Not needed since you should set the ML argument
		// to the player's id for a targeted print message
		
		// Replace LANG_PLAYER with player id
		for (i = 2; i < argscount; i++)
		{
			if (getarg(i) == LANG_PLAYER)
				setarg(i, 0, target)
		}
		*/
		
		// Format message for player
		vformat(buffer, charsmax(buffer), message, 3)
		
		// Send it
		message_begin(MSG_ONE, g_msgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}

/*================================================================================
 [Stocks]
=================================================================================*/

// Set an entity's key value (from fakemeta_util)
stock fm_set_kvd(entity, const key[], const value[], const classname[])
{
	set_kvd(0, KV_ClassName, classname)
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)

	dllfunc(DLLFunc_KeyValue, entity, 0)
}

// Set entity's rendering type (from fakemeta_util)
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

// Get entity's speed (from fakemeta_util)
stock fm_get_speed(entity)
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	
	return floatround(vector_length(velocity));
}

// Get entity's aim origins (from fakemeta_util)
stock fm_get_aim_origin(id, Float:origin[3])
{
	static Float:origin1F[3], Float:origin2F[3]
	pev(id, pev_origin, origin1F)
	pev(id, pev_view_ofs, origin2F)
	xs_vec_add(origin1F, origin2F, origin1F)

	pev(id, pev_v_angle, origin2F);
	engfunc(EngFunc_MakeVectors, origin2F)
	global_get(glb_v_forward, origin2F)
	xs_vec_mul_scalar(origin2F, 9999.0, origin2F)
	xs_vec_add(origin1F, origin2F, origin2F)

	engfunc(EngFunc_TraceLine, origin1F, origin2F, 0, id, 0)
	get_tr2(0, TR_vecEndPos, origin)
}

// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) { /* keep looping */ }
	return entity;
}

// Set player's health (from fakemeta_util)
stock fm_set_user_health(id, health)
{
	(health > 0) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}

// Give an item to a player (from fakemeta_util)
stock fm_give_item(id, const item[])
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent)) return;
	
	static Float:originF[3]
	pev(id, pev_origin, originF)
	set_pev(ent, pev_origin, originF)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	
	static save
	save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, id)
	if (pev(ent, pev_solid) != save)
		return;
	
	engfunc(EngFunc_RemoveEntity, ent)
}

// Strip user weapons (from fakemeta_util)
stock fm_strip_user_weapons(id)
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"))
	if (!pev_valid(ent)) return;
	
	dllfunc(DLLFunc_Spawn, ent)
	dllfunc(DLLFunc_Use, ent, id)
	engfunc(EngFunc_RemoveEntity, ent)
}

// Collect random spawn points
stock load_spawns()
{
	// Check for CSDM spawns of the current map
	new cfgdir[32], mapname[32], filepath[100], linedata[64]
	get_configsdir(cfgdir, charsmax(cfgdir))
	get_mapname(mapname, charsmax(mapname))
	formatex(filepath, charsmax(filepath), "%s/csdm/%s.spawns.cfg", cfgdir, mapname)
	
	// Load CSDM spawns if present
	if (file_exists(filepath))
	{
		new csdmdata[10][6], file = fopen(filepath,"rt")
		
		while (file && !feof(file))
		{
			fgets(file, linedata, charsmax(linedata))
			
			// invalid spawn
			if(!linedata[0] || str_count(linedata,' ') < 2) continue;
			
			// get spawn point data
			parse(linedata,csdmdata[0],5,csdmdata[1],5,csdmdata[2],5,csdmdata[3],5,csdmdata[4],5,csdmdata[5],5,csdmdata[6],5,csdmdata[7],5,csdmdata[8],5,csdmdata[9],5)
			
			// origin
			g_spawns[g_spawnCount][0] = floatstr(csdmdata[0])
			g_spawns[g_spawnCount][1] = floatstr(csdmdata[1])
			g_spawns[g_spawnCount][2] = floatstr(csdmdata[2])
			
			// increase spawn count
			g_spawnCount++
			if (g_spawnCount >= sizeof g_spawns) break;
		}
		if (file) fclose(file)
	}
	else
	{
		// Collect regular spawns
		collect_spawns_ent("info_player_start")
		collect_spawns_ent("info_player_deathmatch")
	}
	
	// Collect regular spawns for non-random spawning unstuck
	collect_spawns_ent2("info_player_start")
	collect_spawns_ent2("info_player_deathmatch")
}

// Collect spawn points from entity origins
stock collect_spawns_ent(const classname[])
{
	new ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		// get origin
		new Float:originF[3]
		pev(ent, pev_origin, originF)
		g_spawns[g_spawnCount][0] = originF[0]
		g_spawns[g_spawnCount][1] = originF[1]
		g_spawns[g_spawnCount][2] = originF[2]
		
		// increase spawn count
		g_spawnCount++
		if (g_spawnCount >= sizeof g_spawns) break;
	}
}

// Collect spawn points from entity origins
stock collect_spawns_ent2(const classname[])
{
	new ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		// get origin
		new Float:originF[3]
		pev(ent, pev_origin, originF)
		g_spawns2[g_spawnCount2][0] = originF[0]
		g_spawns2[g_spawnCount2][1] = originF[1]
		g_spawns2[g_spawnCount2][2] = originF[2]
		
		// increase spawn count
		g_spawnCount2++
		if (g_spawnCount2 >= sizeof g_spawns2) break;
	}
}

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			static wname[32], weapon_ent
			get_weaponname(weaponid, wname, charsmax(wname))
			weapon_ent = fm_find_ent_by_owner(-1, wname, id)
			
			// Hack: store weapon bpammo on PEV_ADDITIONAL_AMMO
			set_pev(weapon_ent, PEV_ADDITIONAL_AMMO, cs_get_user_bpammo(id, weaponid))
			
			// Player drops the weapon and looses his bpammo
			engclient_cmd(id, "drop", wname)
			cs_set_user_bpammo(id, weaponid, 0)
		}
	}
}

// Stock by (probably) Twilight Suzuka -counts number of chars in a string
stock str_count(const str[], searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if(str[i] == searchchar)
			count++
	}
	
	return count;
}

// Checks if a space is vacant (credits to VEN)
stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

// Check if a player is stuck (credits to VEN)
stock is_player_stuck(id)
{
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}


stock zp_user_spawn(id)
{
	if (get_pcvar_num(cvar_randspawn))
		do_random_spawn(id) // random spawn (including CSDM)
	else
		do_random_spawn(id, 1) // regular spawn
}

// Simplified get_weaponid (CS only)
stock cs_weapon_name_to_id(const weapon[])
{
	static i
	for (i = 0; i < sizeof WEAPONENTNAMES; i++)
	{
		if (equal(weapon, WEAPONENTNAMES[i]))
			return i;
	}
	
	return 0;
}

// Get User Current Weapon Entity
stock fm_cs_get_current_weapon_ent(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}

// Get Weapon Entity's Owner
stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

// Set User Deaths
stock fm_cs_set_user_deaths(id, value)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_CSDEATHS, value, OFFSET_LINUX)
}

// Get User Team
stock fm_cs_get_user_team(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return TEAM_UNASSIGNED;
	
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}

// Set a Player's Team
stock fm_cs_set_user_team(id, team)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_CSTEAMS, team, OFFSET_LINUX)
}


// Set User Flashlight Batteries
stock fm_cs_set_user_batteries(id, value)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_FLASHLIGHT_BATTERY, value, OFFSET_LINUX)
}

// Update Player's Team on all clients (adding needed delays)
/*stock fm_user_team_update(id)
{
	static Float:current_time
	current_time = get_gametime()
	
	if (current_time - g_teams_targettime >= 0.1)
	{
		set_task(0.1, "zp_set_user_team_msg", id+TASK_TEAM)
		g_teams_targettime = current_time + 0.1
	}
	else
	{
		set_task((g_teams_targettime + 0.1) - current_time, "zp_set_user_team_msg", id+TASK_TEAM)
		g_teams_targettime = g_teams_targettime + 0.1
	}
}

// Send User Team Message
public zp_set_user_team_msg(taskid)
{
	// Note to self: this next message can now be received by other plugins
	
	// Set the switching team flag
	g_switchingteam = true
	
	// Tell everyone my new team
	emessage_begin(MSG_ALL, g_msgTeamInfo)
	ewrite_byte(ID_TEAM) // player
	ewrite_string(CS_TEAM_NAMES[cell:zp_get_user_team(ID_TEAM)]) // team
	emessage_end()
	
	// Done switching team
	g_switchingteam = false
}*/

stock fm_cs_set_user_model_index(iPlayer, iValue)
{
	set_member(iPlayer, m_modelIndexPlayer, iValue);
	set_entvar(iPlayer, var_modelindex, iValue);
}

// Set Player Model on Entity
stock fm_set_playermodel_ent(id)
{
	// Make original player entity invisible without hiding shadows or firing effects
	fm_set_rendering(id, kRenderFxNone, 255, 255, 255, kRenderTransTexture, 1)
	
	// Format model string
	static model[100]
	formatex(model, charsmax(model), "models/player/%s/%s.mdl", g_playermodel[id], g_playermodel[id])
	
	// Set model on entity or make a new one if unexistant
	if (!pev_valid(g_ent_playermodel[id]))
	{
		g_ent_playermodel[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		if (!pev_valid(g_ent_playermodel[id])) return;
		
		set_pev(g_ent_playermodel[id], pev_classname, MODEL_ENT_CLASSNAME)
		set_pev(g_ent_playermodel[id], pev_movetype, MOVETYPE_FOLLOW)
		set_pev(g_ent_playermodel[id], pev_aiment, id)
		set_pev(g_ent_playermodel[id], pev_owner, id)
	}
	
	engfunc(EngFunc_SetModel, g_ent_playermodel[id], model)
}

// Set Weapon Model on Entity
stock fm_set_weaponmodel_ent(id)
{
	// Get player's p_ weapon model
	static model[100]
	pev(id, pev_weaponmodel2, model, charsmax(model))
	
	// Set model on entity or make a new one if unexistant
	if (!pev_valid(g_ent_weaponmodel[id]))
	{
		g_ent_weaponmodel[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		if (!pev_valid(g_ent_weaponmodel[id])) return;
		
		set_pev(g_ent_weaponmodel[id], pev_classname, WEAPON_ENT_CLASSNAME)
		set_pev(g_ent_weaponmodel[id], pev_movetype, MOVETYPE_FOLLOW)
		set_pev(g_ent_weaponmodel[id], pev_aiment, id)
		set_pev(g_ent_weaponmodel[id], pev_owner, id)
	}
	
	engfunc(EngFunc_SetModel, g_ent_weaponmodel[id], model)
}

// Remove Custom Model Entities
stock fm_remove_model_ents(id)
{
	// Remove "playermodel" ent if present
	if (pev_valid(g_ent_playermodel[id]))
	{
		engfunc(EngFunc_RemoveEntity, g_ent_playermodel[id])
		g_ent_playermodel[id] = 0
	}
	// Remove "weaponmodel" ent if present
	if (pev_valid(g_ent_weaponmodel[id]))
	{
		engfunc(EngFunc_RemoveEntity, g_ent_weaponmodel[id])
		g_ent_weaponmodel[id] = 0
	}
}

// Set User Model
public fm_cs_set_user_model(taskid)
{
	set_user_info(ID_MODEL, "model", g_playermodel[ID_MODEL])
}

// Get User Model -model passed byref-
stock fm_cs_get_user_model(player, model[], len)
{
	get_user_info(player, "model", model, len)
}

// Update Player's Model on all clients (adding needed delays)
public fm_user_model_update(taskid)
{
	static Float:current_time
	current_time = get_gametime()
	
	if (current_time - g_models_targettime >= g_modelchange_delay)
	{
		fm_cs_set_user_model(taskid)
		g_models_targettime = current_time
	}
	else
	{
		set_task((g_models_targettime + g_modelchange_delay) - current_time, "fm_cs_set_user_model", taskid)
		g_models_targettime = g_models_targettime + g_modelchange_delay
	}
}

// WeaponList
stock UTIL_SetWeaponList( iPlayer, const szWeaponName[], int, int2, int3, int4, int5, int6, int7, int8 )
{
	message_begin( MSG_ONE, 78, _, iPlayer );
	write_string( szWeaponName );
	write_byte( int );
	write_byte( int2 );
	write_byte( int3 );
	write_byte( int4 );
	write_byte( int5 );
	write_byte( int6 );
	write_byte( int7 );
	write_byte( int8 );
	message_end( );
	
	if ( pev_valid( iPlayer ) != 2 )
		return;
	
	new iEntity = get_pdata_cbase( iPlayer, 373, 5 );
	
	if ( !pev_valid( iEntity ) )
		return;
	
	new iWeapon = get_pdata_int( iEntity, 43, 4 );
	new iClip = get_pdata_int( iEntity, 51, 4 );
	
	UTIL_CurWeapon( iPlayer, 2, iWeapon, iClip );
}

// Current Weapon
stock UTIL_CurWeapon( iPlayer, IsActive, iWeaponId, iClipAmmo )
{
	message_begin( MSG_ONE, 66, _, iPlayer );
	write_byte( IsActive );
	write_byte( iWeaponId );
	write_byte( iClipAmmo );
	message_end( );
}

stock UTIL_StripWeapon(iPlayer, iSlot) 
{
	if(pev_valid(iPlayer) != 2) return;
	
	static iEntity; iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, 5);
	if(iEntity > 0 && pev_valid(iEntity) == 2) {
		static iNext, iId;
		do{
			iNext = get_pdata_cbase(iEntity, m_pNext, 4);
			iId = get_pdata_int(iEntity, m_iId, 4);
			if(get_user_weapon(iPlayer) == iId)	ExecuteHamB(Ham_Weapon_RetireWeapon, iEntity);
			ExecuteHamB(Ham_RemovePlayerItem, iPlayer, iEntity);
			ExecuteHamB(Ham_Item_Kill, iEntity);
			set_pev(iPlayer, pev_weapons, pev(iPlayer, pev_weapons) & ~(1<<iId));
		} while(( iEntity = iNext) > 0);
	}
}

stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	switch(pPlayer)
	{
		case 0:
		{
			for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++)
			{
				if(!is_user_connected(iPlayer)) continue;
				engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, iPlayer);
				write_byte(iPlayer);
				write_string(szBuffer);
				message_end();
			}
		}
		default:
		{
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, pPlayer);
			write_byte(pPlayer);
			write_string(szBuffer);
			message_end();
		}
	}
}

stock zp_set_user_model(const id, const szModel[], iModelIndex = -1, iBody = -1)
{
	if(is_nullent(id)) return false;


	if(iBody >= 0)
		set_entvar(id, var_body, iBody);

	new szCurrentModel[32]; get_member(id, m_szModel, szCurrentModel, charsmax(szCurrentModel));
	
	if(!equal(szModel, szCurrentModel))
	{
		if(iModelIndex == -1) 
			iModelIndex = g_set_modelindex_offset

		copy(g_playermodel[id], charsmax(g_playermodel[]), szModel);
		//client_print(0, print_chat, "szModel: %s | szCurrentModel: %s | iModelIndex: %d", szModel, szCurrentModel, iModelIndex);
		return rg_set_user_model(id, szModel, bool:iModelIndex);
	}

	return true;
}

stock zp_set_user_zombie_model(id)
{
	new iRand, szModel[32];

	if(g_nemesis[id])
	{
		iRand = random(ArraySize(model_nemesis))
		ArrayGetString(model_nemesis, iRand, szModel, charsmax(szModel))
	}
	else
	{
		iRand = random_num(ArrayGetCell(g_zclass_modelsstart, g_zombieclass[id]), ArrayGetCell(g_zclass_modelsend, g_zombieclass[id]) - 1)
		ArrayGetString(g_zclass_playermodel, iRand, szModel, charsmax(szModel))
	}

	return zp_set_user_model(id, szModel);
}

stock zp_set_user_human_model(id)
{
	return zp_update_user_human_model(id);
}

stock zp_set_user_team(id, TeamName:iTeam)
{
	if(is_nullent(id) || zp_get_user_team(id) == TeamName:iTeam)
		return 0;

	return rg_set_user_team(id, iTeam, MODEL_UNASSIGNED);
}

stock TeamName:zp_get_user_team(id)
{
	if(is_nullent(id))
		return TeamName:0;

	return get_member(id, m_iTeam);
}

stock set_all_team_ct()
{
	for(new iPlayer = 1; iPlayer <= g_maxplayers; iPlayer++)
	{
		if(zp_get_user_team(iPlayer) == TEAM_TERRORIST)
			zp_set_user_team(iPlayer, TEAM_CT);
	}
}


/**
 * Получает массив случайных живых клиентов в 
 * определённой команде по количеству iNum
 * 
 * @param TeamName:iFromTeam - тип команды, из которой нужно получить случайные id клиентов
 * @param iNum - количество случайных клиентов
 * @param iOut - выходной массив с случайными клиентами
 * @param iRand - Тип рандома (TypeRandom)
 * 
 * @return - количество случайных клиентов
 */
stock get_random_alive_players_by_num(TeamName:iFromTeam, iNum, iOut[], TypeRandom:iRand = TypeRandom:e_RandomDef)
{
	new iCount, iPlayers[32];

	if(!(iCount = get_alive_players_by_team(iFromTeam, iPlayers, sizeof iPlayers)))
		return 0;

	//Проверка на выход за пределы и исключительные ситуации, количество рандомных выбраных игроков
	new iMaxRandom = min(iCount, iNum), iCountRand;

	switch(iRand)
	{
		case e_RandomDef: iCountRand = get_random_from_array(iPlayers, iCount, iMaxRandom, iOut);
		case e_RandomPriority: iCountRand = get_random_priority_from_array(iPlayers, iCount, iMaxRandom, iOut);
	}

	return iCountRand;
}

/**
 * Получает массив случайных живых клиентов в 
 * определённой команде по проценту flRatio
 * 
 * @param TeamName:iFromTeam - тип команды, из которой нужно получить случайные id клиентов
 * @param Float:flRatio - процент случайных клиентов
 * @param iOut - выходной массив с случайными клиентами
 * @param iRand - Тип рандома (TypeRandom)
 * 
 * @return - количество случайных клиентов
 */
stock get_random_alive_players_by_ratio(TeamName:iFromTeam, Float:flRatio, iOut[], TypeRandom:iRand = TypeRandom:e_RandomDef)
{
	new iCount, iPlayers[32];

	if(!(iCount = get_alive_players_by_team(iFromTeam, iPlayers, sizeof iPlayers)))
		return 0;

	//Проверка на выход за пределы и исключительные ситуации, количество рандомных выбраных игроков.
	new iMaxRandom = floatround(iCount * flRatio, floatround_ceil), iCountRand;

	switch(iRand)
	{
		case e_RandomDef: iCountRand = get_random_from_array(iPlayers, iCount, iMaxRandom, iOut);
		case e_RandomPriority: iCountRand = get_random_priority_from_array(iPlayers, iCount, iMaxRandom, iOut);
	}

	return iCountRand;
}

stock get_alive_players_by_team(TeamName:iFromTeam, iPlayers[], iLen)
{
	new iCount, iMin = min(g_maxplayers, iLen);

	for(new iPlayer = 1; iPlayer <= iMin; iPlayer++)
	{
		if(!is_user_alive(iPlayer) || zp_get_user_team(iPlayer) != iFromTeam)
			continue;

		iPlayers[iCount++] = iPlayer;
	}

	return iCount;
}

stock get_random_from_array(iInput[], &iCount, iNum, iOut[])
{
	new iOutNums;

	iNum = min(iCount, iNum);

	for(new iCountRandom, iRandomPlayer, iRandom; iCountRandom < iNum; iCountRandom++)
	{
		//Получение случайного id клиента из массива
		iRandom = random(iCount);
		iRandomPlayer = iInput[iRandom];

		//Перемещение последнего элемента на место случайного
		iInput[iRandom] = iInput[iCount-- - 1];

		//Занесение в выходной массив
		iOut[iOutNums++] = iRandomPlayer;
	}

	return iOutNums;
}

//Максимальное число приоритетов
#define PriorytyRounds 16

//Поле, куда записывается приоритет игроков
new const g_szFieldPrior[] = "zpe_main_human_priority";

//Индекс в котором хранится размер массива приоритета
#define PlayerSize 0

//Рандом с приоритетом
stock get_random_priority_from_array(iInput[], &iCount, iNum, iOut[])
{
	new iPriorityUsers[PriorytyRounds][33],
		//Максимальный уровень приоритета
		iMaxPriority;

	//Заполняем массив приоритетов
	for(new i, iUserPriority, iSize; i < iCount; i++)
	{
		iUserPriority = get_user_property(iInput[i], g_szFieldPrior);
		//console_print(0, "iUserPriority: %d", iUserPriority);

		if(iUserPriority > iMaxPriority) iMaxPriority = iUserPriority;

		//Получаем размер нужного нам приоритета и увеличиваем его на 1
		iSize = iPriorityUsers[iUserPriority][PlayerSize] + 1;

		iPriorityUsers[iUserPriority][PlayerSize] = iSize;
		iPriorityUsers[iUserPriority][iSize] = iInput[i];
	}

	//Количество которое войдет в итоговый массив, количество которое осталось набрать, номер приоритета
	new iOutNums, iLeft = min(iCount, iNum), iPriority = iMaxPriority

	//Выбираем рандомно с приоритетом
	for(new iSize, iAdded, i; iPriority >= 0 && iLeft > 0; iPriority--)
	{
		iSize = iPriorityUsers[iPriority][PlayerSize];
		//console_print(0, "iSize: %d", iSize);

		if(iLeft >= iSize)
		{
			//Если в текущем уровне приоритета меньше или равно требующихся игроков
			//Переписываем всех игроков
			for(i = iSize; i > PlayerSize; i--)
				iOut[iOutNums++] = iPriorityUsers[iPriority][i];

			iLeft -= iSize;
			iPriorityUsers[iPriority][PlayerSize] = 0;
		}
		else if(0 < iLeft < iSize)
		{
			//Если в текущем уровне приоритета меньше требующихся игроков
			//Выбираем рандомно
			iAdded = get_random_from_array(iPriorityUsers[iPriority][PlayerSize + 1], iSize, iLeft, iOut[iOutNums])

			//console_print(0, "iAdded: %d | iPriority: %d | iSize: %d | iLeft: %d | iOutNums: %d", iAdded, iPriority, iSize, iLeft, iOutNums);
			//console_print(0, "iPriorityUsers[iPriority][0-3]: %d %d %d %d", iPriorityUsers[iPriority][0], iPriorityUsers[iPriority][1], iPriorityUsers[iPriority][2], iPriorityUsers[iPriority][3]);
			//console_print(0, "iOut[0-3]: %d %d %d %d", iOut[0], iOut[1], iOut[2], iOut[3]);

			iLeft -= iAdded;
			iOutNums += iAdded;
			iPriorityUsers[iPriority][PlayerSize] = iSize;
		}
	}

	//Сбрасываем приоритет у выбраных игроков
	for(new i; i < iOutNums; i++)
		set_user_property(iOut[i], g_szFieldPrior, 0);

	//Прибавляем остальным приоритет на 1
	//Переписываем входной массив
	iCount = 0;

	for(new iPriorityNew = min(iPriority + 1, PriorytyRounds - 1), iSize, i, iPlayer; iPriorityNew >= 0; iPriorityNew--)
	{
		if( (iSize = iPriorityUsers[iPriorityNew][PlayerSize]) <= 0 ) continue;

		for(i = 0; i < iSize; i++)
		{
			iPlayer = iPriorityUsers[iPriorityNew][i + 1];
			set_user_property(iPlayer, g_szFieldPrior, min(iPriorityNew + 1, PriorytyRounds - 1));
			
			//console_print(0, "SETPROPERTY+ iPlayer: %d | iPriority: %d", iPlayer, get_user_property(iPlayer, g_szFieldPrior));
			
			iInput[iCount++] = iPlayer;
		}
	}


	/*for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(!is_user_connected(iPlayer)) continue;
		console_print(0, "iPlayer: %d | iPriority: %d", iPlayer, get_user_property(iPlayer, g_szFieldPrior));
	}*/

	return iOutNums;
}

/*
//Находим значения в массиве
// -1 - значение не найдено
stock find_index_in_array(const any:Array[], const iLen, const any:Value)
{
	for(new iIndex; iIndex < iLen, iIndex++)
		if(Array[iIndex] == Value) return iIndex;

	return -1;
}*/