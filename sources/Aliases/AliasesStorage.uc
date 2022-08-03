/**
 *      This is a simple helper object for `AliasSource` that can store
 *  an array of aliases in config files in a per-object-config manner.
 *      One `AliasesStorage` object can store several aliases for a single
 *  value.
 *      It is recommended that you do not try to access these objects directly.
 *       `AliasesStorage` is abstract, so it can never be created, for any
 *  actual use create a child class. Suggested name scheme is
 *  "<something>Aliases", like "ColorAliases" or "WeaponAliases".
 *      It's only interesting function is storing '.'s as ':' in it's config,
 *  which is necessary to allow storing aliases for class names via
 *  these objects (since UnrealScript's cannot handle '.'s in object's names
 *  in it's configs).
 *  [INTERNAL] This is an internal object and should not be directly modified,
 *  its only allowed use is documented way to create new alias sources.
 *      Copyright 2019-2022 Anton Tarasenko
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
class AliasesStorage extends AcediaObject
    perObjectConfig
    config(AcediaAliases)
    abstract;

//      Aliases, recorded by this `AliasesStorage` object that all refer to
//  the same value, defined by this object's name `string(self.name)`
var protected config array<string>  alias;

//  Name of the configurational file (without extension) where
//  this `AliasSource`'s data will be stored
var protected const string configName;

//  Link to the `AliasSource` that uses `AliasesStorage` objects of this class.
//  To ensure that any `AliasesStorage` sub-class only belongs to one
//  `AliasSource`.
var public const class<AliasSource> sourceClass;

//  `true` means that this `AliasesStorage` object is awaiting saving into its
//  config
var private bool pendingSaveToConfig;

//  Since:
//      1. '.'s in values are converted into ':' for storage purposes;
//      2. We have to store values in `string` to make use of config files.
//  we need methods to convert between "storage" (`string`)
//  and "actual" (`Text`) value version.
//  `ToStorageVersion()` and `ToActualVersion()` do that.
private final static function string ToStorageVersion(BaseText actualValue)
{
    return Repl(actualValue.ToString(), ".", ":");
}

//  See comment to `ToStorageVersion()`
private final static function Text ToActualVersion(string storageValue)
{
    return __().text.FromString(Repl(storageValue, ":", "."));
}

/**
 *  Loads all `AliasesStorage` objects from their config file
 *  (defined in paired `AliasSource` class).
 *
 *  This is an internal method and returned `AliasesStorage` objects require
 *  a special treatment: they aren't meant to be used with Acedia's reference
 *  counting - never release their references.
 *
 *  @return Array of all `Aliases` objects, loaded from their config file.
 */
public static final function array<AliasesStorage> LoadAllObjects()
{
    local int                   i;
    local array<string>         objectNames;
    local array<AliasesStorage> loadedAliasObjects;

    objectNames = GetPerObjectNames(default.configName,
                                    string(default.class.name), MaxInt);
    for (i = 0; i < objectNames.length; i += 1) {
        loadedAliasObjects[i] = LoadObjectByName(objectNames[i]);
    }
    return loadedAliasObjects;
}

//  Loads a new `AliasesStorage` object by it's given name (`objectName`).
private static final function AliasesStorage LoadObjectByName(
    string objectName)
{
    local AliasesStorage result;

    //  Since `MemoryAPI` for now does not support specifying names
    //  to created objects - do some manual dark magic and
    //  initialize this shit ourselves. Don't repeat this at home, kids.
    result = new(none, objectName) default.class;
    result._constructor();
    return result;
}

/**
 *  Loads a new `AliasesStorage` object based on the value (`aliasesValue`)
 *  of it's aliases.
 *
 *  @param  aliasesValue    Value that aliases in this `Aliases` object will
 *      correspond to.
 *  @return Instance of `AliasesStorage` object with a given name.
 */
public static final function AliasesStorage LoadObject(BaseText aliasesValue)
{
    if (aliasesValue != none) {
        return LoadObjectByName(ToStorageVersion(aliasesValue));
    }
    return none;
}

/**
 *  Returns value that caller's `Aliases` object's aliases point to.
 *
 *  @return Value, stored by this object.
 */
public final function Text GetValue()
{
    return ToActualVersion(string(self.name));
}

/**
 *  Returns array of aliases that caller `AliasesStorage` tells us point to
 *  it's value.
 *
 *  @return Array of all aliases, stored by caller `AliasesStorage` object.
 */
public final function array<Text> GetAliases()
{
    local int           i;
    local array<Text>   textAliases;

    for (i = 0; i < alias.length; i += 1) {
        textAliases[i] = _.text.FromString(alias[i]);
    }
    return textAliases;
}

/**
 *  [For inner use by `AliasSource`] Removes alias from this object.
 *
 *  Does not update relevant `AliasHash`.
 *
 *  Will prevent adding duplicate records inside it's own storage.
 *
 *  @param  aliasToRemove   Alias to remove from caller `AliasesStorage` object.
 *      Expected to be in lower case.
 */
public final function RemoveAlias_S(string aliasToRemove)
{
    local int   i;
    local bool  removedAlias;

    while (i < alias.length)
    {
        if (aliasToRemove ~= alias[i])
        {
            alias.Remove(i, 1);
            removedAlias = true;
        }
        else {
            i += 1;
        }
    }
    if (!pendingSaveToConfig)
    {
        pendingSaveToConfig = true;
        _.scheduler.RequestDiskAccess(self).connect = SaveOrClear;
    }
}

/**
 *  If this object still has any alias records, - forces a rewrite of it's data
 *  into the config file, otherwise - removes it's record entirely.
 */
private final function SaveOrClear()
{
    if (alias.length <= 0) {
        ClearConfig();
    }
    else {
        SaveConfig();
    }
    pendingSaveToConfig = false;
}

defaultproperties
{
    sourceClass = class'AliasSource'
    configName  = "AcediaAliases"
}