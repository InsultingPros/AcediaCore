/**
 *      Formatted string can be thought of as a string with a sequence of
 *  formatting-changing commands specified within it (either by opening new
 *  formatting block, swapping to color with "^" or by closing it and reverting
 *  to the previous one).
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
class FormattingCommandList extends AcediaObject
    dependson(Text);

enum FormattingCommandType
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
//      *   Each time a new section opens ("{<color_tag> ") we put another,
//          current formatting on top of the stack;
//      *   Each time a section closes ("}") we pop the stack, returning to
//          a previous formatting.
//      *   In a special case of "^" color swap that is supposed to last until
//          current block closes we simply swap the color of the formatting on
//          top of the stack.
struct FormattingCommand
{
    //      Only defined for `FST_StackPush` commands that correspond to section
    //  openers ("{<color_tag> ").
    //      Indices of first and last character belonging to block it opens.
    var int                     openIndex;
    var int                     closeIndex;
    //  Did this block start by opening or closing formatted part?
    //  Ignored for the very first block without any formatting.
    var FormattingCommandType   type;
    //  Full text inside the block, without any formatting
    var array<Text.Character>   contents;
    //  Formatting tag for the next block
    //  (only used for `FST_StackPush` command type)
    var MutableText             tag;
    //  Formatting character for the "^"-type tag
    //  (only used for `FST_StackSwap` command type)
    var Text.Character          charTag;
};
//      Appending formatted `string` into the `MutableText` first requires its
//  transformation into series of `FormattingCommand` and then their
//  execution to assemble the `MutableText`.
//      First element of `commandList` is special and is used solely as
//  a container for unformatted data. It should not be used to execute
//  formatting stack commands.
//      This variable contains intermediary data.
var private array<FormattingCommand> commandList;

//  Stack that keeps track of which (by index inside `commandList`) command
//  opened section we are currently parsing. This is needed to record positions
//  at which each block is opened and closed.
var private array<int>              pushCommandIndicesStack;
//  Store contents for the next command here, because appending array in
//  the struct is expensive
var private array<Text.Character>   currentContents;
//  `Parser` used to break input formatted string into commands, only used
//  during building this object (inside `BuildSelf()` method).
var private Parser                  parser;
//  `FormattingErrors` object used to reports errors during building process.
//  It is "borrowed" - meaning that we do not really own it and should not
//  deallocate it. Only set as a field for convenience.
var private FormattingErrors        borrowedErrors;

const CODEPOINT_ESCAPE          = 27;   //  ASCII escape code
const CODEPOINT_OPEN_FORMAT     = 123;  //  '{'
const CODEPOINT_CLOSE_FORMAT    = 125;  //  '}'
const CODEPOINT_FORMAT_ESCAPE   = 38;   //  '&'
const CODEPOINT_ACCENT          = 94;   //  '^'
const CODEPOINT_TILDE           = 126;  //  '~'

protected function Finalizer()
{
    local int i;
    _.memory.Free(parser);
    parser          = none;
    borrowedErrors  = none;
    if (currentContents.length > 0) {
        currentContents.length = 0;
    }
    if (pushCommandIndicesStack.length > 0) {
        pushCommandIndicesStack.length = 0;
    }
    for (i = 0; i < commandList.length; i += 1) {
        _.memory.Free(commandList[i].tag);
    }
    if (commandList.length > 0) {
        commandList.length = 0;
    }
}

/**
 *  Create `FormattingCommandList` based on given `Text`.
 *
 *  @param  input           `Text` that should be treated as "formatted" and
 *      to be broken into formatting commands.
 *  @param  errorsReporter  If specified, will be used to report errors
 *      (can only report `FSE_UnmatchedClosingBrackets`).
 *  @return New `FormattingCommandList` instance that allows us to have direct
 *      access to formatting commands.
 */
public final static function FormattingCommandList FromText(
    Text                        input,
    optional FormattingErrors   errorsReporter)
{
    local FormattingCommandList newList;
    newList = FormattingCommandList(
        __().memory.Allocate(class'FormattingCommandList'));
    newList.parser          = __().text.Parse(input);
    newList.borrowedErrors  = errorsReporter;
    newList.BuildSelf();
    __().memory.Free(newList.parser);
    newList.parser          = none;
    newList.borrowedErrors  = none;
    return newList;
}

