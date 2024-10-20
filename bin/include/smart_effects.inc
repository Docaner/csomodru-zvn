#if defined _smart_effects_included
	#endinput
#endif
#define _smart_effects_included

/**
 * При помощи данного дополнения можно 
 * создавать различные эффекты для entity
 */

#include <amxmodx>
#include <fakemeta>
#include <reapi>

/**
 * Установка битов
 */
#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))

/**
 * Сравнение битов
 */
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define IsSetEqual(%0,%1) ( (%0 & (%1)) == (%1) )

/**
 * ЧЕЛОВЕК
 */
#define IsPlayer(%0) bool: (0 < %0 <= MaxClients)


/**
 * NPC
 */
#define IsNPC(%0) (%0 > MaxClients && get_entvar(%0, var_flags) & FL_MONSTER)
#define IsAliveNPC(%0) (IsNPC(%0) && get_entvar(%0, var_deadflag) == DEAD_NO)
/**
 * Прекеш веапон листа (xUnicorn)
 * 
 * @param szWeaponList      Название weaponlist
 * 
 * @noreturn
 */
stock UTIL_PrecacheWeaponList(const szWeaponList[])
{
    new szBuffer[ 128 ], pFile;

    format(szBuffer, charsmax(szBuffer), "sprites/%s.txt", szWeaponList);
    precache_generic(szBuffer);

    if (!(pFile = fopen(szBuffer, "rb")))
        return;

    new szSprName[MAX_RESOURCE_PATH_LENGTH], iPos;

    while (!feof(pFile)) 
    {
        fgets(pFile, szBuffer, charsmax(szBuffer));
        trim(szBuffer);

        if (!strlen(szBuffer)) 
            continue;

        if ((iPos = containi(szBuffer, "640")) == -1)
            continue;
                
        format(szBuffer, charsmax(szBuffer), "%s", szBuffer[iPos + 3]);       
        trim(szBuffer);

        strtok(szBuffer, szSprName, charsmax(szSprName), szBuffer, charsmax(szBuffer), ' ', 1);
        trim(szSprName);

        precache_generic(fmt("sprites/%s.spr", szSprName));
    }

    fclose(pFile);
}

/**
 * Позволяет поставить рендер объекту
 * 
 * @param iEnt 		Индекс объекта
 * @param iFx		Тип визуализации объекта. Константы kRenderFx.. из amxconst.inc
 * @param flColor	Массив цвета рендера в формате RGB
 * @param iRender 	Тип рендера объекта. Константы kRender.. из amxconst.inc
 * @param flAmount	Степень эффекта 0.0 - 255.0
 * 
 * @noreturn
 */
stock UTIL_SetRendering(iEntity, iFx = kRenderFxNone, Float:flColor[3] = {0.0, 0.0, 0.0}, iRender = kRenderNormal, Float:flAmount = 0.0)
{	
	set_entvar(iEntity, var_renderfx, iFx);
	set_entvar(iEntity, var_rendercolor, flColor);
	set_entvar(iEntity, var_rendermode, iRender);
	set_entvar(iEntity, var_renderamt, flAmount);
}

/**
 * Безопасно удаляет объект
 * 
 * @param iEnt      Индекс объекта, который необходимо удалить
 * 
 * @noreturn
 */
stock rg_remove_ent(const iEnt)
{
    set_entvar(iEnt, var_flags, FL_KILLME);
    set_entvar(iEnt, var_nextthink, get_gametime());
}

/**
 * Удаление предмета из инвентаря по его индексу (xUnicorn)
 * 
 * @param pPlayer       Индекс клиента
 * @param pItem         Индекс предмета
 * 
 * @return              true - если предмет удален, false - не удален.
 */
stock bool: UTIL_StripWeaponByIndex(const pPlayer, const pItem)
{
    if (is_nullent(pItem))
        return false;

    if (get_member(pPlayer, m_pActiveItem) == pItem)
        ExecuteHamB(Ham_Weapon_RetireWeapon, pItem);

    if (!ExecuteHamB(Ham_RemovePlayerItem, pPlayer, pItem))
        return false;

    ExecuteHamB(Ham_Item_Kill, pItem);
    set_entvar(pPlayer, var_weapons, get_entvar(pPlayer, var_weapons) & ~(1<<(get_member(pItem, m_iId))));

    return true;
}

/**
 * Поиск индекса предмета по его classname (xUnicorn)
 * 
 * @param pPlayer       Индекс игрока
 * @param szItemName    ClassName предмета
 * 
 * @return              Индекс предмета, в противном случае NULLENT
 */
