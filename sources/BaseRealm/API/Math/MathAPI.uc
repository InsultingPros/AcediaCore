/**
 *  API that provides a collection of non-built in math methods used in Acedia.
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
class MathAPI extends AcediaObject;

/**
 *  For storing result of integer division.
 *
 *  If we divide `number` by `divisor`, then
 *  `number = divisor * quotient + remainder`
 */
struct IntegerDivisionResult
{
    var int quotient;
    var int remainder;
};

/**
 *  Changes current value of `BigInt` to given `BigInt` value.
 *
 *  @param  value   New value of the caller `BigInt`. If `none` is given,
 *      method does nothing.
 *  @return Self-reference to allow for method chaining.
 */
public function BigInt ToBigInt(int value)
{
    local BigInt result;

    result = BigInt(_.memory.Allocate(class'BigInt'));
    return result.SetInt(value);
}

/**
 *  Creates new `BigInt` value, base on the decimal representation given by
 *  `value`.
 *
 *  If invalid decimal representation (digits only, possibly with leading sign)
 *  is given - contents of returned value are undefined. Otherwise cannot fail.
 *
 *  @param  value   New value of the caller `BigInt`, given by decimal
 *      its representation. If `none` is given, method returns `BigInt`
 *      containing `0` as value.
 *  @return Created `BigInt`, containing value, given by its the decimal
 *      representation `value`.
 */
public function BigInt MakeBigInt(BaseText value)
{
    local BigInt result;

    result = BigInt(_.memory.Allocate(class'BigInt'));
    return result.SetDecimal(value);
}

/**
 *  Creates new `BigInt` value, base on the decimal representation given by
 *  `value`.
 *
 *  If invalid decimal representation (digits only, possibly with leading sign)
 *  is given - contents of returned value are undefined. Otherwise cannot fail.
 *
 *  @param  value   New value of the caller `BigInt`, given by decimal
 *      its representation.
 *  @return Created `BigInt`, containing value, given by its the decimal
 *      representation `value`.
 */
public function BigInt MakeBigInt_S(string value)
{
    local BigInt result;

    result = BigInt(_.memory.Allocate(class'BigInt'));
    return result.SetDecimal_S(value);
}

/**
 *  Computes remainder of the integer division of `number` by `divisor`.
 *
 *  This method is necessary as a replacement for `%` module operator, since it
 *  is an operation on `float`s in UnrealScript and does not have appropriate
 *  value range to work with big integer values.
 *
 *  @see `IntegerDivision()` method if you need both quotient and remainder.
 *
 *  @param  number  Number that we are dividing.
 *  @param  divisor Number we are dividing by.
 *  @return Remainder of the integer division.
 */
public function int Remainder(int number, int divisor)
{
    local int quotient;

    quotient = number / divisor;
    return (number - quotient * divisor);
}

/**
 *  Computes quotient and remainder of the integer division of `number` by
 *  `divisor`.
 *
 *  @see `IntegerDivision()` method if you only need remainder.
 *  @param  number  Number that we are dividing.
 *  @param  divisor Number we are dividing by.
 *  @return `struct` with quotient and remainder of the integer division.
 */
public function IntegerDivisionResult IntegerDivision(int number, int divisor)
{
    local IntegerDivisionResult result;

    result.quotient     = number / divisor;
    result.remainder    = (number - result.quotient * divisor);
    return result;
}

defaultproperties
{
}