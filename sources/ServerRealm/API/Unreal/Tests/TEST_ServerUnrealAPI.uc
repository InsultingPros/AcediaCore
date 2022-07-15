/**
 *  Set of tests for `ServerUnrealAPI` class.
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
class TEST_ServerUnrealAPI extends TestCase;

protected static function int CountRulesAmount(class<gameRules> gameRulesClass)
{
    local int       counter;
    local gameRules rulesIter;
    if (gameRulesClass == none) {
        return 0;
    }
    rulesIter = __server().unreal.GetGameType().gameRulesModifiers;
    while (rulesIter != none)
    {
        if (rulesIter.class == gameRulesClass) {
            counter += 1;
        }
        rulesIter = rulesIter.nextgameRules;
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
    TEST_ExpectNotNone(__server().unreal.GetGameType());
    Issue("`GetKFGameType()` returns `none`.");
    TEST_ExpectNotNone(__server().unreal.GetKFGameType());
    Issue("`GetGameType()` and `GetKFGameType()` return different values.");
    TEST_ExpectTrue(    __server().unreal.GetGameType()
                    ==  __server().unreal.GetKFGameType());
}

protected static function Test_GameRules()
{
    Context("Testing methods for working with `gameRules`.");
    SubTest_AddRemoveGameRules();
    SubTest_CheckGameRules();
}

protected static function SubTest_AddRemoveGameRules()
{
    Issue("`gameRules.Add()` does not add game rules.");
    __server().unreal.gameRules.Add(class'MockGameRulesA');
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesA') == 1);

    __server().unreal.gameRules.Add(class'MockGameRulesA');
    Issue("Calling `gameRules.Add()` twice leads to rule duplication.");
    TEST_ExpectFalse(CountRulesAmount(class'MockGameRulesA') > 1);
    Issue("Calling `gameRules.Add()` leads to rule not being added.");
    TEST_ExpectFalse(CountRulesAmount(class'MockGameRulesA') == 0);

    Issue("Adding new rules with `gameRules.Add()` does not work properly.");
    __server().unreal.gameRules.Add(class'MockGameRulesB');
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesA') == 1);
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesB') == 1);

    Issue("Adding/removing rules with `gameRules.Remove()` leads to" @
        "unexpected results.");
    __server().unreal.gameRules.Remove(class'MockGameRulesB');
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesA') == 1);
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesB') == 0);
    __server().unreal.gameRules.Add(class'MockGameRulesB');
    __server().unreal.gameRules.Remove(class'MockGameRulesA');
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesA') == 0);
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesB') == 1);
    __server().unreal.gameRules.Remove(class'MockGameRulesB');
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesA') == 0);
    TEST_ExpectTrue(CountRulesAmount(class'MockGameRulesB') == 0);
}

protected static function SubTest_CheckGameRules()
{
    local string issueForAdded, issueForNotAdded;
    issueForAdded = "`gameRules.AreAdded()` returns `false` for rules that"
        @ "are currently added.";
    issueForNotAdded = "`gameRules.AreAdded()` returns `true` for rules that" @
        "are not currently added.";
    __server().unreal.gameRules.Remove(class'MockGameRulesA');
    __server().unreal.gameRules.Remove(class'MockGameRulesB');
    Issue(issueForNotAdded);
    TEST_ExpectFalse(__server().unreal.gameRules
        .AreAdded(class'MockGameRulesA'));
    TEST_ExpectFalse(__server().unreal.gameRules
        .AreAdded(class'MockGameRulesB'));

    __server().unreal.gameRules.Add(class'MockGameRulesB');
    Issue(issueForNotAdded);
    TEST_ExpectFalse(__server().unreal.gameRules
        .AreAdded(class'MockGameRulesA'));
    Issue(issueForAdded);
    TEST_ExpectTrue(__server().unreal.gameRules
        .AreAdded(class'MockGameRulesB'));

    __server().unreal.gameRules.Add(class'MockGameRulesA');
    Issue(issueForAdded);
    TEST_ExpectTrue(__server().unreal.gameRules
        .AreAdded(class'MockGameRulesA'));
    TEST_ExpectTrue(__server().unreal.gameRules
        .AreAdded(class'MockGameRulesB'));

    __server().unreal.gameRules.Remove(class'MockGameRulesB');
    Issue(issueForAdded);
    TEST_ExpectTrue(__server().unreal.gameRules
        .AreAdded(class'MockGameRulesA'));
    Issue(issueForNotAdded);
    TEST_ExpectFalse(__server().unreal.gameRules.AreAdded(class'MockGameRulesB'));
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
    chainEnd.inventory =
        Inventory(__().memory.Allocate(class'MockInventoryAChild'));
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
            __server().unreal.inventory.Get(class'MockInventoryA', chain)
        ==  chain.inventory.inventory);
    TEST_ExpectTrue(
            __server().unreal.inventory.Get(class'MockInventoryB', chain)
        ==  chain.inventory);
    TEST_ExpectTrue(
            __server().unreal.inventory.Get(class'MockInventoryAChild', chain)
        ==  chain);

    Issue("Incorrectly finds missing inventory entries.");
    TEST_ExpectNone(__server().unreal.inventory.Get(none, chain));
    TEST_ExpectNone(__server().unreal.inventory.Get(class'Winchester', chain));

    Issue("Does not find correct first entry inside the inventory chain when" @
        "allowing for child classes.");
    TEST_ExpectTrue(
            __server().unreal.inventory.Get(class'MockInventoryA', chain, true)
        ==  chain);
    TEST_ExpectTrue(
            __server().unreal.inventory.Get(class'MockInventoryB', chain, true)
        ==  chain.inventory);
    TEST_ExpectTrue(
        __server().unreal.inventory.Get(class'MockInventoryAChild', chain, true)
        == chain);

    Issue("Incorrectly finds missing inventory entries when allowing for" @
        "child classes.");
    TEST_ExpectNone(__server().unreal.inventory.Get(none, chain, true));
    TEST_ExpectNone(__server().unreal.inventory.Get(  class'Winchester', chain,
                                                true));
}

protected static function SubTest_InventoryChainFetchingMany(Inventory chain)
{
    local array<Inventory> result;
    Issue("Does not find correct entries inside the inventory chain.");
    result = __server().unreal.inventory.GetAll(class'MockInventoryB', chain);
    TEST_ExpectTrue(result.length == 2);
    TEST_ExpectTrue(result[0] == chain.inventory);
    TEST_ExpectTrue(result[1] == chain.inventory.inventory.inventory.inventory);

    Issue("Does not find correct entries inside the inventory chain when" @
        "allowing for child classes.");
    result =
        __server().unreal.inventory.GetAll(class'MockInventoryB', chain, true);
    TEST_ExpectTrue(result.length == 2);
    TEST_ExpectTrue(result[0] == chain.inventory);
    TEST_ExpectTrue(result[1] == chain.inventory.inventory.inventory.inventory);
    result =
        __server().unreal.inventory.GetAll(class'MockInventoryA', chain, true);
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
    result = __server().unreal.inventory.GetAll(class'Winchester', chain);
    TEST_ExpectTrue(result.length == 0);
    result = __server().unreal.inventory.GetAll(class'Winchester', chain, true);
    TEST_ExpectTrue(result.length == 0);
}

defaultproperties
{
    caseName = "ServerUnrealAPI"
    caseGroup = "Unreal"
}