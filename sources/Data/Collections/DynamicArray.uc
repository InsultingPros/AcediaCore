/**
 *      Dynamic array object for storing arbitrary types of data. Generic
 *  storage is achieved by using `AcediaObject` as the stored type. Native
 *  variable types such as `int`, `bool`, etc. can be stored by boxing them into
 *  `AcediaObject`s.
 *      Appropriate classes and APIs for their construction are provided for
 *  main primitive types and can be extended to any custom `struct`.
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
class DynamicArray extends Collection;

//  Actual storage of all our data.
var private array<AcediaObject> storedObjects;
//      `managedFlags[i] > 0` iff `contents[i]` is a managed object.
//      Invariant `managedFlags.length == contents.length` should be enforced by
//  all methods.
var private array<byte>         managedFlags;
//      Recorded `lifeVersions` of all stored objects.
//      Invariant `lifeVersions.length == contents.length` should be enforced by
//  all methods.
var private array<int>          lifeVersions;

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
 *  Returns current length of dynamic `DynamicArray`.
 *  Cannot fail.
 *
 *  @return Returns length of the caller `DynamicArray`.
 *      Guaranteed to be non-negative.
 */
public final function int GetLength()
{
    return storedObjects.length;
}

/**
 *      Changes length of the caller `DynamicArray`.
 *      If `DynamicArray` size is increased as a result - added items will be
 *  filled with `none`s.
 *      If `DynamicArray` size is decreased - erased managed items will be
 *  automatically deallocated.
 *
 *  @param  newLength   New length of an `DynamicArray`.
 *      If negative value is passes - method will do nothing.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray SetLength(int newLength)
{
    local int i;
    if (newLength < 0) {
        return self;
    }
    for (i = newLength; i < storedObjects.length; i += 1) {
        FreeManagedItem(i);
    }
    storedObjects.length    = newLength;
    managedFlags.length     = newLength;
    lifeVersions.length     = newLength;
    return self;
}

/**
 *  Deallocates an item at a given index `index`, if it's managed.
 *  Does not check `DynamicArray` bounds for `index`, so you must ensure that
 *  `index` is valid.
 *
 *  @param  index   Index of the managed item to deallocate.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
protected final function DynamicArray FreeManagedItem(int index)
{
    if (storedObjects[index] == none)           return self;
    if (!storedObjects[index].IsAllocated())    return self;
    if (managedFlags[index] <= 0)               return self;
    if (lifeVersions[index] != storedObjects[index].GetLifeVersion()) {
        return self;
    }
    if (    storedObjects[index] != none && managedFlags[index] > 0
        &&  lifeVersions[index] == storedObjects[index].GetLifeVersion())
    {
        storedObjects[index].FreeSelf();
        storedObjects[index] = none;
    }
    return self;
}

/**
 *  Empties caller `DynamicArray`, erasing it's contents.
 *  All managed objects will be deallocated.
 *
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray Empty()
{
    SetLength(0);
    return self;
}

/**
 *      Adds `amountOfNewItems` empty (`none`) items at the end of
 *  the `DynamicArray`.
 *      To insert items at an arbitrary array index, use `Insert()`.
 *
 *  @param  amountOfNewItems    Amount of items to add at the end.
 *      If non-positive value is passed, - method does nothing.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray Add(int amountOfNewItems)
{
    if (amountOfNewItems > 0) {
        SetLength(storedObjects.length + amountOfNewItems);
    }
    return self;
}

/**
 *      Inserts `count` empty (`none`) items into the `DynamicArray`
 *  at specified position.
 *      The indices of the following items are increased by `count` in order
 *  to make room for the new items.
 *
 *  To add items at the end of an `DynamicArray`, consider using `Add()`,
 *  which is equivalent to `array.Insert(array.GetLength(), ...)`.
 *
 *  @param  index   Index, where first inserted item will be located.
 *      Must belong to `[0; self.GetLength()]` inclusive interval,
 *      otherwise method does nothing.
 *  @param  count   Amount of new items to insert.
 *      Must be positive, otherwise method does nothing.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray Insert(int index, int count)
{
    local int i;
    local int swapIndex;
    local int amountToShift;

    if (count <= 0)                                 return self;
    if (index < 0 || index > storedObjects.length)  return self;

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
 *  Swaps two `DynamicArray` items, along with information about their
 *  managed status.
 *
 *  @param  index1  Index of item to swap.
 *  @param  index2  Index of item to swap.
 */
