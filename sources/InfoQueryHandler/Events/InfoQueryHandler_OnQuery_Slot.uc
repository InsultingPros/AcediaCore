/**
 *  Slot class implementation for `InfoQueryHandler`'s signals.
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
class InfoQueryHandler_OnQuery_Slot extends Slot;

var private Text linkedHeader;

delegate connect(ConsoleWriter writer)
{
    DummyCall();
}

protected function Constructor()
{
    connect = none;
}

protected function Finalizer()
{
    super.Finalizer();
    connect = none;
    _.memory.Free(linkedHeader);
    linkedHeader = none;
}

public final function InitializeHeader(BaseText header)
{
    if (linkedHeader != none) {
        return;
    }
    if (header != none) {
        linkedHeader = header.Copy();
    }
    else {
        linkedHeader = P("").Copy();
    }
}

public final function Text GetHeader()
{
    if (linkedHeader != none) {
        return linkedHeader.Copy();
    }
    return none;
}

defaultproperties
{
}