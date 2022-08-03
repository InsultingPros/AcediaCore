/**
 *  Provides convenient access to Aliases-related functions.
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
class AliasesAPI extends AcediaObject
    dependson(LoggerAPI);

//  To avoid bothering with fetching `Aliases_Feature` each time we need to
//  access an alias source, we save all the basic ones separately and
//  `Aliases_Feature` can simply trigger their updates whenever necessary via
//  `AliasesAPI._reloadSources()` function.
var private BaseAliasSource weaponAliasSource;
var private BaseAliasSource colorAliasSource;
var private BaseAliasSource featureAliasSource;
var private BaseAliasSource entityAliasSource;

public function _reloadSources()
{
    local Aliases_Feature feature;

    _.memory.Free(weaponAliasSource);
    _.memory.Free(colorAliasSource);
    _.memory.Free(featureAliasSource);
    _.memory.Free(entityAliasSource);
    weaponAliasSource   = none;
    colorAliasSource    = none;
    featureAliasSource  = none;
    entityAliasSource   = none;
    feature = Aliases_Feature(
        class'Aliases_Feature'.static.GetEnabledInstance());
    if (feature == none) {
        return;
    }
    weaponAliasSource   = feature.GetWeaponSource();
    colorAliasSource    = feature.GetColorSource();
    featureAliasSource  = feature.GetFeatureSource();
    entityAliasSource   = feature.GetEntitySource();
    _.memory.Free(feature);
}

/**
 *  Provides an easier access to the instance of the custom `BaseAliasSource`
 *  with a given name `sourceName`.
 *
 *  Custom alias sources can be added manually by the admin through the
 *  `Aliases_Feature` config file..
 *
 *  @param  sourceName  Name that alias source was added as to
 *      `Aliases_Feature`.
 *  @return Instance of the requested `BaseAliasSource`,
 *      `none` if `sourceName` is `none`, does not refer to any alias source
 *      or `Aliases_Feature` is disabled.
 */
public final function BaseAliasSource GetCustomSource(BaseText sourceName)
{
    local Aliases_Feature feature;

    if (sourceName == none) {
        return none;
    }
    feature =
        Aliases_Feature(class'Aliases_Feature'.static.GetEnabledInstance());
    if (feature != none) {
        return feature.GetCustomSource(sourceName);
    }
    return none;
}

/**
 *  Returns `BaseAliasSource` that is designated in configuration files as
 *  a source for weapon aliases.
 *
 *  @return Reference to the `BaseAliasSource` that contains weapon aliases.
 *      Can return `none` if no source for weapons was configured or
 *      the configured source is incorrectly defined.
 */
public final function BaseAliasSource GetWeaponSource()
{
    if (weaponAliasSource != none) {
        weaponAliasSource.NewRef();
    }
    return weaponAliasSource;
}

/**
 *  Returns `BaseAliasSource` that is designated in configuration files as
 *  a source for color aliases.
 *
 *
 *  @return Reference to the `BaseAliasSource` that contains color aliases.
 *      Can return `none` if no source for colors was configured or
 *      the configured source is incorrectly defined.
 */
public final function BaseAliasSource GetColorSource()
{
    if (colorAliasSource != none) {
        colorAliasSource.NewRef();
    }
    return colorAliasSource;
}

/**
 *  Returns `BaseAliasSource` that is designated in configuration files as
 *  a source for feature aliases.
 *
 *
 *  @return Reference to the `BaseAliasSource` that contains feature aliases.
 *      Can return `none` if no source for features was configured or
 *      the configured source is incorrectly defined.
 */
public final function BaseAliasSource GetFeatureSource()
{
    if (featureAliasSource != none) {
        featureAliasSource.NewRef();
    }
    return featureAliasSource;
}

/**
 *  Returns `BaseAliasSource` that is designated in configuration files as
 *  a source for entity aliases.
 *
 *
 *  @return Reference to the `BaseAliasSource` that contains entity aliases.
 *      Can return `none` if no source for entities was configured or
 *      the configured source is incorrectly defined.
 */
public final function BaseAliasSource GetEntitySource()
{
    if (entityAliasSource != none) {
        entityAliasSource.NewRef();
    }
    return entityAliasSource;
}

