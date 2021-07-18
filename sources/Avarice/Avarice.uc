/**
 *
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
class Avarice extends Feature
    config(AcediaAvarice);

struct AvariceLink
{
    var string name;
    var string host;
};

var private config array<AvariceLink> link;

var private LoggerAPI.Definition errorBadAddress;

protected function OnEnabled()
{
    local int               i;
    local string            host;
    local int               port;
    local AvariceTCPLink    nextTCPLink;
    for (i = 0; i < link.length; i += 1)
    {
        if (!ParseAddress(link[i].host, host, port)) {
            _.logger.Auto(errorBadAddress).Arg(_.text.FromString(link[i].name));
        }
        nextTCPLink = AvariceTCPLink(_.memory.Allocate(class'AvariceTCPLink'));
        nextTCPLink.Connect(link[i].name, host, port);
    }
}

protected function OnDisabled()
{
    local LevelInfo         level;
    local AvariceTCPLink    nextTCPLink;
    level = _.unreal.GetLevel();
    foreach level.DynamicActors(class'AvariceTCPLink', nextTCPLink) {
        nextTCPLink.Destroy();
    }
}

private final function bool ParseAddress(
    string      address,
    out string  host,
    out int     port)
{
    local bool      success;
    local Parser    parser;
    parser = _.text.ParseString(address);
    parser.Skip()
        .MUntilS(host, _.text.GetCharacter(":"))
        .MatchS(":")
        .MUnsignedInteger(port)
        .Skip();
    success = parser.Ok() && parser.GetRemainingLength() == 0;
    parser.FreeSelf();
    return success;
}

defaultproperties
{
    errorBadAddress = (l=LOG_Error,m="Cannot parse address \"%1\"")
}