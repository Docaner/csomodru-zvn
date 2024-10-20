#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>
#include <reapi>
#include <zombieplague>


new const g_szClassName[] = {"ML_TESLA_NAME"};			// Название класса 
new const g_szClassInfo[] = {"ML_TESLA_INFO"};			// Описание класса
new const g_szClassModel[] = "zp_br_tesla_b10";					// Модель класса
new const g_szClassClawModel[] = "claws_tesla_b8.mdl";			// Модель рук класса
#define CLASS_HEALTH 2850								// Здоровье
#define CLASS_SPEED 230									// Скорость
#define CLASS_GRAVITY 0.87								// Гравитация
#define CLASS_KNOCKBACK 0.49							// Отбрасывание

#define BALL_LOADTIME 1 // На сколько нужно зажать [MOUSE2], чтобы активировать способность
#define BALL_RESTTIME 18.0 // Время перезагрузки способности
#define BALL_SPEED 1700.0 // Скорость шара
#define BALL_TOUCHES 16 // Максимальное количество касаний шара, после которых он взрывается
#define BALL_LIFETIME 7.0 // Максимальное время жизни шарика
#define BALL_FREEZETIME 5.0 // Время заморозки шариком
#define BALL_DMGARRMOR 40.0 // Сколько снимать брони при попадании шариком
#define BALL_DMGHEALTH 100.0 // Сколько снимать здоровья при попадании шариком
#define BALL_KNOCKBACK 200.0 // На сколько откидывать игрока при касании шариком
#define BALL_KNOCKBACKUP 100.0 // На сколько откидывать вверх при касании шариком
#define BALL_COUNTS 4 // Сколько выдавать шариков при возраждении
#define BALL_MAX 6 // Сколько максимум можно накопить шариков
#define BALL_ADD 1 // Сколько давать шариков при заражении / убийстве

new const g_szModelBall_P[] = "models/zp_br_cso/other/p_tesla_ball.mdl";
new const g_szModelBall_W[] = "models/zp_br_cso/other/w_tesla_ball.mdl";

new const g_szSndMakeBall[] = "weapons/electro4.wav";
new const g_szSndShootBall[] = "weapons/gauss2.wav";
new const g_szSndTouchBall[][] = {"weapons/ric_conc-1.wav", "weapons/ric_conc-2.wav"};
new const g_szSndHitBall[] = "player/pl_pain6.wav";

new const g_szWpnlistModel[] = "sprites/zp_br_cso/zombie/zmtimer2.txt" // Weaponlist таймер 
new const g_szWpnlistName[] = "zp_br_cso/zombie/zmtimer2" // Название weaponlist

new const g_szWpnlistModelBall[] = "sprites/zp_br_cso/zombie/ball2.txt" // Weaponlist шарика
new const g_szWpnlistNameBall[] = "zp_br_cso/zombie/ball2" // Название weaponlist
new const g_szWpnlistResBall[] = "sprites/zp_br_cso/zombie/640hud90b.spr" // Доп ресы

new const g_szSprFollow[] = "sprites/zbeam4.spr";
new const g_szSprCircle[] = "sprites/shockwave.spr";

#define rg_remove_ent(%0) set_entvar(%0, var_flags, get_entvar(%0, var_flags) | FL_KILLME)

native zp_is_user_frozen(id);

#define ANIM_SKILL_TIME 46.0/30.0

#define TASK_FREEZE 558228

#define MsgId_SayText 76

#define UNIT_SECOND (1<<12)

#if !defined zp_get_user_hero
native zp_get_user_hero(id)
#endif

enum
{
	ANIM_IDLE = 0,
	ANIM_SLASH1,
	ANIM_SKILL,
	ANIM_DRAW,
	ANIM_STAB,
	ANIM_STAB_MISS,
	ANIM_MIDSLASH1,
	ANIM_MIDSLASH2,
}

enum
{
	ABILITY_NO = 0,
	ABILITY_READY,
	ABILITY_SPAM,
	ABILITY_THINK,
	ABILITY_LOADED,
	ABILITY_RESTART,
}

new g_iClassTesla;

new g_iMsgID_AmmoX, g_iMsgID_CurWeapon, g_iMsgID_WeaponList;

new g_pSprZbeam4, g_pSprCircle;

new Float:g_fUserWait[33], g_iUserEntInHand[33], g_iUserAbilityTimes[33];

new g_bUserBallTouched[33], Float:g_fUserNextAttack[33];

