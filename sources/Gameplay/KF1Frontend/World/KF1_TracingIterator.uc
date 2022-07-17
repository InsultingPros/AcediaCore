/**
 *      `EntityIterator` / `TracingIterator` implementation for `KF1_Frontend`.
 *      Both iterators do essentially the same and can be implemented with
 *  a single class.
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

/**
 *  # `KF1_TracingIterator`
 *
 *      This iterator class implements both `EntityIterator` and
 *  `TracingIterator` for default Acedia implementation. It would've been better
 *  to have two separate classes in case someone tries to use `EntityIterator`
 *  as if it was `TracingIterator`, but that's highly unlikely and typical use
 *  should be unaffected.
 *
 *  ## Implementation
 *
 *      `KF1_TracingIterator` collects information about what filters user wants
 *  to apply to entities to be iterated over and, when user tries to access
 *  these entities in any way, it calls `TryIterating()` that decides whether
 *  actual `Actor` lookup is even needed, sets up necessary variables and calls
 *  `DoIterate_PickBest()` method that picks the best (fastest) method for
 *  iterating over `Actor`s based on the limitations given by the user.
 *      In case several entities were specified with `LeaveOnlyTouching()`
 *  method (or it was only one entity, but we're performing tracing), then
 *  several `Actor.TouchingActors()` lookups will be performed to find out which
 *  actors are touching all specified entities.
 */
var private bool initialized;
var private bool tracingIterator;
//  If two contradictory conditions were specified, iterator becomes empty
//  and doesn't bother doing any work
var private bool emptyIterator;
//  (For tracing iteration only)
var private Vector startPosition, endPosition;

//  Did we already perform iteration through actors?
var private bool                iterated;
//      Simply store all traced `Actor`s here at the moment of user first
//  interacting with iterator's items: when either `Next()` or one of
//  the `Get...()` methods were called.
var private array<EPlaceable>   foundActors;
//  Index we're at in `foundActors`, advanced by calling `Next()`
var private int                 currentIndex;
//  (For tracing iteration only)
//  Store information about hit location and normal in the other arrays,
//  alongside `foundActors`.
var private array<Vector>       hitLocations, hitNormals;

//  Iterator filters
var private IterFilter  pawnsFilter;
var private IterFilter  placeablesFilter;
var private IterFilter  collidingFilter;
var private IterFilter  visibleFilter;
var private IterFilter  staticFilter;

/**
 *  Describes limitations provided to iterator by `LeaveOnlyNearby()` or
 *  `LeaveOnlyNearbyToLocation()`.
 */
struct NearbyLimitation
{
    //  If this isn't `none` - use its location
    var EPlaceable  placeable;
    //  If `location` is `none` - use this vector instead
    var Vector      location;
    //  Distance entities must be away from `placeable`
    var float       distance;
    //  Squared `distance` to make distance checks faster
    var float       distanceSquared;
};
//  Should we even do distance checks?
var private bool                    distanceCheck;
//  Store the limitation with the shortest `distance` filed here.
//      Native iterators only take one location into an account, so we pick
//  the one most likely to filter majority of the entities to make native code
//  do most of the work.
var private NearbyLimitation        shortestLimitation;
var private array<NearbyLimitation> otherDistanceLimitations;

var private bool                touchingCheck;
var private array<EPlaceable>   touchers;
//  `Actor` from first existing `EPlaceable`, picked at the moment of building
//  `foundActors` to be used as a source for `TouchingActors`
//  We store it directly as `Actor`, so outside of iteration code it is only
//  allowed to be set to `none` to avoid crashes
var private Actor               mainToucher;

