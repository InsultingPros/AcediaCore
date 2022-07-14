/**
 *  Provides a common interface to a connected player connection.
 *      Copyright 2021 - 2022 Anton Tarasenko
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
class EPlayer extends EInterface;

//  How this `EPlayer` is identified by the server
var private User identity;

//  Writer that can be used to write into this player's console
var private ConsoleWriter   consoleInstance;
//  Remember version to reallocate writer in case someone deallocates it
var private int             consoleLifeVersion;

//  `PlayerController` reference
var private NativeActorRef  controller;

/**
 * Describes the player's admin status (as defined by standard KF classes)
 */
enum AdminStatus
{
    //  Not an admin
    AS_None,
    //  (Publicly visible) admin
    AS_Admin,
    //  Admin with their admin status hidden
    AS_SilentAdmin
};

//  Stores all the types of signals `EPlayer` might emit
struct PlayerSignals
{
    var public PlayerAPI_OnPlayerNameChanging_Signal    onNameChanging;
    var public PlayerAPI_OnPlayerNameChanged_Signal     onNameChanged;
};
//  We do not own objects in this structure, but it is created and managed by
//  `PlayersAPI` and is expected to be allocated during the whole Acedia run.
var protected PlayerSignals signalsReferences;

protected function Finalizer()
{
    _.memory.Free(controller);
    _.memory.Free(consoleInstance);
    controller      = none;
    consoleInstance = none;
    //  No need to deallocate `User` objects, since they are all have unique
    //  instance for every player on the server
    identity        = none;
}

/**
 *  Initializes caller `EPlayer`. Should be called right after `EPlayer`
 *  was allocated.
 *
 *  Every `EPlayer` must be initialized, using non-initialized `EPlayer`
 *  instances is invalid.
 *
 *  Initialization can fail if:
 *      1.  `initController == none`;
 *      2.  Its id hash (from `GetPlayerIDHash()`) was not properly setup yet
 *          (not steam id);
 *      3.  Caller `EPlayer` already was successfully initialized.
 *
 *  @param  initController  Controller that caller `EPlayer` will correspond to.
 *  @return `true` if initialization was successful and `false` otherwise.
 */
public final /* unreal */ function bool Initialize(
    PlayerController    initController,
    PlayerSignals       playerSignals)
{
    local Text idHash;
    if (controller != none)     return false; // Already initialized!
    if (initController == none) return false;

    if (identity == none)
    {
        //  Only fetch `User` object if it was not yet setup, which can happen
        //  if `EPlayer` is making a copy and wants to avoid
        //  re-fetching `identity`
        idHash = _.text.FromString(initController.GetPlayerIDHash());
        identity = _.users.FetchByIDHash(idHash);
        idHash.FreeSelf();
        idHash = none;
    }
    signalsReferences   = playerSignals;
    controller          = _server.unreal.ActorRef(initController);
    return true;
}

public function bool IsExistent()
{
    if (controller == none) {
        return false;
    }
    return (controller.Get() != none);
}

public function EInterface Copy()
{
    local EPlayer playerCopy;
    playerCopy = EPlayer(_.memory.Allocate(class'EPlayer'));
    if (controller == none)
    {
        //  Should not really happen, since then caller `EPlayer` was
        //  not initialized
        return playerCopy;
    }
    playerCopy.identity = identity;
    playerCopy.Initialize(  PlayerController(controller.Get()),
                            signalsReferences);
    return playerCopy;
}

public function bool SameAs(EInterface other)
{
    local EPlayer           asPlayer;
    local NativeActorRef    otherController;
    if (other == none)              return false;
    if (controller == none)         return false;
    asPlayer = EPlayer(other);
    if (asPlayer == none)           return false;
    otherController = asPlayer.controller;
    if (otherController == none)    return false;
    
    return (controller.Get() == otherController.Get());
}

