#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <reapi>
#include <smart_effects>
#include <smart_messages>
#include <api_weapon_player_model>
#include <zc_addon_zclasses>
#include <zc_addon_zchoose>

/* ~ [ Grenade Settings ] ~ */
#define WEAPON_REFERENCE			"weapon_smokegrenade"

#define WEAPON_MODEL_W				"models/zp_br_cso/grenade/w_jumpbomb_b2.mdl"
#define WEAPON_MODEL_W_DEF			"models/w_smokegrenade.mdl"

new const GRENADE_EXPLODE[] = 
	"zp_br_cso/zombie/zombie_grenade_explode2.wav";

new const GRENADE_HITS[][] =
{
	"zp_br_cso/zombie/zombie_grenade_bounce_1.wav",
	"zp_br_cso/zombie/zombie_grenade_bounce_2.wav"
}

#define WEAPON_SPECIAL_CODE			1212191626
#define WEAPON_SLOT					4
#define WEAPON_BODY					0

#define GRENADE_CSW					CSW_SMOKEGRENADE
#define GRENADE_IMPULSE				6999
#define GRENADE_AMMO_MAX			2
#define GRENADE_RADIUS_KNOCK		230.0
#define GRENADE_RADIUS_KNOCK_HUMAN	190.0
//#define GRENADE_RADIUS_DMG			122.0
//#define GRENADE_DMG 				random_float(20.0, 25.0)
#define GRENADE_KNOCKBACK			430
#define GRENADE_KNOCKBACK_HUMAN		330
#define GRENADE_SPRITE_EXP			"sprites/zp_br_cso/grenade/ef_zombibomb.spr"
#define GRENADE_AMMO_TYPE			"smokegrenade"
#define GRENADE_DELAY_HUMAN			20.0
#define GRENADE_DELAY_HITS			2
#define GRENADE_TRAIL_MODEL			"sprites/laserbeam.spr"
#define GRENADE_TRAIL_COLOR			{250, 215, 0, 200}
#define GRENADE_RENDER_COLOR		Float:{250.0, 215.0, 0.0}

#define GRENADE_ICON_NAME "dmg_gas"
#define GRENADE_ICON_COLOR {250, 215, 0}

#define GRENADE_FADE_COLORALPHA {250, 215, 0, 90}
#define GRENADE_FADEIN_TIME 0.2
#define GRENADE_EFFECT_DURATION 2.0
#define GRENADE_EFFECT_SPEED 215.0



//Перечисление попаданий
enum _:TypeHit
{
	//Нет попаданий
	e_JumpNull = 0,
	//Попадание по зомби
	e_JumpZombie,
	//Попадание по людям
	e_JumpHuman

}

native zp_is_user_frozen(id);
//native zp_is_user_trapped(id);

/* ~ [ Params ] ~ */
new g_iszAllocString_Entity,

	g_iszModelIndex_Explosion,

	g_iMaxPlayers,

	bool: g_bRoundEnd,
	
	g_iItemID,

	Float:g_flTimeReload[33],

	g_iModelIndex_Beam;

	//g_iEnt_Effect[33];

new Array:g_aszClass_HandsJump;

