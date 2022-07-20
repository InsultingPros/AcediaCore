/**
 *  Acedia's default implementation for `BroadcastAPI`.
 *      Copyright 2021-2022 Anton Tarasenko
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
class KF1_BroadcastAPI extends BroadcastAPI;

//  Tracks if we have already tried to add our own `BroadcastHandler` to avoid
//  wasting resources/spamming errors in the log about our inability to do so
var private bool triedToInjectBroadcastHandler;

var private LoggerAPI.Definition infoInjectedBroadcastEventsObserver;
var private LoggerAPI.Definition errBroadcasthandlerForbidden;
var private LoggerAPI.Definition errBroadcasthandlerUnknown;

/* SIGNAL */
public function Broadcast_OnBroadcastCheck_Slot OnBroadcastCheck(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryInjectBroadcastHandler(service);
    signal = service.GetSignal(class'Broadcast_OnBroadcastCheck_Signal');
    return Broadcast_OnBroadcastCheck_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function Broadcast_OnHandleText_Slot OnHandleText(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryInjectBroadcastHandler(service);
    signal = service.GetSignal(class'Broadcast_OnHandleText_Signal');
    return Broadcast_OnHandleText_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function Broadcast_OnHandleTextFor_Slot OnHandleTextFor(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryInjectBroadcastHandler(service);
    signal = service.GetSignal(class'Broadcast_OnHandleTextFor_Signal');
    return Broadcast_OnHandleTextFor_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function Broadcast_OnHandleLocalized_Slot OnHandleLocalized(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryInjectBroadcastHandler(service);
    signal = service.GetSignal(class'Broadcast_OnHandleLocalized_Signal');
    return Broadcast_OnHandleLocalized_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function Broadcast_OnHandleLocalizedFor_Slot OnHandleLocalizedFor(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    TryInjectBroadcastHandler(service);
    signal = service.GetSignal(class'Broadcast_OnHandleLocalizedFor_Signal');
    return Broadcast_OnHandleLocalizedFor_Slot(signal.NewSlot(receiver));
}

/**
 *  Method that attempts to inject Acedia's `BroadcastEventObserver`, while
 *  respecting settings inside `class'SideEffects'`.
 *
 *  @param  service Reference to `ServerUnrealService` to exchange signal and
 *      slots classes with.
 */
protected final function TryInjectBroadcastHandler(ServerUnrealService service)
{
    local InjectionLevel            usedLevel;
    local BroadcastSideEffect       sideEffect;
    local BroadcastEventsObserver   broadcastObserver;

    if (triedToInjectBroadcasthandler) {
        return;
    }
    triedToInjectBroadcasthandler = true;
    usedLevel = class'SideEffects'.default.broadcastHandlerInjectionLevel;
    broadcastObserver = BroadcastEventsObserver(_server.unreal.broadcasts.Add(
        class'BroadcastEventsObserver', usedLevel));
    if (broadcastObserver != none)
    {
        broadcastObserver.Initialize(service);
        sideEffect =
            BroadcastSideEffect(_.memory.Allocate(class'BroadcastSideEffect'));
        sideEffect.Initialize(usedLevel);
        _server.sideEffects.Add(sideEffect);
        _.memory.Free(sideEffect);
        _.logger
            .Auto(infoInjectedBroadcastEventsObserver)
            .Arg(InjectionLevelIntoText(usedLevel));
        return;
    }
    //  We are here if we have failed
    if (usedLevel == BHIJ_None) {
        _.logger.Auto(errBroadcastHandlerForbidden);
    }
    else
    {
        _.logger
            .Auto(errBroadcastHandlerUnknown)
            .Arg(InjectionLevelIntoText(usedLevel));
    }
}

private final function Text InjectionLevelIntoText(
    InjectionLevel injectionLevel)
{
    if (injectionLevel == BHIJ_Root) {
        return P("BHIJ_Root");
    }
    if (injectionLevel == BHIJ_Registered) {
        return P("BHIJ_Registered");
    }
    return P("BHIJ_None");
}

public function BroadcastHandler Add(
    class<BroadcastHandler> newBHClass,
    optional InjectionLevel injectionLevel)
{
    local LevelInfo         level;
    local BroadcastHandler  newBroadcastHandler;

    if (injectionLevel == BHIJ_None)            return none;
    level = _server.unreal.GetLevel();
    if (level == none || level.game == none)    return none;
    if (IsAdded(newBHClass))                    return none;

    //      For some reason `default.nextBroadcastHandlerClass` variable can be
    //  auto-set after the level switch.
    //      I don't know why, I don't know when exactly, but not resetting it
    //  can lead to certain issues, including infinite recursion crashes.
    class'BroadcastHandler'.default.nextBroadcastHandlerClass = none;
    newBroadcastHandler = class'ServerLevelCore'.static
        .GetInstance()
        .Spawn(newBHClass);
    if (injectionLevel == BHIJ_Registered)
    {
        //  There is guaranteed to be SOME broadcast handler
        level.game.broadcastHandler
            .RegisterBroadcastHandler(newBroadcastHandler);
        return newBroadcastHandler;
    }
    //      Here `injectionLevel == BHIJ_Root` holds.
    //      Swap out level's first handler with ours
    //  (needs to be done for both actor reference and it's class)
    newBroadcastHandler.nextBroadcastHandler = level.game.broadcastHandler;
    newBroadcastHandler.nextBroadcastHandlerClass = level.game.broadcastClass;
    level.game.broadcastHandler = newBroadcastHandler;
    level.game.broadcastClass   = newBHClass;
    return newBroadcastHandler;
}

public function bool Remove(class<BroadcastHandler> BHClassToRemove)
{
    local LevelInfo         level;
    local BroadcastHandler  previousBH, currentBH;
    level = _server.unreal.GetLevel();
    if (level == none || level.game == none) {
        return false;
    }
    currentBH = level.game.broadcastHandler;
    if (currentBH == none) {
        return false;
    }
    //  Special case of our `BroadcastHandler` being inserted in the root
    if (currentBH == BHClassToRemove)
    {
        level.game.broadcastHandler = currentBH.nextBroadcastHandler;
        level.game.broadcastClass = currentBH.nextBroadcastHandlerClass;
        currentBH.Destroy();
        return true;
    }
    //  And after the root
    previousBH = currentBH;
    currentBH = currentBH.nextBroadcastHandler;
    while (currentBH != none)
    {
        if (currentBH.class != BHClassToRemove)
        {
            previousBH  = currentBH;
            currentBH   = currentBH.nextBroadcastHandler;
        }
        else
        {
            previousBH.nextBroadcastHandler               =
                currentBH.nextBroadcastHandler;
            previousBH.default.nextBroadcastHandlerClass  =
                currentBH.default.nextBroadcastHandlerClass;
            previousBH.nextBroadcastHandlerClass          =
                currentBH.nextBroadcastHandlerClass;
            currentBH.default.nextBroadcastHandlerClass = none;
            currentBH.Destroy();
            return true;
        }
    }
    return false;
}

public function BroadcastHandler FindInstance(
    class<BroadcastHandler> BHClassToFind)
{
    local BroadcastHandler BHIter;
    if (BHClassToFind == none) {
        return none;
    }
    BHIter = _server.unreal.GetGameType().broadcastHandler;
    while (BHIter != none)
    {
        if (BHIter.class == BHClassToFind) {
            return BHIter;
        }
        BHIter = BHIter.nextBroadcastHandler;
    }
    return none;
}

public function bool IsAdded(class<BroadcastHandler> BHClassToFind)
{
    return (FindInstance(BHClassToFind) != none);
}

defaultproperties
{
    infoInjectedBroadcastEventsObserver = (l=LOG_Info,m="Injected AcediaCore's `BroadcastEventsObserver` with level `%1`.")
    errBroadcastHandlerForbidden        = (l=LOG_Error,m="Injected AcediaCore's `BroadcastEventsObserver` is required, but forbidden by AcediaCore's settings: in file \"AcediaSystem.ini\", section [AcediaCore.SideEffects], variable `broadcastHandlerInjectionLevel`.")
    errBroadcastHandlerUnknown          = (l=LOG_Error,m="Injected AcediaCore's `BroadcastEventsObserver` failed to be injected with level `%1` for unknown reason.")
}