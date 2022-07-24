/**
 *      Class that allows to work with simple text templates in the form of
 *  "Template example, following can be replaced: %1, %2, %3 or %4" or
 *  "%%instigator%% {%%rage_color%% raged} %%target_zed%%!".
 *  Part noted by '%' characters can be replaced with arbitrary values.
 *  It should be more efficient that simply repeatedly calling
 *  `MutableText.Replace()` method.
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
class TextTemplate extends AcediaObject;

/**
 *  # `TextTemplate`
 *
 *      This class allows to do more efficient replacements in the templates of
 *  form "Template example, following can be replaced: %1, %2, %3 or %4" or
 *  "%%instigator%% {%%rage_color%% raged} %%target_zed%%!" that simple
 *  repeating of `MutableText.Replace()` method would allow.
 *
 *  ## Usage
 *
 *      All `TextTemplate`s must be initialized before they can be used.
 *  `_.text.MakeTemplate()` method is considered a recommended way to create
 *  a new `TextTemplate` and will initialize it for you. In case you have
 *  manually allocated `TextTemplate` you need to simply call
 *  `TextTemplate.Initialize()` method and provide is with a template source
 *  with designated replaceable part (called *labels*). Any label is designated
 *  by either:
 *
 *      * Specifying a number after a single '%' character (numeric labels);
 *      * Or specifying a textual value in between double percent sequence "%%".
 *
 *      Numeric labels can then be replaced with user values by various provided
 *  `Arg...()` methods and text labels by `TextArg...()` methods. To reuse
 *  template with another values replacing specified labels, simply call
 *  `TextTemplate.Reset()` method and fill labels anew.
 *
 *  ### Escaped sequences
 *
 *      `TextTemplate` allows for the escaped sequences in the style of
 *  formatted strings: the ones based on the '&' character. More precisely, if
 *  you wish to enter actual '%' character in the template, you can escape it
 *  with "&%" and it will be treaded as simply '%' character and not a part of
 *  label definition.
 *      NOTE: any other escaped sequences will be ignored and translated
 *  one-to-one. For example, "{%%color%% &{...&}&%!}", if specified that
 *  "color" -> "$red", will be translated into "{$red &{...&}%!}". This allows
 *  to use `TextTemplate`s to prepare formatted strings in a more convenient
 *  fashion.
 *
 *  ### Error handling
 *
 *  `TextTemplate` lack any means of reporting errors in template's formatting
 *  and tries to correct as many errors as possible.
 *  
 *      1. If after the single '%' character follows not a number, but another
 *          character - that '%' will be ignored and thrown away;
 *      2. After opening text label with double percent "%%" to stop specifying
 *          the text label it is sufficient to type a single '%' character.
 *
 *  ### Numeric labels values
 *
 *  You can specify any values for numeric labels and they will be filled in
 *  order. However the proper notation is to start with `1` and then use
 *  following natural numbers in order (e.g. "%1", "%2", "%3", etc.).
 *
 *  ### Text labels duplicates
 *
 *  It is allowed for the same text label to appear several times in a template
 *  and each entry will be replaced with a specified user value.
 *
 *  ### Unspecified arguments
 *
 *  If no argument was given for some label - it will simply be replaced with
 *  empty text.
 */

//  *Labels* will be an internal name for the parts of the template that is
//  supposed to be replaced. This struct describes one such part.
struct Label
{
    //      If Label starts with two percent characters ("%%"), then it is
    //  a text Label and we will remember contents within "%%...%%" in this
    //  field (`textLabel != none`).
    //      Otherwise it is a numeric Label and `textLabel` will be set
    //  to `none`.
    var MutableText textLabel;
    //  For numeric labels - number after that percent character '%'.
    //  In case numeric labels were specified incorrectly, these values will
    //  be normalized to start from `1` and increase by +1, while preserving
    //  their order.
    var int         numberLabel;
    //  Before which part (from `parts`) to insert this Label?
    var int         insertionIndex;
};

var private bool                initialized;
//  Remembers amount of numeric labels in the template
var private int                 numericLabelsAmount;
//  Arrays of labels and parts in between that template got broken into
//  during initialization
var private array<Label>        labels;
var private array<MutableText>  parts;

