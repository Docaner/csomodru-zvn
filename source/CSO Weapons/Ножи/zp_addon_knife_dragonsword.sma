#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>

#define IsCustomItem(%1)			(get_pdata_int(%1, m_iId, linux_diff_weapon) == CSW_KNIFE)
#define IsUserHasDragonSword(%1)	Get_Bit(gl_iBitUserHasDragonSword, %1)

#define Get_Bit(%1,%2)				((%1 & (1 << (%2 & 31))) ? 1 : 0)
#define Set_Bit(%1,%2)				%1 |= (1 << (%2 & 31))
#define Reset_Bit(%1,%2)			%1 &= ~(1 << (%2 & 31))
#define Invert_Bit(%1,%2)			((%1) ^= (1 << (%2)))

#define msgWeaponList 				78
#define msgWeapPickup				92

#define PDATA_SAFE					2
#define OBS_IN_EYE					4
#define DONT_BLEED					-1
#define ACT_RANGE_ATTACK1			28

// Linux extra offsets
#define linux_diff_animating		4
#define linux_diff_weapon 			4
#define linux_diff_player 			5

// CBaseAnimating
#define m_flFrameRate 				36
#define m_flGroundSpeed 			37
#define m_flLastEventCheck 			38
#define m_fSequenceFinished 		39
#define m_fSequenceLoops			40

// CBasePlayerItem
#define m_pPlayer					41
#define m_iId 						43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack 		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle 			48
#define m_iGlock18ShotsFired 		70 // slash type
#define m_iWeaponState				74 // attack type

// CBaseMonster
#define m_Activity 					73
#define m_IdealActivity				74
#define m_LastHitGroup				75
#define m_flNextAttack 				83

// CBasePlayer
#define m_iPlayerTeam				114
#define m_flLastAttackTime			220
#define m_pActiveItem 				373
#define m_szAnimExtention 			492

#define ANIM_IDLE_TIME				541/30.0
#define ANIM_SLASH_1_TIME			46/30.0 // hit: 18/30.0
#define ANIM_SLASH_2_TIME			31/30.0 // hit: 5/30.0
#define ANIM_DRAW_TIME				56/30.0
#define ANIM_STAB_START_TIME		25/35.0
#define ANIM_STAB_HIT_TIME			37/30.0

enum _: e_AnimList
{
	ANIM_IDLE = 0,
	ANIM_SLASH_1,
	ANIM_SLASH_2,
	ANIM_DRAW,
	ANIM_STAB_START,
	ANIM_STAB_HIT
};

enum _: e_SlashState
{
	STATE_NONE = 0,
	STATE_SLASH,
	STATE_STAB
};

enum _: e_HitResultList
{
	SLASH_HIT_NONE = 0,
	SLASH_HIT_WORLD,
	SLASH_HIT_ENTITY
};

#define WEAPON_REFERENCE			"weapon_knife"

#define KNIFE_ANIM_EXTENSION		"knife" // Original CSO: dragonsword
#define KNIFE_WEAPONLIST			"x/knife_dragonsword" // Weapon List [ Чтобы отключить - закоментируй ]
#define KNIFE_VIEW_MODEL			"models/x/v_dragonsword_fx.mdl"
#define KNIFE_PLAYER_MODEL			"models/x/p_dragonsword.mdl"

#define KNIFE_SLASH_1_DAMAGE 450.0
#define KNIFE_SLASH_1_DISTANCE 100.0

new Float: flAngles_Slash1[] = { 0.0, -2.5, 2.5, -5.0, 5.0, -7.5, 7.5, -10.0, 10.0, -12.5, 12.5, -15.0, 15.0, -17.5, -17.5 };
new Float: flAnglesUp_Slash1[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };

#define KNIFE_SLASH_2_DAMAGE KNIFE_SLASH_1_DAMAGE // In CSNZ damage slash2 = damage slash1 (if u want, u can change)
#define KNIFE_SLASH_2_DISTANCE KNIFE_SLASH_1_DISTANCE // In CSNZ distance slash2 = distance slash1 (if u want, u can change)