/**
 *  Returns command with index `commandIndex`.
 *
 *  @param  commandIndex    Index of the command to return.
 *      Must be non-negative (`>= 0`) and less than `GetAmount()`.
 *  @return Command with index `commandIndex`.
 *      If given `commandIndex` is out of bounds - returns invalid command.
 *      `tag` field is guaranteed to be non-`none` and should be deallocated.
 */
public final function FormattingCommand GetCommand(int commandIndex)
{
    local MutableText       resultTag;
    local FormattingCommand result;
    if (commandIndex < 0)                   return result;
    if (commandIndex >= commandList.length) return result;

    result = commandList[commandIndex];
    resultTag = result.tag;
    if (resultTag != none) {
        result.tag = resultTag.MutableCopy();
    }
    return result;
}

/**
 *  Returns amount of commands inside caller `FormattingCommandList`.
 *
 *  @return Amount of commands inside caller `FormattingCommandList`.
 */
public final function int GetAmount()
{
    return commandList.length;
}

//  Method that turns `parser` into proper `FormattingCommandList` object.
private final function BuildSelf()
{
    //local int i;
    local int               characterCounter;
    local Text.Character    nextCharacter;
    local FormattingCommand nextCommand;
    while (!parser.HasFinished())
    {
        parser.MCharacter(nextCharacter);
        //  New command by "{<formatting_info>"
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_OPEN_FORMAT))
        {
            nextCommand = AddCommand(nextCommand, FST_StackPush, characterCounter);
            parser.MUntil(nextCommand.tag,, true)
                .MCharacter(nextCommand.charTag); //  Simply to skip a char
            continue;
        }
        //  New command by "}"
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_CLOSE_FORMAT))
        {
            nextCommand = AddCommand(nextCommand, FST_StackPop, characterCounter);
            continue;
        }
        //  New command by "^"
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_ACCENT))
        {
            nextCommand = AddCommand(nextCommand, FST_StackSwap, characterCounter);
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
        currentContents[currentContents.length] = nextCharacter;
        characterCounter += 1;
    }
    //  Only put in empty command if there is nothing else.
    if (currentContents.length > 0 || commandList.length == 0)
    {
        nextCommand.contents = currentContents;
        commandList[commandList.length] = nextCommand;
    }
    /*for (i = 0; i < commandList.length; i += 1)
    {
        Log(">>>COMMAND LIST FOR" @ i $ "<<<");
        Log("OPEN/CLOSE:" @ commandList[i].openIndex @ "/" @ commandList[i].closeIndex);
        Log("TYPE:" @ commandList[i].type);
        Log("CONTETS LENGTH:" @ commandList[i].contents.length);
        if (commandList[i].tag != none) {
            Log("TAG:" @ commandList[i].tag.ToString());
        }
        else {
            Log("TAG: NONE");
        }
    }*/
}

//  Helper method for a quick creation of a new `FormattingCommand`
private final function FormattingCommand AddCommand(
    FormattingCommand       nextCommand,
    FormattingCommandType   newStackCommandType,
    optional int            currentCharacterIndex)
{
    local int               lastPushIndex;
    local FormattingCommand newCommand;
    nextCommand.contents = currentContents;
    if (currentContents.length > 0) {
        currentContents.length = 0;
    }
    commandList[commandList.length] = nextCommand;
    if (newStackCommandType == FST_StackPop)
    {
        lastPushIndex = PopIndex();
        if (lastPushIndex >= 0) {
            // BLABLA
            commandList[lastPushIndex].closeIndex = currentCharacterIndex - 1;
        }
        else if (borrowedErrors != none) {
            borrowedErrors.Report(FSE_UnmatchedClosingBrackets);
        }
    }
    newCommand.type = newStackCommandType;
    if (newStackCommandType == FST_StackPush)
    {
        newCommand.openIndex    = currentCharacterIndex;
        newCommand.closeIndex   = -1;
        // BLABLA
        PushIndex(commandList.length);
    }
    return newCommand;
}

private final function PushIndex(int index)
{
    pushCommandIndicesStack[pushCommandIndicesStack.length] =
        commandList.length;
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

defaultproperties
{
}