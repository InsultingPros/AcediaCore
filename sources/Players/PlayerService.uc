/**
 *      Service for tracking currently connected players and remembering what
 *  `APlayer` is connected to what `PlayerController` (`PlayerController`
 *  instance is an `Actor` and therefore should not be stores as `APlayer`'s
 *  variable, since `APlayer` is not an `Actor`).
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
class PlayerService extends Service;

//  Used to 1-to-1 associate `APlayer` with `PlayerController` object.
struct PlayerControllerPair
{
    var APlayer             player;
    var PlayerController    controller;
};
//  Store all known players along with their `PlayerController`s.
var private array<PlayerControllerPair> allPlayers;

//  Shortcut to `ConnectionEvents`, so that we don't have to write
//  `class'ConnectionEvents'` every time.
var const class<PlayerEvents> events;

/**
 *  Creates a new `APlayer` instance for a given `newPlayerController`
 *  controller.
 *
 *  If given controller is `none` or it's `APLayer` was already created,
 *  - does nothing.
 *
 *  @param  newPlayerController Controller for which we must
 *      create new `APlayer`.
 *  @return `true` if new `APlayer` was created and `false` otherwise.
 */
public final function bool RegisterPlayer(PlayerController newPlayerController)
{
    local int                   i;
    local Text                  textIdHash;
    local PlayerControllerPair  newPair;
    if (newPlayerController == none) return false;

    UpdateAllPlayers();
    for (i = 0; i < allPlayers.length; i += 1)
    {
        if (allPlayers[i].controller == newPlayerController) {
            return false;
        }
    }
    //  Record new pair in service's data
    newPair.controller  = newPlayerController;
    newPair.player      = APlayer(_.memory.Allocate(class'APlayer', true));
    allPlayers[allPlayers.length] = newPair;
    //  Initialize new `APlayer`
    textIdHash = _.text.FromString(newPlayerController.GetPlayerIDHash());
    newPair.player.Initialize(textIdHash);
    textIdHash.FreeSelf();
    //  Run events
    events.static.CallPlayerConnected(newPair.player);
    return true;
}

/**
 *  Fetches current array of all player (registered `APLayer`s).
 *
 *  @return Current array of all player (registered `APLayer`s). Guaranteed to
 *      not contain `none` values.
 */
public final function array<APlayer> GetAllPlayers()
{
    local int i;
    local array<APlayer> result;
    for (i = 0; i < allPlayers.length; i += 1)
    {
        if (allPlayers[i].controller != none) {
            result[result.length] = allPlayers[i].player;
        }
    }
    return result;
}

/**
 *  Returns `APlayer` associated with a given `PlayerController`.
 *
 *  @param  controller  Controller for which we want to find associated player.
 *  @return `APlayer` that is associated with a given `PlayerController`.
 *      Can return `none` if player has already "expired".
 */
public final function APlayer GetPlayer(PlayerController controller)
{
    local int i;
    if (controller == none) {
        return none;
    }
    for (i = 0; i < allPlayers.length; i += 1)
    {
        if (controller == allPlayers[i].controller) {
            return allPlayers[i].player;
        }
    }
    return none;
}

/**
 *  Returns `PlayerController` associated with a given `APlayer`.
 *
 *  @param  player  Player for which we want to find associated controller.
 *  @return Controller that is associated with a given player.
 *      Can return `none` if controller has already "expired".
 */
public final function PlayerController GetController(APlayer player)
{
    local int i;
    if (player == none) {
        return none;
    }
    for (i = 0; i < allPlayers.length; i += 1)
    {
        if (player == allPlayers[i].player) {
            return allPlayers[i].controller;
        }
    }
    return none;
}

/**
 *  IMPORTANT: this is a helper function that is not supposed to be
 *  called manually.
 *
 *  Causes status of all players to update.
 *  See `APlayer.Update()` for details.
 */
public final function UpdateAllPlayers()
{
    local int i;
    while (i < allPlayers.length)
    {
        if (allPlayers[i].controller == none)
        {
            events.static.CallPlayerDisconnected(allPlayers[i].player);
            allPlayers.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
}

defaultproperties
{
    events = class'PlayerEvents'
    requiredListeners(0) = class'ConnectionListener_Player'
}