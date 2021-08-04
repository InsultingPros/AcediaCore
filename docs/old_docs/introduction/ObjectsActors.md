# Acedia's objects and actors

Acedia provides it's own base classes for objects and actors: `AcediaObject`/`AcediaActor` that allow a better integration into Acedia's infrastructure, by providing efficient means for their allocation/deallocation and access to Acedia-specific global methods.

## Allocation and deallocation

Any object (including actors) in Acedia must ultimately be allocated by `_.memory.Allocate()`. Although this method can be used to create object/actor of any class (including those that have nothing to do with Acedia), it does some additional initialization work for `AcediaObject` and `AcediaActor` that is necessary for them to function properly. Any allocated object, once no longer needed, must be deallocated via either `self.FreeSelf()` or `_.memory.Free()` methods.

Combination of these methods allows Acedia to store unused `AcediaObject`s in special pool and reuse them later when they are actually needed. This allows us to avoid creation of their excessive copies. However a care must be taken on a modder's side to properly manage such objects:

1. **You must never in any way use objects you have already deallocated;**
2. **You must not deallocate objects other that still might be used in other parts of the code.**

Acedia tries to minimize the need for manual allocation/deallocation and there're plans to potentially remove the need to care about it completely, but as of now it is impossible and is the necessary price for the benefits Acedia is making use of.

## Benefits

### Constructors and finalizers

Implementing and enforcing (de)allocation allowed us to introduce constructors that are guaranteed to be called after any Acedia's object is allocated as well as finalizers that are called when they are deallocated.

To make use of them one can simply overload protected methods `Constructor()` and `Finalizer()`. Parametrized constructors are not supported.

