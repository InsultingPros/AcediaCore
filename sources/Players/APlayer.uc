/**
 *      Represents a connected player connection and serves to provide access to
 *  both it's server data and in-game pawn representation.
 *      Unlike `User`, - changes when player reconnects to the server.
 *      This object SHOULD NOT be created manually, please rely on
 *  Acedia for that.
 *      Due to being relatively rarely created, does not use object pools,
 *  which simplifies their usage and comparison.
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
class APlayer extends AcediaObject;

//  How this `APlayer` is identified by the server
var private User identity;

//  Writer that can be used to write into this player's console
var private ConsoleWriter   consoleInstance;
//  Remember version to reallocate writer in case someone deallocates it
var private int             consoleLifeVersion;

var private NativeActorRef  controller;

//  These variables record name of this player;
//  `hashedName` is used to track outside changes that bypass our getter/setter.
var private Text    textName;
var private string  hashedName;

//  Describes the player's admin status (as defined by standard KF classes)
enum AdminStatus
{
    //  Not an admin
    AS_None,
    //  (Publicly visible) admin
    AS_Admin,
    //  Admin with their admin status hidden
    AS_SilentAdmin
};

protected function Finalizer()
{
    _.memory.Free(controller);
}

/**
 *  Returns location of the caller `APlayer`.
 *
 *  @return If caller `APlayer` has a pawn, then it's location will be returned,
 *  otherwise a location caller `APlayer` is currently spectating the map from
 *  will be returned.
 */
public final function Vector GetLocation()
{
    local Pawn              myPawn;
    local PlayerController  myController;
    myController = PlayerController(controller.Get());
    if (myController != none)
    {
        myPawn = myController.pawn;
        if (myPawn != none) {
            return myPawn.location;
        }
        return myController.location;
    }
    return Vect(0.0, 0.0, 0.0);
}

//  `PlayerReplicationInfo` associated with the caller `APLayer`.
//  Can return `none` if:
//      1. Caller `APlayer` has already disconnected;
//      2. It was not properly initialized;
//      3. There is an issue running `PlayerService`.
private final function PlayerReplicationInfo GetRI()
{
    local PlayerController myController;
    myController = PlayerController(controller.Get());
    if (myController != none) {
        return myController.playerReplicationInfo;
    }
    return none;
}

/**
 *  Checks if player, corresponding to `APlayer`, is still connected to
 *  the server. If player is disconnected - `APlayer` instance should be
 *  considered useless.
 *
 *  @return `true` if player is connected and `false` otherwise.
 */
public final function bool IsConnected()
{
    return (controller.Get() != none);
}

/**
 *  Initializes caller `APlayer`. Should be called right after `APlayer`
 *  was spawned.
 *
 *      Initialization should (and can) only be done once.
 *      Before a `Initialize()` call, any other method calls on such `User`
 *  must be considerate to have undefined behavior.
 *
 *  @param  newController   Controller that caller `APLayer` will correspond to.
 */
public final function Initialize(Text idHash)
{
    local PlayerService         service;
    local PlayerController      myController;
    local PlayerReplicationInfo myReplicationInfo;
    identity = _.users.FetchByIDHash(idHash);
    //  Retrieve controller and replication info
    service = PlayerService(class'PlayerService'.static.Require());
    myController = service.GetController(self);
    controller = _.unreal.ActorRef(myController);
    if (myController != none) {
        myReplicationInfo = myController.playerReplicationInfo;
    }
    //  Hash current name
    if (myReplicationInfo != none) {
        hashedName  = myReplicationInfo.playerName;
        textName    = _.text.FromColoredString(hashedName);
    }
}

/**
 *  Returns `User` object that is corresponding to the caller `APlayer`.
 *
 *  @return `User` corresponding to the caller `APlayer`. Guarantee to be
 *      not `none` for correctly initialized `APlayer` (it remembers `User`
 *      record even if player has disconnected).
 */
public final function User GetIdentity()
{
    return identity;
}

/**
 *  Returns current displayed name of the caller player.
 *
 *  @return `Text` containing current name of the caller player.
 *      Guaranteed to not be `none`. Returned object is not managed by caller
 *      `APlayer` and should be manually deallocated.
 */
public final function Text GetName()
{
    local PlayerReplicationInfo myReplicationInfo;
    myReplicationInfo = GetRI();
    if (myReplicationInfo == none) {
        return P("").Copy();
    }
    if (textName != none && myReplicationInfo.playerName == hashedName) {
        return textName.Copy();
    }
    _.memory.Free(textName);
    hashedName  = myReplicationInfo.playerName;
    textName    = _.text.FromColoredString(hashedName);
    return textName.Copy();
}

/**
 *  Set new displayed name for the caller `APlayer`.
 *
 *  @param  newPlayerName   New name of the caller `APlayer`. This value will
 *      be copied. Passing `none` will result in an empty name.
 */
