class AvariceTcpLink extends TcpLink
    dependson(LoggerAPI);

var private Global _;

var private string linkName;
var private string linkHost;
var private int linkPort;
var private IpAddr remoteAddress;
var private int ttt;

var private bool didWorkLastTick;

var private array<byte> buffer;

var private Utf8Encoder encoder;
var private Utf8Decoder decoder;

var private LoggerAPI.Definition infoSuccess;
var private LoggerAPI.Definition fatalBadPort;
var private LoggerAPI.Definition fatalCannotBindPort;
var private LoggerAPI.Definition fatalCannotResolveHost;
var private LoggerAPI.Definition fatalCannotConnect;

public final function bool Connect(string name, string host, int port)
{
    local InternetLink.IpAddr ip;
    local int usedPort;
    //  Apparently `TcpLink` ignores default values for these variables,
    //  so we set them here
    linkMode    = MODE_Binary;
    receiveMode = RMODE_Manual;
    _ = class'Global'.static.GetInstance();
    encoder = Utf8Encoder(_.memory.Allocate(class'Utf8Encoder'));
    decoder = Utf8Decoder(_.memory.Allocate(class'Utf8Decoder'));
    linkName = name;
    linkHost = host;
    linkPort = port;
    if (port <= 0)
    {
        _.logger.Auto(fatalBadPort)
            .ArgInt(port)
            .Arg(_.text.FromString(linkName));
        return false;
    }
    if (BindPort(, true) <= 0)
    {
        _.logger.Auto(fatalCannotBindPort)
            .ArgInt(port)
            .Arg(_.text.FromString(name));
        return false;
    }
    StringToIpAddr(host, remoteAddress);
    remoteAddress.port = port;
    if (remoteAddress.addr == 0) {
        Resolve(host);
    }
    else {
        OpenAddress();
    }
    return true;
}

event Resolved(IpAddr resolvedAddress)
{
    remoteAddress.addr = resolvedAddress.addr;
    OpenAddress();
}

private final function bool OpenAddress()
{
    if (!OpenNoSteam(remoteAddress)) {
        _.logger.Auto(fatalCannotConnect).Arg(_.text.FromString(linkName));
    }
    _.logger.Auto(infoSuccess).Arg(_.text.FromString(linkName));
}

event ResolveFailed()
{
    _.logger.Auto(fatalCannotResolveHost).Arg(_.text.FromString(linkHost));
    //  !Shut down!
}

event Tick(float delta)
{
    local array<byte> toSend;
    local AvariceMessage nextAMessage;
    local MutableText nextMessage;
    local int   i, j, dataRead, totalRead, iter;
    local byte  data[255];
    if (didWorkLastTick)
    {
        didWorkLastTick = false;
        return;
    }
    if (!IsDataPending()) {
        return;
    }
    while (true) {
        dataRead = ReadBinary(255, data);
        for (i = 0; i < dataRead; i += 1) {
            ttt += 1;
            decoder.PushByte(data[i]);
        }
        if (dataRead <= 0) {
            break;
        }
    }
    if (ttt >= 4095) {
        toSend = encoder.Encode(_.text.FromString("FLUSH"));
        data[0] = toSend[0];
        data[1] = toSend[1];
        data[2] = toSend[2];
        data[3] = toSend[3];
        data[4] = toSend[4];
        data[5] = 0;
        SendBinary(6, data);
    }
    if (dataRead > 0) {
        didWorkLastTick = true;
    }
    //  Obtain!
    nextMessage = decoder.PopText();
    while (nextMessage != none)
    {
        Log("SIZE:" @ nextMessage.GetLength() @ ttt);
        StopWatch(false);
        nextAMessage = _.avarice.MessageFromText(nextMessage);
        nextMessage.FreeSelf();
        nextMessage = nextAMessage.ToText();
        toSend = encoder.Encode(nextMessage);
        toSend[toSend.length] = 0;
        j = 0;
        for (i = 0; i < toSend.length; i += 1)
        {
            data[j] = toSend[i];
            j += 1;
            if (j >= 255) {
                j = 0;
                SendBinary(255, data);
            }
        }
        if (j > 0) {
            SendBinary(j, data);
        }
        nextMessage.FreeSelf();
        nextMessage = decoder.PopText();
        StopWatch(true);
    }
}

event Opened()
{
    //Log("[TestTcp] Accepted!");
    LOG("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
}

event Closed()
{
    //Log("[TestTcp] Closed!");
}

defaultproperties
{
    infoSuccess             = (l=LOG_Info,m="Successfully started Avarice link \"%1\"")
    fatalBadPort            = (l=LOG_Fatal,m="Bad port \"%1\" specified for Avarice link \"%2\"")
    fatalCannotBindPort     = (l=LOG_Fatal,m="Cannot bind port for Avarice link \"%1\"")
    fatalCannotResolveHost  = (l=LOG_Fatal,m="Cannot resolve host \"%1\" for Avarice link \"%2\"")
    fatalCannotConnect      = (l=LOG_Fatal,m="Connection for Avarice link \"%1\" was rejected")
}