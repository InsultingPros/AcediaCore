/**
 *      API that provides functions for working with color.
 *      It has a wide range of pre-defined colors and some functions that
 *  allow to quickly assemble color from rgb(a) values, parse it from
 *  a `Text`/string or load it from an alias.
 *      Copyright 2020-2022 Anton Tarasenko
 *------------------------------------------------------------------------------
 * This file is part of Acedia.
 *
 * Acedia is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License, or
 * (at your option) any later version.
 *
 * Acedia is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Acedia.  If not, see <https://www.gnu.org/licenses/>.
 */
class ColorAPI extends AcediaObject
    dependson(Parser)
    config(AcediaSystem);

/**
 *  Enumeration for ways to represent `Color` as a `string`.
 */
enum ColorDisplayType
{
    //  Hex format; for pink: #ffc0cb
    CLRDISPLAY_HEX,
    //  RGB format; for pink: rgb(255,192,203)
    CLRDISPLAY_RGB,
    //  RGBA format; for opaque pink: rgb(255,192,203,255)
    CLRDISPLAY_RGBA,
    //  RGB format with tags; for pink: rgb(r=255,g=192,b=203)
    CLRDISPLAY_RGB_TAG,
    //  RGBA format with tags; for pink: rgb(r=255,g=192,b=203,a=255)
    CLRDISPLAY_RGBA_TAG,
    //  Stripped RGB format; for pink: 255,192,203
    CLRDISPLAY_RGB_STRIPPED,
    //  Stripped RGBA format; for opaque pink: 255,192,203,255
    CLRDISPLAY_RGBA_STRIPPED
};

//      Some useful predefined color values.
//      They are marked as `config` to allow server admins to mess about with
//  colors if they want to.

