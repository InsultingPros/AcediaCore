/**
 *      API that provides functions for managing object of classes, derived from
 *  `AcediaObject`. It takes care of managing their object pools, as well as
 *  ensuring that constructors and finalizers are called properly.
 *      Almost all `AcediaObject`s should use this API's methods for their own
 *  creation and destruction.
 *      Copyright 2020-2022 Anton Tarasenko
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
 *  # Memory API
 *
 *  This is most-basic API that must be created before anything else in Acedia,
 *  since it is responsible for the proper creation of `AcediaObject`s.
 *  It takes care of managing their object pools, as well as ensuring that
 *  constructors and finalizers are called properly.
 *      Almost all `AcediaObject`s should use this API's methods for their own
 *  creation and destruction.
 *
 *  ## Usage
 *
 *      First of all, this API is only meant for non-actor `Object` creation.
 *  `Actor` creation is generally avoided in Acedia and, when unavoidable,
 *  different APIs are dealing with that. `MemoryAPI` is designed to work in
 *  the absence of any level (and, therefore, `Actor`s) at all.
 *      Simply use `MemoryAPI.Allocate()` to create a new object and
 *  `MemoryAPI.Free()` to get rid on unneeded reference. Do note that
 *  `AcediaObject`s use reference counting and object will be deallocated and
 *  pooled only after every trackable reference was released by
 *  `MemoryAPI.Free()`.
 *      Best practice is to only care about what object reference you're
 *  keeping, properly release them with `MemoryAPI.Free()` and to NEVER EVER USE
 *  THEM after you've release them. Regardless of whether they were actually
 *  deallocated.
 *
 *  There's also a set of auxiliary methods for either loading `class`es from
 *  their `BaseText`/`string`-given names or even directly creating objects of
 *  said classes.
 *
 *  ## Motivation
 *
 *      UnrealScript lacks any practical way to destroy non-actor objects on
 *  demand: the best one can do is remove any references to the object and wait
 *  for garbage collection. But garbage collection itself is too slow and causes
 *  noticeable lag spikes for players, making it suitable only for cleaning
 *  objects when switching levels. To alleviate this problem, there exists
 *  a standard class `ObjectPool` that stores unused objects (mostly resources
 *  such as textures) inside dynamic array until they are needed.
 *      Unfortunately, using a single ObjectPool for a large volume of objects
 *  is impractical from performance perspective, since it stores objects of all
 *  classes together and each object allocation from the pool can potentially
 *  require going through the whole array (see `Engine/ObjectPool.uc`).
 *      Acedia uses a separate object pool (implemented by `AcediaObjectPool`)
 *  for every single class, making object allocation as trivial as grabbing
 *  the last stored object from `AcediaObjectPool`'s internal dynamic array.
 *      New pool is prepared for every class you create, as long as it is
 *  derived from `AcediaObject`. `AcediaActors` do not use object pools and are
 *  meant to be simply `Destroy()`ed.
 *
 *  ## Customizing object pools for your classes
 *
 *      Object pool usage can be disabled completely for your class by setting
 *  `usesObjectPool = false` in `defaultproperties` block. Without object pools
 *  `MemoryAPI.Allocate()` will create a new instance of your class every single
 *  time.
 *      You can also set a limit to how many objects will be stored in an object
 *  pool with defaultMaxPoolSize variable. Negative number (default for
 *  `AcediaObject`) means that object pool can grow without a limit.
 *  `0` effectively disables object pool, similar to setting
 *  `usesObjectPool = false`. However, this can be overwritten by server's
 *  settings (see `AcediaSystem.ini`: `AcediaObjectPool`).
 */

//  Store all created pools, so that we can quickly forget stored objects upon
//  garbage collection
var private array<AcediaObjectPool> registeredPools;

/**
 *  Creates a class instance from its `Text` representation.
 *
 *  Does not generate log messages upon failure.
 *
 *  @param  classReference  Text representation of the class to return.
 *  @return Loaded class, corresponding to its name from `classReference`.
 */
public function class<Object> LoadClass(BaseText classReference)
{
    if (classReference == none) {
        return none;
    }
    return class<Object>(
        DynamicLoadObject(classReference.ToString(),
        class'Class',
        true));
}

/**
 *  Creates a class instance from its `string` representation.
 *
 *  Does not generate log messages upon failure.
 *
 *  @param  classReference  `string` representation of the class to return.
 *  @return Loaded class, corresponding to its name from `classReference`.
 */
public function class<Object> LoadClass_S(string classReference)
{
    return class<Object>(DynamicLoadObject(classReference, class'Class', true));
}

