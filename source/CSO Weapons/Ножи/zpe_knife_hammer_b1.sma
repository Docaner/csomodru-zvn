#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <zp_system>
#include <reapi>
#include <xs>
#include <smart_effects>

#define PLUGIN_NAME    			"[ZMO] Knife: Hammer"
#define PLUGIN_VERSION 			"1.22"
#define PLUGIN_AUTHOR  			"Batcon"

#define get_bit(%1,%2)   		((%1 & (1 << (%2 & 31))) ? 1 : 0)
#define set_bit(%1,%2)	 		%1 |= (1 << (%2 & 31))
#define reset_bit(%1,%2) 		%1 &= ~(1 << (%2 & 31))

#define ACT_RANGE_ATTACK1 		28

#define linux_diff_weapon 4
#define linux_diff_player 5
// CBaseAnimating
#define m_flFrameRate               	36
#define m_flGroundSpeed             	37
#define m_flLastEventCheck          	38
#define m_fSequenceFinished         	39
#define m_fSequenceLoops            	40

// CBasePlayerItem
#define m_pPlayer                   	41

// CBasePlayerWeapon
#define m_iId 43
#define m_flNextPrimaryAttack       	46
#define m_flNextSecondaryAttack     	47
#define m_flTimeWeaponIdle          	48
#define m_flWeaponSpeed			58
#define m_flNextReload                	75

// CBaseMonster
#define m_Activity         	    	73
#define m_IdealActivity             	74
#define m_LastHitGroup              	75
#define m_flNextAttack              	83

// CBasePlayer
#define m_flPainShock 			108
#define m_iPlayerTeam               	114
#define m_flLastAttackTime  		220
#define m_szAnimExtention	    	492

#define m_pActiveItem 373

new const Float:g_vecAddAngles[][] =
{
	{0.0, 0.0, 0.0},
	{0.0, -7.0, 0.0},
	{0.0, 7.0, 0.0},
	{0.0, -15.0, 0.0},
	{0.0, 15.0, 0.0},
	{0.0, -21.0, 0.0},
	{0.0, 21.0, 0.0}
};

#define DONT_BLEED			-1
#define BLOOD_COLOR_RED			247
#define BLOOD_COLOR_YELLOW		195

#define HAMMER_MODEL_VIEW	"models/zp_br_cso/knifes_b1/v_hammer_vip_b2.mdl"
#define HAMMER_MODEL_PLAYER	"models/zp_br_cso/knifes_b1/p_hammer_vip_b1.mdl"

#define HAMMER_SOUND_DRAW	"zp_br_cso/knifes_b1/hammer_vip/draw.wav"
#define HAMMER_SOUND_SLASH	"zp_br_cso/knifes_b1/hammer_vip/hit_slash.wav"
#define HAMMER_SOUND_STAB	"zp_br_cso/knifes_b1/hammer_vip/hit_stab.wav"
#define HAMMER_SOUND_SWING	"zp_br_cso/knifes_b1/hammer_vip/miss.wav"

#define HAMMER_PLAYER_SEQUENCE	"hammer"

#define HAMMER_SEQ_SLASH_IDLE	0
#define HAMMER_SEQ_SLASH_ATTACK	1
#define HAMMER_SEQ_SLASH_DRAW	2
#define HAMMER_SEQ_SLASH_MOVE	7

#define HAMMER_SEQ_STAB_IDLE	3
#define HAMMER_SEQ_STAB_ATTACK	4
#define HAMMER_SEQ_STAB_DRAW	5
#define HAMMER_SEQ_STAB_MOVE	6

#define HAMMER_SPEED_SLASH		230.0
#define HAMMER_SPEED_STAB		170.0

#define HAMMER_DISTANCE_SLASH	88.75
#define HAMMER_DISTANCE_STAB	88.75

#define HAMMER_DISTANCE_JUMP_SLASH	107.5
#define HAMMER_DISTANCE_JUMP_STAB	110.0

#define HAMMER_DAMAGE_SLASH		550.0
#define HAMMER_DAMAGE_STAB		850.0

#define HAMMER_KNOCKBACK_SLASH	275.0

#define HAMMER_NAME 		"Hammer"


enum
{
	HIT_NONE = 0,
	HIT_WALL,
	HIT_PLAYER
}


