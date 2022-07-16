/**
 *      Implementation of `EPlaceable` for classic Killing Floor weapons that
 *  changes as little as possible and only on request from another mod,
 *  otherwise not altering gameplay at all.
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
class EKFPlaceable extends EPlaceable
    abstract;

var private NativeActorRef actorReference;

protected function Finalizer()
{
    _.memory.Free(actorReference);
    actorReference = none;
}

/**
 *  Creates new `EKFPlaceable` that refers to the `actorInstance` pawn.
 *
 *  @param  actorInstance    Native actor class that new `EKFPlaceable` will
 *      represent.
 *  @return New `EKFPlaceable` that represents given `actorInstance`.
 */
public final static /*unreal*/ function EKFPlaceable Wrap(Actor actorInstance)
{
    local EKFPlaceable newReference;

    if (actorInstance == none) {
        return none;
    }
    newReference = EKFPlaceable(__().memory.Allocate(class'EKFPlaceable'));
    newReference.actorReference = __server().unreal.ActorRef(actorInstance);
    return newReference;
}

public function EInterface Copy()
{
    local Actor actorInstance;

    actorInstance = GetNativeInstance();
    return Wrap(actorInstance);
}

public function bool Supports(class<EInterface> newInterfaceClass)
{
    if (newInterfaceClass == none)                  return false;
    if (newInterfaceClass == class'EPlaceable')     return true;
    if (newInterfaceClass == class'EKFPlaceable')   return true;

    if (newInterfaceClass == class'EKFPawn') {
        return (Pawn(GetNativeInstance()) != none);
    }
    return false;
}

public function EInterface As(class<EInterface> newInterfaceClass)
{
    local Pawn pawnInstance;

    if (!IsExistent()) {
        return none;
    }
    if (    newInterfaceClass == class'EPlaceable'
        ||  newInterfaceClass == class'EKFPlaceable')
    {
        return Copy();
    }
    if (    newInterfaceClass == class'EPawn'
        ||  newInterfaceClass == class'EKFPawn')
    {
        pawnInstance = Pawn(GetNativeInstance());
        if (pawnInstance != none) {
            return class'EKFPawn'.static.Wrap(pawnInstance);
        }
    }
    return none;
}

public function bool IsExistent()
{
    return (GetNativeInstance() != none);
}

public function bool SameAs(EInterface other)
{
    local EKFPlaceable otherPlaceable;

    otherPlaceable = EKFPlaceable(other);
    if (otherPlaceable == none) {
        return false;
    }
    return (GetNativeInstance() == otherPlaceable.GetNativeInstance());
}

/**
 *  Returns `Pawn` instance represented by the caller `EKFPlaceable`.
 *
 *  @return `Pawn` instance represented by the caller `EKFPlaceable`.
 */
public final /*unreal*/ function Actor GetNativeInstance()
{
    if (actorReference != none) {
        return actorReference.Get();
    }
    return none;
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

public function Rotator GetRotation()
{
    local Actor actorInstance;

    actorInstance = GetNativeInstance();
    if (actorInstance != none) {
        return actorInstance.rotation;
    }
    return Rot(0.0, 0.0, 0.0);
}

public function bool IsStatic()
{
    local Actor actorInstance;

    actorInstance = GetNativeInstance();
    if (actorInstance != none) {
        return actorInstance.bStatic;
    }
    return false;
}

public function bool IsColliding()
{
    local Actor actorInstance;

    actorInstance = GetNativeInstance();
    if (actorInstance != none) {
        return actorInstance.bCollideActors;
    }
    return false;
}

public function bool IsBlocking()
{
    local Actor actorInstance;

    actorInstance = GetNativeInstance();
    if (actorInstance != none) {
        return actorInstance.bBlockActors;
    }
    return false;
}

public function SetBlocking(bool newBlocking)
{
    local Actor actorInstance;

    actorInstance = GetNativeInstance();
    if (actorInstance != none) {
        actorInstance.bBlockActors = newBlocking;
    }
}

public function bool IsVisible()
{
    local Actor actorInstance;

    actorInstance = GetNativeInstance();
    if (actorInstance != none) {
        return (!actorInstance.bHidden && actorInstance.drawType != DT_None);
    }
    return false;
}

defaultproperties
{
}