/**
 *  Convenience API that provides methods for quickly creating collections.
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
class CollectionsAPI extends AcediaObject;

/**
 *  Creates a new `ArrayList`, optionally filling it with objects from
 *  a given native array.
 *
 *  @param  objectArray Objects to place inside created `ArrayList`;
 *      if empty (by default) - new, empty `ArrayList` will be returned.
 *      Objects will be added in the same order as in `objectArray`.
 *  @param   managed    Flag that indicates whether objects from
 *      `objectArray` argument should be added as managed.
 *      By default `false` - they would not be managed.
 *  @return New `ArrayList`, optionally filled with contents of
 *      `objectArray`. Guaranteed to be not `none` and to not contain any items
 *      outside of `objectArray`.
 */
public final function ArrayList NewArrayList(array<AcediaObject> objectArray)
{
    local int       i;
    local ArrayList result;
    result = ArrayList(_.memory.Allocate(class'ArrayList'));
    for (i = 0; i < objectArray.length; i += 1) {
        result.AddItem(objectArray[i]);
    }
    return result;
}

/**
 *  Creates a new empty `ArrayList`.
 *
 *  @return New empty instance of `ArrayList`.
 */
public final function ArrayList EmptyArrayList()
{
    return ArrayList(_.memory.Allocate(class'ArrayList'));
}

/**
 *  Creates a new `HashTable`, optionally filling it with entries
 *  (key/value pairs) from a given native array.
 *
 *  @param  entriesArray    Entries (key/value pairs) to place inside created
 *      `HashTable`; if empty (by default) - new,
 *      empty `HashTable` will be returned.
 *  @param   managed        Flag that indicates whether values from
 *      `entriesArray` argument should be added as managed.
 *      By default `false` - they would not be managed.
 *  @return New `HashTable`, optionally filled with contents of
 *      `entriesArray`. Guaranteed to be not `none` and to not contain any items
 *      outside of `entriesArray`.
 */
public final function HashTable NewHashTable(
    array<HashTable.Entry> entriesArray)
{
    local int       i;
    local HashTable result;

    result = HashTable(_.memory.Allocate(class'HashTable'));
    for (i = 0; i < entriesArray.length; i += 1) {
        result.SetItem(entriesArray[i].key, entriesArray[i].value);
    }
    return result;
}

/**
 *  Creates a new empty `HashTable`.
 *
 *  @return New empty instance of `HashTable`.
 */
public final function HashTable EmptyHashTable()
{
    return HashTable(_.memory.Allocate(class'HashTable'));
}

defaultproperties
{
}