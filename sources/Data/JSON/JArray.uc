/**
 *      This class implements JSON array storage capabilities.
 *      Array stores ordered JSON values that can be referred by their index.
 *  It can contain any mix of JSON value types and cannot have any gaps,
 *  i.e. in array of length N, there must be a valid value for all indices
 *  from 0 to N-1. Values of the array can beL
 *      ~ Boolean, string, null or number (float in this implementation) data;
 *      ~ Other JSON Arrays;
 *      ~ Other JSON objects (see `JObject` class).
 *
 *      This implementation provides a variety of functionality,
 *  including parsing, displaying, getters and setters for JSON types that
 *  allow to freely set and fetch their values by index.
 *      JSON objects and arrays can be fetched by getters, but you cannot
 *  add existing object or array to another object. Instead one has to either
 *  clone existing object or create an empty one and then manually fill
 *  with data.
 *      This allows to avoid loop situations, where object is
 *  contained in itself.
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
class JArray extends JSON;

//  Data will be stored as an array of JSON values
var private array<JStorageAtom> data;

/**
 *  Returns type (`JType`) of a property with a index in our collection.
 *
 *  @param  index   Index of the JSON value to get the type of.
 *  @return Type of the property at the index `index`.
 *      `JSON_Undefined` iff element at that index does not exist.
 */
public final function JType GetTypeOf(int index)
{
    if (index < 0)              return JSON_Undefined;
    if (index >= data.length)   return JSON_Undefined;

    return data[index].type;
}

/**
 *  Returns current length of the caller array.
 *
 *  @return Length (amount of elements) in the caller array.
 *      Means that max index with recorded value is `GetLength() - 1`
 *      (min index is `0`).
 */
public final function int GetLength()
{
    return data.length;
}

/**
 *  Changes length of the caller `JArray`.
 *
 *      If length is decreased - variables that fit into new length will be
 *  preserved, others - erased.
 *      In case of the increase - sets values at new indices to "null".
 *
 *  @param  newLength   New length of the caller `JArray`.
 *      Negative values will be treated as zero.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function SetLength(int newLength)
{
    local int i;
    local int oldLength;
    newLength = Max(0, newLength);
    oldLength = data.length;
    data.length = newLength;
    if (oldLength >= newLength) {
        return;
    }
    i = oldLength;
    while (i < newLength)
    {
        SetNull(i);
        i += 1;
    }
}

/**
 *  Gets the value (as a `float`) at the index `index`, assuming it has
 *  `JSON_Number` type.
 *
 *      Forms a pair with `GetInteger()` method. JSON allows to specify
 *  arbitrary precision for the number variables, but UnrealScript can only
 *  store a limited range of numeric value.
 *      To alleviate this problem we store numeric JSON values as both
 *  `float` and `int` and can return either of the requested versions.
 *
 *  @param  index           Index of the value to get;
 *      must be between 0 and `GetLength() - 1` inclusively.
 *  @param  defaultValue    Value to return if element does not exist or
 *      has a different type (can be checked by `GetTypeOf()`).
 *  @return Number value of the element at the index `index`,
 *      if it exists and has `JSON_Number` type.
 *      Otherwise returns passed `defaultValue`.
 */
public final function float GetNumber(int index, optional float defaultValue)
{
    if (index < 0)                          return defaultValue;
    if (index >= data.length)               return defaultValue;
    if (data[index].type != JSON_Number)    return defaultValue;

    return data[index].numberValue;
}

/**
 *  Gets the value (as an `int`) at the index `index`, assuming it has
 *  `JSON_Number` type.
 *
 *      Forms a pair with `GetInteger()` method. JSON allows to specify
 *  arbitrary precision for the number variables, but UnrealScript can only
 *  store a limited range of numeric value.
 *      To alleviate this problem we store numeric JSON values as both
 *  `float` and `int` and can return either of the requested versions.
 *
 *  @param  index           Index of the value to get;
 *      must be between 0 and `GetLength() - 1` inclusively.
 *  @param  defaultValue    Value to return if element does not exist or
 *      has a different type (can be checked by `GetTypeOf()`).
 *  @return Number value of the element at the index `index`,
 *      if it exists and has `JSON_Number` type.
 *      Otherwise returns passed `defaultValue`.
 */
