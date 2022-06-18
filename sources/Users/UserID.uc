/**
 *      Acedia's class for storing user's ID.
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
class UserID extends AcediaObject;

/**
 *  Stead data corresponding to a SteamID that relevant `UserID` was
 *  initialized with.
 *
 *  For more info read: https://developer.valvesoftware.com/wiki/SteamID
 */
struct SteamID
{
    var public byte accountType;
    var public byte universe;
    var public int  instance;
    //  32 lowest bits of SteadID64.
    //  Corresponds to a combination of "Y" and "Z" in "STEAM_X:Y:Z".
    var public int  steamID32;
    //      Other 4 fields fully define a SteamID and `steamID64` can be
    //  generated from them, but it is easier to simply cache it in
    //  a separate variable.
    //      `SteamID` is considered valid iff `steamID64` is equal to
    //  Steam64 ID that can be generated from other variables.
    var Text        steamID64;
};
var protected SteamID   initializedData;
//  To make it safe to pass `UserID` to users, prevent any modifications
//  after `initialized` is set to `true`.
var protected bool      initialized;

//  Given a number in form of array (`digits`) of it's digits
//  (425327 <-> [4, 2, 5, 3, 2, 7])
//  return given number mod 2 and
//  divide that number by two (record result in that same array)
private static final function int DivideDigitArrayByTwo(out array<int> digits)
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
private static final function int ReadBitsFromDigitArray(
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
 *  Helper function that generates `SteamID` structure from
 *  a given Steam64 ID.
 *
 *  In case invalid ID is given this method will not raise any warning and
 *  returned value should be considered undefined.
 *
 *  @param  steamID64   Steam64 ID's decimal representation.
 *  @return `SteamID` generated from a given Steam64 ID `steamID64`.
 */
public static final function SteamID GetSteamIDFromIDHash(BaseText steamID64)
{
    local int           i;
    local SteamID       newSteamID;
    local array<int>    digits;
    if (steamID64 == none) return newSteamID;

    for (i = 0; i < steamID64.GetLength(); i += 1)
    {
        digits[digits.length] =
            __().text.CharacterToInt(steamID64.GetCharacter(i));
    }
    newSteamID.steamID64 = steamID64.Copy();
    //  Refer to https://developer.valvesoftware.com/wiki/SteamID
    //  The lowest bit represents Y.
    //  The next 31 bits represents the account number.
    //      ^ these two can be combined into a "SteamID32".
    newSteamID.steamID32    = ReadBitsFromDigitArray(digits, 32);
    //  The next 20 bits represents the instance of the account.
    newSteamID.instance     = ReadBitsFromDigitArray(digits, 20);
    //  The next 4 bits represents the type of account.
    newSteamID.accountType  = ReadBitsFromDigitArray(digits, 4);
    //  The next 8 bits represents the "Universe" the steam account belongs to.
    newSteamID.universe     = ReadBitsFromDigitArray(digits, 8);
    return newSteamID;
}

/**
 *  Initializes caller `UserID` from an ID given as `Text`.
 *
 *  Each `UserID` can only be initialized once and becomes immutable
 *  afterwards.
 *
 *  @param  steamID64   `Text` with unique ID, provided by the game
 *      (Steam64 ID used in profile permalink,
 *      like http://steamcommunity.com/profiles/76561198025127722)
 *
 *  @return `true` if initialization was successful and `false` otherwise
 *      (can happen if caller `UserID` was already initialized
 *      or `steamID64 == none`).
 */
public final function bool Initialize(BaseText steamID64)
{
    if (initialized)        return false;
    if (steamID64 == none)  return false;

    initializedData = GetSteamIDFromIDHash(steamID64);
    initialized     = true;
    return true;
}

/**
 *  Initializes caller `UserID` from a given `SteamID` structure.
 *
 *  Each `UserID` can only be initialized once and becomes immutable
 *  afterwards.
 *
 *  @param  steamID Valid `SteamID` structure that caller `UserID` will
 *      represent. Deallocation of any objects in passed `steamID` will be
 *      managed by the caller `UserID`.
 *  @return `true` if initialization was successful and `false` otherwise
 *      (can only happen if caller `UserID` was already initialized).
 */
public final function bool InitializeWithSteamID(SteamID steamID)
{
    if (initialized) return false;
    initializedData = steamID;
    initialized     = true;
    return true;
}

/**
 *  Checks if caller `UserID` was already initialized
 *  (and is, therefore, immutable).
 *
 *  @return `true` if it was initialized and `false` otherwise.
 */
public final function bool IsInitialized()
{
    return initialized;
}

/**
 *  Returns steam data (see `UserID.SteamID`) of the caller `UserID`.
 *
 *  Only returns a valid value if caller `UserID` was already initialized.
 *
 *  @return `UserID.SteamID` of a caller `UserID`;
 *      structure will be filled with default values if caller `UserID`
 *      was not initialized. Any objects contained in returned structure
 *      (`steamID64`) would not be managed by the caller `UserID` and should be
 *      manually deallocated.
 */
public final function SteamID GetSteamID()
{
    local SteamID steamIDCopy;
    if (steamIDCopy.steamID64 == none) {
        return initializedData;
    }
    steamIDCopy = initializedData;
    steamIDCopy.steamID64 = steamIDCopy.steamID64.Copy();
    return initializedData;
}

/**
 *  Checks if two `UserID`s are the same.
 *
 *  @param  otherID `UserID` to compare caller object to.
 *  @return `true` if caller `UserID` is identical to `otherID` and
 *      `false` otherwise. If at least one of the `UserID`s being compared is
 *      uninitialized, the result will be `false`.
 */
public final function bool IsEqualTo(UserID otherID)
{
    if (!IsInitialized())           return false;
    if (!otherID.IsInitialized())   return false;
    return (initializedData.steamID32 == otherID.initializedData.steamID32);
}

/**
 *  Checks if caller `UserID`s is the same as what's described by
 *  given `SteamID`.
 *
 *  NOTE: only part of the `otherSteamID` might be used for comparison.
 *  It is up to user to ensure that given `otherSteamID` is valid.
 *
 *  @param  otherSteamID  `SteamID` to compare caller `UserID` to.
 *  @return `true` if caller `UserID` is identical to ID described by
 *      `otherSteamID` and `false` otherwise.
 *      If caller `UserID` is uninitialized, the result will be `false`.
 */
public final function bool IsEqualToSteamID(SteamID otherSteamID)
{
    if (!IsInitialized()) {
        return false;
    }
    return (initializedData.steamID32 == otherSteamID.steamID32);
}

/**
 *  Returns unique `Text` representation of the caller `UserID`.
 *
 *  Only returns a valid value if caller `UserID` was already initialized.
 *
 *  @return Unique `Text` representation of the caller `UserID`
 *      if it was initialized and `none` otherwise. Returned object isn't
 *      managed by caller `UserID` and must be deallocated.
 */
public final function Text GetUniqueID()
{
    return GetSteamID64String();
}

/**
 *  Returns `Text` representation of the caller `UserID` in following format:
 *  "STEAM_X:Y:Z".
 *
 *  Only returns a valid value if caller `UserID` was already initialized.
 *
 *  @return `Text` representation of the caller `UserID` in
 *      form "STEAM_X:Y:Z" if it was initialized and `none` otherwise.
 *      Returned object is not managed by the caller `UserID` and should be
 *      manually deallocated.
 */
public final function Text GetSteamIDString()
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
    return _.text.FromString("STEAM_" $ initializedData.universe
        $ ":" $ Y $ ":" $ Z);
}

