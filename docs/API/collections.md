# Collections

All Acedia's collections store `AcediaObject`s. By taking advantage of boxing
we can use them to store arbitrary types:
both value types (native variables and structs)
and reference types (`AcediaObject` and it's children).

Currently Acedia provides dynamic arrays (regular integer-indexed array)
and associative arrays (collection of key-value pairs with quick access to
values via `AcediaObject` keys).
Using them is fairly straightforward, but, since they're dealing with objects,
some explanation about their memory management is needed.
Below we attempt to give a detailed description of everything you need to know
to efficiently use Acedia's collections.

## Usage examples

### Dynamic arrays

Dynamic arrays can be created via either of
`_.collections.EmptyDynamicArray()` / `_.collections.NewDynamicArray()` methods.
`_.collections.NewDynamicArray()` takes an `array<Acedia>` argument and
populates returned `DynamicArray` with it's items, while
`_.collections.EmptyDynamicArray()` simply creates an empty `DynamicArray`.

They are similar to regular dynamic `array<AcediaObject>`s with
several differences:

1. They're passed by reference, rather than by value (no additional copies are
made when passing `DynamicArray` as an argument to a function or assigning it
to another variable);
2. They have richer interface;
3. They automatically handle necessary object deallocations.

As an example to illustrate basic usage of `DynamicArray` let's create
a trivial class that remembers players' nicknames:

```unrealscript
class PlayerDB extends AcediaObject;

var private DynamicArray storage;

//  Constructor and destructor allow for memory management
protected function Constructor()
{
    storage = _.collections.EmptyDynamicArray();
}

protected function Finalizer()
{
    storage.FreeSelf();
    storage = none;
}

public function RegisterNick(Text newNickName)
{
    if (newNickName == none)            return;
    //  `Find` returns `-1` if object is not found
    if (storage.Find(newNickName) >= 0) return;
    storage.AddItem(newNickName);
}

public function IsRegisteredID(Text toCheck)
{
    return (storage.Find(toCheck) >= 0);
}

public function ForgetNick(Text toForget)
{
    //  This method removes all instances of `toForget` in `storage`;
    //  There's also an optional flag to only remove the first one.
    storage.RemoveItem(toForget);
}
```

#### What happens if we deallocate stored objects?

They will turn into `none`:

```unrealscript
local Text item;
local DynamicArray storage;
storage = _.collections.EmptyDynamicArray();
item = _.text.FromString("example");
storage.AddItem(item);
//  Everything is as expected here
TEST_ExpectNotNone(item);
TEST_ExpectNotNone(storage.GetItem(0));
TEST_ExpectTrue(storage.GetItem(0) == item);

//  Now let's deallocate `item`
item.FreeSelf();
//  Suddenly things are different:
TEST_ExpectNotNone(item); // `item` deallocated, but not dereferenced
TEST_ExpectNone(storage.GetItem(0)); // but it is gone from the collection
TEST_ExpectFalse(storage.GetItem(0) == item);
```

Let's explain what's changed after deallocation:

1. Even though we've deallocated `item`, its reference still points at
the `Text` object.
This happens because object being *deallocated* is simply Acedia's flag for it
and, from the Unreal Engine's point of view, `item` still exists and
is being used;
2. `storage.GetItem(0)` no longer points at that `Text` object.
Unlike a simple `array<AcediaObject>`, `DynamicObject` tracks status of its
items and replaces their values with `none` when they're deallocated.
This kind of cleanup is something we cannot do with simple `FreeSelf()` or even
`_.memory.Deallocate()` for object stored in a regular array, but can for
objects stored in Acedia's `Collection`s.
3. Since our collection has forgotten about `item` after it was deallocated,
`storage.GetItem(0) == item` will be false.

#### What happens if we remove an item from our `DynamicArray` collection?

By default nothing - stored items will continue to exist outside the collection.
This is because by default `DynamicArray` (and `AssociativeArray`) is not
responsible for deallocation of its items. But it can be made to.

Suppose that to avoid items disappearing from our collections, we put in their
copies instead.
For `Text` it can be accomplished with a simple `Copy()` method:
`storage.AddItem(item.Copy())`.
This creates a problem - `storage`, as we've just explained, won't actually
deallocate this item if we simply remove it. We will have to do so manually to
prevent memory leaks:

```unrealscript
...
_.memory.Deallocate(storage.GetItem(i));
storage.RemoveIndex(i);
```

which isn't ideal.

To solve this problem we can add a copy of an `item` to our `DynamicArray` as
a *managed object*: collections will consider themselves responsible for
deallocation of objects marked as managed and will automatically clean them up.
To add an item as managed we need to simply specify second argument for
`AddItem(, true)` method:

