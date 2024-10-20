#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>
#include <zp_system>


#define PLUGIN "[ZMO] Weapon: Lego Shotgun (Basic)"
#define VERSION "1.0"
#define AUTHOR "Base: Batcon; ReEdit: t3rkecorejz"

#define CustomItem(%0) (pev_valid(%0) == 2 && pev(%0, pev_impulse) == WEAPON_KEY)

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
#define m_fInReload 54
#define m_fInSpecialReload 55
#define m_iShellId 57

// CBaseMonster
#define m_flNextAttack 83

// CBasePlayer
#define m_flEjectBrass 111
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

#define ANIM_IDLE 0
#define ANIM_ATTACK random_num(1, 3)
#define ANIM_RELOAD_START 6
#define ANIM_RELOAD_INSERT 7
#define ANIM_RELOAD_END 8
#define ANIM_DRAW 5

#define ANIM_IDLE_TIME 1.7
#define ANIM_RELOAD_TIME 0.7
#define ANIM_DRAW_TIME 1.37
#define ANIM_SHOOT_TIME 1.04

#define WEAPON_KEY 1006
#define WEAPON_OLD "weapon_xm1014"
#define WEAPON_NEW "zp_br_cso/weapons2/weapon_blockas"

#define WEAPON_MODEL_V "models/zp_br_cso/weapons2/v_blockas1.mdl"

#define WEAPON_MODEL_W "models/zp_br_cso/other/w_weapons_b1.mdl"
#define WEAPON_MODEL_S "models/zp_br_cso/weapons2/blockas1_bullet.mdl"
#define WEAPON_SOUND_S "weapons/blockas1-2.wav"
#define WEAPON_BODY 8

#define WEAPON_CLIP 8
#define WEAPON_AMMO 32
#define WEAPON_RATE 0.35
#define WEAPON_RECOIL 0.91
#define WEAPON_DAMAGE 1.3
#define WEAPON_ANIM_RELOAD_START_TIME 1.0

new const iWeaponList[ ] = {  
	5,  32, -1, -1, 0, 12,5,  0 // weapon_xm1014
}

