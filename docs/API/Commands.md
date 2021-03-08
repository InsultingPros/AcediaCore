# Commands

Acedia provides a centralized way to define user command that can be invoked by players through either chat or console. Examples are `dosh m14pro 500` to give player named 'm14pro' 500 dosh or `nick m14pro m14elitist` to change his nickname to 'm14elitist'.

## Using them and advantages over "mutate"

How is Acedia's command system better than a regular "mutate/admin" commands that are used in most mutators? There are several important reasons.

### Multiple input methods

While the most convenient and suggested method is to type commands in chat, starting with (by default) "!" character: `!dosh begger 5`, you can, potentially, teach the game to enter commands from any source that can input/return written text. Including mutate command itself.

### Specifying (multiple) targets

#### Name prefix

If command must target a particular player, Acedia's commands provide unified and simple mechanism to specify the target. Consider the example above: `dosh m14pro 500`. Here we specify targeted player by writing his full name right after *dosh* command. The obvious improvement (already used in AdminPlus) is to allow to specify only beginning of his name: "m14" or even "m" - as long as no one else's name starts with the same prefix - only that player will be affected.

What if several players match the same prefix? Then all of them will be affected by this command equally - Acedia will simply run it several times, once for each player.

Even more - one can list several players with different names in the same command like so: `dosh[m14pro, xbowScrub] 500` and 500 dosh will be given to all players whos name starts with 'm14pro' or 'xbowScrub'!

> **NOTE:**
> Lack of space between "dosh" and "[" in `dosh[m14pro, xbowScrub] 500` is **not** a mistake. You only have to specify the space before writing player's nick name, while special characters that allow you to specify groups of players can follow immediately after it.

#### Player key

What if several players are named identically or have weird names that are hard to type? Then you can use key selectors that allow you to specify player's number instead of their nickname: `dosh #2 500` (or `dosh#2 500`) to give dosh to the player with key `2`. You can get players' keys with a built-in "pl" command.

#### Macros

There are even more ways to specify target players: macros that start with a "@". For example "@self" or even simply "@" mean the caller player himself, so this command `dosh@ 500` will give you 500 dosh. There are also macros "@admin" to target all admins and "@all" to target everyone.

#### Combinations

All of the ways above can be combined together: command `dosh[@, #3, joe] -50` will take 50 dosh from the caller player, player with key 3 and player "joe".

You can also *negate* any of these selectors: `dosh[@all, !joe] 100` will give 100 dosh to everyone but "joe" guy. The way it works is: selectors are applied in order, either adding or removing players. In `dosh[@all, !joe] 100` example we first added all players to the target set, then excluded "joe", but if we specify, say, either `dosh[@all, !joe, @all] 100` or `dosh[@all, !joe, joe] 100`, then "joe " will be added again and command will target everybody.

Specifying negated selector first: `dosh !joe 500` (again you can also omit first whitespace: `dosh!joe 500`) will first automatically add all players, only then excluding "joe". Another example: `kick!@` will attempt to kick every player except for the one calling this command.

### Options

Acedia's commands support the concept of options where aside from simply specifying parameters in order you can also specify optional command keys. For example, when "dosh" command gives someone money, it also makes chat announcement to that player that they have received money. However the command caller can avoid that from happening by additionally specifying `-s` or `--silent` in any place of the command call: `dosh@ 500 -s`, `dosh@ 500 --silent`, `dosh@ -s 500` or `dosh@ --silent 500` all do the same thing.

Options can also have parameters of their own. For example, "dosh" command has another option `-M`/`--max` that prevents players from having more than that amount of money after the command call. So if you want to give every player 500 dosh, but in such a way that no one would have more than a 1000 as a result, you can write: `dosh@all 500 -M 1000` or `dosh@all --max 1000 500`.

### Signature specification

With mutate command, modders must manually parse user input to get command parameters. Acedia, on the other hand, requires modders to instead specify what parameters and of what type must their command take and then automatically parses user input based on that.

For players it means that Acedia is aware what parameters each command takes and can automatically generate help pages based on that information. To access these pages simply use built-in command "help".

