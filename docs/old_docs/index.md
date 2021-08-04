# Acedia Frameworks

Acedia Frameworks (later just Acedia) is a platform for modding Killing Floor, which includes both creating new mods and managing them on servers. It's main goals are to provide...

1. ...APIs that improve and standardize many recurring tasks like text coloring, storage and replication of arbitrary data (i.e. dynamic/associative arrays, player data), user commands, GUI and many more;
2. ...abstraction layer, allowing it to potentially switch "backend" from vanilla game to server perks or even something else;
3. ...out-of-the-box rich built-in capabilities to customize the game by changing settings;
4. ...simple, but powerful interface for managing and configuring Acedia on servers.

>**NOTE:** Although some note on server administration will be made, when relevant, this documentation is aimed for modders who want to use Acedia to make their mods.

## Introduction

First of all, note that much of Acedia's documentation is located in the source code itself: comments to classes and their methods. This documentation is meant as a more of the overview, it is supposed to provide necessary details, but expecting to duplicate full information between sources and these documents is unreasonable.

You can use this document to understand Acedia's capabilities and how everything fits together, but if you need a more detailed descriptions of Acedia's classes - you'll have to read documentation in source files.

### Global API access

Adding new global methods in UnrealScript isn't too convenient. One is forced to either use static methods through a cumbersome syntax: `class'MyAwesomeClass'.static.MyAwesomMethod(...)` or somehow fetch an instance of an object where desired functionality is defined.

Acedia doesn't ultimately fix this issue for everybody, but it addresses it for Acedia's own methods: any object in Acedia has a `_` variable defined inside it, which provides access to *API*s, i.e. objects that provide new functionality like so `_.text.ParseString("give@ $ebr")` or `_.color.RGB(132, 45, 12)`.

Concrete APIs are described below.

### Acedia and object management

Before tackling any other topic, it's important to understand that Acedia makes a much heavier use of `Object`s than most Killing Floor mods. This brings certain advantages, like allowing us to introduce collections capable of storing items of different classes, but also introduces an inconvenience of having to deallocate no longer used `Object`s.

[Read more](introduction/ObjectsActors.md)

### Acedia and text

Related to that is the question of `string`s. Acedia provides it's own type `Text` for storing textual data and it is intended to replace `string` almost everywhere. Main reason is that `string`s are monolithic and their individual characters are hard to access, which complicates implementing custom methods for working with them.

[Read more](introduction/Text.md)

## API details

### Aliases

Acedia provides mechanism to give certain values aliases: alternative names that are easier for humans to write and remember, making it easier to specify, for example, weapon classes.

[Read more](API/Aliases.md)

### Collections

Acedia provides dynamic and associative array collections capable of storing `AcediaObject`s. Thanks to boxing we can store essentially any type of variable inside them.

[Read more](API/Collections.md)

### Commands

Acedia provides a centralized way to define user command that can be invoked by players through either chat or console. Examples are `dosh m14pro 500` to give player named 'm14pro' 500 dosh or `nick m14pro m14elitist` to change his nickname to 'm14elitist'. They have a variety of advantages compared to simple "mutate" commands, providing modders with a powerful tool for creating new commands.

[Read more](API/Commands.md)

### Console

Default Killing Floor console output is ill-fit for printing long text messages due to it's automatic line breaking of long enough messages. Acedia provides `ConsoleAPI` that resolves this issue in a nice and easy-to-use way.

[Read more](API/Console.md)

### Colors

Acedia provides some convenience methods and constant that have to do with colors:

[Read more](API/Colors.md)
