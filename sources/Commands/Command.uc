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
    //  Default command name that will be used unless Acedia is configured to
    //  do otherwise
    var protected Text              name;
    //  Short summary of what command does (recommended to
    //  keep it to 80 characters)
    var protected Text              summary;
    var protected array<SubCommand> subCommands;
    var protected array<Option>     options;
    var protected bool              requiresTarget;
};
var private Data commandData;

//  We do not really ever need to create more than one instance of each class
//  of `Command`, so we will simply store and reuse one created instance.
var private Command mainInstance;

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
    local ConsoleWriter console;
    if (callerPlayer == none)       return;
    if (callInfo == none)           return;
    if (callInfo.IsSuccessful())    return;

    //  Setup console color
    console = callerPlayer.Console();
    if (callInfo.GetError() == CET_EmptyTargetList) {
        console.UseColor(_.color.textWarning);
    }
    else {
        console.UseColor(_.color.textFailure);
    }
    //  Send message
    errorMessage = callInfo.PrintErrorMessage();
    console.Say(errorMessage);
    errorMessage.FreeSelf();
    //  Restore console color
    console.ResetColor().Flush();
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
 *  Returns name (in lower case) of the caller command class.
 *
 *  @return Name (in lower case) of the caller command class.
 *      Guaranteed to be not `none`.
 */
public final function Text GetName()
{
    if (commandData.name == none) {
        return P("").Copy();
    }
    return commandData.name.LowerCopy();
}

/**
 *  Returns `Command.Data` struct that describes caller `Command`.
 *
 *  @return `Command.Data` that describes caller `Command`. Returned struct
 *      contains `Text` references that are used internally by the `Command`
 *      and not their copies.
 *          Generally this is undesired approach and leaves `Command` more
 *      vulnerable to modification, but copying all the data inside would not
 *      only introduce a largely pointless computational overhead, but also
 *      would require some cumbersome logic. This might change in the future,
 *      so deallocating any objects in the returned `struct` would lead to
 *      undefined behavior.
 */
public final function Data GetData()
{
    return commandData;
}

defaultproperties
{
}