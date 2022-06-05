/**
 *      Low-level API that provides set of utility methods for working with
 *  unreal script inventory classes, including some Killing Floor specific
 *  methods that depend on how its weapons work.
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
class InventoryAPI extends AcediaObject
    config(AcediaSystem);

/**
 *  Describes a single-dual weapons class pair.
 *  For example,    `single = class'MK23Pickup'` and
 *                  `dual = class'DualMK23Pickup'`.
 */
struct DualiesPair
{
    var class<KFWeaponPickup>   single;
    var class<KFWeaponPickup>   dual;
};
//  All dual pairs that Acedia will recognize
var private const config array<DualiesPair> dualiesClasses;

/**
 *  Describe the role of the weapon regarding a dual wielding.
 *  All weapons have a dual wielding role, although for most it
 *  is simply `DWR_None`.
 */
enum DualWieldingRole
{
    //  Not a dual weapons and cannot be dual wielded;
    //  Most weapons are in this category (e.g. lar, ak47, husk cannon, etc.)
    DWR_None,
    //  Not a dual weapon, but can be dual wielded (e.g. single pistols)
    DWR_Single,
    //  A dual weapon, consisted of two single ones (e.g. dual pistols)
    DWR_Dual
};

/**
 *      Returns array of single - dual pairs (`DualiesPair`) that defines which
 *  single weapon class corresponds to which dual class.
 *      For example, `KFMod.GoldenDeaglePickup` is a single class corresponding
 *  to the `KFMod.GoldenDualDeaglePickup` dual class.
 */
public function array<DualiesPair> GetDualiesPairs()
{
    return dualiesClasses;
}

/**
 *  Returns dual wielding role of the given class of weapon `weaponClass`.
 *  See `DualWieldingRole` enum for more details.
 *
 *  @param  weaponClass Weapon class to check the role for.
 *  @return Dual wielding role of the weapon of given class `weaponClass`.
 *      `DWR_None` in case given `weaponClass` is `none`.
 */
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

/**
 *  For "dual" weapons (`DWR_Dual`), corresponding of two "single" version
 *  returns class of corresponding single version, for any other
 *  (including single weapons themselves) returns `none`.
 *
 *  @param  weaponClass Weapon class for which to find matching single class.
 *  @return Single class that corresponds to the given `weaponClass`, if it is
 *      classified as `DWR_Dual`. `none` for every other class.
 */
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

/**
 *  For "single" weapons (`DWR_Single`) that can have a "dual" version returns
 *  class of corresponding dual version, for any other (including dual weapons
 *  themselves) returns `none`.
 *
 *  @param  weaponClass Weapon class for which to find matching dual class.
 *  @return Dual class that corresponds to the given `weaponClass`, if it is
 *      classified as `DWR_Single`. `none` for every other class.
 */
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

/**
 *  Convenience method for finding a first inventory entry of the given
 *  class `inventoryClass` in the given inventory chain `inventoryChain`.
 *
 *  Inventory is stored as a linked list, where next inventory item is available
 *  through the `inventory` reference. This method follows this list, starting
 *  from `inventoryChain` until it finds `Inventory` of the appropriate class
 *  or reaches the end of the list.
 *
 *  @param  inventoryClass      Class of the inventory we are interested in.
 *  @param  inventoryChain      Inventory chain in which we should search for
 *      the given class.
 *  @param  acceptChildClass    `true` if method should also return any
 *      `Inventory` of class derived from `inventoryClass` and `false` if
 *      we want given class specifically (default).
 *  @return First inventory from `inventoryChain` that matches given
 *      `inventoryClass` class (whether exactly or as a child class,
 *      in case `acceptChildClass == true`).
 */
