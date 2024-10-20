#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < cstrike >
#include < hamsandwich >
#include < xs >
#include < color >
#include < dhudmessage >
#pragma tabsize 0

native set_user_health(id, val)

native zp_cs_get_user_money(id)
native zp_cs_set_user_money(id,value)

native zp_get_user_exp(id)
native zp_set_user_exp(id,value)
native zp_set_umm_start()

new g_MsgSync1
new g_MsgSync2

#define MESSAGE_SOUND	"zombus_cso/npc/msg.wav"
#define SPK_SOUND	"zombus_cso/npc/cnc_schedm.wav"

#define NAME		"[Boss] AlienBoss"
#define VERSION		"1.0"
#define AUTHOR		"heka"

#define PHOBOS_KILL_MONEY				30000
#define PHOBOS_KILL_EXP					30

#define PHOBOS_DMG_MONEY				500
#define PHOBOS_DAMAGE_REWARD			500

#define PHOBOS_HEALTH					500000.0

#define PHOSOS_DAMAGE_ATTACK			350.0
#define PHOBOS_DAMAGE_MAHADASH			1500.0
#define PHOBOS_DAMAGE_SHOCKWAVE_LOW		290.0
#define PHOBOS_DAMAGE_SHOCKWAVE_NORMAL	850.0
#define PHOBOS_DAMAGE_SHOCKWAVE_HIGH	1500.0

#define PHOBOS_ANIM_RUN					4
#define PHOBOS_ANIM_SWING				6
#define PHOBOS_ANIM_SHOCKWAVE			5
#define PHOBOS_ANIM_DUSH				7
#define PHOBOS_ANIN_DEATH				1

#define PHOBOS_SOUND_SWING				"zombus_cso/npc/alienboss/swing.wav"
#define PHOBOS_SOUND_DUSH				"zombus_cso/npc/alienboss/voice2.wav"
#define PHOBOS_SOUND_VOICE				"zombus_cso/npc/alienboss/voice.wav"
#define PHOBOS_SOUND_DEATH				"zombus_cso/npc/alienboss/death.wav"
#define PHOBOS_SOUND_SHOCKWAVE			"zombus_cso/npc/alienboss/shokwave.wav"
#define PHOBOS_SOUND_FOOTSTEP1			"zombus_cso/npc/alienboss/footstep_1.wav"
#define PHOBOS_SOUND_FOOTSTEP2			"zombus_cso/npc/alienboss/footstep_2.wav"
#define PHOBOS_SOUND_FLUXING			"zombus_cso/npc/alienboss/pull_cast.wav"
#define PHOBOS_SOUND_REFLECTION			"zombus_cso/npc/alienboss/distortion.wav"

#define PHOBOS_HEALTH_SPRITE			"sprites/zombus_cso/phoboshp.spr"

static Float:Origin[3]

static g_Alien
static g_Death
new HPspr
static VictimID
static Float:g_Health
static phase
static Ability
new bool:GameStart
new bool:RoundEnd

new const Resource[][] =
{
	"models/zombus_cso/npc/alienboss2.mdl",
	"sprites/zombus_cso/blood.spr",
	"sprites/zombus_cso/bloodspray.spr",
	"sprites/zombus_cso/white.spr",
	"sprites/zombus_cso/fluxing.spr"
}
static g_Resource[sizeof Resource]

new const SoundList[][] =
{
	"zombus_cso/npc/zombie_scenario_ready.mp3",
	"zombus_cso/npc/scenario_rush.mp3",
	"zombus_cso/npc/aftermatch.mp3"
}

static bool:one, Float:g_step[512]
enum
{
	WALK,
	MS,
	ATTACK,
	FLUXING,
	HOOK,
	SHOCKWAVE_LOW,
	SHOCKWAVE_NORMAL,
	SHOCKWAVE_HIGH,
	REFLECTION
}

new const gClassname[] = "KillBox"
new const gModel[] = "models/zombus_cso/npc/supplybox_zbs.mdl"

new iPlayerTouch[33]
new iPlayerTouchFix[33][999]

native zp_stats_getdata(id, iData)
native zp_stats_setdata(id, iData, iNum)
new g_countdown
public plugin_init() 
{
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );

	if( contain( szMapName, "zp_boss_city" ) == -1 )
		return;

	register_plugin(NAME, VERSION, AUTHOR)

	register_think("AlienBoss", "Think_Boss")
	register_think("HP", "Think_HP")
	
	register_touch("AlienBoss", "*", "Touch_Boss")
	register_touch(gClassname, "player", "BoxTouch")

	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")

	RegisterHam(Ham_TakeDamage, "info_target", "TakeDamage")
	RegisterHam(Ham_TraceAttack, "info_target", "TraceAttack")

	register_dictionary("zp_alienboss.txt")

	g_MsgSync1 = CreateHudSyncObj()
	g_MsgSync2 = CreateHudSyncObj()

	RoundEnd = false
	set_task(5.0, "spawn")
	g_countdown = 30
}

