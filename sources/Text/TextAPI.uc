/**
 *      API that provides functions for working with characters and for creating
 *  `Text`, `MutableText` and `Parser` instances.
 *      Copyright 2020 - 2022 Anton Tarasenko
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
class TextAPI extends AcediaObject
    dependson(BaseText);

/**
 *  Creates a new `Formatting` structure that defines a default,
 *  "empty formatting" (no specifics about how to format text)
 *
 *  Cannot fail.
 *
 *  @return Empty formatting object.
 */
public final function BaseText.Formatting EmptyFormatting()
{
    local BaseText.Formatting emptyFormatting;
    return emptyFormatting;
}

/**
 *  Creates a new `Formatting` structure that defines a specified color.
 *
 *  Cannot fail.
 *
 *  @param  color   Color that formatting must have.
 *  @return Formatting object that describes text colored with `color`.
 */
public final function BaseText.Formatting FormattingFromColor(Color color)
{
    local BaseText.Formatting coloredFormatting;
    coloredFormatting.isColored = true;
    coloredFormatting.color = color;
    return coloredFormatting;
}

/**
 *  Checks if two `Text.Formatting` structures are the same.
 *
 *  To be considered the same both formatting must be either colorless or
 *  both have the same color.
 *
 *  @param  formatting1 Formatting to compare.
 *  @param  formatting2 Formatting to compare.
 *  @return `true` if formattings are equal and `false` otherwise.
 */
public final function bool IsFormattingEqual(
    BaseText.Formatting formatting1,
    BaseText.Formatting formatting2)
{
    if (formatting1.isColored != formatting2.isColored) {
        return false;
    }
    if (!formatting1.isColored) {
        return true;
    }
    return _.color.AreEqualWithAlpha(formatting1.color, formatting2.color);
}

/**
 *  Checks if given character is lower case.
 *
 *      Result of this method describes whether character is
 *  precisely "lower case", instead of just "not being upper of title case".
 *      That is, this method will return `true` for characters that aren't
 *  considered either lowercase or uppercase (like "#", "@" or "&").
 *
 *  @param  character   Character to test for lower case.
 *  @return `true` if given character is lower case.
 */
public final function bool IsLower(BaseText.Character character)
{
    //  Small Latin letters
    if (character.codePoint >= 97 && character.codePoint <= 122) {
        return true;
    }
    //  Small Cyrillic (Russian) letters
    if (character.codePoint >= 1072 && character.codePoint <= 1103) {
        return true;
    }
    //  `ё`
    if (character.codePoint == 1105) {
        return true;
    }
    return false;
}

/**
 *  Checks if given character is upper case.
 *
 *      Result of this method describes whether character is
 *  precisely "upper case", instead of just "not being upper of title case".
 *      That is, this method will return `true` for characters that aren't
 *  considered either uppercase or uppercase (like "#", "@" or "&").
 *
 *  @param  character   Character to test for upper case.
 *  @return `true` if given character is upper case.
 */
public final function bool IsUpper(BaseText.Character character)
{
    //  Capital Latin letters
    if (character.codePoint >= 65 && character.codePoint <= 90) {
        return true;
    }
    //  Capital Cyrillic (Russian) letters
    if (character.codePoint >= 1040 && character.codePoint <= 1071) {
        return true;
    }
    //  `Ё`
    if (character.codePoint == 1025) {
        return true;
    }
    return false;
}

/**
 *  Checks if given character corresponds to a digit.
 *
 *  @param  codePoint   Unicode code point to check for being a digit.
 *  @return `true` if given Unicode code point is a digit, `false` otherwise.
 */
public final function bool IsDigit(BaseText.Character character)
{
    if (character.codePoint >= 48 && character.codePoint <= 57) {
        return true;
    }
    return false;
}

/**
 *  Checks if given character corresponds to a latin alphabet.
 *
 *  @param  codePoint   Unicode code point to check for belonging in
 *      the alphabet.
 *  @return `true` if given Unicode code point belongs to a latin alphabet,
 *      `false` otherwise.
 */