private final function Text ResolveWithSource(
    BaseText        alias,
    BaseAliasSource source,
    optional bool   copyOnFailure)
{
    local Text result;
    local Text trimmedAlias;

    if (alias == none) {
        return none;
    }
    if (alias.StartsWith(P("$"))) {
        trimmedAlias = alias.Copy(1);
    }
    else {
        trimmedAlias = alias.Copy();
    }
    if (source != none) {
        result = source.Resolve(trimmedAlias, copyOnFailure);
    }
    else if (copyOnFailure) {
        result = trimmedAlias.Copy();
    }
    trimmedAlias.FreeSelf();
    return result;
}

/**
 *  Tries to look up a value stored for given alias in an `BaseAliasSource`
 *  configured to store weapon aliases.
 *
 *  In Acedia aliases are typically prefixed with '$' to indicate that user
 *  means to enter alias. This method is able to handle both aliases with and
 *  without that prefix. This does not lead to conflicts, because '$' is cannot
 *  be a valid part of any alias.
 *
 *      Lookup of alias can fail if either alias does not exist in weapon alias
 *  source or weapon alias source itself does not exist
 *  (due to either faulty configuration or incorrect definition).
 *      To determine if weapon alias source exists you can check
 *  `_.alias.GetWeaponSource()` value.
 *
 *  @param  alias           Alias, for which method will attempt to
 *      look up a value. Case-insensitive.
 *  @param  copyOnFailure   Whether method should return copy of original
 *      `alias` value in case caller source did not have any records
 *      corresponding to `alias`. If `alias` was specified with '$' prefix -
 *      it will be discarded.
 *  @return If look up was successful - value, associated with the given
 *      alias `alias`. If lookup was unsuccessful, it depends on `copyOnFailure`
 *      flag: `copyOnFailure == false` means method will return `none`
 *      and `copyOnFailure == true` means method will return `alias.Copy()`.
 *      If `alias == none` method always returns `none`.
 */
public final function Text ResolveWeapon(
    BaseText        alias,
    optional bool   copyOnFailure)
{
    return ResolveWithSource(alias, weaponAliasSource, copyOnFailure);
}

/**
 *  Tries to look up a value stored for given alias in an `BaseAliasSource`
 *  configured to store color aliases.
 *
 *  In Acedia aliases are typically prefixed with '$' to indicate that user
 *  means to enter alias. This method is able to handle both aliases with and
 *  without that prefix. This does not lead to conflicts, because '$' is cannot
 *  be a valid part of any alias.
 *
 *      Lookup of alias can fail if either alias does not exist in color alias
 *  source or color alias source itself does not exist
 *  (due to either faulty configuration or incorrect definition).
 *      To determine if color alias source exists you can check
 *  `_.alias.GetColorSource()` value.
 *
 *  @param  alias           Alias, for which method will attempt to
 *      look up a value. Case-insensitive.
 *  @param  copyOnFailure   Whether method should return copy of original
 *      `alias` value in case caller source did not have any records
 *      corresponding to `alias`. If `alias` was specified with '$' prefix -
 *      it will be discarded.
 *  @return If look up was successful - value, associated with the given
 *      alias `alias`. If lookup was unsuccessful, it depends on `copyOnFailure`
 *      flag: `copyOnFailure == false` means method will return `none`
 *      and `copyOnFailure == true` means method will return `alias.Copy()`.
 *      If `alias == none` method always returns `none`.
 */
public final function Text ResolveColor(
    BaseText        alias,
    optional bool   copyOnFailure)
{
    return ResolveWithSource(alias, colorAliasSource, copyOnFailure);
}

