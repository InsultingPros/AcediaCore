/**
 *      Provides convenient access to JSON-related functions.
 *      Printing method produce correct JSON.
 *      Parsing methods do not provide validity checks guarantees and will parse
 *  both valid and invalid JSON. However only correctly parsing valid JSON 
 *  is guaranteed. This means that you should not rely on these methods to parse
 *  any JSON extensions or validate JSON for you.
 *      Copyright 2021-2022 Anton Tarasenko
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
class JSONAPI extends AcediaObject
    config(AcediaSystem);

var private bool            formattingInitialized;
//  Variables used in json pretty printing for defining used colors;
//  Colors are taken from `ColorAPI`.
var private BaseText.Formatting jPropertyName, jObjectBraces, jArrayBraces;
var private BaseText.Formatting jComma, jColon, jNumber, jBoolean, jString;
var private BaseText.Formatting jNull;

var const int TNULL, TTRUE, TFALSE, TDOT, TEXPONENT;
var const int TOPEN_BRACKET, TCLOSE_BRACKET, TOPEN_BRACE, TCLOSE_BRACE;
var const int TCOMMA, TCOLON, TQUOTE, TJSON_INDENT, TSPACE, TCOLON_SPACE;

var const int CODEPOINT_BACKSPACE, CODEPOINT_TAB, CODEPOINT_LINE_FEED;
var const int CODEPOINT_FORM_FEED, CODEPOINT_CARRIAGE_RETURN;
var const int CODEPOINT_QUOTATION_MARK, CODEPOINT_SOLIDUS;
var const int CODEPOINT_REVERSE_SOLIDUS, CODEPOINT_SMALL_B, CODEPOINT_SMALL_F;
var const int CODEPOINT_SMALL_N, CODEPOINT_SMALL_R, CODEPOINT_SMALL_T;

//  Max precision that will be used when outputting JSON values as a string.
//  Hardcoded to force this value between 0 and 10, inclusively.
var private const config int MAX_FLOAT_PRECISION;

//  Method for initializing json formatting variables
private final function InitFormatting()
{
    if (formattingInitialized) {
        return;
    }
    formattingInitialized = true;
    jPropertyName   = _.text.FormattingFromColor(_.color.jPropertyName);
    jObjectBraces   = _.text.FormattingFromColor(_.color.jObjectBraces);
    jArrayBraces    = _.text.FormattingFromColor(_.color.jArrayBraces);
    jComma          = _.text.FormattingFromColor(_.color.jComma);
    jColon          = _.text.FormattingFromColor(_.color.jColon);
    jNumber         = _.text.FormattingFromColor(_.color.jNumber);
    jBoolean        = _.text.FormattingFromColor(_.color.jBoolean);
    jString         = _.text.FormattingFromColor(_.color.jString);
    jNull           = _.text.FormattingFromColor(_.color.jNull);
}

/**
 *  Creates new `JSONPointer`, corresponding to a given path in
 *  JSON pointer format (https://tools.ietf.org/html/rfc6901).
 *
 *      If provided `Text` value is an incorrect pointer, then it will be
 *  treated like an empty pointer.
 *      However, if given pointer can be fixed by prepending "/" - it will be
 *  done automatically. This means that "foo/bar" is treated like "/foo/bar",
 *  "path" like "/path", but empty `Text` "" is treated like itself.
 *
 *  @param  pointerAsText   `Text` representation of the JSON pointer.
 *  @return New `JSONPointer`, corresponding to the given `pointerAsText`.
 *      Guaranteed to not be `none`. If provided `pointerAsText` is
 *      an incorrect JSON pointer or `none`, - empty `JSONPointer` will be
 *      returned.
 */
public final function JSONPointer Pointer(optional BaseText pointerAsText)
{
    return JSONPointer(_.memory.Allocate(class'JSONPointer'))
        .Set(pointerAsText);
}

/**
 *  Checks whether passed `AcediaObject` can be converted into JSON by this API.
 *
 *  Compatible objects are `none` and any object that has one of the following
 *  classes: `BoolBox`, `BoolRef`, `ByteBox`, `ByteRef`, `IntBox`, `IntRef`,
 *  `FloatBox`, `FloatRef`, `Text`, `MutableText`, `ArrayList`,
 *  `HashTable`.
 *
 *  This method does not check whether objects stored inside `ArrayList`,
 *  `HashTable` are compatible. If they are not, they will normally be
 *  defaulted to JSON null upon any conversion.
 */
public function bool IsCompatible(AcediaObject data)
{
    local class<AcediaObject> dataClass;
    if (data == none) {
        return true;
    }
    dataClass = data.class;
    return  dataClass == class'BoolBox'     || dataClass == class'BoolRef'
        ||  dataClass == class'ByteBox'     || dataClass == class'ByteRef'
        ||  dataClass == class'IntBox'      || dataClass == class'IntRef'
        ||  dataClass == class'FloatBox'    || dataClass == class'FloatRef'
        ||  dataClass == class'Text'        || dataClass == class'MutableText'
        ||  dataClass == class'ArrayList'   || dataClass == class'HashTable';
}

/**
 *  Uses given parser to parse a null JSON value ("null" in arbitrary case).
 *
 *  It does not matter what content follows parsed value in the `parser`,
 *  method will be successful as long as it manages to parse correct
 *  JSON null term (from the current `parser`'s position).
 *
 *  To check whether parsing have failed, simply check if `parser` is in
 *  a failed state after the method call.
 *
 *  @param  parser  Parser that method would use to parse JSON value from
 *      it's current position. It's confirmed state will not be changed.
 *      If parsing was successful it will point at the next available character.
 *      Parser will be in a failed state after this method iff
 *      parsing has failed.
 */
public final function TryNullWith(Parser parser)
{
    if (parser != none) {
        parser.Match(T(default.TNULL), SCASE_INSENSITIVE);
    }
}

/**
 *  Tries to parse null JSON value ("null" in arbitrary case) and reports
 *  whether parsing succeeded.
 *
 *  `source` must contain precisely a null JSON value and nothing else for this
 *  method to succeed. For example, even having leading/trailing whitespace
 *  symbols ("  null" or "null ") is enough to fail parsing.
 *
 *  @param  source  `Text` instance to parse JSON null value from.
 *  @return `true` if parsing succeeded and `false` otherwise.
 */
public final function bool IsNull(BaseText source)
{
    local bool      parsingSucceeded;
    local Parser    parser;
    if (source == none) return false;

    parser = _.text.Parse(source);
    parser.Match(T(default.TNULL), SCASE_INSENSITIVE);
    parsingSucceeded = parser.Ok() && parser.HasFinished();
    parser.FreeSelf();
    return parsingSucceeded;
}