new iszHammerModelView, iszHammerModelPlayer
new iModelIndexBloodSpray, iModelIndexBloodDrop
new BitUserHammerMode
new bool:has_item[33]

new g_iHammer;
native zp_register_knife(const szName[]);
forward zp_knife_selected(id, iKnife, iOldKnife);

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	
	RegisterHam(Ham_Item_Deploy, 			"weapon_knife", "fw_Hammer_Draw", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, 		"weapon_knife", "fw_Hammer_Idle");
	RegisterHam(Ham_Weapon_PrimaryAttack,   		"weapon_knife", "fw_Hammer_Attack");
	RegisterHam(Ham_Weapon_SecondaryAttack,		"weapon_knife", "fw_Hammer_Move");
	RegisterHam(Ham_Item_PostFrame,			"weapon_knife", "fw_Hammer_Think");
	RegisterHam(Ham_Spawn, "player", "fw_Player_Spawn", 1);

	g_iHammer = zp_register_knife(HAMMER_NAME);	
}

public plugin_natives() 
{
	register_native("ZPE_SetUserKnifeHammer","native_set_item",1)
}

public native_set_item(pPlayer, bool: bState) 
{
	reset_bit(BitUserHammerMode, pPlayer)
	has_item[pPlayer]=bState
}

public plugin_precache() {
	engfunc(EngFunc_PrecacheModel, HAMMER_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, HAMMER_MODEL_PLAYER);
	
	engfunc(EngFunc_PrecacheSound, HAMMER_SOUND_DRAW);
	engfunc(EngFunc_PrecacheSound, HAMMER_SOUND_SLASH);
	engfunc(EngFunc_PrecacheSound, HAMMER_SOUND_STAB);
	engfunc(EngFunc_PrecacheSound, HAMMER_SOUND_SWING);
	
	iszHammerModelView = engfunc(EngFunc_AllocString, HAMMER_MODEL_VIEW);
	iszHammerModelPlayer = engfunc(EngFunc_AllocString, HAMMER_MODEL_PLAYER);
	
	iModelIndexBloodSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
	iModelIndexBloodDrop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");
}

public client_putinserver(pPlayer) 
{
	reset_bit(BitUserHammerMode, pPlayer);
}

public client_disconnected(pPlayer) 
{
	reset_bit(BitUserHammerMode, pPlayer);
	has_item[pPlayer]=false;
}

public zp_knife_selected(id, iKnife, iOldKnife)
{
	if(g_iHammer == iKnife && iKnife != iOldKnife)
		native_set_item(id, true);

	if(g_iHammer == iOldKnife && iKnife != iOldKnife)
		native_set_item(id, false);
}

