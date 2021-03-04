/**
 *      Acedia's implementation of an immutable text (string) object.
 *  Since it is not native class, it has additional costs for it's creation and
 *  some of it operations, but it:
 *      1.  Supports a more convenient (than native 4-byte color sequences)
 *          storing of format information and allows to extract `string`s with
 *          or without formatting. Including Acedia's own, more human-readable
 *          way to define string formatting.
 *      2.  Stores `string`s disassembled into Unicode code points, potentially
 *          allowing fast implementation of operations that require such
 *          a representation (e.g. faster hash calculation was implemented).
 *      3.  Provides an additional layer of abstraction that can potentially
 *          allow for an improved Unicode support.
 *      Copyright 2020 - 2021 Anton Tarasenko
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
class Text extends AcediaObject;

//      Enumeration that describes how should we treat `Text`s that differ in
//  case only.
//      By default we would consider them unequal.
enum CaseSensitivity
{
    SCASE_SENSITIVE,
    SCASE_INSENSITIVE
};

//      Enumeration that describes how should we treat `Text`s that differ only
//  in their formatting.
//      By default we would consider them unequal.
enum FormatSensitivity
{
    SFORM_INSENSITIVE,
    SFORM_SENSITIVE
};

//  Describes text formatting, can be applied per-character.
struct Formatting
{
    //  Whether this formatting describes a color of the text
    var bool    isColored;
    //  Color of the text, used only when `isColored == true`
    var Color   color;
};

//  Represents one character, together with it's formatting
struct Character
{
    var int             codePoint;
    var Formatting      formatting;
};

//  Actual content of the `Text` is stored as a sequence of Unicode code points.
var private array<int> codePoints;
//  Structure for inner use, describes a change of formatting to `formatting`,
//  starting from index `startIndex`
struct FormattingChunk
{
    var private int         startIndex;
    var private Formatting  formatting;
};
//      Series of `FormattingChunk` that defines formatting over characters,
//  defined by `codePoints`.
//      This array is sorted by `startIndex` of it's elements and
//  formatting for character at <index> is defined by the `FormattingChunk`
//  with the largest `startIndex <= <index>`.
var private array<FormattingChunk>  formattingChunks;
//      To optimize look up of formatting for characters we remember index of
//  the last used `FormattingChunk` to attempt to start the next lookup
//  from that point.
//      This improves performance when several lookups are done in order.
var private int                     formattingIndexCache;

/*
 *      Even though `Text` is an immutable object, for child classes we
 *  encapsulate direct access to `codePoints` by providing a way to append
 *  new data to it's content through protected methods.
 *      For that we implement `AppendCodePoint()` and `AppendManyCodePoints()`
 *  methods that allow to add code points 1-by-1.
 *  To reduce the amount of checks, formatting is set not per-code point,
 *  but separately by `SetFormatting()`: to append a group of code points with
 *  a certain formatting one has to first set their formatting,
 *  then just add code points.
 */
//  Formatting to use for the next code point
var private Formatting  nextFormatting;
//  `true` if the next code point will have a different formatting from
//  the last added one.
var private bool        formattingUpdated;

//  Escape code point is used to change output's color and is used in
//  Unreal Engine's `string`s.
var protected const int     CODEPOINT_ESCAPE;
//  Opening and closing symbols for colored blocks in formatted strings.
var protected const int     CODEPOINT_OPEN_FORMAT;
var protected const int     CODEPOINT_CLOSE_FORMAT;
var protected const string  STRING_OPEN_FORMAT;
var protected const string  STRING_CLOSE_FORMAT;
//  Symbol for separating opening formatting block from it's contents
var protected const string  STRING_SEPARATOR_FORMAT;
//  Symbol to escape any character in formatted strings,
//  including above mentioned opening and closing symbols.
var protected const int     CODEPOINT_FORMAT_ESCAPE;
var protected const string  STRING_FORMAT_ESCAPE;

//  Simply free all used memory.
protected function Finalizer()
{
    codePoints.length       = 0;
    formattingChunks.length = 0;
}

/**
 *  Static method for creating an immutable `Text` object from (plain) `string`.
 *
 *  It is preferred to use `TextAPI` methods for creating `Text` instances.
 *
 *  @param  source  Plain `string` to convert into `Text`.
 *  @return `Text` instance (guaranteed to be not `none`) that stores contents
 *      of `source` if treated as a plain `string`.
 */
