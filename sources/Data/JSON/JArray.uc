/**
 *      This class implements JSON array storage capabilities.
 *      Array stores ordered JSON values that can be referred by their index.
 *  It can contain any mix of JSON value types and cannot have any gaps,
 *  i.e. in array of length N, there must be a valid value for all indices
 *  from 0 to N-1.
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

//  Data will simply be stored as an array of JSON values
var private array<JStorageAtom> data;

//  Return type of value stored at a given index.
//  Returns `JSON_Undefined` if and only if given index is out of bounds.
public final function JType GetTypeOf(int index)
{
    if (index < 0)              return JSON_Undefined;
    if (index >= data.length)   return JSON_Undefined;

    return data[index].type;
}

//  Returns current length of this array.
public final function int GetLength()
{
    return data.length;
}

//  Changes length of this array.
//  In case of the increase - fills new indices with `null` values.
public final function SetLength(int newLength)
{
    local int i;
    local int oldLength;
    oldLength = data.length;
    data.length = newLength;
    if (oldLength >= newLength)
    {
        return;
    }
    i = oldLength;
    while (i < newLength)
    {
        SetNull(i);
        i += 1;
    }
}

//      Following functions are getters for various types of variables.
//      Getter for null value simply checks if it's null
//  and returns true/false as a result.
//      Getters for simple types (number, string, boolean) can have optional
//  default value specified, that will be returned if requested variable
//  doesn't exist or has a different type.
//      Getters for object and array types don't take default values and
//  will simply return `none`.
public final function float GetNumber(int index, optional float defaultValue)
{
    if (index < 0)                          return defaultValue;
    if (index >= data.length)               return defaultValue;
    if (data[index].type != JSON_Number)    return defaultValue;

    return data[index].numberValue;
}

public final function float GetInteger(int index, optional float defaultValue)
{
    if (index < 0)                          return defaultValue;
    if (index >= data.length)               return defaultValue;
    if (data[index].type != JSON_Number)    return defaultValue;

    return data[index].numberValueAsInt;
}

public final function string GetString(int index, optional string defaultValue)
{
    if (index < 0)                          return defaultValue;
    if (index >= data.length)               return defaultValue;
    if (data[index].type != JSON_String)    return defaultValue;

    return data[index].stringValue;
}

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

public final function bool GetBoolean(int index, optional bool defaultValue)
{
    if (index < 0)                          return defaultValue;
    if (index >= data.length)               return defaultValue;
    if (data[index].type != JSON_Boolean)   return defaultValue;

    return data[index].booleanValue;
}

public final function bool IsNull(int index)
{
    if (index < 0)              return false;
    if (index >= data.length)   return false;

    return (data[index].type == JSON_Null);
}

public final function JArray GetArray(int index)
{
    if (index < 0)                      return none;
    if (index >= data.length)           return none;
    if (data[index].type != JSON_Array) return none;

    return JArray(data[index].complexValue);
}

public final function JObject GetObject(int index)
{
    if (index < 0)                          return none;
    if (index >= data.length)               return none;
    if (data[index].type != JSON_Object)    return none;

    return JObject(data[index].complexValue);
}

//      Following functions provide simple setters for boolean, string, number
//  and null values.
//      If passed index is negative - does nothing.
//      If index lies beyond array length (`>= GetLength()`), -
//  these functions will expand array in the same way as `GetLength()` function.
//  This can be prevented by setting optional parameter `preventExpansion` to
//  `false` (nothing will be done in this case).
//      They return object itself, allowing user to chain calls like this:
//  `array.SetNumber("num1", 1).SetNumber("num2", 2);`.
public final function JArray SetNumber(
    int index,
    float value,
    optional bool preventExpansion
)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type                = JSON_Number;
    newStorageValue.numberValue         = value;
    newStorageValue.numberValueAsInt    = int(value);
    newStorageValue.preferIntegerValue  = false;
    data[index] = newStorageValue;
    return self;
}

public final function JArray SetInteger(
    int index,
    int value,
    optional bool preventExpansion
)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type                = JSON_Number;
    newStorageValue.numberValue         = float(value);
    newStorageValue.numberValueAsInt    = value;
    newStorageValue.preferIntegerValue  = true;
    data[index] = newStorageValue;
    return self;
}

public final function JArray SetString
(
    int index,
    string value,
    optional bool preventExpansion
)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type        = JSON_String;
    newStorageValue.stringValue = value;
    data[index] = newStorageValue;
    return self;
}

public final function JArray SetClass(
    int index,
    class<Object> value,
    optional bool preventExpansion
)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type                = JSON_String;
    newStorageValue.stringValue         = string(value);
    newStorageValue.stringValueAsClass  = value;
    data[index] = newStorageValue;
    return self;
}

public final function JArray SetBoolean
(
    int index,
    bool value,
    optional bool preventExpansion
)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type            = JSON_Boolean;
    newStorageValue.booleanValue    = value;
    data[index] = newStorageValue;
    return self;
}

public final function JArray SetNull
(
    int index,
    optional bool preventExpansion
)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type = JSON_Null;
    data[index] = newStorageValue;
    return self;
}

public final function JArray SetArray(
    int index,
    JArray template,
    optional bool preventExpansion
)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;
    if (template == none) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type            = JSON_Array;
    newStorageValue.complexValue    = template.Clone();
    data[index] = newStorageValue;
    return self;
}

public final function JArray SetObject(
    int index,
    JObject template,
    optional bool preventExpansion
)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;
    if (template == none) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type            = JSON_Object;
    newStorageValue.complexValue    = template.Clone();
    data[index] = newStorageValue;
    return self;
}

//      JSON array and object types don't have setters, but instead have
//  functions to create a new, empty array/object under a certain name.
//      If passed index is negative - does nothing.
//      If index lies beyond array length (`>= GetLength()`), -
//  these functions will expand array in the same way as `GetLength()` function.
//  This can be prevented by setting optional parameter `preventExpansion` to
//  `false` (nothing will be done in this case).
//      They return object itself, allowing user to chain calls like this:
//  `array.CreateObject("sub object").CreateArray("sub array");`.
public final function JArray CreateArray
(
    int index,
    optional bool preventExpansion
)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type            = JSON_Array;
    newStorageValue.complexValue    = _.json.newArray();
    data[index] = newStorageValue;
    return self;
}

public final function JArray CreateObject
(
    int index,
    optional bool preventExpansion
)
{
    local JStorageAtom newStorageValue;
    if (index < 0) return self;

    if (index >= data.length)
    {
        if (preventExpansion)
        {
            return self;
        }
        else
        {
            SetLength(index + 1);
        }
    }
    newStorageValue.type            = JSON_Object;
    newStorageValue.complexValue    = _.json.newObject();
    data[index] = newStorageValue;
    return self;
}

//      Wrappers for setter functions that don't take index or
//  `preventExpansion` parameters and add/create value at the end of the array.
public final function JArray AddNumber(float value)
{
    return SetNumber(data.length, value);
}

public final function JArray AddInteger(int value)
{
    return SetInteger(data.length, value);
}

public final function JArray AddString(string value)
{
    return SetString(data.length, value);
}

public final function JArray AddClass(class<Object> value)
{
    return SetClass(data.length, value);
}

public final function JArray AddBoolean(bool value)
{
    return SetBoolean(data.length, value);
}

public final function JArray AddNull()
{
    return SetNull(data.length);
}

public final function JArray AddArray()
{
    return CreateArray(data.length);
}

public final function JArray AddObject()
{
    return CreateObject(data.length);
}

//  Removes up to `amount` (minimum of `1`) of values, starting from
//  a given index.
//      If `index` falls outside array boundaries - nothing will be done.
//  Returns `true` if value was actually removed and `false` if it didn't exist.
public final function bool RemoveValue(int index, optional int amount)
{
    if (index < 0)              return false;
    if (index >= data.length)   return false;

    amount = Max(amount, 1);
    amount = Min(amount, data.length - index);
    data.Remove(index, amount);
    return true;
}

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

public function bool ParseIntoSelfWith(Parser parser)
{
    local int                   i;
    local bool                  parsingSucceeded;
    local Parser.ParserState    initState;
    local JStorageAtom          nextAtom;
    local array<JStorageAtom>   parsedAtoms;
    if (parser == none) return false;
    initState = parser.GetCurrentState();
    parser.Skip().Match("[").Confirm();
    if (!parser.Ok())
    {
        parser.RestoreState(initState);
        return false;
    }
    while (parser.Ok() && !parser.HasFinished())
    {
        parser.Skip().Confirm();
        if (parser.Match("]").Ok()) {
            parsingSucceeded = true;
            break;
        }
        if (parsedAtoms.length > 0 && !parser.R().Match(",").Skip().Ok()) {
            break;
        }
        else {
            parser.Confirm();
        }
        nextAtom = ParseAtom(parser.R());
        if (nextAtom.type == JSON_Undefined) {
            break;
        }
        parsedAtoms[parsedAtoms.length] = nextAtom;
        parser.Confirm();
    }
    if (parsingSucceeded)
    {
        for (i = 0; i < parsedAtoms.length; i += 1) {
            data[data.length] = parsedAtoms[i];
        }
    }
    else {
        parser.RestoreState(initState);
    }
    return parsingSucceeded;
}

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