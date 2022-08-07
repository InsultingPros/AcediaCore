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
    Context("Testing creation of `BigInt`s.");
    Test_Creating();
    //  So here we nee to test `ToText()` methods separately
    Context("Testing `ToText()` method of `BigInt`s.");
    Test_ToText();
    Context("Testing `ToInt()` method of `BigInt`s.");
    Test_ToInt();
    Context("Testing basic arithmetic operations on `BigInt`s.");
    Test_AddingValues();
    Test_SubtractingValues();
}

protected static function Test_Creating()
{
    Issue("`ToString()` doesn't return value `BigInt` was initialized with" @
        "a positive `int`.");
    TEST_ExpectTrue(__().math.ToBigInt(13524).ToString() == "13524");
    TEST_ExpectTrue(
        __().math.ToBigInt(MaxInt).ToString() == "2147483647");

    Issue("`ToString()` doesn't return value `BigInt` was initialized with" @
        "a positive integer inside `string`.");
    TEST_ExpectTrue(
        __().math.MakeBigInt_S("2147483647").ToString()
            == "2147483647");
    TEST_ExpectTrue(
        __().math.MakeBigInt_S("4238756872643464981264982128742389")
            .ToString()  == "4238756872643464981264982128742389");

    Issue("`ToString()` doesn't return value `BigInt` was initialized with" @
        "a negative `int`.");
    TEST_ExpectTrue(__().math.ToBigInt(-666).ToString() == "-666");
    TEST_ExpectTrue(
        __().math.ToBigInt(-MaxInt).ToString() == "-2147483647");
    TEST_ExpectTrue(
        __().math.ToBigInt(-MaxInt - 1).ToString() == "-2147483648");

    Issue("`ToString()` doesn't return value `BigInt` was initialized with" @
        "a negative integer inside `string`.");
    TEST_ExpectTrue(
        __().math.MakeBigInt_S("-2147483648").ToString()
            == "-2147483648");
    TEST_ExpectTrue(
        __().math.MakeBigInt_S("-238473846327894632879097410348127")
            .ToString() == "-238473846327894632879097410348127");
}

protected static function Test_ToText()
{
    Issue("`ToText()` doesn't return value `BigInt` was initialized with" @
        "a positive integer inside `string`.");
    TEST_ExpectTrue(__().math
        .MakeBigInt_S("2147483647")
        .ToText()
        .ToString() == "2147483647");
    TEST_ExpectTrue(__().math
        .MakeBigInt_S("65784236592763459236597823645978236592378659110571388")
        .ToText()
        .ToString() == "65784236592763459236597823645978236592378659110571388");

    Issue("`ToText()` doesn't return value `BigInt` was initialized with" @
        "a negative integer inside `string`.");
    TEST_ExpectTrue(__().math
        .MakeBigInt_S("-2147483648")
        .ToText()
        .ToString() == "-2147483648");
    TEST_ExpectTrue(__().math
        .MakeBigInt_S("-9827657892365923510176386357863078603212901078175829")
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
    main = __().math.MakeBigInt_S("927641962323462271784269213864");
    addition = __().math.MakeBigInt_S("16324234842947239847239239");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "927658286558305219024116453103");
    main = __().math.MakeBigInt_S("16324234842947239847239239");
    addition = __().math.MakeBigInt_S("927641962323462271784269213864");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "927658286558305219024116453103");
    main = __().math.MakeBigInt_S("728965872936589276");
    addition = __().math.MakeBigInt_S("728965872936589276");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "1457931745873178552");

    Issue("Two negative `BigInt`s are incorrectly added.");
    main = __().math.MakeBigInt_S("-27641962323462271784269213864");
    addition = __().math.MakeBigInt_S("-6324234842947239847239239");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "-27648286558305219024116453103");
    main = __().math.MakeBigInt_S("-16324234842947239847239239");
    addition = __().math.MakeBigInt_S("-927641962323462271784269213864");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "-927658286558305219024116453103");
    main = __().math.MakeBigInt_S("-728965872936589276");
    addition = __().math.MakeBigInt_S("-728965872936589276");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "-1457931745873178552");
}

protected static function SubTest_AddingDifferentSignValues()
{
    local BigInt main, addition;

    Issue("Negative `BigInt`s is incorrectly added to positive one.");
    main = __().math.MakeBigInt_S("927641962323462271784269213864");
    addition = __().math.MakeBigInt_S("-1632423484294239847239239");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "927640329899977977544421974625");
    main = __().math.MakeBigInt_S("16324234842947239847239239");
    addition = __().math.MakeBigInt_S("-927641962323462271784269213864");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "-927625638088619324544421974625");
    main = __().math.MakeBigInt_S("728965872936589276");
    addition = __().math.MakeBigInt_S("-728965872936589276");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "0");

    Issue("Positive `BigInt`s is incorrectly added to negative one.");
    main = __().math.MakeBigInt_S("-27641962323462271784269213864");
    addition = __().math.MakeBigInt_S("6324234842947239847239239");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "-27635638088619324544421974625");
    main = __().math.MakeBigInt_S("-16324234842947239847239239");
    addition = __().math.MakeBigInt_S("927641962323462271784269213864");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "927625638088619324544421974625");
    main = __().math.MakeBigInt_S("-728965872936589276");
    addition = __().math.MakeBigInt_S("728965872936589276");
    main.Add(addition);
    TEST_ExpectTrue(main.ToString() == "0");
}

