/**
 *      This class is meant to represent a command type: to create new command
 *  one should extend it, then simply define required sub-commands/options and
 *  parameters in `BuildData()` and use `Execute()` / `ExecuteFor()` to perform
 *  necessary actions when command is executed by a player.
 *      Copyright 2021 Anton Tarasenko
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
class Command extends AcediaObject
    dependson(Text);

/**
 *  Possible errors that can arise when producing `CommandCall` from user input
 */
enum ErrorType
{
    //  No error
    CET_None,
    //  Bad parser was provided to parse user input
    //  (this should not be possible)
    CET_BadParser,
    //  Sub-command name was not specified or was incorrect
    //  (this should not be possible)
    CET_NoSubCommands,
    //  Required param for command / option was not specified
    CET_NoRequiredParam,
    CET_NoRequiredParamForOption,
    //  Unknown option key was specified
    CET_UnknownOption,
    CET_UnknownShortOption,
    //  Same option appeared twice in one command call
    CET_RepeatedOption,
    //  Part of user's input could not be interpreted as a part of
    //  command's call
    CET_UnusedCommandParameters,
    //  In one short option specification (e.g. '-lah') several options
    //  require parameters: this introduces ambiguity and is not allowed
    CET_MultipleOptionsWithParams,
    //  (For targeted commands only)
    //  Targets are specified incorrectly (or none actually specified)
    CET_IncorrectTargetList,
    CET_EmptyTargetList
};

/**
 *  Possible types of parameters.
 */
enum ParameterType
{
    CPT_Boolean,
    CPT_Integer,
    CPT_Number,
    CPT_Text,
    CPT_Object,
    CPT_Array
};

/**
 *      Possible forms a boolean variable can be used as.
 *      Boolean parameter can define it's preferred format, which will be used
 *  for help page generation.
 */
enum PreferredBooleanFormat
{
    PBF_TrueFalse,
    PBF_EnableDisable,
    PBF_OnOff,
    PBF_YesNo
};

//  Defines a singular command parameter
struct Parameter
{
    //  Display name (for the needs of help page displaying)
    var Text                    displayName;
    //  Type of value this parameter would store
    var ParameterType           type;
    //  Does it take only a singular value or can it contain several of them,
    //  written in a list
    var bool                    allowsList;
    //  Variable name that will be used as a key to store parameter's value
    var Text                    variableName;
    //  (For `CPT_Boolean` type variables only) - preferred boolean format,
    //  used in help pages
    var PreferredBooleanFormat  booleanFormat;
};

//      Defines a sub-command of a this command (specified as
//  "<command> <sub_command>").
//      Using sub-command is not optional, but if none defined
//  (in `BuildData()`) / specified by the player - an empty (`name.IsEmpty()`)
//  one is automatically created / used.
struct SubCommand
{
    //  Cannot be `none`
    var Text                name;
    //  Can be `none`
    var Text                description;
    var array<Parameter>    required;
    var array<Parameter>    optional;
};

//  Defines command's option (options are specified by "--long" or "-l").
//  Options are independent from sub-commands.
struct Option
{
    var Text.Character      shortName;
    var Text                longName;
    var Text                description;
    //  Option can also have their own parameters
    var array<Parameter>    required;
    var array<Parameter>    optional;
};

//  Structure that defines what sub-commands and options command has
//  (and what parameters they take)
struct Data
{
    var protected array<SubCommand> subCommands;
    var protected array<Option>     options;
    var protected bool              requiresTarget;
};
var private Data commandData;

//  Default command name that will be used unless Acedia is configured to
//  do otherwise
var private const string commandName;

//  We do not really ever need to create more than one instance of each class
//  of `Command`, so we will simply store and reuse one created instance.
var private Command mainInstance;

