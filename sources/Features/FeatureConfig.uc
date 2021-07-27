/**
 *      Acedia's `Feature`s store their configuration in separate classes
 *  derived from this one. They allow to provide `Feature`s with several config
 *  presets and, potentially, swap them on-the-fly.
 *      To create a new config object for a `Feature` use following template:
 *
 *  ```unrealscript
 *  class <FEATURE_NAME> extends FeatureConfig
 *      perobjectconfig
 *  config(<FEATURE_CONFIG>);
 *
 *  // ...
 *
 *  defaultproperties
 *  {
 *      configName = "<FEATURE_CONFIG>"
 *  }
 *  ```
 *
 *  You should only define a new child class, along with implementing it's
 *  `FromData()`, `ToData()` and `DefaultIt()` methods and otherwise avoid
 *  directly using objects of this class.
 *      Copyright 2021 Anton Tarasenko
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
class FeatureConfig extends AcediaObject
    dependson(AssociativeArray)
    abstract;

//  Name of the config object that was marked as "auto enabled".
//  `none` iff none are set to be auto-enabled.
//  Only it's default value is ever used.
var private Text autoEnabledConfig;

//      All config of a particular class only get loaded once per session
//  (unless new one is created) and then accessed through this collection.
//      Only it's default value is ever used.
var private AssociativeArray existingConfigs;

//  Stores name of the config where settings are to be stored.
//  Must correspond to value in `config(...)` modifier in class definition.
var protected string configName;

//      Setting that tells Acedia whether or not to enable feature,
//  corresponding to this config during initialization.
//      Only one version of any specific class should have this flag set to
//  `true`. Otherwise any config with this flag will be picked as "auto enabled"
//  and log warning will be given.
//      Only it's default value is ever used.
var private config bool autoEnable;

var private LoggerAPI.Definition warningMultipleFeaturesAutoEnabled;

/*      These methods must be overloaded to store and load all the config
*   variables inside an `AssociativeArray` collection. How exactly to store
*   them is up to each `Feature` to decide, as long as it allows conversion into
*   JSON (see `JSONAPI.IsCompatible()` for details). Note, however, that boxes
*   can value boxes and references should be considered interchangeable.
*   For example, even if you always save `int` value as a `IntRef` in
*   `ToData()` method, it might be stored as `IntBox` in `FromData()` call.
*   And vice versa.
*       NOTE: DO NOT use `P()`, `C()`, `F()` or `T()` methods for keys or
*   values in collections you return. All keys and values will be automatically
*   deallocated when necessary, so these methods for creating `Text` values are
*   not suitable.
*/
protected function AssociativeArray ToData() { return none; }
protected function FromData(AssociativeArray source) {}

/**
 *  This method must be overloaded to setup default values for all config
 *  variables. You should use it instead of the `defaultproperties` block.
 */
protected function DefaultIt() {}

/**
 *  This loads all of the `FeatureConfig`'s settings objects into internal
 *  arrays. Must be called before any other methods.
 */
public static final function Initialize()
{
    local int           i;
    local Text          nextName;
    local FeatureConfig nextConfig;
    local array<string> names;
    if (default.existingConfigs != none) {
        return;
    }
    default.autoEnabledConfig = none;
    default.existingConfigs = __().collections.EmptyAssociativeArray();
    names = GetPerObjectNames(  default.configName, string(default.class.name),
                                MaxInt);
    for (i = 0; i < names.length; i += 1)
    {
        if (names[i] == "") {
            continue;
        }
        nextName    = __().text.FromString(names[i]);
        nextConfig  = new(none, nextName.ToPlainString()) default.class;
        default.existingConfigs.SetItem(nextName.LowerCopy(), nextConfig);
        if (nextConfig.autoEnable)
        {
            if (default.autoEnabledConfig == none)
            {
                default.autoEnabledConfig = nextName;
                continue;
            }
            else
            {
                __().logger
                    .Auto(default.warningMultipleFeaturesAutoEnabled)
                    .ArgClass(default.class)
                    .Arg(default.autoEnabledConfig.Copy());
            }
        }
        nextName.FreeSelf();
    }
}

/**
 *  Returns name of the config object that is configured to be used for
 *  auto-enabled `Feature`.
 *
 *  @return Name of the config object (case-insensitive), configured to be used
 *      for auto-enabled `Feature`. `none` if either class of the caller config
 *      object was not initialized or no config object was set to be used
 *      as auto-enabled.
 */
public static function Text GetAutoEnabledConfig()
{
    if (default.autoEnabledConfig != none) {
        return default.autoEnabledConfig.Copy();
    }
    return none;
}

/**
 *  Sets (by name) config object to be used when it's corresponding `Feature`
 *  is auto-enabled.
 *
 *  @param  autoEnabledConfigName   Name (case-insensitive) of the config to
 *      be used when it's corresponding `Feature` is auto-enabled.
 *      Passing `none` or name of non-existing config will prevent it's
 *      `Feature` in question from being auto-enabled at all.
 *  @return `true` iff some config was set to be used when it's `Feature` is
 *      auto-enabled, even if the same config was already configured to be used.
 */