public plugin_init() {

	register_plugin("[CSO Like] Grenade: Zombie Grenade", "1.0", "inf / Batcoh: Code base");
	
	g_iMaxPlayers = get_maxplayers();

	g_iItemID = zp_register_extra_item("Zombie Grenade", 25, ZP_TEAM_ZOMBIE);

	register_event("HLTV", "EventHLTV", "a", "1=0", "2=0")

	//register_forward(FM_SetModel, 			"FM_Hook_SetModel", false);
	RegisterHookChain(RG_ThrowSmokeGrenade, "@RG_Throw_SmokeGrenade_Post", true);
	RegisterHookChain(RH_SV_StartSound, "@RH_StartSound_Pre", false);

	RegisterHam(Ham_Think,					"grenade",			"CGrenade__Think", false);
	//RegisterHam(Ham_Touch,					"grenade",			"CGrenade__Touch", true);

	RegisterHam(Ham_Item_Deploy, WEAPON_REFERENCE, "HM__Grenade_Deploy_Post", true);
	RegisterHam(Ham_Item_Holster, WEAPON_REFERENCE, "HM__Grenade_Holster_Post", true);
	RegisterHam(Ham_RemovePlayerItem, WEAPON_REFERENCE, "@HM__GrenadeRemove_Pre", false);
	//RegisterHam(Ham_Item_PreFrame, "player", "HM__PlayerPreFrame_Post", true);

	//RegisterHookChain(RG_CBasePlayer_Killed, "@RG_PlayerKilled_Pre", false);

	//arrayset(g_iEnt_Effect, NULLENT, sizeof g_iEnt_Effect);
}

public plugin_precache() {

	// Precache models
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_W);
	//engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_W_DEF);
	engfunc(EngFunc_PrecacheModel, GRENADE_SPRITE_EXP);
	
	// Precache sounds
	engfunc(EngFunc_PrecacheSound, GRENADE_EXPLODE);
	for(new i; i < sizeof GRENADE_HITS; i++) engfunc(EngFunc_PrecacheSound, GRENADE_HITS[i]);

	// Other
	g_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);

	g_iszModelIndex_Explosion = engfunc(EngFunc_PrecacheModel, GRENADE_SPRITE_EXP);

	g_iModelIndex_Beam = engfunc(EngFunc_PrecacheModel, GRENADE_TRAIL_MODEL)
}

public plugin_natives()
{
	register_native("zp_get_extra_jump", "zp_get_extra_jump", 1);
	register_native("zp_get_jump_left_sec", "zp_get_jump_left_sec", 1);

	g_aszClass_HandsJump = ArrayCreate(64);
}

/*
public zp_user_infected_pre(id, infector, nemesis) RemoveEffect(id);
public client_disconnected(id, bool:drop, message[], maxlen) RemoveEffect(id);
@RG_PlayerKilled_Pre(iVictim) RemoveEffect(iVictim);
*/

public zc_read_zclass(const JSON:jHandle)
{
	new szJumpHands[64]; json_object_get_string(jHandle, "jump model", szJumpHands, charsmax(szJumpHands));
	
	if(szJumpHands[0] != 0)
	{
		if(file_exists(szJumpHands))
			precache_model(szJumpHands)
		else
			szJumpHands[0] = 0;
	}
	
	ArrayPushString(g_aszClass_HandsJump, szJumpHands);
}

public zp_get_extra_jump()
	return g_iItemID;

public zp_get_jump_left_sec(id)
{
	new Float:flGameTime = get_gametime();

	if(g_flTimeReload[id] > flGameTime)
		return floatround(g_flTimeReload[id] - flGameTime, floatround_ceil);

	return 0;
}

public zp_round_started() g_bRoundEnd = false;

public zp_round_ended() g_bRoundEnd = true;

public zp_user_infected_post(iPlayer, iInfector, iNem) 
{
	if(!iNem) 
	{
		Command_GiveWeapon(iPlayer);
		engclient_cmd(iPlayer, "weapon_knife");
	}
}


public zp_extra_item_selected(iPlayer, iItem) 
{
	if(iItem == g_iItemID) 
	{
		if(g_bRoundEnd) 
			return ZP_PLUGIN_HANDLED;

		Command_GiveWeapon(iPlayer);
	}

	return PLUGIN_CONTINUE;
}

