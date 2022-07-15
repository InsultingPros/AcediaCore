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
    dependson(InventoryAPI);

/**
 *  [reference documentation]
 *  # `EInventory` implementation for vanilla Killing Floor
 *
 *  ## Supported inventory items
 *
 *  This inventory implementation recognized 3 types of inventory items:
 *  *weapons*, *ammunition* and special type *unknown*.
 *
 *  ### Weapons
 *
 *      *Weapons* are any inventory derived from `Weapon` inventory class,
 *  although some features (dual-wielding support and recognizing whether weapon
 *  can be dropped/removed). For recognizing dual-wielded weapons this class
 *  relies on `ServerUnrealAPI.InventoryAPI` and its configuration.
 *
 *      Weapons are droppable/removable by default with the only exception of
 *  weapons derived from `KFWeapon` that have `bKFNeverThrow` set to `true`.
 *
 *  ### Ammunition
 *
 *      *Ammunition* is any `Inventory` derived from `Ammunition` class
 *  (`EKFAmmo`) plus some extra "artificial" items. "Artificial" here means
 *  that some ammunition items are not real `Inventory` objects, but rather
 *  an abstraction about ammo counter inside the weapon:
 *
 *  1. `EKFMedicAmmo` that stands for the medical charge of Field medic's guns;
 *  2. `EKFSyringeAmmo` that stands for healing charge of player's syringe;
 *  3. Even `EKFFlashlightAmmo` that stands for the flashlight energy counter
 *      `torchBatteryLife` inside `KFHumanPawn`.
 *
 *      All their templates are formed as weapon class concatenated with ":ammo"
 *  suffix (and "flashlight:ammo" for `EKFFlashlightAmmo`),
 *  e.g. "kfmod.syringe:ammo".
 *
 *      Ammunition is always considered not droppable/removable and cannot be
 *  added into the inventory by itself, since in Killing Floor it is inherently
 *  linked to the weapon object.
 *
 *  ### Unknow items
 *
 *      *Unknown* are any `Inventory` instances that cannot be classified as
 *  either of the above. They can always be added and removed, but never
 *  dropped.
 *
 *  ##  Supported explanations for being unable to add an item.
 *
 *  * "bad reference" - `EItem` that is either `none` or refers to
 *      now non-existent was passed;
 *  * "bad template" - supplied template does not exist;
 *  * "not supported" - adding this type of item to inventory is not supported
 *      by the API (basically it is ammunition);
 *  * "conflicting item" - there is an item in the inventory that is in conflict
 *      with item you are trying to add;
 *  * "overweight" - adding this item will put player over the available weight
 *      capacity.
 */

var private EPlayer inventoryOwner;

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

public function EInterface Copy()
{
    local EKFInventory interfaceCopy;
    interfaceCopy = EKFInventory(_.memory.Allocate(class'EKFInventory'));
    interfaceCopy.Initialize(inventoryOwner);
    return interfaceCopy;
}

public function bool Supports(class<EInterface> newInterfaceClass)
{
    if (newInterfaceClass == none)                  return false;
    if (newInterfaceClass == class'EInventory')     return true;
    if (newInterfaceClass == class'EKFInventory')   return true;

    return false;
}

public function EInterface As(class<EInterface> newInterfaceClass)
{
    if (inventoryOwner == none) return none;
    if (!IsExistent())          return none;

    if (    newInterfaceClass == class'EInventory'
        ||  newInterfaceClass == class'EKFInventory')
    {
        return Copy();
    }
    return none;
}

public function bool IsExistent()
{
    return (inventoryOwner != none && inventoryOwner.IsExistent());
}

public function bool SameAs(EInterface other)
{
    local EKFInventory otherInventory;
    if (inventoryOwner == none) return false;
    if (other == none)          return false;
    otherInventory = EKFInventory(other);
    if (otherInventory == none) return false;

    return inventoryOwner.SameAs(otherInventory.inventoryOwner);
}

private function Pawn GetOwnerPawn()
{
    local PlayerController myController;
    if (inventoryOwner == none) return none;
    myController = inventoryOwner.GetController();
    if (myController == none)   return none;

    return myController.pawn;
}

//  Wraps `EItem` around passed inventory, based on the appropriate class
private function EItem WrapItem(Inventory nativeItem)
{
    if (nativeItem == none) {
        return none;
    }
    if (KFWeapon(nativeItem) != none) {
        return class'EKFWeapon'.static.Wrap(KFWeapon(nativeItem));
    }
    else if (KFAmmunition(nativeItem) != none) {
        return class'EKFAmmo'.static.Wrap(KFAmmunition(nativeItem));
    }
    return class'EKFUnknownItem'.static.Wrap(nativeItem);
}

//  Some weapons (medic guns, syringe) store ammo counts in their
//  inventory class, this method is supposed to return a wrapper for
//  such ammunitions.
private function EItem WrapItemAmmo(Inventory nativeItem)
{
    if (nativeItem == none) {
        return none;
    }
    if (KFMedicGun(nativeItem) != none) {
        return class'EKFMedicAmmo'.static.Wrap(KFMedicGun(nativeItem));
    }
    else if (Syringe(nativeItem) != none) {
        return class'EKFSyringeAmmo'.static.Wrap(Syringe(nativeItem));
    }
    return none;
}

