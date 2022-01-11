/**
 *  Signal class implementation for `PlayerAPI`'s `OnNewPlayer` signal.
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
class PlayerAPI_OnNewPlayer_Signal extends Signal;

public final function Emit(EPlayer newPlayer)
{
    local Slot nextSlot;
    StartIterating();
    nextSlot = GetNextSlot();
    while (nextSlot != none)
    {
        PlayerAPI_OnNewPlayer_Slot(nextSlot).connect(newPlayer);
        nextSlot = GetNextSlot();
    }
    CleanEmptySlots();
}

defaultproperties
{
    relatedSlotClass = class'PlayerAPI_OnNewPlayer_Slot'
}