/**
 *  Set of tests for `ArrayList` class.
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
class TEST_ArrayList extends TestCase
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
    Test_ReferenceManagementGet();
    Test_Take();
}

protected static function Test_GetSet()
{
    local ArrayList array;

    array = ArrayList(__().memory.Allocate(class'ArrayList'));
    Context("Testing getters and setters for items of `ArrayList`.");
    Issue("Setters do not correctly expand `ArrayList`.");
    array.SetItem(0, __().box.int(-9)).SetItem(2, __().text.FromString("text"));
    TEST_ExpectTrue(array.GetLength() == 3);
    TEST_ExpectTrue(IntBox(array.GetItem(0)).Get() == -9);
    TEST_ExpectNone(array.GetItem(1));
    TEST_ExpectTrue(Text(array.GetItem(2)).ToString() == "text");

    Issue("Setters do not correctly overwrite items of `ArrayList`.");
    array.SetItem(1, __().box.float(34.76));
    array.SetItem(2, none);
    TEST_ExpectTrue(array.GetLength() == 3);
    TEST_ExpectTrue(IntBox(array.GetItem(0)).Get() == -9);
    TEST_ExpectTrue(FloatBox(array.GetItem(1)).Get() == 34.76);
    TEST_ExpectNone(array.GetItem(2));
}

protected static function Test_CreateItem()
{
    local ArrayList array;

    array = ArrayList(__().memory.Allocate(class'ArrayList'));
    Context("Testing creating brand new items for `ArrayList`.");
    Issue("`CreateItem()` incorrectly adds new values to the"
        @ "`ArrayList`.");
    array.CreateItem(1, class'Text');
    array.CreateItem(3, class'IntRef');
    array.CreateItem(4, class'BoolBox');
    TEST_ExpectNone(array.GetItem(0));
    TEST_ExpectNone(array.GetItem(2));
    TEST_ExpectTrue(Text(array.GetItem(1)).ToString() == "");
    TEST_ExpectTrue(IntRef(array.GetItem(3)).Get() == 0);
    TEST_ExpectFalse(BoolBox(array.GetItem(4)).Get());

    Issue("`CreateItem()` incorrectly overrides existing values in the"
        @ "`ArrayList`.");
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
    local ArrayList array;

    array = ArrayList(__().memory.Allocate(class'ArrayList'));
    Context("Testing length getter and setter for `ArrayList`.");
    Issue("Length of just created `ArrayList` is not zero.");
    TEST_ExpectTrue(array.GetLength() == 0);

    Issue("`SetLength()` incorrectly changes length of the `ArrayList`.");
    array.SetLength(200).SetItem(198, __().box.int(25));
    TEST_ExpectTrue(array.GetLength() == 200);
    TEST_ExpectTrue(IntBox(array.GetItem(198)).Get() == 25);
    array.SetLength(0);
    TEST_ExpectTrue(array.GetLength() == 0);

    Issue("Shrinking size of `ArrayList` does not remove recorded items.");
    array.SetLength(1000);
    TEST_ExpectNone(array.GetItem(198));
}

protected static function Test_Empty()
{
    local ArrayList array;

    array = ArrayList(__().memory.Allocate(class'ArrayList'));
    Context("Testing emptying `ArrayList`.");
    array.AddItem(__().box.int(1)).AddItem(__().box.int(3))
        .AddItem(__().box.int(1)).AddItem(__().box.int(3));
    Issue("`Empty()` does not produce an empty array.");
    array.Empty();
    TEST_ExpectTrue(array.GetLength() == 0);
}

protected static function Test_AddInsert()
{
    local ArrayList array;

    array = ArrayList(__().memory.Allocate(class'ArrayList'));
    Context("Testing adding new items to `ArrayList`.");
    Issue("`Add()`/`AddItem()` incorrectly add new items to"
        @   "the `ArrayList`.");
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
        @   "the `ArrayList`.");
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
    local ArrayList array;

    array = ArrayList(__().memory.Allocate(class'ArrayList'));
    Context("Testing removing items from `ArrayList`.");
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
    local ArrayList array;

    array = ArrayList(__().memory.Allocate(class'ArrayList'));
    Context("Testing searching for items in `ArrayList`.");
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

protected static function ArrayList NewMockArray(
    int                 arrayLength,
    out array<MockItem> allocatedItems)
{
    local int       i;
    local ArrayList array;

    class'MockItem'.default.objectCount = 0;
    array = ArrayList(__().memory.Allocate(class'ArrayList'));
    for (i = 0; i < arrayLength; i += 1)
    {
        allocatedItems[allocatedItems.length] = NewMockItem();
        array.AddItem(allocatedItems[allocatedItems.length - 1]);
    }
    //  Get rid of references outside of array
    __().memory.FreeMany(allocatedItems);
    return array;
}

protected static function Test_ReferenceManagementGet()
{
    local int               i;
    local ArrayList         array;
    local array<MockItem>   allocatedItems;

    array = NewMockArray(20, allocatedItems);
    Context("Testing how well `ArrayList` supports reference counting.");
    Issue("`ArrayList` incorrectly increments reference count when storing" @
        "an item.");
    for (i = 0; i < allocatedItems.length; i += 1)
    {
        TEST_ExpectTrue(allocatedItems[i]._getRefCount() == 1);
        if (i % 3 == 0) {
            allocatedItems[i].FreeSelf();
        }
    }

    for (i = 0; i < allocatedItems.length; i += 1)
    {
        if (i % 3 == 0)
        {
            Issue("`ArrayList` does unnecessary handling of deallocated"
                @ "items.");
            TEST_ExpectNotNone(array.GetItem(i));
            TEST_ExpectFalse(array.GetItem(i).IsAllocated());
        }
        else if (i % 3 == 1)
        {
            Issue("`ArrayList` does not increment reference count on"
                @ "`GetItem()`");
            TEST_ExpectTrue(array.GetItem(i)._getRefCount() == 2);
        }
        else
        {
            Issue("`ArrayList` increments reference count on `TakeItem()`");
            TEST_ExpectTrue(array.TakeItem(i)._getRefCount() == 1);
        }
    }
}

protected static function Test_Take()
{
    local int               i;
    local ArrayList         array;
    local array<MockItem>   allocatedItems;

    array = NewMockArray(20, allocatedItems);
    Context("Testing how well `ArrayList`'s `TakeItem()` command");
    Issue("`TakeItem()` return wrongs item.");
    for (i = 0; i < allocatedItems.length; i += 1)
    {
        if (i % 2 == 0) {
            TEST_ExpectTrue(array.TakeItem(i) == allocatedItems[i]);
        }
    }
    for (i = 0; i < allocatedItems.length; i += 1)
    {
        if (i % 2 == 0)
        {
            Issue("`TakeItem()` does not remove items from collection.");
            TEST_ExpectNone(array.TakeItem(i));
        }
        else
        {
            Issue("`TakeItem()` affects other items in collection.");
            TEST_ExpectTrue(array.TakeItem(i).IsAllocated());
        }
    }
}

defaultproperties
{
    caseGroup   = "Collections"
    caseName    = "ArrayList"
}