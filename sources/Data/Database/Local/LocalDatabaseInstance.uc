/**
 *      Implementation of Acedia's `Database` interface for locally stored
 *  databases.
 *      This class SHOULD NOT be deallocated manually.
 *      This name was chosen so that more readable `LocalDatabase` could be
 *  used in config for defining local databases through per-object-config.
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
class LocalDatabaseInstance extends Database;

/**
 *      `LocalDatabaseInstance` implements `Database` interface for
 *  local databases, however most of the work (everything related to actually
 *  performing operations) is handled by `DBRecord` class.
 *  This class' purpose is to:
 *      1.  Managing updating information stored on the disk: it has to make
 *          sure that saving is (eventually) done after every update, but not
 *          too often, since it is an expensive operation;
 *      2.  Making sure handlers for database queries are called (eventually).
 *      First point is done via starting a "cooldown" timer after every disk
 *  update that will count time until the next one. Second is done by storing
 *  `DBTask`, generated by last database query and making it call it's handler
 *  at the start of next tick.
 *
 *      Why do we wait until the next tick?
 *  Factually, every `LocalDatabaseInstance`'s query is completed immediately.
 *  However, `Database`'s interface is designed to be used like so:
 *  `db.ReadData(...).connect = handler;` where `handler` for query is assigned
 *  AFTER it was filed to the database. Therefore, we cannot call `handler`
 *  inside `ReadData()` and wait until next tick instead.
 *      We could have allowed for immediate query response if we either
 *  requested that handler was somehow set before the query or by providing
 *  a method to immediately call handlers for queries users have made so far.
 *  We avoided these solutions because we intend Acedia's `Database` interface
 *  to be used in the same way regardless of whether server admins have chosen
 *  to use local or remote databases. And neither of these solutions would have
 *  worked with inherently asynchronous remote databases. That is why we instead
 *  opted to use a more convenient interface
 *  `db.ReadData(...).connect = handler;` and have both databases behave
 *  the same way - with somewhat delayed response from the database.
 *      If you absolutely must force your local database to have an immediate
 *  response, then you can do it like so:
 *  ```unrealscript
 *  local DBTask task;
 *  ...
 *  task = db.ReadData(...);
 *  task.connect = handler;
 *  task.TryCompleting();
 *  ```
 *  However this method is not recommended and will never be a part of
 *  a stable interface.
 */

//  Reference to the `LocalDatabase` config object, corresponding to
//  this database
var private LocalDatabase   configEntry;
//  Reference to the `DBRecord` that stores root object of this database
var private DBRecord        rootRecord;

//  As long as this `Timer` runs - we are in the "cooldown" period where no disk
//  updates can be done (except special cases like this object getting
//  deallocated).
var private Timer   diskUpdateTimer;
//  Only relevant when `diskUpdateTimer` is running. `false` would mean there is
//  nothing to new to write and the timer will be discarded, but `true` means
//  that we have to write database on disk and restart the update timer again.
var private bool    needsDiskUpdate;

//  Last to-be-completed task added to this database
var private DBTask  lastTask;
//  Remember task's life version to make sure we still have the correct copy
var private int     lastTaskLifeVersion;

protected function Constructor()
{
    _server.unreal.OnTick(self).connect = CompleteAllTasks;
}

protected function Finalizer()
{
    //  Defaulting variables is not necessary, since this class does not
    //  use object pool.
    CompleteAllTasks();
    WriteToDisk();
    rootRecord = none;
    _server.unreal.OnTick(self).Disconnect();
    _.memory.Free(diskUpdateTimer);
    diskUpdateTimer = none;
    configEntry = none;
}

//  It only has parameters so that it can be used as a `Tick()` event handler.
private final function CompleteAllTasks(
    optional float delta,
    optional float dilationCoefficient)
{
    if (lastTask != none && lastTask.GetLifeVersion() == lastTaskLifeVersion) {
        lastTask.TryCompleting();
    }
    lastTask            = none;
    lastTaskLifeVersion = -1;
}

private final function LocalDatabaseInstance ScheduleDiskUpdate()
{
    if (diskUpdateTimer != none)
    {
        needsDiskUpdate = true;
        return self;
    }
    WriteToDisk();
    needsDiskUpdate = false;
    diskUpdateTimer = _server.time.StartTimer(
        class'LocalDBSettings'.default.writeToDiskDelay);
    diskUpdateTimer.OnElapsed(self).connect = DoDiskUpdate;
    return self;
}

private final function DoDiskUpdate(Timer source)
{
    if (needsDiskUpdate)
    {
        WriteToDisk();
        needsDiskUpdate = false;
        diskUpdateTimer.Start();
    }
    else
    {
        _.memory.Free(diskUpdateTimer);
        diskUpdateTimer = none;
    }
}

private final function WriteToDisk()
{
    local string packageName;
    if (configEntry != none) {
        packageName = _.text.ToString(configEntry.GetPackageName());
    }
    if (packageName != "") {
        _server.unreal.GetGameType().SavePackage(packageName);
    }
}

private final function DBTask MakeNewTask(class<DBTask> newTaskClass)
{
    local DBTask newTask;
    if (lastTask != none && lastTask.GetLifeVersion() != lastTaskLifeVersion)
    {
        lastTask = none;
        lastTaskLifeVersion = -1;
    }
    newTask = DBTask(_.memory.Allocate(newTaskClass));
    newTask.SetPreviousTask(lastTask);
    lastTask            = newTask;
    lastTaskLifeVersion = lastTask.GetLifeVersion();
    return newTask;
}

private function bool ValidatePointer(JSONPointer pointer, DBTask relevantTask)
{
    if (pointer != none) {
        return true;
    }
    relevantTask.SetResult(DBR_InvalidPointer);
    return false;
}

