# AcediaCore alpha

AcediaCore is an UnrealScript library that is intended to provide a framework
for creating mods for Killing Floor.
Currently AcediaCore...

* **Changes as little as possible.** Despite its size, AcediaCore will only
    make changes that were requested from it, otherwise doing nothing and
    providing you with completely vanilla experience.
    This is a quality it will keep in all consequent releases.
* **Server-side.** So far AcediaCore was developed as a server-side only
    library.
    Some work on client-side feature has already started and at some point
    AcediaCore *will* support working with mods that affect clients, but
    this side of API is not intended to be accessed as of right now.
* **Unstable API** This doesn't mean that AcediaCore crashes, but that API
    provided by AcediaCore (classes definitions, functions' signatures, ...)
    can and will change as development goes on.
    We aren't going to do it just for the hell of it and will try to preserve
    the current behavior as much as is reasonable, but if providing a better API
    would require us breaking compatibility, we will break it
    (until version `1.0` is released).

AcediaCore is currently in the alpha with a goal is to gather some feedback from
other people while finishing some yet incomplete features and writing
documentation.

## Why should I use it?

TODO:

* Talk about how the proper documentation is still in development, link whatever
    will be available for Friday.
* Add section about gameplay API, why it exists, how complete it is and how it
    is not mandatory to use.
* Short installation/using instructions.

### Aliases

Aliases are basically alternative (more human-readable) names for pretty much
anything.
For example, inventory class of Killing Floor's AK47 is
`KFMod.AK47AssaultRifle`, which is a handful.
AcediaCore allows server admins to define their own aliases for such
values, that can later be used by other mods:
[Futility](https://www.insultplayers.ru/git/dkanus/Futility)
allows to add AK47 to a player with a chat command like
`!inventory SomeGuy add $ak47`, where `$ak47` will be resolved like an alias.

There more aliases type than
[weapon aliases](https://www.insultplayers.ru/git/dkanus/AcediaCore/src/branch/master/config/AcediaAliases_Colors.ini).
Like [color aliases](https://www.insultplayers.ru/git/dkanus/AcediaCore/src/branch/master/config/AcediaAliases_Colors.ini),
[entity aliases](https://www.insultplayers.ru/git/dkanus/AcediaCore/src/branch/master/config/AcediaAliases_Entities.ini).
Or you can even add a custom alias source, if you need aliases for something
completely different.

### Commands

> **NOTE:** AcediaCore's commands are fully functional, but there are still some
> changes planned for them during the alpha.

AcediaCore provides a unified command system.
Instead of the usual way of manually handling `mutate` input to detect your
command and its parameters, you can simply specify command's name and types of
the parameters it should take, register this command with AcediaCore and let it
handle the rest.
Most prominent features of AcediaCore's commands are:

* Supported parameters range from simple `int` or `string` to complex
    JSON values. Some parameters can be marked as optional.
* Ability to specify targeted players with advanced selector system
    (e.g. `@`/`@self` refers to the caller player, `@all` to every player and
    `[@all, !@self, !Dude]` to every player except you and someone called
    "Dude").
* Ability to specify *options*: additional modifiers that start with either `--`
    or `-`.

Nice example is [Futility](https://www.insultplayers.ru/git/dkanus/Futility)'s
command that allows you to give yourself all available weapons:
`inventory@ add --list all --force`.
Same command also be written as `inventory@ add -lf all`, where `-lf` specifies
both `--force` and `--list` options.
This command is defined
[here](https://www.insultplayers.ru/git/dkanus/Futility/src/branch/master/sources/Commands/ACommandInventory.uc).

### Text and colors

AcediaCore provides its own text types as alternative to `string`:
`Text` and `MutableText`.
They are less efficient than `string`, but provide a richer set of methods and
a better formatting support - instead of the usual way of coloring `string`s
with embedded 4-byte escape sequences, it stores meta information about color
for each character.
With custom text types comes a new way to define color, *colored strings*.
Just as an example of one:
"This is a string with {\$red red}, {rgb(0,255,0) green} and {#0000ff blue}
colors! There is also {\$pink pink with {\$gold embedded gold} color}!".

In the future our custom text types also have a potential to offer a better
Unicode support.

#### Parsing

As a part of the text API, AcediaCore provides convenient parsing tools.
As a simple example, here is a code that parses rgb color definition into 3
integer components:

```unrealscript
local Parser parser;
local int redComponent, greenComponent, blueComponent;
...
parser = _.text.ParseS("rgb(0,255,0)");
parser.Match(P("rgb("), SCASE_INSENSITIVE)
    .MInteger(redComponent).Match(P(","))
    .MInteger(greenComponent).Match(P(","))
    .MInteger(blueComponent).Match(P(")"));
```

`P()` here simply creates AcediaCore's `Text` instance from `string`.

### `Signal`s and `Slot`s

The usual way to listen to events in UnrealScript was to use some sort of
listener object: `Mutator` can listen to events like `CheckReplacement()`,
`GameRules` is made to listen to a variety of events like `OnNetDamage()`
or `OnOverridePickupQuery()`.
AcediaCore's `Signal`s and `Slot`s allow to provide mod makers with even simpler
access to certain events. As an example, to listen to `OnNetDamage()` event
[friendly fire fix](https://www.insultplayers.ru/git/dkanus/AcediaFixes/src/branch/master/sources/FixFFHack/FixFFHack_Feature.uc)
simply does `_server.unreal.gameRules.OnNetDamage(self).connect = NetDamage;`
and `_server.unreal.gameRules.OnNetDamage(self).Disconnect();`
to stop listening.
Here `NetDamage` is simply a function with a proper signature.

### Collections

Acedia provides two collection types `ArrayList` for dynamic array and
`HashTable` for... hash tables.
Both of them can store acedia's object values and any simple type values like
`bool`, `byte`, `int`, `float`, `string`, `Vector`
(and this list can be extended further via boxing!).
`ArrayList` simply stores them as an array, by their numeric index, while
`HashTable` stores its values by *keys*, most notably text keys:

```unrealscript
local HashTable table;
table = _.collections.EmptyhashTable();
table.SetInt(P("My cool int!"), 7);
table.SetFloat(P("Just a float..."), 1.25);
Log("Int:" @ table.GetInt(P("My cool int!")));
Log("Float:" @ table.GetFloat(P("Just a float...")));
```

They can even store each other, allowing them together to store anything
that JSON can by using `HashTable` to represent JSON object and
`ArrayList` to represent JSON array.
AcediaCore makes use of that and comes, among other things, with two-way
conversion between its these collections and text JSON representation.
Example of JSON to AcediaCore's collections conversion:

```unrealscript
local HashTable result;
result = _.json.ParseHashTableWith(_.text.ParseString(
    "{\"value\": 7, \"arr\": [11, -39, 5067, true, []]}"));
//  Get int:
Log("Int #1:" @ result.GetArrayList(P("arr")).Get(1)); // Int #1: -39
//  Or directly
Log("Int #2:" @ result.GetIntBy(P("/arr/1"))); // Int #2: -39
```

### Features

Features are server-side replacement for `Mutator`s with more requirements for
them.
Currently they are more annoying to make for a modder, but when done correctly
provide more benefits for the user:

1. Ability to have different configs for different game modes;
2. Ability to serialize their configs into JSON, potentially editable (WIP)
    by users right during the gameplay;
3. Potential ability to swap configs or start/shutdown `Feature`s on the fly.

For now these still need to be manually implemented by modder and AcediaCore
simply provides a common interface through which admins and other modders access
these capabilities, but we have plans to automate implementation of at least
the first two way later down the line.
For now we will settle on providing these capabilities to all mods that we make
with AcediaCore.

### Console output

When sending long messages to client one can encounter an issue with these
messages wrapping to the next line and being displayed on top of the next
message.
AcediaCore introduces `ConsoleWriter` class that can automatically break lines
when they get too long (what is "too long" defined by the config).
Thanks to that, we don't have to think about whether out output gets too big.
`ConsoleWriter` also provides auxiliary methods to make writing into
the console easier.

### [WIP] JSON local and remote databases and AvariceLink

We bring them up last, because they aren't yet complete.
To be precise, AcediaCore right now provides working support for local databases
that can store arbitrary JSON values with following limitations:

* Reading JSON data that is too large can lead to a crash;
* Bit integers (with arbitrary beyond what `int` is capable of) aren't yet able
    to be saved/loaded from it.

We also plan to make use of Acedia's JSON parsing capabilities to allow
interaction with remote JSON database via something called *AvariceLink*.
Work on that has already started (although it was postponed for about a year
due to the need to develop other Acedia's areas) and there is a working
prototype, that is able to overcome some of the UnrealScript's network quirks.
*AvariceLink* itself is supposed to allow a simple JSOPN message exchange with
outside applications.

This is sure to be completed during the duration of this alpha.
