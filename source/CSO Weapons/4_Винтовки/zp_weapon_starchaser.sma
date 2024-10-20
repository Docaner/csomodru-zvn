#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define is_user_valid(%0) (0 < %0 < 33)
#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)

#define PDATA_SAFE 2

#define WEAPON_ANIM_IDLE 0
#define WEAPON_ANIM_SHOOT random_num(1, 2)
#define WEAPON_ANIM_RELOAD 3
#define WEAPON_ANIM_DRAW 4

// From model: Frames/FPS
#define WEAPON_ANIM_IDLE_TIME 181/30.0
#define WEAPON_ANIM_SHOOT_TIME 41/30.0
#define WEAPON_ANIM_RELOAD_TIME 121/30.0
#define WEAPON_ANIM_DRAW_TIME 46/30.0

#define WEAPON_SPECIAL_CODE 156251
#define WEAPON_CSW CSW_G3SG1
#define WEAPON_REFERENCE "weapon_g3sg1"
#define WEAPON_NEW_NAME "x/weapon_starchasersr"
#define WEAPON_HUD "sprites/x/640hud171.spr"
#define WEAPON_HUD_AMMO "sprites/x/640hud18.spr"

#define WEAPON_MODEL_VIEW "models/x/v_starchasersr.mdl"
#define WEAPON_MODEL_PLAYER "models/x/p_starchasersr.mdl"
#define WEAPON_MODEL_WORLD "models/x/w_starchasersr.mdl"
#define WEAPON_SOUND_SHOOT "weapons/starchasersr-1.wav"
#define WEAPON_SOUND_EXPLODE "weapons/starchasersr_exp.wav"
#define WEAPON_BODY 0

#define WEAPON_MAX_CLIP 10
#define WEAPON_DEFAULT_AMMO 120
#define WEAPON_RATE WEAPON_ANIM_SHOOT_TIME - 0.4
#define WEAPON_PUNCHAGNLE 1.0
#define WEAPON_DAMAGE 1.55

#define ENTITY_STARCHASER_CLASSNAME "starchaser_ent"
#define ENTITY_STARCHASER_SPEED 10000
#define ENTITY_STARCHASER_DAMAGE_EXPLODE random_float(225.0, 350.0)
#define ENTITY_STARCHASER_RADIUS 75.0
#define ENTITY_STARCHASER_NEXTTHINK 0.0075

new const iWeaponList[] = 
{
	2, 90, -1, -1, 0, 3, 24, 0 // weapon_g3sg1
};

// Linux extra offsets
#define linux_diff_weapon 4
#define linux_diff_player 5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CBasePlayerItem
#define m_pPlayer 41
#define m_pNext 42
#define m_iId 43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flTimeWeaponIdle 48
#define m_iPrimaryAmmoType 49
#define m_iClip 51
#define m_fInReload 54

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

new g_iszAllocString_Entity,
	g_iszAllocString_ModelView, 
	g_iszAllocString_ModelPlayer, 

	HamHook: g_HamHook_TraceAttack[4],

	g_iszModelIndexStars,
	g_iszModelIndexExplode,
	g_iszModelIndexFollowLine,

	g_iItemID,
	g_iMsgID_Weaponlist;

public plugin_init()
{
	register_plugin("[ZP] Weapon: Star Chaser SR", "1.0", "xUnicorn (t3rkecorejz) / Batcoh: Code base");

	g_iItemID = zp_register_extra_item("Star Chaser SR", 0, ZP_TEAM_HUMAN)

	register_forward(FM_UpdateClientData,	"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 			"FM_Hook_SetModel_Pre", false);

	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
	RegisterHam(Ham_Weapon_Reload,			WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);

	g_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,		"func_breakable",	"CEntity__TraceAttack_Pre", false);
	g_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,		"info_target",		"CEntity__TraceAttack_Pre", false);
	g_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,		"player",			"CEntity__TraceAttack_Pre", false);
	g_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,		"hostage_entity",	"CEntity__TraceAttack_Pre", false);

	fm_ham_hook(false);

	RegisterHam(Ham_Touch,					"info_target",		"CEntity__Touch_Pre", false);
	RegisterHam(Ham_Think,					"info_target",		"CEntity__Think_Pre", false);

	g_iMsgID_Weaponlist = get_user_msgid("WeaponList");
}

