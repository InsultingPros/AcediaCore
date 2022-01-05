/**
 *      This service tracks current connections to the server
 *  as well as their basic information,
 *  like IP or steam ID of connecting player.
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
class ConnectionService extends Service;

//  Stores basic information about a connection
struct Connection
{
    var public  PlayerController        controllerReference;
    //  Remember these for the time `controllerReference` dies
    //  and becomes `none`.
    var public  string                  networkAddress;
    var public  string                  idHash;
    //  Reference to `AcediaReplicationInfo` for this client,
    //  in case it was created.
    var private AcediaReplicationInfo   acediaRI;
};

var private array<Connection> activeConnections;

var private Connection_Signal onConnectionEstablishedSignal;
var private Connection_Signal onConnectionLostSignal;

/**
 *  Signal that will be emitted when new player connection is established.
 *
 *  [Signature]
 *  void <slot>(ConnectionService.Connection newConnection)
 *
 *  @param  newConnection   Structure that describes new connection.
 */
/* SIGNAL */
public final function Connection_Slot OnConnectionEstablished(
    AcediaObject receiver)
{
    return Connection_Slot(onConnectionEstablishedSignal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted when the player connection is lost.
 *
 *  [Signature]
 *  void <slot>(ConnectionService.Connection lostConnection)
 *
 *  @param  newConnection   Structure that describes lost connection.
 */
/* SIGNAL */
public final function Connection_Slot OnConnectionLost(AcediaObject receiver)
{
    return Connection_Slot(onConnectionLostSignal.NewSlot(receiver));
}

//  Clean disconnected and manually find all new players on launch
protected function OnLaunch()
{
    local Controller        nextController;
    local PlayerController  nextPlayerController;
    _.unreal.mutator.OnCheckReplacement(_self).connect = TryAddingController;
    onConnectionEstablishedSignal =
        Connection_Signal(_.memory.Allocate(class'Connection_Signal'));
    onConnectionLostSignal =
        Connection_Signal(_.memory.Allocate(class'Connection_Signal'));
    RemoveBrokenConnections();
    nextController = level.controllerList;
    while (nextController != none)
    {
        nextPlayerController = PlayerController(nextController);
        if (nextPlayerController != none) {
            RegisterConnection(nextPlayerController);
        }
        nextController = nextController.nextController;
    }
}

protected function OnShutdown()
{
    default.activeConnections = activeConnections;
    _.memory.Free(onConnectionEstablishedSignal);
    _.memory.Free(onConnectionLostSignal);
    onConnectionEstablishedSignal = none;
    onConnectionLostSignal = none;
}

//      Returning `true` guarantees that `controllerToCheck != none`
//  and `controllerToCheck.playerReplicationInfo != none`.
private function bool IsHumanController(PlayerController controllerToCheck)
{
    local PlayerReplicationInfo replicationInfo;
    if (controllerToCheck == none)                      return false;
    if (!controllerToCheck.bIsPlayer)                   return false;
    //  Is this a WebAdmin that did not yet set `bIsPlayer = false`?
    if (MessagingSpectator(controllerToCheck) != none)  return false;
    //  Check replication info
    replicationInfo = controllerToCheck.playerReplicationInfo;
    if (replicationInfo == none)                        return false;
    if (replicationInfo.bBot)                           return false;
    return true;
}

//  Returns index of the connection corresponding to the given controller.
//  Returns `-1` if no connection correspond to the given controller.
//  Returns `-1` if given controller is equal to `none`.
private function int GetConnectionIndex(PlayerController controllerToCheck)
{
    local int i;
    if (controllerToCheck == none) return -1;
    for (i = 0; i < activeConnections.length; i += 1)
    {
        if (activeConnections[i].controllerReference == controllerToCheck) {
            return i;
        }
    }
    return -1;
}

//  Remove connections with now invalid (`none`) player controller reference.
private function RemoveBrokenConnections()
{
    local int i;
    i = 0;
    while (i < activeConnections.length)
    {
        if (activeConnections[i].controllerReference == none)
        {
            if (activeConnections[i].acediaRI != none) {
                activeConnections[i].acediaRI.Destroy();
            }
            onConnectionLostSignal.Emit(activeConnections[i]);
            activeConnections.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
}

/**
 *  Returns connection corresponding to a given player controller.
 *
 *  @param  player  `PlayerController` for which this method will return
 *      a connection.
 *  @return `Connection` structure for the given `player`.
 *      For `none` returns an "empty connection" structure that has all it's
 *      variables set to their default values. Can also potentially return
 *      "empty connection" for a valid `PlayerController` if this method was
 *      called before `ConnectionService` had the change to register
 *      a connection for the given `PlayerController`.
 */
public final function Connection GetConnection(PlayerController player)
{
    local int           connectionIndex;
    local Connection    emptyConnection;
    connectionIndex = GetConnectionIndex(player);
    if (connectionIndex < 0) {
        return emptyConnection;
    }
    return activeConnections[connectionIndex];
}

/**
 *  Attempts to register a connection for this player controller.
 *  IMPORTANT: Should not be used outside of `ConnectionService` module.
 *
 *  @param  player          `PlayerController` for which caller service will
 *      have to track a connection.
 *  @return `true` if connection is registered (even if it was already added).
 */
public final function bool RegisterConnection(PlayerController player)
{
    local Connection newConnection;
    if (!IsHumanController(player))         return false;
    if (GetConnectionIndex(player) >= 0)    return true;
    newConnection.controllerReference = player;

    newConnection.idHash = player.GetPlayerIDHash();
    newConnection.networkAddress = player.GetPlayerNetworkAddress();
    activeConnections[activeConnections.length] = newConnection;
    //  Remember recorded connections in case someone decides to
    //  nuke this service
    default.activeConnections = activeConnections;
    onConnectionEstablishedSignal.Emit(newConnection);
    return true;
}

/**
 *  Returns list of currently active connections.
 *
 *      By default can return connections with already disconnected player
 *  (can happen if player disconnected during this tick and `ConnectionService`
 *  has not yet had an opportunity to handle it as a player disconnecting).
 *      This behavior can be changed via `removeBroken` parameter.
 *
 *  @param  removeBroken    Setting this to `true` will cause
 *      `ConnectionService` to first try and detect broken connections.
 *      Doing so might change the state of `ConnectionService` and might
 *      trigger disconnect events. It is recommended to leave this as `false`
 *      and manually check if `PlayerController`s are not `none`.
 *  @return Array that contains all current connection records.
 */
public final function array<Connection> GetActiveConnections(
    optional bool removeBroken)
{
    if (removeBroken) {
        RemoveBrokenConnections();
    }
    return activeConnections;
}

function bool TryAddingController(Actor other, out byte isSuperRelevant)
{
    //      We are looking for `KFSteamStatsAndAchievements` instead of
    //  `PlayerController` because, by the time they it's created,
    //  controller should have a valid reference to `PlayerReplicationInfo`,
    //  as well as valid network address and IDHash (steam id).
    //      However, neither of those are properly initialized at the point when
    //  `CheckReplacement` is called for `PlayerController`.
    //
    //      Since `KFSteamStatsAndAchievements`
    //  is created soon after (at the same tick)
    //  for each new `PlayerController`,
    //  we will be detecting new users right after server
    //  detected and properly initialized them.
    if (KFSteamStatsAndAchievements(other) != none) {
        RegisterConnection(PlayerController(other.owner));
    }
    return true;
}

//  Check if connections are still active every tick.
//  Should not take any noticeable time when no players are disconnecting.
event Tick(float delta)
{
    RemoveBrokenConnections();
}

defaultproperties
{
}