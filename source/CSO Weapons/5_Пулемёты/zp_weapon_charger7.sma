#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <zpe_knokcback>

#define PLUGIN 					"[ZP] Extra: CSO Weapon Charger 7"
#define VERSION 				"1.1"
#define AUTHOR 					"KORD_12.7"

#pragma ctrlchar '\'

//**********************************************
//* Weapon Settings.                           *
//**********************************************

#define WPNLIST
#define LIGHT 

// Main
#define WEAPON_KEY					1045
#define WEAPON_NAME 				"zp_br_cso/weapons4/weapon_charger7_b1"

#define WEAPON_REFERANCE			"weapon_m249"
#define WEAPON_MAX_CLIP				100
#define WEAPON_DEFAULT_AMMO			200

#define WEAPON_TIME_NEXT_IDLE 			3.03
#define WEAPON_TIME_NEXT_ATTACK 		0.1 
#define WEAPON_TIME_NEXT_ATTACK_B 		1.0
#define WEAPON_TIME_DELAY_DEPLOY 		1.0
#define WEAPON_TIME_DELAY_RELOAD 		5.03

#define WEAPON_DAMAGE  	  			1.25
#define WEAPON_DAMAGE_B				random_float(400.0, 600.0)

#define ZP_ITEM_NAME				"Charger-7" 
#define ZP_ITEM_COST				0

// Models
#define MODEL_WORLD					"models/zp_br_cso/other/w_weapons4.mdl"
#define MODEL_WORLD_BODY 			1
#define MODEL_VIEW					"models/zp_br_cso/weapons4/v_charger7_b1.mdl"

// Sounds
#define SOUND_FIRE					"weapons/charger7-1.wav"
#define SOUND_FIRE_B				"weapons/charger7-2.wav"

// Sprites
#define WEAPON_HUD_TXT				"sprites/zp_br_cso/weapons4/weapon_charger7_b1.txt"
#define WEAPON_HUD_SPR_1			"sprites/zp_br_cso/weapons4/hud/640hud165.spr"
#define WEAPON_HUD_SPR_2			"sprites/zp_br_cso/weapons4/hud/640hud7.spr"

// Animation

// Animation sequences
enum
{	
	ANIM_IDLE,
	ANIM_SHOOT,
	ANIM_SHOOT_LASER,
	ANIM_RELOAD,
	ANIM_DRAW
};
//**********************************************
//* Some macroses.                             *
//**********************************************

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

new g_bitIsConnected;

new const iWeaponList[] = {  
	3, 200,-1, -1, 0, 4, 20, 0 // weapon_m249
};

#define m_rgpPlayerItems_CWeaponBox	34

// CBasePlayerItem
#define m_pPlayer			41
#define m_pNext				42
#define m_iId                        	43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle		48
#define m_iPrimaryAmmoType		49
#define m_iClip				51
#define m_fInReload			54
#define m_flAccuracy 			62
#define m_iShotsFired 		64
#define m_iWeaponState 		74
#define m_iLastZoom 			109

// CBaseMonster
#define m_flNextAttack			83

// CBasePlayer
#define m_fResumeZoom       		110
#define m_iFOV				363
#define m_rgpPlayerItems_CBasePlayer	367
#define m_pActiveItem			373
#define m_rgAmmo_CBasePlayer		376
#define m_szAnimExtention		492

#define IsValidPev(%0) 			(pev_valid(%0) == 2)

#define INSTANCE(%0)			((%0 == -1) ? 0 : %0)

#define IsCustomItem(%0) 		(pev(%0, pev_impulse) == WEAPON_KEY)

//**********************************************
//* Let's code our weapon.                     *
//**********************************************

new iRound;
new iBlood[3];

Weapon_OnPrecache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	
	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_FIRE_B);
	
	#if defined WPNLIST
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_1);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_2);
	#endif
	
	iBlood[0] = PRECACHE_MODEL("sprites/bloodspray.spr");
	iBlood[1] = PRECACHE_MODEL("sprites/blood.spr");
	iBlood[2] = PRECACHE_MODEL("sprites/smoke.spr");
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
	
	Update_StatusIcon(iItem, iPlayer, 0);
	Update_StatusIcon(iItem, iPlayer, 1);
}

