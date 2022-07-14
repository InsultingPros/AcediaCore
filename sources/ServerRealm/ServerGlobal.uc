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

var public KFFrontend kf;

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
    local Global _;

    if (initialized) {
        return;
    }
    super.Initialize();
    _ = class'Global'.static.GetInstance();
    kf = KFFrontend(_.memory.Allocate(class'KF1_Frontend'));
    initialized = true;
}

public final function bool ConnectServerLevelCore()
{
    local Global _;

    if (class'ServerLevelCore'.static.GetInstance() == none) {
        return false;
    }
    Initialize();
    _ = class'Global'.static.GetInstance();
    if (class'SideEffects'.default.allowHookingIntoMutate)
    {
        class'InfoQueryHandler'.static.StaticConstructor();
        _.unreal.mutator.OnMutate(
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
}