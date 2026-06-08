#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <zpe_knokcback>

#define PLUGIN "[KZ] Weapon: BALROG-XI"
#define VERSION "1.1"
#define AUTHOR "Batcoh & t3rkecorejz (xUnicorn)"

#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_KEY)

// native zp_set_item_max_clip(iPlayer, iValue);
// native zp_set_item_max_ammo(iPlayer, iValue);
// forward zp_weapon_buyammo(iPlayer, iActiveItem);

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
#define m_fInSpecialReload 55
#define m_iShotsFired 64
#define m_iWeaponState 74

// CBaseMonster
#define m_LastHitGroup 75
#define m_flNextAttack 83

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

#define ANIM_IDLE 0
#define ANIM_ATTACK random_num(1, 2)
#define ANIM_ATTACK2 3
#define ANIM_RELOAD_INSERT 4
#define ANIM_RELOAD_END 5
#define ANIM_RELOAD_START 6
#define ANIM_DRAW 7

#define OBS_IN_EYE 4

// from model: Frames / FPS
#define ANIM_IDLE_TIME 3.37
#define ANIM_SHOOT_TIME 1.03
#define ANIM_DRAW_TIME 1.14
#define ANIM_INSERT_TIME 0.43
#define ANIM_AFTER_RELOAD_TIME 0.45
#define ANIM_START_RELOAD_TIME 0.64

#define WEAPON_KEY 1007
#define WEAPON_CSW CSW_XM1014
#define WEAPON_OLD "weapon_xm1014"
#define WEAPON_NEW "zp_br_cso/weapons/weapon_balrog11"
#define WEAPON_HUD "sprites/zp_br_cso/weapons/hud/640hud89.spr"
#define WEAPON_HUD_AMMO "sprites/zp_br_cso/weapons/hud/640hud153.spr"

#define WEAPON_COST 0

#define WEAPON_MODEL_V "models/zp_br_cso/weapons/v_balrog11_b1.mdl"

#define WEAPON_MODEL_W "models/zp_br_cso/other/w_weapons_b1.mdl"
#define WEAPON_BODY 12

#define WEAPON_SOUND_S "weapons/balrog11-1.wav"
#define WEAPON_SOUND_S2 "weapons/balrog11-2.wav"
#define WEAPON_SOUND_CHARGE "weapons/balrog11_charge.wav"
#define WEAPON_SOUND_INSERT "weapons/balrog11_insert.wav"

#define WEAPON_CLIP 7
#define WEAPON_AMMO 32
#define WEAPON_RATE 0.25
#define WEAPON_RATE_EX 0.5
#define WEAPON_DAMAGE 1.40
#define WEAPON_ANIM_RELOAD_START_TIME 0.7

#define FLAME_CLASSNAME "balrog11_flame"
#define FLAME_SPEED 610.0
#define FLAME_RADIUS 31.0
#define FLAME_DAMAGE random_float(200.0, 250.0)
#define FLAME_SPRITE "sprites/eexplo.spr"
#define FLAME_FRAMES 25.0

new const iWeaponList[] = {  
	5,  32, -1, -1, 0, 12,5,  0 // weapon_xm1014
};

