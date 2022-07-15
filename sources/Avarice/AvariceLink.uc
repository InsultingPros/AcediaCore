/**
 *      Provide interface for the connection to Avarice application.
 *  It's parameters are defined in Acedia's config.
 *      Class provides methods to obtain its configuration information
 *  (name, address, port), methods to check and change the status of connection,
 *  signals to handle arriving messages and ways to send messages back.
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
class AvariceLink extends AcediaObject;

/**
 *      Objects of this class are supposed to be obtained via the
 *  `AvariceAPI.GetLink()` method. Available links are automatically initialized
 *  based on the configs and their parameters cannot be changed.
 *      It is also possible to spawn a link of your own by creating an object of
 *  this class (`AvariceLink`) and calling `Initialize()` method with
 *  appropriate parameters. To start the link then simply call `StartUp()`.
 *  But such links will not appear in the list of available links in
 *  `AvariceAPI`.
 */

//  Actual work of dealing with network input/output is done in
//  the `AvariceTcpStream` `Actor` class that is stored inside this reference
var private NativeActorRef tcpStream;

//  `tcpStream` communicates with this class by informing it about specific
//  events. This enum describes all of their types.
enum AvariceNetworkMessage
{
    //  Connection with Avarice established - can happen several times in case
    //  connection is interrupted
    ANM_Connected,
    //  We have lost connection with Avarice, but normally  will attempt to
    //  reconnect back
    ANM_Disconnected,
    //  JSON message received
    ANM_Message,
    //  Connection died: either was manually closed, host address could not
    //  be resolved or invalid data was received from Avarice
    ANM_Death
};

//  Name of this link, specified in the config
var private Text    linkName;
//  Host of the Avarice instance we are connecting to
var private Text    linkHost;
//  Port used by the Avarice instance we are connecting to
var private int     linkPort;

var private SimpleSignal onConnectedSignal;
var private SimpleSignal onDisconnectedSignal;
var private SimpleSignal onDeathSignal;
//      We want to have a separate signal for each message "service", since most
//  users of `AvariceLink` would only care about one particular service.
//      To achieve that we use this array as a "service name" <-> "signal" map.
var private HashTable serviceSignalMap;

var private const int TSERVICE_PREFIX, TTYPE_PREFIX;
var private const int TPARAMS_PREFIX, TMESSAGE_SUFFIX;

var private LoggerAPI.Definition fatalCannotSpawn;

protected function Constructor()
{
    onConnectedSignal = SimpleSignal(_.memory.Allocate(class'SimpleSignal'));
    onDisconnectedSignal = SimpleSignal(_.memory.Allocate(class'SimpleSignal'));
    onDeathSignal = SimpleSignal(_.memory.Allocate(class'SimpleSignal'));
    serviceSignalMap = _.collections.EmptyHashTable();
}

protected function Finalizer()
{
    local Actor storedStream;
    _.memory.Free(onConnectedSignal);
    _.memory.Free(onDisconnectedSignal);
    _.memory.Free(onDeathSignal);
    _.memory.Free(serviceSignalMap);
    _.memory.Free(linkName);
    _.memory.Free(linkHost);
    onConnectedSignal       = none;
    onDisconnectedSignal    = none;
    onDeathSignal           = none;
    serviceSignalMap        = none;
    linkName                = none;
    linkHost                = none;
    linkPort                = 0;
    if (tcpStream == none) {
        return;
    }
    storedStream = tcpStream.Get();
    if (storedStream != none) {
        storedStream.Destroy();
    }
    tcpStream.FreeSelf();
    tcpStream = none;
}

/**
 *  Initializes this caller `AvariceLink` with config data.
 *
 *  Can only successfully (for that `name` and `host` must not be `none`)
 *  be called once.
 *
 *  @param  name    Alias (case-insensitive) of caller `AvariceLink`.
 *      Must not be `none`.
 *  @param  host    Host of the Avarice instance that caller `AvariceLink` is
 *      connecting to. Must not be `none`.
 *  @param  name    Port used by the Avarice instance that caller `AvariceLink`
 *      is connecting to.
 */
public final function Initialize(BaseText name, BaseText host, int port)
{
    if (tcpStream != none)  return;
    if (name == none)       return;
    if (host == none)       return;

    linkName = name.Copy();
    linkHost = host.Copy();
    linkPort = port;
    tcpStream = _server.unreal.ActorRef(none);
}

/**
 *  Signal that will be emitted whenever caller `AvariceLink` connects to
 *  Avarice. This event can be emitted multiple times if case link temporarily
 *  loses it's TCP connection or if connection is killed off due to errors
 *  (or manually).
 *
 *  [Signature]
 *  void <slot>()
 */