Weapon_OnHolster(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iPlayer, iClip, iAmmoPrimary
	
	set_pdata_int(iItem, m_fInReload, 0, extra_offset_weapon);
	Update_StatusIcon(iItem, iPlayer, 0);
}

Weapon_OnIdle(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary

	ExecuteHamB(Ham_Weapon_ResetEmptySound, iItem);
	
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
	
	set_pdata_int(iItem, m_iClip, 0, extra_offset_weapon);
	
	ExecuteHam(Ham_Weapon_Reload, iItem);
	
	set_pdata_int(iItem, m_iClip, iClip, extra_offset_weapon);
	
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_RELOAD, extra_offset_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_RELOAD, extra_offset_weapon);
	
	Weapon_SendAnim(iPlayer, ANIM_RELOAD);
}

Weapon_OnPrimaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary
	
	CallOrigFireBullets3(iItem, iPlayer);
	
	if(get_pdata_int(iItem, m_iClip, 4) == 0) 
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, 4);
		return HAM_SUPERCEDE;
	}

	Punchangle(iPlayer, .iVecx = -2.0, .iVecy = random_float(1.0, -1.0), .iVecz = 0.0);
	
	Weapon_SendAnim(iPlayer, ANIM_SHOOT);

	set_pdata_float(iItem, m_flAccuracy, 0.2 ,extra_offset_weapon)
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_ATTACK + 0.6, extra_offset_weapon);
	
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	if(get_pdata_int(iItem, m_iWeaponState, 4) < 5) 
	{
		set_pdata_int(iItem, m_iShotsFired, get_pdata_int(iItem, m_iShotsFired, 4) + 1, 4);
		
		if(!(get_pdata_int(iItem, m_iShotsFired, 4) % 60)) 
		{
			Update_StatusIcon(iItem, iPlayer, 0);
			set_pdata_int(iItem, m_iWeaponState, get_pdata_int(iItem, m_iWeaponState, 4) + 1, 4);
			Update_StatusIcon(iItem, iPlayer, 1);
		}
	}
	
	return HAM_SUPERCEDE;
}

Weapon_OnSecondaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary
	
	if(!get_pdata_int(iItem, m_iWeaponState, 4))
		return HAM_SUPERCEDE;
	
	//static iFlags, iAnimDesired; 
	//static szAnimation[64];iFlags = pev(iPlayer, pev_flags);

	Punchangle(iPlayer, .iVecx = -3.0, .iVecy = 0.0, .iVecz = 0.0);
	
	Weapon_SendAnim(iPlayer, ANIM_SHOOT_LASER);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK_B, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_TIME_NEXT_ATTACK_B, extra_offset_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_ATTACK_B + 0.6, extra_offset_weapon);
	
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, SOUND_FIRE_B, 0.9, ATTN_NORM, 0, PITCH_NORM);
	
	Update_StatusIcon(iItem, iPlayer, 0);
	set_pdata_int(iItem, m_iWeaponState, get_pdata_int(iItem, m_iWeaponState, 4) - 1, 4);
	Update_StatusIcon(iItem, iPlayer, 1);
	
	LaserAttack(iItem, iPlayer);
	
	return HAM_SUPERCEDE;
}

//*********************************************************************
//*           Don't modify the code below this line unless            *
//*          	 you know _exactly_ what you are doing!!!             *
//*********************************************************************

#define MSGID_WEAPONLIST 78

new g_iItemID, g_iMsgID_WeaponList, gl_iMsgID_StatusIcon;

