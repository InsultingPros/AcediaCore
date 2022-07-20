/**
 *      `BroadcastHandler` class that used by Acedia to catch
 *  broadcasting events. For Acedia to work properly it needs to be added to
 *  the very beginning of the broadcast handlers' chain.
 *  However, for compatibility reasons Acedia also supports less invasive
 *  methods to add it at the cost of some functionality degradation.
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
class BroadcastEventsObserver extends Engine.BroadcastHandler
    dependson(BroadcastAPI)
    config(AcediaSystem);

//      Forcing Acedia's own `BroadcastHandler` is rather invasive and might be
//  undesired, since it can lead to incompatibilities with some mutators.
//      To alleviate this issue Acedia allows server admins to control how it's
//  `BroadcastHandler` is injected. Do note however that anything other than
//  `BHIJ_Root` can lead to issues with Acedia's features.
var private BroadcastAPI.InjectionLevel usedInjectionLevel;

/**
 *      To understand how what our broadcast handler does, let us first explain
 *  how `BroadcastHandler` classes work. Here we skip voice and speech
 *  broadcasting topics, since they are not something Acedia or this class
 *  currently uses.
 *      `BroadcastHandler`s are capable of forming a one-way linked list by
 *  referring to the next `BroadcastHandler` by `nextBroadcastHandler` and
 *  `nextBroadcastHandlerClass` variables. New `BroadcastHandler`s can be added
 *  via `RegisterBroadcastHandler()` method.
 *      Actual broadcasting of the messages is done by calling one of
 *  the three methods: `Broadcast()`, `BroadcastTeam()` and weirdly named
 *  `AllowBroadcastLocalized()` on the root `BroadcastHandler` (stored in
 *  the current `GameInfo`). These methods are only ever called for the root
 *  `BroadcastHandler` and **are not** propagated down the chain.
 *  This leads to...
 *      ISSUE 1: we cannot reliably detect start of the message propagation with
 *  `BroadcastHandler` unless we are at the root of the linked list. This is why
 *  it is important for Acedia to use `BHIJ_Root` method for its
 *  `BroadcastHandler`.
 *
 *      First we will look into `Broadcast()` and `BroadcastTeam()` methods.
 *  First thing either of them does is to call `AllowsBroadcast()` method that
 *  checks whether message is allowed to be broadcasted at all. It is also only
 *  called for the root `BroadcastHandler`, but allows other `BroadcastHandler`s
 *  to block the message for their own reasons by propagating
 *  `HandlerAllowsBroadcast()` method down the chain.
 *      Then they call `BroadcastText()` for every acceptable player controller
 *  they find and the only difference between `Broadcast()` and
 *  `BroadcastTeam()` is that the latter also checks to that they belong to the
 *  same team as the sender.
 *      `BroadcastText()` is propagated down the linked list of
 *  the `BroadcastHandler`s (allowing them to modify or discard message) and,
 *  once list is exhausted, calls `TeamMessage()` method. However it also
 *  propagates additional method `AcceptBroadcastText()` down the linked list.
 *  Supposedly it's `AcceptBroadcastText()` that you should overload when making
 *  your own `BroadcastHandler`, but this setup creates...
 *      ISSUE 2: by default `AcceptBroadcastText()` is propagated ANEW
 *  inside EVERY `BroadcastText()` call (that is also propagated). This means
 *  that if there is several `BroadcastHandler`s in the chain before yours -
 *  every single one of them (including your own!) will call
 *  `AcceptBroadcastText()` for you. This means that `AcceptBroadcastText()` is
 *  going to be called several times for every broadcasted message unless your
 *  `BroadcastHandler` is added at the very root of the linked list.
 *
 *      All that remains is to consider `AllowBroadcastLocalized()` method.
 *  It works in similar way to the previous two, but is simpler: it does not
 *  have an analogue to the `AllowsBroadcast()` method and simply calls
 *  `BroadcastLocalized()` for every player controller, spectator or not.
 *  `BroadcastLocalized()` works exactly the same way as `BroadcastText()`, but
 *  with uses `AcceptBroadcastLocalized()` instead of `AcceptBroadcastText()`,
 *  completely mirroring issue 2.
 *
 *  Summary.
 *  Methods only called for root `BroadcastHandler`:
 *      1. `Broadcast()` - starts text message broadcast;
 *      2. `BroadcastTeam()` - starts team text message broadcast;
 *      3. `AllowBroadcastLocalized()` - starts localized message broadcast;
 *      4. `AllowsBroadcast()` - called for text message broadcasts (team or
 *          not) to check if they are allowed.
 *  Methods that are propagated down the linked list of `BroadcastHandler`s:
 *      1. `HandlerAllowsBroadcast()` - called before broadcasting text message
 *          (team or not), before any `BroadcastText()` or
 *          `AcceptBroadcastText()` call;
 *      2. `BroadcastText()` - once for every controller that should receive
 *          a certain text message (unless blocked at some point);
 *      3. `AcceptBroadcastText()` - called shit ton of times inside
 *          `BroadcastText()` to check if message can be propagated;
 *      4. `BroadcastLocalized()` - once for every controller that should
 *          receive a certain text message (unless blocked at some point);
 *      5. `AcceptBroadcastLocalized()` - called shit ton of times inside
 *          `BroadcastLocalized()` to check if message can be propagated;
 *
 *  What are we going to do?
 *      We want our `BroadcastHandler` to work at any place inside the
 *  linked list, but also to side step issue 2 completely, so we will use
 *  `BroadcastText()` and `BroadcastLocalized()` methods for catching messages
 *  sent to particular players. We do not want to reimplement `Broadcast()`,
 *  `BroadcastTeam()` or `AllowBroadcastLocalized()` (partially because it would
 *  mostly involve copy-pasting copyrighted code) and will instead inject some
 *  code to reliably catch the moment broadcast has started in case we are
 *  actually placed at the root.
 *      We also want to track broadcast by message parameters in
 *  `BroadcastText()` and `BroadcastLocalized()` methods in case we are not
 *  injected at the root to resolve issue 1. When we detect any difference in
 *  passed parameters (or players message was broadcasted to get repeated) -
 *  we declare a new broadcast. This methods is not perfect, but is likely
 *  the best possible guess for the start of broadcast.
 */


