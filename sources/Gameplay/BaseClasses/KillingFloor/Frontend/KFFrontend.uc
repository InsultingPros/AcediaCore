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

var private config class<AWavesComponent>   wavesClass;
var public AWavesComponent                  waves;

var private config class<AHealthComponent>  healthClass;
var public AHealthComponent                 health;

protected function Constructor()
{
    super.Constructor();
    if (tradingClass != none) {
        trading = ATradingComponent(_.memory.Allocate(tradingClass));
    }
    if (wavesClass != none) {
        waves = AWavesComponent(_.memory.Allocate(wavesClass));
    }
    if (healthClass != none) {
        health = AHealthComponent(_.memory.Allocate(healthClass));
    }
}

protected function Finalizer()
{
    _.memory.Free(trading);
    _.memory.Free(waves);
    _.memory.Free(health);
    trading = none;
    waves   = none;
    health  = none;
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
public function EItemTemplateInfo GetItemTemplateInfo(BaseText templateName)
{
    return none;
}

defaultproperties
{
    tradingClass    = none
    wavesClass      = none
    healthClass     = none
}