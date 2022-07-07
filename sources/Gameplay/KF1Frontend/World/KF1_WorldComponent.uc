/**
 *  `AWorldComponent`'s implementation for `KF1_Frontend`.
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
class KF1_WorldComponent extends AWorldComponent
    abstract;

var private const float tracingDistance;

public function TracingIterator Trace(Vector start, Rotator direction)
{
    local Vector end;

    end = start + tracingDistance * Vector(direction);
    return TraceBetween(start, end);
}

public function TracingIterator TraceBetween(Vector start, Vector end)
{
    local KF1_TracingIterator newIterator;

    newIterator = KF1_TracingIterator(
        _.memory.Allocate(class'KF1_TracingIterator'));
    newIterator.Initialize(start, end);
    return newIterator;
}

public function TracingIterator TracePlayerSight(EPlayer player)
{
    local Vector            start;
    local Rotator           direction;
    local Actor             dummy;
    local EPawn             pawn;
    local PlayerController  controller;
    local TracingIterator   pawnTracingIterator;

    if (player == none) {
        return none;
    }
    pawn = player.GetPawn();
    if (pawn != none)
    {
        pawnTracingIterator = TraceSight(pawn);
        _.memory.Free(pawn);
        return pawnTracingIterator;
    }
    controller = player.GetController();
    if (controller != none)
    {
        controller.PlayerCalcView(dummy, start, direction);
        return Trace(start, direction);
    }
    return none;
}

public function TracingIterator TraceSight(EPawn pawn)
{
    local EKFPawn   kfPawn;
    local Pawn      nativePawn;
    local Vector    start, end;

    kfPawn = EKFPawn(pawn);
    if (kfPawn == none)     return none;
    nativePawn = kfPawn.GetNativeInstance();
    if (nativePawn == none) return none;

    start = nativePawn.location + nativePawn.EyePosition();
    end = start + tracingDistance * Vector(nativePawn.rotation);
    return TraceBetween(start, end);
}

defaultproperties
{
    tracingDistance = 10000
}