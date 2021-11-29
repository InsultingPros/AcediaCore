/**
 *      Frontend skeleton for basic killing floor game mode.
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
class KFFrontend extends BaseFrontend
    abstract;

var private config class<ATradingComponent> tradingClass;
var public ATradingComponent                trading;

protected function Constructor()
{
    if (tradingClass != none) {
        trading = ATradingComponent(_.memory.Allocate(tradingClass));
    }
}

protected function Finalizer()
{
    _.memory.Free(trading);
    trading = none;
}

/**
 *  Returns an instance of information about item template with a given name
 *  `templateName`.
 *
 *  @param  templateName    Name of the template to return info for.
 *  @return Template info for item template named `templateName`.
 *      `none` if item template with given name does not exist or passed
 *      `templateName` is equal to `none`.
 */
public function EItemTemplateInfo GetItemTemplateInfo(Text templateName)
{
    return none;
}

defaultproperties
{
    tradingClass = none
}