public plugin_precache()
{
	// Hook weapon
	register_clcmd(WEAPON_NEW_NAME, "Command_HookWeapon");

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);

	// Precache generic
	new szBuffer[64]; formatex(szBuffer, charsmax(szBuffer), "sprites/%s.txt", WEAPON_NEW_NAME);

	engfunc(EngFunc_PrecacheGeneric, szBuffer);
	engfunc(EngFunc_PrecacheGeneric, WEAPON_HUD);
	engfunc(EngFunc_PrecacheGeneric, WEAPON_HUD_AMMO);
	
	// Precache sounds
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_SHOOT);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_EXPLODE);

	UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW);

	// Other
	g_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	g_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	g_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);

	g_iszModelIndexStars = engfunc(EngFunc_PrecacheModel, "sprites/x/ef_starchasersr_star.spr");
	g_iszModelIndexExplode = engfunc(EngFunc_PrecacheModel, "sprites/x/ef_starchasersr_explosion.spr");
	g_iszModelIndexFollowLine = engfunc(EngFunc_PrecacheModel, "sprites/x/ef_starchasersr_line.spr");
}

public plugin_cfg()
{
	set_cvar_num("sv_maxvelocity", ENTITY_STARCHASER_SPEED);
}

public plugin_natives()
{
	register_native("zp_give_user_starchaser", "Command_GiveWeapon", 1);
}

// [ Zombie Plague ]
public zp_extra_item_selected(iPlayer, iItem)
{
	if(iItem == g_iItemID)
		Command_GiveWeapon(iPlayer);
}

// [ Amxx ]
public Command_HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

public Command_GiveWeapon(iPlayer)
{
	static iEntity; iEntity = engfunc(EngFunc_CreateNamedEntity, g_iszAllocString_Entity);
	if(iEntity <= 0) return 0;

	set_pev(iEntity, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, iEntity);
	UTIL_DropWeapon(iPlayer, 1);

	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iEntity))
	{
		set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
		return 0;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, iEntity, iPlayer);
	set_pdata_int(iEntity, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);

	new iAmmoType = m_rgAmmo + get_pdata_int(iEntity, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, m_rgAmmo, linux_diff_player) < WEAPON_DEFAULT_AMMO)
	set_pdata_int(iPlayer, iAmmoType, WEAPON_DEFAULT_AMMO, linux_diff_player);

	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return 1;
}