public final function float GetInteger(int index, optional float defaultValue)
{
    if (index < 0)                          return defaultValue;
    if (index >= data.length)               return defaultValue;
    if (data[index].type != JSON_Number)    return defaultValue;

    return data[index].numberValueAsInt;
}

/**
 *  Gets the value at the index `index`, assuming it has `JSON_String` type.
 *
 *  See also `GetClass()` method.
 *
 *  @param  index           Index of the value to get;
 *      must be between 0 and `GetLength() - 1` inclusively.
 *  @param  defaultValue    Value to return if element does not exist or
 *      has a different type (can be checked by `GetTypeOf()`).
 *  @return String value of the element at the index `index`,
 *      if it exists and has `JSON_String` type.
 *      Otherwise returns passed `defaultValue`.
 */
public final function string GetString(int index, optional string defaultValue)
{
    if (index < 0)                          return defaultValue;
    if (index >= data.length)               return defaultValue;
    if (data[index].type != JSON_String)    return defaultValue;

    return data[index].stringValue;
}

/**
 *  Gets the value at the index `index` as a `class`, assuming it has
 *  `JSON_String` type.
 *
 *  JSON does not support to store class data type, but we can use string type
 *  for that. This method attempts to load a class object from it's full name,
 *  (like `Engine.Actor`) recorded inside an appropriate string value.
 *
 *  @param  index           Index of the value to get;
 *      must be between 0 and `GetLength() - 1` inclusively.
 *  @param  defaultValue    Value to return if element does not exist,
 *      has a different type (can be checked by `GetTypeOf()`) or not
 *      a valid class name.
 *  @return Class value of the element at the index `index`,
 *      if it exists, has `JSON_String` type and it represents
 *      a full name of some class.
 *      Otherwise returns passed `defaultValue`.
 */
public final function class<Object> GetClass(
    int index,
    optional class<Object> defaultValue)
{
    if (index < 0)                          return defaultValue;
    if (index >= data.length)               return defaultValue;
    if (data[index].type != JSON_String)    return defaultValue;

    TryLoadingStringAsClass(data[index]);
    if (data[index].stringValueAsClass != none) {
        return data[index].stringValueAsClass;
    }
    return defaultValue;
}

/**
 *  Gets the value at the index `index`, assuming it has `JSON_Boolean` type.
 *
 *  See also `GetClass()` method.
 *
 *  @param  index           Index of the value to get;
 *      must be between 0 and `GetLength() - 1` inclusively.
 *  @param  defaultValue    Value to return if property does not exist or
 *      has a different type (can be checked by `GetTypeOf()`).
 *  @return String value of the element at the index `index`,
 *      if it exists and has `JSON_Boolean` type.
 *      Otherwise returns passed `defaultValue`.
 */
public final function bool GetBoolean(int index, optional bool defaultValue)
{
    if (index < 0)                          return defaultValue;
    if (index >= data.length)               return defaultValue;
    if (data[index].type != JSON_Boolean)   return defaultValue;

    return data[index].booleanValue;
}

/**
 *  Checks if an array element at the index `index` has `JSON_Null` type.
 *
 *  Alternatively consider using `GetType()` method.
 *
 *  @param  index   Index of the element to check for being `null`.
 *  @return `true` if element at the given index exists and
 *      has type `JSON_Null`; `false` otherwise.
 */
public final function bool IsNull(int index)
{
    if (index < 0)              return false;
    if (index >= data.length)   return false;

    return (data[index].type == JSON_Null);
}

/**
 *  Gets the value at the index `index`, assuming it has `JSON_Array` type.
 *
 *  @param  index   Index of the value to check for being "null";
 *      must be between 0 and `GetLength() - 1` inclusively.
 *  @return `JArray` object value at the given index, if it exists and
 *      has `JSON_Array` type.
 *      Otherwise returns `none`.
 */
