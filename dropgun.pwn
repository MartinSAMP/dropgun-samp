/*

    Script By Martin ;v — Enhanced Version

    Gun Drop System
    - /dropgun  → Muncul dialog: Drop Langsung / Atur Posisi
    - /pickup   → Ambil senjata terdekat (ganti tombol Y)
    - Atur Posisi menggunakan EditAttachedObject (geser, rotasi bebas)
    - Auto RP message
    - Ada object gun-nya

*/

#include <a_samp>
#include <zcmd>
#include <core>
#include <string>

#define MAX_DROPPED_WEAPONS     100
#define COLOR_GREEN             0x00FF00FF
#define COLOR_RED               0xFF0000FF
#define COLOR_YELLOW            0xFFFF00FF
#define COLOR_WHITE             0xFFFFFFFF
#define COLOR_3DLABEL           0xFFD700FF
#define COLOR_PURPLE            0xC2A2DAFF
#define DIALOG_DROPGUN          1337
#define ATTACH_INDEX            0 

new TotalDropGun;
new DropGunObject[MAX_DROPPED_WEAPONS];
new DropGunAmmo  [MAX_DROPPED_WEAPONS];
new DropGunID    [MAX_DROPPED_WEAPONS];
new Text3D:DropGunText[MAX_DROPPED_WEAPONS];

new PendingWeapon   [MAX_PLAYERS];
new PendingAmmo     [MAX_PLAYERS];
new bool:IsPositioning[MAX_PLAYERS];

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
        case 34: format(name, len, "Rocket Launcher");
        case 35: format(name, len, "Heatseeker");
        case 36: format(name, len, "Flamethrower");
        case 37: format(name, len, "Minigun");
        case 38: format(name, len, "Sniper Rifle");
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

        new Float:dist = floatsqroot(
            floatpower(x - ix, 2) +
            floatpower(y - iy, 2) +
            floatpower(z - iz, 2)
        );

        if(dist <= radius)
            SendClientMessage(i, color, message);
    }
}

stock FindFreeDropSlot()
{
    for(new i = 0; i < MAX_DROPPED_WEAPONS; i++)
        if(DropGunID[i] == 0) return i;
    return -1;
}

stock RemoveWeaponFromPlayer(playerid, weaponid)
{
    new weapons[13][2];
    for(new i = 0; i < 13; i++)
        GetPlayerWeaponData(playerid, i, weapons[i][0], weapons[i][1]);

    ResetPlayerWeapons(playerid);

    for(new i = 0; i < 13; i++)
        if(weapons[i][0] != 0 && weapons[i][0] != weaponid)
            GivePlayerWeapon(playerid, weapons[i][0], weapons[i][1]);

    SetPlayerArmedWeapon(playerid, 0);
}

stock PlaceWeaponInWorld(playerid, Float:x, Float:y, Float:z, Float:rz)
{
    new slot = FindFreeDropSlot();
    if(slot == -1)
    {
        SendClientMessage(playerid, COLOR_RED, "ERROR: Batas senjata di server sudah penuh (100).");
        GivePlayerWeapon(playerid, PendingWeapon[playerid], PendingAmmo[playerid]);
        return;
    }

    new weapon  = PendingWeapon[playerid];
    new ammo    = PendingAmmo[playerid];
    new modelid = GetWeaponObjectID(weapon);

    new objectid = CreateObject(modelid, x, y, z, 90.0, 0.0, rz, 300.0);

    new weaponName[32], label[128];
    GetWeaponNameSimple(weapon, weaponName, sizeof(weaponName));
    format(label, sizeof(label),
        "{FFD700}%s\n{FFFFFF}Ammo: {00FF00}%d\n{FFFFFF}Ketik {FFFF00}/pickup {FFFFFF}untuk mengambil",
        weaponName, ammo);

    new Text3D:textid = Create3DTextLabel(label, COLOR_3DLABEL, x, y, z + 0.3, 10.0, 0, 1);

    DropGunObject[slot] = objectid;
    DropGunAmmo  [slot] = ammo;
    DropGunID    [slot] = weapon;
    DropGunText  [slot] = textid;

    if(slot >= TotalDropGun) TotalDropGun = slot + 1;

    new playerName[MAX_PLAYER_NAME], msg[128];
    GetPlayerName(playerid, playerName, sizeof(playerName));
    format(msg, sizeof(msg),
        "* %s menjatuhkan %s dengan %d ammo ke tanah.",
        playerName, weaponName, ammo);
    SendProximityMessage(playerid, 20.0, COLOR_PURPLE, msg);
}

