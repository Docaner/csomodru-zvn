#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <zombieplague>
#include <human_models>

new const g_szClassName[] = {"ML_HEAVY_NAME"};			// Название класса 
new const g_szClassInfo[] = {"ML_HEAVY_INFO"};			// Описание класса
new const g_szClassModel[] = "zp_br_heavy_b10";			// Модель класса
new const g_szClassClawModel[] = "claws_heavy.mdl";		// Модель рук класса
#define CLASS_HEALTH 2850								// Здоровье
#define CLASS_SPEED 230									// Скорость
#define CLASS_GRAVITY 0.87								// Гравитация
#define CLASS_KNOCKBACK 0.49							// Отбрасывание

#define HEAVY_MAXTRAPS 	5 //Максимальное число ловушек
#define HEAVY_STARTTRAP 3 //Начальное число ловушек

#define HEAVY_ADDTRAP 1 //Сколько давать ловушек за заражение
#define HEAVY_PRESSED 1 //На сколько зажать кнопку, чтобы появилась ловушка
#define HEAVY_ATTACKRADIUS 300.0 // В этом радиусе, если человек попадёт в толстяка, то способность установки ловушки сбросится

#define HEAVY_TRAPBLOCK 8.0 // Насколько блокировать передвижение жерве ловушки

new const g_szModelTrap[] = "models/zp_br_cso/zombie/other/zombitrap.mdl" // Модель ловушки
new const g_szSoundTrap[] = "zp_br_cso/zombie/male/heavy_trapsetup.wav" // Звук установки ловушки
new const g_szSoundTrapped[] = "zp_br_cso/zombie/male/heavy_trapped.wav" // Звук застревания в ловушке
new const g_szSoundTrappedGirl[] = "zp_br_cso/zombie/female/heavy_trapped_female.wav" // Звук застревания для женских моделей
#define HEAVY_TRAPRADIUS 300.0 //Радиус ловушки, в близи которого нельзя ставить другую ловушку
//Хитбокс ловушки
new const Float:g_vecTrapMins[3] = {-15.0, -15.0, 9.0};
new const Float:g_vecTrapMaxs[3] = {15.0, 15.0, 10.0};

new const g_szClassName_Trap[] = "heavy_trap"; // Класснейм ловушки
#define IMPULSE_TRAP 523452 //Импульс ловушки

//WeaponList
new const g_szWpnlistModel[] = "sprites/zp_br_cso/zombie/trap2.txt" // Weaponlist
new const g_szWpnlistHud[] = "sprites/zp_br_cso/zombie/640hud90b.spr" // Спрайт худа weaponlist
new const g_szWpnlistName[] = "zp_br_cso/zombie/trap2" // Название weaponlist


#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))

//Knife Entity
#define var_traps 	var_iuser1 // Количестов ловушек
#define var_pressed	var_fuser1 // Время зажатия кнопки [R]
#define var_restore var_fuser2 // Восстановление способности после получения урона
#define var_touch_block var_fuser3 // Блокировка последнего касания

//WeaponState
enum
{
	ABILITY_NO = 0, //Блокировка способности
	ABILITY_READY,	//Готовность способности
	ABILITY_THINK	//Установка ловушки
}

#define SLOT_KNIFE 3 //Слот ножа

//Trap Entity
#define var_trapped var_iuser1 // id игрока, застрявшего в ловушке

#define MsgID_AmmoX 99
#define MsgID_WeaponList 78

new g_iMaxPlayers;

new g_iClass, g_iBitUserClass;

new g_iEntTrapped[33];