//  System colors for displaying text and variables
var public config const Color TextDefault;
var public config const Color TextHeader;
var public config const Color TextSubHeader;
var public config const Color TextSubtle;
var public config const Color TextEmphasis;
var public config const Color TextPositive;
var public config const Color TextNeutral;
var public config const Color TextNegative;
var public config const Color TextOk;
var public config const Color TextWarning;
var public config const Color TextFailure;
var public config const Color TypeNumber;
var public config const Color TypeBoolean;
var public config const Color TypeString;
var public config const Color TypeLiteral;
var public config const Color TypeClass;
//  Colors for displaying JSON values
var public config const Color jPropertyName;
var public config const Color jObjectBraces;
var public config const Color jArrayBraces;
var public config const Color jComma;
var public config const Color jColon;
var public config const Color jNumber;
var public config const Color jBoolean;
var public config const Color jString;
var public config const Color jNull;
//  Pink colors
var public config const Color Pink;
var public config const Color LightPink;
var public config const Color HotPink;
var public config const Color DeepPink;
var public config const Color PaleVioletRed;
var public config const Color MediumVioletRed;
//  Red colors
var public config const Color LightSalmon;
var public config const Color Salmon;
var public config const Color DarkSalmon;
var public config const Color LightCoral;
var public config const Color IndianRed;
var public config const Color Crimson;
var public config const Color Firebrick;
var public config const Color DarkRed;
var public config const Color Red;
//  Orange colors
var public config const Color OrangeRed;
var public config const Color Tomato;
var public config const Color Coral;
var public config const Color DarkOrange;
var public config const Color Orange;
//  Yellow colors
var public config const Color Yellow;
var public config const Color LightYellow;
var public config const Color LemonChiffon;
var public config const Color LightGoldenrodYellow;
var public config const Color PapayaWhip;
var public config const Color Moccasin;
var public config const Color PeachPuff;
var public config const Color PaleGoldenrod;
var public config const Color Khaki;
var public config const Color DarkKhaki;
var public config const Color Gold;
var public config const Color CoolGold;
//  Brown colors
var public config const Color Cornsilk;
var public config const Color BlanchedAlmond;
var public config const Color Bisque;
var public config const Color NavajoWhite;
var public config const Color Wheat;
var public config const Color Burlywood;
var public config const Color TanColor; // `Tan()` already taken by a function
var public config const Color RosyBrown;
var public config const Color SandyBrown;
var public config const Color Goldenrod;
var public config const Color DarkGoldenrod;
var public config const Color Peru;
var public config const Color Chocolate;
var public config const Color SaddleBrown;
var public config const Color Sienna;
var public config const Color Brown;
var public config const Color Maroon;
//  Green colors
var public config const Color DarkOliveGreen;
var public config const Color Olive;
var public config const Color OliveDrab;
var public config const Color YellowGreen;
var public config const Color LimeGreen;
var public config const Color Lime;
var public config const Color LawnGreen;
var public config const Color Chartreuse;
var public config const Color GreenYellow;
var public config const Color SpringGreen;
var public config const Color MediumSpringGreen;
var public config const Color LightGreen;
var public config const Color PaleGreen;
var public config const Color DarkSeaGreen;
var public config const Color MediumAquamarine;
var public config const Color MediumSeaGreen;
var public config const Color SeaGreen;
var public config const Color ForestGreen;
var public config const Color Green;
var public config const Color DarkGreen;
//  Cyan colors
var public config const Color Aqua;
var public config const Color Cyan;
var public config const Color LightCyan;
var public config const Color PaleTurquoise;
var public config const Color Aquamarine;
var public config const Color Turquoise;
var public config const Color MediumTurquoise;
var public config const Color DarkTurquoise;
var public config const Color LightSeaGreen;
var public config const Color CadetBlue;
var public config const Color DarkCyan;
var public config const Color Teal;
//  Blue colors
var public config const Color LightSteelBlue;
var public config const Color PowderBlue;
var public config const Color LightBlue;
var public config const Color SkyBlue;
var public config const Color LightSkyBlue;
var public config const Color DeepSkyBlue;
var public config const Color DodgerBlue;
var public config const Color CornflowerBlue;
var public config const Color SteelBlue;
var public config const Color RoyalBlue;
var public config const Color Blue;
var public config const Color MediumBlue;
var public config const Color DarkBlue;
var public config const Color Navy;
var public config const Color MidnightBlue;
//  Purple, violet, and magenta colors
var public config const Color Lavender;
var public config const Color Thistle;
var public config const Color Plum;
var public config const Color Violet;
var public config const Color Orchid;
var public config const Color Fuchsia;
var public config const Color Magenta;
var public config const Color MediumOrchid;
var public config const Color MediumPurple;
var public config const Color BlueViolet;
var public config const Color DarkViolet;
var public config const Color DarkOrchid;
var public config const Color DarkMagenta;
var public config const Color Purple;
var public config const Color Indigo;
var public config const Color DarkSlateBlue;
var public config const Color SlateBlue;
var public config const Color MediumSlateBlue;
//  White colors
var public config const Color White;
var public config const Color Snow;
var public config const Color Honeydew;
var public config const Color MintCream;
var public config const Color Azure;
var public config const Color AliceBlue;
var public config const Color GhostWhite;
var public config const Color WhiteSmoke;
var public config const Color Seashell;
var public config const Color Beige;
var public config const Color OldLace;
var public config const Color FloralWhite;
var public config const Color Ivory;
var public config const Color AntiqueWhite;
var public config const Color Linen;
var public config const Color LavenderBlush;
var public config const Color MistyRose;
//  Gray and black colors
var public config const Color Gainsboro;
var public config const Color LightGray;
var public config const Color Silver;
var public config const Color DarkGray;
var public config const Color Gray;
var public config const Color DimGray;
var public config const Color LightSlateGray;
var public config const Color SlateGray;
var public config const Color DarkSlateGray;
var public config const Color Eigengrau;
var public config const Color CoolBlack;
var public config const Color Black;
//  Vue red colors
var public config const Color vuered;
var public config const Color redlighten5;
var public config const Color redlighten4;
var public config const Color redlighten3;
var public config const Color redlighten2;
var public config const Color redlighten1;
var public config const Color reddarken1;
var public config const Color reddarken2;
var public config const Color reddarken3;
var public config const Color reddarken4;
var public config const Color redaccent1;
var public config const Color redaccent2;
var public config const Color redaccent3;
var public config const Color redaccent4;
//  Vue pink colors
var public config const Color vuepink;
var public config const Color pinklighten5;
var public config const Color pinklighten4;
var public config const Color pinklighten3;
var public config const Color pinklighten2;
var public config const Color pinklighten1;
var public config const Color pinkdarken1;
var public config const Color pinkdarken2;
var public config const Color pinkdarken3;
var public config const Color pinkdarken4;
var public config const Color pinkaccent1;
var public config const Color pinkaccent2;
var public config const Color pinkaccent3;
var public config const Color pinkaccent4;
//  Vue purple colors
var public config const Color vuepurple;
var public config const Color purplelighten5;
var public config const Color purplelighten4;
var public config const Color purplelighten3;
var public config const Color purplelighten2;
var public config const Color purplelighten1;
var public config const Color purpledarken1;
var public config const Color purpledarken2;
var public config const Color purpledarken3;
var public config const Color purpledarken4;
var public config const Color purpleaccent1;
var public config const Color purpleaccent2;
var public config const Color purpleaccent3;
var public config const Color purpleaccent4;
//  Vue deep purple colors
var public config const Color deeppurple;
var public config const Color vuedeeppurple;
var public config const Color deeppurplelighten5;
var public config const Color deeppurplelighten4;
var public config const Color deeppurplelighten3;
var public config const Color deeppurplelighten2;
var public config const Color deeppurplelighten1;
var public config const Color deeppurpledarken1;
var public config const Color deeppurpledarken2;
var public config const Color deeppurpledarken3;
var public config const Color deeppurpledarken4;
var public config const Color deeppurpleaccent1;
var public config const Color deeppurpleaccent2;
var public config const Color deeppurpleaccent3;
var public config const Color deeppurpleaccent4;
//  Vue indigo colors
var public config const Color vueindigo;
var public config const Color indigolighten5;
var public config const Color indigolighten4;
var public config const Color indigolighten3;
var public config const Color indigolighten2;
var public config const Color indigolighten1;
var public config const Color indigodarken1;
var public config const Color indigodarken2;
var public config const Color indigodarken3;
var public config const Color indigodarken4;
var public config const Color indigoaccent1;
var public config const Color indigoaccent2;
var public config const Color indigoaccent3;
var public config const Color indigoaccent4;
//  Vue blue colors
var public config const Color vueblue;
var public config const Color bluelighten5;
var public config const Color bluelighten4;
var public config const Color bluelighten3;
var public config const Color bluelighten2;
var public config const Color bluelighten1;
var public config const Color bluedarken1;
var public config const Color bluedarken2;
var public config const Color bluedarken3;
var public config const Color bluedarken4;
var public config const Color blueaccent1;
var public config const Color blueaccent2;
var public config const Color blueaccent3;
var public config const Color blueaccent4;
//  Vue light blue colors
var public config const Color vuelightblue;
var public config const Color lightbluelighten5;
var public config const Color lightbluelighten4;
var public config const Color lightbluelighten3;
var public config const Color lightbluelighten2;
var public config const Color lightbluelighten1;
var public config const Color lightbluedarken1;
var public config const Color lightbluedarken2;
var public config const Color lightbluedarken3;
var public config const Color lightbluedarken4;
var public config const Color lightblueaccent1;
var public config const Color lightblueaccent2;
var public config const Color lightblueaccent3;
var public config const Color lightblueaccent4;
//  Vue cyan colors
var public config const Color vuecyan;
var public config const Color cyanlighten5;
var public config const Color cyanlighten4;
var public config const Color cyanlighten3;
var public config const Color cyanlighten2;
var public config const Color cyanlighten1;
var public config const Color cyandarken1;
var public config const Color cyandarken2;
var public config const Color cyandarken3;
var public config const Color cyandarken4;
var public config const Color cyanaccent1;
var public config const Color cyanaccent2;
var public config const Color cyanaccent3;
var public config const Color cyanaccent4;
//  Vue teal colors
var public config const Color vueteal;
var public config const Color teallighten5;
var public config const Color teallighten4;
var public config const Color teallighten3;
var public config const Color teallighten2;
var public config const Color teallighten1;
var public config const Color tealdarken1;
var public config const Color tealdarken2;
var public config const Color tealdarken3;
var public config const Color tealdarken4;
var public config const Color tealaccent1;
var public config const Color tealaccent2;
var public config const Color tealaccent3;
var public config const Color tealaccent4;
//  Vue green colors
var public config const Color vuegreen;
var public config const Color greenlighten5;
var public config const Color greenlighten4;
var public config const Color greenlighten3;
var public config const Color greenlighten2;
var public config const Color greenlighten1;
var public config const Color greendarken1;
var public config const Color greendarken2;
var public config const Color greendarken3;
var public config const Color greendarken4;
var public config const Color greenaccent1;
var public config const Color greenaccent2;
var public config const Color greenaccent3;
var public config const Color greenaccent4;
//  Vue light green colors
var public config const Color vuelightgreen;
var public config const Color lightgreenlighten5;
var public config const Color lightgreenlighten4;
var public config const Color lightgreenlighten3;
var public config const Color lightgreenlighten2;
var public config const Color lightgreenlighten1;
var public config const Color lightgreendarken1;
var public config const Color lightgreendarken2;
var public config const Color lightgreendarken3;
var public config const Color lightgreendarken4;
//  Vue lime colors
var public config const Color vuelime;
var public config const Color limelighten5;
var public config const Color limelighten4;
var public config const Color limelighten3;
var public config const Color limelighten2;
var public config const Color limelighten1;
var public config const Color limedarken1;
var public config const Color limedarken2;
var public config const Color limedarken3;
var public config const Color limedarken4;
var public config const Color limeaccent1;
var public config const Color limeaccent2;
var public config const Color limeaccent3;
var public config const Color limeaccent4;
//  Vue yellow colors
var public config const Color vueyellow;
var public config const Color yellowlighten5;
var public config const Color yellowlighten4;
var public config const Color yellowlighten3;
var public config const Color yellowlighten2;
var public config const Color yellowlighten1;
var public config const Color yellowdarken1;
var public config const Color yellowdarken2;
var public config const Color yellowdarken3;
var public config const Color yellowdarken4;
var public config const Color yellowaccent1;
var public config const Color yellowaccent2;
var public config const Color yellowaccent3;
var public config const Color yellowaccent4;
//  Vue amber colors
var public config const Color amber;
var public config const Color vueamber;
var public config const Color amberlighten5;
var public config const Color amberlighten4;
var public config const Color amberlighten3;
var public config const Color amberlighten2;
var public config const Color amberlighten1;
var public config const Color amberdarken1;
var public config const Color amberdarken2;
var public config const Color amberdarken3;
var public config const Color amberdarken4;
var public config const Color amberaccent1;
var public config const Color amberaccent2;
var public config const Color amberaccent3;
var public config const Color amberaccent4;
//  Vue orange colors
var public config const Color vueorange;
var public config const Color orangelighten5;
var public config const Color orangelighten4;
var public config const Color orangelighten3;
var public config const Color orangelighten2;
var public config const Color orangelighten1;
var public config const Color orangedarken1;
var public config const Color orangedarken2;
var public config const Color orangedarken3;
var public config const Color orangedarken4;
var public config const Color orangeaccent1;
var public config const Color orangeaccent2;
var public config const Color orangeaccent3;
var public config const Color orangeaccent4;
//  Vue deep orange colors
var public config const Color deeporange;
var public config const Color vuedeeporange;
var public config const Color deeporangelighten5;
var public config const Color deeporangelighten4;
var public config const Color deeporangelighten3;
var public config const Color deeporangelighten2;
var public config const Color deeporangelighten1;
var public config const Color deeporangedarken1;
var public config const Color deeporangedarken2;
var public config const Color deeporangedarken3;
var public config const Color deeporangedarken4;
var public config const Color deeporangeaccent1;
var public config const Color deeporangeaccent2;
var public config const Color deeporangeaccent3;
var public config const Color deeporangeaccent4;
//  Vue brown colors
var public config const Color vuebrown;
var public config const Color brownlighten5;
var public config const Color brownlighten4;
var public config const Color brownlighten3;
var public config const Color brownlighten2;
var public config const Color brownlighten1;
var public config const Color browndarken1;
var public config const Color browndarken2;
var public config const Color browndarken3;
var public config const Color browndarken4;
//  Vue blue grey colors
var public config const Color bluegrey;
var public config const Color vuebluegrey;
var public config const Color bluegreylighten5;
var public config const Color bluegreylighten4;
var public config const Color bluegreylighten3;
var public config const Color bluegreylighten2;
var public config const Color bluegreylighten1;
var public config const Color bluegreydarken1;
var public config const Color bluegreydarken2;
var public config const Color bluegreydarken3;
var public config const Color bluegreydarken4;
//  Vue grey colors
var public config const Color grey;
var public config const Color vuegrey;
var public config const Color greylighten5;
var public config const Color greylighten4;
var public config const Color greylighten3;
var public config const Color greylighten2;
var public config const Color greylighten1;
var public config const Color greydarken1;
var public config const Color greydarken2;
var public config const Color greydarken3;
var public config const Color greydarken4;