public plugin_precache()
{
	g_iClassTesla = zp_register_zombie_class(g_szClassName, g_szClassInfo, g_szClassModel, 
		g_szClassClawModel, CLASS_HEALTH, CLASS_SPEED, CLASS_GRAVITY, CLASS_KNOCKBACK);

	precache_model(g_szModelBall_P)
	precache_model(g_szModelBall_W);

	g_pSprZbeam4 = precache_model(g_szSprFollow);
	g_pSprCircle = precache_model(g_szSprCircle);

	precache_sound(g_szSndMakeBall);
	precache_sound(g_szSndShootBall);

	for(new i; i <= charsmax(g_szSndTouchBall); i++)
		precache_sound(g_szSndTouchBall[i]);

	precache_sound(g_szSndHitBall);

	precache_generic(g_szWpnlistModel);
	register_clcmd(g_szWpnlistName, "Command_HookWeapon");

	precache_generic(g_szWpnlistModelBall);
	precache_generic(g_szWpnlistResBall);
	register_clcmd(g_szWpnlistNameBall, "Command_HookWeapon");
}

public plugin_init()
{
	register_plugin("Pizdatya Tesla", "1.0", "Docaner");

	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Jump, "CBasePlayer_Jump_Post", true);

	new const g_szWeaponName[][] = 
	{
		"weapon_knife", "weapon_p228", "weapon_scout", "weapon_hegrenade", "weapon_xm1014",
		"weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite",
		"weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas",
		"weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3",
		"weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
		"weapon_ak47", "weapon_p90"
	};

	//Блокировка аттаки
	for(new i; i < sizeof(g_szWeaponName); i++) 
		RegisterHam(Ham_Item_Deploy, g_szWeaponName[i], "HM_WeaponsDeploy_Post", true);


	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", true);

	RegisterHam(Ham_Item_Deploy, "weapon_knife", "HM_KnifeDeploy_Post", true);
	RegisterHam(Ham_Item_PreFrame, "weapon_knife", "HM_KnifePreFrame_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "HM_KnifePriAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "HM_KnifeSecAttack_Pre", false);
	RegisterHam(Ham_Item_Holster, "weapon_knife", "HM_KnifeHolster_Post", true);
	//Максимальная скорость выставляется через Ham_Item_PreFrame, потому что
	//в ZP скорость выставляется посредством hamsandwich.
	//Выставление скорости через RG_CBasePlayer_ResetMaxSpeed эффекта не даёт
	RegisterHam(Ham_Item_PreFrame, "player", "HM_PlayerPreFrame_Post", true);

	g_iMsgID_AmmoX = get_user_msgid("AmmoX");
	g_iMsgID_CurWeapon = get_user_msgid("CurWeapon");
	g_iMsgID_WeaponList = get_user_msgid("WeaponList");
	
	register_dictionary( "zp_cso_classes.txt" )
}

