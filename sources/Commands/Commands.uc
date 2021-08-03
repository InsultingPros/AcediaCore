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

var public config bool useChatInput;

protected function AssociativeArray ToData()
{
    local AssociativeArray data;
    data = __().collections.EmptyAssociativeArray();
    data.SetBool(P("useChatInput"), useChatInput, true);
    return data;
}

protected function FromData(AssociativeArray source)
{
    if (source != none) {
        useChatInput = source.GetBool(P("useChatInput"));
    }
}

protected function DefaultIt()
{
    useChatInput = true;
}

defaultproperties
{
    configName = "AcediaSystem"
}