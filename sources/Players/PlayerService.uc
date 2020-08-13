/**
 *      Service for tracking currently connected players.
 *      Besides simply storing all players it also separately stores (caches)
 *  players belonging to specific groups to make appropriate getters faster.
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

var private array<APlayer> allPlayers;

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

public final function array<APlayer> GetAllPlayers()
{
    RemoveNonePlayers();
    return allPlayers;
}

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