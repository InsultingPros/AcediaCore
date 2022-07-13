/**
 *  Signal class for `AcediaEnvironment`'s `FeatureDisabled()` signal.
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
class Environment_FeatureDisabled_Signal extends Signal;

public final function Emit(class<Feature> disabledFeatureClass)
{
    local Slot nextSlot;
    StartIterating();
    nextSlot = GetNextSlot();
    while (nextSlot != none)
    {
        Environment_FeatureDisabled_Slot(nextSlot).connect(disabledFeatureClass);
        nextSlot = GetNextSlot();
    }
    CleanEmptySlots();
}

defaultproperties
{
    relatedSlotClass = class'Environment_FeatureDisabled_Slot'
}