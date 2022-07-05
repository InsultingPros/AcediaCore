/**
 *  This file either is or was auto-generated from the template for
 *  array box.
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
class VectorArrayBox extends ArrayBox;

var protected array< Vector > value;

//      Compares an element from the array to the passed `item`.
//      Does not check boundary conditions, so make sure passed index is valid.
//
//  `0` means values are equal;
//  `-1` means value at `index1` is strictly smaller;
//  `1` means value at `index1` is strictly larger.
//  ^ Only these 3 values can be returned.
private function int _compareTo(int index, Vector item)
{
    if (value[index] == item) {
        return 0;
    }
    if (value[index].x < item.x) {
        return -1;
    }
    if (value[index].y < item.y) {
        return -1;
    }
    if (value[index].z < item.z) {
        return -1;
    }
    return 1;
}

/**
 *  Returns stored value.
 *
 *  @return Value, stored in this box.
 */
public final function array< Vector > Get()
{
    return value;
}

/**
 *  Initialized box value. Can only be called once.
 *
 *  @param  boxValue    Value to store in this box.
 *  @return Reference to the caller `VectorArrayBox` to allow for method
 *      chaining.
 */
public final function VectorArrayBox Initialize(array< Vector > boxValue)
{
    if (IsInitialized()) return self;
    value = boxValue;
    MarkInitialized();
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
 *  Returns item at `index`. If index is invalid, returns `defaultValue`.
 *
 *  @param  index           Index of an item that array has to return.
 *  @param  defaultValue    Value that will be returned if either `index < 0`
 *      or `index >= self.GetLength()`.
 *  @return Either value at `index` in the caller array or `defaultValue` if
 *      passed `index` is invalid.
 */
public final function Vector GetItem(
    int                     index,
    optional Vector    defaultValue)
{
    if (index < 0)              return defaultValue;
    if (index >= value.length)  return defaultValue;
    return value[index];
}

/**
 *  Finds first occurrence of `item` in caller `FloatArrayBox` and returns
 *  it's index.
 *
 *  @param  item    Item to find in array.
 *  @return Index of first occurrence of `item` in caller `FloatArrayBox`.
 *      `-1` if `item` is not found.
 */
public final function int Find(Vector item)
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

public function bool IsEqual(Object other)
{
    local int           i;
    local VectorArrayBox otherBox;
    local array<Vector>  otherValue;
    otherBox = VectorArrayBox(other);
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

protected function int CalculateHashCode()
{
    local int i;
    local int result;
    result = 28492904;
    for (i = 0; i < value.length; i += 1) {
        result = CombineHash(result, CalculateVectorHashCode(value[i]));
    }
    return result;
}

private final function int CalculateVectorHashCode(Vector someVector)
{
    local int hashCode;
    hashCode = CalculateFloatHashCode(someVector.x);
    hashCode = CombineHash(hashCode, CalculateFloatHashCode(someVector.y));
    return CombineHash(hashCode, CalculateFloatHashCode(someVector.z));
}

private final function int CalculateFloatHashCode(float someFloat)
{
    local int integerPart, fractionalPart;
    integerPart = Ceil(someFloat) - 1;
    if (someFloat - integerPart != 0) {
        fractionalPart = Ceil(1 / (someFloat - integerPart));
    }
    else {
        fractionalPart = -26422645;
    }
    return CombineHash(integerPart, fractionalPart);
}

defaultproperties
{
}
