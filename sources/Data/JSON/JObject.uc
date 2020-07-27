/**
 *      This class implements JSON object storage capabilities.
 *      Whenever one wants to store JSON data, they need to define such object.
 *  It stores name-value pairs, where names are strings and values can be:
 *      ~ Boolean, string, null or number (float in this implementation) data;
 *      ~ Other JSON objects;
 *      ~ JSON Arrays (see `JArray` class).
 *
 *      This implementation provides getters and setters for boolean, string,
 *  null or number types that allow to freely set and fetch their values
 *  by name.
 *      JSON objects and arrays can be fetched by getters, but you cannot
 *  add existing object or array to another object. Instead one has to create
 *  a new, empty object with a certain name and then fill it with data.
 *  This allows to avoid loop situations, where object is contained in itself.
 *      Functions to remove existing values are also provided and are applicable
 *  to all variable types.
 *      Setters can also be used to overwrite any value by a different value,
 *  even of a different type.
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
var private config const float MINIMUM_DENSITY;
var private config const float MAXIMUM_DENSITY;
var private config const int MINIMUM_DIFFERENCE_FOR_REALLOCATION;
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

//      Returns `JType` of a variable with a given name in our properties.
//      This function can be used to check if certain variable exists
//  in this object, since if such variable does not exist -
//  function will return `JSON_Undefined`.
public final function JType GetTypeOf(string name)
{
    local JProperty property;
    FindProperty(name, property);
    //  If we did not find anything - `property` will be set up as
    //  a `JSON_Undefined` type value.
    return property.value.type;
}

//      Following functions are getters for various types of variables.
//      Getter for null value simply checks if it's null
//  and returns true/false as a result.
//      Getters for simple types (number, string, boolean) can have optional
//  default value specified, that will be returned if requested variable
//  doesn't exist or has a different type.
//      Getters for object and array types don't take default values and
//  will simply return `none`.
public final function float GetNumber(string name, optional float defaultValue)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.type != JSON_Number) {
        return defaultValue;
    }
    return property.value.numberValue;
}

public final function int GetInteger(string name, optional int defaultValue)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.type != JSON_Number) {
        return defaultValue;
    }
    return property.value.numberValueAsInt;
}

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

public final function bool GetBoolean(string name, optional bool defaultValue)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.type != JSON_Boolean) {
        return defaultValue;
    }
    return property.value.booleanValue;
}

public final function bool IsNull(string name)
{
    local JProperty property;
    FindProperty(name, property);
    return (property.value.type == JSON_Null);
}

public final function JArray GetArray(string name)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.type != JSON_Array) {
        return none;
    }
    return JArray(property.value.complexValue);
}

public final function JObject GetObject(string name)
{
    local JProperty property;
    FindProperty(name, property);
    if (property.value.type != JSON_Object) return none;
    return JObject(property.value.complexValue);
}

//      Following functions provide simple setters for boolean, string, number
//  and null values.
//      They return object itself, allowing user to chain calls like this:
//  `object.SetNumber("num1", 1).SetNumber("num2", 2);`.
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

public final function JObject SetNull(string name)
{
    local JProperty property;
    FindProperty(name, property);
    property.value.type         = JSON_Null;
    property.value.complexValue = none;
    UpdateProperty(property);
    return self;
}

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

//      JSON array and object types don't have setters, but instead have
//  functions to create a new, empty array/object under a certain name.
//      They return object itself, allowing user to chain calls like this:
//  `object.CreateObject("folded object").CreateArray("names list");`.
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

//  Removes values with a given name.
//  Returns `true` if value was actually removed and `false` if it didn't exist.
public final function JObject RemoveValue(string name)
{
    RemoveProperty(name);
    return self;
}

public final function array<string> GetKeys()
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

public function bool ParseIntoSelfWith(Parser parser)
{
    local bool                  parsingSucceeded;
    local Parser.ParserState    initState, confirmedState;
    local JProperty             nextProperty;
    local array<JProperty>      parsedProperties;
    if (parser == none) return false;
    initState = parser.GetCurrentState();
    confirmedState = parser.Skip().Match("{").GetCurrentState();
    if (!parser.Ok())
    {
        parser.RestoreState(initState);
        return false;
    }
    while (parser.Ok() && !parser.HasFinished())
    {
        confirmedState = parser.Skip().GetCurrentState();
        if (parser.Match("}").Ok())
        {
            parsingSucceeded = true;
            break;
        }
        if (    parsedProperties.length > 0
            &&  !parser.RestoreState(confirmedState).Match(",").Skip().Ok()) {
            break;
        }
        else if (parser.Ok()) {
            confirmedState = parser.GetCurrentState();
        }
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
    //      Prepare delimiters using appropriate indentation rules
    //      We only use inner settings for the part right after '{',
    //  as the rest is supposed to be aligned with outer objects
    openingBraces = displaySettings.beforeObjectOpening
        $ "{" $ innerSettings.afterObjectOpening;
    closingBraces = displaySettings.beforeObjectEnding
        $ "}" $ displaySettings.afterObjectEnding;
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

defaultproperties
{
    ABSOLUTE_LOWER_CAPACITY_LIMIT       = 10
    MINIMUM_CAPACITY                    = 50
    MAXIMUM_CAPACITY                    = 100000
    MINIMUM_DENSITY                     = 0.25
    MAXIMUM_DENSITY                     = 0.75
    MINIMUM_DIFFERENCE_FOR_REALLOCATION = 50
}