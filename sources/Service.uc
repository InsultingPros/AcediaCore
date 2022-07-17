/**
 *  Parent class for all services used in Acedia.
 *  Currently simply makes itself server-only.
 *      Copyright 2020 - 2022 Anton Tarasenko
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
class Service extends Singleton
    abstract;

//  `Service`s can use this as a receiver for signal functions
var protected ServiceAnchor _self;

//  Log messages
var private LoggerAPI.Definition errNoService;

//  Enables feature of given class.
public simulated static final function Service Require()
{
    local Service newInstance;

    if (IsRunning()) {
        return Service(GetInstance());
    }
    default.blockSpawning = false;
    newInstance = Service(__().memory.Allocate(default.class));
    default.blockSpawning = true;
    if (newInstance == none) {
        __().logger.Auto(default.errNoService).ArgClass(default.class);
    }
    return newInstance;
}

//  Whether service is currently running is determined by
public simulated static final function bool IsRunning()
{
    return (GetInstance() != none);
}

protected simulated function OnLaunch(){}
protected simulated function OnShutdown(){}

protected simulated function OnCreated()
{
    default.blockSpawning = true;
    _self = ServiceAnchor(_.memory.Allocate(class'ServiceAnchor'));
    OnLaunch();
}

protected simulated function OnDestroyed()
{
    OnShutdown();
    _.memory.Free(_self);
    _self = none;
}

defaultproperties
{
    DrawType        = DT_None
    //  Prevent spawning this feature by any other means than 'Launch()'.
    blockSpawning   = true
    //  Features are server-only actors
    remoteRole      = ROLE_None
    errNoService    = (l=LOG_Fatal,m="Cannot start required service %1")
}