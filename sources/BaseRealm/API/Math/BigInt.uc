/**
 *  A simple big integer implementation, mostly to allow Acedia's databases to
 *  store integers of arbitrary size.
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
class BigInt extends AcediaObject
    dependson(MathAPI);

/**
 *  # `BigInt`
 *
 *  A simple big integer implementation, mostly to allow Acedia's databases to
 *  store integers of arbitrary size. It can be used for long arithmetic
 *  computations, but it was mainly meant as a players' statistics counter and,
 *  therefore, not optimized for performing large amount of operations.
 *
 *  ## Usage
 *
 *      `BigInt` can be created from both `int` and decimal `BaseText`/`string`
 *  representation, preferably by `MathAPI` (`_.math.`) methods
 *  `ToBigInt()`/`MakeBigInt()`.
 *      Then it can be combined either directly with other `BigInt` or with
 *  `int`/`BaseText`/`string` through available arithmetic operations.
 *      To make use of stored value one can convert it back into either `int` or
 *  decimal `BaseText`/`string` representation.
 *      Newly allocated `BigInt` is guaranteed to hold `0` as value.
 */

/**
 *  `BigInt` data as a `struct` - meant to be used to store `BigInt`'s values
 *  inside the local databases.
 */
struct BigIntData
{
    var bool        negative;
    var array<byte> digits;
};

/**
 *  Used to represent a result of comparison for `BigInt`s with each other.
 */
enum BigIntCompareResult
{
    BICR_Less,
    BICR_Equal,
    BICR_Greater
};

//  Does stored `BigInt` has negative sign?
var private bool negative;
//      Digits array, from least to most significant. For example, for 13524:
//  `digits[0] = 4`
//  `digits[1] = 2`
//  `digits[2] = 5`
//  `digits[3] = 3`
//  `digits[4] = 1`
//      Valid `BigInt` should not have this array empty: zero should be
//  represented by an array with a single `0`-element.
//      This isn't a most efficient representation for `BigInt`, but it's easy
//  to convert to and from decimal representation.
//  INVARIANT: this array must not have leading (in the sense of significance)
//  zeroes. That is, last element of the array should not be a `0`. The only
//  exception if if stored value is `0`, then `digits` must consist of a single
//  `0` element.
var private array<byte> digits;

//      Constants useful for converting `BigInt` back to `int`, while avoiding
//  overflow.
//      We can add less digits than that without any fear of overflow
const DIGITS_IN_MAX_INT = 10;
//      Maximum `int` value is `2147483647`, so in case most significant digit
//  is 10th and is `2` (so number has a form of "2xxxxxxxxx"), to check for
//  overflow we only need to compare combination of the rest of the digits with
//  this constant.
const ALMOST_MAX_INT    = 147483647;
//  To add last digit we add/subtract that digit multiplied by this value.
const LAST_DIGIT_ORDER  = 1000000000;

protected function Constructor()
{
    SetZero();
}

protected function Finalizer()
{
    negative = false;
    digits.length = 0;
}

//  Auxiliary method to set current value to zero
private function BigInt SetZero()
{
    negative = false;
    digits.length = 1;
    digits[0] = 0;
    return self;
}

//      Minimal `int` value `-2,147,483,648` is somewhat of a pain to handle, so
//  just use this auxiliary pre-made constructor for it
private function BigInt SetMinimalNegative()
{
    negative = true;
    digits.length = 10;
    digits[0] = 8;
    digits[1] = 4;
    digits[2] = 6;
    digits[3] = 3;
    digits[4] = 8;
    digits[5] = 4;
    digits[6] = 7;
    digits[7] = 4;
    digits[8] = 1;
    digits[9] = 2;
    return self;
}

//  Removes unnecessary zeroes from leading digit positions `digits`.
//  Does not change contained value.
private final function TrimLeadingZeroes()
{
    local int i, zeroesToRemove;

    //      Find how many leading zeroes there is.
    //      Since `digits` stores digits from least to most significant, we need
    //  to check from the end of `digits` array.
    for (i = digits.length - 1; i >= 0; i -= 1)
    {
        if (digits[i] != 0) {
            break;
        }
        zeroesToRemove += 1;
    }
    //  `digits` must not be empty, enforce `0` value in that case
    if (zeroesToRemove  >= digits.length) {
        SetZero();
    }
    else {
        digits.length = digits.length - zeroesToRemove;
    }
}

/**
 *  Changes current value of `BigInt` to given `BigInt` value.
 *
 *  @param  value   New value of the caller `BigInt`. If `none` is given,
 *      method does nothing.
 *  @return Self-reference to allow for method chaining.
 */
