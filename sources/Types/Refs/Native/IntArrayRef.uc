/**
 *  This file either is or was auto-generated from the template for
 *  array references.
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
class IntArrayRef extends ArrayRef;

var protected array< int > value;

//  Method, used to compare array values at different indices.
//  Does not check boundary conditions, so make sure passed indices are valid.
//
//  `0` means values are equal;
//  `-1` means value at `index1` is strictly smaller;
//  `1` means value at `index1` is strictly larger.
//  ^ Only these 3 values can be returned.
private function int _compare(int index1, int index2)
{
    if (value[index1] == value[index2]) {
        return 0;
    }
    if (value[index1] < value[index2]) {
        return -1;
    }
    return 1;
}

//      Compares an element from the array to the passed `item`.
//      Does not check boundary conditions, so make sure passed index is valid.
//      Refer to `_compare` for details on return value
//  (consider `item` corresponding to second/right value at `index2`).
private function int _compareTo(int index, int item)
{
    if (value[index] == item) {
        return 0;
    }
    if (value[index] < item) {
        return -1;
    }
    return 1;
}

//  Free array data
protected function Finalizer()
{
    value.length = 0;
}

/**
 *  Returns stored value.
 *
 *  @return Value, stored in this reference.
 */
public final function array< int > Get()
{
    return value;
}

/**
 *  Changes stored value. Cannot fail.
 *
 *  @param  newValue    New value to store in this reference.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef Set(array< int > newValue)
{
    value = newValue;
    return self;
}

/**
 *  Returns current length of stored array.
 *  Cannot fail.
 *
 *  @return Returns length of the stored array. Guaranteed to be non-negative.
 */
public final function int GetLength()
{
    return value.length;
}

/**
 *      Changes length of the stored array.
 *      If array size is increased as a result - added elements will be
 *  filled with their default values.
 *
 *  @param  newLength   New length of an array. If negative value is passes -
 *      method will do nothing.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef SetLength(int newLength)
{
    if (newLength < 0) return self;
    value.length = newLength;
    return self;
}

/**
 *  Empties stored array, forgetting about it's contents.
 *
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef Empty()
{
    value.length = 0;
    return self;
}

/**
 *  Adds `amountOFNewElements` empty elements at the end of the array.
 *  To insert elements at an arbitrary array index, use `Insert()`.
 *
 *  @param  amountOFNewElements Amount of elements to add at the end.
 *      If non-positive value is passed, - method does nothing.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef Add(int amountOFNewElements)
{
    if (amountOFNewElements > 0) {
        value.length = value.length + amountOfNewElements;
    }
    return self;
}

/**
 *  Inserts `count` empty elements into the array at specified position.
 *  The indices of the following elements are increased by `count` in order
 *  to make room for the new elements.
 *
 *  To add elements at the end of an array, consider using `Add()`,
 *  which is equivalent to `array.Insert(array.GetLength(), ...)`.
 *
 *  @param  index   Index, where first inserted element will be located.
 *      Must belong to `[0; self.GetLength()]` inclusive interval,
 *      otherwise method does nothing.
 *  @param  count   Amount of new elements to insert.
 *      Must be positive, otherwise method does nothing.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef Insert(int index, int count)
{
    local int           i;
    local int           swapIndex;
    local int           amountToShift;
    local int   temporary;

    if (count <= 0)                         return self;
    if (index < 0 || index > value.length)  return self;

    amountToShift = value.length - index;
    Add(count);
    if (amountToShift == 0) {
        return self;
    }
    for (i = 0; i < amountToShift; i += 1)
    {
        swapIndex = value.length - i - 1;
        temporary = value[swapIndex];
        value[swapIndex] = value[swapIndex - count];
        value[swapIndex - count] = temporary;
    }
    return self;
}

/**
 *  Removes number elements from the array, starting at `index`.
 *  All elements before position and from `index + count` on are not changed,
 *  but the element indices change, - they shift to close the gap,
 *  created by removed elements.
 *
 *  @param  index   Remove elements starting from this index.
 *      Must belong to `[0; self.GetLength() - 1]` inclusive interval,
 *      otherwise method does nothing.
 *  @param  count   Removes at most this much elements.
 *      Must be positive, otherwise method does nothing.
 *      Specifying more elements than can be removed simply removes
 *      all elements, starting from `index`.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef Remove(int index, int count)
{
    if (count <= 0)                         return self;
    if (index < 0 || index > value.length)  return self;

    count = Min(count, value.length - index);
    value.Remove(index, count);
}

/**
 *  Removes value at a given index, shifting all the elements that come after
 *  one place backwards.
 *
 *  @param  index   Remove elements starting from this index.
 *      Must belong to `[0; self.GetLength() - 1]` inclusive interval,
 *      otherwise method does nothing.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef RemoveIndex(int index)
{
    Remove(index, 1);
    return self;
}

/**
 *  Returns item at `index`. If index is invalid, returns `defaultValue`.
 *
 *  @param  index           Index of an item that array has to return.
 *  @param  defaultValue    Value that will be returned if either `index < 0`
 *      or `index >= self.GetLength()`.
 *  @return Either value at `index` in the caller array or `defaultValue` if
 *      passed `index` is invalid.
 */
