/**
 *      Acedia's class for storing player's ID.
 *      This class is inherently linked to steam and it's SteamIDs, since
 *  Killing Floor 1 is all but guaranteed to be steam-exclusive.
 *  Still, if you wish to use it in a portable manner, limit yourself to
 *  `Initialize()`, `IsInitialized()`, `IsEqual()` and `GetUniqueID()`.
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
class APlayerID extends AcediaObject;

/**
 *  Stead data corresponding to a SteamID that relevant `APlayerID` was
 *  initialized with.
 *
 *  For more info read: https://developer.valvesoftware.com/wiki/SteamID
 */
struct SteamData
{
    var public byte accountType;
    var public byte universe;
    var public int  instance;
    //  32 lowest bits of SteadID64.
    //  Corresponds to a combination of "Y" and "Z" in "STEAM_X:Y:Z".
    var public int  steamID32;
    //  Other 4 fields fully define a SteamID and `steamID64` can be generated
    //  from them, but it is easier to simply cache it in a separate variable.
    var string      steamID64;
};
var protected SteamData initializedData;
//  To make it safe to pass `APlayerID` to users, prevent any modifications
//  after `initialized` is set to `true`.
var protected bool      initialized;

//  Given a number in form of array (`digits`) of it's digits
//  (425327 <-> [4, 2, 5, 3, 2, 7])
//  return given number mod 2 and
//  divide that number by two (record result in that same array)
private final function int DivideDigitArrayByTwo(out array<int> digits)
{
    local int i;
    local int wasOdd;
    if (digits[digits.length - 1] % 2 == 1)
    {
        wasOdd = 1;
        digits[digits.length - 1] -= 1;
    }
    for (i = digits.length - 1; i >= 0; i -= 1)
    {
        if (digits[i] % 2 == 1) 
        {
            digits[i] -= 1;
            //  `digits[digits.length - 1]` was guaranteed to be even before
            //  this cycle, so it is safe to add 1 to the index here
            digits[i + 1] += 5;
        }
        digits[i] = digits[i] / 2;
    }
    return wasOdd;
}

//  Given a number in form of array (`digits`) of it's digits
//  (425327 <-> [4, 2, 5, 3, 2, 7])
//  extracts `bitsToRead` of lower bits from it and returns them as an `int`.
private final function int ReadBitsFromDigitArray(
    out array<int>  digits,
    int             bitsToRead)
{
    local int i;
    local int result;
    local int binaryPadding;
    result          = 0;
    binaryPadding   = 1;
    for (i = 0; i < bitsToRead; i += 1) {
        result += DivideDigitArrayByTwo(digits) * binaryPadding;
        binaryPadding *= 2;
    }
    return result;
}

//  Explanation of what that is:
//  https://developer.valvesoftware.com/wiki/SteamID#Types_of_Steam_Accounts
private final function string GetSteamAccountTypeCharacter()
{
    //  Individual
    if (initializedData.accountType == 1)   return "U";
    //  Multiseat
    if (initializedData.accountType == 2)   return "M";
    //  GameServer
    if (initializedData.accountType == 3)   return "G";
    //  AnonGameServer
    if (initializedData.accountType == 4)   return "A";
    //  Pending
    if (initializedData.accountType == 5)   return "P";
    //  ContentServer
    if (initializedData.accountType == 6)   return "C";
    //  Clan
    if (initializedData.accountType == 7)   return "g";
    //  Chat
    if (initializedData.accountType == 8)   return "c";
    //  P2P SuperSeeder
    if (initializedData.accountType == 9)   return "";
    //  AnonUser
    if (initializedData.accountType == 10)  return "a";
    //  Invalid
    return "I";
}

/**
 *  Initializes caller `APlayerID` from a given `string` ID.
 *
 *  Each `APLayerID` can only be initialized once and becomes immutable
 *  afterwards.
 *
 *  @param  steamID64   `string` with unique ID, provided by the game
 *      (Steam64 ID used in profile permalink,
 *      like http://steamcommunity.com/profiles/76561198025127722)
 *
 *  @return `true` if initialization was successful and `false` otherwise
 *      (can only happen if caller `APlayerID` was already initialized).
 */
