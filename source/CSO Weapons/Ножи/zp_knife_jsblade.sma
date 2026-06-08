#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <zombieplague>
#include <zp_system>
#include <xs>
#include <smart_effects>

#include <zmcso/smart_messages>

//Player Animation Reference
new const g_szKnifeRef[] = "katanad";

//Settings Fake TraceLines
#define ATTACK_STEP 10.0 // Шаг TraceAttack

#define ATTACK_PRIMARY_DIST 	64.0
#define ATTACK_PRIMARY_DAMAGE 	313.5
#define ATTACK_PRIMARY_WIDTH 	30.0
#define ATTACK_PRIMARY_HEIGHT 	10.0
#define ATTACK_PRIMARY_KNOC		120.0

#define ATTACK_SECONDARY_DIST 	64.0
#define ATTACK_SECONDARY_DAMAGE 	718.5
#define ATTACK_SECONDARY_WIDTH 	60.0
#define ATTACK_SECONDARY_HEIGHT 	20.0
#define ATTACK_SECONDARY_KNOC		927.5

//Delay primary attack
#define KNIFE_ATTACK_PRIMARY_DELAY 0.55

//Delay secondary attack
#define KNIFE_ATTACK_SECONDARY_DELAY 1.6


new const g_szSndHits[][] =
{
	"zp_br_cso/knifes_b1/jsblade/zbs64knife_hit1.wav",
	"zp_br_cso/knifes_b1/jsblade/zbs64knife_hit2.wav",
	"zp_br_cso/knifes_b1/jsblade/zbs64knife_hit3.wav"
};

new const g_szSndPrimary[][] =
{
	"zp_br_cso/knifes_b1/jsblade/zbs64knife_midslash1.wav", 
	"zp_br_cso/knifes_b1/jsblade/zbs64knife_midslash2.wav", 
	"zp_br_cso/knifes_b1/jsblade/zbs64knife_midslash3.wav"
};

new const g_szSndSecondary[][] =
{
	"zp_br_cso/knifes_b1/jsblade/stab.wav",
	"zp_br_cso/knifes_b1/jsblade/stab_miss.wav"
}

new const g_szSndWallHits[][] =
{
	"zp_br_cso/knifes_b1/jsblade/zbs64knife_wall.wav"
};

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))

enum
{
	ANIM_IDLE = 0,

	ANIM_SLASH1,
	ANIM_SLASH2,

	ANIM_DRAW,

	ANIM_STAB,
	ANIM_STAB_MISS,

	ANIM_MIDSLASH1,
	ANIM_MIDSLASH2,
	ANIM_MIDSLASH3

}

#define ANIM_IDLE_TIME 251.0/30.0
#define ANIM_SLASH1_TIME 26.0/30.0
#define ANIM_SLASH2_TIME 38.0/30.0
#define ANIM_DRAW_TIME 21.0/30.0
#define ANIM_STAB_TIME 38.0/30.0
#define ANIM_STAB_MISS_TIME 46.0/30.0
#define ANIM_MIDSLASH_TIME 26.0/30.0

#define ATTACK_SECONDARY1_TIME 13.0/30.0

enum _: e_HitResultList
{
	SLASH_HIT_NONE = 0,
	SLASH_HIT_WORLD,
	SLASH_HIT_ENTITY
};

enum _: ATTACK_SECONARY_STATE
{
	SEC_NONE = 0,
	SEC_ATTACK1,
}

#define var_knife_second_time var_fuser1

//Attack's Counter 
#define var_knife_primary_anim var_iuser1

//Last Attack Knife
#define var_knife_last_attack var_ltime

//Hits counter
#define var_knife_hit_counter var_iuser2

native zp_register_knife(const szName[]);
forward zp_knife_selected(id, iKnife, iOldKnife);

//User variable
new g_iBitUserKnife;

new g_iKnife;

new HookChain:g_hRGSetAnimation;

new g_iszModelIndexBloodSpray,
	g_iszModelIndexBloodDrop;

public plugin_precache()
{
	precache_array_sound(g_szSndHits, sizeof g_szSndHits);
	precache_array_sound(g_szSndPrimary, sizeof g_szSndPrimary);
	precache_array_sound(g_szSndSecondary, sizeof g_szSndSecondary);
	precache_array_sound(g_szSndWallHits, sizeof g_szSndWallHits);

	// Model Index
	g_iszModelIndexBloodSpray = precache_model("sprites/bloodspray.spr");
	g_iszModelIndexBloodDrop = precache_model("sprites/blood.spr");

}

