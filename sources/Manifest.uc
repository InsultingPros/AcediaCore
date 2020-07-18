/**
 *      Manifest is meant to describe contents of the Acedia's package.
 *      Copyright 2020 Anton Tarasenko
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
 class Manifest extends _manifest
    abstract;

defaultproperties
{
    aliasSources(0) = class'AliasSource'
    aliasSources(1) = class'WeaponAliasSource'
    aliasSources(2) = class'ColorAliasSource'
    testCases(0) = class'TEST_Aliases'
    testCases(1) = class'TEST_ColorAPI'
    testCases(2) = class'TEST_JSON'
    testCases(3) = class'TEST_Text'
    testCases(4) = class'TEST_TextAPI'
    testCases(5) = class'TEST_Parser'
}