//Created using gunxpmod include

#if defined _supplybox_included
  #endinput
#endif
#define _supplybox_included

#if !defined charsmax
    #define charsmax(%1) sizeof(%1)-1
#endif

stock sb_item_index()
{
	new temp[2], name[64], pluginname[64]
	get_plugin(-1, pluginname, 63, temp, 1, temp, 1, temp, 1, temp, 1)
	for (new i = 0; i < get_pluginsnum(); ++i)
	{
		get_plugin(i, name, 63, temp, 1, temp, 1, temp, 1, temp, 1)
 		if(equal(name, pluginname))
		{
 			return i
		}
	}
 	return -1
}

stock sb_item_plugin()
{
	for(new i = 0; i < get_pluginsnum(); ++i)
	{
		new temp[2], name[64]
		get_plugin(i, name, 63, temp, 1, temp, 1, temp, 1, temp, 1)
 		if(equali(name, "SupplyBox.amxx")) {
 			return i;
		}
	}
 	return -1;
}

stock register_supply_box(supply_desc[128])
{
	new item_index = sb_item_index()
	new itemplugin = sb_item_plugin()
	new itemregfunc = get_func_id("register_box", itemplugin)

	new temp = callfunc_begin_i(itemregfunc, itemplugin)
	if(temp == -1 || temp == -2)
	{
		if(temp == -2) {
			log_amx("You have to many items, and need to increase the MAX_UNLOCKS define!");
		} 
		else {
			log_amx("A unkown error has happend, make sure the Upgrades plugin is loaded!");
		}
		return PLUGIN_HANDLED;		
	}

	callfunc_push_int(item_index)
	callfunc_push_str(supply_desc)
	
	temp = callfunc_end()
	if(temp == -1 || temp == -2) {
		return PLUGIN_HANDLED;
	}
	
	return temp;
}