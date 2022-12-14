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

var const string japaneseString;

protected static function TESTS()
{
    Test_CharacterStringConverstions();
    Test_Equality();
    Test_CaseChecks();
    Test_GroupChecks();
    Test_CaseConversions();
    Test_CharacterToInt();
    Test_Parts();
    Test_FromVariables();
}

protected static function Test_CharacterStringConverstions()
{
    local BaseText.Character testCharacter;
    Context("Testing conversion between `Character` and `string`.");
    Issue("`GetCharacter()` incorrectly handles out-of-bounds indices.");
    TEST_ExpectFalse(__().text.IsValidCharacter(__().text.GetCharacter("")));
    TEST_ExpectFalse(
        __().text.IsValidCharacter(__().text.GetCharacter("yes", -1)));
    TEST_ExpectFalse(
        __().text.IsValidCharacter(__().text.GetCharacter("no", 2)));

    Issue("`GetCharacter()` returns wrong characters.");
    TEST_ExpectTrue(__().text.GetCharacter("j", 0).codePoint == 0x6a);
    TEST_ExpectTrue(
        __().text.GetCharacter(default.japaneseString, 1).codePoint == 0x304b);
    TEST_ExpectTrue(__().text.GetCharacter("Some string", 4).codePoint == 0x20);

    Issue("`CharacterToString()` incorrectly handles invalid characters.");
    testCharacter.codePoint = -1;
    TEST_ExpectTrue(__().text.CharacterToString(testCharacter) == "");
    testCharacter.codePoint = 0x23;
    TEST_ExpectTrue(__().text.CharacterToString(testCharacter) == "#");
    testCharacter.codePoint = 0x0401;
    TEST_ExpectTrue(__().text.CharacterToString(testCharacter) == "Ё");
}

protected static function Test_Equality()
{
    Context("Testing equality checks for codepoints.");
    Test_EqualityInvalid();
    Test_EqualitySimple();
    Test_EqualitySensitivityRules();
}

protected static function Test_EqualityInvalid()
{
    local BaseText.Character invalid1, invalid2, loChar, justChar;
    invalid1.codePoint              = -7;
    invalid2.codePoint              = -1;
    invalid2.formatting.isColored   = true;
    justChar.codePoint              = 0x02eb;
    loChar.codePoint                = 0x0436;
    Issue("`AreEqual()` incorrectly compares invalid (to any) characters.");
    TEST_ExpectTrue(__().text.AreEqual(invalid1, invalid1));
    TEST_ExpectTrue(__().text.AreEqual(invalid1, invalid2, SCASE_INSENSITIVE));
    TEST_ExpectTrue(__().text.AreEqual(invalid1, invalid2,, SFORM_SENSITIVE));
    TEST_ExpectFalse(__().text.AreEqual(invalid1, loChar,, SFORM_SENSITIVE));
    TEST_ExpectFalse(__().text.AreEqual(invalid2, justChar));
}

protected static function Test_EqualitySimple()
{
    local BaseText.Character loChar, hiChar, justChar, hiCharF;
    justChar.codePoint              = 0x02eb;
    loChar.codePoint                = 0x0436;
    hiChar.codePoint                = 0x0416;
    hiChar.formatting.isColored     = true;
    hiCharF = hiChar;
    hiCharF.formatting.color.r      = 145;
    Issue("`AreEqual()` incorrectly compares with only valid characters.");
    TEST_ExpectFalse(__().text.AreEqual(loChar, hiChar));
    TEST_ExpectTrue(__().text.AreEqual(hiChar, hiChar));
    TEST_ExpectTrue(__().text.AreEqual(justChar, justChar));
    TEST_ExpectTrue(__().text.AreEqual(hiChar, hiCharF));
}

