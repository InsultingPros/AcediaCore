/**
 *      Utility class that provides developers with a simple interface to
 *  prepare data that describes command's parameters and options.
 *      Copyright 2021-2022 Anton Tarasenko
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
class CommandDataBuilder extends AcediaObject
    dependson(Command);

/**
 *  `CommandDataBuilder` should be able to fill information about:
 *      1. subcommands and their parameters;
 *      2. options and their parameters.
 *  As far as user is concerned, the process of filling both should be
 *  identical. Therefore we will store all defined data in two ways:
 *      1. Selected data: data about parameters for subcommand/option that is
 *          currently being filled;
 *      2. Prepared data: data that was already filled as "selected data" then
 *          stored in these records. Whenever we want to switch to filling
 *          another subcommand/option or return already prepared data we must
 *          dump "selected data" into "prepared data" first and then return
 *          the latter.
 *
 *      Overall, intended flow for creating a new sub-command or option is to
 *  select either, fill it with data with public methods `Param...()` into
 *  "selected data" and then copy it into "prepared data"
 *  (through a `RecordSelection()` method below).
 */

//  "Prepared data"
var private Text                        commandName, commandGroup;
var private Text                        commandSummary;
var private array<Command.SubCommand>   subcommands;
var private array<Command.Option>       options;
var private bool                        requiresTarget;
//      Auxiliary arrays signifying that we've started adding optional
//  parameters into appropriate `subcommands` and `options`.
//      All optional parameters must follow strictly after required parameters
//  and so, after user have started adding optional parameters to
//  subcommand/option, we prevent them from adding required ones
//  (to that particular command/option).
var private array<byte> subcommandsIsOptional;
var private array<byte> optionsIsOptional;

//  "Selected data"
//  `false` means we have selected sub-command, `true` - option
var private bool                        selectedItemIsOption;
//  `name` for sub-commands, `longName` for options
var private Text                        selectedItemName;
//  Description of selected sub-command/option
var private Text                        selectedDescription;
//  Are we filling optional parameters (`true`)? Or required ones (`false`)?
var private bool                        selectionIsOptional;
//  Array of parameters we are currently filling (either required or optional)
var private array<Command.Parameter>    selectedParameterArray;

var LoggerAPI.Definition errLongNameTooShort, errShortNameTooLong;
var LoggerAPI.Definition warnSameLongName, warnSameShortName;

protected function Constructor()
{
    //  Fill empty subcommand (no special key word) by default
    SelectSubCommand(P(""));
}

protected function Finalizer()
{
    subcommands.length              = 0;
    subcommandsIsOptional.length    = 0;
    options.length                  = 0;
    optionsIsOptional.length        = 0;
    selectedParameterArray.length   = 0;
    commandName                     = none;
    commandGroup                    = none;
    commandSummary                  = none;
    selectedItemName                = none;
    selectedDescription             = none;
    requiresTarget                  = false;
    selectedItemIsOption            = false;
    selectionIsOptional             = false;
}

//  Find index of sub-command with a given name `name` in `subcommands`.
//  `-1` if there's not sub-command with such name.
//  Case-sensitive.
private final function int FindSubCommandIndex(BaseText name)
{
    local int i;
    if (name == none) {
        return -1;
    }
    for (i = 0; i < subcommands.length; i += 1)
    {
        if (name.Compare(subcommands[i].name)) {
            return i;
        }
    }
    return -1;
}

//  Find index of option with a given name `name` in `options`.
//  `-1` if there's not sub-command with such name.
//  Case-sensitive.
private final function int FindOptionIndex(BaseText longName)
{
    local int i;
    if (longName == none) {
        return -1;
    }
    for (i = 0; i < options.length; i += 1)
    {
        if (longName.Compare(options[i].longName)) {
            return i;
        }
    }
    return -1;
}

//      Creates an empty selection record for subcommand or option with
//  name (long name) `name`.
//      Doe not check whether subcommand/option with that name already exists.
//      Copies passed `name`, assumes that it is not `none`.
private final function MakeEmptySelection(BaseText name, bool selectedOption)
{
    selectedItemIsOption            = selectedOption;
    selectedItemName                = name.Copy();
    selectedDescription             = none;
    selectedParameterArray.length   = 0;
    selectionIsOptional             = false;
}

