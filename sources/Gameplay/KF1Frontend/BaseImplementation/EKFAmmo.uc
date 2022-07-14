/**
 *  Implementation of `EAmmo` for classic Killing Floor weapons that changes
 *  as little as possible and only on request from another mod, otherwise not
 *  altering gameplay at all.
 *      Copyright 2022 Anton Tarasenko
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
class EKFAmmo extends EAmmo;

var private NativeActorRef ammunitionReference;

protected function Finalizer()
{
    _.memory.Free(ammunitionReference);
    ammunitionReference = none;
}

/**
 *  Creates new `EKFAmmo` that refers to the `ammunitionInstance` ammunition.
 *
 *  @param  ammunitionInstance  Native ammunition instance that new `EKFAmmo`
 *      will represent.
 *  @return New `EKFAmmo` that represents given `ammunitionInstance`.
 *      `none` iff `ammunitionInstance` is either `none` or
 *      is an unused flash light ammunition
 *      (has `class'KFMod.FlashlightAmmo'` class).
 */
public final static /*unreal*/ function EKFAmmo Wrap(
    Ammunition ammunitionInstance)
{
    local EKFAmmo newReference;
    if (ammunitionInstance == none)                                 return none;
    //  This one is not actually used for anything, so it is not real
    if (ammunitionInstance.class == class'KFMod.FlashlightAmmo')    return none;

    newReference = EKFAmmo(__().memory.Allocate(class'EKFAmmo'));
    newReference.ammunitionReference =
        __server().unreal.ActorRef(ammunitionInstance);
    return newReference;
}

public function EInterface Copy()
{
    local Ammunition ammunitionInstance;
    ammunitionInstance = GetNativeInstance();
    return Wrap(ammunitionInstance);
}

public function bool Supports(class<EInterface> newInterfaceClass)
{
    if (newInterfaceClass == none)              return false;
    if (newInterfaceClass == class'EItem')      return true;
    if (newInterfaceClass == class'EAmmo')      return true;
    if (newInterfaceClass == class'EKFAmmo')    return true;

    return false;
}

public function EInterface As(class<EInterface> newInterfaceClass)
{
    if (!IsExistent()) {
        return none;
    }
    if (    newInterfaceClass == class'EItem'
        ||  newInterfaceClass == class'EAmmo'
        ||  newInterfaceClass == class'EKFAmmo')
    {
        return Copy();
    }
    return none;
}

public function bool IsExistent()
{
    return (GetNativeInstance() != none);
}

public function bool SameAs(EInterface other)
{
    local EKFAmmo otherAmmo;
    otherAmmo = EKFAmmo(other);
    if (otherAmmo == none) {
        return false;
    }
    return (GetNativeInstance() == otherAmmo.GetNativeInstance());
}

/**
 *  Returns `Ammunition` instance represented by the caller `EKFAmmo`.
 *
 *  @return `Ammunition` instance represented by the caller `EKFAmmo`.
 */
public final /*unreal*/ function Ammunition GetNativeInstance()
{
    if (ammunitionReference != none) {
        return Ammunition(ammunitionReference.Get());
    }
    return none;
}

public function array<Text> GetTags()
{
    local array<Text> tagArray;
    if (ammunitionReference == none)        return tagArray;
    if (ammunitionReference.Get() == none)  return tagArray;

    tagArray[0] = P("ammo").Copy();
    return tagArray;
}

public function bool HasTag(BaseText tagToCheck)
{
    if (tagToCheck == none)             return false;
    if (tagToCheck.Compare(P("ammo")))  return true;

    return false;
}

public function Text GetTemplate()
{
    local Ammunition ammunition;
    ammunition = GetNativeInstance();
    if (ammunition == none) {
        return none;
    }
    return _.text.FromString(string(ammunition.class));
}

public function Text GetName()
{
    local Ammunition ammunition;
    ammunition = GetNativeInstance();
    if (ammunition == none) {
        return none;
    }
    return _.text.FromString(ammunition.GetHumanReadableName());
}

public function bool IsRemovable()
{
    return false;
}

public function bool IsSellable()
{
    return false;
}

private function class<KFWeaponPickup> GetOwnerWeaponPickupClass()
{
    local KFWeapon      ownerWeapon;
    local Ammunition    ammunition;
    ammunition = GetNativeInstance();
    if (ammunition == none) {
        return none;
    }
    ownerWeapon = GetOwnerWeapon();
    if (ownerWeapon != none) {
        return class<KFWeaponPickup>(ownerWeapon.pickupClass);
    }
    return none;
}

