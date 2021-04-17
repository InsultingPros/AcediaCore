/**
 *      Set of tests for `ActorService`'s functionality.
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
class TEST_ActorService extends TestCase
    dependson(ActorService)
    abstract;

protected static function TESTS()
{
    local ActorService service;
    Context("Testing adding and retrieving native `Actor`s from"
        @ "`ActorService`.");
    Issue("Cannot get instance of `ActorService`.");
    service = ActorService(class'ActorService'.static.Require());
    TEST_ExpectNotNone(service);
    Test_AddDestroy(class'MockNativeActor');
    Test_AddDestroy(class'MockAcediaActor');
    Test_AddRemove(class'MockNativeActor');
    Test_AddRemove(class'MockAcediaActor');
    Test_Update(class'MockNativeActor');
    Test_Update(class'MockAcediaActor');
}

protected static function Test_AddDestroy(class<Actor> classToTest)
{
    local int                                   i;
    local ActorService                          service;
    local array<ActorService.ActorReference>    actorRefs;
    local array<Actor>                          nativeActors;
    service = ActorService(class'ActorService'.static.Require());
    Issue("Cannot retrieve recorded `Actor`s with `GetActor()`.");
    for (i = 0; i < 1000; i += 1)
    {
        nativeActors[i] = Actor(__().memory.Allocate(classToTest));
        actorRefs[i] = service.AddActor(nativeActors[i]);
    }
    for (i = 0; i < 1000; i += 1)
    {
        TEST_ExpectNotNone(service.GetActor(actorRefs[i]));
        TEST_ExpectTrue(service.GetActor(actorRefs[i]) == nativeActors[i]);
    }
    Issue("Just destroyed `Actor`s are not returned as `none` from"
        @ "`GetActor()`.");
    for (i = 0; i < 1000; i += 1)
    {
        if (i % 2 == 1) {
            continue;
        }
        nativeActors[i].Destroy();
        TEST_ExpectNone(service.GetActor(actorRefs[i]));
    }

    Issue("`Actor`s are not properly added to service after destruction of the"
        @ "previously stored ones.");
    for (i = 0; i < 1000; i += 1)
    {
        if (i % 2 == 0)
        {
            nativeActors[i] = Actor(__().memory.Allocate(classToTest));
            actorRefs[i] = service.AddActor(nativeActors[i]);
        }
    }
    for (i = 0; i < 1000; i += 1)
    {
        TEST_ExpectNotNone(service.GetActor(actorRefs[i]));
        TEST_ExpectTrue(service.GetActor(actorRefs[i]) == nativeActors[i]);
    }
}

protected static function Test_AddRemove(class<Actor> classToTest)
{
    local int                                   i;
    local ActorService                          service;
    local array<ActorService.ActorReference>    actorRefs;
    local array<Actor>                          nativeActors;
    service = ActorService(class'ActorService'.static.Require());
    for (i = 0; i < 1000; i += 1)
    {
        nativeActors[i] = Actor(__().memory.Allocate(classToTest));
        actorRefs[i] = service.AddActor(nativeActors[i]);
    }

    Issue("Just `Remove()`-ed `Actor`s are not returned as `none` from"
        @ "`GetActor()`.");
    for (i = 0; i < 1000; i += 1)
    {
        if (i % 2 == 1) {
            continue;
        }
        service.RemoveActor(actorRefs[i]);
        TEST_ExpectNone(service.GetActor(actorRefs[i]));
    }

    Issue("`Actor`s are not properly added to service after removal of the"
        @ "previously stored ones.");
    for (i = 0; i < 1000; i += 1)
    {
        if (i % 2 == 0)
        {
            nativeActors[i] = Actor(__().memory.Allocate(classToTest));
            actorRefs[i] = service.AddActor(nativeActors[i]);
        }
    }
    for (i = 0; i < 1000; i += 1)
    {
        TEST_ExpectNotNone(service.GetActor(actorRefs[i]));
        TEST_ExpectTrue(service.GetActor(actorRefs[i]) == nativeActors[i]);
    }
}

protected static function Test_Update(class<Actor> classToTest)
{
    local int                                   i;
    local ActorService                          service;
    local array<ActorService.ActorReference>    actorRefs;
    local array<Actor>                          nativeActors;
    service = ActorService(class'ActorService'.static.Require());
    for (i = 0; i < 1000; i += 1)
    {
        nativeActors[i] = Actor(__().memory.Allocate(classToTest));
        actorRefs[i] = service.AddActor(nativeActors[i]);
    }

    Issue("`Actor`s are not properly updated.");
    for (i = 0; i < 1000; i += 1)
    {
        if (i % 2 == 0)
        {
            nativeActors[i] = Actor(__().memory.Allocate(classToTest));
            actorRefs[i] = service.UpdateActor(actorRefs[i], nativeActors[i]);
        }
    }
    for (i = 0; i < 1000; i += 1)
    {
        TEST_ExpectNotNone(service.GetActor(actorRefs[i]));
        TEST_ExpectTrue(service.GetActor(actorRefs[i]) == nativeActors[i]);
    }
}

defaultproperties
{
    caseGroup   = "Types"
    caseName    = "ActorService"
}