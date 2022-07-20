/**
 *      An auxiliary actor class to help detect the exact moment when non-Acedia
 *  `Actor`s get destroyed. This is accomplished by attaching to them like to
 *  the base and then waiting for `BaseChange` event that will be called once
 *  our base gets destroyed.
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
class ActorStalker extends AcediaActor;

var private bool initialized;

//  Actor, whos destruction we want to detect
var private Actor target;

//  To notify that stalked target got destroyed
var private SimpleSignal onActorDestructionSignal;

protected function Constructor()
{
    onActorDestructionSignal =
        SimpleSignal(_.memory.Allocate(class'SimpleSignal'));
}

protected function Finalizer()
{
    _.memory.Free(onActorDestructionSignal);
}

/**
 *  Signal that will be emitted once stalked actor gets destroyed.
 *
 *  [Signature]
 *  void <slot>()
 */
/* SIGNAL */
public final function SimpleSlot OnActorDestruction(AcediaObject receiver)
{
    return SimpleSlot(onActorDestructionSignal.NewSlot(receiver));
}

/**
 *  Initialized `ActorStalker` to stalk a particular target.
 *
 *  Cannot fail unless `none` is passed as an argument.
 *
 *  @param  initTarget  Target that new `ActorStalker` will stalk.
 */
public final function Initialize(Actor initTarget)
{
    if (initTarget == none) {
        Destroy();
        return;
    }
    target = initTarget;
    SetBase(initTarget);
    initialized = true;
}

event BaseChange()
{
    if (initialized && target == none)
    {
        onActorDestructionSignal.Emit();
        Destroy();
    }
}

defaultproperties
{
    RemoteRole      = ROLE_None
    drawType        = DT_None
    bCollideActors  = false
    bCollideWorld   = false
    bBlockActors    = false
}