#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
// #include <dhudmessage>
#include <zombieplague>
#include <reapi>

#define NAME 			"OberonBoss"
#define VERSION			"3.1.2"
#define AUTHOR			"Alexander.3/heka"

#define NEW_SEARCH
#define RANDOM_ABILITY

// #define MAPCHOOSER

#define KILL_MONEY					3000

#define DMG_MONEY					20
#define DAMAGE_REWARD				600

new g_MsgSync2

new g_game_start

new const playerModelOberon[] = "npc_oberon";

new const Resource[][] = {
	"models/npc_hardcs/npc_oberon_attach.mdl",				// 0
	"sprites/npc_hp_grade2.spr",					// 1
	"sprites/blood.spr",							// 2
	"sprites/bloodspray.spr",						// 3
	"models/npc_hardcs/bomb.mdl",					// 4
	"sprites/eexplo.spr",							// 5
	"models/npc_hardcs/hole.mdl",					// 6
	"models/npc_hardcs/claws_trails.mdl", 					// 7
	"models/npc_hardcs/box.mdl",					// 8
	"models/npc_hardcs/gibs_bossbox.mdl",			// 9
	"models/npc_hardcs/box_gibs.mdl"						// 10
}
static g_Resource[sizeof Resource]
new const SoundList[][] =
{
	"npc/oberon/footstep_1.wav",		// 0
	"npc/oberon/footstep_2.wav",		// 1
	"npc/oberon/attack1.wav",			// 2 -
	"npc/oberon/attack2.wav",			// 3 -
	"npc/oberon/attack3.wav",			// 4 -
	"npc/oberon/attack1_knife.wav",		// 5 -
	"npc/oberon/attack2_knife.wav",		// 6 -
	"npc/oberon/bomb.wav",				// 7 -
	"npc/oberon/hole.wav",				// 8 -
	"npc/oberon/jump.wav",				// 9 -
	"npc/oberon/knife.wav",				// 10 -
	"npc/oberon/roar.wav",				// 11 -
	"npc/oberon/death.wav",				// 12 -
	"npc/alienboss/zombie_scenario_ready.mp3",		// 13
	"npc/alienboss/scenario_rush.mp3",	// 14
	"npc/oberon/aftermatch.mp3",		// 15
	"npc/alienboss/voice2.wav",			// 16
	"npc/alienboss/swing.wav",			// 17
	"npc/alienboss/death.wav",			// 18
	"npc/oberon/voice_2.wav",			// 19
	"npc/oberon/voice3.wav"				// 20
}

new const g_CountSound[][] = 
{ 
	"city/other/1.wav",
	"city/other/2.wav",
	"city/other/3.wav",
	"city/other/4.wav",
	"city/other/5.wav"
}

new const FILE_SETTING[] = "zl_oberonboss.ini"
new boss_heal, prepare_time, Float:bomb_dist, blood_color,
	speed_boss, dmg_attack_max, dmg_attack, bomb_damage, hole_dmg, jump_damage, jump_distance, time_ability,
	speed_boss_agr, bomb_damage_agr, hole_dmg_agr, jump_damage_agr, time_ability_agr,dmg_attack_agr,dmg_attack_agr_max


#if defined MAPCHOOSER
native zl_vote_start()
#else
new boss_nextmap[32]
#endif
	
#define MAX_BOMB		32

static g_Oberon, g_Bomb[MAX_BOMB], g_Hole, Float:g_MaxHp
#define var_activity_ent var_iuser1
static e_boss, Box, hpbar
new g_iModelIndex;

enum {
	RUN,
	ATTACK,
	BOMB,
	HOLE,
	JUMP,
	AGRESS
}

#define MONSTER_REFERANCE	"info_target" 

#define pev_pre				pev_euser1
#define pev_num				pev_euser2
#define pev_ability			pev_euser3
#define pev_victim			pev_euser4
new bool:RoundEnd

public plugin_init()
{
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );

	if( contain( szMapName, "zl_boss_oberon" ) == -1 )
		return;
		
	register_plugin(NAME, VERSION, AUTHOR)

	RegisterHam(Ham_TraceAttack, MONSTER_REFERANCE, "Hook_TraceAttack");
	RegisterHam(Ham_BloodColor, MONSTER_REFERANCE, "Hook_BloodColor")
	// RegisterHam(Ham_Killed, MONSTER_REFERANCE, "Hook_Killed")
	// RegisterHam(Ham_Killed, "player", "Hook_Killed", 1)
	// RegisterHam(Ham_Think,  MONSTER_REFERANCE, "@ThinkOberon")
	// RegisterHam(Ham_Touch, MONSTER_REFERANCE, "@BossTouch");
	// RegisterHam(Ham_Use, MONSTER_REFERANCE, "@BossUse");
	// RegisterHam(Ham_Think, MONSTER_REFERANCE, "@ThinkBoss");
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")	
	
	RegisterHam(Ham_TakeDamage, MONSTER_REFERANCE, "TakeDamage")
	RegisterHam(Ham_TakeDamage, MONSTER_REFERANCE, "TakeDamage_Post", true);
	// RegisterHam(Ham_Classify,      MONSTER_REFERANCE,    "@Classify_Pre",    false);
	// RegisterHookChain(RG_CBasePlayer_Classify, "@Classify_Pre", false)

	// register_think("OberonBoss", "@ThinkBoss")
	register_think("OberonKnife", "Think_Knife")
	register_think("Health", "Think_Health")
	register_think("Timer", "Think_Timer")
	register_think("OberonBox", "Think_Box")
	
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET);

	// register_touch("OberonBoss", "*", "Touch_Boss")
	register_touch("OberonBomb", "*", "Touch_Bomb")
	register_touch("OberonBoss", "func_breakable", "Touch_Boss_Use")
	
	register_dictionary("zp_oberonboss.txt")
	
	g_MsgSync2 = CreateHudSyncObj()
	
	RoundEnd = false
	
	MapEvent()
}