//  Values user specified as replacements to the labels
var private array<Text>         numericArguments;
//  Fort text arguments we keep two arrays of equal size: `textLabels` records
//  what text Label is replaced and `textArguments` (at the same index)
//  records with what it needs to be replaced
var private array<Text>         textLabels;
var private array<Text>         textArguments;

var private const int TPERCENT, TAMPERSAND;

const CODEPOINT_PERCENT     = 37;   // '%'
const CODEPOINT_AMPERSAND   = 38;   // '&'

protected function Finalizer()
{
    local int i;

    //  Clear user input
    Reset();
    //  Clear numeric labels
    numericLabelsAmount   = 0;
    _.memory.FreeMany(parts);
    //  Clear text Labels
    parts.length = 0;
    for (i = 0; i < Labels.length; i += 1) {
        _.memory.Free(Labels[i].textLabel);
    }
    labels.length = 0;
    //  Now we can safely mark caller template as not initialized
    initialized = false;
}

/**
 *  Checks if caller `TextTemplate` was already initialized.
 *
 *  If you use recommended means of creating `TextTemplate`s (`MakeTemplate` and
 *  `MakeTemplate_S`), then all your templates for not `none` arguments will be
 *  initialized.
 *
 *  @return `true` if it was initialized and `false` otherwise.
 */
public final function bool IsInitialized()
{
    return initialized;
}

/**
 *  Initializes caller `TextTemplate` with a given `input`.
 *
 *  Initialization should only be performed once for every `TextTemplate` -
 *  right after its allocation, before any use.
 *
 *  If you use recommended means of creating `TextTemplate`s (`MakeTemplate`),
 *  then all your templates for not `none` arguments will be initialized.
 *
 *  @param  input   `string` containing template to prepare `TextTemplate` from.
 */
public final function Initialize_S(string input)
{
    local MutableText wrapper;

    wrapper = _.text.FromStringM(input);
    Initialize(wrapper);
    _.memory.Free(wrapper);
}

/**
 *  Initializes caller `TextTemplate` with a given `input`.
 *
 *  Initialization should only be performed once for every `TextTemplate` -
 *  right after its allocation, before any use.
 *
 *  If you use recommended means of creating `TextTemplate`s (`MakeTemplate`),
 *  then all your templates for not `none` arguments will be initialized.
 *
 *  @param  input   Text containing template to prepare `TextTemplate` from.
 */
public final function Initialize(BaseText input)
{
    local Parser                parser;
    local MutableText           nextPart;
    local BaseText.Character    percent, nextCharacter;

    if (input == none) {
        return;
    }
    percent = _.text.CharacterFromCodePoint(CODEPOINT_PERCENT);
    parser  = input.Parse();
    while (!parser.HasFinished())
    {
        nextPart = MatchUntilUnescapedPercent(parser); //  guaranteed success
        parts[parts.length] = nextPart;
        if (parser.HasFinished()) {
            break;
        }
        //  If there is still input - next character is definitely "%"
        parser.MCharacter(nextCharacter).Confirm();
        parser.MCharacter(nextCharacter);   //  But what is this?
        if (parser.Ok() && _.text.IsCodePoint(nextCharacter, CODEPOINT_PERCENT))
        {
            //  "%%" prefix (already confirmed) - should have text Label
            MatchTextLabel(parser, percent);
        }
        else
        {
            //  single "%" prefix - look for number
            MatchNumericLabel(parser.R());
        }
    }
    initialized = true;
    _.memory.Free(parser);
    NormalizeArguments();
}

private final function MatchTextLabel(
    Parser              parser,
    BaseText.Character  percentCharacter)
{
    local MutableText nextLabel;

    parser.MUntil(nextLabel, percentCharacter).Confirm();
    labels[labels.length] = MakeTextLabel(nextLabel);
    //  Tries to parse "%%", but will be content with a single "%"
    parser.Match(T(TPERCENT)).Confirm();
    parser.Match(T(TPERCENT)).Confirm();
    //  Just reset to last properly parsed point in case of the failure
    parser.R();
}

