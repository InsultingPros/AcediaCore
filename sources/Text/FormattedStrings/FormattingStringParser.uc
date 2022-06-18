/**
 *  A simple parser with a single public method for parsing formatted strings.
 *  Was introduced instead of a simple method in `MutableText` to:
 *      1. Allow for reporting errors caused by badly specified colors;
 *      2. Allow for a more complicated case of specifying a color gradient
 *          range.
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
class FormattingStringParser extends AcediaObject
    dependson(BaseText)
    dependson(FormattingErrorsReport)
    dependson(FormattingCommandsSequence);

/**
 *  # Usage
 *
 *      Public interface of this parser consists of a single static method
 *  `ParseFormatted()` that temporarily creates (and auto deallocates before
 *  method has returned) instance of its own class to store the state necessary
 *  during parsing.
 *
 *  # Implementation
 *
 *  ## Formatting commands
 *
 *      The algorithm looks at formatting block "{<color_tag> ...}" as a set
 *  of two operations: turn on a certain formatting ("{<color_tag>") and
 *  turn it off ("}"). Since blocks can be folded into each other, as we parse
 *  the string we put opened ones onto the stack, closing them upon
 *  encountering "}". Short color tags "^<color_character>" are handled by
 *  switching formatting within the current block.
 *      Overall this leads us to transforming markdown of formatted string into
 *  sequence of three operations:
 *      1. Put formatting onto the formatting stack (and add following
 *          contents);
 *      2. Pop formatting off the formatting stack (and add following contents);
 *      3. Swap formatting on top of the formatting stack (and add following
 *          contents).
 *      Transforming formatted string in such a sequence is moved out from this
 *  class into auxiliary `FormattingCommandsSequence`, since it task is
 *  logically separated from the one that comes next...
 *
 *  ## Building `MutableText`
 *
 *      Once we have broken formatted string down into sequence of formatted
 *  commands, we only need to go through them, command-by-command, appending
 *  their contents to the resulting `MutableText` with formatting, specified by
 *  the command.
 *      The only somewhat complicated part here are formatted blocks with
 *  specified gradient coloring
 *  ("<color_1>:<color_2>:<color_3>[<point>]:<color_4>"). For that we make use
 *  of the information about starting and ending indices of gradient formatted
 *  block, given by `FormattingCommandsSequence`:
 *      * We correct/uniformly place missing points where each intermediate
 *          color must be at 100% on the segment [0; 1], where 0 represents
 *          start of the formatting block and 1 its end;
 *      * Then for each character we determine between which color it lies and
 *          how far from each of them (again on the scale from 0 to 1,
 *          where `0` is left color and `1` is right color);
 *      * Finally we use linear interpolation between selected pair of colors to
 *          determine appropriate formatting.
 */

/**
 *  Element of the formatting stack, that completely defines formatting block.
 */
struct FormattingInfo
{
    //  Is segment even colored?
    var bool            colored;
    //  Does it use color gradient?
    var bool            gradient;
    //  Color of the segment, only used when `gradient` equals `true`
    var Color           plainColor;
    //  All the colors for gradient inside the segment, only used when
    //  `gradient` equals `false`
    var array<Color>    gradientColors;
    //  Points (from 0 to 1) at which each `gradientColors` with the same index
    //  should be at its 100%
    var array<float>    gradientPoints;
    //      To decide how to color each character we need to know position of
    //  the segment, it is convenient for us to store it as a starting point
    //  and length.
    //      Length is stored as `float` because it will mostly be used as
    //  a divisor of some values and we need a `float` result.
    var int             gradientStart;
    var float           gradientLength;
};
//  Formatted `string` can have an arbitrary level of folded format definitions,
//  this array is used as a stack to keep track of opened formatting blocks
//  when appending formatted `string`.
var private array<FormattingInfo>       formattingStack;
//      Keep top element copied into a separate variable for quicker access.
//      Must maintain invariant: if `formattingStack.length > 0`
//  then `formattingStack[formattingStack.length - 1] == formattingStackHead`.
var private FormattingInfo              formattingStackHead;
//  For calculating gradient we need to know what character we are
//  currently adding.
var private int                         nextCharacterIndex;
//  `FormattingStringParser` itself only performs "stage 2" of the algorithm,
//  while "stage 1" (converting formatted string into a sequence of commands is
//  done by this object).
var private FormattingCommandsSequence  commandSequence;
//  Text we are appending formatted string to
var private MutableText                 borrowedTarget;
var private FormattingErrorsReport      borrowedErrors;

