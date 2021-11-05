/**
 *  Set of tests for `User` and related classes.
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
class TEST_User extends TestCase
    dependson(UserID)
    abstract;

protected static function TESTS()
{
    Test_UserID();
}


protected static function Test_UserID()
{
    local UserID.SteamID    SteamID;
    local UserID            testID, testID2, testID3;
    testID = UserID(__().memory.Allocate(class'UserID'));
    Context("Testing Acedia's player ID (`UserID`).");
    Issue("`UserID` initialization works incorrectly.");
    TEST_ExpectFalse(testID.IsInitialized());
    TEST_ExpectTrue(testID.Initialize(P("76561198025127722")));
    TEST_ExpectTrue(testID.IsInitialized());
    TEST_ExpectFalse(testID.Initialize(P("76561198044316328")));

    Issue("`UserID` incorrectly handles SteamID.");
    TEST_ExpectTrue(    testID.GetUniqueID().ToString()
                    ==  "76561198025127722");
    TEST_ExpectTrue(    testID.GetSteamIDString().ToString()
                    ==  "STEAM_1:0:32430997");
    TEST_ExpectTrue(    testID.GetSteamID3String().ToString()
                    ==  "U:1:64861994");
    TEST_ExpectTrue(testID.GetSteamID32() == 64861994);
    TEST_ExpectTrue(    testID.GetSteamID64String().ToString()
                    ==  "76561198025127722");

    Issue("Two `UserID` equality check is incorrect.");
    testID2 = UserID(__().memory.Allocate(class'UserID'));
    testID3 = UserID(__().memory.Allocate(class'UserID'));
    testID2.Initialize(P("76561198025127722"));
    testID3.Initialize(P("76561198044316328"));
    TEST_ExpectTrue(testID.IsEqualTo(testID2));
    TEST_ExpectTrue(testID.IsEqualToSteamID(testID2.GetSteamID()));
    TEST_ExpectFalse(testID3.IsEqualTo(testID));

    Issue("Steam data returned by `UserID` is incorrect.");
    SteamID = testID3.GetSteamID();
    TEST_ExpectTrue(SteamID.accountType == 1);
    TEST_ExpectTrue(SteamID.universe == 1);
    TEST_ExpectTrue(SteamID.instance == 1);
    TEST_ExpectTrue(SteamID.steamID32 == 84050600);
    TEST_ExpectTrue(SteamID.steamID64.ToString() == "76561198044316328");
}

defaultproperties
{
    caseName = "User"
}