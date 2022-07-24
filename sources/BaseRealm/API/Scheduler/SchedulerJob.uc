/**
 *      Template object that represents a job, capable of being scheduled on the
 *  `SchedulerAPI`. Use `IsCompleted()` to mark job as completed.
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
class SchedulerJob extends AcediaObject
    abstract;

/**
 *  Checks if caller `SchedulerJob` was completed.
 *  Once this method returns `true`, it shouldn't start returning `false` again.
 *
 *  @return `true` if `SchedulerJob` is already completed and doesn't need to
 *      be further executed and `false` otherwise.
 */
public function bool IsCompleted();

/**
 *  Called when scheduler decides that `SchedulerJob` should be executed, taking
 *  amount of abstract "work units" that it is allowed to spend for work.
 *
 *  @param  allottedWorkUnits   Work units allotted to the caller
 *      `SchedulerJob`. By default there is `10000` work units per second, so
 *      you can expect about 10000 / 1000 = 10 work units per millisecond or,
 *      on servers with 30 tick rate, about 10000 * (30 / 1000) = 300 work units
 *      per tick to be allotted to all the scheduled jobs.
 */
public function DoWork(int allottedWorkUnits);

defaultproperties
{
}