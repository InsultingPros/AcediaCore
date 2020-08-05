/**
 *      JSON is an open standard file format, and data interchange format,
 *  that uses human-readable text to store and transmit data objects
 *  consisting of name–value pairs and array data types.
 *      For more information refer to https://en.wikipedia.org/wiki/JSON
 *      This is a base class for implementation of JSON objects and arrays
 *  for Acedia.
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
    abstract
    config(AcediaSystem);

/**
 *  Enumeration for possible types of JSON values.
 */
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

/**
 *  Represents a single JSON value.
 */
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

/**
 *      Enumeration of possible result of comparing two JSON containers
 *  (objects or arrays).
 *      Containers are compared as sets of stored variables.
 */
enum JComparisonResult
{
    //  Containers contain different sets of values and
    //  neither can be considered a subset of another.
    JCR_Incomparable,
    //  "Left" container is a subset of the "right" one.
    JCR_SubSet,
    //  "Right" container is a subset of the "left" one.
    JCR_Overset,
    //  Both objects are identical.
    JCR_Equal
};

/**
 *  Describes how JSON containers are supposed to be displayed.
 */
struct JSONDisplaySettings
{
    //  Should it be displayed as a formatted string, with added color tags?
    var bool    colored;
    //  Should we "stack" indentation of folded objects?
    var bool    stackIndentation;
    //  Indentation for elements in object/array
    var string  subObjectIndentation, subArrayIndentation;
    //  Strings to put immediately before and after object opening: '{'
    var string  beforeObjectOpening, afterObjectOpening;
    //  Strings to put immediately before and after object closing: '}'
    var string  beforeObjectEnding, afterObjectEnding;
    //  {<beforePropertyName>"name"<afterPropertyName>:value}
    var string  beforePropertyName, afterPropertyName;
    //  {"name":<beforePropertyValue>value<afterPropertyValue>}
    var string  beforePropertyValue, afterPropertyValue;
    //  String to put immediately after comma inside object,
    //  can be used to break line after each property record
    var string  afterObjectComma;
    //  Strings to put immediately before and after array opening: '['
    var string  beforeArrayOpening, afterArrayOpening;
    //  Strings to put immediately before and after array closing: ']'
    var string  beforeArrayEnding, afterArrayEnding;
    //  [<beforeElement>element1<afterElement>,<afterArrayComma>...]
    var string  beforeElement, afterElement;
    //  Can be used to break line after each property record
    var string  afterArrayComma;
};

//  Max precision that will be used when outputting JSON values as a string.
//  Hardcoded to force this value between 0 and 10, inclusively.
var private const config int MAX_FLOAT_PRECISION;

/**
 *  Completely clears caller JSON container of all stored data.
 */
public function Clear(){}

/**
 *  Makes an exact copy of the caller JSON container.
 *
 *  @return Copy of the caller JSON container object.
 */
public function JSON Clone()
{
    return none;
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
    return false;
}

/**
 *  Compares caller JSON container ("left container")
 *  to `rightJSON` ("right container").
 *
 *  @param  rightJSON   Value to compare caller object to.
 *  @return `JComparisonResult` describing comparison of caller `JSON` container
 *      to `rightJSON`.
 *      Always returns `false` if compared objects are of different types.
 */
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

/**
 *  Checks if two objects are equal.
 *
 *  A shortcut for `Compare(rightJSON) == JCR_Equal`.
 *
 *  @param  rightJSON   Value to compare caller object to.
 *  @return `true` if caller and `rightJSON` store exactly same set of values
 *      (under the same names for `JObject`) and `false` otherwise.
 */
public final function bool IsEqual(JSON rightJSON)
{
    return (Compare(rightJSON) == JCR_Equal);
}

/**
 *  Displays caller JSON container with one of the presets.
 *
 *  Default compact preset displays JSON in as little characters as possible,
 *  fancy preset tries to make it human-readable with appropriate spacing and
 *  indentation for sub objects.
 *
 *  See `DisplayWith()` for a more tweakable method.
 *
 *  @param  fancyPrinting   Leave empty of `false` for a compact display and
 *      `true` to display it with a fancy preset.
 *  @param  colorSettings   Display JSON container as a formatted string,
 *      adding color tags to JSON syntax.
 *  @return String representation of caller JSON container,
 *      in plain format if `colorSettings == false` and
 *      as a formatted string if `colorSettings == true`.
 */
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

