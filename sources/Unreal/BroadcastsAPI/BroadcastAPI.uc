/**
 *      Low-level API that provides set of utility methods for working with
 *  `BroadcastHandler`s.
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
class BroadcastAPI extends AcediaObject;

//  Tracks if we have already tried to add our own `BroadcastHandler` to avoid
//  wasting resources/spamming errors in the log about our inability to do so
var private bool triedToInjectBroadcastHandler;

/**
 *  Defines ways to add a new `BroadcastHandler` into the `GameInfo`'s
 *  `BroadcastHandler` linked list.
 */
enum InjectionLevel
{
    //   `BroadcastHandler` will be places in the broadcast handlers'
    //  chain as a normal `BroadcastHandler`
    //  (through `RegisterBroadcastHandler()` call).
    BHIJ_Registered,
    //  `BroadcastHandler` will not be added at all.
    BHIJ_None,
    //      `BroadcastEventsObserver` will be injected at the very beginning of
    //  the broadcast handlers' chain.
    BHIJ_Root
};

/**
 *  Describes propagated localized message.
 */
struct LocalizedMessage
{
    //      Every localized message is described by a class and id.
    //      For example, consider 'KFMod.WaitingMessage':
    //  if passed 'id' is '1',
    //  then it's supposed to be a message about new wave,
    //  but if passed 'id' is '2',
    //  then it's about completing the wave.
    var class<LocalMessage>     class;
    var int                     id;
    //      Localized messages in unreal script can be passed along with
    //  optional arguments, described by variables below.
    var PlayerReplicationInfo   relatedPRI1;
    var PlayerReplicationInfo   relatedPRI2;
    var Object                  relatedObject;
};

var private LoggerAPI.Definition infoInjectedBroadcastEventsObserver;
var private LoggerAPI.Definition errBroadcasthandlerForbidden;
var private LoggerAPI.Definition errBroadcasthandlerUnknown;

/**
 *  Called before text message is sent to any player, during the check for
 *  whether it is at all allowed to be broadcasted. Corresponds to
 *  the `HandlerAllowsBroadcast()` method from `BroadcastHandler`.
 *  Return `false` to prevent message from being broadcast. If a `false` is
 *  returned, signal propagation will be interrupted.
 *
 *  Only guaranteed to be called for a message if `BHIJ_Root` was used to
 *  inject `BroadcastEventsObserver`. Otherwise it depends on what other
 *  `BroadcastHandler`s are added to `GameInfo`'s linked list. However for
 *  `BHIJ_Registered` this signal function should be more reliable than
 *  `OnHandleText()`, with the downside of not providing you with
 *  an actual message.
 *
 *  [Signature]
 *  bool <slot>(Actor broadcaster, int newMessageLength)
 *
 *  @param  broadcaster         `Actor` that attempts to broadcast next
 *      text message.
 *  @param  newMessageLength    Length of the message (amount of code points).
 *  @return `false` if you want to prevent message from being broadcast
 *      and `true` otherwise. `false` returned by one of the handlers overrides
 *      `true` values returned by others.
 */
/* SIGNAL */
public final function Broadcast_OnBroadcastCheck_Slot OnBroadcastCheck(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;

    service = UnrealService(class'UnrealService'.static.Require());
    TryInjectBroadcastHandler(service);
    signal = service.GetSignal(class'Broadcast_OnBroadcastCheck_Signal');
    return Broadcast_OnBroadcastCheck_Slot(signal.NewSlot(receiver));
}

