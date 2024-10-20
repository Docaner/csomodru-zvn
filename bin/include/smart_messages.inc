 #if defined _smart_messages_included
	#endinput
#endif
#define _smart_messages_included

/**
 * Дополнение предназначенное для удобной отправки 
 * сообщений клиенту через функцию message_begin
 */

#include <amxmodx>
#include <fakemeta>
#include <reapi>

/**
 * [#]===============================[#]
 * 
 * Раздел Temp Entity (Временных объектов). 
 * 
 * Создает объекты на определенное время, 
 * индекс которых нельзя получить
 * 
 * [#]===============================[#]
 */

/**
 * Эффект разрушения объекта при котором появляются 
 * модели и разлетаюстся в разные стороны
 * https://github.com/baso88/SC_AngelScript/wiki/TE_BREAKMODEL
 * 
 * @param vecOrigin[3] 			Точка центра эффекта
 * @param vecSize[3] 			Радиус поля в котором появляются модели
 * @param vecVelocity[3]		Скорость и направление объектов
 * @param iRandomVelocity 		Сумма для рандомизации скорости объектов
 * @param iModelIndex			Индекс модели
 * @param iCount				Количество моделей
 * @param flLife				Время жизни моделей
 * @param iFlags				Флаги констант BREAK_.. из hlsdk_const.inc:
 * 								
 * 								BREAK_TYPEMASK - ?
 * 								BREAK_GLASS - Звуки стекла + прозрачность 50%
 * 								BREAK_METAL - Звуки метала
 * 								BREAK_FLESH - Звуки плоти
 * 								BREAK_WOOD - Звуки дерева
 * 								
 * 								Дополнительные флаги
 * 								BREAK_SMOKE - Следы частиц
 * 								BREAK_TRANS - Прозрачность 50%
 * 								BREAK_CONCRETE - ?
 * 								BREAK_2 - ?
 *
 * @noreturn
 */
stock MSG_BreakModel(Float:vecOrigin[3], Float:vecSize[3] = {16.0, 16.0, 16.0}, Float:vecVelocity[3] = {25.0, 25.0, 25.0}, 
	iRandomVelocity, iModelIndex, iCount, Float:flLife, iFlags)
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_BREAKMODEL);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2]);
	write_coord_f(vecSize[0]);
	write_coord_f(vecSize[1]);
	write_coord_f(vecSize[2]);
	write_coord_f(vecVelocity[0]);
	write_coord_f(vecVelocity[1]);
	write_coord_f(vecVelocity[2]);
	write_byte(iRandomVelocity);
	write_short(iModelIndex);
	write_byte(iCount);
	write_byte(floatround(flLife * 10));
	write_byte(iFlags);
	message_end();
}

/**
 * Создает эффект медленно растворяющихся красных частиц
 * https://github.com/baso88/SC_AngelScript/wiki/TE_LAVASPLASH
 * 
 * @param vecOrigin 	Точка создания эффекта
 * 
 * @noreturn
 */
stock MSG_LavaSplash(Float:vecOrigin[3])
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_LAVASPLASH);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2]);
	message_end();
}

/**
 * Луч в форме кольца, расширяющийся со временем. 
 * Ориентация цилиндра не может быть изменена.
 * https://github.com/baso88/SC_AngelScript/wiki/TE_BEAMCYLINDER
 * 
 * @param vecOrigin[3]			Центр точки цилиндра
 * @param flRadius				Максимальный радиус цилиндра
 * @param iModelIndex			Индекс модели спрайта
 * @param iStartFrame			Начальный кадр спрайта
 * @param flFrameRate			FR спрайта (не наносит эффекта)
 * @param flLife				Время жизни линии
 * @param iWidth			    Высота цилинда / толщина луча
 * @param flAmplitude			Амплитуда линии (не наносит эффекта)
 * @param iColorAlpha 			Цвет линии в формате RGBA
 * @param iScrollSpeed			Скорость прокрутки (не наносит эффекта)
 * 
 * @noreturn
 */