@ThinkBoss(iEnt){

	if(!FClassnameIs(iEnt, "OberonBoss")) 
		return HAM_IGNORED;

	client_print(0, print_chat, "m_Activity: %d", get_member(iEnt, m_Activity));
	return HAM_IGNORED;
	// return HAM_SUPERCEDE; 
}

/**
    Блокировка передвижения заложника при прикосновении к нему
 */
@BossTouch(iEnt, iToucher) {
	if(!FClassnameIs(iEnt, "OberonBoss") || !is_user_alive(iToucher)) 
		return HAM_IGNORED;

	// new Float:vecVelocity[3]; get_entvar(iEnt, var_velocity, vecVelocity);
	// set_entvar(iEnt, var_velocity, Float:{0.0,0.0,0.0});

	return HAM_SUPERCEDE;
}

/**
    Блокировка приручения заложника
 */
@BossUse(iEnt, iActivator) {
	if(!FClassnameIs(iEnt, "OberonBoss")) 
		return HAM_IGNORED;

	return HAM_SUPERCEDE;
}

public logevent_round_end(ent) 
{	
	RoundEnd = true
}

public event_round_start()
{
	if(RoundEnd) set_task(5.0, "change_map")
}	

stock SpawnBossActivity(iOwner) {
	new iEnt = rg_create_entity("info_target");
	set_entvar(iEnt, var_owner, iOwner);
	SetThink(iEnt, "Think_Boss")
	return iEnt;
}

stock SpawnHost(Float:vecOrigin[3]) {
	new iEnt = rg_create_entity(MONSTER_REFERANCE);
	engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);
	engfunc(EngFunc_SetModel, iEnt, Resource[0])
	set_entvar(iEnt, var_modelindex, g_Resource[0]);
	dllfunc(DLLFunc_Spawn, iEnt);
	engfunc(EngFunc_SetSize, iEnt, Float:{-40.0, -40.0, -40.0}, Float:{40.0, 40.0, 96.0});
	return iEnt;
}

public COberonNPC__SpawnEntity( const Float:vecOrigin[3] )
{
	new pEntity = rg_create_entity( "info_target" );
	if ( is_nullent( pEntity ) )
		return NULLENT;

	set_entvar( pEntity, var_classname, "OberonBoss" );
	// set_entvar( pEntity, var_impulse, gl_szOberonBoss );
	set_entvar( pEntity, var_solid, SOLID_BBOX );
	set_entvar( pEntity, var_movetype, MOVETYPE_PUSHSTEP );
	set_entvar( pEntity, var_takedamage, DAMAGE_AIM );
	set_entvar( pEntity, var_gamestate, 1 );
	set_entvar( pEntity, var_health, 100000.0 );
	set_entvar( pEntity, var_deadflag, DEAD_NO );
	set_entvar( pEntity, var_max_health, 100000.0 );
	set_entvar( pEntity, var_modelindex, g_Resource[0] );

	// engfunc( EngFunc_SetModel, pEntity, NpcModel );
	// engfunc( EngFunc_SetSize, pEntity, Float: { -32.0, -32.0, -285.0 }, Float: { 32.0, 32.0, 96.0 } );
	engfunc(EngFunc_SetSize, pEntity, Float:{-40.0, -40.0, -40.0}, Float:{40.0, 40.0, 96.0});
	engfunc( EngFunc_SetOrigin, pEntity, vecOrigin );

	// zp_debug_show_bbox( pEntity );

	return pEntity;
}

public Boss_Spawn(Float:hp, Ent) {
	
	// g_Oberon = enterBot("Oberon");
	// g_Oberon = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, MONSTER_REFERANCE))
	hpbar = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, MONSTER_REFERANCE))

	new Float:Origin[3]; pev(Ent, pev_origin, Origin); Origin[2] += 50.0
	g_Oberon = COberonNPC__SpawnEntity(Origin);
	set_entvar(g_Oberon, var_classname, "OberonBoss")
	new iActivityEnt = SpawnBossActivity(g_Oberon);
	set_entvar(g_Oberon, var_activity_ent, iActivityEnt);

	// engfunc(EngFunc_SetModel, g_Oberon, fmt("models/player/%s/%s.mdl", playerModelOberon, playerModelOberon))
	
	// set_entvar(g_Oberon, var_modelindex, g_Resource[0]);
	// set_member(g_Oberon, m_modelIndexPlayer, g_Resource[0]);

	// engfunc( EngFunc_RunPlayerMove, g_Oberon, Float:{0.0,0.0,0.0}, 0.0, 0.0, 0.0, 0, 0, 76 )
	// rg_set_user_model(g_Oberon, playerModelOberon, true)
	
	set_entvar(g_Oberon, var_solid, SOLID_SLIDEBOX);
	set_entvar(g_Oberon, var_movetype, MOVETYPE_STEP);
	// set_member(g_Oberon, m_bloodColor, BLOOD_COLOR_RED);
	// set_member(g_Oberon, m_flFieldOfView, 0.2);
	// #define MONSTER_NONE 0
	// set_member(g_Oberon, m_MonsterState, MONSTER_NONE);
	
	static Float:Angles[3]
	get_entvar(g_Oberon, var_angles, Angles)
	Angles[1] -= 85
	set_entvar(g_Oberon, var_angles, Angles)
	set_pev(g_Oberon, pev_health, hp)

	// set_entvar(g_Oberon, var_effects, 0);
	set_entvar(g_Oberon, var_takedamage, DAMAGE_AIM)
	set_entvar(g_Oberon, var_ideal_yaw, Angles[1]);
	set_entvar(g_Oberon, var_max_health, hp);
	set_entvar(g_Oberon, var_deadflag, DEAD_NO);
	#define MONSTERSTATE_IDLE 1
	// set_member(g_Oberon, m_IdealMonsterState, MONSTERSTATE_IDLE)
	// set_member(g_Oberon, m_IdealActivity, ACT_IDLE)
	// set_entvar(g_Oberon, var_flags, FL_MONSTER);

	engfunc(EngFunc_SetOrigin, g_Oberon, Origin)

	g_MaxHp = hp

	Origin[2] += 160.0
	engfunc(EngFunc_SetOrigin, hpbar, Origin)
	set_pev(hpbar, pev_effects, pev(hpbar, pev_effects) | EF_NODRAW)
	engfunc(EngFunc_SetModel, hpbar, Resource[1])
	entity_set_float(hpbar, EV_FL_scale, 0.67)
	set_pev(hpbar, pev_classname, "Health")
	set_pev(hpbar, pev_frame, 100.0)
	set_pev(hpbar, pev_aiment, g_Oberon);
	set_pev(hpbar, pev_movetype, MOVETYPE_FOLLOW);
	set_pev(hpbar, pev_body, 0);
	set_pev(hpbar, pev_skin, 0);

	set_pev(g_Oberon, pev_fuser1, get_gametime() + 15.0)
	set_pev(hpbar, pev_nextthink, get_gametime() + 10.0)

	Anim(g_Oberon, 0, 1.0)
}


