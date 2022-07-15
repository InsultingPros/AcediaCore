/**
 *  Iterator for iterating over `HashTable`'s items.
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
class HashTableIterator extends CollectionIterator
    dependson(HashTable);

var private bool            hasNotFinished;
var private HashTable       relevantCollection;
var private HashTable.Index currentIndex;

var private bool skipNoneReferences;

protected function Finalizer()
{
    relevantCollection = none;
    skipNoneReferences = false;
}

public function bool Initialize(Collection relevantArray)
{
    local AcediaObject      currentKey;
    local HashTable.Index   emptyIndex;

    currentIndex = emptyIndex;
    relevantCollection = HashTable(relevantArray);
    if (relevantCollection == none) {
        return false;
    }
    hasNotFinished = (relevantCollection.GetLength() > 0);
    currentKey = GetKey();
    if (currentKey == none) {
        relevantCollection.IncrementIndex(currentIndex);
    }
    _.memory.Free(currentKey);
    return true;
}

public function Iter LeaveOnlyNotNone()
{
    skipNoneReferences = true;
    return self;
}

public function Iter Next()
{
    local int collectionLength;

    if (!skipNoneReferences)
    {
        hasNotFinished = relevantCollection.IncrementIndex(currentIndex);
        return self;
    }
    collectionLength = relevantCollection.GetLength();
    while (hasNotFinished)
    {
        hasNotFinished = relevantCollection.IncrementIndex(currentIndex);
        if (relevantCollection.IsSomethingByIndex(currentIndex)) {
            return self;
        }
    }
    return self;
}

public function AcediaObject Get()
{
    return relevantCollection.GetItemByIndex(currentIndex);
}

public function AcediaObject GetKey()
{
    return relevantCollection.GetKeyByIndex(currentIndex);
}

public function bool HasFinished()
{
    return !hasNotFinished;
}

defaultproperties
{
}