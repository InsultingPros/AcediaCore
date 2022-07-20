/**
 *      Object representing a side effect introduced into the game/server.
 *  Side effects in Acedia refer to changes that aren't a part of mod's main
 *  functionality, but rather something necessary to make that functionality
 *  possible that might also affect how other mods work.
 *      This is a simple data container that is meant to describe relevant
 *  changes to the human user.
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
class BroadcastSideEffect extends SideEffect
    dependson(BroadcastAPI);

public final function Initialize(BroadcastAPI.InjectionLevel usedInjectionLevel)
{
    sideEffectName =
        _.text.FromString("AcediaCore's `BroadcastHandler` injected");
    sideEffectDescription =
        _.text.FromString("Handling text and localized messages between server"
        @ "and clients requires AcediaCore to add its own `BroadcastHandler`"
        @ "into their linked list."
        @ "This is normal, since `BroadcastHandler` class was designed to allow"
        @ "mods to do that, however, for full functionality Acedia requires to"
        @ "inject it as the very first element (`BHIJ_Root` level injection),"
        @ "since some of the events become otherwise inaccessible."
        @ "This can result in incompatibility with other mods that are trying"
        @ "to do the same."
        @ "For that reason AcediaCore can also inject its `BroadcastHandler` as"
        @ "`BHIJ_Registered`.");
    sideEffectPackage = _.text.FromString("AcediaCore");
    sideEffectSource = _.text.FromString("UnrealAPI");
    if (usedInjectionLevel == BHIJ_Root)
    {
        sideEffectStatus =
            _.text.FromFormattedString("{$TextPositive BHIJ_Root}");
    }
    else if (usedInjectionLevel == BHIJ_Registered)
    {
        sideEffectStatus =
            _.text.FromFormattedString("{$TextNetutral BHIJ_Registered}");
    }
    else
    {
        sideEffectStatus =
            _.text.FromFormattedString("{$TextNegative BHIJ_None (???)}");
    }
}

defaultproperties
{
}