//      This is only relevant for `BHIJ_Root` injection level.
//      The way vanilla `BroadcastHandler` works - it can check if broadcast is
//  possible for any actor, but for actually sending the text messages it will
//  try to extract `PlayerReplicationInfo` from it and will simply pass `none`
//  for a sender if it can't.
//      We remember senders in this array in order to pass real ones to
//  our events.
//      We use an array instead of a single variable is to account for possible
//  folded calls (when handling of broadcast events leads to another
//  message generation).
var private array<Actor> storedSenders;

//      This is only relevant for `BHIJ_Root` injection level.
//      We do not want to reimplement functions `Broadcast()`, `BroadcastTeam()`
//  or `AllowBroadcastLocalized()` that root `BroadcastHandler` calls to do
//  checks and send messages to individual players.
//  Instead we would like to inject our own code and call parent version of
//  these methods.
//      We would also like to insert our code in some of the functions between
//  `AllowsBroadcast()` check and actual broadcasting, so we cannot simply use
//  a `super.AllowsBroadcast()` call that calls both of them in order.
//      Instead we move `AllowsBroadcast()` unto our own methods:
//  we first manually do `AllowsBroadcast()` check, then perform our logic and
//  then make a super call, but with `blockAllowsBroadcast` flag set to `true`,
//  which causes overloaded `AllowsBroadcast()` to omit checks that we've
//  already performed.
var private bool blockAllowsBroadcast;