stock UTIL_GetItemByName(const pPlayer, const szItemName[])
{
    for (new i, pItem = NULLENT; i < MAX_ITEM_TYPES; i++)
    {
        pItem = get_member(pPlayer, m_rgpPlayerItems, i);
        while (!is_nullent(pItem))
        {
            if (FClassnameIs(pItem, szItemName))
                return pItem;

            pItem = get_member(pItem, m_pNext);
        }
    }
    return NULLENT;
}

/**
 * Установка разброса оружию (xUnicorn)
 * 
 * @param pItem             Индекс оружия
 * @param pPlayer           Индекс игрока
 * @param flUpBase          Старт вверх
 * @param flLateralBase     Старт в бок
 * @param flUpModifier      Множитель увеличения вектора вверх
 * @param flLateralModifier Множитель увеличения вектора в бок
 * @param flUpMax           Максимальный ввектор вверх
 * @param flLateralMax      Максимальный вектор в бок
 * @param iDirectionChange  Шанс смены направления вверх/в бок
 * 
 * @noreturn
 */

stock UTIL_WeaponKickBack( const pItem, const pPlayer, Float: flUpBase, Float: flLateralBase, Float: flUpModifier, Float: flLateralModifier, Float: flUpMax, Float: flLateralMax, iDirectionChange ) 
{
    new Float: flKickUp, Float: flKickLateral;
    new iShotsFired = get_member( pItem, m_Weapon_iShotsFired );
    new iDirection = get_member( pItem, m_Weapon_iDirection );
    new Float:vecPunchAngle[3]; get_entvar( pPlayer, var_punchangle, vecPunchAngle );

    if ( iShotsFired == 1 ) 
    {
        flKickUp = flUpBase;
        flKickLateral = flLateralBase;
    }
    else
    {
        flKickUp = iShotsFired * flUpModifier + flUpBase;
        flKickLateral = iShotsFired * flLateralModifier + flLateralBase;
    }

    vecPunchAngle[ 0 ] -= flKickUp;

    if ( vecPunchAngle[ 0 ] < -flUpMax ) 
        vecPunchAngle[ 0 ] = -flUpMax;

    if ( iDirection ) 
    {
        vecPunchAngle[ 1 ] += flKickLateral;
        if ( vecPunchAngle[ 1 ] > flLateralMax ) 
            vecPunchAngle[ 1 ] = flLateralMax;
    }
    else
    {
        vecPunchAngle[ 1 ] -= flKickLateral;
        if ( vecPunchAngle[ 1 ] < -flLateralMax ) 
            vecPunchAngle[ 1 ] = -flLateralMax;
    }

    if ( iDirectionChange != 0 && !random_num( 0, iDirectionChange ) ) 
        set_member( pItem, m_Weapon_iDirection, !iDirection );

    set_entvar( pPlayer, var_punchangle, vecPunchAngle );
}

/**
 *   Задает анимацию объекту
 *
 *   @param pEntity      Индекс объекта
 *   @param iSequence    Номер анимации (начиная с 0)
 *
 *   @noreturn
 */
stock UTIL_SetEntityAnim( const pEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0 )
{
	set_entvar( pEntity, var_frame, flFrame );
	set_entvar( pEntity, var_framerate, flFrameRate );
	set_entvar( pEntity, var_animtime, get_gametime( ) );
	set_entvar( pEntity, var_sequence, iSequence );
}

/**
    Нормализация угла в диапазоне 0.0 - 360.0
 */
stock Float:UTIL_AngleMod(Float:flAngle)
{
  if(flAngle < 0.0)
    flAngle = flAngle + 360.0 *((flAngle / 360.0) + 1.0);
  else if(flAngle >= 360.0)
    flAngle = flAngle - 360.0 *((flAngle / 360.0));
  
  return flAngle;
}

/**
    Нормализация 3х-мерного угла в диапазоне 0.0 - 360.0
 */
stock UTIL_VecAngleMod(Float:vecAngleIn[3], Float:vecAngleOut[3])
{
    vecAngleOut[0] = floatmod(vecAngleIn[0], 360.0);
    vecAngleOut[1] = floatmod(vecAngleIn[1], 360.0);
    vecAngleOut[2] = floatmod(vecAngleIn[2], 360.0);
}

/**
 *   Интерполяция угла
 *
 *   @param vecInAngle текущий угол
 *   @param vecGoalAngle целевой угол
 *   @param vecOutAngle выходной угол
 *   @param flSpeedMul множитель скорости поворота
 *
 *  @noreturn
 */
