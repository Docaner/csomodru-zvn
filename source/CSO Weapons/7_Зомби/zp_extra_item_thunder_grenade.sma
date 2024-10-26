#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <reapi>
#include <xs>
#include <smart_effects>
#include <smart_messages>
#include <api_weapon_player_model>

native zp_get_user_hero(iPlayer);

#define ITEM_NAME "Thunder"
#define ITEM_COST 0
#define ITEM_TEAM ZP_TEAM_ZOMBIE

#define WEAPON_REFERENCE 	"weapon_hegrenade"
#define WEAPON_IMPULSE		1245
#define WEAPON_CLIP_MAX		1
#define WEAPON_WLIST		"zp_br_cso/grenade/weapon_shock"

#define WEAPON_ICON_NAME	"dmg_chem"
#define WEAPON_ICON_COLOR	{255, 0, 0}

#define GRENADE_SPECIAL_CODE 8375647
#define GRENADE_MODEL_WORLD "models/zp_br_cso/grenade/w_jumpbomb_b2.mdl"
#define GRENADE_MODEL_BODY 0

#define GRENADE_EFFECT_RADIUS 100.0
#define GRENADE_EFFECT_DURATION 10.0
//#define GRENADE_EFFECT_DMG random_float(20.0, 30.0)
#define GRENADE_EFFECT_PUNCH random_float(-50.0, 50.0)
#define GRENADE_EFFECT_THINK 0.25

#define GRENADE_EXPLODE_SOUND "zp_br_cso/zombie/zombie_grenade_shock_explode.wav"

#define GRENADE_RENDER_COLOR Float:{255.0, 0.0, 0.0}

#define GRENADE_TRAIL_MODEL "sprites/laserbeam.spr"
#define GRENADE_TRAIL_COLORALPHA {255, 0, 0, 200}

#define GRENADE_TORUS_MODEL "sprites/laserbeam.spr"
new const GRENADE_TORUS_COLORALPHA[][4] =
{
	{66, 177, 255, 70},
	{0, 0, 255, 60},
	{255, 192, 203, 50}
}

new const GRENADE_HIT_SOUNDS[][] =
{
	"zp_br_cso/zombie/zombie_grenade_bounce_1.wav",
	"zp_br_cso/zombie/zombie_grenade_bounce_2.wav"
}

new const g_szWeaponReferences[][] = {
	"weapon_p228", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4",
	"weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", 
	"weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", 
	"weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", 
	"weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", 
	"weapon_knife", "weapon_p90"
};

new g_iItemID, bool:g_bRoundEnd;

new g_iModelIndex_Trail, g_iModelIndex_Torus;

new g_iEnt_Effect[33], g_iUserBitEffect;

new HamHook:g_hWeaponPrimaryAttack[sizeof g_szWeaponReferences], 
	HamHook:g_hWeaponSecondaryAttack[sizeof g_szWeaponReferences];

public plugin_precache()
{
	register_plugin("[ZP] Extra Item: Thunder", "1.0", "Docaner & MeatGrinder")

	UTIL_PrecacheWeaponList(WEAPON_WLIST);

	precache_sound(GRENADE_EXPLODE_SOUND);

	for(new i, iSize = sizeof GRENADE_HIT_SOUNDS; i < iSize; i++)
		precache_sound(GRENADE_HIT_SOUNDS[i]);
	
	g_iModelIndex_Trail = precache_model(GRENADE_TRAIL_MODEL);
	g_iModelIndex_Torus = precache_model(GRENADE_TORUS_MODEL);

	register_clcmd(WEAPON_WLIST, "@ClCmd__HookWeapon");
}

