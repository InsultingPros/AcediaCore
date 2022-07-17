/**
 *      Base actor class to be used in Acedia instead of an `Actor`.
 *  `AcediaActor` provides access to Acedia's APIs through an accessor to
 *  a `Global` object, built-in mechanism for storing unneeded references in
 *  an object pool and constructor/finalizer.
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
class AcediaActor extends Actor
    abstract;

//  References to Acedia's APIs for simple access.
var protected Global        _;
var protected ServerGlobal  _server;
var protected ClientGlobal  _client;

//  To make logic simpler and increase efficiency, we allow storing a reference
//  to any actors in many different places. To know when we can actually
//  deallocate an actor, we keep this reference counter and only move actor
//  to the actor pool once nothing refers to it anymore.
var private int _refCounter;

//  Store allocation status to prevent possible issues
//  with freeing the same object several times without reallocating it
//  (such as preventing finalizers or constructors being called several times)
var private bool _isAllocated;

//  Remembers (in its `default` value) whether static constructor was already
//  called for this object.
var private bool _staticConstructorWasCalled;

//  We only want to compute hash code once and reuse generated value later,
//  since it cannot change without reallocation.
var private int     _cachedHashCode;
var private bool    _hashCodeWasCached;

//      This object will provide `string` to `Text` map, necessary for
//  efficient and convenient conversion methods.
//      It is implemented as a separate object to facilitate static (per-class)
//  hashing in `default` value that will not copy full stored stored data to
//  every instance. 
//      We use a separate `TextCache` for every class, because that way
//  efficiency of `string` to `Text` conversion depends only on amount of
//  `string`s cached for a given class.
var private TextCache _textCache;

//  Formatted `strings` declared in this array will be converted into `Text`s
//  available via `T()` method when static constructor is called.
var protected const array<string> stringConstants;

/**
 *  This function is called upon caller actor allocation.
 *
 *  Guaranteed to do nothing for allocated actors for which constructor
 *  was already called.
 *
 *  AVOID MANUALLY CALLING IT, UNLESS YOU ARE REIMPLEMENTING `MemoryAPI`.
 */
public simulated function _constructor()
{
    if (_isAllocated) return;
    _isAllocated = true;
    _refCounter = 1;
    _       = class'Global'.static.GetInstance();
    _server = class'ServerGlobal'.static.GetInstance();
    _client = class'ClientGlobal'.static.GetInstance();
    if (!default._staticConstructorWasCalled)
    {
        CreateTextCache();
        StaticConstructor();
        default._staticConstructorWasCalled = true;
    }
    _hashCodeWasCached = false;
    Constructor();
}

/**
 *  This function is called upon caller actor deallocation
 *  (essentially destruction).
 *
 *  Guaranteed to do nothing for already deallocated actors.
 *
 *  AVOID MANUALLY CALLING IT, UNLESS YOU ARE REIMPLEMENTING `MemoryAPI`.
 */
public simulated function _finalizer()
{
    if (!_isAllocated) return;
    _isAllocated = false;
    _refCounter = 0;
    Finalizer();
    _       = none;
    _server = none;
    _client = none;
}

/**
 *  Auxiliary method that is called before each static constructor to
 *  perform internal initialization work and check whether calling static
 *  constructor was already called.
 *
 *  @return `true` if static constructor should not be called
 *      and `false` if it should.
 */
protected simulated final static function bool StaticConstructorGuard()
{
    if (!default._staticConstructorWasCalled)
    {
        default._staticConstructorWasCalled = true;
        return false;
    }
    return true;
}

/**
 *  When using proper methods for creating actors (`MemoryAPI`),
 *  this method is guaranteed to be called after actor is spawned,
 *  but before it's returned from allocation method.
 *
 *  AVOID MANUALLY CALLING IT, UNLESS YOU ARE REIMPLEMENTING `MemoryAPI`.
 */
protected simulated function Constructor(){}

/**
 *  This method is called before actor is destroyed or deallocated by
 *  `MemoryAPI`.
 *
 *  AVOID MANUALLY CALLING IT, UNLESS YOU ARE REIMPLEMENTING `MemoryAPI`.
 */
protected simulated function Finalizer(){}

/**
 *  When using proper methods for creating objects (`MemoryAPI`),
 *  this method is guaranteed to be called before any object of this class is
 *  allocated.
 *
 *  Allowed to be called manually.
 *
 *  If you overload this method, first line must always be
 *  `if (StaticConstructorGuard()) return;`
 *  otherwise behavior of constructors should be considered undefined.
 */
public simulated static function StaticConstructor()
{
    StaticConstructorGuard();
}

/**
 *  This method is guaranteed to be called during Acedia's shutdown if
 *  `StaticConstructor()` was called on the caller class.
 */
