/**
 *  Signal class implementation for `GameRulesAPI`'s
 *  `OnOverridePickupQuerySignal` signal.
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
class GameRules_OnOverridePickupQuery_Signal extends Signal;

public function bool Emit(Pawn other, Pickup item, out byte allowPickup)
{
    local Slot  nextSlot;
    local bool  shouldOverride;
    StartIterating();
    nextSlot = GetNextSlot();
    while (nextSlot != none)
    {
        shouldOverride = GameRules_OnOverridePickupQuery_Slot(nextSlot)
            .connect(other, item, allowPickup);
        if (shouldOverride && !nextSlot.IsEmpty())
        {
            CleanEmptySlots();
            return shouldOverride;
        }
        nextSlot = GetNextSlot();
    }
    CleanEmptySlots();
    return false;
}

defaultproperties
{
    relatedSlotClass = class'GameRules_OnOverridePickupQuery_Slot'
}