public static final function Text ConstFromPlainString(string source)
{
    local MutableText   builder;
    local Text          result;
    builder = MutableText(__().memory.Allocate(class'MutableText'));
    result = builder.AppendPlainString(source).Copy();
    builder.FreeSelf();
    return result;
}

/**
 *  Static method for creating an immutable `Text` object from
 *  (colored) `string`.
 *
 *  It is preferred to use `TextAPI` methods for creating `Text` instances.
 *
 *  @param  source  Colored `string` to convert into `Text`.
 *  @return `Text` instance (guaranteed to be not `none`) that stores contents
 *      of `source` if treated as a colored `string`.
 */
public static final function Text ConstFromColoredString(string source)
{
    local MutableText   builder;
    local Text          result;
    builder = MutableText(__().memory.Allocate(class'MutableText'));
    result = builder.AppendColoredString(source).Copy();
    builder.FreeSelf();
    return result;
}

/**
 *  Static method for creating an immutable `Text` object from
 *  (formatted) `string`.
 *
 *  It is preferred to use `TextAPI` methods for creating `Text` instances.
 *
 *  @param  source  Formatted `string` to convert into `Text`.
 *  @return `Text` instance (guaranteed to be not `none`) that stores contents
 *      of `source` if treated as a formatted `string`.
 */
public static final function Text ConstFromFormattedString(string source)
{
    local MutableText   builder;
    local Text          result;
    builder = MutableText(__().memory.Allocate(class'MutableText'));
    result = builder.AppendFormattedString(source).Copy();
    builder.FreeSelf();
    return result;
}

/**
 *  Makes an immutable copy (`class'Text'`) of the caller `Text`.
 *
 *  If provided parameters `startPosition` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startPosition   Position of the first character to copy.
 *      By default `0`, corresponding to the very first character.
 *  @param  maxLength       Max length of the extracted string. By default `0`,
 *      - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a string as possible.
 *  @return Immutable copy of the caller `Text` instance.
 *      Guaranteed to be not `none` and have class `Text`.
 */
public final function Text Copy(
    optional int startIndex,
    optional int maxLength)
{
    //  `startIndex` is inclusive and `endIndex` is not
    local int       i, endIndex;
    local Text      copy;
    local Character nextCharacter;
    if (maxLength <= 0) {
        maxLength = codePoints.length;
    }
    endIndex = startIndex + maxLength;
    copy = Text(_.memory.Allocate(class'Text'));
    //  Edge cases
    if (endIndex <= 0) {
        return copy;
    }
    if (startIndex <= 0 && maxLength >= startIndex + codePoints.length)
    {
        copy.codePoints         = codePoints;
        copy.formattingChunks   = formattingChunks;
        return copy;
    }
    //  Substring copy
    if (startIndex < 0) {
        startIndex = 0;
    }
    endIndex = Min(endIndex, codePoints.length);
    for (i = startIndex; i < endIndex; i += 1)
    {
        nextCharacter = GetCharacter(i);
        copy.SetFormatting(nextCharacter.formatting);
        copy.AppendCodePoint(nextCharacter.codePoint);
    }
    return copy;
}

/**
 *  Makes a mutable copy (`class'MutableText'`) of the caller text instance.
 *
 *  If provided parameters `startPosition` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startPosition   Position of the first character to copy.
 *      By default `0`, corresponding to the very first character.
 *  @param  maxLength       Max length of the extracted string. By default `0`,
 *      - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a string as possible.
 *  @return Mutable copy of the caller `Text` instance.
 *      Guaranteed to be not `none` and have class `MutableText`.
 */
public final function MutableText MutableCopy(
    optional int startIndex,
    optional int maxLength)
{
    //  `startIndex` is inclusive and `endIndex` is not
    local int           i, endIndex;
    local MutableText   copy;
    if (maxLength <= 0) {
        maxLength = codePoints.length;
    }
    endIndex = startIndex + maxLength;
    copy = MutableText(_.memory.Allocate(class'MutableText'));
    //  Edge cases
    if (endIndex <= 0 || startIndex >= codePoints.length) {
        return copy;
    }
    if (startIndex <= 0 && maxLength >= startIndex + codePoints.length)
    {
        copy.codePoints         = codePoints;
        copy.formattingChunks   = formattingChunks;
        return copy;
    }
    //  Substring copy
    if (startIndex < 0) {
        startIndex = 0;
    }
    endIndex = Min(endIndex, codePoints.length);
    for (i = startIndex; i < endIndex; i += 1) {
        copy.AppendCharacter(GetCharacter(i));
    }
    return copy;
}