public plugin_precache()
{
	Weapon_OnPrecache();

	#if defined WPNLIST
	register_clcmd(WEAPON_NAME, "Cmd_WeaponSelect");
	#endif
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_logevent("StartRound", 2, "1=Round_Start");  
	register_logevent("EndRound", 2, "1=Round_End");
	
	register_forward(FM_UpdateClientData,				"FakeMeta_UpdateClientData_Post",true);
	register_forward(FM_PlaybackEvent,				"FakeMeta_PlaybackEvent",	 false);
	register_forward(FM_SetModel,					"FakeMeta_SetModel",		 false);

	RegisterHam(Ham_Spawn, 			"weaponbox", 		"HamHook_Weaponbox_Spawn_Post", true);

	RegisterHam(Ham_TraceAttack,		"func_breakable",	"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_TraceAttack,		"info_target", 		"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_TraceAttack,		"player", 		"HamHook_Entity_TraceAttack", 	false);

	RegisterHam(Ham_Item_Deploy,		WEAPON_REFERANCE, 	"HamHook_Item_Deploy_Post",	true);
	RegisterHam(Ham_Item_Holster,		WEAPON_REFERANCE, 	"HamHook_Item_Holster",		false);
	RegisterHam(Ham_Item_AddToPlayer,	WEAPON_REFERANCE, 	"HamHook_Item_AddToPlayer",	1);
	RegisterHam(Ham_Item_PostFrame,		WEAPON_REFERANCE, 	"HamHook_Item_PostFrame",	false);
	
	RegisterHam(Ham_Weapon_Reload,		WEAPON_REFERANCE, 	"HamHook_Item_Reload",		false);
	RegisterHam(Ham_Weapon_WeaponIdle,	WEAPON_REFERANCE, 	"HamHook_Item_WeaponIdle",	false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERANCE, 	"HamHook_Item_PrimaryAttack",	false);
	
	g_iMsgID_WeaponList = get_user_msgid("WeaponList")
	gl_iMsgID_StatusIcon = get_user_msgid("StatusIcon")

	g_iItemID = zp_register_extra_item(	ZP_ITEM_NAME, 		ZP_ITEM_COST, 			ZP_TEAM_HUMAN);
}
	
public zp_extra_item_selected(id, itemid)
{
	if (itemid == g_iItemID)
	{
		Weapon_Give(id);
	}
}

public plugin_natives()
{ 
	register_native("GetCharger5", "NativeGiveWeapon", true) 
}

public NativeGiveWeapon(iPlayer)
{
	Weapon_Give(iPlayer);
}

public zp_user_infected_post(iPlayer) 
{
	new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, 5);
	Update_StatusIcon(iItem, iPlayer, 0);
}

public StartRound()iRound=false;
public EndRound()iRound=true;

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
	static iButton;
	
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
	
	if ((iButton = pev(iPlayer, pev_button)) & IN_ATTACK2 && get_pdata_float(iItem, m_flNextSecondaryAttack, extra_offset_weapon) <= 0.0)
	{
		_call.SecondaryAttack(iItem, iPlayer);
		set_pev(iPlayer, pev_button, iButton & ~IN_ATTACK2);
	}
	
	return HAM_IGNORED;
}	

//**********************************************
//* Fire Bullets.                              *
//**********************************************

CallOrigFireBullets3(const iItem, const iPlayer)
{
	static fm_hooktrace;fm_hooktrace=register_forward(FM_TraceLine,"FakeMeta_TraceLine",true)
	
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
	static Decal;
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
		else if(pev(iHit,pev_rendermode)!=0)Decal=glassdecal;
		else Decal=random_num(41,45);
	else Decal=random_num(41,45);
	
	get_tr2(iTrase, TR_vecEndPos, vecEndPos);
	get_tr2(iTrase, TR_vecPlaneNormal, vecPlaneNormal);
	
	MESSAGE_BEGIN(MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
	WRITE_BYTE(TE_GUNSHOTDECAL);
	WRITE_COORD(vecEndPos[0]);
	WRITE_COORD(vecEndPos[1]);
	WRITE_COORD(vecEndPos[2]);
	WRITE_SHORT(iHit > 0 ? iHit : 0);
	WRITE_BYTE(Decal);
	MESSAGE_END();
	
	MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, vecEndPos, 0);
	WRITE_BYTE(TE_STREAK_SPLASH)
	WRITE_COORD(vecEndPos[0]);
	WRITE_COORD(vecEndPos[1]);
	WRITE_COORD(vecEndPos[2]);
	WRITE_COORD(vecPlaneNormal[0] * random_float(20.0,30.0));
	WRITE_COORD(vecPlaneNormal[1] * random_float(20.0,30.0));
	WRITE_COORD(vecPlaneNormal[2] * random_float(20.0,30.0));
	WRITE_BYTE(198);	//Colorid
	WRITE_SHORT(10);	//Count
	WRITE_SHORT(3);		//Speed
	WRITE_SHORT(60);	//Random speed
	MESSAGE_END();

	return FMRES_IGNORED;
}

