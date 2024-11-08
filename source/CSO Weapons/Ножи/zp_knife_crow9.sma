#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN 					"[ZP] Extra: CSO Weapon Crow 9"
#define VERSION 				"1.0"
#define AUTHOR 					"KORD_12.7"

#pragma ctrlchar 				'\'
#pragma compress 				1

//* Weapon Settings

#define WEAPON_NAME					"weapon_crow9"
#define WEAPON_REFERANCE			"weapon_knife"

#define WEAPON_MODEL_VIEW			"models/x/v_crow9.mdl"
#define WEAPON_MODEL_PLAYER			"models/x/p_crow9a.mdl"

#define WEAPON_MODEL_EXP			"models/x/crow9_wind.mdl"

#define WEAPON_DISTANCE_ATTACK		50.0 // Значение дистанции остается равным 50, если идет речь о первом режиме, и умножается, если о втором 

#define WEAPON_DAMAGE				random_float(150.0, 300.0)
#define WEAPON_KNOCKBACK			250.0

#define WEAPON_DAMAGE_EXP			750.0
#define WEAPON_RADIUS_EXP			120.0
#define WEAPON_KNOCKBACK_EXP		600.0

#define SOUND_DRAW 					"weapons/crow9_draw.wav"
#define SOUND_SLASH1				"weapons/crow9_slasha_1.wav"
#define SOUND_SLASH2				"weapons/crow9_slashc_in.wav"
#define SOUND_SLASH3				"weapons/crow9_slashc_1.wav"
#define SOUND_HIT					"weapons/balrog9_hit1.wav"
#define SOUND_HIT_WALL				"weapons/balrog9_hit2.wav"

#define WEAPON_HUD_TXT				"sprites/x/weapon_crow9.txt"
#define WEAPON_HUD_SPR1				"sprites/x/640hud149.spr"
#define WEAPON_HUD_SPR2				"sprites/x/640hud7.spr"

#define ANIM_EXTENSION				"dragontail"

enum
{	
	ANIM_IDLE,
	
	ANIM_SLASH1,
	ANIM_SLASH2,
	
	ANIM_DRAW,
	
	ANIM_MODE_START,
	ANIM_MODE_SLASH,
	ANIM_MODE_END
};

//* Some macroses.
#define GET_SHOOTS(%0)			get_pdata_int(%0, m_fInCheckShoots, extra_offset_weapon)
#define SET_SHOOTS(%0,%1)		set_pdata_int(%0, m_fInCheckShoots, %1, extra_offset_weapon)

#define GET_STATE(%0)			get_pdata_int(%0, m_fWeaponState, extra_offset_weapon)
#define SET_STATE(%0,%1)		set_pdata_int(%0, m_fWeaponState, %1, extra_offset_weapon)

#define MDLL_Spawn(%0)			dllfunc(DLLFunc_Spawn, %0)
#define MDLL_Touch(%0,%1)		dllfunc(DLLFunc_Touch, %0, %1)

#define SET_MODEL(%0,%1)		engfunc(EngFunc_SetModel, %0, %1)
#define SET_ORIGIN(%0,%1)		engfunc(EngFunc_SetOrigin, %0, %1)

#define PRECACHE_MODEL(%0)		engfunc(EngFunc_PrecacheModel, %0)
#define PRECACHE_SOUND(%0)		engfunc(EngFunc_PrecacheSound, %0)
#define PRECACHE_GENERIC(%0)		engfunc(EngFunc_PrecacheGeneric, %0)

#define MODEL_INDEX(%0) 		engfunc(EngFunc_ModelIndex,%0)

#define MESSAGE_BEGIN(%0,%1,%2,%3)	engfunc(EngFunc_MessageBegin, %0, %1, %2, %3)
#define MESSAGE_END()			message_end()

#define WRITE_ANGLE(%0)			engfunc(EngFunc_WriteAngle, %0)
#define WRITE_BYTE(%0)			write_byte(%0)
#define WRITE_COORD(%0)			engfunc(EngFunc_WriteCoord, %0)
#define WRITE_STRING(%0)		write_string(%0)
#define WRITE_SHORT(%0)			write_short(%0)

#define INSTANCE(%0)			((%0 == -1) ? 0 : %0)