/**
 *  Makes an immutable copy (`class'Text'`) of the caller `Text`
 *  in a lower case.
 *
 *  If provided parameters `startPosition` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startPosition   Position of the first character to copy.
 *      By default `0`, corresponding to the very first character.
 *  @param  maxLength       Max length of the extracted string. By default `0`,
 *      - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a string as possible.
 *  @return Immutable copy of caller `Text` in a lower case.
 *      Guaranteed to be not `none` and have class `Text`.
 */
public final function Text LowerCopy(
    optional int startIndex,
    optional int maxLength)
{
    local Text textCopy;
    textCopy = Copy(startIndex, maxLength);
    textCopy.ConvertCase(true);
    return textCopy;
}

/**
 *  Makes an immutable copy (`class'Text'`) of the caller `Text`
 *  in a upper case.
 *
 *  If provided parameters `startPosition` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startPosition   Position of the first character to copy.
 *      By default `0`, corresponding to the very first character.
 *  @param  maxLength       Max length of the extracted string. By default `0`,
 *      - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a string as possible.
 *  @return Immutable copy of caller `Text` in a upper case.
 *      Guaranteed to be not `none` and have class `Text`.
 */
public final function Text UpperCopy(
    optional int startIndex,
    optional int maxLength)
{
    local Text textCopy;
    textCopy = Copy(startIndex, maxLength);
    textCopy.ConvertCase(false);
    return textCopy;
}

/**
 *  Makes a mutable copy (`class'MutableText'`) of the caller text instance
 *  in lower case.
 *
 *  If provided parameters `startPosition` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startPosition   Position of the first character to copy.
 *      By default `0`, corresponding to the very first character.
 *  @param  maxLength       Max length of the extracted string. By default `0`,
 *      - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a string as possible.
 *  @return Mutable copy of caller `Text` instance in lower case.
 *      Guaranteed to be not `none` and have class `MutableText`.
 */
public final function MutableText LowerMutableCopy(
    optional int startIndex,
    optional int maxLength)
{
    local MutableText textCopy;
    textCopy = MutableCopy(startIndex, maxLength);
    textCopy.ConvertCase(true);
    return textCopy;
}

/**
 *  Makes a mutable copy (`class'MutableText'`) of the caller text instance
 *  in upper case.
 *
 *  If provided parameters `startPosition` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startPosition   Position of the first character to copy.
 *      By default `0`, corresponding to the very first character.
 *  @param  maxLength       Max length of the extracted string. By default `0`,
 *      - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a string as possible.
 *  @return Mutable copy of caller `Text` instance in upper case.
 *      Guaranteed to be not `none` and have class `MutableText`.
 */
public final function MutableText UpperMutableCopy(
    optional int startIndex,
    optional int maxLength)
{
    local MutableText textCopy;
    textCopy = MutableCopy(startIndex, maxLength);
    textCopy.ConvertCase(false);
    return textCopy;
}

/**
 *  Auxiliary function that converts case of the caller `Text` object.
 *  As `Text` is supposed to be immutable, cannot be public.
 *
 *  @param  toLower `true` if caller `Text` must be converted to the lower case
 *      and `false` otherwise.
 */
protected final function ConvertCase(bool toLower)
{
    local int i;
    local Character nextCharacter;
    for (i = 0; i < GetLength(); i += 1)
    {
        nextCharacter = GetCharacter(i);
        if (toLower) {
            nextCharacter = _.text.ToLower(nextCharacter);
        }
        else {
            nextCharacter = _.text.ToUpper(nextCharacter);
        }
        codePoints[i] = nextCharacter.codePoint;
    }
}

/**
 *  Calculates hash value of the caller `Text`. Hash will depend only on
 *  it's textual contents, without taking formatting (color information)
 *  into account.
 *
 *  @return Hash, that depends on textual contents only.
 */
protected function int CalculateHashCode()
{
    local int i;
    local int hash;
    //  Manually inline `CombineHash()`, to avoid too many calls
    //  (and infinite loop detection) for some long text data.
    hash = 5381;
    for (i = 0; i < codePoints.length; i += 1)
    {
        //  hash * 33 + codePoints[i]
        hash = ((hash << 5) + hash) + codePoints[i];
    }
    return hash;
}

