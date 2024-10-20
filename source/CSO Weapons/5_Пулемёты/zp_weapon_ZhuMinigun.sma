#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <zombieplague>
#include <xs>
#include <smart_effects>

#define PLUGIN 					"[ZP] Extra: CSO Weapon Zhu Bajie Minigun"
#define VERSION 				"1.0"
#define AUTHOR 					"KORD_12.7"

#pragma ctrlchar 				'\'
#pragma compress 				1

//**********************************************
//* Weapon Settings.                           *
//**********************************************

#define WPNLIST					//off weaponlist

// Main
#define WEAPON_KEY					1024
#define WEAPON_NAME 				"zp_br_cso/weapons/weapon_m134"

#define WEAPON_REFERANCE			"weapon_m249"
#define WEAPON_MAX_CLIP				100
#define WEAPON_DEFAULT_AMMO			200

#define WEAPON_TIME_NEXT_IDLE 			10.0
#define WEAPON_TIME_NEXT_ATTACK			0.09
#define WEAPON_TIME_DELAY_DEPLOY 		1.0
#define WEAPON_TIME_DELAY_RELOAD 		5.0

#define WEAPON_DAMAGE  	  			1.36
#define WEAPON_DAMAGE_SURV  		2.25
#define WEAPON_DAMAGE_SURV_NEM  	2.4

#define ZP_ITEM_NAME				"M134 Minigun" 
#define ZP_ITEM_COST				0

// Models
#define MODEL_WORLD					"models/zp_br_cso/other/w_weapons_b1.mdl"
#define MODEL_WORLD_BODY 			38
#define MODEL_VIEW					"models/zp_br_cso/weapons/v_m134_b10.mdl"

#define MODEL_SHEEL_762				"models/zp_br_cso/weapons/shell762.mdl"

// Sounds
#define SOUND_FIRE_B				"weapons/m134-1.wav"

// Sprites
#define WEAPON_HUD_TXT				"sprites/zp_br_cso/weapons/weapon_m134.txt"

#define WEAPON_HUD_SPR_1			"sprites/zp_br_cso/weapons/hud/640hud5.spr"
#define WEAPON_HUD_SPR_2			"sprites/zp_br_cso/weapons/hud/ammo1.spr"

// Animation

// native zp_set_item_max_clip(iPlayer, iValue);
// native zp_set_item_max_ammo(iPlayer, iValue);
// forward zp_weapon_buyammo(iPlayer, iActiveItem);

// Animation sequences
enum
{	
	ANIM_IDLE,
	ANIM_SHOOT,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_FIRE_READY,
	ANIM_FIRE_AFTER,
	ANIM_FIRE_CHANGE,
	ANIM_FIRE_END
};

//**********************************************
//* Some macroses.                             *
//**********************************************
#define GET_CHARGE(%0)			get_pdata_int(%0, m_iChargeReady, extra_offset_weapon)
#define SET_CHARGE(%0,%1)		set_pdata_int(%0, m_iChargeReady, %1, extra_offset_weapon)

#define GET_SHOOTS(%0)			get_pdata_int(%0, m_fInCheckShoots, extra_offset_weapon)
#define SET_SHOOTS(%0,%1)		set_pdata_int(%0, m_fInCheckShoots, %1, extra_offset_weapon)

#define MDLL_Spawn(%0)			dllfunc(DLLFunc_Spawn, %0)
#define MDLL_Touch(%0,%1)		dllfunc(DLLFunc_Touch, %0, %1)
#define MDLL_USE(%0,%1)			dllfunc(DLLFunc_Use, %0, %1)

#define SET_MODEL(%0,%1)		engfunc(EngFunc_SetModel, %0, %1)
#define SET_ORIGIN(%0,%1)		engfunc(EngFunc_SetOrigin, %0, %1)

#define PRECACHE_MODEL(%0)		engfunc(EngFunc_PrecacheModel, %0)
#define PRECACHE_SOUND(%0)		engfunc(EngFunc_PrecacheSound, %0)
#define PRECACHE_GENERIC(%0)		engfunc(EngFunc_PrecacheGeneric, %0)

