/**
 *  Acedia's default implementation for `Timer` class.
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
class KF1_Timer extends Timer;

//  Is timer currently tracking time until the next event?
var protected bool  isTimerEnabled;
//  Should timer automatically reset after the next event to
//  also generate recurring signals?
var protected bool  isTimerAutoReset;
//  Currently elapsed time since this timer has started waiting for the
//  next event
var protected float totalElapsedTime;
//  Time interval between timer's start and generating the signal
var protected float eventInterval;
//  This flag tells `Timer` to stop trying to emit messages that accumulated
//  between two `Tick()` updates. Used in case `Timer` was disables or
//  stopped during one of them.
var protected bool  clearEventQueue;

//  `UnrealAPI` to use, has to be set to access `OnTick()` signal.
var protected UnrealAPI api;

var protected Timer_OnElapsed_Signal onElapsedSignal;

protected function Constructor()
{
    onElapsedSignal = Timer_OnElapsed_Signal(
        _.memory.Allocate(class'Timer_OnElapsed_Signal'));
}

protected function Finalizer()
{
    _.memory.Free(onElapsedSignal);
    StopMe();   //  Disconnects from listening to `api.OnTick()`
    api = none;
}

/**
 *  Initializes caller `Timer` with given `UnrealAPI` instance that will be used
 *  to track `OnTick()` signal.
 *
 *  This is necessary, because we don't know where `KF1_Timer` will be used:
 *  on server or on client.
 */
public function Timer Initialize(UnrealAPI newAPI)
{
    if (api != none) {
        return self;
    }
    api = newAPI;
    return self;
}

/* SIGNAL */
public function Timer_OnElapsed_Slot OnElapsed(AcediaObject receiver)
{
    return Timer_OnElapsed_Slot(onElapsedSignal.NewSlot(receiver));
}

protected function float HandleTimeDilation(
    float timeDelta,
    float dilationCoefficient)
{
    return timeDelta;
}


public function float GetInterval()
{
    return eventInterval;
}

public function Timer SetInterval(float newInterval)
{
    eventInterval = newInterval;
    if (eventInterval <= 0)
    {
        StopMe();
        return self;
    }
    if (isTimerEnabled) {
        Start();
    }
    return self;
}

public function bool IsEnabled()
{
    return isTimerEnabled;
}

public function bool IsAutoReset(float newInterval)
{
    return isTimerAutoReset;
}

public function Timer SetAutoReset(bool doAutoReset)
{
    isTimerAutoReset = doAutoReset;
    return self;
}

public function Timer Start()
{
    if (eventInterval <= 0) {
        return self;
    }
    if (!isTimerEnabled) {
        api.OnTick(self).connect = Tick;
    }
    isTimerEnabled = true;
    totalElapsedTime = 0.0;
    return self;
}

public function Timer StopMe()
{
    api.OnTick(self).Disconnect();
    isTimerEnabled = false;
    clearEventQueue = true;
    return self;
}

public function float GetElapsedTime()
{
    return totalElapsedTime;
}

private function Tick(float delta, float dilationCoefficient)
{
    local int lifeVersion;

    if (onElapsedSignal == none || eventInterval <= 0.0)
    {
        StopMe();
        return;
    }
    totalElapsedTime += HandleTimeDilation(delta, dilationCoefficient);
    clearEventQueue = false;
    while (totalElapsedTime > eventInterval && !clearEventQueue)
    {
        //  It is important to modify _before_ the signal call in case `Timer`
        //  is reset there and already has a zeroed `totalElapsedTime`
        totalElapsedTime -= eventInterval;
        //  Stop `Timer` before emitting a signal, to allow user to potentially
        //  restart it
        if (!isTimerAutoReset) {
            StopMe();
        }
        //      During signal emission caller `Timer` can get reallocated and
        //  used to perform a completely different role.
        //      In such a case we need to bail from this method as soom as
        //  possible.
        lifeVersion = GetLifeVersion();
        onElapsedSignal.Emit(self);
        if (!isTimerEnabled || lifeVersion != GetLifeVersion()) {
            return;
        }
    }
}

defaultproperties
{
}