/**
 *  Creates a new `Object` of a given class.
 *
 *  For `AcediaObject`s calls constructors and tries (uses them only if they
 *  aren't forbidden for a given class) to make use of their classes' object
 *  pools.
 *
 *  If Acedia's object does make use of object pools, -
 *  guarantees to return last pooled object (in a LIFO queue),
 *  unless `forceNewInstance` is set to `true`.
 *
 *  @see `AllocateByReference()`, `AllocateByReference_S()`
 *
 *  @param  classToAllocate     Class of the `Object` that this method will
 *      create. Must not be subclass of `Actor`.
 *  @param  forceNewInstance    Set this to `true` if you require this method to
 *      create a new instance, bypassing any object pools.
 *  @return Newly created object. Will only be `none` if:
 *      1. `classToAllocate` is `none`;
 *      2. `classToAllocate` is abstract;
 *      3. `classToAllocate` is derived from `Actor`.
 */
public function Object Allocate(
    class<Object>   classToAllocate,
    optional bool   forceNewInstance)
{
    //  TODO: this is an old code require while we still didn't get rid of
    //  services - replace it later
    local LevelCore             core;
    local Object                allocatedObject;
    local AcediaObjectPool      relevantPool;
    local class<AcediaObject>   acediaObjectClassToAllocate;
    local class<AcediaActor>    acediaActorClassToAllocate;
    local class<Actor>          actorClassToAllocate;

    if (classToAllocate == none) {
        return none;
    }
    //  Try using pool first (only if new instance is not required)
    acediaObjectClassToAllocate = class<AcediaObject>(classToAllocate);
    acediaActorClassToAllocate  = class<AcediaActor>(classToAllocate);
    if (!forceNewInstance)
    {
        if (acediaObjectClassToAllocate != none) {
            relevantPool = acediaObjectClassToAllocate.static._getPool();
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
        actorClassToAllocate  = class<Actor>(classToAllocate);
        if (actorClassToAllocate != none)
        {
            core = class'ServerLevelCore'.static.GetInstance();
            if (core == none) {
                core = class'ClientLevelCore'.static.GetInstance();
            }
            allocatedObject = core.Spawn(actorClassToAllocate);
        }
        else {
            allocatedObject = (new classToAllocate);
        }
    }
    //  Call constructors
    if (acediaObjectClassToAllocate != none) {
        AcediaObject(allocatedObject)._constructor();
    }
    if (acediaActorClassToAllocate != none)
    {
        //  Call it here, just in case, to make sure constructor is called
        //  as soon as possible
        AcediaActor(allocatedObject)._constructor();
    }
    return allocatedObject;
}

/**
 *  Creates a new `Object` of a given class using its `BaseText`
 *  representation.
 *
 *  For `AcediaObject`s calls constructors and tries (uses them only if they
 *  aren't forbidden for a given class) to make use of their classes' object
 *  pools.
 *
 *  If Acedia's object does make use of object pools, -
 *  guarantees to return last pooled object (in a LIFO queue),
 *  unless `forceNewInstance` is set to `true`.
 *  @see `Allocate()`, `AllocateByReference_S()`
 *
 *  @param  refToClassToAllocate    `BaseText` representation of the class' name
 *      of the `Object` that this method will create. Must not be subclass of
 *      `Actor`.
 *  @param  forceNewInstance    Set this to `true` if you require this method to
 *      create a new instance, bypassing any object pools.
 *  @return Newly created object. Will only be `none` if:
 *      1. `classToAllocate` is `none`;
 *      2. `classToAllocate` is abstract;
 *      3. `classToAllocate` is derived from `Actor`.
 */
public function Object AllocateByReference(
    BaseText        refToClassToAllocate,
    optional bool   forceNewInstance)
{
    return Allocate(LoadClass(refToClassToAllocate), forceNewInstance);
}

/**
 *  Creates a new `Object` of a given class using its `string`
 *  representation.
 *
 *  For `AcediaObject`s calls constructors and tries (uses them only if they
 *  aren't forbidden for a given class) to make use of their classes' object
 *  pools.
 *
 *  If Acedia's object does make use of object pools, -
 *  guarantees to return last pooled object (in a LIFO queue),
 *  unless `forceNewInstance` is set to `true`.
 *
 *  @see `Allocate()`, `AllocateByReference()`
 *
 *  @param  refToClassToAllocate    `string` representation of the class' name
 *      of the `Object` that this method will create. Must not be subclass of
 *      `Actor`.
 *  @param  forceNewInstance    Set this to `true` if you require this method to
 *      create a new instance, bypassing any object pools.
 *  @return Newly created object. Will only be `none` if:
 *      1. `classToAllocate` is `none`;
 *      2. `classToAllocate` is abstract;
 *      3. `classToAllocate` is derived from `Actor`.
 */
public function Object AllocateByReference_S(
    string          refToClassToAllocate,
    optional bool   forceNewInstance)
{
    return Allocate(LoadClass_S(refToClassToAllocate), forceNewInstance);
}

/**
 *  Releases one reference to a given `AcediaObject`, calling its finalizers in
 *  case all references were released.
 *
 *  Method will attempt to store `objectToRelease` in its object pool once
 *  deallocated, unless it is forbidden by its class' settings.
 *
 *  @see `FreeMany()`
 *
 *  @param  objectToRelease Object, which reference method needs to release.
 */
public function Free(Object objectToRelease)
{
    //  TODO: this is an old code require while we still didn't get rid of
    //  services - replace it later, changing argument to `AcediaObject`
    local AcediaObjectPool  relevantPool;
    local Actor             objectAsActor;
    local AcediaActor       objectAsAcediaActor;
    local AcediaObject      objectAsAcediaObject;

    if (objectToRelease == none) {
        return;
    }
    //  Call finalizers for Acedia's objects and actors
    objectAsAcediaObject    = AcediaObject(objectToRelease);
    objectAsAcediaActor     = AcediaActor(objectToRelease); 
    if (objectAsAcediaObject != none)
    {
        if (!objectAsAcediaObject.IsAllocated()) {
            return;
        }
        objectAsAcediaObject._deref();
        if (objectAsAcediaObject._getRefCount() > 0) {
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
        objectAsAcediaActor._deref();
        if (objectAsAcediaActor._getRefCount() > 0) {
            return;
        }
        objectAsAcediaActor._finalizer();
    }
    //  Try to store freed object in a pool
    if (relevantPool != none && relevantPool.Store(objectAsAcediaObject)) {
        return;
    }
    //  Otherwise destroy actors and forget about objects
    objectAsActor = Actor(objectToRelease);
    if (objectAsActor != none) {
        objectAsActor.Destroy();
    }
}

/**
 *  Releases one reference to each `AcediaObject` inside the given array
 *  `objectsToRelease`, calling finalizers for the ones that got all of their
 *  references released.
 *
 *  Method will attempt to store objects inside `objectsToRelease` in their
 *  object pools, unless it is forbidden by their class' settings.
 *
 *  @see `Free()`
 *
 *  @param  objectToRelease Array of objects, which reference method needs
 *      to release.
 */
public function FreeMany(array<Object> objectsToRelease)
{
    //  TODO: this is an old code require while we still didn't get rid of
    //  services - replace it later, changing argument to `AcediaObject`
    local int i;

    for (i = 0; i < objectsToRelease.length; i += 1) {
        Free(objectsToRelease[i]);
    }
}

/**
 *  Forces Unreal Engine to perform garbage collection.
 *  By default also cleans up all of the Acedia's objects pools.
 *
 *  Process of garbage collection causes significant lag spike during the game
 *  and should be used sparingly and at right moments.
 *
 *  If not `LevelCore` was setup, Acedia doesn't have access to the level and
 *  cannot perform garbage collection, meaning that this method can fail.
 *
 *  @param  keepAcediaPools  Set this to `true` to NOT garbage collect
 *      objects inside pools. Otherwise keep it `false`.
 *      Pools won't be dropped regardless of this parameter if no `LevelCore` is
 *      found.
 *  @return `true` if garbage collection successfully happened and `false` if it
 *      failed. Garbage collection can only fail if no `LevelCore` was yet
 *      setup.
 */
public function bool CollectGarbage(optional bool keepAcediaPools)
{
    local LevelCore core;

    //  Try to find level core
    core = class'ServerLevelCore'.static.GetInstance();
    if (core == none) {
        core = class'ClientLevelCore'.static.GetInstance();
    }
    if (core == none) {
        return false;
    }
    //  Drop content of all `AcediaObjectPools` first
    if (!keepAcediaPools) {
        DropPools();
    }
    //  This makes Unreal Engine do garbage collection
    core.ConsoleCommand("obj garbage");
    return true;
}

/**
 *  Registers new object pool to auto-clean before Acedia's garbage collection.
 *
 *  @param  newPool New object pool that can get cleaned if `CollectGarbage()`
 *      is called with appropriate parameters.
 *  @return `true` if `newPool` was registered,
 *      `false` if `newPool == none` or was already registered.
 */
public function bool RegisterNewPool(AcediaObjectPool newPool)
{
    local int i;

    if (newPool == none) {
        return false;
    }
    registeredPools = default.registeredPools;
    for (i = 0; i < registeredPools.length; i += 1)
    {
        if (registeredPools[i] == newPool) {
            return false;
        }
    }
    registeredPools[registeredPools.length] = newPool;
    default.registeredPools = registeredPools;
    return true;
}

/**
 *  Forgets about all stored (deallocated) object references in registered
 *  object pools.
 */
protected function DropPools()
{
    local int i;
    registeredPools = default.registeredPools;
    for (i = 0; i < registeredPools.length; i += 1)
    {
        if (registeredPools[i] == none) {
            continue;
        }
        registeredPools[i].Clear();
    }
}

defaultproperties
{
}