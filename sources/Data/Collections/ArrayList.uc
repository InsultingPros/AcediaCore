/**
 *      Dynamic array object for storing arbitrary types of data. Generic
 *  storage is achieved by using `AcediaObject` as the stored type. Native
 *  variable types such as `int`, `bool`, etc. can be stored by boxing them into
 *  `AcediaObject`s.
 *      Appropriate classes and APIs for their construction are provided for
 *  main primitive types and can be extended to any custom `struct`.
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
class ArrayList extends Collection;

//  Actual storage of all our data.
var private array<AcediaObject> storedObjects;

//  Free array data
protected function Finalizer()
{
    Empty();
}

//  Method, used to compare array values at different indices.
//  Does not check boundary conditions, so make sure passed indices are valid.
private function bool AreEqual(AcediaObject object1, AcediaObject object2)
{
    if (object1 == none && object2 == none) return true;
    if (object1 == none || object2 == none) return false;

    return object1.IsEqual(object2);
}

/**
 *  Returns current length of dynamic `ArrayList`.
 *
 *  @return Returns length of the caller `ArrayList`.
 *      Guaranteed to be non-negative.
 */
public final function int GetLength()
{
    return storedObjects.length;
}

/**
 *      Changes length of the caller `ArrayList`.
 *      If `ArrayList` size is increased as a result - added items will be
 *  filled with `none`s.
 *
 *  @param  newLength   New length of an `ArrayList`.
 *      If negative value is passes - method will do nothing.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList SetLength(int newLength)
{
    local int i;

    if (newLength < 0) {
        return self;
    }
    for (i = newLength; i < storedObjects.length; i += 1) {
        FreeItem(i);
    }
    storedObjects.length = newLength;
    return self;
}

/**
 *  Deallocates an item at a given index `index`.
 *  Does not check `ArrayList` bounds for `index`, so you must ensure that
 *  `index` is valid.
 *
 *  @param  index   Index of the item to deallocate.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
protected final function ArrayList FreeItem(int index)
{
    if (storedObjects[index] == none) {
        return self;
    }
    storedObjects[index].FreeSelf();
    storedObjects[index] = none;
    return self;
}

public function Empty()
{
    SetLength(0);
}

/**
 *      Adds `amountOfNewItems` empty (`none`) items at the end of
 *  the `ArrayList`.
 *      To insert items at an arbitrary array index, use `Insert()`.
 *
 *  @param  amountOfNewItems    Amount of items to add at the end.
 *      If non-positive value is passed, - method does nothing.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList Add(int amountOfNewItems)
{
    if (amountOfNewItems > 0) {
        SetLength(storedObjects.length + amountOfNewItems);
    }
    return self;
}

/**
 *      Inserts `count` empty (`none`) items into the `ArrayList`
 *  at specified position.
 *      The indices of the following items are increased by `count` in order
 *  to make room for the new items.
 *
 *  To add items at the end of an `ArrayList`, consider using `Add()`,
 *  which is equivalent to `array.Insert(array.GetLength(), ...)`.
 *
 *  @param  index   Index, where first inserted item will be located.
 *      Must belong to `[0; self.GetLength()]` inclusive interval,
 *      otherwise method does nothing.
 *  @param  count   Amount of new items to insert.
 *      Must be positive, otherwise method does nothing.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList Insert(int index, int count)
{
    local int i;
    local int swapIndex;
    local int amountToShift;

    if (count <= 0)                                 return self;
    if (index < 0 || index > storedObjects.length)  return self;

    //  Native `Insert()` for an array is bugged and cannot be trusted
    amountToShift = storedObjects.length - index;
    Add(count);
    if (amountToShift == 0) {
        return self;
    }
    for (i = 0; i < amountToShift; i += 1)
    {
        swapIndex = storedObjects.length - i - 1;
        Swap(swapIndex, swapIndex - count);
    }
    return self;
}

/**
 *  Swaps two `ArrayList` items.
 *
 *  @param  index1  Index of item to swap.
 *  @param  index2  Index of item to swap.
 */
protected final function Swap(int index1, int index2)
{
    local AcediaObject temporaryItem;

    //  Swap object
    temporaryItem = storedObjects[index1];
    storedObjects[index1] = storedObjects[index2];
    storedObjects[index2] = temporaryItem;
}

