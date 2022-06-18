/**
 *  Subset of functionality for dealing with everything related to templates.
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
class ATemplatesComponent extends AcediaObject
    abstract;

/**
 *  Returns `true` if list of items named `listName` exists and
 *  `false` otherwise.
 *
 *  This method is necessary, since `GetItemList()` does not allow to
 *  distinguish between empty and non-existing item list.
 *
 *  @param  listName    Name of the list to check for whether it exists.
 *  @return `true` if list named `listName` exists and `false` otherwise.
 *      Always returns `false` if `listName` equals `none`.
 */
public function bool ItemListExists(BaseText listName)
{
    return false;
}

/**
 *  Returns array with templates of items belonging to the `listName` list.
 *
 *  All implementations must support:
 *      1. "all weapons" / "weapons" (both names
 *          should refer to the same list) list with templates of all weapons in
 *          the game;
 *      2. "trading weapons" list with names of all weapons available for trade
 *          in one way or another (even if they are not all tradable in
 *          all shops / for all players).
 *
 *  @param  listName    Name of the list to return templates for.
 *      In case a name of inexistent list is specified - method does nothing.
 *  @return Array of templates in the list, specified with `listName`.
 *      All of the `Text`s in the returned array are guaranteed to be `none`.
 *      When incorrect `listName` is specified - empty array is returned
 *      (which can also happen if specified list is empty).
 */
public function array<Text> GetItemList(BaseText listName)
{
    local array<Text> emptyArray;
    return emptyArray;
}

/**
 *  Returns array that is listing all available lists of item templates.
 *
 *  All implementations must include "all weapons" and "trading weapons" lists.
 *
 *  @return Array with names of all available lists.
 *      All of the `Text`s in the returned array are guaranteed to be `none`.
 *      If a certain list has several names (like "all weapons" / "weapons"),
 *      only one of these names (guaranteed to always be the same between calls)
 *      will be included.
 */
public function array<Text> GetAvailableLists()
{
    local array<Text> emptyArray;
    return emptyArray;
}

defaultproperties
{
}