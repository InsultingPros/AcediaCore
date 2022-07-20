/**
 *  Acedia's default implementation for `InventoryAPI`.
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
class KF1_InventoryAPI extends InventoryAPI
    config(AcediaSystem);

public function array<DualiesPair> GetDualiesPairs()
{
    return dualiesClasses;
}

public function DualWieldingRole GetDualWieldingRole(
    class<KFWeapon> weaponClass)
{
    local int                   i;
    local class<KFWeaponPickup> pickupClass;

    if (weaponClass == none) return DWR_None;
    pickupClass = class<KFWeaponPickup>(weaponClass.default.pickupClass);
    if (pickupClass == none) return DWR_None;

    for (i = 0; i < dualiesClasses.length; i += 1)
    {
        if (dualiesClasses[i].single == pickupClass) {
            return DWR_Single;
        }
        if (dualiesClasses[i].dual == pickupClass) {
            return DWR_Dual;
        }
    }
    return DWR_None;
}

public function class<KFWeapon> GetSingleClass(class<KFWeapon> weapon)
{
    local int                   i;
    local class<KFWeaponPickup> pickupClass;
    local class<KFWeaponPickup> singlePickupClass;

    if (weapon == none)         return none;
    pickupClass = class<KFWeaponPickup>(weapon.default.pickupClass);
    if (pickupClass == none)    return none;

    for (i = 0; i < dualiesClasses.length; i += 1)
    {
        if (dualiesClasses[i].dual == pickupClass)
        {
            singlePickupClass = dualiesClasses[i].single;
            if (singlePickupClass != none) {
                return class<KFWeapon>(singlePickupClass.default.inventoryType);
            }
        }
    }
    return none;
}

public function class<KFWeapon> GetDualClass(class<KFWeapon> weaponClass)
{
    local int                   i;
    local class<KFWeaponPickup> pickupClass;
    local class<KFWeaponPickup> dualPickupClass;

    if (weaponClass == none)    return none;
    pickupClass = class<KFWeaponPickup>(weaponClass.default.pickupClass);
    if (pickupClass == none)    return none;

    for (i = 0; i < dualiesClasses.length; i += 1)
    {
        if (dualiesClasses[i].single == pickupClass)
        {
            dualPickupClass = dualiesClasses[i].dual;
            if (dualPickupClass != none) {
                return class<KFWeapon>(dualPickupClass.default.inventoryType);
            }
        }
    }
    return none;
}

public function Inventory Get(
    class<Inventory>    inventoryClass,
    Inventory           inventoryChain,
    optional bool       acceptChildClass)
{
    if (inventoryClass == none) {
        return none;
    }
    while (inventoryChain != none)
    {
        if (inventoryChain.class == inventoryClass) {
            return inventoryChain;
        }
        if (    acceptChildClass
            &&  ClassIsChildOf(inventoryChain.class, inventoryClass))
        {
            return inventoryChain;
        }
        inventoryChain = inventoryChain.inventory;
    }
    return none;
}

public function array<Inventory> GetAll(
    class<Inventory>    inventoryClass,
    Inventory           inventoryChain,
    optional bool       acceptChildClass)
{
    local bool              shouldAdd;
    local array<Inventory>  result;

    if (inventoryClass == none) {
        return result;
    }
    while (inventoryChain != none)
    {
        shouldAdd = false;
        if (inventoryChain.class == inventoryClass) {
            shouldAdd = true;
        }
        else if (acceptChildClass) {
            shouldAdd = ClassIsChildOf(inventoryChain.class, inventoryClass);
        }
        if (shouldAdd) {
            result[result.length] = inventoryChain;
        }
        inventoryChain = inventoryChain.inventory;
    }
    return result;
}

public function bool Contains(Inventory inventory, Inventory inventoryChain)
{
    while (inventoryChain != none)
    {
        if (inventoryChain == inventory) {
            return true;
        }
        inventoryChain = inventoryChain.inventory;
    }
    return false;
}

public function class<KFWeaponPickup> GetRootPickupClass(
    class<KFWeapon> weaponClass)
{
    local int                   i;
    local class<KFWeaponPickup> root;

    if (weaponClass == none)    return none;
    //  Start with a pickup of the given weapons
    root = class<KFWeaponPickup>(weaponClass.default.pickupClass);
    if (root == none)           return none;

    //      In case it's a dual version - find corresponding single pickup class
    //  (it's root would be the same).
    for (i = 0; i < dualiesClasses.length; i += 1)
    {
        if (dualiesClasses[i].dual == root)
        {
            root = dualiesClasses[i].single;
            break;
        }
    }
    //      Take either first variant class or the class itself -
    //  it's going to be root by definition
    if (root != none && root.default.variantClasses.length > 0) {
        root = class<KFWeaponPickup>(root.default.variantClasses[0]);
    }
    return root;
}

public function KFWeapon GetByRoot(
    class<KFWeapon> inventoryClass,
    Inventory       inventoryChain)
{
    local class<KFWeapon>       nextWeaponClass;
    local class<KFWeaponPickup> itemRoot, nextRoot;

    itemRoot = GetRootPickupClass(inventoryClass);
    if (itemRoot == none) {
        return none;
    }
    while (inventoryChain != none)
    {
        nextWeaponClass = class<KFWeapon>(inventoryChain.class);
        nextRoot = GetRootPickupClass(nextWeaponClass);
        if (itemRoot == nextRoot) {
            return KFWeapon(inventoryChain);
        }
        inventoryChain = inventoryChain.inventory;
    }
    return none;
}

public function array<KFWeapon> GetAllByRoot(
    class<KFWeapon> inventoryClass,
    Inventory       inventoryChain)
{
    local array<KFWeapon>       result;
    local KFWeapon              nextWeapon;
    local class<KFWeapon>       nextWeaponClass;
    local class<KFWeaponPickup> itemRoot, nextRoot;

    itemRoot = GetRootPickupClass(inventoryClass);
    if (itemRoot == none) {
        return result;
    }
    while (inventoryChain != none)
    {
        nextWeaponClass = class<KFWeapon>(inventoryChain.class);
        nextRoot = GetRootPickupClass(nextWeaponClass);
        if (itemRoot == nextRoot) {
            nextWeapon = KFWeapon(inventoryChain);
        }
        if (nextWeapon != none)
        {
            result[result.length] = nextWeapon;
            nextWeapon = none;
        }
        inventoryChain = inventoryChain.inventory;
    }
    return result;
}

public function class<Ammunition> GetAmmoClass(Weapon weapon, int modeNumber)
{
    local WeaponFire relevantWeaponFire;

    if (weapon == none) {
        return none;
    }
    //  Just use majestic rjp's hack method `GetFireMode()` to get ammo class
    //  through a weapon fire
    relevantWeaponFire = weapon.GetFireMode(modeNumber);
    if (relevantWeaponFire != none) {
        return relevantWeaponFire.ammoClass;
    }
    return none;
}

public function ClearAmmo(Weapon weapon)
{
    local InventoryService service;

    service = InventoryService(class'InventoryService'.static.Require());
    if (service != none) {
        service.ClearAmmo(weapon);
    }
}

public function Weapon AddWeaponWithAmmo(
    Pawn            pawn,
    class<Weapon>   weaponClassToAdd,
    optional int    totalAmmoPrimary,
    optional int    totalAmmoSecondary,
    optional int    magazineAmmo,
    optional bool   clearStarterAmmo)
{
    local InventoryService service;

    service = InventoryService(class'InventoryService'.static.Require());
    if (service == none) {
        return none;
    }
    return service.AddWeaponWithAmmo(   pawn, weaponClassToAdd,
                                        totalAmmoPrimary, totalAmmoSecondary,
                                        magazineAmmo, clearStarterAmmo);
}

public function Weapon MergeWeapons(
    Pawn            ownerPawn,
    class<Weapon>   mergedClass,
    optional Weapon weaponToMerge1,
    optional Weapon weaponToMerge2,
    optional bool   clearStarterAmmo)
{
    local InventoryService service;

    service = InventoryService(class'InventoryService'.static.Require());
    if (service == none) {
        return none;
    }
    return service.MergeWeapons(ownerPawn, mergedClass,
                                weaponToMerge1, weaponToMerge2);
}

defaultproperties
{
    dualiesClasses(0)=(single=class'KFMod.SinglePickup',dual=class'KFMod.DualiesPickup')
    dualiesClasses(1)=(single=class'KFMod.Magnum44Pickup',dual=class'KFMod.Dual44MagnumPickup')
    dualiesClasses(2)=(single=class'KFMod.MK23Pickup',dual=class'KFMod.DualMK23Pickup')
    dualiesClasses(3)=(single=class'KFMod.DeaglePickup',dual=class'KFMod.DualDeaglePickup')
    dualiesClasses(4)=(single=class'KFMod.GoldenDeaglePickup',dual=class'KFMod.GoldenDualDeaglePickup')
    dualiesClasses(5)=(single=class'KFMod.FlareRevolverPickup',dual=class'KFMod.DualFlareRevolverPickup')
}