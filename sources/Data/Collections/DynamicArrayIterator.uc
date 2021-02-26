/**
 *  Iterator for iterating over `DynamicArray`'s items.
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
class DynamicArrayIterator extends Iter;

var private DynamicArray    relevantCollection;
var private int             currentIndex;

protected function Finalizer()
{
    relevantCollection = none;
}

public function bool Initialize(Collection relevantArray)
{
    currentIndex = 0;
    relevantCollection = DynamicArray(relevantArray);
    if (relevantCollection == none) {
        return false;
    }
    return true;
}

public function Iter Next(optional bool skipNone)
{
    local int collectionLength;
    if (!skipNone)
    {
        currentIndex += 1;
        return self;
    }
    collectionLength = relevantCollection.GetLength();
    while (currentIndex < collectionLength)
    {
        currentIndex += 1;
        if (relevantCollection.GetItem(currentIndex) != none) {
            return self;
        }
    }
    return self;
}

public function AcediaObject Get()
{
    return relevantCollection.GetItem(currentIndex);
}

/**
 *  Note that for `DynamicArrayIterator` this method produces a new `IntBox`
 *  object each time and requires manual deallocation.
 */
public function AcediaObject GetKey()
{
    return _.box.int(currentIndex);
}

public function bool HasFinished()
{
    return currentIndex >= relevantCollection.GetLength();
}

defaultproperties
{
}