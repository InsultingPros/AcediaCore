/**
 *      Abstract interface that represents any kind of weapon.
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
class EWeapon extends EItem
    abstract;

/**
 *  Returns `EAmmo` for every ammo item that can be used with the caller's
 *  referred weapon. Method looks for that ammo in the weapon's owner's
 *  inventory.
 *
 *  @return Array of `EAmmo`s that refer to ammo items suitable for use with
 *      referred weapon. Every item of the returned array is guaranteed to not
 *      be `none` and refer to an existent item.
 */
public function array<EAmmo> GetAvailableAmmo()
{
    local array<EAmmo> emptyArray;
    return emptyArray;
}

/**
 *  Fills (@see `EAmmo.Fill()` method) `EAmmo` for every ammo item that can be
 *  used with the caller's referred weapon. Method looks for that ammo in
 *  the weapon's owner's inventory.
 */
public final function FillAmmo()
{
    local int           i;
    local array<EAmmo>  myAmmo;
    myAmmo = GetAvailableAmmo();
    for (i = 0; i < myAmmo.length; i += 1) {
        myAmmo[i].Fill();
    }
    _.memory.FreeMany(myAmmo);
}


defaultproperties
{
}