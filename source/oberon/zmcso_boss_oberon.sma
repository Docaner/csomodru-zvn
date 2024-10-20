#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <smart_messages>
#include <smart_effects>
#include <xs>
#include <gamecms5>
#include <zp_system>
#include <zpe_lvl>

// new const MAPCHANGE[] = "zm_dust_world"
// new const Float:TIME_CHANGEAFTERDEATH = 20.0;
// new const Float:TIME_CHANGEAFTERKILLSUSERS = 5.0;

new const BOSS_MAP[] = "zl_boss_oberon";

new PRIZE_AUTH[] = "ce"; // Флаги авторизации
new PRIZE_TIME = 1440; // Время в минутах
new PRIZE_FLAGS[] = "pt"; // Флаги админ
new PRIZE_SERVICEID = 2; // ID услуги
new const PRIZE_EXP = 1000; // EXP за убийство

#define RESPAWN_TIME 60.0 // время в течение которого можно возродиться игроку
new Float:g_flTimeSpawn = 0.0;

// BOSS ENTITY

new const BOSS_REFERENCE[] = "info_target"
new const BOSS_MODEL[] = "models/npc_hardcs/npc_oberon_attach.mdl";
new const BOSS_CLASSNAME[] = "boss_oberon" 
new const Float:BOSS_MINSIZE[] = {-40.0, -40.0, -40.0};
new const Float:BOSS_MAXSIZE[] = {40.0, 40.0, 96.0};
new const Float:BOSS_HEALTHPERHUMAN = 40_000.0

#define BOSS_ROTATE_COEF_DEF 0.1
#define BOSS_ROTATE_COEF_SMOOTH 0.01

#define BOSS_WALKSPEED 238.0
#define BOSS_WALKSPEED_CLAWS 248.0

new const BOSS_SOUND_RHAND[] = "npc/oberon/attack1.wav";
#define BOSS_RADIUS_RHAND 165.0
#define BOSS_DAMAGE_RHAND 50.0

new const BOSS_SOUND_RHAND_CLAWS[] = "npc/oberon/attack1_knife.wav";
#define BOSS_RADIUS_RHAND_CLAWS 190.0
#define BOSS_DAMAGE_RHAND_CLAWS 60.0

new const BOSS_SOUND_LHAND[] = "npc/oberon/attack2.wav";
#define BOSS_RADIUS_LHAND 165.0
#define BOSS_DAMAGE_LHAND 50.0

new const BOSS_SOUND_LHAND_CLAWS[] = "npc/oberon/attack2_knife.wav";
#define BOSS_RADIUS_LHAND_CLAWS 190.0
#define BOSS_DAMAGE_LHAND_CLAWS 60.0

new const BOSS_SOUND_JUMP[] = "npc/oberon/jump.wav";

new const BOSS_SOUND_FALL[] = "npc/oberon/attack3.wav";
#define BOSS_RADIUS_FALL 165.0
#define BOSS_DAMAGE_FALL 30.0

#define BOSS_RADIUS_FALL_CLAWS 190.0
#define BOSS_DAMAGE_FALL_CLAWS 40.0

new const BOSS_SOUND_HOLE[] = "npc/oberon/hole.wav";
#define BOSS_RADIUS_HOLE 250.0
#define BOSS_DAMAGE_HOLE 15.0

#define BOSS_RADIUS_HOLE_CLAWS 280.0
#define BOSS_DAMAGE_HOLE_CLAWS 30.0

new const BOSS_SOUND_START_BOMBS[] = "npc/oberon/voice3.wav";
new const BOSS_SOUND_DROP_BOMBS[] = "npc/oberon/bomb.wav";

new const BOSS_SOUND_SECOND_PHASE[] = "npc/oberon/knife.wav";
new const BOSS_SOUND_KILLED[] = "npc/oberon/death.wav";
new const SOUND_VICTORY[] = "sound/npc/oberon/aftermatch.mp3";

native zp_start_mapchoosing();

#define BOSS_THINKDELAY 0.01
#define BOSS_ENEMYDELAY 10.0

#define var_boss_hpbar var_iuser1
#define var_boss_state var_iuser2
#define var_boss_attackzone var_iuser3
#define var_boss_droptimes var_iuser4
#define var_boss_prizebits var_iStepLeft

#define var_boss_animdelay var_fuser1
#define var_boss_enemydelay var_fuser2
#define var_boss_nextstate var_fuser3
#define var_boss_rotatecoef var_fuser4
#define var_boss_nextshake var_ltime

#define var_boss_endattack var_vuser1

enum
{
	IDLE = 0,
	WALK, // 1
	ATTACK_RHAND, // 2
	ATTACK_LHAND, // 3
	ATTACK_JUMP, // 4
	ATTACK_BOMB, // 5
	ATTACK_HOLE, // 6
	IDLE_CLAWS, // 7
	WALK_CLAWS, // 8
	ATTACK_RHAND_CLAWS, // 9
	ATTACK_LHAND_CLAWS, // 10
	ATTACK_JUMP_CLAWS, // 11
	ATTACK_BOMB_CLAWS, // 12
	ATTACK_HOLE_CLAWS, // 13
	SCENE_APPEAR, // 14
	SCENE_CLAWS, // 15
	SCENE_DEATH, // 16
}

#define TIME_IDLE 5.30

#define TIME_WALK 4.04
#define TIME_WALK_FIRST_SHAKE (5.0 / 25.0)
#define TIME_WALK_OTHER_SHAKE (25.0 / 25.0)

// #define TIME_ATTACK_RHAND 2.70
#define TIME_ATTACK_RHAND_HIT (28.0 / 30.0)
#define TIME_ATTACK_RHAND_END (53.0 / 30.0)

// #define TIME_ATTACK_LHAND 2.03
#define TIME_ATTACK_LHAND_HIT (7.0 / 30.0)
#define TIME_ATTACK_LHAND_END (54.0 / 30.0)

#define TIME_ATTACK_JUMP 4.03
#define TIME_ATTACK_JUMP_PREPARE (15.0 / 30.0)
#define TIME_ATTACK_JUMP_FLY (45.0 / 30.0)
#define TIME_ATTACK_JUMP_ONGROUND (2.0 / 30.0)
#define TIME_ATTACK_JUMP_ATTACK (59.0 / 30.0)

#define TIME_ATTACK_BOMB 11.20
#define TIME_ATTACK_BOMB_PREPARE (45.0 / 15.0)
new const Float:TIME_ATTACK_BOMBS[] = { 2.93, 3.0, 2.26 };


#define TIME_ATTACK_HOLE 6.03
#define TIME_ATTACK_HOLE_PREPARE (147.0 / 30.0)
#define TIME_ATTACK_HOLE_ATTACK (34.0 / 30.0)

#define TIME_IDLE_CLAWS 2.65

#define TIME_WALK_CLAWS 3.37
#define TIME_WALK_CLAWS_FIRST_SHAKE (5.0 / 30.0)
#define TIME_WALK_CLAWS_OTHER_SHAKE (25.0 / 30.0)

// #define TIME_ATTACK_RHAND_CLAWS 1.87
#define TIME_ATTACK_RHAND_CLAWS_HIT (21.0 / 30.0)
#define TIME_ATTACK_RHAND_CLAWS_END (35.0 / 30.0)

