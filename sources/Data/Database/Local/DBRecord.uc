/**
 *      This should be considered an internal class and a detail of
 *  implementation.
 *      This is a data object that is used to store JSON data inside
 *  Unreal Engine's save packages (see `GameInfo` class, starting from
 *  `CreateDataObject()` method).
 *      Auxiliary data object that can store either a JSON array or an object in
 *  the local Acedia database. It is supposed to be saved and loaded
 *  to / from packages.
 *      Copyright 2021-2022 Anton Tarasenko
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
class DBRecord extends Object
    perobjectconfig
    config(AcediaDB);

/**
 *  # How can JSON information be stored in per-config-objects?
 *      Standard way to store information locally would be by simply recording
 *  it inside a config file. This is enough for almost anything.
 *  Even something like ServerPerks' player database is implemented with just
 *  a per-config-objects: since it just stores a particular data per player -
 *  it can do with simply creating one storage object per player.
 *      We, however, want to store an arbitrary JSON object inside our database
 *  that can contain any other kind of JSON data and not just player's
 *  numeric stats. With some additional work this again can also be done with
 *  per-config-objects. For example, if we want to store a JSON object inside
 *  another JSON object - we can create both of them separately, give them some
 *  different arbitrary names and then make the first one refer to the second
 *  one by it's given name.
 *      This way we can create a config object for each JSON array/object and
 *  then store it's data as an array of plain types (same as ServerPerks' one):
 *  null, boolean, number and string can be stored as is and other
 *  JSON arrays/objects can be stored by their references.
 *
 *  # Why are we using data objects instead of per-object-configs?
 *      Despite everything described above, Acedia's local databases DO NOT use
 *  per-object-configs to store their data, opting for data objects and
 *  Unreal Engine's save packages instead.
 *      Data objects can be created, loaded and saved inside Unreal Engine's
 *  binary packages with methods available from `GameInfo` class (look them up
 *  starting from `CreateDataObject()` or browsing through
 *  [wiki](https://wiki.beyondunreal.com/Legacy:DataObject)).
 *      They can essentially act the same as per-object-configs, but have
 *  an advantage of allowing us to cheaply (execution time-wise) create/delete
 *  as many objects as we need and then update their package on the disk instead
 *  of calling `SaveConfig()` or `ClearConfig()` on them one-by-one. This both
 *  simplifies and speed up a bunch of necessary operations.
 *      They also seem to behave more predictably.
 *
 *  # Some terminology
 *      Acedia's objects (representing JSON values) that are getting loaded
 *  into the `DBRecord`s are called "objects". We then refer to their
 *  representation within `DBRecord`s as "items". For example, this class has
 *  two methods for conversion between the two: `ConvertObjectToItem()` and
 *  `ConvertItemToObject()`.
 *      Most other methods are:
 *      1.  either methods that actually perform Acedia's database queries;
 *      2.  or methods that provide safe and easy access to the `DBRecord`'s
 *          items array (like making sure to remove unneeded data objects).
 *      All of the methods that perform database query rely on the
 *  `ConvertPointer()` method that take `JSONPointer` and convert it into
 *  internal pointer representation that immediately points at `DBRecord` that
 *  represents referred data (or contains it).
 */

//  Name of the database package this object belongs to
var private string  package;
//  Does this record store a JSON array (`true`) or object (`false`)?
var private bool    isJSONArray;

//  `ToCollection()` and `EraseSelf()` methods make recursive calls on their
//  "sub-objects" (referred via name). If database was somehow damaged - a loop
//  of references can occur, leading to infinite recursive calls (which results
//  in a crash). These variable help to avoid that by preventing re-entry into
//  these methods for the same object.
var private bool lockToCollection;
var private bool lockEraseSelf;

/**
 *      We pack as much information into the type of the record:
 *  whether it's 'null', 'boolean', 'number', 'string' or reference to another
 *  `DBRecord`.
 *      If it's 'boolean', then record value in the type
 *  (`DBAT_False` / `DBAT_True`), if `number` record whether it's `int` or
 *  `float`.
 *      While JSON does not distinguish between `int` and `float`, we still
 *  have to pick one of these type when transferring JSON numeric value into
 *  UnrealScript, plus it's easier for us to store it in one of these types.
*/
enum DBDataType
{
    DBAT_Null,
    DBAT_False,
    DBAT_True,
    DBAT_Int,
    DBAT_Float,
    DBAT_String,
    //  We actually store the name of another `DBRecord` that represents either
    //  sub-array or sub-object.
    DBAT_Reference,
    //  Some integer values we might want to store won't fit into `int`, so we
    //  store them as `BigIntData`
    DBAT_BigInt,
};

/**
 *  Store JSON array / object as a bunch of values.
 *  Which variable is used to store value depends on the type `t`.
 */
