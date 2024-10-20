#if !defined HL_WEAPON_PHYSICS_STOCK
	#define HL_WEAPON_PHYSICS_STOCK

#include <hl_weapon_physics_data>	

// Source

#define _PlayerEntity(%1) (0 < %1 < g_iMaxPlayersSizeOf)
#define _PlayerEntityAlive(%1) ((0 < %1 < g_iMaxPlayersSizeOf) && bit_alive(%1))

#define IndexFix(%1) (%1 - 1)

#define _Flag_Add(%1) (g_iPluginFlags |= _:%1)
#define _Flag_Sub(%1) (g_iPluginFlags &= _:~%1)
#define _Flag_Exists(%1) (g_iPluginFlags & _:%1)
#define _Flag_NOT_Exists(%1) (1 << %1 & ~g_iPluginFlags)

#define PLUGIN  "hl_weapon_physics"
#define VERSION "0.6.2" // 05.02.2020
#define AUTHOR  "Turanga_Leela"

#define bit_alive_NOT(%1) (1 << (%1 - 1) & ~g_iBitAlive)
#define bit_alive_add(%1) (g_iBitAlive |= 1 << (%1 - 1))
#define bit_alive_sub(%1) (g_iBitAlive &= ~(1 << (%1 - 1)))
#define bit_alive(%1) (g_iBitAlive & 1 << (%1 - 1))

stock Get_Velocity_Vector(iTarget, iSource, Float:fPower, Float:fOrigin_Result[3])
{
	static
	
	Float:fOrigin_Source[3],
	Float:fOrigin_Target[3],
	Float:fResult,
	i;
	
	if(fPower < 1.0)
	{
		fPower = 1.0;
	}
	
	pev(iSource, pev_origin, fOrigin_Source);
	pev(iTarget, pev_origin, fOrigin_Target);
	
	xs_vec_sub(fOrigin_Target, fOrigin_Source, fOrigin_Result);
	xs_vec_normalize(fOrigin_Result, fOrigin_Result);

	if((fResult = (204.8 - (get_distance_f(fOrigin_Source, fOrigin_Target) * 0.025))) < 32.0)
	{
		fResult = 32.0;
	}

	fResult *= fPower;
	
	fOrigin_Result[0] *= fResult;
	fOrigin_Result[1] *= fResult;

	if(fOrigin_Result[2] < 0.0)
	{
		fOrigin_Result[2] = -fOrigin_Result[2];
	}
	
	fOrigin_Result[2] = (fOrigin_Result[2] * fResult * 0.64);
	
	enum
	{
		iMassiveSize = 6
	};

	static const Float:const_fMultiple[iMassiveSize] = {512.0, 256.0, 224.0, 192.0, 160.0, 128.0};
	
	static const const_iMultiple[iMassiveSize][2] =
	{
		{256, 512},
		{224, 256},
		{192, 224},
		{160, 192},
		{128, 160},
		{112, 128}	
	};
	
	enum
	{
		iFirstNum = 0,
		iSecondNum
	};
	
	i = iMassiveSize;
	
	while(i)
	{
		if(fOrigin_Result[2] < const_fMultiple[--i])
		{
			fOrigin_Result[2] = float(random_num(const_iMultiple[i][iFirstNum], const_iMultiple[i][iSecondNum]));
			
			return;
		}
	}
	
	fOrigin_Result[2] = 512.0;
}

stock Get_Entity_Flags(index)
{
	enum
	{
		iMassiveSize = 31
	};
	
	static 
	
	sClass[iMassiveSize + 1],
	iBack;
	
	iBack = 0;
	
	switch(pev(index, pev_movetype))
	{
		case MOVETYPE_PUSH:
		{
			if(pev(index, pev_takedamage))
			{				
				pev(index, pev_classname, sClass, iMassiveSize);
			
				if(equali(sClass, "func_breakable", 14))
				{
					iBack = is_Breakable;
				}
			}	
		}
					
		case MOVETYPE_STEP, MOVETYPE_FLY:
		{
			if(FL_MONSTER & pev(index, pev_flags) && !pev(index, pev_deadflag))
			{
				iBack = is_Monster;
			}	
		}
		
		case MOVETYPE_BOUNCE:
		{
			iBack = is_Physics;
		}
	}
				
	if(iBack & ~is_Breakable)
	{
		iBack |= (pev(index, pev_flags) & FL_ONGROUND);
	}
	
	return iBack;
}