public HamHook_Entity_TraceAttack(const iEntity, const iAttacker, const Float: flDamage) <FireBullets: Enabled>
{
	static iItem;

	if (!BitCheck(g_bitIsConnected, iAttacker) || !IsValidPev(iAttacker))
	{
		return;
	}
	
	iItem = get_pdata_cbase(iAttacker, m_pActiveItem, extra_offset_player);
	
	if (!IsValidPev(iItem))
	{
		return;
	}
	
	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
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

LaserAttack(const iItem, const iPlayer)
{
	static Float: vecUp[3];
	static Float: vecDir[3];
	static Float: vecEnd[3];
	static Float: vecSrc[3];
	static Float: vecRight[3];
	static Float: vecDirShooting[3];
	static Float: vecPlane[3];
	static Float: StartOrigin[3];GetWeaponPosition(iPlayer, 22.0, 4.0, -2.0, StartOrigin);
	static Float: iVecx;
	static Float: iVecy;	
	static iTrace;
	
	global_get(glb_v_up, vecUp);
	global_get(glb_v_right, vecRight);
	global_get(glb_v_forward, vecDirShooting);
			
	ExecuteHam(Ham_Player_GetGunPosition, iPlayer, vecSrc);
	
	do{iVecx = random_float(-0.2, 0.2) + random_float(-0.2, 0.2);iVecy = random_float(-0.2, 0.2) + random_float(-0.2, 0.2);}
	while ((iVecx * iVecx + iVecy * iVecy) > 1.0);
	xs_vec_mul_scalar(vecUp, 0.02 * iVecy, vecUp);
	xs_vec_mul_scalar(vecRight, 0.02 * iVecx, vecRight);
	xs_vec_add(vecUp, vecRight, vecDir);
	xs_vec_add(vecDir, vecDirShooting, vecDir);		
	xs_vec_mul_scalar(vecDir, 8192.0, vecUp);
	xs_vec_add(vecSrc, vecUp, vecEnd);
		
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, (iTrace = create_tr2()));
	
	get_tr2(iTrace, TR_vecEndPos, vecEnd);
	get_tr2(iTrace, TR_vecPlaneNormal, vecPlane);
	
	new iVictim = INSTANCE(get_tr2(iTrace, TR_pHit));
	
	if(!iVictim)
	{
		MESSAGE_BEGIN(MSG_BROADCAST,SVC_TEMPENTITY, vecEnd, 0);
		WRITE_BYTE(TE_GUNSHOTDECAL);
		WRITE_COORD(vecEnd[0]);
		WRITE_COORD(vecEnd[1]);
		WRITE_COORD(vecEnd[2]);
		WRITE_SHORT(iVictim);
		WRITE_BYTE(random_num(41,45));
		MESSAGE_END();
		
		MESSAGE_BEGIN(MSG_PVS, SVC_TEMPENTITY, vecEnd, 0);
		WRITE_BYTE(TE_STREAK_SPLASH)
		WRITE_COORD(vecEnd[0]);
		WRITE_COORD(vecEnd[1]);
		WRITE_COORD(vecEnd[2]);
		WRITE_COORD(vecPlane[0] * random_float(30.0,40.0));
		WRITE_COORD(vecPlane[1] * random_float(30.0,40.0));
		WRITE_COORD(vecPlane[2] * random_float(30.0,40.0));
		WRITE_BYTE(232);	//Colorid //137, 145, 151, 232
		WRITE_SHORT(30);	//Count
		WRITE_SHORT(5);		//Speed
		WRITE_SHORT(60);	//Random speed
		MESSAGE_END();
		
		MESSAGE_BEGIN(MSG_PAS, SVC_TEMPENTITY, vecEnd, 0);
		WRITE_BYTE(TE_SPARKS);
		WRITE_COORD(vecEnd[0]);
		WRITE_COORD(vecEnd[1]);
		WRITE_COORD(vecEnd[2]);
		MESSAGE_END();
		
		#if defined LIGHT
		MESSAGE_BEGIN(MSG_BROADCAST, SVC_TEMPENTITY, vecEnd, 0)
		WRITE_BYTE(TE_DLIGHT) // TE id
		WRITE_COORD(vecEnd[0]) // x
		WRITE_COORD(vecEnd[1]) // y
		WRITE_COORD(vecEnd[2]) // z
		WRITE_BYTE(10) // radius
		WRITE_BYTE(39) // r
		WRITE_BYTE(242) // g
		WRITE_BYTE(248) // b
		WRITE_BYTE(5) // life
		WRITE_BYTE(10) // decay rate
		MESSAGE_END();
		#endif
	}

	CreateBeam(StartOrigin, vecEnd, iBlood[2], 1, 8, 50);
	CreateBeam(StartOrigin, vecEnd, iBlood[2], 2, 8, 60);
	CreateBeam(StartOrigin, vecEnd, iBlood[2], 3, 8, 70);
	CreateBeam(StartOrigin, vecEnd, iBlood[2], 4, 8, 80);
	CreateBeam(StartOrigin, vecEnd, iBlood[2], 5, 8, 90);
	CreateBeam(StartOrigin, vecEnd, iBlood[2], 6, 8, 100);
	CreateBeam(StartOrigin, vecEnd, iBlood[2], 7, 8, 110);
	CreateBeam(StartOrigin, vecEnd, iBlood[2], 8, 8, 120);

	ApplyDamage(INSTANCE(get_tr2(iTrace, TR_pHit)), iItem, iPlayer, WEAPON_DAMAGE_B, iTrace, DMG_BULLET);

	free_tr2(iTrace);
}

