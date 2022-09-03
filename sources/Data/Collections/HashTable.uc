/**
 *      This class implements an associative array for storing arbitrary types
 *  of data that provides a quick (near constant) access to *values* by
 *  associated *keys*.
 *      Since UnrealScript lacks any sort of templating, `HashTable`
 *  stores generic `AcediaObject` keys and values. `Text` can be used instead of
 *  typical `string` keys and primitive values can be added in their boxed form
 *  (either as actual `<Type>Box` or as it's reference counterpart).
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
class HashTable extends Collection;

// Defines key <-> value mapping
struct Entry
{
    var AcediaObject key;
    var AcediaObject value;
};

//  Bucket of entries.
//  Used to store entries with the same index in hash table.
struct Bucket
{
    var array<Entry> entries;
};
var private array<Bucket> hashTable;

//      Amount of elements currently stored in this `HashTable`.
//      If one of the keys was deallocated outside of `HashTable`,
//  this value may overestimate actual amount of elements.
var private int storedElementCount;
//  Lower limit on hash table capacity, can be changed by the user.
var private int minimalCapacity;

//  hard lower and upper limits on hash table size, constant.
var private const int MINIMUM_SIZE;
var private const int MAXIMUM_SIZE;
//      Minimum and maximum allowed density of elements
//  (`storedElementCount / hashTable.length`).
//      If density falls outside this range, - we have to resize hash table to
//  get into (MINIMUM_DENSITY; MAXIMUM_DENSITY) bounds, as long as it does not
//  violate hard size restrictions.
//      Actual size changes in multipliers of 2, so
//  `MINIMUM_DENSITY * 2 < MAXIMUM_DENSITY` must hold or we will constantly
//  oscillate outside of (MINIMUM_DENSITY; MAXIMUM_DENSITY) bounds.
var private const float MINIMUM_DENSITY;
var private const float MAXIMUM_DENSITY;

/**
 *  Auxiliary struct, necessary to implement iterator for `HashTable`.
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
    UpdateHashTableSize();
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

//  Accessing value in `HashTable` requires two level lookup of both bucket and
//  entry (inside that bucket) indices.
//
//      As a result returns bucket's and entry's indices in `bucketIndex` and
//  `entryIndex` inside `out` variables.
//      `bucketIndex` is guaranteed to be found for non-`none` keys (in case you
//  want to add a new entry), `entryIndex` is valid iff method returns `true`,
//  otherwise it's equal to the index at which new property can get inserted.
private final function bool FindEntryIndices(
    AcediaObject    key,
    out int         bucketIndex,
    out int         entryIndex)
{
    local int           i;
    local array<Entry>  bucketEntries;

    if (key == none){
        return false; 
    }
    bucketIndex = GetBucketIndex(key);
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

//  Checks if we need to change our current hash table size
//  and does so if needed
private final function UpdateHashTableSize()
{
    local int oldSize, newSize;

    oldSize = hashTable.length;
    //  Calculate new size (and whether it is needed) based on amount of
    //  stored properties and current size
    newSize = oldSize;
    if (storedElementCount < newSize * MINIMUM_DENSITY) {
        newSize /= 2;
    }
    else if (storedElementCount > newSize * MAXIMUM_DENSITY) {
        newSize *= 2;
    }
    //  `table_density = items_amount / table_size`, so to store at least
    //  `items_amount = minimalCapacity` without making table too dense we need
    //  `table_size = minimalCapacity / MAXIMUM_DENSITY`.
    newSize = Max(newSize, Ceil(minimalCapacity / MAXIMUM_DENSITY));
    //  But everything must fall into the set hard limits
    newSize = Clamp(newSize, MINIMUM_SIZE, MAXIMUM_SIZE);
    //  Only resize if difference is huge enough or table does not exists yet
    if (newSize != oldSize) {
        ResizeHashTable(newSize);
    }
}

//      Changes size of the hash table, does not check any limits,
//  does not check if `newSize` is a valid size (`newSize > 0`).
private final function ResizeHashTable(int newSize)
{
    local int           i, j;
    local int           newBucketIndex, newEntryIndex;
    local array<Entry>  bucketEntries;
    local array<Bucket> oldHashTable;

    oldHashTable = hashTable;
    //  Clean current hash table
    hashTable.length = 0;
    hashTable.length = newSize;
    for (i = 0; i < oldHashTable.length; i += 1)
    {
        bucketEntries = oldHashTable[i].entries;
        for (j = 0; j < bucketEntries.length; j += 1)
        {
            newBucketIndex  = GetBucketIndex(bucketEntries[j].key);
            newEntryIndex   = hashTable[newBucketIndex].entries.length;
            hashTable[newBucketIndex].entries[newEntryIndex] = bucketEntries[j];
        }
    }
}

/**
 *  Returns minimal capacity of the caller associative array.
 *
 *  See `SetMinimalCapacity()` for details.
 *
 *  @return Minimal capacity of the caller associative array. Default is zero.
 */
