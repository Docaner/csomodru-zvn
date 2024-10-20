#include <amxmodx>
#include <fakemeta_util>
#include <xs>
#include <reapi>
#include <zombieplague>


new const g_szFileBoxes[] = "addons/amxmodx/configs/zp_supplyboxes.ini"; // Параметры подарков
new g_szFilePos[128] = "addons/amxmodx/data/zpsb_positions/" // Папка с координатами подарков

#define BOX_TIMEINTERVAL 40.0  // Интервал времени, через который будут появляться подарки (В секундах)
//#define BOX_TIMEINTERVAL 5.0  // Интервал времени, через который будут появляться подарки (В секундах)
#define BOX_SPAWNCOUNT 2 // Количество появлений коробок за один промежуток времени
#define BOX_NEXTTHINK 1.0 // Интервалы вызовов think подарков для создания спрайта

new const Float:g_fMins[] = {-25.0, -25.0, -1.0}; // Минимальные координаты для бокса модели
new const Float:g_fMaxs[] = {25.0, 25.0, 15.0}; // Максимальные координаты для бокса модели

new const g_szSndSpawn[] = "sound/zp_br_cso/zpsb_spawn.wav";
new const g_szSndGet[] = "zp_br_cso/zpsb_get.wav";

new const g_szModelSprite[] = "sprites/zp_br_cso/supplybox3.spr"; // Спрайт 

#define SPRITE_VIEWDIST 1000.0 // При какой дистанции показывать спрайт
#define SPRITE_SCALE 0.35 // Масштаб спрайта
#define SPRITE_NEXTTHINK 0.02 // Интервалы вызовов think спрайтов для обновления позиции спрайта


#define TASK_BOXSPAWN 567456

#define VAR_BOXITEM 		var_iuser1
#define VAR_BOXIDPOS 		var_iuser2
#define VAR_BOXBITVIEW		var_iuser3
#define VAR_BOXCOPY			var_iuser4
#define VAR_BOXFLAGS		var_impulse
#define VAR_BOXVIEW			var_oldorigin

#define VAR_SPRATTACH		var_iuser1
#define VAR_SPRNEXTSCALE	var_fuser1
#define VAR_SPRTIMESCALE	var_ltime

//Переменные для подарков
new Array:g_asName, Array:g_aaExtraName, Array:g_aaExtraItem, Array:g_aiChance, 
	Array:g_asModel, Array:g_aiBody, Array:g_aiSequence, Array:g_aiFlags, Array:g_afSprHeight;

//Переменные для координат
new Array:g_aOrigin, Array:g_aEnt;
new bool:g_bPos = false;

//Главные переменные
new g_iBoxesSpawned, g_iMaxPlayers;


//Режим расстановки спавнов
new bool:g_bSpawns = false;

#define FLAG_A      (1<<0)  /* flag "a" */
#define FLAG_B   	(1<<1)  /* flag "b" */
#define FLAG_C      (1<<2)  /* flag "c" */
#define FLAG_D      (1<<3)  /* flag "d" */
#define FLAG_E      (1<<4)  /* flag "e" */
#define FLAG_F      (1<<5)  /* flag "f" */

#if !defined(zp_get_user_hero)
native zp_get_user_hero(id);
#endif

//Пила
native zpe_get_user_chainsaw(id);

//[Main forwards]...........

public plugin_precache()
{
	g_asName = ArrayCreate(32);
	g_aaExtraName = ArrayCreate();
	g_aiChance = ArrayCreate();
	g_aiFlags = ArrayCreate();
	g_afSprHeight = ArrayCreate();
	g_asModel = ArrayCreate(64);
	g_aiBody = ArrayCreate();
	g_aiSequence = ArrayCreate();

	load_boxes();

	precache_generic(g_szSndSpawn);
	precache_sound(g_szSndGet);

	precache_model(g_szModelSprite);
}

public plugin_init()
{
	register_plugin("[ZP] Re Supply Boxes", "2.2", "Docaner");
	register_clcmd("supply_box_menu", "Show_BoxMenu", ADMIN_CFG);
	register_menucmd(register_menuid("Show_BoxMenu"), 1023, "Handle_BoxMenu");

	g_iMaxPlayers = get_maxplayers();
}