public TakeDamage(victim, weapon, attacker, Float:damage, damagetype) 
{
	static ClassName[32], Float:dmg_buffer[33], Float:g_Health
	pev(victim, pev_classname, ClassName, charsmax(ClassName))
	if (equal(ClassName, "OberonBoss")) 
	{
		pev(victim, pev_health, g_Health)
		if(g_Health >= damage)
		{
			dmg_buffer[attacker] += damage
			if(dmg_buffer[attacker] >= DAMAGE_REWARD)
			{
				dmg_buffer[attacker] = 0.0
				zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + DMG_MONEY)
			}
		}
	}
	return HAM_HANDLED
}

new const g_szParseHit[][] =
{
	"generic",
	"head",
	"chest",
	"stomach",
	"l_arm",
	"r_arm",
	"l_leg",
	"r_leg",
	"shield"
}

public TakeDamage_Post(victim, weapon, attacker, Float:damage, damagetype) 
{
	static ClassName[32]
	pev(victim, pev_classname, ClassName, charsmax(ClassName))
	if (!equal(ClassName, "OberonBoss")) return;
	// new iHitGroup = get_member(victim, m_LastHitGroup)
	if(Float:get_entvar(victim, var_health) <= 0.0) @BossKilled(victim, attacker);
	client_print(0, print_center, "dmg: %f | FRAMERATE: %f", damage, Float:get_entvar(victim, var_framerate));
}

public EventPrepare() {
	new Float:Origin[3]
	Box = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, MONSTER_REFERANCE))
	engfunc(EngFunc_SetModel, Box, Resource[8])
	engfunc(EngFunc_SetSize, Box, Float:{-150.0, -150.0, -5.0}, Float:{150.0, 150.0, 150.0})
	Origin[0] = -351.0
	Origin[1] = -146.0
	Origin[2] = 962.0
	engfunc(EngFunc_SetOrigin, Box, Origin)
	set_pev(Box, pev_classname, "OberonBox")
	set_pev(Box, pev_solid, SOLID_SLIDEBOX)
	set_pev(Box, pev_movetype, MOVETYPE_NONE)
	set_pev(Box, pev_nextthink, get_gametime() + (prepare_time + 0.1))
	set_rendering(Box, kRenderFxFadeSlow, 255, 255, 0, kRenderTransAlpha, 255)
}

public Think_Box(Ent) {
	static Float:Origin[3]
	static Float:OriginBox[3]; pev(Box, pev_origin, OriginBox)
	switch (pev(Ent, pev_num)) 
	{
		case 0: 
		{
			static shake_num, sound
			if(sound == 0) client_cmd(0, "mp3 play ^"sound/%s^"", SoundList[14])
			if(shake_num == 0)
			{
				Sound(Box, 16)
			}
			else if(shake_num == 1)
			{		
				Sound(Box, 17)
			}
			else if (shake_num == 2)
			{
				set_pev(Ent, pev_num, 1)
			}			
			ScreenShake_Box(0, ((1<<14) * 3) ,  ((1<<12) * 3), ((2<<12) * 3))
			Rock(OriginBox, {1.0, 1.0, 1.0}, {25.0, 25.0, 25.0}, 10, 20, 50, (0x07))				
			shake_num++
			sound = 1
			set_pev(Ent, pev_nextthink, get_gametime() + 3.0)
		}
		case 1:
		{
			Sound(Box, 20)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.5)
			set_pev(Ent, pev_num, 2)
		}
		case 2: 
		{
			OriginBox[2] = 1350.0
			expl(OriginBox, 50, 5)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
			set_pev(Ent, pev_num, 3)
		}
		case 3: 
		{
			OriginBox[2] = 1750.0
			set_pev(Ent, pev_movetype, MOVETYPE_TOSS)
			set_pev(Box, pev_solid, SOLID_SLIDEBOX)
			expl(OriginBox, 50, 5)
			Sound(Box, 18)
			set_pev(Ent, pev_nextthink, get_gametime() + 1.1)
			set_pev(Ent, pev_num, 4)
		}
		case 4: 
		{
			Boss_Spawn(50_000.0, Ent)
			pev(Ent, pev_origin, Origin)
			ScreenShake_Box(0, ((1<<14) * 3) ,  ((1<<12) * 3), ((2<<12) * 3))
			//set_pev(Ent, pev_body, 1)
			set_pev(Ent, pev_nextthink, get_gametime() + 5.0)
			set_pev(Ent, pev_num, 5)
		}
		case 5: 
		{
			set_pev(Ent ,pev_solid, SOLID_SLIDEBOX)
			set_pev(g_Oberon, pev_ability, RUN)

			Anim(Ent, 1, 1.0)

			Anim(g_Oberon, 14, 1.0)
			
			Sound(g_Oberon, 11)

			new iActivityEnt = get_entvar(g_Oberon, var_activity_ent);
			set_pev(iActivityEnt, pev_nextthink, get_gametime() + 6.2)
			set_pev(Ent, pev_nextthink, get_gametime() + 0.02)

			Wreck(Origin, {100.0, 100.0, 100.0}, {100.0, 100.0, 100.0}, 30, 25, 50, (0x02))

			set_dhudmessage(255, 255, 0, -1.0, 0.0, 1, 6.0, 10000.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "BONUS_HUD")

			g_game_start = true

			set_pev(Ent, pev_num, 6)
		}
		case 6 : 
		{
			engfunc(EngFunc_RemoveEntity, Ent)
		}
	}
}

