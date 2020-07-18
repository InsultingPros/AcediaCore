/**
 *  Set of tests for `TextAPI` system.
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
class TEST_TextAPI extends TestCase
    abstract;

var const string russianTest, russianTestLower, russianTestUpper;
var const string languageMixTest;

protected static function TESTS()
{
    Test_GetCharacter();
    Test_CaseChecks();
    Test_GroupChecks();
    Test_EqualityChecks();
    Test_StringEqualityChecks();
    Test_RawStringConversions();
    Test_InterStringConversions();
    Test_CaseConversions();
    Test_CharacterToInt();
    Test_IsQuotationMark();
}

protected static function Test_GetCharacter()
{
    Context("Testing `GetCharacter()` function.");
    SubTest_GetCharacterCodePointTests();
    SubTest_GetCharacterFromColoredOrFormattedTests();

    Issue("Does not return character with correct coloring from a"
        @ "plain string.");
    TEST_ExpectTrue(_().text.GetCharacter("Q").colorType == STRCOLOR_Default);
    TEST_ExpectTrue(_().text.GetCharacter("8").colorType == STRCOLOR_Default);

    SubTest_GetCharacterColorTestsColored();
    SubTest_GetCharacterColorTestsFormatted();
}

protected static function SubTest_GetCharacterCodePointTests()
{
    Issue("Doesn't return ASCII characters correctly.");
    TEST_ExpectTrue(_().text.GetCharacter("Q").codePoint == 0x0051);
    TEST_ExpectTrue(_().text.GetCharacter("m").codePoint == 0x006d);
    TEST_ExpectTrue(_().text.GetCharacter("4").codePoint == 0x0034);
    TEST_ExpectTrue(_().text.GetCharacter("@").codePoint == 0x0040);
    TEST_ExpectTrue(_().text.GetCharacter("~").codePoint == 0x007e);
    TEST_ExpectTrue(_().text.GetCharacter("+").codePoint == 0x002b);

    Issue("Doesn't return non-ASCII characters correctly.");
    TEST_ExpectTrue(_().text.GetCharacter("Ё").codePoint == 0x0401);
    TEST_ExpectTrue(_().text.GetCharacter("ъ").codePoint == 0x044a);
    TEST_ExpectTrue(_().text.GetCharacter("の").codePoint == 0x306e);
    TEST_ExpectTrue(_().text.GetCharacter("ザ").codePoint == 0x30b6);

    Issue("Returns wrong character when non-zero index is specified.");
    TEST_ExpectTrue(_().text.GetCharacter("Word~bar", 4).codePoint == 0x007e);
    TEST_ExpectTrue(_().text.GetCharacter("Teh+Meh", 3).codePoint == 0x002b);
    TEST_ExpectTrue(
        _().text.GetCharacter("Why must we suffer", 17).codePoint == 0x0072);
    TEST_ExpectTrue(
        _().text.GetCharacter("Why must we suffer", 0).codePoint == 0x0057);

    Issue(  "Doesn't return character with code point `-1` for out-of-bounds" @
            "indices.");
    TEST_ExpectTrue(_().text.GetCharacter("S", 2).codePoint == -1);
    TEST_ExpectTrue(
        _().text.GetCharacter("Just some random text", -1).codePoint == -1);
    TEST_ExpectTrue(_().text.GetCharacter("d", 1).codePoint == -1);
    TEST_ExpectTrue(_().text.GetCharacter("", 0).codePoint == -1);
}

protected static function SubTest_GetCharacterFromColoredOrFormattedTests()
{
    local string coloredString, formattedString;
    coloredString = "pre" $ _().color.GetColorTagRGB(137, 86, 19) $ "later";
    Issue("Does not return correct characters from a colored strings.");
    TEST_ExpectTrue(_().text.GetCharacter(coloredString,, STRING_Colored)
        .codePoint == 0x70);
    TEST_ExpectTrue(_().text.GetCharacter(coloredString, 3, STRING_Colored)
        .codePoint == 0x6c);
    
    formattedString = "pre{rgb(137,86,19) later{$blue plus}}";
    Issue("Does not return correct characters from a formatted strings.");
    TEST_ExpectTrue(_().text.GetCharacter(formattedString,, STRING_Formatted)
        .codePoint == 0x70);
    TEST_ExpectTrue(_().text.GetCharacter(formattedString, 3, STRING_Formatted)
        .codePoint == 0x6c);
    TEST_ExpectTrue(_().text.GetCharacter(formattedString, 8, STRING_Formatted)
        .codePoint == 0x70);
}

protected static function SubTest_GetCharacterColorTestsColored()
{
    local Color     testColor;
    local string    coloredString;
    testColor = _().color.RGB(137, 86, 19);
    coloredString = "pre" $ _().color.GetColorTag(testColor) $ "later";
    Issue("Does not return correct coloring from a colored string.");
    TEST_ExpectTrue(_().text.GetCharacter(coloredString,, STRING_Colored)
        .colorType== STRCOLOR_Default);
    TEST_ExpectTrue(_().text.GetCharacter(coloredString, 3, STRING_Colored)
        .colorType == STRCOLOR_Struct);
    TEST_ExpectTrue(
        _().color.AreEqual(
            _().text.GetCharacter(coloredString, 3, STRING_Colored).color,
            testColor));
}

protected static function SubTest_GetCharacterColorTestsFormatted()
{
    local Color     testColor;
    local string    formattedString;
    testColor = _().color.RGB(137, 86, 19);
    formattedString = "pre{rgb(137,86,19) later{$blue plus}}";
    Issue("Does not return correct coloring from a formatted string.");
    TEST_ExpectTrue(_().text.GetCharacter(formattedString,, STRING_Formatted)
        .colorType == STRCOLOR_Default);
    TEST_ExpectTrue(_().text.GetCharacter(formattedString, 3, STRING_Formatted)
        .colorType == STRCOLOR_Struct);
    TEST_ExpectTrue(
        _().color.AreEqual(
            _().text.GetCharacter(formattedString, 3, STRING_Formatted).color,
            testColor));
    TEST_ExpectTrue(_().text.GetCharacter(formattedString, 8, STRING_Formatted)
        .colorType == STRCOLOR_Alias);
    TEST_ExpectTrue(
        _().color.AreEqual(
            _().text.GetCharacter(formattedString, 8, STRING_Formatted).color,
            _().color.blue));
}

protected static function Test_CaseChecks()
{
    Context("Testing case-testing functions.");
    Issue("Case of characters is incorrectly determined.");
    TEST_ExpectTrue(_().text.IsLower( _().text.GetCharacter("q") ));
    TEST_ExpectTrue(_().text.IsUpper( _().text.GetCharacter("D") ));
    TEST_ExpectTrue(_().text.IsUpper( _().text.GetCharacter("Е") ));
    TEST_ExpectTrue(_().text.IsLower( _().text.GetCharacter("л") ));

    Issue("Non-letters reported as having either upper or lower case.");
    TEST_ExpectFalse(_().text.IsLower( _().text.GetCharacter("$") ));
    TEST_ExpectFalse(_().text.IsUpper( _().text.GetCharacter("$") ));
    TEST_ExpectFalse(_().text.IsLower( _().text.GetCharacter("&") ));
    TEST_ExpectFalse(_().text.IsUpper( _().text.GetCharacter("&") ));
    TEST_ExpectFalse(_().text.IsLower( _().text.GetCharacter("(") ));
    TEST_ExpectFalse(_().text.IsUpper( _().text.GetCharacter("(") ));

    Issue("Case checks for `string`s fail when they should not.");
    TEST_ExpectTrue(_().text.IsUpperString("WHY ARE WE SHOUTING?!1"));
    TEST_ExpectTrue(_().text.IsLowerString("keep your voice down"));
    TEST_ExpectTrue(_().text.IsLowerString(default.russianTestLower));

    Issue("`string` case checks succeed when they should not.");
    TEST_ExpectFalse(_().text.IsLowerString("This is a normal sentence."));
    TEST_ExpectFalse(_().text.IsUpperString("This is a normal sentence."));
    TEST_ExpectFalse(_().text.IsLowerString("This one isn't so normal."));
    TEST_ExpectFalse(_().text.IsUpperString("This one isn't so normal."));
    TEST_ExpectFalse(_().text.IsLowerString(default.russianTest));
    TEST_ExpectFalse(_().text.IsLowerString(default.languageMixTest));

    Issue("Empty `string` is not considered lower case.");
    TEST_ExpectTrue(_().text.IsLowerString(""));

    Issue("Empty `string` is not considered upper case.");
    TEST_ExpectTrue(_().text.IsUpperString(""));
}

protected static function Test_GroupChecks()
{
    SubTest_CommonGroupChecks();
    SubTest_WhitespaceChecks();
}

protected static function SubTest_CommonGroupChecks()
{
    Context("Testing `IsDigit()` function.");
    Issue("`IsDigit()` check does not recognize all of the digits.");
    TEST_ExpectTrue(_().text.IsDigit( _().text.GetCharacter("0") ));
    TEST_ExpectTrue(_().text.IsDigit( _().text.GetCharacter("1") ));
    TEST_ExpectTrue(_().text.IsDigit( _().text.GetCharacter("2") ));
    TEST_ExpectTrue(_().text.IsDigit( _().text.GetCharacter("3") ));
    TEST_ExpectTrue(_().text.IsDigit( _().text.GetCharacter("4") ));
    TEST_ExpectTrue(_().text.IsDigit( _().text.GetCharacter("5") ));
    TEST_ExpectTrue(_().text.IsDigit( _().text.GetCharacter("6") ));
    TEST_ExpectTrue(_().text.IsDigit( _().text.GetCharacter("7") ));
    TEST_ExpectTrue(_().text.IsDigit( _().text.GetCharacter("8") ));
    TEST_ExpectTrue(_().text.IsDigit( _().text.GetCharacter("9") ));

    Issue("`IsDigit()` accepts non-digit characters as digits.");
    TEST_ExpectFalse(_().text.IsDigit( _().text.GetCharacter("%") ));
    TEST_ExpectFalse(_().text.IsDigit( _().text.GetCharacter("Ж") ));

    Issue("`IsDigit()` accepts invalid characters as digits.");
    TEST_ExpectFalse(_().text.IsDigit( _().text.GetCharacter("") ));
}

protected static function SubTest_WhitespaceChecks()
{
    local Text.Character character;
    Context("Testing functions for identifying whitespace characters.");
    Issue(  "Unicode code points, classically considered whitespaces, are not" @
            "recognized as whitespaces.");
    character.codePoint = 0x0020;
    TEST_ExpectTrue(_().text.IsWhitespace(character));
    character.codePoint = 0x0009;
    TEST_ExpectTrue(_().text.IsWhitespace(character));
    character.codePoint = 0x000A;
    TEST_ExpectTrue(_().text.IsWhitespace(character));
    character.codePoint = 0x000B;
    TEST_ExpectTrue(_().text.IsWhitespace(character));
    character.codePoint = 0x000C;
    TEST_ExpectTrue(_().text.IsWhitespace(character));
    character.codePoint = 0x000D;
    TEST_ExpectTrue(_().text.IsWhitespace(character));

    Issue(  "Unicode code points that belong to 'Separator, Space' Category" @
            "are not recognized as whitespaces.");
    character.codePoint = 0x00A0;
    TEST_ExpectTrue(_().text.IsWhitespace(character));
    character.codePoint = 0x2001;
    TEST_ExpectTrue(_().text.IsWhitespace(character));
    character.codePoint = 0x2007;
    TEST_ExpectTrue(_().text.IsWhitespace(character));
    character.codePoint = 0x3000;
    TEST_ExpectTrue(_().text.IsWhitespace(character));

    Issue(  "Some Unicode code points that aren't whitespaces by any metric" @
            "are recognized as such.");
    character.codePoint = 0x0045;
    TEST_ExpectFalse(_().text.IsWhitespace(character) );
}

protected static function Test_EqualityChecks()
{
    local Text.Character character;
    Context("Testing a check for character equality.");
    Issue("Identical characters are considered different.");
    character = _().text.GetCharacter("b");
    TEST_ExpectTrue(_().text.AreEqual(character, character));
    TEST_ExpectTrue(_().text.AreEqual(character, character, true));

    Issue("Different characters are considered equal (case-sensitive).");
    TEST_ExpectFalse(_().text.AreEqual( _().text.GetCharacter("c"),
                                        _().text.GetCharacter("$")));
    TEST_ExpectFalse(_().text.AreEqual( _().text.GetCharacter("f"),
                                        _().text.GetCharacter("F")));
    TEST_ExpectFalse(_().text.AreEqual( _().text.GetCharacter("v"),
                                        _().text.GetCharacter("X")));
    TEST_ExpectFalse(_().text.AreEqual( _().text.GetCharacter("Ж"),
                                        _().text.GetCharacter("м")));

    Issue("Case-insensitive comparison doesn't properly work.");
    TEST_ExpectTrue(_().text.AreEqual(  _().text.GetCharacter("d"),
                                        _().text.GetCharacter("D"), true));
    TEST_ExpectTrue(_().text.AreEqual(  _().text.GetCharacter("Ё"),
                                        _().text.GetCharacter("ё"), true));
}

protected static function Test_StringEqualityChecks()
{
    Context("Testing a check for `string`s equality.");
    Issue("Equal `string`s are rejected.");
    TEST_ExpectTrue(_().text.AreEqualStrings(   "Just good string",
                                                "Just good string"));
    TEST_ExpectTrue(_().text.AreEqualStrings(   default.languageMixTest,
                                                default.languageMixTest));

    Issue(  "`string`s that differ (but by case only) are accepted by" @
            "case-sensitive check.");
    TEST_ExpectFalse(_().text.AreEqualStrings(  "Just good string",
                                                "jUsT GoOd sTrInG"));

    Issue(  "`string`s that differ by case only are rejected by" @
            "case-insensitive check.");
    TEST_ExpectTrue(_().text.AreEqualStrings(   "Just good string",
                                                "jUsT GoOd sTrInG", true));
    TEST_ExpectTrue(_().text.AreEqualStrings(   default.russianTest,
                                                default.russianTestLower,
                                                true));
}

protected static function bool CompareRaw(
    array<Text.Character> original,
    array<Text.Character> fromPlain)
{
    local int i;
    if (original.length != fromPlain.length) return false;
    for (i = 0; i < original.length; i += 1)
    {
        //  Compare characters
        if (original[i].codePoint != fromPlain[i].codePoint) {
            return false;
        }
    }
    return true;
}

protected static function bool CompareRawWithColor(
    array<Text.Character> original,
    array<Text.Character> fromFormatted)
{
    local int i;
    if (original.length != fromFormatted.length) return false;
    for (i = 0; i < original.length; i += 1)
    {
        //  Compare characters
        if (original[i].codePoint != fromFormatted[i].codePoint) {
            return false;
        }
        //  Compare color type
        if (original[i].colorType != fromFormatted[i].colorType) {
            return false;
        }
        //  Only compare color for colored characters
        //  STRCOLOR_Struct && STRCOLOR_Alias
        if (original[i].colorType == STRCOLOR_Default) continue;
        if (!_().color.AreEqualWithAlpha(   original[i].color,
                                            fromFormatted[i].color, true)) {
            return false;
        }
        //  Only compare aliases for alias color characters
        //  STRCOLOR_Alias
        if (original[i].colorType != STRCOLOR_Alias) continue;
        if (!(original[i].colorAlias ~= fromFormatted[i].colorAlias)) {
            return false;
        }
    }
    return true;
}

//  Returns array of Unicode code points decoding "Hello, World!"
protected static function array<Text.Character> PrepareTestArray()
{
    local Text.Character        nextCharacter;
    local array<Text.Character> preparedArray;
    nextCharacter.codePoint = 0x0048;
    nextCharacter.colorType = STRCOLOR_Default;
    preparedArray[0] = nextCharacter; // H
    nextCharacter.codePoint = 0x0065;
    nextCharacter.colorType = STRCOLOR_Alias;
    nextCharacter.color = _().color.red;
    nextCharacter.colorAlias = "red";
    preparedArray[1] = nextCharacter; // e
    nextCharacter.codePoint = 0x006c;
    nextCharacter.colorType = STRCOLOR_Struct;
    nextCharacter.color = _().color.RGBA(0,255,0,143);
    preparedArray[2] = nextCharacter; // l
    nextCharacter.codePoint = 0x006c;
    nextCharacter.color = _().color.RGB(243,195,0);
    preparedArray[3] = nextCharacter; // l
    nextCharacter.codePoint = 0x006f;
    preparedArray[4] = nextCharacter; // o
    nextCharacter.codePoint = 0x002c;
    nextCharacter.color = _().color.RGBA(0,255,0,143);
    preparedArray[5] = nextCharacter; // ,
    nextCharacter.codePoint = 0x0020;
    preparedArray[6] = nextCharacter; // <whitespace>
    nextCharacter.codePoint = 0x0077;
    nextCharacter.colorType = STRCOLOR_Alias;
    nextCharacter.color = _().color.red;
    preparedArray[7] = nextCharacter; // w
    nextCharacter.codePoint = 0x006f;
    preparedArray[8] = nextCharacter; // o
    nextCharacter.codePoint = 0x0072;
    preparedArray[9] = nextCharacter; // r
    nextCharacter.codePoint = 0x006c;
    nextCharacter.colorType = STRCOLOR_Default;
    preparedArray[10] = nextCharacter; // l
    nextCharacter.codePoint = 0x0064;
    nextCharacter.colorType = STRCOLOR_Struct;
    nextCharacter.color = _().color.RGB(0,0,255);
    preparedArray[11] = nextCharacter; // d
    nextCharacter.codePoint = 0x0021;
    preparedArray[12] = nextCharacter; // !
    return preparedArray;
}

protected static function array<Text.Character> PrepareTestArrayForColored()
{
    local Text.Character        nextCharacter;
    local array<Text.Character> preparedArray;
    nextCharacter.codePoint = 0x0048;
    nextCharacter.colorType = STRCOLOR_Default;
    preparedArray[0] = nextCharacter; // H
    nextCharacter.codePoint = 0x0065;
    nextCharacter.colorType = STRCOLOR_Struct;
    nextCharacter.color = _().color.red;
    preparedArray[1] = nextCharacter; // e
    nextCharacter.codePoint = 0x006c;
    nextCharacter.color = _().color.RGB(1,255,1);
    preparedArray[2] = nextCharacter; // l
    nextCharacter.codePoint = 0x006c;
    nextCharacter.color = _().color.RGB(243,195,1);
    preparedArray[3] = nextCharacter; // l
    nextCharacter.codePoint = 0x006f;
    preparedArray[4] = nextCharacter; // o
    nextCharacter.codePoint = 0x002c;
    nextCharacter.color = _().color.RGB(1,255,1);
    preparedArray[5] = nextCharacter; // ,
    nextCharacter.codePoint = 0x0020;
    preparedArray[6] = nextCharacter; // <whitespace>
    nextCharacter.codePoint = 0x0077;
    nextCharacter.color = _().color.red;
    preparedArray[7] = nextCharacter; // w
    nextCharacter.codePoint = 0x006f;
    preparedArray[8] = nextCharacter; // o
    nextCharacter.codePoint = 0x0072;
    preparedArray[9] = nextCharacter; // r
    nextCharacter.codePoint = 0x006c;
    nextCharacter.color = _().color.white;
    preparedArray[10] = nextCharacter; // l
    nextCharacter.codePoint = 0x0064;
    nextCharacter.color = _().color.RGB(1,1,255);
    preparedArray[11] = nextCharacter; // d
    nextCharacter.codePoint = 0x0021;
    preparedArray[12] = nextCharacter; // !
    return preparedArray;
}

//  Creates a colored "Hello, world!" string in several different ways.
//  For formatted `string`s there's 3 types they can be generated in:
//      ~ Initial, how we could define it (`formattedType == 0`);
//      ~ How it could be output if generated from a raw data,
//          with alpha channel and aliases preserved (`formattedType == 1`);
//      ~ How it could be output if generated from a colored string, with only
//          rgb channels preserved (`formattedType == 2`) and all default
//          color parts, except initial, filled with chosen for the tests
//          default color (white).
//      ~ How it could be output if generated from a colored string, with only
//          rgb channels preserved (`formattedType == 3`) and all default
//          color parts, including initial, filled with chosen for the tests
//          default color (white).
protected static function string PrepareTestString(
    Text.StringType stringType,
    optional int    formattedType)
{
    if (stringType == STRING_Plain) {
        return "Hello, world!";
    }
    else if (stringType == STRING_Colored) {
        return "H" $ _().color.GetColorTagRGB(255, 0, 0) $ "e"
            $ _().color.GetColorTagRGB(0, 255, 0) $ "l"
            $ _().color.GetColorTagRGB(243, 195, 0) $ "lo"
            $ _().color.GetColorTagRGB(0, 255, 0) $ ", "
            $ _().color.GetColorTagRGB(255, 0, 0) $ "wor"
            $ _().color.GetColorTagRGB(255, 255, 255) $ "l"
            $ _().color.GetColorTagRGB(0, 0, 255) $ "d!";
    }
    else if (stringType == STRING_Formatted && formattedType == 0) {
        return "H{$red e{rgba(0,255,0,143) l{rgb(r=243,g=195,b=0) lo}, }"
            $ "wor}l{rgb(0,0,255) d!}";
    }
    else if (stringType == STRING_Formatted && formattedType == 1) {
        return "H{$red e}{rgba(0,255,0,143) l}{rgb(243,195,0) lo}"
            $ "{rgba(0,255,0,143) , }{$red wor}l{rgb(0,0,255) d!}";
    }
    else if (stringType == STRING_Formatted && formattedType == 2) {
        return "H{rgb(255,1,1) e}{rgb(1,255,1) l}{rgb(243,195,1) lo}{"
            $ "rgb(1,255,1) , }{rgb(255,1,1) wor}{rgb(255,255,255) l}"
            $ "{rgb(1,1,255) d!}";
    }
    else if (stringType == STRING_Formatted && formattedType == 3) {
        return "{rgb(255,255,255) H}{rgb(255,1,1) e}{rgb(1,255,1) l}"
            $ "{rgb(243,195,1) lo}{rgb(1,255,1) , }{rgb(255,1,1) wor}"
            $ "{rgb(255,255,255) l}{rgb(1,1,255) d!}";
    }
    return "";
}

protected static function Test_RawStringConversions()
{
    Context("Testing character raw data <-> `string` conversion.");
    SubTest_RawStringConversionsPlain();
    SubTest_RawStringConversionsColored();
    SubTest_RawStringConversionsFormatted();
}

protected static function SubTest_RawStringConversionsPlain()
{
    local string                plainString;
    local array<Text.Character> rawData;
    Issue("Empty raw data is not converted into empty plain string.");
    TEST_ExpectTrue(_().text.RawToString(rawData, STRING_Plain) == "");

    Issue("Empty plain string is not converted into empty raw data.");
    TEST_ExpectTrue(_().text.StringToRaw("", STRING_Plain).length == 0);

    rawData     = PrepareTestArray();
    plainString = PrepareTestString(STRING_Plain);
    Issue("Raw data is incorrectly converted into plain string.");
    TEST_ExpectTrue(_().text.RawToString(rawData, STRING_Plain) == plainString);

    Issue("Plain string is incorrectly converted into raw data.");
    TEST_ExpectTrue(
        CompareRaw(rawData, _().text.StringToRaw(plainString, STRING_Plain)));
}

protected static function SubTest_RawStringConversionsColored()
{
    local string                coloredString, coloredStringOutput;
    local array<Text.Character> rawData;
    Issue("Empty raw data is not converted into empty colored string.");
    TEST_ExpectTrue(_().text.RawToString(rawData, STRING_Colored) == "");

    Issue("Empty colored string is not converted into empty raw data.");
    TEST_ExpectTrue(_().text.StringToRaw("", STRING_Colored).length == 0);

    rawData             = PrepareTestArrayForColored();
    coloredString       = PrepareTestString(STRING_Colored);
    coloredStringOutput =
        _().color.GetColorTag(_().color.white) $ coloredString;
    Issue("Raw data is incorrectly converted into colored string.");
    TEST_ExpectTrue(
            _().text.RawToString(rawData, STRING_Colored, _().color.white)
        ==  coloredStringOutput);

    Issue("Colored string is incorrectly converted into raw data.");
    TEST_ExpectTrue(
        CompareRawWithColor(rawData,
                        _().text.StringToRaw(coloredString, STRING_Colored)));
}

protected static function SubTest_RawStringConversionsFormatted()
{
    local string                formattedString, formattedStringOutput;
    local array<Text.Character> rawData;
    Issue("Empty raw data is not converted into empty formatted string.");
    TEST_ExpectTrue(_().text.RawToString(rawData, STRING_Formatted) == "");

    Issue("Empty formatted string is not converted into empty raw data.");
    TEST_ExpectTrue(_().text.StringToRaw("", STRING_Formatted).length == 0);

    rawData                 = PrepareTestArray();
    formattedString         = PrepareTestString(STRING_Formatted, 0);
    formattedStringOutput   = PrepareTestString(STRING_Formatted, 1);
    Issue("Raw data is incorrectly converted into formatted string.");
    TEST_ExpectTrue(
            _().text.RawToString(rawData, STRING_Formatted)
        ==  formattedStringOutput);

    Issue("Formatted string is incorrectly converted into raw data.");
    TEST_ExpectTrue(
        CompareRawWithColor(rawData,
            _().text.StringToRaw(formattedString, STRING_Formatted)));
}

protected static function Test_InterStringConversions()
{
    Context("Testing conversions between different `string` types.");
    SubTest_InterStringConversionsWithPlain();
    SubTest_InterStringConversionsColoredAndFormatted();
}

protected static function SubTest_InterStringConversionsWithPlain()
{
    local string plainHelloWorld;
    local string coloredHelloWorld;
    local string formattedHelloWorld0;
    local string formattedHelloWorld1;
    local string formattedHelloWorld2;
    local string formattedHelloWorld3;
    plainHelloWorld         = PrepareTestString(STRING_Plain);
    coloredHelloWorld       = PrepareTestString(STRING_Colored);
    formattedHelloWorld0    = PrepareTestString(STRING_Formatted, 0);
    formattedHelloWorld1    = PrepareTestString(STRING_Formatted, 1);
    formattedHelloWorld2    = PrepareTestString(STRING_Formatted, 2);
    formattedHelloWorld3    = PrepareTestString(STRING_Formatted, 3);
    Issue("Colored strings aren't correctly converted into plain strings.");
    TEST_ExpectTrue(plainHelloWorld == _().text.ConvertString(
        coloredHelloWorld, STRING_Colored, STRING_Plain));

    Issue("Formatted strings aren't correctly converted into plain strings.");
    TEST_ExpectTrue(plainHelloWorld == _().text.ConvertString(
        formattedHelloWorld0, STRING_Formatted, STRING_Plain));
    TEST_ExpectTrue(plainHelloWorld == _().text.ConvertString(
        formattedHelloWorld1, STRING_Formatted, STRING_Plain));
    TEST_ExpectTrue(plainHelloWorld == _().text.ConvertString(
        formattedHelloWorld2, STRING_Formatted, STRING_Plain));
    TEST_ExpectTrue(plainHelloWorld == _().text.ConvertString(
        formattedHelloWorld3, STRING_Formatted, STRING_Plain));
    TEST_ExpectTrue("This is zed" == _().text.ConvertString(
        "This {#ef320a is} zed", STRING_Formatted, STRING_Plain));
    
    Issue("Plain strings change after being converted into a formatted type.");
    TEST_ExpectTrue(plainHelloWorld == _().text.ConvertString(
        plainHelloWorld, STRING_Plain, STRING_Formatted));
}

protected static function SubTest_InterStringConversionsColoredAndFormatted()
{
    local string coloredHelloWorld;
    local string coloredHelloWorldOut;
    local string formattedHelloWorld0;
    local string formattedHelloWorld1;
    local string formattedHelloWorldOut0;
    local string formattedHelloWorldOut1;
    coloredHelloWorld       = PrepareTestString(STRING_Colored);
    coloredHelloWorldOut    =
        _().color.GetColorTag(_().color.white) $ coloredHelloWorld;
    formattedHelloWorld0    = PrepareTestString(STRING_Formatted, 0);
    formattedHelloWorld1    = PrepareTestString(STRING_Formatted, 1);
    formattedHelloWorldOut0 = PrepareTestString(STRING_Formatted, 2);
    formattedHelloWorldOut1 = PrepareTestString(STRING_Formatted, 3);
    Issue("Colored strings aren't correctly converted into formatted strings.");
    TEST_ExpectTrue(formattedHelloWorldOut0 == _().text.ConvertString(
        coloredHelloWorld, STRING_Colored, STRING_Formatted));
    TEST_ExpectTrue(formattedHelloWorldOut1 == _().text.ConvertString(
        coloredHelloWorldOut, STRING_Colored, STRING_Formatted));

    Issue("Formatted strings aren't correctly converted into colored strings.");
    TEST_ExpectTrue(coloredHelloWorldOut == _().text.ConvertString(
        formattedHelloWorld0,   STRING_Formatted, STRING_Colored,
                                _().color.white));
    TEST_ExpectTrue(coloredHelloWorldOut == _().text.ConvertString(
        formattedHelloWorld1,   STRING_Formatted, STRING_Colored,
                                _().color.white));
    TEST_ExpectTrue(coloredHelloWorldOut == _().text.ConvertString(
        formattedHelloWorldOut0,    STRING_Formatted, STRING_Colored,
                                    _().color.white));
    TEST_ExpectTrue(coloredHelloWorldOut == _().text.ConvertString(
        formattedHelloWorldOut1, STRING_Formatted, STRING_Colored));
}

protected static function Test_CaseConversions()
{
    Context("Testing conversions between lower and upper case.");
    Issue("Character conversion to lower case works incorrectly.");
    TEST_ExpectTrue(    _().text.ToLower( _().text.GetCharacter("Ё") )
                    ==  _().text.GetCharacter("ё"));
    TEST_ExpectTrue(    _().text.ToLower( _().text.GetCharacter("щ") )
                    ==  _().text.GetCharacter("щ"));

    Issue("Character conversion to upper case works incorrectly.");
    TEST_ExpectTrue(    _().text.ToUpper( _().text.GetCharacter("r") )
                    ==  _().text.GetCharacter("R"));
    TEST_ExpectTrue(    _().text.ToUpper( _().text.GetCharacter("Ъ") )
                    ==  _().text.GetCharacter("Ъ"));

    Issue("Characters that do not have case are changed by case conversion.");
    TEST_ExpectTrue(    _().text.ToLower( _().text.GetCharacter("$") )
                    ==  _().text.GetCharacter("$"));
    TEST_ExpectTrue(    _().text.ToUpper( _().text.GetCharacter("-") )
                    ==  _().text.GetCharacter("-"));

    Issue("`string` conversion to lower case works incorrectly.");
    TEST_ExpectTrue(    _().text.ToLowerString("jUsT GoOd sTr&%!")
                    ==  "just good str&%!");
    TEST_ExpectTrue(    _().text.ToLowerString("just some string")
                    ==  "just some string");
    TEST_ExpectTrue(    _().text.ToLowerString(default.russianTest)
                    ==  default.russianTestLower);

    Issue("`string` conversion to upper case works incorrectly.");
    TEST_ExpectTrue(    _().text.ToUpperString("jUsT GoOd sTrInG")
                    ==  "JUST GOOD STRING");
    TEST_ExpectTrue(    _().text.ToUpperString("JUST SOME STRING")
                    ==  "JUST SOME STRING");
    TEST_ExpectTrue(    _().text.ToUpperString(default.russianTest)
                    ==  default.russianTestUpper);
}

protected static function Test_IsQuotationMark()
{
    Context("Testing `IsQuotationMark()`.");
    Issue("Method cannot correctly determine quotation marks.");
    TEST_ExpectTrue(_().text.IsQuotationMark(_().text.GetCharacter("'")));
    TEST_ExpectTrue(_().text.IsQuotationMark(_().text.GetCharacter("\"")));
    TEST_ExpectTrue(_().text.IsQuotationMark(_().text.GetCharacter("`")));
    Issue("Method reports non-quotation marks as such.");
    TEST_ExpectFalse(_().text.IsQuotationMark(_().text.GetCharacter("A")));
    TEST_ExpectFalse(_().text.IsQuotationMark(_().text.GetCharacter("^")));
}

protected static function Test_CharacterToInt()
{
    Context("Testing `CodePointToInt()`.");
    Issue("Method does not properly work for digits without specifying base.");
    TEST_ExpectTrue(_().text.CharacterToInt(_().text.GetCharacter("7")) == 7);
    TEST_ExpectTrue(_().text.CharacterToInt(_().text.GetCharacter("0")) == 0);

    Issue("Method does not properly work for latin letter without specifying"
        @ "base.");
    TEST_ExpectTrue(_().text.CharacterToInt(_().text.GetCharacter("a")) == 10);
    TEST_ExpectTrue(_().text.CharacterToInt(_().text.GetCharacter("z")) == 35);
    TEST_ExpectTrue(_().text.CharacterToInt(_().text.GetCharacter("T")) == 29);

    Issue("Method does not properly work with specified base.");
    TEST_ExpectTrue(
        _().text.CharacterToInt(_().text.GetCharacter("8"), 10) == 8);
    TEST_ExpectTrue(
        _().text.CharacterToInt(_().text.GetCharacter("T"), 30) == 29);
    TEST_ExpectTrue(
        _().text.CharacterToInt(_().text.GetCharacter("z"), 36) == 35);

    Issue("Method does not report error for characters that do not represent"
        @ "integers in a given base.");
    TEST_ExpectTrue(
        _().text.CharacterToInt(_().text.GetCharacter("7"), 5) == -1);
    TEST_ExpectTrue(
        _().text.CharacterToInt(_().text.GetCharacter("T"), 16) == -1);
    TEST_ExpectTrue(
        _().text.CharacterToInt(_().text.GetCharacter("z"), 35) == -1);

    Issue("Method does not report error for characters that never represent" 
        @ "integer.");
    TEST_ExpectTrue(
        _().text.CharacterToInt(_().text.GetCharacter("#")) == -1);
    TEST_ExpectTrue(
        _().text.CharacterToInt(_().text.GetCharacter("Ж")) == -1);
}

defaultproperties
{
    caseName = "Text API"

    russianTest = "НекоТорАя сТрОка"
    russianTestLower = "некоторая строка"
    russianTestUpper = "НЕКОТОРАЯ СТРОКА"

    languageMixTest = "This one is a perfectly valid string. С парой языков! ばか!~"
}