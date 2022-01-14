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

var public config bool      useChatInput;
var public config bool      useMutateInput;
var public config string    chatCommandPrefix;

protected function AssociativeArray ToData()
{
    local AssociativeArray data;
    data = __().collections.EmptyAssociativeArray();
    data.SetBool(P("useChatInput"), useChatInput, true);
    data.SetBool(P("useMutateInput"), useMutateInput, true);
    data.SetItem(   P("chatCommandPrefix"),
                    _.text.FromString(chatCommandPrefix), true);
    return data;
}

protected function FromData(AssociativeArray source)
{
    local Text newChatPrefix;
    if (source == none) {
        return;
    }
    useChatInput    = source.GetBool(P("useChatInput"));
    useMutateInput  = source.GetBool(P("useMutateInput"));
    newChatPrefix = source.GetText(P("chatCommandPrefix"));
    chatCommandPrefix = "!";
    if (newChatPrefix != none) {
        chatCommandPrefix = newChatPrefix.ToString();
    }
    _.memory.Free(newChatPrefix);
}

protected function DefaultIt()
{
    useChatInput        = true;
    useMutateInput      = true;
    chatCommandPrefix   = "!";
}

defaultproperties
{
    configName = "AcediaSystem"
    useChatInput        = true
    useMutateInput      = true
    chatCommandPrefix   = "!"
}