new g_iszAllocString_ModelView,
	g_iszAllocString_Entity,

	HamHook: g_fw_TraceAttack[4],

	g_iMsgID_WeaponList,
	g_iMsgID_StatusIcon,
	// g_iSpriteFrames,
	g_iItemID

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHam(Ham_Item_Holster, WEAPON_OLD, "fw_Item_Holster_Post", 1);
	RegisterHam(Ham_Item_Deploy, WEAPON_OLD, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_PostFrame, WEAPON_OLD, "fw_Item_PostFrame");
	RegisterHam(Ham_Item_AddToPlayer, WEAPON_OLD, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Weapon_Reload, WEAPON_OLD, "fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_WeaponIdle, WEAPON_OLD, "fw_Weapon_WeaponIdle");
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_OLD, "fw_Weapon_PrimaryAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_OLD, "fw_Weapon_SecondaryAttack");
	
	g_fw_TraceAttack[0] = RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack");
	g_fw_TraceAttack[1] = RegisterHam(Ham_TraceAttack, "info_target",    "fw_TraceAttack");
	g_fw_TraceAttack[2] = RegisterHam(Ham_TraceAttack, "player",         "fw_TraceAttack");
	g_fw_TraceAttack[3] = RegisterHam(Ham_TraceAttack, "hostage_entity", "fw_TraceAttack");
	
	fm_ham_hook(false);

	register_forward(FM_Touch, "fw_Touch");
	register_forward(FM_Think, "fw_Think");

	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_SetModel, "fw_SetModel");

	register_clcmd(WEAPON_NEW, "HookSelect");

	g_iMsgID_WeaponList = get_user_msgid("WeaponList");
	g_iMsgID_StatusIcon = get_user_msgid("StatusIcon");

	g_iItemID = zp_register_extra_item("Balrog-11", 27, ZP_TEAM_HUMAN);
}
public plugin_precache() {
	new szBuffer[64]; formatex(szBuffer, charsmax(szBuffer), "sprites/%s.txt", WEAPON_NEW);

	engfunc(EngFunc_PrecacheGeneric, szBuffer);
	engfunc(EngFunc_PrecacheGeneric, WEAPON_HUD);
	engfunc(EngFunc_PrecacheGeneric, WEAPON_HUD_AMMO);

	// g_iSpriteFrames = engfunc(EngFunc_ModelFrames, engfunc(EngFunc_PrecacheModel, FLAME_SPRITE));
	
	g_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_V);
	g_iszAllocString_Entity = engfunc(EngFunc_AllocString, WEAPON_OLD);

	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_V);
	
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_S);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_S2);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_CHARGE);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_INSERT);
}
public zp_extra_item_selected(iPlayer, iItemID)
{
	if(iItemID == g_iItemID)
		give_weapon(iPlayer);
}
public HookSelect(iPlayer) {
	engclient_cmd(iPlayer, WEAPON_OLD);
	return PLUGIN_HANDLED;
}
public give_weapon(iPlayer) {
	static iEnt; iEnt = engfunc(EngFunc_CreateNamedEntity, g_iszAllocString_Entity);
	if(iEnt <= 0) return 0;

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
public zp_user_infected_post(iPlayer) 
{
	if(pev_valid(iPlayer) != 2) return;
	new iItem = get_pdata_cbase(iPlayer, m_pActiveItem, 5);
	Update_StatusIcon(iItem, iPlayer, 0);
}
public fw_Think(iEntity) {
	if(!pev_valid(iEntity))
		return FMRES_IGNORED;

	static szClassName[32]; 
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(equal(szClassName, FLAME_CLASSNAME)) {
		static Float: flFrame; pev(iEntity, pev_frame, flFrame);
		static Float: flScale; pev(iEntity, pev_scale, flScale);
		static Float: flGameTime; flGameTime = get_gametime();

		if(pev(iEntity, pev_movetype) == MOVETYPE_NONE) {
			flFrame += 0.65;
			
			if(flScale <= 0.7) flScale += 0.01;
			if(flFrame > FLAME_FRAMES) { 
				set_pev(iEntity, pev_flags, FL_KILLME);
				return FMRES_IGNORED;
			}
		}
		else {
			flFrame += 0.8;
			
			if(flFrame >= FLAME_FRAMES - 1.0) set_pev(iEntity, pev_movetype, MOVETYPE_NONE);
			if(flScale <= 0.7) flScale += 0.05;
		}

		set_pev(iEntity, pev_scale, flScale);
		set_pev(iEntity, pev_frame, flFrame);
		
		set_pev(iEntity, pev_nextthink, flGameTime + 0.017);
	}

	return FMRES_IGNORED;
}
public fw_Touch(iEntity, iVictim) {
	if(!pev_valid(iEntity))
		return FMRES_IGNORED;

	static szClassName[32]; 
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	if(equal(szClassName, FLAME_CLASSNAME)) {

		if(iVictim == iEntity)
			return FMRES_IGNORED;

		new szClassNameVictim[32]; pev(iVictim, pev_classname, szClassNameVictim, charsmax(szClassNameVictim));
		if(strcmp(szClassNameVictim, FLAME_CLASSNAME) == 0)
			return FMRES_IGNORED;

		new iOwner; iOwner = pev(iEntity, pev_owner);
		if(iVictim == iOwner)
			return FMRES_IGNORED;

		/* По тимейтам не ебашит */
		if(is_user_connected(iVictim) && !zp_get_user_zombie(iVictim))
			return FMRES_IGNORED;

		set_pev(iEntity, pev_movetype, MOVETYPE_NONE);
		set_pev(iEntity, pev_solid, SOLID_NOT);

		new Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		new iVictim = -1

		while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, vecOrigin, FLAME_RADIUS)) > 0) {
			if(pev(iVictim, pev_takedamage) == DAMAGE_NO) 
				continue;

			if(is_user_alive(iVictim)) {
				if(iVictim == iOwner || zp_get_user_zombie(iOwner) || !zp_get_user_zombie(iVictim))
					continue;
			}
			else if(pev(iVictim, pev_solid) == SOLID_BSP) {
				if(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
					continue;
			}

			set_pdata_int(iVictim, m_LastHitGroup, HIT_GENERIC, 5);
			ExecuteHamB(Ham_TakeDamage, iVictim, iEntity, iOwner, FLAME_DAMAGE, DMG_BURN|DMG_SLASH);
			zp_set_user_knock_by_missile(iVictim, iOwner, 255.0, 2.54)
		}
	}

	return FMRES_IGNORED;
}
public fw_Item_Holster_Post(iItem) {
	if(pev_valid(iItem) != 2 || !CustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);

	Update_StatusIcon(iItem, iPlayer, 0);
	set_pdata_int(iItem, m_fInSpecialReload, 0, 4);
}
public fw_Item_Deploy_Post(iItem) {
	if(pev_valid(iItem) != 2 || !CustomItem(iItem)) return;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);

	set_pev_string(iPlayer, pev_viewmodel2, g_iszAllocString_ModelView);
	
	Update_StatusIcon(iItem, iPlayer, 0);
	Update_StatusIcon(iItem, iPlayer, 1);

	SendWeaponAnim(iPlayer, ANIM_DRAW);

	set_pdata_float(iPlayer, m_flNextAttack, ANIM_DRAW_TIME, 5);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_DRAW_TIME, 4);

	set_pdata_int(iItem, m_fInSpecialReload, 0, 4);
}
public fw_Item_PostFrame(iItem) {
	if(pev_valid(iItem) != 2 || !CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);

	static iClip; iClip = get_pdata_int(iItem, m_iClip, 4);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, 4);
	static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, 5);
	static iButton; iButton = pev(iPlayer, pev_button);

	if(get_pdata_int(iItem, m_fInSpecialReload, 4) == 1) 
	{
		if(get_pdata_float(iItem, m_flNextSecondaryAttack, 4) > 0.0) return HAM_IGNORED;

		if(iAmmo <= 0 || iClip == WEAPON_CLIP) 
		{
			set_pdata_int(iItem, m_fInSpecialReload, 0, 4);
			set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_AFTER_RELOAD_TIME, 4);
			set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_AFTER_RELOAD_TIME, 4);

			SendWeaponAnim(iPlayer, ANIM_RELOAD_END);
		}
		else 
		{
			set_pdata_int(iItem, m_iClip, iClip + 1, 4);
			set_pdata_int(iPlayer, iAmmoType, iAmmo - 1, 5);
			set_pdata_float(iItem,m_flNextSecondaryAttack, ANIM_INSERT_TIME, 4);
			set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_INSERT_TIME, 4);

			SendWeaponAnim(iPlayer, ANIM_RELOAD_INSERT);
			emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_INSERT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	if(iButton & IN_ATTACK2) 
	{
		ExecuteHamB(Ham_Weapon_SecondaryAttack, iItem);
		iButton &= ~IN_ATTACK2;
		set_pev(iPlayer, pev_button, iButton);
	}

	return HAM_IGNORED;
}
public fw_Item_AddToPlayer_Post(iItem, iPlayer) 
{
	switch(pev(iItem, pev_impulse)) 
	{
		case WEAPON_KEY: s_weaponlist(iPlayer, true);
		case 0: s_weaponlist(iPlayer, false);
	}
}
public fw_Weapon_Reload(iItem) {
	if(pev_valid(iItem) != 2 || !CustomItem(iItem)) return HAM_IGNORED;
	if(get_pdata_int(iItem, m_fInSpecialReload, 4) != 0) return HAM_SUPERCEDE;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, 4);
	if(iClip >= WEAPON_CLIP) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, 4);
	if(get_pdata_int(iPlayer, iAmmoType, 5) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iItem, m_iClip, 0, 4);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, 4);

	set_pdata_int(iItem, m_fInSpecialReload, 1, 4);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_START_TIME, 4);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_START_TIME, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_START_TIME, 4);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_START_TIME, 5);

	SendWeaponAnim(iPlayer, ANIM_RELOAD_START);
	return HAM_SUPERCEDE;
}
public fw_Weapon_WeaponIdle(iItem) {
	if(pev_valid(iItem) != 2 || !CustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, 4) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);

	SendWeaponAnim(iPlayer, ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_IDLE_TIME, 4);

	return HAM_SUPERCEDE;
}
public fw_Weapon_PrimaryAttack(iItem) 
{
	if(pev_valid(iItem) != 2 || !CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);

	if(get_pdata_int(iItem, m_iClip, 4) == 0) 
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, 4);
		return HAM_SUPERCEDE;
	}

	static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "fw_TraceLine_Post", 1);
	static fw_PlayBackEvent; fw_PlayBackEvent = register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
	fm_ham_hook(true);

	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);

	unregister_forward(FM_TraceLine, fw_TraceLine, 1);
	unregister_forward(FM_PlaybackEvent, fw_PlayBackEvent);
	fm_ham_hook(false);

	if(get_pdata_int(iItem, m_iWeaponState, 4) < 7) 
	{
		set_pdata_int(iItem, m_iShotsFired, get_pdata_int(iItem, m_iShotsFired, 4) + 1, 4);
		
		if(!(get_pdata_int(iItem, m_iShotsFired, 4) % 4)) 
		{
			Update_StatusIcon(iItem, iPlayer, 0);
			set_pdata_int(iItem, m_iWeaponState, get_pdata_int(iItem, m_iWeaponState, 4) + 1, 4);
			Update_StatusIcon(iItem, iPlayer, 1);

			emit_sound(iPlayer, CHAN_ITEM, WEAPON_SOUND_CHARGE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_S, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	SendWeaponAnim(iPlayer, ANIM_ATTACK);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_SHOOT_TIME, 4);

	return HAM_SUPERCEDE;
}
public fw_Weapon_SecondaryAttack(iItem) {
	if(pev_valid(iItem) != 2 || !CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);

	if(!get_pdata_int(iItem, m_iWeaponState, 4)) return HAM_SUPERCEDE;

	static Float: flGameTime; flGameTime = get_gametime();
	static iReference;

	new Float: vecOfs[3]; pev(iPlayer, pev_view_ofs, vecOfs);
	new Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	new Float: vecAngle[3]; pev(iPlayer, pev_v_angle, vecAngle);

	vecOrigin[0] += vecOfs[0];
	vecOrigin[1] += vecOfs[1];
	vecOrigin[2] += vecOfs[2];
	
	vecAngle[1] -= 30.0;

	for(new i = 0; i < 5; i++) {
		vecAngle[1] += 10.0;

		new Float: vecVelocity[3]; angle_vector(vecAngle, ANGLEVECTOR_FORWARD, vecVelocity);
		new Float: vecFireOrigin[3];

		vecFireOrigin[0] = vecOrigin[0] + vecVelocity[0] * 20.0;
		vecFireOrigin[1] = vecOrigin[1] + vecVelocity[1] * 20.0;
		vecFireOrigin[2] = vecOrigin[2] + vecVelocity[2] * 20.0;

		vecVelocity[0] *= FLAME_SPEED;
		vecVelocity[1] *= FLAME_SPEED;
		vecVelocity[2] *= FLAME_SPEED;

		if(iReference || (iReference = engfunc(EngFunc_AllocString, "info_target"))) {
			new iEntity = engfunc(EngFunc_CreateNamedEntity, iReference);

			set_pev(iEntity, pev_classname, FLAME_CLASSNAME);
			set_pev(iEntity, pev_solid, SOLID_TRIGGER);
			set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
			set_pev(iEntity, pev_owner, iPlayer);
			set_pev(iEntity, pev_nextthink, flGameTime);
			set_pev(iEntity, pev_velocity, vecVelocity);
			set_pev(iEntity, pev_gravity, 0.1);

			set_pev(iEntity, pev_rendermode, kRenderTransAdd);
			set_pev(iEntity, pev_renderamt, 255.0);
			set_pev(iEntity, pev_renderfx, kRenderFxNone);

			set_pev(iEntity, pev_scale, 0.3);
			set_pev(iEntity, pev_frame, 1.0);
			
			engfunc(EngFunc_SetModel, iEntity, FLAME_SPRITE);
			engfunc(EngFunc_SetSize, iEntity, Float: { -1.0, -1.0, -1.0 }, Float: { 1.0, 1.0, 1.0 });
			engfunc(EngFunc_SetOrigin, iEntity, vecFireOrigin);
		}
	}

	set_pdata_int(iItem, m_fInSpecialReload, 0, 4);

	Update_StatusIcon(iItem, iPlayer, 0);
	set_pdata_int(iItem, m_iWeaponState, get_pdata_int(iItem, m_iWeaponState, 4) - 1, 4);
	Update_StatusIcon(iItem, iPlayer, 1);

	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_S2, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	SendWeaponAnim(iPlayer, ANIM_ATTACK2);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE_EX, 4);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_RATE_EX, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_SHOOT_TIME, 4);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_RATE_EX, 5);

	return HAM_SUPERCEDE;
}
public fw_PlaybackEvent() return FMRES_SUPERCEDE;
public fw_TraceAttack(iVictim, iAttacker, Float:flDamage) {
	if(pev_valid(iAttacker) != 2 ||!is_user_connected(iAttacker)) return;
	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, 5);
	if(iItem <= 0 || !CustomItem(iItem)) return;
        SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}