public final function bool Initialize(string steamID64)
{
    local int                   i;
    local array<Text.Character> characters;
    local array<int>            digits;
    if (initialized) return false;

    characters = _().text.StringToRaw(steamID64);
    for (i = 0; i < characters.length; i += 1) {
        digits[digits.length] = _().text.CharacterToInt(characters[i]);
    }
    initializedData.steamID64 = steamID64;
    //  Refer to https://developer.valvesoftware.com/wiki/SteamID
    //  The lowest bit represents Y.
    //  The next 31 bits represents the account number.
    //      ^ these two can be combined into a "SteamID32".
    initializedData.steamID32   = ReadBitsFromDigitArray(digits, 32);
    //  The next 20 bits represents the instance of the account.
    initializedData.instance    = ReadBitsFromDigitArray(digits, 20);
    //  The next 4 bits represents the type of account.
    initializedData.accountType = ReadBitsFromDigitArray(digits, 4);
    //  The next 8 bits represents the "Universe" the steam account belongs to.
    initializedData.universe    = ReadBitsFromDigitArray(digits, 8);
    initialized = true;
    return true;
}

/**
 *  Checks if caller `APlayerID` was already initialized
 *  (and is, therefore, immutable).
 *
 *  @return `true` if it was initialized and `false` otherwise.
 */
public final function bool IsInitialized()
{
    return initialized;
}

/**
 *  Returns steam data (see `APlayerID.SteamData`) of the caller `APlayerData`.
 *
 *  Only returns a valid value if caller `APLayerData` was already initialized.
 *
 *  @return `APlayerID.SteamData` of a caller `APlayerID`;
 *      structure will be filled with default values if caller `APlayerID`
 *      was not initialized.
 */
public final function SteamData GetSteamData()
{
    return initializedData;
}

/**
 *  Checks if two `APlayerID`s are the same.
 *
 *  @param  otherID `APlayerID` to compare caller object to.
 *  @return `true` if caller `APlayerID` is identical to `otherID` and
 *      `false` otherwise. If at least one of the `APlayerID`s being compared is
 *      uninitialized, the result will be `false`.
 */
public final function bool IsEqual(APlayerID otherID)
{
    if (!IsInitialized())           return false;
    if (!otherID.IsInitialized())   return false;
    return (initializedData.steamID32 == otherID.initializedData.steamID32);
}

/**
 *  Returns unique string representation of the caller `APlayerData`.
 *
 *  Only returns a valid value if caller `APLayerData` was already initialized.
 *
 *  @return Unique string representation of the caller `APlayerData`
 *      if it was initialized and `false` otherwise.
 */
public final function string GetUniqueID()
{
    if (!IsInitialized()) return "";
    return initializedData.steamID64;
}

/**
 *  Returns string representation of the caller `APlayerData` in
 *  following format: "STEAM_X:Y:Z".
 *
 *  Only returns a valid value if caller `APLayerData` was already initialized.
 *
 *  @return String representation of the caller `APlayerData` in
 *      form "STEAM_X:Y:Z" if it was initialized and empty `string` otherwise.
 */
public final function string GetSteamID()
{
    local int Y, Z;
    Y = 0;
    Z = initializedData.steamID32;
    if (Z % 2 == 1)
    {
        Y = 1;
        Z -= 1;
    }
    Z = Z / 2;
    return ("STEAM_" $ initializedData.universe $ ":" $ Y $ ":" $ Z);
}

/**
 *      Returns string representation of the caller `APlayerData` in
 *  following format: "C:U:A", where
 *      C is character representation of Account Type;
 *      U is "Universe" steam account belongs to;
 *      A is account ID.
 *
 *  Only returns a valid value if caller `APLayerData` was already initialized.
 *
 *  @return String representation of the caller `APlayerData` in
 *      form "C:U:A" if it was initialized and empty `string` otherwise.
 */
public final function string GetSteamID3()
{
    return (GetSteamAccountTypeCharacter()
        $ ":" $ initializedData.universe
        $ ":" $ initializedData.steamID32);
}

/**
 *  Returns Steam32 ID for the caller `APlayerData`. It is a lowest 32 bits of
 *  the full Steam64 ID.
 *
 *  Only returns a valid value if caller `APLayerData` was already initialized.
 *
 *  @return Unique `int` representation of the caller `APlayerData`
 *      if it was initialized and `-1` otherwise.
 */
public final function int GetSteamID32()
{
    if (!IsInitialized()) return -1;
    return initializedData.steamID32;
}

/**
 *  Returns Steam64 ID for the caller `APlayerData`.
 *
 *  Only returns a valid value if caller `APLayerData` was already initialized.
 *
 *  Since UnrealEngine 2 does not support 64-bit integer values, it is returned
 *  simply as a decimal representation of a whole Steam64 ID
 *  (Steam64 ID used in profile permalink,
 *  like http://steamcommunity.com/profiles/76561198025127722).
 *
 *  @return String representation of the Steam64 ID of the caller `APlayerData`
 *      if it was initialized and empty `string` otherwise.
 */
public final function string GetSteamID64()
{
    if (!IsInitialized()) return "";
    return initializedData.steamID64;
}

defaultproperties
{
}