public final function BigInt Set(BigInt value)
{
    if (value == none) {
        return self;
    }
    value.TrimLeadingZeroes();
    digits      = value.digits;
    negative    = value.negative;
    return self;
}

/**
 *  Changes current value of `BigInt` to given `int` value `value`.
 *
 *  Cannot fail.
 *
 *  @param  value   New value of the caller `BigInt`.
 *  @return Self-reference to allow for method chaining.
 */
public final function BigInt SetInt(int value)
{
    local MathAPI.IntegerDivisionResult divisionResult;

    negative = false;
    digits.length = 0;
    if (value < 0)
    {
        //  Treat special case of minimal `int` value `-2,147,483,648` that
        //  won't fit into positive `int` as special and use pre-made
        //  specialized constructor `CreateMinimalNegative()`
        if (value < -MaxInt) {
            return SetMinimalNegative();
        }
        else
        {
            negative = true;
            value *= -1;
        }
    }
    if (value == 0) {
        digits[0] = 0;
    }
    else
    {
        while (value > 0)
        {
            divisionResult = __().math.IntegerDivision(value, 10);
            value                   = divisionResult.quotient;
            digits[digits.length]   = divisionResult.remainder;
        }
    }
    TrimLeadingZeroes();
    return self;
}

/**
 *  Changes current value of `BigInt` to the value, given by decimal
 *  representation inside `value` argument.
 *
 *  If invalid decimal representation (digits only, possibly with leading sign)
 *  is given - behavior is undefined. Otherwise cannot fail.
 *
 *  @param  value   New value of the caller `BigInt`, given by decimal
 *      its representation. If `none` is given, method does nothing.
 *  @return Self-reference to allow for method chaining.
 */
public final function BigInt SetDecimal(BaseText value)
{
    local int                   i;
    local byte                  nextDigit;
    local Parser                parser;
    local Basetext.Character    nextCharacter;

    if (value == none) {
        return none;
    }
    parser = value.Parse();
    negative = parser.Match(P("-")).Ok();
    if (!parser.Ok()) {
        parser.R().Match(P("+")).Ok();
    }
    //  Reset to valid state whether sign was consumed or not
    parser.Confirm();
    parser.R();
    //  Reset current value
    digits.length = 0;
    digits.length = parser.GetRemainingLength();
    //  Parse new one
    i = digits.length - 1;
    while (!parser.HasFinished())
    {
        //  This should not happen, but just in case
        if (i < 0) {
            break;
        }
        parser.MCharacter(nextCharacter);
        nextDigit = Clamp(__().text.CharacterToInt(nextCharacter), 0, 9);
        digits[i] = nextDigit;
        i -= 1;
    }
    parser.FreeSelf();
    TrimLeadingZeroes();
    return self;
}

/**
 *  Changes current value of `BigInt` to the value, given by decimal
 *  representation inside `value` argument.
 *
 *  If invalid decimal representation (digits only, possibly with leading sign)
 *  is given - behavior is undefined. Otherwise cannot fail.
 *
 *  @param  value   New value of the caller `BigInt`, given by decimal
 *      its representation.
 *  @return Self-reference to allow for method chaining.
 */
public final function BigInt SetDecimal_S(string value)
{
    local MutableText wrapper;

    wrapper = __().text.FromStringM(value);
    SetDecimal(wrapper);
    wrapper.FreeSelf();
    return self;
}

//  Auxiliary method for comparing two `BigInt`s by their absolute value.
private function BigIntCompareResult _compareAbsolute(BigInt other)
{
    local int           i;
    local array<byte>   otherDigits;

    otherDigits = other.digits;
    if (digits.length == otherDigits.length)
    {
        for (i = digits.length - 1; i >= 0; i -= 1)
        {
            if (digits[i] < otherDigits[i]) {
                return BICR_Less;
            }
            if (digits[i] > otherDigits[i]) {
                return BICR_Greater;
            }
        }
        return BICR_Equal;
    }
    if (digits.length < otherDigits.length) {
        return BICR_Less;
    }
    return BICR_Greater;
}

/**
 *  Compares caller `BigInt` to `other`.
 *
 *  @param  other   Value to compare the caller `BigInt`.
 *      If given reference is `none` - behavior is undefined.
 *  @return `BigIntCompareResult` representing the result of comparison.
 *      Returned value describes how caller `BigInt` relates to the `other`,
 *      e.g. if `BICR_Less` was returned - it means that caller `BigInt` is
 *      smaller that `other`.
 */
