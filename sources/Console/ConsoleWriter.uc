/**
 *  Object that provides simple access to console output.
 *  Can either write to a certain player's console or to all consoles at once.
 *  Supports "fancy" and "raw" output (for more details @see `ConsoleAPI`).
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
class ConsoleWriter extends AcediaObject
    dependson(ConsoleAPI)
    dependson(ConnectionService);

//  Prefixes we output before every line to signify whether they were broken
//  or not
var private string NEWLINE_PREFIX;
var private string BROKENLINE_PREFIX;
var private string INDENTATION;

/**
 *  Describes current output target of the `ConsoleWriter`.
 */
enum ConsoleWriterTarget
{
    //  No one. Can happed if our target disconnects.
    CWTARGET_None,
    //  A certain player.
    CWTARGET_Player,
    //  All players.
    CWTARGET_All
};
var private ConsoleWriterTarget targetType;
//  Player that will receive output passed to this `ConsoleWriter`.
//  Only used when `targetType == CWTARGET_Player`
var private APlayer             outputTarget;
var private ConsoleBuffer       outputBuffer;

var private ConsoleAPI.ConsoleDisplaySettings   displaySettings;

public final function ConsoleWriter Initialize(
    ConsoleAPI.ConsoleDisplaySettings newDisplaySettings)
{
    displaySettings = newDisplaySettings;
    if (outputBuffer == none) {
        outputBuffer = ConsoleBuffer(_.memory.Allocate(class'ConsoleBuffer'));
    }
    else {
        outputBuffer.Clear();
    }
    outputBuffer.SetSettings(displaySettings);
    return self;
}

/**
 *  Return current default color for caller `ConsoleWriter`.
 *
 *  This method returns default color, i.e. color that will be used if no other
 *  is specified by text you're outputting.
 *  If color is specified, this value will be ignored.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @return Current default color.
 */
public final function Color GetColor()
{
    return displaySettings.defaultColor;
}

/**
 *  Sets default color for caller 'ConsoleWriter`'s output.
 *
 *  This only changes default color, i.e. color that will be used if no other is
 *  specified by text you're outputting.
 *  If color is specified, this value will be ignored.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @param  newDefaultColor New color to use when none specified by text itself.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter SetColor(Color newDefaultColor)
{
    displaySettings.defaultColor = newDefaultColor;
    if (outputBuffer != none) {
        outputBuffer.SetSettings(displaySettings);
    }
    return self;
}

/**
 *  Return current visible limit that describes how many (at most)
 *  visible characters can be output in the console line.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @return Current global visible limit.
 */
public final function int GetVisibleLineLength()
{
    return displaySettings.maxVisibleLineWidth;
}

/**
 *  Sets current visible limit that describes how many (at most) visible
 *  characters can be output in the console line.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @param  newVisibleLimit New global visible limit.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter SetVisibleLineLength(
    int newMaxVisibleLineWidth
)
{
    displaySettings.maxVisibleLineWidth = newMaxVisibleLineWidth;
    if (outputBuffer != none) {
        outputBuffer.SetSettings(displaySettings);
    }
    return self;
}

/**
 *  Return current total limit that describes how many (at most)
 *  characters can be output in the console line.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @return Current global total limit.
 */
public final function int GetTotalLineLength()
{
    return displaySettings.maxTotalLineWidth;
}

/**
 *  Sets current total limit that describes how many (at most)
 *  characters can be output in the console line.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @param  newTotalLimit   New global total limit.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter SetTotalLineLength(int newMaxTotalLineWidth)
{
    displaySettings.maxTotalLineWidth = newMaxTotalLineWidth;
    if (outputBuffer != none) {
        outputBuffer.SetSettings(displaySettings);
    }
    return self;
}

/**
 *  Configures caller `ConsoleWriter` to output to all players.
 *  `Flush()` will be automatically called between target change.
 *
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter ForAll()
{
    Flush();
    targetType = CWTARGET_All;
    return self;
}

/**
 *      Configures caller `ConsoleWriter` to output only to the given player.
 *      `Flush()` will be automatically called between target change.
 *
 *  @param  targetPlayer    Player, to whom console we want to write.
 *      If `none` - caller `ConsoleWriter` would be configured to
 *      throw messages away.
 *  @return ConsoleWriter Returns caller `ConsoleWriter` to allow for
 *      method chaining.
 */
public final function ConsoleWriter ForPlayer(APlayer targetPlayer)
{
    Flush();
    if (targetPlayer != none)
    {
        targetType      = CWTARGET_Player;
        outputTarget    = targetPlayer;
    }
    else {
        targetType = CWTARGET_None;
    }
    return self;
}

/**
 *  Returns type of current target for the caller `ConsoleWriter`.
 *
 *  @return `ConsoleWriterTarget` value, describing current target of
 *      the caller `ConsoleWriter`.
 */
