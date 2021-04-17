/**
 *  Object that provides a signal handler for testing signal/slot functionality
 *  of Acedia.
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
class MockSignalSlotClient extends AcediaObject;

//  Remember `Signal` and `Slot` for testing purposes
var private MockSignal  usedSignal;
var private MockSlot    usedSlot;
var private int         value;

public final function SetValue(int newValue)
{
    value = newValue;
}

public final function DisconnectMe(MockSignal signal)
{
    if (signal != none) {
        signal.NewSlot(self).Disconnect();
    }
}

//  Return `SMockSlot` for testing purposes
public final function MockSlot AddToSignal(MockSignal signal)
{
    local MockSlot slot;
    if (signal == none) {
        return none;
    }
    slot = MockSlot(signal.NewSlot(self));
    slot.connect = Handler;
    return slot;
}

public final function MockSlot AddToSignal_AddNewSlot(MockSignal signal)
{
    local MockSlot slot;
    if (signal == none) {
        return none;
    }
    usedSignal = signal;
    slot = MockSlot(signal.NewSlot(self));
    slot.connect = Handler_AddNewSlot;
    return slot;
}

public final function MockSlot AddToSignal_DestroySlot(MockSignal signal)
{
    if (signal == none) {
        return none;
    }
    usedSlot = MockSlot(signal.NewSlot(self));
    usedSlot.connect = Handler_DestroySlot;
    return usedSlot;
}

private final function int Handler(int inputValue, optional bool doSubtract)
{
    if (doSubtract) {
        return inputValue - value;
    }
    return inputValue + value;
}

private final function int Handler_AddNewSlot(
    int             inputValue,
    optional bool   doSubtract)
{
    local MockSignalSlotClient newClient;
    if (usedSignal == none) {
        return inputValue;
    }
    newClient = MockSignalSlotClient(
        _.memory.Allocate(class'MockSignalSlotClient'));
    newClient.SetValue(value);
    newClient.AddToSignal(usedSignal);
    usedSignal = none;
    return inputValue;
}

private final function int Handler_DestroySlot(
    int             inputValue,
    optional bool   doSubtract)
{
    if (usedSlot != none) {
        usedSlot.FreeSelf();
    }
    usedSlot = none;
    return inputValue;
}

defaultproperties
{
}