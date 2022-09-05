/**
 *  Object that is meant to describe a squad of zeds for Killing Floor spawning
 *  system. Zeds can be either added individually or through native squad
 *  definitions "3A1B2D1G1H".
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
class ASquad extends AcediaObject;

struct ZedCountPair
{
    var Text    template;
    var int     count;
};

/**
 *  Resets caller squad, removing all zeds inside.
 */
public function Reset();

/**
 *  Changes amount of zeds with given template inside the caller squad.
 *
 *  @param  template    Template for which to change stored count.
 *  @param  delta       By how much to change zed count in squad. Negative
 *      values are allowed.
 */
public function ChangeCount(BaseText template, int delta);

/**
 *  Changes amount of zeds with given template inside the caller squad.
 *
 *  @param  template    Template for which to change stored count.
 *  @param  delta       By how much to change zed count in squad. Negative
 *      values are allowed.
 */
public final function ChangeCount_S(string template, int delta)
{
    local MutableText wrapper;

    wrapper = _.text.FromStringM(template);
    ChangeCount(wrapper, delta);
    wrapper.FreeSelf();
}

/**
 *  Adds zeds into the squad from the text definition format.
 *
 *  For example "3clot5crawer1fp" will add 3 clots, 5 crawlers and 1 fleshpound
 *  into the squad (names are resolved via entity aliases).
 *  Counts inside a definition cannot be negative.
 *
 *  @param  definition  Text definition of the addition to squad.
 */
public function AddFromDefinition(BaseText definition);

/**
 *  Adds zeds into the squad from the text definition format.
 *
 *  For example "3clot5crawer1fp" will add 3 clots, 5 crawlers and 1 fleshpound
 *  into the squad (names are resolved via entity aliases).
 *  Counts inside a definition cannot be negative.
 *
 *  @param  definition  Text definition of the addition to squad.
 */
public final function AddFromDefinition_S(string definition)
{
    local MutableText wrapper;

    wrapper = _.text.FromStringM(definition);
    AddFromDefinition(wrapper);
    wrapper.FreeSelf();
}

/**
 *  Returns list of zeds inside caller squad as an array of zed template and
 *  the count of that zed in a squad.
 *
 *  @return Array of pairs of template and corresponding zed count inside
 *      a squad. Guaranteed that there cannot be two array elements with
 *      the same template.
 */
public function array<ZedCountPair> GetZedList();

/**
 *  Returns amount of zeds of the given template inside the caller squad.
 *
 *  @return Current amount of zeds of the given template inside the caller
 *      squad.
 */
public function int GetZedCount(BaseText template);

/**
 *  Returns current total zed count inside a squad.
 *
 *  @return Current total zed count inside a caller squad.
 */
public function int GetTotalZedCount();

defaultproperties
{
}