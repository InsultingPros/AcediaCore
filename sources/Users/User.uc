/**
 *      Object that is supposed to store a persistent data about the
 *  certain player. That is data that will be remembered even after player
 *  reconnects or server changes map/restarts.
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
class User extends AcediaObject;

//  Unique identifier for which this `User` stores it's data
var private UserID  id;
//  A numeric "key" assigned to this user for a session that can serve as
//  an easy reference in console commands
var private int     key;

//  Database where user's persistent data is stored
var private Database    persistentDatabase;
//  Pointer to this user's "settings" data in particular
var private JSONPointer persistentSettingsPointer;

var private LoggerAPI.Definition errNoUserDataDatabase;

//  TODO: redo this comment
/**
 *  Initializes caller `User` with id and it's session key. Should be called
 *  right after `EPlayer` was created.
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

/**
 *  Reads user's persistent data saved inside group `groupName`, saving it into
 *  a collection using mutable data types.
 *  Only should be used if `_.users.PersistentStorageExists()` returns `true`.
 *
 *  @param  groupName   Name of the group these settings belong to.
 *      This exists to help reduce name collisions between different mods.
 *      Acedia stores all its settings under "Acedia" group. We suggest that you
 *      pick at least one name to use for your own mods.
 *      It should be unique enough to not get picked by others - "weapons" is
 *      a bad name, while "CoolModMastah79" is actually a good pick.
 *  @return Task object for reading specified persistent data from the database.
 *      For more info see `Database.ReadData()` method.
 *      Guaranteed to not be `none` iff
 *      `_.users.PersistentStorageExists() == true`.
 */
public final function DBReadTask ReadGroupOfPersistentData(BaseText groupName)
{
    local DBReadTask task;
    if (groupName == none)          return none;
    if (!SetupDatabaseVariables())  return none;

    persistentSettingsPointer.Push(groupName);
    task = persistentDatabase.ReadData(persistentSettingsPointer, true);
    _.memory.Free(persistentSettingsPointer.Pop());
    return task;
}

/**
 *  Reads user's persistent data saved under name `dataName`, saving it into
 *  a collection using mutable data types.
 *  Only should be used if `_.users.PersistentStorageExists()` returns `true`.
 *
 *  @param  groupName   Name of the group these settings belong to.
 *      This exists to help reduce name collisions between different mods.
 *      Acedia stores all its settings under "Acedia" group. We suggest that you
 *      pick at least one name to use for your own mods.
 *      It should be unique enough to not get picked by others - "weapons" is
 *      a bad name, while "CoolModMastah79" is actually a good pick.
 *  @param  dataName    Any name, from under which settings you are interested
 *      (inside `groupName` group) should be read.
 *  @return Task object for reading specified persistent data from the database.
 *      For more info see `Database.ReadData()` method.
 *      Guaranteed to not be `none` iff
 *      `_.users.PersistentStorageExists() == true`.
 */
public final function DBReadTask ReadPersistentData(
    BaseText groupName,
    BaseText dataName)
{
    local DBReadTask task;
    if (groupName == none)          return none;
    if (dataName == none)           return none;
    if (!SetupDatabaseVariables())  return none;

    persistentSettingsPointer.Push(groupName).Push(dataName);
    task = persistentDatabase.ReadData(persistentSettingsPointer, true);
    _.memory.Free(persistentSettingsPointer.Pop());
    _.memory.Free(persistentSettingsPointer.Pop());
    return task;
}

/**
 *  Writes user's persistent data under name `dataName`.
 *  Only should be used if `_.users.PersistentStorageExists()` returns `true`.
 *
 *  @param  groupName   Name of the group these settings belong to.
 *      This exists to help reduce name collisions between different mods.
 *      Acedia stores all its settings under "Acedia" group. We suggest that you
 *      pick at least one name to use for your own mods.
 *      It should be unique enough to not get picked by others - "weapons" is
 *      a bad name, while "CoolModMastah79" is actually a good pick.
 *  @param  dataName    Any name, under which settings you are interested
 *      (inside `groupName` group) should be written.
 *  @param  data        JSON-compatible (see `_.json.IsCompatible()`) data that
 *      should be written into database.
 *  @return Task object for writing specified persistent data into the database.
 *      For more info see `Database.WriteData()` method.
 *      Guarantee to not be `none` iff
 *      `_.users.PersistentStorageExists() == true`.
 */
public final function DBWriteTask WritePersistentData(
    BaseText        groupName,
    BaseText        dataName,
    AcediaObject    data)
{
    local DBWriteTask   task;
    local HashTable     emptyObject;
    if (groupName == none)          return none;
    if (dataName == none)           return none;
    if (!SetupDatabaseVariables())  return none;

    emptyObject = _.collections.EmptyHashTable();
    persistentSettingsPointer.Push(groupName);
    persistentDatabase.IncrementData(persistentSettingsPointer, emptyObject);
    persistentSettingsPointer.Push(dataName);
    task = persistentDatabase.WriteData(persistentSettingsPointer, data);
    _.memory.Free(persistentSettingsPointer.Pop());
    _.memory.Free(persistentSettingsPointer.Pop());
    _.memory.Free(emptyObject);
    return task;
}

//  Setup database `persistentDatabase` and pointer to this user's data
//  `persistentSettingsPointer`.
//  Return `true` if these variables were setup (during this call or before)
//  and `false` otherwise.
private function bool SetupDatabaseVariables()
{
    local Text      userDataLink;
    local Text      userTextID;
    local HashTable emptyObject, skeletonObject;

    if (    persistentDatabase != none && persistentSettingsPointer != none
        &&  persistentDatabase.IsAllocated())
    {
        return true;
    }
    if (id == none || !id.IsInitialized()) {
        return false;
    }
    _.memory.Free(persistentSettingsPointer);
    userDataLink = _.users.GetUserDataLink();
    persistentDatabase = _.db.Load(userDataLink);
    if (persistentDatabase == none)
    {
        _.logger.Auto(errNoUserDataDatabase).Arg(userDataLink);
        return false;
    }
    persistentSettingsPointer = _.db.GetPointer(userDataLink);
    userTextID = id.GetSteamID64String();
    skeletonObject = _.collections.EmptyHashTable();
    skeletonObject.SetItem(P("statistics"), _.collections.EmptyHashTable());
    skeletonObject.SetItem(P("settings"), _.collections.EmptyHashTable());
    emptyObject = _.collections.EmptyHashTable();
    persistentDatabase.IncrementData(persistentSettingsPointer, emptyObject);
    persistentSettingsPointer.Push(userTextID);
    persistentDatabase.IncrementData(persistentSettingsPointer, skeletonObject);
    persistentSettingsPointer.Push(P("settings"));
    _.memory.Free(userTextID);
    _.memory.Free(userDataLink);
    _.memory.Free(skeletonObject);
    _.memory.Free(emptyObject);
    return true;
}

defaultproperties
{
    errNoUserDataDatabase = (l=LOG_Error,m="Failed to load persistent user database instance given by link \"%1\".")
}