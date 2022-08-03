/**
 *      Config object for `Aliases_Feature`.
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
class Aliases extends FeatureConfig
    perobjectconfig
    config(AcediaAliases);

struct CustomSourceRecord
{
    var string              name;
    var class<AliasSource>  source;
};

var public config class<AliasSource>        weaponAliasSource;
var public config class<AliasSource>        colorAliasSource;
var public config class<AliasSource>        featureAliasSource;
var public config class<AliasSource>        entityAliasSource;
var public config array<CustomSourceRecord> customSource;

protected function HashTable ToData()
{
    local int       i;
    local Text      nextKey;
    local HashTable data, otherSourcesData;

    data = __().collections.EmptyHashTable();
    //  Add named aliases
    data.SetString(P("weapon"),   string(weaponAliasSource));
    data.SetString(P("color"),    string(colorAliasSource));
    data.SetString(P("feature"),  string(featureAliasSource));
    data.SetString(P("entity"),   string(entityAliasSource));
    //  Add the rest
    otherSourcesData = __().collections.EmptyHashTable();
    for (i = 0; i < customSource.length; i += 1)
    {
        nextKey = _.text.FromString(customSource[i].name);
        otherSourcesData.SetString(nextKey, string(customSource[i].source));
        nextKey.FreeSelf();
    }
    data.SetItem(P("other"), otherSourcesData);
    otherSourcesData.FreeSelf();
    return data;
}

protected function FromData(HashTable source)
{
    local HashTable otherSourcesData;

    if (source == none) {
        return;
    }
    //  We cast `class` into `string`
    //  (e.g. `string(class'AcediaAliases_Weapons')`)
    //  instead of writing full name of the class so that code is independent
    //  from this package's name, making it easier to change later
    weaponAliasSource = class<AliasSource>(_.memory.LoadClass_S(
        source.GetString(P("weapon"), string(class'WeaponAliasSource'))));
    colorAliasSource = class<AliasSource>(_.memory.LoadClass_S(
        source.GetString(P("color"), string(class'ColorAliasSource'))));
    featureAliasSource = class<AliasSource>(_.memory.LoadClass_S(
        source.GetString(P("feature"), string(class'FeatureAliasSource'))));
    entityAliasSource = class<AliasSource>(_.memory.LoadClass_S(
        source.GetString(P("entity"), string(class'EntityAliasSource'))));
    otherSourcesData = source.GetHashTable(P("other"));
    if (otherSourcesData != none)
    {
        ReadOtherSources(otherSourcesData);
        otherSourcesData.FreeSelf();
    }
}

//  Doesn't check whether `otherSources` is `none`
protected function ReadOtherSources(HashTable otherSourcesData)
{
    local CustomSourceRecord    newRecord;
    local BaseText              keyAsText, valueAsText;
    local AcediaObject          key, value;
    local HashTableIterator     iter;

    customSource.length = 0;
    iter = HashTableIterator(otherSourcesData.Iterate().LeaveOnlyNotNone());
    for (iter = iter; !iter.HasFinished(); iter.Next())
    {
        key     = iter.GetKey();
        value   = iter.GetKey();
        keyAsText   = BaseText(key);
        valueAsText = BaseText(value);
        if (keyAsText != none && valueAsText != none)
        {
            newRecord.name      = keyAsText.ToString();
            newRecord.source    = class<AliasSource>(
                _.memory.LoadClass_S(valueAsText.ToString()));
            if (newRecord.source != none) {
                customSource[customSource.length] = newRecord;
            }
        }
        _.memory.Free(key);
        _.memory.Free(value);
    }
}

protected function DefaultIt()
{
    customSource.length = 0;
    weaponAliasSource   = class'WeaponAliasSource';
    colorAliasSource    = class'ColorAliasSource';
    featureAliasSource  = class'FeatureAliasSource';
    entityAliasSource   = class'EntityAliasSource';
}

defaultproperties
{
    configName = "AcediaAliases"
    weaponAliasSource   = class'WeaponAliasSource'
    colorAliasSource    = class'ColorAliasSource'
    featureAliasSource  = class'FeatureAliasSource'
    entityAliasSource   = class'EntityAliasSource'
}