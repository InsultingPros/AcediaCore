/**
 *  Subset of functionality for dealing with everything related to pawns'
 *  health.
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
class AHealthComponent extends AcediaObject
    abstract;

var protected Health_OnDamage_Signal onDamageSignal;

protected function Constructor()
{
    onDamageSignal = Health_OnDamage_Signal(
        _.memory.Allocate(class'Health_OnDamage_Signal'));
}

protected function Finalizer()
{
    _.memory.Free(onDamageSignal);
    onDamageSignal = none;
}

/**
 *  Signal that will be emitted whenever trading time starts.
 *
 *  [Signature]
 *  void <slot>(EPawn target, EPawn instigator, HashTable damageData)
 *
 *  @param  target      Pawn that took damage.
 *  @param  instigator  Pawn responsible for dealing damage.
 *  @param  damageData  Data set related to damage. Exact stored values can
 *      differ based on the implementation, but any implementation must support
 *      at least 4 values: "damage" - `int` value representing amount of damage
 *      `target will be dealt, "originalDamage" - originally intended damage for
 *      `target`, before other event handlers altered "damage" value (you can
 *      modify this value, but you shouldn't), "hitLocation" - `Vector` that
 *      describes the point of contact with whatever dealt this damage and
 *      "momentum" - `Vector` value describing momentum transferred to `target`
 *      as a result of the damage dealt.
 */
/* SIGNAL */
public function Health_OnDamage_Slot OnDamage(AcediaObject receiver)
{
    return Health_OnDamage_Slot(onDamageSignal.NewSlot(receiver));
}

defaultproperties
{
}