struct StorageItem
{
    //  Determines whether variable's value is stored in `i`, `f` or `s`.
    var DBDataType  t;
    //  For JSON objects only (`isJSONArray == false`), stores the key of
    //  corresponding value.
    var string      k;
    var int         i;
    var float       f;
    //  For both `DBRecord` references and JSON strings
    var string      s;
    //  For storing `BigInt`'s `BigIntData` - last `byte` stores `negative`
    //  value
    var array<byte> b;
};
var private config array<StorageItem> storage;

var private const int       LATIN_LETTERS_AMOUNT;
var private const int       LOWER_A_CODEPOINT, UPPER_A_CODEPOINT;
var private const string    JSONPOINTER_NEW_ARRAY_ELEMENT;

/**
 *      Since `DBRecord` represents JSON array or object, we can use
 *  JSON pointers to refer to any sub-value inside it.
 *      However, JSON pointers are not convenient or efficient enough for that,
 *  so internally we use this struct that provides quick and easy access to
 *  any sub-value.
 */
struct DBRecordPointer
{
    //  `DBRecord` inside which referred value is directly stored.
    //  `record == none` automatically makes `DBRecordPointer` invalid.
    var DBRecord    record;
    //      Index in `record`'s `storage` variable that corresponds to
    //  referred (simple) value.
    //      Negative `index` values mean `record` itself is pointed at.
    //  To point at JSON array / object represented by a `DBRecord`, always set
    //  `record` to that record and `index` to negative value (e.g. `-1`).
    var int         index;
};

private final function bool IsValidPointer(DBRecordPointer pointer)
{
    return pointer.record != none;
}

private final function bool IsPointerToRecord(DBRecordPointer pointer)
{
    return (pointer.record != none && pointer.index < 0);
}

//  Auxiliary method serving as a simple constructor.
private final function DBRecordPointer MakeRecordPointer(
    DBRecord        record,
    optional int    index)
{
    local DBRecordPointer pointer;
    pointer.record  = record;
    pointer.index   = index;
    return pointer;
}

private final function DBRecordPointer ConvertPointer(JSONPointer jsonPointer)
{
    if (jsonPointer == none) {
        return MakeRecordPointer(none);
    }
    return ConvertPointerPath(jsonPointer, 0, jsonPointer.GetLength());
}

private final function DBRecordPointer ConvertContainerPointer(
    JSONPointer jsonPointer)
{
    local DBRecordPointer pointer;
    if (jsonPointer == none) {
        return MakeRecordPointer(none);
    }
    pointer = ConvertPointerPath(jsonPointer, 0, jsonPointer.GetLength() - 1);
    if (!IsPointerToRecord(pointer)) {
        pointer.record = none;  //  invalidate pointer
    }
    return pointer;
}

//  Converts `JSONPointer` into internal `DBRecordPointer`.
//  Only uses sub-pointer: components from `startIndex` to `endIndex`.
private final function DBRecordPointer ConvertPointerPath(
    JSONPointer pointer,
    int         startIndex,
    int         endIndex)
{
    local int           index;
    local StorageItem   nextElement;
    local DBRecord      nextRecord;
    local string        nextComponent;
    if (pointer == none) {
        return MakeRecordPointer(none);
    }
    //  We are done!
    if (startIndex >= endIndex) {
        return MakeRecordPointer(self, -1);
    }
    //  Use first available to us component to find next sub-object
    if (isJSONArray)
    {
        index = pointer.GetNumericComponent(startIndex);
        if (index < 0 || index >= storage.length) {
            return MakeRecordPointer(none); // fail: out-of-bounds index
        }
    }
    else
    {
        nextComponent = __().text.IntoString(pointer.GetComponent(startIndex));
        index = FindItem(nextComponent);
    }
    if (index < 0) {
        return MakeRecordPointer(none); // fail: missing key for component
    }
    nextElement = storage[index];
    if (nextElement.t != DBAT_Reference)
    {
        if (startIndex + 1 >= endIndex) {
            return MakeRecordPointer(self, index);
        }
        //  fail: found value cannot contain sub-values,
        //  but pointer is not exhausted
        return MakeRecordPointer(none);
    }
    nextRecord = LoadRecordFor(nextElement.s, package);
    if (nextRecord == none) {
        return MakeRecordPointer(none); // fail: bad database
    }
    //  Success for the component, do recursive call
    startIndex += 1;
    return nextRecord.ConvertPointerPath(pointer, startIndex, endIndex);
}

public static final function Global __()
{
    return class'Global'.static.GetInstance();
}

public static final function ServerGlobal __server()
{
    return class'ServerGlobal'.static.GetInstance();
}