protected static function Test_EqualitySensitivityRules()
{
    local BaseText.Character loChar, hiChar, justChar, hiCharF;
    justChar.codePoint              = 0x02eb;
    loChar.codePoint                = 0x0436;
    hiChar.codePoint                = 0x0416;
    hiChar.formatting.isColored     = true;
    hiCharF = hiChar;
    hiCharF.formatting.color.r      = 145;
    Issue("`AreEqual()` incorrectly compares with case-insensitivity.");
    TEST_ExpectTrue(__().text.AreEqual(loChar, hiChar, SCASE_INSENSITIVE));
    TEST_ExpectTrue(__().text.AreEqual(hiChar, hiChar, SCASE_INSENSITIVE));
    TEST_ExpectTrue(__().text.AreEqual(justChar, justChar, SCASE_INSENSITIVE));

    Issue("`AreEqual()` incorrectly compares when taking formatting"
        @ "into account.");
    TEST_ExpectFalse(__().text.AreEqual(loChar, hiChar,, SFORM_SENSITIVE));
    TEST_ExpectTrue(__().text.AreEqual(hiChar, hiChar,, SFORM_SENSITIVE));
    TEST_ExpectTrue(__().text.AreEqual(justChar, justChar,, SFORM_SENSITIVE));
    TEST_ExpectFalse(__().text.AreEqual(hiChar, hiCharF,, SFORM_SENSITIVE));

    Issue("`AreEqual()` incorrectly compares when taking formatting,"
        @ "but not case into account.");
    TEST_ExpectFalse(__().text.AreEqual(loChar, hiChar,
        SCASE_INSENSITIVE, SFORM_SENSITIVE));
    TEST_ExpectTrue(__().text.AreEqual(justChar, justChar,
        SCASE_INSENSITIVE, SFORM_SENSITIVE));
    TEST_ExpectFalse(__().text.AreEqual(hiChar, hiCharF,
        SCASE_INSENSITIVE, SFORM_SENSITIVE));
}

protected static function Test_CaseChecks()
{
    Context("Testing case-testing functions.");
    Issue("Case of characters is incorrectly determined.");
    TEST_ExpectTrue(__().text.IsLower( __().text.GetCharacter("q") ));
    TEST_ExpectTrue(__().text.IsUpper( __().text.GetCharacter("D") ));
    TEST_ExpectTrue(__().text.IsUpper( __().text.GetCharacter("Е") ));
    TEST_ExpectTrue(__().text.IsLower( __().text.GetCharacter("л") ));

    Issue("Non-letters reported as having either upper or lower case.");
    TEST_ExpectFalse(__().text.IsLower( __().text.GetCharacter("$") ));
    TEST_ExpectFalse(__().text.IsUpper( __().text.GetCharacter("$") ));
    TEST_ExpectFalse(__().text.IsLower( __().text.GetCharacter("&") ));
    TEST_ExpectFalse(__().text.IsUpper( __().text.GetCharacter("&") ));
    TEST_ExpectFalse(__().text.IsLower( __().text.GetCharacter("(") ));
    TEST_ExpectFalse(__().text.IsUpper( __().text.GetCharacter("(") ));
}

protected static function Test_GroupChecks()
{
    SubTest_CommonGroupChecks();
    SubTest_WhitespaceChecks();
    SubTest_IsQuotationMark();
    SubTest_ASCIICheck();
}