//  Seem to be the Killing Floor way to first manually call `Destroyed()` event
//  before calling `Destroy()` on an actor. This method does this safely
//  (making sure `Actor` reference does not die in a way that will
//  crash the game) for an `Actor` wrapped inside `NativeActorRef`.
private function KillRefInventory(NativeActorRef itemRef)
{
    local Actor         nativeReference;
    local class<Weapon> destroyedClass;
    if (itemRef == none) {
        return;
    }
    nativeReference = itemRef.Get();
    if (nativeReference != none)
    {
        destroyedClass = class<Weapon>(nativeReference.class);
        nativeReference.Destroyed();
    }
    //  Update `nativeReference` actor, in case it got messed up
    nativeReference = itemRef.Get();
    if (nativeReference != none) {
        nativeReference.Destroy();
    }
    if (destroyedClass != none) {
        _server.unreal.GetKFGameType().WeaponDestroyed(destroyedClass);
    }
}   

//  Adds an item that this API implementation is not aware about,
//  i.e. `Inventory` that must be wrapped as `EKFUnknown`.
private function EItem TryAddUnknownItem(EKFUnknownItem newItem)
{
    local Pawn      pawn;
    local Inventory nativeInventory;
    pawn = GetOwnerPawn();
    if (pawn == none)               return none;
    nativeInventory = newItem.GetNativeInstance();
    if (nativeInventory == none)    return none;

    nativeInventory.GiveTo(pawn);
    if (newItem.IsExistent()) {
        return newItem;
    }
    return none;
}

//  Searches `inventoryChain` for a weapon that:
//      1. Has the same root as `inventoryClass`
//          (see `ServerUnrealAPI.InventoryAPI` for an explanation of what a
//          "root" is);
//      2. Has specified dual wielding role.
private function KFWeapon GetByRootWithDualRole(
    class<KFWeapon>                 inventoryClass,
    Inventory                       inventoryChain,
    InventoryAPI.DualWieldingRole   requiredRole)
{
    local InventoryAPI          api;
    local class<KFWeapon>       nextWeaponClass;
    local class<KFWeaponPickup> itemRoot, nextRoot;
    api = _server.unreal.inventory;
    itemRoot = api.GetRootPickupClass(inventoryClass);
    while (inventoryChain != none)
    {
        nextWeaponClass = class<KFWeapon>(inventoryChain.class);
        nextRoot = api.GetRootPickupClass(nextWeaponClass);
        if (    itemRoot == nextRoot
            &&  api.GetDualWieldingRole(nextWeaponClass) == requiredRole)
        {
            return KFWeapon(inventoryChain);
        }
        inventoryChain = inventoryChain.inventory;
    }
    return none;
}

/**
 *  Supports adding weapons and non-ammo (unknown `Inventory` instances added
 *  by other mods) items. Cannot properly check if unknown item can be added
 *  and can fail adding an item even if `CanAdd()` succeeded.
 */
public function EItem Add(EItem newItem, optional bool forceAddition)
{
    local Pawn              pawn;
    local EKFWeapon         kfWeaponItem;
    local KFWeapon          nativeWeapon;
    local class<KFWeapon>   dualClass;
    local KFWeapon          conflictWeapon;
    if (!CanAdd(newItem, forceAddition))    return none;
    pawn = GetOwnerPawn();
    if (pawn == none)                       return none;

    kfWeaponItem = EKFWeapon(newItem);
    if (kfWeaponItem == none) {
        return TryAddUnknownItem(EKFUnknownItem(newItem));
    }
    nativeWeapon = kfWeaponItem.GetNativeInstance();
    if (nativeWeapon == none) {
        //  Dead entity - nothing to add
        return none;
    }
    dualClass = _server.unreal.inventory.GetDualClass(nativeWeapon.class);
    //  The only possible complication here are dual weapons - `newItem` might
    //  cause addition of completely different weapon.
    if (dualClass != none)
    {
        conflictWeapon = GetByRootWithDualRole( nativeWeapon.class,
                                                pawn.inventory, DWR_Single);
        if (conflictWeapon != none)
        {
            nativeWeapon = KFWeapon(_server.unreal.inventory
                .MergeWeapons(pawn, dualClass, nativeWeapon, conflictWeapon));
        }
        if (nativeWeapon != none) {
            return class'EKFWeapon'.static.Wrap(nativeWeapon);
        }
    }
    nativeWeapon.GiveTo(pawn);
    return newItem;
}

/**
 *  Supports adding weapons and non-ammo (unknown `Inventory` instances added
 *  by other mods) items. Cannot properly check if unknown item can be added
 *  and can fail adding an item even if `CanAddTemplate()` succeeded.
 */