/**
 *  Checks whether contents of the caller `Text` are empty.
 *
 *  @return `true` if caller `Text` contains no symbols.
 */
public final function bool IsEmpty()
{
    return (codePoints.length == 0);
}

/**
 *  Returns current length of the caller `Text` in symbols.
 *
 *  Do note that codepoint is not the same as a symbol, since one symbol
 *  can consist of several code points. While current implementation only
 *  supports symbols represented by a single code point, this might change
 *  in the future.
 *
 *  @return Current length of caller `Text`'s contents in symbols.
 */
public final function int GetLength()
{
    return codePoints.length;
}

/**
 *      Override equality check for `Text` to make two different `Text`s equal
 *  based on their text contents.
 *      Text equality check is case-sensitive and does not take formatting
 *  into account.
 *
 *  `Text` cannot be equal to object of any class that is not
 *  derived from `Text`.
 *
 *  @param  other   Object to compare to the caller.
 *      `none` is only equal to the `none`.
 *  @return `true` if `other` is considered equal to the caller `Text`,
 *      `false` otherwise.
 */
public function bool IsEqual(Object other)
{
    if (self == other) {
        return true;
    }
    return Compare(Text(other));
}

//      "Normalizes" code point for comparison by converting it to lower case if
//  `caseSensitivity == SCASE_INSENSITIVE`.
//      Otherwise returns same code point.
private final function int NormalizeCodePoint(
    int             codePoint,
    CaseSensitivity caseSensitivity)
{
    local int newCodePoint;
    if (caseSensitivity == SCASE_INSENSITIVE) {
        newCodePoint = class'UnicodeData'.static.ToLowerCodePoint(codePoint);
    }
    else {
        newCodePoint = codePoint;
    }
    if (newCodePoint < 0) {
        return codePoint;
    }
    return newCodePoint;
}

/**
 *  Method for checking equality between the caller and another `Text` object.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *  @param  otherText           `Text` to compare caller instance to.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if the caller `Text` is equal to the `otherText` under
 *      specified parameters and `false` otherwise.
 */
public final function bool Compare(
    Text                        otherText,
    optional CaseSensitivity    caseSensitivity,
    optional FormatSensitivity  formatSensitivity)
{
    local int           i;
    local array<int>    otherCodePoints;
    if (otherText == none) {
        return false;
    }
    if (GetLength() != otherText.GetLength()) {
        return false;
    }
    if (formatSensitivity == SFORM_SENSITIVE && !CompareFormatting(otherText)) {
        return false;
    }
    //  Copy once to avoid doing it each iteration
    otherCodePoints = otherText.codePoints;
    for (i = 0; i < codePoints.length; i += 1)
    {
        if (    NormalizeCodePoint(codePoints[i],       caseSensitivity)
            !=  NormalizeCodePoint(otherCodePoints[i],  caseSensitivity)) {
            return false;
        }
    }
    return true;
}

/**
 *  Method for checking if the caller starts with another `Text` object.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *  @param  otherText           `Text` that caller is checked to start with.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if the caller `Text` starts with `otherText` under
 *      specified parameters and `false` otherwise.
 */
public final function bool StartsWith(
    Text                        otherText,
    optional CaseSensitivity    caseSensitivity,
    optional FormatSensitivity  formatSensitivity)
{
    local int       i;
    local Character char1, char2;
    if (otherText == none) {
        return false;
    }
    if (GetLength() < otherText.GetLength()) {
        return false;
    }
    //  Copy once to avoid doing it each iteration
    for (i = 0; i < otherText.GetLength(); i += 1)
    {
        char1 = GetCharacter(i);
        char2 = otherText.GetCharacter(i);
        if (    NormalizeCodePoint(char1.codePoint, caseSensitivity)
            !=  NormalizeCodePoint(char2.codePoint, caseSensitivity)) {
            return false;
        }
        if (    formatSensitivity == SFORM_SENSITIVE
            &&  !_.text.IsFormattingEqual(char1.formatting, char2.formatting)) {
                return false;
        }
    }
    return true;
}

/**
 *  Method for checking if the caller ends with another `Text` object.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *  @param  otherText           `Text` that caller is checked to end with.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if the caller `Text` ends with `otherText` under
 *      specified parameters and `false` otherwise.
 */