public final function int GetMinimalCapacity()
{
    return minimalCapacity;
}

/**
 *  Returns minimal capacity of the caller associative array.
 *
 *      This associative array works like a hash table and needs to allocate
 *  sufficiently large dynamic array as a storage for its items.
 *  If you keep adding new items that storage will eventually become too small
 *  for hash table to work efficiently and we will have to reallocate and
 *  re-fill it. If you want to add a huge enough amount of items, this process
 *  can be repeated several times.
 *      This is not ideal, since it means doing a lot of iteration, each
 *  increasing infinite loop counter (game will crash if it gets high enough).
 *      Setting minimal capacity to the (higher) amount of items you expect to
 *  store in the caller array can remove the need for reallocating the storage.
 *
 *  @param  newMinimalCapacity  New minimal capacity of this associative array.
 *      It's recommended to set it to the max amount of items you expect to
 *      store in this associative array
 *      (you will be still allowed to store more).
 */
public final function SetMinimalCapacity(int newMinimalCapacity)
{
    minimalCapacity = newMinimalCapacity;
    UpdateHashTableSize();
}

/**
 *  Checks if caller `HashTable` has value recorded with a given `key`.
 *
 *  @return `true` if caller `HashTable` has value recorded with
 *      a given `key` and `false` otherwise.
 */
public final function bool HasKey(AcediaObject key)
{
    local int bucketIndex, entryIndex;

    return FindEntryIndices(key, bucketIndex, entryIndex);
}

/**
 *  Returns borrowed value recorded by a given key `key` in the caller
 *  `HashTable`.
 *
 *  Can return `none` if either stored values is `none` or there's no value
 *  recorded with a `key`. To check whether there is a record, corresponding to
 *  the `key` use `HasKey()` method.
 *
 *  @param  key Key for which to return value.
 *  @return Value, stored with given key `key`. If there is no value with
 *      such a key method will return `none`.
 */
private final function AcediaObject BorrowItem(AcediaObject key)
{
    local int bucketIndex, entryIndex;

    if (FindEntryIndices(key, bucketIndex, entryIndex)) {
        return hashTable[bucketIndex].entries[entryIndex].value;
    }
    return none;
}

/**
 *  Returns value recorded by a given key `key` in the caller
 *  `HashTable`.
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
    local int           bucketIndex, entryIndex;
    local AcediaObject  result;

    if (FindEntryIndices(key, bucketIndex, entryIndex)) {
        result = hashTable[bucketIndex].entries[entryIndex].value;
    }
    if (result != none) {
        return result.NewRef();
    }
    return none;
}

/**
 *  Returns entry corresponding to a given key `key` in the caller
 *  `HashTable`.
 *
 *  @param  key Key for which to return entry.
 *  @return Entry (key/value pair) with the given key `key`.
 */
public final function Entry GetEntry(AcediaObject key)
{
    local Entry result;
    local int   bucketIndex, entryIndex;

    if (!FindEntryIndices(key, bucketIndex, entryIndex)) {
        return result;
    }
    result = hashTable[bucketIndex].entries[entryIndex];
    if (result.key != none) {
        result.key.NewRef();
    }
    if (result.value != none) {
        result.value.NewRef();
    }
    return result;
}