var private const int TRGB, TRGBA, TCLOSING_PARENTHESIS, TR_COMPONENT;
var private const int TG_COMPONENT, TB_COMPONENT, TA_COMPONENT, TCOMMA, THASH;
var private const int TDOLLAR;

//  Struct and array that are meant to store colors used by "^"-color tags:
//  "^2" means green, "^b" means blue, etc..
struct ShortColorTagDefinition
{
    //  Letter after "^"
    var public string   char;
    //  Color corresponding to such letter
    var public Color    color;
};
var public config const array<ShortColorTagDefinition> shortColorTag;

//  Escape code point is used to change output's color and is used in
//  Unreal Engine's `string`s.
var private const int CODEPOINT_ESCAPE;
var private const int CODEPOINT_SMALL_A;

/**
 *  Creates opaque color from (red, green, blue) triplet.
 *
 *  @param  red     Red component, range from 0 to 255.
 *  @param  green   Green component, range from 0 to 255.
 *  @param  blue    Blue component, range from 0 to 255.
 *  @return `Color` with specified red, green and blue component and
 *      alpha component of `255`.
 */
public final function Color RGB(byte red, byte green, byte blue)
{
    local Color result;
    result.r = red;
    result.g = green;
    result.b = blue;
    result.a = 255;
    return result;
}

/**
 *  Creates color from (red, green, blue, alpha) quadruplet.
 *
 *  @param  red     Red component, range from 0 to 255.
 *  @param  green   Green component, range from 0 to 255.
 *  @param  blue    Blue component, range from 0 to 255.
 *  @param  alpha   Alpha component, range from 0 to 255.
 *  @return `Color` with specified red, green, blue and alpha component.
 */
public final function Color RGBA(byte red, byte green, byte blue, byte alpha)
{
    local Color result;
    result.r = red;
    result.g = green;
    result.b = blue;
    result.a = alpha;
    return result;
}

/**
 *  Compares two colors for exact equality of red, green and blue components.
 *  Alpha component is ignored.
 *
 *  @param  color1  Color to compare
 *  @param  color2  Color to compare
 *  @return `true` if colors' red, green and blue components are equal
 *      and `false` otherwise.
 */
public final function bool AreEqual(Color color1, Color color2, optional bool fixColors)
{
    if (fixColors) {
        color1 = FixColor(color1);
        color2 = FixColor(color2);
    }
    if (color1.r != color2.r) return false;
    if (color1.g != color2.g) return false;
    if (color1.b != color2.b) return false;
    return true;
}

/**
 *  Compares two colors for exact equality of red, green, blue
 *  and alpha components.
 *
 *  @param  color1  Color to compare
 *  @param  color2  Color to compare
 *  @return `true` if colors' red, green, blue and alpha components are equal
 *      and `false` otherwise.
 */
public final function bool AreEqualWithAlpha(Color color1, Color color2, optional bool fixColors)
{
    if (fixColors) {
        color1 = FixColor(color1);
        color2 = FixColor(color2);
    }
    if (color1.r != color2.r) return false;
    if (color1.g != color2.g) return false;
    if (color1.b != color2.b) return false;
    if (color1.a != color2.a) return false;
    return true;
}

/**
 *      Killing floor's standard methods of rendering colored `string`s
 *  make use of inserting 4-byte sequence into them: first bytes denotes
 *  the start of the sequence, 3 following bytes denote rgb color components.
 *      Unfortunately these methods also have issues with rendering `string`s
 *  if you specify certain values (`0` and `10`) of rgb color components.
 *
 *  This function "fixes" components by replacing them with close and valid
 *  color component values (adds `1` to the component).
 */
public final function byte FixColorComponent(byte colorComponent)
{
    if (colorComponent == 0 || colorComponent == 10)
    {
        return colorComponent + 1;
    }
    return colorComponent;
}

/**
 *      Killing floor's standard methods of rendering colored `string`s
 *  make use of inserting 4-byte sequence into them: first bytes denotes
 *  the start of the sequence, 3 following bytes denote rgb color components.
 *      Unfortunately these methods also have issues with rendering `string`s
 *  if you specify certain values (`0` and `10`) as rgb color components.
 *
 *  This function "fixes" given `Color`'s components by replacing them with
 *  close and valid color values (using `FixColorComponent()` method),
 *  resulting in a `Color` that looks almost the same, but is suitable to be
 *  included into 4-byte color change sequence.
 *
 *  Since alpha component is never used in color-change sequences,
 *  it is never affected.
 */
public final function Color FixColor(Color colorToFix)
{
    colorToFix.r = FixColorComponent(colorToFix.r);
    colorToFix.g = FixColorComponent(colorToFix.g);
    colorToFix.b = FixColorComponent(colorToFix.b);
    return colorToFix;
}

/**
 *  Returns 4-gyte sequence for color change to a given color.
 *
 *      To make returned tag work in most sequences, the value of given color is
 *  auto "fixed" (see `FixColor()` for details).
 *      There is an option to skip color fixing, but method will still change
 *  `0` components to `1`, since they cannot otherwise be used in a tag at all.
 *
 *  Also see `GetColorTagRGB()`.
 *
 *  @param  colorToUse          Color to which tag must change the text.
 *      It's alpha value (`colorToUse.a`) is discarded.
 *  @param  doNotFixComponents  Minimizes changes to color components
 *      (only allows to change `0` components to `1` before creating a tag).
 *  @return `string` containing 4-byte sequence that will swap text's color to
 *      a given one in standard Unreal Engine's UI.
 */
public final function string GetColorTag(
    Color           colorToUse,
    optional bool   doNotFixComponents)
{
    if (!doNotFixComponents) {
        colorToUse = FixColor(colorToUse);
    }
    colorToUse.r    = Max(1, colorToUse.r);
    colorToUse.g    = Max(1, colorToUse.g);
    colorToUse.b    = Max(1, colorToUse.b);
    return Chr(CODEPOINT_ESCAPE)
        $ Chr(colorToUse.r)
        $ Chr(colorToUse.g)
        $ Chr(colorToUse.b);
}

/**
 *  Returns 4-gyte sequence for color change to a given color.
 *
 *      To make returned tag work in most sequences, the value of given color is
 *  auto "fixed" (see `FixColor()` for details).
 *      There is an option to skip color fixing, but method will still change
 *  `0` components to `1`, since they cannot otherwise be used in a tag at all.
 *
 *  Also see `GetColorTag()`.
 *
 *  @param  red                 Red component of color to which tag must
 *      change the text.
 *  @param  green               Green component of color to which tag must
 *      change the text.
 *  @param  blue                Blue component of color to which tag must
 *      change the text.
 *  @param  doNotFixComponents  Minimizes changes to color components
 *      (only allows to change `0` components to `1` before creating a tag).
 *  @return `string` containing 4-byte sequence that will swap text's color to
 *      a given one in standard Unreal Engine's UI.
 */
public final function string GetColorTagRGB(
    int             red,
    int             green,
    int             blue,
    optional bool   doNotFixComponents)
{
    if (!doNotFixComponents)
    {
        red     = FixColorComponent(red);
        green   = FixColorComponent(green);
        blue    = FixColorComponent(blue);
    }
    red     = Max(1, red);
    green   = Max(1, green);
    blue    = Max(1, blue);
    return Chr(CODEPOINT_ESCAPE) $ Chr(red) $ Chr(green) $ Chr(blue);
}

//  Helper function that converts `byte` with values between 0 and 15 into
//  a corresponding hex letter
private final function string ByteToHexCharacter(byte component)
{
    component = Clamp(component, 0, 15);
    if (component < 10) {
        return string(component);
    }
    return Chr(component - 10 + CODEPOINT_SMALL_A);
}

//  `byte` to `string` in hex
private final function string ComponentToHex(byte component)
{
    local byte high4Bits, low4Bits;
    low4Bits = component % 16;
    if (component >= 16) {
        high4Bits = (component - low4Bits) / 16;
    }
    else {
        high4Bits = 0;
    }
    return ByteToHexCharacter(high4Bits) $ ByteToHexCharacter(low4Bits);
}