public plugin_init()
{
	register_plugin("[ZPE] Knife : J's blade", "1.0", "Docaner");

	register_forward(FM_UpdateClientData, "Meta_UpdateClientData_Post", true);

	RegisterHam(Ham_Spawn, "player", "HM_PlayerSpawn_Post", true);

	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_knife", "HM_Knife_Idle_Pre", false);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "HM_Knife_Deploy_Post", true);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "HM_Knife_PrimaryAttack_Pre", false);	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "HM_Knife_PrimaryAttack_Post", true);	
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "HM_Knife_SecondaryAttack_Pre", false);	
	RegisterHam(Ham_Item_PreFrame, "weapon_knife", "HM_Knife_PreFrame_Post", true);	
	
	DisableHookChain(g_hRGSetAnimation = RegisterHookChain(RG_CBasePlayer_SetAnimation, "RG_Player_SetAnimation_Pre", false));

	g_iKnife = zp_register_knife("Dagger [AGENT]");
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

	set_cd(iCD, CD_flNextAttack, get_gametime() + 2.01);
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
	set_member(iItem, m_Weapon_flTimeWeaponIdle,  ANIM_IDLE_TIME);

	return HAM_SUPERCEDE;
}

public HM_Knife_Deploy_Post(iItem)
{
	new id = get_member(iItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserKnife, id) || zp_get_user_zombie(id))
		return HAM_IGNORED;

	//set_entvar(iItem, var_knife_primary_anim, ANIM_SLASH1);
	set_member(iItem, m_Weapon_iWeaponState, SEC_NONE);

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

	//ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	DisableHookChain(g_hRGSetAnimation);

	FakeTraceLine(id, 1, ATTACK_PRIMARY_DIST, ATTACK_PRIMARY_DAMAGE, ATTACK_PRIMARY_WIDTH, ATTACK_PRIMARY_HEIGHT, ATTACK_PRIMARY_KNOC);

	new Float:flGameTime = get_gametime();

	new Float:flLastAttackTime = Float:get_entvar(iItem, var_knife_last_attack);
	new iAnim = get_entvar(iItem, var_knife_primary_anim);
	new iCounter = get_entvar(iItem, var_knife_hit_counter);

	if(iAnim > ANIM_MIDSLASH3)
		iAnim = ANIM_MIDSLASH1;

	if(flLastAttackTime <= flGameTime)
	{
		iAnim = ANIM_MIDSLASH1;
		iCounter = 1;
	}
	
	if(iCounter % 2)
		rg_set_animation(id, PLAYER_ATTACK1)

	UTIL_AnimBlockAttack(id, iItem, iAnim, KNIFE_ATTACK_PRIMARY_DELAY, ANIM_MIDSLASH_TIME);

	//set_entvar(id, var_punchangle, Float:{-1.5, 0.0, 0.0});

	set_entvar(iItem, var_knife_primary_anim, iAnim + 1);
	set_entvar(iItem, var_knife_hit_counter, iCounter + 1);
	set_entvar(iItem, var_knife_last_attack, flGameTime + KNIFE_ATTACK_PRIMARY_DELAY + 0.05);

	return HAM_IGNORED;
}

public HM_Knife_SecondaryAttack_Pre(iItem)
{
	new id = get_member(iItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserKnife, id) || zp_get_user_zombie(id))
		return HAM_IGNORED;

	rg_set_animation(id, PLAYER_ATTACK1)
	play_random_sound(id, g_szSndSecondary, sizeof g_szSndSecondary);
	//set_member(id, m_flNextAttack, 0.0);

	UTIL_AnimBlockAttack(id, iItem, ANIM_STAB, KNIFE_ATTACK_SECONDARY_DELAY, ANIM_STAB_TIME);

	set_member(iItem, m_Weapon_iWeaponState, SEC_ATTACK1);
	set_entvar(iItem, var_knife_second_time, get_gametime() + ATTACK_SECONDARY1_TIME);

	return HAM_SUPERCEDE;
}

public HM_Knife_PreFrame_Post(iItem)
{
	new id = get_member(iItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserKnife, id) || zp_get_user_zombie(id))
		return HAM_IGNORED;

	new iState = get_member(iItem, m_Weapon_iWeaponState)

	if(!iState)
		return HAM_IGNORED;

	new Float:flGameTime = get_gametime(), 
		Float:flTimeAttack = Float:get_entvar(iItem, var_knife_second_time);

	switch(iState)
	{
		case SEC_ATTACK1:
		{
			if(flGameTime >= flTimeAttack)
			{
				set_member(iItem, m_Weapon_iWeaponState, SEC_NONE);
				FakeTraceLine(id, 0, ATTACK_SECONDARY_DIST, ATTACK_SECONDARY_DAMAGE, ATTACK_SECONDARY_WIDTH, ATTACK_SECONDARY_HEIGHT, ATTACK_SECONDARY_KNOC);
				//set_entvar(iItem, var_knife_second_time, flGameTime + ATTACK_SECONDARY2_TIME)
			}
		}
	}

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

