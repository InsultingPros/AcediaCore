/**
 *  Set of tests for `DBRecord` class.
 *      Copyright 2021 Anton Tarasenko
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
class TEST_DatabaseCommon extends TestCase
    abstract;

protected static function TESTS()
{
    local JSONPointer pointer;
    Context("Testing extracting `JSONPointer` from database link.");
    Issue("`JSONPointer` is incorrectly extracted.");
    pointer = __().db.GetPointer(
        __().text.FromString("[local]default:/huh/what/is/"));
    TEST_ExpectNotNone(pointer);
    TEST_ExpectTrue(pointer.ToText().ToString() == "/huh/what/is/");
    pointer = __().db.GetPointer(__().text.FromString("[remote]db:"));
    TEST_ExpectNotNone(pointer);
    TEST_ExpectTrue(pointer.ToText().ToString() == "");
    pointer = __().db.GetPointer(__().text.FromString("[remote]:"));
    TEST_ExpectNotNone(pointer);
    TEST_ExpectTrue(pointer.ToText().ToString() == "");
    pointer = __().db.GetPointer(__().text.FromString("db:/just/a/pointer"));
    TEST_ExpectNotNone(pointer);
    TEST_ExpectTrue(pointer.ToText().ToString() == "/just/a/pointer");
    pointer = __().db.GetPointer(__().text.FromString(":/just/a/pointer"));
    TEST_ExpectNotNone(pointer);
    TEST_ExpectTrue(pointer.ToText().ToString() == "/just/a/pointer");
}

defaultproperties
{
    caseGroup   = "Database"
    caseName    = "Common database tests"
}