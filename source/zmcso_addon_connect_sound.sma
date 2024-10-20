#include <amxmodx>
#include <fakemeta>
#include <amxmisc> 

#define CONNECT_SOUND	"sound/zp_br_cso/mod/connecting_sound.mp3"

public plugin_precache() {
	register_plugin("[ZC] Addon: Connect Sound", "1.0", "DesortioN");
	engfunc(EngFunc_PrecacheGeneric, CONNECT_SOUND)
}

public client_connect(iPlayer) {
	if(is_user_bot(iPlayer) || is_user_hltv(iPlayer))
		return;
		
	client_cmd(iPlayer, "mp3 play %s", CONNECT_SOUND)
}