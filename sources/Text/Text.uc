/**
 *      Acedia's type for an immutable text (string) object.
 *  Since it is not native type, it has additional costs for it's creation and
 *  some of it operations, but it:
 *      1.  Supports a more convenient (than native 4-byte color sequences)
 *          storing of format information and allows to extract `string`s with
 *          or without formatting. Including Acedia's own, more human-readable
 *          way to define string formatting.
 *      2.  Stores `string`s disassembled into Unicode code points, potentially
 *          allowing fast implementation of operations that require such
 *          a representation (e.g. faster hash calculation was implemented).
 *      3.  Provides an additional layer of abstraction that can potentially
 *          allow for an improved Unicode support.
 *      Copyright 2020 - 2022 Anton Tarasenko
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
class Text extends BaseText;

public function Text IntoText()
{
    return self;
}

public function MutableText IntoMutableText()
{
    local MutableText mutableVersion;
    mutableVersion = MutableCopy();
    FreeSelf();
    return mutableVersion;
}

defaultproperties
{
}