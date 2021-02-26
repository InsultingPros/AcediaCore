/**
 *      This class implements an associative array for storing arbitrary types
 *  of data that provides a quick (near constant) access to *values* by
 *  associated *keys*.
 *      Since UnrealScript lacks any sort of templating, `AssociativeArray`
 *  stores generic `AcediaObject` keys and values. `Text` can be used instead of
 *  typical `string` keys and primitive values can be added in their boxed form
 *  (either as actual `<Type>Box` or as it's reference counterpart).
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
class AssociativeArray extends Collection;

//      Defines key <-> value (with managed status) mapping.
//      Stores lifetime information to ensure that values were not reallocated
//  after being added to the collection.
struct Entry
{
    var public      AcediaObject    key;
    var protected   int             keyLifeVersion;
    var public      AcediaObject    value;
    var protected   int             valueLifeVersion;
    var public      bool            managed;
};
//  Bucket of entries. Used to store entries with the same index in hash table.
struct Bucket
{
    var array<Entry> entries;
};
var private array<Bucket> hashTable;
//      Amount of elements currently stored in this `AssociativeArray`.
//      If one of the keys was deallocated outside of `AssociativeArray`,
//  this value may overestimate actual amount of elements.
var private int storedElementCount;

//  Lower and upper limits on hash table capacity.
var private const int MINIMUM_CAPACITY;
var private const int MAXIMUM_CAPACITY;
//      Minimum and maximum allowed density of elements
//  (`storedElementCount / hashTable.length`).
//      If density falls outside this range, - we have to resize hash table to
//  get into (MINIMUM_DENSITY; MAXIMUM_DENSITY) bounds, as long as it does not
//  violate capacity restrictions.
var private const float MINIMUM_DENSITY;
var private const float MAXIMUM_DENSITY;

/**
 *  Auxiliary struct, necessary to implement iterator for `AssociativeArray`.
 *  Can be used for manual iteration, but should be avoided in favor of
 *  `Iterator`.
 */
struct Index
{
    var protected int bucketIndex;
    var protected int entryIndex;
};

protected function Constructor()
{
    UpdateHashTableCapacity();
}

protected function Finalizer()
{
    Empty();
}

//      Auxiliary method that is needed as a replacement for `%` module
//  operator, since it is an operation on `float`s in UnrealScript and does not
//  have appropriate value range to work with hashes.
//      Assumes non-negative input.
private function int Remainder(int number, int divisor)
{
    local int quotient;
    quotient = number / divisor;
    return (number - quotient * divisor);
}

//  Calculates appropriate bucket index for the given key.
//  Assumes that given key is not `none` and is allocated.
private final function int GetBucketIndex(AcediaObject key)
{
    local int bucketIndex;
    bucketIndex = key.GetHashCode();
    if (bucketIndex < 0) {
        //  Minimum `int` value is greater than maximum one in absolute value,
        //  so shift it up to avoid overflow.
        bucketIndex = -1 * (bucketIndex + 1);
    }
    bucketIndex = Remainder(bucketIndex, hashTable.length);
    return bucketIndex;
}

//  Accessing value in `AssociativeArray` requires:
//      1.  Two level lookup of both bucket and entry (inside that bucket)
//          indices;
//      2.  Lifetime checks to ensure no-one reallocated keys/values we
//          are using;
//      3. Appropriate clean up o keys/values that were already deallocated.
//
//      We spread the cost of the cleaning by pairing it with every bucket
//  access.
//      We only clean one (accessed) bucket per `FindEntryIndices()` and,
//  given that there isn't many hash collisions, this operation should not be
//  noticeably expensive.
//
//      As a result returns bucket's and entry's indices in `bucketIndex` and
//  `entryIndex` out variables.
//      `bucketIndex` is guaranteed to be found for non-`none` keys,
//  `entryIndex` is valid iff method returns `true`, otherwise it's equal to
//  the index at which new property can get inserted.
private final function bool FindEntryIndices(
    AcediaObject    key,
    out int         bucketIndex,
    out int         entryIndex)
{
    local int           i;
    local array<Entry>  bucketEntries;
    if (key == none)        return false;
    if (!key.IsAllocated()) return false;

    bucketIndex = GetBucketIndex(key);
    CleanBucket(hashTable[bucketIndex]);
    //  Check if bucket actually has given key.
    bucketEntries = hashTable[bucketIndex].entries;
    for (i = 0; i < bucketEntries.length; i += 1)
    {
        if (key.IsEqual(bucketEntries[i].key))
        {
            entryIndex = i;
            return true;
        }
    }
    entryIndex = bucketEntries.length;
    return false;
}

