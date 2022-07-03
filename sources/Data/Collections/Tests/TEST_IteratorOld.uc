/**
 *  Set of tests for `Iterator` classes.
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
class TEST_IteratorOld extends TestCase
    abstract;

var const int           TESTED_ITEMS_AMOUNT;
var array<AcediaObject> items;
var array<byte>         seenFlags;

protected static function CreateItems()
{
    local int i;
    ResetFlags();
    for (i = 0; i < default.TESTED_ITEMS_AMOUNT; i += 1) {
        default.items[default.items.length] = __().ref.float(i*2 + 1/i);
    }
}

protected static function ResetFlags()
{
    default.seenFlags.length = 0;
    default.seenFlags.length = default.TESTED_ITEMS_AMOUNT;
}

protected static function DoTestIterator(Iter iter)
{
    local int           i;
    local int           seenCount;
    local AcediaObject  nextObject;
    ResetFlags();
    while (!iter.HasFinished())
    {
        nextObject = iter.Get();
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
    TEST_ExpectTrue(seenCount == default.TESTED_ITEMS_AMOUNT);
}

protected static function TESTS()
{
    //  Prepare
    CreateItems();
    //  Test
    Test_DynamicArray();
    Test_AssociativeArray();
}

protected static function Test_DynamicArray()
{
    local int           i;
    local Iter          iter;
    local DynamicArray  array;
    array = DynamicArray(__().memory.Allocate(class'DynamicArray'));
    iter = array.Iterate();
    Context("Testing iterator for `DynamicArray`");
    Issue("`DynamicArray` returns `none` iterator.");
    TEST_ExpectNotNone(iter);

    Issue("Iterator for empty `DynamicArray` is not finished by default.");
    TEST_ExpectTrue(iter.HasFinished());

    Issue("Iterator for empty `DynamicArray` does not return `none` as"
        @ "a current item.");
    TEST_ExpectNone(iter.Get());
    TEST_ExpectNone(iter.Next().Get());

    for (i = 0; i < default.items.length; i += 1) {
        array.AddItem(default.items[i]);
    }
    iter = array.Iterate();
    Issue("`DynamicArray` returns `none` iterator.");
    TEST_ExpectNotNone(iter);

    Issue("`DynamicArray`'s iterator iterates over incorrect set of items.");
    DoTestIterator(iter);
}

protected static function Test_AssociativeArray()
{
    local int               i;
    local Iter              iter;
    local AssociativeArray  array;
    array = AssociativeArray(__().memory.Allocate(class'AssociativeArray'));
    iter = array.Iterate();
    Context("Testing iterator for `AssociativeArray`");
    Issue("`AssociativeArray` returns `none` iterator.");
    TEST_ExpectNotNone(iter);

    Issue("Iterator for empty `AssociativeArray` is not finished by default.");
    TEST_ExpectTrue(iter.HasFinished());

    Issue("Iterator for empty `AssociativeArray` does not return `none` as"
        @ "a current item.");
    TEST_ExpectNone(iter.Get());
    TEST_ExpectNone(iter.Next().Get());

    for (i = 0; i < default.items.length; i += 1) {
        array.SetItem(__().box.int(i), default.items[i]);
    }
    iter = array.Iterate();
    Issue("`AssociativeArray` returns `none` iterator.");
    TEST_ExpectNotNone(iter);

    Issue("`AssociativeArray`'s iterator iterates over incorrect set of"
        @ "items.");
    DoTestIterator(iter);
}

defaultproperties
{
    caseGroup = "Collections"
    caseName = "IteratorOld"
    TESTED_ITEMS_AMOUNT = 100
}