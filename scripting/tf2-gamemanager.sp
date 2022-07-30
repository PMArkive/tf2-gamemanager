#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define NO_GAMEMODE -1

ArrayList g_Modes;
StringMap g_StatusConVars;

int g_Gamemode = NO_GAMEMODE;

GlobalForward g_Forward_OnGamemodeChanged;

public Plugin myinfo = {
	name = "[TF2] Game Manager", 
	author = "Drixevel", 
	description = "Helps to manage and change gamemodes on a server.", 
	version = "1.0.0", 
	url = "https://scoutshideaway.tf/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("tf2-gamemanager");

	CreateNative("TF2GM_RegisterMode", Native_RegisterMode);

	g_Forward_OnGamemodeChanged = new GlobalForward("TF2GM_OnGamemodeChanged", ET_Ignore, Param_Cell, Param_Cell);

	return APLRes_Success;
}

public void OnPluginStart() {
	RegAdminCmd("sm_mode", Command_Mode, ADMFLAG_BAN, "Manages and changes the gamemode.");
	RegAdminCmd("sm_gamemode", Command_Mode, ADMFLAG_BAN, "Manages and changes the gamemode.");

	g_Modes = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
	g_StatusConVars = new StringMap();
}

public Action Command_Mode(int client, int args) {
	OpenGamemodesMenu(client);
	return Plugin_Handled;
}

void OpenGamemodesMenu(int client) {
	Menu menu = new Menu(MenuHandler_Modes);
	menu.SetTitle("[SH] Game Manager");

	char sID[16]; char sName[MAX_NAME_LENGTH];
	for (int i = 0; i < g_Modes.Length; i++) {
		IntToString(i, sID, sizeof(sID));
		g_Modes.GetString(i, sName, sizeof(sName));
		menu.AddItem(sID, sName);
	}

	if (menu.ItemCount == 0) {
		menu.AddItem("", " :: No Modes Available", ITEMDRAW_DISABLED);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Modes(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sID[16];
			menu.GetItem(param2, sID, sizeof(sID));
			
			int index = StringToInt(sID);
			OpenGamemodeMenu(param1, index);
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
	
	return 0;
}

void OpenGamemodeMenu(int client, int index) {
	char name[MAX_NAME_LENGTH];
	g_Modes.GetString(index, name, sizeof(name));

	Menu menu = new Menu(MenuHandler_Gamemode);
	menu.SetTitle("[SH] Game Manager - %s", name);

	menu.AddItem("load", "Load Gamemode");

	PushMenuInt(menu, "index", index);

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Gamemode(Menu menu, MenuAction action, int param1, int param2) {
	int index = GetMenuInt(menu, "index");

	switch (action) {
		case MenuAction_Select: {
			char sInfo[16];
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			if (StrEqual(sInfo, "load")) {
				ChangeGamemode(index);
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_Exit) {
				OpenGamemodesMenu(param1);
			}
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
	
	return 0;
}

void ChangeGamemode(int index) {
	char name[MAX_NAME_LENGTH]; char convar[64];

	if (g_Gamemode != NO_GAMEMODE) {
		g_Modes.GetString(g_Gamemode, name, sizeof(name));
		g_StatusConVars.GetString(name, convar, sizeof(convar));
		FindConVar(convar).BoolValue = false;
	}

	int old = g_Gamemode;
	g_Gamemode = index;

	g_Modes.GetString(g_Gamemode, name, sizeof(name));
	g_StatusConVars.GetString(name, convar, sizeof(convar));
	FindConVar(convar).BoolValue = true;

	PrintToChatAll("[SH] Gamemode Changed to: %s", name);

	Call_StartForward(g_Forward_OnGamemodeChanged);
	Call_PushCell(old);
	Call_PushCell(g_Gamemode);
	Call_Finish();
}

public int Native_RegisterMode(Handle plugin, int numParams) {
	//Display Name
	int size;
	GetNativeStringLength(1, size);

	char[] name = new char[size];
	GetNativeString(1, name, size);

	if (g_Modes.FindString(name) == -1) {
		g_Modes.PushString(name);
	}

	//Status ConVar
	GetNativeStringLength(2, size);

	char[] status = new char[size];
	GetNativeString(2, status, size);

	g_StatusConVars.SetString(name, status);

	return true;
}

bool PushMenuInt(Menu menu, const char[] id, int value) {
	if (menu == null || strlen(id) == 0) {
		return false;
	}
	
	char sBuffer[128];
	IntToString(value, sBuffer, sizeof(sBuffer));
	return menu.AddItem(id, sBuffer, ITEMDRAW_IGNORE);
}

int GetMenuInt(Menu menu, const char[] id, int defaultvalue = 0) {
	if (menu == null || strlen(id) == 0) {
		return defaultvalue;
	}
	
	char info[128]; char data[128];
	for (int i = 0; i < menu.ItemCount; i++) {
		if (menu.GetItem(i, info, sizeof(info), _, data, sizeof(data)) && StrEqual(info, id)) {
			return StringToInt(data);
		}
	}
	
	return defaultvalue;
}