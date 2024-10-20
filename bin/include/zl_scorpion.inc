/* 
	ScorpionBoss
	
	www.ZombieLite.Ru
	www.Alexander3.Ru
*/

#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < xs >

#define VERSION			"1.0.1"

#define pev_victim		pev_weaponanim
#define pev_tornado		pev_iuser2		

#define ZL_CHOOSE_MIN		0
#define ZL_CHOOSE_MAX		1
#define ZL_CHOOSE_RANDOM	2

native zl_boss_map()
native zl_boss_valid( ent )
native zl_player_random()
native zl_player_alive()
native zl_colorchat(id, const msg[], any:...)
forward zl_timer(timer, prepare)

stock zl_anim(ent, sequence, Float:speed) {		
	set_pev(ent, pev_sequence, sequence)
	set_pev(ent, pev_animtime, halflife_time())
	set_pev(ent, pev_framerate, speed)
}

stock zl_radiusdmg(origin_start, maxdmg, radius) {
	new i = 1, p = get_maxplayers()
	new Float:origin[3], Float:vector[3], len
	new Float:dmg_len, Float:dmg_current
	for(i = 1; <= p; ++i) {
		if (!is_user_alive(i))
			continue
		
		pev(i, pev_origin, origin_end)
		xs_vec_sub(orign_end, origin_start, vector)
		len = xs_vec_len(vector)
		
		if (len > radius)
			continue
			
		dmg_len = len * 100 / radius
		dmg_len = 100 - dmg_len
		dmg_current = maxdmg * dmg_len / 100
		zl_damage(i, floatround(dmg_current))
	}
}

stock zl_slap(victim, slap, damage, sound) {
	if (!is_user_alive(victim))
		return
		
	new hp = pev(victim, pev_health)
	if (hp - damage <= 0) {
		ExecuteHamB(Ham_Killed, victim, victim, 2)
		return
	}
	
	new Float:origin1[3], Float:origin2[3], Float:angle[3]
	pev(victim, pev_origin, origin1)
	pev(victim, pev_angles, angle)
	angle_vector(angle, ANGLEVECTOR_FORWARD, angle)
	origin2[0] = origin1[0] + angle[0] * 65.0
	origin2[1] = origin1[1] + angle[1] * 65.0
	xs_vec_sub(origin1, origin2, origin2)
	xs_vec_normalize(origin2, origin2)
	xs_vec_mul_scalar(origin2, float(slap), origin2)
	origin2[2] = 250.0
	set_pev(victim, pev_velocity, origin2)
	zl_damage(victim, damage, sound)
}

stock zl_damage(id, damage, sound) {
	if (!is_user_alive(id))
		return
		
	new hp = pev(id, pev_health)
	if (hp - damage <= 0) {
		if (sound) zl_sound(id, "zl/npc/illidan/attack_killed.wav", 0)
		ExecuteHamB(Ham_Killed, id, id, 2)
	} else ExecuteHamB(Ham_TakeDamage, id, 0, id, float(damage), DMG_BLAST)
}

stock zl_player_choose(boss, type) {
	new i = 1
	new m = get_maxplayers()
	new v = 0
	new Float:dist = 9999.0
	new num = 0
	new player[33]
	
	new Float:len, Float:buffer
	new Float:origin_player[3], Float:origin_boss[3], Float:vector[3]
	pev(boss, pev_origin, origin_boss)
	
	for(i = 1; i <= m; ++i) {
		if (!is_user_alive(i))
			continue
				
		pev(i, pev_origin, origin_player)
		xs_vec_sub(origin_player, origin_boss, vector)
		len = xs_vec_len(vector)
		
		switch(type) {
			case ZL_CHOOSE_MIN: {
				if (len < dist) {
					dist = len
					v = i
				}
			}
			case ZL_CHOOSE_MAX: {
				if (len > buffer) {
					buffer = len
					v = i
				}
			}
			case ZL_CHOOSE_RANDOM: {
				player[num] = i
				num++
			}
		}
	}
	return (type == 2) ? player[random(num)] : v
}

