
public stock PluginVersion[] = "1.0.0";

//

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
// #include <addtofullpack_manager>

//

new Float:g_flLastFB3;
new g_FM_Hook_ShouldCollide_Pre;
new bool:g_bIsAlive[MAX_PLAYERS + 1];
new Array:g_hArray_SemiAttack = Invalid_Array;

//

public plugin_init() {
	
	register_plugin("Test semi penetra", PluginVersion, "Ragamafona");

	g_hArray_SemiAttack = ArrayCreate(.reserved = 1);

	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", .post = true);

	RegisterHookChain(RG_CBaseEntity_FireBullets3, "@CBaseEntity_FireBullets3_Pre", .post = false);
	RegisterHookChain(RG_CBaseEntity_FireBullets3, "@CBaseEntity_FireBullets3_Post", .post = true);

	RegisterHookChain(RG_CBaseEntity_FireBuckshots, "@CBaseEntity_FireBuckshots_Pre", .post = false);
	RegisterHookChain(RG_CBaseEntity_FireBuckshots, "@CBaseEntity_FireBuckshots_Post", .post = true);
}

public plugin_end()
{
	ArrayDestroy(g_hArray_SemiAttack);
}

@FM_ShouldCollide_Pre(const pPlayer, const pEntity) {

	if(get_gametime() != g_flLastFB3)
	{
		return FMRES_IGNORED;
	}

	if(!(0 < pPlayer <= MaxClients) || g_bIsAlive[pPlayer] == false)
	{
		return FMRES_IGNORED;
	}

	static iArrayPos;
	iArrayPos = ArrayFindValue(g_hArray_SemiAttack, pEntity);

	if(iArrayPos == -1)
	{
		return FMRES_IGNORED;
	}

	static pAttacker;
	pAttacker = ArrayGetCell(g_hArray_SemiAttack, iArrayPos);

	if(pAttacker > MaxClients)
	{
		pAttacker = get_member(pAttacker, m_pPlayer);
	}

	if(!pAttacker)
	{
		return FMRES_IGNORED;
	}

	// server_print("iArrayPos: %i, pAttacker: %i", iArrayPos, pAttacker);

	if(g_bIsAlive[pAttacker] == false || pAttacker == pPlayer)
	{
		return FMRES_IGNORED;
	}

	if(get_member(pPlayer, m_iTeam) == get_member(pAttacker, m_iTeam))
	{
		// server_print("<FM_ShouldCollide_Pre> block player: '%n'(%i) | ent: '%n'(%i)", pPlayer, pPlayer, pAttacker, pAttacker);

		forward_return(FMV_CELL, 0);
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

//

public client_disconnected(pPlayer) {

	g_bIsAlive[pPlayer] = false;
}

//

@CBasePlayer_Spawn_Post(const pPlayer) {

	g_bIsAlive[pPlayer] = bool:is_user_alive(pPlayer);
}

@CBaseEntity_FireBullets3_Pre(const pInflictor)
{
	g_flLastFB3 = get_gametime();
	ArrayPushCell(g_hArray_SemiAttack, pInflictor);

	if(g_FM_Hook_ShouldCollide_Pre == 0)
	{
		g_FM_Hook_ShouldCollide_Pre = register_forward(FM_ShouldCollide, "@FM_ShouldCollide_Pre", false);
	}
}

@CBaseEntity_FireBullets3_Post(const pInflictor)
{
	if(g_FM_Hook_ShouldCollide_Pre)
	{
		unregister_forward(FM_ShouldCollide, g_FM_Hook_ShouldCollide_Pre, false);
		g_FM_Hook_ShouldCollide_Pre = 0;
	}

	static iArrayPos;
	iArrayPos = ArrayFindValue(g_hArray_SemiAttack, pInflictor);

	if(iArrayPos == -1)
	{
		return;
	}

	ArrayDeleteItem(g_hArray_SemiAttack, iArrayPos);
}

@CBaseEntity_FireBuckshots_Pre(const pInflictor)
{
	g_flLastFB3 = get_gametime();
	ArrayPushCell(g_hArray_SemiAttack, pInflictor);

	if(g_FM_Hook_ShouldCollide_Pre == 0)
	{
		g_FM_Hook_ShouldCollide_Pre = register_forward(FM_ShouldCollide, "@FM_ShouldCollide_Pre", false);
	}
}

@CBaseEntity_FireBuckshots_Post(const pInflictor)
{
	if(g_FM_Hook_ShouldCollide_Pre)
	{
		unregister_forward(FM_ShouldCollide, g_FM_Hook_ShouldCollide_Pre, false);
		g_FM_Hook_ShouldCollide_Pre = 0;
	}

	static iArrayPos;
	iArrayPos = ArrayFindValue(g_hArray_SemiAttack, pInflictor);

	if(iArrayPos == -1)
	{
		return;
	}

	ArrayDeleteItem(g_hArray_SemiAttack, iArrayPos);
}