//  Keep this as an easy access to separator of gradient colors ':'
var private BaseText.Character separatorCharacter;

var private const int TOPENING_BRACKET, TCLOSING_BRACKET, TPERCENT;

protected function Constructor()
{
    separatorCharacter = _.text.GetCharacter(":");
}

protected function Finalizer()
{
    formattingStack.length = 0;
    _.memory.Free(commandSequence); //  the only object we have owned
    commandSequence = none;
    borrowedTarget  = none;
    borrowedErrors  = none;
}

/**
 *  Parses formatted string given by the `source`.
 *
 *  As a result of parsing can either append it to given `MutableText` or
 *  report any errors in its formatting.
 *
 *  @param  source          `Text` to parse as a formatted string.
 *  @param  target          Method will append result of parsing `source` into
 *      this parameter. Does nothing if it is equal to `none`.
 *  @param  doReportErrors  Set this to `true` if you want parsing errors to be
 *      reported in the return value and `false` otherwise.
 *  @return Array of formatting errors in the given `source` formatted string,
 *      each represented by `FormattedStringError` struct.
 *      Errors are only generated if `doReportErrors` is equals to `true`.
 *      If `doReportErrors` is `false`, then returned value is guaranteed to be
 *      an empty array.
 *      Each `FormattedStringError` item in array has either:
 *          * non-`none` `cause` field or;
 *          * strictly positive `count > 0` field.
 *      But never both.
 *      `count` field is always guaranteed to be non-negative.
 *      WARNING: `FormattedStringError` struct may contain `Text` objects that
 *      should be deallocated, as per usual rules.
 */
public static final function array<FormattingErrorsReport.FormattedStringError>
    ParseFormatted(
    BaseText                source,
    optional MutableText    target,
    optional bool           doReportErrors)
{
    local FormattingErrorsReport newErrorsReport;
    local FormattingStringParser newFormattingParser;
    local array<FormattingErrorsReport.FormattedStringError> resultErrors;
    if (source == none)                     return resultErrors;
    if (target == none && !doReportErrors)  return resultErrors;

    //  Setup formatting parser
    newFormattingParser = FormattingStringParser(__().memory
        .Allocate(class'FormattingStringParser'));
    if (doReportErrors)
    {
        newErrorsReport = FormattingErrorsReport(__().memory
            .Allocate(class'FormattingErrorsReport'));
        newFormattingParser.borrowedErrors = newErrorsReport;
    }
    newFormattingParser.commandSequence =
        class'FormattingCommandsSequence'.static
            .FromText(source, newErrorsReport);
    newFormattingParser.borrowedTarget = target;
    //  Do it and release resources
    newFormattingParser.DoAppend();
    //  We have only set these fields for access convenience and we
    //  neither own `target` that will contain appended formatted string,
    //  nor errors report that user requires, so release them right after use
    newFormattingParser.borrowedTarget  = none;
    newFormattingParser.borrowedErrors  = none;
    __().memory.Free(newFormattingParser);
    if (newErrorsReport != none)
    {
        resultErrors = newErrorsReport.GetErrors();
        __().memory.Free(newErrorsReport);
    }
    return resultErrors;
}

