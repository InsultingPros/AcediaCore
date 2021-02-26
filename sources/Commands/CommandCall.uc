/**
 *      This object describes a call attempt for one of the `Command`s.
 *      `Command`s are meant to be be executed from user's console input,
 *  so this object should only be created while parsing their input. Any other
 *  use of this object is not guaranteed to be supported.
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
class CommandCall extends AcediaObject
    dependson(Command);

//  Once this value is set to `true`, the command call is considered fully
//  described and will prevent any changes to it's internal state
//  (except deallocation).
var private bool                locked;
//  Player who initiated the call and targeted players (if applicable)
var private APlayer             callerPlayer;
var private array<APlayer>      targetPlayers;
//  Specified sub-command and parameters/options
var private Text                subCommandName;
var private AssociativeArray    commandParameters, commandOptions;

//  Errors that occurred during command call processing are described by
//  error type and optional error textual name of the object
//  (parameter, option, etc.) that caused it.
var private Command.ErrorType   parsingError;
var private Text                errorCause;

var public const int TBAD_PARSER, TNOSUB_COMMAND, TNO_REQ_PARAM;
var public const int TNO_REQ_PARAM_FOR_OPTION, TUNKNOW_NOPTION;
var public const int TUNKNOWN_SHORT_OPTION, TREPEATED_OPTION, TUNUSED_INPUT;
var public const int TMULTIPLE_OPTIONS_WITH_PARAMS;
var public const int TINCORRECT_TARGET, TEMPTY_TARGETS;

protected function Constructor()
{
    //  We simply take ownership and record into `commandParameters` whatever
    //  `AssociativeArray` was passed to us, but fill (and therefore create)
    //  `commandOptions` ourselves.
    commandOptions = _.collections.EmptyAssociativeArray();
}

protected function Finalizer()
{
    _.memory.Free(commandParameters);
    _.memory.Free(commandOptions);
    _.memory.Free(subCommandName);
    _.memory.Free(errorCause);
    commandParameters       = none;
    commandOptions          = none;
    subCommandName          = none;
    errorCause              = none;
    parsingError            = CET_None;
    targetPlayers.length    = 0;
    locked                  = false;
}

/**
 *  Method for producing erroneous `CommandCall` for the needs of
 *  error reporting.
 *
 *  @param  type            Type of error resulting `CommandCall` must have.
 *  @param  callerPlayer    Player that caused erroneous command call.
 *  @return `CommandCall` with specified error type and `APlayer`.
 */
public final static function CommandCall MakeError(
    Command.ErrorType   type,
    APlayer             callerPlayer)
{
    return CommandCall(__().memory.Allocate(class'CommandCall'))
        .DeclareError(type)
        .SetCallerPlayer(callerPlayer);
}

/**
 *  Put caller `CommandCall` into erroneous state.
 *  Does nothing after `CommandCall` was locked for change (see `Finish()`).
 *
 *  @param  type    Type of error caller `CommandCall` must have.
 *      Once error (not `CET_None`) was set - calling this method with
 *      `CET_None` to erase error will not work.
 *  @param  cause   Textual description of offender command part to supplement
 *      error report (will be used when reporting error to the caller).
 *  @return Caller `CommandCall` to allow for method chaining.
 */
public final function CommandCall DeclareError(
    Command.ErrorType   type,
    optional Text       cause)
{
    if (locked)                     return self;
    if (parsingError != CET_None)   return self;

    parsingError = type;
    _.memory.Free(errorCause);
    errorCause = none;
    if (cause != none) {
        errorCause = cause.Copy();
    }
    return self;
}

/**
 *  Checks if caller `CommandCall` is in erroneous state.
 *
 *  @return `true` if `CommandCall` has not recorded any errors so far and
 *      `false` otherwise.
 */
public final function bool IsSuccessful()
{
    return parsingError == CET_None;
}

/**
 *  Returns current error type (including `CET_None` if there were no errors).
 *
 *  @return Error type for caller `CommandCall` error.
 */
public final function Command.ErrorType GetError()
{
    return parsingError;
}