public plugin_precache()
{
	register_plugin("[ZP] Zombie class: Heavy", "0.1b", "Docaner");

	g_iClass = zp_register_zombie_class(g_szClassName, g_szClassInfo, g_szClassModel, 
		g_szClassClawModel, CLASS_HEALTH, CLASS_SPEED, CLASS_GRAVITY, CLASS_KNOCKBACK);

	precache_model(g_szModelTrap);

	precache_sound(g_szSoundTrap);
	precache_sound(g_szSoundTrapped);
	precache_sound(g_szSoundTrappedGirl);

	precache_generic(g_szWpnlistModel);
	precache_generic(g_szWpnlistHud);

	register_clcmd(g_szWpnlistName, "Command_HookWeapon");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_PlayerKilled_Post", true);
	RegisterHookChain(RG_CBasePlayer_Jump, "RG_PlayerJump_Post", true);

	RegisterHam(Ham_Spawn, "player", "HM_PlayerSpawn_Post", true);
	RegisterHam(Ham_TakeDamage, "player", "HM_Player_TakeDamage_Post", true);
	RegisterHam(Ham_Item_PreFrame, "player", "HM_Player_PreFrame_Post", true);

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "HM_Kinfe_Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame, "weapon_knife", "HM_Knife_PostFrame_Post", true);
	RegisterHam(Ham_Item_Holster, "weapon_knife", "HM_Knife_Holster_Post", true);

	g_iMaxPlayers = get_maxplayers();

	arrayset(g_iEntTrapped, NULLENT, sizeof g_iEntTrapped);

	register_dictionary("zp_cso_classes.txt");
}

public plugin_natives()
{
	register_native("zp_is_user_trapped", "zp_is_user_trapped", 1);
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	disable_trap(id);
	disable_class(id);
}

public zp_user_humanized_post(id, survivor)
	disable_class(id);

public zp_user_infected_post(id, infector, nemesis)
{
	//Удаляем ловушку, если заразили
	disable_trap(id);

	//Добавляем ловушку за заражение
	heavy_trap_add(infector, HEAVY_ADDTRAP);

	if(zp_get_user_zombie_class(id) != g_iClass || zp_is_survivor_round()) return;

	if(nemesis)
	{
		disable_class(id);
		return;
	}

	//Выдача класса
	SetBit(g_iBitUserClass, id);

	new pItem = get_member(id, m_rgpPlayerItems, SLOT_KNIFE);

	if(!is_nullent(pItem)) 
	{
		//Делаем способность доступной
		set_member(pItem, m_Weapon_iWeaponState, ABILITY_READY);

		//Установка начального количества ловушек
		set_entvar(pItem, var_traps, HEAVY_STARTTRAP);
	}

	new pActiveItem = get_member(id, m_pActiveItem);

	if(pActiveItem == pItem)
	{
		UTIL_SetWeaponList(id, g_szWpnlistName, 15, HEAVY_MAXTRAPS, -1, -1, 2, 1, CSW_KNIFE, 0);
		AMMOX(id, 15, HEAVY_STARTTRAP);
	}
}

public zp_round_ended()
{
	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
		disable_trap(iPlayer);

	if(g_iBitUserClass)
	{
		new iTrap = NULLENT;
		while((iTrap = fm_find_ent_by_class(iTrap, g_szClassName_Trap)) > 0)
			rg_remove_ent(iTrap);

		for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
			disable_class(iPlayer, false);
	}
}

public Command_HookWeapon(id)
{
	engclient_cmd(id, "weapon_knife");
	return PLUGIN_HANDLED;
}

public RG_PlayerKilled_Post(iVictim, iKiller)
{
	disable_trap(iVictim);
	disable_class(iVictim);

	heavy_trap_add(iKiller, HEAVY_ADDTRAP)
}

public RG_PlayerJump_Post(id)
{
	if(is_nullent(g_iEntTrapped[id])) return HC_CONTINUE;
	//Запрещаем застрявшему в ловушке прыгать
	set_entvar(id, var_oldbuttons, get_entvar(id, var_oldbuttons) | IN_JUMP);
	return HC_BREAK;
}

public HM_PlayerSpawn_Post(id)
	if(IsSetBit(g_iBitUserClass, id)) RequestFrame("Request_PlayerSpawn_Post", id);

public Request_PlayerSpawn_Post(id)
{
	if(!IsSetBit(g_iBitUserClass, id)) return;

	new pActiveItem = get_member(id, m_pActiveItem);

	if(!is_nullent(pActiveItem) && get_member(pActiveItem, m_iId) == CSW_KNIFE)
	{
		UTIL_SetWeaponList(id, g_szWpnlistName, 15, HEAVY_MAXTRAPS, -1, -1, 2, 1, CSW_KNIFE, 0);
		AMMOX(id, 15, HEAVY_STARTTRAP);
	}
}