public OnAutoConfigsBuffered()
{
	g_aOrigin = ArrayCreate(3);
	g_aEnt = ArrayCreate();

	new szMap[32];
	get_mapname(szMap, charsmax(szMap));
	add(g_szFilePos, charsmax(g_szFilePos), szMap);
	add(g_szFilePos, charsmax(g_szFilePos), ".ini");

	load_pos();
	load_extraitems();
}

public plugin_end()
	free_data();

create_spr(iOwner, iEntAttach)
{
	new iEnt = rg_create_entity("env_sprite");

	if(is_nullent(iEnt)) return NULLENT;

	//set_entvar(iEnt, var_classname, "sprite_box");
	set_entvar(iEnt, var_owner, iOwner);
	set_entvar(iEnt, var_solid, SOLID_NOT);
	set_entvar(iEnt, var_movetype, MOVETYPE_NOCLIP);
	set_entvar(iEnt, var_effects, EF_OWNER_VISIBILITY);

	set_entvar(iEnt, var_rendermode, kRenderTransAdd);
	set_entvar(iEnt, var_renderamt, 255.0);
	
	set_entvar(iEnt, VAR_SPRATTACH, iEntAttach);

	new Float:vecOriginBox[3]; get_entvar(iEntAttach, var_origin, vecOriginBox);
	new Float:vecOriginViewer[3]; get_entvar(iOwner, var_origin, vecOriginViewer);

	new Float:vecViewOfs[3]; get_entvar(iOwner, var_view_ofs, vecViewOfs);
	new Float:vecEyes[3]; xs_vec_add(vecOriginViewer, vecViewOfs, vecEyes);
	new Float:vecBoxVeiw[3]; get_entvar(iEntAttach, VAR_BOXVIEW, vecBoxVeiw);

	new Float:vecEnd[3], Float:flFraction; 
	get_origin_to_view_wall(iOwner, vecEyes, vecBoxVeiw, vecEnd, flFraction);	

	new Float:flScale = flFraction * SPRITE_SCALE
	new Float:flGameTime = get_gametime();

	set_entvar(iEnt, var_scale, flScale);
	set_entvar(iEnt, VAR_SPRNEXTSCALE, flScale);

	engfunc(EngFunc_SetModel, iEnt, g_szModelSprite);
	engfunc(EngFunc_SetOrigin, iEnt, vecEnd);

	SetThink(iEnt, "RG_Think_Spr");

	set_entvar(iEnt, var_nextthink, flGameTime + SPRITE_NEXTTHINK);


	return iEnt;
}