public Command_HookWeapon(id)
{
	engclient_cmd(id, "weapon_knife");
	return PLUGIN_HANDLED;
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	if(is_user_alive(id) && !zp_get_user_nemesis(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_iClassTesla)
		set_default_values(id);

	unfreeze_player(id);
}

public zp_user_humanized_pre(id, survivor)
{
	if(!zp_get_user_nemesis(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_iClassTesla)
		set_default_values(id);
}

public zp_user_infected_pre(id, infector, nemesis)
{
	unfreeze_player(id);
}

public zp_user_infected_post(id, infector, nemesis)
{
	if(zp_get_user_zombie_class(id) == g_iClassTesla)
	{
		if(nemesis)
			set_default_values(id);
		else
		{
			new iWeapon = rg_find_weapon_bpack_by_name(id, "weapon_knife");
			if(!is_nullent(iWeapon)) set_member(iWeapon, m_Weapon_iWeaponState, ABILITY_READY);
			
			g_iUserAbilityTimes[id] = BALL_COUNTS;

			UTIL_SetWeaponList(id, g_szWpnlistNameBall, 15, BALL_MAX, -1, -1, 2, 1, CSW_KNIFE, 0);
			AMMOX(id, 15, g_iUserAbilityTimes[id]);
			CURWEAPON(id, 1, CSW_KNIFE, -1);

			UTIL_SayText(id, "!g[ZOMBIE] !yСпособность !g[Энергетический шар]!y | Кнопки: !g[ЛКМ] + [ПКМ] !y(удерж.)")
			UTIL_SayText(id, "!g[ZOMBIE] !yВремя заморозки: !g%d сек. !y| Отсчёт: !g%d секунд!y", floatround(BALL_FREEZETIME), floatround(BALL_RESTTIME));
		}

	}
	
	if(is_user_alive(infector) && zp_get_user_zombie_class(infector) == g_iClassTesla && !zp_get_user_nemesis(infector) && !zp_is_survivor_round())
	{
		if(g_iUserAbilityTimes[infector] < BALL_MAX)
			set_user_ball(infector, g_iUserAbilityTimes[infector] + BALL_ADD);
	}
}

public zp_round_ended(winteam)
{
	for(new i = 1; i <= get_maxplayers(); i++)
	{
		if(!is_user_alive(i)) continue;

		unfreeze_player(i);

		if(!zp_get_user_nemesis(i) && zp_get_user_zombie(i) && zp_get_user_zombie_class(i) == g_iClassTesla)
			set_default_values(i);
	}

	new iEnt = -1;

	while((iEnt = rg_find_ent_by_class(iEnt, "energy_ball")))
		if(!is_nullent(iEnt))
			rg_remove_ent(iEnt);
}

//ReGameDLL===========>
public CBasePlayer_Killed_Pre(iVictim, iAttacker)
{
	if(is_user_alive(iAttacker) && zp_get_user_zombie(iAttacker) && zp_get_user_zombie_class(iAttacker) == g_iClassTesla && 
		!zp_get_user_nemesis(iAttacker) && !zp_is_survivor_round())
	{ 
		if(g_iUserAbilityTimes[iAttacker] < BALL_MAX)
			set_user_ball(iAttacker, g_iUserAbilityTimes[iAttacker] + BALL_ADD);
	}

	if(!zp_get_user_nemesis(iVictim) && zp_get_user_zombie(iVictim) && zp_get_user_zombie_class(iVictim) == g_iClassTesla)
		set_default_values(iVictim);

	unfreeze_player(iVictim);
}

public CBasePlayer_Jump_Post(id)
{
	if(!g_bUserBallTouched[id]) return HC_CONTINUE;

	new iOldButtons = get_entvar(id, var_oldbuttons);
	set_entvar(id, var_oldbuttons, iOldButtons | IN_JUMP);

	return HC_BREAK;
}
//ReGameDLL<===========
//Fakemeta============>
public fw_UpdateClientData_Post(id, SendWeapons, CD_Handle) 
{
	if(get_cd(CD_Handle, CD_DeadFlag) != DEAD_NO) 
		return;

	if(!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_nemesis(id) ||
		zp_get_user_zombie_class(id) != g_iClassTesla) 
		return;

	new pActiveItem = get_member(id, m_pActiveItem);

	if(is_nullent(pActiveItem) || get_member(pActiveItem, m_iId) != CSW_KNIFE)
		return;

	set_cd(CD_Handle, CD_flNextAttack, 99999.0);
}
//Fakemeta<============
//Hamsandwich=========>
public HM_KnifeDeploy_Post(iEnt)
{
	new id = get_member(iEnt, m_pPlayer);

	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) ||
		zp_get_user_zombie_class(id) != g_iClassTesla) return HAM_IGNORED;

	new iWeaponState = get_member(iEnt, m_Weapon_iWeaponState);
	switch(iWeaponState)
	{
		case ABILITY_RESTART: chek_user_ability_timer(id, iEnt, true);
		default:
		{
			UTIL_SetWeaponList(id, g_szWpnlistNameBall, 15, BALL_MAX, -1, -1, 2, 1, CSW_KNIFE, 0);
			CURWEAPON(id, 1, CSW_KNIFE, -1);
			AMMOX(id, 15, g_iUserAbilityTimes[id]);
		}
	}

	return HAM_IGNORED;
}

