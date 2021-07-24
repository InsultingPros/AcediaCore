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
class TEST_AssociativeArray extends TestCase
    abstract;

protected static function TESTS()
{
    Test_GetSet();
    Test_HasKey();
    Test_GetKeys();
    Test_CopyTextKeys();
    Test_Remove();
    Test_CreateItem();
    Test_Empty();
    Test_Length();
    Test_Managed();
    Test_DeallocationHandling();
    Test_Take();
    Test_LargeArray();
}

protected static function Test_GetSet()
{
    local Text              textObject;
    local AssociativeArray  array;
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));

    Context("Testing getters and setters for items of `AssociativeArray`.");
    Issue("`SetItem()` does not correctly set new items.");
    textObject = __().text.FromString("value");
    array.SetItem(__().text.FromString("key"), textObject);
    array.SetItem(__().box.int(13), __().text.FromString("value #2"));
    array.SetItem(__().box.float(345.2), __().box.bool(true));
    TEST_ExpectTrue(    Text(array.GetItem(__().box.int(13))).ToPlainString()
                    ==  "value #2");
    TEST_ExpectTrue(array.GetItem(__().text.FromString("key")) == textObject);
    TEST_ExpectTrue(BoolBox(array.GetItem(__().box.float(345.2))).Get());

    Issue("`SetItem()` does not correctly overwrite new items.");
    array.SetItem(__().text.FromString("key"), __().text.FromString("value"));
    array.SetItem(__().box.int(13), __().box.int(11));
    TEST_ExpectFalse(array.GetItem(__().text.FromString("key")) == textObject);
    TEST_ExpectTrue(    Text(array.GetItem(__().text.FromString("key")))
        .ToPlainString() ==  "value");
    TEST_ExpectTrue(    IntBox(array.GetItem(__().box.int(13))).Get()
                    ==  11);

    Issue("`GetItem()` does not return `none` for non-existing keys.");
    TEST_ExpectNone(array.GetItem(__().box.int(12)));
    TEST_ExpectNone(array.GetItem(__().box.byte(67)));
    TEST_ExpectNone(array.GetItem(__().box.float(43.1234)));
    TEST_ExpectNone(array.GetItem(__().text.FromString("Some random stuff")));
}

protected static function Test_HasKey()
{
    local AssociativeArray array;
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    Context("Testing `HasKey()` method for `AssociativeArray`.");
    array.SetItem(__().text.FromString("key"), __().text.FromString("value"));
    array.SetItem(__().box.int(13), __().text.FromString("value #2"));
    array.SetItem(__().box.float(345.2), __().box.bool(true));
    Issue("`HasKey()` reports that added keys do not exist in"
        @ "`AssociativeArray`.");
    TEST_ExpectTrue(array.HasKey(__().text.FromString("key")));
    TEST_ExpectTrue(array.HasKey(__().box.int(13)));
    TEST_ExpectTrue(array.HasKey(__().box.float(345.2)));

    Issue("`HasKey()` reports that `AssociativeArray` contains keys that"
        @ "were never added.");
    TEST_ExpectFalse(array.HasKey(none));
    TEST_ExpectFalse(array.HasKey(__().box.float(13)));
    TEST_ExpectFalse(array.HasKey(__().box.byte(139)));
}

protected static function Test_GetKeys()
{
    local int                   i;
    local AcediaObject          key1, key2, key3;
    local array<AcediaObject>   keys;
    local AssociativeArray      array;
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    Context("Testing `GetKeys()` method for `AssociativeArray`.");
    key1 = __().text.FromString("key");
    key2 = __().box.int(13);
    key3 = __().box.float(345.2);
    array.SetItem(key1, __().text.FromString("value"));
    array.SetItem(key2, __().text.FromString("value #2"));
    array.SetItem(key3, __().box.bool(true));
    keys = array.GetKeys();
    Issue("`GetKeys()` returns array with wrong amount of elements.");
    TEST_ExpectTrue(keys.length == 3);

    Issue("`GetKeys()` returns array with duplicate keys.");
    TEST_ExpectTrue(keys[0] != keys[1]);
    TEST_ExpectTrue(keys[0] != keys[2]);
    TEST_ExpectTrue(keys[1] != keys[2]);

    Issue("`GetKeys()` returns array with incorrect keys.");
    for (i = 0; i < 3; i += 1) {
        TEST_ExpectTrue(keys[i] == key1 || keys[i] == key2 || keys[i] == key3);
    }

    keys = array.RemoveItem(key1).GetKeys();
    Issue("`GetKeys()` returns array with incorrect keys after removing"
        @ "an element.");
    TEST_ExpectTrue(keys.length == 2);
    TEST_ExpectTrue(keys[0] != keys[1]);
    for (i = 0; i < 2; i += 1) {
        TEST_ExpectTrue(keys[i] == key2 || keys[i] == key3);
    }
}

