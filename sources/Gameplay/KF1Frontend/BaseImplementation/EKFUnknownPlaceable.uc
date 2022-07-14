/**
 *  Dummy implementation for `EPlaceable` interface that can wrap around
 *  `Actor` instances that Acedia does not know about - including the ones
 *  added by any other mods.
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
class EKFUnknownPlaceable extends EPlaceable;

var private NativeActorRef actorReference;

protected function Finalizer()
{
    _.memory.Free(actorReference);
    actorReference = none;
}

/**
 *  Creates new `EKFUnknownPlaceable` that refers to the `actorInstance` actor.
 *
 *  @param  actorInstance   Native `Actor` class that new `EKFUnknownPlaceable`
 *      will represent.
 *  @return New `EKFUnknownPlaceable` that represents given `actorInstance`.
 */
public final static /*unreal*/ function EKFUnknownPlaceable Wrap(
    Actor actorInstance)
{
    local EKFUnknownPlaceable newReference;

    if (actorInstance == none) {
        return none;
    }
    newReference = EKFUnknownPlaceable(
        __().memory.Allocate(class'EKFUnknownPlaceable'));
    newReference.actorReference = __server().unreal.ActorRef(actorInstance);
    return newReference;
}

/**
 *  Returns `Actor` instance represented by the caller `EKFUnknownPlaceable`.
 *
 *  @return `Actor` instance represented by the caller `EKFUnknownPlaceable`.
 */
public final /*unreal*/ function Actor GetNativeInstance()
{
    if (actorReference != none) {
        return actorReference.Get();
    }
    return none;
}

public function EInterface Copy()
{
    local Actor actorInstance;

    actorInstance = GetNativeInstance();
    return Wrap(actorInstance);
}

public function bool Supports(class<EInterface> newInterfaceClass)
{
    if (newInterfaceClass == none)                          return false;
    if (newInterfaceClass == class'EPlaceable')             return true;
    if (newInterfaceClass == class'EKFUnknownPlaceable')    return true;

    return false;
}

public function EInterface As(class<EInterface> newInterfaceClass)
{
    if (!IsExistent()) {
        return none;
    }
    if (    newInterfaceClass == class'EPlaceable'
        ||  newInterfaceClass == class'EKFUnknownPlaceable')
    {
        return Copy();
    }
    return none;
}

public function bool IsExistent()
{
    return (GetNativeInstance() != none);
}

public function bool SameAs(EInterface other)
{
    local EKFUnknownPlaceable otherUnknown;

    otherUnknown = EKFUnknownPlaceable(other);
    if (otherUnknown == none) {
        return false;
    }
    return (GetNativeInstance() == otherUnknown.GetNativeInstance());
}

public function Vector GetLocation()
{
    local Actor actorInstance;

    actorInstance = GetNativeInstance();
    if (actorInstance != none) {
        return actorInstance.location;
    }
    return Vect(0.0, 0.0, 0.0);
}

defaultproperties
{
}