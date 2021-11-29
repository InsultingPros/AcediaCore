/**
 *      Abstract interface that represents information about some kind of item.
 *      It refers to some sort of preset from which new instances of `EItem`
 *  can be created. "Template" might be implemented in any way, but
 *  the requirement is that "templates" can be referred to by case-insensitive,
 *  human-readable text value. In Killing Floor "templates" correspond to
 *  classes: for example, `KFMod.M79GrenadeLauncher` for M79 or
 *  `KFMod.M14EBRBattleRifle` for EBR. However Acedia adds its own parameters
 *  (such as tags) on top.
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
class EItemTemplateInfo extends AcediaObject
    abstract;

/**
 *  Returns arrays of tags for caller `EItem`.
 *
 *  @return Tags for the caller `EItem`. Returned `Text` values are not allowed
 *      to be empty or `none`. There can be no duplicates (in case-insensitive
 *      sense). But returned array can be empty.
 */
public function array<Text> GetTags()
{
    local array<Text> emptyArray;
    return emptyArray;
}

/**
 *  Returns template caller `EItem` was created from.
 *
 *  @return Template caller `EItem` belongs to, even if it was modified to be
 *      something else entirely. `none` for dead `EItem`s.
 */
public function Text GetTemplateName()
{
    return none;
}

/**
 *  Returns UI-usable name of the caller `EItem`.
 *
 *  @return UI-usable name of the caller `EItem`. Allowed to be empty,
 *      not allowed to be `none`. `none` for dead `EItem`s.
 */
public function Text GetName()
{
    return none;
}

defaultproperties
{
}