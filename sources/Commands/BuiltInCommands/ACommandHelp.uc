/**
 *  Command for displaying help information about registered Acedia's commands.
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
class ACommandHelp extends Command;

protected function BuildData(CommandDataBuilder builder)
{
    builder.OptionalParams()
        .ParamTextList(P("commands"))
        .Describe(P("Displays information about all specified commands."));
    builder.Option(P("list"))
        .Describe(P("Displays list of all available commands."));
}

protected function Executed(CommandCall callInfo)
{
    local AssociativeArray  parameters;
    local DynamicArray      commandsToDisplay;
    local APlayer           callerPlayer;
    callerPlayer = callInfo.GetCallerPlayer();
    if (callerPlayer == none) return;

    //  Command list
    if (callInfo.GetOptions().HasKey(P("list"))) {
        DisplayCommandList(callerPlayer);
    }
    //  Help pages
    parameters = callInfo.GetParameters();
    commandsToDisplay = DynamicArray(parameters.GetItem(P("commands")));
    DisplayCommandHelpPages(callerPlayer, commandsToDisplay);
}

private final function DisplayCommandList(APlayer player)
{
    local int           i;
    local ConsoleWriter console;
    local array<Text>   commandNames;
    local Commands      commandsFeature;
    if (player == none)             return;
    commandsFeature = Commands(class'Commands'.static.GetInstance());
    if (commandsFeature == none)    return;

    console = player.Console();
    commandNames = commandsFeature.GetCommandNames();
    for (i = 0; i < commandNames.length; i += 1) {
        console.WriteLine(commandNames[i]);
    }
    _.memory.FreeMany(commandNames);
}

private final function DisplayCommandHelpPages(
    APlayer         player,
    DynamicArray    commandList)
{
    local int       i;
    local Text      nextHelpPage;
    local Command   nextCommand;
    local Commands  commandsFeature;
    if (player == none)             return;
    commandsFeature = Commands(class'Commands'.static.GetInstance());
    if (commandsFeature == none)    return;

    //  If arguments were empty - at least display our own help page
    if (commandList.GetLength() == 1 && Text(commandList.GetItem(0)).IsEmpty())
    {
        nextHelpPage = PrintHelp();
        player.Console().WriteLine(nextHelpPage).Flush();
        nextHelpPage.FreeSelf();
        return;
    }
    for (i = 0; i < commandList.GetLength(); i += 1)
    {
        nextCommand = commandsFeature.GetCommand(Text(commandList.GetItem(i)));
        if (nextCommand == none) continue;
        nextHelpPage = nextCommand.PrintHelp();
        player.Console().WriteLine(nextHelpPage);
        nextHelpPage.FreeSelf();
    }
    player.Console().Flush();
}

defaultproperties
{
    commandName = "help"
}