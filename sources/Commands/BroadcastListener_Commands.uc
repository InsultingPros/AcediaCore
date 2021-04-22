/**
 *      Overloaded broadcast events listener to catch commands input from
 *  the in-game chat.
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
class BroadcastListener_Commands extends BroadcastListenerBase
    abstract;

//  TODO: reimplement with even to provide `APlayer` in the first place
static function bool HandleText(
    Actor           sender,
    out string      message,
    optional name   messageType)
{
    local Text          messageAsText;
    local APlayer       callerPlayer;
    local Parser        parser;
    local Commands      commandFeature;
    local PlayerService service;
    //  We only want to catch chat messages
    //  and only if `Commands` feature is active
    if (messageType != 'Say')           return true;
    commandFeature = Commands(class'Commands'.static.GetInstance());
    if (commandFeature == none)         return true;
    if (!commandFeature.useChatInput)   return true;
    //  We are only interested in messages that start with "!"
    parser = __().text.ParseString(message);
    if (!parser.Match(P("!")).Ok())
    {
        parser.FreeSelf();
        //  Convert color tags into colors
        messageAsText = __().text.FromFormattedString(message);
        message = messageAsText.ToColoredString(,, __().color.White);
        messageAsText.FreeSelf();
        return true;
    }
    //  Extract `APlayer` from the `sender`
    service = PlayerService(class'PlayerService'.static.Require());
    if (service != none) {
        callerPlayer = service.GetPlayer(PlayerController(sender));
    }
    //  Pass input to command feature
    commandFeature.HandleInput(parser, callerPlayer);
    parser.FreeSelf();
    return false;
}

defaultproperties
{
}