/**
 *      Called before text message is sent to any player, but after the check
 *  for whether it is at all allowed to be broadcasted. Corresponds to
 *  the `Broadcast()` or `BroadcastTeam()` method from `BroadcastHandler` if
 *  `BHIJ_Root` injection method was used and to `BroadcastText()` for
 *  `BHIJ_Registered`.
 *      Return `false` to prevent message from being broadcast. If `false` is
 *  returned, signal propagation to the remaining handlers will also
 *  be interrupted.
 *
 *  Only guaranteed to be called for a message if `BHIJ_Root` was used to
 *  inject `BroadcastEventsObserver`. Otherwise:
 *      1.  Whether it gets emitted at all depends on what other
 *          `BroadcastHandler`s are added to `GameInfo`'s linked list;
 *      2.  This event is actually inaccessible for `BroadcastEventsObserver`
 *          and Acedia tries to make a guess on whether it occurred based on
 *          parameters of `BroadcastText()` call - in some cases it can be
 *          called twice for the same message or not be called at all.
 *          Although conditions for that are exotic and unlikely.
 *  If you do not care about actual contents of the `message` and simply want to
 *  detect (and possibly prevent) message broadcast as early as possible,
 *  consider using `OnBroadcastCheck()` signal function instead.
 *
 *  [Signature]
 *  bool <slot>(Actor sender, out string message, name type, bool teamMessage)
 *
 *  @param  sender      `Actor` that attempts to broadcast next text message.
 *  @param  message     Message that is being broadcasted. Can be changed, but
 *      with `BHIJ_Registered` level of injection such change can actually
 *      affect detection of new broadcasts and lead to weird behavior.
 *      If one of the handler modifies the `message`, then all the handlers
 *      after it will get a modified version.
 *  @param  type        Type of the message.
 *  @param  teamMessage `true` if this message is a message that is being
 *      broadcasted within `sender`'s team. Only works if `BHIJ_Root` injection
 *      method was used, otherwise, always stays `false`.
 *  @return `false` if you want to prevent message from being broadcast
 *      and `true` otherwise. `false` returned by one of the handlers overrides
 *      `true` values returned by others.
 */
/* SIGNAL */
public final function Broadcast_OnHandleText_Slot OnHandleText(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;

    service = UnrealService(class'UnrealService'.static.Require());
    TryInjectBroadcastHandler(service);
    signal = service.GetSignal(class'Broadcast_OnHandleText_Signal');
    return Broadcast_OnHandleText_Slot(signal.NewSlot(receiver));
}

/**
 *      Called before text message is sent to a particular player. Corresponds
 *  to the `BroadcastText()` method from `BroadcastHandler`.
 *      Return `false` to prevent message from being broadcast to a
 *  specified player. If `false` is returned, signal propagation to
 *  the remaining handlers will also be interrupted.
 *
 *  [Signature]
 *  bool <slot>(
 *      PlayerController    receiver,
 *      Actor               sender,
 *      string              message,
 *      name                type)
 *
 *  @param  receiver    Player that is about to receive message in question.
 *  @param  sender      `Actor` that attempts to broadcast next text message.
 *      With `BHIJ_Root` injection level an actual sender `Actor` is passed,
 *      instead of extracted `PlayerReplicationInfo` that is given inside
 *      `BroadcastText()` for `Pawn`s and `Controller`s.
 *      Otherwise returns `PlayerReplicationInfo` provided in
 *      the `BroadcastText()`.
 *  @param  message     Message that is being broadcasted.
 *  @param  type        Type of the message.
 *  @return `false` if you want to prevent message from being broadcast
 *      and `true` otherwise. `false` returned by one of the handlers overrides
 *      `true` values returned by others.
 */
/* SIGNAL */
public final function Broadcast_OnHandleTextFor_Slot OnHandleTextFor(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;

    service = UnrealService(class'UnrealService'.static.Require());
    TryInjectBroadcastHandler(service);
    signal = service.GetSignal(class'Broadcast_OnHandleTextFor_Signal');
    return Broadcast_OnHandleTextFor_Slot(signal.NewSlot(receiver));
}

/**
 *      Called before localized message is sent to any player. Corresponds to
 *  the `AllowBroadcastLocalized()` method from `BroadcastHandler` if
 *  `BHIJ_Root` injection method was used and to `BroadcastLocalized()` for
 *  `BHIJ_Registered`.
 *      Return `false` to prevent message from being broadcast. If `false` is
 *  returned, signal propagation for remaining handlers will also
 *  be interrupted.
 *
 *  Only guaranteed to be called for a message if `BHIJ_Root` was used to
 *  inject `BroadcastEventsObserver`. Otherwise:
 *      1.  Whether it gets emitted at all depends on what other
 *          `BroadcastHandler`s are added to `GameInfo`'s linked list;
 *      2.  This event is actually inaccessible for `BroadcastEventsObserver`
 *          and Acedia tries to make a guess on whether it occurred based on
 *          parameters of `BroadcastLocalized()` call - in some cases it can be
 *          called twice for the same message or not be called at all.
 *          Although conditions for that are exotic and unlikely.
 *
 *  [Signature]
 *  bool <slot>(
 *      Actor               sender,
 *      LocalizedMessage    packedMessage)
 *
 *  @param  sender          `Actor` that attempts to broadcast next text message.
 *  @param  packedMessage   Message that is being broadcasted, represented as
 *      struct that contains all the normal parameters associate with
 *      localized messages.
 *  @return `false` if you want to prevent message from being broadcast
 *      and `true` otherwise. `false` returned by one of the handlers overrides
 *      `true` values returned by others.
 */