//  Cleans given bucket from entries with deallocated/reallocated
//  keys or values.
private final function CleanBucket(out Bucket bucketToClean)
{
    local int           i;
    local Entry         nextEntry;
    local array<Entry>  bucketEntries;
    bucketEntries = bucketToClean.entries;
    i = 0;
    while (i < bucketEntries.length)
    {
        nextEntry = bucketEntries[i];
        //  If value was already reallocated - set it to `none`.
        if (    nextEntry.value != none
            &&  nextEntry.value.GetLifeVersion() != nextEntry.valueLifeVersion)
        {
            bucketEntries[i].value = none;
        }
        //      If key was reallocated - it's value becomes essentially
        //  inaccessible, so we deallocate it.
        //      All keys, recorded in hash table, guaranteed to be `!= none`.
        if (nextEntry.key.GetLifeVersion() != nextEntry.keyLifeVersion)
        {
            if (bucketEntries[i].value != none && bucketEntries[i].managed) {
                bucketEntries[i].value.FreeSelf(nextEntry.keyLifeVersion);
            }
            bucketEntries.Remove(i, 1);
            //  We'll update the count, but won't trigger hash table size update
            //  to avoid making value's indices lookup more expensive, since
            //  this method is used in `FindEntryIndices()`.
            storedElementCount = Max(0, storedElementCount - 1);
            continue;
        }
        i += 1;
    }
    bucketToClean.entries = bucketEntries;
}

//  Checks if we need to change our current capacity and does so if needed
private final function UpdateHashTableCapacity()
{
    local int oldCapacity, newCapacity;
    oldCapacity = hashTable.length;
    //  Calculate new capacity (and whether it is needed) based on amount of
    //  stored properties and current capacity
    newCapacity = oldCapacity;
    if (storedElementCount < newCapacity * MINIMUM_DENSITY) {
        newCapacity /= 2;
    }
    if (storedElementCount > newCapacity * MAXIMUM_DENSITY) {
        newCapacity *= 2;
    }
    //  Enforce our limits
    newCapacity = Clamp(newCapacity, MINIMUM_CAPACITY, MAXIMUM_CAPACITY);
    //  Only resize if difference is huge enough or table does not exists yet
    if (newCapacity != oldCapacity) {
        ResizeHashTable(newCapacity);
    }
}

//      Changes size of the hash table, does not check any limits,
//  does not check if `newCapacity` is a valid capacity (`newCapacity > 0`).
private final function ResizeHashTable(int newCapacity)
{
    local int           i, j;
    local int           newBucketIndex, newEntryIndex;
    local array<Entry>  bucketEntries;
    local array<Bucket> oldHashTable;
    oldHashTable = hashTable;
    //  Clean current hash table
    hashTable.length = 0;
    hashTable.length = newCapacity;
    for (i = 0; i < oldHashTable.length; i += 1)
    {
        CleanBucket(oldHashTable[i]);
        bucketEntries = oldHashTable[i].entries;
        for (j = 0; j < bucketEntries.length; j += 1) {
            newBucketIndex = GetBucketIndex(bucketEntries[j].key);
            newEntryIndex = hashTable[newBucketIndex].entries.length;
            hashTable[newBucketIndex].entries[newEntryIndex] = bucketEntries[j];
        }
    }
}

/**
 *  Checks if caller `AssociativeArray` has value recorded with a given `key`.
 *
 *  @return `true` if caller `AssociativeArray` has value recorded with
 *      a given `key` and `false` otherwise.
 */
public final function bool HasKey(AcediaObject key)
{
    local int bucketIndex, entryIndex;
    return FindEntryIndices(key, bucketIndex, entryIndex);
}

/**
 *  Checks if caller `AssociativeArray`'s value recorded with a given `key`
 *  is managed.
 *
 *  Managed values will be automatically deallocated once they are removed
 *  (or overwritten) from the caller `AssociativeArray`.
 *
 *  @return `true` if value recorded with a given `key` is managed
 *      and `false` otherwise;
 *      if value is missing (`none` or there is not entry for the `key`),
 *      returns `false`.
 */
public final function bool IsManaged(AcediaObject key)
{
    local int bucketIndex, entryIndex;
    if (FindEntryIndices(key, bucketIndex, entryIndex)) {
        return hashTable[bucketIndex].entries[entryIndex].managed;
    }
    return false;
}

