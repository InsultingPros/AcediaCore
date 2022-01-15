/**
 *  Implementation of `EItem` for classic Killing Floor weapons that changes
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
class EKFWeapon extends EItem
    abstract;

var private NativeActorRef weaponReference;

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
    newReference = EKFWeapon(__().memory.Allocate(class'EKFWeapon'));
    newReference.weaponReference = __().unreal.ActorRef(weaponInstance);
    return newReference;
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
    return tagArray;
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

    return _.text.FromString(Locs(weapon.itemName));
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

defaultproperties
{
}