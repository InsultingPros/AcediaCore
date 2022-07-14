/**
 *  Base class for objects that will provide an access to a Acedia's client- and
 *  server-specific functionality by giving a reference to this object to all
 *  Acedia's objects and actors, emulating a global API namespace.
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

var public const class<SideEffectAPIBase>  sideEffectAPIClass;

defaultproperties
{
    SideEffectAPIClass = class'SideEffectAPI'
}