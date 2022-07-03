/**
 *  Set of tests for `ArrayList` and `HashTable` classes.
 *      Copyright 2022 Anton Tarasenko
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
    Test_GetBy();
    Test_GetTypeBy();
}

protected static function Test_GetBy()
{
    local AcediaObject  result;
    local HashTable     obj;
    Issue("`GetItemBy()` does not return correct objects.");
    obj = __().json.ParseHashTableWith(
        __().text.ParseString(default.complexJSONObject));
    TEST_ExpectTrue(obj.GetItemBy(P("")) == obj);
    result = obj.GetItemBy(P("/innerObject/array/1"));
    TEST_ExpectNotNone(BoolBox(result));
    TEST_ExpectTrue(BoolBox(result).Get() == false);
    result = obj.GetItemBy(P("/innerObject/array/3/maybe"));
    TEST_ExpectNotNone(FloatBox(result));
    TEST_ExpectTrue(FloatBox(result).Get() == 0.003);

    Issue("`GetItemBy()` does not return correct objects when using"
        @ "'~'-escaped sequences.");    
    result = obj.GetItemBy(P("/another~01var"));
    TEST_ExpectNotNone(Text(result));
    TEST_ExpectTrue(Text(result).ToString() == "aye!");
    result = obj.GetItemBy(P("/innerObject/one more/no~1pe"));
    TEST_ExpectNotNone(IntBox(result));
    TEST_ExpectTrue(IntBox(result).Get() == 324532);
    TEST_ExpectNotNone(
        ArrayList(obj.GetItemBy(P("/innerObject/array"))));

    Issue("`GetItemBy()` does not return `none` for incorrect pointers");
    TEST_ExpectNone(obj.GetItemBy(P("//")));
    TEST_ExpectNone(obj.GetItemBy(P("/innerObject/array/5")));
    TEST_ExpectNone(obj.GetItemBy(P("/innerObject/array/-1")));
    TEST_ExpectNone(obj.GetItemBy(P("/innerObject/array/")));
}

protected static function Test_GetTypeBy()
{
    local HashTable obj;
    obj = __().json.ParseHashTableWith(
        __().text.ParseString(default.complexJSONObject));
    obj.SetItem(P("byte"), __().ref.byte(56));
    Issue("`Get<Type>By()` methods do not return correct"
        @ "existing values.");
    TEST_ExpectTrue(obj.GetHashTableBy(P("")) == obj);
    TEST_ExpectNotNone(obj.GetArrayListBy(P("/innerObject/array")));
    TEST_ExpectTrue(
            obj.GetBoolBy(P("/innerObject/array/1"), true)
        ==  false);
    TEST_ExpectTrue(obj.GetByteBy(P("/byte"), 128) == 56);
    TEST_ExpectTrue(obj.GetIntBy(P("/innerObject/my_int")) == -9823452);
    TEST_ExpectTrue(obj
            .GetFloatBy(P("/innerObject/array/4"), 2.34)
        ==  56.6);
    TEST_ExpectTrue(obj
            .GetTextBy(P("/innerObject/one more/o rly?")).ToString()
        ==  "ya rly");
    Issue("`Get<Type>By()` methods do not return default value for"
        @ "incorrect pointers.");
    TEST_ExpectTrue(
            obj.GetBoolBy(P("/innerObject/array/20"), true)
        ==  true);
    TEST_ExpectTrue(obj.GetByteBy(P("/byte/"), 128) == 128);
    TEST_ExpectTrue(obj.GetIntBy(P("/innerObject/my int")) == 0);
    TEST_ExpectTrue(obj
            .GetFloatBy(P("/innerObject/array"), 2.34)
        ==  2.34);
    TEST_ExpectNone(obj.GetTextBy(P("")));
}

defaultproperties
{
    caseGroup = "Collections"
    caseName = "Common methods"
    complexJSONObject = "{\"innerObject\":{\"my_bool\":true,\"array\":[\"Engine.Actor\",false,null,{\"something \\\"here\\\"\":\"yes\",\"maybe\":0.003},56.6],\"one more\":{\"no/pe\":324532,\"whatever\":false,\"o rly?\":\"ya rly\"},\"my_int\":-9823452},\"some_var\":-7.32,\"another~1var\":\"aye!\"}"
}