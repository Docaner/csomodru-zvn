#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <zombieplague>
#include <smart_effects>
#include <api_maxspeed>
#include <api_flame>
#include <zc_addon_zclasses>
#include <zc_addon_zchoose>

/*//Натив, который получает рандомный звук горения
native bool:zp_get_random_burn_sound(const pClassId, szSound[], iLen);
*/

/**
 * Модель пламени
 */
new const FLAME_MODEL[] = "sprites/zp_br_cso/zombie/flameplayer2.spr"

/**
 * Скорость ниже которой включается костыль-система, которая в присяде позволяет набирать нормально скорость
 */ 
#define FLAME_SPEED_MIN 200.0

/**
 * Стартовый кадр первого пламени
 * Note: Стартовый кадр второго пламени высчитывается g_iFlameMaxFrames - FLAME_FIRST_START_FRAME
 */
#define FLAME_FIRST_START_THINK random_float(float(1 * g_iFlameMaxFrames / 6), float(1 * g_iFlameMaxFrames / 4)) * FLAME_THINK
#define FLAME_SECOND_START_THINK random_float(float(2 * g_iFlameMaxFrames / 3), float(5 * g_iFlameMaxFrames / 6)) * FLAME_THINK

/**
 * Частота обновления кадров пламени
 */
#define FLAME_THINK 0.06

/**
 * Размер пламени
 */
#define FLAME_SCALE 0.55 

/**
 * Модель гари
 */
new const SMOKE_MODEL[] = "sprites/black_smoke1.spr";

/**
 * Размер гари
 */
#define SMOKE_SCALE 0.9

/**
 * Частота обновления кадров гари
 */
#define SMOKE_THINK 0.03

/**
 * Цвет рендера гари
 */
#define SMOKE_COLOR_RENDER Float:{73.0, 77.0, 78.0}

/**
 * Яркость рендера гари
 */
 #define SMOKE_COLOR_AMOUNT 255.0

/**
 * Название класса entity
 */
new const BASE_CLASSNAME[] = "ef_flame";

/**
 * Урон от эффекта огня
 */ 
#define BASE_DAMAGE 35.0

/**
 * Тип урона от огля
 */
#define BASE_DMGTYPE (DMG_GRENADE|DMG_BURN)

/**
 * Частота нанесения урона
 */
#define BASE_THINK 0.3

/**
 * Частота воспроизведения звука горения
 */
#define BASE_SOUND_DELAY random_float(1.5, 5.5)

/**
 * ModelIdexes
 */
new g_iModelIndex_Flame, g_iModelIndex_Smoke;

/**
 * Максимальное количество кадров спрайтов
 */
new g_iFlameMaxFrames, g_iSmokeMaxFrames;

/**
 * Переменные обозначающие горение игрока
 */

new g_pEnt_FlameBase[33] = { NULLENT, ... }, 
	g_pEnt_FlameChild[33][sizeof g_iVarsFlames],
	g_iBitUserFlame;

/**
 * Хуки
 */

//Для огня
new HookChain:g_hPM_Move, HookChain:g_hPlayerKillder;

//Для блока звуков и анимаций урона
new HookChain:g_hSetAnimation, HookChain:g_hStartSound;

//Мультифорварды
new g_hFlameCreatePost, g_hFlameParamsChangePost, g_hFlameDisablePost;

public plugin_precache()
{
	register_plugin("[ZP] Addon: User Flame", "1.0", "Docaner");

	g_iModelIndex_Flame = precache_model(FLAME_MODEL);
	g_iModelIndex_Smoke = precache_model(SMOKE_MODEL);

	g_iFlameMaxFrames = engfunc(EngFunc_ModelFrames, g_iModelIndex_Flame);
	g_iSmokeMaxFrames = engfunc(EngFunc_ModelFrames, g_iModelIndex_Smoke);
}

