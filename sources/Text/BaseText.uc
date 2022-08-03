/**
 *      Acedia's base text class. It implements all of the methods for
 *  immutable `Text`, but by itself does not give a guarantee of immutability,
 *  since `MutableText` is one of its child classes.
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
class BaseText extends AcediaObject
    abstract;

//      Enumeration that describes how should we treat `BaseText`s that
//  differ in case only.
//      By default we would consider them unequal.
enum CaseSensitivity
{
    SCASE_SENSITIVE,
    SCASE_INSENSITIVE
};

//      Enumeration that describes how should we treat `BaseText`s that
//  differ only in their formatting.
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
    var int         codePoint;
    var Formatting  formatting;
};

//  Actual content of the `BaseText` is stored as a sequence of
//  Unicode code points.
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
 *      In the base class we implement `AppendCodePoint()` and
 *  `AppendManyCodePoints()` methods that allow to add code points 1-by-1.
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
 *  Auxiliary method that changes formatting of the whole `BaseText` to
 *  a specified one (`newFormatting`). This method is faster than calling
 *  `ReformatRange`.
 *
 *  @param  newFormatting   Formatting to set to the whole `BaseText`.
 */
protected final function ReformatWhole(Formatting newFormatting)
{
    local FormattingChunk newChunk;
    formattingChunks.length = 0;
    newChunk.startIndex = 0;
    newChunk.formatting = newFormatting;
    formattingChunks[0] = newChunk;
}

/**
 *  Auxiliary method that changes formatting of the characters with indices in
 *  range `[start; end]` to a specified one (`newFormatting`).
 *
 *  This method assumes, but does not check that:
 *      1. `start <= end`;
 *      2. `start` and `end` parameters belong to the range of valid indices
 *          `[0; GetLength() - 1]`
 *
 *  @param  start           First character to change formatting of.
 *  @param  end             Last character to change formatting of.
 *  @param  newFormatting   Formatting to set to the specified characters.
 */
protected final function ReformatRange(
    int         start,
    int         end,
    Formatting  newFormatting)
{
    local int                       i;
    local Formatting                formattingAfterChangedSegment;
    local FormattingChunk           newChunk;
    local array<FormattingChunk>    newFormattingChunks;
    start   = Max(start, 0);
    end     = Min(GetLength() - 1, end);
    //  Formatting right after `end`, the end of re-formatted segment
    formattingAfterChangedSegment = GetFormatting(end + 1);
    //  1. Copy old formatting before `start`
    for (i = 0; i < formattingChunks.length; i += 1)
    {
        if (start <= formattingChunks[i].startIndex) {
            break;
        }
        newFormattingChunks[newFormattingChunks.length] = formattingChunks[i];
    }
    newChunk.formatting = newFormatting;
    newChunk.startIndex = start;
    newFormattingChunks[newFormattingChunks.length] = newChunk;
    if (end == GetLength() - 1)
    {
        formattingChunks = newFormattingChunks;
        //  We have inserted `FormattingChunk` without checking if it actually
        //  changes formatting. It might be excessive, so do a normalization.
        NormalizeFormatting();
        return;
    }
    //  2. Drop old formatting overwritten by `newFormatting`
    while (i < formattingChunks.length)
    {
        if (end < formattingChunks[i].startIndex) {
            break;
        }
        i += 1;
    }
    //  3. Copy old formatting after `end`
    newChunk.formatting = formattingAfterChangedSegment;
    newChunk.startIndex = end + 1;  //  end < GetLength() - 1
    newFormattingChunks[newFormattingChunks.length] = newChunk;
    while (i < formattingChunks.length)
    {
        newFormattingChunks[newFormattingChunks.length] = formattingChunks[i];
        i += 1;
    }
    formattingChunks = newFormattingChunks;
    //  We have inserted `FormattingChunk` without checking if it actually
    //  changes formatting. It might be excessive, so do a normalization.
    NormalizeFormatting();
}

