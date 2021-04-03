/**
 *  Set of tests for `UnrealAPI` class.
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
class TEST_UnrealAPI extends TestCase;

protected static function int CountRulesAmount(class<GameRules> gameRulesClass)
{
    local int       counter;
    local GameRules rulesIter;
    if (gameRulesClass == none) {
        return 0;
    }
    rulesIter = __().unreal.GetGameType().gameRulesModifiers;
    while (rulesIter != none)
    {
        if (rulesIter.class == gameRulesClass) {
            counter += 1;
        }
        rulesIter = rulesIter.nextGameRules;
    }
    return counter;
}

protected static function TESTS()
{
    Test_GameType();
    Test_GameRules();
    Test_InventoryChainFetching();
}

protected static function Test_GameType()
{
    Context("Testing methods for returning `GameType` class.");
    Issue("`GetGameType()` returns `none`.");
    TEST_ExpectNotNone(__().unreal.GetGameType());
    Issue("`GetKFGameType()` returns `none`.");
    TEST_ExpectNotNone(__().unreal.GetKFGameType());
    Issue("`GetGameType()` and `GetKFGameType()` return different values.");
    TEST_ExpectTrue(__().unreal.GetGameType() == __().unreal.GetKFGameType());
}

protected static function Test_GameRules()
{
    Context("Testing methods for working with `GameRules`.");
    SubTest_AddRemoveGameRules();
    SubTest_CheckGameRules();
}

protected static function SubTest_AddRemoveGameRules()
{
    Issue("`AddGameRules()` does not add game rules.");
    __().unreal.AddGameRules(class'MockGameRulesA');
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesA') == 1);

    __().unreal.AddGameRules(class'MockGameRulesA');
    Issue("Calling `AddGameRules()` twice leads to rule duplication.");
    TEST_ExpectFalse(CountRulesAmount(class'MockGameRulesA') > 1);
    Issue("Calling `AddGameRules()` leads to rule not being added.");
    TEST_ExpectFalse(CountRulesAmount(class'MockGameRulesA') == 0);

    Issue("Adding new rules with `AddGameRules()` does not work properly.");
    __().unreal.AddGameRules(class'MockGameRulesB');
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesA') == 1);
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesB') == 1);

    Issue("Adding/removing rules with `RemoveGameRules()` leads to" @
        "unexpected results.");
    __().unreal.RemoveGameRules(class'MockGameRulesB');
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesA') == 1);
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesB') == 0);
    __().unreal.AddGameRules(class'MockGameRulesB');
    __().unreal.RemoveGameRules(class'MockGameRulesA');
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesA') == 0);
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesB') == 1);
    __().unreal.RemoveGameRules(class'MockGameRulesB');
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesA') == 0);
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesB') == 0);
}

protected static function SubTest_CheckGameRules()
{
    local string issueForAdded, issueForNotAdded;
    issueForAdded = "`AreGameRulesAdded()` returns `false` for rules that are" @
        "currently added.";
    issueForNotAdded = "`AreGameRulesAdded()` returns `true` for rules that" @
        "are not currently added.";
    __().unreal.RemoveGameRules(class'MockGameRulesA');
    __().unreal.RemoveGameRules(class'MockGameRulesB');
    Issue(issueForNotAdded);
    TEST_ExpectFalse(__().unreal.AreGameRulesAdded(class'MockGameRulesA'));
    TEST_ExpectFalse(__().unreal.AreGameRulesAdded(class'MockGameRulesB'));

    __().unreal.AddGameRules(class'MockGameRulesB');
    Issue(issueForNotAdded);
    TEST_ExpectFalse(__().unreal.AreGameRulesAdded(class'MockGameRulesA'));
    Issue(issueForAdded);
    TEST_ExpectTrue(__().unreal.AreGameRulesAdded(class'MockGameRulesB'));

    __().unreal.AddGameRules(class'MockGameRulesA');
    Issue(issueForAdded);
    TEST_ExpectTrue(__().unreal.AreGameRulesAdded(class'MockGameRulesA'));
    TEST_ExpectTrue(__().unreal.AreGameRulesAdded(class'MockGameRulesB'));

    __().unreal.RemoveGameRules(class'MockGameRulesB');
    Issue(issueForAdded);
    TEST_ExpectTrue(__().unreal.AreGameRulesAdded(class'MockGameRulesA'));
    Issue(issueForNotAdded);
    TEST_ExpectFalse(__().unreal.AreGameRulesAdded(class'MockGameRulesB'));
}

protected static function Test_InventoryChainFetching()
{
    local Inventory chainStart, chainEnd;
    //  a - B - A - a - B - a - A,
    //  where   A = `MockInventoryA`
    //          a = `MockInventoryAChild`
    //          B = `MockInventoryB`
    chainStart = Inventory(__().memory.Allocate(class'MockInventoryAChild'));
    chainEnd = chainStart;
    chainEnd.inventory = Inventory(__().memory.Allocate(class'MockInventoryB'));
    chainEnd = chainEnd.inventory;
    chainEnd.inventory = Inventory(__().memory.Allocate(class'MockInventoryA'));
    chainEnd = chainEnd.inventory;
    chainEnd.inventory = Inventory(__().memory.Allocate(class'MockInventoryAChild'));
    chainEnd = chainEnd.inventory;
    chainEnd.inventory = Inventory(__().memory.Allocate(class'MockInventoryB'));
    chainEnd = chainEnd.inventory;
    chainEnd.inventory =
        Inventory(__().memory.Allocate(class'MockInventoryAChild'));
    chainEnd = chainEnd.inventory;
    chainEnd.inventory = Inventory(__().memory.Allocate(class'MockInventoryA'));
    chainEnd = chainEnd.inventory;
    Context("Testing auxiliary methods for working with inventory chains.");
    SubTest_InventoryChainFetchingSingle(chainStart);
    SubTest_InventoryChainFetchingMany(chainStart);
}

protected static function SubTest_InventoryChainFetchingSingle(Inventory chain)
{
    Issue("Does not find correct first entry inside the inventory chain.");
    TEST_ExpectTrue(
            __().unreal.GetInventoryFrom(class'MockInventoryA', chain)
        ==  chain.inventory.inventory);
    TEST_ExpectTrue(
            __().unreal.GetInventoryFrom(class'MockInventoryB', chain)
        ==  chain.inventory);
    TEST_ExpectTrue(
            __().unreal.GetInventoryFrom(class'MockInventoryAChild', chain)
        ==  chain);

    Issue("Incorrectly finds missing inventory entries.");
    TEST_ExpectNone(__().unreal.GetInventoryFrom(none, chain));
    TEST_ExpectNone(__().unreal.GetInventoryFrom(class'Winchester', chain));

    Issue("Does not find correct first entry inside the inventory chain when" @
        "allowing for child classes.");
    TEST_ExpectTrue(
            __().unreal.GetInventoryFrom(class'MockInventoryA', chain, true)
        ==  chain);
    TEST_ExpectTrue(
            __().unreal.GetInventoryFrom(class'MockInventoryB', chain, true)
        ==  chain.inventory);
    TEST_ExpectTrue(
        __().unreal.GetInventoryFrom(class'MockInventoryAChild', chain, true)
        == chain);

    Issue("Incorrectly finds missing inventory entries when allowing for" @
        "child classes.");
    TEST_ExpectNone(__().unreal.GetInventoryFrom(none, chain, true));
    TEST_ExpectNone(__().unreal.GetInventoryFrom(   class'Winchester', chain,
                                                    true));
}

protected static function SubTest_InventoryChainFetchingMany(Inventory chain)
{
    local array<Inventory> result;
    Issue("Does not find correct entries inside the inventory chain.");
    result = __().unreal.GetAllInventoryFrom(class'MockInventoryB', chain);
    TEST_ExpectTrue(result.length == 2);
    TEST_ExpectTrue(result[0] == chain.inventory);
    TEST_ExpectTrue(result[1] == chain.inventory.inventory.inventory.inventory);

    Issue("Does not find correct entries inside the inventory chain when" @
        "allowing for child classes.");
    result =
        __().unreal.GetAllInventoryFrom(class'MockInventoryB', chain, true);
    TEST_ExpectTrue(result.length == 2);
    TEST_ExpectTrue(result[0] == chain.inventory);
    TEST_ExpectTrue(result[1] == chain.inventory.inventory.inventory.inventory);
    result =
        __().unreal.GetAllInventoryFrom(class'MockInventoryA', chain, true);
    TEST_ExpectTrue(result.length == 5);
    TEST_ExpectTrue(result[0] == chain);
    TEST_ExpectTrue(result[1] == chain.inventory.inventory);
    TEST_ExpectTrue(result[2] == chain.inventory.inventory.inventory);
    TEST_ExpectTrue(
            result[3]
        ==  chain.inventory.inventory.inventory.inventory.inventory);
    TEST_ExpectTrue(
            result[4]
        ==  chain.inventory.inventory.inventory.inventory.inventory.inventory);
    
    Issue("Does not return empty array for non-existing inventory class.");
    result = __().unreal.GetAllInventoryFrom(class'Winchester', chain);
    TEST_ExpectTrue(result.length == 0);
    result = __().unreal.GetAllInventoryFrom(class'Winchester', chain, true);
    TEST_ExpectTrue(result.length == 0);
}

defaultproperties
{
    caseName = "UnrealAPI"
    caseGroup = "Unreal"
}