#### [Technical] How do I define new command and it's parameters?

Let's consider one of the simple commands "nick" at the moment of writing this document:

```unrealscript
class ACommandNick extends Command;

protected function BuildData(CommandDataBuilder builder)
{
    builder.Name(P("nick")).Summary(P("Changes nickname."));
    builder.RequireTarget();
    builder.ParamRemainder(P("nick"))
}

protected function ExecutedFor(APlayer player, CommandCall result)
{
    player.SetName(Text(result.GetParameters().GetItem(P("nick"))));
}
```

Following that example, to create a new command you have to make a subclass of `Command` class and then overload `BuildData` method, where you can use `CommandDataBuilder` object to define your command:

* `Name()` defines the name of your command.
* `Summary()` should be a short description that can fit into one line - it is going to be displayed when user lists all of the commands.
* `RequireTarget()` should be called if you command can target a player.
* `Describe()` allows to specify more detailed description to the "nick" command.
* `Param*()` calls define actual parameters of a certain type, in order. `ParamRemainder()` is a special kind of parameters that simply dumps all of the remaining input as `Text` into a single parameter. Be careful, if you add more required parameters after that one - you command will not be able to parse any kind of input. It's parameter `P("nick") defines the name of the parameter, as it will be displayed in a help page.

> **NOTE:**
> There are also `Param*List()` method calls for defining lists (or arrays) of values of a certain type.

Then comes `ExecutedFor()` method that will be called whenever command is executed, once for every player (`APlayer`) specified as a target. `CommandCall` parameter will contain data about parsed command: command parameters can be obtained as an `AssociativeArray` of name-value pairs with the `GetParameters()` call as demonstrated here: `result.GetParameters().GetItem(P("nick"))`.

Here is the table of the available parameter types:

|Method for defining parameter|What it parses into|
|--|--|
|`ParamBoolean()`|`BoolBox` containing parsed `bool` value.|
|`ParamBooleanList()`|`DynamicArray` that is guaranteed to contain only parsed `BoolBox`es, listed one after the other, separated by whitespaces.|
|`ParamInteger()`|`IntBox` containing parsed `int` value.|
|`ParamIntegerList()`|`DynamicArray` that is guaranteed to contain only parsed `IntBox`es, listed one after the other, separated by whitespaces.|
|`ParamNumber()`|`FloatBox` containing parsed `float` value.|
|`ParamNumberList()`|`DynamicArray` that is guaranteed to contain only parsed `FloatBox`es, listed one after the other, separated by whitespaces.|
|`ParamText()`|`Text` object, containing either word (character sequence unbroken by whitespaces) or any contents between quotes: "", '' or ``.|
|`ParamTextList()`|`DynamicArray` that is guaranteed to contain parsed `Text`s, listed one after the other, separated by whitespaces.|
|`ParamObject()`|`AssociativeArray` containing parsed JSON object value.|
|`ParamObjectList()`|`DynamicArray` that is guaranteed to contain only a `AssociativeArray`s with parsed JSON object values, listed one after the other.|
|`ParamArray()`|`DynamicArray` containing parsed JSON array value.|
|`ParamArrayList()`|`DynamicArray` that is guaranteed to contain only `DynamicArray`s with parsed JSON array values, listed one after the other.|
|`ParamRemainder()`|`Text` containing the remainder of unparsed user input. Used by the "nick" command to allow to specify nicknames with whitespace characters without enclosing them into quotes.|

> **NOTE:**
> `CommandCall` contains methods to check whether it is in an erroneous state, however, you do not need to check for that since only successful calls make it to the `ExecutedFor()` call.

There is also another method `Executed()` that is executed before any of the `ExecutedFor()` calls. It's main purpose is to contain logic of commands that do not target any players.

##### Options and optional parameters

Let's see how to define options and optional parameters with the following example of "help" command definition:

```unrealscript
builder.Name(P("help"))
    .Summary(P("Detailed information about available commands."));
builder.OptionalParams()
    .ParamTextList(P("commands"))
    .Describe(P("Display information about all specified commands."));
builder.Option(P("list"))
    .Describe(P("Display list of all available commands."));
```

