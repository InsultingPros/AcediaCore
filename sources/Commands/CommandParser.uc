/**
 *  Auxiliary class for parsing user's input into a `Command.CallData` based on
 *  a given `Command.Data`. While it's meant to be allocated for
 *  a `self.ParseWith()` call and deallocated right after, it can be reused
 *  without deallocation.
 *      Copyright 2021 - 2022 Anton Tarasenko
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
class CommandParser extends AcediaObject
    dependson(Command);

/**
 *      `CommandParser` stores both it's state and command data, relevant to
 *  parsing, as it's member variables during the whole parsing process,
 *  instead of passing that data around in every single method.
 *
 *      We will give a brief overview of how around 20 parsing methods below
 *  are interconnected.
 *      The only public method `ParseWith()` is used to start parsing and it
 *  uses `PickSubCommand()` to first try and figure out what sub command is
 *  intended by user's input.
 *      Main bulk of the work is done by `ParseParameterArrays()` method,
 *  for simplicity broken into two `ParseRequiredParameterArray()` and
 *  `ParseOptionalParameterArray()` methods that can parse parameters for both
 *  command itself and it's options.
 *      They go through arrays of required and optional parameters,
 *  calling `ParseParameter()` for each parameters, which in turn can make
 *  several calls of `ParseSingleValue()` to parse parameters' values:
 *  it is called once for single-valued parameters, but possibly several times
 *  for list parameters that can contain several values.
 *      So main parsing method looks something like:
 *  ParseParameterArrays() {
 *      loop ParseParameter() {
 *          loop ParseSingleValue()
 *      }
 *  }
 *      `ParseSingleValue()` is essentially that redirects it's method call to
 *  another, more specific, parsing method based on the parameter type.
 *
 *      Finally, to allow users to specify options at any point in command,
 *  we call `TryParsingOptions()` at the beginning of every
 *  `ParseSingleValue()` (the only parameter that has higher priority than
 *  options is `CPT_Remainder`), since option definition can appear at any place
 *  between parameters. We also call `TryParsingOptions()` *after* we've parsed
 *  all command's parameters, since that case won't be detected by parsing
 *  them *before* every parameter.
 *      `TryParsingOptions()` itself simply tries to detect "-" and "--"
 *  prefixes (filtering out negative numeric values) and then redirect the call
 *  to either of more specialized methods: `ParseLongOption()` or
 *  `ParseShortOption()`, that can in turn make another `ParseParameterArrays()`
 *  call, if specified option has parameters.
 *      NOTE: `ParseParameterArrays()` can only nest in itself once, since
 *  option declaration always interrupts previous option's parameter list.
 *      Rest of the methods perform simple auxiliary functions.
 */

//  Parser filled with user input.
var private Parser                  commandParser;
//  Data for sub-command specified by both command we are parsing
//  and user's input; determined early during parsing.
var private Command.SubCommand      pickedSubCommand;
//  Options available for the command we are parsing.
var private array<Command.Option>   availableOptions;
//  Result variable we are filling during the parsing process,
//  should be `none` outside of `self.ParseWith()` method call.
var private Command.CallData        nextResult;

//      Describes which parameters we are currently parsing, classifying them
//  as either "necessary" or "extra".
//  E.g. if last require parameter is a list of integers,
//  then after parsing first integer we are:
//      * Still parsing required *parameter* "integer list";
//      * But no more integers are *necessary* for successful parsing.
//
//      Therefore we consider parameter "necessary" if the lack of it will
//  result in failed parsing and "extra" otherwise.
enum ParsingTarget
{
    //      We are in the process of parsing required parameters, that must all
    //  be present.
    //      This case does not include parsing last required parameter: it needs
    //  to be treated differently to track when we change from "necessary" to
    //  "extra" parameters.
    CPT_NecessaryParameter,
    //  We are parsing last necessary parameter.
    CPT_LastNecessaryParameter,
    //  We are not parsing extra parameters that can be safely omitted.
    CPT_ExtraParameter,
};

