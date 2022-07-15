/**
 *  Signal class implementation for `GameRulesAPI`'s `OnCheckEndGame` signal.
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
class GameRules_OnCheckEndGame_Signal extends Signal;

public function bool Emit(
    PlayerReplicationInfo   winner,
    string                  reason)
{
    local Slot  nextSlot;
    local bool  result, nextReply;
    StartIterating();
    nextSlot = GetNextSlot();
    result = true;
    while (nextSlot != none)
    {
        nextReply = GameRules_OnCheckEndGame_Slot(nextSlot)
            .connect(winner, reason);
        if (!nextReply && !nextSlot.IsEmpty()) {
            result = result && nextReply;
        }
        nextSlot = GetNextSlot();
    }
    CleanEmptySlots();
    return result;
}

defaultproperties
{
    relatedSlotClass = class'GameRules_OnCheckEndGame_Slot'
}