public HM_KnifePreFrame_Pre(iEnt)
{
	new id = get_member(iEnt, m_pPlayer);

	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) ||
		zp_get_user_zombie_class(id) != g_iClassTesla) 
		return HAM_IGNORED;

	new iWeaponState = get_member(iEnt, m_Weapon_iWeaponState);

	switch(iWeaponState)
	{
		case ABILITY_NO: {}
		case ABILITY_RESTART: chek_user_ability_timer(id, iEnt);
		default:
		{
			new iButton = get_entvar(id, var_button), iFrozen = zp_is_user_frozen(id);
			
			if(~iButton & (IN_ATTACK|IN_ATTACK2) || iFrozen)
			{
				if(iWeaponState == ABILITY_LOADED)
				{
					if(g_iUserEntInHand[id]) rg_remove_ent(g_iUserEntInHand[id]);
					g_iUserEntInHand[id] = 0;

					UTIL_PlayerAnimation(id, get_entvar(id, var_flags) & FL_DUCKING ? "crouch_aim_knife" : "ref_aim_knife");

				}

				if(iWeaponState == ABILITY_LOADED && iButton & IN_ATTACK2 && !iFrozen)
				{
					create_ball_in_world(id);

					AMMOX(id, 15, --g_iUserAbilityTimes[id]);

					g_fUserWait[id] = -1.0;
					iWeaponState = ABILITY_RESTART; set_member(iEnt, m_Weapon_iWeaponState, iWeaponState);
					
					emit_sound(id, CHAN_VOICE, g_szSndShootBall, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

					UTIL_WeaponAnimation(id, ANIM_SKILL);
					UTIL_PlayerAnimation(id, "zbs_skill_idle");

					set_member(id, m_flNextAttack, ANIM_SKILL_TIME);
					return HAM_IGNORED;
				}
				
				if(iWeaponState != ABILITY_READY)
				{
					rg_send_bartime(id, 0, false);
					set_member(iEnt, m_Weapon_iWeaponState, ABILITY_READY);
					
					client_print(id, print_center, "Отмена способности");
				}
			}
			else
			{
				static Float:fTime[33]; 

				if(iWeaponState == ABILITY_READY)
				{	
					iWeaponState = ABILITY_SPAM; set_member(iEnt, m_Weapon_iWeaponState, iWeaponState);
					fTime[id] = get_gametime() + 0.2;
				}

				if(iWeaponState == ABILITY_SPAM && fTime[id] <= get_gametime())
				{
					iWeaponState = ABILITY_THINK; set_member(iEnt, m_Weapon_iWeaponState, iWeaponState);
					fTime[id] = get_gametime() + float(BALL_LOADTIME);
					
					rg_send_bartime(id, BALL_LOADTIME, false);

					UTIL_WeaponAnimation(id, ANIM_SLASH1);
					emit_sound(id, CHAN_VOICE, g_szSndMakeBall, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
					
					client_print(id, print_center, "Подождите...");
				}

				if(iWeaponState == ABILITY_THINK && fTime[id] <= get_gametime())
				{
					iWeaponState = ABILITY_LOADED; set_member(iEnt, m_Weapon_iWeaponState, iWeaponState);
					g_iUserEntInHand[id] = create_ball_in_hand(id);

					client_print(id, print_center, "Отпустите клавишу ЛКМ (Левая кнопка мыши)");
				}

				if(iWeaponState == ABILITY_LOADED || iWeaponState == ABILITY_THINK)
				{
					new Float:fOrigin[3];
					get_entvar (id, var_origin, fOrigin);

					new Float:fPerCent = fTime[id] <= get_gametime() ? 
						1.0 : (float(BALL_LOADTIME) - (fTime[id] - get_gametime())) / float(BALL_LOADTIME);

					new Float:fResult = 15 * fPerCent

					CREATE_DLIGHT(fOrigin, floatround(fResult), 244, 102, 255, 2);
				}

				if(iWeaponState == ABILITY_LOADED)
				{
					UTIL_PlayerAnimation(id, get_entvar(id, var_flags) & FL_DUCKING ? "crouch_aim_grenade" : "ref_aim_grenade");
				}
			}
		}
	}

	return HAM_IGNORED;
}

public HM_KnifePriAttack_Pre(iEnt)
{
	new id = get_member(iEnt, m_pPlayer);

	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) ||
		zp_get_user_zombie_class(id) != g_iClassTesla) return HAM_IGNORED;

	new iWeaponState = get_member(iEnt, m_Weapon_iWeaponState);

	if(iWeaponState == ABILITY_LOADED || iWeaponState == ABILITY_THINK)
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public HM_KnifeSecAttack_Pre(iEnt)
{
	new id = get_member(iEnt, m_pPlayer);

	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) ||
		zp_get_user_zombie_class(id) != g_iClassTesla) return HAM_IGNORED;
	
	new iWeaponState = get_member(iEnt, m_Weapon_iWeaponState);

	if(iWeaponState == ABILITY_LOADED || iWeaponState == ABILITY_THINK)
		return HAM_SUPERCEDE;

	UTIL_WeaponAnimation(id, ANIM_STAB);

	return HAM_IGNORED;
}

