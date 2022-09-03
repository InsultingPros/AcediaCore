/**
 *      Acedia provides a small set of collections for easier data storage.
 *      This is their base class that provides a simple interface for
 *  common methods.
 *      Copyright 2020 - 2022 Anton Tarasenko
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

var protected class<CollectionIterator> iteratorClass;

/**
 *  Method that must be overloaded for `GetItemByPointer()` to properly work.
 *
 *      This method must return an item that `key` refers to with it's
 *  textual content (not as an object itself).
 *      For example, `ArrayList` parses it into unsigned number, while
 *  `HashTable` uses it as a key directly.
 *
 *      There is no requirement that all stored values must be reachable by
 *  this method (i.e. `HashTable` only lets you access values with
 *  `Text` keys).
 */
protected function AcediaObject GetByText(BaseText key);

/**
 *  Creates an `Iterator` instance to iterate over stored items.
 *
 *  Returned `Iterator` must be manually deallocated after it was used.
 *
 *  @return New initialized `Iterator` that will iterate over all items in
 *      a given collection. Guaranteed to be not `none`.
 */
public final function CollectionIterator Iterate()
{
    local CollectionIterator newIterator;

    newIterator = CollectionIterator(_.memory.Allocate(iteratorClass));
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
 *  Completely clears caller `Collections` of all stored entries,
 *  deallocating any stored managed values.
 */
public function Empty() {}

/**
 *  Returns stored `AcediaObject` from the caller storage
 *  (or from it's sub-storages) via given `JSONPointer` path.
 *
 *      Acedia provides two collections:
 *      1. `ArrayList` is treated as a JSON array in the context of
 *          JSON pointers and passed variable names are treated as a `Text`
 *          representation of it's integer indices;
 *      2. `HashTable` is treated as a JSON object in the context of
 *          JSON pointers and passed variable names are treated as it's
 *          `Text` keys (to refer to an element with an empty key, use "/",
 *          since "" is treated as a JSON pointer and refers to
 *          the array itself).
 *      It is also possible to define your own collection type that will also be
 *  integrated with this method by making it a sub-class of `Collection` and
 *  appropriately defining `GetByText()` protected method.
 *
 *      There is no requirement that all stored values must be reachable by
 *  this method (i.e. `HashTable` only lets you access values with `Text` keys).
 *
 *  @param  jsonPointer Path, given by a JSON pointer.
 *  @return An item `jsonPointerAsText` is referring to (according to the above
 *      stated rules). `none` if such item does not exist.
 */
public final function AcediaObject GetItemByJSON(JSONPointer jsonPointer)
{
    local int           segmentIndex;
    local Text          nextSegment;
    local AcediaObject  result, nextObject;
    local Collection    prevCollection, nextCollection;

    if (jsonPointer == none) {
        return none;
    }
    if (jsonPointer.GetLength() < 1)
    {
        NewRef();
        return self;
    }
    nextCollection = self;
    nextCollection.NewRef();
    while (segmentIndex < jsonPointer.GetLength() - 1)
    {
        nextSegment = jsonPointer.GetComponent(segmentIndex);
        prevCollection = nextCollection;
        nextObject = nextCollection.GetByText(nextSegment);
        nextCollection = Collection(nextObject);
        _.memory.Free(prevCollection);
        if (nextCollection == none) {
            _.memory.Free(nextObject);
        }
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
 *      1. `ArrayList` is treated as a JSON array in the context of
 *          JSON pointers and passed variable names are treated as a `Text`
 *          representation of it's integer indices;
 *      2. `HashTable` is treated as a JSON object in the context of
 *          JSON pointers and passed variable names are treated as it's
 *          `Text` keys (to refer to an element with an empty key, use "/",
 *          since "" is treated as a JSON pointer and refers to
 *          the array itself).
 *      It is also possible to define your own collection type that will also be
 *  integrated with this method by making it a sub-class of `Collection` and
 *  appropriately defining `GetByText()` protected method.
 *
 *      There is no requirement that all stored values must be reachable by
 *  this method (i.e. `HashTable` only lets you access values with
 *  `Text` keys).
 *
 *  @param  jsonPointer Path, given by a JSON pointer.
 *  @return An item `jsonPointerAsText` is referring to (according to the above
 *      stated rules). `none` if such item does not exist.
 */
public final function AcediaObject GetItemBy(BaseText jsonPointerAsText)
{
    local AcediaObject  result;
    local JSONPointer   jsonPointer;
    if (jsonPointerAsText == none) {
        return none;
    }
    if (jsonPointerAsText.IsEmpty())
    {
        NewRef();
        return self;
    }
    jsonPointer = _.json.Pointer(jsonPointerAsText);
    result = GetItemByJSON(jsonPointer);
    _.memory.Free(jsonPointer);
    return result;
}

/**
 *  Returns a `bool` value (stored in the caller `Collection` or
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
    BaseText        jsonPointerAsText,
    optional bool   defaultValue)
{
    local bool          result;
    local AcediaObject  resultObject;
    local BoolBox       asBox;
    local BoolRef       asRef;

    resultObject = GetItemBy(jsonPointerAsText);
    if (resultObject == none) {
        return defaultValue;
    }
    result = defaultValue;
    asBox = BoolBox(resultObject);
    if (asBox != none) {
        result = asBox.Get();
    }
    asRef = BoolRef(resultObject);
    if (asRef != none) {
        result = asRef.Get();
    }
    _.memory.Free(resultObject);
    return result;
}

/**
 *  Returns a `byte` value (stored in the caller `Collection` or
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
    BaseText        jsonPointerAsText,
    optional byte   defaultValue)
{
    local byte          result;
    local AcediaObject  resultObject;
    local ByteBox       asBox;
    local ByteRef       asRef;

    resultObject = GetItemBy(jsonPointerAsText);
    if (resultObject == none) {
        return defaultValue;
    }
    result = defaultValue;
    asBox = ByteBox(resultObject);
    if (asBox != none) {
        result = asBox.Get();
    }
    asRef = ByteRef(resultObject);
    if (asRef != none) {
        result = asRef.Get();
    }
    _.memory.Free(resultObject);
    return result;
}

/**
 *  Returns a `int` or `float` value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901) as `int`.
 *  See `GetItemBy()` for more information.
 *
 *  Referred value must be stored as `IntBox`, `IntRef`, `FloatBox` or
 *  `FloatRef` (or one of their sub-classes) for this method to work.
 *
 *  Allowing for implicit conversion between non-`byte` numeric types simplifies
 *  handling parsed input as there is no need to know whether parsed value is
 *  expected to be integer or floating point.
 *
 *  @param  jsonPointerAsText   Description of a path to the `int` value.
 *  @param  defaultValue        Value to return in case `jsonPointerAsText`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return `int` value, stored at `jsonPointerAsText` or `defaultValue` if it
 *      is missing or has a different type.
 */
public final function int GetIntBy(
    BaseText        jsonPointerAsText,
    optional int    defaultValue)
{
    local int           result;
    local AcediaObject  resultObject;
    local IntBox        asBox;
    local IntRef        asRef;
    local FloatBox      asFloatBox;
    local FloatRef      asFloatRef;

    resultObject = GetItemBy(jsonPointerAsText);
    if (resultObject == none) {
        return defaultValue;
    }
    result = defaultValue;
    asBox = IntBox(resultObject);
    if (asBox != none) {
        result = asBox.Get();
    }
    asRef = IntRef(resultObject);
    if (asRef != none) {
        result = asRef.Get();
    }
    asFloatBox = FloatBox(resultObject);
    if (asFloatBox != none) {
        result = int(asFloatBox.Get());
    }
    asFloatRef = FloatRef(resultObject);
    if (asFloatRef != none) {
        result = int(asFloatRef.Get());
    }
    _.memory.Free(resultObject);
    return result;
}

/**
 *  Returns a `float` or `int` value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901) as `float`.
 *  See `GetItemBy()` for more information.
 *
 *  Referred value must be stored as `IntBox`, `IntRef`, `FloatBox` or
 *  `FloatRef` (or one of their sub-classes) for this method to work.
 *
 *  Allowing for implicit conversion between non-`byte` numeric types simplifies
 *  handling parsed input as there is no need to know whether parsed value is
 *  expected to be integer or floating point.
 *
 *  @param  jsonPointerAsText   Description of a path to the `float` value.
 *  @param  defaultValue        Value to return in case `jsonPointerAsText`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return `float` value, stored at `jsonPointerAsText` or `defaultValue` if it
 *      is missing or has a different type.
 */
public final function float GetFloatBy(
    BaseText        jsonPointerAsText,
    optional float  defaultValue)
{
    local float         result;
    local AcediaObject  resultObject;
    local FloatBox      asBox;
    local FloatRef      asRef;
    local IntBox        asIntBox;
    local IntRef        asIntRef;

    resultObject = GetItemBy(jsonPointerAsText);
    if (resultObject == none) {
        return defaultValue;
    }
    result = defaultValue;
    asBox = FloatBox(resultObject);
    if (asBox != none) {
        result = asBox.Get();
    }
    asRef = FloatRef(resultObject);
    if (asRef != none) {
        result = asRef.Get();
    }
    asIntBox = IntBox(resultObject);
    if (asIntBox != none) {
        result = float(asIntBox.Get());
    }
    asIntRef = IntRef(resultObject);
    if (asIntRef != none) {
        result = float(asIntRef.Get());
    }
    _.memory.Free(resultObject);
    return result;
}

/**
 *  Returns a `Vector` value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemBy()` for more information.
 *
 *  Referred value must be stored as `VectorBox` or `VectorRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the `Vector` value.
 *  @param  defaultValue        Value to return in case `jsonPointerAsText`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return `Vector` value, stored at `jsonPointerAsText` or `defaultValue` if it
 *      is missing or has a different type.
 */
public final function Vector GetVectorBy(
    BaseText        jsonPointerAsText,
    optional Vector defaultValue)
{
    local Vector        result;
    local AcediaObject  resultObject;
    local VectorBox     asBox;
    local VectorRef     asRef;

    resultObject = GetItemBy(jsonPointerAsText);
    if (resultObject == none) {
        return defaultValue;
    }
    result = defaultValue;
    asBox = VectorBox(resultObject);
    if (asBox != none) {
        result = asBox.Get();
    }
    asRef = VectorRef(resultObject);
    if (asRef != none) {
        result = asRef.Get();
    }
    _.memory.Free(resultObject);
    return result;
}

/**
 *  Returns a plain string value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemBy()` for more information.
 *
 *  Referred value must be stored as `BaseText` (or one of its sub-classes) for
 *  this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the `string` value.
 *  @param  defaultValue        Value to return in case `jsonPointerAsText`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return Plain string value, stored at `jsonPointerAsText` or `defaultValue`
 *      if it is missing or has a different type.
 */
public final function string GetStringBy(
    BaseText        jsonPointerAsText,
    optional string defaultValue)
{
    local AcediaObject  result;
    local Basetext      asText;

    result = GetItemBy(jsonPointerAsText);
    if (result == none) {
        return defaultValue;
    }
    asText = BaseText(result);
    if (asText != none) {
        return _.text.IntoString(asText);
    }
    _.memory.Free(result);
    return defaultValue;
}

/**
 *  Returns a formatted string value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemBy()` for more information.
 *
 *  Referred value must be stored as `BaseText` (or one of its sub-classes) for
 *  this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the `string` value.
 *  @param  defaultValue        Value to return in case `jsonPointerAsText`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return Formatted string value, stored at `jsonPointerAsText` or
 *      `defaultValue` if it is missing or has a different type.
 */
public final function string GetFormattedStringBy(
    BaseText        jsonPointerAsText,
    optional string defaultValue)
{
    local AcediaObject  result;
    local Basetext      asText;

    result = GetItemBy(jsonPointerAsText);
    if (result == none) {
        return defaultValue;
    }
    asText = BaseText(result);
    if (asText != none) {
        return _.text.IntoFormattedString(asText);
    }
    _.memory.Free(result);
    return defaultValue;
}

/**
 *  Returns a `Text` value (stored in the caller `Collection` or
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
public final function Text GetTextBy(BaseText jsonPointerAsText)
{
    local Text          asText;
    local AcediaObject  result;

    result = GetItemBy(jsonPointerAsText);
    asText = Text(result);
    if (asText != none) {
        return asText;
    }
    _.memory.Free(result);
    return none;
}

/**
 *  Returns an `HashTable` value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemBy()` for more information.
 *
 *  Referred value must be stored as `HashTable`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the `HashTable` value.
 *  @return `HashTable` value, stored at `jsonPointerAsText` or
 *      `none` if it is missing or has a different type.
 */
public final function HashTable GetHashTableBy(
    BaseText jsonPointerAsText)
{
    local HashTable     asHashTable;
    local AcediaObject  result;

    result = GetItemBy(jsonPointerAsText);
    asHashTable = HashTable(result);
    if (asHashTable != none) {
        return asHashTable;
    }
    _.memory.Free(result);
    return none;
}

/**
 *  Returns an `ArrayList` value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by
 *  [JSON pointer](https://tools.ietf.org/html/rfc6901).
 *  See `GetItemBy()` for more information.
 *
 *  Referred value must be stored as `ArrayList`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  jsonPointerAsText   Description of a path to the `ArrayList` value.
 *  @return `ArrayList` value, stored at `jsonPointerAsText` or
 *      `none` if it is missing or has a different type.
 */
public final function ArrayList GetArrayListBy(BaseText jsonPointerAsText)
{
    local ArrayList     asArrayList;
    local AcediaObject  result;

    result = GetItemBy(jsonPointerAsText);
    asArrayList = ArrayList(result);
    if (asArrayList != none) {
        return asArrayList;
    }
    _.memory.Free(result);
    return none;
}

/**
 *  Returns a `bool` value (stored in the caller `Collection` or
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
    local bool          result;
    local AcediaObject  resultObject;
    local BoolBox       asBox;
    local BoolRef       asRef;

    resultObject = GetItemByJSON(jsonPointer);
    if (resultObject == none) {
        return defaultValue;
    }
    result = defaultValue;
    asBox = BoolBox(resultObject);
    if (asBox != none) {
        result = asBox.Get();
    }
    asRef = BoolRef(resultObject);
    if (asRef != none) {
        result = asRef.Get();
    }
    _.memory.Free(resultObject);
    return result;
}

/**
 *  Returns a `byte` value (stored in the caller `Collection` or
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
    local byte          result;
    local AcediaObject  resultObject;
    local ByteBox       asBox;
    local ByteRef       asRef;

    resultObject = GetItemByJSON(jsonPointer);
    if (resultObject == none) {
        return defaultValue;
    }
    result = defaultValue;
    asBox = ByteBox(resultObject);
    if (asBox != none) {
        result = asBox.Get();
    }
    asRef = ByteRef(resultObject);
    if (asRef != none) {
        result = asRef.Get();
    }
    _.memory.Free(resultObject);
    return result;
}

/**
 *  Returns a `int` or `float` value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by JSON pointer as `int`.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `IntBox`, `IntRef`, `FloatBox` or
 *  `FloatRef` (or one of their sub-classes) for this method to work.
 *
 *  Allowing for implicit conversion between non-`byte` numeric types simplifies
 *  handling parsed input as there is no need to know whether parsed value is
 *  expected to be integer or floating point.
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
    local int           result;
    local AcediaObject  resultObject;
    local IntBox        asBox;
    local IntRef        asRef;
    local FloatBox      asFloatBox;
    local FloatRef      asFloatRef;

    resultObject = GetItemByJSON(jsonPointer);
    if (resultObject == none) {
        return defaultValue;
    }
    result = defaultValue;
    asBox = IntBox(resultObject);
    if (asBox != none) {
        result = asBox.Get();
    }
    asRef = IntRef(resultObject);
    if (asRef != none) {
        result = asRef.Get();
    }
    asFloatBox = FloatBox(resultObject);
    if (asFloatBox != none) {
        result = int(asFloatBox.Get());
    }
    asFloatRef = FloatRef(resultObject);
    if (asFloatRef != none) {
        result = int(asFloatRef.Get());
    }
    _.memory.Free(resultObject);
    return result;
}

/**
 *  Returns a `float` or `int` value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by JSON pointer as `float`.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `IntBox`, `IntRef`, `FloatBox` or
 *  `FloatRef` (or one of their sub-classes) for this method to work.
 *
 *  Allowing for implicit conversion between non-`byte` numeric types simplifies
 *  handling parsed input as there is no need to know whether parsed value is
 *  expected to be integer or floating point.
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
    local float         result;
    local AcediaObject  resultObject;
    local FloatBox      asBox;
    local FloatRef      asRef;
    local IntBox        asIntBox;
    local IntRef        asIntRef;

    resultObject = GetItemByJSON(jsonPointer);
    if (resultObject == none) {
        return defaultValue;
    }
    result = defaultValue;
    asBox = FloatBox(resultObject);
    if (asBox != none) {
        result = asBox.Get();
    }
    asRef = FloatRef(resultObject);
    if (asRef != none) {
        result = asRef.Get();
    }
    asIntBox = IntBox(resultObject);
    if (asIntBox != none) {
        result = float(asIntBox.Get());
    }
    asIntRef = IntRef(resultObject);
    if (asIntRef != none) {
        result = float(asIntRef.Get());
    }
    _.memory.Free(resultObject);
    return result;
}

/**
 *  Returns a `Vector` value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by JSON pointer.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `VectorBox` or `VectorRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  jsonPointer     JSON path to the `Vector` value.
 *  @param  defaultValue    Value to return in case `jsonPointer`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return `Vector` value, stored at `jsonPointerAsText` or `defaultValue` if it
 *      is missing or has a different type.
 */
public final function Vector GetVectorByJSON(
    JSONPointer     jsonPointer,
    optional Vector defaultValue)
{
    local Vector        result;
    local AcediaObject  resultObject;
    local VectorBox     asBox;
    local VectorRef     asRef;

    resultObject = GetItemByJSON(jsonPointer);
    if (resultObject == none) {
        return defaultValue;
    }
    result = defaultValue;
    asBox = VectorBox(resultObject);
    if (asBox != none) {
        result = asBox.Get();
    }
    asRef = VectorRef(resultObject);
    if (asRef != none) {
        result = asRef.Get();
    }
    _.memory.Free(resultObject);
    return result;
}

/**
 *  Returns a plain string value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by JSON pointer.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `Text` or `MutableText`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  jsonPointer     JSON path to the `string` value.
 *  @param  defaultValue    Value to return in case `jsonPointer`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return Plain string value, stored at `jsonPointerAsText` or `defaultValue`
 *      if it is missing or has a different type.
 */
public final function string GetStringByJSON(
    JSONPointer     jsonPointer,
    optional string defaultValue)
{
    local AcediaObject  result;
    local BaseText      asText;

    result = GetItemByJSON(jsonPointer);
    if (result == none) {
        return defaultValue;
    }
    asText = BaseText(result);
    if (asText != none) {
        return _.text.IntoString(asText);
    }
    _.memory.Free(result);
    return defaultValue;
}

/**
 *  Returns a formatted string value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by JSON pointer.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `BaseText` (or one of its sub-classes) for
 *  this method to work.
 *
 *  @param  jsonPointer     JSON path to the `string` value.
 *  @param  defaultValue    Value to return in case `jsonPointer`
 *      does not point at any existing value or if that value does not have
 *      appropriate type.
 *  @return Formatted string value, stored at `jsonPointerAsText` or
 *      `defaultValue` if it is missing or has a different type.
 */
public final function string GetFormattedStringByJSON(
    JSONPointer     jsonPointer,
    optional string defaultValue)
{
    local AcediaObject  result;
    local BaseText      asText;

    result = GetItemByJSON(jsonPointer);
    if (result == none) {
        return defaultValue;
    }
    asText = BaseText(result);
    if (asText != none) {
        return _.text.IntoFormattedString(asText);
    }
    _.memory.Free(result);
    return defaultValue;
}

/**
 *  Returns a `Text` value (stored in the caller `Collection` or
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
    local AcediaObject  result;
    local Text          asText;

    result = GetItemByJSON(jsonPointer);
    asText = Text(result);
    if (asText != none) {
        return asText;
    }
    _.memory.Free(result);
    return none;
}

/**
 *  Returns an `HashTable` value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by JSON pointer.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `HashTable`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  jsonPointer JSON path to the `HashTable` value.
 *  @return `HashTable` value, stored at `jsonPointerAsText` or
 *      `none` if it is missing or has a different type.
 */
public final function HashTable GetHashTableByJSON(
    JSONPointer jsonPointer)
{
    local AcediaObject  result;
    local HashTable     asHashTable;

    result = GetItemByJSON(jsonPointer);
    asHashTable = HashTable(result);
    if (asHashTable != none) {
        return asHashTable;
    }
    _.memory.Free(result);
    return none;
}

/**
 *  Returns an `ArrayList` value (stored in the caller `Collection` or
 *  one of it's sub-collections) pointed by JSON pointer.
 *  See `GetItemByJSON()` for more information.
 *
 *  Referred value must be stored as `ArrayList`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  jsonPointer JSON path to the `ArrayList` value.
 *  @return `ArrayList` value, stored at `jsonPointerAsText` or
 *      `none` if it is missing or has a different type.
 */
public final function ArrayList GetArrayListByJSON(
    JSONPointer jsonPointer)
{
    local AcediaObject  result;
    local ArrayList     asArrayList;

    result = GetItemByJSON(jsonPointer);
    asArrayList = ArrayList(result);
    if (asArrayList != none) {
        return asArrayList;
    }
    _.memory.Free(result);
    return none;
}

defaultproperties
{
}