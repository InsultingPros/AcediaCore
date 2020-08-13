/**
 *      Service for tracking currently connected players.
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
class PlayerService extends Service;

//  Record of all current players
var private array<APlayer> allPlayers;

//  Cleans all our player records just in case something caused certain
//  `APlayer` to get destroyed.
private final function RemoveNonePlayers()
{
    local int i;
    while (i < allPlayers.length)
    {
        if (allPlayers[i] == none) {
            allPlayers.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
}

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
    local int       i;
    local APlayer   newPlayer;
    if (newPlayerController == none) return false;

    RemoveNonePlayers();
    for (i = 0; i < allPlayers.length; i += 1)
    {
        if (allPlayers[i] == none) continue;
        if (allPlayers[i].GetController() == newPlayerController) {
            return false;
        }
    }
    newPlayer = APlayer(_.memory.Allocate(class'APlayer'));
    if (newPlayer == none)
    {
        _.logger.Fatal("Cannot spawn a new instance of `APlayer`."
            @ "Acedia will not properly work from now on.");
        return false;
    }
    newPlayer.Initialize(newPlayerController);
    allPlayers[allPlayers.length] = newPlayer;
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
    RemoveNonePlayers();
    return allPlayers;
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
    RemoveNonePlayers();
    for (i = 0; i < allPlayers.length; i += 1)
    {
        if (allPlayers[i] != none){
            allPlayers[i].Update();
        }
    }
}

defaultproperties
{
}