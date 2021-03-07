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
class ACommandHelp extends Command
    dependson(LoggerAPI);

var LoggerAPI.Definition testMsg;

var public const int TSPACE, TCOMMAND_NAME_FALLBACK, TPLUS;
var public const int TOPEN_BRACKET, TCLOSE_BRACKET, TCOLUMN_SPACE;
var public const int TKEY, TDOUBLE_KEY, TCOMMA_SPACE, TBOOLEAN, TINDENT;
var public const int TBOOLEAN_TRUE_FALSE, TBOOLEAN_ENABLE_DISABLE;
var public const int TBOOLEAN_ON_OFF, TBOOLEAN_YES_NO;
var public const int TOPTIONS, TCMD_WITH_TARGET, TCMD_WITHOUT_TARGET;

protected function BuildData(CommandDataBuilder builder)
{
    builder.Name(P("help"))
        .Summary(P("Detailed information about available commands."));
    builder.OptionalParams()
        .ParamTextList(P("commands"))
        .Describe(P("Display information about all specified commands."));
    builder.Option(P("list"))
        .Describe(P("Display list of all available commands."));
}

protected function Executed(CommandCall callInfo)
{
    local AssociativeArray  parameters;
    local DynamicArray      commandsToDisplay;
    local APlayer           callerPlayer;
    callerPlayer = callInfo.GetCallerPlayer();
    if (callerPlayer == none) {
        return;
    }

    //  Print command list if "--list" option was specified
    if (callInfo.GetOptions().HasKey(P("list"))) {
        DisplayCommandList(callerPlayer);
    }
    //  Help pages.
    //  Only need to print them if:
    //      1. Any commands are specified as parameters;
    //      2. No commands or "--list" option was specified, then we want to
    //          print a help page for this command.
    if (    !callInfo.GetOptions().HasKey(P("list"))
        ||  callInfo.GetParameters().HasKey(P("commands")))
    {
        parameters = callInfo.GetParameters();
        commandsToDisplay = DynamicArray(parameters.GetItem(P("commands")));
        DisplayCommandHelpPages(callerPlayer, commandsToDisplay);
    }
}

private final function DisplayCommandList(APlayer player)
{
    local int           i;
    local ConsoleWriter console;
    local Command       nextCommand;
    local Command.Data  nextData;
    local array<Text>   commandNames;
    local Commands      commandsFeature;
    if (player == none)             return;
    commandsFeature = Commands(class'Commands'.static.GetInstance());
    if (commandsFeature == none)    return;

    console = player.Console();
    commandNames = commandsFeature.GetCommandNames();
    for (i = 0; i < commandNames.length; i += 1)
    {
        nextCommand = commandsFeature.GetCommand(commandNames[i]);
        if (nextCommand == none) continue;

        nextData = nextCommand.GetData();
        console.UseColor(_.color.textEmphasis)
            .Write(nextData.name)
            .ResetColor()
            .Write(T(TCOLUMN_SPACE))
            .WriteLine(nextData.summary);
    }
    _.memory.FreeMany(commandNames);
}

private final function DisplayCommandHelpPages(
    APlayer         player,
    DynamicArray    commandList)
{
    local int       i;
    local Command   nextCommand;
    local Commands  commandsFeature;
    if (player == none)             return;
    commandsFeature = Commands(class'Commands'.static.GetInstance());
    if (commandsFeature == none)    return;

    //  If arguments were empty - at least display our own help page
    if (commandList == none)
    {
        PrintHelpPage(player.Console(), GetData());
        return;
    }
    //  Otherwise - print help for specified commands
    for (i = 0; i < commandList.GetLength(); i += 1)
    {
        nextCommand = commandsFeature.GetCommand(Text(commandList.GetItem(i)));
        if (nextCommand == none) continue;
        PrintHelpPage(player.Console(), nextCommand.GetData());
    }
}

