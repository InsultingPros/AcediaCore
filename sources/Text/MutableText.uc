/**
 *  Mutable version of Acedia's `Text`
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
class MutableText extends Text;

var private int CODEPOINT_NEWLINE;

/**
 *  Clears all current data from the caller `MutableText` instance.
 *
 *  @return Returns caller `MutableText` to allow for method chaining.
 */
public final function MutableText Clear()
{
    DropCodePoints();
    return self;
}

/**
 *  Appends a new character to the caller `MutableText`, while discarding its
 *  own formatting.
 *
 *  @param  newCharacter        Character to add to the caller `MutableText`.
 *      Only valid characters will be added. Its formatting will be discarded.
 *  @param  characterFormatting You can use this parameter to specify formatting
 *      `newCharacter` should have in the caller `MutableText` instead of
 *      its own.
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText AppendRawCharacter(
    Text.Character      newCharacter,
    optional Formatting characterFormatting)
{
    if (!_.text.IsValidCharacter(newCharacter)) {
        return self;
    }
    SetFormatting(characterFormatting);
    return MutableText(AppendCodePoint(newCharacter.codePoint));
}

/**
 *  Appends all characters from the given array, in order, but discarding their
 *  own formatting.
 *
 *  This method should be faster than `AppendManyCharacters()` or several calls
 *  of `AppendRawCharacter()`, since it does not need to check whether
 *  formatting is changed from character to character.
 *
 *  @param  newCharacters   Characters to be added to the caller `MutableText`.
 *      Only valid characters will be added. Their formatting will be discarded.
 *  @param  characterFormatting You can use this parameter to specify formatting
 *      `newCharacters` should have in the caller `MutableText` instead of
 *      their own.
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText AppendManyRawCharacters(
    array<Text.Character>   newCharacters,
    optional Formatting     charactersFormatting)
{
    local int i;
    SetFormatting(charactersFormatting);
    for (i = 0; i < newCharacters.length; i += 1) {
        AppendCodePoint(newCharacters[i].codePoint);
    }
    return self;
}

/**
 *  Appends a new character to the caller `MutableText`.
 *
 *  @param  newCharacter    Character to add to the caller `MutableText`.
 *      Only valid characters will be added.
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText AppendCharacter(Text.Character newCharacter)
{
    if (!_.text.IsValidCharacter(newCharacter)) {
        return self;
    }
    SetFormatting(newCharacter.formatting);
    return MutableText(AppendCodePoint(newCharacter.codePoint));
}

/**
 *  Appends all characters from the given array, in order.
 *
 *  @param  newCharacters   Characters to be added to the caller `MutableText`.
 *      Only valid characters will be added.
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText AppendManyCharacters(
    array<Text.Character> newCharacters)
{
    local int i;
    for (i = 0; i < newCharacters.length; i += 1) {
        AppendCharacter(newCharacters[i]);
    }
    return self;
}

/**
 *  Adds new line character to the end of the caller `MutableText`.
 *
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText AppendNewLine()
{
    AppendCodePoint(CODEPOINT_NEWLINE);
    return self;
}

/**
 *  Converts caller `MutableText` instance into lower case.
 */
public final function ToLower()
{
    ConvertCase(true);
}

/**
 *  Converts caller `MutableText` instance into upper case.
 */
public final function ToUpper()
{
    ConvertCase(false);
}