public final function JArray GetArray(int index)
{
    if (index < 0)                      return none;
    if (index >= data.length)           return none;
    if (data[index].type != JSON_Array) return none;

    return JArray(data[index].complexValue);
}

/**
 *  Gets the value at the index `index`, assuming it has `JSON_Object` type.
 *
 *  @param  index   Index of the value to check for being "null";
 *      must be between 0 and `GetLength() - 1` inclusively.
 *  @return `JObject` object value at the given index, if it exists and
 *      has `JSON_Array` type.
 *      Otherwise returns `none`.
 */
public final function JObject GetObject(int index)
{
    if (index < 0)                          return none;
    if (index >= data.length)               return none;
    if (data[index].type != JSON_Object)    return none;

    return JObject(data[index].complexValue);
}

/**
 *  Sets the number value (as `float`) at the index `index`, erasing previous
 *  value (if it was recorded).
 *
 *      If negative index is given - does nothing.
 *      If given index is too large (`>= GetLength()`) then array will be
 *  extended, setting values at new indices (except specified `index`)
 *  to "null" value (`JSON_Null`).
 *
 *      Forms a pair with `SetInteger()` method.
 *      While JSON standard allows to store numbers with arbitrary precision,
 *  UnrealScript's types have a limited range.
 *      To alleviate this problem we store numbers in both `float`- and
 *  `int`-type variables to extended supported range of values.
 *  So if you need to store a number with fractional part, you should
 *  prefer `SetNumber()` and for integer values `SetInteger()` is preferable.
 *  Both will record a value of type `JSON_Number`.
 *
 *  @param  index   Index at which to set given numeric value.
 *  @param  value   Value to set at given index.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray SetNumber(int index, float value)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length) {
        SetLength(index + 1);
    }
    newStorageValue.type                = JSON_Number;
    newStorageValue.numberValue         = value;
    newStorageValue.numberValueAsInt    = int(value);
    newStorageValue.preferIntegerValue  = false;
    data[index] = newStorageValue;
    return self;
}

/**
 *  Sets the number value (as `int`) at the index `index`, erasing previous
 *  value (if it was recorded).
 *
 *      If negative index is given - does nothing.
 *      If given index is too large (`>= GetLength()`) then array will be
 *  extended, setting values at new indices (except specified `index`)
 *  to "null" value (`JSON_Null`).
 *
 *      Forms a pair with `SetNumber()` method.
 *      While JSON standard allows to store numbers with arbitrary precision,
 *  UnrealScript's types have a limited range.
 *      To alleviate this problem we store numbers in both `float`- and
 *  `int`-type variables to extended supported range of values.
 *  So if you need to store a number with fractional part, you should
 *  prefer `SetNumber()` and for integer values `SetInteger()` is preferable.
 *  Both will record a value of type `JSON_Number`.
 *
 *  @param  index   Index at which to set given numeric value.
 *  @param  value   Value to set at given index.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray SetInteger(int index, int value)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length) {
        SetLength(index + 1);
    }
    newStorageValue.type                = JSON_Number;
    newStorageValue.numberValue         = float(value);
    newStorageValue.numberValueAsInt    = value;
    newStorageValue.preferIntegerValue  = true;
    data[index] = newStorageValue;
    return self;
}

/**
 *  Sets the string value at the given index `index`, erasing previous value
 *  (if it was recorded).
 *
 *      If negative index is given - does nothing.
 *      If given index is too large (`>= GetLength()`) then array will be
 *  extended, setting values at new indices (except specified `index`)
 *  to "null" value (`JSON_Null`).
 *
 *  Also see `SetClass()` method.
 *
 *  @param  index   Index at which to set given string value.
 *  @param  value   Value to set at given index.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray SetString(int index, string value)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length) {
        SetLength(index + 1);
    }
    newStorageValue.type        = JSON_String;
    newStorageValue.stringValue = value;
    data[index] = newStorageValue;
    return self;
}

/**
 *  Sets the string value, corresponding to a given class `value`,
 *  at the index `index`, erasing previous value (if it was recorded).
 *
 *  Value in question will have `JSON_String` type.
 *
 *      If negative index is given - does nothing.
 *      If given index is too large (`>= GetLength()`) then array will be
 *  extended, setting values at new indices (except specified `index`)
 *  to "null" value (`JSON_Null`).
 *
 *      We want to allow storing `class` data in our JSON containers, but JSON
 *  standard does not support such a type, so we have to use string type
 *  to store `class`' name instead.
 *      Also see `GetClass()` method`.
 *
 *  @param  index   Index at which to set given value.
 *  @param  value   Value to set at given index.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray SetClass(int index, class<Object> value)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length) {
        SetLength(index + 1);
    }
    newStorageValue.type                = JSON_String;
    newStorageValue.stringValue         = string(value);
    newStorageValue.stringValueAsClass  = value;
    data[index] = newStorageValue;
    return self;
}

/**
 *  Sets the boolean value at the given index `index`, erasing previous value
 *  (if it was recorded).
 *
 *      If negative index is given - does nothing.
 *      If given index is too large (`>= GetLength()`) then array will be
 *  extended, setting values at new indices (except specified `index`)
 *  to "null" value (`JSON_Null`).
 *
 *  @param  index   Index at which to set given boolean value.
 *  @param  value   Value to set at given index.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray SetBoolean(int index, bool value)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length) {
        SetLength(index + 1);
    }
    newStorageValue.type            = JSON_Boolean;
    newStorageValue.booleanValue    = value;
    data[index] = newStorageValue;
    return self;
}

/**
 *  Sets the value at the given index `index` to be "null" (`JSON_Null`),
 *  erasing previous value (if it was recorded).
 *
 *      If negative index is given - does nothing.
 *      If given index is too large (`>= GetLength()`) then array will be
 *  extended, setting values at new indices (except specified `index`)
 *  to "null" value (`JSON_Null`).
 *
 *  @param  index   Index at which to set "null" value to.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray SetNull(int index)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length) {
        SetLength(index + 1);
    }
    newStorageValue.type = JSON_Null;
    data[index] = newStorageValue;
    return self;
}

/**
 *  Sets the value at the given index `index` to store `JArray` object
 *  (JSON array type).
 *
 *      If negative index is given - does nothing.
 *      If given index is too large (`>= GetLength()`) then array will be
 *  extended, setting values at new indices (except specified `index`)
 *  to "null" value (`JSON_Null`).
 *
 *      NOTE: This method DOES NOT make caller `JArray` store a
 *  given reference, instead it clones it (see `Clone()`) into a new copy and
 *  stores that. This is made this way to ensure you can not, say, store
 *  an object in itself or it's children.
 *      See also `CreateArray()` method.
 *
 *  @param  index       Index at which to set given array value.
 *  @param  template    Template `JArray` to clone.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray SetArray(int index, JArray template)
{
    local JStorageAtom newStorageValue;
    if (index < 0)          return self;
    if (template == none)   return self;

    if (index >= data.length) {
        SetLength(index + 1);
    }
    newStorageValue.type            = JSON_Array;
    newStorageValue.complexValue    = template.Clone();
    data[index] = newStorageValue;
    return self;
}

/**
 *  Sets the value at the given index `index` to store `JObject` object
 *  (JSON object type).
 *
 *      If negative index is given - does nothing.
 *      If given index is too large (`>= GetLength()`) then array will be
 *  extended, setting values at new indices (except specified `index`)
 *  to "null" value (`JSON_Null`).
 *
 *      NOTE: This method DOES NOT make caller `JArray` store a
 *  given reference, instead it clones it (see `Clone()`) into a new copy and
 *  stores that. This is made this way to ensure you can not, say, store
 *  an object in itself or it's children.
 *      See also `CreateObject()` method.
 *
 *  @param  index       Index at which to set given array value.
 *  @param  template    Template `JObject` to clone.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray SetObject(int index, JObject template)
{
    local JStorageAtom newStorageValue;
    if (index < 0)          return self;
    if (template == none)   return self;

    if (index >= data.length) {
        SetLength(index + 1);
    }
    newStorageValue.type            = JSON_Object;
    newStorageValue.complexValue    = template.Clone();
    data[index] = newStorageValue;
    return self;
}

/**
 *  Sets the value oat the given index `index` to store a new
 *  `JArray` object (JSON array type).
 *
 *  See also `SetArray()` method.
 *
 *      If negative index is given - does nothing.
 *      If given index is too large (`>= GetLength()`) then array will be
 *  extended, setting values at new indices (except specified `index`)
 *  to "null" value (`JSON_Null`).
 *
 *  @param  index   Index at which to create a new `JArray`.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray CreateArray(int index)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length) {
        SetLength(index + 1);
    }
    newStorageValue.type            = JSON_Array;
    newStorageValue.complexValue    = _.json.newArray();
    data[index] = newStorageValue;
    return self;
}

/**
 *  Sets the value oat the given index `index` to store a new
 *  `JObject` object (JSON object type).
 *
 *  See also `SetObject()` method.
 *
 *      If negative index is given - does nothing.
 *      If given index is too large (`>= GetLength()`) then array will be
 *  extended, setting values at new indices (except specified `index`)
 *  to "null" value (`JSON_Null`).
 *
 *  @param  index   Index at which to create a new `JObject`.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray CreateObject(int index)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length) {
        SetLength(index + 1);
    }
    newStorageValue.type            = JSON_Object;
    newStorageValue.complexValue    = _.json.newObject();
    data[index] = newStorageValue;
    return self;
}

/**
 *  Appends numeric value (as `float`) at the end of the caller `JArray`.
 *
 *      Forms a pair with `AddInteger()` method.
 *      While JSON standard allows to store numbers with arbitrary precision,
 *  UnrealScript's types have a limited range.
 *      To alleviate this problem we store numbers in both `float`- and
 *  `int`-type variables to extended supported range of values.
 *  So if you need to store a number with fractional part, you should
 *  prefer `AddNumber()` and for integer values `AddInteger()` is preferable.
 *  Both will record a value of type `JSON_Number`.
 *
 *  @param  value   Numeric value to append.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray AddNumber(float value)
{
    return SetNumber(data.length, value);
}

/**
 *  Appends numeric value (as `int`) at the end of the caller `JArray`.
 *
 *      Forms a pair with `AddNumber()` method.
 *      While JSON standard allows to store numbers with arbitrary precision,
 *  UnrealScript's types have a limited range.
 *      To alleviate this problem we store numbers in both `float`- and
 *  `int`-type variables to extended supported range of values.
 *  So if you need to store a number with fractional part, you should
 *  prefer `AddNumber()` and for integer values `AddInteger()` is preferable.
 *  Both will record a value of type `JSON_Number`.
 *
 *  @param  value   Numeric value to append.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray AddInteger(int value)
{
    return SetInteger(data.length, value);
}

/**
 *  Appends string value at the end of the caller `JArray`.
 *
 *  Also see `AddClass()` method.
 *
 *  @param  value   String value to append.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray AddString(string value)
{
    return SetString(data.length, value);
}

/**
 *  Appends string value, corresponding to a given class `value`, at the end of
 *  the caller `JArray`.
 *
 *  Value in question will have `JSON_String` type.
 *
 *      We want to allow storing `class` data in our JSON containers, but JSON
 *  standard does not support such a type, so we have to use string type
 *  to store `class`' name instead.
 *      Also see `GetClass()` method`.
 *
 *  @param  value   Class value to append.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray AddClass(class<Object> value)
{
    return SetClass(data.length, value);
}

/**
 *  Appends boolean value at the end of the caller `JArray`.
 *
 *  @param  value   Boolean value to append.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray AddBoolean(bool value)
{
    return SetBoolean(data.length, value);
}

/**
 *  Appends "null" value at the end of the caller `JArray`.
 *
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray AddNull()
{
    return SetNull(data.length);
}

/**
 *  Appends new empty `JArray` (JSON array type) at the end of
 *  the caller `JArray`.
 *
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray AddArray()
{
    return CreateArray(data.length);
}

/**
 *  Appends new empty `JObject` (JSON object type) at the end of
 *  the caller `JArray`.
 *
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JArray AddObject()
{
    return CreateObject(data.length);
}

//  Removes up to `amount` (minimum of `1`) of values, starting from
//  a given index.
//      If `index` falls outside array boundaries - nothing will be done.
//  Returns `true` if value was actually removed and `false` if it didn't exist.
/**
 *  Removes up to `amount` (minimum of `1`) of values, starting from
 *  a given index `index`.
 *
 *  If `index` falls outside array boundaries - nothing will be done.
 *
 *  @param  index   Index of first value to remove.
 *  @param  amount  Amount of values to remove.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function bool RemoveValue(int index, optional int amount)
{
    local int i;
    if (index < 0)              return false;
    if (index >= data.length)   return false;

    amount = Max(amount, 1);
    amount = Min(amount, data.length - index);
    for (i = index; i < index + amount; i += 1)
    {
        if (data[index].complexValue != none) {
            data[index].complexValue.Destroy();
        }
    }
    data.Remove(index, amount);
    return true;
}

/**
 *  Completely clears caller `JObject` of all values.
 */
