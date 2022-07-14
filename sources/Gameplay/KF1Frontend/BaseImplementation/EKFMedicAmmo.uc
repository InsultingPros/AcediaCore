/**
 *  Implementation of `EAmmo` for Killing Floor medic weapons that changes
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
class EKFMedicAmmo extends EAmmo;

var private NativeActorRef medicWeaponReference;

protected function Finalizer()
{
    _.memory.Free(medicWeaponReference);
    medicWeaponReference = none;
}

/**
 *  Creates new `EKFMedicAmmo` that refers to the `medicWeaponInstance`'s
 *  medic ammunition.
 *
 *  @param  medicWeaponInstance Native medic gun, whose medic ammunition
 *      new `EKFMedicAmmo` will represent.
 *  @return New `EKFMedicAmmo` that represents medic ammunition of given
 *      `medicWeaponInstance`. `none` iff `medicWeaponInstance` is `none`.
 */
public final static /*unreal*/ function EKFMedicAmmo Wrap(
    KFMedicGun medicWeaponInstance)
{
    local EKFMedicAmmo newReference;
    if (medicWeaponInstance == none) {
        return none;
    }
    newReference = EKFMedicAmmo(__().memory.Allocate(class'EKFMedicAmmo'));
    newReference.medicWeaponReference =
        __server().unreal.ActorRef(medicWeaponInstance);
    return newReference;
}

public function EInterface Copy()
{
    local KFMedicGun medicWeaponInstance;
    medicWeaponInstance = GetNativeInstance();
    return Wrap(medicWeaponInstance);
}

public function bool Supports(class<EInterface> newInterfaceClass)
{
    if (newInterfaceClass == none)                  return false;
    if (newInterfaceClass == class'EItem')          return true;
    if (newInterfaceClass == class'EAmmo')          return true;
    if (newInterfaceClass == class'EKFMedicAmmo')   return true;

    return false;
}

public function EInterface As(class<EInterface> newInterfaceClass)
{
    if (!IsExistent()) {
        return none;
    }
    if (    newInterfaceClass == class'EItem'
        ||  newInterfaceClass == class'EAmmo'
        ||  newInterfaceClass == class'EKFMedicAmmo')
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
    local EKFMedicAmmo otherAmmo;
    otherAmmo = EKFMedicAmmo(other);
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
public final /*unreal*/ function KFMedicGun GetNativeInstance()
{
    if (medicWeaponReference != none) {
        return KFMedicGun(medicWeaponReference.Get());
    }
    return none;
}

public function array<Text> GetTags()
{
    local array<Text> tagArray;
    if (medicWeaponReference == none)       return tagArray;
    if (medicWeaponReference.Get() == none) return tagArray;

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
    local KFMedicGun medicWeapon;
    medicWeapon = GetNativeInstance();
    if (medicWeapon == none) {
        return none;
    }
    return _.text.FromString(string(medicWeapon.class) $ ":ammo");
}

public function Text GetName()
{
    local KFMedicGun medicWeapon;
    medicWeapon = GetNativeInstance();
    if (medicWeapon == none) {
        return none;
    }
    return _.text.FromString(medicWeapon.GetHumanReadableName() $ "'s ammo");
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
    local KFMedicGun medicWeapon;
    medicWeapon = GetNativeInstance();
    if (medicWeapon == none) {
        return;
    }
    if (forceAddition) {
        medicWeapon.healAmmoCharge += amount;
    }
    else
    {
        medicWeapon.healAmmoCharge =
            Min(medicWeapon.maxAmmoCount, medicWeapon.healAmmoCharge + amount);
    }
    //  Correct possible negative values
    if (medicWeapon.healAmmoCharge < 0) {
        medicWeapon.healAmmoCharge = 0;
    }
}

public function int GetAmount()
{
    local KFMedicGun medicWeapon;
    medicWeapon = GetNativeInstance();
    if (medicWeapon == none) {
        return 0;
    }
    return Max(0, medicWeapon.healAmmoCharge);
}

public function int GetTotalAmount()
{
    return GetAmount();
}

public function SetAmount(int amount, optional bool forceAddition)
{
    local KFMedicGun medicWeapon;
    medicWeapon = GetNativeInstance();
    if (medicWeapon == none) {
        return;
    }
    if (forceAddition) {
        medicWeapon.healAmmoCharge = amount;
    }
    else {
        medicWeapon.healAmmoCharge = Min(medicWeapon.maxAmmoCount, amount);
    }
    //  Correct possible negative values
    if (medicWeapon.healAmmoCharge < 0) {
        medicWeapon.healAmmoCharge = 0;
    }
}

public function int GetMaxAmount()
{
    local KFMedicGun medicWeapon;
    medicWeapon = GetNativeInstance();
    if (medicWeapon == none) {
        return 0;
    }
    return Max(0, medicWeapon.maxAmmoCount);
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