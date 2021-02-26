/**
 *      Set of tests for value and array references.
 *  Since all reference types are generated from the same template,
 *  we just test them on `IntArrayRef`.
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
class TEST_Refs extends TestCase
    abstract;

var string preparedJObjectString;

protected static function TESTS()
{
    Test_API();
    Test_ValueRef();
    Test_ArrayRef();
    Test_Cleaning();
}

protected static function Test_API()
{
    local IntArrayRef ref;
    local array<int> arr;
    arr[0] = 2;
    arr[1] = 1;
    arr[2] = 3;
    Context("Testing `RefAPI`.");
    Issue("Objects created by API are `none`.");
    TEST_ExpectNotNone(__().ref.int());
    TEST_ExpectNotNone(__().ref.IntArray(arr));
    TEST_ExpectNotNone(__().ref.EmptyIntArray());

    Issue("Objects created by API have wrong initial value.");
    TEST_ExpectTrue(__().ref.int().Get() == 0);
    TEST_ExpectTrue(__().ref.EmptyIntArray().Get().length == 0);
    TEST_ExpectTrue(__().ref.int(35).Get() == 35);
    ref = __().ref.IntArray(arr);
    TEST_ExpectTrue(ref.Get().length == 3);
    TEST_ExpectTrue(ref.GetItem(0) == 2);
    TEST_ExpectTrue(ref.GetItem(1) == 1);
    TEST_ExpectTrue(ref.GetItem(2) == 3);
}

protected static function Test_ValueRef()
{
    local IntRef ref;
    ref = IntRef(__().memory.Allocate(class'IntRef'));

    Context("Testing `IntRef` methods.");
    Issue("`IntRef` incorrectly changes/stores value.");
    TEST_ExpectTrue(ref.Set(5).Get() == 5);
    TEST_ExpectTrue(ref.Set(-7).Get() == -7);
    TEST_ExpectTrue(ref.Set(MaxInt).Get() == MaxInt);
}

protected static function Test_ArrayRef()
{
    Context("Testing `IntArrayRef` methods.");
    SubTest_ArrayRefJustAllocated();
    SubTest_ArrayRefGetSet();
    SubTest_ArrayRefLength();
    SubTest_ArrayRefEmpty();
    SubTest_ArrayRefAddInsert();
    SubTest_ArrayRefRemove();
    SubTest_ArrayRefGetSetItem();
    SubTest_ArrayRefAddInsertItem();
    SubTest_ArrayRefAddInsertArray();
    SubTest_ArrayRefAddInsertArrayRef();
    SubTest_ArrayRefRemoveItem();
    SubTest_ArrayRefFind();
    SubTest_ArrayRefReplace();
    SubTest_ArrayRefSort();
}

protected static function SubTest_ArrayRefJustAllocated()
{
    local IntArrayRef ref;
    ref = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    Issue("`IntArrayRef` has unexpected (non-empty) default value.");
    Test_ExpectTrue(ref.Get().length == 0);

    Issue("`GetLength()` returns unexpected (non-zero) value on"
        @ "just created array.");
    Test_ExpectTrue(ref.GetLength() == 0);
}

protected static function SubTest_ArrayRefGetSet()
{
    local IntArrayRef ref;
    local array<int> arr;
    arr[arr.length] = 1;
    arr[arr.length] = 3;
    arr[arr.length] = 5;
    arr[arr.length] = 2;
    arr[arr.length] = 4;

    Issue("`Get()/Set()` incorrectly changes/stores array value.");
    ref = __().ref.IntArray(arr);
    TEST_ExpectTrue(ref.Get()[0] == 1);
    TEST_ExpectTrue(ref.Get()[1] == 3);
    TEST_ExpectTrue(ref.Get()[2] == 5);
    TEST_ExpectTrue(ref.Get()[3] == 2);
    TEST_ExpectTrue(ref.Get()[4] == 4);
}

protected static function SubTest_ArrayRefLength()
{
    local IntArrayRef ref;
    local array<int> arr;
    ref = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    Issue("`IntArrayRef` does not increase it's length while empty.");
    ref.SetLength(2);
    TEST_ExpectTrue(ref.GetLength() == 2);
    TEST_ExpectTrue(ref.Get().length == 2);
    TEST_ExpectTrue(ref.Get()[0] == 0);
    TEST_ExpectTrue(ref.Get()[1] == 0);

    Issue("`GetLength()/SetLength()` incorrectly changes/returns it's length.");
    arr[arr.length] = 8;
    arr[arr.length] = 3;
    ref.Set(arr);
    TEST_ExpectTrue(ref.GetLength() == 2);
    ref.SetLength(4);
    TEST_ExpectTrue(ref.GetLength() == 4);
    TEST_ExpectTrue(ref.Get().length == 4);
    TEST_ExpectTrue(ref.Get()[1] == 3);
    TEST_ExpectTrue(ref.Get()[2] == 0);
    TEST_ExpectTrue(ref.Get()[3] == 0);
    ref.SetLength(1);
    TEST_ExpectTrue(ref.GetLength() == 1);
    TEST_ExpectTrue(ref.Get().length == 1);
    ref.SetLength(-1);
    TEST_ExpectTrue(ref.GetLength() == 1);
    TEST_ExpectTrue(ref.Get().length == 1);
    TEST_ExpectTrue(ref.Get()[0] == 8);
    ref.SetLength(0);
    TEST_ExpectTrue(ref.GetLength() == 0);
    TEST_ExpectTrue(ref.Get().length == 0);
}

protected static function SubTest_ArrayRefEmpty()
{
    local IntArrayRef ref;
    local array<int> arr;
    ref = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    Issue("`Empty()` does not empty array.");
    //  Empty just created array
    ref.Empty();
    TEST_ExpectTrue(ref.GetLength() == 0);

    //  Empty array with set value
    arr[arr.length] = 1;
    arr[arr.length] = 3;
    arr[arr.length] = 5;
    arr[arr.length] = 2;
    arr[arr.length] = 4;
    ref.Set(arr).Empty();
    TEST_ExpectTrue(ref.GetLength() == 0);

    //  Empty after simple length increase
    ref.SetLength(100).Empty();
    TEST_ExpectTrue(ref.GetLength() == 0);
}

protected static function SubTest_ArrayRefAddInsert()
{
    local IntArrayRef ref;
    local array<int> arr;
    ref = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    arr[arr.length] = 4;
    arr[arr.length] = 9;
    Issue("`Add()` does not properly add new elements to the end of an array.");
    ref.Add(2);
    TEST_ExpectTrue(ref.GetLength() == 2);
    TEST_ExpectTrue(ref.Get()[0] == 0);
    TEST_ExpectTrue(ref.Get()[1] == 0);
    ref.Set(arr).Add(2);
    TEST_ExpectTrue(ref.GetLength() == 4);
    TEST_ExpectTrue(ref.Get()[0] == 4);
    TEST_ExpectTrue(ref.Get()[3] == 0);
    ref.Add(1);
    TEST_ExpectTrue(ref.GetLength() == 5);
    TEST_ExpectTrue(ref.Get()[1] == 9);
    TEST_ExpectTrue(ref.Get()[4] == 0);

    Issue("`Insert()` does not properly add new elements to the array.");
    ref.Set(arr).Insert(1, 3).Insert(0, 2).Insert(7, 10);
    TEST_ExpectTrue(ref.GetLength() == 17);
    TEST_ExpectTrue(ref.Get()[1] == 0);
    TEST_ExpectTrue(ref.Get()[2] == 4);
    TEST_ExpectTrue(ref.Get()[6] == 9);
    TEST_ExpectTrue(ref.Get()[5] == 0);
    TEST_ExpectTrue(ref.Get()[7] == 0);
    TEST_ExpectTrue(ref.Get()[16] == 0);
}

protected static function SubTest_ArrayRefRemove()
{
    local IntArrayRef ref;
    local array<int> arr;
    ref = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    arr[arr.length] = 1;
    arr[arr.length] = 2;
    arr[arr.length] = 3;
    arr[arr.length] = 4;
    arr[arr.length] = 5;
    Issue("`Remove()` does not properly remove elements from an array.");
    ref.Set(arr).Remove(2, 2);
    TEST_ExpectTrue(ref.GetLength() == 3);
    TEST_ExpectTrue(ref.Get()[0] == 1);
    TEST_ExpectTrue(ref.Get()[1] == 2);
    TEST_ExpectTrue(ref.Get()[2] == 5);
    ref.Remove(2, 10);
    TEST_ExpectTrue(ref.GetLength() == 2);
    TEST_ExpectTrue(ref.Get()[0] == 1);
    TEST_ExpectTrue(ref.Get()[1] == 2);
    ref.Remove(0, 3);
    TEST_ExpectTrue(ref.GetLength() == 0);

    Issue("`RemoveIndex()` does not properly remove elements from an array.");
    ref.Set(arr).RemoveIndex(2).RemoveIndex(3).RemoveIndex(0);
    TEST_ExpectTrue(ref.GetLength() == 2);
    TEST_ExpectTrue(ref.Get()[0] == 2);
    TEST_ExpectTrue(ref.Get()[1] == 4);
}

protected static function SubTest_ArrayRefGetSetItem()
{
    local IntArrayRef ref;
    ref = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    ref.SetLength(3);
    ref.SetItem(0, 24);
    ref.SetItem(1, 9);
    ref.SetItem(2, 11);
    ref.SetItem(4, 15);
    Issue("`GetItem()/SetItem()` incorrectly changes/stores array's items.");
    TEST_ExpectTrue(ref.GetItem(0) == 24);
    TEST_ExpectTrue(ref.GetItem(1, 132) == 9);
    TEST_ExpectTrue(ref.GetItem(2, 132) == 11);
    TEST_ExpectTrue(ref.GetItem(3, 132) == 0);
    TEST_ExpectTrue(ref.GetItem(4, 132) == 15);
    TEST_ExpectTrue(ref.GetItem(5, 132) == 132);
}

protected static function SubTest_ArrayRefAddInsertItem()
{
    local IntArrayRef ref;
    ref = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    Issue("`AddItem()/InsertItem()` incorrectly add single items.");
    ref.InsertItem(0, 7).AddItem(64).AddItem(-5).InsertItem(2, 24);
    TEST_ExpectTrue(ref.GetLength() == 4);
    TEST_ExpectTrue(ref.Get()[0] == 7);
    TEST_ExpectTrue(ref.Get()[1] == 64);
    TEST_ExpectTrue(ref.Get()[2] == 24);
    TEST_ExpectTrue(ref.Get()[3] == -5);
}

protected static function SubTest_ArrayRefAddInsertArray()
{
    local IntArrayRef ref;
    local array<int> arr, emptyArr;
    ref = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    arr[arr.length] = 4;
    arr[arr.length] = 7;
    arr[arr.length] = -1;
    Issue("`AddArray()/InsertArray()` incorrectly add items from array.");
    ref.InsertArray(0, arr)
        .AddArray(arr)
        .InsertArray(2, arr)
        .InsertArray(4, emptyArr);
    TEST_ExpectTrue(ref.Get()[0] == 4);
    TEST_ExpectTrue(ref.Get()[1] == 7);
    TEST_ExpectTrue(ref.Get()[2] == 4);
    TEST_ExpectTrue(ref.Get()[3] == 7);
    TEST_ExpectTrue(ref.Get()[4] == -1);
    TEST_ExpectTrue(ref.Get()[5] == -1);
    TEST_ExpectTrue(ref.Get()[6] == 4);
    TEST_ExpectTrue(ref.Get()[7] == 7);
    TEST_ExpectTrue(ref.Get()[8] == -1);
}

protected static function SubTest_ArrayRefAddInsertArrayRef()
{
    local IntArrayRef ref, otherRef, emptyRef;
    local array<int> arr;
    ref         = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    otherRef    = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    emptyRef    = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    arr[arr.length] = 4;
    arr[arr.length] = 7;
    arr[arr.length] = -1;
    otherRef.Set(arr);
    Issue("`AddArrayRef()/InsertArrayRef()` incorrectly add items from array.");
    ref.InsertArrayRef(0, otherRef)
        .AddArrayRef(otherRef)
        .InsertArrayRef(2, otherRef)
        .InsertArrayRef(4, emptyRef);
    TEST_ExpectTrue(ref.Get()[0] == 4);
    TEST_ExpectTrue(ref.Get()[1] == 7);
    TEST_ExpectTrue(ref.Get()[2] == 4);
    TEST_ExpectTrue(ref.Get()[3] == 7);
    TEST_ExpectTrue(ref.Get()[4] == -1);
    TEST_ExpectTrue(ref.Get()[5] == -1);
    TEST_ExpectTrue(ref.Get()[6] == 4);
    TEST_ExpectTrue(ref.Get()[7] == 7);
    TEST_ExpectTrue(ref.Get()[8] == -1);
}

protected static function SubTest_ArrayRefRemoveItem()
{
    local IntArrayRef ref;
    local array<int> arr;
    ref = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    arr[arr.length] = 4;
    arr[arr.length] = 7;
    arr[arr.length] = -1;
    arr[arr.length] = 5;
    arr[arr.length] = 7;
    arr[arr.length] = 5;
    arr[arr.length] = 5;
    arr[arr.length] = 7;
    arr[arr.length] = 5;
    ref.Set(arr).RemoveItem(5, true);
    Issue("`RemoveItem(, true)` incorrectly removes single item from array.");
    TEST_ExpectTrue(ref.Get()[0] == 4);
    TEST_ExpectTrue(ref.Get()[1] == 7);
    TEST_ExpectTrue(ref.Get()[2] == -1);
    TEST_ExpectTrue(ref.Get()[3] == 7);
    TEST_ExpectTrue(ref.Get()[4] == 5);
    TEST_ExpectTrue(ref.Get()[5] == 5);
    TEST_ExpectTrue(ref.Get()[6] == 7);
    TEST_ExpectTrue(ref.Get()[7] == 5);
    Issue("`RemoveItem()` incorrectly removes items from array.");
    ref.RemoveItem(5);
    TEST_ExpectTrue(ref.Get()[0] == 4);
    TEST_ExpectTrue(ref.Get()[1] == 7);
    TEST_ExpectTrue(ref.Get()[2] == -1);
    TEST_ExpectTrue(ref.Get()[3] == 7);
    TEST_ExpectTrue(ref.Get()[4] == 7);
}

protected static function SubTest_ArrayRefFind()
{
    local IntArrayRef ref;
    local array<int> arr;
    ref = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    arr[arr.length] = 4;
    arr[arr.length] = 7;
    arr[arr.length] = -1;
    arr[arr.length] = 5;
    arr[arr.length] = 7;
    arr[arr.length] = 5;
    ref.Set(arr);
    Issue("`Find()` incorrectly finds items inside array.");
    TEST_ExpectTrue(ref.Find(7) == 1);
    TEST_ExpectTrue(ref.Find(4) == 0);
    TEST_ExpectTrue(ref.Find(-1) == 2);
    TEST_ExpectTrue(ref.Find(-2) == -1);
}

protected static function SubTest_ArrayRefReplace()
{
    local IntArrayRef ref;
    local array<int> arr;
    ref = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    arr[arr.length] = 4;
    arr[arr.length] = 7;
    arr[arr.length] = -1;
    arr[arr.length] = 5;
    arr[arr.length] = 7;
    arr[arr.length] = 5;
    ref.Set(arr).Replace(7, 0).Replace(-1, 0).Replace(0, 1).Replace(7, -5);
    Issue("`Replace()` incorrectly replaces items inside array.");
    TEST_ExpectTrue(ref.Get()[0] == 4);
    TEST_ExpectTrue(ref.Get()[1] == 1);
    TEST_ExpectTrue(ref.Get()[2] == 1);
    TEST_ExpectTrue(ref.Get()[3] == 5);
    TEST_ExpectTrue(ref.Get()[4] == 1);
    TEST_ExpectTrue(ref.Get()[5] == 5);
}

protected static function SubTest_ArrayRefSort()
{
    local int           i;
    local IntArrayRef   ref;
    local array<int>    sorted;
    ref     = IntArrayRef(__().memory.Allocate(class'IntArrayRef'));
    sorted  = GetSortedArray();
    ref.Set(GetUnsortedArray());
    ref.Sort();
    Issue("`Sort()` incorrectly sorts array in ascending order.");
    for (i = 0; i < sorted.length; i += 1) {
        TEST_ExpectTrue(ref.GetItem(i) == sorted[i]);
    }
    ref.Sort(true);
    Issue("`Sort()` incorrectly sorts array in descending order.");
    for (i = 0; i < sorted.length; i += 1) {
        TEST_ExpectTrue(ref.GetItem(i) == sorted[sorted.length - i - 1]);
    }
}

protected static function Test_Cleaning()
{
    local BoolRef ref1;
    local FloatRef ref2;
    local IntRef ref3;
    Issue("Test cleaning ref values after deallocation.");
    ref1 = __().ref.bool(true);
    ref2 = __().ref.float(67.352);
    ref3 = __().ref.int(-34);
    ref1.FreeSelf();
    ref2.FreeSelf();
    ref3.FreeSelf();
    TEST_ExpectFalse(ref1.Get());
    TEST_ExpectTrue(ref2.Get() == 0.0);
    TEST_ExpectTrue(ref3.Get() == 0);
}

protected static function array<int> GetUnsortedArray()
{
    local array<int> arr;
    arr[arr.length] = -1;
    arr[arr.length] = 8;
    arr[arr.length] = -19;
    arr[arr.length] = -6;
    arr[arr.length] = 12;
    arr[arr.length] = 14;
    arr[arr.length] = -12;
    arr[arr.length] = -7;
    arr[arr.length] = 18;
    arr[arr.length] = -13;
    arr[arr.length] = -13;
    arr[arr.length] = -3;
    arr[arr.length] = -13;
    arr[arr.length] = -12;
    arr[arr.length] = 7;
    arr[arr.length] = 17;
    arr[arr.length] = -6;
    arr[arr.length] = -16;
    arr[arr.length] = 8;
    arr[arr.length] = -10;
    arr[arr.length] = 0;
    arr[arr.length] = 10;
    arr[arr.length] = -11;
    arr[arr.length] = 3;
    arr[arr.length] = -3;
    arr[arr.length] = 11;
    arr[arr.length] = 2;
    arr[arr.length] = -3;
    arr[arr.length] = 7;
    arr[arr.length] = -19;
    arr[arr.length] = 20;
    arr[arr.length] = -1;
    arr[arr.length] = -15;
    arr[arr.length] = -3;
    arr[arr.length] = -1;
    arr[arr.length] = -11;
    arr[arr.length] = -11;
    arr[arr.length] = -13;
    arr[arr.length] = -14;
    arr[arr.length] = 3;
    arr[arr.length] = -11;
    arr[arr.length] = 14;
    arr[arr.length] = 4;
    arr[arr.length] = 12;
    arr[arr.length] = 9;
    arr[arr.length] = -12;
    arr[arr.length] = 14;
    arr[arr.length] = -1;
    arr[arr.length] = -1;
    arr[arr.length] = -14;
    arr[arr.length] = 14;
    arr[arr.length] = -10;
    arr[arr.length] = 18;
    arr[arr.length] = 2;
    arr[arr.length] = -5;
    arr[arr.length] = -19;
    arr[arr.length] = 19;
    arr[arr.length] = 0;
    arr[arr.length] = -16;
    arr[arr.length] = 11;
    arr[arr.length] = -6;
    arr[arr.length] = 20;
    arr[arr.length] = -8;
    arr[arr.length] = -12;
    arr[arr.length] = 10;
    arr[arr.length] = 9;
    arr[arr.length] = -10;
    arr[arr.length] = 3;
    arr[arr.length] = -1;
    arr[arr.length] = 7;
    arr[arr.length] = 1;
    arr[arr.length] = -7;
    arr[arr.length] = 5;
    arr[arr.length] = 17;
    arr[arr.length] = 2;
    arr[arr.length] = 15;
    arr[arr.length] = 8;
    arr[arr.length] = -13;
    arr[arr.length] = 10;
    arr[arr.length] = -14;
    arr[arr.length] = -1;
    arr[arr.length] = 8;
    arr[arr.length] = -19;
    arr[arr.length] = 17;
    arr[arr.length] = 0;
    arr[arr.length] = -12;
    arr[arr.length] = -15;
    arr[arr.length] = -11;
    arr[arr.length] = -4;
    arr[arr.length] = 12;
    arr[arr.length] = -7;
    arr[arr.length] = -11;
    arr[arr.length] = -16;
    arr[arr.length] = -2;
    arr[arr.length] = 8;
    arr[arr.length] = 0;
    arr[arr.length] = -16;
    arr[arr.length] = 0;
    arr[arr.length] = 8;
    arr[arr.length] = 14;
    return arr;
}

protected static function array<int> GetSortedArray()
{
    local array<int> arr;
    arr[arr.length] = -19;
    arr[arr.length] = -19;
    arr[arr.length] = -19;
    arr[arr.length] = -19;
    arr[arr.length] = -16;
    arr[arr.length] = -16;
    arr[arr.length] = -16;
    arr[arr.length] = -16;
    arr[arr.length] = -15;
    arr[arr.length] = -15;
    arr[arr.length] = -14;
    arr[arr.length] = -14;
    arr[arr.length] = -14;
    arr[arr.length] = -13;
    arr[arr.length] = -13;
    arr[arr.length] = -13;
    arr[arr.length] = -13;
    arr[arr.length] = -13;
    arr[arr.length] = -12;
    arr[arr.length] = -12;
    arr[arr.length] = -12;
    arr[arr.length] = -12;
    arr[arr.length] = -12;
    arr[arr.length] = -11;
    arr[arr.length] = -11;
    arr[arr.length] = -11;
    arr[arr.length] = -11;
    arr[arr.length] = -11;
    arr[arr.length] = -11;
    arr[arr.length] = -10;
    arr[arr.length] = -10;
    arr[arr.length] = -10;
    arr[arr.length] = -8;
    arr[arr.length] = -7;
    arr[arr.length] = -7;
    arr[arr.length] = -7;
    arr[arr.length] = -6;
    arr[arr.length] = -6;
    arr[arr.length] = -6;
    arr[arr.length] = -5;
    arr[arr.length] = -4;
    arr[arr.length] = -3;
    arr[arr.length] = -3;
    arr[arr.length] = -3;
    arr[arr.length] = -3;
    arr[arr.length] = -2;
    arr[arr.length] = -1;
    arr[arr.length] = -1;
    arr[arr.length] = -1;
    arr[arr.length] = -1;
    arr[arr.length] = -1;
    arr[arr.length] = -1;
    arr[arr.length] = -1;
    arr[arr.length] = 0;
    arr[arr.length] = 0;
    arr[arr.length] = 0;
    arr[arr.length] = 0;
    arr[arr.length] = 0;
    arr[arr.length] = 1;
    arr[arr.length] = 2;
    arr[arr.length] = 2;
    arr[arr.length] = 2;
    arr[arr.length] = 3;
    arr[arr.length] = 3;
    arr[arr.length] = 3;
    arr[arr.length] = 4;
    arr[arr.length] = 5;
    arr[arr.length] = 7;
    arr[arr.length] = 7;
    arr[arr.length] = 7;
    arr[arr.length] = 8;
    arr[arr.length] = 8;
    arr[arr.length] = 8;
    arr[arr.length] = 8;
    arr[arr.length] = 8;
    arr[arr.length] = 8;
    arr[arr.length] = 9;
    arr[arr.length] = 9;
    arr[arr.length] = 10;
    arr[arr.length] = 10;
    arr[arr.length] = 10;
    arr[arr.length] = 11;
    arr[arr.length] = 11;
    arr[arr.length] = 12;
    arr[arr.length] = 12;
    arr[arr.length] = 12;
    arr[arr.length] = 14;
    arr[arr.length] = 14;
    arr[arr.length] = 14;
    arr[arr.length] = 14;
    arr[arr.length] = 14;
    arr[arr.length] = 15;
    arr[arr.length] = 17;
    arr[arr.length] = 17;
    arr[arr.length] = 17;
    arr[arr.length] = 18;
    arr[arr.length] = 18;
    arr[arr.length] = 19;
    arr[arr.length] = 20;
    arr[arr.length] = 20;
    return arr;
}

defaultproperties
{
    caseGroup = "Types"
    caseName = "Refs"
}