stock MSG_BeamCylinder(Float:vecOrigin[3], Float:flRadius, iModelIndex, iStartFrame = 0, Float:flFrameRate = 0.0, 
	Float:flLife, iWidth, Float:flAmplitude = 0.0, iColorAlpha[4] = {255, 255, 255, 255}, iScrollSpeed = 0)
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_BEAMCYLINDER);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2]);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2] + flRadius);
	write_short(iModelIndex);
	write_byte(iStartFrame);
	write_byte(floatround(flFrameRate * 10));
	write_byte(floatround(flLife * 10));
	write_byte(iWidth);
	write_byte(floatround(flAmplitude * 10));
	write_byte(iColorAlpha[0]);
	write_byte(iColorAlpha[1]);
	write_byte(iColorAlpha[2]);
	write_byte(iColorAlpha[3]);
	write_byte(iScrollSpeed);
	message_end();
}

/**
 * Луч в форме кольца, расширяющийся со временем. 
 * Края кольца поворачиваются так, чтобы они всегда 
 * были обращены к вам. Ориентация тора не может быть изменена
 * https://github.com/baso88/SC_AngelScript/wiki/TE_BEAMTORUS
 * 
 * @param vecOrigin[3]          Центр точки тора
 * @param flRadius               Максимальный радиус тора
 * @param iModelIndex           Индекс модели спрайта
 * @param iStartFrame           Начальный кадр спрайта
 * @param flFrameRate           FR спрайта (не наносит эффекта)
 * @param flLife                Время жизни линии
 * @param iWidth                Высота цилинда / толщина луча
 * @param flAmplitude           Амплитуда линии (не наносит эффекта)
 * @param iColorAlpha           Цвет линии в формате RGBA
 * @param iScrollSpeed          Скорость прокрутки (не наносит эффекта)
 * 
 * @noreturn
 */ 
stock MSG_BeamTorus(Float:vecOrigin[3], Float:flRadius, iModelIndex, iStartFrame = 0, Float:flFrameRate = 0.0, 
    Float:flLife, iWidth, Float:flAmplitude = 0.0, iColorAlpha[4] = {255, 255, 255, 255}, iScrollSpeed = 0)
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
    write_byte(TE_BEAMTORUS);
    write_coord_f(vecOrigin[0]);
    write_coord_f(vecOrigin[1]);
    write_coord_f(vecOrigin[2]);
    write_coord_f(vecOrigin[0]);
    write_coord_f(vecOrigin[1]);
    write_coord_f(vecOrigin[2] + flRadius);
    write_short(iModelIndex);
    write_byte(iStartFrame);
    write_byte(floatround(flFrameRate * 10));
    write_byte(floatround(flLife * 10));
    write_byte(iWidth);
    write_byte(floatround(flAmplitude * 10));
    write_byte(iColorAlpha[0]);
    write_byte(iColorAlpha[1]);
    write_byte(iColorAlpha[2]);
    write_byte(iColorAlpha[3]);
    write_byte(iScrollSpeed);
    message_end();
}

/**
 * След луча, который следует за движущимся объектом. 
 * След убьет сам себя, если объект остановится и не начнет двигаться в течение 1 секунды, 
 * или если луч догонит сам себя после того, как объект перестал двигаться.
 * https://github.com/baso88/SC_AngelScript/wiki/TE_BEAMFOLLOW
 * 
 * @param pEntity           Индекс объекта, за которым будет следовать линия
 * @param iModelIndex       Индекс спрайта, который будет отображен на линии
 * @param flLife            Время жизни следа от линни (с)
 * @param iWidth            Толщина линии
 * @param iColorAlpha       Цвет линии в формате RGBA
 * 
 * @noreturn
 */
stock MSG_BeamFollow(pEntity, iModelIndex, Float:flLife, iWidth, iColorAlpha[4] = {255, 255, 255, 255})
{
    message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY);
    write_byte(TE_BEAMFOLLOW);
    write_short(pEntity);
    write_short(iModelIndex);
    write_byte(floatround(flLife * 10.0));
    write_byte(iWidth);
    write_byte(iColorAlpha[0]);
    write_byte(iColorAlpha[1]);
    write_byte(iColorAlpha[2]);
    write_byte(iColorAlpha[3]);
    message_end();
}

