/**
 *  Provides convenient access to JSON-related functions.
 *      Copyright 2019 Anton Tarasenko
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
class JSONAPI extends Singleton;

public function JObject newObject()
{
    local JObject newObject;
    newObject = Spawn(class'JObject');
    return newObject;
}

public function JArray newArray()
{
    local JArray newArray;
    newArray = Spawn(class'JArray');
    return newArray;
}

public function JObject ParseObjectWith(Parser jsonParser)
{
    local JObject result;
    result = NewObject();
    if (result == none) {
        return none;
    }
    if (!result.ParseIntoSelfWith(jsonParser))
    {
        result.Destroy();
        return none;
    }
    return result;
}

public function JObject ParseObject(Text source)
{
    local JObject result;
    result = NewObject();
    if (result == none) {
        return none;
    }
    if (!result.ParseIntoSelf(source))
    {
        result.Destroy();
        return none;
    }
    return result;
}

public function JObject ParseObjectString(string source)
{
    local JObject result;
    result = NewObject();
    if (result == none) {
        return none;
    }
    if (!result.ParseIntoSelfString(source))
    {
        result.Destroy();
        return none;
    }
    return result;
}

public function JObject ParseObjectRaw(array<Text.Character> source)
{
    local JObject result;
    result = NewObject();
    if (result == none) {
        return none;
    }
    if (!result.ParseIntoSelfRaw(source))
    {
        result.Destroy();
        return none;
    }
    return result;
}

public function JArray ParseArrayWith(Parser jsonParser)
{
    local JArray result;
    result = NewArray();
    if (result == none) {
        return none;
    }
    if (!result.ParseIntoSelfWith(jsonParser))
    {
        result.Destroy();
        return none;
    }
    return result;
}

public function JArray ParseArray(Text source)
{
    local JArray result;
    result = NewArray();
    if (result == none) {
        return none;
    }
    if (!result.ParseIntoSelf(source))
    {
        result.Destroy();
        return none;
    }
    return result;
}

public function JArray ParseArrayString(string source)
{
    local JArray result;
    result = NewArray();
    if (result == none) {
        return none;
    }
    if (!result.ParseIntoSelfString(source))
    {
        result.Destroy();
        return none;
    }
    return result;
}

public function JArray ParseArrayRaw(array<Text.Character> source)
{
    local JArray result;
    result = NewArray();
    if (result == none) {
        return none;
    }
    if (!result.ParseIntoSelfRaw(source))
    {
        result.Destroy();
        return none;
    }
    return result;
}

defaultproperties
{
}