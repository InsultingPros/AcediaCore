/**
 *      Class for encoding Acedia's `MutableText` value into UTF8 byte
 *  representation.
 *      This is a separate object instead of just a method to match design of
 *  `Utf8Decoder`.
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
class Utf8Encoder extends AcediaObject;

//  Limits on code point values that can be recorded with 1, 2, 3 and 4 bytes
//  respectively
var private int utfLimit1, utfLimit2, utfLimit3, utfLimit4;

//  Bit prefixes for UTF8 encoding
var private int utfMask2, utfMask3, utfMask4, utfMaskIn;
//  This integer will have only 6 last bits be 1s.
//  We need it to zero all but last 6 bits for `int`s (with `&` bit operator).
var private int lastSixBits;

/**
 *  Encodes passed `Text` object into UTF8 byte representation.
 *
 *  In case passed `text` is somehow broken and contains invalid Unicode
 *  code points - this method will return empty array.
 *
 *  @param  text    `Text` object to encode.
 *  @return UTF8 representation of passed `text` inside `ByteArrayRef`.
 *      `none` iff `text == none` or `text` contains invalid Unicode
 *      code points.
 */
public final function ByteArrayRef Encode(BaseText text)
{
    local int           i, nextCodepoint, textLength;
    local ByteArrayRef  buffer;
    if (__().text.IsEmpty(text)) {
        return none; // empty array
    }
    buffer = ByteArrayRef(_.memory.Allocate(class'ByteArrayRef'));
    textLength = text.GetLength();
    for (i = 0; i < textLength; i += 1)
    {
        nextCodepoint = text.GetCharacter(i).codePoint;
        if (nextCodepoint <= utfLimit1) {
            buffer.AddItem(nextCodepoint);
        }
        else if (nextCodepoint <= utfLimit2)
        {
            //  Drop 6 bits that will be recorded inside second byte and
            //  add 2-byte sequence mask
            buffer.AddItem(utfMask2 | (nextCodepoint >> 6));
            //  Take only last 6 bits for the second (last) byte
            //  + add inner-byte sequence mask
            buffer.AddItem(utfMaskIn | (nextCodepoint & lastSixBits));
        }
        else if (nextCodepoint <= utfLimit3)
        {
            //  Drop 12 bits that will be recorded inside second and third bytes
            //  and add 3-byte sequence mask
            buffer.AddItem(utfMask3 | (nextCodepoint >> 12));
            //  Drop 6 bits that will be recorded inside third byte and
            //  add inner-byte sequence mask
            buffer.AddItem(utfMaskIn | ((nextCodepoint >> 6) & lastSixBits));
            //  Take only last 6 bits for the third (last) byte
            //  + add inner-byte sequence mask
            buffer.AddItem(utfMaskIn | (nextCodepoint & lastSixBits));
        }
        else if (nextCodepoint <= utfLimit4)
        {
            //  Drop 18 bits that will be recorded inside second, third and
            //  fourth bytes, then add 4-byte sequence mask
            buffer.AddItem(utfMask4 | (nextCodepoint >> 18));
            //  Drop 12 bits that will be recorded inside third and fourth bytes
            //  and add inner-byte sequence mask
            buffer.AddItem(utfMaskIn | ((nextCodepoint >> 12) & lastSixBits));
            //  Drop 6 bits that will be recorded inside fourth byte
            //  and add inner-byte sequence mask
            buffer.AddItem(utfMaskIn | ((nextCodepoint >> 6) & lastSixBits));
            //  Take only last 6 bits for the fourth (last) byte
            //  + add inner-byte sequence mask
            buffer.AddItem(utfMaskIn | (nextCodepoint & lastSixBits));
        }
        else
        {
            //      Outside of known Unicode range
            //      Should not be possible, since `Text` is expected to
            //  contain only correct Unicode
            _.memory.Free(buffer);
            buffer = none;
            break;
        }
    }
    return buffer;
}

defaultproperties
{
    utfLimit1   = 127
    utfLimit2   = 2047
    utfLimit3   = 65535
    utfLimit4   = 1114111
    utfMask2    = 192   //  1 1 0 0 0 0 0 0
    utfMask3    = 224   //  1 1 1 0 0 0 0 0
    utfMask4    = 240   //  1 1 1 1 0 0 0 0
    utfMaskIn   = 128   //  1 0 0 0 0 0 0 0
    lastSixBits = 63    //  0 0 1 1 1 1 1 1
}