private final function MatchNumericLabel(Parser parser)
{
    local int nextNumericLabel;

    if (parser.MInteger(nextNumericLabel).Ok()) {
        labels[labels.length] = MakeNumericLabel(nextNumericLabel);
    }
    parser.Confirm();
    //  Just reset to last properly parsed point in case of the failure
    parser.R();
}

//  Normalize enumeration by replacing them with natural numbers sequence:
//  [0, 1, 2, ...] in the same order:
//  [2, 6, 3] -> [0, 2, 1]
//  [-2, 0, 4, -7] -> [1, 2, 3, 0]
//  [1, 1, 2, 1] -> [0, 1, 3, 2]
private final function NormalizeArguments()
{
    local int           i;
    local int           nextArgument;
    local int           lowestArgument, lowestArgumentIndex;
    local array<int>    argumentsOrder, normalizedArguments;

    for (i = 0; i < labels.length; i += 1)
    {
        if (labels[i].textLabel == none)
        {
            numericLabelsAmount += 1;
            argumentsOrder[argumentsOrder.length] = labels[i].numberLabel;
        }
    }
    normalizedArguments.length = argumentsOrder.length;
    while (nextArgument < normalizedArguments.length)
    {
        //  Find next minimal index and record next natural number
        //  (`nextArgument`) into it
        for (i = 0; i < argumentsOrder.length; i += 1)
        {
            if (argumentsOrder[i] < lowestArgument || i == 0)
            {
                lowestArgumentIndex = i;
                lowestArgument = argumentsOrder[i];
            }
        }
        argumentsOrder[lowestArgumentIndex] = MaxInt;
        normalizedArguments[lowestArgumentIndex] = nextArgument;
        nextArgument += 1;
    }
    nextArgument = 0;
    for (i = 0; i < labels.length; i += 1)
    {
        if (labels[i].textLabel == none)
        {
            labels[i].numberLabel = normalizedArguments[nextArgument];
            nextArgument += 1;
        }
    }
}

private final function Label MakeTextLabel(MutableText Label2)
{
    local Label result;

    result.textLabel = Label2;
    result.insertionIndex = parts.length;
    return result;
}

private final function Label MakeNumericLabel(int Label2)
{
    local Label result;

    result.numberLabel = Label2;
    result.insertionIndex = parts.length;
    return result;
}

//      Skips until next non-escaped (that is "&%") '%' character
//  (or until the end).
//      It returns any contents inside `parser` before that character replacing
//  "&%" with simply "%", but leaving all other escaped sequences intact,
//  e.g. "&a" -> "&a" and "&{" -> "&{". This is needed to allow parsing of
//  the result of substitution as a formatted string.
private final function MutableText MatchUntilUnescapedPercent(Parser parser)
{
    local MutableText           result, nextMatched;
    local BaseText.Character    ampersand, nextCharacter;
    local array<Text>           delimiters;

    ampersand = _.text.CharacterFromCodePoint(CODEPOINT_AMPERSAND);
    delimiters[0] = T(TPERCENT);
    delimiters[1] = T(TAMPERSAND);
    result = _.text.Empty();
    while (!parser.HasFinished())
    {
        parser.MUntilMany(nextMatched, delimiters).Confirm();
        result.Append(nextMatched);
        _.memory.Free(nextMatched);
        if (parser.HasFinished()) {
            break;
        }
        parser.MCharacter(nextCharacter);
        //  If this is "%": we are done
        if (_.text.IsCodePoint(nextCharacter, CODEPOINT_PERCENT))
        {
            parser.R();
            return result;
        }
        //  Otherwise it is "&": skip it and the next character
        parser.MCharacter(nextCharacter).Confirm();
        if (!parser.Ok())
        {
            result.AppendCharacter(ampersand);
            return result;
        }
        if (!_.text.IsCodePoint(nextCharacter, CODEPOINT_PERCENT)) {
            result.AppendCharacter(ampersand);
        }
        result.AppendCharacter(nextCharacter);
    }
    parser.Confirm();
    return result;
}

