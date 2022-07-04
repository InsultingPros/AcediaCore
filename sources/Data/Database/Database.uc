/**
 *      Interface database class that provides all Acedia's functionality for
 *  querying databases. For most of the cases, this is a class you are expected
 *  to work with and providing appropriate implementation is Acedia's `DBAPI`
 *  responsibility. Choice of the implementation is done based on user's
 *  config files.
 *      All of the methods are asynchronous - they do not return requested
 *  values immediately and instead require user to provide a handler function
 *  that will be called once operation is completed.
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
class Database extends AcediaObject
    abstract;

/**
 *      Describes possible data types that can be stored in Acedia's databases.
 *      Lists consists of all possible JSON values types (with self-explanatory
 *  names) plus technical `JSON_Undefined` type that is used to indicate that
 *  a particular value does not exist.
 */
enum DataType
{
    JSON_Undefined,
    JSON_Null,
    JSON_Boolean,
    JSON_Number,
    JSON_String,
    JSON_Array,
    JSON_Object
};

/**
 *      Possible outcomes of any query: success (only `DBR_Success`) or
 *  some kind of failure (any other value).
 *      This type is common for all queries, however reasons as to why
 *  a particular result value was obtained can differ from one to another.
 */
enum DBQueryResult
{
    //  Means query has succeeded;
    DBR_Success,
    //  Query was provided with an invalid JSON pointer
    //  (`none` or somehow otherwise unfit to be used with a particular query);
    DBR_InvalidPointer,
    //  Operation could not finish because database is damaged and unusable;
    DBR_InvalidDatabase,
    //  Means that data (provided for the query) is somehow invalid.
    DBR_InvalidData
};

/**
 *  Schedules reading data, located at the given `pointer` in
 *  the caller database.
 *
 *  @param  pointerToData   JSON pointer to the value in database to read.
 *      `none` is always treated as an invalid JSON pointer.
 *  @param  makeMutable     Setting this to `false` (default) will force method
 *      to load data as immutable Acedia's types and `true` will make it load
 *      data as mutable types. This setting does not affect `Collection`s into
 *      which JSON arrays and objects are converted - they are always mutable.
 *  @return Task object that corresponds to this `ReadData()` call.
 *      *   Guaranteed to be not `none`;
 *      *   Use it to connect a handler for when reading task is complete:
 *              `ReadData(...).connect = handler`,
 *              where `handler` must have the following signature:
 *              `connect(DBQueryResult result, AcediaObject data)`;
 *      *   Ownership of `data` object returned in the `connect()` is considered
 *          to be transferred to whoever handled result of this query.
 *          It must be deallocated once no longer needed.
 *      *   Possible `DBQueryResult` types are `DBR_Success`,
 *          `DBR_InvalidPointer` and `DBR_InvalidDatabase`;
 *      *   `data` is guaranteed to be `none` if `result != DBR_Success`;
 *      *   `DBR_InvalidPointer` can be produced if either `pointer == none` or
 *          it does not point at any existing value inside the caller database.
 */
public function DBReadTask ReadData(
    JSONPointer     pointer,
    optional bool   makeMutable)
{
    return none;
}

/**
 *  Schedules writing `data` at the location inside the caller database,
 *  given by the `pointer`.
 *
 *  Only `HashTable` (that represents JSON object) can be recorded as
 *  a database's root value (referred to by an empty JSON pointer "").
 *
 *  @param  pointer JSON pointer to the location in the database, where `data`
 *      should be written (as a JSON value).
 *      This JSON pointer can make use of "-" index for JSON arrays that allows
 *      appending data at their end.
 *      `none` is always treated as an invalid JSON pointer.
 *  @param  data    Data that needs to be written at the specified location
 *      inside the database. For method to succeed this object needs to have
 *      JSON-compatible type (see `_.json.IsCompatible()` for more details).
 *  @return Task object that corresponds to this `WriteData()` call.
 *      *   Guaranteed to be not `none`;
 *      *   Use it to connect a handler for when writing task is complete:
 *          `WriteData(...).connect = handler`,
 *          where `handler` must have the following signature:
 *          `connect(DBQueryResult result)`;
 *      *   Possible `DBQueryResult` types are `DBR_Success`,
 *          `DBR_InvalidPointer`, `DBR_InvalidDatabase` and `DBR_InvalidData`;
 *      *   Data is actually written inside the database iff
 *          `result == DBR_Success`;
 *      *   `result == DBR_InvalidData` iff either given `data`'s type is not
 *          JSON-compatible or a non-`HashTable` was attempted to be
 *          recorded as caller database's root value;
 *      *   `DBR_InvalidPointer` can be produced if either `pointer == none` or
 *          container of the value `pointer` points at does not exist.
 *          Example: writing data at "/sub-object/valueA" will always fail if
 *          "sub-object" does not exist.
 */