public final function SetName(Text newPlayerName)
{
    local Text.Formatting       endingFormatting;
    local PlayerReplicationInfo myReplicationInfo;
    myReplicationInfo = GetRI();
    if (myReplicationInfo == none) return;

    _.memory.Free(textName);
    //  Filter both `none` and empty `newPlayerName`, so that we can
    //  later rely on it having at least one character
    if (newPlayerName == none || newPlayerName.IsEmpty()) {
        textName = P("").Copy();
    }
    else {
        textName = newPlayerName.Copy();
    }
    hashedName = textName.ToColoredString(,, _.color.white);
    //      To correctly display nicknames we want to drop default color tag
    //  at the beginning (the one `ToColoredString()` adds if first character
    //  has no defined color).
    //      This is a compatibility consideration with vanilla UIs that use
    //  color codes from `myReplicationInfo.playerName` for displaying nicknames
    //  and whose expected behavior can get broken by default color tag.
    if (!textName.GetFormatting(0).isColored) {
        hashedName = Mid(hashedName, 4);
    }
    //      This is another compatibility consideration with vanilla UIs: unless
    //  we restore color to neutral white, Killing Floor will paint any chat
    //  messages we send in the color our nickname ended with.
    endingFormatting = textName.GetFormatting(textName.GetLength() - 1);
    if (    endingFormatting.isColored
        &&  !_.color.AreEqual(endingFormatting.color, _.color.white, true))
    {
        hashedName $= _.color.GetColorTag(_.color.white);
    }
    myReplicationInfo.playerName = hashedName;
}

/**
 *  Returns admin status of the caller player.
 *  Disconnected players are never admins.
 *
 *  Different from `IsAdmin()` since this method allows to distinguish between
 *  different types of admin login (like silent admins).
 *
 *  @return Admin status of the caller `APLayer`.
 */
public final function AdminStatus GetAdminStatus()
{
    local PlayerReplicationInfo myReplicationInfo;
    myReplicationInfo = GetRI();
    if (myReplicationInfo == none) {
        return AS_None;
    }
    if (myReplicationInfo.bAdmin) {
        return AS_Admin;
    }
    if (myReplicationInfo.bSilentAdmin) {
        return AS_SilentAdmin;
    }
    return AS_None;
}

/**
 *  Checks if caller player has admin rights.
 *  Disconnected players never have admin rights.
 *
 *  Different from `GetAdminStatus()` since this method simply checks admin
 *  rights, without distinguishing between different types of admin login
 *  (like silent admins).
 *
 *  @return `true` if player has admin rights and `false` otherwise.
 */
public final function bool IsAdmin()
{
    return (GetAdminStatus() != AS_None);
}

/**
 *  Changes admin status of the caller `APlayer`.
 *  Can only fail if caller `APlayer` has already disconnected.
 *
 * @param   newAdminStatus  New admin status of the `APlayer`.
 */
public final function SetAdminStatus(AdminStatus newAdminStatus)
{
    local PlayerReplicationInfo myReplicationInfo;
    myReplicationInfo = GetRI();
    if (myReplicationInfo == none) {
        return;
    }
    switch (newAdminStatus)
    {
    case AS_Admin:
        myReplicationInfo.bAdmin        = true;
        myReplicationInfo.bSilentAdmin  = false;
        break;
    case AS_SilentAdmin:
        myReplicationInfo.bAdmin        = false;
        myReplicationInfo.bSilentAdmin  = true;
        break;
    default:
        myReplicationInfo.bAdmin        = false;
        myReplicationInfo.bSilentAdmin  = false;
    }
}

/**
 *  Returns current amount of money caller `APlayer` has.
 *
 *  @return Amount of money `APlayer` has. If player has already disconnected
 *      method will return `0`.
 */
public final function int GetDosh()
{
    local PlayerReplicationInfo myReplicationInfo;
    myReplicationInfo = GetRI();
    if (myReplicationInfo == none) {
        return 0;
    }
    return myReplicationInfo.score;
}

/**
 *  Sets amount of money that caller `APlayer` will have.
 *
 *  @param  newDoshAmount   New amount of money that caller `APlayer` must have.
 */
public final function SetDosh(int newDoshAmount)
{
    local PlayerReplicationInfo myReplicationInfo;
    myReplicationInfo = GetRI();
    if (myReplicationInfo == none) {
        return;
    }
    myReplicationInfo.score = newDoshAmount;
}

/**
 *  Return `ConsoleWriter` that can be used to write into this player's console.
 *
 *  Provided that returned object is never deallocated - returns the same object
 *  with each call, otherwise can allocate new instance of `ConsoleWriter`.
 *
 *  @return `ConsoleWriter` that can be used to write into this player's
 *      console. Returned object should not be deallocated, but it is
 *      guaranteed to be valid for non-disconnected players.
 */
public final function ConsoleWriter Console()
{
    if (    consoleInstance == none
        ||  consoleInstance.GetLifeVersion() != consoleLifeVersion)
    {
        consoleInstance = _.console.For(self);
        consoleLifeVersion = consoleInstance.GetLifeVersion();
    }
    //  Set us as target in case someone messed with this setting
    return consoleInstance.ForPlayer(self);
}

defaultproperties
{
    usesObjectPool = false
}