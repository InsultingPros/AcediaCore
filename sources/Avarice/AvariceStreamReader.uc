/**
 *      Helper class meant for reading byte stream sent to us by the Avarice
 *  application.
 *      Avarice sends us utf8-encoded JSONs one-by-one, prepending each of them
 *  with 4 bytes (big endian) that encode the length of the following message.
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
class AvariceStreamReader extends AcediaObject;

//  Are we currently reading length of the message (`true`) or
//  the message itself (`false`)?
var private bool                readingLength;
//      How many byte we have read so far.
//      Resets to zero when we finish reading either length of the message or
//  the message itself.
var private int                 readBytes;
//  Expected length of the next message
var private int                 nextMessageLength;
//  Message read so far
var private ByteArrayRef        nextMessage;
//  All the messages we have fully read, but did not yet return
var private array<MutableText>  outputQueue;
//  For converting read messages into `MutableText`
var private Utf8Decoder         decoder;
//  Set to `true` if Avarice input was somehow unacceptable.
//  Cannot be recovered from.
var private bool                hasFailed;

//  Maximum allowed size of JSON message sent from avarice;
//  Anything more than that is treated as a mistake.
//  TODO: make this configurable
var private const int           MAX_MESSAGE_LENGTH;

protected function Constructor()
{
    readingLength   = true;
    nextMessage     = ByteArrayRef(_.memory.Allocate(class'ByteArrayRef'));
    decoder         = Utf8Decoder(_.memory.Allocate(class'Utf8Decoder'));
}

protected function Finalizer()
{
    _.memory.FreeMany(outputQueue);
    _.memory.Free(nextMessage);
    _.memory.Free(decoder);
    outputQueue.length  = 0;
    nextMessage         = none;
    decoder             = none;
    hasFailed           = false;
}

/**
 *  Adds next `byte` from the input Avarice stream to the reader.
 *
 *      If input stream signals that message we have to read is too long
 *  (longer then `MAX_MESSAGE_LENGTH`) - enters a failed state and will
 *  no longer accept any input. Failed status can be checked with
 *  `Failed()` method.
 *      Otherwise cannot fail.
 *
 *  @param  nextByte    Next byte from the Avarice input stream.
 *  @return `false` if caller `AvariceStreamReader` is in a failed state
 *      (including if it entered one after pushing this byte)
 *      and `true` otherwise.
 */
public final function bool PushByte(byte nextByte)
{
    if (hasFailed) {
        return false;
    }
    if (readingLength)
    {
        //  Make space for the next 8 bits by shifting previously recorded ones
        nextMessageLength = nextMessageLength << 8;
        nextMessageLength += nextByte;
        readBytes += 1;
        if (readBytes >= 4)
        {
            readingLength = false;
            readBytes = 0;
        }
        //  Message either too long or so long it overfilled `MaxInt`
        if (    nextMessageLength > MAX_MESSAGE_LENGTH
            ||  nextMessageLength < 0)
        {
            hasFailed = true;
            return false;
        }
        return true;
    }
    nextMessage.AddItem(nextByte);
    readBytes += 1;
    if (readBytes >= nextMessageLength)
    {
        outputQueue[outputQueue.length] = decoder.Decode(nextMessage);
        nextMessage.Empty();
        readingLength = true;
        readBytes = 0;
        nextMessageLength = 0;
    }
    return true;
}

/**
 *  Returns all complete messages read so far.
 *
 *  Even if caller `AvariceStreamReader` entered a failed state - this method
 *  will return all the messages read before it has failed.
 *
 *  @return aAl complete messages read from Avarice stream so far
 */
public final function array<MutableText> PopMessages()
{
    local array<MutableText> result;
    result = outputQueue;
    outputQueue.length = 0;
    return result;
}

/**
 *  Is caller `AvariceStreamReader` in a failed state?
 *  See `PushByte()` method for details.
 *
 *  @return `true` iff caller `AvariceStreamReader` has failed.
 */
public final function bool Failed()
{
    return hasFailed;
}

defaultproperties
{
    MAX_MESSAGE_LENGTH = 26214400 // 25 * 1024 * 1024 = 25MB
}