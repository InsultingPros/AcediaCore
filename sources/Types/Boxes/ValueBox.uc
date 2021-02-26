/**
 *      This file either is or was auto-generated from the template for
 *  value box.
 *      Boxes are immutable wrappers around primitive values and arrays.
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
class ValueBox extends AcediaObject
    abstract;

var private bool boxInitialized;

/**
 *  Marks caller box as initialized with value.
 */
protected final function MarkInitialized()
{
    boxInitialized = true;
}

/**
 *  Checks if caller box was initialized.
 *  Once initialized box cannot be de-initialized without deallocation.
 */
public final function bool IsInitialized()
{
    return boxInitialized;
}

protected function Constructor()
{
    boxInitialized = false;
}

protected function Finalizer()
{
    boxInitialized = false;
}

defaultproperties
{
}