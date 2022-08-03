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

protected function Constructor()
{
    //  Init with zero
    digits[0] = 0;
}

protected function Finalizer()
{
    negative = false;
    digits.length = 0;
}

//  Minimal `int` value `-2,147,483,648` is slightly a pain to handle, so just
//  use this pre-made constructor for it
private static function BigInt CreateMinimalNegative()
{
    local array<byte>   newDigits;
    local BigInt        result;
    newDigits[0] = 8;
    newDigits[1] = 4;
    newDigits[2] = 6;
    newDigits[3] = 3;
    newDigits[4] = 8;
    newDigits[5] = 4;
    newDigits[6] = 7;
    newDigits[7] = 4;
    newDigits[8] = 1;
    newDigits[9] = 2;
    result = BigInt(__().memory.Allocate(class'BigInt'));
    result.digits   = newDigits;
    result.negative = true;
    return result;
}

//  Removes unnecessary zeroes from leading digit positions `digits`.
//  Does not change contained value.
private final static function TrimLeadingZeroes()
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
    if (zeroesToRemove  >= digits.length)
    {
        digits.length = 1;
        digits[0] = 0;
        negative = false;
    }
    else {
        digits.length = digits.length - zeroesToRemove;
    }
}

public final static function BigInt FromInt(int value)
{
    local bool                          valueIsNegative;
    local array<byte>                   newDigits;
    local BigInt                        result;
    local MathAPI.IntegerDivisionResult divisionResult;

    if (value < 0)
    {
        //  Treat special case of minimal `int` value `-2,147,483,648` that
        //  won't fit into positive `int` as special and use pre-made
        //  specialized constructor `CreateMinimalNegative()`
        if (value < -MaxInt) {
            return CreateMinimalNegative();
        }
        else
        {
            valueIsNegative = true;
            value *= -1;
        }
    }
    if (value == 0) {
        newDigits[0] = 0;
    }
    else
    {
        while (value > 0)
        {
            divisionResult = __().math.IntegerDivision(value, 10);
            value                       = divisionResult.quotient;
            newDigits[newDigits.length] = divisionResult.remainder;
        }
    }
    result = BigInt(__().memory.Allocate(class'BigInt'));
    result.digits   = newDigits;
    result.negative = valueIsNegative;
    result.TrimLeadingZeroes();
    return result;
}

public final static function BigInt FromDecimal(BaseText value)
{
    local int                   i;
    local bool                  valueIsNegative;
    local byte                  nextDigit;
    local array<byte>           newDigits;
    local Parser                parser;
    local BigInt                result;
    local Basetext.Character    nextCharacter;

    if (value == none) {
        return none;
    }
    parser = value.Parse();
    if (parser.Match(P("-")).Ok())
    {
        valueIsNegative = true;
        parser.Confirm();
    }
    parser.R();
    newDigits.length = parser.GetRemainingLength();
    i = newDigits.length - 1;
    while (!parser.HasFinished())
    {
        //  This should not happen, but just in case
        if (i < 0) {
            break;
        }
        parser.MCharacter(nextCharacter);
        nextDigit = Clamp(__().text.CharacterToInt(nextCharacter), 0, 9);
        newDigits[i] = nextDigit;
        i -= 1;
    }
    result = BigInt(__().memory.Allocate(class'BigInt'));
    result.digits   = newDigits;
    result.negative = valueIsNegative;
    parser.FreeSelf();
    result.TrimLeadingZeroes();
    return result;
}

public final static function BigInt FromDecimal_S(string value)
{
    local MutableText   wrapper;
    local BigInt        result;

    wrapper = __().text.FromStringM(value);
    result = FromDecimal(wrapper);
    wrapper.FreeSelf();
    return result;
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
}

public function BigInt Add(BigInt other)
{
    _add(other);
    return self;
}

public function BigInt AddInt(int other)
{
    local BigInt otherObject;

    otherObject = FromInt(other);
    Add(otherObject);
    _.memory.Free(otherObject);
    return self;
}

/*public function BigInt Multiply(BigInt other);
public function BigInt MultiplyInt(int other);

public function bool IsNegative();
public function (int other);

public function int ToInt();

public function Text ToText();

public function Text ToText_M();*/

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