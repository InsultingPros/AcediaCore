/**
 *      This class implements JSON object storage capabilities.
 *  It stores name-value pairs, where names are strings and values can be:
 *      ~ Boolean, string, null or number (float in this implementation) data;
 *      ~ Other JSON objects;
 *      ~ JSON Arrays (see `JArray` class).
 *
 *      This implementation provides a variety of functionality,
 *  including parsing, displaying, getters and setters for JSON types that
 *  allow to freely set and fetch their values by name.
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
class JObject extends JSON;

//  We will store all our properties as a simple array of name-value pairs.
struct JProperty
{
    var string          name;
    var JStorageAtom    value;
};
//  Bucket of alias-value pairs, with the same alias hash.
struct PropertyBucket
{
    var array<JProperty> properties;
};
var private array<PropertyBucket>   hashTable;
var private int                     storedElementCount;

//  Reasonable lower and upper limits on hash table capacity,
//  that will be enforced if user requires something outside those bounds
var private config const int MINIMUM_CAPACITY;
var private config const int MAXIMUM_CAPACITY;
//      Minimum and maximum allowed density of elements
//  (`storedElementCount / hashTable.length`).
//      If density falls outside this range, - we have to resize hash table to
//  get into (MINIMUM_DENSITY; MAXIMUM_DENSITY) bounds,
//  as long as it does not violate other restrictions.
var private config const float MINIMUM_DENSITY;
var private config const float MAXIMUM_DENSITY;
//  Only ever reallocate hash table if new size will differ by
//  at least that much, regardless of other restrictions.
var private config const int MINIMUM_DIFFERENCE_FOR_REALLOCATION;
//  Never use any hash table capacity below this limit,
//  regardless of other variables
//  (like `MINIMUM_CAPACITY` or `MINIMUM_DENSITY`).
var private config const int ABSOLUTE_LOWER_CAPACITY_LIMIT;

//      Helper method that is needed as a replacement for `%`, since it is
//  an operation on `float`s in UnrealScript and does not have enough precision
//  to work with hashes.
//      Assumes positive input.
private function int Remainder(int number, int divisor)
{
    local int quotient;
    quotient = number / divisor;
    return (number - quotient * divisor);
}

//  Finds indices for:
//      1. Bucked that contains specified alias (`bucketIndex`);
//      2. Pair for specified alias in the bucket's collection
//          (`propertyIndex`).
//  `bucketIndex` is always found,
//  `propertyIndex` is valid iff method returns `true`, otherwise it's equal to
//  the index at which new property can get inserted.
private final function bool FindPropertyIndices(
    string  name,
    out int bucketIndex,
    out int propertyIndex)
{
    local int               i;
    local array<JProperty>  bucketProperties;
    TouchHashTable();
    bucketIndex = _.text.GetHash(name);
    if (bucketIndex < 0) {
        bucketIndex *= -1;
    }
    bucketIndex = Remainder(bucketIndex, hashTable.length);
    //  Check if bucket actually has given name.
    bucketProperties = hashTable[bucketIndex].properties;
    for (i = 0; i < bucketProperties.length; i += 1)
    {
        if (bucketProperties[i].name == name)
        {
            propertyIndex = i;
            return true;
        }
    }
    propertyIndex = bucketProperties.length;
    return false;
}

//  Creates hash table in case it does not exist yet
private final function TouchHashTable()
{
    if (hashTable.length <= 0) {
        UpdateHashTableCapacity();
    }
}

//  Attempts to find a property in a caller `JObject` by the name `name` and
//  writes it into `result`. Returns `true` if it succeeds and `false` otherwise
//  (in that case writes a blank property with a given name in `result`).
private final function bool FindProperty(string name, out JProperty result)
{
    local JProperty newProperty;
    local int       bucketIndex, propertyIndex;
    if (FindPropertyIndices(name, bucketIndex, propertyIndex))
    {
        result = hashTable[bucketIndex].properties[propertyIndex];
        return true;
    }
    newProperty.name = name;
    result = newProperty;
    return false;
}

//  Creates/replaces a property with a name `newProperty.name` in caller
//  JSON object
private final function UpdateProperty(JProperty newProperty)
{
    local bool  overriddenProperty;
    local int   bucketIndex, propertyIndex;
    overriddenProperty = !FindPropertyIndices(  newProperty.name,
                                                bucketIndex, propertyIndex);
    hashTable[bucketIndex].properties[propertyIndex] = newProperty;
    if (overriddenProperty) {
        storedElementCount += 1;
        UpdateHashTableCapacity();
    }
}

//  Removes a property with a name `newProperty.name` from caller JSON object
//  Returns `true` if something was actually removed.
private final function bool RemoveProperty(string propertyName)
{
    local JProperty propertyToRemove;
    local int       bucketIndex, propertyIndex;
    //  Ensure has table was initialized before any updates
    if (hashTable.length <= 0) {
        UpdateHashTableCapacity();
    }
    if (FindPropertyIndices(propertyName, bucketIndex, propertyIndex)) {
        propertyToRemove = hashTable[bucketIndex].properties[propertyIndex];
        if (propertyToRemove.value.complexValue != none) {
            propertyToRemove.value.complexValue.Destroy();
        }
        hashTable[bucketIndex].properties.Remove(propertyIndex, 1);
        storedElementCount = Max(0, storedElementCount - 1);
        UpdateHashTableCapacity();
        return true;
    }
    return false;
}

//  Checks if we need to change our current capacity and does so if needed
private final function UpdateHashTableCapacity()
{
    local int oldCapacity, newCapacity;
    oldCapacity = hashTable.length;
    //  Calculate new capacity (and whether it is needed) based on amount of
    //  stored properties and current capacity
    newCapacity = oldCapacity;
    if (storedElementCount < newCapacity * MINIMUM_DENSITY) {
        newCapacity /= 2;
    }
    if (storedElementCount > newCapacity * MAXIMUM_DENSITY) {
        newCapacity *= 2;
    }
    //  Enforce our limits
    newCapacity = Clamp(newCapacity, MINIMUM_CAPACITY, MAXIMUM_CAPACITY);
    newCapacity = Max(ABSOLUTE_LOWER_CAPACITY_LIMIT, newCapacity);
    //  Only resize if difference is huge enough or table does not exists yet
    if (    newCapacity - oldCapacity > MINIMUM_DIFFERENCE_FOR_REALLOCATION
        ||  oldCapacity - newCapacity > MINIMUM_DIFFERENCE_FOR_REALLOCATION
        ||  oldCapacity <= 0) {
        ResizeHashTable(newCapacity);
    }
}

//      Change size of the hash table, does not check any limits, does not check
//  if `newCapacity` is a valid capacity (`newCapacity > 0`).
//      Use `UpdateHashTableCapacity()` for that.
private final function ResizeHashTable(int newCapacity)
{
    local int                   i, j;
    local array<JProperty>      bucketProperties;
    local array<PropertyBucket> oldHashTable;
    oldHashTable = hashTable;
    //  Clean current hash table
    hashTable.length = 0;
    hashTable.length = newCapacity;
    for (i = 0; i < oldHashTable.length; i += 1)
    {
        bucketProperties = oldHashTable[i].properties;
        for (j = 0; j < bucketProperties.length; j += 1) {
            UpdateProperty(bucketProperties[j]);
        }
    }
}

/**
 *  Returns `JType` of a property with a given name in our collection.
 *
 *  This function can be used to check if certain variable exists
 *  in this object, since if such variable does not exist -
 *  function will return `JSON_Undefined`.
 *
 *  @param  name    Name of the property to get the type of.
 *  @return Type of the property by the name `name`.
 *      `JSON_Undefined` iff property with that name does not exist.
 */
