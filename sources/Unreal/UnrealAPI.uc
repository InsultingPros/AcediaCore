/**
 *      Low-level API that provides set of utility methods for working with
 *  unreal script classes.
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
class UnrealAPI extends AcediaObject;

/**
 *  Returns current game's `LevelInfo`. Useful because `level` variable
 *  is not defined inside objects.
 *
 *  @return `LevelInfo` instance for the current game. Guaranteed to
 *      not be `none`.
 */
public final function LevelInfo GetLevel()
{
    return class'CoreService'.static.GetInstance().level;
}

/**
 *  Returns current game's `GameInfo`. Useful because `level.game` is not
 *  accessible inside objects.
 *
 *  @return `GameInfo` instance for the current game. Guaranteed to
 *      not be `none`.
 */
public final function GameInfo GetGameType()
{
    return class'CoreService'.static.GetInstance().level.game;
}

/**
 *  Returns current game's `GameInfo` as `KFGameType`. Useful because
 *  `level.game` is not accessible inside objects and because it auto converts
 *  game type to `KFGameType`, which virtually all mods for killing floor use
 *  (by itself or as a base class).
 *
 *  @return `KFGameType` instance for the current game. Can be `none` only if
 *      game was modded to run a `GameInfo` not derived from `KFGameType`.
 */
public final function KFGameType GetKFGameType()
{
    return KFGameType(GetGameType());
}

/**
 *  Returns current local player's `Controller`. Useful because `level`
 *  is not accessible inside objects.
 *
 *  @return `PlayerController` instance for the local player. `none` iff run on
 *      dedicated servers.
 */
public final function PlayerController GetLocalPlayer()
{
    return class'CoreService'.static.GetInstance().level
        .GetLocalPlayerController();
}

/**
 *  Checks if given class of `GameRules` is currently active in `GameInfo`.
 *
 *  @param  rulesClassToCheck   Class of rules to check for.
 *  @return `true` if `GameRules` are active and `false` otherwise.
 */
public final function bool AreGameRulesAdded(
    class<GameRules> rulesClassToCheck)
{
    local GameRules rulesIter;
    if (rulesClassToCheck == none) {
        return false;
    }
    rulesIter = GetGameType().gameRulesModifiers;
    while (rulesIter != none)
    {
        if (rulesIter.class == rulesClassToCheck) {
            return true;
        }
        rulesIter = rulesIter.nextGameRules;
    }
    return false;
}

/**
 *  Adds new `GameRules` class to the current `GameInfo`.
 *  Does nothing if give `GameRules` class was already added before.
 *
 *  @param  newRulesClass   Class of rules to add.
 *  @return `true` if `GameRules` were added and `false` otherwise
 *      (because they were already active.)
 */
public final function bool AddGameRules(class<GameRules> newRulesClass)
{
    if (AreGameRulesAdded(newRulesClass)) {
        return false;
    }
    GetGameType().AddGameModifier(GameRules(_.memory.Allocate(newRulesClass)));
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
public final function bool RemoveGameRules(class<GameRules> rulesClassToRemove)
{
    local GameInfo  game;
    local GameRules rulesIter;
    local GameRules rulesToDestroy;
    if (rulesClassToRemove == none)         return false;
    game = GetGameType();
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
 *  Convenience method for finding a first inventory entry of the given
 *  class `inventoryClass` in the given inventory chain `inventoryChain`.
 *
 *  Inventory is stored as a linked list, where next inventory item is available
 *  through the `inventory` reference. This method follows this list, starting
 *  from `inventoryChain` until it finds `Inventory` of the appropriate class
 *  or reaches the end of the list.
 *
 *  @param  inventoryClass      Class of the inventory we are interested in.
 *  @param  inventoryChain      Inventory chain in which we should search for
 *      the given class.
 *  @param  acceptChildClass    `true` if method should also return any
 *      `Inventory` of class derived from `inventoryClass` and `false` if
 *      we want given class specifically (default).
 *  @return First inventory from `inventoryChain` that matches given
 *      `inventoryClass` class (whether exactly or as a child class,
 *      in case `acceptChildClass == true`).
 */
public final function Inventory GetInventoryFrom(
    class<Inventory>    inventoryClass,
    Inventory           inventoryChain,
    optional bool       acceptChildClass)
{
    if (inventoryClass == none) {
        return none;
    }
    while (inventoryChain != none)
    {
        if (inventoryChain.class == inventoryClass) {
            return inventoryChain;
        }
        if (    acceptChildClass
            &&  ClassIsChildOf(inventoryChain.class, inventoryClass))
        {
            return inventoryChain;
        }
        inventoryChain = inventoryChain.inventory;
    }
    return none;
}

/**
 *  Convenience method for finding a all inventory entries of the given
 *  class `inventoryClass` in the given inventory chain `inventoryChain`.
 *
 *  Inventory is stored as a linked list, where next inventory item is available
 *  through the `inventory` reference. This method follows this list, starting
 *  from `inventoryChain` until the end of the list.
 *
 *  @param  inventoryClass      Class of the inventory we are interested in.
 *  @param  inventoryChain      Inventory chain in which we should search for
 *      the given class.
 *  @param  acceptChildClass    `true` if method should also return any
 *      `Inventory` of class derived from `inventoryClass` and `false` if
 *      we want given class specifically (default).
 *  @return Array of inventory items from `inventoryChain` that match given
 *      `inventoryClass` class (whether exactly or as a child class,
 *      in case `acceptChildClass == true`).
 */
public final function array<Inventory> GetAllInventoryFrom(
    class<Inventory>    inventoryClass,
    Inventory           inventoryChain,
    optional bool       acceptChildClass)
{
    local bool              shouldAdd;
    local array<Inventory>  result;
    if (inventoryClass == none) {
        return result;
    }
    while (inventoryChain != none)
    {
        shouldAdd = false;
        if (inventoryChain.class == inventoryClass) {
            shouldAdd = true;
        }
        else if (acceptChildClass) {
            shouldAdd = ClassIsChildOf(inventoryChain.class, inventoryClass);
        }
        if (shouldAdd) {
            result[result.length] = inventoryChain;
        }
        inventoryChain = inventoryChain.inventory;
    }
    return result;
}

/**
 *  Creates reference object to store a `Actor` value.
 *
 *  @param  value   Initial value to store in reference.
 *  @return `NativeActorRef`, containing `value`.
 */
public final function NativeActorRef ActorRef(optional Actor value)
{
    local NativeActorRef ref;
    ref = NativeActorRef(_.memory.Allocate(class'NativeActorRef'));
    ref.Set(value);
    return ref;
}

defaultproperties
{
}