public HM_KnifeHolster_Post(iEnt)
{
	new id = get_member(iEnt, m_pPlayer);

	if(!zp_get_user_zombie(id) || zp_get_user_nemesis(id) ||
		zp_get_user_zombie_class(id) != g_iClassTesla) return HAM_IGNORED;

	new iWeaponState = get_member(iEnt, m_Weapon_iWeaponState);

	switch(iWeaponState)
	{
		case ABILITY_THINK: 
		{
			set_member(iEnt, m_Weapon_iWeaponState, ABILITY_READY);
			rg_send_bartime(id, 0, false);
		}
		case ABILITY_LOADED: 
		{
			if(g_iUserEntInHand[id]) rg_remove_ent(g_iUserEntInHand[id]);
			g_iUserEntInHand[id] = 0;

			set_member(iEnt, m_Weapon_iWeaponState, ABILITY_READY); 
		}
	}

	if(g_fUserWait[id] == -1.0) g_fUserWait[id] = get_gametime() + BALL_RESTTIME;

	return HAM_IGNORED;
}

public HM_WeaponsDeploy_Post(iEnt)
{
	new id = get_member(iEnt, m_pPlayer);

	if(!g_bUserBallTouched[id]) return;

	set_member(id, m_flNextAttack, g_fUserNextAttack[id] - get_gametime());
	set_member(iEnt, m_Weapon_flNextPrimaryAttack, g_fUserNextAttack[id] - get_gametime());
	set_member(iEnt, m_Weapon_flNextSecondaryAttack, g_fUserNextAttack[id] - get_gametime());
}

public HM_PlayerPreFrame_Post(id)
	if(g_bUserBallTouched[id])
		set_entvar(id, var_maxspeed, 1.0);
//Hamsandwich<=========
//Other===============>
set_default_values(id)
{
	if(is_user_connected(id))
	{
		new iWeapon = rg_find_weapon_bpack_by_name(id, "weapon_knife");
		if(!is_nullent(iWeapon))
		{
			new iWeaponState = get_member(iWeapon, m_Weapon_iWeaponState);
			if(iWeaponState == ABILITY_THINK) rg_send_bartime(id, 0, false);
			set_member(iWeapon, m_Weapon_iWeaponState, ABILITY_NO);
		}
		UTIL_SetWeaponList(id, "weapon_knife", -1, -1, -1, -1, 2, 1, CSW_KNIFE, 0);
	}

	g_fUserWait[id] = 0.0;

	if(g_iUserEntInHand[id]) rg_remove_ent(g_iUserEntInHand[id]);
	g_iUserEntInHand[id] = 0;

	g_iUserAbilityTimes[id] = 0;
}


create_ball_in_hand(id)
{
	new iEnt = rg_create_entity("info_target");

	if(is_nullent(iEnt)) return NULLENT;

	set_entvar(iEnt, var_classname, "weapon_model");
	set_entvar(iEnt, var_movetype, MOVETYPE_FOLLOW);
	set_entvar(iEnt, var_aiment, id);
	set_entvar(iEnt, var_owner, id);
	
	engfunc(EngFunc_SetModel, iEnt, g_szModelBall_P);
	fm_set_rendering(iEnt, kRenderFxGlowShell, 224, 102, 255, kRenderNormal, 255);

	return iEnt;
}