public fw_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle) {
	if(pev_valid(iPlayer) != 2 ||get_cd(CD_Handle, CD_DeadFlag) != DEAD_NO) return;

	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, 5);
	if(iItem <= 0 || !CustomItem(iItem)) return;

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}
public fw_SetModel(iEnt) {
	if(pev_valid(iEnt) != 2) return FMRES_IGNORED;
	static i, szClassName[32], iItem; 
	pev(iEnt, pev_classname, szClassName, 31);

	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
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
public fw_TraceLine_Post(const Float:flOrigin1[3], const Float:flOrigin2[3], iFrag, iIgnore, tr) {
	if(iFrag & IGNORE_MONSTERS) return FMRES_IGNORED;
	static pHit; pHit = get_tr2(tr, TR_pHit);
	static Float:flvecEndPos[3]; get_tr2(tr, TR_vecEndPos, flvecEndPos);

	if(pHit > 0) {
		if(pev(pHit, pev_solid) != SOLID_BSP) return FMRES_IGNORED;
	}

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, flvecEndPos, 0);
	write_byte(TE_GUNSHOTDECAL);
	engfunc(EngFunc_WriteCoord, flvecEndPos[0]);
	engfunc(EngFunc_WriteCoord, flvecEndPos[1]);
	engfunc(EngFunc_WriteCoord, flvecEndPos[2]);
	write_short(pHit > 0 ? pHit : 0);
	write_byte(random_num(41, 45));
	message_end();

	return FMRES_IGNORED;
}
public fm_ham_hook(bool:on) {
	if(on) {
		EnableHamForward(g_fw_TraceAttack[0]);
		EnableHamForward(g_fw_TraceAttack[1]);
		EnableHamForward(g_fw_TraceAttack[2]);
		EnableHamForward(g_fw_TraceAttack[3]);
	}
	else {
		DisableHamForward(g_fw_TraceAttack[0]);
		DisableHamForward(g_fw_TraceAttack[1]);
		DisableHamForward(g_fw_TraceAttack[2]);
		DisableHamForward(g_fw_TraceAttack[3]);
	}
}
stock SendWeaponAnim(iPlayer, iAnim) {
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}
stock UTIL_DropWeapon(iPlayer, iSlot)
{
	if(pev_valid(iPlayer) != 2 ) return;
	static iEntity, szWeaponName[32];
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot);
	while ( pev_valid( iEntity ) == 2 )
	{
		pev( iEntity, pev_classname, szWeaponName, charsmax( szWeaponName ) );
		engclient_cmd( iPlayer, "drop", szWeaponName );

		iEntity = get_pdata_cbase( iEntity, m_pNext, 4 );
	}
}
stock UTIL_PrecacheSoundsFromModel(const szModelPath[]) {
	new iFile;
	
	if((iFile = fopen(szModelPath, "rt"))) {
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for(new k, i = 0; i < iNumSeq; i++) {
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);
			
			for(k = 0; k < iNumEvents; k++) {
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if(iEvent != 5004)
					continue;
				
				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if(strlen(szSoundPath)) {
					format(szSoundPath, charsmax(szSoundPath), "sound/%s", szSoundPath);
					engfunc(EngFunc_PrecacheGeneric, szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}
stock s_weaponlist(iPlayer, bool:on) {
	message_begin(MSG_ONE, g_iMsgID_WeaponList, _, iPlayer);
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
stock Update_StatusIcon(iItem, iPlayer, iUpdateMode) {
	new szSprite[33];
	new SuperBullets = get_pdata_int(iItem, m_iWeaponState, 4);
	
	format(szSprite, charsmax(szSprite), "number_%d", SuperBullets);
	
	message_begin(MSG_ONE, g_iMsgID_StatusIcon, { 0, 0, 0 }, iPlayer);
	if(iUpdateMode && SuperBullets > 0) write_byte(1);
	else write_byte(0);
	write_string(szSprite); 
	write_byte(30);
	write_byte(144); 
	write_byte(255);
	message_end();
}