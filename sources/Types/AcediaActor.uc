/**
 *      Base actor class to be used in Acedia instead of an `Actor`.
 *  `AcediaActor` provides access to Acedia's APIs through an accessor to
 *  a `Global` object, built-in mechanism for storing unneeded references in
 *  an object pool and constructor/finalizer.
 *      It isn't guaranteed that `default._` will be defined for `AcediaActor`s.
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

//  Reference to Acedia's APIs for simple access.
var protected Global _;

//  Object pool to store objects of a particular class
var private AcediaObjectPool    _objectPool;
//  Do we even use object pool?
var public const bool           usesObjectPool;
//      Is there a limit to it? Any negative number means unlimited pool size,
//  `0` effectively disables object pool.
//      This value can be changed through Acedia's system settings.
var public const int            defaultMaxPoolSize;

//      Same actor can be reallocated for different purposes and as far as
//  users are concerned, - it should be considered a different actor after each
//  reallocation.
//      This variable stores a number unique to the current version and
//  can help distinguish between them.
var private int _lifeVersion;

//  Store allocation status to prevent possible issues
//  (such as preventing finalizers or constructors being called several times)
//  with freeing the same object several times without reallocating it
var private bool _isAllocated;

//  Remembers (in it's `default` value) whether static constructor was already
//  called for this object.
var private bool _staticConstructorWasCalled;

//  We only want to compute hash code once and reuse generated value later,
//  since it cannot changed without reallocation.
var private int     _cachedHashCode;
var private bool    _hashCodeWasCached;

//      This object will provide hashed `string` to `Text` map, necessary for
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
 *  FOR USE ONLY IN `MemoryAPI` METHODS.
 *
 *  If object pool is enabled for this actor, - returns a reference to it.
 *  Time of object pool creation is undefined and can happen during this call.
 *
 *  @return `AcediaObjectPool` that stores instances of caller actor's class,
 *      `none` iff `usesObjectPool == true || defaultMaxPoolSize == 0`.
 */
public final static function AcediaObjectPool _getPool()
{
    local MemoryService service;
    if (!default.usesObjectPool) {
        return none;
    }
    if (default._objectPool == none) {
        default._objectPool = new class'AcediaObjectPool';
        default._objectPool.Initialize(default.class);
        service = MemoryService(class'MemoryService'.static.Require());
        if (service != none) {
            service.RegisterNewPool(default._objectPool);
        }
    }
    return default._objectPool;
}

/**
 *  This function is called upon caller actor allocation.
 *
 *  Guaranteed to do nothing for allocated actors for which constructor
 *  was already called.
 *
 *  AVOID MANUALLY CALLING IT, UNLESS YOU ARE REIMPLEMENTING `MemoryAPI`.
 */
