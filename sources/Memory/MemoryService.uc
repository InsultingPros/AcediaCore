/**
 *      This service is meant to perform auxiliary functions for `MemoryAPI`.
 *  It's main task is to keep track of all `AcediaObjectPool`s to force them to
 *  get rid of object references before garbage collection.
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
class MemoryService extends Service;

var private array<AcediaObjectPool> registeredPools;

/**
 *  Registers new object pool to auto-clean before Acedia's garbage collection.
 *
 *  Registered `AcediaObjectPool`s will persist even if `MemoryService` is
 *  destroyed and re-created.
 *
 *  @param  newPool Pool that service must clean during a `ClearAll()` call.
 *  @return `true` if `newPool` was registered,
 *      `false` if `newPool == none` or was already registered.
 */
public final function bool RegisterNewPool(AcediaObjectPool newPool)
{
    local int i;
    if (newPool == none) {
        return false;
    }
    registeredPools = default.registeredPools;
    for (i = 0; i < registeredPools.length; i += 1) {
        if (registeredPools[i] == newPool) return false;
    }
    registeredPools[registeredPools.length] = newPool;
    default.registeredPools = registeredPools;
    return true;
}

/**
 *  Clears all registered (via `RegisterNewPool()`) pools.
 */
public final function ClearAll()
{
    local int i;
    registeredPools = default.registeredPools;
    for (i = 0; i < registeredPools.length; i += 1)
    {
        if (registeredPools[i] == none) continue;
        registeredPools[i].Clear();
    }
}

defaultproperties
{
}