public final function int GetItem(
    int                     index,
    optional int    defaultValue)
{
    if (index < 0)              return defaultValue;
    if (index >= value.length)  return defaultValue;
    return value[index];
}

/**
 *  Changes array's value at `index` to `item`.
 *
 *  @param  index   Index, at which to change the value. If array is not long
 *      enough to hold it, it will be automatically expanded.
 *  @param  item    Value to be set at a given index.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef SetItem(int index, int item)
{
    if (index < 0)              return self;
    if (index >= value.length) {
        value.length = index + 1;
    }
    value[index] = item;
    return self;
}

/**
 *  Adds given `item` at the end of the array, expanding it by 1 element.
 *  Cannot fail.
 *
 *  @param  item    Item to be added at the end of the array.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef AddItem(int item)
{
    value[value.length] = item;
    return self;
}

/**
 *      Inserts given `item` at index `index` of the array, shifting all
 *  the elements starting from `index` one position to the right.
 *      Cannot fail.
 *
 *  @param  index   Index at which to insert new element. Must belong to
 *      inclusive range `[0; self.GetLength()]`, otherwise method does nothing.
 *  @param  item    Item to insert.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef InsertItem(int index, int item)
{
    if (index < 0)              return self;
    if (index > value.length)   return self;
    Insert(index, 1);
    value[index] = item;
    return self;
}

/**
 *      Adds given array of items at the end of the array, expanding it by
 *  inserted amount.
 *      Cannot fail.
 *
 *  @param  item    Item array to be added at the end of
 *      the caller `IntArrayRef`.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef AddArray(array< int > items)
{
    local int i;
    for (i = 0; i < items.length; i += 1) {
        value[value.length] = items[i];
    }
    return self;
}

/**
 *      Inserts items array at index `index` of the array, shifting all
 *  the elements starting from `index` by inserted amount to the right.
 *      Cannot fail.
 *
 *  @param  index   Index at which to insert array. Must belong to
 *      inclusive range `[0; self.GetLength()]`, otherwise method does nothing.
 *  @param  item    Item array to insert.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef InsertArray(
    int                     index,
    array< int >    items)
{
    local int i;
    if (index < 0)              return self;
    if (index > value.length)   return self;
    if (items.length == 0)      return self;

    Insert(index, items.length);
    for (i = 0; i < items.length; i += 1) {
        value[index + i] = items[i];
    }
    return self;
}

/**
 *      Adds given array of items at the end of the array, expanding it by
 *  inserted amount.
 *      Cannot fail.
 *
 *  @param  item    Item array to be added at the end of
 *      the caller `IntArrayRef`.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef AddArrayRef(IntArrayRef other)
{
    local int                   i;
    local array< int >  otherValue;
    otherValue = other.value;
    for (i = 0; i < otherValue.length; i += 1) {
        value[value.length] = otherValue[i];
    }
    return self;
}

/**
 *      Inserts items array at index `index` of the array, shifting all
 *  the elements starting from `index` by inserted amount to the right.
 *      Cannot fail.
 *
 *  @param  index   Index at which to insert array. Must belong to
 *      inclusive range `[0; self.GetLength()]`, otherwise method does nothing.
 *  @param  item    Item array to insert.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef InsertArrayRef(int index, IntArrayRef other)
{
    local int                   i;
    local array< int >  otherValue;
    if (index < 0)              return self;
    if (index > value.length)   return self;
    if (other.GetLength() == 0) return self;

    otherValue = other.value;
    Insert(index, otherValue.length);
    for (i = 0; i < otherValue.length; i += 1) {
        value[index + i] = otherValue[i];
    }
    return self;
}

/**
 *  Returns all occurrences of `item` in the caller `int`
 *  (optionally only first one).
 *
 *  @param  item            Element that needs to be removed from an array.
 *  @param  onlyFirstItem   Set to `true` to only remove first occurrence.
 *      By default `false`, which means all occurrences will be removed.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef RemoveItem(
    int     item,
    optional bool   onlyFirstItem)
{
    local int i;
    while (i < value.length)
    {
        if (_compareTo(i, item) == 0)
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
 *  Finds first occurrence of `item` in caller `IntArrayRef` and returns
 *  it's index.
 *
 *  @param  item    Item to find in array.
 *  @return Index of first occurrence of `item` in caller `IntArrayRef`.
 *      `-1` if `item` is not found.
 */
