/**
 *      Acedia's implementation for object pool that can only store objects of
 *  one specific class to allow for their faster allocation.
 *      Allows to set a maximum capacity and can handle properly storing,
 *  auto-cleaning destroyed ones.
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
class AcediaObjectPool extends Object
    config(AcediaSystem);

//  Class of objects that this `AcediaObjectPool` stores.
//  if `== none`, - object pool is considered uninitialized.
var private class<Object>   storedClass;
//  Actual storage, functions on LIFO principle.
var private array<Object>   objectPool;

//      This struct and it's associated array `poolSizeOverwrite` allows
//  server admins to rewrite the pool capacity for each class.
struct PoolSizeSetting
{
    var class<Object>   objectClass;
    var int             maxPoolSize;
};
var private config const array<PoolSizeSetting> poolSizeOverwrite;
//  Capacity for object pool that we are using.
//  Set during initialization and cannot be changed later.
var private int usedMaxPoolSize;

/**
 *  Initialize caller object pool to store objects of `initStoredClass` class.
 *
 *  If successful, this action is irreversible: same pool cannot be
 *  re-initialized.
 *
 *  @param  initStoredClass Class of objects that caller object pool will store.
 *  @param  forcedPoolSize  Max pool size for the caller `AcediaObjectPool`.
 *      Leaving it at default `0` value will cause method to auto-determine
 *      the size: gives priority to the `poolSizeOverwrite` config array;
 *      if not specified, for `AcediaActor`s and `AcediaObject`s uses their
 *      `defaultMaxPoolSize` (ignoring `usesActorPool` setting),
 *      for other objects uses `-1`, to remove the capacity limit.
 *  @return `true` if initialization completed, `false` otherwise
 *      (including if it was already completed with passed `initStoredClass`).
 */
public final function bool Initialize(
    class<Object>   initStoredClass,
    optional int    forcedPoolSize)
{
    if (storedClass != none)        return false;
    if (initStoredClass == none)    return false;

    //  If does not matter that we've set those variables until
    //  we set `storedClass`.
    if (forcedPoolSize == 0) {
        usedMaxPoolSize = GetMaxPoolSizeForClass(initStoredClass);
    }
    else {
        usedMaxPoolSize = forcedPoolSize;
    }
    if (usedMaxPoolSize == 0) {
        return false;
    }
    storedClass = initStoredClass;
    return true;
}

//  Determines default object pool size for the initialization.
private final function int GetMaxPoolSizeForClass(class<Object> classToCheck)
{
    local int                   i;
    local int                   result;
    local class<AcediaObject>   classAsAcediaObject;
    local class<AcediaActor>    classAsAcediaActor;
    //  Get hard-coded value
    classAsAcediaObject = class<AcediaObject>(classToCheck);
    classAsAcediaActor  = class<AcediaActor>(classToCheck);
    if (classAsAcediaActor != none) {
        result = classAsAcediaActor.default.defaultMaxPoolSize;
    }
    if (classAsAcediaObject != none) {
        result = classAsAcediaObject.default.defaultMaxPoolSize;
    }
    else {
        result = -1;
    }
    //  Try to replace it with server's settings
    for (i = 0; i < poolSizeOverwrite.length; i += 1) {
        if (poolSizeOverwrite[i].objectClass == classToCheck) {
            result = poolSizeOverwrite[i].maxPoolSize;
            break;
        }
    }
    return result;
}

/**
 *  Returns class of objects inside the caller `AcediaObjectPool`.
 *
 *  @return class of objects inside caller the caller object pool;
 *      `none` means object pool was not initialized.
 */
public final function class<Object> GetClassOfStoredObjects()
{
    return storedClass;
}

/**
 *  Clear the storage of all it's contents. In case of stored actors also
 *  destroys them.
 *
 *  Can be used before UnrealEngine's garbage collection to free pooled objects.
 */
public final function Clear()
{
    local int   i;
    local Actor nextActor;
    if (storedClass != none) {
        return;
    }
    if (class<Actor>(storedClass) == none)
    {
        //  We can't destroy non-actors, so just get rid of references
        objectPool.length = 0;
        return;
    }
    for (i = 0; i < objectPool.length; i += 1)
    {
        nextActor = Actor(objectPool[i]);
        if (nextActor != none) {
            nextActor.Destroy();
        }
    }
    objectPool.length = 0;
}

/**
 *  Adds object to the caller storage
 *  (that needs to be initialized to store `newObject.class` classes).
 *
 *  @param  newObject   Object to put inside caller pool. Must be not `none` and
 *      have precisely the class this object pool was initialized to store.
 *  @return `true` on success and `false` on failure
 *      (can happen if passed `newObject` reference was invalid, caller storage
 *      is not initialized yet or reached it's capacity).
 */
public final function bool Store(Object newObject)
{
    local int i;
    if (newObject == none)              return false;
    if (newObject.class != storedClass) return false;

    //  Check for duplicates and clear dead references
    while (i < objectPool.length)
    {
        if (objectPool[i] == newObject) {
            return false;
        }
        //  Getting `none` in object pool is expected to be rare and abnormal
        //  occurrence (since objects and actors put in the pool are
        //  not supposed to be touched), so filtering `none` values here
        //  should be negligible performance-wise, even if it's expensive.
        if (objectPool[i] == none) {
            objectPool.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
    if (usedMaxPoolSize >= 0 && objectPool.length < usedMaxPoolSize) {
        return false;
    }
    objectPool[objectPool.length] = newObject;
    return true;
}

/**
 *  Extracts last stored last not destroyed object (can happen for actors)
 *  from the pool.
 *
 *  Returned object is no longer stored in the pool.
 *
 *  @return Reference to the last (not destroyed) stored object.
 *      Only returns `none` if either empty or not initialized.
 */
public final function Object Fetch()
{
    local int       i;
    local int       validObjectIndex;
    local Object    result;
    if (storedClass == none) {
        return none;
    }
    validObjectIndex = -1;
    for (i = objectPool.length - 1; i >= 0; i -= 1)
    {
        if (objectPool[i] == none) continue;
        validObjectIndex = i;
        break;
    }
    if (validObjectIndex < 0) {
        return none;
    }
    result = objectPool[validObjectIndex];
    objectPool.length = validObjectIndex;
    return result;
}

defaultproperties
{
}