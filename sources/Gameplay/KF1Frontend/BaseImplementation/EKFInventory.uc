/**
 *  Player's inventory implementation for classic Killing Floor that changes
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
class EKFInventory extends EInventory
    config(AcediaSystem_KF1Frontend);

struct DualiesPair
{
    var class<KFWeaponPickup>   single;
    var class<KFWeaponPickup>   dual;
};

var private EPlayer                     inventoryOwner;
var private config array<DualiesPair>   dualiesClasses;

protected function Finalizer()
{
    _.memory.Free(inventoryOwner);
    inventoryOwner = none;
}

public function Initialize(EPlayer player)
{
    if (inventoryOwner != none) {
        return;
    }
    if (player != none) {
        inventoryOwner = EPlayer(player.Copy());
    }
}

private function Pawn GetOwnerPawn()
{
    local PlayerController myController;
    myController = inventoryOwner.GetController();
    if (myController == none) {
        return none;
    }
    return myController.pawn;
}

//  TODO: needs more testing
public function bool Add(EItem newItem, optional bool forceAddition)
{
    local Pawn              pawn;
    local EKFWeapon         kfWeaponItem;
    local KFWeapon          kfWeapon;
    local class<KFWeapon>   dualClass;
    local Inventory         collidingItem;
    if (!CanAdd(newItem, forceAddition))    return false;
    kfWeaponItem = EKFWeapon(newItem);
    if (kfWeaponItem == none)               return false;
    pawn = GetOwnerPawn();
    if (pawn == none)                       return false;
    kfWeapon = kfWeaponItem.GetNativeInstance();
    if (kfWeapon == none)                   return false;

    dualClass = GetDualClass(kfWeapon.class);
    if (dualClass != none)
    {
        collidingItem = FindSkinnedInventory(pawn, kfWeapon.class);
        if (collidingItem != none)
        {
            collidingItem.Destroyed();
            collidingItem.Destroy();
        }
        kfWeapon.Destroy();
        kfWeapon = KFWeapon(_.memory.Allocate(dualClass));
        if (kfWeapon != none) {
            _.unreal.GetKFGameType().WeaponSpawned(kfWeapon);
        }
        else {
            return false;
        }
    }
    kfWeapon.GiveTo(pawn);
    return true;
}

public function bool AddTemplate(
    Text            newItemTemplate,
    optional bool   forceAddition)
{
    local Pawn              pawn;
    local KFWeapon          newWeapon;
    local class<KFWeapon>   newWeaponClass;
    local class<KFWeapon>   dualClass;
    local KFWeapon          collidingWeapon;
    local int               totalAmmo, magazineAmmo;
    if (newItemTemplate == none)                            return false;
    if (!CanAddTemplate(newItemTemplate, forceAddition))    return false;
    pawn = GetOwnerPawn();
    if (pawn == none)                                       return false;

    newWeaponClass = class<KFWeapon>(_.memory.LoadClass(newItemTemplate));
    if (newWeaponClass != none) {
        dualClass = GetDualClass(newWeaponClass);
    }
    if (dualClass != none)
    {
        collidingWeapon = FindSkinnedInventory(pawn, newWeaponClass);
        if (collidingWeapon != none)
        {
            totalAmmo       = collidingWeapon.AmmoAmount(0);
            magazineAmmo    = collidingWeapon.magAmmoRemaining;
            collidingWeapon.Destroyed();
            collidingWeapon.Destroy();
            newWeaponClass = dualClass;
        }
    }
    newWeapon = KFWeapon(_.memory.Allocate(newWeaponClass));
    if (newWeapon != none)
    {
        _.unreal.GetKFGameType().WeaponSpawned(newWeapon);
        newWeapon.GiveTo(pawn);
        if (totalAmmo > 0) {
            newWeapon.AddAmmo(totalAmmo, 0);
        }
        newWeapon.magAmmoRemaining += magazineAmmo;
        return true;
    }
    return false;
}

public function bool CanAdd(EItem itemToCheck, optional bool forceAddition)
{
    local EKFWeapon kfWeaponItem;
    local KFWeapon  kfWeapon;
    kfWeaponItem = EKFWeapon(itemToCheck);
    if (kfWeaponItem == none)   return false;   // can only add weapons
    kfWeapon = kfWeaponItem.GetNativeInstance();
    if (kfWeapon == none)       return false;   // dead `EKFWeapon` object

    return CanAddWeaponClass(kfWeapon.class, forceAddition);
}

public function bool CanAddTemplate(
    Text            itemTemplateToCheck,
    optional bool   forceAddition)
{
    local class<KFWeapon> kfWeaponClass;
    //  Can only add weapons for now
    kfWeaponClass = class<KFWeapon>(_.memory.LoadClass(itemTemplateToCheck));
    return CanAddWeaponClass(kfWeaponClass, forceAddition);
}

private function bool CanAddWeaponClass(
    class<KFWeapon> kfWeaponClass,
    optional bool   forceAddition)
{
    local KFPawn    kfPawn;
    local Inventory collidingItem;
    if (kfWeaponClass == none)  return false;
    kfPawn = KFPawn(GetOwnerPawn());
    if (kfPawn == none)         return false;
    
    if (!forceAddition && !kfPawn.CanCarry(kfWeaponClass.default.weight)) {
        return false;
    }
    if (!forceAddition && HasSameTypeWeapons(kfWeaponClass, kfPawn))
    {
        if (GetDualClass(kfWeaponClass) != none) {
            collidingItem = FindSkinnedInventory(kfPawn, kfWeaponClass);
        }
        return (collidingItem != none);
    }
    return true;
}

private function bool HasSameTypeWeapons(
    class<KFWeapon> kfWeaponClass,
    Pawn            pawn)
{
    local Inventory             nextInventory;
    local class<KFWeaponPickup> itemRoot, nextRoot;
    nextInventory = pawn.inventory;
    itemRoot = GetRootPickupClass(kfWeaponClass);
    while (nextInventory != none)
    {
        nextRoot = GetRootPickupClass(class<KFWeapon>(nextInventory.class));
        if (itemRoot == nextRoot) {
            return true;
        }
        nextInventory = nextInventory.inventory;
    }
    return false;
}

//  For "single" weapons that can have a "dual" version returns class of
//  corresponding dual version, for any other
//  (including dual weapons themselves) returns `none`.
private final function class<KFWeapon> GetDualClass(class<KFWeapon> weapon)
{
    local int                   i;
    local class<KFWeaponPickup> pickupClass;
    local class<KFWeaponPickup> dualPickupClass;
    if (weapon == none)         return none;
    pickupClass = class<KFWeaponPickup>(weapon.default.pickupClass);
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

//      Returns inventory type of class `desiredClass` if it exists in
//  `pawn`'s inventory.
//      Unlike `Pawn`'s `FindInventoryType()` method, this one will find
//  inventory type in case it corresponds to the different (weapon's) skin by
//  comparing first item of `KFWeaponPickup`'s `variantClasses`.
private function KFWeapon FindSkinnedInventory(
    Pawn            pawn,
    class<KFWeapon> desiredClass)
{
    local Inventory             nextInv;
    local class<Pickup>         rootVariant;
    local class<KFWeaponPickup> nextPickupClass, desiredPickupClass;
    if (desiredClass == none)   return none;
    if (pawn == none)           return none;

    desiredPickupClass = class<KFWeaponPickup>(desiredClass.default.pickupClass);
    if (    desiredPickupClass != none
        &&  desiredPickupClass.default.variantClasses.length > 0)
    {
        rootVariant = desiredPickupClass.default.variantClasses[0];
    }
    for (nextInv = pawn.inventory; nextInv != none; nextInv = nextInv.inventory)
    {
        if (nextInv.class == desiredClass) {
            return KFWeapon(nextInv);
        }
        //  Variant check
        if (rootVariant == none)                                continue;
        nextPickupClass = class<KFWeaponPickup>(nextInv.pickupClass);
        if (nextPickupClass == none)                            continue;
        if (nextPickupClass.default.variantClasses.length <= 0) continue;
        if (rootVariant == nextPickupClass.default.variantClasses[0]) {
            return KFWeapon(nextInv);
        }
    }
    return none;
}

//      Returns a root pickup class.
//  For non-dual weapons, root class is defined as either:
//      1. the first variant (reskin), if there are variants for that weapon;
//      2. and as the class itself, if there are no variants.
//  For dual weapons (all dual pistols) root class is defined as
//  a root of their single version.
//      This definition is useful because:
//      ~ Vanilla game rules are such that player can only have two weapons
//      in the inventory if they have different roots;
//      ~ Root is easy to find.
private final function class<KFWeaponPickup> GetRootPickupClass(
    class<KFWeapon> weapon)
{
    local int                   i;
    local class<KFWeaponPickup> root;
    if (weapon == none) return none;
    //  Start with a pickup of the given weapons
    root = class<KFWeaponPickup>(weapon.default.pickupClass);
    if (root == none)   return none;

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
    //      Take either first variant class or the class itself, -
    //  it's going to be root by definition.
    if (root.default.variantClasses.length > 0) {
        root = class<KFWeaponPickup>(root.default.variantClasses[0]);
    }
    return root;
}

public function bool Remove(
    EItem           itemToRemove,
    optional bool   keepItem,
    optional bool   forceRemoval)
{
    local bool      removedItem;
    local float     passedTime;
    local Pawn      pawn;
    local Inventory nextInventory;
    local EKFWeapon kfWeaponItem;
    local KFWeapon  kfWeapon;
    kfWeaponItem = EKFWeapon(itemToRemove);
    if (kfWeaponItem == none)                       return false;
    pawn = GetOwnerPawn();
    if (pawn == none)                               return false;
    if (pawn.inventory == none)                     return false;
    kfWeapon = kfWeaponItem.GetNativeInstance();
    if (kfWeapon == none)                           return false;
    if (!forceRemoval && kfWeapon.bKFNeverThrow)    return false;

    passedTime = _.unreal.GetLevel().timeSeconds - 1;
    nextInventory = pawn.inventory;
    while (nextInventory.inventory != none)
    {
        if (nextInventory.inventory == kfWeapon)
        {
            nextInventory.inventory     = kfWeapon.inventory;
            kfWeapon.inventory          = none;
            nextInventory.netUpdateTime = passedTime;
            kfWeapon.netUpdateTime      = passedTime;
            kfWeapon.Destroy();
            removedItem = true;
        }
        else {
            nextInventory = nextInventory.inventory;
        }
    }
    return removedItem;
}

public function bool RemoveTemplate(
    Text            itemTemplateToRemove,
    optional bool   keepItem,
    optional bool   forceRemoval,
    optional bool   removeAll)
{
    local bool              canRemoveInventory;
    local bool              removedItem;
    local float             passedTime;
    local Pawn              pawn;
    local Inventory         nextInventory;
    local KFWeapon          nextKFWeapon;
    local class<KFWeapon>   kfWeaponClass;
    pawn = GetOwnerPawn();
    if (pawn == none)                                           return false;
    if (pawn.inventory == none)                                 return false;
    kfWeaponClass = class<KFWeapon>(_.memory.LoadClass(itemTemplateToRemove));
    if (kfWeaponClass == none)                                  return false;
    if (!forceRemoval && kfWeaponClass.default.bKFNeverThrow)   return false;

    passedTime = _.unreal.GetLevel().timeSeconds - 1;
    nextInventory = pawn.inventory;
    while (nextInventory.inventory != none)
    {
        canRemoveInventory = true;
        if (!forceRemoval)
        {
            nextKFWeapon = KFWeapon(nextInventory.inventory);
            if (nextKFWeapon != none && nextKFWeapon.bKFNeverThrow) {
                canRemoveInventory = false;
            }
        }
        if (    canRemoveInventory
            &&  nextInventory.inventory.class == kfWeaponClass)
        {
            nextInventory.inventory     = nextKFWeapon.inventory;
            nextKFWeapon.inventory      = none;
            nextInventory.netUpdateTime = passedTime;
            nextKFWeapon.netUpdateTime  = passedTime;
            nextKFWeapon.Destroy();
            removedItem = true;
            if (!removeAll) {
                return true;
            }
        }
        else {
            nextInventory = nextInventory.inventory;
        }
    }
    return removedItem;
}

public function bool RemoveAll(
    optional bool keepItems,
    optional bool forceRemoval)
{
    local int               i;
    local Pawn              pawn;
    local KFWeapon          kfWeapon;
    local Inventory         nextInventory;
    local class<Weapon>     destroyedClass;
    local array<Inventory>  inventoryToRemove;
    pawn = GetOwnerPawn();
    if (pawn == none)           return false;
    if (pawn.inventory == none) return false;

    nextInventory = pawn.inventory;
    while (nextInventory != none)
    {
        kfWeapon = KFWeapon(nextInventory);
        if (kfWeapon == none)
        {
            nextInventory = nextInventory.inventory;
            continue; //  TODO: handle non-weapons differently
        }
        if (forceRemoval || !kfWeapon.bKFNeverThrow) {
            inventoryToRemove[inventoryToRemove.length] = nextInventory;
        }
        nextInventory = nextInventory.inventory;
    }
    for(i = 0; i < inventoryToRemove.length; i += 1)
    {
        if (inventoryToRemove[i] == none) {
            continue;
        }
        destroyedClass = class<Weapon>(inventoryToRemove[i].class);
        inventoryToRemove[i].Destroyed();
        inventoryToRemove[i].Destroy();
        _.unreal.GetKFGameType().WeaponDestroyed(destroyedClass);
    }
    return (inventoryToRemove.length > 0);
}

/**
 *  Checks whether caller `EInventory` contains given `itemToCheck`.
 *
 *  @param  itemToCheck `EItem` we want to check for belonging to the caller
 *      `EInventory`.
 *  @result `true` if item does belong to the inventory and `false` otherwise.
 */
