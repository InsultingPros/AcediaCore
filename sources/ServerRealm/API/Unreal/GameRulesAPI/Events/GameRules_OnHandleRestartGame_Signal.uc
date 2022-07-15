/**
 *  Signal class implementation for `GameRulesAPI`'s
 *  `OnHandleRestartGame` signal.
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
class GameRules_OnHandleRestartGame_Signal extends Signal;

public function bool Emit()
{
    local Slot  nextSlot;
    local bool  doPrevent, nextResult;
    StartIterating();
    nextSlot = GetNextSlot();
    while (nextSlot != none)
    {
        nextResult = GameRules_OnHandleRestartGame_Slot(nextSlot).connect();
        if (nextResult && !nextSlot.IsEmpty()) {
            doPrevent = doPrevent || nextResult;
        }
        nextSlot = GetNextSlot();
    }
    CleanEmptySlots();
    return doPrevent;
}

defaultproperties
{
    relatedSlotClass = class'GameRules_OnHandleRestartGame_Slot'
}