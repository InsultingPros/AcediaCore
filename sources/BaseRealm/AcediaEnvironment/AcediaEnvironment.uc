/**
 *  Container for the information about available resources from other packages.
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
class AcediaEnvironment extends AcediaObject;

/**
 *  # `AcediaEnvironment`
 *
 *  Instance of this class will be used by Acedia to manage resources available
 *  from different packages like `Feature`s and such other etc..
 *  This is mostly necessary to implement Acedia loader (and, possibly,
 *  its alternatives) that would load available packages and enable `Feature`s
 *  admin wants to be enabled.
 *
 *  ## Packages
 *
 *  Any package to be used in Acedia should first be *registered* with
 *  `RegisterPackage()` method. Then a manifest class from it will be read and
 *  Acedia will become aware of all the resources that package contains.
 *  Once any of those resources is used, package gets marked as *loaded* and its
 *  *entry object* (if specified) will be created.
 *
 *  ## `Feature`s
 *
 *  Whether `Feature` is enabled is governed by the `AcediaEnvironment` added
 *  into the `Global` class. It is possible to create several `Feature`
 *  instances of the same class instance of each class, but only one can be
 *  considered enabled at the same time.
 */

var private bool acediaShutDown;

var private array< class<_manifest> > availablePackages;
var private array< class<_manifest> > loadedPackages;

var private array< class<Feature> > availableFeatures;
var private array<Feature>          enabledFeatures;
var private array<int>              enabledFeaturesLifeVersions;

var private string manifestSuffix;

var private LoggerAPI.Definition infoRegisteringPackage, infoAlreadyRegistered;
var private LoggerAPI.Definition errNotRegistered, errFeatureAlreadyEnabled;
var private LoggerAPI.Definition warnFeatureAlreadyEnabled;
var private LoggerAPI.Definition errFeatureClassAlreadyEnabled;

var private SimpleSignal                        onShutdownSignal;
var private SimpleSignal                        onShutdownSystemSignal;
var private Environment_FeatureEnabled_Signal   onFeatureEnabledSignal;
var private Environment_FeatureDisabled_Signal  onFeatureDisabledSignal;

protected function Constructor()
{
    //  Always register our core package
    RegisterPackage_S("AcediaCore");
    onShutdownSignal = SimpleSignal(
        _.memory.Allocate(class'SimpleSignal'));
    onShutdownSystemSignal = SimpleSignal(
        _.memory.Allocate(class'SimpleSignal'));
    onFeatureEnabledSignal = Environment_FeatureEnabled_Signal(
        _.memory.Allocate(class'Environment_FeatureEnabled_Signal'));
    onFeatureDisabledSignal = Environment_FeatureDisabled_Signal(
        _.memory.Allocate(class'Environment_FeatureDisabled_Signal'));
}

protected function Finalizer()
{
    _.memory.Free(onShutdownSignal);
    _.memory.Free(onShutdownSystemSignal);
    _.memory.Free(onFeatureEnabledSignal);
    _.memory.Free(onFeatureDisabledSignal);
}

/**
 *  Signal that will be emitted before Acedia shuts down.
 *  At this point all APIs should still exist and function.
 *
 *  [Signature]
 *  void <slot>()
 */