#define SetBit(%0,%1) 			(%0 |= (1 << (%1 - 1)))
#define ClearBit(%0,%1) 		(%0 &= ~(1 << (%1 - 1)))
#define IsSetBit(%0,%1) 		(%0 & (1 << (%1 - 1)))

//* PvData Offsets.
// Linux extra offsets
#define extra_offset_weapon		4
#define extra_offset_player		5

new g_bitIsConnected;

#define m_rgpPlayerItems_CWeaponBox	34
#define m_fInCheckShoots		39
#define m_pPlayer			41
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle		48
#define m_iDirection			60
#define m_fWeaponState			74
#define m_LastHitGroup 			75
#define m_flNextAttack			83
#define m_iLastZoom 			109
#define m_fResumeZoom      		110
#define m_iFOV				363
#define m_pActiveItem			373
#define m_szAnimExtention		492

#define IsValidPev(%0) 			(pev_valid(%0) == 2)

#define EXP_CLASSNAME			"CrowWind"

new iBlood[2];

enum
{
	STATE_NONE = 0,
	STATE_MODE = 1
}

Weapon_OnPrecache()
{
	PRECACHE_SOUNDS_FROM_MODEL(WEAPON_MODEL_VIEW);
	PRECACHE_MODEL(WEAPON_MODEL_VIEW);
	PRECACHE_MODEL(WEAPON_MODEL_PLAYER);
	
	PRECACHE_MODEL(WEAPON_MODEL_EXP);

	PRECACHE_SOUND(SOUND_SLASH1);
	PRECACHE_SOUND(SOUND_SLASH2);
	PRECACHE_SOUND(SOUND_SLASH3);
	PRECACHE_SOUND(SOUND_HIT);
	PRECACHE_SOUND(SOUND_HIT_WALL);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR1);
	PRECACHE_GENERIC(WEAPON_HUD_SPR2);
	
	iBlood[0] = PRECACHE_MODEL("sprites/bloodspray.spr");
	iBlood[1] = PRECACHE_MODEL("sprites/blood.spr");
}

Weapon_OnDeploy(const iItem, const iPlayer)
{
	#pragma unused iItem, iPlayer
		
	Weapon_DefaultDeploy(iPlayer, WEAPON_MODEL_VIEW, WEAPON_MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
			
	set_pdata_float(iItem, m_flTimeWeaponIdle, 1.5, extra_offset_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, 1.0, extra_offset_player);
	
	MsgHook_WeaponList(78, iItem, iPlayer);
}

Weapon_OnHolster(const iItem, const iPlayer)
{
	#pragma unused iItem, iPlayer

	set_pev(iItem, pev_iuser1, 0);
	set_pev(iItem, pev_fuser1, 0.0);
}

Weapon_OnIdle(const iItem, const iPlayer)
{
	#pragma unused iItem, iPlayer
	
	ExecuteHamB(Ham_Weapon_ResetEmptySound, iItem);
	
	if (get_pdata_float(iItem, m_flNextSecondaryAttack, extra_offset_weapon) > 0.0)
	{
		return
	}
	
	static Float:iState;pev(iItem, pev_fuser1, iState);
	static iState2;pev(iItem, pev_iuser1, iState2);
	
	if (iState && !iState2 && iState <= get_gametime())
	{
		Weapon_SendAnim(iPlayer, ANIM_MODE_END);
					
		set_pdata_float(iItem, m_flTimeWeaponIdle, 1.5, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 2.0, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, 2.0, extra_offset_weapon);
		
		set_pev(iItem, pev_iuser1, 0);
		set_pev(iItem, pev_fuser1, 0.0);
	}

	if (get_pdata_int(iItem, m_flTimeWeaponIdle, extra_offset_weapon) > 0.0)
	{
		return;
	}
	
	if (pev(iItem, pev_iuser1))
	{
		set_pev(iItem, pev_iuser1, 0);
		set_pev(iItem, pev_fuser1, 0.0);
	}
	
	Weapon_SendAnim(iPlayer, ANIM_IDLE);	
	set_pdata_float(iItem, m_flTimeWeaponIdle, 10.0, extra_offset_weapon);
}

Weapon_OnPrimaryAttack(const iItem, const iPlayer)
{
	#pragma unused iItem, iPlayer
	
	static szAnimation[64];

	formatex(szAnimation, charsmax(szAnimation), "ref_shoot_%s", ANIM_EXTENSION);
			
	switch (GET_SHOOTS(iItem))
	{
		case 0:
		{
			Weapon_SendAnim(iPlayer, ANIM_SLASH1);
					
			set_pdata_float(iItem, m_flTimeWeaponIdle, 1.5, extra_offset_weapon);
			set_pdata_float(iItem, m_flNextPrimaryAttack, 1.0, extra_offset_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, 1.0, extra_offset_weapon);
					
			engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_SLASH1, 1.0, ATTN_NORM, 0, PITCH_NORM);
					
			PrimarySlash_Attack(iPlayer, iItem);
					
			SET_SHOOTS(iItem, 1);
		}
		case 1:
		{
			Weapon_SendAnim(iPlayer, ANIM_SLASH2);
					
			set_pdata_float(iItem, m_flTimeWeaponIdle, 1.5, extra_offset_weapon);
			set_pdata_float(iItem, m_flNextPrimaryAttack, 1.0, extra_offset_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, 1.0, extra_offset_weapon);
					
			engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_SLASH2, 1.0, ATTN_NORM, 0, PITCH_NORM);
					
			PrimarySlash_Attack(iPlayer, iItem);
					
			SET_SHOOTS(iItem, 0);
		}
	}
	Player_SetAnimation(iPlayer, szAnimation);
}