public client_putinserver(id)
{
	if(g_game_start) 
		set_pdata_int(id, 365, 1)
}
public Think_Boss(iActivityEnt) {
	new iBoss = get_entvar(iActivityEnt, var_owner);
	// client_print(0, print_chat, "THINK ACTIVITY");
	if (pev(iBoss, pev_deadflag) == DEAD_DYING)
		return

	if (!zl_player_alive()) {
		Anim(iBoss, 0, 1.0)
		set_pev(iActivityEnt, pev_nextthink, get_gametime() + 6.1)
		return
	}

	static Agr; Agr = pev(iBoss, pev_button)
	if (pev(iBoss, pev_fuser1) <= get_gametime()) {
		if (pev(iBoss, pev_ability) == RUN && pev(iBoss, pev_button) != 3) {
			#if defined RANDOM_ABILITY
			switch( random(3) ) {
				case 0: set_pev(iBoss, pev_ability, BOMB)
				case 1: set_pev(iBoss, pev_ability, HOLE)
				case 2: set_pev(iBoss, pev_ability, JUMP)
			}
			#else
			switch( pev(iBoss, pev_weaponanim) ) {
				case 0: { set_pev(iBoss, pev_ability, BOMB); set_pev(iBoss, pev_weaponanim, 1); }
				case 1: { set_pev(iBoss, pev_ability, HOLE); set_pev(iBoss, pev_weaponanim, 2); }
				case 2: { set_pev(iBoss, pev_ability, JUMP); set_pev(iBoss, pev_weaponanim, 0); }
			}
			#endif
			set_pev(iBoss, pev_num, 0)
		}
		set_pev(iBoss, pev_fuser1, get_gametime() + (Agr ? float(time_ability_agr) : float(time_ability)))
	}
	switch(pev(iBoss, pev_ability)) {
		case RUN: {
			new Float:Velocity[3], Float:Angle[3]
			static Target
			if (!is_user_alive(Target)) {
				Target = zl_player_random()
				set_pev(iActivityEnt, pev_nextthink, get_gametime() + 0.1)
				return
			}
			if (!pev(iBoss, pev_num)) {
				set_pev(iBoss, pev_num, 1)
				set_pev(iBoss, pev_movetype, MOVETYPE_PUSHSTEP)
				Anim(iBoss, Agr ? 8 : 1, 1.5)
			}
			#if defined NEW_SEARCH
			new Len, LenBuff = 99999
			for(new i = 1; i <= get_maxplayers(); i++) {
				if (!is_user_alive(i) || is_user_bot(i))
					continue

				Len = Move(iBoss, i, 500.0, Velocity, Angle)
				if (Len < LenBuff) {
					LenBuff = Len
					Target = i
				}
			}
			#endif
			for(new i = 1; i <= get_maxplayers(); i++)
			{
				if(is_user_alive(i) && entity_range(i, iBoss) <= 500.0)
				{
					message_begin(MSG_ONE, get_user_msgid("ScreenShake"),{0,0,0}, i)
					write_short(1<<14)
					write_short(1<<13)
					write_short(1<<13)
					message_end()
				}
			} 			
			Move(iBoss, Target, pev(g_Oberon, pev_button) ? float(speed_boss_agr) : float(speed_boss), Velocity, Angle)
			Velocity[2] = 0.0
			set_pev(iBoss, pev_velocity, Velocity)
			set_pev(iBoss, pev_angles, Angle)
			set_pev(iActivityEnt, pev_nextthink, get_gametime() + 0.1)
		}
		case ATTACK:{
			static randoms
			switch(pev(iBoss, pev_num)) {
				case 0: {
					randoms = random(2)
					set_pev(iBoss, pev_num, 1)
					set_pev(iBoss, pev_movetype, MOVETYPE_NONE)
					set_pev(iBoss, pev_velocity, Float:{0.0, 0.0, -0.1})
					if(Agr) {
						Sound(iBoss, random_num(5, 6))
						Anim(iBoss, randoms ? 9 : 10, 1.0)
						set_pev(iActivityEnt, pev_nextthink, get_gametime() + (randoms ? 0.6 : 0.3))
					} else {
						Sound(iBoss, randoms ? 2 : 3)
						Anim(iBoss, randoms ? 2 : 3, 1.0)
						set_pev(iActivityEnt, pev_nextthink, get_gametime() + (randoms ? 1.15 : 0.55))
					}
					return
				}
				case 1: {
					new Float:Velocity[3], Float:Angle[3], Len
					new victim = pev(iBoss, pev_victim)

					Len = Move(iBoss, victim, 2000.0, Velocity, Angle)
					if ( Len <= 330 ) {
						if (Agr) {
							AgrEff(0)
							boss_damage(victim, randoms ? dmg_attack_agr_max : dmg_attack_agr)
						} else {
							boss_damage(victim, randoms ? dmg_attack_max : dmg_attack)
						}
					}
				}
			}
			set_pev(iBoss, pev_num, 0)
			set_pev(iBoss, pev_ability, RUN)
			set_pev(iActivityEnt, pev_nextthink, get_gametime() + 1.3)
		}
		case BOMB: {
			static BombTarget[MAX_BOMB], Float:VectorB[3]
			static BombCount; BombCount = 14
			switch(pev(iBoss, pev_num)) {
				case 0: {
					set_pev(iBoss, pev_movetype, MOVETYPE_NONE)
					Anim(iBoss, Agr ? 12 : 5, 1.0)
					set_pev(iBoss, pev_num, 1)
					set_pev(iActivityEnt, pev_nextthink, get_gametime() + 3.2)
					set_pev(iBoss, pev_velocity, Float:{0.0, 0.0, -0.1})
					for (new i; i < BombCount; ++i) BombTarget[i] = zl_player_random()
					Sound(iBoss, 20)
				}
				case 1: {
					Sound(iBoss, 7)
					new Float:Origin[3]; pev(iBoss, pev_origin, Origin)
					Origin[2] += 45.0
					for (new i; i < BombCount; ++i) {
						new Bomb = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
						new Float:Origin2[3], Float:Angles[3]
						get_position(BombTarget[i], random_float(-50.0, -250.0), random_float(-100.0, 350.0), random_float(-900.0, 900.0), Origin2)
						g_Bomb[i] = Bomb
						engfunc(EngFunc_SetModel, Bomb, Resource[4])
						engfunc(EngFunc_SetOrigin, Bomb, Origin)
						engfunc(EngFunc_SetSize, Bomb, {-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
						set_pev(Bomb, pev_classname, "OberonBomb")
						set_pev(Bomb, pev_solid, SOLID_NOT)
						set_pev(Bomb, pev_gravity, 1.3)
						set_pev(Bomb, pev_movetype, MOVETYPE_NOCLIP)
						Anim(Bomb, 0, 3.0)

						xs_vec_sub(Origin2, Origin, VectorB)
						vector_to_angle(VectorB, Angles)
						xs_vec_normalize(VectorB, VectorB)
						Angles[0] = 0.0
						Angles[2] = 0.0
						VectorB[2] = 1.0
						xs_vec_mul_scalar(VectorB, 450.0, VectorB)
						set_pev(Bomb, pev_velocity, VectorB)
						set_pev(Bomb, pev_angles, Angles)
						set_pev(iBoss, pev_num, 2)
						set_pev(iActivityEnt, pev_nextthink, get_gametime() + 1.0)
					}
				}
				case 2: 
				{
					for (new i; i < BombCount; ++i) 
					{
						new Bomb = g_Bomb[i]
						set_pev(Bomb, pev_movetype, MOVETYPE_BOUNCE)
						set_pev(Bomb, pev_solid, SOLID_BBOX)

						VectorB[2] = 0.0
					}
					static num
					if (num >= 2) 
					{
						set_pev(iActivityEnt, pev_nextthink, get_gametime() + 1.5)
						set_pev(iBoss, pev_ability, RUN)
						set_pev(iBoss, pev_num, 0)
						num = 0
						return
					} 
					else 
						num++

					set_pev(iBoss, pev_num, 1)
					set_pev(iActivityEnt, pev_nextthink, get_gametime() + 1.8)
				}
			}
		}
		case HOLE: {
			new Float:Origin[3]; pev(iBoss, pev_origin, Origin)
			switch (pev(iBoss, pev_num)) {
				case 0: {
					set_pev(iBoss, pev_movetype, MOVETYPE_NONE)
					Origin[2] -= 35.0
					g_Hole = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
					engfunc(EngFunc_SetModel, g_Hole, Resource[6])
					engfunc(EngFunc_SetOrigin, g_Hole, Origin)

					Sound(iBoss, 8)

					Anim(iBoss, Agr ? 13 : 6, 0.9)
					Anim(g_Hole, 0, 0.9)
					set_pev(iActivityEnt, pev_nextthink, get_gametime() + 0.2)
					set_pev(iBoss, pev_num, 1)
				}
				case 1:
				{
					static Float:Angle[3], Float:Velocity[3], Len, num
					for(new id = 1; id <= get_maxplayers(); id++)
					{
						if (!is_user_alive(id) || is_user_bot(id))
							continue

						Len = Move(id, iBoss, 700.0, Velocity, Angle)
						if (Len < 1100) set_pev(id, pev_velocity, Velocity)
					}
					set_pev(iActivityEnt, pev_nextthink, get_gametime() + 0.3)
					if (num >= 18) {
						num = 0
						set_pev(iBoss, pev_num, 2)
						return
					}
					num++
				}
				case 2: {
					if (Agr) AgrEff(1)
					engfunc(EngFunc_RemoveEntity, g_Hole)
					static victim = -1
					while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 200.0)) != 0) {
						if(0 < victim <= get_maxplayers() && is_user_alive(victim)) {
							boss_damage(victim, pev(g_Oberon, pev_button) ? hole_dmg_agr : hole_dmg)
							client_cmd(victim, "drop")
						}
					}
					set_pev(iActivityEnt, pev_nextthink, get_gametime() + 1.0)
					set_pev(iBoss, pev_ability, RUN)
					set_pev(iBoss, pev_num, 0)
				}
			}
		}
		case JUMP: {
			static Float:Origin2[3], Float:Velocity[3]
			static Float:Origin[3]; pev(iBoss, pev_origin, Origin)
			new JumpTarget, Float:j_Origin[3], Float:j_Vector[3], Float:Len, Float:LenSubb
			switch (pev(iBoss, pev_num)) {
				case 0: {
					for(new s; s <= get_maxplayers(); s++) {
						if (!is_user_alive(s) || is_user_bot(s))
							continue

						pev(s, pev_origin, j_Origin)
						xs_vec_sub(j_Origin, Origin, j_Vector)
						Len = xs_vec_len(j_Vector)

						if (Len > LenSubb) {
							LenSubb = Len
							JumpTarget = s
						}
					}
					static Float:Angle[3]; pev(JumpTarget, pev_origin, Origin2)
					Move(iBoss, JumpTarget, 800.0, Velocity, Angle)
					set_pev(iBoss, pev_angles, Angle)				

					set_pev(iActivityEnt, pev_nextthink, get_gametime() + 0.5)
					set_pev(iBoss, pev_num, 1)
					Anim(iBoss, Agr ? 11 : 4, 1.0)
				}
				case 1: {					
					Sound(iBoss, 9)
					Velocity[2] = 1000.0
					set_pev(iBoss, pev_velocity, Velocity)						
					set_pev(iActivityEnt, pev_nextthink, get_gametime() + 1.0)
					set_pev(iBoss, pev_num, 2)
				}
				case 2: {
					xs_vec_sub(Origin2, Origin, Velocity)
					xs_vec_normalize(Velocity, Velocity)
					xs_vec_mul_scalar(Velocity, 900.0, Velocity)
					
					set_pev(iBoss, pev_velocity, Velocity)
					
					set_pev(iActivityEnt, pev_nextthink, get_gametime() + 0.8)
					set_pev(iBoss, pev_num, 3)
					set_pev(iBoss, pev_pre, 1)
				}
				case 3: {
					set_pev(iBoss, pev_velocity, Float:{0.0, 0.0, -0.1})
					Sound(iBoss, 4)
					set_pev(iBoss, pev_pre, 0)
					set_pev(iActivityEnt, pev_nextthink, get_gametime() + 1.6)
					set_pev(iBoss, pev_ability, RUN)
					set_pev(iBoss, pev_num, 0)
				}
			}
		}
		case AGRESS: {
			switch(pev(iBoss, pev_num)) {
				case 0: {
					set_pev(iBoss, pev_num, 1)
					set_pev(iBoss, pev_takedamage, DAMAGE_NO)
					set_pev(iBoss, pev_button, 3)
					set_pev(iBoss, pev_movetype, MOVETYPE_NONE)
					set_pev(iActivityEnt, pev_nextthink, get_gametime() + 8.6)
					Anim(iBoss, 15, 1.0)
					Sound(iBoss, 10)
				}
				case 1: {
					set_pev(iBoss, pev_takedamage, DAMAGE_YES)
					set_pev(iBoss, pev_button, 1)
					set_pev(iBoss, pev_ability, RUN)
					set_pev(iBoss, pev_num, 0)
					set_pev(iActivityEnt, pev_nextthink, get_gametime() + 0.1)
				}
			}
		}
	}
}

