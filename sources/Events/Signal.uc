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
 *      To create your own `Signal` you need to:
 *      1. Make a non-abstract child class of `Signal`;
 *      2. Use one of the templates presented in this file below;
 *      3. Create a paired `Slot` class and set it's class to `relatedSlotClass`
 *          in `defaultproperties`.
 *      4. (Recommended) Provide a standard interface by defining an event
 *          method (similar to `_server.unreal.OnTick()`) in an object that will
 *          own this signal, example of definition is also listed below.
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

/**
 *      `Signal` essentially has to provide functionality for
 *  connecting/disconnecting slots and iterating through them. The main
 *  challenge is that slots can also be connected / disconnected during
 *  the signal emission. And in such cases we want:
 *      1. To not propagate a signal to `Slot`s that were added during
 *          it's emission;
 *      2. To not propagate a signal to any removed `Slot`, even if it was
 *          connected to the `Signal` in question when signal started emitting.
 *
 *      We store connected `Slot`s in array, so to iterate we will simply use
 *  internal index variable `nextSlotIndex`. To account for removal of `Slot`s
 *  we will simply have to appropriately correct `nextSlotIndex` variable.
 *  To account for adding `Slot`s during signal emission we will first add them
 *  to a temporary queue `slotQueueToAdd` and only dump slots stored there
 *  into actual connected `Slot`s array before next iteration starts.
 */

//  Class of the slot that can catch your `Signal` class
var public const class<Slot> relatedSlotClass;

//      Set to `true` when we are in the process of removing connected `Slot`s.
//      Once `Slot` is deallocated, it notifies it's `Signal` (us) that it
//  should be removed.
//      But if it's deallocated because we are removing it, then we want to
//  ignore that notification and this flag helps us do that.
var private bool    doingSelfCleaning;
//  Used to provide iterating interface (`StartIterating()` / `GetNextSlot()`).
//  Points at the next slot to return.
var private int     nextSlotIndex;

//  This record describes slot-receiver pair to be added, along with it's
//  life versions at the moment of adding a slot. Life versions help us verify
//  that slot/receiver were not re-allocated at some point
//  (thus becoming different objects).
struct SlotRecord
{
    var Slot            slotInstance;
    var int             slotLifeVersion;
    var AcediaObject    receiver;
    var int             receiverLifeVersion;
};
//  Slots to be added before the next iteration (signal emission).
//  We ensure that any added record has `slotInstance != none`.
var array<SlotRecord> slotQueueToAdd;

//      These arrays could be defined as one array of `SlotRecord` structs.
//      We use four different arrays instead for performance reasons.
//  (Acedia is expected to make extensive use of `Signal`s and `Slot`s, so it's
//  reasonable to consider even small optimization in this case).
//      They must have the same length at all times and elements with the
//  same index correspond to the same "record".

//  References to registered `Slot`s
var private array<Slot>         registeredSlots;
//  Life versions of the registered `Slot`s, to track unexpected deallocations
var private array<int>          slotLifeVersions;
//  Receivers, associated with the `Slot`s: when they're deallocated,
//  corresponding `Slot`s should be removed
var private array<AcediaObject> slotReceivers;
//  Life versions of the registered receivers, to track their deallocation
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

public final function <RETURN_TYPE> Emit(<PARAMETERS>)
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
    //  Return whatever you see fit after handling all the slots
    return <END_RETURN_VALUE>;
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
    local int i;
    doingSelfCleaning = true;
    //  Free queue for slot addition
    for (i = 0; i < slotQueueToAdd.length; i += 1)
    {
        slotQueueToAdd[i].slotInstance
            .FreeSelf(slotQueueToAdd[i].slotLifeVersion);
    }
    slotQueueToAdd.length = 0;
    //  Free actually connected slots
    for (i = 0; i < registeredSlots.length; i += 1) {
        registeredSlots[i].FreeSelf(slotLifeVersions[i]);
    }
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
 *  @param  receiver    Receiver to which new `Slot` would be connected to.
 *      Method connected to a `Slot` generated by this method must belong to
 *      the `receiver`, otherwise behavior of `Signal`-`Slot` system is
 *      undefined.
 *      Must be a properly allocated `AcediaObject`.
 *  @return New `Slot` object that will be connected to the caller `Signal` if
 *      provided `receiver` is correct. Guaranteed to have class
 *      `relatedSlotClass`. Guaranteed to not be `none` if allocated `receiver`
 *      is provided.
 */