public Command_GiveWeapon(iPlayer) 
{
	if(user_has_weapon(iPlayer, GRENADE_CSW)) 
	{
		ExecuteHamB(Ham_GiveAmmo, iPlayer, 1, GRENADE_AMMO_TYPE, GRENADE_AMMO_MAX);
		emit_sound(iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
	else 
	{
		static iEntity; iEntity = engfunc(EngFunc_CreateNamedEntity, g_iszAllocString_Entity);

		if(!pev_valid(iEntity)) return PLUGIN_CONTINUE;
		
		set_pev(iEntity, pev_impulse, GRENADE_IMPULSE);

		ExecuteHam(Ham_Spawn, iEntity);

		if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iEntity)) 
		{
			set_pev(iEntity, pev_flags, FL_KILLME);

			return PLUGIN_CONTINUE;
		}

		ExecuteHamB(Ham_Item_AttachToPlayer, iEntity, iPlayer);
		
		emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}

	return PLUGIN_HANDLED;
}

public EventHLTV()
{
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_alive(iPlayer)) continue;
	
		if(zp_get_user_zombie(iPlayer)) rg_remove_item(iPlayer, "weapon_smokegrenade", true);
		
		//RemoveEffect(iPlayer);
	}
}

/*public FM_Hook_SetModel(iEntity, const szModel[]) {
	if(!pev_valid(iEntity)) return FMRES_IGNORED;

	if(!equal(szModel, WEAPON_MODEL_W_DEF)) return FMRES_IGNORED;

	new iOwner = pev(iEntity, pev_owner);

	if(g_iUserHasZombieBomb[iOwner]) {

		engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_W);

		set_pev(iEntity, pev_body, WEAPON_BODY);
		set_pev(iEntity, pev_flTimeStepSound, WEAPON_SPECIAL_CODE);

		g_iUserHasZombieBomb[iOwner] -= 1;

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}*/

@RG_Throw_SmokeGrenade_Post(const id, Float:vecStart[3], Float:vecVelocity[3], Float:time, const usEvent)
{
	if(!zp_get_user_zombie(id))
		return;

	new pAciveItem = get_member(id, m_pActiveItem);

	if(is_nullent(pAciveItem) || get_member(pAciveItem, m_iId) != CSW_SMOKEGRENADE)
		return;

	new pEntity = GetHookChainReturn(ATYPE_INTEGER);
 	if(is_nullent(pEntity))
    	return;

	engfunc(EngFunc_SetModel, pEntity, WEAPON_MODEL_W);

	set_entvar(pEntity, var_owner, id);
	set_entvar(pEntity, var_impulse, WEAPON_SPECIAL_CODE);
	set_entvar(pEntity, var_flTimeStepSound, WEAPON_SPECIAL_CODE);
	set_entvar(pEntity, var_body, WEAPON_BODY);
	set_entvar(pEntity, var_avelocity, Float:{100.0, 100.0, 100.0});
	MSG_BeamFollow(pEntity, g_iModelIndex_Beam, 1.0, 3, GRENADE_TRAIL_COLOR);
	UTIL_SetRendering(pEntity, kRenderFxGlowShell, GRENADE_RENDER_COLOR, kRenderNormal, 0.0);
}

@RH_StartSound_Pre(const iRecipients, const pEntity, const iChanel, const szSample[], const iVolume, Float:flAttenuation, const flFlags, const iPitch)
{
	if(is_nullent(pEntity) || get_entvar(pEntity, var_flTimeStepSound) != WEAPON_SPECIAL_CODE)
		return HC_CONTINUE;

	if(!equal(szSample, "weapons/grenade_hit", 15))
		return HC_CONTINUE;

	SetHookChainArg(4, ATYPE_STRING, GRENADE_HITS[random(sizeof(GRENADE_HITS))]);
	return HC_CONTINUE;
}