protected final function Swap(int index1, int index2)
{
    local AcediaObject  temporaryItem;
    local int           temporaryNumber;
    //  Swap object
    temporaryItem = storedObjects[index1];
    storedObjects[index1] = storedObjects[index2];
    storedObjects[index2] = temporaryItem;
    //  Swap life versions
    temporaryNumber = lifeVersions[index1];
    lifeVersions[index1] = lifeVersions[index2];
    lifeVersions[index2] = temporaryNumber;
    //  Swap managed flags
    temporaryNumber = managedFlags[index1];
    managedFlags[index1] = managedFlags[index2];
    managedFlags[index2] = temporaryNumber;
}

/**
 *  Removes number items from the `DynamicArray`, starting at `index`.
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
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray Remove(int index, int count)
{
    local int i;
    if (count <= 0)                                 return self;
    if (index < 0 || index > storedObjects.length)  return self;

    count = Min(count, storedObjects.length - index);
    for (i = 0; i < count; i += 1) {
        FreeManagedItem(index + i);
    }
    storedObjects.Remove(index, count);
    managedFlags.Remove(index, count);
    lifeVersions.Remove(index, count);
    return self;
}

/**
 *  Removes item at a given index, shifting all the items that come after
 *  one place backwards.
 *
 *  @param  index   Remove items starting from this index.
 *      Must belong to `[0; self.GetLength() - 1]` inclusive interval,
 *      otherwise method does nothing.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray RemoveIndex(int index)
{
    Remove(index, 1);
    return self;
}

/**
 *  Checks if caller `DynamicArray`'s value at index `index` is managed.
 *
 *  Managed values will be automatically deallocated once they are removed
 *  (or overwritten) from the caller `DynamicArray`.
 *
 *  @return `true` if value, recorded in caller `DynamicArray` at index `index`
 *      is managed and `false` otherwise.
 *      If `index` is invalid (outside of `DynamicArray` bounds)
 *      also returns `false`.
 */
public final function bool IsManaged(int index)
{
    if (index < 0)                              return false;
    if (index >= storedObjects.length)          return false;
    if (storedObjects[index] == none)           return false;
    if (!storedObjects[index].IsAllocated())    return false;
    if (storedObjects[index].GetLifeVersion() != lifeVersions[index]) {
        return false;
    }

    return (managedFlags[index] > 0);
}

/**
 *  Returns item at `index` and replaces it with `none` inside `DynamicArray`.
 *  If index is invalid, returns `none`.
 *
 *  If returned value was managed, it won't be deallocated
 *  and will stop being managed.
 *
 *  @param  index   Index of an item that `DynamicArray` has to return.
 *  @return Either value at `index` in the caller `DynamicArray` or `none` if
 *      passed `index` is invalid.
 */
public final function AcediaObject TakeItem(int index)
{
    local AcediaObject result;
    if (index < 0)                              return none;
    if (index >= storedObjects.length)          return none;
    if (storedObjects[index] == none)           return none;
    if (!storedObjects[index].IsAllocated())    return none;
    if (storedObjects[index].GetLifeVersion() != lifeVersions[index]) {
        return none;
    }

    result                  = storedObjects[index];
    storedObjects[index]    = none;
    managedFlags[index]     = 0;
    lifeVersions[index]     = 0;
    return result;
}