public function bool Contains(EItem itemToCheck)
{
    return false;
}

/**
 *  Returns array with all `EItem`s contained inside the caller `EInventory`.
 *
 *  @return Array with all `EItem`s contained inside the caller `EInventory`.
 */
public function array<EItem> GetAllItems()
{
    local array<EItem> emptyArray;
    return emptyArray;
}

/**
 *  Returns array with all `EItem`s contained inside the caller `EInventory`
 *  that has specified tag `tag`.
 *
 *  @param  tag Tag, which items we want to get.
 *  @return Array with all `EItem`s contained inside the caller `EInventory`
 *      that has specified tag `tag`.
 */
public function array<EItem> GetTagItems(Text tag)
{
    local array<EItem> emptyArray;
    return emptyArray;
}

/**
 *  Returns `EItem` contained inside the caller `EInventory` that has specified
 *  tag `tag`.
 *
 *  If several `EItem`s inside caller `EInventory` have specified tag,
 *  inventory system can pick one arbitrarily (can be based on simple
 *  convenience of implementation). Returned value does not have to
 *  be stable (the same after repeated calls).
 *
 *  @param  tag   Tag, which item we want to get.
 *  @return `EItem` contained inside the caller `EInventory` that belongs to
 *      the specified tag `tag`.
 */