//      Finds a weapons that is corresponding to our ammo.
//      We can limit ourselves to returning a single instance, since one weapon
//  per ammo type is how Killing Floor does things.
private function KFWeapon GetOwnerWeapon()
{
    local Pawn          myOwner;
    local KFWeapon      nextWeapon;
    local Inventory     nextInventory;
    local Ammunition    ammunition;
    ammunition = GetNativeInstance();
    if (ammunition == none) return none;
    myOwner = Pawn(ammunition.owner);
    if (myOwner == none)    return none;

    nextInventory = myOwner.inventory;
    while (nextInventory != none)
    {
        nextWeapon = KFWeapon(nextInventory);
        nextInventory = nextInventory.inventory;
        if (    _server.unreal.inventory.GetAmmoClass(nextWeapon, 0)
            ==  ammunition.class)
        {
            return nextWeapon;
        }
        else if (   _server.unreal.inventory.GetAmmoClass(nextWeapon, 1)
                ==  ammunition.class) {
            return nextWeapon;
        }
    }
    return none;
}

/**
 *  In Killing Floor ammo object itself does not actually have a price,
 *  instead it is defined inside weapon's `Pickup` class and, therefore,
 *  cannot be changed for an individual item. Only calculated.
 */
public function bool SetPrice(int newPrice)
{
    return false;
}

public function int GetPrice()
{
    return GetPriceOf(GetAmount());
}

public function int GetTotalPrice()
{
    return GetPriceOf(GetTotalAmount());
}

public function int GetPriceOf(int ammoAmount)
{
    local Pawn                      myOwner;
    local int                       clipSize;
    local float                     clipPrice;
    local KFWeapon                  ownerWeapon;
    local KFPlayerReplicationInfo   ownerKFPRI;
    local class<KFWeaponPickup>     ownerWeaponPickupClass;
    local Ammunition                ammunition;
    ammunition = GetNativeInstance();
    if (ammunition == none)             return 0;
    ownerWeapon = GetOwnerWeapon();
    if (ownerWeapon == none)            return 0;
    ownerWeaponPickupClass = class<KFWeaponPickup>(ownerWeapon.pickupClass);
    if (ownerWeaponPickupClass == none) return 0;

    //  Calculate clip price
    if (    ownerWeapon.bHasSecondaryAmmo
        &&  ammunition.class != ownerWeapon.fireModeClass[0].default.ammoClass)
    {
        //  Amon Killing Floor's weapons, only M4 203 has a real secondary ammo
        clipSize = 1;
    }
    else {
        clipSize = ownerWeapon.default.magCapacity;
    }
    if( ownerWeapon.PickupClass == class'HuskGunPickup' ) {
        clipSize = ownerWeaponPickupClass.default.buyClipSize;
    }
    clipPrice = ownerWeaponPickupClass.default.ammoCost;
    //  Calculate clip size
    myOwner = Pawn(ammunition.owner);
    if (myOwner != none) {
        ownerKFPRI = KFPlayerReplicationInfo(myOwner.playerReplicationInfo);
    }
    if (ownerKFPRI != none)
    {
        clipPrice *= ownerKFPRI.clientVeteranSkill.static
            .GetAmmoCostScaling(ownerKFPRI, ownerWeaponPickupClass);
    }
    //  Calculate price of total ammo
    return int(ammoAmount * clipPrice / clipSize);
}

public function bool SetWeight(int newWeight)
{
    return false;
}

public function int GetWeight()
{
    return 0;
}

//      Killing Floor weapons do not reduce ammunition when it is loaded it into
//  the weapons. This is because each ammo type is only ever used by one weapon,
//  so the can simply treat it as part of the weapon and only record how much
//  of it is currently in the weapon's magazine.
//      This method goes through inventory weapons to find how much ammo was
//  already loaded into the weapons.
private function int GetLoadedAmmo()
{
    local KFWeapon      ownerWeapon;
    local Ammunition    ammunition;
    ammunition = GetNativeInstance();
    if (ammunition == none)                         return 0;
    ownerWeapon = GetOwnerWeapon();
    if (ownerWeapon == none)                        return 0;
    //  Husk gun does not load ammo at all
    if (ownerWeapon.class == class'KFMod.HuskGun')  return 0;

    //      Most of the Killing Floor weapons do not have a proper separate
    //  secondary ammo: they either reuse primary ammo (like zed guns or
    //  hunting shotgun), or they use some pseudo-ammo (like medic guns).
    //      They only exception is M4 203 that loads itself as soon as
    //  it fires. Some modded weapons might also be exceptions and/or use
    //  secondary ammo differently, but we have no way of knowing how
    //  exactly they are doing it and cannot implement this interface
    //  for them.
    //      That is why we only bother with the first fire mode and count
    //  one loaded ammo for the secondary, just assuming it is M4 203.
    //      We can also quit as soon as we have found a single weapon that
    //  uses our ammo, since one weapon per ammo type is how Killing Floor
    //  does things.
    if (    _server.unreal.inventory.GetAmmoClass(ownerWeapon, 0)
        ==  ammunition.class)
    {
        return ownerWeapon.magAmmoRemaining;
    }
    else if (   _server.unreal.inventory.GetAmmoClass(ownerWeapon, 1)
            ==  ammunition.class)
    {
        return 1; // M4 203
    }
    return 0;
}