/**
 *  In case there were any errors - returns textual description of offender
 *  command part. Mostly used for reporting errors to players.
 *
 *  @return Textual description of command part that caused an error.
 */
public final function Text GetErrorCause()
{
    if (errorCause != none) {
        return errorCause.Copy();
    }
    return none;
}

/**
 *  After this method is called - changes to the `CommandCall` will be
 *  prevented.
 *
 *  @return Caller `CommandCall` to allow for method chaining.
 */
public final function CommandCall Finish()
{
    locked = true;
    return self;
}

/**
 *  Returns player, that initiated command, that produced caller `CommandCall`.
 *
 *  @return Player, that initiated command, that produced caller `CommandCall`
 */
public final function APlayer GetCallerPlayer()
{
    return callerPlayer;
}

/**
 *  Sets player, that initiated command, that produced caller `CommandCall`.
 *  Does nothing after `CommandCall` was locked for change (see `Finish()`).
 *
 *  @return Caller `CommandCall` to allow for method chaining.
 */
public final function CommandCall SetCallerPlayer(APlayer player)
{
    callerPlayer = player;
    return self;
}

/**
 *  Returns players that were targeted by command that produced caller
 *  `CommandCall`.
 *
 *  @return Players, targeted by caller `CommandCall`.
 */
public final function array<APlayer> GetTargetPlayers()
{
    return targetPlayers;
}

/**
 *  Sets players, targeted by command that produced caller `CommandCall`.
 *  Does nothing after `CommandCall` was locked for change (see `Finish()`).
 *
 *  @return Caller `CommandCall` to allow for method chaining.
 */
public final function CommandCall SetTargetPlayers(array<APlayer> newTargets)
{
    if (!locked) {
        targetPlayers = newTargets;
    }
    return self;
}

/**
 *  Returns picked sub-command of command that produced caller `CommandCall`.
 *
 *  @return Sub-command of command that produced caller `CommandCall`.
 *      Returns stored value that will be deallocated along with
 *      caller `CommandCall` - do not deallocate returned `Text` manually.
 */
public final function Text GetSubCommand()
{
    return subCommandName;
}

/**
 *  Sets sub-command of command that produced caller `CommandCall`.
 *  Does nothing after `CommandCall` was locked for change (see `Finish()`).
 *
 *  @param  newSubCommandName   New sub command name.
 *      Copy of passed object will be stored.
 *  @return Caller `CommandCall` to allow for method chaining.
 */
public final function CommandCall SetSubCommand(Text newSubCommandName)
{
    if (!locked)
    {
        _.memory.Free(subCommandName);
        subCommandName = newSubCommandName.Copy();
    }
    return self;
}

/**
 *  Returns parameters of command that produced caller `CommandCall`.
 *
 *  @return Parameters of command that produced caller `CommandCall`.
 *      Returns stored value that will be deallocated along with
 *      caller `CommandCall` - do not deallocate returned `AssociativeArray`
 *      manually.
 */
public final function AssociativeArray GetParameters()
{
    return commandParameters;
}

/**
 *  Sets parameters of command that produced caller `CommandCall`.
 *  Does nothing after `CommandCall` was locked for change (see `Finish()`).
 *
 *  @param  parameters  New set of parameters. Passed value will be managed by
 *      caller `CommandCall` and should not be deallocated manually after
 *      calling `SetParameters()`.
 *  @return Caller `CommandCall` to allow for method chaining.
 */
public final function CommandCall SetParameters(AssociativeArray parameters)
{
    if (!locked)
    {
        _.memory.Free(commandParameters);
        commandParameters = parameters;
    }
    return self;
}

/**
 *  Returns options of command that produced caller `CommandCall`.
 *
 *      If option without parameters was specified - it will be recorded as
 *  a key with value `none`.
 *      If option has parameters - `AssociativeArray` with them will be
 *  recorded as value instead.
 *
 *  @return Options of command that produced caller `CommandCall`.
 *      Returns stored value that will be deallocated along with
 *      caller `CommandCall` - do not deallocate returned `AssociativeArray`
 *      manually.
 */
