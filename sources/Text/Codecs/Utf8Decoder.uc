/**
 *      Class for decoding UTF8 byte stream into Acedia's `MutableText` value.
 *      This is a separate object instead of just a method, because it allows
 *  to make code simpler by storing state variables related to
 *  the decoding process.
 *      This implementation should correctly convert any valid UTF8, but it is
 *  not guaranteed to reject any invalid UTF8. In particular, it accepts
 *  overlong code point encodings. It does check whether every byte has
 *  a correct bit prefix and does not attempt to repair input data if it finds
 *  invalid one.
 *      See [wiki page](https://en.wikipedia.org/wiki/UTF-8) for details.
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
class Utf8Decoder extends AcediaObject;

//  Variables for building a multi-byte code point.
//  Stored as a class member variables to avoid copying them between methods.
var private MutableText builtText;
var private int         nextCodePoint;
var private int         innerBytesLeft;

//  These masks (`maskDropN`) allow to turn into zero first `N` bits in
//  the byte with `&` operator.
var private byte maskDrop1, maskDrop2, maskDrop3, maskDrop4, maskDrop5;
//      These masks (`maskTakeN`) allow to turn into zero all but first `N` bits
//  in the byte with `&` operator.
//      `maskTakeN == ~maskDropN`.
var private byte maskTake1, maskTake2, maskTake3, maskTake4, maskTake5;

/**
 *  Decodes passed `byte` array (that contains utf8-encoded text) into
 *  the `MutableText` type.
 *
 *  @param  byteStream  Byte stream to decode.
 *  @return `MutableText` that contains `byteStream`'s text data.
 *      `none` iff either `byteStream == none` or it's contents do not
 *      correspond to a (valid) utf8-encoded text.
 */
public final function MutableText Decode(ByteArrayRef byteStream)
{
    local int           i;
    local int           length;
    local MutableText   result;
    if (byteStream == none) {
        return none;
    }
    nextCodePoint   = 0;
    innerBytesLeft  = 0;
    builtText       = _.text.Empty();
    length = byteStream.GetLength();
    for (i = 0; i < length; i += 1)
    {
        if (!PushByte(byteStream.GetItem(i)))
        {
            _.memory.Free(builtText);
            return none;
        }
    }
    if (innerBytesLeft <= 0) {
        result = builtText;
    }
    else {
        _.memory.Free(builtText);
    }
    builtText = none;
    return result;
}

private final function bool PushByte(byte nextByte)
{
    if (innerBytesLeft > 0) {
        return PushInnerByte(nextByte);
    }
    //  Form of 0xxxxxxx means 1 byte per code point
    if ((nextByte & maskTake1) == 0)
    {
        AppendCodePoint(nextByte);
        return true;
    }
    //  Form of 110xxxxx means 2 bytes per code point
    if ((nextByte & maskTake3) == maskTake2)    //  maskTake2 == 1 1 0 0 0 0 0 0
    {
        nextCodePoint = nextByte & maskDrop3;
        innerBytesLeft = 1;
        return true;
    }
    //  Form of 1110xxxx means 3 bytes per code point
    if ((nextByte & maskTake4) == maskTake3)    //  maskTake3 == 1 1 1 0 0 0 0 0
    {
        nextCodePoint = nextByte & maskDrop4;
        innerBytesLeft = 2;
        return true;
    }
    //  Form of 11110xxx means 4 bytes per code point
    if ((nextByte & maskTake5) == maskTake4)    //  maskTake4 == 1 1 1 1 0 0 0 0
    {
        nextCodePoint = nextByte & maskDrop5;
        innerBytesLeft = 3;
        return true;
    }
    //  `nextByte` must have has one of the above forms
    //  (or 10xxxxxx that is handled in `PushInnerByte()`)
    return false;
}

//      This method is responsible for pushing "inner" bytes: bytes that come
//  after the first one when code point is encoded with multiple bytes.
//  All of them are expected to have 10xxxxxx prefix.
//      Assumes `innerBytesLeft > 0` to avoid needless checks.
private final function bool PushInnerByte(byte nextByte)
{
    //  Fail if `nextByte` does not have an expected form: 10xxxxxx
    if ((nextByte & maskTake2) != maskTake1) {
        return false;
    }
    //  Since inner bytes have the form of 10xxxxxx, they all carry only 6 bits
    //  that actually encode code point, so to make space for those bits we must
    //  shift previously added code points by `6`
    nextCodePoint = (nextCodePoint << 6) + (nextByte & maskDrop2);
    innerBytesLeft -= 1;
    if (innerBytesLeft <= 0) {
        AppendCodePoint(nextCodePoint);
    }
    return true;
}

private final function AppendCodePoint(int codePoint)
{
    local BaseText.Character nextCharacter;
    nextCharacter.codePoint = codePoint;
    builtText.AppendCharacter(nextCharacter);
}

defaultproperties
{
    maskDrop1 = 127 //  0 1 1 1 1 1 1 1
    maskDrop2 = 63  //  0 0 1 1 1 1 1 1
    maskDrop3 = 31  //  0 0 0 1 1 1 1 1
    maskDrop4 = 15  //  0 0 0 0 1 1 1 1
    maskDrop5 = 7   //  0 0 0 0 0 1 1 1
    maskTake1 = 128 //  1 0 0 0 0 0 0 0
    maskTake2 = 192 //  1 1 0 0 0 0 0 0
    maskTake3 = 224 //  1 1 1 0 0 0 0 0
    maskTake4 = 240 //  1 1 1 1 0 0 0 0
    maskTake5 = 248 //  1 1 1 1 1 0 0 0
}