/**
 *      Special service type that is supposed to be launched alongside
 *  a particular `Feature`.
 *      Such service is spawned right before `OnEnabled()` event.
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
class FeatureService extends Service
    abstract;

var protected Feature ownerFeature;

protected function OnShutdown()
{
    ownerFeature = none;
}

/**
 *  Called right after spawning a service to record it's owner.
 *
 *  Can be overloaded to convert and record `newOwnerFeature` in a more
 *  type-specific variable, so that service does not have to constantly convert
 *  `ownerFeature` to your `Feature` class to access it's methods.
 *
 *  @param  newOwnerFeature `Feature` that this `Service` is launched for.
 */
public function SetOwnerFeature(Feature newOwnerFeature)
{
    if (ownerFeature != none) {
        return;
    }
    ownerFeature = newOwnerFeature;
}

defaultproperties
{
}