/**
 *  Returns item at `index`. If index is invalid, returns `none`.
 *
 *  @param  index   Index of an item that `DynamicArray` has to return.
 *  @return Either value at `index` in the caller `DynamicArray` or `none` if
 *      passed `index` is invalid.
 */
public final function AcediaObject GetItem(int index)
{
    if (index < 0)                              return none;
    if (index >= storedObjects.length)          return none;
    if (storedObjects[index] == none)           return none;
    if (!storedObjects[index].IsAllocated())    return none;
    if (storedObjects[index].GetLifeVersion() != lifeVersions[index]) {
        return none;
    }

    return storedObjects[index];
}

/**
 *  Changes `DynamicArray`'s value at `index` to `item`.
 *
 *  @param  index   Index, at which to change the value. If `DynamicArray` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  item    Value to be set at a given index.
 *  @param  managed Whether `item` should be managed by `DynamicArray`.
 *      By default (`false`) all items are not managed.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray SetItem(
    int             index,
    AcediaObject    item,
    optional bool   managed)
{
    if (index < 0) {
        return self;
    }
    if (index >= storedObjects.length) {
        SetLength(index + 1);
    }
    else if (item != storedObjects[index]) {
        FreeManagedItem(index);
    }
    storedObjects[index] = item;
    managedFlags[index] = 0;
    if (managed) {
        managedFlags[index] = 1;
    }
    if (item != none) {
        lifeVersions[index] = item.GetLifeVersion();
    }
    return self;
}

/**
 *  Creates a new instance of class `valueClass` and records it's value at index
 *  `index` in the caller `DynamicArray`. Value is recorded as managed.
 *
 *  @param  index       Index, at which to change the value. If `DynamicArray`
 *      is not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  valueClass  Class of object to create. Will only be created if
 *      passed `index` is valid.
 *  @return Caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray CreateItem(
    int                 index,
    class<AcediaObject> valueClass)
{
    if (index < 0)          return self;
    if (valueClass == none) return self;

    return SetItem(index, AcediaObject(_.memory.Allocate(valueClass)), true);
}

/**
 *      Adds given `item` at the end of the `DynamicArray`, expanding it by
 *  one item.
 *  Cannot fail.
 *
 *  @param  item    Item to be added at the end of the `DynamicArray`.
 *  @param  managed Whether `item` should be managed by `DynamicArray`.
 *      By default (`false`) all items are not managed.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray AddItem(
    AcediaObject    item,
    optional bool   managed)
{
    return SetItem(storedObjects.length, item, managed);
}

/**
 *      Inserts given `item` at index `index` of the `DynamicArray`,
 *  shifting all the items starting from `index` one position to the right.
 *      Cannot fail.
 *
 *  @param  index   Index at which to insert new item. Must belong to
 *      inclusive range `[0; self.GetLength()]`, otherwise method does nothing.
 *  @param  item    Item to insert.
 *  @param  managed Whether `item` should be managed by `DynamicArray`.
 *      By default (`false`) all items are not managed.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray InsertItem(
    int             index,
    AcediaObject    item,
    optional bool   managed)
{
    if (index < 0)                      return self;
    if (index > storedObjects.length)   return self;

    Insert(index, 1);
    SetItem(index, item, managed);
    return self;
}

/**
 *  Returns all occurrences of `item` in the caller `DynamicArray`
 *  (optionally only first one).
 *
 *  @param  item            Item that needs to be removed from a `DynamicArray`.
 *  @param  onlyFirstItem   Set to `true` to only remove first occurrence.
 *      By default `false`, which means all occurrences will be removed.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray RemoveItem(
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
 *  Finds first occurrence of `item` in caller `DynamicArray` and returns
 *  it's index.
 *
 *  @param  item    Item to find in `DynamicArray`.
 *  @return Index of first occurrence of `item` in caller `DynamicArray`.
 *      `-1` if `item` is not found.
 */
public final function int Find(AcediaObject item)
{
    local int i;
    for (i = 0; i < storedObjects.length; i += 1)
    {
        if (AreEqual(storedObjects[i], item)) {
            return i;
        }
    }
    return -1;
}