protected static function Test_SubtractingValues()
{
    SubTest_SubtractingSameSignValues();
    SubTest_SubtractingDifferentSignValues();
}

protected static function SubTest_SubtractingSameSignValues()
{
    local BigInt main, sub;

    Issue("Two positive `BigInt`s are incorrectly subtracted.");
    main = __().math.MakeBigInt_S("213721893712893789123798123912");
    sub = __().math.MakeBigInt_S("91283172381723712893718931");
    main.Subtract(sub);
    TEST_ExpectTrue(main.ToString() == "213630610540512065410904404981");
    main = __().math.MakeBigInt_S("328478923749827489237948");
    sub = __().math.MakeBigInt_S("652578623458293527957923579235792529");
    main.Subtract(sub);
    TEST_ExpectTrue(main.ToString() == "-652578623457965049034173751746554581");
    main = __().math.MakeBigInt_S("728965872936589276");
    sub = __().math.MakeBigInt_S("728965872936589276");
    main.Subtract(sub);
    TEST_ExpectTrue(main.ToString() == "0");

    Issue("Two negative `BigInt`s are incorrectly subtracted.");
    main = __().math.MakeBigInt_S("-47283948923742901278492345984");
    sub = __().math.MakeBigInt_S("-234782394728937402983200234");
    main.Subtract(sub);
    TEST_ExpectTrue(main.ToString() == "-47049166529013963875509145750");
    main = __().math.MakeBigInt_S("-8920758902379");
    sub = __().math.MakeBigInt_S("-2975234896823956283952");
    main.Subtract(sub);
    TEST_ExpectTrue(main.ToString() == "2975234887903197381573");
    main = __().math.MakeBigInt_S("-728965872936589276");
    sub = __().math.MakeBigInt_S("-728965872936589276");
    main.Subtract(sub);
    TEST_ExpectTrue(main.ToString() == "0");
}

protected static function SubTest_SubtractingDifferentSignValues()
{
    local BigInt main, sub;

    Issue("Negative `BigInt`s is incorrectly subtracted from positive one.");
    main = __().math.MakeBigInt_S("927641962323462271784269213864");
    sub = __().math.MakeBigInt_S("-1632423484294239847239239");
    main.Subtract(sub);
    TEST_ExpectTrue(main.ToString() == "927643594746946566024116453103");
    main = __().math.MakeBigInt_S("16324234842947239847239239");
    sub = __().math.MakeBigInt_S("-927641962323462271784269213864");
    main.Subtract(sub);
    TEST_ExpectTrue(main.ToString() == "927658286558305219024116453103");
    main = __().math.MakeBigInt_S("728965872936589276");
    sub = __().math.MakeBigInt_S("-728965872936589276");
    main.Subtract(sub);
    TEST_ExpectTrue(main.ToString() == "1457931745873178552");

    Issue("Positive `BigInt`s is incorrectly subtracted from negative one.");
    main = __().math.MakeBigInt_S("-27641962323462271784269213864");
    sub = __().math.MakeBigInt_S("6324234842947239847239239");
    main.Subtract(sub);
    TEST_ExpectTrue(main.ToString() == "-27648286558305219024116453103");
    main = __().math.MakeBigInt_S("-16324234842947239847239239");
    sub = __().math.MakeBigInt_S("927641962323462271784269213864");
    main.Subtract(sub);
    TEST_ExpectTrue(main.ToString() == "-927658286558305219024116453103");
    main = __().math.MakeBigInt_S("-728965872936589276");
    sub = __().math.MakeBigInt_S("728965872936589276");
    main.Subtract(sub);
    TEST_ExpectTrue(main.ToString() == "-1457931745873178552");
}

protected static function Test_ToInt()
{
    Issue("Testing conversion for non-overflowing values.");
    TEST_ExpectTrue(__().math.MakeBigInt_S("0").ToInt() == 0);
    TEST_ExpectTrue(__().math.MakeBigInt_S("-0").ToInt() == 0);
    TEST_ExpectTrue(__().math.MakeBigInt_S("13524").ToInt() == 13524);
    TEST_ExpectTrue(__().math.MakeBigInt_S("-666").ToInt() == -666);
    TEST_ExpectTrue(__().math.MakeBigInt_S("2147483647").ToInt() == 2147483647);
    TEST_ExpectTrue(__().math.MakeBigInt_S("2147483646").ToInt() == 2147483646);
    TEST_ExpectTrue(
        __().math.MakeBigInt_S("-2147483648").ToInt() == -2147483648);
    TEST_ExpectTrue(
        __().math.MakeBigInt_S("-2147483647").ToInt() == -2147483647);

    Issue("Testing conversion for overflowing values.");
    TEST_ExpectTrue(__().math.MakeBigInt_S("2147483648").ToInt() == 2147483647);
    TEST_ExpectTrue(
        __().math.MakeBigInt_S("8342748293074932473246").ToInt() == 2147483647);
    TEST_ExpectTrue(
        __().math.MakeBigInt_S("-2147483649").ToInt() == -2147483648);
    TEST_ExpectTrue(
        __().math.MakeBigInt_S("-32545657348437563873").ToInt() == -2147483648);
}

defaultproperties
{
    caseGroup   = "Math"
    caseName    = "BigInt"
}