#define MESSAGE_BEGIN(%0,%1,%2,%3)	engfunc(EngFunc_MessageBegin, %0, %1, %2, %3)
#define MESSAGE_END()			message_end()

#define WRITE_ANGLE(%0)			engfunc(EngFunc_WriteAngle, %0)
#define WRITE_BYTE(%0)			write_byte(%0)
#define WRITE_COORD(%0)			engfunc(EngFunc_WriteCoord, %0)
#define WRITE_STRING(%0)		write_string(%0)
#define WRITE_SHORT(%0)			write_short(%0)

#define BitSet(%0,%1) 			(%0 |= (1 << (%1 - 1)))
#define BitClear(%0,%1) 		(%0 &= ~(1 << (%1 - 1)))
#define BitCheck(%0,%1) 		(%0 & (1 << (%1 - 1)))

//**********************************************
//* PvData Offsets.                            *
//**********************************************

// Linux extra offsets
#define extra_offset_weapon		4
#define extra_offset_player		5
#define linux_diff_animating 4

new g_bitIsConnected;

#define m_rgpPlayerItems_CWeaponBox	34
#define m_fInCheckShoots		39

// CBasePlayerItem
#define m_pPlayer			41
#define m_pNext				42
#define m_iId                        	43

// CBasePlayerWeapon
#define m_fFireOnEmpty 			45
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle		48
#define m_iPrimaryAmmoType		49
#define m_iClip				51
#define m_fInReload			54
#define m_iChargeReady			55
#define m_iShellId 			57
#define m_flAccuracy 			62
#define m_flNextAttack			83
#define m_flStunPower 			108
#define m_iLastZoom 			109
#define m_fResumeZoom       		110
#define m_flEjectBrass 			111

// CBasePlayer
#define m_iFOV				363
#define m_rgpPlayerItems_CBasePlayer	367
#define m_pActiveItem			373
#define m_rgAmmo_CBasePlayer		376
#define m_szAnimExtention		492

#define IsValidPev(%0) 			(pev_valid(%0) == 2)
#define INSTANCE(%0)			((%0 == -1) ? 0 : %0)

//**********************************************
//* Let's code our weapon.                     *
//**********************************************

new iShell

Weapon_OnPrecache()
{
	PRECACHE_SOUND_FROM_MODEL(MODEL_VIEW);
	
	PRECACHE_MODEL(MODEL_VIEW);
	
	iShell = PRECACHE_MODEL(MODEL_SHEEL_762);

	PRECACHE_SOUND(SOUND_FIRE_B);
	
	#if defined WPNLIST
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_1);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_2);
	#endif
}

Weapon_OnSpawn(const iItem)
{
	// Setting world model.
	SET_MODEL(iItem, MODEL_WORLD);
}

Weapon_OnDeploy(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary
		
	static iszViewModel;
	if (iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, MODEL_VIEW)))
	{
		set_pev_string(iPlayer, pev_viewmodel2, iszViewModel);
	}
	

	set_pdata_int(iItem, m_fInReload, 0, extra_offset_weapon);
	

	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_DEPLOY, extra_offset_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_DEPLOY, extra_offset_player);

	Weapon_DefaultDeploy(iPlayer, MODEL_VIEW, ANIM_DRAW);
	
	set_pdata_string(iPlayer, m_szAnimExtention * 4, "m134", -1, extra_offset_player * linux_diff_animating);
}

Weapon_OnHolster(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iPlayer, iClip, iAmmoPrimary
	
	set_pdata_int(iItem, m_fInReload, 0, extra_offset_weapon);
	
	SET_CHARGE(iItem, 0);
	SET_SHOOTS(iItem, 0);
}

