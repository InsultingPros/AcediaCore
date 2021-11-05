/**
 *      Aliases allow users to define human-readable and easier to use
 *  "synonyms" to some symbol sequences (mainly names of UnrealScript classes).
 *      This class implements an alias database that stores aliases inside
 *  standard config ini-files.
 *      Several `AliasSource`s are supposed to exist separately, each storing
 *  aliases of particular kind: for weapon, zeds, colors, etc..
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
class AliasSource extends Singleton
    dependson(AssociativeArray)
    config(AcediaAliases);

//      (Sub-)class of `Aliases` objects that this `AliasSource` uses to store
//  aliases in per-object-config manner.
//      Leaving this variable `none` will produce an `AliasSource` that can
//  only store aliases in form of `record=(alias="...",value="...")`.
var public const class<Aliases> aliasesClass;
//  Storage for all objects of `aliasesClass` class in the config.
//  Exists after `OnCreated()` event and is maintained up-to-date at all times.
var private array<Aliases>      loadedAliasObjects;

//      Links alias to a value.
//      An array of these structures (without duplicate `alias` records) defines
//  a function from the space of aliases to the space of values.
struct AliasValuePair
{
    var string alias;
    var string value;
};
//  Aliases data for saving and loading on a disk (ini-file).
//  Name is chosen to make configurational files more readable.
var private config array<AliasValuePair> record;
//      Faster access to value by alias' name.
//      It contains same records as `record` array + aliases from
//  `loadedAliasObjects` objects when there are no duplicate aliases.
//  Otherwise only stores first loaded alias.
var private AssociativeArray aliasHash;

var private LoggerAPI.Definition errIncorrectAliasPair, warnDuplicateAlias;

//  Load and hash all the data `AliasSource` creation.
protected function OnCreated()
{
    if (!AssertAliasesClassIsOwnedByThisSource()) {
        Destroy();
        return;
    }
    //  Load and hash
    loadedAliasObjects = aliasesClass.static.LoadAllObjects();
    aliasHash = _.collections.EmptyAssociativeArray();
    HashValidAliasesFromRecord();
    HashValidAliasesFromPerObjectConfig();
}

protected function OnDestroyed()
{
    loadedAliasObjects.length = 0;
    _.memory.Free(aliasHash);
    aliasHash = none;
}

//  Ensures that our `Aliases` class is properly linked with this
//  source's class. Logs failure otherwise.
private final function bool AssertAliasesClassIsOwnedByThisSource()
{
    if (aliasesClass == none)                       return true;
    if (aliasesClass.default.sourceClass == class)  return true;
    _.logger.Auto(errIncorrectAliasPair).ArgClass(class);
    Destroy();
    return false;
}

//  Load hashes from `AliasSource`'s config (`record` array)
private final function HashValidAliasesFromRecord()
{
    local int   i;
    local Text  aliasAsText, valueAsText;
    for (i = 0; i < record.length; i += 1)
    {
        aliasAsText = _.text.FromString(record[i].alias);
        valueAsText = _.text.FromString(record[i].value);
        InsertAlias(aliasAsText, valueAsText);
        aliasAsText.FreeSelf();
        valueAsText.FreeSelf();
    }
}

//  Load hashes from `Aliases` objects' config
private final function HashValidAliasesFromPerObjectConfig()
{
    local int           i, j;
    local Text          nextValue;
    local array<Text>   valueAliases;
    for (i = 0; i < loadedAliasObjects.length; i += 1)
    {
        nextValue       = loadedAliasObjects[i].GetValue();
        valueAliases    = loadedAliasObjects[i].GetAliases();
        for (j = 0; j < valueAliases.length; j += 1) {
            InsertAlias(valueAliases[j], nextValue);
        }
        nextValue.FreeSelf();
        _.memory.FreeMany(valueAliases);
    }
}

//      Inserts alias into `aliasHash`, cleaning previous keys/values in case
//  they already exist.
//      Takes care of lower case conversion to store aliases in `aliasHash`
//  in a case-insensitive way.
private final function InsertAlias(Text alias, Text value)
{
    local Text                      aliasLowerCaseCopy;
    local AssociativeArray.Entry    hashEntry;
    if (alias == none)  return;
    if (value == none)  return;
    aliasLowerCaseCopy = alias.LowerCopy();
    hashEntry = aliasHash.TakeEntry(aliasLowerCaseCopy);
    if (hashEntry.value != none) {
        LogDuplicateAliasWarning(alias, Text(hashEntry.value));
    }
    _.memory.Free(hashEntry.key);
    _.memory.Free(hashEntry.value);
    aliasHash.SetItem(aliasLowerCaseCopy, value.Copy(), true);
}

/**
 *  Checks if given alias is present in caller `AliasSource`.
 *
 *  @param  alias   Alias to check, case-insensitive.
 *  @return `true` if present, `false` otherwise.
 */