public final function bool IsAlpha(BaseText.Character character)
{
    //  Capital Latin letters
    if (character.codePoint >= 65 && character.codePoint <= 90) {
        return true;
    }
    //  Small Latin letters
    if (character.codePoint >= 97 && character.codePoint <= 122) {
        return true;
    }
    return false;
}

/**
 *  Checks if given character is an ASCII character.
 *
 *  @param  character   Character to check for being from ASCII.
 *  @return `true` if given character is a digit, `false` otherwise.
 */
public final function bool IsASCII(BaseText.Character character)
{
    if (character.codePoint >= 0 && character.codePoint <= 127) {
        return true;
    }
    return false;
}

/**
 *  Checks if given character represents some kind of white space
 *  symbol (like space ~ 0x0020, tab ~ 0x0009, etc.),
 *  according to either Unicode or a more classic space symbol definition,
 *  that includes:
 *      whitespace, tab, line feed, line tabulation, form feed, carriage return.
 *
 *  @param  character   Character to check for being a whitespace.
 *  @return `true` if given character is a whitespace, `false` otherwise.
 */
public final function bool IsWhitespace(BaseText.Character character)
{
    switch (character.codePoint)
    {
    //  Classic whitespaces
    case 0x0020:    //  Whitespace
    case 0x0009:    //  Tab
    case 0x000A:    //  Line feed
    case 0x000B:    //  Line tabulation
    case 0x000C:    //  Form feed
    case 0x000D:    //  Carriage return
    //  Unicode Characters in the 'Separator, Space' Category
    case 0x00A0:    //  No-break space
    case 0x1680:    //  Ogham space mark
    case 0x2000:    //  En quad
    case 0x2001:    //  Em quad
    case 0x2002:    //  En space
    case 0x2003:    //  Em space
    case 0x2004:    //  Three-per-em space
    case 0x2005:    //  Four-per-em space
    case 0x2006:    //  Six-per-em space
    case 0x2007:    //  Figure space
    case 0x2008:    //  Punctuation space
    case 0x2009:    //  Thin space
    case 0x200A:    //  Hair space
    case 0x202F:    //  Narrow no-break space
    case 0x205F:    //  Medium mathematical space
    case 0x3000:    //  Ideographic space
        return true;
    default:
        return false;
    }
    return false;
}

/**
 *  Checks if passed character is one of the following quotation mark symbols:
 *      `"`, `'`, `\``.
 *
 *  @param  character   Character to check for being a quotation mark.
 *  @return `true` if given Unicode code point denotes one of the recognized
 *      quote symbols, `false` otherwise.
 */
public final function bool IsQuotationMark(BaseText.Character character)
{
    if (character.codePoint == 0x0022) return true;
    if (character.codePoint == 0x0027) return true;
    if (character.codePoint == 0x0060) return true;
    return false;
}

/**
 *  Creates a new character from a provided code point.
 *
 *  @param  codePoint   Code point that defines resulting character.
 *      Must be a valid Unicode code point.
 *  @param  formatting  Optional parameter that allows to specify resulting
 *      character's formatting. By default uses default formatting
 *      (text is not colored).
 *  @return Character defined by provided code point and, optionally,
 *      `formatting`.
 */
// TODO: Validity checks fro non-negative input code points
public final function BaseText.Character CharacterFromCodePoint(
    int                             codePoint,
    optional BaseText.Formatting    formatting)
{
    local BaseText.Character result;
    result.codePoint    = codePoint;
    result.formatting   = formatting;
    return result;
}

/**
 *  Extracts a character at position `position` from a given plain `string`.
 *
 *  For extracting multiple character or character from colored/formatted
 *  `string` we advice to convert `string` into `BaseText` instead.
 *
 *  @param  source      `string`, from which to extract the character.
 *  @param  position    Position of the character to extract, starts from `0`.
 *  @return Returns character at given position in the given source.
 *      If specified position is invalid (`< 0` or `>= Len(source)`),
 *      returns invalid character.
 */
public final function BaseText.Character GetCharacter(
    string          source,
    optional int    position)
{
    local BaseText.Character result;
    if (position < 0)               return GetInvalidCharacter();
    if (position >= Len(source))    return GetInvalidCharacter();

    result.codePoint = Asc(Mid(source, position, 1));
    return result;
}