public plugin_init()
{
	RegisterHookChain(RG_CSGameRules_RestartRound, "@RG__RestartRound_Pre", false);
	RegisterHookChain(RH_SV_StartSound, "@RH__StartSound_Pre", false);
	RegisterHookChain(RG_ThrowHeGrenade, "@RG__Throw_HeGrenade_Post", true);
	RegisterHookChain(RG_CGrenade_ExplodeHeGrenade, "@RG__Explode_HeGrenade_Pre", false);

	RegisterHookChain(RG_CBasePlayer_Killed, "@RG__PlayerKilled_Pre", false);

	RegisterHam(Ham_Item_AddToPlayer, WEAPON_REFERENCE, "@HM__GrenadeAddToPlayer_Post", true);
	RegisterHam(Ham_Item_Deploy, WEAPON_REFERENCE, "@HM__GrenadeDeploy_Post", true);
	RegisterHam(Ham_Item_Holster, WEAPON_REFERENCE, "@HM__GrenadeHolster_Post", true);
	RegisterHam(Ham_RemovePlayerItem, WEAPON_REFERENCE, "@HM__GrenadeRemove_Pre", false);

	for(new i, iSize = sizeof g_szWeaponReferences; i < iSize; i++)
	{
		DisableHamForward( (g_hWeaponPrimaryAttack[i] = RegisterHam(Ham_Weapon_PrimaryAttack, g_szWeaponReferences[i], "@HM_WeaponsAttack_Post", true)) );
		DisableHamForward( (g_hWeaponSecondaryAttack[i] = RegisterHam(Ham_Weapon_SecondaryAttack, g_szWeaponReferences[i], "@HM_WeaponsAttack_Post", true)) );
	}

	g_iItemID = zp_register_extra_item(ITEM_NAME, ITEM_COST, ITEM_TEAM);

	arrayset(g_iEnt_Effect, NULLENT, sizeof g_iEnt_Effect);
}

public client_disconnected(pPlayer) Thunder_EffectDisable(pPlayer);
public zp_user_infected_pre(pPlayer) Thunder_EffectDisable(pPlayer);
@RG__PlayerKilled_Pre(pVictim) Thunder_EffectDisable(pVictim);

public zp_extra_item_selected(iPlayer, iItem) 
{
	if(iItem != g_iItemID) 
		return PLUGIN_CONTINUE;

	return GiveItem_Extra(iPlayer) ? PLUGIN_CONTINUE : ZP_PLUGIN_HANDLED;
}

public zp_round_ended(winteam)
{
	g_bRoundEnd = true;
	
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(!is_user_alive(iPlayer)) continue;
		
		Thunder_EffectDisable(iPlayer);
	}
}