public RG_Think_Spr(iEnt)
{
	new iBox = get_entvar(iEnt, VAR_SPRATTACH);

	if(is_nullent(iBox))
	{
		rg_remove_ent(iEnt);
		return;
	} 

	new iBoxFlags = get_entvar(iBox, VAR_BOXFLAGS);
	new id = get_entvar(iEnt, var_owner);

	if(!is_user_alive(id) || get_user_block(id, iBoxFlags))
	{	
		remove_spr(iEnt, id, iBox);
		return; 
	}

	new Float:vecOriginBox[3]; get_entvar(iBox, var_origin, vecOriginBox);
	new Float:vecOriginViewer[3]; get_entvar(id, var_origin, vecOriginViewer);

	new Float:flDist = get_distance_f(vecOriginBox, vecOriginViewer);

	if(flDist > SPRITE_VIEWDIST)
	{	
		remove_spr(iEnt, id, iBox);
		return; 
	}

	new Float:vecOriginOldSpr[3]; get_entvar(iEnt, var_origin, vecOriginOldSpr);
	new Float:vecViewOfs[3]; get_entvar(id, var_view_ofs, vecViewOfs);
	
	new Float:vecEyes[3]; xs_vec_add(vecOriginViewer, vecViewOfs, vecEyes);
	new Float:vecBoxVeiw[3]; get_entvar(iBox, VAR_BOXVIEW, vecBoxVeiw);

	new Float:vecEnd[3], Float:flFraction; 
	get_origin_to_view_wall(id, vecEyes, vecBoxVeiw, vecEnd, flFraction);	

	new Float:flDistOldToNew = get_distance_f(vecOriginOldSpr, vecEnd), 
		Float:vecVelocity[3];

	if(flDistOldToNew > 50.0)
		get_velocity_to_origin(vecOriginOldSpr, vecEnd, flDistOldToNew * 5.0, vecVelocity);
	else if(flDistOldToNew > 5.0)
		get_velocity_to_origin(vecOriginOldSpr, vecEnd, 200.0, vecVelocity);
	else if(flDistOldToNew > 1.0)
		get_velocity_to_origin(vecOriginOldSpr, vecEnd, 10.0, vecVelocity);


	new Float:flGameTime = get_gametime();
	new Float:flTimeScale = Float:get_entvar(iEnt, VAR_SPRTIMESCALE);

	if(0.0 < flTimeScale <= flGameTime)
	{
		set_entvar(iEnt, var_scale, Float:get_entvar(iEnt, VAR_SPRNEXTSCALE));
		set_entvar(iEnt, VAR_SPRTIMESCALE, 0.0);
	}

	new Float:flNewScale = flFraction * SPRITE_SCALE;
	if(flNewScale != Float:get_entvar(iEnt, var_scale) && flTimeScale <= 0.0)
	{
		set_entvar(iEnt, VAR_SPRNEXTSCALE, flNewScale);
		set_entvar(iEnt, VAR_SPRTIMESCALE, flGameTime + 0.1);
	}

	set_entvar(iEnt, var_velocity, vecVelocity);

	set_entvar(iEnt, var_nextthink, flGameTime + SPRITE_NEXTTHINK);
}

stock get_velocity_to_origin(const Float:vecOriginStart[3], const Float:vecOriginEnd[3], const Float:flSpeed, Float:vecVelocity[3])
{
	xs_vec_sub(vecOriginEnd, vecOriginStart, vecVelocity);
	xs_vec_normalize(vecVelocity, vecVelocity);
	xs_vec_mul_scalar(vecVelocity, flSpeed, vecVelocity);
}

stock get_origin_to_view_wall(id, Float:vecOriginStart[3], Float:vecOriginEnd[3], Float:vecOriginWall[3], &Float:flFraction)
{
	new pTrace = create_tr2();

	engfunc(EngFunc_TraceLine, vecOriginStart, vecOriginEnd, IGNORE_MONSTERS, id, pTrace);
	
	get_tr2(pTrace, TR_flFraction, flFraction);

	if(flFraction != 1.0)
	{
		get_tr2(pTrace, TR_vecEndPos, vecOriginWall);
		
		new Float:vecNormal[3]; 
		xs_vec_sub(vecOriginEnd, vecOriginStart, vecNormal);
		xs_vec_normalize(vecNormal, vecNormal)

		xs_vec_mul_scalar(vecNormal, -5.0, vecNormal);
		xs_vec_add(vecOriginWall, vecNormal, vecOriginWall);
	}
	else vecOriginWall = vecOriginEnd;

	free_tr2(pTrace);
}

stock remove_spr(iSpr, iOwner, iBox)
{
	set_entvar(iBox, VAR_BOXBITVIEW, get_entvar(iBox, VAR_BOXBITVIEW) & ~(1<<iOwner));
	rg_remove_ent(iSpr);
}

//[Menus]

