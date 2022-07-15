/**
 *  Signal class implementation for `GameRulesAPI`'s `OnNetDamage` signal.
 *      Copyright 2021 Anton Tarasenko
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
class GameRules_OnNetDamage_Signal extends Signal;

public function int Emit(
    int                 originalDamage,
    int                 damage,
    Pawn                injured,
    Pawn                instigatedBy,
    Vector              hitLocation,
    out Vector          momentum,
    class<DamageType>   damageType)
{
    local Slot  nextSlot;
    local int   newDamage;
    StartIterating();
    nextSlot = GetNextSlot();
    while (nextSlot != none)
    {
        newDamage = GameRules_OnNetDamage_Slot(nextSlot)
            .connect(   originalDamage, damage, injured, instigatedBy,
                        hitLocation, momentum, damageType);
        if (!nextSlot.IsEmpty()) {
            damage = newDamage;
        }
        nextSlot = GetNextSlot();
    }
    CleanEmptySlots();
    return damage;
}

defaultproperties
{
    relatedSlotClass = class'GameRules_OnNetDamage_Slot'
}