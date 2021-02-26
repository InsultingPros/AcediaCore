/**
 *      Acedia provides a small set of collections for easier data storage.
 *      This is their base class that provides a simple interface for
 *  common methods.
 *      Copyright 2020 Anton Tarasenko
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
class Collection extends AcediaObject
    abstract;

var class<Iter> iteratorClass;

/**
 *  Creates an `Iterator` instance to iterate over stored items.
 *
 *  Returned `Iterator` must be manually deallocated after it was used.
 *
 *  @return New initialized `Iterator` that will iterate over all items in
 *      a given collection. Guaranteed to be not `none`.
 */
public final function Iter Iterate()
{
    local Iter newIterator;
    newIterator = Iter(_.memory.Allocate(iteratorClass));
    if (!newIterator.Initialize(self))
    {
        //  This should not ever happen.
        //  If it does - it is a bug.
        newIterator.FreeSelf();
        return none;
    }
    return newIterator;
}

defaultproperties
{
}