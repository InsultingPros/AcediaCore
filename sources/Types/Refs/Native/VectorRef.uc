/**
 *  This file either is or was auto-generated from the template for
 *  value references.
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
class VectorRef extends ValueRef;

var protected Vector value;

protected function Finalizer()
{
    value = Vect(0.0f, 0.0f, 0.0f);
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
 *  Changes stored value. Cannot fail.
 *
 *  @param  newValue    New value to store in this reference.
 *  @return Reference to the caller `VectorRef` to allow for method chaining.
 */
public final function VectorRef Set(Vector newValue)
{
    value = newValue;
    return self;
}

/**
 *  Changes x-coordinate of the stored value.
 *
 *  @param  newValue    New value of the x-coordinate of the stored reference.
 *  @return Reference to the caller `VectorRef` to allow for method chaining.
 */
public final function VectorRef SetX(float newValue)
{
    value.x = newValue;
    return self;
}

/**
 *  Changes y-coordinate of the stored value.
 *
 *  @param  newValue    New value of the x-coordinate of the stored reference.
 *  @return Reference to the caller `VectorRef` to allow for method chaining.
 */
public final function VectorRef SetY(float newValue)
{
    value.y = newValue;
    return self;
}

/**
 *  Changes z-coordinate of the stored value.
 *
 *  @param  newValue    New value of the x-coordinate of the stored reference.
 *  @return Reference to the caller `VectorRef` to allow for method chaining.
 */
public final function VectorRef SetZ(float newValue)
{
    value.z = newValue;
    return self;
}

public function bool IsEqual(Object other)
{
    local VectorRef otherBox;
    otherBox = VectorRef(other);
    if (otherBox == none) {
        return false;
    }
    return value == otherBox.value;
}

defaultproperties
{
}