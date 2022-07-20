/**
 *  API that provides time-related methods.
 *      Copyright 2021-2022 Anton Tarasenko
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
class TimeAPI extends AcediaObject
    abstract;

//      API to use to initialize `Timer`s, should be chosen depending on where
//  `Timer`s are created.
var protected UnrealAPI api;

/**
 *  Initializes caller `TimeAPI` with given `UnrealAPI` instance that will
 *  be used to create all `Timer`s.
 *
 *  This is necessary, because we don't know where `TimeAPI` will be used:
 *  on server or on client.
 */
public function Initialize(UnrealAPI newAPI)
{
    if (api != none) {
        return;
    }
    api = newAPI;
}

/**
 *  Creates new `Timer`. Does not start it.
 *
 *  @param  interval    Returned `Timer` will be configured to emit
 *      `OnElapsed()` signals every `interval` seconds.
 *  @param  autoReset   `true` will configure caller `Timer` to repeatedly emit
 *      `OnElapsed()` every `interval` seconds, `false` (default value) will
 *      make returned `Timer` emit that signal only once.
 *  @return `Timer`, configured to emit `OnElapsed()` every `interval` seconds.
 *      Not started. Guaranteed to be not `none`.
 */
public function Timer NewTimer(
    optional float  interval,
    optional bool   autoReset);

/**
 *  Creates and starts new `Timer`.
 *
 *  @param  interval    Returned `Timer` will be configured to emit
 *      `OnElapsed()` signals every `interval` seconds.
 *  @param  autoReset   Setting this to `true` will configure caller `Timer` to
 *      repeatedly emit `OnElapsed()` signal every `interval` seconds, `false`
 *      (default value) will make returned `Timer` emit that signal only once.
 *  @return `Timer`, configured to emit `OnElapsed()` every `interval` seconds.
 *      Guaranteed to be not `none`.
 */
public function Timer StartTimer(float interval, optional bool autoReset);

/**
 *  Creates new `Timer` that measures real time, not in-game one.
 *  Does not start it.
 *
 *  @param  interval    Returned `Timer` will be configured to emit
 *      `OnElapsed()` signals every `interval` seconds.
 *  @param  autoReset   `true` will configure caller `Timer` to repeatedly
 *      emit `OnElapsed()` every `interval` seconds, `false` (default value)
 *      will make returned `Timer` emit that signal only once.
 *  @return `Timer`, configured to emit `OnElapsed()` every `interval`
 *      seconds. Not started. Guaranteed to be not `none`.
 */
public function Timer NewRealTimer(
    optional float  interval,
    optional bool   autoReset);

/**
 *  Creates and starts new `Timer` that measures real time, not in-game one.
 *
 *  @param  interval    Returned `Timer` will be configured to emit
 *      `OnElapsed()` signals every `interval` seconds.
 *  @param  autoReset   Setting this to `true` will configure caller `Timer`
 *      to repeatedly emit `OnElapsed()` signal every `interval` seconds,
 *      `false` (default value) will make returned `Timer` emit that signal
 *      only once.
 *  @return `Timer`, configured to emit `OnElapsed()` every `interval`
 *      seconds. Guaranteed to be not `none`.
 */
public function Timer StartRealTimer(
    float           interval,
    optional bool   autoReset);

defaultproperties
{
}