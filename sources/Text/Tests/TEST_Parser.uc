/**
 *  Set of tests for `Parser` class.
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
class TEST_Parser extends TestCase
    dependson(Text)
    dependson(Parser)
    abstract;

var const string stringWithNonASCIISymbols;
var const string stringWithWhitespaces;
var const string usedSpaces1, usedSpaces2, usedSpaces3;

//  Do given arrays form identical sequences of code points?
protected static function bool CompareRaw
(
    array<Text.Character> array1,
    array<Text.Character> array2
)
{
    local int i;
    if (array1.length != array2.length) return false;

    for (i = 0; i < array1.length; i += 1)
    {
        if (!_().text.AreEqual(array1[i], array2[i]))
        {
            return false;
        }
    }
    return true;
}

protected static function TESTS()
{
    Test_Match();
    Test_GetLength();
    Test_GetRemainder();
    Test_EOF();
    Test_States();
    Test_Skip();
    Test_Whitespaces();
    Test_CharacterAndByte();
    Test_Until();
    Test_ParseString();
    Test_ParseInt();
    Test_ParseNumber();
}

protected static function Test_Match()
{
    Context("Testing `Parser`'s `Match()` functions.");
    SubTest_MatchSimple();
    SubTest_MatchEmpty();
    SubTest_MatchInvalid();
    SubTest_MatchRawSimple();
    SubTest_MatchRawEmpty();
    SubTest_MatchRawInvalid();
}

protected static function SubTest_MatchSimple()
{
    local Parser parser;
    parser = new class'Parser';
    parser.Initialize("PuripuriPerurun");
    Issue("`Match` can't parse prefix in a simplest case.");
    TEST_ExpectTrue(parser.Match("Puri").Ok());

    Issue("`Match` can't perform two parsings in a row.");
    TEST_ExpectTrue(parser.R().Match("Puri").Match("puriPerur").Ok());

    Issue("`Match` doesn't properly parse in a case-insensitive mode.");
    TEST_ExpectTrue(parser.R().Match("pURi", true).Ok());
    TEST_ExpectTrue(parser.R().Match("Puri").Match("PuRiPeRur", true).Ok());

    parser.InitializeT(_().text.FromString("PuripuriPerurun"));
    Issue("`MatchT` does not return back the caller parser.");
    TEST_ExpectTrue(parser.MatchT(_().text.FromString("Puri")) == parser);

    Issue("`MatchT` can't parse prefix in a simplest case.");
    TEST_ExpectTrue(parser.R().MatchT(_().text.FromString("Puri")).Ok());

    Issue("`MatchT` can't perform two parsings in a row.");
    TEST_ExpectTrue(parser.R()
        .MatchT(_().text.FromString("Puri"))
        .MatchT(_().text.FromString("puriPerur"))
        .Ok());

    Issue("`MatchT` doesn't properly parse in a case-insensitive mode.");
    TEST_ExpectTrue(parser.R().MatchT(_().text.FromString("pURi"), true).Ok());
    TEST_ExpectTrue(parser.R()
        .MatchT(_().text.FromString("Puri"))
        .MatchT(_().text.FromString("PuRiPeRur"), true)
        .Ok());
}

protected static function SubTest_MatchRawSimple()
{
    local Parser parser;
    parser = new class'Parser';
    parser.InitializeRaw(_().text.StringToRaw("PuripuriPerurun"));
    Issue("`MatchRaw` does not return back the caller parser.");
    TEST_ExpectTrue(parser.MatchRaw(_().text.StringToRaw("Puri")) == parser);

    Issue("`MatchRaw` can't parse prefix in a simplest case.");
    TEST_ExpectTrue(parser.R().MatchRaw(_().text.StringToRaw("Puri")).Ok());

    Issue("`MatchRaw` can't perform two parsings in a row.");
    TEST_ExpectTrue(parser.R()
        .MatchRaw(_().text.StringToRaw("Puri"))
        .MatchRaw(_().text.StringToRaw("puriPerur"))
        .Ok());

    Issue("`MatchRaw` doesn't properly parse in a case-insensitive mode.");
    parser.R().MatchRaw(_().text.StringToRaw("pURi"), true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(parser.R()
        .MatchRaw(_().text.StringToRaw("Puri"))
        .MatchRaw(_().text.StringToRaw("PuRiPeRur"), true)
        .Ok());
}

protected static function SubTest_MatchEmpty()
{
    local Parser parser;
    parser = new class'Parser';
    parser.Initialize("Just me.");
    Issue("`Match` does not succeed at empty input.");
    TEST_ExpectTrue(parser.Match("").Ok());

    parser.Initialize("");
    Issue(  "`Match` does not succeed at empty input when filled" @
            "with empty content.");
    TEST_ExpectTrue(parser.Match("").Ok());

    Issue("`Match` succeed when `Parser`'s contents are empty.");
    TEST_ExpectFalse(parser.Match("1").Ok());

    parser.InitializeT(_().text.FromString("Just me."));
    Issue("`MatchT` does not succeed at empty input.");
    TEST_ExpectTrue(parser.MatchT(_().text.FromString("")).Ok());

    parser.InitializeT(_().text.FromString(""));
    Issue(  "`MatchT` does not succeed at empty input when filled" @
            "with empty content.");
    TEST_ExpectTrue(parser.MatchT(_().text.FromString("")).Ok());

    Issue("`MatchT` succeed when `Parser`'s contents are empty.");
    TEST_ExpectFalse(parser.MatchT(_().text.FromString("1")).Ok());
}

protected static function SubTest_MatchRawEmpty()
{
    local Parser parser;
    parser = new class'Parser';
    parser.InitializeRaw(_().text.StringToRaw("Just me."));
    Issue("`MatchRaw` does not succeed at empty input.");
    TEST_ExpectTrue(parser.MatchRaw(_().text.StringToRaw("")).Ok());

    parser.InitializeRaw(_().text.StringToRaw(""));
    Issue(  "`MatchRaw` does not succeed at empty input when filled" @
            "with empty content.");
    TEST_ExpectTrue(parser.MatchRaw(_().text.StringToRaw("")).Ok());

    Issue("`MatchRaw` succeed when `Parser`'s contents are empty.");
    TEST_ExpectFalse(parser.MatchRaw(_().text.StringToRaw("1")).Ok());
}

protected static function SubTest_MatchInvalid()
{
    local Parser parser;
    parser = new class'Parser';
    parser.Initialize("Something");
    Issue("`Match` succeeds in parsing where it should not.");
    TEST_ExpectFalse(parser.Match("Puri").Ok());

    Issue(  "`Match` accepts argument that should only be accepted in" @
            "case-insensitive mode, while doing case-sensitive parsing.");
    TEST_ExpectFalse(parser.Match("sOme").Ok());

    Issue("`Match` accepts argument that is longer than `Parser`'s contents");
    TEST_ExpectFalse(parser.Match("Something wicked.").Ok());

    parser.InitializeT(_().text.FromString("Something"));
    Issue("`MatchT` succeeds in parsing where it should not.");
    TEST_ExpectFalse(parser.MatchT(_().text.FromString("Puri")).Ok());

    Issue(  "`MatchT` accepts argument that should only be accepted in" @
            "case-insensitive mode, while doing case-sensitive parsing.");
    TEST_ExpectFalse(parser.MatchT(_().text.FromString("sOme")).Ok());

    Issue("`MatchT` accepts argument that is longer than `Parser`'s contents");
    TEST_ExpectFalse(
        parser.MatchT(_().text.FromString("Something wicked.")).Ok());
}

protected static function SubTest_MatchRawInvalid()
{
    local Parser parser;
    parser = new class'Parser';
    parser.InitializeRaw(_().text.StringToRaw("Something"));
    Issue("`MatchRaw` succeeds in parsing where it should not.");
    TEST_ExpectFalse(parser.MatchRaw(_().text.StringToRaw("Puri")).Ok());

    Issue(  "`MatchRaw` accepts argument that should only be accepted in" @
            "case-insensitive mode, while doing case-sensitive parsing.");
    TEST_ExpectFalse(parser.MatchRaw(_().text.StringToRaw("sOme")).Ok());

    Issue(  "`MatchRaw` accepts argument that is longer than" @
            "`Parser`'s contents");
    TEST_ExpectFalse(
        parser.MatchRaw(_().text.StringToRaw("Something wicked.")).Ok());
}

protected static function Test_GetLength()
{
    Context("Testing `Parser`'s `GetParsedLength()` function.");
    SubTest_GetParsedLength();
    Context("Testing `Parser`'s `GetRemainingLength()` function.");
    SubTest_GetRemainingLength();
}

protected static function SubTest_GetParsedLength()
{
    local Parser parser;
    parser = new class'Parser';
    parser.Initialize("AmazingUmbra");
    Issue(  "`GetParsedLength()` does not report zero right after" @
            "`Parser` initialization.");
    TEST_ExpectTrue(parser.GetParsedLength() == 0);

    Issue("`GetParsedLength()` reports incorrect amount after parsing.");
    parser.Match("Amazing");
    TEST_ExpectTrue(parser.GetParsedLength() == 7);

    Issue("`GetParsedLength()` reports incorrect amount after failed parsing.");
    TEST_ExpectTrue(parser.GetParsedLength() == 7);

    Issue(  "`GetParsedLength()` reports incorrect amount after" @
            "resetting `Parser`'s state.");
    parser.Confirm();
    parser.Match("UmNo").R();
    TEST_ExpectTrue(parser.GetParsedLength() == 7);

    Issue(  "`GetParsedLength()` reports incorrect amount after parsing" @
            "the whole source data.");
    parser.Match("Umbra");
    TEST_ExpectTrue(parser.GetParsedLength() == 12);
}

protected static function SubTest_GetRemainingLength()
{
    local Parser parser;
    parser = new class'Parser';
    parser.Initialize("AmazingUmbra");
    Issue(  "`GetRemainingLength()` does not report correct amount of" @
            "code points `Parser` initialization.");
    TEST_ExpectTrue(parser.GetRemainingLength() == 12);

    Issue("`GetRemainingLength()` reports incorrect amount after parsing.");
    parser.Match("Amazing");
    TEST_ExpectTrue(parser.GetRemainingLength() == 5);

    Issue(  "`GetRemainingLength()` reports incorrect amount after" @
            "failed parsing.");
    TEST_ExpectTrue(parser.GetRemainingLength() == 5);

    Issue(  "`GetRemainingLength()` reports incorrect amount after" @
            "resetting `Parser`'s state.");
    parser.Confirm();
    parser.Match("UmNo").R();
    TEST_ExpectTrue(parser.GetRemainingLength() == 5);

    Issue(  "`GetRemainingLength()` does not report zero after parsing" @
            "the whole source data.");
    parser.Match("Umbra");
    TEST_ExpectTrue(parser.GetRemainingLength() == 0);
}

protected static function Test_GetRemainder()
{
    Context("Testing `Parser`'s functionality of returning unparsed parts" @
            "of it's source.");
    SubTest_GetRemainderForRaw();
    SubTest_GetRemainder();
    SubTest_GetRemainderForText();
}

protected static function SubTest_GetRemainderForRaw()
{
    local Parser parser;
    parser = new class'Parser';
    parser.Initialize("String to test.");
    Issue(  "`GetRemainderRaw()` does not return full source" @
            "right after initialization.");
    TEST_ExpectTrue(CompareRaw( parser.GetRemainderRaw(),
                                _().text.StringToRaw("String to test.")));

    Issue(  "`GetRemainderRaw()` does not return correct result after" @
            "resetting `Parser`.");
    parser.Match("Error").R();
    TEST_ExpectTrue(CompareRaw( parser.GetRemainderRaw(),
                                _().text.StringToRaw("String to test.")));

    Issue(  "`GetRemainderRaw()` does not return correct result after" @
            "correctly parsing.");
    parser.Match("String").Skip();
    TEST_ExpectTrue(CompareRaw( parser.GetRemainderRaw(),
                                _().text.StringToRaw("to test.")));

    Issue(  "`GetRemainderRaw()` does not return empty Unicode code points" @
            "array after correctly parsing everything.");
    parser.Match("to test.");
    TEST_ExpectTrue(parser.GetRemainderRaw().length == 0);
}
//  TODO: test this shit with colors
protected static function SubTest_GetRemainder()
{
    local Parser parser;
    parser = new class'Parser';
    parser.Initialize("String to test.");
    Issue(  "`GetRemainder()` does not return full source" @
            "right after initialization.");
    TEST_ExpectTrue(parser.GetRemainder() == "String to test.");

    Issue(  "`GetRemainder()` does not return correct result after" @
            "resetting `Parser`.");
    parser.Match("Error").R();
    TEST_ExpectTrue(parser.GetRemainder() == "String to test.");

    Issue(  "`GetRemainder()` does not return correct result after" @
            "correctly parsing.");
    parser.Match("String").Skip();
    TEST_ExpectTrue(parser.GetRemainder() == "to test.");

    Issue(  "`GetRemainder()` does not return empty string after" @
            "correctly parsing everything.");
    parser.Match("to test.");
    TEST_ExpectTrue(parser.GetRemainder() == "");
}

protected static function SubTest_GetRemainderForText()
{
    local Parser parser;
    parser = new class'Parser';
    parser.Initialize("String to test.");
    Issue(  "`GetRemainderT()` does not return full source" @
            "right after initialization.");
    TEST_ExpectNotNone(parser.GetRemainderT());
    TEST_ExpectTrue(parser.GetRemainderT().IsEqualToString("String to test."));

    Issue(  "`GetRemainderT()` does not return correct result after" @
            "resetting `Parser`.");
    parser.Match("Error").R();
    TEST_ExpectNotNone(parser.GetRemainderT());
    TEST_ExpectTrue(parser.GetRemainderT().IsEqualToString("String to test."));

    Issue(  "`GetRemainderT()` does not return correct result after" @
            "correctly parsing.");
    parser.Match("String").Skip();
    TEST_ExpectNotNone(parser.GetRemainderT());
    TEST_ExpectTrue(parser.GetRemainderT().IsEqualToString("to test."));

    Issue(  "`GetRemainderT()` does not return empty `Text` after" @
            "correctly parsing everything.");
    parser.Match("to test.");
    TEST_ExpectNotNone(parser.GetRemainderT());
    TEST_ExpectTrue(parser.GetRemainderT().IsEmpty());
}

protected static function Test_EOF()
{
    local Parser parser;
    parser = new class'Parser';
    Context("Testing `Parser`'s `HasFinished()` function for EOF checks.");
    Issue(  "`Parser` says it has not finished parsing when it" @
            "was not even initialized.");
    TEST_ExpectTrue(parser.HasFinished());

    Issue(  "`Parser` says it has not finished parsing when it" @
            "was initialized with empty data.");
    TEST_ExpectTrue(parser.Initialize("").HasFinished());

    Issue(  "`Parser` says it has finished parsing when it" @
            "was just initialized with non-empty data.");
    TEST_ExpectFalse(parser.Initialize("Test").HasFinished());

    Issue("`Parser` says it has not finished parsing when it has.");
    TEST_ExpectTrue(parser.Match("Test").HasFinished());
}

protected static function Test_States()
{
    Context("Testing `Parser`'s functionality of saving and restoring states.");
    SubTest_StatesGeneral();
    SubTest_StatesRConfirm();
}

protected static function SubTest_StatesGeneral()
{
    local Parser                parser;
    local Parser.ParserState    okState, failState;
    parser = new class'Parser';

    Issue("`Parser` cannot revert states after successful parsing.");
    okState = parser.Initialize("ABCD").Match("A").GetCurrentState();
    TEST_ExpectTrue(parser.Match("B").Ok());
    TEST_ExpectTrue(parser.RestoreState(okState).Match("B").Ok());

    Issue("`Parser` cannot revert states after failed parsing.");
    TEST_ExpectFalse(parser.Match("Z").Ok());
    failState = parser.GetCurrentState();
    TEST_ExpectTrue(parser.RestoreState(okState).Match("B").Ok());

    Issue(  "`Parser` is not considered to have failed after being restored" @
            "to a failed state.");
    TEST_ExpectFalse(parser.RestoreState(failState).Ok());

    Issue("`IsStateValid()` claims that valid, non-failed state is invalid.");
    TEST_ExpectTrue(parser.IsStateValid(okState));

    Issue("`IsStateValid()` claims that valid, but failed state is invalid.");
    TEST_ExpectTrue(parser.IsStateValid(failState));

    Issue("`IsStateOk()` claims valid, non-failed state is failed.");
    TEST_ExpectTrue(parser.IsStateOk(okState));

    Issue("`IsStateOk()` claims valid, failed state is not failed.");
    TEST_ExpectFalse(parser.IsStateOk(failState));

    parser.Initialize("Redo");
    Issue("`IsStateValid()` claims that invalid state is valid.");
    TEST_ExpectFalse(parser.IsStateValid(okState));
    TEST_ExpectFalse(parser.IsStateValid(failState));

    Issue("`IsStateOk()` returns `true` for invalid state.");
    TEST_ExpectFalse(parser.IsStateOk(okState));
    TEST_ExpectFalse(parser.IsStateOk(failState));
}

protected static function SubTest_StatesRConfirm()
{
    local Parser                parser;
    local Parser.ParserState    confirmedState;
    parser = new class'Parser';

    Issue(  "`Parser`'s confirmed state is not set to initial by default.");
    TEST_ExpectTrue(parser.Initialize("Some words").Match("Some").Ok());
    TEST_ExpectTrue(parser.R().Match("Some").Ok());

    Issue(  "`Parser` cannot confirm valid state.");
    TEST_ExpectTrue(parser.Initialize("ABCD").Match("A").Ok());
    TEST_ExpectTrue(parser.Confirm());

    Issue(  "`Parser` cannot revert states after successful parsing with" @
            "`Confirm()` / `R()`.");
    TEST_ExpectTrue(parser.Match("B").Ok());
    TEST_ExpectTrue(parser.R().Match("B").Ok());

    parser.Match("Z");
    Issue("`Parser` can confirm failed state.");
    TEST_ExpectFalse(parser.Confirm());

    Issue(  "`Parser` cannot revert states after failed parsing with" @
            "`Confirm()` / `R()`.");
    TEST_ExpectTrue(parser.R().Match("B").Ok());

    Issue("`GetConfirmedState()` does not return confirmed actually state.");
    confirmedState = parser.GetConfirmedState();
    TEST_ExpectTrue(parser.R().GetCurrentState() == confirmedState);
}

protected static function Test_Skip()
{
    local int       skippedCount;
    local Parser    parser;
    parser = new class'Parser';
    parser.Initialize(default.stringWithWhitespaces);
    Context("Testing `Parser`'s functionality of skipping whitespace symbols.");
    Issue("`Parser` skips whitespace symbols without being told to.");
    TEST_ExpectFalse(parser.Match("Spaced").Ok());

    Issue(  "`Parser`'s function `Skip()` does not properly skip" @
            "whitespace symbols.");
    TEST_ExpectTrue(parser.R().Skip().Match("Spaced")
        .Skip().Match("out").Skip().Match("string").Skip().Match("here")
        .Skip().Match(",").Skip().Match("not").Skip().Match("much")
        .Skip().Match("to").Skip().Match("see.").Ok());

    Issue(  "`Parser`'s function `Skip()` does not properly count skipped" @
            "whitespace symbols.");
    parser.Initialize(default.stringWithWhitespaces);
    parser.Skip(skippedCount).Match("Spaced");
    TEST_ExpectTrue(skippedCount == 3);
    parser.Skip(skippedCount);
    TEST_ExpectTrue(skippedCount == 1);
    parser.Skip(skippedCount);
    TEST_ExpectTrue(skippedCount == 0);
}

protected static function Test_Whitespaces()
{
    Context("Testing parsing whitespace symbols.");
    SubTest_ParseWhitespaces();
    SubTest_ParseWhitespacesForRaw();
    SubTest_ParseWhitespacesForText();
}

protected static function SubTest_ParseWhitespaces()
{
    local Parser parser;
    local string result1, result2, result3;
    parser = new class'Parser';
    Issue("`MWhitespaces` does not correctly parse whitespace sequences.");
    parser.Initialize(default.stringWithWhitespaces);
    parser.MWhitespaces(result1).Match("Spaced").MWhitespaces(result2)
        .Match("out").MWhitespaces(result3);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1 == default.usedSpaces1);
    TEST_ExpectTrue(result2 == default.usedSpaces2);
    TEST_ExpectTrue(result3 == default.usedSpaces3);

    Issue(  "`MWhitespaces` does not successfully return empty `string` when" @
            "next symbol is a non-whitespace.");
    parser.MWhitespaces(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1 == "");

    Issue(  "`MWhitespaces` does not successfully return empty `string` when" @
            "parsing an empty string.");
    parser.Initialize("").MWhitespaces(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1 == "");

    Issue(  "`MWhitespaces` does not successfully return empty `string` after" @
            "reaching the end of an empty string.");
    parser.Initialize("padding").Match("padding").MWhitespaces(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1 == "");
}

protected static function SubTest_ParseWhitespacesForRaw()
{
    local Parser                parser;
    local array<Text.Character> result1, result2, result3;
    parser = new class'Parser';
    Issue("`MWhitespacesRaw` does not correctly parse whitespace sequences.");
    parser.Initialize(default.stringWithWhitespaces);
    parser.MWhitespacesRaw(result1).Match("Spaced").MWhitespacesRaw(result2)
        .Match("out").MWhitespacesRaw(result3);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(CompareRaw( result1,
                                _().text.StringToRaw(default.usedSpaces1)));
    TEST_ExpectTrue(CompareRaw( result2,
                                _().text.StringToRaw(default.usedSpaces2)));
    TEST_ExpectTrue(CompareRaw( result3,
                                _().text.StringToRaw(default.usedSpaces3)));

    Issue(  "`MWhitespacesRaw` does not successfully return empty array when" @
            "next symbol is a non-whitespace.");
    parser.MWhitespacesRaw(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1.length == 0);

    Issue(  "`MWhitespacesRaw` does not successfully return empty array when" @
            "parsing an empty string.");
    parser.Initialize("").MWhitespacesRaw(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1.length == 0);

    Issue(  "`MWhitespacesRaw` does not successfully return empty array" @
            "after reaching the end of an empty string.");
    parser.Initialize("padding").Match("padding").MWhitespacesRaw(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1.length == 0);
}

protected static function SubTest_ParseWhitespacesForText()
{
    local Parser parser;
    local Text result1, result2, result3;
    parser = new class'Parser';
    Issue("`MWhitespacesT` does not correctly parse whitespace sequences.");
    parser.Initialize(default.stringWithWhitespaces);
    parser.MWhitespacesT(result1).Match("Spaced").MWhitespacesT(result2)
        .Match("out").MWhitespacesT(result3);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1.IsEqualToString(default.usedSpaces1));
    TEST_ExpectTrue(result2.IsEqualToString(default.usedSpaces2));
    TEST_ExpectTrue(result3.IsEqualToString(default.usedSpaces3));

    Issue(  "`MWhitespacesT` does not successfully return empty `Text` when" @
            "next symbol is a non-whitespace.");
    parser.MWhitespacesT(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1.IsEmpty());

    Issue(  "`MWhitespacesT` does not successfully return empty `Text` when" @
            "parsing an empty string.");
    parser.Initialize("").MWhitespacesT(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1.IsEmpty());

    Issue(  "`MWhitespacesT` does not successfully return empty `Text` after" @
            "reaching the end of an empty string.");
    parser.Initialize("padding").Match("padding").MWhitespacesT(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1.IsEmpty());
}

protected static function Test_CharacterAndByte()
{
    local Parser            parser;
    local Text.Character    character1, character2, character3, character4;
    local byte              byteCodePoint;
    parser = new class'Parser';
    parser.Initialize(default.stringWithNonASCIISymbols);
    Context("Testing `Parser`'s functionality of reading code points.");
    Issue("`Parser` incorrectly reads code points.");
    parser.MCharacter(character1).MCharacter(character2)
        .MCharacter(character3).MCharacter(character4);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(character1.codePoint == 0x0053);
    TEST_ExpectTrue(character2.codePoint == 0x346C);
    TEST_ExpectTrue(character3.codePoint == 0x0423);
    TEST_ExpectTrue(character4.codePoint == 0x134C);

    parser.Initialize(default.stringWithNonASCIISymbols);
    Issue("`Parser` incorrectly reads code points as bytes.");
    parser.MByte(byteCodePoint);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(byteCodePoint == 0x53);

    Issue(  "`Parser` cannot correctly parse code points as `int`" @
            "after parsing them as a `byte`.");
    parser.MCharacter(character1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(character1.codePoint == 0x346C);

    Issue(  "`Parser` does not fail when trying to parse a" @
            "Unicode code point >255 as a byte.");
    parser.MByte(byteCodePoint);
    TEST_ExpectFalse(parser.Ok());
}

protected static function Test_Until()
{
    Context("Testing parsing until certain symbols.");
    SubTest_ParseUntil();
    SubTest_ParseUntilForRaw();
    SubTest_ParseUntilForText();
}

protected static function SubTest_ParseUntil()
{
    local Parser parser;
    local string result;
    parser = new class'Parser';
    Issue("`MUntil()` fails parsing until specified symbols.");
    parser.Initialize("come@me").MUntil(result, _().text.GetCharacter("@"));
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "come");

    Issue("`MUntil()` fails parsing until first whitespace.");
    parser.Initialize("Sokme words").MUntil(result,, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "Sokme");

    Issue("`MUntil()` fails parsing until first quotation mark.");
    parser.Initialize("@\"Quoted text\"").MUntil(result,,, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "@");

    Issue(  "`MUntil()` ignores specified symbol when also told to stop at" @
            "whitespace or a quotation mark symbol.");
    parser.Initialize("This is a so-called `Pro-gamer move`")
        .MUntil(result, _().text.GetCharacter("s"), true, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "Thi");

    Issue("`MUntil()` throws an error on empty string.");
    parser.Initialize("").MUntil(   result, _().text.GetCharacter("w"),
                                    true, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "");
}

protected static function SubTest_ParseUntilForRaw()
{
    local Parser                parser;
    local array<Text.Character> result;
    parser = new class'Parser';
    Issue("`MUntilRaw()` fails parsing until specified symbols.");
    parser.Initialize("come@me").MUntilRaw(result, _().text.GetCharacter("@"));
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("come")));

    Issue("`MUntilRaw()` fails parsing until first whitespace.");
    parser.Initialize("Sokme words").MUntilRaw(result,, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("Sokme")));

    Issue("`MUntilRaw()` fails parsing until first quotation mark.");
    parser.Initialize("@\"Quoted text\"").MUntilRaw(result,,, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("@")));

    Issue(  "`MUntilRaw()` ignores specified symbol when also told to stop at" @
            "whitespace or a quotation mark symbol.");
    parser.Initialize("This is a so-called `Pro-gamer move`")
        .MUntilRaw(result, _().text.GetCharacter("s"), true, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("Thi")));

    Issue("`MUntilRaw()` throws an error on empty string.");
    parser.Initialize("").MUntilRaw(result, _().text.GetCharacter("w"),
                                    true, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.length == 0);
}

protected static function SubTest_ParseUntilForText()
{
    local Parser    parser;
    local Text      result;
    parser = new class'Parser';
    Issue("`MUntilT()` fails parsing until specified symbols.");
    parser.Initialize("come@me").MUntilT(result, _().text.GetCharacter("@"));
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEqualToString("come"));

    Issue("`MUntilT()` fails parsing until first whitespace.");
    parser.Initialize("Sokme words").MUntilT(result,, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEqualToString("Sokme"));

    Issue("`MUntilT()` fails parsing until first quotation mark.");
    parser.Initialize("@\"Quoted text\"").MUntilT(result,,, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEqualToString("@"));

    Issue(  "`MUntilT()` ignores specified symbol when also told to stop at" @
            "whitespace or a quotation mark symbol.");
    parser.Initialize("This is a so-called `Pro-gamer move`")
        .MUntilT(result, _().text.GetCharacter("s"), true, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEqualToString("Thi"));

    Issue("`MUntilT()` throws an error on empty string.");
    parser.Initialize("").MUntilT(  result, _().text.GetCharacter("w"),
                                    true, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEmpty());
}

protected static function Test_ParseString()
{
    Context("Testing parsing simple strings.");
    SubTest_ParseStringSimple();
    SubTest_ParseStringForRawSimple();
    SubTest_ParseStringForTextSimple();
    Context("Testing parsing quoted strings.");
    SubTest_ParseStringComplex();
    SubTest_ParseStringForRawComplex();
    SubTest_ParseStringForTextComplex();
    SubTest_ParseStringLiteral();
    SubTest_ParseStringLiteralForRaw();
    SubTest_ParseStringLiteralForText();
    Context("Testing parsing escaped sequences.");
    SubTest_ParseEscapedSequence();
    SubTest_ParseStringEscapedSequencesAllAtOnce();
}

protected static function SubTest_ParseStringSimple()
{
    local Parser parser;
    local string result;
    parser = new class'Parser';
    Issue("`MString()` fails simple parsing.");
    parser.Initialize("My random!").MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "My");

    Issue("`MString()` incorrectly handles whitespace symbols by default.");
    parser.MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "");

    Issue("`MString()` incorrectly handles sequential passing.");
    parser.Skip().MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "random!");

    Issue(  "`MString()` incorrectly handles parsing after" @
            "consuming all input.");
    parser.Skip().MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "");
}

protected static function SubTest_ParseStringForRawSimple()
{
    local Parser                parser;
    local array<Text.Character> result;
    parser = new class'Parser';
    Issue("`MStringRaw()` fails simple parsing.");
    parser.Initialize("My random!").MStringRaw(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("My")));

    Issue("`MStringRaw()` incorrectly handles whitespace symbols by default.");
    parser.MStringRaw(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.length == 0);

    Issue("`MStringRaw()` incorrectly handles sequential passing.");
    parser.Skip().MStringRaw(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("random!")));

    Issue(  "`MStringRaw()` incorrectly handles parsing after" @
            "consuming all input.");
    parser.Skip().MStringRaw(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.length == 0);
}

protected static function SubTest_ParseStringForTextSimple()
{
    local Parser    parser;
    local Text      result;
    parser = new class'Parser';
    Issue("`MStringT()` fails simple parsing.");
    parser.Initialize("My random!").MStringT(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEqualToString("My"));

    Issue("`MStringT()` incorrectly handles whitespace symbols by default.");
    parser.MStringT(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEmpty());

    Issue("`MStringT()` incorrectly handles sequential passing.");
    parser.Skip().MStringT(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEqualToString("random!"));

    Issue(  "`MStringT()` incorrectly handles parsing after" @
            "consuming all input.");
    parser.Skip().MStringT(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEmpty());
}

protected static function SubTest_ParseStringComplex()
{
    local Parser parser;
    local string result;
    parser = new class'Parser';
    Issue("`MString()` fails simple parsing of quoted string.");
    parser.Initialize("\"My random!\" and more!").MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "My random!");

    Issue("`MString()` incorrectly handles whitespace symbols by default.");
    parser.MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "");

    Issue("`MString()` incorrectly handles sequential passing.");
    parser.Skip().MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "and");

    Issue("`MString()` does not recognize \' and ` as quote symbols.");
    parser.Initialize("\'Some string\'").MString(result);
    TEST_ExpectTrue(result == "Some string");
    parser.Initialize("`Other string`").MString(result);
    TEST_ExpectTrue(result == "Other string");

    Issue(  "`MString()` can not freely use (without escaping them)" @
            "quotation marks that were not used to open the string.");
    parser.Initialize("`Some\"string\'here...`").MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "Some\"string\'here...");
}

protected static function SubTest_ParseStringForRawComplex()
{
    local Parser                parser;
    local array<Text.Character> result;
    parser = new class'Parser';
    Issue("`MStringRaw()` fails simple parsing of quoted string.");
    parser.Initialize("\"My random!\" and more!").MStringRaw(result);
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("My random!")));

    Issue("`MStringRaw()` incorrectly handles whitespace symbols by default.");
    parser.MStringRaw(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.length == 0);

    Issue("`MStringRaw()` incorrectly handles sequential passing.");
    parser.Skip().MStringRaw(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("and")));

    Issue("`MStringRaw()` does not recognize \' and ` as quote symbols.");
    parser.Initialize("\'Some string\'").MStringRaw(result);
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("Some string")));
    parser.Initialize("`Other string`").MStringRaw(result);
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("Other string")));

    Issue(  "`MStringRaw()` can not freely use (without escaping them)" @
            "quotation marks that were not used to open the string.");
    parser.Initialize("`Some\"string\'here...`").MStringRaw(result);
    TEST_ExpectTrue(CompareRaw( result,
                                _().text.StringToRaw("Some\"string\'here...")));
}

protected static function SubTest_ParseStringForTextComplex()
{
    local Parser    parser;
    local Text      result;
    parser = new class'Parser';
    Issue("`MStringT()` fails simple parsing of quoted string.");
    parser.Initialize("\"My random!\" and more!").MStringT(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEqualToString("My random!"));

    Issue("`MStringT()` incorrectly handles whitespace symbols by default.");
    parser.MStringT(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEmpty());

    Issue("`MStringT()` incorrectly handles sequential passing.");
    parser.Skip().MStringT(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEqualToString("and"));

    Issue("`MStringT()` does not recognize \' and ` as quote symbols.");
    parser.Initialize("\'Some string\'").MStringT(result);
    TEST_ExpectTrue(result.IsEqualToString("Some string"));
    parser.Initialize("`Other string`").MStringT(result);
    TEST_ExpectTrue(result.IsEqualToString("Other string"));

    Issue(  "`MStringT()` can not freely use (without escaping them)" @
            "quotation marks that were not used to open the string.");
    parser.Initialize("`Some\"string\'here...`").MStringT(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEqualToString("Some\"string\'here..."));
}

protected static function SubTest_ParseStringLiteral()
{
    local Parser parser;
    local string result;
    parser = new class'Parser';
    Issue("`MStringLiteral()` fails simple parsing of quoted string.");
    parser.Initialize("\"My random!\" and more!").MStringLiteral(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "My random!");

    Issue(  "`MStringLiteral()` incorrectly able to parse strings," @
            "not enclosed in quotation marks.");
    parser.Skip().MStringLiteral(result);
    TEST_ExpectFalse(parser.Ok());

    Issue("`MStringLiteral()` does not recognize \' and ` as quote symbols.");
    parser.Initialize("\'Some string\'").MStringLiteral(result);
    TEST_ExpectTrue(result == "Some string");
    parser.Initialize("`Other string`").MStringLiteral(result);
    TEST_ExpectTrue(result == "Other string");

    Issue(  "`MStringLiteral()` can not freely use (without escaping them)" @
            "quotation marks that were not used to open the string.");
    parser.Initialize("`Some\"string\'here...`").MStringLiteral(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "Some\"string\'here...");
}

protected static function SubTest_ParseStringLiteralForRaw()
{
    local Parser                parser;
    local array<Text.Character> result;
    parser = new class'Parser';
    Issue("`MStringLiteralRaw()` fails simple parsing of quoted string.");
    parser.Initialize("\"My random!\" and more!").MStringLiteralRaw(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("My random!")));

    Issue(  "`MStringLiteralRaw()` incorrectly able to parse strings," @
            "not enclosed in quotation marks.");
    parser.Skip().MStringLiteralRaw(result);
    TEST_ExpectFalse(parser.Ok());

    Issue(  "`MStringLiteralRaw()` does not recognize \' and ` as" @
            "quote symbols.");
    parser.Initialize("\'Some string\'").MStringLiteralRaw(result);
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("Some string")));
    parser.Initialize("`Other string`").MStringLiteralRaw(result);
    TEST_ExpectTrue(CompareRaw(result, _().text.StringToRaw("Other string")));

    Issue(  "`MStringLiteralRaw()` can not freely use (without escaping them)" @
            "quotation marks that were not used to open the string.");
    parser.Initialize("`Some\"string\'here...`").MStringLiteralRaw(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(CompareRaw( result,
                                _().text.StringToRaw("Some\"string\'here...")));
}

protected static function SubTest_ParseStringLiteralForText()
{
    local Parser    parser;
    local Text      result;
    parser = new class'Parser';
    Issue("`MStringLiteralT()` fails simple parsing of quoted string.");
    parser.Initialize("\"My random!\" and more!").MStringLiteralT(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEqualToString("My random!"));

    Issue(  "`MStringLiteralT()` incorrectly able to parse strings," @
            "not enclosed in quotation marks.");
    parser.Skip().MStringLiteralT(result);
    TEST_ExpectFalse(parser.Ok());

    Issue("`MStringLiteralT()` does not recognize \' and ` as quote symbols.");
    parser.Initialize("\'Some string\'").MStringLiteralT(result);
    TEST_ExpectTrue(result.IsEqualToString("Some string"));
    parser.Initialize("`Other string`").MStringLiteralT(result);
    TEST_ExpectTrue(result.IsEqualToString("Other string"));

    Issue(  "`MStringLiteralT()` can not freely use (without escaping them)" @
            "quotation marks that were not used to open the string.");
    parser.Initialize("`Some\"string\'here...`").MStringLiteralT(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEqualToString("Some\"string\'here..."));
}

protected static function SubTest_ParseEscapedSequence()
{
    local Parser            parser;
    local Text.Character    result;
    parser = new class'Parser';
    Issue(  "`MString()` does not properly handle escaped characters in" @
            "quotes strings.");
    parser.Initialize("\\udc6d\\'\\\"\\n\\r\\t\\b\\f\\v\\U67\\h");
    TEST_ExpectTrue(parser.MEscapedSequence(result).Ok());
    TEST_ExpectTrue(result.codePoint == 0xdc6d); // code point: dc6d
    TEST_ExpectTrue(parser.MEscapedSequence(result).Ok());
    TEST_ExpectTrue(result.codePoint == 0x0027); // '
    TEST_ExpectTrue(parser.MEscapedSequence(result).Ok());
    TEST_ExpectTrue(result.codePoint == 0x0022); // "
    TEST_ExpectTrue(parser.MEscapedSequence(result).Ok());
    TEST_ExpectTrue(result.codePoint == 0x000a); // \n
    TEST_ExpectTrue(parser.MEscapedSequence(result).Ok());
    TEST_ExpectTrue(result.codePoint == 0x000d); // \r
    TEST_ExpectTrue(parser.MEscapedSequence(result).Ok());
    TEST_ExpectTrue(result.codePoint == 0x0009); // \t
    TEST_ExpectTrue(parser.MEscapedSequence(result).Ok());
    TEST_ExpectTrue(result.codePoint == 0x0008); // \b
    TEST_ExpectTrue(parser.MEscapedSequence(result).Ok());
    TEST_ExpectTrue(result.codePoint == 0x000c); // \f
    TEST_ExpectTrue(parser.MEscapedSequence(result).Ok());
    TEST_ExpectTrue(result.codePoint == 0x000b); // \v
    TEST_ExpectTrue(parser.MEscapedSequence(result).Ok());
    TEST_ExpectTrue(result.codePoint == 0x0067); // code point 0067
    TEST_ExpectTrue(parser.MEscapedSequence(result).Ok());
    TEST_ExpectTrue(result.codePoint == 0x0068); // h
}

protected static function SubTest_ParseStringEscapedSequencesAllAtOnce()
{
    local Parser                parser;
    local string                result;
    local array<Text.Character> rawData;
    parser = new class'Parser';
    Issue(  "`MString()` does not properly handle escaped characters in" @
            "quotes strings.");
    parser.Initialize("\"\\Udc6d\\'\\\"\\n\\r\\t\\b\\f\\v\\u67\\h\"");
    parser.MString(result);
    TEST_ExpectTrue(parser.Ok());
    rawData = _().text.StringToRaw(result);
    TEST_ExpectTrue(rawData[0].codePoint == 0xdc6d);   // code point: dc6d
    TEST_ExpectTrue(rawData[1].codePoint == 0x0027);   // '
    TEST_ExpectTrue(rawData[2].codePoint == 0x0022);   // "
    TEST_ExpectTrue(rawData[3].codePoint == 0x000a);   // \n
    TEST_ExpectTrue(rawData[4].codePoint == 0x000d);   // \r
    TEST_ExpectTrue(rawData[5].codePoint == 0x0009);   // \t
    TEST_ExpectTrue(rawData[6].codePoint == 0x0008);   // \b
    TEST_ExpectTrue(rawData[7].codePoint == 0x000c);   // \f
    TEST_ExpectTrue(rawData[8].codePoint == 0x000b);   // \v
    TEST_ExpectTrue(rawData[9].codePoint == 0x0067);   // code point 0067
    TEST_ExpectTrue(rawData[10].codePoint == 0x0068);  // h
}

protected static function Test_ParseInt()
{
    Context("Testing parsing integers.");
    SubTest_ParseSign();
    SubTest_ParseBase();
    SubTest_ParseUnsignedInt();
    SubTest_ParseUnsignedIntIncorrect();
    SubTest_ParseIntSimple();
    SubTest_ParseIntBases();
    SubTest_ParseIntBasesSpecified();
    SubTest_ParseIntBasesNegative();
}

protected static function SubTest_ParseSign()
{
    local Parser            parser;
    local Parser.ParsedSign result;
    parser = new class'Parser';
    Issue("`MSign()` can't properly parse + sign.");
    TEST_ExpectTrue(parser.Initialize("+").MSign(result).Ok());
    TEST_ExpectTrue(result == SIGN_Plus);

    Issue("`MSign()` can't properly parse - sign.");
    TEST_ExpectTrue(parser.Initialize("-").MSign(result).Ok());
    TEST_ExpectTrue(result == SIGN_Minus);

    Issue(  "`MSign()` can't properly parse non-sign symbol as" @
            "a lack of sign, even with `allowMissingSign = true`.");
    TEST_ExpectTrue(parser.Initialize("a").MSign(result, true).Ok());
    TEST_ExpectTrue(result == SIGN_Missing);

    Issue(  "`MSign()` can't properly parse empty input as" @
            "a lack of sign, even with `allowMissingSign = true`.");
    TEST_ExpectTrue(parser.Initialize("").MSign(result, true).Ok());
    TEST_ExpectTrue(result == SIGN_Missing);

    Issue(  "`MSign()` incorrectly parses non-sign symbol by default," @
            "with `allowMissingSign = false`.");
    TEST_ExpectFalse(parser.Initialize("a").MSign(result).Ok());

    Issue(  "`MSign()` incorrectly parses empty input by default," @
            "with `allowMissingSign = false`.");
    TEST_ExpectFalse(parser.Initialize("").MSign(result).Ok());
}

protected static function SubTest_ParseBase()
{
    local Parser    parser;
    local int       result;
    parser = new class'Parser';
    Issue("`MBase()` can't properly parse binary prefix.");
    TEST_ExpectTrue(parser.Initialize("0b").MBase(result).Ok());
    TEST_ExpectTrue(result == 2);

    Issue("`MBase()` can't properly parse octal prefix.");
    TEST_ExpectTrue(parser.Initialize("0o").MBase(result).Ok());
    TEST_ExpectTrue(result == 8);

    Issue("`MBase()` can't properly parse hexadecimal prefix.");
    TEST_ExpectTrue(parser.Initialize("0x").MBase(result).Ok());
    TEST_ExpectTrue(result == 16);

    Issue(  "`MBase()` does not treat lack of base prefix as a sign of" @
            "decimal system.");
    TEST_ExpectTrue(parser.Initialize("123").MBase(result).Ok());
    TEST_ExpectTrue(result == 10);

    Issue(  "`MBase()` does not treat non-digit input as a sign of" @
            "decimal system.");
    TEST_ExpectTrue(parser.Initialize("asdas").MBase(result).Ok());
    TEST_ExpectTrue(result == 10);

    Issue(  "`MBase()` does not treat empty input as a sign of" @
            "decimal system.");
    TEST_ExpectTrue(parser.Initialize("").MBase(result).Ok());
    TEST_ExpectTrue(result == 10);
}

protected static function SubTest_ParseUnsignedInt()
{
    local Parser    parser;
    local int       result;
    local int       readDigits;
    parser = new class'Parser';
    Issue("`MUnsignedInteger()` can't properly parse simple unsigned integer.");
    parser.Initialize("13").MUnsignedInteger(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 13);

    Issue(  "`MUnsignedInteger()` can't properly parse integer" @
            "written in non-standard base (13).");
    parser.Initialize("C1").MUnsignedInteger(result, 13,, readDigits);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 157);

    Issue("`MUnsignedInteger()` incorrectly reads amount of digits.");
    TEST_ExpectTrue(readDigits == 2);

    Issue(  "`MUnsignedInteger()` can't properly parse integer when" @
            "length is fixed.");
    parser.Initialize("12345").MUnsignedInteger(result,, 3);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 123);
}

protected static function SubTest_ParseUnsignedIntIncorrect()
{
    local Parser    parser;
    local int       result;
    local int       readDigitsEmpty;
    parser = new class'Parser';
    Issue(  "`MUnsignedInteger()` is successfully parsing" @
            "empty input, but it should not.");
    parser.Initialize("").MUnsignedInteger(result,,, readDigitsEmpty);
    TEST_ExpectFalse(parser.Ok());

    Issue(  "`MUnsignedInteger()` incorrectly reads amount of digits for" @
            "empty input.");
    TEST_ExpectTrue(readDigitsEmpty == 0);

    Issue(  "`MUnsignedInteger()` successfully parsing" @
            "insufficient input, but it should not.");
    parser.Initialize("123").MUnsignedInteger(result,, 4);
    TEST_ExpectFalse(parser.Ok());

    Issue(  "`MUnsignedInteger()` successfully parsing base it cannot.");
    parser.Initialize("e3").MUnsignedInteger(result,, 12);
    TEST_ExpectFalse(parser.Ok());
}

protected static function SubTest_ParseIntSimple()
{
    local Parser    parser;
    local int       result;
    parser = new class'Parser';
    Issue("`MInteger()` can't properly parse simple unsigned integer.");
    parser.Initialize("13").MInteger(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 13);

    Issue("`MInteger()` can't properly parse negative integer.");
    parser.Initialize("-7").MInteger(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == -7);

    Issue("`MInteger()` can't properly parse explicitly positive integer.");
    parser.Initialize("+21").MInteger(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 21);

    Issue(  "`MInteger()` incorrectly allows whitespaces between" @
            "sign and digits.");
    TEST_ExpectFalse(parser.Initialize("+ 4").MInteger(result).Ok());
    TEST_ExpectFalse(parser.Initialize("- 90").MInteger(result).Ok());

    Issue("`MInteger()` incorrectly consumes a dot after the integer");
    parser.Initialize("45.").MInteger(result).Match(".");
    TEST_ExpectTrue(parser.Ok());

    Issue(  "`MInteger()` incorrectly reports success after" @
            "empty integer input.");
    TEST_ExpectFalse(parser.Initialize("").MInteger(result).Ok());
    TEST_ExpectFalse(parser.Initialize(".345").MInteger(result).Ok());
    TEST_ExpectFalse(parser.Initialize(" 4").MInteger(result).Ok());
}

protected static function SubTest_ParseIntBases()
{
    local Parser parser;
    local int result;
    parser = new class'Parser';
    Issue(  "`MInteger()` can't properly parse integers in" @
            "hexadecimal system.");
    TEST_ExpectTrue(parser.Initialize("0x2a").MInteger(result).Ok());
    TEST_ExpectTrue(result == 0x2a);

    Issue(  "`MInteger()` can't properly parse integers in" @
            "octo system.");
    TEST_ExpectTrue(parser.Initialize("0o27").MInteger(result).Ok());
    TEST_ExpectTrue(result == 23);

    Issue(  "`MInteger()` can't properly parse integers in hexadecimal" @
            "system with uppercase letters.");
    TEST_ExpectTrue(parser.Initialize("0x10Bc").MInteger(result).Ok());
    TEST_ExpectTrue(result == 0x10bc);

    Issue("`MInteger()` can't properly parse integers in binary system.");
    TEST_ExpectTrue(parser.Initialize("0b011101").MInteger(result).Ok());
    TEST_ExpectTrue(result == 29);
}

protected static function SubTest_ParseIntBasesSpecified()
{
    local Parser parser;
    local int result;
    parser = new class'Parser';
    Issue(  "`MInteger()` can't properly parse integers in directly" @
            "specified, non-standard base.");
    TEST_ExpectTrue(parser.Initialize("10c").MInteger(result, 13).Ok());
    TEST_ExpectTrue(result == 181);

    Issue(  "`MInteger()` can't properly parse integers in directly" @
            "specified decimal system.");
    TEST_ExpectTrue(parser.Initialize("205").MInteger(result, 10).Ok());
    TEST_ExpectTrue(result == 205);

    Issue(  "`MInteger()` does not ignore octo-, hex- and binary- system" @
            "prefixes when base is directly specified.");
    TEST_ExpectTrue(parser.Initialize("0x104").MInteger(result, 10).Ok());
    TEST_ExpectTrue(result == 0);
    TEST_ExpectTrue(parser.Initialize("018").MInteger(result, 10).Ok());
    TEST_ExpectTrue(result == 18);
    parser.Initialize("0b01001010101").MInteger(result, 10);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 0);
}

protected static function SubTest_ParseIntBasesNegative()
{
    local Parser parser;
    local int result;
    parser = new class'Parser';
    Issue(  "`MInteger()` can't properly parse negative integers in" @
            "hexadecimal system.");
    TEST_ExpectTrue(parser.Initialize("-0x2a").MInteger(result).Ok());
    TEST_ExpectTrue(result == -0x2a);

    Issue(  "`MInteger()` can't properly parse negative integers in" @
            "hexadecimal system with uppercase letters.");
    TEST_ExpectTrue(parser.Initialize("-0x10Bc").MInteger(result).Ok());
    TEST_ExpectTrue(result == -0x10bc);

    Issue(  "`MInteger()` can't properly parse negative integers in" @
            "binary system.");
    TEST_ExpectTrue(parser.Initialize("-0b011101").MInteger(result).Ok());
    TEST_ExpectTrue(result == -29);

    Issue(  "`MInteger()` can't properly parse negative integers in" @
            "directly specified, non-standard base.");
    TEST_ExpectTrue(parser.Initialize("-10c").MInteger(result, 13).Ok());
    TEST_ExpectTrue(result == -181);

    Issue(  "`MInteger()` can't properly parse negative integers in" @
            "directly specified decimal system.");
    TEST_ExpectTrue(parser.Initialize("-205").MInteger(result, 10).Ok());
    TEST_ExpectTrue(result == -205);
}

protected static function Test_ParseNumber()
{
    Context("Testing parsing numbers (float).");
    SubTest_ParseNumberSimple();
    SubTest_ParseNumberIncorrectSimple();
    SubTest_ParseNumberF();
    SubTest_ParseNumberScientific();
}

protected static function SubTest_ParseNumberSimple()
{
    local Parser parser;
    local float result;
    parser = new class'Parser';
    Issue("`MNumber()` can't properly parse simple unsigned float.");
    parser.Initialize("3.14").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 3.14);

    Issue("`MNumber()` can't properly parse negative float.");
    parser.Initialize("-2.6").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == -2.6);

    Issue("`MNumber()` can't properly parse explicitly positive float.");
    parser.Initialize("+97.0043").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 97.0043);

    Issue(  "`MNumber()` incorrectly parses fractional part that starts" @
            "with zeroes.");
    parser.Initialize("0.0006").MNumber(result);

    Issue(  "`MNumber()` incorrectly does not consume a dot after" @
            "the integer part, if the fractional part is missing.");
    parser.Initialize("45.str");
    parser.MNumber(result);
    parser.Match("str");
    TEST_ExpectTrue(parser.Ok());
}

protected static function SubTest_ParseNumberIncorrectSimple()
{
    local Parser parser;
    local float result;
    parser = new class'Parser';
    Issue(  "`MNumber()` incorrectly allows whitespaces between" @
            "sign, digits and dot.");
    TEST_ExpectFalse(parser.Initialize("- 90").MNumber(result).Ok());
    parser.Initialize("4. 6").MNumber(result).Skip().Match("6");
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 4);
    parser.Initialize("34 .").MNumber(result).Skip().Match(".");
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 34);

    Issue(  "`ParseNumber()` incorrectly reports success after" @
            "an empty input.");
    TEST_ExpectFalse(parser.Initialize("").MNumber(result).Ok());
    TEST_ExpectFalse(parser.Initialize(" 4").MNumber(result).Ok());
}

protected static function SubTest_ParseNumberF()
{
    local Parser parser;
    local float num1, num2;
    parser = new class'Parser';
    Issue("`MNumber()` does not consume float's \"f\" suffix.");
    parser.Initialize("2fstr").MNumber(num1).Match("str");
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(num1 == 2);
    parser.Initialize("2.f3.7fstr").MNumber(num1)
        .MNumber(num2).Match("str");
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(num1 == 2);
    TEST_ExpectTrue(num2 == 3.7);

    Issue("`MNumber()` consumes float's \"f\" suffix after whitespace.");
    parser.Initialize("35.8 f")
        .MNumber(num1)
        .Skip()
        .Match("f");
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(num1 == 35.8);
}

protected static function SubTest_ParseNumberScientific()
{
    local Parser parser;
    local float result;
    parser = new class'Parser';
    Issue(  "`MNumber()` can't properly parse float in scientific format" @
            "with lower \"e\".");
    parser.Initialize("3.14e2").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 314);

    Issue(  "`MNumber()` can't properly parse float in scientific format" @
            "with upper \"E\".");
    parser.Initialize("0.4E1").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 4);

    Issue(  "`MNumber()` can't properly parse float in scientific format" @
            "with a sign specified.");
    parser.Initialize("2.56e+3").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 2560);
    parser.Initialize("7.8E-2").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 0.078);

    Issue(  "`MNumber()` incorrectly reports success when exponent number" @
            "is missing");
    TEST_ExpectFalse(parser.Initialize("0.054e").MNumber(result).Ok());
    TEST_ExpectFalse(parser.Initialize("2.56e+str").MNumber(result).Ok());
}

defaultproperties
{
    caseName = "Parser"
    stringWithWhitespaces       = "   Spaced out	string here	, not  much  to see."
    usedSpaces1                 = "   "
    usedSpaces2                 = " "
    usedSpaces3                 = "	"
    stringWithNonASCIISymbols   = "S㑬Уፌ!"
}