public function DBWriteTask WriteData(JSONPointer pointer, AcediaObject data)
{
    return none;
}

/**
 *  Schedules removing data at the location inside the caller database,
 *  given by the `pointer`.
 *
 *  "Removing" root object results in simply erasing all of it's stored data.
 *
 *  @param  pointer JSON pointer to the location of the data to remove from
 *      database. `none` is always treated as an invalid JSON pointer.
 *  @return Task object that corresponds to this `RemoveData()` call.
 *      *   Guaranteed to be not `none`;
 *      *   Use it to connect a handler for when writing task is complete:
 *          `RemoveData(...).connect = handler`,
 *          where `handler` must have the following signature:
 *          `connect(DBQueryResult result)`.
 *      *   Possible `DBQueryResult` types are `DBR_Success`,
 *          `DBR_InvalidPointer` and `DBR_InvalidDatabase`;
 *      *   Data is actually removed from the database iff
 *          `result == DBR_Success`.
 *      *   `DBR_InvalidPointer` can be produced if either `pointer == none` or
 *          it does not point at any existing value inside the caller database.
 */
public function DBRemoveTask RemoveData(JSONPointer pointer)
{
    return none;
}

/**
 *  Schedules checking type of data at the location inside the caller database,
 *  given by the `pointer`.
 *
 *  @param  pointer JSON pointer to the location of the data for which type
 *      needs to be checked.
 *      `none` is always treated as an invalid JSON pointer.
 *  @return Task object that corresponds to this `CheckDataType()` call.
 *      *   Guaranteed to be not `none`;
 *      *   Use it to connect a handler for when reading task is complete:
 *          `CheckDataType(...).connect = handler`,
 *          where `handler` must have the following signature:
 *          `connect(DBQueryResult result, Database.DataType type)`;
 *      *   Possible `DBQueryResult` types are `DBR_Success`,
 *          `DBR_InvalidPointer` and `DBR_InvalidDatabase`;
 *      *   This task can only fail if either caller database is broken
 *          (task will produce `DBR_InvalidDatabase` result) or given `pointer` 
 *          is `none` (task will produce `DBR_InvalidPointer` result).
 *          Otherwise the result will be `DBR_Success`.
 *      *   Data is actually removed from the database iff
 *          `result == DBR_Success`.
 */
public function DBCheckTask CheckDataType(JSONPointer pointer)
{
    return none;
}

/**
 *  Schedules obtaining "size": amount of elements stored inside
 *  either JSON object or JSON array, which location inside the caller database
 *  is given by provided `pointer`.
 *
 *  For every JSON value that is neither object or array size is
 *  defined as `-1`.
 *
 *  @param  pointer JSON pointer to the location of the JSON object or array
 *      for which size needs to be obtained.
 *      `none` is always treated as an invalid JSON pointer.
 *  @return Task object that corresponds to this `GetDataSize()` call.
 *      *   Guaranteed to be not `none`;
 *      *   Use it to connect a handler for when reading task is complete:
 *          `GetDataSize(...).connect = handler`,
 *          where `handler` must have the following signature:
 *          `connect(DBQueryResult result, int size)`.
 *      *   Possible `DBQueryResult` types are `DBR_Success`,
 *          `DBR_InvalidPointer` and `DBR_InvalidDatabase`;
 *      *   Returned `size` value is actually a size of referred
 *          JSON object/array inside the database iff `result == DBR_Success`;
 *      *   `DBR_InvalidPointer` can be produced if either `pointer == none` or
 *          it does not point at a JSON object or array inside the
 *          caller database.
 */
public function DBSizeTask GetDataSize(JSONPointer pointer)
{
    return none;
}