//  Current `ParsingTarget`, see it's enum description for more details
var private ParsingTarget           currentTarget;
//  `true` means we are parsing parameters for a command's option and
//  `false` means we are parsing command's own parameters
var private bool                    currentTargetIsOption;
//  If we are parsing parameters for an option (`currentTargetIsOption == true`)
//  this variable will store that option's data.
var private Command.Option          targetOption;
//  Last successful state of `commandParser`.
var Parser.ParserState              confirmedState;
//  Options we have so far encountered during parsing, necessary since we want
//  to forbid specifying th same option more than once.
var private array<Command.Option>   usedOptions;

//  Literals that can be used as boolean values
var private array<string> booleanTrueEquivalents;
var private array<string> booleanFalseEquivalents;

var LoggerAPI.Definition errNoSubCommands;

protected function Finalizer()
{
    Reset();
}

//  Zero important variables
private final function Reset()
{
    local Command.CallData blankCallData;
    commandParser           = none;
    nextResult              = blankCallData;
    currentTarget           = CPT_NecessaryParameter;
    currentTargetIsOption   = false;
    usedOptions.length      = 0;
}

//  Auxiliary method for recording errors
private final function DeclareError(
    Command.ErrorType   type,
    optional BaseText   cause)
{
    nextResult.parsingError = type;
    if (cause != none) {
        nextResult.errorCause = cause.Copy();
    }
    if (commandParser != none) {
        commandParser.Fail();
    }
}

//      Assumes `commandParser != none`, is in successful state.
//      Picks a sub command based on it's contents (parser's pointer must be
//  before where subcommand's name is specified).
private final function PickSubCommand(Command.Data commandData)
{
    local int                       i;
    local MutableText               candidateSubCommandName;
    local Command.SubCommand        emptySubCommand;
    local array<Command.SubCommand> allSubCommands;
    allSubCommands = commandData.subCommands;
    if (allSubcommands.length == 0)
    {
        _.logger.Auto(errNoSubCommands).ArgClass(class);
        pickedSubCommand = emptySubCommand;
        return;
    }
    //  Get candidate name
    confirmedState = commandParser.GetCurrentState();
    commandParser.Skip().MUntil(candidateSubCommandName,, true);
    //  Try matching it to sub commands
    pickedSubCommand = allSubcommands[0];
    if (candidateSubCommandName.IsEmpty())
    {
        candidateSubCommandName.FreeSelf();
        return;
    }
    for (i = 0; i < allSubcommands.length; i += 1)
    {
        if (candidateSubCommandName.Compare(allSubcommands[i].name))
        {
            candidateSubCommandName.FreeSelf();
            pickedSubCommand = allSubcommands[i];
            return;
        }
    }
    //  We will only reach here if we did not match any sub commands,
    //  meaning that whatever consumed by `candidateSubCommandName` probably
    //  has a different meaning.
    commandParser.RestoreState(confirmedState);
}

/**
 *  Parses user's input given in `parser` using command's information given by
 *  `commandData`.
 *
 *  @param  parser      `Parser`, initialized with user's input that will need
 *      to be parsed as a command's call.
 *  @param  commandData Describes what parameters and options should be
 *      expected in user's input. `Text` values from `commandData` can be used
 *      inside resulting `Command.CallData`, so deallocating them can
 *      invalidate returned value.
 *  @return Results of parsing, described by `Command.CallData`.
 *      Returned object is guaranteed to be not `none`.
 */
public final function Command.CallData ParseWith(
    Parser          parser,
    Command.Data    commandData)
{
    local HashTable         commandParameters;
    //  Temporary object to return `nextResult` while setting variable to `none`
    local Command.CallData  toReturn;
    nextResult.parameters   = _.collections.EmptyHashTable();
    nextResult.options      = _.collections.EmptyHashTable();
    if (commandData.subCommands.length == 0)
    {
        DeclareError(CET_NoSubCommands, none);
        toReturn = nextResult;
        Reset();
        return toReturn;
    }
    if (parser == none || !parser.Ok())
    {
        DeclareError(CET_BadParser, none);
        toReturn = nextResult;
        Reset();
        return toReturn;
    }
    commandParser = parser;
    availableOptions = commandData.options;
    //  (subcommand) (parameters, possibly with options) and nothing else!
    PickSubCommand(commandData);
    nextResult.subCommandName = pickedSubCommand.name.Copy();
    commandParameters   = ParseParameterArrays( pickedSubCommand.required,
                                                pickedSubCommand.optional);
    AssertNoTrailingInput();    //  make sure there is nothing else
    if (commandParser.Ok()) {
        nextResult.parameters = commandParameters;
    }
    else {
        _.memory.Free(commandParameters);
    }
    //  Clean up
    toReturn = nextResult;
    Reset();
    return toReturn;
}