Static constructors are also supported (and can be used by overloading `StaticConstructor()`), - they are methods that take care of some initialization work before any instance of the given class is created. They are called only once, at the latest when an instance of relevant class (or it's child class) is created. `StaticConstructor()` is allowed to be called early to initialize static members of a certain class before creating it's instances.

### General collections

Ability to allocate/deallocate objects in a way makes them cheaper: our ability to reuse them in theory means that we can keep allocating objects without worrying about having heaps of their old, now useless instances cluttering up our memory.

This, in turn, lets us use *boxes* - objects that we create to simply store primitive variables like `int`, `float` or `string` inside. This adds overhead on memory and time of accessing them, but it also allows us to store different types of variables in a single array `array<AcediaObject>`.

Following code illustrates it:

```unrealscript
local IntBox numberBox;
local BoolBox logicBox;
local array<AcediaObject> myArray;

//  There two lines simply store `7` and `true` in boxes:
numberBox = _.box.int(7);
logicBox = _.box.bool(true);

//  And now array our can stores both values:
myArray[0] = numberBox;
myArray[1] = numberBox;
```

While that example is artificial and of dubious usefulness, it lets Acedia provide:

1. `AssociativeArray` collection that implements hash map to store `AcediaObject`s with `AcediaObject` keys;
2. Method for parsing JSON of any complexity into regular Acedia's objects;

## Dangers

Title is *Dangers* but there's pretty much one main danger: someone (possibly you) will deallocate a certain object, but will then keep using it. So if you later allocate object of the same class, you can potentially share an instance with someone else, which can lead to all sorts of unpredictable bugs.

General recommendation to combat this is to take care to properly manage your resources. Always setting to `none` any object variables you've deallocated might help.

There are some ways to alleviate this issue for yourself:

1. Specifying an optional argument to allocation method: `_.memory.Allocate(..., true)` that forces it to create a new object;
2. Using object classes that have disabled object pool altogether (can be done with setting `usesObjectPool = false` in default properties).
3. If you are worried that some other piece of the code might deallocate your object without, you can check for it with life version. Each time an object (the same from UnrealScript's point of view) is re-allocated, it receives a unique to it *life version* that can be accessed by method `GetLifeVersion()`. You can use remember this value and if it's changed - then referenced object was deallocated at some point.

## Hash

To allow for implementation of hash maps (`AssociativeArray`), Acedia's objects and actors provide a `GetHashCode()` method that calculates their hash ([wiki](https://en.wikipedia.org/wiki/Hash_function)). For most objects it's simply an `int`, randomly generated upon their allocation.

There are, however, exceptions. For example, `Text`'s hash depends solely on it's contents, since they cannot be changed. Therefore two `Text`s, that store the same `string` value, will have the same hash, making them a good choice as a key of the hash map.

## Boxes, refs and hashing

Boxes and references (or just refs) are trivial wrappers around other variable types. For example here is full listing of `int`-reference (`IntRef`):

```unrealscript
class IntRef extends ValueRef;

var protected int value;

public final function int Get()
{
    return value;
}

public final function IntRef Set(int newValue)
{
    value = newValue;
    return self;
}

public function bool IsEqual(Object other)
{
    local IntRef otherBox;
    otherBox = IntRef(other);
    if (otherBox == none) {
        return false;
    }
    return value == otherBox.value;
}
```

Box definition (`IntBox`) is similar. Benefit of boxes and refs is that they allow us to "transform" primitive types into the child type of `AcediaObject` (and, therefore, `Object` as well) and then store them in any collection that allows us to store `AcediaObject`s.

You can manually create box and ref type for any of your classes/structs, however it is currently cumbersome and a better way is planned in the future.

### Difference between boxes and refs

The difference is that boxes are immutable, once value has been recorded into them, it cannot be changed. This makes them inconvenient as variables, but instead allows their hash to depends only on their contents, which lets them be usable as keys for `AssociativeArray`. Generally, you want to default to using refs and only use boxes as key for `AssociativeArray`.

If you do need to use a box, - either create them using appropriate API (`_.box.`) or initialize them right after the allocation.

### Array boxes

Acedia provides not only boxes for primitive types themselves, but also for their arrays (for example `IntArrayBox`/`IntArrayRef`). Unlike standard UnrealScript arrays, they are passed by reference (because they are objects) and provide move functionality (like searching or, for array refs, sorting and inserting other arrays).

## [Technical] How allocation works

UnrealScript lacks any practical way to destroy an object on demand: the best one can do is remove any references to an object and wait for garbage collection (GC). But GC itself is too slow and causes noticeable lag spikes for players and can only seamlessly be used when switching between maps. There is a standard class `ObjectPool` that helps alleviate this problem by temporary storing unused references until they are needed. A reference to an instance of `ObjectPool` is provided by `LevelInfo`.

Unfortunately, using a single `ObjectPool` for a large volume of objects is impractical from performance perspective, since it stores objects of all classes together and each time a new object is requested from the pool, - allocation method has to search through all the other objects before finding an appropriate one. Modders can create their own `ObjectPool` instances specifically for their classes, but it's relatively cumbersome to reimplement each time.

Acedia automates this process by automatically providing each of it's classes with personal object pool. This extends to any child classes you create, as long as they were inherited from `AcediaObject` or `AcediaActor` at some point.

## [Technical] Customizing object pools for your classes

Object pool usage can be disabled completely for your class by setting `usesObjectPool = false`, which is the default for `AcediaActor`.

You can also set a limit to how many objects will be stored in an object pool with `defaultMaxPoolSize` variable. Negative number (default for `AcediaObject`) means that it can grow without a limit. `0` effectively disables object pool, similar to setting `usesObjectPool = false`. However do note that this variable can be overwritten by server's setting (see `AcediaSystem.ini: AcediaObjectPool`).

## [Technical] `AcediaObjectPool`

`AcediaObjectPool` is the class used for managing deallocated objects, derived from either `AcediaObject` or `AcediaActor`. For them it's created automatically and can be accessed by `_getPool()` static method.

However you can also make use of it for any kind of object. It has a simple interface and is not actually derived from either `AcediaObject` or `AcediaActor`, meaning that it can be created simply with a standard `new` operation. Just remember to first initialize it for a particular class you want to store with `Initialize()`.
