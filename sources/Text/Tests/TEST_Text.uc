/**
 *  Set of tests for functionality of `Text` and `MutableText` classes.
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
class TEST_Text extends TestCase
    abstract;

var string  justString, altString;
var string  formattedString, rndCaseString, bothString;
var string  spacesString, spacesEmptyString, trimmedString, simplifiedString;

var Text    emptyText, emptyText2, justText, altText;
var Text    formattedText, rndCaseText, bothText;

protected static function TESTS()
{
    Test_TextCreation();
    Test_TextCopy();
    Test_TextLength();
    Test_EqualityTests();
    Test_GetCharacter();
    Test_GetFormatting();
    Test_AppendGet();
    Test_AppendStringGet();
    Test_AppendRaw();
    Test_Substring();
    Test_SeparateByCharacter();
    Test_StartsEndsWith();
    Test_IndexOf();
    Test_Replace();
    Test_ChangeFormatting();
    Test_Remove();
    Test_Simplify();
}

protected static function Test_TextCreation()
{
    Context("Testing basic functionality for creating `Text` objects.");
    SubTest_TextCreationSimply();
    SubTest_TextCreationFormattedComplex();
}

protected static function SubTest_TextCreationSimply()
{
    local string    plainString, coloredString, formattedString;
    local Text      plain, colored, formatted;
    Issue("`Text` object is not properly created from the plain string.");
    plainString = "Prepare to DIE and be reborn!";
    plain = __().text.FromString(plainString);
    TEST_ExpectNotNone(plain);
    TEST_ExpectTrue(plain.ToString() == plainString);

    Issue("`Text` object is not properly created from the colored string.");
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = __().text.FromColoredString(coloredString);
    TEST_ExpectNotNone(colored);
    TEST_ExpectTrue(colored.ToColoredString() == coloredString);

    Issue("`Text` object is not properly created from the formatted string.");
    formattedString = "Prepare to {rgb(255,0,0) DIE ^yand} be ^7reborn!";
    formatted = class'Text'.static.__().text.FromFormattedString(formattedString);
    TEST_ExpectNotNone(formatted);
    TEST_ExpectTrue(    formatted.ToFormattedString()
                    ==  ("Prepare to {rgb(255,0,0) DIE }{rgb(255,255,0) and} be"
                    @   "{rgb(255,255,255) reborn!}"));
}

protected static function SubTest_TextCreationFormattedComplex()
{
    local string    input, output;
    local Text      formatted;
    Issue("`Text` object is not properly created from the formatted string.");
    input = "This {$green i^4^5^cs q{#0f0f0f uit}^1e} a {rgb(45,234,154)"
        @ "{$white ^bcomplex {$white ex}amp^ple}!}";
    output = "This {rgb(0,128,0) i}{rgb(0,255,255) s q}{rgb(15,15,15) uit}"
        $ "{rgb(255,0,0) e} a {rgb(0,0,255) complex }{rgb(255,255,255) ex}"
        $ "{rgb(0,0,255) amp}{rgb(255,0,255) le}{rgb(45,234,154) !}";
    formatted = class'Text'.static.__().text.FromFormattedString(input);
    TEST_ExpectNotNone(formatted);
    TEST_ExpectTrue(formatted.ToFormattedString() == output);
}

protected static function Test_TextCopy()
{
    Context("Testing basic functionality for copying `Text` objects.");
    SubTest_TextCompleteCopy();
    SubTest_TextSubCopy();
    SubTest_TextLowerCompleteCopy();
    SubTest_TextLowerSubCopy();
    SubTest_TextUpperCompleteCopy();
    SubTest_TextUpperSubCopy();
}

protected static function SubTest_TextCompleteCopy()
{
    local string    plainString, coloredString, formattedString;
    local Text      plain, colored, formatted;
    plainString = "Prepare to DIE and be reborn!";
    plain = __().text.FromString(plainString);
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = __().text.FromColoredString(coloredString);
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.__().text.FromFormattedString(formattedString);

    Issue("`Text` object is not properly copied (immutable).");
    TEST_ExpectTrue(plain.Copy().ToString() == plainString);
    TEST_ExpectTrue(colored.Copy().ToColoredString() == coloredString);
    TEST_ExpectTrue(formatted.Copy().ToFormattedString() == formattedString);
    TEST_ExpectFalse(plain.Copy() == plain);
    TEST_ExpectFalse(colored.Copy() == colored);
    TEST_ExpectFalse(formatted.Copy() == formatted);

    Issue("`Text` object is not properly copied (mutable).");
    TEST_ExpectTrue(plain.MutableCopy().ToString() == plainString);
    TEST_ExpectTrue(colored.MutableCopy().ToColoredString() == coloredString);
    TEST_ExpectFalse(plain.class == class'MutableText');
    TEST_ExpectFalse(colored.class == class'MutableText');
    TEST_ExpectFalse(formatted.class == class'MutableText');
    TEST_ExpectFalse(plain.MutableCopy() == plain);
    TEST_ExpectFalse(colored.MutableCopy() == colored);
}

protected static function SubTest_TextSubCopy()
{
    local string    plainString, coloredString, formattedString;
    local Text      plain, colored, formatted;
    plainString = "Prepare to DIE and be reborn!";
    plain = __().text.FromString(plainString);
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = __().text.FromColoredString(coloredString);
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.__().text.FromFormattedString(formattedString);

    Issue("Part of `Text`'s contents is not properly copied (immutable).");
    TEST_ExpectTrue(    formatted.Copy(-2, 100).ToFormattedString()
                    ==  formattedString);
    TEST_ExpectTrue(plain.Copy(-2, 5).ToString() == "Pre");
    TEST_ExpectTrue(    formatted.Copy(13, -10).ToFormattedString()
                    ==  "{rgb(255,0,0) E} and be reborn!");
    TEST_ExpectTrue(formatted.Copy(32).ToString() == "");
    TEST_ExpectTrue(formatted.Copy(-30, -1).ToString() == plainString);
    TEST_ExpectTrue(formatted.Copy(-20, -1).ToString() == plainString);
    TEST_ExpectTrue(formatted.Copy(-30, 5).ToString() == "");
    TEST_ExpectTrue(formatted.Copy(-29, 32).ToString() == "Pre");

    Issue("Part of `Text`'s contents is not properly copied (mutable).");
    TEST_ExpectTrue(    formatted.MutableCopy(-2, 100).ToFormattedString()
                    ==  formattedString);
    TEST_ExpectTrue(plain.MutableCopy(-2, 5).ToString() == "Pre");
    TEST_ExpectTrue(    formatted.MutableCopy(13, -10).ToFormattedString()
                    ==  "{rgb(255,0,0) E} and be reborn!");
    TEST_ExpectTrue(formatted.MutableCopy(32).ToString() == "");
    TEST_ExpectTrue(formatted.MutableCopy(-30, -1).ToString() == plainString);
    TEST_ExpectTrue(formatted.MutableCopy(-20, -1).ToString() == plainString);
    TEST_ExpectTrue(formatted.MutableCopy(-30, 5).ToString() == "");
    TEST_ExpectTrue(formatted.MutableCopy(-29, 32).ToString() == "Pre");
}

protected static function SubTest_TextLowerCompleteCopy()
{
    local string    plainString, coloredString, formattedString;
    local Text      plain, colored, formatted;
    plainString = "Prepare to DIE and be reborn!";
    plain = __().text.FromString(plainString);
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = __().text.FromColoredString(coloredString);
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.__().text.FromFormattedString(formattedString);

    Issue("`Text` object is not properly copied (immutable) in lower case.");
    TEST_ExpectTrue(plain.LowerCopy().ToString() == Locs(plainString));
    TEST_ExpectTrue(    colored.LowerCopy().ToColoredString()
                    ==  Locs(coloredString));
    TEST_ExpectTrue(    formatted.LowerCopy().ToFormattedString()
                    ==  Locs(formattedString));
    TEST_ExpectFalse(plain.LowerCopy() == plain);
    TEST_ExpectFalse(colored.LowerCopy() == colored);
    TEST_ExpectFalse(formatted.LowerCopy() == formatted);

    Issue("`Text` object is not properly copied (mutable) in lower case.");
    TEST_ExpectTrue(    plain.LowerMutableCopy().ToString()
                    ==  Locs(plainString));
    TEST_ExpectTrue(    colored.LowerMutableCopy().ToColoredString()
                    ==  Locs(coloredString));
    TEST_ExpectFalse(plain.class == class'MutableText');
    TEST_ExpectFalse(colored.class == class'MutableText');
    TEST_ExpectFalse(formatted.class == class'MutableText');
    TEST_ExpectFalse(plain.LowerMutableCopy() == plain);
    TEST_ExpectFalse(colored.LowerMutableCopy() == colored);
}

protected static function SubTest_TextLowerSubCopy()
{
    local string    plainString, coloredString, formattedString;
    local Text      plain, colored, formatted;
    plainString = "Prepare to DIE and be reborn!";
    plain = __().text.FromString(plainString);
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = __().text.FromColoredString(coloredString);
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.__().text.FromFormattedString(formattedString);

    Issue("Part of `Text`'s contents is not properly copied (immutable) in"
        @ "lower case.");
    TEST_ExpectTrue(    formatted.LowerCopy(-2, 100).ToFormattedString()
                    ==  Locs(formattedString));
    TEST_ExpectTrue(plain.LowerCopy(-2, 5).ToString() == "pre");
    TEST_ExpectTrue(    formatted.LowerCopy(13, -10).ToFormattedString()
                    ==  "{rgb(255,0,0) e} and be reborn!");
    TEST_ExpectTrue(formatted.LowerCopy(32).ToString() == "");

    Issue("Part of `Text`'s contents is not properly copied (mutable) in"
        @ "lower case.");
    TEST_ExpectTrue(    formatted.LowerMutableCopy(-2, 100).ToFormattedString()
                    ==  Locs(formattedString));
    TEST_ExpectTrue(plain.LowerMutableCopy(-2, 5).ToString() == "pre");
    TEST_ExpectTrue(    formatted.LowerMutableCopy(13, -10).ToFormattedString()
                    ==  "{rgb(255,0,0) e} and be reborn!");
    TEST_ExpectTrue(formatted.LowerMutableCopy(32).ToString() == "");
}

protected static function SubTest_TextUpperCompleteCopy()
{
    local string    plainString, coloredString, formattedString;
    local Text      plain, colored, formatted;
    plainString = "Prepare to DIE and be reborn!";
    plain = __().text.FromString(plainString);
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = __().text.FromColoredString(coloredString);
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.__().text.FromFormattedString(formattedString);

    Issue("`Text` object is not properly copied (immutable) in upper case.");
    TEST_ExpectTrue(plain.UpperCopy().ToString() == Caps(plainString));
    TEST_ExpectTrue(    colored.UpperCopy().ToColoredString()
                    ==  Caps(coloredString));
    TEST_ExpectFalse(plain.UpperCopy() == plain);
    TEST_ExpectFalse(colored.UpperCopy() == colored);
    TEST_ExpectFalse(formatted.UpperCopy() == formatted);

    Issue("`Text` object is not properly copied (mutable) in upper case.");
    TEST_ExpectTrue(    plain.UpperMutableCopy().ToString()
                    ==  Caps(plainString));
    TEST_ExpectTrue(    colored.UpperMutableCopy().ToColoredString()
                    ==  Caps(coloredString));
    TEST_ExpectFalse(plain.class == class'MutableText');
    TEST_ExpectFalse(colored.class == class'MutableText');
    TEST_ExpectFalse(formatted.class == class'MutableText');
    TEST_ExpectFalse(plain.UpperMutableCopy() == plain);
    TEST_ExpectFalse(colored.UpperMutableCopy() == colored);
}

protected static function SubTest_TextUpperSubCopy()
{
    local string    plainString, coloredString, formattedString;
    local Text      plain, colored, formatted;
    plainString = "Prepare to DIE and be reborn!";
    plain = __().text.FromString(plainString);
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = __().text.FromColoredString(coloredString);
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.__().text.FromFormattedString(formattedString);

    Issue("Part of `Text`'s contents is not properly copied (immutable) in"
        @ "lower case.");
    TEST_ExpectTrue(plain.UpperCopy(-2, 5).ToString() == "PRE");
    TEST_ExpectTrue(    formatted.UpperCopy(13, -10).ToFormattedString()
                    ==  "{rgb(255,0,0) E} AND BE REBORN!");
    TEST_ExpectTrue(formatted.UpperCopy(32).ToString() == "");

    Issue("Part of `Text`'s contents is not properly copied (mutable) in"
        @ "upper case.");
    TEST_ExpectTrue(plain.UpperMutableCopy(-2, 5).ToString() == "PRE");
    TEST_ExpectTrue(    formatted.UpperMutableCopy(13, -10).ToFormattedString()
                    ==  "{rgb(255,0,0) E} AND BE REBORN!");
    TEST_ExpectTrue(formatted.UpperMutableCopy(32).ToString() == "");
}

protected static function Test_TextLength()
{
    local Text allocated, empty, saturated;
    Context("Testing functionality for measuring length of `Text`'s contents.");
    allocated = Text(__().memory.Allocate(class'Text'));
    empty = __().text.FromColoredString("");
    Issue("Newly created or `Text` is not considered empty.");
    TEST_ExpectTrue(allocated.GetLength() == 0);
    TEST_ExpectTrue(allocated.IsEmpty());
    TEST_ExpectTrue(empty.GetLength() == 0);
    TEST_ExpectTrue(empty.IsEmpty());

    saturated = class'Text'.static.__().text.FromFormattedString(
        "Prepare to {rgb(255,0,0) DIE} and be reborn!");
    TEST_ExpectFalse(saturated.IsEmpty());
    TEST_ExpectTrue(    saturated.GetLength()
                    ==  Len("Prepare to DIE and be reborn!"));
}

protected static function PrepareDataForComparison()
{
    default.emptyText = __().text.FromString("");
    default.emptyText2 = __().text.FromString("");
    default.justText =
        __().text.FromString(default.justString);
    default.altText =
        __().text.FromString(default.altString);
    default.formattedText =
        class'Text'.static.__().text.FromFormattedString(default.formattedString);
    default.rndCaseText =
        __().text.FromString(default.rndCaseString);
    default.bothText =
        class'Text'.static.__().text.FromFormattedString(default.bothString);
}

protected static function Test_EqualityTests()
{
    PrepareDataForComparison();
    Context("Testing functionality for equality checking.");
    SubTest_EqualitySimple();
    SubTest_EqualityCaseFormatting();
    SubTest_EqualityStringSimple();
    SubTest_EqualityStringCaseFormatting();
}

protected static function SubTest_EqualitySimple()
{
    Issue("Comparisons with `none` are return `true`.");
    TEST_ExpectFalse(default.emptyText.Compare(none));
    TEST_ExpectFalse(default.justText.Compare(none));

    Issue("Comparisons with empty `Text` are not working as expected.");
    TEST_ExpectTrue(default.emptyText.Compare(default.emptyText));
    TEST_ExpectTrue(default.emptyText.Compare(default.emptyText2));
    TEST_ExpectFalse(default.emptyText.Compare(default.justText));
    TEST_ExpectFalse(default.justText.Compare(default.emptyText));

    Issue("Simple case-sensitive check is not working as expected.");
    TEST_ExpectTrue(default.justText.Compare(default.justText));
    TEST_ExpectFalse(default.justText.Compare(default.altText));
    TEST_ExpectFalse(default.justText.Compare(default.rndCaseText));
    TEST_ExpectTrue(default.bothText.Compare(default.rndCaseText));
    TEST_ExpectTrue(default.justText.Compare(default.formattedText));
}

protected static function SubTest_EqualityCaseFormatting()
{
    Issue("Case-insensitive check are not working as expected.");
    TEST_ExpectTrue(default.justText.Compare(   default.justText,
                                                SCASE_INSENSITIVE));
    TEST_ExpectFalse(default.justText.Compare(  default.altText,
                                                SCASE_INSENSITIVE));
    TEST_ExpectTrue(default.justText.Compare(   default.rndCaseText,
                                                SCASE_INSENSITIVE));
    TEST_ExpectTrue(default.bothText.Compare(   default.formattedText,
                                                SCASE_INSENSITIVE));

    Issue("Format-sensitive check are not working as expected.");
    TEST_ExpectTrue(default.justText.Compare(   default.justText,,
                                                SFORM_SENSITIVE));
    TEST_ExpectTrue(default.justText.Compare(   default.rndCaseText,
                                                SCASE_INSENSITIVE,
                                                SFORM_SENSITIVE));
    TEST_ExpectFalse(default.justText.Compare(  default.formattedText,,
                                                SFORM_SENSITIVE));
    TEST_ExpectTrue(default.formattedText.Compare(  default.bothText,
                                                SCASE_INSENSITIVE,
                                                SFORM_SENSITIVE));
}

protected static function SubTest_EqualityStringSimple()
{
    Issue("Comparisons with empty `Text` are not working as expected.");
    TEST_ExpectTrue(default.emptyText.CompareToString(""));
    TEST_ExpectTrue(default.emptyText.CompareToColoredString(""));
    TEST_ExpectFalse(default.emptyText.
        CompareToString(default.justString));
    TEST_ExpectFalse(default.justText.CompareToString(""));

    Issue("Simple case-sensitive check is not working as expected.");
    TEST_ExpectTrue(default.justText.CompareToString(default.justString));
    TEST_ExpectFalse(default.justText.CompareToString(default.altString));
    TEST_ExpectFalse(default.justText.
        CompareToFormattedString(default.rndCaseString));
    TEST_ExpectTrue(default.bothText.
        CompareToColoredString(default.rndCaseString));
    TEST_ExpectTrue(default.justText.
        CompareToFormattedString(default.formattedString));
}

protected static function SubTest_EqualityStringCaseFormatting()
{
    Issue("Case-insensitive check are not working as expected.");
    TEST_ExpectTrue(default.justText.CompareToString(  default.justString,
                                                            SCASE_INSENSITIVE));
    TEST_ExpectFalse(default.justText.CompareToString( default.altString,
                                                            SCASE_INSENSITIVE));
    TEST_ExpectTrue(default.justText.CompareToColoredString(
        default.rndCaseString, SCASE_INSENSITIVE));
    TEST_ExpectTrue(default.bothText.CompareToFormattedString(
        default.formattedString, SCASE_INSENSITIVE));

    Issue("Format-sensitive check are not working as expected.");
    TEST_ExpectTrue(default.justText.CompareToColoredString(
        default.justString,, SFORM_SENSITIVE));
    TEST_ExpectTrue(default.justText.CompareToString(
        default.rndCaseString, SCASE_INSENSITIVE, SFORM_SENSITIVE));
    TEST_ExpectFalse(default.justText.CompareToFormattedString(
        default.formattedString,, SFORM_SENSITIVE));
    TEST_ExpectTrue(default.formattedText.CompareToFormattedString(
        default.bothString, SCASE_INSENSITIVE, SFORM_SENSITIVE));
}

protected static function Test_GetCharacter()
{
    local Text txt;
    Context("Testing functionality for extracting characters.");
    txt = class'Text'.static.__().text.FromFormattedString("Prepare to"
        @ "{rgb(255,0,0) DIE} and be {rgb(143,200,72) reborn}!");
    Issue("Extracted characters have incorrect code points.");
    //  0x65 ~ 'e', 0x72 ~ 'r'
    TEST_ExpectTrue(__().text.IsCodePoint(txt.GetCharacter(2), 0x65));
    TEST_ExpectTrue(__().text.IsCodePoint(txt.GetCharacter(26), 0x72));
    TEST_ExpectTrue(__().text.IsCodePoint(txt.GetRawCharacter(2), 0x65));
    TEST_ExpectTrue(__().text.IsCodePoint(txt.GetRawCharacter(26), 0x72));

    Issue("Extracted characters have incorrect formatting"
        @ "information recorded.");
    TEST_ExpectFalse(txt.GetCharacter(2).formatting.isColored);
    TEST_ExpectFalse(txt.GetRawCharacter(2).formatting.isColored);
    TEST_ExpectTrue(txt.GetCharacter(26).formatting.isColored);
    TEST_ExpectFalse(txt.GetRawCharacter(26).formatting.isColored);
    TEST_ExpectTrue(txt.GetCharacter(26).formatting.color.r == 143);
    TEST_ExpectTrue(txt.GetCharacter(26).formatting.color.g == 200);
    TEST_ExpectTrue(txt.GetCharacter(26).formatting.color.b == 72);
}

protected static function Test_GetFormatting()
{
    local Text txt;
    Context("Testing functionality for extracting formatting information.");
    txt = class'Text'.static.__().text.FromFormattedString("Prepare to"
        @ "{rgb(255,0,0) DIE} and be {rgb(143,200,72) reborn}!");

    Issue("Incorrect formatting information is returned.");
    TEST_ExpectFalse(txt.GetFormatting(0).isColored);
    TEST_ExpectFalse(txt.GetFormatting(17).isColored);
    TEST_ExpectFalse(txt.GetFormatting(28).isColored);
    TEST_ExpectTrue(txt.GetFormatting(11).isColored);
    TEST_ExpectTrue(txt.GetFormatting(11).color.r == 255);
    TEST_ExpectTrue(txt.GetFormatting(11).color.g == 0);
    TEST_ExpectTrue(txt.GetFormatting(11).color.b == 0);
    TEST_ExpectTrue(txt.GetFormatting(26).isColored);
    TEST_ExpectTrue(txt.GetFormatting(26).color.r == 143);
    TEST_ExpectTrue(txt.GetFormatting(26).color.g == 200);
    TEST_ExpectTrue(txt.GetFormatting(26).color.b == 72);
}

protected static function Test_AppendRaw()
{
    local MutableText           someText;
    local array<Text.Character> characters;
    characters[0] = __().text.GetCharacter("c");
    characters[1] = __().text.GetCharacter("a");
    characters[2] = __().text.GetCharacter("t");
    Context("Testing adding \"raw\" characters to `Text` objects.");
    someText = __().text.FromFormattedStringM("simply {$red red}");
    Issue("`AppendRawCharacter()` does not work correctly.");
    someText.AppendRawCharacter(__().text.GetCharacter("A"));
    TEST_ExpectTrue(someText.ToFormattedString()
        ==  "simply {rgb(255,0,0) red}A");
    someText.AppendRawCharacter(
        __().text.GetCharacter("B"),
        __().text.FormattingFromColor(__().color.blue));
    TEST_ExpectTrue(someText.ToFormattedString()
        ==  "simply {rgb(255,0,0) red}A{rgb(0,0,255) B}");

    Issue("`AppendManyRawCharacters()` does not work correctly.");
    someText.AppendManyRawCharacters(characters);
    TEST_ExpectTrue(    someText.ToFormattedString()
        ==  "simply {rgb(255,0,0) red}A{rgb(0,0,255) B}cat");
    someText.AppendManyRawCharacters(
        characters,
        __().text.FormattingFromColor(__().color.black));
    TEST_ExpectTrue(    someText.ToFormattedString()
        ==  "simply {rgb(255,0,0) red}A{rgb(0,0,255) B}cat{rgb(0,0,0) cat}");
}

protected static function Test_Substring()
{
    local Color         testColor;
    local string        defaultTag, colorTag;
    local MutableText   txt;
    Context("Testing functionality of `Text` to extract substrings.");
    testColor = __().color.RGB(198, 23, 7);
    defaultTag = __().color.GetColorTagRGB(1, 1, 1);
    colorTag = __().color.GetColorTag(testColor);
    txt = MutableText(__().memory.Allocate(class'MutableText'));
    txt.AppendFormattedString("Prepare to {rgb(198,23,7) DIE} and"
        @ "be {rgb(0,255,0) reborn}!");
    Issue("Substrings are not extracted as expected.");
    TEST_ExpectTrue(txt.ToString(3, 5) == "pare ");
    TEST_ExpectTrue(txt.ToString(100, 200) == "");
    TEST_ExpectTrue(    txt.ToColoredString(1, 9)
                    ==  (defaultTag $ "repare to"));
    TEST_ExpectTrue(    txt.ToColoredString(9, 3)
                    ==  (defaultTag $ "o " $ colorTag $ "D"));
    TEST_ExpectTrue(    txt.ToColoredString(9, 3, testColor)
                    ==  (colorTag $ "o D"));
    TEST_ExpectTrue(txt.ToFormattedString(, 7) == "Prepare");
    TEST_ExpectTrue(    txt.ToFormattedString(13)
                    ==  "{rgb(198,23,7) E} and be {rgb(0,255,0) reborn}!");
    TEST_ExpectTrue(    txt.ToFormattedString(13, 11)
                    ==  "{rgb(198,23,7) E} and be {rgb(0,255,0) re}");
    TEST_ExpectTrue(    txt.ToFormattedString(-20, 34)
                    ==  "Prepare to {rgb(198,23,7) DIE}");
    TEST_ExpectTrue(    txt.ToString(-2, 100)
                    ==  "Prepare to DIE and be reborn!");
    TEST_ExpectTrue(    txt.ToString(-2, -1)
                    ==  "Prepare to DIE and be reborn!");
}

protected static function Test_AppendGet()
{
    local Color         testColor;
    local string        defaultTag, colorTag, greenTag;
    local Text          part1, part2, part3, part4;
    local MutableText   txt;
    Context("Testing functionality of `MutableText` to append other"
        @ "`Text` instances.");
    Issue("`Append()` incorrectly appends given instances.");
    testColor = __().color.RGB(198, 23, 7);
    defaultTag = __().color.GetColorTagRGB(1, 1, 1);
    colorTag = __().color.GetColorTag(testColor);
    greenTag = __().color.GetColorTagRGB(0, 255, 0);
    txt = MutableText(__().memory.Allocate(class'MutableText'));
    part1 = __().text.FromString("Prepare to ");
    part2 = __().text.FromColoredString(colorTag $ "DIE");
    part3 = class'Text'.static.__().text.FromFormattedString(
        " and be {#00ff00 reborn}!");
    part4 = __().text.FromFormattedString(" Also {rgb(0,255,0) this}.");
    txt.Append(part1).Append(part2).Append(part3).Append(none);
    txt.Append(part4, __().text.FormattingFromColor(testColor));
    TEST_ExpectTrue(    txt.ToString()
                    ==  "Prepare to DIE and be reborn! Also this.");
    TEST_ExpectTrue(    txt.ToColoredString()
                    ==  (   defaultTag $ "Prepare to " $ colorTag $ "DIE"
                        $   defaultTag $ " and be " $ greenTag $ "reborn"
                        $   defaultTag $ "!" $ colorTag $ " Also " $ greenTag
                        $   "this" $ colorTag $ "."));
    TEST_ExpectTrue(    txt.ToFormattedString()
                    ==  ("Prepare to {rgb(198,23,7) DIE} and be {rgb(0,255,0)"
                            @ "reborn}!{rgb(198,23,7)  Also }{rgb(0,255,0)"
                            @ "this}{rgb(198,23,7) .}"));
}

protected static function Test_AppendStringGet()
{
    local Color         testColor;
    local string        defaultTag, colorTag, greenTag, limeTag;
    local MutableText   txt;
    Context("Testing functionality of `MutableText` to append strings.");
    txt = MutableText(__().memory.Allocate(class'MutableText'));
    Issue("New `Text` returns non-empty string as a result.");
    TEST_ExpectTrue(txt.ToString() == "");
    TEST_ExpectTrue(txt.ToColoredString() == "");

    Issue("Appended strings are not returned as expected.");
    testColor = __().color.RGB(198, 23, 7);
    defaultTag = __().color.GetColorTagRGB(1, 1, 1);
    colorTag = __().color.GetColorTag(testColor);
    greenTag = __().color.GetColorTagRGB(0, 255, 0);
    limeTag = __().color.GetColorTagRGB(50, 205, 50);
    txt.AppendString("Prepare to ");
    txt.AppendColoredString(colorTag $ "DIE");
    txt.AppendFormattedString(" ^gand {$LimeGreen be }");
    txt.AppendFormatted(P("r{#00ff00 eborn}!"));
    TEST_ExpectTrue(    txt.ToString()
                    ==  "Prepare to DIE and be reborn!");
    TEST_ExpectTrue(    txt.ToColoredString()
                    ==  (   defaultTag $ "Prepare to " $ colorTag $ "DIE"
                        $   defaultTag $ " " $ greenTag $ "and "
                        $   limeTag $ "be " $ defaultTag $ "r"
                        $   greenTag $ "eborn" $   defaultTag $ "!"));
    TEST_ExpectTrue(    txt.ToFormattedString()
                    ==  ("Prepare to {rgb(198,23,7) DIE} {rgb(0,255,0) and }"
                            $ "{rgb(50,205,50) be }r{rgb(0,255,0) eborn}!"));
}

protected static function Test_SeparateByCharacter()
{
    Context("Testing functionality of `Text` to be split by given character.");
    SubTest_SeparateByCharacterInvalid();
    SubTest_SeparateByCharacterAll();
    SubTest_SeparateByCharacterSkip();
    SubTest_SeparateByCharacterSAll();
    SubTest_SeparateByCharacterSSkip();
    SubTest_SeparateByCharacterMutability();
}

protected static function SubTest_SeparateByCharacterInvalid()
{
    local Text              testText;
    local array<BaseText>   result;
    testText = __().text.FromFormattedString("/{#ff0000 usr//{#0000ff bin}}/"
        $ "{#00ff00 stu}ff");

    Issue("`SplitByCharacter()` doesn't return empty array when invalid"
        @ "character is passed as argument.");
    result = testText.SplitByCharacter(__().text.GetInvalidCharacter());
    TEST_ExpectTrue(result.length == 0);

    Issue("`SplitByCharacterS()` doesn't return empty array when empty"
        @ "`string` is passed as argument.");
    result = testText.SplitByCharacterS("");
    TEST_ExpectTrue(result.length == 0);
}

protected static function SubTest_SeparateByCharacterAll()
{
    local Text              testText;
    local array<BaseText>   slashResult, fResult;
    testText = __().text.FromFormattedString("/{#ff0000 usr//{#0000ff bin}}/"
        $ "{#00ff00 stu}ff");
    slashResult = testText.SplitByCharacter(__().text.GetCharacter("/"));
    fResult = testText.SplitByCharacter(__().text.GetCharacter("f"));

    Issue("Returned `MutableText`s have incorrect text content.");
    TEST_ExpectTrue(slashResult.length == 5);
    TEST_ExpectTrue(slashResult[0].CompareToString(""));
    TEST_ExpectTrue(slashResult[1].CompareToString("usr"));
    TEST_ExpectTrue(slashResult[2].CompareToString(""));
    TEST_ExpectTrue(slashResult[3].CompareToString("bin"));
    TEST_ExpectTrue(slashResult[4].CompareToString("stuff"));
    TEST_ExpectTrue(fResult.length == 3);
    TEST_ExpectTrue(fResult[0].CompareToString("/usr//bin/stu"));
    TEST_ExpectTrue(fResult[1].CompareToString(""));
    TEST_ExpectTrue(fResult[2].CompareToString(""));

    Issue("Returned `MutableText`s have incorrect formatting.");
    TEST_ExpectTrue(slashResult[1].CompareToFormattedString("{#ff0000 usr}"));
    TEST_ExpectTrue(slashResult[3].CompareToFormattedString("{#0000ff bin}"));
    TEST_ExpectTrue(slashResult[4].CompareToFormattedString("{#00ff00 stu}ff"));
    TEST_ExpectTrue(fResult[0].CompareToFormattedString(
        "/{#ff0000 usr//{#0000ff bin}}/{#00ff00 stu}"));
}

protected static function SubTest_SeparateByCharacterSkip()
{
    local Text              testText;
    local array<BaseText>   slashResult, fResult;
    testText = __().text.FromFormattedString("/{#ff0000 usr//{#0000ff bin}}/"
        $ "{#00ff00 stu}ff");
    slashResult = testText.SplitByCharacter(__().text.GetCharacter("/"), true);
    fResult = testText.SplitByCharacter(__().text.GetCharacter("f"), true);

    Issue("Returned `MutableText`s (with empty ones skipped) have incorrect"
        @ "text content.");
    TEST_ExpectTrue(slashResult.length == 3);
    TEST_ExpectTrue(slashResult[0].CompareToString("usr"));
    TEST_ExpectTrue(slashResult[1].CompareToString("bin"));
    TEST_ExpectTrue(slashResult[2].CompareToString("stuff"));
    TEST_ExpectTrue(fResult.length == 1);
    TEST_ExpectTrue(fResult[0].CompareToString("/usr//bin/stu"));

    Issue("Returned `MutableText`s (with empty ones skipped) have"
        @ "incorrect formatting.");
    TEST_ExpectTrue(slashResult[0].CompareToFormattedString("{#ff0000 usr}"));
    TEST_ExpectTrue(slashResult[1].CompareToFormattedString("{#0000ff bin}"));
    TEST_ExpectTrue(slashResult[2].CompareToFormattedString("{#00ff00 stu}ff"));
    TEST_ExpectTrue(fResult[0].CompareToFormattedString(
        "/{#ff0000 usr//{#0000ff bin}}/{#00ff00 stu}"));
}

protected static function SubTest_SeparateByCharacterSAll()
{
    local Text              testText;
    local array<BaseText>   slashResult, fResult;
    testText = __().text.FromFormattedString("/{#ff0000 usr//{#0000ff bin}}/"
        $ "{#00ff00 stu}ff");
    slashResult = testText.SplitByCharacterS("/");
    fResult = testText.SplitByCharacterS("fuck");

    Issue("Returned `MutableText`s have incorrect text content.");
    TEST_ExpectTrue(slashResult.length == 5);
    TEST_ExpectTrue(slashResult[0].CompareToString(""));
    TEST_ExpectTrue(slashResult[1].CompareToString("usr"));
    TEST_ExpectTrue(slashResult[2].CompareToString(""));
    TEST_ExpectTrue(slashResult[3].CompareToString("bin"));
    TEST_ExpectTrue(slashResult[4].CompareToString("stuff"));
    TEST_ExpectTrue(fResult.length == 3);
    TEST_ExpectTrue(fResult[0].CompareToString("/usr//bin/stu"));
    TEST_ExpectTrue(fResult[1].CompareToString(""));
    TEST_ExpectTrue(fResult[2].CompareToString(""));

    Issue("Returned `MutableText`s have incorrect formatting.");
    TEST_ExpectTrue(slashResult[1].CompareToFormattedString("{#ff0000 usr}"));
    TEST_ExpectTrue(slashResult[3].CompareToFormattedString("{#0000ff bin}"));
    TEST_ExpectTrue(slashResult[4].CompareToFormattedString("{#00ff00 stu}ff"));
    TEST_ExpectTrue(fResult[0].CompareToFormattedString(
        "/{#ff0000 usr//{#0000ff bin}}/{#00ff00 stu}"));
}

protected static function SubTest_SeparateByCharacterSSkip()
{
    local Text              testText;
    local array<BaseText>   slashResult, fResult;
    testText = __().text.FromFormattedString("/{#ff0000 usr//{#0000ff bin}}/"
        $ "{#00ff00 stu}ff");
    slashResult = testText.SplitByCharacterS("/home/user/", true);
    fResult = testText.SplitByCharacterS("f", true);

    Issue("Returned `MutableText`s (with empty ones skipped) have incorrect"
        @ "text content.");
    TEST_ExpectTrue(slashResult.length == 3);
    TEST_ExpectTrue(slashResult[0].CompareToString("usr"));
    TEST_ExpectTrue(slashResult[1].CompareToString("bin"));
    TEST_ExpectTrue(slashResult[2].CompareToString("stuff"));
    TEST_ExpectTrue(fResult.length == 1);
    TEST_ExpectTrue(fResult[0].CompareToString("/usr//bin/stu"));

    Issue("Returned `MutableText`s (with empty ones skipped) have"
        @ "incorrect formatting.");
    TEST_ExpectTrue(slashResult[0].CompareToFormattedString("{#ff0000 usr}"));
    TEST_ExpectTrue(slashResult[1].CompareToFormattedString("{#0000ff bin}"));
    TEST_ExpectTrue(slashResult[2].CompareToFormattedString("{#00ff00 stu}ff"));
    TEST_ExpectTrue(fResult[0].CompareToFormattedString(
        "/{#ff0000 usr//{#0000ff bin}}/{#00ff00 stu}"));
}

protected static function SubTest_SeparateByCharacterMutability()
{
    local Text              testText;
    local array<BaseText>   slashResult, fResult;
    testText = __().text.FromFormattedString("/{#ff0000 usr//{#0000ff bin}}/"
        $ "{#00ff00 stu}ff");

    Issue("When picking immutable return value, method does not return `Text`");
    slashResult = testText.SplitByCharacter(__().text.GetCharacter("/"));
    fResult = testText.SplitByCharacterS("fuck");
    TEST_ExpectTrue(slashResult[0].class == class'Text');
    TEST_ExpectTrue(slashResult[1].class == class'Text');
    TEST_ExpectTrue(slashResult[2].class == class'Text');
    TEST_ExpectTrue(slashResult[3].class == class'Text');
    TEST_ExpectTrue(slashResult[4].class == class'Text');
    TEST_ExpectTrue(fResult[0].class == class'Text');
    TEST_ExpectTrue(fResult[1].class == class'Text');
    TEST_ExpectTrue(fResult[2].class == class'Text');

    Issue("When picking immutable return value, method does not return"
        @ "`MutableText`");
    slashResult = testText.SplitByCharacter(__().text.GetCharacter("/"),, true);
    fResult = testText.SplitByCharacterS("fuck",, true);
    TEST_ExpectTrue(slashResult[0].class == class'MutableText');
    TEST_ExpectTrue(slashResult[1].class == class'MutableText');
    TEST_ExpectTrue(slashResult[2].class == class'MutableText');
    TEST_ExpectTrue(slashResult[3].class == class'MutableText');
    TEST_ExpectTrue(slashResult[4].class == class'MutableText');
    TEST_ExpectTrue(fResult[0].class == class'MutableText');
    TEST_ExpectTrue(fResult[1].class == class'MutableText');
    TEST_ExpectTrue(fResult[2].class == class'MutableText');
}

protected static function Test_StartsEndsWith()
{
    SubTest_StartsWith(SFORM_SENSITIVE);
    SubTest_StartsWith(SFORM_INSENSITIVE);
    SubTest_StartsWith_Formatting();
    SubTest_EndsWith(SFORM_SENSITIVE);
    SubTest_EndsWith(SFORM_INSENSITIVE);
    SubTest_EndsWith_Formatting();
}

protected static function SubTest_StartsWith(BaseText.FormatSensitivity flag)
{
    Context("Testing `StartsWith()` method.");
    Issue("`StartsWith()` works incorrectly with empty `Text`s.");
    TEST_ExpectTrue(P("").StartsWith(F("{rgb(4,5,6) }"),, flag));
    TEST_ExpectTrue(P("something").StartsWith(P(""),, flag));
    TEST_ExpectFalse(F("{rgb(23,342,32) }").StartsWith(P("something"),, flag));

    Issue("`StartsWith()` returns `true` for longer `Text`s.");
    TEST_ExpectFalse(P("text").StartsWith(P("image"), SCASE_INSENSITIVE, flag));
    TEST_ExpectFalse(P("text").StartsWith(P("text+"),, flag));

    Issue("`StartsWith()` returns `false` for identical `Text`s.");
    TEST_ExpectTrue(P("Just something").StartsWith(P("Just something")));
    TEST_ExpectTrue(P("CraZy").StartsWith(P("CRaZy"), SCASE_INSENSITIVE, flag));

    Issue("`StartsWith()` returns `false` for correct prefixes.");
    TEST_ExpectTrue(P("Just something").StartsWith(P("Just so"),, flag));
    TEST_ExpectTrue(P("CraZy").StartsWith(P("Cra"),, flag));

    Issue("`StartsWith()` returns `false` for correct"
        @ "case-insensitive prefixes.");
    TEST_ExpectTrue(P("Just something").
        StartsWith(P("jUSt sO"), SCASE_INSENSITIVE, flag));
    TEST_ExpectTrue(P("CraZy").StartsWith(P("CRA"), SCASE_INSENSITIVE, flag));
}

protected static function SubTest_StartsWith_Formatting()
{
    Context("Testing how `StartsWith()` method deals with formatting.");
    Issue("`StartsWith()` returns `false` for identical `Text`s.");
    TEST_ExpectTrue(F("Just {#4fe2ac some}thing")
        .StartsWith(F("Just {#4fe2ac some}thing"),, SFORM_SENSITIVE));
    TEST_ExpectTrue(F("Cra{#ff0000 Zy}")
        .StartsWith(F("Cra{#ff0000 Zy}"),, SFORM_SENSITIVE));

    Issue("`StartsWith()` in formatting-sensitive mode returns `true` for"
        @ "`Text`s that differ only in formatting.");
    TEST_ExpectFalse(F("Just {#4f632dc some}thing")
        .StartsWith(F("Just {#4fe2ac some}thing"),, SFORM_SENSITIVE));
    TEST_ExpectFalse(F("Cr{#ff0000 aZy}")
        .StartsWith(F("Cra{#ff0000 Zy}"),, SFORM_SENSITIVE));

    Issue("`StartsWith()` in formatting-insensitive mode returns `false` for"
        @ "`Text`s that differ only in formatting.");
    TEST_ExpectTrue(F("Just {#4f632dc some}thing")
        .StartsWith(F("Just {#4fe2ac some}thing"),, SFORM_INSENSITIVE));
    TEST_ExpectTrue(F("Cr{#ff0000 aZy}")
        .StartsWith(F("Cra{#ff0000 Zy}"),, SFORM_INSENSITIVE));

    Issue("`StartsWith()` returns `false` for correct prefixes.");
    TEST_ExpectTrue(F("{#00ff00 Just {#f00000 some}thing}")
        .StartsWith(F("{#00ff00 Just }{#f00000 so}"),, SFORM_SENSITIVE));
    TEST_ExpectTrue(F("{#454545 Cr}aZy")
        .StartsWith(F("{#454545 C}"),, SFORM_SENSITIVE));
}

protected static function SubTest_EndsWith(BaseText.FormatSensitivity flag)
{
    Context("Testing `EndsWith()` method.");
    Issue("`EndsWith()` works incorrectly with empty `Text`s.");
    TEST_ExpectTrue(P("").EndsWith(F("{rgb(4,5,6) }"),, flag));
    TEST_ExpectTrue(P("something").EndsWith(P(""),, flag));
    TEST_ExpectFalse(F("{rgb(23,342,32) }").EndsWith(P("something"),, flag));

    Issue("`EndsWith()` returns `true` for longer `Text`s.");
    TEST_ExpectFalse(P("text").EndsWith(P("image"), SCASE_INSENSITIVE, flag));
    TEST_ExpectFalse(P("text").EndsWith(P("+text"),, flag));

    Issue("`EndsWith()` returns `false` for identical `Text`s.");
    TEST_ExpectTrue(P("Just something").EndsWith(P("Just something"),, flag));
    TEST_ExpectTrue(P("CraZy").EndsWith(P("CRaZy"), SCASE_INSENSITIVE, flag));

    Issue("`EndsWith()` returns `false` for correct suffixes.");
    TEST_ExpectTrue(P("Just something").EndsWith(P("thing"),, flag));
    TEST_ExpectTrue(P("CraZy").EndsWith(P("aZy"),, flag));

    Issue("`EndsWith()` returns `false` for correct"
        @ "case-insensitive prefixes.");
    TEST_ExpectTrue(P("Just something").
        EndsWith(P("eTHiNG"), SCASE_INSENSITIVE, flag));
    TEST_ExpectTrue(P("CraZy").EndsWith(P("zy"), SCASE_INSENSITIVE, flag));
}

protected static function SubTest_EndsWith_Formatting()
{
    Context("Testing how `EndsWith()` method deals with formatting.");
    Issue("`EndsWith()` returns `false` for identical `Text`s.");
    TEST_ExpectTrue(F("Just {#4fe2ac some}thing")
        .EndsWith(F("Just {#4fe2ac some}thing"),, SFORM_SENSITIVE));
    TEST_ExpectTrue(F("Cra{#ff0000 Zy}")
        .EndsWith(F("Cra{#ff0000 Zy}"),, SFORM_SENSITIVE));

    Issue("`EndsWith()` in formatting-sensitive mode returns `true` for"
        @ "`Text`s that differ only in formatting.");
    TEST_ExpectFalse(F("Just {#4f632dc some}thing")
        .EndsWith(F("Just {#4fe2ac some}thing"),, SFORM_SENSITIVE));
    TEST_ExpectFalse(F("Cr{#ff0000 aZy}")
        .EndsWith(F("Cra{#ff0000 Zy}"),, SFORM_SENSITIVE));

    Issue("`EndsWith()` in formatting-insensitive mode returns `false` for"
        @ "`Text`s that differ only in formatting.");
    TEST_ExpectTrue(F("Just {#4f632dc some}thing")
        .EndsWith(F("Just {#4fe2ac some}thing"),, SFORM_INSENSITIVE));
    TEST_ExpectTrue(F("Cr{#ff0000 aZy}")
        .EndsWith(F("Cra{#ff0000 Zy}"),, SFORM_INSENSITIVE));

    Issue("`EndsWith()` returns `false` for correct prefixes.");
    TEST_ExpectTrue(F("{#00ff00 Just {#f00000 some}thing}")
        .EndsWith(F("{#f00000 ome}{#00ff00 thing}"),, SFORM_SENSITIVE));
    TEST_ExpectTrue(F("{#454545 Cr}aZy")
        .EndsWith(F("{#454545 r}aZy"),, SFORM_SENSITIVE));
}

protected static function Test_IndexOf()
{
    Context("Testing `IndexOf()` method with non-formatted `Text`s.");
    SubTest_IndexOfSuccess(SFORM_SENSITIVE);
    SubTest_IndexOfSuccess(SFORM_INSENSITIVE);
    SubTest_IndexOfFail(SFORM_SENSITIVE);
    SubTest_IndexOfFail(SFORM_INSENSITIVE);
    Context("Testing `IndexOf()` method with formatted `Text`s.");
    SubTest_IndexOfFormatting();
    Context("Testing `LastIndexOf()` method with non-formatted `Text`s.");
    SubTest_LastIndexOfSuccess(SFORM_SENSITIVE);
    SubTest_LastIndexOfSuccess(SFORM_INSENSITIVE);
    SubTest_LastIndexOfFail(SFORM_SENSITIVE);
    SubTest_LastIndexOfFail(SFORM_INSENSITIVE);
    Context("Testing `LastIndexOf()` method with formatted `Text`s.");
    SubTest_LastIndexOfFormatting();
}

protected static function SubTest_IndexOfSuccess(
    BaseText.FormatSensitivity flag)
{
    Issue("`IndexOf()` works incorrectly with empty `Text`s.");
    TEST_ExpectTrue(P("").IndexOf(F("{rgb(4,5,6) }"),,, flag) == 0);
    TEST_ExpectTrue(P("something").IndexOf(P(""),,, flag) == 0);
    TEST_ExpectFalse(
        F("{rgb(23,342,32) }").IndexOf(P("something"),,, flag) == 0);

    Issue("`IndexOf()` returns non-zero index for identical `Text`s.");
    TEST_ExpectTrue(P("Just something").IndexOf(P("Just something")) == 0);
    TEST_ExpectTrue(
        P("CraZy").IndexOf(P("CRaZy"),, SCASE_INSENSITIVE, flag) == 0);

    Issue("`IndexOf()` returns wrong index for correct sub-`Text`s.");
    TEST_ExpectTrue(P("Just something").IndexOf(P("some"),,, flag) == 5);
    TEST_ExpectTrue(P("Just something").IndexOf(P("some"), 3,, flag) == 5);
    TEST_ExpectTrue(P("Just something").IndexOf(P("some"), 5,, flag) == 5);
    TEST_ExpectTrue(
        P("Just some-something").IndexOf(P("some"), 7,, flag) == 10);

    Issue("`IndexOf()` returns wrong index for correct case-insensitive" @
        "sub-`Text`s.");
    TEST_ExpectTrue(P("JUSt sOmEtHiNG")
            .IndexOf(P("sOME"),, SCASE_INSENSITIVE, flag)
        ==  5);
    TEST_ExpectTrue(P("JUSt sOmEtHiNG")
            .IndexOf(P("SoMe"), 3, SCASE_INSENSITIVE, flag)
        ==  5);
    TEST_ExpectTrue(P("JUSt sOmEtHiNG")
            .IndexOf(P("sOMe"), 5, SCASE_INSENSITIVE, flag)
        ==  5);
    TEST_ExpectTrue(P("JUSt soME-sOmEtHiNG")
            .IndexOf(P("SomE"), 7, SCASE_INSENSITIVE, flag)
        ==  10);
}

protected static function SubTest_IndexOfFail(BaseText.FormatSensitivity flag)
{
    Issue("`IndexOf()` returns non-negative index for longer `Text`s.");
    TEST_ExpectTrue(
        P("text").IndexOf(P("image"),, SCASE_INSENSITIVE, flag) < 0);
    TEST_ExpectTrue(P("++text").IndexOf(P("text+"), 2,, flag) < 0);

    Issue("`IndexOf()` returns non-negative index when looking for `Text`s that"
        @ "are not a substring.");
    TEST_ExpectTrue(P("text").IndexOf(P("exd"),, SCASE_INSENSITIVE, flag) < 0);
    TEST_ExpectTrue(P("A string").IndexOf(P("  string"),,, flag) < 0);
    TEST_ExpectTrue(P("A string").IndexOf(P("  string"),,, flag) < 0);
    TEST_ExpectTrue(P("A string").IndexOf(P("str"), 3,, flag) < 0);
    TEST_ExpectTrue(P("A string").IndexOf(P("str"), 20,, flag) < 0);
}

protected static function SubTest_IndexOfFormatting()
{
    Issue("`IndexOf()` returns non-zero index for identical `Text`s.");
    TEST_ExpectTrue(F("Just {#4fe2ac some}thing")
            .IndexOf(F("Just {#4fe2ac some}thing"),,, SFORM_SENSITIVE)
        ==  0);
    TEST_ExpectTrue(F("Cra{#ff0000 Zy}")
            .IndexOf(F("Cra{#ff0000 Zy}"),,, SFORM_SENSITIVE)
        ==  0);

    Issue("`IndexOf()` returns wrong index for correct sub-`Text`s.");
    TEST_ExpectTrue(F("Just so{#4f632dc me-some}thing")
            .IndexOf(F("so{#4f632dc me}"),,, SFORM_SENSITIVE)
        ==  5);
    TEST_ExpectTrue(F("Just so{#4f632dc me-some}thing")
            .IndexOf(F("so{#4f632dc me}"), 3,, SFORM_SENSITIVE)
        ==  5);
    TEST_ExpectTrue(F("Just so{#4f632dc me-some}thing")
            .IndexOf(F("so{#4f632dc me}"), 5,, SFORM_SENSITIVE)
        ==  5);
    TEST_ExpectTrue(F("Just so{#4f632dc me-some}thing")
            .IndexOf(F("{#4f632dc some}"),,, SFORM_SENSITIVE)
        ==  10);
    TEST_ExpectTrue(F("Just so{#4f632dc me-some}thing")
            .IndexOf(F("{#4f632dc some}"), 7,, SFORM_SENSITIVE)
        ==  10);
}

protected static function SubTest_LastIndexOfSuccess(
    BaseText.FormatSensitivity flag)
{
    Issue("`LastIndexOf()` works incorrectly with empty `Text`s.");
    TEST_ExpectTrue(P("").LastIndexOf(F("{rgb(4,5,6) }"),,, flag) == 0);
    TEST_ExpectTrue(P("something").LastIndexOf(P(""),,, flag) == 0);
    TEST_ExpectFalse(
        F("{rgb(23,342,32) }").LastIndexOf(P("something"),,, flag) == 0);

    Issue("`LastIndexOf()` returns non-zero index for identical `Text`s.");
    TEST_ExpectTrue(P("Just something").LastIndexOf(P("Just something")) == 0);
    TEST_ExpectTrue(
        P("CraZy").LastIndexOf(P("CRaZy"),, SCASE_INSENSITIVE, flag) == 0);

    Issue("`LastIndexOf()` returns wrong index for correct sub-`Text`s.");
    TEST_ExpectTrue(P("Just something").LastIndexOf(P("some"),,, flag) == 5);
    TEST_ExpectTrue(P("Just something").LastIndexOf(P("some"), 3,, flag) == 5);
    TEST_ExpectTrue(P("Just something").LastIndexOf(P("some"), 5,, flag) == 5);
    TEST_ExpectTrue(
        P("Just some-something").LastIndexOf(P("some"),,, flag) == 10);
    TEST_ExpectTrue(
        P("Just some-something").LastIndexOf(P("some"), 6,, flag) == 5);

    Issue("`LastIndexOf()` returns wrong index for correct case-insensitive" @
        "sub-`Text`s.");
    TEST_ExpectTrue(P("JUSt sOmEtHiNG")
            .LastIndexOf(P("sOME"),, SCASE_INSENSITIVE, flag)
        ==  5);
    TEST_ExpectTrue(P("JUSt sOmEtHiNG")
            .LastIndexOf(P("SoMe"), 3, SCASE_INSENSITIVE, flag)
        ==  5);
    TEST_ExpectTrue(P("JUSt soME-sOmEtHiNG")
            .LastIndexOf(P("sOMe"), 5, SCASE_INSENSITIVE, flag)
        ==  10);
    TEST_ExpectTrue(P("JUSt soME-sOmEtHiNG")
            .LastIndexOf(P("SomE"), 6, SCASE_INSENSITIVE, flag)
        ==  5);
}

protected static function SubTest_LastIndexOfFail(
    BaseText.FormatSensitivity flag)
{
    Issue("`LastIndexOf()` returns non-negative index for longer `Text`s.");
    TEST_ExpectTrue(
        P("text").LastIndexOf(P("image"),, SCASE_INSENSITIVE, flag) < 0);
    TEST_ExpectTrue(P("++text").LastIndexOf(P("text+"), 2,, flag) < 0);

    Issue("`LastIndexOf()` returns non-negative index when looking for `Text`s that"
        @ "are not a substring.");
    TEST_ExpectTrue(
        P("text").LastIndexOf(P("exd"),, SCASE_INSENSITIVE, flag) < 0);
    TEST_ExpectTrue(P("A string").LastIndexOf(P("  string"),,, flag) < 0);
    TEST_ExpectTrue(P("A string").LastIndexOf(P("  string"),,, flag) < 0);
    TEST_ExpectTrue(P("A string").LastIndexOf(P("str"), 4,, flag) < 0);
    TEST_ExpectTrue(P("A string").LastIndexOf(P("str"), 20,, flag) < 0);
}

protected static function SubTest_LastIndexOfFormatting()
{
    Issue("`LastIndexOf()` returns non-zero index for identical `Text`s.");
    TEST_ExpectTrue(F("Just {#4fe2ac some}thing")
            .LastIndexOf(F("Just {#4fe2ac some}thing"),,, SFORM_SENSITIVE)
        ==  0);
    TEST_ExpectTrue(F("Cra{#ff0000 Zy}")
            .LastIndexOf(F("Cra{#ff0000 Zy}"),,, SFORM_SENSITIVE)
        ==  0);

    Issue("`LastIndexOf()` returns wrong index for correct sub-`Text`s.");
    TEST_ExpectTrue(F("Just so{#4f632dc me-some}thing")
            .LastIndexOf(F("{#4f632dc some}"),,, SFORM_SENSITIVE)
        ==  10);
    TEST_ExpectTrue(F("Just so{#4f632dc me-some}thing")
            .LastIndexOf(F("{#4f632dc some}"), 3,, SFORM_SENSITIVE)
        ==  10);
    TEST_ExpectTrue(F("Just so{#4f632dc me-some}thing")
            .LastIndexOf(F("{#4f632dc some}"), 5,, SFORM_SENSITIVE)
        ==  10);
    TEST_ExpectTrue(F("Just so{#4f632dc me-some}thing")
            .LastIndexOf(F("so{#4f632dc me}"),,, SFORM_SENSITIVE)
        ==  5);
    TEST_ExpectTrue(F("Just so{#4f632dc me-some}thing")
            .LastIndexOf(F("so{#4f632dc me}"), 7,, SFORM_SENSITIVE)
        ==  5);
}

protected static function Test_Replace()
{
    Context("Testing `Replace()` method with non-formatted `MutableText`s.");
    SubTest_ReplaceEdgeCases(SFORM_SENSITIVE);
    SubTest_ReplaceEdgeCases(SFORM_INSENSITIVE);
    SubTest_ReplaceMainCases(SFORM_SENSITIVE);
    SubTest_ReplaceMainCases(SFORM_INSENSITIVE);
    Context("Testing `Replace()` method with formatted `MutableText`s.");
    SubTest_ReplaceEmptyFormatting();
    SubTest_ReplaceFullFormatting();
    SubTest_ReplacePartFormatting();
}

protected static function SubTest_ReplaceEdgeCases(
    BaseText.FormatSensitivity flag)
{
    local MutableText builder;
    builder = __().text.Empty();
    Issue("`Replace()` works incorrectly when replacing empty `Text`s.");
    TEST_ExpectTrue(builder.Replace(P(""), P(""),, flag).ToString() == "");
    TEST_ExpectTrue(
        builder.Replace(P(""), P("huh"),, flag).ToString() == "");
    builder.AppendString("word");
    TEST_ExpectTrue(
        builder.Replace(P(""), P(""),, flag).ToString() == "word");
    TEST_ExpectTrue(
        builder.Replace(P(""), P("huh"),, flag).ToString() == "word");

    Issue("`Replace()` works incorrectly when replacing something inside"
        @ "an empty `Text`s.");
    builder.Clear();
    TEST_ExpectTrue(
        builder.Replace(P("huh"), P(""),, flag).ToString() == "");

    Issue("`Replace()` cannot replace whole `Text`s.");
    TEST_ExpectTrue(builder.Clear()
            .AppendFormattedString("Just {#54af4c something}")
            .Replace(F("Just {#54af4c something}"), P("Nothing really"),, flag)
            .ToString()
        ==  "Nothing really");
    TEST_ExpectTrue(builder.Clear().AppendString("CraZy")
            .Replace(P("CRaZy"), P("calm"), SCASE_INSENSITIVE, flag)
            .ToString()
        ==  "calm");
}

protected static function SubTest_ReplaceMainCases(
    BaseText.FormatSensitivity flag)
{
    local MutableText builder;
    builder = __().text.FromStringM("Mate eight said");
    Issue("`Replace()` works incorrectly changes `Text` when replacing"
        @ "non-existent sub-`Text`.");
    TEST_ExpectTrue(builder.Replace(P("word"), P("another"),, flag)
            .ToString()
        ==  "Mate eight said");
    TEST_ExpectTrue(builder
            .Replace(P("word"), P("another"), SCASE_INSENSITIVE, flag)
            .ToString()
        ==  "Mate eight said");

    Issue("`Replace()` replaces sub-`Text` incorrectly.");
    builder.Clear().AppendString("Do it bay bee");
    TEST_ExpectTrue(builder.Replace(P("it"), P("this"),, flag).ToString()
        ==  "Do this bay bee");
    builder.Clear().AppendString("dO It bAy BEe");
    TEST_ExpectTrue(
            builder.Replace(P("it"), P("tHis"), SCASE_INSENSITIVE, flag)
            .ToString()
        ==  "dO tHis bAy BEe");

    Issue("`Replace()` replaces sub-`Text` incorrectly.");
    builder.Clear().AppendString("he and she and it");
    TEST_ExpectTrue(builder.Replace(P("and"), P("OR"),, flag)
            .ToString()
        ==  "he OR she OR it");
    builder.Clear().AppendFormattedString("{#54af4c HE} aNd sHe aND iT");
    TEST_ExpectTrue(builder.Replace(P("AND"), P("Or"), SCASE_INSENSITIVE, flag)
            .ToString()
        ==  "HE Or sHe Or iT");
}

protected static function SubTest_ReplaceEmptyFormatting()
{
    local MutableText builder;
    builder = __().text.Empty();
    Issue("`Replace()` works incorrectly when replacing empty `MutableText`s.");
    TEST_ExpectTrue(builder
        .Replace(F("{rgb(4,5,6) }"), F("{rgb(76,52,161) }"),, SFORM_SENSITIVE)
        .IsEmpty());
    TEST_ExpectTrue(
        builder.Replace(F("{rgb(76,52,161) }"), F("huh"),, SFORM_SENSITIVE)
        .IsEmpty());
    builder.AppendFormattedString("{rgb(76,52,161) wo}rd");
    TEST_ExpectTrue(builder
        .Replace(F("{rgb(4,5,6) }"), F("{rgb(76,52,161) }"),, SFORM_SENSITIVE)
        .ToFormattedString() ==  "{rgb(76,52,161) wo}rd");
    TEST_ExpectTrue(builder
        .Replace(F("{rgb(76,52,161) }"), F("huh"),, SFORM_SENSITIVE)
        .ToFormattedString() ==  "{rgb(76,52,161) wo}rd");
}

protected static function SubTest_ReplaceFullFormatting()
{
    local Text          other;
    local MutableText   builder;
    builder = __().text.Empty();
    Issue("`Replace()` cannot replace whole `MutableText`s.");
    builder.AppendFormattedString("{rgb(76,52,161) One}, {rgb(4,5,6) two}!");
    other = F("{rgb(76,52,161) One}, {rgb(4,5,6) two}!");
    TEST_ExpectTrue(builder
            .Replace(other, F("Nothing {rgb(25,0,0) really}"),, SFORM_SENSITIVE)
            .ToFormattedString()
        ==  "Nothing {rgb(25,0,0) really}");
    builder.Clear().AppendFormattedString("{rgb(76,52,161) CraZy}");
    other = __().text.FromFormattedString("{rgb(76,52,161) CraZy}");
    TEST_ExpectTrue(builder.Replace(other, F("c{rgb(25,0,0) a}lm"),
                                    SCASE_INSENSITIVE, SFORM_SENSITIVE)
                    .ToFormattedString() ==  "c{rgb(25,0,0) a}lm");

    Issue("`Replace()` incorrectly replaces whole `MutableText`s by matching"
        @ "with a `Text` with different formatting.");
    builder.Clear();
    builder.AppendFormattedString("{rgb(76,52,161) One}, {rgb(4,5,6) two}!");
    other = F("{rgb(76,52,161) One}, {rgb(5,5,6) two}!");
    TEST_ExpectTrue(builder
            .Replace(other, F("Nothing {rgb(25,0,0) really}"),, SFORM_SENSITIVE)
            .ToFormattedString()
        ==  "{rgb(76,52,161) One}, {rgb(4,5,6) two}!");
}

protected static function SubTest_ReplacePartFormatting()
{
    local string        normalCase, randomCase, complexCase;
    local Text          other;
    local MutableText   builder;
    builder = __().text.Empty();
    normalCase = "He {rgb(76,52,161) and} she {rgb(204,5,6) and} it!";
    randomCase = "hE {rgb(76,52,161) aNd} SHE {rgb(76,52,161) ANd} IT!";
    complexCase =
        "{rgb(76,52,161) Aba}B{rgb(76,52,161) bb{rgb(76,52,160) aB}b}a";
    Issue("`Replace()` incorrectly replaces parts of `MutableText`s.");
    builder.Clear();
    builder.AppendFormattedString(normalCase);
    other = F("{rgb(204,5,6) and}");
    TEST_ExpectTrue(builder
            .Replace(other, F("{rgb(25,0,0) ???}"),, SFORM_SENSITIVE)
            .ToFormattedString()
        ==  "He {rgb(76,52,161) and} she {rgb(25,0,0) ???} it!");
    builder.Clear().AppendFormattedString(randomCase);
    other = F("{rgb(76,52,161) and}");
    TEST_ExpectTrue(builder.Replace(other, F("c{rgb(25,0,0) o}r"),
                                    SCASE_INSENSITIVE, SFORM_SENSITIVE)
            .ToFormattedString()
        ==  "hE c{rgb(25,0,0) o}r SHE c{rgb(25,0,0) o}r IT!");

    builder.Clear();
    builder.AppendFormattedString(complexCase);
    other = F("{rgb(76,52,161) B}");
    TEST_ExpectTrue(builder
            .Replace(   other, F("{rgb(4,4,4) cc}"),
                        SCASE_INSENSITIVE, SFORM_SENSITIVE)
            .ToFormattedString()
        ==  ("{rgb(76,52,161) A}{rgb(4,4,4) cc}{rgb(76,52,161) a}B"
            $ "{rgb(4,4,4) cccc}{rgb(76,52,160) aB}{rgb(4,4,4) cc}a"));
}

protected static function Test_ChangeFormatting()
{
    Context("Testing `DefaultChangeFormatting()` method.");
    SubTest_ChangeDefaultFormatting();
    Context("Testing `ChangeFormatting()` method.");
    SubTest_ChangeFormattingRegular();
    SubTest_ChangeFormattingEdgeCases();
}

protected static function SubTest_ChangeDefaultFormatting()
{
    local Text                  template;
    local MutableText           testText;
    local BaseText.Formatting   defaultFormatting;
    local BaseText.Formatting   blueFormatting, greenFormatting;
    template = __().text.FromFormattedString(
        "Normal part, {rgb(255,0,0) red part}, {rgb(0,255,0) green part}!!!");
    blueFormatting  = __().text.FormattingFromColor(__().color.Blue);
    greenFormatting = __().text.FormattingFromColor(__().color.Lime);
    Issue("Default formatting is changed even when replaced with non-colored"
        @ "formatting.");
    testText = template.MutableCopy().ChangeDefaultFormatting(defaultFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part, {rgb(255,0,0) red part}, {rgb(0,255,0) green part}!!!");

    Issue("Default formatting is not changed correctly.");
    testText = template.MutableCopy().ChangeDefaultFormatting(blueFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        ("{rgb(0,0,255) Normal part, }{rgb(255,0,0) red part}{rgb(0,0,255) , }"
        $ "{rgb(0,255,0) green part}{rgb(0,0,255) !!!}"));
    testText = template.MutableCopy().ChangeDefaultFormatting(greenFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        ("{rgb(0,255,0) Normal part, }{rgb(255,0,0) red part}{rgb(0,255,0) , "
        $ "green part!!!}"));
    //  Some initial code broke at this example, so add this check
    testText =
        __().text.FromFormattedStringM("{$red red}{$lime instantly green}")
        .ChangeDefaultFormatting(greenFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "{rgb(255,0,0) red}{rgb(0,255,0) instantly green}");
}

protected static function SubTest_ChangeFormattingRegular()
{
    local Text                  template;
    local MutableText           testText;
    local BaseText.Formatting   greenFormatting, defaultFormatting;
    greenFormatting = __().text.FormattingFromColor(__().color.Lime);
    Issue("Formatting is not changed correctly.");
    template = __().text.FromFormattedString(
        "Normal part, {#ff0000 red part}, {#00ff00 green part}!!!");
    testText = template.MutableCopy().ChangeFormatting(greenFormatting, 3, 4);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        ("Nor{rgb(0,255,0) mal }part, {rgb(255,0,0) red part}, {rgb(0,255,0)"
        @ "green part}!!!"));
    testText = template.MutableCopy().ChangeFormatting(greenFormatting, 12, 10);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part,{rgb(0,255,0)  red part,} {rgb(0,255,0) green part}!!!");
    testText = template.MutableCopy().ChangeFormatting(greenFormatting, 12, 11);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part,{rgb(0,255,0)  red part, green part}!!!");
    //  This test was added because it produced `none` access errors in the
    //  old implementation of `ChangeFormatting()`
    testText = template.MutableCopy().ChangeFormatting(greenFormatting, 0, 35);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "{rgb(0,255,0) Normal part, red part, green part!!}!");
    testText = template.MutableCopy().ChangeFormatting(defaultFormatting, 3, 4);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part, {rgb(255,0,0) red part}, {rgb(0,255,0) green part}!!!");
    testText = template.MutableCopy()
        .ChangeFormatting(defaultFormatting, 16, 13);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part, {rgb(255,0,0) red} part, green {rgb(0,255,0) part}!!!");
}

protected static function SubTest_ChangeFormattingEdgeCases()
{
    local Text                  template;
    local MutableText           testText;
    local BaseText.Formatting   greenFormatting, defaultFormatting;
    greenFormatting = __().text.FormattingFromColor(__().color.Lime);
    Issue("Formatting is not changed correctly when indices are out of or"
        @ "near index boundaries.");
    template = __().text.FromFormattedString(
        "Normal part, {#ff0000 red part}, {#00ff00 green part}!!!");
    testText = template.MutableCopy().ChangeFormatting(greenFormatting, 33, 3);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part, {rgb(255,0,0) red part}, {rgb(0,255,0) green part!!!}");
    testText = template.MutableCopy().ChangeFormatting(greenFormatting, 36, 5);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part, {rgb(255,0,0) red part}, {rgb(0,255,0) green part}!!!");

    testText = template.MutableCopy()
        .ChangeFormatting(defaultFormatting, -10, 100);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part, red part, green part!!!");
    testText = template.MutableCopy()
        .ChangeFormatting(greenFormatting, -10, 16);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        ("{rgb(0,255,0) Normal} part, {rgb(255,0,0) red part}, {rgb(0,255,0)"
        @ "green part}!!!"));
}

protected static function Test_Remove()
{
    local MutableText example;
    Context("Testing `Remove()` method.");
    Issue("`Remove()` incorrectly removes `Text`'s contents with"
        @ "in-range indices.");
    example =
        __().text.FromFormattedStringM("{$Red Red}{$Green Green}{$Red Red}");
    TEST_ExpectTrue(example.MutableCopy().Remove(0, 1).ToFormattedString()
                ==  "{rgb(255,0,0) ed}{rgb(0,128,0) Green}{rgb(255,0,0) Red}");
    TEST_ExpectTrue(example.MutableCopy().Remove(2, 4).ToFormattedString()
                ==  "{rgb(255,0,0) Re}{rgb(0,128,0) en}{rgb(255,0,0) Red}");
    TEST_ExpectTrue(example.MutableCopy().Remove(3, 5).ToFormattedString()
                ==  "{rgb(255,0,0) RedRed}");
    TEST_ExpectTrue(example.MutableCopy().Remove(2, 8).ToFormattedString()
                ==  "{rgb(255,0,0) Red}");

    Issue("`Remove()` incorrectly removes `Text`'s contents with"
        @ "out-of-range indices.");
    TEST_ExpectTrue(example.MutableCopy().Remove(-10, 8).ToFormattedString()
                ==  "{rgb(255,0,0) Red}{rgb(0,128,0) Green}{rgb(255,0,0) Red}");
    TEST_ExpectTrue(example.MutableCopy().Remove(11, 20).ToFormattedString()
                ==  "{rgb(255,0,0) Red}{rgb(0,128,0) Green}{rgb(255,0,0) Red}");
    TEST_ExpectTrue(example.MutableCopy().Remove(6, 0).ToFormattedString()
                == "{rgb(255,0,0) Red}{rgb(0,128,0) Gre}");
    TEST_ExpectTrue(example.MutableCopy().Remove(6, -1).ToFormattedString()
                ==  "{rgb(255,0,0) Red}{rgb(0,128,0) Gre}");
}

protected static function Test_Simplify()
{
    local MutableText example;
    Context("Testing `Simplify()` method.");
    Issue("`Simplify()` incorrectly removes trailing and leading whitespaces.");
    example = __().text.FromFormattedStringM(default.spacesString);
    TEST_ExpectTrue(example.Simplify().ToFormattedString()
                ==  default.trimmedString);

    Issue("`Simplify(true)` incorrectly removes trailing and leading"
        @ "whitespaces and/or inner whitespaces.");
    example = __().text.FromFormattedStringM(default.spacesString);
    TEST_ExpectTrue(example.Simplify(true).ToFormattedString()
                ==  default.simplifiedString);

    Issue("`Simplify()` incorrectly simplifies `MutableText`s that consist"
        @ "only out of whitespaces.");
    example = __().text.FromFormattedStringM(default.spacesEmptyString);
    TEST_ExpectTrue(example.Simplify().IsEmpty());
    example = __().text.FromFormattedStringM(default.spacesEmptyString);
    TEST_ExpectTrue(example.Simplify(true).IsEmpty());
}

defaultproperties
{
    caseName = "Text/MutableText"
    caseGroup = "Text"
    justString          = "This is a string"
    altString           = "This is another string"
    formattedString     = "This is a {#37a6b3 string}"
    rndCaseString       = "thIs IS a sTriNG"
    bothString          = "thIs IS a {#37a6b3 sTriNG}"
    spacesString        = "	  just 　{$Red some  }{$blue string}   "
    spacesEmptyString   = "	   　{$Red   }   "
    trimmedString       = "just 　{rgb(255,0,0) some  }{rgb(0,0,255) string}"
    simplifiedString    = "just {rgb(255,0,0) some }{rgb(0,0,255) string}"
}