public force_team(id)
{
	engclient_cmd(id, "jointeam", "2", "3")
}

public event_round_start()
{
	if(RoundEnd) 
		zp_set_umm_start()

	remove_entity_name("AlienBoss")
	remove_entity_name("HP")
	remove_task(1337)
}

public countdown()
{
	if(!g_countdown)
	{
		remove_task(4441223)
		return
	}
	new sound[32]

	client_print(0, print_center, "%L", LANG_PLAYER, "PREPARE_BATTLE", g_countdown)
	
	if(g_countdown <= 5)
	{
		format(sound, 31, "zombus_cso/countdown/%d.wav", g_countdown)
		
		client_cmd(0, "spk ^"%s^"", sound)
	}

	if(g_countdown == 21)
	{
		format(sound, 31, "zombus_cso/countdown/20.wav")
		
		client_cmd(0, "spk ^"%s^"", sound)
	}
	
	if(g_countdown == 20)
	{
		client_cmd(0, "mp3 play ^"sound/%s^"", SoundList[0])
	}

	if(g_countdown == 1)
	{
		client_print(0, print_center, "%L", LANG_PLAYER, "START_BATTLE")
		client_cmd(0, "mp3 play ^"sound/%s^"", SoundList[1])
		
		set_dhudmessage(255, 255, 0, -1.0, 0.0, 1, 6.0, 10000.0)
		show_dhudmessage(0, "%L", LANG_PLAYER, "BONUS_HUD")
	}
	
	g_countdown--
}


public logevent_round_end(ent) 
{	
	RoundEnd = true
}

public RandomAbility(taskid)
{
	if (Ability != WALK)
		return

	switch(phase)
	{
		case 1:
		{
			switch(random_num(0, 1))
			{
				case 0: Ability = SHOCKWAVE_LOW
				case 1: Ability = FLUXING
			}			
		}
		case 2:
		{
			switch(random_num(0, 2))
			{
				case 0: Ability = SHOCKWAVE_LOW
				case 1: Ability = SHOCKWAVE_NORMAL
				case 2: Ability = FLUXING
			}
		}
		case 3:
		{
			switch(random_num(0, 5))
			{
				case 0: Ability = SHOCKWAVE_LOW
				case 1: Ability = SHOCKWAVE_NORMAL
				case 2: Ability = SHOCKWAVE_HIGH
				case 3: Ability = MS
				case 4: Ability = FLUXING
				case 5: Ability = REFLECTION
			}
		}
	}
}

public spawn() 
{
	g_Alien = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	HPspr = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))

	engfunc(EngFunc_SetModel, g_Alien, Resource[0])
	engfunc(EngFunc_SetSize, g_Alien, { -16.0, -16.0, -36.0 }, { 16.0, 16.0, 90.0 })
	/*Origin[0] = -2494.0
	Origin[1] = -1755.0
	Origin[2] = -1538.0*/

	Origin[0] = -27.0
	Origin[1] = 24.0
	Origin[2] = 460.0

	//Origin[1] += 50.0
	
	engfunc(EngFunc_SetOrigin, g_Alien, Origin)

	set_pev(g_Alien, pev_classname, "AlienBoss")
	set_pev(g_Alien, pev_solid, SOLID_BBOX)
	set_pev(g_Alien, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(g_Alien, pev_takedamage, DAMAGE_NO)
	set_pev(g_Alien, pev_health, PHOBOS_HEALTH)
	set_pev(g_Alien, pev_deadflag, DEAD_NO)
	set_pev(g_Alien, pev_gravity, 10.0)
	set_pev(g_Alien, pev_nextthink, get_gametime() + 30.0)

	g_step[g_Alien] = 0.0

	Anim(g_Alien, 2)
	Ability = FLUXING

	one = true
	GameStart = false

	set_task(1.0, "countdown", 4441223, _, _, "b")
	set_task(40.0, "RandomAbility", 1337, _, _, "b")
	set_task(30.0, "AlienBoss_Start")
}

public AlienBoss_Start() 
{
	set_pev(g_Alien, pev_takedamage, DAMAGE_YES)
	
	phase = 1
	Color(0,print_chat,"!g[ZP] %L!", LANG_PLAYER, "ALIEN_PHASE", phase)
	
	Origin[2] += 300.0
	pev(g_Alien, pev_origin, Origin)
	engfunc(EngFunc_SetOrigin, HPspr, Origin)
	engfunc(EngFunc_SetModel, HPspr, PHOBOS_HEALTH_SPRITE)
	entity_set_float(HPspr, EV_FL_scale, 0.6)
	set_pev(HPspr, pev_classname, "HP")
	set_pev(HPspr, pev_solid, SOLID_NOT)
	set_pev(HPspr, pev_movetype, MOVETYPE_NOCLIP)
	set_pev(HPspr, pev_frame, 100.0)
	set_pev(HPspr, pev_nextthink, get_gametime())
	
	GameStart = true
}

