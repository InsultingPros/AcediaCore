/**
 *      Low-level API that provides set of utility methods for working with
 *  unreal script classes.
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
class UnrealAPI extends AcediaObject
    abstract;

public function Initialize(class<AcediaAdapter> adapterClass);

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
public function Unreal_OnTick_Slot OnTick(AcediaObject receiver);

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
public function SimpleSlot OnDestructionFor(
    AcediaObject    receiver,
    Actor           targetToStalk);

/**
 *  Returns current game's `LevelInfo`. Useful because `level` variable
 *  is not defined inside objects.
 *
 *  @return `LevelInfo` instance for the current game. Guaranteed to
 *      not be `none`.
 */
public function LevelInfo GetLevel();

/**
 *  Returns current game's `GameReplicationInfo`. Useful because `level.game`
 *  is not accessible inside objects.
 *
 *  @return `GameReplicationInfo` instance for the current game. Guaranteed to
 *      not be `none`.
 */
public function GameReplicationInfo GetGameRI();

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
public function KFGameReplicationInfo GetKFGameRI();

/**
 *  Returns current game's `GameInfo`. Useful because `level.game` is not
 *  accessible inside objects.
 *
 *  @return `GameInfo` instance for the current game. Guaranteed to
 *      not be `none`.
 */
public function GameInfo GetGameType();

/**
 *  Returns current game's `GameInfo` as `KFGameType`. Useful because
 *  `level.game` is not accessible inside objects and because it auto converts
 *  game type to `KFGameType`, which virtually all mods for killing floor use
 *  (by itself or as a base class).
 *
 *  @return `KFGameType` instance for the current game. Can be `none` only if
 *      game was modded to run a `GameInfo` not derived from `KFGameType`.
 */
public function KFGameType GetKFGameType();

/**
 *  Searches all `Actor`s on the level for an instance of specific class and
 *  returns it.
 *
 *  @param  classToFind Class we want to find an instance of.
 *  @result A pre-existing instance of class `classToFind`, `none` if
 *      no instances exist at the moment of this method's call.
 */
public function Actor FindActorInstance(class<Actor> classToFind);

/**
 *  Creates reference object to store a `Actor` value.
 *
 *  Such references are necessary, since `Actor` references aren't safe to store
 *  inside non-actor `Object`s. To allow that Acedia uses a round about way of
 *  storing all `Actor` references in a special `Actor`, while allowing to refer
 *  to them via `NativeActorRef` (also `ActorRef` for `AcediaActor`s
 *  specifically).
 *
 *  @param  value   Initial value to store in reference.
 *  @return `NativeActorRef`, containing `value`.
 */
public function NativeActorRef ActorRef(optional Actor value);

defaultproperties
{
}