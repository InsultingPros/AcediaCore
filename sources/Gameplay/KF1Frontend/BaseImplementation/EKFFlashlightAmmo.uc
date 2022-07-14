/**
 *  Implementation of `EAmmo` for Killing Floor's flashlight charge that changes
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
class EKFFlashlightAmmo extends EAmmo;

var private NativeActorRef pawnReference;

protected function Finalizer()
{
    _.memory.Free(pawnReference);
    pawnReference = none;
}

/**
 *  Creates new `EKFFlashlightAmmo` that refers to the `medicWeaponInstance`'s
 *  medic ammunition.
 *
 *  @param  kfHumanPawn Pawn class with flashlight ammo.
 *      In Killing Floor, "flashlight ammo" is basically just a variable
 *      inside `KFHumanPawn` instance.
 *  @return New `EKFFlashlightAmmo` that represents medic ammunition of given
 *      `kfHumanPawn`. `none` iff `kfHumanPawn` is `none`.
 */
public final static /*unreal*/ function EKFFlashlightAmmo Wrap(
    KFHumanPawn kfHumanPawn)
{
    local EKFFlashlightAmmo newReference;
    if (kfHumanPawn == none) {
        return none;
    }
    newReference =
        EKFFlashlightAmmo(__().memory.Allocate(class'EKFFlashlightAmmo'));
    newReference.pawnReference = __server().unreal.ActorRef(kfHumanPawn);
    return newReference;
}

public function EInterface Copy()
{
    local KFHumanPawn pawnInstance;
    pawnInstance = GetNativeInstance();
    return Wrap(pawnInstance);
}

public function bool Supports(class<EInterface> newInterfaceClass)
{
    if (newInterfaceClass == none)                      return false;
    if (newInterfaceClass == class'EItem')              return true;
    if (newInterfaceClass == class'EAmmo')              return true;
    if (newInterfaceClass == class'EKFFlashlightAmmo')  return true;

    return false;
}

public function EInterface As(class<EInterface> newInterfaceClass)
{
    if (!IsExistent()) {
        return none;
    }
    if (    newInterfaceClass == class'EItem'
        ||  newInterfaceClass == class'EAmmo'
        ||  newInterfaceClass == class'EKFFlashlightAmmo')
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
    local EKFFlashlightAmmo otherAmmo;
    otherAmmo = EKFFlashlightAmmo(other);
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
public final /*unreal*/ function KFHumanPawn GetNativeInstance()
{
    if (pawnReference != none) {
        return KFHumanPawn(pawnReference.Get());
    }
    return none;
}

public function array<Text> GetTags()
{
    local array<Text> tagArray;
    if (pawnReference == none)       return tagArray;
    if (pawnReference.Get() == none) return tagArray;

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
    if (IsExistent()) {
        return P("flashlight:ammo").Copy();
    }
    return none;
}

public function Text GetName()
{
    if (IsExistent()) {
        return P("Flashlight's ammo").Copy();
    }
    return none;
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
    local KFHumanPawn kfHumanPawn;
    kfHumanPawn = GetNativeInstance();
    if (kfHumanPawn == none) {
        return;
    }
    if (forceAddition) {
        kfHumanPawn.torchBatteryLife += amount;
    }
    else
    {
        kfHumanPawn.torchBatteryLife =
            Min(    kfHumanPawn.default.torchBatteryLife,
                    kfHumanPawn.torchBatteryLife + amount);
    }
    //  Correct possible negative values
    if (kfHumanPawn.torchBatteryLife < 0) {
        kfHumanPawn.torchBatteryLife = 0;
    }
}

public function int GetAmount()
{
    local KFHumanPawn kfHumanPawn;
    kfHumanPawn = GetNativeInstance();
    if (kfHumanPawn == none) {
        return 0;
    }
    return Max(0, kfHumanPawn.torchBatteryLife);
}

public function int GetTotalAmount()
{
    return GetAmount();
}

public function SetAmount(int amount, optional bool forceAddition)
{
    local KFHumanPawn kfHumanPawn;
    kfHumanPawn = GetNativeInstance();
    if (kfHumanPawn == none) {
        return;
    }
    if (forceAddition) {
        kfHumanPawn.torchBatteryLife = amount;
    }
    else
    {
        kfHumanPawn.torchBatteryLife =
            Min(kfHumanPawn.default.torchBatteryLife, amount);
    }
    //  Correct possible negative values
    if (kfHumanPawn.torchBatteryLife < 0) {
        kfHumanPawn.torchBatteryLife = 0;
    }
}

public function int GetMaxAmount()
{
    local KFHumanPawn kfHumanPawn;
    kfHumanPawn = GetNativeInstance();
    if (kfHumanPawn == none) {
        return 0;
    }
    return Max(0, kfHumanPawn.default.torchBatteryLife);
}

public function int GetMaxTotalAmount()
{
    return GetMaxAmount();
}

public function bool SetMaxAmount(
    int             newMaxAmmo,
    optional bool   leaveCurrentAmmo)
{
    local KFHumanPawn kfHumanPawn;
    //  We do not support unlimited ammo values
    if (newMaxAmmo < 0)         return false;
    kfHumanPawn = GetNativeInstance();
    if (kfHumanPawn == none)    return false;

    kfHumanPawn.default.torchBatteryLife = newMaxAmmo;
    if (!leaveCurrentAmmo)
    {
        kfHumanPawn.torchBatteryLife =
            Min(    kfHumanPawn.default.torchBatteryLife,
                    kfHumanPawn.torchBatteryLife);
    }
    return true;
}

public function bool SetMaxTotalAmount(
    int             newTotalMaxAmmo,
    optional bool   leaveCurrentAmmo)
{
    return SetMaxAmount(newTotalMaxAmmo, leaveCurrentAmmo);
}

public function bool HasWeapon()
{
    return (GetNativeInstance() != none);
}

defaultproperties
{
}