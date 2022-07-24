/**
 *      API that provides functions for scheduling jobs and expensive tasks such
 *  as writing onto the disk. Also provides methods for users to inform API that
 *  they've recently did an expensive operation, so that `SchedulerAPI` is to
 *  try and use less resources when managing jobs.
 *      Copyright 2022 Anton Tarasenko
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
class SchedulerAPI extends AcediaObject
    config(AcediaSystem);

/**
 *  # `SchedulerAPI`
 *
 *      UnrealScript is inherently single-threaded and whatever method you call,
 *  it will be completely executed within a single game's tick. 
 *  This API is meant for scheduling various actions over time to help emulating
 *  multi-threading by spreading some code executions over several different
 *  game/server ticks.
 *
 *  ## Usage
 *
 *  ### Job scheduling
 *
 *      One of the reasons which is faulty infinite loop detection system that
 *  will crash the game/server if it thinks UnrealScript code has executed too
 *  many operations (it is not about execution time, logging a lot of messages
 *  with `Log()` can take a lot of time and not crash anything, while simple
 *  loop, that would've finished much sooner, can trigger a crash).
 *      This is a very atypical problem for mods to have, but Acedia's
 *  introduction of databases and avarice link can lead to users trying to read
 *  (from database or network) an object that is too big, leading to a crash.
 *      Jobs are not about performance, they're about crash prevention.
 *
 *      In case you have such a job of your own, that can potentially take too
 *  many steps to finish without crashing, you can convert it into
 *  a `SchedulerJob` (you make a subclass for your type of the job and
 *  instantiate it for each execution of the job). This requires you to
 *  restructure your algorithm in such a way, that it is able to run for some
 *  finite (maybe small) amount of steps and postpone the rest of calculations
 *  to the next tick and put it into a method
 *  `SchedulerJob.DoWork(int allottedWorkUnits)`, where `allottedWorkUnits` is
 *  how much your method is allowed to do during this call, assuming `10000`
 *  units of work on their own won't lead to a crash.
 *      Another method `SchedulerJob.IsCompleted()` needs to be setup to return
 *  `true` iff your job is done.
 *      After you prepared an instance of your job subclass, simply pass it to
 *  `_.scheduler.AddJob()`.
 *
 *  ### Disk usage requests
 *
 *      Writing to the disk (saving data into config file, saving local database
 *  changes) can be an expensive operation and to avoid lags in gameplay you
 *  might want to spread such operations over time.
 *  `_.scheduler.RequestDiskAccess()` method allows you to do that. It is not
 *  exactly a signal, but it acts similar to one: to request a right to save to
 *  the disk, just do the following:
 *  `_.scheduler.RequestDiskAccess(<receiver>).connect = <disk_writing_method>`
 *  and `disk_writing_method()` will be called once your turn come up.
 *
 *  ## Manual ticking
 *
 *      If any kind of level core (either server or client one) was created,
 *  this API will automatically perform necessary actions every tick.
 *  Otherwise, if only base API is available, there's no way to do that, but
 *  you can manually decide when to tick this API by calling `ManualTick()`
 *  method.
 */

/**
 *      How often can files be saved on disk. This is a relatively expensive
 *  operation and we don't want to write a lot of different files at once.
 *  But since we lack a way to exactly measure how much time that saving will
 *  take, AcediaCore falls back to simply performing every saving with same
 *  uniform time intervals in-between.
 *      This variable decides how much time there should be between two file
 *  writing accesses.
 *      Negative and zero values mean that all writing disk access will be
 *  granted as soon as possible, without any cooldowns.
 */
var private config float diskSaveCooldown;
/**
 *  Maximum total work units for jobs allowed per tick. Jobs are expected to be
 *  constructed such that they don't lead to a crash if they have to perform
 *  this much work.
 *
 *  Changing default value of `10000` is not advised.
 */
var private config int maxWorkUnits;
/**
 *  How many different jobs can be performed per tick. This limit is added so
 *  that `maxWorkUnits` won't be spread too thin if a lot of jobs get registered
 *  at once.
 */
var private config int maxJobsPerTick;

//  We can (and will) automatically tick
var private bool tickAvailable;
//  `true`  == it is safe to use server API for a tick
//  `false` == it is safe to use client API for a tick
var private bool tickFromServer;
//      Our `Tick()` method is currently connected to the `OnTick()` signal.
//      Keeping track of this allows us to disconnect from `OnTick()` signal
//  when it is not necessary.
var private bool connectedToTick;