public Show_BoxMenu(id)
{
	new iKeys = (1<<0|1<<9), szMenu[512], iLen = formatex(szMenu, charsmax(szMenu), "\yМеню спавнов | Количество: \r%d^n^n", ArraySize(g_aEnt));

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r1. \w%s режим редактирования^n^n", g_bSpawns ? "Выключить" : "Включить");

	if(g_bSpawns)
	{
		iKeys |= (1<<1|1<<2|1<<3|1<<4|1<<5);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \wДобавить спавн^n^n");

		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \wУдалить предыдущий^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \wУдалить по прицелу^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5. \wУдалить все^n^n");

		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6. \wСохранить^n^n");
	}
	else
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r2. \dДобавить спавн^n^n");

		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. \dУдалить предыдущий^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r4. \dУдалить по прицелу^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r5. \dУдалить все^n^n");

		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r6. \dСохранить^n^n");
	}	

	formatex(szMenu[iLen], charsmax(szMenu), "\r0. \wВыход")

	return show_menu(id, iKeys, szMenu, _, "Show_BoxMenu");
}

public Handle_BoxMenu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			g_bSpawns = !g_bSpawns;

			if(g_bSpawns)
			{
				disable_presents();
				spawn_all_presents();
			}
			else
			{
				disable_presents();
				array_clear_pos();
				load_pos();
			}
		}

		case 1:
		{
			new Float:vecOrigin[3]; fm_get_aim_origin(id, vecOrigin);

			new iEnt = create_box(vecOrigin, ArraySize(g_aEnt), true);

			ArrayPushCell(g_aEnt, iEnt);
			ArrayPushArray(g_aOrigin, vecOrigin, sizeof vecOrigin);
		}

		case 2:
		{
			if(ArraySize(g_aEnt))
			{
				new iEnt = ArrayGetCell(g_aEnt, ArraySize(g_aEnt) - 1);

				if(!is_nullent(iEnt))
					remove_box(iEnt);

				ArrayDeleteItem(g_aEnt, ArraySize(g_aEnt) - 1)
				ArrayDeleteItem(g_aOrigin, ArraySize(g_aOrigin) - 1)
			}
		}

		case 3:
		{
			new iEnt; get_user_aiming(id, iEnt);

			if(!is_nullent(iEnt))
			{
				new iItem = ArrayFindValue(g_aEnt, iEnt);

				if(iItem != -1)
				{
					remove_box(iEnt);

					ArrayDeleteItem(g_aEnt, iItem)
					ArrayDeleteItem(g_aOrigin, iItem)
				}
			}
		}

		case 4:
		{
			new iEnt;
			for(new i; i < ArraySize(g_aEnt); i++)
			{
				iEnt = ArrayGetCell(g_aEnt, i);

				if(is_nullent(iEnt)) continue;

				remove_box(iEnt);
			}

			ArrayClear(g_aEnt);
			ArrayClear(g_aOrigin);
		}

		case 5:
			save_spawns();
		
		case 9:
			return PLUGIN_HANDLED;
	}

	return Show_BoxMenu(id);
}

//[ZP Forwards]................

public zp_round_started(gamemode, id)
{
	if(g_bSpawns || !g_bPos || !ArraySize(g_aaExtraItem)) return;

	//Включение таймера
	switch(gamemode)
	{
		case MODE_INFECTION, MODE_SWARM, MODE_MULTI, MODE_PLAGUE, MODE_NEMESIS:
			set_task(BOX_TIMEINTERVAL, "task_BoxSpawn", TASK_BOXSPAWN, _, _, "b");
	}
}

public zp_round_ended(winteam)
{
	if(g_bSpawns) return;

	disable_presents();
}

public task_BoxSpawn()
{
	client_cmd(0, "spk %s", g_szSndSpawn);
	
	for(new i = 1; i <= g_iMaxPlayers; i++)
	{
		if(!is_user_alive(i) || zp_get_user_zombie(i)) continue;
		client_print(i, print_center, "Подарки доставлены!");
	}
	
	//Выбор точки спавна случайным образом
	new Array:aForChoose = ArrayCreate(), iRandom, iChoosed;

	//Заносим индексы свободных точек спавна в aForChoose
	for(new i; i < ArraySize(g_aEnt); i++)
		if(ArrayGetCell(g_aEnt, i) == NULLENT)
			ArrayPushCell(aForChoose, i);

	new iSpawnLeft = min(BOX_SPAWNCOUNT, ArraySize(g_aEnt) - g_iBoxesSpawned);
	
	for(new i; i < iSpawnLeft; i++)
	{
		//Случайный выбор
		iChoosed = random(ArraySize(aForChoose))
		iRandom = ArrayGetCell(aForChoose, iChoosed);

		if(spawn_box(iRandom))
			ArrayDeleteItem(aForChoose, iChoosed);
	}

	//Освобождение памяти
	ArrayDestroy(aForChoose);

	//Удаляем таймер спавна коробор в случае, если все места заняты
	if(g_iBoxesSpawned == ArraySize(g_aEnt)) remove_task(TASK_BOXSPAWN);

	//client_print(0, print_chat, "Spawned: %d | Max: %d | Spawned: %d", g_iBoxesSpawned, ArraySize(g_aEnt), iSpawnLeft);
}

