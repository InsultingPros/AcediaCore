/**
 *  Set of tests for `AssociativeArray` class.
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
class TEST_CollectionsMixed extends TestCase
    abstract;

var protected const string complexJSONObject;

protected static function TESTS()
{
    Context("Testing accessing collections by JSON pointers.");
    Test_GetByPointer();
    Test_GetTypeByPointer();
}

protected static function Test_GetByPointer()
{
    local AcediaObject      result;
    local AssociativeArray  obj;
    Issue("`GetItemByPointer()` does not return correct objects.");
    obj = __().json.ParseObjectWith(
        __().text.ParseString(default.complexJSONObject));
    TEST_ExpectTrue(obj.GetItemByPointer(P("")) == obj);
    result = obj.GetItemByPointer(P("/innerObject/array/1"));
    TEST_ExpectNotNone(BoolBox(result));
    TEST_ExpectTrue(BoolBox(result).Get() == false);
    result = obj.GetItemByPointer(P("/innerObject/array/3/maybe"));
    TEST_ExpectNotNone(FloatBox(result));
    TEST_ExpectTrue(FloatBox(result).Get() == 0.003);

    Issue("`GetItemByPointer()` does not return correct objects when using"
        @ "'~'-escaped sequences.");    
    result = obj.GetItemByPointer(P("/another~01var"));
    TEST_ExpectNotNone(Text(result));
    TEST_ExpectTrue(Text(result).ToPlainString() == "aye!");
    result = obj.GetItemByPointer(P("/innerObject/one more/no~1pe"));
    TEST_ExpectNotNone(IntBox(result));
    TEST_ExpectTrue(IntBox(result).Get() == 324532);
    TEST_ExpectNotNone(
        DynamicArray(obj.GetItemByPointer(P("/innerObject/array"))));

    Issue("`GetItemByPointer()` does not return `none` for incorrect pointers");
    TEST_ExpectNone(obj.GetItemByPointer(P("//")));
    TEST_ExpectNone(obj.GetItemByPointer(P("/innerObject/array/5")));
    TEST_ExpectNone(obj.GetItemByPointer(P("/innerObject/array/-1")));
    TEST_ExpectNone(obj.GetItemByPointer(P("/innerObject/array/")));
}

protected static function Test_GetTypeByPointer()
{
    local AssociativeArray obj;
    obj = __().json.ParseObjectWith(
        __().text.ParseString(default.complexJSONObject));
    obj.SetItem(P("byte"), __().ref.byte(56));
    Issue("`Get<Type>ByPointer()` methods do not return correct"
        @ "existing values.");
    TEST_ExpectTrue(obj.GetAssociativeArrayByPointer(P("")) == obj);
    TEST_ExpectNotNone(obj.GetDynamicArrayByPointer(P("/innerObject/array")));
    TEST_ExpectTrue(
            obj.GetBoolByPointer(P("/innerObject/array/1"), true)
        ==  false);
    TEST_ExpectTrue(obj.GetByteByPointer(P("/byte"), 128) == 56);
    TEST_ExpectTrue(obj.GetIntByPointer(P("/innerObject/my_int")) == -9823452);
    TEST_ExpectTrue(obj
            .GetFloatByPointer(P("/innerObject/array/4"), 2.34)
        ==  56.6);
    TEST_ExpectTrue(obj
            .GetTextByPointer(P("/innerObject/one more/o rly?")).ToPlainString()
        ==  "ya rly");
    Issue("`Get<Type>ByPointer()` methods do not return default value for"
        @ "incorrect pointers.");
    TEST_ExpectTrue(
            obj.GetBoolByPointer(P("/innerObject/array/20"), true)
        ==  true);
    TEST_ExpectTrue(obj.GetByteByPointer(P("/byte/"), 128) == 128);
    TEST_ExpectTrue(obj.GetIntByPointer(P("/innerObject/my int")) == 0);
    TEST_ExpectTrue(obj
            .GetFloatByPointer(P("/innerObject/array"), 2.34)
        ==  2.34);
    TEST_ExpectNone(obj.GetTextByPointer(P("")));
}

defaultproperties
{
    caseGroup = "Collections"
    caseName = "Common methods"
    complexJSONObject = "{\"innerObject\":{\"my_bool\":true,\"array\":[\"Engine.Actor\",false,null,{\"something \\\"here\\\"\":\"yes\",\"maybe\":0.003},56.6],\"one more\":{\"no/pe\":324532,\"whatever\":false,\"o rly?\":\"ya rly\"},\"my_int\":-9823452},\"some_var\":-7.32,\"another~1var\":\"aye!\"}"
}