/**
 *  Auxiliary method for checking whether `BaseText` object defines an "empty"
 *  `string`. That is, if it's either `none` or has empty contents.
 *
 *  It is added, since it allows to replace two common checks
 *  `text == none || text.IsEmpty()` with a nicer looking one:
 *  `_.text.IsEmpty(text)`.
 *
 *  @param  text    `BaseText` to check for emptiness.
 *  @return `true` iff either passed `text == none` or `text.IsEmpty()`.
 */
public final function bool IsEmpty(BaseText text)
{
    return (text == none || text.IsEmpty());
}

/**
 *  Converts given `BaseText` into a plain `string`, returns it's value and
 *  deallocates passed `BaseText`.
 *
 *  Method introduced to simplify a common use-case of converting returned copy
 *  of `BaseText` into a `string`, which required additional variable to store
 *  and later deallocate `BaseText` reference.
 *
 *  @param  toConvert   `BaseText` to convert.
 *  @return `string` representation of passed `BaseText` as a plain string.
 *      Empty `string`, if `toConvert == none`.
 */
public final function string IntoString(/*take*/ BaseText toConvert)
{
    local string result;
    if (toConvert != none) {
        result = toConvert.ToString();
    }
    _.memory.Free(toConvert);
    return result;
}

/**
 *  Converts given `BaseText` into a colored `string`, returns it's value and
 *  deallocates passed `BaseText`.
 *
 *  Method introduced to simplify a common use-case of converting returned copy
 *  of `BaseText` into a `string`, which required additional variable to store
 *  and later deallocate `BaseText` reference.
 *
 *  @param  toConvert   `BaseText` to convert.
 *  @return `string` representation of passed `BaseText` as a colored `string`.
 *      Empty `string`, if `toConvert == none`.
 */
public final function string IntoColoredString(/*take*/ BaseText toConvert)
{
    local string result;
    if (toConvert != none) {
        result = toConvert.ToColoredString();
    }
    _.memory.Free(toConvert);
    return result;
}

/**
 *  Converts given `BaseText` into a formatted `string`, returns it's value and
 *  deallocates passed `BaseText`.
 *
 *  Method introduced to simplify a common use-case of converting returned copy
 *  of `BaseText` into a `string`, which required additional variable to store
 *  and later deallocate `BaseText` reference.
 *
 *  @param  toConvert   `BaseText` to convert.
 *  @return `string` representation of passed `BaseText` as a formatted `string`.
 *      Empty `string`, if `toConvert == none`.
 */
public final function string IntoFormattedString(/*take*/ BaseText toConvert)
{
    local string result;
    if (toConvert != none) {
        result = toConvert.ToFormattedString();
    }
    _.memory.Free(toConvert);
    return result;
}

/**
 *  Creates a `string` that consists only of a given character.
 *
 *  @param  character   Character that will be converted into a string.
 *  @return `string` that consists only of a given character,
 *      if given character is valid. Empty `string` otherwise.
 */
public final function string CharacterToString(BaseText.Character character)
{
    if (!IsValidCharacter(character)) {
        return "";
    }
    return Chr(character.codePoint);
}

/**
 *  Converts given character into a number it represents in some base
 *  (from 2 to 36), i.e.:
 *  1 -> 1
 *  7 -> 7
 *  a -> 10
 *  e -> 14
 *  z -> 35
 *
 *  @param  character   Character to convert into integer.
 *      Case does not matter, i.e. "a" and "A" will be treated the same.
 *  @param  base        Base to use for conversion.
 *      Valid values are from `2` to `36` (inclusive);
 *      If invalid value was specified (such as default `0`),
 *      the base of `36` is assumed, since that would allow for all possible
 *      characters to be converted.
 *  @return Positive integer value that is denoted by
 *      given character in given base;
 *      `-1` if given character does not represent anything in the given base.
 */
public final function int CharacterToInt(
    BaseText.Character  character,
    optional int    base
)
{
    local int number;
    if (base < 2 || base > 36) {
        base = 36;
    }
    character = ToLower(character);
    //  digits
    if (character.codePoint >= 0x0030 && character.codePoint <= 0x0039) {
        number = character.codePoint - 0x0030;
    }
    //  a-z
    else if (character.codePoint >= 0x0061 && character.codePoint <= 0x007a) {
        number = character.codePoint - 0x0061 + 10;
    }
    else {
        return -1;
    }
    if (number >= base) {
        return -1;
    }
    return number;
}

