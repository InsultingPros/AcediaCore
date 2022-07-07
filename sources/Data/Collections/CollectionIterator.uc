/**
 *      Base class for collection iterators, an auxiliary object for iterating
 *  through objects stored inside an Acedia's collection.
 *      Iterators expect that collection remains unchanged while they
 *  are iterating through it. Otherwise their behavior becomes undefined.
 *      Copyright 2020-2022 Anton Tarasenko
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
class CollectionIterator extends Iter
    abstract;

/**
 *  Initialized caller `Iterator` to iterate over a given collection.
 *
 *  `Iterator` should only be initialized once, reinitializing `Iterator` is
 *  considered an undefined behavior. Collection's `Iterate()` method is
 *  a preferred method to create initialized `Iterator`.
 *
 *  Initialization is not guaranteed to be successful, - each iterator class
 *  corresponds to a particular collection and it's not `none` reference must
 *  be used as an argument.
 *
 *  @param  relevantCollection  `Collection` over which items `Iterator`
 *      must iterate.
 *  @param  `true` if iteration was successful and `false` otherwise.
 */
public function bool Initialize(Collection relevantCollection);

/**
 *  Returns key of current value pointed to by an iterator.
 *
 *  NOTE: this method is guaranteed to return reference to the key used in
 *  relevant `Collection` if it actually stores key objects inside.
 *  However for other `Collection`s this method may create a "replacement"
 *  object (like `ArrayList` creating `IntBox` to simply return integer index).
 *
 *  Does not advance iteration: use `Next()` to pick next value.
 *
 *  @return Key of the current value being iterated over.
 *      If `Iterator()` has finished iterating over all values or
 *      was not initialized - returns `none`.
 */
public function AcediaObject GetKey();

defaultproperties
{
}