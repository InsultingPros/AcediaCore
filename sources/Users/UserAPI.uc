/**
 *      API that allows easy access to `User` persistent data and `UserID`s.
 *      Copyright 2020 - 2021 Anton Tarasenko
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
class UserAPI extends AcediaObject
    config(AcediaSystem);

var private config string userDataDBLink;

/**
 *  Returns reference to the database of user records that Acedia was
 *  set up to use.
 *
 *  @return Main `UserDatabase` that Acedia currently uses to load and
 *      store user information. Guaranteed to be a valid non-`none` reference.
 */
public final function UserDatabase GetDatabase()
{
    return class'UserDatabase'.static.GetInstance();
}

/**
 *  Fetches `User` object that stores persistent data for a given `userID`.
 *
 *  @param  userID  ID for which to fetch a persistent data storage.
 *  @return `User` object for a given `UserID`. Guaranteed to be a valid
 *      non-`none` reference if passed `userID` is not `none` and initialized
 *      (which is guaranteed unless you manually created it).
 */
public final function User Fetch(UserID userID)
{
    return class'UserDatabase'.static.GetInstance().FetchUser(userID);
}

/**
 *  Fetches appropriate `User` object for a player, given his id as a `Text`.
 *
 *  @param  idHash  `Text` representation of someone's id.
 *  @return Corresponding `User` object. Guaranteed to be a valid non-`none`
 *      reference.
 */
public final function User FetchByIDHash(BaseText idHash)
{
    local UserID        userID;
    local UserDatabase  userDB;
    userDB = class'UserDatabase'.static.GetInstance();
    userID = userDB.FetchUserID(idHash);
    return userDB.FetchUser(userID);
}

/**
 *  Fetches appropriate `User` object for a player, given his session key.
 *
 *  @param  userKey Key corresponding to a `User` method must to get.
 *  @return Corresponding `User` object. Guaranteed to be a valid non-`none`
 *      reference if `userKey` was actually assigned to any `User` during
 *      current playing session; `none` otherwise.
 */
public final function User FetchByKey(int userKey)
{
    return class'UserDatabase'.static.GetInstance().FetchUserByKey(userKey);
}

/**
 *  Returns configured database link to the JSON object in which users' data
 *  is stored.
 *
 *  @return Database link to the JSON object in which users' data is stored.
 *      Guaranteed to not be `none`.
 */
public final function Text GetUserDataLink()
{
    return P(userDataDBLink).Copy();
}

/**
 *  Checks whether database setup to store users' persistent data was configured
 *  and actually exists.
 *
 *  This does not check for whether that database is properly configured.
 *  If sub-object set to store users' data was not created inside it, then
 *  Acedia will not be able to make use of users' persistent storage.
 *
 *  @return `true` if database for users' persistent data storage exists and
 *      `false` otherwise.
 */
public final function bool PersistentStorageExists()
{
    return (_.db.Load(P(userDataDBLink)) != none);
}

defaultproperties
{
    userDataDBLink = "[local]database:/users"
}