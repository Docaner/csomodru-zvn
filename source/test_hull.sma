#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <xs>

public plugin_init()
{
	register_plugin("Test Hull", "1.0", "Docaner");
	register_clcmd("testhull", "@testhull");
}

@testhull(id)
{
	client_print(id, print_chat, "Стоять: %s", can_user_stand(id) ? "можно" : "нельзя");
}

/**
 * Высота бокса игрока в положении стоя
 */
#define Player_StandHeight 72.0
#define Player_SitHeight 50.0
#define Player_DiffrenceHeight 12.0 

// Размеры игрока стоя. Высота = 72
// mins: -16.000000 -16.000000 -36.000000
// maxs: 16.000000 16.000000 36.000000

// Размеры игрока сидя. Высота = 50
// mins: -16.000000 -16.000000 -18.000000
// maxs: 16.000000 16.000000 32.000000

/**
 * Может ли игрок стоять в текущем положении
 * 
 * @param pPlayer 		Индекс игрока
 * 
 * @return 				true - может встать, false - не может
 */
stock bool:can_user_stand(const pPlayer)
{
	if(~get_entvar(pPlayer, var_flags) & FL_DUCKING)
		return true;

	new Float:vecStart[3], Float:flHeight; get_entvar(pPlayer, var_origin, vecStart);
	
	new tHandle = create_tr2();
	
	for(new i, Float:vecEnd[3], Float:flFraction; i < 2; i++)
	{
		xs_vec_copy(vecStart, vecEnd);

		vecEnd[2] += i ? -Player_DiffrenceHeight : Player_StandHeight;

		engfunc(EngFunc_TraceHull, vecStart, vecEnd, 0, HULL_HEAD, pPlayer, tHandle);
		get_tr2(tHandle, TR_flFraction, flFraction);
		new Float:flHeightPhase = flFraction * Player_StandHeight;
		client_print(pPlayer, print_chat, "flHeightPhase: %f", flHeightPhase);
		flHeight += flHeightPhase
	}

	free_tr2(tHandle);

	client_print(pPlayer, print_chat, "flHeight: %f", flHeight);
	return flHeight >= Player_StandHeight ? true : false;
}