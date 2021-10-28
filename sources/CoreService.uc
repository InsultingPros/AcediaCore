/**
 *      Core service that is always running alongside Acedia framework, must be
 *  created by a launcher.
 *      Used for booting up and shutting down Acedia.
 *      Also used for spawning `Actor`s as the only must-have `Service`.
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
class CoreService extends Service
    dependson(BroadcastEventsObserver);

//  Package's manifest is supposed to always have a name of
//  "<package_name>.Manifest", this variable stores the ".Manifest" part
var private const string manifestSuffix;
//  Classes that will need to do some cleaning before Acedia shuts down
var private array< class<AcediaObject> >    usedObjectClasses;
var private array< class<AcediaActor> >     usedActorClasses;
//  `Singleton`s are handled as a special case and cleaned up after
//  the rest of the classes.
var private array< class<Singleton> >       usedSingletonClasses;

var array<string> packagesToLoad;

var private LoggerAPI.Definition infoLoadingPackage;
var private LoggerAPI.Definition infoBootingUp, infoBootingUpFinished;
var private LoggerAPI.Definition infoShuttingDown;
var private LoggerAPI.Definition errorNoManifest, errorCannotRunTests;

//  We do not implement `OnShutdown()`, because total Acedia's clean up
//  is supposed to happen before that event.
protected function OnCreated()
{
    BootUp();
    default.packagesToLoad.length = 0;
}

/**
 *  Static method that starts everything needed by Acedia framework to function.
 *  Must be called before attempting to use any of the Acedia's functionality.
 *
 *  Acedia needs to be able to spawn actors and for that it first needs to
 *  spawn `CoreService`. To make that possible you need to provide
 *  an `Actor` instance from current level. It can be any valid actor.
 *
 *  @param  source      Valid actor instance that Acedia will use to
 *      spawn `CoreService`
 *  @param  packages    List of acedia packages to load.
 *      Using array of `string`s since Acedia's `Text` wouldn't yet
 *      be available.
 */
public final static function LaunchAcedia(Actor source, array<string> packages)
{
    default.packagesToLoad = packages;
    default.blockSpawning = false;
    //  Actual work will be done inside `BootUp()` private method that will be
    //  called from `OnCreated()` event.
    source.Spawn(class'CoreService');
    default.blockSpawning = true;
}

/**
 *  Shuts down Acedia, cleaning up created actors, default values,
 *  changes made to the standard game classes, etc..
 *
 *  This method must be called before the level change (map change), otherwise
 *  Acedia is not guaranteed to work on the next map and you might 
 *  even experience game crashes.
 */
public final function ShutdownAcedia()
{
    local int           i;
    local AcediaActor   nextActor;
    local MemoryService memoryService;
    _.logger.Auto(infoShuttingDown);
    memoryService = MemoryService(class'MemoryService'.static.GetInstance());
    //  Turn off gameplay-related stuff first
    class'Global'.static.GetInstance().DropGameplayAPI();
    //  Get rid of actors
    foreach AllActors(class'AcediaActor', nextActor)
    {
        if (nextActor == self)          continue;
        if (nextActor == memoryService) continue;
        nextActor.Destroy();
    }
    //  Clean all used classes, except for singletons
    for (i = 0; i < usedObjectClasses.length; i += 1) {
        usedObjectClasses[i].static._cleanup();
    }
    for (i = 0; i < usedActorClasses.length; i += 1) {
        usedActorClasses[i].static._cleanup();
    }
    //  Remove remaining objects
    _.unreal.broadcasts.Remove(class'BroadcastEventsObserver');
    memoryService.ClearAll();
    //  Finally clean up singletons
    for (i = 0; i < usedSingletonClasses.length; i += 1) {
        usedSingletonClasses[i].static._cleanup();
    }
    //  Clean API
    class'Global'.static.GetInstance().DropCoreAPI();
    _ = none;
    //  Get rid of the `MemoryService` and `CoreService` last
    memoryService.Destroy();
    Destroy();
    Log("Acedia has shut down.");
}

//  Loads packages, injects broadcast handler and optionally runs tests
private final function BootUp()
{
    local int               i;
    local Text              nextPackageName;
    local class<_manifest>  nextManifest;
    _.logger.Auto(infoBootingUp);
    LoadManifest(class'AcediaCore_0_2.Manifest');
    //  Load packages
    for (i = 0; i < packagesToLoad.length; i += 1)
    {
        nextPackageName = _.text.FromString(packagesToLoad[i]);
        _.logger.Auto(infoLoadingPackage).Arg(nextPackageName.Copy());
        nextManifest = LoadManifestClass(packagesToLoad[i]);
        if (nextManifest == none)
        {
            _.logger.Auto(errorNoManifest).Arg(nextPackageName.Copy());
            continue;
        }
        LoadManifest(nextManifest);
        _.memory.Free(nextPackageName);
    }
    nextPackageName = none;
    _.logger.Auto(infoBootingUpFinished);
    //  Other initialization
    class'UnrealService'.static.Require();
    if (class'TestingService'.default.runTestsOnStartUp) {
        RunStartUpTests();
    }
}