// #define TIME_ATTACK_LHAND_CLAWS 1.53
#define TIME_ATTACK_LHAND_CLAWS_HIT (7.0 / 30.0)
#define TIME_ATTACK_LHAND_CLAWS_END (39.0 / 30.0)

// #define TIME_ATTACK_JUMP_CLAWS 4.03
// #define TIME_ATTACK_BOMB_CLAWS 11.20
// #define TIME_ATTACK_HOLE_CLAWS 6.03

#define TIME_SCENE_APPEAR 6.20
#define TIME_SCENE_CLAWS 8.70
#define TIME_SCENE_DEATH 10.03

enum (<<= 1)
{
	BOSS_IDLE = 1, // Бездействие
	BOSS_RUN, // Бег
	BOSS_ATTACK, // Атака
	BOSS_JUMP, // Прыжок
	BOSS_FLY, // Полёт
	BOSS_FALL_ATTACK, // Атака при приземлении
	BOSS_HOLE, // Чёрная дырочка
	BOSS_BOMB, // Черкаши
	BOSS_ROTATE, // Поворот (Интерполяция)
	BOSS_SECONDPHASE, // Вторая фаза
	BOSS_KILLED, // Умер
}

new g_iModelIndex_Boss;

// BOX ENTITY

new const BOX_REFERENCE[] = "info_target";
new const BOX_MODEL[] = "models/npc_hardcs/box.mdl";
//-346 x, -154 y, 629 z
#define BOX_ORIGIN Float:{-346.0, -154.0, 962.0}
#define BOX_MINSIZE Float:{-150.0, -150.0, -5.0}
#define BOX_MAXSIZE Float:{150.0, 150.0, 150.0}
new const BOX_CLASSNAME[] = "boss_box";
#define BOX_TIMEPREPARE 30.0 // 30.0
#define BOX_TIMESHAKE 5.0 // 5.0
#define BOX_TIMEDOWN 3.0 // 3.0

new const GIBS_MODEL[] = "models/npc_hardcs/box_gibs.mdl";
new g_iModelIndex_Gibs;

new const EXPLOSION_MODEL[] = "sprites/eexplo.spr";
new g_iModelIndex_Explosion;

enum
{
	BOX_SHAKE1 = 0,
	BOX_SHAKE2,
	BOX_SHAKE3,
	BOX_DOWN,
	BOX_DESTROY,
}

new const SOUND_SCINARIO[] = "sound/zp_br_cso/bosses/oberon/roundSeoJeongMin.mp3";

// HPBAR ENTITY

new const HPBAR_REFERENCE[] = "env_sprite";
new const HPBAR_CLASSNAME[] = "boss_hpbar";
new const HPBAR_MODEL[] = "sprites/npc_hp_grade2.spr";
#define HPBAR_SCALE 0.67
#define HPBAR_FRAMEMAX 100.0

// ATTACK ZONE ENTITY

new const ATTACKZONE_REFERENCE[] = "info_target";
new const ATTACKZONE_CLASSNAME[] = "boss_attackzone";
#define ATTACKZONE_MINSIZE Float:{-88.0, -108.0, -108.0}
#define ATTACKZONE_MAXSIZE Float:{108.0, 108.0, 108.0}

// HOLE

new const HOLE_REFERENCE[] = "info_target";
new const HOLE_CLASSNAME[] = "boss_hole";
new const HOLE_MODEL[] = "models/npc_hardcs/hole.mdl";
#define HOLE_THINK 0.01

#define HOLE_IDLE1 0

#define TIME_HOLE_IDLE1 (161.0 / 30.0)
#define TIME_HOLE_IDLE1_INCREASE (35.0 / 30.0)
#define TIME_HOLE_IDLE1_DECREASE (124.0 / 30.0)

#define var_hole_state var_iuser1
#define var_hole_nextstate var_fuser1

enum
{
	HOLE_INCREASE = 0,
	HOLE_DECREASE,
	HOLE_KILL,
}

#define HOLE_RADIUS 900.0

// BOMB

new const BOMB_REFERENCE[] = "info_target";
new const BOMB_CLASSNAME[] = "boss_bomb";
new const BOMB_MODEL[] = "models/npc_hardcs/bomb.mdl";
new const Float:BOMB_MINSIZE[] = {-21.15, -23.24, -21.37};
new const Float:BOMB_MAXSIZE[] = {25.24, 20.78, 21.37};

#define BOMB_RADIUS 130.0
#define BOMB_DAMAGE 15.0

#define BOMB_RADIUS_CLAWS 160.0
#define BOMB_DAMAGE_CLAWS 30.0

enum
{
	BOMB_IDLE = 0
}

#define BOMB_FLYTIME 1.5

// PRIZE

new const PRIZE_REFERENCE[] = "info_target";
new const PRIZE_CLASSNAME[] = "boss_prize";
new const PRIZE_MODEL[] = "models/zp_br_cso/supply_v10.mdl";
new const PRIZE_SOUND[] = "zp_br_cso/zpsb_get.wav";
new const PRIZE_BODY = 6;
new const Float:PRIZE_MINSIZE[] = {-21.0, -21.0, 0.0};
new const Float:PRIZE_MAXSIZE[] = {21.0, 21.0, 21.0};


public plugin_precache() {
	if(!isBossMap()) return;

	precache_model(BOX_MODEL);

	g_iModelIndex_Boss = precache_model(BOSS_MODEL);
	g_iModelIndex_Gibs = precache_model(GIBS_MODEL);
	g_iModelIndex_Explosion = precache_model(EXPLOSION_MODEL);

	precache_model(HPBAR_MODEL);
	precache_model(HOLE_MODEL);
	precache_model(BOMB_MODEL);

	precache_sound(BOSS_SOUND_RHAND);
	precache_sound(BOSS_SOUND_RHAND_CLAWS);
	precache_sound(BOSS_SOUND_LHAND);
	precache_sound(BOSS_SOUND_LHAND_CLAWS);

	precache_sound(BOSS_SOUND_START_BOMBS);
	precache_sound(BOSS_SOUND_DROP_BOMBS);

	precache_sound(BOSS_SOUND_HOLE);

	precache_sound(BOSS_SOUND_JUMP);
	precache_sound(BOSS_SOUND_FALL);

	precache_sound(BOSS_SOUND_SECOND_PHASE);

	precache_sound(BOSS_SOUND_KILLED);

	precache_generic(SOUND_SCINARIO);
	precache_generic(SOUND_VICTORY);

	precache_model(PRIZE_MODEL);
	precache_sound(PRIZE_SOUND);
}

public plugin_init() {
	register_plugin("[ZMCSO] Boss Oberon", "1.0", "Docaner / HACTEHbKA322");

	if(!isBossMap()) return;

	RegisterHookChain(RG_CBasePlayer_RoundRespawn, "@PlayerSpawnPre", false);

	RegisterHam(Ham_TraceAttack, BOSS_REFERENCE, "@BossTraceAttackPre", false);
	RegisterHam(Ham_TakeDamage, BOSS_REFERENCE, "@BossTakeDamagePost", true);    
	RegisterHam(Ham_BloodColor, BOSS_REFERENCE, "@BossBloodColorPre", false);
	RegisterHam(Ham_Killed, BOSS_REFERENCE, "@BossKilledPre", false);
	RegisterHam(Ham_Killed, "player", "@PlayerKilledPost", true);

	spawnBox();
}

