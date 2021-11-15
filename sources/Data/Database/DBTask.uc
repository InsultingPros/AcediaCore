/**
 *      This should be considered an internal class and a detail of
 *  implementation.
 *      An object that is created when user tries to query database.
 *      It contains a delegate `connect()` that will be called when query is
 *  completed and will self-destruct afterwards. Concrete delegates are
 *  declared in child classes of this `DBTask`, since they can have different
 *  signatures, depending on the query.
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
class DBTask extends AcediaObject
    dependson(Database)
    abstract;

/**
 *  Life of instances of this class is supposed to go like so:
 *      1.  Get created and returned to the user that made database query so
 *          that he can setup a delegate that will receive the result;
 *      2.  Wait until database query result is ready AND all previous tasks
 *          have completed;
 *      3.  Call it's `connect()` delegate with query results;
 *      4.  Deallocate itself.
 *
 *  Task is determined ready when it's `DBQueryResult` variable was set.
 *
 *  This class IS NOT supposed to be accessed by user at all - this is simply
 *  an auxiliary construction that allows us to make calls to the database
 *  like so: `db.ReadData(...).connect = handler;`.
 *
 *  Since every query can have it's own set of returning parameters -
 *  signature of `connect()` method can vary from task to task.
 *  For this reason we define it in child classes of `BDTask` that specialize in
 *  particular query.
 */

var private DBTask  previousTask;
//  These allows us to detect when previous task got completed (deallocated)
var private int     previousTaskLifeVersion;

var private Database.DBQueryResult  taskResult;
var private bool                    isReadyToComplete;

var private LoggerAPI.Definition errLoopInTaskChain;

protected function Finalizer()
{
    if (previousTask != none) {
        previousTask.FreeSelf(previousTaskLifeVersion);
    }
    previousTask            = none;
    previousTaskLifeVersion = -1;
    isReadyToComplete       = false;
}

/**
 *  Sets `DBQueryResult` for the caller task.
 *  
 *  Having previous task assigned is not required for the caller task to
 *  be completed, since it can be the first task.
 *
 *  @param  task    Task that has to be completed before this one can.
 */
public final function SetPreviousTask(DBTask task)
{
    previousTask = task;
    if (previousTask != none) {
        previousTaskLifeVersion = previousTask.GetLifeVersion();
    }
}

/**
 *  Returns `DBQueryResult` assigned to the caller `DBTask`.
 *
 *  This method should only be called after `SetResult()`, otherwise it's
 *  behavior and return result should be considered undefined.
 *
 *  @return `DBQueryResult` assigned to the caller `DBTask`.
 */
public final function Database.DBQueryResult GetResult()
{
    return taskResult;
}

/**
 *  Assigns `DBQueryResult` for the caller task.
 *  
 *  Every single task has to be assigned one and cannot be completed before
 *  it does.
 *
 *  This value can be assigned several times and the last assigned value will
 *  be used.
 *
 *  @param  result  Result of the query, relevant to the caller task.
 */
public final function SetResult(Database.DBQueryResult result)
{
    taskResult          = result;
    isReadyToComplete   = true;
}

/**
 *  Override this to call `connect()` delegate declared in child classes.
 *  Since this base class does not itself have `connect()` delegate declared -
 *  this method cannot be implemented here.
 */
protected function CompleteSelf(Database source) {}

/**
 *  Attempts to complete this task.
 *  Can only succeed iff caller task both has necessary data to complete it's
 *  query and all previous tasks have completed.
 *
 *  @param  source  Database that will be passed to `DBTask`'s delegate as
 *      its cause.
 */
public final function TryCompleting(optional Database source)
{
    local int           i;
    local array<DBTask> tasksQueue;
    tasksQueue = BuildRequiredTasksQueue();
    //  Queue is built backwards: tasks that have to be completed first are
    //  at the end of the array
    for (i = tasksQueue.length - 1; i >= 0; i -= 1)
    {
        if (tasksQueue[i].isReadyToComplete)
        {
            tasksQueue[i].CompleteSelf(source);
            _.memory.Free(tasksQueue[i]);
        }
        else {
            break;
        }
    }
}

//  We do not know how deep `previousTask`-based chain will go, so we
//  will store tasks that have to complete last earlier in the array.
private final function array<DBTask> BuildRequiredTasksQueue()
{
    local int           i;
    local int           expectedLifeVersion;
    local bool          loopDetected;
    local DBTask        nextRequiredTask;
    local array<DBTask> tasksQueue;
    nextRequiredTask = self;
    tasksQueue[0] = nextRequiredTask;
    while (nextRequiredTask.previousTask != none)
    {
        expectedLifeVersion = nextRequiredTask.previousTaskLifeVersion;
        nextRequiredTask    = nextRequiredTask.previousTask;
        if (nextRequiredTask.GetLifeVersion() != expectedLifeVersion) {
            break;
        }
        for (i = 0; i < tasksQueue.length; i += 1)
        {
            if (nextRequiredTask == tasksQueue[i])
            {
                loopDetected = true;
                break;
            }
        }
        if (!loopDetected) {
            tasksQueue[tasksQueue.length] = nextRequiredTask;
        }
        else
        {
            _.logger.Auto(errLoopInTaskChain).ArgClass(nextRequiredTask.class);
            break;
        }
    }
    return tasksQueue;
}

defaultproperties
{
    errLoopInTaskChain = (l=LOG_Error,m="`DBTask` of class `%1` required itself to complete. This might cause database to get damaged unexpectedly. Please report this to the developer.")
}