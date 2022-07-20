/**
 *  Acedia's default implementation for `GameRulesAPI` API.
 *      Copyright 2021-2022 Anton Tarasenko
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
class KF1_GameRulesAPI extends GameRulesAPI;

//  Tracks if we have already tried to add our own `BroadcastHandler` to avoid
//  wasting resources/spamming errors in the log about our inability to do so
var private bool triedToInjectGameRules;

var private LoggerAPI.Definition infoAddedGameRules;
var private LoggerAPI.Definition errGameRulesForbidden;
var private LoggerAPI.Definition errGameRulesUnknown;

/* SIGNAL */
public function GameRules_OnFindPlayerStart_Slot OnFindPlayerStart(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryAddingGameRules(service);
    signal = service.GetSignal(class'GameRules_OnFindPlayerStart_Signal');
    return GameRules_OnFindPlayerStart_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function GameRules_OnHandleRestartGame_Slot OnHandleRestartGame(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryAddingGameRules(service);
    signal = service.GetSignal(class'GameRules_OnHandleRestartGame_Signal');
    return GameRules_OnHandleRestartGame_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function GameRules_OnCheckEndGame_Slot OnCheckEndGame(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryAddingGameRules(service);
    signal = service.GetSignal(class'GameRules_OnCheckEndGame_Signal');
    return GameRules_OnCheckEndGame_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function GameRules_OnCheckScore_Slot OnCheckScore(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryAddingGameRules(service);
    signal = service.GetSignal(class'GameRules_OnCheckScore_Signal');
    return GameRules_OnCheckScore_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function GameRules_OnOverridePickupQuery_Slot
    OnOverridePickupQuery(AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryAddingGameRules(service);
    signal = service.GetSignal(class'GameRules_OnOverridePickupQuery_Signal');
    return GameRules_OnOverridePickupQuery_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function GameRules_OnNetDamage_Slot OnNetDamage(AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryAddingGameRules(service);
    signal = service.GetSignal(class'GameRules_OnNetDamage_Signal');
    return GameRules_OnNetDamage_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function GameRules_OnPreventDeath_Slot OnPreventDeath(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryAddingGameRules(service);
    signal = service.GetSignal(class'GameRules_OnPreventDeath_Signal');
    return GameRules_OnPreventDeath_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function GameRules_OnScoreKill_Slot OnScoreKill(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryAddingGameRules(service);
    signal = service.GetSignal(class'GameRules_OnScoreKill_Signal');
    return GameRules_OnScoreKill_Slot(signal.NewSlot(receiver));
}

/**
 *  Method that attempts to inject Acedia's `AcediaGameRules`, while
 *  respecting settings inside `class'SideEffects'`.
 *
 *  @param  service Reference to `ServerUnrealService` to exchange signal and
 *      slots classes with.
 */
protected function TryAddingGameRules(ServerUnrealService service)
{
    local AcediaGameRules       gameRules;
    local GameRulesSideEffect   sideEffect;

    if (triedToInjectGameRules) {
        return;
    }
    triedToInjectGameRules = true;
    if (!class'SideEffects'.default.allowAddingGameRules)
    {
        _.logger.Auto(errGameRulesForbidden);
        return;
    }
    gameRules = AcediaGameRules(Add(class'AcediaGameRules'));
    if (gameRules != none)
    {
        gameRules.Initialize(service);
        sideEffect =
            GameRulesSideEffect(_.memory.Allocate(class'GameRulesSideEffect'));
        sideEffect.Initialize();
        _server.sideEffects.Add(sideEffect);
        _.memory.Free(sideEffect);
        _.logger.Auto(infoAddedGameRules);
    }
    else {
        _.logger.Auto(errGameRulesUnknown);
    }
}

public function GameRules Add(class<GameRules> newRulesClass)
{
    local GameRules newGameRules;
    if (AreAdded(newRulesClass)) {
        return none;
    }
    newGameRules = GameRules(_.memory.Allocate(newRulesClass));
    _server.unreal.GetGameType().AddGameModifier(newGameRules);
    return newGameRules;
}

public function bool Remove(class<GameRules> rulesClassToRemove)
{
    local GameInfo  game;
    local GameRules rulesIter;
    local GameRules rulesToDestroy;
    if (rulesClassToRemove == none)         return false;
    game = _server.unreal.GetGameType();
    if (game.gameRulesModifiers == none)    return false;

    //  Check root rules
    rulesToDestroy = game.gameRulesModifiers;
    if (rulesToDestroy.class == rulesClassToRemove)
    {
        game.gameRulesModifiers = rulesToDestroy.nextGameRules;
        rulesToDestroy.Destroy();
        return true;
    }
    //  Check rest of the rules
    rulesIter = game.gameRulesModifiers;
    while (rulesIter != none)
    {
        rulesToDestroy = rulesIter.nextGameRules;
        if (    rulesToDestroy != none
            &&  rulesToDestroy.class == rulesClassToRemove)
        {
            rulesIter.nextGameRules = rulesToDestroy.nextGameRules;
            rulesToDestroy.Destroy();
            return true;
        }
        rulesIter = rulesIter.nextGameRules;
    }
    return false;
}

public function GameRules FindInstance(class<GameRules> rulesClassToFind)
{
    local GameRules rulesIter;
    if (rulesClassToFind == none) {
        return none;
    }
    rulesIter = _server.unreal.GetGameType().gameRulesModifiers;
    while (rulesIter != none)
    {
        if (rulesIter.class == rulesClassToFind) {
            return rulesIter;
        }
        rulesIter = rulesIter.nextGameRules;
    }
    return none;
}

public function bool AreAdded(class<GameRules> rulesClassToCheck)
{
    return (FindInstance(rulesClassToCheck) != none);
}

defaultproperties
{
    infoAddedGameRules      = (l=LOG_Info,m="Added AcediaCore's `AcediaGameRules`.")
    errGameRulesForbidden   = (l=LOG_Error,m="Adding AcediaCore's `AcediaGameRules` is required, but forbidden by AcediaCore's settings: in file \"AcediaSystem.ini\", section [AcediaCore.SideEffects], variable `allowAddingGameRules`.")
    errGameRulesUnknown     = (l=LOG_Error,m="Adding AcediaCore's `AcediaGameRules` failed to be injected with level for unknown reason.")
}