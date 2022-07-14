/**
 *  Dummy implementation for `EItem` interface that can wrap around `Inventory`
 *  instances that Acedia does not know about - including any non-weapons and
 *  non-ammo items added by any other mods.
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
class EKFUnknownItem extends EItem;

var private NativeActorRef inventoryReference;

protected function Finalizer()
{
    _.memory.Free(inventoryReference);
    inventoryReference = none;
}

/**
 *  Creates new `EKFUnknownItem` that refers to the `inventoryInstance`.
 *
 *  @param  inventoryInstance   Native inventory instance that new
 *      `EKFUnknownItem` will represent.
 *  @return New `EKFUnknownItem` that represents given `inventoryInstance`.
 *      `none` iff `inventoryInstance` is either `none`.
 */
public final static /*unreal*/ function EKFUnknownItem Wrap(
    Inventory inventoryInstance)
{
    local EKFUnknownItem newReference;
    if (inventoryInstance == none)                              return none;
    if (Ammunition(inventoryInstance) != none)                  return none;
    //  This one is not actually used for anything, so it is not real
    if (inventoryInstance.class == class'KFMod.FlashlightAmmo') return none;

    newReference = EKFUnknownItem(__().memory.Allocate(class'EKFUnknownItem'));
    newReference.inventoryReference =
        __server().unreal.ActorRef(inventoryInstance);
    return newReference;
}

/**
 *  Returns `Inventory` instance represented by the caller `EKFUnknownItem`.
 *
 *  @return `Inventory` instance represented by the caller `EKFUnknownItem`.
 */
public final /*unreal*/ function Inventory GetNativeInstance()
{
    if (inventoryReference != none) {
        return Inventory(inventoryReference.Get());
    }
    return none;
}

public function EInterface Copy()
{
    local Inventory inventoryInstance;
    inventoryInstance = GetNativeInstance();
    return Wrap(inventoryInstance);
}

public function bool Supports(class<EInterface> newInterfaceClass)
{
    if (newInterfaceClass == none)              return false;
    if (newInterfaceClass == class'EItem')      return true;

    return false;
}

public function EInterface As(class<EInterface> newInterfaceClass)
{
    if (!IsExistent()) {
        return none;
    }
    if (newInterfaceClass == class'EItem') {
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
    local EKFUnknownItem otherItem;
    otherItem = EKFUnknownItem(other);
    if (otherItem == none) {
        return false;
    }
    return (GetNativeInstance() == otherItem.GetNativeInstance());
}

public function array<Text> GetTags()
{
    local array<Text> emptyArray;
    return emptyArray;
}

public function bool HasTag(BaseText tagToCheck)
{
    return false;
}

public function Text GetTemplate()
{
    local Inventory inventory;
    inventory = GetNativeInstance();
    if (inventory == none) {
        return none;
    }
    return _.text.FromString(string(inventory.class));
}

public function Text GetName()
{
    local Inventory inventory;
    inventory = GetNativeInstance();
    if (inventory == none) {
        return none;
    }
    return _.text.FromString(inventory.GetHumanReadableName());
}

public function bool IsRemovable()
{
    return true;
}

public function bool IsSellable()
{
    return false;
}

public function bool SetPrice(int newPrice)
{
    return false;
}

public function int GetPrice() { return 0; }

public function bool SetWeight(int newWeight)
{
    return false;
}

public function int GetWeight()
{
    return 0;
}

defaultproperties
{
}