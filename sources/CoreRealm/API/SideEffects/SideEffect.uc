/**
 *      Object representing a side effect introduced into the game/server.
 *  Side effects in Acedia refer to changes that aren't a part of mod's main
 *  functionality, but rather something necessary to make that functionality
 *  possible that might also affect how other mods work.
 *      This is a simple data container that is meant to describe relevant
 *  changes to the human user.
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
class SideEffect extends AcediaObject
    abstract;

/**
 *  # Side effects
 *
 *      In Acedia "side effect" refers to changes that aren't a part of mod's
 *  main functionality, but rather something necessary to make that
 *  functionality possible that might also affect how other mods work. Their
 *  purpose is to help developers and server admins figure out what changes were
 *  performed by Acedia or mods based on it.
 *      What needs to be considered a side effect is loosely defined and they
 *  are simply a tool to inform others that something they might not have
 *  expected has happened, that can possibly break other (their) mods.
 *      AcediaCore, for example, tried to leave a minimal footprint, avoiding
 *  making any changes to the game classes unless requested, but it still has to
 *  do some changes (adding `GameRules`, replacing damage types for some zeds,
 *  etc.) and `SideEffect`s can be used to document these changes. They can be
 *  used in a similar way for AcediaFixes - a package that is only meant for
 *  fixing bugs, but inevitably has to make a lot of under the hood changes to
 *  achieve that.
 *      On the other hand gameplay mods like Futility can make a lot of changes,
 *  but they can all be just expected part of its direct functionality: we
 *  expect feature that shares dosh of leavers to alter players' dosh values, so
 *  this is not a side effect. Such mods are likely not going to have to specify
 *  any side effects whatsoever.
 *
 *  ## Implementing your own `SideEffect`s
 *
 *      Simply make a non-abstract child class based on `SideEffect`, create its
 *  instance filled with necessary data and register it in `SideEffectAPI` once
 *  side effect is introduced. If you revert introduced side effect, you should
 *  remove registered object through the same API.
 *      Each class of the `SideEffect` is supposed to represent a particular
 *  side effect introduced into the game engine. Whether side effect is active
 *  is decided by whether it is currently registered in `SideEffectAPI`.
 *
 *  NOTE: `SideEffect` should not have any logic and should serve as
 *  an immutable data container.
 */

var protected Text sideEffectName;
var protected Text sideEffectDescription;
var protected Text sideEffectPackage;
var protected Text sideEffectSource;
var protected Text sideEffectStatus;

/**
 *  Returns name (short description) of the caller `SideEffect`. User need to
 *  be able to tell what this `SideEffect` is generally about from the glance at
 *  this name.
 *
 *  Guideline is for this value to not exceed `80` characters, but this is not
 *  enforced.
 *
 *  Must not be `none`.
 *
 *  @return Name (short description) of the caller `SideEffect`.
 *      Guaranteed to not be `none`.
 */
public function Text GetName()
{
    if (sideEffectName != none) {
        return sideEffectName.Copy();
    }
    return none;
}

/**
 *  Returns description of the caller `SideEffect`. This should describe what
 *  was done and why relevant change was necessary.
 *
 *  Must not be `none`.
 *
 *  @return Description of the caller `SideEffect`.
 *      Guaranteed to not be `none`.
 */
public function Text GetDescription()
{
    if (sideEffectDescription != none) {
        return sideEffectDescription.Copy();
    }
    return none;
}

/**
 *  Returns name of the package ("*.u" file) that introduced this change.
 *
 *  Note that if package "A" actually performed the change because another
 *  package "B" requested certain functionality, it is still package "A" that is
 *  responsible for the side effect.
 *
 *  Must not be `none`.
 *
 *  @return Name of the package ("*.u" file) that introduced this change.
 *      Guaranteed to not be `none`.
 */
public function Text GetPackage()
{
    if (sideEffectPackage != none) {
        return sideEffectPackage.Copy();
    }
    return none;
}

/**
 *  What part of package caused this change. For huge packages can be used to
 *  further specify what introduced the change.
 *
 *  Returned value can be `none` (e.g. when it is unnecessary for small
 *  packages).
 *
 *  @return Name (short description) of the part of the package that caused
 *      caller `SideEffect`.
 */
public function Text GetSource()
{
    if (sideEffectSource != none) {
        return sideEffectSource.Copy();
    }
    return none;
}

/**
 *  Status of the caller `SideEffect`. Some side effects can be introduced in
 *  several different ways - this value needs to help distinguish between them.
 *
 *  @return Status of the caller `SideEffect`.
 */
public function Text GetStatus()
{
    if (sideEffectStatus != none) {
        return sideEffectStatus.Copy();
    }
    return none;
}

defaultproperties
{
}