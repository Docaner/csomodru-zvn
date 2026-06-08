#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <reapi>
#include <zombieplague>
#include <smart_effects>

new const g_szItemName[] = "Pumpkin Grenade"; // Название
#define GRENADE_COST 10 // Цена
#define GRENADE_TEAM ZP_TEAM_HUMAN // Битсумма команд

#define GRENADE_RADIUS 200.0 // Радиус действия гранаты
#define GRENADE_MAXDAMAGE 1600.0 // Максимальный урон со взрыва гранаты

#define GRENADE_MAXKNOCKBAK 100.0 // Максимальный отброс в стороны от гранаты
#define GRENADE_MAXKNOCKBAKUP 430.0 // Максимальный отброс вверх от гранаты

//Модели
new const g_szModelGrenade_V[] = "models/zp_br_cso/grenade/v_pumpkin.mdl";

new const g_szModelGrenade_W[] = "models/zp_br_cso/grenade/w_grenad_s3.mdl";
#define GRENADE_BODY 4

new const g_szSpriteExplode[] = "sprites/zp_br_cso/grenade/ef_epumpkin.spr"; // Спрайт взрыва

new const g_szSndExplode[] = "zp_br_cso/grenade/pumpkin_explosion.wav"; // Звук взрыва

new const g_szSoundAmmoPurchase[] = "items/9mmclip1.wav";
new const g_szDefaulModel[] = "models/w_smokegrenade.mdl"; 
new const g_szAmmoType[] = "SmokeGrenade";
#define WEAPON_REFERENCE WEAPON_SMOKEGRENADE

#define UNIT_SECOND (1<<12)

#define NADE_TYPE_FLARE 2004
#define WEAPON_FIREGRENADE 5003

#if !defined zp_is_round_end
native zp_is_round_end();
#endif

#define CustomWeaponBox(%1) (get_entvar(%1, var_flTimeStepSound) == NADE_TYPE_FLARE)
#define CustomWeapon(%1) (get_entvar(%1, var_impulse) == WEAPON_FIREGRENADE)

new g_iPumpkinGrnd;
new g_pSriteExplode;

new g_iMsgID_ScreanFade

public plugin_precache()
{
	precache_model(g_szModelGrenade_V);

	precache_model(g_szModelGrenade_W);
	g_pSriteExplode = precache_model(g_szSpriteExplode);
	
	precache_sound(g_szSndExplode);
	precache_sound(g_szSoundAmmoPurchase);

	UTIL_PrecacheSoundsFromModel(g_szModelGrenade_V);
}

public plugin_init()
{
	register_plugin("[ZPE] Extra Item: Pumpkin", "1.0", "Docaner")

	register_forward(FM_SetModel, "fw_SetModel_Pre", false);
	RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "HM_HeDeploy_Post", true);

	RegisterHam(Ham_Think, "grenade", "HM_ThinkGrenade_Pre", false)

	//register_clcmd("gr", "give_grenade");

	g_iMsgID_ScreanFade = get_user_msgid("ScreenFade");

	g_iPumpkinGrnd = zp_register_extra_item(g_szItemName, GRENADE_COST, GRENADE_TEAM)
}

public zp_extra_item_selected(id, itemid)
{
	if(g_iPumpkinGrnd == itemid)
	{
		return give_grenade(id);
	}
	return PLUGIN_CONTINUE;
}

public fw_SetModel_Pre(iEnt, szModel[])
{
	if(!is_entity(iEnt) || !equal(szModel, g_szDefaulModel)) return FMRES_IGNORED;

	new id = get_entvar(iEnt, var_owner);

	if(!is_user_connected(id)) return FMRES_IGNORED;

	new iWeapon = rg_find_weapon_bpack_by_name(id, "weapon_smokegrenade");

	if(!is_entity(iWeapon) || !CustomWeapon(iWeapon)) 
		return FMRES_IGNORED;

	engfunc(EngFunc_SetModel, iEnt, g_szModelGrenade_W);

	set_entvar(iEnt, var_body, GRENADE_BODY);
	set_entvar(iEnt, var_flTimeStepSound, NADE_TYPE_FLARE);
	fm_set_rendering(iEnt, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 0);

	return FMRES_SUPERCEDE;

}

public HM_HeDeploy_Post(iEnt)
{
	if(!CustomWeapon(iEnt)) return;

	new id = get_member(iEnt, m_pPlayer);

	set_entvar(id, var_viewmodel, g_szModelGrenade_V);
}

public HM_ThinkGrenade_Pre(iEnt)
{
	if(!is_entity(iEnt)) return HAM_IGNORED;

	new Float:fDmgTime;
	get_entvar(iEnt, var_dmgtime, fDmgTime);

	if(fDmgTime > get_gametime())
		return HAM_IGNORED;

	if(!CustomWeaponBox(iEnt))
		return HAM_IGNORED;

	custom_explode(iEnt);
	set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);

	return HAM_SUPERCEDE;
}

