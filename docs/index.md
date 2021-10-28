# Acedia for mod making

This document describes Acedia from the mod maker's perspective:
how to use it to create new mods and how it works internally.
It consists of a brief overview of how different components fit together and
then somewhat detailed look at each of them.

This document is not a reference documentation that lists and describes
every single class and method.
Unfortunately, such a document does not exist right now.
The closest substitute for it would be Acedia's source code - most of
the methods and classes are given brief descriptions in the comments.
They might somewhat lack in quality, since having a peer review for them
would not have been viable, but that is all we can offer.
Any corrections to them are always welcome.

We assume that our audience is at least familiar with UnrealScript and we cannot
recommend using it to people new to the modding anyway:
Acedia's API is not stable enough and has certain quirks that can lead to nasty,
hard-to-catch bugs.

## What the hell is all of this?

Acedia 0.1 was a small mutator that fixed game-breaking bugs and what Acedia is
now might seem like a huge departure from that.
But this development was more or less planned even before version 0.1 release.
In particular, Acedia 0.1 had already included a `Feature` class that was used
to pick what bug fixes should be enabled.
It would have been an overkill if bug fixing was all Acedia would ever do and
now `Feature` is one of the Acedia's main... features, that is supposed to take
the role of the `Mutator` class.

What Acedia was before is now broken into three different packages:

* AcediaCore - package that defines base classes, required for other
Acedia packages to work correctly;
* Acedia - launcher that is supposed to load both native `Mutator`s and
Acedia's `Feature`s;
* AcediaFixes - all the bug fixing `Feature`s were moved here.

The topic of this document is only AcediaCore - a base class library.

## Getting started

First of all, go read about [safety rules](./safety.md).
They make a good introduction and will warn you about otherwise very likely
mistakes that could lead to rather nasty consequences.

After you've familiarized yourself with safety rules, you can skip to reading
about any topic of interest, but we strongly recommend that you first read up on

the fundamental topics:
[what is API](./api.md),
at least non-advanced topics of [Acedia's objects / actors](./objects.md)
and about [signal / slot system](./events.md).

| Topics        | Documentation |
| ------------- | ------------- |
| `Text`, `MutableText`, 3 types of `string`s and json support | [Link](./API/text.md) |
| Collections, `DynamicArray`, `AssociativeArray` | [Link](./API/collections.md) |
| Low-level UnrealScript functions and events | [Link](./API/unreal.md) |