// [ Fakemeta ]
public FM_Hook_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle)
{
	if(get_cd(CD_Handle, CD_DeadFlag) != DEAD_NO) return;

	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, 5);
	if(iItem <= 0 || !CustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
	static i, szClassName[32], iItem;
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;

	for(i = 0; i < 6; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, linux_diff_weapon);

		if(iItem > 0 && CustomItem(iItem))
		{
			engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
			set_pev(iEntity, pev_body, WEAPON_BODY);
			
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public FM_Hook_PlaybackEvent_Pre() return FMRES_SUPERCEDE;

public FM_Hook_TraceLine_Post(const Float:flOrigin1[3], const Float:flOrigin2[3], iFrag, iAttacker, iTrace)
{
	if(iFrag & IGNORE_MONSTERS) return FMRES_IGNORED;

	static pHit; pHit = get_tr2(iTrace, TR_pHit);
	static Float:flvecEndPos[3]; get_tr2(iTrace, TR_vecEndPos, flvecEndPos);

	if(pHit > 0) if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, flvecEndPos, 0);
	write_byte(TE_GUNSHOTDECAL);
	engfunc(EngFunc_WriteCoord, flvecEndPos[0]);
	engfunc(EngFunc_WriteCoord, flvecEndPos[1]);
	engfunc(EngFunc_WriteCoord, flvecEndPos[2]);
	write_short(pHit > 0 ? pHit : 0);
	write_byte(random_num(41, 45));
	message_end();

	return FMRES_IGNORED;
}

// [ HamSandwich ]
public CWeapon__Deploy_Post(iItem)
{
	if(!CustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	set_pev_string(iPlayer, pev_viewmodel2, g_iszAllocString_ModelView);
	set_pev_string(iPlayer, pev_weaponmodel2, g_iszAllocString_ModelPlayer);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);

	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_DRAW_TIME, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_DRAW_TIME, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
	static j; j = min(WEAPON_MAX_CLIP - iClip, iAmmo);

	if(get_pdata_int(iItem, m_fInReload, linux_diff_weapon) == 1)
	{
		set_pdata_int(iItem, m_iClip, iClip + j, linux_diff_weapon);
		set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
		set_pdata_int(iItem, m_fInReload, 0, linux_diff_weapon);
	}

	return HAM_IGNORED;
}

public CWeapon__AddToPlayer_Post(iItem, iPlayer)
{
	switch(pev(iItem, pev_impulse))
	{
		case WEAPON_SPECIAL_CODE: UTIL_WeaponList(iPlayer, true);
		case 0: UTIL_WeaponList(iPlayer, false);
	}
}

public CWeapon__Reload_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;

	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInReload, 1, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_RELOAD);

	// set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	// set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_TIME, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_TIME, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!CustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_IDLE_TIME, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	if(get_pdata_int(iItem, m_iClip, linux_diff_weapon) == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);

		return HAM_SUPERCEDE;
	}

	static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "FM_Hook_TraceLine_Post", true);
	static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false);
	fm_ham_hook(true);

	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);

	unregister_forward(FM_TraceLine, fw_TraceLine, true);
	unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
	fm_ham_hook(false);

	static Float:vecPunchangle[3];
	pev(iPlayer, pev_punchangle, vecPunchangle);
	vecPunchangle[0] *= WEAPON_PUNCHAGNLE;
	vecPunchangle[1] *= WEAPON_PUNCHAGNLE;
	vecPunchangle[2] *= WEAPON_PUNCHAGNLE;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_SHOOT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_SHOOT_TIME, linux_diff_weapon);

	static iReference;
	
	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngles[3]; pev(iPlayer, pev_v_angle, vecAngles);
	new Float: vecVelocity[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecVelocity);
	new Float: vecViewOfs[3]; pev(iPlayer, pev_view_ofs, vecViewOfs);

	vecVelocity[0] *= ENTITY_STARCHASER_SPEED; 
	vecVelocity[1] *= ENTITY_STARCHASER_SPEED; 
	vecVelocity[2] *= ENTITY_STARCHASER_SPEED;

	vecOrigin[0] += vecViewOfs[0];
	vecOrigin[1] += vecViewOfs[1];
	vecOrigin[2] += vecViewOfs[2];

	if(iReference || (iReference = engfunc(EngFunc_AllocString, "info_target")))
	{
		new iEntity = engfunc(EngFunc_CreateNamedEntity, iReference);

		set_pev(iEntity, pev_classname, ENTITY_STARCHASER_CLASSNAME);
		set_pev(iEntity, pev_solid, SOLID_TRIGGER);
		set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
		set_pev(iEntity, pev_owner, iPlayer);
		set_pev(iEntity, pev_velocity, vecVelocity);
		set_pev(iEntity, pev_effects, EF_NODRAW);
		set_pev(iEntity, pev_nextthink, get_gametime() + ENTITY_STARCHASER_NEXTTHINK);
		
		engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
		engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);
	}

	return HAM_SUPERCEDE;
}

