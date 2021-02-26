/**
 *  Set of tests related to `MemoryAPI` class and the chain of events related to
 *  creating/destroying Acedia's objects / actors.
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
class TEST_Memory extends TestCase
    abstract;

protected static function TESTS()
{
    Test_ObjectConstructorsFinalizers();
    Test_ActorConstructorsFinalizers();
    Test_ObjectPoolUsage();
    Test_ActorPoolUsage();
    Test_LifeVersionIsUnique();
}

protected static function Test_LifeVersionIsUnique()
{
    local int               i, j;
    local int               nextVersion;
    local MockObject        obj;
    local MockActorWithPool act;
    local array<int>        objectVersions;
    local array<int>        actorVersions;
    local bool              versionsRepeated;
    //      Deallocate and reallocate same object/actor a bunch of times and
    //  ensure that every single time a unique number is returned.
    //      Not a comprehensive test of uniqueness, but such is impossible.
    for (i = 0; i < 1000 && !versionsRepeated; i += 1)
    {
        //  Object
        obj = MockObject(__().memory.Allocate(class'MockObject'));
        nextVersion = obj.GetLifeVersion();
        for (j = 0; j < objectVersions.length; j += 1)
        {
            if (nextVersion == objectVersions[j])
            {
                versionsRepeated = true;
                break;
            }
        }
        objectVersions[objectVersions.length] = nextVersion;
        __().memory.Free(obj);
        //  Actor
        act = MockActorWithPool(__().memory.Allocate(class'MockActorWithPool'));
        nextVersion = act.GetLifeVersion();
        for (j = 0; j < actorVersions.length; j += 1)
        {
            if (nextVersion == actorVersions[j])
            {
                versionsRepeated = true;
                break;
            }
        }
        actorVersions[actorVersions.length] = nextVersion;
        __().memory.Free(act);
    }
    Context("Testing that `GetLifeVersion()` returns unique value for Acedia's"
        @ "actors/objects after each reallocation.");
    Issue("`GetLifeVersion()` repeats the same version within 1000 attempts.");
    TEST_ExpectFalse(versionsRepeated);
}

protected static function Test_ObjectConstructorsFinalizers()
{
    local MockObject obj1, obj2;
    Context("Testing that Acedia object's constructors and finalizers are"
        @ "called properly.");
    Issue("Object's constructor is not called.");
    obj1 = MockObject(__().memory.Allocate(class'MockObject'));
    TEST_ExpectTrue(class'MockObject'.default.objectCount == 1);
    obj2 = MockObject(__().memory.Allocate(class'MockObject'));
    TEST_ExpectTrue(class'MockObject'.default.objectCount == 2);

    Issue("Object's finalizer is not called.");
    __().memory.Free(obj1);
    TEST_ExpectTrue(class'MockObject'.default.objectCount == 1);

    Issue("`IsAllocated()` returns `false` for allocated objects.");
    TEST_ExpectTrue(obj2.IsAllocated());

    Issue("`IsAllocated()` returns `true` for deallocated objects.");
    TEST_ExpectFalse(obj1.IsAllocated());

    Issue("Object's finalizer is called for already freed object.");
    __().memory.Free(obj1);
    TEST_ExpectTrue(class'MockObject'.default.objectCount == 1);

    Issue("Object's finalizer is not called.");
    __().memory.Free(obj2);
    TEST_ExpectTrue(class'MockObject'.default.objectCount == 0);
}

protected static function Test_ActorConstructorsFinalizers()
{
    local MockActor         act1, act2;
    local MockActorWithPool poolActor;
    Context("Testing that Acedia actor's constructors and finalizers are"
        @ "called properly.");
    Issue("Actor's constructor is not called.");
    act1 = MockActor(__().memory.Allocate(class'MockActor'));
    TEST_ExpectTrue(class'MockActor'.default.actorCount == 1);
    act2 = MockActor(__().memory.Allocate(class'MockActor'));
    TEST_ExpectTrue(class'MockActor'.default.actorCount == 2);

    Issue("Actor's finalizer is not called.");
    __().memory.Free(act1);
    TEST_ExpectTrue(class'MockActor'.default.actorCount == 1);

    Issue("`IsAllocated()` returns `false` for allocated actors.");
    TEST_ExpectTrue(act2.IsAllocated());

    Issue("`IsAllocated()` returns `true` for deallocated actors.");
    poolActor =
        MockActorWithPool(__().memory.Allocate(class'MockActorWithPool'));
    __().memory.Free(poolActor);
    TEST_ExpectNotNone(poolActor);
    TEST_ExpectFalse(poolActor.IsAllocated());

    Issue("Actor's finalizer is called for already freed object.");
    __().memory.Free(act1);
    TEST_ExpectTrue(class'MockActor'.default.actorCount == 1);

    Issue("Actor's finalizer is not called.");
    __().memory.Free(act2);
    TEST_ExpectTrue(class'MockActor'.default.actorCount == 0);
}

protected static function Test_ObjectPoolUsage()
{
    local bool              allocatedNewObject;
    local int               i, j;
    local MockObject        temp;
    local array<MockObject> objects;
    local MockObjectNoPool  obj1, obj2;
    Context("Testing usage of object pools by `MockObject`s.");
    Issue("Object pool is not utilized enough.");
    for (i = 0; i < 200; i += 1)
    {
        objects[objects.length] =
            MockObject(__().memory.Allocate(class'MockObject'));
    }
    for (i = 0; i < 200; i += 1) {
        __().memory.Free(objects[i]);
    }
    for (i = 0; i < 200; i += 1)
    {
        temp = MockObject(__().memory.Allocate(class'MockObject'));
        //  Have to find just allocated object among already free ones
        j = 0;
        allocatedNewObject = true;
        while (j < objects.length)
        {
            if (objects[j] == temp)
            {
                allocatedNewObject = false;
                objects.Remove(j, 1);
                break;
            }
            j += 1;
        }
        if (allocatedNewObject) {
            break;
        }
    }
    TEST_ExpectFalse(allocatedNewObject);

    Issue("Disabling pool for a class does not prevent pooling objects.");
    obj1 = MockObjectNoPool(__().memory.Allocate(class'MockObjectNoPool'));
    __().memory.Free(obj1);
    obj2 = MockObjectNoPool(__().memory.Allocate(class'MockObjectNoPool'));
    TEST_ExpectTrue(obj1 != obj2);
}
/*Test case [Memory] AllocationDeallocation: failed!
    Testing usage of object pools by `MockActor`s.
        Object pool is not utilized enough. [1]
    Testing that `GetLifeVersion()` returns unique value for Acedia's actors/objects after each reallocation.
        `GetLifeVersion()` repeats the same version within 1000 attempts. [1]*/