@PlayerSpawnPre(iPlayer)
{
	// if(g_flTimeSpawn != 0.0 && g_flTimeSpawn < get_gametime())
	return HC_SUPERCEDE;
}

@PlayerKilledPost() if(!countAliveUsers()) zp_start_mapchoosing();

stock countAliveUsers()
{
	new iAlives;
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		if(is_user_alive(iPlayer)) iAlives++;
	return iAlives;
}

@BossTraceAttackPre(iVictim, iAttacker, Float:flDamage, Float:vecDir[3], pTrace, iBitDamage) {
	if(!FClassnameIs(iVictim, BOSS_CLASSNAME))
		return;

	switch(get_tr2(pTrace, TR_iHitgroup))
	{
		case HIT_HEAD: flDamage *= 4.0;
		case HIT_STOMACH: flDamage *= 1.25;
		case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 0.75;
	}

	SetHamParamFloat(3, flDamage);
}

@BossTakeDamagePost(iVictim, iInflictor, iAttacker, Float:flDamage, iBitDamage) {
	if(!FClassnameIs(iVictim, BOSS_CLASSNAME))
		return;

	bossUpdateHPBar(iVictim);
}

@BossBloodColorPre(iEnt) {
	if(!FClassnameIs(iEnt, BOSS_CLASSNAME))
		return HAM_IGNORED;

	SetHamReturnInteger(BLOOD_COLOR_YELLOW);
	return HAM_SUPERCEDE;
}

@BossKilledPre(iVictim, iKiller)
{
	if(!FClassnameIs(iVictim, BOSS_CLASSNAME))
		return HAM_IGNORED;

	if(get_entvar(iVictim, var_deadflag) == DEAD_DYING)
		return HAM_SUPERCEDE;	

	set_entvar(iVictim, var_deadflag, DEAD_DYING);
	set_entvar(iVictim, var_velocity, Float:{0.0, 0.0, -0.1})

	bossDeleteEntByVar(iVictim, var_boss_hpbar);
	bossDeleteEntByVar(iVictim, var_boss_attackzone);

	UTIL_SetEntityAnim(iVictim, SCENE_DEATH);

	emit_sound(iVictim, CHAN_AUTO, BOSS_SOUND_KILLED, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	if(IsPlayer(iKiller))
	{
		set_entvar(iVictim, var_boss_prizebits, (1<<iKiller));

		client_cmd(0, "mp3 play ^"%s^"", SOUND_VICTORY);
		
		new szName[32]; get_user_name(iKiller, szName, charsmax(szName));

		set_dhudmessage(255, 255, 255, -1.0, 0.25)
		show_dhudmessage(0, fmt("%s убил Оберона и получил PREMIUM на 1 день + %d exp!", szName, PRIZE_EXP));

		cmsapi_add_account(iKiller, PRIZE_AUTH,  PRIZE_TIME,  _, PRIZE_FLAGS, PRIZE_SERVICEID);
		zpe_set_user_exp(iKiller, zpe_get_user_exp(iKiller) + PRIZE_EXP);
	}

	for(new i; i < 5; i++) spawnPrize(iVictim);


	set_entvar(iVictim, var_solid, SOLID_NOT);
	SetThink(iVictim, "");

	zp_start_mapchoosing();

	return HAM_SUPERCEDE;
}

// @ChangeMap() server_cmd("changelevel %s", MAPCHANGE)

stock bossDeleteEntByVar(iEnt, EntVars:entVar)
{
	new iChildEnt = get_entvar(iEnt, entVar);
	if(!is_nullent(iChildEnt)) rg_remove_entity(iChildEnt);
	set_entvar(iEnt, entVar, 0);
}

stock bossUpdateHPBar(iEnt) {
	new Float:flHealth = Float:get_entvar(iEnt, var_health);
	new Float:flMaxHealth = Float:get_entvar(iEnt, var_max_health);
	new iHPBar = get_entvar(iEnt, var_boss_hpbar);
	if(is_nullent(iHPBar)) return;
	set_entvar(iHPBar, var_frame, flHealth / flMaxHealth * HPBAR_FRAMEMAX);
}

stock bool:isBossMap() {
	new szMapName[32]; get_mapname(szMapName, charsmax(szMapName));
	return strcmp(szMapName, BOSS_MAP) == 0;
}

stock spawnBox() {
	new iEnt = rg_create_entity(BOX_REFERENCE);

	if(is_nullent(iEnt)) return NULLENT;

	set_entvar(iEnt, var_classname, BOX_CLASSNAME);
	set_entvar(iEnt, var_solid, SOLID_SLIDEBOX);
	set_entvar(iEnt, var_movetype, MOVETYPE_NONE);
	set_entvar(iEnt, var_iuser1, BOX_SHAKE1)
	set_entvar(iEnt, var_nextthink, get_gametime() + BOX_TIMEPREPARE)
	set_entvar(iEnt, var_iuser1, 0);

	engfunc(EngFunc_SetModel, iEnt, BOX_MODEL);
	engfunc(EngFunc_SetOrigin, iEnt, BOX_ORIGIN);
	engfunc(EngFunc_SetSize, iEnt, BOX_MINSIZE, BOX_MAXSIZE);

	SetThink(iEnt, "@ThinkBox");

	return iEnt;
}

@ThinkBox(iEnt) {
	new iState = get_entvar(iEnt, var_iuser1);
	if(iState == BOX_SHAKE1) client_cmd(0, "mp3 play ^"%s^"", SOUND_SCINARIO);
	switch(iState)
	{
		case BOX_SHAKE1, BOX_SHAKE2, BOX_SHAKE3: {
			new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin);
			MSG_ScreenShake(0, 3.0, 3.0, 3.0);
			MSG_BreakModel(vecOrigin, Float:{1.0, 1.0, 1.0}, Float:{25.0, 25.0, 25.0}, 10, g_iModelIndex_Gibs, 20, 5.0, (BREAK_GLASS|BREAK_METAL|BREAK_FLESH));
			
			set_entvar(iEnt, var_iuser1, iState + 1);
			set_entvar(iEnt, var_nextthink, get_gametime() + BOX_TIMESHAKE);
			return;
		}
		case BOX_DOWN: {
			new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin);
			MSG_Explosion(vecOrigin, g_iModelIndex_Explosion, 5.0, 2.0, 0);
		
			set_entvar(iEnt, var_iuser1, iState + 1);
			set_entvar(iEnt, var_movetype, MOVETYPE_TOSS);
			set_entvar(iEnt, var_velocity, Float:{0.0, 0.0, -800.0});
			set_entvar(iEnt, var_nextthink, get_gametime() + BOX_TIMEDOWN);

			SetTouch(iEnt, "@TouchBoxKill");
			return;
		}
		case BOX_DESTROY: {
			new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin);
			// vecOrigin[2] += 30.0
			vecOrigin[2] += 35.0
			MSG_Explosion(vecOrigin, g_iModelIndex_Explosion, 5.0, 2.0, 0);
			MSG_BreakModel(vecOrigin, BOX_MINSIZE, Float:{0.0, 0.0, 500.0}, 10, g_iModelIndex_Gibs, 20, 5.0, (BREAK_GLASS|BREAK_METAL|BREAK_FLESH));
			
			
			spawnBoss(vecOrigin);
			rg_remove_entity(iEnt);
		}
	}
}

