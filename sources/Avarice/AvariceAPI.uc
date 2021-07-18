/**
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
class AvariceAPI extends AcediaObject;

public final function AvariceMessage MessageFromText(Text message)
{
    local Parser            parser;
    local AvariceMessage    result;
    local AssociativeArray  parsedMessage;
    if (message == none) return none;
    parser = _.text.Parse(message);
    parsedMessage = _.json.ParseObjectWith(parser);
    parser.FreeSelf();
    if (!HasNecessaryMessageKeys(parsedMessage))
    {
        _.memory.Free(parsedMessage);
        return none;
    }
    result = AvariceMessage(_.memory.Allocate(class'AvariceMessage'));
    result.SetID(parsedMessage.GetText(P("i")));
    result.SetGroup(parsedMessage.GetText(P("g")));
    result.data = parsedMessage.TakeItem(P("p"));
    _.memory.Free(parsedMessage);
    return result;
}

private final function bool HasNecessaryMessageKeys(AssociativeArray message)
{
    if (message == none)            return false;
    if (!message.HasKey(P("i")))    return false;
    if (!message.HasKey(P("g")))    return false;

    return true;
}

defaultproperties
{
}