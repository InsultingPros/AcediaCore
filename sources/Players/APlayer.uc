/**
 *      Represents a connected player connection and serves to provide access to
 *  both it's server data and in-game pawn representation.
 *      Unlike `User`, - changes when player reconnects the server.
 *      This object SHOULD NOT be created manually, please rely on
 *  `AcediaCore` for that.
 *      Killing floor 1 note: inherently linked to
 *  a particular `PlayerController`.
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

//  How this `APlayer` is identified by the server
var private User                identity;
//  Controller 
var private PlayerController    ownerController;

//  Shortcut to `ConnectionEvents`, so that we don't have to write
//  `class'ConnectionEvents'` every time.
var const class<PlayerEvents> events;

/**
 *  Initializes caller `APlayer`. Should be called right after `APlayer`
 *  was spawned.
 *
 *      Initialization should (and can) only be done once.
 *      Before a `Initialize()` call, any other method calls on such `User`
 *  must be considerate to have undefined behavior.
 *
 *  @param  newController   Controller that caller `APLayer` will correspond to.
 */
public final function Initialize(PlayerController newController)
{
    ownerController = initOwnerController;
    identity = _.users.FetchByIDHash(initOwnerController.GetPlayerIDHash());
    events.static.CallPlayerConnected(self);
}

/**
 *  Returns associated controller.
 *
 *  @return Controller that caller `APLayer` corresponds to.
 */
public final function PlayerController GetController()
{
    return ownerController;
}

/**
 *  IMPORTANT: this is a helper function that is not supposed to be
 *  called manually.
 *
 *  Causes `APlayer` to update it's inner state and should be triggered by
 *  various outside events. A necessary work-around, since we cannot make
 *  an event to trigger a protected function.
 */
public final function Update()
{
    if (ownerController == none) {
        events.static.CallPlayerDisconnected(self);
        Destroy();
    }
}

//  This is one of the most important objects for `Acedia` and should be kept
//  up-to-date as much as possible.
event Tick(float delta)
{
    Update();
}

defaultproperties
{
    events = class'PlayerEvents'
}