public client_putinserver(id)
{
	if(GameStart) set_pdata_int(id, 365, 1)
}

public Think_Boss(Ent) 
{
	if(g_Death)
		return

	if(pev(Ent, pev_health)  <= PHOBOS_HEALTH / 2.0 && phase == 1)
	{
		phase = 2
		Color(0,print_chat,"!g[ZP] %L!", LANG_PLAYER, "ALIEN_PHASE", phase)
		Light(Ent, 1, 80, 80, {27, 141, 35})
	}
	if(pev(Ent, pev_health)  <= PHOBOS_HEALTH / 4.0 && phase == 2)
	{
		phase = 3
		Color(0,print_chat,"!g[ZP] %L!", LANG_PLAYER, "ALIEN_PHASE", phase)
		Light(Ent, 1, 80, 80, {255, 0, 0})
	}

	switch ( Ability ) {
		case WALK: {
			new Float:Velocity[3], Float:Angle[3]
			static Target
			if (!is_user_alive(Target)) {
				Target = GetRandomAlive(random_num(1, GetAliveCount()))
				set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
				return
			}
			if (one) {
				set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
				Anim(Ent, PHOBOS_ANIM_RUN)
				one = false
			}
			new Len, LenBuff = 99999
			for(new i = 1; i <= get_maxplayers(); i++) {
				if (!is_user_alive(i) || is_user_bot(i))
					continue

				Len = Move(Ent, i, 500.0, Velocity, Angle)
				if (Len < LenBuff) {
					LenBuff = Len
					Target = i
				}
			}
			for(new i = 1; i < get_maxplayers(); i++)
			{
				if(is_user_alive(i) && entity_range(i, Ent) <= 500.0)
				{
					message_begin(MSG_ONE, get_user_msgid("ScreenShake"),{0,0,0}, i)
					write_short(1<<14)
					write_short(1<<13)
					write_short(1<<13)
					message_end()
				}
			}
			set_rendering(Ent)
			Move(Ent, Target, 320.0, Velocity, Angle)
			Velocity[2] = 0.0
			set_pev(Ent, pev_velocity, Velocity)
			set_pev(Ent, pev_angles, Angle)
			set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
		}
		case ATTACK: {
			static num
			switch (num) {
				case 0: {
					set_pev(Ent, pev_velocity, Float:{0.0, 0.0, -0.1})
					Anim(Ent, PHOBOS_ANIM_SWING)
					num++
					set_pev(Ent, pev_nextthink, get_gametime() + 0.2)
					PlaySound(0, PHOBOS_SOUND_SWING)
					return
				}
				case 1: {
					static Float:OriginA[3], Float:OriginA2[3], Float:LenA, Float:Vector[3], Float:Velocity[3]

					pev(g_Alien, pev_origin, OriginA)
					pev(VictimID, pev_origin, OriginA2)

					xs_vec_sub(OriginA2, OriginA, Velocity)
					xs_vec_sub(OriginA, OriginA2, Vector)

					LenA = xs_vec_len(Vector)

					if (LenA <= 400)
					{
						//ExecuteHamB(Ham_TakeDamage, VictimID, 0, VictimID, PHOSOS_DAMAGE_ATTACK, DMG_BLAST)
						boss_damage(VictimID, PHOSOS_DAMAGE_ATTACK)
						ScreenShake(VictimID)
						ScreenFade(VictimID, 3, {255, 0, 0}, 120)
					}
				}
			}
			num = 0
			one = true
			Ability = WALK
			set_pev(Ent, pev_nextthink, get_gametime() + 1.2)
		}
		case MS: {
			static num, Float:Origin[3], Float:Origin2[3], Float:Vector[3], Float:Angle[3]
			switch ( num ) {
				case 0: {
					new MS_Attack = GetRandomAlive(random_num(1, GetAliveCount()))

					pev(MS_Attack, pev_origin, Origin)
					pev(Ent, pev_origin, Origin2)

					set_pev(g_Alien, pev_gravity, 1.0)

					xs_vec_sub(Origin, Origin2, Vector)
					vector_to_angle(Vector, Angle)
					xs_vec_normalize(Vector, Vector)
					xs_vec_mul_scalar(Vector, 1200.0, Vector)
					Angle[0] = 0.0
					Angle[2] = 0.0
					Vector[2] = 0.0
					set_pev(Ent, pev_angles, Angle)
					set_pev(Ent, pev_movetype, MOVETYPE_NONE)
					Anim(Ent, PHOBOS_ANIM_DUSH)
					set_pev(Ent, pev_nextthink, get_gametime() + 1.0)
					PlaySound(0, PHOBOS_SOUND_DUSH)
					num++
					return
				}
				case 1: {
					set_pev(Ent, pev_movetype, MOVETYPE_FLY)
					set_pev(Ent, pev_velocity, Vector)
					set_pev(Ent, pev_nextthink, get_gametime() + 0.7)

					num++
					return
				}
			}
			set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
			num = 0
			Ability = WALK
			one = true
			return
		}
		case REFLECTION:
		{
			static num
			switch ( num ) 
			{
				case 0: 
				{
					Anim(Ent, 2)
					set_rendering(Ent, kRenderFxGlowShell, 255, 0, 255, kRenderNormal, 30)
					Light(Ent, 1, 80, 80, {255, 0, 255})
				
					PlaySound(0, PHOBOS_SOUND_REFLECTION)
					
					set_pev(Ent, pev_nextthink, get_gametime() + 15.0)
					
					num++
					return
				}
				case 1: 
				{
					set_rendering(Ent)
	
					Ability = WALK
	
					one = true
					num = 0
					set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
					return
				}
			}
		}		
		case FLUXING:
		{
			static num, FluxSpr, Float:Origin[3]
			switch ( num ) {
				case 0: {
					Anim(Ent, 2)
					FluxSpr = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
					pev(Ent, pev_origin, Origin)
					Origin[2] += 70
					engfunc(EngFunc_SetOrigin, FluxSpr, Origin)
					engfunc(EngFunc_SetModel, FluxSpr, Resource[4])
					set_pev(FluxSpr, pev_solid, SOLID_NOT)
					set_pev(FluxSpr, pev_movetype, MOVETYPE_NOCLIP)
					set_rendering(FluxSpr, kRenderFxFadeSlow, 255, 255, 255, kRenderTransAdd, 255)
					set_rendering(Ent, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 30)
					set_pev(FluxSpr, pev_framerate, 5.0)
					dllfunc(DLLFunc_Spawn, FluxSpr)
					PlaySound(0, PHOBOS_SOUND_FLUXING)
					set_pev(Ent, pev_nextthink, get_gametime() + 0.2)
					num++
					return
				}
				case 1..9: {
					static Float:originF[3],  victim = -1;
					pev(Ent, pev_origin, originF);

					while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, 1000.0)) != 0)
					{
						if (!is_user_alive(victim))
							continue;

						new Float:fl_Velocity[3];
						new vicOrigin[3], originN[3];

						get_user_origin(victim, vicOrigin);
						originN[0] = floatround(originF[0]);
						originN[1] = floatround(originF[1]);
						originN[2] = floatround(originF[2]);

						new distance = get_distance(originN, vicOrigin);

						if (distance > 1)
						{
							new Float:fl_Time = distance / 900.0;

							fl_Velocity[0] = (originN[0] - vicOrigin[0]) / fl_Time;
							fl_Velocity[1] = (originN[1] - vicOrigin[1]) / fl_Time;
							fl_Velocity[2] = (originN[2] - vicOrigin[2]) / fl_Time;
						}
						else
						{
							fl_Velocity[0] = 0.0
							fl_Velocity[1] = 0.0
							fl_Velocity[2] = 0.0
						}

						entity_set_vector(victim, EV_VEC_velocity, fl_Velocity);
					}

					set_pev(Ent, pev_nextthink, get_gametime() + 0.2)
					num++
					return
				}
				case 10: {
					engfunc(EngFunc_RemoveEntity, FluxSpr)
					set_rendering(Ent)
					switch(phase)
					{
						case 1:
						{
							switch(random_num(0, 1))
							{
								case 0: Ability = ATTACK
								case 1: Ability = SHOCKWAVE_LOW
							}
						}
						case 2:
						{
							switch(random_num(0, 2))
							{
								case 0: Ability = ATTACK
								case 1: Ability = SHOCKWAVE_LOW
								case 2: Ability = SHOCKWAVE_NORMAL
							}
						}
						case 3:
						{
							switch(random_num(0, 3))
							{
								case 0: Ability = ATTACK
								case 1: Ability = SHOCKWAVE_LOW
								case 2: Ability = SHOCKWAVE_NORMAL
								case 3: Ability = SHOCKWAVE_HIGH
							}
						}
					}
					one = true
					num = 0
					set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
					return
				}
			}
		}
		case HOOK:
		{
			static num
			switch ( num ) {
				case 0: {
					Anim(Ent, 2)
					set_rendering(Ent, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 30)
					PlaySound(0, PHOBOS_SOUND_FLUXING)
					set_pev(Ent, pev_nextthink, get_gametime() + 0.2)
					num++
					return
				}
				case 1..9: {
					static Float:originF[3],  victim = -1;
					pev(Ent, pev_origin, originF);

					while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, 1000.0)) != 0)
					{
						if (!is_user_alive(victim))
							continue;

						new Float:fl_Velocity[3];
						new vicOrigin[3], originN[3];

						get_user_origin(victim, vicOrigin);
						originN[0] = floatround(originF[0]);
						originN[1] = floatround(originF[1]);
						originN[2] = floatround(originF[2]);

						new distance = get_distance(originN, vicOrigin);

						if (distance > 1)
						{
							new Float:fl_Time = distance / 900.0;

							fl_Velocity[0] = (originN[0] - vicOrigin[0]) / fl_Time;
							fl_Velocity[1] = (originN[1] - vicOrigin[1]) / fl_Time;
							fl_Velocity[2] = (originN[2] - vicOrigin[2]) / fl_Time;
						}
						else
						{
							fl_Velocity[0] = 0.0
							fl_Velocity[1] = 0.0
							fl_Velocity[2] = 0.0
						}

						entity_set_vector(victim, EV_VEC_velocity, fl_Velocity);
					}

					set_pev(Ent, pev_nextthink, get_gametime() + 0.2)
					num++
					return
				}
				case 10: {
					set_rendering(Ent)
					switch(phase)
					{
						case 1:
						{
							switch(random_num(0, 1))
							{
								case 0: Ability = ATTACK
								case 1: Ability = SHOCKWAVE_LOW
							}
						}
						case 2:
						{
							switch(random_num(0, 2))
							{
								case 0: Ability = ATTACK
								case 1: Ability = SHOCKWAVE_LOW
								case 2: Ability = SHOCKWAVE_NORMAL
							}
						}
						case 3:
						{
							switch(random_num(0, 4))
							{
								case 0: Ability = ATTACK
								case 1: Ability = SHOCKWAVE_LOW
								case 2: Ability = SHOCKWAVE_NORMAL
								case 3: Ability = SHOCKWAVE_HIGH
								case 4: Ability = MS
							}
						}
					}
					one = true
					num = 0
					set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
					return
				}
			}
		}
		case SHOCKWAVE_LOW: {
			static num
			switch ( num ) {
				case 0: {
					set_pev(Ent, pev_velocity, Float:{0.0, 0.0, -0.1})
					Anim(Ent, PHOBOS_ANIM_SHOCKWAVE)
					PlaySound(0, PHOBOS_SOUND_VOICE)
					set_pev(Ent, pev_nextthink, get_gametime() + 2.2)
					num++
					return
				}
				case 1: {
					static Float:Orig[3]
					pev(Ent, pev_origin, Orig)

					ShockWave(Orig, 750.0, {174, 87, 0}) // 450
					PlaySound(0, PHOBOS_SOUND_SHOCKWAVE)

					for(new id = 1; id <= get_maxplayers(); id++)
					{
						if (!is_user_alive(id))
							continue

						if (~pev(id, pev_flags) & FL_ONGROUND)
         						continue

						static Float:gOrigin[3], Float:Vec[3], Float:Len
						pev(id, pev_origin, gOrigin)
						xs_vec_sub(Orig, gOrigin, Vec)
						Len = xs_vec_len(Vec)
						if (Len <= 550.0)
						{
							//ExecuteHamB(Ham_TakeDamage, id, 0, id, PHOBOS_DAMAGE_SHOCKWAVE_LOW, DMG_BLAST)
							boss_damage(id, PHOBOS_DAMAGE_SHOCKWAVE_LOW)
							ScreenFade(id, 3, {174, 87, 0}, 120)
							client_cmd(id, "drop")
							ScreenShake(id)
						}
					}
					Ability = WALK
					one = true
					num = 0
					set_pev(Ent, pev_nextthink, get_gametime() + 0.6)
					return
				}
			}
		}
		case SHOCKWAVE_NORMAL: {
			static num
			switch ( num ) {
				case 0: {
					set_pev(Ent, pev_velocity, Float:{0.0, 0.0, -0.1})
					Anim(Ent, PHOBOS_ANIM_SHOCKWAVE)
					PlaySound(0, PHOBOS_SOUND_VOICE)
					set_rendering(Ent, kRenderFxGlowShell, 27, 141, 35, kRenderNormal, 30)
					set_pev(Ent, pev_nextthink, get_gametime() + 2.2)
					num++
					return
				}
				case 1: {
					static Float:Orig[3]
					pev(Ent, pev_origin, Orig)

					ShockWave(Orig, 950.0, {27, 141, 35}) // 450
					PlaySound(0, PHOBOS_SOUND_SHOCKWAVE)

					for(new id = 1; id <= get_maxplayers(); id++) {
						if (!is_user_alive(id))
							continue

						if (~pev(id, pev_flags) & FL_ONGROUND)
         						continue

						static Float:gOrigin[3], Float:Vec[3], Float:Len
						pev(id, pev_origin, gOrigin)
						xs_vec_sub(Orig, gOrigin, Vec)
						Len = xs_vec_len(Vec)
						if (Len <= 800.0)
						{
							//ExecuteHamB(Ham_TakeDamage, id, 0, id, PHOBOS_DAMAGE_SHOCKWAVE_NORMAL, DMG_BLAST)
							boss_damage(id, PHOBOS_DAMAGE_SHOCKWAVE_NORMAL)
							client_cmd(id, "drop")
							ScreenShake(id)
							ScreenFade(id, 3, {27, 141, 35}, 120)
						}
					}
					Ability = WALK
					one = true
					num = 0
					set_pev(Ent, pev_nextthink, get_gametime() + 0.6)
					return
				}
			}
		}
		case SHOCKWAVE_HIGH: {
			static num
			switch ( num ) {
				case 0: {
					set_pev(Ent, pev_velocity, Float:{0.0, 0.0, -0.1})
					Anim(Ent, PHOBOS_ANIM_SHOCKWAVE)
					PlaySound(0, PHOBOS_SOUND_VOICE)
					set_rendering(Ent, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 30)
					set_pev(Ent, pev_nextthink, get_gametime() + 2.2)
					num++
					return
				}
				case 1: {
					static Float:Orig[3]
					pev(Ent, pev_origin, Orig)

					ShockWave(Orig, 1650.0, {255, 0, 0}) // 450
					PlaySound(0, PHOBOS_SOUND_SHOCKWAVE)

					for(new id = 1; id <= get_maxplayers(); id++)
					{
						if (!is_user_alive(id))
							continue

						if (~pev(id, pev_flags) & FL_ONGROUND)
         						continue

						static Float:gOrigin[3], Float:Vec[3], Float:Len
						pev(id, pev_origin, gOrigin)
						xs_vec_sub(Orig, gOrigin, Vec)
						Len = xs_vec_len(Vec)
						if (Len <= 1400.0)
						{
							//ExecuteHamB(Ham_TakeDamage, id, 0, id, PHOBOS_DAMAGE_SHOCKWAVE_HIGH, DMG_BLAST)
							boss_damage(id, PHOBOS_DAMAGE_MAHADASH)
							client_cmd(id, "drop")
							ScreenShake(id)
							ScreenFade(id, 3, {255, 0, 0}, 120)
						}
					}
					Ability = WALK
					one = true
					num = 0
					set_pev(Ent, pev_nextthink, get_gametime() + 0.6)
					return
				}
			}
		}
	}
}

