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
stock UTIL_SetEntityAnim(const pEntity, const iSequence = 0)
{
	set_entvar(pEntity, var_frame, 1.0);
	set_entvar(pEntity, var_framerate, 1.0);
	//set_entvar(pEntity, var_animtime, get_gametime());
	set_entvar(pEntity, var_sequence, iSequence);
}