/**
 *  Returns value recorded by a given key `key` in the caller
 *  `AssociativeArray`.
 *
 *  Can return `none` if either stored values is `none` or there's no value
 *  recorded with a `key`. To check whether there is a record, corresponding to
 *  the `key` use `HasKey()` method.
 *
 *  @param  key Key for which to return value.
 *  @return Value, stored with given key `key`. If there is no value with
 *      such a key method will return `none`.
 */
public final function AcediaObject GetItem(AcediaObject key)
{
    local int bucketIndex, entryIndex;
    if (FindEntryIndices(key, bucketIndex, entryIndex)) {
        return hashTable[bucketIndex].entries[entryIndex].value;
    }
    return none;
}

/**
 *  Returns entry corresponding to a given key `key` in the caller
 *  `AssociativeArray`, removing it from the caller `AssociativeArray`.
 *
 *  Returned value is no longer managed by the `AssociativeArray` (if it was)
 *  and must be deallocated once you do not need them anymore.
 *
 *  @param  key Key for which to return entry.
 *  @return Entry (key/value pair + indicator of whether values was managed
 *      by `AssociativeArray`) with the given key `key`.
 */
public final function Entry TakeEntry(AcediaObject key)
{
    local Entry entryToTake;
    local int   bucketIndex, entryIndex;
    if (!FindEntryIndices(key, bucketIndex, entryIndex)) {
        return entryToTake;
    }
    entryToTake = hashTable[bucketIndex].entries[entryIndex];
    hashTable[bucketIndex].entries.Remove(entryIndex, 1);
    storedElementCount = Max(0, storedElementCount - 1);
    UpdateHashTableCapacity();
    return entryToTake;
}

/**
 *  Returns value recorded with a given key `key` in the caller
 *  `AssociativeArray`, removing it from the collection.
 *
 *  Returned value is no longer managed by the `AssociativeArray` (if it was)
 *  and must be deallocated once you do not need it anymore.
 *
 *  @param  key Key for which to return value.
 *  @return Value, stored with given key `key`. If there is no value with
 *      such a key method will return `none`.
 */
public final function AcediaObject TakeItem(AcediaObject key)
{
    return TakeEntry(key).value;
}

/**
 *  Records new `value` under the key `key` into the caller `AssociativeArray`.
 *
 *      If this will override already existing managed record - old value will
 *  be automatically deallocated (unless they are the same object as a new one).
 *      If you wish to avoid this behavior - retrieve them with either of
 *  `TakeItem()` or `TakeEntry()` methods first.
 *
 *  @param  key     Key by which new value will be referred to.
 *  @param  value   Value to store in the caller `AssociativeArray`.
 *  @return Caller `AssociativeArray` to allow for method chaining.
 */
public final function AssociativeArray SetItem(
    AcediaObject    key,
    AcediaObject    value,
    optional bool   managed)
{
    local Entry oldEntry, newEntry;
    local int   bucketIndex, entryIndex;
    if (key == none) {
        return self;
    }
    if (FindEntryIndices(key, bucketIndex, entryIndex)) {
        oldEntry = hashTable[bucketIndex].entries[entryIndex];
    }
    else {
        storedElementCount += 1;
    }
    newEntry.key                    = key;
    newEntry.keyLifeVersion         = key.GetLifeVersion();
    newEntry.managed                = managed;
    newEntry.value                  = value;
    if (value != none) {
        newEntry.valueLifeVersion   = value.GetLifeVersion();
    }
    if (    oldEntry.managed && oldEntry.value != none
        &&  newEntry.value != oldEntry.value)
    {
        oldEntry.value.FreeSelf(oldEntry.valueLifeVersion);
    }
    hashTable[bucketIndex].entries[entryIndex] = newEntry;
    return self;
}

/**
 *  Creates a new instance of class `valueClass` and records it's value with
 *  key `key` in the caller `AssociativeArray`. Value is recorded as managed.
 *
 *  @param  key         Key by which new value will be referred to.
 *  @param  valueClass  Class of object to create. Will only be created if
 *      passed `key` is valid.
 *  @return Caller `AssociativeArray` to allow for method chaining.
 */
public final function AssociativeArray CreateItem(
    AcediaObject        key,
    class<AcediaObject> valueClass)
{
    if (key == none)        return self;
    if (valueClass == none) return self;

    return SetItem(key, AcediaObject(_.memory.Allocate(valueClass)), true);
}

/**
 *  Removes a value recorded with a given key `key`.
 *  Does nothing if entry with a given key does not exist.
 *
 *  Removed values are deallocated if they are managed. If you wish to avoid
 *  that, use `TakeItem()` or `TakeEntry()` methods.
 *
 *  @param  key Key for which to remove value.
 *  @return Caller `AssociativeArray` to allow for method chaining.
 */
