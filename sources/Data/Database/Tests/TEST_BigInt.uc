/**
 *  Set of tests for `BigInt` class.
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
class TEST_BigInt extends TestCase
    abstract;

protected static function TESTS()
{
    //  Here we use `ToString()` method to check `BigInt` creation,
    //  therefore also testing it
    Test_Creating();
    //  So here we nee to test `ToText()` methods separately
    Test_ToText();
    Context("Testing basic arithmetic operations on `BigInt`s.");
    Test_AddingValues();
}

protected static function Test_Creating()
{
    Context("Testing creation of `BigInt`s.");
    Issue("`ToString()` doesn't return value `BigInt` was initialized with" @
        "a positive `int`.");
    TEST_ExpectTrue(class'BigInt'.static.FromInt(13524).ToString() == "13524");
    TEST_ExpectTrue(
        class'BigInt'.static.FromInt(MaxInt).ToString() == "2147483647");

    Issue("`ToString()` doesn't return value `BigInt` was initialized with" @
        "a positive integer inside `string`.");
    TEST_ExpectTrue(
        class'BigInt'.static.FromDecimal_S("2147483647").ToString()
            == "2147483647");
    TEST_ExpectTrue(
        class'BigInt'.static.FromDecimal_S("4238756872643464981264982128742389")
            .ToString()  == "4238756872643464981264982128742389");

    Issue("`ToString()` doesn't return value `BigInt` was initialized with" @
        "a negative `int`.");
    TEST_ExpectTrue(class'BigInt'.static.FromInt(-666).ToString() == "-666");
    TEST_ExpectTrue(
        class'BigInt'.static.FromInt(-MaxInt).ToString() == "-2147483647");
    TEST_ExpectTrue(
        class'BigInt'.static.FromInt(-MaxInt - 1).ToString() == "-2147483648");

    Issue("`ToString()` doesn't return value `BigInt` was initialized with" @
        "a negative integer inside `string`.");
    TEST_ExpectTrue(
        class'BigInt'.static.FromDecimal_S("-2147483648").ToString()
            == "-2147483648");
    TEST_ExpectTrue(
        class'BigInt'.static.FromDecimal_S("-238473846327894632879097410348127")
            .ToString() == "-238473846327894632879097410348127");
}

protected static function Test_ToText()
{
    Context("Testing `ToText()` method of `BigInt`s.");
    Issue("`ToText()` doesn't return value `BigInt` was initialized with" @
        "a positive integer inside `string`.");
    TEST_ExpectTrue(class'BigInt'.static
        .FromDecimal_S("2147483647")
        .ToText()
        .ToString() == "2147483647");
    TEST_ExpectTrue(class'BigInt'.static
        .FromDecimal_S("65784236592763459236597823645978236592378659110571388")
        .ToText()
        .ToString() == "65784236592763459236597823645978236592378659110571388");

    Issue("`ToText()` doesn't return value `BigInt` was initialized with" @
        "a negative integer inside `string`.");
    TEST_ExpectTrue(class'BigInt'.static
        .FromDecimal_S("-2147483648")
        .ToText()
        .ToString() == "-2147483648");
    TEST_ExpectTrue(class'BigInt'.static
        .FromDecimal_S("-9827657892365923510176386357863078603212901078175829")
        .ToText()
        .ToString() == "-9827657892365923510176386357863078603212901078175829");
}

protected static function Test_AddingValues()
{
    SubTest_AddingSameSignValues();
    SubTest_AddingDifferentSignValues();
}

protected static function SubTest_AddingSameSignValues()
{
    local BigInt main, addition;

    Issue("Two positive `BigInt`s are incorrectly added.");
    main = class'BigInt'.static.FromDecimal_S("927641962323462271784269213864");
    addition = class'BigInt'.static.FromDecimal_S("16324234842947239847239239");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "927658286558305219024116453103");
    main = class'BigInt'.static.FromDecimal_S("16324234842947239847239239");
    addition = class'BigInt'.static
        .FromDecimal_S("927641962323462271784269213864");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "927658286558305219024116453103");
    main = class'BigInt'.static.FromDecimal_S("728965872936589276");
    addition = class'BigInt'.static.FromDecimal_S("728965872936589276");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "1457931745873178552");

    Issue("Two negative `BigInt`s are incorrectly added.");
    main = class'BigInt'.static.FromDecimal_S("-27641962323462271784269213864");
    addition = class'BigInt'.static.FromDecimal_S("-6324234842947239847239239");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "-27648286558305219024116453103");
    main = class'BigInt'.static.FromDecimal_S("-16324234842947239847239239");
    addition = class'BigInt'.static
        .FromDecimal_S("-927641962323462271784269213864");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "-927658286558305219024116453103");
    main = class'BigInt'.static.FromDecimal_S("-728965872936589276");
    addition = class'BigInt'.static.FromDecimal_S("-728965872936589276");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "-1457931745873178552");
}

protected static function SubTest_AddingDifferentSignValues()
{
    local BigInt main, addition;

    Issue("Negative `BigInt`s is incorrectly added to positive one.");
    main = class'BigInt'.static.FromDecimal_S("927641962323462271784269213864");
    addition = class'BigInt'.static.FromDecimal_S("-1632423484294239847239239");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "927640329899977977544421974625");
    main = class'BigInt'.static.FromDecimal_S("16324234842947239847239239");
    addition = class'BigInt'.static
        .FromDecimal_S("-927641962323462271784269213864");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "-927625638088619324544421974625");
    main = class'BigInt'.static.FromDecimal_S("728965872936589276");
    addition = class'BigInt'.static.FromDecimal_S("-728965872936589276");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "0");

    Issue("Positive `BigInt`s is incorrectly added to negative one.");
    main = class'BigInt'.static.FromDecimal_S("-27641962323462271784269213864");
    addition = class'BigInt'.static.FromDecimal_S("6324234842947239847239239");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "-27635638088619324544421974625");
    main = class'BigInt'.static.FromDecimal_S("-16324234842947239847239239");
    addition = class'BigInt'.static
        .FromDecimal_S("927641962323462271784269213864");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "927625638088619324544421974625");
    main = class'BigInt'.static.FromDecimal_S("-728965872936589276");
    addition = class'BigInt'.static.FromDecimal_S("728965872936589276");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "0");
}

defaultproperties
{
    caseGroup   = "Database"
    caseName    = "BigInt"
}