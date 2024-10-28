#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>
#include <zombieplague>
#include <zpe_lvl>

/*
	* Запретить ножи (необходимо для пилы)
	*
	* id 				- идентификатор игрока
	* iValue			- 1 запрещает ножи, 0 разрешает
	*
	* Ничего не возвращает
	* 
native zp_block_user_knife(id, iValue);

	* Регистрация ножа

	* szName 			- Название ножа
	* 
	* Возвращает номер ножа в случае, если в ini-файле
	* нашлось одинаковое название.
	* В противном случае функция вернёт -1.

native zp_register_knife(const szName[]);

	* Forward выбора ножа
	
	* id 				- идентификатор игрока
	* iKnife 			- идентификатор выбранного ножа
	* iOldKnife 		- идентификатор предыдущего ножа
	* 
	* Вызывается когда игрок меняет нож

forward zp_knife_selected(id, iKnife, iOldKnife);
*/

new g_szKnivesFile[] = "addons/amxmodx/configs/zpe_mode/addon_knives.ini" // Файл конфигурации

#define KNIFE_DEFAULT 0 // Номер ножа по умолчанию

#define MsgId_SayText 76

#define PLAYERS_PER_PAGE 7

new Array:g_asName, Array:g_asDescription, Array:g_asModel_V, Array:g_asModel_P, 
	Array:g_aaSndDeploy, Array:g_aaSndHit, Array:g_aaSndHitWall, Array:g_aaSndSlash, 
	Array:g_aaSndStab, Array:g_afJump, Array:g_afDamage, Array:g_afKnockback, Array:g_aiFlag, Array:g_aiLvl;

new g_iUserKnife[33], g_iUserBlock[33], g_iMenuPosition[33];

new g_fwKnifeSelected;

public plugin_precache()
{
	g_asName = ArrayCreate(64);
	g_asDescription = ArrayCreate(256);
	g_asModel_V = ArrayCreate(128);
	g_asModel_P = ArrayCreate(128);
	g_aaSndDeploy = ArrayCreate();
	g_aaSndHit = ArrayCreate();
	g_aaSndHitWall = ArrayCreate();
	g_aaSndSlash = ArrayCreate();
	g_aaSndStab = ArrayCreate();
	g_afJump = ArrayCreate();
	g_afDamage = ArrayCreate();
	g_afKnockback = ArrayCreate();
	g_aiFlag = ArrayCreate();
	g_aiLvl = ArrayCreate();

	load_knives();
}

