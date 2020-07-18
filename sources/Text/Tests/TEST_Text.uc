/**
 *  Set of tests for `Text` class.
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
class TEST_Text extends TestCase
    abstract;

var const string russianTest, russianTestLower, russianTestUpper;
var const string languageMixTest;

protected static function TESTS()
{
    Test_SetGetTests();
    Test_LengthTests();
    Test_GetCharacter();
    Test_CaseConversions();
}

protected static function Test_SetGetTests()
{
    SubTest_SetGetTestsStringText();
    SubTest_SetGetTestsArrayText();
    SubTest_SetGetTestsArrayTextEmpty();
    SubTest_TextCopy();
}
//  TODO: redo tests to account for colored strings
protected static function SubTest_SetGetTestsStringText()
{
    local Text      textInstance;
    local string    stringInstance;
    //  These test several things at once, but they are basically getters and
    //  setters that are hard/meaningless to test separately.
    Context("Testing functions for conversion between `Text` and `string`.");
    Issue(  "`_.text.FromString()` -> `Text.ToString()` alters" @
            "the initial string value when it shouldn't.");
    stringInstance = "Just my random string here! & stuff";
    textInstance = _().text.FromString(stringInstance);
    TEST_ExpectTrue(stringInstance == textInstance.ToString(STRING_Plain));
    TEST_ExpectTrue(textInstance.IsEqualToString(stringInstance));

    Issue(  "`_.text.CopyString()` -> `Text.ToString()` alters" @
            "the initial string value when it shouldn't.");
    stringInstance = "Another, brand new string.";
    textInstance = textInstance.CopyString(stringInstance);
    TEST_ExpectTrue(stringInstance == textInstance.ToString(STRING_Plain));
    TEST_ExpectTrue(textInstance.IsEqualToString(stringInstance));

    Issue(  "`_.text.FromString(\"\")` doesn't create `Text` containing empty" @
        "string.");
    TEST_ExpectTrue(_().text.FromString("").ToString(STRING_Plain) == "");
    TEST_ExpectTrue(_().text.FromString("").IsEqualToString(""));

    Issue(  "`_.text.CopyString(\"\")` doesn't create `Text` containing empty" @
            "string.");
    textInstance.CopyString("");
    TEST_ExpectTrue(textInstance.ToString(STRING_Plain) == "");
    TEST_ExpectTrue(textInstance.IsEqualToString(""));

    Issue(  "`_.text.FromString(\"\")` doesn't produce empty `Text`" @
            "according to `Text.IsEmpty()`.");
    TEST_ExpectTrue(_().text.FromString("").IsEmpty());

    Issue(  "`_.text.CopyString(\"\")` doesn't produce empty `Text`" @
            "according to `Text.IsEmpty()`.");
    TEST_ExpectTrue(textInstance.CopyString("").IsEmpty());
}

//  Returns array of Unicode code points decoding "Hello, World!"
protected static function array<Text.Character> PrepareArray()
{
    local array<Text.Character> preparedArray;
    preparedArray.length = 13;
    preparedArray[0].codePoint = 0x0048;    // H
    preparedArray[1].codePoint = 0x0065;    // e
    preparedArray[2].codePoint = 0x006c;    // l
    preparedArray[3].codePoint = 0x006c;    // l
    preparedArray[4].codePoint = 0x006f;    // o
    preparedArray[5].codePoint = 0x002c;    // ,
    preparedArray[6].codePoint = 0x0020;    // <whitespace>
    preparedArray[7].codePoint = 0x0057;    // W
    preparedArray[8].codePoint = 0x006f;    // o
    preparedArray[9].codePoint = 0x0072;    // r
    preparedArray[10].codePoint = 0x006c;   // l
    preparedArray[11].codePoint = 0x0064;   // d
    preparedArray[12].codePoint = 0x0021;   // !
    return preparedArray;
}

protected static function SubTest_SetGetTestsArrayText()
{
    local int                   i;
    local bool                  arraysAreSame;
    local Text                  textInstance;
    local array<Text.Character> arrayInstance, arrayInstance2;
    //  These test several things at once, but they are basically getters and
    //  setters that are hard/meaningless to test separately.
    Context("Testing functions for conversion between `Text`" @
            "and arrays of Unicode code points.");
    Issue(  "`_.text.FromRaw()` -> `Text.ToRaw()` alters" @
            "the initial string value.");
    arrayInstance = PrepareArray();
    textInstance = _().text.FromRaw(arrayInstance);
    arrayInstance2 = textInstance.ToRaw();
    arraysAreSame = arrayInstance.length == arrayInstance2.length;
    if (arraysAreSame)
    {
        for (i = 0; i < arrayInstance.length; i += 1)
        {
            if (arrayInstance[i] != arrayInstance2[i])
            {
                arraysAreSame = false;
                break;
            }
        }
    }
    TEST_ExpectTrue(arraysAreSame);

    Issue(  "`_.text.CopyRaw()` -> `Text.ToRaw()` alters" @
            "initial array values.");
    arrayInstance = PrepareArray();
    textInstance.CopyRaw(arrayInstance);
    arrayInstance2 = textInstance.ToRaw();
    arraysAreSame = arrayInstance.length == arrayInstance2.length;
    if (arraysAreSame)
    {
        for (i = 0; i < arrayInstance.length; i += 1)
        {
            if (arrayInstance[i] != arrayInstance2[i])
            {
                arraysAreSame = false;
                break;
            }
        }
    }
    TEST_ExpectTrue(arraysAreSame);
}

protected static function SubTest_SetGetTestsArrayTextEmpty()
{
    local Text                  textInstance;
    local array<Text.Character> arrayInstance;
    Context("Testing functions for conversion between `Text`" @
            "and arrays of Unicode code points.");
    Issue(  "`_.text.FromRaw([])` -> `Text.ToRaw()` does not produce" @
            "empty array.");
    TEST_ExpectTrue(_().text.FromRaw(arrayInstance).ToRaw().length == 0);

    Issue(  "`Text.CopyRaw([])` -> `Text.ToRaw()` does not produce" @
            "empty array.");
    textInstance = _().text.FromString("Fill it with bullshit.");
    textInstance.CopyRaw(arrayInstance);
    TEST_ExpectTrue(textInstance.ToRaw().length == 0);

    Issue(  "`_.text.FromRaw([])` does not produce empty `Text`" @
            "according to `Text.IsEmpty()`.");
    TEST_ExpectTrue(_().text.FromRaw(arrayInstance).IsEmpty());

    Issue(  "`Text.CopyRaw([])` does not produce empty `Text`" @
            "according to `Text.IsEmpty()`.");
    textInstance = _().text.FromString("Fill it with bullshit.");
    textInstance.CopyRaw(arrayInstance);
    TEST_ExpectTrue(textInstance.IsEmpty());
}

protected static function SubTest_TextCopy()
{
    local Text text1, text2;
    Context("Testing `Copy()` function for copying `Text` into another `Text`");
    Issue("Copying `Text` produces a `Text` object with different content," @
            "according to `IsEqual().");
    text1 = _().text.FromString(default.languageMixTest);
    text2 = _().text.Empty();
    text2.Copy(text1);
    TEST_ExpectTrue(text1.IsEqual(text2));
    TEST_ExpectTrue(text2.IsEqual(text1));
}

protected static function Test_LengthTests()
{
    Context("Testing `Text.GetLength()` function.");
    Issue("Empty `Text` has non-zero length.");
    TEST_ExpectTrue(_().text.FromString("").GetLength() == 0);

    Issue("Length is incorrectly computed.");
    TEST_ExpectTrue(_().text.FromString("ABC DEF").GetLength() == 7);
    TEST_ExpectTrue(
        _().text.FromString("  string with  padding  ").GetLength() == 24);
}

protected static function Test_GetCharacter()
{
    Context("Testing `Text.GetCodePoint()` function.");
    Issue("Doesn't return ASCII code points correctly.");
    TEST_ExpectTrue(_().text.FromString("Q").GetCharacter().codePoint == 0x51);
    TEST_ExpectTrue(_().text.FromString("4").GetCharacter().codePoint == 0x34);
    TEST_ExpectTrue(_().text.FromString("@").GetCharacter().codePoint == 0x40);
    TEST_ExpectTrue(    _().text.FromString("Л").GetCharacter().codePoint
                    ==  0x041b);
    TEST_ExpectTrue(    _().text.FromString("の").GetCharacter().codePoint
                    ==  0x306e);

    Issue("Returns wrong code point when non-zero index is specified.");
    TEST_ExpectTrue(    _().text.FromString("Word~bar").GetCharacter(4).codePoint
                    ==  0x007e);
    TEST_ExpectTrue(
            _().text.FromString("Why must we suffer").GetCharacter(17).codePoint
        ==  0x0072);
    TEST_ExpectTrue(
            _().text.FromString("Why must we suffer").GetCharacter(0).codePoint
        ==  0x0057);

    Issue("Doesn't return `-1` for incorrect index.");
    TEST_ExpectTrue(_().text.FromString("S").GetCharacter(2).codePoint == -1);
    TEST_ExpectTrue(    _().text.FromString("Just").GetCharacter(-1).codePoint
                    ==  -1);
    TEST_ExpectTrue(_().text.FromString("d").GetCharacter(1).codePoint == -1);
    TEST_ExpectTrue(_().text.FromString("").GetCharacter(0).codePoint == -1);
}


protected static function Test_CaseConversions()
{
    Context("Testing conversions between lower and upper case");
    Issue("Text conversion to lower case works incorrectly.");
    TEST_ExpectTrue(_().text.FromString("jUsT GoOd sTr&%!").ToLower().
        IsEqualToString("just good str&%!"));
    TEST_ExpectTrue(_().text.FromString("just some string").ToLower().
        IsEqualToString("just some string"));
    TEST_ExpectTrue(_().text.FromString(default.russianTest).ToLower().
        IsEqualToString(default.russianTestLower));

    Issue("Text conversion to upper case works incorrectly.");
    TEST_ExpectTrue(_().text.FromString("jUsT GoOd sTrInG").ToUpper().
        IsEqualToString("JUST GOOD STRING"));
    TEST_ExpectTrue(_().text.FromString("JUST SOME STRING").ToUpper().
        IsEqualToString("JUST SOME STRING"));
    TEST_ExpectTrue(_().text.FromString(default.russianTest).ToUpper().
        IsEqualToString(default.russianTestUpper));
}

defaultproperties
{
    caseName = "Text"

    russianTest = "НекоТорАя сТрОка"
    russianTestLower = "некоторая строка"
    russianTestUpper = "НЕКОТОРАЯ СТРОКА"

    languageMixTest = "This one is a perfectly valid string. С парой языков! ばか!~"
}