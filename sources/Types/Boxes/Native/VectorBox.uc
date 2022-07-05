/**
 *  This file either is or was auto-generated from the template for
 *  value box.
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
class VectorBox extends ValueBox;

var protected Vector value;

protected function Finalizer()
{
    value = Vect(0.0, 0.0, 0.0);
}

/**
 *  Returns stored value.
 *
 *  @return Value, stored in this reference.
 */
public final function Vector Get()
{
    return value;
}

/**
 *  Returns x-coordinate of the stored value.
 *
 *  @return Value, stored in this reference.
 */
public final function float GetX()
{
    return value.x;
}

/**
 *  Returns y-coordinate of the stored value.
 *
 *  @return Value, stored in this reference.
 */
public final function float GetY()
{
    return value.y;
}

/**
 *  Returns z-coordinate of the stored value.
 *
 *  @return Value, stored in this reference.
 */
public final function float GetZ()
{
    return value.z;
}

/**
 *  Initialized box value. Can only be called once.
 *
 *  @param  boxValue    Value to store in this reference.
 *  @return Reference to the caller `VectorBox` to allow for method chaining.
 */
public final function VectorBox Initialize(Vector boxValue)
{
    if (IsInitialized()) return self;
    value = boxValue;
    MarkInitialized();
    return self;
}

public function bool IsEqual(Object other)
{
    local VectorBox otherBox;
    otherBox = VectorBox(other);
    if (otherBox == none) {
        return false;
    }
    return value == otherBox.value;
}

protected function int CalculateHashCode()
{
    local int hashCode;
    hashCode = CalculateFloatHashCode(value.x);
    hashCode = CombineHash(hashCode, CalculateFloatHashCode(value.y));
    return CombineHash(hashCode, CalculateFloatHashCode(value.z));
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