public function BigIntCompareResult Compare(BigInt other)
{
    local BigIntCompareResult resultForModulus;

    if (other == none) {
        return BICR_Less;
    }
    if (negative && !other.negative) {
        return BICR_Less;
    }
    if (!negative && other.negative) {
        return BICR_Greater;
    }
    resultForModulus = _compareAbsolute(other);
    if (resultForModulus == BICR_Equal) {
        return BICR_Equal;
    }
    if (    (negative   &&  (resultForModulus == BICR_Greater))
        ||  (!negative  &&  (resultForModulus == BICR_Less))    )
    {
        return BICR_Less;
    }
    return BICR_Greater;
}

/**
 *  Compares caller `BigInt` to `other`.
 *
 *  @param  other   Value to compare the caller `BigInt`.
 *  @return `BigIntCompareResult` representing the result of comparison.
 *      Returned value describes how caller `BigInt` relates to the `other`,
 *      e.g. if `BICR_Less` was returned - it means that caller `BigInt` is
 *      smaller that `other`.
 */
public function BigIntCompareResult CompareInt(int other)
{
    local BigInt                wrapper;
    local BigIntCompareResult   result;

    wrapper = _.math.ToBigInt(other);
    result = Compare(wrapper);
    wrapper.FreeSelf();
    return result;
}

/**
 *  Compares caller `BigInt` to `other`.
 *
 *  @param  other   Value to compare the caller `BigInt`.
 *      If given reference is `none` - behavior is undefined.
 *  @return `BigIntCompareResult` representing the result of comparison.
 *      Returned value describes how caller `BigInt` relates to the `other`,
 *      e.g. if `BICR_Less` was returned - it means that caller `BigInt` is
 *      smaller that `other`.
 */
public function BigIntCompareResult CompareDecimal(BaseText other)
{
    local BigInt                wrapper;
    local BigIntCompareResult   result;

    wrapper = _.math.MakeBigInt(other);
    result = Compare(wrapper);
    wrapper.FreeSelf();
    return result;
}

/**
 *  Compares caller `BigInt` to `other`.
 *
 *  @param  other   Value to compare the caller `BigInt`.
 *      If given value contains invalid decimal value - behavior is undefined.
 *  @return `BigIntCompareResult` representing the result of comparison.
 *      Returned value describes how caller `BigInt` relates to the `other`,
 *      e.g. if `BICR_Less` was returned - it means that caller `BigInt` is
 *      smaller that `other`.
 */
public function BigIntCompareResult CompareDecimal_S(string other)
{
    local BigInt                wrapper;
    local BigIntCompareResult   result;

    wrapper = _.math.MakeBigInt_S(other);
    result = Compare(wrapper);
    wrapper.FreeSelf();
    return result;
}

//  Adds absolute values of caller `BigInt` and `other` with no changes to
//  the sign
private function _add(BigInt other)
{
    local int           i;
    local byte          carry, digitSum;
    local array<byte>   otherDigits;

    if (other == none) {
        return;
    }
    otherDigits = other.digits;
    if (digits.length < otherDigits.length) {
        digits.length = otherDigits.length;
    }
    else {
        otherDigits.length = digits.length;
    }
    carry = 0;
    for (i = 0; i < digits.length; i += 1)
    {
        digitSum = digits[i] + otherDigits[i] + carry;
        digits[i] = _.math.Remainder(digitSum, 10);
        carry = (digitSum - digits[i]) / 10;
    }
    if (carry > 0) {
        digits[digits.length] = carry;
    }
    //  No leading zeroes can be created here, so no need to trim
}

//  Subtracts absolute value of `other` from the caller `BigInt`, flipping
//  caller's sign in case `other`'s absolute value is bigger.
private function _sub(BigInt other)
{
    local int                   i;
    local int                   carry, nextDigit;
    local array<byte>           minuendDigits, subtrahendDigits;
    local BigIntCompareResult   resultForModulus;

    if (other == none) {
        return;
    }
    resultForModulus = _compareAbsolute(other);
    if (resultForModulus == BICR_Equal)
    {
        SetZero();
        return;
    }
    if (resultForModulus == BICR_Less)
    {
        negative            = !negative;
        minuendDigits       = other.digits;
        subtrahendDigits    = digits;
    }
    else
    {
        minuendDigits       = digits;
        subtrahendDigits    = other.digits;
    }
    digits.length           = minuendDigits.length;
    subtrahendDigits.length = minuendDigits.length;
    carry = 0;
    for (i = 0; i < digits.length; i += 1)
    {
        nextDigit = int(minuendDigits[i]) - int(subtrahendDigits[i]) + carry;
        if (nextDigit < 0)
        {
            nextDigit += 10;
            carry = -1;
        }
        else {
            carry = 0;
        }
        digits[i] = nextDigit;
    }
    TrimLeadingZeroes();
}