public function EItem AddTemplate(
    BaseText        newItemTemplate,
    optional bool   forceAddition)
{
    local Pawn              pawn;
    local EKFUnknownItem    newItem;
    local KFWeapon          newWeapon, collidingWeapon;
    local class<Inventory>  newInventoryClass;
    local class<KFWeapon>   newWeaponClass, dualClass;
    if (newItemTemplate == none)                            return none;
    if (!CanAddTemplate(newItemTemplate, forceAddition))    return none;
    pawn = GetOwnerPawn();
    if (pawn == none)                                       return none;

    //  Since `CanAddTemplate()` check was passed - `newInventoryClass` is
    //  either a weapon or some non-ammo inventory.
    newInventoryClass   = class<Inventory>(_.memory.LoadClass(newItemTemplate));
    newWeaponClass      = class<KFWeapon>(newInventoryClass);
    if (newWeaponClass == none)
    {
        newItem = class'EKFUnknownItem'.static
            .Wrap(Inventory(_.memory.Allocate(newInventoryClass)));
        if (newItem != none && TryAddUnknownItem(newItem) != none) {
            return newItem;
        }
        _.memory.Free(newItem);
        return none;
    }
    //  Handle dual pistols merging
    dualClass = _server.unreal.inventory.GetDualClass(newWeaponClass);
    if (dualClass != none)
    {
        collidingWeapon = GetByRootWithDualRole(newWeaponClass,
                                                pawn.inventory, DWR_Single);
        if (collidingWeapon != none) {
            newWeaponClass = dualClass;
        }
    }
    //  Add regular weapons
    newWeapon = KFWeapon(_server.unreal.inventory
        .MergeWeapons(GetOwnerPawn(), newWeaponClass, collidingWeapon));
    if (newWeapon != none) {
        return class'EKFWeapon'.static.Wrap(newWeapon);
    }
    return none;
}

/**
 *  Supports adding weapons and non-ammo (unknown `Inventory` instances added
 *  by other mods) items. Cannot properly check if unknown item can be added
 *  and can raise "faulty implementation" error in case it cannot.
 */
public function Text CanAddExplain(
    EItem           itemToCheck,
    optional bool   forceAddition)
{
    local EKFWeapon         kfWeaponItem;
    local EKFUnknownItem    kfSomeItem;
    local KFWeapon          kfWeapon;
    if (itemToCheck == none) {
        return P("bad reference").Copy();
    }
    //  We assume all unknown items can be added, since we cannot really
    //  check anyway
    kfSomeItem = EKFUnknownItem(itemToCheck);
    if (kfSomeItem != none)
    {
        if (kfSomeItem.IsExistent()) {
            return none;
        }
        return P("entity was destroyed").Copy();
    }
    //  If not an `EKFUnknownItem`, then it must be `EKFWeapon`
    kfWeaponItem = EKFWeapon(itemToCheck);
    if (kfWeaponItem == none) {
        return P("unsupported item").Copy();
    }
    kfWeapon = kfWeaponItem.GetNativeInstance();
    if (kfWeapon == none) {
        return P("entity was destroyed").Copy();
    }
    return CanAddWeaponClassExplain(kfWeapon.class, forceAddition);
}

/**
 *  Supports adding weapons and non-ammo (unknown `Inventory` instances added
 *  by other mods) items. Cannot properly check if unknown item can be added
 *  and can raise "faulty implementation" error in case it cannot.
 */
public function Text CanAddTemplateExplain(
    BaseText        itemTemplateToCheck,
    optional bool   forceAddition)
{
    local class<Inventory>  inventoryClass;
    local class<KFWeapon>   kfWeaponClass;
    if (itemTemplateToCheck == none) {
        return P("bad reference").Copy();
    }
    if (itemTemplateToCheck.EndsWith(P(":ammo"))) {
        return P("not supported").Copy();
    }
    //  Can only add weapons for now
    inventoryClass = class<Inventory>(_.memory.LoadClass(itemTemplateToCheck));
    if (inventoryClass == none) {
        return P("bad template");
    }
    if (class<Ammunition>(inventoryClass) != none) {
        return P("not supported").Copy();
    }
    kfWeaponClass = class<KFWeapon>(_.memory.LoadClass(itemTemplateToCheck));
    if (kfWeaponClass == none) {
        return none;    //  Neither ammo or a weapon, so `EKFUnknownItem`
    }
    return CanAddWeaponClassExplain(kfWeaponClass, forceAddition);
}

//  Auxiliary method for building "conflicting item:<item name>" explanations
private function Text ReportConflictingItem(Inventory conflictingItem)
{
    local Text result;
    local MutableText builder;
    if (conflictingItem == none) {
        return P("conflicting item").Copy();
    }
    builder = P("conflicting item:")
        .MutableCopy()
        .AppendString(string(conflictingItem));
    result = builder.Copy();
    _.memory.Free(builder);
    return result;
}

//      Checks if a weapon of given class `kfWeaponClass` can be added to
//  the inventory. There is two reasons that can prevent it from being added:
//      1. There is a conflict with existing weapon (i.e. already have
//          different skin in the inventory);
//      2. It will put player over his weight capacity.
private function Text CanAddWeaponClassExplain(
    class<KFWeapon> kfWeaponClass,
    optional bool   forceAddition)
{
    local float                         additionalWeight;
    local class<KFWeapon>               dualVersion;
    local KFPawn                        kfPawn;
    local Inventory                     conflictingWeapon;
    local InventoryAPI.DualWieldingRole dualWeildingRole;
    if (kfWeaponClass == none)  return P("bad template").Copy();
    kfPawn = KFPawn(GetOwnerPawn());
    if (kfPawn == none)         return P("internal error:no pawn").Copy();

    additionalWeight = kfWeaponClass.default.weight;
    //  Start with checking conflicting weapons, since in case of conflicting
    //  dual weapons we might need to update `additionalWeight` variable.
    conflictingWeapon =
        _server.unreal.inventory.GetByRoot(kfWeaponClass, kfPawn.inventory);
    if (conflictingWeapon != none)
    {
        //  `GetByRoot()` is a simple check that thinks handcannon is in
        //  a conflict with another handcannon, so we need to handle
        //  dual wieldable weapons differently
        dualWeildingRole = _server.unreal.inventory.GetDualWieldingRole(
            class<KFWeapon>(conflictingWeapon.class));
        if (dualWeildingRole != DWR_None)
        {
            if (HasDualWieldingConflict(kfWeaponClass, kfPawn, forceAddition)) {
                return ReportConflictingItem(conflictingWeapon);
            }
            //  Update additional weight
            dualVersion = _server.unreal.inventory.GetDualClass(kfWeaponClass);
            if (dualVersion != none)
            {
                additionalWeight =
                    dualVersion.default.weight - additionalWeight;
            }
        }
        //  For non-dual weapons the check easy: we can only force
        //  conflicting weapons of the different classes into the same inventory
        //  (e.g. different skins)
        else if (!forceAddition || kfWeaponClass == conflictingWeapon.class) {
            return ReportConflictingItem(conflictingWeapon);
        }
    }
    //  If there were no conflict - just check the weight
    if (!forceAddition && !kfPawn.CanCarry(additionalWeight)) {
        return P("overweight").Copy();
    }
    return none;
}