//  Assumes `commandParser` is not `none`
//  Declares an error if `commandParser` still has any input left
private final function AssertNoTrailingInput()
{
    local Text remainder;
    if (!commandParser.Ok())                            return;
    if (commandParser.Skip().GetRemainingLength() <= 0) return;

    remainder = commandParser.GetRemainder();
    DeclareError(CET_UnusedCommandParameters, remainder);
    remainder.FreeSelf();
}

//      Assumes `commandParser` is not `none`.
//      Parses given required and optional parameters along with any
//  possible option declarations.
//      Returns `HashTable` filled with (variable, parsed value) pairs.
//      Failure is equal to `commandParser` entering into a failed state.
private final function HashTable ParseParameterArrays(
    array<Command.Parameter> requiredParameters,
    array<Command.Parameter> optionalParameters)
{
    local HashTable parsedParameters;
    if (!commandParser.Ok()) {
        return none;
    }
    parsedParameters = _.collections.EmptyHashTable();
    //  Parse parameters
    ParseRequiredParameterArray(parsedParameters, requiredParameters);
    ParseOptionalParameterArray(parsedParameters, optionalParameters);
    //  Parse trailing options
    while (TryParsingOptions());
    return parsedParameters;
}

//      Assumes `commandParser` and `parsedParameters` are not `none`.
//      Parses given required parameters along with any possible option
//  declarations into given `parsedParameters` `HashTable`.
private final function ParseRequiredParameterArray(
    HashTable                   parsedParameters,
    array<Command.Parameter>    requiredParameters)
{
    local int i;
    if (!commandParser.Ok()) {
        return;
    }
    currentTarget = CPT_NecessaryParameter;
    while (i < requiredParameters.length)
    {
        if (i == requiredParameters.length - 1) {
            currentTarget = CPT_LastNecessaryParameter;
        }
        //  Parse parameters one-by-one, reporting appropriate errors
        if (!ParseParameter(parsedParameters, requiredParameters[i]))
        {
            //  Any failure to parse required parameter leads to error
            if (currentTargetIsOption)
            {
                DeclareError(   CET_NoRequiredParamForOption,
                                targetOption.longName);
            }
            else
            {
                DeclareError(   CET_NoRequiredParam,
                                requiredParameters[i].displayName);
            }
            return;
        }
        i += 1;
    }
    currentTarget = CPT_ExtraParameter;
}

//      Assumes `commandParser` and `parsedParameters` are not `none`.
//      Parses given optional parameters along with any possible option
//  declarations into given `parsedParameters` hash table.
private final function ParseOptionalParameterArray(
    HashTable                   parsedParameters,
    array<Command.Parameter>    optionalParameters)
{
    local int i;
    if (!commandParser.Ok()) {
        return;
    }
    while (i < optionalParameters.length)
    {
        confirmedState = commandParser.GetCurrentState();
        //  Parse parameters one-by-one, reporting appropriate errors
        if (!ParseParameter(parsedParameters, optionalParameters[i]))
        {
            //  Propagate errors
            if (nextResult.parsingError != CET_None) {
                return;
            }
            //  Failure to parse optional parameter is fine if
            //  it is caused by that parameters simply missing
            commandParser.RestoreState(confirmedState);
            break;
        }
        i += 1;
    }
}

//      Assumes `commandParser` and `parsedParameters` are not `none`.
//      Parses one given parameter along with any possible option
//  declarations into given `parsedParameters` `HashTable`.
//      Returns `true` if we've successfully parsed given parameter without
//  any errors.
private final function bool ParseParameter(
    HashTable           parsedParameters,
    Command.Parameter   expectedParameter)
{
    local bool parsedEnough;
    confirmedState = commandParser.GetCurrentState();
    while (ParseSingleValue(parsedParameters, expectedParameter))
    {
        if (currentTarget == CPT_LastNecessaryParameter) {
            currentTarget = CPT_ExtraParameter;
        }
        parsedEnough = true;
        //  We are done if there is either no more input or we only needed
        //  to parse a single value
        if (!expectedParameter.allowsList) {
            return true;
        }
        if (commandParser.Skip().HasFinished()) {
            return true;
        }
        confirmedState = commandParser.GetCurrentState();
    }
    //  We only succeeded in parsing if we've parsed enough for
    //  a given parameter and did not encounter any errors
    if (parsedEnough && nextResult.parsingError == CET_None) {
        commandParser.RestoreState(confirmedState);
        return true;
    }
    //  Clean up any values `ParseSingleValue` might have recorded
    parsedParameters.RemoveItem(expectedParameter.variableName);
    return false;
}

