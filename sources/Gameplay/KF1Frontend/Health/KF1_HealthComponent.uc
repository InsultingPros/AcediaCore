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

var private bool connectedToGameRules;

/**
 *      Unfortunately, thanks to the TWI's code, there's no way to catch events
 *  of when certain kinds of damage are dealt: from welder, bloat's bile and
 *  siren's scream. At least not without something drastic, like replacing game
 *  type class.
 *      As a workaround, Acedia can optionally replace bloat and siren damage
 *  type to at least catch damage dealt by zeds (as being dealt welder damage is
 *  pretty rare and insignificant). This change has several unfortunate
 *  side-effects:
 *      1. Potentially breaking mods that are looking for `DamTypeVomit` and
 *          `SirenScreamDamage` damage types specifically. Fixing this issue
 *          would require these mods to either also try and catch Acedia's
 *          replacements `AcediaCore.Dummy_DamTypeVomit` and
 *          `AcediaCore.Dummy_SirenScreamDamage` or to catch any child classes
 *          of `DamTypeVomit` and `SirenScreamDamage` (as Acedia's replacements
 *          are also their child classes).
 *      2. Breaking some achievements that rely on
 *          `KFSteamStatsAndAchievements`'s `KilledEnemyWithBloatAcid()` method
 *          being called. This is mostly dealt with by Acedia calling it
 *          manually. However it relies on killed pawn to have
 *          `lastDamagedByType` set to `DamTypeVomit`, which sometimes might not
 *          be the case. Achievements should still be obtainable.
 *      3. A lot of siren's visual damage effects code does direct checks for
 *          `SirenScreamDamage` class. These can also break, stopping working as
 *          intended.
 */
var private const config bool replaceBloatAndSirenDamageTypes;

var private const int TDAMAGE, TORIGINAL_DAMAGE, THIT_LOCATION, TMOMENTUM;

var private LoggerAPI.Definition infoReplacingDamageTypes, errNoServerLevelCore;
var private LoggerAPI.Definition infoRestoringReplacingDamageTypes;

public function PseudoConstructor()
{
    local LevelCore core;

    if (!replaceBloatAndSirenDamageTypes) {
        return;
    }
    _.logger.Auto(infoReplacingDamageTypes);
    core = class'ServerLevelCore'.static.GetInstance();
    if (core != none)
    {
        ReplaceDamageTypes(core);
        core.OnShutdown(self).connect = RestoreDamageTypes;
    }
    else {
        _.logger.Auto(errNoServerLevelCore);
    }
}

protected function Finalizer()
{
    super.Finalizer();
    _.unreal.gameRules.OnNetDamage(self).Disconnect();
    _.unreal.gameRules.OnScoreKill(self).Disconnect();
    if (replaceBloatAndSirenDamageTypes) {
        RestoreDamageTypes();
    }
    connectedToGameRules = false;
}

public function Health_OnDamage_Slot OnDamage(AcediaObject receiver)
{
    TryConnectToGameRules();
    return super.OnDamage(receiver);
}

private final function TryConnectToGameRules()
{
    if (connectedToGameRules) {
        return;
    }
    connectedToGameRules = true;
    _.unreal.gameRules.OnNetDamage(self).connect = OnNetDamageHandler;
    //  Fixes achievements
    _.unreal.gameRules.OnScoreKill(self).connect = UpdateBileAchievement;
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
    //  In case Acedia has started mid-game
    foreach core.AllActors(class'KFBloatVomit', nextVomit) {
        nextVomit.myDamageType = class'Dummy_DamTypeVomit';
    }
    foreach core.AllActors(class'ZombieSirenBase', nextSiren) {
        nextSiren.screamDamageType = class'Dummy_SirenScreamDamage';
    }
}

private final function RestoreDamageTypes()
{
    //  No need to restore damage type values for all the preexisting `Actor`s,
    //  since Acedia is not meant to be shutdown mid-game
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
    damage = EmitDamageSignal(
        originalDamage,
        damage,
        injured,
        instigatedBy,
        hitLocation,
        momentum,
        damageType);
    if (damageType != class'Dummy_DamTypeVomit') {
        return damage;
    }
    if (ZombieBloatBase(injured) != none) {
        return 0;
    }
    if (ZombieFleshpoundBase(injured) != none) {
        return 0;
    }
    return damage;
}

private function int EmitDamageSignal(
    int                 originalDamage,
    int                 damage,
    Pawn                injured,
    Pawn                instigatedBy,
    Vector              hitLocation,
    out Vector          momentum,
    class<DamageType>   damageType)
{
    local HashTable damageData;
    local EPawn     target, instigator;

    if (injured != none) {
        target = class'EKFPawn'.static.Wrap(injured);
    }
    if (instigatedBy != none) {
        instigator = class'EKFPawn'.static.Wrap(instigatedBy);
    }
    damageData = _.collections.EmptyHashTable();
    damageData.SetInt(T(TDAMAGE), damage);
    damageData.SetInt(T(TORIGINAL_DAMAGE), originalDamage);
    damageData.SetVector(T(THIT_LOCATION), hitLocation);
    damageData.SetVector(T(TMOMENTUM), momentum, true);
    onDamageSignal.Emit(target, instigator, damageData);
    damage      = damageData.GetInt(T(TDAMAGE), damage);
    momentum    = damageData.GetVector(T(TMOMENTUM), momentum);
    _.memory.Free(damageData);
    _.memory.Free(instigator);
    _.memory.Free(target);
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
    TDAMAGE             = 0
    stringConstants(0) = "damage"
    TORIGINAL_DAMAGE    = 1
    stringConstants(1) = "originalDamage"
    THIT_LOCATION       = 2
    stringConstants(2) = "hitLocation"
    TMOMENTUM           = 3
    stringConstants(3) = "momentum"
    infoReplacingDamageTypes            = (l=LOG_Info,m="Replacing bloat's and siren's damage types to dummy ones.")
    infoRestoringReplacingDamageTypes   = (l=LOG_Info,m="Restoring bloat and siren's damage types to their original values.")
    errNoServerLevelCore                = (l=LOG_Error,m="Server level core is missing. Either this isn't a server or Acedia was wrongly initialized. Bloat and siren damage type will not be replaced.")
}