/**
 *  Adds `other` value to the caller `BigInt`.
 *
 *  @param  other   Value to add. If `none` is given method does nothing.
 *  @return Self-reference to allow for method chaining.
 */
public function BigInt Add(BigInt other)
{
    if (other == none) {
        return self;
    }
    if (negative == other.negative) {
        _add(other);
    }
    else {
        _sub(other);
    }
    return self;
}

/**
 *  Adds `other` value to the caller `BigInt`.
 *
 *  Cannot fail.
 *
 *  @param  other   Value to add.
 *  @return Self-reference to allow for method chaining.
 */
public function BigInt AddInt(int other)
{
    local BigInt otherObject;

    otherObject = _.math.ToBigInt(other);
    Add(otherObject);
    _.memory.Free(otherObject);
    return self;
}

/**
 *  Adds `other` value to the caller `BigInt`.
 *
 *  If invalid decimal representation (digits only, possibly with leading sign)
 *  is given - behavior is undefined. Otherwise cannot fail.
 *
 *  @param  other   Value to add. If `none` is given, method does nothing.
 *  @return Self-reference to allow for method chaining.
 */
public function BigInt AddDecimal(BaseText other)
{
    local BigInt otherObject;

    if (other == none) {
        return self;
    }
    otherObject = _.math.MakeBigInt(other);
    Add(otherObject);
    _.memory.Free(otherObject);
    return self;
}

/**
 *  Adds `other` value to the caller `BigInt`.
 *
 *  If invalid decimal representation (digits only, possibly with leading sign)
 *  is given - behavior is undefined. Otherwise cannot fail.
 *
 *  @param  other   Value to add.
 *  @return Self-reference to allow for method chaining.
 */
public function BigInt AddDecimal_S(string other)
{
    local BigInt otherObject;

    otherObject = _.math.MakeBigInt_S(other);
    Add(otherObject);
    _.memory.Free(otherObject);
    return self;
}

/**
 *  Subtracts `other` value to the caller `BigInt`.
 *
 *  @param  other   Value to subtract. If `none` is given method does nothing.
 *  @return Self-reference to allow for method chaining.
 */
public function BigInt Subtract(BigInt other)
{
    if (negative != other.negative) {
        _add(other);
    }
    else {
        _sub(other);
    }
    return self;
}

/**
 *  Subtracts `other` value to the caller `BigInt`.
 *
 *  Cannot fail.
 *
 *  @param  other   Value to subtract.
 *  @return Self-reference to allow for method chaining.
 */
public function BigInt SubtractInt(int other)
{
    local BigInt otherObject;

    otherObject = _.math.ToBigInt(other);
    Subtract(otherObject);
    _.memory.Free(otherObject);
    return self;
}

/**
 *  Subtracts `other` value to the caller `BigInt`.
 *
 *  If invalid decimal representation (digits only, possibly with leading sign)
 *  is given - behavior is undefined. Otherwise cannot fail.
 *
 *  @param  other   Value to subtract. If `none`, method does nothing.
 *  @return Self-reference to allow for method chaining.
 */
public function BigInt SubtractDecimal(BaseText other)
{
    local BigInt otherObject;

    if (other == none) {
        return self;
    }
    otherObject = _.math.MakeBigInt(other);
    Subtract(otherObject);
    _.memory.Free(otherObject);
    return self;
}

/**
 *  Subtracts `other` value to the caller `BigInt`.
 *
 *  If invalid decimal representation (digits only, possibly with leading sign)
 *  is given - behavior is undefined. Otherwise cannot fail.
 *
 *  @param  other   Value to subtract.
 *  @return Self-reference to allow for method chaining.
 */
public function BigInt SubtractDecimal_S(string other)
{
    local BigInt otherObject;

    otherObject = _.math.MakeBigInt_S(other);
    Subtract(otherObject);
    _.memory.Free(otherObject);
    return self;
}

/**
 *  Checks if caller `BigInt` is negative. Zero is not considered negative
 *  number.
 *
 *  @return `true` if stored value is negative (`< 0`) and `false` otherwise
 *      (`>= 0`).
 */
public function bool IsNegative()
{
    //  Handle special case of zero first (it ignores `negative` flag)
    if (digits.length == 1 && digits[0] == 0) {
        return false;
    }
    return negative;
}

/**
 *  Converts caller `BigInt` into `int` representation.
 *
 *  In case stored value is outside `int`'s value range
 *  (`[-MaxInt-1, MaxInt] == [-2147483648; 2147483647]`),
 *  method returns either maximal or minimal possible value, depending on
 *  the `BigInt`'s sign.
 *
 *  @return `int` representation of the caller `BigInt`, clamped into available
 *      `int` value range.
 */
