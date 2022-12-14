/**
 *  This file either is or was auto-generated from the template for
 *  value references.
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
class BoolRef extends ValueRef;

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
 *  Changes stored value. Cannot fail.
 *
 *  @param  newValue    New value to store in this reference.
 *  @return Reference to the caller `BoolRef` to allow for method chaining.
 */
public final function BoolRef Set(bool newValue)
{
    value = newValue;
    return self;
}

public function bool IsEqual(Object other)
{
    local BoolRef otherBox;
    otherBox = BoolRef(other);
    if (otherBox == none) {
        return false;
    }
    return value == otherBox.value;
}

defaultproperties
{
}
