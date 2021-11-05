# Collections

All Acedia's collections store `AcediaObject`s. By taking advantage of boxing we can use them to store arbitrary types: both value types (native variables and structs) and reference types (`AcediaObject` and it's children).

Currently Acedia provides dynamic (indexed, variable sized array) and associative arrays (collection of key-value pairs with quick access to values via keys). Using them is fairly straightforward, but, since they're dealing with objects, some explanation about their memory management is needed. Next section aims to explain all that with some examples.

## Usage examples

### Dynamic arrays

Dynamics arrays can be created via either of `_.collections.EmptyDynamicArray()` / `_.collections.NewDynamicArray()` methods. `_.collections.NewDynamicArray()` takes an `array<Acedia>` argument and populates returned `DynamicArray` with it's items, while `_.collections.EmptyDynamicArray()` simply creates an empty `DynamicArray`.

They are similar to regular dynamic `array<AcediaObject>`s with several differences:

1. It's passed by reference, rather than by value (`DynamicArray` isn't copied each time it's passed as an argument to a function);
2. It has richer interface;
3. It can handle Acedia's object deallocation.

As an example to illustrate basic usage of `DynamicArray` let's create a trivial class that remembers players by their nickname:

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
    //  Optionally there's a flag to only remove the first one.
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
TEST_ExpectNotNone(item);
TEST_ExpectNone(storage.GetItem(0));
TEST_ExpectFalse(storage.GetItem(0) == item);
```

Let's explain what's changed after deallocation:

1. Even though we've deallocated `item`, it's reference still points at `Text` object. This is because deallocation is an Acedia's convention and actual UnrealScript objects are not destroyed by it;
2. `storage.GetItem(0)` no longer points at that `Text` object. Unlike a simple `array<AcediaObject>`, `DynamicObject` tracks status of it's items and replaces their values with `none` when they are deallocated. This cleanup is something we cannot do with simple `FreeSelf()` or even `_.memory.Deallocate()` for regular object, but can for objects stored in collections.
3. Since collection forgot about `item` after it was deallocated, `storage.GetItem(0) == item` will be false even if an instance of `item` will be later reused from it's object pool.

#### What happens if we deallocate our `DynamicArray` collection?

By default nothing.

To avoid items disappearing from our collections, we can put in their copies instead. For `Text` it can be accomplished with a simple `Copy()` method: `storage.AddItem(item.Copy())`. But this leads us to another problem - `storage` won't actually deallocate this item if we simply remove it. We will have to do so manually to prevent memory leaks:

```unrealscript
...
_.memory.Deallocate(storage.GetItem(i));
storage.RemoveIndex(i);
```

which isn't ideal.

To solve this problem we can add a copy of an `item` to our `DynamicArray` as a **managed object**: collections will consider themselves responsible for deallocation of objects marked as managed and will do it for us. To add item as managed we need to simply specify second argument for `AddItem(, true)` method:

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

It depends on your needs whether you'd want your collection to auto-deallocate your items or not. Note also that the same collection can contain both managed and unmanaged items.

Let's rewrite `RegisterNick()` method of `PlayerDB` to make it independent from whether `Text` objects passed to it are deallocated:

```unrealscript
...
public function RegisterNick(Text newNickName)
{
    if (newNickName == none)            return;
    if (storage.Find(newNickName) >= 0) return;
    storage.AddItem(newNickName.Copy(), true);
}
...
```

### Associative arrays

> **NOTE:** It is assumed you've read previous section about `DynamicArray`s and it's managed objects first.

Associative arrays allow to store and access `AcediaObject` values via `AcediaObject` keys using hash map under the hood. While objects of any `AcediaObject`'s subclass can be used as keys, the main reason for implementing associative arrays was to allow for `Text` keys and examples in this sections will focus on them specifically.

The basic interface is simple and can be demonstrated like so:

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

In above example we've created separate text instances (with the same contents) to store and retrieve items in `AssociativeArray`. However it's inefficient to each time create `Text` anew:

1. It defeats the purpose of using `Text` over `string`, since one of `Text`'s main benefits is that once created, it allows cheaper access to individual characters and allows us to compute `Text`'s hash only once, caching it. But if we create `Text` object every time we want to access value in `AssociativeArray` we will only get more overhead without any benefits.
2. It leads to creation of useless objects, that we didn't deallocate in the above example.

So it's recommended that, whenever possible, your class would define `Text` constant that it'd want to use as keys beforehand. If you want to implement a class that receives zed's data as an `AssociativeArray` and wants to buff it's health, you can do the following:

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

[Text](../instroduction/Text.md) has more information about how else you can efficiently create `Text` constants. For example, in the above use case of upgrading zed's health we can instead do this:

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

`AssociativeArray` support the concept of managed objects in the same way as `DynamicArray`s: by default objects are not managed, but can be added as such when optional argument is used: `AssociativeArray.GetItem(P("value"), someItem, true)`. We'll just note here that it's possible to remove a managed item from `AssociativeArray` without deallocating it with `TakeItem()`/`TakeEntry()` methods.

A question specific for `AssociativeArray`s is whether they deallocate their keys. And the answer is: they do not. `AssociativeArray` will never deallocate it's keys, even if managed value is recorded with them. This way one can use the same pre-allocated key in several different `AssociativeArray`s. If you do need to deallocate them, you will have to do it manually.

In case of the opposite situation, where one deallocates an `AcediaObject` used as a key: `AssociativeArray` will automatically remove appropriate entry in it's entirety. However this is only a clean-up attempt: **you should never deallocate objects that are still used as keys in `AssociativeArray`**. One of the negative consequences is that it'll screw up it's `GetLength()` results, making it possibly overestimate the amount of stored items (there is no guarantee on *when* an entry with deallocated key will be detected and disposed of).

### Associative array keys

`AssociativeArray` allows to store `AcediaObject` values by `AcediaObject` keys. Object of any class (derivative of `AcediaObject`) can be used for either, but behavior of the key depends on how their `IsEqual()` and `GetHashCode()` methods are implemented.

For example `Text`'s hash and equality is determined by it's content:

```unrealscript
local Text t1, t2;
t1 = _.text.FromString("Some random text");
t2 = _.text.FromString("Some random text");
//  All of these assertions are correct:
TEST_ExpectTrue(t1.IsEqual(t2));                        //  same contents
TEST_ExpectTrue(t1.GetHashCode() == t2.GetHashCode());  //  same hashes
TEST_ExpectTrue(t1 != t2);                              //  different objects
```

Therefore, if you used one `Text` as a key, then you will be able to obtain it's value with another `Text` that contains the same `string`.

However `MutableText`'s contents can change and so it cannot afford to base it's equality and hash on it's contents:

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

`MutableText` can still be used as a key, but value will only be obtainable by providing the exact instance of `MutableText` used as a key, no matter it's contents.

It's for the similar reason that immutable boxes are more fitting than mutable references as keys.