protected function Finalizer()
{
    local int i;

    currentIndex    = 0;
    initialized     = false;
    iterated        = false;
    //  Clear conditions
    //  ~ Simple conditions
    pawnsFilter         = ITF_Nothing;
    placeablesFilter    = ITF_Nothing;
    collidingFilter     = ITF_Nothing;
    visibleFilter       = ITF_Nothing;
    staticFilter        = ITF_Nothing;
    //  ~ Distance conditions
    distanceCheck       = false;
    _.memory.Free(shortestLimitation.placeable);
    shortestLimitation.placeable = none;
    for (i = 0; i < otherDistanceLimitations.length; i += 1) {
        _.memory.Free(otherDistanceLimitations[i].placeable);
    }
    otherDistanceLimitations.length = 0;
    //  ~ Touching conditions
    touchingCheck = false;
    _.memory.FreeMany(touchers);
    touchers.length = 0;
    mainToucher = none;
    //  Clear iterated actors
    _.memory.FreeMany(foundActors);
    foundActors.length  = 0;
    hitLocations.length = 0;
    hitNormals.length   = 0;
}

/**
 *  Initializes iterator to iterate over entities in the game world without
 *  tracing limitations.
 */
public final function Initialize()
{
    if (initialized) {
        return;
    }
    initialized     = true;
    tracingIterator = false;
}

/**
 *      Initializes iterator for entities that can be traced between `start` and
 *  `end` positions, in order starting from the `start`.
 *      Will iterate only over colliding entities.
 */
public final function InitializeTracing(Vector start, Vector end)
{
    if (initialized) {
        return;
    }
    startPosition   = start;
    endPosition     = end;
    collidingFilter = ITF_Have;
    initialized     = true;
    tracingIterator = true;
}

public function Vector GetTracingStart()
{
    return startPosition;
}

public function Vector GetTracingEnd()
{
    return endPosition;
}

private final function bool IsActorVisible(Actor actorToCheck)
{
    if (actorToCheck == none)                                   return false;
    if (actorToCheck.bHidden && !actorToCheck.bWorldGeometry)   return false;
    if (actorToCheck.drawType == DT_None)                       return false;

    return true;
}

private final function bool IsAllowed(Actor nextActor, array<Actor> allowedList)
{
    local int i;

    if (nextActor == none) {
        return false;
    }
    for (i = 0; i < allowedList.length; i += 1)
    {
        if (nextActor == allowedList[i]) {
            return true;
        }
    }
    return false;
}

private final function bool IsCloseEnough(Actor nextActor)
{
    local int       i;
    local Vector    nextLocation;

    for (i = 0; i < otherDistanceLimitations.length; i += 1)
    {
        if (otherDistanceLimitations[i].placeable != none) {
            nextLocation = otherDistanceLimitations[i].placeable.GetLocation();
        }
        else {
            nextLocation = otherDistanceLimitations[i].location;
        }
        if (    VSizeSquared(nextActor.location - nextLocation)
            >   otherDistanceLimitations[i].distanceSquared)
        {
            return false;
        }
    }
    return true;
}