/**
 *  Resets any data user entered into this template via any "Arg"-methods.
 *
 *  This method allows to reuse a once initialized `TextTemplate` any amount of
 *  times.
 *
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate Reset()
{
    if (!initialized) {
        return self;
    }
    _.memory.FreeMany(numericArguments);
    _.memory.FreeMany(textLabels);
    _.memory.FreeMany(textArguments);
    numericArguments.length = 0;
    textLabels.length     = 0;
    textArguments.length    = 0;
    return self;
}

/**
 *  Returns amount of numeric arguments inside the caller `TextTemplate`.
 *
 *  @return Amount of numeric arguments inside the caller `TextTemplate`.
 *      `-1` for uninitialized `TextTemplate`s.
 */
public final function int GetNumericArgsAmount()
{
    if (initialized) {
        return numericLabelsAmount;
    }
    return -1;
}

/**
 *  Returns array of text arguments inside the caller `TextTemplate`.
 *
 *  @return Array of text arguments inside the caller `TextTemplate`.
 *      Empty array for uninitialized `TextTemplate`s.
 */
public final function array<Text> GetTextArgs()
{
    local int           i, j;
    local bool          duplicate;
    local array<Text>   result;

    if (!initialized) {
        return result;
    }
    for (i = 0; i < labels.length; i += 1)
    {
        if (labels[i].textLabel == none) {
            continue;
        }
        duplicate = false;
        for (j = 0; j < result.length; j += 1)
        {
            if (result[j].Compare(labels[i].textLabel))
            {
                duplicate = true;
                break;
            }
        }
        if (!duplicate && labels[i].textLabel != none) {
            result[result.length] = labels[i].textLabel.Copy();
        }
    }
    return result;
}

