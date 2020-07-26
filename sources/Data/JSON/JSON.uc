/**
 *      JSON is an open standard file format, and data interchange format,
 *  that uses human-readable text to store and transmit data objects
 *  consisting of name–value pairs and array data types.
 *      For more information refer to https://en.wikipedia.org/wiki/JSON
 *      This is a base class for implementation of JSON data storage for Acedia.
 *      It does not implement parsing and printing from/into human-readable
 *  text representation, just provides means to store such information.
 *
 *      JSON data is stored as an object (represented via `JSONObject`) that
 *  contains a set of name-value pairs, where value can be
 *  a number, string, boolean value, another object or
 *  an array (represented by `JSONArray`).
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
class JSON extends AcediaActor
    abstract;

//  Enumeration for possible types of JSON values.
enum JType
{
    //  Technical type, used to indicate that requested value is missing.
    //  Undefined values are not part of JSON format.
    JSON_Undefined,
    //  An empty value, in teste representation defined by a single word "null".
    JSON_Null,
    //  A number, recorded as a float.
    //  JSON itself doesn't specify whether number is an integer or float.
    JSON_Number,
    //  A string.
    JSON_String,
    //  A bool value.
    JSON_Boolean,
    //  Array of other JSON values, stored without names;
    //  Single array can contain any mix of value types.
    JSON_Array,
    //  Another JSON object, i.e. associative array of name-value pairs
    JSON_Object
};

//  Stores a single JSON value
struct JStorageAtom
{
    //  What type is stored exactly?
    //  Depending on that, uses one of the other fields as a storage.
    var JType         type;
    var float         numberValue;
    var string        stringValue;
    var bool          booleanValue;
    //  Used for storing both JSON objects and arrays.
    var JSON          complexValue;
    //  Numeric value might not fit into a `float` very well, so we will store
    //  them as both `float` and `integer` and allow user to request any version
    //  of them
    var int           numberValueAsInt;
    var bool          preferIntegerValue;
    //  Some `string` values might be actually used to represent classes,
    //  so we will give users an ability to request `string` value as a class.
    var class<Object> stringValueAsClass;
    //  To avoid several unsuccessful attempts to load `class` object from
    //  a `string`, we will record whether we've already tied that.
    var bool          classLoadingWasAttempted;
};

enum JComparisonResult
{
    JCR_Incomparable,
    JCR_SubSet,
    JCR_Overset,
    JCR_Equal
};

struct JSONDisplaySettings
{
    var bool    colored;
    var bool    stackIndentation;
    var string  subObjectIndentation, subArrayIndentation;
    var string  beforeObjectOpening, afterObjectOpening;
    var string  beforeObjectEnding, afterObjectEnding;
    var string  beforePropertyName, afterPropertyName;
    var string  beforePropertyValue, afterPropertyValue;
    var string  afterObjectComma;
    var string  beforeArrayOpening, afterArrayOpening;
    var string  beforeArrayEnding, afterArrayEnding;
    var string  beforeElement, afterElement;
    var string  afterArrayComma;
};

var private const int MAX_FLOAT_PRECISION;

public function JSON Clone()
{
    return none;
}

public function bool IsSubsetOf(JSON rightJSON)
{
    return false;
}

public final function JComparisonResult Compare(JSON rightJSON)
{
    local bool firstIsSubset, secondIsSubset;
    if (rightJSON == none) return JCR_Incomparable;
    firstIsSubset   = IsSubsetOf(rightJSON);
    secondIsSubset  = rightJSON.IsSubsetOf(self);
    if (firstIsSubset)
    {
        if (secondIsSubset) {
            return JCR_Equal;
        }
        else {
            return JCR_SubSet;
        }
    }
    else {
        if (secondIsSubset) {
            return JCR_Overset;
        }
        else {
            return JCR_Incomparable;
        }
    }
}

public final function bool IsEqual(JSON rightJSON)
{
    return (Compare(rightJSON) == JCR_Equal);
}

protected final function bool AreAtomsEqual(
    JStorageAtom atom1,
    JStorageAtom atom2)
{
    if (atom1.type != atom2.type)       return false;
    if (atom1.type == JSON_Undefined)   return true;
    if (atom1.type == JSON_Null)        return true;
    if (atom1.type == JSON_Number) {
        return (    atom1.numberValue       == atom2.numberValue
                &&  atom1.numberValueAsInt  == atom2.numberValueAsInt);
    }
    if (atom1.type == JSON_Boolean) {
        return (atom1.booleanValue == atom2.booleanValue);
    }
    if (atom1.type == JSON_String) {
        return (atom1.stringValue == atom2.stringValue);
    }
    if (atom1.complexValue == none && atom2.complexValue == none) {
        return true;
    }
    if (atom1.complexValue == none || atom2.complexValue == none) {
        return false;
    }
    return atom1.complexValue.IsEqual(atom2.complexValue);
}

protected final function TryLoadingStringAsClass(out JStorageAtom atom)
{
    if (atom.classLoadingWasAttempted) return;
    atom.classLoadingWasAttempted = true;
    atom.stringValueAsClass =
        class<Object>(DynamicLoadObject(atom.stringValue, class'Class', true));
}

public final function string Display(
    optional bool fancyPrinting,
    optional bool colorSettings)
{
    local JSONDisplaySettings settingsToUse;
    //  Settings are minimal by default
    if (fancyPrinting) {
        settingsToUse = GetFancySettings();
    }
    if (colorSettings) {
        settingsToUse.colored = true;
    }
    return DisplayWith(settingsToUse);
}

public function string DisplayWith(JSONDisplaySettings displaySettings)
{
    return "";
}

protected final function string DisplayAtom(
    JStorageAtom        atom,
    JSONDisplaySettings displaySettings)
{
    local string colorTag;
    local string result;
    if (    atom.complexValue != none
        &&  (atom.type == JSON_Object || atom.type == JSON_Array) ) {
        return atom.complexValue.DisplayWith(displaySettings);
    }
    if (atom.type == JSON_Null) {
        result = "null";
        colorTag = "$json_null";
    }
    else if (atom.type == JSON_Number) {
        if (atom.preferIntegerValue) {
            result = string(atom.numberValueAsInt);
        }
        else {
            result = DisplayFloat(atom.numberValue);
        }
        colorTag = "$json_number";
    }
    else if (atom.type == JSON_String) {
        result = DisplayJSONString(atom.stringValue);
        colorTag = "$json_string";
    }
    else if (atom.type == JSON_Boolean) {
        if (atom.booleanValue) {
            result = "true";
        }
        else {
            result = "false";
        }
        colorTag = "$json_boolean";
    }
    if (displaySettings.colored) {
        return "{" $ colorTag @ result $ "}";
    }
    return result;
}

protected final function string DisplayFloat(float number)
{
    local int       integerPart, fractionalPart;
    local int       precision;
    local int       howManyZeroes;
    local string    zeroes;
    local string    result;
    precision = Clamp(MAX_FLOAT_PRECISION, 0, 10);
    if (number < 0) {
        number *= -1;
        result = "-";
    }
    integerPart = number;
    result $= string(integerPart);
    number = (number - integerPart);
    fractionalPart = Round(number * (10 ** precision));
    if (fractionalPart <= 0) {
        return result;
    }
    result $= ".";
    howManyZeroes = precision - CountDigits(fractionalPart);
    while (fractionalPart > 0 && fractionalPart % 10 == 0) {
        fractionalPart /= 10;
    }
    while (howManyZeroes > 0) {
        zeroes $= "0";
        howManyZeroes -= 1;
    }
    return result $ zeroes $ string(fractionalPart);
}

protected final function int CountDigits(int number)
{
    local int digitCounter;
    while (number > 0)
    {
        number -= (number % 10);
        number /= 10;
        digitCounter += 1;
    }
    return digitCounter;
}

protected final function JSONDisplaySettings GetFancySettings()
{
    local string                lineFeed;
    local JSONDisplaySettings   fancySettings;
    lineFeed = Chr(10);
    fancySettings.stackIndentation      = true;
    fancySettings.subObjectIndentation  = "    ";
    fancySettings.subArrayIndentation   = "";
    fancySettings.afterObjectOpening    = lineFeed;
    fancySettings.beforeObjectEnding    = lineFeed;
    fancySettings.beforePropertyValue   = " ";
    fancySettings.afterObjectComma      = lineFeed;
    fancySettings.beforeElement         = " ";
    fancySettings.afterArrayComma       = " ";
    return fancySettings;
}

protected final function string DisplayJSONString(string input)
{
    //  Convert control characters (+ other, specified by JSON)
    //  into escaped sequences
    ReplaceText(input, "\"", "\\\"");
    ReplaceText(input, "/", "\\/");
    ReplaceText(input, "\\", "\\\\");
    ReplaceText(input, Chr(0x08), "\\b");
    ReplaceText(input, Chr(0x0c), "\\f");
    ReplaceText(input, Chr(0x0a), "\\n");
    ReplaceText(input, Chr(0x0d), "\\r");
    ReplaceText(input, Chr(0x09), "\\t");
    //  TODO: test if there are control characters and render them as "\u...."
    return ("\"" $ input $ "\"");
}

protected final function JSONDisplaySettings IndentSettings(
    JSONDisplaySettings inputSettings,
    optional bool       indentingArray)
{
    local string                lineFeed;
    local string                lineFeedIndent;
    local JSONDisplaySettings   indentedSettings;
    indentedSettings = inputSettings;
    lineFeed = Chr(0x0a);
    if (indentingArray) {
        lineFeedIndent = lineFeed $ inputSettings.subArrayIndentation;
    }
    else {
        lineFeedIndent = lineFeed $ inputSettings.subObjectIndentation;
    }
    if (lineFeedIndent == lineFeed) {
        return indentedSettings;
    }
    ReplaceText(indentedSettings.afterObjectEnding, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.afterPropertyName, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.afterObjectComma, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.afterArrayOpening, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.beforeArrayEnding, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.afterArrayEnding, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.beforeElement, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.afterElement, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.afterArrayComma, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.beforeObjectOpening, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.beforePropertyValue, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.afterObjectOpening, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.beforeObjectEnding, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.beforeArrayOpening, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.afterPropertyValue, lineFeed, lineFeedIndent);
    ReplaceText(indentedSettings.beforePropertyName, lineFeed, lineFeedIndent);
    return indentedSettings;
}

public function bool ParseIntoSelfWith(Parser parser)
{
    return false;
}

public final function bool ParseIntoSelf(Text source)
{
    local bool      successfullyParsed;
    local Parser    jsonParser;
    jsonParser = _.text.Parse(source);
    successfullyParsed = ParseIntoSelfWith(jsonParser);
    _.memory.Free(jsonParser);
    return successfullyParsed;
}

public final function bool ParseIntoSelfString(string source)
{
    local bool      successfullyParsed;
    local Parser    jsonParser;
    jsonParser = _.text.ParseString(source);
    successfullyParsed = ParseIntoSelfWith(jsonParser);
    _.memory.Free(jsonParser);
    return successfullyParsed;
}

public final function bool ParseIntoSelfRaw(array<Text.Character> rawSource)
{
    local bool      successfullyParsed;
    local Parser    jsonParser;
    jsonParser = _.text.ParseRaw(rawSource);
    successfullyParsed = ParseIntoSelfWith(jsonParser);
    _.memory.Free(jsonParser);
    return successfullyParsed;
}

protected final function JStorageAtom ParseAtom(Parser parser)
{
    local Parser.ParserState    initState;
    local JStorageAtom          newAtom;
    if (parser == none) return newAtom;
    if (!parser.Ok())   return newAtom;
    initState = parser.GetCurrentState();
    parser.Skip().Confirm();
    if (parser.MStringLiteral(newAtom.stringValue).Ok())
    {
        newAtom.type = JSON_String;
        return newAtom;
    }
    newAtom = ParseLiteral(parser.R());
    if (newAtom.type != JSON_Undefined) {
        return newAtom;
    }
    newAtom = ParseComplex(parser.R());
    if (newAtom.type != JSON_Undefined) {
        return newAtom;
    }
    newAtom = ParseNumber(parser.R());
    if (newAtom.type == JSON_Undefined) {
        parser.RestoreState(initState);
    }
    return newAtom;
}

protected final function JStorageAtom ParseLiteral(Parser parser)
{
    local JStorageAtom newAtom;
    if (parser.Match("null", true).Ok())
    {
        newAtom.type = JSON_Null;
        return newAtom;
    }
    if (parser.R().Match("false", true).Ok())
    {
        newAtom.type = JSON_Boolean;
        return newAtom;
    }
    if (parser.R().Match("true", true).Ok())
    {
        newAtom.type = JSON_Boolean;
        newAtom.booleanValue = true;
        return newAtom;
    }
}

protected final function JStorageAtom ParseComplex(Parser parser)
{
    local JStorageAtom newAtom;
    if (parser.Match("{").Ok())
    {
        newAtom.complexValue = _.json.NewObject();
        newAtom.type = JSON_Object;
    }
    else if (parser.R().Match("[").Ok())
    {
        newAtom.complexValue = _.json.NewArray();
        newAtom.type = JSON_Array;
    }
    if (    newAtom.complexValue != none
        &&  newAtom.complexValue.ParseIntoSelfWith(parser.R())) {
        return newAtom;
    }
    newAtom.type = JSON_Undefined;
    newAtom.complexValue = none;
    return newAtom;
}

protected final function JStorageAtom ParseNumber(Parser parser)
{
    local JStorageAtom          newAtom;
    local Parser.ParserState    integerParsedState;
    if (!parser.MInteger(newAtom.numberValueAsInt).Ok()) {
        return newAtom;
    }
    newAtom.type        = JSON_Number;
    integerParsedState  = parser.GetCurrentState();
    //  For a number check if it is recorded as a float specifically.
    //  If not - prefer integer for storage.
    if (    parser.Match(".").Ok()
        ||  parser.RestoreState(integerParsedState).Match("e", true).Ok())
    {
        parser.R().MNumber(newAtom.numberValue);
        return newAtom;
    }
    parser.RestoreState(integerParsedState);
    newAtom.numberValue         = newAtom.numberValueAsInt;
    newAtom.preferIntegerValue  = true;
    return newAtom;
}

defaultproperties
{
    MAX_FLOAT_PRECISION = 4
}