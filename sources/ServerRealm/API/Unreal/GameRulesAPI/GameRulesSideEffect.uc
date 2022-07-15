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
class GameRulesSideEffect extends SideEffect;

public final function Initialize()
{
    sideEffectName =
        _.text.FromString("AcediaCore's `AcediaGameRules` added");
    sideEffectDescription =
        _.text.FromString("`GameRule`s is one of the main ways to get notified"
        @ "about various gameplay-related events in Unreal Engine."
        @ "Of course AcediaCore would require handling some of those events,"
        @ "depending on how it's used.");
    sideEffectPackage = _.text.FromString("AcediaCore");
    sideEffectSource = _.text.FromString("UnrealAPI");
    sideEffectStatus = _.text.FromFormattedString("{$TextPositive active}");
}

defaultproperties
{
}