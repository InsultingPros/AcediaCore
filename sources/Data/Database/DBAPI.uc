/**
 *  API that provides methods for creating/destroying and managing available
 *  databases.
 *      Copyright 2021-2022 Anton Tarasenko
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
var private HashTable loadedLocalDatabases;

var private LoggerAPI.Definition infoLocalDatabaseCreated;
var private LoggerAPI.Definition infoLocalDatabaseDeleted;
var private LoggerAPI.Definition infoLocalDatabaseLoaded;

private final function CreateLocalDBMapIfMissing()
{
    if (loadedLocalDatabases == none) {
        loadedLocalDatabases = __().collections.EmptyHashTable();
    }
}

/**
 *  Loads database based on the link.
 *
 *  Links have the form of "<db_name>:" (or, optionally, "[<type>]<db_name>:"),
 *  followed by the JSON pointer (possibly empty one) to the object inside it.
 *  "<type>" can be either "local" or "remote" and is necessary only when both
 *  local and remote database have the same name (which should be avoided).
 *  "<db_name>" refers to the database that we are expected
 *  to load, it has to consist of numbers and latin letters only.
 *
 *  @param  databaseLink    Link from which to extract database's name.
 *  @return Database named "<db_name>" of type "<type>" from the `databaseLink`.
 */
public final function Database Load(BaseText databaseLink)
{
    local Parser        parser;
    local Database      result;
    local Text          immutableDatabaseName;
    local MutableText   databaseName;

    if (databaseLink == none) {
        return none;
    }
    parser = _.text.Parse(databaseLink);
    //  Only local DBs are supported for now!
    //  So just consume this prefix, if it's present.
    parser.Match(P("[local]")).Confirm();
    parser.R().MUntil(databaseName, _.text.GetCharacter(":")).MatchS(":");
    if (!parser.Ok())
    {
        parser.FreeSelf();
        return none;
    }
    immutableDatabaseName = databaseName.Copy();
    result = LoadLocal(immutableDatabaseName);
    parser.FreeSelf();
    databaseName.FreeSelf();
    immutableDatabaseName.FreeSelf();
    return result;
}

/**
 *  Extracts `JSONPointer` from the database path, given by `databaseLink`.
 *
 *  Links have the form of "<db_name>:" (or, optionally, "[<type>]<db_name>:"),
 *  followed by the JSON pointer (possibly empty one) to the object inside it.
 *  "<type>" can be either "local" or "remote" and is necessary only when both
 *  local and remote database have the same name (which should be avoided).
 *  "<db_name>" refers to the database that we are expected
 *  to load, it has to consist of numbers and latin letters only.
 *  This method returns `JSONPointer` that comes after type-name pair.
 *
 *  @param  Link from which to extract `JSONPointer`.
 *  @return `JSONPointer` from the database link.
 *      Guaranteed to not be `none` if provided argument `databaseLink`
 *      is not `none`.
 */