public Weapon_OnSecondaryAttack(const iItem, const iPlayer)
{
	#pragma unused iItem, iPlayer
	
	if (!pev(iItem, pev_iuser1) && pev(iItem, pev_fuser1))
	{
		set_pev(iItem, pev_iuser1, 1);
		return;
	}

	Weapon_SendAnim(iPlayer, ANIM_MODE_START);
		
	set_pdata_float(iItem, m_flTimeWeaponIdle, 0.92, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 1.0, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.9, extra_offset_weapon);
	
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_SLASH2, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	set_pev(iItem, pev_fuser1, get_gametime() + 0.9);
}

//*           Don't modify the code below this line unless            *
//*          	 you know _exactly_ what you are doing!!!             *
#define MSGID_WEAPONLIST 	78

public plugin_precache()
{
	Weapon_OnPrecache();
	register_clcmd(WEAPON_NAME, "Cmd_WeaponSelect");
	register_message(MSGID_WEAPONLIST, "MsgHook_WeaponList");
}

native zp_register_knife(const szName[]);
forward zp_knife_selected(id, iKnife, iOldKnife);

new g_iKnife, g_iBitUserKnife

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Item_AddToPlayer,		WEAPON_REFERANCE,  	"HamHook_Item_AddToPlayer",		false);
	RegisterHam(Ham_Item_Deploy,			WEAPON_REFERANCE, 	"HamHook_Item_Deploy_Post",		true);
	RegisterHam(Ham_Item_Holster,			WEAPON_REFERANCE, 	"HamHook_Item_Holster",			false);
	
	RegisterHam(Ham_Weapon_WeaponIdle,		WEAPON_REFERANCE, 	"HamHook_Item_WeaponIdle",		false);
	RegisterHam(Ham_Weapon_PrimaryAttack,		WEAPON_REFERANCE, 	"HamHook_Item_PrimaryAttack",		false);
	RegisterHam(Ham_Weapon_SecondaryAttack, 	WEAPON_REFERANCE, 	"HamHook_Item_SecondaryAttack",		false);

	RegisterHam(Ham_Item_PostFrame,			WEAPON_REFERANCE, 	"HamHook_Item_PostFrame",		false);
	
	RegisterHam(Ham_Spawn, 				"player",		"HamHook_Player_Spawn",  		true);

	register_forward(FM_UpdateClientData,					"FakeMeta_UpdateClientData_Post", 	true);
	register_forward(FM_Think, 						"FakeMeta_Think",			false);

	g_iKnife = zp_register_knife("Crow 9")
}

public zp_knife_selected(iPlayer, iNew, iOld)
{
	if(g_iKnife == iNew && iNew != iOld)
		SetBit(g_iBitUserKnife, iPlayer);

	if(g_iKnife == iOld && iNew != iOld)
		ClearBit(g_iBitUserKnife, iPlayer);
}

//* Block client weapon.                       *

