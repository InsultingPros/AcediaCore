/**
 *  Object that provides a buffer functionality for Killing Floor's (in-game)
 *  console output: it accepts content that user want to output and breaks it
 *  into lines that will be well-rendered according to the given
 *  `ConsoleDisplaySettings`.
 *      Copyright 2020 Anton Tarasenko
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
class ConsoleBuffer extends AcediaObject
    dependson(BaseText)
    dependson(ConsoleAPI);

/**
 *  `ConsoleBuffer` works by breaking it's input into words, counting how much
 *  space they take up and only then deciding to which line to append them
 *  (new or the next, new one).
 *
 *  It is implemented making heavier use of `string`s instead of `Text`.
 *  This is because:
 *      1. `string`s that are passed to console are broken into lines,
 *          that need to be specifically prepared anyway;
 *      2. It was coded before I the switch to mostly using `Text`,
 *          when a lot of methods were also accepting `string`s
 *          and `array<Character>` types as parameters.
 *          And i really do not want to have to reimplement it.
 */

var private int CODEPOINT_ESCAPE;
var private int CODEPOINT_NEWLINE;
var private int COLOR_SEQUENCE_LENGTH;

//  Display settings according to which to format our output
var private ConsoleAPI.ConsoleDisplaySettings displaySettings;

/**
 *  This structure is used to both share results of our work and for tracking
 *  information about the line we are currently filling.
 */
struct LineRecord
{
    //  Contents of the line, as a colored `string`.
    //  Not a `Text`, because it has to be prepared exactly how we want it.
    var string  contents;
    //      Is this a wrapped line?
    //  `true` means that this line was supposed to be part part of another,
    //  singular line of text, that had to be broken into smaller pieces.
    //      Such lines will start with "|" in front of them in Acedia's
    //  `ConsoleWriter`.
    var bool    wrappedLine;
    //  Information variables that describe how many visible and total symbols
    //  (visible + color change sequences) are stored int the `line`
    var int     visibleSymbolsStored;
    var int     totalSymbolsStored;
    //  Does `contents` contain a color change sequence?
    //  Non-empty line can have no such sequence if they consist of whitespaces.
    var private bool    colorInserted;
    //  If `colorInserted == true`, stores the last inserted color.
    var private Color   endColor;
};
//  Lines that are ready to be output to the console
var private array<LineRecord> completedLines;

//  Line we are currently building
var private LineRecord              currentLine;
//      Word we are currently building, colors of it's characters will be
//  automatically converted into `STRCOLOR_Struct`, according to the default
//  color setting at the time of their addition.
//      We are using array of `Character`s instead of `MutableText` since
//  we want to have a more directly control over how it is converted into
//  a colored string anyway and otherwise only need an ability to
//  append `Character`s to it.
var private array<Text.Character>   wordBuffer;
//  Amount of color swaps inside `wordBuffer`
var private int                     colorSwapsInWordBuffer;

/**
 *  Returns current setting used by this buffer to break up it's input into
 *  lines fit to be output in console.
 *
 *  @return Currently used `ConsoleDisplaySettings`.
 */
public final function ConsoleAPI.ConsoleDisplaySettings GetSettings()
{
    return displaySettings;
}

/**
 *  Sets new setting to be used by this buffer to break up it's input into
 *  lines fit to be output in console.
 *
 *  It is recommended (although not required) to call `Flush()` before
 *  changing settings. Not doing so would not lead to any errors or warnings,
 *  but can lead to some wonky results and is considered an undefined behavior.
 *
 *  @param  newSettings New `ConsoleDisplaySettings` to be used.
 *  @return Returns caller `ConsoleBuffer` to allow for method chaining.
 */
public final function ConsoleBuffer SetSettings(
    ConsoleAPI.ConsoleDisplaySettings newSettings)
{
    displaySettings = newSettings;
    return self;
}

/**
 *  Does caller `ConsoleBuffer` has any completed lines that can be output?
 *
 *      "Completed line" means that nothing else will be added to it.
 *      So negative (`false`) response does not mean that the buffer is empty, -
 *  it can still contain an uncompleted and non-empty line that can still be
 *  expanded with `Insert()`. If you want to completely empty the buffer -
 *  call the `Flush()` method.
 *      Also see `IsEmpty()`.
 *
 *  @return `true` if caller `ConsoleBuffer` has no completed lines and
 *      `false` otherwise.
 */
public final function bool HasCompletedLines()
{
    return (completedLines.length > 0);
}

/**
 *  Does caller `ConsoleBuffer` has any unprocessed input?
 *
 *      Note that `ConsoleBuffer` can be non-empty, but no completed line if it
 *  currently builds one.
 *      See `Flush()` and `HasCompletedLines()` methods.
 *
 *  @return `true` if `ConsoleBuffer` is completely empty
 *      (either did not receive or already returned all processed input) and
 *      `false` otherwise.
 */