public fw_Player_Spawn(pPlayer) 
{
	if(!is_user_alive(pPlayer) || zp_get_user_zombie(pPlayer) || !has_item[pPlayer])
		return;
	
	new iActiveItem = get_pdata_cbase(pPlayer, m_pActiveItem);

	if(pev_valid(iActiveItem) != 2 || get_pdata_int(iActiveItem, m_iId, linux_diff_weapon) != CSW_KNIFE)
		return
	
	set_pev_string(pPlayer, pev_viewmodel2, iszHammerModelView);
	set_pev_string(pPlayer, pev_weaponmodel2, iszHammerModelPlayer);
	set_pdata_string(pPlayer, m_szAnimExtention * 4, HAMMER_PLAYER_SEQUENCE, -1, 20);
	
	if(get_bit(BitUserHammerMode, pPlayer)) 
	{
		UTIL_SendWeaponAnim(pPlayer, HAMMER_SEQ_STAB_DRAW);
		set_pdata_float(iActiveItem, m_flWeaponSpeed, HAMMER_SPEED_STAB, 4);
	}
	else 
	{
		UTIL_SendWeaponAnim(pPlayer, HAMMER_SEQ_SLASH_DRAW);
		set_pdata_float(iActiveItem, m_flWeaponSpeed, HAMMER_SPEED_SLASH, 4);
	}

	// return;
}
public fw_UpdateClientData_Post(pPlayer, SendWeapons, CD_Handle) 
{
	if(get_cd(CD_Handle, CD_DeadFlag) != DEAD_NO) return;
	if(!has_item[pPlayer] || zp_get_user_zombie(pPlayer)||get_user_weapon(pPlayer) != CSW_KNIFE) return;
	set_cd(CD_Handle, CD_flNextAttack, 99999.0);
}
public fw_Hammer_Draw(iItem) 
{
	static pPlayer; pPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	
	if(!has_item[pPlayer] || zp_get_user_zombie(pPlayer))
		return;
		
	set_pev_string(pPlayer, pev_viewmodel2, iszHammerModelView);
	set_pev_string(pPlayer, pev_weaponmodel2, iszHammerModelPlayer);
	set_pdata_string(pPlayer, m_szAnimExtention * 4, HAMMER_PLAYER_SEQUENCE, -1, 20);
	set_pdata_float(pPlayer, m_flNextAttack, 1.5, 5);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 1.5, 4);
	set_pdata_float(iItem, m_flNextReload, 0.0, 4);
	
	emit_sound(pPlayer, CHAN_ITEM, HAMMER_SOUND_DRAW, 1.0, 2.4, 0, PITCH_NORM);

	if(get_bit(BitUserHammerMode, pPlayer)) 
	{
		UTIL_SendWeaponAnim(pPlayer, HAMMER_SEQ_STAB_DRAW);
		set_pdata_float(iItem, m_flWeaponSpeed, HAMMER_SPEED_STAB, 4);
	}
	else 
	{
		UTIL_SendWeaponAnim(pPlayer, HAMMER_SEQ_SLASH_DRAW);
		set_pdata_float(iItem, m_flWeaponSpeed, HAMMER_SPEED_SLASH, 4);
	}
}
public fw_Hammer_Idle(iItem) {
	if(get_pdata_float(iItem, m_flTimeWeaponIdle, 4) > 0.0) return HAM_IGNORED;
	static pPlayer; pPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	if(!has_item[pPlayer] || zp_get_user_zombie(pPlayer)) return HAM_IGNORED;
	UTIL_SendWeaponAnim(pPlayer, get_bit(BitUserHammerMode, pPlayer) ? HAMMER_SEQ_STAB_IDLE : HAMMER_SEQ_SLASH_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 99999.0, 4);
	return HAM_SUPERCEDE;
}
public fw_Hammer_Attack(iItem) 
{
	static pPlayer; pPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	
	if(!has_item[pPlayer] || zp_get_user_zombie(pPlayer)) return HAM_IGNORED;
	
	set_pdata_float(iItem, m_flNextPrimaryAttack, 2.0, 4);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 2.0, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 2.1, 4);
	
	if(get_bit(BitUserHammerMode, pPlayer)) 
	{
		UTIL_SendWeaponAnim(pPlayer, HAMMER_SEQ_STAB_ATTACK);
		set_pdata_float(iItem, m_flNextReload, get_gametime() + 0.12, 4);
	}
	else 
	{
		UTIL_SendWeaponAnim(pPlayer, HAMMER_SEQ_SLASH_ATTACK);
		set_pdata_float(iItem, m_flNextReload, get_gametime() + 1.0, 4);
	}
	
	static szAnimation[32]; 
	format(szAnimation, charsmax(szAnimation), pev(pPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", HAMMER_PLAYER_SEQUENCE);
	UTIL_PlayerAnimation(pPlayer, szAnimation);
	
	return HAM_SUPERCEDE;
}
public fw_Hammer_Move(iItem) 
{
	static pPlayer; pPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	if(!has_item[pPlayer] || zp_get_user_zombie(pPlayer)) return HAM_IGNORED;
	if(pev(pPlayer,pev_button)&IN_ATTACK)return HAM_SUPERCEDE;
	set_pdata_float(pPlayer, m_flNextAttack, 1.5, 5);
	set_pdata_float(iItem, m_flTimeWeaponIdle, 1.8, 4);
	
	if(get_bit(BitUserHammerMode, pPlayer)) 
	{
		reset_bit(BitUserHammerMode, pPlayer);
		UTIL_SendWeaponAnim(pPlayer, HAMMER_SEQ_SLASH_MOVE);
		set_pdata_float(iItem, m_flWeaponSpeed, HAMMER_SPEED_SLASH, 4);
	}
	else 
	{
		set_bit(BitUserHammerMode, pPlayer);
		UTIL_SendWeaponAnim(pPlayer, HAMMER_SEQ_STAB_MOVE);
		set_pdata_float(iItem, m_flWeaponSpeed, HAMMER_SPEED_STAB, 4);
	}
	ExecuteHamB(Ham_Item_PreFrame, pPlayer);
	return HAM_SUPERCEDE;
}
public fw_Hammer_Think(iItem) 
{
	static pPlayer; pPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	if(!has_item[pPlayer] || zp_get_user_zombie(pPlayer)) return;
	static Float:flTimeAttack; flTimeAttack = get_pdata_float(iItem, m_flNextReload, 4);
	
	if(flTimeAttack == 0.0 || flTimeAttack > get_gametime()) return;
	set_pdata_float(iItem, m_flNextReload, 0.0, 4);
	
	static Float:flDistance;
	if(pev(pPlayer, pev_flags) & FL_ONGROUND)
		flDistance = get_bit(BitUserHammerMode, pPlayer) ? HAMMER_DISTANCE_SLASH : HAMMER_DISTANCE_STAB;
	else
		flDistance = get_bit(BitUserHammerMode, pPlayer) ? HAMMER_DISTANCE_JUMP_SLASH : HAMMER_DISTANCE_JUMP_STAB;
	static tr; tr = create_tr2();
	static Float:vecTraceStart[3];
	static Float:vecOrigin[3]; pev(pPlayer, pev_origin, vecOrigin);
	static Float:vecViewOfs[3]; pev(pPlayer, pev_view_ofs, vecViewOfs);
	static Float:vecAngles[3]; pev(pPlayer, pev_v_angle, vecAngles);
	static Float:vecForward[3]//, Float:vecRight[3];
	static Float:vecBack[3];
	
	static Float:vecNewAngles[3], Float:vecTraceEnd[3];

	new Trie:tEntsDamaged = TrieCreate(), pHitSound, iSoundDefAngle, iSoundOther

	for(new i; i < sizeof g_vecAddAngles; i++)
	{
		xs_vec_add(vecAngles, g_vecAddAngles[i], vecNewAngles);

		angle_vector(vecNewAngles, ANGLEVECTOR_FORWARD, vecForward);
		//engfunc(EngFunc_AngleVectors, vecNewAngles, vecForward, vecRight);
		
		xs_vec_add(vecViewOfs, vecOrigin, vecTraceStart);

		xs_vec_mul_scalar(vecForward, flDistance, vecTraceEnd);
		xs_vec_add(vecTraceEnd, vecTraceStart, vecTraceEnd);

		xs_vec_mul_scalar(vecForward, -10.0, vecBack)
		xs_vec_add(vecTraceStart, vecBack, vecTraceStart);

		pHitSound = Trace_AccrosPlayers(tEntsDamaged, get_bit(BitUserHammerMode, pPlayer) ? HAMMER_DAMAGE_SLASH : HAMMER_DAMAGE_STAB, vecTraceStart, vecTraceEnd, DONT_IGNORE_MONSTERS, pPlayer, tr)

		if(i == 0) 
			iSoundDefAngle = pHitSound;

		if(pHitSound > iSoundOther)
			iSoundOther = pHitSound;

		//client_print(0, print_chat, "iter next")
	}	

	free_tr2(tr);
	TrieDestroy(tEntsDamaged);

	if(iSoundOther == HIT_PLAYER || iSoundDefAngle > HIT_NONE)
		emit_sound(pPlayer, CHAN_WEAPON, get_bit(BitUserHammerMode, pPlayer) ? HAMMER_SOUND_SLASH : HAMMER_SOUND_STAB, 1.0, ATTN_NORM, 0, PITCH_NORM);
	else
		emit_sound(pPlayer, CHAN_WEAPON, HAMMER_SOUND_SWING, 1.0, ATTN_NORM, 0, PITCH_NORM);


	/*if(IsWall && !SoundWallPlayed)
		emit_sound(pPlayer, CHAN_WEAPON, get_bit(BitUserHammerMode, pPlayer) ? HAMMER_SOUND_SLASH : HAMMER_SOUND_STAB, 1.0, ATTN_NORM, 0, PITCH_NORM);
	else if(!bBloodSound) 
		emit_sound(pPlayer, CHAN_WEAPON, HAMMER_SOUND_SWING, 1.0, ATTN_NORM, 0, PITCH_NORM);*/
}

stock Trace_AccrosPlayers(Trie:tEntsDamaged, Float:flDamage, Float:vecTraceStart[3], Float:vecTraceEnd[3], iMonsterIgnore, pPlayer, tr)
{
	new iHitType = HIT_NONE,
		Float:flCurrentDist,
		Float:flDist = get_distance_f(vecTraceStart, vecTraceEnd),
		Float:vecDir[3],
		pHit = pPlayer,
		Float:flFraction,
		Float:vecEndPos[3];

	xs_vec_sub(vecTraceEnd, vecTraceStart, vecDir);
	xs_vec_normalize(vecDir, vecDir);

	while(flCurrentDist < flDist)
	{
		engfunc(EngFunc_TraceLine, vecTraceStart, vecTraceEnd, iMonsterIgnore, pHit, tr);
		get_tr2(tr, TR_flFraction, flFraction);

		if(flFraction == 1.0) return max(HIT_NONE, iHitType);

		flCurrentDist = flDist * flFraction;
		flDist -= flCurrentDist;

		get_tr2(tr, TR_vecEndPos, vecEndPos);
		xs_vec_add(vecEndPos, vecDir, vecTraceStart);
		pHit = get_tr2(tr, TR_pHit);

		//client_print(pPlayer, print_chat, "pHit: %d | is_null: %s | is_user_alive: %s", pHit, is_nullent(pHit) ? "true" : "flase", is_user_alive(pHit) ? "true" : "flase");

		if(is_nullent(pHit)) return max(HIT_WALL, iHitType);

		if(pHit == pPlayer) 
			continue;

		if(pev(pHit, pev_solid) == SOLID_BSP)
		{
			if(~pev(pHit, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY && Float:get_entvar(pHit, var_health) != 0.0) 
			{
				ExecuteHamB(Ham_TakeDamage, pHit, pPlayer, pPlayer, flDamage, DMG_NEVERGIB | DMG_CLUB);

				// client_print(0, print_chat, "pHit: %d | spawnflags: %d | health: %f", pHit, pev(pHit, pev_spawnflags), Float:get_entvar(pHit, var_health))

				iHitType = max(HIT_WALL, iHitType);
			}
			else	
				return max(HIT_WALL, iHitType);
		}
		
		if(FakeTraceAttack(tEntsDamaged, pHit, pPlayer, flDamage, vecDir, tr, DMG_NEVERGIB | DMG_CLUB)) 
		{
			iHitType = max(HIT_PLAYER, iHitType);
		}
	}
	return iHitType;
}

public FakeTraceAttack(Trie:tEntsDamaged, iVictim, iAttacker, Float:flDamage, Float:vecDirection[3], pTrace, bDamageBits) 
{
	if(zp_is_round_end() || TrieKeyExists(tEntsDamaged, fmt("%d", iVictim)) || pev(iVictim, pev_takedamage) == DAMAGE_NO ||
		zp_get_user_zombie(iAttacker) || is_user_alive(iVictim) && !zp_get_user_zombie(iVictim) && !IsAliveNPC(iVictim)) 
		return 0;

	static iHitgroup; iHitgroup = get_tr2(pTrace, TR_iHitgroup);
	static Float:vecEndPos[3]; get_tr2(pTrace, TR_vecEndPos, vecEndPos);
	static iBloodColor; iBloodColor = ExecuteHamB(Ham_BloodColor, iVictim);
	
	if(IsPlayer(iVictim)) set_pdata_int(iVictim, m_LastHitGroup, iHitgroup, linux_diff_player)
	
	switch(iHitgroup) 
	{
		case HIT_HEAD:                  flDamage *= 3.0;
		case HIT_LEFTARM, HIT_RIGHTARM: flDamage *= 0.75;
		case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 0.75;
		case HIT_STOMACH:               flDamage *= 1.5;
	}
	
	ExecuteHamB(Ham_TakeDamage, iVictim, iAttacker, iAttacker, flDamage, bDamageBits);
	
	if(!IsNPC(iVictim)) FakeKnockBack(iVictim, vecDirection, HAMMER_KNOCKBACK_SLASH);
	
	if(iBloodColor != DONT_BLEED) 
	{
		ExecuteHamB(Ham_TraceBleed, iVictim, flDamage, vecDirection, pTrace, bDamageBits);
		UTIL_BloodDrips(vecEndPos, iBloodColor, floatround(flDamage));
	}

	TrieSetCell(tEntsDamaged, fmt("%d", iVictim), 1);
	return 1;
}
public FakeKnockBack(pPlayer, Float:vecDirection[3], Float:flKnockBack) {
	set_pdata_float(pPlayer, m_flPainShock, 1.0, 5);
	static Float:vecVelocity[3]; pev(pPlayer, pev_velocity, vecVelocity);
	if(pev(pPlayer, pev_flags) & FL_DUCKING) flKnockBack *= 0.7;
	vecVelocity[0] = vecDirection[0] * flKnockBack;
	vecVelocity[1] = vecDirection[1] * flKnockBack;
	vecVelocity[2] = 200.0;
	set_pev(pPlayer, pev_velocity, vecVelocity);
}
/*public FakeKnockBackUpdate(pPlayer, Float:vecForward[3], Float:vecRight[3], Float:flForward, Float:flRight) {
	set_pdata_float(pPlayer, m_flPainShock, 1.0, 5);
	static Float:vecVelocity[3]; pev(pPlayer, pev_velocity, vecVelocity);
	if(pev(pPlayer, pev_flags) & FL_DUCKING) flForward *= 0.7;
	vecVelocity[0] = vecForward[0] * flForward + vecRight[0] * flRight;
	vecVelocity[1] = vecForward[1] * flForward + vecRight[1] * flRight;
	vecVelocity[2] = 200.0;
	set_pev(pPlayer, pev_velocity, vecVelocity);
}*/

public UTIL_SendWeaponAnim(pPlayer, iSequence) {
	set_pev(pPlayer, pev_weaponanim, iSequence);
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, pPlayer);
	write_byte(iSequence);
	write_byte(0);
	message_end();
	
	static iPlayersID[32], iPlayer, iCount, i;
	get_players(iPlayersID, iCount, "bc");
	
	for(i = 0; i < iCount; i++) {
		iPlayer = iPlayersID[i];
		if(!(pev(iPlayer, pev_iuser1) == 4 && pev(iPlayer, pev_iuser2) == pPlayer)) continue;
		
		set_pev(iPlayer, pev_weaponanim, iSequence);
		message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, iPlayer);
		write_byte(iSequence);
		write_byte(0);
		message_end();
	}
	
	return iSequence;
}
public UTIL_BloodDrips(Float:vecOrigin[3], iColor, iAmount) {
	if(iAmount > 255) iAmount = 255;
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(iModelIndexBloodSpray);
	write_short(iModelIndexBloodDrop);
	write_byte(iColor);
	write_byte(min(max(3,iAmount/10),16));
	message_end();
}
public UTIL_PlayerAnimation(pPlayer, szAnimation[]) 
{ 
	static iAnimDesired, Float:flFrameRate, Float:flGroundSpeed, bool:bLoops;
	if((iAnimDesired = lookup_sequence(pPlayer, szAnimation, flFrameRate, bLoops, flGroundSpeed)) == -1) iAnimDesired = 0;
	
	static Float:flGameTime; flGameTime = get_gametime();
	
	set_pev(pPlayer, pev_frame, 0.0);
	set_pev(pPlayer, pev_animtime, flGameTime);
	set_pev(pPlayer, pev_sequence, iAnimDesired);
	if(get_bit(BitUserHammerMode, pPlayer))
		set_pev(pPlayer, pev_framerate, 1.895);
	else
		set_pev(pPlayer, pev_framerate, 1.0);
	
	set_pdata_int(pPlayer, m_fSequenceLoops, bLoops, 4);
	set_pdata_int(pPlayer, m_fSequenceFinished, 0, 4);
	set_pdata_float(pPlayer, m_flFrameRate, flFrameRate, 4);
	set_pdata_float(pPlayer, m_flGroundSpeed, flGroundSpeed, 4);
	set_pdata_float(pPlayer, m_flLastEventCheck, flGameTime, 4);
	set_pdata_int(pPlayer, m_Activity, ACT_RANGE_ATTACK1, 5);
	set_pdata_int(pPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, 5);  
	set_pdata_float(pPlayer, m_flLastAttackTime, flGameTime, 5);
}