public function Clear()
{
    RemoveValue(0, data.length);
}

/**
 *  Checks if caller JSON container's values form a subset of
 *  `rightJSON`'s values.
 *
 *  @return `true` if caller ("left") object is a subset of `rightJSON`
 *      and `false` otherwise.
 */
public function bool IsSubsetOf(JSON rightValue)
{
    local int                   i;
    local JArray                rightArray;
    local array<JStorageAtom>   rightAtomArray;
    rightArray = JArray(rightValue);
    if (rightArray == none)                     return false;
    if (data.length > rightArray.data.length)   return false;
    rightAtomArray = rightArray.data;
    for (i = 0; i < data.length; i += 1)
    {
        if (!AreAtomsEqual(data[i], rightAtomArray[i])) {
            return false;
        }
    }
    return true;
}

/**
 *  Makes an exact copy of the caller `JArray`
 *
 *  @return Copy of the caller `JArray`. Guaranteed to be `JArray`
 *      (or `none`, if appropriate object could not be created).
 */
public function JSON Clone()
{
    local int                   i;
    local JArray                clonedArray;
    local array<JStorageAtom>   clonedData;
    clonedArray = _.json.NewArray();
    if (clonedArray == none)
    {
        _.logger.Failure("Cannot clone `JArray`: cannot spawn a new instance.");
        return none;
    }
    clonedData = data;
    for (i = 0; i < clonedData.length; i += 1)
    {
        if (clonedData[i].complexValue == none) continue;
        if (    clonedData[i].type != JSON_Array
            &&  clonedData[i].type != JSON_Object) {
            continue;
        }
        clonedData[i].complexValue = clonedData[i].complexValue.Clone();
    }
    clonedArray.data = clonedData;
    return clonedArray;
}