protected static function Test_CopyTextKeys()
{
    local array<AcediaObject>   allKeys;
    local array<Text>           keys;
    local AssociativeArray      array;
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    Context("Testing `CopyTextKeys()` method for `AssociativeArray`.");
    array.SetItem(__().text.FromString("key"), __().text.FromString("value"));
    array.SetItem(__().box.int(13), __().text.FromString("value #2"));
    array.SetItem(__().box.float(-925.274), __().text.FromString("value #2"));
    array.SetItem(__().text.FromString("second key"), __().box.bool(true));

    Issue("`CopyTextKeys()` does not return correct set of keys.");
    keys = array.CopyTextKeys();
    TEST_ExpectTrue(keys.length == 2);
    TEST_ExpectTrue(
                (keys[0].ToPlainString() == "key"
            &&  keys[1].ToPlainString() == "second key")
        ||      (keys[0].ToPlainString() == "second key"
            &&  keys[1].ToPlainString() == "key"));

    Issue("Deallocating keys returned by `CopyTextKeys()` affects their"
        @ "source collection.");
    allKeys = array.GetKeys();
    TEST_ExpectTrue(allKeys.length == 4);
    TEST_ExpectNotNone(array.GetItem(__().text.FromString("key")));
    TEST_ExpectNotNone(array.GetItem(__().text.FromString("second key")));
    TEST_ExpectTrue(
        array.GetText(__().text.FromString("key")).ToPlainString() == "value");
}

protected static function Test_Remove()
{
    local AcediaObject          key1, key2, key3;
    local array<AcediaObject>   keys;
    local AssociativeArray      array;
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    Context("Testing removing elements from `AssociativeArray`.");
    key1 = __().text.FromString("some key");
    key2 = __().box.int(25);
    key3 = __().box.float(0.07);
    array.SetItem(key1, __().text.FromString("value"));
    array.SetItem(key2, __().text.FromString("value #2"));
    array.SetItem(key3, __().box.bool(true));
    Issue("Elements are not properly removed from `AssociativeArray`.");
    array.RemoveItem(key1)
        .RemoveItem(__().box.int(25))
        .RemoveItem(__().box.float(0.06));
    keys = array.GetKeys();
    TEST_ExpectTrue(array.GetLength() == 1);
    TEST_ExpectTrue(keys.length == 1);
    TEST_ExpectTrue(keys[0] == key3);
}

protected static function Test_CreateItem()
{
    local AssociativeArray array;
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    Context("Testing creating brand new items for `AssociativeArray`.");
    Issue("`CreateItem()` incorrectly adds new values to the"
        @ "`AssociativeArray`.");
    array.CreateItem(__().text.FromString("key"), class'Text');
    array.CreateItem(__().box.float(17.895), class'IntRef');
    array.CreateItem(__().text.FromString("key #2"), class'BoolBox');
    TEST_ExpectTrue(Text(array.GetItem(__().text.FromString("key")))
        .ToPlainString() == "");
    TEST_ExpectTrue(    IntRef(array.GetItem(__().box.float(17.895))).Get()
                    ==  0);
    TEST_ExpectFalse(BoolBox(array.GetItem(__().text.FromString("key #2")))
        .Get());

    Issue("`CreateItem()` incorrectly overrides existing values in the"
        @ "`AssociativeArray`.");
    array.SetItem(__().box.int(13), __().ref.int(7));
    array.CreateItem(__().box.int(13), class'StringRef');
    TEST_ExpectTrue(    StringRef(array.GetItem(__().box.int(13))).Get()
                    ==  "");
    
    class'MockItem'.default.objectCount = 0;
    Issue("`CreateItem()` creates new object even if it cannot be recorded with"
        @ "a given key.");
    array.CreateItem(none, class'MockItem');
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 0);
}