custom_explode(iEnt)
{
	new Float:fOrigin[3]
	get_entvar(iEnt, var_origin, fOrigin);

	new Float:fOriginSprite[3];
	fOriginSprite = fOrigin;
	fOriginSprite[2] += 80.0;
	CREATE_SPRITE(fOriginSprite, g_pSriteExplode, 20, 200);

	emit_sound(iEnt, CHAN_WEAPON, g_szSndExplode, 1.0, ATTN_NORM, 0, PITCH_NORM);

	if(zp_is_round_end())
		return;

	new iVictim, Float:fDistance, Float:fDamage, 
		Float:fOriginVic[3], iOwner = get_entvar(iEnt, var_owner),
		Float:fPerCent, Float:fDir[3], Float:fVelocity[3];
	while((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, fOrigin, GRENADE_RADIUS)) > 0)
	{
		if(is_nullent(iVictim) || Float:get_entvar(iVictim, var_takedamage) == DAMAGE_NO) continue;

		if((!is_user_alive(iVictim) || !zp_get_user_zombie(iVictim)) && !IsAliveNPC(iVictim))
			continue;
		

		get_entvar(iVictim, var_origin, fOriginVic);

		fDistance = get_distance_f(fOrigin, fOriginVic);

		fPerCent = GRENADE_RADIUS - fDistance;
		fPerCent = fPerCent < 0.0 ? -fPerCent : fPerCent;
		fPerCent = fPerCent / GRENADE_RADIUS;
		fPerCent = fPerCent + 0.1 > 1.0 ? 1.0 : fPerCent + 0.1; 

		fDamage = GRENADE_MAXDAMAGE * fPerCent;

		set_entvar(iVictim, var_punchangle, { 15.0, 15.0, 15.0 });

		fDir[0] = random_float(10.0, -10.0);
		fDir[1] = random_float(10.0, -10.0);
		fDir[2] = random_float(-100.0, -160.0);

		CREATE_BLOOD(fOriginVic, fDir, _, random_num(50, 100));

		ExecuteHamB(Ham_TakeDamage, iVictim, iEnt, iOwner, fDamage, DMG_GRENADE);
		
		if(IsPlayer(iVictim))
		{
			SCREEN_FADE(iVictim, 1, 1, SF_FADE_MODULATE, 200, 200, 0, 80);
			create_knockback_up(fOriginVic, fOrigin, (GRENADE_MAXKNOCKBAK * fPerCent), (GRENADE_MAXKNOCKBAKUP * fPerCent), fVelocity);
			set_entvar(iVictim, var_velocity, fVelocity);		
		}
	}
}

public give_grenade(id)
{
	if(rg_get_user_bpammo(id, WEAPON_REFERENCE) >= 2)
		return ZP_PLUGIN_HANDLED;
	new iWeapon = rg_find_weapon_bpack_by_name(id, "weapon_smokegrenade");
	if(is_entity(iWeapon) && CustomWeapon(iWeapon))
	{
		ExecuteHamB(Ham_GiveAmmo, id, 1, g_szAmmoType, charsmax(g_szAmmoType));
		emit_sound(id, CHAN_ITEM, g_szSoundAmmoPurchase, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
	else
	{
		new iEnt = rg_give_custom_item(id, "weapon_smokegrenade", GT_APPEND, WEAPON_FIREGRENADE);
		if(is_nullent(iEnt))
			return ZP_PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
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

/*stock CREATE_WORLDDECAL(Float:fOrigin[3], pDecal)
{
	message_begin_f(MSG_PAS, SVC_TEMPENTITY, fOrigin)
	write_byte(TE_WORLDDECAL)
	write_coord_f(fOrigin[0])
	write_coord_f(fOrigin[1])
	write_coord_f(fOrigin[2])
	write_byte(pDecal)
	message_end()
}*/

stock CREATE_SPRITE(Float:fOrigin[3], pSprite, iScale, iAlpha)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	write_coord_f(fOrigin[0])
	write_coord_f(fOrigin[1])
	write_coord_f(fOrigin[2])
	write_short(pSprite)
	write_byte(iScale) // 0.1
	write_byte(iAlpha)
	message_end()
}

/*stock CREATE_BEAMCYLINDER(Float:vecOrigin[3], iRadius, pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0)
{
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	write_byte(TE_BEAMCYLINDER);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2]);
	write_coord_f(vecOrigin[0]);
	write_coord_f(vecOrigin[1]);
	write_coord_f(vecOrigin[2] + iRadius);
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
}*/

stock SCREEN_FADE(id, iDuration, iHoldtime, iFadeType, iRed, iGreen, iBlue, iAlpha)
{
	message_begin(MSG_ONE_UNRELIABLE, g_iMsgID_ScreanFade, _, id)
	write_short(UNIT_SECOND*iDuration) // duration
	write_short(UNIT_SECOND*iHoldtime) // hold time
	write_short(iFadeType) // fade type
	write_byte(iRed) // r
	write_byte(iGreen) // g
	write_byte(iBlue) // b
	write_byte(iAlpha) // alpha
	message_end()
}

stock CREATE_BLOOD(Float:fOrigin[3], Float:fDirection[3], iColor = 70, iSpeed = 16)
{
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, fOrigin);
	write_byte(TE_BLOOD);
	write_coord_f(fOrigin[0]);
	write_coord_f(fOrigin[1]);
	write_coord_f(fOrigin[2]);
	write_coord_f(fDirection[0]);
	write_coord_f(fDirection[1]);
	write_coord_f(fDirection[2]);
	write_byte(iColor);
	write_byte(iSpeed);
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