public final function bool IsEmpty()
{
    if (HasCompletedLines())                return false;
    if (currentLine.totalSymbolsStored > 0) return false;
    if (wordBuffer.length > 0)              return false;
    return true;
}

/**
 *  Clears the buffer of all data, but leaving current settings intact.
 *  After this calling method `IsEmpty()` should return `true`.
 *
 *  @return Returns caller `ConsoleBuffer` to allow method chaining.
 */
public final function ConsoleBuffer Clear()
{
    local LineRecord newLineRecord;
    currentLine = newLineRecord;
    completedLines.length = 0;
    return self;
}

/**
 *  Inserts a string into the buffer. This method does not automatically break
 *  the line after the `input`, call `Flush()` or add line feed symbol "\n"
 *  at the end of the `input` if you want that.
 *
 *  @param  input       `Text` to be added to the current line in caller
 *      `ConsoleBuffer`. Does nothing if passed `none`.
 *  @param  inputType   How to treat given `string` regarding coloring.
 *  @return Returns caller `ConsoleBuffer` to allow method chaining.
 */
public final function ConsoleBuffer Insert(BaseText input)
{
    local int                   inputConsumed;
    local BaseText.Character    nextCharacter;
    if (input == none) {
        return self;
    }
    //  Regular symbols and whitespaces are treated differently when
    //  breaking input into lines, so alternate between adding them,
    //  switching the logic appropriately
    while (inputConsumed < input.GetLength())
    {
        while (inputConsumed < input.GetLength())
        {
            nextCharacter = input.GetCharacter(inputConsumed);
            if (_.text.IsWhitespace(nextCharacter)) {
                break;
            }
            InsertIntoWordBuffer(input.GetCharacter(inputConsumed));
            inputConsumed += 1;
        }
        //  If we didn't encounter any whitespace symbols - bail
        if (inputConsumed >= input.GetLength()) {
            return self;
        }
        FlushWordBuffer();
        //  Dump whitespaces into lines
        while (inputConsumed < input.GetLength())
        {
            nextCharacter = input.GetCharacter(inputConsumed);
            if (!_.text.IsWhitespace(nextCharacter)) {
                break;
            }
            AppendWhitespaceToCurrentLine(nextCharacter);
            inputConsumed += 1;
        }
    }
    return self;
}

/**
 *  Returns (and makes caller `ConsoleBuffer` forget) next completed line that
 *  can be output to console in `STRING_Colored` format.
 *
 *  If there are no completed line to return - returns an empty one.
 *
 *  @return Next completed line that can be output, in `STRING_Colored` format.
 */
public final function LineRecord PopNextLine()
{
    local LineRecord result;
    if (completedLines.length <= 0) return result;
    result = completedLines[0];
    completedLines.Remove(0, 1);
    return result;
}

/**
 *  Forces all buffered data into "completed line" array, making it retrievable
 *  by `PopNextLine()`.
 *
 *  @return Next completed line that can be output, in `STRING_Colored` format.
 */
public final function ConsoleBuffer Flush()
{
    FlushWordBuffer();
    BreakLine(false);
    return self;
}

//      It is assumed that passed characters are not whitespace, -
//  responsibility to check is on the one calling this method.
private final function InsertIntoWordBuffer(BaseText.Character newCharacter)
{
    local int                   newCharacterIndex;
    local BaseText.Formatting   newFormatting;
    local Color                 oldColor, newColor;
    //  Fix text color in the buffer to remember default color, if we use it.
    newFormatting = _.text.GetCharacterFormatting(newCharacter);
    newFormatting.color =
        _.text.GetCharacterColor(newCharacter, displaySettings.defaultColor);
    newFormatting.isColored = true;
    newCharacter = _.text.SetFormatting(newCharacter, newFormatting);

    //  Add new character and check if color swapped
    newCharacterIndex = wordBuffer.length;
    wordBuffer[newCharacterIndex] = newCharacter;
    if (newCharacterIndex <= 0) {
        return;
    }
    newColor = newFormatting.color;
    oldColor = _.text.GetCharacterColor(wordBuffer[newCharacterIndex - 1]);
    if (!_.color.AreEqual(oldColor, newColor, true)) {
        colorSwapsInWordBuffer += 1;
    }
}

