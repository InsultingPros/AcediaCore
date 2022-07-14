/**
 *      API that provides functions for working with chat.
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
class ChatAPI extends AcediaObject;

var protected bool connectedToBroadcastAPI;

var protected ChatAPI_OnMessage_Signal      onMessageSignal;
var protected ChatAPI_OnMessageFor_Signal   onMessageForSignal;

protected function Constructor()
{
    onMessageSignal = ChatAPI_OnMessage_Signal(
        _.memory.Allocate(class'ChatAPI_OnMessage_Signal'));
    onMessageForSignal = ChatAPI_OnMessageFor_Signal(
        _.memory.Allocate(class'ChatAPI_OnMessageFor_Signal'));
}

protected function Finalizer()
{
    _.memory.Free(onMessageSignal);
    _.memory.Free(onMessageForSignal);
    onMessageSignal     = none;
    onMessageForSignal  = none;
    _server.unreal.broadcasts.OnHandleText(self).Disconnect();
    _server.unreal.broadcasts.OnHandleTextFor(self).Disconnect();
    connectedToBroadcastAPI = false;
}

private final function TryConnectingBroadcastSignals()
{
    if (connectedToBroadcastAPI) {
        return;
    }
    connectedToBroadcastAPI = true;
    _server.unreal.broadcasts.OnHandleText(self).connect = HandleText;
    _server.unreal.broadcasts.OnHandleTextFor(self).connect = HandleTextFor;
}

/**
 *  Signal that will be emitted when a player sends a message into the chat.
 *  Allows to modify message before sending it, as well as prevent it from
 *  being sent at all.
 *
 *      Return `false` to prevent message from being sent.
 *  If `false` is returned, signal propagation to the remaining handlers will
 *  also be interrupted.
 *
 *  [Signature]
 *  bool <slot>(EPlayer sender, MutableText message, bool teamMessage)
 *
 *  @param  sender      `EPlayer` that has sent the message.
 *  @param  message     Message that `sender` has sent. This is a mutable
 *      variable and can be modified from message will be sent.
 *  @param  teamMessage Is this a team message
 *      (to be sent only to players on the same team)?
 *  @return Return `false` to prevent this message from being sent at all
 *      and `true` otherwise. Message will be sent only if all handlers will
 *      return `true`.
 */
/* SIGNAL */
public function ChatAPI_OnMessage_Slot OnMessage(
    AcediaObject receiver)
{
    TryConnectingBroadcastSignals();
    return ChatAPI_OnMessage_Slot(onMessageSignal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted when a player sends a message into the chat.
 *  Allows to modify message before sending it, as well as prevent it from
 *  being sent at all.
 *
 *      Return `false` to prevent message from being sent to a specific player.
 *  If `false` is returned, signal propagation to the remaining handlers will
 *  also be interrupted.
 *
 *  [Signature]
 *  bool <slot>(EPlayer receiver, EPlayer sender, BaseText message)
 *
 *  @param  receiver    `EPlayer` that will receive the message.
 *  @param  sender      `EPlayer` that has sent the message.
 *  @param  message     Message that `sender` has sent. This is an immutable
 *      variable and cannot be changed at this point. Use `OnMessage()`
 *      signal function for that.
 *  @return Return `false` to prevent this message from being sent to
 *      a particular player and `true` otherwise. Message will be sent only if
 *      all handlers will return `true`.
 *      However decision whether to send message or not is made for
 *      every player separately.
 */
/* SIGNAL */
public function ChatAPI_OnMessageFor_Slot OnMessageFor(
    AcediaObject receiver)
{
    TryConnectingBroadcastSignals();
    return ChatAPI_OnMessageFor_Slot(onMessageForSignal.NewSlot(receiver));
}

private function bool HandleText(
    Actor       sender,
    out string  message,
    name        messageType,
    bool        teamMessage)
{
    local bool          result;
    local MutableText   messageAsText;
    local EPlayer       senderPlayer;
    //  We only want to catch chat messages from a player
    if (messageType != 'Say' && messageType != 'TeamSay')   return true;
    senderPlayer = _.players.FromController(PlayerController(sender));
    if (senderPlayer == none)                               return true;

    messageAsText = __().text.FromColoredStringM(message);
    result = onMessageSignal.Emit(senderPlayer, messageAsText, teamMessage);
    message = messageAsText.ToColoredString();
    //      To correctly display chat messages we want to drop default color tag
    //  at the beginning (the one `ToColoredString()` adds if first character
    //  has no defined color).
    //      This is a compatibility consideration with vanilla UI that expects
    //  uncolored text. Not removing initial color tag will make chat text
    //  appear black.
    if (!messageAsText.GetFormatting(0).isColored) {
        message = Mid(message, 4);
    }
    _.memory.Free(messageAsText);
    _.memory.Free(senderPlayer);
    return result;
}

private function bool HandleTextFor(
    PlayerController    receiver,
    Actor               sender,
    out string          message,
    name                messageType)
{
    local bool      result;
    local Text      messageAsText;
    local EPlayer   senderPlayer, receiverPlayer;
    //  We only want to catch chat messages from another player
    if (messageType != 'Say' && messageType != 'TeamSay')   return true;
    senderPlayer = _.players.FromController(PlayerController(sender));
    if (senderPlayer == none)                               return true;

    receiverPlayer = _.players.FromController(receiver);
    if (receiverPlayer == none)
    {
        _.memory.Free(senderPlayer);
        return true;
    }
    messageAsText = __().text.FromColoredString(message);
    result = onMessageForSignal.Emit(   receiverPlayer, senderPlayer,
                                        messageAsText);
    _.memory.Free(messageAsText);
    _.memory.Free(senderPlayer);
    _.memory.Free(receiverPlayer);
    return result;
}

defaultproperties
{
}