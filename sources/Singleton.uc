/**
 *      Singleton is an auxiliary class, meant to be used as a base for others,
 *  that allows for only one instance of it to exist.
 *      To make sure your child class properly works, either don't overload
 *  'PreBeginPlay' or make sure to call it's parent's version.
 *      Copyright 2019 Anton Tarasenko
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
class Singleton extends AcediaActor
    abstract;

//      Default value of this variable will store one and only existing version
//  of actor of this class.
var private Singleton activeInstance;

//      Setting default value of this variable to 'true' prevents creation of
//  a singleton, even if no instances of it exist.
//      Only a default value is ever used.
var protected bool blockSpawning;

public final static function Singleton GetInstance(optional bool spawnIfMissing)
{
    local bool instanceExists;
    instanceExists =    default.activeInstance != none
                    &&  !default.activeInstance.bPendingDelete;
    if (instanceExists) {
        return default.activeInstance;
    }
    if (spawnIfMissing) {
        return __().Spawn(default.class);
    }
    return none;
}

public final static function bool IsSingletonCreationBlocked()
{
    return default.blockSpawning;
}

protected function OnCreated(){}
protected function OnDestroyed(){}

//  Make sure only one instance of 'Singleton' exists at any point in time.
//      Instead of overloading this function we suggest you overload a special
//  event function `OnCreated()` that is called whenever a valid `Singleton`
//  instance is spawned.
//      If you absolutely must overload this function in any child class -
//  first call this version of the method and then check if
//  you are about to be deleted 'bDeleteMe == true':
//  ____________________________________________________________________________
//  |   super.PreBeginPlay();
//  |   // ^^^  If singleton wasn't already created, - only after that call
//  |   //      will instance, returned by 'GetInstance()', be set.
//  |   if (bDeleteMe)
//  |       return;
//  |___________________________________________________________________________
event PreBeginPlay()
{
    super.PreBeginPlay();
    if (default.blockSpawning || GetInstance() != none)
    {
        Destroy();
    }
    else
    {
        default.activeInstance = self;
        OnCreated();
    }
}

//  Make sure only one instance of 'Singleton' exists at any point in time.
//      Instead of overloading this function we suggest you overload a special
//  event function `OnDestroyed()` that is called whenever a valid `Singleton`
//  instance is destroyed.
//      If you absolutely must overload this function in any child class -
//  first call this version of the method.
event Destroyed()
{
    super.Destroyed();
    if (self == default.activeInstance)
    {
        OnDestroyed();
        default.activeInstance = none;
    }
}

defaultproperties
{
    blockSpawning = false
}