public FakeTraceLine(iPlayer, iAttackPrimary, Float: flDistance, Float: flDamage, const Float:flWidth, const Float:flHeight, const Float:flKnock)
{
	new iHitResult = Create_FakeAttack(iPlayer, flDistance, flDamage, flHeight, flWidth, flKnock);

	switch(iHitResult)
	{
		case SLASH_HIT_NONE:
		{
			if(iAttackPrimary)
				play_random_sound(iPlayer, g_szSndPrimary, sizeof g_szSndPrimary);
		}
		case SLASH_HIT_WORLD:
		{
			play_random_sound(iPlayer, g_szSndWallHits, sizeof g_szSndWallHits);
		}
		case SLASH_HIT_ENTITY:
		{
			play_random_sound(iPlayer, g_szSndHits, sizeof g_szSndHits);
		}
	}

	/*static Float: vecPunchangle[3];
	vecPunchangle[0] = random_float(-1.7, 1.7);
	vecPunchangle[1] = random_float(-1.7, 1.7);
	set_pev(iPlayer, pev_punchangle, vecPunchangle);*/

}

stock Create_FakeAttack(id, Float:flDistance, Float:flDamage, const Float:flMaxHeight, const Float:flMaxWidth, const Float:flKnock)
{
	new tr = create_tr2(), Trie:tEntsDamaged = TrieCreate(), iHitAim, iHitResult;

	new Float:flAttackHeight, Float:flAttackWidth;

	flAttackHeight = 0.0;
	iHitAim = Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, flAttackWidth, flAttackHeight, tEntsDamaged, flKnock);

	flAttackHeight = ATTACK_STEP;
	while(flAttackHeight < flMaxHeight / 2.0)
	{
		iHitResult = max(iHitResult, Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, flAttackWidth, flAttackHeight, tEntsDamaged, flKnock));
		iHitResult = max(iHitResult, Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, flAttackWidth, -flAttackHeight, tEntsDamaged, flKnock));
		flAttackHeight += ATTACK_STEP;
	}

	flAttackWidth = ATTACK_STEP;
	while(flAttackWidth < flMaxWidth / 2.0)
	{
		flAttackHeight = 0.0;
		iHitResult = max(iHitResult, Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, flAttackWidth, flAttackHeight, tEntsDamaged, flKnock));


		flAttackHeight = ATTACK_STEP;
		while(flAttackHeight < flMaxHeight / 2.0)
		{
			iHitResult = max(iHitResult, Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, flAttackWidth, flAttackHeight, tEntsDamaged, flKnock));
			iHitResult = max(iHitResult, Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, flAttackWidth, -flAttackHeight, tEntsDamaged, flKnock));
			flAttackHeight += ATTACK_STEP;
		}

		flAttackHeight = ATTACK_STEP;
		while(flAttackHeight < flMaxWidth / 2.0)
		{
			iHitResult = max(iHitResult, Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, -flAttackWidth, flAttackHeight, tEntsDamaged, flKnock));
			iHitResult = max(iHitResult, Trace_FakeAttackByAngles(id, tr, flDistance, flDamage, -flAttackWidth, -flAttackHeight, tEntsDamaged, flKnock));
			flAttackHeight += ATTACK_STEP;
		}

		flAttackWidth += ATTACK_STEP;
	}

	free_tr2(tr);
	TrieDestroy(tEntsDamaged);

	return iHitResult < SLASH_HIT_ENTITY ? iHitAim : iHitResult;
}

//TraceAttack по углу flAttackWidth и flAttackHeight
stock Trace_FakeAttackByAngles(id, tr, Float:flDistance, Float:flDamage, Float:flAttackWidth, Float:flAttackHeight, Trie:tEntsDamaged, const Float:flKnock)
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
	return Trace_AccrosEnts(tEntsDamaged, flDamage, vecStart, vecEnd, DONT_IGNORE_MONSTERS, id, tr, flKnock)
}

