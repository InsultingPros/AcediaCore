/**
 *      Acedia makes extensive use of `perobjectconfig` for storing information
 *  in ini config files. Their data is usually stored in ini config files as:
 *  "[<config_object_name> <data_class_name>]".
 *  Making a child class for `AcediaConfig` defines "<data_class_name>" and
 *  contents of appropriate section. Then any such class can have multiple
 *  records with different "<config_object_name>" values. The only requirement
 *  is that "<config_object_name>" must be considered *valid* by
 *  `BaseText.IsValidName()` standards.
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
class AcediaConfig extends AcediaObject
    dependson(HashTable)
    abstract;

/**
 *  # `AcediaConfig`
 *
 *      This class deals with several issues related to use of such objects,
 *  stemming from the lack of documentation:
 *
 *  1. Not all `Object` names are a usable.
 *      [Beyond Unreal wiki](
 *      https://wiki.beyondunreal.com/Legacy:PerObjectConfig)
 *      lists a couple of limitations: whitespace and ']' character.
 *      However there are more, including '.'. 
 *          We limit available character set to ASCII latin letters, digits and
 *      the dot ('.') / underscore ('_'). Dot is a forbidden character, but it
 *      is often used in class names and, therefore, was added via workaround:
 *      it is automatically converted into colon ':' character to allow its
 *      storage inside ini config files. It also will not lead to the name
 *      conflicts, since colon is a forbidden character for `AcediaConfig`.
 *          Unreal Engine also doesn't handle long object names very well:
 *      if it considers "[<config_object_name> <data_class_name>]" too long, it
 *      might cut some of the trailing letters of what is between brackets '['
 *      and ']' basically mangling class' name. Since such config header seems
 *      to be able to contain at least 100 character (at least in our tests),
 *      we deal with that issue by limiting name to 50 characters at most.
 *      Depending on the class' name it might still cause problems, so don't
 *      make them too long.
 *  2. Behavior of loading `perobjectconfig`-objects a second time is wonky and
 *      is fixed by `AcediaConfig`: it provides concrete behavior guarantees
 *      for all of its config object-managing methods.
 */

//      All config objects of a particular class only get loaded once
//  per session (unless new one is created) and then accessed through this
//  collection.
//      This array stores `AcediaConfig` values with `Text` keys in
//  a case-insensitive way (by converting keys into lower case).
//  In case it has a `none` value stored under some key - it means that value
//  was detected in config, but not yet loaded.
//      Only its default value is ever used.
var private HashTable existingConfigs;

//  Stores name of the config where settings are to be stored.
//  Must correspond to value in `config(...)` modifier in class definition.
var protected const string configName;

//      Set this to `true` if you implement `ToData()` / `FromData()` pair of
//  methods.
//      This will tell Acedia that your config can be converted into
//  JSON-compatible types.
var public const bool supportsDataConversion;

/**
 *      These methods must be overloaded to store and load all the config
 *  variables inside an `HashTable` collection. How exactly to store
 *  them is up to each config class to decide, as long as it allows conversion
 *  into JSON (see `JSONAPI.IsCompatible()` for details).
 *      Note that `HashTable` reference `FromData()` receives is
 *  not necessarily the same one your `ToData()` method returns - any particular
 *  value boxes can be replaced with value references and vice versa.
 *      NOTE: DO NOT use `P()`, `C()`, `F()` or `T()` methods for keys or
 *  values in collections you return. All keys and values will be automatically
 *  deallocated when necessary, so these methods for creating `Text` values are
 *  not suitable.
*/
protected function HashTable ToData() { return none; }
protected function FromData(HashTable source) {}

/**
 *  This method must be overloaded to setup default values for all config
 *  variables. You should use it instead of the `defaultproperties` block.
 */
protected function DefaultIt() {}

/**
 *      This reads all of the `AcediaConfig`'s settings objects into internal
 *  storage. Must be called before any other methods. Actual loading might be
 *  postponed until a particular config is needed.
 */
public static function Initialize()
{
    local int           i;
    local Text          nextName, lowerName;
    local array<string> names;
    if (default.existingConfigs != none) {
        return;
    }
    default.existingConfigs = __().collections.EmptyHashTable();
    names = GetPerObjectNames(  default.configName, string(default.class.name),
                                MaxInt);
    for (i = 0; i < names.length; i += 1)
    {
        if (names[i] == "") {
            continue;
        }
        nextName = __().text.FromString(NameToActualVersion(names[i]));
        if (nextName.IsValidName())
        {
            lowerName = nextName.LowerCopy();
            default.existingConfigs.SetItem(lowerName, none);
            lowerName.FreeSelf();
        }
        nextName.FreeSelf();
    }
}

private static function string NameToStorageVersion(string configObjectName)
{
    return Repl(configObjectName, ".", ":");
}

private static function string NameToActualVersion(string configObjectName)
{
    return Repl(configObjectName, ":", ".");
}

/**
 *  Creates a brand new config object with a given name.
 *
 *  Fails if config object with that name already exists.
 *  Config name must be considered *valid* by `BaseText.IsValidName()`
 *  standards.
 *
 *  Always writes new config inside the ini file on disk.
 *
 *  @param  name    Name of the new config object.
 *      Must be considered *valid* by `BaseText.IsValidName()`
 *      standards, otherwise method will fail.
 *  @return `false` iff config object name `name` already exists
 *      or `name` is invalid for config object.
 */