public Think_HP(Ent)
 {
	static Float:Origin[3]
	pev(g_Alien, pev_origin, Origin)

	Origin[2] += 300.0
	set_pev(Ent, pev_origin, Origin)

	static Float:frame
	frame = g_Health * 100.0 / PHOBOS_HEALTH

	if (frame)
		set_pev(Ent, pev_frame, frame)

	if(g_Death)
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return
	}
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
}

public TraceAttack(victim, attacker, Float:damage, Float:direction[3], th, dt) {
	static Float:End[3], ClassName[32]
	pev(victim, pev_classname, ClassName, charsmax(ClassName))
	if (equal(ClassName, "AlienBoss")) {
		get_tr2(th, TR_vecEndPos, End)
		Blood(End)
	}
}

public TakeDamage(victim, weapon, attacker, Float:damage, damagetype) {
	static ClassName[32], Float:dmg_buffer[33]
	pev(victim, pev_classname, ClassName, charsmax(ClassName))
	if (equal(ClassName, "AlienBoss"))
	{
		if(Ability == REFLECTION)
		{
			if(pev(attacker, pev_health)  - damage <= 0)
				user_kill(attacker, 1)
			else
				set_pev(attacker, pev_health, pev(attacker, pev_health) - damage)	
		}
		
		pev(victim, pev_health, g_Health)
		if (g_Health <= damage)
		{
			set_pev(victim, pev_velocity, Float:{0.0, 0.0, -0.1})
			Anim(victim, PHOBOS_ANIN_DEATH)
			PlaySound(0, PHOBOS_SOUND_DEATH)
			set_pev(victim, pev_movetype, MOVETYPE_FLY)
			set_pev(victim, pev_solid, SOLID_NOT)
			set_pev(victim, pev_velocity, {0.0, 0.0, 0.0})

			g_Death = victim
			//set_pev(victim, pev_deadflag, DEAD_DYING)

			zp_cs_set_user_money(attacker, zp_cs_get_user_money(attacker) + PHOBOS_KILL_MONEY)
			zp_set_user_exp(attacker, zp_get_user_exp(attacker) + PHOBOS_KILL_EXP)

			zp_stats_setdata(attacker, 8, zp_stats_getdata(attacker, 8) + 1)

			new szKillerName[32]
			get_user_name(attacker, szKillerName, 31)

			set_hudmessage(255, 255, 0, 0.12, 0.5, 0, 5.0, 5.0)
			ShowSyncHudMsg(0, g_MsgSync2, "%L", LANG_PLAYER, "ALIEN_DEATH_KILLER", szKillerName, PHOBOS_KILL_EXP,PHOBOS_KILL_MONEY)

			Color(0,print_chat,"!g[ZP] %L", LANG_PLAYER, "ALIEN_DEATH")

			client_cmd(0, "mp3 stop")
			client_cmd(0, "mp3 play ^"sound/%s^"", SoundList[2])

			remove_task(1337)

			SpawnBox()
			set_task(15.0, "UmmStart", 100500)

			zp_set_umm_start()
			return HAM_SUPERCEDE
		}
		if(g_Health >= damage)
		{
			dmg_buffer[attacker] += damage
			if(dmg_buffer[attacker] >= PHOBOS_DAMAGE_REWARD)
			{
				dmg_buffer[attacker] = 0.0
				zp_cs_set_user_money(attacker, zp_cs_get_user_money(attacker) + PHOBOS_DMG_MONEY)
			}
		}
	}
	return HAM_HANDLED
}

