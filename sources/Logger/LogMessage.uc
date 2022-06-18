/**
 *      Object of this class is meant to represent a single log message that
 *  can have parameters, specified by "%<number>" definitions
 *  (e.g. "Thing %1 conflicts with thing %2, so we will have to remove %3").
 *  Log message only has to prepare (break into parts) provided human-readable
 *  string once and then will be able to quickly perform argument insertion
 *  (for which several convenient `Arg*()` methods are provided).
 *      The supposed way to use `LogMessage` is is in conjunction with
 *  `LoggerAPI`'s `Auto()` method that takes `Definition` with pre-filled
 *  message (`m`) and type (`t`), then:
 *      1. (first time only) Generates a new `LogMessage` from them;
 *      2. Returns `LogMessage` object that, whos arguments are supposed to be
 *          filled with `Arg*()` methods;
 *      3. When the appropriate amount of `Arg*()` calls (by the number of
 *          specified "%<number>" tags) was made - logs resulting message.
 *      (4). If message takes no arguments - no `Arg*()` calls are necessary;
 *      (5). If new `Auto()` call is made before previous message was provided
 *          enough arguments - error will be logged and previous message
 *          will be discarded (along with it's arguments).
 *      For more information about using it - refer to the documentation.
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
class LogMessage extends AcediaObject;

//  Flag to prevent `Initialize()` being called several times in a row
var private bool                isInitialized;
//  With what level was this message initialized?
var private LoggerAPI.LogLevel  myLevel;

/**
 *  We essentially break specified log string into parts
 *  (replacing empty parts with `none`) like this:
 *  "This %1 is %3, not %2" =>
 *      * "This "
 *      * " is "
 *      * ", not "
 *      * `none`
 *  Arguments always fit between these parts, so if there is `N` parts,
 *  there will be `N - 1` arguments. We consider that we are done filling
 *  arguments when amount of `Arg*()` calls reaches that number.
 *
 *      For future localization purposes we do not assume that arguments are
 *  specified from left to right in order: in our example,
 *  if we make following calls: `.Arg("one").Arg("caged").Arg("free")`,
 *  we will get the string: "This one is free, not caged".
 *      To remember the order we keep a special array, in our case it would be
 *  [1, 3, 2], except normalized to start from zero: [0, 2, 1].
 */
//  Parts of the initial message, broken by "%<number> tags
var private array<Text> logParts;
//  Defines order of arguments:
//  `i` -> argument at what number to use at insertion place `i`?
//  (`i` starting from zero instead of `1`).
var private array<int>  normalizedArguments;

//      Only default value is used for this variable: it remembers what
//  `LogMessage` currently stores "garbage": temporary `Text` object to create
//  a log message. Making an `Arg*()` call on any other `LogMessage` will cause
//  progress of `default.dirtyLogMessage` to be reset, thus enforcing that only
//  one `LogMessage` can be in the process of filling itself with arguments at
//  a time and, therefore, only one can be "dirty": contain temporary
//  `Text` objects.
//      This way using `LogMessage` would not lead to accumulating large
//  amounts of trash objects, since only one of them can "make a mess".
var private LogMessage  dirtyLogMessage;
//  Arguments, collected so far by the `Arg*()` calls
var private array<BaseText> collectedArguments;

protected function Finalizer()
{
    isInitialized = false;
    _.memory.FreeMany(logParts);
    _.memory.FreeMany(collectedArguments);
    logParts.length = 0;
    collectedArguments.length = 0;
    normalizedArguments.length = 0;
}

/**
 *  Initialize new `LogMessage` object by a given definition.
 *  Can only be done once.
 *
 *  Correct functionality is guaranteed when arguments start from either
 *  `0` or `1` and then increase in order, without gaps or repetitions.
 *  `Initialize()` will attempt to correctly initialize `LogMessage` in case
 *  these rules are broken, by making assumptions about user's intentions,
 *  but behavior in that case should be considered undefined.
 *
 *  @param  logMessageDefinition    Definition to take message parameter from.
 */