/**
 * Стандартный взрыв Half-Life. 
 * Спрайт движется вверх со скоростью 8 единиц в секунду.
 * https://github.com/baso88/SC_AngelScript/wiki/TE_EXPLOSION
 * 
 * @param vecOrigin         Положение в пространстве
 * @param iModelIndex       Модел индекс спрайта
 * @param flScale           Масштаб
 * @param flFrameRate       Частота кадров
 * @param iFlags            Флаги
 * 
#define SF_ENVEXPLOSION_NODAMAGE        (1<<0) // Если оно задано, ENV_EXPLOSION фактически не наносит урона
#define SF_ENVEXPLOSION_REPEATABLE      (1<<1) // Можно ли восстановить этот объект?
#define SF_ENVEXPLOSION_NOFIREBALL      (1<<2) // Не рисуйте огненный шар
#define SF_ENVEXPLOSION_NOSMOKE         (1<<3) // Не втягивайте дым
#define SF_ENVEXPLOSION_NODECAL         (1<<4) // Не оставляйте следов ожога
#define SF_ENVEXPLOSION_NOSPARKS        (1<<5) // Не оставлять следов ожогов
 * @noreturn
 */
stock MSG_Explosion(Float:vecOrigin[3], iModelIndex, Float:flScale, Float:flFrameRate, iFlags)
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
    write_byte(TE_EXPLOSION);
    write_coord_f(vecOrigin[0]);
    write_coord_f(vecOrigin[1]);
    write_coord_f(vecOrigin[2]);
    write_short(iModelIndex);
    write_byte(floatround(flScale * 10.0));
    write_byte(floatround(flFrameRate * 10.0));
    write_byte(iFlags);
    message_end();
}

/**
 * Линия между двумя статическими точками со спрайтом
 * https://github.com/baso88/SC_AngelScript/wiki/TE_BEAMPOINTS
 * 
 * @param vecStart          Стартовая позиция
 * @param vecEnd            Конечная позиция
 * @param iModelIndex       Модел индекс спрайта
 * @param iStartFrame       С какого кадра начинать
 * @param flFrameRate       Частота кадров
 * @param flLife            Время жизни в секундах
 * @param flScale           Масштаб
 * @param flAmplitude       Амплитуда
 * @param iColorAlpha       Цвет
 * @param iScroll           Скорость прокрутки спрайта луча
 * 
 * @noreturn
 */
stock MSG_BeamPoints(Float:vecStart[3], Float:vecEnd[3], iModelIndex, 
                    iStartFrame = 0, Float:flFrameRate = 10.0, Float:flLife = 1.0, Float:flScale = 3.2, 
                    Float:flAmplitude = 0.1, iColorAlpha[4] = {255, 255, 255, 255}, iScroll = 32)
{
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	write_coord_f(vecStart[0]);
	write_coord_f(vecStart[1]);
	write_coord_f(vecStart[2]);
	write_coord_f(vecEnd[0]);
	write_coord_f(vecEnd[1]);
	write_coord_f(vecEnd[2]);
	write_short(iModelIndex);
	write_byte(iStartFrame);
	write_byte(floatround(flFrameRate * 10.0));
	write_byte(floatround(flLife * 10.0));
	write_byte(floatround(flScale * 10.0));
	write_byte(floatround(flAmplitude * 10.0));
	write_byte(iColorAlpha[0]);
	write_byte(iColorAlpha[1]);
	write_byte(iColorAlpha[2]);
	write_byte(iColorAlpha[3]);
	write_byte(iScroll);
	message_end();
}

/**
 * Рисует пунктирную линию между двумя точками. Цвета с зеленым, кажется, не очень хорошо работают.
 * https://github.com/baso88/SC_AngelScript/wiki/TE_LINE
 *
 * @note Host_Error: UserMsg: Not Present on Client 244
 * @note Клиенты вылетают с сервера

 * @param vecStart          Стартовая позиция
 * @param vecEnd            Конечная позиция
 * @param flLife            Время жизни
 * @param iColor            Цвет
 *
 * 
 * @noreturn
 */
