/**
 *  Acedia's default `ServerTimeAPIBase` API implementation
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
class ServerTimeAPI extends ServerTimeAPIBase;

public function Timer NewTimer(
    optional float  interval,
    optional bool   autoReset)
{
    return Timer(_.memory.Allocate(class'Timer'))
        .SetInterval(interval)
        .SetAutoReset(autoReset);
}

public function Timer StartTimer(float interval, optional bool autoReset)
{
    return Timer(_.memory.Allocate(class'Timer'))
        .SetInterval(interval)
        .SetAutoReset(autoReset)
        .Start();
}

public function RealTimer NewRealTimer(
    optional float  interval,
    optional bool   autoReset)
{
    local RealTimer newTimer;
    newTimer = RealTimer(_.memory.Allocate(class'RealTimer'));
    newTimer.SetInterval(interval).SetAutoReset(autoReset);
    return newTimer;
}

public function RealTimer StartRealTimer(
    float           interval,
    optional bool   autoReset)
{
    local RealTimer newTimer;
    newTimer = RealTimer(_.memory.Allocate(class'RealTimer'));
    newTimer.SetInterval(interval)
        .SetAutoReset(autoReset)
        .Start();
    return newTimer;
}

defaultproperties
{
}