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
    Test_Decoding(decoder);
    decoder = Utf8Decoder(__().memory.Allocate(class'Utf8Decoder')); // reset
    Test_DecoderFail(decoder);

    Context("Testing encoding Acedia's `Text` into UTF8 byte stream.");
    Test_EncodeDecode();
}

protected static function Test_Decoding(Utf8Decoder decoder)
{
    local ByteArrayRef  stream;
    local MutableText   text1, text2;
    stream = ByteArrayRef(__().memory.Allocate(class'ByteArrayRef'));
    Issue("Pushing byte stream into `Utf8Decoder` fails when it should not.");
    stream.AddItem(194).AddItem(162);               //  ¢ U+00A2
    stream.AddItem(36);                             //  $ U+0024
    stream.AddItem(224).AddItem(164).AddItem(185);  //  ह U+0939
    text1 = decoder.Decode(stream);
    TEST_ExpectNotNone(text1);
    stream.Empty();
    //  𐍈 U+10348
    stream.AddItem(240).AddItem(144).AddItem(141).AddItem(136);
    stream.AddItem(226).AddItem(130).AddItem(172);  //  € U+20AC
    stream.AddItem(237).AddItem(149).AddItem(156);  //  한 U+D55C
    text2 = decoder.Decode(stream);
    TEST_ExpectNotNone(text2);

    Issue("Decoded `MutableText`s has wrong contents.");
    TEST_ExpectTrue(text1.GetCharacter(0).codePoint == 162);    //  ¢ U+00A2
    TEST_ExpectTrue(text1.GetCharacter(1).codePoint == 36);     //  $ U+0024
    TEST_ExpectTrue(text1.GetCharacter(2).codePoint == 2361);   //  ह U+0939
    TEST_ExpectTrue(text1.GetLength() == 3);
    TEST_ExpectTrue(text2.GetCharacter(0).codePoint == 66376);  //  𐍈 U+10348
    TEST_ExpectTrue(text2.GetCharacter(1).codePoint == 8364);   //  € U+20AC
    TEST_ExpectTrue(text2.GetCharacter(2).codePoint == 54620);  //  한 U+D55C
    TEST_ExpectTrue(text2.GetLength() == 3);
}

protected static function Test_DecoderFail(Utf8Decoder decoder)
{
    local ByteArrayRef stream;
    stream = ByteArrayRef(__().memory.Allocate(class'ByteArrayRef'));
    Issue("Having incorrect byte prefix does not fail `Utf8Decoder`.");
    stream.AddItem(248).AddItem(50);
    TEST_ExpectNone(decoder.Decode(stream));

    Issue("Having incorrect byte prefix does not fail `Utf8Decoder`.");
    //  11111000 - 5 '1' bits
    //  11000000 - 2 '1' bits
    stream.AddItem(194).AddItem(192);
    TEST_ExpectNone(decoder.Decode(stream));
}

protected static function Test_EncodeDecode()
{
    local Text          outputText;
    local Text          textRepresentation;
    local ByteArrayRef  byteRepresentation;
    local Utf8Encoder   encoder;
    local Utf8Decoder   decoder;
    encoder = Utf8Encoder(__().memory.Allocate(class'Utf8Encoder'));
    decoder = Utf8Decoder(__().memory.Allocate(class'Utf8Decoder'));
    textRepresentation = __().text.FromString(default.simpleString);
    byteRepresentation = encoder.Encode(textRepresentation);
    outputText = decoder.Decode(byteRepresentation).IntoText();
    Issue("Decoding encoded `string` does not produce expected `Text` value.");
    TEST_ExpectNotNone(outputText);
    TEST_ExpectTrue(outputText.Compare(textRepresentation));
    TEST_ExpectTrue(outputText.ToString() == default.simpleString);
}

defaultproperties
{
    caseGroup   = "Text"
    caseName    = "Utf8Encoding"
    simpleString = "Hello world! Привет, мир! こんにちは世界！小熊维尼"
    //  Nice test data for later usage, cannot use it now because it is stored
    //  as UTF16 and we will need an appropriate decoder for that
    complexString  = "ăѣ𝔠ծềſģȟᎥ𝒋ǩľḿꞑȯ𝘱𝑞𝗋𝘴ȶ𝞄𝜈ψ𝒙𝘆𝚣1234567890!@#$%^&*()-_=+[{]};:'\",<.>/?~𝘈Ḇ𝖢𝕯٤ḞԍНǏ𝙅ƘԸⲘ𝙉০Ρ𝗤Ɍ𝓢ȚЦ𝒱Ѡ𝓧ƳȤѧᖯć𝗱ễ𝑓𝙜Ⴙ𝞲𝑗𝒌ļṃŉо𝞎𝒒ᵲꜱ𝙩ừ𝗏ŵ𝒙𝒚ź1234567890!@#$%^&*()-_=+[{]};:'\",<.>/?~АḂⲤ𝗗𝖤𝗙ꞠꓧȊ𝐉𝜥ꓡ𝑀𝑵Ǭ𝙿𝑄Ŗ𝑆𝒯𝖴𝘝𝘞ꓫŸ𝜡ả𝘢ƀ𝖼ḋếᵮℊ𝙝Ꭵ𝕛кιṃդⱺ𝓅𝘲𝕣𝖘ŧ𝑢ṽẉ𝘅ყž1234567890!@#$%^&*()-_=+[{]};:'\",<.>/?~Ѧ𝙱ƇᗞΣℱԍҤ١𝔍К𝓛𝓜ƝȎ𝚸𝑄Ṛ𝓢ṮṺƲᏔꓫ𝚈𝚭𝜶Ꮟçძ𝑒𝖿𝗀ḧ𝗂𝐣ҝɭḿ𝕟𝐨𝝔𝕢ṛ𝓼тú𝔳ẃ⤬𝝲𝗓1234567890!@#$%^&*()-_=+[{]};:'\",<.>/?~𝖠Β𝒞𝘋𝙴𝓕ĢȞỈ𝕵ꓗʟ𝙼ℕ০𝚸𝗤ՀꓢṰǓⅤ𝔚Ⲭ𝑌𝙕𝘢𝕤"
}