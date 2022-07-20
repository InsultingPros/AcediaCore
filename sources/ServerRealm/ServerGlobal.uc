/**
 *  Class for an object that will provide an access to a Acedia's
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
class ServerGlobal extends CoreGlobal;

//  `Global` is expected to behave like a singleton and will store it's
//  main instance in this variable's default value.
var protected ServerGlobal myself;

var public KFFrontend       kf;
var public ServerUnrealAPI  unreal;

var private LoggerAPI.Definition fatBadAdapterClass;

public final static function ServerGlobal GetInstance()
{
    if (default.myself == none)
    {
        //  `...Global`s are special and exist outside main Acedia's
        //  object infrastructure, so we allocate it without using API methods.
        default.myself = new class'ServerGlobal';
    }
    return default.myself;
}

protected function Initialize()
{
    local Global                        _;
    local class<ServerAcediaAdapter>    serverAdapterClass;

    if (initialized) {
        return;
    }
    super.Initialize();
    initialized = true;
    serverAdapterClass = class<ServerAcediaAdapter>(adapterClass);
    if (adapterClass != none && serverAdapterClass == none)
    {
        class'Global'.static.GetInstance().logger
            .Auto(fatBadAdapterClass)
            .ArgClass(self.class);
        return;
    }
    if (serverAdapterClass == none) {
        return;
    }
    _ = class'Global'.static.GetInstance();
    unreal = ServerUnrealAPI(
        _.memory.Allocate(serverAdapterClass.default.serverUnrealAPIClass));
    unreal.Initialize(serverAdapterClass);
    time.Initialize(unreal);
    kf = KFFrontend(_.memory.Allocate(class'KF1_Frontend'));
}

public final function bool ConnectServerLevelCore()
{
    local Global _;

    if (class'ServerLevelCore'.static.GetInstance() == none) {
        return false;
    }
    Initialize();
    if (class'SideEffects'.default.allowHookingIntoMutate)
    {
        _ = class'Global'.static.GetInstance();
        class'InfoQueryHandler'.static.StaticConstructor();
        unreal.mutator.OnMutate(
            ServiceAnchor(_.memory.Allocate(class'ServiceAnchor')))
                .connect = EnableCommandsFeature;
    }
    return true;
}

private final function EnableCommandsFeature(
    string              command,
    PlayerController    sendingPlayer)
{
    if (command ~= "acediacommands") {
        class'Commands_Feature'.static.EmergencyEnable();
    }
}

defaultproperties
{
    adapterClass = class'ServerAcediaAdapter'
    fatBadAdapterClass = (l=LOG_Fatal,m="non-`ServerAcediaAdapter` class was specified as an adapter for `%1` level core class. This should not have happened. AcediaCore cannot properly function.")
}