/**
 *  Returns entry corresponding to a given key `key` in the caller
 *  `HashTable`, removing it from the caller `HashTable`.
 *
 *  @param  key Key for which to return entry.
 *  @return Entry (key/value pair) with the given key `key`.
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
    UpdateHashTableSize();
    return entryToTake;
}

/**
 *  Returns value recorded with a given key `key` in the caller
 *  `HashTable`, removing it from the collection.
 *
 *  @param  key     Key for which to return value.
 *  @param  freeKey Setting this to `true` will also free the key item was
 *      stored with. Passed argument `key` will not be deallocated, unless it is
 *      the exact same object as item's key inside caller collection.
 *  @return Value, stored with given key `key`. If there is no value with
 *      such a key method will return `none`.
 */
public final function AcediaObject TakeItem(AcediaObject key)
{
    local Entry entry;

    entry = TakeEntry(key);
    if (entry.key != none) {
        entry.key.FreeSelf();
    }
    return entry.value;
}

/**
 *  Records new `value` under the key `key` into the caller `HashTable`.
 *
 *  @param  key     Key by which new value will be referred to.
 *  @param  value   Value to store in the caller `HashTable`.
 *  @return Caller `HashTable` to allow for method chaining.
 */
public final function HashTable SetItem(
    AcediaObject    key,
    AcediaObject    value)
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
    key.NewRef();
    _.memory.Free(oldEntry.key);
    newEntry.key    = key;
    newEntry.value  = value;
    if (value != none) {
        value.NewRef();
    }
    if (oldEntry.value != none) {
        oldEntry.value.FreeSelf();
    }
    hashTable[bucketIndex].entries[entryIndex] = newEntry;
    return self;
}

/**
 *  Creates a new instance of class `valueClass` and records it's value with
 *  key `key` in the caller `HashTable`.
 *
 *  @param  key         Key by which new value will be referred to.
 *  @param  valueClass  Class of object to create. Will only be created if
 *      passed `key` is valid.
 *  @return Caller `HashTable` to allow for method chaining.
 */
public final function HashTable CreateItem(
    AcediaObject        key,
    class<AcediaObject> valueClass)
{
    local AcediaObject newItem;

    if (key == none)        return self;
    if (valueClass == none) return self;

    newItem = AcediaObject(_.memory.Allocate(valueClass));
    SetItem(key, newItem);
    newItem.FreeSelf();
    return self;
}

/**
 *  Removes a value recorded with a given key `key`.
 *  Does nothing if entry with a given key does not exist.
 *
 *  @param  key Key for which to remove value.
 *  @return Caller `HashTable` to allow for method chaining.
 */
public final function HashTable RemoveItem(AcediaObject key)
{
    local Entry entryToRemove;
    local int   bucketIndex, entryIndex;

    if (key == none)                                        return self;
    if (!FindEntryIndices(key, bucketIndex, entryIndex))    return self;

    entryToRemove = hashTable[bucketIndex].entries[entryIndex];
    hashTable[bucketIndex].entries.Remove(entryIndex, 1);
    storedElementCount = Max(0, storedElementCount - 1);
    UpdateHashTableSize();
    if (entryToRemove.value != none) {
        entryToRemove.value.FreeSelf();
    }
    if (entryToRemove.key != none) {
        entryToRemove.key.FreeSelf();
    }
    return self;
}

public function Empty()
{
    local int           i, j;
    local array<Entry>  nextEntries;

    for (i = 0; i < hashTable.length; i += 1)
    {
        nextEntries = hashTable[i].entries;
        for (j = 0; j < nextEntries.length; j += 1)
        {
            if (nextEntries[j].value != none) {
                nextEntries[j].value.FreeSelf();
            }
            if (nextEntries[j].key != none) {
                nextEntries[j].key.FreeSelf();
            }
        }
    }
    hashTable.length = 0;
    storedElementCount = 0;
    UpdateHashTableSize();
}

