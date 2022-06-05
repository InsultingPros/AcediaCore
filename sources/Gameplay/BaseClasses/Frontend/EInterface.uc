/**
 *      Base class for all entity interfaces. Entity interface is a reference to
 *  an entity inside the game world that provides a specific API for
 *  that entity.
 *      A single entity is not bound to a single `EInterface` class,
 *  e.g. a weapon can provide `EWeapon` and `ESellable` interfaces.
 *      An entity can also have several `EInterface` instances reference it at
 *  once (including those of the same type). Deallocating one such reference
 *  should not affect referred entity in any way and should be treated as simply
 *  getting rid of one of the references.
 *      Copyright 2021 - 2022 Anton Tarasenko
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
 class EInterface extends AcediaObject
    abstract;

/**
 *  Makes a copy of the caller interface, producing a new `EInterface` of
 *  the exactly the same class (`EWeapon` will produce another `EWeapon`).
 *
 *  This should never fail. Even if referred entity is already gone.
 *
 *  @return Copy of the caller `EInterface`, of the exactly the same class.
 *      Guaranteed to not be `none`.
 */
public function EInterface Copy()
{
    return none;
}

/**
 *  Checks if entity, referred to by the caller `EInterface` supports
 *  `newInterfaceClass` interface class.
 *
 *  @param  newInterfaceClass   Class of the `EInterface`, for which method
 *      should check support by entity, referred to by the caller `EInterface`.
 *  @return `true` if referred entity supports `newInterfaceClass` and
 *      `false` otherwise.
 */
public function bool Supports(class<EInterface> newInterfaceClass)
{
    return false;
}

/**
 *  Provides `EInterface` reference of given class `newInterfaceClass` to
 *  the entity, referred to by the caller `EInterface` (if supported).
 *
 *  Can be used to access entity's other API.
 *
 *  @param  newInterfaceClass   Class of the new `EInterface` for the entity,
 *      referred to by the caller `EInterface`.
 *  @return `EInterface` of the given class `newInterfaceClass` that refers to
 *      the caller `EInterface`'s entity.
 *      Can only be `none` if either caller `EInterface`'s entity does not
 *      support `EInterface` of the specified class or caller `EInterface`
 *      no longer exists (`self.IsExistent() == false`).
 */
public function EInterface As(class<EInterface> newInterfaceClass)
{
    return none;
}

/**
 *  Checks whether caller `EInterface` refers to the entity that still exists
 *  in the game world.
 *
 *  Once destroyed, same entity will not come into existence again (but can be
 *  replaced by its exact copy), so once `EInterface`'s `IsExistent()` call
 *  returns `false` it will never return `true` again.
 *
 *  `EInterface`'s entity being gone is not the same as that `EInterface` being
 *  deallocated - deallocation of such `EInterface` still has to be manually
 *  done.
 *
 *  @return `true` if caller `EInterface` refers to the entity that exists in
 *      the game world and `false` otherwise.
 */
public function bool IsExistent()
{
    return false;
}

/**
 *  Checks whether caller interface refers to the same entity as
 *  the `other` argument.
 *
 *  If two `EInterface`s referred to the same entity
 *  (`SameAs()` returned `true`), but that entity got destroyed,
 *  these `EInterface`s will not longer be considered "same"
 *  (`SameAs()` will return false).
 *
 *  @param  other   `EInterface` to check for referring to the same entity.
 *  @return `true` if `other` refers to the same entity as the caller
 *      `EInterface` and `false` otherwise.
 */
public function bool SameAs(EInterface other)
{
    return false;
}

defaultproperties
{
}