protected simulated static function StaticFinalizer(){}

//      By default this method will only create `TextCache` instance if it
//  is needed, which is detected by checking whether `stringConstantsCopy` array
//  is not empty.
//      However even if it is empty - caller class might still make use of
//  `P()`, `C()` or `F()` methods that also use `TextCache`.
//  To force creating `TextCache` for them - set `forceCreation` parameter to
//  `true`.
private simulated final static function CreateTextCache(
    optional bool forceCreation)
{
    local int           i;
    local array<string> stringConstantsCopy;
    if (default._textCache != none)                             return;
    //  Prevent infinite recursion
    if (default.class == class'TextCache')                      return;
    //  If there is no string constants to convert into `Text`s,
    //  then this constructor has nothing to do.
    if (!forceCreation && default.stringConstants.length <= 0)  return;

    default._textCache = TextCache(__().memory.Allocate(class'TextCache'));
    //  Create `Text` constants
    stringConstantsCopy = default.stringConstants;
    for (i = 0; i < stringConstantsCopy.length; i += 1) {
        default._textCache.AddIndexedText(stringConstantsCopy[i]);
    }
}

/**
 *  This function is called each time this object is freed, to decrease it
 *  internal reference counter and know when it can be actually deallocated.
 *
 *  AVOID MANUALLY CALLING IT.
 */
public simulated final function _deref()
{
    if (!_isAllocated) {
        return;
    }
    _refCounter = Max(0, _refCounter - 1);
}

/**
 *  This function returns current reference counter for the caller actor.
 *  It is an amount of times it can be freed before being deallocated.
 *  This should correspond to the amount of places that reference it.
 *
 *  AVOID MANUALLY CALLING IT.
 */
public simulated final function int _getRefCount()
{
    if (!_isAllocated) {
        return 0;
    }
    return _refCounter;
}

/**
 *  Method that creates new reference to the given actor.
 *  Call this if you do not have ownership over the actor, but want to store
 *  somewhere - this way it should not get deallocated until you free your
 *  own reference.
 *
 *  @return Caller actor, to allow for easier use.
 */
public simulated final function AcediaActor NewRef()
{
    if (!_isAllocated) {
        return none;
    }
    _refCounter = Max(0, _refCounter + 1);
    return self;
}

/**
 *  Acedia actors cannot be deallocated into an actor pool, but they still
 *  support constructors and destructors and, therefore, track their own
 *  allocation status (`AcediaActor` is considered allocated between constructor
 *  and finalizer calls).
 *
 *  @return `true` if actor is allocated and ready to use, `false` otherwise
 *      (`Destroy()` was called for it directly or through deallocation method).
 */
public simulated final function bool IsAllocated()
{
    return _isAllocated;
}

/**
 *  Deallocates caller `AcediaActor`, calling its finalizer and then
 *  destroying it.
 */
public simulated final function FreeSelf()
{
    if (IsAllocated()) {
        _.memory.Free(self);
    }
}

/**
 *  Determines whether passed `Object` is equal to the caller.
 *
 *  By default simply compares references.
 *
 *  Reimplementing `IsEqual()` is allowed, but you need to make sure that:
 *      1. `a.IsEqual(b)` iff `b.IsEqual(a)`;
 *      2. If `a.IsEqual(b)` then `a.GetHashCode() == b.GetHashCode()`.
 *      3. `none` is only equal to `none;
 *      4. Result of `a.IsEqual(b)` does not change unless one of the objects
 *          gets deallocated;
 *  and also reimplement `CalculateHashCode()` in a compatible way.
 *
 *  @param  other   Object to compare to the caller.
 *  @return `true` if `other` is considered equal to the caller object,
 *      `false` otherwise.
 */
public simulated function bool IsEqual(Object other)
{
    return (self == other);
}

/**
 *  Calculates hash of an object. Overload this method if you want to change
 *  how object's hash is computed.
 *
 *  If you overload `IsEqual()` method to allow two different objects to
 *  be equal, you must implement `CalculateHashCode()` make sure such objects
 *  will also have the same hash value
 *
 *  By default it is just a random value, generated at the time of allocation.
 *
 *  @return Hash code for the caller object.
 */
protected simulated function int CalculateHashCode()
{
    return Rand(MaxInt);
}

/**
 *  Returns hash of an object.
 *
 *  Calculates hash only once, later using internally cached value.
 *
 *  By default it is just a random value.
 *  See `CalculateHashCode()` if you wish to change how hash code is computed.
 *
 *  @return Hash code for the caller object.
 */
public simulated final function int GetHashCode()
{
    if (_hashCodeWasCached) {
        return _cachedHashCode;
    }
    _hashCodeWasCached = true;
    _cachedHashCode = CalculateHashCode();
    return _cachedHashCode;
}