public final function JType GetTypeOf(string name)
{
    local JProperty property;
    FindProperty(name, property);
    //  If we did not find anything - `property` will be set up as
    //  a `JSON_Undefined` type value.
    return property.value.type;
}

/**
 *  Gets the value (as a `float`) of a property by the name `name`,
 *  assuming it has `JSON_Number` type.
 *
 *      Forms a pair with `GetInteger()` method. JSON allows to specify
 *  arbitrary precision for the number variables, but UnrealScript can only
 *  store a limited range of numeric value.
 *      To alleviate this problem we store numeric JSON values as both
 *  `float` and `int` and can return either of the requested versions.
 *
 *  @param  name            Name of the property to return a value of.
 *  @param  defaultValue    Value to return if property does not exist or
 *      has a different type (can be checked by `GetTypeOf()`).
 *  @return Number value of the property under name `name`,
 *      if it exists and has `JSON_Number` type.
 *      Otherwise returns passed `defaultValue`.
 */
public final function float GetNumber(string name, optional float defaultValue)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.type != JSON_Number) {
        return defaultValue;
    }
    return property.value.numberValue;
}

/**
 *  Gets the value (as an `int`) of a property by the name `name`,
 *  assuming it has `JSON_Number` type.
 *
 *      Forms a pair with `GetNumber()` method. JSON allows to specify
 *  arbitrary precision for the number variables, but UnrealScript can only
 *  store a limited range of numeric value.
 *      To alleviate this problem we store numeric JSON values as both
 *  `float` and `int` and can return either of the requested versions.
 *
 *  @param  name            Name of the property to return a value of.
 *  @param  defaultValue    Value to return if property does not exist or
 *      has a different type (can be checked by `GetTypeOf()`).
 *  @return Number value of the property under name `name`,
 *      if it exists and has `JSON_Number` type.
 *      Otherwise returns passed `defaultValue`.
 */