```unrealscript
local Text item;
local DynamicArray storage;
storage = _.collections.EmptyDynamicArray();
item = _.text.FromString("example");
storage.AddItem(item, true);
//  Here added item is still allocated
TEST_ExpectTrue(item.IsAllocated());
//  But after it's removed from `storage`...
storage.RemoveIndex(0);
//  ...it's automatically gets deallocated
TEST_ExpectFalse(item.IsAllocated());
```

Whether you would want your collection to auto-deallocate your items or not
depends only on how you plan to use your collections.

> **NOTE:**
> The same collection can technically contain both managed and unmanaged items,
> but it is best you avoid mixing these types of items.

Let's rewrite `RegisterNick()` method of `PlayerDB` to make it independent from
whether `Text` objects passed to it are deallocated:

```unrealscript
...
public function RegisterNick(Text newNickName)
{
    if (newNickName == none)            return;
    if (storage.Find(newNickName) >= 0) return;
    //  Store an independent, but managed copy,
    //  that will be gone along with the `storage`
    storage.AddItem(newNickName.Copy(), true);
}
...
```

> **IMPORTANT:**
> While items added to collections aren't managed by *default*,
> it is a convention that if you return a collection from your function and
> make another piece of code responsible for it - that piece of code also
> becomes responsible for that collection's items
> (meaning that it must deallocate them when they are no longer needed).
> If you expect a different behavior - you must specify so in the function's
> description.

### Associative arrays

> **IMPORTANT:**
> It is assumed you've read previous section about `DynamicArray`s and
> its managed objects first.

Associative arrays allow to efficiently store and access `AcediaObject` values
via `AcediaObject` keys by using hash map under the hood.
While objects of any `AcediaObject`'s subclass can be used as keys, the main
reason for implementing associative arrays was to allow for `Text` keys and
examples in this sections will focus on them specifically.

The basic interface is simple and can be demonstrated with this:

```unrealscript
local AcediaObject      item;
local AssociativeArray  storage;
storage = _.collection.NewAssociativeArray();
//  Add some values
storage.SetItem(_.text.FromString("year"), _.ref.int(2021));
storage.SetItem(    _.text.FromString("comment"),
                    _.text.FromString("What year it is?"));
//  Then get them
item = storage.GetItem(_.text.FromString("year"));
TEST_ExpectTrue(IntRef(item).Get() == 2021);
item = storage.GetItem(_.text.FromString("comment"));
TEST_ExpectTrue(Text(item).ToString() == "What year it is?");
```

In above example we've created separate text instances (with the same contents)
to store and retrieve items in `AssociativeArray`.
However it is inefficient to each time create `Text` anew just to get an item:

1. It defeats the purpose of using `Text` over `string`, since
(after initial creation cost) `Text` allows for a cheaper access to
individual characters and also allows us to compute `Text`'s hash only once,
caching it for later use.
But if we create `Text` object every time we want to access value in
`AssociativeArray` we will only get more overhead without any benefits.
2. It leads to creation of useless objects, that we didn't even deallocate in
the above example.

So it is recommended that, whenever possible, your class would define reusable
`Text` constant that it would want to use as keys beforehand.
If you want to implement a class that receives zed's data as
an `AssociativeArray` and wants to buff its health, you can do the following:

```unrealscript
class MyZedUpgrader extends AcediaObject;

var protected Text TMAX_HEALTH;

protected function StaticConstructor()
{
    default.TMAX_HEALTH = _.text.FromString("maxhealth");
}

public final function UpgradeMyZed(AssociativeArray zedData)
{
    local IntRef maxHealth;
    maxHealth = IntRef(AssociativeArray.GetItem(TMAX_HEALTH));
    maxHealth.Set(maxHealth.Get() * 2);
}
```

[Text](./text.md) has more information about convenient ways to
efficiently create `Text` constants.
For example, in the above use case of upgrading zed's health it is acceptable to
do this instead:

```unrealscript
class MyZedUpgrader extends AcediaObject;

public final function UpgradeMyZed(AssociativeArray zedData)
{
    local IntRef maxHealth;
    maxHealth = IntRef(AssociativeArray.GetItem(P("maxhealth")));
    maxHealth.Set(maxHealth.Get() * 2);
}
```

#### Memory management and `AssociativeArray`

`AssociativeArray` supports the concept of managed objects in the same way as
`DynamicArray`s: by default objects are not managed, but can be added as such
when optional argument is used:
`AssociativeArray.GetItem(P("value"), someItem, true)`.
We'll just note here that it's possible to remove a managed item from
`AssociativeArray` without deallocating it with `TakeItem()`/`TakeEntry()`
methods.

A question specific for `AssociativeArray`s is whether they deallocate
their keys.
And the answer is: they do not.
`AssociativeArray` will not deallocate its keys, even if a managed value is
recorded with them.
This way one can use the same pre-allocated key in several different
`AssociativeArray`s.
If you do need to deallocate them, you will have to do it manually.

