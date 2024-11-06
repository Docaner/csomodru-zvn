#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <zombieplague>
#include <zp_system>
#include <xs>
#include <smart_effects>

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))

native zp_register_knife(const szName[]);
forward zp_knife_selected(id, iKnife, iOldKnife);


enum
{
	ANIM_IDLE = 0,

	ANIM_SLASH1,
	ANIM_SLASH2,
	ANIM_SLASH3,
	ANIM_SLASH4,
	ANIM_SLASH5,

	ANIM_DRAW,

	ANIM_CHARGE_START,
	ANIM_CHARGE_FINISH,
	ANIM_CHARGE_IDLE_NOT_FINISH,
	ANIM_CHARGE_IDLE_FINISH,

	ANIM_CHARGE_ATTACK_NOT_FINISH,
	ANIM_CHARGE_ATTACK_FINISH
};

#define ANIM_IDLE_TIME			201/30.0
#define ANIM_SLASH_TIME			37/30.0
#define ANIM_DRAW_TIME			40/30.0
#define ANIM_CHARGE_START_TIME	22/30.0
#define ANIM_CHARGE_FINISH_TIME	10/30.0
// #define ANIM_CHARGE_IDLE_TIME	30/30.0 * 0.78
#define ANIM_CHARGE_IDLE_TIME	30/30.0
#define ANIM_CHARGE_ATTACK_TIME	49/30.0

#define PLAYER_SHOOT_DRAGONTAIL_TWICE 19.0/30.0
#define PLAYER_SHOOT_DRAGONTAIL_ONCE 11.0/30.0

enum
{
	CHARGE_NONE = 0,
	CHARGE_START,
	CHARGE_LOAD,
	CHARGE_FINISH,
	CHARGE_FINISH_IDLE
}

//Charge Start
new const g_szSndChargeStart[] = "sound/weapons/balrog9_charge_start1.wav";
//Charge Finish
new const g_szSndChargeFinish[] = "sound/weapons/balrog9_charge_finish1.wav";
//Charge Attack
new const g_szSndChargeAttack[] = "weapons/balrog9_charge_attack2.wav";

//Charge Sprite Explode
new const g_szSprChargeExplode[] = "sprites/zp_br_cso/weapons4/hud/balrogcritical.spr";

//Player Animation Reference
new const g_szKnifeRef[] = "dragontail";

//Delay primary attack
#define KNIFE_ATTACK_DELAY 0.322

//Attack's Counter 
#define var_knife_primary_anim var_iuser1

//Last Attack Knife
#define var_knife_last_attack var_ltime

//Hits counter
#define var_knife_hit_counter var_iuser2

//Charge Attack Dist
// #define CHARGE_DISTANCE 121.0
#define CHARGE_DISTANCE 100.0

//Charge Attack Damage
#define CHARGE_DMG 577.5 // 550.0

//Charge Knock
#define CHARGE_KNOCK 600.0 // 572.5

//Settings Fake TraceLines
#define ATTACK_STEP 5.0 // Шаг TraceAttack
#define ATTACK_WIDTH 36.0 // Ширина атаки в градусах
#define ATTACK_HEIGHT 10.0 // Высота атаки в градусах

//User variable
new g_iBitUserKnife;

//ID Knife
new g_iKnife;

enum
{
	HIT_NONE = 0,
	HIT_WALL,
	HIT_PLAYER
}

new g_iMDLIndexBloodSpray, g_iMDLIndexBloodDrop, g_iMDLIndexExplode

new HookChain:g_hRGSetAnimation;

public plugin_precache()
{
	precache_generic(g_szSndChargeStart);
	precache_generic(g_szSndChargeFinish);
	precache_sound(g_szSndChargeAttack);

	g_iMDLIndexBloodSpray = precache_model("sprites/bloodspray.spr");
	g_iMDLIndexBloodDrop = precache_model("sprites/blood.spr");
	g_iMDLIndexExplode = precache_model(g_szSprChargeExplode);
}

public plugin_init()
{
	register_plugin("[ZPE] Knife : Balrog-9", "1.0", "Docaner");

	register_forward(FM_UpdateClientData, "Meta_UpdateClientData_Post", true);

	RegisterHam(Ham_Spawn, "player", "HM_PlayerSpawn_Post", true)

	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_knife", "HM_Knife_Idle_Pre", false);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "HM_Knife_Deploy_Post", true);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "HM_Knife_PrimaryAttack_Pre", false);	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "HM_Knife_PrimaryAttack_Post", true);	
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "HM_Knife_SecondaryAttack_Pre", false);	
	RegisterHam(Ham_Item_PreFrame, "weapon_knife", "HM_Knife_PreFrame_Post", true);	

	DisableHookChain(g_hRGSetAnimation = RegisterHookChain(RG_CBasePlayer_SetAnimation, "RG_Player_SetAnimation_Pre", false));

	g_iKnife = zp_register_knife("Balrog 9")
}

