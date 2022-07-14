/**
 *  Implementation of `EWeapon` for classic Killing Floor weapons that changes
 *  as little as possible and only on request from another mod, otherwise not
 *  altering gameplay at all.
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
class EKFWeapon extends EWeapon;

var private NativeActorRef weaponReference;

var private config array< class<KFWeapon> > weaponsWithFlashlight;

protected function Finalizer()
{
    _.memory.Free(weaponReference);
    weaponReference = none;
}

/**
 *  Creates new `EKFWeapon` that refers to the `weaponInstance` weapon.
 *
 *  @param  weaponInstance  Native weapon class that new `EKFWeapon` will
 *      represent.
 *  @return New `EKFWeapon` that represents given `weaponInstance`.
 */
public final static /*unreal*/ function EKFWeapon Wrap(KFWeapon weaponInstance)
{
    local EKFWeapon newReference;
    if (weaponInstance == none) {
        return none;
    }
    newReference = EKFWeapon(__().memory.Allocate(class'EKFWeapon'));
    newReference.weaponReference = __server().unreal.ActorRef(weaponInstance);
    return newReference;
}

public function EInterface Copy()
{
    local KFWeapon weaponInstance;
    weaponInstance = GetNativeInstance();
    return Wrap(weaponInstance);
}

public function bool Supports(class<EInterface> newInterfaceClass)
{
    if (newInterfaceClass == none)              return false;
    if (newInterfaceClass == class'EWeapon')    return true;
    if (newInterfaceClass == class'EKFWeapon')  return true;

    return false;
}

public function EInterface As(class<EInterface> newInterfaceClass)
{
    if (!IsExistent()) {
        return none;
    }
    if (    newInterfaceClass == class'EItem'
        ||  newInterfaceClass == class'EWeapon'
        ||  newInterfaceClass == class'EKFWeapon')
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
    local EKFWeapon otherWeapon;
    otherWeapon = EKFWeapon(other);
    if (otherWeapon == none) {
        return false;
    }
    return (GetNativeInstance() == otherWeapon.GetNativeInstance());
}

/**
 *  Returns `KFWeapon` instance represented by the caller `EKFWeapon`.
 *
 *  @return `KFWeapon` instance represented by the caller `EKFWeapon`.
 */
public final /*unreal*/ function KFWeapon GetNativeInstance()
{
    if (weaponReference != none) {
        return KFWeapon(weaponReference.Get());
    }
    return none;
}

public function array<Text> GetTags()
{
    local array<Text> tagArray;
    if (weaponReference == none)        return tagArray;
    if (weaponReference.Get() == none)  return tagArray;

    tagArray[0] = P("weapon").Copy();
    tagArray[1] = P("visible").Copy();
    return tagArray;
}

public function bool HasTag(BaseText tagToCheck)
{
    if (tagToCheck == none)                 return false;
    if (tagToCheck.Compare(P("weapon")))    return true;
    if (tagToCheck.Compare(P("visible")))   return true;

    return false;
}

public function Text GetTemplate()
{
    local Weapon weapon;
    if (weaponReference == none)    return none;
    weapon = Weapon(weaponReference.Get());
    if (weapon == none)             return none;

    return _.text.FromString(Locs(string(weapon.class)));
}

public function Text GetName()
{
    local Weapon weapon;
    if (weaponReference == none)    return none;
    weapon = Weapon(weaponReference.Get());
    if (weapon == none)             return none;

    return _.text.FromString(weapon.GetHumanReadableName());
}

public function bool IsRemovable()
{
    local KFWeapon kfWeapon;    //  Check is only meaningful for `KFWeapon`s
    if (weaponReference == none)    return false;
    kfWeapon = KFWeapon(weaponReference.Get());
    if (kfWeapon == none)           return false;

    return !kfWeapon.bKFNeverThrow;
}

public function bool IsSellable()
{
    return IsRemovable();
}

public function bool SetPrice(int newPrice)
{
    local KFWeapon kfWeapon;    //  Price is only meaningful for `KFWeapon`s
    if (weaponReference == none)    return false;
    kfWeapon = KFWeapon(weaponReference.Get());
    if (kfWeapon == none)           return false;

    kfWeapon.sellValue = newPrice;
    return true;
}

