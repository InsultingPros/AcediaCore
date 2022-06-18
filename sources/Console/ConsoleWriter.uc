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
    //  A certain set of players.
    CWTARGET_Players,
    //  All players.
    CWTARGET_All
};
var private ConsoleWriterTarget targetType;
//  Players that will receive output passed to this `ConsoleWriter`.
//  Only used when `targetType == CWTARGET_Players`
//  Cannot be allowed to contain `none` values.
var private array<EPlayer>      outputTargets;
var private ConsoleBuffer       outputBuffer;

var private bool                                needToResetColor;
var private ConsoleAPI.ConsoleDisplaySettings   displaySettings;
//      Sometimes we want to output a certain part of text with a color
//  different from the default one. However this requires to remember current
//  default in additional variable, set new color and then return the old one.
//  To slightly simplify this process we use pair of `UseColor()`/`ResetColor()`
//  methods that use this variable to remember "real" default color and allowing
//  us to quickly reset back to it.
//      This also means that `displaySettings` can sometimes store "default"
//  color information instead.
var private Color                               defaultColor;

protected function Finalizer()
{
    _.memory.FreeMany(outputTargets);
    _.memory.Free(outputBuffer);
    outputTargets.length = 0;
    outputBuffer = none;
}

public final function ConsoleWriter Initialize(
    ConsoleAPI.ConsoleDisplaySettings newDisplaySettings)
{
    defaultColor = newDisplaySettings.defaultColor;
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
 *  Return default color setting for caller `ConsoleWriter`. It can be
 *  temporarily overwritten by `UseColor()` method.
 *
 *      This method returns default color setting, i.e. color that will be used
 *  if no other is specified by text you're outputting and if it was not
 *  overwritten with `UseColor()` method.
 *      To get color currently used for outputting text, see `GetColor()`
 *  method.
 *
 *      Do note that `ConsoleWriter` can have two "default" colors: a "real"
 *  default and a "temporary" default: "temporary" one can be set with
 *  `UseColor()` or `UseColorOnce()` method calls to temporarily color certain
 *  part of the output and then revert to the "real" default color.
 *      This method always returns "real" default color.
 *
 *  This value is not synchronized with the global value from `ConsoleAPI`
 *  (or such value from any other `ConsoleWriter`) and affects only
 *  output produced by this `ConsoleWriter`.
 *
 *  @return Current default color (the one that will be used to color output
 *      text after `ResetColor()` method call).
 */
public final function Color GetDefaultColor()
{
    return defaultColor;
}

/**
 *  Return currently used default color for caller `ConsoleWriter`.
 *
 *      This method returns default color, i.e. color that will be used if
 *  no other is specified by text you're outputting. If color is specified,
 *  this value is ignored.
 *      See also `GetDefaultColor()`.
 *
 *      Do note that `ConsoleWriter` can have two "default" colors: a "real"
 *  default and a "temporary" default: "temporary" one can be set with
 *  `UseColor()` or `UseColorOnce()` method calls to temporarily color certain
 *  part of the output and then revert to the "real" default color.
 *      This method always return the color that will be actually used to
 *  output text, so "temporary" default if it's set and "real" default
 *  otherwise.
 *
 *  @return Current default color (currently used to output text information).
 */
public final function Color GetColor()
{
    return displaySettings.defaultColor;
}

/**
 *  Sets default color for caller 'ConsoleWriter`'s output.
 *
 *  This only changes default color, i.e. color that will be used if no other is
 *  specified by "temporary" color. If color is specified, this value will
 *  be ignored.
 *
 *  If you only want to quickly color certain part of output, it is better to
 *  use `UseColor()` or `UseColorOnce()` methods that temporarily changes used
 *  default color and allow to return to actual default color with
 *  `ResetColor()` method.
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
    defaultColor = newDefaultColor;
    displaySettings.defaultColor = newDefaultColor;
    if (outputBuffer != none) {
        outputBuffer.SetSettings(displaySettings);
    }
    return self;
}

/**
 *  Sets "temporary" default color that can be reverted to "real" default color
 *  with `ResetColor()` method.
 *
 *  For quickly coloring certain parts of output:
 *  `console.UseColor(_.color.blue).Write(blueMessage)
 *  .Write(moreBlueMessage).ResetColor()`.
 *  Also see `UseColorOnce()` method.
 *
 *  Consecutive calls do not "stack up" colors - only last one is remembered:
 *      `console.UseColor(_.color.blue).UseColor(_.color.green)` is the same as
 *      `console.UseColor(_.color.green)`.
 *
 *  Use `SetColor()` to set both "real" and "temporary" color.
 *
 *  @param  temporaryColor  Color to use as default one in the next console
 *      output calls until the `ResetColor()` method call.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter UseColor(Color temporaryColor)
{
    needToResetColor = false;
    displaySettings.defaultColor = temporaryColor;
    if (outputBuffer != none) {
        outputBuffer.SetSettings(displaySettings);
    }
    return self;
}

/**
 *  Sets "temporary" default color that will be automatically reverted to "real"
 *  default color after any "writing" method (i.e. `Write()`, `WriteLine()`,
 *  `WriteBlock()` or `Say()`) or when `ResetColor()` method is called.
 *
 *  For quickly coloring certain parts of output:
 *  `console.UseColorOnce(_.color.blue).Write(blueMessage)`.
 *
 *  Consecutive calls do not "stack up" colors - only last one is remembered:
 *      `console.UseColorOnce(_.color.blue).UseColorOnce(_.color.green)`
 *      is the same as `console.UseColorOnce(_.color.green)`.
 *
 *  Use `SetColor()` to set both "real" and "temporary" color.
 *
 *  @param  temporaryColor  Color to use as default one in the next console
 *      output calls until any "writing" method (or `ResetColor()` method)
 *      is called.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter UseColorOnce(Color temporaryColor)
{
    needToResetColor = true;
    displaySettings.defaultColor = temporaryColor;
    if (outputBuffer != none) {
        outputBuffer.SetSettings(displaySettings);
    }
    return self;
}

/**
 *  Resets "temporary" default text color to "real" default color.
 *  See `UseColor()` and `UseColorOnce()` for details.
 *
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter ResetColor()
{
    needToResetColor = false;
    displaySettings.defaultColor = defaultColor;
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
 *      Configures caller `ConsoleWriter` to output to all players.
 *      `Flush()` will be automatically called if target actually has to switch
 *  (before the switch occurs).
 *
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter ForAll()
{
    if (targetType != CWTARGET_All) {
        Flush();
    }
    targetType = CWTARGET_All;
    return self;
}

/**
 *      Configures caller `ConsoleWriter` to output only to the given player.
 *      `Flush()` will be automatically called if target actually has to switch
 *  (before the switch occurs).
 *
 *  @param  targetPlayer    Player, to whom console we want to write.
 *      If `none` - caller `ConsoleWriter` would be configured to
 *      throw messages away.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter ForPlayer(EPlayer targetPlayer)
{
    if (targetPlayer == none)
    {
        Flush();
        targetType = CWTARGET_None;
        return self;
    }
    if (targetType != CWTARGET_Players) {
        Flush();
    }
    outputTargets.length = 0;
    targetType          = CWTARGET_Players;
    outputTargets[0]    = EPlayer(targetPlayer.Copy());
    return self;
}

/**
 *      Configures caller `ConsoleWriter` to output to one more player,
 *  given by `targetPlayer`.
 *      `Flush()` will be automatically called if target actually has to switch
 *  (before the switch occurs).
 *
 *  @param  targetPlayer    Player, to whom console we want to write.
 *      If `none` - this method will do nothing.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter AndPlayer(EPlayer targetPlayer)
{
    local int i;
    if (targetPlayer == none)       return self;
    if (!targetPlayer.IsExistent()) return self;

    if (targetType != CWTARGET_Players)
    {
        Flush();
        _.memory.FreeMany(outputTargets);
        if (targetType == CWTARGET_None) {
            outputTargets.length = 0;
        }
        else {
            outputTargets = _.players.GetAll();
        }
    }
    targetType = CWTARGET_Players;
    for (i = 0; i < outputTargets.length; i += 1)
    {
        if (targetPlayer.SameAs(outputTargets[i])) {
            return self;
        }
    }
    Flush();
    outputTargets[outputTargets.length] = EPlayer(targetPlayer.Copy());
    return self;
}

/**
 *      Configures caller `ConsoleWriter` to output to one less player,
 *  given by `targetPlayer`.
 *      `Flush()` will be automatically called if target actually has to switch
 *  (before the switch occurs).
 *
 *  @param  targetPlayer    Player, to whom console we no longer want to write.
 *      If `none` - this method will do nothing.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter ButPlayer(EPlayer playerToRemove)
{
    local int i;
    if (targetType == CWTARGET_None)    return self;
    if (playerToRemove == none)         return self;
    if (!playerToRemove.IsExistent())   return self;

    if (targetType == CWTARGET_All)
    {
        Flush();
        _.memory.FreeMany(outputTargets);
        outputTargets = _.players.GetAll();
    }
    targetType = CWTARGET_Players;
    while (i < outputTargets.length)
    {
        if (playerToRemove.SameAs(outputTargets[i]))
        {
            Flush();
            _.memory.Free(outputTargets[i]);
            outputTargets.Remove(i, 1);
            break;
        }
        i += 1;
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
    if (targetType == CWTARGET_Players && outputTargets.length == 0) {
        targetType = CWTARGET_None;
    }
    return targetType;
}

/**
 *      Returns `EPlayer` to whom console caller `ConsoleWriter` is
 *  outputting messages.
 *      If caller `ConsoleWriter` is setup to message several different players,
 *  returns an arbitrary one of them.
 *
 *  @return Player (`EPlayer` class) to whom console caller `ConsoleWriter` is
 *      outputting messages. Returns `none` iff it currently outputs to
 *      every player or to no one.
 */
public final function EPlayer GetTargetPlayer()
{
    if (targetType == CWTARGET_All) return none;
    if (outputTargets.length <= 0)  return none;

    return EPlayer(outputTargets[0].Copy());
}

/**
 *      Returns array of `EPlayer`s, to whom console caller `ConsoleWriter` is
 *  outputting messages.
 *
 *  @return Player (`EPlayer` class) to whom console caller `ConsoleWriter` is
 *      outputting messages. Returned array is guaranteed to not contain `none`s
 *      or `EPlayer` interfaces with non-existent status.
 */
public final function array<EPlayer> GetTargetPlayers()
{
    local int               i;
    local array<EPlayer>    result;
    if (targetType == CWTARGET_None)    return result;
    if (targetType == CWTARGET_All)     return _.players.GetAll();

    for (i = 0; i < outputTargets.length; i += 1)
    {
        if (outputTargets[i].IsExistent()) {
            result[result.length] = EPlayer(outputTargets[i].Copy());
        }
    }
    return result;
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
public final function ConsoleWriter Write(optional BaseText message)
{
    outputBuffer.Insert(message);
    if (needToResetColor) {
        ResetColor();
    }
    return self;
}

/**
 *  Writes text's contents into console.
 *  Result will be output immediately, starts a new line.
 *
 *  @param  message `Text` to output.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter WriteLine(optional BaseText message)
{
    return Write(message).Flush();
}

/**
 *  Writes text's indented contents into console.
 *
 *  Acts like a `WriteLine()` call, except all output contents will be
 *  additionally indented by four whitespace symbols
 *  (including lines after line breaks).
 *
 *  Result will be output immediately, starts a new line.
 *
 *  @param  message `Text` to output.
 *  @return Returns caller `ConsoleWriter` to allow for method chaining.
 */
public final function ConsoleWriter WriteBlock(optional BaseText message)
{
    outputBuffer.Insert(message).Flush();
    SendBuffer(true);
    if (needToResetColor) {
        ResetColor();
    }
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
public final function ConsoleWriter Say(optional BaseText message)
{
    outputBuffer.Insert(message).Flush();
    SendBuffer(, true);
    if (needToResetColor) {
        ResetColor();
    }
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

//  Assumes `connectionService != none`, caller function must ensure that.
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
    local ConnectionService                     connectionService;
    local array<PlayerController>               recipients;
    local array<ConnectionService.Connection>   connections;
    //  No targets
    if (targetType == CWTARGET_None) {
        return recipients;
    }
    //  Selected targets case
    if (targetType != CWTARGET_All)
    {
        for (i = 0; i < outputTargets.length; i += 1)
        {
            nextRecipient = outputTargets[i].GetController();
            if (nextRecipient != none) {
                recipients[recipients.length] = nextRecipient;
            }
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