//  Following methods are mostly self-explanatory,
//  all assume that passed `cout != none` 
private final function PrintHelpPage(ConsoleWriter cout, Command.Data data)
{
    local Text commandNameUpperCase;
    //  Get capitalized command name
    commandNameUpperCase = data.name.UpperCopy();
    //  Print header: name + basic info
    cout.UseColor(_.color.textHeader)
        .Write(commandNameUpperCase)
        .UseColor(_.color.textDefault);
    commandNameUpperCase.FreeSelf();
    if (data.requiresTarget) {
        cout.WriteLine(T(TCMD_WITH_TARGET));
    }
    else {
        cout.WriteLine(T(TCMD_WITHOUT_TARGET));
    }
    //  Print commands and options
    PrintCommands(cout, data);
    PrintOptions(cout, data);
    //  Clean up
    cout.ResetColor().Flush();
}

private final function PrintCommands(ConsoleWriter cout, Command.Data data)
{
    local int               i;
    local array<SubCommand> subCommands;
    subCommands = data.subCommands;
    for (i = 0; i < subCommands.length; i += 1) {
        PrintSubCommand(cout, subCommands[i], data.name);
    }
}

private final function PrintSubCommand(
    ConsoleWriter   cout,
    SubCommand      subCommand,
    Text            commandName)
{
    //  Command + parameters
    //  Command name + sub command name
    cout.UseColor(_.color.textEmphasis)
        .Write(commandName)
        .Write(T(TSPACE));
    if (subCommand.name != none && !subCommand.name.IsEmpty()) {
        cout.Write(subCommand.name).Write(T(TSPACE));
    }
    cout.UseColor(_.color.textDefault);
    //  Parameters
    PrintParameters(cout, subCommand.required, subCommand.optional);
    cout.Flush();
    //  Description
    if (subCommand.description != none && !subCommand.description.IsEmpty()) {
        cout.WriteBlock(subCommand.description);
    }
}

private final function PrintOptions(ConsoleWriter cout, Command.Data data)
{
    local int           i;
    local array<Option> options;
    options = data.options;
    if (options.length <= 0) {
        return;
    }
    cout.UseColor(_.color.textSubHeader)
        .WriteLine(T(TOPTIONS))
        .UseColor(_.color.textDefault);
    for (i = 0; i < options.length; i += 1) {
        PrintOption(cout, options[i]);
    }
}

private final function PrintOption(
    ConsoleWriter   cout,
    Option          option)
{
    local Text shortNameAsText;
    //  Option short and long names with added key characters
    shortNameAsText = _.text.FromCharacter(option.shortName);
    cout.UseColor(_.color.textEmphasis)
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
        cout.Write(T(TSPACE));
        PrintParameters(cout, option.required, option.optional);
        cout.Flush();
    }
    //  Description
    if (option.description != none && !option.description.IsEmpty()) {
        cout.WriteBlock(option.description);
    }
}

private final function PrintParameters(
    ConsoleWriter       cout,
    array<Parameter>    required,
    array<Parameter>    optional)
{
    local int i;
    //  Print required
    for (i = 0; i < required.length; i += 1)
    {
        PrintParameter(cout, required[i]);
        if (i < required.length - 1) {
            cout.Write(T(TSPACE));
        }
    }
    if (optional.length <= 0) {
        return;
    }
    //  Print optional
    cout.Write(T(TSPACE)).Write(T(TOPEN_BRACKET));
    for (i = 0; i < optional.length; i += 1)
    {
        PrintParameter(cout, optional[i]);
        if (i < optional.length - 1) {
            cout.Write(T(TSPACE));
        }
    }
    cout.Write(T(TCLOSE_BRACKET));
}

private final function PrintParameter(ConsoleWriter cout, Parameter parameter)
{
    switch (parameter.type)
    {
    case CPT_Boolean:
        cout.UseColor(_.color.typeBoolean);
        break;
    case CPT_Integer:
        cout.UseColor(_.color.typeNumber);
        break;
    case CPT_Number:
        cout.UseColor(_.color.typeNumber);
        break;
    case CPT_Text:
        cout.UseColor(_.color.typeString);
        break;
    case CPT_Object:
        cout.UseColor(_.color.typeLiteral);
        break;
    case CPT_Array:
        cout.UseColor(_.color.typeLiteral);
        break;
    default:
        cout.UseColor(_.color.textDefault);
    }
    cout.Write(parameter.displayName);
    if (parameter.allowsList) {
        cout.Write(T(TPLUS));
    }
    cout.UseColor(_.color.textDefault);
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
}