protected function AcediaObject GetByText(Text key)
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
 *  Returns `bool` item at `index`. If index is invalid or
 *  stores a non-`bool` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `BoolBox` or `BoolRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  index           Index of a `bool` item that `DynamicArray`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `index` or it has a wrong type.
 *  @return `bool` value at `index` in the caller `DynamicArray`.
 *      `defaultValue` if passed `index` is invalid or non-`bool` value
 *      is stored there.
 */
public final function bool GetBool(int index, optional bool defaultValue)
{
    local AcediaObject  result;
    local BoolBox       asBox;
    local BoolRef       asRef;
    result = GetItem(index);
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
 *  Changes `DynamicArray`'s value at `index` to `value` that will be recorded
 *  as either `BoolBox` or `BoolRef`, depending of `asRef` optional parameter.
 *
 *  Inserted value will always be recorded as a managed value, i.e. it will be
 *  automatically deallocated when overwritten, removed or caller `DynamicArray`
 *  is deallocated.
 *
 *  @param  index   Index, at which to change the value. If `DynamicArray` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  value   Value to be set at a given index.
 *  @param  asRef   Given `bool` value will be recorded as immutable `BoolBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `BoolRef`.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray SetBool(
    int             index,
    bool            value,
    optional bool   asRef)
{
    if (asRef) {
        SetItem(index, _.ref.bool(value), true);
    }
    else {
        SetItem(index, _.box.bool(value), true);
    }
    return self;
}

/**
 *  Returns `byte` item at `index`. If index is invalid or
 *  stores a non-`byte` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `ByteBox` or `ByteRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  index           Index of a `byte` item that `DynamicArray`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `index` or it has a wrong type.
 *  @return `byte` value at `index` in the caller `DynamicArray`.
 *      `defaultValue` if passed `index` is invalid or non-`byte` value
 *      is stored there.
 */