/*
 *      In case of `BHIJ_Registered` injection level, we do not get notified
 *  when a message starts getting broadcasted through `Broadcast()`,
 *  `BroadcastTeam()` and `AcceptBroadcastLocalized()`.
 *      Instead we are only notified when a message is broadcasted to
 *  a particular player, so with 2 players instead of sequence `Broadcast()`,
 *  `AcceptBroadcastText()`, `AcceptBroadcastText()`
 *  we get `AcceptBroadcastText()`, `AcceptBroadcastText()`.
 *      This means that we can only guess when new broadcast was initiated.
 *  We do this by:
 *      1. Recording broadcast instigator (sender) and his message. If any of
 *          these variables change - we assume it's a new broadcast.
 *      2. Recording players that already received that message, - if message is
 *          resend to one of them - it's a new broadcast
 *          (of possibly duplicate message).
 *      3. All broadcasted messages are sent to all players within 1 tick, so
 *          any first message within each tick is a start of a new broadcast.
 *
 *      Check logic is implemented in `UpdateTrackingWithTextMessage()` and
 *  `UpdateTrackingWithLocalizedMessage()` methods.
 */
//  Are we already already tracking any broadcast? Helps to track for point 3.
var private bool                            trackingBroadcast;
//  Sender of the current broadcast. Helps to track for point 1.
var private Actor                           currentBroadcastInstigator;
//  Players that already received current broadcast. Helps to track for point 2.
var private array<PlayerController>         currentBroadcastReceivers;
//      Is current broadcast sending a
//  text message (`Broadcast()` and `BroadcastTeam()`)
//  or localized message (`AcceptBroadcastLocalized()`)?
//      Helps to track message for point 1.
var private bool                            broadcastingLocalizedMessage;
//  Variables to stored text message. Helps to track for point 1.
var private string                          currentTextMessageContents;
var private name                            currentTextMessageType;
//      We allow connected signals to modify message for all players before
//  `BroadcastText()` or `BroadcastLocalized()` calls and can do so in case of
//  `BHIJ_Registered`.
//      But for `BHIJ_Registered` we can only catch those calls and must
//  manually remember modifications we have made. We store those modifications
//  in this variable. It resets when new message is detected.
var private string                          currentlyUsedMessage;
//  Remember if currently tracked message was rejected by either
//  `BroadcastText()` or `BroadcastLocalized()`.
var private bool                            currentMessageRejected;
//  Variables to stored localized message. Helps to track for point 1.
var private BroadcastAPI.LocalizedMessage   currentLocalizedMessage;

var private Broadcast_OnBroadcastCheck_Signal       onBroadcastCheck;
var private Broadcast_OnHandleLocalized_Signal      onHandleLocalized;
var private Broadcast_OnHandleLocalizedFor_Signal   onHandleLocalizedFor;
var private Broadcast_OnHandleText_Signal           onHandleText;
var private Broadcast_OnHandleTextFor_Signal        onHandleTextFor;

public final function Initialize(ServerUnrealService service)
{
    usedInjectionLevel =
        class'SideEffects'.default.broadcastHandlerInjectionLevel;
    if (usedInjectionLevel == BHIJ_Root) {
        Disable('Tick');
    }
    if (service == none) {
        return;
    }
    onBroadcastCheck        = Broadcast_OnBroadcastCheck_Signal(
        service.GetSignal(class'Broadcast_OnBroadcastCheck_Signal'));
    onHandleLocalized       = Broadcast_OnHandleLocalized_Signal(
        service.GetSignal(class'Broadcast_OnHandleLocalized_Signal'));
    onHandleLocalizedFor    = Broadcast_OnHandleLocalizedFor_Signal(
        service.GetSignal(class'Broadcast_OnHandleLocalizedFor_Signal'));
    onHandleText            = Broadcast_OnHandleText_Signal(
        service.GetSignal(class'Broadcast_OnHandleText_Signal'));
    onHandleTextFor         = Broadcast_OnHandleTextFor_Signal(
        service.GetSignal(class'Broadcast_OnHandleTextFor_Signal'));
}

private function bool IsCurrentBroadcastReceiver(PlayerController receiver)
{
    local int i;
    for (i = 0; i < currentBroadcastReceivers.length; i += 1)
    {
        if (currentBroadcastReceivers[i] == receiver) {
            return true;
        }
    }
    return false;
}