/**
 *  Uses given parser to parse a JSON boolean ("true" or "false" with
 *  arbitrary case).
 *
 *  It does not matter what content follows parsed value in the `parser`,
 *  method will be successful as long as it manages to parse correct
 *  JSON boolean (from the current `parser`'s position).
 *
 *  To check whether parsing have failed, simply check if `parser` is in
 *  a failed state after the method call.
 *
 *  @param  parser  Parser that method would use to parse JSON value from
 *      it's current position. It's confirmed state will not be changed.
 *      If parsing was successful it will point at the next available character.
 *      Parser will be in a failed state after this method iff
 *      parsing has failed.
 *  @return Parsed boolean value if parsing was successful and
 *      `false` otherwise. To check for parsing success check the state of
 *      the `parser`.
 */
public final function bool ParseBooleanVariableWith(Parser parser)
{
    local Parser.ParserState initState;
    if (parser == none) return false;
    if (!parser.Ok())   return false;

    initState = parser.GetCurrentState();
    //  Check if we should return `true`
    if (parser.Match(T(default.TTRUE), SCASE_INSENSITIVE).Ok()) {
        return true;
    }
    //      We need to try parsing "false", so that we can use `parser`'s state
    //  to report about success of parsing; but we return `false` anyway.
    parser.RestoreState(initState).Match(T(default.TFALSE), SCASE_INSENSITIVE);
    return false;
}

/**
 *  Uses given parser to parse a JSON boolean ("true" or "false"
 *  with arbitrary case) into either `BoolBox` or `BoolRef`.
 *
 *  It does not matter what content follows parsed value in the `parser`,
 *  method will be successful as long as it manages to parse correct
 *  JSON boolean (from the current `parser`'s position).
 *
 *  To check whether parsing have failed, simply check if `parser` is in
 *  a failed state after the method call.
 *
 *  @param  parser          Parser that method would use to parse JSON value
 *      from it's current position. It's confirmed state will not be changed.
 *      If parsing was successful it will point at the next available character.
 *      Parser will be in a failed state after this method iff
 *      parsing has failed.
 *  @param  parseAsMutable  `true` if you want this method to return mutable
 *      object (`BoolRef`) and `false` if immutable (`BoolBox`).
 *  @return Parsed boolean value as an `AcediaObject` if parsing was successful
 *      and `none` otherwise. If parsing succeeded, it is guaranteed to
 *      be not `none` and have correct class, determined by
 *      `parseAsMutable` parameter.
 *      Returns `none` iff parsing has failed.
 */
public final function AcediaObject ParseBooleanWith(
    Parser          parser,
    optional bool   parseAsMutable)
{
    local bool result;
    if (parser == none) return none;

    result = ParseBooleanVariableWith(parser);
    if (!parser.Ok()) {
        return none;
    }
    if (parseAsMutable) {
        return _.ref.bool(result);
    }
    else {
        return _.box.bool(result);
    }
}

/**
 *  Parses a JSON boolean ("true" or "false" with arbitrary case) from
 *  a given `source` into either `BoolBox` or `BoolRef`.
 *
 *  `source` must contain precisely a boolean value and nothing else for this
 *  method to succeed. For example, even having leading/trailing whitespace
 *  symbols ("  true" or "false ") is enough to fail parsing.
 *
 *  @param  source  `Text` instance to parse JSON boolean value from.
 *  @param  parseAsMutable  `true` if you want this method to return mutable
 *      object (`BoolRef`) and `false` if immutable (`BoolBox`).
 *  @return Parsed boolean value as an `AcediaObject` if parsing was successful
 *      and `none` otherwise. If parsing succeeded, it is guaranteed to
 *      be not `none` and have correct class, determined by
 *      `parseAsMutable` parameter.
 *      Returns `none` iff parsing has failed.
 */
public final function AcediaObject ParseBoolean(
    BaseText        source,
    optional bool   parseAsMutable)
{
    local bool      result;
    local bool      parsingFailed;
    local Parser    parser;
    if (source == none) return none;

    parser = _.text.Parse(source);
    result = ParseBooleanVariableWith(parser);
    parsingFailed = !parser.Ok() || !parser.HasFinished();
    parser.FreeSelf();
    if (parsingFailed) {
        return none;
    }
    if (parseAsMutable) {
        return _.ref.bool(result);
    }
    else {
        return _.box.bool(result);
    }
}

/**
 *  Uses given parser to parse a JSON number into an integer.
 *
 *  If number is written in an "integer form" (not dot "." or exponent "e"),
 *  then it will be directly be parsed as an `int`. Otherwise it will be
 *  parsed as a `float` and the converted into `int`, with appropriate loss
 *  of precision.
 *
 *  It does not matter what content follows parsed value in the `parser`,
 *  method will be successful as long as it manages to parse a JSON number
 *  (from the current `parser`'s position).
 *
 *  To check whether parsing have failed, simply check if `parser` is in
 *  a failed state after the method call.
 *
 *  To parse a JSON number into a `float` use `ParseFloatVariableWith()` method.
 *
 *  @param  parser      Parser that method would use to parse JSON value from
 *      it's current position. It's confirmed state will not be changed.
 *      If parsing was successful it will point at the next available character.
 *      Parser will be in a failed state after this method iff
 *      parsing has failed.
 *  @param  integerOnly Setting this parameter to `true` will prevent method
 *      from parsing number as a `float` (and possibly losing precision):
 *      in case it is written in a `float`, parsing will be considered failed.
 *  @return Parsed integer value if parsing was successful and
 *      `0` otherwise. To check for parsing success check the state of
 *      the `parser`.
 */
public final function int ParseIntegerVariableWith(
    Parser          parser,
    optional bool   integerOnly)
{
    local int                   integerValue;
    local bool                  isInFloatForm;
    local float                 floatValue;
    local Parser.ParserState    initState, integerParsedState;
    if (parser == none) return 0;

    initState = parser.GetCurrentState();
    if (!parser.MInteger(integerValue, 10).Ok()) {
        return 0;
    }
    //  `integerParsedState` is guaranteed to be a successful state
    integerParsedState  = parser.GetCurrentState();
    //  JSON number recorded as float form will have either dot or exponent
    //  after the integer part.
    isInFloatForm = parser.Match(T(default.TDOT)).Ok();
    parser.RestoreState(integerParsedState);
    if (parser.Match(T(default.TEXPONENT), SCASE_INSENSITIVE).Ok()) {
        isInFloatForm = true;
    }
    //  For a number check if it can be parsed as a float specifically.
    //  If not - use parsed integer.
    parser.RestoreState(initState);
    if (isInFloatForm && parser.MNumber(floatValue).Ok())
    {
        if (integerOnly)
        {
            parser.Fail();
            return 0;
        }
        return int(floatValue);
    }
    parser.RestoreState(integerParsedState);
    return integerValue;
}

