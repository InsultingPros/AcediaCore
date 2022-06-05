/**
 *  Implementation of `EItemTemplateInfo` for classic Killing Floor items that
 *  changes as little as possible and only on request from another mod,
 *  otherwise not altering gameplay at all.
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
class EKFItemTemplateInfo extends EItemTemplateInfo;

var private class<Inventory> classReference;

/**
 *  Creates new `EKFItemTemplateInfo` that refers to the `newClass` inventory
 *  class.
 *
 *  @param  newClass    Native inventory class that new `EKFItemTemplateInfo`
 *      will represent.
 *  @return New `EKFItemTemplateInfo` that represents given `newClass`.
 *      `none` if passed argument `newInventoryClass` is `none`.
 */
public final static /*unreal*/ function EKFItemTemplateInfo Wrap(
    class<Inventory> newInventoryClass)
{
    local EKFItemTemplateInfo newTemplateReference;
    if (newInventoryClass == none) {
        return none;
    }
    newTemplateReference =
        EKFItemTemplateInfo(__().memory.Allocate(class'EKFItemTemplateInfo'));
    newTemplateReference.classReference = newInventoryClass;
    return newTemplateReference;
}

public function array<Text> GetTags()
{
    local array<Text> tagArray;
    if (class<Weapon>(classReference) != none) {
        tagArray[0] = P("weapon").Copy();
    }
    return tagArray;
}

public function Text GetTemplateName()
{
    if (classReference == none) {
        return none;
    }
    return _.text.FromString(Locs(string(classReference)));
}

public function Text GetName()
{
    local class<KFWeaponPickup> pickupClass;
    if (classReference == none) {
        return none;
    }
    //  `KFWeaponPickup` names are usually longer and an overall better fit for
    //  being displayed
    pickupClass = class<KFWeaponPickup>(classReference.default.pickupClass);
    if (pickupClass != none && pickupClass.default.itemName != "") {
        return _.text.FromString(pickupClass.default.itemName);
    }
    return _.text.FromString(classReference.default.itemName);
}

defaultproperties
{
}