CMD:dropgun(playerid, params[])
{
    if(IsPlayerInAnyVehicle(playerid))
        return SendClientMessage(playerid, COLOR_RED, "ERROR: Tidak bisa drop senjata di dalam kendaraan.");

    if(IsPositioning[playerid])
        return SendClientMessage(playerid, COLOR_RED, "ERROR: Kamu sedang dalam mode pengaturan posisi.");

    new weapon = GetPlayerWeapon(playerid);
    new ammo   = GetPlayerAmmo(playerid);

    if(weapon < 22 || weapon > 38)
    {
        SendClientMessage(playerid, COLOR_RED, "ERROR: Kamu hanya bisa drop senjata berikut:");
        SendClientMessage(playerid, COLOR_YELLOW,
            "Colt45, Silenced, Deagle, Shotgun, Sawnoff, SPAS, Micro UZI,");
        SendClientMessage(playerid, COLOR_YELLOW,
            "MP5, AK-47, M4, TEC-9, Rifle, RPG, Heatseeker, Flamethrower, Minigun, Sniper");
        return 1;
    }

    if(ammo <= 0)
        return SendClientMessage(playerid, COLOR_RED, "ERROR: Senjatamu tidak memiliki ammo.");

    if(FindFreeDropSlot() == -1)
        return SendClientMessage(playerid, COLOR_RED, "ERROR: Batas senjata di server sudah penuh (100).");

    PendingWeapon[playerid] = weapon;
    PendingAmmo  [playerid] = ammo;
    RemoveWeaponFromPlayer(playerid, weapon);

    ShowPlayerDialog(playerid, DIALOG_DROPGUN, DIALOG_STYLE_LIST,
        "{FFD700}Drop Senjata — Pilih Metode",
        "{FFFFFF}Drop Langsung\n{00FF00}Atur Posisi {FFFFFF}(Geser & Rotasi Bebas)",
        "Pilih", "Batal");
    return 1;
}

CMD:pickup(playerid, params[])
{
    if(IsPositioning[playerid])
        return SendClientMessage(playerid, COLOR_RED, "ERROR: Kamu sedang dalam mode pengaturan posisi.");

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new closestIndex = -1;
    new Float:closestDist = 999999.0;

    for(new i = 0; i < MAX_DROPPED_WEAPONS; i++)
    {
        if(DropGunID[i] == 0) continue;

        new Float:ox, Float:oy, Float:oz;
        GetObjectPos(DropGunObject[i], ox, oy, oz);

        new Float:dist = floatsqroot(
            floatpower(px - ox, 2) +
            floatpower(py - oy, 2) +
            floatpower(pz - oz, 2)
        );

        if(dist <= 3.0 && dist < closestDist)
        {
            closestDist = dist;
            closestIndex = i;
        }
    }

    if(closestIndex == -1)
        return SendClientMessage(playerid, COLOR_RED,
            "Tidak ada senjata di dekatmu. Dekati senjata terlebih dahulu!");

    new i = closestIndex;
    new weaponName[32];
    GetWeaponNameSimple(DropGunID[i], weaponName, sizeof(weaponName));

    GivePlayerWeapon(playerid, DropGunID[i], DropGunAmmo[i]);

    DestroyObject(DropGunObject[i]);
    Delete3DTextLabel(DropGunText[i]);

    new playerName[MAX_PLAYER_NAME], msg[128];
    GetPlayerName(playerid, playerName, sizeof(playerName));
    format(msg, sizeof(msg),
        "* %s mengambil %s dengan %d ammo dari tanah.",
        playerName, weaponName, DropGunAmmo[i]);
    SendProximityMessage(playerid, 20.0, COLOR_PURPLE, msg);

    DropGunID    [i] = 0;
    DropGunAmmo  [i] = 0;
    DropGunObject[i] = 0;
    return 1;
}