Weapon_OnIdle(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary

	ExecuteHamB(Ham_Weapon_ResetEmptySound, iItem);
	
	if (get_pdata_float(iItem, m_flNextPrimaryAttack, extra_offset_weapon) > 0.0)
	{
		return;
	}
	
	if (GET_CHARGE(iItem) > 0)
	{
		Weapon_OnShootEnd(iItem,iPlayer);
		return;
	}
	
	if (get_pdata_float(iItem, m_flTimeWeaponIdle, extra_offset_weapon) > 0.0)
	{
		return;
	}
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_IDLE, extra_offset_weapon);
	
	Weapon_SendAnim(iPlayer, ANIM_IDLE);
}

Weapon_OnReload(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iAmmoPrimary
	
	if (min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary) <= 0)
	{
		return;
	}
	
	if (GET_CHARGE(iItem) > 0)
	{
		Weapon_OnShootEnd(iItem,iPlayer);
		return;
	}

	set_pdata_int(iItem, m_iClip, 0, extra_offset_weapon);
	
	ExecuteHam(Ham_Weapon_Reload, iItem);
	
	set_pdata_int(iItem, m_iClip, iClip, extra_offset_weapon);
	
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_RELOAD, extra_offset_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_RELOAD, extra_offset_weapon);
	
	Weapon_SendAnim(iPlayer, ANIM_RELOAD);
}

Weapon_OnPrimaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iAmmoPrimary
	
	switch(GET_CHARGE(iItem))
	{
		case 0:
		{
			Weapon_SendAnim(iPlayer, ANIM_FIRE_READY);
			
			set_pdata_float(iItem, m_flTimeWeaponIdle, 1.0, extra_offset_weapon);
			set_pdata_float(iItem, m_flNextPrimaryAttack, 1.0, extra_offset_weapon);
			set_pdata_float(iItem, m_flNextSecondaryAttack, 1.0, extra_offset_weapon);
			
			SET_CHARGE(iItem, 1);
			
			// engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, SOUND_FIRE_START, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
		case 1:
		{
			Weapon_OnShoot(iItem, iPlayer, iClip)
		}
	}
}

