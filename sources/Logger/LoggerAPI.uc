/**
 *      API that provides functions quick access to Acedia's
 *  logging functionality.
 *      Every message can be logged at five different levels: debug, info,
 *  warning, error, fatal. For each of the levels it keeps the list of `Logger`
 *  objects that then do the actual logging. `Logger` class itself is abstract
 *  and can have different implementations, depending on where do you want to
 *  output log information.
 *      Copyright 2020 - 2021 Anton Tarasenko
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
class LoggerAPI extends AcediaObject
    config(AcediaSystem);

//  Struct used to define `Logger`s list in Acedia's config files.
struct LoggerRecord
{
    //  Name of the `Logger`
    var public  string          name;
    //  Class of the logger to load
    var public  class<Logger>   cls;
};

//  To add a new `Logger` one first must to create a named object record with
//  appropriate settings and then specify the name and the class of that logger
//  in one of the `*Loggers` arrays, depending on what messages you want logger
//  to store.

//  Loggers, specified in `allLoggers` will log all levels of messages
var private config array<LoggerRecord> allLoggers;
//  Loggers, specified in one of the arrays below will only output logs of
//  a particular level (although one can always add the same `Logger` to
//  several log levels)
var private config array<LoggerRecord> debugLoggers;
var private config array<LoggerRecord> infoLoggers;
var private config array<LoggerRecord> warningLoggers;
var private config array<LoggerRecord> errorLoggers;
var private config array<LoggerRecord> fatalLoggers;

//  `Logger`s currently created for each log level
var private config array<Logger> debugLoggerInstances;
var private config array<Logger> infoLoggerInstances;
var private config array<Logger> warningLoggerInstances;
var private config array<Logger> errorLoggerInstances;
var private config array<Logger> fatalLoggerInstances;

//  Log levels, available in Acedia.
enum LogLevel
{
    //  Do not output log message anywhere. Added as a default value to
    //  avoid outputting message at unintended level by omission.
    LOG_None,
    //      Information that can be used to track down errors that occur on
    //  other people's systems, that developer cannot otherwise pinpoint.
    //      Use this to log information about internal objects' state that
    //  might be helpful to figuring out what the problem is when something
    //  breaks.
    LOG_Debug,
    //      Information about important events that should be occurring under
    //  normal conditions, such as initializations/shutdowns,
    //  successful completion of significant events, configuration assumptions.
    //      Should not occur too often.
    LOG_Info,
    //      For recoverable issues, anything that might cause errors or
    //  oddities in behavior.
    //      Should be used sparingly, i.e. player disconnecting might cause
    //  interruption in some logic, but should not cause a warning,
    //  since it is something expected to happen normally.
    LOG_Warning,
    //  Use this for errors, - events that some operation cannot recover from,
    //  but still does not require your feature / module to shut down.
    LOG_Error,
    //      Anything that does not allow your feature / module or game to
    //  function, completely irrecoverable failure state.
    LOG_Fatal
};

//  This structure can be used to initialize and store new `LogMessage`, based
//  on `string` description (not a text to use it inside `defaultproperties`).
struct Definition
{
    //  Message
    var private string      m;
    //  Level of the message
    //  (not actually used to create an `instance`, but to later know
    //  how to report it)
    var private LogLevel    l;
    //  Once created, `LogMessage` will be hashed here
    var private LogMessage  instance;
};

var private const int TDEBUG, TINFO, TWARNING, TERROR, TFATAL, TKFLOG;

//  Constructor simply adds `Logger`s as specified by the config
protected function Constructor()
{
    local int i;
    for (i = 0; i < debugLoggers.length; i += 1) {
        AddLogger(debugLoggers[i], LOG_Debug);
    }
    for (i = 0; i < infoLoggers.length; i += 1) {
        AddLogger(infoLoggers[i], LOG_Info);
    }
    for (i = 0; i < warningLoggers.length; i += 1) {
        AddLogger(warningLoggers[i], LOG_Warning);
    }
    for (i = 0; i < errorLoggers.length; i += 1) {
        AddLogger(errorLoggers[i], LOG_Error);
    }
    for (i = 0; i < fatalLoggers.length; i += 1) {
        AddLogger(fatalLoggers[i], LOG_Fatal);
    }
    for (i = 0; i < allLoggers.length; i += 1)
    {
        AddLogger(allLoggers[i], LOG_Debug);
        AddLogger(allLoggers[i], LOG_Info);
        AddLogger(allLoggers[i], LOG_Warning);
        AddLogger(allLoggers[i], LOG_Error);
        AddLogger(allLoggers[i], LOG_Fatal);
    }
}

/**
 *  Adds another `Logger` to a particular log level (`messageLevel`).
 *  Once added, a logger cannot be removed.
 *
 *  @param  record          Logger that must be added to track a specified level
 *      of log messages.
 *  @param  messageLevel    Level of messages passed logger must track.
 *  @return `LoggerAPI` instance to allow for method chaining.
 */