CreateBeam(const Float:vStart[3], const Float:vEnd[3], const iModel, const iLife, const iWigth, const iBrightness)
{
	MESSAGE_BEGIN(MSG_BROADCAST, SVC_TEMPENTITY, {0.0,0.0,0.0}, 0);
	WRITE_BYTE(TE_BEAMPOINTS);
	WRITE_COORD(vStart[0]);
	WRITE_COORD(vStart[1])
	WRITE_COORD(vStart[2])
	WRITE_COORD(vEnd[0]);
	WRITE_COORD(vEnd[1]);
	WRITE_COORD(vEnd[2]);
	WRITE_SHORT(iModel);
	WRITE_BYTE(0);//StartFrame
	WRITE_BYTE(0);//FrameRate
	WRITE_BYTE(iLife);//Life
	WRITE_BYTE(iWigth);//Width
	WRITE_BYTE(0);//Amplitude
	WRITE_BYTE(39);//R
	WRITE_BYTE(242);//G
	WRITE_BYTE(248);//B
	WRITE_BYTE(iBrightness);//Brightness
	WRITE_BYTE(0);//ScrollSpeed
	MESSAGE_END();
}

ApplyDamage(const iEntity, const iInflictor, const iAttacker, Float: flDamage, const iTrace, const bitsDamageType)
{
	if (!IsValidPev(iEntity))
	{
		return;
	}
	
	if(iRound)
	{
		return;
	}
	
	static iHitGroup;
	static Float: flTakeDamage;
	static Float: vecEndPos[3];
	
	pev(iEntity, pev_takedamage, flTakeDamage);
	
	if (flTakeDamage == DAMAGE_NO)
	{
		return;
	}
	
	if (ExecuteHamB(Ham_IsPlayer, iEntity))
	{
		if(!zp_get_user_zombie(iEntity))
		{
			return;
		}
		
		get_tr2(iTrace, TR_vecEndPos, vecEndPos);

		MESSAGE_BEGIN(MSG_BROADCAST, SVC_TEMPENTITY, vecEndPos, 0);
		WRITE_BYTE(TE_BLOODSPRITE);
		WRITE_COORD(vecEndPos[0]);
		WRITE_COORD(vecEndPos[1]);
		WRITE_COORD(vecEndPos[2]);
		WRITE_SHORT(iBlood[0]);
		WRITE_SHORT(iBlood[1]);
		WRITE_BYTE(76);
		WRITE_BYTE(18);
		MESSAGE_END();
	
		switch ((iHitGroup = get_tr2(iTrace, TR_iHitgroup)))
		{
			case HIT_HEAD:flDamage *= 2;
			case HIT_CHEST:flDamage *= 1;
			case HIT_STOMACH:flDamage *= 1.25;
			case HIT_LEFTARM, HIT_RIGHTARM:flDamage *= 1;
			case HIT_LEFTLEG, HIT_RIGHTLEG:flDamage *= 0.75;
		}
		set_pdata_int(iEntity, 75, iHitGroup, extra_offset_player);
	}
	
	ExecuteHamB(Ham_TakeDamage, iEntity, iInflictor, iAttacker, flDamage, bitsDamageType);
	zp_set_user_knock_by_missile(iEntity, iAttacker, 260.0, 2.8)
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
	static Float:iVec[3];pev(iPlayer, pev_punchangle,iVec);
	iVec[0] = iVecx;iVec[1] = iVecy;iVec[2] = iVecz
	set_pev(iPlayer, pev_punchangle, iVec);
}