/**
 *  Displays given color as a `string` in a given style
 *  (hex color representation by default).
 *
 *  @param  colorToConvert  Color to display as a `string`.
 *  @param  displayType     `enum` value, describing how should color
 *      be displayed.
 *  @return `string` representation of a given color in a given style.
 */
public final function string ToStringType(
    Color                       colorToConvert,
    optional ColorDisplayType   displayType)
{
    if (displayType == CLRDISPLAY_HEX) {
        return "#" $ ComponentToHex(colorToConvert.r)
            $ ComponentToHex(colorToConvert.g)
            $ ComponentToHex(colorToConvert.b);
    }
    else if (displayType == CLRDISPLAY_RGB)
    {
        return "rgb(" $ string(colorToConvert.r) $ ","
            $ string(colorToConvert.g) $ ","
            $ string(colorToConvert.b) $ ")";
    }
    else if (displayType == CLRDISPLAY_RGBA)
    {
        return "rgba(" $ string(colorToConvert.r) $ ","
            $ string(colorToConvert.g) $ ","
            $ string(colorToConvert.b) $ ","
            $ string(colorToConvert.a) $ ")";
    }
    else if (displayType == CLRDISPLAY_RGB_TAG)
    {
        return "rgb(r=" $ string(colorToConvert.r) $ ","
            $ "g=" $ string(colorToConvert.g) $ ","
            $ "b=" $ string(colorToConvert.b) $ ")";
    }
    else if (displayType == CLRDISPLAY_RGBA_TAG)
    {
        return "rgba(r=" $ string(colorToConvert.r) $ ","
            $ "g=" $ string(colorToConvert.g) $ ","
            $ "b=" $ string(colorToConvert.b) $ ","
            $ "a=" $ string(colorToConvert.a) $ ")";
    }
    else if (displayType == CLRDISPLAY_RGB_STRIPPED)
    {
        return string(colorToConvert.r) $ ","
            $ string(colorToConvert.g) $ ","
            $ string(colorToConvert.b);
    }
    //else if (displayType == CLRDISPLAY_RGBA_STRIPPED)
    return string(colorToConvert.r) $ ","
        $ string(colorToConvert.g) $ ","
        $ string(colorToConvert.b) $ ","
        $ string(colorToConvert.a);
}

/**
 *  Displays given color as a `string` in RGB or RGBA format, depending on
 *  whether color is opaque.
 *
 *  @param  colorToConvert  Color to display as a `string` in `CLRDISPLAY_RGB`
 *      style if `colorToConvert.a == 255` and `CLRDISPLAY_RGBA` otherwise.
 *  @return `string` representation of a given color in a given style.
 */
public final function string ToString(Color colorToConvert)
{
    if (colorToConvert.a < 255) {
        return ToStringType(colorToConvert, CLRDISPLAY_RGBA);
    }
    return ToStringType(colorToConvert, CLRDISPLAY_RGB);
}

/**
 *  Displays given color as a `Text` in a given style
 *  (hex color representation by default).
 *
 *  @param  colorToConvert  Color to display as a `Text`.
 *  @param  displayType     `enum` value, describing how should color
 *      be displayed.
 *  @return `Text` representation of a given color in a given style.
 *      Guaranteed to not be `none`.
 */
public final function Text ToTextType(
    Color                       colorToConvert,
    optional ColorDisplayType   displayType)
{
    return _.text.FromString(ToStringType(colorToConvert, displayType));
}

/**
 *  Displays given color as a `Text` in RGB or RGBA format, depending on
 *  whether color is opaque.
 *
 *  @param  colorToConvert  Color to display as a `Text` in `CLRDISPLAY_RGB`
 *      style if `colorToConvert.a == 255` and `CLRDISPLAY_RGBA` otherwise.
 *  @return `Text` representation of a given color in a given style.
 */
public final function Text ToText(Color colorToConvert)
{
    return _.text.FromString(ToString(colorToConvert));
}

//  Parses color in `CLRDISPLAY_RGB`, `CLRDISPLAY_RGB_TAG` and
//  `CLRDISPLAY_RGB_STRIPPED` representations.
private final function Color ParseRGB(Parser parser)
{
    local int                   redComponent;
    local int                   greenComponent;
    local int                   blueComponent;
    local Parser.ParserState    initialParserState;
    initialParserState = parser.GetCurrentState();
    parser.Match(T(TRGB), SCASE_INSENSITIVE)
        .MInteger(redComponent).Match(T(TCOMMA))
        .MInteger(greenComponent).Match(T(TCOMMA))
        .MInteger(blueComponent).Match(T(TCLOSING_PARENTHESIS));
    if (!parser.Ok())
    {
        parser.RestoreState(initialParserState)
            .Match(T(TRGB), SCASE_INSENSITIVE)
            .Match(T(TR_COMPONENT), SCASE_INSENSITIVE)
            .MInteger(redComponent).Match(T(TCOMMA))
            .Match(T(TG_COMPONENT), SCASE_INSENSITIVE)
            .MInteger(greenComponent).Match(T(TCOMMA))
            .Match(T(TB_COMPONENT), SCASE_INSENSITIVE)
            .MInteger(blueComponent).Match(T(TCLOSING_PARENTHESIS));
    }
    if (!parser.Ok())
    {
        parser.RestoreState(initialParserState)
            .MInteger(redComponent).Match(T(TCOMMA))
            .MInteger(greenComponent).Match(T(TCOMMA))
            .MInteger(blueComponent);
    }
    return RGB(redComponent, greenComponent, blueComponent);
}

//  Parses color in `CLRDISPLAY_RGBA`, `CLRDISPLAY_RGBA_TAG`
//  and `CLRDISPLAY_RGBA_STRIPPED` representations.
private final function Color ParseRGBA(Parser parser)
{
    local int                   redComponent;
    local int                   greenComponent;
    local int                   blueComponent;
    local int                   alphaComponent;
    local Parser.ParserState    initialParserState;
    initialParserState = parser.GetCurrentState();
    parser.Match(T(TRGBA), SCASE_INSENSITIVE)
        .MInteger(redComponent).Match(T(TCOMMA))
        .MInteger(greenComponent).Match(T(TCOMMA))
        .MInteger(blueComponent).Match(T(TCOMMA))
        .MInteger(alphaComponent).Match(T(TCLOSING_PARENTHESIS));
    if (!parser.Ok())
    {
        parser.RestoreState(initialParserState)
            .Match(T(TRGBA), SCASE_INSENSITIVE) 
            .Match(T(TR_COMPONENT), SCASE_INSENSITIVE)
            .MInteger(redComponent).Match(T(TCOMMA))
            .Match(T(TG_COMPONENT), SCASE_INSENSITIVE)
            .MInteger(greenComponent).Match(T(TCOMMA))
            .Match(T(TB_COMPONENT), SCASE_INSENSITIVE)
            .MInteger(blueComponent).Match(T(TCOMMA))
            .Match(T(TA_COMPONENT), SCASE_INSENSITIVE)
            .MInteger(alphaComponent).Match(T(TCLOSING_PARENTHESIS));
    }
    if (!parser.Ok())
    {
        parser.RestoreState(initialParserState)
            .MInteger(redComponent).Match(T(TCOMMA))
            .MInteger(greenComponent).Match(T(TCOMMA))
            .MInteger(blueComponent).Match(T(TCOMMA))
            .MInteger(alphaComponent);
    }
    return RGBA(redComponent, greenComponent, blueComponent, alphaComponent);
}

//  Parses color in `CLRDISPLAY_HEX` representation.
private final function Color ParseHexColor(Parser parser)
{
    local int redComponent;
    local int greenComponent;
    local int blueComponent;
    parser.Match(T(THASH))
        .MUnsignedInteger(redComponent, 16, 2)
        .MUnsignedInteger(greenComponent, 16, 2)
        .MUnsignedInteger(blueComponent, 16, 2);
    return RGB(redComponent, greenComponent, blueComponent);
}

/**
 *  Uses given parser to try and parse a color in any of the
 *  `ColorDisplayType` representations.
 *
 *  @param  parser          Parser that method would use to parse color from
 *      wherever it left. It's confirmed state will not be changed.
 *      Do not treat `parser` bein in a non-failed state as a confirmation of
 *      successful parsing: color parsing might fail regardless.
 *      Check return value for that.
 *  @param  resultingColor  Parsed color will be written here if parsing is
 *      successful, otherwise value is undefined.
 *      If parsed color did not specify alpha component - 255 will be used.
 *  @return `true` if parsing was successful and false otherwise.
 */
