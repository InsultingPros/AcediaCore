/**
 *      Objects of this class are meant to represent a "server user":
 *  not a particular `PlayerController`, but an entity that server would
 *  recognize to be the same person even after reconnections.
 *      It is supposed to store and recognize various stats and
 *  server privileges.
 *      Copyright 2020 Anton Tarasenko
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
class APlayer extends AcediaActor;

var private User                identity;
var private PlayerController    ownerController;

//  Shortcut to `ConnectionEvents`, so that we don't have to write
//  `class'ConnectionEvents'` every time.
var const class<PlayerEvents> events;

public final function Initialize(PlayerController initOwnerController)
{
    ownerController = initOwnerController;
    identity = _.users.FetchByIDHash(initOwnerController.GetPlayerIDHash());
    events.static.CallPlayerConnected(self);
}

public final function PlayerController GetController()
{
    return ownerController;
}

public final function Update()
{
    if (ownerController == none) {
        events.static.CallPlayerDisconnected(self);
        Destroy();
    }
}

event Tick(float delta)
{
    Update();
}

defaultproperties
{
    events = class'PlayerEvents'
}