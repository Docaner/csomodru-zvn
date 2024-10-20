#include <amxmodx>
#include <reapi>
#include <zombieplague>
#include <xs>

new HookChain:g_hcSetAnimation;

public plugin_init()
{
    register_plugin("[ZC] Flinch Anim Disable", "1.0", "Docaner");
    
    DisableHookChain( (g_hcSetAnimation = RegisterHookChain(RG_CBasePlayer_SetAnimation, "@RG_Player_SetAnimation_Pre", false)) );

    RegisterHookChain(RG_CBasePlayer_TakeDamage, "@RG_Player_TakeDamage_Pre", false);
    RegisterHookChain(RG_CBasePlayer_TakeDamage, "@RG_Player_TakeDamage_Post", true);
}

@RG_Player_TakeDamage_Pre(iVictim)
{
    if(zp_get_user_zombie(iVictim))
        EnableHookChain(g_hcSetAnimation);
}

@RG_Player_TakeDamage_Post(iVictim)
{
    if(zp_get_user_zombie(iVictim))
        DisableHookChain(g_hcSetAnimation);
}


@RG_Player_SetAnimation_Pre(const iPlayer, PLAYER_ANIM:pAnim)
{
    if(!zp_get_user_zombie(iPlayer)) return HC_CONTINUE;

    switch(pAnim)
    {
        case PLAYER_FLINCH, PLAYER_LARGE_FLINCH:
        {
            //client_print(0, print_chat, "iPlayer: %d | BLOCK ANIM", iPlayer);
            return HC_SUPERCEDE;
        }
    }
    
    return HC_CONTINUE;
}