//      Performs specified filter checks on the next `Actor` and adds it to
//  `foundActors` array in case it passes all.
//      If `allowedList` is empty, it is assumed that there is no limitations.
private final function bool ProcessActor(
    Actor           nextActor,
    array<Actor>    allowedList)
{
    local bool isVisible, isCollidable;
    local Pawn nextPawn;

    if (allowedList.length > 0 && IsAllowed(nextActor, allowedList)) {
        return false;
    }
    if (staticFilter == ITF_Have && !nextActor.bStatic) {
        return false;
    }
    if (staticFilter == ITF_NotHave && nextActor.bStatic) {
        return false;
    }
    isCollidable = (nextActor.bCollideActors || (LevelInfo(nextActor) != none));
    if (collidingFilter == ITF_Have && !isCollidable) {
        return false;
    }
    if (collidingFilter == ITF_NotHave && isCollidable) {
        return false;
    }
    if (placeablesFilter == ITF_Have && nextActor.bWorldGeometry) {
        return false;
    }
    if (placeablesFilter == ITF_NotHave && !nextActor.bWorldGeometry) {
        return false;
    }
    isVisible = IsActorVisible(nextActor);
    if (visibleFilter == ITF_Have && !isVisible) {
        return false;
    }
    if (visibleFilter == ITF_NotHave && isVisible) {
        return false;
    }
    if (distanceCheck && !IsCloseEnough(nextActor)) {
        return false;
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
    return true;
}

private final function array<Actor> GetActorsToTouch(
    class<Actor> targetClass)
{
    local int                   i;
    local Actor                 nextActor;
    local EKFPawn               asPawn;
    local EKFUnknownPlaceable   asUnknown;
    local array<Actor>          actorsToTouch;

    if (!touchingCheck) {
        return actorsToTouch;
    }
    for (i = 0; i < touchers.length; i += 1)
    {
        //  Get native instance
        asPawn      = EKFPawn(touchers[i]);
        asUnknown   = EKFUnknownPlaceable(touchers[i]);
        if (asPawn != none) {
            nextActor = asPawn.GetNativeInstance();
        }
        if (nextActor == none && asUnknown != none) {
            nextActor = asUnknown.GetNativeInstance();
        }
        if (nextActor == none) {
            continue;
        }
        //  Setup `mainToucher` / `actorsToTouch`
        if (!tracingIterator && mainToucher == none) {
            mainToucher = nextActor;
        }
        else {
            actorsToTouch[actorsToTouch.length] = nextActor;
        }
    }
    return actorsToTouch;
}

//      Calculates allow list based on additional `Actor`s that must be touched
//  by entities of interest.
//      Basically we call `TouchingActors()` for each of them and then take
//  intersection.
private final function array<Actor> GetAllowList(
    class<Actor> targetClass,
    array<Actor> actorsToTouch)
{
    local int           i, j;
    local Actor         nextActor;
    local int           requiredTouchesAmount;
    local array<int>    touchesAmount;
    local array<Actor>  allowedList;

    if (actorsToTouch.length <= 0) {
        return allowedList;
    }
    //  First get all actors touching the first one in array;
    //  This can be seen as intersection with all `Actors` in the game world.
    foreach actorsToTouch[0].TouchingActors(targetClass, nextActor)
    {
        allowedList[allowedList.length]     = nextActor;
        touchesAmount[touchesAmount.length] = 0;
    }
    //  Then for all `Actor`s we've found, count how many others from
    //  `actorsToTouch` they are touching
    for (i = 1; i < actorsToTouch.length; i += 1)
    {
        foreach actorsToTouch[i].TouchingActors(targetClass, nextActor)
        {
            for (j = 0; j < allowedList.length; j += 1)
            {
                if (allowedList[j] == nextActor)
                {
                    touchesAmount[j] += 1;
                    break;
                }
            }
        }
    }
    //      Actors remaining in `allowedList` must touch all actors from
    //  `actorsToTouch`.
    //      First one they touch by the way they were constructed, so we just
    //  need to ensure they touch `actorsToTouch.length - 1` of other `Actor`s
    //  from `actorsToTouch`
    i = 0;
    requiredTouchesAmount = actorsToTouch.length - 1;
    while (i < touchesAmount.length)
    {
        if (touchesAmount[i] != requiredTouchesAmount)
        {
            touchesAmount.Remove(i, 1);
            allowedList.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
    return allowedList;
}

//  Does actual tracing, but only once per iterator's lifecycle.
//  Assumes `initialized` is `true`.
private final function TryIterating()
{
    local ServerLevelCore   core;
    local class<Actor>      targetClass;
    local array<Actor>      actorsToTouch;
    local array<Actor>      allowedActors;

    if (iterated) {
        return;
    }
    if (emptyIterator)
    {
        iterated = true;
        return;
    }
    core = ServerLevelCore(class'ServerLevelCore'.static.GetInstance());
    if (pawnsFilter == ITF_Have) {
        targetClass =  class'Pawn';
    }
    else {
        targetClass =  class'Actor';
    }
    actorsToTouch = GetActorsToTouch(targetClass);
    if (actorsToTouch.length > 0)
    {
        allowedActors = GetAllowList(targetClass, actorsToTouch);
        //  If no actors are allowed - no need to iterate further,
        //  result of this iterator is an empty collection
        if (allowedActors.length <= 0)
        {
            iterated = true;
            return;
        }
    }
    DoIterate_PickBest(core, targetClass, allowedActors);
    iterated = true;
}

//  For iterations where we don't use `shortestLimitation`'s data in native
//  iterator, so we have to do that check manually
private final function MergeShortestDistanceLimitationIntoOthers()
{
    otherDistanceLimitations[otherDistanceLimitations.length] =
        shortestLimitation;
    shortestLimitation.placeable = none;
}

//  Empty `allowedActors` here means no limitations
private final function DoIterate_PickBest(
    LevelCore       core,
    class<Actor>    targetClass,
    array<Actor>    allowedActors)
{
    //  If tracing is required - there is no choice, but to use tracing iterator
    if (tracingIterator)
    {
        MergeShortestDistanceLimitationIntoOthers();
        DoIterate_Trace(core, targetClass, allowedActors);
        mainToucher = none;
        return;
    }
    //  Limiting iteration to touching actors is probably the fastest
    if (touchingCheck)
    {
        MergeShortestDistanceLimitationIntoOthers();
        DoIterate_Touching(targetClass, allowedActors);
        mainToucher = none;
        return;
    }
    //  There is no need to have `mainToucher` in the code below, since if touch
    //  limitations were specified, it is needed either tracing or
    //  `DoIterate_Touching()`
    mainToucher = none;
    //      Otherwise limiting iteration to colliding actors is always
    //  preferable, but only doable if we're also filtering by distance.
    if (distanceCheck)
    {
        if (collidingFilter == ITF_Have) {
            DoIterate_Colliding(core, targetClass);
        }
        else {
            //  Otherwise `RadiusActors` is still better than nothing
            DoIterate_Radius(core, targetClass);
        }
        return;
    }
    //  If above fails - try to at least limit iteration to dynamic actors
    if (staticFilter == ITF_NotHave)
    {
        DoIterate_Dynamic(core, targetClass);
        return;
    }
    DoIterate_All(core, targetClass);
}

private final function DoIterate_Trace(
    LevelCore       core,
    class<Actor>    targetClass,
    array<Actor>    allowedActors)
{
    local Actor     nextActor;
    local Vector    nextHitLocation, nextHitNormal;

    foreach core.TraceActors(targetClass,
        nextActor,
        nextHitLocation,
        nextHitNormal,
        endPosition,
        startPosition)
    {

        if (ProcessActor(nextActor, allowedActors))
        {
            hitLocations[hitLocations.length]   = nextHitLocation;
            hitNormals[hitNormals.length]       = nextHitNormal;
        }
    }
}

private final function DoIterate_Touching(
    class<Actor>    targetClass,
    array<Actor>    allowedActors)
{
    local Actor nextActor;

    foreach mainToucher.TouchingActors(targetClass, nextActor) {
        ProcessActor(nextActor, allowedActors);
    }
}

private final function DoIterate_Colliding(
    LevelCore       core,
    class<Actor>    targetClass)
{
    local Actor         nextActor;
    local Vector        location;
    local array<Actor>  emptyActorArray;

    if (shortestLimitation.placeable != none) {
        location = shortestLimitation.placeable.GetLocation();
    }
    else {
        location = shortestLimitation.location;
    }
    foreach core.CollidingActors(
        targetClass,
        nextActor,
        shortestLimitation.distance,
        location)
    {
        ProcessActor(nextActor, emptyActorArray);
    }
}

private final function DoIterate_Radius(
    LevelCore       core,
    class<Actor>    targetClass)
{
    local Actor         nextActor;
    local Vector        location;
    local array<Actor>  emptyActorArray;

    if (shortestLimitation.placeable != none) {
        location = shortestLimitation.placeable.GetLocation();
    }
    else {
        location = shortestLimitation.location;
    }
    foreach core.RadiusActors(
        targetClass,
        nextActor,
        shortestLimitation.distance,
        location)
    {
        ProcessActor(nextActor, emptyActorArray);
    }
}

private final function DoIterate_Dynamic(
    LevelCore       core,
    class<Actor>    targetClass)
{
    local Actor         nextActor;
    local array<Actor>  emptyActorArray;

    foreach core.DynamicActors(targetClass, nextActor) {
        ProcessActor(nextActor, emptyActorArray);
    }
}

private final function DoIterate_All(
    LevelCore       core,
    class<Actor>    targetClass)
{
    local Actor         nextActor;
    local array<Actor>  emptyActorArray;

    foreach core.AllActors(targetClass, nextActor) {
        ProcessActor(nextActor, emptyActorArray);
    }
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

public function Vector GetHitLocation()
{
    if (!initialized) {
        return Vect(0.0f, 0.0f, 0.0f);
    }
    TryIterating();
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
    TryIterating();
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
    TryIterating();
    return (currentIndex >= foundActors.length);
}

public function Iter LeaveOnlyNotNone()
{
    //  We cannot iterate over `none` actors with native iterators, so this
    //  condition is automatically satisfied
    return self;
}

private final function UpdateFilter(
    out IterFilter  actualValue, 
    IterFilter      newValue)
{
    if (!initialized)   return;
    if (iterated)       return;

    if (actualValue == ITF_Nothing) {
        actualValue = ITF_Have;
    }
    else if (actualValue != newValue)
    {
        //  Filter already had value and it contradicted our current one
        emptyIterator = true;
    }
}

public function EntityIterator LeaveOnlyPawns()
{
    UpdateFilter(pawnsFilter, ITF_Have);
    return self;
}

public function EntityIterator LeaveOnlyNonPawns()
{

    UpdateFilter(pawnsFilter, ITF_NotHave);
    return self;
}

public function EntityIterator LeaveOnlyPlaceables()
{
    UpdateFilter(placeablesFilter, ITF_Have);
    return self;
}

public function EntityIterator LeaveOnlyNonPlaceables()
{
    UpdateFilter(placeablesFilter, ITF_NotHave);
    return self;
}

public function EntityIterator LeaveOnlyVisible()
{
    UpdateFilter(visibleFilter, ITF_Have);
    return self;
}

public function EntityIterator LeaveOnlyInvisible()
{
    UpdateFilter(visibleFilter, ITF_NotHave);
    return self;
}

public function EntityIterator LeaveOnlyColliding()
{
    UpdateFilter(collidingFilter, ITF_Have);
    return self;
}

public function EntityIterator LeaveOnlyNonColliding()
{
    UpdateFilter(collidingFilter, ITF_NotHave);
    return self;
}

public function EntityIterator LeaveOnlyStatic()
{
    UpdateFilter(staticFilter, ITF_Have);
    return self;
}

public function EntityIterator LeaveOnlyDynamic()
{
    UpdateFilter(staticFilter, ITF_NotHave);
    return self;
}

private function AddDistanceLimitation(NearbyLimitation newLimitation)
{
    if (!distanceCheck)
    {
        distanceCheck = true;
        shortestLimitation = newLimitation;
        return;
    }
    if (newLimitation.distance < shortestLimitation.distance)
    {
        otherDistanceLimitations[otherDistanceLimitations.length] =
            shortestLimitation;
        shortestLimitation = newLimitation;
    }
    else
    {
        otherDistanceLimitations[otherDistanceLimitations.length] =
            newLimitation;
    }
}

public function EntityIterator LeaveOnlyNearby(
    EPlaceable  placeable,
    float       radius)
{
    local NearbyLimitation newLimitation;

    if (!initialized)       return self;
    if (iterated)           return self;
    if (placeable == none)  return self;

    placeable.NewRef();
    newLimitation.placeable         = placeable;
    newLimitation.location          = placeable.GetLocation();
    newLimitation.distance          = radius;
    newLimitation.distanceSquared   = radius * radius;
    AddDistanceLimitation(newLimitation);
    return self;
}

public function EntityIterator LeaveOnlyNearbyToLocation(
    Vector  location,
    float   radius)
{
    local NearbyLimitation newLimitation;

    if (!initialized)   return self;
    if (iterated)       return self;

    newLimitation.location          = location;
    newLimitation.distance          = radius;
    newLimitation.distanceSquared   = radius * radius;
    AddDistanceLimitation(newLimitation);
    return self;
}

public function EntityIterator LeaveOnlyTouching(EPlaceable placeable)
{
    if (!initialized)       return self;
    if (iterated)           return self;
    if (placeable == none)  return self;

    touchingCheck = true;
    placeable.NewRef();
    touchers[touchers.length] = placeable;
    return self;
}

defaultproperties
{
}