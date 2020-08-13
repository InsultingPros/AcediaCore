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
class User extends AcediaObject;

var private UserID  id;
var private int     key;

public final function Initialize(UserID initID, int initKey)
{
    id  = initID;
    key = initKey;
}

public final function UserID GetID()
{
    return id;
}

public final function int GetKey()
{
    return key;
}

defaultproperties
{
}