public function EItem GetTagItem(Text tag) { return none; }

/**
 *  Returns array with all `EItem`s contained inside the caller `EInventory`
 *  that originated from the specified template `template`.
 *
 *  @param  template    Template, that items we want to get originated from.
 *  @return Array with all `EItem`s contained inside the caller `EInventory`
 *      that originated from the specified template `template`.
 */
public function array<EItem> GetTemplateItems(Text template)
{
    local array<EItem> emptyArray;
    return emptyArray;
}

/**
 *  Returns array with all `EItem`s contained inside the caller `EInventory`
 *  that originated from the specified template `template`.
 *
 *  If several `EItem`s inside caller `EInventory` originated from
 *  that template, inventory system can pick one arbitrarily (can be based on
 *  simple convenience of implementation). Returned value does not have to
 *  be stable (the same after repeated calls).
 *
 *  @param  template    Template, that item we want to get originated from.
 *  @return `EItem`s contained inside the caller `EInventory` that originated
 *      from the specified template `template`.
 */
public function EItem GetTemplateItem(Text template) { return none; }

defaultproperties
{
    dualiesClasses(0)=(single=class'KFMod.SinglePickup',dual=class'KFMod.DualiesPickup')
    dualiesClasses(1)=(single=class'KFMod.Magnum44Pickup',dual=class'KFMod.Dual44MagnumPickup')
    dualiesClasses(2)=(single=class'KFMod.MK23Pickup',dual=class'KFMod.DualMK23Pickup')
    dualiesClasses(3)=(single=class'KFMod.DeaglePickup',dual=class'KFMod.DualDeaglePickup')
    dualiesClasses(4)=(single=class'KFMod.GoldenDeaglePickup',dual=class'KFMod.GoldenDualDeaglePickup')
    dualiesClasses(5)=(single=class'KFMod.FlareRevolverPickup',dual=class'KFMod.DualFlareRevolverPickup')
}