public final function int GetInteger(string name, optional int defaultValue)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.type != JSON_Number) {
        return defaultValue;
    }
    return property.value.numberValueAsInt;
}

/**
 *  Gets the value of a property by the name `name`,
 *  assuming it has `JSON_String` type.
 *
 *  See also `GetClass()` method.
 *
 *  @param  name            Name of the property to return a value of.
 *  @param  defaultValue    Value to return if property does not exist or
 *      has a different type (can be checked by `GetTypeOf()`).
 *  @return String value of the property under name `name`,
 *      if it exists and has `JSON_String` type.
 *      Otherwise returns passed `defaultValue`.
 */
public final function string GetString(
    string          name,
    optional string defaultValue
)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.type != JSON_String) {
        return defaultValue;
    }
    return property.value.stringValue;
}

/**
 *  Gets the value of a property by the name `name` as a `class`,
 *  assuming it has `JSON_String` type.
 *
 *  JSON does not support to store class data type, but we can use string type
 *  for that. This method attempts to load a class object from it's full name,
 *  (like `Engine.Actor`) recorded inside an appropriate string value.
 *
 *  @param  name            Name of the property to return a value of.
 *  @param  defaultValue    Value to return if property does not exist,
 *      has a different type (can be checked by `GetTypeOf()`) or not
 *      a valid class name.
 *  @return Class value of the property under name `name`,
 *      if it exists, has `JSON_String` type and it represents
 *      a full name of some class.
 *      Otherwise returns passed `defaultValue`.
 */
public final function class<Object> GetClass(
    string                  name,
    optional class<Object>  defaultValue
)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.type != JSON_String) {
        return defaultValue;
    }
    TryLoadingStringAsClass(property.value);
    if (property.value.stringValueAsClass != none) {
        return property.value.stringValueAsClass;
    }
    return defaultValue;
}

/**
 *  Gets the value of a property by the name `name`,
 *  assuming it has `JSON_Boolean` type.
 *
 *  @param  name            Name of the property to return a value of.
 *  @param  defaultValue    Value to return if property does not exist or
 *      has a different type (can be checked by `GetTypeOf()`).
 *  @return Boolean value of the property under name `name`,
 *      if it exists and has `JSON_Boolean` type.
 *      Otherwise returns passed `defaultValue`.
 */
