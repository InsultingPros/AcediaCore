/**
 *  Subset of functionality for dealing with basic game world interactions:
 *  searching for entities, tracing, etc..
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
class AWorldComponent extends AcediaObject
    abstract;

/**
 *  Traces world for entities starting from `start` point and continuing into
 *  the direction `direction` for a "far distance". What is considered
 *  a "far distance" depends on the implementation (can potentially be infinite
 *  distance).
 *
 *  @param  start       Point from which to start tracing.
 *  @param  direction   Direction alongside which to trace.
 *  @return `TracingIterator` that will iterate among `EPlaceable` interfaces
 *      for traced entities. Iteration is done in order from the entity closest
 *      to `start` point.
 */
public function TracingIterator Trace(Vector start, Rotator direction);

/**
 *  Traces world for entities starting from `start` point and until `end` point.
 *
 *  @param  start   Point from which to start tracing.
 *  @param  end     Point at which to stop tracing.
 *  @return `TracingIterator` that will iterate among `EPlaceable` interfaces
 *      for traced entities. Iteration is done in order from the entity closest
 *      to `start` point.
 */
public function TracingIterator TraceBetween(Vector start, Vector end);

/**
 *  Traces world for entities starting from the `player`'s camera position and
 *  along the direction of his sight.
 *
 *  This method works for both players with and without pawns. For player with
 *  a pawn it produce identical results to `TraceSight()` method.
 *
 *  @param  player  Player alongside whos sight method is supposed to trace.
 *  @return `TracingIterator` that will iterate among `EPlaceable` interfaces
 *      for traced entities. Iteration is done in order from the entity closest
 *      to `player`'s camera location.
 */
public function TracingIterator TracePlayerSight(EPlayer player);

/**
 *  Traces world for entities starting from the `pawn`'s camera position and
 *  along the direction of his sight.
 *
 *  @param  pawn    Pawn alongside whos sight method is supposed to trace.
 *  @return `TracingIterator` that will iterate among `EPlaceable` interfaces
 *      for traced entities. Iteration is done in order from the entity closest
 *      to `pawn`'s eyes location.
 */
public function TracingIterator TraceSight(EPawn pawn);

/**
 *  Spawns a new `EPlaceable` based on the given `template` at a given location
 *  `location`, facing it into the given direction `direction`.
 *
 *  @param  template    Describes entity (supporting `EPlaceable` interface) to
 *      spawn into the world.
 *  @param  location    At what location to spawn that entity.
 *  @param  direction   In what direction spawned entity must face.
 *  @return `EPlaceable` interface for the spawned entity. `none` if spawning it
 *      has failed. If method returns interface to a non-existent entity, it
 *      means that entity has successfully spawned, but then something handled
 *      its spawning and destroyed it.
 */
public function EPlaceable Spawn(
    BaseText            template,
    optional Vector     location,
    optional Rotator    direction);

/**
 *  Returns iterator for going through all entities in the game world.
 *
 *  @return `EntityIterator` that will iterate through world entities.
 */
public function EntityIterator Entities();

defaultproperties
{
}