public function Add(int amount, optional bool forceAddition)
{
    local Ammunition ammunition;
    ammunition = GetNativeInstance();
    if (ammunition == none) {
        return;
    }
    if (forceAddition) {
        ammunition.ammoAmount += amount;
    }
    else
    {
        ammunition.ammoAmount =
            Min(ammunition.maxAmmo, ammunition.ammoAmount + amount);
    }
    //  Correct possible negative values
    if (ammunition.ammoAmount < 0) {
        ammunition.ammoAmount = 0;
    }
    ammunition.netUpdateTime = ammunition.level.timeSeconds - 1;
}

public function int GetAmount()
{
    local Ammunition ammunition;
    ammunition = GetNativeInstance();
    if (ammunition == none) {
        return 0;
    }
    return Max(0, ammunition.ammoAmount - GetLoadedAmmo());
}

public function int GetTotalAmount()
{
    local Ammunition ammunition;
    ammunition = GetNativeInstance();
    if (ammunition == none) {
        return 0;
    }
    return Max(0, ammunition.ammoAmount);
}

public function SetAmount(int amount, optional bool forceAddition)
{
    local Ammunition ammunition;
    ammunition = GetNativeInstance();
    if (ammunition == none) {
        return;
    }
    if (forceAddition) {
        ammunition.ammoAmount = amount;
    }
    else {
        ammunition.ammoAmount = Min(ammunition.maxAmmo, amount);
    }
    //  Correct possible negative values
    if (ammunition.ammoAmount < 0) {
        ammunition.ammoAmount = 0;
    }
    ammunition.netUpdateTime = ammunition.level.timeSeconds - 1;
}

public function int GetMaxAmount()
{
    local Ammunition ammunition;
    ammunition = GetNativeInstance();
    if (ammunition == none) {
        return 0;
    }
    //  `Ammunition` does not really support infinite ammo, so return `0` if
    //  the value is messed up.
    return Max(0, ammunition.maxAmmo - GetLoadedAmmo());
}

public function int GetMaxTotalAmount()
{
    local Ammunition ammunition;
    ammunition = GetNativeInstance();
    if (ammunition == none) {
        return 0;
    }
    //  `Ammunition` does not really support infinite ammo, so return `0` if
    //  the value is messed up.
    return Max(0, ammunition.maxAmmo);
}

/**
 *  Supports any non-negative ammo value.
 */
public function bool SetMaxAmount(
    int             newMaxAmmo,
    optional bool   leaveCurrentAmmo)
{
    local Ammunition ammunition;
    //  We do not support unlimited ammo values
    if (newMaxAmmo < 0)     return false;
    ammunition = GetNativeInstance();
    if (ammunition == none) return false;

    ammunition.maxAmmo = newMaxAmmo + GetLoadedAmmo();
    if (!leaveCurrentAmmo) {
        ammunition.ammoAmount = Min(ammunition.maxAmmo, ammunition.ammoAmount);
    }
    ammunition.netUpdateTime = ammunition.level.timeSeconds - 1;
    return true;
}

public function bool SetMaxTotalAmount(
    int             newTotalMaxAmmo,
    optional bool   leaveCurrentAmmo)
{
    local Ammunition ammunition;
    //  We do not support unlimited ammo values
    if (newTotalMaxAmmo < 0)    return false;
    ammunition = GetNativeInstance();
    if (ammunition == none)     return false;

    ammunition.maxAmmo = newTotalMaxAmmo;
    if (!leaveCurrentAmmo) {
        ammunition.ammoAmount = Min(ammunition.maxAmmo, ammunition.ammoAmount);
    }
    ammunition.netUpdateTime = ammunition.level.timeSeconds - 1;
    return true;
}

public function bool HasWeapon()
{
    return (GetOwnerWeapon() != none);
}

//  Killing Floor's ammo should also count ammo already loaded into the magazine
public function Fill()
{
    if (GetMaxTotalAmount() < 0)            return;
    if (GetAmount() >= GetMaxTotalAmount()) return;

    SetAmount(GetMaxTotalAmount());
}

defaultproperties
{
}