public OnGameModeInit()
{
    for(new i = 0; i < MAX_DROPPED_WEAPONS; i++)
    {
        DropGunObject[i] = 0;
        DropGunAmmo  [i] = 0;
        DropGunID    [i] = 0;
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    PendingWeapon [playerid] = 0;
    PendingAmmo   [playerid] = 0;
    IsPositioning [playerid] = false;
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if(IsPositioning[playerid])
    {
        if(IsPlayerAttachedObjectSlotUsed(playerid, ATTACH_INDEX))
            RemovePlayerAttachedObject(playerid, ATTACH_INDEX);

        new Float:px, Float:py, Float:pz, Float:angle;
        GetPlayerPos(playerid, px, py, pz);
        GetPlayerFacingAngle(playerid, angle);
        PlaceWeaponInWorld(playerid, px, py, pz - 0.9, angle);

        PendingWeapon [playerid] = 0;
        PendingAmmo   [playerid] = 0;
        IsPositioning [playerid] = false;
    }
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_DROPGUN)
    {
        if(!response)
        {
            GivePlayerWeapon(playerid, PendingWeapon[playerid], PendingAmmo[playerid]);
            PendingWeapon[playerid] = 0;
            PendingAmmo  [playerid] = 0;
            SendClientMessage(playerid, COLOR_YELLOW, "Drop senjata dibatalkan.");
            return 1;
        }

        if(listitem == 0)
        {
            new Float:x, Float:y, Float:z, Float:angle;
            GetPlayerPos(playerid, x, y, z);
            GetPlayerFacingAngle(playerid, angle);

            x += 0.7 * floatsin(-angle, degrees);
            y += 0.7 * floatcos(-angle, degrees);
            z -= 0.95;

            PlaceWeaponInWorld(playerid, x, y, z, angle);
            PendingWeapon[playerid] = 0;
            PendingAmmo  [playerid] = 0;
        }
        else if(listitem == 1)
        {
            IsPositioning[playerid] = true;

            new modelid = GetWeaponObjectID(PendingWeapon[playerid]);

            SetPlayerAttachedObject(playerid, ATTACH_INDEX, modelid, 6,
                0.05, 0.05, -0.15,  
                0.0,  90.0,  0.0,    
                1.0,  1.0,   1.0);   

            EditAttachedObject(playerid, ATTACH_INDEX);

            SendClientMessage(playerid, COLOR_YELLOW,
                ">> Geser/rotasi senjata ke posisi yang diinginkan.");
            SendClientMessage(playerid, COLOR_GREEN,
                ">> Tekan {00FF00}SAVE {FFFF00}untuk konfirmasi | {FF0000}CANCEL {FFFF00}untuk batalkan.");
        }
        return 1;
    }
    return 0;
}

public OnPlayerEditAttachedObject(playerid, response, index, modelid, boneid,
    Float:fOffsetX, Float:fOffsetY, Float:fOffsetZ,
    Float:fRotX,    Float:fRotY,    Float:fRotZ,
    Float:fScaleX,  Float:fScaleY,  Float:fScaleZ)
{
    if(index != ATTACH_INDEX || !IsPositioning[playerid])
        return 1;

    RemovePlayerAttachedObject(playerid, ATTACH_INDEX);
    IsPositioning[playerid] = false;

    if(response == EDIT_RESPONSE_FINAL)
    {
        new Float:px, Float:py, Float:pz;
        GetPlayerPos(playerid, px, py, pz);

        new Float:dropX = px + fOffsetX;
        new Float:dropY = py + fOffsetY;
        new Float:dropZ = pz + fOffsetZ - 0.9;

        PlaceWeaponInWorld(playerid, dropX, dropY, dropZ, fRotZ);
        PendingWeapon[playerid] = 0;
        PendingAmmo  [playerid] = 0;

        SendClientMessage(playerid, COLOR_GREEN, "Posisi senjata dikonfirmasi dan di-drop.");
    }
    else 
    {
        GivePlayerWeapon(playerid, PendingWeapon[playerid], PendingAmmo[playerid]);
        PendingWeapon[playerid] = 0;
        PendingAmmo  [playerid] = 0;
        SendClientMessage(playerid, COLOR_RED, "Pengaturan posisi dibatalkan. Senjata dikembalikan.");
    }

    return 1;
}
