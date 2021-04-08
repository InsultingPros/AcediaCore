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

//      A private struct for `Collection` that disassembles a
//  [JSON pointer](https://tools.ietf.org/html/rfc6901) into the path parts,
//  separated by "/".
//      It is used to simplify the code working with them.
struct JSONPointer
{
    //  Records whether JSON pointer had it's escape sequences ("~0" and "~1");
    //  This is used to determine if we need to waste our time replacing them.
    var private bool                hasEscapedSequences;
    //  Parts of the path that were separated by "/" character.
    var private array<MutableText>  keys;
    //  Points at a part in `keys` to be used next.
    var private int                 nextIndex;
};

var class<Iter> iteratorClass;

var protected const int TSLASH, TJSON_ESCAPE, TJSON_ESCAPED_SLASH;
var protected const int TJSON_ESCAPED_ESCAPE;

/**
 *  Method that must be overloaded for `GetItemByPointer()` to properly work.
 *
 *      This method must return an item that `key` refers to with it's
 *  textual content (not as an object itself).
 *      For example, `DynamicArray` parses it into unsigned number, while
 *  `AssociativeArray` converts it into an immutable `Text` key, whose hash code
 *  depends on the contents.
 *
 *      There is no requirement that all stored values must be reachable by
 *  this method (i.e. `AssociativeArray` only lets you access values with
 *  `Text` keys).
 */
protected function AcediaObject GetByText(MutableText key);

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

//      Created `JSONPointer` structure (inside `ptr` out argument), based on
//  it's textual representation `pointerAsText`. Returns whether it's succeeded.
//      Deviates from JSON pointer specification in also allowing non-empty
//  arguments not starting with "/" by treating them as a whole variable name.
private final function bool MakePointer(Text pointerAsText, out JSONPointer ptr)
{
    if (pointerAsText == none) {
        return false;
    }
    FreePointer(ptr);   //  Clean up, in case we were given used pointer
    ptr.hasEscapedSequences = (pointerAsText.IndexOf(T(TJSON_ESCAPE)) >= 0);
    if (!pointerAsText.StartsWith(T(TSLASH)))
    {
        ptr.nextIndex = 0;
        ptr.keys[0] = pointerAsText.MutableCopy();
        return true;
    }

    ptr.keys = pointerAsText.SplitByCharacter(T(TSLASH).GetCharacter(0));
    //  First elements of the array will be empty, so throw it away
    _.memory.Free(ptr.keys[0]);
    ptr.nextIndex = 1;
    return true;
}

private final function bool IsFinalPointerKey(JSONPointer ptr)
{
    return ((ptr.nextIndex + 1) == ptr.keys.length);
}

private final function MutableText PopJSONKey(out JSONPointer ptr)
{
    local MutableText result;
    if (ptr.nextIndex >= ptr.keys.length) {
        return none;
    }
    ptr.nextIndex += 1;
    result = ptr.keys[ptr.nextIndex - 1];
    if (ptr.hasEscapedSequences)
    {
        //  Order is specific, necessity of which is explained in
        //  JSON Pointer's documentation:
        //  https://tools.ietf.org/html/rfc6901
        result.Replace(T(TJSON_ESCAPED_SLASH), T(TSLASH));
        result.Replace(T(TJSON_ESCAPED_ESCAPE), T(TJSON_ESCAPE));
    }
    return result;
}

//  Frees all memory used up by the `JSONPointer`
private final function FreePointer(out JSONPointer ptr)
{
    _.memory.FreeMany(ptr.keys);
}

/**
 *  Returns stored `AcediaObject` from the caller storage
 *  (or from it's sub-storages) via given `Text` path.
 *
 *  Path is used in one of the two ways:
 *      1. If path is an empty `Text` or if it starts with "/" character,
 *          it will be interpreted as
 *          a [JSON pointer](https://tools.ietf.org/html/rfc6901);
 *      2. Otherwise it will be used as an argument's name.
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
 *  @param  jsonPointerAsText   Treated as a JSON pointer if it starts with "/"
 *      character or is an empty `Text`, otherwise treated as an item's
 *      name / identificator inside the caller collection.
 *  @return An item `jsonPointerAsText` is referring to (according to the above
 *      stated rules). `none` if such item does not exist.
 */
public final function AcediaObject GetItemByPointer(Text jsonPointerAsText)
{
    local AcediaObject  result;
    local JSONPointer   ptr;
    local Collection    nextCollection;
    if (jsonPointerAsText == none)      return none;
    if (jsonPointerAsText.IsEmpty())    return self;

    if (!MakePointer(jsonPointerAsText, ptr)) {
        return none;
    }
    nextCollection = self;
    while (!IsFinalPointerKey(ptr))
    {
        nextCollection = Collection(nextCollection.GetByText(PopJSONKey(ptr)));
        if (nextCollection == none)
        {
            FreePointer(ptr);
            return none;
        }
    }
    result = nextCollection.GetByText(PopJSONKey(ptr));
    FreePointer(ptr);
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
    TSLASH                  = 0
    stringConstants(0)      = "/"
    TJSON_ESCAPE            = 1
    stringConstants(1)      = "~"
    TJSON_ESCAPED_SLASH     = 2
    stringConstants(2)      = "~1"
    TJSON_ESCAPED_ESCAPE    = 3
    stringConstants(3)      = "~0"
}