//      Assumes `commandParser` and `parsedParameters` are not `none`.
//      Parses a single value for a given parameter (e.g. one integer for
//  integer or integer list parameter types) along with any possible option
//  declarations into given `parsedParameters` `HashTable`.
//      Returns `true` if we've successfully parsed a single value without
//  any errors.
private final function bool ParseSingleValue(
    HashTable           parsedParameters,
    Command.Parameter   expectedParameter)
{
    //      Before parsing any other value we need to check if user has
    //  specified any options instead.
    //      However this might lead to errors if we are already parsing
    //  necessary parameters of another option:
    //  we must handle such situation and report an error.
    if (currentTargetIsOption)
    {
        //  There is no problem is option's parameter is remainder
        if (expectedParameter.type == CPT_Remainder) {
            return ParseRemainderValue(parsedParameters, expectedParameter);
        }
        if (currentTarget != CPT_ExtraParameter && TryParsingOptions())
        {
            DeclareError(CET_NoRequiredParamForOption, targetOption.longName);
            return false;
        }
    }
    while (TryParsingOptions());
    //  First we try `CPT_Remainder` parameter, since it is a special case that
    //  consumes all further input
    if (expectedParameter.type == CPT_Remainder) {
        return ParseRemainderValue(parsedParameters, expectedParameter);
    }
    //  Propagate errors after parsing options
    if (nextResult.parsingError != CET_None) {
        return false;
    }
    //  Try parsing one of the variable types
    if (expectedParameter.type == CPT_Boolean) {
        return ParseBooleanValue(parsedParameters, expectedParameter);
    }
    else if (expectedParameter.type == CPT_Integer) {
        return ParseIntegerValue(parsedParameters, expectedParameter);
    }
    else if (expectedParameter.type == CPT_Number) {
        return ParseNumberValue(parsedParameters, expectedParameter);
    }
    else if (expectedParameter.type == CPT_Text) {
        return ParseTextValue(parsedParameters, expectedParameter);
    }
    else if (expectedParameter.type == CPT_Remainder) {
        return ParseRemainderValue(parsedParameters, expectedParameter);
    }
    else if (expectedParameter.type == CPT_Object) {
        return ParseObjectValue(parsedParameters, expectedParameter);
    }
    else if (expectedParameter.type == CPT_Array) {
        return ParseArrayValue(parsedParameters, expectedParameter);
    }
    return false;
}

//      Assumes `commandParser` and `parsedParameters` are not `none`.
//      Parses a single boolean value into given `parsedParameters`
//  hash table.
private final function bool ParseBooleanValue(
    HashTable           parsedParameters,
    Command.Parameter   expectedParameter)
{
    local int           i;
    local bool          isValidBooleanLiteral;
    local bool          booleanValue;
    local MutableText   parsedLiteral;
    commandParser.Skip().MUntil(parsedLiteral,, true);
    if (!commandParser.Ok())
    {
        _.memory.Free(parsedLiteral);
        return false;
    }
    //  Try to match parsed literal to any recognizable boolean literals
    for (i = 0; i < booleanTrueEquivalents.length; i += 1)
    {
        if (parsedLiteral.CompareToString( booleanTrueEquivalents[i],
                                                SCASE_INSENSITIVE))
        {
            isValidBooleanLiteral   = true;
            booleanValue            = true;
            break;
        }
    }
    for (i = 0; i < booleanFalseEquivalents.length; i += 1)
    {
        if (isValidBooleanLiteral) break;
        if (parsedLiteral.CompareToString( booleanFalseEquivalents[i],
                                                SCASE_INSENSITIVE))
        {
            isValidBooleanLiteral   = true;
            booleanValue            = false;
        }
    }
    parsedLiteral.FreeSelf();
    if (!isValidBooleanLiteral) {
        return false;
    }
    RecordParameter(parsedParameters, expectedParameter,
                    _.box.bool(booleanValue));
    return true;
}