private final function LoadManifest(class<_manifest> manifestClass)
{
    local int i;
    for (i = 0; i < manifestClass.default.aliasSources.length; i += 1)
    {
        if (manifestClass.default.aliasSources[i] == none) continue;
        _.memory.Allocate(manifestClass.default.aliasSources[i]);
    }
    LaunchServicesAndFeatures(manifestClass);
    if (class'Commands_Feature'.static.IsEnabled()) {
        RegisterCommands(manifestClass);
    }
    for (i = 0; i < manifestClass.default.testCases.length; i += 1)
    {
        class'TestingService'.static
            .RegisterTestCase(manifestClass.default.testCases[i]);
    }
}

private final function class<_manifest> LoadManifestClass(string packageName)
{
    return class<_manifest>(DynamicLoadObject(  packageName $ manifestSuffix,
                                                class'Class', true));
}

private final function RegisterCommands(class<_manifest> manifestClass)
{
    local int               i;
    local Commands_Feature  commandsFeature;
    commandsFeature =
        Commands_Feature(class'Commands_Feature'.static.GetInstance());
    for (i = 0; i < manifestClass.default.commands.length; i += 1)
    {
        if (manifestClass.default.commands[i] == none) continue;
        commandsFeature.RegisterCommand(manifestClass.default.commands[i]);
    }
}

private final function LaunchServicesAndFeatures(class<_manifest> manifestClass)
{
    local int   i;
    local Text  autoConfigName;
    //  Services
    for (i = 0; i < manifestClass.default.services.length; i += 1)
    {
        if (manifestClass.default.services[i] == none) continue;
        manifestClass.default.services[i].static.Require();
    }
    //  Features
    for (i = 0; i < manifestClass.default.features.length; i += 1)
    {
        if (manifestClass.default.features[i] == none) continue;
        manifestClass.default.features[i].static.LoadConfigs();
        autoConfigName =
            manifestClass.default.features[i].static.GetAutoEnabledConfig();
        if (autoConfigName != none) {
            manifestClass.default.features[i].static.EnableMe(autoConfigName);
        }
        _.memory.Free(autoConfigName);
    }
}

private final function RunStartUpTests()
{
    local TestingService testService;
    testService = TestingService(class'TestingService'.static.Require());
    testService.PrepareTests();
    if (testService.filterTestsByName) {
        testService.FilterByName(testService.requiredName);
    }
    if (testService.filterTestsByGroup) {
        testService.FilterByGroup(testService.requiredGroup);
    }
    if (!testService.Run()) {
        _.logger.Auto(errorCannotRunTests);
    }
}

/**
 *  Registers class derived from `AcediaObject` for clean up when
 *  Acedia shuts down.
 *
 *  Does not check for duplicates.
 *
 *  This is an internal function and should not be used outside of
 *  AcediaCore package.
 */
public final function _registerObjectClass(class<AcediaObject> classToClean)
{
    if (classToClean != none) {
        usedObjectClasses[usedObjectClasses.length] = classToClean;
    }
}

/**
 *  Registers class derived from `AcediaActor` for clean up when
 *  Acedia shuts down.
 *
 *  Does not check for duplicates.
 *
 *  This is an internal function and should not be used outside of
 *  AcediaCore package.
 */
public final function _registerActorClass(class<AcediaActor> classToClean)
{
    local class<Singleton> singletonClass;
    if (classToClean == none) {
        return;
    }
    singletonClass = class<Singleton>(classToClean);
    if (singletonClass != none) {
        usedSingletonClasses[usedSingletonClasses.length] = singletonClass;
    }
    else {
        usedActorClasses[usedActorClasses.length] = classToClean;
    }
}

defaultproperties
{
    manifestSuffix  = ".Manifest"

    infoBootingUp               = (l=LOG_Info,m="Initializing Acedia.")
    infoBootingUpFinished       = (l=LOG_Info,m="Acedia initialized.")
    infoShuttingDown            = (l=LOG_Info,m="Shutting down Acedia.")
    infoLoadingPackage          = (l=LOG_Info,m="BLoading package \"%1\".")
    errorNoManifest             = (l=LOG_Error,m="Cannot load `Manifest` for package \"%1\". Check if it's missing or if its name is spelled incorrectly.")
    errorCannotRunTests         = (l=LOG_Error,m="Could not perform Acedia's tests.")
}