public final function bool GetBoolean(string name, optional bool defaultValue)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.type != JSON_Boolean) {
        return defaultValue;
    }
    return property.value.booleanValue;
}

/**
 *  Checks if a property by the name `name` has `JSON_Null` type.
 *
 *  Alternatively consider using `GetType()` method.
 *
 *  @param  name    Name of the property to check for being `null`.
 *  @return `true` if property under given name `name` exists and
 *      has type `JSON_Null`; `false` otherwise.
 */
public final function bool IsNull(string name)
{
    local JProperty property;
    FindProperty(name, property);
    return (property.value.type == JSON_Null);
}

/**
 *  Gets the value of a property by the name `name`,
 *  assuming it has `JSON_Array` type.
 *
 *  @param  name            Name of the property to return a value of.
 *  @return `JArray` object value of the property under name `name`,
 *      if it exists and has `JSON_Array` type.
 *      Otherwise returns `none`.
 */
public final function JArray GetArray(string name)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.type != JSON_Array) {
        return none;
    }
    return JArray(property.value.complexValue);
}

/**
 *  Gets the value of a property by the name `name`,
 *  assuming it has `JSON_Object` type.
 *
 *  @param  name            Name of the property to return a value of.
 *  @return `JObject` object value of the property under name `name`,
 *      if it exists and has `JSON_Object` type.
 *      Otherwise returns `none`.
 */
public final function JObject GetObject(string name)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.type != JSON_Object) return none;
    return JObject(property.value.complexValue);
}