var public const int TSPACE, TCOMMAND_NAME_FALLBACK, TPLUS;
var public const int TOPEN_BRACKET, TCLOSE_BRACKET;
var public const int TKEY, TDOUBLE_KEY, TCOMMA_SPACE, TBOOLEAN, TINDENT;
var public const int TBOOLEAN_TRUE_FALSE, TBOOLEAN_ENABLE_DISABLE;
var public const int TBOOLEAN_ON_OFF, TBOOLEAN_YES_NO;
var public const int TOPTIONS, TCMD_WITH_TARGET, TCMD_WITHOUT_TARGET;

protected function Constructor()
{
    local CommandDataBuilder dataBuilder;
    dataBuilder =
        CommandDataBuilder(_.memory.Allocate(class'CommandDataBuilder'));
    BuildData(dataBuilder);
    commandData = dataBuilder.GetData();
    dataBuilder.FreeSelf();
    dataBuilder = none;
}

/**
 *  Overload this method to use `builder` to define parameters and options for
 *  your command.
 *
 *  @param  builder Builder that can be used to define your commands parameters
 *      and options. Do not deallocate.
 */
protected function BuildData(CommandDataBuilder builder){}

/**
 *  Overload this method to perform what is needed when your command is called.
 *
 *  @param  callInfo    Object filled with parameters that your command has
 *      been called with. Guaranteed to not be in error state.
 */
protected function Executed(CommandCall callInfo){}

/**
 *  Overload this method to perform what is needed when your command is called
 *  with a given player as a target. If several players have been specified -
 *  this method will be called once for each.
 *
 *  If your command does not require a target - this method will not be called.
 *
 *  @param  targetPlayer    Player that this command must perform an action on.
 *  @param  callInfo        Object filled with parameters that your command has
 *      been called with. Guaranteed to not be in error state.
 */
protected function ExecutedFor(APlayer targetPlayer, CommandCall callInfo){}

/**
 *  Returns an instance of command (of particular class) that is stored
 *  "as a singleton" in command's class itself. Do not deallocate it.
 */
public final static function Command GetInstance()
{
    if (default.mainInstance == none) {
        default.mainInstance = Command(__().memory.Allocate(default.class));
    }
    return default.mainInstance;
}

/**
 *  Returns name (in lower case) of the caller command class.
 *
 *  @return Name (in lower case) of the caller command class.
 */
public final static function Text GetName()
{
    local Text name, lowerCaseName;
    name = __().text.FromString(default.commandName);
    lowerCaseName = name.LowerCopy();
    name.FreeSelf();
    return lowerCaseName;
}

/**
 *  Forces command to process (parse and, if successful, execute itself)
 *  player's input.
 *
 *  @param  parser          Parser that contains player's input.
 *  @param  callerPlayer    Player that initiated this command's call.
 *  @return `CommandCall` object that described parsed command call.
 *      Guaranteed to be not `none`.
 */
public final function CommandCall ProcessInput(
    Parser  parser,
    APlayer callerPlayer)
{
    local int               i;
    local array<APlayer>    targetPlayers;
    local CommandParser     commandParser;
    local CommandCall       callInfo;
    if (parser == none || !parser.Ok()) {
        return MakeAndReportError(callerPlayer, CET_BadParser);
    }
    //  Parse targets and handle errors that can arise here
    if (commandData.requiresTarget)
    {
        targetPlayers = ParseTargets(parser, callerPlayer);
        if (!parser.Ok()) {
            return MakeAndReportError(callerPlayer, CET_IncorrectTargetList);
        }
        if (targetPlayers.length <= 0) {
            return MakeAndReportError(callerPlayer, CET_EmptyTargetList);
        }
    }
    //  Parse parameters themselves
    commandParser = CommandParser(_.memory.Allocate(class'CommandParser'));
    callInfo = commandParser.ParseWith(parser, commandData)
        .SetCallerPlayer(callerPlayer)
        .SetTargetPlayers(targetPlayers);
    commandParser.FreeSelf();
    //  Report or execute
    if (!callInfo.IsSuccessful())
    {
        ReportError(callerPlayer, callInfo);
        return callInfo;
    }
    Executed(callInfo);
    if (commandData.requiresTarget)
    {
        for (i = 0; i < targetPlayers.length; i += 1) {
            ExecutedFor(targetPlayers[i], callInfo);
        }
    }
    return callInfo;
}