/**
 *  Replaces next numeric argument with `argument` value.
 *
 *  If all numeric arguments were already filled this call will do nothing.
 *
 *  @param  argument    Value to replace next numeric argument in the caller
 *      `TextTemplate`. `none` values will be ignored (method will do nothing).
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate Arg_S(string argument)
{
    local MutableText wrapper;

    wrapper = _.text.FromStringM(argument);
    Arg(wrapper);
    _.memory.Free(wrapper);
    return self;
}

/**
 *  Replaces next numeric argument with `argument` value.
 *
 *  If all numeric arguments were already filled this call will do nothing.
 *
 *  @param  argument            Value to replace next numeric argument in
 *      the caller `TextTemplate`. `none` equals to an empty text.
 *  @param  ignoreFormatting    `false` means `argument` will be inserted along
 *      with its formatting information. Setting this option to `true` will
 *      insert it into template as plain text without any formatting
 *      (which should also be faster).
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate Arg(
    BaseText        argument,
    optional bool   ignoreFormatting)
{
    if (numericLabelsAmount <= numericArguments.length) {
        return self;
    }
    if (argument != none)
    {
        if (ignoreFormatting) {
            numericArguments[numericArguments.length] = argument.Copy();
        }
        else
         {
            numericArguments[numericArguments.length] =
                argument.ToFormattedText();
        }
    }
    else {
        numericArguments[numericArguments.length] = none;
    }
    return self;
}

/**
 *  Replaces next numeric argument with `argument` integer value.
 *
 *  If all numeric arguments were already filled this call will do nothing.
 *
 *  @param  argument    Value to replace next numeric argument in the caller
 *      `TextTemplate`.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate ArgInt(int argument)
{
    local MutableText textRepresentation;

    textRepresentation = _.text.FromIntM(argument);
    Arg(textRepresentation);
    _.memory.Free(textRepresentation);
    return self;
}

/**
 *  Replaces next numeric argument with `argument` floating point value.
 *
 *  If all numeric arguments were already filled this call will do nothing.
 *
 *  @param  argument    Value to replace next numeric argument in the caller
 *      `TextTemplate`.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate ArgFloat(float argument)
{
    local MutableText textRepresentation;

    textRepresentation = _.text.FromFloatM(argument);
    Arg(textRepresentation);
    _.memory.Free(textRepresentation);
    return self;
}

/**
 *  Replaces next numeric argument with `argument` boolean value.
 *
 *  If all numeric arguments were already filled this call will do nothing.
 *
 *  @param  argument    Value to replace next numeric argument in the caller
 *      `TextTemplate`.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate ArgBool(bool argument)
{
    local MutableText textRepresentation;

    textRepresentation = _.text.FromBoolM(argument);
    Arg(textRepresentation);
    _.memory.Free(textRepresentation);
    return self;
}

/**
 *  Replaces next numeric argument with `argument` class value.
 *
 *  If all numeric arguments were already filled this call will do nothing.
 *
 *  @param  argument    Value to replace next numeric argument in the caller
 *      `TextTemplate`.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate ArgClass(class<Object> argument)
{
    local MutableText textRepresentation;

    textRepresentation = _.text.FromClassM(argument);
    Arg(textRepresentation);
    _.memory.Free(textRepresentation);
    return self;
}

/**
 *  Replaces next text argument with label `label` with `argument` value.
 *
 *  If all text argument with that label was already set, then it will override
 *  previous value.
 *
 *  @param  label       Label of the text argument to replace.
 *  @param  argument    Value to replace specified text argument in the caller
 *      `TextTemplate` with.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate TextArg_S(string label, string argument)
{
    local MutableText labelWrapper, argumentWrapper;

    labelWrapper    = _.text.FromStringM(label);
    argumentWrapper = _.text.FromStringM(argument);
    TextArg(labelWrapper, argumentWrapper);
    _.memory.Free(labelWrapper);
    _.memory.Free(argumentWrapper);
    return self;
}

/**
 *  Replaces next text argument with label `label` with `argument` value.
 *
 *  If all text argument with that label was already set, then it will override
 *  previous value.
 *
 *  @param  label               Label of the text argument to replace.
 *  @param  argument            Value to replace specified text argument in
 *      the caller `TextTemplate` with. `none` is equal to an empty text.
 *  @param  ignoreFormatting    `false` means `argument` will be inserted along
 *      with its formatting information. Setting this option to `true` will
 *      insert it into template as plain text without any formatting
 *      (which should also be faster).
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate TextArg(
    BaseText        label,
    BaseText        argument,
    optional bool   ignoreFormatting)
{
    local int i;

    if (label == none) {
        return self;
    }
    for (i = 0; i < textLabels.length; i += 1)
    {
        if (label.Compare(textLabels[i]))
        {
            _.memory.Free(textArguments[i]);
            if (argument != none) {
                textArguments[i] = argument.Copy();
            }
            else {
                textArguments[i] = none;
            }
            return self;
        }
    }
    if (label != none) {
        textLabels[textLabels.length] = label.Copy();
    }
    else {
        textLabels[textLabels.length] = none;   
    }
    if (argument != none)
    {
        if (ignoreFormatting) {
            textArguments[i] = argument.Copy();
        }
        else {
            textArguments[i] = argument.ToFormattedText();
        }
    }
    else {
        textArguments[i] = none;
    }
    return self;
}

/**
 *  Replaces next text argument with label `label` with integer `argument`
 *  value.
 *
 *  If all text argument with that label was already set, then it will override
 *  previous value.
 *
 *  @param  label       Label of the text argument to replace.
 *  @param  argument    Value to replace specified text argument in the caller
 *      `TextTemplate` with.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate TextArgInt_S(string label, int argument)
{
    local MutableText labelWrapper;
    local MutableText textRepresentation;

    labelWrapper = _.text.FromStringM(label);
    textRepresentation = _.text.FromIntM(argument);
    TextArg(labelWrapper, textRepresentation);
    _.memory.Free(textRepresentation);
    _.memory.Free(labelWrapper);
    return self;
}

/**
 *  Replaces next text argument with label `label` with integer `argument`
 *  value.
 *
 *  If all text argument with that label was already set, then it will override
 *  previous value.
 *
 *  @param  label       Label of the text argument to replace.
 *  @param  argument    Value to replace specified text argument in the caller
 *      `TextTemplate` with.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate TextArgInt(BaseText label, int argument)
{
    local MutableText textRepresentation;

    textRepresentation = _.text.FromIntM(argument);
    TextArg(label, textRepresentation);
    _.memory.Free(textRepresentation);
    return self;
}

/**
 *  Replaces next text argument with label `label` with floating point
 *  `argument` value.
 *
 *  If all text argument with that label was already set, then it will override
 *  previous value.
 *
 *  @param  label       Label of the text argument to replace.
 *  @param  argument    Value to replace specified text argument in the caller
 *      `TextTemplate` with.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate TextArgFloat_S(string label, float argument)
{
    local MutableText labelWrapper;
    local MutableText textRepresentation;

    labelWrapper = _.text.FromStringM(label);
    textRepresentation = _.text.FromFloatM(argument);
    TextArg(labelWrapper, textRepresentation);
    _.memory.Free(textRepresentation);
    _.memory.Free(labelWrapper);
    return self;
}

/**
 *  Replaces next text argument with label `label` with floating point
 *  `argument` value.
 *
 *  If all text argument with that label was already set, then it will override
 *  previous value.
 *
 *  @param  label       Label of the text argument to replace.
 *  @param  argument    Value to replace specified text argument in the caller
 *      `TextTemplate` with.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate TextArgFloat(BaseText label, float argument)
{
    local MutableText textRepresentation;

    textRepresentation = _.text.FromFloatM(argument);
    TextArg(label, textRepresentation);
    _.memory.Free(textRepresentation);
    return self;
}

/**
 *  Replaces next text argument with label `label` with boolean `argument`
 *  value.
 *
 *  If all text argument with that label was already set, then it will override
 *  previous value.
 *
 *  @param  label       Label of the text argument to replace.
 *  @param  argument    Value to replace specified text argument in the caller
 *      `TextTemplate` with.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate TextArgBool_S(string label, bool argument)
{
    local MutableText labelWrapper;
    local MutableText textRepresentation;

    labelWrapper = _.text.FromStringM(label);
    textRepresentation = _.text.FromBoolM(argument);
    TextArg(labelWrapper, textRepresentation);
    _.memory.Free(textRepresentation);
    _.memory.Free(labelWrapper);
    return self;
}

/**
 *  Replaces next text argument with label `label` with boolean `argument`
 *  value.
 *
 *  If all text argument with that label was already set, then it will override
 *  previous value.
 *
 *  @param  label       Label of the text argument to replace.
 *  @param  argument    Value to replace specified text argument in the caller
 *      `TextTemplate` with.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate TextArgBool(BaseText label, bool argument)
{
    local MutableText textRepresentation;

    textRepresentation = _.text.FromBoolM(argument);
    TextArg(label, textRepresentation);
    _.memory.Free(textRepresentation);
    return self;
}

/**
 *  Replaces next text argument with label `label` with class value `argument`.
 *
 *  If all text argument with that label was already set, then it will override
 *  previous value.
 *
 *  @param  label       Label of the text argument to replace.
 *  @param  argument    Value to replace specified text argument in the caller
 *      `TextTemplate` with.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate TextArgClass_S(
    string          label,
    class<Object>   argument)
{
    local MutableText labelWrapper;
    local MutableText textRepresentation;

    labelWrapper = _.text.FromStringM(label);
    textRepresentation = _.text.FromClassM(argument);
    TextArg(labelWrapper, textRepresentation);
    _.memory.Free(textRepresentation);
    _.memory.Free(labelWrapper);
    return self;
}

/**
 *  Replaces next text argument with label `label` with class value `argument`.
 *
 *  If all text argument with that label was already set, then it will override
 *  previous value.
 *
 *  @param  label       Label of the text argument to replace.
 *  @param  argument    Value to replace specified text argument in the caller
 *      `TextTemplate` with.
 *  @return Reference to the caller `TextTemplate` to allow for method chaining.
 */
