/*

Script By Martin ;v

Gun Drop System
- Tekan Y untuk mengambil Gun
- /dropgun untuk drop gun ke tanah
- auto rp
- ada object gun nya

Note: Kalian bisa menambahin object gun lainnya sendiri

*/

#include <a_samp>
#include <zcmd>
#include <core>
#include <string>

#define MAX_DROPPED_WEAPONS 100
#define COLOR_GREEN 0x00FF00FF
#define COLOR_RED 0xFF0000FF
#define COLOR_YELLOW 0xFFFF00FF
#define COLOR_WHITE 0xFFFFFFFF
#define COLOR_3DLABEL 0xFFD700FF
#define COLOR_PURPLE 0xC2A2DAFF

new TotalDropGun;
new DropGunObject[MAX_DROPPED_WEAPONS];
new DropGunAmmo[MAX_DROPPED_WEAPONS];
new DropGunID[MAX_DROPPED_WEAPONS];
new Text3D:DropGunText[MAX_DROPPED_WEAPONS];

stock GetWeaponObjectID(weaponid)
{
	switch(weaponid)
	{
		case 22: return 346;
		case 23: return 347;
		case 24: return 348;
		case 25: return 349;
		case 26: return 350;
		case 27: return 351;
		case 28: return 352;
		case 29: return 353;
		case 30: return 355;
		case 31: return 356;
		case 32: return 357;
		case 33: return 358;
		case 34: return 359;
		case 35: return 360;
		case 36: return 361;
		case 37: return 362;
		case 38: return 363;
	}
	return 348;
}

stock GetWeaponNameSimple(weaponid, name[], len)
{
	switch(weaponid)
	{
		case 22: format(name, len, "Colt 45");
		case 23: format(name, len, "Silenced Pistol");
		case 24: format(name, len, "Desert Eagle");
		case 25: format(name, len, "Shotgun");
		case 26: format(name, len, "Sawnoff Shotgun");
		case 27: format(name, len, "SPAS-12");
		case 28: format(name, len, "Micro UZI");
		case 29: format(name, len, "MP5");
		case 30: format(name, len, "AK-47");
		case 31: format(name, len, "M4");
		case 32: format(name, len, "TEC-9");
		case 33: format(name, len, "Rifle");
		default: format(name, len, "Unknown Weapon");
	}
}

stock SendProximityMessage(playerid, Float:radius, color, const message[])
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);

	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(!IsPlayerConnected(i)) continue;

		new Float:ix, Float:iy, Float:iz;
		GetPlayerPos(i, ix, iy, iz);
		new Float:dist = floatsqroot(floatpower(x - ix, 2) + floatpower(y - iy, 2) + floatpower(z - iz, 2));

		if(dist <= radius)
			SendClientMessage(i, color, message);
	}
}

