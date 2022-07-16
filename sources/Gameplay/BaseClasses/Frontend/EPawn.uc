/**
 *      Interface for a *Pawn* - base class for any entity that can be
 *  controlled by player or AI. To avoid purity for the sake of itself, in
 *  Acedia it will also be bundled with typical components like health.
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
class EPawn extends EPlaceable
    abstract;

/**
 *  If caller pawn is controlled by a player, this method returns that player.
 *
 *  @return Player that controls caller pawn. `none` iff caller pawn is not
 *      controlled by a player.
 */
public function EPlayer GetPlayer();

/**
 *  Returns current amount of health caller `EPawn`'s referred entity has,
 *  assuming that entity has a health component.
 *
 *  @return Current amount of health caller `EPawn`'s entity has.
 *      If entity that caller `EPawn` refers to doesn't have health component -
 *      returns `0`.
 */
public function int GetHealth()
{
    return 0;
}

/**
 *  Returns current maximum amount of health caller `EPawn`'s referred entity can
 *  have, assuming that entity has a health component.
 *
 *  @return Current maximum amount of health caller `EPawn`'s entity can have.
 *      If entity that caller `EPawn` refers to doesn't have health component -
 *      returns `0`.
 */
public function int GetMaxHealth();

/**
 *  Produces a suicide event for caller `EPawn`, making it drain its health and
 *  change its state into dead, whatever it means for the caller `EPawn`.
 */
public function Suicide();

defaultproperties
{
}