stock Trace_AccrosEnts(Trie:tEntsDamaged, Float:flDamage, Float:vecTraceStart[3], Float:vecTraceEnd[3], iMonsterIgnore, pPlayer, tr, const Float:flKnock)
{
	new iHitType = SLASH_HIT_NONE,
		Float:flCurrentDist,
		Float:flDist = get_distance_f(vecTraceStart, vecTraceEnd),
		Float:vecDir[3],
		pHit = pPlayer,
		Float:flFraction,
		Float:vecEndPos[3];

	xs_vec_sub(vecTraceEnd, vecTraceStart, vecDir);
	xs_vec_normalize(vecDir, vecDir);

	new Float:vecSliceStart[3]; xs_vec_copy(vecTraceStart, vecSliceStart);

	while(flCurrentDist < flDist)
	{
		engfunc(EngFunc_TraceLine, vecSliceStart, vecTraceEnd, iMonsterIgnore, pHit, tr);
		get_tr2(tr, TR_flFraction, flFraction);

		get_tr2(tr, TR_vecEndPos, vecEndPos);

		if(flFraction == 1.0) return max(SLASH_HIT_NONE, iHitType);

		flCurrentDist = flDist * flFraction;
		flDist -= flCurrentDist;

		xs_vec_add(vecEndPos, vecDir, vecSliceStart);
		pHit = get_tr2(tr, TR_pHit);

		// client_print(pPlayer, print_chat, "pHit: %d | is_null: %s | is_user_alive: %s", pHit, is_nullent(pHit) ? "true" : "flase", is_user_alive(pHit) ? "true" : "flase");

		if(is_nullent(pHit)) return max(SLASH_HIT_WORLD, iHitType);

		if(pHit == pPlayer) 
			continue;

		

		if(pev(pHit, pev_solid) == SOLID_BSP)
		{
			if(~pev(pHit, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY && Float:get_entvar(pHit, var_health) != 0.0) 
			{
				ExecuteHamB(Ham_TakeDamage, pHit, pPlayer, pPlayer, flDamage, DMG_NEVERGIB | DMG_CLUB);

				// client_print(0, print_chat, "pHit: %d | spawnflags: %d | health: %f", pHit, pev(pHit, pev_spawnflags), Float:get_entvar(pHit, var_health))

				iHitType = max(SLASH_HIT_WORLD, iHitType);
			}
			else	
				return max(SLASH_HIT_WORLD, iHitType);
		}
		
		if(FakeTraceAttack(tEntsDamaged, pHit, pPlayer, flDamage, vecDir, tr, DMG_NEVERGIB | DMG_CLUB, flKnock)) 
		{
			// new trTest = create_tr2()

			// engfunc(EngFunc_TraceLine, vecTraceStart, vecEndPos, iMonsterIgnore, pPlayer, trTest);

			// get_tr2(tr, TR_flFraction, flFraction);
			// get_tr2(tr, TR_vecEndPos, vecEndPos);
			// pHit = get_tr2(tr, TR_pHit);

			// free_tr2(trTest);

			// client_print(0, print_chat, "pHit: %d | flFraction: %f | vecEndPos: %f %f %f", pHit, flFraction, vecEndPos[0], vecEndPos[1], vecEndPos[2]);

			// MSG_Line(0, vecTraceStart, vecEndPos, 10.0, {255, 0, 0})

			iHitType = max(SLASH_HIT_ENTITY, iHitType);
		}
	}
	return iHitType;
}


public FakeTraceAttack(Trie:tEntsDamaged, iVictim, iAttacker, Float:flDamage, Float:vecDirection[3], pTrace, bDamageBits, const Float:flKnock) 
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
	if(!IsNPC(iVictim)) FakeKnockBack(iVictim, vecDirection, flKnock);
	
	if(iBloodColor != DONT_BLEED) 
	{
		ExecuteHamB(Ham_TraceBleed, iVictim, flDamage, vecDirection, pTrace, bDamageBits);
		UTIL_BloodDrips(vecEndPos, iBloodColor, floatround(flDamage));
	}

	TrieSetCell(tEntsDamaged, fmt("%d", iVictim), 1);
	return 1;
}

public FakeKnockBack(iVictim, Float: vecDirection[3], Float: flKnockBack) 
{
	if(!(is_user_alive(iVictim) && zp_get_user_zombie(iVictim))) return 0;

	set_member(iVictim, m_flVelocityModifier, 1.0);

	static Float:vecVelocity[3]; pev(iVictim, pev_velocity, vecVelocity);

	new iFlags = get_entvar(iVictim, var_flags)
	if(iFlags & FL_DUCKING || ~iFlags & FL_ONGROUND) 
		flKnockBack *= 0.45

	vecVelocity[0] = vecDirection[0] * flKnockBack;
	vecVelocity[1] = vecDirection[1] * flKnockBack;

	set_pev(iVictim, pev_velocity, vecVelocity);
	
	return 1;
}

public UTIL_BloodDrips(Float:vecOrigin[3], iColor, iAmount)
{
	if(iAmount > 255) iAmount = 255;
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(g_iszModelIndexBloodSpray);
	write_short(g_iszModelIndexBloodDrop);
	write_byte(iColor);
	write_byte(min(max(3,iAmount/10),16));
	message_end();
}

stock precache_array_sound(const szArray[][], iLen)
	for(new i; i < iLen; i++) precache_sound(szArray[i]);

stock play_random_sound(id, const szArray[][], iLen)
	rh_emit_sound2(id, 0, CHAN_WEAPON, szArray[random(iLen)]);