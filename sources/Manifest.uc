/**
 *      Manifest is meant to describe contents of the Acedia's package.
 *      Copyright 2020 - 2021 Anton Tarasenko
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
    features(0)     = class'Commands_Feature'
    features(1)     = class'Avarice_Feature'
    commands(0)     = class'ACommandHelp'
    commands(1)     = class'ACommandDosh'
    commands(2)     = class'ACommandNick'
    commands(3)     = class'ACommandTrader'
    services(0)     = class'ConnectionService'
    services(1)     = class'PlayerService'
    aliasSources(0) = class'AliasSource'
    aliasSources(1) = class'WeaponAliasSource'
    aliasSources(2) = class'ColorAliasSource'
    testCases(0)    = class'TEST_Base'
    testCases(1)    = class'TEST_ActorService'
    testCases(2)    = class'TEST_Boxes'
    testCases(3)    = class'TEST_Refs'
    testCases(4)    = class'TEST_SignalsSlots'
    testCases(5)    = class'TEST_UnrealAPI'
    testCases(6)    = class'TEST_Aliases'
    testCases(7)    = class'TEST_ColorAPI'
    testCases(8)    = class'TEST_Text'
    testCases(9)    = class'TEST_TextAPI'
    testCases(10)   = class'TEST_Parser'
    testCases(11)   = class'TEST_JSON'
    testCases(12)   = class'TEST_TextCache'
    testCases(13)   = class'TEST_User'
    testCases(14)   = class'TEST_Memory'
    testCases(15)   = class'TEST_DynamicArray'
    testCases(16)   = class'TEST_AssociativeArray'
    testCases(17)   = class'TEST_CollectionsMixed'
    testCases(18)   = class'TEST_Iterator'
    testCases(19)   = class'TEST_Command'
    testCases(20)   = class'TEST_CommandDataBuilder'
    testCases(21)   = class'TEST_LogMessage'
    testCases(22)   = class'TEST_DatabaseCommon'
    testCases(23)   = class'TEST_LocalDatabase'
    testCases(24)   = class'TEST_AcediaConfig'
    testCases(25)   = class'TEST_UTF8EncoderDecoder'
    testCases(26)   = class'TEST_AvariceStreamReader'
}