Weapon_OnShoot(const iItem, const iPlayer, const iClip)
{
	CallOrigFireBullets3(iItem, iPlayer)

	if (iClip <= 0)
	{
		Weapon_OnShootEnd(iItem,iPlayer);
		return;
	}
	
	if (GET_SHOOTS(iItem) <= 99)
	{
		SET_SHOOTS(iItem, GET_SHOOTS(iItem)+1);
	}
	
	//new Float:vecPunch[3]; get_entvar(iPlayer, var_punchangle, vecPunch);

	switch(GET_SHOOTS(iItem))
	{
		case 0..10:
		{
			Punchangle(iPlayer, .iVecx = random_float(-1.0, -1.3), .iVecy = random_float(0.3, -0.3), .iVecz = 0.0);
			//UTIL_WeaponKickBack(iItem, iPlayer, vecPunch[0], vecPunch[1], 1.1, 1.1, 1.3, 0.3, 1);
		}
		case 11..20:
		{
			Punchangle(iPlayer, .iVecx = random_float(-1.0, -1.65), .iVecy = random_float(0.67, -0.67), .iVecz = 0.0);
			//UTIL_WeaponKickBack(iItem, iPlayer, vecPunch[0], vecPunch[1], 1.1, 1.1, 1.65, 0.67, 1);
		}
		case 21..30:
		{
			Punchangle(iPlayer, .iVecx = random_float(-1.0, -2.0), .iVecy = random_float(1.10, -1.10), .iVecz = 0.0);
			//UTIL_WeaponKickBack(iItem, iPlayer, vecPunch[0], vecPunch[1], 1.1, 1.1, 2.0, 1.15, 1);
		}
		case 31..40:
		{
			Punchangle(iPlayer, .iVecx = random_float(-1.0, -2.25), .iVecy = random_float(1.45, -1.45), .iVecz = 0.0);
			//UTIL_WeaponKickBack(iItem, iPlayer, vecPunch[0], vecPunch[1], 1.1, 1.1, 2.25, 1.55, 1);
		}
		case 41..50:
		{
			Punchangle(iPlayer, .iVecx = random_float(-1.0, -2.5), .iVecy = random_float(1.8, -1.8), .iVecz = 0.0);
			//UTIL_WeaponKickBack(iItem, iPlayer, vecPunch[0], vecPunch[1], 1.1, 1.1, 2.5, 1.85, 1);
		}
		case 51..60:
		{
			Punchangle(iPlayer, .iVecx = random_float(-1.0, -2.8), .iVecy = random_float(2.10, -2.10), .iVecz = 0.0);
			//UTIL_WeaponKickBack(iItem, iPlayer, vecPunch[0], vecPunch[1], 1.1, 1.1, 2.8, 2.15, 1);
		}
		case 61..70:
		{
			Punchangle(iPlayer, .iVecx = random_float(-1.0, -3.15), .iVecy = random_float(2.40, -2.40), .iVecz = 0.0);
			//UTIL_WeaponKickBack(iItem, iPlayer, vecPunch[0], vecPunch[1], 1.1, 1.1, 3.15, 2.45, 1);
		}
		case 71..80:
		{
			Punchangle(iPlayer, .iVecx = random_float(-1.0, -3.4), .iVecy = random_float(2.715, -2.715), .iVecz = 0.0);
			//UTIL_WeaponKickBack(iItem, iPlayer, vecPunch[0], vecPunch[1], 1.1, 1.1, 3.4, 2.72, 1);
		}
		case 81..90:
		{
			Punchangle(iPlayer, .iVecx = random_float(-1.0, -3.75), .iVecy = random_float(3.075, -3.075), .iVecz = 0.0);
			//UTIL_WeaponKickBack(iItem, iPlayer, vecPunch[0], vecPunch[1], 1.1, 1.1, 3.75, 3.05, 1);
		}
		default:
		{
			Punchangle(iPlayer, .iVecx = random_float(-1.0, -4.05), .iVecy = random_float(3.35, -3.35), .iVecz = 0.0);
			//UTIL_WeaponKickBack(iItem, iPlayer, vecPunch[0], vecPunch[1], 1.1, 1.1, 4.05, 3.35, 1);
		}
	}

	//Punchangle(iPlayer, .iVecx = random_float(-1.0, -1.4), .iVecy = random_float(-1.9, 1.9), .iVecz = 0.0);
	
	set_pdata_int(iItem, m_iShellId, iShell, extra_offset_weapon);
	set_pdata_float(iPlayer, m_flEjectBrass, get_gametime() - 1.0);
			
	Weapon_SendAnim(iPlayer, ANIM_SHOOT);
		
	set_pdata_float(iItem, m_flAccuracy, 0.8, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_ATTACK + 0.6, extra_offset_weapon);
			
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE_B, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

Weapon_OnShootEnd(const iItem, const iPlayer)
{
	Weapon_SendAnim(iPlayer, ANIM_FIRE_AFTER);
			
	set_pdata_float(iItem, m_flTimeWeaponIdle, 1.0, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.75, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.75, extra_offset_weapon);
			
	// engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, SOUND_FIRE_END, 1.0, ATTN_NORM, 0, PITCH_NORM);		
	
	SET_CHARGE(iItem, 0);
	SET_SHOOTS(iItem, 0);
}
	
//*********************************************************************
//*           Don't modify the code below this line unless            *
//*          	 you know _exactly_ what you are doing!!!             *
//*********************************************************************

#define MSGID_WEAPONLIST 78

new g_iItemID;

#define IsCustomItem(%0) (pev(%0, pev_impulse) == WEAPON_KEY)

public plugin_precache()
{
	Weapon_OnPrecache();

	#if defined WPNLIST
	register_clcmd(WEAPON_NAME, "Cmd_WeaponSelect");
	register_message(MSGID_WEAPONLIST, "MsgHook_WeaponList");
	#endif
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_forward(FM_PlaybackEvent,				"FakeMeta_PlaybackEvent",	 false);
	register_forward(FM_SetModel,					"FakeMeta_SetModel",		 false);
	register_forward(FM_UpdateClientData,				"FakeMeta_UpdateClientData_Post", true);
	
	register_event("HLTV", "EventHLTV", "a", "1=0", "2=0")

	RegisterHam(Ham_Spawn, 			"weaponbox", 		"HamHook_Weaponbox_Spawn_Post", true);
	
	RegisterHam(Ham_TraceAttack,		"func_breakable",	"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_TraceAttack,		"info_target", 		"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_TraceAttack,		"player", 		"HamHook_Entity_TraceAttack", 	false);

	RegisterHam(Ham_Item_Deploy,		WEAPON_REFERANCE, 	"HamHook_Item_Deploy_Post",	true);
	RegisterHam(Ham_Item_Holster,		WEAPON_REFERANCE, 	"HamHook_Item_Holster",		false);
	#if defined WPNLIST
	RegisterHam(Ham_Item_AddToPlayer,	WEAPON_REFERANCE, 	"HamHook_Item_AddToPlayer",	false);
	#endif
	RegisterHam(Ham_Item_PostFrame,		WEAPON_REFERANCE, 	"HamHook_Item_PostFrame",	false);
	
	RegisterHam(Ham_Weapon_Reload,		WEAPON_REFERANCE, 	"HamHook_Item_Reload",		false);
	RegisterHam(Ham_Weapon_WeaponIdle,	WEAPON_REFERANCE, 	"HamHook_Item_WeaponIdle",	false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERANCE, 	"HamHook_Item_PrimaryAttack",	false);
	
	g_iItemID = zp_register_extra_item(ZP_ITEM_NAME, ZP_ITEM_COST, ZP_TEAM_HUMAN);
}

public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_iItemID)
	{
		Weapon_Give(id);
	}
}

