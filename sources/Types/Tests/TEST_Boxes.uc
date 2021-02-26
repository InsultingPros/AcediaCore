/**
 *      Set of tests for value and array boxes.
 *  Since all boxes types are generated from the same template,
 *  we just test them on `IntBox` and `IntArrayBox`.
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
class TEST_Boxes extends TestCase
    abstract;

var string preparedJObjectString;

protected static function TESTS()
{
    Test_API();
    Test_ValueBox();
    Test_ArrayBox();
    Test_Cleaning();
}

protected static function Test_API()
{
    local IntArrayBox box;
    local array<int> arr;
    arr[0] = 2;
    arr[1] = 1;
    arr[2] = 3;
    Context("Testing `BoxAPI`.");
    Issue("Objects created by API are `none`.");
    TEST_ExpectNotNone(__().box.int());
    TEST_ExpectNotNone(__().box.IntArray(arr));

    Issue("Objects created by API store wrong value.");
    TEST_ExpectTrue(__().box.int().Get() == 0);
    TEST_ExpectTrue(__().box.int(35).Get() == 35);
    box = __().box.IntArray(arr);
    TEST_ExpectTrue(box.Get().length == 3);
    TEST_ExpectTrue(box.GetItem(0) == 2);
    TEST_ExpectTrue(box.GetItem(1) == 1);
    TEST_ExpectTrue(box.GetItem(2) == 3);
}

protected static function Test_ValueBox()
{
    local IntBox box;
    box = IntBox(__().memory.Allocate(class'IntBox'));

    Context("Testing `IntBox` methods.");
    Issue("`IntBox` incorrectly stores value.");
    box.Initialize(7);
    TEST_ExpectTrue(box.Get() == 7);
}

protected static function Test_ArrayBox()
{
    Context("Testing `IntArrayBox` methods.");
    SubTest_ArrayBoxJustAllocated();
    SubTest_ArrayBoxGet();
    SubTest_ArrayBoxFind();
}

protected static function SubTest_ArrayBoxJustAllocated()
{
    local IntArrayBox box;
    box = IntArrayBox(__().memory.Allocate(class'IntArrayBox'));
    Issue("`IntArrayBox` has unexpected (non-empty) default value.");
    Test_ExpectTrue(box.Get().length == 0);

    Issue("`GetLength()` returns unexpected (non-zero) value on"
        @ "just created array box.");
    Test_ExpectTrue(box.GetLength() == 0);
}

protected static function SubTest_ArrayBoxGet()
{
    local IntArrayBox box;
    local array<int> arr;
    box = IntArrayBox(__().memory.Allocate(class'IntArrayBox'));
    arr[arr.length] = 1;
    arr[arr.length] = 3;
    arr[arr.length] = 5;
    arr[arr.length] = 2;
    arr[arr.length] = 4;

    Issue("`Get()` returns unexpected value.");
    box.Initialize(arr);
    TEST_ExpectTrue(box.Get()[0] == 1);
    TEST_ExpectTrue(box.Get()[1] == 3);
    TEST_ExpectTrue(box.Get()[2] == 5);
    TEST_ExpectTrue(box.Get()[3] == 2);
    TEST_ExpectTrue(box.Get()[4] == 4);

    Issue("`GetItem()` returns unexpected values.");
    TEST_ExpectTrue(box.GetItem(0) == 1);
    TEST_ExpectTrue(box.GetItem(1) == 3);
    TEST_ExpectTrue(box.GetItem(2) == 5);
    TEST_ExpectTrue(box.GetItem(3) == 2);
    TEST_ExpectTrue(box.GetItem(4) == 4);

    Issue("`GetItem()` returns unexpected array length.");
    TEST_ExpectTrue(box.GetLength() == 5);
}

protected static function SubTest_ArrayBoxFind()
{
    local IntArrayBox box;
    local array<int> arr;
    box = IntArrayBox(__().memory.Allocate(class'IntArrayBox'));
    arr[arr.length] = 4;
    arr[arr.length] = 7;
    arr[arr.length] = -1;
    arr[arr.length] = 5;
    arr[arr.length] = 7;
    arr[arr.length] = 5;
    box.Initialize(arr);
    Issue("`Find()` incorrectly finds items inside array box.");
    TEST_ExpectTrue(box.Find(7) == 1);
    TEST_ExpectTrue(box.Find(4) == 0);
    TEST_ExpectTrue(box.Find(-1) == 2);
    TEST_ExpectTrue(box.Find(-2) == -1);
}

protected static function Test_Cleaning()
{
    local BoolBox box1;
    local FloatBox box2;
    local IntBox box3;
    Issue("Test cleaning box values after deallocation.");
    box1 = __().box.bool(true);
    box2 = __().box.float(67.352);
    box3 = __().box.int(-34);
    box1.FreeSelf();
    box2.FreeSelf();
    box3.FreeSelf();
    TEST_ExpectFalse(box1.Get());
    TEST_ExpectTrue(box2.Get() == 0.0);
    TEST_ExpectTrue(box3.Get() == 0);
}

defaultproperties
{
    caseGroup = "Types"
    caseName = "Boxes"
}