//  How much time if left until we can write to the disk again?
var private float currentDiskCooldown;

//      There is a limit (`maxJobsPerTick`) to how many different jobs we can
//  perform per tick and if we register an amount jobs over that limit, we need
//  to uniformly spread execution time between them.
//      To achieve that we simply cyclically (in order) go over `currentJobs`
//  array, each time executing exactly `maxJobsPerTick` jobs.
//  `nextJobToPerform` remembers what job is to be executed next tick.
var private int                 nextJobToPerform;
var private array<SchedulerJob> currentJobs;
//      Storing receiver objects, following example of signals/slots, is done
//  without increasing their reference count, allowing them to get deallocated
//  while we are still keeping their reference.
//      To avoid using such deallocated receivers, we keep track of the life
//  versions they've had when their disk requests were registered.
var private array<SchedulerDiskRequest> diskQueue;
var private array<AcediaObject>         receivers;
var private array<int>                  receiversLifeVersions;

/**
 *  Registers new scheduler job `newJob` to be executed in the API.
 *
 *  @param  newJob  New job to be scheduled for execution.
 *      Does nothing if given `newJob` is already added.
 */
public function AddJob(SchedulerJob newJob)
{
    local int i;

    if (newJob == none) {
        return;
    }
    for (i = 0; i < currentJobs.length; i += 1)
    {
        if (currentJobs[i] == newJob) {
            return;
        }
    }
    newJob.NewRef();
    currentJobs[currentJobs.length] = newJob;
    UpdateTickConnection();
}

/**
 *  Requests another disk access.
 *
 *  Use it like signal: `RequestDiskAccess(<receiver>).connect = <handler>`.
 *  Since it is meant to be used as a signal, so DO NOT STORE/RELEASE returned
 *  wrapper object `SchedulerDiskRequest`.
 *
 *  @param  receiver    Same as for signal/slots, this is an object, responsible
 *      for the disk request. If this object gets deallocated - request will be
 *      thrown away.
 *      Typically this should be an object in which connected method will be
 *      executed.
 *  @return Wrapper object that provides `connect` delegate.
 */
public function SchedulerDiskRequest RequestDiskAccess(AcediaObject receiver)
{
    local SchedulerDiskRequest newRequest;

    if (receiver == none)           return none;
    if (!receiver.IsAllocated())    return none;

    newRequest =
        SchedulerDiskRequest(_.memory.Allocate(class'SchedulerDiskRequest'));
    diskQueue[diskQueue.length] = newRequest;
    receivers[receivers.length] = receiver;
    receiversLifeVersions[receiversLifeVersions.length] =
        receiver.GetLifeVersion();
    UpdateTickConnection();
    return newRequest;
}

/**
 *  Tells you how many incomplete jobs are currently registered in
 *  the scheduler.
 *
 *  @return How many incomplete jobs are currently registered in the scheduler.
 */
public function int GetJobsAmount()
{
    CleanCompletedJobs();
    return currentJobs.length;
}

/**
 *  Tells you how many disk access requests are currently registered in
 *  the scheduler.
 *
 *  @return How many incomplete disk access requests are currently registered
 *      in the scheduler.
 */
public function int GetDiskQueueSize()
{
    CleanDiskQueue();
    return diskQueue.length;
}

/**
 *      In case neither server, nor client core is registered, scheduler must be
 *  ticked manually. For that call this method each separate tick (or whatever
 *  is your closest approximation available for that).
 *
 *      Before manually invoking this method, you should check if scheduler
 *  actually started to tick *automatically*. Use `_.scheduler.IsAutomated()`
 *  for that.
 *
 *  NOTE: If neither server-/client- core is created, nor `ManualTick()` is
 *  invoked manually, `SchedulerAPI` won't actually do anything.
 *
 *  @param  delta   Time (real one) that is supposedly passes from the moment
 *      `ManualTick()` was called last time. Used for tracking disk access
 *      cooldowns. How `SchedulerJob`s are executed is independent from this
 *      value.
 */
public final function ManualTick(optional float delta)
{
    Tick(delta, 1.0);
}

/**
 *      Is scheduler ticking automated? It can only be automated if either
 *  server or client level cores are created. Scheduler can automatically enable
 *  automation and it cannot be prevented, but can be helped by using
 *  `UpdateTickConnection()` method.
 *
 *  @return `true` if scheduler's tick is automatically called and `false`
 *      otherwise (and calling `ManualTick()` is required).
 */