//  Reports given error to the `callerPlayer`, appropriately picking
//  message color
private final function ReportError(
    APLayer     callerPlayer,
    CommandCall callInfo)
{
    local Text          errorMessage;
    local Color         previousConsoleColor;
    local ConsoleWriter console;
    if (callerPlayer == none)       return;
    if (callInfo == none)           return;
    if (callInfo.IsSuccessful())    return;

    //  Setup console color
    console = callerPlayer.Console();
    previousConsoleColor = console.GetColor();
    if (callInfo.GetError() == CET_EmptyTargetList) {
        console.SetColor(_.color.TextWarning);
    }
    else {
        console.SetColor(_.color.TextFailure);
    }
    //  Send message
    errorMessage = callInfo.PrintErrorMessage();
    console.Write(errorMessage);
    errorMessage.FreeSelf();
    //  Restore console color
    console.SetColor(previousConsoleColor).Flush();
}

//  Creates (and returns) empty `CommandCall` with given error type and
//  empty error cause and reports it
private final function CommandCall MakeAndReportError(
    APLayer     callerPlayer,
    ErrorType   errorType)
{
    local CommandCall dummyCall;
    if (errorType == CET_None)  return none;

    dummyCall = class'CommandCall'.static.MakeError(errorType, callerPlayer);
    ReportError(callerPlayer, dummyCall);
    return dummyCall;
}

//  Auxiliary method for parsing list of targeted players.
//  Assumes given parser is not `none` and not in a failed state.
private final function array<APlayer> ParseTargets(
    Parser  parser,
    APlayer callerPlayer)
{
    local array<APlayer>    targetPlayers;
    local PlayersParser     targetsParser;
    targetsParser = PlayersParser(_.memory.Allocate(class'PlayersParser'));
    targetsParser.SetSelf(callerPlayer);
    targetsParser.ParseWith(parser);
    targetPlayers = targetsParser.GetPlayers();
    targetsParser.FreeSelf();
    return targetPlayers;
}


//  TODO: This is a hack to insert new line symbol,
//  this needs to be redone in a better way
private final function Text.Character GetNewLine(Text.Formatting formatting)
{
    local Text.Character newLine;
    newLine.codePoint   = 10;
    newLine.formatting  = formatting;
    return newLine;
}

/**
 *  Returns colored `Text` with auto-generated help page for the caller command.
 *
 *  @return Auto-generated help page for the caller `Command` class.
 */
public final function Text PrintHelp()
{
    local Text              result, commandNameAsText, commandNameRandomCase;
    local MutableText       builder, subBuilder;
    local Text.Formatting   defaultFormatting;
    defaultFormatting = _.text.FormattingFromColor(_.color.TextDefault);
    builder = _.text.Empty();
    //  Get capitalized command name
    commandNameRandomCase = _.text.FromString(commandName);
    commandNameAsText = commandNameRandomCase.UpperCopy();
    commandNameRandomCase.FreeSelf();
    //  Print header: name + basic info
    builder.Append(commandNameAsText, defaultFormatting);
    if (commandData.requiresTarget) {
        builder.Append(T(TCMD_WITH_TARGET), defaultFormatting);
    }
    else {
        builder.Append(T(TCMD_WITHOUT_TARGET), defaultFormatting);
    }
    //  Print commands part
    subBuilder = PrintCommands(commandNameAsText);
    builder.Append(subBuilder);
    _.memory.Free(subBuilder);
    //  Print options part
    subBuilder = PrintOptions();
    builder.Append(subBuilder);
    _.memory.Free(subBuilder);
    result = builder.Copy();
    builder.FreeSelf();
    return result;
}