/**
 *  Checks if given `character` can be represented by a given `codePoint` in
 *  Unicode standard.
 *
 *  @param  character   Character to check.
 *  @param  codePoint   Code point to check.
 *  @return `true` if given character can be represented by a given code point
 *      and `false` otherwise.
 */
public final function bool IsCodePoint(
    BaseText.Character  character,
    int                 codePoint)
{
    return (character.codePoint == codePoint);
}

/**
 *  Extracts formatting of the given character.
 *
 *  @param  character   Character to get formatting of.
 *  @return Returns formatting of the given character.
 *      Always returns 'null' (not colored) formatting for invalid characters.
 */
public final function BaseText.Formatting GetCharacterFormatting(
    BaseText.Character character)
{
    local BaseText.Formatting emptyFormatting;
    if(IsValidCharacter(character)) {
        return character.formatting;
    }
    return emptyFormatting;
}

/**
 *  Changes formatting of a given character.
 *
 *  @param  character       Character to change formatting of.
 *  @param  newFormatting   New formatting to set.
 *  @return Same character as `character`, but with new formatting.
 *      Invalid characters are not altered.
 */
public final function BaseText.Character SetFormatting(
    BaseText.Character  character,
    BaseText.Formatting newFormatting)
{
    if(!IsValidCharacter(character)) {
        return character;
    }
    character.formatting = newFormatting;
    return character;
}

/**
 *  Returns color of a given `Character` with set default color.
 *
 *  `Character`s can have their color set to "default", meaning they would use
 *  whatever considered default color in the context.
 *
 *  @param  character       `Character`, which color to return.
 *  @param  defaultColor    Color, considered default.
 *  @return Supposed color of a given `Character`, assuming default color is
 *      `defaultColor`.
 */
public final function Color GetCharacterColor(
    BaseText.Character  character,
    optional Color      defaultColor)
{
    if (character.formatting.isColored) {
        return character.formatting.color;
    }
    return defaultColor;
}

/**
 *  Returns character that is considered invalid.
 *
 *  It is not unique, there can be different invalid characters.
 *
 *  @return Invalid character instance.
 */
public final function BaseText.Character GetInvalidCharacter()
{
    local BaseText.Character result;
    result.codePoint = -1;
    return result;
}

/**
 *  Checks if given character is invalid.
 *
 *  @param  character   Character to check.
 *  @return `true` if passed character is valid and `false` otherwise.
 */
public final function bool IsValidCharacter(BaseText.Character character)
{
    return (character.codePoint >= 0);
}

/**
 *  Checks if given characters are equal, with or without accounting
 *  for their case.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *      Invalid characters are always considered equal to each other
 *  (precise value of their `codePoint` or `formatting` is irrelevant).
 *
 *  @param  codePoint1          Character to compare.
 *  @param  codePoint2          Character to compare.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if given characters are considered equal,
 *      `false` otherwise.
 */
public final function bool AreEqual(
    BaseText.Character                  character1,
    BaseText.Character                  character2,
    optional BaseText.CaseSensitivity   caseSensitivity,
    optional BaseText.FormatSensitivity formatSensitivity
)
{
    //  These handle checks with invalid characters
    if (character1.codePoint < 0 && character2.codePoint < 0)   return true;
    if (character1.codePoint < 0 || character2.codePoint < 0)   return false;

    if (caseSensitivity == SCASE_INSENSITIVE)
    {
        character1 = ToLower(character1);
        character2 = ToLower(character2);
    }
    if (    formatSensitivity == SFORM_SENSITIVE
        &&  !IsFormattingEqual(character1.formatting, character2.formatting))
    {
        return false;
    }
    return (character1.codePoint == character2.codePoint);
}

/**
 *  Converts Unicode code point into its lower case folding,
 *  as defined by Unicode standard.
 *
 *  @param  codePoint   Code point to convert into lower case.
 *  @return Lower case folding of the given code point. If Unicode standard does
 *  not define any lower case folding (like "&" or "!") for given code point, -
 *  function returns given code point unchanged.
 */