create_ball_in_world(id)
{
	new iEnt = rg_create_entity("func_wall");

	if(is_nullent(iEnt)) return NULLENT;

	set_entvar(iEnt, var_classname, "energy_ball");
	set_entvar(iEnt, var_solid, SOLID_BBOX);
	set_entvar(iEnt, var_movetype, MOVETYPE_BOUNCEMISSILE);
	set_entvar(iEnt, var_owner, id);
	set_entvar(iEnt, var_sequence, 1);
	set_entvar(iEnt, var_dmgtime, get_gametime() + BALL_LIFETIME);


	new Float: vecOrigin[ 3 ]; get_entvar( id, var_origin, vecOrigin );
	new Float: vecViewOfs[ 3 ]; get_entvar( id, var_view_ofs, vecViewOfs );
	new Float: vecViewAngle[ 3 ]; get_entvar( id, var_v_angle, vecViewAngle );
	new Float: vecForward[ 3 ]; angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecForward );
	new Float: vecVelocity[ 3 ]; xs_vec_copy( vecForward, vecVelocity );
	
	//xs_vec_mul_scalar( vecForward, 45.0, vecForward );
	xs_vec_add( vecViewOfs, vecForward, vecViewOfs );
	xs_vec_add( vecOrigin, vecViewOfs, vecOrigin );


	xs_vec_mul_scalar(vecVelocity, BALL_SPEED, vecVelocity)
	set_entvar(iEnt, var_velocity, vecVelocity);

	engfunc(EngFunc_SetModel, iEnt, g_szModelBall_W);
	engfunc(EngFunc_SetSize, iEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
	engfunc(EngFunc_SetOrigin, iEnt, vecOrigin);

	fm_set_rendering(iEnt, kRenderFxGlowShell, 224, 102, 255, kRenderNormal, 200)
	CREATE_BEAMFOLLOW(iEnt, g_pSprZbeam4, 1, 10, 224, 102, 255, 200)

	set_entvar(iEnt, var_nextthink, get_gametime());

	SetTouch(iEnt, "RG_BallTouch");

	return iEnt;
}