stock Update_StatusIcon(iItem, iPlayer, iUpdateMode) {
	new szSprite[33];
	new SuperBullets = get_pdata_int(iItem, m_iWeaponState, 4);
	
	format(szSprite, charsmax(szSprite), "number_%d", SuperBullets);
	
	message_begin(MSG_ONE, gl_iMsgID_StatusIcon, { 0, 0, 0 }, iPlayer);
	if(iUpdateMode && SuperBullets > 0) write_byte(1);
	else write_byte(0);
	write_string(szSprite); 
	write_byte(30);
	write_byte(144); 
	write_byte(255);
	message_end();
}

stock GetWeaponPosition(const iPlayer, Float: forw, Float: right, Float: up, Float: vStart[])
{
	new Float: vOrigin[3], Float: vAngle[3], Float: vForward[3], Float: vRight[3], Float: vUp[3];
	
	pev(iPlayer, pev_origin, vOrigin);
	pev(iPlayer, pev_view_ofs, vUp);
	xs_vec_add(vOrigin, vUp, vOrigin);
	pev(iPlayer, pev_v_angle, vAngle);
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward);
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight);
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp);
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up;
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up;
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up;
}

stock Player_SetAnimation(const iPlayer, const szAnim[])
{
	   if(!is_user_alive(iPlayer))return;
		
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
	   set_pev(iPlayer, pev_animtime, flGametime );
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

public client_putinserver(id)
{
	BitSet(g_bitIsConnected, id);
}

public client_disconnected(id)
{
	BitClear(g_bitIsConnected, id);
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

public HamHook_Item_AddToPlayer(iItem, iPlayer)
{
	switch(pev(iItem, pev_impulse)) 
	{
		case WEAPON_KEY: s_weaponlist(iPlayer, true);
		case 0: s_weaponlist(iPlayer, false);
	}
	
	return HAM_IGNORED;
}

stock s_weaponlist(iPlayer, bool:on) {
	message_begin(MSG_ONE, g_iMsgID_WeaponList, _, iPlayer);
	write_string(on ? WEAPON_NAME : WEAPON_REFERANCE);
	write_byte(iWeaponList[0]);
	write_byte(on ? WEAPON_DEFAULT_AMMO : iWeaponList[1]);
	write_byte(iWeaponList[2]);
	write_byte(iWeaponList[3]);
	write_byte(iWeaponList[4]);
	write_byte(iWeaponList[5]);
	write_byte(iWeaponList[6]);
	write_byte(iWeaponList[7]);
	message_end();
}


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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
