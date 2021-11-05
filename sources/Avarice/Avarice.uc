/**
 *      Config object for `Avarice_Feature`.
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
class Avarice extends FeatureConfig
    perobjectconfig
    config(AcediaAvarice);

struct AvariceLinkRecord
{
    var string name;
    var string address;
};
//      List all the names (and addresses) of all Avarice instances Acedia must
//  connect to.
//      `name` parameter is a useful (case-insensitive) identifier that
//  can be used in other configs to point at each link.
//      `address` must have form "host:port", where "host" is either ip or
//  domain name and "port" is a numerical port value.
var public config array<AvariceLinkRecord> link;

//      In case Avarice utility is launched after link started trying open
//  the connection - that connection attempt will fail. To fix that link must
//  try connecting again.
//      This variable sets the time (in seconds), after which link will
//  re-attempt opening connection. Setting value too low can prevent any
//  connection from opening, setting it too high might make you wait for
//  connection too long.
var public config float reconnectTime;

protected function AssociativeArray ToData()
{
    local int               i;
    local AssociativeArray  data;
    local AssociativeArray  linkData;
    local DynamicArray      linksArray;
    data = __().collections.EmptyAssociativeArray();
    data.SetFloat(P("reconnectTime"), reconnectTime, true);
    linksArray = __().collections.EmptyDynamicArray();
    data.SetItem(P("link"), linksArray);
    for (i = 0; i < link.length; i += 1)
    {
        linkData = __().collections.EmptyAssociativeArray();
        linkData.SetItem(P("name"), __().text.FromString(link[i].name));
        linkData.SetItem(P("address"), __().text.FromString(link[i].address));
        linksArray.AddItem(linkData);
    }
    return data;
}

protected function FromData(AssociativeArray source)
{
    local int               i;
    local Text              nextText;
    local DynamicArray      linksArray;
    local AssociativeArray  nextLink;
    local AvariceLinkRecord nextRecord;
    if (source == none) {
        return;
    }
    reconnectTime = source.GetFloat(P("reconnectTime"));
    link.length = 0;
    linksArray = source.GetDynamicArray(P("link"));
    if (linksArray == none) {
        return;
    }
    for (i = 0; i < linksArray.GetLength(); i += 1)
    {
        nextLink = linksArray.GetAssociativeArray(i);
        if (nextLink == none) {
            continue;
        }
        nextText = nextLink.GetText(P("name"));
        if (nextText != none) {
            nextRecord.name = nextText.ToString();
        }
        nextText = nextLink.GetText(P("address"));
        if (nextText != none) {
            nextRecord.address = nextText.ToString();
        }
        link[i] = nextRecord;
    }
}

protected function DefaultIt()
{
    local AvariceLinkRecord defaultRecord;
    reconnectTime = 10.0;
    link.length = 0;
    defaultRecord.name = "avarice";
    defaultRecord.address = "127.0.0.1:1234";
    link[0] = defaultRecord;
}

defaultproperties
{
    configName = "AcediaAvarice"
}