spawn_box(iRandom)
{
	new Float:vecOrigin[3]; ArrayGetArray(g_aOrigin, iRandom, vecOrigin, sizeof vecOrigin);

	new iEnt = create_box(vecOrigin, iRandom);
	
	if(iEnt != NULLENT)
	{
		ArraySetCell(g_aEnt, iRandom, iEnt);

		++g_iBoxesSpawned;

		return true;
	}

	return false
}

create_box(Float:vecOrigin[3], iSpawnPos, iRedactor = false)
{
	new iEnt = rg_create_entity("info_target");

	if(is_nullent(iEnt)) return NULLENT;

	//set_entvar(iEnt, var_classname, "pizdaebannaya");
	set_entvar(iEnt, var_solid, iRedactor ? SOLID_BBOX : SOLID_TRIGGER);
	set_entvar(iEnt, var_movetype, MOVETYPE_NONE);
	set_entvar(iEnt, var_nextthink, get_gametime());

	//Выбор случайного предмета
	new iAllChance;
	for(new i; i < ArraySize(g_aiChance); i++)
		iAllChance += ArrayGetCell(g_aiChance, i);

	new iRandomChance = random_num(0, iAllChance), iRandomItem = -1;

	for(new i; i < ArraySize(g_aiChance); i++)
	{
		iRandomChance -= ArrayGetCell(g_aiChance, i);
		if(iRandomChance > 0) continue;

		iRandomItem = i;
		break; 
	}

	new szModel[64]; ArrayGetString(g_asModel, iRandomItem, szModel, charsmax(szModel));

	engfunc(EngFunc_SetModel, iEnt, szModel);
	engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);
	engfunc(EngFunc_SetSize, iEnt, g_fMins, g_fMaxs);
	
	new iBody = ArrayGetCell(g_aiBody, iRandomItem)
	set_entvar(iEnt, var_body, iBody)

	new iAnim = ArrayGetCell(g_aiSequence, iRandomItem)
	UTIL_SetEntityAnim(iEnt, iAnim);

	set_entvar(iEnt, VAR_BOXITEM, iRandomItem);
	set_entvar(iEnt, VAR_BOXIDPOS, iSpawnPos);
	set_entvar(iEnt, VAR_BOXBITVIEW, 0);
	set_entvar(iEnt, VAR_BOXCOPY, create_box_copy(szModel, vecOrigin, iBody, iAnim))
	set_entvar(iEnt, VAR_BOXFLAGS, ArrayGetCell(g_aiFlags, iRandomItem));

	new Float:vecBoxVeiw[3]; xs_vec_copy(vecOrigin, vecBoxVeiw); 
	vecBoxVeiw[2] += Float:ArrayGetCell(g_afSprHeight, iRandomItem);
	set_entvar(iEnt, VAR_BOXVIEW, vecBoxVeiw);

	SetTouch(iEnt, "RG_Touch_Box");
	SetThink(iEnt, "RG_Think_Box");

	return iEnt;
}

create_box_copy(szModel[], Float:vecOrigin[3], iBody, iAnim)
{
	new iEnt = rg_create_entity("info_target");

	if(is_nullent(iEnt)) return NULLENT;

	engfunc(EngFunc_SetModel, iEnt, szModel);
	engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);
	engfunc(EngFunc_SetSize, iEnt, g_fMins, g_fMaxs);

	set_entvar(iEnt, var_body, iBody);
	UTIL_SetEntityAnim(iEnt, iAnim);

	fm_set_rendering(iEnt, .render=kRenderTransAdd, .amount=100)
	return iEnt;
}