/**
 *  Uses given parser to parse a JSON number.
 *
 *  It does not matter what content follows parsed value in the `parser`,
 *  method will be successful as long as it manages to parse correct
 *  JSON number (from the current `parser`'s position).
 *
 *  To check whether parsing have failed, simply check if `parser` is in
 *  a failed state after the method call.
 *
 *  To parse a JSON number into an `int` use `ParseIntegerVariableWith()` method.
 *
 *  @param  parser  Parser that method would use to parse JSON value from
 *      it's current position. It's confirmed state will not be changed.
 *      If parsing was successful it will point at the next available character.
 *      Parser will be in a failed state after this method iff
 *      parsing has failed.
 *  @return Parsed number value if parsing was successful and
 *      `0.0` otherwise. To check for parsing success check the state of
 *      the `parser`.
 */
public final function float ParseFloatVariableWith(Parser parser)
{
    local float floatValue;
    if (parser == none)                     return 0.0;
    if (!parser.MNumber(floatValue).Ok())   return 0.0;

    return floatValue;
}

/**
 *  Uses given parser to parse a JSON number into one of the following
 *  object classes: `IntBox`, `IntRef`, `FloatBox`, `FloatRef`, depending on
 *  parameters and how numeric value is recorded.
 *
 *      To improve precision, this method will try to parse JSON number as
 *  an integer (`IntBox` or `IntRef`) if possible (if number does not include
 *  fractional or exponent parts: "." or "e").
 *      Otherwise it will parse number as a floating point value
 *  (`FloatBox` or `FloatRef`).
 *      The choice between box and reference is made depending on the method's
 *  parameter `parseAsMutable`.
 *
 *  It does not matter what content follows parsed value in the `parser`,
 *  method will be successful as long as it manages to parse correct
 *  JSON number (from the current `parser`'s position).
 *
 *  To check whether parsing have failed, simply check if `parser` is in
 *  a failed state after the method call.
 *
 *  @param  parser          Parser that method would use to parse JSON value
 *      from it's current position. It's confirmed state will not be changed.
 *      If parsing was successful it will point at the next available character.
 *      Parser will be in a failed state after this method iff
 *      parsing has failed.
 *  @param  parseAsMutable  `true` if you want this method to return mutable
 *      object (`IntRef` or `FloatRef`) and `false` if immutable
 *      (`IntBox` or `FloatBox`).
 *  @return Parsed number value as an `AcediaObject` if parsing was successful
 *      and `none` otherwise. If parsing succeeded, it is guaranteed to
 *      be not `none` and have correct class, determined partly by
 *      `parseAsMutable` parameter.
 *      Returns `none` iff parsing has failed.
 */
public final function AcediaObject ParseNumberWith(
    Parser          parser,
    optional bool   parseAsMutable)
{
    local int                   integerResult;
    local float                 floatResult;
    local Parser.ParserState    initState;
    if (parser == none) return none;

    initState = parser.GetCurrentState();
    //  Try parsing into `int`;
    //  this will fail if number recorded in floating format.
    integerResult = ParseIntegerVariableWith(parser, true);
    if (parser.Ok())
    {
        if (parseAsMutable) {
            return _.ref.int(integerResult);
        }
        else {
            return _.box.int(integerResult);
        }
    }
    //  If simple integer does not work - try to parse it as `float`
    floatResult = ParseFloatVariableWith(parser.RestoreState(initState));
    if (!parser.Ok()) {
        return none;
    }
    if (parseAsMutable) {
        return _.ref.float(floatResult);
    }
    else {
        return _.box.float(floatResult);
    }
}

/**
 *  Parses a JSON number from `source` into one of the following
 *  object classes: `IntBox`, `IntRef`, `FloatBox`, `FloatRef`, depending on
 *  parameters and how numeric value is recorded.
 *
 *      To improve precision, this method will try to parse JSON number as
 *  an integer (`IntBox` or `IntRef`) if possible (if number does not include
 *  fractional or exponent parts: "." or "e").
 *      Otherwise it will parse number as a floating point value
 *  (`FloatBox` or `FloatRef`).
 *      The choice between box and reference is made depending on the method's
 *  parameter `parseAsMutable`.
 *
 *  `source` must contain precisely a numeric value and nothing else for this
 *  method to succeed. For example, even having leading/trailing whitespace
 *  symbols ("  75.3" or "9 ") is enough to fail parsing.
 *
 *  @param  source          `Text` instance to parse JSON number from.
 *  @param  parseAsMutable  `true` if you want this method to return mutable
 *      object (`IntRef` or `FloatRef`) and `false` if immutable
 *      (`IntBox` or `FloatBox`).
 *  @return Parsed number value as an `AcediaObject` if parsing was successful
 *      and `none` otherwise. If parsing succeeded, it is guaranteed to
 *      be not `none` and have correct class, determined partly by
 *      `parseAsMutable` parameter.
 *      Returns `none` iff parsing has failed.
 */
public final function AcediaObject ParseNumber(
    BaseText        source,
    optional bool   parseAsMutable)
{
    local int       integerResult;
    local float     floatResult;
    local Parser    parser;
    parser = _.text.Parse(source);
    //  Try parsing into `int`;
    //  this will fail if number recorded in floating format.
    integerResult = ParseIntegerVariableWith(parser, true);
    if (parser.Ok() && parser.HasFinished())
    {
        parser.FreeSelf();
        if (parseAsMutable) {
            return _.ref.int(integerResult);
        }
        else {
            return _.box.int(integerResult);
        }
    }
    //  If simple integer does not work - try to parse it as `float`
    floatResult = ParseFloatVariableWith(parser.R());
    if (!parser.Ok() || !parser.HasFinished())
    {
        parser.FreeSelf();
        return none;
    }
    parser.FreeSelf();
    if (parseAsMutable) {
        return _.ref.float(floatResult);
    }
    else {
        return _.box.float(floatResult);
    }
}

/**
 *  Uses given parser to parse a JSON string.
 *
 *  It does not matter what content follows parsed value in the `parser`,
 *  method will be successful as long as it manages to parse correct
 *  JSON string (from the current `parser`'s position).
 *
 *  To check whether parsing have failed, simply check if `parser` is in
 *  a failed state after the method call.
 *
 *  @param  parser          Parser that method would use to parse JSON value
 *      from it's current position. It's confirmed state will not be changed.
 *      If parsing was successful it will point at the next available character.
 *      Parser will be in a failed state after this method iff
 *      parsing has failed.
 *  @param parseAsMutable   `true` if you want this method to return mutable
 *      object (`MutableText`) and `false` if immutable (`Text`).
 *  @return Parsed string value as `Text` or `MutableText` (depending on
 *      `parseAsMutable` parameter) if parsing was successful and
 *      `none` otherwise. To check for parsing success check the state of
 *      the `parser`.
 */