public Touch_Boss(Ent, WorldEnt)
{
	static ClassName[32];
	pev(WorldEnt, pev_classname, ClassName, charsmax(ClassName))

	if(equal(ClassName, "player")) 
	{
		if (Ability == MS) 
		{
			static victim = -1, Float:Origin[3]
			pev(Ent, pev_origin, Origin)
			while((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, 300.0)) != 0)
	 		{
				if (!is_user_alive(victim))
					continue
	
				//ExecuteHamB(Ham_TakeDamage, victim, 0, victim, PHOBOS_DAMAGE_MAHADASH, DMG_BLAST)
				boss_damage(victim, PHOBOS_DAMAGE_MAHADASH)
				ScreenFade(victim, 3, {255, 0, 0} ,120)
			}
		}
	
		if (Ability == WALK) 
		{
			Ability = ATTACK
			VictimID = WorldEnt
		}
	}
	if(equal(ClassName, "func_breakable")) {		
		force_use(Ent, WorldEnt);
	}
}

boss_damage(victim, Float:damage)
{
	if (pev(victim, pev_health) - damage <= 0) 
		ExecuteHamB(Ham_Killed, victim, victim, 1)
	else 
		ExecuteHamB(Ham_TakeDamage, victim, 0, victim, damage, DMG_BLAST)
}

