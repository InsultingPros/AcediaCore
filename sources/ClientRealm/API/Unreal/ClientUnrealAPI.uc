/**
 *      Low-level API that provides set of utility methods for working with
 *  unreal script classes on the clients.
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
class ClientUnrealAPI extends UnrealAPI
    abstract;

var protected bool initialized;

var public InteractionAPI interaction;

public function Initialize(class<AcediaAdapter> adapterClass)
{
    local class<ClientAcediaAdapter> asClientAdapter;

    if (initialized)                return;
    asClientAdapter = class<ClientAcediaAdapter>(adapterClass);
    if (asClientAdapter == none)    return;

    super.Initialize(adapterClass);
    initialized = true;
    interaction = InteractionAPI(_.memory.Allocate(
        asClientAdapter.default.clientInteractionAPIClass));
}

/**
 *  Returns current local player's `Controller`. Useful because `level`
 *  is not accessible inside objects.
 *
 *  @return `PlayerController` instance for the local player. `none` iff run on
 *      dedicated servers.
 */
public function PlayerController GetLocalPlayer();

defaultproperties
{
}