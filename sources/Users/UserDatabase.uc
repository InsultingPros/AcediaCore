/**
 *  Simple user database for Acedia.
 *  Only stores data for a session, map or server restarts will clear it.
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

//  This is used as a global variable only (`default.activeDatabase`) to store
//  a reference to main database for persistent data, used by Acedia.
var private UserDatabase    activeDatabase;
//  `User` records that were stored this session
var private array<User>     sessionUsers;
//  `UserID`s generated during this session.
//  Instead of constantly creating new ones - just reuse already created.
//  This array should not grow too huge under normal circumstances.
var private array<UserID>   storedUserIDs;

/**
 *  Provides a reference to the database of user records that Acedia was
 *  set up to use.
 *
 *  Provided reference is guaranteed to not change during one session.
 *
 *  @return reference to the database of user records that Acedia was
 *      set up to use.
 */
public final static function UserDatabase GetInstance()
{
    if (default.activeDatabase == none)
    {
        default.activeDatabase =
            UserDatabase(_().memory.Allocate(class'UserDatabase'));
    }
    return default.activeDatabase;
}

/**
 *  Converts `string` representation of someone's id into appropriate
 *  `UserID` object.
 *
 *  Always returns the same object for the same `idHash`.
 */
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

/**
 *  Fetches `User` object that stores persistent data for a given `userID`.
 *
 *  @param  userID  ID for which to fetch a persistent data storage.
 *  @return `User` object for a given `UserID`. Guaranteed to be a valid
 *      non-`none` reference if passed `userID` is not `none` and initialized
 *      (which is guaranteed unless you manually created it).
 */
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

/**
 *  Fetches appropriate `User` object for a player, given his session key.
 *
 *  @param  userKey Key corresponding to a `User` method must to get.
 *  @return Corresponding `User` object. Guaranteed to be a valid non-`none`
 *      reference if `userKey` was actually assigned to any `User` during
 *      current playing session; `none` otherwise.
 */
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