protected static function SubTest_CommonGroupChecks()
{
    Context("Testing `IsDigit()` function.");
    Issue("`IsDigit()` check does not recognize all of the digits.");
    TEST_ExpectTrue(__().text.IsDigit( __().text.GetCharacter("0") ));
    TEST_ExpectTrue(__().text.IsDigit( __().text.GetCharacter("1") ));
    TEST_ExpectTrue(__().text.IsDigit( __().text.GetCharacter("2") ));
    TEST_ExpectTrue(__().text.IsDigit( __().text.GetCharacter("3") ));
    TEST_ExpectTrue(__().text.IsDigit( __().text.GetCharacter("4") ));
    TEST_ExpectTrue(__().text.IsDigit( __().text.GetCharacter("5") ));
    TEST_ExpectTrue(__().text.IsDigit( __().text.GetCharacter("6") ));
    TEST_ExpectTrue(__().text.IsDigit( __().text.GetCharacter("7") ));
    TEST_ExpectTrue(__().text.IsDigit( __().text.GetCharacter("8") ));
    TEST_ExpectTrue(__().text.IsDigit( __().text.GetCharacter("9") ));

    Issue("`IsDigit()` accepts non-digit characters as digits.");
    TEST_ExpectFalse(__().text.IsDigit( __().text.GetCharacter("%") ));
    TEST_ExpectFalse(__().text.IsDigit( __().text.GetCharacter("Ж") ));

    Issue("`IsDigit()` accepts invalid characters as digits.");
    TEST_ExpectFalse(__().text.IsDigit( __().text.GetCharacter("") ));
}

protected static function SubTest_WhitespaceChecks()
{
    local BaseText.Character character;
    Context("Testing functions for identifying whitespace characters.");
    Issue(  "Unicode code points, classically considered whitespaces, are not" @
            "recognized as whitespaces.");
    character.codePoint = 0x0020;
    TEST_ExpectTrue(__().text.IsWhitespace(character));
    character.codePoint = 0x0009;
    TEST_ExpectTrue(__().text.IsWhitespace(character));
    character.codePoint = 0x000A;
    TEST_ExpectTrue(__().text.IsWhitespace(character));
    character.codePoint = 0x000B;
    TEST_ExpectTrue(__().text.IsWhitespace(character));
    character.codePoint = 0x000C;
    TEST_ExpectTrue(__().text.IsWhitespace(character));
    character.codePoint = 0x000D;
    TEST_ExpectTrue(__().text.IsWhitespace(character));

    Issue(  "Unicode code points that belong to 'Separator, Space' Category" @
            "are not recognized as whitespaces.");
    character.codePoint = 0x00A0;
    TEST_ExpectTrue(__().text.IsWhitespace(character));
    character.codePoint = 0x2001;
    TEST_ExpectTrue(__().text.IsWhitespace(character));
    character.codePoint = 0x2007;
    TEST_ExpectTrue(__().text.IsWhitespace(character));
    character.codePoint = 0x3000;
    TEST_ExpectTrue(__().text.IsWhitespace(character));

    Issue(  "Some Unicode code points that aren't whitespaces by any metric" @
            "are recognized as such.");
    character.codePoint = 0x0045;
    TEST_ExpectFalse(__().text.IsWhitespace(character) );
}

protected static function SubTest_IsQuotationMark()
{
    Context("Testing `IsQuotationMark()`.");
    Issue("Method cannot correctly determine quotation marks.");
    TEST_ExpectTrue(__().text.IsQuotationMark(__().text.GetCharacter("'")));
    TEST_ExpectTrue(__().text.IsQuotationMark(__().text.GetCharacter("\"")));
    TEST_ExpectTrue(__().text.IsQuotationMark(__().text.GetCharacter("`")));
    Issue("Method reports non-quotation marks as such.");
    TEST_ExpectFalse(__().text.IsQuotationMark(__().text.GetCharacter("A")));
    TEST_ExpectFalse(__().text.IsQuotationMark(__().text.GetCharacter("^")));
}

protected static function SubTest_ASCIICheck()
{
    local int               i;
    local BaseText.Character    nextChar;
    Context("Testing `IsASCII()` function.");
    Issue("`IsASCII()` incorrectly classifies characters.");
    for (i = 1; i < 200; i += 1)
    {
        nextChar.codePoint = i;
        if (i < 128) {
            TEST_ExpectTrue(__().text.IsASCII(nextChar));
        }
        else {
            TEST_ExpectFalse(__().text.IsASCII(nextChar));
        }
    }
}