public final function bool ParseWith(Parser parser, out Color resultingColor)
{
    local bool                  successfullyParsed;
    local Text                  colorContent;
    local MutableText           colorAlias;
    local Parser                colorParser;
    local Parser.ParserState    initialParserState;
    if (parser == none) {
        return false;
    }
    resultingColor.a    = 0xff;
    colorParser         = parser;
    initialParserState  = parser.GetCurrentState();
    if (parser.Match(T(TDOLLAR)).MName(colorAlias).Ok())
    {
        colorContent = _.alias.ResolveColor(colorAlias);
        colorParser = _.text.Parse(colorContent);
        initialParserState = colorParser.GetCurrentState();
        _.memory.Free(colorContent);
    }
    else {
        parser.RestoreState(initialParserState);
    }
    colorAlias.FreeSelf();
    //  `CLRDISPLAY_RGBA_STRIPPED` format can be parsed as an incomplete
    //  `CLRDISPLAY_RGB_STRIPPED`, so we need to try parsing RGBA first
    resultingColor = ParseRGBA(colorParser);
    if (!colorParser.Ok())
    {
        colorParser.RestoreState(initialParserState);
        resultingColor = ParseRGB(colorParser);
    }
    if (!colorParser.Ok())
    {
        colorParser.RestoreState(initialParserState);
        resultingColor = ParseHexColor(colorParser);
    }
    successfullyParsed = colorParser.Ok();
    if (colorParser != parser) {
        _.memory.Free(colorParser);
    }
    return successfullyParsed;
}

/**
 *  Parses a color in any of the `ColorDisplayType` representations from the
 *  beginning of a given `string`.
 *
 *  @param  stringWithColor String, that contains color definition at
 *      the beginning. Anything after color definition is not used.
 *  @param  resultingColor  Parsed color will be written here if parsing is
 *      successful, otherwise value is undefined.
 *      If parsed color did not specify alpha component - 255 will be used.
 *  @return `true` if parsing was successful and false otherwise.
 */
public final function bool ParseString(
    string      stringWithColor,
    out Color   resultingColor)
{
    local bool      successfullyParsed;
    local Parser    colorParser;
    colorParser = _.text.ParseString(stringWithColor);
    successfullyParsed = ParseWith(colorParser, resultingColor);
    _.memory.Free(colorParser);
    return successfullyParsed;
}

/**
 *  Parses a color in any of the `ColorDisplayType` representations from the
 *  beginning of a given `Text`.
 *
 *  @param  textWithColor   `Text`, that contains color definition at
 *      the beginning. Anything after color definition is not used.
 *  @param  resultingColor  Parsed color will be written here if parsing is
 *      successful, otherwise value is undefined.
 *      If parsed color did not specify alpha component - 255 will be used.
 *  @return `true` if parsing was successful and false otherwise.
 */
public final function bool Parse(
    BaseText    textWithColor,
    out Color   resultingColor)
{
    local bool      successfullyParsed;
    local Parser    colorParser;
    colorParser = _.text.Parse(textWithColor);
    successfullyParsed = ParseWith(colorParser, resultingColor);
    _.memory.Free(colorParser);
    return successfullyParsed;
}

/**
 *  Resolves a given short (character) tag into a color.
 *  These are the tags referred to by "^" color change sequence
 *  (like "^4" or "^r").
 *
 *  This operation can fail if passed character does not correspond to
 *  any color, according to settings.
 *
 *  @param  shortTag        Character that represents the short tag.
 *  @param  resultingColor  Parsed color will be written here if resolving is
 *      successful, otherwise value is undefined.
 *  @return `true` if resolving was successful and false otherwise.
 */
public final function bool ResolveShortTagColor(
    BaseText.Character  shortTag,
    out Color           resultingColor)
{
    local int i;
    if (shortTag.codePoint <= 0) {
        return false;
    }
    for (i = 0; i < shortColorTag.length; i += 1)
    {
        if (    shortTag.codePoint
            ==  _.text.GetCharacter(shortColorTag[i].char).codepoint)
        {
            resultingColor = shortColorTag[i].color;
            return true;
        }
    }
    return false;
}