//  Pushes whole `wordBuffer` into lines
private final function FlushWordBuffer()
{
    local int   i;
    local Color newColor;
    if (!WordCanFitInCurrentLine() && WordCanFitInNewLine()) {
        BreakLine(true);
    }
    for (i = 0; i < wordBuffer.length; i += 1)
    {
        if (!CanAppendNonWhitespaceIntoLine(wordBuffer[i])) {
            BreakLine(true);
        }
        newColor = _.text.GetCharacterColor(wordBuffer[i]);
        if (MustSwapColorsFor(newColor))
        {
            currentLine.contents $= _.color.GetColorTag(newColor);
            currentLine.totalSymbolsStored += COLOR_SEQUENCE_LENGTH;
            currentLine.colorInserted   = true;
            currentLine.endColor        = newColor;
        }
        currentLine.contents $= Chr(wordBuffer[i].codePoint);
        currentLine.totalSymbolsStored      += 1;
        currentLine.visibleSymbolsStored    += 1;
    }
    wordBuffer.length       = 0;
    colorSwapsInWordBuffer  = 0;
}

private final function BreakLine(bool makeWrapped)
{
    local LineRecord newLineRecord;
    if (currentLine.visibleSymbolsStored > 0) {
        completedLines[completedLines.length] = currentLine;
    }
    currentLine = newLineRecord;
    currentLine.wrappedLine = makeWrapped;
}

private final function bool MustSwapColorsFor(Color newColor)
{
    if (!currentLine.colorInserted) return true;
    return !_.color.AreEqual(currentLine.endColor, newColor, true);
}

private final function bool CanAppendWhitespaceIntoLine()
{
    //  We always allow to append at least something into empty line,
    //  otherwise we can never insert it anywhere
    if (currentLine.totalSymbolsStored <= 0) return true;
    if (currentLine.totalSymbolsStored >= displaySettings.maxTotalLineWidth)
    {
        return false;
    }
    if (currentLine.visibleSymbolsStored >= displaySettings.maxVisibleLineWidth)
    {
        return false;
    }
    return true;
}

private final function bool CanAppendNonWhitespaceIntoLine(
    BaseText.Character nextCharacter)
{
    //  We always allow to insert at least something into empty line,
    //  otherwise we can never insert it anywhere
    if (currentLine.totalSymbolsStored <= 0) {
        return true;
    }
    //  Check if we can fit a single character by fitting a whitespace symbol.
    if (!CanAppendWhitespaceIntoLine()) {
        return false;
    }
    if (!MustSwapColorsFor(_.text.GetCharacterColor(nextCharacter))) {
        return true;
    }
    //  Can we fit character + color swap sequence?
    return  (   currentLine.totalSymbolsStored + COLOR_SEQUENCE_LENGTH + 1
            <=  displaySettings.maxTotalLineWidth);
}

//  For performance reasons assumes that passed character is a whitespace,
//  the burden of checking is on the caller.
private final function AppendWhitespaceToCurrentLine(
    BaseText.Character whitespace)
{
    if (_.text.IsCodePoint(whitespace, CODEPOINT_NEWLINE)) {
        BreakLine(false);
        return;
    }
    if (!CanAppendWhitespaceIntoLine()) {
        BreakLine(true);
    }
    currentLine.contents $= Chr(whitespace.codePoint);
    currentLine.totalSymbolsStored      += 1;
    currentLine.visibleSymbolsStored    += 1;
}

private final function bool WordCanFitInNewLine()
{
    local int totalCharactersInWord;
    if (wordBuffer.length <= 0) return true;
    if (wordBuffer.length > displaySettings.maxVisibleLineWidth) {
        return false;
    }
    //  `(colorSwapsInWordBuffer + 1)` counts how many times we must
    //  switch color inside a word + 1 for setting initial color
    totalCharactersInWord = wordBuffer.length
        + (colorSwapsInWordBuffer + 1) * COLOR_SEQUENCE_LENGTH;
    return (totalCharactersInWord <= displaySettings.maxTotalLineWidth);
}

private final function bool WordCanFitInCurrentLine()
{
    local int totalLimit, visibleLimit;
    local int totalCharactersInWord;
    if (wordBuffer.length <= 0) return true;
    totalLimit =
        displaySettings.maxTotalLineWidth - currentLine.totalSymbolsStored;
    visibleLimit =
        displaySettings.maxVisibleLineWidth - currentLine.visibleSymbolsStored;
    //  Visible symbols check
    if (wordBuffer.length > visibleLimit) {
        return false;
    }
    //  Total symbols check
    totalCharactersInWord = wordBuffer.length
        + colorSwapsInWordBuffer * COLOR_SEQUENCE_LENGTH;
    if (MustSwapColorsFor(_.text.GetCharacterColor(wordBuffer[0]))) {
        totalCharactersInWord += COLOR_SEQUENCE_LENGTH;
    }
    return (totalCharactersInWord <= totalLimit);
}

defaultproperties
{
    CODEPOINT_ESCAPE        = 27
    CODEPOINT_NEWLINE       = 10
    //  CODEPOINT_ESCAPE + <redByte> + <greenByte> + <blueByte>
    COLOR_SEQUENCE_LENGTH   = 4
}