public function bool HasAlias(Text alias)
{
    local bool  result;
    local Text  lowerCaseAlias;
    if (alias == none) {
        return false;
    }
    lowerCaseAlias = alias.LowerCopy();
    result = aliasHash.HasKey(lowerCaseAlias);
    lowerCaseAlias.FreeSelf();
    return result;
}

/**
 *  Return value stored for the given alias in caller `AliasSource`
 *  (as well as it's `Aliases` objects).
 *
 *  @param  alias           Alias, for which method will attempt to return
 *      a value. Case-insensitive.
 *  @param  copyOnFailure   Whether method should return copy of original
 *      `alias` value in case caller source did not have any records
 *      corresponding to `alias`.
 *  @return If look up was successful - value, associated with the given
 *      alias `alias`. If lookup was unsuccessful, it depends on `copyOnFailure`
 *      flag: `copyOnFailure == false` means method will return `none`
 *      and `copyOnFailure == true` means method will return `alias.Copy()`.
 *      If `alias == none` method always returns `none`.
 */
public function Text Resolve(Text alias, optional bool copyOnFailure)
{
    local Text result;
    local Text lowerCaseAlias;
    if (alias == none) {
        return none;
    }
    lowerCaseAlias = alias.LowerCopy();
    result = Text(aliasHash.GetItem(lowerCaseAlias));
    lowerCaseAlias.FreeSelf();
    if (result != none) {
        return result.Copy();
    }
    if (copyOnFailure) {
        return alias.Copy();
    }
    return none;
}

/**
 *  Adds another alias to the caller `AliasSource`.
 *  If alias with the same name as `aliasToAdd` already exists, -
 *  method overwrites it.
 *
 *  Can fail iff `aliasToAdd` is an invalid alias or `aliasValue == none`.
 *
 *  When adding alias to an object (`saveInObject == true`) alias `aliasToAdd`
 *  will be altered by changing any ':' inside it into a '.'.
 *  This is a necessary measure to allow storing class names in
 *  config files via per-object-config.
 *
 *  NOTE:   This call will cause update of an ini-file. That update can be
 *  slightly delayed, so do not make assumptions about it's immediacy.
 *
 *  NOTE #2: Removing alias would require this method to go through the
 *  whole `AliasSource` to remove possible duplicates.
 *  This means that unless you can guarantee that there is no duplicates, -
 *  performing a lot of alias additions during run-time can be costly.
 *
 *  @param  aliasToAdd      Alias that you want to add to caller source.
 *      Alias names are case-insensitive.
 *  @param  aliasValue      Intended value of this alias.
 *  @param  saveInObject    Setting this to `true` will make `AliasSource` save
 *      given alias in per-object-config storage, while keeping it at default
 *      `false` will just add alias to the `record=` storage.
 *      If caller `AliasSource` does not support per-object-config storage, -
 *      this flag will be ignores.
 *  @return `true` if alias was added and `false` otherwise (alias was invalid).
 */
