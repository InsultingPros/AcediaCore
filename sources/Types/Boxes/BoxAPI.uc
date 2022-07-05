/**
 *  Convenience API that provides methods for quickly creating
 *  box objects for native types.
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
class BoxAPI extends AcediaObject;

/**
 *  Creates initialized box that stores a `bool` value.
 *
 *  @param  value   Value to store in the box.
 *  @return `BoolBox`, containing `value`.
 */
public final function BoolBox Bool(optional bool value)
{
    local BoolBox box;
    box = BoolBox(_.memory.Allocate(class'BoolBox'));
    box.Initialize(value);
    return box;
}

/**
 *  Creates initialized box that stores an array of `bool` values.
 *  Initializes it with a given array.
 *
 *  @param  arrayValue  Initial array value to store in the box.
 *  @return `BoolArrayBox`, containing `arrayValue`.
 */
public final function BoolArrayBox BoolArray(array<bool> arrayValue)
{
    local BoolArrayBox box;
    box = BoolArrayBox(_.memory.Allocate(class'BoolArrayBox'));
    box.Initialize(arrayValue);
    return box;
}

/**
 *  Creates initialized box that stores a `byte` value.
 *
 *  @param  value   Value to store in the box.
 *  @return `ByteBox`, containing `value`.
 */
public final function ByteBox Byte(optional byte value)
{
    local ByteBox box;
    box = ByteBox(_.memory.Allocate(class'ByteBox'));
    box.Initialize(value);
    return box;
}

/**
 *  Creates initialized box that stores an array of `byte` values.
 *  Initializes it with a given array.
 *
 *  @param  arrayValue  Initial array value to store in the box.
 *  @return `ByteArrayBox`, containing `arrayValue`.
 */
public final function ByteArrayBox ByteArray(array<byte> arrayValue)
{
    local ByteArrayBox box;
    box = ByteArrayBox(_.memory.Allocate(class'ByteArrayBox'));
    box.Initialize(arrayValue);
    return box;
}

/**
 *  Creates initialized box that stores a `float` value.
 *
 *  @param  value   Value to store in the box.
 *  @return `FloatBox`, containing `value`.
 */
public final function FloatBox Float(optional float value)
{
    local FloatBox box;
    box = FloatBox(_.memory.Allocate(class'FloatBox'));
    box.Initialize(value);
    return box;
}

/**
 *  Creates initialized box that stores an array of `float` values.
 *  Initializes it with a given array.
 *
 *  @param  arrayValue  Initial array value to store in the box.
 *  @return `FloatArrayBox`, containing `arrayValue`.
 */
public final function FloatArrayBox FloatArray(array<float> arrayValue)
{
    local FloatArrayBox box;
    box = FloatArrayBox(_.memory.Allocate(class'FloatArrayBox'));
    box.Initialize(arrayValue);
    return box;
}

/**
 *  Creates initialized box that stores an `int` value.
 *
 *  @param  value   Value to store in the box.
 *  @return `IntBox`, containing `value`.
 */
public final function IntBox Int(optional int value)
{
    local IntBox box;
    box = IntBox(_.memory.Allocate(class'IntBox'));
    box.Initialize(value);
    return box;
}

/**
 *  Creates initialized box that stores an array of `int` values.
 *  Initializes it with a given array.
 *
 *  @param  arrayValue  Initial array value to store in the box.
 *  @return `IntArrayBox`, containing `arrayValue`.
 */
public final function IntArrayBox IntArray(array<int> arrayValue)
{
    local IntArrayBox box;
    box = IntArrayBox(_.memory.Allocate(class'IntArrayBox'));
    box.Initialize(arrayValue);
    return box;
}

/**
 *  Creates initialized box that stores an `Vector` value.
 *
 *  @param  value   Value to store in the box.
 *  @return `VectorBox`, containing `value`.
 */
public final function VectorBox Vec(optional Vector value)
{
    local VectorBox box;
    box = VectorBox(_.memory.Allocate(class'VectorBox'));
    box.Initialize(value);
    return box;
}

/**
 *  Creates initialized box that stores an array of `Vector` values.
 *  Initializes it with a given array.
 *
 *  @param  arrayValue  Initial array value to store in the box.
 *  @return `VectorArrayBox`, containing `arrayValue`.
 */
public final function VectorArrayBox VectorArray(array<Vector> arrayValue)
{
    local VectorArrayBox box;
    box = VectorArrayBox(_.memory.Allocate(class'VectorArrayBox'));
    box.Initialize(arrayValue);
    return box;
}

/**
 *  Creates initialized box that stores an `Vector` value.
 *
 *  @param  value   Value to store in the box.
 *  @return `VectorBox`, containing `value`.
 */
public final function AcediaType Class(optional class<Object> value)
{
    local AcediaType box;
    box = AcediaType(_.memory.Allocate(class'AcediaType'));
    box.Initialize(value);
    return box;
}

defaultproperties
{
}