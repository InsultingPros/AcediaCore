/**
 *  Set of tests for `FeatureConfig` class.
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
class TEST_FeatureConfig extends TestCase
    abstract;

protected static function TESTS()
{
    class'MockFeature'.static.Initialize();
    Context("Testing `FeatureConfig` functionality.");
    TEST_AvailableConfigs();
    TEST_DataGetSet();
    TEST_DataNew();
}

protected static function TEST_AvailableConfigs()
{
    local int           i;
    local bool          foundConfig;
    local array<Text>   configNames;
    configNames = class'MockFeature'.static.AvailableConfigs();
    Issue("Incorrect amount of configs are loaded.");
    TEST_ExpectTrue(configNames.length == 3);

    Issue("Configs with incorrect names or values are loaded.");
    for (i = 0; i < configNames.length; i += 1)
    {
        if (configNames[i].CompareToPlainString("default", SCASE_INSENSITIVE)) {
            foundConfig = true;
        }
    }
    TEST_ExpectTrue(foundConfig);
    foundConfig = false;
    for (i = 0; i < configNames.length; i += 1)
    {
        if (configNames[i].CompareToPlainString("other", SCASE_INSENSITIVE)) {
            foundConfig = true;
        }
    }
    TEST_ExpectTrue(foundConfig);
    foundConfig = false;
    for (i = 0; i < configNames.length; i += 1)
    {
        if (configNames[i].CompareToPlainString("another", SCASE_INSENSITIVE)) {
            foundConfig = true;
        }
    }
    TEST_ExpectTrue(foundConfig);
}

protected static function TEST_DataGetSet()
{
    local AssociativeArray data, newData;
    data = class'MockFeature'.static.LoadData(P("other"));
    Issue("Wrong value is loaded from config.");
    TEST_ExpectTrue(data.GetIntBy(P("/value")) == 11);

    newData = __().collections.EmptyAssociativeArray();
    newData.SetItem(P("value"), __().box.int(903));
    class'MockFeature'.static.SaveData(P("other"), newData);
    data = class'MockFeature'.static.LoadData(P("other"));
    Issue("Wrong value is loaded from config after saving another value.");
    TEST_ExpectTrue(data.GetIntBy(P("/value")) == 903);

    Issue("`FeatureConfig` returns `AssociativeArray` reference that was"
        @ "passed in `SaveData()` call instead of a new collection.");
    TEST_ExpectTrue(data != newData);

    //  Restore configs
    data.SetItem(P("value"), __().box.int(11));
    class'MockFeature'.static.SaveData(P("other"), data);
}

protected static function TEST_DataNew()
{
    local AssociativeArray data;
    Issue("Creating new config with existing name succeeds.");
    TEST_ExpectFalse(class'MockFeature'.static.NewConfig(P("another")));
    data = class'MockFeature'.static.LoadData(P("another"));
    TEST_ExpectTrue(data.GetIntBy(P("/value")) == -2956);

    Issue("Cannot create new config.");
    TEST_ExpectTrue(class'MockFeature'.static.NewConfig(P("new_one")));

    Issue("New config does not have expected default value.");
    data = class'MockFeature'.static.LoadData(P("new_one"));
    TEST_ExpectTrue(data.GetIntBy(P("/value")) == 13);

    //  Restore configs, cannot properly test `DeleteConfig()`
    class'MockFeature'.static.DeleteConfig(P("new_one"));
}

defaultproperties
{
    caseName    = "FeatureConfig"
    caseGroup   = "Features"
}