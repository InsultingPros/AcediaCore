/**
 *      Core service that is always running alongside Acedia framework, must be
 *  created by a launcher.
 *      Does nothing, simply used for spawning `Actor`s.
 *      Copyright 2020 Anton Tarasenko
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
class CoreService extends Service;

defaultproperties
{
    //  Since `CoreService` is what we use to start spawning `Actor`s,
    //  we have to allow launcher to spawn it with `Spawn()` call
    blockSpawning = false
}