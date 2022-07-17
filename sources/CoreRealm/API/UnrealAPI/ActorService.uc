/**
 *      Service for safe `Actor` storage, aimed to resolve two issues that arise
 *  from storing references to `Actor`s inside non-`Actor` objects:
 *      1. This can potentially prevent the whole level from being
 *          garbage-collected on level change, leading to excessive memory use
 *          and crashes;
 *      2. This can lead to stored `Actor` temporarily being put into
 *          a "faulty state", where any sort of access to that `Actor`
 *          (except converting it into a `string` ¯\_(ツ)_/¯) will lead to 
 *          server/game crashing.
 *      This `Service` resolves these issues by storing `Actor`s in such a way
 *  that they can be relatively quickly obtained via a simple struct value
 *  (`ActorReference`) that can be safely stored inside any `Object`.
 *      It is recommended to use `ActorRef` / `ActorBox` instead of accessing
 *  this `Service` directly.
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
class ActorService extends Service;

/**
 *      This service works as follows: it contains an array filled with `Actor`s
 *  that will dynamically grow in size whenever more space is needed for new
 *  `Actor`s. To refer to the stored `Actor` we put it's index in the storage
 *  array in `ActorReference` struct.
 *
 *      The main problem with that approach is that once `Actor` is destroyed or
 *  removed- it leaves a "hole" inside our storage and if we keep simply adding
 *  new `Actor`s at the end of the storage array - we will eventually use
 *  too much space, even if we only store a limited amount of `Actor`s at any
 *  given point in time.
 *      To avoid this problem we also maintain an array of "empty indices" that
 *  remembers where the "holes" are located and can let us re-allocate them to
 *  place new `Actor`s in, without needlessly increasing storage's size.
 *
 *      Another problem is that now two different `Actor`s can occupy the same
 *  spot at different points in time. To deal with that we will also record
 *  an `Actor`'s "version" for each storage index and increment it each time
 *  a new `Actor` is stored at that index. We will also store that "version"
 *  inside `ActorReference` to help us invalidate references to old `Actor`s
 *  that were stored there before.
 *
 *      NOTE that this `Service` avoids doing any sort of manual cleaning,
 *  instead relying on the proper interface (`ActorRef` / `ActorBox`) to do it.
 */

/**
 *      Reference to the `Actor` storage inside this service.
 *      Reference is only considered invalid after an `Actor` it was referring
 *  to was removed from the storage (possibly by being replaced with
 *  another `Actor`).
 */
struct ActorReference
{
    var private int index;
    var private int version;
};

/*      Arrays `actorRecords`, `actorVersions` and `indexAllocationFlag` could
 *  be represented as an array of a single struct with 3 element, but instead,
 *  for performance reasons, were separated into three distinct arrays - one for
 *  each variable.
 *      This means that they must at all times have the same length and
 *  elements with the same index should be considered to belong to
 *  the same record.
 */
//  Storage for `Actor`s. It's size can grow, but it cannot shrink, instead
//  marking some of array's indices as vacant
//  (by putting them into `emptyIndices`).
var private array<Actor>    actorRecords;
//  Defines a "version" of a corresponding `Actor`.
var private array<int>      actorVersions;
//      Marks whether values at a particular index are currently used to
//  store some `Actor` (`1`) or not (`0`).
//      Without these flags we would have no way of knowing whether a spot in
//  the array was already freed and recorded in `emptyIndices`, since stored
//  `Actor`s can turn into `none` by themselves upon destruction.
var private array<byte>     indexAllocationFlag;

//      A set of empty indices - that once contained stored an `Actor`, but can
//  now be reused.
//      Used like a LIFO-queue to quickly find an empty spot in `actorRecords`.
var private array<int>      emptyIndices;

//      Finds an vacant index in our records (expands array if all indices are
//  already taken) and puts `candidate` there.
//      Does not do any checks for whether `candidate != none`.
private final function int InsertAtEmptyIndex(Actor candidate)
{
    local int newIndex;
    if (emptyIndices.length > 0)
    {
        newIndex = emptyIndices[emptyIndices.length - 1];
        emptyIndices.length = emptyIndices.length - 1;
        actorVersions[newIndex] += 1;
    }
    else
    {
        newIndex = actorRecords.length;
        actorVersions[newIndex] = 0;
    }
    actorRecords[newIndex]          = candidate;
    indexAllocationFlag[newIndex]   = 1;
    return newIndex;
}

//  Forces `indexToFree` to become vacant, not storing any `Actor`.
private final function FreeIndex(int indexToFree)
{
    if (indexAllocationFlag[indexToFree] > 0)
    {
        actorRecords[indexToFree] = none;
        emptyIndices[emptyIndices.length] = indexToFree;
    }
    //  No need to bump `actorVersions[indexToFree]` here, since any refences to
    //  this index will automatically be invalidated by this:
    indexAllocationFlag[indexToFree] = 0;
}