stock zl_move(Start, End, Float:speed = 250.0, Float:Velocity[] = {0.0, 0.0, 0.0}, Float:Angles[] = {0.0, 0.0, 0.0}) {
	static Float:Origin[3], Float:Origin2[3], Float:Angle[3], Float:Vector[3], Float:Len
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

stock bool:TraceCheckCollides(Float:origin[3], const Float:BOUNDS) {
	new Float:traceEnds[8][3], Float:traceHit[3], hitEnt
	traceEnds[0][0] = origin[0] - BOUNDS
	traceEnds[0][1] = origin[1] - BOUNDS
	traceEnds[0][2] = origin[2] - BOUNDS

	traceEnds[1][0] = origin[0] - BOUNDS
	traceEnds[1][1] = origin[1] - BOUNDS
	traceEnds[1][2] = origin[2] + BOUNDS

	traceEnds[2][0] = origin[0] + BOUNDS
	traceEnds[2][1] = origin[1] - BOUNDS
	traceEnds[2][2] = origin[2] + BOUNDS

	traceEnds[3][0] = origin[0] + BOUNDS
	traceEnds[3][1] = origin[1] - BOUNDS
	traceEnds[3][2] = origin[2] - BOUNDS
     
	traceEnds[4][0] = origin[0] - BOUNDS
	traceEnds[4][1] = origin[1] + BOUNDS
	traceEnds[4][2] = origin[2] - BOUNDS

	traceEnds[5][0] = origin[0] - BOUNDS
	traceEnds[5][1] = origin[1] + BOUNDS
	traceEnds[5][2] = origin[2] + BOUNDS

	traceEnds[6][0] = origin[0] + BOUNDS
	traceEnds[6][1] = origin[1] + BOUNDS
	traceEnds[6][2] = origin[2] + BOUNDS

	traceEnds[7][0] = origin[0] + BOUNDS
	traceEnds[7][1] = origin[1] + BOUNDS
	traceEnds[7][2] = origin[2] - BOUNDS

	for (new i = 0; i < 8; i++) {
		if (point_contents(traceEnds[i]) != CONTENTS_EMPTY)
			return true

		hitEnt = trace_line(0, origin, traceEnds[i], traceHit)
		if (hitEnt != 0) return true
		
		for (new j = 0; j < 3; j++) {
			if (traceEnds[i][j] != traceHit[j])
				return true
		}
	}
	return false
}

stock zl_position(id, Float:forw, Float:right, Float:up, Float:vStart[]) {
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
    
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_angles, vAngle) // if normal entity ,use pev_angles
    
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
    
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock zl_screenshake(id, ampl, timer) {
	if(id) if(!is_user_alive(id)) return
	
	if (ampl > 15)
		ampl = 15
	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid("ScreenShake"), _, id ? id : 0);
	write_short(ampl << 12)
	write_short(timer << 12)
	write_short(7 << 12)
	message_end()
}

stock zl_screenfade(id, Timer = 1, FadeTime = 1, Colors[3] = {0, 0, 0}, Alpha = 0, type = 1) {
	if(id) if(!is_user_connected(id)) return

	if (Timer > 0xFFFF) Timer = 0xFFFF
	if (FadeTime <= 0) FadeTime = 4
	
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid("ScreenFade"), _, id);
	write_short(Timer * 1 << 12)
	write_short(FadeTime * 1 << 12)
	switch (type) {
		case 1: write_short(0x0000)		// IN ( FFADE_IN )
		case 2: write_short(0x0001)		// OUT ( FFADE_OUT )
		case 3: write_short(0x0002)		// MODULATE ( FFADE_MODULATE )
		case 4: write_short(0x0004)		// STAYOUT ( FFADE_STAYOUT )
		default: write_short(0x0001)
	}
	write_byte(Colors[0])
	write_byte(Colors[1])
	write_byte(Colors[2])
	write_byte(Alpha)
	message_end()
}

stock zl_wreck(Float:Origin[3], Float:Size[3], Float:Velocity[3], RandomVelocity, Num, Life, Flag, index) {			
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
	write_short(index) // Model/Sprite index
	write_byte(Num) // Num
	write_byte(Life) // Life
	write_byte(Flag) // Flags ( 0x02 )
	message_end()
}

stock zl_sound(index, sound[], type = 0) { // Type : 0 - Message, 1 - EntSound
	switch (type) {
		case 0: {
			if (contain(sound, ".wav") == -1) {
				client_cmd(index, "mp3 play ^"sound/%s^"", sound)
			} else {
				message_begin(index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid("SendAudio"), _, index)	
				write_byte(index)
				write_string(sound)
				write_short(PITCH_NORM)
				message_end()
			}
		}
		case 1: engfunc(EngFunc_EmitSound, index, CHAN_VOICE, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		default: log_amx("[ERROR] SoundType ERROR")
	}
}

stock zl_boss_slap(boss, end) {
	static Float:origin_start[3], Float:origin_end[3], Float:angle[3], Float:velocity[3]
	
	pev(boss, pev_origin, origin_start)
	pev(end, pev_origin, origin_end)
		
	xs_vec_sub(origin_end, origin_start, velocity)
	vector_to_angle(velocity, angle)
	
	velocity[2] = 0.0
	angle[0] = 0.0
	angle[2] = 0.0
	
	xs_vec_normalize(velocity, velocity)
	xs_vec_mul_scalar(velocity, 700.0, velocity)
	
	set_pev(boss, pev_velocity, velocity)
	set_pev(boss, pev_angles, angle)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
