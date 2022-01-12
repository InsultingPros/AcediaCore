/**
 *  Signal class implementation for `ChatAPI`'s `OnMessage` signal.
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
class ChatAPI_OnMessage_Signal extends Signal;

public final function bool Emit(
    EPlayer     sender,
    MutableText message,
    bool        teamMessage)
{
    local Slot  nextSlot;
    local bool  nextReply;
    StartIterating();
    nextSlot = GetNextSlot();
    while (nextSlot != none)
    {
        nextReply = ChatAPI_OnMessage_Slot(nextSlot)
            .connect(sender, message, teamMessage);
        if (!nextReply && !nextSlot.IsEmpty())
        {
            CleanEmptySlots();
            return false;
        }
        nextSlot = GetNextSlot();
    }
    CleanEmptySlots();
    return true;
}

defaultproperties
{
    relatedSlotClass = class'ChatAPI_OnMessage_Slot'
}