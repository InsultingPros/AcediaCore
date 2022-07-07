/**
 *  Iterator for iterating over `AssociativeArray`'s items.
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
class AssociativeArrayIterator extends CollectionIterator
    dependson(AssociativeArray);

var private bool                    hasNotFinished;
var private AssociativeArray        relevantCollection;
var private AssociativeArray.Index  currentIndex;

protected function Finalizer()
{
    relevantCollection = none;
}

public function bool Initialize(Collection relevantArray)
{
    local AssociativeArray.Index emptyIndex;
    currentIndex = emptyIndex;
    relevantCollection = AssociativeArray(relevantArray);
    if (relevantCollection == none) {
        return false;
    }
    hasNotFinished = (relevantCollection.GetLength() > 0);
    if (GetKey() == none) {
        relevantCollection.IncrementIndex(currentIndex);
    }
    return true;
}

public function Iter Next(optional bool skipNone)
{
    local int collectionLength;
    if (!skipNone)
    {
        hasNotFinished = relevantCollection.IncrementIndex(currentIndex);
        return self;
    }
    collectionLength = relevantCollection.GetLength();
    while (hasNotFinished)
    {
        hasNotFinished = relevantCollection.IncrementIndex(currentIndex);
        if (relevantCollection.GetEntryByIndex(currentIndex).value != none) {
            return self;
        }
    }
    return self;
}

public function AcediaObject Get()
{
    return relevantCollection.GetEntryByIndex(currentIndex).value;
}

public function AcediaObject GetKey()
{
    return relevantCollection.GetEntryByIndex(currentIndex).key;
}

public function bool HasFinished()
{
    return !hasNotFinished;
}

defaultproperties
{
}