public final function Inventory Get(
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

/**
 *  Convenience method for finding all inventory entries of the given
 *  class `inventoryClass` in the given inventory chain `inventoryChain`.
 *
 *  Inventory is stored as a linked list, where next inventory item is available
 *  through the `inventory` reference. This method follows this list, starting
 *  from `inventoryChain` until the end of the list.
 *
 *  @param  inventoryClass      Class of the inventory we are interested in.
 *  @param  inventoryChain      Inventory chain in which we should search for
 *      the given class.
 *  @param  acceptChildClass    `true` if method should also return any
 *      `Inventory` of class derived from `inventoryClass` and `false` if
 *      we want given class specifically (default).
 *  @return Array of inventory items from `inventoryChain` that match given
 *      `inventoryClass` class (whether exactly or as a child class,
 *      in case `acceptChildClass == true`).
 */
public final function array<Inventory> GetAll(
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

/**
 *  Checks whether `inventory` is contained in the inventory given by
 *  `inventoryChain`.
 *
 *  @param  inventory       Item we are searching for.
 *  @param  inventoryChain  Inventory chain in which we should search for
 *      the given item.
 *  @return `true` if `inventoryChain` contains `inventory` and
 *      `false` otherwise.
 */
public final function bool Contains(
    Inventory inventory,
    Inventory inventoryChain)
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

/**
 *      Returns a root pickup class.
 *  For non-dual weapons, root class is defined as either:
 *      1. The first variant (reskin), if there are variants for that weapon;
 *      2. And as the class itself, if there are no variants.
 *          For dual weapons (all dual pistols) root class is defined as
 *          a root of their single version.
 *
 *  This definition is useful because:
 *      1. Vanilla game rules are such that player can only have two weapons
 *          in the inventory if they have different roots;
 *      2. Root is easy to find.
 *
 *  @param  weaponClass Weapon class for which we must find root class.
 *  @return Root class for the provided `weaponClass` class.
 *      If `weaponClass` is `none`, method will also return `none`.
*/
public final function class<KFWeaponPickup> GetRootPickupClass(
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

/**
 *  Convenience method for finding a first inventory entry with the same root as
 *  class `inventoryClass` in the given inventory chain `inventoryChain`.
 *  For information of what a "root" is, see `GetRootPickupClass()`.
 *
 *  Inventory is stored as a linked list, where next inventory item is available
 *  through the `inventory` reference. This method follows this list, starting
 *  from `inventoryChain` until it finds `Inventory` of the appropriate class
 *  or reaches the end of the list.
 *
 *  @param  inventoryClass  Class of the inventory we are interested in.
 *  @param  inventoryChain  Inventory chain in which we should search for
 *      the given class.
 *  @return First inventory from `inventoryChain` that has the same root as
 *      given `inventoryClass` class.
 */
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

/**
 *  Convenience method for finding all inventory entries with the same root as
 *  class `inventoryClass` in the given inventory chain `inventoryChain`.
 *  For information of what a "root" is, see `GetRootPickupClass()`.
 *
 *  Inventory is stored as a linked list, where next inventory item is available
 *  through the `inventory` reference. This method follows this list, starting
 *  from `inventoryChain` until the end of the list.
 *
 *  @param  inventoryClass  Class of the inventory we are interested in.
 *  @param  inventoryChain  Inventory chain in which we should search for
 *      the given class.
 *  @return Array of inventory items from `inventoryChain` that have the same
 *      root as given `inventoryClass` class.
 */
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

/**
 *  Returns ammunition class for the given `weapon` weapon, that it uses for
 *  fire mode numbered `modeNumber`.
 *
 *  @param  weapon      Weapon for which ammunition class should be found.
 *  @param  modeNumber  Fire mode for which ammunition class should be found.
 *  @return Class of ammunition used for `weapon`'s fire mode,
 *      numbered `modeNumber`.
 *      `none` if `weapon` is `none`, fire mode does not exist or
 *      it is not associated with inventory ammo class.
 */
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

/**
 *  Removes all ammo from the given `weapon`. Assumes weapons has no more than
 *  two fire modes.
 *
 *  In case given weapon is a child class of `KFWeapon`, also clears its
 *  magazine counter.
 *
 *  @param  weapon  Weapon to remove all ammo from. If `none`,
 *      method does nothing.
 */
public final function ClearAmmo(Weapon weapon)
{
    local InventoryService service;
    service = InventoryService(class'InventoryService'.static.Require());
    if (service != none) {
        service.ClearAmmo(weapon);
    }
}

/**
 *  Creates and adds a weapons of the given class to the `pawn` with specified
 *  amount of ammunition.
 *
 *  @param  pawn                `Pawn` to which we should add new weapon.
 *      If `none` - method does nothing.
 *  @param  weaponClassToAdd    Class of the weapon we need to add.
 *      If `none` - method does nothing.
 *  @param  totalAmmoPrimary    Ammo to add to the primary fire.
 *  @param  totalAmmoSecondary  Ammo to add to the secondary fire.
 *  @param  magazineAmmo        Ammo to add to the new weapon's magazine count.
 *      Only relevant if `weaponClassToAdd` is a child class of `KFWeapon` and
 *      otherwise ignored.
 *  @param  clearStarterAmmo    Newly created weapons usually come with some
 *      default amount of ammo. Setting this flag to `true` will remove it
 *      before adding `totalAmmoPrimary`, `totalAmmoSecondary` and
 *      `magazineAmmo`.
 *  @return Instance of the newly created weapon. `none` in case of failure or
 *      if created weapon was destroyed in the process of adding it to
 *      the `pawn` (can happen as a result of interaction with preexisting
 *      weapons - e.g. pistol can merge with another one of the same type and
 *      produce a new weapon).
 */
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

/**
 *  Auxiliary method for "merging" weapons. Basically acts as
 *  a `AddWeaponWithAmmo()` - creates and adds a weapons of the given class to
 *  the `pawn`. But instead of taking numeric parameters to specify starter
 *  ammunition, copies ammunition counts (adding them together) from two weapons
 *  (`weaponToMerge1` and `weaponToMerge2`) specified for "merging"
 *
 *  @param  pawn            `Pawn` to which we should add new merged weapon.
 *      If `none` - method does nothing.
 *  @param  mergedClass     Class of the weapon we need to add as a result
 *      of "merging". If `none` - method does nothing.
 *  @param  weaponToMerge1  First weapon from which to copy ammunition counts.
 *      In case it is of a child class of `KFWeapon`, also copies magazine size.
 *      If `none` - assumes all ammo counts to be zero. 
 *  @param  weaponToMerge2  Second weapon from which to copy ammunition counts.
 *      Completely interchangeable with `weaponToMerge1`.
 *  @param  clearStarterAmmo    Newly created weapons usually come with some
 *      default amount of ammo. Setting this flag to `true` will remove it
 *      before adding ammunition counts from `weaponToMerge1` and
 *      `weaponToMerge2`.
 *  @return Instance of the newly created weapon. `none` in case of failure or
 *      if created weapon was destroyed in the process of adding it to
 *      the `pawn` (can happen as a result of interaction with preexisting
 *      weapons - e.g. pistol can merge with another one of the same type and
 *      produce a new weapon).
 */
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