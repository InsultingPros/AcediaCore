/**
 *  `PlayerService`'s listener for events generated by 'ConnectionService'.
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
class ConnectionListener_Player extends ConnectionListenerBase;

static function ConnectionEstablished(ConnectionService.Connection connection)
{
    local PlayerService service;
    service = PlayerService(class'PlayerService'.static.Require());
    if (service == none) {
        __().logger.Fatal("Cannot start `PlayerService` service"
            @ "Acedia will not properly work from now on.");
        return;
    }
    service.RegisterPlayer(connection.controllerReference);
}

static function ConnectionLost(ConnectionService.Connection connection)
{
    local PlayerService service;
    service = PlayerService(class'PlayerService'.static.Require());
    if (service == none) {
        __().logger.Fatal("Cannot start `PlayerService` service"
            @ "Acedia will not properly work from now on.");
        return;
    }
    service.UpdateAllPlayers();
}

defaultproperties
{
    relatedEvents = class'ConnectionEvents'
}