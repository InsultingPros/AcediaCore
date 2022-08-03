/**
 *  Set of tests for `HashTable` class.
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
class TEST_HashTable extends TestCase
    abstract;

var private array<IntBox>   keys;
var private array<MockItem> mockedItems;

protected static function TESTS()
{
    Test_GetSet();
    Test_Rewrite();
    Test_HasKey();
    Test_GetKeys();
    Test_GetTextKeys();
    Test_Remove();
    Test_CreateItem();
    Test_Empty();
    Test_Length();
    Test_ReferenceManagement();
    Test_Take();
    Test_LargeArray();
}

protected static function AcediaObject NewKey(int value)
{
    local IntBox newBox;

    newBox = __().box.int(value);
    default.keys[default.keys.length] = newBox;
    return newBox;
}

protected static function MockItem NewMockItem()
{
    local MockItem newItem;

    newItem = MockItem(__().memory.Allocate(class'MockItem'));
    default.mockedItems[default.mockedItems.length] = newItem;
    return newItem;
}

protected static function Test_GetSet()
{
    local Text      textObject;
    local HashTable array;

    array = HashTable(__().memory.Allocate(class'HashTable'));
    Context("Testing getters and setters for items of `HashTable`.");
    Issue("`SetItem()` does not correctly set new items.");
    textObject = __().text.FromString("value");
    array.SetItem(__().text.FromString("key"), textObject);
    array.SetItem(__().box.int(13), __().text.FromString("value #2"));
    array.SetItem(__().box.float(345.2), __().box.bool(true));
    TEST_ExpectTrue(    Text(array.GetItem(__().box.int(13))).ToString()
                    ==  "value #2");
    TEST_ExpectTrue(array.GetItem(__().text.FromString("key")) == textObject);
    TEST_ExpectTrue(BoolBox(array.GetItem(__().box.float(345.2))).Get());

    Issue("`SetItem()` does not correctly overwrite new items.");
    array.SetItem(__().text.FromString("key"), __().text.FromString("value"));
    array.SetItem(__().box.int(13), __().box.int(11));
    TEST_ExpectFalse(array.GetItem(__().text.FromString("key")) == textObject);
    TEST_ExpectTrue(    Text(array.GetItem(__().text.FromString("key")))
        .ToString() ==  "value");
    TEST_ExpectTrue(    IntBox(array.GetItem(__().box.int(13))).Get()
                    ==  11);

    Issue("`GetItem()` does not return `none` for non-existing keys.");
    TEST_ExpectNone(array.GetItem(__().box.int(12)));
    TEST_ExpectNone(array.GetItem(__().box.byte(67)));
    TEST_ExpectNone(array.GetItem(__().box.float(43.1234)));
    TEST_ExpectNone(array.GetItem(__().text.FromString("Some random stuff")));
}

protected static function Test_Rewrite()
{
    local Text      textObject;
    local HashTable array;

    array = HashTable(__().memory.Allocate(class'HashTable'));
    Context("Testing getters and setters for items of `HashTable`.");
    Issue("`SetItem()` does not handle reference counts correctly when"
        @ "replacing a value with itself.");
    textObject = __().text.FromString("value");
    array.SetItem(__().text.FromString("key"), textObject);
    array.SetItem(__().text.FromString("key"), textObject);
    TEST_ExpectTrue(textObject._getRefCount() == 2);
}

protected static function Test_HasKey()
{
    local HashTable array;

    array = HashTable(__().memory.Allocate(class'HashTable'));
    Context("Testing `HasKey()` method for `HashTable`.");
    array.SetItem(__().text.FromString("key"), __().text.FromString("value"));
    array.SetItem(__().box.int(13), __().text.FromString("value #2"));
    array.SetItem(__().box.float(345.2), __().box.bool(true));
    Issue("`HasKey()` reports that added keys do not exist in"
        @ "`HashTable`.");
    TEST_ExpectTrue(array.HasKey(__().text.FromString("key")));
    TEST_ExpectTrue(array.HasKey(__().box.int(13)));
    TEST_ExpectTrue(array.HasKey(__().box.float(345.2)));

    Issue("`HasKey()` reports that `HashTable` contains keys that"
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
    local HashTable      array;

    array = HashTable(__().memory.Allocate(class'HashTable'));
    Context("Testing `GetKeys()` method for `HashTable`.");
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

protected static function Test_GetTextKeys()
{
    local array<AcediaObject>   allKeys;
    local array<Text>           keys;
    local HashTable             array;

    array = HashTable(__().memory.Allocate(class'HashTable'));
    Context("Testing `GetTextKeys()` method for `HashTable`.");
    array.SetItem(__().text.FromString("key"), __().text.FromString("value"));
    array.SetItem(__().box.int(13), __().text.FromString("value #2"));
    array.SetItem(__().box.float(-925.274), __().text.FromString("value #2"));
    array.SetItem(__().text.FromString("second key"), __().box.bool(true));

    Issue("`GetTextKeys()` does not return correct set of keys.");
    keys = array.GetTextKeys();
    TEST_ExpectTrue(keys.length == 2);
    TEST_ExpectTrue(
                (keys[0].ToString() == "key"
            &&  keys[1].ToString() == "second key")
        ||      (keys[0].ToString() == "second key"
            &&  keys[1].ToString() == "key"));

    Issue("Deallocating keys returned by `GetTextKeys()` affects their"
        @ "source collection.");
    allKeys = array.GetKeys();
    TEST_ExpectTrue(allKeys.length == 4);
    TEST_ExpectNotNone(array.GetItem(__().text.FromString("key")));
    TEST_ExpectNotNone(array.GetItem(__().text.FromString("second key")));
    TEST_ExpectTrue(
        array.GetText(__().text.FromString("key")).ToString() == "value");
}

protected static function Test_Remove()
{
    local AcediaObject          key1, key2, key3;
    local array<AcediaObject>   keys;
    local HashTable             array;

    Context("Testing removing elements from `HashTable`.");
    array = HashTable(__().memory.Allocate(class'HashTable'));
    key1 = __().text.FromString("some key");
    key2 = __().box.int(25);
    key3 = __().box.float(0.07);
    array.SetItem(key1, __().text.FromString("value"));
    array.SetItem(key2, __().text.FromString("value #2"));
    array.SetItem(key3, __().box.bool(true));

    Issue("Elements are not properly removed from `HashTable`.");
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
    local HashTable array;

    array = HashTable(__().memory.Allocate(class'HashTable'));
    Context("Testing creating brand new items for `HashTable`.");
    Issue("`CreateItem()` incorrectly adds new values to the"
        @ "`HashTable`.");
    array.CreateItem(__().text.FromString("key"), class'Text');
    array.CreateItem(__().box.float(17.895), class'IntRef');
    array.CreateItem(__().text.FromString("key #2"), class'BoolBox');
    TEST_ExpectTrue(Text(array.GetItem(__().text.FromString("key")))
        .ToString() == "");
    TEST_ExpectTrue(    IntRef(array.GetItem(__().box.float(17.895))).Get()
                    ==  0);
    TEST_ExpectFalse(BoolBox(array.GetItem(__().text.FromString("key #2")))
        .Get());

    Issue("`CreateItem()` incorrectly overrides existing values in the"
        @ "`HashTable`.");
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
    local HashTable array;

    key1 = __().text.FromString("key");
    key2 = __().box.int(13);
    key3 = __().box.float(345.2);
    array = HashTable(__().memory.Allocate(class'HashTable'));
    array.SetItem(key1, __().text.FromString("value"));
    array.SetItem(key2, __().text.FromString("value #2"));
    array.SetItem(key3, __().box.bool(true));

    Context("Testing `Empty()` method for `HashTable`.");
    Issue("`HashTable` still contains elements after being emptied.");
    array.Empty();
    TEST_ExpectTrue(array.GetKeys().length == 0);
    TEST_ExpectTrue(array.GetLength() == 0);

    Issue("`HashTable` still contains elements after being emptied.");
    array.SetItem(key1, __().text.FromString("value"));
    array.SetItem(key2, __().text.FromString("value #2"));
    array.SetItem(key3, __().box.bool(true));
    array.Empty();
    TEST_ExpectTrue(array.GetKeys().length == 0);
    TEST_ExpectTrue(array.GetLength() == 0);
}

protected static function Test_Length()
{
    local HashTable array;

    array = HashTable(__().memory.Allocate(class'HashTable'));
    Context("Testing computing length of `HashTable`.");
    Issue("Length is not zero for newly created `HashTable`.");
    TEST_ExpectTrue(array.GetLength() == 0);

    Issue("Length is incorrectly computed after adding elements to"
        @ "`HashTable`.");
    array.SetItem(__().text.FromString("key"), __().text.FromString("value"));
    array.SetItem(__().box.int(4563), __().text.FromString("value #2"));
    array.SetItem(__().box.float(3425.243), __().box.byte(23));
    TEST_ExpectTrue(array.GetLength() == 3);

    Issue("Length is incorrectly computed after removing elements from"
        @ "`HashTable`.");
    array.RemoveItem(__().box.int(4563));
    TEST_ExpectTrue(array.GetLength() == 2);
}

protected static function HashTable RecreateTestHashTable()
{
    local HashTable table;

    class'MockItem'.default.objectCount = 0;
    default.mockedItems.length  = 0;
    default.keys.length         = 0;
    table = HashTable(__().memory.Allocate(class'HashTable'));
    table.SetItem(NewKey(0), NewMockItem());
    table.SetItem(NewKey(1), NewMockItem());
    table.SetItem(NewKey(2), NewMockItem());
    table.SetItem(NewKey(3), NewMockItem());
    table.SetItem(NewKey(4), NewMockItem());
    table.SetItem(NewKey(5), NewMockItem());
    table.CreateItem(NewKey(6), class'MockItem');
    table.CreateItem(NewKey(7), class'MockItem');
    table.CreateItem(NewKey(8), class'MockItem');
    return table;
}

protected static function Test_ReferenceManagement()
{
    Context("Testing how `HashTable` handles reference counting.");
    SubTest_IncorrectGetRefCount(RecreateTestHashTable());
    SubTest_IncorrectTakeRefCount(RecreateTestHashTable());
    SubTest_IncorrectGetEntryRefCount(RecreateTestHashTable());
    SubTest_IncorrectTakeEntryRefCount(RecreateTestHashTable());
    SubTest_IncorrectEmptyRefCount(RecreateTestHashTable());
    SubTest_IncorrectGetKeysRefCount(RecreateTestHashTable());
}

protected static function SubTest_IncorrectGetRefCount(HashTable table)
{
    Issue("`HashTable` incorrectly handles reference count when storing" @
        "an item.");
    //  1 ref after creation + 1 ref in `HastTable` => 2
    TEST_ExpectTrue(default.mockedItems[0]._getRefCount() == 2);
    TEST_ExpectTrue(default.mockedItems[1]._getRefCount() == 2);
    TEST_ExpectTrue(default.mockedItems[2]._getRefCount() == 2);
    TEST_ExpectTrue(default.mockedItems[3]._getRefCount() == 2);
    TEST_ExpectTrue(default.mockedItems[4]._getRefCount() == 2);
    TEST_ExpectTrue(default.mockedItems[5]._getRefCount() == 2);

    Issue("`HashTable` incorrectly handles reference count when returning"
        @ "an item with `GetItem()`.");
    //  1 ref after creation + 1 ref in `HastTable` + 1 after `GetItem()` => 3
    TEST_ExpectTrue(table.GetItem(__().box.int(0))._getRefCount() == 3);
    TEST_ExpectTrue(table.GetItem(__().box.int(1))._getRefCount() == 3);
    TEST_ExpectTrue(table.GetItem(__().box.int(2))._getRefCount() == 3);
    TEST_ExpectTrue(table.GetItem(__().box.int(3))._getRefCount() == 3);
    TEST_ExpectTrue(table.GetItem(__().box.int(4))._getRefCount() == 3);
    TEST_ExpectTrue(table.GetItem(__().box.int(5))._getRefCount() == 3);
    //  1 ref in `HastTable` + 1 after `GetItem()` => 2
    TEST_ExpectTrue(table.GetItem(__().box.int(6))._getRefCount() == 2);
    TEST_ExpectTrue(table.GetItem(__().box.int(7))._getRefCount() == 2);
    TEST_ExpectTrue(table.GetItem(__().box.int(8))._getRefCount() == 2);
    //  1 ref after creation + 1 ref in `HastTable` => 2
    Issue("`HashTable` incorrectly handles reference count for keys when"
        @ "using `GetItem().");
    TEST_ExpectTrue(default.keys[0]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[1]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[2]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[3]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[4]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[5]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[6]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[7]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[8]._getRefCount() == 2);
}

protected static function SubTest_IncorrectTakeRefCount(HashTable table)
{
    Issue("`HashTable` incorrectly handles reference count when returning"
        @ "an item with `TakeItem()`.");
    //  1 ref after creation + 1 ref in `HastTable` => 2
    TEST_ExpectTrue(table.TakeItem(__().box.int(0))._getRefCount() == 2);
    TEST_ExpectTrue(table.TakeItem(__().box.int(1))._getRefCount() == 2);
    TEST_ExpectTrue(table.TakeItem(__().box.int(2))._getRefCount() == 2);
    TEST_ExpectTrue(table.TakeItem(__().box.int(3))._getRefCount() == 2);
    TEST_ExpectTrue(table.TakeItem(__().box.int(4))._getRefCount() == 2);
    TEST_ExpectTrue(table.TakeItem(__().box.int(5))._getRefCount() == 2);
    //  1 ref in `HastTable` => 1
    TEST_ExpectTrue(table.TakeItem(__().box.int(6))._getRefCount() == 1);
    TEST_ExpectTrue(table.TakeItem(__().box.int(7))._getRefCount() == 1);
    TEST_ExpectTrue(table.TakeItem(__().box.int(8))._getRefCount() == 1);
    //  Keys should get their refs decreased after the `Take()` command
    TEST_ExpectTrue(default.keys[0]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[1]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[2]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[3]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[4]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[5]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[6]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[7]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[8]._getRefCount() == 1);
}

protected static function SubTest_IncorrectGetEntryRefCount(HashTable table)
{
    Issue("`HashTable` incorrectly handles reference count when storing" @
        "an item.");
    Issue("`HashTable` incorrectly handles reference count when returning"
        @ "an item with `GetEntry()`.");
    //  1 ref after creation + 1 ref in `HastTable` + 1 from `GetEntry()` => 3
    TEST_ExpectTrue(table.GetEntry(__().box.int(0)).key._getRefCount() == 3);
    TEST_ExpectTrue(table.GetEntry(__().box.int(1)).key._getRefCount() == 3);
    TEST_ExpectTrue(table.GetEntry(__().box.int(2)).key._getRefCount() == 3);
    TEST_ExpectTrue(table.GetEntry(__().box.int(3)).key._getRefCount() == 3);
    TEST_ExpectTrue(table.GetEntry(__().box.int(4)).key._getRefCount() == 3);
    TEST_ExpectTrue(table.GetEntry(__().box.int(5)).key._getRefCount() == 3);
    //  1ref after creation + 1 ref in `HastTable` + 1 after `GetEntry()` => 3
    TEST_ExpectTrue(table.GetEntry(__().box.int(6)).key._getRefCount() == 3);
    TEST_ExpectTrue(table.GetEntry(__().box.int(7)).key._getRefCount() == 3);
    TEST_ExpectTrue(table.GetEntry(__().box.int(8)).key._getRefCount() == 3);

    //  1 ref after creation + 1 ref in `HastTable`
    //      + 2 from two `GetEntry()`s => 4
    TEST_ExpectTrue(table.GetEntry(__().box.int(0)).value._getRefCount() == 4);
    TEST_ExpectTrue(table.GetEntry(__().box.int(1)).value._getRefCount() == 4);
    TEST_ExpectTrue(table.GetEntry(__().box.int(2)).value._getRefCount() == 4);
    TEST_ExpectTrue(table.GetEntry(__().box.int(3)).value._getRefCount() == 4);
    TEST_ExpectTrue(table.GetEntry(__().box.int(4)).value._getRefCount() == 4);
    TEST_ExpectTrue(table.GetEntry(__().box.int(5)).value._getRefCount() == 4);
    //  1 ref in `HastTable` + 2 from two `GetEntry()`s => 3
    TEST_ExpectTrue(table.GetEntry(__().box.int(6)).value._getRefCount() == 3);
    TEST_ExpectTrue(table.GetEntry(__().box.int(7)).value._getRefCount() == 3);
    TEST_ExpectTrue(table.GetEntry(__().box.int(8)).value._getRefCount() == 3);
}

protected static function SubTest_IncorrectTakeEntryRefCount(HashTable table)
{
    Issue("`HashTable` incorrectly handles reference count when returning"
        @ "an item with `TakeEntry()`.");
    //  1 ref after creation + 1 ref in `HastTable` => 2
    TEST_ExpectTrue(table.TakeEntry(__().box.int(0)).value._getRefCount() == 2);
    TEST_ExpectTrue(table.TakeEntry(__().box.int(1)).value._getRefCount() == 2);
    TEST_ExpectTrue(table.TakeEntry(__().box.int(2)).value._getRefCount() == 2);
    TEST_ExpectTrue(table.TakeEntry(__().box.int(3)).value._getRefCount() == 2);
    TEST_ExpectTrue(table.TakeEntry(__().box.int(4)).value._getRefCount() == 2);
    TEST_ExpectTrue(table.TakeEntry(__().box.int(5)).value._getRefCount() == 2);
    //  1 ref in `HastTable` => 1
    TEST_ExpectTrue(table.TakeEntry(__().box.int(6)).value._getRefCount() == 1);
    TEST_ExpectTrue(table.TakeEntry(__().box.int(7)).value._getRefCount() == 1);
    TEST_ExpectTrue(table.TakeEntry(__().box.int(8)).value._getRefCount() == 1);
    //  Keys should get their refs unchanged after the `TakeEntry()` command
    TEST_ExpectTrue(default.keys[0]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[1]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[2]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[3]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[4]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[5]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[6]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[7]._getRefCount() == 2);
    TEST_ExpectTrue(default.keys[8]._getRefCount() == 2);
}

protected static function SubTest_IncorrectEmptyRefCount(HashTable table)
{
    Issue("`HashTable` incorrectly handles reference count when emptying"
        @ "`HashTable` with `Empty()`.");
    table.Empty();
    //  1 ref after creation + now 0 ref in `HastTable` => 1
    TEST_ExpectTrue(default.mockedItems[0]._getRefCount() == 1);
    TEST_ExpectTrue(default.mockedItems[1]._getRefCount() == 1);
    TEST_ExpectTrue(default.mockedItems[2]._getRefCount() == 1);
    TEST_ExpectTrue(default.mockedItems[3]._getRefCount() == 1);
    TEST_ExpectTrue(default.mockedItems[4]._getRefCount() == 1);
    TEST_ExpectTrue(default.mockedItems[5]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[0]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[1]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[2]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[3]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[4]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[5]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[6]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[7]._getRefCount() == 1);
    TEST_ExpectTrue(default.keys[8]._getRefCount() == 1);
}

protected static function SubTest_IncorrectGetKeysRefCount(HashTable table)
{
    Issue("`HashTable` incorrectly handles reference count when returning"
        @ "keys with `GetKeys()`.");
    table.GetKeys();
    //  1 ref after creation + 1 ref in `HastTable` + 1 after `GetKeys()` => 3
    TEST_ExpectTrue(default.keys[0]._getRefCount() == 3);
    TEST_ExpectTrue(default.keys[1]._getRefCount() == 3);
    TEST_ExpectTrue(default.keys[2]._getRefCount() == 3);
    TEST_ExpectTrue(default.keys[3]._getRefCount() == 3);
    TEST_ExpectTrue(default.keys[4]._getRefCount() == 3);
    TEST_ExpectTrue(default.keys[5]._getRefCount() == 3);
    TEST_ExpectTrue(default.keys[6]._getRefCount() == 3);
    TEST_ExpectTrue(default.keys[7]._getRefCount() == 3);
    TEST_ExpectTrue(default.keys[8]._getRefCount() == 3);
}

protected static function Test_Take()
{
    local HashTable.Entry       entry;
    local HashTable             array;
    local array<AcediaObject>   keys;

    class'MockItem'.default.objectCount = 0;
    array = HashTable(__().memory.Allocate(class'HashTable'));
    array.SetItem(__().box.int(0), NewMockItem());
    array.SetItem(__().box.int(1), NewMockItem());
    array.SetItem(__().box.int(2), NewMockItem());
    array.CreateItem(__().box.int(3), class'MockItem');
    array.CreateItem(__().box.int(4), class'MockItem');
    Context("Testing `TakeItem()`and `TakeEntry()` methods of `HashTable`.");
    Issue("`TakeItem()` does not return stored value.");
    TEST_ExpectTrue(array.TakeItem(__().box.int(0)).class == class'MockItem');
    TEST_ExpectTrue(array.TakeItem(__().box.int(3)).class == class'MockItem');

    Issue("`TakeItem()` does not remove value from the hash table.");
    TEST_ExpectNone(array.GetItem(__().box.int(0)));
    TEST_ExpectNone(array.GetItem(__().box.int(3)));

    Issue("`TakeEntry()` does not return stored key / value.");
    entry = array.TakeEntry(__().box.int(1));
    TEST_ExpectTrue(IntBox(entry.key).Get() == 1);
    TEST_ExpectTrue(entry.value.class == class'MockItem');
    entry = array.TakeEntry(__().box.int(4));
    TEST_ExpectTrue(IntBox(entry.key).Get() == 4);
    TEST_ExpectTrue(entry.value.class == class'MockItem');

    Issue("`TakeEntry()` does not remove value from the hash table.");
    TEST_ExpectNone(array.GetItem(__().box.int(1)));
    TEST_ExpectNone(array.GetItem(__().box.int(4)));

    Issue("Keys are not removed by `Take()` / `TakeEntry()` commands.");
    keys = array.GetKeys();
    TEST_ExpectTrue(keys.length == 1);
    TEST_ExpectTrue(IntBox(keys[0]).Get() == 2);
}

protected static function Test_LargeArray()
{
    local int           i;
    local AcediaObject  nextKey;
    local HashTable     array;

    Context("Testing storing large amount of elements in `HashTable`.");
    Issue("`HashTable` cannot handle large amount of elements.");
    array = HashTable(__().memory.Allocate(class'HashTable'));
    for (i = 0; i < 5000; i += 1) {
        if (i % 2 == 0) {
            nextKey = __().text.FromString("var" @ i);
        }
        else {
            nextKey = __().box.int(i * 56 - 435632);
        }
        array.SetItem(nextKey, __().ref.int(i));
    }
    for (i = 0; i < 5000; i += 1) {
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
    caseGroup   = "Collections"
    caseName    = "HashTable"
}