public CGrenade__Think(iEntity) {
	if(pev_valid(iEntity) != 2) return HAM_IGNORED;

	if(pev(iEntity, pev_flTimeStepSound) == WEAPON_SPECIAL_CODE) {
		static Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		
		if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_WATER) {
			set_pev(iEntity, pev_flags, FL_KILLME);

			return HAM_IGNORED;
		}

		static Float: flDmgTime; pev(iEntity, pev_dmgtime, flDmgTime);
		static Float: flGameTime; flGameTime = get_gametime();

		if(flDmgTime <= flGameTime) 
		{
			static Float: flDistance, Float: vecVicOrigin[3], Float: vecVelocity[3];


			/*new iOwner = pev(iEntity, pev_owner);


			for(new iVictim = 1; iVictim <= MaxClients; iVictim++)
			{
				pev(iVictim, pev_origin, vecVicOrigin);
				flDistance = get_distance_f(vecOrigin, vecVicOrigin);
				
				if(!is_user_alive(iVictim) || flDistance > GRENADE_RADIUS_KNOCK || zp_is_user_frozen(iVictim)) continue;

				iVicZombie = zp_get_user_zombie(iVictim)

				if(!iVicZombie) IsHuman = true;

				if(flDistance <= GRENADE_RADIUS_DMG && !iVicZombie)
				{
					zp_takedamage(iVictim, iEntity, iOwner, GRENADE_DMG, DMG_NEVERGIB);	
				}
				else
				{
					UTIL_GetSpeedVector(vecOrigin, vecVicOrigin, GRENADE_KNOCKBACK + (1.0 - (flDistance / GRENADE_RADIUS_KNOCK)), vecVelocity);
					set_pev(iVictim, pev_velocity, vecVelocity);
				}
			}*/

			new TypeHit:iTypeHit;

			for(new iVictim = 1; iVictim <= MaxClients; iVictim++)
			{
				pev(iVictim, pev_origin, vecVicOrigin);
				flDistance = get_distance_f(vecOrigin, vecVicOrigin);
				
				if(!is_user_alive(iVictim) || zp_is_user_frozen(iVictim) /*|| zp_is_user_trapped(iVictim)*/) continue;

				if(zp_get_user_zombie(iVictim))
				{
					if(flDistance > GRENADE_RADIUS_KNOCK) 
						continue;

					UTIL_GetSpeedVector(vecOrigin, vecVicOrigin, GRENADE_KNOCKBACK + (1.0 - (flDistance / GRENADE_RADIUS_KNOCK)), vecVelocity);
					
					if(!iTypeHit) iTypeHit = TypeHit:e_JumpZombie;
				}
				else
				{
					if(flDistance > GRENADE_RADIUS_KNOCK_HUMAN) 
						continue;
					
					UTIL_GetSpeedVector(vecOrigin, vecVicOrigin, GRENADE_KNOCKBACK_HUMAN + (1.0 - (flDistance / GRENADE_RADIUS_KNOCK_HUMAN)), vecVelocity);
					//CreateEffect(iVictim);

					iTypeHit = TypeHit:e_JumpHuman;
				}

				MSG_BeamFollow(iVictim, g_iModelIndex_Beam, 0.5, 3, GRENADE_TRAIL_COLOR);
				MSG_ScreenShake(iVictim, 5.0, 3.0, 0.5);
				set_pev(iVictim, pev_velocity, vecVelocity);
			}

			/**
			 * Счетчик, который блокирует покупку после 2х попаданий
			 */
			if(iTypeHit == TypeHit:e_JumpHuman)
			{
				static iTimesHit[33], Float:flFirstHit[33];

				new id = get_entvar(iEntity, var_owner);
				
				if(flFirstHit[id] <= flGameTime)
				{ 
					iTimesHit[id] = 0;
					flFirstHit[id] = flGameTime + GRENADE_DELAY_HUMAN
				}

				if(++iTimesHit[id] >= GRENADE_DELAY_HITS)
					g_flTimeReload[id] = flFirstHit[id];
			
				//client_print(id, print_chat, "iTimesHit[id] : %d | flFirstHit[id] : %f | g_flTimeReload[id] : %f", iTimesHit[id], flFirstHit[id], g_flTimeReload[id])
			}

			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
			write_byte(TE_SPRITE);
			engfunc(EngFunc_WriteCoord, vecOrigin[0]);
			engfunc(EngFunc_WriteCoord, vecOrigin[1]);
			engfunc(EngFunc_WriteCoord, vecOrigin[2] + 50.0);
			write_short(g_iszModelIndex_Explosion);
			write_byte(25); // Scale
			write_byte(200); // Alpha
			message_end();

			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
			write_byte(TE_PARTICLEBURST); // TE id
			engfunc(EngFunc_WriteCoord, vecOrigin[0]); // x
			engfunc(EngFunc_WriteCoord, vecOrigin[1]); // y
			engfunc(EngFunc_WriteCoord, vecOrigin[2] + 5.0); // z
			write_short(200); // Radius
			write_byte(108); // Color
			write_byte(16); // Life
			message_end();

			emit_sound(iEntity, CHAN_WEAPON, GRENADE_EXPLODE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			set_pev(iEntity, pev_flags, FL_KILLME);
			set_pev(iEntity, pev_nextthink, flGameTime);

			return HAM_IGNORED;
		}

		/*if(!(pev(iEntity, pev_flags) & FL_ONGROUND) && pev(iEntity, pev_sequence) != 3)
		{
			UTIL_SendEntityAnim(iEntity, 3);
		}*/


		return HAM_IGNORED;
	}

	return HAM_IGNORED;
}

