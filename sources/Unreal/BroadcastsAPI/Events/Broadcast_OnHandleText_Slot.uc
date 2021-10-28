/**
 *  Slot class implementation for `BroadcastAPI`'s `OnHandleText` signal.
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
class Broadcast_OnHandleText_Slot extends Slot;

delegate bool connect(
    Actor       sender,
    out string  message,
    name        type,
    bool        teamMessage)
{
    DummyCall();
    return true;
}

protected function Constructor()
{
    connect = none;
}

protected function Finalizer()
{
    super.Finalizer();
    connect = none;
}

defaultproperties
{
}