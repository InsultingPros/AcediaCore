/**
 *  Command for managing trader time and traders.
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
class ACommandTrader extends Command;

var protected const int TLIST, TOPEN, TCLOSE, TENABLE, TDISABLE, TAUTO_OPEN;
var protected const int TTRADER, TTRADERS, TALL, TAUTO_OPEN_QUESTION, TQUOTE;
var protected const int TAUTO_OPEN_FLAG, TDISABLED_FLAG, TUNKNOWN_TRADERS;
var protected const int TLIST_TRADERS, TCOMMA_SPACE, TSELECTED_FLAG;
var protected const int TPARENTHESIS_OPEN, TPARENTHESIS_CLOSE;
var protected const int TSELECT, TIGNORE_DOORS, TBOOT, TTRADER_TIME, TTIME;
var protected const int TIGNORE_PLAYERS, TPAUSE, TUNPAUSE, TCANNOT_PARSE_PARAM;
var protected const int TCLOSEST, TSPACE;

protected function BuildData(CommandDataBuilder builder)
{
    builder.Name(T(TTRADER))
        .Summary(P("Manages trader time and available traders."))
        .Describe(P("Enables of disables trading."))
        .ParamBoolean(T(TENABLE));
    builder.SubCommand(T(TTIME))
        .Describe(F("Changes current trader time if numeric value is specified."
            @ "You can also pause trader countdown by specifying"
            @ "{$TextEmphasis pause} or turn it back on with"
            @ "{$TextEmphasis unpause}."))
        .ParamText(T(TTRADER_TIME));
    builder.SubCommand(T(TLIST))
        .Describe(P("Lists names of all available traders and"
            @ "marks closest one to the caller."));
    builder.SubCommand(T(TOPEN))
        .Describe(P("Opens specified traders."))
        .OptionalParams()
        .ParamTextList(T(TTRADERS));
    builder.SubCommand(T(TCLOSE))
        .Describe(P("Closes specified traders."))
        .OptionalParams()
        .ParamTextList(T(TTRADERS));
    builder.SubCommand(T(TAUTO_OPEN))
        .Describe(P("Sets whether specified traders are open automatically."))
        .ParamBoolean(T(TAUTO_OPEN_QUESTION))
        .OptionalParams()
        .ParamTextList(T(TTRADERS));
    builder.SubCommand(T(TSELECT))
        .Describe(P("Selects specified trader."))
        .OptionalParams()
        .ParamText(T(TTRADER));
    builder.SubCommand(T(TBOOT))
        .Describe(P("Boots all players from specified traders. If no traders"
            @ "were specified - assumes that all of them should be affected."))
        .OptionalParams()
        .ParamTextList(T(TTRADERS));
    builder.SubCommand(T(TENABLE))
        .Describe(P("Enables specified traders."))
        .OptionalParams()
        .ParamTextList(T(TTRADERS));
    builder.SubCommand(T(TDISABLE))
        .Describe(P("Disables specified traders."))
        .OptionalParams()
        .ParamTextList(T(TTRADERS));
    builder.Option(T(TALL))
        .Describe(P("If sub-command targets shops, this flag will make it"
            @ "target all the available shops."));
    builder.Option(T(TCLOSEST))
        .Describe(P("If sub-command targets shops, this flag will make it also"
            @ "target closest shop to the caller."));
    builder.Option(T(TIGNORE_DOORS))
        .Describe(F("When used with {$TextEmphasis select} sub-command, it will"
            @ "neither open or close doors."));
    builder.Option(T(TIGNORE_PLAYERS), P("I"))
        .Describe(P("Normally commands that close doors will automatically boot"
            @ "players from inside to prevent locking them in. This flag forces"
            @ "this command to leave players inside. However they can still be"
            @ "booted out at the end of trading time. Also it is impossible to"
            @ "disable the trader and not boot players inside it."));
}

protected function Executed(CommandCall result)
{
    local Text              subCommand;
    local AssociativeArray  commandParameters, commandOptions;
    subCommand          = result.GetSubCommand();
    commandParameters   = result.GetParameters();
    commandOptions      = result.GetOptions();
    if (subCommand.IsEmpty()) {
        _.kf.trading.SetTradingStatus(commandParameters.GetBool(T(TENABLE)));
    }
    else if (subCommand.Compare(T(TLIST))) {
        ListTradersFor(result.GetCallerPlayer());
    }
    else if (subCommand.Compare(T(TTIME), SCASE_INSENSITIVE)) {
        HandleTraderTime(result);
    }
    else if (subCommand.Compare(T(TOPEN), SCASE_INSENSITIVE)) {
        SetTradersOpen(true, result);
    }
    else if (subCommand.Compare(T(TCLOSE), SCASE_INSENSITIVE)) {
        SetTradersOpen(false, result);
    }
    else if (subCommand.Compare(T(TSELECT), SCASE_INSENSITIVE)) {
        SelectTrader(result);
    }
    else if (subCommand.Compare(T(TBOOT), SCASE_INSENSITIVE)) {
        BootFromTraders(result);
    }
    else if (subCommand.Compare(T(TENABLE), SCASE_INSENSITIVE)) {
        SetTradersEnabled(true, result);
    }
    else if (subCommand.Compare(T(TDISABLE), SCASE_INSENSITIVE)) {
        SetTradersEnabled(false, result);
    }
    else if (subCommand.Compare(T(TAUTO_OPEN), SCASE_INSENSITIVE)) {
        SetTradersAutoOpen(result);
    }
    subCommand.FreeSelf();
}

protected function ListTradersFor(APlayer target)
{
    local int               i;
    local ATrader           closestTrader;
    local ConsoleWriter     console;
    local array<ATrader>    availableTraders;
    if (target == none) {
        return;
    }
    availableTraders = _.kf.trading.GetTraders();
    console = target.Console();
    console.Flush()
        .UseColor(_.color.TextEmphasis)
        .Write(T(TLIST_TRADERS))
        .ResetColor();
    closestTrader = FindClosestTrader(target);
    for (i = 0; i < availableTraders.length; i += 1)
    {
        WriteTrader(availableTraders[i], availableTraders[i] == closestTrader,
                    console);
        if (i != availableTraders.length - 1) {
            console.Write(T(TCOMMA_SPACE));
        }
    }
    console.Flush();
}

protected function HandleTraderTime(CommandCall result)
{
    local int       countDownValue;
    local Text      parameter;
    local Parser    parser;
    local APlayer   callerPlayer;
    parameter = result.GetParameters().GetText(T(TTRADER_TIME));
    if (parameter.Compare(T(TPAUSE), SCASE_INSENSITIVE))
    {
        _.kf.trading.SetCountDownPause(true);
        return;
    }
    else if (parameter.Compare(T(TUNPAUSE), SCASE_INSENSITIVE))
    {
        _.kf.trading.SetCountDownPause(false);
        return;
    }
    parser = _.text.Parse(parameter);
    if (parser.MInteger(countDownValue).Ok()) {
        _.kf.trading.SetCountDown(countDownValue);
    }
    else
    {
        callerPlayer = result.GetCallerPlayer();
        if (callerPlayer != none)
        {
            callerPlayer.Console()
                .UseColor(_.color.TextFailure)
                .Write(T(TCANNOT_PARSE_PARAM))
                .WriteLine(parameter)
                .ResetColor();
        }
    }
    parser.FreeSelf();

}

protected function SetTradersOpen(bool doOpen, CommandCall result)
{
    local int               i;
    local bool              needToBootPlayers;
    local array<ATrader>    selectedTraders;
    selectedTraders = GetTradersArray(result);
    needToBootPlayers = !doOpen
        && !result.GetOptions().HasKey(T(TIGNORE_PLAYERS));
    for (i = 0; i < selectedTraders.length; i += 1)
    {
        selectedTraders[i].SetOpen(doOpen);
        if (needToBootPlayers) {
            selectedTraders[i].BootPlayers();
        }
    }
}

protected function SelectTrader(CommandCall result)
{
    local int               i;
    local APlayer           callerPlayer;
    local ConsoleWriter     console;
    local Text              selectedTraderName, nextTraderName;
    local ATrader           previouslySelectedTrader;
    local array<ATrader>    availableTraders;
    selectedTraderName          = result.GetParameters().GetText(T(TTRADER));
    previouslySelectedTrader    = _.kf.trading.GetSelectedTrader();
    //  Corner case: no new trader
    if (selectedTraderName == none)
    {
        _.kf.trading.SelectTrader(none);
        HandleTraderSwap(result, none, availableTraders[i]);
        return;
    }
    //  Find new trader among available ones
    availableTraders = _.kf.trading.GetTraders();
    for (i = 0; i < availableTraders.length; i += 1)
    {
        nextTraderName = availableTraders[i].GetName();
        if (selectedTraderName.Compare(nextTraderName))
        {
            availableTraders[i].Select();
            HandleTraderSwap(   result, previouslySelectedTrader,
                                availableTraders[i]);
            nextTraderName.FreeSelf();
            return;
        }
        nextTraderName.FreeSelf();
    }
    //  If we have reached here: given trader name was invalid.
    callerPlayer = result.GetCallerPlayer();
    if (callerPlayer != none) {
        console = callerPlayer.Console();
    }
    if (console != none)
    {
        console.Flush()
            .UseColor(_.color.TextNegative).Write(T(TUNKNOWN_TRADERS))
            .ResetColor().WriteLine(selectedTraderName);
    }
}

//  Boot players from the old trader iff
//      1. It's different from the new one (otherwise swapping means nothing);
//      2. Option "ignore-players" was not specified.
protected function HandleTraderSwap(
    CommandCall result,
    ATrader     oldTrader,
    ATrader     newTrader)
{
    if (oldTrader == none)                              return;
    if (oldTrader == newTrader)                         return;
    if (result.GetOptions().HasKey(T(TIGNORE_DOORS)))   return;
    if (result.GetOptions().HasKey(T(TIGNORE_PLAYERS))) return;

    oldTrader.Close().BootPlayers();
    if (newTrader != none) {
        newTrader.Open();
    }
}

protected function BootFromTraders(CommandCall result)
{
    local int               i;
    local array<ATrader>    selectedTraders;
    selectedTraders = GetTradersArray(result);
    if (selectedTraders.length <= 0) {
        selectedTraders = _.kf.trading.GetTraders();
    }
    for (i = 0; i < selectedTraders.length; i += 1) {
        selectedTraders[i].BootPlayers();
    }
}

protected function SetTradersEnabled(bool doEnable, CommandCall result)
{
    local int               i;
    local array<ATrader>    selectedTraders;
    selectedTraders = GetTradersArray(result);
    for (i = 0; i < selectedTraders.length; i += 1) {
        selectedTraders[i].SetEnabled(doEnable);
    }
}

protected function SetTradersAutoOpen(CommandCall result)
{
    local int               i;
    local bool              doAutoOpen;
    local array<ATrader>    selectedTraders;
    doAutoOpen = result.GetParameters().GetBool(T(TAUTO_OPEN_QUESTION));
    selectedTraders = GetTradersArray(result);
    for (i = 0; i < selectedTraders.length; i += 1) {
        selectedTraders[i].SetAutoOpen(doAutoOpen);
    }
}

//  Reads traders specified for the command (if any).
//  Assumes `result != none`.
protected function array<ATrader> GetTradersArray(CommandCall result)
{
    local int               i, j;
    local APLayer           callerPlayer;
    local Text              nextTraderName;
    local DynamicArray      specifiedTrades;
    local array<ATrader>    resultTraders;
    local array<ATrader>    availableTraders;
    //  Boundary cases: all traders and no traders at all
    availableTraders = _.kf.trading.GetTraders();
    if (result.GetOptions().HasKey(T(TALL))) {
        return availableTraders;
    }
    //  Add closest one, if flag tells us to
    callerPlayer = result.GetCallerPlayer();
    if (result.GetOptions().HasKey(T(TCLOSEST)))
    {
        resultTraders =
            InsertTrader(resultTraders, FindClosestTrader(callerPlayer));
    }
    specifiedTrades = result.GetParameters().GetDynamicArray(T(TTRADERS));
    if (specifiedTrades == none) {
        return resultTraders;
    }
    //  We iterate over `availableTraders` in the outer loop because:
    //  1. Each `ATrader` from `availableTraders` will be matched only once,
    //      ensuring that result will not contain duplicate instances;
    //  2. `availableTraders.GetName()` creates a new `Text` copy and
    //      `specifiedTrades.GetText()` does not.
    for (i = 0; i < availableTraders.length; i += 1)
    {
        nextTraderName = availableTraders[i].GetName();
        for (j = 0; j < specifiedTrades.GetLength(); j += 1)
        {
            if (nextTraderName.Compare(specifiedTrades.GetText(j)))
            {
                resultTraders =
                    InsertTrader(resultTraders, availableTraders[i]);
                specifiedTrades.Remove(j, 1);
                break;
            }
        }
        nextTraderName.FreeSelf();
        if (specifiedTrades.GetLength() <= 0) {
            break;
        }
    }
    //  Some of the remaining trader names inside `specifiedTrades` do not
    //  match any actual traders. Report it.
    if (callerPlayer != none && specifiedTrades.GetLength() > 0) {
        ReportUnknowTraders(specifiedTrades, callerPlayer.Console());
    }
    return resultTraders;
}

//  Auxiliary method that adds `newTrader` into existing array of traders
//  if it is still missing.
protected function array<ATrader> InsertTrader(
    array<ATrader>  traders,
    ATrader         newTrader)
{
    local int i;
    if (newTrader == none) {
        return traders;
    }
    for (i = 0; i < traders.length; i += 1)
    {
        if (traders[i] == newTrader) {
            return traders;
        }
    }
    traders[traders.length] = newTrader;
    return traders;
}

protected function ReportUnknowTraders(
    DynamicArray    specifiedTrades,
    ConsoleWriter   console)
{
    local int i;
    if (console == none)            return;
    if (specifiedTrades == none)    return;

    console.Flush()
        .UseColor(_.color.TextNegative)
        .Write(T(TUNKNOWN_TRADERS))
        .ResetColor();
    for (i = 0; i < specifiedTrades.GetLength(); i += 1)
    {
        console.Write(specifiedTrades.GetText(i));
        if (i != specifiedTrades.GetLength() - 1) {
            console.Write(T(TCOMMA_SPACE));
        }
    }
    console.Flush();
}

//  Find closest trader to the `target` player
protected function ATrader FindClosestTrader(APlayer target)
{
    local int               i;
    local float             newDistance, bestDistance;
    local ATrader           bestTrader;
    local array<ATrader>    availableTraders;
    local Vector            targetLocation;
    if (target == none) {
        return none;
    }
    targetLocation = target.GetLocation();
    availableTraders = _.kf.trading.GetTraders();
    for (i = 0; i < availableTraders.length; i += 1)
    {
        newDistance =
            VSizeSquared(availableTraders[i].GetLocation() - targetLocation);
        if (bestTrader == none || newDistance < bestDistance)
        {
            bestTrader = availableTraders[i];
            bestDistance = newDistance;
        }
    }
    return bestTrader;
}

//  Writes a trader name along with information on whether it's
//  disabled / auto-open
protected function WriteTrader(
    ATrader         traderToWrite,
    bool            isClosestTrader,
    ConsoleWriter   console)
{
    local Text traderName;
    if (traderToWrite == none)  return;
    if (console == none)        return;

    console.Write(T(TQUOTE));
    if (traderToWrite.IsOpen()) {
        console.UseColor(_.color.TextPositive);
    }
    else {
        console.UseColor(_.color.TextNegative);
    }
    traderName = traderToWrite.GetName();
    console.Write(traderName)
        .ResetColor()
        .Write(T(TQUOTE));
    traderName.FreeSelf();
    WriteTraderTags(traderToWrite, isClosestTrader, console);
}

protected function WriteTraderTags(
    ATrader         traderToWrite,
    bool            isClosest,
    ConsoleWriter   console)
{
    local bool hasTagsInFront;
    local bool isAutoOpen, isSelected;
    if (traderToWrite == none) {
        return;
    }
    if (!traderToWrite.IsEnabled())
    {
        console.Write(T(TDISABLED_FLAG));
        return;
    }
    isAutoOpen = traderToWrite.IsAutoOpen();
    isSelected = traderToWrite.IsSelected();
    if (!isAutoOpen && !isSelected && !isClosest) {
        return;
    }
    console.Write(T(TSPACE)).Write(T(TPARENTHESIS_OPEN));
    if (isClosest)
    {
        console.Write(T(TCLOSEST));
        hasTagsInFront = true;
    }
    if (isAutoOpen)
    {
        if (hasTagsInFront) {
            console.Write(T(TCOMMA_SPACE));
        }
        console.Write(T(TAUTO_OPEN_FLAG));
        hasTagsInFront = true;
    }
    if (isSelected)
    {
        if (hasTagsInFront) {
            console.Write(T(TCOMMA_SPACE));
        }
        console.Write(T(TSELECTED_FLAG));
    }
    console.Write(T(TPARENTHESIS_CLOSE));
}

defaultproperties
{
    TLIST               = 0
    stringConstants(0)  = "list"
    TOPEN               = 1
    stringConstants(1)  = "open"
    TCLOSE              = 2
    stringConstants(2)  = "close"
    TENABLE             = 3
    stringConstants(3)  = "enable"
    TDISABLE            = 4
    stringConstants(4)  = "disable"
    TAUTO_OPEN          = 5
    stringConstants(5)  = "autoopen"
    TTRADER             = 6
    stringConstants(6)  = "trader"
    TTRADERS            = 7
    stringConstants(7)  = "traders"
    TALL                = 8
    stringConstants(8)  = "all"
    TAUTO_OPEN_QUESTION = 9
    stringConstants(9)  = "autoOpen?"
    TQUOTE              = 10
    stringConstants(10) = "\""
    TAUTO_OPEN_FLAG     = 11
    stringConstants(11) = "auto-open"
    TDISABLED_FLAG      = 12
    stringConstants(12) = " (disabled)"
    TUNKNOWN_TRADERS    = 13
    stringConstants(13) = "Could not find some of the traders: "
    TLIST_TRADERS       = 14
    stringConstants(14) = "List of available traders: "
    TCOMMA_SPACE        = 15
    stringConstants(15) = ", "
    TPARENTHESIS_OPEN   = 16
    stringConstants(16) = "("
    TPARENTHESIS_CLOSE  = 17
    stringConstants(17) = ")"
    TSELECTED_FLAG      = 18
    stringConstants(18) = "selected"
    TSELECT             = 19
    stringConstants(19) = "select"
    TIGNORE_DOORS       = 20
    stringConstants(20) = "ignore-doors"
    TBOOT               = 21
    stringConstants(21) = "boot"
    TTIME               = 22
    stringConstants(22) = "time"
    TTRADER_TIME        = 23
    stringConstants(23) = "traderTime"
    TIGNORE_PLAYERS     = 24
    stringConstants(24) = "ignore-players"
    TPAUSE              = 25
    stringConstants(25) = "pause"
    TUNPAUSE            = 26
    stringConstants(26) = "unpause"
    TCANNOT_PARSE_PARAM = 27
    stringConstants(27) = "Cannot parse parameter: "
    TCLOSEST            = 28
    stringConstants(28) = "closest"
    TSPACE              = 29
    stringConstants(29) = " "
}