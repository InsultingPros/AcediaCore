/**
 *  Implementation of `EPawn` for classic Killing Floor weapons that changes
 *  as little as possible and only on request from another mod, otherwise not
 *  altering gameplay at all.
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
class EKFPawn extends EPawn;

var private NativeActorRef pawnReference;

protected function Finalizer()
{
    _.memory.Free(pawnReference);
    pawnReference = none;
}

/**
 *  Creates new `EKFPawn` that refers to the `pawnInstance` pawn.
 *
 *  @param  pawnInstance    Native pawn class that new `EKFPawn` will represent.
 *  @return New `EKFPawn` that represents given `pawnInstance`.
 */
public final static /*unreal*/ function EKFPawn Wrap(Pawn pawnInstance)
{
    local EKFPawn newReference;

    if (pawnInstance == none) {
        return none;
    }
    newReference = EKFPawn(__().memory.Allocate(class'EKFPawn'));
    newReference.pawnReference = __server().unreal.ActorRef(pawnInstance);
    return newReference;
}

public function EInterface Copy()
{
    local Pawn pawnInstance;

    pawnInstance = GetNativeInstance();
    return Wrap(pawnInstance);
}

public function bool Supports(class<EInterface> newInterfaceClass)
{
    if (newInterfaceClass == none)                  return false;
    if (newInterfaceClass == class'EPlaceable')     return true;
    if (newInterfaceClass == class'EKFPawn')        return true;

    return false;
}

public function EInterface As(class<EInterface> newInterfaceClass)
{
    if (!IsExistent()) {
        return none;
    }
    if (    newInterfaceClass == class'EPlaceable'
        ||  newInterfaceClass == class'EKFPawn')
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
    local EKFPawn otherPawn;

    otherPawn = EKFPawn(other);
    if (otherPawn == none) {
        return false;
    }
    return (GetNativeInstance() == otherPawn.GetNativeInstance());
}

/**
 *  Returns `Pawn` instance represented by the caller `EKFPawn`.
 *
 *  @return `Pawn` instance represented by the caller `EKFPawn`.
 */
public final /*unreal*/ function Pawn GetNativeInstance()
{
    if (pawnReference != none) {
        return Pawn(pawnReference.Get());
    }
    return none;
}

public function Vector GetLocation()
{
    local Pawn pawnInstance;

    pawnInstance = GetNativeInstance();
    if (pawnInstance != none) {
        return pawnInstance.location;
    }
    return Vect(0.0, 0.0, 0.0);
}


public function Rotator GetRotation()
{
    local Pawn pawnInstance;

    pawnInstance = GetNativeInstance();
    if (pawnInstance != none) {
        return pawnInstance.rotation;
    }
    return Rot(0.0, 0.0, 0.0);
}

public function bool IsStatic()
{
    local Pawn pawnInstance;

    pawnInstance = GetNativeInstance();
    if (pawnInstance != none) {
        return pawnInstance.bStatic;
    }
    return false;
}

public function bool IsColliding()
{
    local Pawn pawnInstance;

    pawnInstance = GetNativeInstance();
    if (pawnInstance != none) {
        return pawnInstance.bCollideActors;
    }
    return false;
}

public function bool IsBlocking()
{
    local Pawn pawnInstance;

    pawnInstance = GetNativeInstance();
    if (pawnInstance != none) {
        return pawnInstance.bBlockActors;
    }
    return false;
}

public function SetBlocking(bool newBlocking)
{
    local Pawn pawnInstance;

    pawnInstance = GetNativeInstance();
    if (pawnInstance != none) {
        pawnInstance.bBlockActors = newBlocking;
    }
}

public function bool IsVisible()
{
    local Pawn pawnInstance;

    pawnInstance = GetNativeInstance();
    if (pawnInstance != none) {
        return (!pawnInstance.bHidden && pawnInstance.drawType != DT_None);
    }
    return false;
}

public function EPlayer GetPlayer()
{
    local Pawn pawnInstance;

    pawnInstance = GetNativeInstance();
    if (pawnInstance != none)
    {
        return _.players.FromController(
            PlayerController(pawnInstance.controller));
    }
    return none;
}

public function int GetHealth()
{
    local Pawn pawnInstance;

    pawnInstance = GetNativeInstance();
    if (pawnInstance != none) {
        return pawnInstance.health;
    }
    return 0;
}

public function int GetMaxHealth()
{
    local Pawn pawnInstance;

    pawnInstance = GetNativeInstance();
    if (pawnInstance != none) {
        return int(pawnInstance.healthMax);
    }
    return 0;
}

public function Suicide()
{
    local Pawn pawnInstance;

    pawnInstance = GetNativeInstance();
    if (pawnInstance != none) {
        pawnInstance.Suicide();
    }
}

defaultproperties
{
}