One good way to do so is to use `TakeEntry(AcediaObject key)` method that
returns a struct `Entry` with both key and recorded value inside:

```unrealscript
struct Entry
{
    //  Non-public fields are omitted
    var public      AcediaObject    key;
    var public      AcediaObject    value;
    var public      bool            managed;
};
```

This method also always removes stored value from `AssociativeArray` without
deallocating it, even if it was managed, making you responsible for it.

Another way is to completely clear your collection along with any keys inside
with `Empty(true)` method.
This method recursively clears your collection (also making `Empty()` calls on
any collections stored inside yours) and passing it `true` as a parameter makes
it deallocate any key objects used in these collections.

In case of the opposite situation, where one deallocates an `AcediaObject` used
as a key, `AssociativeArray` will automatically remove appropriate entry
in its entirety.
However this is only a contingency measure:
**you should never deallocate objects that are still used as keys in `AssociativeArray`**.
One of the negative consequences is that it'll screw up `AssociativeArray`'s
`GetLength()` results, making it possibly overestimate the amount of
stored items (because there is no guarantee on *when* an entry with
deallocated key will be detected and cleaned up).

#### Capacity

Acedia's `AssociativeArray` works like a hash table and needs to allocate
sufficiently large dynamic array as a storage for its items.
If you keep adding new items that storage will eventually become too small for
hash table to work efficiently and we will have to reallocate and re-fill it.
If you want to add a huge enough amount of items into your `AssociativeArray`,
this process might be repeated several times.
This is not ideal, since it means doing a lot of iteration, each taking
noticeable time and increasing infinite loop counter
(game will crash if it gets high enough).
`AssociativeArray` allows you to set minimal capacity with
`SetMinimalCapacity()` method to force it to pre-allocate enough space for
the expected amount of items.
Setting minimal capacity to the maximum amount of items you expect to store in
the caller `AssociativeArray` will remove any need for reallocating the storage.

> **NOTE:**
> `AssociativeArray` always allocates storage array with length of at least
> `MINIMUM_SIZE = 50` and won't need any reallocations before you add at least
> `MINIMUM_SIZE * MAXIMUM_DENSITY = 50 * 0.75 ~= 38` items,
> no matter the current minimal capacity
> (that can be checked with `GetMinimalCapacity()` method).

#### [Advanced] Associative arrays' keys

`AssociativeArray` allows to store `AcediaObject` values by `AcediaObject` keys.
Ultimately, any `AcediaObject` can be used for either, but
behavior of the `AssociativeArray` regarding its key depends on how key's
`IsEqual()` and `GetHashCode()` methods are implemented.

> **IMPORTANT:**
> [Refresh](../objects.md) your knowledge on how equality checks for
> Acedia's objects work, do not rely on intuition here.

For example `Text`'s hash and equality is determined by its content:

```unrealscript
local Text t1, t2;
t1 = _.text.FromString("Some random text");
t2 = _.text.FromString("Some random text");
//  All of these assertions are correct:
TEST_ExpectTrue(t1.IsEqual(t2));                        //  same content
TEST_ExpectTrue(t1.GetHashCode() == t2.GetHashCode());  //  same hashes
TEST_ExpectTrue(t1 != t2);                              //  different objects
```

Therefore, if you used one `Text` as a key, then you will be able to obtain its
value with another `Text` that contains the same `string`.
However `MutableText`'s contents can change dynamically, so it cannot afford to
base its equality and hash on its contents:

```unrealscript
local MutableText t1, t2;
t1 = _.text.FromStringM("Some random text");
t2 = _.text.FromStringM("Some random text");
//  `IsEqual()` no longer compares contents;
//  Use `Compare()` instead.
TEST_ExpectFalse(t1.IsEqual(t2));
TEST_ExpectFalse(t1.GetHashCode() == t2.GetHashCode()); //  different hashes (most likely)
TEST_ExpectTrue(t1 != t2);                              //  different objects
```

`MutableText` can still be used as a key, but value stored with it will only be
obtainable by providing the exact instance of `MutableText`, regardless of
its contents:

```unrealscript
local MutableText       t1, t2;
local AssociativeArray  storage;
storage = _.collection.NewAssociativeArray();
t1 = _.text.FromStringM("Some random text");
t2 = _.text.FromStringM("Some random text");
storage.SetItem(t1, _.text.FromString("Contents!"));
TEST_ExpectNone(storage.GetItem(t2));
TEST_ExpectNotNone(storage.GetItem(t1));
```

As far as base Acedia's classes go, only `Text` and boxed
(immutable ones, not refs) values are a good fit to be used as
contents-dependent keys.

## Better accessors

