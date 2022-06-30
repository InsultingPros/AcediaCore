/**
 *  Set of tests for functionality of `TextTemplate`.
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
class TEST_TextTemplate extends TestCase
    abstract;

protected static function TESTS()
{
    Context("Testing `TextTemplate` class' ability to handle empty (erroneous)"
        @ "argument declarations.");
    Test_EmptyDeclarations();
    Context("Testing `TextTemplate` class' ability to handle numeric"
        @ "argument declarations.");
    Test_NumericDeclarationsAmount();
    Test_NumericDeclarationsOrder();
    Test_NumericDeclarationsNoOrder();
    Test_NumericDeclarationsRandomValues();
    Test_NumericDeclarationsIgnoreFormatting();
    Context("Testing `TextTemplate` class' ability to handle text"
        @ "argument declarations.");
    Test_TextDeclarationsGet();
    Test_TextDeclarationsEmptyCollect();
    Test_TextDeclarationsCollect();
    Test_TextDeclarationsOverwriteCollect();
    Test_TextDeclarationsIgnoreFormatting();
    Context("Testing complex `TextTemplate` scenarios.");
    Test_Reset();
    Test_Complex();
    Test_Formatted();
}

protected static function Test_EmptyDeclarations()
{
    local TextTemplate instance;

    Issue("Empty `TextTemplate` is not collected into empty text.");
    instance = __().text.MakeTemplate_S("");
    TEST_ExpectTrue(instance.Collect().IsEmpty());

    Issue("`TextTemplate` with empty numeric definition is not properly"
        @ "collected.");
    instance = __().text.MakeTemplate_S("%");
    TEST_ExpectTrue(instance.Collect().IsEmpty());
    instance = __().text.MakeTemplate_S("With some%text");
    TEST_ExpectTrue(instance.Collect().ToString() == "With sometext");

    Issue("`TextTemplate` with empty text definition is not properly"
        @ "collected.");
    instance = __().text.MakeTemplate_S("%%");
    TEST_ExpectTrue(instance.Collect().IsEmpty());
    instance = __().text.MakeTemplate_S("With some%%%text and %%%%more!");
    TEST_ExpectTrue(instance.Collect().ToString() == "With sometext and more!");

    Issue("`TextTemplate` with definitions opened at the very end is not"
        @ "properly collected.");
    instance = __().text.MakeTemplate_S("Some text: %");
    TEST_ExpectTrue(instance.Collect().ToString() == "Some text: ");
    instance = __().text.MakeTemplate_S("Another example: %%");
    TEST_ExpectTrue(instance.Collect().ToString() == "Another example: ");
}

protected static function Test_NumericDeclarationsAmount()
{
    local TextTemplate instance;

    Issue("`GetNumericArgsAmount()` does not return `0` for `Text` without any"
        @ "numeric declarations.");
    instance = __().text.MakeTemplate_S("");
    TEST_ExpectTrue(instance.GetNumericArgsAmount() == 0);
    instance = __().text.MakeTemplate_S("With some%text");
    TEST_ExpectTrue(instance.GetNumericArgsAmount() == 0);
    instance = __().text.MakeTemplate_S("With some%%%text and %%%%more!");
    TEST_ExpectTrue(instance.GetNumericArgsAmount() == 0);
    instance = __().text.MakeTemplate_S("With some%%valid arg%text and"
        @ "%%me too%%more!");
    TEST_ExpectTrue(instance.GetNumericArgsAmount() == 0);

    Issue("`GetNumericArgsAmount()` does not correctly counts numeric"
        @ "declarations.");
    instance = __().text.MakeTemplate_S("just %1 %2 %3 %t %4 %5 %%text one!%%"
        @" %6 %7 %8");
    TEST_ExpectTrue(instance.GetNumericArgsAmount() == 8);

    Issue("`GetNumericArgsAmount()` does not correctly counts numeric"
        @ "declarations with escaped '%' characters.");
    instance = __().text.MakeTemplate_S("just &%1 %2 %3 %t &%4 %5 %%text one!%%"
        @" %6 %7 %8");
    TEST_ExpectTrue(instance.GetNumericArgsAmount() == 6);
}

protected static function Test_NumericDeclarationsOrder()
{
    local TextTemplate instance;

    Issue("Basic numeric declarations are not working as intended.");
    instance = __().text.MakeTemplate_S("This is argument: %1!");
    instance.Arg(P("<enter_phrase_here>"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "This is argument: <enter_phrase_here>!");
    instance = __().text.MakeTemplate_S("just %1 %2 %3 %4 %5 %6 %7 %8");
    instance.Arg(P("a")).Arg(P("b")).Arg(P("c")).Arg(P("d")).Arg(P("e"))
        .Arg(P("f")).Arg(P("g")).Arg(P("h"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "just a b c d e f g h");

    Issue("Basic numeric declarations are not working as intended after"
        @ "specifying too many.");
    instance = __().text.MakeTemplate_S("This is argument: %1!");
    instance.Arg(P("<enter_phrase_here>")).Arg(P("Now this is too much!"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "This is argument: <enter_phrase_here>!");
    instance = __().text.MakeTemplate_S("just %1 %2 %3 %4 %5 %6 %7 %8");
    instance.Arg(P("a")).Arg(P("b")).Arg(P("c")).Arg(P("d")).Arg(P("e"))
        .Arg(P("f")).Arg(P("g")).Arg(P("h")).Arg(P("i")).Arg(P("j"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "just a b c d e f g h");

    Issue("Basic numeric declarations are not working as intended after"
        @ "specifying too little.");
    instance = __().text.MakeTemplate_S("This is argument: %1!");
    TEST_ExpectTrue(instance.Collect().ToString() == "This is argument: !");
    instance = __().text.MakeTemplate_S("just %1 %2 %3 %4 %5 %6 %7 %8");
    instance.Arg(P("a")).Arg(P("b")).Arg(P("c")).Arg(P("d")).Arg(P("e"));
    TEST_ExpectTrue(instance.Collect().ToString() == "just a b c d e   ");
}

protected static function Test_NumericDeclarationsNoOrder()
{
    local TextTemplate instance;

    Issue("Basic numeric declarations are not working as intended.");
    instance = __().text.MakeTemplate_S("This is argument: %2! And this: %1!!");
    instance.Arg(P("<enter_phrase_here>")).Arg(P("heh"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "This is argument: heh! And this: <enter_phrase_here>!!");
    instance = __().text.MakeTemplate_S("just %1 %3 %5 %2 %4 %8 %6 %7");
    instance.Arg(P("a")).Arg(P("b")).Arg(P("c")).Arg(P("d")).Arg(P("e"))
        .Arg(P("f")).Arg(P("g")).Arg(P("h"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "just a c e b d h f g");

    Issue("Basic numeric declarations are not working as intended after"
        @ "specifying too many.");
    instance = __().text.MakeTemplate_S("just %1 %3 %5 %2 %4 %8 %6 %7");
    instance.Arg(P("a")).Arg(P("b")).Arg(P("c")).Arg(P("d")).Arg(P("e"))
        .Arg(P("f")).Arg(P("g")).Arg(P("h")).Arg(P("i")).Arg(P("j"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "just a c e b d h f g");

    Issue("Basic numeric declarations are not working as intended after"
        @ "specifying too little.");
    instance = __().text.MakeTemplate_S("just %1 %3 %5 %2 %4 %8 %6 %7");
    instance.Arg(P("a")).Arg(P("b")).Arg(P("c"));
    TEST_ExpectTrue(instance.Collect().ToString() == "just a c  b    ");
}

protected static function Test_NumericDeclarationsRandomValues()
{
    local TextTemplate instance;

    Issue("Basic numeric declarations are not working as intended when using"
        @ "arbitrary integer values.");
    instance = __().text.MakeTemplate_S("This is argument:"
        @ "%205! And this: %-7!!");
    instance.Arg(P("<enter_phrase_here>")).Arg(P("heh"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "This is argument: heh! And this: <enter_phrase_here>!!");
    instance = __().text.MakeTemplate_S("just %-3912842 %0 %666 %-111 %34"
        @ "%666999 %10234 %10235");
    instance.Arg(P("a")).Arg(P("b")).Arg(P("c")).Arg(P("d")).Arg(P("e"))
        .Arg(P("f")).Arg(P("g")).Arg(P("h"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "just a c e b d h f g");
}

protected static function Test_NumericDeclarationsIgnoreFormatting()
{
    local TextTemplate instance;

    Issue("Basic numeric declarations are not using arguments formatting by"
        @ "default.");
    instance = __().text.MakeTemplate_S("Simple {#ff0000 test %1}");
    instance.Arg(F("{#00ff00 arg}"));
    TEST_ExpectTrue(instance.CollectFormatted().ToFormattedString()
        == "Simple {rgb(255,0,0) test }{rgb(0,255,0) arg}");

    Issue("Basic numeric declarations are using arguments formatting when"
        @ "method is told to ignore it.");
    instance = __().text.MakeTemplate_S("Simple {#ff0000 test %1}");
    instance.Arg(F("{#00ff00 arg}"), true);
    TEST_ExpectTrue(instance.CollectFormatted().ToFormattedString()
        == "Simple {rgb(255,0,0) test arg}");
}

protected static function Test_TextDeclarationsGet()
{
    local TextTemplate  instance;
    local array<Text>   result;

    Issue("Specified text labels aren't properly returned by"
        @ "the `GetTextlabels()` method.");
    instance = __().text.MakeTemplate_S("This is argument: %%argument!%% and"
        @ "so its this: %%another arg%%");
    result = instance.GetTextArgs();
    TEST_ExpectTrue(result[0].ToString() == "argument!");
    TEST_ExpectTrue(result[1].ToString() == "another arg");
    TEST_ExpectTrue(result.length == 2);
    instance.TextArg(P("another arg"), P("heh"))
        .TextArg(P("argument!"), P("<enter_phrase_here>"));
    result = instance.GetTextArgs();
    TEST_ExpectTrue(result[0].ToString() == "argument!");
    TEST_ExpectTrue(result[1].ToString() == "another arg");
    TEST_ExpectTrue(result.length == 2);

    instance = __().text.MakeTemplate_S("Here: %2 %76 %4 %5 %8");
    result = instance.GetTextArgs();
    TEST_ExpectTrue(result.length == 0);

    instance = __().text.MakeTemplate_S("More %%complex%% %7 %%/example% here,"
        @ "yes. Very %%complex%!");
    result = instance.GetTextArgs();
    TEST_ExpectTrue(result[0].ToString() == "complex");
    TEST_ExpectTrue(result[1].ToString() == "/example");
    TEST_ExpectTrue(result.length == 2);
}

protected static function Test_TextDeclarationsEmptyCollect()
{
    local TextTemplate instance;

    Issue("`TextTempalte` is not properly collected with it contains empty"
@         "text labels.");
    instance = __().text.MakeTemplate_S("This is argument: %%%% and"
        @ "so its this: %%%");
    instance.TextArg(P(""), P("what do y'll know?!"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == ("This is argument: what do y'll know?! and so its this:"
            @ "what do y'll know?!"));
}

protected static function Test_TextDeclarationsCollect()
{
    local TextTemplate instance;

    Issue("Specified text labels aren't properly collected.");
    instance = __().text.MakeTemplate_S("This is argument: %%argument!%% and"
        @ "so its this: %%another arg%%");
    instance.TextArg(P("another arg"), P("heh"))
        .TextArg(P("argument!"), P("<enter_phrase_here>"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "This is argument: <enter_phrase_here> and so its this: heh");

    Issue("Specified text labels aren't properly collected when duplicate"
        @ "labels are present.");
    instance = __().text.MakeTemplate_S("More %%complex%% %7 %%/example% here,"
        @ "yes. Very %%complex%!");
    instance.TextArg(P("complex"), P("simple")).TextArg(P("/example"), P("!!"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "More simple  !! here, yes. Very simple!");

    Issue("Specified text labels aren't properly collected when specified"
        @ "too little arguments.");
    instance = __().text.MakeTemplate_S("More %%complex%% %7 %%/example% here,"
        @ "yes. Very %%complex% and %%nasty%%!!!");
    instance.TextArg(P("complex"), P("simple")).TextArg(P("nasty"), P("-_-"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "More simple   here, yes. Very simple and -_-!!!");

    Issue("Specified text labels aren't properly collected when specified"
        @ "too many arguments.");
    instance = __().text.MakeTemplate_S("More %%complex%% %11 %%/example% here,"
        @ "yes. Very %%complex% and %%nasty%%!!!");
    instance.TextArg(P("complex"), P("simple")).TextArg(P("nasty"), P("-_-"))
        .TextArg(P("/usr/bin"), P("geronimo")).TextArg(P("/example"), P("???"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "More simple  ??? here, yes. Very simple and -_-!!!");
}

protected static function Test_TextDeclarationsOverwriteCollect()
{
    local TextTemplate instance;

    Issue("Specified text labels aren't properly collected when some labels"
        @ "are overwritten.");
    instance = __().text.MakeTemplate_S("More %%complex%% %7 %%/example% here,"
        @ "yes. Very %%complex%!");
    instance.TextArg(P("complex"), P("simple")).TextArg(P("/example"), P("!!"))
        .TextArg(P("complex"), P("nasty")).TextArg(P("/exe"), P("???"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == "More nasty  !! here, yes. Very nasty!");
}

protected static function Test_TextDeclarationsIgnoreFormatting()
{
    local TextTemplate instance;

    Issue("Basic numeric declarations are not using arguments formatting by"
        @ "default.");
    instance = __().text.MakeTemplate_S("Simple {#ff0000 test %%it%%}");
    instance.TextArg(P("it"), F("{#00ff00 arg}"));
    TEST_ExpectTrue(instance.CollectFormatted().ToFormattedString()
        == "Simple {rgb(255,0,0) test }{rgb(0,255,0) arg}");

    Issue("Basic numeric declarations are using arguments formatting when"
        @ "method is told to ignore it.");
    instance = __().text.MakeTemplate_S("Simple {#ff0000 test %%it%%}");
    instance.TextArg(P("it"), F("{#00ff00 arg}"), true);
    TEST_ExpectTrue(instance.CollectFormatted().ToFormattedString()
        == "Simple {rgb(255,0,0) test arg}");
}

protected static function Test_Reset()
{
    local TextTemplate instance;

    Issue("`Reset()` does not properly reset user's input.");
    instance = __().text.MakeTemplate_S("Testing %1, %2, %3 and %%one%%,"
        @ "%%two%% + %%three%%");
    instance.Arg_S("1").Arg_S("2").Arg_S("3").Arg_S("more?");
    instance
        .TextArg(P("one"), P("4"))
        .TextArg(P("two"), P("5"))
        .TextArg(P("three"), P("6"));
    instance.Reset().Arg_S("HEY").Arg_S("ARE").Arg_S("YOU");
    instance
        .TextArg(P("one"), P("READY"))
        .TextArg(P("two"), P("TO"))
        .TextArg(P("three"), P("GO?"));
    TEST_ExpectTrue(instance.Collect().ToString() == ("Testing HEY, ARE, YOU"
        @ "and READY, TO + GO?"));
}

protected static function Test_Complex()
{
    local TextTemplate  instance;
    local array<Text>   result;

    Issue("Specified text labels aren't properly collected in complex scenario"
        @ "with several numeric / text arguments and escaped characters.");
    instance = __().text.MakeTemplate_S("Welcome %%MoonAndStar%%, it is %7 nice"
        @ "to %-2 %%you%%. %%MoonAndStar%% drop your %%weapons%%, it is not too"
        @ "%0 for &m&y %%mercy%&%!");
    instance
        .TextArg(P("MoonAndStar"), P("Nerevar"))
        .TextArg(P("you"), P("you"))
        .TextArg(P("weapons"), P("cheats"))
        .Arg(P("see"))
        .Arg(P("late"))
        .Arg(P("so"));
    TEST_ExpectTrue(instance.Collect().ToString()
        == ("Welcome Nerevar, it is so nice to see you."
        @ "Nerevar drop your cheats, it is not too late for &m&y %!"));
    result = instance.GetTextArgs();
    TEST_ExpectTrue(result[0].ToString() == "MoonAndStar");
    TEST_ExpectTrue(result[1].ToString() == "you");
    TEST_ExpectTrue(result[2].ToString() == "weapons");
    TEST_ExpectTrue(result[3].ToString() == "mercy");
    TEST_ExpectTrue(result.length == 4);
}

protected static function Test_Formatted()
{
    local TextTemplate instance;

    Issue("Specified text labels aren't properly collected in complex scenario"
        @ "with several numeric / text arguments and escaped characters and"
        @ "we are asking to parse template as a formatted string"
        @ "(`CollectFormatted()` method).");
    instance = __().text.MakeTemplate_S("Test simple {%%color%% %1} string"
        @ "that is {%2 %%what%%}!");
    instance
        .Arg(P("formatted"))
        .Arg(P("$blue"))
        .TextArg(P("color"), P("$red"))
        .TextArg(P("what"), P("colored"));
    TEST_ExpectTrue(instance.CollectFormatted().ToFormattedString()
        == ("Test simple {rgb(255,0,0) formatted} string that is"
            @ "{rgb(0,0,255) colored}!"));
}

defaultproperties
{
    caseName = "TextTemplate"
    caseGroup = "Text"
}