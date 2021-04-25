/**
 *  Set of tests for functionality of `Text` and `MutableText` classes.
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
class TEST_Text extends TestCase
    abstract;

var string  justString, altString;
var string  formattedString, rndCaseString, bothString;
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
    Test_Substring();
    Test_SeparateByCharacter();
    Test_StartsEndsWith();
    Test_IndexOf();
    Test_Replace();
    Test_ChangeFormatting();
}

protected static function Test_TextCreation()
{
    local string    plainString, coloredString, formattedString;
    local Text      plain, colored, formatted;
    Context("Testing basic functionality for creating `Text` objects.");
    Issue("`Text` object is not properly created from the plain string.");
    plainString = "Prepare to DIE and be reborn!";
    plain = class'Text'.static.ConstFromPlainString(plainString);
    TEST_ExpectNotNone(plain);
    TEST_ExpectTrue(plain.ToPlainString() == plainString);

    Issue("`Text` object is not properly created from the colored string.");
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = class'Text'.static.ConstFromColoredString(coloredString);
    TEST_ExpectNotNone(colored);
    TEST_ExpectTrue(colored.ToColoredString() == coloredString);

    Issue("`Text` object is not properly created from the formatted string.");
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.ConstFromFormattedString(formattedString);
    TEST_ExpectNotNone(formatted);
    TEST_ExpectTrue(formatted.ToFormattedString() == formattedString);
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
    plain = class'Text'.static.ConstFromPlainString(plainString);
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = class'Text'.static.ConstFromColoredString(coloredString);
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.ConstFromFormattedString(formattedString);

    Issue("`Text` object is not properly copied (immutable).");
    TEST_ExpectTrue(plain.Copy().ToPlainString() == plainString);
    TEST_ExpectTrue(colored.Copy().ToColoredString() == coloredString);
    TEST_ExpectTrue(formatted.Copy().ToFormattedString() == formattedString);
    TEST_ExpectNone(MutableText(plain));
    TEST_ExpectNone(MutableText(colored));
    TEST_ExpectNone(MutableText(formatted));
    TEST_ExpectFalse(plain.Copy() == plain);
    TEST_ExpectFalse(colored.Copy() == colored);
    TEST_ExpectFalse(formatted.Copy() == formatted);

    Issue("`Text` object is not properly copied (mutable).");
    TEST_ExpectTrue(plain.MutableCopy().ToPlainString() == plainString);
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
    plain = class'Text'.static.ConstFromPlainString(plainString);
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = class'Text'.static.ConstFromColoredString(coloredString);
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.ConstFromFormattedString(formattedString);

    Issue("Part of `Text`'s contents is not properly copied (immutable).");
    TEST_ExpectTrue(    formatted.Copy(-2, 100).ToFormattedString()
                    ==  formattedString);
    TEST_ExpectTrue(plain.Copy(-2, 5).ToPlainString() == "Pre");
    TEST_ExpectTrue(    formatted.Copy(13, -10).ToFormattedString()
                    ==  "{rgb(255,0,0) E} and be reborn!");
    TEST_ExpectTrue(formatted.Copy(32).ToPlainString() == "");

    Issue("Part of `Text`'s contents is not properly copied (mutable).");
    TEST_ExpectTrue(    formatted.MutableCopy(-2, 100).ToFormattedString()
                    ==  formattedString);
    TEST_ExpectTrue(plain.MutableCopy(-2, 5).ToPlainString() == "Pre");
    TEST_ExpectTrue(    formatted.MutableCopy(13, -10).ToFormattedString()
                    ==  "{rgb(255,0,0) E} and be reborn!");
    TEST_ExpectTrue(formatted.MutableCopy(32).ToPlainString() == "");
}

protected static function SubTest_TextLowerCompleteCopy()
{
    local string    plainString, coloredString, formattedString;
    local Text      plain, colored, formatted;
    plainString = "Prepare to DIE and be reborn!";
    plain = class'Text'.static.ConstFromPlainString(plainString);
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = class'Text'.static.ConstFromColoredString(coloredString);
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.ConstFromFormattedString(formattedString);

    Issue("`Text` object is not properly copied (immutable) in lower case.");
    TEST_ExpectTrue(plain.LowerCopy().ToPlainString() == Locs(plainString));
    TEST_ExpectTrue(    colored.LowerCopy().ToColoredString()
                    ==  Locs(coloredString));
    TEST_ExpectTrue(    formatted.LowerCopy().ToFormattedString()
                    ==  Locs(formattedString));
    TEST_ExpectNone(MutableText(plain));
    TEST_ExpectNone(MutableText(colored));
    TEST_ExpectNone(MutableText(formatted));
    TEST_ExpectFalse(plain.LowerCopy() == plain);
    TEST_ExpectFalse(colored.LowerCopy() == colored);
    TEST_ExpectFalse(formatted.LowerCopy() == formatted);

    Issue("`Text` object is not properly copied (mutable) in lower case.");
    TEST_ExpectTrue(    plain.LowerMutableCopy().ToPlainString()
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
    plain = class'Text'.static.ConstFromPlainString(plainString);
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = class'Text'.static.ConstFromColoredString(coloredString);
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.ConstFromFormattedString(formattedString);

    Issue("Part of `Text`'s contents is not properly copied (immutable) in"
        @ "lower case.");
    TEST_ExpectTrue(    formatted.LowerCopy(-2, 100).ToFormattedString()
                    ==  Locs(formattedString));
    TEST_ExpectTrue(plain.LowerCopy(-2, 5).ToPlainString() == "pre");
    TEST_ExpectTrue(    formatted.LowerCopy(13, -10).ToFormattedString()
                    ==  "{rgb(255,0,0) e} and be reborn!");
    TEST_ExpectTrue(formatted.LowerCopy(32).ToPlainString() == "");

    Issue("Part of `Text`'s contents is not properly copied (mutable) in"
        @ "lower case.");
    TEST_ExpectTrue(    formatted.LowerMutableCopy(-2, 100).ToFormattedString()
                    ==  Locs(formattedString));
    TEST_ExpectTrue(plain.LowerMutableCopy(-2, 5).ToPlainString() == "pre");
    TEST_ExpectTrue(    formatted.LowerMutableCopy(13, -10).ToFormattedString()
                    ==  "{rgb(255,0,0) e} and be reborn!");
    TEST_ExpectTrue(formatted.LowerMutableCopy(32).ToPlainString() == "");
}

protected static function SubTest_TextUpperCompleteCopy()
{
    local string    plainString, coloredString, formattedString;
    local Text      plain, colored, formatted;
    plainString = "Prepare to DIE and be reborn!";
    plain = class'Text'.static.ConstFromPlainString(plainString);
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = class'Text'.static.ConstFromColoredString(coloredString);
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.ConstFromFormattedString(formattedString);

    Issue("`Text` object is not properly copied (immutable) in upper case.");
    TEST_ExpectTrue(plain.UpperCopy().ToPlainString() == Caps(plainString));
    TEST_ExpectTrue(    colored.UpperCopy().ToColoredString()
                    ==  Caps(coloredString));
    TEST_ExpectNone(MutableText(plain));
    TEST_ExpectNone(MutableText(colored));
    TEST_ExpectNone(MutableText(formatted));
    TEST_ExpectFalse(plain.UpperCopy() == plain);
    TEST_ExpectFalse(colored.UpperCopy() == colored);
    TEST_ExpectFalse(formatted.UpperCopy() == formatted);

    Issue("`Text` object is not properly copied (mutable) in upper case.");
    TEST_ExpectTrue(    plain.UpperMutableCopy().ToPlainString()
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
    plain = class'Text'.static.ConstFromPlainString(plainString);
    coloredString = __().color.GetColorTagRGB(0, 0, 0) $ "Prepare to "
        $ __().color.GetColorTagRGB(255, 0, 0) $ "DIE and be reborn!";
    colored = class'Text'.static.ConstFromColoredString(coloredString);
    formattedString = "Prepare to {rgb(255,0,0) DIE} and be reborn!";
    formatted = class'Text'.static.ConstFromFormattedString(formattedString);

    Issue("Part of `Text`'s contents is not properly copied (immutable) in"
        @ "lower case.");
    TEST_ExpectTrue(plain.UpperCopy(-2, 5).ToPlainString() == "PRE");
    TEST_ExpectTrue(    formatted.UpperCopy(13, -10).ToFormattedString()
                    ==  "{rgb(255,0,0) E} AND BE REBORN!");
    TEST_ExpectTrue(formatted.UpperCopy(32).ToPlainString() == "");

    Issue("Part of `Text`'s contents is not properly copied (mutable) in"
        @ "upper case.");
    TEST_ExpectTrue(plain.UpperMutableCopy(-2, 5).ToPlainString() == "PRE");
    TEST_ExpectTrue(    formatted.UpperMutableCopy(13, -10).ToFormattedString()
                    ==  "{rgb(255,0,0) E} AND BE REBORN!");
    TEST_ExpectTrue(formatted.UpperMutableCopy(32).ToPlainString() == "");
}

protected static function Test_TextLength()
{
    local Text allocated, empty, saturated;
    Context("Testing functionality for measuring length of `Text`'s contents.");
    allocated = Text(__().memory.Allocate(class'Text'));
    empty = class'Text'.static.ConstFromColoredString("");
    Issue("Newly created or `Text` is not considered empty.");
    TEST_ExpectTrue(allocated.GetLength() == 0);
    TEST_ExpectTrue(allocated.IsEmpty());
    TEST_ExpectTrue(empty.GetLength() == 0);
    TEST_ExpectTrue(empty.IsEmpty());

    saturated = class'Text'.static.ConstFromFormattedString(
        "Prepare to {rgb(255,0,0) DIE} and be reborn!");
    TEST_ExpectFalse(saturated.IsEmpty());
    TEST_ExpectTrue(    saturated.GetLength()
                    ==  Len("Prepare to DIE and be reborn!"));
}

protected static function PrepareDataForComparison()
{
    default.emptyText = class'Text'.static.ConstFromPlainString("");
    default.emptyText2 = class'Text'.static.ConstFromPlainString("");
    default.justText =
        class'Text'.static.ConstFromPlainString(default.justString);
    default.altText =
        class'Text'.static.ConstFromPlainString(default.altString);
    default.formattedText =
        class'Text'.static.ConstFromFormattedString(default.formattedString);
    default.rndCaseText =
        class'Text'.static.ConstFromPlainString(default.rndCaseString);
    default.bothText =
        class'Text'.static.ConstFromFormattedString(default.bothString);
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
    TEST_ExpectTrue(default.emptyText.CompareToPlainString(""));
    TEST_ExpectTrue(default.emptyText.CompareToColoredString(""));
    TEST_ExpectFalse(default.emptyText.
        CompareToPlainString(default.justString));
    TEST_ExpectFalse(default.justText.CompareToPlainString(""));

    Issue("Simple case-sensitive check is not working as expected.");
    TEST_ExpectTrue(default.justText.CompareToPlainString(default.justString));
    TEST_ExpectFalse(default.justText.CompareToPlainString(default.altString));
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
    TEST_ExpectTrue(default.justText.CompareToPlainString(  default.justString,
                                                            SCASE_INSENSITIVE));
    TEST_ExpectFalse(default.justText.CompareToPlainString( default.altString,
                                                            SCASE_INSENSITIVE));
    TEST_ExpectTrue(default.justText.CompareToColoredString(
        default.rndCaseString, SCASE_INSENSITIVE));
    TEST_ExpectTrue(default.bothText.CompareToFormattedString(
        default.formattedString, SCASE_INSENSITIVE));

    Issue("Format-sensitive check are not working as expected.");
    TEST_ExpectTrue(default.justText.CompareToColoredString(
        default.justString,, SFORM_SENSITIVE));
    TEST_ExpectTrue(default.justText.CompareToPlainString(
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
    txt = class'Text'.static.ConstFromFormattedString("Prepare to"
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
    txt = class'Text'.static.ConstFromFormattedString("Prepare to"
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
    TEST_ExpectTrue(txt.ToPlainString(3, 5) == "pare ");
    TEST_ExpectTrue(txt.ToPlainString(100, 200) == "");
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
    TEST_ExpectTrue(    txt.ToPlainString(-2, 100)
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
    part1 = class'Text'.static.ConstFromPlainString("Prepare to ");
    part2 = class'Text'.static.ConstFromColoredString(colorTag $ "DIE");
    part3 = class'Text'.static.ConstFromFormattedString(
        " and be {#00ff00 reborn}!");
    part4 = __().text.FromFormattedString(" Also {rgb(0,255,0) this}.");
    txt.Append(part1).Append(part2).Append(part3).Append(none);
    txt.Append(part4, __().text.FormattingFromColor(testColor));
    TEST_ExpectTrue(    txt.ToPlainString()
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
    local string        defaultTag, colorTag, greenTag;
    local MutableText   txt;
    Context("Testing functionality of `MutableText` to append strings.");
    txt = MutableText(__().memory.Allocate(class'MutableText'));
    Issue("New `Text` returns non-empty string as a result.");
    TEST_ExpectTrue(txt.ToPlainString() == "");
    TEST_ExpectTrue(txt.ToColoredString() == "");

    Issue("Appended strings are not returned as expected.");
    testColor = __().color.RGB(198, 23, 7);
    defaultTag = __().color.GetColorTagRGB(1, 1, 1);
    colorTag = __().color.GetColorTag(testColor);
    greenTag = __().color.GetColorTagRGB(0, 255, 0);
    txt.AppendPlainString("Prepare to ");
    txt.AppendColoredString(colorTag $ "DIE");
    txt.AppendFormattedString(" and be {#00ff00 reborn}!");
    TEST_ExpectTrue(    txt.ToPlainString()
                    ==  "Prepare to DIE and be reborn!");
    TEST_ExpectTrue(    txt.ToColoredString()
                    ==  (   defaultTag $ "Prepare to " $ colorTag $ "DIE"
                        $   defaultTag $ " and be " $ greenTag $ "reborn"
                        $   defaultTag $ "!"));
    TEST_ExpectTrue(    txt.ToFormattedString()
                    ==  ("Prepare to {rgb(198,23,7) DIE} and"
                            @ "be {rgb(0,255,0) reborn}!"));
}

protected static function Test_SeparateByCharacter()
{
    local Text                  testText;
    local array<MutableText>    slashResult, fResult;
    testText = __().text.FromFormattedString("/{#ff0000 usr/{#0000ff bin}}/"
        $ "{#00ff00 stu}ff");
    Context("Testing functionality of `Text` to be split by given character.");
    slashResult = testText.SplitByCharacter(__().text.GetCharacter("/"));
    fResult = testText.SplitByCharacter(__().text.GetCharacter("f"));

    Issue("Returned `MutableText`s have incorrect text content.");
    TEST_ExpectTrue(slashResult.length == 4);
    TEST_ExpectTrue(slashResult[0].CompareToPlainString(""));
    TEST_ExpectTrue(slashResult[1].CompareToPlainString("usr"));
    TEST_ExpectTrue(slashResult[2].CompareToPlainString("bin"));
    TEST_ExpectTrue(slashResult[3].CompareToPlainString("stuff"));
    TEST_ExpectTrue(fResult.length == 3);
    TEST_ExpectTrue(fResult[0].CompareToPlainString("/usr/bin/stu"));
    TEST_ExpectTrue(fResult[1].CompareToPlainString(""));
    TEST_ExpectTrue(fResult[2].CompareToPlainString(""));

    Issue("Returned `MutableText`s have incorrect formatting.");
    TEST_ExpectTrue(slashResult[1].CompareToFormattedString("{#ff0000 usr}"));
    TEST_ExpectTrue(slashResult[2].CompareToFormattedString("{#0000ff bin}"));
    TEST_ExpectTrue(slashResult[3].CompareToFormattedString("{#00ff00 stu}ff"));
    TEST_ExpectTrue(fResult[0].CompareToFormattedString(
        "/{#ff0000 usr/{#0000ff bin}}/{#00ff00 stu}"));
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

protected static function SubTest_StartsWith(Text.FormatSensitivity flag)
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

protected static function SubTest_EndsWith(Text.FormatSensitivity flag)
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

protected static function SubTest_IndexOfSuccess(Text.FormatSensitivity flag)
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

protected static function SubTest_IndexOfFail(Text.FormatSensitivity flag)
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
    Text.FormatSensitivity flag)
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

protected static function SubTest_LastIndexOfFail(Text.FormatSensitivity flag)
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

protected static function SubTest_ReplaceEdgeCases(Text.FormatSensitivity flag)
{
    local MutableText builder;
    builder = __().text.Empty();
    Issue("`Replace()` works incorrectly when replacing empty `Text`s.");
    TEST_ExpectTrue(builder.Replace(P(""), P(""),, flag).ToPlainString() == "");
    TEST_ExpectTrue(
        builder.Replace(P(""), P("huh"),, flag).ToPlainString() == "");
    builder.AppendPlainString("word");
    TEST_ExpectTrue(
        builder.Replace(P(""), P(""),, flag).ToPlainString() == "word");
    TEST_ExpectTrue(
        builder.Replace(P(""), P("huh"),, flag).ToPlainString() == "word");

    Issue("`Replace()` works incorrectly when replacing something inside"
        @ "an empty `Text`s.");
    builder.Clear();
    TEST_ExpectTrue(
        builder.Replace(P("huh"), P(""),, flag).ToPlainString() == "");

    Issue("`Replace()` cannot replace whole `Text`s.");
    TEST_ExpectTrue(builder.Clear()
            .AppendFormattedString("Just {#54af4c something}")
            .Replace(F("Just {#54af4c something}"), P("Nothing really"),, flag)
            .ToPlainString()
        ==  "Nothing really");
    TEST_ExpectTrue(builder.Clear().AppendPlainString("CraZy")
            .Replace(P("CRaZy"), P("calm"), SCASE_INSENSITIVE, flag)
            .ToPlainString()
        ==  "calm");
}

protected static function SubTest_ReplaceMainCases(Text.FormatSensitivity flag)
{
    local MutableText builder;
    builder = __().text.FromStringM("Mate eight said");
    Issue("`Replace()` works incorrectly changes `Text` when replacing"
        @ "non-existent sub-`Text`.");
    TEST_ExpectTrue(builder.Replace(P("word"), P("another"),, flag)
            .ToPlainString()
        ==  "Mate eight said");
    TEST_ExpectTrue(builder
            .Replace(P("word"), P("another"), SCASE_INSENSITIVE, flag)
            .ToPlainString()
        ==  "Mate eight said");

    Issue("`Replace()` replaces sub-`Text` incorrectly.");
    builder.Clear().AppendPlainString("Do it bay bee");
    TEST_ExpectTrue(builder.Replace(P("it"), P("this"),, flag).ToPlainString()
        ==  "Do this bay bee");
    builder.Clear().AppendPlainString("dO It bAy BEe");
    TEST_ExpectTrue(
            builder.Replace(P("it"), P("tHis"), SCASE_INSENSITIVE, flag)
            .ToPlainString()
        ==  "dO tHis bAy BEe");

    Issue("`Replace()` replaces sub-`Text` incorrectly.");
    builder.Clear().AppendPlainString("he and she and it");
    TEST_ExpectTrue(builder.Replace(P("and"), P("OR"),, flag)
            .ToPlainString()
        ==  "he OR she OR it");
    builder.Clear().AppendFormattedString("{#54af4c HE} aNd sHe aND iT");
    TEST_ExpectTrue(builder.Replace(P("AND"), P("Or"), SCASE_INSENSITIVE, flag)
            .ToPlainString()
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
    Context("Testing `ChangeFormatting()` method.");
    SubTest_ChangeFormattingRegular();
    SubTest_ChangeFormattingEdgeCases();
}

protected static function SubTest_ChangeFormattingRegular()
{
    local Text              template;
    local MutableText       testText;
    local Text.Formatting   greenFormatting, defaultFormatting;
    greenFormatting = __().text.FormattingFromColor(__().color.Lime);
    Issue("Formatting is not changed correctly.");
    template = __().text.FromFormattedString(
        "Normal part, {#ff0000 red part}, {#00ff00 green part}!!!");
    testText = template.MutableCopy().ChangeFormatting(3, 4, greenFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        ("Nor{rgb(0,255,0) mal }part, {rgb(255,0,0) red part}, {rgb(0,255,0)"
        @ "green part}!!!"));
    testText = template.MutableCopy().ChangeFormatting(12, 10, greenFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part,{rgb(0,255,0)  red part,} {rgb(0,255,0) green part}!!!");
    testText = template.MutableCopy().ChangeFormatting(12, 11, greenFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part,{rgb(0,255,0)  red part, green part}!!!");
    //  This test was added because it produced `none` access errors in the
    //  old implementation of `ChangeFormatting()`
    testText = template.MutableCopy().ChangeFormatting(0, 35, greenFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "{rgb(0,255,0) Normal part, red part, green part!!}!");
    testText = template.MutableCopy().ChangeFormatting(3, 4, defaultFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part, {rgb(255,0,0) red part}, {rgb(0,255,0) green part}!!!");
    testText = template.MutableCopy()
        .ChangeFormatting(16, 13, defaultFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part, {rgb(255,0,0) red} part, green {rgb(0,255,0) part}!!!");
}

protected static function SubTest_ChangeFormattingEdgeCases()
{
    local Text              template;
    local MutableText       testText;
    local Text.Formatting   greenFormatting, defaultFormatting;
    greenFormatting = __().text.FormattingFromColor(__().color.Lime);
    Issue("Formatting is not changed correctly when indices are out of or"
        @ "near index boundaries.");
    template = __().text.FromFormattedString(
        "Normal part, {#ff0000 red part}, {#00ff00 green part}!!!");
    testText = template.MutableCopy().ChangeFormatting(33, 3, greenFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part, {rgb(255,0,0) red part}, {rgb(0,255,0) green part!!!}");
    testText = template.MutableCopy().ChangeFormatting(36, 5, greenFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part, {rgb(255,0,0) red part}, {rgb(0,255,0) green part}!!!");

    testText = template.MutableCopy()
        .ChangeFormatting(-10, 100, defaultFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        "Normal part, red part, green part!!!");
    testText = template.MutableCopy()
        .ChangeFormatting(-10, 16, greenFormatting);
    TEST_ExpectTrue(testText.ToFormattedString() ==
        ("{rgb(0,255,0) Normal} part, {rgb(255,0,0) red part}, {rgb(0,255,0)"
        @ "green part}!!!"));
}

defaultproperties
{
    caseName = "Text/MutableText"
    caseGroup = "Text"
    justString      = "This is a string"
    altString       = "This is another string"
    formattedString = "This is a {#37a6b3 string}"
    rndCaseString   = "thIs IS a sTriNG"
    bothString      = "thIs IS a {#37a6b3 sTriNG}"
}