//  Return `true` if new broadcast was detected
private function bool UpdateTrackingWithTextMessage(
    PlayerReplicationInfo   senderPRI,
    PlayerController        receiver,
    string                  message,
    name                    messageType)
{
    local bool isCurrentBroadcastContinuation;
    if (usedInjectionLevel != BHIJ_Registered) {
        return false;
    }
    isCurrentBroadcastContinuation = trackingBroadcast
        && (senderPRI == currentBroadcastInstigator)
        && (!broadcastingLocalizedMessage)
        && (message == currentTextMessageContents)
        && (messageType == currentTextMessageType)
        && !IsCurrentBroadcastReceiver(receiver);
    if (isCurrentBroadcastContinuation)
    {
        currentBroadcastReceivers[currentBroadcastReceivers.length] = receiver;
        return false;
    }
    trackingBroadcast                   = true;
    broadcastingLocalizedMessage        = false;
    currentBroadcastInstigator          = senderPRI;
    currentTextMessageContents          = message;
    currentlyUsedMessage                = message;
    currentTextMessageType              = messageType;
    currentMessageRejected              = false;
    currentBroadcastReceivers.length    = 0;
    return true;
}

//  Return `true` if new broadcast was detected
private function bool UpdateTrackingWithLocalizedMessage(
    Actor                           sender,
    PlayerController                receiver,
    BroadcastAPI.LocalizedMessage   localizedMessage)
{
    local bool isCurrentBroadcastContinuation;
    if (usedInjectionLevel != BHIJ_Registered) {
        return false;
    }
    isCurrentBroadcastContinuation = trackingBroadcast
        && (sender == currentBroadcastInstigator)
        && (broadcastingLocalizedMessage)
        && (localizedMessage == currentLocalizedMessage)
        && !IsCurrentBroadcastReceiver(receiver);
    if (isCurrentBroadcastContinuation)
    {
        currentBroadcastReceivers[currentBroadcastReceivers.length] = receiver;
        return false;
    }
    trackingBroadcast                   = true;
    broadcastingLocalizedMessage        = true;
    currentBroadcastInstigator          = sender;
    currentLocalizedMessage             = localizedMessage;
    currentBroadcastReceivers.length    = 0;
    currentMessageRejected              = false;
    return true;
}

//  Makes us stop tracking current broadcast
private function ResetTracking()
{
    trackingBroadcast = false;
    //      Only important to forget objects and actors, since keeping
    //  references can cause issues.
    //      Other fields can remain "dirty", since they will be rewritten before
    //  they will ever be used.
    currentBroadcastInstigator              = none;
    currentLocalizedMessage.relatedPRI1     = none;
    currentLocalizedMessage.relatedPRI2     = none;
    currentLocalizedMessage.relatedObject   = none;
}

public function bool HandlerAllowsBroadcast(Actor broadcaster, int sentTextNum)
{
    local bool canBroadcast;
    //  Fire and check signals
    canBroadcast = onBroadcastCheck.Emit(broadcaster, sentTextNum);
    //  Check other broadcast handlers (if present)
    if (canBroadcast && nextBroadcastHandler != none)
    {
        canBroadcast = nextBroadcastHandler
            .HandlerAllowsBroadcast(broadcaster, sentTextNum);
    }
    if (canBroadcast && usedInjectionLevel == BHIJ_Registered)
    {
        //  This method is only really called by the `AllowsBroadcast()` at the
        //  beginning of either `Broadcast()` or `BroadcastTeam()` methods.
        //  Meaning that new broadcast has started for sure.
        ResetTracking();
    }
    return canBroadcast;
}

function Broadcast(Actor sender, coerce string message, optional name type)
{
    local bool canTryToBroadcast;
    if (!AllowsBroadcast(sender, Len(message))) {
        return;
    }
    canTryToBroadcast = onHandleText.Emit(sender, message, type, false);
    if (canTryToBroadcast)
    {
        storedSenders[storedSenders.length] = sender;
        blockAllowsBroadcast = true;
        super.Broadcast(sender, message, type);
        blockAllowsBroadcast = false;
        storedSenders.length = storedSenders.length - 1;
    }
}

