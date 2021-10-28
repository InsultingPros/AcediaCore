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

var protected class<Iter> iteratorClass;

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
 *  (or from it's sub-storages) via given `JSONPointer` path.
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
 *      There is no requirement that all stored values must be reachable by
 *  this method (i.e. `AssociativeArray` only lets you access values with
 *  `Text` keys).
 *
 *  @param  jsonPointer Path, given by a JSON pointer.
 *  @return An item `jsonPointerAsText` is referring to (according to the above
 *      stated rules). `none` if such item does not exist.
 */
public final function AcediaObject GetItemByJSON(JSONPointer jsonPointer)
{
    local int           segmentIndex;
    local Text          nextSegment;
    local AcediaObject  result;
    local Collection    nextCollection;
    if (jsonPointer == none)            return none;
    if (jsonPointer.GetLength() < 1)    return self;

    nextCollection = self;
    while (segmentIndex < jsonPointer.GetLength() - 1)
    {
        nextSegment = jsonPointer.GetComponent(segmentIndex);
        nextCollection = Collection(nextCollection.GetByText(nextSegment));
        _.memory.Free(nextSegment);
        if (nextCollection == none) {
            break;
        }
        segmentIndex += 1;
    }
    if (nextCollection != none)
    {
        nextSegment = jsonPointer.GetComponent(segmentIndex);
        result = nextCollection.GetByText(nextSegment);
        _.memory.Free(nextSegment);
    }
    _.memory.Free(jsonPointer);
    return result;
}

/**
 *  Returns stored `AcediaObject` from the caller storage
 *  (or from it's sub-storages) via given `Text` path.
 *
 *      Path is treated like a
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901)
 *  with an additional fix applied:
 *      If given path does not start with "/" character (like it is expected
 *  from a json pointer) - it will be added automatically.
 *      This means that "foo/bar" is treated like "/foo/bar" and
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
 *      There is no requirement that all stored values must be reachable by
 *  this method (i.e. `AssociativeArray` only lets you access values with
 *  `Text` keys).
 *
 *  @param  jsonPointer Path, given by a JSON pointer.
 *  @return An item `jsonPointerAsText` is referring to (according to the above
 *      stated rules). `none` if such item does not exist.
 */
public final function AcediaObject GetItemBy(Text jsonPointerAsText)
{
    local AcediaObject  result;
    local JSONPointer   jsonPointer;
    if (jsonPointerAsText == none)      return none;
    if (jsonPointerAsText.IsEmpty())    return self;

    jsonPointer = _.json.Pointer(jsonPointerAsText);
    result = GetItemByJSON(jsonPointer);
    _.memory.Free(jsonPointer);
    return result;
}

/**
 *  Returns a `bool` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemBy()` for more information.
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
public final function bool GetBoolBy(
    Text            jsonPointerAsText,
    optional bool   defaultValue)
{
    local AcediaObject  result;
    local BoolBox       asBox;
    local BoolRef       asRef;
    result = GetItemBy(jsonPointerAsText);
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
 *  See `GetItemBy()` for more information.
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
public final function byte GetByteBy(
    Text            jsonPointerAsText,
    optional byte   defaultValue)
{
    local AcediaObject  result;
    local ByteBox       asBox;
    local ByteRef       asRef;
    result = GetItemBy(jsonPointerAsText);
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
 *  See `GetItemBy()` for more information.
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
public final function int GetIntBy(
    Text            jsonPointerAsText,
    optional int    defaultValue)
{
    local AcediaObject  result;
    local IntBox        asBox;
    local IntRef        asRef;
    result = GetItemBy(jsonPointerAsText);
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
 *  See `GetItemBy()` for more information.
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
public final function float GetFloatBy(
    Text            jsonPointerAsText,
    optional float  defaultValue)
{
    local AcediaObject  result;
    local FloatBox      asBox;
    local FloatRef      asRef;
    result = GetItemBy(jsonPointerAsText);
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
 *  See `GetItemBy()` for more information.
 *
 *  Referred value must be stored as `Text` (or one of it's sub-classes,
 *  such as `MutableText`) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the `Text` value.
 *  @return `Text` value, stored at `jsonPointerAsText` or `none` if it
 *      is missing or has a different type.
 */
public final function Text GetTextBy(Text jsonPointerAsText)
{
    return Text(GetItemBy(jsonPointerAsText));
}

/**
 *  Returns an `AssociativeArray` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemBy()` for more information.
 *
 *  Referred value must be stored as `AssociativeArray`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the
 *      `AssociativeArray` value.
 *  @return `AssociativeArray` value, stored at `jsonPointerAsText` or
 *      `none` if it is missing or has a different type.
 */
public final function AssociativeArray GetAssociativeArrayBy(
    Text jsonPointerAsText)
{
    return AssociativeArray(GetItemBy(jsonPointerAsText));
}

/**
 *  Returns an `DynamicArray` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemBy()` for more information.
 *
 *  Referred value must be stored as `DynamicArray`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the
 *      `DynamicArray` value.
 *  @return `DynamicArray` value, stored at `jsonPointerAsText` or
 *      `none` if it is missing or has a different type.
 */
public final function DynamicArray GetDynamicArrayBy(Text jsonPointerAsText)
{
    return DynamicArray(GetItemBy(jsonPointerAsText));
}

/**
 *  Returns a `bool` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by JSON pointer.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `BoolBox` or `BoolRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  jsonPointer     JSON path to the `bool` value.
 *  @param  defaultValue    Value to return in case `jsonPointer`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return `bool` value, stored at `jsonPointerAsText` or `defaultValue` if it
 *      is missing or has a different type.
 */
public final function bool GetBoolByJSON(
    JSONPointer     jsonPointer,
    optional bool   defaultValue)
{
    local AcediaObject  result;
    local BoolBox       asBox;
    local BoolRef       asRef;
    result = GetItemByJSON(jsonPointer);
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
 *  one of it's sub-collections) pointed by JSON pointer.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `ByteBox` or `ByteRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  jsonPointer     JSON path to the `byte` value.
 *  @param  defaultValue    Value to return in case `jsonPointer`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return `byte` value, stored at `jsonPointerAsText` or `defaultValue` if it
 *      is missing or has a different type.
 */
public final function byte GetByteByJSON(
    JSONPointer     jsonPointer,
    optional byte   defaultValue)
{
    local AcediaObject  result;
    local ByteBox       asBox;
    local ByteRef       asRef;
    result = GetItemByJSON(jsonPointer);
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
 *  one of it's sub-collections) pointed by JSON pointer.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `IntBox` or `IntRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  jsonPointer     JSON path to the `int` value.
 *  @param  defaultValue    Value to return in case `jsonPointer`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return `int` value, stored at `jsonPointerAsText` or `defaultValue` if it
 *      is missing or has a different type.
 */
public final function int GetIntByJSON(
    JSONPointer     jsonPointer,
    optional int    defaultValue)
{
    local AcediaObject  result;
    local IntBox        asBox;
    local IntRef        asRef;
    result = GetItemByJSON(jsonPointer);
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
 *  one of it's sub-collections) pointed by JSON pointer.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `FloatBox` or `FloatRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  jsonPointer     JSON path to the `float` value.
 *  @param  defaultValue    Value to return in case `jsonPointer`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return `float` value, stored at `jsonPointerAsText` or `defaultValue` if it
 *      is missing or has a different type.
 */
public final function float GetFloatByJSON(
    JSONPointer     jsonPointer,
    optional float  defaultValue)
{
    local AcediaObject  result;
    local FloatBox      asBox;
    local FloatRef      asRef;
    result = GetItemByJSON(jsonPointer);
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
 *  one of it's sub-collections) pointed by JSON pointer.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `Text` (or one of it's sub-classes,
 *  such as `MutableText`) for this method to work.
 *
 *  @param  jsonPointer JSON path to the `Text` value.
 *  @return `Text` value, stored at `jsonPointerAsText` or `none` if it
 *      is missing or has a different type.
 */
public final function Text GetTextByJSON(JSONPointer jsonPointer)
{
    return Text(GetItemByJSON(jsonPointer));
}

/**
 *  Returns an `AssociativeArray` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by JSON pointer.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `AssociativeArray`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  jsonPointer JSON path to the `AssociativeArray` value.
 *  @return `AssociativeArray` value, stored at `jsonPointerAsText` or
 *      `none` if it is missing or has a different type.
 */
public final function AssociativeArray GetAssociativeArrayByJSON(
    JSONPointer jsonPointer)
{
    return AssociativeArray(GetItemByJSON(jsonPointer));
}

/**
 *  Returns an `DynamicArray` value stored (in the caller `Collection` or
 *  one of it's sub-collections) pointed by JSON pointer.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `DynamicArray`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  jsonPointer JSON path to the `DynamicArray` value.
 *  @return `DynamicArray` value, stored at `jsonPointerAsText` or
 *      `none` if it is missing or has a different type.
 */
public final function DynamicArray GetDynamicArrayByJSON(
    JSONPointer jsonPointer)
{
    return DynamicArray(GetItemByJSON(jsonPointer));
}

defaultproperties
{
}