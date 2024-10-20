stock IsTitanBoss(iEnt, const szBossClassname[]) { // name should be "IsValidBoss" :)

	new szClassname[64]; pev(iEnt, pev_classname, szClassname, charsmax(szClassname));
	return equal(szClassname, szBossClassname);

}

stock IsValidMap(const szBossMapname[]) {

	new szMapname[32]; get_mapname(szMapname, charsmax(szMapname));
	return equal(szMapname, szBossMapname);

}

stock PlayAnimation(iEnt, iSequence, Float:flFramerate = 1.0) {

	set_pev(iEnt, pev_sequence, 	iSequence);
	set_pev(iEnt, pev_animtime, 	get_gametime());
	set_pev(iEnt, pev_framerate, 	flFramerate);

}

stock GetRandomVictim() {

	new iPlayers[32], iNum;
	get_players(iPlayers, iNum, "ach");
	return iNum ? iPlayers[random_num(0, iNum - 1)] : -1;

}

stock SetRendering(iPlayer, iRenderFx = kRenderFxNone, iRed = 0, iGreen = 0, iBlue = 0, iRenderMode = kRenderNormal, iRenderAmt = 0) {

	new Float:flRenderColor[3];
	flRenderColor[0] = float(iRed);
	flRenderColor[1] = float(iGreen);
	flRenderColor[2] = float(iBlue);
	
	set_pev(iPlayer, pev_renderfx, 		iRenderFx);
	set_pev(iPlayer, pev_rendercolor, 	flRenderColor);
	set_pev(iPlayer, pev_rendermode, 	iRenderMode);
	set_pev(iPlayer, pev_renderamt, 	float(iRenderAmt));
	
}

stock Float:GetEntSpeed(iEnt) {

	if(!pev_valid(iEnt)) return 0.0;
	static Float:vecVelocity[3]; pev(iEnt, pev_velocity, vecVelocity)
	
	vecVelocity[2] = 0.0;
	return vector_length(vecVelocity);
	
}

stock CheckSpace(iPlayer, Float:vecOrigin[3], iHull) {

	engfunc(EngFunc_TraceHull, vecOrigin, vecOrigin, 0, iHull, iPlayer, 0);
	return (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen));
	
}

stock UTIL_ELight(iPlayer, const Float:vecOrigin[3], iRadius = 40, iRed, iGreen, iBlue, iLife = 60) {

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, _, iPlayer);
	write_byte(TE_ELIGHT);
	write_short(iPlayer);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_coord(iRadius);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iLife);
	write_coord(0);
	message_end();

}

stock UTIL_ScreenShake(iPlayer, iAmplitude, iDuration, iFrequency, iReliable = 0) {

	switch(iPlayer) {
	
		case 0: {
		
			message_begin(MSG_BROADCAST, 97);
			write_short((1<<12) * iAmplitude);
			write_short((1<<12) * iDuration);
			write_short((1<<12) * iFrequency);
			message_end();
		
		}
		
		default: {
		
			engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, 97, {0.0, 0.0, 0.0}, iPlayer);
			write_short((1<<12) * iAmplitude);
			write_short((1<<12) * iDuration);
			write_short((1<<12) * iFrequency);
			message_end();
		
		}
	
	}
	
	
}

stock UTIL_ScreenFade(iPlayer, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0) {

	switch(iPlayer) {
	
		case 0: {
		
			message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, 98);
			write_short((1<<12) * iDuration);
			write_short((1<<12) * iHoldTime);
			write_short(iFlags);
			write_byte(iRed);
			write_byte(iGreen);
			write_byte(iBlue);
			write_byte(iAlpha);
			message_end();
			
		}
		
		default: {
		
			engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, 98, {0.0, 0.0, 0.0}, iPlayer);
			write_short((1<<12) * iDuration);
			write_short((1<<12) * iHoldTime);
			write_short(iFlags);
			write_byte(iRed);
			write_byte(iGreen);
			write_byte(iBlue);
			write_byte(iAlpha);
			message_end();
			
		}
		
	}
	
}

stock UTIL_SendAudio(iPlayer, iPitch = 100, const szPathSound[], any:...) {

	new szBuffer[128];
	if(numargs() > 3) vformat(szBuffer, charsmax(szBuffer), szPathSound, 4);
	else copy(szBuffer, charsmax(szBuffer), szPathSound);
	switch(iPlayer) {
	
		case 0: {
		
			message_begin(MSG_BROADCAST, 100);
			write_byte(iPlayer);
			write_string(szBuffer);
			write_short(iPitch);
			message_end();
			
		}
		
		default: {
		
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, 100, {0.0, 0.0, 0.0}, iPlayer);
			write_byte(iPlayer);
			write_string(szBuffer);
			write_short(iPitch);
			message_end();
			
		}
		
	}
	
}

stock CreateBlood(Float:vecOrigin[3], pBlood, pBloodspray) {	

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(pBlood);
	write_short(pBloodspray);
	write_byte(84);
	write_byte(random_num(2, 3));
	message_end();
	
}

stock CreateExplosion(Float:vecOrigin[3], Float:flOffset, pSprite, iScale, iFramerate, iFlags) {

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + flOffset);
	write_short(pSprite);
	write_byte(iScale);
	write_byte(iFramerate);
	write_byte(iFlags);
	message_end();

}

stock CreateBeamfollow(iEnt, pSprite, iLife = 5, iWidth = 3, iRed, iGreen, iBlue, iAlpha) {

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEnt);
	write_short(pSprite);
	write_byte(iLife);
	write_byte(iWidth);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();

}

stock CreateWorldDecal(Float:vecOrigin[3], pIndex) {

	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_WORLDDECAL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_byte(pIndex);
	message_end();

}

stock CreateSmoke(Float:vecOrigin[3], pSprite) {

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SMOKE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 35.0);
	write_short(pSprite);
	write_byte(35);
	write_byte(20);
	message_end();

}

stock CreateRockGibs(Float:vecOrigin[3], pModel, iCount = 13, iLife = 4) {

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_coord(60);
	write_coord(60);
	write_coord(60);
	write_coord(random_num(-80, 80));
	write_coord(random_num(-80, 80));
	write_coord(60);
	write_byte(30);
	write_short(pModel);
	write_byte(iCount);
	write_byte(iLife);
	write_byte(0x40);
	message_end();

}

stock UTIL_SayText(pPlayer, const szMessage[], any:...) {

	new szBuffer[190];
	
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	
	switch(pPlayer) {
	
		case 0: {
		
			for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++) {
			
				if(!is_user_connected(iPlayer)) continue;
				engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, 76, {0.0, 0.0, 0.0}, iPlayer);
				write_byte(iPlayer);
				write_string(szBuffer);
				message_end();
				
			}
			
		}
		default: {
		
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, 76, {0.0, 0.0, 0.0}, pPlayer);
			write_byte(pPlayer);
			write_string(szBuffer);
			message_end();
			
		}
		
	}
	
}