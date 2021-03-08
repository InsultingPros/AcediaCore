# Colors

Acedia provides a variety of color constants and methods for working with color, since it was necessary to set up proper `Text` formatting.

## Constants

Acedia provides over a hundred color constant named after their respective colors like `red`, `green` or `yellow` to more exotic `Maroon`, `Gainsboro` or `Eigengrau`. The other set of constants are the system colors used by Acedia for a particular purpose, like `TextDefault` for regular text color, `TypeBoolean` for coloring boolean constants or `TextPositive` for marking words that a related to some positive event ("dosh" command generates messages "You've gotten <amount> of dosh!" in which the word "gotten" in displayed with positive color, by default green).

All of them can be changed using `AcediaSystem.ini` config.

Do note, however, that while by default sets of colors in `ColorAPI` and in `AcediaAliases_Color.ini` coincide, they are actually independent and used in different context. Constants defined in `AcediaSystem.ini` are used by UnrealScript code while aliases usually used for parsing players' input and your config files.

## Defining colors

Whenever Acedia asks you to specify color as a text (whether it is to color formatted text or just a parameter in a config), it can understand following several formats of color representaion:

1. Hex color definitions in format of `#ffc0cb`;
2. RGB color definitions that look like either `rgb(255,192,203)` or `rgb(r=255,g=192,b=203)`;
3. RGBA color definitions that look like either `rgb(255,192,203,13)` or `rgb(r=255,g=192,b=203,a=13)`;
4. Alias color definitions that **Acedia** looks up from color-specific alias source and look like any other alias reference: `$pink`.

You should be able to use any form you like while working with **Acedia**.

## [Technical] Color fixing

Killing floor's standard methods of rendering colored `string`s make use of inserting 4-byte sequence into them: first bytes denotes the start of the sequence, 3 following bytes denote rgb color components. Unfortunately these methods also have issues with rendering `string`s if you specify certain values (`0` and `10`) as red-green-blue color components.

You can freely use colors with these components, since **Acedia** automatically should fix them for you (by replacing them with indistinguishably close, but valid color) whenever it matters.
