/**
 *      Low-level API that provides set of utility methods for working with
 *  `GameRule`s.
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
class GameRulesAPI extends AcediaObject;

/**
 *  Called when game decides on a player's spawn point. If a `NavigationPoint`
 *  is returned, signal propagation will be interrupted and returned value will
 *  be used as the player start.
 *
 *  [Signature]
 *  NavigationPoint <slot>(
 *      Controller      player,
 *      optional byte   inTeam,
 *      optional string incomingName)
 *
 *  @param  player          Player for whom we are picking a spawn point.
 *  @param  inTeam          Player's team number.
 *  @param  incomingName    `Portal` parameter from `GameInfo.Login()` event.
 *  @return `NavigationPoint` that will player must be spawned at.
 *      `none` means that slot does not want to modify it.
 */
/* SIGNAL */
public final function GameRules_OnFindPlayerStart_Slot OnFindPlayerStart(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;
    service = UnrealService(class'UnrealService'.static.Require());
    signal = service.GetSignal(class'GameRules_OnFindPlayerStart_Signal');
    return GameRules_OnFindPlayerStart_Slot(signal.NewSlot(receiver));
}

/**
 *  Called in `GameInfo`'s `RestartGame()` method and allows to prevent
 *  game's restart.
 *
 *  This signal will always be propagated to all registered slots.
 *
 *  [Signature]
 *  bool <slot>()
 *
 *  @return `true` if you want to prevent game restart and `false` otherwise.
 */
/* SIGNAL */
public final function GameRules_OnHandleRestartGame_Slot OnHandleRestartGame(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;
    service = UnrealService(class'UnrealService'.static.Require());
    signal = service.GetSignal(class'GameRules_OnHandleRestartGame_Signal');
    return GameRules_OnHandleRestartGame_Slot(signal.NewSlot(receiver));
}

/**
 *  Allows modification of game ending conditions.
 *  Return `false` to prevent game from ending.
 *
 *  This signal will always be propagated to all registered slots.
 *
 *  [Signature]
 *  bool <slot>(PlayerReplicationInfo winner, string reason)
 *
 *  @param  winner  Replication info of the supposed winner of the game.
 *  @param  reason  String with a description about how/why `winner` has won.
 *  @return `false` if you want to prevent game from ending
 *      and `false` otherwise.
 */
/* SIGNAL */
public final function GameRules_OnCheckEndGame_Slot OnCheckEndGame(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;
    service = UnrealService(class'UnrealService'.static.Require());
    signal = service.GetSignal(class'GameRules_OnHandleRestartGame_Signal');
    return GameRules_OnCheckEndGame_Slot(signal.NewSlot(receiver));
}

/* CheckScore()

*/
/**
 *  Check if this score means the game ends.
 *
 *  Return `true` to override `GameInfo`'s `CheckScore()`, or if game was ended
 *  (with a call to `Level.Game.EndGame()`).
 *
 *  [Signature]
 *  bool <slot>(PlayerReplicationInfo scorer)
 *
 *  @param  scorer  For whom to do a score check.
 *  @return `true` to override `GameInfo`'s `CheckScore()`, or if game was ended
 *      and `false` otherwise.
 */
/* SIGNAL */
public final function GameRules_OnCheckScore_Slot OnCheckScore(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;
    service = UnrealService(class'UnrealService'.static.Require());
    signal = service.GetSignal(class'GameRules_OnCheckScore_Signal');
    return GameRules_OnCheckScore_Slot(signal.NewSlot(receiver));
}

/**
 *      When pawn wants to pickup something, `GameRule`s are given a chance to
 *  modify it.  If one of the `Slot`s returns `true`, `allowPickup` will
 *  determine if the object can be picked up.
 *      Overriding via this method allows to completely bypass check against
 *  `Pawn`'s inventory's `HandlePickupQuery()` method.
 *
 *  [Signature]
 *  bool <slot>(Pawn other, Pickup item, out byte allowPickup)
 *
 *  @param  other       Pawn which will potentially pickup `item`.
 *  @param  item        Pickup which `other` might potentially pickup.
 *  @param  allowPickup `true` if you want to force `other` to pickup an item
 *      and `false` otherwise. This parameter is ignored if returned value of
 *      your slot call is `false`.
 *  @return `true` if you wish to override decision about pickup with
 *      `allowPickup` and `false` if you do not want to make that decision.
 *      If you do decide to override decision by returning `true` - this signal
 *      will not be propagated to the rest of the slots.
 */