public static function bool SetAutoEnabledConfig(Text autoEnabledConfigName)
{
    local Iter          I;
    local bool          wasAutoEnabled;
    local bool          enabledConfig;
    local Text          nextConfigName;
    local FeatureConfig nextConfig;
    if (default.existingConfigs == none) {
        return false;
    }
    I = default.existingConfigs.Iterate();
    for (I = default.existingConfigs.Iterate(); !I.HasFinished(); I.Next(true))
    {
        nextConfigName  = Text(I.GetKey());
        nextConfig      = FeatureConfig(I.Get());
        wasAutoEnabled  = nextConfig.autoEnable;
        if (nextConfigName.Compare(autoEnabledConfigName, SCASE_INSENSITIVE))
        {
            default.autoEnabledConfig = autoEnabledConfigName.LowerCopy();
            nextConfig.autoEnable = true;
            enabledConfig = true;
        }
        else {
            nextConfig.autoEnable = false;
        }
        if (wasAutoEnabled != nextConfig.autoEnable) {
            nextConfig.SaveConfig();
        }
    }
    return enabledConfig;
}

/**
 *  Returns array containing names of all available config objects.
 *
 *  @return Array with names of all available config objects.
 */
public static function array<Text> AvailableConfigs()
{
    local array<Text> emptyResult;
    if (default.existingConfigs != none) {
        return default.existingConfigs.CopyTextKeys();
    }
    return emptyResult;
}

/**
 *  Loads Acedia's representation of settings data of a particular config
 *  object, given by the `name`.
 *
 *  @param  name    Name of the config object, whos settings data is to
 *      be loaded.
 *  @return Settings data of a particular config object, given by the `name`.
 *      Expected to be in format that allows for JSON serialization
 *      (see `JSONAPI.IsCompatible()` for details).
 *      For correctly implemented config objects should only return `none` if
 *      their class was not yet initialized (see `self.Initialize()` method).
*/
public final static function AssociativeArray LoadData(Text name)
{
    local AssociativeArray  result;
    local FeatureConfig     requiredConfig;
    if (default.existingConfigs == none) {
        return none;
    }
    if (name != none) {
        name = name.LowerCopy();
    }
    requiredConfig = FeatureConfig(default.existingConfigs.GetItem(name));
    if (requiredConfig != none) {
        result = requiredConfig.ToData();
    }
    __().memory.Free(name);
    return result;
}

/**
 *  Saves Acedia's representation of settings data (`data`) for a particular
 *  config object, given by the `name`.
 *
 *  @param  name    Name of the config object, whos settings data is to
 *      be modified.
 *  @param  data    New data for config variables. Expected to be in format that
 *      allows for JSON deserialization (see `JSONAPI.IsCompatible()` for
 *      details).
*/
public final static function SaveData(Text name, AssociativeArray data)
{
    local FeatureConfig requiredConfig;
    if (name != none) {
        name = name.LowerCopy();
    }
    if (default.existingConfigs != none) {
        requiredConfig = FeatureConfig(default.existingConfigs.GetItem(name));
    }
    if (requiredConfig != none)
    {
        requiredConfig.FromData(data);
        requiredConfig.SaveConfig();
    }
    __().memory.Free(name);
}

/**
 *  Creates a brand new config object with a given name.
 *
 *  Fails if config object with that name already exists.
 *  Names are case-insensitive.
 *
 *  @param  name    Name of the new config object.
 *  @return `true` iff new config object was created.
*/
public final static function bool NewConfig(Text name)
{
    local FeatureConfig oldConfig, newConfig;
    if (name == none)                       return false;
    if (default.existingConfigs == none)    return false;
    oldConfig = FeatureConfig(default.existingConfigs.GetItem(name));
    if (oldConfig != none)                  return false;

    newConfig = new(none, name.ToPlainString()) default.class;
    newConfig.DefaultIt();
    newConfig.SaveConfig();
    default.existingConfigs.SetItem(name.LowerCopy(), newConfig);
    return true;
}

/**
 *  Deletes config object with a given name.
 *  Names are case-insensitive.
 *
 *  If given config object exists, this method cannot fail.
 *
 *  @param  name    Name of the config object to delete.
*/
public final static function DeleteConfig(Text name)
{
    local AssociativeArray.Entry entry;
    if (default.existingConfigs == none) {
        return;
    }
    entry = default.existingConfigs.TakeEntry(name);
    if (entry.value != none) {
        entry.value.ClearConfig();
    }
    __().memory.Free(entry.value);
    __().memory.Free(entry.key);
}

defaultproperties
{
    usesObjectPool  = false
    autoEnable      = false
    warningMultipleFeaturesAutoEnabled = (l=LOG_Warning,m="Multiple configs for `%1` were marked as \"auto enabled\". This is likely caused by an erroneous config. \"%2\" config will be used.")
}