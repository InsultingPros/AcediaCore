# Signals and slots system

Acedia provides its own unique event system that is more powerful than regular
`delegate`s and easier to use than listener-type objects like `GameRules`.
It's best demonstrated with an example from AcediaFixes' feature
that deals with friendly fire-related exploits.
Said feature has to catch and handle `NetDamage()` event from `GameRules` and,
with Acedia's signal/slot system, handler can be added with a single line:

```unrealscript
_.unreal.gameRules.OnNetDamage(self).connect = NetDamageHandler;
```

`OnNetDamage()` here is a *signal function* responsible for adding new handlers
for the `NetDamage` event.
Function `NetDamageHandler` has to have an appropriate signature
(parameters and return value types) for the event and will be called each time
`NetDamage` event occurs.

Unlike raw `delegate`s, that can each only store one function, signal/slot
system allows us to have however many handlers we want:

```unrealscript
//  All of those will be called on `NetDamage` event
_.unreal.gameRules.OnNetDamage(self).connect = NetDamageNext;
_.unreal.gameRules.OnNetDamage(self).connect = NetDamageTry;
_.unreal.gameRules.OnNetDamage(self).connect = NetDamageRevolution;
_.unreal.gameRules.OnNetDamage(self).connect = NetDamageEvolutionR;
```

`self` parameter defines a *receiver object* for each handler.
Receiver is responsible for the added handler and helps Acedia to cleanup unused
ones - if receiver gets deallocated, then all of the associated handlers will be
automatically removed:

```unrealscript
//  This assumes that `someObj` is a child class of `AcediaObject`
_.unreal.gameRules.OnNetDamage(someObj).connect = NetDamageHandler;
_.memory.Free(someObj); // After this line `NetDamageHandler()` won't be called.
```

Most of the time receiver is going to be `self`, since normally each
object adds its own functions as event handlers.
Passing `none` for a receiver will make Acedia do a bunch of additional work,
while not actually connecting your handler, so avoid doing that.

Once you no longer need to handle an event, you can *disconnect* from it:

```unrealscript
_.unreal.gameRules.OnNetDamage(self).Disconnect();
//  To disconnect some object `someObj`:
_.unreal.gameRules.OnNetDamage(someObj).Disconnect();
```

This will remove all handlers associated with the object passed as
an argument.

> **NOTE:**
> Even though handlers associated with deallocated object will be automatically
> removed, it is still good practice to manually remove all handlers associated
> with it inside a finalizer, since otherwise "dead" handlers will be stored
> until related event is triggered.

Removing individual handlers is also possible, but can be a bit cumbersome and
is not recommended.

