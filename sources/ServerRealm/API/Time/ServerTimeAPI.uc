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
class ServerTimeAPI extends AcediaObject
    abstract;

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
 *  Creates new `RealTimer`. Does not start it.
 *
 *  @param  interval    Returned `RealTimer` will be configured to emit
 *      `OnElapsed()` signals every `interval` seconds.
 *  @param  autoReset   `true` will configure caller `RealTimer` to repeatedly
 *      emit `OnElapsed()` every `interval` seconds, `false` (default value)
 *      will make returned `RealTimer` emit that signal only once.
 *  @return `RealTimer`, configured to emit `OnElapsed()` every `interval`
 *      seconds. Not started. Guaranteed to be not `none`.
 */
public function RealTimer NewRealTimer(
    optional float  interval,
    optional bool   autoReset);

/**
 *  Creates and starts new `RealTimer`.
 *
 *  @param  interval    Returned `RealTimer` will be configured to emit
 *      `OnElapsed()` signals every `interval` seconds.
 *  @param  autoReset   Setting this to `true` will configure caller `RealTimer`
 *      to repeatedly emit `OnElapsed()` signal every `interval` seconds,
 *      `false` (default value) will make returned `RealTimer` emit that signal
 *      only once.
 *  @return `RealTimer`, configured to emit `OnElapsed()` every `interval`
 *      seconds. Guaranteed to be not `none`.
 */
public function RealTimer StartRealTimer(
    float           interval,
    optional bool   autoReset);

defaultproperties
{
}