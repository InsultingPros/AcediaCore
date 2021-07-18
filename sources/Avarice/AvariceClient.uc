class AvariceClient extends AcediaObject;

enum AvariceClientState
{
    ACS_Waiting,
    ACS_ReadingID,
    ACS_ReadingLength,
    ACS_ReadingPayload,
    ACS_Invalid
};

var private int currentID;
var private int currentMessageLength;
var private array<byte> currentPayload;

var private AvariceClientState currentState;
var private int bytesLeftToRead;
var private byte buffer[255];
var private array<byte> longBuffer;
var private int pendingBytes;

public final function PushByte(byte nextByte)
{
    if (nextByte == 0)
    {
        if (bytesLeftToRead > 0)
        {
            //  ACK for short message (with id)
        }
        currentState = ACS_Waiting;
        ResetBuffer();
        return;
    }
    else if (currentState == ACS_Invalid)
    {
        //  ACK of invalid message's end
        return;
    }
    else if (currentState == ACS_Waiting)
    {
        currentID = nextByte;
        currentID = currentID << 8;
        currentState = ACS_ReadingID;
    }
    else if (currentState == ACS_ReadingID)
    {
        currentID += nextByte;
        currentState = ACS_ReadingLength;
        bytesLeftToRead = 2;
    }
    else if (currentState == ACS_ReadingLength)
    {
        bytesLeftToRead -= 1;
        if (bytesLeftToRead > 0)
        {
            currentMessageLength = nextByte;
            currentMessageLength = currentMessageLength << 8;
        }
        else
        {
            currentMessageLength += nextByte;
            currentState = ACS_ReadingPayload;
            bytesLeftToRead = currentMessageLength;
        }
    }
    else if (currentState == ACS_ReadingPayload)
    {
        currentPayload[currentPayload.length] = nextByte;
        //  Decode payload into `AvariceMessage`
        //  Send messages via Acedia's signals
        bytesLeftToRead -= 1;
        if (bytesLeftToRead == 0)
        {
            currentState = ACS_Waiting;
            //  ACK into buffer
        }
    }
}

private final function ResetBuffer()
{
    pendingBytes = 0;
    longBuffer.length = 0;
}

defaultproperties
{
}