/**
 *  Method for creating a new `DBRecord` in a package named `dbPackageName`,
 *  picking an appropriate and unique name for it.
 *
 *  @param  dbPackageName   Name of the package new `DBRecord` must belong to.
 *  @return New `DBRecord`, created in specified package.
 *      `none` iff `dbPackageName == none`.
 */
public final static function DBRecord NewRecord(BaseText dbPackageName)
{
    if (dbPackageName == none) {
        return none;
    }
    return NewRecordFor(dbPackageName.ToString());
}

//  Auxiliary method that does what `NewRecord()` does, but for `string`
//  parameter. This makes it cheaper to call for internal use.
private final static function DBRecord NewRecordFor(string dbPackageName)
{
    local string    nextName;
    local DBRecord  recordCandidate;
    //  Try to generate new random name.
    //  This cycle can in theory be infinite. However in practice it will
    //  only run for one iteration (unless user messed with settings and
    //  set length of randomized names too low), since by default there is
    //  26^20 == 19,928,148,895,209,409,152,340,197,376 different
    //  random names and the chance of duplicate in infinitesimal.
    while (true)
    {
        nextName = GetRandomName();
        recordCandidate = LoadRecordFor(nextName, dbPackageName);
        if (recordCandidate != none) {
            continue;
        }
        recordCandidate = __server().unreal.GetGameType()
            .CreateDataObject(class'DBRecord', nextName, dbPackageName);
        recordCandidate.package = dbPackageName;
        return recordCandidate;
    }
    //  We cannot actually reach here
    return none;
}

public final static function DBRecord LoadRecord(
    BaseText recordName,
    BaseText dbPackageName)
{
    if (dbPackageName == none)  return none;
    if (recordName == none)     return none;

    return LoadRecordFor(   recordName.ToString(),
                            dbPackageName.ToString());
}

//  Auxiliary method that does what `LoadRecord()` does, but for `string`
//  parameter. This makes it cheaper to call for internal use.
private final static function DBRecord LoadRecordFor(
    string name,
    string package)
{
    return __server().unreal.GetGameType()
        .LoadDataObject(class'DBRecord', name, package);
}

private final static function string GetRandomName()
{
    local int       i;
    local int       length;
    local string    result;
    length = Max(1, class'LocalDBSettings'.default.randomNameLength);
    for (i = 0; i < length; i += 1) {
        result = result $ GetRandomLetter();
    }
    return result;
}

private final static function string GetRandomLetter()
{
    return Chr(Rand(default.LATIN_LETTERS_AMOUNT) + default.LOWER_A_CODEPOINT);
}

/**
 *  Loads Acedia's representation of JSON value stored at `pointer` inside
 *  the JSON object/array represented by the caller `DBRecord`.
 *
 *  @param  jsonPointer JSON pointer to the value to load
 *      (either simple, array or object one).
 *  @param  result      Loaded value will be recorded inside this variable.
 *      Set to `none` on failure.
 *  @param  makeMutable `false` if you want simple value to be recorded as
 *      immutable "boxes" (and `Text` for JSON strings) and `true` if you want
 *      them to be recorded as mutable "references"
 *      (`MutableText` for JSON strings).
 *  @return `true` if method successfully loaded JSON value and
 *      `false` otherwise. Failure can happen if passed `pointer` is invalid
 *      (either does not point at any existing value or is equal to `none`).
 */
public final function bool LoadObject(
    JSONPointer         jsonPointer,
    out AcediaObject    result,
    bool                makeMutable)
{
    local int               itemIndex;
    local DBRecord          container;
    local DBRecordPointer   pointer;
    if (jsonPointer == none)        return false;
    pointer = ConvertPointer(jsonPointer);
    if (!IsValidPointer(pointer))   return false;

    if (IsPointerToRecord(pointer)) {
        result = pointer.record.ToCollection(makeMutable);
    }
    else
    {
        itemIndex = pointer.index;
        container = pointer.record;
        result = ConvertItemToObject(container.GetItem(itemIndex), makeMutable);
    }
    return true;
}

/**
 *  Saves Acedia's representation of JSON value at a `pointer` inside
 *  the JSON object/array represented by the caller `DBRecord`.
 *
 *  @param  jsonPointer JSON pointer to location at which to save the value.
 *      Only the last segment of the path will be created (if missing), the rest
 *      must already exist and will not be automatically created.
 *      If another value is already recorded at `pointer` - it will be erased.
 *  @param  newItem     New value to save at `pointer` inside
 *      the caller `DBRecord`.
 *  @return `true` if method successfully saved new JSON value and
 *      `false` otherwise. Failure can happen if passed `pointer` is invalid
 *      (either missing some necessary segments or is equal to `none`).
 */