public function _constructor()
{
    if (_isAllocated) return;
    _isAllocated = true;
    _lifeVersion += 1;
    if (_ == none) {
        default._ = class'Global'.static.GetInstance();
        _ = default._;
    }
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
 *  This function is called upon caller actor deallocation.
 *
 *  Guaranteed to do nothing for already deallocated actors.
 *
 *  AVOID MANUALLY CALLING IT, UNLESS YOU ARE REIMPLEMENTING `MemoryAPI`.
 */
public function _finalizer()
{
    if (!_isAllocated) return;
    _isAllocated = false;
    Finalizer();
}

/**
 *  Auxiliary method that helps child classes to decide whether calling static
 *  constructor is still needed.
 *
 *  @return `true` if static constructor should not be called
 *      and `false` if it should.
 */
protected final static function bool StaticConstructorGuard()
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
protected function Constructor(){}

/**
 *  When using proper methods for creating objects (`MemoryAPI`),
 *  this method is guaranteed to be called after object of this class is
 *  allocated.
 *
 *  If you overload this method, first two lines must always be
 *  ____________________________________________________________________________
 *  |   if (StaticConstructorGuard()) return;
 *  |   super.StaticConstructor();
 *  |___________________________________________________________________________
 *  otherwise behavior of constructors should be considered undefined.
 */
public static function StaticConstructor(){}

//      By default this method will only create `TextCache` instance if it
//  is needed, which is detected by checking whether `stringConstantsCopy` array
//  is empty.
//      However even if it is - class might make use of `P()`, `C()` or `F()`
//  methods that also use `TextCache`. To force creating `TextCache` for them -
//  set `forceCreation` parameter to `true`.
private final static function CreateTextCache(optional bool forceCreation)
{
    local int           i;
    local array<string> stringConstantsCopy;
    //  Cache already created
    if (default._textCache != none)                             return;
    //  Do not do it for the cache itself
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
 *  This method is called before actor is destroyed or deallocated by
 *  `MemoryAPI`.
 *
 *  AVOID MANUALLY CALLING IT, UNLESS YOU ARE REIMPLEMENTING `MemoryAPI`.
 */
protected function Finalizer(){}

/**
 *  Acedia actors can be deallocated instead of being destroyed and
 *  deallocated instances should not be used while in the object pool.
 *  This method can be used to check if actor reference was deallocated.
 *
 *  @return `true` if actor is allocated and ready to use, `false` otherwise.
 */
public final function bool IsAllocated()
{
    return _isAllocated;
}

/**
 *  Marks caller `AcediaActor` free and stores it in the pool
 *  (if it is enabled and has free space).
 *
 *  @param  lifeVersion If specified, will only free actor that have provided
 *      life version. `<= 0` means actor must be freed regardless.
 */
public final function FreeSelf(optional int lifeVersion)
{
    if (lifeVersion <= 0 || lifeVersion == GetLifeVersion()) {
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
 *
 *  @param  other   Object to compare to the caller.
 *      `none` is only equal to the `none`.
 *  @return `true` if `other` is considered equal to the caller object,
 *      `false` otherwise.
 */
public function bool IsEqual(Object other)
{
    return (self == other);
}

/**
 *  Calculated hash of an object. Overload this method if you want to change
 *  how object's hash is computed.
 *
 *  `GetHashCode()` method uses it to calculate had code once and then cache it.
 *
 *  If you overload `IsEqual()` method to allow two different objects to
 *  be equal, you must implement `CalculateHashCode()` to return the same hash
 *  for them.
 *
 *  By default it is just a random value, generated at the time of allocation.
 *
 *  @return Hash code for the caller object.
 */
protected function int CalculateHashCode()
{
    return Rand(MaxInt);
}

/**
 *  Returns hash of an object.
 *
 *  Calculated hash only once, later using internally cached value.
 *
 *  By default it is just a random value.
 *  See `CalculateHashCode()` if you wish to change how hash code is computed.
 *
 *  @return Hash code for the caller object.
 */
public final function int GetHashCode()
{
    if (_hashCodeWasCached) {
        return _cachedHashCode;
    }
    _hashCodeWasCached = true;
    _cachedHashCode = CalculateHashCode();
    return _cachedHashCode;
}

/**
 *  Returns a positive number that uniquely changes for caller actor reference
 *  after each reallocation, which can help ensure that a reference was not
 *  deallocated and reallocated without us knowing at some point.
 *
 *  If referred actor is not allocated at the moment, always returns `-1`
 *
 *  @return A positive number unique for each reallocation of the caller's
 *      instance. `-1` if actor is not allocated.
 */
public final function int GetLifeVersion()
{
    if (!IsAllocated()) {
        return -1;
    }
    return _lifeVersion;
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
 */
public static final function Text T(int index)
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
 */
public static final function Text P(string string)
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
 */
public static final function Text C(string string)
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
 */
public static final function Text F(string string)
{
    CreateTextCache(true);
    return default._textCache.GetFormattedText(string);
}

/**
 *  Static method accessor to API namespace, necessary for Acedia's
 *  implementation.
 */
public static final function Global __()
{
    return class'Global'.static.GetInstance();
}

/**
 *  If you are overloading this event - you have to first call
 *  `super.PreBeginPlay()`, otherwise Acedia might not function properly.
 */
event PreBeginPlay()
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
event Destroyed()
{
    super.Destroyed();
    _finalizer();
}

defaultproperties
{
    usesObjectPool      = false
    defaultMaxPoolSize  = 0
}