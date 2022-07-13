/**
 *      Simple API for managing a list of `SideEffect` info objects: can add,
 *  remove, return all and by package.
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
class SideEffectAPI extends AcediaObject;

var private array<SideEffect> activeSideEffects;

/**
 *  Returns all so far registered `SideEffect`s.
 *
 *  @return Array of all registered `SideEffect`s.
 */
public final function array<SideEffect> GetAll()
{
    local int i;

    for (i = 0; i < activeSideEffects.length; i += 1) {
        activeSideEffects[i].NewRef();
    }
    return activeSideEffects;
}

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
public final function SideEffect GetClass(class<SideEffect> sideEffectClass)
{
    local int i;

    if (sideEffectClass == none) {
        return none;
    }
    for (i = 0; i < activeSideEffects.length; i += 1)
    {
        if (activeSideEffects[i].class == sideEffectClass)
        {
            activeSideEffects[i].NewRef();
            return activeSideEffects[i];
        }
    }
    return none;
}

/**
 *  Returns all so far registered `SideEffect`s from a package `packageName`
 *  (case insensitive).
 *
 *  @param  packageName Name opf the package, in `SideEffect`s from which we are
 *      interested. Must be not `none`.
 *  @return Array of all registered `SideEffect`s from a package `packageName`.
 *      If `none`, returns an empty array.
 */
public final function array<SideEffect> GetFromPackage(BaseText packageName)
{
    local int               i;
    local Text              nextPackage;
    local array<SideEffect> result;

    if (packageName == none) {
        return result;
    }
    for (i = 0; i < activeSideEffects.length; i += 1)
    {
        nextPackage = activeSideEffects[i].GetPackage();
        if (nextPackage.Compare(packageName, SCASE_INSENSITIVE))
        {
            activeSideEffects[i].NewRef();
            result[result.length] = activeSideEffects[i];
        }
        _.memory.Free(nextPackage);
    }
    return result;
}

/**
 *  Registers a new `SideEffect` object as active.
 *
 *  @param  newSideEffect   Instance of some `SideEffect` class to register as
 *      active side effect. Must not be `none`.
 *  @return `true` if new side effect was added and `false` otherwise.
 */
public final function bool Add(SideEffect newSideEffect)
{
    local int i;

    if (newSideEffect == none) {
        return false;
    }
    for (i = 0; i < activeSideEffects.length; i += 1)
    {
        if (activeSideEffects[i].class == newSideEffect.class) {
            return false;
        }
    }
    newSideEffect.NewRef();
    activeSideEffects[activeSideEffects.length] = newSideEffect;
    return true;
}

/**
 *  Removes `SideEffect` of the specified sub-class from the list of active
 *  side effects.
 *
 *  @param  sideEffectClass Class of the side effect to remove.
 *  @return `true` if some side effect was removed as a result of this operation
 *      and `false` otherise (even if there was no side effect of specified
 *      class to begin with).
 */
public final function bool RemoveClass(
    class<SideEffect> sideEffectClass)
{
    local int i;

    if (sideEffectClass == none) {
        return false;
    }
    for (i = 0; i < activeSideEffects.length; i += 1)
    {
        if (activeSideEffects[i].class == sideEffectClass)
        {
            _.memory.Free(activeSideEffects[i]);
            activeSideEffects.Remove(i, 1);
            return true;
        }
    }
    return false;
}

defaultproperties
{
}