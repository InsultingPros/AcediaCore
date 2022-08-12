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

AcediaCore is currently in the alpha with a goal to expose it to slightly wider
circle of people, while finishing some yet incomplete features.

So far there's very little documentation to go by:

* For reference documentation you can check the source code: it is rather
    heavily documented;
* For basic usage examples you can refer to
    [this document](https://insultplayers.ru/killingfloor/acedia/howto/);
* For information about how it works internally and justifications for why
    things were made the way they are, read
    [this document](https://insultplayers.ru/killingfloor/acedia/docs/).

## Why should I be interested in it?

Currently AcediaCore doesn't offer much in terms of gameplay-altering features,
focusing mostly on utility APIs:

* **Aliases** Write `$ak47` instead of `KFMod.AK47AssaultRifle`;
* **Commands** Don't worry about parsing your `mutate` commands' input,
    AcediaCore will handle it for you;
* **Text** Slower, but more functional text types. Define colored `string`s like
    this:
    `This is a string with {\$red red}, {rgb(0,255,0) green} and {#0000ff blue} colors! There is also {\$pink pink with {\$gold embedded gold} color}!`;
* **Parsing** Additional tools for making parsing whatever you want easier;
* **Signals and Slots** Want to handle user's `mutate` commands?
    Just do this:
    `_server.unreal.mutator.OnMutate(self).connect = HandleMutate;`;
* **Collections** Generic collections that can be converted into JSON and back;
* **Features** More of a pain in the ass to make than `Mutator`s, but should
    provide better UX (I hope);
* **Console output** No more ugly-wrapped lines from `ClientMessage`,
    AcediaCore's `ConsoleWriter` will auto-wrap long lines for you;
* **Local databases** Working local databases that can store arbitrary
    JSON values, still require a bit of polish;
* **Unit testing** Built-in support for unit testing of things that can be
    tested within one tick;
* **[WIP] External applications** Exchange JSON messages with external
    applications, including remote JSON databases. Passed proof-of-concept
    stage, but still unfinished;

## Installation

There is no need for installation besides copying the mod file into your
server's `System/` directory, but to actually make use of AcediaCore you need
to install
[AcediaLauncher](https://www.insultplayers.ru/git/AcediaFramework/AcediaLauncher).
There is a way to use AcediaCore without launcher or any other package, but we
will document it later, after polishing a few things.

## Related projects

Some of the projects that are still in development:

* [AcediaLauncher](https://www.insultplayers.ru/git/AcediaFramework/AcediaLauncher)
    - for starting up AcediaCore and packages that depend on it;
* [AcediaFixes](https://www.insultplayers.ru/git/AcediaFramework/AcediaFixes)
    - game bug fixes have moved into this package;
* [Futility](https://www.insultplayers.ru/git/AcediaFramework/Futility)
    - a package that aims to make administration and mod testing easier through
    Admin-Plus-esque commands and non-gameplay related configuration features.
