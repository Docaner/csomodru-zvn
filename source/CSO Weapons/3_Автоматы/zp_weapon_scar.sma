#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "[KZ] Weapon: FN Scar"
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

enum
{
	ANIM_IDLE_A = 0,
	ANIM_RELOAD_A,
	ANIM_DRAW_A,
	ANIM_SHOOT1_A,
	ANIM_SHOOT2_A,
	ANIM_CHANGE_A,

	ANIM_IDLE_B,
	ANIM_RELOAD_B,
	ANIM_DRAW_B,
	ANIM_SHOOT1_B,
	ANIM_SHOOT2_B,
	ANIM_CHANGE_B
};

// from model: Frames / FPS
#define ANIM_IDLE_TIME 0.125
#define ANIM_SHOOT_TIME 1.03
#define ANIM_RELOAD_A_TIME 2.92
#define ANIM_RELOAD_B_TIME 3.64
#define ANIM_DRAW_A_TIME 1.1
#define ANIM_DRAW_B_TIME 1.24
#define ANIM_CHANGE_TIME 5.7

#define WEAPON_KEY 1036
#define WEAPON_CSW CSW_GALIL
#define WEAPON_OLD "weapon_galil"
#define WEAPON_NEW "zp_br_cso/weapons2/weapon_scar"
#define WEAPON_NEW_EX "zp_br_cso/weapons2/weapon_scar2"
#define WEAPON_HUD "sprites/zp_br_cso/weapons2/hud2/640hud1.spr"
#define WEAPON_HUD_EX "sprites/zp_br_cso/weapons2/hud2/640hud6.spr"
#define WEAPON_HUD_AMMO "sprites/zp_br_cso/weapons2/hud2/ammo1.spr"

#define WEAPON_NAME "FN Scar"
#define WEAPON_COST 0

#define WEAPON_MODEL_V "models/zp_br_cso/weapons2/v_scar.mdl"

#define WEAPON_MODEL_W "models/zp_br_cso/other/w_weapons_b1.mdl"
#define WEAPON_SOUND_S "weapons/scar-1.wav"
#define WEAPON_SOUND_S2 "weapons/scar-2.wav"
#define WEAPON_BODY 20

#define WEAPON_CLIP 30
#define WEAPON_AMMO 90

#define WEAPON_RATE_A 0.103
#define WEAPON_RECOIL_A 0.95
#define WEAPON_DAMAGE_A 1.4

#define WEAPON_RATE_B 0.12
#define WEAPON_RECOIL_B 0.9
#define WEAPON_DAMAGE_B 1.53

new const iWeaponList[ ] = {  
	4,  90, -1, -1, 0, 17,14, 0 // weapon_galil
}