public final function bool SaveObject(
    JSONPointer     jsonPointer,
    AcediaObject    newItem)
{
    local int               index;
    local string            itemKey;
    local DBRecord          directContainer;
    local Collection        newItemAsCollection;
    local DBRecordPointer   pointer;
    if (jsonPointer == none) {
        return false;
    }
    if (jsonPointer.IsEmpty())
    {
        //  Special case - rewriting caller `DBRecord` itself
        newItemAsCollection = Collection(newItem);
        if (newItemAsCollection == none) {
            return false;
        }
        EmptySelf();
        isJSONArray = (newItemAsCollection.class == class'ArrayList');
        FromCollection(newItemAsCollection);
        return true;
    }
    pointer = ConvertContainerPointer(jsonPointer);
    if (!IsValidPointer(pointer)) {
        return false;
    }
    directContainer = pointer.record;
    itemKey = __().text.IntoString(jsonPointer.Pop(true));
    if (directContainer.isJSONArray)
    {
        index = jsonPointer.PopNumeric(true);
        if (index < 0 && itemKey == JSONPOINTER_NEW_ARRAY_ELEMENT) {
            index = directContainer.GetStorageLength();
        }
        if (index < 0) {
            return false;
        }
    }
    else {
        index = directContainer.FindItem(itemKey);
    }
    directContainer.SetItem(index, ConvertObjectToItem(newItem), itemKey);
    return true;
}

/**
 *  Removes Acedia's values stored in the database at `pointer` inside
 *  the JSON object/array represented by the caller `DBRecord`.
 *
 *  @param  jsonPointer JSON pointer to the value to remove
 *      (either simple, array or object one).
 *  @return `true` if method successfully removed JSON value and
 *      `false` otherwise. Failure can happen if passed `pointer` is invalid
 *      (either does not point at any existing value or equal to `none`).
 */
public final function bool RemoveObject(JSONPointer jsonPointer)
{
    local int               itemIndex;
    local string            itemKey;
    local DBRecord          directContainer;
    local DBRecordPointer   containerPointer;
    if (jsonPointer == none)                return false;
    containerPointer = ConvertContainerPointer(jsonPointer);
    if (!IsValidPointer(containerPointer))  return false;

    directContainer = containerPointer.record;
    if (directContainer.isJSONArray) {
        itemIndex = jsonPointer.PopNumeric(true);
    }
    else
    {
        itemKey = __().text.IntoString(jsonPointer.Pop(true));
        itemIndex = directContainer.FindItem(itemKey);
    }
    if (itemIndex >= 0)
    {
        directContainer.RemoveItem(itemIndex);
        return true;
    }
    return false;
}

/**
 *  Checks type of the JSON value stored at `pointer` inside
 *  the JSON object/array represented by the caller `DBRecord`.
 *
 *  @param  jsonPointer JSON pointer to the value for which type
 *      should be checked.
 *  @return `Database.DataType` that corresponds to the type of referred value.
 *      `JSON_Undefined` if value is missing or passed pointer is invalid.
 */
public final function LocalDatabaseInstance.DataType GetObjectType(
    JSONPointer jsonPointer)
{
    local DBRecord          directContainer;
    local DBRecordPointer   pointer;
    if (jsonPointer == none)        return JSON_Undefined;
    pointer = ConvertPointer(jsonPointer);
    if (!IsValidPointer(pointer))   return JSON_Undefined;

    if (IsPointerToRecord(pointer))
    {
        if (pointer.record.isJSONArray) {
            return JSON_Array;
        }
        else {
            return JSON_Object;
        }
    }
    directContainer = pointer.record;
    switch (directContainer.GetItem(pointer.index).t)
    {
    case DBAT_Null:
        return JSON_Null;
    case DBAT_False:
    case DBAT_True:
        return JSON_Boolean;
    case DBAT_Int:
    case DBAT_Float:
        return JSON_Number;
    case DBAT_String:
        return JSON_String;
    }
    //  We should not reach here
    return JSON_Undefined;
}

/**
 *  Returns "size" of the JSON value stored at `pointer` inside
 *  the JSON object/array represented by the caller `DBRecord`.
 *
 *  For JSON arrays and objects it's the amount of stored elements.
 *  For other values it's considered undefined and method returns negative
 *  value instead.
 *
 *  @param  jsonPointer JSON pointer to the value for which method should
 *      return size.
 *  @return If `pointer` refers to the JSON array or object - amount of it's
 *      elements is returned. Otherwise returns `-1`.
 */
public final function int GetObjectSize(JSONPointer jsonPointer)
{
    local DBRecordPointer pointer;
    if (jsonPointer == none) {
        return -1;
    }
    pointer = ConvertPointer(jsonPointer);
    if (IsPointerToRecord(pointer)) {
        return pointer.record.GetStorageLength();
    }
    return -1;
}

/**
 *  Returns keys of the JSON object stored at `pointer` inside
 *  the JSON object/array represented by the caller `DBRecord`.
 *
 *  @param  jsonPointer JSON pointer to the value for which method should
 *      return size.
 *  @return If `pointer` refers to the JSON object - all available keys.
 *      `none` otherwise (including case of JSON arrays).
 */
