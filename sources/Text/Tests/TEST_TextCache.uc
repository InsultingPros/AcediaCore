/**
 *  Set of tests for functionality of `TextCache` class.
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
class TEST_TextCache extends TestCase
    abstract;

var string formatted1, formatted2, formatted3, formatted4;

protected static function TESTS()
{
    Test_Plain();
    Test_Formatted();
    Test_Indexed();
}

protected static function Test_Plain()
{
    local int       lifeVersion;
    local Text      text1, text2, text3, newText;
    local TextCache cache;

    Context("Testing caching plain strings.");
    cache = TextCache(__().memory.Allocate(class'TextCache'));
    text1 = cache.GetPlainText("First string");
    text2 = cache.GetPlainText("Second string");
    text3 = cache.GetPlainText("Last string");

    Issue("Cache returns `none`.");
    TEST_ExpectNotNone(text1);
    TEST_ExpectNotNone(text2);
    TEST_ExpectNotNone(text3);

    Issue("Cache returns different objects for the same `string`.");
    TEST_ExpectTrue(text1 == cache.GetPlainText("First string"));
    TEST_ExpectTrue(text2 == cache.GetPlainText("Second string"));
    TEST_ExpectTrue(text3 == cache.GetPlainText("Last string"));

    Issue("Cache returns dead, previously deallocated `Text` reference.");
    lifeVersion = text1.GetLifeVersion();
    text1.FreeSelf();
    newText = cache.GetFormattedText(default.formatted1);
    TEST_ExpectTrue(    text1 != newText
                    ||  lifeVersion != newText.GetLifeVersion());

    Issue("Cache returns `Text` with wrong data.");
    TEST_ExpectTrue(    cache.GetPlainText("First string").ToString()
                    ==  "First string");
    TEST_ExpectTrue(    cache.GetPlainText("New string").ToString()
                    ==  "New string");
}

protected static function Test_Formatted()
{
    local int       lifeVersion;
    local Text      text1, text2, text3, newText;
    local TextCache cache;

    Context("Testing caching formatted strings.");
    cache = TextCache(__().memory.Allocate(class'TextCache'));
    text1 = cache.GetFormattedText(default.formatted1);
    text2 = cache.GetFormattedText(default.formatted2);
    text3 = cache.GetFormattedText(default.formatted3);

    Issue("Cache returns `none`.");
    TEST_ExpectNotNone(text1);
    TEST_ExpectNotNone(text2);
    TEST_ExpectNotNone(text3);

    Issue("Cache returns different objects for the same `string`.");
    TEST_ExpectTrue(text1 == cache.GetFormattedText(default.formatted1));
    TEST_ExpectTrue(text2 == cache.GetFormattedText(default.formatted2));
    TEST_ExpectTrue(text3 == cache.GetFormattedText(default.formatted3));

    Issue("Cache returns dead, previously deallocated `Text` reference.");
    lifeVersion = text1.GetLifeVersion();
    text1.FreeSelf();
    newText = cache.GetFormattedText(default.formatted1);
    TEST_ExpectTrue(    text1 != newText
                    ||  lifeVersion != newText.GetLifeVersion());

    Issue("Cache returns `Text` with wrong data.");
    TEST_ExpectTrue(cache.GetFormattedText(default.formatted1)
        .ToFormattedString() == default.formatted1);
    TEST_ExpectTrue(cache.GetFormattedText(default.formatted4)
        .ToFormattedString() ==  default.formatted4);
}

protected static function Test_Indexed()
{
    local int       lifeVersion;
    local Text      text1, text2, text3, newText;
    local TextCache cache;

    Context("Testing caching indexed strings.");
    cache = TextCache(__().memory.Allocate(class'TextCache'));
    text1 = cache.AddIndexedText(default.formatted1).GetIndexedText(0);
    text2 = cache.AddIndexedText(default.formatted2).GetIndexedText(1);
    text3 = cache.AddIndexedText(default.formatted3).GetIndexedText(2);

    Issue("Cache returns `none`.");
    TEST_ExpectNotNone(text1);
    TEST_ExpectNotNone(text2);
    TEST_ExpectNotNone(text3);

    Issue("Cache returns different objects for the same index.");
    TEST_ExpectTrue(text1 == cache.GetIndexedText(0));
    TEST_ExpectTrue(text2 == cache.GetIndexedText(1));
    TEST_ExpectTrue(text3 == cache.GetIndexedText(2));

    Issue("Cache returns dead, previously deallocated `Text` reference.");
    lifeVersion = text1.GetLifeVersion();
    text1.FreeSelf();
    newText =  cache.GetIndexedText(0);
    TEST_ExpectTrue(    text1 != newText
                    ||  lifeVersion != newText.GetLifeVersion());

    Issue("Cache returns `Text` with wrong data.");
    TEST_ExpectTrue(cache.GetIndexedText(0)
        .ToFormattedString() == default.formatted1);

    Issue("Cache does not return `none` for wrong indices.");
    TEST_ExpectNone(cache.GetIndexedText(-1));
    TEST_ExpectNone(cache.GetIndexedText(3));
}

defaultproperties
{
    caseName = "TextCache"
    caseGroup = "Text"
    formatted1 = "{rgb(23,122,231) First} {rgb(255,0,0) string}"
    formatted2 = "{rgb(32,1,154) Second} {rgb(0,255,0) string}"
    formatted3 = "{rgb(76,23,111) Last} {rgb(0,0,255) string}"
    formatted4 = "{rgb(145,231,41) New str}ing"
}