stock Get_Entity_Data(index, iMode = 0)
{
	if(_PlayerEntity(index))
	{
		if(bit_alive(index))
		{
			return -index;
		}
	}
	
	else if(pev_valid(index))
	{
		if(iMode)
		{
			return Get_Entity_Flags(index);
		}
		
		else
		{
			return index;
		}
	}
	
	return 0;
}

#if defined ARMOURY_ENTITY_RANDOMIZER
stock Armoury_Entity_Change()
{
	new i;
	
	g_iWeaponsCounter = 0;
	
	for(i = 0; i < _All_Weapons; i++)
	{
		if(g_iBitWeaponList & 1 << i)
		{
			g_iRandomWeapons_Enum[g_iWeaponsCounter++] = i;
		}
	}
}

stock Check_Armoury_Entity_Cvar()
{
	if(cvar_iWeaponsCountCheck < 0)
	{
		cvar_iWeaponsCountCheck = -cvar_iWeaponsCountCheck;
	}
		
	if(cvar_iWeaponsCountCheck > 32)
	{
		cvar_iWeaponsCountCheck = 32;
	}
		
	else if(!cvar_iWeaponsCountCheck)
	{
		cvar_iWeaponsCountCheck = 1;
	}
}
#endif

stock Main_Menu(id, iMode)
{
	enum
	{
		iMassiveSize = 31
	};
	
	new sMenuTitle[iMassiveSize + 1];
	
	formatex(sMenuTitle, iMassiveSize, "%s%d%c%d%c", "\r#Armoury Entity List [", (g_iClientMenuChoice[IndexFix(id)] = iMode), '/', 4, ']');
	
	new iMenu = menu_create(sMenuTitle, "Menu_Config");
	
	switch(iMode)
	{
		case 1:
		{
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_Awp ? "\wAwp -> [ON]" : "\wAwp -> [OFF]", "1");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_G3sg1 ? "\wG3sg1 -> [ON]" : "\wG3sg1 -> [OFF]", "2");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_Scout ? "\wScout -> [ON]" : "\wScout -> [OFF]", "3");
			
			menu_addblank(iMenu, 0);
			
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_Xm1014 ? "\wXm1014 -> [ON]" : "\wXm1014 -> [OFF]", "4");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_M3 ? "\wM3 -> [ON]" : "\wM3 -> [OFF]", "5");
			
			menu_addblank(iMenu, 0);
			
			menu_additem(iMenu, "\wNext ->", "6");
		}
		
		case 2:
		{
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_Aug ? "\wAug -> [ON]" : "\wAug -> [OFF]", "1");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_Sg552 ? "\wSg552 -> [ON]" : "\wSg552 -> [OFF]", "2");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_M4a1 ? "\wM4a1 -> [ON]" : "\wM4a1 -> [OFF]", "3");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_Ak47 ? "\wAk47 -> [ON]" : "\wAk47 -> [OFF]", "4");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_M249 ? "\wM249 -> [ON]" : "\wM249 -> [OFF]", "5");
			
			menu_addblank(iMenu, 0);
		
			menu_additem(iMenu, "\wBack <-", "6");	
			
			menu_addblank(iMenu, 0);
			
			menu_additem(iMenu, "\wNext ->", "7");
		}
		
		case 3:
		{
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_P90 ? "\wP90 -> [ON]" : "\wP90 -> [OFF]", "1");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_Mp5Navy ? "\wMp5Navy -> [ON]" : "\wMp5Navy -> [OFF]", "2");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_Mac10 ? "\wMac10 -> [ON]" : "\wMac10 -> [OFF]", "3");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_Tmp ? "\wTmp -> [ON]" : "\wTmp -> [OFF]", "4");
			
			menu_addblank(iMenu, 0);
		
			menu_additem(iMenu, "\wBack <-", "5");
			
			menu_addblank(iMenu, 0);
			
			menu_additem(iMenu, "\wNext ->", "6");
		}
	
		case 4:
		{
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_Hegrenade ? "\wHegrenade -> [ON]" : "\wHegrenade -> [OFF]", "1");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_Flashbang ? "\wFlashbang -> [ON]" : "\wFlashbang -> [OFF]", "2");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Weapon_Smokegrenade ? "\wSmokegrenade -> [ON]" : "\wSmokegrenade -> [OFF]", "3");
		
			menu_addblank(iMenu, 0);
			
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Item_Kevlar ? "\wKevlar -> [ON]" : "\wKevlar -> [OFF]", "4");
			menu_additem(iMenu, g_iBitWeaponList & _Bit_Item_Assaultsuit ? "\wAssaultsuit -> [ON]" : "\wAssaultsuit -> [OFF]", "5");
			
			menu_addblank(iMenu, 0);
		
			menu_additem(iMenu, "\wBack <-", "6");
		}
	}
	
	menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, iMenu, 0);
	
	return PLUGIN_CONTINUE;
}