public zp_user_humanized_post(iPlayer, iSurvivor)
{
	if(iSurvivor) 
	{
		Weapon_Give(iPlayer);
	}
}

public EventHLTV()
{
	for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++)
	{
		if(!is_user_alive(iPlayer) || !zp_get_user_survivor(iPlayer)) continue;
	
		rg_remove_item(iPlayer, "weapon_m249", true);
	}
}

public plugin_natives()
{ 
	register_native("GetZhuBajieMinigun", "NativeGiveWeapon", 1) 
}

public NativeGiveWeapon(iPlayer)
{
	Weapon_Give(iPlayer);
}

//**********************************************
//* Block client weapon.                       *
//**********************************************

public FakeMeta_UpdateClientData_Post(const iPlayer, const iSendWeapons, const CD_Handle)
{
	static iActiveItem;iActiveItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);

	if (!IsValidPev(iActiveItem) || !IsCustomItem(iActiveItem))
	{
		return FMRES_IGNORED;
	}
	
	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
	
	return FMRES_IGNORED;
}


//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

	#define _call.%0(%1,%2) \
									\
	Weapon_On%0							\
	(								\
		%1, 							\
		%2,							\
									\
		get_pdata_int(%1, m_iClip, extra_offset_weapon),	\
		GetAmmoInventory(%2, PrimaryAmmoIndex(%1))		\
	) 

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

public HamHook_Item_Reload(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_call.Reload(iItem, iPlayer);
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

public HamHook_Item_PostFrame(const iItem)
{
	static iPlayer;

	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}

	if (get_pdata_int(iItem, m_fInReload, extra_offset_weapon))
	{
		new iClip		= get_pdata_int(iItem, m_iClip, extra_offset_weapon); 
		new iPrimaryAmmoIndex	= PrimaryAmmoIndex(iItem);
		new iAmmoPrimary	= GetAmmoInventory(iPlayer, iPrimaryAmmoIndex);
		new iAmount		= min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary);
		
		set_pdata_int(iItem, m_iClip, iClip + iAmount, extra_offset_weapon);
		set_pdata_int(iItem, m_fInReload, false, extra_offset_weapon);

		SetAmmoInventory(iPlayer, iPrimaryAmmoIndex, iAmmoPrimary - iAmount);
	}
	
	return HAM_IGNORED;
}	