public FakeMeta_UpdateClientData_Post(const iPlayer, const iSendWeapons, const CD_Handle)
{
	static iActiveItem;iActiveItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);
	
	if(zp_get_user_zombie(iPlayer) || !IsSetBit(g_iBitUserKnife, iPlayer))
	{
		return FMRES_IGNORED;
	}
	
	if (!IsValidPev(iActiveItem) || get_user_weapon(iPlayer) != CSW_KNIFE)
	{
		return FMRES_IGNORED;
	}
	
	if (!IsSetBit(g_iBitUserKnife, iPlayer))
	{	
		return FMRES_IGNORED;
	}

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
	
	return FMRES_IGNORED;
}

public FakeMeta_Think(const iEnt)
{
	if (!pev_valid(iEnt))
	{
		return FMRES_IGNORED;
	}
	
	static Classname[32];pev(iEnt, pev_classname, Classname, sizeof(Classname));
	
	if (equal(Classname, EXP_CLASSNAME))
	{
		set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}


//* Item (weapon) hooks.                       *

	#define _call.%0(%1,%2) \
								\
	Weapon_On%0						\
	(							\
		%1, 						\
		%2						\
	) 
	
public HamHook_Item_AddToPlayer(const iItem, const iPlayer)
{
	if (!IsValidPev(iItem) || !IsSetBit(g_iBitUserKnife, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	MsgHook_WeaponList(MSGID_WEAPONLIST, iItem, iPlayer);
	
	return HAM_IGNORED;
}

public HamHook_Item_Deploy_Post(const iItem)
{
	new iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.Deploy(iItem, iPlayer);
	return HAM_IGNORED;
}

public HamHook_Item_Holster(const iItem)
{
	new iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	set_pev(iPlayer, pev_viewmodel, 0);
	set_pev(iPlayer, pev_weaponmodel, 0);
	
	_call.Holster(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_WeaponIdle(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}

	_call.Idle(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_PrimaryAttack(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}

	_call.PrimaryAttack(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_SecondaryAttack(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.SecondaryAttack(iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_PostFrame(const iItem)
{
	static iPlayer;

	static szAnimation[64];

	formatex(szAnimation, charsmax(szAnimation), "ref_shoot_%s", ANIM_EXTENSION);

	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	static Float:iState;pev(iItem, pev_fuser1, iState);
	static iState2;pev(iItem, pev_iuser1, iState2);

	if (iState2 && iState <= get_gametime())
	{
		Weapon_SendAnim(iPlayer, ANIM_MODE_SLASH);
					
		set_pdata_float(iItem, m_flTimeWeaponIdle, 1.7, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 2.0, extra_offset_weapon);
		set_pdata_float(iItem, m_flNextSecondaryAttack, 2.0, extra_offset_weapon);
		
		engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_SLASH3, 1.0, ATTN_NORM, 0, PITCH_NORM);
		
		set_pev(iItem, pev_iuser1, 0);
		set_pev(iItem, pev_fuser1, 0.0);
		
		static pEntity;
		static Float:Origin[3], Float:iAngle[3];Weapon_GetGunPosition(iPlayer, Origin, iAngle, .add_forward = 20.0, .add_right = 0.0, .add_up = 0.0)
	
		static iszAllocStringCached;
		if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
		{
			pEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
		}
		
		static Float:vAngles[3];pev(iPlayer, pev_v_angle,vAngles);
		
		static Float:Angles[3];Angles[0] = 360.0 - vAngles[0];
		Angles[1] = vAngles[1];
		Angles[2] = vAngles[2];
			
		if (pev_valid(pEntity))
		{	
			set_pev(pEntity, pev_movetype, MOVETYPE_FLY);
			set_pev(pEntity, pev_owner, iPlayer);
						
			SET_MODEL(pEntity, WEAPON_MODEL_EXP);
			SET_ORIGIN(pEntity, Origin);
				
			set_pev(pEntity, pev_classname, EXP_CLASSNAME);
			set_pev(pEntity, pev_solid, SOLID_NOT);
			set_pev(pEntity, pev_angles, Angles);
			set_pev(pEntity, pev_sequence, 0);
			set_pev(pEntity, pev_framerate, 0.8);
			set_pev(pEntity, pev_animtime, get_gametime());
			set_pev(pEntity, pev_nextthink, get_gametime() + 0.7);
		}
		
		static pNull;pNull = FM_NULLENT;
		static Float:vec[3];pev(iPlayer, pev_origin, vec);
		while((pNull = fm_find_ent_in_sphere(pNull, vec, WEAPON_RADIUS_EXP)) != 0)
		{	
			static Float:vOrigin[3];pev(pNull, pev_origin, vOrigin);
			if (IsValidPev(pNull) && pev(pNull, pev_takedamage) != DAMAGE_NO && pev(pNull, pev_solid) != SOLID_NOT)
			{
				if (is_user_connected(pNull) && zp_get_user_zombie(pNull) && fm_is_in_viewcone(iPlayer, vOrigin) && !IsWallBetweenPoints(vec, vOrigin, iPlayer))
				{
					static Float:vOrigin[3], Float:dist, Float:damage;pev(pNull, pev_origin, vOrigin);
								
					Create_Blood(vOrigin, iBlood[0], iBlood[1], 76, 13);
					static Float:vecViewAngle[3]; pev(iPlayer, pev_v_angle, vecViewAngle);
					static Float:vecForward[3]; angle_vector(vecViewAngle, ANGLEVECTOR_FORWARD, vecForward);
					FakeKnockBack(pNull, vecForward, WEAPON_KNOCKBACK_EXP);
	
					dist = get_distance_f(vec, vOrigin);damage = WEAPON_DAMAGE_EXP - (WEAPON_DAMAGE_EXP/WEAPON_DAMAGE_EXP) * dist;
					if (damage > 0.0)
					{
						ExecuteHamB(Ham_TakeDamage, pNull, iPlayer, iPlayer, damage, DMG_BURN);
					}
				}
			}
		}
		Player_SetAnimation(iPlayer, szAnimation);
	}
		
	return HAM_IGNORED;
}

public HamHook_Player_Spawn(iPlayer)
{
	if(is_user_alive(iPlayer))
	{
		new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);

		if (pev_valid(iItem))
		{
			ExecuteHamB(Ham_Item_Deploy, iItem);
			MsgHook_WeaponList(MSGID_WEAPONLIST, iItem, iPlayer);
		}
	}
}

//* Attack function.                           *
PrimarySlash_Attack(const iPlayer, const iItem, const Float: flRightScale = 1.0, const Float: flUpScale = 1.0)
{
	new Float: Origin[3]; 
	new Float: vecEnd[3];
	new Float: vecScr[3]; 
	
	new Float: flFraction; 
	
	new iTrace;
	new iVictim;
	
	Weapon_GetGunPosition(iPlayer, Origin, vecScr, 0.0, flRightScale, flUpScale);
	
	angle_vector(vecScr, ANGLEVECTOR_FORWARD, vecScr);

	xs_vec_mul_scalar(vecScr, WEAPON_DISTANCE_ATTACK, vecEnd);

	xs_vec_add(Origin, vecEnd, vecEnd);
	
	engfunc(EngFunc_TraceLine, Origin, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, (iTrace = create_tr2()));
	get_tr2(iTrace, TR_flFraction, flFraction);
	
	if (flFraction >= 1.0)
	{
		engfunc(EngFunc_TraceHull, Origin, vecEnd, DONT_IGNORE_MONSTERS, HULL_HEAD, iPlayer, iTrace);
		get_tr2(iTrace, TR_flFraction, flFraction);
		
		if (flFraction < 1.0)
		{
			iVictim = INSTANCE(get_tr2(iTrace, TR_pHit));
			
			if (!iVictim || ExecuteHamB(Ham_IsBSPModel, iVictim))
			{
				FindHullIntersection(Origin, iTrace, Float: {-16.0, -16.0, -18.0}, Float: {16.0,  16.0,  18.0}, iPlayer);
			}
		}
	}

	get_tr2(iTrace, TR_flFraction, flFraction);
	
	if (flFraction < 1.0)
	{
		iVictim = INSTANCE(get_tr2(iTrace, TR_pHit));
		new Float:iDamage = WEAPON_DAMAGE;
		
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.5, extra_offset_weapon);
		
		if(iVictim > 0 && pev(iVictim, pev_takedamage) != DAMAGE_NO && pev(iVictim, pev_solid) != SOLID_NOT)
		{	
			if(ExecuteHamB(Ham_IsPlayer, iVictim))
			{
				emit_sound(iPlayer, CHAN_ITEM, SOUND_HIT, 1.0, ATTN_NORM, 0, PITCH_NORM);
				
				if(!zp_get_user_zombie(iVictim))
				{
					return;
				}
				
				new Float:vecViewAngle[3]; pev(iPlayer, pev_v_angle, vecViewAngle);
				new Float:vecForward[3]; angle_vector(vecViewAngle, ANGLEVECTOR_FORWARD, vecForward);
	
				FakeKnockBack(iVictim, vecForward, WEAPON_KNOCKBACK);
				
				get_tr2(iTrace, TR_vecEndPos, vecEnd);
				Create_Blood(vecEnd, iBlood[0], iBlood[1], 76, 10);
				
				static iHitGroup;
				switch ((iHitGroup = get_tr2(iTrace, TR_iHitgroup)))
				{
					case HIT_HEAD:iDamage *= 2;
					case HIT_CHEST:iDamage *= 1;
					case HIT_STOMACH:iDamage *= 1.25;
					case HIT_LEFTARM,HIT_RIGHTARM:iDamage *= 1;
					case HIT_LEFTLEG,HIT_RIGHTLEG:iDamage *= 0.75;
				}
				set_pdata_int(iVictim, m_LastHitGroup, iHitGroup, extra_offset_player);
			}
			
			ExecuteHamB(Ham_TakeDamage, iVictim, iItem, iPlayer, iDamage, DMG_CLUB | DMG_NEVERGIB);	
		}
		else
		{
			emit_sound(iPlayer, CHAN_ITEM, SOUND_HIT_WALL, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	free_tr2(iTrace);
}


//* Create and check our custom weapon.        *
Weapon_SendAnim(const iPlayer, const iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, iPlayer);
	WRITE_BYTE(iAnim);
	WRITE_BYTE(0);
	MESSAGE_END();
}

stock Weapon_DefaultDeploy(const iPlayer, const szViewModel[], const szWeaponModel[], const iAnim, const szAnimExt[])
{
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	set_pev(iPlayer, pev_weaponmodel2, szWeaponModel);
	set_pev(iPlayer, pev_fov, 90.0);
	
	set_pdata_int(iPlayer, m_iFOV, 90, extra_offset_player);
	set_pdata_int(iPlayer, m_fResumeZoom, 0, extra_offset_player);
	set_pdata_int(iPlayer, m_iLastZoom, 90, extra_offset_player);
	
	set_pdata_string(iPlayer, m_szAnimExtention * 4, szAnimExt, -1, extra_offset_player * 4);

	Weapon_SendAnim(iPlayer, iAnim);
}

stock Create_Blood(const Float:vStart[3], const iModel, const iModel2, const iColor, const iScale)
{
	MESSAGE_BEGIN(MSG_BROADCAST, SVC_TEMPENTITY, vStart, 0);
	WRITE_BYTE(TE_BLOODSPRITE);
	WRITE_COORD(vStart[0])
	WRITE_COORD(vStart[1])
	WRITE_COORD(vStart[2])
	WRITE_SHORT(iModel);
	WRITE_SHORT(iModel2);
	WRITE_BYTE(iColor);
	WRITE_BYTE(iScale);
	MESSAGE_END();
}

stock IsWallBetweenPoints(const Float: vecStart[3], const Float: vecEnd[3], PlayerEnt)
{
	static iTrace;iTrace = create_tr2();
	static Float: vecEndPos[3];
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, IGNORE_MONSTERS, PlayerEnt, iTrace);
	get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	free_tr2(iTrace);
	return floatround(get_distance_f(vecEnd, vecEndPos));
} 

public client_putinserver(id)
{
	SetBit(g_bitIsConnected, id);
}

public client_disconnected(id)
{
	ClearBit(g_bitIsConnected, id);
}

bool: CheckItem(const iItem, &iPlayer)
{
	if (!IsValidPev(iItem))
	{
		return false;
	}
	
	iPlayer = get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon);
	
	if (!IsSetBit(g_bitIsConnected, iPlayer) || !IsValidPev(iPlayer) || zp_get_user_zombie(iPlayer) || !IsSetBit(g_iBitUserKnife, iPlayer))
	{
		return false;
	}
	
	return true;
}


//* Some usefull stocks.                       *


stock Weapon_GetGunPosition(const iPlayer, Float: fOrigin[3], Float: fAngles[3], Float: add_forward = 0.0, Float: add_right = 0.0, Float: add_up = 0.0)
{
	static Float: Forward[3], Float: Right[3], Float: Up[3];

	if (IsValidPev(iPlayer)) ExecuteHamB(Ham_Player_GetGunPosition, iPlayer, fOrigin);
	
	pev(iPlayer, pev_angles, fAngles);
	pev(iPlayer, pev_v_angle, fAngles);
	
	global_get(glb_v_forward, Forward);
	global_get(glb_v_right, Right);
	global_get(glb_v_up, Up);
	
	xs_vec_mul_scalar(Forward, add_forward, Forward);
	xs_vec_mul_scalar(Right, add_right, Right);
	xs_vec_mul_scalar(Up, add_up, Up);
	
	fOrigin[0] = fOrigin[0] + Forward[0] + Right[0] + Up[0];
	fOrigin[1] = fOrigin[1] + Forward[1] + Right[1] + Up[1];
	fOrigin[2] = fOrigin[2] + Forward[2] + Right[2] + Up[2];
}

stock FindHullIntersection(const Float: vecSrc[3], &iTrace, const Float: vecMins[3], const Float: vecMaxs[3], const iEntity)
{
	new iTempTrace;
	
	new Float: flFraction;
	new Float: flThisDistance;
	
	new Float: vecEnd[3];
	new Float: vecEndPos[3];
	new Float: vecHullEnd[3];
	new Float: vecMinMaxs[2][3];
	
	new Float: flDistance = 999999.0;
	
	xs_vec_copy(vecMins, vecMinMaxs[0]);
	xs_vec_copy(vecMaxs, vecMinMaxs[1]);
	
	get_tr2(iTrace, TR_vecEndPos, vecHullEnd);
	
	xs_vec_sub(vecHullEnd, vecSrc, vecHullEnd);
	xs_vec_mul_scalar(vecHullEnd, 2.0, vecHullEnd);
	xs_vec_add(vecHullEnd, vecSrc, vecHullEnd);
	
	engfunc(EngFunc_TraceLine, vecSrc, vecHullEnd, DONT_IGNORE_MONSTERS, iEntity, (iTempTrace = create_tr2()));
	get_tr2(iTempTrace, TR_flFraction, flFraction);
	
	if (flFraction < 1.0)
	{
		free_tr2(iTrace);
		
		iTrace = iTempTrace;
		return;
	}
	
	for (new j, k, i = 0; i < 2; i++)
	{
		for (j = 0; j < 2; j++)
		{
			for (k = 0; k < 2; k++)
			{
				vecEnd[0] = vecHullEnd[0] + vecMinMaxs[i][0];
				vecEnd[1] = vecHullEnd[1] + vecMinMaxs[j][1];
				vecEnd[2] = vecHullEnd[2] + vecMinMaxs[k][2];
				
				engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, iEntity, iTempTrace);
				get_tr2(iTempTrace, TR_flFraction, flFraction);
				
				if (flFraction < 1.0)
				{
					get_tr2(iTempTrace, TR_vecEndPos, vecEndPos);
					xs_vec_sub(vecEndPos, vecSrc, vecEndPos);
					
					if ((flThisDistance = xs_vec_len(vecEndPos)) < flDistance)
					{
						free_tr2(iTrace);
						
						iTrace = iTempTrace;
						flDistance = flThisDistance;
					}
				}
			}
		}
	}
}

stock FakeKnockBack(iPlayer, Float:vecDirection[3], Float:flKnockBack)
{
	#define m_flPainShock 108

	set_pdata_float(iPlayer, m_flPainShock, 1.0, 5);
	static Float:vecVelocity[3]; pev(iPlayer, pev_velocity, vecVelocity);
	if(pev(iPlayer, pev_flags) & FL_DUCKING) flKnockBack *= 0.45;
	vecVelocity[0] = vecDirection[0] * flKnockBack;
	vecVelocity[1] = vecDirection[1] * flKnockBack;
	vecVelocity[2] = 0.0;
	set_pev(iPlayer, pev_velocity, vecVelocity);
}

stock Player_SetAnimation(const iPlayer, const szAnim[])
{
	#define ACT_RANGE_ATTACK1   28
	   
	// Linux extra offsets
	#define extra_offset_animating   4
	   
	// CBaseAnimating
	#define m_flFrameRate      36
	#define m_flGroundSpeed      37
	#define m_flLastEventCheck   38
	#define m_fSequenceFinished   39
	#define m_fSequenceLoops   40
	   
	// CBaseMonster
	#define m_Activity      73
	#define m_IdealActivity      74
	   
	   // CBasePlayer
	#define m_flLastAttackTime   220
   
	new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
	      
	if ((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
	{
		iAnimDesired = 0;
	}
	   
	new Float: flGametime = get_gametime();
	
	set_pev(iPlayer, pev_frame, 0.0);
	set_pev(iPlayer, pev_framerate, 1.0);
	set_pev(iPlayer, pev_animtime, flGametime);
	set_pev(iPlayer, pev_sequence, iAnimDesired);
	   
	set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, extra_offset_animating);
	set_pdata_int(iPlayer, m_fSequenceFinished, 0, extra_offset_animating);
	   
	set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, extra_offset_animating);
	set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, extra_offset_animating);
	set_pdata_float(iPlayer, m_flLastEventCheck, flGametime , extra_offset_animating);
	   
	set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, extra_offset_player);
	set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, extra_offset_player);   
	set_pdata_float(iPlayer, m_flLastAttackTime, flGametime , extra_offset_player);
}

public Cmd_WeaponSelect(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERANCE);
	return PLUGIN_HANDLED;
}

public MsgHook_Death(const iMsgID, const iMsgDest, const iMsgEntity)
{
	static szWeapon[64];get_msg_arg_string(4, szWeapon, charsmax(szWeapon));
	
	static iPlayer;
	static iItem; 
	
	if (strcmp(szWeapon, "knife"))
	{
		return PLUGIN_CONTINUE;
	}
	
	iPlayer = get_msg_arg_int(1);
	
	iItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);
	
	if (!IsValidPev(iItem) || !IsSetBit(g_iBitUserKnife, iPlayer))
	{	
		return PLUGIN_CONTINUE;
	}

	set_msg_arg_string(4, "hammer");
	
	return PLUGIN_CONTINUE
}