@TouchBoxKill(iEnt, iToucher)
{
	if(iToucher == 0)
	{
		SetTouch(iEnt, "");
		return;
	}

	if(!IsPlayer(iToucher)) return;
		
	set_entvar(iEnt, var_velocity, Float:{0.0, 0.0, -800.0});
	ExecuteHamB(Ham_Killed, iToucher, iEnt, 1);
}

stock spawnBoss(Float:vecOrigin[3]) {
	new iEnt = rg_create_entity(BOSS_REFERENCE);

	if(is_nullent(iEnt)) return NULLENT;

	g_flTimeSpawn = get_gametime() + RESPAWN_TIME;

	new Float:flMaxHealth = BOSS_HEALTHPERHUMAN * float(max(1, getOnlineCounts()));

	set_entvar(iEnt, var_classname, BOSS_CLASSNAME);
	set_entvar(iEnt, var_solid, SOLID_BBOX);
	set_entvar(iEnt, var_movetype, MOVETYPE_PUSHSTEP);
	// set_entvar(iEnt, var_movetype, MOVETYPE_TOSS);
	set_entvar(iEnt, var_takedamage, DAMAGE_YES);
	set_entvar(iEnt, var_gamestate, 1);
	set_entvar(iEnt, var_health,  flMaxHealth);
	set_entvar(iEnt, var_max_health, flMaxHealth);
	set_entvar(iEnt, var_modelindex, g_iModelIndex_Boss);
	set_entvar(iEnt, var_flags, FL_MONSTER);
	set_entvar(iEnt, var_deadflag, DEAD_NO)
	// #define m_modelIndexPlayer 491
	// set_pdata_int(iEnt, m_modelIndexPlayer, g_iModelIndex_Boss)
	// set_member(iEnt, m_modelIndexPlayer, g_iModelIndex_Boss);
	// set_entvar(iEnt, var_modelindex, g_iModelIndex_Boss);
	set_entvar(iEnt, var_boss_hpbar, spawnHPBar(iEnt));
	set_entvar(iEnt, var_boss_attackzone, spawnAttackZone(iEnt));
	set_entvar(iEnt, var_boss_state, BOSS_IDLE);
	set_entvar(iEnt, var_boss_rotatecoef, BOSS_ROTATE_COEF_DEF);

	engfunc(EngFunc_SetSize, iEnt, BOSS_MINSIZE, BOSS_MAXSIZE);
	engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);

	UTIL_SetEntityAnim(iEnt, SCENE_APPEAR);
	set_entvar(iEnt, var_nextthink, get_gametime() + TIME_SCENE_APPEAR);

	SetThink(iEnt, "@ThinkBoss");

	return iEnt;
}

stock getOnlineCounts()
{
	new iOnline = 0;
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		if(is_user_connected(iPlayer)) ++iOnline;
	return iOnline;
}

@ThinkBoss(iEnt) 
{
	new Float:flGameTime = get_gametime();
	new iStateBits = get_entvar(iEnt, var_boss_state);

	if(iStateBits & BOSS_IDLE) idle(iEnt, flGameTime, iStateBits);
	else if(iStateBits & BOSS_RUN) run(iEnt, flGameTime, iStateBits);
	else if(iStateBits & BOSS_ATTACK) attack(iEnt, flGameTime, iStateBits);
	else if(iStateBits & BOSS_JUMP) jump(iEnt, flGameTime, iStateBits);
	else if(iStateBits & BOSS_FLY) fall(iEnt, flGameTime, iStateBits);
	else if(iStateBits & BOSS_FALL_ATTACK) fallAttack(iEnt, flGameTime, iStateBits);
	else if(iStateBits & BOSS_HOLE) holeAttack(iEnt, flGameTime, iStateBits);
	else if(iStateBits & BOSS_BOMB) dropBombs(iEnt, flGameTime, iStateBits);

	if(iStateBits & BOSS_ROTATE) rotate(iEnt, iStateBits);

	set_entvar(iEnt, var_boss_state, iStateBits);
	set_entvar(iEnt, var_nextthink, flGameTime + BOSS_THINKDELAY);
}

/* Бездействие босса */

stock startIdle(iEnt, Float:flGameTime, &iStateBits)
{
	iStateBits |= BOSS_IDLE;
	idle(iEnt, flGameTime, iStateBits)
}

stock idle(iEnt, Float:flGameTime, &iStateBits)
{
	if(Float:get_entvar(iEnt, var_boss_nextstate) > flGameTime)
		return;
	
	set_entvar(iEnt, var_velocity, Float:{0.0, 0.0, -0.1})

	if(~iStateBits & BOSS_SECONDPHASE && 
		Float:get_entvar(iEnt, var_health) <= Float:get_entvar(iEnt, var_max_health) / 2.0)
	{
		startSecondPhase(iEnt, flGameTime, iStateBits);
		return;
	}	

	new iPlayer;
	if((iPlayer = closeAliveUser(iEnt, get_entvar(iEnt, var_enemy))) == NULLENT) {
		UTIL_SetEntityAnim(iEnt, iStateBits & BOSS_SECONDPHASE ? IDLE_CLAWS : IDLE);
		set_entvar(iEnt, var_boss_nextstate, flGameTime + (iStateBits & BOSS_SECONDPHASE ? TIME_IDLE_CLAWS : TIME_IDLE));
		return;
	}

	set_entvar(iEnt, var_enemy, iPlayer);
	
	iStateBits &= ~BOSS_IDLE;

	new iRandom = random(100);

	switch(iRandom)
	{
		case 0..69: startRun(iEnt, flGameTime, iStateBits);
		case 70..79: startHole(iEnt, flGameTime, iStateBits);
		case 80..89: startJump(iEnt, flGameTime, iStateBits);
		case 90..99: startBomb(iEnt, flGameTime, iStateBits)
	}
}

/* Переход во вторую фазу */

stock startSecondPhase(iEnt, Float:flGameTime, &iStateBits)
{
	UTIL_SetEntityAnim(iEnt, SCENE_CLAWS);
	iStateBits |= BOSS_SECONDPHASE;
	emit_sound(iEnt, CHAN_AUTO, BOSS_SOUND_SECOND_PHASE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_SCENE_CLAWS);
}

/* Ходьба за игроком */

stock startRun(iEnt, Float:flGameTime, &iStateBits)
{
	iStateBits |= (BOSS_RUN|BOSS_ROTATE);
	set_entvar(iEnt, var_boss_enemydelay, flGameTime + 20.0);

	new iAttackZone = get_entvar(iEnt, var_boss_attackzone);
	attackZoneToggle(iAttackZone, true);
	
	set_entvar(iEnt, var_boss_rotatecoef, BOSS_ROTATE_COEF_DEF);
	set_entvar(iEnt, var_boss_animdelay, 0.0);

	run(iEnt, flGameTime, iStateBits);
}

