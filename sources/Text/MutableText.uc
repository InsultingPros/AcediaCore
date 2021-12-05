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

var private int CODEPOINT_NEWLINE, CODEPOINT_ACCENT;

enum FormattedStackCommandType
{
    //  Push more data onto formatted stack
    FST_StackPush,
    //  Pop data from formatted stack
    FST_StackPop,
    //  Swap the top value on the formatting stack
    FST_StackSwap
};

//      Formatted `string` is separated into several (possibly nested) parts,
//  each with its own formatting. These can be easily handled with a formatting
//  stack:
//      *   Each time a new section opens ("{<color_tag ") we put another,
//          current formatting on top of the stack;
//      *   Each time a section closes ("}") we pop the stack, returning to
//          a previous formatting.
//      *   In a special case of "^" color swap that is supposed to last until
//          current block closes we simply swap the color of the formatting on
//          top of the stack.
//      Logic that parses formatted `string` works is broken into two steps:
//      1.  Read formatted `string` detecting "{<color_tag ", "}" and "^"
//          sequences and build a series of stack commands (along with data that
//          should be appended after them);
//      2.  use these commands to construct `MutableText`.
struct FormattedStackCommand
{
    //  Did this block start by opening or closing formatted part?
    //  Ignored for the very first block without any formatting.
    var FormattedStackCommandType   type;
    //  Full text inside the block, without any formatting
    var array<int>                  contents;
    //  Formatting tag for the next block
    //  (only used for `FST_StackPush` command type)
    var MutableText                 tag;
    //  Formatting character for the "^"-type tag
    //  (only used for `FST_StackSwap` command type)
    var Character                   charTag;
};
//      Appending formatted `string` into the `MutableText` first requires its
//  transformation into series of `FormattedStackCommand` and then their
//  execution to assemble the `MutableText`.
//      First element of `stackCommands` is special and is used solely as
//  a container for unformatted data. It should not be used to execute
//  formatting stack commands.
//      This variable contains intermediary data.
var array<FormattedStackCommand>    stackCommands;
//  Formatted `string` can have an arbitrary level of folded format definitions,
//  this array is used as a stack to keep track of opened formatting blocks
//  when appending formatted `string`.
var array<Formatting>               formattingStack;

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
 *  Appends contents of the formatted `Text` to the caller `MutableText`.
 *
 *  @param  source              `Text` (with formatted string contents) to be
 *      appended to the caller `MutableText`.
 *  @param  defaultFormatting   Formatting to apply to `source`'s character that
 *      do not have it specified. For example, `defaultFormatting.isColored`,
 *      but some of `other`'s characters do not have a color defined -
 *      they will be appended with a specified color.
 *  @return Caller `MutableText` to allow for method chaining.
 */