stock Make_Vectors(&iAgressor, iEntity, Float:fDamage, iDamagebits, Float:fTemp[3], iMode = 0)
{
	static 
	
	Float:fDmgCheck,	
	Float:fOriginFix,	
	Float:fCheckOrigin[3],
	Float:fDifference[3],
	Float:fGroundData[3],
	Float:fGravityCheckFirst,
	Float:fGravityCheckSecond,
	
	bool:X_axis,
	bool:Y_axis,
	bool:bExplosion = false;
	
	if(iAgressor < 0)
	{
		fOriginFix = 32.0;
		
		switch(g_iClientEntity[IndexFix((iAgressor = -iAgressor))] ^ iEntity)
		{
			case 0:
			{
				fDmgCheck = g_fClientDamage[IndexFix(iAgressor)] * Float:DAMAGE_DIVIDER;
			}
				
			default:
			{
				fDmgCheck = fDamage * Float:DAMAGE_DIVIDER;
			}
		}	
	}
				
	else
	{
		fOriginFix = 0.0;
		
		if(iDamagebits & (DMG_UNKNOWN | DMG_BLAST)) 
		{
			bExplosion = true;
			
			fDmgCheck = fDamage;
		}
					
		else
		{
			bExplosion = false;
			
			fDmgCheck = fDamage * Float:DAMAGE_DIVIDER;
		}
	}
	
	if(fDmgCheck < 1.1)
	{
		fDmgCheck = random_float(1.1, 1.64);
	}
					
	else if(fDmgCheck > g_fMaxDamageMultiple)
	{
		fDmgCheck = g_fMaxDamageMultiple;
	}
		
	if(iMode) // if Entity is on Ground that has Angles
	{					
		pev(iAgressor, pev_origin, fCheckOrigin);
		pev(iEntity, pev_origin, fDifference);
		
		if((fCheckOrigin[2] - fOriginFix) < fDifference[2])
		{
			if(bExplosion)
			{
				bExplosion = false;
				
				Get_Velocity_Vector(iEntity, iAgressor, fDmgCheck, fTemp);
				
				set_pev(iEntity, pev_velocity, fTemp);
				set_pev(iEntity, PEV_JUMP_REDUCE, 1);
				
				return;
			}
			
			pev(iEntity, pev_gravity, fGravityCheckFirst);
					
			fGravityCheckFirst *= 32;
			fGravityCheckSecond = fGravityCheckFirst * 2;
					
			if((fTemp[2] = random_float(fDamage / 2, fDamage)) < fGravityCheckFirst)
			{
				fTemp[2] = fGravityCheckFirst;
			}
				
			else if(fTemp[2] > fGravityCheckSecond)
			{
				fTemp[2] = fGravityCheckSecond;
			}
				
			pev(iEntity, PEV_GROUND_DATA, fGroundData);
					
			X_axis = (fGroundData[0] != 0.000000);	
			Y_axis = (fGroundData[1] != 0.000000);
						
			if(X_axis && Y_axis)
			{
				fTemp[0] = fGroundData[0] * fDamage * random_float(1.1, 2.5);
				fTemp[1] = fGroundData[1] * fDamage * random_float(1.1, 2.5);
			}
						
			else if(X_axis)
			{
				fTemp[0] = fGroundData[0] * fDamage * random_float(1.1, 2.5);
				fTemp[1] = fDamage * random_float(-Float:MAX_VELOCITY_MULTIPLE, Float:MAX_VELOCITY_MULTIPLE);
			}
					
			else if(Y_axis)
			{
				fTemp[0] = fDamage * random_float(-Float:MAX_VELOCITY_MULTIPLE, Float:MAX_VELOCITY_MULTIPLE);
				fTemp[1] = fGroundData[1] * fDamage * random_float(1.1, 2.5);
			}	
				
			else
			{
				return;
			}
					
			set_pev(iEntity, pev_velocity, fTemp);
			
			return;
		}
	}

	Get_Velocity_Vector(iEntity, iAgressor, fDmgCheck, fTemp);
	
	set_pev(iEntity, pev_velocity, fTemp);
}