> **NOTE:**
> Our signals and slots take this moniker after [Qt](https://doc.qt.io)'s
> events system;
> however, what they are and how they work is different and shouldn't
> be mixed up.

## Are handlers guaranteed to be called?

As a rule of thumb, all handlers, connected to a signal, are expected to
be called when that `signal` is emitted.
Exceptions are frowned upon and mostly exist for wrappers for existing
UnrealScript's event (for mutators, game rules, etc.) to provide the same
kind of interface.
If `signal` allows handlers to prevent its propagation to other handlers, then
this must be specified in documentation for event's `signal` function.

However note that `signal` only calls handlers that were added before its
emission began.
For example, if you add a new handler for `OnTick()` while handling that event,
the new one will only be called on the next tick.
However, removing existing handlers will prevent them from being called even if
they were connected to a `signal` when emission has already began.

## [Advanced] How signals and slots work

### Delegates overview

This system was created because of limitations of `delegate`s in UnrealEngine 2.
One can declare `delegate` inside any class:

```unrealscript
class MyClass extends Object;

delegate MyDelegate()
{
    //  This code will be executed if no function is assigned to the delegate.
    Log("Empty message");
}
```

then assign a function to them and any time a delegate is called an assigned
function will be called instead:

```unrealscript
function handler()
{
    Log("Handler is called!");
}

local MyClass obj;
obj = new class'MyClass';
obj.MyDelegate();       // "Empty message" is logged
obj.MyDelegate = handler;
obj.MyDelegate();       // "Handler is called!" is logged
obj.MyDelegate = none;  // Reset delegate to its default state
obj.MyDelegate();       // "Empty message" is logged
```

However they have their limitations, main one being that out of the box they
do not support multiple event handlers: you can neither assign several functions
to a `delegate` nor can you create an array of `delegate`s.

### `slot`s are boxed `delegate`s, `Signal`s are arrays of `slot`s

Acedia bypasses this limitation by essentially boxing `delegate`s.
If you are unfamiliar with the concept of boxing, it is somewhat discussed
[here](./objects.md).
`slot` is just an object that contains a single `delegate`
(convention is to call it `connect()`) with some extra code to support
cleanup of no longer needed `slot`s.
Wrapping `delegate`s into `slot`s allows us to store them in arrays represented
by `Signal`s: each `Signal` is usually associated with some sort of an event and
can refer (be connected to) several `slot`s, therefore supporting several
different event handlers.

`Signal`s are usually declared as internal variables and are distinct entities
from *signal function* like `_.unreal.gameRules.OnNetDamage()`.
Connecting a handler to an event with line like
`OnNetDamage(self).connect = NetDamage`
actually means performing following steps:

1. Found / access appropriate `Signal` object;
2. Created and return new `slot` object for that `Singal`;
3. Assign `connect` delegate for returned `slot` to a handler function
    (`NetDamage` in above example).

```unrealscript
//  [GameRulesAPI.uc]
public final function GameRules_OnNetDamage_Slot OnNetDamage(
    AcediaObject receiver)
{
    local signal        signal;
    local UnrealService service;
    //  These two lines are implementation detail for `OnNetDamage()`,
    //  you can store your `signal` object wherever you need.
    service = UnrealService(class'UnrealService'.static.Require());
    signal = service.GetSignal(class'GameRules_OnNetDamage_Signal');
    //  This corresponds to the second step of creating new slot
    return GameRules_OnNetDamage_Slot(signal.NewSlot(receiver));
}

//  [FixFFHack.uc]
//  `connect` is simply a delegate variable defined inside
//  object of class `GameRules_OnNetDamage_Slot`
_.unreal.gameRules.OnNetDamage(self).connect = NetDamage;

```

If returned `slot` is not assigned to any function, then it will be
automatically cleaned up at some later point.
We cannot directly check whether a `delegate` was assigned some value, but
`connect`'s default implementation calls special protected method `DummyCall()`
that marks caller `slot` as empty.

### Disconnecting

So how does `_.unreal.gameRules.OnNetDamage(someObj).Disconnect()` work?
Same as above, `_.unreal.gameRules.OnNetDamage(someObj)` creates a new empty
`slot`, associated with `someObj`.
This `slot` has references to both `signal` its connected to and `someObj`.
`Disconnect()` method makes our `slot` inform its `signal` that all `slot`s
related to `someObj` (including itself) must be disconnected and deallocated.

This means that disconnecting object's `slot`s from the `signal` with
`Disconnect()`always involves creation of the new `slot` that will never be
connected to any handler method.
It is a roundabout way of doing things, but it provides a simple interface for
the task that shouldn't be performed often enough to affect performance.

## [Advanced] How to make your own `signal`s and `slot`s

Providing support for your own signals and slots actually takes quite a bit more
work that using them.
It is definitely more work than with listener-type objects.
Here we will consider main use cases.

### Simple notification events

If you need to add an event with handlers that don't take any parameters and
don't return anything, then easiest way it to use `SimpleSignal` / `SingleSlot`
classes:

```unrealscript
class MyEventClass extends AcediaObject;

var private SimpleSignal onMyEventSignal;

protected function Constructor()
{
    onMyEventSignal = SimpleSignal(_.memory.Allocate(class'SimpleSignal'));
}

protected function Finalizer()
{
    _.memory.Free(onMyEventSignal);
    onMyEventSignal = none;
}

public function SimpleSlot OnMyEvent(AcediaObject receiver)
{
    return SimpleSlot(onMyEventSignal.NewSlot(receiver));
}

//  Suppose you want to emit the `signal` when this function is called...
public function SimpleSlot FireOffMyEvent(AcediaObject receiver)
{
    //  ...simply call this and all the slots will have their handlers called
    onMyEventSignal.Emit();
}
```

Then you can use `OnMyEvent()` as a *signal function*:

```unrealscript
//  To add handlers
myEventClassInstance.OnMyEvent(self).connect = handler;
//  To remove handlers
myEventClassInstance.OnMyEvent(self).Disconnect();
```

### Events with parameters

Some of the events, like `OnNetDamage()` in our first examples, can take
parameters.
We cannot use `SimpleSignal` or `SimpleSlot` for them and have to define new
classes that will wrap around `delegate` with an appropriate signature.

You simply need to follow the template and define new classes like this:

```unrealscript
class MySignal extends Signal;

public final function Emit(<PARAMETERS>)
{
    local Slot nextSlot;
    StartIterating();
    nextSlot = GetNextSlot();
    while (nextSlot != none)
    {
        MySlot(nextSlot).connect(<PARAMETERS>);
        nextSlot = GetNextSlot();
    }
    CleanEmptySlots();
}

defaultproperties
{
    relatedSlotClass = class'MySlot'
}
```

```unrealscript
class MySlot extends Slot;

delegate connect(<PARAMETERS>)
{
    DummyCall(); // This allows Acedia to cleanup slots without set handlers
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

defaultproperties
{
}
```

where you can use any set of parameters instead of `<PARAMETERS>`.
You can check out `Unreal_OnTick_Signal` and `Unreal_OnTick_Slot` for
an example.

### Events with return values

Sometimes you want your handlers to respond in some way to the event.
You can either allow them to modify input parameters (e.g. by declaring them as
`out`) or allow them to have return value.
`OnNetDamage()`, for example, is allowed to modify incoming damage by returning
a new value.

To add `signal`s / `slot`s that handle return value use following templates:

```unrealscript
class MySignal extends Signal;

public final function <RETURN_TYPE> Emit(<PARAMETERS>)
{
    local <RETURN_TYPE> newValue;
    local Slot          nextSlot;
    StartIterating();
    nextSlot = GetNextSlot();
    while (nextSlot != none)
    {
        newValue = <SLOT_CLASS>(nextSlot).connect(<PARAMETERS>);
        //  This check is necessary before using returned value
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

defaultproperties
{
    relatedSlotClass = class'MySlot'
}
```

```unrealscript
class MySlot extends Slot;

delegate <RETURN_TYPE> connect(<PARAMETERS>)
{
    DummyCall();
    //  Return anything you want:
    //  this value will be filtered inside corresponding `Signal`
    //  if no handler is set to the associated slot
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
```

For working example you can check out `GameRules_OnNetDamage_Signal` and
`GameRules_OnNetDamage_Slot` classes.

## [Advanced] How to remove particular `slot`

In our very first example we've seen that we can remove all `slot`s for
`OnNetDamage()`, associated with `someObj`, by calling
`_.unreal.gameRules.OnNetDamage(someObj).Disconnect()`.
But sometimes it might be necessary to remove only one slot.
In that case you'll have to store that slot in a separate variable:

```unrealscript
//  Each `signal` can have its own `slot` type
var GameRules_OnNetDamage_Slot trackedSlot;
var int trackedSlotLifeVersion;
// ...
// Record new `slot` in a variable, then set `connect` delegate
trackedSlot = _.unreal.gameRules.OnNetDamage(self);
trackedSlot.connect = handler;
trackedSlotLifeVersion = trackedSlot.GetLifeVersion();
// ...
// 1. You can then change `slot`'s handler
if (trackedSlotLifeVersion == trackedSlot.GetLifeVersion()) {
    trackedSlot.connect = handler2;
}
// ...
// 2. Or deallocate `slot` once it's no longer needed -
// its handler won't be called again
trackedSlot.FreeSelf(trackedSlotLifeVersion);
trackedSlot = none;
```

Here we record *life version* because it is `signal`, and not us, that is
responsible for the deallocation of `slot`s.
If we don't check life versions, we might use `slot` reallocated for a different
purpose.
This shouldn't happen unless you deallocate `trackedSlot` in some other way
(e.g. with `_.unreal.gameRules.OnNetDamage(self).Disconnect()`), but its safer
to do this check.
Not accessing separate `slot`s is even safer.

> **NOTE:**
> `singal`s themselves also track `slot`'s life versions and will be able to
> tell if you've deallocated them on your own.