protected static function Test_CaseConversions()
{
    Context("Testing conversions between lower and upper case.");
    Issue("Character conversion to lower case works incorrectly.");
    TEST_ExpectTrue(    __().text.ToLower( __().text.GetCharacter("Ё") )
                    ==  __().text.GetCharacter("ё"));
    TEST_ExpectTrue(    __().text.ToLower( __().text.GetCharacter("щ") )
                    ==  __().text.GetCharacter("щ"));

    Issue("Character conversion to upper case works incorrectly.");
    TEST_ExpectTrue(    __().text.ToUpper( __().text.GetCharacter("r") )
                    ==  __().text.GetCharacter("R"));
    TEST_ExpectTrue(    __().text.ToUpper( __().text.GetCharacter("Ъ") )
                    ==  __().text.GetCharacter("Ъ"));

    Issue("Characters that do not have case are changed by case conversion.");
    TEST_ExpectTrue(    __().text.ToLower( __().text.GetCharacter("$") )
                    ==  __().text.GetCharacter("$"));
    TEST_ExpectTrue(    __().text.ToUpper( __().text.GetCharacter("-") )
                    ==  __().text.GetCharacter("-"));
}

protected static function Test_CharacterToInt()
{
    Context("Testing `CodePointToInt()`.");
    Issue("Method does not properly work for digits without specifying base.");
    TEST_ExpectTrue(__().text.CharacterToInt(__().text.GetCharacter("7")) == 7);
    TEST_ExpectTrue(__().text.CharacterToInt(__().text.GetCharacter("0")) == 0);

    Issue("Method does not properly work for latin letter without specifying"
        @ "base.");
    TEST_ExpectTrue(
        __().text.CharacterToInt(__().text.GetCharacter("a")) == 10);
    TEST_ExpectTrue(
        __().text.CharacterToInt(__().text.GetCharacter("z")) == 35);
    TEST_ExpectTrue(
        __().text.CharacterToInt(__().text.GetCharacter("T")) == 29);

    Issue("Method does not properly work with specified base.");
    TEST_ExpectTrue(
        __().text.CharacterToInt(__().text.GetCharacter("8"), 10) == 8);
    TEST_ExpectTrue(
        __().text.CharacterToInt(__().text.GetCharacter("T"), 30) == 29);
    TEST_ExpectTrue(
        __().text.CharacterToInt(__().text.GetCharacter("z"), 36) == 35);

    Issue("Method does not report error for characters that do not represent"
        @ "integers in a given base.");
    TEST_ExpectTrue(
        __().text.CharacterToInt(__().text.GetCharacter("7"), 5) == -1);
    TEST_ExpectTrue(
        __().text.CharacterToInt(__().text.GetCharacter("T"), 16) == -1);
    TEST_ExpectTrue(
        __().text.CharacterToInt(__().text.GetCharacter("z"), 35) == -1);

    Issue("Method does not report error for characters that never represent" 
        @ "integer.");
    TEST_ExpectTrue(
        __().text.CharacterToInt(__().text.GetCharacter("#")) == -1);
    TEST_ExpectTrue(
        __().text.CharacterToInt(__().text.GetCharacter("Ж")) == -1);
}

protected static function Test_Parts()
{
    local array<BaseText> array1, array2;
    Context("Testing `Parts()`.");
    Issue("Returns non-empty array for empty input.");
    TEST_ExpectTrue(__().text.Parts(__().text.Empty()).length == 0);

    Issue("Returns incorrect parts.");
    array1 = __().text.Parts(__().text.FromString("/usr/bin/command"));
    array2 = __().text.Parts(__().text.FromString("a//a/*aa"));
    TEST_ExpectTrue(array1.length == 3);
    TEST_ExpectTrue(array1[0].CompareToString("usr"));
    TEST_ExpectTrue(array1[1].CompareToString("bin"));
    TEST_ExpectTrue(array1[2].CompareToString("command"));
    TEST_ExpectTrue(array2.length == 4);
    TEST_ExpectTrue(array2[0].CompareToString("//"));
    TEST_ExpectTrue(array2[1].CompareToString("/*"));
    TEST_ExpectTrue(array2[2].CompareToString(""));
    TEST_ExpectTrue(array2[3].CompareToString(""));
}

