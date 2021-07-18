/**
 *  Set of tests related to `Utf8Decoder` and `Utf8Encoder`, used by Avarice.
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
class TEST_UTF8EncoderDecoder extends TestCase
    abstract;

var private string simpleString, complexString;

protected static function TESTS()
{
    local Utf8Decoder decoder;
    decoder = Utf8Decoder(__().memory.Allocate(class'Utf8Decoder'));
    Context("Testing decoding UTF8 byte stream.");
    Test_DecoderPushingSuccess(decoder);
    Test_DecoderPoppingSuccess(decoder);
    Test_DecoderHasUnfinishedData(decoder);
    decoder = Utf8Decoder(__().memory.Allocate(class'Utf8Decoder')); // reset
    Test_DecoderFail(decoder);

    Context("Testing encoding Acedia's `Text` into UTF8 byte stream.");
    Test_EncodeDecode();
}

protected static function Test_DecoderPushingSuccess(Utf8Decoder decoder)
{
    Issue("Pushing byte into `Utf8Decoder` fails when it should not.");
    //  ¢ U+00A2
    TEST_ExpectTrue(decoder.PushByte(194));
    TEST_ExpectTrue(decoder.PushByte(162));
    //  $ U+0024
    TEST_ExpectTrue(decoder.PushByte(36));
    //  ह U+0939
    TEST_ExpectTrue(decoder.PushByte(224));
    TEST_ExpectTrue(decoder.PushByte(164));
    TEST_ExpectTrue(decoder.PushByte(185));
    //  Another `Text`
    TEST_ExpectTrue(decoder.PushByte(0));
    //  𐍈 U+10348
    TEST_ExpectTrue(decoder.PushByte(240));
    TEST_ExpectTrue(decoder.PushByte(144));
    TEST_ExpectTrue(decoder.PushByte(141));
    TEST_ExpectTrue(decoder.PushByte(136));
    //  € U+20AC
    TEST_ExpectTrue(decoder.PushByte(226));
    TEST_ExpectTrue(decoder.PushByte(130));
    TEST_ExpectTrue(decoder.PushByte(172));
    //  한 U+D55C
    TEST_ExpectTrue(decoder.PushByte(237));
    TEST_ExpectTrue(decoder.PushByte(149));
    TEST_ExpectTrue(decoder.PushByte(156));
    //  End `Text`
    TEST_ExpectTrue(decoder.PushByte(0));
}

protected static function Test_DecoderPoppingSuccess(Utf8Decoder decoder)
{
    local MutableText text1, text2;
    Issue("Popping `MutableText`s from `Utf8Decoder` does not produce expected"
        @ "amount of `MutableText`s.");
    text1 = decoder.PopText();
    text2 = decoder.PopText();
    TEST_ExpectNotNone(text1);
    TEST_ExpectNotNone(text2);
    TEST_ExpectNone(decoder.PopText());

    Issue("Popped `MutableText`s has wrong contents.");
    TEST_ExpectTrue(text1.GetCharacter(0).codePoint == 162);    //  ¢ U+00A2
    TEST_ExpectTrue(text1.GetCharacter(1).codePoint == 36);     //  $ U+0024
    TEST_ExpectTrue(text1.GetCharacter(2).codePoint == 2361);   //  ह U+0939
    TEST_ExpectTrue(text1.GetLength() == 3);
    TEST_ExpectTrue(text2.GetCharacter(0).codePoint == 66376);  //  𐍈 U+10348
    TEST_ExpectTrue(text2.GetCharacter(1).codePoint == 8364);   //  € U+20AC
    TEST_ExpectTrue(text2.GetCharacter(2).codePoint == 54620);  //  한 U+D55C
    TEST_ExpectTrue(text1.GetLength() == 3);
}

protected static function Test_DecoderHasUnfinishedData(Utf8Decoder decoder)
{
    local Utf8Decoder blankDecoder;
    Issue("Brand new `Utf8Decoder` is reported to have content inside.");
    blankDecoder = Utf8Decoder(__().memory.Allocate(class'Utf8Decoder'));
    TEST_ExpectFalse(blankDecoder.HasUnfinishedData());
    TEST_ExpectNone(blankDecoder.PopText());

    Issue("Emptied `Utf8Decoder` is reported to have content inside.");
    TEST_ExpectFalse(decoder.HasUnfinishedData());
    TEST_ExpectNone(decoder.PopText());

    Issue("Decoder that has contents is reported to be empty.");
    decoder.PushByte(226);
    TEST_ExpectTrue(decoder.HasUnfinishedData());
    decoder.PushByte(130);
    TEST_ExpectTrue(decoder.HasUnfinishedData());
    decoder.PushByte(172);
    TEST_ExpectTrue(decoder.HasUnfinishedData());
    decoder.PopText();
    decoder.PushByte(50);
    TEST_ExpectTrue(decoder.HasUnfinishedData());
}

protected static function Test_DecoderFail(Utf8Decoder decoder)
{
    Issue("Having incorrect byte prefix does not fail `Utf8Decoder`.");
    TEST_ExpectFalse(decoder.PushByte(248));    //  11111000 - 5 '1' bits
    TEST_ExpectFalse(decoder.PushByte(50));
    TEST_ExpectTrue(decoder.Failed());

    Issue("Pushing `0` byte does not reset `Utf8Decoder` from fail state.");
    decoder.PushByte(0);
    TEST_ExpectFalse(decoder.Failed());

    Issue("`Utf8Decoder`'s `PopText()` does not return `none` after failure.");
    TEST_ExpectNone(decoder.PopText());

    Issue("Having incorrect byte prefix does not fail `Utf8Decoder`.");
    TEST_ExpectTrue(decoder.PushByte(194));     //  11111000 - 5 '1' bits
    TEST_ExpectFalse(decoder.Failed());         //  Here it should be still fine
    TEST_ExpectFalse(decoder.PushByte(192));    //  11000000 - 2 '1' bits
    TEST_ExpectTrue(decoder.Failed());          //  But here it should be bad

    Issue("Pushing `0` byte does not reset `Utf8Decoder` from fail state.");
    decoder.PushByte(0);
    TEST_ExpectFalse(decoder.Failed());

    Issue("`Utf8Decoder`'s `PopText()` does not return `none` after failure.");
    TEST_ExpectNone(decoder.PopText());

    Issue("Overlong encoding for `0` byte does not lead to fail state.");
    TEST_ExpectTrue(decoder.PushByte(240));     //  11110000
    TEST_ExpectTrue(decoder.PushByte(128));     //  10000000
    TEST_ExpectTrue(decoder.PushByte(128));     //  10000000
    TEST_ExpectFalse(decoder.PushByte(128));    //  10000000
    TEST_ExpectTrue(decoder.Failed());

    Issue("Pushing `0` while building a code point does not produce error.");
    decoder.PushByte(0);
    TEST_ExpectTrue(decoder.PushByte(194));
    TEST_ExpectFalse(decoder.PushByte(0));
    TEST_ExpectFalse(decoder.Failed());
}

protected static function Test_EncodeDecode()
{
    local int           i;
    local Text          outputText;
    local Text          textRepresentation;
    local array<byte>   byteRepresentation;
    local Utf8Encoder   encoder;
    local Utf8Decoder   decoder;
    encoder = Utf8Encoder(__().memory.Allocate(class'Utf8Encoder'));
    decoder = Utf8Decoder(__().memory.Allocate(class'Utf8Decoder'));
    textRepresentation = __().text.FromString(default.simpleString);
    byteRepresentation = encoder.Encode(textRepresentation);
    for (i = 0; i < byteRepresentation.length; i += 1) {
        decoder.PushByte(byteRepresentation[i]);
    }
    decoder.PushByte(0);
    outputText = decoder.PopText();
    Issue("Decoding encoded `string` does not produce expected `Text` value.");
    TEST_ExpectNotNone(outputText);
    TEST_ExpectTrue(outputText.Compare(textRepresentation));
    TEST_ExpectTrue(outputText.ToPlainString() == default.simpleString);
    TEST_ExpectNone(decoder.PopText());
}

defaultproperties
{
    caseGroup   = "Avarice"
    caseName    = "Utf8"
    simpleString = "Hello world! Привет, мир! こんにちは世界！小熊维尼"
    //  Nice test data for later usage, cannot use it now because it is stored
    //  as UTF16 and we will need an appropriate decoder for that
    complexString  = "ăѣ𝔠ծềſģȟᎥ𝒋ǩľḿꞑȯ𝘱𝑞𝗋𝘴ȶ𝞄𝜈ψ𝒙𝘆𝚣1234567890!@#$%^&*()-_=+[{]};:'\",<.>/?~𝘈Ḇ𝖢𝕯٤ḞԍНǏ𝙅ƘԸⲘ𝙉০Ρ𝗤Ɍ𝓢ȚЦ𝒱Ѡ𝓧ƳȤѧᖯć𝗱ễ𝑓𝙜Ⴙ𝞲𝑗𝒌ļṃŉо𝞎𝒒ᵲꜱ𝙩ừ𝗏ŵ𝒙𝒚ź1234567890!@#$%^&*()-_=+[{]};:'\",<.>/?~АḂⲤ𝗗𝖤𝗙ꞠꓧȊ𝐉𝜥ꓡ𝑀𝑵Ǭ𝙿𝑄Ŗ𝑆𝒯𝖴𝘝𝘞ꓫŸ𝜡ả𝘢ƀ𝖼ḋếᵮℊ𝙝Ꭵ𝕛кιṃդⱺ𝓅𝘲𝕣𝖘ŧ𝑢ṽẉ𝘅ყž1234567890!@#$%^&*()-_=+[{]};:'\",<.>/?~Ѧ𝙱ƇᗞΣℱԍҤ١𝔍К𝓛𝓜ƝȎ𝚸𝑄Ṛ𝓢ṮṺƲᏔꓫ𝚈𝚭𝜶Ꮟçძ𝑒𝖿𝗀ḧ𝗂𝐣ҝɭḿ𝕟𝐨𝝔𝕢ṛ𝓼тú𝔳ẃ⤬𝝲𝗓1234567890!@#$%^&*()-_=+[{]};:'\",<.>/?~𝖠Β𝒞𝘋𝙴𝓕ĢȞỈ𝕵ꓗʟ𝙼ℕ০𝚸𝗤ՀꓢṰǓⅤ𝔚Ⲭ𝑌𝙕𝘢𝕤"
}