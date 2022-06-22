/**
 *  Set of tests for functionality of parsing formatted strings.
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
class TEST_FormattedStrings extends TestCase
    abstract;

protected static function MutableText GetRGBText(
    optional bool noFormattingReset)
{
    local int           wordIndex;
    local MutableText   result;
    result = __().text.FromStringM("This is red, green and blue!");
    wordIndex = result.IndexOf(P("red"));
    result.ChangeFormatting(__().text.FormattingFromColor(__().color.red),
                            wordIndex, 3);
    wordIndex = result.IndexOf(P("green"));
    result.ChangeFormatting(__().text.FormattingFromColor(__().color.lime),
                            wordIndex, 5);
    wordIndex = result.IndexOf(P("blue"));
    result.ChangeFormatting(__().text.FormattingFromColor(__().color.blue),
                            wordIndex, 4);
    //  also color ", " and " and " parts white, and "!" part blue
    if (noFormattingReset)
    {
        result.ChangeFormatting(__().text.FormattingFromColor(__().color.blue),
                                wordIndex, -1);
        wordIndex = result.IndexOf(P(", "));
        result.ChangeFormatting(__().text.FormattingFromColor(__().color.white),
                                wordIndex, 2);
         wordIndex = result.IndexOf(P(" and "));
        result.ChangeFormatting(__().text.FormattingFromColor(__().color.white),
                                wordIndex, 5);
    }
    return result;
}

protected static function TESTS()
{
    Test_Simple();
    Test_Gradient();
    Test_Errors();
}

protected static function Test_Simple()
{
    Context("Testing parsing formatted strings with plain colors.");
    SubTest_SimpleNone();
    SubTest_SimpleAlias();
    SubTest_SimpleRGB();
    SubTest_SimpleHEX();
    SubTest_SimpleTag();
    SubTest_SimpleMix();
}

protected static function SubTest_SimpleNone()
{
    local MutableText result;
    result = __().text.Empty();
    Issue("Empty formatted strings are handled incorrectly.");
    class'FormattingStringParser'.static.ParseFormatted(P(""), result);
    TEST_ExpectNotNone(result);
    TEST_ExpectTrue(result.IsEmpty());

    Issue("Formatted strings with no content are handled incorrectly.");
    class'FormattingStringParser'.static.ParseFormatted(P("{$red }"), result);
    TEST_ExpectNotNone(result);
    TEST_ExpectTrue(result.IsEmpty());
    class'FormattingStringParser'.static
        .ParseFormatted(P("{#ff03a5 {$blue }}^3{$lime }"), result);
    TEST_ExpectNotNone(result);
    TEST_ExpectTrue(result.IsEmpty());
}

protected static function SubTest_SimpleAlias()
{
    local MutableText result, example;
    result = __().text.Empty();
    Issue("Formatted strings with aliases are handled incorrectly.");
    example = GetRGBText();
    class'FormattingStringParser'.static.ParseFormatted(
        P("This is {$red red}, {$lime green} and {$blue blue}!"), result);
    TEST_ExpectTrue(example.Compare(result,, SFORM_SENSITIVE));
    example = GetRGBText(true);
    class'FormattingStringParser'.static.ParseFormatted(
        P("This is {$red red{$white , }{$lime green{$white  and }}}"
            $ "{$blue blue!}"),
        result.Clear());
    TEST_ExpectTrue(example.Compare(result,, SFORM_SENSITIVE));
}

protected static function SubTest_SimpleRGB()
{
    local MutableText result, example;
    result = __().text.Empty();
    Issue("Formatted strings with rgb definitions are handled incorrectly.");
    example = GetRGBText();
    class'FormattingStringParser'.static
        .ParseFormatted(P("This is {rgb(255,0,0) red}, {rgb(0,255,0) green} and"
            @ "{rgb(0,0,255) blue}!"), result);
    TEST_ExpectTrue(example.Compare(result,, SFORM_SENSITIVE));
    example = GetRGBText(true);
    class'FormattingStringParser'.static
        .ParseFormatted(P("This is {rgb(255,0,0) red{rgb(255,255,255) , }"
            $ "{rgb(0,255,0) green{rgb(255,255,255)  and }}}{rgb(0,0,255)"
            $ " blue!}"), result.Clear());
    TEST_ExpectTrue(example.Compare(result,, SFORM_SENSITIVE));
}

protected static function SubTest_SimpleHEX()
{
    local MutableText result, example;
    result = __().text.Empty();
    Issue("Formatted strings with hex definitions are handled incorrectly.");
    example = GetRGBText();
    class'FormattingStringParser'.static
        .ParseFormatted(P("This is {#ff0000 red}, {#00ff00 green} and"
            @ "{#0000ff blue}!"), result);
    TEST_ExpectTrue(example.Compare(result,, SFORM_SENSITIVE));
    example = GetRGBText(true);
    class'FormattingStringParser'.static.ParseFormatted(
        P("This is {#ff0000 red{#ffffff , }{#00ff00 green{#ffffff  and }}}"
            $ "{#0000ff blue!}"),
        result.Clear());
    TEST_ExpectTrue(example.Compare(result,, SFORM_SENSITIVE));
}

protected static function SubTest_SimpleTag()
{
    local MutableText result, example;
    result = __().text.Empty();
    Issue("Formatted strings with rag definitions are handled incorrectly.");
    example = GetRGBText(true);
    class'FormattingStringParser'.static
        .ParseFormatted(P("This is ^rred^w, ^2green^w and ^4blue!"), result);
    TEST_ExpectTrue(example.Compare(result,, SFORM_SENSITIVE));
}

protected static function SubTest_SimpleMix()
{
    local MutableText result, example;
    result = __().text.Empty();
    Issue("Formatted strings with mixed definitions are handled incorrectly.");
    example = GetRGBText();
    class'FormattingStringParser'.static
        .ParseFormatted(P("This is {rgb(255,0,0) red}, {$lime green} and"
            @ "{#af4378 ^bblue}!"), result);
    TEST_ExpectTrue(example.Compare(result,, SFORM_SENSITIVE));
    example = GetRGBText(true);
    class'FormattingStringParser'.static
        .ParseFormatted(P("This is {$red red{rgb(255,255,255) , }"
            $ "{#800c37d ^ggre^gen{#ffffff  and }}}^bblue!"), result.Clear());
    TEST_ExpectTrue(example.Compare(result,, SFORM_SENSITIVE));
}

protected static function Test_Gradient()
{
    Context("Testing parsing formatted strings with gradient.");
    SubTest_TestGradientTwoColors();
    SubTest_TestGradientThreeColors();
    SubTest_TestGradientFiveColors();
    SubTest_TestGradientPoints();
    SubTest_TestGradientPointsBad();
}

protected static function SubTest_TestGradientTwoColors()
{
    local int           i;
    local Color         previousColor, currentColor;
    local MutableText   result;
    result = __().text.Empty();
    Issue("Simple (two color) gradient block does not color intermediate"
        @ "characters correctly.");
    class'FormattingStringParser'.static
        .ParseFormatted(P("{rgb(255,128,56):rgb(0,255,56)"
            @ "Simple shit to test out gradient}"), result);
    previousColor = result.GetFormatting(0).color;
    TEST_ExpectTrue(result.GetFormatting(0).isColored);
    for (i = 1; i < result.GetLength(); i += 1)
    {
        TEST_ExpectTrue(result.GetFormatting(i).isColored);
        currentColor = result.GetFormatting(i).color;
        TEST_ExpectTrue(previousColor.r > currentColor.r);
        TEST_ExpectTrue(previousColor.g < currentColor.g);
        TEST_ExpectTrue(previousColor.b == currentColor.b);
        previousColor = currentColor;
    }
    Issue("Gradient (two color) block does not color edge characters"
        @ "correctly.");
    previousColor   = result.GetFormatting(0).color;
    currentColor    = result.GetFormatting(result.GetLength() - 1).color;
    TEST_ExpectTrue(previousColor.r == 255);
    TEST_ExpectTrue(previousColor.g == 128);
    TEST_ExpectTrue(previousColor.b == 56);
    TEST_ExpectTrue(currentColor.r == 0);
    TEST_ExpectTrue(currentColor.g == 255);
    TEST_ExpectTrue(currentColor.b == 56);
}

protected static function CheckRedDecrease(BaseText sample, int from, int to)
{
    local int   i;
    local Color previousColor, currentColor;
    previousColor = sample.GetFormatting(from).color;
    TEST_ExpectTrue(sample.GetFormatting(from).isColored);
    for (i = from + 1; i < to; i += 1)
    {
        TEST_ExpectTrue(sample.GetFormatting(i).isColored);
        currentColor = sample.GetFormatting(i).color;
        TEST_ExpectTrue(previousColor.r > currentColor.r);
        previousColor = currentColor;
    }
}

protected static function CheckRedIncrease(BaseText sample, int from, int to)
{
    local int   i;
    local Color previousColor, currentColor;
    previousColor = sample.GetFormatting(from).color;
    TEST_ExpectTrue(sample.GetFormatting(from).isColored);
    for (i = from + 1; i < to; i += 1)
    {
        TEST_ExpectTrue(sample.GetFormatting(i).isColored);
        currentColor = sample.GetFormatting(i).color;
        TEST_ExpectTrue(previousColor.r < currentColor.r);
        previousColor = currentColor;
    }
}

protected static function SubTest_TestGradientThreeColors()
{
    local Color         borderColor;
    local MutableText   result;
    result = __().text.Empty();
    Issue("Gradient block with three colors does not color intermediate"
        @ "characters correctly.");
    class'FormattingStringParser'.static
        .ParseFormatted(P("{rgb(255,0,0):#000000:$red"
            @ "Simple shit to test out gradient!}"), result);
    CheckRedDecrease(result, 0, 16);
    CheckRedIncrease(result, 17, result.GetLength());
    Issue("Gradient block with three colors does not color edge characters"
        @ "correctly.");
    borderColor = result.GetFormatting(0).color;
    TEST_ExpectTrue(borderColor.r == 255);
    borderColor = result.GetFormatting(result.GetLength() - 1).color;
    TEST_ExpectTrue(borderColor.r == 255);
    borderColor = result.GetFormatting(16).color;
    TEST_ExpectTrue(borderColor.r == 0);
}

protected static function SubTest_TestGradientFiveColors()
{
    local Color         borderColor;
    local MutableText   result;
    result = __().text.Empty();
    Issue("Gradient block with five colors does not color intermediate"
        @ "characters correctly.");
    class'FormattingStringParser'.static.ParseFormatted(
        P("Check this wacky shit out: {rgb(255,0,0):rgb(200,0,0):rgb(180,0,0)"
            $ ":rgb(210,0,0):rgb(97,0,0) Go f yourself}!?!?!"),
        result);
    result = result;
    CheckRedDecrease(result, 0 + 27, 6 + 27);
    CheckRedIncrease(result, 7 + 27, 9 + 27);
    CheckRedDecrease(result, 9 + 27, 12 + 27);
    Issue("Gradient block with five colors does not color edge characters"
        @ "correctly.");
    borderColor = result.GetFormatting(0 + 27).color;
    TEST_ExpectTrue(borderColor.r == 255);
    borderColor = result.GetFormatting(3 + 27).color;
    TEST_ExpectTrue(borderColor.r == 200);
    borderColor = result.GetFormatting(6 + 27).color;
    TEST_ExpectTrue(borderColor.r == 180);
    borderColor = result.GetFormatting(9 + 27).color;
    TEST_ExpectTrue(borderColor.r == 210);
    borderColor = result.GetFormatting(12 + 27).color;
    TEST_ExpectTrue(borderColor.r == 97);
}

protected static function SubTest_TestGradientPoints()
{
    local Color         borderColor;
    local MutableText   result;
    result = __().text.Empty();
    Issue("Gradient points are incorrectly handled.");
    class'FormattingStringParser'.static.ParseFormatted(
        P("Check this wacky shit out: {rgb(255,0,0):rgb(0,0,0)[25%]:"
            $ "rgb(123,0,0) Go f yourself}!?!?!"),
        result);
    CheckRedDecrease(result, 0 + 27, 3 + 27);
    CheckRedIncrease(result, 3 + 27, 12 + 27);
    borderColor = result.GetFormatting(0 + 27).color;
    TEST_ExpectTrue(borderColor.r == 255);
    borderColor = result.GetFormatting(3 + 27).color;
    TEST_ExpectTrue(borderColor.r == 0);
    borderColor = result.GetFormatting(12 + 27).color;
    TEST_ExpectTrue(borderColor.r == 123);
    Issue("Gradient block does not color intermediate characters correctly.");
    class'FormattingStringParser'.static.ParseFormatted(
        P("Check this wacky shit out: {rgb(255,0,0):rgb(0,0,0)[0.75]:"
            $ "rgb(45,0,0) Go f yourself}!?!?!"),
        result.Clear());
    CheckRedDecrease(result, 0 + 27, 9 + 27);
    CheckRedIncrease(result, 9 + 27, 12 + 27);
    borderColor = result.GetFormatting(0 + 27).color;
    TEST_ExpectTrue(borderColor.r == 255);
    borderColor = result.GetFormatting(9 + 27).color;
    TEST_ExpectTrue(borderColor.r == 0);
    borderColor = result.GetFormatting(12 + 27).color;
    TEST_ExpectTrue(borderColor.r == 45);
}

protected static function SubTest_TestGradientPointsBad()
{
    local Color         borderColor;
    local MutableText   result;
    result = __().text.Empty();
    Issue("Bad gradient points are incorrectly handled.");
    class'FormattingStringParser'.static.ParseFormatted(
        P("Check this wacky shit out: {rgb(255,0,0):rgb(128,0,0)[50%]:"
            $ "rgb(150,0,0)[0.3]:rgb(123,0,0) Go f yourself}!?!?!"),
        result);
    result = result;
    CheckRedDecrease(result, 0 + 27, 6 + 27);
    CheckRedIncrease(result, 6 + 27, 9 + 27);
    CheckRedDecrease(result, 9 + 27, 12 + 27);
    borderColor = result.GetFormatting(0 + 27).color;
    TEST_ExpectTrue(borderColor.r == 255);
    borderColor = result.GetFormatting(6 + 27).color;
    TEST_ExpectTrue(borderColor.r == 128);
    borderColor = result.GetFormatting(9 + 27).color;
    TEST_ExpectTrue(borderColor.r == 150);
    borderColor = result.GetFormatting(12 + 27).color;
    TEST_ExpectTrue(borderColor.r == 123);
    class'FormattingStringParser'.static.ParseFormatted(
        P("Check this wacky shit out: {rgb(200,0,0):rgb(255,0,0)[EDF]:"
            $ "rgb(0,0,0)[0.50]:rgb(45,0,0) Go f yourself}!?!?!"),
        result.Clear());
    CheckRedIncrease(result, 0 + 27, 3 + 27);
    CheckRedDecrease(result, 3 + 27, 6 + 27);
    CheckRedIncrease(result, 6 + 27, 12 + 27);
    borderColor = result.GetFormatting(0 + 27).color;
    TEST_ExpectTrue(borderColor.r == 200);
    borderColor = result.GetFormatting(3 + 27).color;
    TEST_ExpectTrue(borderColor.r == 255);
    borderColor = result.GetFormatting(6 + 27).color;
    TEST_ExpectTrue(borderColor.r == 0);
    borderColor = result.GetFormatting(12 + 27).color;
    TEST_ExpectTrue(borderColor.r == 45);
}

protected static function Test_Errors()
{
    Context("Testing error reporting for formatted strings.");
    SubTest_ErrorUnmatchedClosingBrackets();
    SubTest_ErrorEmptyColorTag();
    SubTest_ErrorBadColor();
    SubTest_ErrorBadShortColorTag();
    SubTest_ErrorBadGradientPoint();
    SubTest_ErrorBadGradientPointEmptyBlock();
    SubTest_AllErrors();
}

protected static function SubTest_ErrorUnmatchedClosingBrackets()
{
    local array<FormattingErrorsReport.FormattedStringError> errors;
    Issue("Unmatched closing brackets are not reported.");
    errors = class'FormattingStringParser'.static.ParseFormatted(
        P("Testing {$pink pink text}}!"),, true);
    TEST_ExpectTrue(errors.length == 1);
    TEST_ExpectTrue(errors[0].type == FSE_UnmatchedClosingBrackets);
    TEST_ExpectTrue(errors[0].count == 1);
    TEST_ExpectNone(errors[0].cause);
    errors = class'FormattingStringParser'.static.ParseFormatted(
        P("Testing regular text!}"),, true);
    TEST_ExpectTrue(errors.length == 1);
    TEST_ExpectTrue(errors[0].type == FSE_UnmatchedClosingBrackets);
    TEST_ExpectTrue(errors[0].count == 1);
    TEST_ExpectNone(errors[0].cause);
    errors = class'FormattingStringParser'.static
        .ParseFormatted(P("This is {rgb(255,0,0) red{rgb(255,255,255) , }}}"
            $ "{rgb(0,255,0) gr}een{rgb(255,255,255)  and }}}}{rgb(0,0,255)"
            $ " blue!}}}"),, true);
    TEST_ExpectTrue(errors.length == 1);
    TEST_ExpectTrue(errors[0].type == FSE_UnmatchedClosingBrackets);
    TEST_ExpectTrue(errors[0].count == 6);
    TEST_ExpectNone(errors[0].cause);
}

protected static function SubTest_ErrorEmptyColorTag()
{
    local array<FormattingErrorsReport.FormattedStringError> errors;
    Issue("Empty color tags are not reported.");
    errors = class'FormattingStringParser'.static.ParseFormatted(
        P("Testing { pink text}!"),, true);
    TEST_ExpectTrue(errors.length == 1);
    TEST_ExpectTrue(errors[0].type == FSE_EmptyColorTag);
    TEST_ExpectTrue(errors[0].count == 1);
    TEST_ExpectNone(errors[0].cause);
    errors = class'FormattingStringParser'.static.ParseFormatted(
        P("Testing {$red regu{   lar tex}t!}"),, true);
    TEST_ExpectTrue(errors.length == 1);
    TEST_ExpectTrue(errors[0].type == FSE_EmptyColorTag);
    TEST_ExpectTrue(errors[0].count == 1);
    TEST_ExpectNone(errors[0].cause);
    errors = class'FormattingStringParser'.static
        .ParseFormatted(P("This is { {rgb(255,255,255):$green , }"
            $ "{#800c37 ^ggre^gen{ and }}}^bblue!"),, true);
    TEST_ExpectTrue(errors.length == 1);
    TEST_ExpectTrue(errors[0].type == FSE_EmptyColorTag);
    TEST_ExpectTrue(errors[0].count == 2);
    TEST_ExpectNone(errors[0].cause);
}

protected static function SubTest_ErrorBadColor()
{
    local array<FormattingErrorsReport.FormattedStringError> errors;
    Issue("Bad color is not reported.");
    errors = class'FormattingStringParser'.static.ParseFormatted(
        P("Testing {$cat pink text}!"),, true);
    TEST_ExpectTrue(errors.length == 1);
    TEST_ExpectTrue(errors[0].type == FSE_BadColor);
    TEST_ExpectTrue(errors[0].cause.ToString() == "$cat");
    TEST_ExpectTrue(errors[0].count == 0);
    errors = class'FormattingStringParser'.static.ParseFormatted(
        P("Testing {dog regular} {#wicked text!}"),, true);
    TEST_ExpectTrue(errors.length == 2);
    TEST_ExpectTrue(errors[0].type == FSE_BadColor);
    TEST_ExpectTrue(errors[1].type == FSE_BadColor);
    TEST_ExpectTrue(errors[0].cause.ToString() == "dog");
    TEST_ExpectTrue(errors[1].cause.ToString() == "#wicked");
    errors = class'FormattingStringParser'.static
        .ParseFormatted(P("This is {goat red{rgb(255,255,255):lol:$green , }"
            $ "{#800c37 ^ggre^gen{324sd  and }}}^bblue!"),, true);
    TEST_ExpectTrue(errors.length == 3);
    TEST_ExpectTrue(errors[0].type == FSE_BadColor);
    TEST_ExpectTrue(errors[1].type == FSE_BadColor);
    TEST_ExpectTrue(errors[2].type == FSE_BadColor);
    TEST_ExpectTrue(errors[0].cause.ToString() == "goat");
    TEST_ExpectTrue(errors[1].cause.ToString() == "lol");
    TEST_ExpectTrue(errors[2].cause.ToString() == "324sd");
}

protected static function SubTest_ErrorBadShortColorTag()
{
    local array<FormattingErrorsReport.FormattedStringError> errors;
    Issue("Bad short color tag is not reported.");
    errors = class'FormattingStringParser'.static.ParseFormatted(
        P("This is ^xred^w, ^ugreen^x and ^zblue!"),, true);
    TEST_ExpectTrue(errors.length == 4);
    TEST_ExpectTrue(errors[0].type == FSE_BadShortColorTag);
    TEST_ExpectTrue(errors[0].cause.ToString() == "^x");
    TEST_ExpectTrue(errors[0].count == 0);
    TEST_ExpectTrue(errors[1].type == FSE_BadShortColorTag);
    TEST_ExpectTrue(errors[1].cause.ToString() == "^u");
    TEST_ExpectTrue(errors[1].count == 0);
    TEST_ExpectTrue(errors[2].type == FSE_BadShortColorTag);
    TEST_ExpectTrue(errors[2].cause.ToString() == "^x");
    TEST_ExpectTrue(errors[2].count == 0);
    TEST_ExpectTrue(errors[3].type == FSE_BadShortColorTag);
    TEST_ExpectTrue(errors[3].cause.ToString() == "^z");
    TEST_ExpectTrue(errors[3].count == 0);
}

protected static function SubTest_ErrorBadGradientPoint()
{
    local array<FormattingErrorsReport.FormattedStringError> errors;
    Issue("Bad gradient point is not reported.");
    errors = class'FormattingStringParser'.static.ParseFormatted(
        P("Testing {$pink[dog] pink text}!"),, true);
    TEST_ExpectTrue(errors.length == 1);
    TEST_ExpectTrue(errors[0].type == FSE_BadGradientPoint);
    TEST_ExpectTrue(errors[0].cause.ToString() == "[dog]");
    TEST_ExpectTrue(errors[0].count == 0);
    errors = class'FormattingStringParser'.static.ParseFormatted(
        P("Testing {45,2,241[bad] regular} {#ffaacd:rgb(2,3,4)45worse]"
            @ "text!}"),
        ,
        true);
    TEST_ExpectTrue(errors.length == 2);
    TEST_ExpectTrue(errors[0].type == FSE_BadGradientPoint);
    TEST_ExpectTrue(errors[1].type == FSE_BadGradientPoint);
    TEST_ExpectTrue(errors[0].cause.ToString() == "[bad]");
    TEST_ExpectTrue(errors[1].cause.ToString() == "45worse]");
    errors = class'FormattingStringParser'.static.ParseFormatted(
        P("This is {$red[45%%] red{rgb(255,255,255):45,3,128point:$green , }"
            $ "{#800c37 ^ggre^gen{#43fa6b3c  and }}}^bblue!"),
        ,
        true);
    TEST_ExpectTrue(errors.length == 3);
    TEST_ExpectTrue(errors[0].type == FSE_BadGradientPoint);
    TEST_ExpectTrue(errors[1].type == FSE_BadGradientPoint);
    TEST_ExpectTrue(errors[2].type == FSE_BadGradientPoint);
    TEST_ExpectTrue(errors[0].cause.ToString() == "[45%%]");
    TEST_ExpectTrue(errors[1].cause.ToString() == "point");
    TEST_ExpectTrue(errors[2].cause.ToString() == "3c");
}

protected static function SubTest_ErrorBadGradientPointEmptyBlock()
{
    local array<FormattingErrorsReport.FormattedStringError> errors;
    Issue("Bad gradient point with empty text block is not reported.");
    errors = class'FormattingStringParser'.static.ParseFormatted(
        P("{$red$red}"),, true);
    TEST_ExpectTrue(errors.length == 1);
    TEST_ExpectTrue(errors[0].type == FSE_BadGradientPoint);
    TEST_ExpectTrue(errors[0].cause.ToString() == "$red}");
    TEST_ExpectTrue(errors[0].count == 0);
}

protected static function SubTest_AllErrors()
{
    local int   i;
    local bool  foundUnmatched, foundEmpty, foundBadColor;
    local bool  foundBadPoint, foundBadShortTag;
    local array<FormattingErrorsReport.FormattedStringError> errors;
    Issue("If formatted string contains several errors, not all of them are"
        @ "properly detected.");
    errors = class'FormattingStringParser'.static.ParseFormatted(
        P("This} is {$cat:$green[%7] red{$white , }{ green^z and }}"
            $ "{$blue blue!}}"),
        ,
        true);
    for (i = 0; i < errors.length; i += 1)
    {
        if (errors[i].type == FSE_UnmatchedClosingBrackets)
        {
            foundUnmatched = true;
            TEST_ExpectTrue(errors[i].count == 2);
        }
        if (errors[i].type == FSE_EmptyColorTag)
        {
            foundEmpty = true;
            TEST_ExpectTrue(errors[i].count == 1);
        }
        if (errors[i].type == FSE_BadColor)
        {
            foundBadColor = true;
            TEST_ExpectTrue(errors[i].cause.ToString() == "$cat");
        }
        if (errors[i].type == FSE_BadGradientPoint)
        {
            foundBadPoint = true;
            TEST_ExpectTrue(errors[i].cause.ToString() == "[%7]");
        }
        if (errors[i].type == FSE_BadShortColorTag)
        {
            foundBadShortTag = true;
            TEST_ExpectTrue(errors[i].cause.ToString() == "^z");
        }
    }
}

defaultproperties
{
    caseName = "FormattedStrings"
    caseGroup = "Text"
}