/**
 *  Sets the number value (as `float`) of a property by the name `name`,
 *  erasing previous value (if it was recorded).
 *
 *  Property in question will have `JSON_Number` type.
 *
 *      Forms a pair with `SetInteger()` method.
 *      While JSON standard allows to store numbers with arbitrary precision,
 *  UnrealScript's types have a limited range.
 *      To alleviate this problem we store numbers in both `float`- and
 *  `int`-type variables to extended supported range of values.
 *  So if you need to store a number with fractional part, you should
 *  prefer `SetNumber()` and for integer values `SetInteger()` is preferable.
 *  Both will create a property of type `JSON_Number`.
 *
 *  @param  name    Name of the property to set a value of.
 *  @param  value   Value to set to a property under a given name `name`.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JObject SetNumber(string name, float value)
{
    local JProperty property;
    FindProperty(name, property);
    property.value.type                 = JSON_Number;
    property.value.numberValue          = value;
    property.value.numberValueAsInt     = int(value);
    property.value.complexValue         = none;
    property.value.preferIntegerValue   = false;
    UpdateProperty(property);
    return self;
}

/**
 *  Sets the number value (as `int`) of a property by the name `name`,
 *  erasing previous value (if it was recorded).
 *
 *  Property in question will have `JSON_Number` type.
 *
 *      Forms a pair with `SetNumber()` method.
 *      While JSON standard allows to store numbers with arbitrary precision,
 *  UnrealScript's types have a limited range.
 *      To alleviate this problem we store numbers in both `float`- and
 *  `int`-type variables to extended supported range of values.
 *  So if you need to store a number with fractional part, you should
 *  prefer `SetNumber()` and for integer values `SetInteger()` is preferable.
 *  Both will create a property of type `JSON_Number`.
 *
 *  @param  name    Name of the property to set a value of.
 *  @param  value   Value to set to a property under a given name `name`.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JObject SetInteger(string name, int value)
{
    local JProperty property;
    FindProperty(name, property);
    property.value.type                 = JSON_Number;
    property.value.numberValue          = float(value);
    property.value.numberValueAsInt     = value;
    property.value.complexValue         = none;
    property.value.preferIntegerValue   = true;
    UpdateProperty(property);
    return self;
}

/**
 *  Sets the string value of a property by the name `name`,
 *  erasing previous value (if it was recorded).
 *
 *  Property in question will have `JSON_String` type.
 *
 *  Also see `SetClass()` method.
 *
 *  @param  name    Name of the property to set a value of.
 *  @param  value   Value to set to a property under a given name `name`.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JObject SetString(string name, string value)
{
    local JProperty property;
    FindProperty(name, property);
    property.value.type                     = JSON_String;
    property.value.stringValue              = value;
    property.value.stringValueAsClass       = none;
    property.value.classLoadingWasAttempted = false;
    property.value.complexValue             = none;
    UpdateProperty(property);
    return self;
}

/**
 *  Sets the string value, corresponding to a given class `value`,
 *  of a property by the name `name`, erasing previous value
 *  (if it was recorded).
 *
 *  Property in question will have `JSON_String` type.
 *
 *      We want to allow storing `class` data in our JSON containers, but JSON
 *  standard does not support such a type, so we have to use string type
 *  to store `class`' name instead.
 *      Also see `GetClass()` method`.
 *
 *  @param  name    Name of the property to set a value of.
 *  @param  value   Value to set to a property under a given name `name`.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JObject SetClass(string name, class<Object> value)
{
    local JProperty property;
    FindProperty(name, property);
    property.value.type                     = JSON_String;
    property.value.stringValue              = string(value);
    property.value.stringValueAsClass       = value;
    property.value.classLoadingWasAttempted = true;
    property.value.complexValue             = none;
    UpdateProperty(property);
    return self;
}

/**
 *  Sets the boolean value of a property by the name `name`,
 *  erasing previous value (if it was recorded).
 *
 *  Property in question will have `JSON_Boolean` type.
 *
 *  @param  name    Name of the property to set a value of.
 *  @param  value   Value to set to a property under a given name `name`.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JObject SetBoolean(string name, bool value)
{
    local JProperty property;
    FindProperty(name, property);
    property.value.type         = JSON_Boolean;
    property.value.booleanValue = value;
    property.value.complexValue = none;
    UpdateProperty(property);
    return self;
}

/**
 *  Sets the value of a property by the name `name` to be "null" (`JSON_Null`),
 *  erasing previous value (if it was recorded).
 *
 *  Property in question will have `JSON_Null` type.
 *
 *  @param  name    Name of the property to set a "null" value to.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JObject SetNull(string name)
{
    local JProperty property;
    FindProperty(name, property);
    property.value.type         = JSON_Null;
    property.value.complexValue = none;
    UpdateProperty(property);
    return self;
}

/**
 *  Sets the value of a property by the name `name` to store `JArray` object
 *  (JSON array type).
 *
 *      NOTE: This method DOES NOT make caller `JObject` store a
 *  given reference, instead it clones it (see `Clone()`) into a new copy and
 *  stores that. This is made this way to ensure you can not, say, store
 *  an object in itself or it's children.
 *      See also `CreateArray()` method.
 *
 *  @param  name        Name of the property to return a value of.
 *  @param  template    Template `JArray` to clone into property.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JObject SetArray(string name, JArray template)
{
    local JProperty property;
    if (template == none) return self;
    FindProperty(name, property);
    if (property.value.complexValue != none) {
        property.value.complexValue.Destroy();
    }
    property.value.type         = JSON_Array;
    property.value.complexValue = template.Clone();
    UpdateProperty(property);
    return self;
}

/**
 *  Sets the value of a property by the name `name` to store `JObject` object
 *  (JSON object type).
 *
 *      NOTE: This method DOES NOT make caller `JObject` store a
 *  given reference, instead it clones it (see `Clone()`) into a new copy and
 *  stores that. This is made this way to ensure you can not, say, store
 *  an object in itself or it's children.
 *      See also `CreateArray()` method.
 *
 *  @param  name        Name of the property to return a value of.
 *  @param  template    Template `JObject` to clone into property.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JObject SetObject(string name, JObject template)
{
    local JProperty property;
    if (template == none) return self;
    FindProperty(name, property);
    if (property.value.complexValue != none) {
        property.value.complexValue.Destroy();
    }
    property.value.type = JSON_Object;
    property.value.complexValue = template.Clone();
    UpdateProperty(property);
    return self;
}

/**
 *  Sets the value of a property by the name `name` to store a new
 *  `JArray` object (JSON array type).
 *
 *  See also `SetArray()` method.
 *
 *  @param  name    Name of the property to store the new `JArray` value.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JObject CreateArray(string name)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.complexValue != none) {
        property.value.complexValue.Destroy();
    }
    property.value.type         = JSON_Array;
    property.value.complexValue = _.json.NewArray();
    UpdateProperty(property);
    return self;
}

/**
 *  Sets the value of a property by the name `name` to store a new
 *  `JObject` object (JSON array type).
 *
 *  See also `SetArray()` method.
 *
 *  @param  name    Name of the property to store the new `JObject` value.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JObject CreateObject(string name)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.complexValue != none) {
        property.value.complexValue.Destroy();
    }
    property.value.type         = JSON_Object;
    property.value.complexValue = _.json.NewObject();
    UpdateProperty(property);
    return self;
}

/**
 *  Removes a property with a given name.
 *
 *  Does nothing if property with a given name does not exist.
 *
 *  @param  name    Name of the property to remove.
 *  @return Reference to the caller object, to allow for function chaining.
 */
