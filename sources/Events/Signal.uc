/**
 *      One of the two classes that make up a core of event system in Acedia.
 *      `Signal`s, along with `Slot`s, are used for communication between
 *  objects. Signals can be connected to slots of appropriate class and emitted.
 *  When a signal is emitted, all connected slots are notified and their handler
 *  is called.
 *      This `Signal`-`Slot` system is essentially a wrapper for delegates
 *  (`Slot` wraps over a single delegate, allowing us to store them in array),
 *  but, unlike them, makes it possible to add several handlers for any event in
 *  a convenient to use way, e.g..:
 *  `_.unreal.OnTick(self).connect = myTickHandler`
 *      To create your own `Signal` you need to:
 *      1. Make a non-abstract child class of `Signal`;
 *      2. Use one of the templates presented in this file below;
 *      3. Create a paired `Slot` class and set it's class to `relatedSlotClass`
 *          in `defaultproperties`.
 *      4. (Recommended) Provide a standard interface by defining an event
 *          method (similar to `_.unreal.OnTick()`) in an object that will own
 *          this signal, example of definition is also listed below.
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
class Signal extends AcediaObject
    abstract;

//  Class of the slot that can catch your `Signal` class
var public const class<Slot> relatedSlotClass;

//      We want to always return a non-`none` slot to avoid "Access 'none'"
//  errors.
//      So if provided signal receiver is invalid - we still create a `Slot`
//  for it, but remember it in this array of slots we aren't going to use
//  in order to dispose of them later.
var private array<Slot> failedSlots;

//      Set to `true` when we are in the process of deleting our `Slot`s.
//      Once `Slot` is deallocated, it notifies it's `Signal` (us) that it
//  should be removed.
//      But if it's deallocated because we are removing it we want to ignore
//  their notification and this flag helps us do that.
var private bool    doingSelfCleaning;
//  Used to provide iterating interface (`StartIterating()` / `GetNextSlot()`).
//  Points at the next slot to return.
var private int     nextSlotIndex;

//      These arrays could be defined as one array of `struct`s with four
//  elements.
//      We use four different arrays instead for performance reasons.
//      They must have the same length at all times and elements with the
//  same index correspond to the same "record".

//  Reference to registered `Slot`
var private array<Slot>         registeredSlots;
//  Life version of the registered `Slot`, to track unexpected deallocations
var private array<int>          slotLifeVersions;
//  Receiver, associated with the `Slot`: when it's deallocated,
//  corresponding `Slot` should be removed
var private array<AcediaObject> slotReceivers;
//  Life version of the registered receiver, to track it's deallocation
var private array<int>          slotReceiversLifeVersions;

/*  TEMPLATE for handlers without returned values:

public final function Emit(<PARAMETERS>)
{
    local Slot nextSlot;
    StartIterating();
    nextSlot = GetNextSlot();
    while (nextSlot != none)
    {
        <SLOT_CLASS>(nextSlot).connect(<PARAMETERS>);
        nextSlot = GetNextSlot();
    }
    CleanEmptySlots();
}
*/

/*  TEMPLATE for handlers with returned values:

public final function int Emit(<PARAMETERS>)
{
    local <RETURN_TYPE> newValue;
    local Slot          nextSlot;
    StartIterating();
    nextSlot = GetNextSlot();
    while (nextSlot != none)
    {
        newValue = <SLOT_CLASS>(nextSlot).connect(<PARAMETERS>);
        //  This check if necessary before using returned value
        if (!nextSlot.IsEmpty())
        {
            //  Now handle `newValue` however you see fit
        }
        nextSlot = GetNextSlot();
    }
    CleanEmptySlots();
    return value;
}
*/

/*  TEMPLATE for the interface method:

var private <SIGNAL_CLASS> mySignal;
public final function <SLOT_CLASS> OnMyEvent(AcediaObject receiver)
{
    return <SLOT_CLASS>(mySignal.NewSlot(receiver));
}
*/

protected function Finalizer()
{
    doingSelfCleaning = true;
    _.memory.FreeMany(registeredSlots);
    doingSelfCleaning = false;
    registeredSlots.length              = 0;
    slotLifeVersions.length             = 0;
    slotReceivers.length                = 0;
    slotReceiversLifeVersions.length    = 0;
}

/**
 *  Creates a new slot for `receiver` to catch emitted signals.
 *  Supposed to be used inside a special interface method only.
 *
 *  @param  receiver    Receiver to which new `Slot` would be connected.
 *      Method connected to a `Slot` generated by this method must belong to
 *      the `receiver`, otherwise behavior of `Signal`-`Slot` system is
 *      undefined.
 *      Must be a properly allocated `AcediaObject`.
 *  @return New `Slot` object that will be connected to the caller `Signal` if
 *      provided `receiver` is correct. Guaranteed to have class
 *      `relatedSlotClass`.
 */
public final function Slot NewSlot(AcediaObject receiver)
{
    local Slot newSlot;
    newSlot = Slot(_.memory.Allocate(relatedSlotClass));
    newSlot.Initialize(self);
    AddSlot(newSlot, receiver);
    return newSlot;
}

/**
 *  Disconnects all of the `receiver`'s `Slot`s from the caller `Signal`.
 *
 *  @param  receiver    Object to disconnect from the caller `Signal`.
 */
