/**
 *  Base class for describing what API Acedia should load into its client- and
 *  server- `...Global`s objects.
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
class AcediaAdapter extends AcediaObject
    abstract;

/**
 *  # `AcediaAdapter`
 *
 *      Acedia provides a set of APIs through `...Global`s objects
 *  `_` (for everything), `_server` (for servers) and `_client` (for clients).
 *  The functionality in common API set `_` is hardcoded, but Acedia allows
 *  users to provide their own implementation of `_server`'s and/or `_client`'s
 *  functionality to extend them, offer compatibility with other mods, etc..
 *  This replacement is done through `AcediaAdapter` classes that serve as
 *  a collection of API classes to be used in `_server` or `_client`.
 *  All one needs to do to use a different set of server/client APIs is to
 *  specify desired `AcediaAdapter` before loading server/client core.
 */

var public const class<SideEffectAPI>   sideEffectAPIClass;
var public const class<TimeAPI>         timeAPIClass;

defaultproperties
{
    sideEffectAPIClass = class'KF1_SideEffectAPI'
}