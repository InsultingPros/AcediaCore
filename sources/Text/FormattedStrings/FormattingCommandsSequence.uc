/**
 *      Formatted string can be thought of as a string with a sequence of
 *  formatting-changing commands specified within it, along with raw contents
 *  to be pasted before performing next command (for more information about this
 *  see `FormattingStringParser`). This is a class for an accessor object
 *  that can return these individual commands based on the given `Text`/`string`
 *  (alongside with the construction code that determines these commands).
 *      This objects allows to directly access these commands.
 *      Copyright 2022 Anton Tarasenko
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
class FormattingCommandsSequence extends AcediaObject
    dependson(BaseText);

enum FormattingCommandType
{
    //  Push more new formatting onto the stack. Corresponds to "{<color_tag> ".
    FST_StackPush,
    //  Pop formatting from the stack. Corresponds to "}".
    FST_StackPop,
    //  Swap the top value on the formatting stack for a different formatting
    //  (pushes new one, if the stack is empty). Corresponds to "^<color_char>".
    FST_StackSwap
};

/**
 *  Represents formatting command + contents, alongside some additional
 *  meta information, necessary for `FormattingStringParser`.
 */
struct FormattingCommand
{
    var FormattingCommandType   type;
    var array<Text.Character>   contents;

    //  Formatting character for the "^"-type tag
    //  This parameter is only used for `FST_StackSwap` command type.
    var BaseText.Character      charTag;

    //      Rest of the parameters are only used for `FST_StackPush`
    //  command type.
    //      These commands correspond to section openers ("{<color_tag> "):
    //  such openings define a *formatting block* between itself and matching
    //  closing curly braces "}".
    //      Meta information about these blocks is necessary for
    //  `FormattingStringParser`.

    //  Formatting tag for the next block - "<color_tag>" from "{<color_tag> ".
    var MutableText             tag;
    //      When formatting block for this command started and ended -
    //  necessary for gradient coloring.
    //      `closeIndex` should be equal to `-1` if it is not defined.
    var int                     openIndex;
    var int                     closeIndex;
};
//  All the commands we got from formatted string
var private array<FormattingCommand>    commandSequence;
//  Store contents for the next command here, because constantly appending array
//  inside the struct (`FormattingCommand` here) is expensive.
var private array<Text.Character>       currentContents;
//  `Parser` used to break input formatted string into commands.
//  It is only used during building this object (inside `BuildSelf()` method).
var private Parser                      parser;
//      How many non-formatting defining characters we have parsed.
//      That is characters that are actually meant to be displayed to the user
//  and not the part of formatting definitions (e.g. "{$red", "}" or "^r";
//  "&{", "&&" or "&^" are also resolved into a single displayed character).
//      `Parser`'s `GetParsedLength()` method is unusable here, since it
//  reports all parsed characters.
var private int                         characterCounter;
//      Command we are currently building.
//      Making it a field makes code simpler and lets us avoid passing
//  `FormattingCommand` struct between functions.
var private FormattingCommand           currentCommand;
//      `FormattingErrorsReport` we are given to report errors to.
//      It is considered "borrowed": we do not really own it and will not
//  deallocate it.
//      Since, similar to `parser` field, it is only used during building this
//  object - there is no danger of it being deallocated while we are storing
//  this reference.
//      Only set as a field for convenience, to avoid passing it as a parameter
//  between methods during parsing.
var private FormattingErrorsReport      borrowedErrors;

//  Stack that keeps track of which (by index inside `commandSequence`) command
//  opened section we are currently parsing. This is needed to record positions
//  at which each block is opened and closed.

//      It is easy to record opening indices for each formatting block by
//  recording how many characters we have already processed before encountering
//  opening statement "{<color_tag> ". But to record closing indices we need to
//  correspond correct opener with correct closer ("}").
//      We accomplish that by keeping track of all formatted blocks opened
//  at the current moment during parsing in a stack and popping the top value
//  upon reaching "}".
//      We identify each formatting block by recording index of corresponding
//  `FormattingCommand` inside `commandSequence` array. This makes setting
//  appropriate `closeIndex` simple.
var private array<int> pushCommandIndicesStack;

const CODEPOINT_OPEN_FORMAT     = 123;  //  '{'
const CODEPOINT_CLOSE_FORMAT    = 125;  //  '}'
const CODEPOINT_FORMAT_ESCAPE   = 38;   //  '&'
const CODEPOINT_ACCENT          = 94;   //  '^'

protected function Finalizer()
{
    local int i;
    for (i = 0; i < commandSequence.length; i += 1) {
        _.memory.Free(commandSequence[i].tag);
    }
    pushCommandIndicesStack.length  = 0;
    currentContents.length          = 0;
    commandSequence.length          = 0;
    characterCounter                = 0;
    //  These fields should not be set at this point, but clean them up
    //  just in case
    _.memory.Free(parser);
    parser          = none;
    borrowedErrors  = none;
}

/**
 *  Create `FormattingCommandsSequence` based on the given `Text`.
 *
 *  There is not separate method for `string`, since we would require reading it
 *  into a `Text` as a *plain string* first anyway and, as this class is
 *  technical/internal, no convenience methods are needed.
 *
 *  @param  input           `Text` that should be treated as "formatted" and
 *      to be broken into formatting commands.
 *  @param  errorsReporter  If specified, will be used to report errors detected
 *      during construction of `FormattingCommandsSequence`
 *      (can only report `FSE_UnmatchedClosingBrackets`).
 *  @return New `FormattingCommandsSequence` instance that allows us to have
 *      direct access to formatting commands defined in `input`.
 */