public HM_Player_TakeDamage_Post(iVictim, iInflictor, iAttacker)
{
	if(!IsSetBit(g_iBitUserClass, iVictim) || !is_user_alive(iAttacker) || zp_get_user_zombie(iAttacker))
		return;

	new pItem = get_member(iVictim, m_rgpPlayerItems, SLOT_KNIFE);

	if(is_nullent(pItem) || get_member(pItem, m_Weapon_iWeaponState) != ABILITY_THINK)
		return;

	new Float:vecVictim[3]; get_entvar(iVictim, var_origin, vecVictim);
	new Float:vecAttacker[3]; get_entvar(iAttacker, var_origin, vecAttacker);

	if(get_distance_f(vecVictim, vecAttacker) > HEAVY_ATTACKRADIUS)
		return;

	//Убираем режим установки ловушки
	client_print(iVictim, print_center, "Отмена способности");

	disable_ability_think(iVictim, pItem);
}

public HM_Player_PreFrame_Post(id)
{
	if(IsSetBit(g_iBitUserClass, id))
	{
		new pItem = get_member(id, m_rgpPlayerItems, SLOT_KNIFE);

		if(is_nullent(pItem) || get_member(pItem, m_Weapon_iWeaponState) != ABILITY_THINK)
			return;

		//Запрещаем передвигаться в момент установки ловушки
		set_entvar(id, var_maxspeed, 1.0);
	}
	//Если человек застрял в ловушке, то запрещаем движение
	else if(!is_nullent(g_iEntTrapped[id]))
		set_entvar(id, var_maxspeed, 1.0);

}

public HM_Kinfe_Deploy_Post(pItem)
{
	new id = get_member(pItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserClass, id)) return;

	UTIL_SetWeaponList(id, g_szWpnlistName, 15, HEAVY_MAXTRAPS, -1, -1, 2, 1, CSW_KNIFE, 0);
	AMMOX(id, 15, get_entvar(pItem, var_traps));

	//Блокировку flNextAttack переносим на оружие 
	new Float:flNextAttack = Float:get_member(id, m_flNextAttack);

	set_member(pItem, m_Weapon_flNextPrimaryAttack, flNextAttack);
	set_member(pItem, m_Weapon_flNextSecondaryAttack, flNextAttack);

	//Убираем блокировку PostFrame
	set_member(id, m_flNextAttack, 0.0);
}

public HM_Knife_PostFrame_Post(pItem)
{
	new id = get_member(pItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserClass, id)) return;

	new iWeaponState = get_member(pItem, m_Weapon_iWeaponState);

	switch(iWeaponState)
	{
		case ABILITY_READY:
		{
			//Проверяем на нажатие кнопки
			if(~get_member(id, m_afButtonPressed) & IN_RELOAD) 
				return;

			if(!get_entvar(pItem, var_traps))
			{
				client_print(id, print_center, "Ловушки закончились!")
				return;
			}
		
			//Проверяем, что зомби находится на земле
			if(~get_entvar(id, var_flags) & FL_ONGROUND)
			{
				client_print(id, print_center, "Ловушку можно ставить только на земле!")
				return;
			}

			if(Float:get_entvar(pItem, var_touch_block) > get_gametime())
			{
				client_print(id, print_center, "Нельзя ставить ловушки близко!")
				return;
			}

			//Выдаём таймер
			client_print(id, print_center, "Установка...")

			set_member(pItem, m_Weapon_iWeaponState, ABILITY_THINK);

			rg_send_bartime(id, HEAVY_PRESSED);
			set_entvar(pItem, var_pressed, get_gametime() + float(HEAVY_PRESSED));

			set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
			ExecuteHamB(Ham_Item_PreFrame, id);
		}
		case ABILITY_THINK:
		{
			//Проверяем если кнопка отпущена
			if(get_member(id, m_afButtonReleased) & IN_RELOAD)
			{
				client_print(id, print_center, "Отмена способности");

				disable_ability_think(id, pItem);
				return;
			}

			//Проверяем, что зомби находится на земле
			if(~get_entvar(id, var_flags) & FL_ONGROUND)
			{
				client_print(id, print_center, "Ловушку можно ставить только на земле!");

				disable_ability_think(id, pItem);
				return;
			}

			//Проверяем время
			if(Float:get_entvar(pItem, var_pressed) > get_gametime())
				return;

			client_print(id, print_center, "Ловушка установлена!")

			set_member(pItem, m_Weapon_iWeaponState, ABILITY_READY);
			ExecuteHamB(Ham_Item_PreFrame, id);

			create_trap(id);

			new iTraps = get_entvar(pItem, var_traps) - 1;
			set_entvar(pItem, var_traps, iTraps);
			AMMOX(id, 15, iTraps);
		}
	}
}