public RG_Touch_Box(iBox, iPlayer)
{
	if(g_bSpawns)
		return;

	if(!is_user_alive(iPlayer) || get_user_block(iPlayer, get_entvar(iBox, VAR_BOXFLAGS)))
		return;

	//Выдача подарка игроку
	new iBoxItem = get_entvar(iBox, VAR_BOXITEM), Array:a = ArrayGetCell(g_aaExtraItem, iBoxItem);
	for(new i; i < ArraySize(a); i++)
		zp_force_buy_extra_item(iPlayer, ArrayGetCell(a, i), 1);

	//Удаление ent из массива координат
	ArraySetCell(g_aEnt, get_entvar(iBox, VAR_BOXIDPOS), NULLENT);

	//Восстанавливаем таймер спавна коробок
	--g_iBoxesSpawned;
	if(g_iBoxesSpawned == ArraySize(g_aEnt) - 1)
		set_task(BOX_TIMEINTERVAL, "task_BoxSpawn", TASK_BOXSPAWN, _, _, "b");

	//Вывод сообщения
	new szUserName[32]; get_user_name(iPlayer, szUserName, charsmax(szUserName));
	new szBoxName[32];	ArrayGetString(g_asName, iBoxItem, szBoxName, charsmax(szBoxName));

	for(new i = 1; i <= g_iMaxPlayers; i++)
	{
		if(!is_user_alive(i) || zp_get_user_zombie(i)) continue;
		client_print(i, print_center, "%s нашёл в подарке [%s]", szUserName, szBoxName);
	} 

	//Звук
	emit_sound(iBox, CHAN_AUTO, g_szSndGet, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	//Уничтожение ent
	remove_box(iBox);
}

stock remove_box(iBox)
{
	new iCopy = get_entvar(iBox, VAR_BOXCOPY);

	if(!is_nullent(iCopy))
		rg_remove_ent(iCopy);

	rg_remove_ent(iBox);
}

public RG_Think_Box(iEnt)
{
	new iBoxFlags = get_entvar(iEnt, VAR_BOXFLAGS);
	new iBitView = get_entvar(iEnt, VAR_BOXBITVIEW), iOldBitView = iBitView;

	new Float:vecOriginBox[3]; get_entvar(iEnt, var_origin, vecOriginBox);
	new Float:vecOriginPlayer[3];

	for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
	{
		if(!is_user_alive(iPlayer) || get_user_block(iPlayer, iBoxFlags) || iBitView & (1<<iPlayer)) continue;

		get_entvar(iPlayer, var_origin, vecOriginPlayer);

		if(get_distance_f(vecOriginBox, vecOriginPlayer) <= SPRITE_VIEWDIST)
		{
			create_spr(iPlayer, iEnt);
			iBitView |= (1<<iPlayer);
		}
	}

	if(iBitView != iOldBitView)
		set_entvar(iEnt, VAR_BOXBITVIEW, iBitView);

	set_entvar(iEnt, var_nextthink, get_gametime() + BOX_NEXTTHINK);
}


stock bool:get_user_block(id, iFlags)
{
	if(iFlags & FLAG_A && zp_get_user_zombie(id))
		return true;

	if(iFlags & FLAG_B && !zp_get_user_zombie(id))
		return true;

	if(iFlags & FLAG_C && zp_get_user_nemesis(id))
		return true;

	if(iFlags & FLAG_D && zp_get_user_survivor(id))
		return true;

	if(iFlags & FLAG_E && zp_get_user_hero(id))
		return true;

	if(iFlags & FLAG_F && zpe_get_user_chainsaw(id))
		return true;

	return false;
}

load_boxes()
{
	if(!file_exists(g_szFileBoxes))
	{
		server_print( "[RE SUPPLYBOXES] Файл ^"%s^" не был найден.", g_szFileBoxes)
		return 0;
	}

	new szBuffer[1024], szKey[64], iLine, iLen, iSize,
		szName[32], szModel[64],
		Array:aExtra = ArrayCreate(32),
		iChance, iFlags, iBody, iSequence, Float:flHeight;

	while(read_file(g_szFileBoxes, iLine++, szBuffer, charsmax(szBuffer), iLen))
	{
		if(!iLen || szBuffer[0] == ';')
			continue;

		if(szBuffer[0] == '[' && iSize++)
		{
			Push_Box(szName, aExtra, iChance, iFlags, szModel, iBody, iSequence, flHeight);

			szName = ""; aExtra = ArrayCreate(32); iChance = 0; iFlags = 0; 
			szModel = ""; iBody = 0; iSequence = 0; flHeight = 0.0;

			continue;
		}

		strtok(szBuffer, szKey, charsmax(szKey), szBuffer, charsmax(szBuffer), '=');

		trim(szKey);
		trim(szBuffer);

		if(equal(szKey, "NAME"))
			copy(szName, charsmax(szName), szBuffer);
		else if(equal(szKey, "EXTRAITEMS"))
			Array_PushExtra(aExtra, szBuffer, charsmax(szBuffer))
		else if(equal(szKey, "CHANCE"))
			iChance = str_to_num(szBuffer)
		else if(equal(szKey, "FLAGS"))
			iFlags = read_flags(szBuffer);
		else if(equal(szKey, "MODEL"))
			copy(szModel, charsmax(szModel), szBuffer);
		else if(equal(szKey, "BODY"))
			iBody = str_to_num(szBuffer)
		else if(equal(szKey, "SEQUENCE"))
			iSequence = str_to_num(szBuffer);
		else if(equal(szKey, "SPRHEIGHT"))
			flHeight = str_to_float(szBuffer);
	}

	if(iSize)
		Push_Box(szName, aExtra, iChance, iFlags, szModel, iBody, iSequence, flHeight);
	else
	{
		ArrayDestroy(aExtra);
		server_print( "[RE SUPPLYBOXES] Параметры подарков не были загружены");
		return 0;
	}

	return 1;
}

Push_Box(szName[], Array:aExtra, iChance, iFlags, szModel[], iBody, iSequence, Float:flHeight)
{
	ArrayPushString(g_asName, szName);
	ArrayPushCell(g_aaExtraName, aExtra);
	ArrayPushCell(g_aiChance, iChance);
	ArrayPushCell(g_aiFlags, iFlags)

	precache_model(szModel)
	ArrayPushString(g_asModel, szModel);

	ArrayPushCell(g_aiBody, iBody);
	ArrayPushCell(g_aiSequence, iSequence);
	ArrayPushCell(g_afSprHeight, flHeight)
}

Array_PushExtra(Array:a, szBuffer[], iLen)
{
	new szKey[32];
	while (szBuffer[0] != 0 && strtok(szBuffer, szKey, charsmax(szKey), szBuffer, iLen, ','))
	{
		trim(szKey)
		trim(szBuffer)
		
		//console_print(0, "szKey: [%s]", szKey);

		ArrayPushString(a, szKey)
	}
}

load_pos()
{
	if(!file_exists(g_szFilePos))
	{
		server_print("[RE SUPPLYBOXES] Файл ^"%s^" не найден.", g_szFilePos);
		g_bPos = false;
		return;
	}
	new szBuffer[128], iLine, iLen,
		Float:szOrigin[3], szNumbers[3][16];
	while(read_file(g_szFilePos, iLine++, szBuffer, charsmax(szBuffer), iLen))
	{
		if(!iLen || szBuffer[0] == ';') continue;

		parse(szBuffer, szNumbers[0], charsmax(szNumbers[]),  szNumbers[1], charsmax(szNumbers[]), szNumbers[2], charsmax(szNumbers[]));
		for(new i; i < sizeof szOrigin; i++)
			szOrigin[i] = str_to_float(szNumbers[i]);

		ArrayPushArray(g_aOrigin, szOrigin);
		ArrayPushCell(g_aEnt, NULLENT);
	}

	g_bPos = ArraySize(g_aEnt) ? true : false;
}

load_extraitems()
{
	g_aaExtraItem = ArrayCreate();

	new Array:a, Array:aExtraItem, j, szExtraName[32], iExtra
	for(new i; i < ArraySize(g_aaExtraName); i++)
	{
		a = ArrayGetCell(g_aaExtraName, i);
		
		aExtraItem = ArrayCreate();

		for(j = 0; j < ArraySize(a); j++)
		{
			ArrayGetString(a, j, szExtraName, charsmax(szExtraName));

			iExtra = zp_get_extra_item_id(szExtraName);

			//console_print(0, "[%s]", szExtraName);

			if(iExtra == -1)
			{
				server_print("[RE SUPPLYBOXES] Extra Item [%s] не найден.", szExtraName);
				continue;
			}

			ArrayPushCell(aExtraItem, iExtra);
		}
		
		//console_print(0, "[///]");

		ArrayDestroy(a);

		ArrayPushCell(g_aaExtraItem, aExtraItem);
	}

	ArrayDestroy(g_aaExtraName);
}

free_data()
{
	ArrayDestroy(g_asName);

	new Array:a;
	for(new i; i < ArraySize(g_aaExtraItem); i++)
	{
		a = ArrayGetCell(g_aaExtraItem, i);
		ArrayDestroy(a);
	}

	ArrayDestroy(g_aaExtraItem);
	ArrayDestroy(g_aiChance);
	ArrayDestroy(g_aiFlags);
	ArrayDestroy(g_asModel);
	ArrayDestroy(g_aiBody);
	ArrayDestroy(g_aiSequence);
	ArrayDestroy(g_afSprHeight);

	ArrayDestroy(g_aOrigin);
	ArrayDestroy(g_aEnt);
}

stock rg_remove_ent(iEnt) 
{
	set_entvar(iEnt, var_flags, FL_KILLME);
	set_entvar(iEnt, var_nextthink, get_gametime());
}


disable_presents()
{
	//Остановка таймера
	remove_task(TASK_BOXSPAWN);

	//Обнуление счётчика спавнов
	g_iBoxesSpawned = 0;

	//Обнуление массива Ents
	new iEnt;
	for(new i; i < ArraySize(g_aEnt); i++)
	{
		iEnt = ArrayGetCell(g_aEnt, i);
		
		if(iEnt == NULLENT) continue;

		remove_box(iEnt);
		ArraySetCell(g_aEnt, i, NULLENT);
	}
}

spawn_all_presents()
{
	new iEnt, Float:vecOrigin[3];
	for(new i; i < ArraySize(g_aEnt); i++)
	{
		iEnt = ArrayGetCell(g_aEnt, i);
		
		if(!is_nullent(iEnt)) continue;

		ArrayGetArray(g_aOrigin, i, vecOrigin, sizeof vecOrigin);
		iEnt = create_box(vecOrigin, i, true)

		ArraySetCell(g_aEnt, i, iEnt);
	}
}

array_clear_pos()
{
	ArrayClear(g_aEnt);
	ArrayClear(g_aOrigin);
}

save_spawns()
{
	if(file_exists(g_szFilePos))
		delete_file(g_szFilePos);

	new Float:vecOrigin[3], szString[32];
	for(new i; i < ArraySize(g_aOrigin); i++)
	{
		ArrayGetArray(g_aOrigin, i, vecOrigin, sizeof vecOrigin);
		formatex(szString, charsmax(szString), "%.2f %.2f %.2f", vecOrigin[0], vecOrigin[1], vecOrigin[2]);
		write_file(g_szFilePos, szString);
	}
}


stock UTIL_SetEntityAnim(const pEntity, const iSequence = 0)
{
	set_entvar(pEntity, var_frame, 1.0);
	set_entvar(pEntity, var_framerate, 1.0);
	//set_entvar(pEntity, var_animtime, get_gametime());
	set_entvar(pEntity, var_sequence, iSequence);
}