/**
 *  Returns color of the caller `EPlayer`'s current team.
 *
 *  Such color is supposed to be defined even for a single-team modes.
 *
 *  @return `Color` structure with the `EPlayer`'s current color.
 */
public final function Color GetTeamColor()
{
    return _.color.Red;
}

/**
 *  Returns location of the caller `EPlayer`.
 *
 *  If caller `EPlayer` has a pawn, then it's location will be returned,
 *  otherwise a location from which caller `EPlayer` is currently spectating is
 *  considered caller's location.
 *
 *  @return Location of the caller `EPlayer` has a pawn.
 */
public final function Vector GetLocation()
{
    local Pawn              myPawn;
    local PlayerController  myController;
    if (controller != none) {
        myController = PlayerController(controller.Get());
    }
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

/**
 *  If caller `EPlayer` currently owns a pawn, then this method will return
 *  `EPawn` interface to it.
 *
 *  @return `EPawn` interface to pawn of the caller `EPlayer`.
 *      `none` if caller `EPayer` is non-existent or does not have a pawn.
 */
public final function EPawn GetPawn()
{
    local Pawn              myPawn;
    local PlayerController  myController;

    if (controller == none)     return none;
    myController = PlayerController(controller.Get());
    if (myController == none)   return none;
    myPawn = myController.pawn;
    if (myPawn == none)         return none;

    return class'EKFPawn'.static.Wrap(myPawn);
}

//  `PlayerReplicationInfo` associated with the caller `EPlayer`.
//  Can return `none` if:
//      1. Caller `EPlayer` has already disconnected;
//      2. It was not properly initialized;
private final function PlayerReplicationInfo GetRI()
{
    local PlayerController myController;
    if (controller == none)     return none;
    myController = PlayerController(controller.Get());
    if (myController == none)   return none;

    return myController.playerReplicationInfo;
}

/**
 *  Returns `PlayerController`, associated with the caller `EPlayer`.
 *
 *  @return `PlayerController`, associated with the caller `EPlayer`.
 */
public final /* unreal */ function PlayerController GetController()
{
    if (controller == none) {
        return none;
    }
    return PlayerController(controller.Get());
}

/**
 *  Returns `User` object that is corresponding to the caller `EPlayer`.
 *
 *  @return `User` corresponding to the caller `EPlayer`. Guarantee to be
 *      not `none` for correctly initialized `EPlayer` (it remembers `User`
 *      record even if player has disconnected).
 */
public final function User GetIdentity()
{
    return identity;
}

/**
 *  Returns player's original name - the one he joined the game with.
 *
 *  @return `Text` containing original name of the caller player.
 *      Guaranteed to not be `none`.
 */
public final function Text GetOriginalName()
{
    local ConnectionService             service;
    local ConnectionService.Connection  myConnection;
    service = ConnectionService(class'ConnectionService'.static.Require());
    myConnection = service.GetConnection(GetController());
    return _.text.FromString(myConnection.originalName);
}

/**
 *  Returns current displayed name of the caller player.
 *
 *  @return `Text` containing current name of the caller player.
 *      Guaranteed to not be `none`.
 */
public final function Text GetName()
{
    local PlayerReplicationInfo myReplicationInfo;
    myReplicationInfo = GetRI();
    if (myReplicationInfo != none) {
        return _.text.FromColoredString(myReplicationInfo.playerName);
    }
    return P("").Copy();
}

/**
 *  Set new displayed name for the caller `EPlayer`.
 *
 *  @param  newPlayerName   New name of the caller `EPlayer`. This value will
 *      be copied. Passing `none` will result in an empty name.
 */
public final function SetName(BaseText newPlayerName)
{
    local Text                  oldPlayerName;
    local PlayerReplicationInfo replicationInfo;
    replicationInfo = GetRI();
    if (replicationInfo == none) {
        return;
    }
    oldPlayerName = _.text.FromFormattedString(replicationInfo.playerName);
    replicationInfo.playerName = CensorPlayerName(oldPlayerName, newPlayerName);
    _.memory.Free(oldPlayerName);
}

//  Converts `Text` nickname into a suitable `string` representation.
private final function string ConvertTextNameIntoString(BaseText playerName)
{
    local string                newPlayerNameAsString;
    local BaseText.Formatting   endingFormatting;
    if (playerName == none) {
        return "";
    }
    newPlayerNameAsString = playerName.ToColoredString(,, _.color.white);
    //      To correctly display nicknames we want to drop default color tag
    //  at the beginning (the one `ToColoredString()` adds if first character
    //  has no defined color).
    //      This is a compatibility consideration with vanilla UIs that use
    //  color codes from `myReplicationInfo.playerName` for displaying nicknames
    //  and whose expected behavior can get broken by default color tag.
    if (!playerName.GetFormatting(0).isColored) {
        newPlayerNameAsString = Mid(newPlayerNameAsString, 4);
    }
    //      This is another compatibility consideration with vanilla UIs: unless
    //  we restore color to neutral white, Killing Floor will paint any chat
    //  messages we send in the color our nickname ended with.
    endingFormatting = playerName.GetFormatting(playerName.GetLength() - 1);
    if (    endingFormatting.isColored
        &&  !_.color.AreEqual(endingFormatting.color, _.color.white, true))
    {
        newPlayerNameAsString $= _.color.GetColorTag(_.color.white);
    }
    return newPlayerNameAsString;
}

//  Calls appropriate events to let them modify / "censor" player's new name.
private final function string CensorPlayerName(
    BaseText oldPlayerName,
    BaseText newPlayerName)
{
    local string        result;
    local Text          censoredName;
    local MutableText   mutablePlayerName;
    if (newPlayerName == none) {
        return "";
    }
    mutablePlayerName = newPlayerName.MutableCopy();
    //  Let signal handlers alter the name
    signalsReferences.onNameChanging
        .Emit(self, oldPlayerName, mutablePlayerName);
    censoredName = mutablePlayerName.Copy();
    signalsReferences.onNameChanged.Emit(self, oldPlayerName, censoredName);
    //  Returns "censored" result
    result = ConvertTextNameIntoString(censoredName);
    _.memory.Free(mutablePlayerName);
    _.memory.Free(censoredName);
    return result;
}

//  TODO: replace this, it has no place here
//  ^ works as a temporary solution before we add pawn wrappers
public final function EInventory GetInventory()
{
    local EKFInventory inventory;
    if (controller != none && controller.Get() != none)
    {
        inventory = EKFInventory(_.memory.Allocate(class'EKFInventory'));
        inventory.Initialize(self);
        return inventory;
    }
    return none;
}

/**
 *  Returns admin status of the caller player.
 *  Disconnected players are never admins.
 *
 *  Different from `IsAdmin()` since this method allows to distinguish between
 *  different types of admin login (like silent admins).
 *
 *  @return Admin status of the caller `EPlayer`.
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
 *  Changes admin status of the caller `EPlayer`.
 *  Can only fail if caller `EPlayer` has already disconnected.
 *
 * @param   newAdminStatus  New admin status of the `EPlayer`.
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
 *  Returns current amount of money caller `EPlayer` has.
 *
 *  @return Amount of money `EPlayer` has. If player has already disconnected
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
 *  Sets amount of money that caller `EPlayer` will have.
 *
 *  @param  newDoshAmount   New amount of money that caller `EPlayer` must have.
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
 *  with each call. If somebody does deallocate it - method will allocate new
 *  instance of `ConsoleWriter`.
 *
 *  @return `ConsoleWriter` that can be used to write into this player's
 *      console. Returned object should not be deallocated, but it is
 *      guaranteed to be valid for non-disconnected players.
 */
public final function /* borrow */ ConsoleWriter BorrowConsole()
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