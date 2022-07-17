/**
 *  Iterator for going through all the entities inside the game world.
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
class EntityIterator extends Iter
    abstract;

/**
 *  Returns only `EPlaceable` interfaces for world entities.
 *
 *  Resulting `EPlaceable` can refer to now non-existing entities if they were
 *  destroyed after the start of iteration.
 */
public function AcediaObject Get() { return none; }

/**
 *  Returns `EPlaceable` caller `EntityIterator` is currently at.
 *  Guaranteed to be not `none` as long as iteration hasn't finished.
 *
 *  Resulting `EPlaceable` can refer to now non-existing entities if they were
 *  destroyed after the start of iteration.
 *
 *  @return `EPlaceable` caller `EntityIterator` is currently at.
 */
public function EPlaceable GetPlaceable();

/**
 *  Returns `EPlaceable` caller `EntityIterator` is currently at as `EPawn`,
 *  assuming that its entity support that interface.
 *
 *  Resulting `EPawn` can refer to now non-existing entities if they were
 *  destroyed after the start of iteration.
 *
 *  @return `EPawn` interface for `EPlaceable` that `Get()` would have returned.
 *      If `EPawn` is not supported by that `EPlaceable` - returns `none`.
 */
public function EPawn GetPawn();

/**
 *  Makes caller iterator skip any entities that do not support `EPawn`
 *  interface during iteration.
 *
 *  @return Reference to caller `EntityIterator` to allow for method chaining.
 */
public function EntityIterator LeaveOnlyPawns();

/**
 *  Makes caller iterator skip any entities that support `EPawn` interface
 *  during iteration.
 *
 *  @return Reference to caller `EntityIterator` to allow for method chaining.
 */
public function EntityIterator LeaveOnlyNonPawns();

/**
 *  Makes caller iterator skip any entities that are placeable (support
 *  `EPlaceable` interface) in the game.
 *
 *  @return Reference to caller `EntityIterator` to allow for method chaining.
 */
public function EntityIterator LeaveOnlyPlaceables();

/**
 *  Makes caller iterator skip any entities that are not placeable (don't
 *  support `EPlaceable` interface) into the game world.
 *
 *  @return Reference to caller `EntityIterator` to allow for method chaining.
 */
public function EntityIterator LeaveOnlyNonPlaceables();

/**
 *  Makes caller iterator skip any entities that are not visible in the game
 *  world.
 *
 *  @return Reference to caller `EntityIterator` to allow for method chaining.
 */
public function EntityIterator LeaveOnlyVisible();

/**
 *  Makes caller iterator skip any entities that are visible in the game
 *  world.
 *
 *  @return Reference to caller `EntityIterator` to allow for method chaining.
 */
public function EntityIterator LeaveOnlyInvisible();

/**
 *  Makes caller iterator skip any entities that are able to collide with other
 *  entities in the game world.
 *
 *  @return Reference to caller `EntityIterator` to allow for method chaining.
 */
public function EntityIterator LeaveOnlyColliding();

/**
 *  Makes caller iterator skip any entities that are unable to collide with
 *  other entities in the game world.
 *
 *  @return Reference to caller `EntityIterator` to allow for method chaining.
 */
public function EntityIterator LeaveOnlyNonColliding();

/**
 *  Makes caller iterator skip any non-static entities that do not change over
 *  time, leaving only dynamic ones.
 *
 *  @return Reference to caller `EntityIterator` to allow for method chaining.
 */
public function EntityIterator LeaveOnlyStatic();

/**
 *  Makes caller iterator skip any static entities that do not change over time.
 *
 *  @return Reference to caller `EntityIterator` to allow for method chaining.
 */
public function EntityIterator LeaveOnlyDynamic();

/**
 *  Leaves only placeable entities that are located no further than `radius`
 *  distance from `placeable`.
 *
 *  @see `LeaveOnlyNearbyToLocation()`
 *
 *  @param  placeable   Interface to entity that iterated entities must be
 *      close to.
 *  @param  radius      Maximum distance that entities are allowed to be away
 *      from `location`.
 *  @return Reference to caller `EntityIterator` to allow for method chaining.
 */
public function EntityIterator LeaveOnlyNearby(
    EPlaceable  placeable,
    float       radius);

/**
 *  Leaves only placeable entities that are located no further than `radius`
 *  distance from `location`.
 *
 *  @see `LeaveOnlyNearby()`
 *
 *  @param  location    Location to which entities must be close to.
 *  @param  radius      Maximum distance that entities are allowed to be away
 *      from `location`.
 *  @return Reference to caller `EntityIterator` to allow for method chaining.
 */
public function EntityIterator LeaveOnlyNearbyToLocation(
    Vector  location,
    float   radius);

/**
 *  Leaves only placeable entities that are touching `placeable`.
 *
 *  `placeable` must have collisions enabled for any entity to touch it.
 */
public function EntityIterator LeaveOnlyTouching(EPlaceable placeable);

defaultproperties
{
}