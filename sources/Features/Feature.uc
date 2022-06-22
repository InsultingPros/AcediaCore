/**
 *      Features are intended as a replacement for mutators: a certain subset of
 *  functionality that can be enabled or disabled, according to server owner's
 *  wishes.
 *      Copyright 2019 - 2022 Anton Tarasenko
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
class Feature extends AcediaObject
    abstract;

/**
 *  # `Feature`
 *
 *      This class is Acedia's replacement for `Mutators`: a certain subset of
 *  functionality that can be enabled or disabled, according to server owner's
 *  wishes. Unlike `Mutator`s:
 *      * There is not limit for the amount of `Feature`s that can be active
 *          at the same time;
 *      * They also provide built-in ability to have several different configs
 *          that can be swapped during the runtime;
 *      * They can be enabled / disabled during the runtime.
 *  Achieving these points currently comes at the cost of developer having to
 *  perform additional work.
 *
 *  ## Enabling `Feature`
 *
 *      Creating a `Feature` instance should be done by using
 *  `EnableMe()` / `DisableMe()` methods; instead of regular `Constructor()`
 *  and `Finalizer()` one should use `OnEnabled() and `OnDisabled()` methods.
 *  There is nothing preventing you from allocating several more instances,
 *  however only one `Feature` per its class can be considered "enabled" at
 *  the same time. This is governed by `AcediaEnvironment` residing in
 *  the acting `Global` class.
 *
 *  ## Configuration
 *
 *      `Feature`s store their configuration in a different object
 *  `FeatureConfig`, that uses per-object-config and allows users to define
 *  several different versions of `Feature`'s settings. Each `Feature` must be
 *  in 1-to-1 relationship with one sub-class of `FeatureConfig`, that should be
 *  defined in `configClass` variable.
 *
 *  ## Creating new `Feature` classes
 *
 *  To create a new `Feature` one need:
 *      1. Create child class for `Feature` (usual naming scheme
 *          "MyAwesomeThing_Feature") and a child class for feature config
 *          `FeatureConfig` (usual naming scheme is simply "MyAwesomeThing" to 
 *          make config files more readable) and link them by setting
 *          `configClass` variable in `defaultproperties` in your `Feature`
 *          child class.
 *      2. Properly setup `FeatureConfig` (read more in its own documentation);
 *      3. Define `OnEnabled()` / `OnDisabled()` / `SwapConfig()` methods in
 *          a way that accounts for the possibility of them running during
 *          the gameplay (meaning that this must be possible - it can still be
 *          considered a heavy operation and it is allowed to cause lag).
 *          NOTE: `SwapConfig()` is always called just before `OnEnabled()` to
 *          set initial configuration up, so the bulk of `Feature` configuration
 *          can be done there.
 *      4. Implement whatever it is your `Feature` will be doing.
 */

//      Remembers if `EnableMe()` was called to indicate that `DisableMe()`
//  should be called.
var private bool wasEnabled;
//      Variable that store name of the config object that was chosen for this
//  `Feature`.
var private Text currentConfigName;

//  Class of this `Feature`'s config objects.
//  These classes must be in 1-to-1 correspondence.
var public const class<FeatureConfig> configClass;

//  `Service` that will be launched and shut down along with this `Feature`.
//  One should never launch or shut down this `Service` manually.
var protected const class<FeatureService> serviceClass;

var private LoggerAPI.Definition errorBadConfigData;

const defaultConfigName = "default";

protected function Finalizer()
{
    DisableInternal();
    _.memory.Free(currentConfigName);
    currentConfigName = none;
}

/**
 *  Calling this method for `Feature` instance that was added to the `Global`'s
 *  `AcediaEnvironment` will actually enable `Feature`, including calling
 *  `OnEnabled()` method. Otherwise this method will do nothing.
 *
 *  This is internal method, it should not be called manually and neither will
 *  it do anything.
 *
 *  @param  newConfigName   Config name to enable caller `Feature` with.
 */
public final /* internal */ function EnableInternal(BaseText newConfigName)
{
    local FeatureService myService;
    if (wasEnabled)                             return;
    if (!_.environment.IsFeatureEnabled(self))  return;

    wasEnabled = true;
    if (serviceClass != none) {
        myService = FeatureService(serviceClass.static.Require());
    }
    if (myService != none) {
        myService.SetOwnerFeature(self);
    }
    ApplyConfig(newConfigName);
    OnEnabled();
}

/**
 *  Calling this for once enabled `Feature` instance that is no longer added to
 *  the active `Global`'s `AcediaEnvironment` will actually disable `Feature`,
 *  including calling `OnDisabled()` method. Otherwise this method will do
 *  nothing.
 *
 *  This is internal method, it should not be called manually and neither will
 *  it do anything.
 */
public final /* internal */ function DisableInternal()
{
    local FeatureService service;
    if (!wasEnabled)                            return;
    if (_.environment.IsFeatureEnabled(self))   return;

    OnDisabled();
    if (serviceClass != none) {
        service = FeatureService(serviceClass.static.GetInstance());
    }
    if (service != none) {
        service.Destroy();
    }
    _.memory.Free(currentConfigName);
    currentConfigName = none;
    wasEnabled = false;
}

/**
 *  Loads all configs defined for the caller `Feature`'s class into internal
 *  collections.
 *
 *  This method must be called only once, by initialization routines.
 */
public static final function LoadConfigs()
{
    if (default.configClass != none) {
        default.configClass.static.Initialize();
    }
}

/**
 *  Changes config for the caller `Feature` class.
 *
 *  This method should only be called when caller `Feature` is enabled.
 *  To set initial config on this `Feature`'s start - specify it as a parameter
 *  to `EnableMe()` method.
 *
 *  @param  newConfigName   Name of the config to apply to the caller `Feature`.
 *      If `none`, method will use "default" config, creating it if necessary.
 */