public final static function FormattingCommandsSequence FromText(
    BaseText                        input,
    optional FormattingErrorsReport errorsReporter)
{
    local FormattingCommandsSequence newSequence;
    newSequence = FormattingCommandsSequence(
        __().memory.Allocate(class'FormattingCommandsSequence'));
    //  Setup variables
    newSequence.parser          = __().text.Parse(input);
    newSequence.borrowedErrors  = errorsReporter;
    //  Parse
    newSequence.BuildSelf();
    //  Clean up
    __().memory.Free(newSequence.parser);
    newSequence.parser          = none;
    newSequence.borrowedErrors  = none;
    return newSequence;
}

/**
 *  Amount of commands to reconstruct formatted string caller
 *  `FormattingCommandsSequence` was created from.
 *
 *  @return Amount of commands inside caller `FormattingCommandsSequence`.
 */
public final function int GetAmount()
{
    return commandSequence.length;
}

/**
 *  Returns command with index `commandIndex`. Indexation starts from `0`.
 *
 *  @param  commandIndex    Index of the command to return.
 *      Must be non-negative (`>= 0`) and less than `GetAmount()`.
 *  @return Command with index `commandIndex`.
 *      If given `commandIndex` is out of bounds - returns invalid command.
 *      `tag` field is guaranteed to be non-`none` for commands of type
 *      `FST_StackPush` and should be deallocated, as per usual rules.
 */
public final function FormattingCommand GetCommand(int commandIndex)
{
    local MutableText       resultTag;
    local FormattingCommand result;
    if (commandIndex < 0)                       return result;
    if (commandIndex >= commandSequence.length) return result;

    result = commandSequence[commandIndex];
    resultTag = result.tag;
    if (resultTag != none) {
        result.tag = resultTag.MutableCopy();
    }
    return result;
}

private final function BuildSelf()
{
    local BaseText.Character nextCharacter;
    while (!parser.HasFinished())
    {
        parser.MCharacter(nextCharacter);
        //  New command by "{<formatting_info> "
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_OPEN_FORMAT))
        {
            AddCommand(FST_StackPush);
            parser
                .MUntil(currentCommand.tag,, true)
                .MCharacter(currentCommand.charTag); //  Simply to skip a char
            continue;
        }
        //  New command by "}"
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_CLOSE_FORMAT))
        {
            AddCommand(FST_StackPop);
            continue;
        }
        //  New command by "^"
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_ACCENT))
        {
            AddCommand(FST_StackSwap);
            parser.MCharacter(currentCommand.charTag);
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
        currentContents[currentContents.length] = nextCharacter;
        characterCounter += 1;
    }
    //  Only put in empty command if it is push command or there is nothing else
    if (    currentCommand.type == FST_StackPush
        ||  currentContents.length > 0 || commandSequence.length == 0)
    {
        currentCommand.contents = currentContents;
        commandSequence[commandSequence.length] = currentCommand;
    }
    //  We no longer use `currentCommand` and have transferred ownership over
    //  `currentCommand.tag` to the `commandSequence`, so better forget about it
    //  to avoid messing up.
    currentCommand.tag = none;
}

//  Helper method for a adding `currentCommand` to the command sequence and
//  quick creation of a new `FormattingCommand` in its place
private final function AddCommand(FormattingCommandType newStackCommandType)
{
    local int               lastPushIndex;
    local int               lastCharacterIndex;
    local FormattingCommand newCommand;
    currentCommand.contents = currentContents;
    currentContents.length = 0;
    commandSequence[commandSequence.length] = currentCommand;
    //  Last (so far) character index in a string equals total amount of
    //  parsed characters minus one
    lastCharacterIndex = characterCounter - 1;
    if (newStackCommandType == FST_StackPop)
    {
        lastPushIndex = PopIndex();
        if (lastPushIndex >= 0) {
            commandSequence[lastPushIndex].closeIndex = lastCharacterIndex;
        }
        else if (borrowedErrors != none) {
            borrowedErrors.Report(FSE_UnmatchedClosingBrackets);
        }
    }
    newCommand.type = newStackCommandType;
    if (newStackCommandType == FST_StackPush)
    {
        //  Formatting should be applied to the next character,
        //  not the currently last added one
        newCommand.openIndex    = lastCharacterIndex + 1;
        newCommand.closeIndex   = -1;
        //  `FormattingCommand` that new formatting block corresponds to
        //  is not added yet, but it is guaranteed to be added next,
        //  we know its future index
        PushIndex(commandSequence.length);
    }
    currentCommand = newCommand;
}

private final function int PopIndex()
{
    local int result;
    if (pushCommandIndicesStack.length <= 0) {
        return -1;
    }
    result = pushCommandIndicesStack[pushCommandIndicesStack.length - 1];
    pushCommandIndicesStack.length = pushCommandIndicesStack.length - 1;
    return result;
}

private final function PushIndex(int index)
{
    pushCommandIndicesStack[pushCommandIndicesStack.length] =
        commandSequence.length;
}

defaultproperties
{
}