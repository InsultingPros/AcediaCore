/**
 *      This feature provides a mechanism to define commands that automatically
 *  parse their arguments into standard Acedia collection. It also allows to
 *  manage them (and specify limitation on how they can be called) in a
 *  centralized manner.
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
class Aliases_Feature extends Feature
    dependson(Aliases);

struct ClassSourcePair
{
    var class<AliasSource>  class;
    var AliasSource         source;
};
//  We don't want to reload `AliasSource`s several times when this feature is
//  disabled and re-enabled or its config is swapped, so we keep all loaded
//  sources here at all times and look them up from here
var private array<ClassSourcePair> loadedSources;

//  Loaded `AliasSource`s
var private AliasSource weaponAliasSource;
var private AliasSource colorAliasSource;
var private AliasSource featureAliasSource;
var private AliasSource entityAliasSource;
//  Everything else
var private HashTable   customSources;

var private LoggerAPI.Definition errCannotLoadAliasSource, errEmptyName;
var private LoggerAPI.Definition errDuplicateCustomSource;

protected function OnEnabled()
{
    _.alias._reloadSources();
}

protected function OnDisabled()
{
    DropSources();
    _.alias._reloadSources();
}

private function DropSources()
{
    _.memory.Free(weaponAliasSource);
    weaponAliasSource = none;
    _.memory.Free(colorAliasSource);
    colorAliasSource = none;
    _.memory.Free(featureAliasSource);
    featureAliasSource = none;
    _.memory.Free(entityAliasSource);
    entityAliasSource = none;
    _.memory.Free(customSources);
    customSources = none;
}

//      Create each `AliasSource` instance only once to avoid any possible
//  nonsense with loading named objects several times: alias sources don't use
//  `AcediaConfig`s, so they don't automatically avoid named config reloading
private function AliasSource GetSource(class<AliasSource> sourceClass)
{
    local int               i;
    local AliasSource       newSource;
    local ClassSourcePair   newPair;

    if (sourceClass == none) {
        return none;
    }
    for (i = 0; i < loadedSources.length; i += 1)
    {
        if (loadedSources[i].class == sourceClass) {
            return loadedSources[i].source;
        }
    }
    newSource = AliasSource(_.memory.Allocate(sourceClass));
    if (newSource != none)
    {
        newPair.class = sourceClass;
        newPair.source = newSource;
        //  One reference we store, one we return
        newSource.NewRef();
    }
    else {
        _.logger.Auto(errCannotLoadAliasSource).ArgClass(sourceClass);
    }
    return newSource;
}

protected function SwapConfig(FeatureConfig config)
{
    local Aliases newConfig;

    newConfig = Aliases(config);
    if (newConfig == none) {
        return;
    }
    _.memory.Free(weaponAliasSource);
    DropSources();
    weaponAliasSource   = GetSource(newConfig.weaponAliasSource);
    colorAliasSource    = GetSource(newConfig.colorAliasSource);
    featureAliasSource  = GetSource(newConfig.featureAliasSource);
    entityAliasSource   = GetSource(newConfig.entityAliasSource);
    LoadCustomSources(newConfig.customSource);
    _.alias._reloadSources();
}

private function LoadCustomSources(
    array<Aliases.CustomSourceRecord> configCustomSources)
{
    local int           i;
    local bool          reportedEmptyName;
    local Text          nextKey;
    local AliasSource   nextSource, conflictingSource;

    _.memory.Free(customSources);
    customSources = _.collections.EmptyHashTable();
    for (i = 0; i < configCustomSources.length; i += 1)
    {
        if (configCustomSources[i].name == "" && !reportedEmptyName)
        {
            reportedEmptyName = true;
            _.logger.Auto(errEmptyName);
        }
        nextKey = _.text.FromString(configCustomSources[i].name);
        //  We only store `AliasSource`s
        conflictingSource = AliasSource(customSources.GetItem(nextKey));
        if (conflictingSource != none)
        {
            _.logger.Auto(errDuplicateCustomSource)
                .ArgClass(conflictingSource.class)
                .Arg(nextKey)   //  Releases `nextKey`
                .ArgClass(configCustomSources[i].source);
            conflictingSource.FreeSelf();
            continue;
        }
        nextSource = GetSource(configCustomSources[i].source);
        if (nextSource != none)
        {
            customSources.SetItem(nextKey, nextSource);
            nextSource.FreeSelf();
        }
        nextKey.FreeSelf();
    }
}

/**
 *  Returns `AliasSource` for weapon aliases.
 *
 *  @return `AliasSource`, configured to store weapon aliases.
 */
public function AliasSource GetWeaponSource()
{
    if (weaponAliasSource != none) {
        weaponAliasSource.Newref();
    }
    return weaponAliasSource;
}

/**
 *  Returns `AliasSource` for color aliases.
 *
 *  @return `AliasSource`, configured to store color aliases.
 */
public function AliasSource GetColorSource()
{
    if (colorAliasSource != none) {
        colorAliasSource.Newref();
    }
    return colorAliasSource;
}

/**
 *  Returns `AliasSource` for feature aliases.
 *
 *  @return `AliasSource`, configured to store feature aliases.
 */
public function AliasSource GetFeatureSource()
{
    if (featureAliasSource != none) {
        featureAliasSource.Newref();
    }
    return featureAliasSource;
}

/**
 *  Returns `AliasSource` for entity aliases.
 *
 *  @return `AliasSource`, configured to store entity aliases.
 */
public function AliasSource GetEntitySource()
{
    if (entityAliasSource != none) {
        entityAliasSource.Newref();
    }
    return entityAliasSource;
}

/**
 *  Returns custom `AliasSource` with a given name.
 *
 *  @return Custom `AliasSource`, configured with a given name `sourceName`.
 */
public function AliasSource GetCustomSource(BaseText sourceName)
{
    if (sourceName == none) {
        return none;
    }
    //  We only store `AliasSource`s
    return AliasSource(customSources.GetItem(sourceName));
}

/**
 *  Returns custom `AliasSource` with a given name `sourceName.
 *
 *  @return Custom `AliasSource`, configured with a given name `sourceName`.
 */
public function AliasSource GetCustomSource_S(string sourceName)
{
    local Text          wrapper;
    local AliasSource   result;

    wrapper = _.text.FromString(sourceName);
    result = GetCustomSource(wrapper);
    wrapper.FreeSelf();
    return result;
}

defaultproperties
{
    configClass = class'Aliases'
    errEmptyName                = (l=LOG_Error,m="Empty name provided for the custom alias source. This is likely due to an erroneous config.")
    errCannotLoadAliasSource    = (l=LOG_Error,m="Failed to load alias source class `%1`.")
    errDuplicateCustomSource    = (l=LOG_Error,m="Custom alias source `%1` is already registered with name '%2'. Alias source `%3` with the same name will be ignored.")
}