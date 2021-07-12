/**
 *  Object for storing settings for the local databases. It is useless to
 *  allocate it's instances.
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
class LocalDBSettings extends AcediaObject
    config(AcediaSystem);

//      Acedia's local database stores it's JSON objects and arrays as
//  named data objects inside a it's package file.
//      Every object in a package must have a unique name, but neither
//  JSON object/array's own name or it's path can be used since they can contain
//  characters unusable for data object's name.
//      That's why Acedia generates a random name for every object that consists
//  of a sequence of latin letters. This value defines how many letters this
//  sequence must contain. With default value of 20 letters it provides database
//  with an ability to store up to
//  26^20 ~= 19,928,148,895,209,409,152,340,197,376
//  different names, while also reducing probability of name collision for
//  newly created objects to zero.
//      There is really no need to modify this value and reducing it might
//  lead to issues with database, so do not do it unless there is a really good
//  reason to it.
var config public const int     randomNameLength;
//      Delay (in seconds) between consecutive writings of the database's
//  content on the disk.
//      Setting this value too low can cause loss of performance, while setting
//  it too high might cause some of the data not being recorded and getting lost
//  on crash.
//      This delay is ignored in special circumstances when database object is
//  forcefully destroyed (and upon level end).
var config public const float   writeToDiskDelay;

defaultproperties
{
    randomNameLength = 20
    writeToDiskDelay = 10.0
}