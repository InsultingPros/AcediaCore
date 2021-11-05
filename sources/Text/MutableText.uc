/**
 *  Mutable version of Acedia's `Text`
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
class MutableText extends Text;

var private int CODEPOINT_NEWLINE;

//      Every formatted `string` essentially consists of multiple differently
//  formatted (colored) parts. Such `string`s will be more convenient for us to
//  work with if we separate them from each other.
//      This structure represents one such block: maximum uninterrupted
//  substring, every character of which has identical formatting.
//      Do note that a single block does not define text formatting, -
//  it is defined by the whole sequence of blocks before it
//  (if `isOpening == false` you only know that you should change previous
//  formatting, but you do not know to what).
struct FormattedBlock
{
    //  Did this block start by opening or closing formatted part?
    //  Ignored for the very first block without any formatting.
    var bool        isOpening;
    //  Full text inside the block, without any formatting
    var array<int>  contents;
    //  Formatting tag for this block
    //  (ignored for `isOpening == false`)
    var string      tag;
    //  Whitespace symbol that separates tag from the `contents`;
    //  For the purposes of reassembling a `string` broken into blocks.
    //  (ignored for `isOpening == false`)
    var Character   delimiter;
};
//      Appending formatted `string` into the `MutableText` first requires to
//  split it into series of `FormattedBlock` and then extract code points with
//  the proper formatting from it.
//      This variable contains intermediary data.
var array<FormattedBlock>   splitBlocks;
//  Formatted `string` can have an arbitrary level of folded format definitions,
//  this array is used as a stack to keep track of opened formatting blocks
//  when appending formatted `string`.
var array<Formatting>       formattingStack;

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
 *  Appends contents of the formatted `string` to the caller `MutableText`.
 *
 *  @param  source              Formatted `string` to be appended to
 *      the caller `MutableText`.
 *  @param  defaultFormatting   Formatting to be used for `source`'s characters
 *      that have no color information defined.
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText AppendFormattedString(
    string              source,
    optional Formatting defaultFormatting)
{
    local int       i;
    local Parser    parser;
    SplitFormattedStringIntoBlocks(source);
    if (splitBlocks.length <= 0) {
        return self;
    }
    SetupFormattingStack(defaultFormatting);
    parser = Parser(_.memory.Allocate(class'Parser'));
    //  First element of `decomposedSource` is special and has
    //  no color information,
    //  see `SplitFormattedStringIntoBlocks()` for details.
    SetFormatting(defaultFormatting);
    AppendManyCodePoints(splitBlocks[0].contents);
    for (i = 1; i < splitBlocks.length; i += 1)
    {
        if (splitBlocks[i].isOpening)
        {
            parser.InitializeS(splitBlocks[i].tag);
            SetFormatting(PushIntoFormattingStack(parser));
        }
        else {
            SetFormatting(PopFormattingStack());
        }
        AppendManyCodePoints(splitBlocks[i].contents);
    }
    _.memory.Free(parser);
    return self;
}

//      Function that breaks formatted string into array of `FormattedBlock`s.
//      Returned array is guaranteed to always have at least one block.
//      First block in array always corresponds to part of the input string
//  (`source`) without any formatting defined, even if it's empty.
//  This is to avoid `FormattedBlock` having a third option besides two defined
//  by `isOpening` variable.
private final function SplitFormattedStringIntoBlocks(string source)
{
    local Parser            parser;
    local Character         nextCharacter;
    local FormattedBlock    nextBlock;
    splitBlocks.length = 0;
    parser = _.text.ParseString(source);
    while (!parser.HasFinished())
    {
        parser.MCharacter(nextCharacter);
        //  New formatted block by "{<color>"
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_OPEN_FORMAT))
        {
            splitBlocks[splitBlocks.length] = nextBlock;
            nextBlock = CreateFormattedBlock(true);
            parser.MUntilS(nextBlock.tag,, true)
                .MCharacter(nextBlock.delimiter);
            if (!parser.Ok()) {
                break;
            }
            continue;
        }
        //  New formatted block by "}"
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_CLOSE_FORMAT))
        {
            splitBlocks[splitBlocks.length] = nextBlock;
            nextBlock = CreateFormattedBlock(false);
            continue;
        }
        //  Escaped sequence
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_FORMAT_ESCAPE)) {
            parser.MCharacter(nextCharacter);
        }
        if (!parser.Ok()) {
            break;
        }
        nextBlock.contents[nextBlock.contents.length] = nextCharacter.codePoint;
    }
    //  Only put in empty block if there is nothing else.
    if (nextBlock.contents.length > 0 || splitBlocks.length == 0) {
        splitBlocks[splitBlocks.length] = nextBlock;
    }
    _.memory.Free(parser);
}

//      Following two functions are to maintain a "color stack" that will
//  remember unclosed colors (new colors are obtained from a parser) defined in
//  formatted string, on order.
//      Stack array always contains one element, defined by
//  the `SetupFormattingStack()` call. It corresponds to the default formatting
//  that will be used when we pop all the other elements.
//      It is necessary to deal with possible folded formatting definitions in
//  formatted strings.
//      For storing the color information we simply use `Text.Character`,
//  ignoring all information that is not related to colors.
private final function SetupFormattingStack(Text.Formatting defaultFormatting)
{
    formattingStack.length = 0;
    formattingStack[0] = defaultFormatting;
}

private final function Formatting PushIntoFormattingStack(
    Parser formattingDefinitionParser)
{
    local Formatting newFormatting;
    if (_.color.ParseWith(formattingDefinitionParser, newFormatting.color)) {
        newFormatting.isColored = true;
    }
    formattingStack[formattingStack.length] = newFormatting;
    return newFormatting;
}

private final function Formatting PopFormattingStack()
{
    local Formatting result;
    formattingStack.length = Max(1, formattingStack.length - 1);
    if (formattingStack.length > 0) {
        result = formattingStack[formattingStack.length - 1];
    }
    return result;
}

//  Helper method for a quick creation of a new `FormattedBlock`
private final function FormattedBlock CreateFormattedBlock(bool isOpening)
{
    local FormattedBlock newBlock;
    newBlock.isOpening = isOpening;
    return newBlock;
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
 *  @return Returns caller `Text`, to allow for method chaining.
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
 *      By default `0`, - that and all negative values are replaces by `MaxInt`,
 *      effectively extracting as much of a string as possible.
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
    if (maxLength <= 0) {
        maxLength = MaxInt;
    }
    endIndex    = Min(startIndex + maxLength, GetLength()) - 1;
    startIndex  = Max(startIndex, 0);
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

defaultproperties
{
    CODEPOINT_NEWLINE = 10
}