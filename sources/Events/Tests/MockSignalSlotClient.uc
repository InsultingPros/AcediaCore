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

var private int value;

public final function SetValue(int newValue)
{
    value = newValue;
}

//  Return `SMockSlot` for testing purposes
public final function MockSlot AddToSignal(MockSignal signal)
{
    local MockSlot slot;
    slot = MockSlot(signal.NewSlot(self));
    slot.connect = Handler;
    return slot;
}

private final function int Handler(int inputValue, optional bool doSubtract)
{
    if (doSubtract) {
        return inputValue - value;
    }
    return inputValue + value;
}

defaultproperties
{
}