public final function bool AddAlias(
    Text            aliasToAdd,
    Text            aliasValue,
    optional bool   saveInObject)
{
    local Text              lowerCaseAlias;
    local AliasValuePair    newPair;
    if (aliasToAdd == none) return false;
    if (aliasValue == none) return false;

    lowerCaseAlias = aliasToAdd.LowerCopy();
    if (aliasHash.HasKey(lowerCaseAlias)) {
        RemoveAlias(aliasToAdd);
    }
    //  Save
    if (saveInObject) {
        GetAliasesObjectWithValue(aliasValue).AddAlias(aliasToAdd);
    }
    else
    {
        newPair.alias = aliasToAdd.ToString();
        newPair.value = aliasValue.ToString();
        record[record.length] = newPair;
    }
    aliasHash.SetItem(lowerCaseAlias, aliasValue);
    AliasService(class'AliasService'.static.Require()).PendingSaveSource(self);
    return true;
}

/**
 *  Removes alias (all records with it, in case of duplicates) from
 *  the caller `AliasSource`.
 *
 *  Cannot fail.
 *
 *  NOTE:   This call will cause update of an ini-file. That update can be
 *  slightly delayed, so do not make assumptions about it's immediacy.
 *
 *  NOTE #2: removing alias requires this method to go through the
 *  whole `AliasSource` to remove possible duplicates, which can make
 *  performing a lot of alias removal during run-time costly.
 *
 *  @param  aliasToRemove   Alias that you want to remove from caller source.
 */
public final function RemoveAlias(Text aliasToRemove)
{
    local int                       i;
    local bool                      isMatchingRecord;
    local bool                      removedAliasFromRecord;
    local AssociativeArray.Entry    hashEntry;
    if (aliasToRemove == none) {
        return;
    }
    hashEntry = aliasHash.TakeEntry(aliasToRemove);
    _.memory.Free(hashEntry.key);
    _.memory.Free(hashEntry.value);
    while (i < record.length)
    {
        isMatchingRecord = aliasToRemove
            .CompareToString(record[i].alias, SCASE_INSENSITIVE);
        if (isMatchingRecord)
        {
            record.Remove(i, 1);
            removedAliasFromRecord = true;
        }
        else {
            i += 1;
        }
    }
    for (i = 0; i < loadedAliasObjects.length; i += 1) {
        loadedAliasObjects[i].RemoveAlias(aliasToRemove);
    }
    if (removedAliasFromRecord)
    {
        AliasService(class'AliasService'.static.Require())
            .PendingSaveSource(self);
    }
}

private final function LogDuplicateAliasWarning(Text alias, Text existingValue)
{
    _.logger.Auto(warnDuplicateAlias)
        .ArgClass(class)
        .Arg(alias.Copy())
        .Arg(existingValue.Copy());
}

//      Tries to find a loaded `Aliases` config object that stores aliases for
//  the given value. If such object does not exists - creates a new one.
//      Assumes `value != none`.
private final function Aliases GetAliasesObjectWithValue(Text value)
{
    local int       i;
    local Text      nextValue;
    local Aliases   newAliasesObject;
    for (i = 0; i < loadedAliasObjects.length; i += 1)
    {
        nextValue = loadedAliasObjects[i].GetValue();
        if (value.Compare(nextValue)) {
            return loadedAliasObjects[i];
        }
        _.memory.Free(nextValue);
    }
    newAliasesObject = aliasesClass.static.LoadObject(value);
    loadedAliasObjects[loadedAliasObjects.length] = newAliasesObject;
    return newAliasesObject;
}

defaultproperties
{
    //  Source main parameters
    aliasesClass = class'Aliases'
    errIncorrectAliasPair   = (l=LOG_Error,m="`AliasSource`-`Aliases` class pair is incorrectly setup for source `%1`. Omitting it.")
    warnDuplicateAlias      = (l=LOG_Warning,m="Alias source `%1` has duplicate record for alias \"%2\". This is likely due to an erroneous config. \"%3\" value will be used.")
}