//      Select sub-command with a given name `name` from `subcommands`.
//      If there is no command with specified name `name` in prepared data -
//  creates new record in selection, otherwise copies previously saved data.
//      Automatically saves previously selected data into prepared data.
//      Copies `name` if it has to create new record.
private final function SelectSubCommand(BaseText name)
{
    local int subcommandIndex;
    if (name == none)                                               return;
    if (    !selectedItemIsOption && selectedItemName != none
        &&  selectedItemName.Compare(name))
    {
        return;
    }
    RecordSelection();
    subcommandIndex = FindSubCommandIndex(name);
    if (subcommandIndex < 0)
    {
        MakeEmptySelection(name, false);
        return;
    }
    //  Load appropriate prepared data, if it exists for
    //  sub-command with name `name`
    selectedItemIsOption    = false;
    selectedItemName        = subcommands[subcommandIndex].name;
    selectedDescription     = subcommands[subcommandIndex].description;
    selectionIsOptional      = subcommandsIsOptional[subcommandIndex] > 0;
    if (selectionIsOptional) {
        selectedParameterArray = subcommands[subcommandIndex].optional;
    }
    else {
        selectedParameterArray = subcommands[subcommandIndex].required;
    }
}

//      Select option with a given long name `longName` from `options`.
//      If there is no option with specified `longName` in prepared data -
//  creates new record in selection, otherwise copies previously saved data.
//      Automatically saves previously selected data into prepared data.
//      Copies `name` if it has to create new record.
private final function SelectOption(BaseText longName)
{
    local int optionIndex;
    if (longName == none) return;
    if (    selectedItemIsOption && selectedItemName != none
        &&  selectedItemName.Compare(longName))
    {
        return;
    }
    RecordSelection();
    optionIndex = FindOptionIndex(longName);
    if (optionIndex < 0)
    {
        MakeEmptySelection(longName, true);
        return;
    }
    //  Load appropriate prepared data, if it exists for
    //  option with long name `longName`
    selectedItemIsOption    = true;
    selectedItemName        = options[optionIndex].longName;
    selectedDescription     = options[optionIndex].description;
    selectionIsOptional      = optionsIsOptional[optionIndex] > 0;
    if (selectionIsOptional) {
        selectedParameterArray = options[optionIndex].optional;
    }
    else {
        selectedParameterArray = options[optionIndex].required;
    }
}

//  Saves currently selected data into prepared data.
private final function RecordSelection()
{
    if (selectedItemName == none) {
        return;
    }
    if (selectedItemIsOption) {
        RecordSelectedOption();
    }
    else {
        RecordSelectedSubCommand();
    }
}

//  Saves selected sub-command into prepared records.
//  Assumes that command and not an option is selected.
private final function RecordSelectedSubCommand()
{
    local int                   selectedSubCommandIndex;
    local Command.SubCommand    newSubcommand;
    if (selectedItemName == none) return;

    selectedSubCommandIndex = FindSubCommandIndex(selectedItemName);
    if (selectedSubCommandIndex < 0)
    {
        selectedSubCommandIndex = subcommands.length;
        subcommands[selectedSubCommandIndex] = newSubcommand;
    }
    subcommands[selectedSubCommandIndex].name           = selectedItemName;
    subcommands[selectedSubCommandIndex].description    = selectedDescription;
    if (selectionIsOptional)
    {
        subcommands[selectedSubCommandIndex].optional = selectedParameterArray;
        subcommandsIsOptional[selectedSubCommandIndex] = 1;
    }
    else
    {
        subcommands[selectedSubCommandIndex].required = selectedParameterArray;
        subcommandsIsOptional[selectedSubCommandIndex] = 0;
    }
}