private final function MutableText PrintCommands(Text commandNameAsText)
{
    local int               i;
    local Text.Character    newLine;
    local MutableText       builder, subBuilder;
    local array<SubCommand> subCommands;
    newLine = GetNewLine(_.text.FormattingFromColor(_.color.TextDefault));
    subCommands = commandData.subCommands;
    builder = _.text.Empty();
    for (i = 0; i < subCommands.length; i += 1)
    {
        builder.AppendCharacter(newLine);
        subBuilder = PrintSubCommand(commandNameAsText, subCommands[i]);
        builder.AppendCharacter(newLine).Append(subBuilder);
        _.memory.Free(subBuilder);
    }
    return builder;
}

private final function MutableText PrintOptions()
{
    local int               i;
    local Text.Character    newLine;
    local MutableText       builder, subBuilder;
    local array<Option>     options;
    options = commandData.options;
    if (options.length <= 0) {
        return none;
    }
    newLine = GetNewLine(_.text.FormattingFromColor(_.color.TextDefault));
    builder = _.text.Empty();
    builder.AppendCharacter(newLine)
        .Append(T(TOPTIONS))
        .AppendCharacter(newLine);
    for (i = 0; i < options.length; i += 1)
    {
        subBuilder = PrintOption(options[i]);
        builder.AppendCharacter(newLine).Append(subBuilder);
        _.memory.Free(subBuilder);
    }
    return builder;
}

private final function MutableText PrintSubCommand(
    Text        usedCommandName,
    SubCommand  subCommand)
{
    local MutableText builder, subBuilder;
    local Text.Formatting defaultFormatting, emphasisFormatting;
    defaultFormatting   = _.text.FormattingFromColor(_.color.TextDefault);
    emphasisFormatting  = _.text.FormattingFromColor(_.color.TextEmphasis);
    //  Command + parameters
    builder = _.text.Empty().Append(usedCommandName, emphasisFormatting);
    if (subCommand.name != none && !subCommand.name.IsEmpty())
    {
        builder.Append(T(TSPACE), defaultFormatting)
            .Append(subCommand.name, emphasisFormatting);
    }
    subBuilder = PrintParameters(subCommand.required, subCommand.optional);
    builder.Append(T(TSPACE), defaultFormatting).Append(subBuilder);
    _.memory.Free(subBuilder);
    //  Text description
    builder.AppendCharacter(GetNewLine(defaultFormatting))
        .Append(T(TINDENT), defaultFormatting)
        .Append(subCommand.description, defaultFormatting);
    return builder;
}

private final function MutableText PrintOption(Option option)
{
    local Text.Character    shortName;
    local MutableText       builder, subBuilder;
    local Text.Formatting   defaultFormatting, emphasisFormatting;
    defaultFormatting   = _.text.FormattingFromColor(_.color.TextDefault);
    emphasisFormatting  = _.text.FormattingFromColor(_.color.TextEmphasis);
    //  Option name
    shortName = option.shortName;
    shortName.formatting = emphasisFormatting;
    builder = _.text.Empty()
        .Append(T(TKEY), emphasisFormatting)            // "-"
        .AppendCharacter(shortName)
        .Append(T(TCOMMA_SPACE), defaultFormatting)     //", "
        .Append(T(TDOUBLE_KEY), emphasisFormatting)     //"--"
        .Append(option.longName, emphasisFormatting)
        .Append(T(TSPACE), defaultFormatting);
    //  Possible options
    if (option.required.length != 0 || option.optional.length != 0)
    {
        subBuilder = PrintParameters(option.required, option.optional);
        builder.Append(subBuilder);
        _.memory.Free(subBuilder);
        //  If there actually were options - start a new line
        builder.AppendCharacter(GetNewLine(defaultFormatting))
            .Append(T(TINDENT), defaultFormatting);
    }
    //  Text description
    return builder.Append(option.description, defaultFormatting);
}

