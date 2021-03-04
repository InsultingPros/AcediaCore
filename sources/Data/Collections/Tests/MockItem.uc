/**
 *  Mock object class for testing how collections deal with managed objects.
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
class MockItem extends AcediaObject;

var public int objectCount;

protected function Constructor()
{
    default.objectCount += 1;
}

protected function Finalizer()
{
    default.objectCount -= 1;
}

//  We don't want to differentiate between these objects
public function bool IsEqual(Object other)
{
    return true;
}

protected function int CalculateHashCode()
{
    return 0;
}

defaultproperties
{
    objectCount = 0
}