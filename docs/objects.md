# `AcediaObject` and `AcediaActor`

Acedia defines its own base classes for both actor and non-actor objects
(`AcediaActor` and `AcediaObject` respectively).
Both of them are better integrated into Acedia's infrastructure than regular
objects and actors.
`AcediaObject` is especially important, since it provides support for
*object deallocation*.
In this document we will go over everything you need to know about
these classes.

## Who is responsible for objects?

If you have read [safety rules](./safety.md) document (and you should have),
then you already know about the importance of deallocation.
But which objects exactly are you supposed to deallocate?
Understanding what objects you are responsible for is one of the most important
concepts to get when working with Acedia.
There are two main guidelines:

* **If function returns an object (as a return value or as an `out` argument) -
    then this object must be deallocated by
    whoever called that function.**
    If you've called `_.text.Empty()`, then you must deallocate
    the `MutableText`object it has returned.
    Conversely, if you are implementing function that returns an object,
    then you must not deallocate it yourself.
    In fact, you are expected to not use that object at all after returning it,
    since you cannot know when it will be deallocated.
* **Functions do not deallocate their arguments.**
    If you pass an object as an argument to a function - you can expect
    that said object won't be deallocated during function's execution.
    When implementing your own function - you should not deallocate
    objects passed as its arguments.

> **NOTE:**
> If you're responsible for Acedia's [collection](./API/collections.md) -
> you are also considered responsible for its items,
> unless explicitly stated otherwise.

However, these guidelines should be treated as *default assumptions* and
not *hard rules*.

### Exceptions

First guideline, for example, can be broken if returned object is supposed to
be shared: `_.players.GetAll()` returns `array<APLayer>` with references to
*player objects* that aren't supposed to ever be deallocated.
Similarly, Acedia's collections operate by different rules:
they might still consider themselves responsible for objects returned with
`GetItem()`.

Second guideline can also be broken by some of the methods for the sake of
convenience.
If you need to turn a `Text` object into a `string`, then you can either do:

```unrealscript
if (textToConvert != none)
{
    result = textToConvert.ToString();
    textToConvert.FreeSelf();
}
```

or simply call `_.text.ToString()` that automatically deallocates its argument:
`result = _.text.ToString(textToConvert)`.

> **NOTE:**
> Any such exceptions are documented (or at least should be), so simply read
> the comment docs in source code for functions you're using.
> If they don't mention anything about how arguments or return values
> should be treated - assume above stated default guidelines.

## `MemoryAPI`

The majority, if not all, of the Acedia's objects you will be using are going to
be created by specialized methods like `_.text.FromString()`,
`_.collections.EmptyDynamicArray()` or `_.time.StartTimer()`
and can be deallocated with `self.FreeSelf()` method.
However, if you want to allocate instances of your own classes,
you'll need the help of `MemoryAPI`'s methods:
`_.memory.Allocate()` and `_.memory.Free()`.

Ultimately, all Acedia's objects and actors must be created with
`_.memory.Allocate()` and destroyed with `_.memory.Free()`.
For example, here is how new `Parser` is created with `_.text.NewParser()`:

```unrealscript
public final function Parser NewParser()
{
    return Parser(_.memory.Allocate(class'Parser'));
}
```

and `self.FreeSelf()` is actually defined in `AcediaObject`
and `AcediaActor` as follows (ignore parts about life versions for now,
they will be explained in sections below):

```unrealscript
public final function FreeSelf(optional int lifeVersion)
{
    if (lifeVersion <= 0 || lifeVersion == GetLifeVersion()) {
        _.memory.Free(self);
    }
}
```

If you create your own classes, derived from either
`AcediaObject` or `AcediaActor`, you must also use these functions to
create and destroy their instances.

`MemoryAPI` contains a few more useful functions:

| Function | Description |
| -------- | ----------- |
| `Allocate(class<Object>, optional bool)` | Creates a new `Object` / `Actor` of a given class. `bool` argument allows to forbid reallocation, forcing creation of a new object.
| `LoadClass(Text)` | Creates a class instance from its `Text` representation. |
| `LoadClassS(string)` | Creates a class instance from its `string` representation. |
| `AllocateByReference(Text, optional bool)` | Same as `Allocate()`, but takes `Text` representation of the class as an argument. |
| `AllocateByReferenceS(string, optional bool)` | Same as `Allocate()`, but takes `string` representation of the class as an argument. |
| `Free(Object)` | Deallocates provided object. Does not produce errors if its argument is `none`. |
| `FreeMany(array<Object>)` | Deallocates every object inside given array. Does not produce errors if some (or all) of them are `none`. |
| `CollectGarbage(optional bool)` | Forces garbage collection. By default also includes all deallocated (but not destroyed) objects and `bool` argument allows to skip collecting them.