public final static function bool NewConfig(BaseText name)
{
    local AcediaConfig newConfig;
    if (name == none)                       return false;
    if (!name.IsValidName())                return false;
    if (default.existingConfigs == none)    return false;

    name = name.LowerCopy();
    if (default.existingConfigs.HasKey(name))
    {
        name.FreeSelf();
        return false;
    }
    newConfig =
        new(none, NameToStorageVersion(name.ToString())) default.class;
    newConfig._ = __();
    newConfig.DefaultIt();
    newConfig.SaveConfig();
    default.existingConfigs.SetItem(name, newConfig);
    name.FreeSelf();
    return true;
}

/**
 *  Checks if a config object with a given name exists.
 *
 *  @param  name    Name of the new config object.
 *      Must be considered *valid* by `BaseText.IsValidName()` standards.
 *  @return `true` iff new config object was created.
 */
public final static function bool Exists(BaseText name)
{
    local bool result;
    if (name == none)                       return false;
    if (!name.IsValidName())                return false;
    if (default.existingConfigs == none)    return false;

    name = name.LowerCopy();
    result = default.existingConfigs.HasKey(name);
    name.FreeSelf();
    return result;
}

/**
 *  Deletes config object with a given name.
 *
 *  If given config object exists, this method cannot fail.
 *  `Exists()` is guaranteed to return `false` after this method call.
 *
 *  Always removes any present config entries from ini files.
 *
 *  @param  name    Name of the config object to delete.
*/
public final static function DeleteConfig(BaseText name)
{
    local AcediaObject value;
    if (name == none)                       return;
    if (default.existingConfigs == none)    return;

    name = name.LowerCopy();
    value = default.existingConfigs.TakeItem(name);
    if (value != none) {
        value.ClearConfig();
    }
    __().memory.Free(name);
}

/**
 *  Returns array containing names of all available config objects.
 *
 *  @return Array with names of all available config objects.
 *      Guaranteed to not contain `none` values.
 */
public static function array<Text> AvailableConfigs()
{
    local array<Text> emptyResult;
    if (default.existingConfigs != none) {
        return default.existingConfigs.GetTextKeys();
    }
    return emptyResult;
}

/**
 *  Returns `AcediaConfig` of caller class with name `name`.
 *
 *  @param  name    Name of the config object, whos settings data is to
 *      be loaded. Must be considered *valid* by `BaseText.IsValidName()`
 *      standards.
 *  @return `AcediaConfig` of caller class with name `name`.
 *      Returns `none` if config with given name doesn't exist.
 */
public final static function AcediaConfig GetConfigInstance(BaseText name)
{
    local HashTable.Entry configEntry;
    if (name == none)                       return none;
    if (!name.IsValidName())                return none;
    if (default.existingConfigs == none)    return none;

    name = name.LowerCopy();
    configEntry = default.existingConfigs.GetEntry(name);
    if (configEntry.value == none && configEntry.key != none)
    {
        configEntry.value =
            new(none, NameToStorageVersion(name.ToString())) default.class;
        configEntry.value._ = __();
        default.existingConfigs.SetItem(configEntry.key, configEntry.value);
    }
    __().memory.Free(name);
    //  We return value, so do not deallocate it
    __().memory.Free(configEntry.key);
    return AcediaConfig(configEntry.value);
}

/**
 *  Loads Acedia's representation of settings data of a particular config
 *  object, given by the `name`.
 *
 *  Should only be called if caller class has `supportsDataConversion` set to
 *  `true`.
 *
 *  @param  name    Name of the config object, whos data is to be loaded.
 *      Name must be considered *valid* by `BaseText.IsValidName()` standards.
 *  @return Data of a particular config object, given by the `name`.
 *      Expected to be in format that allows for JSON serialization
 *      (see `JSONAPI.IsCompatible()` for details).
 *      Returns `none` if config with specified name is missing (or their class
 *      was not yet initialized: see `self.Initialize()` method).
*/
public final static function HashTable LoadData(BaseText name)
{
    local HashTable     result;
    local AcediaConfig  requiredConfig;
    requiredConfig = GetConfigInstance(name);
    if (requiredConfig != none) {
        result = requiredConfig.ToData();
    }
    return result;
}

/**
 *  Saves Acedia's representation of settings data (`data`) for a particular
 *  config object, given by the `name`.
 *
 *  Should only be called if caller class has `supportsDataConversion` set to
 *  `true`.
 *
 *  @param  name    Name of the config object, whos data is to be modified.
 *      Name must be considered *valid* by `BaseText.IsValidName()` standards.
 *  @param  data    New data for config variables. Expected to be in format that
 *      allows for JSON deserialization (see `JSONAPI.IsCompatible()` for
 *      details).
*/
public final static function SaveData(BaseText name, HashTable data)
{
    local AcediaConfig requiredConfig;
    requiredConfig = GetConfigInstance(name);
    if (requiredConfig != none)
    {
        requiredConfig.FromData(data);
        requiredConfig.SaveConfig();
    }
}

defaultproperties
{
    supportsDataConversion = false
    usesObjectPool = false
}