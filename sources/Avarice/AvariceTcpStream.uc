/**
 *  Acedia's `TcpLink` class for connecting to Avarice.
 *  This class should be considered an internal implementation detail and not
 *  accessed directly.
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
class AvariceTcpStream extends TcpLink
    dependson(LoggerAPI);

var private Global _;

//  Reference to the link that has spawned us, to pass on messages.
var private AvariceLink ownerLink;

//  Information needed for connection
var private string  linkHost;
var private int     linkPort;
var private IpAddr  remoteAddress;

//      If `OpenNoSteam()` (inside `OpenAddress()`) call is made before Avarice
//  application started - connection will not succeed. Because of that
//  `AvariceTcpStream` will keep restarting its attempt to connect if it waited
//  for connection to go through for long enough.
//      This variable is set when `AvariceTcpStream` is initialized and it
//  defines how long we have to wait before reconnection attempt.
var private float   reconnectInterval;
//      This variable track how much time has passed since `OpenNoSteam()` call.
var private float   timeSpentConnecting;
//      For reconnections we need to remember whether we have already bound our
//  port, otherwise it will lead to errors in logs.
var private bool    portBound;

//  Array used to read to and write from TCP connection.
//  All the native methods use it, so avoid creating it locally in our methods.
var private byte buffer[255];

//  Used to convert our messages in a way appropriate for the network
var private Utf8Encoder         encoder;
//  Used to read and correctly interpret byte stream from Avarice
var private AvariceStreamReader avariceReader;

//  Arbitrary value indicating that next byte sequence from us reports amount of
//  bytes received so far
var private byte HEAD_BYTES_RECEIVED;
//  Arbitrary value indicating that next byte sequence from us contains
//  JSON message (prepended by it's length)
var private byte HEAD_MESSAGE;

//  Byte mask to extract lowest byte from the `int`s:
//  00000000 00000000 00000000 11111111
var private int byteMask;

//  `Text` values to be used as keys for getting information from
//  received messages
var private Text keyS, keyT, keyP;

var private LoggerAPI.Definition infoConnected;
var private LoggerAPI.Definition infoDisconnected;
var private LoggerAPI.Definition fatalNoLink;
var private LoggerAPI.Definition fatalBadPort;
var private LoggerAPI.Definition fatalCannotBindPort;
var private LoggerAPI.Definition fatalCannotResolveHost;
var private LoggerAPI.Definition fatalCannotConnect;
var private LoggerAPI.Definition fatalInvaliddUTF8;
var private LoggerAPI.Definition fatalInvalidMessage;

//  Starts this link, to stop it - simply destroy it
public final function StartUp(AvariceLink link, float reconnectTime)
{
    if (link == none)
    {
        Destroy();
        return;
    }
    ownerLink = link;
    //  Apparently `TcpLink` ignores default values for these variables,
    //  so we set them here
    linkMode    = MODE_Binary;
    receiveMode = RMODE_Manual;
    //  This actor does not have `AcediaActor` for a parent, so manually
    //  define `_` for convenience
    _ = class'Global'.static.GetInstance();
    //  Necessary constants
    keyS = _.text.FromString("s");
    keyT = _.text.FromString("t");
    keyP = _.text.FromString("p");
    //  For decoding input and encoding output
    encoder = Utf8Encoder(_.memory.Allocate(class'Utf8Encoder'));
    avariceReader =
        AvariceStreamReader(_.memory.Allocate(class'AvariceStreamReader'));
    linkHost = _.text.IntoString(link.GetHost());
    linkPort = link.GetPort();
    reconnectInterval = reconnectTime;
    TryConnecting();
}

private final function TryConnecting()
{
    if (linkPort <= 0)
    {
        _.logger.Auto(fatalBadPort)
            .ArgInt(linkPort)
            .Arg(ownerLink.GetName());
        Destroy();
        return;
    }
    //  `linkPort` is a port we are connecting to, which is different
    //  from the port we have to bind to use `OpenNoSteam()` method
    if (!portBound && BindPort(, true) <= 0)
    {
        _.logger.Auto(fatalCannotBindPort)
            .Arg(ownerLink.GetName());
        Destroy();
        return;
    }
    portBound = true;
    //  Try to read `linkHost` as an IP address first, in case of failure -
    //  try to resolve it from the host name
    StringToIpAddr(linkHost, remoteAddress);
    remoteAddress.port = linkPort;
    if (remoteAddress.addr == 0) {
        Resolve(linkHost);
    }
    else {
        OpenAddress();
    }
    timeSpentConnecting = 0.0;
}

event Resolved(IpAddr resolvedAddress)
{
    remoteAddress.addr = resolvedAddress.addr;
    OpenAddress();
}

event ResolveFailed()
{
    _.logger.Auto(fatalCannotResolveHost).Arg(_.text.FromString(linkHost));
    Destroy();
}

private final function OpenAddress()
{
    if (!OpenNoSteam(remoteAddress))
    {
        _.logger.Auto(fatalCannotConnect).Arg(ownerLink.GetName());
        Destroy();
    }
}

event Opened()
{
    _.logger.Auto(infoConnected).Arg(ownerLink.GetName());
    if (ownerLink != none) {
        ownerLink.ReceiveNetworkMessage(ANM_Connected);
    }
    else {
        _.logger.Auto(fatalNoLink).Arg(ownerLink.GetName());
    }
}

event Closed()
{
    _.logger.Auto(infoDisconnected).Arg(ownerLink.GetName());
    if (ownerLink != none) {
        ownerLink.ReceiveNetworkMessage(ANM_Connected);
    }
    else {
        _.logger.Auto(fatalNoLink).Arg(ownerLink.GetName());
    }
    portBound = false;
    timeSpentConnecting = 0.0;
}

event Destroyed()
{
    if (_ != none)
    {
        _.memory.Free(avariceReader);
        _.memory.Free(encoder);
        _.memory.Free(keyS);
        _.memory.Free(keyT);
        _.memory.Free(keyP);
        if (ownerLink != none) {
            ownerLink.ReceiveNetworkMessage(ANM_Death);
        }
        else {
            _.logger.Auto(fatalNoLink).Arg(ownerLink.GetName());
        }
    }
}

event Tick(float delta)
{
    if (linkState == STATE_Connected) {
        HandleIncomingData();
    }
    else
    {
        timeSpentConnecting += delta;
        if (timeSpentConnecting >= reconnectInterval)
        {
            Close();
            TryConnecting();
            timeSpentConnecting = 0.0;
        }
    }
}

private final function HandleIncomingData()
{
    local int                   i, totalReceivedBytes;
    local AvariceMessage        nextMessage;
    local array<MutableText>    receivedMessages;
    local int                   bytesRead;
    bytesRead = ReadBinary(255, buffer);
    while (bytesRead > 0)
    {
        totalReceivedBytes += bytesRead;
        for (i = 0; i < bytesRead; i += 1) {
            avariceReader.PushByte(buffer[i]);
        }
        bytesRead = ReadBinary(255, buffer);
    }
    if (avariceReader.Failed())
    {
        _.logger.Auto(fatalInvaliddUTF8).Arg(ownerLink.GetName());
        Destroy();
        return;
    }
    //  Tell Avarice how many bytes we have received, so it can send
    //  more information
    if (totalReceivedBytes > 0) {
        SendReceived(totalReceivedBytes);
    }
    receivedMessages = avariceReader.PopMessages();
    for (i = 0; i < receivedMessages.length; i += 1)
    {
        nextMessage = MessageFromText(receivedMessages[i]);
        //  This means received message is invalid,
        //  which means whatever we are connected to is feeding us invalid data,
        //  which means connection should be cut immediately
        if (nextMessage == none)
        {
            _.logger.Auto(fatalInvalidMessage).Arg(ownerLink.GetName());
            _.memory.Free(nextMessage);
            _.memory.FreeMany(receivedMessages);
            Destroy();
            return;
        }
        ownerLink.ReceiveNetworkMessage(ANM_Message, nextMessage);
        _.memory.Free(nextMessage);
    }
    _.memory.FreeMany(receivedMessages);
}

public final function SendMessage(BaseText textMessage)
{
    local int           i;
    local int           nextByte;
    local ByteArrayRef  message;
    local int           messageLength;
    if (textMessage == none) {
        return;
    }
    message = encoder.Encode(textMessage);
    messageLength = message.GetLength();
    //  Signal that we are sending next message
    buffer[0] = HEAD_MESSAGE;
    //      Next four bytes (with indices 1, 2, 3 and 4) must contain length of
    //  the message's contents as a 4-byte unsigned integer in big endian.
    //      UnrealScript does not actually have an unsigned integer type, but
    //  even `int`'s positive value range is enough, since avarice server
    //  will not accept message length that is even close to `MaxInt`.
    buffer[4] = messageLength & byteMask;
    messageLength -= buffer[4];
    messageLength = messageLength >> 8;
    buffer[3] = messageLength & byteMask;
    messageLength -= buffer[3];
    messageLength = messageLength >> 8;
    buffer[2] = messageLength & byteMask;
    messageLength -= buffer[2];
    messageLength = messageLength >> 8;
    buffer[1] = messageLength;
    //  Record the rest of the message in chunks of `255`, since `SendBinary()`
    //  can only send this much at once
    nextByte = 5;   //  We have already added 5 bytes in the code above
    messageLength = message.GetLength();
    for (i = 0; i < messageLength; i += 1)
    {
        buffer[nextByte] = message.GetItem(i);
        nextByte += 1;
        if (nextByte >= 255)
        {
            nextByte = 0;
            SendBinary(255, buffer);
        }
    }
    //  Cycle above only sent full chunks of `255`, so send the remainder now
    if (nextByte > 0) {
        SendBinary(nextByte, buffer);
    }
    message.FreeSelf();
}

private final function SendReceived(int received)
{
    //  Signal that we are sending amount of bytes received this tick
    buffer[0] = HEAD_BYTES_RECEIVED;
    //  Next four bytes (with indices 1 and 2) must contain amount of bytes
    //  received as a 2-byte unsigned integer in big endian
    buffer[2] = received & byteMask;
    received -= buffer[2];
    received = received >> 8;
    buffer[1] = received;
    SendBinary(3, buffer);
}

private final function AvariceMessage MessageFromText(BaseText message)
{
    local Parser            parser;
    local AvariceMessage    result;
    local HashTable         parsedMessage;
    local AcediaObject      item;
    if (message == none) {
        return none;
    }
    parser = _.text.Parse(message);
    parsedMessage = _.json.ParseHashTableWith(parser);
    parser.FreeSelf();
    if (parsedMessage == none) {
        return none;
    }
    result = AvariceMessage(_.memory.Allocate(class'AvariceMessage'));
    item = parsedMessage.TakeItem(keyS);
    if (item == none || item.class != class'Text')
    {
        _.memory.Free(item);
        _.memory.Free(parsedMessage);
        _.memory.Free(result);
        return none;
    }
    result.service = Text(item);
    item = parsedMessage.TakeItem(keyT);
    if (item == none || item.class != class'Text')
    {
        _.memory.Free(item);
        _.memory.Free(parsedMessage);
        _.memory.Free(result);
        return none;
    }
    result.type = Text(item);
    result.parameters = parsedMessage.TakeItem(keyP);
    _.memory.Free(parsedMessage);
    return result;
}

defaultproperties
{
    HEAD_BYTES_RECEIVED     = 85
    HEAD_MESSAGE            = 42
    byteMask                = 255   //  Only lowest 8 bits are `1`
    infoConnected           = (l=LOG_Info,m="Avarice link \"%1\" connected")
    infoDisconnected        = (l=LOG_Info,m="Avarice link \"%1\" disconnected")
    fatalNoLink             = (l=LOG_Fatal,m="Unexpected internal `none` value for Avarice link \"%1\"")
    fatalBadPort            = (l=LOG_Fatal,m="Bad port \"%1\" specified for Avarice link \"%2\"")
    fatalCannotBindPort     = (l=LOG_Fatal,m="Cannot bind port for Avarice link \"%1\"")
    fatalCannotResolveHost  = (l=LOG_Fatal,m="Cannot resolve host \"%1\" for Avarice link \"%2\"")
    fatalCannotConnect      = (l=LOG_Fatal,m="Connection for Avarice link \"%1\" was rejected")
    fatalInvaliddUTF8       = (l=LOG_Fatal,m="Avarice link \"%1\" has received invalid UTF8, aborting connection")
    fatalInvalidMessage     = (l=LOG_Fatal,m="Avarice link \"%1\" has received invalid message, aborting connection")
}