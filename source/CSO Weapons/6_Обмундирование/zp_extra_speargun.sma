#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>

#include <xs>
#include <engine>

#define ZP_SUPPORT // Чтобы отключить поддержку ZP 4.3+ , достаточно закоментировать макрос (//#define ZP_SUPPORT)

#if defined ZP_SUPPORT
	#include <zombieplague>
#endif

#define PLUGIN "[ZP] Weapon: Spear Gun"
#define VERSION "1.2.4"
#define AUTHOR "Base: Batcon; ReEdit: t3rkecorejz"

#define linux_diff_weapon 4
#define linux_diff_player 5

#define MAX_CLIENTS 32

#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_KEY)

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CBasePlayerItem
#define m_pPlayer 41
#define m_pNext 42
#define m_iId 43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flTimeWeaponIdle 48
#define m_iPrimaryAmmoType 49
#define m_iClip 51
#define m_fInReload 54
#define m_iWeaponState 74

// CBaseMonster
#define m_flNextAttack 83

// CBasePlayer
#define m_flPainShock 108
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376
#define m_szAnimExtention 492

#define ANIM_IDLE 0
#define ANIM_ATTACK 1
#define ANIM_RELOAD 2
#define ANIM_DRAW 3
#define ANIM_DRAW_EMPTY 4
#define ANIM_IDLE_EMPTY 5

// from model: Frames / FPS
#define ANIM_IDLE_TIME 1.7
#define ANIM_SHOOT_TIME 1.03
#define ANIM_RELOAD_TIME 1.84
#define ANIM_DRAW_TIME 1.44

#define SPEAR_CLASSNAME "spear" // класс нейм стрелы
#define SPEAR_SPEED	2000 // скорость стрелы
#define SPEAR_KNOCKBACK 100 // сила отталкивания от стрелы (при попадании)
#define SPEAR_KNOCKBACK_EXPLODE 225.0 // сила отталкивания от взрыва (только того, кто выстрелил оттолкнёт)
#define SPEAR_EXPLODE_RADIUS 100.0 // радиус от взрыва

#if defined ZP_SUPPORT
	#define SPEAR_DAMAGE 100.0 // урон от стрелы (ZP)
	#define SPEAR_DAMAGE_EXPLODE random_float(350.0, 500.0) // урон от взрыва (ZP)
#else
	#define SPEAR_DAMAGE 60.0 // урон от стрелы
	#define SPEAR_DAMAGE_EXPLODE random_float(35.0, 50.0) // урон от взрыва
#endif

#define WEAPON_KEY 2241
#define WEAPON_CSW CSW_M249
#define WEAPON_OLD "weapon_m249"
#define WEAPON_NEW "x/weapon_speargun"
#define WEAPON_HUD "sprites/x/640hud103.spr"
#define WEAPON_HUD_AMMO "sprites/x/640hud12.spr"

#define WEAPON_MODEL_V "models/x/v_speargun.mdl"
#define WEAPON_MODEL_P "models/x/p_speargun.mdl"
#define WEAPON_MODEL_W "models/x/w_speargun.mdl"
#define WEAPON_MODEL_SPEAR "models/x/s_spear.mdl"
#define WEAPON_MODEL_SPEAR2 "models/x/s_spear2.mdl"
#define WEAPON_SOUND_S "weapons/speargun-1.wav"
#define WEAPON_SOUND_HIT "weapons/speargun_stone1.wav"

#define WEAPON_BODY 0

#define WEAPON_CLIP 1
#define WEAPON_AMMO 30
#define WEAPON_RATE 0.8

new const iWeaponList[ ] = {
	3, 200,-1, -1, 0, 4, 20, 0 // weapon_m249
}

new g_AllocString_V, 
	g_AllocString_P, 
	g_AllocString_E,

	g_iModelIndexBreakSpear, 
	g_iSpriteIndexTrail,

	g_iMsgID_Weaponlist

#if defined ZP_SUPPORT
	new g_iItemID
