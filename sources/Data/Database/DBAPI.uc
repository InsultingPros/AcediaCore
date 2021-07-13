/**
 *  API that provides methods for creating/destroying and managing available
 *  databases.
 *      Copyright 2021 Anton Tarasenko
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
class DBAPI extends AcediaObject;

var private const class<Database> localDBClass;

//      Store all already loaded databases to make sure we do not create two
//  different `LocalDatabaseInstance` that are trying to make changes
//  separately.
var private AssociativeArray loadedLocalDatabases;

private final function CreateLocalDBMapIfMissing()
{
    if (loadedLocalDatabases == none) {
        loadedLocalDatabases = __().collections.EmptyAssociativeArray();
    }
}

/**
 *  Creates new local database with name `databaseName`.
 *
 *  This method will fail if:
 *      1. `databaseName` is `none` or empty;
 *      2. Local database with name `databaseName` already exists.
 *
 *  @param  databaseName    Name for the new database.
 *  @return Reference to created database. Returns `none` iff method failed.
 */
public final function LocalDatabaseInstance NewLocal(Text databaseName)
{
    local DBRecord              rootRecord;
    local Text                  rootRecordName;
    local LocalDatabase         newConfig;
    local LocalDatabaseInstance newLocalDBInstance;
    CreateLocalDBMapIfMissing();
    //  No need to check `databaseName` for being valid,
    //  since `Load()` will just return `none` if it is not.
    newConfig = class'LocalDatabase'.static.Load(databaseName);
    if (newConfig == none)                          return none;
    if (newConfig.HasDefinedRoot())                 return none;
    if (loadedLocalDatabases.HasKey(databaseName))  return none;

    newLocalDBInstance = LocalDatabaseInstance(_.memory.Allocate(localDBClass));
    loadedLocalDatabases.SetItem(databaseName.Copy(), newLocalDBInstance);
    rootRecord = class'DBRecord'.static.NewRecord(databaseName);
    rootRecordName = _.text.FromString(string(rootRecord.name));
    newConfig.SetRootName(rootRecordName);
    newConfig.Save();
    newLocalDBInstance.Initialize(newConfig, rootRecord);
    _.memory.Free(rootRecordName);
    return newLocalDBInstance;
}

/**
 *  Loads and returns local database with the name `databaseName`.
 *
 *  If specified database is already loaded - simply returns it's reference
 *  (consequent calls to `LoadLocal()` will keep returning the same reference,
 *  unless database is deleted).
 *
 *  @param  databaseName    Name of the database to load.
 *  @return Loaded local database. `none` if it does not exist.
 */
public final function LocalDatabaseInstance LoadLocal(Text databaseName)
{
    local DBRecord              rootRecord;
    local Text                  rootRecordName;
    local LocalDatabase         newConfig;
    local LocalDatabaseInstance newLocalDBInstance;
    CreateLocalDBMapIfMissing();
    if (loadedLocalDatabases.HasKey(databaseName))
    {
        return LocalDatabaseInstance(loadedLocalDatabases
            .GetItem(databaseName));
    }
    //  No need to check `databaseName` for being valid,
    //  since `Load()` will just return `none` if it is not.
    newConfig = class'LocalDatabase'.static.Load(databaseName);
    if (newConfig == none)              return none;
    if (!newConfig.HasDefinedRoot())    return none;

    newLocalDBInstance = LocalDatabaseInstance(_.memory.Allocate(localDBClass));
    loadedLocalDatabases.SetItem(databaseName.Copy(), newLocalDBInstance);
    rootRecordName = newConfig.GetRootName();
    rootRecord = class'DBRecord'.static
        .LoadRecord(rootRecordName, databaseName);
    newLocalDBInstance.Initialize(newConfig, rootRecord);
    _.memory.Free(rootRecordName);
    return newLocalDBInstance;
}

/**
 *  Checks if local database with the name `databaseName` already exists.
 *
 *  @param  databaseName    Name of the database to check.
 *  @return `true` if database with specified name exists and `false` otherwise.
 */
public final function bool ExistsLocal(Text databaseName)
{
    return LoadLocal(databaseName) != none;
}

/**
 *  Deletes local database with name `databaseName`.
 *
 *  @param  databaseName    Name of the database to delete.
 *  @return `true` if database with specified name existed and was deleted and
 *      `false` otherwise.
 */
public final function bool DeleteLocal(Text databaseName)
{
    local LocalDatabase             localDatabaseConfig;
    local LocalDatabaseInstance     localDatabase;
    local AssociativeArray.Entry    dbEntry;
    CreateLocalDBMapIfMissing();
    //  To delete database we first need to load it
    localDatabase = LoadLocal(databaseName);
    if (localDatabase != none) {
        localDatabaseConfig = localDatabase.GetConfig();
    }
    dbEntry = loadedLocalDatabases.TakeEntry(databaseName);
    //  Delete `LocalDatabaseInstance` before erasing the package,
    //  to allow it to clean up safely
    _.memory.Free(dbEntry.key);
    _.memory.Free(dbEntry.value);
    if (localDatabaseConfig != none) {
        EraseAllPackageData(localDatabaseConfig.GetPackageName());
        localDatabaseConfig.DeleteSelf();
        return true;
    }
    return false;
}

private function EraseAllPackageData(Text packageToErase)
{
    local int               i;
    local string            packageName;
    local GameInfo          game;
    local DBRecord          nextRecord;
    local array<DBRecord>   allRecords;
    packageName = _.text.ToString(packageToErase);
    if (packageName == "") {
        return;
    }
    game = _.unreal.GetGameType();
    game.DeletePackage(packageName);
    //  Delete any leftover objects. This has to be done *after*
    //  `DeletePackage()` call, otherwise removed garbage can reappear.
    //  No clear idea why it works this way.
    foreach game.AllDataObjects(class'DBRecord', nextRecord, packageName) {
        allRecords[allRecords.length] = nextRecord;
    }
    for (i = 0; i < allRecords.length; i += 1)
    {
        game.DeleteDataObject(  class'DBRecord', string(allRecords[i].name),
                                packageName);
    }
}

/**
 *  Returns array of names of all available local databases.
 *
 *  @return List of names of all local databases.
 */
public final function array<Text> ListLocal()
{
    local int           i;
    local array<Text>   dbNames;
    local array<string> dbNamesAsStrings;
    dbNamesAsStrings = GetPerObjectNames(   "AcediaDB",
                                            string(class'LocalDatabase'.name),
                                            MaxInt);
    for (i = 0; i < dbNamesAsStrings.length; i += 1) {
        dbNames[dbNames.length] = _.text.FromString(dbNamesAsStrings[i]);
    }
    return dbNames;
}

defaultproperties
{
    localDBClass = class'LocalDatabaseInstance'
}