//  Decides whether we can add a weapon to the `pawn`'s inventory based on
//  the dual-wielding weapons rules
private function bool HasDualWieldingConflict(
    class<KFWeapon> kfWeaponClass,
    Pawn            pawn,
    bool            forceAddition)
{
    local bool              addingSingle;
    local class<KFWeapon>   dualClass;
    if (pawn == none) {
        return false;
    }
    addingSingle = false;
    dualClass = _server.unreal.inventory.GetDualClass(kfWeaponClass);
    if (dualClass == none)
    {
        dualClass       = kfWeaponClass;
        addingSingle    = true;
    }
    //  1. We can always add pistols if we do not yet have dual version
    if (GetByRootWithDualRole(kfWeaponClass, pawn.inventory, DWR_Dual) == none)
    {
        return false;
    }
    //  2. If we do have a dual version, but we are forcing this addition and
    //      are adding single when there is no other single pistol yet
    if (    addingSingle && forceAddition
        &&  _server.unreal.inventory.Get(kfWeaponClass, pawn.inventory) == none)
    {
        return false;
    }
    //  3. If we do have a dual version, but we are forcing this addition and
    //      are adding a different skin
    if (    forceAddition
        &&  _server.unreal.inventory.Get(dualClass, pawn.inventory) == none)
    {
        return false;
    }
    return true;
}

//  Gets `Inventory` to which `item` corresponds. If there even is one -
//  e.g. `EKFFlashlightAmmo` does not correspond to inventory.
private final function Inventory GetItemNativeInstance(EItem item)
{
    if (item == none) {
        return none;
    }
    if (item.class == class'EKFAmmo') {
        return EKFAmmo(item).GetNativeInstance();
    }
    if (item.class == class'EKFMedicAmmo') {
        return EKFMedicAmmo(item).GetNativeInstance();
    }
    if (item.class == class'EKFSyringeAmmo') {
        return EKFSyringeAmmo(item).GetNativeInstance();
    }
    if (item.class == class'EKFWeapon') {
        return EKFWeapon(item).GetNativeInstance();
    }
    if (item.class == class'EKFUnknownItem') {
        return EKFUnknownItem(item).GetNativeInstance();
    }
    return none;
}

/**
 *  Supports removal of weapons and non-ammo (unknown `Inventory` instances
 *  added by other mods) items.
 */
public function bool Remove(
    EItem           itemToRemove,
    optional bool   keepItem,
    optional bool   forceRemoval)
{
    local bool              result;
    local Pawn              pawn;
    local NativeActorRef    pawnRef;
    local Inventory         nativeInstance;
    local KFWeapon          kfWeapon;
    local ArrayList         removalList;
    if (EAmmo(itemToRemove) != none)    return false;
    nativeInstance = GetItemNativeInstance(itemToRemove);
    if (nativeInstance == none)         return false;
    pawn = GetOwnerPawn();
    if (pawn == none)                   return false;

    //  Do some checks first
    kfWeapon = KFWeapon(nativeInstance);
    if (!forceRemoval && kfWeapon != none && kfWeapon.bKFNeverThrow) {
        return false;
    }
    if (!_server.unreal.inventory.Contains(kfWeapon, pawn.inventory)) {
        return false;
    }
    //      This code is an overkill for removing a single item and is not
    //  really efficient, but it completely relies on methods that
    //  `RemoveTemplate()` and `RemoveAll()` use, so consistent behavior is
    //  guaranteed.
    //      Only optimize this if this method will become
    //  a bottleneck somewhere.
    removalList = _.collections.EmptyArrayList();
    removalList.AddItem(_server.unreal.ActorRef(nativeInstance));
    pawnRef = _server.unreal.ActorRef(pawn);
    result = RemoveInventoryArray(  pawnRef, removalList,
                                    keepItem, forceRemoval, true);
    _.memory.Free(removalList);
    _.memory.Free(pawnRef);
    return result;
}

/**
 *  Supports removal of weapons and non-ammo (unknown `Inventory` instances
 *  added by other mods) items.
 */