public final function ArrayList GetObjectKeys(JSONPointer jsonPointer)
{
    local int                   i;
    local ArrayList             resultKeys;
    local array<StorageItem>    items;
    local DBRecord              referredObject;
    local DBRecordPointer       pointer;
    if (jsonPointer == none)            return none;
    pointer = ConvertPointer(jsonPointer);
    if (!IsValidPointer(pointer))       return none;
    if (!IsPointerToRecord(pointer))    return none;
    referredObject = pointer.record;
    if (referredObject.isJSONArray)     return none;

    resultKeys  = __().collections.EmptyArrayList();
    items       = referredObject.storage;
    for (i = 0; i < items.length; i += 1) {
        resultKeys.AddString(items[i].k);
    }
    return resultKeys;
}

/**
 *  Increments JSON value at a `pointer` inside the JSON object/array
 *  represented by the caller `DBRecord` by a given Acedia's value.
 *
 *  For "increment" operation description refer to `Database.IncrementData()`.
 *
 *  @param  jsonPointer JSON pointer to location at which to save the value.
 *      Only the last segment of the path might be created (if missing),
 *      the rest must already exist and will not be automatically created.
 *      If another value is already recorded at `pointer` - it will be erased.
 *  @param  object      Value by which to increment another value, stored at
 *      `pointer` inside the caller `DBRecord`.
 *  @return Returns query result that is appropriate for "increment" operation,
 *      according to `Database.IncrementData()` specification.
 */
public final function Database.DBQueryResult IncrementObject(
    JSONPointer     jsonPointer,
    AcediaObject    object)
{
    local int               index;
    local string            itemKey;
    local DBRecord          directContainer;
    local HashTable         objectAsHashTable;
    local DBRecordPointer   pointer;
    if (jsonPointer == none) {
        return DBR_InvalidPointer;
    }
    if (jsonPointer.IsEmpty())
    {
        //  Special case - incrementing caller `DBRecord` itself
        objectAsHashTable = HashTable(object);
        if (objectAsHashTable == none) {
            return DBR_InvalidData;
        }
        FromCollection(objectAsHashTable);
        return DBR_Success;
    }
    //      All the work will be done by the separate `IncrementItem()` method;
    //      But it is applied to the `DBRecord` that contains referred item,
    //  so we have to find it.
    pointer = ConvertContainerPointer(jsonPointer);
    if (!IsValidPointer(pointer)) {
        return DBR_InvalidPointer;
    }
    directContainer = pointer.record;
    itemKey = __().text.IntoString(jsonPointer.Pop(true));
    if (directContainer.isJSONArray)
    {
        index = jsonPointer.PopNumeric(true);
        if (index < 0 && itemKey == JSONPOINTER_NEW_ARRAY_ELEMENT) {
            index = directContainer.GetStorageLength();
        }
        if (index < 0) {
            return DBR_InvalidPointer;
        }
    }
    else {
        index = directContainer.FindItem(itemKey);
    }
    if (directContainer.IncrementItem(index, object, itemKey)) {
        return DBR_Success;
    }
    return DBR_InvalidData;
}

private final function StorageItem GetItem(int index)
{
    local StorageItem emptyResult;
    if (index < 0)                  return emptyResult;
    if (index >= storage.length)    return emptyResult;

    return storage[index];
}

//      Negative `index` means that value will need to be appended to the end
//  of the `storage`.
//      Optionally lets you specify item's key (via `itemName`) for
//  JSON objects.
private final function SetItem(
    int             index,
    StorageItem     newItem,
    optional string itemName)
{
    local DBRecord      oldRecord;
    local StorageItem   oldItem;
    if (index < 0) {
        index = storage.length;
    }
    if (index < storage.length)
    {
        //  Clean up old value
        oldItem = storage[index];
        if (oldItem.t == DBAT_Reference)
        {
            oldRecord = LoadRecordFor(oldItem.s, package);
            if (oldRecord != none) {
                oldRecord.EmptySelf();
            }
            __server().unreal.GetGameType()
                .DeleteDataObject(class'DBRecord', oldItem.s, package);
        }
    }
    storage[index]      = newItem;
    storage[index].k    = itemName;
}

//      Auxiliary getter that helps us avoid referring to `storage` array
//  directly from `DBRecord` reference, which would cause unnecessary copying of
//  it's data.
private final function int GetStorageLength()
{
    return storage.length;
}