public final function BaseText.Character ToLower(BaseText.Character character)
{
    local int newCodePoint;
    newCodePoint =
        class'UnicodeData'.static.ToLowerCodePoint(character.codePoint);
    if (newCodePoint >= 0) {
        character.codePoint = newCodePoint;
    }
    return character;
}

/**
 *  Converts Unicode code point into it's upper case version,
 *  as defined by Unicode standard.
 *
 *  @param  codePoint   Code point to convert into upper case.
 *  @return Upper case version of the given code point. If Unicode standard does
 *  not define any upper case version (like "&" or "!") for given code point, -
 *  function returns given code point unchanged.
 */
public final function BaseText.Character ToUpper(BaseText.Character character)
{
    local int newCodePoint;
    newCodePoint =
        class'UnicodeData'.static.ToUpperCodePoint(character.codePoint);
    if (newCodePoint >= 0) {
        character.codePoint = newCodePoint;
    }
    return character;
}

/**
 *      Prepares an array of parts from a given single `BaseText`.
 *      First character is treated as a separator with which the rest of
 *  the given `BaseText` is split into parts:
 *      ~ "/ab/c/d" => ["ab", "c", "d"]
 *      ~ "zWordzomgzz" => ["Word", "omg", "", ""]
 *
 *  This method is useful to easily prepare array of words for `Parser`'s
 *  methods.
 *
 *  @param  source  `BaseText` that contains separator with parts to
 *      separate and extract.
 *  @return Separated words. Empty array if passed `source` was empty,
 *      otherwise contains at least one element.
 */
public final function array<BaseText> Parts(BaseText source)
{
    local array<BaseText> result;
    if (source == none)             return result;
    if (source.GetLength() <= 0)    return result;
    result = source.SplitByCharacter(source.GetCharacter(0),, true);
    //  Since we use first character as a separator:
    //      1. `result` is guaranteed to be non-empty;
    //      2. We can just drop first (empty) substring.
    result[0].FreeSelf();
    result.Remove(0, 1);
    return result;
}

/**
 *      Prepares an array of parts from a given single `BaseText`.
 *      First character is treated as a separator with which the rest of
 *  the given `BaseText` is split into parts:
 *      ~ "/ab/c/d" => ["ab", "c", "d"]
 *      ~ "zWordzomgzz" => ["Word", "omg", "", ""]
 *
 *  This method is useful to easily prepare array of words for `Parser`'s
 *  methods.
 *
 *  @param  source  `string` that contains separator with parts to
 *      separate and extract.
 *  @return Separated words. Empty array if passed `source` was empty,
 *      otherwise contains at least one element.
 */
public final function array<BaseText> PartsS(string source)
{
    local MutableText       wrapper;
    local array<BaseText>   result;
    wrapper = _.text.FromStringM(source);
    result = Parts(wrapper);
    _.memory.Free(wrapper);
    return result;
}

/**
 *  Creates and initializes with `source` new `TextTemplate` instance.
 *
 *  @param  source  Data to initialize new `TextTemplate` with.
 *  @return `TextTemplate` based on `source`.
 *      `none` if given `source` is `none`.
 */
public final function TextTemplate MakeTemplate(BaseText source)
{
    local TextTemplate newTemplate;
    if (source == none) {
        return none;
    }
    newTemplate = TextTemplate(_.memory.Allocate(class'TextTemplate'));
    newTemplate.Initialize(source);
    return NewTemplate;
}

/**
 *  Creates and initializes with `source` new `TextTemplate` instance.
 *
 *  @param  source  Data to initialize new `TextTemplate` with.
 *  @return `TextTemplate` based on `source`.
 *      `none` if given `source` is `none`.
 */
public final function TextTemplate MakeTemplate_S(string source)
{
    local MutableText   wrapper;
    local TextTemplate  result;
    wrapper = FromStringM(source);
    result = MakeTemplate(wrapper);
    _.memory.Free(wrapper);
    return result;
}