stock run(iEnt, Float:flGameTime, &iStateBits)
{
	// if(Float:get_entvar(iEnt, var_boss_nextstate) > flGameTime)
	// 	return;

	new iPlayer = get_entvar(iEnt, var_enemy);

	if(!is_user_alive(iPlayer) || Float:get_entvar(iEnt, var_boss_enemydelay) < flGameTime) {

		new iAttackZone = get_entvar(iEnt, var_boss_attackzone);
		attackZoneToggle(iAttackZone, false);

		iStateBits &= ~(BOSS_RUN|BOSS_ROTATE);
		startIdle(iEnt, flGameTime, iStateBits);
		return;
	}

	new Float:vecVelocity[3];
	bossMoveToEnt(iEnt, iPlayer, iStateBits & BOSS_SECONDPHASE ? BOSS_WALKSPEED_CLAWS : BOSS_WALKSPEED, vecVelocity);
	set_entvar(iEnt, var_velocity, vecVelocity);

	if(Float:get_entvar(iEnt, var_boss_animdelay) <= flGameTime) 
	{
		UTIL_SetEntityAnim(iEnt, iStateBits & BOSS_SECONDPHASE ? WALK_CLAWS : WALK);
		set_entvar(iEnt, var_boss_animdelay, flGameTime + (iStateBits & BOSS_SECONDPHASE ? TIME_WALK_CLAWS : TIME_WALK));
		set_entvar(iEnt, var_boss_nextshake, flGameTime + (iStateBits & BOSS_SECONDPHASE ? TIME_WALK_CLAWS_FIRST_SHAKE : TIME_WALK_FIRST_SHAKE));
	} 
	

	if(Float:get_entvar(iEnt, var_boss_nextshake) <= flGameTime)
	{
		bossShake(iEnt);
		set_entvar(iEnt, var_boss_nextshake, flGameTime + (iStateBits & BOSS_SECONDPHASE ? TIME_WALK_CLAWS_OTHER_SHAKE : TIME_WALK_OTHER_SHAKE));
	}	
}

stock bossShake(iEnt, Float:flRadius = 500.0)
{
	new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin);
	new Float:vecPlayer[3];
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) 
	{
		if(!is_user_alive(iPlayer)) continue;
		get_entvar(iPlayer, var_origin, vecPlayer);
		if(get_distance_f(vecOrigin, vecPlayer) > flRadius) continue;
		MSG_ScreenShake(iPlayer, 90.0, 0.8, 0.5);
	}
}

/* Атака */

stock startAttack(iEnt, Float:flGameTime, &iStateBits)
{
	iStateBits |= (BOSS_ATTACK|BOSS_ROTATE);
	set_entvar(iEnt, var_boss_rotatecoef, BOSS_ROTATE_COEF_SMOOTH);
	
	set_entvar(iEnt, var_velocity, Float:{0.0, 0.0, -0.1})
	new iAnim = iStateBits & BOSS_SECONDPHASE ? random_num(ATTACK_RHAND_CLAWS, ATTACK_LHAND_CLAWS) : random_num(ATTACK_RHAND, ATTACK_LHAND);

	UTIL_SetEntityAnim(iEnt, iAnim);
	switch(iAnim)
	{
		case ATTACK_RHAND: 
		{
			emit_sound(iEnt, CHAN_AUTO, BOSS_SOUND_RHAND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_RHAND_HIT);
		}
		case ATTACK_LHAND: 
		{
			emit_sound(iEnt, CHAN_AUTO, BOSS_SOUND_LHAND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_LHAND_HIT);
		}
		case ATTACK_RHAND_CLAWS: 
		{
			emit_sound(iEnt, CHAN_AUTO, BOSS_SOUND_RHAND_CLAWS, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_RHAND_CLAWS_HIT);
		}
		case ATTACK_LHAND_CLAWS: 
		{
			emit_sound(iEnt, CHAN_AUTO, BOSS_SOUND_LHAND_CLAWS, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_LHAND_CLAWS_HIT);
		}
	}
}

stock attack(iEnt, Float:flGameTime, &iStateBits)
{
	if(Float:get_entvar(iEnt, var_boss_nextstate) > flGameTime)
		return;

	new iAnim = get_entvar(iEnt, var_sequence);

	switch(iAnim)
	{
		case ATTACK_RHAND: 
		{
			new Float:vecOrigin[3]; GetBonePosition(iEnt, 36, vecOrigin);
			
			damageRadius(iEnt, vecOrigin, BOSS_RADIUS_RHAND, BOSS_DAMAGE_RHAND, (DMG_ALWAYSGIB|DMG_BULLET), true)
			set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_RHAND_END);
		}
		case ATTACK_LHAND: 
		{
			new Float:vecOrigin[3]; GetBonePosition(iEnt, 13, vecOrigin);
			damageRadius(iEnt, vecOrigin, BOSS_RADIUS_LHAND, BOSS_DAMAGE_LHAND, (DMG_ALWAYSGIB|DMG_BULLET), true);
			set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_LHAND_END);
		}
		case ATTACK_RHAND_CLAWS:
		{
			new Float:vecOrigin[3]; GetBonePosition(iEnt, 36, vecOrigin);
			damageRadius(iEnt, vecOrigin, BOSS_RADIUS_RHAND_CLAWS, BOSS_DAMAGE_RHAND_CLAWS, (DMG_ALWAYSGIB|DMG_BULLET), true)
			set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_RHAND_CLAWS_END);
		}
		case ATTACK_LHAND_CLAWS: 
		{
			new Float:vecOrigin[3]; GetBonePosition(iEnt, 13, vecOrigin);
			damageRadius(iEnt, vecOrigin, BOSS_RADIUS_LHAND_CLAWS, BOSS_DAMAGE_LHAND_CLAWS, (DMG_ALWAYSGIB|DMG_BULLET), true);
			set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_LHAND_CLAWS_END);
		}
	}
	
	iStateBits &= ~(BOSS_ATTACK|BOSS_ROTATE);
	startIdle(iEnt, flGameTime, iStateBits);
}

/* Начало прыжка */

stock startJump(iEnt, Float:flGameTime, &iStateBits)
{
	iStateBits |= (BOSS_JUMP);
	set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_JUMP_PREPARE);
	UTIL_SetEntityAnim(iEnt, iStateBits & BOSS_SECONDPHASE ? ATTACK_JUMP_CLAWS : ATTACK_JUMP)
}

stock jump(iEnt, Float:flGameTime, &iStateBits)
{
	if(Float:get_entvar(iEnt, var_boss_nextstate) > flGameTime)
		return;

	new iPlayer = get_entvar(iEnt, var_enemy);
	if(!is_user_alive(iPlayer))
	{
		iPlayer = closeAliveUser(iEnt, get_entvar(iEnt, var_enemy));
		
		if(iPlayer == NULLENT) 
		{
			startIdle(iEnt, flGameTime, iStateBits);
			return;
		}

		set_entvar(iEnt, var_enemy, iPlayer);
	}

	iStateBits &= ~(BOSS_JUMP);
	iStateBits |= (BOSS_FLY|BOSS_ROTATE);

	emit_sound(iEnt, CHAN_AUTO, BOSS_SOUND_JUMP, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin);

	new Float:vecPlayer[3]; get_entvar(iPlayer, var_origin, vecPlayer);
	UTIL_DropVectorToFloor(vecPlayer);
	vecPlayer[2] += -BOSS_MINSIZE[2] + 10.0;

	new Float:vecVelocity[3];
	
	UTIL_GetSpeedVectorByGravity(vecOrigin, vecPlayer, TIME_ATTACK_JUMP_FLY - 0.1, vecVelocity)
	set_entvar(iEnt, var_velocity, vecVelocity);
	// set_entvar(iEnt, var_movetype, MOVETYPE_TOSS);
	attackZoneToggle(get_entvar(iEnt, var_boss_attackzone), true, "@TouchAttackZoneKill");
	set_entvar(iEnt, var_boss_rotatecoef, BOSS_ROTATE_COEF_SMOOTH);
	
	set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_JUMP_FLY);
}