//      Auxiliary method for removing items from `storage` array that helps us
//  avoid referring to it directly from `DBRecord` reference, which would cause
//  unnecessary copying of it's data.
private final function RemoveItem(int index)
{
    local DBRecord      oldRecord;
    local StorageItem   oldItem;
    if (index >= storage.length)    return;
    if (index < 0)                  return;

    //  Clean up old value
    oldItem = storage[index];
    if (oldItem.t == DBAT_Reference)
    {
        oldRecord = LoadRecordFor(oldItem.s, package);
        if (oldRecord != none) {
            oldRecord.EmptySelf();
        }
        __server().unreal.GetGameType()
            .DeleteDataObject(class'DBRecord', oldItem.s, package);
    }
    storage.Remove(index, 1);
}

private final function int FindItem(string itemName)
{
    local int index;
    if (isJSONArray) {
        return -1;
    }
    for (index = 0; index < storage.length; index += 1)
    {
        if (storage[index].k == itemName) {
            return index;
        }
    }
    return -1;
}

//      Negative `index` means that `object` value needs to be appended to the
//  end of the `storage`, instead of incrementing an existing value.
//      Returns `true` if changes were successfully made and `false` otherwise.
private final function bool IncrementItem(
    int             index,
    AcediaObject    object,
    optional string itemName)
{
    local StorageItem itemToIncrement;
    if (index < 0)
    {
        index = storage.length;
        //  `itemToIncrement` is blank at this point and has type `DBAT_Null`,
        //  which will simply be rewritten by `IncrementItemByObject()`
        //  call later
        storage[index] = itemToIncrement;
    }
    else if (index < storage.length) {
        itemToIncrement = storage[index];
    }
    if (IncrementItemByObject(itemToIncrement, object))
    {
        //  Increment object cannot overwrite existing `DBRecord` with
        //  other value, so it's safe to skip cleaning check
        storage[index]      = itemToIncrement;
        storage[index].k    = itemName;
        return true;
    }
    return false;
}

/**
 *  Extracts JSON object or array data from caller `DBRecord` as either
 *  `HashTable` (for JSON objects) or `ArrayList` (for JSON arrays).
 *
 *  Type conversion rules in immutable case:
 *      1. 'null'       -> `none`;
 *      2. 'boolean'    -> `BoolBox`;
 *      3. 'number'     -> either `IntBox` or `FloatBox`, depending on
 *          what seems to fit better;
 *      4. 'string'     -> `Text`;
 *      5. 'array'      -> `ArrayList`;
 *      6. 'object'     -> `HashTable`.
 *
 *  Type conversion rules in mutable case:
 *      1. 'null'       -> `none`;
 *      2. 'boolean'    -> `BoolRef`;
 *      3. 'number'     -> either `IntRef` or `FloatRef`, depending on
 *          what seems to fit better;
 *      4. 'string'     -> `MutableText`;
 *      5. 'array'      -> `ArrayList`;
 *      6. 'object'     -> `HashTable`.
 *
 *  @param  makeMutable `false` if you want this method to produce
 *      immutable types and `true` otherwise.
 *  @return `HashTable` if caller `DBRecord` represents a JSON object
 *      and `ArrayList` if it represents JSON array.
 *      Returned collection must have all of it's keys deallocated before being
 *      discarded.
 *      `none` iff caller `DBRecord` was not initialized as either.
 */
public final function Collection ToCollection(bool makeMutable)
{
    local Collection result;
    if (lockToCollection) {
        return none;
    }
    lockToCollection = true;
    if (isJSONArray) {
        result = ToArrayList(makeMutable);
    }
    else {
        result = ToHashTable(makeMutable);
    }
    lockToCollection = false;
    return result;
}

//  Does not do any validation check, assumes caller `DBRecord`
//  represents an array.
private final function Collection ToArrayList(bool makeMutable)
{
    local int           i;
    local ArrayList     result;
    local AcediaObject  nextObject;
    result = __().collections.EmptyArrayList();
    for (i = 0; i < storage.length; i += 1)
    {
        nextObject = ConvertItemToObject(storage[i], makeMutable);
        result.AddItem(nextObject);
        __().memory.Free(nextObject);
    }
    return result;
}

//  Does not do any validation check, assumes caller `DBRecord`
//  represents an object.
private final function Collection ToHashTable(bool makeMutable)
{
    local int           i;
    local HashTable     result;
    local Text          nextKey;
    local AcediaObject  nextObject;
    result = __().collections.EmptyHashTable();
    for (i = 0; i < storage.length; i += 1)
    {
        nextKey = __().text.FromString(storage[i].k);
        nextObject = ConvertItemToObject(storage[i], makeMutable);
        result.SetItem(nextKey, nextObject);
        __().memory.Free(nextKey);
        __().memory.Free(nextObject);
    }
    return result;
}

/**
 *  Completely erases all data inside a caller `DBRecord`, recursively deleting
 *  all referred `DBRecord`.
 */