public final function MutableText AppendFormatted(
    Text                source,
    optional Formatting defaultFormatting)
{
    local Parser parser;
    parser = _.text.Parse(source);
    AppendFormattedParser(parser, defaultFormatting);
    parser.FreeSelf();
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
    local Parser parser;
    parser = _.text.ParseString(source);
    AppendFormattedParser(parser, defaultFormatting);
    parser.FreeSelf();
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
private final function MutableText AppendFormattedParser(
    Parser              sourceParser,
    optional Formatting defaultFormatting)
{
    local int       i;
    local Parser    tagParser;
    BuildFormattingStackCommands(sourceParser);
    if (stackCommands.length <= 0) {
        return self;
    }
    SetupFormattingStack(defaultFormatting);
    tagParser = Parser(_.memory.Allocate(class'Parser'));
    SetFormatting(defaultFormatting);
    //  First element of color stack is special and has no color information;
    //  see `BuildFormattingStackCommands()` for details.
    AppendManyCodePoints(stackCommands[0].contents);
    for (i = 1; i < stackCommands.length; i += 1)
    {
        if (stackCommands[i].type == FST_StackPush)
        {
            tagParser.Initialize(stackCommands[i].tag);
            SetFormatting(PushIntoFormattingStack(tagParser));
        }
        else if (stackCommands[i].type == FST_StackPop) {
            SetFormatting(PopFormattingStack());
        }
        else if (stackCommands[i].type == FST_StackSwap) {
            SetFormatting(SwapFormattingStack(stackCommands[i].charTag));
        }
        AppendManyCodePoints(stackCommands[i].contents);
        _.memory.Free(stackCommands[i].tag);
    }
    stackCommands.length = 0;
    _.memory.Free(tagParser);
    return self;
}

//      Function that parses formatted `string` into array of
//  `FormattedStackCommand`s.
//      Returned array is guaranteed to always have at least one element.
//      First element in array always corresponds to part of the input string
//  (`source`) without any formatting defined, even if it's empty.
//  This is to avoid having fourth command type, only usable at the beginning.
private final function BuildFormattingStackCommands(Parser parser)
{
    local Character             nextCharacter;
    local FormattedStackCommand nextCommand;
    stackCommands.length = 0;
    while (!parser.HasFinished())
    {
        parser.MCharacter(nextCharacter);
        //  New command by "{<color>"
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_OPEN_FORMAT))
        {
            stackCommands[stackCommands.length] = nextCommand;
            nextCommand = CreateStackCommand(FST_StackPush);
            parser.MUntil(nextCommand.tag,, true)
                .MCharacter(nextCommand.charTag); //  Simply to skip a char
            continue;
        }
        //  New command by "}"
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_CLOSE_FORMAT))
        {
            stackCommands[stackCommands.length] = nextCommand;
            nextCommand = CreateStackCommand(FST_StackPop);
            continue;
        }
        //  New command by "^"
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_ACCENT))
        {
            stackCommands[stackCommands.length] = nextCommand;
            nextCommand = CreateStackCommand(FST_StackSwap);
            parser.MCharacter(nextCommand.charTag);
            if (!parser.Ok()) {
                break;
            }
            continue;
        }
        //  Escaped sequence
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_FORMAT_ESCAPE)) {
            parser.MCharacter(nextCharacter);
        }
        if (!parser.Ok()) {
            break;
        }
        nextCommand.contents[nextCommand.contents.length] =
            nextCharacter.codePoint;
    }
    //  Only put in empty command if there is nothing else.
    if (nextCommand.contents.length > 0 || stackCommands.length == 0) {
        stackCommands[stackCommands.length] = nextCommand;
    }
}

//      Following four functions are to maintain a "color stack" that will
//  remember unclosed colors (new colors are obtained from formatting commands
//  sequence) defined in formatted string, in order.
//      Stack array always contains one element, defined by
//  the `SetupFormattingStack()` call. It corresponds to the default formatting
//  that will be used when we pop all the other elements.
//      It is necessary to deal with possible folded formatting definitions in
//  formatted strings.
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

private final function Formatting SwapFormattingStack(Character tagCharacter)
{
    local Formatting updatedFormatting;
    if (formattingStack.length <= 0) {
        return updatedFormatting;
    }
    updatedFormatting = formattingStack[formattingStack.length - 1];
    if (_.color.ResolveShortTagColor(tagCharacter, updatedFormatting.color)) {
        updatedFormatting.isColored = true;
    }
    formattingStack[formattingStack.length - 1] = updatedFormatting;
    return updatedFormatting;
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

//  Helper method for a quick creation of a new `FormattedStackCommand`
private final function FormattedStackCommand CreateStackCommand(
    FormattedStackCommandType stackCommandType)
{
    local FormattedStackCommand newCommand;
    newCommand.type = stackCommandType;
    return newCommand;
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

/**
 *  Removes all characters in range, specified as
 *  `[startIndex; startIndex + maxLength - 1]`.
 *
 *  If provided parameters `startPosition` and `maxLength` define a range that
 *  goes beyond `[0; self.GetLength() - 1]`, then intersection with a valid
 *  range will be used.
 *
 *  @param  startIndex      Position of the first character to get removed.
 *  @param  maxLength       Max length of the segment to get removed.
 *      By default `0` - that and all negative values are replaces by `MaxInt`,
 *      effectively removing as much characters to the right of `startIndex`
 *      as possible.
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
    CODEPOINT_NEWLINE   = 10
    CODEPOINT_ACCENT    = 94
}