public final function byte GetByte(int index, optional byte defaultValue)
{
    local AcediaObject  result;
    local ByteBox       asBox;
    local ByteRef       asRef;
    result = GetItem(index);
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
 *  Changes `DynamicArray`'s value at `index` to `value` that will be recorded
 *  as either `ByteBox` or `ByteRef`, depending of `asRef` optional parameter.
 *
 *  Inserted value will always be recorded as a managed value, i.e. it will be
 *  automatically deallocated when overwritten, removed or caller `DynamicArray`
 *  is deallocated.
 *
 *  @param  index   Index, at which to change the value. If `DynamicArray` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  value   Value to be set at a given index.
 *  @param  asRef   Given `byte` value will be recorded as immutable `ByteBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `ByteRef`.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray SetByte(
    int             index,
    byte            value,
    optional bool   asRef)
{
    if (asRef) {
        SetItem(index, _.ref.byte(value), true);
    }
    else {
        SetItem(index, _.box.byte(value), true);
    }
    return self;
}

/**
 *  Returns `int` item at `index`. If index is invalid or
 *  stores a non-`int` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `IntBox` or `IntRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  index           Index of a `int` item that `DynamicArray`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `index` or it has a wrong type.
 *  @return `int` value at `index` in the caller `DynamicArray`.
 *      `defaultValue` if passed `index` is invalid or non-`int` value
 *      is stored there.
 */
public final function int GetInt(int index, optional int defaultValue)
{
    local AcediaObject  result;
    local IntBox        asBox;
    local IntRef        asRef;
    result = GetItem(index);
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
 *  Changes `DynamicArray`'s value at `index` to `value` that will be recorded
 *  as either `IntBox` or `IntRef`, depending of `asRef` optional parameter.
 *
 *  Inserted value will always be recorded as a managed value, i.e. it will be
 *  automatically deallocated when overwritten, removed or caller `DynamicArray`
 *  is deallocated.
 *
 *  @param  index   Index, at which to change the value. If `DynamicArray` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  value   Value to be set at a given index.
 *  @param  asRef   Given `int` value will be recorded as immutable `IntBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `IntRef`.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray SetInt(
    int             index,
    int             value,
    optional bool   asRef)
{
    if (asRef) {
        SetItem(index, _.ref.int(value), true);
    }
    else {
        SetItem(index, _.box.int(value), true);
    }
    return self;
}

/**
 *  Returns `float` item at `index`. If index is invalid or
 *  stores a non-`int` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `FloatBox` or `FloatRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  index           Index of a `float` item that `DynamicArray`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `index` or it has a wrong type.
 *  @return `float` value at `index` in the caller `DynamicArray`.
 *      `defaultValue` if passed `index` is invalid or non-`float` value
 *      is stored there.
 */
public final function float GetFloat(int index, optional float defaultValue)
{
    local AcediaObject  result;
    local FloatBox      asBox;
    local FloatRef      asRef;
    result = GetItem(index);
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
 *  Changes `DynamicArray`'s value at `index` to `value` that will be recorded
 *  as either `FloatBox` or `FloatRef`, depending of `asRef` optional parameter.
 *
 *  Inserted value will always be recorded as a managed value, i.e. it will be
 *  automatically deallocated when overwritten, removed or caller `DynamicArray`
 *  is deallocated.
 *
 *  @param  index   Index, at which to change the value. If `DynamicArray` is
 *      not long enough to hold it, it will be automatically expanded.
 *      If passed index is negative - method will do nothing.
 *  @param  value   Value to be set at a given index.
 *  @param  asRef   Given `float` value will be recorded as immutable `FloatBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `FloatRef`.
 *  @return Reference to the caller `DynamicArray` to allow for method chaining.
 */
public final function DynamicArray SetFloat(
    int             index,
    float           value,
    optional bool   asRef)
{
    if (asRef) {
        SetItem(index, _.ref.float(value), true);
    }
    else {
        SetItem(index, _.box.float(value), true);
    }
    return self;
}

/**
 *  Returns `Text` item at `index`. If index is invalid or
 *  stores a non-`Text` value, returns `none`.
 *
 *  Referred value must be stored as `Text` (or one of it's sub-classes,
 *  such as `MutableText`) for this method to work.
 *
 *  @param  index   Index of a `Text` item that `DynamicArray` has to return.
 *  @return `Text` value at `index` in the caller `DynamicArray`.
 *      `none` if passed `index` is invalid or non-`Text` value
 *      is stored there.
 */
public final function Text GetText(int index)
{
    return Text(GetItem(index));
}

/**
 *  Returns `AssociativeArray` item at `index`. If index is invalid or
 *  stores a non-`AssociativeArray` value, returns `none`.
 *
 *  Referred value must be stored as `AssociativeArray`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  index   Index of an `AssociativeArray` item that `DynamicArray`
 *      has to return.
 *  @return `AssociativeArray` value at `index` in the caller `DynamicArray`.
 *      `none` if passed `index` is invalid or non-`AssociativeArray` value
 *      is stored there.
 */
public final function AssociativeArray GetAssociativeArray(int index)
{
    return AssociativeArray(GetItem(index));
}

/**
 *  Returns `DynamicArray` item at `index`. If index is invalid or
 *  stores a non-`DynamicArray` value, returns `none`.
 *
 *  Referred value must be stored as `Text` (or one of it's sub-classes,
 *  such as `MutableText`) for this method to work.
 *
 *  @param  index   Index of a `DynamicArray` item that caller `DynamicArray`
 *      has to return.
 *  @return `DynamicArray` value at `index` in the caller `DynamicArray`.
 *      `none` if passed `index` is invalid or non-`DynamicArray` value
 *      is stored there.
 */
public final function DynamicArray GetDynamicArray(int index)
{
    return DynamicArray(GetItem(index));
}

defaultproperties
{
    iteratorClass = class'DynamicArrayIterator'
}