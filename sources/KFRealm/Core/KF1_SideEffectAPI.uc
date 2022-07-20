/**
 *      Standard implementation for simple API for managing a list of
 *  `SideEffect` info objects: can add, remove, return all and by package.
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
class KF1_SideEffectAPI extends SideEffectAPI;

var private array<SideEffect> activeSideEffects;

public function array<SideEffect> GetAll()
{
    local int i;

    for (i = 0; i < activeSideEffects.length; i += 1) {
        activeSideEffects[i].NewRef();
    }
    return activeSideEffects;
}

public function SideEffect GetClass(class<SideEffect> sideEffectClass)
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

public function array<SideEffect> GetFromPackage(BaseText packageName)
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

public function bool Add(SideEffect newSideEffect)
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

public function bool RemoveClass(
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