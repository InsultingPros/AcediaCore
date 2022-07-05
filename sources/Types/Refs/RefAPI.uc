/**
 *  Convenience API that provides methods for quickly creating
 *  reference objects for native types.
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
class RefAPI extends AcediaObject;

/**
 *  Creates reference object to store a `bool` value.
 *
 *  @param  value   Initial value to store in reference.
 *  @return `BoolRef`, containing `value`.
 */
public final function BoolRef Bool(optional bool value)
{
    local BoolRef ref;
    ref = BoolRef(_.memory.Allocate(class'BoolRef'));
    ref.Set(value);
    return ref;
}

/**
 *  Creates reference object to store an array of `bool` values.
 *  Initializes it with a given array.
 *
 *  @param  arrayValue  Initial array value to store in reference.
 *  @return `BoolArrayRef`, containing `arrayValue`.
 */
public final function BoolArrayRef BoolArray(array<bool> arrayValue)
{
    local BoolArrayRef ref;
    ref = BoolArrayRef(_.memory.Allocate(class'BoolArrayRef'));
    ref.Set(arrayValue);
    return ref;
}

/**
 *  Creates reference object to store an array of `bool` values.
 *  Initializes it with an empty array.
 *
 *  @return `BoolArrayRef`, containing empty array.
 */
public final function BoolArrayRef EmptyBoolArray()
{
    return BoolArrayRef(_.memory.Allocate(class'BoolArrayRef'));
}

/**
 *  Creates reference object to store a `byte` value.
 *
 *  @param  value   Initial value to store in reference.
 *  @return `ByteRef`, containing `value`.
 */
public final function ByteRef Byte(optional byte value)
{
    local ByteRef ref;
    ref = ByteRef(_.memory.Allocate(class'ByteRef'));
    ref.Set(value);
    return ref;
}

/**
 *  Creates reference object to store an array of `byte` values.
 *  Initializes it with a given array.
 *
 *  @param  arrayValue  Initial array value to store in reference.
 *  @return `ByteArrayRef`, containing `arrayValue`.
 */
public final function ByteArrayRef ByteArray(array<byte> arrayValue)
{
    local ByteArrayRef ref;
    ref = ByteArrayRef(_.memory.Allocate(class'ByteArrayRef'));
    ref.Set(arrayValue);
    return ref;
}

/**
 *  Creates reference object to store an array of `byte` values.
 *  Initializes it with an empty array.
 *
 *  @return `ByteArrayRef`, containing empty array.
 */
public final function ByteArrayRef EmptyByteArray()
{
    return ByteArrayRef(_.memory.Allocate(class'ByteArrayRef'));
}

/**
 *  Creates reference object to store a `float` value.
 *
 *  @param  value   Initial value to store in reference.
 *  @return `FloatRef`, containing `value`.
 */
public final function FloatRef Float(optional float value)
{
    local FloatRef ref;
    ref = FloatRef(_.memory.Allocate(class'FloatRef'));
    ref.Set(value);
    return ref;
}

/**
 *  Creates reference object to store an array of `float` values.
 *  Initializes it with a given array.
 *
 *  @param  arrayValue  Initial array value to store in reference.
 *  @return `FloatArrayRef`, containing `arrayValue`.
 */
public final function FloatArrayRef FloatArray(array<float> arrayValue)
{
    local FloatArrayRef ref;
    ref = FloatArrayRef(_.memory.Allocate(class'FloatArrayRef'));
    ref.Set(arrayValue);
    return ref;
}

/**
 *  Creates reference object to store an array of `float` values.
 *  Initializes it with an empty array.
 *
 *  @return `FloatArrayRef`, containing empty array.
 */
public final function FloatArrayRef EmptyFloatArray()
{
    return FloatArrayRef(_.memory.Allocate(class'FloatArrayRef'));
}

/**
 *  Creates reference object to store an `int` value.
 *
 *  @param  value   Initial value to store in reference.
 *  @return `IntRef`, containing `value`.
 */
public final function IntRef Int(optional int value)
{
    local IntRef ref;
    ref = IntRef(_.memory.Allocate(class'IntRef'));
    ref.Set(value);
    return ref;
}

/**
 *  Creates reference object to store an array of `int` values.
 *  Initializes it with a given array.
 *
 *  @param  arrayValue  Initial array value to store in reference.
 *  @return `IntArrayRef`, containing `arrayValue`.
 */
public final function IntArrayRef IntArray(array<int> arrayValue)
{
    local IntArrayRef ref;
    ref = IntArrayRef(_.memory.Allocate(class'IntArrayRef'));
    ref.Set(arrayValue);
    return ref;
}

/**
 *  Creates reference object to store an `Vector` value.
 *
 *  @param  value   Initial value to store in reference.
 *  @return `VectorRef`, containing `value`.
 */
public final function VectorRef Vec(optional Vector value)
{
    local VectorRef ref;
    ref = VectorRef(_.memory.Allocate(class'VectorRef'));
    ref.Set(value);
    return ref;
}

/**
 *  Creates reference object to store an array of `Vector` values.
 *  Initializes it with a given array.
 *
 *  @param  arrayValue  Initial array value to store in reference.
 *  @return `VectorArrayRef`, containing `arrayValue`.
 */
public final function VectorArrayRef VectorArray(array<Vector> arrayValue)
{
    local VectorArrayRef ref;
    ref = VectorArrayRef(_.memory.Allocate(class'VectorArrayRef'));
    ref.Set(arrayValue);
    return ref;
}

/**
 *  Creates reference object to store an array of `int` values.
 *  Initializes it with an empty array.
 *
 *  @return `IntArrayRef`, containing empty array.
 */
public final function IntArrayRef EmptyIntArray()
{
    return IntArrayRef(_.memory.Allocate(class'IntArrayRef'));
}

/**
 *  Creates reference object to store an `Actor` value.
 *
 *  @param  value   Initial value to store in reference.
 *  @return `ActorRef`, containing `value`.
 */
public final function ActorRef Actor(optional AcediaActor value)
{
    local ActorRef ref;
    ref = ActorRef(_.memory.Allocate(class'ActorRef'));
    ref.Set(value);
    return ref;
}

defaultproperties
{
}