public HM__Grenade_Deploy_Post(pItem)
{
	if(get_entvar(pItem, var_impulse) != GRENADE_IMPULSE)
		return;

	new pPlayer = get_member(pItem, m_pPlayer);
	
	new szJumpHands[64]; ArrayGetString(g_aszClass_HandsJump, zc_get_user_zclass(pPlayer), szJumpHands, charsmax(szJumpHands));
	if(szJumpHands[0] != 0) set_entvar(pPlayer, var_viewmodel, szJumpHands);
	
	new pEnt = api_wpn_player_model_get(pPlayer);
	
	if(!is_nullent(pEnt))
		UTIL_SetRendering(pEnt, kRenderFxGlowShell, GRENADE_RENDER_COLOR, kRenderNormal, 0.0);

	MSG_StatusIcon(pPlayer, GRENADE_ICON_NAME, 1, GRENADE_ICON_COLOR);
}

public HM__Grenade_Holster_Post(pItem)
{
	if(get_entvar(pItem, var_impulse) != GRENADE_IMPULSE)
		return;

	WeaponDisableEffects(get_member(pItem, m_pPlayer));
}

@HM__GrenadeRemove_Pre(pPlayer, pItem)
{
	if(get_entvar(pItem, var_impulse) != GRENADE_IMPULSE)
		return;

	WeaponDisableEffects(pPlayer);
}

stock WeaponDisableEffects(pPlayer)
{
	new pEnt = api_wpn_player_model_get(pPlayer);

	if(!is_nullent(pEnt))
		UTIL_SetRendering(pEnt);

	MSG_StatusIcon(pPlayer, GRENADE_ICON_NAME);
}

/*public HM__PlayerPreFrame_Post(pPlayer)
	if(!is_nullent(g_iEnt_Effect[pPlayer])) set_entvar(pPlayer, var_maxspeed, GRENADE_EFFECT_SPEED);
*/
stock zp_takedamage(iVictim, iInflictor, iOwner, Float:flDamage, iDmg)
{
	if(g_bRoundEnd) return;

	static Float:fHealth; fHealth = Float:get_entvar(iVictim, var_health);

	if(fHealth - flDamage > 0.0)
		ExecuteHam(Ham_TakeDamage, iVictim, iInflictor, iOwner, GRENADE_DMG, iDmg);
	else if(!zp_infect_user(iVictim, iOwner, .rewards = 1))
		ExecuteHamB(Ham_TakeDamage, iVictim, iInflictor, iOwner, GRENADE_DMG, iDmg);

}