stock UTIL_InterpolateAngle(Float:vecInAngle[3], Float:vecGoalAngle[3], Float:vecOutAngle[3], Float:flSpeedMul = 0.1)
{
    new Float:flNormIn, Float:flNormGoal, Float:flDelta, Float:flDeltaAbs, Float:flSpeed;
    for(new i = 0; i < 3; i++) {
        flNormIn = UTIL_AngleMod(vecInAngle[i]);
        flNormGoal = UTIL_AngleMod(vecGoalAngle[i]);

        flDelta = flNormGoal - flNormIn;

        if(flDelta > 180.0) 
            flDelta -= 360.0;
        else if(flDelta < -180.0) 
            flDelta += 360.0;

        flDeltaAbs = floatabs(flDelta);

        flSpeed = floatmax(flDeltaAbs * flSpeedMul, 1.0);

        if(flDeltaAbs > flSpeed)
            vecOutAngle[i] = UTIL_AngleMod(flNormIn + flSpeed * (flDelta > 0 ? 1 : -1));
        else
            vecOutAngle[i] = flNormIn;
    }
}

/* -> Drop Vector to floor <- */
stock UTIL_DropVectorToFloor(Float:vecOrigin[3])
{
	new Float:vecStart[3]; xs_vec_copy(vecOrigin, vecStart);
	vecOrigin[2] = -4096.0;

	engfunc(EngFunc_TraceLine, vecStart, vecOrigin, IGNORE_MONSTERS, 0, 0);
	get_tr2(0, TR_vecEndPos, vecOrigin);
}

/* Интерполяция */
stock Float: UTIL_Lerp( Float: flA, Float: flB, const Float: flT )
  return ( flA + ( flB - flA ) * floatclamp( flT, 0.0, 1.0 ) );

stock UTIL_VectorLerp( const Float:vecStart[3], const Float:vecEnd[3], Float: flT, Float:vecOut[3] )
{
  flT = floatclamp(flT, 0.0, 1.0);

  vecOut[0] = vecStart[0] + ( vecEnd[0] - vecStart[0] ) * flT;
  vecOut[1] = vecStart[1] + ( vecEnd[1] - vecStart[1] ) * flT;
  vecOut[2] = vecStart[2] + ( vecEnd[2] - vecStart[2] ) * flT;
}

/* -> Get speed Vector to 2 points <- */
stock UTIL_GetSpeedVector(const Float:vecStartOrigin[3], const Float:vecEndOrigin[3], Float:flSpeed = 0.0, Float:flTime = 1.0, Float:vecVelocity[3] )
{
	if (!flSpeed)
		flSpeed = xs_vec_distance(vecStartOrigin, vecEndOrigin) / flTime;
	else
		flSpeed /= flTime;

	xs_vec_sub(vecEndOrigin, vecStartOrigin, vecVelocity);
	xs_vec_normalize(vecVelocity, vecVelocity);
	xs_vec_mul_scalar(vecVelocity, flSpeed, vecVelocity);
}

/**
 * Посчитать вектор скорости из одной точки 
 * в другую с учётом гравитации
 *
 * @param vecStartPos стартовая позиция
 * @param vecEndPos конечная позиция
 * @param flTime время в секундах за которое нужно преодолеть растояние
 * @param vecVelocity результирующий вектор скорости
 * @param flGravity гравитация (по умолчанию 800.0)
 *
 * */
stock UTIL_GetSpeedVectorByGravity(const Float:vecStartPos[3], const Float:vecEndPos[3],
    const Float:flTime, Float:vecVelocity[3], const Float:flGravity = 800.0)
{
    new Float:vecGravity[3]; vecGravity[2] = -flGravity;

    for(new i = 0; i < 3; i++)
        vecVelocity[i] = (vecEndPos[i] - vecStartPos[i] - 0.5 * vecGravity[i] * flTime * flTime) / flTime;
}

/* -> Player KnockBack <- */
stock UTIL_PlayerKnockBack( const pVictim, const pAttacker, const Float: flForce, const Float: flVelocityModifier = 0.0 )
{
	if ( flForce == 0.0 )
		return;

	new Float:vecOrigin[3]; get_entvar( pVictim, var_origin, vecOrigin );
	new Float:vecVelocity[3]; get_entvar( pVictim, var_velocity, vecVelocity );
	new Float:vecAttackerOrigin[3]; get_entvar( pAttacker, var_origin, vecAttackerOrigin );
	new Float:vecDirection[3]; xs_vec_sub( vecOrigin, vecAttackerOrigin, vecDirection );
	new Float: flLen = xs_vec_len_2d( vecDirection );

	for ( new i = 0; i < 3; ++i )
		vecVelocity[ i ] = ( vecDirection[ i ] / flLen ) * flForce;

	set_entvar( pVictim, var_velocity, vecVelocity );

	if ( flVelocityModifier )
		set_member( pVictim, m_flVelocityModifier, flVelocityModifier );
}