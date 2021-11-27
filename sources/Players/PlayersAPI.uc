/**
 *      API that provides functions for working player references (`APlayer`).
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
class PlayersAPI extends AcediaObject
    dependson(Text);

//  Writer that can be used to write into this player's console
var private ConsoleWriter   consoleInstance;
//  Remember version to reallocate writer in case someone deallocates it
var private int             consoleLifeVersion;

protected function Constructor()
{
    local ConnectionService service;
    service = ConnectionService(class'ConnectionService'.static.Require());
    service.OnConnectionEstablished(self).connect = MakePlayer;
}

protected function Finalizer()
{
    local ConnectionService service;
    service = ConnectionService(class'ConnectionService'.static.Require());
    service.OnConnectionEstablished(self).Disconnect();
}

private final function MakePlayer(ConnectionService.Connection newConnection)
{
    local APlayer       newPlayer;
    local Text          textIdHash;
    local PlayerService service;
    //  Make new player controller and link it to `newConnection`
    newPlayer = APlayer(_.memory.Allocate(class'APlayer'));
    service = PlayerService(class'PlayerService'.static.Require());
    service.RegisterPair(newConnection.controllerReference, newPlayer);
    //  Initialize new `APlayer`
    textIdHash = _.text.FromString(newConnection.idHash);
    newPlayer.Initialize(textIdHash);
    textIdHash.FreeSelf();
}

/**
 *  Return `ConsoleWriter` that can be used to write into every player's
 *  console.
 *
 *  Provided that returned object is never deallocated - returns the same object
 *  with each call, otherwise can allocate new instance of `ConsoleWriter`.
 *
 *  @return `ConsoleWriter` that can be used to write into every player's
 *      console. Returned object should not be deallocated, but it is
 *      guaranteed to be valid for non-disconnected players.
 */
public final function ConsoleWriter Console()
{
    if (    consoleInstance == none
        ||  consoleInstance.GetLifeVersion() != consoleLifeVersion)
    {
        consoleInstance = _.console.ForAll();
        consoleLifeVersion = consoleInstance.GetLifeVersion();
    }
    //  Set everybody as a target in case someone messed with this setting
    return consoleInstance.ForAll();
}

/**
 *  Fetches current array of all players.
 *
 *  @return Current array of all players.
 *      Guaranteed to not contain `none` values.
 */
public final function array<APlayer> GetAll()
{
    local PlayerService     service;
    local array<APlayer>    emptyResult;
    service = PlayerService(class'PlayerService'.static.GetInstance());
    if (service != none) {
        return service.GetAllPlayers();
    }
    return emptyResult;
}

defaultproperties
{
}