public final function BaseText ParseStringWith(
    Parser          parser,
    optional bool   parseAsMutable)
{
    local Text          immutableTextValue;
    local MutableText   mutableTextValue;
    if (parser == none) {
        return none;
    }
    parser.MStringLiteral(mutableTextValue);
    if (!parser.Ok()) {
        mutableTextValue.FreeSelf();
        return none;
    }
    if (parseAsMutable) {
        return mutableTextValue;
    }
    immutableTextValue = mutableTextValue.Copy();
    mutableTextValue.FreeSelf();
    return immutableTextValue;
}

/**
 *  Parses a JSON string from `source` into either `Text` or `MutableText`,
 *  depending on parameters.
 *
 *  `source` must contain precisely a JSON string value and nothing else for
 *  this method to succeed. For example, even having leading/trailing whitespace
 *  symbols ("  \"string!\"" or "\"another!\" ") is enough to fail parsing.
 *
 *  @param  source          `Text` instance to parse JSON string from.
 *  @param parseAsMutable   `true` if you want this method to return mutable
 *      object (`MutableText`) and `false` if immutable (`Text`).
 *  @return Parsed string value as `Text` or `MutableText` (depending on
 *      `parseAsMutable` parameter) if parsing was successful and
 *      `none` otherwise. To check for parsing success check the state of
 *      the `parser`.
 */
public final function BaseText ParseString(
    BaseText        source,
    optional bool   parseAsMutable)
{
    local bool          parsingSuccessful;
    local Parser        parser;
    local Text          immutableTextValue;
    local MutableText   mutableTextValue;
    parser = _.text.Parse(source);
    parsingSuccessful =
        parser.MStringLiteral(mutableTextValue).Ok() && parser.HasFinished();
    parser.FreeSelf();
    if (!parsingSuccessful) {
        mutableTextValue.FreeSelf();
        return none;
    }
    if (parseAsMutable) {
        return mutableTextValue;
    }
    immutableTextValue = mutableTextValue.Copy();
    mutableTextValue.FreeSelf();
    return immutableTextValue;
}

/**
 *  Uses given parser to parse a JSON array.
 *
 *  This method will parse JSON values that are contained in parsed JSON array
 *  according to description given for `ParseWith()` method.
 *
 *  It does not matter what content follows parsed value in the `parser`,
 *  method will be successful as long as it manages to parse correct
 *  JSON array (from the current `parser`'s position).
 *
 *  To check whether parsing have failed, simply check if `parser` is in
 *  a failed state after the method call.
 *
 *  @param  parser          Parser that method would use to parse JSON array
 *      from it's current position. It's confirmed state will not be changed.
 *      If parsing was successful it will point at the next available character.
 *      Parser will be in a failed state after this method iff
 *      parsing has failed.
 *  @param parseAsMutable   `true` if you want this method to parse array's
 *      items as mutable values and `false` otherwise (as immutable ones).
 *  @return Parsed JSON array as `ArrayList` if parsing was successful and
 *      `none` otherwise. To check for parsing success check the state of
 *      the `parser`.
 */
public final function ArrayList ParseArrayListWith(
    Parser          parser,
    optional bool   parseAsMutable)
{
    local bool                  parsingSucceeded;
    local Parser.ParserState    confirmedState;
    local AcediaObject          nextValue;
    local array<AcediaObject>   parsedValues;
    local ArrayList             result;

    if (parser == none) {
        return none;
    }
    confirmedState =
        parser.Skip().Match(T(default.TOPEN_BRACKET)).GetCurrentState();
    while (parser.Ok() && !parser.HasFinished())
    {
        confirmedState = parser.Skip().GetCurrentState();
        //  Check for JSON array ending and ONLY THEN declare parsing
        //  is successful, not encountering '}' implies bad JSON format.
        if (parser.Match(T(default.TCLOSE_BRACKET)).Ok()) {
            parsingSucceeded = true;
            break;
        }
        parser.RestoreState(confirmedState);
        //  Look for comma after each element
        if (parsedValues.length > 0)
        {
            if (!parser.Match(T(default.TCOMMA)).Skip().Ok()) {
                break;
            }
            confirmedState = parser.GetCurrentState();
        }
        //  Parse next value
        nextValue = ParseWith(parser, parseAsMutable);
        parsedValues[parsedValues.length] = nextValue;
        if (!parser.Ok()) {
            break;
        }
    }
    if (parsingSucceeded) {
        result = _.collections.NewArrayList(parsedValues);
    }
    else {
        parser.Fail();
    }
    _.memory.FreeMany(parsedValues);
    return result;
}

/**
 *  Uses given parser to parse a JSON object.
 *
 *  This method will parse JSON values that are contained in parsed JSON object
 *  according to description given for `ParseWith()` method.
 *
 *  It does not matter what content follows parsed value in the `parser`,
 *  method will be successful as long as it manages to parse correct
 *  JSON object (from the current `parser`'s position).
 *
 *  To check whether parsing have failed, simply check if `parser` is in
 *  a failed state after the method call.
 *
 *  @param  parser          Parser that method would use to parse JSON object
 *      from it's current position. It's confirmed state will not be changed.
 *      If parsing was successful it will point at the next available character.
 *      Parser will be in a failed state after this method iff
 *      parsing has failed.
 *  @param parseAsMutable   `true` if you want this method to parse object's
 *      items as mutable values and `false` otherwise (as immutable ones).
 *  @return Parsed JSON object as `HashTable` if parsing was successful
 *      and `none` otherwise. To check for parsing success check the state of
 *      the `parser`.
 */