/**
 *  Displays caller JSON container with a provided preset.
 *
 *  See `Display()` for a simpler to use method.
 *
 *  @param  displaySettings   Struct that describes precisely how to display
 *      caller JSON container. Can be used to emulate `Display()` call.
 *  @return String representation of caller JSON container in format defined by
 *      `displaySettings`.
 */
public function string DisplayWith(JSONDisplaySettings displaySettings)
{
    return "";
}

/**
 *  Uses given parser to parse a new set of properties inside
 *  the caller JSON container.
 *
 *  Only adds new properties if parsing the whole object was successful,
 *  otherwise even successfully parsed properties will be discarded.
 *
 *      `parser` must point at the text describing a JSON object or an array
 *  (depending on whether a caller object is `JObject` or `JArray`) in
 *  a valid notation. Then it parses that container inside memory, but
 *  instead of creating it as a separate entity, adds it's values to
 *  the caller container.
 *      Everything that comes after parsed JSON container is discarded.
 *
 *      This method does not try to validate passed JSON and can accept invalid
 *  JSON by making some assumptions, but it is an undefined behavior and
 *  one should not expect it.
 *      Method is only guaranteed to work on valid JSON.
 *
 *  @param  parser  Parser that method would use to parse JSON container from
 *      wherever it left. It's confirmed will not be changed, but if parsing
 *      was successful, - it will point at the next available character.
 *      Do not treat `parser` being in a non-failed state as a confirmation of
 *      successful parsing: JSON parsing might fail regardless.
 *      Check return value for that.
 *  @return `true` if parsing was successful and `false` otherwise.
 */
public function bool ParseIntoSelfWith(Parser parser)
{
    return false;
}

/**
 *  Parse a new set of properties inside the caller JSON container from
 *  a given `Text`.
 *
 *  Only adds new properties if parsing the whole object was successful,
 *  otherwise even successfully parsed properties will be discarded.
 *
 *      JSON container is parsed from a given `Text`, but instead of creating
 *  new object as a separate entity, method adds it's values to
 *  the caller container.
 *      Everything that comes after parsed JSON container is discarded.
 *
 *      This method does not try to validate passed JSON and can accept invalid
 *  JSON by making some assumptions, but it is an undefined behavior and
 *  one should not expect it.
 *      Method is only guaranteed to work on valid JSON.
 *
 *  @param  source  `Text` to get JSON container definition from.
 *  @return `true` if parsing was successful and `false` otherwise.
 */
public final function bool ParseIntoSelf(Text source)
{
    local bool      successfullyParsed;
    local Parser    jsonParser;
    jsonParser = _.text.Parse(source);
    successfullyParsed = ParseIntoSelfWith(jsonParser);
    _.memory.Free(jsonParser);
    return successfullyParsed;
}

/**
 *  Parse a new set of properties inside the caller JSON container from
 *  a given `string`.
 *
 *  Only adds new properties if parsing the whole object was successful,
 *  otherwise even successfully parsed properties will be discarded.
 *
 *      JSON container is parsed from a given `string`, but instead of creating
 *  new object as a separate entity, method adds it's values to
 *  the caller container.
 *      Everything that comes after parsed JSON container is discarded.
 *
 *      This method does not try to validate passed JSON and can accept invalid
 *  JSON by making some assumptions, but it is an undefined behavior and
 *  one should not expect it.
 *      Method is only guaranteed to work on valid JSON.
 *
 *  @param  source  `string` to get JSON container definition from.
 *  @return `true` if parsing was successful and `false` otherwise.
 */
public final function bool ParseIntoSelfString(
    string                      source,
    optional Text.StringType    stringType)
{
    local bool      successfullyParsed;
    local Parser    jsonParser;
    jsonParser = _.text.ParseString(source, stringType);
    successfullyParsed = ParseIntoSelfWith(jsonParser);
    _.memory.Free(jsonParser);
    return successfullyParsed;
}

/**
 *  Parse a new set of properties inside the caller JSON container from
 *  a given raw data.
 *
 *  Only adds new properties if parsing the whole object was successful,
 *  otherwise even successfully parsed properties will be discarded.
 *
 *      JSON container is parsed from a given raw data, but instead of creating
 *  new object as a separate entity, method adds it's values to
 *  the caller container.
 *      Everything that comes after parsed JSON container is discarded.
 *
 *      This method does not try to validate passed JSON and can accept invalid
 *  JSON by making some assumptions, but it is an undefined behavior and
 *  one should not expect it.
 *      Method is only guaranteed to work on valid JSON.
 *
 *  @param  source  Raw data *array of `Text.Character`) to get JSON container
 *      definition from.
 *  @return `true` if parsing was successful and `false` otherwise.
 */