public final function Initialize(LoggerAPI.Definition logMessageDefinition)
{
    local int                   nextArgument;
    local Parser                parser;
    local MutableText           nextLogPart, nextChunk;
    local BaseText.Character    percentCharacter;
    local array<int>            parsedArguments;
    if (isInitialized) {
        return;
    }
    isInitialized = true;
    myLevel = logMessageDefinition.l;
    percentCharacter = _.text.GetCharacter("%");
    parser = _.text.ParseString(logMessageDefinition.m);
    nextLogPart = _.text.Empty();
    //  General idea is simply to repeat: parse until "%" -> parse "%<number>"
    while (!parser.HasFinished())
    {
        parser.MUntil(nextChunk, percentCharacter).Confirm();
        nextLogPart.Append(nextChunk);
        //  If we cannot parse "%" after `MUntil(nextChunk, percentCharacter)`,
        //  then we have parsed everything
        if (!parser.Match(P("%")).Confirm()) {
            break;
        }
        //  We need to check whether it i really "%<number>" tag and not
        //  just a "%" symbol without number
        if (parser.MInteger(nextArgument).Confirm())
        {
            parsedArguments[parsedArguments.length] = nextArgument;
            logParts[logParts.length] = nextLogPart.Copy();
            nextLogPart.Clear();
        }
        else
        {
            //  If it is just a symbol - simply add it
            nextLogPart.AppendCharacter(percentCharacter);
            parser.R();
        }
    }
    logParts[logParts.length] = nextLogPart.Copy();
    parser.FreeSelf();
    nextLogPart.FreeSelf();
    CleanupEmptyLogParts();
    NormalizeArguments(parsedArguments);
}

//  Since `none` and empty `Text` will be treated the same way by the `Append()`
//  operation, we do not need to keep empty `Text` objects and can simply
//  replace them with `none`s
private final function CleanupEmptyLogParts()
{
    local int i;
    for (i = 0; i < logParts.length; i += 1)
    {
        if (logParts[i].IsEmpty())
        {
            logParts[i].FreeSelf();
            logParts[i] = none;
        }
    }
}

//  Normalize enumeration by replacing them with natural numbers sequence:
//  [0, 1, 2, ...] in the same order:
//  [2, 6, 3] -> [0, 2, 1]
//  [-2, 0, 4, -7] -> [1, 2, 3, 0]
//  [1, 1, 2, 1] -> [0, 1, 3, 2]
private final function NormalizeArguments(array<int> argumentsOrder)
{
    local int i;
    local int nextArgument;
    local int lowestArgument, lowestArgumentIndex;
    normalizedArguments.length = 0;
    normalizedArguments.length = argumentsOrder.length;
    while (nextArgument < normalizedArguments.length)
    {
        //  Find next minimal index and record next natural number
        //  (`nextArgument`) into it
        for (i = 0; i < argumentsOrder.length; i += 1)
        {
            if (argumentsOrder[i] < lowestArgument || i == 0)
            {
                lowestArgumentIndex = i;
                lowestArgument = argumentsOrder[i];
            }
        }
        argumentsOrder[lowestArgumentIndex] = MaxInt;
        normalizedArguments[lowestArgumentIndex] = nextArgument;
        nextArgument += 1;
    }
}

/**
 *  Fills next argument in caller `LogMessage` with given `Text` argument.
 *
 *  When used on `LogMessage` returned from `LoggerAPI.Auto()` call - filling
 *  all arguments leads to message being logged.
 *
 *  @param  argument    This argument will be managed by the `LogMessage`:
 *      you should not deallocate it by hand or rely on passed `Text` to not
 *      be deallocated. This also means that you should not pass `Text` objects
 *      returned by `P()`, `C()` or `F()` calls.
 *  @return Caller `LogMessage` to allow for method chaining.
 */
public final function LogMessage Arg(/*take*/ BaseText argument)
{
    if (IsArgumentListFull()) {
        return self;
    }
    //  Do we need to clean old `LogMessage` from it's arguments first?
    if (default.dirtyLogMessage != none && default.dirtyLogMessage != self) {
        default.dirtyLogMessage.Reset();
    }
    default.dirtyLogMessage = self; //  `self` is dirty with arguments now
    collectedArguments[collectedArguments.length] = argument;
    TryLogging();
    return self;
}

