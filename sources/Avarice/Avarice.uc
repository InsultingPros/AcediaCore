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

protected function HashTable ToData()
{
    local int       i;
    local HashTable data;
    local HashTable linkData;
    local ArrayList linksArray;
    data = __().collections.EmptyHashTable();
    data.SetFloat(P("reconnectTime"), reconnectTime, true);
    linksArray = __().collections.EmptyArrayList();
    data.SetItem(P("link"), linksArray);
    for (i = 0; i < link.length; i += 1)
    {
        linkData = __().collections.EmptyHashTable();
        linkData.SetString(P("name"), link[i].name);
        linkData.SetString(P("address"), link[i].address);
        linksArray.AddItem(linkData);
        linkData.FreeSelf();
    }
    linksArray.FreeSelf();
    return data;
}

protected function FromData(HashTable source)
{
    local int               i;
    local ArrayList         linksArray;
    local HashTable         nextLink;
    local AvariceLinkRecord nextRecord;
    if (source == none) {
        return;
    }
    reconnectTime = source.GetFloat(P("reconnectTime"));
    link.length = 0;
    linksArray = source.GetArrayList(P("link"));
    if (linksArray == none) {
        return;
    }
    for (i = 0; i < linksArray.GetLength(); i += 1)
    {
        nextLink = linksArray.GetHashTable(i);
        if (nextLink == none) {
            continue;
        }
        nextRecord.name = nextLink.GetString(P("name"));
        nextRecord.address = nextLink.GetString(P("address"));
        link[i] = nextRecord;
        _.memory.Free(nextLink);
    }
    _.memory.Free(linksArray);
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