/**
 *      Listener for events, related to broadcasting messages
 *  through standard Unreal Script means:
 *  1. text messages, typed by a player;
 *  2. localized messages, identified by a LocalMessage class and id.
 *  Allows to make decisions whether or not to propagate certain messages.
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
class BroadcastListenerBase extends Listener
    abstract;

/**
 *  Helper function for extracting `PlayerController` of the `sender` Actor,
 * if it has one / is one.
 */
static public final function PlayerController GetController(Actor sender)
{
    local Pawn senderPawn;
    senderPawn = Pawn(sender);
    if (senderPawn != none) {
        return PlayerController(senderPawn.controller);
    }
    return PlayerController(sender);
}

/**
 *  This event is called whenever registered broadcast handlers are asked if
 *  they'd allow given actor ('broadcaster') to broadcast a text message.
 *
 *  If injection level for Acedia's broadcast handler is `BHIJ_Root`, this event
 *  is guaranteed to be generated before any of the other `BroadcastHandler`s
 *  receive it.
 *
 *  NOTE: this function is ONLY called when someone tries to
 *  broadcast TEXT messages.
 *
 *  You can also reject a broadcast after looking at the message itself by
 *  using `HandleText()` event.
 *
 *  @param  broadcaster         `Actor` that requested broadcast in question.
 *  @param  recentSentTextSize  Amount of recently broadcasted symbols of text
 *      by `broadcaster`. This value is periodically reset in 'GameInfo',
 *      by default should be each second.
 *  @return If one of the listeners returns 'false', -
 *      it will be treated just like one of broadcasters returning 'false'
 *      in 'AllowsBroadcast' and this method won't be called for remaining
 *      active listeners. Return `true` if you do not wish to block
 *      `broadcaster` from broadcasting his next message.
 *      By default returns `true`.
 */
static function bool CanBroadcast(Actor broadcaster, int recentSentTextSize)
{
    return true;
}

/**
 *      This event is called whenever a someone is trying to broadcast
 *  a text message (typically the typed by a player).
 *      It is called once per message and allows you to change it
 *  (by changing 'message' argument) before any of the players receive it.
 *
 *  See also `HandleTextFor()`.
 *
 *  @param  sender      `Actor` that requested broadcast in question.
 *  @param  message     Message that `sender` wants to broadcast, possibly
 *      altered by other broadcast listeners.
 *  @param  messageType Name variable that describes a type of the message.
 *      Examples are 'Say' and 'CriticalEvent'.
 *  @return If one of the listeners returns 'false', -
 *      it will be treated just like one of broadcasters returning 'false'
 *      in `AcceptBroadcastText()`: this event won't be called for remaining
 *      active listeners and message will not be broadcasted.
 */
static function bool HandleText(
    Actor           sender,
    out string      message,
    optional name   messageType)
{
    return true;
}

/**
 *      This event is called whenever a someone is trying to broadcast
 *  a text message (typically the typed by a player).
 *      This event is similar to 'HandleText', but is called for every player
 *  the message is sent to.
 *
 *  Method allows you to alter the message, but note that changes are
 *  accumulated as events go through the players.
 *
 *  @param  receiver    Player, to which message is supposed to be sent next.
 *  @param  sender      `Actor` that requested broadcast in question.
 *  @param  message     Message that `sender` wants to broadcast, possibly
 *      altered by other broadcast listeners.
 *      But keep in mind that if you do change the message for one client, -
 *      clients that come after it will get an already altered version.
 *      That is, changes to the message accumulate between different
 *      `HandleTextFor()` calls for one broadcast.
 *  @param  messageType Name variable that describes a type of the message.
 *      Examples are 'Say' and 'CriticalEvent'.
 *  @return If one of the listeners returns 'false', -
 *      message would not be sent to `receiver` at all
 *      (but it would not prevent broadcasting it to the rest of the players).
 *      Return `true` if you want it to be broadcasted.
 */
static function bool HandleTextFor(
    PlayerController    receiver,
    Actor               sender,
    out string          message,
    optional name       messageType)
{
    return true;
}

/**
 *      This event is called whenever a someone is trying to broadcast
 *  a localized message. It is called once per message, but,
 *  unlike `HandleText()`, does not allow you to change it.
 *
 *  @param  sender      `Actor` that requested broadcast in question.
 *  @param  message     Message that `sender` wants to broadcast.
 *  @return If one of the listeners returns 'false', -
 *      it will be treated just like one of broadcasters returning 'false'
 *      in `AcceptBroadcastLocalized()`: this event won't be called for
 *      remaining active listeners and message will not be broadcasted.
 */
static function bool HandleLocalized(
    Actor                               sender,
    BroadcastEvents.LocalizedMessage    message)
{
    return true;
}

/**
 *      This event is called whenever a someone is trying to broadcast
 *  a localized message. This event is similar to 'HandleLocalized', but is
 *  called for every player the message is sent to.
 *
 *  Unlike `HandleTextFor()` method does not allow you to alter the message.
 *
 *  @param  receiver    Player, to which message is supposed to be sent next.
 *  @param  sender      `Actor` that requested broadcast in question.
 *  @param  message     Message that `sender` wants to broadcast.
 *  @return If one of the listeners returns 'false', -
 *      message would not be sent to `receiver` at all
 *      (but it would not prevent broadcasting it to the rest of the players).
 *      Return `true` if you want it to be broadcasted.
 */
static function bool HandleLocalizedFor(
    PlayerController                    receiver,
    Actor                               sender,
    BroadcastEvents.LocalizedMessage    message)
{
    return true;
}

defaultproperties
{
    relatedEvents = class'BroadcastEvents'
}