#include <amxmodx>
#include <reapi>

public plugin_init()
{
    register_plugin("[ZMCSO] Zombie: Distance Hands", "1.0", "Docaner");
}

public zp_user_infected_post(id)
{
    set_knife_distance(id);
}

stock set_knife_distance(id)
{
    new const pKnife = get_member(id, m_rgpPlayerItems, KNIFE_SLOT);

    if(is_nullent(pKnife)) return;

    set_member(pKnife, m_Knife_flStabDistance, 32.0); // ПКМ default: 32.0
    set_member(pKnife, m_Knife_flSwingDistance, 34.0); // ЛКМ default: 64.0
}