new g_AllocString_V, g_AllocString_E
new HamHook:g_fw_TraceAttack[4]
new g_iszModelIndexShell
new g_iMsgID_Weaponlist
new g_iItemID
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHam(Ham_Item_Deploy, WEAPON_OLD, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_PostFrame, WEAPON_OLD, "fw_Item_PostFrame");
	RegisterHam(Ham_Item_AddToPlayer, WEAPON_OLD, "fw_Item_AddToPlayer_Post", 1);
	
	RegisterHam(Ham_Weapon_Reload, WEAPON_OLD, "fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_WeaponIdle, WEAPON_OLD, "fw_Weapon_WeaponIdle");
	RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_OLD, "fw_Weapon_PrimaryAttack");
	
	g_fw_TraceAttack[0] = RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack");
	g_fw_TraceAttack[1] = RegisterHam(Ham_TraceAttack, "info_target",    "fw_TraceAttack");
	g_fw_TraceAttack[2] = RegisterHam(Ham_TraceAttack, "player",         "fw_TraceAttack");
	g_fw_TraceAttack[3] = RegisterHam(Ham_TraceAttack, "hostage_entity", "fw_TraceAttack");
	fm_ham_hook(false);
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
	register_forward(FM_SetModel, "fw_SetModel");
	g_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	register_clcmd(WEAPON_NEW, "HookSelect");
	g_iItemID = zp_register_extra_item("M777 Shotgun", 0, ZP_TEAM_HUMAN);
}
public plugin_precache() 
{
	g_AllocString_V = engfunc(EngFunc_AllocString, WEAPON_MODEL_V);
	g_AllocString_E = engfunc(EngFunc_AllocString, WEAPON_OLD);
	g_iszModelIndexShell = engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_S);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_V);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_S);
}
public HookSelect(iPlayer) {
	engclient_cmd(iPlayer, WEAPON_OLD);
	return PLUGIN_HANDLED;
}
public zp_extra_item_selected(iPlayer, iItemID) 
{
	if(iItemID == g_iItemID)
		give_weapon(iPlayer);
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

	set_pdata_float(iPlayer, m_flNextAttack, ANIM_DRAW_TIME, 5);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_DRAW_TIME, 4);

	UTIL_SendWeaponAnim(iPlayer, ANIM_DRAW);

	if(get_pdata_int(iItem, m_fInSpecialReload, 4) != 0)
		set_pdata_int(iItem, m_fInSpecialReload, 0, 4);
}
public fw_Item_PostFrame(iItem) 
{
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);

	if(get_pdata_int(iItem, m_fInSpecialReload, 4) == 1) 
	{
		if(get_pdata_float(iItem, m_flNextSecondaryAttack, 4) > 0.0) return HAM_IGNORED;

		static iClip; iClip = get_pdata_int(iItem, m_iClip, 4);
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, 4);
		static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, 5);

		if(iAmmo <= 0 || iClip== WEAPON_CLIP) 
		{
			set_pdata_int(iItem, m_fInSpecialReload, 0, 4);
			set_pdata_float(iItem, m_flNextSecondaryAttack, 1.0, 4);
			set_pdata_float(iItem, m_flTimeWeaponIdle, 1.0, 4);

			UTIL_SendWeaponAnim(iPlayer, ANIM_RELOAD_END);
		}
		else 
		{
			set_pdata_int(iItem, m_iClip, iClip + 1, 4);
			set_pdata_int(iPlayer, iAmmoType, iAmmo - 1, 5);
			set_pdata_float(iItem,m_flNextSecondaryAttack, 0.5, 4);
			set_pdata_float(iItem, m_flTimeWeaponIdle, 0.5, 4);

			UTIL_SendWeaponAnim(iPlayer, ANIM_RELOAD_INSERT);
		}
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
	if(get_pdata_int(iItem, m_fInSpecialReload, 4) !=0 )return HAM_SUPERCEDE;

	static iClip; iClip = get_pdata_int(iItem, m_iClip, 4);
	if(iClip >= WEAPON_CLIP) return HAM_SUPERCEDE;

	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, 4);
	if(get_pdata_int(iPlayer, iAmmoType, 5) <= 0) return HAM_SUPERCEDE

	set_pdata_int(iItem, m_iClip, 0, 4);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, 4);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_ANIM_RELOAD_START_TIME, 4);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_ANIM_RELOAD_START_TIME, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_ANIM_RELOAD_START_TIME, 4);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_ANIM_RELOAD_START_TIME, 5);
	// set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_RELOAD_TIME, 4);
	// set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_RELOAD_TIME, 4);
	// set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_RELOAD_TIME, 4);
	// set_pdata_float(iPlayer, m_flNextAttack, ANIM_RELOAD_TIME, 5);

	set_pdata_int(iItem, m_fInReload, 0, 4);
	set_pdata_int(iItem, m_fInSpecialReload, 1, 4);

	UTIL_SendWeaponAnim(iPlayer, ANIM_RELOAD_START);
	return HAM_SUPERCEDE;
}
public fw_Weapon_WeaponIdle(iItem) {
	if(!CustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, 4) > 0.0) return HAM_IGNORED;
	UTIL_SendWeaponAnim(get_pdata_cbase(iItem, m_pPlayer, 4), ANIM_IDLE);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_IDLE_TIME, 4);
	return HAM_SUPERCEDE;
}
public fw_Weapon_PrimaryAttack(iItem) {
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	if(get_pdata_int(iItem, m_iClip, 4) == 0) {
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, 4);
		return HAM_SUPERCEDE;
	}
	static fw_TraceLine; fw_TraceLine = register_forward(FM_TraceLine, "fw_TraceLine_Post", 1);
	fm_ham_hook(true);
	state FireBullets: Enabled;
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	state FireBullets: Disabled;
	unregister_forward(FM_TraceLine, fw_TraceLine, 1);
	fm_ham_hook(false);
	static Float:vecPunchangle[3];

	pev(iPlayer, pev_punchangle, vecPunchangle);
	vecPunchangle[0] *= WEAPON_RECOIL;
	vecPunchangle[1] *= WEAPON_RECOIL;
	vecPunchangle[2] *= WEAPON_RECOIL;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	UTIL_EjectBrass(iItem, iPlayer);

	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUND_S, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	UTIL_SendWeaponAnim(iPlayer, ANIM_ATTACK);

	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_RATE, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_SHOOT_TIME, 4);

	if(get_pdata_int(iItem, m_fInSpecialReload, 4) != 0)
		set_pdata_int(iItem, m_fInSpecialReload, 0, 4);

	return HAM_SUPERCEDE;
}
public fw_PlaybackEvent() <FireBullets: Enabled> { return FMRES_SUPERCEDE; }
public fw_PlaybackEvent() <FireBullets: Disabled> { return FMRES_IGNORED; }
public fw_PlaybackEvent() <> { return FMRES_IGNORED; }
public fw_TraceAttack(iVictim, iAttacker, Float:flDamage) {
	if(pev_valid(iAttacker) != 2 || !is_user_connected(iAttacker)) return;
	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, 5);
	if(iItem <= 0 || !CustomItem(iItem)) return;
        SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}
public fw_UpdateClientData_Post(iPlayer, SendWeapons, CD_Handle) {
	if(pev_valid(iPlayer) != 2 || get_cd(CD_Handle, CD_DeadFlag) != DEAD_NO) return;
	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, 5);
	if(iItem <= 0 || !CustomItem(iItem)) return;
	set_cd(CD_Handle, CD_flNextAttack, 999999.0);
}
public fw_SetModel(iEnt) {
	if(pev_valid(iEnt) != 2) return FMRES_IGNORED;
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

	static Float:flvecWallPos[3];get_tr2(tr, TR_vecPlaneNormal, flvecWallPos);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flvecEndPos, 0);
	write_byte(TE_STREAK_SPLASH)
	engfunc(EngFunc_WriteCoord, flvecEndPos[0]);
	engfunc(EngFunc_WriteCoord, flvecEndPos[1]);
	engfunc(EngFunc_WriteCoord, flvecEndPos[2]);
	engfunc(EngFunc_WriteCoord, flvecWallPos[0] * random_float(25.0,30.0));
	engfunc(EngFunc_WriteCoord, flvecWallPos[1] * random_float(25.0,30.0));
	engfunc(EngFunc_WriteCoord, flvecWallPos[2] * random_float(25.0,30.0));
	write_byte(2); //colorid
	write_short(12); //count
	write_short(3); //speed
	write_short(75); // random velocity
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
stock UTIL_SendWeaponAnim(iPlayer, iSequence) {
	set_pev(iPlayer, pev_weaponanim, iSequence);
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iSequence);
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

stock UTIL_EjectBrass(iWeapon, iPlayer) {
	set_pdata_int(iWeapon, m_iShellId, g_iszModelIndexShell, 4);
	set_pdata_float(iPlayer, m_flEjectBrass, get_gametime());
}
stock UTIL_PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;
	
	if((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for(new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);
			
			for(k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if(iEvent != 5004)
					continue;
				
				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if(strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					engfunc(EngFunc_PrecacheSound, szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
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