/*public CGrenade__Touch(iEntity, iTouch) 
{
	if(pev_valid(iEntity) != 2) return HAM_IGNORED;

	if(pev(iEntity, pev_flTimeStepSound) == WEAPON_SPECIAL_CODE) 
	{
		if(pev(iEntity, pev_sequence) != 0) 
		{
			UTIL_SendEntityAnim(iEntity, 0);
			emit_sound(iEntity, CHAN_WEAPON, GRENADE_EXPLODE[random_num(0, 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	return HAM_IGNORED;
}*/

stock UTIL_GetSpeedVector(const Float: vecOrigin1[3], const Float: vecOrigin2[3], Float: flSpeed, Float: vecVelocity[3]) {
	vecVelocity[0] = vecOrigin2[0] - vecOrigin1[0];
	vecVelocity[1] = vecOrigin2[1] - vecOrigin1[1];
	vecVelocity[2] = vecOrigin2[2] - vecOrigin1[2];

	new Float: flNum = floatsqroot(flSpeed * flSpeed / (vecVelocity[0] * vecVelocity[0] + vecVelocity[1] * vecVelocity[1] + vecVelocity[2] * vecVelocity[2]));

	vecVelocity[0] *= flNum;
	vecVelocity[1] *= flNum;
	vecVelocity[2] *= flNum;
}
stock UTIL_SendEntityAnim(iEntity, iAnim) 
{
	static Float: flGameTime; flGameTime = get_gametime();

	set_pev(iEntity, pev_frame, 0.0);
	set_pev(iEntity, pev_sequence, iAnim);
	set_pev(iEntity, pev_framerate, 9.0);
	set_pev(iEntity, pev_animtime, flGameTime);
}

/*stock CreateEffect(const id)
{
	if(Float:get_entvar(id, var_maxspeed) <= 1.0)
		return

	if(is_nullent(g_iEnt_Effect[id])) 
		g_iEnt_Effect[id] = CreateEntityEffect();

	SetEntityEffects(id, g_iEnt_Effect[id]);
}

stock CreateEntityEffect()
{
	new iEnt = rg_create_entity("info_target");

	if(is_nullent(iEnt)) return NULLENT;

	return iEnt;
}

enum _:e_iEffectState
{
	e_iEffectFadeIn,
	e_iEffectFadeOut 
}

stock SetEntityEffects(const id, const iEnt)
{
	MSG_ScreenFade(id, GRENADE_FADEIN_TIME, _, SF_FADE_IN, GRENADE_FADE_COLORALPHA);

	ExecuteHamB(Ham_Item_PreFrame, id);

	set_entvar(iEnt, var_iuser1, e_iEffectFadeIn);
	
	set_entvar(iEnt, var_owner, id);
	set_entvar(iEnt, var_nextthink, get_gametime() + GRENADE_FADEIN_TIME);

	SetThink(iEnt, "@Think_Effect");
}

@Think_Effect(iEnt)
{
	new pPlayer = get_entvar(iEnt, var_owner)

	switch(get_entvar(iEnt, var_iuser1))
	{
		case e_iEffectFadeIn:
		{
			set_entvar(iEnt, var_iuser1, e_iEffectFadeOut);

			new Float:flDuration = GRENADE_EFFECT_DURATION - GRENADE_FADEIN_TIME;

			MSG_ScreenFade(pPlayer, flDuration, _, 0, GRENADE_FADE_COLORALPHA);
			
			set_entvar(iEnt, var_nextthink, get_gametime() + flDuration);
		}
		case e_iEffectFadeOut: RemoveEffect(pPlayer)
	}
}

stock RemoveEffect(pPlayer)
{
	if(g_iEnt_Effect[pPlayer] == NULLENT)
		return;

	if(!is_nullent(g_iEnt_Effect[pPlayer])) rg_remove_ent(g_iEnt_Effect[pPlayer]);
	
	g_iEnt_Effect[pPlayer] = NULLENT;
	ExecuteHamB(Ham_Item_PreFrame, pPlayer);
}*/