/**
 *  Tries to look up a value stored for given alias in an `BaseAliasSource`
 *  configured to store feature aliases.
 *
 *  In Acedia aliases are typically prefixed with '$' to indicate that user
 *  means to enter alias. This method is able to handle both aliases with and
 *  without that prefix. This does not lead to conflicts, because '$' is cannot
 *  be a valid part of any alias.
 *
 *      Lookup of alias can fail if either alias does not exist in feature alias
 *  source or feature alias source itself does not exist
 *  (due to either faulty configuration or incorrect definition).
 *      To determine if feature alias source exists you can check
 *  `_.alias.GetFeatureSource()` value.
 *
 *  @param  alias           Alias, for which method will attempt to
 *      look up a value. Case-insensitive.
 *  @param  copyOnFailure   Whether method should return copy of original
 *      `alias` value in case caller source did not have any records
 *      corresponding to `alias`. If `alias` was specified with '$' prefix -
 *      it will be discarded.
 *  @return If look up was successful - value, associated with the given
 *      alias `alias`. If lookup was unsuccessful, it depends on `copyOnFailure`
 *      flag: `copyOnFailure == false` means method will return `none`
 *      and `copyOnFailure == true` means method will return `alias.Copy()`.
 *      If `alias == none` method always returns `none`.
 */
public final function Text ResolveFeature(
    BaseText        alias,
    optional bool   copyOnFailure)
{
    return ResolveWithSource(alias, featureAliasSource, copyOnFailure);
}

/**
 *  Tries to look up a value stored for given alias in an `BaseAliasSource`
 *  configured to store entity aliases.
 *
 *  In Acedia aliases are typically prefixed with '$' to indicate that user
 *  means to enter alias. This method is able to handle both aliases with and
 *  without that prefix. This does not lead to conflicts, because '$' is cannot
 *  be a valid part of any alias.
 *
 *      Lookup of alias can fail if either alias does not exist in entity alias
 *  source or entity alias source itself does not exist
 *  (due to either faulty configuration or incorrect definition).
 *      To determine if entity alias source exists you can check
 *  `_.alias.GetEntitySource()` value.
 *
 *  @param  alias           Alias, for which method will attempt to
 *      look up a value. Case-insensitive.
 *  @param  copyOnFailure   Whether method should return copy of original
 *      `alias` value in case caller source did not have any records
 *      corresponding to `alias`. If `alias` was specified with '$' prefix -
 *      it will be discarded.
 *  @return If look up was successful - value, associated with the given
 *      alias `alias`. If lookup was unsuccessful, it depends on `copyOnFailure`
 *      flag: `copyOnFailure == false` means method will return `none`
 *      and `copyOnFailure == true` means method will return `alias.Copy()`.
 *      If `alias == none` method always returns `none`.
 */
public final function Text ResolveEntity(
    BaseText        alias,
    optional bool   copyOnFailure)
{
    return ResolveWithSource(alias, entityAliasSource, copyOnFailure);
}

/**
 *  Tries to look up a value stored for given alias in a custom alias source
 *  with a given name `sourceName`.
 *
 *  In Acedia aliases are typically prefixed with '$' to indicate that user
 *  means to enter alias. This method is able to handle both aliases with and
 *  without that prefix. This does not lead to conflicts, because '$' is cannot
 *  be a valid part of any alias.
 *
 *  Custom alias sources are any type of alias source that isn't built-in into
 *  Acedia. They can either be added manually by the admin through config file.
 *
 *      Lookup of alias can fail if either alias does not exist in entity alias
 *  source or entity alias source itself does not exist
 *  (due to either faulty configuration or incorrect definition).
 *      To determine if entity alias source exists you can check
 *  `_.alias.GetCustomSource()` value.
 *
 *  @param  alias           Alias, for which method will attempt to
 *      look up a value. Case-insensitive.
 *  @param  copyOnFailure   Whether method should return copy of original
 *      `alias` value in case caller source did not have any records
 *      corresponding to `alias`. If `alias` was specified with '$' prefix -
 *      it will be discarded.
 *  @return If look up was successful - value, associated with the given
 *      alias `alias`. If lookup was unsuccessful, it depends on `copyOnFailure`
 *      flag: `copyOnFailure == false` means method will return `none`
 *      and `copyOnFailure == true` means method will return `alias.Copy()`.
 *      If `alias == none` method always returns `none`.
 */
public final function Text ResolveCustom(
    BaseText        sourceName,
    BaseText        alias,
    optional bool   copyOnFailure)
{
    local BaseAliasSource customSource;

    customSource = GetCustomSource(sourceName);
    if (customSource == none) {
        return none;
    }
    return ResolveWithSource(alias, customSource, copyOnFailure);
}

defaultproperties
{
}