#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <reapi>
#include <xs>

#include <zombieplague>
#include <api_flame>

new const g_szSndSkillStart[] = "zp_br_cso/zombie/male/nemesis_skill_start.wav"; // Звук скилла
new const g_szSndSkillHit[] = "zp_br_cso/zombie/male/nemesis_skill_hit.wav"; // Звук попадания
new const g_szAnimPlayer[] = "zbs_skill_idle"; // Анимация модели игрока

new const g_szSprFollow[] = "sprites/zbeam4.spr"; // Спрайт линии

new const g_szSprExplode[] = "sprites/zp_br_cso/zombie/deimosexp.spr" // Срайт взрыва жала
#define SPRITE_FRAMES 10.0 // Количество кадров спрайта
#define SPRITE_FREAMERATE 15.0 // Скорость проигрывания спрайта

new const g_szWpnlistModel[] = "sprites/zp_br_cso/zombie/zmtimer2.txt" // Weaponlist таймер 
new const g_szWpnlistName[] = "zp_br_cso/zombie/zmtimer2" // Название weaponlist

#define DEIMOS_TIME 7.0 //Перезагрузка способности у deimos
#define DEIMOS_SKILLSPEED 1400.0 //Скорость вылета жала
#define DEIMOS_SKILLDMG 100.0 //Урон от жала

#define ANIM_SKILL 8
#define ANIM_SKILL_TIME 46.0/30.0
#define ANIM_SKILL_ETIME 15.0/30.0

#define SLOT_KNIFE 3

#define VAR_ENT 	var_iuser2
#define VAR_STARTPAIN 	var_ltime
#define VAR_RELOAD	var_dmgtime
#define VAR_WAIT	var_fuser1

#define SPRITE_NEXTTHINK (1.0/SPRITE_FREAMERATE)

#if !defined(zp_get_user_hero)
native zp_get_user_hero(id);
#endif

#define MsgID_AmmoX 99
#define MsgID_CurWeapon 66
#define MsgID_WeaponList 78

new g_pSprZbeam4;

enum
{
	ABILITY_NO = 0,
	ABILITY_READY,
	ABILITY_SKILL,
	ABILITY_RESTART
}

public plugin_precache()
{
	precache_sound(g_szSndSkillStart);
	precache_sound(g_szSndSkillHit);

	g_pSprZbeam4 = precache_model(g_szSprFollow);
	precache_model(g_szSprExplode);

	precache_generic(g_szWpnlistModel);
	register_clcmd(g_szWpnlistName, "ClCmd_WeaponKnife");
}

public plugin_init()
{
	register_plugin("[ZPE] Nemesis: Deimos", "1.2", "Docaner");	

	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Pre", false);

	register_clcmd("drop", "ClCmd_Skill");

	RegisterHam(Ham_Item_PreFrame, "weapon_knife", "HM_Knife_PreFrame_Post", true);
}

public client_disconnected(id)
	clear_user_data(id);

public zp_user_humanized_pre(id)
	clear_user_data(id);

public zp_user_infected_pre(id)
	clear_user_data(id);

public zp_user_infected_post(id, infector, nemesis)
{
	if(nemesis)
	{
		new iItem = get_member(id, m_rgpPlayerItems, 3);
		if(!is_nullent(iItem))
		{
			set_member(iItem, m_Weapon_iWeaponState, ABILITY_READY);
			set_entvar(iItem, VAR_ENT, NULLENT);

			client_print_color(id, id, "^4[ZP] ^1Вы стали ^3боссом^1!");
			client_print_color(id, id, "^4[ZP] ^1Способность: жало на ^4[G] | Отсчёт: ^4%d ^1с", floatround(DEIMOS_TIME));
		}
	}
}

public zp_flame_params_change_post(const pEntBase, const pVictim, const pAttacker, const Float:flSeconds)
{
	if(!zp_get_user_nemesis(pVictim))
		return;

	set_entvar(pEntBase, var_ltime, get_gametime() + flSeconds / 15.0);
}

public zp_round_ended()
{
	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		clear_user_data(iPlayer);
}

public CBasePlayer_Killed_Pre(iVictim)
	clear_user_data(iVictim);

public ClCmd_WeaponKnife(id)
{
	engclient_cmd(id, "weapon_knife");
	return PLUGIN_HANDLED;
}

public ClCmd_Skill(id)
{
	if(!is_user_alive(id) || !zp_get_user_nemesis(id))
		return PLUGIN_CONTINUE;

	new iItem = get_member(id, m_pActiveItem);

	if(is_nullent(iItem) || get_member(iItem, m_iId) != CSW_KNIFE)
		return PLUGIN_CONTINUE;

	new iState = get_member(iItem, m_Weapon_iWeaponState);

	switch(iState)
	{
		case ABILITY_READY:
		{
			set_member(iItem, m_Weapon_iWeaponState, ABILITY_SKILL);

			set_member(iItem, m_Weapon_flNextPrimaryAttack, ANIM_SKILL_TIME);
			set_member(iItem, m_Weapon_flNextSecondaryAttack, ANIM_SKILL_TIME);
			set_member(iItem, m_Weapon_flTimeWeaponIdle, ANIM_SKILL_TIME);

			UTIL_WeaponAnimation(id, ANIM_SKILL);
			UTIL_PlayerAnimation(id, g_szAnimPlayer);
			rh_emit_sound2(id, 0, CHAN_WEAPON, g_szSndSkillStart);

			set_entvar(iItem, VAR_STARTPAIN, get_gametime() + ANIM_SKILL_ETIME);
		}
		case ABILITY_RESTART:
		{
			client_print(id, print_center, "Способность перезаряжается!");
		}
	}

	return PLUGIN_HANDLED;
}

