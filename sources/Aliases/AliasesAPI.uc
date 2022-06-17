/**
 *  Provides convenient access to Aliases-related functions.
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
class AliasesAPI extends AcediaObject
    dependson(LoggerAPI);

var private LoggerAPI.Definition noWeaponAliasSource, invalidWeaponAliasSource;
var private LoggerAPI.Definition noColorAliasSource, invalidColorAliasSource;
var private LoggerAPI.Definition noFeatureAliasSource, invalidFeatureAliasSource;

/**
 *  Provides an easier access to the instance of the `AliasSource` of
 *  the given class.
 *
 *  Can fail if `customSourceClass` is incorrectly defined.
 *
 *  @param  customSourceClass   Class of the source we want.
 *  @return Instance of the requested `AliasSource`,
 *      `none` if `customSourceClass` is incorrectly defined.
 */
public final function AliasSource GetCustomSource(
    class<AliasSource> customSourceClass)
{
    return AliasSource(customSourceClass.static.GetInstance(true));
}

/**
 *  Returns `AliasSource` that is designated in configuration files as
 *  a source for weapon aliases.
 *
 *  NOTE: while by default weapon aliases source will contain only weapon
 *  aliases, you should not assume that. Acedia allows admins to store all
 *  the aliases in the same config.
 *
 *  @return Reference to the `AliasSource` that contains weapon aliases.
 *      Can return `none` if no source for weapons was configured or
 *      the configured source is incorrectly defined.
 */
public final function AliasSource GetWeaponSource()
{
    local AliasSource           weaponSource;
    local class<AliasSource>    sourceClass;
    sourceClass = class'AliasService'.default.weaponAliasesSource;
    if (sourceClass == none)
    {
        _.logger.Auto(noWeaponAliasSource);
        return none;
    }
    weaponSource = AliasSource(sourceClass.static.GetInstance(true));
    if (weaponSource == none)
    {
        _.logger.Auto(invalidWeaponAliasSource).ArgClass(sourceClass);
        return none;
    }
    return weaponSource;
}

/**
 *  Returns `AliasSource` that is designated in configuration files as
 *  a source for color aliases.
 *
 *  NOTE: while by default color aliases source will contain only color aliases,
 *  you should not assume that. Acedia allows admins to store all the aliases
 *  in the same config.
 *
 *  @return Reference to the `AliasSource` that contains color aliases.
 *      Can return `none` if no source for colors was configured or
 *      the configured source is incorrectly defined.
 */
public final function AliasSource GetColorSource()
{
    local AliasSource           colorSource;
    local class<AliasSource>    sourceClass;
    sourceClass = class'AliasService'.default.colorAliasesSource;
    if (sourceClass == none)
    {
        _.logger.Auto(noColorAliasSource);
        return none;
    }
    colorSource = AliasSource(sourceClass.static.GetInstance(true));
    if (colorSource == none)
    {
        _.logger.Auto(invalidColorAliasSource).ArgClass(sourceClass);
        return none;
    }
    return colorSource;
}

/**
 *  Returns `AliasSource` that is designated in configuration files as
 *  a source for feature aliases.
 *
 *  NOTE: while by default feature aliases source will contain only feature
 *  aliases, you should not assume that. Acedia allows admins to store all the
 *  aliases in the same config.
 *
 *  @return Reference to the `AliasSource` that contains feature aliases.
 *      Can return `none` if no source for features was configured or
 *      the configured source is incorrectly defined.
 */
public final function AliasSource GetFeatureSource()
{
    local AliasSource           colorSource;
    local class<AliasSource>    sourceClass;
    sourceClass = class'AliasService'.default.colorAliasesSource;
    if (sourceClass == none)
    {
        _.logger.Auto(noColorAliasSource);
        return none;
    }
    colorSource = AliasSource(sourceClass.static.GetInstance(true));
    if (colorSource == none)
    {
        _.logger.Auto(invalidColorAliasSource).ArgClass(sourceClass);
        return none;
    }
    return colorSource;
}

/**
 *  Tries to look up a value stored for given alias in an `AliasSource`
 *  configured to store weapon aliases. Returns `none` on failure.
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
 *      corresponding to `alias`.
 *  @return If look up was successful - value, associated with the given
 *      alias `alias`. If lookup was unsuccessful, it depends on `copyOnFailure`
 *      flag: `copyOnFailure == false` means method will return `none`
 *      and `copyOnFailure == true` means method will return `alias.Copy()`.
 *      If `alias == none` method always returns `none`.
 */
public final function Text ResolveWeapon(
    Text            alias,
    optional bool   copyOnFailure)
{
    local AliasSource source;
    source = GetWeaponSource();
    if (source != none) {
        return source.Resolve(alias, copyOnFailure);
    }
    return none;
}

/**
 *  Tries to look up a value stored for given alias in an `AliasSource`
 *  configured to store color aliases. Reports error on failure.
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
 *      corresponding to `alias`.
 *  @return If look up was successful - value, associated with the given
 *      alias `alias`. If lookup was unsuccessful, it depends on `copyOnFailure`
 *      flag: `copyOnFailure == false` means method will return `none`
 *      and `copyOnFailure == true` means method will return `alias.Copy()`.
 *      If `alias == none` method always returns `none`.
 */
public final function Text ResolveColor(Text alias, optional bool copyOnFailure)
{
    local AliasSource source;
    source = GetColorSource();
    if (source != none) {
        return source.Resolve(alias, copyOnFailure);
    }
    return none;
}

/**
 *  Tries to look up a value stored for given alias in an `AliasSource`
 *  configured to store feature aliases. Reports error on failure.
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
 *      corresponding to `alias`.
 *  @return If look up was successful - value, associated with the given
 *      alias `alias`. If lookup was unsuccessful, it depends on `copyOnFailure`
 *      flag: `copyOnFailure == false` means method will return `none`
 *      and `copyOnFailure == true` means method will return `alias.Copy()`.
 *      If `alias == none` method always returns `none`.
 */
public final function Text ResolveFeature(
    Text            alias,
    optional bool   copyOnFailure)
{
    local AliasSource source;
    source = GetFeatureSource();
    if (source != none) {
        return source.Resolve(alias, copyOnFailure);
    }
    return none;
}

defaultproperties
{
    noWeaponAliasSource         = (l=LOG_Error,m="No weapon aliases source configured for Acedia's alias API. Error is most likely cause by erroneous config.")
    invalidWeaponAliasSource    = (l=LOG_Error,m="`AliasSource` class `%1` is configured to store weapon aliases, but it seems to be invalid. This is a bug and not configuration file problem, but issue might be avoided by using a different `AliasSource`.")
    noColorAliasSource          = (l=LOG_Error,m="No color aliases source configured for Acedia's alias API. Error is most likely cause by erroneous config.")
    invalidColorAliasSource     = (l=LOG_Error,m="`AliasSource` class `%1` is configured to store color aliases, but it seems to be invalid. This is a bug and not configuration file problem, but issue might be avoided by using a different `AliasSource`.")
    noFeatureAliasSource        = (l=LOG_Error,m="No feature aliases source configured for Acedia's alias API. Error is most likely cause by erroneous config.")
    invalidFeatureAliasSource   = (l=LOG_Error,m="`AliasSource` class `%1` is configured to store feature aliases, but it seems to be invalid. This is a bug and not configuration file problem, but issue might be avoided by using a different `AliasSource`.")
}