stock MSG_Line(Float:vecStart[3], Float:vecEnd[3], Float:flLife = 5.0, iColor[3] = {255, 0, 0})
{
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_LINE);
	write_coord_f(vecStart[0]);
	write_coord_f(vecStart[1]);
	write_coord_f(vecStart[2]);
	write_coord_f(vecEnd[0]);
	write_coord_f(vecEnd[1]);
	write_coord_f(vecEnd[2]);
	write_byte(floatround(flLife * 10.0));
	write_byte(iColor[0]);
	write_byte(iColor[1]);
	write_byte(iColor[2]);
	message_end();
}

/**
 * Рисует красную пунктирную линию между двумя точками, 
 * которая исчезает через 30 секунд. Использует меньше точек, чем TE_LINE.
 * https://github.com/baso88/SC_AngelScript/wiki/TE_SHOWLINE
 * 
 * @param vecStart          Стартовая позиция
 * @param vecEnd            Конечная позиция

 * 
 * @noreturn
 */
stock MSG_ShowLine(Float:vecStart[3], Float:vecEnd[3])
{
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SHOWLINE);
	write_coord_f(vecStart[0]);
	write_coord_f(vecStart[1]);
	write_coord_f(vecStart[2]);
	write_coord_f(vecEnd[0]);
	write_coord_f(vecEnd[1]);
	write_coord_f(vecEnd[2]);
	message_end();
}

/**
 * [#]===============================[#]
 * 
 * Раздел Game Events. 
 * 
 * Позволяет создавать разные события которые можно 
 * хукать через register_event
 * 
 * Индекс сообщения получают из функции get_user_msgid
 * 
 * [#]===============================[#]
 */

//Числовая константа переводящая бит в секунды
#define UNIT_SECOND (1<<12)

//Конвертация Float в битовое 2 байтное число
#define FixedUnsigned16(%0,%1) clamp(floatround(%0 * %1), 0, 0xFFFF) 

/**
 * Эффект затемнения экрана
 * https://wiki.alliedmods.net/Half-Life_1_Game_Events#ScreenFade
 * 
 * @param pPlayer 		Индекс клиента
 * @param flDuration	Длительность дополнительного эфекта
 * @param flHoldtime 	Длительность эффекта покраски экрана в общем
 * @param iFadeType		Тип эффекта смотреть константы SF_FADE.. в cssdk_const.inc:
 * 
 * 						0 - эффект постепенно исчезает
 * 						SF_FADE_IN - эффект постепенно нарастает
 * 						SF_FADE_MODULATE - эффект делает цвет более насыщенным (не смешивать) (?)
 * 						SF_FADE_ONLYONE - постоянный эффект. игнорирует время сообщения
 * 
 * @iColorAlpha			Массив RGBa цвета
 * 
 * @noreturn
 */
stock MSG_ScreenFade(pPlayer, Float:flDuration, Float:flHoldtime = 0.0, iFadeType = 0, iColorAlpha[4] = {255, 255, 255, 255})
{
	static iMsg_ScreenFade; if(!iMsg_ScreenFade) iMsg_ScreenFade = get_user_msgid("ScreenFade");

	new iDuration = FixedUnsigned16(flDuration, UNIT_SECOND),
		iHoldtime = flHoldtime == 0.0 ? iDuration : FixedUnsigned16(flHoldtime, UNIT_SECOND);

	message_begin_f(pPlayer ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iMsg_ScreenFade, _, pPlayer);
	write_short(iDuration);
	write_short(iHoldtime);
	write_short(iFadeType);
	write_byte(iColorAlpha[0]);
	write_byte(iColorAlpha[1]);
	write_byte(iColorAlpha[2]);
	write_byte(iColorAlpha[3]);
	message_end();
}

/**
 * Создает эффект тряски экрана
 * https://wiki.alliedmods.net/Half-Life_1_Game_Events#ScreenShake
 * 
 * @param pPlayer 			Индекс клиента
 * @param flAmplitude 		Амплитуда тряски
 * @param flDuration 		Продолжительность тряски
 * @param flFrequency 		Частота тряски
 *
 * @noreturn
 */