public RG_BallTouch(iEntBall, iEntOther)
{
	new iTouches = get_entvar(iEntBall, var_iuser1) + 1;
	new Float:fLifeTime; get_entvar(iEntBall, var_dmgtime, fLifeTime)

	set_entvar(iEntBall, var_iuser1, iTouches);

	if(is_user_connected(iEntOther))
	{
		new Float:vecOriginAtt[3]; get_entvar(iEntBall, var_origin, vecOriginAtt);
		new Float:vecOriginVic[3]; get_entvar(iEntOther, var_origin, vecOriginVic);
		new Float:vecVelocity[3]; create_knockback_up(vecOriginVic, vecOriginAtt, BALL_KNOCKBACK, BALL_KNOCKBACKUP, vecVelocity)

		set_entvar(iEntOther, var_velocity, vecVelocity);

		CREATE_PARTICLEBURST(vecOriginAtt, 50, 70);
		emit_sound(iEntOther, CHAN_VOICE, g_szSndHitBall, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		if(!zp_get_user_zombie(iEntOther) && !zp_get_user_survivor(iEntOther) && !zp_get_user_hero(iEntOther) && !task_exists(iEntOther+TASK_FREEZE))
		{
			if(zp_zombie_take_damage(iEntOther, get_entvar(iEntBall, var_owner), BALL_DMGARRMOR, BALL_DMGHEALTH) && !zp_get_user_zombie(iEntOther))
			{
				g_fUserNextAttack[iEntOther] = get_gametime() + BALL_FREEZETIME;
				
				set_member(iEntOther, m_flNextAttack, BALL_FREEZETIME);
				
				new pActiveItem = get_member(iEntOther, m_pActiveItem);
				if(!is_nullent(pActiveItem))
				{
					set_member(pActiveItem, m_Weapon_flNextPrimaryAttack, BALL_FREEZETIME);
					set_member(pActiveItem, m_Weapon_flNextSecondaryAttack, BALL_FREEZETIME);
				}
				
				g_bUserBallTouched[iEntOther] = true;
				
				ExecuteHamB(Ham_Item_PreFrame, iEntOther);

				SCREEN_FADE(iEntOther, floatround(BALL_FREEZETIME), 0, SF_FADE_MODULATE, 224, 102, 255, 125);
				fm_set_rendering(iEntOther, kRenderFxGlowShell, 224, 102, 255, kRenderNormal, 1);
				
				set_task(BALL_FREEZETIME, "task_freeze_end", iEntOther+TASK_FREEZE);
			}

			rg_remove_ent(iEntBall);
			return;
		}
	}
	else 
		emit_sound(iEntBall, CHAN_VOICE, g_szSndTouchBall[random_num(0, charsmax(g_szSndTouchBall))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	
	if(iTouches >= BALL_TOUCHES || fLifeTime <= get_gametime())
	{
		new Float:vecOrigin[3]; get_entvar(iEntBall, var_origin, vecOrigin);
		
		CREATE_EXPLOSION2(vecOrigin);
		CREATE_BEAMCYLINDER(vecOrigin, 200, g_pSprCircle, _, _, 4, 30, _, 224, 102, 255, 200, 0);
		
		rg_remove_ent(iEntBall);
		return;
	}
}

public task_freeze_end(id)
{
	id -= TASK_FREEZE;
	unfreeze_player(id);
}

stock zp_zombie_take_damage(pVictim, pAttacker, Float:flDamageArmor, Float:flDamageHealth)
{
	new Float:flArmor = Float:get_entvar(pVictim, var_armorvalue)
	if(flArmor > 0.0)
	{
		flArmor = floatmax(0.0, flArmor - flDamageArmor);
		set_entvar(pVictim, var_armorvalue, flArmor);
		return 0;
	}
	
	new Float:flHealth = Float:get_entvar(pVictim, var_health);
	if(flDamageHealth < flHealth)
		ExecuteHam(Ham_TakeDamage, pVictim, pAttacker, pAttacker, flDamageHealth, (DMG_BULLET|DMG_NEVERGIB));
	else 
		ExecuteHamB(Ham_TakeDamage, pVictim, pAttacker, pAttacker, flDamageHealth, (DMG_BULLET|DMG_NEVERGIB));
	return 1;
}

unfreeze_player(id)
{
	if(!g_bUserBallTouched[id]) return;

	remove_task(id+TASK_FREEZE);
	SCREEN_FADE(id, 0, 0, SF_FADE_MODULATE, 0, 0, 0, 0);
	fm_set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	g_bUserBallTouched[id] = false;
	ExecuteHamB(Ham_Item_PreFrame, id);
}

set_user_ball(id, iCount)
{
	g_iUserAbilityTimes[id] = iCount;
			
	new iWeapon = rg_find_weapon_bpack_by_name(id, "weapon_knife");
	
	if(!is_nullent(iWeapon))
	{
		new iWeaponState = get_member(iWeapon, m_Weapon_iWeaponState);
		switch(iWeaponState)
		{
			case ABILITY_NO:
			{
				set_member(iWeapon, m_Weapon_iWeaponState, ABILITY_READY);
				if(get_member(iWeapon, m_iId) == CSW_KNIFE) 
					AMMOX(id, 15, g_iUserAbilityTimes[id]);
			}
			case ABILITY_RESTART: {}
			default:
			{
				if(get_member(iWeapon, m_iId) == CSW_KNIFE) 
					AMMOX(id, 15, g_iUserAbilityTimes[id]);
			}
		}
	}
}

chek_user_ability_timer(id, iWeapon, bool:bReloadWpnlist = false)
{
	new Float:flGameTime = get_gametime();

	if(g_fUserWait[id] == -1.0)
	{
		g_fUserWait[id] = get_gametime() + BALL_RESTTIME;

		UTIL_SetWeaponList(id, g_szWpnlistName, 15, floatround(BALL_RESTTIME, floatround_ceil), -1, -1, 2, 1, CSW_KNIFE, 0);
		CURWEAPON(id, 1, CSW_KNIFE, -1);
		AMMOX(id, 15, floatround(BALL_RESTTIME, floatround_ceil));
	}
	else if(flGameTime < g_fUserWait[id])
	{
		if(bReloadWpnlist)
		{
			UTIL_SetWeaponList(id, g_szWpnlistName, 15, floatround(BALL_RESTTIME, floatround_ceil), -1, -1, 2, 1, CSW_KNIFE, 0);
			CURWEAPON(id, 1, CSW_KNIFE, -1);
		}

		AMMOX(id, 15, floatround(g_fUserWait[id] - flGameTime, floatround_ceil));
	}
	else 
	{
		UTIL_SetWeaponList(id, g_szWpnlistNameBall, 15, BALL_MAX, -1, -1, 2, 1, CSW_KNIFE, 0);
		CURWEAPON(id, 1, CSW_KNIFE, -1);
		AMMOX(id, 15, g_iUserAbilityTimes[id]);

		if(g_iUserAbilityTimes[id])
			set_member(iWeapon, m_Weapon_iWeaponState, ABILITY_READY);
		else
			set_member(iWeapon, m_Weapon_iWeaponState, ABILITY_NO);
	}
}

//Other<===============
//Stocks==============>
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

stock CREATE_DLIGHT(Float:vecOrigin[3], radius, red, green, blue, life)
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_DLIGHT);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2]);
	write_byte(radius);
	write_byte(red); 
	write_byte(green);
	write_byte(blue);
	write_byte(life);
	write_byte(0);
	message_end();
}

stock UTIL_WeaponAnimation(pPlayer, iAnimation)
{
	set_entvar(pPlayer, var_weaponanim, iAnimation);
	
	message_begin_f(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, pPlayer)
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}

