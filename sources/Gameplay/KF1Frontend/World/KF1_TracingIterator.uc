/**
 *  `TracingIterator` implementation for `KF1_Frontend`.
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
class KF1_TracingIterator extends TracingIterator;

var private bool                initialized;
var private Vector              startPosition, endPosition;

var private int                 currentIndex;
//      Simply store all traced `Actor`s here at the moment of user first
//  interacting with iterator's items: when either `Next()` or one of
//  the `Get...()` methods were called.
var private array<EPlaceable>   tracedActors;
//  Store information about hit location and normal in the other arrays,
//  alongside `tracedActors`.
var private array<Vector>       hitLocations, hitNormals;
//  Did we already perform tracing?
var private bool                traced;

//  Iterator filters
var private bool onlyPawns;

protected function Finalizer()
{
    _.memory.FreeMany(tracedActors);
    tracedActors.length = 0;
    initialized = false;
}

/**
 *  Initializes `TracingIterator` that traces entities between `start` and
 *  `end` positions, in order starting from the `start`
 */
public final function Initialize(Vector start, Vector end)
{
    if (initialized) {
        return;
    }
    startPosition = start;
    endPosition = end;
    initialized = true;
}

//  Does actual tracing, but only once per iterator's lifecycle.
//  Assumes `initialized` is `true`.
private final function TryTracing()
{
    local Pawn              nextPawn;
    local Actor             nextActor;
    local class<Actor>      targetClass;
    local ServerLevelCore   core;
    local Vector            nextHitLocation, nextHitNormal;

    //  Checking `initialized` flag is already done by every method that
    //  calls `TryTracing()`
    if (traced) {
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
    foreach core.TraceActors(class'Actor',
        nextActor,
        nextHitLocation,
        nextHitNormal,
        endPosition,
        startPosition)
    {
        hitLocations[hitLocations.length]   = nextHitLocation;
        hitNormals[hitNormals.length]       = nextHitNormal;
        nextPawn = Pawn(nextActor);
        if (nextPawn != none)
        {
            tracedActors[tracedActors.length] =
                class'EKFPawn'.static.Wrap(nextPawn);
        }
        else {
            tracedActors[tracedActors.length] =
                class'EKFUnknownPlaceable'.static.Wrap(nextActor);
        }
    }
    traced = true;
}

public function Iter Next(optional bool skipNone)
{
    if (!initialized) {
        return self;
    }
    TryTracing();
    currentIndex += 1;
    return self;
}

public function AcediaObject Get()
{
    if (!initialized) {
        return none;
    }
    TryTracing();
    if (HasFinished()) {
        return none;
    }
    return tracedActors[currentIndex].NewRef();
}

public function Vector GetHitLocation()
{
    if (!initialized) {
        return Vect(0.0f, 0.0f, 0.0f);
    }
    TryTracing();
    if (HasFinished()) {
        return Vect(0.0f, 0.0f, 0.0f);
    }
    return hitLocations[currentIndex];
}

public function Vector GetHitNormal()
{
    if (!initialized) {
        return Vect(0.0f, 0.0f, 0.0f);
    }
    TryTracing();
    if (HasFinished()) {
        return Vect(0.0f, 0.0f, 0.0f);
    }
    return hitNormals[currentIndex];
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
    return (currentIndex >= tracedActors.length);
}

public function Iter LeaveOnlyNotNone()
{
    //  We cannot tracer `none` actors, so no need to do anything
    return self;
}

public function TracingIterator LeaveOnlyPawns()
{
    if (initialized && !traced) {
        onlyPawns = true;
    }
    return self;
}

defaultproperties
{
}