/**
 *      Simple logger class that uses `Log` method to print all of the
 *  log messages. Supports all of the default `acediaStamp`, `timeStamp` and
 *  `levelStamp` settings
 *      Copyright 2021 Anton Tarasenko
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
class ConsoleLogger extends Logger
    perObjectConfig
    config(AcediaSystem)
    dependson(LoggerAPI);

public function Write(BaseText message, LoggerAPI.LogLevel messageLevel)
{
    local MutableText builder;
    if (message != none)
    {
        builder = GetPrefix(messageLevel);
        builder.Append(message);
        Log(builder.ToString());
        builder.FreeSelf();
    }
}

protected static function StaticFinalizer()
{
    default.loadedLoggers = none;
}


defaultproperties
{
}