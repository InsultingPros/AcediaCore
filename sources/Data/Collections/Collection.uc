/**
 *      Acedia provides a small set of collections for easier data storage.
 *      This is their base class that provides a simple interface for
 *  common methods.
 *      Copyright 2020 - 2021 Anton Tarasenko
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
 *  Method that must be overloaded for `GetItemByPointer()` to properly work.
 *
 *      This method must return an item that `key` refers to with it's
 *  textual content (not as an object itself).
 *      For example, `DynamicArray` parses it into unsigned number, while
 *  `AssociativeArray` uses it as a key directly.
 *
 *      There is no requirement that all stored values must be reachable by
 *  this method (i.e. `AssociativeArray` only lets you access values with
 *  `Text` keys).
 */
protected function AcediaObject GetByText(Text key);

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

/**
 *  Returns stored `AcediaObject` from the caller storage
 *  (or from it's sub-storages) via given `Text` path.
 *
 *  Path is treated like a [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  If given path does not start with "/" character (like it is expected from
 *  a json pointer) - it will be added automatically.
 *  This means that "foo/bar" is treated like "/foo/bar" and
 *  "path" like "/path". However, empty `Text` is treated like itself (""),
 *  since it constitutes a valid JSON pointer (it will point at a caller
 *  collection itself).
 *
 *      Acedia provides two collections:
 *      1. `DynamicArray` is treated as a JSON array in the context of
 *          JSON pointers and passed variable names are treated as a `Text`
 *          representation of it's integer indices;
 *      2. `AssociativeArray` is treated as a JSON object in the context of
 *          JSON pointers and passed variable names are treated as it's
 *          `Text` keys (to refer to an element with an empty key, use "/",
 *          since "" is treated as a JSON pointer and refers to
 *          the array itself).
 *      It is also possible to define your own collection type that will also be
 *  integrated with this method by making it a sub-class of `Collection` and
 *  appropriately defining `GetByText()` protected method.
 *
 *  Making only getter available (without setters or `Take...()` methods that
 *  also remove returned element) is a deliberate choice made to reduce amount
 *  of possible errors when working with collections.
 *
 *      There is no requirement that all stored values must be reachable by
 *  this method (i.e. `AssociativeArray` only lets you access values with
 *  `Text` keys).
 *
 *  @param  jsonPointerAsText   Path, given by a JSON pointer.
 *  @return An item `jsonPointerAsText` is referring to (according to the above
 *      stated rules). `none` if such item does not exist.
 */
public final function AcediaObject GetItemByPointer(Text jsonPointerAsText)
{
    local int           segmentIndex;
    local Text          nextSegment;
    local AcediaObject  result;
    local JSONPointer   pointer;
    local Collection    nextCollection;
    if (jsonPointerAsText == none)          return none;
    if (jsonPointerAsText.IsEmpty())        return self;
    pointer = _.json.Pointer(jsonPointerAsText);
    if (jsonPointerAsText.GetLength() < 1)  return self;

    nextCollection = self;
    while (segmentIndex < pointer.GetLength() - 1)
    {
        nextSegment = pointer.GetComponent(segmentIndex);
        nextCollection = Collection(nextCollection.GetByText(nextSegment));
        _.memory.Free(nextSegment);
        if (nextCollection == none) {
            break;
        }
        segmentIndex += 1;
    }
    if (nextCollection != none)
    {
        nextSegment = pointer.GetComponent(segmentIndex);
        result = nextCollection.GetByText(nextSegment);
        _.memory.Free(nextSegment);
    }
    _.memory.Free(pointer);
    return result;
}

/**
 *  Returns a `bool` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemByPointer()` for more information.
 *
 *  Referred value must be stored as `BoolBox` or `BoolRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the `bool` value.
 *  @param  defaultValue        Value to return in case `jsonPointerAsText`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return `bool` value, stored at `jsonPointerAsText` or `defaultValue` if it
 *      is missing or has a different type.
 */
public final function bool GetBoolByPointer(
    Text            jsonPointerAsText,
    optional bool   defaultValue)
{
    local AcediaObject  result;
    local BoolBox       asBox;
    local BoolRef       asRef;
    result = GetItemByPointer(jsonPointerAsText);
    if (result == none) {
        return defaultValue;
    }
    asBox = BoolBox(result);
    if (asBox != none) {
        return asBox.Get();
    }
    asRef = BoolRef(result);
    if (asRef != none) {
        return asRef.Get();
    }
    return defaultValue;
}

