#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <xs>
#include <zombieplague>
#include <json>
#include <fun>

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))

new const g_szPathToJSON[] = "addons/amxmodx/configs/zpe_mode/addon_knock_bullet.json"; // Путь до json
#define MAX_VEC_KNOCK_LENGTH 500.0 // Максимальная длина вектора knockback

//#define DEBUG // Включить дебаг [Для отключения закомментируйте строку]

#define KNOCK_BASE 100.0 // Базовый кнокбек для оружий, записанных в json
new Float:g_flKnockBase = 100.0;

#define KNOCK_MUL_DEFAULT 1.0 // Множитель по умолчанию для тех частей тела, где он не указан в json
//#define KNOCK_MUL_DUCK 0.25 // Можитель, если жертва находится в присяде
#define KNOCK_MUL 0.7 // Можитель, если жертва стоит
#define KNOCK_MUL_DUCK 0.25 // Можитель, если жертва находится в присяде
#define BACK_ANGLE 60.0 // Угл векторов для проверки спины
#define KNOCK_MUL_BACK 0.3 // Множитель, если жертва повернута спиной
#define KNCOK_MUL_NEMESIS 0.5 // Множитель, если жертва - немезида
#define KNCOK_MUL_FIRSTZM 0.75 // Множитель, если жертва - первый зомби
//#define KNCOK_MUL_FIRSTZM 1.0 // Множитель, если жертва - первый зомби
#define KNOCK_INFECT_FIRSTZM 2 // После скольки заражений перестаёт действовать KNCOK_MUL_FIRSTZM

#define HIT_MAX 9
#define IMPULSE_NONE -1
#define RADIUS_NULL 0.0
#define KNOK_NULL 0.0
#define PAIN_NULL 1.0

new const Float:g_flMulZombieKnock[] =
{
	1.05, // Классик
	1.1, // Быстрая
	1.05, // Доктор
	1.05, // Толстый
	1.05, // Хищник
	1.05, // Шаман
	1.05, // Тесла
	1.05, // Спин-Дайвер
	1.05 // Китаец
}

#if !defined zp_is_round_end
native zp_is_round_end();
#endif

//Множители для каждого игрока лично (по умолчанию 1.0)
new Float:g_flUserKnocks[33];

//Bullets
new Array:g_aiImpulse, Array:g_aflMaxRadius, Array:g_aflMulKnock[HIT_MAX];

//Количество заражений у первого зомби
new g_iFirstInfects;

//Блокировка VelocityModifier
new g_iUserBitVelosityModifier;

new const g_szParseHit[][] =
{
	"generic",
	"head",
	"chest",
	"stomach",
	"l_arm",
	"r_arm",
	"l_leg",
	"r_leg",
	"shield"
}

new Float:g_vecVel[3]

public plugin_init()
{
	register_plugin("[ZPE] Knockback System", "1.1", "Docaner");
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "CBasePlayer_TraceAttack_Post", true);

	RegisterHam(Ham_TakeDamage, "player", "HM_Player_TakeDamage_Pre", false);
	RegisterHam(Ham_TakeDamage, "player", "HM_Player_TakeDamage_Post", true);

	register_clcmd("reload_knockback", "ClCmd_ReloadKnockback", ADMIN_RCON, "У Вас нет прав")

	arrayset(g_flUserKnocks, 1.0, sizeof g_flUserKnocks);
}

public plugin_natives()
{
	register_native("zp_set_user_velocitymifier", 	"zp_set_user_velocitymifier", 1);
	register_native("zp_set_user_block_velocitymifier", 	"zp_set_user_block_velocitymifier", 1);
	register_native("zp_get_user_block_velocitymifier", 	"zp_get_user_block_velocitymifier", 1);
	register_native("zp_set_user_knock_by_trace", 	"zp_set_user_knock_by_trace", 1);
	register_native("zp_set_user_knock_by_missile", "zp_set_user_knock_by_missile", 1);
	register_native("zp_set_user_mul_knock", "zp_set_user_mul_knock", 1);
	register_native("zp_get_user_mul_knock", "zp_get_user_mul_knock", 1);
}