public HM_Knife_Holster_Post(pItem)
{
	new id = get_member(pItem, m_pPlayer);

	if(!IsSetBit(g_iBitUserClass, id) || get_member(pItem, m_Weapon_iWeaponState) != ABILITY_THINK) return;

	//Убираем режим установки ловушки
	disable_ability_think(id, pItem);
}

stock disable_class(id, bool:bDisableTraps = true)
{
	if(!IsSetBit(g_iBitUserClass, id)) 
		return;
	
	ClearBit(g_iBitUserClass, id);
	
	if(bDisableTraps)
	{
		new iTrap = NULLENT;
		while((iTrap = fm_find_ent_by_owner(iTrap, g_szClassName_Trap, id)) > 0)
			rg_remove_ent(iTrap);
	}

	//Убираем режим установки ловушки
	new pItem = get_member(id, m_rgpPlayerItems, SLOT_KNIFE);

	if(!is_nullent(pItem) && get_member(pItem, m_Weapon_iWeaponState) == ABILITY_THINK)
		disable_ability_think(id, pItem);

	//Убираем weaponlist
	new pActiveItem = get_member(id, m_pActiveItem);

	if(!is_nullent(pActiveItem) && get_member(pActiveItem, m_iId) == CSW_KNIFE)
		UTIL_SetWeaponList(id, "weapon_knife", -1, -1, -1, -1, 2, 1, 29, 0);
}	


//Выдача ловучек
stock bool:heavy_trap_add(id, iAdd)
{
	if(!is_user_alive(id) || !IsSetBit(g_iBitUserClass, id)) return false;

	new pItem = get_member(id, m_rgpPlayerItems, SLOT_KNIFE);

	if(is_nullent(pItem)) return false;

	new iTraps = min(HEAVY_MAXTRAPS, get_entvar(pItem, var_traps) + iAdd)

	set_entvar(pItem, var_traps, iTraps);
	
	new pActiveItem = get_member(id, m_pActiveItem);

	if(!is_nullent(pActiveItem) && get_member(pActiveItem, m_iId) == CSW_KNIFE)
		AMMOX(id, 15, iTraps);

	return true;
}


//Проверка на застрял ли игрок в ловушке
// true - застрял
// flase - не застрял
public zp_is_user_trapped(id)
	return !is_nullent(g_iEntTrapped[id]);

stock disable_ability_think(id, pItem)
{
	set_member(pItem, m_Weapon_iWeaponState, ABILITY_READY);
	rg_send_bartime(id, 0);
	ExecuteHamB(Ham_Item_PreFrame, id);
}

stock create_trap(id)
{
	new iEnt = rg_create_entity("info_target");

	if(is_nullent(iEnt)) return NULLENT;

	set_entvar(iEnt, var_solid, SOLID_TRIGGER);

	new iFlags = get_entvar(id, var_flags), 
	Float:vecPlayer[3]; get_entvar(id, var_origin, vecPlayer);

	new Float:vecTrap[3]; xs_vec_copy(vecPlayer, vecTrap);
	vecTrap[2] -= iFlags & FL_DUCKING ? 14.0 : 32.0;

	engfunc(EngFunc_SetModel, iEnt, g_szModelTrap);
	engfunc(EngFunc_SetSize, iEnt, g_vecTrapMins, g_vecTrapMaxs);
	engfunc(EngFunc_SetOrigin, iEnt, vecTrap);

	set_entvar(iEnt, var_classname, g_szClassName_Trap);
	set_entvar(iEnt, var_impulse, IMPULSE_TRAP);

	new Float:vecAngles[3]; get_entvar(id, var_v_angle, vecAngles);
	vecAngles[0] = 0.0;
	vecAngles[2] = 0.0;

	set_entvar(iEnt, var_angles, vecAngles);

	//Координаты для человека, который застрянет в ловушке
	//new Float:vecTrapped[3]; xs_vec_copy(vecPlayer, vecTrapped);
	//if(iFlags & FL_DUCKING) vecTrapped[2] += 8.0;
	set_entvar(iEnt, var_oldorigin, vecPlayer);
	
	set_entvar(iEnt, var_owner, id);
	set_entvar(iEnt, var_effects, EF_OWNER_VISIBILITY);
	fm_set_rendering(iEnt, .render = kRenderTransAlpha, .amount = 100);

	SetTouch(iEnt, "RG_Touch_Trap");

	rh_emit_sound2(iEnt, 0, CHAN_AUTO, g_szSoundTrap);

	return iEnt;
}