public final function Slot NewSlot(AcediaObject receiver)
{
    local Slot newSlot;
    if (receiver == none) {
        return none;
    }
    newSlot = Slot(_.memory.Allocate(relatedSlotClass));
    if (newSlot.Initialize(self, receiver))
    {
        AddSlot(newSlot, receiver);
        return newSlot;
    }
    newSlot.FreeSelf();
    if (!receiver.IsAllocated()) {
        Disconnect(receiver);
    }
    return none;
}

/**
 *  Disconnects all of the `receiver`'s `Slot`s from the caller `Signal`.
 *
 *  Meant to only be used by the `Slot`s `Disconnect()` method.
 *
 *  @param  receiver    Object to disconnect from the caller `Signal`.
 *      If `none` is passed, does nothing.
 */
public final function Disconnect(AcediaObject receiver)
{
    local int i;
    if (receiver == none) {
        return;
    }
    doingSelfCleaning = true;
    //  Clean from the queue for addition
    i = 0;
    while (i < slotQueueToAdd.length)
    {
        if (slotQueueToAdd[i].receiver == receiver)
        {
            slotQueueToAdd[i].slotInstance
                .FreeSelf(slotQueueToAdd[i].slotLifeVersion);
            slotQueueToAdd.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
    //  Clean from the active slots
    i = 0;
    while (i < slotReceivers.length)
    {
        if (slotReceivers[i] == receiver) {
            RemoveSlotAtIndex(i);
        }
        else {
            i += 1;
        }
    }
    doingSelfCleaning = false;
}

/**
 *  Adds new `Slot` (`newSlot`) with receiver `receiver` to the caller `Signal`.
 *
 *  Won't affect caller `Signal` if `newSlot` is already added to it
 *  (even if it's added with a different receiver).
 *
 *  @param  newSlot     Slot to add. Must be initialize for the caller `Signal`.
 *  @param  receiver    Receiver to which new `Slot` would be connected.
 *      Method connected to a `Slot` generated by this method must belong to
 *      the `receiver`, otherwise behavior of `Signal`-`Slot` system is
 *      undefined. Must be a properly allocated `AcediaObject`.
 */
protected final function AddSlot(Slot newSlot, AcediaObject receiver)
{
    local SlotRecord newRecord;
    //      Do not check whether `receiver` is `none`, this requires handling
    //  `newSlot`'s deallocation and it will be dealt with at the moment of
    //  adding new slots from `slotQueueToAdd` queue to the caller `Signal`.
    //      This situation should not normally occur in the first place, so
    //  it does not matter if the `slotQueueToAdd` grows larger than needed when
    //  this does happen.
    if (newSlot == none) {
        return;
    }
    newRecord.slotInstance = newSlot;
    newRecord.slotLifeVersion = newSlot.GetLifeVersion();
    newRecord.receiver = receiver;
    if (receiver != none) {
        newRecord.receiverLifeVersion = receiver.GetLifeVersion();
    }
    slotQueueToAdd[slotQueueToAdd.length] = newRecord;
}

//      Attempts to add a `Slot` from a `SlotRecord` into array of currently
//  connected `Slot`s.
//      IMPORTANT: Must only be called right before a new iteration
//  (signal emission) through the `Slot`s. Otherwise `Signal`'s behavior
//  should be considered undefined.
private final function AddSlotRecord(SlotRecord record)
{
    local int           i;
    local int           newSlotIndex;
    local Slot          newSlot;
    local AcediaObject  receiver;
    newSlot = record.slotInstance;
    receiver = record.receiver;
    if (newSlot.class != relatedSlotClass)                  return;
    if (!newSlot.IsOwnerSignal(self))                       return;
    //  Slot got deallocated while waiting in queue
    if (newSlot.GetLifeVersion() != record.slotLifeVersion) return;

    //  Receiver is outright invalid or got deallocated
    if (    receiver == none
        ||  !receiver.IsAllocated()
        ||  receiver.GetLifeVersion() != record.receiverLifeVersion)
    {
        doingSelfCleaning = true;
        newSlot.FreeSelf();
        doingSelfCleaning = false;
        return;
    }
    //  Check if that slot is already added
    for (i = 0; i < registeredSlots.length; i += 1)
    {
        if (registeredSlots[i] != newSlot) {
            continue;
        }
        //  If we have the same instance recorded, but...
        //      1. it was reallocated: update it's records;
        //      2. it was not reallocated: leave the records intact.
        //  Neither case would cause issues with iterating along `Slot`s if this
        //  method is only called right before new iteration through `Slot`s.
        if (slotLifeVersions[i] != record.slotLifeVersion)
        {
            slotLifeVersions[i] = record.slotLifeVersion;
            slotReceivers[i] = receiver;
            if (receiver != none) {
                slotReceiversLifeVersions[i] = record.receiverLifeVersion;
            }
        }
        return;
    }
    newSlotIndex = registeredSlots.length;
    registeredSlots[newSlotIndex]           = newSlot;
    slotLifeVersions[newSlotIndex]          = record.slotLifeVersion;
    slotReceivers[newSlotIndex]             = receiver;
    slotReceiversLifeVersions[newSlotIndex] = record.receiverLifeVersion;
}

/**
 *  Removes given `slotToRemove` if it was connected to the caller `Signal`.
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

    //  Remove from queue for addition
    while (i < slotQueueToAdd.length)
    {
        if (slotQueueToAdd[i].slotInstance == slotToRemove)
        {
            slotToRemove.FreeSelf(slotQueueToAdd[i].slotLifeVersion);
            slotQueueToAdd.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
    //  Remove from active slots
    for (i = 0; i < registeredSlots.length; i += 1)
    {
        if (registeredSlots[i] == slotToRemove)
        {
            RemoveSlotAtIndex(i);
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
    local int i;
    for (i = 0; i < slotQueueToAdd.length; i += 1) {
        AddSlotRecord(slotQueueToAdd[i]);
    }
    slotQueueToAdd.length = 0;
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
            doingSelfCleaning = false;
            return nextSlot;
        }
        else {
            RemoveSlotAtIndex(nextSlotIndex);
        }
    }
    doingSelfCleaning = false;
    return none;
}

/**
 *  In case it's detected that some of the slots do not actually have any
 *  delegate set - this method will clean them up.
 */
protected final function CleanEmptySlots()
{
    local int index;
    doingSelfCleaning = true;
    while (index < registeredSlots.length)
    {
        if (registeredSlots[index].IsEmpty()) {
            RemoveSlotAtIndex(index);
        }
        else {
            index += 1;
        }
    }
    doingSelfCleaning = false;
}

//  Removes `Slot` at a given `index`.
//  Assumes that passed index is within boundaries.
private final function RemoveSlotAtIndex(int index)
{
    registeredSlots[index].FreeSelf(slotLifeVersions[index]);
    registeredSlots.Remove(index, 1);
    slotLifeVersions.Remove(index, 1);
    slotReceivers.Remove(index, 1);
    slotReceiversLifeVersions.Remove(index, 1);
    //  Alter iteration index `nextSlotIndex` to account for this `Slot` removal
    if (nextSlotIndex > index) {
        nextSlotIndex -= 1;
    }
}

defaultproperties
{
    relatedSlotClass = class'Slot'
}