public final function EmptySelf()
{
    local int       i;
    local GameInfo  game;
    local DBRecord  subRecord;
    if (lockEraseSelf) {
        return;
    }
    lockEraseSelf = true;
    game = __server().unreal.GetGameType();
    for (i = 0; i < storage.length; i += 1)
    {
        if (storage[i].t != DBAT_Reference) continue;
        subRecord = LoadRecordFor(storage[i].s, package);
        if (subRecord == none)              continue;

        subRecord.EmptySelf();
        game.DeleteDataObject(class'DBRecord', string(subRecord.name), package);
    }
    storage.length = 0;
    lockEraseSelf = false;
}

/**
 *  Takes all available values from `source` and records them into caller
 *  `DBRecord`. Does not erase untouched old values, but will overwrite them
 *  in case of the conflict.
 *
 *      Can only convert items in passed collection that return `true` for
 *  `__().json.IsCompatible()` check. Any other values will be treated as `none`.
 *
 *  Only works as long as caller `DBRecord` has the same container type as
 *  `source`. `isJSONArray` iff `source.class == class'ArrayList` and
 *  `!isJSONArray` iff `source.class == class'HashTable`.
 *
 *  Values that cannot be converted into JSON will be replaced with `none`.
 *
 *  @param  source  `Collection` to write into the caller `DBRecord`.
 */
public final function FromCollection(Collection source)
{
    local ArrayList asArrayList;
    local HashTable asHashTable;
    asArrayList = ArrayList(source);
    asHashTable = HashTable(source);
    if (asArrayList != none && isJSONArray) {
        FromArrayList(asArrayList);
    }
    if (asHashTable != none && !isJSONArray) {
        FromHashTable(asHashTable);
    }
}

//  Does not do any validation check.
private final function FromArrayList(ArrayList source)
{
    local int           i, length;
    local AcediaObject  nextObject;
    length = source.GetLength();
    for (i = 0; i < length; i += 1)
    {
        nextObject = source.GetItem(i);
        storage[storage.length] = ConvertObjectToItem(nextObject);
        __().memory.Free(nextObject);
    }
}

//  Does not do any validation check.
private final function FromHashTable(HashTable source)
{
    local int                   i, originalStorageLength;
    local CollectionIterator    iter;
    local string                nextKey;
    local bool                  isNewKey;
    local AcediaObject          nextObject;
    originalStorageLength = storage.length;
    for (iter = source.Iterate(); !iter.HasFinished(); iter.Next())
    {
        if (iter.GetKey() == none) {
            continue;
        }
        nextKey = __().text.IntoString(BaseText(iter.GetKey()));
        isNewKey = true;
        for (i = 0; i < originalStorageLength; i += 1)
        {
            if (storage[i].k == nextKey)
            {
                isNewKey = false;
                break;
            }
        }
        if (isNewKey)
        {
            nextObject = iter.Get();
            SetItem(storage.length, ConvertObjectToItem(nextObject), nextKey);
            __().memory.Free(nextObject);
        }
    }
    iter.FreeSelf();
}

//  Converts `AcediaObject` into it's internal representation.
private final function StorageItem ConvertObjectToItem(AcediaObject data)
{
    local StorageItem   result;
    local DBRecord      newDBRecord;
    if (Text(data) != none)
    {
        result.t = DBAT_String;
        result.s = Text(data).ToString();
    }
    else if(Collection(data) != none)
    {
        result.t = DBAT_Reference;
        newDBRecord = NewRecordFor(package);
        newDBRecord.isJSONArray = (data.class == class'ArrayList');
        newDBRecord.FromCollection(Collection(data));
        result.s = string(newDBRecord.name);
    }
    else if (FloatBox(data) != none || FloatRef(data) != none)
    {
        result.t = DBAT_Float;
        if (FloatBox(data) != none) {
            result.f = FloatBox(data).Get();
        }
        else {
            result.f = FloatRef(data).Get();
        }
    }
    else if (IntBox(data) != none || IntRef(data) != none)
    {
        result.t = DBAT_Int;
        if (IntBox(data) != none) {
            result.i = IntBox(data).Get();
        }
        else {
            result.i = IntRef(data).Get();
        }
    }
    else if (BoolBox(data) != none || BoolRef(data) != none)
    {
        result.t = DBAT_False;
        if (BoolBox(data) != none && BoolBox(data).Get()) {
            result.t = DBAT_True;
        }
        if (BoolRef(data) != none && BoolRef(data).Get()) {
            result.t = DBAT_True;
        }
    }
    return result;
}