public final function bool ParseIntoSelfRaw(array<Text.Character> rawSource)
{
    local bool      successfullyParsed;
    local Parser    jsonParser;
    jsonParser = _.text.ParseRaw(rawSource);
    successfullyParsed = ParseIntoSelfWith(jsonParser);
    _.memory.Free(jsonParser);
    return successfullyParsed;
}

/**
 *  Checks if two `JStorageAtom` values represent the same values.
 *
 *  Atoms storing the same value does not necessarily mean that they are equal
 *  as structs because they contain several different container members and
 *  unused ones can differ.
 *
 *  @return `true` if atoms stores the same value, `false` otherwise.
 */
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

/**
 *  Tries to load class variable into an atom, based on it's `stringValue`.
 *
 *  @param  atom    Result will be recorded in the field of the argument itself.
 */
protected final function TryLoadingStringAsClass(out JStorageAtom atom)
{
    if (atom.classLoadingWasAttempted) return;
    atom.classLoadingWasAttempted = true;
    atom.stringValueAsClass =
        class<Object>(DynamicLoadObject(atom.stringValue, class'Class', true));
}

/**
 *  Displays a `JStorageAtom` in it's appropriate text JSON representation.
 *
 *  That's a representation that can be pasted inside JSON array as-is
 *  (with different values separated by commas).
 *
 *  @param  atom            Atom to display.
 *  @param  displaySettings Display settings, according to which to
 *      display the atom.
 *  @return Text representation of the passed `atom`, empty if it's of
 *      the type `JSON_Undefined`.
 */
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

//  Helper function for printing float with a given max precision
//  (`MAX_FLOAT_PRECISION`).
private final function string DisplayFloat(float number)
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
    //  We try to perform minimal amount of operations to extract fractional
    //  part as integer in order to avoid accumulating too much of an error.
    fractionalPart = Round(number * (10 ** precision));
    if (fractionalPart <= 0) {
        return result;
    }
    result $= ".";
    //  Pad necessary zeroes in front
    howManyZeroes = precision - CountDigits(fractionalPart);
    while (howManyZeroes > 0) {
        zeroes $= "0";
        howManyZeroes -= 1;
    }
    //  Cut off trailing zeroes and 
    while (fractionalPart > 0 && fractionalPart % 10 == 0) {
        fractionalPart /= 10;
    }
    return result $ zeroes $ string(fractionalPart);
}

//  Helper function that counts amount of digits in decimal representation
//  of `number`.
private final function int CountDigits(int number)
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

/**
 *  Prepares a `string` to be displayed as textual JSON representation by
 *  replacing certain characters with their escaped sequences.
 *
 *  @param  input   String value to display inside a text representation of
 *      a JSON data.
 *  @result Representation of an `input` that can be included in text form of
 *      JSON data.
 */
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

//  helper function to prepare fancy display settings, because it is a bitch to
//  include a `string` with new line symbol in `defaultproperties`.
private final function JSONDisplaySettings GetFancySettings()
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

/**
 *  Helper function that prepares `JSONDisplaySettings` to be used for
 *  a folded object / array to make it more human-readable thanks to
 *  sub-object/-arrays indentation.
 *
 *  @param  inputSettings   Settings to modify, passed variable will
 *      remain unchanged.
 *  @param  indentingArray  True if we need to modify settings for
 *      a folded array and `false` if for the object.
 *  @return Modified `inputSettings`, with added indentation.
 */
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

/**
 *  Uses given parser to parse a single (possibly complex like JSON object
 *  or array) JSON value.
 *
 *  @param  parser  Parser that method would use to parse JSON value from
 *      wherever it left. It's confirmed will not be changed, but if parsing
 *      was successful, - it will point at the next available character.
 *      Do not treat `parser` being in a non-failed state as a confirmation of
 *      successful parsing: JSON parsing might fail regardless.
 *      Check return value for that.
 *  @return Parsed JSON value as `JStorageAtom`.
 *      If parsing has failed it will have the `JSON_Undefined` type.
 */
