/**
 *      One of the two classes that make up a core of event system in Acedia.
 *      `Signal`s, along with `Slot`s, are used for communication between
 *  objects. Signals can be connected to slots of appropriate class and emitted.
 *  When a signal is emitted, all connected slots are notified and their handler
 *  is called.
 *      This `Signal`-`Slot` system is essentially a wrapper for delegates
 *  (`Slot` wraps over a single delegate, allowing us to store them in array),
 *  but, unlike them, makes it possible to add several handlers for any event in
 *  a convenient to use way, e.g.:
 *  `_server.unreal.OnTick(self).connect = myTickHandler`
 *      To create your own `Slot` you need to:
 *      1. Make a non-abstract child class of `Signal`;
 *      2. Use one of the templates presented in this file below.
 *      More detailed information can be found in documentation.
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
class Slot extends AcediaObject
    abstract;

var private bool            dummyMethodCalled;
var private AcediaObject    myReceiver;
var private int             myReceiverLifeVersion;
var private Signal          mySignal;

/*  TEMPLATE for handlers without returned values:
delegate connect(<PARAMETERS>)
{
    DummyCall();
}

protected function Constructor()
{
    connect = none;
}

protected function Finalizer()
{
    super.Finalizer();
    connect = none;
}
*/

/*  TEMPLATE for handlers with returned values:
delegate <RETURN_TYPE> connect(<PARAMETERS>)
{
    DummyCall();
    //  Return anything you want:
    //  this value will be filtered inside corresponding `Signal`
    return <???>;
}

protected function Constructor()
{
    connect = none;
}

protected function Finalizer()
{
    super.Finalizer();
    connect = none;
}
*/

protected function Finalizer()
{
    dummyMethodCalled = false;
    if (mySignal != none) {
        mySignal.RemoveSlot(self);
    }
    mySignal    = none;
    myReceiver  = none;
}

/**
 *  Calling this method marks caller `Slot` as "empty", i.e. having an empty
 *  delegate. `Slot`s like that are deleted from `Signal`s upon detection.
 *
 *  Must be called inside your `connect()` implementation.
 */
protected final function DummyCall()
{
    dummyMethodCalled = true;
    //  We do not want to call `mySignal.RemoveSlot(self)` here, since
    //  `mySignal` is likely in process of iterating through it's `Slot`s
    //  and removing (or adding) `Slot`s from it can mess up that process.
}

/**
 *  Initialized caller `Slot` to receive signals emitted by `newOwnerSignal`.
 *
 *  Can only be done once for every `Slot`.
 *
 *  @param  newOwnerSignal  `Signal` we want to receive emitted signals from.
 *  @param  receiver        Receiver object that caused creation of this `Slot`.
 *  @return `true` if initialization was successful and `false` otherwise
 *      (if `newOwnerSignal` is invalid or caller `Slot` was
 *      already initialized).
 */
public final function bool Initialize(
    Signal          newOwnerSignal,
    AcediaObject    receiver)
{
    if (mySignal != none) {
        return false;
    }
    if (receiver != none && receiver.IsAllocated())
    {
        myReceiver = receiver;
        myReceiverLifeVersion = receiver.GetLifeVersion();
    }
    if (newOwnerSignal == none || !newOwnerSignal.IsAllocated())
    {
        FreeSelf();
        return false;
    }
    mySignal = newOwnerSignal;
    return true;
}

/**
 *  Checks if caller `Slot` was initialized to receive `testSignal`'s signals.
 *
 *  @param  testSignal  `Signal` to test.
 *  @return `true` if caller `Slot` was initialized to receiver `testSignal`'s
 *      signals and `false` otherwise.
 */
public final function bool IsOwnerSignal(Signal testSignal)
{
    return (mySignal == testSignal);
}

/**
 *  Disconnects all the `Slot`s that belong to receiver of the caller `Slot`
 *  from our owner signal `mySignal`.
 *
 *  Method's name does not reflect what it does well, however this is done
 *  deliberately to provide an overall more intuitive user interface to
 *  signals and slots that allows for receiver to disconnect from `Signal` in
 *  the similar way to how it connects:
 *  `eventSource.OnSomeEvent(self).connect = handler`
 *  `eventSource.OnSomeEvent(self).Disconnect()`
 */
public final function Disconnect()
{
    if (mySignal == none)                                       return;
    if (myReceiver == none)                                     return;
    if (myReceiver.GetLifeVersion() != myReceiverLifeVersion)   return;

    mySignal.Disconnect(myReceiver);
}

/**
 *  Checks if caller `Slot` was detected to be "empty", i.e. having an empty
 *  delegate. `Slot`s like that are deleted from `Signal`s upon detection.
 *
 *  @return `true` if caller `Slot` is empty (and should be removed from the
 *      appropriate `Signal`) and `false` otherwise.
 */
public final function bool IsEmpty()
{
    return dummyMethodCalled;
}

defaultproperties
{
}