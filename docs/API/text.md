# Text support

Acedia provides its own `Text` / `MutableText` classes for working with text
that are supposed to replace `string` variables as much as possible.

Main reasons to forgo `string` in favor of custom text types are:

1. `string` does not allow cheap access to either individual characters or
    codepoints, which makes computing `string`'s hash too expensive;
2. Expanding `string`'s functionality without introducing new types would
    require (for many cases) to disassemble it into codepoints and then to
    assemble it back for each transformation;
3. Established way of defining characters' color for `string`s is inconvenient
    to work with.

These issues can be resolved with our new text types: `Text` and `MutableText`,
whose only difference is their mutability.

> **NOTE:**
> `Text` and `MutableText` aren't yet in their finished state:
> using them is rather clunky compared to native `string`s and both their
> interface and implementation can be improved. While they already provide some
> important benefits, Acedia's insistence on replacing `string` with `Text` is
> more motivated by its supposed future, rather than current, state.

## `string`

Even if `Text`/`MutableText` are supposed to replace `string` variables, they
still have to be used to either produce `Text`/`MutableText` instances or
to store their values in config files.
This means we have to cover how Acedia deals with `string`s.

### Colored vs plain strings

**Colored strings** are normal UnrealScript `string`s that can contain
4-byte color changing sequences. Whenever some Acedia function takes
a *colored string* these color changing sequences are converted into formatting
information about color of its characters and are not treated
as separate symbols.

> If you are unaware, 4-byte color changing sequences are defined as
> `<0x1b><red_byte><green_byte><blue_byte>` and they allow to color text that is
> being displayed by several native UnrealScript functions.
> For example, `string` that is defined as
> `"One word is colored" @ Chr(0x1b) $ Chr(1) $ Chr(255) $ Chr(1) $ "green"`
> will be output in game's console with its last word colored green.
> Red and blue bytes are taken as `1` instead of `0` because putting zero
> inside break the `string`. `10` is another value that leads to unexpected
> results and should be avoided.

**Plain strings** are `string`s for which all contents are treated as their own
symbols.
If you pass a `string` with 4-byte color changing sequence to some method as
a *plain string*, these 4 bytes will also be treated as characters and
no color information will be extracted as a result.

Plain strings are generally handled faster than colored strings.

### Formatted strings

Formatted `string`s are Acedia's addition and allow to define color information
in a more human-readable way than *colored strings*.

To mark some part of a `string` to have a particular color you need to enclose
it into curly braces `{}`, specify color right after the opening brace
(without any spacing), then, after a single whitespace, must follow
the colored content.
For example, `"Each of these will be colored appropriately: {#ff0000 red}, {#00ff00 green}, {#0000ff blue}!"`
will correspond to a line
`Each of these will be colored appropriately: red, green, blue!`
and only three words representing colors will have any color defined for them.

Color can be specified not only in hex format, but in also in one of
the more readable ways: `rgb(255,0,0)`, `rgb(r=0,G=255,b=255)`,
`rgba(r=45,g=167,b=32,a=200)`.
Or even using color aliases:
`"Each of these will be colored appropriately: {$red red}, {$green green}, {$blue blue}!"`.

These formatting blocks can also be folded into each other:
`"Here {$purple is mostly purple, but {$red some parts} are {$yellow different} color}."`
with an arbitrary depth.

### Conversion

Various types of `string`s can be converted between each other by using
`Text` class, but do note that *formatted strings* can contain more information
than *colored strings* (since latter cannot simply close the colored segment)
and both of them can contain more information than *plain strings*, so
such conversion can lead to information loss.
Examples of conversion:

```unrealscript
local Text auxiliary;
auxiliary = _.text.FromFormattedString("{$gold Hello}, {$crimson world}!");
// Produces a string colored with 4-byte codes, a native way for UnrealScript
auxiliary.ToColoredString();
// Strings all color and produces "Hello, world!"
auxiliary.ToString();
// Don't forget the cleanup!
_.memory.Free(auxiliary);
```

## `Character`

`Character` describes a single symbol of a string and is a smallest text element
that can be returned from a `string` by Acedia's methods.
It contains data about what symbol it represents and what color it has.
`Character` can also be considered invalid, which means that it does not
represent any valid symbol. Validity can be checked with
`_.text.IsValidCharacter()` method.

