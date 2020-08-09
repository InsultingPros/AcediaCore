/**
 *  Set of tests for `APlayer` and related classes.
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
class TEST_Player extends TestCase
    abstract;

protected static function TESTS()
{
    Test_PlayerID();
}


protected static function Test_PlayerID()
{
    local APlayerID.SteamData   steamData;
    local APlayerID             testID, testID2, testID3;
    testID = APlayerID(_().memory.Allocate(class'APlayerID'));
    Context("Testing Acedia's player ID (`APlayerID`).");
    Issue("`APlayerID` initialization works incorrectly.");
    TEST_ExpectFalse(testID.IsInitialized());
    TEST_ExpectTrue(testID.Initialize("76561198025127722"));
    TEST_ExpectTrue(testID.IsInitialized());
    TEST_ExpectFalse(testID.Initialize("76561198044316328"));

    Issue("`APlayerID` incorrectly handles SteamID.");
    TEST_ExpectTrue(testID.GetUniqueID() == "76561198025127722");
    TEST_ExpectTrue(testID.GetSteamID() == "STEAM_1:0:32430997");
    TEST_ExpectTrue(testID.GetSteamID3() == "U:1:64861994");
    TEST_ExpectTrue(testID.GetSteamID32() == 64861994);
    TEST_ExpectTrue(testID.GetSteamID64() == "76561198025127722");

    Issue("Two `APlayerID` equality check is incorrect.");
    testID2 = APlayerID(_().memory.Allocate(class'APlayerID'));
    testID3 = APlayerID(_().memory.Allocate(class'APlayerID'));
    testID2.Initialize("76561198025127722");
    testID3.Initialize("76561198044316328");
    TEST_ExpectTrue(testID.IsEqual(testID2));
    TEST_ExpectTrue(testID.IsEqualToSteamData(testID2.GetSteamData()));
    TEST_ExpectFalse(testID3.IsEqual(testID));

    Issue("Steam data returned by `APlayerID` is incorrect.");
    steamData = testID3.GetSteamData();
    TEST_ExpectTrue(steamData.accountType == 1);
    TEST_ExpectTrue(steamData.universe == 1);
    TEST_ExpectTrue(steamData.instance == 1);
    TEST_ExpectTrue(steamData.steamID32 == 84050600);
    TEST_ExpectTrue(steamData.steamID64 == "76561198044316328");
}

defaultproperties
{
    caseName = "Player"
}