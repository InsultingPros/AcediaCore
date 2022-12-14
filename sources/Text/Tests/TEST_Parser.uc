/**
 *  Set of tests for `Parser` class.
 *      Copyright 2020-2022 Anton Tarasenko
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
    dependson(BaseText)
    dependson(Parser)
    abstract;

var const string stringWithNonASCIISymbols;
var const string stringWithWhitespaces;
var const string stringWithGoodBadNames;
var const string usedSpaces1, usedSpaces2, usedSpaces3;

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
    Test_MatchName();
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
}

protected static function SubTest_MatchSimple()
{
    local Parser parser;
    parser = Parser(__().memory.Allocate(class'Parser'));
    parser.InitializeS("PuripuriPerurun");
    Issue("`MatchS()` can't parse prefix in a simplest case.");
    TEST_ExpectTrue(parser.MatchS("Puri").Ok());

    Issue("`MatchS()` can't perform two parsings in a row.");
    TEST_ExpectTrue(parser.R().MatchS("Puri").MatchS("puriPerur").Ok());

    Issue("`MatchS()` doesn't properly parse in a case-insensitive mode.");
    TEST_ExpectTrue(parser.R().MatchS("pURi", SCASE_INSENSITIVE).Ok());
    TEST_ExpectTrue(parser.R().MatchS("Puri")
        .MatchS("PuRiPeRur", SCASE_INSENSITIVE).Ok());

    parser.Initialize(__().text.FromString("PuripuriPerurun"));
    Issue("`Match()` does not return back the caller parser.");
    TEST_ExpectTrue(parser.Match(__().text.FromString("Puri")) == parser);

    Issue("`Match()` can't parse prefix in a simplest case.");
    TEST_ExpectTrue(parser.R().Match(__().text.FromString("Puri")).Ok());

    Issue("`Match()` can't perform two parsings in a row.");
    TEST_ExpectTrue(parser.R()
        .Match(__().text.FromString("Puri"))
        .Match(__().text.FromString("puriPerur"))
        .Ok());

    Issue("`Match()` doesn't properly parse in a case-insensitive mode.");
    TEST_ExpectTrue(parser.R()
        .Match(__().text.FromString("pURi"), SCASE_INSENSITIVE).Ok());
    TEST_ExpectTrue(parser.R()
        .Match(__().text.FromString("Puri"))
        .Match(__().text.FromString("PuRiPeRur"), SCASE_INSENSITIVE)
        .Ok());
}

protected static function SubTest_MatchEmpty()
{
    local Parser parser;
    parser = Parser(__().memory.Allocate(class'Parser'));
    parser.InitializeS("Just me.");
    Issue("`MatchS()` does not succeed at empty input.");
    TEST_ExpectTrue(parser.MatchS("").Ok());

    parser.InitializeS("");
    Issue(  "`MatchS()` does not succeed at empty input when filled" @
            "with empty content.");
    TEST_ExpectTrue(parser.MatchS("").Ok());

    Issue("`MatchS()` succeed when `Parser`'s contents are empty.");
    TEST_ExpectFalse(parser.MatchS("1").Ok());

    parser.Initialize(__().text.FromString("Just me."));
    Issue("`Match()` does not succeed at empty input.");
    TEST_ExpectTrue(parser.Match(__().text.FromString("")).Ok());

    parser.Initialize(__().text.FromString(""));
    Issue(  "`Match()` does not succeed at empty input when filled" @
            "with empty content.");
    TEST_ExpectTrue(parser.Match(__().text.FromString("")).Ok());

    Issue("`Match()` succeed when `Parser`'s contents are empty.");
    TEST_ExpectFalse(parser.Match(__().text.FromString("1")).Ok());
}

protected static function SubTest_MatchInvalid()
{
    local Parser parser;
    parser = Parser(__().memory.Allocate(class'Parser'));
    parser.InitializeS("Something");
    Issue("`MatchS()` succeeds in parsing where it should not.");
    TEST_ExpectFalse(parser.MatchS("Puri").Ok());

    Issue(  "`MatchS()` accepts argument that should only be accepted in" @
            "case-insensitive mode, while doing case-sensitive parsing.");
    TEST_ExpectFalse(parser.MatchS("sOme").Ok());

    Issue("`MatchS()` accepts argument that is longer than"
        @ "`Parser`'s contents");
    TEST_ExpectFalse(parser.MatchS("Something wicked.").Ok());

    parser.Initialize(__().text.FromString("Something"));
    Issue("`Match()` succeeds in parsing where it should not.");
    TEST_ExpectFalse(parser.Match(__().text.FromString("Puri")).Ok());

    Issue(  "`Match()` accepts argument that should only be accepted in" @
            "case-insensitive mode, while doing case-sensitive parsing.");
    TEST_ExpectFalse(parser.Match(__().text.FromString("sOme")).Ok());

    Issue("`Match()` accepts argument that is longer than `Parser`'s contents");
    TEST_ExpectFalse(
        parser.Match(__().text.FromString("Something wicked.")).Ok());
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
    parser = Parser(__().memory.Allocate(class'Parser'));
    parser.InitializeS("AmazingUmbra");
    Issue(  "`GetParsedLength()` does not report zero right after" @
            "`Parser` initialization.");
    TEST_ExpectTrue(parser.GetParsedLength() == 0);

    Issue("`GetParsedLength()` reports incorrect amount after parsing.");
    parser.MatchS("Amazing");
    TEST_ExpectTrue(parser.GetParsedLength() == 7);

    Issue("`GetParsedLength()` reports incorrect amount after failed parsing.");
    TEST_ExpectTrue(parser.GetParsedLength() == 7);

    Issue(  "`GetParsedLength()` reports incorrect amount after" @
            "resetting `Parser`'s state.");
    parser.Confirm();
    parser.MatchS("UmNo").R();
    TEST_ExpectTrue(parser.GetParsedLength() == 7);

    Issue(  "`GetParsedLength()` reports incorrect amount after parsing" @
            "the whole source data.");
    parser.MatchS("Umbra");
    TEST_ExpectTrue(parser.GetParsedLength() == 12);
}

protected static function SubTest_GetRemainingLength()
{
    local Parser parser;
    parser = Parser(__().memory.Allocate(class'Parser'));
    parser.InitializeS("AmazingUmbra");
    Issue(  "`GetRemainingLength()` does not report correct amount of" @
            "code points `Parser` initialization.");
    TEST_ExpectTrue(parser.GetRemainingLength() == 12);

    Issue("`GetRemainingLength()` reports incorrect amount after parsing.");
    parser.MatchS("Amazing");
    TEST_ExpectTrue(parser.GetRemainingLength() == 5);

    Issue(  "`GetRemainingLength()` reports incorrect amount after" @
            "failed parsing.");
    TEST_ExpectTrue(parser.GetRemainingLength() == 5);

    Issue(  "`GetRemainingLength()` reports incorrect amount after" @
            "resetting `Parser`'s state.");
    parser.Confirm();
    parser.MatchS("UmNo").R();
    TEST_ExpectTrue(parser.GetRemainingLength() == 5);

    Issue(  "`GetRemainingLength()` does not report zero after parsing" @
            "the whole source data.");
    parser.MatchS("Umbra");
    TEST_ExpectTrue(parser.GetRemainingLength() == 0);
}

protected static function Test_GetRemainder()
{
    Context("Testing `Parser`'s functionality of returning unparsed parts" @
            "of it's source.");
    SubTest_GetRemainder();
    SubTest_GetRemainderForText();
}

protected static function SubTest_GetRemainder()
{
    local Parser parser;
    parser = Parser(__().memory.Allocate(class'Parser'));
    parser.InitializeS("String to test.");
    Issue(  "`GetRemainderS()` does not return full source" @
            "right after initialization.");
    TEST_ExpectTrue(parser.GetRemainderS() == "String to test.");

    Issue(  "`GetRemainderS()` does not return correct result after" @
            "resetting `Parser`.");
    parser.MatchS("Error").R();
    TEST_ExpectTrue(parser.GetRemainderS() == "String to test.");

    Issue(  "`GetRemainderS()` does not return correct result after" @
            "correctly parsing.");
    parser.MatchS("String").Skip();
    TEST_ExpectTrue(parser.GetRemainderS() == "to test.");

    Issue(  "`GetRemainderS()` does not return empty string after" @
            "correctly parsing everything.");
    parser.MatchS("to test.");
    TEST_ExpectTrue(parser.GetRemainderS() == "");
}

protected static function SubTest_GetRemainderForText()
{
    local Parser parser;
    parser = Parser(__().memory.Allocate(class'Parser'));
    parser.InitializeS("String to test.");
    Issue(  "`GetRemainder()` does not return full source" @
            "right after initialization.");
    TEST_ExpectNotNone(parser.GetRemainder());
    TEST_ExpectTrue(parser.GetRemainder()
        .CompareToString("String to test."));

    Issue(  "`GetRemainder()` does not return correct result after" @
            "resetting `Parser`.");
    parser.MatchS("Error").R();
    TEST_ExpectNotNone(parser.GetRemainder());
    TEST_ExpectTrue(parser.GetRemainder()
        .CompareToString("String to test."));

    Issue(  "`GetRemainder()` does not return correct result after" @
            "correctly parsing.");
    parser.MatchS("String").Skip();
    TEST_ExpectNotNone(parser.GetRemainder());
    TEST_ExpectTrue(parser.GetRemainder().CompareToString("to test."));

    Issue(  "`GetRemainder()` does not return empty `Text` after" @
            "correctly parsing everything.");
    parser.MatchS("to test.");
    TEST_ExpectNotNone(parser.GetRemainder());
    TEST_ExpectTrue(parser.GetRemainder().IsEmpty());
}

protected static function Test_EOF()
{
    local Parser parser;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Context("Testing `Parser`'s `HasFinished()` function for EOF checks.");
    Issue(  "`Parser` says it has not finished parsing when it" @
            "was not even initialized.");
    TEST_ExpectTrue(parser.HasFinished());

    Issue(  "`Parser` says it has not finished parsing when it" @
            "was initialized with empty data.");
    TEST_ExpectTrue(parser.InitializeS("").HasFinished());

    Issue(  "`Parser` says it has finished parsing when it" @
            "was just initialized with non-empty data.");
    TEST_ExpectFalse(parser.InitializeS("Test").HasFinished());

    Issue("`Parser` says it has not finished parsing when it has.");
    TEST_ExpectTrue(parser.MatchS("Test").HasFinished());
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
    parser = Parser(__().memory.Allocate(class'Parser'));

    Issue("`Parser` cannot revert states after successful parsing.");
    okState = parser.InitializeS("ABCD").MatchS("A").GetCurrentState();
    TEST_ExpectTrue(parser.MatchS("B").Ok());
    TEST_ExpectTrue(parser.RestoreState(okState).MatchS("B").Ok());

    Issue("`Parser` cannot revert states after failed parsing.");
    TEST_ExpectFalse(parser.MatchS("Z").Ok());
    failState = parser.GetCurrentState();
    TEST_ExpectTrue(parser.RestoreState(okState).MatchS("B").Ok());

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

    parser.InitializeS("Redo");
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
    parser = Parser(__().memory.Allocate(class'Parser'));

    Issue(  "`Parser`'s confirmed state is not set to initial by default.");
    TEST_ExpectTrue(parser.InitializeS("Some words").MatchS("Some").Ok());
    TEST_ExpectTrue(parser.R().MatchS("Some").Ok());

    Issue(  "`Parser` cannot confirm valid state.");
    TEST_ExpectTrue(parser.InitializeS("ABCD").MatchS("A").Ok());
    TEST_ExpectTrue(parser.Confirm());

    Issue(  "`Parser` cannot revert states after successful parsing with" @
            "`Confirm()` / `R()`.");
    TEST_ExpectTrue(parser.MatchS("B").Ok());
    TEST_ExpectTrue(parser.R().MatchS("B").Ok());

    parser.MatchS("Z");
    Issue("`Parser` can confirm failed state.");
    TEST_ExpectFalse(parser.Confirm());

    Issue(  "`Parser` cannot revert states after failed parsing with" @
            "`Confirm()` / `R()`.");
    TEST_ExpectTrue(parser.R().MatchS("B").Ok());

    Issue("`GetConfirmedState()` does not return confirmed actually state.");
    confirmedState = parser.GetConfirmedState();
    TEST_ExpectTrue(parser.R().GetCurrentState() == confirmedState);
}

protected static function Test_Skip()
{
    local int       skippedCount;
    local Parser    parser;
    parser = Parser(__().memory.Allocate(class'Parser'));
    parser.InitializeS(default.stringWithWhitespaces);
    Context("Testing `Parser`'s functionality of skipping whitespace symbols.");
    Issue("`Parser` skips whitespace symbols without being told to.");
    TEST_ExpectFalse(parser.MatchS("Spaced").Ok());

    Issue("`Parser` skips non-whitespace symbols.");
    TEST_ExpectTrue(parser.R().Skip().MatchS("Spaced").Skip().Skip()
        .MatchS("out").Skip().Ok());

    Issue(  "`Parser`'s function `Skip()` does not properly skip" @
            "whitespace symbols.");
    TEST_ExpectTrue(parser.R().Skip().MatchS("Spaced")
        .Skip().MatchS("out").Skip().MatchS("string").Skip().MatchS("here")
        .Skip().MatchS(",").Skip().MatchS("not").Skip().MatchS("much")
        .Skip().MatchS("to").Skip().MatchS("see.").Ok());

    Issue(  "`Parser`'s function `Skip()` does not properly count skipped" @
            "whitespace symbols.");
    parser.InitializeS(default.stringWithWhitespaces);
    parser.Skip(skippedCount).MatchS("Spaced");
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
    SubTest_ParseWhitespacesForText();
}

protected static function SubTest_ParseWhitespaces()
{
    local Parser parser;
    local string result1, result2, result3;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MWhitespacesS()` does not correctly parse whitespace sequences.");
    parser.InitializeS(default.stringWithWhitespaces);
    parser.MWhitespacesS(result1).MatchS("Spaced").MWhitespacesS(result2)
        .MatchS("out").MWhitespacesS(result3);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1 == default.usedSpaces1);
    TEST_ExpectTrue(result2 == default.usedSpaces2);
    TEST_ExpectTrue(result3 == default.usedSpaces3);

    Issue(  "`MWhitespacesS()` does not successfully return empty `string`"
        @   "when next symbol is a non-whitespace.");
    parser.MWhitespacesS(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1 == "");

    Issue(  "`MWhitespacesS()` does not successfully return empty `string`"
        @   "whenparsing an empty string.");
    parser.InitializeS("").MWhitespacesS(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1 == "");

    Issue(  "`MWhitespacesS()` does not successfully return empty `string`"
        @   "after reaching the end of an empty string.");
    parser.InitializeS("padding").MatchS("padding").MWhitespacesS(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1 == "");
}

protected static function SubTest_ParseWhitespacesForText()
{
    local Parser parser;
    local MutableText result1, result2, result3;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MWhitespaces()` does not correctly parse whitespace sequences.");
    parser.InitializeS(default.stringWithWhitespaces);
    parser.MWhitespaces(result1).MatchS("Spaced").MWhitespaces(result2)
        .MatchS("out").MWhitespaces(result3);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1.CompareToString(default.usedSpaces1));
    TEST_ExpectTrue(result2.CompareToString(default.usedSpaces2));
    TEST_ExpectTrue(result3.CompareToString(default.usedSpaces3));

    Issue(  "`MWhitespaces()` does not successfully return empty `Text` when" @
            "next symbol is a non-whitespace.");
    parser.MWhitespaces(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1.IsEmpty());

    Issue(  "`MWhitespaces()` does not successfully return empty `Text` when" @
            "parsing an empty string.");
    parser.InitializeS("").MWhitespaces(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1.IsEmpty());

    Issue(  "`MWhitespaces()` does not successfully return empty `Text` after" @
            "reaching the end of an empty string.");
    parser.InitializeS("padding").MatchS("padding").MWhitespaces(result1);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result1.IsEmpty());
}

protected static function Test_CharacterAndByte()
{
    local Parser                parser;
    local MutableText.Character character1, character2, character3, character4;
    local byte                  byteCodePoint;
    parser = Parser(__().memory.Allocate(class'Parser'));
    parser.InitializeS(default.stringWithNonASCIISymbols);
    Context("Testing `Parser`'s functionality of reading code points.");
    Issue("`Parser` incorrectly reads code points.");
    parser.MCharacter(character1).MCharacter(character2)
        .MCharacter(character3).MCharacter(character4);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(character1.codePoint == 0x0053);
    TEST_ExpectTrue(character2.codePoint == 0x346C);
    TEST_ExpectTrue(character3.codePoint == 0x0423);
    TEST_ExpectTrue(character4.codePoint == 0x134C);

    parser.InitializeS(default.stringWithNonASCIISymbols);
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
    SubTest_ParseUntilForText();
    SubTest_UntilManyNormal();
    SubTest_UntilManySeparators();
    SubTest_UntilManyNormalForText();
    SubTest_UntilManySeparatorsForText();
}

protected static function SubTest_ParseUntil()
{
    local Parser parser;
    local string result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MUntilS()` fails parsing until specified symbols.");
    parser.InitializeS("come@me").MUntilS(result, __().text.GetCharacter("@"));
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "come");

    Issue("`MUntilS()` fails parsing until first whitespace.");
    parser.InitializeS("Sokme words").MUntilS(result,, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "Sokme");

    Issue("`MUntilS()` fails parsing until first quotation mark.");
    parser.InitializeS("@\"Quoted text\"").MUntilS(result,,, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "@");

    Issue(  "`MUntilS()` ignores specified symbol when also told to stop at" @
            "whitespace or a quotation mark symbol.");
    parser.InitializeS("This is a so-called `Pro-gamer move`")
        .MUntilS(result, __().text.GetCharacter("s"), true, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "Thi");

    Issue("`MUntilS()` throws an error on empty string.");
    parser.InitializeS("").MUntilS(   result, __().text.GetCharacter("w"),
                                    true, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "");
}

protected static function SubTest_ParseUntilForText()
{
    local Parser        parser;
    local MutableText   result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MUntil()` fails parsing until specified symbols.");
    parser.InitializeS("come@me").MUntil(result, __().text.GetCharacter("@"));
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.CompareToString("come"));

    Issue("`MUntil()` fails parsing until first whitespace.");
    parser.InitializeS("Sokme words").MUntil(result,, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.CompareToString("Sokme"));

    Issue("`MUntil()` fails parsing until first quotation mark.");
    parser.InitializeS("@\"Quoted text\"").MUntil(result,,, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.CompareToString("@"));

    Issue(  "`MUntil()` ignores specified symbol when also told to stop at" @
            "whitespace or a quotation mark symbol.");
    parser.InitializeS("This is a so-called `Pro-gamer move`")
        .MUntil(result, __().text.GetCharacter("s"), true, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.CompareToString("Thi"));

    Issue("`MUntil()` throws an error on empty string.");
    parser.InitializeS("").MUntil(  result, __().text.GetCharacter("w"),
                                    true, true);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEmpty());

    Issue("`MUntil()` does not create new `Text` when parser is in"
        @ "a failed state.");
    result = none;
    parser.InitializeS("not a string literal").Fail().MStringLiteral(result);
    TEST_ExpectNotNone(result);
}

protected static function SubTest_UntilManyNormal()
{
    local array<BaseText>   separators;
    local Parser            parser;
    local string            result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MUntilManyS()` fails parsing until specified symbol sequences.");
    separators = __().text.Parts(__().text.FromString("/,/;;/,;;"));
    parser.InitializeS("word,and,;;another,,words;;ye;s!");
    parser.MUntilManyS(result, separators).MatchS(",");
    TEST_ExpectTrue(result == "word");
    parser.MUntilManyS(result, separators).MatchS(",");
    TEST_ExpectTrue(result == "and");
    parser.MUntilManyS(result, separators).MatchS(";;");
    TEST_ExpectTrue(result == "");
    parser.MUntilManyS(result, separators).MatchS(",");
    TEST_ExpectTrue(result == "another");
    parser.MUntilManyS(result, separators).MatchS(",");
    TEST_ExpectTrue(result == "");
    parser.MUntilManyS(result, separators).MatchS(";;");
    TEST_ExpectTrue(result == "words");
    parser.MUntilManyS(result, separators);
    TEST_ExpectTrue(result == "ye;s!");
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(parser.HasFinished());
}

protected static function SubTest_UntilManySeparators()
{
    local array<BaseText>   separators;
    local Parser            parser;
    local string            result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MUntilManyS()` fails parsing until specified symbol sequences while"
        @ "matching whitespaces/quotes.");
    separators = __().text.Parts(__().text.FromString("/;"));
    parser.InitializeS("word and another; 'words' yes!");
    parser.MUntilManyS(result, separators, true, true).MatchS(" ");
    TEST_ExpectTrue(result == "word");
    parser.MUntilManyS(result, separators, true, true).MatchS(" ");
    TEST_ExpectTrue(result == "and");
    parser.MUntilManyS(result, separators, true, true).MatchS(";");
    TEST_ExpectTrue(result == "another");
    parser.MUntilManyS(result, separators, true, true).MatchS(" ");
    TEST_ExpectTrue(result == "");
    parser.MUntilManyS(result, separators, true, true).MatchS("'word");
    TEST_ExpectTrue(result == "");
    parser.MUntilManyS(result, separators, true, true).MatchS("'");
    TEST_ExpectTrue(result == "s");
    parser.MUntilManyS(result, separators, true, true).MatchS(" ");
    TEST_ExpectTrue(result == "");
    parser.MUntilManyS(result, separators, true, true);
    TEST_ExpectTrue(result == "yes!");
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(parser.HasFinished());
}

protected static function SubTest_UntilManyNormalForText()
{
    local array<BaseText>   separators;
    local Parser            parser;
    local MutableText       result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MUntilMany()` fails parsing until specified symbol sequences.");
    separators = __().text.Parts(__().text.FromString("/,/;;/,;;"));
    parser.InitializeS("word,and,;;another,,words;;ye;s!");
    parser.MUntilMany(result, separators).MatchS(",");
    TEST_ExpectTrue(result.CompareToString("word"));
    parser.MUntilMany(result, separators).MatchS(",");
    TEST_ExpectTrue(result.CompareToString("and"));
    parser.MUntilMany(result, separators).MatchS(";;");
    TEST_ExpectTrue(result.CompareToString(""));
    parser.MUntilMany(result, separators).MatchS(",");
    TEST_ExpectTrue(result.CompareToString("another"));
    parser.MUntilMany(result, separators).MatchS(",");
    TEST_ExpectTrue(result.CompareToString(""));
    parser.MUntilMany(result, separators).MatchS(";;");
    TEST_ExpectTrue(result.CompareToString("words"));
    parser.MUntilMany(result, separators);
    TEST_ExpectTrue(result.CompareToString("ye;s!"));
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(parser.HasFinished());
}

protected static function SubTest_UntilManySeparatorsForText()
{
    local array<BaseText>   separators;
    local Parser            parser;
    local MutableText       result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MUntilMany()` fails parsing until specified symbol sequences while"
        @ "matching whitespaces/quotes.");
    separators = __().text.Parts(__().text.FromString("/;"));
    parser.InitializeS("word and another; 'words' yes!");
    parser.MUntilMany(result, separators, true, true).MatchS(" ");
    TEST_ExpectTrue(result.CompareToString("word"));
    parser.MUntilMany(result, separators, true, true).MatchS(" ");
    TEST_ExpectTrue(result.CompareToString("and"));
    parser.MUntilMany(result, separators, true, true).MatchS(";");
    TEST_ExpectTrue(result.CompareToString("another"));
    parser.MUntilMany(result, separators, true, true).MatchS(" ");
    TEST_ExpectTrue(result.CompareToString(""));
    parser.MUntilMany(result, separators, true, true).MatchS("'word");
    TEST_ExpectTrue(result.CompareToString(""));
    parser.MUntilMany(result, separators, true, true).MatchS("'");
    TEST_ExpectTrue(result.CompareToString("s"));
    parser.MUntilMany(result, separators, true, true).MatchS(" ");
    TEST_ExpectTrue(result.CompareToString(""));
    parser.MUntilMany(result, separators, true, true);
    TEST_ExpectTrue(result.CompareToString("yes!"));
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(parser.HasFinished());
}

protected static function Test_MatchName()
{
    Context("Testing `Parser`'s \"name\"-matching functions.");
    SubTest_MatchNameSuccess();
    SubTest_MatchNameFailure();
}

protected static function SubTest_MatchNameSuccess()
{
    local Parser        parser;
    local string        resultS;
    local MutableText   result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MNameS()` can't parse valid names.");
    parser.InitializeS("Just a7b sentence.");
    parser.MNameS(resultS);
    TEST_ExpectTrue(resultS == "Just");
    parser.Skip().MNameS(resultS);
    TEST_ExpectTrue(resultS == "a7b");
    parser.Skip().MNameS(resultS);
    TEST_ExpectTrue(resultS == "sentence");
    TEST_ExpectTrue(parser.Ok());

    Issue("`MName()` can't parse valid names.");
    parser.Initialize(__().text.FromString("Just a7b sentence."));
    parser.MName(result);
    TEST_ExpectTrue(result.ToString() == "Just");
    parser.Skip().MName(result);
    TEST_ExpectTrue(result.ToString() == "a7b");
    parser.Skip().MName(result);
    TEST_ExpectTrue(result.ToString() == "sentence");
    TEST_ExpectTrue(parser.Ok());
}

protected static function SubTest_MatchNameFailure()
{
    local Parser        parser;
    local string        resultS;
    local MutableText   result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MName()` parses invalid names.");
    parser.Initialize(__().text.FromString(".hidden"));
    parser.MName(result);
    TEST_ExpectFalse(parser.Ok());
    parser.Initialize(__().text.FromString("10MAC"));
    parser.MName(result);
    TEST_ExpectFalse(parser.Ok());
    parser.Initialize(__().text.FromString(default.stringWithGoodBadNames));
    parser.MName(result);
    TEST_ExpectTrue(parser.Ok());
    parser.Skip().MName(result);
    TEST_ExpectFalse(parser.Ok());

    Issue("`MNameS()` parses invalid names.");
    parser.InitializeS(".hidden");
    parser.MNameS(resultS);
    TEST_ExpectFalse(parser.Ok());
    parser.InitializeS("10MAC");
    parser.MNameS(resultS);
    TEST_ExpectFalse(parser.Ok());
    parser.InitializeS(default.stringWithGoodBadNames);
    parser.MNameS(resultS);
    TEST_ExpectTrue(parser.Ok());
    parser.Skip().MNameS(resultS);
    TEST_ExpectFalse(parser.Ok());
}

protected static function Test_ParseString()
{
    Context("Testing parsing simple strings.");
    SubTest_ParseStringSimple();
    SubTest_ParseStringForTextSimple();
    Context("Testing parsing quoted strings.");
    SubTest_ParseStringComplex();
    SubTest_ParseStringForTextComplex();
    SubTest_ParseStringLiteral();
    SubTest_ParseStringLiteralForText();
    Context("Testing parsing escaped sequences.");
    SubTest_ParseEscapedSequence();
    SubTest_ParseStringEscapedSequencesAllAtOnce();
}

protected static function SubTest_ParseStringSimple()
{
    local Parser parser;
    local string result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MString()` fails simple parsing.");
    parser.InitializeS("My random!").MStringS(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "My");

    Issue("`MString()` incorrectly handles whitespace symbols by default.");
    parser.MStringS(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "");

    Issue("`MString()` incorrectly handles sequential passing.");
    parser.Skip().MStringS(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "random!");

    Issue(  "`MString()` incorrectly handles parsing after" @
            "consuming all input.");
    parser.Skip().MStringS(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "");
}

protected static function SubTest_ParseStringForTextSimple()
{
    local Parser    parser;
    local MutableText      result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MStringT()` fails simple parsing.");
    parser.InitializeS("My random!").MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.CompareToString("My"));

    Issue("`MStringT()` incorrectly handles whitespace symbols by default.");
    parser.MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEmpty());

    Issue("`MStringT()` incorrectly handles sequential passing.");
    parser.Skip().MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.CompareToString("random!"));

    Issue(  "`MStringT()` incorrectly handles parsing after" @
            "consuming all input.");
    parser.Skip().MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEmpty());
}

protected static function SubTest_ParseStringComplex()
{
    local Parser parser;
    local string result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MStringS()` fails simple parsing of quoted string.");
    parser.InitializeS("\"My random!\" and more!").MStringS(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "My random!");

    Issue("`MStringS()` incorrectly handles whitespace symbols by default.");
    parser.MStringS(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "");

    Issue("`MStringS()` incorrectly handles sequential passing.");
    parser.Skip().MStringS(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "and");

    Issue("`MStringS()` does not recognize \' and ` as quote symbols.");
    parser.InitializeS("\'Some string\'").MStringS(result);
    TEST_ExpectTrue(result == "Some string");
    parser.InitializeS("`Other string`").MStringS(result);
    TEST_ExpectTrue(result == "Other string");

    Issue(  "`MStringS()` can not freely use (without escaping them)" @
            "quotation marks that were not used to open the string.");
    parser.InitializeS("`Some\"string\'here...`").MStringS(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "Some\"string\'here...");
}

protected static function SubTest_ParseStringForTextComplex()
{
    local Parser    parser;
    local MutableText      result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MString()` fails simple parsing of quoted string.");
    parser.InitializeS("\"My random!\" and more!").MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.CompareToString("My random!"));

    Issue("`MString()` incorrectly handles whitespace symbols by default.");
    parser.MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.IsEmpty());

    Issue("`MString()` incorrectly handles sequential passing.");
    parser.Skip().MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.CompareToString("and"));

    Issue("`MString()` does not recognize \' and ` as quote symbols.");
    parser.InitializeS("\'Some string\'").MString(result);
    TEST_ExpectTrue(result.CompareToString("Some string"));
    parser.InitializeS("`Other string`").MString(result);
    TEST_ExpectTrue(result.CompareToString("Other string"));

    Issue(  "`MString()` can not freely use (without escaping them)" @
            "quotation marks that were not used to open the string.");
    parser.InitializeS("`Some\"string\'here...`").MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.CompareToString("Some\"string\'here..."));
}

protected static function SubTest_ParseStringLiteral()
{
    local Parser parser;
    local string result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MStringLiteralS()` fails simple parsing of quoted string.");
    parser.InitializeS("\"My random!\" and more!").MStringLiteralS(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "My random!");

    Issue(  "`MStringLiteralS()` incorrectly able to parse strings," @
            "not enclosed in quotation marks.");
    parser.Skip().MStringLiteralS(result);
    TEST_ExpectFalse(parser.Ok());

    Issue("`MStringLiteralS()` does not recognize \' and ` as quote symbols.");
    parser.InitializeS("\'Some string\'").MStringLiteralS(result);
    TEST_ExpectTrue(result == "Some string");
    parser.InitializeS("`Other string`").MStringLiteralS(result);
    TEST_ExpectTrue(result == "Other string");

    Issue(  "`MStringLiteralS()` can not freely use (without escaping them)" @
            "quotation marks that were not used to open the string.");
    parser.InitializeS("`Some\"string\'here...`").MStringLiteralS(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == "Some\"string\'here...");
}

protected static function SubTest_ParseStringLiteralForText()
{
    local Parser        parser;
    local MutableText   result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MStringLiteral()` fails simple parsing of quoted string.");
    parser.InitializeS("\"My random!\" and more!").MStringLiteral(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.CompareToString("My random!"));

    Issue(  "`MStringLiteral()` incorrectly able to parse strings," @
            "not enclosed in quotation marks.");
    parser.Skip().MStringLiteral(result);
    TEST_ExpectFalse(parser.Ok());

    Issue("`MStringLiteral()` does not recognize \' and ` as quote symbols.");
    parser.InitializeS("\'Some string\'").MStringLiteral(result);
    TEST_ExpectTrue(result.CompareToString("Some string"));
    parser.InitializeS("`Other string`").MStringLiteral(result);
    TEST_ExpectTrue(result.CompareToString("Other string"));

    Issue(  "`MStringLiteral()` can not freely use (without escaping them)" @
            "quotation marks that were not used to open the string.");
    parser.InitializeS("`Some\"string\'here...`").MStringLiteral(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.CompareToString("Some\"string\'here..."));

    Issue("`MStringLiteral()` does not create new `Text` when parser is in"
        @ "a failed state.");
    result = none;
    parser.InitializeS("not a string literal").Fail().MStringLiteral(result);
    TEST_ExpectNotNone(result);
}

protected static function SubTest_ParseEscapedSequence()
{
    local Parser            parser;
    local MutableText.Character    result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MEscapedSequence()` does not properly handle escaped characters"
        @ "in quoted strings.");
    parser.InitializeS("\\udc6d\\'\\\"\\n\\r\\t\\b\\f\\v\\U67\\h");
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
    local Parser    parser;
    local MutableText      result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MString()` does not properly handle escaped characters in"
        @ "quoted strings.");
    parser.InitializeS("\"\\udc6d\\'\\\"\\n\\r\\t\\b\\f\\v\\U67\\h\"");
    parser.MString(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result.GetCharacter(0).codePoint == 0xdc6d);
    TEST_ExpectTrue(result.GetCharacter(1).codePoint == 0x0027);   // '
    TEST_ExpectTrue(result.GetCharacter(2).codePoint == 0x0022);   // "
    TEST_ExpectTrue(result.GetCharacter(3).codePoint == 0x000a);   // \n
    TEST_ExpectTrue(result.GetCharacter(4).codePoint == 0x000d);   // \r
    TEST_ExpectTrue(result.GetCharacter(5).codePoint == 0x0009);   // \t
    TEST_ExpectTrue(result.GetCharacter(6).codePoint == 0x0008);   // \b
    TEST_ExpectTrue(result.GetCharacter(7).codePoint == 0x000c);   // \f
    TEST_ExpectTrue(result.GetCharacter(8).codePoint == 0x000b);   // \v
    TEST_ExpectTrue(result.GetCharacter(9).codePoint == 0x0067);
    TEST_ExpectTrue(result.GetCharacter(10).codePoint == 0x0068);  // h
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
    SubTest_ParseIntOverflow();
}

protected static function SubTest_ParseSign()
{
    local Parser            parser;
    local Parser.ParsedSign result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MSign()` can't properly parse + sign.");
    TEST_ExpectTrue(parser.InitializeS("+").MSign(result).Ok());
    TEST_ExpectTrue(result == SIGN_Plus);

    Issue("`MSign()` can't properly parse - sign.");
    TEST_ExpectTrue(parser.InitializeS("-").MSign(result).Ok());
    TEST_ExpectTrue(result == SIGN_Minus);

    Issue(  "`MSign()` can't properly parse non-sign symbol as" @
            "a lack of sign, even with `allowMissingSign = true`.");
    TEST_ExpectTrue(parser.InitializeS("a").MSign(result, true).Ok());
    TEST_ExpectTrue(result == SIGN_Missing);

    Issue(  "`MSign()` can't properly parse empty input as" @
            "a lack of sign, even with `allowMissingSign = true`.");
    TEST_ExpectTrue(parser.InitializeS("").MSign(result, true).Ok());
    TEST_ExpectTrue(result == SIGN_Missing);

    Issue(  "`MSign()` incorrectly parses non-sign symbol by default," @
            "with `allowMissingSign = false`.");
    TEST_ExpectFalse(parser.InitializeS("a").MSign(result).Ok());

    Issue(  "`MSign()` incorrectly parses empty input by default," @
            "with `allowMissingSign = false`.");
    TEST_ExpectFalse(parser.InitializeS("").MSign(result).Ok());
}

protected static function SubTest_ParseBase()
{
    local Parser    parser;
    local int       result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MBase()` can't properly parse binary prefix.");
    TEST_ExpectTrue(parser.InitializeS("0b").MBase(result).Ok());
    TEST_ExpectTrue(result == 2);

    Issue("`MBase()` can't properly parse octal prefix.");
    TEST_ExpectTrue(parser.InitializeS("0o").MBase(result).Ok());
    TEST_ExpectTrue(result == 8);

    Issue("`MBase()` can't properly parse hexadecimal prefix.");
    TEST_ExpectTrue(parser.InitializeS("0x").MBase(result).Ok());
    TEST_ExpectTrue(result == 16);

    Issue(  "`MBase()` does not treat lack of base prefix as a sign of" @
            "decimal system.");
    TEST_ExpectTrue(parser.InitializeS("123").MBase(result).Ok());
    TEST_ExpectTrue(result == 10);

    Issue(  "`MBase()` does not treat non-digit input as a sign of" @
            "decimal system.");
    TEST_ExpectTrue(parser.InitializeS("asdas").MBase(result).Ok());
    TEST_ExpectTrue(result == 10);

    Issue(  "`MBase()` does not treat empty input as a sign of" @
            "decimal system.");
    TEST_ExpectTrue(parser.InitializeS("").MBase(result).Ok());
    TEST_ExpectTrue(result == 10);
}

protected static function SubTest_ParseUnsignedInt()
{
    local Parser    parser;
    local int       result;
    local int       readDigits;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MUnsignedInteger()` can't properly parse simple unsigned integer.");
    parser.InitializeS("13").MUnsignedInteger(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 13);

    Issue(  "`MUnsignedInteger()` can't properly parse integer" @
            "written in non-standard base (13).");
    parser.InitializeS("C1").MUnsignedInteger(result, 13,, readDigits);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 157);

    Issue("`MUnsignedInteger()` incorrectly reads amount of digits.");
    TEST_ExpectTrue(readDigits == 2);

    Issue(  "`MUnsignedInteger()` can't properly parse integer when" @
            "length is fixed.");
    parser.InitializeS("12345").MUnsignedInteger(result,, 3);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 123);
}

protected static function SubTest_ParseUnsignedIntIncorrect()
{
    local Parser    parser;
    local int       result;
    local int       readDigitsEmpty;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue(  "`MUnsignedInteger()` is successfully parsing" @
            "empty input, but it should not.");
    parser.InitializeS("").MUnsignedInteger(result,,, readDigitsEmpty);
    TEST_ExpectFalse(parser.Ok());

    Issue(  "`MUnsignedInteger()` incorrectly reads amount of digits for" @
            "empty input.");
    TEST_ExpectTrue(readDigitsEmpty == 0);

    Issue(  "`MUnsignedInteger()` successfully parsing" @
            "insufficient input, but it should not.");
    parser.InitializeS("123").MUnsignedInteger(result,, 4);
    TEST_ExpectFalse(parser.Ok());

    Issue(  "`MUnsignedInteger()` successfully parsing base it cannot.");
    parser.InitializeS("e3").MUnsignedInteger(result,, 12);
    TEST_ExpectFalse(parser.Ok());
}

protected static function SubTest_ParseIntSimple()
{
    local Parser    parser;
    local int       result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MInteger()` can't properly parse simple unsigned integer.");
    parser.InitializeS("13").MInteger(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 13);

    Issue("`MInteger()` can't properly parse negative integer.");
    parser.InitializeS("-7").MInteger(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == -7);

    Issue("`MInteger()` can't properly parse explicitly positive integer.");
    parser.InitializeS("+21").MInteger(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 21);

    Issue(  "`MInteger()` incorrectly allows whitespaces between" @
            "sign and digits.");
    TEST_ExpectFalse(parser.InitializeS("+ 4").MInteger(result).Ok());
    TEST_ExpectFalse(parser.InitializeS("- 90").MInteger(result).Ok());

    Issue("`MInteger()` incorrectly consumes a dot after the integer");
    parser.InitializeS("45.").MInteger(result).MatchS(".");
    TEST_ExpectTrue(parser.Ok());

    Issue(  "`MInteger()` incorrectly reports success after" @
            "empty integer input.");
    TEST_ExpectFalse(parser.InitializeS("").MInteger(result).Ok());
    TEST_ExpectFalse(parser.InitializeS(".345").MInteger(result).Ok());
    TEST_ExpectFalse(parser.InitializeS(" 4").MInteger(result).Ok());
}

protected static function SubTest_ParseIntBases()
{
    local Parser parser;
    local int result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue(  "`MInteger()` can't properly parse integers in" @
            "hexadecimal system.");
    TEST_ExpectTrue(parser.InitializeS("0x2a").MInteger(result).Ok());
    TEST_ExpectTrue(result == 0x2a);

    Issue(  "`MInteger()` can't properly parse integers in" @
            "octo system.");
    TEST_ExpectTrue(parser.InitializeS("0o27").MInteger(result).Ok());
    TEST_ExpectTrue(result == 23);

    Issue(  "`MInteger()` can't properly parse integers in hexadecimal" @
            "system with uppercase letters.");
    TEST_ExpectTrue(parser.InitializeS("0x10Bc").MInteger(result).Ok());
    TEST_ExpectTrue(result == 0x10bc);

    Issue("`MInteger()` can't properly parse integers in binary system.");
    TEST_ExpectTrue(parser.InitializeS("0b011101").MInteger(result).Ok());
    TEST_ExpectTrue(result == 29);
}

protected static function SubTest_ParseIntBasesSpecified()
{
    local Parser parser;
    local int result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue(  "`MInteger()` can't properly parse integers in directly" @
            "specified, non-standard base.");
    TEST_ExpectTrue(parser.InitializeS("10c").MInteger(result, 13).Ok());
    TEST_ExpectTrue(result == 181);

    Issue(  "`MInteger()` can't properly parse integers in directly" @
            "specified decimal system.");
    TEST_ExpectTrue(parser.InitializeS("205").MInteger(result, 10).Ok());
    TEST_ExpectTrue(result == 205);

    Issue(  "`MInteger()` does not ignore octo-, hex- and binary- system" @
            "prefixes when base is directly specified.");
    TEST_ExpectTrue(parser.InitializeS("0x104").MInteger(result, 10).Ok());
    TEST_ExpectTrue(result == 0);
    TEST_ExpectTrue(parser.InitializeS("018").MInteger(result, 10).Ok());
    TEST_ExpectTrue(result == 18);
    parser.InitializeS("0b01001010101").MInteger(result, 10);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 0);
}

protected static function SubTest_ParseIntBasesNegative()
{
    local Parser parser;
    local int result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue(  "`MInteger()` can't properly parse negative integers in" @
            "hexadecimal system.");
    TEST_ExpectTrue(parser.InitializeS("-0x2a").MInteger(result).Ok());
    TEST_ExpectTrue(result == -0x2a);

    Issue(  "`MInteger()` can't properly parse negative integers in" @
            "hexadecimal system with uppercase letters.");
    TEST_ExpectTrue(parser.InitializeS("-0x10Bc").MInteger(result).Ok());
    TEST_ExpectTrue(result == -0x10bc);

    Issue(  "`MInteger()` can't properly parse negative integers in" @
            "binary system.");
    TEST_ExpectTrue(parser.InitializeS("-0b011101").MInteger(result).Ok());
    TEST_ExpectTrue(result == -29);

    Issue(  "`MInteger()` can't properly parse negative integers in" @
            "directly specified, non-standard base.");
    TEST_ExpectTrue(parser.InitializeS("-10c").MInteger(result, 13).Ok());
    TEST_ExpectTrue(result == -181);

    Issue(  "`MInteger()` can't properly parse negative integers in" @
            "directly specified decimal system.");
    TEST_ExpectTrue(parser.InitializeS("-205").MInteger(result, 10).Ok());
    TEST_ExpectTrue(result == -205);
}

protected static function SubTest_ParseIntOverflow()
{
    local Parser parser;
    local int result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("Integer overflow is not handled correctly while parsing.");
    TEST_ExpectTrue(parser.InitializeS("2147483648")
        .MUnsignedInteger(result).Ok());
    TEST_ExpectTrue(result == MaxInt);
    TEST_ExpectTrue(parser.InitializeS("21474836470")
        .MUnsignedInteger(result).Ok());
    TEST_ExpectTrue(result == MaxInt);
    TEST_ExpectTrue(parser.InitializeS("723872394237982")
        .MUnsignedInteger(result).Ok());
    TEST_ExpectTrue(result == MaxInt);

    Issue("Integer overflow is not handled correctly while parsing in hex.");
    TEST_ExpectTrue(parser.InitializeS("ffffffff")
        .MUnsignedInteger(result, 16).Ok());
    TEST_ExpectTrue(result == MaxInt);
    TEST_ExpectTrue(parser.InitializeS("f0000000")
        .MUnsignedInteger(result, 16).Ok());
    TEST_ExpectTrue(result == MaxInt);
    TEST_ExpectTrue(parser.InitializeS("7fffffff0")
        .MUnsignedInteger(result, 16).Ok());
    TEST_ExpectTrue(result == MaxInt);
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
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MNumber()` can't properly parse simple unsigned float.");
    parser.InitializeS("3.14").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 3.14);

    Issue("`MNumber()` can't properly parse negative float.");
    parser.InitializeS("-2.6").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == -2.6);

    Issue("`MNumber()` can't properly parse explicitly positive float.");
    parser.InitializeS("+97.0043").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 97.0043);

    Issue(  "`MNumber()` incorrectly parses fractional part that starts" @
            "with zeroes.");
    parser.InitializeS("0.0006").MNumber(result);

    Issue(  "`MNumber()` incorrectly does not consume a dot after" @
            "the integer part, if the fractional part is missing.");
    parser.InitializeS("45.str");
    parser.MNumber(result);
    parser.MatchS("str");
    TEST_ExpectTrue(parser.Ok());
}

protected static function SubTest_ParseNumberIncorrectSimple()
{
    local Parser parser;
    local float result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue(  "`MNumber()` incorrectly allows whitespaces between" @
            "sign, digits and dot.");
    TEST_ExpectFalse(parser.InitializeS("- 90").MNumber(result).Ok());
    parser.InitializeS("4. 6").MNumber(result).Skip().MatchS("6");
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 4);
    parser.InitializeS("34 .").MNumber(result).Skip().MatchS(".");
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 34);

    Issue(  "`ParseNumber()` incorrectly reports success after" @
            "an empty input.");
    TEST_ExpectFalse(parser.InitializeS("").MNumber(result).Ok());
    TEST_ExpectFalse(parser.InitializeS(" 4").MNumber(result).Ok());
}

protected static function SubTest_ParseNumberF()
{
    local Parser parser;
    local float num1, num2;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue("`MNumber()` does not consume float's \"f\" suffix.");
    parser.InitializeS("2fstr").MNumber(num1).MatchS("str");
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(num1 == 2);
    parser.InitializeS("2.f3.7fstr").MNumber(num1)
        .MNumber(num2).MatchS("str");
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(num1 == 2);
    TEST_ExpectTrue(num2 == 3.7);

    Issue("`MNumber()` consumes float's \"f\" suffix after whitespace.");
    parser.InitializeS("35.8 f")
        .MNumber(num1)
        .Skip()
        .MatchS("f");
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(num1 == 35.8);
}

protected static function SubTest_ParseNumberScientific()
{
    local Parser parser;
    local float result;
    parser = Parser(__().memory.Allocate(class'Parser'));
    Issue(  "`MNumber()` can't properly parse float in scientific format" @
            "with lower \"e\".");
    parser.InitializeS("3.14e2").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 314);

    Issue(  "`MNumber()` can't properly parse float in scientific format" @
            "with upper \"E\".");
    parser.InitializeS("0.4E1").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 4);

    Issue(  "`MNumber()` can't properly parse float in scientific format" @
            "with a sign specified.");
    parser.InitializeS("2.56e+3").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 2560);
    parser.InitializeS("7.8E-2").MNumber(result);
    TEST_ExpectTrue(parser.Ok());
    TEST_ExpectTrue(result == 0.078);

    Issue(  "`MNumber()` incorrectly reports success when exponent number" @
            "is missing");
    TEST_ExpectFalse(parser.InitializeS("0.054e").MNumber(result).Ok());
    TEST_ExpectFalse(parser.InitializeS("2.56e+str").MNumber(result).Ok());
}

defaultproperties
{
    caseName = "Parser"
    caseGroup = "Text"
    stringWithWhitespaces       = "   Spaced out	string here	, not  much  to see."
    stringWithGoodBadNames      = "word слово"
    usedSpaces1                 = "   "
    usedSpaces2                 = " "
    usedSpaces3                 = "	"
    stringWithNonASCIISymbols   = "S㑬Уፌ!"
}