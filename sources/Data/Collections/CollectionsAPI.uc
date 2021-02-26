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
 *  Creates a new `DynamicArray`, optionally filling it with objects from
 *  a given native array.
 *
 *  @param  objectArray Objects to place inside created `DynamicArray`;
 *      if empty (by default) - new, empty `DynamicArray` will be returned.
 *      Objects will be added in the same order as in `objectArray`.
 *  @param   managed    Flag that indicates whether objects from
 *      `objectArray` argument should be added as managed.
 *      By default `false` - they would not be managed.
 *  @return New `DynamicArray`, optionally filled with contents of
 *      `objectArray`. Guaranteed to be not `none` and to not contain any items
 *      outside of `objectArray`.
 */
public final function DynamicArray NewDynamicArray(
    array<AcediaObject> objectArray,
    optional bool       managed)
{
    local int           i;
    local DynamicArray  result;
    result = DynamicArray(_.memory.Allocate(class'DynamicArray'));
    for (i = 0; i < objectArray.length; i += 1) {
        result.AddItem(objectArray[i], managed);
    }
    return result;
}

/**
 *  Creates a new empty `DynamicArray`.
 *
 *  @return New empty instance of `DynamicArray`.
 */
public final function DynamicArray EmptyDynamicArray()
{
    return DynamicArray(_.memory.Allocate(class'DynamicArray'));
}

/**
 *  Creates a new `AssociativeArray`, optionally filling it with entries
 *  (key/value pairs) from a given native array.
 *
 *  @param  entriesArray    Entries (key/value pairs) to place inside created
 *      `AssociativeArray`; if empty (by default) - new,
 *      empty `AssociativeArray` will be returned.
 *  @param   managed        Flag that indicates whether values from
 *      `entriesArray` argument should be added as managed.
 *      By default `false` - they would not be managed.
 *  @return New `AssociativeArray`, optionally filled with contents of
 *      `entriesArray`. Guaranteed to be not `none` and to not contain any items
 *      outside of `entriesArray`.
 */
public final function AssociativeArray NewAssociativeArray(
    array<AssociativeArray.Entry>   entriesArray,
    optional bool                   managed)
{
    local int               i;
    local AssociativeArray  result;
    result = AssociativeArray(_.memory.Allocate(class'AssociativeArray'));
    for (i = 0; i < entriesArray.length; i += 1) {
        result.SetItem(entriesArray[i].key, entriesArray[i].value, managed);
    }
    return result;
}

/**
 *  Creates a new empty `AssociativeArray`.
 *
 *  @return New empty instance of `AssociativeArray`.
 */
public final function AssociativeArray EmptyAssociativeArray()
{
    return AssociativeArray(_.memory.Allocate(class'AssociativeArray'));
}

defaultproperties
{
}