public final function bool EndsWith(
    Text                        otherText,
    optional CaseSensitivity    caseSensitivity,
    optional FormatSensitivity  formatSensitivity)
{
    local int       index, otherIndex;
    local Character char1, char2;
    if (otherText == none) {
        return false;
    }
    if (GetLength() < otherText.GetLength()) {
        return false;
    }
    //  Copy once to avoid doing it each iteration
    index           = GetLength() - 1;
    otherIndex      = otherText.GetLength() - 1;
    while (otherIndex >= 0)
    {
        char1 = GetCharacter(index);
        char2 = otherText.GetCharacter(otherIndex);
        if (    NormalizeCodePoint(char1.codePoint, caseSensitivity)
            !=  NormalizeCodePoint(char2.codePoint, caseSensitivity)) {
            return false;
        }
        if (    formatSensitivity == SFORM_SENSITIVE
            &&  !_.text.IsFormattingEqual(char1.formatting, char2.formatting)) {
                return false;
        }
        index       -= 1;
        otherIndex  -= 1;
    }
    return true;
}

//  Helper method for comparing formatting data of the caller `Text`
//  and `otherText`.
private final function bool CompareFormatting(Text otherText)
{
    local int i;
    local array<FormattingChunk> rightChunks;
    local TextAPI api;
    rightChunks = otherText.formattingChunks;
    if (formattingChunks.length != rightChunks.length) {
        return false;
    }
    api = _.text;
    for (i = 0; i < formattingChunks.length; i += 1)
    {
        if (formattingChunks[i].startIndex != rightChunks[i].startIndex) {
            return false;
        }
        if (!api.IsFormattingEqual( formattingChunks[i].formatting,
                                    rightChunks[i].formatting))
        {
            return false;
        }
    }
    return true;
}

/**
 *  Method for checking equality between the caller `Text` and
 *  a (plain) `string`.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *  @param  otherText           Plain `string` to compare caller `Text` to.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if the caller `Text` is equal to the `stringToCompare` under
 *      specified parameters and `false` otherwise.
 */
public final function bool CompareToPlainString(
    string                      stringToCompare,
    optional CaseSensitivity    caseSensitivity,
    optional FormatSensitivity  formatSensitivity)
{
    local MutableText   builder;
    local bool          result;
    builder = MutableText(_.memory.Allocate(class'MutableText'));
    builder.AppendPlainString(stringToCompare);
    result = Compare(builder, caseSensitivity, formatSensitivity);
    builder.FreeSelf();
    return result;
}

/**
 *  Method for checking equality between the caller `Text` and
 *  a (colored) `string`.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *  @param  otherText           Colored `string` to compare caller `Text` to.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if the caller `Text` is equal to the `stringToCompare` under
 *      specified parameters and `false` otherwise.
 */
public final function bool CompareToColoredString(
    string                      stringToCompare,
    optional CaseSensitivity    caseSensitivity,
    optional FormatSensitivity  formatSensitivity)
{
    local MutableText   builder;
    local bool          result;
    builder = MutableText(_.memory.Allocate(class'MutableText'));
    builder.AppendColoredString(stringToCompare);
    result = Compare(builder, caseSensitivity, formatSensitivity);
    builder.FreeSelf();
    return result;
}

/**
 *  Method for checking equality between the caller `Text` and
 *  a (formatted) `string`.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *  @param  otherText           Formatted `string` to compare caller `Text` to.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if the caller `Text` is equal to the `stringToCompare` under
 *      specified parameters and `false` otherwise.
 */
public final function bool CompareToFormattedString(
    string                      stringToCompare,
    optional CaseSensitivity    caseSensitivity,
    optional FormatSensitivity  formatSensitivity)
{
    local MutableText   builder;
    local bool          result;
    builder = MutableText(_.memory.Allocate(class'MutableText'));
    builder.AppendFormattedString(stringToCompare);
    result = Compare(builder, caseSensitivity, formatSensitivity);
    builder.FreeSelf();
    return result;
}

/**
 *  Returns character at position given by `position`.
 *
 *  Character is returned along with it's color information.
 *
 *  If you do not care about color, you might want to use
 *  `GetRawCharacter()` method that's slightly faster.
 *
 *  Does some optimizations to speed up lookup of the characters,
 *  when they are looked up in order of increasing `position`.
 *
 *  @param position Position of the character to return.
 *      First character is at `0`.
 *  @return Character at required position. If `position` was out of bounds
 *      (`< 0` or `>= self.GetLength()`), returns invalid character instead.
 */