/**
 *  Returns a `byte` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemByPointer()` for more information.
 *
 *  Referred value must be stored as `ByteBox` or `ByteRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the `byte` value.
 *  @param  defaultValue        Value to return in case `jsonPointerAsText`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return `byte` value, stored at `jsonPointerAsText` or `defaultValue` if it
 *      is missing or has a different type.
 */
public final function byte GetByteByPointer(
    Text            jsonPointerAsText,
    optional byte   defaultValue)
{
    local AcediaObject  result;
    local ByteBox       asBox;
    local ByteRef       asRef;
    result = GetItemByPointer(jsonPointerAsText);
    if (result == none) {
        return defaultValue;
    }
    asBox = ByteBox(result);
    if (asBox != none) {
        return asBox.Get();
    }
    asRef = ByteRef(result);
    if (asRef != none) {
        return asRef.Get();
    }
    return defaultValue;
}

/**
 *  Returns a `int` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemByPointer()` for more information.
 *
 *  Referred value must be stored as `IntBox` or `IntRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the `int` value.
 *  @param  defaultValue        Value to return in case `jsonPointerAsText`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return `int` value, stored at `jsonPointerAsText` or `defaultValue` if it
 *      is missing or has a different type.
 */
public final function int GetIntByPointer(
    Text            jsonPointerAsText,
    optional int    defaultValue)
{
    local AcediaObject  result;
    local IntBox        asBox;
    local IntRef        asRef;
    result = GetItemByPointer(jsonPointerAsText);
    if (result == none) {
        return defaultValue;
    }
    asBox = IntBox(result);
    if (asBox != none) {
        return asBox.Get();
    }
    asRef = IntRef(result);
    if (asRef != none) {
        return asRef.Get();
    }
    return defaultValue;
}

/**
 *  Returns a `float` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemByPointer()` for more information.
 *
 *  Referred value must be stored as `FloatBox` or `FloatRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the `float` value.
 *  @param  defaultValue        Value to return in case `jsonPointerAsText`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return `float` value, stored at `jsonPointerAsText` or `defaultValue` if it
 *      is missing or has a different type.
 */
public final function float GetFloatByPointer(
    Text            jsonPointerAsText,
    optional float  defaultValue)
{
    local AcediaObject  result;
    local FloatBox      asBox;
    local FloatRef      asRef;
    result = GetItemByPointer(jsonPointerAsText);
    if (result == none) {
        return defaultValue;
    }
    asBox = FloatBox(result);
    if (asBox != none) {
        return asBox.Get();
    }
    asRef = FloatRef(result);
    if (asRef != none) {
        return asRef.Get();
    }
    return defaultValue;
}

/**
 *  Returns a `Text` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemByPointer()` for more information.
 *
 *  Referred value must be stored as `Text` (or one of it's sub-classes,
 *  such as `MutableText`) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the `Text` value.
 *  @return `Text` value, stored at `jsonPointerAsText` or `none` if it
 *      is missing or has a different type.
 */
public final function Text GetTextByPointer(Text jsonPointerAsText)
{
    return Text(GetItemByPointer(jsonPointerAsText));
}

/**
 *  Returns an `AssociativeArray` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemByPointer()` for more information.
 *
 *  Referred value must be stored as `AssociativeArray`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the
 *      `AssociativeArray` value.
 *  @return `AssociativeArray` value, stored at `jsonPointerAsText` or
 *      `none` if it is missing or has a different type.
 */
public final function AssociativeArray GetAssociativeArrayByPointer(
    Text jsonPointerAsText)
{
    return AssociativeArray(GetItemByPointer(jsonPointerAsText));
}

/**
 *  Returns an `DynamicArray` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemByPointer()` for more information.
 *
 *  Referred value must be stored as `DynamicArray`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the
 *      `DynamicArray` value.
 *  @return `DynamicArray` value, stored at `jsonPointerAsText` or
 *      `none` if it is missing or has a different type.
 */
public final function DynamicArray GetDynamicArrayByPointer(
    Text jsonPointerAsText)
{
    return DynamicArray(GetItemByPointer(jsonPointerAsText));
}

defaultproperties
{
}