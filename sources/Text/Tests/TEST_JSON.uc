/**
 *  Set of tests for functionality of JSON printing/parsing.
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
class TEST_JSON extends TestCase
    abstract;

var string simpleJSONObject, complexJSONObject;

protected static function TESTS()
{
    Test_Pointer();
    Test_Print();
    Test_Parse();
}

protected static function Test_Pointer()
{
    Context("Testing method for working with JSON pointers.");
    SubTest_PointerCreate();
    SubTest_PointerToText();
    SubTest_PointerPushPop();
    SubTest_PointerNumeric();
    SubTest_PopWithoutRemoving();
}

protected static function SubTest_PointerCreate()
{
    local JSONPointer pointer;
    Issue("\"Empty\" JSON pointers are not handled correctly.");
    pointer = __().json.Pointer(P(""));
    TEST_ExpectTrue(pointer.GetLength() == 0);
    TEST_ExpectNone(pointer.GetComponent(0));
    pointer = __().json.Pointer(P("/"));
    TEST_ExpectTrue(pointer.GetLength() == 1);
    TEST_ExpectNotNone(pointer.GetComponent(0));
    TEST_ExpectTrue(pointer.GetComponent(0).IsEmpty());

    Issue("Normal JSON pointers are not handled correctly.");
    pointer = __().json.Pointer(P("/a~1b/c%d/e^f//g|h/i\\j/m~0n/"));
    TEST_ExpectTrue(pointer.GetLength() == 8);
    TEST_ExpectTrue(pointer.GetComponent(0).ToString() == "a/b");
    TEST_ExpectTrue(pointer.GetComponent(1).ToString() == "c%d");
    TEST_ExpectTrue(pointer.GetComponent(2).ToString() == "e^f");
    TEST_ExpectTrue(pointer.GetComponent(3).ToString() == "");
    TEST_ExpectTrue(pointer.GetComponent(4).ToString() == "g|h");
    TEST_ExpectTrue(pointer.GetComponent(5).ToString() == "i\\j");
    TEST_ExpectTrue(pointer.GetComponent(6).ToString() == "m~n");
    TEST_ExpectTrue(pointer.GetComponent(7).ToString() == "");

    Issue("Initializing JSON pointers with values, not starting with \"/\","
        @ "is not handled correctly.");
    pointer = __().json.Pointer(P("huh/send~0/pics~1"));
    TEST_ExpectTrue(pointer.GetLength() == 3);
    TEST_ExpectTrue(pointer.GetComponent(0).ToString() ==  "huh");
    TEST_ExpectTrue(pointer.GetComponent(1).ToString() ==  "send~");
    TEST_ExpectTrue(pointer.GetComponent(2).ToString() ==  "pics/");
}

protected static function SubTest_PointerToText()
{
    local JSONPointer pointer;
    Issue("`JSONPointer` is not converted to `Text` correctly.");
    pointer = __().json.Pointer(P(""));
    TEST_ExpectTrue(pointer.ToText().ToString() == "");
    TEST_ExpectTrue(pointer.ToTextM().ToString() == "");
    pointer = __().json.Pointer(P("///"));
    TEST_ExpectTrue(pointer.ToText().ToString() ==  "///");
    TEST_ExpectTrue(pointer.ToTextM().ToString() ==  "///");
    pointer = __().json.Pointer(P("/a~1b/c%d/e^f//g|h/i\\j/m~0n/"));
    TEST_ExpectTrue(    pointer.ToText().ToString()
                    ==  "/a~1b/c%d/e^f//g|h/i\\j/m~0n/");
    TEST_ExpectTrue(    pointer.ToTextM().ToString()
                    ==  "/a~1b/c%d/e^f//g|h/i\\j/m~0n/");

    pointer = __().json.Pointer(P("/a/b/c"));
    Issue("Result of `ToText()` has a wrong class.");
    TEST_ExpectTrue(pointer.ToText().class == class'Text');

    Issue("Result of `ToTextM()` has a wrong class.");
    TEST_ExpectTrue(pointer.ToTextM().class == class'MutableText');
}

protected static function SubTest_PointerPushPop()
{
    local JSONPointer pointer;
    local Text value0, value1, value2, value3, value4, value5, value6;
    Issue("`Push()`/`PushNumeric()` incorrectly affect `JSONPointer`.");
    pointer = __().json.Pointer(P("//lets/go"));
    pointer.Push(P("one")).PushNumeric(404).Push(P("More"));
    TEST_ExpectTrue(    pointer.ToText().ToString()
                    ==  "//lets/go/one/404/More");

    Issue("`Pop()` incorrectly affects `JSONPointer`.");
    value6 = pointer.Pop();
    TEST_ExpectTrue(pointer.ToText().ToString() ==  "//lets/go/one/404");
    value5 = pointer.Pop();
    TEST_ExpectTrue(pointer.ToText().ToString() ==  "//lets/go/one");
    value4 = pointer.Pop();
    TEST_ExpectTrue(pointer.ToText().ToString() ==  "//lets/go");
    value3 = pointer.Pop();
    TEST_ExpectTrue(pointer.ToText().ToString() ==  "//lets");
    value2 = pointer.Pop();
    TEST_ExpectTrue(pointer.ToText().ToString() ==  "/");
    value1 = pointer.Pop();
    TEST_ExpectTrue(pointer.ToText().ToString() ==  "");
    value0 = pointer.Pop();

    Issue("`Pop()` returns incorrect value.");
    TEST_ExpectTrue(value6.ToString() == "More");
    TEST_ExpectTrue(value5.ToString() == "404");
    TEST_ExpectTrue(value4.ToString() == "one");
    TEST_ExpectTrue(value3.ToString() == "go");
    TEST_ExpectTrue(value2.ToString() == "lets");
    TEST_ExpectTrue(value1.ToString() == "");
    TEST_ExpectNone(value0);
}

protected static function SubTest_PointerNumeric()
{
    local JSONPointer   pointer;
    local string        correct, incorrect;
    correct = "`GetNumericComponent()`/`PopNumeric()` cannot correctly retrieve"
        @ "`JSONPointer`'s numeric components.";
    incorrect = "`GetNumericComponent()`/`PopNumeric()` do not return negative"
        @ "values for non-numeric components `JSONPointer`'s"
        @ "numeric components.";
    Issue(correct);
    pointer = __().json.Pointer(P("/lets//404/8./6/11/d/0"));
    pointer.PushNumeric(-2).PushNumeric(13);
    TEST_ExpectTrue(pointer.GetNumericComponent(8) == 13);
    Issue(incorrect);
    TEST_ExpectTrue(pointer.GetNumericComponent(6) < 0);
    Issue(correct);
    TEST_ExpectTrue(pointer.PopNumeric() == 13);
    TEST_ExpectTrue(pointer.PopNumeric() == 0);
    Issue(incorrect);
    TEST_ExpectTrue(pointer.PopNumeric() < 0);
    Issue(correct);
    TEST_ExpectTrue(pointer.PopNumeric() == 11);
    TEST_ExpectTrue(pointer.PopNumeric() == 6);
    Issue(incorrect);
    TEST_ExpectTrue(pointer.PopNumeric() < 0);
    Issue(correct);
    TEST_ExpectTrue(pointer.PopNumeric() == 404);
    Issue(incorrect);
    TEST_ExpectTrue(pointer.PopNumeric() < 0);
    TEST_ExpectTrue(pointer.PopNumeric() < 0);
    TEST_ExpectTrue(pointer.PopNumeric() < 0);
    TEST_ExpectTrue(pointer.PopNumeric() < 0);
}

protected static function SubTest_PopWithoutRemoving()
{
    local Text          component;
    local JSONPointer   pointer;
    Issue("`Pop(true)` removes the value from the pointer.");
    pointer = __().json.Pointer(P("/just/a/simple/test"));
    TEST_ExpectTrue(pointer.Pop(true).ToString() == "test");
    TEST_ExpectTrue(pointer.Pop(true).ToString() == "test");

    Issue("`Pop(true)` returns actually stored value instead of a copy.");
    pointer.Pop(true).FreeSelf();
    TEST_ExpectTrue(pointer.Pop(true).ToString() == "test");
    component = pointer.Pop();
    TEST_ExpectNotNone(component);
    TEST_ExpectTrue(component.ToString() == "test");
    TEST_ExpectTrue(component.IsAllocated());

    Issue("`Pop(true)` breaks after regular `Pop()` call.");
    TEST_ExpectTrue(pointer.Pop(true).ToString() == "simple");
    TEST_ExpectTrue(pointer.Pop(true).ToString() == "simple");
}

protected static function Test_Print()
{
    Context("Testing printing simple JSON values.");
    SubTest_SimplePrint();
    SubTest_ArrayPrint();
}

protected static function SubTest_SimplePrint()
{
    local string complexString;
    Issue("Simple JSON values are not printed as expected.");
    TEST_ExpectTrue(__().json.Print(none).ToString() == "null");
    TEST_ExpectTrue(    __().json.Print(__().box.bool(false)).ToString()
                    ==  "false");
    TEST_ExpectTrue(    __().json.Print(__().ref.bool(true)).ToFormattedString()
                    ==  "true");
    TEST_ExpectTrue(    __().json.Print(__().box.int(-752)).ToFormattedString()
                    ==  "-752");
    TEST_ExpectTrue(    __().json.Print(__().ref.int(36235)).ToFormattedString()
                    ==  "36235");
    TEST_ExpectTrue(    __().json.Print(__().box.float(5.673)).ToString()
                    ==  "5.673");
    TEST_ExpectTrue(    __().json.Print(__().ref.float(-3.502)).ToString()
                    ==  "-3.502");
    TEST_ExpectTrue(    __().json.Print(F("{#ff000 col}ored")).ToString()
                    ==  "\"colored\"");
    TEST_ExpectTrue(    __().json.Print(P("simple text")).ToFormattedString()
                    ==  "\"simple text\"");
    complexString = "\"comp/lex\"" $ Chr(0x0a) $ "\\str";
    TEST_ExpectTrue(    __().json.Print(P(complexString)).ToFormattedString()
                    ==  "\"\\\"comp\\/lex\\\"\\n\\\\str\"");

    Issue("Printing unrelated objects does not produce `none`s.");
    TEST_ExpectNone(
        __().json.Print(AcediaObject(__().memory.Allocate(class'Parser'))));
}

protected static function SubTest_ArrayPrint()
{
    local ArrayList array, subArray;
    array = ArrayList(__().memory.Allocate(class'ArrayList'));
    subArray = ArrayList(__().memory.Allocate(class'ArrayList'));
    subArray.AddItem(__().box.int(-752));
    subArray.AddItem(__().ref.bool(true));
    subArray.AddItem(__().box.float(3.44));
    subArray.AddItem(__().text.FromString("\"quoted text\""));
    array.AddItem(__().ref.float(34.1));
    array.AddItem(none);
    array.AddItem(subArray);
    array.AddItem(__().text.FromString("	"));
    Issue("JSON arrays are not printed as expected.");
    TEST_ExpectTrue(
            __().json.PrintArrayList(array).ToString()
        ==  "[34.1,null,[-752,true,3.44,\"\\\"quoted text\\\"\"],\"\\t\"]");
    TEST_ExpectTrue(
            __().json.Print(array).ToString()
        ==  "[34.1,null,[-752,true,3.44,\"\\\"quoted text\\\"\"],\"\\t\"]");
}

protected static function Test_Parse()
{
    Context("Testing JSON null parsing methods.");
    SubTest_ParseNull();
    Context("Testing JSON boolean parsing methods.");
    SubTest_ParseBooleanVariable();
    SubTest_ParseBoolean();
    Context("Testing JSON number parsing methods.");
    SubTest_ParseIntegerVariable();
    SubTest_ParseFloatVariable();
    SubTest_ParseNumber();
    Context("Testing JSON string parsing methods.");
    SubTest_ParseString();
    Context("Testing JSON methods for parsing arrays"
        @ "(on arrays with simple value).");
    SubTest_ParseArraySuccess();
    SubTest_ParseArrayFailure();
    Context("Testing JSON methods for parsing object"
        @ "(on objects with simple value).");
    SubTest_ParseObjectSuccess();
    SubTest_ParseObjectFailure();
    Context("Testing generic JSON methods for value parsing.");
    SubTest_ParseSimpleValueSuccess();
    SubTest_ParseSimpleValueFailure();
    Context("Testing parsing complex JSON values.");
    SubTest_ParseComplex();
}

protected static function SubTest_ParseNull()
{
    local Parser parser;
    Issue("`IsNull()` returns `false` for correct JSON null values.");
    TEST_ExpectTrue(__().json.IsNull(P("Null")));
    TEST_ExpectTrue(__().json.IsNull(P("nUll")));

    Issue("`ParseBoolean()` returns `true` for invalid JSON null values.");
    TEST_ExpectFalse(__().json.IsNull(P("Nul")));
    TEST_ExpectFalse(__().json.IsNull(P(" nUll")));
    TEST_ExpectFalse(__().json.IsNull(P("Null ")));

    parser = __().text.Parse(P("nullNullnU"));
    Issue("`TryNullWith()` cannot parse correct JSON null values.");
    __().json.TryNullWith(parser);
    __().json.TryNullWith(parser);
    TEST_ExpectTrue(parser.Ok());
    __().json.TryNullWith(parser);
    TEST_ExpectFalse(parser.Ok());
}

protected static function SubTest_ParseBooleanVariable()
{
    local Parser parser;
    parser = __().text.Parse(P("trUEfAlseTr"));
    Issue("`ParseBooleanVariableWith()` cannot parse correct"
        @ "JSON boolean values.");
    TEST_ExpectTrue(__().json.ParseBooleanVariableWith(parser));
    TEST_ExpectFalse(__().json.ParseBooleanVariableWith(parser));
    TEST_ExpectTrue(parser.Ok());

    Issue("`ParseBooleanVariableWith()` returns `true` for invalid"
        @ "JSON boolean values.");
    TEST_ExpectFalse(__().json.ParseBooleanVariableWith(parser));

    Issue("`ParseBooleanVariableWith()` reports success for invalid"
        @ "JSON boolean values.");
    TEST_ExpectFalse(parser.Ok());
}

protected static function SubTest_ParseBoolean()
{
    local Parser parser;
    Issue("`ParseBoolean()` fails to parse correct JSON booleans.");
    TEST_ExpectTrue(BoolBox(__().json.ParseBoolean(P("tRuE"))).Get());
    TEST_ExpectFalse(BoolRef(__().json.ParseBoolean(P("FAlSe"), true)).Get());

    Issue("`ParseBoolean()` returns non-`none` values for invalid"
        @ "JSON booleans.");
    TEST_ExpectNone(__().json.ParseBoolean(P("tru")));
    TEST_ExpectNone(__().json.ParseBoolean(P("")));
    TEST_ExpectNone(__().json.ParseBoolean(P("false+")));

    parser = __().text.Parse(P("trUEfAlseTr"));
    Issue("`ParseBooleanWith()` fails to parse correct JSON booleans.");
    TEST_ExpectTrue(BoolBox(__().json.ParseBooleanWith(parser)).Get());
    TEST_ExpectFalse(BoolRef(__().json.ParseBooleanWith(parser, true)).Get());
    TEST_ExpectTrue(parser.Ok());

    Issue("`ParseBooleanWith()` returns non-`none` values for invalid"
        @ "JSON booleans or parsers in failed state.");
    TEST_ExpectNone(__().json.ParseBooleanWith(parser));
    TEST_ExpectFalse(parser.Ok());
    TEST_ExpectNone(__().json.ParseBooleanWith(parser));
}

protected static function SubTest_ParseIntegerVariable()
{
    local Parser parser;
    parser = __().text.ParseString("13 -67.3 423e-2 0x67");
    Issue("`ParseIntegerVariableWith()` cannot parse correct"
        @ "JSON number values.");
    TEST_ExpectTrue(__().json.ParseIntegerVariableWith(parser) == 13);
    TEST_ExpectTrue(__().json.ParseIntegerVariableWith(parser.Skip()) == -67);
    TEST_ExpectTrue(__().json.ParseIntegerVariableWith(parser.Skip()) == 4);
    TEST_ExpectTrue(__().json.ParseIntegerVariableWith(parser.Skip()) == 0);
    TEST_ExpectTrue(parser.Ok());

    Issue("`ParseIntegerVariableWith()` returns non-zero values when it"
        @ "should have failed parsing.");
    TEST_ExpectTrue(__().json.ParseIntegerVariableWith(parser.Skip()) == 0);

    Issue("`ParseIntegerVariableWith()` does not put parser into a failed state"
        @ "when it failed parsing.");
    TEST_ExpectFalse(parser.Ok());

    Issue("`ParseIntegerVariableWith()` parses number values in"
        @ "\"float format\" with `integerOnly` parameter set to `true`.");
    parser = __().text.ParseString("-67.3");
    TEST_ExpectTrue(__().json.ParseIntegerVariableWith(parser, true) == 0);
    TEST_ExpectFalse(parser.Ok());
    parser = __().text.ParseString("32e2");
    TEST_ExpectTrue(__().json.ParseIntegerVariableWith(parser, true) == 0);
    TEST_ExpectFalse(parser.Ok());
}

protected static function SubTest_ParseFloatVariable()
{
    local Parser parser;
    parser = __().text.ParseString("13 -67.3 423e-2 0x67");
    Issue("`ParseFloatVariableWith()` cannot parse correct JSON"
        @ "number values.");
    TEST_ExpectTrue(__().json.ParseFloatVariableWith(parser) == 13);
    TEST_ExpectTrue(__().json.ParseFloatVariableWith(parser.Skip()) == -67.3);
    TEST_ExpectTrue(__().json.ParseFloatVariableWith(parser.Skip()) == 4.23);
    TEST_ExpectTrue(__().json.ParseFloatVariableWith(parser.Skip()) == 0);
    TEST_ExpectTrue(parser.Ok());

    Issue("`ParseFloatVariableWith()` returns non-zero values when it"
        @ "should have failed parsing.");
    TEST_ExpectTrue(__().json.ParseFloatVariableWith(parser.Skip()) == 0);

    Issue("`ParseFloatVariableWith()` does not put parser into a failed state"
        @ "when it failed parsing.");
    TEST_ExpectFalse(parser.Ok());
}

protected static function SubTest_ParseNumber()
{
    local Parser parser;
    Issue("`ParseNumber()` fails to parse correct JSON numbers.");
    TEST_ExpectTrue(IntBox(__().json.ParseNumber(P("32"))).Get() == 32);
    TEST_ExpectTrue(    IntRef(__().json.ParseNumber(P("-24"), true)).Get()
                    ==  -24);
    TEST_ExpectTrue(    FloatBox(__().json.ParseNumber(P("-2.6e3"))).Get()
                    ==  -2600);
    TEST_ExpectTrue(    FloatRef(__().json.ParseNumber(P("98e-1"), true)).Get()
                    ==  9.8);

    Issue("`ParseNumber()` returns non-`none` values for invalid"
        @ "JSON numbers.");
    TEST_ExpectNone(__().json.ParseNumber(P(".34")));
    TEST_ExpectNone(__().json.ParseNumber(P("4 ")));

    parser = __().text.Parse(P("-83 0 0.4 -4.676 e2"));
    Issue("`ParseNumberWith()` fails to parse correct JSON numbers.");
    TEST_ExpectTrue(    IntBox(__().json.ParseNumberWith(parser.Skip())).Get()
                    ==  -83);
    TEST_ExpectTrue(
        IntRef(__().json.ParseNumberWith(parser.Skip(), true)).Get() == 0);
    TEST_ExpectTrue(    FloatBox(__().json.ParseNumberWith(parser.Skip())).Get()
                    ==  0.4);
    TEST_ExpectTrue(
            FloatRef(__().json.ParseNumberWith(parser.Skip(), true)).Get()
        ==  -4.676);
    TEST_ExpectTrue(parser.Ok());

    Issue("`ParseNumberWith()` returns non-`none` values for invalid"
        @ "JSON numbers or parsers in failed state.");
    TEST_ExpectNone(__().json.ParseNumberWith(parser.Skip()));
    TEST_ExpectFalse(parser.Ok());
    TEST_ExpectNone(__().json.ParseNumberWith(parser));
}

protected static function SubTest_ParseString()
{
    local Parser parser;
    Issue("`ParseString()` fails to parse correct JSON strings.");
    TEST_ExpectTrue(    __().json.ParseString(P("\"string !\"")).ToString()
                    ==  "string !");
    TEST_ExpectTrue(
            MutableText(__().json.ParseString(P("\"\""), true)).ToString()
        ==  "");

    Issue("`ParseString()` returns non-`none` values for invalid"
        @ "JSON strings.");
    TEST_ExpectNone(__().json.ParseString(P("\"unclosed")));
    TEST_ExpectNone(__().json.ParseString(P("no quotes")));
    TEST_ExpectNone(__().json.ParseString(P("\"space at the end\" ")));

    parser = __().text.Parse(P("\"str\"\" also a kind `of` a string\"not"));
    Issue("`ParseStringWith()` fails to parse correct JSON strings.");
    TEST_ExpectTrue(__().json.ParseStringWith(parser).ToString() == "str");
    TEST_ExpectTrue(
            MutableText(__().json.ParseStringWith(parser, true)).ToString()
        ==  " also a kind `of` a string");
    TEST_ExpectTrue(parser.Ok());

    Issue("`ParseStringWith()` returns non-`none` values for invalid"
        @ "JSON strings or parsers in failed state.");
    TEST_ExpectNone(__().json.ParseStringWith(parser));
    TEST_ExpectFalse(parser.Ok());
    TEST_ExpectNone(__().json.ParseStringWith(parser));
}

protected static function SubTest_ParseArraySuccess()
{
    local Parser    parser;
    local ArrayList result;
    Issue("`ParseArrayListWith()` fails to parse empty JSON array.");
    parser = __().text.ParseString("[]");
    result = __().json.ParseArrayListWith(parser);
    TEST_ExpectNotNone(result);
    TEST_ExpectTrue(parser.OK());
    TEST_ExpectTrue(result.GetLength() == 0);

    Issue("`ParseArrayListWith()` fails to parse correct JSON arrays"
        @ "(as immutable).");
    parser = __().text.ParseString("[true, 76.4, \"val\", null, 5]");
    result = __().json.ParseArrayListWith(parser);
    TEST_ExpectNotNone(result);
    TEST_ExpectTrue(parser.OK());
    TEST_ExpectTrue(result.GetLength() == 5);
    TEST_ExpectTrue(BoolBox(result.GetItem(0)).Get());
    TEST_ExpectTrue(FloatBox(result.GetItem(1)).Get() == 76.4);
    TEST_ExpectTrue(Text(result.GetItem(2)).ToString() == "val");
    TEST_ExpectNone(result.GetItem(3));
    TEST_ExpectTrue(IntBox(result.GetItem(4)).Get() == 5);

    Issue("`ParseArrayListWith()` fails to parse correct JSON arrays"
        @ "(as mutable).");
    result = __().json.ParseArrayListWith(parser.R(), true);
    TEST_ExpectNotNone(result);
    TEST_ExpectTrue(parser.OK());
    TEST_ExpectTrue(result.GetLength() == 5);
    TEST_ExpectTrue(BoolRef(result.GetItem(0)).Get());
    TEST_ExpectTrue(FloatRef(result.GetItem(1)).Get() == 76.4);
    TEST_ExpectTrue(MutableText(result.GetItem(2)).ToString() == "val");
    TEST_ExpectNone(result.GetItem(3));
    TEST_ExpectTrue(IntRef(result.GetItem(4)).Get() == 5);
}

protected static function SubTest_ParseArrayFailure()
{
    local Parser    parser;
    local ArrayList result;
    Issue("`ParseArrayListWith()` incorrectly handles parsing invalid"
        @ "JSON arrays.");
    parser = __().text.ParseString("[,]");
    result = __().json.ParseArrayListWith(parser);
    TEST_ExpectNone(result);
    TEST_ExpectFalse(parser.OK());

    parser = __().text.ParseString("[true, 76.4, \"val\", null, 5");
    result = __().json.ParseArrayListWith(parser);
    TEST_ExpectNone(result);
    TEST_ExpectFalse(parser.OK());

    parser = __().text.ParseString("[true, 76.4, \"val\", null,]");
    result = __().json.ParseArrayListWith(parser, true);
    TEST_ExpectNone(result);
    TEST_ExpectFalse(parser.OK());
}

protected static function SubTest_ParseSimpleValueSuccess()
{
    local JSONAPI   api;
    local Parser    parser;
    api = __().json;
    Issue("`ParseWith()` fails to parse correct JSON values.");
    parser = __().text.ParseString("false, 98.2, 42, \"hmmm\", null");
    TEST_ExpectFalse(BoolBox(api.ParseWith(parser)).Get());
    parser.MatchS(",").Skip();
    TEST_ExpectTrue(FloatBox(api.ParseWith(parser)).Get() == 98.2);
    parser.MatchS(",").Skip();
    TEST_ExpectTrue(IntRef(api.ParseWith(parser, true)).Get() == 42);
    parser.MatchS(",").Skip();
    TEST_ExpectTrue(
            MutableText(api.ParseWith(parser, true)).ToString()
        ==  "hmmm");
    parser.MatchS(",").Skip();
    TEST_ExpectNone(api.ParseWith(parser));
    TEST_ExpectTrue(parser.Ok());
}
protected static function SubTest_ParseSimpleValueFailure()
{
    local JSONAPI   api;
    local Parser    parser;
    api = __().json;
    Issue("`ParseWith()` does not correctly handle parsing invalid"
        @ "JSON values.");
    parser = __().text.ParseString("tru");
    TEST_ExpectNone(api.ParseWith(parser));
    TEST_ExpectFalse(parser.Ok());
    parser = __().text.ParseString("");
    TEST_ExpectNone(api.ParseWith(parser));
    TEST_ExpectFalse(parser.Ok());
    parser = __().text.ParseString("NUL");
    TEST_ExpectNone(api.ParseWith(parser));
    TEST_ExpectFalse(parser.Ok());
}

protected static function SubTest_ParseObjectSuccess()
{
    local Parser    parser;
    local HashTable result;
    Issue("`ParseHashTableWith()` fails to parse empty JSON object.");
    parser = __().text.ParseString("{ }");
    result = __().json.ParseHashTableWith(parser);
    TEST_ExpectNotNone(result);
    TEST_ExpectTrue(parser.OK());
    TEST_ExpectTrue(result.GetLength() == 0);

    Issue("`ParseHashTableWith()` fails to parse correct JSON objects"
        @ "(as immutable).");
    parser = __().text.ParseString(default.simpleJSONObject);
    result = __().json.ParseHashTableWith(parser);
    TEST_ExpectNotNone(result);
    TEST_ExpectTrue(parser.OK());
    TEST_ExpectTrue(result.GetLength() == 4);
    TEST_ExpectTrue(IntBox(result.GetItem(P("var"))).Get() == 13);
    TEST_ExpectTrue(BoolBox(result.GetItem(P("another"))).Get() == true);
    TEST_ExpectTrue(    Text(result.GetItem(P("string one"))).ToString()
                    ==  "string!");
    TEST_ExpectNone(MutableText(result.GetItem(P("string one"))));
    TEST_ExpectNone(result.GetItem(P("last")));

    Issue("`ParseHashTableWith()` fails to parse correct JSON objects"
        @ "(as mutable).");
    result = __().json.ParseHashTableWith(parser.R(), true);
    TEST_ExpectNotNone(result);
    TEST_ExpectTrue(IntRef(result.GetItem(P("var"))).Get() == 13);
    TEST_ExpectTrue(BoolRef(result.GetItem(P("another"))).Get() == true);
    TEST_ExpectTrue(
            MutableText(result.GetItem(P("string one"))).ToString()
        ==  "string!");
    TEST_ExpectNone(result.GetItem(P("last")));
}

protected static function SubTest_ParseObjectFailure()
{
    local Parser    parser;
    local HashTable result;
    Issue("`ParseHashTableWith()` incorrectly handles parsing invalid"
        @ "JSON objects.");
    parser = __().text.ParseString("{,}");
    result = __().json.ParseHashTableWith(parser);
    TEST_ExpectNone(result);
    TEST_ExpectFalse(parser.OK());
    parser = __().text.ParseString("{var:null}");
    result = __().json.ParseHashTableWith(parser);
    TEST_ExpectNone(result);
    TEST_ExpectFalse(parser.OK());
    parser = __().text.ParseString("{\"var\":57,}");
    result = __().json.ParseHashTableWith(parser);
    TEST_ExpectNone(result);
    TEST_ExpectFalse(parser.OK());
    parser = __().text.ParseString("{,\"var\":true}");
    result = __().json.ParseHashTableWith(parser);
    TEST_ExpectNone(result);
    TEST_ExpectFalse(parser.OK());
}

protected static function SubTest_ParseComplex()
{
    local Parser    parser;
    local ArrayList subArr;
    local HashTable root, mainObj, subObj, inner;
    Issue("`ParseHashTableWith()` cannot handle complex values.");
    parser = __().text.ParseString(default.complexJSONObject);
    root = HashTable(__().json.ParseWith(parser));
    TEST_ExpectTrue(root.GetLength() == 3);
    TEST_ExpectTrue(FloatBox(root.GetItem(P("some_var"))).Get() == -7.32);
    TEST_ExpectTrue(    Text(root.GetItem(P("another_var"))).ToString()
                    ==  "aye!");
    mainObj = HashTable(root.GetItem(P("innerObject")));
    TEST_ExpectTrue(root.GetLength() == 3);
    TEST_ExpectTrue(BoolBox(mainObj.GetItem(P("my_bool"))).Get() == true);
    TEST_ExpectTrue(IntBox(mainObj.GetItem(P("my_int"))).Get() == -9823452);
    subObj  = HashTable(mainObj.GetItem(P("one more")));
    subArr  = ArrayList(mainObj.GetItem(P("array")));
    TEST_ExpectTrue(subObj.GetLength() == 3);
    TEST_ExpectTrue(IntBox(subObj.GetItem(P("nope"))).Get() == 324532);
    TEST_ExpectTrue(BoolBox(subObj.GetItem(P("whatever"))).Get() == false);
    TEST_ExpectTrue(    Text(subObj.GetItem(P("o rly?"))).ToString()
                    ==  "ya rly");
    inner = HashTable(subArr.GetItem(3));
    TEST_ExpectTrue(Text(subArr.GetItem(0)).ToString() == "Engine.Actor");
    TEST_ExpectTrue(BoolBox(subArr.GetItem(1)).Get() == false);
    TEST_ExpectNone(subArr.GetItem(2));
    TEST_ExpectTrue(FloatBox(subArr.GetItem(4)).Get() == 56.6);
    TEST_ExpectTrue(
            Text(inner.GetItem(P("something \"here\""))).ToString()
        ==  "yes");
    TEST_ExpectTrue(FloatBox(inner.GetItem(P("maybe"))).Get() == 0.003);
}

defaultproperties
{
    caseName = "JSON"
    caseGroup = "Text"
    simpleJSONObject = "{\"var\": 13, \"another\": true  , \"string one\": \"string!\",\"last\": null}"
    complexJSONObject = "{\"innerObject\":{\"my_bool\":true,\"array\":[\"Engine.Actor\",false,null,{\"something \\\"here\\\"\":\"yes\",\"maybe\":0.003},56.6],\"one more\":{\"nope\":324532,\"whatever\":false,\"o rly?\":\"ya rly\"},\"my_int\":-9823452},\"some_var\":-7.32,\"another_var\":\"aye!\"}"
}