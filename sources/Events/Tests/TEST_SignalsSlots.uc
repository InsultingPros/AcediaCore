/**
 *  Set of tests for signal/slot functionality of Acedia.
 *      Copyright 2021 Anton Tarasenko
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
class TEST_SignalsSlots extends TestCase
    abstract;

protected static function TESTS()
{
    Context("Testing regularly connecting and disconnecting slots to"
        @ "a signal.");
    Test_Connecting();
    Test_Disconnecting();
    Context("Testing how signals and slots system handles deallocations and"
        @ "unexpected changes to managed objects.");
    Test_DeallocSlots();
    Test_EmptySlots();
    Test_DeallocReceivers();
}

protected static function Test_Connecting()
{
    local int                           i;
    local MockSignal                    signal;
    local MockSignalSlotClient          nextObject;
    local array<MockSignalSlotClient>   objects;
    Issue("Slots are not connected correctly.");
    signal = MockSignal(__().memory.Allocate(class'MockSignal'));
    for (i = 0; i < 100; i += 1)
    {
        nextObject = MockSignalSlotClient(
            __().memory.Allocate(class'MockSignalSlotClient'));
        objects[objects.length] = nextObject;
        nextObject.AddToSignal(signal);
        nextObject.SetValue(i + 1);
    }
    //  1 + ... + 100 = 100 * 101 / 2 = 5050
    //  5050 + 100 = 5150
    TEST_ExpectTrue(signal.Emit(100) == 5150);
    //  -5050 + 20 = -5030
    TEST_ExpectTrue(signal.Emit(20, true) == -5030);
    __().memory.Free(signal);

    Issue("Several slots from the same object are not connected correctly.");
    signal = MockSignal(__().memory.Allocate(class'MockSignal'));
    //  Object with `SetValue(100)`
    nextObject.AddToSignal(signal);
    nextObject.AddToSignal(signal);
    nextObject.AddToSignal(signal);
    TEST_ExpectTrue(signal.Emit(400, true) == 100);
    __().memory.FreeMany(objects);
}

protected static function Test_Disconnecting()
{
    local int                           i;
    local MockSignal                    signal;
    local MockSignalSlotClient          nextObject;
    local array<MockSignalSlotClient>   objects;
    Issue("Slots are not disconnected correctly.");
    signal = MockSignal(__().memory.Allocate(class'MockSignal'));
    for (i = 0; i < 100; i += 1)
    {
        nextObject = MockSignalSlotClient(
            __().memory.Allocate(class'MockSignalSlotClient'));
        objects[objects.length] = nextObject;
        nextObject.AddToSignal(signal);
        nextObject.SetValue(i + 1);
    }
    //  Now disconnect the ones with odd values
    for (i = 0; i < 100; i += 2) {
        signal.Disconnect(objects[i]);  //  value is `i + 1`, so 1, 3, 5,...
    }
    //  2 + 4 + 6 + ... + 100 = 2 * (1 + ... + 50) = 50 * 51 = 2550
    //  2550 + 50 = 2600
    TEST_ExpectTrue(signal.Emit(50) == 2600);
    //  -2550 + 550 = -2000
    TEST_ExpectTrue(signal.Emit(550, true) == -2000);
    __().memory.Free(signal);
    __().memory.FreeMany(objects);
}

protected static function Test_DeallocSlots()
{
    local int                           i;
    local MockSignal                    signal;
    local MockSignalSlotClient          nextObject;
    local array<MockSlot>               slots;
    local array<MockSignalSlotClient>   objects;
    Issue("Deallocated slots are still being called.");
    signal = MockSignal(__().memory.Allocate(class'MockSignal'));
    for (i = 0; i < 100; i += 1)
    {
        nextObject = MockSignalSlotClient(
            __().memory.Allocate(class'MockSignalSlotClient'));
        objects[objects.length] = nextObject;
        slots[slots.length] = nextObject.AddToSignal(signal);
        nextObject.SetValue(i + 1);
    }
    //  Now disconnect the ones with odd values
    for (i = 0; i < 100; i += 2) {
        slots[i].FreeSelf();    //  value is `i + 1`, so 1, 3, 5,...
    }
    //  2 + 4 + 6 + ... + 100 = 2 * (1 + ... + 50) = 50 * 51 = 2550
    //  2550 + 50 = 2600
    TEST_ExpectTrue(signal.Emit(50) == 2600);
    //  -2550 + 550 = -2000
    TEST_ExpectTrue(signal.Emit(550, true) == -2000);
    __().memory.Free(signal);
    __().memory.FreeMany(objects);
}

protected static function Test_EmptySlots()
{
    local int                           i;
    local bool                          slotsAreNotDeallocated;
    local MockSignal                    signal;
    local MockSignalSlotClient          nextObject;
    local array<MockSlot>               slots;
    local array<MockSignalSlotClient>   objects;
    Issue("Slots with emptied delegates are still being called.");
    signal = MockSignal(__().memory.Allocate(class'MockSignal'));
    for (i = 0; i < 100; i += 1)
    {
        nextObject = MockSignalSlotClient(
            __().memory.Allocate(class'MockSignalSlotClient'));
        objects[objects.length] = nextObject;
        slots[slots.length] = nextObject.AddToSignal(signal);
        nextObject.SetValue(i + 1);
    }
    //  Now disconnect the ones with odd values
    for (i = 0; i < 100; i += 2) {
        slots[i].connect = none;    //  value is `i + 1`, so 1, 3, 5,...
    }
    //  2 + 4 + 6 + ... + 100 = 2 * (1 + ... + 50) = 50 * 51 = 2550
    //  2550 + 50 = 2600
    TEST_ExpectTrue(signal.Emit(50) == 2600);
    //  -2550 + 550 = -2000
    TEST_ExpectTrue(signal.Emit(550, true) == -2000);
    for (i = 0; i < 100; i += 2)
    {
        if (slots[i].IsAllocated())
        {
            slotsAreNotDeallocated = true;
            break;
        }
    }
    Issue("Slots with emptied delegates are not deallocated.");
    TEST_ExpectFalse(slotsAreNotDeallocated);
    __().memory.Free(signal);
    __().memory.FreeMany(objects);
}

protected static function Test_DeallocReceivers()
{
    local int                           i;
    local bool                          slotsAreNotDeallocated;
    local MockSignal                    signal;
    local MockSignalSlotClient          nextObject;
    local array<MockSlot>               slots;
    local array<MockSignalSlotClient>   objects;
    Issue("Deallocated receivers still receive messages.");
    signal = MockSignal(__().memory.Allocate(class'MockSignal'));
    for (i = 0; i < 100; i += 1)
    {
        nextObject = MockSignalSlotClient(
            __().memory.Allocate(class'MockSignalSlotClient'));
        objects[objects.length] = nextObject;
        slots[slots.length] = nextObject.AddToSignal(signal);
        nextObject.SetValue(i + 1);
    }
    //  Now disconnect the ones with odd values
    for (i = 0; i < 100; i += 2) {
        objects[i].FreeSelf();   //  value is `i + 1`, so 1, 3, 5,...
    }
    //  2 + 4 + 6 + ... + 100 = 2 * (1 + ... + 50) = 50 * 51 = 2550
    //  2550 + 50 = 2600
    TEST_ExpectTrue(signal.Emit(50) == 2600);
    //  -2550 + 550 = -2000
    TEST_ExpectTrue(signal.Emit(550, true) == -2000);
    for (i = 0; i < 100; i += 2)
    {
        if (slots[i].IsAllocated())
        {
            slotsAreNotDeallocated = true;
            break;
        }
    }
    Issue("Slots with deallocated receivers are not deallocated.");
    TEST_ExpectFalse(true);
    __().memory.Free(signal);
    __().memory.FreeMany(objects);
}

defaultproperties
{
    caseGroup   = "Events"
    caseName    = "Signals and slots"
}