public OnAutoConfigsBuffered()
{
	parse_knockback_bullet();
}

public plugin_end() 
	clear_data()

public zp_round_ended()
	g_iFirstInfects = 0


public zp_user_infected_post(id, infector, nemesis)
{
	if(infector && zp_get_user_first_zombie(infector))
		g_iFirstInfects++;
}

public CBasePlayer_TraceAttack_Post(pVictim, pAttacker, Float:flDamage, Float:vecDir[3], tr, bDamageType)
{
	if(!is_user_connected(pAttacker) || zp_get_user_zombie(pAttacker) || get_user_godmode(pVictim) || bDamageType & DMG_GRENADE) 
		return HC_CONTINUE;

	new pActiveItem = get_member(pAttacker, m_pActiveItem)

	if(is_nullent(pActiveItem))
		return HC_CONTINUE;

	#if defined DEBUG
	client_print(0, print_chat, "var_impulse: %d", get_entvar(pActiveItem, var_impulse));
	#endif

	new iArray;
	if((iArray = ArrayFindValue(g_aiImpulse, get_entvar(pActiveItem, var_impulse))) == -1)
		return HC_CONTINUE; 

	new iHitType = get_tr2(tr, TR_iHitgroup);

	zp_set_user_knock_by_trace(pVictim, pAttacker, tr, Float:ArrayGetCell(g_aflMaxRadius, iArray), Float:ArrayGetCell(g_aflMulKnock[iHitType], iArray))
	return HC_CONTINUE;
}


public HM_Player_TakeDamage_Pre(iVictim, iInflictor, iAttacker, Float:flDamage, iBitDmg)
{
	if(!zp_get_user_zombie(iVictim) || !is_user_connected(iAttacker) || get_user_weapon(iAttacker) == CSW_KNIFE)
		return;

	get_entvar(iVictim, var_velocity, g_vecVel);
}

public HM_Player_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, iBitDmg)
{
	if(!is_user_alive(iVictim) || !zp_get_user_zombie(iVictim) || !is_user_connected(iAttacker) || get_user_weapon(iAttacker) == CSW_KNIFE)
		return;

	set_member(iVictim, m_flVelocityModifier, get_entvar(iVictim, var_flags) & FL_DUCKING ? 1.0 : 0.933)
	set_entvar(iVictim, var_velocity, g_vecVel);
}

public ClCmd_ReloadKnockback(id)
{
	clear_data();
	parse_knockback_bullet();
	client_print(id, print_chat, "[KNOCK] Knockback успешно перезагружен");
}


/**
 * Установка VelocityModifier
 * @param iPlayer - id клиента, которому нужно установить замедление
 * @param Float:flModifier - занчение замедления (0.0 - клиента останавливает полностью | 1.0 - клиент спокойно бежит)
 * @return - вернёт true, если VelocityModifier будет  установлен
*/
public bool:zp_set_user_velocitymifier(iPlayer, Float:flModifier)
{
	if(zp_is_round_end() || !is_user_alive(iPlayer) || IsSetBit(g_iUserBitVelosityModifier, iPlayer))
		return false;

	if(zp_get_user_first_zombie(iPlayer) && g_iFirstInfects < KNOCK_INFECT_FIRSTZM)
		return false;

	set_member(iPlayer, m_flVelocityModifier, flModifier);
	return true;
}

/**
 * Блокировка VelocityModifier
 * 
 * @param id 			player id
 * @param iValue 		true - заблокировать установку VelModif
 * 						false - разрешить установку VelModif
 * 
 * @noreturn
 */
public zp_set_user_block_velocitymifier(const id, const iValue)
	if(iValue) 
		SetBit(g_iUserBitVelosityModifier, id); 
	else 
		ClearBit(g_iUserBitVelosityModifier, id);