@ClCmd__HookWeapon(pPlayer)
{
	engclient_cmd(pPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

@RG__RestartRound_Pre()
{
	g_bRoundEnd = false;
	
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if(!is_user_alive(iPlayer) || !zp_get_user_zombie(iPlayer)) continue;

		rg_remove_item(iPlayer, WEAPON_REFERENCE, true);
	}

}

@RH__StartSound_Pre(const iRecipients, const pEntity, const iChanel, const szSample[], const iVolume, Float:flAttenuation, const flFlags, const iPitch)
{
	if(is_nullent(pEntity) || get_entvar(pEntity, var_flTimeStepSound) != GRENADE_SPECIAL_CODE)
		return HC_CONTINUE;

	if(!equal(szSample, "weapons/he_bounce-1", 15))
		return HC_CONTINUE;

	SetHookChainArg(4, ATYPE_STRING, GRENADE_HIT_SOUNDS[random(sizeof(GRENADE_HIT_SOUNDS))]);
	return HC_CONTINUE;
}

@RG__Throw_HeGrenade_Post(const pPlayer, Float:vecStart[3], Float:vecVelocity[3], Float:time, const usEvent)
{
	if(!zp_get_user_zombie(pPlayer))
		return;

	new pAciveItem = get_member(pPlayer, m_pActiveItem);

	if(is_nullent(pAciveItem) || get_entvar(pAciveItem, var_impulse) != WEAPON_IMPULSE)
		return;

	new pEnt = GetHookChainReturn(ATYPE_INTEGER);

 	if(is_nullent(pEnt))
    	return;

	engfunc(EngFunc_SetModel, pEnt, GRENADE_MODEL_WORLD);

	set_entvar(pEnt, var_owner, pPlayer);
	set_entvar(pEnt, var_impulse, GRENADE_SPECIAL_CODE);
	set_entvar(pEnt, var_flTimeStepSound, GRENADE_SPECIAL_CODE);
	set_entvar(pEnt, var_body, GRENADE_MODEL_BODY);
	set_entvar(pEnt, var_avelocity, Float:{100.0, 100.0, 100.0});
	MSG_BeamFollow(pEnt, g_iModelIndex_Trail, 1.0, 3, GRENADE_TRAIL_COLORALPHA);
	UTIL_SetRendering(pEnt, kRenderFxGlowShell, GRENADE_RENDER_COLOR, kRenderNormal, 0.0);

	//2) После действия гранаты, у людей нет отдачи (именно эффект тряски экрана при стрельбе) на оружии до момента нового раунда или перезаражения. С этим я не знаю что делать
	// Забыл перетащить функцию Think

	/* БЕСПОЛЕЗНАЯ ФИГНЯ */
	/* SetThink(pEnt, "@RG_Think_ThunderGrenade"); */
}


@RG_Think_ThunderGrenade(pEnt)
{
	new Float:flGameTime = get_gametime();

	new iColorAlpha[4]; for(new i; i < 3; i++) iColorAlpha[i] = random(256);
	iColorAlpha[3] = 120;

	new pPlayer = get_entvar(pEnt, var_owner);

	MSG_ScreenFade(pPlayer, GRENADE_EFFECT_THINK, GRENADE_EFFECT_THINK, 0, iColorAlpha);

	new Float:vecPunch[3]; for(new i; i < 2; i++) vecPunch[i] = GRENADE_EFFECT_PUNCH; 

	set_entvar(pEnt, var_punchangle, vecPunch)
	set_entvar(pPlayer, var_punchangle, vecPunch);

	if(Float:get_entvar(pEnt, var_ltime) <= flGameTime)
	{	
		Thunder_EffectDisable(pPlayer);
		return;
	}

	set_entvar(pEnt, var_nextthink, flGameTime + GRENADE_EFFECT_THINK);
} 

@RG__Explode_HeGrenade_Pre(pEnt, tHandle, iDamageBits)
{
	if(get_entvar(pEnt, var_flTimeStepSound) != GRENADE_SPECIAL_CODE)
		return HC_CONTINUE;

	Thunder_Explode(pEnt);
	rg_remove_ent(pEnt);

	return HC_BREAK;
}

@HM__GrenadeAddToPlayer_Post(pItem, pPlayer)
{
	if(get_entvar(pItem, var_impulse) != WEAPON_IMPULSE)
		return;

	if(get_entvar(pItem, var_owner) <= 0)
		Item_Initilize_Vars(pItem);

	MSG_Item_WeaponList(pPlayer, pItem);
}

stock Item_Initilize_Vars(pItem)
{
	rg_set_iteminfo(pItem, ItemInfo_iMaxAmmo1, WEAPON_CLIP_MAX);
	rg_set_iteminfo(pItem, ItemInfo_pszName, WEAPON_WLIST);
}

@HM__GrenadeDeploy_Post(pItem)
{
	if(get_entvar(pItem, var_impulse) != WEAPON_IMPULSE)
		return;

	new pPlayer = get_member(pItem, m_pPlayer);
	new pEnt = api_wpn_player_model_get(pPlayer);

	UTIL_SetRendering(pEnt, kRenderFxGlowShell, GRENADE_RENDER_COLOR, kRenderNormal, 0.0);

	MSG_StatusIcon(pPlayer, WEAPON_ICON_NAME, 1, WEAPON_ICON_COLOR);
}

@HM__GrenadeHolster_Post(pItem)
{
	if(get_entvar(pItem, var_impulse) != WEAPON_IMPULSE)
		return;

	WeaponDisableEffects(get_member(pItem, m_pPlayer));
}

@HM__GrenadeRemove_Pre(pPlayer, pItem)
{
	if(get_entvar(pItem, var_impulse) != WEAPON_IMPULSE)
		return;

	WeaponDisableEffects(pPlayer);
}

stock WeaponDisableEffects(pPlayer)
{
	new pEnt = api_wpn_player_model_get(pPlayer);

	UTIL_SetRendering(pEnt);

	MSG_StatusIcon(pPlayer, WEAPON_ICON_NAME);
}

@HM_WeaponsAttack_Post(pItem)
{
	new pPlayer = get_member(pItem, m_pPlayer);
	new pEnt = g_iEnt_Effect[pPlayer];

	if(is_nullent(pEnt)) return;

	new Float:vecPunch[3]; get_entvar(pEnt, var_punchangle, vecPunch)
	set_entvar(pPlayer, var_punchangle, vecPunch);
}

stock Thunder_Explode(pEnt)
{
	rh_emit_sound2(pEnt, 0, CHAN_WEAPON, GRENADE_EXPLODE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_HIGH);

	new Float:vecOrigin[3]; get_entvar(pEnt, var_origin, vecOrigin);

	MSG_LavaSplash(vecOrigin)

	if(g_bRoundEnd) return;

	new Float:vecPlayer[3];

	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		//1) Оружие выпадает даже у героя, но это я еще знаю как исправить - Проверь
		if(!is_user_alive(iPlayer) || zp_get_user_zombie(iPlayer) || zp_get_user_hero(iPlayer))
			continue;

		get_entvar(iPlayer, var_origin, vecPlayer);

		if(get_distance_f(vecOrigin, vecPlayer) > GRENADE_EFFECT_RADIUS)
			continue;

		Thunder_EffectStart(iPlayer);
	}
}


