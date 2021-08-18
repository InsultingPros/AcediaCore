# Acedia's safety rules

To work with Acedia it is necessary to understand its object management:
what it is and why it exists.
Our aim here is to provide a brief introduction using `Text` as an example.

When working with UnrealScript one can distinguish between following types
of variables:

1. Value types: `bool`, `byte`, `int`, `float`, `string` and any `struct`s;
2. Actors: objects that have `Actor` as their parent;
3. Non-actor objects: object of any class not derived derived from the `Actor`.

Most of the mods mainly use first and second type, but Acedia makes heavy use of
the third one.
This allows Acedia to provide convenient interfaces for its functionality and
simplify implementation of its features.
However it also creates several new problems, normally not encountered by
other mods.
Here we will introduce and briefly explain several rules that should be followed
to properly use Acedia.

## Do not store references to actors in non-actor objects

Storing actors in non-actor objects is a bad idea and can lead to
game/server crashes.
If you are interested in the explanation of why, you can read discussion
[here](https://wiki.beyondunreal.com/Legacy:Creating_Actors_And_Objects).

This isn't really a problem in most mutators, since they store references
to actors (`KFMonster`, `KFPlayerController`, ...)
inside other actors (`Mutator`, `GameType`, ...);
however, in Acedia almost everything is a non-actor object, which can cause
a lot of trouble, since even a simple check like `myActor != none`
can lead to a crash.

Acedia's goal is to provide you with enough wrapper API, so that you don't have
to reference actors directly.
We are a long way away from that goal, so for whenever these API are not enough,
Acedia provides a way to work with actors safely
(see [Actor references with `NativeActorRef`](./objects.md)).

## Take care to explicitly free unneeded objects

We'll illustrate this point with `Text` - Acedia's own type that is used as
a replacement for `string`. Consider following simple code:

```unrealscript
function MyFunction()
{
    local string message;
    message = "My log message";
    Log(message);
}
```

For Acedia's `Text` an equivalent code would be:

```unrealscript
function MyFunction()
{
    local Text message;
    message = _.text.FromString("My log message");
    _.logger.Info(message); //  Just Acedia's logging, kind of like `Log()`
}
```

There is an additional action of calling `FromString()` to create
a new `Text` object, but otherwise logic is the same.
But there's one crucial difference: unlike `string` value,
`Text` is an object that will continue to exists in memory even after we exit
`MyFunction()`'s body: every single call to `MyFunction()` will keep creating
new objects that won't ever be used anywhere else.

Supposed way to deal with this is *garbage collection*, but it is a very
expensive operation in Unreal Engines before their 3rd version.
For example, the lag at the start of each wave in Killing Floor is caused by
a garbage collection call.
Many players hate it and several mods were made to disable it,
since there is usually not much to actually clean up.

This means that Acedia needed to find another way of dealing with issue of
creating useless objects. That solution is *deallocating objects*:

```unrealscript
function MyFunction()
{
    local Text message;
    message = _.text.FromString("My log message");
    _.logger.Info(message);
    message.FreeSelf(); //  `_.memory.Free(message)` would also work
}
```

Here `FreeSelf()` call marks `message` as an unneeded object, making it
available to be reused.
In fact, if you call new `MyFunction()` several times in a row:

```unrealscript
MyFunction()
MyFunction()
//  Paste a couple thousand more calls here
MyFunction()
```

all of the calls will use only one `Text` object - the exactly same as the one
first call has created.

This concerns not only `Text`, but almost every single Acedia's object.
To efficiently use Acedia, you must learn to deallocate objects that are
not going to be used anymore.

## You should *never ever* use anything you've deallocated

If `Text` variable from above wasn't local, but global variable, then we'd have
to add one more instruction `message = none`:

```unrealscript
var Text message;

function MyFunction()
{
    message = _.text.FromString("My log message");
    _.logger.Info(message);
    message.FreeSelf();
    message = none; // Forget about `message`!
}
```

Deallocating a `message` does not make an actual object go away and,
without setting `message` variable to `none`, you risk continuing to use it;
however, some other piece of code might re-allocate that object
and use it for something completely different.
This means unpredictable and undefined behavior for everybody.
To avoid creating with this problem - everyone must always make sure to
*forget* about objects you've deallocated by setting your references to `none`.

> **NOTE:** This also means that you should not deallocate the same object
> more than once.
