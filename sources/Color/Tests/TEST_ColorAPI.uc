/**
 *  Set of tests for Color API.
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
class TEST_ColorAPI extends TestCase
    abstract;

protected static function TESTS()
{
    Test_ColorCreation();
    Test_EqualityCheck();
    Test_ColorFixing();
    Test_ToString();
    Test_Parse();
    Test_GetTag();
}

protected static function Test_ColorCreation()
{
    Context("Testing `ColorAPI`'s functions for creating color structures.");
    SubTest_ColorCreationRGB();
    SubTest_ColorCreationRGBA();
}

protected static function SubTest_ColorCreationRGB()
{
    local Color createdColor;
    Issue("`RGB() function does not set red, green and blue components"
        @ "correctly.");
    createdColor = __().color.RGB(145, 67, 237);
    TEST_ExpectTrue(createdColor.r == 145);
    TEST_ExpectTrue(createdColor.g == 67);
    TEST_ExpectTrue(createdColor.b == 237);

    Issue("`RGB() function does not set alpha component to 255.");
    TEST_ExpectTrue(createdColor.a == 255);

    Issue("`RGB() function does not set special values (border values"
        @ "`0`, `255` and value `10`, incorrect for coloring a `string`) for"
        @"red, green and blue components correctly.");
    createdColor = __().color.RGB(0, 10, 255);
    TEST_ExpectTrue(createdColor.r == 0);
    TEST_ExpectTrue(createdColor.g == 10);
    TEST_ExpectTrue(createdColor.b == 255);

    Issue("`RGB() function does not set alpha value to 255.");
    TEST_ExpectTrue(createdColor.a == 255);
}

protected static function SubTest_ColorCreationRGBA()
{
    local Color createdColor;
    Issue("`RGBA() function does not set red, green, blue, alpha"
        @ "components correctly.");
    createdColor = __().color.RGBA(93, 245, 1, 67);
    TEST_ExpectTrue(createdColor.r == 93);
    TEST_ExpectTrue(createdColor.g == 245);
    TEST_ExpectTrue(createdColor.b == 1);
    TEST_ExpectTrue(createdColor.a == 67);

    Issue("`RGBA() function does not set special values (border values"
        @ "`0`, `255` and value `10`, incorrect for coloring a `string`) for"
        @"red, green, blue components correctly.");
    createdColor = __().color.RGBA(0, 10, 10, 255);
    TEST_ExpectTrue(createdColor.r == 0);
    TEST_ExpectTrue(createdColor.g == 10);
    TEST_ExpectTrue(createdColor.b == 10);
    TEST_ExpectTrue(createdColor.a == 255);
}

protected static function Test_EqualityCheck()
{
    Context("Testing `ColorAPI`'s functions for color equality check.");
    SubTest_EqualityCheckNotFixed();
    SubTest_EqualityCheckFixed();
}

protected static function SubTest_EqualityCheckNotFixed()
{
    local Color color1, color2, color3;
    color1 = __().color.RGB(45, 10, 19);
    color2 = __().color.RGB(45, 11, 19);
    color3 = __().color.RGBA(45, 10, 19, 178);
    Issue("`AreEqual()` does not recognized equal colors as such.");
    TEST_ExpectTrue(__().color.AreEqual(color1, color1));

    Issue("`AreEqual()` does not recognized colors that differ only in alpha"
        @ "channel as equal.");
    TEST_ExpectTrue(__().color.AreEqual(color1, color3));

    Issue("`AreEqual()` does not recognized different colors as such.");
    TEST_ExpectFalse(__().color.AreEqual(color1, color2));

    Issue("`AreEqualWithAlpha()` does not recognized equal colors as such.");
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(color1, color1));
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(color3, color3));

    Issue("`AreEqualWithAlpha()` does not recognized different colors" 
        @ "as such.");
    TEST_ExpectFalse(__().color.AreEqualWithAlpha(color1, color2));
    TEST_ExpectFalse(__().color.AreEqualWithAlpha(color1, color3));
}

protected static function SubTest_EqualityCheckFixed()
{
    local Color color1, color2, color3;
    color1 = __().color.RGB(45, 10, 0);
    color2 = __().color.RGB(45, 239, 19);
    color3 = __().color.RGBA(45, 11, 1, 178);
    Issue("`AreEqual()` does not recognized equal colors as such (with color" 
        @ "auto-fix).");
    TEST_ExpectTrue(__().color.AreEqual(color1, color1, true));

    Issue("`AreEqual()` does not recognized colors that differ only in alpha"
        @ "channel as equal (with color auto-fix).");
    TEST_ExpectTrue(__().color.AreEqual(color1, color3, true));

    Issue("`AreEqual()` does not recognized different colors as such"
        @ "(with color auto-fix).");
    TEST_ExpectFalse(__().color.AreEqual(color1, color2, true));

    Issue("`AreEqualWithAlpha()` does not recognized equal colors as such"
        @ "(with color auto-fix).");
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(color1, color1, true));
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(color3, color3, true));

    Issue("`AreEqualWithAlpha()` does not recognized different colors as such"
        @ "(with color auto-fix).");
    TEST_ExpectFalse(__().color.AreEqualWithAlpha(color1, color2, true));
    TEST_ExpectFalse(__().color.AreEqualWithAlpha(color1, color3, true));
}

protected static function Test_ColorFixing()
{
    local Color validColor, brokenColor;
    validColor = __().color.RGB(23, 179, 244);
    brokenColor = __().color.RGB(10, 35, 0);
    Context("Testing `ColorAPI`'s functions for fixing color components for"
        @ "game's native render functions.");
    Issue("`FixColorComponent()` does not \"fix\" values it is expected to," 
        @ "the way it is expected to.");
    TEST_ExpectTrue(__().color.FixColorComponent(0) == 1);
    TEST_ExpectTrue(__().color.FixColorComponent(10) == 11);

    Issue("`FixColorComponent()` changes values it should not.");
    TEST_ExpectTrue(__().color.FixColorComponent(9) == 9);
    TEST_ExpectTrue(__().color.FixColorComponent(255) == 255);
    TEST_ExpectTrue(__().color.FixColorComponent(87) == 87);

    Issue("`FixColor()` changes colors it should not.");
    TEST_ExpectTrue(
        __().color.AreEqualWithAlpha(validColor,
                                    __().color.FixColor(validColor)));

    Issue("`FixColor()` doesn't fix color it should fix in an expected way.");
    TEST_ExpectTrue(
        __().color.AreEqualWithAlpha(__().color.RGB(11, 35, 1),
                                    __().color.FixColor(brokenColor)));

    Issue("`FixColor()` affects alpha channel.");
    TEST_ExpectTrue(__().color.FixColor(validColor).a == 255);
    validColor.a = 0;
    TEST_ExpectTrue(__().color.FixColor(validColor).a == 0);
    validColor.a = 10;
    TEST_ExpectTrue(__().color.FixColor(validColor).a == 10);
}

protected static function Test_ToString()
{
    Context("Testing `ColorAPI`'s `ToString()` function.");
    SubTest_ToStringType();
    SubTest_ToStringTypeStripped();
    SubTest_ToString();
}

protected static function SubTest_ToStringType()
{
    local Color normalColor, borderValueColor;
    normalColor         = __().color.RGBA(24, 232, 187, 34);
    borderValueColor    = __().color.RGBA(0, 255, 255, 0);
    Issue("`ToStringType()` improperly works with `CLRDISPLAY_HEX` option.");
    TEST_ExpectTrue(__().color.ToStringType(normalColor) ~= "#18e8bb");
    TEST_ExpectTrue(__().color.ToStringType(borderValueColor) ~= "#00ffff");

    Issue("`ToStringType()` improperly works with `CLRDISPLAY_RGB` option.");
    TEST_ExpectTrue(__().color.ToStringType(normalColor, CLRDISPLAY_RGB)
                    ~= "rgb(24,232,187)");
    TEST_ExpectTrue(__().color.ToStringType(borderValueColor, CLRDISPLAY_RGB)
                    ~= "rgb(0,255,255)");

    Issue("`ToStringType()` improperly works with `CLRDISPLAY_RGBA` option.");
    TEST_ExpectTrue(__().color.ToStringType(normalColor, CLRDISPLAY_RGBA)
                    ~= "rgba(24,232,187,34)");
    TEST_ExpectTrue(__().color.ToStringType(borderValueColor, CLRDISPLAY_RGBA)
                    ~= "rgba(0,255,255,0)");

    Issue("`ToStringType()` improperly works with `CLRDISPLAY_RGB_TAG`"
        @ "option.");
    TEST_ExpectTrue(__().color.ToStringType(normalColor, CLRDISPLAY_RGB_TAG)
                    ~= "rgb(r=24,g=232,b=187)");
    TEST_ExpectTrue(
        __().color.ToStringType(borderValueColor, CLRDISPLAY_RGB_TAG)
        ~= "rgb(r=0,g=255,b=255)");

    Issue("`ToStringType()` improperly works with `CLRDISPLAY_RGBA_TAG`"
        @ "option.");
    TEST_ExpectTrue(__().color.ToStringType(normalColor, CLRDISPLAY_RGBA_TAG)
                    ~= "rgba(r=24,g=232,b=187,a=34)");
    TEST_ExpectTrue(
        __().color.ToStringType(borderValueColor, CLRDISPLAY_RGBA_TAG)
        ~= "rgba(r=0,g=255,b=255,a=0)");
}

protected static function SubTest_ToStringTypeStripped()
{
    local Color normalColor, borderValueColor;
    normalColor         = __().color.RGBA(24, 232, 187, 34);
    borderValueColor    = __().color.RGBA(0, 255, 255, 0);
    Issue("`ToStringType()` improperly works with `CLRDISPLAY_RGB_STRIPPED`"
        @ "option.");
    TEST_ExpectTrue(
            __().color.ToStringType(normalColor, CLRDISPLAY_RGB_STRIPPED)
        ~=  "24,232,187");
    TEST_ExpectTrue(
        __().color.ToStringType(borderValueColor, CLRDISPLAY_RGB_STRIPPED)
        ~= "0,255,255");

    Issue("`ToStringType()` improperly works with `CLRDISPLAY_RGBA_STRIPPED`"
        @ "option.");
    TEST_ExpectTrue(
            __().color.ToStringType(normalColor, CLRDISPLAY_RGBA_STRIPPED)
        ~=  "24,232,187,34");
    TEST_ExpectTrue(
        __().color.ToStringType(borderValueColor, CLRDISPLAY_RGBA_STRIPPED)
        ~= "0,255,255,0");
}

protected static function SubTest_ToString()
{
    local Color opaqueColor, transparentColor;
    opaqueColor         = __().color.RGBA(143, 211, 43, 255);
    transparentColor    = __().color.RGBA(234, 32, 145, 13);
    Issue("`ToString()` improperly converts color with opaque color.");
    TEST_ExpectTrue(__().color.ToString(opaqueColor) ~= "rgb(143,211,43)");
    Issue("`ToString()` improperly converts color with transparent color.");
    TEST_ExpectTrue(__().color.ToString(transparentColor)
                    ~= "rgba(234,32,145,13)");
}

protected static function Test_GetTag()
{
    Context("Testing `ColorAPI`'s functionality of creating 4-byte color"
        @ "change sequences.");
    SubTest_GetTagColor();
    SubTest_GetTagRGB();
}

protected static function SubTest_GetTagColor()
{
    local Color normalColor, borderColor;
    normalColor = __().color.RGB(143, 211, 43);
    borderColor = __().color.RGB(10, 0, 255);
    Issue("`GetColorTag()` does not properly convert colors.");
    TEST_ExpectTrue(__().color.GetColorTag(normalColor)
        == (Chr(27) $ Chr(143) $ Chr(211) $ Chr(43)));
    TEST_ExpectTrue(__().color.GetColorTag(borderColor)
        == (Chr(27) $ Chr(11) $ Chr(1) $ Chr(255)));

    Issue("`GetColorTag()` does not properly convert colors when asked not to"
        @ "fix components.");
    TEST_ExpectTrue(__().color.GetColorTag(normalColor, true)
        == (Chr(27) $ Chr(143) $ Chr(211) $ Chr(43)));
    TEST_ExpectTrue(__().color.GetColorTag(borderColor, true)
        == (Chr(27) $ Chr(10) $ Chr(1) $ Chr(255)));
}

protected static function SubTest_GetTagRGB()
{
    Issue("`GetColorTagRGB()` does not properly convert colors.");
    TEST_ExpectTrue(__().color.GetColorTagRGB(143, 211, 43)
        == (Chr(27) $ Chr(143) $ Chr(211) $ Chr(43)));
    TEST_ExpectTrue(__().color.GetColorTagRGB(10, 0, 255)
        == (Chr(27) $ Chr(11) $ Chr(1) $ Chr(255)));

    Issue("`GetColorTagRGB()` does not properly convert colors when asked"
        @ "not to fix components.");
    TEST_ExpectTrue(__().color.GetColorTagRGB(143, 211, 43, true)
        == (Chr(27) $ Chr(143) $ Chr(211) $ Chr(43)));
    TEST_ExpectTrue(__().color.GetColorTagRGB(10, 0, 255, true)
        == (Chr(27) $ Chr(10) $ Chr(1) $ Chr(255)));
}

protected static function Test_Parse()
{
    Context("Testing `ColorAPI`'s parsing functionality.");
    SubTest_ParseWithParser();
    SubTest_ParseStringPlain();
    SubTest_ParseText();
    SubTest_ParseWithParserStripped();
    SubTest_ParseStringPlainStripped();
    SubTest_ParseTextStripped();
}

protected static function SubTest_ParseWithParser()
{
    local Color expectedColor, resultColor;
    expectedColor = __().color.RGBA(154, 255, 0, 187);
    Issue("`ParseWith()` cannot parse hex colors.");
    TEST_ExpectTrue(__().color.ParseWith(__().text.ParseString("#9aff00"),
                                        resultColor));
    TEST_ExpectTrue(__().color.AreEqual(resultColor, expectedColor));

    Issue("`ParseWith()` cannot parse rgb colors.");
    TEST_ExpectTrue(__().color.ParseWith(__().text.ParseString("rgb(154,255,0)"),
                                        resultColor));
    TEST_ExpectTrue(__().color.AreEqual(resultColor, expectedColor));

    Issue("`ParseWith()` cannot parse rgba colors.");
    TEST_ExpectTrue(__().color.ParseWith(
        __().text.ParseString("rgba(154,255,0,187)"),
        resultColor));
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(resultColor, expectedColor));

    Issue("`ParseWith()` cannot parse rgb colors with tags.");
    TEST_ExpectTrue(__().color.ParseWith(
        __().text.ParseString("rgb(r=154,g=255,b=0)"),
        resultColor));
    TEST_ExpectTrue(__().color.AreEqual(resultColor, expectedColor));

    Issue("`ParseWith()` cannot parse rgba colors with tags.");
    TEST_ExpectTrue(__().color.ParseWith(
        __().text.ParseString("rgba(r=154,g=255,b=0,a=187)"),
        resultColor));
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(resultColor, expectedColor));

    Issue("`ParseWith()` reports success when parsing invalid color string.");
    TEST_ExpectFalse(__().color.ParseWith(   __().text.ParseString("#9aff0g"),
                                            resultColor));
}

protected static function SubTest_ParseStringPlain()
{
    local Color expectedColor, resultColor;
    expectedColor = __().color.RGBA(154, 255, 0, 187);
    Issue("`ParseString()` cannot parse hex colors.");
    TEST_ExpectTrue(__().color.ParseString("#9aff00", resultColor));
    TEST_ExpectTrue(__().color.AreEqual(resultColor, expectedColor));

    Issue("`ParseString()` cannot parse rgb colors.");
    TEST_ExpectTrue(__().color.ParseString("rgb(154,255,0)", resultColor));
    TEST_ExpectTrue(__().color.AreEqual(resultColor, expectedColor));

    Issue("`ParseString()` cannot parse rgba colors.");
    TEST_ExpectTrue(__().color.ParseString("rgba(154,255,0,187)", resultColor));
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(resultColor, expectedColor));

    Issue("`ParseString()` cannot parse rgb colors with tags.");
    TEST_ExpectTrue(__().color.ParseString("rgb(r=154,g=255,b=0)",
                    resultColor));
    TEST_ExpectTrue(__().color.AreEqual(resultColor, expectedColor));

    Issue("`ParseString()` cannot parse rgba colors with tags.");
    TEST_ExpectTrue(__().color.ParseString(  "rgba(r=154,g=255,b=0,a=187)",
                                            resultColor));
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(resultColor, expectedColor));

    Issue("`ParseString()` reports success when parsing invalid color string.");
    TEST_ExpectFalse(__().color.ParseString("#9aff0g", resultColor));
}

protected static function SubTest_ParseText()
{
    local Color expectedColor, resultColor;
    expectedColor = __().color.RGBA(154, 255, 0, 187);
    Issue("`Parse()` cannot parse hex colors.");
    TEST_ExpectTrue(__().color.Parse(__().text.FromString("#9aff00"),
                                        resultColor));
    TEST_ExpectTrue(__().color.AreEqual(resultColor, expectedColor));

    Issue("`Parse()` cannot parse rgb colors.");
    TEST_ExpectTrue(__().color.Parse(__().text.FromString("rgb(154,255,0)"),
                                        resultColor));
    TEST_ExpectTrue(__().color.AreEqual(resultColor, expectedColor));

    Issue("`Parse()` cannot parse rgba colors.");
    TEST_ExpectTrue(__().color.Parse(
        __().text.FromString("rgba(154,255,0,187)"),
        resultColor));
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(resultColor, expectedColor));

    Issue("`Parse()` cannot parse rgb colors with tags.");
    TEST_ExpectTrue(__().color.Parse(
        __().text.FromString("rgb(r=154,g=255,b=0)"),
        resultColor));
    TEST_ExpectTrue(__().color.AreEqual(resultColor, expectedColor));

    Issue("`Parse()` cannot parse rgba colors with tags.");
    TEST_ExpectTrue(__().color.Parse(
        __().text.FromString("rgba(r=154,g=255,b=0,a=187)"),
        resultColor));
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(resultColor, expectedColor));

    Issue("`Parse()` reports success when parsing invalid color string.");
    TEST_ExpectFalse(__().color.Parse(   __().text.FromString("#9aff0g"),
                                        resultColor));
}

protected static function SubTest_ParseWithParserStripped()
{
    local Color expectedColor, resultColor;
    expectedColor = __().color.RGBA(154, 255, 0, 187);
    Issue("`ParseWith()` cannot parse stripped rgb colors.");
    TEST_ExpectTrue(__().color.ParseWith(
        __().text.ParseString("154,255,0"),
        resultColor));
    TEST_ExpectTrue(__().color.AreEqual(resultColor, expectedColor));

    Issue("`ParseWith()` cannot parse stripped rgba colors.");
    TEST_ExpectTrue(__().color.ParseWith(
        __().text.ParseString("154,255,0,187"),
        resultColor));
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(resultColor, expectedColor));
}

protected static function SubTest_ParseStringPlainStripped()
{
    local Color expectedColor, resultColor;
    expectedColor = __().color.RGBA(154, 255, 0, 187);
    Issue("`ParseString()` cannot parse stripped rgb colors.");
    TEST_ExpectTrue(__().color.ParseString("154,255,0", resultColor));
    TEST_ExpectTrue(__().color.AreEqual(resultColor, expectedColor));

    Issue("`ParseString()` cannot parse stripped rgba colors.");
    TEST_ExpectTrue(__().color.ParseString("154,255,0,187", resultColor));
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(resultColor, expectedColor));
}

protected static function SubTest_ParseTextStripped()
{
    local Color expectedColor, resultColor;
    expectedColor = __().color.RGBA(154, 255, 0, 187);
    Issue("`Parse()` cannot parse stripped rgb colors.");
    TEST_ExpectTrue(__().color.Parse(
        __().text.FromString("154,255,0"),
        resultColor));
    TEST_ExpectTrue(__().color.AreEqual(resultColor, expectedColor));

    Issue("`Parse()` cannot parse stripped rgba colors.");
    TEST_ExpectTrue(__().color.Parse(
        __().text.FromString("154,255,0,187"),
        resultColor));
    TEST_ExpectTrue(__().color.AreEqualWithAlpha(resultColor, expectedColor));
}

defaultproperties
{
    caseName    = "ColorAPI"
    caseGroup   = "Color"
}