stock MSG_ScreenShake(pPlayer, Float:flAmplitude, Float:flDuration, Float:flFrequency)
{
	static iMsg_ScreenShake; if(!iMsg_ScreenShake) iMsg_ScreenShake = get_user_msgid("ScreenShake");

	message_begin_f(pPlayer ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iMsg_ScreenShake, _, pPlayer);
	write_short(FixedUnsigned16(flAmplitude, UNIT_SECOND));
	write_short(FixedUnsigned16(flDuration, UNIT_SECOND));
	write_short(FixedUnsigned16(flFrequency, UNIT_SECOND));
	message_end();
}

/**
 * Это сообщение обновляет индикатор зеленой полосы в списке оружия HUD. 
 * Он также обновляет количество боеприпасов HUD в рюкзаке в правом нижнем 
 * углу экрана, если данный тип боеприпасов совместим с текущим оружием.
 * https://wiki.alliedmods.net/Half-Life_1_Game_Events#AmmoX
 * 
 * Для получения дополнительной информации смотреть раздел
 * https://wiki.alliedmods.net/CS_Weapons_Information
 * 
 * @param pPlayer       Индекс клиента
 * @param iAmmoId       Индекс боеприпасов
 * @param iAmount       Количество
 * 
 * @noreturn
 */
stock MSG_AmmoX(pPlayer, iAmmoId, iAmount)
{
    static iMsg_AmmoX; if(!iMsg_AmmoX) iMsg_AmmoX = get_user_msgid("AmmoX");

    message_begin(pPlayer ? MSG_ONE : MSG_ALL, iMsg_AmmoX, _, pPlayer);
    write_byte(iAmmoId);
    write_byte(iAmount);
    message_end();
}

/**
 * Это сообщение обновляет количество боеприпасов в магазине 
 * и соответствующий значок типа боеприпасов на HUD
 * https://wiki.alliedmods.net/Half-Life_1_Game_Events#CurWeapon
 * 
 * Для получения дополнительной информации смотреть раздел
 * https://wiki.alliedmods.net/CS_Weapons_Information
 * 
 * @param pPlayer 			Индекс клиента
 * @param IsActive		(?) Активная ли пушка в данный момент (по айди)
 * @param iWeaponID 	(?) Индекс оружия. Константы WEAPON_.. из перечисления WeaponIdType cssdk_const.inc
 * @param iClipAmmo 	(?) Патронов в обойме
 * 
 * @noreturn
 */
stock MSG_CurWeapon(pPlayer, IsActive, iWeaponID, iClipAmmo)
{
 	static iMsg_CurWeapon; if(!iMsg_CurWeapon) iMsg_CurWeapon = get_user_msgid("CurWeapon");
	
	message_begin_f(pPlayer ? MSG_ONE : MSG_ALL, iMsg_CurWeapon, _, pPlayer);
	write_byte(IsActive);
	write_byte(iWeaponID);
	write_byte(iClipAmmo);
	message_end();
}

/**
 * Это сообщение обновляет количество боеприпасов в магазине 
 * и соответствующий значок типа боеприпасов на HUD по индексу оружия
 * 
 * @param pPlayer       Индекс клиента
 * @param IsActive      (?) Активная ли пушка в данный момент (по айди)
 * @param pItem         Индекс оружия. Если 0, то берется оружие,
 *                      которое находится у клиента в ркуах.
 * 
 * @noreturn
 */

stock MSG_Item_CurWeapon(pPlayer, IsActive, pItem = 0)
{
	if(!pItem && is_nullent( (pItem = get_member(pPlayer, m_pActiveItem) )))
	   return;

    MSG_CurWeapon(pPlayer, IsActive, get_member(pItem, m_iId), get_member(pItem, m_Weapon_Clip))
}