/**
 *  Returns key of all properties inside caller `HashTable`.
 *
 *  Collecting all keys from the `HashTable` is O(<number_of_elements>).
 *
 *  See also `GetTextKeys()` methods.
 *
 *  @return Array of all the caller `HashTable`'s keys.
 *      This method does not return copies of keys, but actual keys instead -
 *      deallocating them will remove their item from
 *      the caller `HashTable`.
 */
public final function array<AcediaObject> GetKeys()
{
    local int                   i, j;
    local array<AcediaObject>   result;
    local array<Entry>          nextEntry;

    for (i = 0; i < hashTable.length; i += 1)
    {
        nextEntry = hashTable[i].entries;
        for (j = 0; j < nextEntry.length; j += 1)
        {
            nextEntry[j].key.NewRef();
            result[result.length] = nextEntry[j].key;
        }
    }
    return result;
}

/**
 *  Returns copies of `Text` key of all properties inside caller
 *  `HashTable`. Keys that have a different class (even if they are
 *  a child class for `Text`) are not returned.
 *
 *  Collecting all keys from the `HashTable` is O(<number_of_elements>).
 *
 *  @return Array of all the caller `HashTable`'s keys that have exactly
 *      `Text` class.
 */
public final function array<Text> GetTextKeys()
{
    local int           i, j;
    local Text          nextKeyAsText;
    local array<Text>   result;
    local array<Entry>  nextEntry;

    for (i = 0; i < hashTable.length; i += 1)
    {
        nextEntry = hashTable[i].entries;
        for (j = 0; j < nextEntry.length; j += 1)
        {
            nextKeyAsText = Text(nextEntry[j].key);
            if (nextKeyAsText != none && nextKeyAsText.class == class'Text')
            {
                result[result.length] = nextKeyAsText.Copy();
            }
        }
    }
    return result;
}

/**
 *  Returns amount of elements in the caller `HashTable`.
 *
 *      Note that this value might overestimate real amount of values inside
 *  `HashTable` in case some of the keys used for storage were
 *  deallocated by code outside of `HashTable`.
 *      Such values might be eventually found and removed, but
 *  `HashTable` does not provide any guarantees on when it's done.
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
 *  @return Item corresponding to a given index.
 *      If index is invalid returns `none`.
 *      Note that `none` can be returned because that is simply the value
 *      being stored.
 */
public final function AcediaObject GetItemByIndex(Index index)
{
    local AcediaObject item;

    if (index.bucketIndex < 0)                  return none;
    if (index.bucketIndex >= hashTable.length)  return none;

    if (    index.entryIndex < 0
        ||  index.entryIndex >= hashTable[index.bucketIndex].entries.length) {
        return none;
    }
    item = hashTable[index.bucketIndex].entries[index.entryIndex].value;
    if (item == none) {
        return none;
    }
    return item.NewRef();
}

/**
 *  Auxiliary method for iterator that returns value corresponding to
 *  a given `Index` structure.
 *
 *  @param  index   Index of item to return.
 *  @return Key corresponding to a given index.
 *      If index is invalid returns `none`.
 */
public final function AcediaObject GetKeyByIndex(Index index)
{
    local AcediaObject key;

    if (index.bucketIndex < 0)                  return none;
    if (index.bucketIndex >= hashTable.length)  return none;
    if (    index.entryIndex < 0
        ||  index.entryIndex >= hashTable[index.bucketIndex].entries.length) {
        return none;
    }
    key = hashTable[index.bucketIndex].entries[index.entryIndex].key;
    if (key == none) {
        return none;
    }
    return key.NewRef();
}

protected function AcediaObject GetByText(BaseText key)
{
    return GetItem(key);
}

/**
 *  Checks if value corresponding to a given `Index` structure is not `none`.
 *
 *  @param  key Key to check the value at.
 *  @return `true` if non-`none` value is recorded at `key` and
 *      `false` otherwise.
 */
public final function bool IsSomethingByIndex(Index index)
{
    if (index.bucketIndex < 0)                  return false;
    if (index.bucketIndex >= hashTable.length)  return false;

    if (    index.entryIndex < 0
        ||  index.entryIndex >= hashTable[index.bucketIndex].entries.length) {
        return false;
    }
    return
        (hashTable[index.bucketIndex].entries[index.entryIndex].value != none);
}

