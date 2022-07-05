/**
 *  Object that is meant to describe meta-information about types (Acedia's
 *  and not). Currently a stub that stores class name.
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
class AcediaType extends AcediaObject;

var protected class<Object> unrealClass;

protected function Finalizer()
{
    unrealClass = none;
}

/**
 *  Initialized box value. Can only be called once.
 *
 *  @param  boxValue    Value to store in this reference.
 *  @return Reference to the caller `BoolBox` to allow for method chaining.
 */
public final function AcediaType Initialize(class<Object> sourceClass)
{
    if (unrealClass != none) {
        return self;
    }
    unrealClass = sourceClass;
    return self;
}

public function bool IsEqual(Object other)
{
    local AcediaType otherType;
    otherType = AcediaType(other);
    if (otherType == none) {
        return false;
    }
    return unrealClass == otherType.unrealClass;
}

defaultproperties
{
}