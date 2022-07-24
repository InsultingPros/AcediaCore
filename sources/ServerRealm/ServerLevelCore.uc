/**
 *      `LevelCore` version to be used on servers to provide `Actor` source for
 *  `ServerGlobal` API.
 *      Copyright 2022 Anton Tarasenko
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
class ServerLevelCore extends LevelCore;

public static function LevelCore CreateLevelCore(Actor source)
{
    local LevelCore newCore;

    if (source == none)                             return none;
    if (source.level.netMode != NM_DedicatedServer) return none;

    newCore = super.CreateLevelCore(source);
    if (newCore != none) {
        __server().ConnectServerLevelCore();
    }
    __().scheduler.UpdateTickConnection();
    return newCore;
}

defaultproperties
{
}