public function bool RemoveTemplate(
    BaseText        template,
    optional bool   keepItem,
    optional bool   forceRemoval,
    optional bool   removeAll)
{
    local bool              result;
    local Pawn              pawn;
    local NativeActorRef    pawnRef;
    local ArrayList         removalList;
    local class<Inventory>  inventoryClass;
    local class<KFWeapon>   weaponClass;
    if (template == none)                           return false;
    if (template.EndsWith(P(":ammo")))              return false;
    inventoryClass = class<Inventory>(_.memory.LoadClass(template));
    if (class<Ammunition>(inventoryClass) != none)  return false;
    if (inventoryClass == none)                     return false;
    pawn = GetOwnerPawn();
    if (pawn == none)                               return false;

    pawnRef     = _server.unreal.ActorRef(pawn);
    removalList = _.collections.EmptyArrayList();
    //  All removal works the same - form a "kill list", then remove
    //  all `Inventory` at once with `RemoveInventoryArray`
    AddClassForRemoval(removalList, inventoryClass, forceRemoval, removeAll);
    weaponClass = class<KFWeapon>(inventoryClass);
    result = RemoveInventoryArray(
        pawnRef,
        removalList,
        keepItem,
        forceRemoval,
        _server.unreal.inventory.GetDualWieldingRole(weaponClass) ==  DWR_Dual);
    _.memory.Free(removalList);
    _.memory.Free(pawnRef);
    return result;
}

//      Searches `EKFInventory`'s owner's inventory chain for items of class
//  `inventoryClass` and adds them to the `removalArray` (for later removal).
private function AddClassForRemoval(
    ArrayList           removalArray,
    class<Inventory>    inventoryClass,
    optional bool       forceRemoval,
    optional bool       removeAll)
{
    local bool              canRemoveInventory;
    local Pawn              pawn;
    local Inventory         nextInventory;
    local KFWeapon          nextKFWeapon;
    local class<KFWeapon>   dualClass;
    if (removalArray == none)   return;
    if (inventoryClass == none) return;
    pawn = GetOwnerPawn();
    if (pawn == none)           return;
    nextInventory = pawn.inventory;
    if (nextInventory == none)  return;

    dualClass =
        _server.unreal.inventory.GetDualClass(class<KFWeapon>(inventoryClass));
    while (nextInventory != none)
    {
        //  We want to "remove" dual handcannons if removal of single handcannon
        //  is requested (replacing them with another single handcannon)
        canRemoveInventory = (inventoryClass == nextInventory.class)
            || (dualClass == nextInventory.class);
        nextKFWeapon = KFWeapon(nextInventory);
        //  Check if weapon is removable
        if (canRemoveInventory && nextKFWeapon != none) {
            canRemoveInventory = (forceRemoval || !nextKFWeapon.bKFNeverThrow);
        }
        if (canRemoveInventory)
        {
            removalArray.AddItem(_server.unreal.ActorRef(nextInventory));
            if (!removeAll) {
                break;
            }
        }
        nextInventory = nextInventory.inventory;
    }
}

/**
 *  Supports removal of weapons and non-ammo (unknown `Inventory` instances
 *  added by other mods) items. Ammo items are removed alongside linked weapons.
 */
public function bool RemoveAll(
    optional bool keepItems,
    optional bool forceRemoval,
    optional bool includeHidden)
{
    local bool              result, canRemoveItem;
    local Pawn              pawn;
    local NativeActorRef    pawnRef;
    local KFWeapon          kfWeapon;
    local Inventory         nextInventory;
    local ArrayList         inventoryToRemove;
    pawn = GetOwnerPawn();
    if (pawn == none) {
        return false;
    }
    inventoryToRemove = _.collections.EmptyArrayList();
    nextInventory = pawn.inventory;
    while (nextInventory != none)
    {
        kfWeapon = KFWeapon(nextInventory);
        canRemoveItem = kfWeapon != none
            && (forceRemoval || !kfWeapon.bKFNeverThrow);
        canRemoveItem = canRemoveItem
            || (includeHidden && Ammunition(nextInventory) == none);
        if (canRemoveItem) {
            inventoryToRemove.AddItem(_server.unreal.ActorRef(nextInventory));
        }
        nextInventory = nextInventory.inventory;
    }
    pawnRef = _server.unreal.ActorRef(pawn);
    result = RemoveInventoryArray(  pawnRef, inventoryToRemove,
                                    keepItems, forceRemoval, true);
    _.memory.Free(inventoryToRemove);
    _.memory.Free(pawnRef);
    return result;
}

