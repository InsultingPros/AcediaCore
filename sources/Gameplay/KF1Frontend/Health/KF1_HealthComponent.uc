/**
 *  `AHealthComponent`'s implementation for `KF1_Frontend`.
 *      Copyright 2022 Anton Tarasenko
 *------------------------------------------------------------------------------
 * This file is part of Acedia.
 *
 * Acedia is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License, or
 * (at your option) any later version.
 *
 * Acedia is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Acedia.  If not, see <https://www.gnu.org/licenses/>.
 */
class KF1_HealthComponent extends AHealthComponent
    dependson(ConnectionService)
    config(AcediaSystem);

//  TODO: document here and in config
var private const config bool replaceBloatAndSirenDamageTypes;

var private LoggerAPI.Definition infoReplacingDamageTypes, errNoServerLevelCore;
var private LoggerAPI.Definition infoRestoringReplacingDamageTypes;

public function PresudoConstructor()
{
    local LevelCore core;
    _.unreal.gameRules.OnNetDamage(self).connect = OnNetDamageHandler;
    if (!replaceBloatAndSirenDamageTypes) {
        return;
    }
    _.logger.Auto(infoReplacingDamageTypes);
    core = class'ServerLevelCore'.static.GetInstance();
    if (core != none)
    {
        ReplaceDamageTypes(core);
        _.unreal.gameRules.OnScoreKill(self).connect = UpdateBileAchievement;
        core.OnShutdown(self).connect = RestoreDamageTypes;
    }
    else {
        _.logger.Auto(errNoServerLevelCore);
    }
}

protected function Finalizer()
{
    _.unreal.gameRules.OnNetDamage(self).Disconnect();
    if (replaceBloatAndSirenDamageTypes) {
        RestoreDamageTypes();
    }
}

private final function ReplaceDamageTypes(LevelCore core)
{
    local KFBloatVomit      nextVomit;
    local ZombieSirenBase   nextSiren;

    class'KFBloatVomit'.default.myDamageType = class'Dummy_DamTypeVomit';
    class'ZombieSirenBase'.default.screamDamageType =
        class'Dummy_SirenScreamDamage';
    class'ZombieSirenBase'.default.screamDamageType =
        class'Dummy_SirenScreamDamage';
    class'ZombieSiren_STANDARD'.default.screamDamageType =
        class'Dummy_SirenScreamDamage';
    class'ZombieSiren_HALLOWEEN'.default.screamDamageType =
        class'Dummy_SirenScreamDamage';
    class'ZombieSiren_XMas'.default.screamDamageType =
        class'Dummy_SirenScreamDamage';
    class'ZombieSiren_CIRCUS'.default.screamDamageType =
        class'Dummy_SirenScreamDamage';
    foreach core.AllActors(class'KFBloatVomit', nextVomit) {
        nextVomit.myDamageType = class'Dummy_DamTypeVomit';
    }
    foreach core.AllActors(class'ZombieSirenBase', nextSiren) {
        nextSiren.screamDamageType = class'Dummy_SirenScreamDamage';
    }
}

private final function RestoreDamageTypes()
{
    _.logger.Auto(infoRestoringReplacingDamageTypes);
    class'KFBloatVomit'.default.myDamageType = class'DamTypeVomit';
    class'ZombieSirenBase'.default.screamDamageType = class'SirenScreamDamage';
    class'ZombieSirenBase'.default.screamDamageType = class'SirenScreamDamage';
    class'ZombieSiren_STANDARD'.default.screamDamageType =
        class'SirenScreamDamage';
    class'ZombieSiren_HALLOWEEN'.default.screamDamageType =
        class'SirenScreamDamage';
    class'ZombieSiren_XMas'.default.screamDamageType = class'SirenScreamDamage';
    class'ZombieSiren_CIRCUS'.default.screamDamageType =
        class'SirenScreamDamage';
}

private function int OnNetDamageHandler(
    int                 originalDamage,
    int                 damage,
    Pawn                injured,
    Pawn                instigatedBy,
    Vector              hitLocation,
    out Vector          momentum,
    class<DamageType>   damageType)
{
    local KFPlayerReplicationInfo kfPRI;

    if (damageType != class'Dummy_DamTypeVomit')    return damage;
    if (ZombieBloatBase(injured) != none)           return 0;
    if (ZombieFleshpoundBase(injured) != none)      return 0;

    return damage;
}

private function UpdateBileAchievement(Controller killer, Controller killed)
{
    local int                                   i;
    local KFMonster                             killedMonster;
    local ConnectionService                     service;
    local KFSteamStatsAndAchievements           kfSteamStats;
    local array<ConnectionService.Connection>   activeConnections;

    //  `GameInfo` checks that `killed != none`, but between that and this point
    //  a lot of things can change, so don't count on it and check
    if (killed == none)                                                 return;
    killedMonster = KFMonster(killed.pawn);
    if (killedMonster == none)                                          return;
    if (killedMonster.lastDamagedByType != class'Dummy_DamTypeVomit')   return;
    service = ConnectionService(class'ConnectionService'.static.Require());
    if (service == none)                                                return;

    activeConnections = service.GetActiveConnections();
    for (i = 0; i < activeConnections.length; i += 1)
    {
        kfSteamStats = KFSteamStatsAndAchievements(activeConnections[i]
            .controllerReference
            .steamStatsAndAchievements);
        if (kfSteamStats != none) {
            kfSteamStats.KilledEnemyWithBloatAcid();
        }
    }
}


defaultproperties
{
    replaceBloatAndSirenDamageTypes = true
    infoReplacingDamageTypes            = (l=LOG_Info,m="Replacing bloat's and siren's damage types to dummy ones.")
    infoRestoringReplacingDamageTypes   = (l=LOG_Info,m="Restoring bloat and siren's damage types to their original values.")
    errNoServerLevelCore                = (l=LOG_Error,m="Server level core is missing. Either this isn't a server or Acedia was wrongly initialized. Bloat and siren damage type will not be replaced.")
}