/**
 *  Outputs a message at appropriate level, if all of its arguments were filled.
 */
public final function TryLogging()
{
    local Text assembledMessage;
    if (IsArgumentListFull())
    {
        //  Last argument - have to log what we have collected
        assembledMessage = Collect();
        _.logger.LogAtLevel(assembledMessage, myLevel);
        assembledMessage.FreeSelf();
    }
}

//  Check whether we have enough arguments to completely make log message:
//  each argument goes in between two log parts, so there is
//  `logParts.length - 1` arguments total.
private final function bool IsArgumentListFull()
{
    return collectedArguments.length >= logParts.length - 1;
}

/**
 *  Fills next argument in caller `LogMessage` with given `int` argument.
 *
 *  When used on `LogMessage` returned from `LoggerAPI.Auto()` call - filling
 *  all arguments leads to message being logged.
 *
 *  @param  argument    This value will be converted into `Text` and pasted
 *      into the log message.
 *  @return Caller `LogMessage` to allow for method chaining.
 */
public final function LogMessage ArgInt(int argument)
{
    return Arg(_.text.FromInt(argument));
}

/**
 *  Fills next argument in caller `LogMessage` with given `float` argument.
 *
 *  When used on `LogMessage` returned from `LoggerAPI.Auto()` call - filling
 *  all arguments leads to message being logged.
 *
 *  @param  argument    This value will be converted into `Text` and pasted
 *      into the log message.
 *  @return Caller `LogMessage` to allow for method chaining.
 */
public final function LogMessage ArgFloat(float argument)
{
    return Arg(_.text.FromFloat(argument));
}

/**
 *  Fills next argument in caller `LogMessage` with given `bool` argument.
 *
 *  When used on `LogMessage` returned from `LoggerAPI.Auto()` call - filling
 *  all arguments leads to message being logged.
 *
 *  @param  argument    This value will be converted into `Text` and pasted
 *      into the log message.
 *  @return Caller `LogMessage` to allow for method chaining.
 */
public final function LogMessage ArgBool(bool argument)
{
    return Arg(_.text.FromBool(argument));
}

/**
 *  Fills next argument in caller `LogMessage` with given `class<Object>`
 *  argument.
 *
 *  When used on `LogMessage` returned from `LoggerAPI.Auto()` call - filling
 *  all arguments leads to message being logged.
 *
 *  @param  argument    This value will be converted into `Text` and pasted
 *      into the log message.
 *  @return Caller `LogMessage` to allow for method chaining.
 */
public final function LogMessage ArgClass(class<Object> argument)
{
    return Arg(_.text.FromClass(argument));
}

/**
 *  Resets current progress of filling caller `LogMessage` with arguments,
 *  deallocating already passed ones.
 *
 *  @return Caller `LogMessage` to allow for method chaining.
 */
public final function LogMessage Reset()
{
    _.memory.FreeMany(collectedArguments);
    collectedArguments.length = 0;
    return self;
}

/**
 *  Returns `LogMessage`, assembled with it's arguments into the `Text`.
 *
 *  If some arguments were not yet filled - they will treated as empty `Text`
 *  values.
 *
 *  This result will be reset if `Reset()` method is called or another
 *  `LogMessage` starts filling itself with arguments.
 *
 *  @return Caller `LogMessage`, assembled with it's arguments into the `Text`.
 */
public final function Text Collect()
{
    local int           i, argumentIndex;
    local Text          result;
    local BaseText      nextArgument;
    local MutableText   builder;
    if (logParts.length == 0) {
        return P("").Copy();
    }
    builder = _.text.Empty();
    for (i = 0; i < logParts.length - 1; i += 1)
    {
        nextArgument = none;
        //  Since arguments might not be specified in order - 
        argumentIndex = normalizedArguments[i];
        if (argumentIndex < collectedArguments.length) {
            nextArgument = collectedArguments[argumentIndex];
        }
        builder.Append(logParts[i]).Append(nextArgument);
    }
    builder.Append(logParts[logParts.length - 1]);
    result = builder.Copy();
    builder.FreeSelf();
    return result;
}

defaultproperties
{
}