//  `completeRemoval` decides how dual weapons should be treated:
//  `true` means all of their parts must be dropped/removed and
//  `false` means that only a single half (1 pistol from dual pistols) must be
//  dropped/removed.
private function bool RemoveInventoryArray(
    NativeActorRef  ownerPawnRef,
    ArrayList       itemsToRemove,
    bool            keepItems,
    bool            forceRemoval,
    bool            completeRemoval)
{
    local int                       i;
    local bool                      removedItem, removedEquip;
    local Pawn                      ownerPawn;
    local array< class<KFWeapon> >  singleClassesToCleanup;
    local NativeActorRef            equippedWeapon, nextRef;
    if (itemsToRemove == none)  return false;
    if (ownerPawnRef == none)   return false;
    ownerPawn = Pawn(ownerPawnRef.Get());
    if (ownerPawn == none)      return false;

    equippedWeapon = _server.unreal.ActorRef(ownerPawn.weapon);
    for(i = 0; i < itemsToRemove.GetLength(); i += 1)
    {
        //  `itemsToRemove` is guaranteed to contain valid `ActorRef`s
        nextRef         = NativeActorRef(itemsToRemove.GetItem(i));
        removedEquip    = removedEquip || equippedWeapon.IsEqual(nextRef);
        //      If we are dropping (`keepItems == true`) complete dual weapons
        //  and not just their part (`completeRemoval`), then we will need to
        //  re-remove single weapons added as a result of drop.
        //      We have to go through that because we want to employ drop
        //  methods supplied to us by native classes (that usually only drop
        //  a single pistol in the pair), instead of simply removing dual
        //  version and spawning two single pickups.
        if (keepItems && completeRemoval) {
            AppendSingleClass(singleClassesToCleanup, nextRef);
        }
        removedItem =
            HandleInventoryRemoval( ownerPawnRef, nextRef, keepItems,
                                    forceRemoval, completeRemoval)
            || removedItem;
    }
    itemsToRemove.Empty();
    for (i = 0; i < singleClassesToCleanup.length; i += 1)
    {
        AddClassForRemoval(itemsToRemove, singleClassesToCleanup[i],
                                    forceRemoval, false);
    }
    if (itemsToRemove.GetLength() > 0)
    {
        RemoveInventoryArray(   ownerPawnRef, itemsToRemove,
                                keepItems, forceRemoval, false);
    }
    if (removedEquip) {
        RepickEquippedWeapon(ownerPawnRef);
    }
    _.memory.Free(equippedWeapon);
    return removedItem;
}

private function RepickEquippedWeapon(NativeActorRef pawnRef)
{
    local Pawn pawn;
    pawn = Pawn(pawnRef.Get());
    if (pawn != none) {
        pawn.weapon = none;
    }
    if (pawn != none && pawn.controller != none) {
        pawn.controller.SwitchToBestWeapon();
    }
    pawn = Pawn(pawnRef.Get());
    if (pawn != none && pawn.weapon != none) {
        pawn.weapon.ClientWeaponSet(false);
    }
}

private function AppendSingleClass(
    out array< class<KFWeapon> >    singleClasses,
    NativeActorRef                  nextRef)
{
    local KFWeapon          kfWeaponInstance;
    local class<KFWeapon>   singleClass;
    kfWeaponInstance = KFWeapon(nextRef.Get());
    if (kfWeaponInstance == none) {
        return;
    }
    singleClass =
        _server.unreal.inventory.GetSingleClass(kfWeaponInstance.class);
    if (singleClass != none) {
        singleClasses[singleClasses.length] = singleClass;
    }
}

//  Assumes that `ownerPawnRef != none` and `inventoryRef != none`.
//  Removes `Inventory` inside `inventoryRef` in a way appropriate for given
//  flags `keepItems`, `forceRemoval` and `completeRemoval`.
private function bool HandleInventoryRemoval(
    NativeActorRef  ownerPawnRef,
    nativeActorRef  inventoryRef,
    bool            keepItems,
    bool            forceRemoval,
    bool            completeRemoval)
{
    local Inventory         inventory;
    local class<KFWeapon>   singleClass;
    inventory = Inventory(inventoryRef.Get());
    if (inventory == none) {
        return false;
    }
    //  `keepItems` means we have to drop inventory, which is handled by
    //  the unreal script-provided methods
    if (keepItems) {
        return DropInventoryItem(inventory);
    }
    //      Reset `completeRemoval` flag if single weapons produced as a result
    //  of (non-forced) removal of dual version is non-removable.
    //      Example - dual 9mm. Dual 9mm and be dropped, but a single 9mm
    //  should not be dropped without being forced to.
    if (!forceRemoval && completeRemoval)
    {
        if (KFWeapon(inventory) != none)
        {
            singleClass = _server.unreal.inventory
                .GetSingleClass(class<KFWeapon>(inventory.class));
        }
        if (singleClass != none && singleClass.default.bKFNeverThrow) {
            completeRemoval = false;
        }
    }
    //  Simply destroy items we want to remove completely, that is if:
    //      1. We were told by the flag `completeRemoval`;
    //      2. It is not a weapon and, since `Ammunition` inventory should not
    //          reach this method, `EKFUnknown`.
    if (completeRemoval || KFWeapon(inventory) == none) {
        KillRefInventory(inventoryRef);
    }
    else {
        DestroyWeaponSingle(ownerPawnRef, inventoryRef);
    }
    return true;
}

private function bool DropInventoryItem(Inventory inventoryToDrop)
{
    local Pawn      ownerPawn;
    local Vector    x, y, z;
    local Vector    tossVelocity;
    if (inventoryToDrop == none)        return false;
    ownerPawn = Pawn(inventoryToDrop.owner);
    if (ownerPawn == none)              return false;
    if (ownerPawn.controller == none)   return false;

    tossVelocity = Vector(ownerPawn.controller.GetViewRotation());
    tossVelocity =
        tossVelocity * ((ownerPawn.velocity dot tossVelocity) + 150.0)
        + Vect(0.0, 0.0, 100.0);
    inventoryToDrop.velocity = tossVelocity;
    GetAxes(ownerPawn.rotation, x, y, z);
    KFWeapon(inventoryToDrop).bCanThrow = true;
    inventoryToDrop.DropFrom(ownerPawn.location
        + 0.8 * ownerPawn.collisionRadius * x
        - 0.5 * ownerPawn.collisionRadius * y);
    return true;
}

