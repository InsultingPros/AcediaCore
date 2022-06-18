/**
 *      Feature represents a certain subset of Acedia's functionality that
 *  can be enabled or disabled, according to server owner's wishes.
 *  In the current version of Acedia enabling or disabling a feature requires
 *  manually editing configuration file and restarting a server.
 *      Creating a `Feature` instance should be done by using
 *  `EnableMe()` / `DisableMe()` methods; instead of regular `Constructor()`
 *  and `Finalizer()` one should use `OnEnabled() and `OnDisabled()` methods.
 *  Any instances created through other means will be automatically deallocated,
 *  enforcing `Singleton`-like behavior for the `Feature` class.
 *      `Feature`s store their configuration in a different object
 *  `FeatureConfig`, that uses per-object-config and allows users to define
 *  several different versions of `Feature`'s settings. Each `Feature` must be
 *  in 1-to-1 relationship with one sub-class of `FeatureConfig`, that should be
 *  defined in `configClass` variable.
 *      Copyright 2019 - 2021 Anton Tarasenko
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

//      Default value of this variable will store one and only existing version
//  of `Feature` of this class.
var private Feature activeInstance;
var private int     activeInstanceLifeVersion;

//      Variables that store name and data from the config object that was
//  chosen for this `Feature`.
//      Data is expected to be in format that allows for JSON deserialization
//  (see `JSONAPI.IsCompatible()` for details).
var private Text                currentConfigName;
var private AssociativeArray    currentConfig;

//  Class of this `Feature`'s config objects. Classes must be in 1-to-1
//  correspondence.
var public const class<FeatureConfig> configClass;

//      Setting default value of this variable to 'true' prevents creation of
//  a `Feature`, even if no instances of it exist. This is used to ensure active
//  `Feature`s can only be created through the proper means and behave like
//  singletons.
//      Only a default value is ever used.
var protected bool blockSpawning;

//      Setting that tells Acedia whether or not to enable this feature
//  during initialization.
//      Only it's default value is ever used.
var private config bool autoEnable;

//  `Service` that will be launched and shut down along with this `Feature`.
//  One should never launch or shut down this service manually.
var protected const class<FeatureService> serviceClass;

var private string defaultConfigName;

var private LoggerAPI.Definition errorBadConfigData;

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

protected function Constructor()
{
    local FeatureService myService;
    if (default.blockSpawning)
    {
        FreeSelf();
        return;
    }
    if (serviceClass != none) {
        myService = FeatureService(serviceClass.static.Require());
    }
    if (myService != none) {
        myService.SetOwnerFeature(self);
    }
    currentConfigName = none;
    ApplyConfig(default.currentConfigName);
    _.memory.Free(default.currentConfigName);
    default.currentConfigName = none;
    OnEnabled();
}

protected function Finalizer()
{
    local FeatureService service;
    if (GetInstance() != self) {
        return;
    }
    OnDisabled();
    if (serviceClass != none) {
        service = FeatureService(serviceClass.static.GetInstance());
    }
    if (service != none) {
        service.Destroy();
    }
    if (currentConfig != none) {
        currentConfig.Empty(true);
    }
    _.memory.Free(currentConfigName);
    _.memory.Free(currentConfig);
    default.currentConfigName   = none;
    currentConfigName           = none;
    currentConfig               = none;
    default.activeInstance = none;
}

/**
 *  Changes config for the caller `Feature` class.
 *
 *  This method should only be called when caller `Feature` is enabled
 *  (allocated). To set initial config on this `Feature`'s start - specify it
 *  as a parameter to `EnableMe()` method.
 *
 *  Method will do nothing if `newConfigName` parameter is set to `none`.
 *
 *  @param  newConfigName   Name of the config to apply to the caller `Feature`.
 */
private final function ApplyConfig(BaseText newConfigName)
{
    local Text          configNameCopy;
    local FeatureConfig newConfig;
    if (newConfigName == none) {
        return;
    }
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
 *      this method (i.e. `class'MyFunFeature'.static.GetInstance()`).
 *      `none` if particular `Feature` in question is not currently active.
 */
public final static function Feature GetInstance()
{
    if (default.activeInstance == none) {
        return none;
    }
    if (    default.activeInstance.GetLifeVersion()
        !=  default.activeInstanceLifeVersion)
    {
        default.activeInstance = none;
        return none;
    }
    return default.activeInstance;
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
    local Feature myInstance;
    myInstance = GetInstance();
    if (myInstance == none)                     return none;
    if (myInstance.currentConfigName == none)   return none;

    return myInstance.currentConfigName.Copy();
}

/**
 *  Checks whether caller `Feature` is currently enabled.
 *
 *  @return `true` if caller `Feature` is currently enabled and
 *      `false` otherwise.
 */
public static final function bool IsEnabled()
{
    return (GetInstance() != none); 
}

/**
 *  Enables the feature and returns it's active instance.
 *
 *  Does nothing if passed `configName` is `none`.
 *
 *  Cannot fail as long as `configName != none`. Any checks on whether it's
 *  appropriate to enable `Feature` must be done separately, before calling
 *  this method.
 *
 *  If `Feature` is already enabled - changes its config to `configName`
 *  (unless it's `none`).
 *
 *  @param  configName  Name of the config to use for this `Feature`.
 *      Passing `none` will make caller `Feature` use "default" config.
 *  @return Active instance of the caller `Feature` class.
 */
public static final function Feature EnableMe(BaseText configName)
{
    local Feature myInstance;
    if (configName == none) {
        return none;
    }
    myInstance = GetInstance();
    if (myInstance != none)
    {
        myInstance.ApplyConfig(configName);
        return myInstance;
    }
    default.currentConfigName = configName.Copy();
    default.blockSpawning = false;
    myInstance = Feature(__().memory.Allocate(default.class));
    default.activeInstance              = myInstance;
    default.activeInstanceLifeVersion   = myInstance.GetLifeVersion();
    default.blockSpawning = true;
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
    local Feature myself;
    myself = GetInstance();
    if (myself != none)
    {
        myself.FreeSelf();
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
    autoEnable      = false
    blockSpawning   = true
    configClass     = none
    serviceClass    = none

    defaultConfigName = "default"

    errorBadConfigData = (l=LOG_Error,m="Bad config value was provided for `%1`. Falling back to the \"default\".")
}