public final function int Find(int item)
{
    local int i;
    for (i = 0; i < value.length; i += 1)
    {
        if (_compareTo(i, item) == 0) {
            return i;
        }
    }
    return -1;
}

/**
 *  Replaces any occurrence of `search` with `replacement` inside
 *  the caller `IntArrayRef`.
 *
 *  @param  search      Items to replace.
 *  @param  replacement Item to replace `search` with.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef Replace(
    int search,
    int replacement)
{
    local int i;
    for (i = 0; i < value.length; i += 1)
    {
        if (_compareTo(i, search) == 0) {
            value[i] = replacement;
        }
    }
    return self;
}

/**
 *  Sorts contents of caller `IntArrayRef` in either ascending or
 *  descending order.
 *
 *  @param  descending  By default (`false`) method sorts array in
 *      ascending order, setting parameter to `true` will force sorting
 *      in descending order.
 *  @return Reference to the caller `IntArrayRef` to allow for method chaining.
 */
public final function IntArrayRef Sort(optional bool descending)
{
    if (descending) {
        _sort(0, value.length - 1, -1);
    }
    else {
        _sort(0, value.length - 1, 1);
    }
    return self;
}

//      Sorts slice between left and right.
//      `sortMod == 1` for ascending order and `sortMod == -1` for descending,
//  other values are invalid.
private final function _sort(int left, int right, int sortMod)
{
    local int           i, lessOrEqualToPivot;
    local int   swap;
    local int           pivot;
    if (right <= left) {
        return;
    }
    if (left + 7 < right)
    {
        _insertSort(left, right, sortMod);
        return;
    }
    //  Chose and put pivot element at the beginning
    pivot = MedianOfThree(left, right);
    swap = value[pivot];
    value[pivot] = value[left];
    value[left] = swap;
    //  Partition
    i = left + 1;
    lessOrEqualToPivot = left;
    while (i < right)
    {
        // value[i] <= value[pivot]
        if (_compare(i, pivot) * sortMod != -1)
        {
            lessOrEqualToPivot += 1;
            if (i != lessOrEqualToPivot)
            {
                swap = value[lessOrEqualToPivot];
                value[lessOrEqualToPivot] = value[i];
                value[i] = swap;
            }
        }
        i += 1;
    }
    _sort(left, lessOrEqualToPivot, sortMod);
    _sort(lessOrEqualToPivot + 1, right, sortMod);
}

//  Insert sort for sorting small sub-arrays._getPool.
//  Expects (and does not check) `left < right` condition.
private final function _insertSort(int left, int right, int sortMod)
{
    local int           i;
    local int           sortedPart;
    local int   swap;
    sortedPart = left;
    while (sortedPart < right)
    {
        i = sortedPart + 1;
        while (i > left && _compare(i - 1, i) * sortMod == 1)
        {
            swap = value[i];
            value[i] = value[i - 1];
            value[i - 1] = swap;
            i -= 1;
        }
        sortedPart += 1;
    }
}

//  Helper method for calculating median of three, for use in quick sort.
//  Expects (and does not check) `left < right` condition.
private final function int MedianOfThree(int left, int right)
{
    local int mid;
    mid = (left + right) / 2;
    if (_compare(left, mid) == 1)
    {
        if (_compare(mid, right) == 1) {
            return mid;
        }
        else if (_compare(right, left) == 1) {
            return left;
        }
    }
    else
    {
        if (_compare(right, mid) == 1) {
            return mid;
        }
        else if (_compare(left, right) == 1) {
            return left;
        }
    }
    return right;
}

public function bool IsEqual(Object other)
{
    local int           i;
    local IntArrayRef   otherBox;
    local array<int>    otherValue;
    otherBox = IntArrayRef(other);
    if (otherBox == none) {
        return false;
    }
    otherValue = otherBox.value;
    if (value.length != otherValue.length) {
        return false;
    }
    for (i = 0; i < value.length; i += 1)
    {
        if (value[i] != otherValue[i]) {
            return false;
        }
    }
    return true;
}

defaultproperties
{
}
