/**
 *  Acedia's `GameRules` class that provides `GameRules`'s events through
 *  the signal/slot functionality.
 *      Copyright 2021 Anton Tarasenko
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
class AcediaGameRules extends GameRules;

var private GameRules_OnFindPlayerStart_Signal      onFindPlayerStartSignal;
var private GameRules_OnOverridePickupQuery_Signal  onOverridePickupQuery;
var private GameRules_OnNetDamage_Signal            onNetDamage;

public final function Initialize(unrealService service)
{
    if (service == none) {
        return;
    }
    onFindPlayerStartSignal = GameRules_OnFindPlayerStart_Signal(
        service.GetSignal(class'GameRules_OnFindPlayerStart_Signal'));
    onOverridePickupQuery   = GameRules_OnOverridePickupQuery_Signal(
        service.GetSignal(class'GameRules_OnOverridePickupQuery_Signal'));
    onNetDamage             = GameRules_OnNetDamage_Signal(
        service.GetSignal(class'GameRules_OnNetDamage_Signal'));
}

function string GetRules()
{
    local string resultSet;
    resultSet = "acedia";
    if (nextGameRules != none) {
        resultSet = resultSet $ nextGameRules.GetRules();
    }
    return resultSet;
}

function NavigationPoint FindPlayerStart(
    Controller      player,
    optional byte   inTeam,
    optional string incomingName)
{
    local NavigationPoint result;
    if (onFindPlayerStartSignal != none) {
        result = onFindPlayerStartSignal.Emit(player, inTeam, incomingName);
    }
    if (result == none && nextGameRules != none) {
        return nextGameRules.FindPlayerStart(player, inTeam, incomingName);
    }
    return result;
}

function bool OverridePickupQuery(
    Pawn        other,
    Pickup      item,
    out byte    allowPickup)
{
    local bool shouldOverride;
    if (onOverridePickupQuery != none) {
        shouldOverride = onOverridePickupQuery.Emit(other, item, allowPickup);
    }
    if (shouldOverride) {
        return true;
    }
    if (nextGameRules != none) {
        return nextGameRules.OverridePickupQuery(other, item, allowPickup);
    }
    return false;
}

function int NetDamage(
    int                 originalDamage,
    int                 damage,
    Pawn                injured,
    Pawn                instigatedBy,
    Vector              hitLocation,
    out Vector          momentum,
    class<DamageType>   damageType)
{
    if (onNetDamage != none)
    {
        damage = onNetDamage.Emit(  originalDamage, damage, injured,
                                    instigatedBy, hitLocation, momentum,
                                    damageType);
    }
    if (nextGameRules != none)
    {
        return nextGameRules.NetDamage( originalDamage, damage, injured,
                                        instigatedBy, hitLocation, momentum,
                                        damageType);
    }
    return damage;
}

defaultproperties
{
}