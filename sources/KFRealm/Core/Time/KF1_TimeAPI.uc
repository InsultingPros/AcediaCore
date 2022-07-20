/**
 *  Acedia's default `TimeAPI` API implementation
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
class KF1_TimeAPI extends TimeAPI;

public function Timer NewTimer(
    optional float  interval,
    optional bool   autoReset)
{
    return KF1_Timer(_.memory.Allocate(class'KF1_Timer'))
        .Initialize(api)
        .SetInterval(interval)
        .SetAutoReset(autoReset);
}

public function Timer StartTimer(float interval, optional bool autoReset)
{
    return KF1_Timer(_.memory.Allocate(class'KF1_Timer'))
        .Initialize(api)
        .SetInterval(interval)
        .SetAutoReset(autoReset)
        .Start();
}

public function Timer NewRealTimer(
    optional float  interval,
    optional bool   autoReset)
{
    return KF1_Timer(_.memory.Allocate(class'KF1_RealTimer'))
        .Initialize(api)
        .SetInterval(interval).SetAutoReset(autoReset);
}

public function Timer StartRealTimer(
    float           interval,
    optional bool   autoReset)
{
    return KF1_Timer(_.memory.Allocate(class'KF1_RealTimer'))
        .Initialize(api)
        .SetInterval(interval)
        .SetAutoReset(autoReset)
        .Start();
}

defaultproperties
{
}