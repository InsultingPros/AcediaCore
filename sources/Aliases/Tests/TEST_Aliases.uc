/**
 *  Set of tests for Aliases system.
 *      Copyright 2020 Anton Tarasenko
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
class TEST_Aliases extends TestCase
    abstract;

protected static function TESTS()
{
    Context("Testing loading aliases from a mock object `MockAliasSource`.");
    Issue("`GetCustomSource()` fails to return alias source.");
    TEST_ExpectNotNone(__().alias.GetCustomSource(P("mock")));
    SubTest_AliasLoadingCorrect();
    SubTest_AliasLoadingIncorrect();
}

protected static function SubTest_AliasLoadingCorrect()
{
    local BaseAliasSource source;
    Issue("`Resolve()` fails to return alias value that should be loaded.");
    source = __().alias.GetCustomSource(P("mock"));
    TEST_ExpectTrue(source.Resolve(P("Global")).ToString() == "value");
    TEST_ExpectTrue(source.Resolve(P("ford")).ToString() == "car");

    Issue("`Resolve()` fails to return passed alias after failure to"
        @ "load it's value.");
    TEST_ExpectTrue(    source.Resolve(P("nothinMuch"), true).ToString()
                    ==  "nothinMuch");
    TEST_ExpectTrue(    source.Resolve(P("random"), true).ToString()
                    ==  "random");

    Issue("`HasAlias()` reports alias, that should be present,"
        @ "as missing.");
    TEST_ExpectTrue(source.HasAlias(P("Global")));
    TEST_ExpectTrue(source.HasAlias(P("audi")));

    Issue("Aliases in per-object-configs incorrectly handle ':'.");
    TEST_ExpectTrue(    source.Resolve(P("HardToBeAGod")).ToString()
                    ==  "sci.fi");

    Issue("Aliases corresponding to empty values are handled incorrectly.");
    TEST_ExpectTrue(source.Resolve(P("also")).ToString() == "");
}

protected static function SubTest_AliasLoadingIncorrect()
{
    local BaseAliasSource source;
    Issue("`AliasAPI` cannot return value custom source.");
    source = __().alias.GetCustomSource(P("mock"));
    TEST_ExpectNotNone(source);

    Issue("`Resolve()` reports success of finding inexistent alias.");
    source = __().alias.GetCustomSource(P("mock"));
    TEST_ExpectNone(source.Resolve(P("noSuchThing")));

    Issue("`HasAlias()` reports inexistent alias as present.");
    TEST_ExpectFalse(source.HasAlias(P("FordК")));
}

defaultproperties
{
    caseName    = "AliasAPI"
    caseGroup   = "Aliases"
}