new Float: flAngles_Slash2[] = { 0.0, 0.0, 0.0 };
new Float: flAnglesUp_Slash2[] = { 0.0, 0.0, 0.0 };

#define KNIFE_STAB_DAMAGE 310.0
#define KNIFE_STAB_DISTANCE 125.0

new Float: flAngles_Stab[] = { 0.0, -2.5, 2.5, -5.0, 5.0, -7.5, 7.5, -10.0, 10.0, -12.5, 12.5, -15.0, 15.0, -17.5, -17.5 };
new Float: flAnglesUp_Stab[] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };

new const KNIFE_SOUNDS[][] =
{
	"weapons/dragonsword_draw.wav", // 0
	"weapons/dragonsword_hit1.wav", // 1
	"weapons/dragonsword_hit2.wav", // 2
	"weapons/dragonsword_idle.wav", // 3
	"weapons/dragonsword_slash1.wav", // 4
	"weapons/dragonsword_slash2.wav", // 5
	"weapons/dragonsword_stab_hit.wav", // 6
	"weapons/dragonsword_wall.wav" // 7
};

new gl_iBitUserHasDragonSword,

	gl_iszModelIndexBloodSpray,
	gl_iszModelIndexBloodDrop,

	gl_iszAllocString_ModelView,
	gl_iszAllocString_ModelPlayer,

	gl_iItemID;

public plugin_init()
{
	register_plugin("[ZP] Knife: Dragon Sword", "1.0", "xUnicorn (t3rkecorejz)");

	gl_iItemID = zp_register_extra_item("Dragon Sword", 10, ZP_TEAM_HUMAN);

	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);

	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE, "CKnife__PostFrame_Pre", false);
	RegisterHam(Ham_Item_Deploy, 			WEAPON_REFERENCE, "CKnife__Deploy_Post", true);
	RegisterHam(Ham_Weapon_WeaponIdle, 		WEAPON_REFERENCE, "CKnife__Idle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,   WEAPON_REFERENCE, "CKnife__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,	WEAPON_REFERENCE, "CKnife__SecondaryAttack_Pre", false);

	#if defined KNIFE_WEAPONLIST
	register_clcmd(KNIFE_WEAPONLIST, "Command__HookWeapon");
	#endif
}

public plugin_precache()
{
	// Precache models
	engfunc(EngFunc_PrecacheModel, KNIFE_VIEW_MODEL);
	engfunc(EngFunc_PrecacheModel, KNIFE_PLAYER_MODEL);

	// Precache sounds
	for(new i = 0; i < sizeof KNIFE_SOUNDS; i++) 
		engfunc(EngFunc_PrecacheSound, KNIFE_SOUNDS[i]);

	#if defined KNIFE_WEAPONLIST
	// Precache generic
	UTIL_PrecacheSpritesFromTxt(KNIFE_WEAPONLIST);
	#endif

	// Other
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, KNIFE_VIEW_MODEL);
	gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, KNIFE_PLAYER_MODEL);

	// Model Index
	gl_iszModelIndexBloodSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr");
	gl_iszModelIndexBloodDrop = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr");
}

public plugin_natives()
{
	register_native("zp_give_user_dragonsword", "Command__GiveDragonSword", 1);
	register_native("zp_delete_user_dragonsword", "Command__DelDragonSword", 1);
}

public client_putinserver(iPlayer) Command__DelDragonSword(iPlayer);

public Command__HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

public Command__GiveDragonSword(iPlayer)
{
	Set_Bit(gl_iBitUserHasDragonSword, iPlayer);

	#if defined KNIFE_WEAPONLIST
		UTIL_WeapPickup(iPlayer, CSW_KNIFE);
		UTIL_SetWeaponList(iPlayer, KNIFE_WEAPONLIST, -1, -1, -1, -1, 2, 1, 29, 0);
	#endif

	new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(is_user_alive(iPlayer) && get_pdata_int(iItem, m_iId, linux_diff_weapon) == CSW_KNIFE)
	{
		if(pev_valid(iItem) == PDATA_SAFE)
		{
			ExecuteHamB(Ham_Item_Deploy, iItem);
		}
	}
}

