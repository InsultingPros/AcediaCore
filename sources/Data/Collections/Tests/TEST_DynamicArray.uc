/**
 *  Set of tests for `DynamicArray` class.
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
class TEST_DynamicArray extends TestCase
    abstract;

protected static function TESTS()
{
    Test_GetSet();
    Test_CreateItem();
    Test_Length();
    Test_Empty();
    Test_AddInsert();
    Test_Remove();
    Test_Find();
    Test_Managed();
    Test_DeallocationHandling();
    Test_Take();
}

protected static function Test_GetSet()
{
    local DynamicArray array;
    array = DynamicArray(__().memory.Allocate(class'DynamicArray'));
    Context("Testing getters and setters for items of `DynamicArray`.");
    Issue("Setters do not correctly expand `DynamicArray`.");
    array.SetItem(0, __().box.int(-9)).SetItem(2, __().text.FromString("text"));
    TEST_ExpectTrue(array.GetLength() == 3);
    TEST_ExpectTrue(IntBox(array.GetItem(0)).Get() == -9);
    TEST_ExpectNone(array.GetItem(1));
    TEST_ExpectTrue(Text(array.GetItem(2)).ToPlainString() == "text");

    Issue("Setters do not correctly overwrite items of `DynamicArray`.");
    array.SetItem(1, __().box.float(34.76));
    array.SetItem(2, none);
    TEST_ExpectTrue(array.GetLength() == 3);
    TEST_ExpectTrue(IntBox(array.GetItem(0)).Get() == -9);
    TEST_ExpectTrue(FloatBox(array.GetItem(1)).Get() == 34.76);
    TEST_ExpectNone(array.GetItem(2));
}

protected static function Test_CreateItem()
{
    local DynamicArray array;
    array = DynamicArray(__().memory.Allocate(class'DynamicArray'));
    Context("Testing creating brand new items for `DynamicArray`.");
    Issue("`CreateItem()` incorrectly adds new values to the"
        @ "`DynamicArray`.");
    array.CreateItem(1, class'Text');
    array.CreateItem(3, class'IntRef');
    array.CreateItem(4, class'BoolBox');
    TEST_ExpectNone(array.GetItem(0));
    TEST_ExpectNone(array.GetItem(2));
    TEST_ExpectTrue(Text(array.GetItem(1)).ToPlainString() == "");
    TEST_ExpectTrue(IntRef(array.GetItem(3)).Get() == 0);
    TEST_ExpectFalse(BoolBox(array.GetItem(4)).Get());

    Issue("`CreateItem()` incorrectly overrides existing values in the"
        @ "`DynamicArray`.");
    array.SetItem(5, __().ref.int(7));
    array.CreateItem(5, class'StringRef');
    TEST_ExpectTrue(StringRef(array.GetItem(5)).Get() == "");
    
    class'MockItem'.default.objectCount = 0;
    Issue("`CreateItem()` creates new object even if it cannot be recorded at"
        @ "a given index.");
    array.CreateItem(-1, class'MockItem');
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 0);
}

protected static function Test_Length()
{
    local DynamicArray array;
    array = DynamicArray(__().memory.Allocate(class'DynamicArray'));
    Context("Testing length getter and setter for `DynamicArray`.");
    Issue("Length of just created `DynamicArray` is not zero.");
    TEST_ExpectTrue(array.GetLength() == 0);

    Issue("`SetLength()` incorrectly changes length of the `DynamicArray`.");
    array.SetLength(200).SetItem(198, __().box.int(25));
    TEST_ExpectTrue(array.GetLength() == 200);
    TEST_ExpectTrue(IntBox(array.GetItem(198)).Get() == 25);
    array.SetLength(0);
    TEST_ExpectTrue(array.GetLength() == 0);

    Issue("Shrinking size of `DynamicArray` does not remove recorded items.");
    array.SetLength(1000);
    TEST_ExpectNone(array.GetItem(198));
}

protected static function Test_Empty()
{
    local DynamicArray array;
    array = DynamicArray(__().memory.Allocate(class'DynamicArray'));
    Context("Testing emptying `DynamicArray`.");
    array.AddItem(__().box.int(1)).AddItem(__().box.int(3))
        .AddItem(__().box.int(1)).AddItem(__().box.int(3));
    Issue("`Empty()` does not produce an empty array.");
    array.Empty();
    TEST_ExpectTrue(array.GetLength() == 0);
}

protected static function Test_AddInsert()
{
    local DynamicArray array;
    array = DynamicArray(__().memory.Allocate(class'DynamicArray'));
    Context("Testing adding new items to `DynamicArray`.");
    Issue("`Add()`/`AddItem()` incorrectly add new items to"
        @   "the `DynamicArray`.");
    array.AddItem(__().box.int(3)).Add(3).AddItem(__().box.byte(7)).Add(1);
    TEST_ExpectTrue(array.GetLength() == 6);
    TEST_ExpectNotNone(IntBox(array.GetItem(0)));
    TEST_ExpectTrue(IntBox(array.GetItem(0)).Get() == 3);
    TEST_ExpectNone(array.GetItem(1));
    TEST_ExpectNone(array.GetItem(2));
    TEST_ExpectNone(array.GetItem(3));
    TEST_ExpectNotNone(ByteBox(array.GetItem(4)));
    TEST_ExpectTrue(ByteBox(array.GetItem(4)).Get() == 7);
    TEST_ExpectNone(array.GetItem(5));

    Issue("`Insert()`/`InsertItem()` incorrectly add new items to"
        @   "the `DynamicArray`.");
    array.Insert(2, 2).InsertItem(0, __().ref.bool(true));
    TEST_ExpectTrue(array.GetLength() == 9);
    TEST_ExpectNotNone(BoolRef(array.GetItem(0)));
    TEST_ExpectTrue(BoolRef(array.GetItem(0)).Get());
    TEST_ExpectNotNone(IntBox(array.GetItem(1)));
    TEST_ExpectTrue(IntBox(array.GetItem(1)).Get() == 3);
    TEST_ExpectNone(array.GetItem(2));
    TEST_ExpectNone(array.GetItem(6));
    TEST_ExpectNotNone(ByteBox(array.GetItem(7)));
    TEST_ExpectTrue(ByteBox(array.GetItem(7)).Get() == 7);
    TEST_ExpectNone(array.GetItem(8));
}

protected static function Test_Remove()
{
    local DynamicArray array;
    array = DynamicArray(__().memory.Allocate(class'DynamicArray'));
    Context("Testing removing items from `DynamicArray`.");
    array.AddItem(__().box.int(1)).AddItem(__().box.int(3))
        .AddItem(__().box.int(1)).AddItem(__().box.int(3))
        .AddItem(__().box.int(5)).AddItem(__().box.int(2))
        .AddItem(__().box.int(4)).AddItem(__().box.int(7))
        .AddItem(__().box.int(5)).AddItem(__().box.int(1))
        .AddItem(__().box.int(5)).AddItem(__().box.int(0));
    Issue("`Remove()` incorrectly removes items from array.");
    array.Remove(3, 2).Remove(0, 2).Remove(7, 9);
    TEST_ExpectTrue(array.GetLength() == 7);
    TEST_ExpectTrue(IntBox(array.GetItem(0)).Get() == 1);
    TEST_ExpectTrue(IntBox(array.GetItem(1)).Get() == 2);
    TEST_ExpectTrue(IntBox(array.GetItem(2)).Get() == 4);
    TEST_ExpectTrue(IntBox(array.GetItem(3)).Get() == 7);
    TEST_ExpectTrue(IntBox(array.GetItem(4)).Get() == 5);
    TEST_ExpectTrue(IntBox(array.GetItem(5)).Get() == 1);
    TEST_ExpectTrue(IntBox(array.GetItem(6)).Get() == 5);

    Issue("`RemoveItem()` incorrectly removes items from array.");
    array.RemoveItem(__().box.int(1)).RemoveItem(__().box.int(5), true);
    TEST_ExpectTrue(array.GetLength() == 4);
    TEST_ExpectTrue(IntBox(array.GetItem(0)).Get() == 2);
    TEST_ExpectTrue(IntBox(array.GetItem(1)).Get() == 4);
    TEST_ExpectTrue(IntBox(array.GetItem(2)).Get() == 7);
    TEST_ExpectTrue(IntBox(array.GetItem(3)).Get() == 5);

    Issue("`RemoveIndex()` incorrectly removes items from array.");
    array.RemoveIndex(0).RemoveIndex(1).RemoveIndex(1);
    TEST_ExpectTrue(array.GetLength() == 1);
    TEST_ExpectTrue(IntBox(array.GetItem(0)).Get() == 4);
}

protected static function Test_Find()
{
    local DynamicArray array;
    array = DynamicArray(__().memory.Allocate(class'DynamicArray'));
    Context("Testing searching for items in `DynamicArray`.");
    array.AddItem(__().box.int(1)).AddItem(__().box.int(3))
        .AddItem(__().box.int(1)).AddItem(__().box.int(3))
        .AddItem(__().box.int(5)).AddItem(__().box.bool(true))
        .AddItem(none).AddItem(__().box.float(72.54))
        .AddItem(__().box.int(5)).AddItem(__().box.int(1))
        .AddItem(__().box.int(5)).AddItem(__().box.int(0));
    Issue("`Find()` does not properly find indices of existing items.");
    TEST_ExpectTrue(array.Find(__().box.int(5)) == 4);
    TEST_ExpectTrue(array.Find(__().box.int(1)) == 0);
    TEST_ExpectTrue(array.Find(__().box.int(0)) == 11);
    TEST_ExpectTrue(array.Find(__().box.float(72.54)) == 7);
    TEST_ExpectTrue(array.Find(__().box.bool(true)) == 5);
    TEST_ExpectTrue(array.Find(none) == 6);

    Issue("`Find()` does not return `-1` on missing values.");
    TEST_ExpectTrue(array.Find(__().box.int(42)) == -1);
    TEST_ExpectTrue(array.Find(__().box.float(72.543)) == -1);
    TEST_ExpectTrue(array.Find(__().box.bool(false)) == -1);
    TEST_ExpectTrue(array.Find(__().box.byte(128)) == -1);
}

protected static function MockItem NewMockItem()
{
    return MockItem(__().memory.Allocate(class'MockItem'));
}

//  Creates array with mock objects, also zeroing their count.
//  Managed items' count: 6, but 12 items total.
protected static function DynamicArray NewMockArray()
{
    local DynamicArray array;
    class'MockItem'.default.objectCount = 0;
    array = DynamicArray(__().memory.Allocate(class'DynamicArray'));
    array.AddItem(NewMockItem(), true).AddItem(NewMockItem(), false)
        .InsertItem(2, NewMockItem(), true).AddItem(NewMockItem(), true)
        .AddItem(NewMockItem(), false).AddItem(NewMockItem(), true)
        .InsertItem(6, NewMockItem(), false).AddItem(NewMockItem(), true)
        .InsertItem(3, NewMockItem(), false).AddItem(NewMockItem(), false)
        .InsertItem(10, NewMockItem(), true).AddItem(NewMockItem(), false);
    return array;
}

protected static function Test_Managed()
{
    local MockItem      exampleItem;
    local DynamicArray  array;
    exampleItem = NewMockItem();
    //  Managed items' count: 6, but 12 items total.
    array = NewMockArray();
    Context("Testing how `DynamicArray` deallocates managed objects.");
    Issue("`Remove()` incorrectly deallocates managed items.");
    // -2 managed items
    array.Remove(3, 2).Remove(0, 2).Remove(7, 9);
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 10);

    Issue("`RemoveIndex()` incorrectly deallocates managed items.");
    //  -1 managed items
    array.RemoveIndex(3).RemoveIndex(0);
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 9);
    //  -1 managed items
    array.RemoveItem(exampleItem, true).RemoveItem(exampleItem, true);
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 8);
    //  -2 managed items
    array.RemoveItem(exampleItem);
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 6);

    array = NewMockArray();
    Issue("Shrinking array with `SetLength()` incorrectly handles"
        @ "managed items");
    // -4 managed items
    array.SetLength(3);
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 8);

    Issue("Rewriting values with `SetItem()` incorrectly handles"
        @ "managed items.");
    //  -2 managed items
    array.SetItem(0, exampleItem, true);
    array.SetItem(2, exampleItem, true);
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 6);
}

protected static function Test_DeallocationHandling()
{
    local MockItem      exampleItem;
    local DynamicArray  array;
    exampleItem = NewMockItem();
    //  Managed items' count: 6, but 12 items total.
    array = NewMockArray();
    Context("Testing how `DynamicArray` deals with external deallocation of"
        @ "managed objects.");
    Issue("`DynamicArray` does not return `none` even though stored object"
        @ "was already deallocated.");
    array.GetItem(0).FreeSelf();
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 11);
    TEST_ExpectTrue(array.GetItem(0) == none);

    Issue("Managed items are not deallocated when they are duplicated inside"
        @ "`DynamicArray`, but they should.");
    array.SetItem(1, exampleItem, true).SetItem(2, exampleItem, true);
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 10);
    array.SetLength(2);
    //  At this point we got rid of all the managed objects that were generated
    //  in `array` + deallocated `exampleObject`.
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 5);
    TEST_ExpectTrue(array.GetItem(1) == none);
}

protected static function Test_Take()
{
    local DynamicArray array;
    Context("Testing `TakeItem()` method of `DynamicArray`.");
    //  Managed items' count: 6, but 12 items total.
    array = NewMockArray();
    Issue("`TakeItem()` returns incorrect value.");
    TEST_ExpectTrue(array.TakeItem(0).class == class'MockItem');
    TEST_ExpectTrue(array.TakeItem(3).class == class'MockItem');
    TEST_ExpectTrue(array.TakeItem(4).class == class'MockItem');
    TEST_ExpectTrue(array.TakeItem(6).class == class'MockItem');

    Issue("Objects returned by `TakeItem()` are still managed by"
        @ "`DynamicArray`.");
    array.Empty();
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 9);
}

defaultproperties
{
    caseGroup = "Collections"
    caseName = "DynamicArray"
}