public plugin_init()
{
	register_plugin("[ZPE] Addon: Knives", "1.0", "Docaner");

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "HM_KnifeDeploy_Post", true);
	
	//Юзаю hamsandwich, потому что в reapi прибавляется неверное количество денег в HUD
	//Предположение: плагин выдачи денег выдаёт деньги посредством hamsandwich 
	RegisterHam(Ham_TakeDamage, "player", "Ham_PlayerTakeDamage_Pre", false);
	
	RegisterHam(Ham_Spawn, "player", "HM_PlayerSpawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "CBasePlayer_TakeDamage_Post", true);
	RegisterHookChain(RG_CBasePlayer_Jump, "CBasePlayer_Jump_Post", true);

	register_forward(FM_EmitSound, "fw_EmitSound_Pre", false);

	register_clcmd("zpe_knifemenu", "CMD_KnifesMenu");

	register_menucmd(register_menuid("Show_KnivesMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_KnivesMenu");	

	g_fwKnifeSelected = CreateMultiForward("zp_knife_selected", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
}

public plugin_end()
{
	ArrayDestroy(g_asName);
	ArrayDestroy(g_asDescription);
	ArrayDestroy(g_asModel_V);
	ArrayDestroy(g_asModel_P);

	new Array:a
	for(new i; i < ArraySize(g_aaSndDeploy); i++)
	{
		a = Array:ArrayGetCell(g_aaSndDeploy, i);
		ArrayDestroy(a);
	}
	ArrayDestroy(g_aaSndDeploy);

	for(new i; i < ArraySize(g_aaSndHit); i++)
	{
		a = Array:ArrayGetCell(g_aaSndHit, i);
		ArrayDestroy(a);
	}
	ArrayDestroy(g_aaSndHit);

	for(new i; i < ArraySize(g_aaSndHitWall); i++)
	{
		a = Array:ArrayGetCell(g_aaSndHitWall, i);
		ArrayDestroy(a);
	}
	ArrayDestroy(g_aaSndHitWall);

	for(new i; i < ArraySize(g_aaSndSlash); i++)
	{
		a = Array:ArrayGetCell(g_aaSndSlash, i);
		ArrayDestroy(a);
	}
	ArrayDestroy(g_aaSndSlash);

	for(new i; i < ArraySize(g_aaSndStab); i++)
	{
		a = Array:ArrayGetCell(g_aaSndStab, i);
		ArrayDestroy(a);
	}
	ArrayDestroy(g_aaSndStab);

	ArrayDestroy(g_afJump);
	ArrayDestroy(g_afDamage);
	ArrayDestroy(g_afKnockback);
	ArrayDestroy(g_aiFlag);
	ArrayDestroy(g_aiLvl);
}

public plugin_natives()
{
	register_native("zp_register_knife", "zp_register_knife", 1);
	register_native("zp_block_user_knife", "zp_block_user_knife", 1);
	register_native("ZPE_GetUserKnife", "ZPE_GetUserKnife", 1);
	register_native("ZPE_SetUserKnife", "ZPE_SetUserKnife", 1);
}

public client_putinserver(id)
{
	ZPE_SetUserKnife(id, KNIFE_DEFAULT);
}

public client_connect(id)
{
	ZPE_SetUserKnife(id, KNIFE_DEFAULT);
}

public zp_user_humanized_post(id, survivor)
{
	deploy_if_knife(id)
}

public HM_KnifeDeploy_Post(iEnt)
{
	new id = get_member(iEnt, m_pPlayer);

	if(zp_get_user_zombie(id) || zp_get_user_block_knife(id)) return;

	new szModel_V[128], szModel_P[128];

	ArrayGetString(g_asModel_V, g_iUserKnife[id], szModel_V, charsmax(szModel_V));
	ArrayGetString(g_asModel_P, g_iUserKnife[id], szModel_P, charsmax(szModel_P));

	if(!equal(szModel_V, "")) set_entvar(id, var_viewmodel, szModel_V);
	if(!equal(szModel_P, "")) set_entvar(id, var_weaponmodel, szModel_P);
}

public HM_PlayerSpawn_Post(id)
{
	if(!is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_block_knife(id))
		return;

	new pActiveItem = get_member(id, m_pActiveItem);

	if(!is_entity(pActiveItem) || get_member(pActiveItem, m_iId) != CSW_KNIFE)
		return;

	new szModel_V[128], szModel_P[128];

	ArrayGetString(g_asModel_V, g_iUserKnife[id], szModel_V, charsmax(szModel_V));
	ArrayGetString(g_asModel_P, g_iUserKnife[id], szModel_P, charsmax(szModel_P));

	if(!equal(szModel_V, "")) set_entvar(id, var_viewmodel, szModel_V); 
	if(!equal(szModel_P, "")) set_entvar(id, var_weaponmodel, szModel_P);
}

public Ham_PlayerTakeDamage_Pre(pVictim, pInflictor, pAttacker, Float:flDamage, pBits)
{
	if(!is_user_connected(pAttacker) || zp_get_user_block_knife(pAttacker) || pVictim == pAttacker || zp_get_user_zombie(pAttacker) ||
		~pBits & (DMG_BULLET|DMG_NEVERGIB) || pBits & DMG_GRENADE || get_user_weapon(pAttacker) != CSW_KNIFE || pInflictor != pAttacker)
		return HAM_IGNORED;

	new Float:fPerCent = Float:ArrayGetCell(g_afDamage, g_iUserKnife[pAttacker]);

	if(fPerCent) SetHamParamFloat(4, flDamage * fPerCent);

	return HAM_IGNORED;
}

public CBasePlayer_TakeDamage_Post(pVictim, pInflictor, pAttacker, Float:flDamage, pBits)
{
	if(!is_user_connected(pAttacker) || zp_get_user_block_knife(pAttacker) || pVictim == pAttacker || zp_get_user_zombie(pAttacker) ||
		~pBits & (DMG_BULLET|DMG_NEVERGIB) || pBits & DMG_GRENADE || get_user_weapon(pAttacker) != CSW_KNIFE || pInflictor != pAttacker)
		return HC_CONTINUE;

	new Float:fKnock = Float:ArrayGetCell(g_afKnockback, g_iUserKnife[pAttacker]);

	if(!fKnock) return HC_CONTINUE;

	new Float:fOriginVic[3]; get_entvar(pVictim, var_origin, fOriginVic);	
	new Float:fOriginAtt[3]; get_entvar(pAttacker, var_origin, fOriginAtt);

	fKnock *= 3000.0 / get_distance_f(fOriginVic, fOriginAtt);

	new Float:vecVelocity[3]; get_entvar(pVictim, var_velocity, vecVelocity);
	//create_knockback_up(fOriginVic, fOriginAtt, fKnock, random_float(200.0, 275.0), vecVelocity);
	create_knockback_up(fOriginVic, fOriginAtt, fKnock, vecVelocity[2], vecVelocity);
	set_entvar(pVictim, var_velocity, vecVelocity);
	
	return HC_CONTINUE;	
}

public CBasePlayer_Jump_Post(id)
{
	if(zp_get_user_zombie(id) || zp_get_user_block_knife(id) || get_user_weapon(id) != CSW_KNIFE || 
		~get_entvar(id, var_flags) & FL_ONGROUND || 
		~get_member(id, m_afButtonPressed) & IN_JUMP)
		return HC_CONTINUE;

	new Float:fAddJump = Float:ArrayGetCell(g_afJump, g_iUserKnife[id]);

	if(!fAddJump) return HC_CONTINUE;

	new Float:vecVelocity[3];
	get_entvar(id, var_velocity, vecVelocity);
	vecVelocity[2] += fAddJump
	set_entvar(id, var_velocity, vecVelocity);

	return HC_CONTINUE;
}

public fw_EmitSound_Pre(id, iChannel, szSample[], Float:fVolume, Float:fAttn, iFlag, iPitch)
{
	if(!is_user_connected(id) || zp_get_user_zombie(id) || zp_get_user_block_knife(id) || contain(szSample[8], "knife"))
		return FMRES_IGNORED;

	new szNewSound[128];


	if(!contain(szSample[14], "deploy")) 
		get_random_sound(id, g_aaSndDeploy, szNewSound, charsmax(szNewSound));
	else if(!contain(szSample[14], "hitwall"))
		get_random_sound(id, g_aaSndHitWall, szNewSound, charsmax(szNewSound));
	else if(!contain(szSample[14], "hit"))
		get_random_sound(id, g_aaSndHit, szNewSound, charsmax(szNewSound));
	else if(!contain(szSample[14], "slash"))
		get_random_sound(id, g_aaSndSlash, szNewSound, charsmax(szNewSound));
	else if(!contain(szSample[14], "stab"))
		get_random_sound(id, g_aaSndStab, szNewSound, charsmax(szNewSound));

	if(equal(szNewSound, "")) return FMRES_IGNORED;

	emit_sound(id, iChannel, szNewSound, 1.0, fAttn, iFlag, iPitch);
	return FMRES_SUPERCEDE;
}


public CMD_KnifesMenu(id) return Show_KnivesMenu(id, g_iMenuPosition[id] = 0)
Show_KnivesMenu(id, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;

	if(!ArraySize(g_asName))
	{
		UTIL_SayText(id, "!g[ZP] !yНа сервере отсутствуют ножи")
		return PLUGIN_HANDLED
	}

	new iPagesNum = ArraySize(g_asName),
		szName[64], szDescription[256], iFlag, iLvl,
		szMenu[512], iKeys = (1<<2|1<<9), 
	iLen = formatex(szMenu, charsmax(szMenu), "\yВыберите нож \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	
	ArrayGetString(g_asName, iPos, szName, charsmax(szName));
	ArrayGetString(g_asDescription, iPos, szDescription, charsmax(szDescription));

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r>> \y%s \r<<^n^n", szName);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\w%s^n^n", szDescription);

	iFlag = ArrayGetCell(g_aiFlag, iPos);
	iLvl = ArrayGetCell(g_aiLvl, iPos);

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r3. %sВыбрать^n",
	 	(((!iFlag || get_user_flags(id) & iFlag) && g_iUserKnife[id] != iPos)) ? "\w" : "\d")
	
	if(!iFlag || get_user_flags(id) & iFlag)
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	else 
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r>> \wКупить: \ycsomod.ru^n");

	if(zpe_get_user_lvl(id) >= iLvl)
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	else 
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r>> \yТребуемый уровень - %d.^n", iLvl);

	if(iPos > 0)
	{
		iKeys |= (1<<7)
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r8. \wНазад^n")
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r8. \dНазад^n")
	if(iPos < iPagesNum - 1)
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9. \wДалее^n")
		iKeys |= (1<<8)
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r9. \dДалее^n")
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r0. \wВыход")
	return show_menu(id, iKeys, szMenu, -1, "Show_KnivesMenu")
}

public Handle_KnivesMenu(id, iKey)
{
	switch(iKey)
	{
		case 7: return Show_KnivesMenu(id, --g_iMenuPosition[id])
		case 8: return Show_KnivesMenu(id, ++g_iMenuPosition[id])
		case 9: return PLUGIN_HANDLED
		default:
		{
			new iTarget = g_iMenuPosition[id];

			new iFlag = ArrayGetCell(g_aiFlag, iTarget);

			new iLvl = ArrayGetCell(g_aiLvl, iTarget);

			if(iFlag && ~get_user_flags(id) & iFlag)
			{
				UTIL_SayText(id, "!g[ZP] !yУ вас нет доступа. Купить: !gCSOMOD.RU");
				return Show_KnivesMenu(id, g_iMenuPosition[id]);
			}

			if(iTarget == g_iUserKnife[id])
			{
				UTIL_SayText(id, "!g[ZP] !yДанный нож уже !gвыбран!y. Выберите другой.");
				return Show_KnivesMenu(id, g_iMenuPosition[id]);
			}

			if(zpe_get_user_lvl(id) < iLvl)
			{
				UTIL_SayText(id, "!g[ZP] !yУ Вас недостаточный !gуровень!y. Выберите другой.");
				return Show_KnivesMenu(id, g_iMenuPosition[id]);
			}

			ZPE_SetUserKnife(id, iTarget);

			return PLUGIN_HANDLED;
		}
	}
	return Show_KnivesMenu(id, g_iMenuPosition[id])
}

load_knives()
{
	if(!file_exists(g_szKnivesFile))
	{
		server_print( "[KNIVES] Файл ^"%s^" не был найден.", g_szKnivesFile)
		return 0;
	}

	new szBuffer[1024], szKey[64], iLine, iLen, iSize, iLvl,
		szName[64], szDescription[256], szModel_V[128], szModel_P[128],
		Array:aSndDeploy = ArrayCreate(128), Array:aSndHit = ArrayCreate(128),
		Array:aSndHitWall = ArrayCreate(128), Array:aSndSlash = ArrayCreate(128), Array:aSndStab = ArrayCreate(128),
		Float:fJump, Float:fDamage, Float:fKnockback, iFlag;

	while(read_file(g_szKnivesFile, iLine++, szBuffer, charsmax(szBuffer), iLen))
	{
		if(!iLen || szBuffer[0] == ';')
			continue;

		if(szBuffer[0] == '[' && iSize++)
		{
			Push_Knife(szName, szDescription, szModel_V, szModel_P, 
				aSndDeploy, aSndHit, aSndHitWall, aSndSlash, aSndStab,
				fJump, fDamage, fKnockback, iFlag, iLvl);

			szName = ""; szDescription = ""; szModel_V = ""; szModel_P = "";
			fJump = 0.0; fDamage = 0.0; fKnockback = 0.0;
			iFlag = 0; iLvl = 0;

			aSndDeploy = ArrayCreate(128); aSndHit = ArrayCreate(128); aSndHitWall = ArrayCreate(128);
			aSndSlash = ArrayCreate(128); aSndStab = ArrayCreate(128);

			continue;
		}

		strtok(szBuffer, szKey, charsmax(szKey), szBuffer, charsmax(szBuffer), '=');

		trim(szKey);
		trim(szBuffer);

		if(equal(szKey, "NAME"))
			copy(szName, charsmax(szName), szBuffer);
		else if(equal(szKey, "INFO"))
			copy(szDescription, charsmax(szDescription), szBuffer);
		else if(equal(szKey, "MODEL V"))
			copy(szModel_V, charsmax(szModel_V), szBuffer);
		else if(equal(szKey, "MODEL P"))
			copy(szModel_P, charsmax(szModel_P), szBuffer);
		else if(equal(szKey, "SND DEPLOY"))
			Array_PushStrings(aSndDeploy, szBuffer, charsmax(szBuffer))
		else if(equal(szKey, "SND HIT"))
			Array_PushStrings(aSndHit, szBuffer, charsmax(szBuffer))
		else if(equal(szKey, "SND HITWALL"))
			Array_PushStrings(aSndHitWall, szBuffer, charsmax(szBuffer))
		else if(equal(szKey, "SND SLASH"))
			Array_PushStrings(aSndSlash, szBuffer, charsmax(szBuffer))
		else if(equal(szKey, "SND STAB"))
			Array_PushStrings(aSndStab, szBuffer, charsmax(szBuffer))
		else if(equal(szKey, "JUMP"))
			fJump = str_to_float(szBuffer);
		else if(equal(szKey, "DMG"))
			fDamage = str_to_float(szBuffer);
		else if(equal(szKey, "KNOCKBACK"))
			fKnockback = str_to_float(szBuffer);
		else if(equal(szKey, "VIP FLAG"))
			iFlag = read_flags(szBuffer);
		else if(equal(szKey, "LVL"))
			iLvl = str_to_num(szBuffer);		
	}

	Push_Knife(szName, szDescription, szModel_V, szModel_P, 
		aSndDeploy, aSndHit, aSndHitWall, aSndSlash, aSndStab,
		fJump, fDamage, fKnockback, iFlag, iLvl);

	return 1;
}

Push_Knife(const szName[64], szDescription[256], const szModel_V[128], const szModel_P[128],
	Array:aSndDeploy, Array:aSndHit, Array:aSndHitWall, Array:aSndSlash, Array:aSndStab,
	const Float:fJump, const Float:fDamage, const Float:fKnockback, const iFlag, const iLvl)
{

	replace_all(szDescription, charsmax(szDescription), "\n", "^n");

	if(!equal(szModel_V, "")) precache_model(szModel_V);
	if(!equal(szModel_P, "")) precache_model(szModel_P);
	
	new i, szTmp[128];

	if(ArraySize(aSndDeploy))
		for(i = 0; i < ArraySize(aSndDeploy); i++)
		{
			ArrayGetString(aSndDeploy, i, szTmp, charsmax(szTmp));
			if(!equal(szTmp, "")) precache_sound(szTmp);
		}
	
	if(ArraySize(aSndHit))
		for(i = 0; i < ArraySize(aSndHit); i++)
		{
			ArrayGetString(aSndHit, i, szTmp, charsmax(szTmp));
			if(!equal(szTmp, "")) precache_sound(szTmp);
		}

	if(ArraySize(aSndHitWall))
		for(i = 0; i < ArraySize(aSndHitWall); i++)
		{
			ArrayGetString(aSndHitWall, i, szTmp, charsmax(szTmp));
			if(!equal(szTmp, "")) precache_sound(szTmp);
		}

	if(ArraySize(aSndSlash))
		for(i = 0; i < ArraySize(aSndSlash); i++)
		{
			ArrayGetString(aSndSlash, i, szTmp, charsmax(szTmp));
			if(!equal(szTmp, "")) precache_sound(szTmp);
		}

	if(ArraySize(aSndStab))
		for(i = 0; i < ArraySize(aSndStab); i++)
		{
			ArrayGetString(aSndStab, i, szTmp, charsmax(szTmp));
			if(!equal(szTmp, "")) precache_sound(szTmp);
		}

	ArrayPushString(g_asName, szName);
	ArrayPushString(g_asDescription, szDescription);
	ArrayPushString(g_asModel_V, szModel_V);
	ArrayPushString(g_asModel_P, szModel_P);
	ArrayPushCell(g_aaSndDeploy, cell:aSndDeploy);
	ArrayPushCell(g_aaSndHit, cell:aSndHit);
	ArrayPushCell(g_aaSndHitWall, cell:aSndHitWall);
	ArrayPushCell(g_aaSndSlash, cell:aSndSlash);
	ArrayPushCell(g_aaSndStab, cell:aSndStab);
	ArrayPushCell(g_afJump, cell:fJump);
	ArrayPushCell(g_afDamage, cell:fDamage);
	ArrayPushCell(g_afKnockback, cell:fKnockback);
	ArrayPushCell(g_aiFlag, iFlag);
	ArrayPushCell(g_aiLvl, iLvl);
}


bool:get_random_sound(id, Array:a, szPath[], iLen)
{
	new Array:aSounds = ArrayGetCell(a, g_iUserKnife[id]);
	if(!ArraySize(aSounds)) return false;
	ArrayGetString(aSounds, random_num(0, ArraySize(aSounds) - 1), szPath, iLen);
	return true;
}

Array_PushStrings(Array:a, szBuffer[], iLen)
{
	new szKey[128];
	while (szBuffer[0] != 0 && strtok(szBuffer, szKey, charsmax(szKey), szBuffer, iLen, ','))
	{
		trim(szKey)
		trim(szBuffer)
		
		ArrayPushString(a, szKey)
	}
}

stock create_knockback_up(const Float:vecVictim[3], const Float:vecAttacker[3], const Float:fKnockback, const Float:fKnockbackUp, Float:vecOut[3])
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
		xs_vec_mul_scalar(vecDiff, fKnockback, vecOut);
		vecOut[2] = fKnockbackUp;
	}
}

