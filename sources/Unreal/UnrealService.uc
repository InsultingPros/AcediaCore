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
var private array<SignalRecord>     serviceSignals;
var private Unreal_OnTick_Signal    onTickSignal;
var private AcediaGameRules         gameRules;

protected function OnLaunch()
{
    local BroadcastEventsObserver broadcastObserver;
    CreateSignals();
    //  Create broadcast handler
    broadcastObserver = BroadcastEventsObserver(_.unreal.broadcasts.Add(
        class'BroadcastEventsObserver',
        class'BroadcastEventsObserver'.default.usedInjectionLevel));
    if (broadcastObserver != none) {
        broadcastObserver.Initialize(self);
    }
    //  Create game rules
    gameRules = AcediaGameRules(_.unreal.gameRules.Add(class'AcediaGameRules'));
    if (gameRules != none) {
        gameRules.Initialize(self);
    }
}

protected function OnShutdown()
{
    local int i;
    if (gameRules != none) {
        gameRules.Cleanup();
    }
    _.unreal.broadcasts.Remove(class'BroadcastEventsObserver');
    _.unreal.gameRules.Remove(class'AcediaGameRules');
    for (i = 0; i < serviceSignals.length; i += 1) {
        _.memory.Free(serviceSignals[i].instance);
    }
    _.memory.Free(onTickSignal);
    serviceSignals.length = 0;
    onTickSignal = none;
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
    serviceSignals(0)   = (signalClass=class'GameRules_OnFindPlayerStart_Signal')
    serviceSignals(1)   = (signalClass=class'GameRules_OnHandleRestartGame_Signal')
    serviceSignals(2)   = (signalClass=class'GameRules_OnCheckEndGame_Signal')
    serviceSignals(3)   = (signalClass=class'GameRules_OnCheckScore_Signal')
    serviceSignals(4)   = (signalClass=class'GameRules_OnOverridePickupQuery_Signal')
    serviceSignals(5)   = (signalClass=class'GameRules_OnNetDamage_Signal')
    serviceSignals(6)   = (signalClass=class'Broadcast_OnBroadcastCheck_Signal')
    serviceSignals(7)   = (signalClass=class'Broadcast_OnHandleLocalized_Signal')
    serviceSignals(8)   = (signalClass=class'Broadcast_OnHandleLocalizedFor_Signal')
    serviceSignals(9)   = (signalClass=class'Broadcast_OnHandleText_Signal')
    serviceSignals(10)  = (signalClass=class'Broadcast_OnHandleTextFor_Signal')
    serviceSignals(11)  = (signalClass=class'Mutator_OnCheckReplacement_Slot')
    serviceSignals(12)  = (signalClass=class'Mutator_OnMutate_Signal')
}