public Command__DelDragonSword(iPlayer)
{
	Reset_Bit(gl_iBitUserHasDragonSword, iPlayer);

	#if defined KNIFE_WEAPONLIST
		UTIL_SetWeaponList(iPlayer, WEAPON_REFERENCE, -1, -1, -1, -1, 2, 1, 29, 0);
	#endif
}

/* [ Zombie Plague ] */
public zp_extra_item_selected(iPlayer, iItemID)
{
	if(iItemID != gl_iItemID) return PLUGIN_HANDLED;

	if(IsUserHasDragonSword(iPlayer))
	{
		client_print(iPlayer, print_center, "You have already [Dragon Sword]");
		return ZP_PLUGIN_HANDLED;
	}

	Command__GiveDragonSword(iPlayer);
	return PLUGIN_HANDLED;
}

public zp_user_infected_post(iPlayer)
{
	if(!is_user_connected(iPlayer)) return;

	if(IsUserHasDragonSword(iPlayer))
		Command__DelDragonSword(iPlayer);
}

/* [ Fakemeta ] */
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(!is_user_alive(iPlayer) || zp_get_user_zombie(iPlayer)) return;
	if(!IsUserHasDragonSword(iPlayer)) return;

	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(pev_valid(iItem) != PDATA_SAFE || !IsCustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

/* [ HamSandwich ] */
public CKnife__PostFrame_Pre(iItem)
{
	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!IsUserHasDragonSword(iPlayer) || zp_get_user_zombie(iPlayer)) return HAM_IGNORED;

	static iWeaponState; iWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);
	static iSlashType; iSlashType = get_pdata_int(iItem, m_iGlock18ShotsFired, linux_diff_weapon);
	static szAnimation[64];

	switch(iWeaponState)
	{
		case STATE_SLASH:
		{
			if(iSlashType)
			{
				UTIL_FakeTraceLine(iPlayer, 2, KNIFE_SLASH_2_DISTANCE, KNIFE_SLASH_2_DAMAGE, flAngles_Slash2, flAnglesUp_Slash2, sizeof flAngles_Slash2);
				emit_sound(iPlayer, CHAN_ITEM, KNIFE_SOUNDS[5], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
			else
			{
				UTIL_FakeTraceLine(iPlayer, 1, KNIFE_SLASH_1_DISTANCE, KNIFE_SLASH_1_DAMAGE, flAngles_Slash1, flAnglesUp_Slash1, sizeof flAngles_Slash1);
				emit_sound(iPlayer, CHAN_ITEM, KNIFE_SOUNDS[4], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			}
			
			iWeaponState = STATE_NONE;
			iSlashType = !iSlashType;

			formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", KNIFE_ANIM_EXTENSION);
			UTIL_PlayerAnimation(iPlayer, szAnimation);

			set_pdata_int(iItem, m_iWeaponState, iWeaponState, linux_diff_weapon);
			set_pdata_int(iItem, m_iGlock18ShotsFired, iSlashType, linux_diff_weapon);
		}
		case STATE_STAB:
		{
			UTIL_SendWeaponAnim(iPlayer, ANIM_STAB_HIT);
			UTIL_FakeTraceLine(iPlayer, 1, KNIFE_STAB_DISTANCE, KNIFE_STAB_DAMAGE, flAngles_Stab, flAnglesUp_Stab, sizeof flAngles_Stab);
			emit_sound(iPlayer, CHAN_ITEM, KNIFE_SOUNDS[6], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_STAB_HIT_TIME - 0.1, linux_diff_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_STAB_HIT_TIME - 0.1, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_STAB_HIT_TIME, linux_diff_weapon);

			iWeaponState = STATE_NONE;

			formatex(szAnimation, charsmax(szAnimation), pev(iPlayer, pev_flags) & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", KNIFE_ANIM_EXTENSION);
			UTIL_PlayerAnimation(iPlayer, szAnimation);

			set_pdata_int(iItem, m_iWeaponState, iWeaponState, linux_diff_weapon);
		}
	}

	return HAM_IGNORED;
}

public CKnife__Deploy_Post(iItem)
{
	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!IsUserHasDragonSword(iPlayer) || zp_get_user_zombie(iPlayer)) return;

	set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
	set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);

	UTIL_SendWeaponAnim(iPlayer, ANIM_DRAW);

	set_pdata_int(iItem, m_iWeaponState, STATE_NONE, linux_diff_weapon);
	set_pdata_int(iItem, m_iGlock18ShotsFired, 0, linux_diff_weapon);

	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_DRAW_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, ANIM_DRAW_TIME - 0.1, linux_diff_player);
	set_pdata_string(iPlayer, m_szAnimExtention * 4, KNIFE_ANIM_EXTENSION, -1, linux_diff_player * linux_diff_animating);
}