//      Assumes `commandParser` and `parsedParameters` are not `none`.
//      Parses a single integer value into given `parsedParameters`
//  hash table.
private final function bool ParseIntegerValue(
    HashTable           parsedParameters,
    Command.Parameter   expectedParameter)
{
    local int integerValue;
    commandParser.Skip().MInteger(integerValue);
    if (!commandParser.Ok()) {
        return false;
    }
    RecordParameter(parsedParameters, expectedParameter,
                    _.box.int(integerValue));
    return true;
}

//      Assumes `commandParser` and `parsedParameters` are not `none`.
//      Parses a single number (float) value into given `parsedParameters`
//  hash table.
private final function bool ParseNumberValue(
    HashTable           parsedParameters,
    Command.Parameter   expectedParameter)
{
    local float numberValue;
    commandParser.Skip().MNumber(numberValue);
    if (!commandParser.Ok()) {
        return false;
    }
    RecordParameter(parsedParameters, expectedParameter,
                    _.box.float(numberValue));
    return true;
}

//      Assumes `commandParser` and `parsedParameters` are not `none`.
//      Parses a single `Text` value into given `parsedParameters`
//  hash table.
private final function bool ParseTextValue(
    HashTable           parsedParameters,
    Command.Parameter   expectedParameter)
{
    local bool                  failedParsing;
    local string                textValue;
    local parser.ParserState    initialState;
    //  TODO: use parsing methods into `Text`
    //  (needs some work for reading formatting `string`s from `Text` objects)
    initialState = commandParser.Skip().GetCurrentState();
    //  Try manually parsing as a string literal first, since then we will
    //  allow empty `textValue` as a result
    commandParser.MStringLiteralS(textValue);
    failedParsing = !commandParser.Ok();
    //  Otherwise - empty values are not allowed
    if (failedParsing)
    {
        commandParser.RestoreState(initialState).MStringS(textValue);
        failedParsing = (!commandParser.Ok() || textValue == "");
    }
    if (failedParsing)
    {
        commandParser.Fail();
        return false;
    }
    RecordParameter(parsedParameters, expectedParameter,
                    _.text.FromString(textValue));
    return true;
}

//      Assumes `commandParser` and `parsedParameters` are not `none`.
//      Parses a single `Text` value into given `parsedParameters`
//  hash table, consuming all remaining contents.
private final function bool ParseRemainderValue(
    HashTable           parsedParameters,
    Command.Parameter   expectedParameter)
{
    local MutableText value;

    commandParser.Skip().MUntil(value);
    if (!commandParser.Ok()) {
        return false;
    }
    RecordParameter(parsedParameters, expectedParameter, value.IntoText());
    return true;
}

//      Assumes `commandParser` and `parsedParameters` are not `none`.
//      Parses a single JSON object into given `parsedParameters`
//  hash table.
private final function bool ParseObjectValue(
    HashTable           parsedParameters,
    Command.Parameter   expectedParameter)
{
    local HashTable objectValue;
    objectValue = _.json.ParseHashTableWith(commandParser);
    if (!commandParser.Ok()) {
        return false;
    }
    RecordParameter(parsedParameters, expectedParameter, objectValue);
    return true;
}

//      Assumes `commandParser` and `parsedParameters` are not `none`.
//      Parses a single JSON array into given `parsedParameters`
//  hash table.
private final function bool ParseArrayValue(
    HashTable           parsedParameters,
    Command.Parameter   expectedParameter)
{
    local ArrayList arrayValue;
    arrayValue = _.json.ParseArrayListWith(commandParser);
    if (!commandParser.Ok()) {
        return false;
    }
    RecordParameter(parsedParameters, expectedParameter, arrayValue);
    return true;
}

