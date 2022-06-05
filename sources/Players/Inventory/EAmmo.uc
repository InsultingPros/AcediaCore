/**
 *      Abstract interface that represents ammunition of a certain type.
 *      Ammunition methods make distinction between "amount" and "total amount":
 *          * "Amount" is how much of this ammo is stored in this
 *              inventory item, "max amount" is how much it can store at once.
 *              These values can be affected by other items in the inventory.
 *          * "Total amount" is how much ammo of this type player has in his
 *              inventory in total.
 *  Neither amounts can ever be negative.
 *  For Killing Floor "total ammo" corresponds to the amount of ammunition
 *  associated with a weapon, while "ammo" would correspond to the amount of
 *  ammo still unleaded into the weapon. This means that "max ammo" becomes
 *  quite a bizarre value that depends on how full your magazine is.
 *  For example, if you bought lever action rifle, filled it
 *  with ammo (80 bullets) and then shot out 6, you will have:
 *          * "Ammo" == 70 - since you will have that much still unloaded;
 *          * "Max ammo" == 76 - since with 4 loaded bullets you can only
 *              have 76 unloaded ones;
 *          * "Total ammo" == 74 - amount of bullets you can still shoot;
 *          * "Max total ammo" = 80 - since that is the limit of LAR bullets you
 *              can carry in total.
 *      When one loads ammo into the weapon, its "amount" decreases, but its
 *  "total amount" stays the same. Unless specified otherwise, all the methods
 *  deal with a regular "amount".
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
class EAmmo extends EItem
    abstract;

/**
 *  Changes amount of ammo inside referred ammunition item by given `amount`.
 *
 *  Negative argument values will decrease it ("adding" a negative amount).
 *
 *      New value cannot go below zero and can only exceed maximum amount
 *  (@see `GetMaxAmount()` and @see `GetMaxTotalAmount()`) if `forceAddition`
 *  is also set to `true`.
 *      If resulting value is to go over the limits - it will be clamped inside
 *  allowed range.
 *
 *  @param  amount          How much ammo to add. `0` does nothing, negative
 *      values decrease the total ammo count. Cannot force total ammo to go into
 *      negative values.
 *  @param  forceAddition   This parameter is only relevant when changing ammo
 *      amount by `amount` will go over maximum (total) amount that referred
 *      ammo item can store. Setting this parameter to `true` will allow you to
 *      add more ammo than caller `EAmmo` normally supports.
 *      Cannot force total amount below zero.
 */
public function Add(int amount, optional bool forceAddition) {}

/**
 *  Returns current price of total ammo inside inventory of the owner of
 *  referred ammunition item.
 *
 *  In comparison, `EItem`'s method `GetPrice()` returns the price of only
 *  the ammo inside the referred item.
 *  @return Current price of total ammo inside inventory of the owner of
 *      referred ammunition item.
 */
public function int GetTotalPrice()
{
    return 0;
}

/**
 *  Returns how much would `ammoAmount` amount of referred ammo item would cost.
 *
 *  @return Price of `ammoAmount` amount of referred ammo item.
 */
public function int GetPriceOf(int ammoAmount)
{
    return 0;
}

/**
 *  Returns current amount of ammo inside referred ammunition item.
 *
 *  Guaranteed to not be negative, but can exceed maximum value
 *  (@see `GetMaxAmount()`).
 *
 *  @return Current amount of ammo inside referred ammunition item.
 */
public function int GetAmount()
{
    return 0;
}

/**
 *  Returns current total amount of ammo inside inventory of the owner of
 *  referred ammunition item.
 *
 *  Guaranteed to not be negative, but can exceed maximum value
 *  (@see `GetMaxTotalAmount()`).
 *
 *  @return Current amount of ammo inside referred ammunition item.
 */
public function int GetTotalAmount()
{
    return 0;
}

/**
 *  Changes amount of ammo inside referred ammunition item.
 *
 *      Negative values will be treated as `0`. Values that exceed
 *  maximum (total) amount will be automatically reduced to said maximum amount
 *  (@see `GetMaxAmount()` and @see `GetMaxTotalAmount()`), unless
 *  `forceAddition` is also set to `true`.
 *      If resulting value is to go over the limits - it will be clamped inside
 *  allowed range.
 *
 *  @param  amount          How much ammo should referred ammunition item have.
 *      Negative values are treated like `0`.
 *  @param  forceAddition   This parameter is only relevant when `amount` is
 *      higher than maximum (total) amount that referred ammo item can store.
 *      Setting this parameter to `true` will allow you to add more ammo than
 *      caller `EAmmo` normally supports. Cannot force total amount below zero.
 */
