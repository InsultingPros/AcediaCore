/**
 *  Provides Acedia with access to actors of a certain level (server, client or
 *  even entry level).
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
class LevelCore extends AcediaActor
    abstract;

/**
 *  # `LevelCore`
 *
 *  Since in UnrealScript mixing objects and actors (or, more precisely, storing
 *  `Actor`s in non-actor `Object`s) is dangerous, `LevelCore`s are needed to
 *  provide an access to a certain level and its `Actor`s.
 *
 *  `LevelCore is a singleton, however this isn't a design choice, but
 *  a side-effect of granting `Object`s safe access to an `Actor` through class
 *  and `static` methods and `default` fields.
 *
 *  ## Using `LevelCore`s
 *
 *  `LevelCore` itself is `abstract` and cannot be instantiated, so to make use
 *  of it, child classes must be declared. This allows one to specialize
 *  `LevelCore`: for example, Acedia's `ServerLevelCore` checks that net mode of
 *  the level it is created on is either `NM_DedicatedServer` or
 *  `NM_ListenServer`.
 *  Then Acedia's server API can only be created and used with such a level.
 *
 *  To create you own `LevelCore`, extend simply this base class.
 *  If you also want to specialize your level core, overload `CreateLevelCore()`
 *  method to add your checks.
 */

//  Allows to force creation of `LevelCore` only through `CreateLevelCore()`
//  method
var private bool blockSpawning;
//  Default value of this variable will store one and only existing version
//  `LevelCore`
var private LevelCore activeInstance;

protected function Finalizer()
{
    default.activeInstance = none;
}

public static function LevelCore CreateLevelCore(Actor source)
{
    if (GetInstance() != none)  return none;
    if (source == none)         return none;

    default.blockSpawning = false;
    default.activeInstance = source.Spawn(default.class);
    default.blockSpawning = true;
    return default.activeInstance;
}

public final static function LevelCore GetInstance()
{
    local bool instanceExists;
    instanceExists =    default.activeInstance != none
                    &&  !default.activeInstance.bPendingDelete;
    if (instanceExists) {
        return default.activeInstance;
    }
    return none;
}

//  Make sure only one instance of 'LevelCore' exists at any point in time.
event PreBeginPlay()
{
    if (default.blockSpawning || GetInstance() != none)
    {
        Destroy();
        return;
    }
    default.activeInstance = self;
    super.PreBeginPlay();
}

//  Clean up
event Destroyed()
{
    if (self == default.activeInstance) {
        default.activeInstance = none;
    }
    super.Destroyed();
}

defaultproperties
{
    blockSpawning = true
}