/**
 *  Checks if value recorded at a given `key` is not `none`.
 *
 *  @param  key Key to check the value at.
 *  @return `true` if non-`none` value is recorded at `key` and
 *      `false` otherwise.
 */
public final function bool IsSomething(AcediaObject key)
{
    return (BorrowItem(key) != none);
}

/**
 *  Returns `bool` item at key `key`. If key is invalid or
 *  stores a non-`bool` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `BoolBox` or `BoolRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  key             Key of a `bool` item that `HashTable` has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `key` or it has a wrong type.
 *  @return `bool` value at `key` in the caller `HashTable`.
 *      `defaultValue` if passed `key` is invalid or non-`bool` value
 *      is stored with it.
 */
public final function bool GetBool(AcediaObject key, optional bool defaultValue)
{
    local AcediaObject  result;
    local BoolBox       asBox;
    local BoolRef       asRef;

    result = BorrowItem(key);
    if (result == none) {
        return defaultValue;
    }
    asBox = BoolBox(result);
    if (asBox != none) {
        return asBox.Get();
    }
    asRef = BoolRef(result);
    if (asRef != none) {
        return asRef.Get();
    }
    return defaultValue;
}

/**
 *  Changes `HashTable`'s value at key `key` to `value` that will be
 *  recorded as either `BoolBox` or `BoolRef`, depending of `asRef`
 *  optional parameter.
 *
 *  @param  key     Key, at which to change the value.
 *  @param  value   Value to be set at a given key.
 *  @param  asRef   Given `bool` value will be recorded as immutable `BoolBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `BoolRef`.
 *  @return Reference to the caller `HashTable` to allow for
 *      method chaining.
 */
