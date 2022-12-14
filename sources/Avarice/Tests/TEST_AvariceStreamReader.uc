/**
 *  Set of tests related to `AvariceReader` class.
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
class TEST_AvariceStreamReader extends TestCase
    abstract;

var private string simpleString, complexString;

protected static function TESTS()
{
    local Utf8Encoder           encoder;
    local AvariceStreamReader   reader;
    reader =
        AvariceStreamReader(__().memory.Allocate(class'AvariceStreamReader'));
    encoder = Utf8Encoder(__().memory.Allocate(class'Utf8Encoder'));
    Context("Testing decoding reading input Avarice stream.");
    TEST_Success(reader, encoder);
    TEST_Failure(reader, encoder);
}

protected static function TEST_Success(
    AvariceStreamReader reader,
    Utf8Encoder         encoder)
{
    local int                   i;
    local array<MutableText>    readingResult;
    local ByteArrayRef          byteStream;
    byteStream = encoder.Encode(P("Hello, world!"));
    reader.PushByte(0);
    reader.PushByte(0);
    reader.PushByte(0);
    reader.PushByte(13);
    for (i = 0; i < byteStream.GetLength(); i += 1) {
        reader.PushByte(byteStream.GetItem(i));
    }
    reader.PushByte(0);
    reader.PushByte(0);
    reader.PushByte(0);
    reader.PushByte(3);
    byteStream = encoder.Encode(P("Yo?"));
    for (i = 0; i < byteStream.GetLength(); i += 1) {
        reader.PushByte(byteStream.GetItem(i));
    }
    readingResult = reader.PopMessages();

    Issue("`AvariceStreamReader` incorrectly reads messages from the stream.");
    TEST_ExpectTrue(readingResult.length == 2);
    TEST_ExpectTrue(readingResult[0].ToString() =="Hello, world!");
    TEST_ExpectTrue(readingResult[1].ToString() =="Yo?");

    Issue("`AvariceStreamReader` is in a failed state after reading correct"
        @ "data.");
    TEST_ExpectFalse(reader.Failed());
}

protected static function TEST_Failure(
    AvariceStreamReader reader,
    Utf8Encoder         encoder)
{
    Issue("`AvariceStreamReader` does not report errors for overly"
        @ "long messages.");
    reader.PushByte(255);
    reader.PushByte(255);
    reader.PushByte(255);
    reader.PushByte(255);
    TEST_ExpectTrue(reader.Failed());
}

defaultproperties
{
    caseGroup   = "Avarice"
    caseName    = "AvariceStreamReader"
}