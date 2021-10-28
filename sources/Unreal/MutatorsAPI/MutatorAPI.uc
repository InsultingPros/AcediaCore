/**
 *      Low-level API that provides set of utility methods for working with
 *  `Mutator`s.
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
class MutatorAPI extends AcediaObject;

/**
 *      Called whenever mutators (Acedia's mutator) is asked to check whether
 *  an `Actor` should be replaced. This check is done right after that `Actor`
 *  has spawned.
 *
 *      This check is called in UnrealScript and defined in base `Actor` class
 *  inside `PreBeginPlay()` event. It makes each `Actor` call base mutator's
 *  (the one linked as the head of the mutator linked list in `GameInfo`)
 *  `CheckRelevance()` method for itself as long as it has
 *  `bGameRelevant == false` and current `NetMode` is not `NM_Client`.
 *      `CheckRelevance()` is only called on the base mutator and always first
 *  checks with `AlwaysKeep()` method, that allows any mutator to prevent any
 *  further check altogether and then `IsRelevant()` check that then calls
 *  sub-check `CheckReplacement()` this signal catches.
 *      Any described event that is not `CheckRelevance()` is propagated through
 *  the linked mutator list.
 *
 *  [Signature]
 *  bool <slot>(Actor other, out byte isSuperRelevant)
 *
 *  @param  other           `Actor` that is checked for
 *      replacement / modification.
 *  @param  isSuperRelevant Variable with unclear intention. It is defined in
 *      base mutator's `CheckRelevance()` method as a local variable and then
 *      passed as an `out` parameter for `IsRelevant()` and `CheckRelevance()`
 *      checks and not really used for anything once these checks are complete.
 *      Some [sources]
 *      (https://wiki.beyondunreal.com/Legacy:Chain_Of_Events_At_Level_Startup)
 *      indicate that it used to omit additional `GameInfo`'s relevancy checks,
 *      however does not to serve any function in Killing Floor.
 *      Mutators might repurpose it for their own uses, but I am not aware of
 *      any that do.
 *  @return `false` if you want `other` to be destroyed and `true` otherwise.
 */
/* SIGNAL */
public final function Mutator_OnCheckReplacement_Slot OnCheckReplacement(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;
    service = UnrealService(class'UnrealService'.static.Require());
    signal = service.GetSignal(class'Mutator_OnCheckReplacement_Signal');
    return Mutator_OnCheckReplacement_Slot(signal.NewSlot(receiver));
}

/**
 *  Called on a server whenever a player uses a "mutate" console command.
 *
 *  [Signature]
 *  <slot>(string command, PlayerController sendingPlayer)
 *
 *  @param  command         Text, typed by the player after "mutate" command,
 *      trimming spaces from the left.
 *  @param  sendingPlayer   Controller of the player who typed command that
 *      caused this call.
 */
/* SIGNAL */
public final function Mutator_OnMutate_Slot OnMutate(
    AcediaObject receiver)
{
    local Signal        signal;
    local UnrealService service;
    service = UnrealService(class'UnrealService'.static.Require());
    signal = service.GetSignal(class'Mutator_OnMutate_Signal');
    return Mutator_OnMutate_Slot(signal.NewSlot(receiver));
}

defaultproperties
{
}