public CEntity__Touch_Pre(iEntity, iVictim)
{
	if(pev_valid(iEntity) != PDATA_SAFE)
		return HAM_IGNORED;

	static szClassName[32]; 
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(equal(szClassName, ENTITY_STARCHASER_CLASSNAME))
	{
		static iOwner; iOwner = pev(iEntity, pev_owner);

		if(iVictim == iOwner)
			return HAM_IGNORED;

		/* По тимейтам не ебашит */
		if(is_user_connected(iVictim) && !zp_get_user_zombie(iVictim))
			return HAM_SUPERCEDE;


		iVictim = -1;
		static Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		static Float: vecOriginOwner[3]; pev(iOwner, pev_origin, vecOriginOwner);

		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			set_pev(iEntity, pev_flags, FL_KILLME);
			return HAM_IGNORED;
		}

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_EXPLOSION);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2]);
		write_short(g_iszModelIndexExplode);
		write_byte(5);
		write_byte(30);
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES);
		message_end();

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_SPRITETRAIL);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2] + 100);
		engfunc(EngFunc_WriteCoord, vecOriginOwner[0]);
		engfunc(EngFunc_WriteCoord, vecOriginOwner[1]);
		engfunc(EngFunc_WriteCoord, vecOriginOwner[2] + 20);
		write_short(g_iszModelIndexStars);
		write_byte(5);
		write_byte(1);
		write_byte(1);
		write_byte(50);
		write_byte(50);
		message_end();

		emit_sound(iEntity, CHAN_ITEM, WEAPON_SOUND_EXPLODE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, ENTITY_STARCHASER_RADIUS)) > 0)
		{
			if(pev(iVictim, pev_takedamage) == DAMAGE_NO) 
				continue;

			if(is_user_alive(iVictim))
			{
				if(iVictim == iOwner || zp_get_user_zombie(iOwner) || !zp_get_user_zombie(iVictim))
					continue;
			}
			else if(pev(iVictim, pev_solid) == SOLID_BSP) 
			{
				if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
					continue;
			}

			ExecuteHamB(Ham_TakeDamage, iVictim, iEntity, iOwner, ENTITY_STARCHASER_DAMAGE_EXPLODE, DMG_BULLET);
		}

		set_pev(iEntity, pev_flags, FL_KILLME);
	}

	return HAM_IGNORED;
}

public CEntity__Think_Pre(iEntity)
{
	if(pev_valid(iEntity) != PDATA_SAFE)
		return HAM_IGNORED;

	static szClassName[32]; 
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(equal(szClassName, ENTITY_STARCHASER_CLASSNAME))
	{
		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_EXPLOSION);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2]);
		write_short(g_iszModelIndexFollowLine);
		write_byte(random_num(2, 3));
		write_byte(30);
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES);
		message_end();

		set_pev(iEntity, pev_nextthink, get_gametime() + ENTITY_STARCHASER_NEXTTHINK);
	}

	return HAM_IGNORED;
}

public CEntity__TraceAttack_Pre(iVictim, iAttacker, Float:flDamage)
{
	if(!is_user_connected(iAttacker)) return;

	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(iItem <= 0 || !CustomItem(iItem)) return;

	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

// [ Other ]
public fm_ham_hook(bool: bEnabled)
{
	if(bEnabled)
	{
		EnableHamForward(g_HamHook_TraceAttack[0]);
		EnableHamForward(g_HamHook_TraceAttack[1]);
		EnableHamForward(g_HamHook_TraceAttack[2]);
		EnableHamForward(g_HamHook_TraceAttack[3]);
	}
	else 
	{
		DisableHamForward(g_HamHook_TraceAttack[0]);
		DisableHamForward(g_HamHook_TraceAttack[1]);
		DisableHamForward(g_HamHook_TraceAttack[2]);
		DisableHamForward(g_HamHook_TraceAttack[3]);
	}
}

// [ Stocks ]
stock UTIL_SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_DropWeapon(iPlayer, iSlot)
{
	static iEntity, iNext, szWeaponName[32];
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

	if(iEntity > 0)
	{       
		do 
		{
			iNext = get_pdata_cbase(iEntity, m_pNext, linux_diff_weapon);

			if(get_weaponname(get_pdata_int(iEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
				engclient_cmd(iPlayer, "drop", szWeaponName);
		} 
		
		while((iEntity = iNext) > 0);
	}
}

stock UTIL_PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;
	
	if((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for(new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);
			
			for(k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if(iEvent != 5004)
					continue;
				
				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if(strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					engfunc(EngFunc_PrecacheSound, szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}

stock UTIL_WeaponList(iPlayer, bool: bEnabled)
{
	message_begin(MSG_ONE, g_iMsgID_Weaponlist, _, iPlayer);
	write_string(bEnabled ? WEAPON_NEW_NAME : WEAPON_REFERENCE);
	write_byte(iWeaponList[0]);
	write_byte(bEnabled ? WEAPON_DEFAULT_AMMO : iWeaponList[1]);
	write_byte(iWeaponList[2]);
	write_byte(iWeaponList[3]);
	write_byte(iWeaponList[4]);
	write_byte(iWeaponList[5]);
	write_byte(iWeaponList[6]);
	write_byte(iWeaponList[7]);
	message_end();
}