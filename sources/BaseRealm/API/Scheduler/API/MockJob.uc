/**
 *      Simple object that represents a job, capable of being scheduled on the
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
class MockJob extends SchedulerJob;

var public string   mark;
var public int      unitsLeft;

//  We use `default` value only
var public string callStack;

public function bool IsCompleted()
{
    return (unitsLeft <= 0);
}

public function DoWork(int allottedWorkUnits)
{
    unitsLeft -= allottedWorkUnits;
    if (IsCompleted()) {
        default.callStack = default.callStack $ mark;
    }
}

defaultproperties
{
}