stock fall(iEnt, Float:flGameTime, &iStateBits)
{
	if(Float:get_entvar(iEnt, var_boss_nextstate) > flGameTime)
		return;

	iStateBits &= ~(BOSS_FLY|BOSS_ROTATE);
	iStateBits |= BOSS_FALL_ATTACK;

	emit_sound(iEnt, CHAN_AUTO, BOSS_SOUND_FALL, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	// set_entvar(iEnt, var_movetype, MOVETYPE_FLY);
	set_entvar(iEnt, var_movetype, MOVETYPE_NONE);

	set_entvar(iEnt, var_velocity, Float:{0.0, 0.0, -10.0});
	attackZoneToggle(get_entvar(iEnt, var_boss_attackzone), false);

	set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_JUMP_ONGROUND);
}

@TouchAttackZoneKill(iEnt, iToucher)
{
	new iBoss = get_entvar(iEnt, var_owner);

	if(!is_user_alive(iToucher) || Float:get_entvar(iBoss, var_boss_nextstate) - get_gametime() > TIME_ATTACK_JUMP_FLY / 2.0)
		return;

	ExecuteHamB(Ham_Killed, iToucher, get_entvar(iEnt, var_owner), 1);
}

stock fallAttack(iEnt, Float:flGameTime, &iStateBits)
{
	if(Float:get_entvar(iEnt, var_boss_nextstate) > flGameTime)
		return;

	set_entvar(iEnt, var_velocity, Float:{0.0, 0.0, -0.1});

	new Float:vecOrigin[3]; GetBonePosition(iEnt, 36, vecOrigin);
	new Float:flRadius = iStateBits & BOSS_SECONDPHASE ? BOSS_RADIUS_FALL_CLAWS : BOSS_RADIUS_FALL
	new Float:flDamage = iStateBits & BOSS_SECONDPHASE ? BOSS_DAMAGE_FALL_CLAWS : BOSS_DAMAGE_FALL

	damageRadius(iEnt, vecOrigin, flRadius, flDamage, (DMG_ALWAYSGIB|DMG_BULLET), true)

	iStateBits &= ~(BOSS_FALL_ATTACK);

	set_entvar(iEnt, var_movetype, MOVETYPE_PUSHSTEP);
	set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_JUMP_ATTACK);
	startIdle(iEnt, flGameTime, iStateBits);
}


/* Начало чёрной дырки */

stock startHole(iEnt, Float:flGameTime, &iStateBits)
{
	iStateBits |= (BOSS_HOLE);
	
	emit_sound(iEnt, CHAN_AUTO, BOSS_SOUND_HOLE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin);
	vecOrigin[2] += BOSS_MINSIZE[2]
	spawnHole(vecOrigin);

	UTIL_SetEntityAnim(iEnt, iStateBits & BOSS_SECONDPHASE ? ATTACK_HOLE_CLAWS : ATTACK_HOLE);
	set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_HOLE_PREPARE);
}

stock holeAttack(iEnt, Float:flGameTime, &iStateBits)
{
	if(Float:get_entvar(iEnt, var_boss_nextstate) > flGameTime)
		return;
	
	new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin);
	new Float:flRadius = iStateBits & BOSS_SECONDPHASE ? BOSS_RADIUS_HOLE_CLAWS : BOSS_RADIUS_HOLE
	new Float:flDamage = iStateBits & BOSS_SECONDPHASE ? BOSS_DAMAGE_HOLE_CLAWS : BOSS_DAMAGE_HOLE
	damageRadius(iEnt, vecOrigin, flRadius, flDamage, (DMG_ALWAYSGIB|DMG_BULLET), true, true)

	iStateBits &= ~(BOSS_HOLE);
	set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_HOLE_ATTACK);
	
	startIdle(iEnt, flGameTime, iStateBits);
}

/* Начало бомбочек */

stock startBomb(iEnt, Float:flGameTime, &iStateBits)
{
	iStateBits |= BOSS_BOMB;
	emit_sound(iEnt, CHAN_AUTO, BOSS_SOUND_START_BOMBS, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_BOMB_PREPARE);
	UTIL_SetEntityAnim(iEnt, iStateBits & BOSS_SECONDPHASE ? ATTACK_BOMB_CLAWS : ATTACK_BOMB);
	set_entvar(iEnt, var_boss_droptimes, 0);
}

stock dropBombs(iEnt, Float:flGameTime, &iStateBits)
{
	if(Float:get_entvar(iEnt, var_boss_nextstate) > flGameTime)
		return;

	new iTimes = get_entvar(iEnt, var_boss_droptimes);

	if(++iTimes > 3)
	{
		iStateBits &= ~(BOSS_BOMB);
		startIdle(iEnt, flGameTime, iStateBits);
		return;
	}

	bossDropBombs(iEnt);
	emit_sound(iEnt, CHAN_AUTO, BOSS_SOUND_DROP_BOMBS, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_entvar(iEnt, var_boss_droptimes, iTimes);
	set_entvar(iEnt, var_boss_nextstate, flGameTime + TIME_ATTACK_BOMBS[iTimes - 1]);
}

stock bossDropBombs(iEnt)
{
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(!is_user_alive(iPlayer)) continue;
		spawnBomb(iEnt, iPlayer);
	}
}

/* Плавный поворот */

stock rotate(iEnt, &iStateBits)
{
	new iEnemy = get_entvar(iEnt, var_enemy);
	if(!is_user_alive(iEnemy)) return;

	new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin);
	new Float:vecEnemy[3]; get_entvar(iEnemy, var_origin, vecEnemy);
	
	new Float:vecDir[3]; xs_vec_sub(vecEnemy, vecOrigin, vecDir);
	vecDir[2] = 0.0;

	if(xs_vec_len(vecDir) >= 1.0)
	{
		new Float:vecOldAngles[3]; get_entvar(iEnt, var_angles, vecOldAngles);
		new Float:vecGoalAngle[3]; vector_to_angle(vecDir, vecGoalAngle);
		new Float:vecAngles[3];
		UTIL_InterpolateAngle(vecOldAngles, vecGoalAngle, vecAngles, Float:get_entvar(iEnt, var_boss_rotatecoef));
		set_entvar(iEnt, var_angles, vecAngles);
		set_entvar(iEnt, var_v_angle, vecAngles);
		set_entvar(iEnt, var_fixangle, 1);
	}
}


stock damageRadius(iAttacker, Float:vecOrigin[3], Float:flRadius, Float:flDamage, iBitDamage, bool:isPunch = false, bool:isKnock = false) {
	new Float:vecPlayer[3];
	new Float:vecPunch[3];

	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if(!is_user_alive(iPlayer)) continue;
		get_entvar(iPlayer, var_origin, vecPlayer);
		if(get_distance_f(vecOrigin, vecPlayer) > flRadius) continue;
		ExecuteHamB(Ham_TakeDamage, iPlayer, iAttacker, iAttacker, flDamage, iBitDamage)
	
		if(isPunch) 
		{		
			vecPunch[0] = random_float(0.0, 50.0);
			vecPunch[1] = random_float(0.0, 50.0);
			vecPunch[2] = random_float(0.0, 50.0);
			
			set_entvar(iPlayer, var_punchangle, vecPunch)
		}

		if(isKnock)
			UTIL_PlayerKnockBack(iPlayer, iAttacker, 1000.0);
	}
}