public zp_knife_selected(iPlayer, iNew, iOld)
{
	if(g_iKnife == iNew && iNew != iOld)
		SetBit(g_iBitUserKnife, iPlayer);

	if(g_iKnife == iOld && iNew != iOld)
		ClearBit(g_iBitUserKnife, iPlayer);
}

public Meta_UpdateClientData_Post(id, SendWeapons, iCD)
{
	if(get_cd(iCD, CD_DeadFlag) != DEAD_NO || !IsSetBit(g_iBitUserKnife, id) || 
		zp_get_user_zombie(id) || get_user_weapon(id) != CSW_KNIFE)
		return;

	set_cd(iCD, CD_flNextAttack, get_gametime() + 0.01);
}

public HM_PlayerSpawn_Post(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || !IsSetBit(g_iBitUserKnife, id))
		return;

	new pActiveItem = get_member(id, m_pActiveItem);

	if(!is_entity(pActiveItem) || get_member(pActiveItem, m_iId) != CSW_KNIFE)
		return;

	set_member(id, m_szAnimExtention, g_szKnifeRef);
}

public HM_Knife_Idle_Pre(iItem)
{
	if(get_member(iItem, m_Weapon_flTimeWeaponIdle) > 0.0)
		return HAM_IGNORED;

	new id = get_member(iItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserKnife, id) || zp_get_user_zombie(id))
		return HAM_IGNORED;

	UTIL_SendWeaponAnim(id, ANIM_IDLE);
	set_member(iItem, m_Weapon_flTimeWeaponIdle, ANIM_IDLE_TIME);

	return HAM_SUPERCEDE;
}

public HM_Knife_Deploy_Post(iItem)
{
	new id = get_member(iItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserKnife, id) || zp_get_user_zombie(id))
		return HAM_IGNORED;

	set_entvar(iItem, var_knife_primary_anim, ANIM_SLASH1);
	set_member(iItem, m_Weapon_iWeaponState, CHARGE_NONE);

	set_member(id, m_szAnimExtention, g_szKnifeRef);
	UTIL_SendWeaponAnim(id, ANIM_DRAW);
	
	set_member(iItem, m_Weapon_flTimeWeaponIdle, ANIM_DRAW_TIME);

	return HAM_IGNORED;
}

public HM_Knife_PrimaryAttack_Pre(iItem)
{
	new id = get_member(iItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserKnife, id) || zp_get_user_zombie(id))
		return HAM_IGNORED;

	EnableHookChain(g_hRGSetAnimation);
	
	return HAM_SUPERCEDE;
}
public HM_Knife_PrimaryAttack_Post(iItem)
{
	new id = get_member(iItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserKnife, id) || zp_get_user_zombie(id))
		return HAM_IGNORED;

	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	DisableHookChain(g_hRGSetAnimation);

	new Float:flGameTime = get_gametime();

	new Float:flLastAttackTime = Float:get_entvar(iItem, var_knife_last_attack);
	new iAnim = get_entvar(iItem, var_knife_primary_anim);
	new iCounter = get_entvar(iItem, var_knife_hit_counter);

	if(iAnim > ANIM_SLASH5)
		iAnim = ANIM_SLASH1;

	if(flLastAttackTime <= flGameTime)
	{
		iAnim = ANIM_SLASH1;
		iCounter = 1;
	}
	
	if(iCounter % 2)
		UTIL_PlayerAnimation(id, fmt("ref_shoot_%s", g_szKnifeRef));

	UTIL_AnimBlockAttack(id, iItem, iAnim, KNIFE_ATTACK_DELAY, ANIM_SLASH_TIME);

	set_entvar(id, var_punchangle, Float:{-1.0, 0.0, 0.0});

	set_entvar(iItem, var_knife_primary_anim, iAnim + 1);
	set_entvar(iItem, var_knife_hit_counter, iCounter + 1);
	set_entvar(iItem, var_knife_last_attack, flGameTime + KNIFE_ATTACK_DELAY + 0.2);

	return HAM_IGNORED;
}