private function bool ValidateRootRecord(DBTask relevantTask)
{
    if (rootRecord != none) {
        return true;
    }
    relevantTask.SetResult(DBR_InvalidDatabase);
    return false;
}

public function DBReadTask ReadData(
    JSONPointer     pointer,
    optional bool   makeMutable)
{
    local AcediaObject  queryResult;
    local DBReadTask    readTask;
    readTask = DBReadTask(MakeNewTask(class'DBReadTask'));
    if (!ValidatePointer(pointer, readTask))    return readTask;
    if (!ValidateRootRecord(readTask))          return readTask;

    if (rootRecord.LoadObject(pointer, queryResult, makeMutable))
    {
        readTask.SetReadData(queryResult);
        readTask.SetResult(DBR_Success);
    }
    else
    {
        readTask.SetResult(DBR_InvalidPointer);
        _.memory.Free(queryResult); //  just in case
    }
    return readTask;
}

public function DBWriteTask WriteData(JSONPointer pointer, AcediaObject data)
{
    local bool          isDataStorable;
    local DBWriteTask   writeTask;
    writeTask = DBWriteTask(MakeNewTask(class'DBWriteTask'));
    if (!ValidatePointer(pointer, writeTask))   return writeTask;
    if (!ValidateRootRecord(writeTask))         return writeTask;

    //  We can only write JSON array as the root value
    if (data != none && pointer.GetLength() <= 0) {
        isDataStorable = (data.class == class'HashTable');
    }
    else {
        isDataStorable = _.json.IsCompatible(data);
    }
    if (!isDataStorable)
    {
        writeTask.SetResult(DBR_InvalidData);
        return writeTask;
    }
    if (rootRecord.SaveObject(pointer, data))
    {
        writeTask.SetResult(DBR_Success);
        ScheduleDiskUpdate();
    }
    else {
        writeTask.SetResult(DBR_InvalidPointer);
    }
    return writeTask;
}

public function DBRemoveTask RemoveData(JSONPointer pointer)
{
    local DBRemoveTask removeTask;
    removeTask = DBRemoveTask(MakeNewTask(class'DBRemoveTask'));
    if (!ValidatePointer(pointer, removeTask))  return removeTask;
    if (!ValidateRootRecord(removeTask))        return removeTask;

    if (pointer.GetLength() == 0)
    {
        rootRecord.EmptySelf();
        removeTask.SetResult(DBR_Success);
        return removeTask;
    }
    if (rootRecord.RemoveObject(pointer))
    {
        removeTask.SetResult(DBR_Success);
        ScheduleDiskUpdate();
    }
    else {
        removeTask.SetResult(DBR_InvalidPointer);
    }
    return removeTask;
}

public function DBCheckTask CheckDataType(JSONPointer pointer)
{
    local DBCheckTask checkTask;
    checkTask = DBCheckTask(MakeNewTask(class'DBCheckTask'));
    if (!ValidatePointer(pointer, checkTask))   return checkTask;
    if (!ValidateRootRecord(checkTask))         return checkTask;

    checkTask.SetDataType(rootRecord.GetObjectType(pointer));
    checkTask.SetResult(DBR_Success);
    return checkTask;
}

public function DBSizeTask GetDataSize(JSONPointer pointer)
{
    local DBSizeTask sizeTask;
    sizeTask = DBSizeTask(MakeNewTask(class'DBSizeTask'));
    if (!ValidatePointer(pointer, sizeTask))    return sizeTask;
    if (!ValidateRootRecord(sizeTask))          return sizeTask;

    sizeTask.SetDataSize(rootRecord.GetObjectSize(pointer));
    sizeTask.SetResult(DBR_Success);
    return sizeTask;
}

public function DBKeysTask GetDataKeys(JSONPointer pointer)
{
    local ArrayList     keys;
    local DBKeysTask    keysTask;
    keysTask = DBKeysTask(MakeNewTask(class'DBKeysTask'));
    if (!ValidatePointer(pointer, keysTask))    return keysTask;
    if (!ValidateRootRecord(keysTask))          return keysTask;

    keys = rootRecord.GetObjectKeys(pointer);
    keysTask.SetDataKeys(keys);
    if (keys == none) {
        keysTask.SetResult(DBR_InvalidData);
    }
    else {
        keysTask.SetResult(DBR_Success);
    }
    return keysTask;
}

public function DBIncrementTask IncrementData(
    JSONPointer     pointer,
    AcediaObject    increment)
{
    local DBQueryResult     queryResult;
    local DBIncrementTask   incrementTask;
    incrementTask = DBIncrementTask(MakeNewTask(class'DBIncrementTask'));
    if (!ValidatePointer(pointer, incrementTask))   return incrementTask;
    if (!ValidateRootRecord(incrementTask))         return incrementTask;

    queryResult = rootRecord.IncrementObject(pointer, increment);
    incrementTask.SetResult(queryResult);
    if (queryResult == DBR_Success) {
        ScheduleDiskUpdate();
    }
    return incrementTask;
}

/**
 *  Initializes caller database with prepared config and root objects.
 *
 *  This is internal method and should not be called outside of `DBAPI`.
 */
public final function Initialize(LocalDatabase config, DBRecord root)
{
    if (configEntry != none)    return;
    if (config == none)         return;

    configEntry = config;
    rootRecord = root;
    ScheduleDiskUpdate();
}

/**
 *  Returns config object that describes caller database.
 *
 *  @return Config object that describes caller database.
 *      returned value is the same value caller database uses,
 *      it IS NOT a copy and SHOULD NOT be deallocated or deleted.
 */
public final function LocalDatabase GetConfig()
{
    return configEntry;
}

defaultproperties
{
    usesObjectPool = false
}