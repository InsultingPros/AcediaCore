/**
 *      Aliases allow users to define human-readable and easier to use
 *  "synonyms" to some symbol sequences (mainly names of UnrealScript classes).
 *      This is an interface class that can be implemented in various different
 *  ways.
 *      Several `AliasSource`s are supposed to exist separately, each storing
 *  aliases of particular kind: for weapon, zeds, colors, etc..
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
class BaseAliasSource extends AcediaObject
    abstract;

/**
 *  # `AliasSource`
 *
 *  Interface for any alias source instance that includes basic methods for
 *  alias lookup and adding/removal.
 *
 *  ## Aliases
 *
 *      Aliases in Acedia are usually defined as either `$<alias_name>`.
 *  `<alias_name>` can only contain ASCII latin letters and digits.
 *  `<alias_name>` is meant to define a human-readable name for something
 *  (e.g. "m14" for `KFMod.M14EBRBattleRifle`).
 *      Aliases are *case-insensitive*.
 *      '$' prefix is used to emphasize that what user is specifying is,
 *  in fact, an alias and it *is not* actually important for aliases feature
 *  and API: only `<alias_name>` is used. However, for convenience's sake,
 *  `AliasesAPI` usually recognizes aliases both with and without '$' prefix.
 *  Alias sources (classes derived from `BaseAliasSource`), however should only
 *  handle resolving `<alias_name>`, treating '$' prefix as a mistake in alias
 *  parameter.
 *
 *  ## Implementation
 *
 *      As far as implementation goes, it's up to you how your own child alias
 *  source class is configured to obtain its aliases, but `Aliases_Feature`
 *  should only create a single instance for every source class (although
 *  nothing can prevent other mods from creating more instances, so we cannot
 *  give any guarantees).
 *      Methods that add or remove aliases are allowed to fail for whatever
 *  reason is valid for your source's case (it might forbid adding aliases
 *  at all), as long as they return `false`.
 *      Although all built-in aliases are storing case-insensitive values,
 *  `BaseAliasSource` does not demand that and allows to configure this behavior
 *  via `AreValuesCaseSensitive()`. This is important for `GetAliases()` method
 *  that returns all aliases referring to a given value.
 */

/**
 *  Returns whether caller alias source class stores case-sensitive values.
 *
 *  This information is necessary for organizing lookup of aliases by
 *  a given value. Aliases themselves are always case-insensitive.
 *
 *  This method should not change returned value for any fixed class.
 *
 *  @return `true` if stored values are case-sensitive and `false` if they are
 *      case-insensitive.
 */
public static function bool AreValuesCaseSensitive();

/**
 *  Returns all aliases that represent given value `value`.
 *
 *  @param  value   Value for which to return all its aliases.
 *      Whether it is treated as case-sensitive is decided by
 *      `AreValuesCaseSensitive()` method, but all default alias sources are
 *      case-insensitive.
 *  @return Array of all aliases that refer to the given `value` inside
 *      the caller alias source. All `Text` references are guaranteed to not be
 *      `none` or duplicated.
 */
public function array<Text> GetAliases(BaseText value);

/**
 *  Returns all aliases that represent given value `value`.
 *
 *  @param  value   Value for which to return all its aliases.
 *      Whether it is treated as case-sensitive is decided by
 *      `AreValuesCaseSensitive()` method, but all default alias sources are
 *      case-insensitive.
 *  @return Array of all aliases that refer to the given `value` inside
 *      the caller alias source. All `string` references are guaranteed to not
 *      be duplicated.
 */
public function array<string> GetAliases_S(string value)
{
    local int           i;
    local Text          valueAsText;
    local array<Text>   resultWithTexts;
    local array<string> result;

    valueAsText = _.text.FromString(value);
    resultWithTexts = GetAliases(valueAsText);
    _.memory.Free(valueAsText);
    for (i = 0; i < resultWithTexts.length; i += 1) {
        result[result.length] = resultWithTexts[i].ToString();
    }
    _.memory.FreeMany(resultWithTexts);
    return result;
}

/**
 *  Checks if given alias is present in caller `AliasSource`.
 *
 *  NOTE: having '$' prefix is considered to be invalid for `alias` by this
 *  method.
 *
 *  @param  alias   Alias to check, case-insensitive.
 *  @return `true` if present, `false` otherwise.
 */
public function bool HasAlias(BaseText alias);

/**
 *  Checks if given alias is present in caller `AliasSource`.
 *
 *  NOTE: having '$' prefix is considered to be invalid for `alias` by this
 *  method.
 *
 *  @param  alias   Alias to check, case-insensitive.
 *  @return `true` if present, `false` otherwise.
 */
public function bool HasAlias_S(string alias)
{
    local bool result;
    local Text aliasAsText;

    aliasAsText = _.text.FromString(alias);
    result = HasAlias(aliasAsText);
    _.memory.Free(aliasAsText);
    return result;
}