//Блокировка Player-анимаций аттак
public RG_Player_SetAnimation_Pre(id, PLAYER_ANIM:pAnim)
{
	if(!IsSetBit(g_iBitUserKnife, id) || zp_get_user_zombie(id) || get_user_weapon(id) != CSW_KNIFE)
		return HC_CONTINUE;

	if(pAnim != PLAYER_ATTACK1 && pAnim != PLAYER_ATTACK2)
		return HC_CONTINUE;

	return HC_BREAK;
}

public HM_Knife_SecondaryAttack_Pre(iItem)
{
	new id = get_member(iItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserKnife, id) || zp_get_user_zombie(id))
		return HAM_IGNORED;

	switch(get_member(iItem, m_Weapon_iWeaponState))
	{
		case CHARGE_NONE:
		{
			UTIL_AnimBlockAttack(id, iItem, ANIM_CHARGE_START, ANIM_CHARGE_START_TIME);
			//rh_emit_sound2(iItem, 0, CHAN_WEAPON, g_szSndChargeStart);

			set_member(iItem, m_Weapon_iWeaponState, CHARGE_START);
		}
		case CHARGE_START:
		{
			UTIL_AnimBlockAttack(id, iItem, ANIM_CHARGE_IDLE_NOT_FINISH, ANIM_CHARGE_IDLE_TIME);

			set_member(iItem, m_Weapon_iWeaponState, CHARGE_LOAD);
		}
		case CHARGE_LOAD:
		{
			UTIL_AnimBlockAttack(id, iItem, ANIM_CHARGE_FINISH, ANIM_CHARGE_FINISH_TIME);
			//rh_emit_sound2(iItem, 0, CHAN_WEAPON, g_szSndChargeFinish);

			set_member(iItem, m_Weapon_iWeaponState, CHARGE_FINISH);
		}
		case CHARGE_FINISH, CHARGE_FINISH_IDLE:
		{
			UTIL_AnimBlockAttack(id, iItem, ANIM_CHARGE_IDLE_FINISH, ANIM_CHARGE_IDLE_TIME);

			set_member(iItem, m_Weapon_iWeaponState, CHARGE_FINISH_IDLE);
		}
	}

	return HAM_SUPERCEDE;
}

public HM_Knife_PreFrame_Post(iItem)
{
	new id = get_member(iItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserKnife, id) || zp_get_user_zombie(id))
		return HAM_IGNORED;

	new iState = get_member(iItem, m_Weapon_iWeaponState)

	if(iState == CHARGE_NONE || get_entvar(id, var_button) & IN_ATTACK2)
		return HAM_IGNORED;

	if(iState <= CHARGE_LOAD)
	{
		ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
		set_entvar(id, var_punchangle, Float:{-2.0, 0.0, 0.0});

		UTIL_AnimBlockAttack(id, iItem, ANIM_CHARGE_ATTACK_NOT_FINISH, ANIM_CHARGE_ATTACK_TIME);
	}
	else
	{
		Create_FakeAttack(id, CHARGE_DISTANCE, CHARGE_DMG);
		set_entvar(id, var_punchangle, Float:{-2.0, 0.0, 0.0});

		UTIL_AnimBlockAttack(id, iItem, ANIM_CHARGE_ATTACK_FINISH, ANIM_CHARGE_ATTACK_TIME);
		UTIL_PlayerAnimation(id, fmt("ref_shoot_%s", g_szKnifeRef));
		
		rh_emit_sound2(id, 0, CHAN_WEAPON, g_szSndChargeAttack);
	}

	set_member(iItem, m_Weapon_iWeaponState, CHARGE_NONE);
	return HAM_IGNORED;

}