public final function LoggerAPI AddLogger(
    LoggerRecord    record,
    LogLevel        messageLevel)
{
    if (record.cls == none) {
        return none;
    }
    switch (messageLevel)
    {
    case LOG_Debug:
        AddLoggerTo(record, debugLoggerInstances);
        break;
    case LOG_Info:
        AddLoggerTo(record, infoLoggerInstances);
        break;
    case LOG_Warning:
        AddLoggerTo(record, warningLoggerInstances);
        break;
    case LOG_Error:
        AddLoggerTo(record, errorLoggerInstances);
        break;
    case LOG_Fatal:
        AddLoggerTo(record, fatalLoggerInstances);
        break;
    default:
    }
    return self;
}

//  Add logger, described by `record` into `loggers` array.
//  Report errors with `Log()`, since we cannot use `LoggerAPI` yet.
private final function AddLoggerTo(
    LoggerRecord        record,
    out array<Logger>   loggers)
{
    local int       i;
    local Text      loggerName;
    local Logger    newInstance;
    if (record.cls == none)
    {
        //  Cannot use `LoggerAPI` here ¯\_(ツ)_/¯
        Log("[Acedia/LoggerAPI] Failure to add logger: empty class for \""
            $ record.name $ "\" is specified");
        return;
    }
    //  Try to get the instance
    loggerName = _.text.FromString(record.name);
    newInstance = record.cls.static.GetLogger(loggerName);
    loggerName.FreeSelf();
    if (newInstance == none)
    {
        Log("[Acedia/LoggerAPI] Failure to add logger: could not create logger"
            @ "of class `" $ record.cls $ "` named \"" $ record.name $ "\"");
        return;
    }
    //  Ensure it was not already added
    for (i = 0; i < loggers.length; i += 1) {
        if (newInstance == loggers[i]) return;
    }
    loggers[loggers.length] = newInstance;
}

/**
 *  This method accepts "definition struct" for `LogMessage` only to create and
 *  return it, allowing you to make `Arg*()` calls to fill-in missing arguments
 *  (defined in `LogMessage` by "%<number>" tags).
 *
 *      Once all necessary `Arg*()` calls have been made, `LogMessage` will
 *  automatically send prepared message into `LoggerAPI`.
 *      Typical usage usually looks like:
 *      `_.logger.Auto(myErrorDef).Arg(objectName).ArgInt(objectID);`
 *      See `LogMessage` class for more information.
 *
 *  @param  definition  "Definition" filled with `string` message to log and
 *      message level at which resulting message must be logged.
 *  @return `LogMessage` generated by given `definition`. Once created it will
 *      be hashed and reused when the same struct value is passed again
 *      (`LogMessage` will be stored in passed `definition`, so creating a
 *      new struct with the same message/log level will erase
 *      the hashed `LogMessage`).
 */
public final function LogMessage Auto(out Definition definition)
{
    local LogMessage instance;
    instance = definition.instance;
    if (instance == none)
    {
        instance = LogMessage(_.memory.Allocate(class'LogMessage'));
        instance.Initialize(definition);
        definition.instance = instance;
    }
    instance.Reset().TryLogging();
    return instance;
}

/**
 *  This method causes passed message `message` to be passed to loggers for
 *  `messageLevel` message level.
 *
 *  @param  message         Message to log.
 *  @param  messageLevel    Level at which to log message.
 */
public final function LogAtLevel(BaseText message, LogLevel messageLevel)
{
    switch (messageLevel)
    {
    case LOG_Debug:
        self.Debug(message);
        break;
    case LOG_Info:
        self.Info(message);
        break;
    case LOG_Warning:
        self.Warning(message);
        break;
    case LOG_Error:
        self.Error(message);
        break;
    case LOG_Fatal:
        self.Fatal(message);
        break;
    default:
    }
}

/**
 *  This method causes passed message `message` to be passed to loggers for
 *  debug message level.
 *
 *  @param  message Message to log.
 */
public final function Debug(BaseText message)
{
    local int i;
    for (i = 0; i < debugLoggerInstances.length; i += 1) {
        debugLoggerInstances[i].Write(message, LOG_Debug);
    }
}

/**
 *  This method causes passed message `message` to be passed to loggers for
 *  info message level.
 *
 *  @param  message Message to log.
 */
public final function Info(BaseText message)
{
    local int i;
    for (i = 0; i < infoLoggerInstances.length; i += 1) {
        infoLoggerInstances[i].Write(message, LOG_Info);
    }
}

/**
 *  This method causes passed message `message` to be passed to loggers for
 *  warning message level.
 *
 *  @param  message Message to log.
 */
public final function Warning(BaseText message)
{
    local int i;
    for (i = 0; i < warningLoggerInstances.length; i += 1) {
        warningLoggerInstances[i].Write(message, LOG_Warning);
    }
}

/**
 *  This method causes passed message `message` to be passed to loggers for
 *  error message level.
 *
 *  @param  message Message to log.
 */
public final function Error(BaseText message)
{
    local int i;
    for (i = 0; i < errorLoggerInstances.length; i += 1) {
        errorLoggerInstances[i].Write(message, LOG_Error);
    }
}

/**
 *  This method causes passed message `message` to be passed to loggers for
 *  fatal message level.
 *
 *  @param  message Message to log.
 */
public final function Fatal(BaseText message)
{
    local int i;
    for (i = 0; i < fatalLoggerInstances.length; i += 1) {
        fatalLoggerInstances[i].Write(message, LOG_Fatal);
    }
}

defaultproperties
{
}