/**
 * Получить блокировку VelocityModifier
 * 
 * @param id 			player id
 * 
 * @return 				true - VelModif заблокирован
 * 						false - VelModif разрешен
 */
public zp_get_user_block_velocitymifier(const id)
	return IsSetBit(g_iUserBitVelosityModifier, id);

/**
 * Откидывание зомби по трейс-аттаке
 * @param iVictim 			- Жертва
 * @param iAttacker 		- Атакующий
 * @param pTrace 			- Указатель на трейс аттаку
 * @param Float:flRadius 	- Минимальное расстояние между жертвой и атакующим для работы откидывания (0.0 - если не нужно учитывать расстояние)
 * @param Float:flMulKnock 	- Множитель откидывания
 * 
 * @return 					- вернёт true, если кнокбек будет нанесён жертве 
 */
public bool:zp_set_user_knock_by_trace(iVictim, iAttacker, pTrace, Float:flRadius, Float:flMulKnock)
{
	new Float:vecVictim[3]; get_entvar(iVictim, var_origin, vecVictim);
	new Float:vecAttacker[3]; get_entvar(iAttacker, var_origin, vecAttacker);
	new Float:flDist = get_distance_f(vecVictim, vecAttacker);
	new Float:flMulRadius;

	//Если растояние позволительно, то продолжаем
	if((flMulRadius = get_mulknock_by_useful_radius(flRadius, flDist)) <= 0.0)
		return false;

	//Получаем координаты позиции выстрела атакующего
	new Float:vecViewOfs[3]; get_entvar(iAttacker, var_view_ofs, vecViewOfs);
	new Float:vecViewAngle[3]; get_entvar(iAttacker, var_v_angle, vecViewAngle);
	new Float:vecForward[3]; angle_vector(vecViewAngle, ANGLEVECTOR_FORWARD, vecForward);
	new Float:vecStart[3];

	xs_vec_add(vecViewOfs, vecForward, vecViewOfs);
	xs_vec_add(vecAttacker, vecViewOfs, vecStart);

	//Получаем точку, куда попат атакующий
	new Float:vecEnd[3]; get_tr2(pTrace, TR_vecEndPos, vecEnd);

	//Вычисляем направление кнокбека
	new Float:vecDir[3]; get_vec_dir(vecEnd, vecStart, vecDir);

	set_user_knock(iVictim, iAttacker, flMulKnock * flMulRadius, vecDir)
	return true;
}

/**
 * Откидывание зомби (необходимо, если урон не детектится по трейс-аттаке)
 * @param iVictim 			- Жертва
 * @param iAttacker 		- Атакующий
 * @param Float:flRadius 	- Минимальное расстояние между жертвой и атакующим для работы откидывания (0.0 - если не нужно учитывать расстояние)
 * @param Float:flMulKnock 	- Множитель откидывания
 * 
 * @return 					- вернёт true, если кнокбек будет нанесён жертве 
 */
public bool:zp_set_user_knock_by_missile(iVictim, iAttacker, Float:flRadius, Float:flMulKnock)
{
	if(zp_is_round_end() || !is_user_alive(iVictim) || !is_user_alive(iAttacker))
		return false;

	//Проверяем расстояние между жертвой и атакующим
	new Float:vecVictim[3]; get_entvar(iVictim, var_origin, vecVictim);
	new Float:vecAttacker[3]; get_entvar(iAttacker, var_origin, vecAttacker);
	new Float:flDist = get_distance_f(vecVictim, vecAttacker);
	new Float:flMulRadius;

	//Если растояние позволительно, то продолжаем
	if((flMulRadius = get_mulknock_by_useful_radius(flRadius, flDist)) <= 0.0)
		return false;
	
	//Получаем вектор-направление кнокбека от снаряда до жертвы
	//new Float:vecMissile[3]; get_entvar(iMissile, var_origin, vecMissile);
	new Float:vecDir[3]; get_vec_dir(vecVictim, vecAttacker, vecDir);

	set_user_knock(iVictim, iAttacker, flMulKnock * flMulRadius, vecDir);

	return true;
}

