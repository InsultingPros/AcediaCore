/**
 *      Abstract interface that represents some kind of item inside player's
 *  inventory.
 *      At most basic, abstract item has "template", "group" and "name":
 *      1.  "Template" refers to some sort of preset from which new instances of
 *          `EItem` can be created. "Template" might be implemented in any way,
 *          but the requirement is that "templates" can be referred to by
 *          case-insensitive, human-readable text value. In Killing Floor
 *          "templates" correspond to classes: for example,
 *          `KFMod.M79GrenadeLauncher` for M79 or `KFMod.M14EBRBattleRifle`
 *          for EBR.
 *      2.  "Tag" refers to the one of the groups inventory belongs to.
 *          For example all weapons would belong to group "weapons", while ammo
 *          or objective items can have their own group. But weapons can have
 *          several different tags further separating them, like "primary",
 *          "secondary" or "ultimate".
 *      3.  "Name" is simply a human-readable name of an item that is also fit
 *          to be output in UI. Like "M79 Grenade Launcher" instead of just
 *          "KFMod.M79GrenadeLauncher".
 *  We can also specify whether a certain item is allowed to be removed from
 *  inventory by player's own volition for any item. `IsRemovable()` method must
 *  return `true` if it can be.
 *
 *      However, while `EItem` is meant to be abstract generalization for any
 *  kind of item, to help simplify access to common item data we have also
 *  added several additional groups of parameters:
 *      1.  Shop-related parameters. Price (accessed by `SetPrice()` and
 *          `GetPrice()`) and whether it is sellable (`IsSellable()`). Price
 *          should only be used if an item is sellable.
 *      2.  Weight. Accessed by `SetWeight()` / `GetWeight()`.
 *      All of these parameters can be ignored if they are not applicable to
 *  a certain type of item.
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
class EItem extends EInterface
    abstract;

/**
 *  Returns arrays of tags for caller `EItem`.
 *
 *  @return Tags for the caller `EItem`. Returned `Text` values are not allowed
 *      to be empty or `none`. There can be no duplicates (in case-insensitive
 *      sense). But returned array can be empty.
 */
public function array<Text> GetTags()
{
    local array<Text> emptyArray;
    return emptyArray;
}

// TODO: document this
public function bool HasTag(BaseText tagToCheck)
{
    return false;
}

/**
 *  Returns template caller `EItem` was created from.
 *
 *  @return Template caller `EItem` belongs to, even if it was modified to be
 *      something else entirely. `none` for dead `EItem`s.
 */
public function Text GetTemplate()
{
    return none;
}

/**
 *  Returns UI-usable name of the caller `EItem`.
 *
 *  @return UI-usable name of the caller `EItem`. Allowed to be empty,
 *      not allowed to be `none`. `none` for dead `EItem`s.
 */
public function Text GetName()
{
    return none;
}

/**
 *  Checks whether this item can be removed as a result of player's action.
 *
 *  We will not enforce items to be completely unremovable through the API, so
 *  this only marks an item as one unintended to be removed from inventory.
 *  Enforcing of this rule is up to the implementation.
 *  9mm pistol is a good example for Killing Floor.
 *
 *  Note that item being removable does not mean game must always (or ever)
 *  provide players with a way to remove that item, just that it can.
 *
 *  @return `true` if caller `EItem` is removable by player and
 *      `false` otherwise.
 */
public function bool IsRemovable()
{
    return false;
}

/**
 *  Can caller `EItem` be sold?
 *
 *  @return `true` if caller `EItem` can be sold and `false` otherwise.
 */
public function bool IsSellable()
{
    return false;
}

/**
 *  Changes price of the caller `EItem`.
 *  Only applicable it item is sellable (`IsSellable() == true`).
 *
 *  Price is allowed to have any integer value.
 *
 *  Caller `EItem` is allowed to refuse this call and keep the old price.
 *  Setting new price, different from both old value and `newPrice` is
 *  forbidden.
 *
 *  @return `true` if price was successfully changed and `false` otherwise.
 */
public function bool SetPrice(int newPrice)
{
    return false;
}

/**
 *  Returns current price of the caller `EItem`.
 *  Only applicable it item is sellable (`IsSellable() == true`).
 *
 *  Price is allowed to have any integer value.
 *
 *  @return Current price of the caller `EItem`.
 */
public function int GetPrice() { return 0; }

/**
 *  Returns "weight" of the caller `EItem`.
 *  A parameter widely used in Killing Floor.
 *
 *  Weight is allowed to have any integer value.
 *
 *  Caller `EItem` is allowed to refuse this call and keep the old weight.
 *  Setting new weight, different from both old value and `newWeight` is
 *  forbidden.
 *
 *  @return `true` if weight was successfully changed and `false` otherwise.
 */
public function bool SetWeight(int newWeight)
{
    return false;
}

/**
 *  Returns current weight of the caller `EItem`.
 *
 *  Weight is allowed to have any integer value.
 *
 *  If concept of weight is not applicable, this method should return `0`.
 *  However inverse does not hold - returning `0` does not mean that weight
 *  is not applicable for the caller `EItem`.
 *
 *  @return Current weight of the caller `EItem`.
 */
public function int GetWeight()
{
    return 0;
}

defaultproperties
{
}