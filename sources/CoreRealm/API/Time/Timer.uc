/**
 *      Timer class that generates a signal after a set interval, with an option
 *  to generate recurring signals.
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
class Timer extends AcediaObject
    abstract;

/**
 *      Because the `Timer` depends on the `Tick()` event, it has the same
 *  resolution as a server's tick rate (frame rate for clients). This means that
 *  the `OnElapsed()` signal will be emitted at an interval defined by the
 *  `Tick()`. If the set interval between two signals is less than that, then
 *  `Timer` might emit several signals at the same point of time.
 *      Supposing server's tick rate is 30, but `Timer` is set to emit a signal
 *  60 time per second, then on average it will emit two signals each tick at
 *  the same exact time.
 */

/**
 *  Signal that will be emitted every time timer's interval is elapsed.
 *
 *  [Signature]
 *  void <slot>(Timer source)
 *
 *  @param  source  `Timer` that emitted the signal.
 */
/* SIGNAL */
public function Timer_OnElapsed_Slot OnElapsed(AcediaObject receiver);

/**
 *  This method is called every tick while the caller `Timer` is running and
 *  can be overloaded to modify how passed time is affected by the
 *  time dilation.
 *
 *  For example, to make caller `Timer` count real time you need to passed time
 *  by the `dilationCoefficient`:
 *      `return timeDelta / dilationCoefficient;`.
 *
 *  @param  timeDelta           In-game time that has passed since the last
 *      `Tick()` event. To obtain real time should be divided by
 *      `dilationCoefficient`.
 *  @param  dilationCoefficient Coefficient of time dilation for the passed
 *      `Tick()`. Regular speed is `1.0` (corrected from native value `1.1`
 *      for Unreal Engine 2).
 */
protected function float HandleTimeDilation(
    float timeDelta,
    float dilationCoefficient);

/**
 *  Returns current interval between `OnElapsed()` signals for the
 *  caller `Timer`. In seconds.
 *
 *  @return How many seconds separate two `OnElapsed()` signals
 *      (or starting a timer and next `OnElapsed()` event).
 */
public function float GetInterval();

/**
 *  Sets current interval between `OnElapsed()` signals for the
 *  caller `Timer`. In seconds.
 *
 *  Setting this value while the caller `Timer` is running resets it (same as
 *  calling `StopMe().Start()`).
 *
 *  @param  newInterval How many seconds should separate two `OnElapsed()` 
 *      signals (or starting a timer and next `OnElapsed()` event)?
 *      Setting a value `<= 0` disables the timer.
 *  @return Caller `Timer` to allow for method chaining.
 */
public function Timer SetInterval(float newInterval);

/**
 *  Checks whether the timer is currently enabled (emitting signals with
 *  set interval).
 *
 *  @return `true` if caller `Timer` is enabled and `false` otherwise.
 */
public function bool IsEnabled();

/**
 *  Checks whether this `Timer` would automatically reset after the emitted
 *  `OnElapsed()` signal, allowing for recurring signals.
 *
 *  @return `true` if `Timer` will emit `OnElapse()` signal each time
 *      the interval elapses and `false` otherwise.
 */
public function bool IsAutoReset(float newInterval);

/**
 *  Sets whether this `Timer` would automatically reset after the emitted
 *  `OnElapsed()` signal, allowing for recurring signals.
 *
 *  @param  doAutoReset `true` if `Timer` will emit `OnElapse()` signal
 *      each time the interval elapses and `false` otherwise.
 *  @return Caller `Timer` to allow for method chaining.
 */
public function Timer SetAutoReset(bool doAutoReset);

/**
 *  Starts emitting `OneElapsed()` signal.
 *
 *  Does nothing if current timer interval (set by `SetInterval()`) is set
 *  to a value that's `<= 0`.
 *
 *  If caller `Timer` is already running, resets it (same as calling
 *  `StopMe().Start()`).
 *
 *  @return Caller `Timer` to allow for method chaining.
 */
public function Timer Start();

/**
 *  Stops emitting `OneElapsed()` signal.
 *
 *  @return Caller `Timer` to allow for method chaining.
 */
public function Timer StopMe();

/**
 *  Returns currently elapsed time since caller `Timer` has started waiting for
 *  the next event.
 *
 *  @return Elapsed time since caller `Timer` has started.
 */
public function float GetElapsedTime();

private function Tick(float delta, float dilationCoefficient);

defaultproperties
{
}