//  Saves currently selected option into prepared records.
//  Assumes that option and not an command is selected.
private final function RecordSelectedOption()
{
    local int               selectedOptionIndex;
    local Command.Option    newOption;
    if (selectedItemName == none) return;

    selectedOptionIndex = FindOptionIndex(selectedItemName);
    if (selectedOptionIndex < 0)
    {
        selectedOptionIndex = options.length;
        options[selectedOptionIndex] = newOption;
    }
    options[selectedOptionIndex].longName       = selectedItemName;
    options[selectedOptionIndex].description    = selectedDescription;
    if (selectionIsOptional)
    {
        options[selectedOptionIndex].optional = selectedParameterArray;
        optionsIsOptional[selectedOptionIndex] = 1;
    }
    else
    {
        options[selectedOptionIndex].required = selectedParameterArray;
        optionsIsOptional[selectedOptionIndex] = 0;
    }
}
/**
 *  Method to use to start defining a new sub-command.
 *
 *  Does two things:
 *      1. Creates new sub-command with a given name (if it's missing);
 *      2. Selects sub-command with name `name` to add parameters to.
 *
 *  @param  name    Name of the sub-command user wants to define,
 *      case-sensitive. Variable will be copied.
 *      If `none` is passed, this method will do nothing.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder SubCommand(BaseText name)
{
    SelectSubCommand(name);
    return self;
}

//  Validates names (printing errors in case of failure) for the option.
//  Long name must be at least 2 characters long.
//  Short name must be either:
//      1. exactly one character long;
//      2. `none`, which leads to deriving `shortName` from `longName`
//          as a first character.
//  Anything else will result in logging a failure and rejection of
//  the option altogether.
//  Returns `none` if validation failed and chosen short name otherwise
//  (if `shortName` was used for it - it's value will be copied).
private final function BaseText.Character GetValidShortName(
    BaseText longName,
    BaseText shortName)
{
    //  Validate `longName`
    if (longName == none) {
        return _.text.GetInvalidCharacter();
    }
    if (longName.GetLength() < 2)
    {
        _.logger.Auto(errLongNameTooShort).ArgClass(class).Arg(longName.Copy());
        return _.text.GetInvalidCharacter();
    }
    //  Validate `shortName`,
    //  deriving if from `longName` if necessary & possible
    if (shortName == none) {
        return longName.GetCharacter(0);
    }
    if (shortName.IsEmpty() || shortName.GetLength() > 1)
    {
        _.logger.Auto(errShortNameTooLong).ArgClass(class).Arg(longName.Copy());
        return _.text.GetInvalidCharacter();
    }
    return shortName.GetCharacter(0);
}

//  Checks that if any option record has a long/short name from a given pair of
//  names (`longName`, `shortName`), then it also has another one.
//
//  i.e. we cannot have several options with identical names:
//  (--silent, -s) and (--sick, -s).
private final function bool VerifyNoOptionNamingConflict(
    BaseText            longName,
    BaseText.Character  shortName)
{
    local int i;
    //  To make sure we will search through the up-to-date `options`,
    //  record selection into prepared records.
    RecordSelection();
    for (i = 0; i < options.length; i += 1)
    {
        //  Is same long name, but different long names?
        if (    !_.text.AreEqual(shortName, options[i].shortName)
            &&  longName.Compare(options[i].longName))
        {
            _.logger.Auto(warnSameLongName)
                .ArgClass(class)
                .Arg(longName.Copy());
            return true;
        }
        //  Is same short name, but different short ones?
        if (    _.text.AreEqual(shortName, options[i].shortName)
            &&  !longName.Compare(options[i].longName))
        {
            _.logger.Auto(warnSameLongName)
                .ArgClass(class)
                .Arg(_.text.FromCharacter(shortName));
            return true;
        }
    }
    return false;
}

/**
 *  Method to use to start defining a new option.
 *
 *  Does three things:
 *      1.  Checks if some of the recorded options are in conflict with given
 *          `longName` and `shortName` (already using one and only one of them).
 *      2.  Creates new option with a long and short names
 *          (if such option is missing);
 *      3.  Selects option with a long name `longName` to add parameters to.
 *
 *  @param  longName    Long name of the option, case-sensitive
 *      (for using an option in form "--...").
 *      Must be at least two characters long. If passed value is either `none`
 *      or too short, method will log an error and omits this option.
 *  @param  shortName   Short name of the option, case-sensitive
 *      (for using an option in form "-...").
 *      Must be exactly one character. If `none` value is passed
 *      (or the argument altogether omitted) - uses first character of
 *      the `longName`.
 *      If `shortName` is not `none` and is not exactly 1 character long -
 *      logs an error and omits this option.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder Option(
    BaseText            longName,
    optional BaseText   shortName)
{
    local int                   optionIndex;
    local BaseText.Character    shortNameAsCharacter;
    //  Unlike for `SubCommand()`, we need to ensure that option naming is
    //  correct and does not conflict with existing options
    //  (user might attempt to add two options with same long names and
    //  different short ones).
    shortNameAsCharacter = GetValidShortName(longName, shortName);
    if (    !_.text.IsValidCharacter(shortNameAsCharacter)
        ||  VerifyNoOptionNamingConflict(longName, shortNameAsCharacter))
    {
        //  ^ `GetValidShortName()` and `VerifyNoOptionNamingConflict()`
        //  are responsible for logging warnings/errors
        return self;
    }
    SelectOption(longName);
    //  Set short name for new options
    optionIndex = FindOptionIndex(longName);
    if (optionIndex < 0)
    {
        //  We can only be here if option was created for the first time
        RecordSelection();
        //  So now it cannot fail
        optionIndex = FindOptionIndex(longName);
        options[optionIndex].shortName = shortNameAsCharacter;
    }
    return self;    
}

/**
 *  Adds description to the selected sub-command / option.
 *
 *  Previous description is discarded (default description is empty).
 *
 *  Does nothing if nothing is selected.
 *
 *  @param  description New description of selected sub-command / option.
 *      Variable will be copied.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder Describe(BaseText description)
{
    if (selectedDescription == description) {
        return self;
    }
    _.memory.Free(selectedDescription);
    if (description != none) {
        selectedDescription = description.Copy();
    }
    return self;
}

/**
 *  Sets new name of `Command.Data` under construction. This is a name that will
 *  be used unless Acedia is configured to do otherwise.
 *
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder Name(BaseText newName)
{
    if (newName != none && newName == commandName) {
        return self;
    }
    _.memory.Free(commandName);
    if (newName != none) {
        commandName = newName.Copy();
    }
    else {
        commandName = none;
    }
    return self;
}

/**
 *  Sets new group of `Command.Data` under construction. Group name is meant to
 *  be shared among several commands, allowing user to filter or fetch commands
 *  of a certain group.
 *
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder Group(BaseText newName)
{
    if (newName != none && newName == commandGroup) {
        return self;
    }
    _.memory.Free(commandGroup);
    if (newName != none) {
        commandGroup = newName.Copy();
    }
    else {
        commandGroup = none;
    }
    return self;
}

/**
 *  Sets new summary of `Command.Data` under construction. Summary gives a short
 *  description of the command on the whole, to be displayed in a command list.
 *
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder Summary(BaseText newSummary)
{
    if (newSummary != none && newSummary == commandSummary) {
        return self;
    }
    _.memory.Free(commandSummary);
    if (newSummary != none) {
        commandSummary = newSummary.Copy();
    }
    else {
        commandSummary = none;
    }
    return self;
}

/**
 *  Makes caller builder to mark `Command.Data` under construction to require
 *  a player target.
 *
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder RequireTarget()
{
    requiresTarget = true;
    return self;
}

/**
 *  Any parameters added to currently selected sub-command / option after
 *  calling this method will be marked as optional.
 *
 *  Further calls when the same sub-command / option is selected do nothing.
 *
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder OptionalParams()
{
    if (selectionIsOptional) {
        return self;
    }
    //  Record all required parameters first, otherwise there would be no way
    //  to distinguish between them and optional parameters
    RecordSelection();
    selectionIsOptional = true;
    selectedParameterArray.length = 0;
    return self;
}

/**
 *  Returns data that has been constructed so far by
 *  the caller `CommandDataBuilder`.
 *
 *  Does not reset progress.
 *
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function Command.Data BorrowData()
{
    local Command.Data newData;
    RecordSelection();
    newData.name            = commandName;
    newData.group           = commandGroup;
    newData.summary         = commandSummary;
    newData.subcommands     = subcommands;
    newData.options         = options;
    newData.requiresTarget  = requiresTarget;
    return newData;
}

//  Adds new parameter to selected sub-command / option
private final function PushParameter(Command.Parameter newParameter)
{
    selectedParameterArray[selectedParameterArray.length] = newParameter;
}

//  Fills `Command.ParameterType` struct with given values
//  (except boolean format). Assumes `displayName != none`.
private final function Command.Parameter NewParameter(
    BaseText                displayName,
    Command.ParameterType   parameterType,
    bool                    isListParameter,
    optional BaseText       variableName)
{
    local Command.Parameter newParameter;
    newParameter.displayName    = displayName.Copy();
    newParameter.type           = parameterType;
    newParameter.allowsList     = isListParameter;
    if (variableName != none) {
        newParameter.variableName = variableName.Copy();
    }
    else {
        newParameter.variableName = displayName.Copy();
    }
    return newParameter;
}

/**
 *  Adds new boolean parameter (required or optional depends on whether
 *  `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *      
 *  @param format           Preferred format of boolean values.
 *      Command parser will still accept boolean values in any form,
 *      this setting only affects how parameter will be displayed in
 *      generated help.
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamBoolean(
    BaseText                                name,
    optional Command.PreferredBooleanFormat format,
    optional BaseText                       variableName)
{
    local Command.Parameter newParam;
    if (name == none) {
        return self;
    }
    newParam = NewParameter(name, CPT_Boolean, false, variableName);
    newParam.booleanFormat = format;
    PushParameter(newParam);
    return self;
}

/**
 *  Adds new boolean list parameter (required or optional depends on whether
 *  `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *  @param format           Preferred format of boolean values.
 *      Command parser will still accept boolean values in any form,
 *      this setting only affects how parameter will be displayed in
 *      generated help.
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamBooleanList(
    BaseText                                name,
    optional Command.PreferredBooleanFormat format,
    optional BaseText                       variableName)
{
    local Command.Parameter newParam;
    if (name == none) {
        return self;
    }
    newParam = NewParameter(name, CPT_Boolean, true, variableName);
    newParam.booleanFormat = format;
    PushParameter(newParam);
    return self;
}

/**
 *  Adds new integer parameter (required or optional depends on whether
 *  `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamInteger(
    BaseText            name,
    optional BaseText   variableName)
{
    if (name == none) {
        return self;
    }
    PushParameter(NewParameter(name, CPT_Integer, false, variableName));
    return self;
}

/**
 *  Adds new integer list parameter (required or optional depends on whether
 *  `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamIntegerList(
    BaseText            name,
    optional BaseText   variableName)
{
    if (name == none) {
        return self;
    }
    PushParameter(NewParameter(name, CPT_Integer, true, variableName));
    return self;
}

/**
 *  Adds new numeric parameter (required or optional depends on whether
 *  `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamNumber(
    BaseText            name,
    optional BaseText   variableName)
{
    if (name == none) {
        return self;
    }
    PushParameter(NewParameter(name, CPT_Number, false, variableName));
    return self;
}

/**
 *  Adds new numeric list parameter (required or optional depends on whether
 *  `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamNumberList(
    BaseText            name,
    optional BaseText   variableName)
{
    if (name == none) {
        return self;
    }
    PushParameter(NewParameter(name, CPT_Number, true, variableName));
    return self;
}

/**
 *  Adds new text parameter (required or optional depends on whether
 *  `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamText(
    BaseText            name,
    optional BaseText   variableName)
{
    if (name == none) {
        return self;
    }
    PushParameter(NewParameter(name, CPT_Text, false, variableName));
    return self;
}

/**
 *  Adds new text list parameter (required or optional depends on whether
 *  `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamTextList(
    BaseText            name,
    optional BaseText   variableName)
{
    if (name == none) {
        return self;
    }
    PushParameter(NewParameter(name, CPT_Text, true, variableName));
    return self;
}

/**
 *  Adds new remainder parameter (required or optional depends on whether
 *  `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamRemainder(
    BaseText            name,
    optional BaseText   variableName)
{
    if (name == none) {
        return self;
    }
    PushParameter(NewParameter(name, CPT_Remainder, false, variableName));
    return self;
}

/**
 *  Adds new object parameter (required or optional depends on whether
 *  `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamObject(
    BaseText            name,
    optional BaseText   variableName)
{
    if (name == none) {
        return self;
    }
    PushParameter(NewParameter(name, CPT_Object, false, variableName));
    return self;
}

/**
 *  Adds new parameter for list of objects (required or optional depends on
 *  whether `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamObjectList(
    BaseText            name,
    optional BaseText   variableName)
{
    if (name == none) {
        return self;
    }
    PushParameter(NewParameter(name, CPT_Object, true, variableName));
    return self;
}

/**
 *  Adds new array parameter (required or optional depends on whether
 *  `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamArray(
    BaseText            name,
    optional BaseText   variableName)
{
    if (name == none) {
        return self;
    }
    PushParameter(NewParameter(name, CPT_Array, false, variableName));
    return self;
}

/**
 *  Adds new parameter for list of arrays (required or optional depends on
 *  whether `RequireTarget()` call happened) to the currently selected
 *  sub-command / option.
 *
 *  Only fails if provided `name` is `none`.
 *
 *  @param  name            Name of the parameter, will be copied
 *      (as it would appear in the generated help info).
 *  @param  variableName    Name of the variable that will store this
 *      parameter's value in `HashTable` after user's command input
 *      is parsed. Provided value will be copied.
 *      If left `none`, - will coincide with `name` parameter.
 *  @return Returns the caller `CommandDataBuilder` to allow for
 *      method chaining.
 */
public final function CommandDataBuilder ParamArrayList(
    BaseText            name,
    optional BaseText   variableName)
{
    if (name == none) {
        return self;
    }
    PushParameter(NewParameter(name, CPT_Array, true, variableName));
    return self;
}

defaultproperties
{
    errLongNameTooShort = (l=LOG_Error,m="Command `%1` is trying to register an option with a name that is way too short (<2 characters). Option will be discarded: %2")
    errShortNameTooLong = (l=LOG_Error,m="Command `%1` is trying to register an option with a short name that doesn't consist of just one character. Option will be discarded: %2")
    warnSameLongName    = (l=LOG_Error,m="Command `%1` is trying to register several options with the same long name \"%2\", but different short names. This should not happen, do not expect correct behavior.")
    warnSameShortName   = (l=LOG_Error,m="Command `%1` is trying to register several options with the same short name \"%2\", but different long names. This should not have happened, do not expect correct behavior.")
}