/**
 *      API that provides methods for managing objects and actors by providing
 *  simple and general means to create and destroy them in a way that is managed
 *  by Acedia and allows to use object pools, constructors and finalizers.
 *      These methods should be used for all Acedia's objects and actors.
 *      Copyright 2020 - 2021 Anton Tarasenko
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
class MemoryAPI extends AcediaObject;

/**
 *  Creates a class instance from it's string representation.
 *
 *  Does not generate log messages upon failure.
 *
 *  @param  classReference  String representation of the class to return.
 *  @return Loaded class, corresponding to it's name from `classReference`.
 */
public final function class<Object> LoadClass(Text classReference)
{
    if (classReference == none) {
        return none;
    }
    return class<Object>(   DynamicLoadObject(classReference.ToPlainString(),
                            class'Class', true));
}

/**
 *  Creates a new `Object` / `Actor` of a given class.
 *
 *  If uses a proper spawning mechanism for both objects (`new`)
 *  and actors (`Spawn`).
 *
 *  For Acedia's objects / actors makes use of their object pools and
 *  calls constructors.
 *
 *  If Acedia's object / actor does make use of object pools, -
 *  guarantees to return last pooled object (in a LIFO queue),
 *  unless `forceNewInstance == true`.
 *
 *  @param  classToAllocate     Class of the `Object` / `Actor` that this method
 *      must create.
 *  @param  forceNewInstance    Set this to `true` if you require this method to
 *      create a new instance, bypassing any object pools.
 *  @return Newly created object,
 *      `none` if creation has failed (only possible for actors).
 */
public final function Object Allocate(
    class<Object>   classToAllocate,
    optional bool   forceNewInstance)
{
    local Object                allocatedObject;
    local AcediaObjectPool      relevantPool;
    local class<AcediaObject>   acediaObjectClassToAllocate;
    local class<AcediaActor>    acediaActorClassToAllocate;
    local class<Actor>          actorClassToAllocate;
    if (classToAllocate == none) return none;

    //  Try using pool first (only if new instance is not required)
    acediaObjectClassToAllocate = class<AcediaObject>(classToAllocate);
    acediaActorClassToAllocate  = class<AcediaActor>(classToAllocate);
    if (!forceNewInstance)
    {
        if (acediaObjectClassToAllocate != none) {
            relevantPool = acediaObjectClassToAllocate.static._getPool();
        }
        if (acediaActorClassToAllocate != none) {
            relevantPool = acediaActorClassToAllocate.static._getPool();
        }
        //  `relevantPool == none` is expected if object / actor of is setup to
        //  not use object pools.
        if (relevantPool != none) {
            allocatedObject = relevantPool.Fetch();
        }
    }
    //  If pools did not work - spawn / create object through regular methods
    if (allocatedObject == none)
    {
        actorClassToAllocate  = class<AcediaActor>(classToAllocate);
        if (actorClassToAllocate != none)
        {
            allocatedObject = class'CoreService'.static
                .GetInstance()
                .Spawn(actorClassToAllocate);
        }
        else {
            allocatedObject = (new classToAllocate);
        }
    }
    //  Call constructors (also do it for actors, just in case)
    if (acediaObjectClassToAllocate != none) {
        AcediaObject(allocatedObject)._constructor();
    }
    if (acediaActorClassToAllocate != none) {
        AcediaActor(allocatedObject)._constructor();
    }
    return allocatedObject;
}

/**
 *  Creates a new `Object` / `Actor` of a class, given by it's
 *  string representation.
 *
 *  If uses a proper spawning mechanism for both objects (`new`)
 *  and actors (`Spawn`).
 *
 *  For Acedia's objects / actors makes use of their object pools and
 *  calls constructors.
 *
 *  If Acedia's object / actor does make use of object pools, -
 *  guarantees to return last pooled object (in a LIFO queue),
 *  unless `forceNewInstance == true`.
 *
 *  @param  classToAllocate     Class of the `Object` / `Actor` that this method
 *      must create.
 *  @param  forceNewInstance    Set this to `true` if you require this method to
 *      create a new instance, bypassing any object pools.
 *  @return Newly created object,
 *      `none` if creation has failed (only possible for actors).
 */
public final function Object AllocateByReference(
    Text            refToClassToAllocate,
    optional bool   forceNewInstance)
{
    return Allocate(LoadClass(refToClassToAllocate), forceNewInstance);
}

/**
 *  Frees given `Object` / `Actor` resource.
 *
 *  If Acedia's object or actor is passed, method will try to store it
 *  in an object pool.
 *
 *  @param  objectToDelete  `Object` / `Actor` that must be freed.
 */
public final function Free(Object objectToDelete)
{
    local AcediaObjectPool  relevantPool;
    local Actor             objectAsActor;
    local AcediaActor       objectAsAcediaActor;
    local AcediaObject      objectAsAcediaObject;
    if (objectToDelete == none) return;

    //  Call finalizers for Acedia's objects and actors
    objectAsAcediaObject    = AcediaObject(objectToDelete);
    objectAsAcediaActor     = AcediaActor(objectToDelete); 
    if (objectAsAcediaObject != none)
    {
        if (!objectAsAcediaObject.IsAllocated()) {
            return;
        }
        relevantPool = objectAsAcediaObject._getPool();
        objectAsAcediaObject._finalizer();
    }
    if (objectAsAcediaActor != none)
    {
        if (!objectAsAcediaActor.IsAllocated()) {
            return;
        }
        relevantPool = objectAsAcediaActor._getPool();
        objectAsAcediaActor._finalizer();
    }
    //  Try to store freed object in a pool
    if (relevantPool != none && relevantPool.Store(objectToDelete)) {
        return;
    }
    //  Otherwise destroy actors and forget about objects
    objectAsActor = Actor(objectToDelete);
    if (objectAsActor != none) {
        objectAsActor.Destroy();
    }
}

/**
 *  Frees given array of `Object` / `Actor` resources.
 *
 *  If Acedia's object or actor is contained in the passed array,
 *  method will try to store it in an object pool.
 *
 *  @param  objectsToDelete `Object` / `Actor` that must be freed.
 */
public final function FreeMany(array<Object> objectsToDelete)
{
    local int i;
    for (i = 0; i < objectsToDelete.length; i += 1) {
        Free(objectsToDelete[i]);
    }
}

/**
 *  Forces Unreal Engine to do garbage collection.
 *  By default also cleans up all the objects pools registered in
 *  `MemoryService`, which includes all of the pools for
 *  Acedia's built-in classes.
 *
 *  Process of garbage collection causes significant lag spike during the game
 *  and should be used sparingly and at right moments..
 *
 *  @param  keepAcediaPools  Set this to `true` to NOT garbage collect
 *      objects in a borrow pool. Otherwise keep it `false`.
 */
public final function CollectGarbage(optional bool keepAcediaPools)
{
    local MemoryService service;
    //  Drop content of all `AcediaObjectPools` first
    if (!keepAcediaPools)
    {
        service = MemoryService(class'MemoryService'.static.Require());
        if (service != none) {
            service.ClearAll();
        }
    }
    //  This makes Unreal Engine do garbage collection
    class'CoreService'.static.GetInstance().ConsoleCommand("obj garbage");
}

defaultproperties
{
}