public final function Character GetCharacter(int position)
{
    local Character result;
    if (position < 0)                   return  _.text.GetInvalidCharacter();
    if (position >= codePoints.length)  return  _.text.GetInvalidCharacter();

    result.codePoint    = codePoints[position];
    result.formatting   = GetFormatting(position);
    return result;
}

/**
 *  Returns character at position given by `position`.
 *
 *  Character is returned without it's color information
 *  (guaranteed to have `.formatting.isColored == false`).
 *
 *  Unlike `GetCharacter()` does not optimizations.
 *
 *  @param position Position of the character to return.
 *      First character is at `0`.
 *  @return Character at required position, without any color information.
 *      If `position` was out of bounds (`< 0` or `>= self.GetLength()`),
 *      returns invalid character instead.
 */
public final function Character GetRawCharacter(int position)
{
    local Character result;
    if (position < 0)                   return  _.text.GetInvalidCharacter();
    if (position >= codePoints.length)  return  _.text.GetInvalidCharacter();

    result.codePoint = codePoints[position];
    return result;
}

/**
 *  Appends new code point to the `Text`'s data.
 *  Allows to create mutable child classes.
 *
 *  Formatting of this code point needs to be set beforehand by
 *  `SetFormatting()` method.
 *
 *  @param  codePoint   Code point to append, does nothing for
 *      invalid (`< 1`) code points.
 *  @return Returns caller `Text`, to allow for method chaining.
 */
protected final function Text AppendCodePoint(int codePoint)
{
    local FormattingChunk newChunk;
    codePoints[codePoints.length] = codePoint;
    if (formattingUpdated)
    {
        newChunk.startIndex = codePoints.length - 1;
        newChunk.formatting = nextFormatting;
        formattingChunks[formattingChunks.length] = newChunk;
        formattingUpdated = false;
    }
    return self;
}

/**
 *  Appends several new code points to the `Text`'s data.
 *  Convenience method over existing `AppendCodePoint()`.
 *
 *  Formatting of these code points needs to be set beforehand by
 *  `SetFormatting()` method.
 *
 *  @return Returns caller `Text`, to allow for method chaining.
 */
protected final function Text AppendManyCodePoints(array<int> codePoints)
{
    local int i;
    for (i = 0; i < codePoints.length; i += 1) {
        AppendCodePoint(codePoints[i]);
    }
    return self;
}

/**
 *  Drops all of the code points in the caller `Text`.
 *  Allows to easier create mutable child classes.
 *
 *  @return Returns caller `Text`, to allow for method chaining.
 */
protected final function Text DropCodePoints() {
    codePoints.length       = 0;
    formattingChunks.length = 0;
    return self;
}

/**
 *  Sets formatting for the next code point(s) to be added by
 *  `AppendCodePoint()` / `AppendManyCodePoints()`.
 *  Allows to create mutable child classes.
 *
 *  Formatting is not reset by `Append...` calls, i.e. if you are adding
 *  several code points with the same formatting in a row, you only need to
 *  call `SetFormatting()` once.
 *
 *  @param  newFormatting   Formatting to use for next code points,
 *      added via `AppendCodePoint()` / `AppendManyCodePoints()` methods.
 *  @return Returns caller `Text`, to allow for method chaining.
 */
protected final function Text SetFormatting(optional Formatting newFormatting)
{
    local Formatting lastFormatting;
    nextFormatting = newFormatting;
    if (formattingChunks.length > 0)
    {
        lastFormatting =
            formattingChunks[formattingChunks.length - 1].formatting;
    }
    formattingUpdated = !_.text.IsFormattingEqual(  lastFormatting,
                                                    nextFormatting);
    return self;
}

/**
 *  Checks whether formatting has changed at character at position `position`
 *  (different from formatting of a character before it).
 *
 *  Helps to compose `string`s from caller `Text`.
 *
 *  If this method is called for the first character (`position == 0`),
 *  then method checks whether that character has any formatting setup
 *  (has a defined color).
 *
 *  @param  position    Position of the character to check. Starts from `0`.
 *  @return `true` if formatting of specified character is different from
 *      the previous one (for the first character - if it has a defined color).
 *      `false` if formatting is the same or specified `position` is
 *      out-of-bounds (`< 0` or `>= self.GetLength()`)
 */