public final function JObject RemoveValue(string name)
{
    RemoveProperty(name);
    return self;
}

/**
 *  Completely clears caller `JObject` of all stored properties.
 */
public function Clear()
{
    local int               i, j;
    local array<JProperty>  nextProperties;
    for (i = 0; i < hashTable.length; i += 1)
    {
        nextProperties = hashTable[i].properties;
        for (j = 0; j < nextProperties.length; j += 1)
        {
            if (nextProperties[j].value.complexValue == none) continue;
            nextProperties[j].value.complexValue.Destroy();
        }
    }
}

/**
 *  Returns names of all properties inside caller `JObject`.
 *
 *  @return Array of all the caller object's property names as `string`s.
 */
public final function array<string> GetPropertyNames()
{
    local int               i, j;
    local array<string>     result;
    local array<JProperty>  nextProperties;
    for (i = 0; i < hashTable.length; i += 1)
    {
        nextProperties = hashTable[i].properties;
        for (j = 0; j < nextProperties.length; j += 1) {
            result[result.length] = nextProperties[j].name;
        }
    }
    return result;
}

/**
 *  Checks if caller JSON container's values form a subset of
 *  `rightJSON`'s values.
 *
 *  @return `true` if caller ("left") object is a subset of `rightJSON`
 *      and `false` otherwise.
 */
public function bool IsSubsetOf(JSON rightJSON)
{
    local int               i, j;
    local JObject           rightObject;
    local JProperty         rightProperty;
    local array<JProperty>  nextProperties;
    rightObject = JObject(rightJSON);
    if (rightObject == none) return false;
    for (i = 0; i < hashTable.length; i += 1)
    {
        nextProperties = hashTable[i].properties;
        for (j = 0; j < nextProperties.length; j += 1) {
            rightObject.FindProperty(nextProperties[j].name, rightProperty);
            if (rightProperty.value.type == JSON_Undefined) {
                return false;
            }
            if (!AreAtomsEqual(nextProperties[j].value, rightProperty.value)) {
                return false;
            }
        }
    }
    return true;
}

/**
 *  Makes an exact copy of the caller `JObject`
 *
 *  @return Copy of the caller `JObject`. Guaranteed to be `JObject`
 *      (or `none`, if appropriate object could not be created).
 */