/* SIGNAL */
public final function SimpleSlot OnConnected(AcediaObject receiver)
{
    return SimpleSlot(onConnectedSignal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted whenever caller `AvariceLink` disconnects from
 *  Avarice. Disconnects can temporarily be cause by network issue and
 *  `AvariceLink` will attempt to restore it's connection. To detect when
 *  connection was permanently severed use `OnDeath` signal instead.
 *
 *  [Signature]
 *  void <slot>()
 */
/* SIGNAL */
public final function SimpleSlot OnDisconnected(AcediaObject receiver)
{
    return SimpleSlot(onDisconnectedSignal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted whenever connection is closed and dropped:
 *  either due to bein unable to resolve host's address, receiving incorrect
 *  input from Avarice or someone manually closing it.
 *
 *  [Signature]
 *  void <slot>()
 */
/* SIGNAL */
public final function SimpleSlot OnDeath(AcediaObject receiver)
{
    return SimpleSlot(onDeathSignal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted whenever caller `AvariceLink` disconnects from
 *  Avarice. Disconnects can temporarily be cause by network issue and
 *  `AvariceLink` will attempt to restore it's connection. To detect when
 *  connection was permanently severed use `OnDeath` signal instead.
 *
 *  @param  service Name of the service, whos messages one wants to receive.
 *      `none` will be treated as an empty `Text`.
 *
 *  [Signature]
 *  void <slot>(AvariceLink link, AvariceMessage message)
 *  @param  link    Link that has received message.
 *  @param  message Received message.
 *      Can be any JSON-compatible value (see `JSONAPI.IsCompatible()`
 *      for more information).
 */
/* SIGNAL */
public final function Avarice_OnMessage_Slot OnMessage(
    AcediaObject    receiver,
    BaseText        service)
{
    return Avarice_OnMessage_Slot(GetServiceSignal(service).NewSlot(receiver));
}

private final function Avarice_OnMessage_Signal GetServiceSignal(
    BaseText service)
{
    local Avarice_OnMessage_Signal result;
    if (service != none) {
        service = service.Copy();
    }
    else {
        service = Text(_.memory.Allocate(class'Text'));
    }
    result = Avarice_OnMessage_Signal(serviceSignalMap.GetItem(service));
    if (result == none)
    {
        result = Avarice_OnMessage_Signal(
            _.memory.Allocate(class'Avarice_OnMessage_Signal'));
        serviceSignalMap.SetItem(service, result);
        _.memory.Free(result);
    }
    else {
        service.FreeSelf();
    }
    return result;
}

/**
 *  Starts caller `AvariceLink`, making it attempt to connect to the Avarice
 *  with parameters that should be first specified by the `Initialize()` call.
 *
 *  Does nothing if the caller `AvariceLink` is either not initialized or
 *  is already active (`IsActive() == true`).
 */
public final function StartUp()
{
    local AvariceTcpStream newStream;
    if (tcpStream == none)          return;
    if (tcpStream.Get() != none)    return;

    newStream = AvariceTcpStream(_.memory.Allocate(class'AvariceTcpStream'));
    if (newStream == none)
    {
        //  `linkName` has to be defined if `tcpStream` is defined
        _.logger.Auto(fatalCannotSpawn).Arg(linkName.Copy());
        return;
    }
    tcpStream.Set(newStream);
    newStream.StartUp(self, class'Avarice_Feature'.static.GetReconnectTime());
}

/**
 *  Shuts down any connections related to the caller `AvariceLink`.
 *
 *  Does nothing if the caller `AvariceLink` is either not initialized or
 *  is already inactive (`IsActive() == false`).
 */
public final function ShutDown()
{
    local Actor storedStream;
    if (tcpStream == none)      return;
    storedStream = tcpStream.Get();
    if (storedStream == none)   return;

    storedStream.Destroy();
    tcpStream.Set(none);
}

/**
 *  Checks whether caller `AvariceLink` is currently active: either connected or
 *  currently attempts to connect to Avarice.
 *
 *  See also `IsConnected()`.
 *
 *  @return `true` if caller `AvariceLink` is either connected or currently
 *      attempting to connect to Avarice. `false` otherwise.
 */
public final function bool IsActive()
{
    if (tcpStream == none) {
        return false;
    }
    return tcpStream.Get() != none;
}

/**
 *  Checks whether caller `AvariceLink` is currently connected or to Avarice.
 *
 *  See also `IsActive()`.
 *
 *  @return `true` iff caller `AvariceLink` is currently connected to Avarice.
 */
public final function bool IsConnected()
{
    local AvariceTcpStream storedStream;
    if (tcpStream == none) {
        return false;
    }
    storedStream = AvariceTcpStream(tcpStream.Get());
    return storedStream.linkState == STATE_Connected;
}

/**
 *  Returns name caller `AvariceLink` was initialized with.
 *  Defined through the config files.
 *
 *  @return Name of the caller `AvariceLink`.
 *      `none` iff caller link was not yet initialized.
 */
public final function Text GetName()
{
    if (linkName != none) {
        return linkName.Copy();
    }
    //  `linkName` cannot be `none` after `Initialize()` call
    return none;
}

/**
 *  Returns host name (without port number) caller `AvariceLink` was
 *  initialized with. Defined through the config files.
 *
 *  See `GetPort()` method for port number.
 *
 *  @return Host name of the caller `AvariceLink`.
 *      `none` iff caller link was not yet initialized.
 */
public final function Text GetHost()
{
    if (linkHost != none) {
        return linkHost.Copy();
    }
    //  `linkName` cannot be `none` after `Initialize()` call
    return none;
}

/**
 *  Returns port number caller `AvariceLink` was initialized with.
 *  Defined through the config files.
 *
 *  @return Host name of the caller `AvariceLink`.
 *      If caller link was not yet initialized, method makes no guarantees
 *      about returned number.
 */
public final function int GetPort()
{
    return linkPort;
}

/**
 *  Send a message to the Avarice that caller `AvariceLink` is connected to.
 *
 *  Message can only be set if caller `AvariceLink` was initialized and is
 *  currently connected (see `IsConnected()`) to Avarice.
 *
 *  @param  service     Name of the service this message is addressed.
 *      As an example, to address a database one would specify its name,
 *      like "db". Cannot be `none`.
 *  @param  type        Name of this message. As an example, to address
 *      a database, one would specify here WHAT that database must do,
 *      like "get" to fetch some data. Cannot be `none`.
 *  @param  parameters  Parameters of the command. Can be any value that is
 *      JSON-compatible (see `JSONAPI.IsCompatible()` for details).
 *  @return `true` if message was successfully sent and `false` otherwise.
 *      Note that this method returning `true` does not necessarily mean that
 *      message has arrived (which is impossible to know at this moment),
 *      instead simply saying that network call to send data was successful.
 *      Avarice does not provide any mechanism to verify message arrival, so if
 *      you need that confirmation - it is necessary that service you are
 *      addressing make a reply.
 */
public final function bool SendMessage(
    BaseText        service,
    BaseText        type,
    AcediaObject    parameters)
{
    local Mutabletext       parametesAsJSON;
    local MutableText       message;
    local AvariceTcpStream  storedStream;
    if (tcpStream == none)                          return false;
    if (service == none)                            return false;
    if (type == none)                               return false;
    storedStream = AvariceTcpStream(tcpStream.Get());
    if (storedStream == none)                       return false;
    if (storedStream.linkState != STATE_Connected)  return false;
    parametesAsJSON = _.json.Print(parameters);
    if (parametesAsJSON == none)                    return false;

    message = _.text.Empty();
    message.Append(T(TSERVICE_PREFIX))
        .Append(_.json.Print(service))
        .Append(T(TTYPE_PREFIX))
        .Append(_.json.Print(type))
        .Append(T(TPARAMS_PREFIX))
        .Append(parametesAsJSON)
        .Append(T(TMESSAGE_SUFFIX));
    storedStream.SendMessage(message);
    message.FreeSelf();
    parametesAsJSON.FreeSelf();
    return true;
}

//      This is a public method, but it is not a part of
//  `AvariceLink` interface.
//      It is used as a communication channel with `AvariceTcpStream` and
//  should not be called outside of that class.
public final function ReceiveNetworkMessage(
    AvariceNetworkMessage   message,
    optional AvariceMessage avariceMessage)
{
    if (message == ANM_Connected) {
        onConnectedSignal.Emit();
    }
    else if (message == ANM_Disconnected) {
        onDisconnectedSignal.Emit();
    }
    else if (message == ANM_Message && avariceMessage != none) {
        GetServiceSignal(avariceMessage.service).Emit(self, avariceMessage);
    }
    else if (message == ANM_Death) {
        onDeathSignal.Emit();
        tcpStream.Set(none);
    }
}

defaultproperties
{
    TSERVICE_PREFIX = 0
    stringConstants(0) = "&{\"s\":"
    TTYPE_PREFIX    = 1
    stringConstants(1) = ",\"t\":"
    TPARAMS_PREFIX  = 2
    stringConstants(2) = ",\"p\":"
    TMESSAGE_SUFFIX = 3
    stringConstants(3) = "&}"
    fatalCannotSpawn = (l=LOG_Error,m="Cannot spawn new actor of class `AvariceTcpStream`, avarice link \"%1\" will not be created")
}