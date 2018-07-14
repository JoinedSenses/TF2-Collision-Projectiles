// TF2 plugin to projectiles from colliding with players or engineer objects.
// Requires CollisionHook extension: https://forums.alliedmods.net/showthread.php?t=197815

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <collisionhook>

ConVar g_hTeamOnly;

public Plugin myinfo ={
    name = "projectilecollision",
    author = "Larry, JoinedSenses",
    description = "Prevent projectiles from colliding with players and buildings",
    version = "1.0.5",
    url = "https://steamcommunity.com/id/pancakelarry"
};

public void OnPluginStart(){
   g_hTeamOnly = CreateConVar("projectilecollision_teamonly", "1", "Stop stickies from bouncing off only friendly players", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public Action CH_PassFilter(ent1, ent2, &bool:result){
	char
		ent1name[256]
		, ent2name[256];
	GetEntityClassname(ent1, ent1name, sizeof(ent1name));
	GetEntityClassname(ent2, ent2name, sizeof(ent2name));

	int
		projectile
		, player
		, owner
		, sentry;

	// Determine which entity is the projectile or player
	if (StrContains(ent1name, "projectile") != -1){
		projectile = ent1;
		player = ent2;
	}
	else if (StrContains(ent2name, "projectile") != -1){
		player = ent1;
		projectile = ent2;
	}
	else if (!(StrContains(ent1name, "obj_") || StrContains(ent2name, "obj_"))){
		result = false;
		return Plugin_Handled;
	}
	else
		return Plugin_Continue;

	if(1 <= player <= MaxClients){
		char pClass[32];
		
		GetEntityClassname(projectile, pClass, sizeof(pClass));
		if(StrContains(pClass, "projectile_pipe") != -1)
			owner = GetEntPropEnt(projectile, Prop_Send, "m_hThrower");
		else if (StrContains(pClass, "projectile_rocket") != -1)
			owner = GetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity");
		else if (StrContains(pClass, "projectile_sentryrocket") != -1){
			sentry = GetEntPropEnt(projectile, Prop_Send, "m_hOwnerEntity");
			owner = GetEntPropEnt(sentry, Prop_Send, "m_hBuilder");	
		}
		
		if(!(1 <= owner <= MaxClients))
			return Plugin_Handled;
			
		if(g_hTeamOnly.BoolValue)
		{
			if(TF2_GetClientTeam(owner) == TF2_GetClientTeam(player))
			{
				result = false;
				return Plugin_Handled;
			}
		}
		else if (owner != player)
		{
			result = false;
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}