public function HashTable ParseHashTableWith(
    Parser          parser,
    optional bool   parseAsMutable)
{
    local bool                      parsingSucceeded;
    local Parser.ParserState        confirmedState;
    local array<HashTable.Entry>    parsedEntries;
    local HashTable                 result;

    if (parser == none) {
        return none;
    }
    //  Ensure that parser starts pointing at what looks like a JSON object
    confirmedState =
        parser.Skip().Match(T(default.TOPEN_BRACE)).GetCurrentState();
    if (!parser.Ok()) {
        return none;
    }
    while (parser.Ok() && !parser.HasFinished())
    {
        confirmedState = parser.Skip().GetCurrentState();
        //  Check for JSON object ending and ONLY THEN declare parsing
        //  is successful, not encountering '}' implies bad JSON format.
        if (parser.Match(T(default.TCLOSE_BRACE)).Ok())
        {
            parsingSucceeded = true;
            break;
        }
        parser.RestoreState(confirmedState);
        //  Look for comma after each key-value pair
        if (parsedEntries.length > 0)
        {
            if (!parser.Match(T(default.TCOMMA)).Skip().Ok()) {
                break;
            }
            confirmedState = parser.GetCurrentState();
        }
        //  Parse property
        parsedEntries[parsedEntries.length] =
            ParseHashTableProperty(parser, parseAsMutable);
        if (!parser.Ok()) {
            break;
        }
    }
    if (parsingSucceeded) {
        result = _.collections.NewHashTable(parsedEntries);
    }
    else {
        parser.Fail();
    }
    FreeHashTableEntries(parsedEntries);
    return result;
}

//  TODO: ParseProperty
//  Parses a JSON key-value pair (there must not be any leading spaces).
private function HashTable.Entry ParseHashTableProperty(
    Parser  parser,
    bool    parseAsMutable)
{
    local MutableText       nextKey;
    local HashTable.Entry   entry;
    parser.MStringLiteral(nextKey).Skip().Match(T(default.TCOLON)).Skip();
    entry.key = nextKey.IntoText();
    entry.value = ParseWith(parser, parseAsMutable);
    return entry;
}

//  TODO: FreeEntries
//  Auxiliary method for deallocating unneeded objects in entry pairs.
private function FreeHashTableEntries(array<HashTable.Entry> entries)
{
    local int i;
    for (i = 0; i < entries.length; i += 1)
    {
        _.memory.Free(entries[i].key);
        _.memory.Free(entries[i].value);
    }
}

/**
 *  Uses given parser to parse a JSON value.
 *
 *  This method will parse JSON values that are contained in parsed JSON object
 *  according to description given for `ParseWith()` method.
 *
 *  Rules for determining types into which JSON value will be parsed:
 *      1. Null values will be returned as `none`;
 *      2. Number values will be return as an `IntBox`/`IntRef` if they consist
 *          of only digits (and optionally a sign) and `FloatBox`/`FloatRef`
 *          otherwise. Choice between box and ref is made based on
 *          `parseAsMutable` parameter (boxes are immutable, refs are mutable);
 *      3. String values will be parsed as `Text`/`MutableText`, based on
 *          `parseAsMutable` parameter;
 *      4. Array values will be parsed as a `ArrayList`s, their items parsed
 *          according to these rules (`parseAsMutable` parameter is propagated).
 *      5. Object values will be parsed as a `HashTable`s, their items
 *          parsed according to these rules (`parseAsMutable` parameter is
 *          propagated) and recorded under the keys parsed into `Text`.
 *
 *  It does not matter what content follows parsed value in the `parser`,
 *  method will be successful as long as it manages to parse correct
 *  JSON value (from the current `parser`'s position).
 *
 *  To check whether parsing have failed, simply check if `parser` is in
 *  a failed state after the method call.
 *
 *  @param  parser          Parser that method would use to parse JSON value
 *      from it's current position. It's confirmed state will not be changed.
 *      If parsing was successful it will point at the next available character.
 *      Parser will be in a failed state after this method iff
 *      parsing has failed.
 *  @param parseAsMutable   `true` if you want this method to parse value
 *      (and it's sub-items, if applicable) as mutable values and
 *      `false` if you want them to be immutable.
 *  @return Parsed JSON value as `AcediaObject` that has one of the classes
 *      described in parsing rules, `none` otherwise. To check for parsing
 *      success check the state of the `parser`. Note that method can also
 *      return `none` if parsed JSON value was "null".
 */
public final function AcediaObject ParseWith(
    Parser          parser,
    optional bool   parseAsMutable)
{
    local AcediaObject          result;
    local Parser.ParserState    initState;
    if (parser == none) return none;
    if (!parser.Ok())   return none;

    initState = parser.GetCurrentState();
    TryNullWith(parser);
    if (parser.Ok()) {
        return none;
    }
    result = ParseBooleanWith(parser.RestoreState(initState), parseAsMutable);
    if (parser.Ok()) {
        return result;
    }
    result = ParseNumberWith(parser.RestoreState(initState), parseAsMutable);
    if (parser.Ok()) {
        return result;
    }
    result = ParseStringWith(parser.RestoreState(initState), parseAsMutable);
    if (parser.Ok()) {
        return result;
    }
    result = ParseArrayListWith(
        parser.RestoreState(initState),
        parseAsMutable);
    if (parser.Ok()) {
        return result;
    }
    result = ParseHashTableWith(
        parser.RestoreState(initState),
        parseAsMutable);
    if (parser.Ok()) {
        return result;
    }
    return none;
}

/**
 *  "Prints" given `AcediaObject` value, saving it in JSON format.
 *
 *  "Prints" given `AcediaObject` in a minimal way, for a human-readable output
 *  use `PrettyPrint()` method.
 *
 *  Only certain classes (the same as the ones that can be parsed from JSON
 *  via this API) are supported:
 *      1. `none` is printed into "null";
 *      2. Boolean types (`BoolBox`/`BoolRef`) are printed into JSON bool value;
 *      3. Integer (`IntBox`/`IntRef`) and float (`FloatBox`/`FloatRef`) types
 *          are printed into JSON number value;
 *      4. `Text` and `MutableText` are printed into JSON string value;
 *      5. `ArrayList` is printed into JSON array with `Print()` method
 *          applied to each of it's items. If some of them have not printable
 *          types - "none" will be used as a fallback.
 *      6. `HashTable` is printed into JSON object with `Print()` method
 *          applied to each of it's items. Only items with `Text` keys are
 *          printed, the rest is omitted. If some of them have not printable
 *          types - "none" will be used as a fallback.
 *
 *  @param  toPrint Object to "print" into `MutableText`.
 *  @return Text version of given `toDisplay`, if it has one of the printable
 *      classes. Otherwise returns `none`.
 *      Note that `none` is considered printable and will produce "null".
 */