protected static function Test_FromVariables()
{
    Context("Testing conversion of primitive UnrealScript variables into"
        @ "`Text` / `MutableText`.");
    SubTest_FromVariablesImmutable();
    SubTest_FromVariablesMutable();
}

protected static function SubTest_FromVariablesImmutable()
{
    Issue("Immutable conversion method do not produce `Text`.");
    TEST_ExpectTrue(__().text.FromBool(false).class == class'Text');
    TEST_ExpectTrue(__().text.FromByte(12).class == class'Text');
    TEST_ExpectTrue(__().text.FromInt(23).class == class'Text');
    TEST_ExpectTrue(__().text.FromFloat(12.123).class == class'Text');

    Issue("`bool` is incorrectly converted into `Text`.");
    TEST_ExpectTrue(__().text.FromBool(false).ToString() == "false");
    TEST_ExpectTrue(__().text.FromBool(true).ToString() == "true");

    Issue("`byte` is incorrectly converted into `Text`.");
    TEST_ExpectTrue(__().text.FromByte(134).ToString() == "134");
    TEST_ExpectTrue(__().text.FromByte(0).ToString() == "0");

    Issue("`int` is incorrectly converted into `Text`.");
    TEST_ExpectTrue(    __().text.FromInt(-124233124).ToString()
                    ==  "-124233124");
    TEST_ExpectTrue(__().text.FromInt(10000001).ToString() == "10000001");

    Issue("`float` is incorrectly converted into `Text`.");
    TEST_ExpectTrue(__().text.FromFloat(4.56).ToString() == "4.56");
    TEST_ExpectTrue(    __().text.FromFloat(-0.0001, 4).ToString()
                    ==  "-0.0001");
    TEST_ExpectTrue(__().text.FromFloat(0, 10).ToString() == "0");
    TEST_ExpectTrue(__().text.FromFloat(34.67, -1).ToString() == "35");
}

protected static function SubTest_FromVariablesMutable()
{
    Issue("Mutable conversion method do not produce `Text`.");
    TEST_ExpectTrue(__().text.FromBoolM(false).class == class'MutableText');
    TEST_ExpectTrue(__().text.FromByteM(12).class == class'MutableText');
    TEST_ExpectTrue(__().text.FromIntM(23).class == class'MutableText');
    TEST_ExpectTrue(__().text.FromFloatM(12.123).class == class'MutableText');

    Context("testing conversion of primitive UnrealScript variables into"
        @ "`Text`");
    Issue("`bool` is incorrectly converted into `MutableText`.");
    TEST_ExpectTrue(__().text.FromBoolM(false).ToString() == "false");
    TEST_ExpectTrue(__().text.FromBoolM(true).ToString() == "true");

    Issue("`byte` is incorrectly converted into `MutableText`.");
    TEST_ExpectTrue(__().text.FromByteM(134).ToString() == "134");
    TEST_ExpectTrue(__().text.FromByteM(0).ToString() == "0");

    Issue("`int` is incorrectly converted into `MutableText`.");
    TEST_ExpectTrue(    __().text.FromIntM(-124233124).ToString()
                    ==  "-124233124");
    TEST_ExpectTrue(__().text.FromIntM(10000001).ToString() == "10000001");

    Issue("`float` is incorrectly converted into `MutableText`.");
    TEST_ExpectTrue(__().text.FromFloatM(4.56).ToString() == "4.56");
    TEST_ExpectTrue(    __().text.FromFloatM(-0.0001, 4).ToString()
                    ==  "-0.0001");
    TEST_ExpectTrue(__().text.FromFloatM(0, 10).ToString() == "0");
    TEST_ExpectTrue(__().text.FromFloatM(34.67, -1).ToString() == "35");
}

defaultproperties
{
    caseName = "TextAPI"
    caseGroup = "Text"
    japaneseString = "ばか です"
}