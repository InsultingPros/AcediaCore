/**
 *      Acedia's `Feature`s store their configuration in separate classes
 *  derived from this one. They allow to provide `Feature`s with several config
 *  presets and, potentially, swap them on-the-fly.
 *      Difference from regular `AcediaConfig` is that `FeatureConfig` can
 *  determine with what settings (if any) each feature should start
 *  (be auto-enabled).
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
class FeatureConfig extends AcediaConfig
    dependson(LoggerAPI)
    abstract;

//  Name of the config object that was marked as "auto enabled".
//  `none` iff none are set to be auto-enabled.
//  Only it's default value is ever used.
var private Text autoEnabledConfig;

//      Setting that tells Acedia whether or not to enable feature,
//  corresponding to this config during initialization.
//      Only one version of any specific class should have this flag set to
//  `true`. Otherwise any config with this flag will be picked as "auto enabled"
//  and log warning will be given.
//      Only it's default value is ever used.
var private config bool autoEnable;

var private LoggerAPI.Definition warningMultipleFeaturesAutoEnabled;

public static function Initialize()
{
    local int           i;
    local array<Text>   names;
    local FeatureConfig nextConfig;
    super.Initialize();
    //  Load every config, find the auto-enabled one
    default.autoEnabledConfig = none;
    names = AvailableConfigs();
    for (i = 0; i < names.length; i += 1)
    {
        nextConfig = FeatureConfig(GetConfigInstance(names[i]));
        if (nextConfig == none)     continue;
        if (!nextConfig.autoEnable) continue;
        if (default.autoEnabledConfig == none) {
            default.autoEnabledConfig = names[i].Copy();
        }
        else
        {
            __().logger
                .Auto(default.warningMultipleFeaturesAutoEnabled)
                .ArgClass(default.class)
                .Arg(default.autoEnabledConfig.Copy());
        }
    }
    __().memory.FreeMany(names);
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
public static function bool SetAutoEnabledConfig(BaseText autoEnabledConfigName)
{
    local int           i;
    local array<Text>   names;
    local bool          wasAutoEnabled;
    local bool          enabledSomeConfig;
    local FeatureConfig nextConfig;

    __().memory.Free(default.autoEnabledConfig);
    default.autoEnabledConfig = none;
    names = AvailableConfigs();
    for (i = 0; i < names.length; i += 1)
    {
        nextConfig = FeatureConfig(GetConfigInstance(names[i]));
        if (nextConfig == none) {
            continue;
        }
        wasAutoEnabled  = nextConfig.autoEnable;
        if (names[i].Compare(autoEnabledConfigName, SCASE_INSENSITIVE))
        {
            default.autoEnabledConfig = autoEnabledConfigName.Copy();
            nextConfig.autoEnable = true;
            enabledSomeConfig = true;
        }
        else {
            nextConfig.autoEnable = false;
        }
        if (wasAutoEnabled != nextConfig.autoEnable) {
            nextConfig.SaveConfig();
        }
    }
    __().memory.FreeMany(names);
    return enabledSomeConfig;
}

defaultproperties
{
    usesObjectPool  = false
    autoEnable      = false
    warningMultipleFeaturesAutoEnabled = (l=LOG_Warning,m="Multiple configs for `%1` were marked as \"auto enabled\". This is likely caused by an erroneous config. \"%2\" config will be used.")
}