While you can store simple values inside these arrays in a straightforward
manner of `storage.SetItem(_.text.FromString("year"), _.ref.int(2021))`,
it is not very convenient.
Especially getting items from such arrays can be problematic, since that `int`
can potentially be stored as both immutable `IntBox` or mutable `IntRef`.

To help with this problem Acedia's collections provide a bunch of convenience
accessors for UnrealScript's built-in types.
Let us start with getters
`GetBool()`, `GetByte()`, `GetInt()`, `GetFloat()`, `GetText()`
(since Acedia uses `Text` instead of `string`).
These take index for `DynamicArray` or `AcediaObject` keys for
`AssociativeArray` and return relevant type if they find either box or a ref
of such type in the caller array.
All of them, except `Text`, also allow you to provide default value as
a second argument - this value will be used if neither box or ref for
the desired type is found.

Then there's setter methods
`SetBool()`, `SetByte()`, `SetInt()`, `SetFloat()` that take
at least two parameters: index/key and value to store.
They automatically create either box or ref object to wrap around passed
primitive value and always store it as a *managed item*.
Third, optional, `bool` parameter `asRef` allows you to decide whether passed
value should be saved inside the array in an immutable box or in a mutable ref
(default `false` is to save that primitive type in a box).

> **NOTE:**
> There is no paired `SetText()` setter for `GetText()` getter,
> since `Text` itself is an object and can directly be saves with `SetItem()`.

Here is an example of how they work:

```unrealscript
local IntBox        box;
local IntRef        ref;
local DynamicArray  storage;
storage = _.collection.NewDynamicArray();
storage.SetInt(0, 7);
//  `int` value is not returned normally, but there is not auto-conversion
//  into `float` and so `GetFloat()` returns provided default value instead
Log("Value as int:" @ storage.GetInt(0));           //  Value as int: 7
Log("Value as float:" @ storage.GetFloat(0, 9));    //  Value as int: 9

box = IntBox(storage.GetItem(0));
//  `int` should be stored in an allocated box
TEST_ExpectNotNone(box);
TEST_ExpectTrue(box.IsAllocated());
//  Re-recording `int` as ref causes previous box (managed by `storage`)
//  to get destroyed
storage.SetInt(0, 11, true);
TEST_ExpectNotNone(box);                // still not `none`
TEST_ExpectFalse(box.IsAllocated());    // but is not deallocated
Log("Value as int:" @ storage.GetInt(0)); //  Value as int: 11
//  `int` should be stored in an allocated ref now
ref = IntRef(storage.GetItem(0));
TEST_ExpectNotNone(ref);
TEST_ExpectTrue(ref.IsAllocated());
```

## Even more accessors

Collections `DynamicArray` and `AssociativeArray` are `AcediaObject`s themselves
and, therefore, can be stored in other arrays, producing hierarchical
structures, similar to those of JSON's arrays / objects.

```json
{
    "main_guy": {
        "status": "admin",
        "maps": ["biotics", "bedlam", "waterworks"]
    },
    "other_guy": {
        "status": "random",
        "maps": ["biotics", "westlondon"]
    }
}
```

To access some variable, nested deep inside such structure, one can either
manually get reference of each collection on the way, e.g. to access second map
of the "other_guy" we'd need to first get reference to "other_guy"'s collection
(`AssociativeArray`):

```json
{
    "status": "random",
    "maps": ["biotics", "westlondon"]
}
```

then to the array of his maps (`DynamicArray`):

```json
["biotics", "westlondon"]
```

and only then access second item.
This is too cumbersome!
Fortunately, Acedia's collections have an alternative solution:

```unrealscript
userCollection.GetTextBy(P("/other_guy/maps/1"));   //  westlondon!
```

`/other_guy/maps/1` line is describes a path to the element nested deep inside
hierarchy of collections and follows the rules of a
[JSON pointer](https://datatracker.ietf.org/doc/html/rfc6901).
Both `DynamicArray` and `AssociativeArray` support following methods that work
with such pointers:
`GetItemBy()`, `GetBoolBy()`, `GetByteBy()`, `GetIntBy()`, `GetFloatBy()`,
`GetTextBy()`, `GetDynamicArrayBy()` and `GetAssociativeArrayBy()`.

Passing paths like `/other_guy/maps/1` requires collections to perform their
parsing every time such getter is called.
If you want to reuse the same path several times it might be better to convert
it into `JSONPointer` object (using `_.json.Pointer()` method) and then use
that object with following alternative methods:
`GetItemByJSON()`, `GetBoolByJSON()`, `GetByteByJSON()`, `GetIntByJSON()`,
`GetFloatByJSON()`, `GetTextByJSON()`, `GetDynamicArrayByJSON()`,
`GetAssociativeArrayByJSON()`.
This way parsing has to be done only once - when creating `JSONPointer` object.
