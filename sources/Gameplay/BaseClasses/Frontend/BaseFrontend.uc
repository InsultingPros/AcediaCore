/**
 *      Base class for all frontends. Does not define anything meaningful, which
 *  also means it does not put any limitations on it's implementation.
 *      Copyright 2021-2022 Anton Tarasenko
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
 class BaseFrontend extends AcediaObject
    abstract;

var private config class<ATemplatesComponent>   templatesClass;
var public ATemplatesComponent                  templates;

var private config class<AWorldComponent>       worldClass;
var public AWorldComponent                      world;

protected function Constructor()
{
    if (templatesClass != none) {
        templates = ATemplatesComponent(_.memory.Allocate(templatesClass));
    }
    if (worldClass != none) {
        world = AWorldComponent(_.memory.Allocate(worldClass));
    }
}

protected function Finalizer()
{
    _.memory.Free(templates);
    templates = none;
}

defaultproperties
{
    templatesClass  = none
    worldClass      = none
}