public plugin_init()
{
	/* Хуки для пламени */

	g_hPM_Move = RegisterHookChain(RG_PM_Move, "@RG__PlayerMove_Post", true);
	g_hPlayerKillder = RegisterHookChain(RG_CSGameRules_PlayerKilled, "@RG__PlayerKilled_Post", true);

	SwitchToggle_Flame(false);	

	/* Хуки для блока анимации и звуков урона */

	g_hSetAnimation = RegisterHookChain(RG_CBasePlayer_SetAnimation, "@RG__PlayerSetAnimation_Pre", false);
	g_hStartSound = RegisterHookChain(RH_SV_StartSound, "@RH__StartSound_Pre", false);

	SwitchToggle_BlockDamageEffect(false);

	/* Создание хуков мульти-форвардов */

	//forward zp_flame_create_post(const pEntBase, const pVictim)
	g_hFlameCreatePost = CreateMultiForward("zp_flame_create_post", ET_IGNORE, FP_CELL, FP_CELL);

	//forward zp_flame_params_change_post(const pEntBase, const pVictim, const pAttacker, const Float:flSeconds)
	g_hFlameParamsChangePost = CreateMultiForward("zp_flame_params_change_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_FLOAT);

	//forward zp_flame_disable_post(const pEntBase, const pVictim);
	g_hFlameDisablePost = CreateMultiForward("zp_flame_disable_post", ET_IGNORE, FP_CELL, FP_CELL);

	/* Инициализация кеша ChildEnts  */
	Init_ChildEnts();
}

stock Init_ChildEnts()
{
	new iSize2 = sizeof g_pEnt_FlameChild[];

	for(new iPlayer = 1, i; iPlayer <= MaxClients; iPlayer++)
		for(i = 0; i < iSize2; i++)
			g_pEnt_FlameChild[iPlayer][i] = NULLENT;
}

public plugin_natives()
{
	register_native("zp_set_user_flame", "@zp_set_user_flame", true)
	register_native("zp_get_user_flame", "@zp_get_user_flame", true);
}

public client_disconnected(id, bool:drop, message[], maxlen)
	Disable_FlameBase(id, true);

public zp_user_infected_pre(id, infector, nemesis)
	Disable_FlameBase(id);

public zp_user_humanized_pre(id, survivor)
	Disable_FlameBase(id);

public zp_round_ended(winteam)
{
	if(!g_iBitUserFlame) return;

	for(new iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		Disable_FlameBase(iPlayer);
}

@RG__PlayerKilled_Post(const pVictim)
	Disable_FlameBase(pVictim);

//native bool:zp_set_user_flame(const pVictim, const pAttacker, const Float:flSeconds);
bool:@zp_set_user_flame(const pVictim, const pAttacker, const Float:flSeconds)
{
	if(flSeconds <= 0.0 || Float:get_entvar(pVictim, var_maxspeed) <= 1.0 || Float:get_entvar(pVictim, var_takedamage) == DAMAGE_NO)
	{
		Disable_FlameBase(pVictim);
		return true;
	}

	new pEnt = g_pEnt_FlameBase[pVictim];

	if(is_nullent(pEnt) && (pEnt = Create_FlameBase(pVictim)) == NULLENT )
		return false;

	g_pEnt_FlameBase[pVictim] = pEnt;

	set_entvar(pEnt, var_ltime, get_gametime() + flSeconds);
	set_entvar(pEnt, var_base_attacker, pAttacker);

	if(!g_iBitUserFlame)
		SwitchToggle_Flame(true);

	SetBit(g_iBitUserFlame, pVictim);

	ExecuteForward(g_hFlameParamsChangePost, _, pEnt, pVictim, pAttacker, flSeconds);

	return true;
}

// native zp_get_user_flame(const pVictim);
@zp_get_user_flame(const pVictim)
	return g_pEnt_FlameBase[pVictim];

/**
 * Костыль, который при горении в присяде фиксит скорость
 */
@RG__PlayerMove_Post(const pPlayer)
{
	if(!IsSetBit(g_iBitUserFlame, pPlayer))
		return;

	new Float:flMaxSpeed = Float:get_pmove(pm_maxspeed);

	if(flMaxSpeed <= 1.0)
	{
		Disable_FlameBase(pPlayer);
		return;
	}

	new Float:flSpeedFlame = Float:get_entvar(g_pEnt_FlameBase[pPlayer], var_base_speedflame);

	if(flSpeedFlame >= FLAME_SPEED_MIN)
		return;

	new iFlags = get_pmove(pm_flags);

	if(IsSetEqual(iFlags, (FL_DUCKING|FL_ONGROUND) ))
	{
		new Float:vecVelocity[3]; get_entvar(pPlayer, var_velocity, vecVelocity);

		if(xs_vec_len(vecVelocity) > flSpeedFlame / 3.0)
		{
			if(flMaxSpeed != flSpeedFlame)
				set_pmove_speed(flSpeedFlame);
		}
		else
		{
			if(flMaxSpeed < FLAME_SPEED_MIN)
				set_pmove_speed(FLAME_SPEED_MIN);
		}
	}
	else
	{
		if(flMaxSpeed != flSpeedFlame)
			set_pmove_speed(flSpeedFlame);
	}
}

stock set_pmove_speed(Float:flValue)
{
	set_pmove(pm_maxspeed, flValue);
	set_pmove(pm_clientmaxspeed, flValue);
	//client_print(0, print_chat, "speedset spam: %d", random(5));
}

@RG__Think_FlameBase(const pEnt)
{
	new Float:flGameTime = get_gametime(), 
		pVictim = get_entvar(pEnt, var_owner),
		pAttacker = get_entvar(pEnt, var_base_attacker),
		iFlags = get_entvar(pVictim, var_flags);

	if(!is_user_connected(pAttacker) || iFlags & FL_INWATER || Float:get_entvar(pVictim, var_takedamage) == DAMAGE_NO || Float:get_entvar(pEnt, var_ltime) <= flGameTime)
	{
		Disable_FlameBase(pVictim);
		return;
	}

	if(zp_get_user_zombie(pVictim) && Float:get_entvar(pEnt, var_base_delaysound) <= flGameTime)
	{
		new szSoundBurn[64]; 

		//zp_get_random_burn_sound(zp_get_user_zombie_class(pVictim), szSoundBurn, charsmax(szSoundBurn));
		zc_get_zclass_sound(zc_get_user_zclass(pVictim), ZMSoundType:e_SoundBurn, szSoundBurn, charsmax(szSoundBurn));

		rh_emit_sound2(pVictim, 0, CHAN_VOICE, szSoundBurn);

		set_entvar(pEnt, var_base_delaysound, flGameTime + BASE_SOUND_DELAY);
	}

	new Float:flHealth = Float:get_entvar(pVictim, var_health) - 2.0;
	new Float:flDamage = (flHealth > BASE_DAMAGE) ? BASE_DAMAGE : 0.0;
	
	SwitchToggle_BlockDamageEffect(true);
	set_member(pVictim, m_LastHitGroup, HIT_GENERIC);
	ExecuteHamB(Ham_TakeDamage, pVictim, pEnt, pAttacker, flDamage, BASE_DMGTYPE );
	SwitchToggle_BlockDamageEffect(false);

	set_entvar(pEnt, var_nextthink, flGameTime + BASE_THINK);
}

/**
 * Блокировка анимации получения урона
 */
@RG__PlayerSetAnimation_Pre()
	return HC_BREAK;

/**
 * Блокировка звуков получения урона
 */
@RH__StartSound_Pre() 
	return HC_BREAK;

/**
 * Создает базовый entity для двух спрайтов
 */
stock Create_FlameBase(const pPlayer)
{
	new pEnt = rg_create_entity("info_target");

	if(is_nullent(pEnt)) return NULLENT;

	set_entvar(pEnt, var_owner, pPlayer);
	set_entvar(pEnt, var_classname, BASE_CLASSNAME);

	new SpeedType:eSpeedType, Float:flValue = rg_get_user_maxspeed(pPlayer, eSpeedType);

	set_entvar(pEnt, var_base_speedtype, eSpeedType);
	set_entvar(pEnt, var_base_speedvalue, flValue);
	set_entvar(pEnt, var_base_speedflame, FLAME_SPEED);

	rg_set_user_maxspeed(pPlayer, FLAME_SPEED, e_SpeedStatic);

	new Float:flGameTime = get_gametime();

	set_entvar(pEnt, var_base_delaysound, flGameTime + BASE_SOUND_DELAY);
	set_entvar(pEnt, var_nextthink, flGameTime + BASE_THINK);

	SetThink(pEnt, "@RG__Think_FlameBase");

	new Float:flThinks[sizeof g_iVarsFlames];

	Generate_NextThinks_Child(g_pEnt_FlameChild[pPlayer], flThinks, sizeof g_iVarsFlames);

	for(new i, iCount = sizeof g_iVarsFlames; i < iCount; i++)
	{
		if( g_pEnt_FlameChild[pPlayer][i] != NULLENT )
			continue;

		if( (g_pEnt_FlameChild[pPlayer][i] = Create_FlameChild(pEnt, i, flThinks[i])) == NULLENT ) 
			continue; 
		
		set_entvar(pEnt, g_iVarsFlames[i], g_pEnt_FlameChild[pPlayer][i]);
	}

	ExecuteForward(g_hFlameCreatePost, _, pEnt, pPlayer);

	return pEnt;
}

stock Generate_NextThinks_Child(const pEntsChild[], Float:flThinks[], const iSize)
{
	new iNulls, iLastNull;

	for(new i; i < iSize; i++)
		if(pEntsChild[i] == NULLENT) 
			iNulls++
		else iLastNull = i;

	if(0 < iNulls < iSize)
	{
		new iNotNull = (iLastNull + 1) % iSize;
		flThinks[iLastNull] = float(( get_entvar(iNotNull, var_frame) + g_iFlameMaxFrames / 2 ) % g_iFlameMaxFrames) * FLAME_THINK; 
	}
	else if(iNulls == iSize)
	{
		flThinks[0] = FLAME_FIRST_START_THINK;
		flThinks[1] = FLAME_SECOND_START_THINK;
	}
}

/**
 * Создает дочерний entity, который является спрайтом
 */
stock Create_FlameChild(const pEntBase, const iIndexChace, const Float:flThink)
{
	new pEnt = rg_create_entity("env_sprite");

	if(is_nullent(pEnt)) return NULLENT;

	Reset__FlameChild(pEnt);

	new pPlayer = get_entvar(pEntBase, var_owner);

	set_entvar(pEnt, var_child_baseent, pEntBase);
	set_entvar(pEnt, var_child_cacheindex, iIndexChace);

	set_entvar(pEnt, var_owner, pPlayer);
	set_entvar(pEnt, var_movetype, MOVETYPE_FOLLOW);
	set_entvar(pEnt, var_aiment, pPlayer);
	set_entvar(pEnt, var_effects, EF_OWNER_NO_VISIBILITY);
	set_entvar(pEnt, var_spawnflags, SF_SPRITE_STARTON);

	set_entvar(pEnt, var_nextthink, get_gametime() + flThink);
	SetThink(pEnt, "@RG__Think_FlameChild");
	return pEnt;
}

@RG__Think_FlameChild(const pEnt) 	
{
	new iModelIndex = get_entvar(pEnt, var_modelindex);
	new Float:flFrame = Float:get_entvar(pEnt, var_frame) + 1.0;
	
	if(iModelIndex == g_iModelIndex_Flame)
	{
		if(flFrame >= g_iFlameMaxFrames)
			Reset__SmokeChild(pEnt);
		else 
		{
			UTIL_SetRendering(pEnt, .iRender = kRenderTransAdd, .flAmount = (255.0 / float(g_iFlameMaxFrames) * flFrame) );
			set_entvar(pEnt, var_frame, flFrame);
		}

		set_entvar(pEnt, var_nextthink, get_gametime() + FLAME_THINK);
	}
	else if(iModelIndex == g_iModelIndex_Smoke)
	{
		if(flFrame >= g_iSmokeMaxFrames)
		{
			new pPlayer = get_entvar(pEnt, var_owner);

			if(g_pEnt_FlameBase[pPlayer] == NULLENT)
			{
				Disable_FlameChild(pPlayer, get_entvar(pEnt, var_child_cacheindex));
				return;
			}

			Reset__FlameChild(pEnt);
		}
		else set_entvar(pEnt, var_frame, flFrame);
		
		set_entvar(pEnt, var_nextthink, get_gametime() + SMOKE_THINK);
	}

}

/**
 * Выставляет стартовые значения для спрайта огня
 */
stock Reset__FlameChild(const pEnt)
{
	set_entvar(pEnt, var_modelindex, g_iModelIndex_Flame);
	set_entvar(pEnt, var_frame, 0.0);
	set_entvar(pEnt, var_scale, FLAME_SCALE);
	UTIL_SetRendering(pEnt, .iRender = kRenderTransAdd, .flAmount = 1.0)
}

/**
 * Выставляет стартовые значения для спрайта гари
 */
stock Reset__SmokeChild(const pEnt)
{
	set_entvar(pEnt, var_modelindex, g_iModelIndex_Smoke);
	set_entvar(pEnt, var_frame, 0.0);
	set_entvar(pEnt, var_scale, SMOKE_SCALE);
	UTIL_SetRendering(pEnt, .flColor = SMOKE_COLOR_RENDER, .iRender = kRenderTransAlpha, .flAmount = SMOKE_COLOR_AMOUNT)
}

/**
 * Удаляет pEntChild вместе с очисткой кеша
 */
stock Disable_FlameChild(const pPlayer, const iIndexChace)
{
	new pEntChild = g_pEnt_FlameChild[pPlayer][iIndexChace]

	if( pEntChild == NULLENT )
		return;

	rg_remove_ent(pEntChild);

	g_pEnt_FlameChild[pPlayer][iIndexChace] = NULLENT;
}

/**
 * Отключение пламени
 * bInstant - моментальное удаление спрайтов
 */
stock Disable_FlameBase(const pPlayer, const bool:bInstant = false)
{
	if(!IsSetBit(g_iBitUserFlame, pPlayer))
		return;

	new pEntBase = g_pEnt_FlameBase[pPlayer];

	if(!is_nullent(pEntBase))
	{
		rg_set_user_maxspeed(pPlayer, Float:get_entvar(pEntBase, var_base_speedvalue), SpeedType:get_entvar(pEntBase, var_base_speedtype))
		
		if(bInstant)
		{
			for(new iCache = 0, iSize = sizeof g_iVarsFlames; iCache < iSize; iCache++)
				Disable_FlameChild(pPlayer, iCache);
		}

		ExecuteForward(g_hFlameDisablePost, _, pEntBase, pPlayer);

		rg_remove_ent(pEntBase);
	}

	g_pEnt_FlameBase[pPlayer] = NULLENT;

	ClearBit(g_iBitUserFlame, pPlayer);

	if(!g_iBitUserFlame)
		SwitchToggle_Flame(false);
}

/**
 * Переключатель хуков для эффекта огня
 */
stock SwitchToggle_Flame(const bool:bValue)
{
	if(bValue)
	{
		EnableHookChain(g_hPM_Move);
		EnableHookChain(g_hPlayerKillder);
	}
	else
	{
		DisableHookChain(g_hPM_Move);
		DisableHookChain(g_hPlayerKillder);
	}
}

/**
 * Переключатель хуков для блокировки эффектов получения урона
 */
stock SwitchToggle_BlockDamageEffect(const bool:bValue)
{
	if(bValue)
	{
		EnableHookChain(g_hSetAnimation);
		EnableHookChain(g_hStartSound);
	}
	else
	{
		DisableHookChain(g_hSetAnimation);
		DisableHookChain(g_hStartSound);
	}
}