protected static function Test_Empty()
{
    local AcediaObject key1, key2, key3;
    local AssociativeArray array;
    key1 = __().text.FromString("key");
    key2 = __().box.int(13);
    key3 = __().box.float(345.2);
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    array.SetItem(key1, __().text.FromString("value"));
    array.SetItem(key2, __().text.FromString("value #2"), true);
    array.SetItem(key3, __().box.bool(true));

    Context("Testing `Empty()` method for `AssociativeArray`.");
    Issue("`AssociativeArray` still contains elements after being emptied.");
    array.Empty();
    TEST_ExpectTrue(array.GetKeys().length == 0);
    TEST_ExpectTrue(array.GetLength() == 0);

    Issue("`AssociativeArray` deallocated keys when not being told to do so.");
    TEST_ExpectTrue(key1.IsAllocated());
    TEST_ExpectTrue(key2.IsAllocated());
    TEST_ExpectTrue(key3.IsAllocated());

    Issue("`AssociativeArray` still contains elements after being emptied.");
    array.SetItem(key1, __().text.FromString("value"), true);
    array.SetItem(key2, __().text.FromString("value #2"));
    array.SetItem(key3, __().box.bool(true), true);
    array.Empty(true);
    TEST_ExpectTrue(array.GetKeys().length == 0);
    TEST_ExpectTrue(array.GetLength() == 0);

    Issue("`AssociativeArray` does not deallocate keys when told to do so.");
    TEST_ExpectFalse(key1.IsAllocated());
    TEST_ExpectFalse(key2.IsAllocated());
    TEST_ExpectFalse(key3.IsAllocated());
}

protected static function Test_Length()
{
    local AssociativeArray array;
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    Context("Testing computing length of `AssociativeArray`.");
    Issue("Length is not zero for newly created `AssociativeArray`.");
    TEST_ExpectTrue(array.GetLength() == 0);

    Issue("Length is incorrectly computed after adding elements to"
        @ "`AssociativeArray`.");
    array.SetItem(__().text.FromString("key"), __().text.FromString("value"));
    array.SetItem(__().box.int(4563), __().text.FromString("value #2"));
    array.SetItem(__().box.float(3425.243), __().box.byte(23));
    TEST_ExpectTrue(array.GetLength() == 3);

    Issue("Length is incorrectly computed after removing elements from"
        @ "`AssociativeArray`.");
    array.RemoveItem(__().box.int(4563));
    TEST_ExpectTrue(array.GetLength() == 2);
}

protected static function MockItem NewMockItem()
{
    return MockItem(__().memory.Allocate(class'MockItem'));
}

protected static function Test_Managed()
{
    local AssociativeArray array;
    class'MockItem'.default.objectCount = 0;
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    array.SetItem(__().box.int(0), NewMockItem());
    array.SetItem(__().box.int(1), NewMockItem());
    array.SetItem(__().box.int(2), NewMockItem());
    array.SetItem(__().box.int(3), NewMockItem(), true);
    array.SetItem(__().box.int(4), NewMockItem(), true);
    array.SetItem(__().box.int(5), NewMockItem(), true);
    array.CreateItem(__().box.int(6), class'MockItem');
    array.CreateItem(__().box.int(7), class'MockItem');
    array.CreateItem(__().box.int(8), class'MockItem');
    Context("Testing how `AssociativeArray` deallocates managed objects.");
    Issue("`RemoveItem()` incorrectly deallocates managed items.");
    array.RemoveItem(__().box.int(0));
    array.RemoveItem(__().box.int(3));
    array.RemoveItem(__().box.int(6));
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 7);

    Issue("Rewriting values with `SetItem()` incorrectly handles"
        @ "managed items.");
    array.SetItem(__().box.int(1), __().ref.int(28347));
    array.SetItem(__().box.int(4), __().ref.float(13.4));
    array.SetItem(__().box.int(7), __().ref.byte(94));
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 5);

    Issue("Rewriting values with `CreateItem()` incorrectly handles"
        @ "managed items.");
    array.CreateItem(__().box.int(2), class'IntRef');
    array.CreateItem(__().box.int(5), class'StringRef');
    array.CreateItem(__().box.int(8), class'IntArrayBox');
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 3);
}

protected static function Test_DeallocationHandling()
{
    Context("Testing how `AssociativeArray` deals with external deallocation of"
        @ "keys and managed objects.");
    SubTest_DeallocationHandlingKeys();
    SubTest_DeallocationHandlingManagedObjects();
}

protected static function SubTest_DeallocationHandlingKeys()
{
    local IntBox                key1;
    local BoolBox               key2;
    local Text                  key3;
    local AssociativeArray      array;
    local array<AcediaObject>   keys;
    key1 = __().box.int(3881);
    key2 = __().box.bool(true);
    key3 = __().text.FromString("Text key, bay bee");
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    class'MockItem'.default.objectCount = 0;
    array.SetItem(key1, NewMockItem());
    array.SetItem(key2, __().box.float(32.31), true);
    array.SetItem(key3, NewMockItem(), true);

    Issue("Deallocating keys does not remove them from `AssociativeArray`.");
    key1.FreeSelf();
    key3.FreeSelf();
    keys = array.GetKeys();
    TEST_ExpectTrue(keys.length == 1);
    TEST_ExpectTrue(keys[0] == key2);

    Issue("`AssociativeArray` does not deallocate managed objects, even though"
        @ "their keys were deallocated");
    TEST_ExpectTrue(class'MockItem'.default.objectCount < 2);
    TEST_ExpectNone(array.GetItem(__().box.int(3881)));

    Issue("`AssociativeArray` deallocates unmanaged objects, when"
        @ "their keys were deallocated");
    TEST_ExpectTrue(class'MockItem'.default.objectCount > 0);
}

