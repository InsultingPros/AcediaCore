/**
 *      API that provides functions for working player references (`EPlayer`).
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
    dependson(ConnectionService)
    dependson(Text);

//  Writer that can be used to write into this player's console
var private ConsoleWriter   consoleInstance;
//  Remember version to reallocate writer in case someone deallocates it
var private int             consoleLifeVersion;

var protected bool connectedToConnectionServer;
var protected PlayerAPI_OnNewPlayer_Signal  onNewPlayerSignal;
var protected PlayerAPI_OnLostPlayer_Signal onLostPlayerSignal;

protected function Constructor()
{
    onNewPlayerSignal = PlayerAPI_OnNewPlayer_Signal(
        _.memory.Allocate(class'PlayerAPI_OnNewPlayer_Signal'));
    onLostPlayerSignal = PlayerAPI_OnLostPlayer_Signal(
        _.memory.Allocate(class'PlayerAPI_OnLostPlayer_Signal'));
}

protected function Finalizer()
{
    local ConnectionService service;
    connectedToConnectionServer = false;
    if (class'ConnectionService'.static.IsRunning())
    {
        service = ConnectionService(class'ConnectionService'.static.Require());
        service.OnConnectionEstablished(self).Disconnect();
        service.OnConnectionLost(self).Disconnect();
    }
    _.memory.Free(onNewPlayerSignal);
    _.memory.Free(onLostPlayerSignal);
    onNewPlayerSignal   = none;
    onLostPlayerSignal  = none;
}

/**
 *  Signal that will be emitted once new player is connected.
 *
 *  [Signature]
 *  void <slot>(EPlayer newPlayer)
 *
 *  @param  handle  Base `EPlayer` interface for the newly connected player.
 *      Each handler will receive its own copy of `EPlayer` that has to
 *      be deallocated.
 */
/* SIGNAL */
public function PlayerAPI_OnNewPlayer_Slot OnNewPlayer(
    AcediaObject receiver)
{
    ConnectToConnectionService();
    return PlayerAPI_OnNewPlayer_Slot(onNewPlayerSignal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted once player has disconnected.
 *
 *  [Signature]
 *  void <slot>(User identity)
 *
 *  @param  identity    `User` object that corresponds to
 *      the disconnected player.
 */
/* SIGNAL */
public function PlayerAPI_OnLostPlayer_Slot OnLostPlayerHandle(
    AcediaObject receiver)
{
    ConnectToConnectionService();
    return PlayerAPI_OnLostPlayer_Slot(onLostPlayerSignal.NewSlot(receiver));
}

/**
 *  Return `ConsoleWriter` that can be used to write into every player's
 *  console.
 *
 *  Provided that returned object is never deallocated - method returns
 *  the same object with each call, otherwise can allocate new instance of
 *  `ConsoleWriter`.
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

private final function ConnectToConnectionService()
{
    local ConnectionService service;
    if (connectedToConnectionServer) {
        return;
    }
    service = ConnectionService(class'ConnectionService'.static.Require());
    service.OnConnectionEstablished(self).connect   = AnnounceNewPlayer;
    service.OnConnectionLost(self).connect          = AnnounceLostPlayer;
    connectedToConnectionServer = true;
}

private final function AnnounceNewPlayer(
    ConnectionService.Connection newConnection)
{
    if (onNewPlayerSignal == none) {
        return;
    }
    onNewPlayerSignal.Emit(FromController(newConnection.controllerReference));
}

private final function AnnounceLostPlayer(
    ConnectionService.Connection lostConnection)
{
    local Text idHash;
    local User lostIdentity;
    if (onLostPlayerSignal == none) {
        return;
    }
    idHash = _.text.FromString(lostConnection.idHash);
    lostIdentity = _.users.FetchByIDHash(idHash);
    _.memory.Free(idHash);
    idHash = none;
    onLostPlayerSignal.Emit(lostIdentity);
}

/**
 *  Creates `EPlayer` instance from passed `PlayerController` reference.
 *  Can fail if passed parameter is not `controller`.
 *
 *  @param  controller  `PlayerController` for which to create
 *      `EPlayer` instance. Should not be `none`.
 *  @return Instance of `EPlayer` that refers to passed `controller`.
 *      Returns `none` iff `controller == none`.
 */
public final /* unreal */ function EPlayer FromController(
    PlayerController controller)
{
    local EPlayer result;
    result = EPlayer(_.memory.Allocate(class'EPlayer'));
    result.Initialize(controller);
    return result;
}

/**
 *  Fetches current array of all players.
 *
 *  @return Current array of all players.
 *      Guaranteed to not contain `none` values.
 */
public final function array<EPlayer> GetAll()
{
    local int                                   i;
    local array<EPlayer>                        result;
    local ConnectionService                     service;
    local array<ConnectionService.Connection>   activeConnections;
    local PlayerController                      nextControllerReference;
    service = ConnectionService(class'ConnectionService'.static.Require());
    activeConnections = service.GetActiveConnections();
    for (i = 0; i < activeConnections.length; i += 1)
    {
        nextControllerReference = activeConnections[i].controllerReference;
        if (nextControllerReference != none) {
            result[result.length] = FromController(nextControllerReference);
        }
    }
    return result;
}

defaultproperties
{
}