/**
 *  Makes an immutable copy (`class'Text'`) of the caller `BaseText`.
 *
 *  Copies characters in the range `[startIndex; startIndex + maxLength - 1]`
 *  If provided parameters `startIndex` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startIndex  Position of the first character to copy.
 *      By default `0`, corresponding to the very first character.
 *  @param  maxLength   Max length of the extracted string. By default `0`,
 *      - that and all negative values mean that method should extract all
 *      characters to the right of `startIndex`.
 *  @return Immutable copy of the caller `BaseText` instance.
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
        maxLength = codePoints.length - startIndex;
    }
    endIndex = startIndex + maxLength;
    copy = Text(_.memory.Allocate(class'Text'));
    //  Edge cases
    if (endIndex <= 0) {
        return copy;
    }
    if (startIndex <= 0 && startIndex + maxLength >= codePoints.length)
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
 *  Makes a mutable copy (`class'MutableText'`) of the caller
 *  `BaseText` instance.
 *
 *  If provided parameters `startIndex` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startIndex  Position of the first character to copy.
 *      By default `0`, corresponding to the very first character.
 *  @param  maxLength   Max length of the extracted string. By default `0`,
 *      - that and all negative values mean that method should extract all
 *      characters to the right of `startIndex`.
 *  @return Mutable copy of the caller `BaseText` instance.
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
        maxLength = codePoints.length - startIndex;
    }
    endIndex = startIndex + maxLength;
    copy = MutableText(_.memory.Allocate(class'MutableText'));
    //  Edge cases
    if (endIndex <= 0 || startIndex >= codePoints.length) {
        return copy;
    }
    if (startIndex <= 0 && startIndex + maxLength >= codePoints.length)
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
 *  Makes an immutable copy (`class'Text'`) of the caller `BaseText`
 *  in a lower case.
 *
 *  If provided parameters `startPosition` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startPosition   Position of the first character to copy.
 *      By default `0`, corresponding to the very first character.
 *  @param  maxLength   Max length of the extracted string. By default `0`,
 *      - that and all negative values mean that method should extract all
 *      characters to the right of `startIndex`.
 *  @return Immutable copy of caller `BaseText` in a lower case.
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
 *  Makes an immutable copy (`class'Text'`) of the caller `BaseText`
 *  in an upper case.
 *
 *  If provided parameters `startPosition` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startPosition   Position of the first character to copy.
 *      By default `0`, corresponding to the very first character.
 *  @param  maxLength   Max length of the extracted string. By default `0`,
 *      - that and all negative values mean that method should extract all
 *      characters to the right of `startIndex`.
 *  @return Immutable copy of caller `BaseText` in a upper case.
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
 *  Makes a mutable copy (`class'MutableText'`) of the caller
 *  `BaseText` instance in lower case.
 *
 *  If provided parameters `startPosition` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startPosition   Position of the first character to copy.
 *      By default `0`, corresponding to the very first character.
 *  @param  maxLength   Max length of the extracted string. By default `0`,
 *      - that and all negative values mean that method should extract all
 *      characters to the right of `startIndex`.
 *  @return Mutable copy of caller `BaseText` instance in lower case.
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
 *  @param  maxLength   Max length of the extracted string. By default `0`,
 *      - that and all negative values mean that method should extract all
 *      characters to the right of `startIndex`.
 *  @return Mutable copy of caller `BaseText` instance in upper case.
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
 *  Checks if caller `BaseText` contains a valid name object or not.
 *
 *  Valid names are case-insensitive `BaseText`s that:
 *      1. No longer than 50 characters long;
 *      2. Contain only ASCII letters, digits and '.' / '_' characters;
 *      3. Empty `BaseText` is not considered a valid name.
 *
 *  @return `true` if caller `BaseText` contains a valid config object name and
 *      `false` otherwise.
 */