protected static function SubTest_DeallocationHandlingManagedObjects()
{
    local MockItem          exampleItem;
    local AssociativeArray  array;
    class'MockItem'.default.objectCount = 0;
    exampleItem = NewMockItem();
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    array.SetItem(__().box.int(-34), exampleItem, true);
    array.SetItem(__().box.int(-7), exampleItem, true);
    array.SetItem(__().box.int(23), NewMockItem());
    array.SetItem(__().box.int(242), NewMockItem(), true);
    array.CreateItem(__().box.int(24532), class'MockItem');
    Issue("`AssociativeArray` does not return `none` even though stored object"
        @ "was already deallocated.");
    array.GetItem(__().box.int(23)).FreeSelf();
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 3);
    TEST_ExpectTrue(array.GetItem(__().box.int(23)) == none);

    Issue("Managed items are not deallocated when they are duplicated inside"
        @ "`AssociativeArray`, but they should.");
    array.RemoveItem(__().box.int(-7));
    //  At this point we got rid of all the managed objects that were generated
    //  in `array` + deallocated `exampleObject`.
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 2);
    TEST_ExpectTrue(array.GetItem(__().box.int(-34)) == none);
}

protected static function Test_Take()
{
    local AssociativeArray.Entry    entry;
    local AssociativeArray          array;
    class'MockItem'.default.objectCount = 0;
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    array.SetItem(__().box.int(0), NewMockItem());
    array.SetItem(__().box.int(1), NewMockItem());
    array.SetItem(__().box.int(2), NewMockItem());
    array.SetItem(__().box.int(3), NewMockItem(), true);
    array.SetItem(__().box.int(4), NewMockItem(), true);
    array.SetItem(__().box.int(5), NewMockItem(), true);
    array.CreateItem(__().box.int(6), class'MockItem');
    array.CreateItem(__().box.int(7), class'MockItem');
    array.CreateItem(__().box.int(8), class'MockItem');
    Context("Testing `TakeItem()` method of `AssociativeArray`.");
    Issue("`TakeItem()` returns incorrect value.");
    TEST_ExpectTrue(array.TakeItem(__().box.int(0)).class == class'MockItem');
    TEST_ExpectTrue(array.TakeItem(__().box.int(3)).class == class'MockItem');
    TEST_ExpectTrue(array.TakeItem(__().box.int(6)).class == class'MockItem');

    Issue("`TakeEntry()` returns incorrect value.");
    entry = array.TakeEntry(__().box.int(4));
    TEST_ExpectTrue(entry.key.class == class'IntBox');
    TEST_ExpectTrue(entry.value.class == class'MockItem');
    entry = array.TakeEntry(__().box.int(7));
    TEST_ExpectTrue(entry.key.class == class'IntBox');
    TEST_ExpectTrue(entry.value.class == class'MockItem');

    Issue("Objects returned by `Take()` and `takeEntry()` are still managed by"
        @ "`AssociativeArray`.");
    array.Empty();
    TEST_ExpectTrue(class'MockItem'.default.objectCount == 7);
}

protected static function Test_LargeArray()
{
    local int               i;
    local AcediaObject      nextKey;
    local AssociativeArray  array;
    Context("Testing storing large amount of elements in `AssociativeArray`.");
    Issue("`AssociativeArray` cannot handle large amount of elements.");
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    for (i = 0; i < 2500; i += 1) {
        if (i % 2 == 0) {
            nextKey = __().text.FromString("var" @ i);
        }
        else {
            nextKey = __().box.int(i * 56 - 435632);
        }
        array.SetItem(nextKey, __().ref.int(i));
    }
    for (i = 0; i < 2500; i += 1) {
        if (i % 2 == 0) {
            nextKey = __().text.FromString("var" @ i);
        }
        else {
            nextKey = __().box.int(i * 56 - 435632);
        }
        TEST_ExpectTrue(IntRef(array.GetItem(nextKey)).Get() == i);
    }
}

defaultproperties
{
    caseGroup = "Collections"
    caseName = "AssociativeArray"
}