`OptionalParams()` call does not take any arguments itself, but any parameters defined with `Param*()` calls will be considered *optional*: Acedia will not complain if they are missing from the user's input (unlike required parameters). Once `OptionalParams()` call was made, you cannot define more required parameters, since they cannot follow optional ones.

`Option(P("list"))` defines `--list`/`-l` option. Shorter version is generated automatically, but, if you want, you can also specify yours: `Option(P("list"), P("L"))`. Once you have called `Option()` method, you've switched your `CommandDataBuilder` to describing that option instead of the command as a whole and **all further `Param*()` and `Describe()` calls** will affect this option specifically, until you switch to describing another option (or subcommand, more about them below).

To check whether a certain option was specified, you can use `GetOptions()` method in `CommandCall` object to obtain another `AssociativeArray` and then check if it has a record with a key, defined by an option's name. For example, to check if `--list`/`-l` option was specified you can do: `callInfo.GetOptions().HasKey(P("list"))`. If option takes no parameters it will simply store `none` value with that key; if option does take parameters it will store another `AssociativeArray`, same as the one returned by `GetParameters()` method.

##### Sub-commands

To make commands a bit more flexible, Acedia allows them to change a set of parameters they take depending on the first parameter. If none are specified (as is the case for "nick" and "help" commands above), every commands by default uses an empty sub-command: no matter what parameters users gives them, empty sub-command will be invoked.

"dosh" command, on the other hand, has two sub-commands:

* "" - empty one that *adds* dosh to the targeted player.
* "set" - that *sets* their dosh to the specified amount.

When `dosh 500` is invoked - Acedia checks if first parameter "500" fits any sub-command name. Finds that it does not and picks an empty sub-command. However if you type `dosh set 500`, Acedia will match "set" with another sub-command's name and will pick it instead. Every sub-command is listed separately in the help pages.

Let's see how "dosh" command is described in UnrealScript:

```unrealscript
builder.Name(P("dosh")).Summary(P("Changes amount of money."));
builder.RequireTarget();
builder.ParamInteger(P("amount"))
    .Describe(P("Gives (or takes if negative) players a specified <amount>"
        @ "of money."));
builder.SubCommand(P("set"))
    .ParamInteger(P("amount"))
    .Describe(P("Sets player's money to a specified <amount>."));
builder.Option(P("silent"))
    .Describe(P("If specified - players won't receive a notification about"
        @ "obtaining/losing dosh."));
builder.Option(P("min"))
    .ParamInteger(P("minValue"))
    .Describe(F("Players will retain at least this amount of dosh after"
        @ "the command's execution. In case of conflict, overrides"
        @ "'{$TextEmphasis --max}' option. `0` is assumed by default."));
builder.Option(P("max"), P("M"))
    .ParamInteger(P("maxValue"))
    .Describe(F("Players will have at most this amount of dosh after"
        @ "the command's execution. In case of conflict, it is overridden"
        @ "by '{$TextEmphasis --min}' option."));
```

By default, all builder calls afftect the empty sub-command that every command must have, so we describe it with:

```unrealscript
builder.ParamInteger(P("amount"))
    .Describe(P("Gives (or takes if negative) players a specified <amount>"
        @ "of money."));
```

Then we define a new sub-command and, much like with options, switch to now describing it:

```unrealscript
builder.SubCommand(P("set"))
    .ParamInteger(P("amount"))
    .Describe(P("Sets player's money to a specified <amount>."));
```

> **NOTE:**
> Note that is is not necessary to chain method calls like this. Every method simply returns `builder` object and we only group the calls like that for readability. This would give equivalent results:
>
> ```unrealscript
> builder.SubCommand(P("set"));
> builder.ParamInteger(P("amount"));
> builder.Describe(P("Sets player's money to a specified <amount>."));
> ```

> **NOTE 2:**
> `RequireTarget()`, same as `Name()` and `Describe()` affect command as a whole and not a particular sub-command or an option. So it does not matter when you call them.
