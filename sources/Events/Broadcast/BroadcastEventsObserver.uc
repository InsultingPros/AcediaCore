/**
 *      `BroadcastHandler` class that used by Acedia to catch
 *  broadcasting events. For Acedia to work properly it needs to be added to
 *  the very beginning of the broadcast handlers' chain.
 *  However, for compatibility reasons Acedia also supports less invasive
 *  methods to add it at the cost of some functionality degradation.
 *      Copyright 2020 Anton Tarasenko
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
    dependson(BroadcastEvents)
    config(AcediaSystem);

/**
 *      Forcing Acedia's own `BroadcastHandler` is rather invasive and might be
 *  undesired, since it can lead to incompatibilities with some mutators.
 *      To alleviate this issue Acedia allows server admins to control how it's
 *  `BroadcastHandler` is injected. Do note however that anything other than
 *  `BHIJ_Root` can lead to issues with Acedia's features.
 */
enum InjectionLevel
{
    //  `BroadcastEventsObserver` will not be added at all, which will
    //  effectively disable `BroadcastEvents`.
    BHIJ_None,
    //   `BroadcastEventsObserver` will be places in the broadcast handlers'
    //  chain as a normal `BroadcastHandler`
    //  (through `RegisterBroadcastHandler()` call), which can lead to incorrect
    //  handling of `HandleText` and `HandleLocalized` events.
    BHIJ_Registered,
    //      `BroadcastEventsObserver` will be injected at the very beginning of
    //  the broadcast handlers' chain.
    //      This option provides full Acedia's functionality.
    BHIJ_Root
};
var public config const InjectionLevel usedInjectionLevel;
//      The way vanilla `BroadcastHandler` works - it can check if broadcast is
//  possible for any actor, but for actually sending the text messages it will
//  try to extract player's data from it and will simply pass `none` for
//  a sender if it can't.
//      We remember senders in this array in order to pass real ones to
//  our events.
//      We use an array instead of a single variable is to account for possible
//  folded calls (when handling of broadcast events leads to another
//  message generation).
//      This is only relevant for `BHIJ_Root` injection level.
var private array<Actor> storedSenders;

//      We want to insert our code in some of the functions between
//  `AllowsBroadcast` check and actual broadcasting,
//  so we can't just use a `super.AllowsBroadcast()` call.
//      Instead we first manually do this check, then perform our logic and then
//  make a super call, but with `blockAllowsBroadcast` flag set to `true`,
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
 *      Check logic is implemented in `IsFromNewTextBroadcast()` and
 *  `IsFromNewLocalizedBroadcast()` methods.
 */
//  Are we already already tracking any broadcast? Helps to track for point 3.
var private bool                    trackingBroadcast;
//  Sender of the current broadcast. Helps to track for point 1.
var private Actor                   currentBroadcastInstigator;
//  Players that already received current broadcast. Helps to track for point 2.
var private array<PlayerController> currentBroadcastReceivers;
//      Is current broadcast sending a
//  text message (`Broadcast()` and `BroadcastTeam()`)
//  or localized message (`AcceptBroadcastLocalized()`)?
//      Helps to track message for point 1.
var private bool                    broadcastingLocalizedMessage;
//  Variables to stored text message. Helps to track for point 1.
var private string  currentTextMessageContent;
var private name    currentTextMessageType;
//  Variables to stored localized message. Helps to track for point 1.
var private BroadcastEvents.LocalizedMessage currentLocalizedMessage;

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

private function bool IsFromNewTextBroadcast(
    PlayerReplicationInfo   senderPRI,
    PlayerController        receiver,
    string                  message,
    name                    messageType)
{
    local bool isCurrentBroadcastContinuation;
    if (usedInjectionLevel != BHIJ_Registered) return false;

    isCurrentBroadcastContinuation = trackingBroadcast
        && (senderPRI == currentBroadcastInstigator)
        && (!broadcastingLocalizedMessage)
        && (message == currentTextMessageContent)
        && (currentTextMessageType == currentTextMessageType)
        && !IsCurrentBroadcastReceiver(receiver);
    if (isCurrentBroadcastContinuation) {
        return false;
    }
    trackingBroadcast                   = true;
    broadcastingLocalizedMessage        = false;
    currentBroadcastInstigator          = senderPRI;
    currentTextMessageContent           = message;
    currentTextMessageType              = messageType;
    currentBroadcastReceivers.length    = 0;
    return true;
}

private function bool IsFromNewLocalizedBroadcast(
    Actor                               sender,
    PlayerController                    receiver,
    BroadcastEvents.LocalizedMessage    localizedMessage)
{
    local bool isCurrentBroadcastContinuation;
    if (usedInjectionLevel != BHIJ_Registered) return false;

    isCurrentBroadcastContinuation = trackingBroadcast
        && (sender == currentBroadcastInstigator)
        && (broadcastingLocalizedMessage)
        && (localizedMessage == currentLocalizedMessage)
        && !IsCurrentBroadcastReceiver(receiver);
    if (isCurrentBroadcastContinuation) {
        return false;
    }
    trackingBroadcast                   = true;
    broadcastingLocalizedMessage        = true;
    currentBroadcastInstigator          = sender;
    currentLocalizedMessage             = localizedMessage;
    currentBroadcastReceivers.length    = 0;
    return true;
}