/**
 *  Method for returning predefined `Text` constants.
 *
 *  You can define array `stringConstants` (of `string`s) in `defaultproperties`
 *  that will statically be converted into `Text` objects first time an object
 *  of that class is created or `StaticConstructor()` method is called manually.
 *
 *  Provided that returned values are not deallocated, they always refer to
 *  the same `Text` object for any fixed `index`.
 *  Otherwise new `Text` object can be allocated.
 *
 *  @param  index   Index for which to return `Text` instance.
 *  @return `Text` instance containing the data in a `stringConstants[index]`.
 *      `none` if either `index < 0` or `index >= stringConstants.length`,
 *      otherwise guaranteed to be not `none`.
 *      Returned value should not be deallocated.
 */
public simulated static final function Text T(int index)
{
    //  Here cache should already be created, but make extra sure
    CreateTextCache(true);
    return default._textCache.GetIndexedText(index);
}

/**
 *  Method for creating `Text` objects from `string` variables.
 *
 *      Difference with `_.text.FromString()` method is that it will return
 *  the same `Text` instance for the same passed `string`, removing the need to
 *  deallocate created object.
 *      Exception is when returned `Text` instance is deallocated, then this
 *  method will allocate a new `Text` object.
 *
 *  @param  string  Plain `string` data to copy into a returned `Text` instance.
 *  @return `Text` instance that contains data from plain `string`.
 *      Guaranteed to be allocated, not `none`.
 *      Returned value should not be deallocated.
 */
public simulated static final function Text P(string string)
{
    CreateTextCache(true);
    return default._textCache.GetPlainText(string);
}

/**
 *  Method for creating `Text` objects from `string` variables.
 *
 *      Difference with `_.text.FromString()` method is that it will return
 *  the same `Text` instance for the same passed `string`, removing the need to
 *  deallocate created object.
 *      Exception is when returned `Text` instance is deallocated, then this
 *  method will allocate a new `Text` object.
 *
 *  @param  string  Colored `string` data to copy into a returned
 *      `Text` instance.
 *  @return `Text` instance that contains data from colored `string`.
 *      Guaranteed to be allocated, not `none`.
 *      Returned value should not be deallocated.
 */
public simulated static final function Text C(string string)
{
    CreateTextCache(true);
    return default._textCache.GetColoredText(string);
}

/**
 *  Method for creating `Text` objects from `string` variables.
 *
 *      Difference with `_.text.FromString()` method is that it will return
 *  the same `Text` instance for the same passed `string`, removing the need to
 *  deallocate created object.
 *      Exception is when returned `Text` instance is deallocated, then this
 *  method will allocate a new `Text` object.
 *
 *  @param  string  Formatted `string` data to copy into a returned
 *      `Text` instance.
 *  @return `Text` instance that contains data from formatted `string`.
 *      Guaranteed to be allocated, not `none`.
 *      Returned value should not be deallocated.
 */
public simulated static final function Text F(string string)
{
    CreateTextCache(true);
    return default._textCache.GetFormattedText(string);
}

/**
 *  Static method accessor to API namespace, necessary for Acedia's
 *  implementation.
 */
public simulated static final function Global __()
{
    return class'Global'.static.GetInstance();
}

/**
 *  Static method accessor to server API namespace, necessary for Acedia's
 *  implementation.
 */
public simulated static final function ServerGlobal __server()
{
    return class'ServerGlobal'.static.GetInstance();
}

/**
 *  Static method accessor to client API namespace, necessary for Acedia's
 *  implementation.
 */
public simulated static final function ClientGlobal __client()
{
    return class'ClientGlobal'.static.GetInstance();
}

/**
 *  If you are overloading this event - you have to first call
 *  `super.PreBeginPlay()`, otherwise Acedia might not function properly.
 */
public simulated function PreBeginPlay()
{
    super.PreBeginPlay();
    //  Calling this early here makes sure `Actor`s that catch `PreBeginPlay()`
    //  and similar early initialization events will find global API already
    //  setup and working
    _constructor();
}

/**
 *  If you are overloading this event - you have to call `super.Destroyed()`,
 *  otherwise Acedia might not function properly.
 */
public simulated function Destroyed()
{
    super.Destroyed();
    _finalizer();
}

/**
 *  This function is called upon Acedia's shutdown, if `StaticConstructor()`
 *  was called for this class.
 *
 *  AVOID MANUALLY CALLING IT.
 */
public simulated static function _cleanup()
{
    if (default._staticConstructorWasCalled) {
        StaticFinalizer();
    }
    default._textCache = none;
    default._staticConstructorWasCalled = false;
}

defaultproperties
{
    RemoteRole      = ROLE_None
    drawType        = DT_None
    bCollideActors  = false
    bCollideWorld   = false
    bBlockActors    = false
}