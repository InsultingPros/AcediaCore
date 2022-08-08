/**
 *      Config object for `Commands_Feature`.
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
class Commands extends FeatureConfig
    perobjectconfig
    config(AcediaSystem);

var public config bool          useChatInput;
var public config bool          useMutateInput;
var public config string        chatCommandPrefix;
var public config array<string> allowedPlayers;

protected function HashTable ToData()
{
    local int       i;
    local HashTable data;
    local ArrayList playerList;

    data = __().collections.EmptyHashTable();
    data.SetBool(P("useChatInput"), useChatInput, true);
    data.SetBool(P("useMutateInput"), useMutateInput, true);
    data.SetString(P("chatCommandPrefix"), chatCommandPrefix);
    playerList = _.collections.EmptyArrayList();
    for (i = 0; i < allowedPlayers.length; i += 1) {
        playerList.AddString(allowedPlayers[i]);
    }
    data.SetItem(P("allowedPlayers"), playerList);
    playerList.FreeSelf();
    return data;
}

protected function FromData(HashTable source)
{
    local int       i;
    local ArrayList playerList;

    if (source == none) {
        return;
    }
    useChatInput        = source.GetBool(P("useChatInput"));
    useMutateInput      = source.GetBool(P("useMutateInput"));
    chatCommandPrefix   = source.GetString(P("chatCommandPrefix"), "!");
    playerList          = source.GetArrayList(P("allowedPlayers"));
    allowedPlayers.length = 0;
    if (playerList == none) {
        return;
    }
    for (i = 0; i < playerList.GetLength(); i += 1) {
        allowedPlayers[allowedPlayers.length] = playerList.GetString(i);
    }
    playerList.FreeSelf();
}

protected function DefaultIt()
{
    useChatInput            = true;
    useMutateInput          = true;
    chatCommandPrefix       = "!";
    allowedPlayers.length   = 0;
}

defaultproperties
{
    configName = "AcediaSystem"
    useChatInput        = true
    useMutateInput      = true
    chatCommandPrefix   = "!"
}