CMD:dropgun(playerid, params[])
{
	if(IsPlayerInAnyVehicle(playerid))
		return SendClientMessage(playerid, COLOR_RED, "ERROR: Cannot drop weapons while in vehicle.");

	new weapon = GetPlayerWeapon(playerid);
	new ammo = GetPlayerAmmo(playerid);

	if(weapon < 22 || weapon > 38)
	{
		SendClientMessage(playerid, COLOR_RED, "ERROR: You can only drop these weapons:");
		SendClientMessage(playerid, COLOR_YELLOW, "Colt45, Silenced, Deagle, Shotgun, Sawnoff, SPAS, Micro UZI,");
		SendClientMessage(playerid, COLOR_YELLOW, "MP5, AK-47, M4, TEC-9, Rifle, RPG, Heatseeker, Flamethrower, Minigun, Sniper");
		return 1;
	}

	if(weapon == 0 || ammo <= 0)
		return SendClientMessage(playerid, COLOR_RED, "ERROR: You don't have a valid weapon with ammo to drop.");

	if(TotalDropGun >= MAX_DROPPED_WEAPONS)
		return SendClientMessage(playerid, COLOR_RED, "ERROR: Server weapon limit reached (100 dropped weapons).");

	new Float:x, Float:y, Float:z, Float:angle;
	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, angle);

	new Float:offsetX = 0.7 * floatsin(-angle, degrees);
	new Float:offsetY = 0.7 * floatcos(-angle, degrees);
	x += offsetX;
	y += offsetY;
	z -= 0.95;

	new Float:rx = 90.0, Float:ry = 0.0, Float:rz = angle;
	new objectid = CreateObject(GetWeaponObjectID(weapon), x, y, z, rx, ry, rz, 300.0);

	new weaponName[32], label[128];
	GetWeaponNameSimple(weapon, weaponName, sizeof(weaponName));
	format(label, sizeof(label), "{FFD700}%s\n{FFFFFF}Ammo: {00FF00}%d\n{FFFFFF}Press {FFFF00}Y to pick up", weaponName, ammo);
	new Text3D:textid = Create3DTextLabel(label, COLOR_3DLABEL, x, y, z + 0.25, 10.0, 0, 1);

	DropGunObject[TotalDropGun] = objectid;
	DropGunAmmo[TotalDropGun] = ammo;
	DropGunID[TotalDropGun] = weapon;
	DropGunText[TotalDropGun] = textid;

	new weapons[13][2];
	for(new i = 0; i < 13; i++)
		GetPlayerWeaponData(playerid, i, weapons[i][0], weapons[i][1]);

	ResetPlayerWeapons(playerid);

	for(new i = 0; i < 13; i++)
	{
		if(weapons[i][0] != 0 && weapons[i][0] != weapon)
			GivePlayerWeapon(playerid, weapons[i][0], weapons[i][1]);
	}

	SetPlayerArmedWeapon(playerid, 0);

	new playerName[MAX_PLAYER_NAME], msg[128];
	GetPlayerName(playerid, playerName, sizeof(playerName));
	format(msg, sizeof(msg), "* %s drops %s with %d ammo on the ground.", playerName, weaponName, ammo);
	SendProximityMessage(playerid, 20.0, COLOR_PURPLE, msg);

	TotalDropGun++;
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(!((newkeys & KEY_YES) && !(oldkeys & KEY_YES)))
		return 1;

	new Float:playerX, Float:playerY, Float:playerZ;
	GetPlayerPos(playerid, playerX, playerY, playerZ);

	new closestIndex = -1;
	new Float:closestDist = 999999.0;

	for(new i = 0; i < TotalDropGun; i++)
	{
		if(DropGunID[i] == 0) continue;

		new Float:objX, Float:objY, Float:objZ;
		GetObjectPos(DropGunObject[i], objX, objY, objZ);

		new Float:dist = floatsqroot(floatpower(playerX - objX, 2) + floatpower(playerY - objY, 2) + floatpower(playerZ - objZ, 2));

		if(dist <= 3.0 && dist < closestDist)
		{
			closestDist = dist;
			closestIndex = i;
		}
	}

	if(closestIndex == -1)
		return SendClientMessage(playerid, COLOR_RED, "No weapons found nearby. Get closer to a weapon first!");

	new i = closestIndex;
	new weaponName[32];
	GetWeaponNameSimple(DropGunID[i], weaponName, sizeof(weaponName));

	GivePlayerWeapon(playerid, DropGunID[i], DropGunAmmo[i]);

	DestroyObject(DropGunObject[i]);
	Delete3DTextLabel(DropGunText[i]);

	new playerName[MAX_PLAYER_NAME], msg[128];
	GetPlayerName(playerid, playerName, sizeof(playerName));
	format(msg, sizeof(msg), "* %s picks up %s with %d ammo from the ground.", playerName, weaponName, DropGunAmmo[i]);
	SendProximityMessage(playerid, 20.0, COLOR_PURPLE, msg);

	DropGunID[i] = 0;
	DropGunAmmo[i] = 0;
	DropGunObject[i] = 0;

	return 1;
}