/**
 *  Uses given parser to parse a new array of values (append them to the end of
 *  the caller array) inside the caller `JArray`.
 *
 *  Only adds new values if parsing the whole array was successful,
 *  otherwise even successfully parsed properties will be discarded.
 *
 *      `parser` must point at the text describing a JSON array in
 *  a valid notation. Then it parses that container inside memory, but
 *  instead of creating it as a separate entity, adds it's values to
 *  the caller `JArray`.
 *
 *      This method does not try to validate passed JSON and can accept invalid
 *  JSON by making some assumptions, but it is an undefined behavior and
 *  one should not expect it.
 *      Method is only guaranteed to work on valid JSON.
 *
 *  @param  parser  Parser that method would use to parse `JArray` from
 *      wherever it left. It's confirmed will not be changed, but if parsing
 *      was successful, - it will point at the next available character.
 *      Do not treat `parser` being in a non-failed state as a confirmation of
 *      successful parsing: JSON parsing might fail regardless.
 *      Check return value for that.
 *  @return `true` if parsing was successful and `false` otherwise.
 */
public function bool ParseIntoSelfWith(Parser parser)
{
    local bool                  parsingSucceeded;
    local Parser.ParserState    initState, confirmedState;
    local JStorageAtom          nextAtom;
    local array<JStorageAtom>   parsedAtoms;
    if (parser == none) return false;
    initState = parser.GetCurrentState();
    confirmedState = parser.Skip().Match("[").GetCurrentState();
    if (!parser.Ok())
    {
        parser.RestoreState(initState);
        return false;
    }
    while (parser.Ok() && !parser.HasFinished())
    {
        confirmedState = parser.Skip().GetCurrentState();
        if (parser.Match("]").Ok()) {
            parsingSucceeded = true;
            break;
        }
        if (    parsedAtoms.length > 0
            &&  !parser.RestoreState(confirmedState).Match(",").Skip().Ok()) {
            break;
        }
        else if (parser.Ok()) {
            confirmedState = parser.GetCurrentState();
        }
        nextAtom = ParseAtom(parser.RestoreState(confirmedState));
        if (nextAtom.type == JSON_Undefined) {
            break;
        }
        parsedAtoms[parsedAtoms.length] = nextAtom;
    }
    HandleParsedAtoms(parsedAtoms, parsingSucceeded);
    if (!parsingSucceeded) {
        parser.RestoreState(initState);
    }
    return parsingSucceeded;
}

