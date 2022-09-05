/**
 *  Frontend implementation for classic `KFGameType` that changes as little as
 *  possible and only on request from another mod, otherwise not altering
 *  gameplay at all.
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
class KF1_Frontend extends KFFrontend;

public function EItemTemplateInfo GetItemTemplateInfo(BaseText templateName)
{
    local class<Inventory> inventoryClass;
    inventoryClass = class<Inventory>(_.memory.LoadClass(templateName));
    if (inventoryClass == none) {
        return none;
    }
    return class'EKFItemTemplateInfo'.static.Wrap(inventoryClass);
}

defaultproperties
{
    templatesClass  = class'KF1_TemplatesComponent'
    worldClass      = class'KF1_WorldComponent'
    tradingClass    = class'KF1_TradingComponent'
    wavesClass      = class'KF1_WavesComponent'
    healthClass     = class'KF1_HealthComponent'
}