public AgrEff(hole) {
	new Float:OriginKnf[3]; pev(g_Oberon, pev_origin, OriginKnf)
	new Float:AnglesKnf[3]; pev(g_Oberon, pev_angles, AnglesKnf)
	new Eff = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, MONSTER_REFERANCE))
	OriginKnf[2] += 35.0
	engfunc(EngFunc_SetModel, Eff, Resource[7])
	engfunc(EngFunc_SetOrigin, Eff, OriginKnf)
	set_pev(Eff, pev_classname, "OberonKnife")
	set_pev(Eff, pev_angles, AnglesKnf)
	set_pev(Eff, pev_nextthink, get_gametime() + 0.3)
	set_rendering(Eff, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
	Anim(Eff, hole ? 2 : 1, 1.0)
}

public Think_Knife(Ent)
{
	if (!pev_valid(Ent))
		return

	static bool:num, fades
	if (!num)
	{
		num = true
		fades = 255
	}
	else
 	{
		if (fades > 5)
		{
			fades--
			set_rendering(Ent, kRenderFxNone, 0, 0, 0, kRenderTransAdd, fades)
		}
		else
		{
			num = false
			engfunc(EngFunc_RemoveEntity, Ent)
			return
		}
	}
	set_pev(Ent, pev_nextthink, get_gametime() + 0.003)
}