public HM_Knife_PreFrame_Post(iItem)
{
	new id = get_member(iItem, m_pPlayer);

	if(!zp_get_user_nemesis(id))
		return;

	new iState = get_member(iItem, m_Weapon_iWeaponState);

	switch(iState)
	{
		case ABILITY_SKILL:
		{
			new Float:flGameTime = get_gametime();
			new Float:flEntStart = Float:get_entvar(iItem, VAR_STARTPAIN);

			if(0.0 < flEntStart <= flGameTime)
			{
				set_entvar(iItem, VAR_ENT, create_skill(id));
				set_entvar(iItem, VAR_STARTPAIN, 0.0);
			}
		}
		case ABILITY_RESTART: check_user_timer(id, iItem);
	}
}


check_user_timer(id, iItem)
{
	new Float:flGameTime = get_gametime();
	new Float:flWait = Float:get_entvar(iItem, VAR_WAIT);

	if(flWait > flGameTime) return;

	new Float:flReload = Float:get_entvar(iItem, VAR_RELOAD);

	if(flGameTime < flReload)
	{
		AMMOX(id, 15, floatround(flReload - flGameTime, floatround_ceil));
		set_entvar(iItem, VAR_WAIT, flGameTime + 1.0);
	}
	else 
	{
		UTIL_SetWeaponList(id, "weapon_knife", -1, -1, -1, -1, 2, 1, CSW_KNIFE, 0);
		set_member(iItem, m_Weapon_iWeaponState, ABILITY_READY);
	}
}

public create_skill(id)
{
	new iEnt = rg_create_entity("env_sprite");

	if(is_nullent(iEnt))
		return NULLENT;

	set_entvar(iEnt, var_solid, SOLID_BBOX);
	set_entvar(iEnt, var_movetype, MOVETYPE_BOUNCEMISSILE);
	set_entvar(iEnt, var_owner, id);
	//set_entvar(iEnt, var_effects, EF_NODRAW);

	new Float:vecOrigin[3], Float:vecVelocity[3];
	get_velocity_to_aim(id, vecOrigin, DEIMOS_SKILLSPEED, vecVelocity);

	set_entvar(iEnt, var_velocity, vecVelocity);

	engfunc(EngFunc_SetModel, iEnt, g_szSprExplode);
	engfunc(EngFunc_SetSize, iEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
	engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);

	CREATE_BEAMFOLLOW(iEnt, g_pSprZbeam4, 4, 1, 255, 215, 0, 200);
	fm_set_rendering(iEnt, .render = kRenderTransAlpha, .amount = 0);

	SetTouch(iEnt, "RG_Skill_Touch");

	return iEnt;
}

public RG_Skill_Touch(iEnt, iOther)
{
	if(is_user_alive(iOther) && !zp_get_user_zombie(iOther))
	{
		new id = get_entvar(iEnt, var_owner);

		if(!zp_get_user_survivor(iOther) && !zp_get_user_hero(iOther))
		{
			new iItem = get_member(iOther, m_pActiveItem);

			if(!is_nullent(iItem))
			{
				new iSlot = rg_get_iteminfo(iItem, ItemInfo_iSlot);
				if(0 <= iSlot <= 1)
					rg_drop_items_by_slot(iOther, InventorySlotType:++iSlot);
			}
		}
		
		ExecuteHamB(Ham_TakeDamage, iOther, id, id, DEIMOS_SKILLDMG, DMG_GENERIC);
	}

	rh_emit_sound2(iEnt, 0, CHAN_WEAPON, g_szSndSkillHit);

	new Float:vecVelocity[3]; get_entvar(iEnt, var_velocity, vecVelocity);
	set_entvar(iEnt, var_velocity, Float:{0.0, 0.0, 0.0});
	
	xs_vec_normalize(vecVelocity, vecVelocity);
	xs_vec_mul_scalar(vecVelocity, -10.0, vecVelocity);
	new Float:vecOrigin[3]; get_entvar(iEnt, var_origin, vecOrigin);
	xs_vec_add(vecOrigin, vecVelocity, vecOrigin);
	engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);

	fm_set_rendering(iEnt, .render = kRenderTransAdd, .amount = 255);
	set_entvar(iEnt, var_nextthink, get_gametime() + SPRITE_NEXTTHINK);

	SetTouch(iEnt, "");
	SetThink(iEnt, "RG_Shill_Think");
}

