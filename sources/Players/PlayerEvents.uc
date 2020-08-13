/**
 *  Event generator for 'ConnectionService'.
 *      Copyright 2019 Anton Tarasenko
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
class PlayerEvents extends Events
    abstract;

static function CallPlayerConnected(APlayer newPlayer)
{
    local int i;
    local array< class<Listener> > listeners;
    listeners = GetListeners();
    for (i = 0; i < listeners.length; i += 1)
    {
        class<PlayerListenerBase>(listeners[i])
            .static.PlayerConnected(newPlayer);
    }
}

static function CallPlayerDisconnected(APlayer lostPlayer)
{
    local int i;
    local array< class<Listener> > listeners;
    listeners = GetListeners();
    for (i = 0; i < listeners.length; i += 1)
    {
        class<PlayerListenerBase>(listeners[i])
            .static.PlayerDisconnected(lostPlayer);
    }
}

defaultproperties
{
    relatedListener = class'PlayerListenerBase'
    connectedServiceClass = class'PlayerService'
}