> **NOTE:** While `MemoryAPI` can also be used for creating objects that do not
> derive from either `AcediaObject` or `AcediaActor`, there is no point in
> using them over `new` or `Spawn()`:
> Acedia's methods are overall less powerful and will not provide any benefits
> for non-Acedia objects.

## Constructors and finalizers

Both `AcediaObject` and `AcediaActor` support
[constructors](
https://en.wikipedia.org/wiki/Constructor_(object-oriented_programming))
and
[finalizers](https://en.wikipedia.org/wiki/Finalizer).
*Constructor* is a method that's called on object after it's created,
preparing it for use.
*Finalizer* is a method that's called when object is deallocated
(or actor is destroyed) and can be used to clean up any used resources.

> Technically, right now *destructor* might be a better terminology for Acedia's
> finalizers.

A good and simple example is from the `ATradingComponent` that
allocates necessary objects inside its constructor and deallocates them in
its finalizer:

```unrealscript
protected function Constructor()
{
    onStartSignal   = SimpleSignal(_.memory.Allocate(class'SimpleSignal'));
    onEndSignal     = SimpleSignal(_.memory.Allocate(class'SimpleSignal'));
    onTraderSelectSignal = Trading_OnSelect_Signal(
        _.memory.Allocate(class'Trading_OnSelect_Signal'));
}

protected function Finalizer()
{
    _.memory.Free(onStartSignal);
    _.memory.Free(onEndSignal);
    _.memory.Free(onTraderSelectSignal);
    onStartSignal           = none;
    onEndSignal             = none;
    onTraderSelectSignal    = none;
}
```

To use constructors and finalizers in your own classes you simply need to
overload `Constructor()` and `Finalizer()` methods (they are defined in both
`AcediaObject` and `AcediaActor`), just like in the example above.

> Acedia's constructors do not take parameters and because of that some classes
> also define `Initialize()` method that is required to be used right after
> an object was allocated.

## Object equality and object hash

Comparing object variables with `==` operator checks *reference equality*:
whether variables refer to the exact same object.
But sometimes we want to implement *value equality* check - a comparison for
the contents of two objects, e.g. checking that two different `Text`s
store the exact same data.
Acedia provides an alternative way to compare two objects - `IsEqual()` method.
Its default implementation corresponds to that of `==` operator:

```unrealscript
public function bool IsEqual(Object other)
{
    return (self == other);
}
```

But it can be redefined, as long as it obeys following rules:

* `a.IsEqual(a) == true`;
* `a.IsEqual(b)` if and only if `b.IsEqual(a)`;
* `none` is only equal to `none;
* Result of `a.IsEqual(b)` does not change unless one of the objects gets
    deallocated.

Because of the last rule, `IsEqual()` cannot compare two `MutableText`s based on
their contents, since they can change without deallocation
(unlike contents of an immutable `Text`).

Reimplementing `IsEqual()` method also requires you to reimplement how object's
[hash value](https://en.wikipedia.org/wiki/Hash_function) is calculated.
*Hash value* is a an `int` associated with an object.
Several different objects can have the same hash value and equal objects *must*
have the same hash value.

By default, Acedia's objects simply use randomly generated value as their hash,
determined at the moment of their creation.
This can be changed by reimplementing `CalculateHashCode()` method.
Every object will only call it once to cache it for `GetHashCode()`:

```unrealscript
public final function int GetHashCode()
{
    if (_hashCodeWasCached) {
        return _cachedHashCode;
    }
    _hashCodeWasCached = true;
    _cachedHashCode = CalculateHashCode();
    return _cachedHashCode;
}
```

As an example, here is `Text`'s definition that calculates hash based on
the contents:

```unrealscript
protected function int CalculateHashCode()
{
    local int i;
    local int hash;
    hash = 5381;
    for (i = 0; i < codePoints.length; i += 1)
    {
        //  hash * 33 + codePoints[i]
        hash = ((hash << 5) + hash) + codePoints[i];
    }
    return hash;
}
```

This makes sure that two `Text`s with equal contents have the same hash value.

## Boxing

Last important topic to go over is
[boxing](
https://en.wikipedia.org/wiki/Object_type_(object-oriented_programming)#Boxing):
a process of turning primitive types such as `bool`, `byte`, `int` or `float`
into objects.
The concept is very simple, we create a *box* object - an object
that stores a single primitive value.
It could be implemented like that:

```unrealscript
class MyBox extends Object;
var float value;
```

However, Acedia's boxes are *immutable* - their value cannot change once
the box was created.
This means that they store their value in the private field and provide access
to it through the appropriate getter method.

Boxes were introduced because they allowed creation of general collections:
Acedia's collections can only store `AcediaObject`, but, thanks to boxing,
any value can be turned into an `AcediaObject` and stored in the collection.
For native primitive types boxes can be created with either `BoxAPI` or
manually:

```unrealscript
local IntBox    box1;
local FloatBox  box2;
//  Created with `BoxAPI`
box1 = _.box.int(7);
//  Allocated and initialized manually
box2 = FloatBox(_.memory.Allocate(class'FloatBox'));
box2.Initialize(-2.48); // Must be done immediately after allocation!
//  Works the same
Log("Int value:" @ box1.Get());     // Int value: 7
Log("Float value:" @ box2.Get());   // Float value: -2.48
```

Immutable boxes also have a counterpart - mutable *references* that also
provide `Set()` method:

```unrealscript
local IntRef    ref1;
local FloatRef  ref2;
//  Created with `BoxAPI`
ref1 = _.ref.int(7);
//  Allocated and initialized manually
ref2 = FloatRef(_.memory.Allocate(class'FloatRef'));
ref2.Initialize(-2.48); // Must be done immediately after allocation!
//  Change values
ref1.Set(-89);
ref2.Set(0.56);
Log("Int value:" @ ref1.Get());     // Int value: -89
Log("Float value:" @ ref2.Get());   // Float value: 0.56
```

The most important difference between boxes and references concerns
implementation of their `IsEqual()` and `GetHash()` methods:

* Boxes redefine `IsEqual()` and `GetHash()` to depend on the stored value.
    Since value inside the box cannot change, then there is no problem to base
    equality and hash on it.
* References do not redefine `IsEqual()` / `GetHash()` and behave like any
    other object - their hash is random and they are only equal to themselves.

```unrealscript
local ByteBox box1, box2;
local ByteRef ref1, ref2;
box1 = _.box.byte(56);
box2 = _.box.byte(56);
ref1 = _.ref.byte(247);
ref2 = _.ref.byte(247);
// Boxes equality: true
Log("Boxes equality:" @ (box1.IsEqual(box2)));
// Boxes hash equality: true
Log("Boxes hash equality:" @ (box1.GetHash() == box2.GetHash()));
// Refs equality: false
Log("Refs equality:" @ (ref1.IsEqual(ref2)));
// Refs hash equality: false
// (that's the most likely result, but it can actually be `true` by pure chance)
Log("Refs hash equality:" @ (ref1.GetHash() == ref2.GetHash()));
```

> **NOTE:** For `string`s the role of boxes and references is performed by
> `Text` and `MutableText` classes that are discussed elsewhere.

### Actor references with `NativeActorRef`

As was explained in [safety rules](./safety.md), storing references to actors
directly inside objects is a bad idea.
The safe way to do it are *actor references*:
`ActorRef` for Acedia's actors and `NativeActorRef` for any kind of actors.
Actor returned by their `Get()` method is guaranteed to be safe to use:

```unrealscript
class MyObject extends AcediaObject;

var NativeActorRef pawnReference;
// ...

protected function Finalizer()
{
    _.memory.Free(pawnReference); // This does not destroy stored pawn!
    pawnReference = none;
}

function Pawn GetMyPawn()
{
    if (pawnReference == none) {
        return none;
    }
    return Pawn(pawnReference.Get());
}

function SetMyPawn(Pawn newPawn)
{
    if (pawnReference == none)
    {
        //  `UnrealAPI` deals with storing non-Acedia actors such as `Pawn`.
        //  For `AcediaActor`s you can also use `_.ref.Actor()`.
        pawnReference = _.unreal.ActorRef(newPawn);
    }
    else {
        pawnReference.Set(newPawn);
    }
}

function DoWork()
{
    local Pawn myPawn;
    myPawn = GetMyPawn();
    if (myPawn == none) {
        return;
    }
    // <Some code that might `Destroy()` our pawn>
    // ^ After destroying a pawn,
    //  `myPawn` local variable might go "bad" and cause crashes,
    //  so it's a good idea to "update" it from the safe `pawnReference`:
    myPawn = GetMyPawn();
    if (myPawn != none) {
        myPawn.health += 10;
    }
}
```

Actor boxes do not exist, since we cannot guarantee that value inside them will
never change - destroying stored actor will always reset it to `none`.

### Array boxes and references

If necessary, box and reference classes can be manually created for any type
of value, including `array<...>`s and `struct`s.
Acedia provides such classes for arrays of primitive types out of the box.
They can be useful for passing huge arrays between objects and functions
by reference, without copying their entire data every time.
They also provide several convenience methods - here is a list for
`FloatArrayRef`'s methods as an example:

| Method | Description |
| ------ | ----------- |
| `Get()` | Returns the whole stored array as `array<float>`. |
| `Set(array<float>)` | Sets the whole array value. |
| `GetItem(int, optional float)` | Returns item at specified index. If index is invalid, returns passed default value. |
| `SetItem(int, float)` |Changes array's value at specified index. |
| `GetLength()` | Returns length of the array. `ref.GetLength()` is faster than `ref.Get().length`, since latter will make a copy of the whole array first |
| `SetLength(int)` | Resizes stored array, doing nothing on negative input. |
| `Empty()` | Empties stored array. |
| `Add(int)` | Increases length of the array by adding specified amount of new elements at the end. |
| `Insert(int index, int count)` | Inserts `count` zeroes into the array at specified position. The indices of the following elements are increased by `count` in order to make room for the new elements. |
| `Remove(int index, int count)` | Removes number elements from the array, starting at `index`. All elements before position and from `index + count` on are not changed, but the element indices change, - they shift to close the gap, created by removed elements. |
| `RemoveIndex(int)` | Removes value at a given index, shifting all the elements that come after one place backwards. |
| `AddItem(float)` | Adds given `float` at the end of the array, expanding it by 1 element. |
| `InsertItem(int, float)` | Inserts given item at index of the array, shifting all the elements starting from `index` one position to the right. |
| `AddArray(array<float>)` / `AddArrayRef(FloatArrayRef)` | Adds given array of items at the end of the array, expanding it by inserted amount. |
| `InsertArray(array<float>)` / `InsertArrayRef(FloatArrayRef)` | Inserts items array at specified index of the array, shifting all the elements starting from `index` by inserted amount to the right. |
| `RemoveItem(float, bool)` | Returns all occurrences of `item` in the caller `float` (optionally only first one). |
| `Find(float)` | Finds first occurrence of specified item in caller `FloatArrayRef` and returns its index. |
| `Replace(float search, float replacement)` | Replaces any occurrence of `search` with `replacement`. |
| `Sort(optional bool descending)` | Sorts array in either ascending or descending order. |

## [Advanced] Static constructors and finalizers

Acedia also supports a notion of static constructors and finalizers.

Static constructor is called for each class only once:

* Whenever first object of such class is created,
    before its constructor is called;
* If you want static initialization to be done earlier,
    it is possible to call static constructor manually:
    `class'...'.static.StaticConstructor()`.

> **NOTE:** Static constructor being called for your class does not guarantee it
> being called for its parent class. They are considered independently.

Right now relying on static constructors in not advised, but if you are sure
you need them, you can define them like this:

```unrealscript
public static function StaticConstructor()
{
    // This condition is necessary, DO NOT remove it, leave it AS IS
    if (StaticConstructorGuard()) {
        return;
    }
    // Place your logic here
    // ...
}
```

Static finalizers, however, are more important.
They are called during Acedia's shutdown for any class that had its
static constructor invoked (including for any Acedia class that was allocated).
It can be used to "clean up" after yourself.
To have a clean level change it is important that you undo as many changes to
game's objects as you reasonably can.
It is especially important to reset default values, unless their change is
deliberate.
Here is an example that was used in the base `AcediaObject` class at some point:

```unrealscript
protected static function StaticFinalizer()
{
    //  Not cleaning object references in `default` values will interfere
    //  with garbage collection
    default._textCache  = none;
    default._objectPool = none;
    //  Not cleaning this value will prevent static constructors
    //  (and a whole bunch of other code) from being called after the map change
    default._staticConstructorWasCalled = false;
}
```

## [Advanced] Technical details

### How allocation and deallocation works

UnrealScript lacks any practical way to destroy non-actor objects on demand:
the best one can do is remove any references to the object and wait for
garbage collection.
But garbage collection itself is too slow and causes noticeable lag spikes
for players, making it suitable only for cleaning objects when switching levels.
To alleviate this problem, there exists a standard class `ObjectPool`
that stores unused objects (mostly resources such as textures) inside
dynamic array until they are needed.

Unfortunately, using a single `ObjectPool` for a large volume of objects is
impractical from performance perspective, since it stores objects of
all classes together and each object allocation from the pool can potentially
require going through the whole array:

```unrealscript
//  FILE: Engine/ObjectPool.uc
simulated function Object AllocateObject(class ObjectClass)
{
    local Object    Result;
    local int        ObjectIndex;

    for(ObjectIndex = 0;ObjectIndex < Objects.Length;ObjectIndex++)
    {
        if(Objects[ObjectIndex].Class == ObjectClass)
        {
            Result = Objects[ObjectIndex];
            Objects.Remove(ObjectIndex,1);
            break;
        }
    }

    if(Result == None)
        Result = new(Outer) ObjectClass;

    return Result;
}
```

Acedia uses a separate object pool (implemented by `AcediaObjectPool`)
for every single class, making object allocation as trivial as grabbing
the last stored object from `AcediaObjectPool`'s internal dynamic array:

```unrealscript
//  From `AcediaObjectPool` sources
public final function AcediaObject Fetch()
{
    local AcediaObject result;
    if (storedClass == none)    return none;
    if (objectPool.length <= 0) return none;

    result = objectPool[objectPool.length - 1];
    objectPool.length = objectPool.length - 1;
    return result;
}
```

New pool is prepared for every class you create, as long as it is inherited
from `AcediaObject`.
`AcediaActor`s do not use object pools and are simply `Destroy()`ed.

### Detecting deallocated objects

Deallocated objects are not destroyed, but simply stored inside a special pool
to be later reused.
Problems can arise if some function deallocates your object without telling you.
If you suspect this might be the case or just want to make extra sure
your object is intact, then there are ways to confirm it.

First relevant method is defined in any class derived from
`AcediaObject` or `AcediaActor`: `IsAllocated()` that returns
`true` for objects that are currently allocated and `false` otherwise.
However, this method is not enough, since your object might be *reallocated*:
first deallocated and then allocated again by some other code.
Then `IsAllocate()` will return `true` even though your reference is
no longer valid.

This issue can be solved with a *life version* - `int` value that changes
each time object is reallocated:

```unrealscript
local int lifeVersion;
local Text originalObject, newObject;
//  Get object and remember its life version
originalObject = _.text.FromString("My string");
lifeVersion = originalObject.GetLifeVersion();
//  Allocated objects always have positive life version
//  and it won't change until they get deallocated
Log(originalObject.IsAllocated());                      // true
Log(originalObject.GetLifeVersion() > 0);               // true
Log(originalObject.GetLifeVersion() == lifeVersion);    // true
//  But after deallocation, life version will change and become negative
originalObject.FreeSelf();
Log(originalObject.IsAllocated());                      // false
Log(originalObject.GetLifeVersion() > 0);               // false
Log(originalObject.GetLifeVersion() == lifeVersion);    // false
//  This will reallocate object we've just deallocated
//  and it will have different (positive) life version
newObject = _.text.FromString("New string!");
Log(originalObject == newObject);                       // true
Log(originalObject.IsAllocated());                      // true
Log(originalObject.GetLifeVersion() > 0);               // true
Log(originalObject.GetLifeVersion() == lifeVersion);    // false
```

Summarizing, to detect whether your object was reallocated -
remember its life version value right after allocation
and then compare it to the `GetLifeVersion()`'s result.
Value returned by `GetLifeVersion()` changes after each reallocation
and won't repeat for the same object.
The only guarantee about life versions of objects,
that aren't currently allocated, is that they will be negative.

### Customizing object pools for your classes

Object pool usage can be disabled completely for your class by setting
`usesObjectPool = false` in `defaultproperties` block.
Without object pools `_.memory.Allocate()` will create a new instance of
your class every single time.

You can also set a limit to how many objects will be stored in
an object pool with `defaultMaxPoolSize` variable.
Negative number (default for `AcediaObject`) means that object pool can
grow without a limit.
`0` effectively disables object pool, similar to setting
`usesObjectPool = false`.
However, this can be overwritten by server's settings
(see `AcediaSystem.ini: AcediaObjectPool`).
