/**
 *      Service that simply does some of the work of `InventoryService`, since
 *  working with `Actor`s that can get destroyed in the process is much safer
 *  inside another `Actor`.
 *      For description of all methods see `InventoryAPI`.
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
class InventoryService extends Service;

public function Weapon AddWeaponWithAmmo(
    Pawn            pawn,
    class<Weapon>   weaponClassToAdd,
    optional int    totalAmmoPrimary,
    optional int    totalAmmoSecondary,
    optional int    magazineAmmo,
    optional bool   clearStarterAmmo)
{
    local Weapon    newWeapon;
    local KFWeapon  newKFWeapon;
    if (pawn == none)       return none;
    newWeapon = Weapon(_.memory.Allocate(weaponClassToAdd));
    if (newWeapon == none)  return none;
    //  It is possible that `newWeapon` can get destroyed somewhere here,
    //  so add two more checks
    _server.unreal.GetKFGameType().WeaponSpawned(newWeapon);
    if (newWeapon == none)  return none;
    newWeapon.GiveTo(pawn);
    if (newWeapon == none)  return none;

    //  Update ammo & magazine (if applicable)
    if (clearStarterAmmo) {
        ClearAmmo(newWeapon);
    }
    newKFWeapon = KFWeapon(newWeapon);
    if (newKFWeapon != none)
    {
        if (clearStarterAmmo) {
            newKFWeapon.magAmmoRemaining = 0;
        }
        newKFWeapon.magAmmoRemaining += magazineAmmo;
    }
    if (totalAmmoPrimary > 0) {
        newWeapon.AddAmmo(totalAmmoPrimary, 0); 
    }
    if (totalAmmoSecondary > 0) {
        newWeapon.AddAmmo(totalAmmoSecondary, 1); 
    }
    return newWeapon;
}

public function Weapon MergeWeapons(
    Pawn            pawn,
    class<Weapon>   mergedClass,
    optional Weapon weaponToMerge1,
    optional Weapon weaponToMerge2,
    optional bool   clearStarterAmmo)
{
    local int       totalAmmoPrimary, totalAmmoSecondary, magazineAmmo;
    local KFWeapon  kfWeapon;
    if (pawn == none) {
        return none;
    }
    if (weaponToMerge1 != none)
    {
        kfWeapon = KFWeapon(weaponToMerge1);
        if (kfWeapon != none) {
            magazineAmmo += kfWeapon.magAmmoRemaining;
        }
        totalAmmoPrimary    += weaponToMerge1.AmmoAmount(0);
        totalAmmoSecondary  += weaponToMerge1.AmmoAmount(1);
        weaponToMerge1.Destroyed();
        if (weaponToMerge1 != none) {
            weaponToMerge1.Destroy();
        }
    }
    if (weaponToMerge2 != none)
    {
        kfWeapon = KFWeapon(weaponToMerge2);
        if (kfWeapon != none) {
            magazineAmmo += kfWeapon.magAmmoRemaining;
        }
        totalAmmoPrimary    += weaponToMerge2.AmmoAmount(0);
        totalAmmoSecondary  += weaponToMerge2.AmmoAmount(1);
        weaponToMerge2.Destroyed();
        if (weaponToMerge2 != none) {
            weaponToMerge2.Destroy();
        }
    }
    return AddWeaponWithAmmo(   pawn, mergedClass, totalAmmoPrimary,
                                totalAmmoSecondary, magazineAmmo,
                                clearStarterAmmo);
}

public final function ClearAmmo(Weapon weapon)
{
    local float     auxiliary, currentAmmoPrimary, currentAmmoSecondary;
    local KFWeapon  kfWeapon;
    if (weapon == none) {
        return;
    }
    weapon.GetAmmoCount(auxiliary, currentAmmoPrimary);
    //weapon.GetSecondaryAmmoCount(auxiliary, currentAmmoSecondary);
    weapon.AddAmmo(-currentAmmoPrimary, 0);
    weapon.AddAmmo(-currentAmmoSecondary, 1);
    kfWeapon = KFWeapon(weapon);
    if (kfWeapon != none) {
        kfWeapon.magAmmoRemaining = 0;
    }
}

defaultproperties
{
}