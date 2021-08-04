# Aliases

Aliases are `Text` values that act as human-readable synonyms to some other `Text` values.

Often, when using some console commands, users are forced to type into exact class names of objects in **UnrealScript** (e.g., commands to give someone an M14EBR take form similar to `mutate give KFmod.M14EBRBattleRifle`), but such names can be cumbersome to remember and type.

Aliases solve this problem by allowing players to instead type `mutate give $ebr`, where `$` denotes that following word `ebr` is an alias that will be automatically resolved into `KFmod.M14EBRBattleRifle`.

## Alias names

Alias can be any non-empty `Text`, although for practical reasons it is recommended to use only English ASCII letters, digits and `_` character.

Aliases are case-insensitive, so `EBR`, `Ebr` and `ebr` are all considered the same alias.

## Alias sources

Sources essentially act as aliases databases: matching each alias to some value. They can be used to separate aliases that describe different categories of objects: weapons, zeds, colors, etc..

Inside each source aliases and their values are expected to be in many-to-one relationship: several aliases can mean the same value, but each alias can only mean one value. However, two different sources can each contain the same alias and make it point to different values. This won't cause any problems, since game won't look for color aliases in weapons alias source. So it's important for the game to know what source contains what type of aliases.

In case there are several aliases with the same name in the database, - **Acedia** will warn you about it, but won't actually remove duplicates from your configs, instead simply letting the source use the first it finds.

By default **Acedia** offers 4 different alias sources:

* `WeaponAliasSource` (*AcediaAliases_Weapons.ini*) - source filled with aliases for weapons (by default contains aliases to every vanilla weapon);
* `ColorAliasSource` (*AcediaAliases_Colors.ini*) - source filled with aliases for colors (by default contains a decent amount of pre-defined colors);
* `AliasSource` (*AcediaAliases.ini*) - unused source that can, nevertheless, be utilized by server admins or other packages (by default empty);
* `MockAliasSource` (*AcediaAliases_Tests.ini*) - source that is used for testing whether aliases functionality works correctly, avoid changing it if you intend to run tests for **Acedia**'s functionality.

### [Advanced] Changing meaning of alias sources

Even though some of the above sources have rather specific names, only use of `MockAliasSource` is hardcoded: admins can, in theory, move all aliases into any source they like. They'll just have to tell **Acedia** where to look for them by changing *AcediaSystem.ini*'s section *Acedia.AliasService* to point at appropriate source:

```ini
weaponAliasesSource=Class'Acedia.WeaponAliasSource'
colorAliasesSource=Class'Acedia.ColorAliasSource'
```

Specifically, you can move all aliases to a single source (for example `AliasSource`) and tell **Acedia** to look for weapon and color aliases there:

```ini
weaponAliasesSource=Class'Acedia.AliasSource'
colorAliasesSource=Class'Acedia.AliasSource'
```

## How sources are stored

Alias sources are stored in appropriate *ini*-files in two ways that can be mixed with each other however you like.

### 1. Flat array `record`

First way is to define a set alias-value pairs in section of the alias source. Example from the color alias source:

```ini
[Acedia.ColorAliasSource]
; Pink colors
record=(alias="Pink",value="rgb(255,192,203)")
record=(alias="LightPink",value="rgb(255,182,193)")
record=(alias="HotPink",value="rgb(255,105,180)")
record=(alias="DeepPink",value="rgb(255,20,147)")
record=(alias="PaleVioletRed",value="rgb(219,112,147)")
record=(alias="MediumVioletRed",value="rgb(199,21,133)")
```

If you want several different aliases to point to the same value, just add a record for each of them:

```ini
record=(alias="Pink",value="rgb(255,192,203)")
record=(alias="Punk",value="rgb(255,192,203)")
record=(alias="Bunk",value="rgb(255,192,203)")
```

Just avoid having several records for the same alias in one source.

### 2. Per-object-config

If you need to define several aliases for one value it might be better to use per-object-configuration with named objects: each of them stores an array of aliases, while the corresponding value is recorded as object's name. Example from weapons alias source:

```ini
[KFMod:MP5MMedicGun WeaponAliases]
Alias="MP5M"
Alias="MP5"
Alias="MP"
Alias="M5"
```

Here aliases are defined in every line that starts with `Alias=`. Their value `KFMod:MP5MMedicGun` is defined as a first part of the config section (`:` is going to be translated to `.`, more on that below) and the second part `WeaponAliases` indicates that this is a record for `WeaponAliasSource`.

Each source has it's own identification for per-object-config records:

* For `WeaponAliasSource` it is `WeaponAliases`;
* For `ColorAliasSource` it is `ColorAliases`;
* For `MockAliasSource` it is `MockAliases`;
* For `AliasSource` it is just `Aliases`.

#### Limitations of the per-object-config

Because alias' value must be a part of the *ini*-file section there are certain limitations imposed on what that value can be (for example having `.` or `]` inside value's name will confuse **Unreal Engine**'s config parser, so you can't use them). There is not official, complete list of forbidden characters, but it is suggested you keep them limited to sequence of letters, numbers and `_` character.

If you do need to store some weird string as a value, - first test that it does load correctly and, if not, use the first way to define it's aliases.

But `.` being a forbidden symbol is too harsh of a limitation, since we mainly want to store class names via per-object-configs. Because of that any alias values defined the second way will load `:` as `.` from a config. This change allows us to define classes as values at the cost of preventing the use of `:`.

## [Technical] Using aliases in the code

To use built-in alias sources for weapons and colors Acedia provides `ResolveWeapon()` and `ResolveColor()` methods for converting aliases into corresponding values:

```unrealscript
local Text alias, resolved;
alias = P("Blue");
resolved = _.aliases.ResolveColor(alias);
TEST_ExpectTrue(resolved.Compare(P("rgb(0,0,255)")));
```

If specified alias is not found `Resolve*()` methods will return `none`. This behavior can be changed by specifying optional second parameter (as `true`) to copy passed value, instead of returning `none`:

```unrealscript
local Text alias, resolved;

alias = P("M14Ebr - not a color");
TEST_ExpectNone(_.aliases.ResolveColor(alias));
resolved = _.aliases.ResolveColor(alias, true);
TEST_ExpectTrue(resolved.Compare(alias));
TEST_ExpectTrue(resolved != alias);
```

If you need to use any other alias source, you can use `GetCustomSource()` to get it's reference and then use `Resolve()` that reference provides.

## [Technical] Defining new alias sources

If you are making a module using **Acedia** and want to add another alias source you simply need to decide on the names of your:

* Alias source (suppose it's `NewSource`);
* Helper class for second way (*per-object-config*) of defining aliases (suppose it's `NewAliases`)
* Config file, where their data will be stored (suppose it's `MyNewAliases.ini`);

then create two classes, like that:

```java
class NewSource extends AliasSource
    config(MyNewAliases);

defaultproperties
{
    configName = "MyNewAliases"
    aliasesClass = class'NewAliases'
}
```

```java
class NewAliases extends Aliases
    perObjectConfig
    config(MyNewAliases);

defaultproperties
{
    sourceClass = class'NewSource'
}
```

and put them in your manifest.

For more examples check out source code for `ColorAliasSource`, `WeaponAliasSource`, `MockAliasSource`.
