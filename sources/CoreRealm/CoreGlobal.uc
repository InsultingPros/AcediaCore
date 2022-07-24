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
class CoreGlobal extends Object;

var protected bool                  initialized;
var protected class<AcediaAdapter>  adapterClass;

var public SideEffectAPI    sideEffects;
var public TimeAPI          time;

var private LoggerAPI.Definition fatNoAdapterClass;

/**
 *  This method must perform initialization of the caller `...Global` instance.
 *
 *  It must only be executed once (execution should be marked using
 *  `initialized` flag).
 */
protected function Initialize()
{
    local MemoryAPI api;

    if (initialized) {
        return;
    }
    initialized = true;
    if (adapterClass == none)
    {
        class'Global'.static.GetInstance().logger
            .Auto(fatNoAdapterClass)
            .ArgClass(self.class);
        return;
    }
    api = class'Global'.static.GetInstance().memory;
    sideEffects =
        SideEffectAPI(api.Allocate(adapterClass.default.sideEffectAPIClass));
    time = TimeAPI(api.Allocate(adapterClass.default.timeAPIClass));
}

/**
 *  Checks is caller `CoreGlobal` is available to be used.
 *
 *  Server and client `CoreGlobal` instances are always created, so that they
 *  can be added to `AcediaObject`s and `AcediaActor`s at any time, even before
 *  they were initialized (whether they ever will be or not). This method
 *  allows one to check whether they were already initialized and can be used.
 *
 *  @return `true` if caller `CoreGlobal` can be used and `false` otherwise.
 */
public function bool IsAvailable()
{
    return initialized;
}

/**
 *  Changes adapter class for the caller `...Global` instance.
 *
 *  Must not do anything when caller `...Global` instance was already
 *  initialized or when passed adapter class is `none`.
 *
 *  @param  newAdapter  New adapter class to use in the caller `...Global`
 *      instance.
 *  @return `true` if new adapter was set and `false` otherwise.
 */
public function bool SetAdapter(class<AcediaAdapter> newAdapter);

defaultproperties
{
    adapterClass = class'AcediaAdapter'
    fatNoAdapterClass = (l=LOG_Fatal,m="`none` specified as an adapter for `%1` level core class. This should not have happened. AcediaCore cannot properly function.")
}