stock bool:GiveItem_Extra(pPlayer)
{
	if(!is_user_alive(pPlayer))
		return false;

	new pItem = rg_give_custom_item(pPlayer, WEAPON_REFERENCE, GT_APPEND, WEAPON_IMPULSE);

	if(is_nullent(pItem))
		return false;

	return true;
}

stock Thunder_EffectStart(pPlayer)
{
	new pEnt = g_iEnt_Effect[pPlayer];

	if(is_nullent(pEnt) && is_nullent( (pEnt = rg_create_entity("info_target")) ))
		return false;

	g_iEnt_Effect[pPlayer] = pEnt;

	if(!IsSetBit(g_iUserBitEffect, pPlayer))
	{
		if(!g_iUserBitEffect) SwitchToggle(true);
		SetBit(g_iUserBitEffect, pPlayer);
	}
	Thunder_Kill(pPlayer)
    SetThink(pEnt, "@RG_Think_ThunderGrenade");
	return true;
}

stock Thunder_Kill(iVictim)
{
	new iItem = get_member(iVictim, m_pActiveItem);
	new iSlot = rg_get_iteminfo(iItem, ItemInfo_iSlot);
	
	if(!is_nullent(iItem))
	{
		if(0 <= iSlot <= 1)
		rg_drop_items_by_slot(iVictim, InventorySlotType:++iSlot);
	}

	new Float:vecPunch[3]; for(new i; i < 2; i++) vecPunch[i] = GRENADE_EFFECT_PUNCH; 
	set_entvar(iVictim, var_punchangle, vecPunch);
	Thunder_EffectDisable(iVictim)
}

stock Thunder_EffectDisable(iVictim)
{
	if(!IsSetBit(g_iUserBitEffect, iVictim))
		return;

	if(!is_nullent(g_iEnt_Effect[iVictim])) 
		rg_remove_ent(g_iEnt_Effect[iVictim]);

	g_iEnt_Effect[iVictim] = NULLENT;

	ClearBit(g_iUserBitEffect, iVictim);

	if(!g_iUserBitEffect) SwitchToggle(false);
}

stock SwitchToggle(bool:bValue)
{
	if(bValue)
	{
		for(new i, iSize = sizeof g_szWeaponReferences; i < iSize; i++)
		{
			EnableHamForward(g_hWeaponPrimaryAttack[i]);
			EnableHamForward(g_hWeaponSecondaryAttack[i]);
		}
	}
	else
	{
		for(new i, iSize = sizeof g_szWeaponReferences; i < iSize; i++)
		{
			DisableHamForward(g_hWeaponPrimaryAttack[i]);
			DisableHamForward(g_hWeaponSecondaryAttack[i]);
		}
	}
}