/**
 *  Removes number items from the `ArrayList`, starting at `index`.
 *  All items before position and from `index + count` on are not changed,
 *  but the item indices change, - they shift to close the gap,
 *  created by removed items.
 *
 *  @param  index   Remove items starting from this index.
 *      Must belong to `[0; self.GetLength() - 1]` inclusive interval,
 *      otherwise method does nothing.
 *  @param  count   Removes at most this much items.
 *      Must be positive, otherwise method does nothing.
 *      Specifying more items than can be removed simply removes
 *      all items, starting from `index`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList Remove(int index, int count)
{
    local int i;

    if (count <= 0)                                 return self;
    if (index < 0 || index > storedObjects.length)  return self;

    count = Min(count, storedObjects.length - index);
    for (i = 0; i < count; i += 1) {
        FreeItem(index + i);
    }
    storedObjects.Remove(index, count);
    return self;
}

/**
 *  Removes item at a given index, shifting all the items that come after
 *  one place backwards.
 *
 *  @param  index   Remove items starting from this index.
 *      Must belong to `[0; self.GetLength() - 1]` inclusive interval,
 *      otherwise method does nothing.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList RemoveIndex(int index)
{
    Remove(index, 1);
    return self;
}

/**
 *  Validates item at `index`: in case it was erroneously deallocated while
 *  being stored in caller `ArrayList` - forgets stored `AcediaObject`
 *  reference.
 *
 *  @param  index   Index of an item to validate/
 *  @return `true` if `index` is valid for `storedObjects` array.
 */
private final function bool ValidateIndex(int index)
{
    local AcediaObject item;

    if (index < 0)                      return false;
    if (index >= storedObjects.length)  return false;
    item = storedObjects[index];

    return true;
}

/**
 *  Returns item at `index` and replaces it with `none` inside `ArrayList`.
 *
 *  @param  index   Index of an item that `ArrayList` has to return.
 *  @return Either value at `index` in the caller `ArrayList` or `none` if
 *      passed `index` is invalid.
 */
public final function AcediaObject TakeItem(int index)
{
    local AcediaObject result;

    if (ValidateIndex(index))
    {
        result = storedObjects[index];
        storedObjects[index] = none;
    }
    return result;
}

/**
 *  Returns borrowed item at `index`. If index is invalid, returns `none`.
 *
 *  @param  index   Index of an item that `ArrayList` has to return.
 *  @return Either value at `index` in the caller `ArrayList` or `none` if
 *      passed `index` is invalid.
 */
private final function AcediaObject BorrowItem(int index)
{
    if (ValidateIndex(index)) {
        return storedObjects[index];
    }
}

/**
 *  Returns item at `index`. If index is invalid, returns `none`.
 *
 *  @param  index   Index of an item that `ArrayList` has to return.
 *  @return Either value at `index` in the caller `ArrayList` or `none` if
 *      passed `index` is invalid.
 */
public final function AcediaObject GetItem(int index)
{
    local AcediaObject result;

    if (ValidateIndex(index)) {
        result = storedObjects[index];
    }
    if (result != none) {
        result.NewRef();
    }
    return result;
}

