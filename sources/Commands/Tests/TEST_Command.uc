/**
 *  Set of tests for `Command` class.
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
class TEST_Command extends TestCase
    abstract;

var string queryASuccess1, queryASuccess2, queryASuccess3, queryASuccess4;
var string queryAFailure1, queryAFailure2;

var string queryBSuccess1, queryBSuccess2, queryBSuccess3;
var string queryBFailure1, queryBFailure2, queryBFailure3;
var string queryBFailureUnknownOptionLong, queryBFailureUnknownOptionShort;
var string queryBFailureUnused;
var string queryBFailureNoReqParamOption1, queryBFailureNoReqParamOption2;

protected static function Parser PRS(string source)
{
    return __().text.ParseString(source);
}

protected static function TESTS()
{
    Context("Testing `Command` parsing (parameter chains).");
    Test_MockA();
    Context("Testing `Command` parsing (options).");
    Test_MockB();
    Context("Testing `CommandCall` error messages.");
    Test_CommandCallErrors();
    Context("Testing sub-command determination.");
    Test_SubCommandName();
}

protected static function Test_MockA()
{
    SubTest_MockAQ1AndFailed();
    SubTest_MockAQ2();
    SubTest_MockAQ3();
    SubTest_MockAQ4();
}

protected static function Test_MockB()
{
    SubTest_MockBFailed();
    SubTest_MockBQ1();
    SubTest_MockBQ2();
    SubTest_MockBQ3Remainder();
}

protected static function Test_CommandCallErrors()
{
    SubTest_CommandCallErrorBadParser();
    SubTest_CommandCallErrorNoRequiredParam();
    SubTest_CommandCallErrorUnknownOption();
    SubTest_CommandCallErrorRepeatedOption();
    SubTest_CommandCallErrorMultipleOptionsWithParams();
    SubTest_CommandCallErrorUnusedCommandParameters();
    SubTest_CommandCallErrorNoRequiredParamForOption();
}

protected static function SubTest_CommandCallErrorBadParser()
{
    local CommandCall result;
    Issue("`CET_BadParser` errors are incorrectly reported.");
    result = class'MockCommandA'.static.GetInstance().ProcessInput(none, none);
    TEST_ExpectFalse(result.IsSuccessful());
    TEST_ExpectTrue(result.GetError() == CET_BadParser);//
    TEST_ExpectNone(result.GetErrorCause());
    result = class'MockCommandA'.static.GetInstance()
        .ProcessInput(__().text.ParseString("stuff").Fail(), none);
    TEST_ExpectFalse(result.IsSuccessful());
    TEST_ExpectTrue(result.GetError() == CET_BadParser);//
    TEST_ExpectNone(result.GetErrorCause());
}

protected static function SubTest_CommandCallErrorNoRequiredParam()
{
    local CommandCall result;
    Issue("`CET_NoRequiredParam` errors are incorrectly reported.");
    result = class'MockCommandA'.static.GetInstance()
        .ProcessInput(PRS(default.queryAFailure1), none);
    TEST_ExpectFalse(result.IsSuccessful());
    TEST_ExpectTrue(result.GetError() == CET_NoRequiredParam);
    TEST_ExpectTrue(    result.GetErrorCause().ToString()
                    ==  "integer variable");
    result = class'MockCommandA'.static.GetInstance()
        .ProcessInput(PRS(default.queryAFailure2), none);
    TEST_ExpectFalse(result.IsSuccessful());
    TEST_ExpectTrue(result.GetError() == CET_NoRequiredParam);
    TEST_ExpectTrue(    result.GetErrorCause().ToString()
                    ==  "isItSimple?");
}

protected static function SubTest_CommandCallErrorUnknownOption()
{
    local CommandCall result;
    Issue("`CET_UnknownOption` errors are incorrectly reported.");
    result = class'MockCommandB'.static.GetInstance()
        .ProcessInput(PRS(default.queryBFailureUnknownOptionLong), none);
    TEST_ExpectFalse(result.IsSuccessful());
    TEST_ExpectTrue(result.GetError() == CET_UnknownOption);
    TEST_ExpectTrue(    result.GetErrorCause().ToString()
                    ==  "kest");
    Issue("`CET_UnknownShortOption` errors are incorrectly reported.");
    result = class'MockCommandB'.static.GetInstance()
        .ProcessInput(PRS(default.queryBFailureUnknownOptionShort), none);
    TEST_ExpectFalse(result.IsSuccessful());
    TEST_ExpectTrue(result.GetError() == CET_UnknownShortOption);
    TEST_ExpectNone(result.GetErrorCause());
}

protected static function SubTest_CommandCallErrorRepeatedOption()
{
    local CommandCall result;
    Issue("`CET_RepeatedOption` errors are incorrectly reported.");
    result = class'MockCommandB'.static.GetInstance()
        .ProcessInput(PRS(default.queryBFailure2), none);
    TEST_ExpectFalse(result.IsSuccessful());
    TEST_ExpectTrue(result.GetError() == CET_RepeatedOption);
    TEST_ExpectTrue(    result.GetErrorCause().ToString()
                    ==  "forced");
}

protected static function SubTest_CommandCallErrorUnusedCommandParameters()
{
    local CommandCall result;
    Issue("`CET_UnusedCommandParameters` errors are incorrectly reported.");
    result = class'MockCommandB'.static.GetInstance()
        .ProcessInput(PRS(default.queryBFailureUnused), none);
    TEST_ExpectFalse(result.IsSuccessful());
    TEST_ExpectTrue(result.GetError() == CET_UnusedCommandParameters);
    TEST_ExpectTrue(    result.GetErrorCause().ToString()
                    ==  "text -j");
}

protected static function SubTest_CommandCallErrorMultipleOptionsWithParams()
{
    local CommandCall result;
    Issue("`CET_MultipleOptionsWithParams` errors are incorrectly reported.");
    result = class'MockCommandB'.static.GetInstance()
        .ProcessInput(PRS(default.queryBFailure1), none);
    TEST_ExpectFalse(result.IsSuccessful());
    TEST_ExpectTrue(result.GetError() == CET_MultipleOptionsWithParams);
    TEST_ExpectTrue(result.GetErrorCause().ToString() == "tv");
}

protected static function SubTest_CommandCallErrorNoRequiredParamForOption()
{
    local CommandCall result;
    Issue("`CET_NoRequiredParamForOption` errors are incorrectly reported.");
    result = class'MockCommandB'.static.GetInstance()
        .ProcessInput(PRS(default.queryBFailureNoReqParamOption1), none);
    TEST_ExpectFalse(result.IsSuccessful());
    TEST_ExpectTrue(result.GetError() == CET_NoRequiredParamForOption);
    TEST_ExpectTrue(result.GetErrorCause().ToString() == "long");
    result = class'MockCommandB'.static.GetInstance()
        .ProcessInput(PRS(default.queryBFailureNoReqParamOption2), none);
    TEST_ExpectFalse(result.IsSuccessful());
    TEST_ExpectTrue(result.GetError() == CET_NoRequiredParamForOption);
    TEST_ExpectTrue(result.GetErrorCause().ToString() == "values");
}

protected static function Test_SubCommandName()
{
    local CommandCall result;
    Issue("Cannot determine subcommands.");
    result = class'MockCommandA'.static.GetInstance()
        .ProcessInput(PRS(default.queryASuccess1), none);
    TEST_ExpectTrue(result.GetSubCommand().ToString() == "simple");

    Issue("Cannot determine when subcommands are missing.");
    result = class'MockCommandA'.static.GetInstance()
        .ProcessInput(PRS(default.queryASuccess2), none);
    TEST_ExpectTrue(result.GetSubCommand().IsEmpty());
}

protected static function SubTest_MockAQ1AndFailed()
{
    local Parser            parser;
    local Command           command;
    local DynamicArray      paramArray;
    local AssociativeArray  parameters;
    parser = Parser(__().memory.Allocate(class'Parser'));
    command = class'MockCommandA'.static.GetInstance();
    Issue("Command queries that should fail succeed instead.");
    parser.InitializeS(default.queryAFailure1);
    TEST_ExpectFalse(command.ProcessInput(parser, none).IsSuccessful());
    parser.InitializeS(default.queryAFailure2);
    TEST_ExpectFalse(command.ProcessInput(parser, none).IsSuccessful());

    Issue("Cannot parse command queries without optional parameters.");
    parameters =
        command.ProcessInput(parser.InitializeS(default.queryASuccess1), none)
        .GetParameters();
    TEST_ExpectTrue(parameters.GetLength() == 2);
    paramArray = DynamicArray(parameters.GetItem(P("isItSimple?")));
    TEST_ExpectTrue(paramArray.GetLength() == 1);
    TEST_ExpectFalse(BoolBox(paramArray.GetItem(0)).Get());
    TEST_ExpectTrue(IntBox(parameters.GetItem(P("int"))).Get() == 8);
    TEST_ExpectFalse(parameters.HasKey(P("list")));
    TEST_ExpectFalse(parameters.HasKey(P("another list")));
}

protected static function SubTest_MockAQ2()
{
    local DynamicArray      paramArray, subArray;
    local AssociativeArray  result, subObject;
    Issue("Cannot parse command queries without optional parameters.");
    result = class'MockCommandA'.static.GetInstance()
        .ProcessInput(PRS(default.queryASuccess2), none).GetParameters();
    TEST_ExpectTrue(result.GetLength() == 2);
    subObject = AssociativeArray(result.GetItem(P("just_obj")));
    TEST_ExpectTrue(IntBox(subObject.GetItem(P("var"))).Get() == 7);
    TEST_ExpectTrue(subObject.HasKey(P("another")));
    TEST_ExpectNone(subObject.GetItem(P("another")));
    paramArray = DynamicArray(result.GetItem(P("manyLists")));
    TEST_ExpectTrue(paramArray.GetLength() == 4);
    subArray = DynamicArray(paramArray.GetItem(0));
    TEST_ExpectTrue(subArray.GetLength() == 2);
    TEST_ExpectTrue(IntBox(subArray.GetItem(0)).Get() == 1);
    TEST_ExpectTrue(IntBox(subArray.GetItem(1)).Get() == 2);
    subArray = DynamicArray(paramArray.GetItem(1));
    TEST_ExpectTrue(subArray.GetLength() == 1);
    TEST_ExpectTrue(IntBox(subArray.GetItem(0)).Get() == 3);
    TEST_ExpectTrue(DynamicArray(paramArray.GetItem(2)).GetLength() == 0);
    subArray = DynamicArray(paramArray.GetItem(3));
    TEST_ExpectTrue(subArray.GetLength() == 3);
    TEST_ExpectTrue(IntBox(subArray.GetItem(0)).Get() == 8);
    TEST_ExpectTrue(IntBox(subArray.GetItem(1)).Get() == 5);
    TEST_ExpectTrue(IntBox(subArray.GetItem(2)).Get() == 0);
    TEST_ExpectFalse(result.HasKey(P("last_obj")));
}

protected static function SubTest_MockAQ3()
{
    local DynamicArray      paramArray;
    local AssociativeArray  result;
    Issue("Cannot parse command queries with optional parameters.");
    result = class'MockCommandA'.static.GetInstance()
        .ProcessInput(PRS(default.queryASuccess3), none).GetParameters();
    //  Booleans
    paramArray = DynamicArray(result.GetItem(P("isItSimple?")));
    TEST_ExpectTrue(paramArray.GetLength() == 7);
    TEST_ExpectTrue(BoolBox(paramArray.GetItem(0)).Get());
    TEST_ExpectFalse(BoolBox(paramArray.GetItem(1)).Get());
    TEST_ExpectTrue(BoolBox(paramArray.GetItem(2)).Get());
    TEST_ExpectTrue(BoolBox(paramArray.GetItem(3)).Get());
    TEST_ExpectFalse(BoolBox(paramArray.GetItem(4)).Get());
    TEST_ExpectTrue(BoolBox(paramArray.GetItem(5)).Get());
    TEST_ExpectFalse(BoolBox(paramArray.GetItem(6)).Get());
    //  Integer
    TEST_ExpectTrue(IntBox(result.GetItem(P("int"))).Get() == -32);
    //  Floats
    paramArray = DynamicArray(result.GetItem(P("list")));
    TEST_ExpectTrue(paramArray.GetLength() == 3);
    TEST_ExpectTrue(FloatBox(paramArray.GetItem(0)).Get() == 0.45);
    TEST_ExpectTrue(FloatBox(paramArray.GetItem(1)).Get() == 234.7);
    TEST_ExpectTrue(FloatBox(paramArray.GetItem(2)).Get() == 13);
    //  `Text`s
    paramArray = DynamicArray(result.GetItem(P("another list")));
    TEST_ExpectTrue(paramArray.GetLength() == 3);
    TEST_ExpectTrue(Text(paramArray.GetItem(0)).ToString() == "dk");
    TEST_ExpectTrue(Text(paramArray.GetItem(1)).ToString() == "someone");
    TEST_ExpectTrue(    Text(paramArray.GetItem(2)).ToFormattedString()
                    ==  "complex {rgb(123,45,72) string}");
}

protected static function SubTest_MockAQ4()
{
    local DynamicArray      paramArray;
    local AssociativeArray  result, subObject;
    Issue("Cannot parse command queries with optional parameters.");
    result = class'MockCommandA'.static.GetInstance()
        .ProcessInput(PRS(default.queryASuccess4), none).GetParameters();
    TEST_ExpectTrue(result.GetLength() == 3);
    subObject = AssociativeArray(result.GetItem(P("just_obj")));
    TEST_ExpectTrue(IntBox(subObject.GetItem(P("var"))).Get() == 7);
    TEST_ExpectTrue(subObject.HasKey(P("another")));
    TEST_ExpectNone(subObject.GetItem(P("another")));
    paramArray = DynamicArray(result.GetItem(P("manyLists")));
    TEST_ExpectTrue(paramArray.GetLength() == 4);
    subObject = AssociativeArray(result.GetItem(P("last_obj")));
    TEST_ExpectTrue(subObject.GetLength() == 0);
}

protected static function SubTest_MockBFailed()
{
    local Parser    parser;
    local Command   command;
    parser = Parser(__().memory.Allocate(class'Parser'));
    command = class'MockCommandB'.static.GetInstance();
    Issue("Command queries that should fail succeed instead.");
    parser.InitializeS(default.queryBFailure1);
    TEST_ExpectFalse(command.ProcessInput(parser, none).IsSuccessful());
    parser.InitializeS(default.queryBFailure2);
    TEST_ExpectFalse(command.ProcessInput(parser, none).IsSuccessful());
    parser.InitializeS(default.queryBFailure3);
    TEST_ExpectFalse(command.ProcessInput(parser, none).IsSuccessful());
    parser.InitializeS(default.queryBFailureNoReqParamOption1);
    TEST_ExpectFalse(command.ProcessInput(parser, none).IsSuccessful());
    parser.InitializeS(default.queryBFailureNoReqParamOption2);
    TEST_ExpectFalse(command.ProcessInput(parser, none).IsSuccessful());
    parser.InitializeS(default.queryBFailureUnknownOptionLong);
    TEST_ExpectFalse(command.ProcessInput(parser, none).IsSuccessful());
    parser.InitializeS(default.queryBFailureUnknownOptionShort);
    TEST_ExpectFalse(command.ProcessInput(parser, none).IsSuccessful());
    parser.InitializeS(default.queryBFailureUnused);
    TEST_ExpectFalse(command.ProcessInput(parser, none).IsSuccessful());
}

protected static function SubTest_MockBQ1()
{
    local CommandCall     result;
    local DynamicArray      subArray;
    local AssociativeArray  params, options, subObject;
    Issue("Cannot parse command queries with options.");
    result = class'MockCommandB'.static.GetInstance()
        .ProcessInput(PRS(default.queryBSuccess1), none);
    params = result.GetParameters();
    TEST_ExpectTrue(params.GetLength() == 2);
    subArray = DynamicArray(params.GetItem(P("just_array")));
    TEST_ExpectTrue(subArray.GetLength() == 2);
    TEST_ExpectTrue(IntBox(subArray.GetItem(0)).Get() == 7);
    TEST_ExpectNone(subArray.GetItem(1));
    TEST_ExpectTrue(    Text(params.GetItem(P("just_text"))).ToString()
                    ==  "text");
    options = result.GetOptions();
    TEST_ExpectTrue(options.GetLength() == 1);
    subObject = AssociativeArray(options.GetItem(P("values")));
    TEST_ExpectTrue(subObject.GetLength() == 1);
    subArray = DynamicArray(subObject.GetItem(P("types")));
    TEST_ExpectTrue(subArray.GetLength() == 5);
    TEST_ExpectTrue(IntBox(subArray.GetItem(0)).Get() == 1);
    TEST_ExpectTrue(IntBox(subArray.GetItem(1)).Get() == 3);
    TEST_ExpectTrue(IntBox(subArray.GetItem(2)).Get() == 5);
    TEST_ExpectTrue(IntBox(subArray.GetItem(3)).Get() == 2);
    TEST_ExpectTrue(IntBox(subArray.GetItem(4)).Get() == 4);
}

protected static function SubTest_MockBQ2()
{
    local CommandCall       result;
    local DynamicArray      subArray;
    local AssociativeArray  options, subObject;
    Issue("Cannot parse command queries with mixed-in options.");
    result = class'MockCommandB'.static.GetInstance()
        .ProcessInput(PRS(default.queryBSuccess2), none);
    TEST_ExpectTrue(result.GetParameters().GetLength() == 0);
    options = result.GetOptions();
    TEST_ExpectTrue(options.GetLength() == 7);
    TEST_ExpectTrue(options.HasKey(P("actual")));
    TEST_ExpectNone(options.GetItem(P("actual")));
    TEST_ExpectTrue(options.HasKey(P("silent")));
    TEST_ExpectNone(options.GetItem(P("silent")));
    TEST_ExpectTrue(options.HasKey(P("verbose")));
    TEST_ExpectNone(options.GetItem(P("verbose")));
    TEST_ExpectTrue(options.HasKey(P("forced")));
    TEST_ExpectNone(options.GetItem(P("forced")));
    subObject = AssociativeArray(options.GetItem(P("type")));
    TEST_ExpectTrue(    Text(subObject.GetItem(P("type"))).ToString()
                    ==  "value");
    subObject = AssociativeArray(options.GetItem(P("Test")));
    TEST_ExpectTrue(Text(subObject.GetItem(P("to_test"))).IsEmpty());
    subObject = AssociativeArray(options.GetItem(P("values")));
    subArray = DynamicArray(subObject.GetItem(P("types")));
    TEST_ExpectTrue(subArray.GetLength() == 1);
    TEST_ExpectTrue(IntBox(subArray.GetItem(0)).Get() == 8);
}

protected static function SubTest_MockBQ3Remainder()
{
    local CommandCall       result;
    local DynamicArray      subArray;
    local AssociativeArray  options, subObject;
    Issue("Cannot parse command queries with `CPT_Remainder` type parameters.");
    result = class'MockCommandB'.static.GetInstance()
        .ProcessInput(PRS(default.queryBSuccess3), none);
    TEST_ExpectTrue(result.GetParameters().GetLength() == 1);
    subArray = DynamicArray(result.GetParameters().GetItem(P("list")));
    TEST_ExpectTrue(FloatBox(subArray.GetItem(0)).Get() == 3);
    TEST_ExpectTrue(FloatBox(subArray.GetItem(1)).Get() == -76);
    options = result.GetOptions();
    TEST_ExpectTrue(options.GetLength() == 1);
    TEST_ExpectTrue(options.HasKey(P("remainder")));
    subObject = AssociativeArray(options.GetItem(P("remainder")));
    TEST_ExpectTrue(    Text(subObject.GetItem(P("everything"))).ToString()
                    ==  "--type \"value\" -va 8 -sV --forced -T  \"\" 32");
}
// [1, 2, 3, 6]
defaultproperties
{
    caseName = "Command"
    caseGroup = "Commands"

    queryASuccess1 = "simple disable 0o10  "
    queryASuccess2 = "{\"var\": 7, \"another\": null} [1,2] [3] [] [8, 5, 0]"
    queryASuccess3 = "simple true false enable yes no on off -32 45e-2 234.7 13 dk someone \"complex {#7b2d48 string}\" "
    queryASuccess4 = "{\"var\": 7, \"another\": null} [1,2] [3] [] [8, 5, 0] {}"
    queryAFailure1 = "simple true false enable yes no no on disable yes off false"
    queryAFailure2 = "simple fal"

    queryBSuccess1 = "[7, null] --values 1 3 5 2 4 text"
    queryBSuccess2 = "do --type \"value\" -va 8 -sV --forced -T  \"\" "
    queryBSuccess3 = "do 3 -76 -r --type \"value\" -va 8 -sV --forced -T  \"\" 32"
    //  long then same as short
    queryBFailure1 = "[] 8 -tv 13"
    queryBFailure2 = "do 7 5 -sfV --forced yes"
    queryBFailure3 = "[] 8 -l 12 14 23.3 3.71 -t `something` -7e4 false text"
    queryBFailureNoReqParamOption1 = "[] 8 --long 12 14 23.3 3.71 --type `something` -7e4 false text"
    queryBFailureNoReqParamOption2 = "[] 8 -v"
    queryBFailureUnknownOptionLong = "[] text --kest"
    queryBFailureUnknownOptionShort = "[] text -j"
    queryBFailureUnused = "[] 8 text -j"
}