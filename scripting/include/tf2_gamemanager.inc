#if defined __tf2_gamemanager_included
	#endinput
#endif
#define __tf2_gamemanager_included

native bool TF2GM_RegisterMode(const char[] name, const char[] status_convar);

forward void TF2GM_OnGamemodeChanged(int old_mode, int new_mode);

public SharedPlugin __pl_tf2_gamemanager = {
	name = "tf2-gamemanager",
	file = "tf2-gamemanager.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
