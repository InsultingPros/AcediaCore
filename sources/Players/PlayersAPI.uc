/**
 *      API that provides functions for working player references (`EPlayer`).
 *      Copyright 2021 - 2022 Anton Tarasenko
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
    dependson(BaseText)
    dependson(EPlayer);

//  Writer that can be used to write into this player's console
var private ConsoleWriter   consoleInstance;
//  Remember version to reallocate writer in case someone deallocates it
var private int             consoleLifeVersion;

var protected bool connectedToConnectionServer;
var protected PlayerAPI_OnNewPlayer_Signal  onNewPlayerSignal;
var protected PlayerAPI_OnLostPlayer_Signal onLostPlayerSignal;

var private EPlayer.PlayerSignals playerSignals;

protected function Constructor()
{
    onNewPlayerSignal = PlayerAPI_OnNewPlayer_Signal(
        _.memory.Allocate(class'PlayerAPI_OnNewPlayer_Signal'));
    onLostPlayerSignal = PlayerAPI_OnLostPlayer_Signal(
        _.memory.Allocate(class'PlayerAPI_OnLostPlayer_Signal'));
    playerSignals.onNameChanging = PlayerAPI_OnPlayerNameChanging_Signal(
        _.memory.Allocate(class'PlayerAPI_OnPlayerNameChanging_Signal'));
    playerSignals.onNameChanged = PlayerAPI_OnPlayerNameChanged_Signal(
        _.memory.Allocate(class'PlayerAPI_OnPlayerNameChanged_Signal'));
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
    _.memory.Free(playerSignals.onNameChanging);
    _.memory.Free(playerSignals.onNameChanged);
    onNewPlayerSignal               = none;
    onLostPlayerSignal              = none;
    playerSignals.onNameChanging    = none;
    playerSignals.onNameChanged     = none;
}

/**
 *  Signal that will be emitted once new player is connected.
 *
 *  [Signature]
 *  void <slot>(EPlayer newPlayer)
 *
 *  @param  handle  Base `EPlayer` interface for the newly connected player.
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
public function PlayerAPI_OnLostPlayer_Slot OnLostPlayer(
    AcediaObject receiver)
{
    ConnectToConnectionService();
    return PlayerAPI_OnLostPlayer_Slot(onLostPlayerSignal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted once player's name attempt to change.
 *
 *      This signal gives all handlers a change to modify mutable `newName`,
 *  so the one you are given as a parameter might not be final, since other
 *  handlers can modify it after you.
 *      If you simply need to see the final version of the changed name -
 *  use `OnPlayerNameChanged` instead.
 *
 *  [Signature]
 *  void <slot>(EPlayer affectedPlayer, BaseText oldName, MutableText newName)
 *
 *  @param  affectedPlayer  Player, whos name got changed.
 *  @param  oldName         Player's old name.
 *  @param  newName         Player's new name. Can be modified, if you want
 *      to make corrections.
 */
/* SIGNAL */
public function PlayerAPI_OnPlayerNameChanging_Slot OnPlayerNameChanging(
    AcediaObject receiver)
{
    return PlayerAPI_OnPlayerNameChanging_Slot(playerSignals.onNameChanging
        .NewSlot(receiver));
}

/**
 *  Signal that will be emitted once player's name is changed.
 *
 *  This signal simply notifies you of the changed name, if you wish to alter it
 *  after change caused by someone else, use `OnPlayerNameChanging` instead.
 *
 *  [Signature]
 *  void <slot>(EPlayer affectedPlayer, BaseText oldName, BaseText newName)
 *
 *  @param  affectedPlayer  Player, whos name got changed.
 *  @param  oldName         Player's old name.
 *  @param  newName         Player's new name.
 */
/* SIGNAL */
public function PlayerAPI_OnPlayerNameChanged_Slot OnPlayerNameChanged(
    AcediaObject receiver)
{
    return PlayerAPI_OnPlayerNameChanged_Slot(playerSignals.onNameChanged
        .NewSlot(receiver));
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
    local EPlayer newPlayer;
    newPlayer = FromController(newConnection.controllerReference);
    onNewPlayerSignal.Emit(newPlayer);
    _.memory.Free(newPlayer);
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
    result.Initialize(controller, playerSignals);
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