/* SIGNAL */
public final function SimpleSlot OnShutDown(AcediaObject receiver)
{
    return SimpleSlot(onShutdownSignal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted during Acedia shut down. System API use it to
 *  clean up after themselves, so one shouldn't rely on them.
 *
 *  There is no reason to use this signal unless you're reimplementing one of
 *  the APIs. Otherwise you probably want to use `OnShutDown()` signal instead.
 *
 *  [Signature]
 *  void <slot>()
 */
/* SIGNAL */
public final function SimpleSlot OnShutDownSystem(AcediaObject receiver)
{
    return SimpleSlot(onShutdownSystemSignal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted when new `Feature` is enabled.
 *  Emitted after `Feature`'s `OnEnabled()` method was called.
 *
 *  [Signature]
 *  void <slot>(Feature enabledFeature)
 *
 *  @param  enabledFeature  `Feature` instance that was just enabled.
 */
/* SIGNAL */
public final function Environment_FeatureEnabled_Slot OnFeatureEnabled(
    AcediaObject receiver)
{
    return Environment_FeatureEnabled_Slot(
        onFeatureEnabledSignal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted when new `Feature` is disabled.
 *  Emitted after `Feature`'s `OnDisabled()` method was called.
 *
 *  [Signature]
 *  void <slot>(class<Feature> disabledFeatureClass)
 *
 *  @param  disabledFeatureClass    Class of the `Feature` instance that was
 *      just disabled.
 */
/* SIGNAL */
public final function Environment_FeatureDisabled_Slot OnFeatureDisabled(
    AcediaObject receiver)
{
    return Environment_FeatureDisabled_Slot(
        onFeatureEnabledSignal.NewSlot(receiver));
}

/**
 *  Shuts AcediaCore down, performing all the necessary cleaning up.
 */
public final function Shutdown()
{
    local LevelCore core;
    if (acediaShutDown) {
        return;
    }
    DisableAllFeatures();
    onShutdownSignal.Emit();
    onShutdownSystemSignal.Emit();
    core = class'ServerLevelCore'.static.GetInstance();
    if (core != none) {
        core.Destroy();
    }
    core = class'ClientLevelCore'.static.GetInstance();
    if (core != none) {
        core.Destroy();
    }
    acediaShutDown = true;
}

/**
 *  Registers an Acedia package with name given by `packageName`.
 *
 *  @param  packageName Name of the package to register. Must not be `none`.
 *      This package must exist and not have yet been registered in this
 *      environment.
 *  @return `true` if package was successfully registered, `false` if it
 *      either does not exist, was already registered or `packageName` is
 *      `none`.
 */
public final function bool RegisterPackage(BaseText packageName)
{
    local class<_manifest> manifestClass;

    if (packageName == none) {
        return false;
    }
    _.logger.Auto(infoRegisteringPackage).Arg(packageName.Copy());
    manifestClass = class<_manifest>(DynamicLoadObject(
        packageName.ToString() $ manifestSuffix, class'Class', true));
    if (manifestClass == none)
    {
        _.logger.Auto(errNotRegistered).Arg(packageName.Copy());
        return false;
    }
    if (IsManifestRegistered(manifestClass))
    {
        _.logger.Auto(infoAlreadyRegistered).Arg(packageName.Copy());
        return false;
    }
    availablePackages[availablePackages.length] = manifestClass;
    ReadManifest(manifestClass);
    return true;
}

/**
 *  Registers an Acedia package with name given by `packageName`.
 *
 *  @param  packageName Name of the package to register.
 *      This package must exist and not have yet been registered in this
 *      environment.
 *  @return `true` if package was successfully registered, `false` if it
 *      either does not exist or was already registered.
 */
public final function RegisterPackage_S(string packageName)
{
    local Text wrapper;

    wrapper = _.text.FromString(packageName);
    RegisterPackage(wrapper);
    _.memory.Free(wrapper);
}

private final function bool IsManifestRegistered(class<_manifest> manifestClass)
{
    local int i;

    for (i = 0; i < availablePackages.length; i += 1)
    {
        if (manifestClass == availablePackages[i]) {
            return true;
        }
    }
    return false;
}

private final function ReadManifest(class<_manifest> manifestClass)
{
    local int i;

    for (i = 0; i < manifestClass.default.features.length; i += 1)
    {
        if (manifestClass.default.features[i] == none) {
            continue;
        }
        manifestClass.default.features[i].static.LoadConfigs();
        availableFeatures[availableFeatures.length] =
            manifestClass.default.features[i];
    }
    for (i = 0; i < manifestClass.default.testCases.length; i += 1)
    {
        class'TestingService'.static
            .RegisterTestCase(manifestClass.default.testCases[i]);
    }
}

/**
 *  Returns all packages registered in the caller `AcediaEnvironment`.
 *
 *  NOTE: package being registered doesn't mean it's actually loaded.
 *  Package must either be explicitly loaded or automatically when one of its
 *  resources is being used.
 *
 *  @return All packages registered in caller `AcediaEnvironment`.
 */
public final function array< class<_manifest> > GetAvailablePackages()
{
    return availablePackages;
}

/**
 *  Returns all packages loaded in the caller `AcediaEnvironment`.
 *
 *  NOTE: package being registered doesn't mean it's actually loaded.
 *  Package must either be explicitly loaded or automatically when one of its
 *  resources is being used.
 *
 *  @return All packages loaded in caller `AcediaEnvironment`.
 */
public final function array< class<_manifest> > GetLoadedPackages()
{
    return loadedPackages;
}

/**
 *  Returns all `Feature`s available in the caller `AcediaEnvironment`.
 *
 *  @return All `Feature`s available in the caller `AcediaEnvironment`.
 */
public final function array< class<Feature> > GetAvailableFeatures()
{
    return availableFeatures;
}

/**
 *  Returns all `Feature` instances enabled in the caller `AcediaEnvironment`.
 *
 *  @return All `Feature`s enabled in the caller `AcediaEnvironment`.
 */
public final function array<Feature> GetEnabledFeatures()
{
    local int i;
    for (i = 0; i < enabledFeatures.length; i += 1) {
        enabledFeatures[i].NewRef();
    }
    return enabledFeatures;
}

//  CleanRemove `Feature`s that got deallocated.
//  This shouldn't happen unless someone messes up.
private final function CleanEnabledFeatures()
{
    local int i;
    while (i < enabledFeatures.length)
    {
        if (    enabledFeatures[i].GetLifeVersion()
            !=  enabledFeaturesLifeVersions[i])
        {
            enabledFeatures.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
}

/**
 *  Checks if `Feature` of given class `featureClass` is enabled.
 *
 *  NOTE: even if If feature of class `featureClass` is enabled, it's not
 *  necessarily that the instance you have reference to is enabled.
 *      Although unlikely, it is possible that someone spawned another instance
 *  of the same class that isn't considered enabled. If you want to check
 *  whether some particular instance of given class `featureClass` is enabled,
 *  use `IsFeatureEnabled()` method instead.
 *
 *  @param  featureClass    Feature class to check for being enabled.
 *  @return `true` if feature of class `featureClass` is currently enabled and
 *      `false` otherwise.
 */
public final function bool IsFeatureClassEnabled(class<Feature> featureClass)
{
    local int i;
    if (featureClass == none) {
        return false;
    }
    CleanEnabledFeatures();
    for (i = 0; i < enabledFeatures.length; i += 1)
    {
        if (featureClass == enabledFeatures[i].class) {
            return true;
        }
    }
    return false;
}

/**
 *  Checks if given `Feature` instance is enabled.
 *
 *  If you want to check if any instance instance of given class
 *  `classToCheck` is enabled (and not `feature` specifically), use
 *  `IsFeatureClassEnabled()` method instead.
 *
 *  @param  feature Feature instance to check for being enabled.
 *  @return `true` if feature `feature` is currently enabled and
 *      `false` otherwise.
 */
public final function bool IsFeatureEnabled(Feature feature)
{
    local int i;
    if (feature == none)        return false;
    if (!feature.IsAllocated()) return false;

    CleanEnabledFeatures();
    for (i = 0; i < enabledFeatures.length; i += 1)
    {
        if (feature == enabledFeatures[i]) {
            return true;
        }
    }
    return false;
}

/**
 *  Returns enabled `Feature` instance of the given class `featureClass`.
 *
 *  @param  featureClass    Feature class to find enabled instance for.
 *  @return Enabled `Feature` instance of the given class `featureClass`.
 *      If no feature of `featureClass` is enabled, returns `none`.
 */
public final function Feature GetEnabledFeature(class<Feature> featureClass)
{
    local int i;
    if (featureClass == none) {
        return none;
    }
    CleanEnabledFeatures();
    for (i = 0; i < enabledFeatures.length; i += 1)
    {
        if (featureClass == enabledFeatures[i].class)
        {
            enabledFeatures[i].NewRef();
            return enabledFeatures[i];
        }
    }
    return none;
}

/**
 *  Enables given `Feature` instance `newEnabledFeature` with a given config.
 *
 *  @see `Feature::EnableMe()`.
 *
 *  @param  newEnabledFeature   Instance to enable.
 *  @param  configName          Name of the config to enable `newEnabledFeature`
 *      feature with. `none` means "default" config (will be created, if
 *      necessary).
 *  @return `true` if given `newEnabledFeature` was enabled and `false`
 *      otherwise (including if feature of the same class has already been
 *      enabled).
 */
public final function bool EnableFeature(
    Feature     newEnabledFeature,
    BaseText    configName)
{
    local int i;
    if (newEnabledFeature == none)          return false;
    if (!newEnabledFeature.IsAllocated())   return false;

    CleanEnabledFeatures();
    for (i = 0; i < enabledFeatures.length; i += 1)
    {
        if (newEnabledFeature.class == enabledFeatures[i].class)
        {
            if (newEnabledFeature == enabledFeatures[i])
            {
                _.logger
                    .Auto(warnFeatureAlreadyEnabled)
                    .Arg(_.text.FromClass(newEnabledFeature.class));
            }
            else
            {
                _.logger
                    .Auto(errFeatureClassAlreadyEnabled)
                    .Arg(_.text.FromClass(newEnabledFeature.class));
            }
            return false;
        }
    }
    newEnabledFeature.NewRef();
    enabledFeatures[enabledFeatures.length] = newEnabledFeature;
    enabledFeaturesLifeVersions[enabledFeaturesLifeVersions.length] =
        newEnabledFeature.GetLifeVersion();
    newEnabledFeature.EnableInternal(configName);
    onFeatureEnabledSignal.Emit(newEnabledFeature);
    return true;
}

/**
 *  Disables given `Feature` instance `featureToDisable`.
 *
 *  @see `Feature::EnableMe()`.
 *
 *  @param  featureToDisable    Instance to disable.
 *  @return `true` if given `newEnabledFeature` was disabled and `false`
 *      otherwise (including if it already was disabled).
 */
public final function bool DisableFeature(Feature featureToDisable)
{
    local int i;
    if (featureToDisable == none)           return false;
    if (!featureToDisable.IsAllocated())    return false;

    CleanEnabledFeatures();
    for (i = 0; i < enabledFeatures.length; i += 1)
    {
        if (featureToDisable == enabledFeatures[i])
        {
            enabledFeatures.Remove(i, 1);
            enabledFeaturesLifeVersions.Remove(i, 1);
            featureToDisable.DisableInternal();
            onFeatureDisabledSignal.Emit(featureToDisable.class);
            _.memory.Free(featureToDisable);
            return true;
        }
    }
    return false;
}

/**
 *  Disables all currently enabled `Feature`s.
 *
 *  Mainly intended for the clean up when Acedia shuts down.
 */
public final function DisableAllFeatures()
{
    local int               i;
    local array<Feature>    featuresCopy;

    CleanEnabledFeatures();
    featuresCopy = enabledFeatures;
    enabledFeatures.length = 0;
    enabledFeaturesLifeVersions.length = 0;
    for (i = 0; i < enabledFeatures.length; i += 1)
    {
        featuresCopy[i].DisableInternal();
        onFeatureDisabledSignal.Emit(featuresCopy[i].class);
    }
    _.memory.FreeMany(featuresCopy);
}

defaultproperties
{
    manifestSuffix = ".Manifest"
    infoRegisteringPackage          = (l=LOG_Info,m="Registering package \"%1\".")
    infoAlreadyRegistered           = (l=LOG_Info,m="Package \"%1\" is already registered.")
    errNotRegistered                = (l=LOG_Error,m="Package \"%2\" has failed to be registered.")
    warnFeatureAlreadyEnabled       = (l=LOG_Warning,m="Same instance of `Feature` class `%1` is already enabled.")
    errFeatureClassAlreadyEnabled   = (l=LOG_Error,m="Different instance of the same `Feature` class `%1` is already enabled.")
}