/**
 *  Simple user database for Acedia.
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
class UserDatabase extends AcediaObject
    config(Acedia)
    abstract;

var private UserDatabase    activeDatabase;
var private array<User>     sessionUsers;
var private array<UserID>   storedUserIDs;

public final static function UserDatabase GetInstance()
{
    if (default.activeDatabase == none)
    {
        default.activeDatabase =
            UserDatabase(_().memory.Allocate(class'UserDatabase'));
    }
    return default.activeDatabase;
}

public final function UserID FetchUserID(string idHash)
{
    local int               i;
    local UserID.SteamID    steamID;
    local UserID            newUserID;
    steamID = class'UserID'.static.GetSteamIDFromIDHash(idHash);
    for (i = 0; i < storedUserIDs.length; i += 1)
    {
        if (storedUserIDs[i].IsEqualToSteamID(steamID)) {
            return storedUserIDs[i];
        }
    }
    newUserID = UserID(_().memory.Allocate(class'UserID'));
    newUserID.InitializeWithSteamID(steamID);
    storedUserIDs[storedUserIDs.length] = newUserID;
    return newUserID;
}

public final function User FetchUser(UserID userID)
{
    local int   i;
    local User  newUser;
    for (i = 0; i < sessionUsers.length; i += 1)
    {
        if (sessionUsers[i].GetID().IsEqualTo(userID)) {
            return sessionUsers[i];
        }
    }
    newUser = User(_().memory.Allocate(class'User'));
    newUser.Initialize(userID, sessionUsers.length + 1);
    sessionUsers[sessionUsers.length] = newUser;
    return newUser;
}

public final function User FetchUserByKey(int userKey)
{
    local int i;
    for (i = 0; i < sessionUsers.length; i += 1)
    {
        if (sessionUsers[i].GetKey() == userKey) {
            return sessionUsers[i];
        }
    }
    return none;
}

defaultproperties
{
}