//      Assumes `parsedParameters` is not `none`.
//      Records `value` for a given `parameter` into a given `parametersArray`.
//  If parameter is not a list type - simply records `value` as value under
//  `parameter.variableName` key.
//  If parameter is a list type - pushed value at the end of an array,
//  recorded at `parameter.variableName` key (creating it if missing).
//      All recorded values are managed by `parametersArray`.
private final function RecordParameter(
    HashTable               parametersArray,
    Command.Parameter       parameter,
    /* take */AcediaObject  value)
{
    local ArrayList parameterVariable;

    if (!parameter.allowsList)
    {
        parametersArray.SetItem(parameter.variableName, value);
        _.memory.Free(value);
        return;
    }
    parameterVariable =
        ArrayList(parametersArray.GetItem(parameter.variableName));
    if (parameterVariable == none) {
        parameterVariable = _.collections.EmptyArrayList();
    }
    parameterVariable.AddItem(value);
    _.memory.Free(value);
    parametersArray.SetItem(parameter.variableName, parameterVariable);
    _.memory.Free(parameterVariable);
}

//      Assumes `commandParser` is not `none`.
//      Tries to parse an option declaration (along with all of it's parameters)
//  with `commandParser`.
//      Returns `true` on success and `false` otherwise.
//      In case of failure to detect option declaration also reverts state of
//  `commandParser` to that before `TryParsingOptions()` call.
//  However, if option declaration was present, but invalid (or had
//  invalid parameters) parser will be left in a failed state.
private final function bool TryParsingOptions()
{
    local int temporaryInt;
    if (!commandParser.Ok()) return false;

    confirmedState = commandParser.GetCurrentState();
    //  Long options
    commandParser.Skip().Match(P("--"));
    if (commandParser.Ok()) {
        return ParseLongOption();
    }
    //  Filter out negative numbers that start similarly to short options:
    //  -3, -5.7, -.9
    commandParser.RestoreState(confirmedState)
        .Skip().Match(P("-")).MUnsignedInteger(temporaryInt, 10, 1);
    if (commandParser.Ok())
    {
        commandParser.RestoreState(confirmedState);
        return false;
    }
    commandParser.RestoreState(confirmedState).Skip().Match(P("-."));
    if (commandParser.Ok())
    {
        commandParser.RestoreState(confirmedState);
        return false;
    }
    //  Short options
    commandParser.RestoreState(confirmedState).Skip().Match(P("-"));
    if (commandParser.Ok()) {
        return ParseShortOption();
    }
    commandParser.RestoreState(confirmedState);
    return false;
}

//      Assumes `commandParser` is not `none`.
//      Tries to parse a long option name along with all of it's
//  possible parameters with `commandParser`.
//      Returns `true` on success and `false` otherwise. At the point this
//  method is called, option declaration is already assumed to be detected
//  and any failure implies parsing error (ending in failed `Command.CallData`).
private final function bool ParseLongOption()
{
    local int           i, optionIndex;
    local MutableText   optionName;
    commandParser.MUntil(optionName,, true);
    if (!commandParser.Ok()) {
        return false;
    }
    while (optionIndex < availableOptions.length)
    {
        if (optionName.Compare(availableOptions[optionIndex].longName)) break;
        optionIndex += 1;
    }
    if (optionIndex >= availableOptions.length)
    {
        DeclareError(CET_UnknownOption, optionName);
        optionName.FreeSelf();
        return false;
    }
    for (i = 0; i < usedOptions.length; i += 1)
    {
        if (optionName.Compare(usedOptions[i].longName))
        {
            DeclareError(CET_RepeatedOption, optionName);
            optionName.FreeSelf();
            return false;
        }
    }
    //usedOptions[usedOptions.length] = availableOptions[optionIndex];
    optionName.FreeSelf();
    return ParseOptionParameters(availableOptions[optionIndex]);
}

//      Assumes `commandParser` and `nextResult` are not `none`.
//      Tries to parse a short option name along with all of it's
//  possible parameters with `commandParser`.
//      Returns `true` on success and `false` otherwise. At the point this
//  method is called, option declaration is already assumed to be detected
//  and any failure implies parsing error (ending in failed `Command.CallData`).
private final function bool ParseShortOption()
{
    local int           i;
    local bool          pickedOptionWithParameters;
    local MutableText   optionsList;
    commandParser.MUntil(optionsList,, true);
    if (!commandParser.Ok())
    {
        optionsList.FreeSelf();
        return false;
    }
    for (i = 0; i < optionsList.GetLength(); i += 1)
    {
        if (nextResult.parsingError != CET_None) break;
        pickedOptionWithParameters =
            AddOptionByCharacter(   optionsList.GetCharacter(i), optionsList,
                                    pickedOptionWithParameters)
            || pickedOptionWithParameters;
    }
    optionsList.FreeSelf();
    return (nextResult.parsingError == CET_None);
}