/* SIGNAL */
public final function GameRules_OnOverridePickupQuery_Slot
    OnOverridePickupQuery(AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;
    service = UnrealService(class'UnrealService'.static.Require());
    signal = service.GetSignal(class'GameRules_OnOverridePickupQuery_Signal');
    return GameRules_OnOverridePickupQuery_Slot(signal.NewSlot(receiver));
}

/**
 *      When pawn wants to pickup something, `GameRule`s are given a chance to
 *  modify it.  If one of the `Slot`s returns `true`, `allowPickup` will
 *  determine if the object can be picked up.
 *      Overriding via this method allows to completely bypass check against
 *  `Pawn`'s inventory's `HandlePickupQuery()` method.
 *
 *  [Signature]
 *  bool <slot>(Pawn other, Pickup item, out byte allowPickup)
 *
 *  @param  other       Pawn which will potentially pickup `item`.
 *  @param  item        Pickup which `other` might potentially pickup.
 *  @param  allowPickup `true` if you want to force `other` to pickup an item
 *      and `false` otherwise. This parameter is ignored if returned value of
 *      your slot call is `false`.
 *  @return `true` if you wish to override decision about pickup with
 *      `allowPickup` and `false` if you do not want to make that decision.
 *      If you do decide to override decision by returning `true` - this signal
 *      will not be propagated to the rest of the slots.
 */
/* SIGNAL */
public final function GameRules_OnNetDamage_Slot OnNetDamage(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;
    service = UnrealService(class'UnrealService'.static.Require());
    signal = service.GetSignal(class'GameRules_OnNetDamage_Signal');
    return GameRules_OnNetDamage_Slot(signal.NewSlot(receiver));
}

/**
 *  Adds new `GameRules` class to the current `GameInfo`.
 *  Does nothing if give `GameRules` class was already added before.
 *
 *  @param  newRulesClass   Class of rules to add.
 *  @return `true` if `GameRules` were added and `false` otherwise
 *      (because they were already active.)
 */
public final function bool Add(class<GameRules> newRulesClass)
{
    if (AreAdded(newRulesClass)) {
        return false;
    }
    _.unreal.GetGameType()
        .AddGameModifier(GameRules(_.memory.Allocate(newRulesClass)));
    return true;
}

/**
 *  Removes given `GameRules` class from the current `GameInfo`,
 *  if they are active. Does nothing otherwise.
 *
 *  @param  rulesClassToRemove  Class of rules to try and remove.
 *  @return `true` if `GameRules` were removed and `false` otherwise
 *      (if they were not active in the first place).
 */
public final function bool Remove(class<GameRules> rulesClassToRemove)
{
    local GameInfo  game;
    local GameRules rulesIter;
    local GameRules rulesToDestroy;
    if (rulesClassToRemove == none)         return false;
    game = _.unreal.GetGameType();
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

/**
 *  Finds given class of `GameRules` if it's currently active in `GameInfo`.
 *  Returns `none` otherwise.
 *
 *  @param  rulesClassToFind    Class of rules to find.
 *  @return `GameRules` of given class `rulesClassToFind` instance added to
 *      `GameInfo`'s records and `none` if no such rules are currently added.
 */
public final function GameRules FindInstance(
    class<GameRules> rulesClassToFind)
{
    local GameRules rulesIter;
    if (rulesClassToFind == none) {
        return none;
    }
    rulesIter = _.unreal.GetGameType().gameRulesModifiers;
    while (rulesIter != none)
    {
        if (rulesIter.class == rulesClassToFind) {
            return rulesIter;
        }
        rulesIter = rulesIter.nextGameRules;
    }
    return none;
}

/**
 *  Checks if given class of `GameRules` is currently active in `GameInfo`.
 *
 *  @param  rulesClassToCheck   Class of rules to check for.
 *  @return `true` if `GameRules` are active and `false` otherwise.
 */
public final function bool AreAdded(
    class<GameRules> rulesClassToCheck)
{
    return (FindInstance(rulesClassToCheck) != none);
}

defaultproperties
{
}