#endif

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHam(Ham_Item_Deploy, WEAPON_OLD, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_PostFrame, WEAPON_OLD, "fw_Item_PostFrame");
	RegisterHam(Ham_Item_AddToPlayer, WEAPON_OLD, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Weapon_Reload, WEAPON_OLD, "fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_WeaponIdle, WEAPON_OLD, "fw_Weapon_WeaponIdle");
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_OLD, "fw_Weapon_PrimaryAttack");

	register_think(SPEAR_CLASSNAME, "fw_Think_Spear");
	register_touch(SPEAR_CLASSNAME, "*", "fw_Touch_Spear");

	register_event("HLTV", "EV_RoundStart", "a", "1=0", "2=0");

	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_SetModel, "fw_SetModel");

	register_clcmd(WEAPON_NEW, "HookSelect");
	
	g_iMsgID_Weaponlist = get_user_msgid("WeaponList");

	#if defined ZP_SUPPORT
		g_iItemID = zp_register_extra_item("Spear Gun", 0, ZP_TEAM_HUMAN);
	#else
		register_clcmd("say speargun", "give_weapon");
	#endif
}
public plugin_precache() {
	new szBuffer[64]; formatex(szBuffer, charsmax(szBuffer), "sprites/%s.txt", WEAPON_NEW);

	engfunc(EngFunc_PrecacheGeneric, szBuffer);
	engfunc(EngFunc_PrecacheGeneric, WEAPON_HUD);
	engfunc(EngFunc_PrecacheGeneric, WEAPON_HUD_AMMO);

	g_iModelIndexBreakSpear = engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_SPEAR2);
	g_iSpriteIndexTrail = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr");
	
	g_AllocString_V = engfunc(EngFunc_AllocString, WEAPON_MODEL_V);
	g_AllocString_P = engfunc(EngFunc_AllocString, WEAPON_MODEL_P);
	g_AllocString_E = engfunc(EngFunc_AllocString, WEAPON_OLD);

	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_V);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_P);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_W);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_SPEAR);

	new const WPN_SOUND[][] = {
		"weapons/speargun_clipin.wav",
		"weapons/speargun_draw.wav"
	}
	for(new i = 0; i < sizeof WPN_SOUND;i++) engfunc(EngFunc_PrecacheSound, WPN_SOUND[i]);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_S);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_HIT);
}
public EV_RoundStart() {
	new iEntity;
	while((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", SPEAR_CLASSNAME))) {
		if(pev_valid(iEntity))
			set_pev(iEntity, pev_flags, FL_KILLME);
	}
}

#if defined ZP_SUPPORT
	public zp_extra_item_selected(iPlayer, iItemID) {
		if(iItemID == g_iItemID)
			give_weapon(iPlayer);
	}
#endif

public HookSelect(iPlayer) {
	engclient_cmd(iPlayer, WEAPON_OLD);
	return PLUGIN_HANDLED;
}
public give_weapon(iPlayer) {
	static iEnt; iEnt = engfunc(EngFunc_CreateNamedEntity, g_AllocString_E);
	if(iEnt <= 0) return 0;
	set_pev(iEnt, pev_spawnflags, SF_NORESPAWN);
	set_pev(iEnt, pev_impulse, WEAPON_KEY);
	ExecuteHam(Ham_Spawn, iEnt);
	UTIL_DropWeapon(iPlayer, 1);
	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iEnt)) {
		engfunc(EngFunc_RemoveEntity, iEnt);
		return 0;
	}
	ExecuteHamB(Ham_Item_AttachToPlayer, iEnt, iPlayer);
	set_pdata_int(iEnt, m_iClip, WEAPON_CLIP, 4);
	new iAmmoType = m_rgAmmo +get_pdata_int(iEnt, m_iPrimaryAmmoType, 4);
	if(get_pdata_int(iPlayer, m_rgAmmo, 5) < WEAPON_AMMO)
	set_pdata_int(iPlayer, iAmmoType, WEAPON_AMMO, 5);
	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return 1;
}
public fw_Item_Deploy_Post(iItem) {
	if(!CustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);

	set_pev_string(iPlayer, pev_viewmodel2, g_AllocString_V);
	set_pev_string(iPlayer, pev_weaponmodel2, g_AllocString_P);

	set_pdata_string(iPlayer, m_szAnimExtention * 4, "shotgun", -1, 20);

	SendWeaponAnim(iPlayer, ANIM_DRAW, 0);

	set_pdata_float(iPlayer, m_flNextAttack, ANIM_DRAW_TIME, 5);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_DRAW_TIME, 4);
}
public fw_Item_PostFrame(iItem) {
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	if(get_pdata_int(iItem, m_fInReload, 4) == 1) {
		static iClip; iClip = get_pdata_int(iItem, m_iClip, 4);
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, 4);
		static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, 5);
		static j; j = min(WEAPON_CLIP - iClip, iAmmo);
		set_pdata_int(iItem, m_iClip, iClip+j, 4);
		set_pdata_int(iPlayer, iAmmoType, iAmmo-j, 5);
		set_pdata_int(iItem, m_fInReload, 0, 4);
	}

	static iButton; iButton = pev(iPlayer, pev_button);

	if(iButton & IN_ATTACK2 && get_pdata_float(iItem, m_flNextSecondaryAttack, 4) <= 0.0) {
		new iEntity = -1;
	
		iEntity = fm_find_ent_by_owner(-1, SPEAR_CLASSNAME, iPlayer);
		
		if(iEntity != -1 && pev_valid(iEntity))
			CreateExplode(iEntity, pev(iEntity, pev_aiment));
		
		set_pdata_float(iItem, m_flNextSecondaryAttack, 1.0, 4);
		set_pev(iPlayer, pev_button, iButton & ~IN_ATTACK2);
	}
	return HAM_IGNORED;
}
public fw_Item_AddToPlayer_Post(iItem, iPlayer) {
	switch(pev(iItem, pev_impulse)) {
		case WEAPON_KEY: s_weaponlist(iPlayer, true);
		case 0: s_weaponlist(iPlayer, false);
	}
}
public fw_Weapon_Reload(iItem) {
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iClip; iClip = get_pdata_int(iItem, m_iClip, 4);
	if(iClip >= WEAPON_CLIP) return HAM_SUPERCEDE;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, 4);
	if(get_pdata_int(iPlayer, iAmmoType, 5) <= 0) return HAM_SUPERCEDE

	set_pdata_int(iItem, m_iClip, 0, 4);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, 4);
	set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_RELOAD_TIME, 4);
	set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_RELOAD_TIME, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_RELOAD_TIME, 4);
	set_pdata_float(iPlayer, m_flNextAttack, ANIM_RELOAD_TIME, 5);

	SendWeaponAnim(iPlayer, ANIM_RELOAD, 0);
	return HAM_SUPERCEDE;
}
public fw_Weapon_WeaponIdle(iItem) {
	if(!CustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, 4) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);

	SendWeaponAnim(iPlayer, get_pdata_int(iItem, m_iClip, 4) == 0 ? ANIM_IDLE_EMPTY : ANIM_IDLE, 0);

	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_IDLE_TIME, 4);
	return HAM_SUPERCEDE;
}
public fw_Weapon_PrimaryAttack(iItem) {
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	static iAmmo; iAmmo = get_pdata_int(iItem, m_iClip, 4);

	if(iAmmo == 0) {
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, 4);
		return HAM_SUPERCEDE;
	}

	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_S, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	SendWeaponAnim(iPlayer, ANIM_ATTACK, 0);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_SHOOT_TIME, 4);
	set_pdata_int(iItem, m_iClip, iAmmo - 1, 4);

	static Float: vecOrigin[3], Float: vecVelocity[3], Float: vecAngles[3];
	static iReference;

	Weapon_Position(iPlayer, vecOrigin, 50.0, 4.0, -4.0);

	if(iReference || (iReference = engfunc(EngFunc_AllocString, "info_target"))) {
		new iEntity = engfunc(EngFunc_CreateNamedEntity, iReference);

		set_pev(iEntity, pev_classname, SPEAR_CLASSNAME);
		set_pev(iEntity, pev_solid, SOLID_BBOX);
		set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
		set_pev(iEntity, pev_owner, iPlayer);

		velocity_by_aim(iPlayer, SPEAR_SPEED, vecVelocity);
		set_pev(iEntity, pev_velocity, vecVelocity);

		engfunc(EngFunc_VecToAngles, vecVelocity, vecAngles);
		set_pev(iEntity, pev_angles, vecAngles);
		set_pev(iEntity, pev_punchangle, Float: { 0.0, 0.0, 0.0 });
		set_pev(iEntity, pev_nextthink, get_gametime() + 2.0);

		engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_SPEAR);
		engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(iEntity);
		write_short(g_iSpriteIndexTrail);
		write_byte(2);
		write_byte(1);
		write_byte(210);
		write_byte(210);
		write_byte(210);
		write_byte(150);
		message_end();	
	}

	return HAM_SUPERCEDE;
}
public fw_Think_Spear(iEntity) {
	if(!pev_valid(iEntity))
		return;

	CreateExplode(iEntity, pev(iEntity, pev_aiment));
}
public fw_Touch_Spear(iEntity, iVictim) {
	if(!pev_valid(iEntity))
		return;

	new Float: vecVelocity[3], Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
	static iOwner; iOwner = pev(iEntity, pev_owner);

	if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY) {
		set_pev(iEntity, pev_flags, FL_KILLME);
		return;
	}

	if(!iVictim) {
		emit_sound(iEntity, CHAN_ITEM, WEAPON_SOUND_HIT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
	else {
		if(pev(iVictim, pev_takedamage) != DAMAGE_NO) {
			if(pev(iVictim, pev_solid) == SOLID_BSP) {
				if(!(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)) {
					ExecuteHamB(Ham_TakeDamage, iVictim, iEntity, iOwner, SPEAR_DAMAGE, DMG_BULLET);
				}
			}
			else if(is_user_alive(iVictim)) {
				#if defined ZP_SUPPORT
					if(zp_get_user_zombie(iVictim)) {
						ExecuteHamB(Ham_TakeDamage, iVictim, iEntity, iOwner, SPEAR_DAMAGE, DMG_BULLET);

						velocity_by_aim(iOwner, SPEAR_KNOCKBACK, vecVelocity);
						set_pev(iVictim, pev_velocity, vecVelocity);
					}
				#else
					ExecuteHamB(Ham_TakeDamage, iVictim, iEntity, iOwner, SPEAR_DAMAGE, DMG_BULLET);

					velocity_by_aim(iOwner, SPEAR_KNOCKBACK, vecVelocity);
					set_pev(iVictim, pev_velocity, vecVelocity);
				#endif

				set_pev(iEntity, pev_aiment, iVictim);
				set_pev(iEntity, pev_movetype, MOVETYPE_FOLLOW);
				set_pev(iEntity, pev_solid, SOLID_NOT);
			}
		}
	}

	set_pev(iEntity, pev_velocity, Float: { 0.0, 0.0, 0.0 });
	set_pev(iEntity, pev_nextthink, get_gametime() + 1.0);
}
public CreateExplode(iEntity, iAimEnt) {
	new Float: vecOrigin[3], Float: vecVelocity[3], iOwner;
	static iVictim = -1;

	pev(iAimEnt ? iAimEnt : iEntity, pev_origin, vecOrigin);

	iOwner = pev(iEntity, pev_owner);

	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, SPEAR_EXPLODE_RADIUS))) {
		if(pev(iVictim, pev_takedamage) == DAMAGE_NO) 
			continue;

		#if defined ZP_SUPPORT
			if(iVictim == iOwner && !zp_get_user_zombie(iOwner)) {
				pev(iOwner, pev_velocity, vecVelocity);
				vecVelocity[2] += SPEAR_KNOCKBACK_EXPLODE;
				set_pev(iOwner, pev_velocity, vecVelocity);
			}

			if(is_user_alive(iVictim)) {
				if(iVictim == iOwner || zp_get_user_zombie(iOwner) || !zp_get_user_zombie(iVictim))
					continue;
			}
			else if(pev(iVictim, pev_solid) == SOLID_BSP) {
				if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
					continue;
			}
		#else
			if(iVictim == iOwner) {
				pev(iOwner, pev_velocity, vecVelocity);
				vecVelocity[2] += SPEAR_KNOCKBACK_EXPLODE;
				set_pev(iOwner, pev_velocity, vecVelocity);
			}

			if(is_user_alive(iVictim)) {
				if(iVictim == iOwner)
					continue;
			}
			else if(pev(iVictim, pev_solid) == SOLID_BSP) {
				if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
					continue;
			}
		#endif

		ExecuteHamB(Ham_TakeDamage, iVictim, iEntity, iOwner, SPEAR_DAMAGE_EXPLODE, DMG_BULLET);
	}

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	engfunc(EngFunc_WriteCoord, 150);
	engfunc(EngFunc_WriteCoord, 150);
	engfunc(EngFunc_WriteCoord, 150);
	engfunc(EngFunc_WriteCoord, random_num(-50, 50));
	engfunc(EngFunc_WriteCoord, random_num(-50, 50));
	engfunc(EngFunc_WriteCoord, random_num(-50, 50));
	write_byte(30);
	write_short(g_iModelIndexBreakSpear);
	write_byte(random_num(15, 20));
	write_byte(20);
	write_byte(16);
	message_end();

	UTIL_Explosion2(vecOrigin, 66, 66);

	set_pev(iEntity, pev_flags, FL_KILLME);
}
public fw_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle) {
	if(get_cd(CD_Handle, CD_DeadFlag) != DEAD_NO) return;
	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, 5);
	if(iItem <= 0 || !CustomItem(iItem)) return;
	set_cd(CD_Handle, CD_flNextAttack, 999999.0);
}
public fw_SetModel(iEnt) {
	static i, szClassname[32], iItem; 
	pev(iEnt, pev_classname, szClassname, 31);
	if(!equal(szClassname, "weaponbox")) return FMRES_IGNORED;
	for(i = 0; i < 6; i++) {
		iItem = get_pdata_cbase(iEnt, m_rgpPlayerItems_CWeaponBox + i, 4);
		if(iItem > 0 && CustomItem(iItem)) {
			engfunc(EngFunc_SetModel, iEnt, WEAPON_MODEL_W);
			set_pev(iEnt, pev_body, WEAPON_BODY);
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}
stock SendWeaponAnim(iPlayer, iAnim, iBody)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);
	
	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(iBody);
	message_end();
}
stock UTIL_DropWeapon(iPlayer, iSlot) {
	static iEntity, iNext, szWeaponName[32]; 
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, 5);
	if(iEntity > 0) { 
		do {
			iNext = get_pdata_cbase(iEntity, m_pNext, 4)
			if(get_weaponname(get_pdata_int(iEntity, m_iId, 4), szWeaponName, 31)) {
				engclient_cmd(iPlayer, "drop", szWeaponName);
			}
		} while(( iEntity = iNext) > 0);
	}
}
stock s_weaponlist(iPlayer, bool:on) {
	message_begin(MSG_ONE, g_iMsgID_Weaponlist, _, iPlayer);
	write_string(on ? WEAPON_NEW : WEAPON_OLD);
	write_byte(iWeaponList[0]);
	write_byte(on ? WEAPON_AMMO : iWeaponList[1]);
	write_byte(iWeaponList[2]);
	write_byte(iWeaponList[3]);
	write_byte(iWeaponList[4]);
	write_byte(iWeaponList[5]);
	write_byte(iWeaponList[6]);
	write_byte(iWeaponList[7]);
	message_end();
}
stock UTIL_Explosion2(Float: vecOrigin[3], iStartingColor, iColorNum) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION2);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_byte(iStartingColor);
	write_byte(iColorNum);
	message_end();
}
stock Weapon_Position(const iPlayer, Float:fOrigin[], Float:add_forward, Float:add_right, Float:add_up) {
	static Float:Angles[3],Float:ViewOfs[3], Float:vAngles[3];
	static Float:Forward[3], Float:Right[3], Float:Up[3];
	
	pev(iPlayer, pev_v_angle, vAngles);
	pev(iPlayer, pev_origin, fOrigin);
	pev(iPlayer, pev_view_ofs, ViewOfs);
	xs_vec_add( fOrigin, ViewOfs, fOrigin);
	
	pev(iPlayer, pev_angles, Angles);
	
	Angles[0] =  vAngles[0];
	
	engfunc(EngFunc_MakeVectors, Angles);
	
	global_get(glb_v_forward, Forward);
	global_get(glb_v_right, Right);
	global_get(glb_v_up,  Up);
	
	xs_vec_mul_scalar(Forward, add_forward, Forward);
	xs_vec_mul_scalar(Right, add_right, Right);
	xs_vec_mul_scalar(Up, add_up, Up);
	
	fOrigin[0] = fOrigin[0] + Forward[0] + Right[0] + Up[0];
	fOrigin[1] = fOrigin[1] + Forward[1] + Right[1] + Up[1];
	fOrigin[2] = fOrigin[2] + Forward[2] + Right[2] + Up[2];
}