defaultproperties
{
    TextDefault=(R=255,G=255,B=255,A=255)
    TextHeader=(R=128,G=0,B=128,A=255)
    TextSubHeader=(R=147,G=112,B=219,A=255)
    TextSubtle=(R=128,G=128,B=128,A=255)
    TextEmphasis=(R=0,G=128,B=255,A=255)
    TextPositive=(R=60,G=220,B=20,A=255)
    TextNeutral=(R=255,G=255,B=0,A=255)
    TextNegative=(R=220,G=20,B=60,A=255)
    TextOk=(R=0,G=255,B=0,A=255)
    TextWarning=(R=255,G=128,B=0,A=255)
    TextFailure=(R=255,G=0,B=0,A=255)
    TypeNumber=(R=255,G=235,B=172,A=255)
    TypeBoolean=(R=199,G=226,B=244,A=255)
    TypeString=(R=243,G=204,B=223,A=255)
    TypeLiteral=(R=194,G=239,B=235,A=255)
    TypeClass=(R=218,G=219,B=240,A=255)
    jPropertyName=(R=255,G=77,B=77,A=255)
    jObjectBraces=(R=220,G=220,B=220,A=255)
    jArrayBraces=(R=220,G=220,B=220,A=255)
    jComma=(R=220,G=220,B=220,A=255)
    jColon=(R=220,G=220,B=220,A=255)
    jNumber=(R=255,G=255,B=77,A=255)
    jBoolean=(R=38,G=139,B=210,A=255)
    jString=(R=98,G=173,B=227,A=255)
    jNull=(R=38,G=139,B=210,A=255)
    Pink=(R=255,G=192,B=203,A=255)
    LightPink=(R=255,G=182,B=193,A=255)
    HotPink=(R=255,G=105,B=180,A=255)
    DeepPink=(R=255,G=20,B=147,A=255)
    PaleVioletRed=(R=219,G=112,B=147,A=255)
    MediumVioletRed=(R=199,G=21,B=133,A=255)
    LightSalmon=(R=255,G=160,B=122,A=255)
    Salmon=(R=250,G=128,B=114,A=255)
    DarkSalmon=(R=233,G=150,B=122,A=255)
    LightCoral=(R=240,G=128,B=128,A=255)
    IndianRed=(R=205,G=92,B=92,A=255)
    Crimson=(R=220,G=20,B=60,A=255)
    Firebrick=(R=178,G=34,B=34,A=255)
    DarkRed=(R=139,G=0,B=0,A=255)
    Red=(R=255,G=0,B=0,A=255)
    OrangeRed=(R=255,G=69,B=0,A=255)
    Tomato=(R=255,G=99,B=71,A=255)
    Coral=(R=255,G=127,B=80,A=255)
    DarkOrange=(R=255,G=140,B=0,A=255)
    Orange=(R=255,G=165,B=0,A=255)
    Yellow=(R=255,G=255,B=0,A=255)
    LightYellow=(R=255,G=255,B=224,A=255)
    LemonChiffon=(R=255,G=250,B=205,A=255)
    LightGoldenrodYellow=(R=250,G=250,B=210,A=255)
    PapayaWhip=(R=255,G=239,B=213,A=255)
    Moccasin=(R=255,G=228,B=181,A=255)
    PeachPuff=(R=255,G=218,B=185,A=255)
    PaleGoldenrod=(R=238,G=232,B=170,A=255)
    Khaki=(R=240,G=230,B=140,A=255)
    DarkKhaki=(R=189,G=183,B=107,A=255)
    Gold=(R=255,G=215,B=0,A=255)
    CoolGold=(R=255,G=200,B=120,A=255)
    Cornsilk=(R=255,G=248,B=220,A=255)
    BlanchedAlmond=(R=255,G=235,B=205,A=255)
    Bisque=(R=255,G=228,B=196,A=255)
    NavajoWhite=(R=255,G=222,B=173,A=255)
    Wheat=(R=245,G=222,B=179,A=255)
    Burlywood=(R=222,G=184,B=135,A=255)
    TanColor=(R=210,G=180,B=140,A=255)
    RosyBrown=(R=188,G=143,B=143,A=255)
    SandyBrown=(R=244,G=164,B=96,A=255)
    Goldenrod=(R=218,G=165,B=32,A=255)
    DarkGoldenrod=(R=184,G=134,B=11,A=255)
    Peru=(R=205,G=133,B=63,A=255)
    Chocolate=(R=210,G=105,B=30,A=255)
    SaddleBrown=(R=139,G=69,B=19,A=255)
    Sienna=(R=160,G=82,B=45,A=255)
    Brown=(R=165,G=42,B=42,A=255)
    Maroon=(R=128,G=0,B=0,A=255)
    DarkOliveGreen=(R=85,G=107,B=47,A=255)
    Olive=(R=128,G=128,B=0,A=255)
    OliveDrab=(R=107,G=142,B=35,A=255)
    YellowGreen=(R=154,G=205,B=50,A=255)
    LimeGreen=(R=50,G=205,B=50,A=255)
    Lime=(R=0,G=255,B=0,A=255)
    LawnGreen=(R=124,G=252,B=0,A=255)
    Chartreuse=(R=127,G=255,B=0,A=255)
    GreenYellow=(R=173,G=255,B=47,A=255)
    SpringGreen=(R=0,G=255,B=127,A=255)
    MediumSpringGreen=(R=0,G=250,B=154,A=255)
    LightGreen=(R=144,G=238,B=144,A=255)
    PaleGreen=(R=152,G=251,B=152,A=255)
    DarkSeaGreen=(R=143,G=188,B=143,A=255)
    MediumAquamarine=(R=102,G=205,B=170,A=255)
    MediumSeaGreen=(R=60,G=179,B=113,A=255)
    SeaGreen=(R=46,G=139,B=87,A=255)
    ForestGreen=(R=34,G=139,B=34,A=255)
    Green=(R=0,G=128,B=0,A=255)
    DarkGreen=(R=0,G=100,B=0,A=255)
    Aqua=(R=0,G=255,B=255,A=255)
    Cyan=(R=0,G=255,B=255,A=255)
    LightCyan=(R=224,G=255,B=255,A=255)
    PaleTurquoise=(R=175,G=238,B=238,A=255)
    Aquamarine=(R=127,G=255,B=212,A=255)
    Turquoise=(R=64,G=224,B=208,A=255)
    MediumTurquoise=(R=72,G=209,B=204,A=255)
    DarkTurquoise=(R=0,G=206,B=209,A=255)
    LightSeaGreen=(R=32,G=178,B=170,A=255)
    CadetBlue=(R=95,G=158,B=160,A=255)
    DarkCyan=(R=0,G=139,B=139,A=255)
    Teal=(R=0,G=128,B=128,A=255)
    LightSteelBlue=(R=176,G=196,B=222,A=255)
    PowderBlue=(R=176,G=224,B=230,A=255)
    LightBlue=(R=173,G=216,B=230,A=255)
    SkyBlue=(R=135,G=206,B=235,A=255)
    LightSkyBlue=(R=135,G=206,B=250,A=255)
    DeepSkyBlue=(R=0,G=191,B=255,A=255)
    DodgerBlue=(R=30,G=144,B=255,A=255)
    CornflowerBlue=(R=100,G=149,B=237,A=255)
    SteelBlue=(R=70,G=130,B=180,A=255)
    RoyalBlue=(R=65,G=105,B=225,A=255)
    Blue=(R=0,G=0,B=255,A=255)
    MediumBlue=(R=0,G=0,B=205,A=255)
    DarkBlue=(R=0,G=0,B=139,A=255)
    Navy=(R=0,G=0,B=128,A=255)
    MidnightBlue=(R=25,G=25,B=112,A=255)
    Lavender=(R=230,G=230,B=250,A=255)
    Thistle=(R=216,G=191,B=216,A=255)
    Plum=(R=221,G=160,B=221,A=255)
    Violet=(R=238,G=130,B=238,A=255)
    Orchid=(R=218,G=112,B=214,A=255)
    Fuchsia=(R=255,G=0,B=255,A=255)
    Magenta=(R=255,G=0,B=255,A=255)
    MediumOrchid=(R=186,G=85,B=211,A=255)
    MediumPurple=(R=147,G=112,B=219,A=255)
    BlueViolet=(R=138,G=43,B=226,A=255)
    DarkViolet=(R=148,G=0,B=211,A=255)
    DarkOrchid=(R=153,G=50,B=204,A=255)
    DarkMagenta=(R=139,G=0,B=139,A=255)
    Purple=(R=128,G=0,B=128,A=255)
    Indigo=(R=75,G=0,B=130,A=255)
    DarkSlateBlue=(R=72,G=61,B=139,A=255)
    SlateBlue=(R=106,G=90,B=205,A=255)
    MediumSlateBlue=(R=123,G=104,B=238,A=255)
    White=(R=255,G=255,B=255,A=255)
    Snow=(R=255,G=250,B=250,A=255)
    Honeydew=(R=240,G=255,B=240,A=255)
    MintCream=(R=245,G=255,B=250,A=255)
    Azure=(R=240,G=255,B=255,A=255)
    AliceBlue=(R=240,G=248,B=255,A=255)
    GhostWhite=(R=248,G=248,B=255,A=255)
    WhiteSmoke=(R=245,G=245,B=245,A=255)
    Seashell=(R=255,G=245,B=238,A=255)
    Beige=(R=245,G=245,B=220,A=255)
    OldLace=(R=253,G=245,B=230,A=255)
    FloralWhite=(R=255,G=250,B=240,A=255)
    Ivory=(R=255,G=255,B=240,A=255)
    AntiqueWhite=(R=250,G=235,B=215,A=255)
    Linen=(R=250,G=240,B=230,A=255)
    LavenderBlush=(R=255,G=240,B=245,A=255)
    MistyRose=(R=255,G=228,B=225,A=255)
    Gainsboro=(R=220,G=220,B=220,A=255)
    LightGray=(R=211,G=211,B=211,A=255)
    Silver=(R=192,G=192,B=192,A=255)
    Gray=(R=169,G=169,B=169,A=255)
    DimGray=(R=128,G=128,B=128,A=255)
    DarkGray=(R=105,G=105,B=105,A=255)
    LightSlateGray=(R=119,G=136,B=153,A=255)
    SlateGray=(R=112,G=128,B=144,A=255)
    DarkSlateGray=(R=47,G=79,B=79,A=255)
    Eigengrau=(R=22,G=22,B=29,A=255)
    CoolBlack=(R=22,G=22,B=29,A=255)
    Black=(R=0,G=0,B=0,A=255)
    vuered=(R=244,G=67,B=54,A=255)
    redlighten5=(R=255,G=235,B=238,A=255)
    redlighten4=(R=255,G=205,B=210,A=255)
    redlighten3=(R=239,G=154,B=154,A=255)
    redlighten2=(R=229,G=115,B=115,A=255)
    redlighten1=(R=239,G=83,B=80,A=255)
    reddarken1=(R=229,G=57,B=53,A=255)
    reddarken2=(R=211,G=47,B=47,A=255)
    reddarken3=(R=198,G=40,B=40,A=255)
    reddarken4=(R=183,G=28,B=28,A=255)
    redaccent1=(R=255,G=138,B=128,A=255)
    redaccent2=(R=255,G=82,B=82,A=255)
    redaccent3=(R=255,G=23,B=68,A=255)
    redaccent4=(R=213,G=0,B=0,A=255)
    vuepink=(R=233,G=30,B=99,A=255)
    pinklighten5=(R=252,G=228,B=236,A=255)
    pinklighten4=(R=248,G=187,G=208,A=255)
    pinklighten3=(R=244,G=143,G=177,A=255)
    pinklighten2=(R=240,G=98,G=146,A=255)
    pinklighten1=(R=236,G=64,G=122,A=255)
    pinkdarken1=(R=216,G=27,G=96,A=255)
    pinkdarken2=(R=194,G=24,G=91,A=255)
    pinkdarken3=(R=173,G=20,G=87,A=255)
    pinkdarken4=(R=136,G=14,G=79,A=255)
    pinkaccent1=(R=255,G=128,G=171,A=255)
    pinkaccent2=(R=255,G=64,G=129,A=255)
    pinkaccent3=(R=245,G=0,G=87,A=255)
    pinkaccent4=(R=197,G=17,G=98,A=255)
    vuepurple=(R=156,G=39,G=176,A=255)
    purplelighten5=(R=243,G=229,G=245,A=255)
    purplelighten4=(R=225,G=190,G=231,A=255)
    purplelighten3=(R=206,G=147,G=216,A=255)
    purplelighten2=(R=186,G=104,G=200,A=255)
    purplelighten1=(R=171,G=71,G=188,A=255)
    purpledarken1=(R=142,G=36,G=170,A=255)
    purpledarken2=(R=123,G=31,G=162,A=255)
    purpledarken3=(R=106,G=27,G=154,A=255)
    purpledarken4=(R=74,G=20,G=140,A=255)
    purpleaccent1=(R=234,G=128,G=252,A=255)
    purpleaccent2=(R=224,G=64,G=251,A=255)
    purpleaccent3=(R=213,G=0,G=249,A=255)
    purpleaccent4=(R=170,G=0,G=255,A=255)
    deeppurple=(R=103,G=58,G=183,A=255)
    vuedeeppurple=(R=103,G=58,G=183,A=255)
    deeppurplelighten5=(R=237,G=231,G=246,A=255)
    deeppurplelighten4=(R=209,G=196,G=233,A=255)
    deeppurplelighten3=(R=179,G=157,G=219,A=255)
    deeppurplelighten2=(R=149,G=117,G=205,A=255)
    deeppurplelighten1=(R=126,G=87,G=194,A=255)
    deeppurpledarken1=(R=94,G=53,G=177,A=255)
    deeppurpledarken2=(R=81,G=45,G=168,A=255)
    deeppurpledarken3=(R=69,G=39,G=160,A=255)
    deeppurpledarken4=(R=49,G=27,G=146,A=255)
    deeppurpleaccent1=(R=179,G=136,G=255,A=255)
    deeppurpleaccent2=(R=124,G=77,G=255,A=255)
    deeppurpleaccent3=(R=101,G=31,G=255,A=255)
    deeppurpleaccent4=(R=98,G=0,G=234,A=255)
    vueindigo=(R=63,G=81,G=181,A=255)
    indigolighten5=(R=232,G=234,G=246,A=255)
    indigolighten4=(R=197,G=202,G=233,A=255)
    indigolighten3=(R=159,G=168,G=218,A=255)
    indigolighten2=(R=121,G=134,G=203,A=255)
    indigolighten1=(R=92,G=107,G=192,A=255)
    indigodarken1=(R=57,G=73,G=171,A=255)
    indigodarken2=(R=48,G=63,G=159,A=255)
    indigodarken3=(R=40,G=53,G=147,A=255)
    indigodarken4=(R=26,G=35,G=126,A=255)
    indigoaccent1=(R=140,G=158,G=255,A=255)
    indigoaccent2=(R=83,G=109,G=254,A=255)
    indigoaccent3=(R=61,G=90,G=254,A=255)
    indigoaccent4=(R=48,G=79,G=254,A=255)
    vueblue=(R=33,G=150,G=243,A=255)
    bluelighten5=(R=227,G=242,G=253,A=255)
    bluelighten4=(R=187,G=222,G=251,A=255)
    bluelighten3=(R=144,G=202,G=249,A=255)
    bluelighten2=(R=100,G=181,G=246,A=255)
    bluelighten1=(R=66,G=165,G=245,A=255)
    bluedarken1=(R=30,G=136,G=229,A=255)
    bluedarken2=(R=25,G=118,G=210,A=255)
    bluedarken3=(R=21,G=101,G=192,A=255)
    bluedarken4=(R=13,G=71,G=161,A=255)
    blueaccent1=(R=130,G=177,G=255,A=255)
    blueaccent2=(R=68,G=138,G=255,A=255)
    blueaccent3=(R=41,G=121,G=255,A=255)
    blueaccent4=(R=41,G=98,G=255,A=255)
    vuelightblue=(R=3,G=169,G=244,A=255)
    lightbluelighten5=(R=225,G=245,G=254,A=255)
    lightbluelighten4=(R=179,G=229,G=252,A=255)
    lightbluelighten3=(R=129,G=212,G=250,A=255)
    lightbluelighten2=(R=79,G=195,G=247,A=255)
    lightbluelighten1=(R=41,G=182,G=246,A=255)
    lightbluedarken1=(R=3,G=155,G=229,A=255)
    lightbluedarken2=(R=2,G=136,G=209,A=255)
    lightbluedarken3=(R=2,G=119,G=189,A=255)
    lightbluedarken4=(R=1,G=87,G=155,A=255)
    lightblueaccent1=(R=128,G=216,G=255,A=255)
    lightblueaccent2=(R=64,G=196,G=255,A=255)
    lightblueaccent3=(R=0,G=176,G=255,A=255)
    lightblueaccent4=(R=0,G=145,G=234,A=255)
    vuecyan=(R=0,G=188,G=212,A=255)
    cyanlighten5=(R=224,G=247,G=250,A=255)
    cyanlighten4=(R=178,G=235,G=242,A=255)
    cyanlighten3=(R=128,G=222,G=234,A=255)
    cyanlighten2=(R=77,G=208,G=225,A=255)
    cyanlighten1=(R=38,G=198,G=218,A=255)
    cyandarken1=(R=0,G=172,G=193,A=255)
    cyandarken2=(R=0,G=151,G=167,A=255)
    cyandarken3=(R=0,G=131,G=143,A=255)
    cyandarken4=(R=0,G=96,G=100,A=255)
    cyanaccent1=(R=132,G=255,G=255,A=255)
    cyanaccent2=(R=24,G=255,G=255,A=255)
    cyanaccent3=(R=0,G=229,G=255,A=255)
    cyanaccent4=(R=0,G=184,G=212,A=255)
    vueteal=(R=0,G=150,G=136,A=255)
    teallighten5=(R=224,G=242,G=241,A=255)
    teallighten4=(R=178,G=223,G=219,A=255)
    teallighten3=(R=128,G=203,G=196,A=255)
    teallighten2=(R=77,G=182,G=172,A=255)
    teallighten1=(R=38,G=166,G=154,A=255)
    tealdarken1=(R=0,G=137,G=123,A=255)
    tealdarken2=(R=0,G=121,G=107,A=255)
    tealdarken3=(R=0,G=105,G=92,A=255)
    tealdarken4=(R=0,G=77,G=64,A=255)
    tealaccent1=(R=167,G=255,G=235,A=255)
    tealaccent2=(R=100,G=255,G=218,A=255)
    tealaccent3=(R=29,G=233,G=182,A=255)
    tealaccent4=(R=0,G=191,G=165,A=255)
    vuegreen=(R=76,G=175,G=80,A=255)
    greenlighten5=(R=232,G=245,G=233,A=255)
    greenlighten4=(R=200,G=230,G=201,A=255)
    greenlighten3=(R=165,G=214,G=167,A=255)
    greenlighten2=(R=129,G=199,G=132,A=255)
    greenlighten1=(R=102,G=187,G=106,A=255)
    greendarken1=(R=67,G=160,G=71,A=255)
    greendarken2=(R=56,G=142,G=60,A=255)
    greendarken3=(R=46,G=125,G=50,A=255)
    greendarken4=(R=27,G=94,G=32,A=255)
    greenaccent1=(R=185,G=246,G=202,A=255)
    greenaccent2=(R=105,G=240,G=174,A=255)
    greenaccent3=(R=0,G=230,G=118,A=255)
    greenaccent4=(R=0,G=200,G=83,A=255)
    vuelightgreen=(R=139,G=195,G=74,A=255)
    lightgreenlighten5=(R=241,G=248,G=233,A=255)
    lightgreenlighten4=(R=220,G=237,G=200,A=255)
    lightgreenlighten3=(R=197,G=225,G=165,A=255)
    lightgreenlighten2=(R=174,G=213,G=129,A=255)
    lightgreenlighten1=(R=156,G=204,G=101,A=255)
    lightgreendarken1=(R=124,G=179,G=66,A=255)
    lightgreendarken2=(R=104,G=159,G=56,A=255)
    lightgreendarken3=(R=85,G=139,G=47,A=255)
    lightgreendarken4=(R=51,G=105,G=30,A=255)
    vuelime=(R=205,G=220,G=57,A=255)
    limelighten5=(R=249,G=251,G=231,A=255)
    limelighten4=(R=240,G=244,G=195,A=255)
    limelighten3=(R=230,G=238,G=156,A=255)
    limelighten2=(R=220,G=231,G=117,A=255)
    limelighten1=(R=212,G=225,G=87,A=255)
    limedarken1=(R=192,G=202,G=51,A=255)
    limedarken2=(R=175,G=180,G=43,A=255)
    limedarken3=(R=158,G=157,G=36,A=255)
    limedarken4=(R=130,G=119,G=23,A=255)
    limeaccent1=(R=244,G=255,G=129,A=255)
    limeaccent2=(R=238,G=255,G=65,A=255)
    limeaccent3=(R=198,G=255,G=0,A=255)
    limeaccent4=(R=174,G=234,G=0,A=255)
    vueyellow=(R=255,G=235,G=59,A=255)
    yellowlighten5=(R=255,G=253,G=231,A=255)
    yellowlighten4=(R=255,G=249,G=196,A=255)
    yellowlighten3=(R=255,G=245,G=157,A=255)
    yellowlighten2=(R=255,G=241,G=118,A=255)
    yellowlighten1=(R=255,G=238,G=88,A=255)
    yellowdarken1=(R=253,G=216,G=53,A=255)
    yellowdarken2=(R=251,G=192,G=45,A=255)
    yellowdarken3=(R=249,G=168,G=37,A=255)
    yellowdarken4=(R=245,G=127,G=23,A=255)
    yellowaccent1=(R=255,G=255,G=141,A=255)
    yellowaccent2=(R=255,G=255,G=0,A=255)
    yellowaccent3=(R=255,G=234,G=0,A=255)
    yellowaccent4=(R=255,G=214,G=0,A=255)
    amber=(R=255,G=193,G=7,A=255)
    vueamber=(R=255,G=193,G=7,A=255)
    amberlighten5=(R=255,G=248,G=225,A=255)
    amberlighten4=(R=255,G=236,G=179,A=255)
    amberlighten3=(R=255,G=224,G=130,A=255)
    amberlighten2=(R=255,G=213,G=79,A=255)
    amberlighten1=(R=255,G=202,G=40,A=255)
    amberdarken1=(R=255,G=179,G=0,A=255)
    amberdarken2=(R=255,G=160,G=0,A=255)
    amberdarken3=(R=255,G=143,G=0,A=255)
    amberdarken4=(R=255,G=111,G=0,A=255)
    amberaccent1=(R=255,G=229,G=127,A=255)
    amberaccent2=(R=255,G=215,G=64,A=255)
    amberaccent3=(R=255,G=196,G=0,A=255)
    amberaccent4=(R=255,G=171,G=0,A=255)
    vueorange=(R=255,G=152,G=0,A=255)
    orangelighten5=(R=255,G=243,G=224,A=255)
    orangelighten4=(R=255,G=224,B=178,A=255)
    orangelighten3=(R=255,G=204,B=128,A=255)
    orangelighten2=(R=255,G=183,B=77,A=255)
    orangelighten1=(R=255,G=167,B=38,A=255)
    orangedarken1=(R=251,G=140,B=0,A=255)
    orangedarken2=(R=245,G=124,B=0,A=255)
    orangedarken3=(R=239,G=108,B=0,A=255)
    orangedarken4=(R=230,G=81,B=0,A=255)
    orangeaccent1=(R=255,G=209,B=128,A=255)
    orangeaccent2=(R=255,G=171,B=64,A=255)
    orangeaccent3=(R=255,G=145,B=0,A=255)
    orangeaccent4=(R=255,G=109,B=0,A=255)
    deeporange=(R=255,G=87,B=34,A=255)
    vuedeeporange=(R=255,G=87,B=34,A=255)
    deeporangelighten5=(R=251,G=233,B=231,A=255)
    deeporangelighten4=(R=255,G=204,B=188,A=255)
    deeporangelighten3=(R=255,G=171,B=145,A=255)
    deeporangelighten2=(R=255,G=138,B=101,A=255)
    deeporangelighten1=(R=255,G=112,B=67,A=255)
    deeporangedarken1=(R=244,G=81,B=30,A=255)
    deeporangedarken2=(R=230,G=74,B=25,A=255)
    deeporangedarken3=(R=216,G=67,B=21,A=255)
    deeporangedarken4=(R=191,G=54,B=12,A=255)
    deeporangeaccent1=(R=255,G=158,B=128,A=255)
    deeporangeaccent2=(R=255,G=110,B=64,A=255)
    deeporangeaccent3=(R=255,G=61,B=0,A=255)
    deeporangeaccent4=(R=221,G=44,B=0,A=255)
    vuebrown=(R=121,G=85,B=72,A=255)
    brownlighten5=(R=239,G=235,B=233,A=255)
    brownlighten4=(R=215,G=204,B=200,A=255)
    brownlighten3=(R=188,G=170,B=164,A=255)
    brownlighten2=(R=161,G=136,B=127,A=255)
    brownlighten1=(R=141,G=110,B=99,A=255)
    browndarken1=(R=109,G=76,B=65,A=255)
    browndarken2=(R=93,G=64,B=55,A=255)
    browndarken3=(R=78,G=52,B=46,A=255)
    browndarken4=(R=62,G=39,B=35,A=255)
    bluegrey=(R=96,G=125,B=139,A=255)
    vuebluegrey=(R=96,G=125,B=139,A=255)
    bluegreylighten5=(R=236,G=239,B=241,A=255)
    bluegreylighten4=(R=207,G=216,B=220,A=255)
    bluegreylighten3=(R=176,G=190,B=197,A=255)
    bluegreylighten2=(R=144,G=164,B=174,A=255)
    bluegreylighten1=(R=120,G=144,B=156,A=255)
    bluegreydarken1=(R=84,G=110,B=122,A=255)
    bluegreydarken2=(R=69,G=90,B=100,A=255)
    bluegreydarken3=(R=55,G=71,B=79,A=255)
    bluegreydarken4=(R=38,G=50,B=56,A=255)
    grey=(R=158,G=158,B=158,A=255)
    vuegrey=(R=158,G=158,B=158,A=255)
    greylighten5=(R=250,G=250,B=250,A=255)
    greylighten4=(R=245,G=245,B=245,A=255)
    greylighten3=(R=238,G=238,B=238,A=255)
    greylighten2=(R=224,G=224,B=224,A=255)
    greylighten1=(R=189,G=189,B=189,A=255)
    greydarken1=(R=117,G=117,B=117,A=255)
    greydarken2=(R=97,G=97,B=97,A=255)
    greydarken3=(R=66,G=66,B=66,A=255)
    greydarken4=(R=33,G=33,G=33,A=255)
    shortColorTag(0)=(char="0",color=(R=0,G=0,B=0,A=255))
    shortColorTag(1)=(char="1",color=(R=255,G=0,B=0,A=255))
    shortColorTag(2)=(char="2",color=(R=0,G=255,B=0,A=255))
    shortColorTag(3)=(char="3",color=(R=255,G=255,B=0,A=255))
    shortColorTag(4)=(char="4",color=(R=0,G=0,B=255,A=255))
    shortColorTag(5)=(char="5",color=(R=0,G=255,B=255,A=255))
    shortColorTag(6)=(char="6",color=(R=255,G=0,B=255,A=255))
    shortColorTag(7)=(char="7",color=(R=255,G=255,B=255,A=255))
    shortColorTag(8)=(char="8",color=(R=255,G=127,B=0,A=255))
    shortColorTag(9)=(char="9",color=(R=128,G=128,B=128,A=255))
    shortColorTag(10)=(char="r",color=(R=255,G=0,B=0,A=255))
    shortColorTag(11)=(char="g",color=(R=0,G=255,B=0,A=255))
    shortColorTag(12)=(char="b",color=(R=0,G=0,B=255,A=255))
    shortColorTag(13)=(char="p",color=(R=255,G=0,B=255,A=255))
    shortColorTag(14)=(char="y",color=(R=255,G=255,B=0,A=255))
    shortColorTag(15)=(char="o",color=(R=255,G=165,B=0,A=255))
    shortColorTag(17)=(char="c",color=(R=0,G=255,B=255,A=255))
    shortColorTag(18)=(char="w",color=(R=255,G=255,B=255,A=255))
    CODEPOINT_SMALL_A   = 97
    CODEPOINT_ESCAPE    = 27
    TRGB                    = 0
    stringConstants(0) = "rgb("
    TRGBA                   = 1
    stringConstants(1) = "rgba("
    TCLOSING_PARENTHESIS    = 2
    stringConstants(2) = ")"
    TR_COMPONENT            = 3
    stringConstants(3) = "r="
    TG_COMPONENT            = 4
    stringConstants(4) = "g="
    TB_COMPONENT            = 5
    stringConstants(5) = "b="
    TA_COMPONENT            = 6
    stringConstants(6) = "a="
    TCOMMA                  = 7
    stringConstants(7) = ","
    THASH                   = 8
    stringConstants(8) = "#"
    TDOLLAR                 = 9
    stringConstants(9) = "$"
}