public Think_Health(Ent) {
	if (!pev_valid(g_Oberon)) {
		set_pev(Ent, pev_nextthink, get_gametime() + 0.5)
		return
	}

	static Float:frame, Float:hp; pev(g_Oberon, pev_health, hp)
	// static Float:Origin[3]; pev(g_Oberon, pev_origin, Origin)
	switch (pev(Ent, pev_num)) {
		case 0: {
			set_pev(Ent, pev_num, 1)
			set_pev(g_Oberon, pev_takedamage, DAMAGE_YES)
			set_pev(Ent, pev_effects, pev(Ent, pev_effects) & ~EF_NODRAW)
		}
		case 1: {
			frame = hp * 100.0 / g_MaxHp
			if (frame < 50 && pev(g_Oberon, pev_ability) == RUN && pev(g_Oberon, pev_button) == 0 && pev(Ent, pev_pre) == 0) {
				set_pev(g_Oberon, pev_ability, AGRESS)
				set_pev(g_Oberon, pev_num, 0)
				set_pev(Ent, pev_pre, 1)
			}
			// Origin[2] += 210.0
			// set_pev(Ent, pev_origin, Origin)
			set_pev(Ent, pev_frame, frame)
		}
	}
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
}

public Think_Timer(Ent) {
	if (!zl_player_alive()) {
		set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
		return
	}

	if (pev(g_Oberon, pev_deadflag) == DEAD_DYING)
		return

	static Counter
	switch(pev(Ent, pev_num)) 
	{
		case 0: 
		{ 
			Counter = prepare_time; 
			EventPrepare(); 
			set_pev(Ent, pev_num, 1); 
			set_pev(Ent, pev_fuser1, get_gametime() + (prepare_time + 30.0)); 
		}
		case 1: 
		{ 
			Counter --; 
			if(Counter > 0) client_print(0, print_center, "%L", LANG_PLAYER, "PREPARE_BATTLE",Counter)		
			if(Counter < 6) client_cmd(0, "spk city/other/%d", Counter)			
			if(Counter == 20) client_cmd(0, "mp3 play ^"sound/%s^"", SoundList[13])
			if(Counter <= 0) set_pev(Ent, pev_num, 2); 
		}
		case 2: 
		{ 
			Counter ++; 
		}
	}

	set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
	message_begin(MSG_ALL, get_user_msgid("RoundTime"))
	write_short(Counter)
	message_end()
}

public Touch_Boss_Use(Boss, Ent)
{
	force_use(Boss, Ent);
}

public Touch_Boss(Boss, Ent) {
	if (pev(Boss, pev_ability) == ATTACK)
		return

	if (pev(Boss, pev_ability) == JUMP && pev(Boss, pev_pre) == 1) {
		static victim =-1
		new Agr = pev(Ent, pev_button)

		new Float:Origin[3]; pev(Boss, pev_origin, Origin)
		ScreenShake(0, ((1<<12) * 8), ((2<<12) * 7))
		while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, (float(jump_distance) * 4))) != 0) {
			if (!is_user_alive(victim))
				continue

			boss_damage(victim, Agr ? jump_damage_agr : jump_damage)
		}
	}	

	if (pev(Boss, pev_ability) != RUN)
		return

	if (!is_user_alive(Ent))
		return

	set_pev(Boss, pev_victim, Ent)
	set_pev(Boss, pev_ability, ATTACK)
	set_pev(Boss, pev_num, 0)
}

