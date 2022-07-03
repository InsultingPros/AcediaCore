/**
 *  Set of tests for `AcediaConfig` class.
 *      Copyright 2021-2022 Anton Tarasenko
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
class TEST_AcediaConfig extends TestCase
    abstract;

protected static function TESTS()
{
    class'MockConfig'.static.Initialize();
    Context("Testing `AcediaConfig` functionality.");
    TEST_AvailableConfigs();
    TEST_DataGetSet();
    TEST_DataNew();
    TEST_BadName();
}

protected static function TEST_AvailableConfigs()
{
    local int           i;
    local bool          foundConfig;
    local array<Text>   configNames;
    configNames = class'MockConfig'.static.AvailableConfigs();
    Issue("Incorrect amount of configs are loaded.");
    TEST_ExpectTrue(configNames.length == 3);

    Issue("Configs with incorrect names or values are loaded.");
    for (i = 0; i < configNames.length; i += 1)
    {
        if (configNames[i].CompareToString("default", SCASE_INSENSITIVE)) {
            foundConfig = true;
        }
    }
    TEST_ExpectTrue(foundConfig);
    foundConfig = false;
    for (i = 0; i < configNames.length; i += 1)
    {
        if (configNames[i].CompareToString("other", SCASE_INSENSITIVE)) {
            foundConfig = true;
        }
    }
    TEST_ExpectTrue(foundConfig);
    foundConfig = false;
    for (i = 0; i < configNames.length; i += 1)
    {
        if (configNames[i].CompareToString("another.config",
                                                SCASE_INSENSITIVE)) {
            foundConfig = true;
        }
    }
    TEST_ExpectTrue(foundConfig);
}

protected static function TEST_DataGetSet()
{
    local HashTable data, newData;
    data = class'MockConfig'.static.LoadData(P("other"));
    Issue("Wrong value is loaded from config.");
    TEST_ExpectTrue(data.GetIntBy(P("/value")) == 11);

    newData = __().collections.EmptyHashTable();
    newData.SetItem(P("value"), __().box.int(903));
    class'MockConfig'.static.SaveData(P("other"), newData);
    data = class'MockConfig'.static.LoadData(P("other"));
    Issue("Wrong value is loaded from config after saving another value.");
    TEST_ExpectTrue(data.GetIntBy(P("/value")) == 903);

    Issue("`AcediaConfig` returns `HashTable` reference that was"
        @ "passed in `SaveData()` call instead of a new collection.");
    TEST_ExpectTrue(data != newData);

    //  Restore configs
    data.SetItem(P("value"), __().box.int(11));
    class'MockConfig'.static.SaveData(P("other"), data);
}

protected static function TEST_DataNew()
{
    local HashTable data;
    Issue("Creating new config with existing name succeeds.");
    TEST_ExpectFalse(class'MockConfig'.static.NewConfig(P("another.config")));
    data = class'MockConfig'.static.LoadData(P("another.config"));
    TEST_ExpectTrue(data.GetIntBy(P("/value")) == -2956);

    Issue("Cannot create new config.");
    TEST_ExpectTrue(class'MockConfig'.static.NewConfig(P("new_one")));

    Issue("New config does not have expected default value.");
    data = class'MockConfig'.static.LoadData(P("new_one"));
    TEST_ExpectTrue(data.GetIntBy(P("/value")) == 13);

    //  Restore configs, cannot properly test `DeleteConfig()`
    class'MockConfig'.static.DeleteConfig(P("new_one"));
}

protected static function TEST_BadName()
{
    Issue("`AcediaConfig` allows creation of config objects with"
        @ "invalid names.");
    TEST_ExpectFalse(class'MockConfig'.static.NewConfig(P("new:config")));
    TEST_ExpectFalse(class'MockConfig'.static.NewConfig(P("what]")));
    TEST_ExpectFalse(class'MockConfig'.static.NewConfig(P("why#not")));
    TEST_ExpectFalse(class'MockConfig'.static.NewConfig(P("stop@it")));
}

defaultproperties
{
    caseName    = "AcediaConfig"
    caseGroup   = "Config"
}