/* SIGNAL */
public final function Broadcast_OnHandleLocalized_Slot OnHandleLocalized(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;

    service = UnrealService(class'UnrealService'.static.Require());
    TryInjectBroadcastHandler(service);
    signal = service.GetSignal(class'Broadcast_OnHandleLocalized_Signal');
    return Broadcast_OnHandleLocalized_Slot(signal.NewSlot(receiver));
}

/**
 *      Called before localized message is sent to a particular player.
 *  Corresponds to the `BroadcastLocalized()` method from `BroadcastHandler`.
 *      Return `false` to prevent message from being broadcast to a
 *  specified player. If `false` is returned, signal propagation to
 *  the remaining handlers will also be interrupted.
 *
 *  [Signature]
 *  bool <slot>(
 *      PlayerController    receiver,
 *      Actor               sender,
 *      LocalizedMessage    packedMessage)
 *
 *  @param  receiver        Player that is about to receive message in question.
 *  @param  sender          `Actor` that attempts to broadcast next localized
 *      message. Unlike `OnHandleTextFor()`, this parameter always corresponds
 *      to the real sender, regardless of the injection level.
 *  @param  packedMessage   Message that is being broadcasted, represented as
 *      struct that contains all the normal parameters associate with
 *      localized messages.
 *  @return `false` if you want to prevent message from being broadcast
 *      and `true` otherwise. `false` returned by one of the handlers overrides
 *      `true` values returned by others.
 */
/* SIGNAL */
public final function Broadcast_OnHandleLocalizedFor_Slot OnHandleLocalizedFor(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;

    service = UnrealService(class'UnrealService'.static.Require());
    TryInjectBroadcastHandler(service);
    signal = service.GetSignal(class'Broadcast_OnHandleLocalizedFor_Signal');
    return Broadcast_OnHandleLocalizedFor_Slot(signal.NewSlot(receiver));
}

private final function TryInjectBroadcastHandler(UnrealService service)
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

/**
 *  Adds new `BroadcastHandler` class to the current `GameInfo`.
 *  Does nothing if given `BroadcastHandler` class was already added before.
 *
 *  @param  newBHClass  Class of `BroadcastHandler` to add.
 *  @return `BroadcastHandler` instance if it was added and `none` otherwise.
 */
public final function BroadcastHandler Add(
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

/**
 *  Removes given `BroadcastHandler` class from the current `GameInfo`,
 *  if it is active. Does nothing otherwise.
 *
 *  @param  BHClassToRemove Class of `BroadcastHandler` to try and remove.
 *  @return `true` if `BHClassToRemove` was removed and `false` otherwise
 *      (if they were not active in the first place).
 */
public final function bool Remove(class<BroadcastHandler> BHClassToRemove)
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

/**
 *  Finds given class of `BroadcastHandler` if it's currently active in
 *  `GameInfo`. Returns `none` otherwise.
 *
 *  @param  BHClassToFind   Class of `BroadcastHandler` to find.
 *  @return `BroadcastHandler` instance of given class `BHClassToFind`, that is
 *      added to `GameInfo`'s linked list and `none` if no such
 *      `BroadcastHandler` is currently in the list.
 */
public final function BroadcastHandler FindInstance(
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

/**
 *  Checks if given class of `BroadcastHandler` is currently active in
 *  `GameInfo`.
 *
 *  @param  rulesClassToCheck   Class of rules to check for.
 *  @return `true` if `GameRules` are active and `false` otherwise.
 */
public final function bool IsAdded(class<BroadcastHandler> BHClassToFind)
{
    return (FindInstance(BHClassToFind) != none);
}

defaultproperties
{
    infoInjectedBroadcastEventsObserver = (l=LOG_Info,m="Injected AcediaCore's `BroadcastEventsObserver` with level `%1`.")
    errBroadcastHandlerForbidden        = (l=LOG_Error,m="Injected AcediaCore's `BroadcastEventsObserver` is required, but forbidden by AcediaCore's settings: in file \"AcediaSystem.ini\", section [AcediaCore.SideEffects], variable `broadcastHandlerInjectionLevel`.")
    errBroadcastHandlerUnknown          = (l=LOG_Error,m="Injected AcediaCore's `BroadcastEventsObserver` failed to be injected with level `%1` for unknown reason.")
}