public final function ConsoleWriterTarget CurrentTarget()
{
    if (targetType == CWTARGET_Player && outputTarget == none) {
        targetType = CWTARGET_None;
    }
    return targetType;
}

/**
 *  Returns `APlayer` to whom console caller `ConsoleWriter` is
 *  outputting messages.
 *
 *  @return Player (`APlayer` class) to whom console caller `ConsoleWriter` is
 *      outputting messages. Returns `none` iff it currently outputs to
 *      every player or to no one.
 */
public final function APlayer GetTargetPlayer()
{
    if (targetType == CWTARGET_All) return none;
    return outputTarget;
}

/**
 *  Outputs all buffered input and moves further output onto a new line.
 *
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter Flush()
{
    outputBuffer.Flush();
    SendBuffer();
    return self;
}

/**
 *  Writes text's contents into console.
 *
 *  Does not trigger console output, for that use `WriteLine()` or `Flush()`.
 *
 *  @param  message `Text` to output.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter Write(Text message)
{
    outputBuffer.Insert(message);
    return self;
}

/**
 *  Writes text's contents into console.
 *  Result will be output immediately, starts a new line.
 *
 *  @param  message `Text` to output.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter WriteLine(Text message)
{
    return Write(message).Flush();
}

/**
 *  Writes text's indented contents into console.
 *
 *  Acts like a `Flush().WriteLine()` chain of calls, except all output contents
 *  will be additionally indented by four whitespace symbols
 *  (including lines after line breaks).
 *
 *  Result will be output immediately, starts a new line.
 *
 *  @param  message `Text` to output.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter WriteBlock(Text message)
{
    Flush();
    outputBuffer.Insert(message).Flush();
    SendBuffer(true);
    return self;
}

/**
 *  Writes text's contents into console as a player's chat message, causing them
 *  to appear on screen in vanilla UI.
 *
 *  All the buffer stored in caller `ConsoleWriter` so far will be flushed.
 *  Result will be output immediately. Starts a new line.
 *
 *  @param  message `Text` to output.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter Say(Text message)
{
    Flush();
    outputBuffer.Insert(message).Flush();
    SendBuffer(, true);
    return self;
}

//      Send all completed lines from an `outputBuffer`.
//      Setting `indented` to `true` will cause additional four whitespaces to
//  be added to the output.
private final function SendBuffer(optional bool asIndented, optional bool asSay)
{
    local string                    prefix;
    local ConsoleBuffer.LineRecord  nextLineRecord;
    local array<PlayerController>   recipients;

    recipients = GetRecipientsControllers();
    while (outputBuffer.HasCompletedLines())
    {
        nextLineRecord = outputBuffer.PopNextLine();
        if (nextLineRecord.wrappedLine) {
            prefix = NEWLINE_PREFIX;
        }
        else {
            prefix = BROKENLINE_PREFIX;
        }
        if (asIndented) {
            prefix $= INDENTATION;
        }
        SendConsoleMessage(recipients, prefix $ nextLineRecord.contents, asSay);
    }
}

//      Assumes `playerService != none` and `connectionService != none`,
//  caller function must ensure that.
private final function SendConsoleMessage(
    array<PlayerController> recipients,
    string                  message,
    bool                    asSay)
{
    local int i;
    for (i = 0; i < recipients.length; i += 1)
    {
        if (recipients[i] != none)
        {
            if (asSay) {
                recipients[i].ClientMessage(message);
            }
            else {
                recipients[i].TeamMessage(none, message, 'AcediaConsole');
            }
        }
    }
}

//  Method for retrieving `PlayerController`s of recipients at the moment
//  of the call
private final function array<PlayerController> GetRecipientsControllers()
{
    local int                                   i;
    local PlayerController                      nextRecipient;
    local PlayerService                         playerService;
    local ConnectionService                     connectionService;
    local array<PlayerController>               recipients;
    local array<ConnectionService.Connection>   connections;
    //  No targets
    if (targetType == CWTARGET_None) {
        return recipients;
    }
    //  Single target case
    if (targetType != CWTARGET_All)
    {
        playerService = PlayerService(class'PlayerService'.static.Require());
        if (playerService != none && outputTarget != none) {
            nextRecipient = playerService.GetController(outputTarget);
        }
        if (nextRecipient != none) {
            recipients[0] = nextRecipient;
        }
        return recipients;
    }
    //  All players target case
    connectionService =
        ConnectionService(class'ConnectionService'.static.Require());
    if (connectionService == none) {
        return recipients;
    }
    connections = connectionService.GetActiveConnections();
    for (i = 0; i < connections.length; i += 1)
    {
        if (connections[i].controllerReference != none) {
            recipients[recipients.length] = connections[i].controllerReference;
        }
    }
    return recipients;
}

defaultproperties
{
    NEWLINE_PREFIX      = "| "
    BROKENLINE_PREFIX   = "  "
    INDENTATION         = "    "
}