public final function MutableText Print(AcediaObject toPrint)
{
    if (toPrint == none) {
        return T(default.TNULL).MutableCopy();
    }
    if (toPrint.class == class'IntBox') {
        return _.text.FromIntM(IntBox(toPrint).Get());
    }
    if (toPrint.class == class'IntRef') {
        return _.text.FromIntM(IntRef(toPrint).Get());
    }
    if (toPrint.class == class'BoolBox') {
        return _.text.FromBoolM(BoolBox(toPrint).Get());
    }
    if (toPrint.class == class'BoolRef') {
        return _.text.FromBoolM(BoolRef(toPrint).Get());
    }
    if (toPrint.class == class'FloatBox') {
        return _.text.FromFloatM(FloatBox(toPrint).Get(), MAX_FLOAT_PRECISION);
    }
    if (toPrint.class == class'FloatRef') {
        return _.text.FromFloatM(FloatRef(toPrint).Get(), MAX_FLOAT_PRECISION);
    }
    if (    toPrint.class == class'Text'
        ||  toPrint.class == class'MutableText') {
        return DisplayText(BaseText(toPrint));
    }
    if (toPrint.class == class'ArrayList') {
        return PrintArrayList(ArrayList(toPrint));
    }
    if (toPrint.class == class'HashTable') {
        return PrintHashTable(HashTable(toPrint));
    }
    return none;
}

/**
 *  "Prints" given `ArrayList` value, saving it as a JSON array in
 *  `MutableText`.
 *
 *  "Prints" given `ArrayList` in a minimal way, for a human-readable output
 *  use `PrettyPrintArrayList()` method.
 *
 *      It's items must either be equal to `none` or have one of the following
 *  classes: `BoolBox`, `BoolRef`, `IntBox`, `IntRef`, `FloatBox`, `FloatRef`,
 *  `Text`, `MutableText`, `ArrayList`, `HashTable`.
 *      Otherwise items will be printed as "null" values.
 *      Also see `Print()` method.
 *
 *  @param  toPrint Array to "print" into `MutableText`.
 *  @return Text version of given `toPrint`, if it has one of the printable
 *      classes. Otherwise returns `none`.
 *      Note that `none` is considered printable and will produce "null".
 */
public final function MutableText PrintArrayList(ArrayList toPrint)
{
    local int           i, length;
    local AcediaObject  nextItem;
    local MutableText   result, printedItem;

    if (toPrint == none) {
        return none;
    }
    length = toPrint.GetLength();
    result = T(default.TOPEN_BRACKET).MutableCopy();
    for (i = 0; i < length; i += 1)
    {
        if (i > 0) {
            result.Append(T(default.TCOMMA));
        }
        nextItem = toPrint.GetItem(i);
        printedItem = Print(nextItem);
        _.memory.Free(nextItem);
        if (printedItem != none)
        {
            result.Append(printedItem);
            printedItem.FreeSelf();
        }
        else {
            result.Append(T(default.TNULL));
        }
    }
    result.Append(T(default.TCLOSE_BRACKET));
    return result;
}

/**
 *  "Prints" given `HashTable` value, saving it as a JSON object in
 *  `MutableText`.
 *
 *      "Prints" given `HashTable` in a minimal way, for
 *  a human-readable output use `PrettyPrintHashTable()` method.
 *
 *      Only prints items recorded with `Text` key, the rest is omitted.
 *
 *      It's items must either be equal to `none` or have one of the following
 *  classes: `BoolBox`, `BoolRef`, `IntBox`, `IntRef`, `FloatBox`, `FloatRef`,
 *  `Text`, `MutableText`, `ArrayList`, `HashTable`.
 *      Otherwise items will be printed as "null" values.
 *      Also see `Print()` method.
 *
 *  @param  toPrint Array to "print" into `MutableText`.
 *  @return Text version of given `toPrint`, if it has one of the printable
 *      classes. Otherwise returns `none`.
 *      Note that `none` is considered printable and will produce "null".
 */
public final function MutableText PrintHashTable(HashTable toPrint)
{
    local bool                  printedKeyValuePair;
    local CollectionIterator    iter;
    local Text                  nextKey;
    local AcediaObject          nextValue;
    local MutableText           result, printedKey, printedValue;

    if (toPrint == none) {
        return none;
    }
    result = T(default.TOPEN_BRACE).MutableCopy();
    iter = toPrint.Iterate();
    for (iter = toPrint.Iterate(); !iter.HasFinished(); iter.Next())
    {
        if (printedKeyValuePair) {
            result.Append(T(default.TCOMMA));
        }
        nextKey     = Text(iter.GetKey());
        nextValue   = iter.Get();
        if (nextKey == none || nextKey.class != class'Text')
        {
            _.memory.Free(nextKey);
            _.memory.Free(nextValue);
            continue;
        }
        printedKey      = DisplayText(nextKey);
        printedValue    = Print(nextValue);
        _.memory.Free(nextKey);
        _.memory.Free(nextValue);
        result.Append(printedKey).Append(T(default.TCOLON));
        printedKey.FreeSelf();
        if (printedValue != none)
        {
            result.Append(printedValue);
            printedValue.FreeSelf();
        }
        else {
            result.Append(T(default.TNULL));
        }
        printedKeyValuePair = true;
    }
    iter.FreeSelf();
    result.Append(T(default.TCLOSE_BRACE));
    return result;
}

/**
 *  "Prints" given `AcediaObject` value, saving it in JSON format.
 *
 *  "Prints" given `AcediaObject` in a human-readable way. For a minimal output
 *  use `Print()` method.
 *
 *  Only certain classes (the same as the ones that can be parsed from JSON
 *  via this API) are supported:
 *      1. `none` is printed into "null";
 *      2. Boolean types (`BoolBox`/`BoolRef`) are printed into JSON bool value;
 *      3. Integer (`IntBox`/`IntRef`) and float (`FloatBox`/`FloatRef`) types
 *          are printed into JSON number value;
 *      4. `Text` and `MutableText` are printed into JSON string value;
 *      5. `ArrayList` is printed into JSON array with `Print()` method
 *          applied to each of it's items. If some of them have not printable
 *          types - "none" will be used as a fallback.
 *      6. `HashTable` is printed into JSON object with `Print()` method
 *          applied to each of it's items. Only items with `Text` keys are
 *          printed, the rest is omitted. If some of them have not printable
 *          types - "none" will be used as a fallback.
 *
 *  @param  toPrint Object to "print" into `MutableText`.
 *  @return Text version of given `toDisplay`, if it has one of the printable
 *      classes. Otherwise returns `none`.
 *      Note that `none` is considered printable and will produce "null".
 */
public final function MutableText PrettyPrint(AcediaObject toPrint)
{
    local MutableText result;
    local MutableText accumulatedIndent;
    InitFormatting();
    accumulatedIndent = _.text.Empty();
    result = PrettyPrintWithIndent(toPrint, accumulatedIndent);
    accumulatedIndent.FreeSelf();
    return result;
}