public function JSON Clone()
{
    local int                   i, j;
    local JObject               clonedObject;
    local array<PropertyBucket> clonedHashTable;
    local array<JProperty>      nextProperties;
    clonedObject = _.json.NewObject();
    if (clonedObject == none)
    {
        _.logger.Failure("Cannot clone `JObject`: cannot spawn a"
            @ "new instance.");
        return none;
    }
    clonedHashTable = hashTable;
    for (i = 0; i < clonedHashTable.length; i += 1)
    {
        nextProperties = clonedHashTable[i].properties;
        for (j = 0; j < nextProperties.length; j += 1)
        {
            if (nextProperties[j].value.complexValue == none) continue;
            if (    nextProperties[j].value.type != JSON_Array
                &&  nextProperties[j].value.type != JSON_Object) {
                continue;
            }
            nextProperties[j].value.complexValue =
                nextProperties[j].value.complexValue.Clone();
        }
        clonedHashTable[i].properties = nextProperties;
    }
    clonedObject.hashTable = clonedHashTable;
    return clonedObject;
}

/**
 *  Uses given parser to parse a new set of properties inside
 *  the caller `JObject`.
 *
 *  Only adds new properties if parsing the whole object was successful,
 *  otherwise even successfully parsed properties will be discarded.
 *
 *      `parser` must point at the text describing a JSON object in
 *  a valid notation. Then it parses that container inside memory, but
 *  instead of creating it as a separate entity, adds it's values to
 *  the caller container.
 *      Everything that comes after parsed `JObject` is discarded.
 *
 *      This method does not try to validate passed JSON and can accept invalid
 *  JSON by making some assumptions, but it is an undefined behavior and
 *  one should not expect it.
 *      Method is only guaranteed to work on valid JSON.
 *
 *  @param  parser  Parser that method would use to parse `JObject` from
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
    local JProperty             nextProperty;
    local array<JProperty>      parsedProperties;
    if (parser == none) return false;
    initState = parser.GetCurrentState();
    //  Ensure that parser starts pointing at what looks like a JSON object
    confirmedState = parser.Skip().Match("{").GetCurrentState();
    if (!parser.Ok())
    {
        parser.RestoreState(initState);
        return false;
    }
    while (parser.Ok() && !parser.HasFinished())
    {
        confirmedState = parser.Skip().GetCurrentState();
        //  Check for JSON object ending and ONLY THEN declare parsing
        //  is successful, not encountering '}' implies bad JSON format.
        if (parser.Match("}").Ok())
        {
            parsingSucceeded = true;
            break;
        }
        if (    parsedProperties.length > 0
            &&  !parser.RestoreState(confirmedState).Match(",").Skip().Ok()) {
            break;
        }
        //  Recover after failed `Match("}")` on the first cycle
        //  (`parsedProperties.length == 0`)
        else if (parser.Ok()) {
            confirmedState = parser.GetCurrentState();
        }
        //  Parse property
        parser.RestoreState(confirmedState).Skip();
        parser.MStringLiteral(nextProperty.name).Skip().Match(":");
        nextProperty.value = ParseAtom(parser.Skip());
        if (!parser.Ok() || nextProperty.value.type == JSON_Undefined) {
            break;
        }
        parsedProperties[parsedProperties.length] = nextProperty;
    }
    HandleParsedProperties(parsedProperties, parsingSucceeded);
    if (!parsingSucceeded) {
        parser.RestoreState(initState);
    }
    return parsingSucceeded;
}

//  Either cleans up or adds a list of parsed properties,
//  depending on whether parsing was successful or not.
private function HandleParsedProperties(
    array<JProperty>    parsedProperties,
    bool                parsingSucceeded)
{
    local int i;
    if (parsingSucceeded)
    {
        for (i = 0; i < parsedProperties.length; i += 1) {
            UpdateProperty(parsedProperties[i]);
        }
        return;
    }
    for (i = 0; i < parsedProperties.length; i += 1)
    {
        if (parsedProperties[i].value.complexValue != none) {
            parsedProperties[i].value.complexValue.Destroy();
        }
    }
}

/**
 *  Displays caller `JObject` with a provided preset.
 *
 *  See `Display()` for a simpler to use method.
 *
 *  @param  displaySettings   Struct that describes precisely how to display
 *      caller `JObject`. Can be used to emulate `Display()` call.
 *  @return String representation of caller JSON container in format defined by
 *      `displaySettings`.
 */