protected final function JStorageAtom ParseAtom(Parser parser)
{
    local Parser.ParserState    initState;
    local JStorageAtom          newAtom;
    if (parser == none) return newAtom;
    if (!parser.Ok())   return newAtom;
    initState = parser.GetCurrentState();
    if (parser.MStringLiteral(newAtom.stringValue).Ok())
    {
        newAtom.type = JSON_String;
        return newAtom;
    }
    newAtom = ParseLiteral(parser.RestoreState(initState));
    if (newAtom.type != JSON_Undefined) {
        return newAtom;
    }
    newAtom = ParseComplex(parser.RestoreState(initState));
    if (newAtom.type != JSON_Undefined) {
        return newAtom;
    }
    newAtom = ParseNumber(parser.RestoreState(initState));
    if (newAtom.type == JSON_Undefined) {
        parser.RestoreState(initState);
    }
    return newAtom;
}

/**
 *  Uses given parser to parse a "literal" JSON value:
 *      "true", "false" or "null".
 *
 *  @param  parser  Parser that method would use to parse JSON value from
 *      wherever it left. It's confirmed will not be changed, but if parsing
 *      was successful, - it will point at the next available character.
 *      Do not treat `parser` being in a non-failed state as a confirmation of
 *      successful parsing: JSON parsing might fail regardless.
 *      Check return value for that.
 *  @return Parsed JSON value as `JStorageAtom`.
 *      If parsing has failed it will have the `JSON_Undefined` type.
 */
protected final function JStorageAtom ParseLiteral(Parser parser)
{
    local JStorageAtom          newAtom;
    local Parser.ParserState    initState;
    initState = parser.GetCurrentState();
    if (parser.Match("null", true).Ok())
    {
        newAtom.type = JSON_Null;
        return newAtom;
    }
    if (parser.RestoreState(initState).Match("false", true).Ok())
    {
        newAtom.type = JSON_Boolean;
        return newAtom;
    }
    if (parser.RestoreState(initState).Match("true", true).Ok())
    {
        newAtom.type = JSON_Boolean;
        newAtom.booleanValue = true;
        return newAtom;
    }
}

/**
 *  Uses given parser to parse a complex JSON value: JSON object or array.
 *
 *  @param  parser  Parser that method would use to parse JSON value from
 *      wherever it left. It's confirmed will not be changed, but if parsing
 *      was successful, - it will point at the next available character.
 *      Do not treat `parser` being in a non-failed state as a confirmation of
 *      successful parsing: JSON parsing might fail regardless.
 *      Check return value for that.
 *  @return Parsed JSON value as `JStorageAtom`.
 *      If parsing has failed it will have the `JSON_Undefined` type.
 */
protected final function JStorageAtom ParseComplex(Parser parser)
{
    local JStorageAtom          newAtom;
    local Parser.ParserState    initState;
    initState = parser.GetCurrentState();
    if (parser.Match("{").Ok())
    {
        newAtom.complexValue = _.json.NewObject();
        newAtom.type = JSON_Object;
    }
    else if (parser.RestoreState(initState).Match("[").Ok())
    {
        newAtom.complexValue = _.json.NewArray();
        newAtom.type = JSON_Array;
    }
    parser.RestoreState(initState);
    if (    newAtom.complexValue != none
        &&  newAtom.complexValue.ParseIntoSelfWith(parser)) {
        return newAtom;
    }
    newAtom.type = JSON_Undefined;
    newAtom.complexValue = none;
    return newAtom;
}

/**
 *  Uses given parser to parse a numeric JSON value.
 *
 *  @param  parser  Parser that method would use to parse JSON value from
 *      wherever it left. It's confirmed will not be changed, but if parsing
 *      was successful, - it will point at the next available character.
 *      Do not treat `parser` being in a non-failed state as a confirmation of
 *      successful parsing: JSON parsing might fail regardless.
 *      Check return value for that.
 *  @return Parsed JSON value as `JStorageAtom`.
 *      If parsing has failed it will have the `JSON_Undefined` type.
 */
protected final function JStorageAtom ParseNumber(Parser parser)
{
    local JStorageAtom          newAtom;
    local Parser.ParserState    initState, integerParsedState;
    initState = parser.GetCurrentState();
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
        parser.RestoreState(initState).MNumber(newAtom.numberValue);
        return newAtom;
    }
    parser.RestoreState(integerParsedState);
    newAtom.numberValue         = newAtom.numberValueAsInt;
    newAtom.preferIntegerValue  = true;
    return newAtom;
}

event Destroyed()
{
    super.Destroyed();
    Clear();
}

defaultproperties
{
    MAX_FLOAT_PRECISION = 4
}