public function int GetPrice()
{
    local KFWeapon kfWeapon;    //  Price is only meaningful for `KFWeapon`s
    if (weaponReference == none)    return 0;
    kfWeapon = KFWeapon(weaponReference.Get());
    if (kfWeapon == none)           return 0;

    return kfWeapon.sellValue;
}

public function bool SetWeight(int newWeight)
{
    local KFWeapon kfWeapon;    //  Weight is only meaningful for `KFWeapon`s
    if (weaponReference == none)    return false;
    kfWeapon = KFWeapon(weaponReference.Get());
    if (kfWeapon == none)           return false;

    kfWeapon.weight = newWeight;
    return true;
}

public function int GetWeight()
{
    local KFWeapon kfWeapon;    //  Weight is only meaningful for `KFWeapon`s
    if (weaponReference == none)    return 0;
    kfWeapon = KFWeapon(weaponReference.Get());
    if (kfWeapon == none)           return 0;

    return int(kfWeapon.weight);
}

public function array<EAmmo> GetAvailableAmmo()
{
    local EAmmo                 nextAmmo;
    local KFWeapon              kfWeapon;
    local Inventory             nextInventory;
    local array<EAmmo>          result;
    local class<Ammunition>     ammoClass1, ammoClass2;
    if (weaponReference == none)    return result;
    kfWeapon = KFWeapon(weaponReference.Get());
    if (kfWeapon == none)           return result;
    if (kfWeapon.owner == none)     return result;

    ammoClass1 = _server.unreal.inventory.GetAmmoClass(kfWeapon, 0);
    ammoClass2 = _server.unreal.inventory.GetAmmoClass(kfWeapon, 1);
    nextInventory = kfWeapon.owner.inventory;
    while (nextInventory != none)
    {
        if (    nextInventory.class == ammoClass1
            ||  nextInventory.class == ammoClass2)
        {
            nextAmmo = class'EKFAmmo'.static.Wrap(Ammunition(nextInventory));
            if (nextAmmo != none) {
                result[result.length] = nextAmmo;
            }
            //  Reset temporary variable to avoid adding same `EKFAmmo` twice
            nextAmmo = none;
        }
        nextInventory = nextInventory.inventory;
    }
    result = AddSpecialAmmo(kfWeapon, result);
    return result;
}

private function array<EAmmo> AddSpecialAmmo(
    KFWeapon        kfWeapon,
    array<EAmmo>    ammoCollection)
{
    local EAmmo         nextAmmo;
    local KFMedicGun    kfMedicWeapon;
    if (kfWeapon == none) {
        return ammoCollection;
    }
    kfMedicWeapon = KFMedicGun(kfWeapon);
    if (kfMedicWeapon != none)
    {
        nextAmmo = class'EKFMedicAmmo'.static.Wrap(kfMedicWeapon);
        if (nextAmmo != none) {
            ammoCollection[ammoCollection.length] = nextAmmo;
        }
    }
    if (HasFlashlight(kfWeapon))
    {
        nextAmmo =
            class'EKFFlashlightAmmo'.static.Wrap(KFHumanPawn(kfWeapon.owner));
        if (nextAmmo != none) {
            ammoCollection[ammoCollection.length] = nextAmmo;
        }
    }
    if (kfWeapon.class == class'KFMod.Syringe')
    {
        nextAmmo =
            class'EKFSyringeAmmo'.static.Wrap(Syringe(kfWeapon));
        if (nextAmmo != none) {
            ammoCollection[ammoCollection.length] = nextAmmo;
        }
    }
    return ammoCollection;
}

private function bool HasFlashlight(KFWeapon weapon)
{
    local int i;
    if (weapon == none) {
        return false;
    }
    for (i = 0; i < weaponsWithFlashlight.length; i += 1)
    {
        if (weapon.class == weaponsWithFlashlight[i]) {
            return true;
        }
    }
    return false;
}

defaultproperties
{
    weaponsWithFlashlight(0) = class'Single'
    weaponsWithFlashlight(1) = class'Dualies'
    weaponsWithFlashlight(2) = class'Shotgun'
    weaponsWithFlashlight(3) = class'CamoShotgun'
    weaponsWithFlashlight(4) = class'NailGun'
    weaponsWithFlashlight(5) = class'BenelliShotgun'
    weaponsWithFlashlight(6) = class'GoldenBenelliShotgun'
}