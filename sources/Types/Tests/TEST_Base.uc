/**
 *      Set of tests for some of the build-in methods for
 *  Acedia's objects/actors.
 *      Copyright 2020-2022 Anton Tarasenko
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
class TEST_Base extends TestCase
    abstract;

protected static function TESTS()
{
    //  Use test case itself to test `Text`-returning methods
    StaticConstructor();
    Test_QuickText();
    Test_Constants();
}

protected static function Test_QuickText()
{
    local int       lifeVersion;
    local Text      oldText;
    local string    plain, colored, formatted;
    plain = "Plain string";
    colored = "Colored " $ __().color.GetColorTagRGB(0, 0, 128) $ "string!";
    formatted = "{#ff0000 Plain str}i{#00ff00 ng}";
    Context("Testing `P()`/`C()`/`F()` methods for creating texts.");
    Issue("Methods return `Text`s with incorrect data.");
    TEST_ExpectTrue(P(plain).ToString() == "Plain string");
    TEST_ExpectTrue(C(colored).ToFormattedString()
        ==  "Colored {rgb(1,1,128) string!}");
    TEST_ExpectTrue(F(formatted).ToFormattedString()
        == "{rgb(255,0,0) Plain str}i{rgb(0,255,0) ng}");

    Issue("Methods return different `Text` objects each call.");
    TEST_ExpectTrue(P(plain) == P(plain));
    TEST_ExpectTrue(C(colored) == C(colored));
    TEST_ExpectTrue(F(formatted) == F(formatted));

    Issue("Different methods return same objects.");
    TEST_ExpectTrue(P(plain) != C(plain));
    TEST_ExpectTrue(C(colored) != F(colored));
    TEST_ExpectTrue(F(formatted) != P(formatted));

    Issue("Deallocating returned `Text`s does not cause methods to"
        @ "recreate them.");
    oldText = F(formatted);
    lifeVersion = oldText.GetLifeVersion();
    oldText.FreeSelf();
    P(plain).FreeSelf();
    C(colored).FreeSelf();
    TEST_ExpectTrue(    oldText != F(formatted)
                    ||  lifeVersion != F(formatted).GetLifeVersion());
}

protected static function Test_Constants()
{
    local Text  old1, old2;
    local int   old1Lifetime, old2Lifetime;
    Context("Testing `T()` for returning `Text` generated from"
        @ "`stringConstants`.");
    Issue("Expected `Text`s are not correctly generated.");
    TEST_ExpectTrue(T(0).ToString() == default.stringConstants[0]);
    TEST_ExpectTrue(T(1).ToString() == default.stringConstants[1]);
    TEST_ExpectTrue(T(2).ToString() == default.stringConstants[2]);
    TEST_ExpectTrue(T(3).ToString() == default.stringConstants[3]);
    TEST_ExpectTrue(T(4).ToString() == default.stringConstants[4]);

    Issue("`T()` does not return `none` for invalid indices.");
    TEST_ExpectNone(T(-1));
    TEST_ExpectNone(T(5));
    TEST_ExpectNone(T(MaxInt));

    Issue("`T()` does not return same `Text` objects between different calls.");
    TEST_ExpectTrue(T(0) == T(0));
    TEST_ExpectTrue(T(2).GetLifeVersion() == T(2).GetLifeVersion());

    Issue("Deallocating returned `Text` does not cause `T()` to create"
        @ "a new one.");
    old1 = T(0);
    old2 = T(1);
    old1Lifetime = old1.GetLifeVersion();
    old2Lifetime = old2.GetLifeVersion();
    old1.FreeSelf();
    old2.FreeSelf();
    TEST_ExpectTrue(old2 != T(1) || old2Lifetime != T(1).GetLifeVersion());
    TEST_ExpectTrue(old1 != T(0) || old1Lifetime != T(0).GetLifeVersion());
    TEST_ExpectTrue(T(0).IsAllocated());
    TEST_ExpectTrue(T(1).IsAllocated());
    TEST_ExpectTrue(T(0).ToString() == "boolean");
    TEST_ExpectTrue(T(1).ToString() == "byte");
}

defaultproperties
{
    caseGroup   = "Types"
    caseName    = "Base"
    stringConstants(0) = "boolean"
    stringConstants(1) = "byte"
    stringConstants(2) = "integer"
    stringConstants(3) = "float"
    stringConstants(4) = "string"
}