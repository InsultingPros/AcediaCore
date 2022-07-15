/**
 *  `EntityIterator` implementation for `KF1_Frontend`.
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
class KF1_EntityIterator extends EntityIterator;

var private bool initialized;

var private int                 currentIndex;
//      Simply store all traced `Actor`s here at the moment of user first
//  interacting with iterator's items: when either `Next()` or one of
//  the `Get...()` methods were called.
var private array<EPlaceable>   foundActors;
//  Did we already perform iteration through actors?
var private bool                iterated;

//  Iterator filters
var private bool onlyPawns;
var private bool onlyPlaceables;
var private bool onlyVisible;

protected function Finalizer()
{
    _.memory.FreeMany(foundActors);
    foundActors.length = 0;
    initialized = false;
}

/**
 *  Initializes `TracingIterator` that traces entities between `start` and
 *  `end` positions, in order starting from the `start`
 */
public final function Initialize()
{
    initialized = true;
}

private final function bool IsActorVisible(Actor actorToCheck)
{
    if (actorToCheck == none)                                   return false;
    if (actorToCheck.bHidden && !actorToCheck.bWorldGeometry)   return false;
    if (actorToCheck.drawType == DT_None)                       return false;

    return true;
}

//  Does actual tracing, but only once per iterator's lifecycle.
//  Assumes `initialized` is `true`.
private final function TryIterating()
{
    local Pawn              nextPawn;
    local Actor             nextActor;
    local class<Actor>      targetClass;
    local ServerLevelCore   core;

    //  Checking `initialized` flag is already done by every method that
    //  calls `TryTracing()`
    if (iterated) {
        return;
    }
    currentIndex = 0;
    if (onlyPawns) {
        targetClass = class'Pawn';
    }
    else {
        targetClass = class'Actor';
    }
    core = ServerLevelCore(class'ServerLevelCore'.static.GetInstance());
    //  TODO: We should not always use slow `AllActors()` method
    foreach core.AllActors(targetClass, nextActor)
    {
        if (onlyVisible && !IsActorVisible(nextActor)) {
            continue;
        }
        nextPawn = Pawn(nextActor);
        if (nextPawn != none)
        {
            foundActors[foundActors.length] =
                class'EKFPawn'.static.Wrap(nextPawn);
        }
        else {
            foundActors[foundActors.length] =
                class'EKFUnknownPlaceable'.static.Wrap(nextActor);
        }
    }
    iterated = true;
}

public function Iter Next()
{
    if (!initialized) {
        return self;
    }
    TryIterating();
    currentIndex += 1;
    return self;
}

public function AcediaObject Get()
{
    if (!initialized) {
        return none;
    }
    TryIterating();
    if (HasFinished()) {
        return none;
    }
    return foundActors[currentIndex].NewRef();
}

public function EPlaceable GetPlaceable()
{
    //  We only create `EPlaceable` child classes in this class
    return EPlaceable(Get());
}

public function EPawn GetPawn()
{
    local AcediaObject  result;
    local EPawn         pawnResult;

    if (!initialized) {
        return none;
    }
    result = Get();
    pawnResult = EPawn(result);
    if (pawnResult == none) {
        _.memory.Free(result);
    }
    return pawnResult;
}

public function bool HasFinished()
{
    TryIterating();
    return (currentIndex >= foundActors.length);
}

public function Iter LeaveOnlyNotNone()
{
    //  We cannot tracer `none` actors, so no need to do anything
    return self;
}

public function EntityIterator LeaveOnlyPawns()
{
    if (initialized && !iterated) {
        onlyPawns = true;
    }
    return self;
}

public function EntityIterator LeaveOnlyPlaceables() {
    //  Doesn't do anything for now
    //  TODO: make it actually do something
    return self;
}

public function EntityIterator LeaveOnlyVisible()
{
    if (initialized && !iterated) {
        onlyVisible = true;
    }
    return self;
}

defaultproperties
{
}