private final function DoAppend()
{
    local int                                           i;
    local BaseText.Formatting                           emptyFormatting;
    local FormattingCommandsSequence.FormattingCommand  nextCommand;
    SetupFormattingStack(emptyFormatting);
    //  First element of color stack is special and has no color information;
    //  see `BuildFormattingStackCommands()` for details.
    nextCommand = commandSequence.GetCommand(0);
    //  First block is always not formatted
    if (borrowedTarget != none) {
        borrowedTarget.AppendManyRawCharacters(nextCommand.contents);
    }
    nextCharacterIndex = nextCommand.contents.length;
    _.memory.Free(nextCommand.tag);
    for (i = 1; i < commandSequence.GetAmount(); i += 1)
    {
        nextCommand = commandSequence.GetCommand(i);
        if (nextCommand.type == FST_StackPush) {
            PushIntoFormattingStack(nextCommand);
        }
        else if (nextCommand.type == FST_StackPop) {
            PopFormattingStack();
        }
        else if (nextCommand.type == FST_StackSwap) {
            SwapFormattingStack(nextCommand.charTag);
        }
        _.memory.Free(nextCommand.tag);
        if (borrowedTarget != none) {
            AppendToTarget(nextCommand.contents);
        }
    }
}

//      Auxiliary method for appending `contents` character with an appropriate
//  formatting and parser's state modification.
private final function AppendToTarget(array<Text.Character> contents)
{
    local int i;
    if (!IsCurrentFormattingGradient())
    {
        borrowedTarget.AppendManyRawCharacters(
            contents,
            GetFormattingFor(nextCharacterIndex));
        nextCharacterIndex += contents.length;
        return;
    }
    for (i = 0; i < contents.length; i += 1)
    {
        borrowedTarget.AppendRawCharacter(
            contents[i],
            GetFormattingFor(nextCharacterIndex));
        nextCharacterIndex += 1;
    }
}

private final function Report(
    FormattingErrorsReport.FormattedStringErrorType type,
    optional BaseText                               cause)
{
    if (borrowedErrors == none) {
        return;
    }
    borrowedErrors.Report(type, cause);
}

private final function bool IsCurrentFormattingGradient()
{
    if (formattingStack.length <= 0) {
        return false;
    }
    return formattingStackHead.gradient;
}

private final function BaseText.Formatting GetFormattingFor(int index)
{
    local BaseText.Formatting emptyFormatting;
    if (formattingStack.length <= 0)    return emptyFormatting;
    if (!formattingStackHead.colored)   return emptyFormatting;

    return _.text.FormattingFromColor(GetColorFor(index));
}

private final function Color GetColorFor(int index)
{
    local int           i;
    local float         indexPosition, leftPosition, rightPosition;
    local array<float>  points;
    local Color         leftColor, rightColor, targetColor;
    if (formattingStack.length <= 0)    return targetColor;
    if (!formattingStackHead.gradient)  return formattingStackHead.plainColor;

    indexPosition = float(index - formattingStackHead.gradientStart) /
                    formattingStackHead.gradientLength;
    points = formattingStackHead.gradientPoints;
    for (i = 1; i < points.length; i += 1)
    {
        if (points[i - 1] <= indexPosition && indexPosition <= points[i])
        {
            leftPosition    = points[i - 1];
            rightPosition   = points[i];
            leftColor       = formattingStackHead.gradientColors[i - 1];
            rightColor      = formattingStackHead.gradientColors[i];
            break;
        }
    }
    indexPosition =
        (indexPosition - leftPosition) / (rightPosition - leftPosition);
    targetColor.R = Lerp(indexPosition, leftColor.R, rightColor.R);
    targetColor.G = Lerp(indexPosition, leftColor.G, rightColor.G);
    targetColor.B = Lerp(indexPosition, leftColor.B, rightColor.B);
    targetColor.A = Lerp(indexPosition, leftColor.A, rightColor.A);
    return targetColor;
}