public function bool IsAutomated()
{
    return tickAvailable;
}

/**
 *  Causes `SchedulerAPI` to try automating itself by searching for level cores
 *  (checking if server/client APIs are enabled).
 */
public function UpdateTickConnection()
{
    local bool      needsConnection;
    local UnrealAPI api;

    if (!tickAvailable)
    {
        if (_server.IsAvailable())
        {
            tickAvailable   = true;
            tickFromServer  = true;
        }
        else if (_client.IsAvailable())
        {
            tickAvailable   = true;
            tickFromServer  = false;
        }
        if (!tickAvailable) {
            return;
        }
    }
    needsConnection = (currentJobs.length > 0 || diskQueue.length > 0);
    if (connectedToTick == needsConnection) {
        return;
    }
    if (tickFromServer) {
        api = _server.unreal;
    }
    else {
        api = _client.unreal;
    }
    if (connectedToTick && !needsConnection) {
        api.OnTick(self).Disconnect();
    }
    else if (!connectedToTick && needsConnection) {
        api.OnTick(self).connect = Tick;
    }
    connectedToTick = needsConnection;
}

private function Tick(float delta, float dilationCoefficient)
{
    delta = delta / dilationCoefficient;
    //  Manage disk cooldown
    if (currentDiskCooldown > 0) {
        currentDiskCooldown -= delta;
    }
    if (currentDiskCooldown <= 0 && diskQueue.length > 0)
    {
        currentDiskCooldown = diskSaveCooldown;
        ProcessDiskQueue();
    }
    //  Manage jobs
    if (currentJobs.length > 0) {
        ProcessJobs();
    }
    UpdateTickConnection();
}

private function ProcessJobs()
{
    local int unitsPerJob;
    local int jobsToPerform;

    CleanCompletedJobs();
    jobsToPerform = Min(currentJobs.length, maxJobsPerTick);
    if (jobsToPerform <= 0) {
        return;
    }
    unitsPerJob = maxWorkUnits / jobsToPerform;
    while (jobsToPerform > 0)
    {
        if (nextJobToPerform >= currentJobs.length) {
            nextJobToPerform = 0;
        }
        currentJobs[nextJobToPerform].DoWork(unitsPerJob);
        nextJobToPerform += 1;
        jobsToPerform -= 1;
    }
}

private function ProcessDiskQueue()
{
    local int i;

    //  Even if we clean disk queue here, we still need to double check
    //  lifetimes in the code below, since we have no idea what `.connect()`
    //  calls might do
    CleanDiskQueue();
    if (diskQueue.length <= 0) {
        return;
    }
    if (diskSaveCooldown > 0)
    {
        if (receivers[i].GetLifeVersion() == receiversLifeVersions[i]) {
            diskQueue[i].connect();
        }
        _.memory.Free(diskQueue[0]);
        diskQueue.Remove(0, 1);
        receivers.Remove(0, 1);
        receiversLifeVersions.Remove(0, 1);
        return;
    }
    for (i = 0; i < diskQueue.length; i += 1)
    {
        if (receivers[i].GetLifeVersion() == receiversLifeVersions[i]) {
            diskQueue[i].connect();
        }
        _.memory.Free(diskQueue[i]);
    }
    diskQueue.length = 0;
    receivers.length = 0;
    receiversLifeVersions.length = 0;
}

//  Removes completed jobs
private function CleanCompletedJobs()
{
    local int i;

    while (i < currentJobs.length)
    {
        if (currentJobs[i].IsCompleted())
        {
            if (i < nextJobToPerform) {
                nextJobToPerform -= 1;
            }
            currentJobs[i].FreeSelf();
            currentJobs.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
}

//  Remove disk requests with deallocated receivers
private function CleanDiskQueue()
{
    local int i;

    while (i < diskQueue.length)
    {
        if (receivers[i].GetLifeVersion() == receiversLifeVersions[i])
        {
            i += 1;
            continue;
        }
        _.memory.Free(diskQueue[i]);
        diskQueue.Remove(i, 1);
        receivers.Remove(i, 1);
        receiversLifeVersions.Remove(i, 1);
    }
}

defaultproperties
{
    diskSaveCooldown    = 0.25
    maxWorkUnits        = 10000
    maxJobsPerTick      = 5
}