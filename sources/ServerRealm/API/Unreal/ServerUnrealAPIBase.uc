/**
 *      Low-level API that provides set of utility methods for working with
 *  unreal script classes.
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
class ServerUnrealAPIBase extends UnrealAPIBase
    abstract;

var protected bool initialized;

var public MutatorAPIBase   mutator;
var public GameRulesAPIBase gameRules;
var public BroadcastAPIBase broadcasts;
var public InventoryAPIBase inventory;

public function Initialize(class<ServerAcediaAdapter> adapterClass)
{
    if (initialized) {
        return;
    }
    initialized = true;
    if (adapterClass == none) {
        return;
    }
    mutator     = MutatorAPIBase(_.memory.Allocate(
        adapterClass.default.serverMutatorAPIClass));
    gameRules   = GameRulesAPIBase(_.memory.Allocate(
        adapterClass.default.serverGameRulesAPIClass));
    broadcasts  = BroadcastAPIBase(_.memory.Allocate(
        adapterClass.default.serverBroadcastAPIClass));
    inventory   = InventoryAPIBase(_.memory.Allocate(
        adapterClass.default.serverInventoryAPIClass));
}

defaultproperties
{
}