stock Create_FakeAttack(id, Float:flDistance, Float:flDamage)
{
	new tr = create_tr2(), Trie:tEntsDamaged = TrieCreate();

	new Float:flAttackHeight, Float:flAttackWidth, bool:bExploded;

	flAttackHeight = 0.0;
	Trace_FakeAttackByAngles(id, tr, bExploded, flDistance, flDamage, flAttackWidth, flAttackHeight, tEntsDamaged);

	flAttackHeight = ATTACK_STEP;
	while(flAttackHeight < ATTACK_HEIGHT / 2.0)
	{
		Trace_FakeAttackByAngles(id, tr, bExploded, flDistance, flDamage, flAttackWidth, flAttackHeight, tEntsDamaged);
		Trace_FakeAttackByAngles(id, tr, bExploded, flDistance, flDamage, flAttackWidth, -flAttackHeight, tEntsDamaged);
		flAttackHeight += ATTACK_STEP;
	}

	flAttackWidth = ATTACK_STEP;
	while(flAttackWidth < ATTACK_WIDTH / 2.0)
	{
		flAttackHeight = 0.0;
		Trace_FakeAttackByAngles(id, tr, bExploded, flDistance, flDamage, flAttackWidth, flAttackHeight, tEntsDamaged);


		flAttackHeight = ATTACK_STEP;
		while(flAttackHeight < ATTACK_HEIGHT / 2.0)
		{
			Trace_FakeAttackByAngles(id, tr, bExploded, flDistance, flDamage, flAttackWidth, flAttackHeight, tEntsDamaged);
			Trace_FakeAttackByAngles(id, tr, bExploded, flDistance, flDamage, flAttackWidth, -flAttackHeight, tEntsDamaged);
			flAttackHeight += ATTACK_STEP;
		}

		flAttackHeight = ATTACK_STEP;
		while(flAttackHeight < ATTACK_WIDTH / 2.0)
		{
			Trace_FakeAttackByAngles(id, tr, bExploded, flDistance, flDamage, -flAttackWidth, flAttackHeight, tEntsDamaged);
			Trace_FakeAttackByAngles(id, tr, bExploded, flDistance, flDamage, -flAttackWidth, -flAttackHeight, tEntsDamaged);
			flAttackHeight += ATTACK_STEP;
		}

		flAttackWidth += ATTACK_STEP;
	}

	free_tr2(tr);
	TrieDestroy(tEntsDamaged);
}

//TraceAttack по углу flAttackWidth и flAttackHeight
stock Trace_FakeAttackByAngles(id, tr, &bExploded, Float:flDistance, Float:flDamage, Float:flAttackWidth, Float:flAttackHeight, Trie:tEntsDamaged)
{
	new Float:vecOrigin[3]; get_entvar(id, var_origin, vecOrigin);
	new Float:vecViewOfs[3]; get_entvar(id, var_view_ofs, vecViewOfs);
	new Float:vecAngles[3]; get_entvar(id, var_v_angle, vecAngles);
	new Float:vecDir[3], Float:vecBack[3];
	new Float:vecStart[3], Float:vecEnd[3];

	vecAngles[0] += flAttackHeight;
	vecAngles[1] += flAttackWidth;

	//Получение вектора направления камеры
	angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecDir);

	xs_vec_add(vecViewOfs, vecOrigin, vecStart);
	
	//Получение конечного вектора
	xs_vec_mul_scalar(vecDir, flDistance, vecEnd);
	xs_vec_add(vecEnd, vecStart, vecEnd);

	//Получение начального вектора
	xs_vec_mul_scalar(vecDir, -10.0, vecBack)
	xs_vec_add(vecStart, vecBack, vecStart);

	//Trace Attack
	Trace_AccrosPlayers(tEntsDamaged, bExploded, flDamage, vecStart, vecEnd, DONT_IGNORE_MONSTERS, id, tr)
}


stock Trace_AccrosPlayers(Trie:tEntsDamaged, &bExploded, Float:flDamage, Float:vecTraceStart[3], Float:vecTraceEnd[3], iMonsterIgnore, pPlayer, tr)
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

		get_tr2(tr, TR_vecEndPos, vecEndPos);

		if(!bExploded)
		{
			CREATE_EXPLOSION(vecEndPos, g_iMDLIndexExplode, 2, 1, 0);
			bExploded = true;
		}

		if(flFraction == 1.0) return max(HIT_NONE, iHitType);

		flCurrentDist = flDist * flFraction;
		flDist -= flCurrentDist;

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
	
	if(IsPlayer(iVictim)) set_member(iVictim, m_LastHitGroup, iHitgroup)
	
	switch(iHitgroup) 
	{
		case HIT_HEAD:                  flDamage *= 1.5;
		case HIT_LEFTARM, HIT_RIGHTARM: flDamage *= 1.0;
		case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 1.0;
		case HIT_STOMACH:               flDamage *= 1.25;
	}
	
	ExecuteHamB(Ham_TakeDamage, iVictim, iAttacker, iAttacker, flDamage, bDamageBits);
	if(!IsNPC(iVictim)) FakeKnockBack(iVictim, vecDirection, CHARGE_KNOCK);
	
	if(iBloodColor != DONT_BLEED) 
	{
		ExecuteHamB(Ham_TraceBleed, iVictim, flDamage, vecDirection, pTrace, bDamageBits);
		UTIL_BloodDrips(vecEndPos, iBloodColor, floatround(flDamage));
	}

	TrieSetCell(tEntsDamaged, fmt("%d", iVictim), 1);
	return 1;
}