function BroadcastTeam(
    Controller      sender,
    coerce string   message,
    optional name   type)
{
    local bool canTryToBroadcast;
    if (!AllowsBroadcast(sender, Len(message))) {
        return;
    }
    canTryToBroadcast = onHandleText.Emit(sender, message, type, true);
    if (canTryToBroadcast)
    {
        storedSenders[storedSenders.length] = sender;
        blockAllowsBroadcast = true;
        super.BroadcastTeam(sender, message, type);
        blockAllowsBroadcast = false;
        storedSenders.length = storedSenders.length - 1;
    }
}

event AllowBroadcastLocalized(
    Actor                           sender,
    class<LocalMessage>             message,
    optional int                    switch,
    optional PlayerReplicationInfo  relatedPRI1,
    optional PlayerReplicationInfo  relatedPRI2,
    optional Object                 optionalObject)
{
    local bool                          canTryToBroadcast;
    local BroadcastAPI.LocalizedMessage packedMessage;
    packedMessage.class         = message;
    packedMessage.id            = switch;
    packedMessage.relatedPRI1   = relatedPRI1;
    packedMessage.relatedPRI2   = relatedPRI2;
    packedMessage.relatedObject = optionalObject;
    canTryToBroadcast = onHandleLocalized.Emit(sender, packedMessage);
    if (canTryToBroadcast)
    {
        super.AllowBroadcastLocalized(  sender, message, switch,
                                        relatedPRI1, relatedPRI2,
                                        optionalObject);
    }
}

function bool AllowsBroadcast(Actor broadcaster, int len)
{
    if (blockAllowsBroadcast) {
        return true;    //  we have already done this check and it passed
    }
    return super.AllowsBroadcast(broadcaster, len);
}

function BroadcastText(
    PlayerReplicationInfo   senderPRI,
    PlayerController        receiver,
    string                  message,
    optional name           type)
{
    local bool  canBroadcast;
    local Actor sender;
    if (senderPRI != none) {
        sender = PlayerController(senderPRI.owner);
    }
    if (sender == none && storedSenders.length > 0) {
        sender = storedSenders[storedSenders.length - 1];
    }
    if (usedInjectionLevel == BHIJ_Registered)
    {
        if (UpdateTrackingWithTextMessage(senderPRI, receiver, message, type))
        {
            currentMessageRejected = !onHandleText
                .Emit(sender, message, type, false);
            currentlyUsedMessage = message;
        }
        else {
            message = currentlyUsedMessage;
        }
        if (currentMessageRejected) {
            return;
        }
    }
    canBroadcast = onHandleTextFor.Emit(receiver, sender, message, type);
    if (!canBroadcast) {
        return;
    }
    super.BroadcastText(senderPRI, receiver, message, type);
}

function BroadcastLocalized(
    Actor                           sender,
    PlayerController                receiver,
    class<LocalMessage>             message,
    optional int                    switch,
    optional PlayerReplicationInfo  relatedPRI1,
    optional PlayerReplicationInfo  relatedPRI2,
    optional Object                 obj)
{
    local bool                          canBroadcast;
    local BroadcastAPI.LocalizedMessage packedMessage;
    packedMessage.class         = message;
    packedMessage.id            = switch;
    packedMessage.relatedPRI1   = relatedPRI1;
    packedMessage.relatedPRI2   = relatedPRI2;
    packedMessage.relatedObject = obj;
    if (    usedInjectionLevel == BHIJ_Registered
        &&  UpdateTrackingWithLocalizedMessage(sender, receiver, packedMessage))
    {
        currentMessageRejected = !onHandleLocalized.Emit(sender, packedMessage);
    }
    if (currentMessageRejected) {
        return;
    }
    canBroadcast = onHandleLocalizedFor.Emit(receiver, sender, packedMessage);
    if (!canBroadcast) {
        return;
    }
    super.BroadcastLocalized(   sender, receiver, message, switch,
                                relatedPRI1, relatedPRI2, obj);
}

event Tick(float delta)
{
    ResetTracking();
}

defaultproperties
{
    blockAllowsBroadcast = false
}