private final function MutableText PrintParameters(
    array<Parameter> required,
    array<Parameter> optional)
{
    local int               i;
    local MutableText       builder, subBuilder;
    local Text.Formatting   defaultFormatting;
    defaultFormatting = _.text.FormattingFromColor(_.color.TextDefault);
    builder = _.text.Empty();
    //  Print required
    for (i = 0; i < required.length; i += 1)
    {
        subBuilder = PrintParameter(required[i]);
        builder.Append(subBuilder);
        _.memory.Free(subBuilder);
        if (i < required.length - 1) {
            builder.Append(T(TSPACE), defaultFormatting);
        }
    }
    if (optional.length <= 0) {
        return builder;
    }
    //  Print optional
    builder.Append(T(TSPACE), defaultFormatting)
        .Append(T(TOPEN_BRACKET), defaultFormatting);
    for (i = 0; i < optional.length; i += 1)
    {
        subBuilder = PrintParameter(optional[i]);
        builder.Append(subBuilder);
        _.memory.Free(subBuilder);
        if (i < optional.length - 1) {
            builder.Append(T(TSPACE), defaultFormatting);
        }
    }
    builder.Append(T(TCLOSE_BRACKET), defaultFormatting);
    return builder;
}

private final function MutableText PrintParameter(Parameter parameter)
{
    local MutableText       builder;
    local Text.Formatting   defaultFormatting, typeFormatting;
    defaultFormatting = _.text.FormattingFromColor(_.color.TextDefault);
    switch (parameter.type)
    {
    case CPT_Boolean:
        typeFormatting = _.text.FormattingFromColor(_.color.TypeBoolean);
        break;
    case CPT_Integer:
        typeFormatting = _.text.FormattingFromColor(_.color.TypeNumber);
        break;
    case CPT_Number:
        typeFormatting = _.text.FormattingFromColor(_.color.TypeNumber);
        break;
    case CPT_Text:
        typeFormatting = _.text.FormattingFromColor(_.color.TypeString);
        break;
    case CPT_Object:
        typeFormatting = _.text.FormattingFromColor(_.color.TypeLiteral);
        break;
    case CPT_Array:
        typeFormatting = _.text.FormattingFromColor(_.color.TypeLiteral);
        break;
    default:
    }
    builder = _.text.Empty().Append(parameter.displayName, typeFormatting);
    if (parameter.allowsList) {
        builder.Append(T(TPLUS), typeFormatting);
    }
    return builder;
}

private final function Text PrintBooleanType(PreferredBooleanFormat booleanType)
{
    switch (booleanType)
    {
    case PBF_TrueFalse:
        return T(TBOOLEAN_TRUE_FALSE);
    case PBF_EnableDisable:
        return T(TBOOLEAN_ENABLE_DISABLE);
    case PBF_OnOff:
        return T(TBOOLEAN_ON_OFF);
    case PBF_YesNo:
        return T(TBOOLEAN_YES_NO);
    default:
    }
    return T(TBOOLEAN);
}

defaultproperties
{
    TSPACE                  = 0
    stringConstants(0) = " "
    TPLUS                   = 1
    stringConstants(1) = "(+)"
    TOPEN_BRACKET           = 2
    stringConstants(2) = "["
    TCLOSE_BRACKET          = 3
    stringConstants(3) = "]"
    TKEY                    = 4
    stringConstants(4) = "-"
    TDOUBLE_KEY             = 5
    stringConstants(5) = "--"
    TCOMMA_SPACE            = 6
    stringConstants(6) = ", "
    TINDENT                 = 7
    stringConstants(7) = "    "
    TBOOLEAN                = 8
    stringConstants(8) = "boolean"
    TBOOLEAN_TRUE_FALSE     = 9
    stringConstants(9) = "true/false"
    TBOOLEAN_ENABLE_DISABLE = 10
    stringConstants(10) = "enable/disable"
    TBOOLEAN_ON_OFF         = 11
    stringConstants(11) = "on/off"
    TBOOLEAN_YES_NO         = 12
    stringConstants(12) = "yes/no"
    TCMD_WITH_TARGET        = 13
    stringConstants(13) = ": This command requires target to be specified."
    TCMD_WITHOUT_TARGET     = 14
    stringConstants(14) = ": This command does not require target to be specified."
    TOPTIONS                = 15
    stringConstants(15) = "OPTIONS"
    //  Under normal conditions we only create one instance of each, so
    //  there is no need to object pools
    usesObjectPool = false
}