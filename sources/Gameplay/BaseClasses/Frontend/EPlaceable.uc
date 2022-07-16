/**
 *      Interface for any entity that can be placed into the game world. To
 *  avoid purity for the sake of itself, in Acedia it will also be bundled with
 *  typical components such as collision and visibility.
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
class EPlaceable extends EInterface
    abstract;

/**
 *  Returns position of the caller `EPlaceable`
 *
 *  @return `Vector` that describes position of the caller `EPlaceable`.
 */
public function Vector GetLocation();

/**
 *  Returns rotation of the caller `EPlaceable`
 *
 *  @return `Rotator` that describes rotation of the caller `EPlaceable`.
 */
public function Rotator GetRotation();

/**
 *  Is caller `EPlaceable` considered static (i.e. does not move or change over
 *  time)?
 *
 *  @return `true` for static `EPlaceable`s and `false` for all others.
 */
public function bool IsStatic();

/**
 *  Is caller `EPlaceable` capable of colliding other `EPlaceable`s?
 *
 *  @return `true` for `EPlaceable`s that are capable of collision and `false`
 *      for any others.
 */
public function bool IsColliding();

/**
 *  Is caller `EPlaceable` blocking colliding `EPlaceable`s?
 *
 *  Blocking `EPlaceable`s cannot occupy the same space on the map.
 *
 *  @return `true` for `EPlaceable`s that are currently blocking and `false`
 *      for any others.
 */
public function bool IsBlocking();

/**
 *  Changes whether caller `EPlaceable` is blocking other `EPlaceable`s.
 *
 *  @param  newBlocking `true` to make caller `EPlaceable` start blocking others
 *      and `false` to prevent it from blocking.
 *  @return `true` for static `EPlaceable`s and `false` for all others.
 */
public function SetBlocking(bool newBlocking);

/**
 *  Checks if given placeable can be seen by players on the map. It is not
 *  required that it is actually seen by someone at the moment of call, but that
 *  it could be visible in principle.
 *
 *  @return `true` if caller `EPlaceable` is visible and `false` otherwise.
 */
public function bool IsVisible();

defaultproperties
{
}