# Console

Default Killing Floor console output is ill-fit for printing long text messages due to it's automatic line breaking of long enough messages: it breaks formatting and can lead to an ugly text overlapping. To fix this `ConsoleAPI` breaks up user's output into lines by itself, before game does.

We are not 100% sure how Killing Floor decides when to break the line, but it seems to calculate how much text can actually fit in a certain area on screen. There are two issues:

1. We do not know for sure what this limit value is. Even if we knew how to compute it, we cannot do that in server mode, since it depends on a screen resolution and font, which can vary for different players.
2. Even invisible characters, such as color change sequences, that do not take any space on the screen, contribute towards that limit. So for a heavily colored text we will have to break line much sooner than for the plain text.

Both issues are solved by introducing two limits:

* Total character limit will be a hard limit on a character amount in a line (including hidden ones used for color change sequences) that will be used to prevent Killing Floor's native line breaks.
* Visible character limit will be a lower limit on amount of actually visible character. It introduction basically reserves some space that can be used only for color change sequences. Without this limit lines with colored lines will appear to be shorter that mono-colored ones. Visible limit will help to alleviate this problem.

These limits depend on resolution and even with access to clients it's hard to determine their optimal values precisely. Acedia provides default values for these limits that should work for most people, which can be configured through `AcediaSystem.ini` file (`ConsoleAPI` section).

## Basic usage

Most of your interactions with `ConsoleAPI` will be through `ConsoleWriter` object that provides convenient facade to `ConsoleBuffer` (which does the actual work of breaking user messages into lines).

It provides several useful methods for outputting `Text` console messages, all properly using it's color information:

|Method|Short description|
|------|-----------------|
|`WriteLine()` |Outputs all the contents of `Text` in the console, breaking a line.|
|`Write()`     |Writes contents of provided `Text` into the output buffer, without actually outputting it. If you chain several `Write()` calls - all of their content will be put together. To actually display them you'll need to use `Flush()` method. If accumulated buffer can't fit into a single line - it will be output as several lines, each starting with a sequence designating a line wrapping: "\| ".|
|`WriteBlock()`|Acts as `WriteLine()`, but appends additional indentation in front of all output.|
|`Say()`       |Acts as `WriteLine()`, but appends player's name in front every message, like regular chat messages.|

Simplest way to access it is from `APlayer` instance: `player.Console()`. You can also get `ConsoleWriter` that outputs messages to all players at the same time with `_.console.ForAll()`.

## Configuration

Total and visible character limits can be configured with `GetVisibleLineLength()`/`SetVisibleLineLength()`/`GetTotalLineLength()`/`SetTotalLineLength()` defined in both `ConsoleAPI` and `ConsoleWriter`. `ConsoleAPI`'s methods change default setting s for all future `CnosoleWriter`s and `ConsoleWriter`'s only change it's particular settings.

Additionally default text color can be managed with `GetColor()`/`SetColor()` methods.
