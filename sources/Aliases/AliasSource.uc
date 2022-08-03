/**
 *      This class implements an alias database that stores aliases inside
 *  standard config ini-files.
 *      Copyright 2020-2022 Anton Tarasenko
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
class AliasSource extends BaseAliasSource
    dependson(HashTable)
    abstract;

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

//      (Sub-)class of `Aliases` objects that this `AliasSource` uses to store
//  aliases in per-object-config manner.
//      Leaving this variable `none` will produce an `AliasSource` that can
//  only store aliases in form of `record=(alias="...",value="...")`.
var public const class<AliasesStorage>  aliasesClass;
//  Storage for all objects of `aliasesClass` class in the config.
//  Exists after `OnCreated()` event and is maintained up-to-date at all times.
var private array<AliasesStorage>       loadedAliasObjects;

//      Faster access to value by alias' name.
//      It contains same records as `record` array + aliases from
//  `loadedAliasObjects` objects when there are no duplicate aliases.
//  Otherwise only stores first loaded alias.
var private HashTable aliasHash;
//      Faster access to all aliases, corresponding to a certain value.
//      This `HashTable` stores same data as `aliasHash`, but "in reverse":
//  for each value as a "key" it stored `ArrayList` of corresponding aliases.
var private HashTable valueHash;

//  `true` means that this `AliasSource` is awaiting saving into its config
var private bool pendingSaveToConfig;

var private LoggerAPI.Definition errIncorrectAliasPair, warnDuplicateAlias;
var private LoggerAPI.Definition warnInvalidAlias;

//  Load and hash all the data `AliasSource` creation.
protected function Constructor()
{
    //  If this check fails - caller alias source is fundamentally broken
    //  and requires mod to be fixed
    if (!ASSERT_AliasesClassIsOwnedByThisSource()) {
        return;
    }
    //  Load and hash
    loadedAliasObjects = aliasesClass.static.LoadAllObjects();
    aliasHash = _.collections.EmptyHashTable();
    valueHash = _.collections.EmptyHashTable();
    HashValidAliasesFromRecord();
    HashValidAliasesFromPerObjectConfig();
}

protected function Finalizer()
{
    loadedAliasObjects.length = 0;
    _.memory.Free(aliasHash);
    aliasHash = none;
    if (pendingSaveToConfig) {
        SaveConfig();
    }
}

//  Ensures that our `Aliases` class is properly linked with this
//  source's class. Logs failure otherwise.
private function bool ASSERT_AliasesClassIsOwnedByThisSource()
{
    if (aliasesClass == none)                       return true;
    if (aliasesClass.default.sourceClass == class)  return true;

    _.logger.Auto(errIncorrectAliasPair).ArgClass(class);
    return false;
}

//  Load hashes from `AliasSource`'s config (`record` array)
private function HashValidAliasesFromRecord()
{
    local int   i;
    local Text  aliasAsText, valueAsText;

    for (i = 0; i < record.length; i += 1)
    {
        aliasAsText = _.text.FromString(record[i].alias);
        valueAsText = _.text.FromString(record[i].value);
        InsertAliasIntoHash(aliasAsText, valueAsText);
        aliasAsText.FreeSelf();
        valueAsText.FreeSelf();
    }
}

//  Load hashes from `Aliases` objects' config
private function HashValidAliasesFromPerObjectConfig()
{
    local int           i, j;
    local Text          nextValue;
    local array<Text>   valueAliases;

    for (i = 0; i < loadedAliasObjects.length; i += 1)
    {
        nextValue       = loadedAliasObjects[i].GetValue();
        valueAliases    = loadedAliasObjects[i].GetAliases();
        for (j = 0; j < valueAliases.length; j += 1) {
            InsertAliasIntoHash(valueAliases[j], nextValue);
        }
        nextValue.FreeSelf();
        _.memory.FreeMany(valueAliases);
    }
}

public static function bool AreValuesCaseSensitive()
{
    //  Almost all built-in aliases are aliases to class names (or templates)
    //  and the rest are colors. Both are case-insensitive, so returning `false`
    //  is a good default implementation. Child classes can just change this
    //  value, if they need.
    return false;
}

public function array<Text> GetAliases(BaseText value)
{
    local int           i;
    local Text          storedValue;
    local ArrayList     aliasesArray;
    local array<Text>   result;

    storedValue = NormalizeValue(value);
    aliasesArray = valueHash.GetArrayList(storedValue);
    storedValue.FreeSelf();
    if (aliasesArray == none) {
        return result;
    }
    for (i = 0; i < aliasesArray.GetLength(); i += 1) {
        result[result.length] = aliasesArray.GetText(i);
    }
    return result;
}

//  "Normalizes" value:
//      1. Converts it into lower case if `AreValuesCaseSensitive()` returns
//          `true`;
//      2. Converts in into `Text` in case passed value is `MutableText`, so
//          that hash table is actually usable.
private function Text NormalizeValue(BaseText value)
{
    if (value == none) {
        return none;
    }
    if (AreValuesCaseSensitive()) {
        return value.Copy();
    }
    return value.LowerCopy();
}

//      Inserts alias into `aliasHash`, cleaning previous keys/values in case
//  they already exist.
//      Takes care of lower case conversion to store aliases in `aliasHash`
//  in a case-insensitive way. Depending on `AreValuesCaseSensitive()`, can also
//  convert values to lower case.
private function InsertAliasIntoHash(BaseText alias, BaseText value)
{
    local Text      storedAlias;
    local Text      storedValue;
    local Text      existingValue;
    local ArrayList valueAliases;

    if (alias == none)  return;
    if (value == none)  return;

    if (!alias.IsValidName())
    {
        _.logger.Auto(warnInvalidAlias)
            .ArgClass(class)
            .Arg(alias.Copy());
        return;
    }
    storedAlias = alias.LowerCopy();
    existingValue = aliasHash.GetText(storedAlias);
    if (aliasHash.HasKey(storedAlias))
    {
        _.logger.Auto(warnDuplicateAlias)
            .ArgClass(class)
            .Arg(alias.Copy())
            .Arg(existingValue);
    }
    _.memory.Free(existingValue);
    storedValue = NormalizeValue(value);
    //  Add to `aliasHash`: alias -> value
    aliasHash.SetItem(storedAlias, storedValue);
    //  Add to `valueHash`: value -> alias
    valueAliases = valueHash.GetArrayList(storedValue);
    if (valueAliases == none) {
        valueAliases = _.collections.EmptyArrayList();
    }
    valueAliases.AddItem(storedAlias);
    valueHash.SetItem(storedValue, valueAliases);
    //  Clean up
    storedAlias.FreeSelf();
    storedValue.FreeSelf();
}

public function bool HasAlias(BaseText alias)
{
    local bool  result;
    local Text  storedAlias;

    if (alias == none) {
        return false;
    }
    storedAlias = alias.LowerCopy();
    result = aliasHash.HasKey(storedAlias);
    storedAlias.FreeSelf();
    return result;
}

public function Text Resolve(
    BaseText        alias,
    optional bool   copyOnFailure)
{
    local Text result;
    local Text storedAlias;

    if (alias == none) {
        return none;
    }
    storedAlias = alias.LowerCopy();
    result = aliasHash.GetText(storedAlias);
    storedAlias.FreeSelf();
    if (result != none) {
        return result;
    }
    if (copyOnFailure) {
        return alias.Copy();
    }
    return none;
}

public function bool AddAlias(BaseText aliasToAdd, BaseText aliasValue)
{
    local Text storedAlias;

    if (aliasToAdd == none)         return false;
    if (aliasValue == none)         return false;
    if (!aliasToAdd.IsValidName())  return false;

    //  Check if alias already exists and if yes - remove it
    storedAlias = aliasToAdd.LowerCopy();
    if (aliasHash.HasKey(storedAlias)) {
        RemoveAlias(aliasToAdd);
    }
    storedAlias.FreeSelf();
    //  Add alias-value pair
    AddToConfigRecords(aliasToAdd.ToString(), aliasValue.ToString());
    InsertAliasIntoHash(aliasToAdd, aliasValue);
    return true;
}

public function bool RemoveAlias(BaseText aliasToRemove)
{
    local Text      storedAlias, storedValue;
    local ArrayList valueAliases;

    if (aliasToRemove == none)          return false;
    if (!aliasToRemove.IsValidName())   return false;

    storedAlias = aliasToRemove.LowerCopy();
    storedValue = aliasHash.GetText(storedAlias);
    if (storedValue == none)
    {
        storedAlias.FreeSelf();
        return false;
    }
    aliasHash.RemoveItem(aliasToRemove);
    //  Since we've found `storedValue`, this couldn't possibly be `none` if
    //  "same data invariant" is preserved (see their declaration)
    valueAliases = valueHash.GetArrayList(storedValue);
    if (valueAliases != none) {
        valueAliases.RemoveItem(storedAlias, true);
    }
    if (valueAliases != none && valueAliases.GetLength() <= 0)
    {
        valueHash.SetItem(storedValue, none);
        valueAliases = none;
    }
    _.memory.Free(valueAliases);
    RemoveFromConfigRecords(aliasToRemove.ToString());
    return true;
}

//  Takes `string`s that represents alias to remove in proper case (lower for
//  aliases and for values it depends on the caller source's settings):
//  aliases are supposed to be ASCII, so `string` should handle it and its
//  comparison just fine
private function AddToConfigRecords(string alias, string value)
{
    local AliasValuePair newPair;

    newPair.alias = alias;
    newPair.value = value;
    record[record.length] = newPair;
    //  Request saving
    if (!pendingSaveToConfig)
    {
        pendingSaveToConfig = true;
        _.scheduler.RequestDiskAccess(self).connect = SaveSelf;
    }
}

//  Takes `string` that represents alias to remove in lower case: aliases are
//  supposed to be ASCII, so `string` should handle it and its comparison just
//  fine
private function RemoveFromConfigRecords(string aliasToRemove)
{
    local int   i;
    local bool  removedAliasFromRecord;

    //  Aliases are supposed to be ASCII, so `string` should handle it and its
    //  comparison just fine
    while (i < record.length)
    {
        if (aliasToRemove ~= record[i].alias)
        {
            record.Remove(i, 1);
            removedAliasFromRecord = true;
        }
        else {
            i += 1;
        }
    }
    //  Since admins can fuck up and add duplicate aliases, we need to
    //  thoroughly check every alias object
    for (i = 0; i < loadedAliasObjects.length; i += 1) {
        loadedAliasObjects[i].RemoveAlias_S(aliasToRemove);
    }
    //  Alias objects can request disk access themselves, so only record if
    //  needed for the record
    if (removedAliasFromRecord && !pendingSaveToConfig)
    {
        pendingSaveToConfig = true;
        _.scheduler.RequestDiskAccess(self).connect = SaveSelf;
    }
}

private function SaveSelf()
{
    pendingSaveToConfig = false;
    SaveConfig();
}

defaultproperties
{
    //  Source main parameters
    aliasesClass = class'Aliases'
    errIncorrectAliasPair   = (l=LOG_Error,m="`AliasSource`-`Aliases` class pair is incorrectly setup for source `%1`. Omitting it.")
    warnDuplicateAlias      = (l=LOG_Warning,m="Alias source `%1` has duplicate record for alias \"%2\". This is likely due to an erroneous config. \"%3\" value will be used.")
    warnInvalidAlias        = (l=LOG_Warning,m="Alias source `%1` has record with invalid alias \"%2\". This is likely due to an erroneous config. This alias will be discarded.")
}