/**
 *  Schedules obtaining set of keys inside the JSON object, which location in
 *  the caller database is given by provided `pointer`.
 *
 *  Only JSON objects have (and will return) keys (names of their sub-values).
 *
 *  @param  pointer JSON pointer to the location of the JSON object for which
 *      keys need to be obtained.
 *      `none` is always treated as an invalid JSON pointer.
 *  @return Task object that corresponds to this `GetDataKeys()` call.
 *      *   Guaranteed to be not `none`;
 *      *   Use it to connect a handler for when reading task is complete:
 *          `GetDataKeys(...).connect = handler`,
 *          where `handler` must have the following signature:
 *          `connect(DBQueryResult result, ArrayList keys)`.
 *      *   Ownership of `keys` array returned in the `connect()` is considered
 *          to be transferred to whoever handled result of this query.
 *          It must be deallocated once no longer needed.
 *      *   Possible `DBQueryResult` types are `DBR_Success`,
 *          `DBR_InvalidPointer`, `DBR_InvalidData` and `DBR_InvalidDatabase`;
 *      *   Returned `keys` will be non-`none` and contain keys of the referred
 *          JSON object inside the database iff `result == DBR_Success`;
 *      *   `DBR_InvalidPointer` can be produced iff `pointer == none`;
 *      *   `result == DBR_InvalidData` iff `pointer != none`, but does not
 *          point at a JSON object inside caller database
 *          (value can either not exist at all or have some other type).
 */
public function DBKeysTask GetDataKeys(JSONPointer pointer)
{
    return none;
}

/**
 *  Schedules "incrementing" data, located at the given `pointer` in
 *  the caller database.
 *
 *  "Incrementing" is an operation that is safe from the point of view of
 *  simultaneous access. What "incrementing" actually does depends on
 *  the passed JSON value (`increment` parameter):
 *      (0.  Unless `pointer` points at the JSON null value - then "increment"
 *          acts as a `WriteData()` method regardless of `increment`'s value);
 *      1.  JSON null: it never modifies existing value and reports an error if
 *          existing value was not itself JSON null;
 *      2.  JSON bool: if combines with stored JSON bool value -
 *          performs logical "or" operation. Otherwise fails;
 *      3. JSON number: if combines with stored JSON numeric value -
 *          adds values together. Otherwise fails.
 *      4. JSON string: if combines with stored JSON string value -
 *          concatenates itself at the end. Otherwise fails.
 *      5. JSON array: if combines with stored JSON array value -
 *          concatenates itself at the end. Otherwise fails.
 *      6. JSON object: if combines with stored JSON object value -
 *          `increment` adds it's own values with new keys into the stored
 *          JSON object. Does not override old values.
 *          Fails when combined with any other type.
 *
 *  @param  pointer     JSON pointer to the location in the database, where
 *      data should be incremented (by `increment`).
 *      `none` is always treated as an invalid JSON pointer.
 *      This JSON pointer can make use of "-" index for JSON arrays that allows
 *      to add `none` value at the end of that array and then "increment" it
 *      with `increment` parameter.
 *  @param  increment   JSON-compatible value to be used as an increment for
 *      the data at the specified location inside the database.
 *  @return Task object that corresponds to this `IncrementData()` call.
 *      *   Guaranteed to be not `none`;
 *      *   Use it to connect a handler for when reading task is complete:
 *          `IncrementData(...).connect = handler`,
 *          where `handler` must have the following signature:
 *          `connect(DBQueryResult result)`.
 *      *   Possible `DBQueryResult` types are `DBR_Success`,
 *          `DBR_InvalidPointer`, `DBR_InvalidData` and `DBR_InvalidDatabase`;
 *      *   Data is actually incremented iff `result == DBR_Success`;
 *      *   `DBR_InvalidPointer` can be produced if either `pointer == none` or
 *          container of the value `pointer` points at does not exist.
 *          Example: incrementing data at "/sub-object/valueA" will always fail
 *          if "sub-object" does not exist.
 *      *   `result == DBR_InvalidData` iff `pointer != none`, but does not
 *          point at a JSON value compatible (in the sense of "increment"
 *          operation) with `increment` parameter.
 */
public function DBIncrementTask IncrementData(
    JSONPointer     pointer,
    AcediaObject    increment)
{
    return none;
}

defaultproperties
{
}