public function string DisplayWith(JSONDisplaySettings displaySettings)
{
    local int                   i, j;
    local bool                  isntFirstProperty;
    local string                contents;
    local string                openingBraces, closingBraces;
    local string                propertiesSeparator;
    local array<JProperty>      nextProperties;
    local JSONDisplaySettings   innerSettings;
    if (displaySettings.stackIndentation) {
        innerSettings = IndentSettings(displaySettings);
    }
    else {
        innerSettings = displaySettings;
    }
    GetBraces(openingBraces, closingBraces, displaySettings, innerSettings);
    propertiesSeparator = "," $ innerSettings.afterObjectComma;
    if (innerSettings.colored) {
        propertiesSeparator = "{$json_comma" @ propertiesSeparator $ "}";
        openingBraces = "{$json_objectBraces &" $ openingBraces $ "}";
        closingBraces = "{$json_objectBraces &" $ closingBraces $ "}";
    }
    //  Display inner properties
    for (i = 0; i < hashTable.length; i += 1)
    {
        nextProperties = hashTable[i].properties;
        for (j = 0; j < nextProperties.length; j += 1)
        {
            if (isntFirstProperty) {
                contents $= propertiesSeparator;
            }
            contents $= DisplayProperty(nextProperties[j], innerSettings);
            isntFirstProperty = true;
        }
    }
    return openingBraces $ contents $ closingBraces;
}

/**
 *  Helper function that generates `string`s to be used for opening and
 *  closing braces for text representation of the caller `JObject`.
 *
 *  Cannot fail.
 *
 *  @param  openingBraces   `string` for opening braces will be recorded here.
 *  @param  closingBraces   `string` for closing braces will be recorded here.
 *  @param  outerSettings   Settings that were passed to tell us how to display
 *      a caller object.
 *  @param  innerSettings   Settings that were generated from `outerSettings` by
 *      indenting them (`IndentSettings()`) to use to display it's
 *      inner properties.
 */
protected function GetBraces(
    out string          openingBraces,
    out string          closingBraces,
    JSONDisplaySettings outerSettings,
    JSONDisplaySettings innerSettings)
{
    openingBraces = "{";
    closingBraces = "}";
    if (innerSettings.colored) {
        openingBraces = "&" $ openingBraces;
        closingBraces = "&" $ closingBraces;
    }
    //      We only use inner settings for the part right after '{',
    //  as the rest is supposed to be aligned with outer objects
    openingBraces = outerSettings.beforeObjectOpening
        $ openingBraces $ innerSettings.afterObjectOpening;
    closingBraces = outerSettings.beforeObjectEnding
        $ closingBraces $ outerSettings.afterObjectEnding;
}

/**
 *  Helper method to convert a JSON object's property into it's
 *  text representation.
 *
 *  @param  toDisplay       Property to display as a `string`.
 *  @param  displaySettings Settings that tells us how to display it.
 *  @return `string` representation of a given property `toDisplay`,
 *      created according to the settings `displaySettings`.
 */
protected function string DisplayProperty(
    JProperty           toDisplay,
    JSONDisplaySettings displaySettings)
{
    local string result;
    result = displaySettings.beforePropertyName
        $ DisplayJSONString(toDisplay.name)
        $ displaySettings.afterPropertyName;
    if (displaySettings.colored) {
        result = "{$json_propertyName" @ result $ "}{$json_colon :}";
    }
    else {
        result $= ":";
    }
    return (result $ displaySettings.beforePropertyValue
        $ DisplayAtom(toDisplay.value, displaySettings)
        $ displaySettings.afterPropertyValue);
}

defaultproperties
{
    ABSOLUTE_LOWER_CAPACITY_LIMIT       = 10
    MINIMUM_CAPACITY                    = 50
    MAXIMUM_CAPACITY                    = 100000
    MINIMUM_DENSITY                     = 0.25
    MAXIMUM_DENSITY                     = 0.75
    MINIMUM_DIFFERENCE_FOR_REALLOCATION = 50
}