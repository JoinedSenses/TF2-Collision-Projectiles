// TF2 plugin to projectiles from colliding with players or engineer objects.
// Requires CollisionHook extension: https://forums.alliedmods.net/showthread.php?t=197815

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>
#include <collisionhook>

#define PLUGIN_VERSION "1.0.11"
#define PLUGIN_DESCRIPTION "Prevent projectiles from colliding with players and buildings"

ConVar cvarTeamOnly;

public Plugin myinfo = {
    name = "projectilecollision",
    author = "Larry, JoinedSenses",
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = "https://steamcommunity.com/id/pancakelarry"
};

public void OnPluginStart() {
	CreateConVar("sm_projectilecollision_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD).SetString(PLUGIN_VERSION);
	cvarTeamOnly = CreateConVar("projectilecollision_teamonly", "1", "Prevent collision on team only?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public Action CH_PassFilter(int ent1, int ent2, bool &result) {
	char ent1name[128];
	char ent2name[128];

	GetEntityClassname(ent1, ent1name, sizeof(ent1name));
	GetEntityClassname(ent2, ent2name, sizeof(ent2name));

	int projectile;
	int player;
	int owner;
	bool isProjectile;

	if (StrContains(ent1name, "projectile") != -1) {
		projectile = ent1;
		player = ent2;
		isProjectile = true;
		if (StrContains(ent2name, "obj_") != -1) {
			player = GetEntPropEnt(player, Prop_Send, "m_hBuilder");
		}
	}
	else if (StrContains(ent2name, "projectile") != -1) {
		player = ent1;
		projectile = ent2;
		isProjectile = true;
		if (StrContains(ent1name, "obj_") != -1) {
			player = GetEntPropEnt(player, Prop_Send, "m_hBuilder");
		}
	}

	if (isProjectile && (IsValidClient(player))) {
		char classname[128];
		GetEntityClassname(projectile, classname, sizeof(classname));

		if (StrContains(classname, "projectile_pipe") != -1) {
			owner = GetEntPropEnt(projectile, Prop_Send, "m_hThrower");
		}
		else if (StrContains(classname, "projectile_rocket") != -1) {
			owner = GetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity");
		}
		else if (StrContains(classname, "projectile_energy_ball") != -1) {
			owner = GetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity");
		}
		else if (StrContains(classname, "projectile_sentryrocket") != -1) {
			int sentry = GetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity");
			owner = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");	
		}
		else {
			result = false;
			return Plugin_Handled;
		}

		bool other = IsValidClient(owner) && (owner != player);
		if (cvarTeamOnly.BoolValue) {
			if (other && TF2_GetClientTeam(owner) == TF2_GetClientTeam(player)) {
				result = false;
				return Plugin_Handled;
			}
		}
		else if (other) {
			result = false;
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}

	if (StrContains(ent1name, "obj_") != -1) {
		owner = GetEntPropEnt(ent1, Prop_Send, "m_hBuilder");
		if (StrContains(ent2name, "obj_") != -1) {
			player = GetEntPropEnt(ent2, Prop_Send, "m_hBuilder");
		}
		else {
			player = ent2;
		}
	}
	else if (StrContains(ent2name, "obj_") != -1) {
		owner = GetEntPropEnt(ent2, Prop_Send, "m_hBuilder");
		if (StrContains(ent1name, "obj_") != -1) {
			player = GetEntPropEnt(ent1, Prop_Send, "m_hBuilder");
		}
		else {
			player = ent1;
		}
	}
	else {
		return Plugin_Continue;
	}

	if (!IsValidClient(player) || !IsValidClient(owner)) {
		return Plugin_Continue;
	}

	bool other = owner != player;
	if (cvarTeamOnly.BoolValue) {
		if (other && TF2_GetClientTeam(owner) == TF2_GetClientTeam(player)) {
			result = false;
			return Plugin_Handled;
		}
	}
	else if (other) {
		result = false;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

bool IsValidClient(int client) {
	return (0 < client <= MaxClients);
}