//      Assumes that `ownerPawnRef != none` and `inventoryToDestroy != none`.
//      Destroys a dual version of the weapon, adding a single version in its
//  stead (with half the ammo and magazine).
private function DestroyWeaponSingle(
    NativeActorRef  ownerPawnRef,
    NativeActorRef  inventoryToDestroy)
{
    local int               totalAmmoPrimary, totalAmmoSecondary, magazineAmmo;
    local class<KFWeapon>   singleClass;
    local KFWeapon          kfWeaponToDestroy;
    kfWeaponToDestroy = KFWeapon(inventoryToDestroy.Get());
    if (kfWeaponToDestroy == none) {
        return;
    }
    singleClass =
        _server.unreal.inventory.GetSingleClass(kfWeaponToDestroy.class);
    if (singleClass != none)
    {
        totalAmmoPrimary    = kfWeaponToDestroy.AmmoAmount(0);
        totalAmmoSecondary  = kfWeaponToDestroy.AmmoAmount(1);
        magazineAmmo        = kfWeaponToDestroy.magAmmoRemaining;
    }
    KillRefInventory(inventoryToDestroy);
    if (singleClass != none)
    {
        _server.unreal.inventory
            .AddWeaponWithAmmo( Pawn(ownerPawnRef.Get()), singleClass,
                                totalAmmoPrimary / 2, totalAmmoSecondary / 2,
                                magazineAmmo / 2, true);  
    }
}

public function bool Contains(EItem itemToCheck)
{
    local Pawn          itemRelatedPawn;
    local Controller    inventoryRelatedController;
    local Inventory     nextInventory, itemInventory;
    if (inventoryOwner == none) return false;
    if (itemToCheck == none)    return false;

    //  For flashlight ammo, its `Pawn` must be inventory's owner
    if (itemToCheck.class == class'EKFFlashlightAmmo')
    {
        itemRelatedPawn = EKFFlashlightAmmo(itemToCheck).GetNativeInstance();
        inventoryRelatedController = inventoryOwner.GetController();
        if (inventoryRelatedController != none) {
            return itemRelatedPawn ==  inventoryRelatedController.pawn;
        }
        return false;
    }
    //  For everything else, its native instance has to be somewhere
    //  inside inventory
    itemInventory = GetItemNativeInstance(itemToCheck);
    nextInventory = itemRelatedPawn.inventory;
    while (nextInventory != none)
    {
        if (nextInventory == itemInventory) {
            return true;
        }
        nextInventory = nextInventory.inventory;
    }
    return false;
}

public function bool ContainsTemplate(BaseText itemTemplateToCheck)
{
    local bool  success;
    local EItem templateItem;
    templateItem = GetTemplateItem(itemTemplateToCheck);
    success = (templateItem != none);
    _.memory.Free(templateItem);
    return success;
}