public plugin_precache() {
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );

	if( contain( szMapName, "zp_boss_city" ) == -1 )
		return;

	for(new i; i <= charsmax(Resource); i++)
		g_Resource[i] = precache_model(Resource[i])

	for(new e; e <= charsmax(SoundList); e++)
		precache_sound(SoundList[e])

	precache_sound(MESSAGE_SOUND)
	precache_sound(PHOBOS_SOUND_SWING)
	precache_sound(PHOBOS_SOUND_DUSH)
	precache_sound(PHOBOS_SOUND_VOICE)
	precache_sound(PHOBOS_SOUND_DEATH)
	precache_sound(PHOBOS_SOUND_SHOCKWAVE)
	precache_sound(PHOBOS_SOUND_FOOTSTEP1)
	precache_sound(PHOBOS_SOUND_FOOTSTEP2)
	precache_model(PHOBOS_HEALTH_SPRITE)
	precache_sound(PHOBOS_SOUND_REFLECTION)
	precache_model( gModel )
}

stock Blood(Float:Orig[3]) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, Orig[0])
	engfunc(EngFunc_WriteCoord, Orig[1])
	engfunc(EngFunc_WriteCoord, Orig[2])
	write_short(g_Resource[1])
	write_short(g_Resource[2])
	write_byte(218)
	write_byte(random_num(1, 2))
	message_end();
}