public final function AssociativeArray RemoveItem(AcediaObject key)
{
    local Entry entryToRemove;
    local int   bucketIndex, entryIndex;
    if (key == none) return self;

    if (!FindEntryIndices(key, bucketIndex, entryIndex)) {
        return self;
    }
    entryToRemove = hashTable[bucketIndex].entries[entryIndex];
    hashTable[bucketIndex].entries.Remove(entryIndex, 1);
    storedElementCount = Max(0, storedElementCount - 1);
    UpdateHashTableCapacity();
    if (entryToRemove.managed && entryToRemove.value != none) {
        entryToRemove.value.FreeSelf(entryToRemove.valueLifeVersion);
    }
    return self;
}

/**
 *  Completely clears caller `AssociativeArray` of all stored entries,
 *  deallocating any stored managed values.
 *
 *  @return Caller `AssociativeArray` to allow for method chaining.
 */
public function Empty()
{
    local int           i, j;
    local array<Entry>  nextEntries;
    for (i = 0; i < hashTable.length; i += 1)
    {
        nextEntries = hashTable[i].entries;
        for (j = 0; j < nextEntries.length; j += 1)
        {
            if (!nextEntries[j].managed)      continue;
            if (nextEntries[j].value == none) continue;
            nextEntries[j].value.FreeSelf(nextEntries[j].valueLifeVersion);
        }
    }
    hashTable.length = 0;
    storedElementCount = 0;
}

/**
 *  Returns key of all properties inside caller `AssociativeArray`.
 *
 *  Collecting all keys from the `AssociativeArray` is O(<number_of_elements>).
 *
 *  @return Array of all the caller `AssociativeArray`'s keys.
 */
public final function array<AcediaObject> GetKeys()
{
    local int                   i, j;
    local array<AcediaObject>   result;
    local array<Entry>          nextEntry;
    for (i = 0; i < hashTable.length; i += 1)
    {
        //hashTable[i] = CleanBucket(hashTable[i]);
        CleanBucket(hashTable[i]);
        nextEntry = hashTable[i].entries;
        for (j = 0; j < nextEntry.length; j += 1) {
            result[result.length] = nextEntry[j].key;
        }
    }
    return result;
}

/**
 *  Returns amount of elements in the caller `AssociativeArray`.
 *
 *      Note that this value might overestimate real amount of values inside
 *  `AssociativeArray` in case some of the keys used for storage were
 *  deallocated by code outside of `AssociativeArray`.
 *      Such values might be eventually found and removed, but
 *  `AssociativeArray` does not provide any guarantees on when it's done.
 */
public final function int GetLength()
{
    return storedElementCount;
}

/**
 *  Auxiliary method for iterator that increments given `Index` structure.
 *
 *  @param  previousIndex   Index to increment.
 *  @return `true` if incremented index is pointing at a valid item,
 *      `false` if collection has ended.
 */
public final function bool IncrementIndex(out Index previousIndex)
{
    previousIndex.entryIndex += 1;
    //  Go forward through buckets until we find non-empty one
    while (previousIndex.bucketIndex < hashTable.length)
    {
        CleanBucket(hashTable[previousIndex.bucketIndex]);
        if (    previousIndex.entryIndex
            <   hashTable[previousIndex.bucketIndex].entries.length)
        {
            return true;
        }
        previousIndex.entryIndex = 0;
        previousIndex.bucketIndex += 1;
    }
    return false;
}

/**
 *  Auxiliary method for iterator that returns value corresponding to
 *  a given `Index` structure.
 *
 *  @param  index   Index of item to return.
 *  @return `Entry` corresponding to a given index. If index is invalid
 *      (not pointing at any value for caller `AssociativeArray`) returns
 *      `Entry` with key and value set to `none`.
 *      Note that `none` can be returned because that is simply the value
 *      being stored.
 */
public final function Entry GetEntryByIndex(Index index)
{
    local Entry emptyEntry;
    if (index.bucketIndex < 0)                  return emptyEntry;
    if (index.bucketIndex >= hashTable.length)  return emptyEntry;
    if (    index.entryIndex < 0
        ||  index.entryIndex >= hashTable[index.bucketIndex].entries.length) {
        return emptyEntry;
    }
    return hashTable[index.bucketIndex].entries[index.entryIndex];
}

defaultproperties
{
    iteratorClass = class'AssociativeArrayIterator'
    MINIMUM_CAPACITY    = 50
    MAXIMUM_CAPACITY    = 10000
    MINIMUM_DENSITY     = 0.25
    MAXIMUM_DENSITY     = 0.75
}