private final function FormattingInfo ParseFormattingInfo(BaseText colorTag)
{
    local int               i;
    local Parser            colorParser;
    local Color             nextColor;
    local array<BaseText>   specifiedColors;
    local array<Color>      gradientColors;
    local array<float>      gradientPoints;
    local FormattingInfo    targetInfo;
    if (colorTag.IsEmpty())
    {
        Report(FSE_EmptyColorTag);
        return targetInfo;  // not colored
    }
    specifiedColors = colorTag.SplitByCharacter(separatorCharacter, true, true);
    for (i = 0; i < specifiedColors.length; i += 1)
    {
        colorParser = _.text.Parse(specifiedColors[i]);
        if (_.color.ParseWith(colorParser, nextColor))
        {
            colorParser.Confirm();
            gradientColors[gradientColors.length] = nextColor;
            gradientPoints[gradientPoints.length] = ParsePoint(colorParser);
        }
        else {
            Report(FSE_BadColor, specifiedColors[i]);
        }
        _.memory.Free(colorParser);
    }
    _.memory.FreeMany(specifiedColors);
    gradientPoints              = NormalizePoints(gradientPoints);
    targetInfo.colored          = (gradientColors.length > 0);
    targetInfo.gradient         = (gradientColors.length > 1);
    targetInfo.gradientColors   = gradientColors;
    targetInfo.gradientPoints   = gradientPoints;
    if (gradientColors.length > 0) {
        targetInfo.plainColor = gradientColors[0];
    }
    return targetInfo;
}

private final function float ParsePoint(Parser parser)
{
    local float                 point;
    local Parser.ParserState    initialState;
    if (!parser.Ok() || parser.HasFinished()) {
        return -1;
    }
    initialState = parser.GetCurrentState();
    //  [Necessary part] Should starts with "["
    if (!parser.Match(T(TOPENING_BRACKET)).Ok())
    {
        Report(
            FSE_BadGradientPoint,
            parser.RestoreState(initialState).GetRemainder());
        return -1;
    }
    //  [Necessary part] Try parsing number
    parser.MNumber(point).Confirm();
    if (!parser.Ok())
    {
        Report(
            FSE_BadGradientPoint,
            parser.RestoreState(initialState).GetRemainder());
        return -1;
    }
    //  [Optional part] Check if number is a percentage
    if (parser.Match(T(TPERCENT)).Ok()) {
        point *= 0.01;
    }
    //  This either confirms state of parsing "%" (on success)
    //  or reverts to the previous state, just after parsing the number
    //  (on failure)
    parser.Confirm();
    parser.R();
    //  [Necessary part] Have to have closing parenthesis
    if (!parser.HasFinished()) {
        parser.Match(T(TCLOSING_BRACKET)).Confirm();
    }
    //  Still return `point`, even if there was no closing parenthesis,
    //  since that is likely what user wants
    if (!parser.Ok())
    {
        Report(
            FSE_BadGradientPoint,
            parser.RestoreState(initialState).GetRemainder());
    }
    return point;
}

