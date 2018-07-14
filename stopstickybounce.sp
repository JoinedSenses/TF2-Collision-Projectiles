// TF2 plugin to stop stickies from bouncing off players
// Requires CollisionHook extension: https://forums.alliedmods.net/showthread.php?t=197815

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <collisionhook>

ConVar g_hTeamOnly;

public Plugin myinfo = {
    name = "stopstickybounce",
    author = "Larry",
    description = "Prevent stickies from bouncing off players",
    version = "1.0.3",
    url = "https://steamcommunity.com/id/pancakelarry"
};

public OnPluginStart() {
   g_hTeamOnly = CreateConVar("stopstickybounce_teamonly", "0", "Stop stickies from bouncing off only friendly players", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public Action CH_PassFilter(ent1, ent2, &bool:result) {
	char ent1name[256];
	char ent2name[256];
	GetEntityClassname(ent1, ent1name, sizeof(ent1name));
	GetEntityClassname(ent2, ent2name, sizeof(ent2name));

	new projectile;
	new player;

	// Determine which entity is the projectile or player
	if(StrEqual(ent1name, "tf_projectile_pipe_remote", false)) {
		projectile = ent1;
		player = ent2;
	}
	else if (StrEqual(ent2name, "tf_projectile_pipe_remote", false)) {
		player = ent1;
		projectile = ent2;
	}
	else if (!(StrContains(ent1name, "obj_") || StrContains(ent2name, "obj_"))){
		result = false;
		return Plugin_Handled;
	}
	else {
		return Plugin_Continue;
	}

	if(1 <= player <= MaxClients) {
		int owner = GetEntPropEnt(projectile, Prop_Data, "m_hThrower");
		if(!(1 <= owner <= MaxClients))
			return Plugin_Handled;
		if(g_hTeamOnly.BoolValue) {
			if(TF2_GetClientTeam(owner) == TF2_GetClientTeam(player)) {
				result = false;
				return Plugin_Handled;
			}
		}
		else if (owner != player) {
			result = false;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