//**********************************************
//* Fire Bullets.                              *
//**********************************************

CallOrigFireBullets3(const iItem, const iPlayer)
{
	static fm_hooktrace; fm_hooktrace=register_forward(FM_TraceLine,"FakeMeta_TraceLine",true)
	
	state FireBullets: Enabled;
	static Float: vecPuncheAngle[3];
	pev(iPlayer, pev_punchangle, vecPuncheAngle);
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	set_pev(iPlayer, pev_punchangle, vecPuncheAngle);
	state FireBullets: Disabled;
	
	unregister_forward(FM_TraceLine,fm_hooktrace,true)
}

public FakeMeta_PlaybackEvent() <FireBullets: Enabled>
{
	return FMRES_SUPERCEDE;
}

public FakeMeta_TraceLine(Float:vecStart[3], Float:VecEnd[3], iFlags, Ignore, iTrase)// Chrescoe1
{
	if (iFlags & IGNORE_MONSTERS)
	{
		return FMRES_IGNORED;
	}
	
	static iHit;
	static iDecal;
	static glassdecal;
	static Float:vecPlaneNormal[3];
	static Float:vecEndPos[3];
	
	iHit=get_tr2(iTrase,TR_pHit);
	
	if (!glassdecal)
	{
		glassdecal=engfunc( EngFunc_DecalIndex, "{bproof1" );
	}
	
	if(iHit>0 && pev_valid(iHit))
		if(pev(iHit,pev_solid)!=SOLID_BSP)return FMRES_IGNORED;
		else if(pev(iHit,pev_rendermode)!=0)iDecal=glassdecal;
		else iDecal=random_num(41,45);
	else iDecal=random_num(41,45);
	
	get_tr2(iTrase, TR_vecEndPos, vecEndPos);
	get_tr2(iTrase, TR_vecPlaneNormal, vecPlaneNormal);
	
	MESSAGE_BEGIN(MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
	WRITE_BYTE(TE_GUNSHOTDECAL);
	WRITE_COORD(vecEndPos[0]);
	WRITE_COORD(vecEndPos[1]);
	WRITE_COORD(vecEndPos[2]);
	WRITE_SHORT(iHit > 0 ? iHit : 0);
	WRITE_BYTE(iDecal);
	MESSAGE_END();
	
	MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, vecEndPos, 0);
	WRITE_BYTE(TE_STREAK_SPLASH)
	WRITE_COORD(vecEndPos[0]);
	WRITE_COORD(vecEndPos[1]);
	WRITE_COORD(vecEndPos[2]);
	WRITE_COORD(vecPlaneNormal[0] * random_float(20.0,30.0));
	WRITE_COORD(vecPlaneNormal[1] * random_float(20.0,30.0));
	WRITE_COORD(vecPlaneNormal[2] * random_float(20.0,30.0));
	WRITE_BYTE(26);	
	WRITE_SHORT(10);	
	WRITE_SHORT(3);		
	WRITE_SHORT(60);
	MESSAGE_END();

	return FMRES_IGNORED;
}

public HamHook_Entity_TraceAttack(const iEntity, const iAttacker, const Float: flDamage) <FireBullets: Enabled>
{
	if (!BitCheck(g_bitIsConnected, iAttacker) || !IsValidPev(iAttacker))
	{
		return;
	}
	
	if(zp_get_user_survivor(iAttacker))
	{
		if(is_user_alive(iEntity) && zp_get_user_nemesis(iEntity))
		{
			SetHamParamFloat(3, flDamage * WEAPON_DAMAGE_SURV_NEM);
		}
		else
		{
			SetHamParamFloat(3, flDamage * WEAPON_DAMAGE_SURV);
		}
	}
	else
	{
		SetHamParamFloat(3, flDamage * WEAPON_DAMAGE)
	}
}

