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
class KF1_WorldComponent extends AWorldComponent;

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
    newIterator.InitializeTracing(start, end);
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
        return Trace(start, controller.rotation);
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
    end = start + tracingDistance * Vector(nativePawn.controller.rotation);
    return TraceBetween(start, end);
}

public function EPlaceable Spawn(
    BaseText            template,
    optional Vector     location,
    optional Rotator    direction)
{
    local Actor             result;
    local Pawn              resultPawn;
    local class<Actor>      actorClass;
    local ServerLevelCore   core;

    actorClass = class<Actor>(_.memory.LoadClass(template));
    if (actorClass == none) {
        return none;
    }
    core = ServerLevelCore(class'ServerLevelCore'.static.GetInstance());
    result = core.Spawn(actorClass,,, location, direction);
    if (result == none) {
        return none;
    }
    resultPawn = Pawn(result);
    if (resultPawn != none) {
        return class'EKFPawn'.static.Wrap(resultPawn);
    }
    return class'EKFUnknownPlaceable'.static.Wrap(resultPawn);
}

defaultproperties
{
    tracingDistance = 10000
}