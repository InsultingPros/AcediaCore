/**
 *      This class is meant to represent a command type: to create new command
 *  one should extend it, then simply define required sub-commands/options and
 *  parameters in `BuildData()` and overload `Executed()` / `ExecutedFor()`
 *  to perform required actions when command is executed by a player.
 *      `Executed()` is called first, whenever command is executed and
 *  `ExecuteFor()` is called only for targeted commands, once for each
 *  targeted player.
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
class Command extends AcediaObject
    dependson(BaseText);

/**
 *  Possible errors that can arise when parsing command parameters from
 *  user input
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
 *  Structure that contains all the information about how `Command` was called.
 */
struct CallData
{
    //  Targeted players (if applicable)
    var public array<EPlayer>   targetPlayers;
    //  Specified sub-command and parameters/options
    var public Text             subCommandName;
    //  Provided parameters and specified options
    var public HashTable        parameters;
    var public HashTable        options;
    //  Errors that occurred during command call processing are described by
    //  error type and optional error textual name of the object
    //  (parameter, option, etc.) that caused it.
    var public ErrorType        parsingError;
    var public Text             errorCause;
};

/**
 *  Possible types of parameters.
 */
enum ParameterType
{
    //  Parses into `BoolBox`
    CPT_Boolean,
    //  Parses into `IntBox`
    CPT_Integer,
    //  Parses into `FloatBox`
    CPT_Number,
    //  Parses into `Text`
    CPT_Text,
    //  Special parameter that consumes the rest of the input into `Text`
    CPT_Remainder,
    //  Parses into `HashTable`
    CPT_Object,
    //  Parses into `ArrayList`
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
    var BaseText.Character  shortName;
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
    //  Command group this command belongs to
    var protected Text              group;
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

/**
 *      When command is being executed we create several instances of
 *  `ConsoleWriter` that can be used for command output. They will also be
 *  automatically deallocated once command is executed.
 *      DO NOT modify them or deallocate any of them manually.
 *      This should make output more convenient and standardized.
 *
 *      1. `publicConsole` - sends messages to all present players;
 *      2. `callerConsole` - sends messages to the player that
 *          called the command;
 *      3. `targetConsole` - sends messages to the player that is currently
 *          being targeted (different each call of `ExecutedFor()` and
 *          `none` during `Executed()` call);
 *      4. `othersConsole` - sends messaged to every player that is
 *          neither "caller" or "target".
 */
var protected ConsoleWriter publicConsole, othersConsole;
var protected ConsoleWriter callerConsole, targetConsole;

protected function Constructor()
{
    local CommandDataBuilder dataBuilder;
    dataBuilder =
        CommandDataBuilder(_.memory.Allocate(class'CommandDataBuilder'));
    BuildData(dataBuilder);
    commandData = dataBuilder.BorrowData();
    dataBuilder.FreeSelf();
    dataBuilder = none;
}

protected function Finalizer()
{
    local int               i;
    local array<SubCommand> subCommands;
    local array<Option>     options;
    DeallocateConsoles();
    _.memory.Free(commandData.name);
    _.memory.Free(commandData.summary);
    subCommands = commandData.subCommands;
    for (i = 0; i < options.length; i += 1)
    {
        _.memory.Free(subCommands[i].name);
        _.memory.Free(subCommands[i].description);
        CleanParameters(subCommands[i].required);
        CleanParameters(subCommands[i].optional);
        subCommands[i].required.length = 0;
        subCommands[i].optional.length = 0;
    }
    commandData.subCommands.length = 0;
    options = commandData.options;
    for (i = 0; i < options.length; i += 1)
    {
        _.memory.Free(options[i].longName);
        _.memory.Free(options[i].description);
        CleanParameters(options[i].required);
        CleanParameters(options[i].optional);
        options[i].required.length = 0;
        options[i].optional.length = 0;
    }
    commandData.options.length = 0;
}

private final function CleanParameters(array<Parameter> parameters)
{
    local int i;
    for (i = 0; i < parameters.length; i += 1)
    {
        _.memory.Free(parameters[i].displayName);
        _.memory.Free(parameters[i].variableName);
    }
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
 *  Overload this method to perform required actions when
 *  your command is called.
 *
 *  @param  arguments   `struct` filled with parameters that your command
 *      has been called with. Guaranteed to not be in error state.
 *  @param  instigator  Player that instigated this execution.
 */
protected function Executed(CallData arguments, EPlayer instigator){}

/**
 *  Overload this method to perform required actions when your command is called
 *  with a given player as a target. If several players have been specified -
 *  this method will be called once for each.
 *
 *  If your command does not require a target - this method will not be called.
 *
 *  @param  target          Player that this command must perform an action on.
 *  @param  arguments       `struct` filled with parameters that your command
 *      has been called with. Guaranteed to not be in error state and contain
 *      all the required data.
 *  @param  instigator      Player that instigated this call.
 */
protected function ExecutedFor(
    EPlayer     target,
    CallData    arguments,
    EPlayer     instigator){}

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
 *  Forces command to process (parse) player's input, producing a structure
 *  with parsed data in Acedia's format instead.
 *
 *  @see `Execute()` for actually performing command's actions.
 *
 *  @param  parser          Parser that contains command input.
 *  @param  callerPlayer    Player that initiated this command's call,
 *      necessary for parsing player list (since it can point at
 *      the caller player).
 *  @return `CallData` structure that contains all the information about
 *      parameters specified in `parser`'s contents.
 *      Returned structure contains objects that must be deallocated,
 *      which can easily be done by the auxiliary `DeallocateCallData()` method.
 */
public final function CallData ParseInputWith(
    Parser  parser,
    EPlayer callerPlayer)
{
    local array<EPlayer>    targetPlayers;
    local CommandParser     commandParser;
    local CallData          callData;
    if (parser == none || !parser.Ok())
    {
        callData.parsingError = CET_BadParser;
        return callData;
    }
    //  Parse targets and handle errors that can arise here
    if (commandData.requiresTarget)
    {
        targetPlayers = ParseTargets(parser, callerPlayer);
        if (!parser.Ok())
        {
            callData.parsingError = CET_IncorrectTargetList;
            return callData;
        }
        if (targetPlayers.length <= 0)
        {
            callData.parsingError = CET_EmptyTargetList;
            return callData;
        }
    }
    //  Parse parameters themselves
    commandParser = CommandParser(_.memory.Allocate(class'CommandParser'));
    callData = commandParser.ParseWith(parser, commandData);
    callData.targetPlayers = targetPlayers;
    commandParser.FreeSelf();
    return callData;
}

/**
 *  Executes caller `Command` with data provided by `callData` if it is in
 *  a correct state and reports error to `callerPlayer` if
 *  `callData` is invalid.
 *
 *  @param  callData        Data about parameters, options, etc. with which
 *      caller `Command` is to be executed.
 *  @param  callerPlayer    Player that should be considered responsible for
 *      executing this `Command`.
 *  @return `true` if command was successfully executed and `false` otherwise.
 *      Execution is considered successful if `Execute()` call was made,
 *      regardless of whether `Command` can actually perform required action.
 *      For example, giving a weapon to a player can fail because he does not
 *      have enough space in his inventory, but it will still be considered
 *      a successful execution as far as return value is concerned.
 */
public final function bool Execute(CallData callData, EPlayer callerPlayer)
{
    local int               i;
    local array<EPlayer>    targetPlayers;

    if (callerPlayer == none)       return false;
    if (!callerPlayer.IsExistent()) return false;

    //  Report or execute
    if (callData.parsingError != CET_None)
    {
        ReportError(callData, callerPlayer);
        return false;
    }
    targetPlayers = callData.targetPlayers;
    publicConsole = _.console.ForAll();
    callerConsole = _.console.For(callerPlayer);
    callerConsole
        .Write(P("Executing command `"))
        .Write(commandData.name)
        .Say(P("`"));
    //  `othersConsole` should also exist in time for `Executed()` call
    othersConsole = _.console.ForAll().ButPlayer(callerPlayer);
    Executed(callData, callerPlayer);
    _.memory.Free(othersConsole);
    if (commandData.requiresTarget)
    {
        for (i = 0; i < targetPlayers.length; i += 1)
        {
            targetConsole = _.console.For(targetPlayers[i]);
            othersConsole = _.console
                .ForAll()
                .ButPlayer(callerPlayer)
                .ButPlayer(targetPlayers[i]);
            ExecutedFor(targetPlayers[i], callData, callerPlayer);
            _.memory.Free(othersConsole);
            _.memory.Free(targetConsole);
        }
    }
    othersConsole = none;
    targetConsole = none;
    DeallocateConsoles();
    return true;
}

private final function DeallocateConsoles()
{
    if (publicConsole != none && publicConsole.IsAllocated()) {
        _.memory.Free(publicConsole);
    }
    if (callerConsole != none && callerConsole.IsAllocated()) {
        _.memory.Free(callerConsole);
    }
    if (targetConsole != none && targetConsole.IsAllocated()) {
        _.memory.Free(targetConsole);
    }
    if (othersConsole != none && othersConsole.IsAllocated()) {
        _.memory.Free(othersConsole);
    }
    publicConsole = none;
    callerConsole = none;
    targetConsole = none;
    othersConsole = none;
}

/**
 *  Auxiliary method that cleans up all data and deallocates all objects inside
 *  provided `callData` structure.
 *
 *  @param  callData    Structure to clean. All stored data will be cleared,
 *      meaning that `DeallocateCallData()` method takes ownership of
 *      this parameter.
 */
public final static function DeallocateCallData(/* take */ CallData callData)
{
    __().memory.Free(callData.subCommandName);
    __().memory.Free(callData.parameters);
    __().memory.Free(callData.options);
    __().memory.Free(callData.errorCause);
    __().memory.FreeMany(callData.targetPlayers);
    if (callData.targetPlayers.length > 0) {
        callData.targetPlayers.length = 0;
    }
}

//  Reports given error to the `callerPlayer`, appropriately picking
//  message color
private final function ReportError(CallData callData, EPlayer callerPlayer)
{
    local Text          errorMessage;
    local ConsoleWriter console;
    if (callerPlayer == none)       return;
    if (!callerPlayer.IsExistent()) return;

    //  Setup console color
    console = callerPlayer.BorrowConsole();
    if (callData.parsingError == CET_EmptyTargetList) {
        console.UseColor(_.color.textWarning);
    }
    else {
        console.UseColor(_.color.textFailure);
    }
    //  Send message
    errorMessage = PrintErrorMessage(callData);
    console.Say(errorMessage);
    errorMessage.FreeSelf();
    //  Restore console color
    console.ResetColor().Flush();
}

private final function Text PrintErrorMessage(CallData callData)
{
    local Text          result;
    local MutableText   builder;
    builder = _.text.Empty();
    switch (callData.parsingError)
    {
    case CET_BadParser:
        builder.Append(P("Internal error occurred: invalid parser"));
        break;
    case CET_NoSubCommands:
        builder.Append(P("Ill defined command: no subcommands"));
        break;
    case CET_NoRequiredParam:
        builder.Append(P("Missing required parameter: "))
            .Append(callData.errorCause);
        break;
    case CET_NoRequiredParamForOption:
        builder.Append(P("Missing required parameter for option: "))
            .Append(callData.errorCause);
        break;
    case CET_UnknownOption:
        builder.Append(P("Invalid option specified: "))
            .Append(callData.errorCause);
        break;
    case CET_UnknownShortOption:
        builder.Append(P("Invalid short option specified"));
        break;
    case CET_RepeatedOption:
        builder.Append(P("Option specified several times: "))
            .Append(callData.errorCause);
        break;
    case CET_UnusedCommandParameters:
        builder.Append(P("Part of command could not be parsed: "))
            .Append(callData.errorCause);
        break;
    case CET_MultipleOptionsWithParams:
        builder.Append(P(   "Multiple short options in one declarations"
                        @   "require parameters: "))
            .Append(callData.errorCause);
        break;
    case CET_IncorrectTargetList:
        builder.Append(P("Target players are incorrectly specified."))
            .Append(callData.errorCause);
        break;
    case CET_EmptyTargetList:
        builder.Append(P("List of target players is empty"))
            .Append(callData.errorCause);
        break;
    default:
    }
    result = builder.Copy();
    builder.FreeSelf();
    return result;
}

//  Auxiliary method for parsing list of targeted players.
//  Assumes given parser is not `none` and not in a failed state.
//  If parsing failed, guaranteed to return an empty array.
private final function array<EPlayer> ParseTargets(
    Parser  parser,
    EPlayer callerPlayer)
{
    local array<EPlayer>    targetPlayers;
    local PlayersParser     targetsParser;
    targetsParser = PlayersParser(_.memory.Allocate(class'PlayersParser'));
    targetsParser.SetSelf(callerPlayer);
    targetsParser.ParseWith(parser);
    if (parser.Ok()) {
        targetPlayers = targetsParser.GetPlayers();
    }
    targetsParser.FreeSelf();
    return targetPlayers;
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
 *  Returns group name (in lower case) of the caller command class.
 *
 *  @return Group name (in lower case) of the caller command class.
 *      Guaranteed to be not `none`.
 */
public final function Text GetGroupName()
{
    if (commandData.group == none) {
        return P("").Copy();
    }
    return commandData.group.LowerCopy();
}

//  TODO: use `SharedRef` instead
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
public final function Data BorrowData()
{
    return commandData;
}

defaultproperties
{
}