//  Either cleans up or adds a list of parsed values,
//  depending on whether parsing was successful or not.
private function HandleParsedAtoms(
    array<JStorageAtom> parsedAtoms,
    bool                parsingSucceeded)
{
    local int i;
    if (parsingSucceeded)
    {
        for (i = 0; i < parsedAtoms.length; i += 1) {
            data[data.length] = parsedAtoms[i];
        }
        return;
    }
    for (i = 0; i < parsedAtoms.length; i += 1)
    {
        if (parsedAtoms[i].complexValue != none) {
            parsedAtoms[i].complexValue.Destroy();
        }
    }
}

/**
 *  Displays caller `JArray` with a provided preset.
 *
 *  See `Display()` for a simpler to use method.
 *
 *  @param  displaySettings   Struct that describes precisely how to display
 *      caller `JArray`. Can be used to emulate `Display()` call.
 *  @return String representation of caller JSON container in format defined by
 *      `displaySettings`.
 */
public function string DisplayWith(JSONDisplaySettings displaySettings)
{
    local int                   i;
    local bool                  isntFirstElement;
    local string                contents;
    local string                openingBraces, closingBraces;
    local string                elementsSeparator;
    local JSONDisplaySettings   innerSettings;
    if (displaySettings.stackIndentation) {
        innerSettings = IndentSettings(displaySettings, true);
    }
    else {
        innerSettings = displaySettings;
    }
    //      Prepare delimiters using appropriate indentation rules
    //      We only use inner settings for the part right after '[',
    //  as the rest is supposed to be aligned with outer objects
    openingBraces = displaySettings.beforeArrayOpening
        $ "[" $ innerSettings.afterArrayOpening;
    closingBraces = displaySettings.beforeArrayEnding
        $ "]" $ displaySettings.afterArrayEnding;
    elementsSeparator = "," $ innerSettings.afterArrayComma;
    if (innerSettings.colored) {
        elementsSeparator = "{$json_comma" $ elementsSeparator $ "}";
        openingBraces = "{$json_arrayBraces" $ openingBraces $ "}";
        closingBraces = "{$json_arrayBraces" $ closingBraces $ "}";
    }
    //  Display inner properties
    for (i = 0; i < data.length; i += 1)
    {
        if (isntFirstElement) {
            contents $= elementsSeparator;
        }
        contents $= DisplayAtom(data[i], innerSettings);
        isntFirstElement = true;
    }
    return openingBraces $ contents $ closingBraces;
}

defaultproperties
{
}