/**
 * Это сообщение настраивает список оружия HUD.
 * https://wiki.alliedmods.net/Half-Life_1_Game_Events#WeaponList
 * 
 * Примечание: SlotID начинается с 0.
 * 
 * @param pPlayer                   Индекс клиента
 * @param szWeaponName              Название веапон листа оружия
 * @param iPrimaryAmmoID            Индекс основных боеприпасов
 * @param iPrimaryAmmoMaxAmount     Максимальное количество основных боеприпасов
 * @param iSecondaryAmmoID          Индекс второстепенных боеприпасов
 * @param iSecondaryAmmoMaxAmount   Максимаольное количество второстепенных боеприпасов
 * @param iSlotID                   Номер слота, который занимает оружие. Смотреть констаты CS_WEAPONSLOT_.. в cstrike_const.inc
 * @param iNumberInSlot             Позиция в слоте
 * @param iWeaponID                 Индекс оружия. Константы WEAPON_.. из перечисления WeaponIdType cssdk_const.inc
 * @param iFlags                    Флаги. Константы ITEM_FLAG_.. из cssdk_const.inc
 * 
 * @noreturn
 */

stock MSG_WeaponList(pPlayer, const szWeaponName[], iPrimaryAmmoID, iPrimaryAmmoMaxAmount, iSecondaryAmmoID, 
    iSecondaryAmmoMaxAmount, iSlotID, iNumberInSlot, iWeaponID, iFlags)
{
    static iMsg_WeaponList; if(!iMsg_WeaponList) iMsg_WeaponList = get_user_msgid("WeaponList");

    message_begin(pPlayer ? MSG_ONE : MSG_ALL, iMsg_WeaponList, _, pPlayer);
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

/**
 * Это сообщение настраивает список оружия HUD по индексу оружия.
 * 
 * @param pPlayer                   Индекс клиента
 * @param pItem                     Индекс оружия. Если равен 0, то берет оружие, которое в руках
 * 
 * @noreturn
 */

stock MSG_Item_WeaponList(pPlayer, pItem = 0)
{
    if(!pItem && is_nullent( (pItem = get_member(pPlayer, m_pActiveItem) )))
       return;

    new szWeaponName[MAX_NAME_LENGTH]; 
    rg_get_iteminfo(pItem, ItemInfo_pszName, szWeaponName, charsmax(szWeaponName));

    MSG_WeaponList
    (
        pPlayer, 
        szWeaponName, 
        get_member(pItem, m_Weapon_iPrimaryAmmoType), 
        rg_get_iteminfo(pItem, ItemInfo_iMaxAmmo1),
        get_member(pItem, m_Weapon_iSecondaryAmmoType),
        rg_get_iteminfo(pItem, ItemInfo_iMaxAmmo2),
        rg_get_iteminfo(pItem, ItemInfo_iSlot),
        rg_get_iteminfo(pItem, ItemInfo_iPosition),
        rg_get_iteminfo(pItem, ItemInfo_iId),
        rg_get_iteminfo(pItem, ItemInfo_iFlags)
    );
}

/**
 * Перечисления iStatus
 */
enum
{
    //Скрыть иконку
    STATUS_HIDE,
    //Показать иконку
    STATUS_SHOW,
    //Эффект Flash
    STATUS_FLASH
}

/**
 * Это сообщение рисует/удаляет указанный значок HUD статуса.
 * https://wiki.alliedmods.net/Half-Life_1_Game_Events#StatusIcon
 * 
 * @param pPlayer           Индекс игрока
 * @param szSpriteName      Название иконки спрайта. Весь список: ..\Half-Life\valve\sprites\hud.txt
 * @param iStatus           0 - скрывает, 1 - показывает, 2 - флеш эффект
 * @param iColor            Цвет в формате RGB
 * 
 * @noreturn
 */
stock MSG_StatusIcon(pPlayer, szSpriteName[], iStatus = 0, iColor[3] = {255, 255, 255})
{
    static iMsg_StatusIcon; if(!iMsg_StatusIcon) iMsg_StatusIcon = get_user_msgid("StatusIcon");

    message_begin(pPlayer ? MSG_ONE : MSG_ALL, iMsg_StatusIcon, _, pPlayer);
    write_byte(iStatus = clamp(iStatus, STATUS_HIDE, STATUS_FLASH));
    write_string(szSpriteName);
    
    if(iStatus != STATUS_HIDE)
    {
        write_byte(iColor[0]);
        write_byte(iColor[1]);
        write_byte(iColor[2]);
    }
    
    message_end();
}