//  Converts internal data representation into `AcediaObject`.
private final function AcediaObject ConvertItemToObject(
    StorageItem item,
    bool        makeMutable)
{
    local DBRecord subRecord;
    switch (item.t) {
    case DBAT_False:
    case DBAT_True:
        if (makeMutable) {
            return __().ref.bool(item.t == DBAT_True);
        }
        else {
            return __().box.bool(item.t == DBAT_True);
        }
    case DBAT_Int:
        if (makeMutable) {
            return __().ref.int(item.i);
        }
        else {
            return __().box.int(item.i);
        }
    case DBAT_Float:
        if (makeMutable) {
            return __().ref.float(item.f);
        }
        else {
            return __().box.float(item.f);
        }
    case DBAT_String:
        if (makeMutable) {
            return __().text.FromStringM(item.s);
        }
        else {
            return __().text.FromString(item.s);
        }
    case DBAT_Reference:
        subRecord = LoadRecordFor(item.s, package);
        if (subRecord != none) {
            return subRecord.ToCollection(makeMutable);
        }
    default:
    }
    return none;
}

//      "Increments" internal data representation by value inside given
//  `AcediaObject`.
//      See `IncrementObject()` method for details.
private final function bool IncrementItemByObject(
    out StorageItem item,
    AcediaObject    object)
{
    local DBRecord itemRecord;
    if (object == none) {
        return (item.t == DBAT_Null);
    }
    if (item.t == DBAT_Null)
    {
        item = ConvertObjectToItem(object);
        return true;
    }
    else if (item.t == DBAT_String && Text(object) != none)
    {
        item.s $= Text(object).ToString();
        return true;
    }
    else if(item.t == DBAT_Reference && Collection(object) != none)
    {
        itemRecord = LoadRecordFor(item.s, package);
        if (itemRecord == none)
        {
            itemRecord = NewRecordFor(package); // DB was broken somehow
            item.s = string(itemRecord.name);
            itemRecord.isJSONArray = (object.class == class'ArrayList');
        }
        if (    (itemRecord.isJSONArray && object.class != class'ArrayList')
            ||  (   !itemRecord.isJSONArray
                &&  object.class != class'HashTable'))
        {
            return false;
        }
        itemRecord.FromCollection(Collection(object));
        return true;
    }
    else if (   (item.t == DBAT_False || item.t == DBAT_True)
            &&  (BoolBox(object) != none || BoolRef(object) != none))
    {
        if (BoolBox(object) != none && BoolBox(object).Get()) {
            item.t = DBAT_True;
        }
        if (BoolRef(object) != none && BoolRef(object).Get()) {
            item.t = DBAT_True;
        }
        return true;
    }
    return IncrementNumericItemByObject(item, object);
}

private final function bool IncrementNumericItemByObject(
    out StorageItem item,
    AcediaObject    object)
{
    local int   storedValueAsInteger, incrementAsInteger;
    local float storedValueAsFloat, incrementAsFloat;
    if (item.t != DBAT_Float && item.t != DBAT_Int) {
        return false;
    }
    if (!ReadNumericObjectInto(object, incrementAsInteger, incrementAsFloat)) {
        return false;
    }
    if (item.t == DBAT_Float)
    {
        storedValueAsInteger = int(item.f);
        storedValueAsFloat = item.f;
    }
    else
    {
        storedValueAsInteger = item.i;
        storedValueAsFloat = float(item.i);
    }
    //  Later we want to implement arbitrary precision arithmetic for storage,
    //  but for now let's just assume that if either value is a float -
    //  then user wants a float precision.
    if (    item.t == DBAT_Float || FloatBox(object) != none
        ||  FloatRef(object) != none)
    {
        item.t = DBAT_Float;
        item.f = storedValueAsFloat + incrementAsFloat;
        item.i = 0;
    }
    else
    {
        item.t = DBAT_Int;
        item.i = storedValueAsInteger + incrementAsInteger;
        item.f = 0;
    }
    return true;
}

private final function bool ReadNumericObjectInto(
    AcediaObject    object,
    out int         valueAsInt,
    out float       valueAsFloat)
{
    if (IntBox(object) != none || IntRef(object) != none)
    {
        if (IntBox(object) != none) {
            valueAsInt = IntBox(object).Get();
        }
        else {
            valueAsInt = IntRef(object).Get();
        }
        valueAsFloat = float(valueAsInt);
        return true;
    }
    if (FloatBox(object) != none || FloatRef(object) != none)
    {
        if (FloatBox(object) != none) {
            valueAsFloat = FloatBox(object).Get();
        }
        else {
            valueAsFloat = FloatRef(object).Get();
        }
        valueAsInt = int(valueAsFloat);
        return true;
    }
    return false;
}

//  Add storing bytes
defaultproperties
{
    LATIN_LETTERS_AMOUNT            = 26
    LOWER_A_CODEPOINT               = 97
    UPPER_A_CODEPOINT               = 65
    //  JSON Pointers allow using "-" as an indicator that element must be
    //  added at the end of the array
    JSONPOINTER_NEW_ARRAY_ELEMENT   = "-"
}