protected static function Test_ActorPoolUsage()
{
    local bool                      allocatedNewActor;
    local int                       i, j;
    local MockActorWithPool         temp;
    local array<MockActorWithPool>  actors;
    local MockActor                 noPoolActor;
    Context("Testing usage of object pools by `MockActor`s.");
    Issue("Object pool is not utilized enough.");
    for (i = 0; i < 200; i += 1)
    {
        actors[actors.length] =
            MockActorWithPool(__().memory.Allocate(class'MockActorWithPool'));
    }
    for (i = 0; i < 200; i += 1) {
        __().memory.Free(actors[i]);
    }
    for (i = 0; i < 200; i += 1)
    {
        temp =
            MockActorWithPool(__().memory.Allocate(class'MockActorWithPool'));
        //  Have to find just allocated object among already free ones
        j = 0;
        allocatedNewActor = true;
        while (j < actors.length)
        {
            if (actors[j] == temp)
            {
                allocatedNewActor = false;
                actors.Remove(j, 1);
                break;
            }
            j += 1;
        }
        if (allocatedNewActor) {
            break;
        }
    }
    TEST_ExpectFalse(allocatedNewActor);

    Issue("Disabling pool for a class does not prevent pooling actors.");
    noPoolActor = MockActor(__().memory.Allocate(class'MockActor'));
    __().memory.Free(noPoolActor);
    TEST_ExpectNone(noPoolActor);
}

defaultproperties
{
    caseGroup = "Memory"
    caseName = "AllocationDeallocation"
}