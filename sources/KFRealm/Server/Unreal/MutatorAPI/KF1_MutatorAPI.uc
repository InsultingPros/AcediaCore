/**
 *  Acedia's default implementation for `MutatorAPI` API.
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
class KF1_MutatorAPI extends MutatorAPI;

/* SIGNAL */
public function Mutator_OnCheckReplacement_Slot OnCheckReplacement(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    signal = service.GetSignal(class'Mutator_OnCheckReplacement_Signal');
    return Mutator_OnCheckReplacement_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function Mutator_OnMutate_Slot OnMutate(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    signal = service.GetSignal(class'Mutator_OnMutate_Signal');
    return Mutator_OnMutate_Slot(signal.NewSlot(receiver));
}

/* SIGNAL */
public function Mutator_OnModifyLogin_Slot OnModifyLogin(
    AcediaObject receiver)
{
    local Signal                signal;
    local ServerUnrealService   service;

    service = ServerUnrealService(class'ServerUnrealService'.static.Require());
    signal = service.GetSignal(class'Mutator_OnModifyLogin_Signal');
    return Mutator_OnModifyLogin_Slot(signal.NewSlot(receiver));
}

defaultproperties
{
}