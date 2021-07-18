/**
 *      Class for decoding UTF8 byte stream into Acedia's `MutableText` value.
 *      It is made to work with incoming, and possibly incomplete, streams of
 *  bytes: instead of consuming the whole utf8 text, it is made to consume it
 *  byte-by-byte and store `MutableText`s that it parsed from the stream
 *  (assumes that separate `MutableText`s are separated by `0` byte).
 *      This implementation should correctly convert any valid UTF8, but it is
 *  not guaranteed to reject any invalid UTF8. In particular, it accepts
 *  overlong code point encodings (except overlong encoding of zero).
 *  It, however, does check whether every byte has a correct bit prefix and
 *  does not attempt to repair input data if it finds invalid one.
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

/**
 *  `Utf8Decoder` consumes byte by byte with `PushByte()` method and it's
 *  algorithm is simple:
 *      1.  If it encounters a byte that encodes a singular code point by
 *              itself (starts with `0` bit) - it is added as a codepoint;
 *      2.  If it encounters byte which indicates that next code point is
 *              composed out of several bytes (starts with 110, 1110 or 11110) -
 *              remembers that it has to read several "inner" bytes belonging to
 *              the same code point and starts to expect them instead;
 *      3.  If it ever encounters a byte with unexpected (and thus invalid)
 *              bit prefix - enters a failed state;
 *      4.  If it ever encounters a `0` byte:
 *          *   If it was not in a failed state - records `MutableText`
 *                  accumulated so far;
 *          *   Clears failed state.
 */

var private bool failedState;

//  Variables for building a multi-byte code point
var private int nextCodePoint;
var private int innerBytesLeft;

//  `MutableText` we are building right now
var private MutableText         nextText;
//  `MutableText`s we have already built
var private array<MutableText>  outputQueue;

//  These masks (`maskDropN`) allow to turn into zero first `N` bits in
//  the byte with `&` operator.
var private byte maskDrop1, maskDrop2, maskDrop3, maskDrop4, maskDrop5;
//      These masks (`maskTakeN`) allow to turn into zero all but first `N` bits
//  in the byte with `&` operator.
//      `maskTakeN == ~maskDropN`.
var private byte maskTake1, maskTake2, maskTake3, maskTake4, maskTake5;

protected function Constructor()
{
    nextText = _.text.Empty();
}

protected function Finalizer()
{
    _.memory.Free(nextText);
    _.memory.FreeMany(outputQueue);
    nextText            = none;
    failedState         = false;
    outputQueue.length  = 0;
    innerBytesLeft      = 0;
    nextCodePoint       = 0;
}

/**
 *  Checks whether data in the `MutableText` that caller `Utf8Decoder` is
 *  currently filling was detected to be invalid.
 *
 *  This state can be reset by pushing `0` byte into caller `Utf8Decoder`.
 *  See `PushByte()` for more info.
 *
 *  @return `true` iff  caller `Utf8Decoder` is not in a failed state.
 */
public final function bool Failed()
{
    return failedState;
}

/**
 *      Checks whether caller `Utf8Decoder` has any data put in
 *  the `MutableText` it is currently building.
 *      Result is guaranteed to be `false` after `self.PushByte(0)` call, since
 *  it starts a brand new `MutableText`.
 */
public final function bool HasUnfinishedData()
{
    if (innerBytesLeft > 0)         return true;
    if (nextText.GetLength() > 0)   return true;
    return false;
}

/**
 *  Returns next `MutableText` that was successfully decoded by
 *  the caller `Utf8Decoder`, removing it from the output queue.
 *
 *  @return Next `MutableText` in the caller `Utf8Decoder`'s output queue.
 *      `none` iff output queue is empty. `MutableText`s are returned in order
 *      they were decoded.
 */
public final function MutableText PopText()
{
    local MutableText result;
    if (outputQueue.length <= 0) {
        return none;
    }
    result = outputQueue[0];
    outputQueue.Remove(0, 1);
    return result;
}

/**
 *  Adds next `byte` from the byte stream that is supposed to encode UTF8 text.
 *  To finish building `MutableText` pass `0` byte into this method, which will
 *  `MutableText` built so far into an "output queue" (accessible with
 *  `PopText()`) and start building a new one.
 *
 *      This method expects `byte`s, in order, from a sequence that has correct
 *  UTF8 encoding. If method detects incorrect UTF8 sequence - it will be put
 *  into a "failed state", discarding `MutableText` it was currently building,
 *  along with any further input (except `0` byte).
 *      Pushing `0` byte will restore `Utf8Decoder` from a failed state and it
 *  will start building a new `MutableText`.
 *
 *  @param  nextByte    next byte from byte stream that is supposed to encode
 *      UTF8 text. `0` will make caller `Utf8Decoder` start building new
 *      `MutableText`.
 *  @return `true` iff caller `Utf8Decoder` was not in a failed state and
 *      operation was successful.
 */
public final function bool PushByte(byte nextByte)
{
    if (nextByte == 0)      return QueueCurrentText();
    if (failedState)        return false;
    if (innerBytesLeft > 0) return PushInnerByte(nextByte);

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
    failedState = true;
    return false;
}

//      This method is responsible for pushing "inner" bytes: bytes that come
//  after the first one when code point is encoded with multiple bytes.
//  All of them are expected to have 10xxxxxx prefix.
//      Assumes `innerBytesLeft > 0` and `failedState == false`
//  to avoid needless checks.
private final function bool PushInnerByte(byte nextByte)
{
    //  Fail if `nextByte` does not have an expected form: 10xxxxxx
    if ((nextByte & maskTake2) != maskTake1)
    {
        failedState = true;
        return false;
    }
    //  Since inner bytes have the form of 10xxxxxx, they all carry only 6 bits
    //  that actually encode code point, so to make space for those bits we must
    //  shift previously added code points by `6`
    nextCodePoint = (nextCodePoint << 6) + (nextByte & maskDrop2);
    innerBytesLeft -= 1;
    if (innerBytesLeft <= 0)
    {
        //  We forbid overlong encoding of `0`
        //  (as does the Unicode standard)
        if (nextCodePoint == 0)
        {
            failedState = true;
            return false;
        }
        AppendCodePoint(nextCodePoint);
    }
    return true;
}

private final function AppendCodePoint(int codePoint)
{
    local Text.Character nextCharacter;
    nextCharacter.codePoint = codePoint;
    nextText.AppendCharacter(nextCharacter);
}

//  Return `true` if `MutableText` was added to the queue
//  (there were no encoding errors)
private final function bool QueueCurrentText()
{
    local bool result;
    //  If we still do not have all bytes for the character we were building -
    //  then passed UTF8 was invalid
    failedState = failedState || innerBytesLeft > 0;
    result = !failedState;
    if (failedState) {
        _.memory.Free(nextText);
    }
    else {
        outputQueue[outputQueue.length] = nextText;
    }
    failedState = false;
    innerBytesLeft = 0;
    nextText = _.text.Empty();
    return result;
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