public RG_Shill_Think(iEnt)
{
	new Float:flNewFrame = Float:get_entvar(iEnt, var_frame) + 1.0;
	
	if(flNewFrame < SPRITE_FRAMES)
	{
		set_entvar(iEnt, var_frame, flNewFrame);
		set_entvar(iEnt, var_nextthink, get_gametime() + SPRITE_NEXTTHINK);
		return;
	}

	new id = get_entvar(iEnt, var_owner);
	new iItem = get_member(id, m_rgpPlayerItems, SLOT_KNIFE);

	if(!is_nullent(iItem))
	{
		set_entvar(iItem, VAR_ENT, NULLENT);
		start_user_timer(id, iItem);
	}

	rg_remove_ent(iEnt);

}


start_user_timer(id, iItem)
{
	UTIL_SetWeaponList(id, g_szWpnlistName, 15, floatround(DEIMOS_TIME, floatround_ceil), -1, -1, 2, 1, CSW_KNIFE, 0);
	CURWEAPON(id, 1, CSW_KNIFE, -1);
	AMMOX(id, 15, floatround(DEIMOS_TIME, floatround_ceil));

	new Float:flGameTime = get_gametime();

	set_entvar(iItem, VAR_RELOAD, flGameTime + DEIMOS_TIME);
	set_entvar(iItem, VAR_WAIT, flGameTime + 1.0);
	set_member(iItem, m_Weapon_iWeaponState, ABILITY_RESTART);
}

clear_user_data(id)
{
	if(!is_user_connected(id) || !zp_get_user_nemesis(id)) return;

	new iItem = get_member(id, m_rgpPlayerItems, SLOT_KNIFE);

	if(is_nullent(iItem)) return;

	set_member(iItem, m_Weapon_iWeaponState, ABILITY_NO);

	new iSkillEnt = get_entvar(iItem, VAR_ENT);

	if(!is_nullent(iSkillEnt))
		rg_remove_ent(iSkillEnt);

	new iState = get_member(iItem, m_Weapon_iWeaponState);

	if(iState == ABILITY_RESTART)
		UTIL_SetWeaponList(id, "weapon_knife", -1, -1, -1, -1, 2, 1, CSW_KNIFE, 0);

	set_entvar(iItem, VAR_ENT, 0);
	set_entvar(iItem, VAR_WAIT, 0.0);
	set_entvar(iItem, VAR_STARTPAIN, 0.0);
	set_entvar(iItem, VAR_RELOAD, 0.0)
}

stock rg_remove_ent(iEnt)
{
	set_entvar(iEnt, var_flags, FL_KILLME);
	set_entvar(iEnt, var_nextthink, get_gametime());
}

stock get_velocity_to_aim(const id, Float:vecOrigin[3], const Float:flSpeed, Float:vecVelocity[3])
{
	get_entvar(id, var_origin, vecOrigin);
	new Float:vecViewOfs[3]; get_entvar(id, var_view_ofs, vecViewOfs);
	new Float:vecViewAngle[3]; get_entvar(id, var_v_angle, vecViewAngle);
	new Float:vecForward[3]; angle_vector(vecViewAngle, ANGLEVECTOR_FORWARD, vecForward);
	xs_vec_copy(vecForward, vecVelocity);
	
	xs_vec_add(vecViewOfs, vecForward, vecViewOfs);
	xs_vec_add(vecOrigin, vecViewOfs, vecOrigin);

	xs_vec_mul_scalar(vecVelocity, flSpeed, vecVelocity)
}

stock UTIL_SetWeaponList(iPlayer, const szWeaponName[], iPrimaryAmmoID, iPrimaryAmmoMaxAmount, iSecondaryAmmoID, iSecondaryAmmoMaxAmount, iSlotID, iNumberInSlot, iWeaponID, iFlags)
{
	message_begin(MSG_ONE, MsgID_WeaponList, _, iPlayer);
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

stock AMMOX(id, iAmmoId, iAmount)
{
	message_begin(MSG_ONE, MsgID_AmmoX, _, id);
	write_byte(iAmmoId);
	write_byte(iAmount);
	message_end();
}

stock CURWEAPON(id, IsActive, iWeaponID, iClipAmmo)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE, MsgID_CurWeapon, {0, 0, 0}, id);
	write_byte(IsActive);
	write_byte(iWeaponID);
	write_byte(iClipAmmo);
	message_end();
}

stock UTIL_PlayerAnimation(pPlayer, const szAnimation[]) 
{ 
	static iAnimDesired, Float:flFrameRate, Float:flGroundSpeed, bool:bLoops;
	if((iAnimDesired = lookup_sequence(pPlayer, szAnimation, flFrameRate, bLoops, flGroundSpeed)) == -1) iAnimDesired = 0;
	
	static Float:flGameTime; flGameTime = get_gametime();
	
	set_entvar(pPlayer, var_frame, 0.0);
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

stock UTIL_WeaponAnimation(pPlayer, iAnimation)
{
	set_entvar(pPlayer, var_weaponanim, iAnimation);
	
	message_begin_f(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, pPlayer)
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}

stock CREATE_BEAMFOLLOW(pEntity, pSptite, iLife, iWidth, iRed, iGreen, iBlue, iAlpha)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(pEntity);
	write_short(pSptite);
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}