/**
 *  Creates a new, empty `MutableText`.
 *
 *  This is a shortcut, same result can be achieved by
 *  `_.memory.Allocate(class'MutableText')`.
 *
 *  @return new instance of `Text` with empty contents.
 */
public final function MutableText Empty()
{
    return MutableText(_.memory.Allocate(class'MutableText'));
}

/**
 *  Creates a `Text` that will contain a given plain `string`.
 *
 *  To create `MutableText` instead use `FromStringM()` method.
 *
 *  @param  source  Plain `string` that will be copied into returned `Text`.
 *  @return New instance of `Text` that will contain passed plain `string`.
 */
public final function Text FromString(string source)
{
    local MutableText   builder;
    local Text          result;
    builder = MutableText(_.memory.Allocate(class'MutableText'));
    result = builder.AppendString(source).Copy();
    builder.FreeSelf();
    return result;
}

/**
 *  Creates a `MutableText` that will contain a given plain `string`.
 *
 *  To create immutable `Text` instead use `FromString()` method.
 *
 *  @param  source  Plain `string` that will be copied into
 *      returned `MutableText`.
 *  @return New instance of `MutableText` that will contain passed
 *      plain `string`.
 */
public final function MutableText FromStringM(string source)
{
    local MutableText newText;
    newText = MutableText(_.memory.Allocate(class'MutableText'));
    return newText.AppendString(source);
}

/**
 *  Creates a `Text` that will contain a given colored `string`.
 *
 *  To create `MutableText` instead use `FromColoredStringM()` method.
 *
 *  @param  source  Colored `string` that will be copied into returned `Text`.
 *  @return New instance of `Text` that will contain passed colored `string`.
 */
public final function Text FromColoredString(string source)
{
    local MutableText   builder;
    local Text          result;
    builder = MutableText(_.memory.Allocate(class'MutableText'));
    result = builder.AppendColoredString(source).Copy();
    builder.FreeSelf();
    return result;
}

/**
 *  Creates a `MutableText` that will contain a given colored `string`.
 *
 *  To create immutable `Text` instead use `FromColoredString()` method.
 *
 *  @param  source  Colored `string` that will be copied into
 *      returned `MutableText`.
 *  @return New instance of `MutableText` that will contain passed
 *      colored `string`.
 */
public final function MutableText FromColoredStringM(string source)
{
    local MutableText newText;
    newText = MutableText(_.memory.Allocate(class'MutableText'));
    return newText.AppendColoredString(source);
}

/**
 *  Creates a `Text` that will contain a parsed formatted string inside
 *  the given `BaseText`.
 *
 *  To create `MutableText` instead use `FromFormattedM()` method.
 *
 *  @param  source  Formatted string inside `Text` that will be parsed into
 *      returned `Text`.
 *  @return New instance of `Text` that will contain parsed formatted `source`.
 */
public final function Text FromFormatted(BaseText source)
{
    local MutableText   builder;
    local Text          result;
    if (source == none) {
        return none;
    }
    builder = MutableText(_.memory.Allocate(class'MutableText'));
    result = builder.AppendFormatted(source).Copy();
    builder.FreeSelf();
    return result;
}

/**
 *  Creates a `MutableText` that will contain a parsed formatted string inside
 *  the given `BaseText`.
 *
 *  To create `Text` instead use `FromFormatted()` method.
 *
 *  @param  source  Formatted string inside `Text` that will be parsed into
 *      returned `Text`.
 *  @return New instance of `MutableText` that will contain parser formatted
 *      `source`.
 */
public final function MutableText FromFormattedM(BaseText source)
{
    local MutableText newText;
    if (source == none) {
        return none;
    }
    newText = MutableText(_.memory.Allocate(class'MutableText'));
    return newText.AppendFormatted(source);
}

/**
 *  Creates a `Text` that will contain parsed formatted `string`.
 *
 *  To create `MutableText` instead use `FromFormattedStringM()` method.
 *
 *  @param  source  Formatted `string` that will be copied into returned `Text`.
 *  @return New instance of `Text` that will contain parsed formatted `string`.
 */
public final function Text FromFormattedString(string source)
{
    local MutableText   builder;
    local Text          result;
    builder = MutableText(_.memory.Allocate(class'MutableText'));
    result = builder.AppendFormattedString(source).Copy();
    builder.FreeSelf();
    return result;
}