public MsgHook_Death()			</* Empty statement */>		{ /* Fallback */ }
public MsgHook_Death()			<FireBullets: Disabled>		{ /* Do notning */ }

public FakeMeta_PlaybackEvent() 	</* Empty statement */>		{ return FMRES_IGNORED; }
public FakeMeta_PlaybackEvent() 	<FireBullets: Disabled>		{ return FMRES_IGNORED; }

public HamHook_Entity_TraceAttack() 	</* Empty statement */>		{ /* Fallback */ }
public HamHook_Entity_TraceAttack() 	<FireBullets: Disabled>		{ /* Do notning */ }

Weapon_Create(const Float: vecOrigin[3] = {0.0, 0.0, 0.0}, const Float: vecAngles[3] = {0.0, 0.0, 0.0})
{
	new iWeapon;

	static iszAllocStringCached;
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, WEAPON_REFERANCE)))
	{
		iWeapon = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (!IsValidPev(iWeapon))
	{
		return FM_NULLENT;
	}
	
	MDLL_Spawn(iWeapon);
	SET_ORIGIN(iWeapon, vecOrigin);
	
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, extra_offset_weapon);

	set_pev(iWeapon, pev_impulse, WEAPON_KEY);
	set_pev(iWeapon, pev_angles, vecAngles);
	
	Weapon_OnSpawn(iWeapon);
	
	return iWeapon;
}

Weapon_Give(const iPlayer)
{
	if (!IsValidPev(iPlayer))
	{
		return FM_NULLENT;
	}
	
	new iWeapon, Float: vecOrigin[3];
	pev(iPlayer, pev_origin, vecOrigin);
	
	if ((iWeapon = Weapon_Create(vecOrigin)) != FM_NULLENT)
	{
		Player_DropWeapons(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));
		
		set_pev(iWeapon, pev_spawnflags, pev(iWeapon, pev_spawnflags) | SF_NORESPAWN);
		MDLL_Touch(iWeapon, iPlayer);
		
		SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iWeapon), WEAPON_DEFAULT_AMMO);
		
		return iWeapon;
	}
	
	return FM_NULLENT;
}

Player_DropWeapons(const iPlayer, const iSlot)
{
	new szWeaponName[32], iItem = get_pdata_cbase(iPlayer, m_rgpPlayerItems_CBasePlayer + iSlot, extra_offset_player);

	while (IsValidPev(iItem))
	{
		pev(iItem, pev_classname, szWeaponName, charsmax(szWeaponName));
		engclient_cmd(iPlayer, "drop", szWeaponName);

		iItem = get_pdata_cbase(iItem, m_pNext, extra_offset_weapon);
	}
}

Weapon_SendAnim(const iPlayer, const iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, iPlayer);
	WRITE_BYTE(iAnim);
	WRITE_BYTE(0);
	MESSAGE_END();
}

stock Weapon_DefaultDeploy(const iPlayer, const szViewModel[], const iAnim)
{
	set_pev(iPlayer, pev_viewmodel2, szViewModel);
	

	set_pev(iPlayer, pev_fov, 90.0);
	
	set_pdata_int(iPlayer, m_iFOV, 90, extra_offset_player);
	set_pdata_int(iPlayer, m_fResumeZoom, 0, extra_offset_player);
	set_pdata_int(iPlayer, m_iLastZoom, 90, extra_offset_player);
	
	Weapon_SendAnim(iPlayer, iAnim);
}

stock Punchangle(iPlayer, Float:iVecx = 0.0, Float:iVecy = 0.0, Float:iVecz = 0.0)
{
	new Float:vecPunch[3]; vecPunch[0] = iVecx; vecPunch[1] = iVecy; vecPunch[2] = iVecz;
	set_pev(iPlayer, pev_punchangle, vecPunch);
}

public client_putinserver(id)
{
	BitSet(g_bitIsConnected, id);
}

public client_disconnected(id)
{
	BitClear(g_bitIsConnected, id);
}