/**
 *  Adds a new `Actor` to the storage.
 *
 *  Any reference created with `AddActor()` must be release with
 *  `RemoveActor()`.
 *
 *  This method does not attempt to check whether `newActor` is already stored
 *  in `ActorService`. Therefore it is possible for the same actor to be stored
 *  multiple times under different `ActorReference` records.
 *
 *  Can only fail if provided `Actor` is either equal to `none`.
 *
 *      Note that while this storage is supposed to be "safe", meaning that it
 *  aims to reduce probability of `Actor`-related crashes, it assumes that
 *  passed `Actor`s are not already "broken", as there is no way to check
 *  for that.
 *      `Actor`s that were not stored in a non-`Actor` object as a non-local
 *  variable should not be broken.
 *
 *  @param  newActor    `Actor` to store. If it's equal to `none`, then
 *      this method will do nothing.
 *  @return `ActorReference` struct that can be used to retrieve stored
 *      `Actor` later. Returned reference will point at `none` once stored
 *      `Actor` gets destroyed or removed via the `RemoveActor()` call.
 */
public final function ActorReference AddActor(Actor newActor)
{
    local int               newIndex;
    local ActorReference    result;
    //  This will make the very first check inside `ValidateIndexVersion()` fail
    result.index = -1;
    if (newActor == none) {
        return result;
    }

    newIndex = InsertAtEmptyIndex(newActor);
    result.index    = newIndex;
    result.version  = actorVersions[newIndex];
    return result;
}

/**
 *  Returns an `Actor` that provided `reference` points at.
 *
 *  @param  reference   Reference to the `Actor` this method should return.
 *  @return `Actor`, stored in caller `ActorService` with `reference`.
 *      If stored `Actor` was already destroyed or removed, this method will
 *      return `none`.
 */
public final function Actor GetActor(ActorReference reference)
{
    local int   index;
    local Actor result;
    index = reference.index;
    if (!ValidateIndexVersion(index, reference.version)) {
        return none;
    }
    //  While this can be considered a side-effect in a getter, removing `none`
    //  from the storage will not affect how `reference` behaves, since it can
    //  only refer to `none` from now on.
    result = actorRecords[index];
    if (result == none)
    {
        FreeIndex(index);
        return none;
    }
    return result;
}

/**
 *  Replaces an `Actor`, that provided `reference` points at, with a `newActor`,
 *  returning a new `ActorReference` and invalidating the old one (`reference`),
 *  making it to refer to `none`.
 *
 *  This method is guaranteed to be functionally identical (as far as public,
 *  not encapsulated, interface is concerned) to calling two methods:
 *  `RemoveActor(reference)` and `AddActor(newActor)`. But is expected to
 *  provide be more efficient.
 *
 *  @param  reference   Reference to `Actor` that should be replaced.
 *  @param  newActor    New `Actor` to store.
 *  @return Reference to the `newActor` inside the storage.
 */
public final function ActorReference UpdateActor(
    ActorReference  reference,
    Actor           newActor)
{
    local int index;
    index = reference.index;
    //  Nothing to remove
    if (!ValidateIndexVersion(index, reference.version)) {
        return AddActor(newActor);
    }
    //  Nothing to add
    if (newActor == none) {
        RemoveActor(reference);
    }
    else
    {
        //  If we need to both remove and add, we can just replace an `Actor`
        //  and bump the stored version to invalidate copies of the passed
        //  `reference`:
        actorRecords[index] = newActor;
        actorVersions[index] += 1;
        reference.version += 1;
    }
    return reference;
}

/**
 *  Unconditionally removes an `Actor` recorded with `reference` from storage.
 *
 *  Cannot fail.
 *
 *  If referred `Actor` is recorded in storage under several different
 *  references - only this reference will be affected. The rest are still going
 *  to refer to that `Actor`.
 *
 *  @param  reference   Reference to `Actor` to be removed.
 */
public final function RemoveActor(ActorReference reference)
{
    if (ValidateIndexVersion(reference.index, reference.version)) {
        FreeIndex(reference.index);
    }
}

/**
 *  Returns size of this storage.
 *
 *  @param  totalSize   Default value (`false`) means that method should return
 *      amount of currently stored `Actor`s, while `true` means how much space
 *      this storage takes up (in the sense that the actual amount in bytes is
 *      `O(GetSize(true))` in big-O notation).
 *  @return Size of this storage.
 */
public final function int GetSize(optional bool totalSize)
{
    if (totalSize) {
        return actorRecords.length;
    }
    return actorRecords.length - emptyIndices.length;
}

//  Validates passed index and `Actor`'s version, taken from
//  the `ActorReference`: returns `true` iff `Actor` referred to by them
//  currently exists in this storage (even if it's now equal to `none`).
private final function bool ValidateIndexVersion(
    int refIndex,
    int refVersion)
{
    if (refIndex < 0)                           return false;
    if (refIndex >= actorRecords.length)        return false;
    if (actorVersions[refIndex] != refVersion)  return false;

    return (indexAllocationFlag[refIndex] > 0);
}

defaultproperties
{
}