public FakeKnockBack(pPlayer, Float:vecDirection[3], Float:flKnockBack) 
{
	set_member(pPlayer, m_flVelocityModifier, 1.0);
	static Float:vecVelocity[3]; get_entvar(pPlayer, var_velocity, vecVelocity);
	if(get_entvar(pPlayer, var_flags) & FL_DUCKING) flKnockBack *= 0.7;
	vecVelocity[0] = vecDirection[0] * flKnockBack;
	vecVelocity[1] = vecDirection[1] * flKnockBack;
	vecVelocity[2] = 150.0;
	set_entvar(pPlayer, var_velocity, vecVelocity);
}

public UTIL_BloodDrips(Float:vecOrigin[3], iColor, iAmount) {
	if(iAmount > 255) iAmount = 255;
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(g_iMDLIndexBloodSpray);
	write_short(g_iMDLIndexBloodDrop);
	write_byte(iColor);
	write_byte(min(max(3,iAmount/10),16));
	message_end();
}

stock UTIL_AnimBlockAttack(iPlayer, iItem, iAnim, Float:flNextAttack, Float:flNextIdle = 0.0)
{
	UTIL_SendWeaponAnim(iPlayer, iAnim);

	set_member(iItem, m_Weapon_flNextPrimaryAttack, flNextAttack);
	set_member(iItem, m_Weapon_flNextSecondaryAttack, flNextAttack);
	set_member(iItem, m_Weapon_flTimeWeaponIdle, flNextIdle == 0.0 ? flNextAttack : flNextIdle);
}

stock UTIL_SendWeaponAnim(iPlayer, iAnim, iBody = 0)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(iBody);
	message_end();

	if(!iBody) return;

	static i, iCount, iSpectator, iszSpectators[32];

	if(pev(iPlayer, pev_iuser1)) return;

	get_players(iszSpectators, iCount, "bch");

	for(i = 0; i < iCount; i++)
	{
		iSpectator = iszSpectators[i];

		if(pev(iSpectator, pev_iuser1) != OBS_IN_EYE) continue;
		if(pev(iSpectator, pev_iuser2) != iPlayer) continue;

		set_pev(iSpectator, pev_weaponanim, iAnim);

		message_begin(MSG_ONE, SVC_WEAPONANIM, _, iSpectator);
		write_byte(iAnim);
		write_byte(iBody);
		message_end();
	}
}

stock UTIL_PlayerAnimation(pPlayer, const szAnimation[]) 
{ 
	static iAnimDesired, Float:flFrameRate, Float:flGroundSpeed, bool:bLoops;
	if((iAnimDesired = lookup_sequence(pPlayer, szAnimation, flFrameRate, bLoops, flGroundSpeed)) == -1) iAnimDesired = 0;
	
	static Float:flGameTime; flGameTime = get_gametime();
	
	set_entvar(pPlayer, var_frame, 5.0);
	set_entvar(pPlayer, var_animtime, flGameTime);
	set_entvar(pPlayer, var_sequence, iAnimDesired);
	set_entvar(pPlayer, var_framerate, 1.0);
	
	set_member(pPlayer, m_fSequenceLoops, bLoops);
	set_member(pPlayer, m_fSequenceFinished, 0);
	set_member(pPlayer, m_flFrameRate, flFrameRate);
	set_member(pPlayer, m_flGroundSpeed, flGroundSpeed);
	set_member(pPlayer, m_flLastEventCheck, flGameTime);
	set_member(pPlayer, m_Activity, ACT_RANGE_ATTACK1);
	set_member(pPlayer, m_IdealActivity, ACT_RANGE_ATTACK1);
	set_member(pPlayer, m_flLastFired, flGameTime);
}

stock CREATE_EXPLOSION(Float:vecOrigin[3], pSprite, iScale, iFrameRate, iFlags)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION) 
	engfunc(EngFunc_WriteCoord, vecOrigin[0]) 
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2]) 
	write_short(pSprite)
	write_byte(iScale)
	write_byte(iFrameRate)
	write_byte(iFlags)
	message_end()
}