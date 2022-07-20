/**
 *      Base class for simple API for managing a list of `SideEffect` info
 *  objects: can add, remove, return all and by package.
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
class SideEffectAPI extends AcediaObject
    abstract;

/**
 *  Returns all so far registered `SideEffect`s.
 *
 *  @return Array of all registered `SideEffect`s.
 */
public function array<SideEffect> GetAll();

/**
 *  Returns active `SideEffect` instance of the specified class
 *  `sideEffectClass`.
 *
 *  @param  sideEffectClass Class of side effect to return active instance of.
 *  @return Active `SideEffect` instance of the specified class
 *      `sideEffectClass`.
 *      `none` if either `sideEffectClass` is `none` or side effect of such
 *      class is not currently active.
 */
public function SideEffect GetClass(class<SideEffect> sideEffectClass);

/**
 *  Returns all so far registered `SideEffect`s from a package `packageName`
 *  (case insensitive).
 *
 *  @param  packageName Name of the package, in `SideEffect`s from which we are
 *      interested. Must be not `none`.
 *  @return Array of all registered `SideEffect`s from a package `packageName`.
 *      If `none`, returns an empty array.
 */
public function array<SideEffect> GetFromPackage(BaseText packageName);

/**
 *  Registers a new `SideEffect` object as active.
 *
 *  @param  newSideEffect   Instance of some `SideEffect` class to register as
 *      active side effect. Must not be `none`.
 *  @return `true` if new side effect was added and `false` otherwise.
 */
public function bool Add(SideEffect newSideEffect);

/**
 *  Removes `SideEffect` of the specified sub-class from the list of active
 *  side effects.
 *
 *  @param  sideEffectClass Class of the side effect to remove.
 *  @return `true` if some side effect was removed as a result of this operation
 *      and `false` otherwise (even if there was no side effect of specified
 *      class to begin with).
 */
public function bool RemoveClass(class<SideEffect> sideEffectClass);

defaultproperties
{
}