//      Functions below simply reroute vanilla's broadcast events to
//  Acedia's 'BroadcastEvents', while keeping original senders
//  and blocking 'AllowsBroadcast()' as described in comments for
//  'storedSenders' and 'blockAllowsBroadcast'.

public function bool HandlerAllowsBroadcast(Actor broadcaster, int sentTextNum)
{
    local bool canBroadcast;
    //  Check listeners
    canBroadcast = class'BroadcastEvents'.static
        .CallCanBroadcast(broadcaster, sentTextNum);
    //  Check other broadcast handlers (if present)
    if (canBroadcast && nextBroadcastHandler != none)
    {
        canBroadcast = nextBroadcastHandler
            .HandlerAllowsBroadcast(broadcaster, sentTextNum);
    }
	return canBroadcast;
}

function Broadcast(Actor sender, coerce string message, optional name type)
{
    local bool canTryToBroadcast;
    if (!AllowsBroadcast(sender, Len(message))) return;
    canTryToBroadcast = class'BroadcastEvents'.static
        .CallHandleText(sender, message, type);
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
    optional name   type
)
{
    local bool canTryToBroadcast;
    if (!AllowsBroadcast(sender, Len(message))) return;
    canTryToBroadcast = class'BroadcastEvents'.static
        .CallHandleText(sender, message, type);
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
    optional Object                 optionalObject
)
{
    local bool                              canTryToBroadcast;
    local BroadcastEvents.LocalizedMessage  packedMessage;
    packedMessage.class         = message;
    packedMessage.id            = switch;
    packedMessage.relatedPRI1   = relatedPRI1;
    packedMessage.relatedPRI2   = relatedPRI2;
    packedMessage.relatedObject = optionalObject;
    canTryToBroadcast = class'BroadcastEvents'.static
        .CallHandleLocalized(sender, packedMessage);
    if (canTryToBroadcast)
    {
        super.AllowBroadcastLocalized(  sender, message, switch,
                                        relatedPRI1, relatedPRI2,
                                        optionalObject);
    }
}

function bool AllowsBroadcast(Actor broadcaster, int len)
{
	if (blockAllowsBroadcast)
        return true;
    return super.AllowsBroadcast(broadcaster, len);
}

function bool AcceptBroadcastText(
    PlayerController        receiver,
    PlayerReplicationInfo   senderPRI,
    out string              message,
    optional name           type
)
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
        if (IsFromNewTextBroadcast(senderPRI, receiver, message, type))
        {
            class'BroadcastEvents'.static.CallHandleText(sender, message, type);
            currentBroadcastReceivers.length = 0;
        }
        currentBroadcastReceivers[currentBroadcastReceivers.length] = receiver;
    }
    canBroadcast = class'BroadcastEvents'.static
        .CallHandleTextFor(receiver, sender, message, type);
    if (!canBroadcast) {
        return false;
    }
	return super.AcceptBroadcastText(receiver, senderPRI, message, type);
}


function bool AcceptBroadcastLocalized(
    PlayerController                receiver,
    Actor                           sender,
    class<LocalMessage>             message,
    optional int                    switch,
    optional PlayerReplicationInfo  relatedPRI1,
    optional PlayerReplicationInfo  relatedPRI2,
    optional Object                 obj
)
{
	local bool                              canBroadcast;
    local BroadcastEvents.LocalizedMessage  packedMessage;
    packedMessage.class         = message;
    packedMessage.id            = switch;
    packedMessage.relatedPRI1   = relatedPRI1;
    packedMessage.relatedPRI2   = relatedPRI2;
    packedMessage.relatedObject = obj;
    if (usedInjectionLevel == BHIJ_Registered)
    {
        if (IsFromNewLocalizedBroadcast(sender, receiver, packedMessage))
        {
            class'BroadcastEvents'.static
                .CallHandleLocalized(sender, packedMessage);
            currentBroadcastReceivers.length = 0;
        }
        currentBroadcastReceivers[currentBroadcastReceivers.length] = receiver;
    }
    canBroadcast = class'BroadcastEvents'.static
        .CallHandleLocalizedFor(receiver, sender, packedMessage);
    if (!canBroadcast) {
        return false;
    }
	return super.AcceptBroadcastLocalized(  receiver, sender, message, switch,
                                            relatedPRI1, relatedPRI2, obj);
}

event Tick(float delta)
{
    trackingBroadcast = false;
    currentBroadcastReceivers.length = 0;
}

defaultproperties
{
    blockAllowsBroadcast    = false
    usedInjectionLevel      = BHIJ_Root
}