`Character` is defined as a structure with public fields
(necessary for the implementation), but you should not access them directly
if you wish for your code to stay compatible with future versions of Acedia.

### `Formatting`

Formatting describes how character should be displayed, which currently
corresponds to simply it's color (or the lack of it).
Formatting of a character can be accessed through
`_.text.GetCharacterFormatting()` method and changed
with `_.text.SetFormatting()`.

It is a structure that contains two public fields, which can be freely accessed
(unlike `Character`'s fields):

1. `isColored`: defines whether `Character` is even colored.
2. `color`: color of the `Character`. Only used if `isColored == true`.

## `Text` and `MutableText`

`Text` is an `AcediaObject` that must be appropriately allocated
(also deallocated) and is used by Acedia as substitute for a `string`.
It's contents are immutable: you can expect that they will not change if you
pass a `Text` as an argument to some method, although the whole object can
be deallocated.
`MutableText` is a child class of a `Text` that can change its own contents.

To create either of them you can use `TextAPI` methods:
`_.text.Empty()` to create empty mutable text,
`_.text.FromString()` / `_.text.FromStringM()` to create immutable/mutable
text variants from a plain `string` and their analogues
`_.text.FromColoredString()` / `_.text.FromColoredStringM()` /
`_.text.FromFormattedString()` / `_.text.FromFormattedStringM()`
for colored and formatted `string`s.

You can also get a `string` back by calling either of
`self.ToString()` / `self.ToColoredString()` / `self.ToFormattedString()`
methods.

To duplicate `Text` / `MutableText` themselves you can use `Copy()`
for immutable copies and `MutableCopy()` for mutable ones.

## Defining `Text` / `MutableText` constants

The major drawback of `Text` is how inconvenient it is to use it, compared to
simple string literals. It needs to be defined, allocated, used and
then deallocated:

```unrealscript
local Text message;
message = _.text.FromString("Just some message to y'all!");
_.console.ForAll().WriteLine(message)
    .FreeSelf();    //  Freeing console writer
message.FreeSelf(); //  Freeing message
```

which can lead to some boilerplate code. Unfortunately, at this moment not much
can be done about this boilerplate. An ideal way to work with text literals
right now is to create `Text` instances with all the necessary text constants on
initialization and then use them:

```unrealscript
class SomeClass extends AcediaObject;

var Text MESSAGE, SPECIAL;

protected function StaticConstructor()
{
    default.MESSAGE = _.text.FromString("Just some message to y'all!");
    default.SPECIAL = _.text.FromString("Only for special occasions!");
}

public final function DoSend()
{
    _.console.ForAll().WriteLine(MESSAGE).FreeSelf();
}

public final function DoSendSpecial()
{
    _.console.ForAll().WriteLine(SPECIAL).FreeSelf();
}
```

Acedia also pre-defines `stringConstants` array that will be automatically
converted into an array of `Text`s that can later be accessed by their indices
through the `T()` method:

```unrealscript
class SomeClass extends AcediaObject;

var int TMESSAGE, TSPECIAL;

public final function DoSend()
{
    _.console.ForAll().WriteLine(T(TMESSAGE)).FreeSelf();
}

public final function DoSendSpecial()
{
    _.console.ForAll().WriteLine(T(TSPECIAL)).FreeSelf();
}

defaultproperties
{
    TMESSAGE = 0
    stringConstants(0) = "Just some message to y'all!"
    TSPECIAL = 1
    stringConstants(1) = "Only for special occasions!"
}
```

This way of doing things is a bit more cumbersome, but is also safer in
the sense that `T()` will automatically allocate a new `Text` instance should
someone deallocate previous one:

```unrealscript
local Text oldOne, newOne;
oldOne = T(TMESSAGE);
//  `T()` returns the same instance of `Text`
TEST_ExpectTrue(oldOne == T(TMESSAGE))
//  Until we deallocate it...
oldOne.FreeSelf();
//  ...then it creates and returns newly allocated `Text` instance
newOne = T(TMESSAGE);
TEST_ExpectTrue(newOne.IsAllocated());

//  This assertion *might* not actually be correct, since `newOne` can be
//  just an `oldOne`, reallocated from the object pool.
//  TEST_ExpectFalse(oldOne == newOne);
```

### An easier way

While you should ideally define `Text` constants, setting them up can
get annoying.
To alleviate this issue Acedia provides three more methods for quickly
converting `string`s into `Text`: `P()` for plain `string`s,
`C()` for colored `string`s and `F()` for formatted `string`s.
With them out `SomeClass` can be rewritten as:

```unrealscript
class SomeClass extends AcediaObject;

public final function DoSend()
{
    _.console.ForAll().WriteLine(P("Just some message to y'all!")).FreeSelf();
}

public final function DoSendSpecial()
{
    _.console.ForAll().WriteLine(P("Only for special occasions!")).FreeSelf();
}
```

They do not endlessly create `Text` instances, since they cache and reuse
the ones they return for the same `string`:

```unrealscript
local Text firstInstance;
firstInstance = F("{$purple Some} {$red colored} {$yellow text}.");
//  `F()` returns the same instance for the same `string`
TEST_ExpectTrue(    firstInstance
                ==  F("{$purple Some} {$red colored} {$yellow text}."));
//  But not for different one
TEST_ExpectFalse(firstInstance ==  F("Some other string"));
//  Still the same
TEST_ExpectTrue(    firstInstance
                ==  F("{$purple Some} {$red colored} {$yellow text}."));
```

Ideally one would at some point replace these calls with pre-defined constants,
but if you're using only a small amount of literals in your class,
then relying on them should be fine. However avoid using them for
an arbitrarily large amounts of `string`s, since as cache's size grows,
these methods will become increasingly less efficient:

```unrealscript
//  The more you call this method with different arguments, the worse
//  performance gets since `C()` has to look `string`s up in
//  larger and larger cache.
public function DisplayIt(string message)
{
    //  This is bad, don't do this
    _.console.ForAll().WriteLine(C(message)).FreeSelf();
}
```

## Parsing

Acedia provides some parsing functionality through a `Parser` class:
it must first be initialized by either `Initialize()` or `InitializeS()` method
(the only difference whether they take `Text` or `string` as a parameter)
and then it can parse passed contents by consuming its symbols from
the beginning to the end.

For that it provides a set of *matcher methods* that try to read certain values
from the input.
For example, following can parse a color, defined in a hex format:

```unrealscript
local Parser parser;
local int redComponent, greenComponent, blueComponent;
parser = _.text.ParseString("#23a405");
parser.MatchS("#").MUnsignedInteger(redComponent, 16, 2)
    .MUnsignedInteger(greenComponent, 16, 2)
    .MUnsignedInteger(blueComponent, 16, 2);
//  These should be correct values
TEST_ExpectTrue(redComponent == 35);
TEST_ExpectTrue(greenComponent == 164);
TEST_ExpectTrue(blueComponent == 5);
```

Here `MatchS()` matches an exact `string` constant and `MUnsignedInteger()`
matches an unsigned number (with base `16`) of length `2`, recording parsed
value into its first argument.

Another example of parsing a color in format `rgb(123, 135, 2)`:

```unrealscript
local Parser parser;
local int redComponent, greenComponent, blueComponent;
parser = _.text.ParseString("RGB( 123,135 , 2)");
parser.MatchS("rgb(", SCASE_INSENSITIVE).Skip()
    .MInteger(redComponent).Skip().MatchS(",").Skip()
    .MInteger(greenComponent).Skip().MatchS(",").Skip()
    .MInteger(blueComponent).Skip().MatchS(")");
//  These should be correct values
TEST_ExpectTrue(redComponent == 123);
TEST_ExpectTrue(greenComponent == 135);
TEST_ExpectTrue(blueComponent == 2);
TEST_ExpectTrue(parser.Ok());
```

where `MInteger()` matches any decimal integer and then records that integer
into the first argument. `Skip()` matches a sequence of whitespaces of
an arbitrary length, adding some these calls allows this code to parse colors
defined with spacings between numbers and other characters like
`rgb(  12, 13 , 107 )`. `Ok()` method simply confirms that all matching calls
so far have succeeded.

If you are unsure in which format the color was defined, then you can use
`Parser`'s methods for remembering/restoring a successful state:
you can first call `parser.Confirm()` to record that all the parsing so far
was successful and should not be discarded, then try to parse hex color.
After that:

* If parsing was successful, - `parser.Ok()` check will return `true` and
    you can call `parser.Confirm()` again to mark this new state as one that
    shouldn't be discarded.
* Otherwise you can call `parser.R()` to reset your `parser` to the state it
    was at the last `parser.Confirm()` call
    (or the initial state if no `parser.Confirm()` calls were made)
    and try parsing the color in some other way.

```unrealscript
local Parser parser;
local int redComponent, greenComponent, blueComponent;
...
//  Suppose we've successfully parsed something and
//  need to parse color in one of the two forms next,
//  so we remember the current state
parser.Confirm();   //  This won't do anything if `parser` has already failed
//  Try parsing color in it's rgb-form;
//  It's not a major issue to have this many calls before checking for success,
//  since once one of them has failed - others won't even try to do anything.
parser.MatchS("rgb(", SCASE_INSENSITIVE).Skip()
    .MInteger(redComponent).Skip().MatchS(",").Skip()
    .MInteger(greenComponent).Skip().MatchS(",").Skip()
    .MInteger(blueComponent).Skip().MatchS(")");
//  If we've failed - try hex representation
if (!parser.Ok())
{
    parser.R().MatchS("#")
        .MUnsignedInteger(redComponent, 16, 2)
        .MUnsignedInteger(greenComponent, 16, 2)
        .MUnsignedInteger(blueComponent, 16, 2);
}
//  It's fine to call `Confirm()` without checking for success,
//  since it won't do anything for a parser in a failed state
parser.Confirm();
```

>You can store even more different parser states with
`GetCurrentState()` / `RestoreState()` methods.
In fact, these are the ones used inside a lot of Acedia's methods to avoid
changing main `Parser`'s state that user can rely on.

For more details and examples see the source code of `Parser.uc` or
any Acedia source code that uses `Parser`s.

## JSON support

> **NOTE:**
> This section is closely linked with [Collections](../API/Collections.md).

Acedia's text capabilities also provide limited JSON support.
That is, Acedia can display some of it's types as JSON and parse any valid JSON
into its types/collections, but it does not guarantee verification of whether
parsed JSON is valid and can also accept some technically invalid JSON.

Main methods for these tasks are `_.json.Print()`/`_.json.PrettyPrint()` and
`_.json.ParseWith()`, but there are some more type-specialized methods as well.
Here are the current rules of conversion from JSON to Acedia's types via
`_.json.ParseWith()`:

1. Null values will be returned as `none`;
2. Number values will be return as an `IntBox`/`IntRef` if they consist
    of only digits (and optionally a sign) and `FloatBox`/`FloatRef`
    otherwise. Choice between box and ref is made based on
    `parseAsMutable` parameter (boxes are immutable, refs are mutable);
3. String values will be parsed as `Text`/`MutableText`, based on
    `parseAsMutable` parameter;
4. Array values will be parsed as a `DynamicArray`, it's items parsed
    according to these rules (`parseAsMutable` parameter is propagated).
5. Object values will be parsed as a `AssociativeArray`, it's items
    parsed according to these rules (`parseAsMutable` parameter is
    propagated) and recorded under the keys parsed into `Text`.

And printing with `_.json.Print()`/`_.json.PrettyPrint()` follows
symmetrical rules:

1. `none` is printed into "null";
2. Boolean types (`BoolBox`/`BoolRef`) are printed into JSON bool value;
3. Integer (`IntBox`/`IntRef`) and float (`FloatBox`/`FloatRef`) types
    are printed into JSON number value;
4. `Text` and `MutableText` are printed into JSON string value;
5. `DynamicArray` is printed into JSON array with `Print()` method
    applied to each of its items. If some of them have not printable
    types - "none" will be used for them as a replacement.
6. `AssociativeArray` is printed into JSON object with `Print()` method
    applied to each of it's items. Only items with `Text` keys are
    printed, the rest is omitted. If some of them have not printable
    types - "none" will be used for them as a replacement.

The difference between `_.json.Print()` and `_.json.PrettyPrint()` is that
`_.json.Print()` prints out a minimal, compact json, while
`_.json.PrettyPrint()` prints a more human-readable JSON with indentation and
color highlights.
