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
class FormattingErrors extends AcediaObject;

/**
 *  Errors that can occur during parsing of the formatted string.
 */
enum FormattedDataErrorType
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
    //  "That is SO {$red~$orange(what?)~$red AMAZING}!!!" or
    //  "That is SO {$red~$orange(0.76~$red AMAZING}!!!"
    FSE_BadGradientPoint,
    FSE_BadShortColorTag
};

//  `FSE_UnmatchedClosingBrackets` and `FSE_EmptyColorTag` errors never have any
//  `Text` hint associated with them, so simply store how many times they were
//  invoked.
var private int unmatchedClosingBracketsErrorCount;
var private int emptyColorTagErrorCount;
//  `FSE_BadColor` and `FSE_BadGradientPoint` are always expected to have
//  a `Text` hint reported alongside them, so simply store that hint.
var private array<Text> badColorTagErrorHints;
var private array<Text> badGradientTagErrorHints;
var private array<Text> badShortColorTagErrorHints;

//  We will report accumulated errors as an array of these structs.
struct FormattedDataError
{
    //  Type of the error
    var FormattedDataErrorType  type;
    //      How many times had this error happened?
    //      Can be specified for `FSE_UnmatchedClosingBrackets` and
    //  `FSE_EmptyColorTag` error types. Never negative.
    var int                     count;
    //      `Text` hint that should help user understand where the error is
    //  coming from.
    //      Can be specified for `FSE_BadColor` and `FSE_BadGradientPoint`
    //  error types.
    var Text                    cause;
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
 *  Adds new error to the caller `FormattingErrors` object.
 *
 *  @param  type    Type of the new error.
 *  @param  cause   Auxiliary `Text` that might give user additional hint about
 *      what exactly went wrong.
 *      If this parameter is `none` for errors `FSE_BadColor` or
 *      `FSE_BadGradientPoint` - method will do nothing.
 */
public final function Report(FormattedDataErrorType type, optional Text cause)
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
 *  Returns array of errors collected so far.
 *
 *  @return Array of errors collected so far.
 *      Each `FormattedDataError` in array has either non-`none` `cause` field
 *      or strictly positive `count > 0` field (but not both).
 *      `count` field is always guaranteed to not be negative.
 *      WARNING: `FormattedDataError` struct may contain `Text` objects that
 *      should be deallocated.
 */
public final function array<FormattedDataError> GetErrors()
{
    local int                       i;
    local FormattedDataError        newError;
    local array<FormattedDataError> errors;
    //  We overwrite old `cause` in `newError` with new one each time we
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
    //  Need to reset `cause` here, to avoid duplicating it in
    //  following two errors
    newError.cause = none;
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
    return errors;
}

defaultproperties
{
}