/**
 *      Base class for iterator, an auxiliary object for iterating through
 *  a set of objects obtained from some context-dependent source.
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
class Iter extends AcediaObject
    abstract;

/**
 *  Iterators can filter objects they're iterating on by a presence or lack of
 *  a certain property, recording this choice requires 3 values, so `bool`
 *  isn't enough and we need to use this `enum` instead.
 */
enum IterFilter
{
    //  We don't use relevant property for filtering
    ITF_Nothing,
    //  Iterated objects must have that property
    ITF_Have,
    //  Iterated objects must not have that property
    ITF_NotHave
};

/**
 *      Makes iterator pick next item.
 *  Use `HasFinished()` to check whether you have iterated all of them.
 *
 *  @return Reference to caller `Iterator` to allow for method chaining.
 */
public function Iter Next();

/**
 *  Returns current value pointed to by an iterator.
 *
 *  Does not advance iteration: use `Next()` to pick next value.
 *
 *  @return Current value being iterated over. If `Iterator()` has finished
 *      iterating over all values or was not initialized - returns `none`.
 *      Note that depending on context `none` values can also be returned,
 *      use `LeaveOnlyNotNone()` method to prevent that.
 */
public function AcediaObject Get();

/**
 *  Checks if caller `Iterator` has finished iterating.
 *
 *  @return `true` if caller `Iterator` has finished iterating or
 *      was not initialized. `false` otherwise.
 */
public function bool HasFinished();

/**
 *  Makes caller iterator skip any `none` items during iteration.
 *
 *  @return Reference to caller `Iterator` to allow for method chaining.
 */
public function Iter LeaveOnlyNotNone();

defaultproperties
{
}