#if defined PUSH_MONSTERS
stock Touch_Extension_Check(iEntity, iTouched, iEntFlags, iTouchedFlags, iMode)
#else
stock Touch_Extension_Check(iEntity, iTouched, iEntFlags, iMode)
#endif
{
	if(iEntFlags & ~FL_ONGROUND)
	{
		static 
		Float:fVelReverse[3],
		Float:fVelocity[3],

		iAttacker;

		if((iAttacker = Get_Entity_Data(pev(iEntity, pev_owner))))
		{
			if(iAttacker < 0)
			{
				if((iAttacker = -iAttacker) == iTouched)
				{
					return HAM_IGNORED;
				}
			}
		}

		else
		{
			iAttacker = iEntity;
		}
		
		pev(iEntity, pev_velocity, fVelocity);
		
#if defined PUSH_MONSTERS

		static	
		Float:fVector, 
		Float:fDamage;
		fDamage = Float:((fVector = (vector_length(fVelocity) * g_fMultiple[iMode][_SpeedVectorMultiple])) * g_fMultiple[iMode][_DamageMultiple]);
		
		if(fVector > g_fMultiple[iMode][_SpeedVectorCheck])
		{
		
			if(iTouchedFlags & (is_Monster | is_Player))
			{
				Get_Velocity_Vector(iTouched, iEntity, fDamage * 0.1, fVelocity);
				
				set_pev(iTouched, pev_velocity, fVelocity);
			}
			
			ExecuteHamB(Ham_TakeDamage, iTouched, iEntity, iAttacker, fDamage, DMG_GENERIC);
		}
		
#endif

		if(1 << pev(iEntity, pev_solid) & (1 << SOLID_TRIGGER | 1 << SOLID_BBOX))
		{
			switch(1 << iMode & is_Breakable)
			{
				case 0:
				{
					fVelReverse[0] = 0.0;
					fVelReverse[1] = 0.0;
				}
				
				default:
				{
					static Float:Check_Ground[3];
					
					pev(iEntity, PEV_GROUND_DATA, Check_Ground);
			
					if((pev(iTouched, pev_health) > 0.0) || (0.0 < Check_Ground[2] < 1.0))
					{
						fVelReverse[0] = fVelocity[0];
						fVelReverse[1] = fVelocity[1];
					}
					
					else
					{
						fVelReverse[0] = -fVelocity[0];
						fVelReverse[1] = -fVelocity[1];
					}
				}	
			}
			
			fVelReverse[2] = fVelocity[2];
			
			set_pev(iEntity, pev_velocity, fVelReverse);
		}
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

stock Entity_Trail(iEntity, iColors[3] = {0, 0, 0})
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(g_SpriteTrail);
	write_byte(5);
	write_byte(2);
	write_byte(iColors[0] ? iColors[0] : random(256));
	write_byte(iColors[1] ? iColors[1] : random(256));
	write_byte(iColors[2] ? iColors[2] : random(256));
	write_byte(255);		
	
	message_end();
}

stock Change_Rendering(iEntity, iColors[3] = {0, 0, 0})
{
	new Float:f_Colors[3];
				
	f_Colors[0] = iColors[0] ? float(iColors[0]) : float(random(256));
	f_Colors[1] = iColors[1] ? float(iColors[1]) : float(random(256));
	f_Colors[2] = iColors[2] ? float(iColors[2]) : float(random(256));
			
	set_pev(iEntity, pev_renderfx, kRenderFxGlowShell);
	set_pev(iEntity, pev_rendercolor, f_Colors);
	set_pev(iEntity, pev_rendermode, kRenderNormal);
	set_pev(iEntity, pev_renderamt, 24.0);
}

stock bool:Extension_Check(iEntToSkip, iEntity, Float:fEnd[3])
{
	static Float:fOrigin[3];
					
	pev(iEntToSkip, pev_origin, fOrigin);
	pev(iEntity, pev_origin, fEnd);
			
	return bool:(get_distance_f(fEnd, fOrigin) > 2.5);
}

stock Enable_Physics(iEntity)
{
	static
	
	Float:f_destination[3],
	Float:f_velocity[3],
	Float:f_angles_2[3],
	Float:f_forward[3],
	Float:f_origin[3],
	Float:f_vector[3],
	Float:f_trace[3],
	iGround,
	trace,
	_i;

	pev(iEntity, pev_origin, f_origin);
	xs_vec_sub(f_origin, Float:{0.0, 0.0, Float:VECTOR_SUB}, f_destination);
		
	engfunc(EngFunc_TraceLine, f_origin, f_destination, IGNORE_MONSTERS | IGNORE_MISSILE, iEntity, trace);
		
	get_tr2(trace, TR_vecPlaneNormal, f_trace);
		
	if(!f_trace[2])
	{
		_i = (iGround = Ground_Vertical);
	}
		
	else if(f_trace[2] == 1.0)
	{
		_i = (iGround = Ground_Horizontal);
	}
		
	else if(0.0 < f_trace[2] <= Float:GROUND_TRACE_RESULT)
	{
		_i = (iGround = Ground_Angle_High);
	}
		
	else if(f_trace[2] > Float:GROUND_TRACE_RESULT)
	{
		_i = (iGround = Ground_Angle) - 0x1;
	}
		
	else
	{
		return HAM_IGNORED;
	}
		
	set_pev(iEntity, PEV_GROUND_DATA, f_trace);
	pev(iEntity, pev_velocity, f_velocity);
	
	_i >>= 0x1;
	
	set_pev(iEntity, PEV_GROUND_TYPE, _i);
	
#if defined SOUNDS_ON		
	if(vector_length(f_velocity) > Float:BLOCK_SOUND_BY_SPEED)
	{
		engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, g_sTouchSounds[random(g_iPrecacheTouchSoundSizeOf)], Float:SOUND_TOUCH, ATTN_NORM, 0, PITCH_NORM);
	}
#endif	
	
	f_velocity[0] *= g_fReduceSpeed[_i][0];
	f_velocity[1] *= g_fReduceSpeed[_i][1];
	f_velocity[2] *= g_fReduceSpeed[_i][2];
	
	if(pev(iEntity, PEV_JUMP_REDUCE))
	{
		set_pev(iEntity, PEV_JUMP_REDUCE, 0);
		
		f_velocity[0] *= random_float(1.1, 2.0);
		f_velocity[1] *= random_float(1.1, 2.0);
		f_velocity[2] *= random_float(1.1, 2.0);
	}
		
	if(f_velocity[2] > Float:MAX_REFLECT_VELOCITY)
	{
		f_velocity[2] = Float:MAX_REFLECT_VELOCITY;
	}
		
	else if(f_velocity[2] < -Float:MAX_REFLECT_VELOCITY)
	{
		f_velocity[2] = -Float:MAX_REFLECT_VELOCITY;
	}
		
	set_pev(iEntity, pev_velocity, f_velocity);	
		
	#define f_a_velocity f_velocity
		
	f_a_velocity[0] = random_float(-f_a_velocity[0], f_a_velocity[0]);
	f_a_velocity[1] = random_float(-f_a_velocity[1], f_a_velocity[1]);
	f_a_velocity[2] = random_float(f_a_velocity[2] / -2, f_a_velocity[2] / 2);
		
	set_pev(iEntity, pev_avelocity, f_a_velocity);	
		
	#define f_angles_1 f_velocity
	#define f_right f_origin
		
	if(iGround & ~Ground_Vertical)
	{		
		pev(iEntity, pev_angles, f_angles_1);
		angle_vector(f_angles_1, ANGLEVECTOR_FORWARD, f_vector);

		xs_vec_cross(f_vector, f_trace, f_right);
		xs_vec_cross(f_trace, f_right, f_forward);

		vector_to_angle(f_forward, f_angles_1);
		vector_to_angle(f_right, f_angles_2);

		f_angles_1[2] = -f_angles_2[0];
			
		set_pev(iEntity, pev_angles, f_angles_1);
	}
	
	return HAM_HANDLED;
}
#endif