public final function HashTable SetBool(
    AcediaObject    key,
    bool            value,
    optional bool   asRef)
{
    local AcediaObject newValue;

    if (asRef) {
        newValue = _.ref.bool(value);
    }
    else {
        newValue = _.box.bool(value);
    }
    SetItem(key, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns `byte` item at key `key`. If key is invalid or
 *  stores a non-`byte` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `ByteBox` or `ByteBox`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  key             Key of a `byte` item that `HashTable`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `key` or it has a wrong type.
 *  @return `byte` value at `key` in the caller `HashTable`.
 *      `defaultValue` if passed `key` is invalid or non-`byte` value
 *      is stored with it.
 */
public final function byte GetByte(AcediaObject key, optional byte defaultValue)
{
    local AcediaObject  result;
    local ByteBox       asBox;
    local ByteRef       asRef;

    result = BorrowItem(key);
    if (result == none) {
        return defaultValue;
    }
    asBox = ByteBox(result);
    if (asBox != none) {
        return asBox.Get();
    }
    asRef = ByteRef(result);
    if (asRef != none) {
        return asRef.Get();
    }
    return defaultValue;
}

/**
 *  Changes `HashTable`'s value at key `key` to `value` that will be
 *  recorded as either `ByteBox` or `ByteBox`, depending of `asRef`
 *  optional parameter.
 *
 *  @param  key     Key, at which to change the value.
 *  @param  value   Value to be set at a given key.
 *  @param  asRef   Given `byte` value will be recorded as immutable `ByteBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `ByteBox`.
 *  @return Reference to the caller `HashTable` to allow for
 *      method chaining.
 */
public final function HashTable SetByte(
    AcediaObject    key,
    byte            value,
    optional bool   asRef)
{
    local AcediaObject newValue;

    if (asRef) {
        newValue = _.ref.byte(value);
    }
    else {
        newValue = _.box.byte(value);
    }
    SetItem(key, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns `int` or `float` item at key `key` as `int`. If key is invalid or
 *  stores a non-`int` (or non-`float`) value, returns `defaultValue`.
 *
 *  Referred value must be stored as `IntBox`, `IntRef`, `FloatBox` or
 *  `FloatRef` (or one of their sub-classes) for this method to work.
 *
 *  Allowing for implicit conversion between non-`byte` numeric types simplifies
 *  handling parsed input as there is no need to know whether parsed value is
 *  expected to be integer or floating point.
 *
 *  @param  key             Key of a `int` item that `HashTable`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `key` or it has a wrong type.
 *  @return `int` value at `key` in the caller `HashTable`.
 *      `defaultValue` if passed `key` is invalid or non-`int` value
 *      is stored with it.
 */
public final function int GetInt(AcediaObject key, optional int defaultValue)
{
    local AcediaObject  result;
    local IntBox        asBox;
    local IntRef        asRef;
    local FloatBox      asFloatBox;
    local FloatRef      asFloatRef;

    result = BorrowItem(key);
    if (result == none) {
        return defaultValue;
    }
    asBox = IntBox(result);
    if (asBox != none) {
        return asBox.Get();
    }
    asRef = IntRef(result);
    if (asRef != none) {
        return asRef.Get();
    }
    asFloatBox = FloatBox(result);
    if (asFloatBox != none) {
        return int(asFloatBox.Get());
    }
    asFloatRef = FloatRef(result);
    if (asFloatRef != none) {
        return int(asFloatRef.Get());
    }
    return defaultValue;
}

/**
 *  Changes `HashTable`'s value at key `key` to `value` that will be
 *  recorded as either `IntBox` or `IntRef`, depending of `asRef`
 *  optional parameter.
 *
 *  @param  key     Key, at which to change the value.
 *  @param  value   Value to be set at a given key.
 *  @param  asRef   Given `int` value will be recorded as immutable `IntBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `IntRef`.
 *  @return Reference to the caller `HashTable` to allow for
 *      method chaining.
 */
public final function HashTable SetInt(
    AcediaObject    key,
    int             value,
    optional bool   asRef)
{
    local AcediaObject newValue;

    if (asRef) {
        newValue = _.ref.int(value);
    }
    else {
        newValue = _.box.int(value);
    }
    SetItem(key, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns `int` or `float` item at key `key` as `float`. If key is invalid or
 *  stores a non-`float` (or non-`int`) value, returns `defaultValue`.
 *
 *  Referred value must be stored as `IntBox`, `IntRef`, `FloatBox` or
 *  `FloatRef` (or one of their sub-classes) for this method to work.
 *
 *  Allowing for implicit conversion between non-`byte` numeric types simplifies
 *  handling parsed input as there is no need to know whether parsed value is
 *  expected to be integer or floating point.
 *
 *  @param  key             Key of a `float` item that `HashTable`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `key` or it has a wrong type.
 *  @return `float` value at `key` in the caller `HashTable`.
 *      `defaultValue` if passed `key` is invalid or non-`float` value
 *      is stored with it.
 */
public final function float GetFloat(
    AcediaObject    key,
    optional float  defaultValue)
{
    local AcediaObject  result;
    local FloatBox      asBox;
    local FloatRef      asRef;
    local IntBox        asIntBox;
    local IntRef        asIntRef;

    result = BorrowItem(key);
    if (result == none) {
        return defaultValue;
    }
    asBox = FloatBox(result);
    if (asBox != none) {
        return asBox.Get();
    }
    asRef = FloatRef(result);
    if (asRef != none) {
        return asRef.Get();
    }
    asIntBox = IntBox(result);
    if (asIntBox != none) {
        return float(asIntBox.Get());
    }
    asIntRef = IntRef(result);
    if (asIntRef != none) {
        return float(asIntRef.Get());
    }
    return defaultValue;
}

/**
 *  Changes `HashTable`'s value at key `key` to `value` that will be
 *  recorded as either `FloatBox` or `FloatRef`, depending of `asRef`
 *  optional parameter.
 *
 *  @param  key     Key, at which to change the value.
 *  @param  value   Value to be set at a given key.
 *  @param  asRef   Given `float` value will be recorded as immutable `FloatBox`
 *      by default (`asRef == false`). Setting this parameter to `true` will
 *      make this method record it as a mutable `FloatRef`.
 *  @return Reference to the caller `HashTable` to allow for method chaining.
 */
public final function HashTable SetFloat(
    AcediaObject    key,
    float           value,
    optional bool   asRef)
{
    local AcediaObject newValue;

    if (asRef) {
        newValue = _.ref.float(value);
    }
    else {
        newValue = _.box.float(value);
    }
    SetItem(key, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns `Vector` item at key `key`. If key is invalid or
 *  stores a non-`Vector` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `VectorBox` or `VectorRef`
 *  (or one of their sub-classes) for this method to work.
 *
 *  @param  key             Key of a `Vector` item that `HashTable`
 *      has to return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `key` or it has a wrong type.
 *  @return `Vector` value at `key` in the caller `HashTable`.
 *      `defaultValue` if passed `key` is invalid or non-`Vector` value
 *      is stored with it.
 */
public final function Vector GetVector(
    AcediaObject    key,
    optional Vector defaultValue)
{
    local AcediaObject  result;
    local VectorBox      asBox;
    local VectorRef      asRef;

    result = BorrowItem(key);
    if (result == none) {
        return defaultValue;
    }
    asBox = VectorBox(result);
    if (asBox != none) {
        return asBox.Get();
    }
    asRef = VectorRef(result);
    if (asRef != none) {
        return asRef.Get();
    }
    return defaultValue;
}

/**
 *  Changes `HashTable`'s value at key `key` to `value` that will be
 *  recorded as either `VectorBox` or `VectorRef`, depending of `asRef`
 *  optional parameter.
 *
 *  @param  key     Key, at which to change the value.
 *  @param  value   Value to be set at a given key.
 *  @param  asRef   Given `Vector` value will be recorded as immutable
 *      `VectorBox` by default (`asRef == false`). Setting this parameter to
 *      `true` will make this method record it as a mutable `VectorRef`.
 *  @return Reference to the caller `HashTable` to allow for method chaining.
 */
public final function HashTable SetVector(
    AcediaObject    key,
    Vector          value,
    optional bool   asRef)
{
    local AcediaObject newValue;

    if (asRef) {
        newValue = _.ref.Vec(value);
    }
    else {
        newValue = _.box.Vec(value);
    }
    SetItem(key, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns plain string item at key `key`. If key is invalid or stores
 *  a non-`BaseText` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `Text` or `MutableText` (or one of their
 *  sub-classes) for this method to work.
 *
 *  @param  key             Key of a `string` item that `HashTable` has to
 *      return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `key` or it has a wrong type.
 *  @return Plain string value at `key` in the caller `HashTable`.
 *      `defaultValue` if passed `key` is invalid or non-`BaseText` value is
 *      stored with it.
 */
public final function string GetString(
    AcediaObject    key,
    optional string defaultValue)
{
    local AcediaObject  result;
    local BaseText      asText;

    result = BorrowItem(key);
    if (result == none) {
        return defaultValue;
    }
    asText = BaseText(result);
    if (asText != none) {
        return asText.ToString();
    }
    return defaultValue;
}

/**
 *  Changes `HashTable`'s value at key `key` to plain string `value` that will
 *  be recorded as either `Text` or `MutableText`, depending of `asMutable`
 *  optional parameter.
 *
 *  @param  key         Key, at which to change the value.
 *  @param  value       Value to be set at a given key.
 *  @param  asMutable   Given plain string value will be recorded as immutable
 *      `Text` by default (`asMutable == false`). Setting this parameter to
 *      `true` will make this method record it as a mutable `MutableText`.
 *  @return Reference to the caller `HashTable` to allow for
 *      method chaining.
 */
public final function HashTable SetString(
    AcediaObject    key,
    string          value,
    optional bool   asMutable)
{
    local AcediaObject newValue;

    if (asMutable) {
        newValue = _.text.FromStringM(value);
    }
    else {
        newValue = _.text.FromString(value);
    }
    SetItem(key, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns formatted string item at key `key`. If key is invalid or stores
 *  a non-`BaseText` value, returns `defaultValue`.
 *
 *  Referred value must be stored as `Text` or `MutableText` (or one of their
 *  sub-classes) for this method to work.
 *
 *  @param  key             Key of a `string` item that `HashTable` has to
 *      return.
 *  @param  defaultValue    Value to return if there is either no item recorded
 *      at `key` or it has a wrong type.
 *  @return Formatted string value at `key` in the caller `HashTable`.
 *      `defaultValue` if passed `key` is invalid or non-`BaseText` value is
 *      stored with it.
 */
public final function string GetFormattedString(
    AcediaObject    key,
    optional string defaultValue)
{
    local AcediaObject  result;
    local BaseText      asText;

    result = BorrowItem(key);
    if (result == none) {
        return defaultValue;
    }
    asText = BaseText(result);
    if (asText != none) {
        return asText.ToFormattedString();
    }
    return defaultValue;
}

/**
 *  Changes `HashTable`'s value at key `key` to formatted string `value` that
 *  will be recorded as either `Text` or `MutableText`, depending of `asMutable`
 *  optional parameter.
 *
 *  @param  key         Key, at which to change the value.
 *  @param  value       Value to be set at a given key.
 *  @param  asMutable   Given formatted string value will be recorded as
 *      immutable `Text` by default (`asMutable == false`). Setting this
 *      parameter to `true` will make this method record it as a mutable
 *      `MutableText`.
 *  @return Reference to the caller `HashTable` to allow for
 *      method chaining.
 */
public final function HashTable SetFormattedString(
    AcediaObject    key,
    string          value,
    optional bool   asMutable)
{
    local AcediaObject newValue;

    if (asMutable) {
        newValue = _.text.FromFormattedStringM(value);
    }
    else {
        newValue = _.text.FromFormattedString(value);
    }
    SetItem(key, newValue);
    newValue.FreeSelf();
    return self;
}

/**
 *  Returns `Text` item stored at key `key`. If key is invalid or
 *  stores a non-`Text` value, returns `none`.
 *
 *  Referred value must be stored as `Text` (or one of it's sub-classes,
 *  such as `MutableText`) for this method to work.
 *
 *  @param  key Key of a `Text` item that `HashTable`
 *      has to return.
 *  @return `Text` value recorded with `key` in the caller `HashTable`.
 *      `none` if passed `key` is invalid or non-`Text` value
 *      is stored with it.
 */
public final function Text GetText(AcediaObject key)
{
    local Text result;

    result = Text(BorrowItem(key));
    if (result != none) {
        result.NewRef();
    }
    return result;
}

/**
 *  Returns `HashTable` item stored at key `key`. If key is invalid or
 *  stores a non-`HashTable` value, returns `none`.
 *
 *  Referred value must be stored as `HashTable`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  key Key of a `HashTable` item that caller `HashTable`
 *      has to return.
 *  @return `HashTable` value recorded with `key` in the caller
 *      `HashTable`. `none` if passed `key` is invalid or
 *      non-`HashTable` value is stored with it.
 */
public final function HashTable GetHashTable(AcediaObject key)
{
    local HashTable result;

    result = HashTable(BorrowItem(key));
    if (result != none) {
        result.NewRef();
    }
    return result;
}

/**
 *  Returns `ArrayList` item stored at key `key`. If key is invalid or
 *  stores a non-`ArrayList` value, returns `none`.
 *
 *  Referred value must be stored as `ArrayList`
 *  (or one of it's sub-classes) for this method to work.
 *
 *  @param  key Key of a `ArrayList` item that caller `HashTable`
 *      has to return.
 *  @return `ArrayList` value recorded with `key` in the caller
 *      `HashTable`. `none` if passed `key` is invalid or
 *      non-`ArrayList` value is stored with it.
 */
public final function ArrayList GetArrayList(AcediaObject key)
{
    local ArrayList result;

    result = ArrayList(BorrowItem(key));
    if (result != none) {
        result.NewRef();
    }
    return result;
}

defaultproperties
{
    iteratorClass = class'HashTableIterator'
    minimalCapacity = 0
    MINIMUM_SIZE    = 50
    MAXIMUM_SIZE    = 20000
    //  `MINIMUM_DENSITY * 2 < MAXIMUM_DENSITY` must hold for `HashTable`
    //  to work properly
    MINIMUM_DENSITY = 0.25
    MAXIMUM_DENSITY = 0.75
}