public Touch_Bomb(Ent, Ent2) {
	new Sprite = 5, Float:Origin[3]; pev(Ent, pev_origin, Origin)
	Origin[2] += bomb_dist
	expl(Origin, 40, Sprite)
	engfunc(EngFunc_RemoveEntity, Ent)
}

public plugin_precache()
{
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );

	if( contain( szMapName, "zl_boss_oberon" ) == -1 )
		return;

	for (new i; i <= charsmax(Resource); i++)
		g_Resource[i] = precache_model(Resource[i])

	for(new e; e <= charsmax(SoundList); e++)
		precache_sound(SoundList[e])

	for(new i = 0 ; i < sizeof g_CountSound ; i++) 
	precache_sound(g_CountSound[i]);

	// g_iModelIndex = precache_model(fmt("models/player/%s/%s.mdl", playerModelOberon, playerModelOberon));
}

public plugin_cfg()
	config_load()

public Hook_TraceAttack(victim, attacker, Float:damage, Float:direction[3], th, dt) 
{
	if (zl_boss_valid(victim) != 1)
		return HAM_IGNORED

	if (pev(victim, pev_button) != 3)
		return HAM_IGNORED

	static Float:End[3]
	get_tr2(th, TR_vecEndPos, End)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, End[0])
	engfunc(EngFunc_WriteCoord, End[1])
	engfunc(EngFunc_WriteCoord, End[2])
	message_end()
	return HAM_IGNORED
}

@BossKilled(victim, attacker) {
// public Hook_Killed(victim, attacker, corpse) {
	if (!zl_boss_valid(victim))
		return HAM_IGNORED

	client_print(0, print_chat, "pev_deadflag %d", pev(victim, pev_deadflag));
	// if (pev(victim, pev_deadflag) == DEAD_DYING)
	// 	return HAM_IGNORED
		
	new szKillerName[32]
	get_user_name(attacker, szKillerName, 31)
	
	set_hudmessage(255, 255, 0, 0.12, 0.5, 0, 5.0, 5.0)
	ShowSyncHudMsg(0, g_MsgSync2, "%L", LANG_PLAYER, "OBERON_DEATH_KILLER", szKillerName,KILL_MONEY)

	Sound(victim, 12)
	Anim(victim, 16, 1.0)
	set_pev(victim, pev_solid, SOLID_SLIDEBOX)
	set_pev(victim, pev_velocity, {0.0, 0.0, 0.0})
	set_pev(victim, pev_deadflag, DEAD_DYING)
	zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + KILL_MONEY)	
	set_task(5.0, "change_map")
	client_cmd(0, "mp3 stop")
	set_task(2.0, "Victory")
	if (pev_valid(g_Hole)) engfunc(EngFunc_RemoveEntity, g_Hole)
	engfunc(EngFunc_RemoveEntity, hpbar)
	return HAM_SUPERCEDE
}

public Victory() client_cmd(0, "mp3 play ^"sound/%s^"", SoundList[15])

public Hook_BloodColor(Ent) {
	if (!zl_boss_valid(Ent))
		return HAM_IGNORED

	// SetHamReturnInteger(blood_color)
	SetHamReturnInteger(BLOOD_COLOR_RED)
	return HAM_SUPERCEDE
}

//public change_map()
//{
//	server_cmd("changelevel zm_dust_world")
//}

public change_map() {
	#if defined MAPCHOOSER
	zl_vote_start()
	#else
	server_cmd("changelevel ^"%s^"", boss_nextmap)
	#endif
}



public MapEvent() {
	e_boss = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, MONSTER_REFERANCE))
	set_pev(e_boss, pev_classname, "Timer")
	set_pev(e_boss, pev_nextthink, get_gametime() + 1.0)

	g_game_start = false
}

boss_damage(victim, damage) {
	// if (w	
}

config_load() {
	new path[64]
	get_localinfo("amxx_configsdir", path, charsmax(path))
	format(path, charsmax(path), "%s/zl/%s", path, FILE_SETTING)

	if (!file_exists(path)) {
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
		set_fail_state(error)
		return
	}

	new linedata[1024], key[64], value[960], section
	new file = fopen(path, "rt")

	while (file && !feof(file)) {
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")

		if (!linedata[0] || linedata[0] == '/') continue;
		if (linedata[0] == '[') { section++; continue; }

		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')
		trim(key)
		trim(value)

		switch (section) {
			case 1: {
				if (equal(key, "HEALTH"))
					boss_heal = str_to_num(value)
				else if (equal(key, "PREPARE"))
					prepare_time = str_to_num(value)
				else if (equal(key, "BLOOD_COLOR"))
					blood_color = str_to_num(value)
			}
			case 2: {
				if (equal(key, "NORMAL_SPEED"))
					speed_boss = str_to_num(value)
				else if (equal(key, "DMG_MAX"))
					dmg_attack_max = str_to_num(value)
				else if (equal(key, "DMG_NORMAL"))
					dmg_attack = str_to_num(value)
				else if (equal(key, "DMG_BOMB"))
					bomb_damage = str_to_num(value)
				else if (equal(key, "DMG_HOLE"))
					hole_dmg = str_to_num(value)
				else if (equal(key, "DMG_JUMP"))
					jump_damage = str_to_num(value)
				#if !defined MAPCHOOSER
				else if (equal(key, "NEXT_MAP"))
					copy(boss_nextmap, charsmax(boss_nextmap), value)
				#endif
				else if (equal(key, "DIST_JUMP"))
					jump_distance = str_to_num(value)
				else if (equal(key, "NTIME_ABILITY"))
					time_ability = str_to_num(value)
			}
			case 3: {
				if (equal(key, "AGR_SPEED"))
					speed_boss_agr = str_to_num(value)
				else if (equal(key, "AGR_DMG_MAX"))
					dmg_attack_agr_max = str_to_num(value)
				else if (equal(key, "AGR_DMG_NORMAL"))
					dmg_attack_agr = str_to_num(value)
				else if (equal(key, "AGR_DMG_BOMB"))
					bomb_damage_agr = str_to_num(value)
				else if (equal(key, "AGR_DMG_HOLE"))
					hole_dmg_agr = str_to_num(value)
				else if (equal(key, "AGR_DMG_JUMP"))
					jump_damage_agr = str_to_num(value)
				else if (equal(key, "ATIME_ABILITY"))
					time_ability_agr = str_to_num(value)
			}
			case 4: {
				if (equal(key, "BOMB_DIST"))
					bomb_dist = float(str_to_num(value))
			}
		}
	}
	if (file) fclose(file)
}

 /*========================
// STOCK
========================*/

