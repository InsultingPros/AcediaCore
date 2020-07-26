/**
 *      Set of tests for JSON data storage, implemented via
 *  `JObject` and `JArray`.
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
class TEST_JSON extends TestCase
    abstract;

var string preparedJObjectString;

protected static function TESTS()
{
    local JObject jsonData;
    jsonData = _().json.newObject();
    Test_ObjectGetSetRemove();
    Test_ObjectKeys();
    Test_ArrayGetSetRemove();
    Test_JSONComparison();
    Test_JSONCloning();
    Test_JSONSetComplexValues();
    Test_JSONParsing();
}

protected static function Test_ObjectGetSetRemove()
{
    SubTest_Undefined();
    SubTest_StringGetSetRemove();
    SubTest_ClassGetSetRemove();
    SubTest_StringAsClass();
    SubTest_BooleanGetSetRemove();
    SubTest_NumberGetSetRemove();
    SubTest_IntegerGetSetRemove();
    SubTest_FloatAndInteger();
    SubTest_NullGetSetRemove();
    SubTest_MultipleVariablesGetSet();
    SubTest_Object();
}

protected static function Test_ArrayGetSetRemove()
{
    Context("Testing get/set/remove functions for JSON arrays");
    SubTest_ArrayUndefined();
    SubTest_ArrayStringGetSetRemove();
    SubTest_ArrayClassGetSetRemove();
    SubTest_ArrayStringAsClass();
    SubTest_ArrayBooleanGetSetRemove();
    SubTest_ArrayNumberGetSetRemove();
    SubTest_ArrayIntegerGetSetRemove();
    SubTest_ArrayFloatAndInteger();
    SubTest_ArrayNullGetSetRemove();
    SubTest_ArrayMultipleVariablesStorage();
    SubTest_ArrayMultipleVariablesRemoval();
    SubTest_ArrayRemovingMultipleVariablesAtOnce();
    SubTest_ArrayExpansions();
}

protected static function SubTest_Undefined()
{
    local JObject testJSON;
    testJSON = _().json.newObject();

    Context("Testing how `JObject` handles undefined values");
    Issue("Undefined variable doesn't have proper type.");
    TEST_ExpectTrue(testJSON.GetTypeOf("some_var") == JSON_Undefined);

    Issue("There is a variable in an empty object after `GetTypeOf` call.");
    TEST_ExpectTrue(testJSON.GetTypeOf("some_var") == JSON_Undefined);

    Issue("Getters don't return default values for undefined variables.");
    TEST_ExpectTrue(testJSON.GetNumber("some_var", 0) == 0);
    TEST_ExpectTrue(testJSON.GetString("some_var", "") == "");
    TEST_ExpectTrue(testJSON.GetBoolean("some_var", false) == false);
    TEST_ExpectNone(testJSON.GetObject("some_var"));
    TEST_ExpectNone(testJSON.GetArray("some_var"));
}

protected static function SubTest_BooleanGetSetRemove()
{
    local JObject testJSON;
    testJSON = _().json.newObject();
    testJSON.SetBoolean("some_boolean", true);

    Context("Testing `JObject`'s get/set/remove functions for" @
            "boolean variables");
    Issue("Boolean type isn't properly set by `SetBoolean`");
    TEST_ExpectTrue(testJSON.GetTypeOf("some_boolean") == JSON_Boolean);

    Issue("Variable value is incorrectly assigned by `SetBoolean`");
    TEST_ExpectTrue(testJSON.GetBoolean("some_boolean") == true);

    Issue("Variable value isn't correctly reassigned by `SetBoolean`");
    testJSON.SetBoolean("some_boolean", false);
    TEST_ExpectTrue(testJSON.GetBoolean("some_boolean") == false);

    Issue(  "Getting boolean variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetNumber("some_boolean", 7) == 7);

    Issue("Boolean variable isn't being properly removed");
    testJSON.RemoveValue("some_boolean");
    TEST_ExpectTrue(testJSON.GetTypeOf("some_boolean") == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored boolean value, that got removed");
    TEST_ExpectTrue(testJSON.GetBoolean("some_boolean", true) == true);
}

protected static function SubTest_StringGetSetRemove()
{
    local JObject testJSON;
    testJSON = _().json.newObject();
    testJSON.SetString("some_string", "first string");

    Context("Testing `JObject`'s get/set/remove functions for" @
            "string variables");
    Issue("String type isn't properly set by `SetString`");
    TEST_ExpectTrue(testJSON.GetTypeOf("some_string") == JSON_String);

    Issue("Value is incorrectly assigned by `SetString`");
    TEST_ExpectTrue(testJSON.GetString("some_string") == "first string");

    Issue(  "Providing default variable value makes 'GetString'" @
            "return wrong value");
    TEST_ExpectTrue(    testJSON.GetString("some_string", "alternative")
                    ==  "first string");

    Issue("Variable value isn't correctly reassigned by `SetString`");
    testJSON.SetString("some_string", "new string!~");
    TEST_ExpectTrue(testJSON.GetString("some_string") == "new string!~");

    Issue(  "Getting string variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetBoolean("some_string", true) == true);

    Issue("String variable isn't being properly removed");
    testJSON.RemoveValue("some_string");
    TEST_ExpectTrue(testJSON.GetTypeOf("some_string") == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored string value, but got removed");
    TEST_ExpectTrue(testJSON.GetString("some_string", "other") == "other");
}

protected static function SubTest_ClassGetSetRemove()
{
    local JObject testJSON;
    testJSON = _().json.newObject();
    testJSON.SetClass("info_class", class'Info');

    Context("Testing `JObject`'s get/set/remove functions for" @
            "class variables");
    Issue("String type isn't properly set by `SetClass`");
    TEST_ExpectTrue(testJSON.GetTypeOf("info_class") == JSON_String);

    Issue("Value is incorrectly assigned by `SetClass`");
    TEST_ExpectTrue(testJSON.GetClass("info_class") == class'Info');

    Issue(  "Providing default variable value makes 'GetClass'" @
            "return wrong value");
    TEST_ExpectTrue(    testJSON.GetClass("info_class", class'Actor')
                    ==  class'Info');

    Issue("Variable value isn't correctly reassigned by `SetClass`");
    testJSON.SetClass("info_class", class'ReplicationInfo');
    TEST_ExpectTrue(testJSON.GetClass("info_class") == class'ReplicationInfo');

    Issue(  "Getting class variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetBoolean("info_class", true) == true);

    Issue("Class variable isn't being properly removed");
    testJSON.RemoveValue("info_class");
    TEST_ExpectTrue(testJSON.GetTypeOf("info_class") == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored class value, but got removed");
    TEST_ExpectTrue(    testJSON.GetClass("info_class", class'Actor')
                    ==  class'Actor');
}

protected static function SubTest_StringAsClass()
{
    local JObject testJSON;
    testJSON = _().json.newObject();
    testJSON.SetString("SetString", "Engine.Actor");
    testJSON.SetString("SetStringIncorrect", "blahblahblah");
    testJSON.SetClass("SetClass", class'Info');
    testJSON.SetClass("none", none);

    Context("Testing how `JObject` treats mixed string and"
        @ "class setters/getters.");
    Issue("Incorrect result of `SetClass().GetString()` sequence.");
    TEST_ExpectTrue(testJSON.GetString("SetClass") == "Engine.Info");
    TEST_ExpectTrue(testJSON.GetString("none") == "None");
    TEST_ExpectTrue(testJSON.GetString("none", "alternative") == "None");

    Issue("Incorrect result of `SetString().GetClass()` sequence for"
        @ "correct value in `SetString()`.");
    TEST_ExpectTrue(testJSON.GetClass("SetString") == class'Actor');
    TEST_ExpectTrue(    testJSON.GetClass("SetString", class'Object')
                    ==  class'Actor');

    Issue("Incorrect result of `SetString().GetClass()` sequence for"
        @ "incorrect value in `SetString()`.");
    TEST_ExpectTrue(testJSON.GetClass("SetStringIncorrect") == none);
    TEST_ExpectTrue(    testJSON.GetClass("SetStringIncorrect", class'Object')
                    ==  class'Object');
}

protected static function SubTest_NumberGetSetRemove()
{
    local JObject testJSON;
    testJSON = _().json.newObject();
    testJSON.SetNumber("some_number", 3.5);

    Context("Testing `JObject`'s get/set/remove functions for" @
            "number variables as floats");
    Issue("Number type isn't properly set by `SetNumber`");
    TEST_ExpectTrue(testJSON.GetTypeOf("some_number") == JSON_Number);

    Issue("Value is incorrectly assigned by `SetNumber`");
    TEST_ExpectTrue(testJSON.GetNumber("some_number") == 3.5);

    Issue(  "Providing default variable value makes 'GetNumber'" @
            "return wrong value");
    TEST_ExpectTrue(testJSON.GetNumber("some_number", 5) == 3.5);

    Issue("Variable value isn't correctly reassigned by `SetNumber`");
    testJSON.SetNumber("some_number", 7);
    TEST_ExpectTrue(testJSON.GetNumber("some_number") == 7);

    Issue(  "Getting number variable as a wrong type" @
            "doesn't yield default value.");
    TEST_ExpectTrue(testJSON.GetString("some_number", "default") == "default");

    Issue("Number type isn't being properly removed");
    testJSON.RemoveValue("some_number");
    TEST_ExpectTrue(testJSON.GetTypeOf("some_number") == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored number value, that got removed");
    TEST_ExpectTrue(testJSON.GetNumber("some_number", 13) == 13);
}

protected static function SubTest_IntegerGetSetRemove()
{
    local JObject testJSON;
    testJSON = _().json.newObject();
    testJSON.SetInteger("some_number", 33653);

    Context("Testing `JObject`'s get/set/remove functions for" @
            "number variables as integers");
    Issue("Number type isn't properly set by `SetInteger`");
    TEST_ExpectTrue(testJSON.GetTypeOf("some_number") == JSON_Number);

    Issue("Value is incorrectly assigned by `SetInteger`");
    TEST_ExpectTrue(testJSON.GetInteger("some_number") == 33653);

    Issue(  "Providing default variable value makes 'GetInteger'" @
            "return wrong value");
    TEST_ExpectTrue(testJSON.GetInteger("some_number", 5) == 33653);

    Issue("Variable value isn't correctly reassigned by `SetInteger`");
    testJSON.SetInteger("some_number", MaxInt);
    TEST_ExpectTrue(testJSON.GetInteger("some_number") == MaxInt);

    Issue(  "Getting number variable as a wrong type" @
            "doesn't yield default value.");
    TEST_ExpectTrue(testJSON.GetString("some_number", "default") == "default");

    Issue("Number type isn't being properly removed");
    testJSON.RemoveValue("some_number");
    TEST_ExpectTrue(testJSON.GetTypeOf("some_number") == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored number value, that got removed");
    TEST_ExpectTrue(testJSON.GetInteger("some_number", -235) == -235);
}

protected static function SubTest_FloatAndInteger()
{
    local JObject testJSON;
    testJSON = _().json.newObject();
    testJSON.SetNumber("SetNumber", 6.70087);

    Context("Testing how `JObject` treats mixed float and"
        @ "integer setters/getters.");
    Issue("Incorrect result of `SetNumber().GetInteger()` sequence.");
    TEST_ExpectTrue(testJSON.GetInteger("SetNumber") == 6);

    testJSON.SetInteger("SetNumber", 11);
    testJSON.SetNumber("SetInteger", 0.43);
    Issue("SetNumber().SetInteger() for same variable name does not overwrite"
        @ "initial number value.");
    TEST_ExpectTrue(testJSON.GetNumber("SetNumber") == 11);

    Issue("SetInteger().SetNumber() for same variable name does not overwrite"
        @ "initial integer value.");
    TEST_ExpectTrue(testJSON.GetInteger("SetInteger") == 0);
}

protected static function SubTest_NullGetSetRemove()
{
    local JObject testJSON;
    testJSON = _().json.newObject();

    Context("Testing `JObject`'s get/set/remove functions for" @
            "null values");
    Issue("Undefined variable is incorrectly considered `null`");
    TEST_ExpectFalse(testJSON.IsNull("some_var"));

    Issue("Number variable is incorrectly considered `null`");
    testJSON.SetNumber("some_var", 4);
    TEST_ExpectFalse(testJSON.IsNull("some_var"));

    Issue("Boolean variable is incorrectly considered `null`");
    testJSON.SetBoolean("some_var", true);
    TEST_ExpectFalse(testJSON.IsNull("some_var"));

    Issue("String variable is incorrectly considered `null`");
    testJSON.SetString("some_var", "string");
    TEST_ExpectFalse(testJSON.IsNull("some_var"));
    
    Issue("Null value is incorrectly assigned");
    testJSON.SetNull("some_var");
    TEST_ExpectTrue(testJSON.IsNull("some_var"));

    Issue("Null type isn't properly set by `SetNumber`");
    TEST_ExpectTrue(testJSON.GetTypeOf("some_var") == JSON_Null);

    Issue("Null value isn't being properly removed.");
    testJSON.RemoveValue("some_var");
    TEST_ExpectTrue(testJSON.GetTypeOf("some_var") == JSON_Undefined);
}

protected static function SubTest_MultipleVariablesGetSet()
{
    local int           i;
    local bool          correctValue, allValuesCorrect;
    local JObject    testJSON;
    testJSON = _().json.newObject();
    Context("Testing how `JObject` handles addition, change and removal" @
            "of relatively large (hundreds) number of variables");
    for (i = 0; i < 2000; i += 1)
    {
        testJSON.SetNumber("num" $ string(i), 4 * i*i - 2.6 * i + 0.75);
    }
    for (i = 0; i < 500; i += 1)
    {
        testJSON.SetString("num" $ string(i), "str" $ string(Sin(i)));
    }
    for (i = 1500; i < 2000; i += 1)
    {
        testJSON.RemoveValue("num" $ string(i));
    }
    allValuesCorrect = true;
    for (i = 0; i < 200; i += 1)
    {
        if (i < 500)
        {
            correctValue = (    testJSON.GetString("num" $ string(i))
                            ==  ("str" $ string(Sin(i))) );
            Issue("Variables are incorrectly overwritten");
        }
        else if(i < 1500)
        {
            correctValue = (    testJSON.GetNumber("num" $ string(i))
                            ==  4 * i*i - 2.6 * i + 0.75);
            Issue("Variables are lost");
        }
        else
        {
            correctValue = (    testJSON.GetTypeOf("num" $ string(i))
                            ==  JSON_Undefined);
            Issue("Variables aren't removed");
        }
        if (!correctValue)
        {
            allValuesCorrect = false;
            break;
        }
    }
    TEST_ExpectTrue(allValuesCorrect);
}

protected static function SubTest_Object()
{
    local JObject testObject;
    Context("Testing setters and getters for folded objects");
    testObject = _().json.newObject();
    testObject.CreateObject("folded");
    testObject.GetObject("folded").CreateObject("folded");
    testObject.SetString("out", "string outside");
    testObject.GetObject("folded").SetNumber("mid", 8);
    testObject.GetObject("folded")
        .GetObject("folded")
        .SetString("in", "string inside");

    Issue("Addressing variables in root object doesn't work");
    TEST_ExpectTrue(testObject.GetString("out", "default") == "string outside");

    Issue("Addressing variables in folded object doesn't work");
    TEST_ExpectTrue(testObject.GetObject("folded").GetNumber("mid", 1) == 8);

    Issue("Addressing plain variables in folded (twice) object doesn't work");
    TEST_ExpectTrue(testObject.GetObject("folded").GetObject("folded")
        .GetString("in", "default") == "string inside");
}

protected static function Test_ObjectKeys()
{
    local int           i;
    local bool          varFound, clsFound, objFound;
    local JObject       testObject;
    local array<string> keys;
    testObject = _().json.newObject();
    Context("Testing getting list of keys from the `JObject`.");
    Issue("Just created `JObject` returns non-empty key list.");
    TEST_ExpectTrue(testObject.GetKeys().length == 0);

    Issue("`JObject` returns incorrect key list.");
    keys = testObject.SetInteger("var", 7).SetClass("cls", class'Actor')
        .CreateObject("obj").GetKeys();
    TEST_ExpectTrue(keys.length == 3);
    for (i = 0; i < keys.length; i += 1)
    {
        if (keys[i] == "var") { varFound = true; }
        if (keys[i] == "cls") { clsFound = true; }
        if (keys[i] == "obj") { objFound = true; }
    }
    TEST_ExpectTrue(varFound && clsFound && objFound);

    Issue("`JObject` returns incorrect key list after removing an element.");
    keys = testObject.RemoveValue("cls").GetKeys();
    TEST_ExpectTrue(keys.length == 2);
    varFound = false;
    objFound = false;
    for (i = 0; i < keys.length; i += 1)
    {
        if (keys[i] == "var") { varFound = true; }
        if (keys[i] == "obj") { objFound = true; }
    }
    TEST_ExpectTrue(varFound && objFound);

    Issue("`JObject` returns incorrect key list after removing all elements.");
    keys = testObject.RemoveValue("var").RemoveValue("obj").GetKeys();
    TEST_ExpectTrue(keys.length == 0);
}

protected static function SubTest_ArrayUndefined()
{
    local JArray testJSON;
    testJSON = _().json.newArray();
    Context("Testing how `JArray` handles undefined values");
    Issue("Undefined variable doesn't have `JSON_Undefined` type");
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_Undefined);

    Issue("There is a variable in an empty object after `GetTypeOf` call");
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_Undefined);

    Issue("Negative index refers to a defined value");
    TEST_ExpectTrue(testJSON.GetTypeOf(-1) == JSON_Undefined);

    Issue("Getters don't return default values for undefined variables");
    TEST_ExpectTrue(testJSON.GetNumber(0, 0) == 0);
    TEST_ExpectTrue(testJSON.GetString(0, "") == "");
    TEST_ExpectTrue(testJSON.GetBoolean(0, false) == false);
    TEST_ExpectNone(testJSON.GetObject(0));
    TEST_ExpectNone(testJSON.GetArray(0));

    Issue(  "Getters don't return user-defined default values for" @
            "undefined variables");
    TEST_ExpectTrue(testJSON.GetNumber(0, 10) == 10);
    TEST_ExpectTrue(testJSON.GetString(0, "test") == "test");
    TEST_ExpectTrue(testJSON.GetBoolean(0, true) == true);
}

protected static function SubTest_ArrayBooleanGetSetRemove()
{
    local JArray testJSON;
    testJSON = _().json.newArray();
    testJSON.SetBoolean(0, true);

    Context("Testing `JArray`'s get/set/remove functions for" @
            "boolean variables");
    Issue("Boolean type isn't properly set by `SetBoolean`");
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_Boolean);

    Issue("Value is incorrectly assigned by `SetBoolean`");
    TEST_ExpectTrue(testJSON.GetBoolean(0) == true);
    testJSON.SetBoolean(0, false);

    Issue("Variable value isn't correctly reassigned by `SetBoolean`");
    TEST_ExpectTrue(testJSON.GetBoolean(0) == false);

    Issue(  "Getting boolean variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetNumber(0, 7) == 7);

    Issue("Boolean variable isn't being properly removed");
    testJSON.RemoveValue(0);
    TEST_ExpectTrue( testJSON.GetTypeOf(0) == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored boolean value, but got removed");
    TEST_ExpectTrue(testJSON.GetBoolean(0, true) == true);
}

protected static function SubTest_ArrayStringGetSetRemove()
{
    local JArray testJSON;
    testJSON = _().json.newArray();
    testJSON.SetString(0, "first string");

    Context("Testing `JArray`'s get/set/remove functions for" @
            "string variables");
    Issue("String type isn't properly set by `SetString`");
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_String);

    Issue("Value is incorrectly assigned by `SetString`");
    TEST_ExpectTrue(testJSON.GetString(0) == "first string");

    Issue(  "Providing default variable value makes 'GetString'" @
            "return incorrect value");
    TEST_ExpectTrue(testJSON.GetString(0, "alternative") == "first string");

    Issue("Variable value isn't correctly reassigned by `SetString`");
    testJSON.SetString(0, "new string!~");
    TEST_ExpectTrue(testJSON.GetString(0) == "new string!~");

    Issue(  "Getting string variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetBoolean(0, true) == true);

    Issue("Boolean variable isn't being properly removed");
    testJSON.RemoveValue(0);
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored string value, but got removed");
    TEST_ExpectTrue(testJSON.GetString(0, "other") == "other");
}

protected static function SubTest_ArrayClassGetSetRemove()
{
    local JArray testJSON;
    testJSON = _().json.newArray();
    testJSON.SetClass(0, class'Actor');

    Context("Testing `JArray`'s get/set/remove functions for" @
            "class variables");
    Issue("Class type isn't properly set by `SetClass`");
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_String);

    Issue("Value is incorrectly assigned by `SetClass`");
    TEST_ExpectTrue(testJSON.GetClass(0) == class'Actor');

    Issue(  "Providing default variable value makes `GetClass`" @
            "return incorrect value");
    TEST_ExpectTrue(testJSON.GetClass(0, class'GameInfo') == class'Actor');

    Issue("Variable value isn't correctly reassigned by `SetClass`");
    testJSON.SetClass(0, class'Info');
    TEST_ExpectTrue(testJSON.GetClass(0) == class'Info');

    Issue(  "Getting class variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetBoolean(0, true) == true);

    Issue("Boolean variable isn't being properly removed");
    testJSON.RemoveValue(0);
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored string value, but got removed");
    TEST_ExpectTrue(testJSON.GetClass(0, class'Mutator') == class'Mutator');
}

protected static function SubTest_ArrayStringAsClass()
{
    local JArray testJSON;
    testJSON = _().json.NewArray();
    testJSON.SetString(0, "Engine.Actor");
    testJSON.AddString("blahblahblah");
    testJSON.AddClass(class'Info');
    testJSON.SetClass(3, none);

    Context("Testing how `JArray` treats mixed string and"
        @ "class setters/getters.");
    Issue("Incorrect result of `SetClass().GetString()` sequence.");
    TEST_ExpectTrue(testJSON.GetString(2) == "Engine.Info");
    TEST_ExpectTrue(testJSON.GetString(3) == "None");
    TEST_ExpectTrue(testJSON.GetString(3, "alternative") == "None");

    Issue("Incorrect result of `SetString().GetClass()` sequence for"
        @ "correct value in `SetString()`.");
    TEST_ExpectTrue(testJSON.GetClass(0) == class'Actor');
    TEST_ExpectTrue(testJSON.GetClass(0, class'Object') ==  class'Actor');

    Issue("Incorrect result of `SetString().GetClass()` sequence for"
        @ "incorrect value in `SetString()`.");
    TEST_ExpectTrue(testJSON.GetClass(1) == none);
    TEST_ExpectTrue(testJSON.GetClass(1, class'Object') ==  class'Object');
}

protected static function SubTest_ArrayNumberGetSetRemove()
{
    local JArray testJSON;
    testJSON = _().json.newArray();
    testJSON.SetNumber(0, 3.5);

    Context("Testing `JArray`'s get/set/remove functions for" @
            "number variables");
    Issue("Number type isn't properly set by `SetNumber`");
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_Number);

    Issue("Value is incorrectly assigned by `SetNumber`");
    TEST_ExpectTrue(testJSON.GetNumber(0) == 3.5);

    Issue(  "Providing default variable value makes 'GetNumber'" @
            "return incorrect value");
    TEST_ExpectTrue(testJSON.GetNumber(0, 5) == 3.5);

    Issue("Variable value isn't correctly reassigned by `SetNumber`");
    testJSON.SetNumber(0, 7);
    TEST_ExpectTrue(testJSON.GetNumber(0) == 7);

    Issue(  "Getting number variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetString(0, "default") == "default");

    Issue("Number type isn't being properly removed");
    testJSON.RemoveValue(0);
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored number value, but got removed");
    TEST_ExpectTrue(testJSON.GetNumber(0, 13) == 13);
}

protected static function SubTest_ArrayIntegerGetSetRemove()
{
    local JArray testJSON;
    testJSON = _().json.newArray();
    testJSON.SetInteger(0, 19);

    Context("Testing `JArray`'s get/set/remove functions for" @
            "integer variables");
    Issue("Integer type isn't properly set by `SetInteger`");
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_Number);

    Issue("Value is incorrectly assigned by `SetInteger`");
    TEST_ExpectTrue(testJSON.GetInteger(0) == 19);

    Issue(  "Providing default variable value makes `GetInteger`" @
            "return incorrect value");
    TEST_ExpectTrue(testJSON.GetInteger(0, 5) == 19);

    Issue("Variable value isn't correctly reassigned by `SetInteger`");
    testJSON.SetInteger(0, MaxInt);
    TEST_ExpectTrue(testJSON.GetInteger(0) == MaxInt);

    Issue(  "Getting integer variable as a wrong type" @
            "doesn't yield default value");
    TEST_ExpectTrue(testJSON.GetString(0, "default") == "default");

    Issue("Integer type isn't being properly removed");
    testJSON.RemoveValue(0);
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_Undefined);

    Issue(  "Getters don't return default value for missing key that" @
            "previously stored integer value, but got removed");
    TEST_ExpectTrue(testJSON.GetInteger(0, 13) == 13);
}

protected static function SubTest_ArrayFloatAndInteger()
{
    local JArray testJSON;
    testJSON = _().json.NewArray();
    testJSON.SetNumber(0, 6.70087);

    Context("Testing how `JArray` treats mixed float and"
        @ "integer setters/getters.");
    Issue("Incorrect result of `SetNumber().GetInteger()` sequence.");
    TEST_ExpectTrue(testJSON.GetInteger(0) == 6);

    testJSON.SetInteger(0, 11);
    testJSON.SetNumber(1, 0.43);
    Issue("SetNumber().SetInteger() for same variable name does not overwrite"
        @ "initial number value.");
    TEST_ExpectTrue(testJSON.GetNumber(0) == 11);

    Issue("SetInteger().SetNumber() for same variable name does not overwrite"
        @ "initial integer value.");
    TEST_ExpectTrue(testJSON.GetInteger(1) == 0);
}

protected static function SubTest_ArrayNullGetSetRemove()
{
    local JArray testJSON;
    testJSON = _().json.newArray();

    Context("Testing `JArray`'s get/set/remove functions for" @
            "null values");
    
    Issue("Undefined variable is incorrectly considered `null`");
    TEST_ExpectFalse(testJSON.IsNull(0));
    TEST_ExpectFalse(testJSON.IsNull(2));
    TEST_ExpectFalse(testJSON.IsNull(-1));

    Issue("Number variable is incorrectly considered `null`");
    testJSON.SetNumber(0, 4);
    TEST_ExpectFalse(testJSON.IsNull(0));

    Issue("Boolean variable is incorrectly considered `null`");
    testJSON.SetBoolean(0, true);
    TEST_ExpectFalse(testJSON.IsNull(0));
    
    Issue("String variable is incorrectly considered `null`");
    testJSON.SetString(0, "string");
    TEST_ExpectFalse(testJSON.IsNull(0));

    Issue("Null value is incorrectly assigned");
    testJSON.SetNull(0);
    TEST_ExpectTrue(testJSON.IsNull(0));

    Issue("Null type isn't properly set by `SetNumber`");
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_Null);

    Issue("Null value isn't being properly removed");
    testJSON.RemoveValue(0);
    TEST_ExpectTrue(testJSON.GetTypeOf(0) == JSON_Undefined);
}

//  Returns following array:
//  [10.0, "test string", "another string", true, 0.0, {"var": 7.0}]
protected static function JArray Prepare_Array()
{
    local JArray testArray;
    testArray = _().json.newArray();
    testArray.AddNumber(10.0f)
        .AddString("test string")
        .AddString("another string")
        .AddBoolean(true)
        .AddNumber(0.0f)
        .AddObject();
    testArray.GetObject(5).SetNumber("var", 7);
    return testArray;
}

protected static function SubTest_ArrayMultipleVariablesStorage()
{
    local JArray testArray;
    testArray = Prepare_Array();

    Context("Testing how `JArray` handles adding and" @
            "changing several variables");
    Issue("Stored values are compromised.");
    TEST_ExpectTrue(testArray.GetNumber(0) == 10.0f);
    TEST_ExpectTrue(testArray.GetString(1) == "test string");
    TEST_ExpectTrue(testArray.GetString(2) == "another string");
    TEST_ExpectTrue(testArray.GetBoolean(3) == true);
    TEST_ExpectTrue(testArray.GetNumber(4) == 0.0f);
    TEST_ExpectTrue(testArray.GetObject(5).GetNumber("var") == 7);

    Issue("Values incorrectly change their values.");
    testArray.SetString(3, "new string");
    TEST_ExpectTrue(testArray.GetString(3) == "new string");

    Issue(  "After overwriting boolean value with a different type," @
            "attempting go get it as a boolean gives old value," @
            "instead of default");
    TEST_ExpectTrue(testArray.GetBoolean(3, false) == false);

    Issue("Type of the variable is incorrectly changed.");
    TEST_ExpectTrue(testArray.GetTypeOf(3) == JSON_String);
}

protected static function SubTest_ArrayMultipleVariablesRemoval()
{
    local JArray testArray;
    testArray = Prepare_Array();
    //  Test removing variables
    //  After `Prepare_Array`, our array should be:
    //  [10.0, "test string", "another string", true, 0.0, {"var": 7.0}]

    Context("Testing how `JArray` handles adding and" @
            "removing several variables");
    Issue("Values are incorrectly removed");
    testArray.RemoveValue(2);
    //  [10.0, "test string", true, 0.0, {"var": 7.0}]
    Issue("Values are incorrectly removed");
    TEST_ExpectTrue(testArray.GetNumber(0) == 10.0);
    TEST_ExpectTrue(testArray.GetString(1) == "test string");
    TEST_ExpectTrue(testArray.GetBoolean(2) == true);
    TEST_ExpectTrue(testArray.GetNumber(3) == 0.0f);
    TEST_ExpectTrue(testArray.GetTypeOf(4) == JSON_Object);

    Issue("First element incorrectly removed");
    testArray.RemoveValue(0);
    //  ["test string", true, 0.0, {"var": 7.0}]
    TEST_ExpectTrue(testArray.GetString(0) == "test string");
    TEST_ExpectTrue(testArray.GetBoolean(1) == true);
    TEST_ExpectTrue(testArray.GetNumber(2) == 0.0f);
    TEST_ExpectTrue(testArray.GetTypeOf(3) == JSON_Object);
    TEST_ExpectTrue(testArray.GetObject(3).GetNumber("var") == 7.0);

    Issue("Last element incorrectly removed");
    testArray.RemoveValue(3);
    //  ["test string", true, 0.0]
    TEST_ExpectTrue(testArray.GetLength() == 3);
    TEST_ExpectTrue(testArray.GetString(0) == "test string");
    TEST_ExpectTrue(testArray.GetBoolean(1) == true);
    TEST_ExpectTrue(testArray.GetNumber(2) == 0.0f);

    Issue("Removing all elements is handled incorrectly");
    testArray.RemoveValue(0);
    testArray.RemoveValue(0);
    testArray.RemoveValue(0);
    TEST_ExpectTrue(testArray.Getlength() == 0);
    TEST_ExpectTrue(testArray.GetTypeOf(0) == JSON_Undefined);
}

protected static function SubTest_ArrayRemovingMultipleVariablesAtOnce()
{
    local JArray testArray;
    testArray = _().json.newArray();
    testArray.AddNumber(10.0f)
        .AddString("test string")
        .AddString("another string")
        .AddNumber(7.0);

    Context("Testing how `JArray`' handles removing" @
            "multiple elements at once");
    Issue("Multiple values are incorrectly removed");
    testArray.RemoveValue(1, 2);
    TEST_ExpectTrue(testArray.GetLength() == 2);
    TEST_ExpectTrue(testArray.GetNumber(1) == 7.0);

    testArray.AddNumber(4.0f)
        .AddString("test string")
        .AddString("another string")
        .AddNumber(8.0);

    //  Current array:
    //  [10.0, 7.0, 4.0, "test string", "another string", 8.0]
    Issue("Last value is incorrectly removed");
    testArray.RemoveValue(5, 1);
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetString(4) == "another string");

    //  Current array:
    //  [10.0, 7.0, 4.0, "test string", "another string"]
    Issue("Tail elements are incorrectly removed");
    testArray.RemoveValue(3, 4);
    TEST_ExpectTrue(testArray.GetLength() == 3);
    TEST_ExpectTrue(testArray.GetNumber(0) == 10.0);
    TEST_ExpectTrue(testArray.GetNumber(2) == 4.0);

    Issue("Array empties incorrectly");
    testArray.RemoveValue(0, testArray.GetLength());
    TEST_ExpectTrue(testArray.GetLength() == 0);
    TEST_ExpectTrue(testArray.GetTypeOf(0) == JSON_Undefined);
    TEST_ExpectTrue(testArray.GetTypeOf(1) == JSON_Undefined);
}

protected static function SubTest_ArrayExpansions()
{
    local JArray testArray;
    testArray = _().json.newArray();

    Context("Testing how `JArray`' handles expansions/shrinking " @
            "via `SetLength()`");
    Issue("`SetLength()` doesn't properly expand empty array");
    testArray.SetLength(2);
    TEST_ExpectTrue(testArray.GetLength() == 2);
    TEST_ExpectTrue(testArray.GetTypeOf(0) == JSON_Null);
    TEST_ExpectTrue(testArray.GetTypeOf(1) == JSON_Null);

    Issue("`SetLength()` doesn't properly expand non-empty array");
    testArray.AddNumber(1);
    testArray.SetLength(4);
    TEST_ExpectTrue(testArray.GetLength() == 4);
    TEST_ExpectTrue(testArray.GetTypeOf(0) == JSON_Null);
    TEST_ExpectTrue(testArray.GetTypeOf(1) == JSON_Null);
    TEST_ExpectTrue(testArray.GetTypeOf(2) == JSON_Number);
    TEST_ExpectTrue(testArray.GetTypeOf(3) == JSON_Null);
    TEST_ExpectTrue(testArray.GetNumber(2) == 1);
    SubSubTest_ArraySetNumberExpansions();
    SubSubTest_ArraySetStringExpansions();
    SubSubTest_ArraySetBooleanExpansions();
}

protected static function SubSubTest_ArraySetNumberExpansions()
{
    local JArray testArray;
    testArray = _().json.newArray();

    Context("Testing how `JArray`' handles expansions via" @
            "`SetNumber()` function");
    Issue("Setters don't create correct first element");
    testArray.SetNumber(0, 1);
    TEST_ExpectTrue(testArray.GetLength() == 1);
    TEST_ExpectTrue(testArray.GetNumber(0) == 1);

    Issue(  "`SetNumber()` doesn't properly define array when setting" @
            "value out-of-bounds");
    testArray = _().json.newArray();
    testArray.AddNumber(1);
    testArray.SetNumber(4, 2);
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetNumber(0) == 1);
    TEST_ExpectTrue(testArray.GetTypeOf(1) == JSON_Null);
    TEST_ExpectTrue(testArray.GetTypeOf(2) == JSON_Null);
    TEST_ExpectTrue(testArray.GetTypeOf(3) == JSON_Null);
    TEST_ExpectTrue(testArray.GetNumber(4) == 2);

    Issue("`SetNumber()` expands array even when it told not to");
    testArray.SetNumber(6, 7, true);
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetNumber(6) == 0);
    TEST_ExpectTrue(testArray.GetTypeOf(5) == JSON_Undefined);
    TEST_ExpectTrue(testArray.GetTypeOf(6) == JSON_Undefined);
}

protected static function SubSubTest_ArraySetStringExpansions()
{
    local JArray testArray;
    testArray = _().json.newArray();

    Context("Testing how `JArray`' handles expansions via" @
            "`SetString()` function");
    Issue("Setters don't create correct first element");
    testArray.SetString(0, "str");
    TEST_ExpectTrue(testArray.GetLength() == 1);
    TEST_ExpectTrue(testArray.GetString(0) == "str");

    Issue(  "`SetString()` doesn't properly define array when setting" @
            "value out-of-bounds");
    testArray = _().json.newArray();
    testArray.AddString("str");
    testArray.SetString(4, "str2");
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetString(0) == "str");
    TEST_ExpectTrue(testArray.GetTypeOf(1) == JSON_Null);
    TEST_ExpectTrue(testArray.GetTypeOf(2) == JSON_Null);
    TEST_ExpectTrue(testArray.GetTypeOf(3) == JSON_Null);
    TEST_ExpectTrue(testArray.GetString(4) == "str2");

    Issue("`SetString()` expands array even when it told not to");
    testArray.SetString(6, "new string", true);
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetString(6) == "");
    TEST_ExpectTrue(testArray.GetTypeOf(5) == JSON_Undefined);
    TEST_ExpectTrue(testArray.GetTypeOf(6) == JSON_Undefined);
}

protected static function SubSubTest_ArraySetBooleanExpansions()
{
    local JArray testArray;
    testArray = _().json.newArray();

    Context("Testing how `JArray`' handles expansions via" @
            "`SetBoolean()` function");
    Issue("Setters don't create correct first element");
    testArray.SetBoolean(0, false);
    TEST_ExpectTrue(testArray.GetLength() == 1);
    TEST_ExpectTrue(testArray.GetBoolean(0) == false);

    Issue(  "`SetBoolean()` doesn't properly define array when setting" @
            "value out-of-bounds");
    testArray = _().json.newArray();
    testArray.AddBoolean(true);
    testArray.SetBoolean(4, true);
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetBoolean(0) == true);
    TEST_ExpectTrue(testArray.GetTypeOf(1) == JSON_Null);
    TEST_ExpectTrue(testArray.GetTypeOf(2) == JSON_Null);
    TEST_ExpectTrue(testArray.GetTypeOf(3) == JSON_Null);
    TEST_ExpectTrue(testArray.GetBoolean(4) == true);

    Issue("`SetBoolean()` expands array even when it told not to");
    testArray.SetBoolean(6, true, true);
    TEST_ExpectTrue(testArray.GetLength() == 5);
    TEST_ExpectTrue(testArray.GetBoolean(6) == false);
    TEST_ExpectTrue(testArray.GetTypeOf(5) == JSON_Undefined);
    TEST_ExpectTrue(testArray.GetTypeOf(6) == JSON_Undefined);
}

protected static function JObject Prepare_FoldedObject()
{
    local JObject testObject;
    testObject = _().json.NewObject();
    testObject.SetNumber("some_var", -7.32);
    testObject.SetString("another_var", "aye!");
    testObject.CreateObject("innerObject");
    testObject.GetObject("innerObject").SetBoolean("my_bool", true)
        .SetInteger("my_int", -9823452).CreateArray("array");
    testObject.GetObject("innerObject").GetArray("array").AddClass(class'Actor')
        .AddBoolean(false).AddNull().AddObject().AddNumber(56.6);
    testObject.GetObject("innerObject").GetArray("array").GetObject(3)
        .SetString("something here", "yes").SetNumber("maybe", 0.003);
    testObject.GetObject("innerObject").CreateObject("one more");
    testObject.GetObject("innerObject").GetObject("one more")
        .SetString("o rly?", "ya rly").SetBoolean("whatever", false)
        .SetNumber("nope", 324532);
    return testObject;
}

protected static function Test_JSONComparison()
{
    Context("Testing comparison of JSON objects");
    SubTest_JSONIsEqual();
    SubTest_JSONIsSubsetOf();
    SubTest_JSONCompare();
}

protected static function SubTest_JSONIsEqual()
{
    local JObject test1, test2, empty;
    test1 = Prepare_FoldedObject();
    test2 = Prepare_FoldedObject();
    empty = _().json.NewObject();

    Issue("`IsEqual()` does not recognize identical JSON objects as equal.");
    TEST_ExpectTrue(test1.IsEqual(test1));
    TEST_ExpectTrue(test1.IsEqual(test2));
    TEST_ExpectTrue(empty.IsEqual(empty));

    Issue("`IsEqual()` reports non-empty JSON object as equal to"
        @ "an empty one.");
    TEST_ExpectFalse(test1.IsEqual(empty));

    Issue("`IsEqual()` reports JSON objects with identical variable names,"
        @ "but different values as equal.");
    test2.GetObject("innerObject").GetObject("one more").SetNumber("nope", 2);
    TEST_ExpectFalse(test1.IsEqual(test2));
    test2 = Prepare_FoldedObject();
    test2.GetObject("innerObject").GetArray("array").SetBoolean(1, true);
    TEST_ExpectFalse(test1.IsEqual(test2));

    Issue("`IsEqual()` reports JSON objects with different"
        @ "structure as equal.");
    test2 = Prepare_FoldedObject();
    test2.GetObject("innerObject").SetNumber("ahaha", 8);
    TEST_ExpectFalse(test1.IsEqual(test2));
    test2 = Prepare_FoldedObject();
    test2.GetObject("innerObject").GetArray("array").AddNull();
    TEST_ExpectFalse(test1.IsEqual(test2));
}

protected static function SubTest_JSONIsSubsetOf()
{
    local JObject test1, test2, empty;
    test1 = Prepare_FoldedObject();
    test2 = Prepare_FoldedObject();
    empty = _().json.NewObject();

    Issue("`IsSubsetOf()` incorrectly handles equal objects.");
    TEST_ExpectTrue(test1.IsSubsetOf(test1));
    TEST_ExpectTrue(test1.IsSubsetOf(test2));
    TEST_ExpectTrue(empty.IsSubsetOf(empty));

    Issue("`IsSubsetOf()` incorrectly handles object subsets.");
    test1.SetNumber("Garage", 234);
    TEST_ExpectTrue(test2.IsSubsetOf(test1));
    TEST_ExpectFalse(test1.IsSubsetOf(test2));
    TEST_ExpectTrue(empty.IsSubsetOf(test1));
    TEST_ExpectFalse(test1.IsSubsetOf(empty));

    Issue("`IsSubsetOf()` incorrectly handles objects that cannot be compared.");
    test2.GetObject("innerObject").GetArray("array").SetNull(1);
    TEST_ExpectFalse(test1.IsSubsetOf(test2));
    TEST_ExpectFalse(test2.IsSubsetOf(test1));
}

protected static function SubTest_JSONCompare()
{
    local JObject test1, test2, empty;
    test1 = Prepare_FoldedObject();
    test2 = Prepare_FoldedObject();
    empty = _().json.NewObject();

    Issue("`Compare()` incorrectly handles equal objects.");
    TEST_ExpectTrue(test1.Compare(test1) == JCR_Equal);
    TEST_ExpectTrue(test1.Compare(test2) == JCR_Equal);
    TEST_ExpectTrue(empty.Compare(empty) == JCR_Equal);

    Issue("`Compare()` incorrectly handles object subsets.");
    test1.SetNumber("Garage", 234);
    TEST_ExpectTrue(test2.Compare(test1) == JCR_SubSet);
    TEST_ExpectTrue(test1.Compare(test2) == JCR_Overset);
    TEST_ExpectTrue(empty.Compare(test1) == JCR_SubSet);
    TEST_ExpectTrue(test1.Compare(empty) == JCR_Overset);

    Issue("`Compare()` incorrectly handles objects that cannot be compared.");
    test2.GetObject("innerObject").GetArray("array").AddNull();
    TEST_ExpectTrue(test1.Compare(test2) == JCR_Incomparable);
    TEST_ExpectTrue(test2.Compare(test1) == JCR_Incomparable);
}

protected static function Test_JSONCloning()
{
    local JObject original, clone;
    original = Prepare_FoldedObject();
    clone = JObject(original.Clone());
    Context("Testing cloning functionality of JSON data.");
    Issue("JSON data is cloned incorrectly.");
    TEST_ExpectTrue(original.IsEqual(clone));

    Issue("`Clone()` produces only a shallow copy.");
    TEST_ExpectTrue(original != clone);
    TEST_ExpectTrue(    original.GetObject("innerObject")
                    !=  clone.GetObject("innerObject"));
    TEST_ExpectTrue(    original.GetObject("innerObject").GetArray("array")
                    !=  clone.GetObject("innerObject").GetArray("array"));
    TEST_ExpectTrue(    original.GetObject("innerObject").GetObject("one more")
                    !=  clone.GetObject("innerObject").GetObject("one more"));
    TEST_ExpectTrue(
            original.GetObject("innerObject").GetArray("array").GetObject(3)
        !=  clone.GetObject("innerObject").GetArray("array").GetObject(3));
}

protected static function Test_JSONSetComplexValues()
{
    local JObject   testObject, original;
    local JArray    testArray;
    Context("Testing `Set...()` operation for `JObject` / `JArray`.");
    original = Prepare_FoldedObject();
    testObject = Prepare_FoldedObject();
    testArray =
        JArray(testObject.GetObject("innerObject").GetArray("array").Clone());
    testObject.SetObject("newObjectCopy", testObject);
    testObject.SetArray("newArrayCopy", testArray);
    testArray.SetObject(0, testObject);
    testArray.SetArray(1, testArray);
    Issue("`Set() for `JObject` / `JArray` does not produce correct copy.");
    Test_ExpectTrue(testObject.GetObject("newObjectCopy").IsEqual(original));
    Test_ExpectTrue(testObject.GetArray("newArrayCopy")
        .IsEqual(original.GetObject("innerObject").GetArray("array")));
    Test_ExpectTrue(testArray.GetObject(0).IsEqual(testObject));

    Issue("`Set() for `JObject` / `JArray` produces a shallow copy.");
    Test_ExpectTrue(testObject.GetObject("newObjectCopy") != original);
    Test_ExpectTrue(    testObject.GetObject("newArrayCopy")
                    !=  original.GetObject("innerObject").GetArray("array"));
    Test_ExpectTrue(testArray.GetObject(0) != original);
    Test_ExpectTrue(    testArray.GetArray(1)
                    !=  original.GetObject("innerObject").GetArray("array"));
}

protected static function Test_JSONParsing()
{
    Context("Testing parsing JSON data.");
    SubTest_JSONObjectParsingWithParser();
    SubTest_JSONArrayParsingWithParser();
    SubTest_JSONObjectParsingText();
    SubTest_JSONArrayParsingText();
    SubTest_JSONObjectParsingRaw();
    SubTest_JSONArrayParsingRaw();
    SubTest_JSONObjectParsingString();
    SubTest_JSONArrayParsingString();

    Issue("Complex JSON object is incorrectly parsed.");
    Test_ExpectTrue(Prepare_FoldedObject().IsEqual(_().json.ParseObjectWith(
        _().text.ParseString(default.preparedJObjectString))));
    Test_ExpectTrue(Prepare_FoldedObject().IsEqual(_().json.ParseObject(
        _().text.FromString(default.preparedJObjectString))));
    Test_ExpectTrue(Prepare_FoldedObject().IsEqual(_().json.ParseObjectRaw(
        _().text.StringToRaw(default.preparedJObjectString))));
    Test_ExpectTrue(Prepare_FoldedObject().IsEqual(
        _().json.ParseObjectString(default.preparedJObjectString)));
}

protected static function SubTest_JSONObjectParsingWithParser()
{
    local JObject parsedObject;
    Issue("`ParseObjectWith()` cannot parse empty JSON object.");
    parsedObject = _().json.ParseObjectWith(_().text.ParseString("{}"));
    TEST_ExpectNotNone(parsedObject);
    TEST_ExpectTrue(parsedObject.GetKeys().length == 0);

    Issue("`ParseObjectWith()` doesn't report error when parsing an incorrect"
        @ "object.");
    parsedObject = _().json.ParseObjectWith(_().text.ParseString("{}"));
    TEST_ExpectNone(_().json.ParseObjectWith(_().text.ParseString("")));
    TEST_ExpectNone(_().json.ParseObjectWith(
        _().text.ParseString("{\"var\": 89")));
    TEST_ExpectNone(_().json.ParseObjectWith(
        _().text.ParseString("\"var\": 89}")));
    TEST_ExpectNone(_().json.ParseObjectWith(
        _().text.ParseString("{var:false}")));

    Issue("`ParseObjectWith()` cannot parse simple JSON object.");
    parsedObject = _().json.ParseObjectWith(
        _().text.ParseString("{\"var\":7 ,\"str\":\"aye!~\"}"));
    TEST_ExpectNotNone(parsedObject);
    TEST_ExpectTrue(parsedObject.GetNumber("var") == 7);
    TEST_ExpectTrue(parsedObject.GetString("str") == "aye!~");

    Issue("`JObject.ParseIntoSelfWith()` cannot add new properties.");
    TEST_ExpectTrue(parsedObject.ParseIntoSelfWith(
        _().text.ParseString("{\"newVar\": true}")));
    TEST_ExpectTrue(parsedObject.GetBoolean("newVar"));
}

protected static function SubTest_JSONArrayParsingWithParser()
{
    local JArray parsedArray;
    Issue("`ParseArrayWith()` cannot parse empty JSON array.");
    parsedArray = _().json.ParseArrayWith(_().text.ParseString("[]"));
    TEST_ExpectNotNone(parsedArray);
    TEST_ExpectTrue(parsedArray.GetLength() == 0);

    Issue("`ParseArrayWith()` doesn't report error when parsing an incorrect"
        @ "object.");
    parsedArray = _().json.ParseArrayWith(_().text.ParseString("[]"));
    TEST_ExpectNone(_().json.ParseArrayWith(_().text.ParseString("")));
    TEST_ExpectNone(_().json.ParseArrayWith(_().text.ParseString("[89")));
    TEST_ExpectNone(_().json.ParseArrayWith(_().text.ParseString("89]")));
    TEST_ExpectNone(_().json.ParseArrayWith(
        _().text.ParseString("[false null]")));

    Issue("`ParseArrayWith()` cannot parse simple JSON array.");
    parsedArray = _().json.ParseArrayWith(
        _().text.ParseString("[null, 67.349e2, \"what\"  , {}]"));
    TEST_ExpectNotNone(parsedArray);
    TEST_ExpectTrue(parsedArray.IsNull(0));
    TEST_ExpectTrue(parsedArray.GetNumber(1) == 6734.9);
    TEST_ExpectTrue(parsedArray.GetString(2) == "what");
    TEST_ExpectTrue(parsedArray.GetObject(3).GetKeys().length == 0);

    Issue("`JArray.ParseIntoSelfWith()` cannot add new elements.");
    TEST_ExpectTrue(parsedArray.ParseIntoSelfWith(
        _().text.ParseString("[\"huh\", Null]")));
    TEST_ExpectTrue(parsedArray.GetString(4) == "huh");
    TEST_ExpectTrue(parsedArray.IsNull(5));
}

protected static function SubTest_JSONObjectParsingText()
{
    local JObject parsedObject;
    Issue("`ParseObject()` cannot parse empty JSON object.");
    parsedObject = _().json.ParseObject(_().text.FromString("{}"));
    TEST_ExpectNotNone(parsedObject);
    TEST_ExpectTrue(parsedObject.GetKeys().length == 0);

    Issue("`ParseObject()` doesn't report error when parsing an incorrect"
        @ "object.");
    parsedObject = _().json.ParseObject(_().text.FromString("{}"));
    TEST_ExpectNone(_().json.ParseObject(_().text.FromString("")));
    TEST_ExpectNone(_().json.ParseObject(_().text.FromString("{\"var\": 89")));
    TEST_ExpectNone(_().json.ParseObject(_().text.FromString("\"var\": 89}")));
    TEST_ExpectNone(_().json.ParseObject(_().text.FromString("{var:false}")));

    Issue("`ParseObject()` cannot parse simple JSON object.");
    parsedObject = _().json.ParseObject(
        _().text.FromString("{\"var\":7 ,\"str\":\"aye!~\"}"));
    TEST_ExpectNotNone(parsedObject);
    TEST_ExpectTrue(parsedObject.GetNumber("var") == 7);
    TEST_ExpectTrue(parsedObject.GetString("str") == "aye!~");

    Issue("`JObject.ParseIntoSelf()` cannot add new properties.");
    TEST_ExpectTrue(parsedObject.ParseIntoSelf(
        _().text.FromString("{\"newVar\": true}")));
    TEST_ExpectTrue(parsedObject.GetBoolean("newVar"));
}

protected static function SubTest_JSONArrayParsingText()
{
    local JArray parsedArray;
    Issue("`ParseArray()` cannot parse empty JSON array.");
    parsedArray = _().json.ParseArray(_().text.FromString("[]"));
    TEST_ExpectNotNone(parsedArray);
    TEST_ExpectTrue(parsedArray.GetLength() == 0);

    Issue("`ParseArray()` doesn't report error when parsing an incorrect"
        @ "object.");
    parsedArray = _().json.ParseArray(_().text.FromString("[]"));
    TEST_ExpectNone(_().json.ParseArray(_().text.FromString("")));
    TEST_ExpectNone(_().json.ParseArray(_().text.FromString("[89")));
    TEST_ExpectNone(_().json.ParseArray(_().text.FromString("89]")));
    TEST_ExpectNone(_().json.ParseArray(_().text.FromString("[false null]")));

    Issue("`ParseArray()` cannot parse simple JSON array.");
    parsedArray = _().json.ParseArray(
        _().text.FromString("[null, 67.349e2, \"what\"  , {}]"));
    TEST_ExpectNotNone(parsedArray);
    TEST_ExpectTrue(parsedArray.IsNull(0));
    TEST_ExpectTrue(parsedArray.GetNumber(1) == 6734.9);
    TEST_ExpectTrue(parsedArray.GetString(2) == "what");
    TEST_ExpectTrue(parsedArray.GetObject(3).GetKeys().length == 0);

    Issue("`JArray.ParseIntoSelf()` cannot add new elements.");
    TEST_ExpectTrue(parsedArray.ParseIntoSelf(
        _().text.FromString("[\"huh\", Null]")));
    TEST_ExpectTrue(parsedArray.GetString(4) == "huh");
    TEST_ExpectTrue(parsedArray.IsNull(5));
}

protected static function SubTest_JSONObjectParsingRaw()
{
    local JObject parsedObject;
    Issue("`ParseObjectRaw()` cannot parse empty JSON object.");
    parsedObject = _().json.ParseObjectRaw(_().text.StringToRaw("{}"));
    TEST_ExpectNotNone(parsedObject);
    TEST_ExpectTrue(parsedObject.GetKeys().length == 0);

    Issue("`ParseObjectRaw()` doesn't report error when parsing an incorrect"
        @ "object.");
    parsedObject = _().json.ParseObjectRaw(_().text.StringToRaw("{}"));
    TEST_ExpectNone(_().json.ParseObjectRaw(_().text.StringToRaw("")));
    TEST_ExpectNone(_().json.ParseObjectRaw(
        _().text.StringToRaw("{\"var\": 89")));
    TEST_ExpectNone(_().json.ParseObjectRaw(
        _().text.StringToRaw("\"var\": 89}")));
    TEST_ExpectNone(_().json.ParseObjectRaw(
        _().text.StringToRaw("{var:false}")));

    Issue("`ParseObjectRaw()` cannot parse simple JSON object.");
    parsedObject = _().json.ParseObjectRaw(
        _().text.StringToRaw("{\"var\":7 ,\"str\":\"aye!~\"}"));
    TEST_ExpectNotNone(parsedObject);
    TEST_ExpectTrue(parsedObject.GetNumber("var") == 7);
    TEST_ExpectTrue(parsedObject.GetString("str") == "aye!~");

    Issue("`JObject.ParseIntoSelfRaw()` cannot add new properties.");
    TEST_ExpectTrue(parsedObject.ParseIntoSelfRaw(
        _().text.StringToRaw("{\"newVar\": true}")));
    TEST_ExpectTrue(parsedObject.GetBoolean("newVar"));
}

protected static function SubTest_JSONArrayParsingRaw()
{
    local JArray parsedArray;
    Issue("`ParseArrayRaw()` cannot parse empty JSON array.");
    parsedArray = _().json.ParseArrayRaw(_().text.StringToRaw("[]"));
    TEST_ExpectNotNone(parsedArray);
    TEST_ExpectTrue(parsedArray.GetLength() == 0);

    Issue("`ParseArrayRaw()` doesn't report error when parsing an incorrect"
        @ "object.");
    parsedArray = _().json.ParseArrayRaw(_().text.StringToRaw("[]"));
    TEST_ExpectNone(_().json.ParseArrayRaw(_().text.StringToRaw("")));
    TEST_ExpectNone(_().json.ParseArrayRaw(_().text.StringToRaw("[89")));
    TEST_ExpectNone(_().json.ParseArrayRaw(_().text.StringToRaw("89]")));
    TEST_ExpectNone(_().json.ParseArrayRaw(
        _().text.StringToRaw("[false null]")));

    Issue("`ParseArrayRaw()` cannot parse simple JSON array.");
    parsedArray = _().json.ParseArrayRaw(
        _().text.StringToRaw("[null, 67.349e2, \"what\"  , {}]"));
    TEST_ExpectNotNone(parsedArray);
    TEST_ExpectTrue(parsedArray.IsNull(0));
    TEST_ExpectTrue(parsedArray.GetNumber(1) == 6734.9);
    TEST_ExpectTrue(parsedArray.GetString(2) == "what");
    TEST_ExpectTrue(parsedArray.GetObject(3).GetKeys().length == 0);

    Issue("`JArray.ParseIntoSelfRaw()` cannot add new elements.");
    TEST_ExpectTrue(parsedArray.ParseIntoSelfRaw(
        _().text.StringToRaw("[\"huh\", Null]")));
    TEST_ExpectTrue(parsedArray.GetString(4) == "huh");
    TEST_ExpectTrue(parsedArray.IsNull(5));
}

protected static function SubTest_JSONObjectParsingString()
{
    local JObject parsedObject;
    Issue("`ParseObjectString()` cannot parse empty JSON object.");
    parsedObject = _().json.ParseObjectString("{}");
    TEST_ExpectNotNone(parsedObject);
    TEST_ExpectTrue(parsedObject.GetKeys().length == 0);

    Issue("`ParseObjectString()` doesn't report error when parsing an incorrect"
        @ "object.");
    parsedObject = _().json.ParseObjectString("{}");
    TEST_ExpectNone(_().json.ParseObjectString(""));
    TEST_ExpectNone(_().json.ParseObjectString("{\"var\": 89"));
    TEST_ExpectNone(_().json.ParseObjectString("\"var\": 89}"));
    TEST_ExpectNone(_().json.ParseObjectString("{var:false}"));

    Issue("`ParseObjectString()` cannot parse simple JSON object.");
    parsedObject = _().json.ParseObjectString("{\"var\":7 ,\"str\":\"aye!~\"}");
    TEST_ExpectNotNone(parsedObject);
    TEST_ExpectTrue(parsedObject.GetNumber("var") == 7);
    TEST_ExpectTrue(parsedObject.GetString("str") == "aye!~");

    Issue("`JObject.ParseIntoSelfString()` cannot add new properties.");
    TEST_ExpectTrue(parsedObject.ParseIntoSelfString("{\"newVar\": true}"));
    TEST_ExpectTrue(parsedObject.GetBoolean("newVar"));
}

protected static function SubTest_JSONArrayParsingString()
{
    local JArray parsedArray;
    Issue("`ParseArrayString()` cannot parse empty JSON array.");
    parsedArray = _().json.ParseArrayString("[]");
    TEST_ExpectNotNone(parsedArray);
    TEST_ExpectTrue(parsedArray.GetLength() == 0);

    Issue("`ParseArrayString()` doesn't report error when parsing an incorrect"
        @ "object.");
    parsedArray = _().json.ParseArrayString("[]");
    TEST_ExpectNone(_().json.ParseArrayString(""));
    TEST_ExpectNone(_().json.ParseArrayString("[89"));
    TEST_ExpectNone(_().json.ParseArrayString("89]"));
    TEST_ExpectNone(_().json.ParseArrayString("[false null]"));

    Issue("`ParseArrayString()` cannot parse simple JSON array.");
    parsedArray = _().json.ParseArrayString("[null, 67.349e2, \"what\"  , {}]");
    TEST_ExpectNotNone(parsedArray);
    TEST_ExpectTrue(parsedArray.IsNull(0));
    TEST_ExpectTrue(parsedArray.GetNumber(1) == 6734.9);
    TEST_ExpectTrue(parsedArray.GetString(2) == "what");
    TEST_ExpectTrue(parsedArray.GetObject(3).GetKeys().length == 0);

    Issue("`JArray.ParseIntoSelfString()` cannot add new elements.");
    TEST_ExpectTrue(parsedArray.ParseIntoSelfString("[\"huh\", Null]"));
    TEST_ExpectTrue(parsedArray.GetString(4) == "huh");
    TEST_ExpectTrue(parsedArray.IsNull(5));
}

defaultproperties
{
    caseName = "JSON"
    preparedJObjectString = "{\"innerObject\":{\"my_bool\":true,\"array\":[\"Engine.Actor\",false,null,{\"something here\":\"yes\",\"maybe\":0.003},56.6],\"one more\":{\"nope\":324532,\"whatever\":false,\"o rly?\":\"ya rly\"},\"my_int\":-9823452},\"some_var\":-7.32,\"another_var\":\"aye!\"}"
}