/**
 *  Set of tests for Scheduler API.
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
class TEST_SchedulerAPI extends TestCase
    abstract;

var int diskUses;

protected static function UseDisk()
{
    default.diskUses += 1;
}

protected static function MockJob MakeJob(string mark, int totalUnits)
{
    local MockJob newJob;

    newJob = MockJob(__().memory.Allocate(class'MockJob'));
    newJob.mark         = mark;
    newJob.unitsLeft    = totalUnits;
    return newJob;
}

protected static function TESTS()
{
    Test_MockJob();
}

protected static function Test_MockJob()
{
    Context("Testing job scheduling.");
    SubText_SimpleScheduling();
    SubText_ManyScheduling();
    SubText_DiskScheduling();
    SubText_DiskSchedulingDeallocate();
    SubText_JobDiskMix();
}

protected static function SubText_SimpleScheduling()
{
    Issue("Simple scheduling doesn't process jobs in intended order");
    class'MockJob'.default.callStack = "";
    __().scheduler.ManualTick(); //  Reset work units
    __().scheduler.AddJob(MakeJob("A", 2400));
    __().scheduler.AddJob(MakeJob("B", 3000));
    __().scheduler.AddJob(MakeJob("C", 7600));
    __().scheduler.AddJob(MakeJob("D", 1000));
    __().scheduler.ManualTick();    //  10,000 units => -2,500 units per job
    TEST_ExpectTrue(class'MockJob'.default.callStack == "AD");
    TEST_ExpectTrue(__().scheduler.GetJobsAmount() == 2);
    __().scheduler.ManualTick();    //  10,000 units => -5,000 units per job
    TEST_ExpectTrue(class'MockJob'.default.callStack == "ADB");
    TEST_ExpectTrue(__().scheduler.GetJobsAmount() == 1);
    __().scheduler.ManualTick();    //  10,000 units => -5,000 units per job
    TEST_ExpectTrue(class'MockJob'.default.callStack == "ADBC");
    TEST_ExpectTrue(__().scheduler.GetJobsAmount() == 0);
}

protected static function SubText_ManyScheduling()
{
    Issue("After scheduling jobs over per-tick limit, scheduler doesn't process"
        @ "jobs in intended order");
    class'MockJob'.default.callStack = "";
    __().scheduler.ManualTick();    //  Reset work units
    //  10,000 units => 2,000 units per job for 5 jobs
    __().scheduler.AddJob(MakeJob("A", 3000));
    __().scheduler.AddJob(MakeJob("B", 3000));
    __().scheduler.AddJob(MakeJob("C", 3000));
    __().scheduler.AddJob(MakeJob("D", 1000));
    __().scheduler.AddJob(MakeJob("E", 3000));
    __().scheduler.AddJob(MakeJob("F", 3000));
    __().scheduler.AddJob(MakeJob("G", 1000));
    __().scheduler.AddJob(MakeJob("H", 5000));
    __().scheduler.AddJob(MakeJob("I", 1000));
    __().scheduler.ManualTick();
    //  A:1000, B:1000, C:1000, D:0, E:1000, F:3000, G:1000, H:5000, I:1000
    TEST_ExpectTrue(class'MockJob'.default.callStack == "D");
    TEST_ExpectTrue(__().scheduler.GetJobsAmount() == 8);
    __().scheduler.ManualTick();
    //  A:0, B:1000, C:1000, D:0, E:1000, F:1000, G:0, H:3000, I:0
    TEST_ExpectTrue(class'MockJob'.default.callStack == "DGIA");
    TEST_ExpectTrue(__().scheduler.GetJobsAmount() == 5);
    __().scheduler.ManualTick();
    //  A:0, B:0, C:0, D:0, E:0, F:0, G:0, H:1000, I:0
    TEST_ExpectTrue(class'MockJob'.default.callStack == "DGIABCEF");
    TEST_ExpectTrue(__().scheduler.GetJobsAmount() == 1);
    __().scheduler.ManualTick();
    //  A:0, B:0, C:0, D:0, E:0, F:0, G:0, H:0, I:0
    TEST_ExpectTrue(class'MockJob'.default.callStack == "DGIABCEFH");
    TEST_ExpectTrue(__().scheduler.GetJobsAmount() == 0);
}

protected static function SubText_DiskScheduling()
{
    local Text objectInstance;

    Issue("Disk scheduling doesn't happen at expected intervals.");
    default.diskUses = 0;
    __().scheduler.ManualTick(1.0); //  Pre-fill cooldown, just in case
    objectInstance = __().text.FromString("whatever");
    __().scheduler.RequestDiskAccess(objectInstance).connect = UseDisk;
    __().scheduler.RequestDiskAccess(objectInstance).connect = UseDisk;
    __().scheduler.RequestDiskAccess(objectInstance).connect = UseDisk;
    __().scheduler.RequestDiskAccess(objectInstance).connect = UseDisk;
    __().scheduler.ManualTick(0.001);
    TEST_ExpectTrue(default.diskUses == 1);
    __().scheduler.ManualTick(0.21);
    TEST_ExpectTrue(default.diskUses == 1);
    TEST_ExpectTrue(__().scheduler.GetDiskQueueSize() == 3);
    __().scheduler.ManualTick(0.2);
    TEST_ExpectTrue(default.diskUses == 2);
    __().scheduler.ManualTick(0.21);
    TEST_ExpectTrue(default.diskUses == 2);
    TEST_ExpectTrue(__().scheduler.GetDiskQueueSize() == 2);
    __().scheduler.ManualTick(0.2);
    TEST_ExpectTrue(default.diskUses == 3);
    TEST_ExpectTrue(__().scheduler.GetDiskQueueSize() == 1);
    __().scheduler.ManualTick(0.1);
    TEST_ExpectTrue(default.diskUses == 3);
    __().scheduler.ManualTick(0.1);
    TEST_ExpectTrue(default.diskUses == 3);
    TEST_ExpectTrue(__().scheduler.GetDiskQueueSize() == 1);
    __().scheduler.ManualTick(0.1);
    TEST_ExpectTrue(default.diskUses == 4);
    TEST_ExpectTrue(__().scheduler.GetDiskQueueSize() == 0);
}

protected static function SubText_DiskSchedulingDeallocate()
{
    local Text objectInstance, deletedInstance;

    Issue("Disk scheduling cannot correctly handle deallocated receivers.");
    default.diskUses = 0;
    __().scheduler.ManualTick(1.0); //  Pre-fill cooldown, just in case
    objectInstance = __().text.FromString("whatever");
    deletedInstance = __().text.FromString("heh");
    __().scheduler.RequestDiskAccess(objectInstance).connect = UseDisk;
    __().scheduler.RequestDiskAccess(deletedInstance).connect = UseDisk;
    __().scheduler.RequestDiskAccess(objectInstance).connect = UseDisk;
    __().scheduler.RequestDiskAccess(deletedInstance).connect = UseDisk;
    //  Fuck off the `deletedInstance` object
    deletedInstance.FreeSelf();
    //  Test!
    __().scheduler.ManualTick(0.001);
    TEST_ExpectTrue(default.diskUses == 1);
    __().scheduler.ManualTick(0.21);
    TEST_ExpectTrue(default.diskUses == 1);
    __().scheduler.ManualTick(0.2);
    TEST_ExpectTrue(default.diskUses == 2);
    __().scheduler.ManualTick(0.21);
    TEST_ExpectTrue(default.diskUses == 2);
    __().scheduler.ManualTick(0.2);
    TEST_ExpectTrue(default.diskUses == 2);
    __().scheduler.ManualTick(1.0);
    TEST_ExpectTrue(default.diskUses == 2);
}

protected static function SubText_JobDiskMix()
{
    local Text objectInstance;

    Issue("Job and disk scheduling doesn't happen at expected intervals.");
    objectInstance = __().text.FromString("whatever");
    class'MockJob'.default.callStack = "";
    default.diskUses = 0;
    __().scheduler.ManualTick(1.0); //  Reset work units
    //  0.2 * 10,000 = 2,000 units => 1,000 units per job for 2 jobs
    __().scheduler.AddJob(MakeJob("A", 30000));
    __().scheduler.AddJob(MakeJob("B", 10000));
    __().scheduler.RequestDiskAccess(objectInstance).connect = UseDisk;
    __().scheduler.RequestDiskAccess(objectInstance).connect = UseDisk;
    //  Reset disk cooldown
    __().scheduler.ManualTick(0.2);
    //  A:25000, B:5000
    TEST_ExpectTrue(default.diskUses == 1);
    __().scheduler.ManualTick(0.2); //  Disk on cooldown
    //  A:20000, B:0
    TEST_ExpectTrue(class'MockJob'.default.callStack == "B");
    TEST_ExpectTrue(__().scheduler.GetJobsAmount() == 1);
    TEST_ExpectTrue(default.diskUses == 1);
    TEST_ExpectTrue(__().scheduler.GetDiskQueueSize() == 1);
    __().scheduler.ManualTick(0.2); //  Disk got off cooldown, do writing
    //  A:10000, B:0
    TEST_ExpectTrue(class'MockJob'.default.callStack == "B");
    TEST_ExpectTrue(__().scheduler.GetJobsAmount() == 1);
    TEST_ExpectTrue(default.diskUses == 2);
    TEST_ExpectTrue(__().scheduler.GetDiskQueueSize() == 0);
    __().scheduler.ManualTick(0.2); //  Disk on cooldown
    //  A:0, B:0
    TEST_ExpectTrue(class'MockJob'.default.callStack == "BA");
    TEST_ExpectTrue(__().scheduler.GetJobsAmount() == 0);
    TEST_ExpectTrue(default.diskUses == 2);
    TEST_ExpectTrue(__().scheduler.GetDiskQueueSize() == 0);
}

defaultproperties
{
    caseName    = "SchedulerAPI"
    caseGroup   = "Scheduler"
}