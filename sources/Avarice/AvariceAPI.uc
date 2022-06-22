/**
 *  API for Avarice functionality of Acedia.
 *      Copyright 2020 - 2021 Anton Tarasenko
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
class AvariceAPI extends AcediaObject;

/**
 *  Method that returns all the `AvariceLink` created by `Avarice` feature.
 *
 *  @return Array of links created by this feature.
 *      Guaranteed to not contain `none` values.
 *      Empty if `Avarice` feature is currently disabled.
 */
public final function array<AvariceLink> GetAllLinks()
{
    local Avarice_Feature       avariceFeature;
    local array<AvariceLink>    emptyResult;
    avariceFeature =
        Avarice_Feature(class'Avarice_Feature'.static.GetEnabledInstance());
    if (avariceFeature != none) {
        return avariceFeature.GetAllLinks();
    }
    return emptyResult;
}

/**
 *  Finds and returns `AvariceLink` by its name, specified in "AcediaAvarice"
 *  config, if it exists.
 *
 *  @param  linkName    Name of the `AvariceLink` to find.
 *  @return `AvariceLink` corresponding to name `linkName`.
 *      If `linkName == none` or `AvariceLink` with such name does not exist -
 *      returns `none`.
 */
public final function AvariceLink GetLink(BaseText linkName)
{
    local int                   i;
    local Text                  nextName;
    local array<AvariceLink>    allLinks;
    if (linkName == none) {
        return none;
    }
    allLinks = GetAllLinks();
    for (i = 0; i < allLinks.length; i += 1)
    {
        if (allLinks[i] == none) {
            continue;
        }
        nextName = allLinks[i].GetName();
        if (linkName.Compare(nextName, SCASE_INSENSITIVE))
        {
            _.memory.Free(nextName);
            return allLinks[i];
        }
        _.memory.Free(nextName);
    }
    return none;
}

defaultproperties
{
}