public final function Disconnect(AcediaObject receiver)
{
    local int i;
    doingSelfCleaning = true;
    while (i < slotReceivers.length)
    {
        if (slotReceivers[i] == none || slotReceivers[i] == receiver)
        {
            _.memory.Free(registeredSlots[i]);
            registeredSlots.Remove(i, 1);
            slotLifeVersions.Remove(i, 1);
            slotReceivers.Remove(i, 1);
            slotReceiversLifeVersions.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
    doingSelfCleaning = false;
}

/**
 *  Adds new `Slot` `newSlot` with receiver `receiver` to the caller `Signal`.
 *
 *  Does nothing if `newSlot` is already added to the caller `Signal`.
 *
 *  @param  newSlot     Slot to add. Must be initialize for the caller `Signal`.
 *  @param  receiver    Receiver to which new `Slot` would be connected.
 *      Method connected to a `Slot` generated by this method must belong to
 *      the `receiver`, otherwise behavior of `Signal`-`Slot` system is
 *      undefined.
 *      Must be a properly allocated `AcediaObject`.
 */
protected final function AddSlot(Slot newSlot, AcediaObject receiver)
{
    local int i;
    local int newSlotIndex;
    if (newSlot == none)                    return;
    if (newSlot.class != relatedSlotClass)  return;
    if (!newSlot.IsOwnerSignal(self))       return;
    if (receiver == none || !receiver.IsAllocated())
    {
        failedSlots[failedSlots.length] = newSlot;
        return;
    }
    for (i = 0; i < registeredSlots.length; i += 1)
    {
        if (registeredSlots[i] != newSlot) {
            continue;
        }
        if (slotLifeVersions[i] != newSlot.GetLifeVersion())
        {
            slotLifeVersions[i] = newSlot.GetLifeVersion();
            slotReceivers[i] = receiver;
            if (receiver != none) {
                slotReceiversLifeVersions[i] = receiver.GetLifeVersion();
            }
        }
        return;
    }
    newSlotIndex = registeredSlots.length;
    registeredSlots[newSlotIndex]           = newSlot;
    slotLifeVersions[newSlotIndex]          = newSlot.GetLifeVersion();
    slotReceivers[newSlotIndex]             = receiver;
    slotReceiversLifeVersions[newSlotIndex] = receiver.GetLifeVersion();
}

/**
 *  Removes given `slotToRemove` if it was connected to the caller `Signal`.
 *
 *  Does not deallocate `slotToRemove`.
 *
 *  Cannot fail.
 *
 *  @param  slotToRemove    Slot to be removed.
 */
public final function RemoveSlot(Slot slotToRemove)
{
    local int i;
    if (slotToRemove == none)   return;
    if (doingSelfCleaning)      return;

    for (i = 0; i < registeredSlots.length; i += 1)
    {
        if (registeredSlots[i] == slotToRemove)
        {
            registeredSlots.Remove(i, 1);
            slotLifeVersions.Remove(i, 1);
            slotReceivers.Remove(i, 1);
            slotReceiversLifeVersions.Remove(i, 1);
            return;
        }
    }
}

/**
 *  One of two methods that provide an iterator access to the private array of
 *  `Slot`s and perform all the necessary safety checks.
 *
 *  Must be called before each new iterating cycle.
 *
 *  There cannot be any `Slot` additions or removal during one iteration cycle.
 */
protected final function StartIterating()
{
    nextSlotIndex = 0;
}

/**
 *  One of two methods that provide an iterator access to the private array of
 *  `Slot`s and perform all the necessary safety checks.
 *
 *  `StartIterating()` must be called to initialize iteration cycle, then this
 *  method can be called until it returns `none`.
 *
 *  There cannot be any `Slot` additions or removal during one iteration cycle.
 *
 *  @return Next `Slot` that must receive emitted signal. `none` means that
 *      there are no more `Slot`s to iterate over.
 */
protected final function Slot GetNextSlot()
{
    local bool          isNextSlotValid;
    local int           nextSlotLifeVersion, nextReceiverLifeVersion;
    local Slot          nextSlot;
    local AcediaObject  nextReceiver;
    doingSelfCleaning = true;
    while (nextSlotIndex < registeredSlots.length)
    {
        nextSlot                = registeredSlots[nextSlotIndex];
        nextSlotLifeVersion     = slotLifeVersions[nextSlotIndex];
        nextReceiver            = slotReceivers[nextSlotIndex];
        nextReceiverLifeVersion = slotReceiversLifeVersions[nextSlotIndex];
        isNextSlotValid = (nextSlot.GetLifeVersion() == nextSlotLifeVersion)
            &&  (nextReceiver.GetLifeVersion() ==  nextReceiverLifeVersion);
        if (isNextSlotValid)
        {
            nextSlotIndex += 1;
            return nextSlot;
        }
        else
        {
            registeredSlots.Remove(nextSlotIndex, 1);
            slotLifeVersions.Remove(nextSlotIndex, 1);
            slotReceivers.Remove(nextSlotIndex, 1);
            slotReceiversLifeVersions.Remove(nextSlotIndex, 1);
            _.memory.Free(nextSlot);
        }
    }
    doingSelfCleaning = false;
    return none;
}

/**
 *  In case it's detected that some of the slots do not actually have any
 *  handler setup - this method will clean them up.
 */
protected final function CleanEmptySlots()
{
    local int index;
    _.memory.FreeMany(failedSlots);
    failedSlots.length = 0;
    doingSelfCleaning = true;
    while (index < registeredSlots.length)
    {
        if (registeredSlots[index].IsEmpty())
        {
            registeredSlots[index].FreeSelf(slotLifeVersions[index]);
            _.memory.Free(registeredSlots[index]);
            registeredSlots.Remove(index, 1);
            slotLifeVersions.Remove(index, 1);
            slotReceivers.Remove(index, 1);
            slotReceiversLifeVersions.Remove(index, 1);
        }
        else {
            index += 1;
        }
    }
    doingSelfCleaning = false;
}

defaultproperties
{
    relatedSlotClass = class'Slot'
}