//      Assumes `commandParser` and `nextResult` are not `none`.
//      Auxiliary method that adds option by it's short version's character
//  `optionCharacter`.
//      It also accepts `optionSourceList` that describes short option
//  expression (e.g. "-rtV") from which it originated for error reporting and
//  `forbidOptionWithParameters` that, when set to `true`, forces this method to
//  cause the `CET_MultipleOptionsWithParams` error if
//  new option has non-empty parameters.
//      Method returns `true` if added option had non-empty parameters and
//  `false` otherwise.
//      Any parsing failure inside this method always causes
//  `nextError.DeclareError()` call, so you can use `nextResult.IsSuccessful()`
//  to check if method has failed.
private final function bool AddOptionByCharacter(
    BaseText.Character  optionCharacter,
    BaseText            optionSourceList,
    bool                forbidOptionWithParameters)
{
    local int   i;
    local bool  optionHasParameters;
    //  Prevent same option appearing twice
    for (i = 0; i < usedOptions.length; i += 1)
    {
        if (_.text.AreEqual(optionCharacter, usedOptions[i].shortName))
        {
            DeclareError(CET_RepeatedOption, usedOptions[i].longName);
            return false;
        }
    }
    //  If it's a new option - look it up in all available options
    for (i = 0; i < availableOptions.length; i += 1)
    {
        if (!_.text.AreEqual(optionCharacter, availableOptions[i].shortName)) {
            continue;
        }
        usedOptions[usedOptions.length] = availableOptions[i];
        optionHasParameters = (availableOptions[i].required.length > 0
            ||  availableOptions[i].optional.length > 0);
        //  Enforce `forbidOptionWithParameters` flag restriction
        if (optionHasParameters && forbidOptionWithParameters)
        {
            DeclareError(CET_MultipleOptionsWithParams, optionSourceList);
            return optionHasParameters;
        }
        //  Parse parameters (even if they are empty) and bail
        commandParser.Skip();
        ParseOptionParameters(availableOptions[i]);
        break;
    }
    if (i >= availableOptions.length) {
        DeclareError(CET_UnknownShortOption);
    }
    return optionHasParameters;
}

//      Auxiliary method for parsing option's parameters (including empty ones).
//      Automatically fills `nextResult` with parsed parameters
//  (or `none` if option has no parameters).
//      Assumes `commandParser` and `nextResult` are not `none`.
private final function bool ParseOptionParameters(Command.Option pickedOption)
{
    local HashTable optionParameters;
    //  If we are already parsing other option's parameters and did not finish
    //  parsing all required ones - we cannot start another option
    if (currentTargetIsOption && currentTarget != CPT_ExtraParameter)
    {
        DeclareError(CET_NoRequiredParamForOption, targetOption.longName);
        return false;
    }
    if (pickedOption.required.length == 0 && pickedOption.optional.length == 0)
    {
        nextResult.options.SetItem(pickedOption.longName, none);
        return true;
    }
    currentTargetIsOption   = true;
    targetOption            = pickedOption;
    optionParameters        = ParseParameterArrays( pickedOption.required,
                                                    pickedOption.optional);
    currentTargetIsOption = false;
    if (commandParser.Ok())
    {
        nextResult.options
            .SetItem(pickedOption.longName, optionParameters);
        _.memory.Free(optionParameters);
        return true;
    }
    _.memory.Free(optionParameters);
    return false;
}

defaultproperties
{
    booleanTrueEquivalents(0)   = "true"
    booleanTrueEquivalents(1)   = "enable"
    booleanTrueEquivalents(2)   = "on"
    booleanTrueEquivalents(3)   = "yes"
    booleanFalseEquivalents(0)  = "false"
    booleanFalseEquivalents(1)  = "disable"
    booleanFalseEquivalents(2)  = "off"
    booleanFalseEquivalents(3)  = "no"
    errNoSubCommands = (l=LOG_Error,m="`GetSubCommand()` method was called on a command `%1` with zero defined sub-commands.")
}