public CKnife__Idle_Pre(iItem)
{
	if(get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;

	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!IsUserHasDragonSword(iPlayer) || zp_get_user_zombie(iPlayer)) return HAM_IGNORED;

	UTIL_SendWeaponAnim(iPlayer, ANIM_IDLE);

	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CKnife__PrimaryAttack_Pre(iItem)
{
	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!IsUserHasDragonSword(iPlayer) || zp_get_user_zombie(iPlayer)) return HAM_IGNORED;

	static iSlashType; iSlashType = get_pdata_int(iItem, m_iGlock18ShotsFired, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, iSlashType ? ANIM_SLASH_2 : ANIM_SLASH_1);

	set_pdata_int(iItem, m_iWeaponState, STATE_SLASH, linux_diff_weapon);

	set_pdata_float(iPlayer, m_flNextAttack, iSlashType ? 5/30.0 : 18/30.0, linux_diff_player);
	set_pdata_float(iItem, m_flNextPrimaryAttack, iSlashType ? ANIM_SLASH_2_TIME : ANIM_SLASH_1_TIME - 0.1, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, iSlashType ? ANIM_SLASH_2_TIME : ANIM_SLASH_1_TIME - 0.1, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, iSlashType ? ANIM_SLASH_2_TIME : ANIM_SLASH_1_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CKnife__SecondaryAttack_Pre(iItem)
{
	new iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!IsUserHasDragonSword(iPlayer) || zp_get_user_zombie(iPlayer)) return HAM_IGNORED;

	UTIL_SendWeaponAnim(iPlayer, ANIM_STAB_START);

	set_pdata_int(iItem, m_iWeaponState, STATE_STAB, linux_diff_weapon);

	set_pdata_float(iPlayer, m_flNextAttack, ANIM_STAB_START_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_STAB_START_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_STAB_START_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_STAB_START_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

/* [ Stocks ] */
stock UTIL_SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_PlayerAnimation(iPlayer, szAnim[])
{
	new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
		
	if((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
		iAnimDesired = 0;
	
	new Float: flGameTime = get_gametime();

	set_pev(iPlayer, pev_frame, 0.0);
	set_pev(iPlayer, pev_framerate, 1.0);
	set_pev(iPlayer, pev_animtime, flGameTime);
	set_pev(iPlayer, pev_sequence, iAnimDesired);
	
	set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, linux_diff_animating);
	set_pdata_int(iPlayer, m_fSequenceFinished, 0, linux_diff_animating);
	
	set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, linux_diff_animating);
	set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, linux_diff_animating);
	set_pdata_float(iPlayer, m_flLastEventCheck, flGameTime , linux_diff_animating);
	
	set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, linux_diff_player);
	set_pdata_float(iPlayer, m_flLastAttackTime, flGameTime , linux_diff_player);
}

stock UTIL_PrecacheSpritesFromTxt(szWeaponList[])
{
	new szTxtDir[64], szSprDir[64]; 
	new szFileData[128], szSprName[48], temp[1];

	format(szTxtDir, charsmax(szTxtDir), "sprites/%s.txt", szWeaponList);
	engfunc(EngFunc_PrecacheGeneric, szTxtDir);

	new iFile = fopen(szTxtDir, "rb");
	while(iFile && !feof(iFile)) 
	{
		fgets(iFile, szFileData, charsmax(szFileData));
		trim(szFileData);

		if(!strlen(szFileData)) 
			continue;

		new pos = containi(szFileData, "640");	
			
		if(pos == -1)
			continue;
			
		format(szFileData, charsmax(szFileData), "%s", szFileData[pos+3]);		
		trim(szFileData);

		strtok(szFileData, szSprName, charsmax(szSprName), temp, charsmax(temp), ' ', 1);
		trim(szSprName);
		
		format(szSprDir, charsmax(szSprDir), "sprites/%s.spr", szSprName);
		engfunc(EngFunc_PrecacheGeneric, szSprDir);
	}

	if(iFile) fclose(iFile);
}

stock UTIL_FakeTraceLine(iPlayer, iSound, Float: flDistance, Float: flDamage, Float: flSendAngles[], Float: flSendAnglesUp[], iSendAngles)
{
	new Float: flOrigin[3], Float: flAngle[3], Float: flEnd[3], Float: flViewOfs[3];
	new Float: flForw[3], Float: flUp[3], Float: flRight[3];

	pev(iPlayer, pev_origin, flOrigin);
	pev(iPlayer, pev_view_ofs, flViewOfs);

	flOrigin[0] += flViewOfs[0];
	flOrigin[1] += flViewOfs[1];
	flOrigin[2] += flViewOfs[2];
			
	pev(iPlayer, pev_v_angle, flAngle);
	engfunc(EngFunc_AngleVectors, flAngle, flForw, flRight, flUp);

	new iTrace = create_tr2();

	new Float: flTan;
	new Float: flMul;

	static Float: flFraction, pHit;
	static pHitEntity; pHitEntity = SLASH_HIT_NONE;
	static iHitResult; iHitResult = SLASH_HIT_NONE;

	for(new i; i < iSendAngles; i++)
	{
		flTan = floattan(flSendAngles[i], degrees);

		flEnd[0] = (flForw[0] * flDistance) + (flRight[0] * flTan * flDistance) + flUp[0] * flSendAnglesUp[i];
		flEnd[1] = (flForw[1] * flDistance) + (flRight[1] * flTan * flDistance) + flUp[1] * flSendAnglesUp[i];
		flEnd[2] = (flForw[2] * flDistance) + (flRight[2] * flTan * flDistance) + flUp[2] * flSendAnglesUp[i];
			
		flMul = (flDistance/vector_length(flEnd));
		flEnd[0] *= flMul;
		flEnd[1] *= flMul;
		flEnd[2] *= flMul;

		flEnd[0] = flEnd[0] + flOrigin[0];
		flEnd[1] = flEnd[1] + flOrigin[1];
		flEnd[2] = flEnd[2] + flOrigin[2];

		engfunc(EngFunc_TraceLine, flOrigin, flEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
		get_tr2(iTrace, TR_flFraction, flFraction);

		if(flFraction == 1.0)
		{
			engfunc(EngFunc_TraceHull, flOrigin, flEnd, HULL_HEAD, iPlayer, iTrace);
			get_tr2(iTrace, TR_flFraction, flFraction);
		
			engfunc(EngFunc_TraceLine, flOrigin, flEnd, DONT_IGNORE_MONSTERS, iPlayer, iTrace);
			pHit = get_tr2(iTrace, TR_pHit);
		}
		else
		{
			pHit = get_tr2(iTrace, TR_pHit);
		}

		if(flFraction != 1.0)
		{
			if(!iHitResult) iHitResult = SLASH_HIT_WORLD;
		}

		if(pHit > 0 && pHitEntity != pHit)
		{
			if(pev(pHit, pev_solid) == SOLID_BSP && !(pev(pHit, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
			{
				ExecuteHamB(Ham_TakeDamage, pHit, iPlayer, iPlayer, flDamage, DMG_NEVERGIB | DMG_CLUB);
			}
			else
			{
				UTIL_FakeTraceAttack(pHit, iPlayer, flDamage, flForw, iTrace, DMG_NEVERGIB | DMG_CLUB);
			}

			iHitResult = SLASH_HIT_ENTITY;
			pHitEntity = pHit;
		}
	}

	switch(iHitResult)
	{
		case SLASH_HIT_NONE: return;
		case SLASH_HIT_WORLD: iSound = 7;
	}

	emit_sound(iPlayer, CHAN_WEAPON, KNIFE_SOUNDS[iSound], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

stock UTIL_FakeTraceAttack(iVictim, iAttacker, Float: flDamage, Float: vecDirection[3], iTrace, ibitsDamageBits)
{
	static Float: flTakeDamage; pev(iVictim, pev_takedamage, flTakeDamage);

	if(flTakeDamage == DAMAGE_NO) return 0; 
	if(!(is_user_alive(iVictim))) return 0;

	if(is_user_connected(iVictim)) 
	{
		if(get_pdata_int(iVictim, m_iPlayerTeam, linux_diff_player) == get_pdata_int(iAttacker, m_iPlayerTeam, linux_diff_player)) 
			return 0;
	}

	static iHitgroup; iHitgroup = get_tr2(iTrace, TR_iHitgroup);
	static Float: vecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	static iBloodColor; iBloodColor = ExecuteHamB(Ham_BloodColor, iVictim);
	
	set_pdata_int(iVictim, m_LastHitGroup, iHitgroup, linux_diff_player);

	switch(iHitgroup) 
	{
		case HIT_HEAD:                  flDamage *= 3.0;
		case HIT_LEFTARM, HIT_RIGHTARM: flDamage *= 0.75;
		case HIT_LEFTLEG, HIT_RIGHTLEG: flDamage *= 0.75;
		case HIT_STOMACH:               flDamage *= 1.5;
	}
	
	ExecuteHamB(Ham_TakeDamage, iVictim, iAttacker, iAttacker, flDamage, ibitsDamageBits);
	
	if(zp_get_user_zombie(iVictim)) 
	{
		if(iBloodColor != DONT_BLEED) 
		{
			ExecuteHamB(Ham_TraceBleed, iVictim, flDamage, vecDirection, iTrace, ibitsDamageBits);
			UTIL_BloodDrips(vecEndPos, iBloodColor, floatround(flDamage));
		}
	}

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
	write_short(gl_iszModelIndexBloodSpray);
	write_short(gl_iszModelIndexBloodDrop);
	write_byte(iColor);
	write_byte(min(max(3, iAmount / 10), 16));
	message_end();
}

#if defined KNIFE_WEAPONLIST
stock UTIL_WeapPickup(iPlayer, iId)
{
	message_begin(MSG_ONE, msgWeapPickup, _, iPlayer);
	write_byte(iId);
	message_end();
}

stock UTIL_SetWeaponList(iPlayer, const szWeaponName[], iPrimaryAmmoID, iPrimaryAmmoMaxAmount, iSecondaryAmmoID, iSecondaryAmmoMaxAmount, iSlotID, iNumberInSlot, iWeaponID, iFlags)
{
	message_begin(MSG_ONE, msgWeaponList, _, iPlayer);
	write_string(szWeaponName);
	write_byte(iPrimaryAmmoID);
	write_byte(iPrimaryAmmoMaxAmount);
	write_byte(iSecondaryAmmoID);
	write_byte(iSecondaryAmmoMaxAmount);
	write_byte(iSlotID);
	write_byte(iNumberInSlot);
	write_byte(iWeaponID);
	write_byte(iFlags);
	message_end();
}
#endif