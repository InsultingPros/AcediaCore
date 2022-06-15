/**
 *  Object that is created from *formatted string* (or `Text`) and stores
 *  information about formatting used in said string. Was introduced instead of
 *  a simple method in `MutableText` to:
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
class FormattedStringData extends AcediaObject
    dependson(Text)
    dependson(FormattingErrors)
    dependson(FormattingCommandList);

struct FormattingInfo
{
    var bool            colored;
    var Color           plainColor;
    var bool            gradient;
    var array<Color>    gradientColors;
    var array<float>    gradientPoints;
    var int             gradientStart;
    var float           gradientLength;
};
//  Formatted `string` can have an arbitrary level of folded format definitions,
//  this array is used as a stack to keep track of opened formatting blocks
//  when appending formatted `string`.
var array<FormattingInfo>   formattingStack;
//      Keep top element copied into a separate variable for quicker access.
//      Must maintain invariant: if `formattingStack.length > 0`
//  then `formattingStack[formattingStack.length - 1] == formattingStackHead`.
var FormattingInfo          formattingStackHead;

var private FormattingCommandList   commands;
var private MutableText             result;
var private FormattingErrors        errors;

protected function Finalizer()
{
    formattingStack.length = 0;
    _.memory.Free(commands);
    _.memory.Free(errors);
    _.memory.Free(result);
    commands    = none;
    errors      = none;
    result      = none;
}

public static final function FormattedStringData FromText(
    Text            source,
    optional bool   doReportErrors)
{
    local FormattedStringData newData;
    if (source == none) {
        return none;
    }
    newData =
        FormattedStringData(__().memory.Allocate(class'FormattedStringData'));
    if (doReportErrors)
    {
        newData.errors =
            FormattingErrors(__().memory.Allocate(class'FormattingErrors'));
    }
    newData.commands = class'FormattingCommandList'.static
        .FromText(source, newData.errors);
    newData.result = __().text.Empty();
    newData.BuildSelf();
    __().memory.Free(newData.commands);
    newData.commands = none;
    return newData;
}

public final function Text GetResult()
{
    return result.Copy();
}

public final function MutableText GetResultM()
{
    return result.MutableCopy();
}

public final function FormattingErrors BorrowErrors()
{
    return errors;
}

private final function BuildSelf()
{
    local int                                       i, j, nextCharacterIndex;
    local Text.Formatting                           defaultFormatting;
    local array<Text.Character>                     nextContents;
    local FormattingCommandList.FormattingCommand   nextCommand;
    SetupFormattingStack(defaultFormatting);
    //  First element of color stack is special and has no color information;
    //  see `BuildFormattingStackCommands()` for details.
    nextCommand = commands.GetCommand(0);
    nextContents = nextCommand.contents;
    result.AppendManyRawCharacters(nextContents);
    nextCharacterIndex = nextContents.length;
    _.memory.Free(nextCommand.tag);
    for (i = 1; i < commands.GetAmount(); i += 1)
    {
        nextCommand = commands.GetCommand(i);
        if (nextCommand.type == FST_StackPush) {
            PushIntoFormattingStack(nextCommand);
        }
        else if (nextCommand.type == FST_StackPop) {
            PopFormattingStack();
        }
        else if (nextCommand.type == FST_StackSwap) {
            SwapFormattingStack(nextCommand.charTag);
        }
        nextContents = nextCommand.contents;
        if (IsCurrentFormattingGradient())
        {
            for (j = 0; j < nextContents.length; j += 1)
            {
                result.AppendRawCharacter(nextContents[j], GetFormattingFor(nextCharacterIndex));
                nextCharacterIndex += 1;
            }
        }
        else
        {
            result.AppendManyRawCharacters(nextContents, GetFormattingFor(nextCharacterIndex));
            nextCharacterIndex += nextContents.length;
        }
        _.memory.Free(nextCommand.tag);
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
    local FormattingInfo defaultFormattingInfo;
    defaultFormattingInfo.colored       = defaultFormatting.isColored;
    defaultFormattingInfo.plainColor    = defaultFormatting.color;
    if (formattingStack.length > 0) {
        formattingStack.length = 0;
    }
    formattingStack[0]  = defaultFormattingInfo;
    formattingStackHead = defaultFormattingInfo;
}

private final function bool IsCurrentFormattingGradient()
{
    if (formattingStack.length <= 0) {
        return false;
    }
    return formattingStackHead.gradient;
}

private final function Text.Formatting GetFormattingFor(int index)
{
    local Text.Formatting emptyFormatting;
    if (formattingStack.length <= 0)    return emptyFormatting;
    if (!formattingStackHead.colored)   return emptyFormatting;

    return _.text.FormattingFromColor(GetColorFor(index));
}
//FormattedStringData Package.FormattedStringData (Function AcediaCore.FormattedStringData.GetColorFor:00FC) Accessed array 'gradientColors' out of bounds (2/2)
private final function Color GetColorFor(int index)
{
    local int           i;
    local float         indexPosition, leftPosition, rightPosition;
    local array<float>  points;
    local Color         leftColor, rightColor, resultColor;
    if (formattingStack.length <= 0) {
        return resultColor;
    }
    if (!formattingStackHead.gradient) {
        return formattingStackHead.plainColor;
    }
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
    resultColor.R = Lerp(indexPosition, leftColor.R, rightColor.R);
    resultColor.G = Lerp(indexPosition, leftColor.G, rightColor.G);
    resultColor.B = Lerp(indexPosition, leftColor.B, rightColor.B);
    resultColor.A = Lerp(indexPosition, leftColor.A, rightColor.A);
    return resultColor;
}

private final function PushIntoFormattingStack(
    FormattingCommandList.FormattingCommand formattingCommand)
{
    formattingStackHead = ParseFormattingInfo(formattingCommand.tag);
    formattingStackHead.gradientStart   = formattingCommand.openIndex;
    formattingStackHead.gradientLength  =
        float(formattingCommand.closeIndex - formattingCommand.openIndex);
    formattingStack[formattingStack.length] = formattingStackHead;
}

private final function SwapFormattingStack(Text.Character tagCharacter)
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
    else {
        Report(FSE_BadShortColorTag, _.text.FromString("^" $ Chr(tagCharacter.codePoint)));
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

private final function FormattingInfo ParseFormattingInfo(Text colorTag)
{
    local int                   i;
    local Parser                colorParser;
    local Color                 nextColor;
    local array<MutableText>    specifiedColors;
    local Text.Character        tildeCharacter;
    local array<Color>          gradientColors;
    local array<float>          gradientPoints;
    local FormattingInfo        resultInfo;
    if (colorTag.IsEmpty())
    {
        Report(FSE_EmptyColorTag);
        return resultInfo;  // not colored
    }
    tildeCharacter  = _.text.GetCharacter("~");
    specifiedColors = colorTag.SplitByCharacter(tildeCharacter, true);
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
    resultInfo.colored          = (gradientColors.length > 0);
    resultInfo.gradient         = (gradientColors.length > 1);
    resultInfo.gradientColors   = gradientColors;
    resultInfo.gradientPoints   = gradientPoints;
    if (gradientColors.length > 0) {
        resultInfo.plainColor = gradientColors[0];
    }
    return resultInfo;
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
    if (!parser.Match(P("[")).Ok())
    {
        Report(FSE_BadGradientPoint, parser.RestoreState(initialState).GetRemainder());
        return -1;
    }
    //  [Necessary part] Try parsing number
    parser.MNumber(point).Confirm();
    if (!parser.Ok())
    {
        Report(FSE_BadGradientPoint, parser.RestoreState(initialState).GetRemainder());
        return -1;
    }
    //  [Optional part] Check if number is a percentage
    if (parser.Match(P("%")).Ok()) {
        point *= 0.01;
    }
    //  This either confirms state of parsing "%" (on success)
    //  or reverts to the previous state, just after parsing the number
    //  (on failure)
    parser.Confirm();
    parser.R();
    //  [Necessary part] Have to have closing parenthesis
    if (!parser.HasFinished()) {
        parser.Match(P("]")).Confirm();
    }
    //  Still return `point`, even if there was no closing parenthesis,
    //  since that is likely what user wants
    if (!parser.Ok()) {
        Report(FSE_BadGradientPoint, parser.RestoreState(initialState).GetRemainder());
    }
    return point;
}
/*FIRST-POPOPOINTS 0.00 -1.00 -1.00 -1.00 1.00 5
PRE-POPOPOINTS 0.00 -1.00 0.00 -1.00 1.00 5 */
private final function array<float> NormalizePoints(array<float> points)
{
    local int i, j;
    local int negativeSegmentStart, negativeSegmentLength;
    local float lowerBound, upperBound;
    local bool foundNegative;
    if (points.length > 1)
    {
        points[0] = 0.0;
        points[points.length - 1] = 1.0;
    }
    for (i = 1; i < points.length - 1; i += 1)
    {
        if (points[i] <= 0 || points[i] > 1 || points[i] <= points[i - 1]) {
            points[i] = -1;
        }
    }
    for (i = 1; i < points.length; i += 1)
    {
        if (foundNegative && points[i] > 0)
        {
            upperBound = points[i];
            for (j = negativeSegmentStart; j < i; j += 1)
            {
                points[j] = Lerp(   float(j - negativeSegmentStart + 1) / float(negativeSegmentLength + 1),
                                    lowerBound, upperBound);
            }
            negativeSegmentLength = 0;
        }
        if (!foundNegative && points[i] < 0)
        {
            lowerBound = points[i - 1];
            negativeSegmentStart = i;
        }
        foundNegative = (points[i] < 0);
        if (foundNegative) {
            negativeSegmentLength += 1;
        }
    }
    return points;
}

public final function Report(
    FormattingErrors.FormattedDataErrorType type,
    optional Text                           cause)
{
    if (errors == none) {
        return;
    }
    errors.Report(type, cause);
}

defaultproperties
{
}