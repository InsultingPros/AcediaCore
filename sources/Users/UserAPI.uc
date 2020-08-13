/**
 *      API that provides functions for managing objects and actors by providing
 *  easy and general means to create and destroy them, that allow to make use of
 *  temporary `Object`s in a more efficient way.
 *      This is a low-level API that most users of Acedia, most likely,
 *  would not have to use, since creation of most objects would use their own
 *  wrapper functions around this API.
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
class UserAPI extends Singleton;

public final function UserDatabase GetDatabase()
{
    return class'UserDatabase'.static.GetInstance();
}

public final function User Fetch(UserID userID)
{
    return class'UserDatabase'.static.GetInstance().FetchUser(userID);
}

public final function User FetchByIDHash(string idHash)
{
    local UserID        userID;
    local UserDatabase  userDB;
    userDB = class'UserDatabase'.static.GetInstance();
    userID = userDB.FetchUserID(idHash);
    return userDB.FetchUser(userID);
}

public final function User FetchByKey(int userKey)
{
    return class'UserDatabase'.static.GetInstance().FetchUserByKey(userKey);
}

defaultproperties
{
}