public function int ToInt()
{
    local int i;
    local int accumulator;
    local int safeDigitsAmount;

    if (digits.length <= 0) {
        return 0;
    }
    if (digits.length > DIGITS_IN_MAX_INT)
    {
        if (negative) {
            return (-MaxInt - 1);
        }
        else {
            return MaxInt;
        }
    }
    //  At most `DIGITS_IN_MAX_INT - 1` iterations
    safeDigitsAmount = Min(DIGITS_IN_MAX_INT - 1, digits.length);
    for (i = safeDigitsAmount - 1; i >= 0; i -= 1)
    {
        accumulator *= 10;
        accumulator += digits[i];
    }
    if (negative) {
        accumulator *= -1;
    }
    accumulator = AddUnsafeDigitToInt(accumulator);
    return accumulator;
}

//      Adding `DIGITS_IN_MAX_INT - 1` will never lead to an overflow, but
//  adding the next digit can, so we need to handle it differently and more
//  carefully.
//      Assumes `digits.length <= DIGITS_IN_MAX_INT`.
private function int AddUnsafeDigitToInt(int accumulator)
{
    local int   unsafeDigit;
    local bool  noOverflow;

    if (digits.length < DIGITS_IN_MAX_INT) {
        return accumulator;
    }
    unsafeDigit = digits[DIGITS_IN_MAX_INT - 1];
    //  `MaxInt` stats with `2`, so if last/unsafe digit is either `0` or `1`,
    //  there is no overflow, otherwise - check rest of the digits
    noOverflow =  (unsafeDigit < 2);
    if (unsafeDigit == 2)
    {
        //  Include `MaxInt` and `-MaxInt-1` (minimal possible value) into
        //  an overflow too - this way we still give a correct result, but do
        //  not have to worry about `int`-arithmetic error
        noOverflow = noOverflow
            ||  (negative && (accumulator > -ALMOST_MAX_INT - 1))
            ||  (!negative && (accumulator < ALMOST_MAX_INT));
    }
    if (noOverflow)
    {
        if (negative) {
            accumulator -= unsafeDigit * LAST_DIGIT_ORDER;
        }
        else {
            accumulator += unsafeDigit * LAST_DIGIT_ORDER;
        }
        return accumulator;
    }
    //  Handle overflow
    if (negative) {
        return (-MaxInt - 1);
    }
    return MaxInt;
}

/**
 *  Converts caller `BigInt` into `Text` representation.
 *
 *  @return `Text` representation of the caller `BigInt`.
 */
public function Text ToText()
{
    return ToText_M().IntoText();
}

/**
 *  Converts caller `BigInt` into `MutableText` representation.
 *
 *  @return `MutableText` representation of the caller `BigInt`.
 */
public function MutableText ToText_M()
{
    local int           i;
    local MutableText   result;

    result = _.text.Empty();
    if (negative) {
        result.AppendCharacter(_.text.GetCharacter("-"));
    }
    for (i = digits.length - 1; i >= 0; i -= 1) {
        result.AppendCharacter(_.text.CharacterFromCodePoint(digits[i] + 48));
    }
    return result;
}

/**
 *  Converts caller `BigInt` into `string` representation.
 *
 *  @return `string` representation of the caller `BigInt`.
 */
public function string ToString()
{
    local int       i;
    local string    result;

    if (negative) {
        result = "-";
    }
    for (i = digits.length - 1; i >= 0; i -= 1) {
        result = result $ digits[i];
    }
    return result;
}

/**
 *  Restores `BigInt` from the `BigIntData` value.
 *
 *  This method is created to make an efficient way to store `BigInt` inside
 *  local databases.
 *
 *  @param  data    Data to read new caller `BigInt`'s value from.
 */
public function FromData(BigIntData data)
{
    local int i;

    negative    = data.negative;
    digits      = data.digits;
    //  Deal with possibly erroneous data
    for (i = 0; i < digits.length; i += 1) {
        if (digits[i] > 9) {
            digits[i] = 9;
        }
    }
}

/**
 *  Converts caller `BigInt`'s value into `BigIntData`.
 *
 *  This method is created to make an efficient way to store `BigInt` inside
 *  local databases.
 *
 *  @return Value of the caller `BigInt` in the `struct` form.
 */
public function BigIntData ToData()
{
    local BigIntData result;

    result.negative = negative;
    result.digits   = digits;
    return result;
}

defaultproperties
{
}