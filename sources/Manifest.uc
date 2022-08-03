/**
 *      Manifest is meant to describe contents of the Acedia's package.
 *      Copyright 2020-2022 Anton Tarasenko
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
    features(0)     = class'Aliases_Feature'
    features(1)     = class'Commands_Feature'
    features(2)     = class'Avarice_Feature'
    testCases(0)    = class'TEST_Base'
    testCases(1)    = class'TEST_ActorService'
    testCases(2)    = class'TEST_Boxes'
    testCases(3)    = class'TEST_Refs'
    testCases(4)    = class'TEST_SignalsSlots'
    testCases(5)    = class'TEST_ServerUnrealAPI'
    testCases(6)    = class'TEST_Aliases'
    testCases(7)    = class'TEST_ColorAPI'
    testCases(8)    = class'TEST_Text'
    testCases(9)    = class'TEST_TextAPI'
    testCases(10)   = class'TEST_Parser'
    testCases(11)   = class'TEST_JSON'
    testCases(12)   = class'TEST_TextCache'
    testCases(13)   = class'TEST_FormattedStrings'
    testCases(14)   = class'TEST_TextTemplate'
    testCases(15)   = class'TEST_User'
    testCases(16)   = class'TEST_Memory'
    testCases(17)   = class'TEST_ArrayList'
    testCases(18)   = class'TEST_HashTable'
    testCases(19)   = class'TEST_CollectionsMixed'
    testCases(20)   = class'TEST_Iterator'
    testCases(21)   = class'TEST_Command'
    testCases(22)   = class'TEST_CommandDataBuilder'
    testCases(23)   = class'TEST_LogMessage'
    testCases(24)   = class'TEST_SchedulerAPI'
    testCases(25)   = class'TEST_BigInt'
    testCases(26)   = class'TEST_DatabaseCommon'
    testCases(27)   = class'TEST_LocalDatabase'
    testCases(28)   = class'TEST_AcediaConfig'
    testCases(29)   = class'TEST_UTF8EncoderDecoder'
    testCases(30)   = class'TEST_AvariceStreamReader'
}