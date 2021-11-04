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

var public MutatorAPI   mutator;
var public GameRulesAPI gameRules;
var public BroadcastAPI broadcasts;

var private LoggerAPI.Definition fatalNoStalker;

protected function Constructor()
{
    mutator     = MutatorAPI(_.memory.Allocate(class'MutatorAPI'));
    gameRules   = GameRulesAPI(_.memory.Allocate(class'GameRulesAPI'));
    broadcasts  = BroadcastAPI(_.memory.Allocate(class'BroadcastAPI'));
}

public function DropAPI()
{
    mutator     = none;
    gameRules   = none;
    broadcasts  = none;
}

/**
 *  Signal that will be emitted every tick.
 *
 *  [Signature]
 *  void <slot>(float delta, float dilationCoefficient)
 *
 *  @param  delta               In-game time in seconds that has passed since
 *      the last tick. To obtain real time passed from the last tick divide
 *      `delta` by `dilationCoefficient`.
 *  @param  dilationCoefficient How fast is in-game time flow compared to
 *      the real world's one? `2` means twice as fast and
 *      `0.5` means twice as slow.
 */
/* SIGNAL */
public final function Unreal_OnTick_Slot OnTick(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;
    service = UnrealService(class'UnrealService'.static.Require());
    signal = service.GetSignal(class'Unreal_OnTick_Signal');
    return Unreal_OnTick_Slot(signal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted when a passed `targetToStalk` is destroyed.
 *
 *  Passed parameter `targetToStalk` cannot be `none`, otherwise `none` will be
 *  returned instead of a valid slot.
 *
 *  @param  receiver        Specify a receiver like for any other signal.
 *  @param  targetToStalk   Actor whose destruction we want to detect.
 *
 *  [Signature]
 *  void <slot>()
 */
/* SIGNAL */
public final function SimpleSlot OnDestructionFor(
    AcediaObject    receiver,
    Actor           targetToStalk)
{
    local ActorStalker stalker;
    if (receiver == none)       return none;
    if (targetToStalk == none)  return none;

    //  Failing to spawn this actor without any collision flags is considered
    //  completely unexpected and grounds for fatal failure on Acedia' part
    stalker = ActorStalker(_.memory.Allocate(class'ActorStalker'));
    if (stalker == none)
    {
        _.logger.Auto(fatalNoStalker);
        return none;
    }
    //  This will not fail, since we have already ensured that
    //  `targetToStalk == none`
    stalker.Initialize(targetToStalk);
    return stalker.OnActorDestruction(receiver);
}

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
 *  Returns current game's `GameReplicationInfo`. Useful because `level.game`
 *  is not accessible inside objects.
 *
 *  @return `GameReplicationInfo` instance for the current game. Guaranteed to
 *      not be `none`.
 */
public final function GameReplicationInfo GetGameRI()
{
    return class'CoreService'.static.GetInstance().level.GRI;
}

/**
 *  Returns current game's `GameReplicationInfo` as `KFGameReplicationInfo`.
 *  Useful because `level.game` is not accessible inside objects and because it
 *  auto converts game replication info type to `KFGameReplicationInfo`, which
 *  virtually all mods for killing floor use (by itself or as a base class).
 *
 *  @return `KFGameReplicationInfo` instance for the current game.
 *      Can be `none` only if game was modded to run a `KFGameReplicationInfo`
 *      not derived from `KFGameType`.
 */
public final function KFGameReplicationInfo GetKFGameRI()
{
    return KFGameReplicationInfo(GetGameRI());
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
 *  Searches all `Actor`s on the level for an instance of specific class and
 *  returns it.
 *
 *  @param  classToFind Class we want to find an instance of.
 *  @result A pre-existing instance of class `classToFind`, `none` if
 *      no instances exist at the moment of this method's call.
 */
public final function Actor FindActorInstance(class<Actor> classToFind)
{
    local Actor result;
    local Service service;
    service = class'CoreService'.static.Require();
    foreach service.AllActors(classToFind, result)
    {
        if (result != none) {
            break;
        }
    }
    return result;
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
    fatalNoStalker = (l=LOG_Fatal,m="Cannot spawn `PawnStalker`")
}