/**
 *      Service for the needs of `UnrealAPI`. Mainly tasked with creating API's
 *  `Signal`s.
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
class UnrealService extends Service;

struct SignalRecord
{
    var class<Signal>   signalClass;
    var Signal          instance;
};
var private array<SignalRecord> serviceSignals;
var private Unreal_OnTick_Signal onTickSignal;

protected function OnLaunch()
{
    local AcediaGameRules gameRules;
    CreateSignals();
    _.unreal.gameRules.Add(class'AcediaGameRules');
    gameRules = AcediaGameRules(
        _.unreal.gameRules.FindInstance(class'AcediaGameRules'));
    gameRules.Initialize(self);
}

protected function OnShutdown()
{
    _.unreal.gameRules.Remove(class'AcediaGameRules');
}

private final function CreateSignals()
{
    local int i;
    onTickSignal = Unreal_OnTick_Signal(
        _.memory.Allocate(class'Unreal_OnTick_Signal'));
    for (i = 0; i < serviceSignals.length; i += 1)
    {
        if (serviceSignals[i].instance != none)     continue;
        if (serviceSignals[i].signalClass == none)  continue;

        serviceSignals[i].instance =
            Signal(_.memory.Allocate(serviceSignals[i].signalClass));
    }
}

public final function Signal GetSignal(class<Signal> requiredClass)
{
    local int i;
    if (requiredClass == class'Unreal_OnTick_Signal') {
        return onTickSignal;
    }
    for (i = 0; i < serviceSignals.length; i += 1)
    {
        if (serviceSignals[i].signalClass == requiredClass) {
            return serviceSignals[i].instance;
        }
    }
    return none;
}


public event Tick(float delta)
{
    local float dilationCoefficient;
    if (onTickSignal != none)
    {
        dilationCoefficient = level.timeDilation / 1.1;
        onTickSignal.Emit(delta, dilationCoefficient);
    }
}

defaultproperties
{
    serviceSignals(0) = (signalClass=class'GameRules_OnFindPlayerStart_Signal')
    serviceSignals(1) = (signalClass=class'GameRules_OnOverridePickupQuery_Signal')
    serviceSignals(2) = (signalClass=class'GameRules_OnNetDamage_Signal')
}