/**
 *  "Prints" given `ArrayList` value, saving it as a JSON array in
 *  `MutableText`.
 *
 *  "Prints" given `ArrayList` in human-readable way, for minimal output
 *  use `PrintArrayList()` method.
 *
 *      It's items must either be equal to `none` or have one of the following
 *  classes: `BoolBox`, `BoolRef`, `IntBox`, `IntRef`, `FloatBox`, `FloatRef`,
 *  `Text`, `MutableText`, `ArrayList`, `HashTable`.
 *      Otherwise items will be printed as "null" values.
 *      Also see `Print()` method.
 *
 *  @param  toPrint Array to "print" into `MutableText`.
 *  @return Text version of given `toPrint`, if it has one of the printable
 *      classes. Otherwise returns `none`.
 *      Note that `none` is considered printable and will produce "null".
 */
public final function MutableText PrettyPrintArrayList(ArrayList toPrint)
{
    local MutableText result;
    local MutableText accumulatedIndent;

    InitFormatting();
    accumulatedIndent = _.text.Empty();
    result = PrettyPrintArrayListWithIndent(toPrint, accumulatedIndent);
    accumulatedIndent.FreeSelf();
    return result;
}

/**
 *  "Prints" given `HashTable` value, saving it as a JSON object in
 *  `MutableText`.
 *
 *      "Prints" given `HashTable` in a human readable way, for
 *  a minimal output use `PrintHashTable()` method.
 *
 *      Only prints items recorded with `Text` key, the rest is omitted.
 *
 *      It's items must either be equal to `none` or have one of the following
 *  classes: `BoolBox`, `BoolRef`, `IntBox`, `IntRef`, `FloatBox`, `FloatRef`,
 *  `Text`, `MutableText`, `ArrayList`, `HashTable`.
 *      Otherwise items will be printed as "null" values.
 *      Also see `Print()` method.
 *
 *  @param  toPrint Array to "print" into `MutableText`.
 *  @return Text version of given `toPrint`, if it has one of the printable
 *      classes. Otherwise returns `none`.
 *      Note that `none` is considered printable and will produce "null".
 */
public final function MutableText PrettyPrintHashTable(HashTable toPrint)
{
    local MutableText result;
    local MutableText accumulatedIndent;

    InitFormatting();
    accumulatedIndent = _.text.Empty();
    result = PrettyPrintHashTableWithIndent(toPrint, accumulatedIndent);
    accumulatedIndent.FreeSelf();
    return result;
}

//      Does the actual job for `PrettyPrint()` method.
//      Separated to hide `accumulatedIndent` parameter that is necessary for
//  pretty printing.
//      Assumes `InitFormatting()` was made and json formatting variables are
//  initialized.
private final function MutableText PrettyPrintWithIndent(
    AcediaObject            toPrint,
    optional MutableText    accumulatedIndent)
{
    if (toPrint == none) {
        return T(default.TNULL).MutableCopy().ChangeFormatting(jNull);
    }
    if (toPrint.class == class'IntBox') {
        return _.text.FromIntM(IntBox(toPrint).Get()).ChangeFormatting(jNumber);
    }
    if (toPrint.class == class'IntRef') {
        return _.text.FromIntM(IntRef(toPrint).Get()).ChangeFormatting(jNumber);
    }
    if (toPrint.class == class'BoolBox')
    {
        return _.text.FromBoolM(BoolBox(toPrint).Get())
            .ChangeFormatting(jBoolean);
    }
    if (toPrint.class == class'BoolRef')
    {
        return _.text.FromBoolM(BoolRef(toPrint).Get())
            .ChangeFormatting(jBoolean);
    }
    if (toPrint.class == class'FloatBox')
    {
        return _.text.FromFloatM(FloatBox(toPrint).Get(), MAX_FLOAT_PRECISION)
            .ChangeFormatting(jNumber);
    }
    if (toPrint.class == class'FloatRef')
    {
        return _.text.FromFloatM(FloatRef(toPrint).Get(), MAX_FLOAT_PRECISION)
            .ChangeFormatting(jNumber);
    }
    if (    toPrint.class == class'Text'
        ||  toPrint.class == class'MutableText')
    {
        return DisplayText(BaseText(toPrint)).ChangeFormatting(jString);
    }
    if (toPrint.class == class'ArrayList')
    {
        return PrettyPrintArrayListWithIndent(  ArrayList(toPrint),
                                                accumulatedIndent);
    }
    if (toPrint.class == class'HashTable') {
        return PrettyPrintHashTableWithIndent(  HashTable(toPrint),
                                                accumulatedIndent);
    }
    return none;
}

//      Does the actual job for `PrettyPrintArray()` method.
//      Separated to hide `accumulatedIndent` parameter that is necessary for
//  pretty printing.
//      Assumes `InitFormatting()` was made and json formatting variables are
//  initialized.
private final function MutableText PrettyPrintArrayListWithIndent(
    ArrayList   toPrint,
    MutableText accumulatedIndent)
{
    local int           i, length;
    local AcediaObject  nextItem;
    local MutableText   extendedIndent;
    local MutableText   result, printedItem;

    if (toPrint == none) {
        return none;
    }
    length = toPrint.GetLength();
    extendedIndent = accumulatedIndent.MutableCopy().Append(T(TJSON_INDENT));
    result = T(default.TOPEN_BRACKET).MutableCopy()
        .ChangeFormatting(jArrayBraces);
    for (i = 0; i < length; i += 1)
    {
        if (i > 0) {
            result.Append(T(default.TCOMMA), jComma);
        }
        nextItem = toPrint.GetItem(i);
        printedItem = PrettyPrintWithIndent(nextItem, extendedIndent);
        _.memory.Free(nextItem);
        if (printedItem != none)
        {
            result.AppendLineBreak().Append(extendedIndent).Append(printedItem);
            printedItem.FreeSelf();
        }
        else {
            result.Append(T(default.TNULL), jNull);
        }
    }
    if (i > 0) {
        result.AppendLineBreak().Append(accumulatedIndent);
    }
    result.Append(T(default.TCLOSE_BRACKET), jArrayBraces);
    extendedIndent.FreeSelf();
    return result;
}