stock UTIL_SetWeaponList(iPlayer, const szWeaponName[], iPrimaryAmmoID, iPrimaryAmmoMaxAmount, iSecondaryAmmoID, iSecondaryAmmoMaxAmount, iSlotID, iNumberInSlot, iWeaponID, iFlags)
{
	message_begin(MSG_ONE, g_iMsgID_WeaponList, _, iPlayer);
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
	message_begin(MSG_ONE, g_iMsgID_AmmoX, _, id);
	write_byte(iAmmoId);
	write_byte(iAmount);
	message_end();
}

stock CURWEAPON(id, IsActive, iWeaponID, iClipAmmo)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE, g_iMsgID_CurWeapon, {0, 0, 0}, id);
	write_byte(IsActive);
	write_byte(iWeaponID);
	write_byte(iClipAmmo);
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

stock UTIL_PlayerAnimation(pPlayer, szAnimation[]) 
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

	new pActiveItem = get_member(pPlayer, m_pActiveItem);  
	if(!is_nullent(pActiveItem)) set_member(pActiveItem, m_Weapon_flLastFireTime, flGameTime);
}

stock CREATE_EXPLOSION2(Float:vecOrigin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION2) 
	engfunc(EngFunc_WriteCoord, vecOrigin[0]) 
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2]) 
	write_byte(0) // "start color" - has no effect
	write_byte(127) // "number of colors" - has no effect
	message_end()
}

stock CREATE_BEAMCYLINDER(Float:vecOrigin[3], iRadius, pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0)
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_BEAMCYLINDER);
	write_coord_f(vecOrigin[0])
	write_coord_f(vecOrigin[1])
	write_coord_f(vecOrigin[2])
	write_coord_f(vecOrigin[0])
	write_coord_f(vecOrigin[1])
	write_coord_f(vecOrigin[2] + iRadius)
	write_short(pSprite);
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

stock CREATE_LAVASPLASH(Float:fOrigin[3])
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin);
	write_byte(TE_LAVASPLASH);
	write_coord_f(fOrigin[0]);
	write_coord_f(fOrigin[1]);
	write_coord_f(fOrigin[2]);
	message_end();
}

stock CREATE_PARTICLEBURST(Float:vecPos[3], iRadius = 128, iColor = 250, iLife = 5)
{
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, vecPos, 0);
	write_byte(TE_PARTICLEBURST);
	write_coord_f(vecPos[0]);
	write_coord_f(vecPos[1]);
	write_coord_f(vecPos[2]);
	write_short(iRadius)
	write_byte(iColor);
	write_byte(iLife);
	message_end();
}

stock SCREEN_FADE(id, iDuration, iHoldtime, iFadeType, iRed, iGreen, iBlue, iAlpha)
{
	static iMsg_ScreenFade; if(!iMsg_ScreenFade) iMsg_ScreenFade = get_user_msgid("ScreenFade");

	message_begin(MSG_ONE_UNRELIABLE, iMsg_ScreenFade, _, id)
	write_short(UNIT_SECOND*iDuration) // duration
	write_short(UNIT_SECOND*iHoldtime) // hold time
	write_short(iFadeType) // fade type
	write_byte(iRed) // r
	write_byte(iGreen) // g
	write_byte(iBlue) // b
	write_byte(iAlpha) // alpha
	message_end()
}



/*Update_StatusIcon(id, iNum, iStatus)
{
	new szSprite[33]; formatex(szSprite, charsmax(szSprite), "number_%d", iNum);
	STATUS_ICON(id, iStatus, szSprite);
}


stock STATUS_ICON(id, iStatus = 0, szSprite[], iRed = 224, iGreen = 102, iBlue = 255) 
{
    message_begin(MSG_ONE, g_iMsgID_StatusIcon, {0, 0, 0}, id);
    write_byte(iStatus);
    write_string(szSprite); 
    write_byte(iRed);
    write_byte(iGreen); 
    write_byte(iBlue);
    message_end();
}*/

stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	switch(pPlayer)
	{
		case 0:
		{
			for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++)
			{
				if(!is_user_connected(iPlayer)) continue;
				engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, iPlayer);
				write_byte(iPlayer);
				write_string(szBuffer);
				message_end();
			}
		}
		default:
		{
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MsgId_SayText, {0.0, 0.0, 0.0}, pPlayer);
			write_byte(pPlayer);
			write_string(szBuffer);
			message_end();
		}
	}
}
//Stocks<==============