/**
 *  Appends new line character to the caller `MutableText`.
 *
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText AppendLineBreak()
{
    AppendCodePoint(CODEPOINT_NEWLINE);
    return self;
}

/**
 *  Appends contents of another `Text` to the caller `MutableText`.
 *
 *  @param  other               Instance of `Text`, which content method must
 *      append. Appends nothing if passed value is `none`.
 *  @param  defaultFormatting   Formatting to apply to `other`'s character that
 *      do not have it specified. For example, `defaultFormatting.isColored`,
 *      but some of `other`'s characters do not have a color defined -
 *      they will be appended with a specified color.
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText Append(
    Text                other,
    optional Formatting defaultFormatting)
{
    local int           i;
    local int           otherLength;
    local Character     nextCharacter;
    local Formatting    newFormatting;
    if (other == none) {
        return self;
    }
    SetFormatting(defaultFormatting);
    otherLength = other.GetLength();
    for (i = 0; i < otherLength; i += 1)
    {
        nextCharacter = other.GetRawCharacter(i);
        if (other.IsFormattingChangedAt(i))
        {
            newFormatting = other.GetFormatting(i);
            //  If default formatting is specified, but `other`'s formatting
            //  (at least for some characters) is not, - apply default one
            if (defaultFormatting.isColored && !newFormatting.isColored)
            {
                newFormatting.isColored = true;
                newFormatting.color     = defaultFormatting.color;
            }
            SetFormatting(newFormatting);
        }
        AppendCodePoint(nextCharacter.codePoint);
    }
    return self;
}

/**
 *  Appends contents of the plain `string` to the caller `MutableText`.
 *
 *  @param  source              Plain `string` to be appended to
 *      the caller `MutableText`.
 *  @param  defaultFormatting   Formatting to be used for `source`'s characters.
 *      By default defines 'null' formatting (no color set).
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText AppendString(
    string              source,
    optional Formatting defaultFormatting)
{
    local int i;
    local int sourceLength;

    sourceLength = Len(source);
    SetFormatting(defaultFormatting);
    //  Decompose `source` into integer codes
    for (i = 0; i < sourceLength; i += 1) {
        AppendCodePoint(Asc(Mid(source, i, 1)));
    }
    return self;
}

/**
 *  Appends contents of the colored `string` to the caller `MutableText`.
 *
 *  @param  source              Colored `string` to be appended to
 *      the caller `MutableText`.
 *  @param  defaultFormatting   Formatting to be used for `source`'s characters
 *      that have no color information defined.
 *      By default defines 'null' formatting (no color set).
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText AppendColoredString(
    string              source,
    optional Formatting defaultFormatting)
{
    local int           i;
    local int           sourceLength;
    local array<int>    sourceAsIntegers;
    local Formatting    newFormatting;

    //  Decompose `source` into integer codes
    sourceLength = Len(source);
    for (i = 0; i < sourceLength; i += 1) {
        sourceAsIntegers[sourceAsIntegers.length] = Asc(Mid(source, i, 1));
    }
    //  With colored strings we only need to care about color for formatting
    i = 0;
    newFormatting = defaultFormatting;
    SetFormatting(newFormatting);
    while (i < sourceLength)
    {
        if (sourceAsIntegers[i] == CODEPOINT_ESCAPE)
        {
            if (i + 3 >= sourceLength) break;
            newFormatting.isColored = true;
            newFormatting.color     = _.color.RGB(sourceAsIntegers[i + 1],
                                                    sourceAsIntegers[i + 2],
                                                    sourceAsIntegers[i + 3]);
            i += 4;
            SetFormatting(newFormatting);
        }
        else
        {
            AppendCodePoint(sourceAsIntegers[i]);
            i += 1;
        }
    }
    return self;
}

/**
 *  Appends contents of the formatted `Text` to the caller `MutableText`.
 *
 *  @param  source  `Text` (with formatted string contents) to be
 *      appended to the caller `MutableText`.
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText AppendFormatted(
    Text                source,
    optional Formatting defaultFormatting)
{
    class'FormattingStringParser'.static.ParseFormatted(source, self);
    return self;
}

/**
 *  Appends contents of the formatted `string` to the caller `MutableText`.
 *
 *  @param  source  Formatted `string` to be appended to
 *      the caller `MutableText`.
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText AppendFormattedString(
    string              source,
    optional Formatting defaultFormatting)
{
    local Text sourceAsText;
    sourceAsText = _.text.FromString(source);
    AppendFormatted(sourceAsText);
    _.memory.Free(sourceAsText);
    return self;
}

/**
 *  Unlike `Text`, `MutableText` can change it's content and therefore it's
 *  hash code cannot depend on it. So we restore `AcediaObject`'s behavior and
 *  return random value, generated at the time of allocation.
 *
 *  @return Hash code for the caller `MutableText`.
 */
protected function int CalculateHashCode()
{
    return super(AcediaObject).GetHashCode();
}

/**
 *  Replaces every occurrence of the string `before` with the string `after`.
 *
 *  @param  before              `Text` contents to match and then replace.
 *  @param  after               `Text` contents to replace `before` with.
 *  @param  caseSensitivity     Defines whether `before` should be matched
 *      in a case-sensitive manner. By default it will be.
 *  @param  formatSensitivity   Defines whether `before` should be matched
 *      in a way sensitive for color information. By default it is will not.
 *  @return Returns caller `MutableText`, to allow for method chaining.
 */
public final function MutableText Replace(
    Text                        before,
    Text                        after,
    optional CaseSensitivity    caseSensitivity,
    optional FormatSensitivity  formatSensitivity)
{
    local int   index;
    local bool  needToInsertReplacer;
    local int   nextReplacementIndex;
    local Text  selfCopy;
    if (before == none)     return self;
    if (before.IsEmpty())   return self;

    selfCopy = Copy();
    Clear();
    while (index < selfCopy.GetLength())
    {
        nextReplacementIndex = selfCopy.IndexOf(before, index,
                                                caseSensitivity,
                                                formatSensitivity);
        if (nextReplacementIndex < 0)
        {
            needToInsertReplacer    = false;
            nextReplacementIndex    = selfCopy.GetLength();
        }
        else {
            needToInsertReplacer    = true;
        }
        //  Copy characters between replacements one by one
        while (index < nextReplacementIndex)
        {
            AppendCharacter(selfCopy.GetCharacter(index));
            index += 1;
        }
        if (needToInsertReplacer)
        {
            Append(after);
            //  `before.GetLength() > 0` because of entry conditions
            index += before.GetLength();
        }
    }
    selfCopy.FreeSelf();
    return self;
}