public final function JSONPointer GetPointer(BaseText databaseLink)
{
    local int           slashIndex;
    local Text          textPointer;
    local JSONPointer   result;

    if (databaseLink == none) {
        return none;
    }
    slashIndex = databaseLink.IndexOf(P(":"));
    if (slashIndex < 0) {
        return JSONPointer(_.memory.Allocate(class'JSONPointer'));
    }
    textPointer = databaseLink.Copy(slashIndex + 1);
    result = _.json.Pointer(textPointer);
    textPointer.FreeSelf();
    return result;
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
public final function LocalDatabaseInstance NewLocal(BaseText databaseName)
{
    local DBRecord              rootRecord;
    local Text                  rootRecordName;
    local Text                  databaseNameCopy;
    local LocalDatabase         newConfig;
    local LocalDatabaseInstance newLocalDBInstance;

    CreateLocalDBMapIfMissing();
    if (databaseName == none)                       return none;
    if (!databaseName.IsValidName())                return none;
    newConfig = class'LocalDatabase'.static.Load(databaseName);
    if (newConfig == none)                          return none;
    if (newConfig.HasDefinedRoot())                 return none;
    if (loadedLocalDatabases.HasKey(databaseName))  return none;

    newLocalDBInstance = LocalDatabaseInstance(_.memory.Allocate(localDBClass));
    databaseNameCopy = databaseName.Copy();
    loadedLocalDatabases.SetItem(databaseNameCopy, newLocalDBInstance);
    rootRecord = class'DBRecord'.static.NewRecord(databaseName);
    rootRecordName = _.text.FromString(string(rootRecord.name));
    newConfig.SetRootName(rootRecordName);
    newConfig.Save();
    newLocalDBInstance.Initialize(newConfig, rootRecord);
    _.logger.Auto(infoLocalDatabaseCreated).Arg(databaseNameCopy);
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
public final function LocalDatabaseInstance LoadLocal(BaseText databaseName)
{
    local DBRecord              rootRecord;
    local Text                  rootRecordName;
    local LocalDatabase         newConfig;
    local LocalDatabaseInstance newLocalDBInstance;

    if (databaseName == none) {
        return none;
    }
    CreateLocalDBMapIfMissing();
    if (loadedLocalDatabases.HasKey(databaseName))
    {
        return LocalDatabaseInstance(loadedLocalDatabases
            .GetItem(databaseName));
    }
    //  No need to check `databaseName` for being valid,
    //  since `Load()` will just return `none` if it is not.
    newConfig = class'LocalDatabase'.static.Load(databaseName);
    if (newConfig == none) {
        return none;
    }
    if (!newConfig.HasDefinedRoot() && !newConfig.ShouldCreateIfMissing()) {
        return none;
    }
    newLocalDBInstance = LocalDatabaseInstance(_.memory.Allocate(localDBClass));
    loadedLocalDatabases.SetItem(databaseName.Copy(), newLocalDBInstance);
    if (newConfig.HasDefinedRoot())
    {
        rootRecordName = newConfig.GetRootName();
        rootRecord = class'DBRecord'.static
            .LoadRecord(rootRecordName, databaseName);
    }
    else
    {
        rootRecord = class'DBRecord'.static.NewRecord(databaseName);
        rootRecordName = _.text.FromString(string(rootRecord.name));
        newConfig.SetRootName(rootRecordName);
        newConfig.Save();
    }
    newLocalDBInstance.Initialize(newConfig, rootRecord);
    _.logger.Auto(infoLocalDatabaseLoaded).Arg(databaseName.Copy());
    _.memory.Free(rootRecordName);
    _.memory.Free(newLocalDBInstance);
    return newLocalDBInstance;
}

/**
 *  Checks if local database with the name `databaseName` already exists.
 *
 *  @param  databaseName    Name of the database to check.
 *  @return `true` if database with specified name exists and `false` otherwise.
 */
public final function bool ExistsLocal(BaseText databaseName)
{
    local bool                  result;
    local LocalDatabaseInstance instance;

    instance = LoadLocal(databaseName);
    result = (instance != none);
    _.memory.Free(instance);
    return result;
}

/**
 *  Deletes local database with name `databaseName`.
 *
 *  @param  databaseName    Name of the database to delete.
 *  @return `true` if database with specified name existed and was deleted and
 *      `false` otherwise.
 */
public final function bool DeleteLocal(BaseText databaseName)
{
    local LocalDatabase         localDatabaseConfig;
    local LocalDatabaseInstance localDatabase;
    local HashTable.Entry       dbEntry;

    if (databaseName == none) {
        return false;
    }
    CreateLocalDBMapIfMissing();
    //  To delete database we first need to load it
    localDatabase = LoadLocal(databaseName);
    if (localDatabase != none)
    {
        localDatabaseConfig = localDatabase.GetConfig();
        localDatabase.WriteToDisk();
        _.memory.Free(localDatabase);
    }
    dbEntry = loadedLocalDatabases.TakeEntry(databaseName);
    //  Delete `LocalDatabaseInstance` before erasing the package,
    //  to allow it to clean up safely
    _.memory.Free(dbEntry.key);
    _.memory.Free(dbEntry.value);
    if (localDatabaseConfig != none)
    {
        EraseAllPackageData(localDatabaseConfig.GetPackageName());
        localDatabaseConfig.DeleteSelf();
        _.logger.Auto(infoLocalDatabaseDeleted).Arg(databaseName.Copy());
        return true;
    }
    return false;
}

private function EraseAllPackageData(BaseText packageToErase)
{
    local int               i;
    local string            packageName;
    local GameInfo          game;
    local DBRecord          nextRecord;
    local array<DBRecord>   allRecords;

    packageName = _.text.IntoString(packageToErase);
    if (packageName == "") {
        return;
    }
    game = _server.unreal.GetGameType();
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
    infoLocalDatabaseCreated = (l=LOG_Info,m="Local database \"%1\" was created.")
    infoLocalDatabaseLoaded = (l=LOG_Info,m="Local database \"%1\" was loaded.")
    infoLocalDatabaseDeleted = (l=LOG_Info,m="Local database \"%1\" was deleted.")
}