public Weapon_Select(const iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERANCE);
	
	emessage_begin(MSG_ONE, get_user_msgid("CurWeapon"), _, iPlayer);
	ewrite_byte(1);
	ewrite_byte(CSW_KNIFE);
	ewrite_byte(-1);
	emessage_end();
	
	new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);

	if (pev_valid(iItem))
	{
		ExecuteHamB(Ham_Item_Deploy, iItem);
		MsgHook_WeaponList(MSGID_WEAPONLIST, iItem, iPlayer);
	}
}

public MsgHook_WeaponList(const iMsgID, const iMsgDest, const iMsgEntity)
{
	static arrWeaponListData[8];
	
	if (!iMsgEntity)
	{
		new szWeaponName[32];
		get_msg_arg_string(1, szWeaponName, charsmax(szWeaponName));
		
		if (!strcmp(szWeaponName, WEAPON_REFERANCE))
		{
			for (new i, a = sizeof arrWeaponListData; i < a; i++)
			{
				arrWeaponListData[i] = get_msg_arg_int(i + 2);
			}
		}
	}
	else
	{
		if (!IsSetBit(g_iBitUserKnife, iMsgID))
		{
			return;
		}
		
		MESSAGE_BEGIN(MSG_ONE, iMsgID, {0.0, 0.0, 0.0}, iMsgEntity);
		/* WRITE_STRING(IsKnife[iMsgEntity] ? WEAPON_NAME : WEAPON_REFERANCE); */
		
		for (new i, a = sizeof arrWeaponListData; i < a; i++)
		{
			WRITE_BYTE(arrWeaponListData[i]);
		}
		
		MESSAGE_END();
	}
}

PRECACHE_SOUNDS_FROM_MODEL(const szModelPath[])
{
	new iFile;
	
	if ((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for (new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);

			for (k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if (iEvent != 5004)
				{
					continue;
				}

				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if (strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					PRECACHE_SOUND(szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}