stock Anim(ent, sequence)
{
	set_pev(ent, pev_sequence, sequence)
	set_pev(ent, pev_animtime, halflife_time())
	set_pev(ent, pev_framerate, 1.0)
}

stock ShockWave(Float:Orig[3], Float:Radius, Color[3]) {
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Orig, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, Orig[0]) // x
	engfunc(EngFunc_WriteCoord, Orig[1]) // y
	engfunc(EngFunc_WriteCoord, Orig[2]-24.0) // z
	engfunc(EngFunc_WriteCoord, Orig[0]) // x axis
	engfunc(EngFunc_WriteCoord, Orig[1]) // y axis
	engfunc(EngFunc_WriteCoord, Orig[2]+Radius) // z axis
	write_short(g_Resource[3]) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(5) // life (4)
	write_byte(30) // width (20)
	write_byte(0) // noise
	write_byte(Color[0]) // red
	write_byte(Color[1]) // green
	write_byte(Color[2]) // blue
	write_byte(255) // brightness
	write_byte(0) // speed
	message_end()
}

stock ScreenShake(id) {
	message_begin(MSG_ONE, get_user_msgid("ScreenShake"),{0,0,0}, id)
	write_short(1<<14)
	write_short(1<<13)
	write_short(1<<13)
	message_end()
}