public RG_Touch_Trap(iEnt, iToucher)
{
	if(IsSetBit(g_iBitUserClass, iToucher))
	{
		new pItem = get_member(iToucher, m_rgpPlayerItems, SLOT_KNIFE);

		if(is_nullent(pItem))
			return;

		if(get_member(pItem, m_Weapon_iWeaponState) == ABILITY_THINK)
		{
			client_print(iToucher, print_center, "Нельзя ставить ловушки близко!");
			disable_ability_think(iToucher, pItem);
		}

		new Float:flGameTime = get_gametime();

		if(Float:get_entvar(pItem, var_touch_block) <= flGameTime)
			set_entvar(pItem, var_touch_block, flGameTime + 0.5);

		return;
	}

	//Детектим человека и устанавливаем его в ловушку
	if(get_entvar(iEnt, var_trapped) || 
		!is_user_alive(iToucher) || zp_get_user_zombie(iToucher) ||
		~get_entvar(iToucher, var_flags) & FL_ONGROUND)
		return;

	set_user_trapped(iToucher, iEnt);
}

stock set_user_trapped(id, iEnt)
{
	if(!is_nullent(g_iEntTrapped[id]))
		return;

	g_iEntTrapped[id] = iEnt;

	set_entvar(id, var_velocity, Float:{0.0, 0.0, 0.0});
	ExecuteHamB(Ham_Item_PreFrame, id);
	
	new Float:vecOrigin[3]; get_entvar(id, var_origin, vecOrigin);
	vecOrigin[2] -= get_entvar(id, var_flags) & FL_DUCKING ? 14.0 : 32.0;
	engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);

	fm_set_rendering(iEnt, .render = kRenderNormal, .amount = 0);

	client_print(id, print_center, "Вы попались в ловушку!");

	new szName[32]; get_user_name(id, szName, charsmax(szName));
	client_print(get_entvar(iEnt, var_owner), print_center, "%s попался в ловушку!", szName);

	if(zp_get_user_survivor(id) || !zp_is_user_girl_model(id))
		rh_emit_sound2(iEnt, 0, CHAN_AUTO, g_szSoundTrapped)
	else
		rh_emit_sound2(iEnt, 0, CHAN_AUTO, g_szSoundTrappedGirl)
		

	set_entvar(iEnt, var_trapped, id);

	//Убираем владельца ловушки, чтобы при его дисконнекте не исчезала ловушка
	set_entvar(iEnt, var_owner, 0);
	//Делаем ловушку видимой для всех и сетаем анимацию
	set_entvar(iEnt, var_effects, get_entvar(iEnt, var_effects) & ~EF_OWNER_VISIBILITY);
	UTIL_SetEntityAnim(iEnt, 1);

	SetThink(iEnt, "RG_Think_Trap");

	set_entvar(iEnt, var_nextthink, get_gametime() + HEAVY_TRAPBLOCK);
}

public RG_Think_Trap(iEnt)
	disable_trap(get_entvar(iEnt, var_trapped));


stock disable_trap(id)
{
	if(is_nullent(g_iEntTrapped[id]))
		return;

	rg_remove_ent(g_iEntTrapped[id]);

	g_iEntTrapped[id] = NULLENT;

	ExecuteHamB(Ham_Item_PreFrame, id);
}

stock rg_remove_ent(iEnt)
{
	set_entvar(iEnt, var_flags, FL_KILLME);
	set_entvar(iEnt, var_nextthink, get_gametime());
}

stock UTIL_SetEntityAnim(const pEntity, const iSequence = 0)
{
	set_entvar(pEntity, var_frame, 0.0);
	set_entvar(pEntity, var_framerate, 1.0);
	set_entvar(pEntity, var_animtime, get_gametime());
	set_entvar(pEntity, var_sequence, iSequence);
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