bool: CheckItem(const iItem, &iPlayer)
{
	if (!IsValidPev(iItem) || !IsCustomItem(iItem))
	{
		return false;
	}
	
	iPlayer = get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon);
	
	if (!IsValidPev(iPlayer) || !BitCheck(g_bitIsConnected, iPlayer))
	{
		return false;
	}
	
	return true;
}

//**********************************************
//* Weapon list update.                        *
//**********************************************

#if defined WPNLIST
public Cmd_WeaponSelect(const iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERANCE);
	return PLUGIN_HANDLED;
}
#endif

#if defined WPNLIST
public HamHook_Item_AddToPlayer(const iItem, const iPlayer)
{
	if (!IsValidPev(iItem) || !IsValidPev(iPlayer))
	{
		return HAM_IGNORED;
	}
	
	switch(pev(iItem, pev_impulse))
	{
		case 0: 
		{
			MsgHook_WeaponList(MSGID_WEAPONLIST, iItem, iPlayer);
		}
		case WEAPON_KEY: 
		{
			MsgHook_WeaponList(MSGID_WEAPONLIST, iItem, iPlayer);
			SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iItem), pev(iItem, pev_iuser2));
		}
	}
	
	return HAM_IGNORED;
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
		if (!IsCustomItem(iMsgDest) && pev(iMsgDest, pev_impulse))
		{
			return;
		}
		
		MESSAGE_BEGIN(MSG_ONE, iMsgID, {0.0, 0.0, 0.0}, iMsgEntity);
		WRITE_STRING(IsCustomItem(iMsgDest) ? WEAPON_NAME : WEAPON_REFERANCE);
		
		for (new i, a = sizeof arrWeaponListData; i < a; i++)
		{
			WRITE_BYTE(arrWeaponListData[i]);
		}
		
		MESSAGE_END();
	}
}


#endif

//**********************************************
//* Weaponbox world model.                     *
//**********************************************

public HamHook_Weaponbox_Spawn_Post(const iWeaponBox)
{
	if (IsValidPev(iWeaponBox))
	{
		state (IsValidPev(pev(iWeaponBox, pev_owner))) WeaponBox: Enabled;
	}
	
	return HAM_IGNORED;
}

public FakeMeta_SetModel(const iEntity) <WeaponBox: Enabled>
{
	state WeaponBox: Disabled;
	
	if (!IsValidPev(iEntity))
	{
		return FMRES_IGNORED;
	}
	
	#define MAX_ITEM_TYPES	6
	
	for (new i, iItem; i < MAX_ITEM_TYPES; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, extra_offset_weapon);
		
		if (IsValidPev(iItem) && IsCustomItem(iItem))
		{
			SET_MODEL(iEntity, MODEL_WORLD);	
			set_pev(iItem, pev_iuser2, GetAmmoInventory(pev(iEntity,pev_owner), PrimaryAmmoIndex(iItem)))
			set_pev(iEntity, pev_body, MODEL_WORLD_BODY)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public FakeMeta_SetModel()	</* Empty statement */>	{ /*  Fallback  */ return FMRES_IGNORED; }
public FakeMeta_SetModel() 	< WeaponBox: Disabled >	{ /* Do nothing */ return FMRES_IGNORED; }

//**********************************************
//* Ammo Inventory.                            *
//**********************************************

PrimaryAmmoIndex(const iItem)
{
	return get_pdata_int(iItem, m_iPrimaryAmmoType, extra_offset_weapon);
}

GetAmmoInventory(const iPlayer, const iAmmoIndex)
{
	if (iAmmoIndex == -1)
	{
		return -1;
	}

	return get_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, extra_offset_player);
}

SetAmmoInventory(const iPlayer, const iAmmoIndex, const iAmount)
{
	if (iAmmoIndex == -1)
	{
		return 0;
	}

	set_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, iAmount, extra_offset_player);
	return 1;
}


PRECACHE_SOUND_FROM_MODEL(const szModelPath[])
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