public final function AssociativeArray GetOptions()
{
    return commandOptions;
}

/**
 *  Sets option parameters of command that produced caller `CommandCall`.
 *  Does nothing after `CommandCall` was locked for change (see `Finish()`).
 *
 *  For recording options without parameters simply pass `none` instead of them.
 *
 *  @param  option      Option to record (along with it's possible parameters).
 *  @param  parameters  Option parameters. Passed value will be managed by
 *      caller `CommandCall` and should not be deallocated manually after
 *      calling `SetParameters()`.
 *      Pass `none` if option has no parameters.
 *  @return Caller `CommandCall` to allow for method chaining.
 */
public final function CommandCall SetOptionParameters(
    Command.Option              option,
    optional AssociativeArray   parameters)
{
    if (locked)                 return self;
    if (commandOptions == none) return self;

    commandOptions.SetItem(option.longName, parameters, true);
    return self;
}

/**
 *  Prints error message as a human-readable message that can be reported to
 *  the caller player.
 *
 *  In case there was no error - empty text is returned.
 *
 *  @return Error message in a human-readable form.
 */
public final function Text PrintErrorMessage()
{
    local Text          result;
    local MutableText   builder;
    builder = _.text.Empty();
    switch (parsingError)
    {
    case CET_BadParser:
        builder.Append(T(TBAD_PARSER));
        break;
    case CET_NoSubCommands:
        builder.Append(T(TNOSUB_COMMAND));
        break;
    case CET_NoRequiredParam:
        builder.Append(T(TNO_REQ_PARAM)).Append(errorCause);
        break;
    case CET_NoRequiredParamForOption:
        builder.Append(T(TNO_REQ_PARAM_FOR_OPTION)).Append(errorCause);
        break;
    case CET_UnknownOption:
        builder.Append(T(TUNKNOW_NOPTION)).Append(errorCause);
        break;
    case CET_UnknownShortOption:
        builder.Append(T(TUNKNOWN_SHORT_OPTION));
        break;
    case CET_RepeatedOption:
        builder.Append(T(TREPEATED_OPTION)).Append(errorCause);
        break;
    case CET_UnusedCommandParameters:
        builder.Append(T(TUNUSED_INPUT)).Append(errorCause);
        break;
    case CET_MultipleOptionsWithParams:
        builder.Append(T(TMULTIPLE_OPTIONS_WITH_PARAMS)).Append(errorCause);
        break;
    case CET_IncorrectTargetList:
        builder.Append(T(TINCORRECT_TARGET)).Append(errorCause);
        break;
    case CET_EmptyTargetList:
        builder.Append(T(TEMPTY_TARGETS)).Append(errorCause);
        break;
    default:
    }
    result = builder.Copy();
    builder.FreeSelf();
    return result;
}

defaultproperties
{
    TBAD_PARSER                     = 0
    stringConstants(0)  = "Internal error occurred: invalid parser."
    TNOSUB_COMMAND                  = 1
    stringConstants(1)  = "Ill defined command: no subcommands"
    TNO_REQ_PARAM                   = 2
    stringConstants(2)  = "Missing required parameter: "
    TNO_REQ_PARAM_FOR_OPTION        = 3
    stringConstants(3)  = "Missing required parameter for option: "
    TUNKNOW_NOPTION                 = 4
    stringConstants(4)  = "Invalid option specified: "
    TUNKNOWN_SHORT_OPTION           = 5
    stringConstants(5)  = "Invalid short option specified."
    TREPEATED_OPTION                = 6
    stringConstants(6)  = "Option specified several times: "
    TUNUSED_INPUT                   = 7
    stringConstants(7)  = "Part of command could not be parsed: "
    TMULTIPLE_OPTIONS_WITH_PARAMS   = 8
    stringConstants(8)  = "Multiple short options in one declarations require parameters:"
    TINCORRECT_TARGET               = 9
    stringConstants(9)  = "Target players are incorrectly specified."
    TEMPTY_TARGETS                  = 10
    stringConstants(10) = "List of target players is empty."
}