public final function TextTemplate TextArgClass(
    BaseText        label,
    class<Object>   argument)
{
    local MutableText textRepresentation;

    textRepresentation = _.text.FromClassM(argument);
    TextArg(label, textRepresentation);
    _.memory.Free(textRepresentation);
    return self;
}

private final function Text BorrowNumericArg(int index)
{
    if (index < 0)                          return none;
    if (index >= numericArguments.length)   return none;

    return numericArguments[index];
}

private final function Text BorrowTextArg(BaseText Label)
{
    local int i;

    if (Label == none) {
        return none;
    }
    for (i = 0; i < textLabels.length; i += 1)
    {
        if (Label.Compare(textLabels[i])) {
            return textArguments[i];
        }
    }
    return none;
}

/**
 *  Assembles initialized `TextTemplate` from provided arguments into a final
 *  `Text` result.
 *
 *  Unspecified arguments will be replaced with empty texts.
 *
 *  Returns `string`. To return mutable `Text` or `MutableText` use
 *  `Collect()` or `CollectM()`.
 *
 *  @return Result of replacing all argument inside caller `TextTemplate` with
 *      arguments, specified by user.
 */
public final function string Collect_S()
{
    return _.text.IntoString(CollectM());
}

/**
 *  Assembles initialized `TextTemplate` from provided arguments into a final
 *  `Text` result.
 *
 *  Unspecified arguments will be replaced with empty texts.
 *
 *  Returns immutable `Text`. To return mutable `MutableText` use `CollectM()`.
 *
 *  @return Result of replacing all argument inside caller `TextTemplate` with
 *      arguments, specified by user.
 */
