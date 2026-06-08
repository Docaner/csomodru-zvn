#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "[KZ] Weapon: M4A1 Dragon"
#define VERSION "1.0"
#define AUTHOR "Batcon & t3rkecorejz"

#define CustomItem(%0) (pev(%0, pev_impulse) == WEAPON_KEY)

#define Get_WeaponState(%0) get_pdata_int(%0, m_iWeaponState, 4)
#define Set_WeaponState(%0,%1) set_pdata_int(%0, m_iWeaponState, %1, 4)

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
#define m_iShellId 57
#define m_iWeaponState 74

// CBaseMonster
#define m_flNextAttack 83

// CBasePlayer
#define m_flEjectBrass 111
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376
#define m_szAnimExtention 492

enum
{
	ANIM_IDLE_A,
	ANIM_SHOOT1_A,
	ANIM_SHOOT2_A,
	ANIM_SHOOT3_A,
	ANIM_RELOAD_A,
	ANIM_DRAW_A,
	ANIM_ADD_SILENCER,

	ANIM_IDLE_B,
	ANIM_SHOOT1_B,
	ANIM_SHOOT2_B,
	ANIM_SHOOT3_B,
	ANIM_RELOAD_B,
	ANIM_DRAW_B,
	ANIM_DETACH_SILENCER
};

// from model: Frames / FPS
#define ANIM_IDLE_TIME 0.125
#define ANIM_SHOOT_TIME 1.55
#define ANIM_RELOAD_TIME 3.08
#define ANIM_SILENCER_TIME 2.03
#define ANIM_DRAW_TIME 1.025

#define WEAPON_KEY 1031
#define WEAPON_CSW CSW_M4A1
#define WEAPON_OLD "weapon_m4a1"
#define WEAPON_NEW "zp_br_cso/weapons3/weapon_m4a1dragon"
#define WEAPON_HUD "sprites/zp_br_cso/weapons3/hud/640hud45.spr"
#define WEAPON_HUD_AMMO "sprites/640hud7.spr"

#define WEAPON_NAME "M4A1 Dragon"
#define WEAPON_COST 0


#define WEAPON_MODEL_V "models/zp_br_cso/weapons3/v_m4a1dragon.mdl"

#define WEAPON_MODEL_W "models/zp_br_cso/other/w_weapons_b1.mdl"
#define WEAPON_SOUND_S "weapons/m4a1-1.wav"
#define WEAPON_SOUND_S2 "weapons/m4a1_unsil-1.wav"
#define WEAPON_BODY 16

#define WEAPON_CLIP 30
#define WEAPON_AMMO 90

#define WEAPON_RATE_A 0.105
#define WEAPON_RECOIL_A 1.04
#define WEAPON_DAMAGE_A 1.25

#define WEAPON_RATE_B 0.105
#define WEAPON_RECOIL_B 1.01
#define WEAPON_DAMAGE_B 1.275

new const iWeaponList[ ] = {  
	4, 90, -1, -1, 0, 6, 22, 0 // weapon_m4a1
}