/**
 *  Changes `ArrayList`'s value at `index` to `item`.
 *
 *  @param  index   Index, at which to change the value. If `ArrayList` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  item    Value to be set at a given index.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList SetItem(int index, AcediaObject item)
{
    if (index < 0) {
        return self;
    }
    if (index >= storedObjects.length) {
        SetLength(index + 1);
    }
    else if (item != storedObjects[index]) {
        FreeItem(index);
    }
    if (item != none && item.IsAllocated())
    {
        item.NewRef();
        storedObjects[index] = item;
    }
    return self;
}

/**
 *  Creates a new instance of class `valueClass` and records it's value at index
 *  `index` in the caller `ArrayList`.
 *
 *  @param  index       Index, at which to change the value. If `ArrayList`
 *      is not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  valueClass  Class of object to create. Will only be created if
 *      passed `index` is valid.
 *  @return Caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList CreateItem(
    int                 index,
    class<AcediaObject> valueClass)
{
    local AcediaObject newObject;

    if (index < 0)          return self;
    if (valueClass == none) return self;

    newObject = AcediaObject(_.memory.Allocate(valueClass));
    SetItem(index, newObject);
    _.memory.Free(newObject);
    return self;
}

/**
 *      Adds given `item` at the end of the `ArrayList`, expanding it by
 *  one item.
 *
 *  @param  item    Item to be added at the end of the `ArrayList`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList AddItem(AcediaObject item)
{
    return SetItem(storedObjects.length, item);
}

/**
 *      Inserts given `item` at index `index` of the `ArrayList`,
 *  shifting all the items starting from `index` one position to the right.
 *
 *  @param  index   Index at which to insert new item. Must belong to
 *      inclusive range `[0; self.GetLength()]`, otherwise method does nothing.
 *  @param  item    Item to insert.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList InsertItem(int index, AcediaObject item)
{
    if (index < 0)                      return self;
    if (index > storedObjects.length)   return self;

    Insert(index, 1);
    SetItem(index, item);
    return self;
}

/**
 *  Returns all occurrences of `item` in the caller `ArrayList`
 *  (optionally only first one).
 *
 *  @param  item            Item that needs to be removed from a `ArrayList`.
 *  @param  onlyFirstItem   Set to `true` to only remove first occurrence.
 *      By default `false`, which means all occurrences will be removed.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList RemoveItem(
    AcediaObject    item,
    optional bool   onlyFirstItem)
{
    local int i;

    while (i < storedObjects.length)
    {
        if (AreEqual(storedObjects[i], item))
        {
            Remove(i, 1);
            if (onlyFirstItem) {
                return self;
            }
        }
        else {
            i += 1;
        }
    }
    return self;
}

/**
 *  Finds first occurrence of `item` in caller `ArrayList` and returns
 *  it's index.
 *
 *  @param  item    Item to find in `ArrayList`.
 *  @return Index of first occurrence of `item` in caller `ArrayList`.
 *      `-1` if `item` is not found.
 */
public final function int Find(AcediaObject item)
{
    local int i;

    if (item != none && !item.IsAllocated()) {
        item = none;
    }
    for (i = 0; i < storedObjects.length; i += 1)
    {
        if (AreEqual(storedObjects[i], item)) {
            return i;
        }
    }
    return -1;
}

protected function AcediaObject GetByText(BaseText key)
{
    local int       index, consumed;
    local Parser    parser;

    parser = _.text.Parse(key);
    parser.MUnsignedInteger(index,,, consumed);
    if (!parser.Ok())
    {
        parser.FreeSelf();
        return none;
    }
    parser.FreeSelf();
    return GetItem(index);
}

/**
 *  Checks if value recorded at a given `index` is `none`.
 *
 *  @param  index   Index to check the value at.
 *  @return `true` if `none` value is recorded at `index` and
 *      `false` otherwise.
 *      In case `index` is out-of-bound, nothing is recorded there,
 *      not even `none`, so method will return `false`.
 */
public final function bool IsNone(int index)
{
    if (ValidateIndex(index)) {
        return (storedObjects[index] == none);
    }
    return false;
}

/**
 *  Returns `bool` item at `index`. If index is invalid or
 *  stores a non-`bool` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `BoolBox` or `BoolRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  index           Index of a `bool` item that `ArrayList`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `index` or it has a wrong type.
 *  @return `bool` value at `index` in the caller `ArrayList`.
 *      `defaultValue` if passed `index` is invalid or non-`bool` value
 *      is stored there.
 */
