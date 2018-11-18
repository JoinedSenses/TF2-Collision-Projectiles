// TF2 plugin to projectiles from colliding with players or engineer objects.
// Requires CollisionHook extension: https://forums.alliedmods.net/showthread.php?t=197815

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>
#include <collisionhook>

#define PLUGIN_VERSION "1.0.6"

ConVar g_hTeamOnly;

public Plugin myinfo = {
    name = "projectilecollision",
    author = "Larry, JoinedSenses",
    description = "Prevent projectiles from colliding with players and buildings",
    version = PLUGIN_VERSION,
    url = "https://steamcommunity.com/id/pancakelarry"
};

public void OnPluginStart() {
	CreateConVar("sm_projectilecollision_version", PLUGIN_VERSION);
	g_hTeamOnly = CreateConVar("projectilecollision_teamonly", "1", "Prevent collision on team only?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public Action CH_PassFilter(int ent1, int ent2, bool& result) {
	char ent1name[256];
	GetEntityClassname(ent1, ent1name, sizeof(ent1name));

	char ent2name[256];
	GetEntityClassname(ent2, ent2name, sizeof(ent2name));

	int projectile;
	int player;
	int owner;
	int sentry;

	// Determine which entity is the projectile or player
	if (StrContains(ent1name, "projectile") != -1) {
		projectile = ent1;
		player = ent2;
	}
	else if (StrContains(ent2name, "projectile") != -1) {
		player = ent1;
		projectile = ent2;
	}
	else if (!(StrContains(ent1name, "obj_") || StrContains(ent2name, "obj_"))) {
		result = false;
		return Plugin_Handled;
	}
	else {
		return Plugin_Continue;
	}

	if (0 < player <= MaxClients) {
		char className[32];
		
		GetEntityClassname(projectile, className, sizeof(className));
		if(StrContains(className, "projectile_pipe") != -1) {
			owner = GetEntPropEnt(projectile, Prop_Send, "m_hThrower");
		}
		else if (StrContains(className, "projectile_rocket") != -1) {
			owner = GetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity");
		}
		else if (StrContains(className, "projectile_sentryrocket") != -1){
			sentry = GetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity");
			owner = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");	
		}
		
		if (!(0 < owner <= MaxClients)) {
			return Plugin_Handled;
		}
			
		if (g_hTeamOnly.BoolValue) {
			if (TF2_GetClientTeam(owner) == TF2_GetClientTeam(player)) {
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