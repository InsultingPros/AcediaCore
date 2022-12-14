/**
 *  This file either is or was auto-generated from the template for
 *  value box.
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
class BoolBox extends ValueBox;

var protected bool value;

protected function Finalizer()
{
    value = false;
}

/**
 *  Returns stored value.
 *
 *  @return Value, stored in this reference.
 */
public final function bool Get()
{
    return value;
}

/**
 *  Initialized box value. Can only be called once.
 *
 *  @param  boxValue    Value to store in this reference.
 *  @return Reference to the caller `BoolBox` to allow for method chaining.
 */
public final function BoolBox Initialize(bool boxValue)
{
    if (IsInitialized()) return self;
    value = boxValue;
    MarkInitialized();
    return self;
}

public function bool IsEqual(Object other)
{
    local BoolBox otherBox;
    otherBox = BoolBox(other);
    if (otherBox == none) {
        return false;
    }
    return value == otherBox.value;
}

protected function int CalculateHashCode()
{
    if (value) {
        return 328742932;
    }
    return 83619237;
}

defaultproperties
{
}
