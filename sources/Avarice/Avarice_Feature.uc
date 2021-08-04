/**
 *      This feature makes it possible to use TCP connection to exchange
 *  messages (represented by JSON objects) with external applications.
 *  There are some peculiarities to UnrealEngine's `TCPLink`, so to simplify
 *  communication process for external applications, they are expected to
 *  connect to the server through the "Avarice" utility that can accept a stream
 *  of utf8-encoded JSON messageand feed them to our `TCPLink` (we use child
 *  class `AvariceTcpStream`) in a way it can receive them.
 *      Every message sent to us must have the following structure:
 *  { "s": "<service_name>", "t": "<command_type>", "p": <any_json_value> }
 *  where
 *      * <service_name> describes a particular source of messages
 *          (it can be a name of the database or an alias for
 *          a connected application);
 *      * <command_type> simply states the name of a command, for a database it
 *          can be "get", "set", "delete", etc..
 *      * <any_json_value> can be an arbitrary json value and can be used to
 *          pass any additional information along with the message.
 *      Acedia provides a special treatment for any messages that have their
 *  service set to "echo" - it always returns them back as-is, except for the
 *  message type that gets set to "end".
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
class Avarice_Feature extends Feature
    dependson(Avarice);

var private /*config*/ array<Avarice.AvariceLinkRecord> link;
var private /*config*/ float reconnectTime;

//  The feature itself is dead simple - it simply creates list of
//  `AvariceLink` objects, according to its settings, and stores them
var private array<AvariceLink> createdLinks;

var private const int TECHO, TEND, TCOLON;

var private LoggerAPI.Definition errorBadAddress;

protected function OnEnabled()
{
    local int           i;
    local Text          name;
    local MutableText   host;
    local int           port;
    local AvariceLink   nextLink;
    for (i = 0; i < link.length; i += 1)
    {
        name = _.text.FromString(link[i].name);
        if (ParseAddress(link[i].address, host, port))
        {
            nextLink = AvariceLink(_.memory.Allocate(class'AvariceLink'));
            nextLink.Initialize(name, host, port);
            nextLink.StartUp();
            nextLink.OnMessage(self, T(TECHO)).connect = EchoHandler;
            createdLinks[createdLinks.length] = nextLink;
        }
        else
        {
            _.logger.Auto(errorBadAddress)
                .Arg(_.text.FromString(link[i].address))
                .Arg(_.text.FromString(link[i].name));
        }
        _.memory.Free(name);
        _.memory.Free(host);
    }
}

protected function OnDisabled()
{
    _.memory.FreeMany(createdLinks);
}

protected function SwapConfig(FeatureConfig config)
{
    local Avarice newConfig;
    newConfig = Avarice(config);
    if (newConfig == none) {
        return;
    }
    link            = newConfig.link;
    reconnectTime   = newConfig.reconnectTime;
    //  For static `GetReconnectTime()` method
    default.reconnectTime = reconnectTime;
}

//  Reply back any messages from "echo" service
private function EchoHandler(AvariceLink link, AvariceMessage message)
{
    link.SendMessage(T(TECHO), T(TEND), message.parameters);
}

private final function bool ParseAddress(
    string          address,
    out MutableText host,
    out int         port)
{
    local bool      success;
    local Parser    parser;
    parser = _.text.ParseString(address);
    parser.Skip()
        .MUntil(host, T(TCOLON).GetCharacter(0))
        .Match(T(TCOLON))
        .MUnsignedInteger(port)
        .Skip();
    success = parser.Ok() && parser.GetRemainingLength() == 0;
    parser.FreeSelf();
    return success;
}

/**
 *  Method that returns all the `AvariceLink` created by this feature.
 *
 *  @return Array of links created by this feature.
 *      Guaranteed to not contain `none` values.
 */
public final function array<AvariceLink> GetAllLinks()
{
    local int i;
    while (i < createdLinks.length)
    {
        if (createdLinks[i] == none) {
            createdLinks.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
    return createdLinks;
}

/**
 *  Returns its current `reconnectTime` setting that describes amount of time
 *  between connection attempts.
 *
 *  @return Value of `reconnectTime` config variable.
 */
public final static function float GetReconnectTime()
{
    return default.reconnectTime;
}

defaultproperties
{
    configClass = class'Avarice'
    //  `Text` constants
    TECHO               = 0
    stringConstants(0)  = "echo"
    TEND                = 1
    stringConstants(1)  = "end"
    TCOLON              = 2
    stringConstants(2)  = ":"
    //  Log messages
    errorBadAddress = (l=LOG_Error,m="Cannot parse address \"%1\" for \"%2\"")
}