/**
 *  Sets `newFormatting` for every non-formatted character in the caller `Text`.
 *
 *  @param  newFormatting   Formatting to use for all non-formatted character in
 *      the caller `Text`. If `newFormatting` is not colored itself -
 *      method does nothing.
 *  @return Returns caller `MutableText`, to allow for method chaining.
 */
public final function MutableText ChangeDefaultFormatting(
    Formatting newFormatting)
{
    _changeDefaultFormatting(newFormatting);
    return self;
}

/**
 *  Changes formatting for characters with indices in range, specified as
 *  `[startIndex; startIndex + maxLength - 1]` to `newFormatting` parameter.
 *
 *  If provided parameters `startPosition` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  newFormatting   New formatting to apply.
 *  @param  startIndex      Position of the first character to change formatting
 *      of. By default `0`, corresponding to the very first character.
 *  @param  maxLength       Max length of the segment to change formatting of.
 *      By default `0` - that and all negative values mean that method should
 *      reformat all characters to the right of `startIndex`.
 *  @return Reference to the caller `MutableText` to allow for method chaining.
 */
public final function MutableText ChangeFormatting(
    Formatting      newFormatting,
    optional int    startIndex,
    optional int    maxLength)
{
    local int endIndex;
    if (startIndex >= GetLength()) {
        return self;
    }
    endIndex    = startIndex + maxLength - 1;
    startIndex  = Max(startIndex, 0);
    if (maxLength <= 0) {
        endIndex = GetLength() - 1;
    }
    if (startIndex > endIndex) {
        return self;
    }
    if (startIndex == 0 && endIndex == GetLength() - 1) {
        ReformatWhole(newFormatting);
    }
    else {
        ReformatRange(startIndex, endIndex, newFormatting);
    }
    return self;
}

/**
 *  Removes all characters in range, specified as
 *  `[startIndex; startIndex + maxLength - 1]`.
 *
 *  If provided parameters `startPosition` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startIndex  Position of the first character to get removed.
 *  @param  maxLength   Max length of the segment to get removed.
 *      By default `0` - that and all negative values mean that method should
 *      remove all characters to the right of `startIndex`.
 *  @return Reference to the caller `MutableText` to allow for method chaining.
 */
public final function MutableText Remove(int startIndex, optional int maxLength)
{
    local int   index;
    local int   endIndex;
    local Text  selfCopy;
    if (startIndex >= GetLength()) {
        return self;
    }
    endIndex    = startIndex + maxLength - 1;
    startIndex  = Max(startIndex, 0);
    if (maxLength <= 0) {
        endIndex = GetLength() - 1;
    }
    if (startIndex > endIndex) {
        return self;
    }
    if (startIndex == 0 && endIndex == GetLength() - 1)
    {
        Clear();
        return self;
    }
    selfCopy = Copy();
    Clear();
    while (index < selfCopy.GetLength())
    {
        if (index >= startIndex && index <= endIndex) {
            index = endIndex + 1;
        }
        else
        {
            AppendCharacter(selfCopy.GetCharacter(index));
            index += 1;
        }
    }
    selfCopy.FreeSelf();
    return self;
}

/**
 *  Removes leading and trailing whitespaces from the caller `MutableText`.
 *  Optionally also reduces all sequences of internal whitespace characters to
 *  a single space (first space character in each sequence).
 *
 *  @param  fixInnerSpacings    By default `false` - only removes leading and
 *      trailing whitespace sequences from the caller `MutableText`.
 *      Setting this to `true` also makes method simplify sequences internal
 *      whitespace characters inside caller `MutableText`.
 *  @return Reference to the caller `MutableText` to allow for method chaining.
 */
public final function MutableText Simplify(optional bool fixInnerSpacings)
{
    local int   index;
    local int   leftIndex, rightIndex;
    local bool  isWhitespace, foundNonWhitespace;
    local Text  selfCopy;
    while (leftIndex < GetLength())
    {
        if (!_.text.IsWhitespace(GetCharacter(leftIndex)))
        {
            foundNonWhitespace = true;
            break;
        }
        leftIndex += 1;
    }
    if (!foundNonWhitespace)
    {
        Clear();
        return self;
    }
    rightIndex = GetLength() - 1;
    while (rightIndex >= 0)
    {
        if (!_.text.IsWhitespace(GetCharacter(rightIndex))) {
            break;
        }
        rightIndex -= 1;
    }
    selfCopy = Copy(leftIndex, rightIndex - leftIndex + 1);
    Clear();
    while (index < selfCopy.GetLength())
    {
        isWhitespace = _.text.IsWhitespace(selfCopy.GetCharacter(index));
        if (foundNonWhitespace || !isWhitespace) {
            AppendCharacter(selfCopy.GetCharacter(index));
        }
        if (fixInnerSpacings) {
            foundNonWhitespace = !isWhitespace;
        }
        index += 1;
    }
    selfCopy.FreeSelf();
    return self;
}

defaultproperties
{
    CODEPOINT_NEWLINE = 10
}