protected final function bool IsFormattingChangedAt(int position)
{
    local int i;
    UpdateFormattingCacheFor(position);
    for (i = formattingIndexCache; i < formattingChunks.length; i += 1)
    {
        if (formattingChunks[i].startIndex > position) {
            return false;
        }
        if (formattingChunks[i].startIndex == position) {
            return true;
        }
    }
    return false;
}

/**
 *  Returns formatting information of character at position `position`.
 *
 *  Does some optimizations to speed up lookup of the formatting,
 *  when they are looked up in order of increasing `position`.
 *
 *  @param  position    Position of the character to get formatting for.
 *      Starts from `0`.
 *  @return Formatting of requested character. Default formatting with
 *      undefined color, if `position is out-of-bounds
 *      (`< 0` or `>= self.GetLength()`).
 */
public final function Formatting GetFormatting(int position)
{
    local int               i;
    local Formatting   result;
    UpdateFormattingCacheFor(position);
    for (i = formattingIndexCache; i < formattingChunks.length; i += 1)
    {
        if (formattingChunks[i].startIndex > position) {
            break;
        }
    }
    i -= 1;
    if (i < 0) {
        return result;
    }
    return formattingChunks[i].formatting;
}

//      Verifies that current `formattingIndexCache` can be used as a starting
//  position to look up for formatting of symbol at `index`.
//      If it cannot - resets it to zero.
private final function UpdateFormattingCacheFor(int index)
{
    if (    formattingIndexCache < 0
        ||  formattingIndexCache >= formattingChunks.length) {
        formattingIndexCache = 0;
        return;
    }
    if (formattingChunks[formattingIndexCache].startIndex > index) {
        formattingIndexCache = 0;
    }
}

/**
 *  Converts data from the caller `Text` instance into a plain `string`.
 *  Can be used to extract only substrings.
 *
 *  If provided parameters `startIndex` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startIndex      Position of the first symbol to extract into a
 *      plain `string`. By default `0`, corresponding to the first symbol.
 *  @param  maxLength       Max length of the extracted string. By default `0`,
 *      - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a string as possible.
 *  @return Plain `string` representation of the caller `Text`,
 *      i.e. `string` without any color information inside.
 */
public final function string ToPlainString(
    optional int startIndex,
    optional int maxLength)
{
    local int       i;
    local string    result;
    if (maxLength <= 0) {
        maxLength = MaxInt;
    }
    else if (startIndex < 0)
    {
        maxLength += startIndex;
        startIndex = 0;
    }
    for (i = startIndex; i < codePoints.length; i += 1)
    {
        if (maxLength <= 0) {
            break;
        }
        maxLength -= 1;
        result $= Chr(codePoints[i]);
    }
    return result;
}

/**
 *  Converts data from the caller `Text` instance into a colored `string`.
 *  Can be used to extract only substrings.
 *
 *  Guaranteed to add a color tag (possibly of `defaultColor`parameter)
 *  at the beginning of the returned `string`.
 *
 *  If provided parameters `startIndex` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startIndex      Position of the first symbol to extract into a
 *      colored `string`. By default `0`, corresponding to the first symbol.
 *  @param  maxLength       Max length of the extracted string. By default `0`,
 *      - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a string as possible.
 *      NOTE:   this parameter only counts actual visible symbols, ignoring
 *              4-byte color code sequences, so method `Len()`, applied to
 *              the result of `ToColoredString()`, will return a bigger value
 *              than `maxLength`.
 *  @param  defaultColor    Color to be applied to the parts of the string that
 *      do not have any specified color.
 *      This is necessary, since 4-byte color sequences cannot unset the color.
 *  @return Colored `string` representation of the caller `Text`,
 *      i.e. `string` without any color information inside.
 */
public final function string ToColoredString(
    optional int    startIndex,
    optional int    maxLength,
    optional Color  defaultColor)
{
    local int           i;
    local Formatting    newFormatting;
    local Color         nextColor, appliedColor;
    local string        result;
    if (maxLength <= 0) {
        maxLength = MaxInt;
    }
    else if (startIndex < 0)
    {
        maxLength += startIndex;
        startIndex = 0;
    }
    //  `appliedColor` will contain perfect black and so,
    //  guaranteed to be different from any actually used color
    defaultColor = _.color.FixColor(defaultColor);
    for (i = startIndex; i < codePoints.length; i += 1)
    {
        if (maxLength <= 0) {
            break;
        }
        maxLength -= 1;
        if (IsFormattingChangedAt(i) || i == startIndex)
        {
            newFormatting = GetFormatting(i);
            if (newFormatting.isColored) {
                nextColor = _.color.FixColor(newFormatting.color);
            }
            else {
                nextColor = defaultColor;
            }
            //  Colors are already fixed (and will be different from
            //  `appliedColor` before we initialize it)
            if (!_.color.AreEqual(nextColor, appliedColor))
            {
                result $= Chr(CODEPOINT_ESCAPE);
                result $= Chr(nextColor.r);
                result $= Chr(nextColor.g);
                result $= Chr(nextColor.b);
                appliedColor = nextColor;
            }
        }
        result $= Chr(codePoints[i]);
    }
    return result;
}

