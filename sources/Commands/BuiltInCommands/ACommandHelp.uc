/**
 *  Command for displaying help information about registered Acedia's commands.
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
class ACommandHelp extends Command
    dependson(LoggerAPI);

var LoggerAPI.Definition testMsg;

var public const int TSPACE, TCOMMAND_NAME_FALLBACK, TPLUS;
var public const int TOPEN_BRACKET, TCLOSE_BRACKET, TCOLUMN_SPACE;
var public const int TKEY, TDOUBLE_KEY, TCOMMA_SPACE, TBOOLEAN, TINDENT;
var public const int TBOOLEAN_TRUE_FALSE, TBOOLEAN_ENABLE_DISABLE;
var public const int TBOOLEAN_ON_OFF, TBOOLEAN_YES_NO;
var public const int TOPTIONS, TCMD_WITH_TARGET, TCMD_WITHOUT_TARGET;
var public const int TSEPARATOR, TLIST_REGIRESTED_CMDS, TEMPTY_GROUP;

protected function BuildData(CommandDataBuilder builder)
{
    builder.Name(P("help")).Group(P("core"))
        .Summary(P("Displays detailed information about available commands."));
    builder.OptionalParams()
        .ParamTextList(P("commands"))
        .Describe(P("Displays information about all specified commands."));
    builder.Option(P("list"))
        .Describe(P("Display available commands. Optionally command groups can"
            @ "be specified and then only commands from such groups will be"
            @ "listed. Otherwise all commands will be displayed."))
        .OptionalParams()
        .ParamTextList(P("groups"));
}

protected function Executed(Command.CallData callData, EPlayer callerPlayer)
{
    local HashTable parameters, options;;
    local ArrayList commandsToDisplay, commandGroupsToDisplay;
    parameters  = callData.parameters;
    options     = callData.options;
    //  Print command list if "--list" option was specified
    if (options.HasKey(P("list")))
    {
        commandGroupsToDisplay = options.GetArrayListBy(P("/list/groups"));
        DisplayCommandLists(commandGroupsToDisplay);
        _.memory.Free(commandGroupsToDisplay);
    }
    //  Help pages.
    //  Only need to print them if:
    //      1. Any commands are specified as parameters;
    //      2. No commands or "--list" option was specified, then we want to
    //          print a help page for this command.
    if (!options.HasKey(P("list")) || parameters.HasKey(P("commands")))
    {
        commandsToDisplay = parameters.GetArrayList(P("commands"));
        DisplayCommandHelpPages(commandsToDisplay);
        _.memory.Free(commandsToDisplay);
    }
}

private final function DisplayCommandLists(ArrayList commandGroupsToDisplay)
{
    local int               i;
    local array<Text>       commandNames, groupsNames;
    local Commands_Feature  commandsFeature;

    commandsFeature =
        Commands_Feature(class'Commands_Feature'.static.GetEnabledInstance());
    if (commandsFeature == none) {
        return;
    }
    if (commandGroupsToDisplay == none)
    {
        groupsNames = commandsFeature.GetGroupsNames();
        DisplayCommandsNamesArray(commandsFeature, commandNames);
    }
    else
    {
        for (i = 0; i < commandGroupsToDisplay.GetLength(); i += 1) {
            groupsNames[groupsNames.length] = commandGroupsToDisplay.GetText(i);
        }
    }
    callerConsole.WriteLine(T(TLIST_REGIRESTED_CMDS));
    for (i = 0; i < groupsNames.length; i += 1)
    {
        if (groupsNames[i] == none) {
            continue;
        }
        commandNames = commandsFeature.GetCommandNamesInGroup(groupsNames[i]);
        if (commandNames.length > 0)
        {
            callerConsole.UseColorOnce(_.color.TextSubHeader);
            if (groupsNames[i].IsEmpty()) {
                callerConsole.WriteLine(T(TEMPTY_GROUP));
            }
            else {
                callerConsole.WriteLine(groupsNames[i]);
            }
            DisplayCommandsNamesArray(commandsFeature, commandNames);
            _.memory.FreeMany(commandNames);
        }
    }
    _.memory.FreeMany(groupsNames);
}

private final function DisplayCommandsNamesArray(
    Commands_Feature    commandsFeature,
    array<Text>         commandsNamesArray)
{
    local int           i;
    local Command       nextCommand;
    local Command.Data  nextData;

    for (i = 0; i < commandsNamesArray.length; i += 1)
    {
        nextCommand = commandsFeature.GetCommand(commandsNamesArray[i]);
        if (nextCommand == none) {
            continue;
        }
        nextData = nextCommand.BorrowData();
        callerConsole.UseColor(_.color.textEmphasis)
            .Write(nextData.name)
            .ResetColor()
            .Write(T(TCOLUMN_SPACE))
            .WriteLine(nextData.summary);
        _.memory.Free(nextCommand);
    }
}

private final function DisplayCommandHelpPages(ArrayList commandList)
{
    local int               i;
    local Text              nextCommandName;
    local Command           nextCommand;
    local Commands_Feature  commandsFeature;
    commandsFeature =
        Commands_Feature(class'Commands_Feature'.static.GetEnabledInstance());
    if (commandsFeature == none) {
        return;
    }
    //  If arguments were empty - at least display our own help page
    if (commandList == none)
    {
        PrintHelpPage(BorrowData());
        return;
    }
    //  Otherwise - print help for specified commands
    for (i = 0; i < commandList.GetLength(); i += 1)
    {
        nextCommandName = commandList.GetText(i);
        nextCommand = commandsFeature.GetCommand(nextCommandName);
        _.memory.Free(nextCommandName);
        if (nextCommand == none) {
            continue;
        }
        if (i > 0) {
            callerConsole.WriteLine(T(TSEPARATOR));
        }
        PrintHelpPage(nextCommand.BorrowData());
        _.memory.Free(nextCommand);
    }
}

//  Following methods are mostly self-explanatory
private final function PrintHelpPage(Command.Data data)
{
    local Text commandNameUpperCase;
    //  Get capitalized command name
    commandNameUpperCase = data.name.UpperCopy();
    //  Print header: name + basic info
    callerConsole.UseColor(_.color.textHeader)
        .Write(commandNameUpperCase)
        .UseColor(_.color.textDefault);
    commandNameUpperCase.FreeSelf();
    if (data.requiresTarget) {
        callerConsole.WriteLine(T(TCMD_WITH_TARGET));
    }
    else {
        callerConsole.WriteLine(T(TCMD_WITHOUT_TARGET));
    }
    //  Print commands and options
    PrintCommands(data);
    PrintOptions(data);
    //  Clean up
    callerConsole.ResetColor().Flush();
}

private final function PrintCommands(Command.Data data)
{
    local int               i;
    local array<SubCommand> subCommands;
    subCommands = data.subCommands;
    for (i = 0; i < subCommands.length; i += 1) {
        PrintSubCommand(subCommands[i], data.name);
    }
}

private final function PrintSubCommand(
    SubCommand  subCommand,
    BaseText    commandName)
{
    //  Command + parameters
    //  Command name + sub command name
    callerConsole.UseColor(_.color.textEmphasis)
        .Write(commandName)
        .Write(T(TSPACE));
    if (subCommand.name != none && !subCommand.name.IsEmpty()) {
        callerConsole.Write(subCommand.name).Write(T(TSPACE));
    }
    callerConsole.UseColor(_.color.textDefault);
    //  Parameters
    PrintParameters(subCommand.required, subCommand.optional);
    callerConsole.Flush();
    //  Description
    if (subCommand.description != none && !subCommand.description.IsEmpty()) {
        callerConsole.WriteBlock(subCommand.description);
    }
}

private final function PrintOptions(Command.Data data)
{
    local int           i;
    local array<Option> options;
    options = data.options;
    if (options.length <= 0) {
        return;
    }
    callerConsole
        .UseColor(_.color.textSubHeader)
        .WriteLine(T(TOPTIONS))
        .UseColor(_.color.textDefault);
    for (i = 0; i < options.length; i += 1) {
        PrintOption(options[i]);
    }
}

private final function PrintOption(Option option)
{
    local Text shortNameAsText;
    //  Option short and long names with added key characters
    shortNameAsText = _.text.FromCharacter(option.shortName);
    callerConsole
        .UseColor(_.color.textEmphasis)
        .Write(T(TKEY)).Write(shortNameAsText)          //  "-"
        .UseColor(_.color.textDefault)
        .Write(T(TCOMMA_SPACE))                         //  ", "
        .UseColor(_.color.textEmphasis)
        .Write(T(TDOUBLE_KEY)).Write(option.longName)   //  "--"
        .UseColor(_.color.textDefault);
    shortNameAsText.FreeSelf();
    //  Parameters
    if (option.required.length != 0 || option.optional.length != 0)
    {
        callerConsole.Write(T(TSPACE));
        PrintParameters(option.required, option.optional);
    }
    callerConsole.Flush();
    //  Description
    if (option.description != none && !option.description.IsEmpty()) {
        callerConsole.WriteBlock(option.description);
    }
}

private final function PrintParameters(
    array<Parameter>    required,
    array<Parameter>    optional)
{
    local int i;
    //  Print required
    for (i = 0; i < required.length; i += 1)
    {
        PrintParameter(required[i]);
        if (i < required.length - 1) {
            callerConsole.Write(T(TSPACE));
        }
    }
    if (optional.length <= 0) {
        return;
    }
    //  Print optional
    callerConsole.Write(T(TSPACE)).Write(T(TOPEN_BRACKET));
    for (i = 0; i < optional.length; i += 1)
    {
        PrintParameter(optional[i]);
        if (i < optional.length - 1) {
            callerConsole.Write(T(TSPACE));
        }
    }
    callerConsole.Write(T(TCLOSE_BRACKET));
}

private final function PrintParameter(Parameter parameter)
{
    switch (parameter.type)
    {
    case CPT_Boolean:
        callerConsole.UseColor(_.color.typeBoolean);
        break;
    case CPT_Integer:
        callerConsole.UseColor(_.color.typeNumber);
        break;
    case CPT_Number:
        callerConsole.UseColor(_.color.typeNumber);
        break;
    case CPT_Text:
    case CPT_Remainder:
        callerConsole.UseColor(_.color.typeString);
        break;
    case CPT_Object:
        callerConsole.UseColor(_.color.typeLiteral);
        break;
    case CPT_Array:
        callerConsole.UseColor(_.color.typeLiteral);
        break;
    default:
        callerConsole.UseColor(_.color.textDefault);
    }
    callerConsole.Write(parameter.displayName);
    if (parameter.allowsList) {
        callerConsole.Write(T(TPLUS));
    }
    callerConsole.UseColor(_.color.textDefault);
}

defaultproperties
{
    TSPACE                  = 0
    stringConstants(0)  = " "
    TPLUS                   = 1
    stringConstants(1)  = "(+)"
    TOPEN_BRACKET           = 2
    stringConstants(2)  = "["
    TCLOSE_BRACKET          = 3
    stringConstants(3)  = "]"
    TKEY                    = 4
    stringConstants(4)  = "-"
    TDOUBLE_KEY             = 5
    stringConstants(5)  = "--"
    TCOMMA_SPACE            = 6
    stringConstants(6)  = ", "
    TCOLUMN_SPACE           = 7
    stringConstants(7)  = ": "
    TINDENT                 = 8
    stringConstants(8)  = "    "
    TBOOLEAN                = 9
    stringConstants(9)  = "boolean"
    TBOOLEAN_TRUE_FALSE     = 10
    stringConstants(10) = "true/false"
    TBOOLEAN_ENABLE_DISABLE = 11
    stringConstants(11) = "enable/disable"
    TBOOLEAN_ON_OFF         = 12
    stringConstants(12) = "on/off"
    TBOOLEAN_YES_NO         = 13
    stringConstants(13) = "yes/no"
    TCMD_WITH_TARGET        = 14
    stringConstants(14) = ": This command requires target to be specified."
    TCMD_WITHOUT_TARGET     = 15
    stringConstants(15) = ": This command does not require target to be specified."
    TOPTIONS                = 16
    stringConstants(16) = "OPTIONS"
    TSEPARATOR              = 17
    stringConstants(17) = "============================="
    TLIST_REGIRESTED_CMDS   = 18
    stringConstants(18) = "{$TextHeader List of registered commands}"
    TEMPTY_GROUP            = 19
    stringConstants(19) = "Empty group"
}