/**
 *  Creates a `MutableText` that will contain parsed formatted `string`.
 *
 *  To create immutable `Text` instead use `FromFormattedString()` method.
 *
 *  @param  source  Formatted `string` that will be copied into
 *      returned `MutableText`.
 *  @return New instance of `MutableText` that will contain parsed
 *      formatted `string`.
 */
public final function MutableText FromFormattedStringM(string source)
{
    local MutableText newText;
    newText = MutableText(_.memory.Allocate(class'MutableText'));
    return newText.AppendFormattedString(source);
}

/**
 *  Method for creating a new, uninitialized parser object.
 *
 *  This is a shortcut, same result can be achieved by
 *  `_.memory.Allocate(class'Parser')`.
 *
 *  @return New, uninitialized `Parser`.
 */
public final function Parser NewParser()
{
    return Parser(_.memory.Allocate(class'Parser'));
}

/**
 *  Method for creating a new parser, initialized with contents of given
 *  `BaseText`.
 *
 *  @param  source  Returned `Parser` will be setup to parse the contents of
 *      the passed `BaseText`.
 *      If `none` value is passed, - parser won't be initialized.
 *  @return Guaranteed to be not `none` and contain a valid `Parser`.
 *      If passed argument also is not `none`, - guaranteed to be
 *      initialized with it's content.
 */
public final function Parser Parse(BaseText source)
{
    local Parser parser;
    parser = NewParser();
    parser.Initialize(source);
    return parser;
}

/**
 *  Method for creating a new parser, initialized with a given plain `string`.
 *
 *  @param  source  Returned `Parser` will be setup to parse this
 *      plain `string`.
 *  @return Guaranteed to be not `none` and contain a valid `Parser`,
 *      initialized with contents of a `source` (treated as a plain `string`).
 */
public final function Parser ParseString(string source)
{
    local Parser parser;
    parser = NewParser();
    parser.InitializeS(source);
    return parser;
}

/**
 *  Creates a `Text` that consists only of a given character.
 *
 *  @param  character   Character that will be converted into a string.
 *  @return `Text` that consists only of a given character,
 *      if given character is valid. Empty `Text` otherwise.
 *      Guaranteed to be not `none`.
 */
public final function Text FromCharacter(BaseText.Character character)
{
    return _.text.FromString(CharacterToString(character));
}

/**
 *  Method for converting `bool` values into immutable `Text`.
 *
 *  To create `MutableText` instead use `FromBoolM()` method.
 *
 *  @param  value   `bool` value to be displayed as `Text`.
 *  @return Text representation of given `bool` value.
 */
public final function Text FromBool(bool value)
{
    if (value) {
        return P("true").Copy();
    }
    return P("false").Copy();
}

/**
 *  Method for converting `bool` values into mutable `MutableText`.
 *
 *  To create `Text` instead use `FromBool()` method.
 *
 *  @param  value   `bool` value to be displayed as `MutableText`.
 *  @return Text representation of given `bool` value.
 */
public final function MutableText FromBoolM(bool value)
{
    if (value) {
        return P("true").MutableCopy();
    }
    return P("false").MutableCopy();
}

/**
 *  Method for converting `byte` values into immutable `Text`.
 *
 *  To create `MutableText` instead use `FromByteM()` method.
 *
 *  @param  value   `byte` value to be displayed as `Text`.
 *  @return Text representation of given `byte` value.
 */
public final function Text FromByte(byte value)
{
    return FromString(string(value));
}

/**
 *  Method for converting `byte` values into mutable `MutableText`.
 *
 *  To create `Text` instead use `FromByte()` method.
 *
 *  @param  value   `byte` value to be displayed as `MutableText`.
 *  @return Text representation of given `byte` value.
 */
public final function MutableText FromByteM(byte value)
{
    return FromStringM(string(value));
}

/**
 *  Method for converting `int` values into immutable `Text`.
 *
 *  To create `MutableText` instead use `FromIntM()` method.
 *
 *  @param  value   `int` value to be displayed as `Text`.
 *  @return Text representation of given `int` value.
 */
public final function Text FromInt(int value)
{
    return FromString(string(value));
}