/**
 *  Returns value stored for the given alias in caller `AliasSource`
 *  (as well as it's `Aliases` objects).
 *
 *  NOTE: having '$' prefix is considered to be invalid for `alias` by this
 *  method.
 *
 *  @param  alias           Alias, for which method will attempt to return
 *      a value. Case-insensitive. If given `alias` starts with "$" character -
 *      that character will be removed before resolving that alias.
 *  @param  copyOnFailure   Whether method should return copy of original
 *      `alias` value in case caller source did not have any records
 *      corresponding to `alias`.
 *  @return If look up was successful - value, associated with the given
 *      alias `alias`. If lookup was unsuccessful, it depends on `copyOnFailure`
 *      flag: `copyOnFailure == false` means method will return `none`
 *      and `copyOnFailure == true` means method will return `alias.Copy()`.
 *      If `alias == none` method always returns `none`.
 */
public function Text Resolve(BaseText alias, optional bool copyOnFailure);

/**
 *  Returns value stored for the given alias in caller `AliasSource`
 *  (as well as it's `Aliases` objects).
 *
 *  NOTE: having '$' prefix is considered to be invalid for `alias` by this
 *  method.
 *
 *  @param  alias           Alias, for which method will attempt to return
 *      a value. Case-insensitive. If given `alias` starts with "$" character -
 *      that character will be removed before resolving that alias.
 *  @param  copyOnFailure   Whether method should return copy of original
 *      `alias` value in case caller source did not have any records
 *      corresponding to `alias`.
 *  @return If look up was successful - value, associated with the given
 *      alias `alias`. If lookup was unsuccessful, it depends on `copyOnFailure`
 *      flag: `copyOnFailure == false` means method will return empty `string`
 *      and `copyOnFailure == true` means method will return `alias`.
 */
public function string Resolve_S(
    string          alias,
    optional bool   copyOnFailure)
{
    local Text resultAsText;
    local Text aliasAsText;

    aliasAsText = _.text.FromString(alias);
    resultAsText = Resolve(aliasAsText, copyOnFailure);
    return _.text.IntoString(resultAsText);
}

/**
 *  Adds another alias to the caller `AliasSource`.
 *  If alias with the same name as `aliasToAdd` already exists - method
 *  overwrites it.
 *
 *  Can fail iff `aliasToAdd` is an invalid alias or `aliasValue == none`.
 *
 *  NOTE: having '$' prefix is considered to be invalid for `alias` by this
 *  method.
 *
 *  @param  aliasToAdd  Alias that you want to add to caller source.
 *      Alias names are case-insensitive.
 *  @param  aliasValue  Intended value of this alias.
 *  @return `true` if alias was added and `false` otherwise (alias was invalid).
 */
public function bool AddAlias(BaseText aliasToAdd, BaseText aliasValue);

/**
 *  Adds another alias to the caller `AliasSource`.
 *  If alias with the same name as `aliasToAdd` already exists, -
 *  method overwrites it.
 *
 *  Can fail iff `aliasToAdd` is an invalid alias.
 *
 *  NOTE: having '$' prefix is considered to be invalid for `alias` by this
 *  method.
 *
 *  @param  aliasToAdd  Alias that you want to add to caller source.
 *      Alias names are case-insensitive.
 *  @param  aliasValue  Intended value of this alias.
 *  @return `true` if alias was added and `false` otherwise (alias was invalid).
 */
public function bool AddAlias_S(string aliasToAdd, string aliasValue)
{
    local bool result;
    local Text aliasAsText, valueAsText;

    aliasAsText = _.text.FromString(aliasToAdd);
    valueAsText = _.text.FromString(aliasValue);
    result = AddAlias(aliasAsText, valueAsText);
    _.memory.Free(aliasAsText);
    _.memory.Free(valueAsText);
    return result;
}

/**
 *  Removes alias (all records with it, in case of duplicates) from
 *  the caller `AliasSource`.
 *
 *  NOTE: having '$' prefix is considered to be invalid for `alias` by this
 *  method.
 *
 *  @param  aliasToRemove   Alias that you want to remove from caller source.
 *  @return `true` if an alias was present in the source and was deleted and
 *      `false` if there was no specified alias in the first place.
 */
public function bool RemoveAlias(BaseText aliasToRemove);

/**
 *  Removes alias (all records with it, in case of duplicates) from
 *  the caller `AliasSource`.
 *
 *  NOTE: having '$' prefix is considered to be invalid for `alias` by this
 *  method.
 *
 *  @param  aliasToRemove   Alias that you want to remove from caller source.
 *  @return `true` if an alias was present in the source and was deleted and
 *      `false` if there was no specified alias in the first place.
 */
public function bool RemoveAlias_S(string aliasToRemove)
{
    local bool result;
    local Text aliasAsText;

    aliasAsText = _.text.FromString(aliasToRemove);
    result = RemoveAlias(aliasAsText);
    _.memory.Free(aliasAsText);
    return result;
}

defaultproperties
{
}