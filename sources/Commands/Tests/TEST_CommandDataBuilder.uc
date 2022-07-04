/**
 *  Set of tests for `CommandDataBuilder` class.
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
class TEST_CommandDataBuilder extends TestCase
    dependson(CommandDataBuilder)
    abstract;

protected static function CommandDataBuilder PrepareBuilder()
{
    local CommandDataBuilder builder;
    builder =
        CommandDataBuilder(__().memory.Allocate(class'CommandDataBuilder'));
    builder.ParamNumber(P("var")).ParamText(P("str_var"), P("otherName"));
    builder.OptionalParams();
    builder.Describe(P("Simple command"));
    builder.ParamBooleanList(P("list"), PBF_OnOff);
    //  Subcommands
    builder.SubCommand(P("sub")).ParamArray(P("array_var"));
    builder.Describe(P("Alternative command!"));
    builder.ParamIntegerList(P("int"));
    builder.SubCommand(P("empty"));
    builder.Describe(P("Empty one!"));
    builder.SubCommand(P("huh")).ParamNumber(P("list"));
    builder.SubCommand(P("sub")).ParamObjectList(P("one_more"), P("but"));
    builder.Describe(P("Alternative command! Updated!"));
    //  Options
    builder.Option(P("silent")).Describe(P("Just an option, I dunno."));
    builder.Option(P("Params"), P("d"));
    builder.ParamBoolean(P("www"), PBF_YesNo, P("random"));
    builder.OptionalParams().ParamIntegerList(P("www2"));
    return builder.RequireTarget();
}

protected static function Command.SubCommand GetSubCommand(
    Command.Data    data,
    string          subCommandName)
{
    local int                   i;
    local Command.SubCommand    emptySubCommand;
    for (i = 0; i < data.subcommands.length; i += 1)
    {
        if (data.subcommands[i].name.CompareToString(subCommandName)) {
            return data.subcommands[i];
        }
    }
    return emptySubCommand;
}

protected static function Command.Option GetOption(
    Command.Data    data,
    string          subCommandName)
{
    local int               i;
    local Command.Option    emptyOption;
    for (i = 0; i < data.options.length; i += 1)
    {
        if (data.options[i].longName.CompareToString(subCommandName)) {
            return data.options[i];
        }
    }
    return emptyOption;
}

protected static function TESTS()
{
    Test_Empty();
    Test_Full();
}

protected static function Test_Empty()
{
    local Command.Data          data;
    local CommandDataBuilder    builder;
    Context("Testing that new `CommandDataBuilder` returns"
        @ "blank command data.");
    builder =
        CommandDataBuilder(__().memory.Allocate(class'CommandDataBuilder'));
    data = builder.BorrowData();
    TEST_ExpectTrue(data.subcommands.length == 1);
    TEST_ExpectTrue(data.subcommands[0].name.IsEmpty());
    TEST_ExpectNone(data.subcommands[0].description);
    TEST_ExpectTrue(data.subcommands[0].required.length == 0);
    TEST_ExpectTrue(data.subcommands[0].optional.length == 0);
    TEST_ExpectTrue(data.options.length == 0);
    TEST_ExpectFalse(data.requiresTarget);
}

protected static function Test_Full()
{
    local Command.Data data;
    data = PrepareBuilder().BorrowData();
    Context("Testing that `CommandDataBuilder` properly builds command data for"
        @ "complex commands.");
    Issue("Incorrect amount of sub-commands and/or option.");
    TEST_ExpectTrue(data.subcommands.length == 4);
    TEST_ExpectTrue(data.options.length == 2);
    TEST_ExpectTrue(data.requiresTarget);
    //  Test empty sub command.
    Issue("\"empty\" command was filled incorrectly.");
    TEST_ExpectTrue(    GetSubCommand(data, "empty").name.ToString()
                    ==  "empty");
    TEST_ExpectTrue(    GetSubCommand(data, "empty").description.ToString()
                    ==  "Empty one!");
    TEST_ExpectTrue(GetSubCommand(data, "empty").required.length == 0);
    TEST_ExpectTrue(GetSubCommand(data, "empty").optional.length == 0);
    //  Sub other commands / options
    SubTest_DefaultSubCommand(data);
    SubTest_subSubCommand(data);
    SubTest_huhSubCommand(data);
    SubTest_silentOption(data);
    SubTest_ParamsOption(data);
}

protected static function SubTest_DefaultSubCommand(Command.Data data)
{
    local Command.SubCommand subCommand;
    Issue("Default sub-command was filled incorrectly.");
    subCommand = GetSubCommand(data, "");
    TEST_ExpectTrue(subCommand.name.IsEmpty());
    TEST_ExpectTrue(subCommand.description.ToString() == "Simple command");
    TEST_ExpectTrue(subCommand.required.length == 2);
    TEST_ExpectTrue(subCommand.optional.length == 1);
    //  Required
    TEST_ExpectTrue(    subCommand.required[0].displayName.ToString()
                    ==  "var");
    TEST_ExpectTrue(    subCommand.required[0].variableName.ToString()
                    ==  "var");
    TEST_ExpectTrue(subCommand.required[0].type == CPT_Number);
    TEST_ExpectFalse(subCommand.required[0].allowsList);
    TEST_ExpectTrue(    subCommand.required[1].displayName.ToString()
                    ==   "str_var");
    TEST_ExpectTrue(    subCommand.required[1].variableName.ToString()
                    ==  "otherName");
    TEST_ExpectTrue(subCommand.required[1].type == CPT_Text);
    TEST_ExpectFalse(subCommand.required[1].allowsList);
    //  Optional
    TEST_ExpectTrue(    subCommand.optional[0].displayName.ToString()
                    ==  "list");
    TEST_ExpectTrue(    subCommand.optional[0].variableName.ToString()
                    ==  "list");
    TEST_ExpectTrue(subCommand.optional[0].type == CPT_Boolean);
    TEST_ExpectTrue(subCommand.optional[0].booleanFormat == PBF_OnOff);
    TEST_ExpectTrue(subCommand.optional[0].allowsList);
}

protected static function SubTest_subSubCommand(Command.Data data)
{
    local Command.SubCommand subCommand;
    Issue("\"sub\" sub-command was filled incorrectly.");
    subCommand = GetSubCommand(data, "sub");
    TEST_ExpectTrue(subCommand.name.ToString() == "sub");
    TEST_ExpectTrue(    subCommand.description.ToString()
                    ==  "Alternative command! Updated!");
    TEST_ExpectTrue(subCommand.required.length == 3);
    TEST_ExpectTrue(subCommand.optional.length == 0);
    //  Required
    TEST_ExpectTrue(    subCommand.required[0].displayName.ToString()
                    ==  "array_var");
    TEST_ExpectTrue(    subCommand.required[0].variableName.ToString()
                    ==  "array_var");
    TEST_ExpectTrue(subCommand.required[0].type == CPT_Array);
    TEST_ExpectFalse(subCommand.required[0].allowsList);
    TEST_ExpectTrue(    subCommand.required[1].displayName.ToString()
                    ==  "int");
    TEST_ExpectTrue(    subCommand.required[1].variableName.ToString()
                    ==  "int");
    TEST_ExpectTrue(subCommand.required[1].type == CPT_Integer);
    TEST_ExpectTrue(subCommand.required[1].allowsList);
    TEST_ExpectTrue(    subCommand.required[2].displayName.ToString()
                    ==  "one_more");
    TEST_ExpectTrue(    subCommand.required[2].variableName.ToString()
                    ==  "but");
    TEST_ExpectTrue(subCommand.required[2].type == CPT_Object);
    TEST_ExpectTrue(subCommand.required[2].allowsList);
}

protected static function SubTest_huhSubCommand(Command.Data data)
{
    local Command.SubCommand subCommand;
    Issue("\"huh\" sub-command was filled incorrectly.");
    subCommand = GetSubCommand(data, "huh");
    TEST_ExpectTrue(subCommand.name.ToString() == "huh");
    TEST_ExpectNone(subCommand.description);
    TEST_ExpectTrue(subCommand.required.length == 1);
    TEST_ExpectTrue(subCommand.optional.length == 0);
    //  Required
    TEST_ExpectTrue(    subCommand.required[0].displayName.ToString()
                    ==  "list");
    TEST_ExpectTrue(    subCommand.required[0].variableName.ToString()
                    ==  "list");
    TEST_ExpectTrue(subCommand.required[0].type == CPT_Number);
    TEST_ExpectFalse(subCommand.required[0].allowsList);
}

protected static function SubTest_silentOption(Command.Data data)
{
    local Command.Option option;
    Issue("\"silent\" option was filled incorrectly.");
    option = GetOption(data, "silent");
    TEST_ExpectTrue(option.longName.ToString() == "silent");
    TEST_ExpectTrue(option.shortName.codePoint == 0x73);   // s
    TEST_ExpectTrue(    option.description.ToString()
                    ==  "Just an option, I dunno.");
    TEST_ExpectTrue(option.required.length == 0);
    TEST_ExpectTrue(option.optional.length == 0);
}

protected static function SubTest_ParamsOption(Command.Data data)
{
    local Command.Option option;
    Issue("\"Params\" option was filled incorrectly.");
    option = GetOption(data, "Params");
    TEST_ExpectTrue(option.longName.ToString() == "Params");
    TEST_ExpectTrue(option.shortName.codePoint == 0x64);
    TEST_ExpectNone(option.description);
    TEST_ExpectTrue(option.required.length == 1);
    TEST_ExpectTrue(option.optional.length == 1);
    //  Required
    TEST_ExpectTrue(option.required[0].displayName.ToString() == "www");
    TEST_ExpectTrue(    option.required[0].variableName.ToString()
                    ==  "random");
    TEST_ExpectTrue(option.required[0].type == CPT_Boolean);
    TEST_ExpectTrue(option.required[0].booleanFormat == PBF_YesNo);
    TEST_ExpectFalse(option.required[0].allowsList);
    //  Optional
    TEST_ExpectTrue(option.optional[0].displayName.ToString() == "www2");
    TEST_ExpectTrue(option.optional[0].variableName.ToString() == "www2");
    TEST_ExpectTrue(option.optional[0].type == CPT_Integer);
    TEST_ExpectTrue(option.optional[0].allowsList);
}

defaultproperties
{
    caseName = "Command data builder"
    caseGroup = "Commands"
}