new g_AllocString_V, g_AllocString_E
new HamHook:g_fw_TraceAttack[4]
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
	RegisterHam(Ham_Weapon_SecondaryAttack, WEAPON_OLD,"fw_Weapon_SecondaryAttack")
	
	g_fw_TraceAttack[0] = RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack");
	g_fw_TraceAttack[1] = RegisterHam(Ham_TraceAttack, "info_target",    "fw_TraceAttack");
	g_fw_TraceAttack[2] = RegisterHam(Ham_TraceAttack, "player",         "fw_TraceAttack");
	g_fw_TraceAttack[3] = RegisterHam(Ham_TraceAttack, "hostage_entity", "fw_TraceAttack");
	
	fm_ham_hook(false);

	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
	register_forward(FM_SetModel, "fw_SetModel");

	register_clcmd(WEAPON_NEW, "HookSelect");

	g_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	g_iItemID = zp_register_extra_item(WEAPON_NAME, 0, ZP_TEAM_HUMAN);
}
public plugin_precache() {
	new szBuffer[64]; formatex(szBuffer, charsmax(szBuffer), "sprites/%s.txt", WEAPON_NEW);

	engfunc(EngFunc_PrecacheGeneric, szBuffer);
	engfunc(EngFunc_PrecacheGeneric, WEAPON_HUD);
	engfunc(EngFunc_PrecacheGeneric, WEAPON_HUD_AMMO);
	
	g_AllocString_V = engfunc(EngFunc_AllocString, WEAPON_MODEL_V);
	g_AllocString_E = engfunc(EngFunc_AllocString, WEAPON_OLD);

	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_V);

	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_S);
	engfunc(EngFunc_PrecacheSound, WEAPON_SOUND_S2);
}
public zp_extra_item_selected(iPlayer, iItemID) {
	if(iItemID == g_iItemID)
		give_weapon(iPlayer);
}
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
	
	SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? ANIM_DRAW_A : ANIM_DRAW_B);

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

	set_pdata_int(iItem, m_fInReload, 1, 4);
	// set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_RELOAD_TIME, 4);
	// set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_RELOAD_TIME, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_RELOAD_TIME, 4);
	set_pdata_float(iPlayer, m_flNextAttack, ANIM_RELOAD_TIME, 5);

	SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? ANIM_RELOAD_A : ANIM_RELOAD_B);
	return HAM_SUPERCEDE;
}
public fw_Weapon_WeaponIdle(iItem) {
	if(!CustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, 4) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? ANIM_IDLE_A : ANIM_IDLE_B);
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
	static Float: flRecoil; flRecoil = Get_WeaponState(iItem) ? WEAPON_RECOIL_A : WEAPON_RECOIL_B;

	pev(iPlayer, pev_punchangle, vecPunchangle);
	vecPunchangle[0] *= flRecoil;
	vecPunchangle[1] *= flRecoil;
	vecPunchangle[2] *= flRecoil;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	emit_sound(iPlayer, CHAN_WEAPON, Get_WeaponState(iItem) ? WEAPON_SOUND_S : WEAPON_SOUND_S2, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? random_num(ANIM_SHOOT1_A, ANIM_SHOOT3_A) : random_num(ANIM_SHOOT1_B, ANIM_SHOOT3_B));

	set_pdata_float(iItem, m_flNextPrimaryAttack, Get_WeaponState(iItem) ? WEAPON_RATE_A : WEAPON_RATE_B, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_SHOOT_TIME, 4);

	

	return HAM_SUPERCEDE;
}
public fw_Weapon_SecondaryAttack(iItem) {
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);

	SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? ANIM_DETACH_SILENCER : ANIM_ADD_SILENCER);
	Set_WeaponState(iItem, Get_WeaponState(iItem) ? 0 : 1);

	set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_SILENCER_TIME, 4);
	set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_SILENCER_TIME, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_SILENCER_TIME, 4);

	return HAM_SUPERCEDE;
}
public fw_PlaybackEvent() <FireBullets: Enabled> { return FMRES_SUPERCEDE; }
public fw_PlaybackEvent() <FireBullets: Disabled> { return FMRES_IGNORED; }
public fw_PlaybackEvent() <> { return FMRES_IGNORED; }
public fw_TraceAttack(iVictim, iAttacker, Float:flDamage) {
	if(!is_user_connected(iAttacker)) return;
	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, 5);
	if(iItem <= 0 || !CustomItem(iItem)) return;
        SetHamParamFloat(3, flDamage * (Get_WeaponState(iItem) ? WEAPON_DAMAGE_A : WEAPON_DAMAGE_B));
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
stock SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
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
stock UTIL_PrecacheSoundsFromModel( const szModelPath[] )
{
	new iFile;
	
	if ( ( iFile = fopen( szModelPath, "rt" ) ) )
	{
		new szSoundPath[ 64 ];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek( iFile, 164, SEEK_SET );
		fread( iFile, iNumSeq, BLOCK_INT );
		fread( iFile, iSeqIndex, BLOCK_INT );
		
		for ( new k, i = 0; i < iNumSeq; i++ )
		{
			fseek( iFile, iSeqIndex + 48 + 176 * i, SEEK_SET );
			fread( iFile, iNumEvents, BLOCK_INT );
			fread( iFile, iEventIndex, BLOCK_INT );
			fseek( iFile, iEventIndex + 176 * i, SEEK_SET );
			
			for ( k = 0; k < iNumEvents; k++ )
			{
				fseek( iFile, iEventIndex + 4 + 76 * k, SEEK_SET );
				fread( iFile, iEvent, BLOCK_INT );
				fseek( iFile, 4, SEEK_CUR );
				
				if ( iEvent != 5004 )
					continue;
				
				fread_blocks( iFile, szSoundPath, 64, BLOCK_CHAR );
				
				if ( strlen( szSoundPath ) )
				{
					format( szSoundPath, charsmax( szSoundPath ), "sound/%s", szSoundPath );
					precache_generic( szSoundPath );
				}
			}
		}
	}
	
	fclose(iFile);
}