/**
 * Установка knock лично игроку
 * @param id 				- Игрок
 * @param Float:flValue 	- Значение (по умолчанию 1.0)
 * @param Float:flRadius 	- Минимальное расстояние между жертвой и атакующим для работы откидывания (0.0 - если не нужно учитывать расстояние)
 * 
 * @noreturn
 */
public zp_set_user_mul_knock(id, Float:flValue)
	g_flUserKnocks[id] = flValue;


/**
 * Получение личного knock
 * @param id 				- Игрок
 * 
 * @return 					- Значение личного knock
 */
public Float:zp_get_user_mul_knock(id)
	return g_flUserKnocks[id];

//Получение направления
stock get_vec_dir(Float:vecVictim[3], Float:vecAttacker[3], Float:vecDir[3])
{
	xs_vec_sub(vecVictim, vecAttacker, vecDir);
	xs_vec_normalize(vecDir, vecDir);
}

//Получение множителя по расстаянию между жертвой и атакующим
stock Float:get_mulknock_by_useful_radius(Float:flRadius, Float:flDist)
{
	if(flRadius <= 0.0) return 1.0;

	new Float:flUseful = flRadius - flDist;

	if(flUseful <= 0.0) return 0.0;

	//Расстояние между жертвой и атакующим учитывается
	//return flUseful / flRadius;
	
	//Расстояние между жертвой и атакующим не учитывается
	return 1.0;

}

//Установка кнокбека по направлению
stock set_user_knock(iVictim, iAttacker, Float:flMulKnock, Float:vecDir[3])
{
	//Выставляем базовый кнокбек
	new Float:flMaxSpeed = Float:get_entvar(iVictim, var_maxspeed);
	new Float:flKnock = (get_entvar(iVictim, var_flags) & FL_DUCKING) ? flMaxSpeed / 3.0 : flMaxSpeed;

	//Умножаем на множитель
	flKnock *= flMulKnock;

	//Учитываем множитель для каждого игрока
	flKnock *= g_flUserKnocks[iVictim];
	
	new iFlags = get_entvar(iVictim, var_flags);
	
	//Если жертва сидит, то умножаем на множитель
	/*if(iFlags & FL_DUCKING)
	{
		flKnock *= KNOCK_MUL_DUCK

		new Float:vecViewAttacker[3]; get_entvar(iAttacker, var_v_angle, vecViewAttacker);
		new Float:vecFwAttacker[3]; angle_vector(vecViewAttacker, ANGLEVECTOR_FORWARD, vecFwAttacker);

		new Float:vecViewVictim[3]; get_entvar(iVictim, var_v_angle, vecViewVictim);
		new Float:vecFwVictim[3]; angle_vector(vecViewVictim, ANGLEVECTOR_FORWARD, vecFwVictim);

		if(floatabs(xs_vec_angle(vecFwAttacker, vecFwVictim)) <= BACK_ANGLE)
			flKnock *= KNOCK_MUL_BACK
	}
	else flKnock *= KNOCK_MUL;*/

	if(zp_get_user_nemesis(iVictim))
		flKnock *= KNCOK_MUL_NEMESIS;

	if(zp_get_user_first_zombie(iVictim) && g_iFirstInfects < KNOCK_INFECT_FIRSTZM)
		flKnock *= KNCOK_MUL_FIRSTZM;

	new iZombie = zp_get_user_zombie_class(iVictim);

	if(iZombie >= 0 || iZombie < sizeof g_flMulZombieKnock)
		flKnock *= g_flMulZombieKnock[iZombie]

	new Float:vecVelocityVic[3]; get_entvar(iVictim, var_velocity, vecVelocityVic);

	new Float:vecKnock[3]; xs_vec_mul_scalar(vecDir, flKnock, vecKnock);
	vecKnock[2] = 0.0;	
	xs_vec_add(vecVelocityVic, vecKnock, vecVelocityVic);

	if(xs_vec_len(vecVelocityVic) > MAX_VEC_KNOCK_LENGTH)
	{
		xs_vec_normalize(vecVelocityVic, vecVelocityVic);
		xs_vec_mul_scalar(vecVelocityVic, MAX_VEC_KNOCK_LENGTH, vecVelocityVic);
	}
	
	set_entvar(iVictim, var_velocity, vecVelocityVic);

	#if defined DEBUG
	client_print(0, print_chat, "flKnock: %f", flKnock);
	#endif
}