stock ScreenFade(id, Timer, Colors[3], Alpha) {
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
	write_short((1<<12) * Timer)
	write_short(1<<12)
	write_short(0)
	write_byte(Colors[0])
	write_byte(Colors[1])
	write_byte(Colors[2])
	write_byte(Alpha)
	message_end()
}

GetRandomAlive(target_index) {			// :3
	new iAlive
	for (new id = 1; id <= get_maxplayers(); id++) {
		if (is_user_alive(id)) iAlive++
		if (iAlive == target_index) return id
	}
	return -1
}

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

GetAliveCount() {				// ^^
	new iAlive
	for (new id = 1; id <= get_maxplayers(); id++) if (is_user_alive(id)) iAlive++
	return iAlive
}

PlaySound(id, const sound[])
{
	client_cmd(id, "spk ^"%s^"", sound)
}

public SpawnBox()
{
	for(new i; i < 7; i++)
	{
		new iEntity = create_entity("info_target")

		if(!pev_valid( iEntity ))
			return PLUGIN_HANDLED

		new Float:fOrigin[3]
		pev(g_Death, pev_origin, fOrigin)

		fOrigin[0] += random_float(-100.0, 100.0)
		fOrigin[1] += random_float(-100.0, 100.0)
		fOrigin[2] -= 20.0

		set_pev(iEntity, pev_origin, fOrigin)

		new Float:fAngles[3]

		fAngles[0] = 0.0
		fAngles[2] = 0.0
		fAngles[1] = random_float(0.0, 180.0)

		set_pev(iEntity, pev_angles, fAngles)

		velocity_by_aim(g_Death, 600, fAngles)
		set_pev(iEntity, pev_velocity, fAngles)

		new Float:fVel[3]
		fVel[0] = random_float(10.0, 50.0)
		fVel[1] = random_float(10.0, 50.0)
		fVel[2] = random_float(10.0, 50.0)

		set_pev(iEntity, pev_velocity, fVel)

		set_pev(iEntity, pev_classname, gClassname)
		set_pev(iEntity, pev_solid, SOLID_TRIGGER)
		set_pev(iEntity, pev_movetype, MOVETYPE_TOSS)

		engfunc(EngFunc_SetModel, iEntity, gModel)
		engfunc(EngFunc_SetSize, iEntity, Float:{-3.5, -3.5, -3.5}, Float:{3.5, 3.5, 3.5})

		set_rendering(iEntity, kRenderFxGlowShell, 242, 12, 189, kRenderNormal, 30)

		drop_to_floor(iEntity)
	}
	return PLUGIN_HANDLED
}

public BoxTouch(iBox, id)
{
	if(!pev_valid( iBox ))
		return PLUGIN_HANDLED

	if(iPlayerTouch[id] || iPlayerTouchFix[id][iBox])
		return PLUGIN_HANDLED


	new iRandom = random_num(1, 2)

	switch( iRandom )
	{
		case 1:
		{
			new iMoney = random_num(5000, 150000)
			zp_cs_set_user_money(id, zp_cs_get_user_money(id) + iMoney)

			set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), 0.12, 0.7, 0, 5.0, 4.0)
			ShowSyncHudMsg(id, g_MsgSync1, "%L", LANG_PLAYER, "ALIEN_BOX_MONEY", iMoney)
		}

		case 2:
		{
			new iExp = random_num(1, 10)
			zp_set_user_exp(id, zp_get_user_exp(id) + iExp)

			set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), 0.12, 0.7, 0, 5.0, 4.0)
			ShowSyncHudMsg(id, g_MsgSync1, "%L", LANG_PLAYER, "ALIEN_BOX_EXP", iExp)
		}
	}

	
	set_pev(iBox, pev_flags, FL_KILLME)

	iPlayerTouch[id] = true
	iPlayerTouchFix[id][iBox] = true

	return PLUGIN_HANDLED
}

public UmmStart()
{
	set_pev(g_Death, pev_deadflag, DEAD_DYING)
	zp_set_umm_start()
}

stock Light(Ent, Time, Radius, Rate, Colors[3]) 
{
    if(!pev_valid(Ent)) return
    new Float:Origin[3]; pev(Ent, pev_origin, Origin)
        
    engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, Origin, 0)
    write_byte(TE_DLIGHT) // TE id
    engfunc(EngFunc_WriteCoord, Origin[0]) // x
    engfunc(EngFunc_WriteCoord, Origin[1]) // y
    engfunc(EngFunc_WriteCoord, Origin[2]) // z
    write_byte(Radius) // radius
    write_byte(Colors[0]) // r
    write_byte(Colors[1]) // g
    write_byte(Colors[2]) // b
    write_byte(10 * Time) //life
    write_byte(Rate) //decay rate
    message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