public final function bool GetBool(int index, optional bool defaultValue)
{
    local AcediaObject  result;
    local BoolBox       asBox;
    local BoolRef       asRef;

    result = BorrowItem(index);
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
 *  Changes `ArrayList`'s value at `index` to `value` that will be recorded
 *  as either `BoolBox` or `BoolRef`, depending of `asRef` optional parameter.
 *
 *  @param  index   Index, at which to change the value. If `ArrayList` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  value   Value to be set at a given index.
 *  @param  asRef   Given `bool` value will be recorded as immutable `BoolBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `BoolRef`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList SetBool(
    int             index,
    bool            value,
    optional bool   asRef)
{
    local AcediaObject newValue;

    if (asRef) {
        newValue = _.ref.bool(value);
    }
    else {
        newValue = _.box.bool(value);
    }
    SetItem(index, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns `byte` item at `index`. If index is invalid or
 *  stores a non-`byte` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `ByteBox` or `ByteRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  index           Index of a `byte` item that `ArrayList`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `index` or it has a wrong type.
 *  @return `byte` value at `index` in the caller `ArrayList`.
 *      `defaultValue` if passed `index` is invalid or non-`byte` value
 *      is stored there.
 */
public final function byte GetByte(int index, optional byte defaultValue)
{
    local AcediaObject  result;
    local ByteBox       asBox;
    local ByteRef       asRef;

    result = BorrowItem(index);
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
 *  Changes `ArrayList`'s value at `index` to `value` that will be recorded
 *  as either `ByteBox` or `ByteRef`, depending of `asRef` optional parameter.
 *
 *  @param  index   Index, at which to change the value. If `ArrayList` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  value   Value to be set at a given index.
 *  @param  asRef   Given `byte` value will be recorded as immutable `ByteBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `ByteRef`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList SetByte(
    int             index,
    byte            value,
    optional bool   asRef)
{
    local AcediaObject newValue;

    if (asRef) {
        newValue = _.ref.byte(value);
    }
    else {
        newValue = _.box.byte(value);
    }
    SetItem(index, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns `int` or `float` item at `index` as `int`. If index is invalid or
 *  stores a non-`int` (or non-`float`) value, returns `defaultValue`.
 *
 *  Referred value must be stored as `IntBox`, `IntRef`, `FloatBox` or
 *  `FloatRef` (or one of their sub-classes) for this method to work.
 *
 *  Allowing for implicit conversion between non-`byte` numeric types simplifies
 *  handling parsed input as there is no need to know whether parsed value is
 *  expected to be integer or floating point.
 *
 *  @param  index           Index of a `int` item that `ArrayList`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `index` or it has a wrong type.
 *  @return `int` value at `index` in the caller `ArrayList`.
 *      `defaultValue` if passed `index` is invalid or non-`int` value
 *      is stored there.
 */
public final function int GetInt(int index, optional int defaultValue)
{
    local AcediaObject  result;
    local IntBox        asBox;
    local IntRef        asRef;
    local FloatBox      asFloatBox;
    local FloatRef      asFloatRef;

    result = BorrowItem(index);
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
    asFloatBox = FloatBox(result);
    if (asFloatBox != none) {
        return int(asFloatBox.Get());
    }
    asFloatRef = FloatRef(result);
    if (asFloatRef != none) {
        return int(asFloatRef.Get());
    }
    return defaultValue;
}

/**
 *  Changes `ArrayList`'s value at `index` to `value` that will be recorded
 *  as either `IntBox` or `IntRef`, depending of `asRef` optional parameter.
 *
 *  @param  index   Index, at which to change the value. If `ArrayList` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  value   Value to be set at a given index.
 *  @param  asRef   Given `int` value will be recorded as immutable `IntBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `IntRef`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList SetInt(
    int             index,
    int             value,
    optional bool   asRef)
{
    local AcediaObject newValue;

    if (asRef) {
        newValue = _.ref.int(value);
    }
    else {
        newValue = _.box.int(value);
    }
    SetItem(index, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns `int` or `float` item at `index` as `float`. If index is invalid or
 *  stores a non-`float` (or non-`int`) value, returns `defaultValue`.
 *
 *  Referred value must be stored as `IntBox`, `IntRef`, `FloatBox` or
 *  `FloatRef` (or one of their sub-classes) for this method to work.
 *
 *  Allowing for implicit conversion between non-`byte` numeric types simplifies
 *  handling parsed input as there is no need to know whether parsed value is
 *  expected to be integer or floating point.
 *
 *  @param  index           Index of a `float` item that `ArrayList`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `index` or it has a wrong type.
 *  @return `float` value at `index` in the caller `ArrayList`.
 *      `defaultValue` if passed `index` is invalid or non-`float` value
 *      is stored there.
 */
public final function float GetFloat(int index, optional float defaultValue)
{
    local AcediaObject  result;
    local FloatBox      asBox;
    local FloatRef      asRef;
    local IntBox        asIntBox;
    local IntRef        asIntRef;

    result = BorrowItem(index);
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
    asIntBox = IntBox(result);
    if (asIntBox != none) {
        return float(asIntBox.Get());
    }
    asIntRef = IntRef(result);
    if (asIntRef != none) {
        return float(asIntRef.Get());
    }
    return defaultValue;
}

/**
 *  Changes `ArrayList`'s value at `index` to `value` that will be recorded
 *  as either `FloatBox` or `FloatRef`, depending of `asRef` optional parameter.
 *
 *  @param  index   Index, at which to change the value. If `ArrayList` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  value   Value to be set at a given index.
 *  @param  asRef   Given `float` value will be recorded as immutable `FloatBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `FloatRef`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList SetFloat(
    int             index,
    float           value,
    optional bool   asRef)
{
    local AcediaObject newValue;

    if (asRef) {
        newValue = _.ref.float(value);
    }
    else {
        newValue = _.box.float(value);
    }
    SetItem(index, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns `Vector` item at `index`. If index is invalid or
 *  stores a non-`int` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `VectorBox` or `VectorRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  index           Index of a `Vector` item that `ArrayList`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `index` or it has a wrong type.
 *  @return `Vector` value at `index` in the caller `ArrayList`.
 *      `defaultValue` if passed `index` is invalid or non-`Vector` value
 *      is stored there.
 */
public final function Vector GetVector(int index, optional Vector defaultValue)
{
    local AcediaObject  result;
    local VectorBox     asBox;
    local VectorRef     asRef;

    result = BorrowItem(index);
    if (result == none) {
        return defaultValue;
    }
    asBox = VectorBox(result);
    if (asBox != none) {
        return asBox.Get();
    }
    asRef = VectorRef(result);
    if (asRef != none) {
        return asRef.Get();
    }
    return defaultValue;
}

/**
 *  Changes `ArrayList`'s value at `index` to `value` that will be recorded
 *  as either `VectorBox` or `VectorRef`, depending of `asRef` optional
 *  parameter.
 *
 *  @param  index   Index, at which to change the value. If `ArrayList` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  value   Value to be set at a given index.
 *  @param  asRef   Given `Vector` value will be recorded as immutable
 *      `VectorBox` by default (`asRef == false`). Setting this parameter to
 *      `true` will make this method record it as a mutable `VectorRef`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList SetVector(
    int             index,
    Vector          value,
    optional bool   asRef)
{
    local AcediaObject newValue;

    if (asRef) {
        newValue = _.ref.Vec(value);
    }
    else {
        newValue = _.box.Vec(value);
    }
    SetItem(index, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns plain string item at `index`. If index is invalid or
 *  stores a non-`BaseText` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `Text` or `MutableText`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  index           Index of a `string` item that `ArrayList`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `index` or it has a wrong type.
 *  @return Plain string value at `index` in the caller `ArrayList`.
 *      `defaultValue` if passed `index` is invalid or non-`BaseText`
 *      value is stored there.
 */
public final function string GetString(int index, optional string defaultValue)
{
    local AcediaObject  result;
    local BaseText      asText;

    result = BorrowItem(index);
    if (result == none) {
        return defaultValue;
    }
    asText = BaseText(result);
    if (asText != none) {
        return asText.ToString();
    }
    return defaultValue;
}

/**
 *  Changes `ArrayList`'s value at `index` to `value` (treated as a plain
 *  string) that will be recorded as either `Text` or `MutableText`, depending
 *  of `asMutable` optional parameter.
 *
 *  @param  index       Index, at which to change the value. If `ArrayList` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  value       Value to be set at a given index.
 *  @param  asMutable   Given `string` value will be recorded as immutable
 *      `Text` by default (`asMutable == false`). Setting this parameter to
 *      `true` will make this method record it as a mutable `MutableText`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList SetString(
    int             index,
    string          value,
    optional bool   asMutable)
{
    local AcediaObject newValue;

    if (asMutable) {
        newValue = _.text.FromStringM(value);
    }
    else {
        newValue = _.text.FromString(value);
    }
    SetItem(index, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns formatted string item at `index`. If index is invalid or
 *  stores a non-`BaseText` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `Text` or `MutableText`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  index           Index of a `string` item that `ArrayList`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `index` or it has a wrong type.
 *  @return Formatted string value at `index` in the caller `ArrayList`.
 *      `defaultValue` if passed `index` is invalid or non-`BaseText`
 *      value is stored there.
 */
public final function string GetFormattedString(
    int             index,
    optional string defaultValue)
{
    local AcediaObject  result;
    local BaseText      asText;

    result = BorrowItem(index);
    if (result == none) {
        return defaultValue;
    }
    asText = BaseText(result);
    if (asText != none) {
        return asText.ToFormattedString();
    }
    return defaultValue;
}

/**
 *  Changes `ArrayList`'s value at `index` to `value` (treated as a formatted
 *  string) that will be recorded as either `Text` or `MutableText`, depending
 *  of `asMutable` optional parameter.
 *
 *  @param  index       Index, at which to change the value. If `ArrayList` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  value       Value to be set at a given index.
 *  @param  asMutable   Given `string` value will be recorded as immutable
 *      `Text` by default (`asMutable == false`). Setting this parameter to
 *      `true` will make this method record it as a mutable `MutableText`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList SetFormattedString(
    int             index,
    string          value,
    optional bool   asMutable)
{
    local AcediaObject newValue;

    if (asMutable) {
        newValue = _.text.FromFormattedStringM(value);
    }
    else {
        newValue = _.text.FromFormattedString(value);
    }
    SetItem(index, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *      Adds given `bool` at the end of the `ArrayList`, expanding it by
 *  one item.
 *
 *  @param  value   `bool` value to be added at the end of the `ArrayList`.
 *  @param  asRef   Given `bool` value will be recorded as immutable `BoolBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `BoolRef`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList AddBool(bool value, optional bool asRef)
{
    return SetBool(storedObjects.length, value, asRef);
}

/**
 *      Adds given `byte` at the end of the `ArrayList`, expanding it by
 *  one item.
 *
 *  @param  value   `byte` value to be added at the end of the `ArrayList`.
 *  @param  asRef   Given `byte` value will be recorded as immutable `ByteBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `ByteRef`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList AddByte(byte value, optional bool asRef)
{
    return SetByte(storedObjects.length, value, asRef);
}

/**
 *      Adds given `int` at the end of the `ArrayList`, expanding it by
 *  one item.
 *
 *  @param  value   `int` value to be added at the end of the `ArrayList`.
 *  @param  asRef   Given `int` value will be recorded as immutable `IntBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `IntRef`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList AddInt(int value, optional bool asRef)
{
    return SetInt(storedObjects.length, value, asRef);
}

/**
 *      Adds given `float` at the end of the `ArrayList`, expanding it by
 *  one item.
 *
 *  @param  value   `float` value to be added at the end of the `ArrayList`.
 *  @param  asRef   Given `float` value will be recorded as immutable `FloatBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `FloatRef`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList AddFloat(float value, optional bool asRef)
{
    return SetFloat(storedObjects.length, value, asRef);
}

/**
 *      Adds given `Vector` at the end of the `ArrayList`, expanding it by
 *  one item.
 *
 *  @param  value   `Vector` value to be added at the end of the `ArrayList`.
 *  @param  asRef   Given `Vector` value will be recorded as immutable
 *      `VectorBox` by default (`asRef == false`). Setting this parameter to
 *      `true` will make this method record it as a mutable `VectorRef`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList AddVector(Vector value, optional bool asRef)
{
    return SetVector(storedObjects.length, value, asRef);
}

/**
 *      Adds given plain string at the end of the `ArrayList`, expanding it by
 *  one item.
 *
 *  @param  value   Plain string value to be added at the end of
 *      the `ArrayList`.
 *  @param  asRef   Given plain string value will be recorded as immutable
 *      `Text` by default (`asRef == false`). Setting this parameter to `true`
 *      will make this method record it as a mutable `MutableText`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList AddString(string value, optional bool asRef)
{
    return SetString(storedObjects.length, value, asRef);
}

/**
 *      Adds given formatted string at the end of the `ArrayList`, expanding it
 *  by one item.
 *
 *  @param  value   Formatted string value to be added at the end of
 *      the `ArrayList`.
 *  @param  asRef   Given formatted string value will be recorded as immutable
 *      `Text` by default (`asRef == false`). Setting this parameter to `true`
 *      will make this method record it as a mutable `MutableText`.
 *  @return Reference to the caller `ArrayList` to allow for method chaining.
 */
public final function ArrayList AddFormattedString(
    string          value,
    optional bool   asRef)
{
    return SetFormattedString(storedObjects.length, value, asRef);
}

/**
 *  Returns `BaseText` item at `index`. If index is invalid or
 *  stores a non-`BaseText` value, returns `none`.
 *
 *  Referred value must be stored as `BaseText` (or one of it's sub-classes,
 *  such as `Text` or `MutableText`) for this method to work.
 *
 *  @param  index   Index of a `BaseText` item that `ArrayList` has to return.
 *  @return `BaseText` value at `index` in the caller `ArrayList`.
 *      `none` if passed `index` is invalid or non-`BaseText` value
 *      is stored there.
 */
public final function BaseText GetBaseText(int index)
{
    local BaseText result;

    result = BaseText(BorrowItem(index));
    if (result != none) {
        result.NewRef();
    }
    return result;
}

/**
 *  Returns `Text` item at `index`. If index is invalid or
 *  stores a non-`Text` value, returns `none`.
 *
 *  Referred value must be stored as `Text` (or one of it's sub-classes,
 *  such as `MutableText`) for this method to work.
 *
 *  @param  index   Index of a `Text` item that `ArrayList` has to return.
 *  @return `Text` value at `index` in the caller `ArrayList`.
 *      `none` if passed `index` is invalid or non-`Text` value
 *      is stored there.
 */
public final function Text GetText(int index)
{
    local Text result;

    result = Text(BorrowItem(index));
    if (result != none) {
        result.NewRef();
    }
    return result;
}

/**
 *  Returns `MutableText` item at `index`. If index is invalid or
 *  stores a non-`Text` value, returns `none`.
 *
 *  Referred value must be stored as `MutableText` for this method to work.
 *
 *  @param  index   Index of a `MutableText` item that `ArrayList` will return.
 *  @return `MutableText` value at `index` in the caller `ArrayList`.
 *      `none` if passed `index` is invalid or non-`MutableText` value
 *      is stored there.
 */
public final function MutableText GetMutableText(int index)
{
    local MutableText result;

    result = MutableText(BorrowItem(index));
    if (result != none) {
        result.NewRef();
    }
    return result;
}

/**
 *  Returns `ArrayList` item at `index`. If index is invalid or
 *  stores a non-`ArrayList` value, returns `none`.
 *
 *  Referred value must be stored as `Text` (or one of it's sub-classes,
 *  such as `MutableText`) for this method to work.
 *
 *  @param  index   Index of a `ArrayList` item that caller `ArrayList`
 *      has to return.
 *  @return `ArrayList` value at `index` in the caller `ArrayList`.
 *      `none` if passed `index` is invalid or non-`ArrayList` value
 *      is stored there.
 */
public final function ArrayList GetArrayList(int index)
{
    local ArrayList result;

    result = ArrayList(BorrowItem(index));
    if (result != none) {
        result.NewRef();
    }
    return result;
}

/**
 *  Returns `HashTable` item at `index`. If index is invalid or
 *  stores a non-`HashTable` value, returns `none`.
 *
 *  Referred value must be stored as `Text` (or one of it's sub-classes,
 *  such as `MutableText`) for this method to work.
 *
 *  @param  index   Index of a `HashTable` item that caller `ArrayList`
 *      has to return.
 *  @return `HashTable` value at `index` in the caller `ArrayList`.
 *      `none` if passed `index` is invalid or non-`HashTable` value
 *      is stored there.
 */
public final function HashTable GetHashTable(int index)
{
    local HashTable result;

    result = HashTable(BorrowItem(index));
    if (result != none) {
        result.NewRef();
    }
    return result;
}

defaultproperties
{
    iteratorClass = class'ArrayListIterator'
}