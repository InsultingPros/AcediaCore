/**
 *  Implementation of `EAmmo` for Killing Floor medical syringe that changes
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
class EKFSyringeAmmo extends EAmmo;

var private NativeActorRef syringeReference;

protected function Finalizer()
{
    _.memory.Free(syringeReference);
    syringeReference = none;
}

/**
 *  Creates new `EKFSyringeAmmo` that refers to the `syringeInstance`'s
 *  ammunition.
 *
 *  @param  syringeInstance Native syringe instance, whose ammunition
 *      new `EKFSyringeAmmo` will represent.
 *  @return New `EKFSyringeAmmo` that represents ammunition of given
 *      `syringeInstance`. `none` iff `syringeInstance` is `none`.
 */
public final static /*unreal*/ function EKFSyringeAmmo Wrap(
    Syringe syringeInstance)
{
    local EKFSyringeAmmo newReference;
    if (syringeInstance == none) {
        return none;
    }
    newReference = EKFSyringeAmmo(__().memory.Allocate(class'EKFSyringeAmmo'));
    newReference.syringeReference =
        __server().unreal.ActorRef(syringeInstance);
    return newReference;
}

public function EInterface Copy()
{
    local Syringe syringeInstance;
    syringeInstance = GetNativeInstance();
    return Wrap(syringeInstance);
}

public function bool Supports(class<EInterface> newInterfaceClass)
{
    if (newInterfaceClass == none)                  return false;
    if (newInterfaceClass == class'EItem')          return true;
    if (newInterfaceClass == class'EAmmo')          return true;
    if (newInterfaceClass == class'EKFSyringeAmmo') return true;

    return false;
}

public function EInterface As(class<EInterface> newInterfaceClass)
{
    if (!IsExistent()) {
        return none;
    }
    if (    newInterfaceClass == class'EItem'
        ||  newInterfaceClass == class'EAmmo'
        ||  newInterfaceClass == class'EKFSyringeAmmo')
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
    local EKFSyringeAmmo otherAmmo;
    otherAmmo = EKFSyringeAmmo(other);
    if (otherAmmo == none) {
        return false;
    }
    return (GetNativeInstance() == otherAmmo.GetNativeInstance());
}

/**
 *  Returns `KFAmmunition` instance represented by the caller `EKFAmmo`.
 *
 *  @return `KFAmmunition` instance represented by the caller `EKFAmmo`.
 */
public final /*unreal*/ function Syringe GetNativeInstance()
{
    if (syringeReference != none) {
        return Syringe(syringeReference.Get());
    }
    return none;
}

public function array<Text> GetTags()
{
    local array<Text> tagArray;
    if (syringeReference == none)       return tagArray;
    if (syringeReference.Get() == none) return tagArray;

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
    local Syringe syringeInstance;
    syringeInstance = GetNativeInstance();
    if (syringeInstance == none) {
        return none;
    }
    return _.text.FromString("kfmod.syringe:ammo");
}

public function Text GetName()
{
    local Syringe syringeInstance;
    syringeInstance = GetNativeInstance();
    if (syringeInstance == none) {
        return none;
    }
    return _.text.FromString("Syringe's ammo");
}

public function bool IsRemovable()
{
    return false;
}

public function bool IsSellable()
{
    return false;
}

/**
 *  Medic ammo is free and does not have a price in Killing Floor.
 */
public function bool SetPrice(int newPrice)
{
    return false;
}

public function int GetPrice()
{
    return 0;
}

public function int GetTotalPrice()
{
    return 0;
}

public function int GetPriceOf(int ammoAmount)
{
    return 0;
}

public function bool SetWeight(int newWeight)
{
    return false;
}

public function int GetWeight()
{
    return 0;
}

public function Add(int amount, optional bool forceAddition)
{
    local Syringe syringeInstance;
    syringeInstance = GetNativeInstance();
    if (syringeInstance == none) {
        return;
    }
    if (forceAddition) {
        syringeInstance.ammoCharge[0] += amount;
    }
    else
    {
        syringeInstance.ammoCharge[0] =
            Min(syringeInstance.maxAmmoCount,
                syringeInstance.ammoCharge[0] + amount);
    }
    //  Correct possible negative values
    if (syringeInstance.ammoCharge[0] < 0) {
        syringeInstance.ammoCharge[0] = 0;
    }
}

public function int GetAmount()
{
    local Syringe syringeInstance;
    syringeInstance = GetNativeInstance();
    if (syringeInstance == none) {
        return 0;
    }
    return Max(0, syringeInstance.ammoCharge[0]);
}

public function int GetTotalAmount()
{
    return GetAmount();
}

public function SetAmount(int amount, optional bool forceAddition)
{
    local Syringe syringeInstance;
    syringeInstance = GetNativeInstance();
    if (syringeInstance == none) {
        return;
    }
    if (forceAddition) {
        syringeInstance.ammoCharge[0] = amount;
    }
    else
    {
        syringeInstance.ammoCharge[0] =
            Min(syringeInstance.maxAmmoCount, amount);
    }
    //  Correct possible negative values
    if (syringeInstance.ammoCharge[0] < 0) {
        syringeInstance.ammoCharge[0] = 0;
    }
}

public function int GetMaxAmount()
{
    local Syringe syringeInstance;
    syringeInstance = GetNativeInstance();
    if (syringeInstance == none) {
        return 0;
    }
    return Max(0, syringeInstance.maxAmmoCount);
}

public function int GetMaxTotalAmount()
{
    return GetMaxAmount();
}

public function bool SetMaxAmount(
    int             newMaxAmmo,
    optional bool   leaveCurrentAmmo)
{
    return false;
}

public function bool SetMaxTotalAmount(
    int             newTotalMaxAmmo,
    optional bool   leaveCurrentAmmo)
{
    return false;
}

public function bool HasWeapon()
{
    return (GetNativeInstance() != none);
}

defaultproperties
{
}