stock Move(Start, End, Float:speed, Float:Velocity[], Float:Angles[]) {
	new Float:Origin[3], Float:Origin2[3], Float:Angle[3], Float:Vector[3], Float:Len
	pev(Start, pev_origin, Origin2)
	pev(End, pev_origin, Origin)
	xs_vec_sub(Origin, Origin2, Vector)
	Len = xs_vec_len(Vector)
	vector_to_angle(Vector, Angle)
	Angles[0] = 0.0
	Angles[1] = Angle[1]
	Angles[2] = 0.0
	xs_vec_normalize(Vector, Vector)
	xs_vec_mul_scalar(Vector, speed, Velocity)
	return floatround(Len, floatround_round)
}

stock Anim(ent, sequence, Float:speed) {
	set_pev(ent, pev_frame, 0.0);
	set_pev(ent, pev_sequence, sequence)
	set_pev(ent, pev_animtime, halflife_time())
	set_pev(ent, pev_framerate, speed)
}

stock get_position(id, Float:forw, Float:right, Float:up, Float:vStart[]) {
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]

	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_angles, vAngle) // if normal entity ,use pev_angles

	engfunc(EngFunc_AngleVectors, ANGLEVECTOR_FORWARD, vForward)
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)

	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
50, 5
expl(Float:Origin[3], scale19, SprIndex) {
	static victim = -1
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_Resource[SprIndex])
	write_byte(scale19)
	write_byte(20)
	write_byte(0)
	message_end()
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 200.0)) != 0) {
		if(is_user_alive(victim)) {
			static Agr; Agr = pev(victim, pev_button)
			boss_damage(victim, Agr ? bomb_damage_agr : bomb_damage)
		}
	}
}

stock ScreenShake_Box(id, amplitude, duration, frequency) {
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_ALL, get_user_msgid("ScreenShake"), _, id ? id : 0);
	write_short(amplitude)
	write_short(duration)
	write_short(frequency)
	message_end();
}

stock ScreenShake(id, duration, frequency) {
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_ALL, get_user_msgid("ScreenShake"), _, id ? id : 0);
	write_short(1<<14)
	write_short(duration)
	write_short(frequency)
	message_end();
}

stock Rock(Float:Origin[3], Size[3], Velocity[3], RandomVelocity, Num, Life, Flag) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, Origin[0]) // Pos.X
	engfunc(EngFunc_WriteCoord, Origin[1]) // Pos Y
	engfunc(EngFunc_WriteCoord, Origin[2]) // Pos.Z
	engfunc(EngFunc_WriteCoord, Size[0]) // Size X
	engfunc(EngFunc_WriteCoord, Size[1]) // Size Y
	engfunc(EngFunc_WriteCoord, Size[2]) // Size Z
	engfunc(EngFunc_WriteCoord, Velocity[0]) // Velocity X
	engfunc(EngFunc_WriteCoord, Velocity[1]) // Velocity Y
	engfunc(EngFunc_WriteCoord, Velocity[2]) // Velocity Z
	write_byte(RandomVelocity) // Random velocity
	write_short(g_Resource[10]) // Model/Sprite index
	write_byte(Num) // Num
	write_byte(Life) // Life
	write_byte(Flag) // Flags ( 0x01 )
	message_end()
}

stock Wreck(Float:Origin[3], Size[3], Velocity[3], RandomVelocity, Num, Life, Flag) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, Origin[0]) // Pos.X
	engfunc(EngFunc_WriteCoord, Origin[1]) // Pos Y
	engfunc(EngFunc_WriteCoord, Origin[2]) // Pos.Z
	engfunc(EngFunc_WriteCoord, Size[0]) // Size X
	engfunc(EngFunc_WriteCoord, Size[1]) // Size Y
	engfunc(EngFunc_WriteCoord, Size[2]) // Size Z
	engfunc(EngFunc_WriteCoord, Velocity[0]) // Velocity X
	engfunc(EngFunc_WriteCoord, Velocity[1]) // Velocity Y
	engfunc(EngFunc_WriteCoord, Velocity[2]) // Velocity Z
	write_byte(RandomVelocity) // Random velocity
	write_short(g_Resource[9]) // Model/Sprite index
	write_byte(Num) // Num
	write_byte(Life) // Life
	write_byte(Flag) // Flags ( 0x02 )
	message_end()
}

public zl_player_random() 
{
	new Index
	
	Index = GetRandomAlive(random_num(1, zl_player_alive()))
	
	return Index
}

public zl_player_alive() 
{
	new iAlive
	
	for (new id = 1; id <= get_maxplayers(); id++) 
		if (is_user_alive(id) && !is_user_bot(id)) 
			iAlive++
			
	return iAlive
}

public GetRandomAlive(target_index) 
{
	new iAlive
	
	for (new id = 1; id <= get_maxplayers(); id++) 
	{
		if (is_user_alive(id) && !is_user_bot(id)) 
			iAlive++
			
		if (iAlive == target_index) 
			return id
	}
	return -1
}

public zl_boss_valid(index) 
{
	new ClassName[32]
	pev(index, pev_classname, ClassName, charsmax(ClassName))

	if (equal(ClassName, "OberonBoss")) 
		return 1

	return 0
}
stock Sound(Ent, Sounds) engfunc(EngFunc_EmitSound, Ent, CHAN_STREAM, SoundList[_:Sounds], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