stock bossMoveToEnt(iAttacker, iVictim, Float:flSpeed, Float:vecVelocity[3]) {
	new Float:vecAttacker[3]; get_entvar(iAttacker, var_origin, vecAttacker);
	new Float:vecVictim[3]; get_entvar(iVictim, var_origin, vecVictim);
	new Float:vecDirection[3]; xs_vec_sub(vecVictim, vecAttacker, vecDirection);
	xs_vec_normalize(vecDirection, vecDirection);

	vecDirection[2] = 0.0;
	new Float:vecOldAngles[3]; get_entvar(iAttacker, var_angles, vecOldAngles);

	xs_vec_mul_scalar(vecDirection, flSpeed, vecVelocity)
}

stock bossMoveToPoint(iAttacker, Float:vecGoal[3], Float:flSpeed, Float:vecVelocity[3]) {
	new Float:vecAttacker[3]; get_entvar(iAttacker, var_origin, vecAttacker);
	new Float:vecDirection[3]; xs_vec_sub(vecGoal, vecAttacker, vecDirection);
	xs_vec_normalize(vecDirection, vecDirection);

	vecDirection[2] = 0.0;
	new Float:vecOldAngles[3]; get_entvar(iAttacker, var_angles, vecOldAngles);

	xs_vec_mul_scalar(vecDirection, flSpeed, vecVelocity)
}

stock closeAliveUser(iAttacker, iIgnoreEnt) {
	new Float:vecAttacker[3]; get_entvar(iAttacker, var_origin, vecAttacker);
	new iTarget = NULLENT, Float:flDist, Float:flDistCur, Float:vecTarget[3];

	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if(!is_user_alive(iPlayer) || iIgnoreEnt == iPlayer) continue;
		
		get_entvar(iPlayer, var_origin, vecTarget);
		flDistCur = get_distance_f(vecAttacker, vecTarget);
		
		if(flDist != 0.0 && flDist < flDistCur) continue;

		iTarget = iPlayer;
		flDist = flDistCur;
	}  

	if(iTarget == NULLENT && is_user_alive(iIgnoreEnt))
		return iIgnoreEnt

	return iTarget;
}

stock spawnHPBar(iFollow) {
	new iEnt = rg_create_entity(HPBAR_REFERENCE);

	if(is_nullent(iEnt)) return NULLENT;

	set_entvar(iEnt, var_classname, HPBAR_CLASSNAME);
	set_entvar(iEnt, var_scale, HPBAR_SCALE);
	set_entvar(iEnt, var_movetype, MOVETYPE_FOLLOW);

	set_entvar(iEnt, var_owner, iFollow);
	set_entvar(iEnt, var_aiment, iFollow);
	set_entvar(iEnt, var_body, 1);

	engfunc(EngFunc_SetModel, iEnt, HPBAR_MODEL);

	dllfunc(DLLFunc_Spawn, iEnt);

	set_entvar(iEnt, var_effects, get_entvar(iEnt, var_effects) | EF_FORCEVISIBILITY)
	set_entvar(iEnt, var_frame, HPBAR_FRAMEMAX);

	return iEnt;
}

stock spawnAttackZone(iFollow)
{
	new iEnt = rg_create_entity(ATTACKZONE_REFERENCE);

	if(is_nullent(iEnt)) return NULLENT;

	set_entvar(iEnt, var_classname, ATTACKZONE_CLASSNAME);

	set_entvar(iEnt, var_movetype, MOVETYPE_FOLLOW);
	set_entvar(iEnt, var_owner, iFollow);
	set_entvar(iEnt, var_aiment, iFollow);
	// set_entvar(iEnt, var_takedamage, DAMAGE_YES);

	engfunc(EngFunc_SetSize, iEnt, ATTACKZONE_MINSIZE, ATTACKZONE_MAXSIZE)

	return iEnt;
}

stock attackZoneToggle(iEnt, bool:isEnable = true, szTouchFunction[] = "@AttackZoneTouch") 
{
	set_entvar(iEnt, var_solid, isEnable ? SOLID_TRIGGER : SOLID_NOT);
	SetTouch(iEnt, isEnable ? szTouchFunction : "");
}

@AttackZoneTouch(iEnt, iToucher)
{
	if(!IsPlayer(iToucher)) return;

	new iBoss = get_entvar(iEnt, var_owner);
	set_entvar(iBoss, var_enemy, iToucher);

	new iStateBits = get_entvar(iBoss, var_boss_state);

	iStateBits &= ~BOSS_RUN;
	attackZoneToggle(iEnt, false);

	startAttack(iBoss, get_gametime(), iStateBits);

	set_entvar(iBoss, var_boss_state, iStateBits);
}

stock spawnHole(Float:vecOrigin[3])
{
	new iEnt = rg_create_entity(HOLE_REFERENCE);

	if(is_nullent(iEnt)) return NULLENT;

	set_entvar(iEnt, var_classname, HOLE_CLASSNAME);

	engfunc(EngFunc_SetModel, iEnt, HOLE_MODEL);
	engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);

	UTIL_SetEntityAnim(iEnt, HOLE_IDLE1);
	
	SetThink(iEnt, "@ThinkHole");
	new Float:flGameTime = get_gametime();
	set_entvar(iEnt, var_nextthink, flGameTime + HOLE_THINK);
	set_entvar(iEnt, var_hole_state, HOLE_INCREASE);
	set_entvar(iEnt, var_hole_nextstate, flGameTime + TIME_HOLE_IDLE1_INCREASE);

	return iEnt;
}

@ThinkHole(iEnt) 
{
	switch(get_entvar(iEnt, var_hole_state))
	{
		case HOLE_INCREASE: holeIncrease(iEnt);
		case HOLE_DECREASE: holeDecrease(iEnt);
	}
	set_entvar(iEnt, var_nextthink, get_gametime() + HOLE_THINK)
}

stock holeIncrease(iEnt)
{
	new Float:flGameTime = get_gametime(),  
		Float:flNextState = get_entvar(iEnt, var_hole_nextstate);

	if(flNextState > flGameTime)
	{
		new Float:flTime = TIME_HOLE_IDLE1_INCREASE - (flNextState - flGameTime);
		new Float:flPerCent = flTime / TIME_HOLE_IDLE1_INCREASE;
		new Float:flRadius = UTIL_Lerp(0.0, HOLE_RADIUS, flPerCent);
		
		movePlayersTo2DEnt(iEnt, flRadius, 100.0 * (1.0 - flPerCent));
		return;
	}

	set_entvar(iEnt, var_hole_nextstate, flGameTime + TIME_HOLE_IDLE1_DECREASE);
	set_entvar(iEnt, var_hole_state, HOLE_DECREASE);
}