public function SetAmount(int amount, optional bool forceAddition) {}

/**
 *  Returns maximum amount of ammo referred ammunition item supports.
 *
 *      This is not a hard limit and can be bypassed by `SetAmount()` and
 *  `Add()` methods, meaning that it is possible that
 *  `GetAmount() > GetMaxAmount()`.
 *      Treat this value like a limit obtainable through "normal means", that
 *  can only be exceeded through cheats or special powerups of some kind.
 *
 *  @return Current "soft" max ammo limit of the referred ammunition item.
 *      Returning negative value means that there is no upper limit.
 *      Zero is considered a valid value.
 */
public function int GetMaxAmount()
{
    return 0;
}

/**
 *  Returns maximum total amount of ammo owner of the referred ammunition item
 *  can hold.
 *
 *      This is not a hard limit and can be bypassed by `SetAmount()` and
 *  `Add()` methods, meaning that it is possible that
 *  `GetTotalAmount() > GetMaxTotalAmount()`.
 *      Treat this value like a limit obtainable through "normal means", that
 *  can only be exceeded through cheats or special powerups of some kind.
 *
 *  @return Current "soft" max total ammo limit of the referred ammunition item.
 *      Returning negative value means that there is no upper limit.
 *      Zero is considered a valid value.
 */
public function int GetMaxTotalAmount()
{
    return 0;
}

/**
 *  Changes maximum amount of ammo referred ammunition item supports.
 *
 *      This is not a hard limit and can be bypassed by `SetAmount()` and
 *  `Add()` methods, meaning that it is possible that
 *  `GetAmount() > GetMaxAmount()`.
 *      Treat this value like a limit obtainable through "normal means", that
 *  can only be exceeded through cheats or special powerups of some kind.
 *
 *  Referred ammunition item does not have to support this method and is
 *  allowed to refuse changing maximum ammo value. It can also only support
 *  certain ranges of values.
 *
 *  @param  newMaxAmmo          New maximum ammo referred ammunition
 *      should support. Negative values mean unlimited maximum value.
 *  @param  leaveCurrentAmmo    Default value of `false` will result in current
 *      ammo being updated to not exceed `newMaxAmmo`, while setting this to
 *      `true` will leave it unchanged.
 *
 *  @return `true` if maximum value was changed and `false` otherwise.
 */
public function bool SetMaxAmount(
    int             newMaxAmmo,
    optional bool   leaveCurrentAmmo)
{
    return false;
}

/**
 *  Changes maximum total amount of ammo that owner of the referred
 *  ammunition item supports.
 *
 *      This is not a hard limit and can be bypassed by `SetAmount()` and
 *  `Add()` methods, meaning that it is possible that
 *  `GetTotalAmount() > GetMaxTotalAmount()`.
 *      Treat this value like a limit obtainable through "normal means", that
 *  can only be exceeded through cheats or special powerups of some kind.
 *
 *  Referred ammunition item does not have to support this method is allowed to
 *  refuse changing maximum ammo value. It can also only support certain ranges
 *  of values.
 *
 *  @param  newTotalMaxAmmo     New maximum total ammo owner of the referred
 *      ammunition can have. Negative values mean unlimited maximum value.
 *  @param  leaveCurrentAmmo    Default value of `false` will result in current
 *      total ammo being updated to not exceed `newTotalMaxAmmo`, while setting
 *      this to `true` will leave it unchanged.
 *
 *  @return `true` if maximum value was changed and `false` otherwise.
 */
public function bool SetMaxTotalAmount(
    int             newTotalMaxAmmo,
    optional bool   leaveCurrentAmmo)
{
    return false;
}

/**
 *  Checks whether the owner of the referred ammo item also has a weapon that
 *  can be loaded with that ammo.
 *
 *  @return `true` if owner of the referred ammo has a weapon that can be
 *      loaded with that ammo and `false` otherwise.
 */
public function bool HasWeapon()
{
    return false;
}

/**
 *  Maxes out amount of ammo of the referred ammunition item.
 *
 *  Does nothing if current ammo is already at (or higher) than maximum value 
 *  (@see `GetMaxAmount()`).
 */
public function Fill()
{
    if (GetMaxAmount() < 0)             return;
    if (GetAmount() >= GetMaxAmount())  return;

    SetAmount(GetMaxAmount());
}

defaultproperties
{
}