stock create_knockback_add(const Float:vecVictim[3], const Float:vecAttacker[3], const Float:flKnock, const Float:fKnockbackUp, Float:vecOut[3])
{
	new Float:vecDiff[3];

	xs_vec_sub(vecVictim, vecAttacker, vecDiff);
	vecDiff[2] = 0.0;

	new Float:fMax;

	if(floatabs(vecDiff[0]) > fMax) fMax = floatabs(vecDiff[0]);
	if(floatabs(vecDiff[1]) > fMax) fMax = floatabs(vecDiff[1]);

	if(fMax > 0.0)
	{
		xs_vec_div_scalar(vecDiff, fMax, vecDiff);
		xs_vec_mul_scalar(vecDiff, flKnock, vecDiff);
		xs_vec_add(vecOut, vecDiff, vecOut);
		vecOut[2] = fKnockbackUp;

		if(xs_vec_len(vecOut) > MAX_VEC_KNOCK_LENGTH)
		{
			xs_vec_normalize(vecOut, vecOut);
			xs_vec_mul_scalar(vecOut, MAX_VEC_KNOCK_LENGTH, vecOut);
		}
	}
}

parse_knockback_bullet()
{
	new JSON:jHandle = json_parse(g_szPathToJSON, true, true)

	if(!json_is_object(jHandle))
		set_fail_state("Неудалось распарсить '%s'", g_szPathToJSON);

	if(!json_object_has_value(jHandle, "weapons", JSONArray))
	{
		json_free(jHandle);
		set_fail_state("В '%s' нет поля weapons", g_szPathToJSON);
	}

	g_aiImpulse = ArrayCreate();
	g_aflMaxRadius = ArrayCreate();

	for(new i; i < sizeof g_aflMulKnock; i++)
		g_aflMulKnock[i] = ArrayCreate();

	new JSON:jArrayWeapons = json_object_get_value(jHandle, "weapons");
	new iCount = json_array_get_count(jArrayWeapons);
	
	new JSON:jTemp;

	for(new i; i < iCount; i++)
	{
		jTemp = json_array_get_value(jArrayWeapons, i);

		if(json_is_object(jTemp))
		{
			if(json_object_has_value(jTemp, "impulse", JSONNumber))
				ArrayPushCell(g_aiImpulse, json_object_get_number(jTemp, "impulse"))
			else
				ArrayPushCell(g_aiImpulse, IMPULSE_NONE);

			if(json_object_has_value(jTemp, "radius", JSONNumber))
				ArrayPushCell(g_aflMaxRadius, json_object_get_real(jTemp, "radius"))
			else
				ArrayPushCell(g_aflMaxRadius, RADIUS_NULL);

			for(new j; j < sizeof g_szParseHit; j++)
			{
				if(json_object_has_value(jTemp, g_szParseHit[j], JSONNumber))
					ArrayPushCell(g_aflMulKnock[j], json_object_get_real(jTemp, g_szParseHit[j]));
				else
					ArrayPushCell(g_aflMulKnock[j], KNOCK_MUL_DEFAULT);
			}
		}

		json_free(jTemp);
	}

	json_free(jArrayWeapons);
	json_free(jHandle);
}

clear_data()
{
	ArrayDestroy(g_aiImpulse);
	ArrayDestroy(g_aflMaxRadius);

	for(new i; i < sizeof g_aflMulKnock; i++)
		ArrayDestroy(g_aflMulKnock[i]);
}