/**
 *  Method for converting `int` values into mutable `MutableText`.
 *
 *  To create `Text` instead use `FromInt()` method.
 *
 *  @param  value   `int` value to be displayed as `MutableText`.
 *  @return Text representation of given `int` value.
 */
public final function MutableText FromIntM(int value)
{
    return FromStringM(string(value));
}

/**
 *  Method for converting `class<object>` values into immutable `Text`.
 *
 *  To create `MutableText` instead use `FromClassM()` method.
 *
 *  @param  value   `class<object>` value to be displayed as `Text`.
 *  @return Text representation of given `class<object>` value.
 */
public final function Text FromClass(class<object> value)
{
    return FromString(string(value));
}

/**
 *  Method for converting `class<Object>` values into mutable `MutableText`.
 *
 *  To create `Text` instead use `FromClass()` method.
 *
 *  @param  value   `class<Object>` value to be displayed as `MutableText`.
 *  @return Text representation of given `class<Object>` value.
 */
public final function MutableText FromClassM(class<Object> value)
{
    return FromStringM(string(value));
}

/**
 *  Method for converting `float` values into immutable `Text`.
 *
 *  To create `MutableText` instead use `FromFloatM()` method.
 *
 *  @param  value       `float` value to be displayed as `Text`.
 *  @param  precision   Up to how many digits after the decimal point to
 *      display in resulting `Text`. If `0` (default value) is passed - method
 *      will use native `float` conversion that usually specifies up to
 *      2 digits. To render number without any digits after the decimal point,
 *      specify any negative precision as a value.
 *  @return Text representation of given `float` value.
 */
public final function Text FromFloat(float value, optional int precision)
{
    return FromString(FloatToString(value, precision));
}

/**
 *  Method for converting `float` values into mutable `MutableText`.
 *
 *  To create `Text` instead use `FromFloat()` method.
 *
 *  @param  value       `float` value to be displayed as `MutableText`.
 *  @param  precision   Up to how many digits after the decimal point to
 *      display in resulting `MutableText`. If `0` (default value) is passed -
 *      method will use native `float` conversion that usually specifies up to
 *      2 digits. To render number without any digits after the decimal point,
 *      specify any negative precision as a value.
 *  @return Text representation of given `float` value.
 */
public final function MutableText FromFloatM(
    float           value,
    optional int    precision)
{
    return FromStringM(FloatToString(value, precision));
}

//  Auxiliary method that does `float` into `string` conversion to later
//  reassemble it into `Text` / `MutableText`. Likely to be replaced later.
private final function string FloatToString(float value, optional int precision)
{
    local int       integerPart, fractionalPart;
    local int       howManyZeroes;
    local string    zeroes;
    local string    result;
    //  Special cases of: native `float` -> `string` conversion
    //  and of displaying `float`, effectively, as an `int`
    if (precision == 0) {
        return string(value);
    }
    if (precision < 0) {
        return string(int(Round(value)));
    }
    //  Display sign if needed and then the absolute value of the `value`
    if (value < 0)
    {
        value *= -1;
        result = "-";
    }
    //  Separate integer and fractional parts
    integerPart = value;
    value = (value - integerPart);
    fractionalPart = Round(value * (10 ** precision));
    //  Display integer & fractional parts (if latter even needed)
    result $= string(integerPart);
    if (fractionalPart <= 0) {
        return result;
    }
    result $= ".";
    //  Pad necessary zeroes in front
    howManyZeroes = precision - CountDigits(fractionalPart);
    while (howManyZeroes > 0)
    {
        zeroes $= "0";
        howManyZeroes -= 1;
    }
    //  Cut off trailing zeroes from fractional part
    while (fractionalPart > 0 && fractionalPart % 10 == 0) {
        fractionalPart /= 10;
    }
    return result $ zeroes $ string(fractionalPart);
}

//  Auxiliary method that counts amount of digits in decimal representation
//  of `number`.
private final function int CountDigits(int number)
{
    local int digitCounter;
    while (number > 0)
    {
        number -= (number % 10);
        number /= 10;
        digitCounter += 1;
    }
    return digitCounter;
}

defaultproperties
{
}