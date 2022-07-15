/**
 *  Signal class implementation for `GameRulesAPI`'s
 *  `OnPreventDeathSignal` signal.
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
class GameRules_OnPreventDeath_Signal extends Signal;

public function bool Emit(
    Pawn                killed,
    Controller          killer,
    class<DamageType>   damageType,
    Vector              hitLocation)
{
    local Slot  nextSlot;
    local bool  shouldPrevent;
    StartIterating();
    nextSlot = GetNextSlot();
    while (nextSlot != none)
    {
        shouldPrevent = GameRules_OnPreventDeath_Slot(nextSlot)
            .connect(killed, killer, damageType, hitLocation);
        if (shouldPrevent && !nextSlot.IsEmpty())
        {
            CleanEmptySlots();
            return shouldPrevent;
        }
        nextSlot = GetNextSlot();
    }
    CleanEmptySlots();
    return false;
}

defaultproperties
{
    relatedSlotClass = class'GameRules_OnPreventDeath_Slot'
}