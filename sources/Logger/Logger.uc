/**
 *      Base class for implementing "loggers" - objects that actually write log
 *  messages somewhere. To use it - simply implement `Write()` method,
 *  preferably making use of `GetPrefix()` method.
 *      Note that any child class must clean up its loaded loggers:
 *
 *  protected static function StaticFinalizer()
 *  {
 *      default.loadedLoggers = none;
 *  }
 *
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
class Logger extends AcediaObject
    perObjectConfig
    config(AcediaSystem)
    dependson(LoggerAPI)
    abstract;

//  Named loggers are stored here to avoid recreating them
var protected HashTable loadedLoggers;

//  Should `Logger` display prefix indicating it's a log message from Acedia?
var protected config bool acediaStamp;
//  Should `Logger` display time stamp prefix in front of log messages?
var protected config bool timeStamp;
//  Should `Logger` display information about what level message was logged?
var protected config bool levelStamp;

var protected const int TDEBUG, TINFO, TWARNING, TERROR, TFATAL, TTIME, TACEDIA;
var protected const int TSPACE;

protected static function StaticFinalizer()
{
    default.loadedLoggers = none;
}

/**
 *  Method for creating named `Logger`s that can have their settings prepared
 *  in the config file. Only one `Logger` is made for every
 *  unique (case insensitive) `loggerName`.
 *
 *  @param  loggerName  Name of the logger instance to return. Consequent calls
 *      with the same `loggerName` value will return the same `Logger`,
 *      unless it is deallocated.
 *  @return Logger with object name `loggerName`.
 */
public final static function Logger GetLogger(BaseText loggerName)
{
    local Logger    loggerInstance;
    local Text      loggerKey;
    if (loggerName == none) {
        return none;
    }
    if (default.loadedLoggers == none) {
        default.loadedLoggers = __().collections.EmptyHashTable();
    }
    loggerKey = loggerName.LowerCopy();
    loggerInstance = Logger(default.loadedLoggers.GetItem(loggerKey));
    if (loggerInstance == none)
    {
        loggerInstance = new(none, loggerName.ToString()) default.class;
        loggerInstance._constructor();
        default.loadedLoggers.SetItem(loggerKey, loggerInstance);
    }
    loggerKey.FreeSelf();
    return loggerInstance;
}

/**
 *  Auxiliary method for generating log message prefix based on `acediaStamp`,
 *  `timeStamp` and `levelStamp` flags according to their description.
 *  Method does not provide any guarantees on how exactly.
 *
 *  @param  messageLevel    Message level for which to generate prefix.
 *  @return Text (mutable) representation of generated prefix.
 */
protected function MutableText GetPrefix(LoggerAPI.LogLevel messageLevel)
{
    local MutableText builder;
    builder = _.text.Empty();
    if (acediaStamp) {
        builder.Append(T(TACEDIA));
    }
    if (timeStamp) {
        builder.Append(T(TTIME));
    }
    //  Make output prettier by adding a space after the "[...]" prefixes
    if (!levelStamp && (acediaStamp || timeStamp)) {
        builder.Append(T(TSPACE));
    }
    if (!levelStamp) {
        return builder;
    }
    switch (messageLevel)
    {
    case LOG_Debug:
        builder.Append(T(TDEBUG));
        break;
    case LOG_Info:
        builder.Append(T(TINFO));
        break;
    case LOG_Warning:
        builder.Append(T(TWARNING));
        break;
    case LOG_Error:
        builder.Append(T(TERROR));
        break;
    case LOG_Fatal:
        builder.Append(T(TFATAL));
        break;
    default:
    }
    return builder;
}

/**
 *  Method that must perform an actual work of outputting message `message`
 *  at level `messageLevel`.
 *
 *  @param  message         Message to output.
 *  @param  messageLevel    Level, at which message must be output.
 */
public function Write(BaseText message, LoggerAPI.LogLevel messageLevel){}

defaultproperties
{
    //  Parts of the prefix for our log messages, redirected into kf log file.
    TDEBUG      = 0
    stringConstants(0)  = "[Debug]   "
    TINFO       = 1
    stringConstants(1)  = "[Info]    "
    TWARNING    = 2
    stringConstants(2)  = "[Warning] "
    TERROR      = 3
    stringConstants(3)  = "[Error]   "
    TFATAL      = 4
    stringConstants(4)  = "[Fatal]   "
    TTIME       = 5
    stringConstants(5)  = "[hh:mm:ss]"
    TACEDIA     = 6
    stringConstants(6)  = "[Acedia]"
    TSPACE      = 7
    stringConstants(7)  = " "
}