private function array<EItem> FilterNoneReferences(array<EItem> arrayToFilter)
{
    local int i;
    while (i < arrayToFilter.length)
    {
        if (arrayToFilter[i] == none) {
            arrayToFilter.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
    return arrayToFilter;
}

//  Wraps and returns all items that correspond to at least one given flag.
//  This implementation only supports weapons and ammo right now.
//  Most of the other item getters are basically just calling this method.
public function array<EItem> GetItemsByFlags(
    bool getWeapon,
    bool getAmmo,
    bool getRest)
{
    local Pawn          pawn;
    local Inventory     nextInventory;
    local array<EItem>  result;
    if (!getWeapon && !getAmmo) return result;
    pawn = GetOwnerPawn();
    if (pawn == none)           return result;

    if (getAmmo)
    {
        result[result.length] =
            class'EKFFlashlightAmmo'.static.Wrap(KFHumanPawn(pawn));
    }
    nextInventory = pawn.inventory;
    while (nextInventory != none)
    {
        if (KFWeapon(nextInventory) != none)
        {
            if (getWeapon) {
                result[result.length] = WrapItem(nextInventory);
            }
            if (getAmmo) {
                result[result.length] = WrapItemAmmo(nextInventory);
            }
        }
        //  Ammunition never has another, built-in, ammo, so we do not need to
        //  call `WrapItemAmmo` method
        else if (getAmmo && KFAmmunition(nextInventory) != none) {
            result[result.length] = WrapItem(nextInventory);
        }
        else if (getRest) {
            result[result.length] = WrapItem(nextInventory);
        }
        nextInventory = nextInventory.inventory;
    }
    return FilterNoneReferences(result);
}

//  Same as `GetItemsByFlags()`, but only returns first match.
private function EItem GetItemByFlags(
    bool getWeapon,
    bool getAmmo,
    bool getRest)
{
    local Pawn          pawn;
    local EItem         result;
    local Inventory     nextInventory;
    if (!getWeapon && !getAmmo) return result;
    pawn = GetOwnerPawn();
    if (pawn == none)           return result;

    if (getAmmo)
    {
        result = class'EKFFlashlightAmmo'.static.Wrap(KFHumanPawn(pawn));
        if (result != none) {
            return result;
        }
    }
    nextInventory = pawn.inventory;
    while (nextInventory != none)
    {
        //  From weapon instances we can either wrap a weapon interface or
        //  ammo interface (for weapons with built-in ammo)
        if (KFWeapon(nextInventory) != none)
        {
            if (getWeapon) {
                result = WrapItem(nextInventory);
            }
            if (getAmmo &&result == none) {
                result = WrapItemAmmo(nextInventory);
            }
            if (result != none) {
                return result;
            }
        }
        //  Ammunition never has another, built-in, ammo, so we do not need to
        //  call `WrapItemAmmo` method
        if (getAmmo && KFAmmunition(nextInventory) != none) {
            result = WrapItem(nextInventory);
        }
        else if (getRest && result == none) {
            result = WrapItem(nextInventory);
        }
        if (result != none) {
            return result;
        }
        nextInventory = nextInventory.inventory;
    }
    return none;
}

public function array<EItem> GetAllItems()
{
    return GetItemsByFlags(true, true, true);
}

public function array<EItem> GetItemsSupporting(class<EItem> interfaceClass)
{
    local bool getWeapon, getAmmo;
    getWeapon   =   (   interfaceClass == class'EWeapon'
                    ||  interfaceClass == class'EKFWeapon');
    getAmmo     =   (   interfaceClass == class'EAmmo'
                    ||  interfaceClass == class'EKFAmmo');
    return GetItemsByFlags(getWeapon, getAmmo, false);
}

public function array<EItem> GetTagItems(BaseText tag)
{
    local array<EItem>  emptyArray;
    local bool          getWeapon, getAmmo;
    if (tag == none) {
        return emptyArray;
    }
    getWeapon   = P("weapon").Compare(tag) || P("visible").Compare(tag);
    getAmmo     = P("ammo").Compare(tag);
    return GetItemsByFlags(getWeapon, getAmmo, false);
}

public function EItem GetTagItem(BaseText tag)
{
    local bool getWeapon, getAmmo;
    if (tag == none) {
        return none;
    }
    getWeapon   = P("weapon").Compare(tag);
    getAmmo     = P("ammo").Compare(tag);
    return GetItemByFlags(getWeapon, getAmmo, false);
}

public function array<EItem> GetTemplateItems(BaseText template)
{
    local Pawn          pawn;
    local bool          getBuiltInAmmo;
    local string        inventoryClass;
    local Inventory     nextInventory;
    local EItem         nextItem;
    local array<EItem>  result;
    if (template == none)       return result;
    pawn = GetOwnerPawn();
    if (pawn == none)           return result;
    if (pawn.inventory == none) return result;

    //  As far as Killing Floor is concerned, template == class name
    if (template.Compare(P("flashlight:ammo")))
    {
        result[0] = class'EKFFlashlightAmmo'.static.Wrap(KFHumanPawn(pawn));
        return result;
    }
    if (template.EndsWith(P(":ammo")))
    {
        //  Drop the ":ammo" part (`5` letters long)
        inventoryClass = template.ToString(0, template.GetLength() - 5);
        getBuiltInAmmo = true;
    }
    else {
        inventoryClass = template.ToString();
    }
    nextInventory = pawn.inventory;
    while (nextInventory != none)
    {
        if (inventoryClass ~= string(nextInventory.class))
        {
            if (getBuiltInAmmo) {
                nextItem = WrapItemAmmo(nextInventory);
            }
            else {
                nextItem = WrapItem(nextInventory);
            }
            if (nextItem != none)
            {
                result[result.length] = nextItem;
                nextItem = none;
            }
        }
        nextInventory = nextInventory.inventory;
    }
    return result;
}

public function EItem GetTemplateItem(BaseText template)
{
    local Pawn      pawn;
    local bool      getBuiltInAmmo;
    local string    inventoryClass;
    local Inventory nextInventory;
    local EItem     result;
    if (template == none)       return result;
    pawn = GetOwnerPawn();
    if (pawn == none)           return result;
    if (pawn.inventory == none) return result;

    //  As far as Killing Floor is concerned, template == class name
    if (template.Compare(P("flashlight:ammo"))) {
        return class'EKFFlashlightAmmo'.static.Wrap(KFHumanPawn(pawn));
    }
    if (template.EndsWith(P(":ammo")))
    {
        //  Drop the ":ammo" part (`5` letters long)
        inventoryClass = template.ToString(0, template.GetLength() - 5);
        getBuiltInAmmo = true;
    }
    else {
        inventoryClass = template.ToString();
    }
    nextInventory = pawn.inventory;
    while (nextInventory != none)
    {
        if (inventoryClass ~= string(nextInventory.class))
        {
            if (getBuiltInAmmo) {
                result = WrapItemAmmo(nextInventory);
            }
            else {
                result = WrapItem(nextInventory);
            }
            if (result != none) {
                return result;
            }
        }
        nextInventory = nextInventory.inventory;
    }
    return none;
}

public function array<EItem> GetEquippedItems()
{
    local EItem         equippedWeapon;
    local array<EItem>  result;
    equippedWeapon = GetEquippedItem();
    if (equippedWeapon != none) {
        result[0] = equippedWeapon;
    }
    return result;
}

public function EItem GetEquippedItem()
{
    local Pawn      pawn;
    local KFWeapon  currentWeapon;
    pawn = GetOwnerPawn();
    if (pawn == none)           return none;
    if (pawn.weapon == none)    return none;
    currentWeapon = KFWeapon(pawn.weapon);
    if (currentWeapon == none)  return none;

    return class'EKFWeapon'.static.Wrap(currentWeapon);
}

defaultproperties
{
}