public final function bool IsValidName()
{
    local int       i;
    local int       codePoint;
    local bool      isValidCodePoint;
    local Character nextCharacter;

    if (IsEmpty())          return false;
    if (GetLength() > 50)   return false;

    for (i = 0; i < GetLength(); i += 1)
    {
        nextCharacter = GetCharacter(i);
        codePoint = nextCharacter.codePoint;
        isValidCodePoint =
                ( (codePoint == 0x2E) || (codePoint == 0x5F)    //  '.' or '_'
            ||  (0x30 <= codePoint && codePoint <= 0x39)        //  '0' to '9'
            ||  (0x41 <= codePoint && codePoint <= 0x5A)        //  'A' to 'Z'
            ||  (0x61 <= codePoint && codePoint <= 0x7A));      //  'a' to 'z'
        if (!isValidCodePoint) {
            return false;
        }
    }
    return true;
}

/**
 *  Auxiliary function that converts case of the caller `BaseText` object.
 *  As `BaseText` is supposed to be immutable, cannot be public.
 *
 *  @param  toLower `true` if caller `BaseText` must be converted to
 *      the lower case and `false` otherwise.
 */
protected final function ConvertCase(bool toLower)
{
    local int       i;
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
 *  Calculates hash value of the caller `BaseText`. Hash will depend only on
 *  it's textual contents, without taking formatting (color information)
 *  into account.
 *
 *  @return Hash, that depends on textual contents only.
 */
protected function int CalculateHashCode()
{
    //  We have left this method here, since only the base class has access
    //  to code points, which allows for more efficient implementation.
    //  You must overload it for mutable text child classes
    //  (like `MutableText`).
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
 *  Checks whether contents of the caller `BaseText` are empty.
 *
 *  @return `true` if caller `BaseText` contains no symbols.
 */
public final function bool IsEmpty()
{
    return (codePoints.length == 0);
}

/**
 *  Returns current length of the caller `BaseText` in symbols.
 *
 *  Do note that codepoint is not the same as a symbol, since one symbol
 *  can consist of several code points. While current implementation only
 *  supports symbols represented by a single code point, this might change
 *  in the future.
 *
 *  @return Current length of caller `BaseText`'s contents in symbols.
 */
public final function int GetLength()
{
    return codePoints.length;
}

/**
 *      Override equality check for `BaseText` to make two different
 *  `BaseText`s equal based on their text contents.
 *      Text equality check is case-sensitive and does not take formatting
 *  into account.
 *
 *  `BaseText` cannot be equal to object of any class that is not
 *  derived from `BaseText`.
 *
 *  @param  other   Object to compare to the caller.
 *      `none` is only equal to the `none`.
 *  @return `true` if `other` is considered equal to the caller `BaseText`,
 *      `false` otherwise.
 */
public function bool IsEqual(Object other)
{
    if (self == other) {
        return true;
    }
    return Compare(BaseText(other));
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
 *  Method for checking equality between the caller and another `BaseText`
 *  object.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *  @param  otherText           `BaseText` to compare caller instance to.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if the caller `BaseText` is equal to the `otherText` under
 *      specified parameters and `false` otherwise.
 */
public final function bool Compare(
    BaseText                    otherText,
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
 *  Method for checking if the caller starts with another `BaseText` object.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *  @param  otherText           `BaseText` that caller is checked to start with.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if the caller `BaseText` starts with `otherText` under
 *      specified parameters and `false` otherwise.
 */
public final function bool StartsWith(
    BaseText                    otherText,
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
 *  Method for checking if the caller starts with another `string`.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case. By default comparison is case-sensitive.
 *
 *  @param  otherString     `string` that caller is checked to start with.
 *  @param  caseSensitivity Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @return `true` if the caller `BaseText` starts with `otherString` under
 *      specified parameters and `false` otherwise.
 */
public final function bool StartsWithS(
    string                      otherString,
    optional CaseSensitivity    caseSensitivity)
{
    local bool          result;
    local MutableText   otherText;
    otherText = _.text.FromStringM(otherString);
    result = StartsWith(otherText, caseSensitivity);
    _.memory.Free(otherText);
    return result;
}

/**
 *  Method for checking if the caller ends with another `BaseText` object.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *  @param  otherText           `BaseText` that caller is checked to end with.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if the caller `BaseText` ends with `otherText` under
 *      specified parameters and `false` otherwise.
 */
public final function bool EndsWith(
    BaseText                    otherText,
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

/**
 *  Method for checking if the caller ends with another `string`.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case. By default comparison is case-sensitive.
 *
 *  @param  otherString     `string` that caller is checked to end with.
 *  @param  caseSensitivity Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @return `true` if the caller `BaseText` ends with `otherString` under
 *      specified parameters and `false` otherwise.
 */
public final function bool EndsWithS(
    string                      otherString,
    optional CaseSensitivity    caseSensitivity)
{
    local bool          result;
    local MutableText   otherText;
    otherText = _.text.FromStringM(otherString);
    result = EndsWith(otherText, caseSensitivity);
    _.memory.Free(otherText);
    return result;
}

//  Helper method for comparing formatting data of the caller `BaseText`
//  and `otherText`.
private final function bool CompareFormatting(BaseText otherText)
{
    local int                       i;
    local TextAPI                   api;
    local array<FormattingChunk>    rightChunks;
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
 *  Method for checking equality between the caller `BaseText` and
 *  a (plain) `string`.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *  @param  otherText           Plain `string` to compare caller `BaseText` to.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if the caller `BaseText` is equal to the `stringToCompare`
 *      under specified parameters and `false` otherwise.
 */
public final function bool CompareToString(
    string                      stringToCompare,
    optional CaseSensitivity    caseSensitivity,
    optional FormatSensitivity  formatSensitivity)
{
    local MutableText   builder;
    local bool          result;
    builder = MutableText(_.memory.Allocate(class'MutableText'));
    builder.AppendString(stringToCompare);
    result = Compare(builder, caseSensitivity, formatSensitivity);
    builder.FreeSelf();
    return result;
}

/**
 *  Method for checking equality between the caller `BaseText` and
 *  a (colored) `string`.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *  @param  otherText           Colored `string` to compare caller
 *      `BaseText` to.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if the caller `BaseText` is equal to the `stringToCompare`
 *      under specified parameters and `false` otherwise.
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
 *  Method for checking equality between the caller `BaseText` and
 *  a (formatted) `string`.
 *
 *      This method supports comparison both sensitive and not sensitive to
 *  the case and difference in formatting (color of the characters).
 *      By default comparison is case-sensitive, but ignores
 *  formatting information.
 *
 *  @param  otherText           Formatted `string` to compare caller
 *      `BaseText` to.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `true` if the caller `BaseText` is equal to the `stringToCompare`
 *      under specified parameters and `false` otherwise.
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
 *  Appends new code point to the `BaseText`'s data.
 *  Allows to create mutable child classes.
 *
 *  Formatting of this code point needs to be set beforehand by
 *  `SetFormatting()` method.
 *
 *  @param  codePoint   Code point to append, does nothing for
 *      invalid (`< 1`) code points.
 *  @return Returns caller `BaseText`, to allow for method chaining.
 */
protected final function BaseText AppendCodePoint(int codePoint)
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
 *  Appends several new code points to the `BaseText`'s data.
 *  Convenience method over existing `AppendCodePoint()`.
 *
 *  Formatting of these code points needs to be set beforehand by
 *  `SetFormatting()` method.
 *
 *  @return Returns caller `BaseText`, to allow for method chaining.
 */
protected final function BaseText AppendManyCodePoints(array<int> codePoints)
{
    local int i;
    for (i = 0; i < codePoints.length; i += 1) {
        AppendCodePoint(codePoints[i]);
    }
    return self;
}

/**
 *  Drops all of the code points in the caller `BaseText`.
 *  Allows to easier create mutable child classes.
 *
 *  @return Returns caller `BaseText`, to allow for method chaining.
 */
protected final function BaseText DropCodePoints() {
    codePoints.length       = 0;
    formattingChunks.length = 0;
    return self;
}

/**
 *  Sets `newFormatting` for every non-formatted character in
 *  the caller `BaseText`.
 *  Allows to create mutable child classes.
 *
 *  @param  newFormatting   Formatting to use for all non-formatted character in
 *      the caller `BaseText`. If `newFormatting` is not colored itself -
 *      method does nothing.
 *  @return Returns caller `BaseText`, to allow for method chaining.
 */
protected final function BaseText _changeDefaultFormatting(
    Formatting newFormatting)
{
    local int                       i;
    local FormattingChunk           newFormattingChunk;
    local array<FormattingChunk>    newFormattingChunks;
    if (!newFormatting.isColored) {
        return self;
    }
    newFormattingChunk.formatting = newFormatting;
    if (    formattingChunks.length <= 0
        ||  formattingChunks[0].startIndex > 0)
    {
        newFormattingChunks[0] = newFormattingChunk;
    }
    while (i < formattingChunks.length)
    {
        if (formattingChunks[i].formatting.isColored)
        {
            newFormattingChunks[newFormattingChunks.length] =
                formattingChunks[i];
        }
        else
        {
            newFormattingChunk.startIndex = formattingChunks[i].startIndex;
            newFormattingChunks[newFormattingChunks.length] =
                newFormattingChunk;
        }
        i += 1;
    }
    formattingChunks = newFormattingChunks;
    NormalizeFormatting();
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
 *  @return Returns caller `BaseText`, to allow for method chaining.
 */
protected final function BaseText SetFormatting(
    optional Formatting newFormatting)
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
 *  Helps to compose `string`s from caller `BaseText`.
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

//  Removes possible unnecessary chunks from `formattingChunks`:
//  if there is a chunk that tells us to have red color after index `3` and
//  next one tells us to have red color after index `5` - the second chunk is
//  unnecessary.
private final function NormalizeFormatting()
{
    local int i;
    while (i < formattingChunks.length - 1)
    {
        if (_.text.IsFormattingEqual(   formattingChunks[i].formatting,
                                        formattingChunks[i + 1].formatting))
        {
            formattingChunks.Remove(i + 1, 1);
        }
        else {
            i += 1;
        }
    }
}

/**
 *  Converts data from the caller `BaseText` instance into a plain `string`.
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
 *      effectively extracting as much of a `string` as possible.
 *  @return Plain `string` representation of the caller `BaseText`,
 *      i.e. `string` without any color information inside.
 */
public final function string ToString(
    optional int startIndex,
    optional int maxLength)
{
    local int       i;
    local string    result;
    if (maxLength <= 0) {
        maxLength = MaxInt;
    }
    else if (startIndex < 0) {
        maxLength += startIndex;
    }
    startIndex = Max(0, startIndex);
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
 *  Converts data from the caller `BaseText` instance into a colored `string`.
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
 *      effectively extracting as much of a `string` as possible.
 *      NOTE:   this parameter only counts actual visible symbols, ignoring
 *              4-byte color code sequences, so method `Len()`, applied to
 *              the result of `ToColoredString()`, will return a bigger value
 *              than `maxLength`.
 *  @param  defaultColor    Color to be applied to the parts of the string that
 *      do not have any specified color.
 *      This is necessary, since 4-byte color sequences cannot unset the color.
 *  @return Colored `string` representation of the caller `BaseText`,
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
    else if (startIndex < 0) {
        maxLength += startIndex;
    }
    startIndex = Max(0, startIndex);
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
 *  Converts data from the caller `BaseText` instance into a `Text` containing
 *  formatted `string`.
 *  Can be used to extract only substrings.
 *
 *  If provided parameters `startIndex` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startIndex      Position of the first symbol to extract into a
 *      formatted `string`. By default `0`, corresponding to the first symbol.
 *  @param  maxLength       Max length of the extracted `string`.
 *      By default `0` - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a `string` as possible.
 *      NOTE:   this parameter only counts actual visible symbols,
 *              ignoring formatting blocks ('{<color> }')
 *              or escape sequences (i.e. '&{' is one character),
 *              so method `Len()`, applied to the result of
 *              `ToFormattedString()`, will return a bigger value
 *              than `maxLength`.
 *  @return Formatted string representation inside `Text` of the caller
 *      `BaseText`.
 */
public final function Text ToFormattedText(
    optional int startIndex,
    optional int maxLength)
{
    return ToFormattedTextM(startIndex, maxLength).IntoText();
}

/**
 *  Converts data from the caller `BaseText` instance into a `MutableText`
 *  containing formatted `string`.
 *  Can be used to extract only substrings.
 *
 *  If provided parameters `startIndex` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startIndex      Position of the first symbol to extract into a
 *      formatted `string`. By default `0`, corresponding to the first symbol.
 *  @param  maxLength       Max length of the extracted `string`.
 *      By default `0` - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a `string` as possible.
 *      NOTE:   this parameter only counts actual visible symbols,
 *              ignoring formatting blocks ('{<color> }')
 *              or escape sequences (i.e. '&{' is one character),
 *              so method `Len()`, applied to the result of
 *              `ToFormattedString()`, will return a bigger value
 *              than `maxLength`.
 *  @return Formatted string representation inside `MutableText` of the caller
 *      `BaseText`.
 */
public final function MutableText ToFormattedTextM(
    optional int startIndex,
    optional int maxLength)
{
    local int           i;
    local bool          isInsideBlock;
    local MutableText   result;
    local Formatting    newFormatting;

    if (maxLength <= 0) {
        maxLength = MaxInt;
    }
    else if (startIndex < 0) {
        maxLength += startIndex;
    }
    startIndex = Max(0, startIndex);
    result = _.text.Empty();
    for (i = startIndex; i < codePoints.length; i += 1)
    {
        if (maxLength <= 0) {
            break;
        }
        maxLength -= 1;
        if (IsFormattingChangedAt(i) || i == startIndex)
        {
            newFormatting = GetFormatting(i);
            if (isInsideBlock && i != startIndex)
            {
                result.AppendString(STRING_CLOSE_FORMAT);
                isInsideBlock = false;
            }
            if (newFormatting.isColored)
            {
                result
                    .AppendString(STRING_OPEN_FORMAT)
                    .Append(_.color.ToText(newFormatting.color))
                    .AppendString(STRING_SEPARATOR_FORMAT);
                isInsideBlock = true;
            }
        }
        if (    codePoints[i] == CODEPOINT_OPEN_FORMAT
            ||  codePoints[i] == CODEPOINT_CLOSE_FORMAT)
        {
            result.AppendString(STRING_FORMAT_ESCAPE);
        }
        result.AppendString(Chr(codePoints[i]));
    }
    if (isInsideBlock) {
        result.AppendString(STRING_CLOSE_FORMAT);
    }
    return result;
}

/**
 *  Converts data from the caller `BaseText` instance into a formatted `string`.
 *  Can be used to extract only substrings.
 *
 *  If provided parameters `startIndex` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startIndex      Position of the first symbol to extract into a
 *      formatted `string`. By default `0`, corresponding to the first symbol.
 *  @param  maxLength       Max length of the extracted `string`.
 *      By default `0` - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a `string` as possible.
 *      NOTE:   this parameter only counts actual visible symbols,
 *              ignoring formatting blocks ('{<color> }')
 *              or escape sequences (i.e. '&{' is one character),
 *              so method `Len()`, applied to the result of
 *              `ToFormattedString()`, will return a bigger value
 *              than `maxLength`.
 *  @return Formatted `string` representation of the caller `BaseText`,
 *      i.e. `string` without any color information inside.
 */
public final function string ToFormattedString(
    optional int startIndex,
    optional int maxLength)
{
    return _.text.IntoString(ToFormattedTextM(startIndex, maxLength));
}

/**
 *  Splits the string into substrings wherever `separator` occurs, and returns
 *  array of those strings.
 *
 *  If `separator` does not match anywhere in the string, method returns a
 *  single-element array containing copy of this `Text`.
 *
 *  @param  separator       Character that separates different parts of
 *      this `Text`. If `separator` is an invalid character, method will do
 *      nothing and return empty result.
 *  @param  skipEmpty       Set this to `true` to filter out empty
 *      `MutableText`s from the output.
 *  @param  returnMutable   Decides whether this method will return
 *      `Text` (`false`, by default) or `MutableText` (`true`) instances.
 *  @return Array of `BaseText`s (whether it's `Text` or `MutableText` depends
 *      on `returnMutable` parameter) that contain separated substrings.
 *      Always empty if `separator` is an invalid character.
 */
public final function array<BaseText> SplitByCharacter(
    Character       separator,
    optional bool   skipEmpty,
    optional bool   returnMutable)
{
    local int               i, length;
    local Character         nextCharacter;
    local MutableText       nextText;
    local array<BaseText>   result;
    if (!_.text.IsValidCharacter(separator)) {
        return result;
    }
    length = GetLength();
    nextText = _.text.Empty();
    i = 0;
    while (i < length)
    {
        nextCharacter = GetCharacter(i);
        if (_.text.AreEqual(separator, nextCharacter))
        {
            if (!skipEmpty || !nextText.IsEmpty())
            {
                if (returnMutable) {
                    result[result.length] = nextText;
                }
                else {
                    result[result.length] = nextText.IntoText();
                }
            }
            else {
                _.memory.Free(nextText);
            }
            nextText = _.text.Empty();
        }
        else {
            nextText.AppendCharacter(nextCharacter);
        }
        i += 1;
    }
    if (!skipEmpty || !nextText.IsEmpty())
    {
        if (returnMutable) {
            result[result.length] = nextText;
        }
        else {
            result[result.length] = nextText.IntoText();
        }
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
 *  @param  separatorSource `string`, first character of which will be used as
 *      a separator. If `separatorSource` is empty, method will do nothing and
 *      return empty result.
 *  @param  skipEmpty       Set this to `true` to filter out empty
 *      `MutableText`s from the output.
 *  @param  returnMutable   Decides whether this method will return
 *      `Text` (`false`, by default) or `MutableText` (`true`) instances.
 *  @return Array of `BaseText`s (whether it's `Text` or `MutableText` depends
 *      on `returnMutable` parameter) that contain separated substrings.
 *      Always empty if `separatorSource` is empty.
 */
public final function array<BaseText> SplitByCharacterS(
    string          separatorSource,
    optional bool   skipEmpty,
    optional bool   returnMutable)
{
    local Character separator;
    separator = _.text.GetCharacter(separatorSource, 0);
    return SplitByCharacter(separator, skipEmpty, returnMutable);
}

/**
 *  Returns the index position of the first occurrence of the `otherText` in
 *  the caller `BaseText`, searching forward from index position `fromIndex`.
 *
 *  @param  otherText           `BaseText` data to find inside the caller
 *      `BaseText`.
 *  @param  fromIndex           Index from which we should start searching.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `-1` if `otherText` is not found after `fromIndex`.
 */
public final function int IndexOf(
    BaseText                    otherText,
    optional int                fromIndex,
    optional CaseSensitivity    caseSensitivity,
    optional FormatSensitivity  formatSensitivity)
{
    local int       startCandidate;
    local int       index, otherIndex;
    local Character char1, char2;
    if (otherText == none)                                  return -1;
    if (fromIndex > GetLength())                            return -1;
    if (GetLength() - fromIndex < otherText.GetLength())    return -1;
    if (otherText.IsEmpty())                                return fromIndex;

    startCandidate = fromIndex;
    for (index = fromIndex; index < GetLength(); index += 1)
    {
        char1 = GetCharacter(index);
        char2 = otherText.GetCharacter(otherIndex);
        if (    NormalizeCodePoint(char1.codePoint, caseSensitivity)
            !=  NormalizeCodePoint(char2.codePoint, caseSensitivity))
        {
            startCandidate = index + 1;
            otherIndex = 0;
            continue;
        }
        if (    formatSensitivity == SFORM_SENSITIVE
            &&  !_.text.IsFormattingEqual(char1.formatting, char2.formatting))
        {
            startCandidate = index + 1;
            otherIndex = 0;
            continue;
        }
        otherIndex += 1;
        if (otherIndex == otherText.GetLength()) {
            return startCandidate;
        }
    }
    return -1;
}

/**
 *  Returns the index position of the last occurrence of the `otherText` in
 *  the caller `BaseText`, searching backward from index position `fromIndex`,
 *  counted the end of the caller `BaseText`.
 *
 *  @param  otherText           `BaseText` data to find inside the caller
 *      `BaseText`.
 *  @param  fromIndex           Index from which we should start searching, but
 *      it's counted from the end of the caller `BaseText`: `0` means starting
 *      from the last character, `1` means next to last, etc.
 *  @param  caseSensitivity     Defines whether comparison should be
 *      case-sensitive. By default it is.
 *  @param  formatSensitivity   Defines whether comparison should be
 *      sensitive for color information. By default it is not.
 *  @return `-1` if `otherText` is not found starting `fromIndex`
 *      (this index is counted from the end of the caller `BaseText`).
 */
public final function int LastIndexOf(
    BaseText                    otherText,
    optional int                fromIndex,
    optional CaseSensitivity    caseSensitivity,
    optional FormatSensitivity  formatSensitivity)
{
    local int       startCandidate;
    local int       index, otherIndex;
    local Character char1, char2;
    if (otherText == none)                                  return -1;
    if (fromIndex > GetLength())                            return -1;
    if (GetLength() - fromIndex < otherText.GetLength())    return -1;
    if (otherText.IsEmpty())                                return fromIndex;

    otherIndex = otherText.GetLength() - 1;
    startCandidate = GetLength() - fromIndex - 1;
    for (index = startCandidate; index >= 0; index -= 1)
    {
        char1 = GetCharacter(index);
        char2 = otherText.GetCharacter(otherIndex);
        if (    NormalizeCodePoint(char1.codePoint, caseSensitivity)
            !=  NormalizeCodePoint(char2.codePoint, caseSensitivity))
        {
            startCandidate = index - 1;
            otherIndex = otherText.GetLength() - 1;
            continue;
        }
        if (    formatSensitivity == SFORM_SENSITIVE
            &&  !_.text.IsFormattingEqual(char1.formatting, char2.formatting))
        {
            startCandidate = index - 1;
            otherIndex = otherText.GetLength() - 1;
            continue;
        }
        otherIndex -= 1;
        if (otherIndex < 0) {
            return startCandidate - (otherText.GetLength() - 1);
        }
    }
    return -1;
}

/**
 *  This method frees caller `MutableText` and returns immutable `Text`
 *  copy instead.
 *
 *  @return Immutable `Text` copy of the caller `MutableText`.
 */
public function Text IntoText()
{
    return none;
}

/**
 *  This method frees caller `Text` and returns immutable `Text` copy instead.
 *
 *  @return Immutable `Text` copy of the caller `MutableText`.
 */
public function MutableText IntoMutableText()
{
    return none;
}

/**
 *  Creates `Parser` to parse caller `BaseText`.
 *
 *  @return `Parser` that is setup to parse caller `BaseText`.
 *      Guaranteed to not be `none`.
 */
public final function Parser Parse()
{
    return _.text.Parse(self);
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