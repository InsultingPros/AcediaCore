/**
 *  A simply big integer implementation, mostly to allow Acedia's databases to
 *  store integers of arbitrary size. Should not be used in regular
 *  computations, designed to store player statistic values that are incremented
 *  from time to time.
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

enum BigIntCompareResult
{
    BICR_Less,
    BICR_Equal,
    BICR_Greater
};

var private bool negative;
//  Digits array, from least to most significant:
//  For example, for 13524:
//  `digits[0] = 4`
//  `digits[1] = 2`
//  `digits[2] = 5`
//  `digits[3] = 3`
//  `digits[4] = 1`
//  Valid `BigInt` should not have this array empty.
var private array<byte> digits;

private const ALMOST_MAX_INT    = 147483647;
private const DIGITS_IN_MAX_INT = 10;

protected function Constructor()
{
    //  Init with zero
    SetZero();
}

protected function Finalizer()
{
    negative = false;
    digits.length = 0;
}

//  ???
private function BigInt SetZero()
{
    negative = false;
    digits.length = 1;
    digits[0] = 0;
    return self;
}

//  Minimal `int` value `-2,147,483,648` is slightly a pain to handle, so just
//  use this pre-made constructor for it
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

public final function BigInt Set(BaseText value)
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
    parser.Confirm();
    parser.R();
    digits.length = parser.GetRemainingLength();
    /*if (digits.length <= 0)
    {
        parser.FreeSelf();
        return SetZero();
    }*/
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

public final function BigInt Set_S(string value)
{
    local MutableText wrapper;

    wrapper = __().text.FromStringM(value);
    Set(wrapper);
    wrapper.FreeSelf();
    return self;
}

public function BigIntCompareResult _compareModulus(BigInt other)
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

public function BigIntCompareResult Compare(BigInt other)
{
    local BigIntCompareResult resultForModulus;

    if (negative && !other.negative) {
        return BICR_Less;
    }
    if (!negative && other.negative) {
        return BICR_Greater;
    }
    resultForModulus = _compareModulus(other);
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

private function _sub(BigInt other)
{
    local int                   i;
    local int                   carry, nextDigit;
    local array<byte>           minuendDigits, subtrahendDigits;
    local BigIntCompareResult   resultForModulus;

    if (other == none) {
        return;
    }
    resultForModulus = _compareModulus(other);
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

public function BigInt Add(BigInt other)
{
    if (negative == other.negative) {
        _add(other);
    }
    else {
        _sub(other);
    }
    return self;
}

public function BigInt AddInt(int other)
{
    local BigInt otherObject;

    otherObject = _.math.ToBigInt(other);
    Add(otherObject);
    _.memory.Free(otherObject);
    return self;
}

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

public function BigInt SubtractInt(int other)
{
    local BigInt otherObject;

    otherObject = _.math.ToBigInt(other);
    Add(otherObject);
    _.memory.Free(otherObject);
    return self;
}

public function bool IsNegative()
{
    return negative;
}

public function int ToInt()
{
    local int i;
    local int accumulator;
    local int mostSignificantDigit;

    if (digits.lenght <= 0) {
        return 0;
    }
    if (digits.lenght > DIGITS_IN_MAX_INT)
    {
        if (negative) {
            return (-MaxInt - 1);
        }
        else {
            return MaxInt;
        }
    }
    mostSignificantDigit = -1;
    if (digits.lenght == DIGITS_IN_MAX_INT)
    {
        mostSignificantDigit = digits[digits.length - 1];
        digits[i] = DIGITS_IN_MAX_INT - 1;
    }
    //  At most `DIGITS_IN_MAX_INT - 1` iterations
    for (i = 0; i < digits.length; i += 1)
    {//ALMOST_MAX_INT
        accumulator *= 10;
        accumulator += digits[i];
    }
    if (mostSignificantDigit < 0) {
        return accumulator;
    }
}

public function Text ToText()
{
    return ToText_M().IntoText();
}

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

defaultproperties
{
}