private final function array<float> NormalizePoints(array<float> points)
{
    local int   i, j;
    local int   negativeSegmentStart, negativeSegmentLength;
    local float leftPositiveBound, rightPositiveBound;
    local bool  foundNegative;
    //  Leftmost and rightmost points are always fixed
    if (points.length > 1)
    {
        points[0]                   = 0.0;
        points[points.length - 1]   = 1.0;
    }
    for (i = 1; i < points.length - 1; i += 1)
    {
        //      Each point must be in bounds (between `0` and `1`) and points
        //  must be specified in an increasing order.
        //      If either does not hold - simply mark point as unspecified and
        //  let let it be regenerated naturally.
        if (points[i] <= 0 || points[i] > 1 || points[i] <= points[i - 1]) {
            points[i] = -1;
        }
    }
    //      Check all points - if a sequence of them are undefined, then place
    //  them uniformly between bounding non-negative points.
    //      For example [0.5, -1, -1, -1, -1, 1] should turn into
    //  [0.5, 0.6, 0.7, 0.8, 0.9, 1.0].
    //      NOTE: at the beginning of this method we have forced `points[0]`
    //  to be `0.0` and `points[points.length - 1]` to be `1.0`. Thanks to that
    //  there always exists left and right non-negative bounding points.
    for (i = 1; i < points.length; i += 1)
    {
        //  Found first element of negative sequence
        if (!foundNegative && points[i] < 0)
        {
            leftPositiveBound = points[i - 1];
            negativeSegmentStart = i;
        }
        //  Found where negative sequence ends
        if (foundNegative && points[i] > 0)
        {
            rightPositiveBound = points[i];
            for (j = negativeSegmentStart; j < i; j += 1)
            {
                points[j] = Lerp(
                    float(j - negativeSegmentStart + 1) /
                        float(negativeSegmentLength + 1),
                    leftPositiveBound,
                    rightPositiveBound);
            }
            negativeSegmentLength = 0;
        }
        foundNegative = (points[i] < 0);
        //  Still continuing with negative segment
        if (foundNegative) {
            negativeSegmentLength += 1;
        }
    }
    return points;
}

//      Following four functions are to maintain a "color stack" that will
//  remember unclosed colors (new colors are obtained from formatting commands
//  sequence) defined in formatted string, in order.
//      Stack array always contains one element, defined by
//  the `SetupFormattingStack()` call. It corresponds to the default formatting
//  that will be used when we pop all the other elements.
//      It is necessary to deal with possible folded formatting definitions in
//  formatted strings.
private final function SetupFormattingStack(
    BaseText.Formatting defaultFormatting)
{
    local FormattingInfo defaultFormattingInfo;
    defaultFormattingInfo.colored       = defaultFormatting.isColored;
    defaultFormattingInfo.plainColor    = defaultFormatting.color;
    if (formattingStack.length > 0) {
        formattingStack.length = 0;
    }
    formattingStack[0]  = defaultFormattingInfo;
    formattingStackHead = defaultFormattingInfo;
}

private final function PushIntoFormattingStack(
    FormattingCommandsSequence.FormattingCommand formattingCommand)
{
    formattingStackHead = ParseFormattingInfo(formattingCommand.tag);
    formattingStackHead.gradientStart   = formattingCommand.openIndex;
    formattingStackHead.gradientLength  =
        float(formattingCommand.closeIndex - formattingCommand.openIndex);
    formattingStack[formattingStack.length] = formattingStackHead;
}

private final function SwapFormattingStack(BaseText.Character tagCharacter)
{
    local FormattingInfo updatedFormatting;
    if (formattingStack.length > 0) {
        updatedFormatting = formattingStackHead;
    }
    if (_.color.ResolveShortTagColor(tagCharacter, updatedFormatting.plainColor))
    {
        updatedFormatting.colored   = true;
        updatedFormatting.gradient  = false;
    }
    else
    {
        Report(
            FSE_BadShortColorTag,
            _.text.FromString("^" $ Chr(tagCharacter.codePoint)));
    }
    formattingStackHead = updatedFormatting;
    if (formattingStack.length > 0) {
        formattingStack[formattingStack.length - 1] = updatedFormatting;
    }
    else {
        formattingStack[0] = updatedFormatting;
    }
}

private final function PopFormattingStack()
{
    //  Remove the top of the stack
    if (formattingStack.length > 0) {
        formattingStack.length = formattingStack.length - 1;
    }
    //  Update the stack head copy
    if (formattingStack.length > 0) {
        formattingStackHead = formattingStack[formattingStack.length - 1];
    }
}

defaultproperties
{
    TOPENING_BRACKET    = 0
    stringConstants(0)  = "["
    TCLOSING_BRACKET    = 1
    stringConstants(1)  = "]"
    TPERCENT            = 2
    stringConstants(2)  = "%"
}