//      Does the actual job for `PrettyPrintHashTable()` method.
//      Separated to hide `accumulatedIndent` parameter that is necessary for
//  pretty printing.
//      Assumes `InitFormatting()` was made and json formatting variables are
//  initialized.
private final function MutableText PrettyPrintHashTableWithIndent(
    HashTable   toPrint,
    MutableText accumulatedIndent)
{
    local bool                  printedKeyValuePair;
    local CollectionIterator    iter;
    local Text                  nextKey;
    local AcediaObject          nextValue;
    local MutableText           extendedIndent;
    local MutableText           result;
    if (toPrint == none) {
        return none;
    }
    extendedIndent = accumulatedIndent.MutableCopy().Append(T(TJSON_INDENT));
    result = T(default.TOPEN_BRACE).MutableCopy()
        .ChangeFormatting(jObjectBraces);
    iter = toPrint.Iterate();
    for (iter = toPrint.Iterate(); !iter.HasFinished(); iter.Next())
    {
        if (printedKeyValuePair) {
            result.Append(T(default.TCOMMA), jComma);
        }
        nextKey     = Text(iter.GetKey());
        nextValue   = iter.Get();
        if (nextKey == none || nextKey.class != class'Text')
        {
            _.memory.Free(nextKey);
            _.memory.Free(nextValue);
            continue;
        }
        PrettyPrintKeyValue(result, nextKey, nextValue, extendedIndent);
        printedKeyValuePair = true;
        _.memory.Free(nextKey);
        _.memory.Free(nextValue);
    }
    if (printedKeyValuePair) {
        result.AppendLineBreak().Append(accumulatedIndent);
    }
    iter.FreeSelf();
    result.Append(T(default.TCLOSE_BRACE), jObjectBraces);
    extendedIndent.FreeSelf();
    return result;
}

//      Auxiliary method for printing key-value pair into the `builder`.
//  `accumulatedIndent` is necessary in case passed `value` is
//  an object or array.
//      Assumes `InitFormatting()` was made and json formatting variables are
//  initialized.
private final function PrettyPrintKeyValue(
    MutableText     builder,
    BaseText        nextKey,
    AcediaObject    nextValue,
    MutableText     accumulatedIndent)
{
    local MutableText printedKey, printedValue;
    printedKey      = DisplayText(nextKey).ChangeFormatting(jPropertyName);
    printedValue    = PrettyPrintWithIndent(nextValue, accumulatedIndent);
    builder.AppendLineBreak()
        .Append(accumulatedIndent)
        .Append(printedKey)
        .Append(T(default.TCOLON_SPACE), jColon);
    printedKey.FreeSelf();
    if (printedValue != none)
    {
        builder.Append(printedValue);
        printedValue.FreeSelf();
    }
    else {
        builder.Append(T(default.TNULL), jNull);
    }
}

//      Auxiliary method to convert `Text` into it's JSON "string"
//  representation.
//      We can't just dump `original`'s contents into JSON output as is,
//  since we have to replace several special characters with escaped sequences.
private final function MutableText DisplayText(BaseText original)
{
    local int                   i, length;
    local MutableText           result;
    local BaseText.Character    nextCharacter;
    local BaseText.Character    reverseSolidus;
    reverseSolidus = _.text.CharacterFromCodePoint(CODEPOINT_REVERSE_SOLIDUS);
    result = T(TQUOTE).MutableCopy();
    length = original.GetLength();
    for (i = 0; i < length; i += 1)
    {
        nextCharacter = original.GetCharacter(i);
        if (DoesNeedEscaping(nextCharacter.codePoint))
        {
            result.AppendCharacter(reverseSolidus);
            nextCharacter.codePoint =
                GetEscapedVersion(nextCharacter.codePoint);
            result.AppendCharacter(nextCharacter);
        }
        else {
            result.AppendCharacter(nextCharacter);
        }
    }
    result.Append(T(TQUOTE));
    return result;
}

//  Checks whether a certain character (code point) needs to be replaced for
//  JSON printing.
private final function bool DoesNeedEscaping(int codePoint)
{
    if (codePoint == CODEPOINT_REVERSE_SOLIDUS) return true;
    if (codePoint == CODEPOINT_CARRIAGE_RETURN) return true;
    if (codePoint == CODEPOINT_QUOTATION_MARK)  return true;
    if (codePoint == CODEPOINT_BACKSPACE)       return true;
    if (codePoint == CODEPOINT_FORM_FEED)       return true;
    if (codePoint == CODEPOINT_LINE_FEED)       return true;
    if (codePoint == CODEPOINT_SOLIDUS)         return true;
    if (codePoint == CODEPOINT_TAB)             return true;
    return false;
}

//      Replaces code point with it's escaped letter.
//      When printing text into JSON some characters need to be escaped
//  (see `DoesNeedEscaping()`), but while some can use themselves in escaped
//  sequence ("\""), some need to be replaced with a different character ("\n").
private final function int GetEscapedVersion(int codePoint)
{
    if (codePoint == CODEPOINT_BACKSPACE) {
        return CODEPOINT_SMALL_B;
    }
    else if (codePoint == CODEPOINT_FORM_FEED) {
        return CODEPOINT_SMALL_F;
    }
    else if (codePoint == CODEPOINT_LINE_FEED) {
        return CODEPOINT_SMALL_N;
    }
    else if (codePoint == CODEPOINT_CARRIAGE_RETURN) {
        return CODEPOINT_SMALL_R;
    }
    else if (codePoint == CODEPOINT_TAB) {
        return CODEPOINT_SMALL_T;
    }
    return codePoint;
}

defaultproperties
{
    MAX_FLOAT_PRECISION = 4
    TNULL               = 0
    stringConstants(0)  = "null"
    TTRUE               = 1
    stringConstants(1)  = "true"
    TFALSE              = 2
    stringConstants(2)  = "false"
    TDOT                = 3
    stringConstants(3)  = "."
    TEXPONENT           = 4
    stringConstants(4)  = "e"
    TOPEN_BRACKET       = 5
    stringConstants(5)  = "["
    TCLOSE_BRACKET      = 6
    stringConstants(6)  = "]"
    TOPEN_BRACE         = 7
    stringConstants(7)  = "&{"
    TCLOSE_BRACE        = 8
    stringConstants(8)  = "&}"
    TCOMMA              = 9
    stringConstants(9)  = ","
    TCOLON              = 10
    stringConstants(10) = ":"
    TQUOTE              = 11
    stringConstants(11) = "\""
    TJSON_INDENT        = 12
    stringConstants(12) = "  "
    TCOLON_SPACE        = 13
    stringConstants(13) = ": "

    CODEPOINT_BACKSPACE         = 8
    CODEPOINT_TAB               = 9
    CODEPOINT_LINE_FEED         = 10
    CODEPOINT_FORM_FEED         = 12
    CODEPOINT_CARRIAGE_RETURN   = 13
    CODEPOINT_QUOTATION_MARK    = 34
    CODEPOINT_SOLIDUS           = 47
    CODEPOINT_REVERSE_SOLIDUS   = 92
    CODEPOINT_SMALL_B           = 98
    CODEPOINT_SMALL_F           = 102
    CODEPOINT_SMALL_N           = 110
    CODEPOINT_SMALL_R           = 114
    CODEPOINT_SMALL_T           = 116
}