public zp_register_knife(const szName[])
{
	param_convert(1);
	return ArrayFindString(g_asName, szName);
}

public zp_block_user_knife(id, iValue)
{
	if(iValue)
	{
		new iDummyResault;
		ExecuteForward(g_fwKnifeSelected, iDummyResault, id, -1, g_iUserKnife[id]);
	}
	else
	{
		new iDummyResault;
		ExecuteForward(g_fwKnifeSelected, iDummyResault, id, g_iUserKnife[id], -1);
	}

	g_iUserBlock[id] = iValue;
	deploy_if_knife(id);
}

public zp_get_user_block_knife(id)
	return g_iUserBlock[id];

public ZPE_GetUserKnife(id)
	return g_iUserKnife[id];

public ZPE_SetUserKnife(id, iKnife)
{
	new iReturn = 1;

	if(iKnife < 0 || iKnife >= ArraySize(g_asName) || ~get_user_flags(id) & ArrayGetCell(g_aiFlag, iKnife))
	{
		iKnife = KNIFE_DEFAULT;
		iReturn = 0;
	}

	if(iKnife < 0 || iKnife >= ArraySize(g_asName) || ~zpe_get_user_lvl(id) >= ArrayGetCell(g_aiLvl, iKnife))
	{
		iKnife = KNIFE_DEFAULT;
		iReturn = 0;
	}

	if(g_iUserKnife[id] != iKnife)
	{
		new iOldKnife = g_iUserKnife[id];
		g_iUserKnife[id] = iKnife;

		if(zp_get_user_block_knife(id)) return iReturn;

		new iDummyResault;
		ExecuteForward(g_fwKnifeSelected, iDummyResault, id, iKnife, iOldKnife);
		
		deploy_if_knife(id);
	}

	return iReturn;
}

stock deploy_if_knife(const id)
{
	if(zp_get_user_zombie(id))
		return;

	new pActiveItem = get_member(id, m_pActiveItem);

	if(is_nullent(pActiveItem) || get_member(pActiveItem, m_iId) != CSW_KNIFE) 
		return;

	ExecuteHamB(Ham_Item_Deploy, pActiveItem);
}

stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190]
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3)
	else copy(szBuffer, charsmax(szBuffer), szMessage)
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	switch(pPlayer)
	{
		case 0:
		{
			for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++)
			{
				if(!is_user_connected(iPlayer)) continue
				message_begin(MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, iPlayer)
				write_byte(iPlayer)
				write_string(szBuffer)
				message_end()
			}
		}
		default:
		{
			message_begin(MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, pPlayer)
			write_byte(pPlayer)
			write_string(szBuffer)
			message_end()
		}
	}
}