stock holeDecrease(iEnt)
{
	new Float:flGameTime = get_gametime(),  
		Float:flNextState = get_entvar(iEnt, var_hole_nextstate);

	if(flNextState > flGameTime)
	{
		new Float:flTime = TIME_HOLE_IDLE1_DECREASE - (flNextState - flGameTime);
		new Float:flPerCent = flTime / TIME_HOLE_IDLE1_DECREASE;
		new Float:flRadius = UTIL_Lerp(HOLE_RADIUS, 0.0, flTime / TIME_HOLE_IDLE1_DECREASE);
		
		movePlayersTo2DEnt(iEnt, flRadius, 100.0 * (1.0 - flPerCent) );
		return;
	}

	rg_remove_entity(iEnt);
}


stock movePlayersTo2DEnt(iEnt, Float:flRadius, Float:flSpeed = 50.0)
{
	new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin); vecOrigin[2] = 0.0;
	new Float:vecPlayer[3], Float:vecVelocity[3], Float:vecOldVelocity[3];
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(!is_user_alive(iPlayer))
			continue;
	
		get_entvar(iPlayer, var_origin, vecPlayer); vecPlayer[2] = 0.0

		if(get_distance_f(vecOrigin, vecPlayer) > flRadius)
			continue;
		
		bossMoveToPoint(iPlayer, vecOrigin, flSpeed, vecVelocity);

		get_entvar(iPlayer, var_velocity, vecOldVelocity);
		xs_vec_add(vecOldVelocity, vecVelocity, vecVelocity);
		set_entvar(iPlayer, var_velocity, vecVelocity);
	}
}

stock spawnBomb(iAttacker, iVictim)
{
	new iEnt = rg_create_entity(BOMB_REFERENCE);

	if(is_nullent(iEnt)) return NULLENT;

	set_entvar(iEnt, var_owner, iAttacker);
	set_entvar(iEnt, var_classname, BOMB_CLASSNAME);
	set_entvar(iEnt, var_solid, SOLID_TRIGGER)
	set_entvar(iEnt, var_movetype, MOVETYPE_TOSS)

	new Float:vecAttacker[3]; get_entvar(iAttacker, var_origin, vecAttacker);

	engfunc(EngFunc_SetModel, iEnt, BOMB_MODEL);
	engfunc(EngFunc_SetSize, iEnt, BOMB_MINSIZE, BOMB_MAXSIZE);
	engfunc(EngFunc_SetOrigin, iEnt, vecAttacker);

	UTIL_SetEntityAnim(iEnt, BOMB_IDLE);
	
	new Float:vecVictim[3]; get_entvar(iVictim, var_origin, vecVictim);
	new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin);
	new Float:vecVelocity[3]; UTIL_GetSpeedVectorByGravity(vecOrigin, vecVictim, BOMB_FLYTIME, vecVelocity);

	set_entvar(iEnt, var_velocity, vecVelocity);

	new Float:vecAngles[3]; vector_to_angle(vecVelocity, vecAngles);
	set_entvar(iEnt, var_angles, vecAngles);

	SetTouch(iEnt, "@TouchBomb");

	return iEnt;
}

@TouchBomb(iEnt, iTouch)
{
	if(FClassnameIs(iTouch, BOMB_CLASSNAME) || FClassnameIs(iTouch, BOSS_CLASSNAME))
		return;

	new iBoss = get_entvar(iEnt, var_owner);
	new iStateBits = get_entvar(iBoss, var_boss_state);

	new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin)
	MSG_Explosion(vecOrigin, g_iModelIndex_Explosion, 5.0, 2.0, 0);
	new Float:flRadius = iStateBits & BOSS_SECONDPHASE ? BOMB_RADIUS_CLAWS : BOMB_RADIUS
	new Float:flDamage = iStateBits & BOSS_SECONDPHASE ? BOMB_DAMAGE_CLAWS : BOMB_DAMAGE
	damageRadius(iEnt, vecOrigin, flRadius, flDamage, (DMG_ALWAYSGIB|DMG_BULLET), true);
	
	rg_remove_entity(iEnt);
}

stock bool:giveUserPrize(iEnt, iPlayer)
{
	new iPrizeBits = get_entvar(iEnt, var_boss_prizebits);

	if(IsSetBit(iPrizeBits, iPlayer))
		return false;

	SetBit(iPrizeBits, iPlayer)
	set_entvar(iEnt, var_boss_prizebits, iPrizeBits);

	switch(random(3))
	{
		case 0:
		{
			new iMoney = random_num(40000, 52000);
			zp_set_user_money(iPlayer, zp_get_user_money(iPlayer) + iMoney);
		
			set_dhudmessage(255, 255, 255, -1.0, 0.65);
			show_dhudmessage(iPlayer, "Вы получили %d$ из подарка", iMoney);
		}
		case 1:
		{
			new iAmmo = random_num(100, 150);
			zp_set_user_ammo(iPlayer, zp_get_user_ammo(iPlayer) + iAmmo);
		
			set_dhudmessage(255, 255, 255, -1.0, 0.65);
			show_dhudmessage(iPlayer, "Вы получили %d аммо из подарка", iAmmo);
		}
		case 2:
		{
			new iExp = random_num(200, 500);
			zpe_set_user_exp(iPlayer, zpe_get_user_exp(iPlayer) + iExp);
		
			set_dhudmessage(255, 255, 255, -1.0, 0.65);
			show_dhudmessage(iPlayer, "Вы получили %d exp из подарка", iExp);
		}
	}

	return true;
}


stock spawnPrize(iBoss)
{
	new iEnt = rg_create_entity(PRIZE_REFERENCE);

	if(is_nullent(iEnt)) return NULLENT;

	new Float:vecOrigin[3]; get_entvar(iBoss, var_origin, vecOrigin);

	engfunc(EngFunc_SetModel, iEnt, PRIZE_MODEL);
	engfunc(EngFunc_SetSize, iEnt, PRIZE_MINSIZE, PRIZE_MAXSIZE);
	engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);

	set_entvar(iEnt, var_classname, PRIZE_CLASSNAME);
	set_entvar(iEnt, var_owner, iBoss);
	set_entvar(iEnt, var_solid, SOLID_TRIGGER);
	set_entvar(iEnt, var_movetype, MOVETYPE_TOSS);
	set_entvar(iEnt, var_body, PRIZE_BODY);

	new Float:vecVelocity[3];

	vecVelocity[0] = random_float(-1.0, 1.0);
	vecVelocity[1] = random_float(-1.0, 1.0);
	
	new Float:vecAngles[3]; xs_vec_mul_scalar(vecVelocity, -1.0, vecAngles);
	vector_to_angle(vecAngles, vecAngles);

	set_entvar(iEnt, var_angles, vecAngles);
	
	vecVelocity[2] = 1.0; 

	xs_vec_normalize(vecVelocity, vecVelocity);

	xs_vec_mul_scalar(vecVelocity, 500.0, vecVelocity);

	set_entvar(iEnt, var_velocity, vecVelocity);

	SetTouch(iEnt, "@PrizeTouch");
	return iEnt;
}

@PrizeTouch(iEnt, iToucher)
{
	if(!is_user_alive(iToucher)) return;

	if(!giveUserPrize(get_entvar(iEnt, var_owner), iToucher)) return;

	rh_emit_sound2(iEnt, 0, CHAN_AUTO, PRIZE_SOUND);
	rg_remove_entity(iEnt);
}