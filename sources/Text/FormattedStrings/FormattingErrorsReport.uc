/**
 *      Simple aggregator object for errors that may arise during parsing of
 *  formatted string.
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
class FormattingErrorsReport extends AcediaObject;

/**
 *  Errors that can occur during parsing of the formatted string.
 */
enum FormattedStringErrorType
{
    //  There was an unmatched closing figure bracket, e.g.
    //  "{$red Hey} you, there}!"
    FSE_UnmatchedClosingBrackets,
    //  Color tag was empty, e.g. "Why not { just kill them}?"
    FSE_EmptyColorTag,
    //  Color tag cannot be parsed as a color or color gradient,
    //  e.g. "Why not {just kill them}?"
    FSE_BadColor,
    //  Gradient color tag contained bad point specified, e.g.
    //  "That is SO {$red:$orange[what?]:$red AMAZING}!!!" or
    //  "That is SO {$red:$orange[0.76:$red AMAZING}!!!"
    FSE_BadGradientPoint,
    //  Short tag (e.g. "^r" or "^2") was specified, but the character after "^"
    //  is not configured to correspond to any color
    FSE_BadShortColorTag
};

//  `FSE_UnmatchedClosingBrackets` and `FSE_EmptyColorTag` errors never have any
//  `Text` hint associated with them, so simply store how many times they were
//  invoked.
var private int unmatchedClosingBracketsErrorCount;
var private int emptyColorTagErrorCount;
//  `FSE_BadColor`, `FSE_BadGradientPoint` and `FSE_BadShortColorTag` are always
//  expected to have a `Text` hint reported alongside them. We store that hint.
var private array<Text> badColorTagErrorHints;
var private array<Text> badGradientTagErrorHints;
var private array<Text> badShortColorTagErrorHints;

/**
 *  `FormattingErrorsReport` returns reported errors in formatting strings via
 *  this struct.
 */
struct FormattedStringError
{
    //  Type of the error
    var FormattedStringErrorType    type;
    //      How many times had this error happened?
    //      Can be specified for `FSE_UnmatchedClosingBrackets` and
    //  `FSE_EmptyColorTag` error types. Never negative.
    var int                         count;
    //      `Text` hint that should help user understand where the error is
    //  coming from.
    //      Can be specified for `FSE_BadColor`, `FSE_BadGradientPoint` and
    //  `FSE_BadShortColorTag` error types.
    var Text                        cause;
};

protected function Finalizer()
{
    unmatchedClosingBracketsErrorCount  = 0;
    emptyColorTagErrorCount             = 0;
    _.memory.FreeMany(badColorTagErrorHints);
    _.memory.FreeMany(badShortColorTagErrorHints);
    _.memory.FreeMany(badGradientTagErrorHints);
    badColorTagErrorHints.length        = 0;
    badShortColorTagErrorHints.length   = 0;
    badGradientTagErrorHints.length     = 0;
}

/**
 *  Adds new error to the caller `FormattingErrorsReport` object.
 *
 *  @param  type    Type of the new error.
 *  @param  cause   Auxiliary `Text` that might give user additional hint about
 *      what exactly went wrong.
 *      If this parameter is `none` for errors  of type `FSE_BadColor`,
 *      `FSE_BadGradientPoint` or `FSE_BadShortColorTag`, then method will
 *      do nothing.
 *      Parameter is unused for other types of errors.
 */
public final function Report(
    FormattedStringErrorType    type,
    optional BaseText           cause)
{
    switch (type)
    {
    case FSE_UnmatchedClosingBrackets:
        unmatchedClosingBracketsErrorCount += 1;
        break;
    case FSE_EmptyColorTag:
        emptyColorTagErrorCount += 1;
        break;
    case FSE_BadColor:
        if (cause != none) {
            badColorTagErrorHints[badColorTagErrorHints.length] = cause.Copy();
        }
        break;
    case FSE_BadShortColorTag:
        if (cause != none)
        {
            badShortColorTagErrorHints[badShortColorTagErrorHints.length] =
                cause.Copy();
        }
        break;
    case FSE_BadGradientPoint:
        if (cause != none)
        {
            badGradientTagErrorHints[badGradientTagErrorHints.length] =
                cause.Copy();
        }
        break;
    }
}

/**
 *  Returns all formatted string errors reported for caller
 *  `FormattingErrorReport`.
 *
 *  @return Array of `FormattedStringError`s that represent reported errors.
 *      Each `FormattedStringError` item in array has either:
 *          * non-`none` `cause` field or;
 *          * strictly positive `count > 0` field.
 *      But never both.
 *      `count` field is always guaranteed to be non-negative.
 *      WARNING: `FormattedStringError` struct may contain `Text` objects that
 *      should be deallocated, as per usual rules.
 */
public final function array<FormattedStringError> GetErrors()
{
    local int                           i;
    local FormattedStringError          newError;
    local array<FormattedStringError>   errors;
    //  First add errors that do not need `cause` variable
    if (unmatchedClosingBracketsErrorCount > 0)
    {
        newError.type = FSE_UnmatchedClosingBrackets;
        newError.count = unmatchedClosingBracketsErrorCount;
        errors[errors.length] = newError;
    }
    if (emptyColorTagErrorCount > 0)
    {
        newError.type = FSE_EmptyColorTag;
        newError.count = emptyColorTagErrorCount;
        errors[errors.length] = newError;
    }
    //  We overwrite old `newError.cause` with new `Text` object each time we
    //  add new error, so it should be fine to not set it to `none` after
    //  "moving it" into `errors`.
    newError.type = FSE_BadColor;
    for (i = 0; i < badColorTagErrorHints.length; i += 1)
    {
        newError.cause = badColorTagErrorHints[i].Copy();
        errors[errors.length] = newError;
    }
    newError.type = FSE_BadShortColorTag;
    for (i = 0; i < badShortColorTagErrorHints.length; i += 1)
    {
        newError.cause = badShortColorTagErrorHints[i].Copy();
        errors[errors.length] = newError;
    }
    newError.type = FSE_BadGradientPoint;
    for (i = 0; i < badGradientTagErrorHints.length; i += 1)
    {
        newError.cause = badGradientTagErrorHints[i].Copy();
        errors[errors.length] = newError;
    }
    return errors;
}

defaultproperties
{
}