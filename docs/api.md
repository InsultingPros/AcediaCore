# Acedia's API

Acedia's API is our way of solving the problem of adding new *global functions*.
Examples of *global functions* are `Log()`, `Caps()`, `Abs()`, `VSize()`
and a multitude of others that you can call from anywhere in UnrealScript.
They can be accessed from anywhere because they are all declared as
static methods inside `Object` - a base class for any other class.
Problem is, since we cannot add our own methods to the `Object`,
then we also can't add new global functions.
The best we can do is declare new static methods in our own classes,
but calling them would be cumbersome: `class'glb'.static.DoIt()`.

Idea that we've used to solve this problem for Acedia is to provide every single
Acedia object with an instance of a class that would contain all our
global functions.
We save an instance of this class in a local variable
`_`, which allows us to simply write `_.DoIt()`.

In actuality we don't just dump all of Acedia's global functions into
one object, but group them into different APIs that can be accessed
through `_` variable:

```unrealscript
_.text.FromString("I am here!");        // Text API
_.alias.ResolveColor("blue");           // Alias API
_.collections.EmptyDynamicArray();      // Collections API
_.memory.Allocate(class'SimpleSignal'); // Memory API
```

`_` can't be accessed in static methods, since only default values are
available in them.
Since writing `default._` would also be bulky, `AcediaObject` and `AcediaActor`
provide a static method `public static final function Global __()`
that is always available:

```unrealscript
__().text.FromString("I am here!");
__().alias.ResolveColor("blue");
__().collections.EmptyDynamicArray();
__().memory.Allocate(class'SimpleSignal');
```

Any class you make that derives from either `AcediaObject` or `AcediaActor`
will have `_` and `__()` defined.
If you need to create a class that does not derive from Acedia's classes,
but you want to make Acedia's API be available inside it,
then you simply need to redefine `_` and `__()`:

```unrealscript
var Global _;

public static final function Global __()
{
    return class'Global'.static.GetInstance();
}

// ...
// Set `_`'s value somewhere before using your class:
_ = class'Global'.static.GetInstance();
```