private final function ApplyConfig(BaseText newConfigName)
{
    local Text          configNameCopy;
    local FeatureConfig newConfig;
    newConfig =
        FeatureConfig(configClass.static.GetConfigInstance(newConfigName));
    if (newConfig == none)
    {
        _.logger.Auto(errorBadConfigData).ArgClass(class);
        //  Fallback to "default" config
        configNameCopy = _.text.FromString(defaultConfigName);
        configClass.static.NewConfig(configNameCopy);
        newConfig =
            FeatureConfig(configClass.static.GetConfigInstance(configNameCopy));
    }
    else {
        configNameCopy = newConfigName.Copy();
    }
    SwapConfig(newConfig);
    _.memory.Free(currentConfigName);
    currentConfigName = configNameCopy;
}

/**
 *  Returns an instance of the `Feature` of the class used to call
 *  this method.
 *
 *  @return Active `Feature` instance of the class used to call
 *      this method (i.e. `class'MyFunFeature'.static.GetEnabledInstance()`).
 *      `none` if particular `Feature` in question is not currently active.
 */
public final static function Feature GetEnabledInstance()
{
    return __().environment.GetEnabledFeature(default.class);
}

/**
 *  Returns reference to this `Feature`'s `FeatureService`.
 *
 *  @return Reference to this `Feature`'s `FeatureService`.
 *      `none` if caller `Feature` did not set a proper `serviceClass`,
 *      otherwise guaranteed to be not `none`.
 */
public final function Service GetService()
{
    if (serviceClass == none) {
        return none;
    }
    return serviceClass.static.Require();
}

/**
 *  Returns name of the config that is configured to be auto-enabled for
 *  the caller `Feature`.
 *
 *  "Auto-enabled" means that `Feature` must be enabled at the server's start,
 *  unless launcher is instructed to skip it for a particular game mode.
 *
 *  @return Name of the config configured to be auto-enabled for
 *      the caller `Feature`. `none` means `Feature` should not be auto-enabled.
 */
public static final function Text GetAutoEnabledConfig()
{
    return default.configClass.static.GetAutoEnabledConfig();
}

/**
 *  Returns name of the currently enabled config for the caller `Feature`.
 *
 *  @return Name of the currently enabled for the caller `Feature`.
 *      `none` if `Feature` is not currently enabled.
 */
public static final function Text GetCurrentConfig()
{
    local Text      configNameCopy;
    local Feature   myInstance;

    myInstance = GetEnabledInstance();
    if (myInstance == none)                     return none;
    if (myInstance.currentConfigName == none)   return none;

    configNameCopy = myInstance.currentConfigName.Copy();
    __().memory.Free(myInstance);
    return configNameCopy;
}

/**
 *  Checks whether caller `Feature` is currently enabled.
 *
 *  @return `true` if caller `Feature` is currently enabled and
 *      `false` otherwise.
 */
public static final function bool IsEnabled()
{
    return __().environment.IsFeatureClassEnabled(default.class);
}

/**
 *  Enables the feature and returns it's active instance.
 *
 *  Any checks on whether it's appropriate to enable `Feature` must be done
 *  separately, before calling this method.
 *
 *  If `Feature` is already enabled - changes its config to `configName`.
 *
 *  @param  configName  Name of the config to use for this `Feature`.
 *      Passing `none` will make caller `Feature` use "default" config.
 *  @return Active instance of the caller `Feature` class.
 */
public static final function Feature EnableMe(BaseText configName)
{
    local Feature myInstance;
    myInstance = GetEnabledInstance();
    if (myInstance != none)
    {
        myInstance.ApplyConfig(configName);
        return myInstance;
    }
    myInstance = Feature(__().memory.Allocate(default.class));
    __().environment.EnableFeature(myInstance, configName);
    return myInstance;
}

/**
 *  Disables this feature in case it is enabled. Does nothing otherwise.
 *
 *  @return `true` if `Feature` in question was enabled at th moment of
 *      the call and `false` otherwise.
 */
public static final function bool DisableMe()
{
    local Feature myInstance;
    myInstance = GetEnabledInstance();
    if (myInstance != none)
    {
        __().environment.DisableFeature(myInstance);
        __().memory.Free(myInstance);
        return true;
    }
    return false;
}

/**
 *  When using proper methods for enabling a `Feature`,
 *  this method is guaranteed to be called right after it is enabled.
 *
 *  AVOID MANUALLY CALLING IT.
 */
protected function OnEnabled(){}

/**
 *  When using proper methods for enabling a `Feature`,
 *  this method is guaranteed to be called right after it is disabled.
 *
 *  AVOID MANUALLY CALLING IT.
 */
protected function OnDisabled(){}

/**
 *  Will be called whenever caller `Feature` class must change it's config
 *  parameters. This can be done both when the `Feature` is enabled or disabled.
 *
 *  @param  newConfigData   New config that caller `Feature`'s class must use.
 *      We pass `FeatureConfig` value for performance and simplicity reasons,
 *      but to keep Acedia working correctly and in an expected way you
 *      MUST AVOID MODIFYING THIS VALUE IN ANY WAY WHATSOEVER.
 *      Guaranteed to not be `none`.
 *
 *  AVOID MANUALLY CALLING THIS METHOD.
 */
protected function SwapConfig(FeatureConfig newConfig){}

defaultproperties
{
    configClass     = none
    serviceClass    = none
    errorBadConfigData = (l=LOG_Error,m="Bad config value was provided for `%1`. Falling back to the \"default\".")
}