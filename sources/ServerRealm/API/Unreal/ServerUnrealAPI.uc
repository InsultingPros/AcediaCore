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
class ServerUnrealAPI extends UnrealAPI
    abstract;

var protected bool initialized;

var public MutatorAPI   mutator;
var public GameRulesAPI gameRules;
var public BroadcastAPI broadcasts;
var public InventoryAPI inventory;

public function Initialize(class<AcediaAdapter> adapterClass)
{
    local class<ServerAcediaAdapter> asServerAdapter;

    if (initialized)                return;
    asServerAdapter = class<ServerAcediaAdapter>(adapterClass);
    if (asServerAdapter == none)    return;

    super.Initialize(adapterClass);
    initialized = true;
    mutator     = MutatorAPI(_.memory.Allocate(
        asServerAdapter.default.serverMutatorAPIClass));
    gameRules   = GameRulesAPI(_.memory.Allocate(
        asServerAdapter.default.serverGameRulesAPIClass));
    broadcasts  = BroadcastAPI(_.memory.Allocate(
        asServerAdapter.default.serverBroadcastAPIClass));
    inventory   = InventoryAPI  (_.memory.Allocate(
        asServerAdapter.default.serverInventoryAPIClass));
}

defaultproperties
{
}