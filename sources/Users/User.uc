/**
 *      Object that is supposed to store a persistent data about the
 *  certain player. That is data that will be remembered even after player
 *  reconnects or server changes map/restarts.
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

//  Unique identifier for which this `User` stores it's data
var private UserID  id;
//  A numeric "key" assigned to this user for a session that can serve as
//  an easy reference in console commands
var private int     key;

/**
 *  Initializes caller `User` with id and it's session key. Should be called
 *  right after `APlayer` was created.
 *
 *      Initialization should (and can) only be done once.
 *      Before a `Initialize()` call, any other method calls on such `User`
 *  must be considerate to have undefined behavior.
 */
public final function Initialize(UserID initID, int initKey)
{
    id  = initID;
    key = initKey;
}

/**
 *  Return id for which caller `User` stores data.
 *
 *  @return `UserID` that caller `User` was initialized with.
 */
public final function UserID GetID()
{
    return id;
}

/**
 *  Return session key of the caller `User`.
 *
 *  @return Session key of the caller `User`.
 */
public final function int GetKey()
{
    return key;
}

defaultproperties
{
}