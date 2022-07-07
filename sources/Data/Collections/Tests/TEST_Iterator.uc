/**
 *  Set of tests for `Iterator` classes.
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
class TEST_Iterator extends TestCase
    abstract;

var const int           TESTED_ITEMS_AMOUNT;
var array<AcediaObject> items;
var array<byte>         seenFlags;

protected static function CreateItems()
{
    local int i;
    ResetFlags();
    default.items.length = 0;
    for (i = 0; i < default.TESTED_ITEMS_AMOUNT; i += 1) {
        default.items[default.items.length] = __().ref.float(i*2 + 1/i);
    }
}

protected static function ResetFlags()
{
    default.seenFlags.length = 0;
    default.seenFlags.length = default.TESTED_ITEMS_AMOUNT;
}

protected static function DoTestIterator(
    string              issueSubjectAllocation,
    string              issueSubjectAmount,
    CollectionIterator  iter)
{
    local int           i;
    local int           seenCount;
    local AcediaObject  nextObject;

    ResetFlags();
    Issue(issueSubjectAllocation);
    while (!iter.HasFinished())
    {
        nextObject = iter.Get();
        //  Create + insert into collection + get reference
        TEST_ExpectTrue(nextObject._getRefCount() == 3);
        if (iter.class == class'ArrayListIterator') {
            //  `ArrayList` creates keys to return on-the-fly
            TEST_ExpectTrue(iter.GetKey()._getRefCount() == 1);
        }
        else {
            //  Create + insert into collection + get reference
            TEST_ExpectTrue(iter.GetKey()._getRefCount() == 3);
        }
        for (i = 0; i < default.items.length; i += 1)
        {
            if (default.items[i] == nextObject)
            {
                if (default.seenFlags[i] == 0) {
                    seenCount += 1;
                }
                default.seenFlags[i] = 1;
                continue;
            }
        }
        iter.Next();
    }
    Issue(issueSubjectAmount);
    TEST_ExpectTrue(seenCount == default.TESTED_ITEMS_AMOUNT);
}

protected static function TESTS()
{
    CreateItems();
    Test_ArrayList();
    CreateItems();
    Test_HashTable();
    Test_IterationAndNone();
}

protected static function Test_ArrayList()
{
    local int                   i;
    local CollectionIterator    iter;
    local ArrayList             array;

    array = ArrayList(__().memory.Allocate(class'ArrayList'));
    iter = array.Iterate();
    Context("Testing iterator for `ArrayList`");
    Issue("`ArrayList` returns `none` iterator.");
    TEST_ExpectNotNone(iter);

    Issue("Iterator for empty `ArrayList` is not finished by default.");
    TEST_ExpectTrue(iter.HasFinished());

    Issue("Iterator for empty `ArrayList` does not return `none` as"
        @ "a current item.");
    TEST_ExpectNone(iter.Get());
    TEST_ExpectNone(iter.Next().Get());

    for (i = 0; i < default.items.length; i += 1) {
        array.AddItem(default.items[i]);
    }
    iter = array.Iterate();
    Issue("`ArrayList` returns `none` iterator.");
    TEST_ExpectNotNone(iter);

    Issue("`ArrayList`'s iterator iterates over incorrect set of items.");
    DoTestIterator(
        "`ArrayList`'s iterator incorrectly handles reference counting.",
        "`ArrayList`'s iterator iterates over incorrect set of items.",
        iter);
}

protected static function Test_HashTable()
{
    local int                   i;
    local CollectionIterator    iter;
    local HashTable             array;

    array = HashTable(__().memory.Allocate(class'HashTable'));
    iter = array.Iterate();
    Context("Testing iterator for `HashTable`");
    Issue("`HashTable` returns `none` iterator.");
    TEST_ExpectNotNone(iter);

    Issue("Iterator for empty `HashTable` is not finished by default.");
    TEST_ExpectTrue(iter.HasFinished());

    Issue("Iterator for empty `HashTable` does not return `none` as"
        @ "a current item.");
    TEST_ExpectNone(iter.Get());
    TEST_ExpectNone(iter.Next().Get());

    for (i = 0; i < default.items.length; i += 1) {
        array.SetItem(__().box.int(i), default.items[i]);
    }
    iter = array.Iterate();
    Issue("`HashTable` returns `none` iterator.");
    TEST_ExpectNotNone(iter);

    DoTestIterator(
        "`HashTable`'s iterator incorrectly handles reference counting.",
        "`HashTable`'s iterator iterates over incorrect set of items.",
        iter);
}

protected static function Test_IterationAndNone()
{
    Context("Testing how collections iterate over `none` references.");
    SubTest_ArrayListIterationAndNone();
    SubTest_HashTableIterationAndNone();
}

protected static function SubTest_ArrayListIterationAndNone()
{
    local bool                  sawNone;
    local int                   counter;
    local CollectionIterator    iter;
    local ArrayList             list;

    list = __().collections.EmptyArrayList();
    list.AddItem(__().box.int(1));
    list.AddItem(none);
    list.AddItem(__().box.int(3));
    list.AddItem(none);
    list.AddItem(__().box.int(5));
    Issue("`ArrayList` doesn't properly iterate over `none` items by default.");
    iter = list.Iterate();
    while (!iter.HasFinished())
    {
        sawNone = sawNone || (iter.Get() == none);
        counter += 1;
        iter.Next();
    }
    TEST_ExpectTrue(sawNone);
    TEST_ExpectTrue(counter == 5);

    Issue("`ArrayList` iterates over `none` items even after"
        @ "`LeaveOnlyNotNone()` call.");
    sawNone = false;
    counter = 0;
    iter = list.Iterate();
    iter.LeaveOnlyNotNone();
    while (!iter.HasFinished())
    {
        sawNone = sawNone || (iter.Get() == none);
        counter += 1;
        iter.Next();
    }
    TEST_ExpectFalse(sawNone);
    TEST_ExpectTrue(counter == 3);
}

protected static function SubTest_HashTableIterationAndNone()
{
    local bool                  sawNone;
    local int                   counter;
    local CollectionIterator    iter;
    local HashTable             table;

    table = __().collections.EmptyHashTable();
    table.SetItem(__().box.float(1.0), __().box.int(1));
    table.SetItem(__().box.float(0.3453), none);
    table.SetItem(__().box.float(423.3), __().box.int(3));
    table.SetItem(__().box.float(7), none);
    table.SetItem(__().box.float(1.1), __().box.int(5));
    Issue("`HashTable` doesn't properly iterate over `none` items by default.");
    iter = table.Iterate();
    while (!iter.HasFinished())
    {
        sawNone = sawNone || (iter.Get() == none);
        counter += 1;
        iter.Next();
    }
    TEST_ExpectTrue(sawNone);
    TEST_ExpectTrue(counter == 5);

    Issue("`HashTable` iterates over `none` items even after"
        @ "`LeaveOnlyNotNone()` call.");
    sawNone = false;
    counter = 0;
    iter = table.Iterate();
    iter.LeaveOnlyNotNone();
    while (!iter.HasFinished())
    {
        sawNone = sawNone || (iter.Get() == none);
        counter += 1;
        iter.Next();
    }
    TEST_ExpectFalse(sawNone);
    TEST_ExpectTrue(counter == 3);
}

defaultproperties
{
    caseGroup   = "Collections"
    caseName    = "Iterator"
    TESTED_ITEMS_AMOUNT = 100
}