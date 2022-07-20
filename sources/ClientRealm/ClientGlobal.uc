/**
 *  Class for an object that will provide an access to a Acedia's
 *  client-specific functionality by giving a reference to this object to all
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
class ClientGlobal extends CoreGlobal;

//  `Global` is expected to behave like a singleton and will store it's
//  main instance in this variable's default value.
var protected ClientGlobal myself;

var public ClientUnrealAPI unreal;

var private LoggerAPI.Definition fatBadAdapterClass, errNoInteraction;

public final static function ClientGlobal GetInstance()
{
    if (default.myself == none)
    {
        //  `...Global`s are special and exist outside main Acedia's
        //  object infrastructure, so we allocate it without using API methods.
        default.myself = new class'ClientGlobal';
    }
    return default.myself;
}

protected function Initialize()
{
    local Global                        _;
    local PlayerController              localPlayer;
    local AcediaInteraction             newInteraction;
    local class<ClientAcediaAdapter>    clientAdapterClass;

    if (initialized) {
        return;
    }
    super.Initialize();
    initialized = true;
    clientAdapterClass = class<ClientAcediaAdapter>(adapterClass);
    if (adapterClass != none && clientAdapterClass == none)
    {
        class'Global'.static.GetInstance().logger
            .Auto(fatBadAdapterClass)
            .ArgClass(self.class);
        return;
    }
    if (clientAdapterClass == none) {
        return;
    }
    //  Create APIs
    _ = class'Global'.static.GetInstance();
    unreal  = ClientUnrealAPI(
        _.memory.Allocate(clientAdapterClass.default.clientUnrealAPIClass));
    unreal.Initialize(clientAdapterClass);
    time.Initialize(unreal);
    //  Create `AcediaInteraction`
    localPlayer = unreal.GetLocalPlayer();
    if (localPlayer != none)
    {
        newInteraction = AcediaInteraction(unreal
            .interaction
            .AddInteraction_S("AcediaCore.AcediaInteraction"));
        if (newInteraction != none) {
            newInteraction.InitializeInteraction();
        }
        else {
            _.logger.Auto(errNoInteraction);
        }
    }
}

public final function bool ConnectClientLevelCore()
{
    if (class'ClientLevelCore'.static.GetInstance() == none) {
        return false;
    }
    Initialize();
    return true;
}

defaultproperties
{
    adapterClass = class'ClientAcediaAdapter'
    fatBadAdapterClass  = (l=LOG_Fatal,m="Non-`ClientAcediaAdapter` class was specified as an adapter for `%1` level core class. This should not have happened. AcediaCore cannot properly function.")
    errNoInteraction    = (l=LOG_Error,m="Failed to create interaction \"AcediaCore.AcediaInteraction\". AcediaCore won't support most of its client-side functionality.")
}