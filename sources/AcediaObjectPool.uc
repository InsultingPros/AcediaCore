/**
 *      Acedia's implementation for object pool that can only store objects of
 *  one specific class to allow for both faster allocation and
 *  faster deallocation.
 *      Allows to set a maximum capacity.
 *      Copyright 2020-2021 Anton Tarasenko
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
var private class<AcediaObject> storedClass;
//  Actual storage, functions on LIFO principle.
var public array<AcediaObject>  objectPool;

//      This struct and it's associated array `poolSizeOverwrite` allows
//  server admins to rewrite the pool capacity for each class.
struct PoolSizeSetting
{
    var class<AcediaObject> objectClass;
    var int                 maxPoolSize;
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
 *      if not specified, uses `AcediaObject`'s `defaultMaxPoolSize`
 *      (ignoring `usesObjectPool` setting).
 *  @return `true` if initialization completed, `false` otherwise
 *      (including if it was already completed with passed `initStoredClass`).
 */
public final function bool Initialize(
    class<AcediaObject> initStoredClass,
    optional int        forcedPoolSize)
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
private final function int GetMaxPoolSizeForClass(
    class<AcediaObject> classToCheck)
{
    local int i;
    local int result;
    if (classToCheck != none) {
        result = classToCheck.default.defaultMaxPoolSize;
    }
    else {
        result = -1;
    }
    //  Try to replace it with server's settings
    for (i = 0; i < poolSizeOverwrite.length; i += 1)
    {
        if (poolSizeOverwrite[i].objectClass == classToCheck)
        {
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
public final function class<AcediaObject> GetClassOfStoredObjects()
{
    return storedClass;
}

/**
 *  Clear the storage of all it's contents.
 *
 *  Can be used before UnrealEngine's garbage collection to free pooled objects.
 */
public final function Clear()
{
    objectPool.length = 0;
}

/**
 *  Adds object to the caller storage
 *  (that needs to be initialized to store `newObject.class` classes).
 *
 *  For performance purposes does not do duplicates checks,
 *  this should be verified from outside `AcediaObjectPool`.
 *
 *  Does type checks and only allows objects of the class that caller
 *  `AcediaObjectPool` was initialized for.
 *
 *  @param  newObject   Object to put inside caller pool. Must be not `none` and
 *      have precisely the class this object pool was initialized to store.
 *  @return `true` on success and `false` on failure
 *      (can happen if passed `newObject` reference was invalid, caller storage
 *      is not initialized yet or reached it's capacity).
 */
public final function bool Store(AcediaObject newObject)
{
    if (newObject == none)              return false;
    if (newObject.class != storedClass) return false;

    if (usedMaxPoolSize >= 0 && objectPool.length >= usedMaxPoolSize) {
        return false;
    }
    objectPool[objectPool.length] = newObject;
    return true;
}

/**
 *  Extracts last stored object from the pool. Returned object will no longer
 *  be stored in the pool.
 *
 *  @return Reference to the last (not destroyed) stored object.
 *      Only returns `none` if caller `AcediaObjectPool` is either empty or
 *      not initialized.
 */
public final function AcediaObject Fetch()
{
    local AcediaObject result;
    if (storedClass == none)    return none;
    if (objectPool.length <= 0) return none;

    result = objectPool[objectPool.length - 1];
    objectPool.length = objectPool.length - 1;
    return result;
}

defaultproperties
{
}