/**
 *      Returns `Text` representation of the caller `UserID` in
 *  following format: "C:U:A", where
 *      C is character representation of Account Type;
 *      U is "Universe" steam account belongs to;
 *      A is account ID.
 *
 *  Only returns a valid value if caller `UserID` was already initialized.
 *
 *  @return `Text` representation of the caller `UserID` in
 *      form "C:U:A" if it was initialized and `none` otherwise. Returned object
 *      is not managed by the caller `UserID` and should be
 *      manually deallocated.
 */
public final function Text GetSteamID3String()
{
    return _.text.FromString(GetSteamAccountTypeCharacter()
        $ ":" $ initializedData.universe
        $ ":" $ initializedData.steamID32);
}

/**
 *  Returns Steam32 ID for the caller `UserID`. It is a lowest 32 bits of
 *  the full Steam64 ID.
 *
 *  Only returns a valid value if caller `UserID` was already initialized.
 *
 *  @return Unique `int` representation of the caller `UserID`
 *      if it was initialized and `-1` otherwise.
 */
public final function int GetSteamID32()
{
    if (!IsInitialized()) return -1;
    return initializedData.steamID32;
}

/**
 *  Returns Steam64 ID for the caller `UserID`.
 *
 *  Only returns a valid value if caller `UserID` was already initialized.
 *
 *  Since UnrealEngine 2 does not support 64-bit integer values, it is returned
 *  simply as a decimal representation of a whole Steam64 ID
 *  (Steam64 ID used in profile permalink,
 *  like http://steamcommunity.com/profiles/76561198025127722).
 *
 *  @return `Text` representation of the Steam64 ID of the caller `UserID`
 *      if it was initialized and `none` otherwise. Returned object isn't
 *      managed by caller `UserID` and must be deallocated.
 */
public final function Text GetSteamID64String()
{
    if (!IsInitialized())                   return none;
    if (initializedData.steamID64 == none)  return none;
    return initializedData.steamID64.Copy();
}

defaultproperties
{
}