new g_AllocString_V, 
	g_AllocString_E,

	HamHook: g_fw_TraceAttack[4],

	
	g_iMsgID_Weaponlist,
	g_iMsgID_CurWeapon,
	g_iMsgID_BarTime,
	g_iItemID

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

	register_clcmd(WEAPON_NEW, "HookSelect");
	register_clcmd(WEAPON_NEW_EX, "HookSelect");

	g_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	g_iMsgID_CurWeapon = get_user_msgid("CurWeapon");
	g_iMsgID_BarTime = get_user_msgid("BarTime");
	
	g_iItemID = zp_register_extra_item(WEAPON_NAME, 0, ZP_TEAM_HUMAN);
}
public plugin_precache() {
	new szBuffer[64]; 

	formatex(szBuffer, charsmax(szBuffer), "sprites/%s.txt", WEAPON_NEW);
	engfunc(EngFunc_PrecacheGeneric, szBuffer);

	formatex(szBuffer, charsmax(szBuffer), "sprites/%s.txt", WEAPON_NEW_EX);
	engfunc(EngFunc_PrecacheGeneric, szBuffer);

	engfunc(EngFunc_PrecacheGeneric, WEAPON_HUD);
	engfunc(EngFunc_PrecacheGeneric, WEAPON_HUD_EX);
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

	UTIL_SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? ANIM_DRAW_B : ANIM_DRAW_A);

	set_pdata_float(iPlayer, m_flNextAttack, Get_WeaponState(iItem) ? ANIM_DRAW_B_TIME : ANIM_DRAW_A_TIME, 5);
	set_pdata_float(iItem, m_flTimeWeaponIdle, Get_WeaponState(iItem) ? ANIM_DRAW_B_TIME : ANIM_DRAW_A_TIME, 4);
}
public fw_Item_PostFrame(iItem) {
	if(!CustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, 4);
	if(get_pdata_int(iItem, m_fInReload, 4) == 1) {
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, 4);
		static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, 5);
		static j; j = min(WEAPON_CLIP - iClip, iAmmo);
		set_pdata_int(iItem, m_iClip, iClip+j, 4);
		set_pdata_int(iPlayer, iAmmoType, iAmmo-j, 5);
		set_pdata_int(iItem, m_fInReload, 0, 4);
	}

	static iButton; iButton = pev(iPlayer, pev_button);

	if(get_pdata_float(iItem, m_flNextSecondaryAttack, 4) <= 0.0) {
		if(iButton & IN_USE) {
			UTIL_SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? ANIM_CHANGE_B : ANIM_CHANGE_A);
			Set_WeaponState(iItem, Get_WeaponState(iItem) ? 0 : 1);
			s_weaponlist(iPlayer, true, Get_WeaponState(iItem) ? WEAPON_NEW_EX : WEAPON_NEW);

			message_begin(MSG_ONE, g_iMsgID_CurWeapon, _, iPlayer);
			write_byte(true);
			write_byte(iWeaponList[6]);
			write_byte(iClip);
			message_end();

			set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_CHANGE_TIME, 4);
			set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_CHANGE_TIME, 4);
			set_pdata_float(iItem, m_flNextSecondaryAttack, ANIM_CHANGE_TIME, 4);
			set_pdata_float(iPlayer, m_flNextAttack, ANIM_CHANGE_TIME, 5);

			UTIL_BarTime(iPlayer, ANIM_CHANGE_TIME);

			iButton &= ~IN_USE;
			set_pev(iPlayer, pev_button, iButton);
		}
	}

	return HAM_IGNORED;
}
public fw_Item_AddToPlayer_Post(iItem, iPlayer) {
	switch(pev(iItem, pev_impulse)) {
		case WEAPON_KEY: {
			client_print(iPlayer, print_center, "Смена режима - Кнопка [E]", iPlayer);

			s_weaponlist(iPlayer, true, Get_WeaponState(iItem) ? WEAPON_NEW_EX : WEAPON_NEW);
		}
		case 0: s_weaponlist(iPlayer, false, WEAPON_OLD);
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
	// set_pdata_float(iItem, m_flNextPrimaryAttack, Get_WeaponState(iItem) ? ANIM_RELOAD_B_TIME : ANIM_RELOAD_A_TIME, 4);
	// set_pdata_float(iItem, m_flNextSecondaryAttack, Get_WeaponState(iItem) ? ANIM_RELOAD_B_TIME : ANIM_RELOAD_A_TIME, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, Get_WeaponState(iItem) ? ANIM_RELOAD_B_TIME : ANIM_RELOAD_A_TIME, 4);
	set_pdata_float(iPlayer, m_flNextAttack, Get_WeaponState(iItem) ? ANIM_RELOAD_B_TIME : ANIM_RELOAD_A_TIME, 5);

	UTIL_SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? ANIM_RELOAD_B : ANIM_RELOAD_A);
	return HAM_SUPERCEDE;
}
public fw_Weapon_WeaponIdle(iItem) {
	if(!CustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, 4) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, 4);
	UTIL_SendWeaponAnim(iPlayer, Get_WeaponState(iItem) ? ANIM_IDLE_B : ANIM_IDLE_A);
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
	static Float: flRecoil; flRecoil = Get_WeaponState(iItem) ? WEAPON_RECOIL_B : WEAPON_RECOIL_A;

	pev(iPlayer, pev_punchangle, vecPunchangle);
	vecPunchangle[0] *= flRecoil;
	vecPunchangle[1] *= flRecoil;
	vecPunchangle[2] *= flRecoil;
	set_pev(iPlayer, pev_punchangle, vecPunchangle);

	static iAnim; iAnim = Get_WeaponState(iItem) ? random_num(ANIM_SHOOT1_B, ANIM_SHOOT2_B) : random_num(ANIM_SHOOT1_A, ANIM_SHOOT2_A);

	emit_sound(iPlayer, CHAN_WEAPON, Get_WeaponState(iItem) ? WEAPON_SOUND_S2 : WEAPON_SOUND_S, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	UTIL_SendWeaponAnim(iPlayer, iAnim);

	

	set_pdata_float(iItem, m_flNextPrimaryAttack, Get_WeaponState(iItem) ? WEAPON_RATE_B : WEAPON_RATE_A, 4);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_SHOOT_TIME, 4);

	return HAM_SUPERCEDE;
}
public fw_PlaybackEvent() <FireBullets: Enabled> { return FMRES_SUPERCEDE; }
public fw_PlaybackEvent() <FireBullets: Disabled> { return FMRES_IGNORED; }
public fw_PlaybackEvent() <> { return FMRES_IGNORED; }
public fw_TraceAttack(iVictim, iAttacker, Float:flDamage) {
	if(!is_user_connected(iAttacker)) return;
	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, 5);
	if(iItem <= 0 || !CustomItem(iItem)) return;
        SetHamParamFloat(3, flDamage * (Get_WeaponState(iItem) ? WEAPON_DAMAGE_B : WEAPON_DAMAGE_A));
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
stock UTIL_SendWeaponAnim(iPlayer, iAnim)
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
stock UTIL_BarTime(iPlayer, Float: flValue) {
	message_begin(MSG_ONE, g_iMsgID_BarTime, _, iPlayer)
	write_short(floatround(flValue))
	message_end()
}
stock s_weaponlist(iPlayer, bool: on, const szWeaponList[]) {
	message_begin(MSG_ONE, g_iMsgID_Weaponlist, _, iPlayer);
	write_string(szWeaponList);
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