public final function Text Collect()
{
    local MutableText mutableResult;

    mutableResult = CollectM();
    if (mutableResult != none) {
        return mutableResult.IntoText();
    }
    return none;
}

/**
 *  Assembles initialized `TextTemplate` from provided arguments into a final
 *  `Text` result.
 *
 *  Unspecified arguments will be replaced with empty texts.
 *
 *  Returns mutable `MutableText`. To return immutable `Text` use `CollectM()`.
 *
 *  @return Result of replacing all argument inside caller `TextTemplate` with
 *      arguments, specified by user.
 */
public final function MutableText CollectM()
{
    local int           i, labelCounter;
    local Label         nextLabel;
    local MutableText   builder;

    if (!initialized) {
        return none;
    }
    builder = _.text.Empty();
    for (i = 0; i < parts.length; i += 1)
    {
        if (    labelCounter < labels.length
            &&  labels[labelCounter].insertionIndex == i)
        {
            nextLabel = labels[labelCounter];
            if (nextLabel.textLabel == none) {
                builder.Append(BorrowNumericArg(nextLabel.numberLabel));
            }
            else {
                builder.Append(BorrowTextArg(nextLabel.textLabel));
            }
            labelCounter += 1;
        }
        builder.Append(parts[i]);
    }
    while (labelCounter < labels.length)
    {
        nextLabel = labels[labelCounter];
        if (nextLabel.textLabel == none) {
            builder.Append(BorrowNumericArg(nextLabel.numberLabel));
        }
        else {
            builder.Append(BorrowTextArg(nextLabel.textLabel));
        }
        labelCounter += 1;
    }
    return builder;
}

/**
 *  Assembles initialized `TextTemplate` from provided arguments and parses
 *  resulting text as formatted string.
 *
 *  Allows to do things like specify color inside formatted strings:
 *  "{%%color_arg%% ColoredText}".
 *
 *  Unspecified arguments will be replaced with empty texts.
 *
 *  Returns immutable `Text`. To return mutable `MutableText` use `CollectM()`.
 *
 *  @return Result of replacing all argument inside caller `TextTemplate` with
 *      arguments, specified by user and then parsing that intermediate result
 *  as a formatting string. 
 */
public final function Text CollectFormatted()
{
    local Text          result;
    local MutableText   source;

    source = CollectM();
    if (source == none) {
        return none;
    }
    result = _.text.FromFormatted(source);
    _.memory.Free(source);
    return result;
}

/**
 *  Assembles initialized `TextTemplate` from provided arguments and parses
 *  resulting text as formatted string.
 *
 *  Allows to do things like specify color inside formatted strings:
 *  "{%%color_arg%% ColoredText}".
 *
 *  Unspecified arguments will be replaced with empty texts.
 *
 *  Returns mutable `MutableText`. To return immutable `Text` use `CollectM()`.
 *
 *  @return Result of replacing all argument inside caller `TextTemplate` with
 *      arguments, specified by user and then parsing that intermediate result
 *  as a formatting string. 
 */
public final function MutableText CollectFormattedM()
{
    local MutableText result, source;

    source = CollectM();
    if (source == none) {
        return none;
    }
    result = _.text.FromFormattedM(source);
    _.memory.Free(source);
    return result;
}

defaultproperties
{
    TPERCENT    = 0
    stringConstants(0) = "%"
    TAMPERSAND  = 1
    stringConstants(1) = "&&"
}