/**
 *  Converts data from the caller `Text` instance into a formatted `string`.
 *  Can be used to extract only substrings.
 *
 *  If provided parameters `startIndex` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startIndex      Position of the first symbol to extract into a
 *      formatted `string`. By default `0`, corresponding to the first symbol.
 *  @param  maxLength       Max length of the extracted string. By default `0`,
 *      - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a string as possible.
 *      NOTE:   this parameter only counts actual visible symbols,
 *              ignoring formatting blocks ('{<color> }')
 *              or escape sequences (i.e. '&{' is one character),
 *              so method `Len()`, applied to the result of
 *              `ToFormattedString()`, will return a bigger value
 *              than `maxLength`.
 *  @return Formatted `string` representation of the caller `Text`,
 *      i.e. `string` without any color information inside.
 */
public final function string ToFormattedString(
    optional int startIndex,
    optional int maxLength)
{
    local int           i;
    local bool          isInsideBlock;
    local string        result;
    local Formatting    newFormatting;
    if (maxLength <= 0) {
        maxLength = MaxInt;
    }
    else if (startIndex < 0)
    {
        maxLength += startIndex;
        startIndex = 0;
    }
    for (i = startIndex; i < codePoints.length; i += 1)
    {
        if (maxLength <= 0) {
            break;
        }
        maxLength -= 1;
        if (IsFormattingChangedAt(i) || i == startIndex)
        {
            newFormatting = GetFormatting(i);
            if (isInsideBlock && i != startIndex) {
                result $= STRING_CLOSE_FORMAT;
                isInsideBlock = false;
            }
            if (newFormatting.isColored) {
                result $= STRING_OPEN_FORMAT
                    $ _.color.ToString(newFormatting.color)
                    $ STRING_SEPARATOR_FORMAT;
                isInsideBlock = true;
            }
        }
        if (    codePoints[i] == CODEPOINT_OPEN_FORMAT
            ||  codePoints[i] == CODEPOINT_CLOSE_FORMAT) {
            result $= STRING_FORMAT_ESCAPE;
        }
        result $= Chr(codePoints[i]);
    }
    if (isInsideBlock) {
        result $= STRING_CLOSE_FORMAT;
    }
    return result;
}

/**
 *  Splits the string into substrings wherever `separator` occurs, and returns
 *  array of those strings.
 *
 *  If `separator` does not match anywhere in the string, method returns a
 *  single-element array containing copy of this `Text`.
 *
 *  @param  separator   Character that separates different parts of this `Text`.
 *  @return Array of `MutableText`s that contain separated substrings.
 */
public final function array<MutableText> SplitByCharacter(Character separator)
{
    local int                   i, length;
    local Character             nextCharacter;
    local MutableText           nextText;
    local array<MutableText>    result;
    length = GetLength();
    nextText = _.text.Empty();
    i = 0;
    while (i < length)
    {
        nextCharacter = GetCharacter(i);
        if (_.text.AreEqual(separator, nextCharacter))
        {
            result[result.length] = nextText;
            nextText = _.text.Empty();
        }
        else {
            nextText.AppendCharacter(nextCharacter);
        }
        i += 1;
    }
    result[result.length] = nextText;
    return result;
}

defaultproperties
{
    STRING_SEPARATOR_FORMAT = " "
    STRING_OPEN_FORMAT      = "{"
    STRING_CLOSE_FORMAT     = "}"
    STRING_FORMAT_ESCAPE    = "&"
    CODEPOINT_ESCAPE        = 27    //  ASCII escape code
    CODEPOINT_OPEN_FORMAT   = 123   //  '{'
    CODEPOINT_CLOSE_FORMAT  = 125   //  '}'
    CODEPOINT_FORMAT_ESCAPE = 38    //  '&'
}