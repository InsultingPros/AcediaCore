/**
 *      Auxiliary class for `AcediaObject` / `AcediaActor` that maps `string`s
 *  to `Text`s constant, returning same `Text` object for the equal `string`s
 *  (unless it was deallocated).
 *      This object solves the problem of `Acedia` needing a simple way to
 *  create the `Text` without the need to later deallocate it by reusing same
 *  `Text` instance for the same `string`s.
 *      It was implemented to provide a simple-to-use `string` -> `Text`
 *  conversion for a small amount of `string`s and should not be considered
 *  an efficient choice to cache large amounts of them.
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
class TextCache extends AcediaObject;

//      These arrays are supposed to be treated as an "unrolled" singular array
//  of struct with three fields. It is done this way to avoid overhead/issues
//  that come with arrays of `struct`s. This means we must take care to maintain
//  invariant that these arrays have the same length.
//      <type>Strings - `string` value in a cached pair
//      <type>Text - `Text` value in a cached pair
//      <type>Strings - life version of cached `Text` to check if
//          stored instance was reallocated and needs to be recreated.

//  Pairs for plain strings
var private array<string>   plainStrings;
var private array<Text>     plainTexts;
var private array<int>      plainLifeVersions;
//  Pairs for colored strings
var private array<string>   coloredStrings;
var private array<Text>     coloredTexts;
var private array<int>      coloredLifeVersions;
//  Pairs for formatted strings
var private array<string>   formattedStrings;
var private array<Text>     formattedTexts;
var private array<int>      formattedLifeVersions;
//  Pairs for indexed strings:
//  for `Text`s to be obtained by index rather than `string` variable.
var private array<string>   indexedStrings;
var private array<Text>     indexedTexts;
var private array<int>      indexedLifeVersions;

protected function Finalizer()
{
    plainStrings.length             = 0;
    plainTexts.length               = 0;
    plainLifeVersions.length        = 0;
    coloredStrings.length           = 0;
    coloredTexts.length             = 0;
    coloredLifeVersions.length      = 0;
    formattedStrings.length         = 0;
    formattedTexts.length           = 0;
    formattedLifeVersions.length    = 0;
}

/**
 *  Returns (immutable) `Text` object that stores given `string`.
 *
 *  If caller `TextCache` has already been asked to return given `string`,
 *  it will attempt to return the same `Text` object (unless it
 *  was deallocated). Otherwise `TextCache` will create a new `Text`.
 *
 *  @param  string  Plain `string` for returned `Text` to contain.
 *  @return `Text` that contains same data as a given plain `string`.
 *      Guaranteed to not be `none` and allocated.
 */
public final function Text GetPlainText(string string)
{
    local int   i;
    local Text  result;
    //  Check if we have already cached `string`
    for (i = 0; i < plainStrings.length; i += 1)
    {
        //  Skip all other `string`s
        if (plainStrings[i] != string)                              continue;
        //  Replace cached `string` if it was deallocated externally
        if (plainTexts[i].GetLifeVersion() != plainLifeVersions[i]) break;
        return plainTexts[i];
    }
    //      `i` is equal to array index where `string` must be cached.
    //      Normally it's an index of the new element (`plainTexts.length`),
    //  but can also contain already existing index if cached `Text`
    //  was invalidated.
    result = _.text.FromString(string);
    plainStrings[i]         = string;
    plainTexts[i]           = result;
    plainLifeVersions[i]    = result.GetLifeVersion();
    return result;
}

/**
 *  Returns (immutable) `Text` object that stores given `string`.
 *
 *  If caller `TextCache` has already been asked to return given `string`,
 *  it will attempt to return the same `Text` object (unless it
 *  was deallocated). Otherwise `TextCache` will create a new `Text`.
 *
 *  @param  string  Colored `string` for returned `Text` to contain.
 *  @return `Text` that contains same data as a given colored `string`.
 *      Guaranteed to not be `none` and allocated.
 */
public final function Text GetColoredText(string string)
{
    local int   i;
    local Text  result;
    //  Check if we have already cached `string`
    for (i = 0; i < coloredStrings.length; i += 1)
    {
        //  Skip all other `string`s
        if (coloredStrings[i] != string) {
            continue;
        }
        //  Replace cached `string` if it was deallocated externally
        if (coloredTexts[i].GetLifeVersion() != coloredLifeVersions[i]) {
            break;
        }
        return coloredTexts[i];
    }
    //      `i` is equal to array index where `string` must be cached.
    //      Normally it's an index of the new element (`coloredTexts.length`),
    //  but can also contain already existing index if cached `Text`
    //  was invalidated.
    result = _.text.FromColoredString(string);
    coloredStrings[i]       = string;
    coloredTexts[i]         = result;
    coloredLifeVersions[i]  = result.GetLifeVersion();
    return result;
}

/**
 *  Returns (immutable) `Text` object that stores given `string`.
 *
 *  If caller `TextCache` has already been asked to return given `string`,
 *  it will attempt to return the same `Text` object (unless it
 *  was deallocated). Otherwise `TextCache` will create a new `Text`.
 *
 *  @param  string  Formatted `string` for returned `Text` to contain.
 *  @return `Text` that contains same data as a given formatted `string`.
 *      Guaranteed to not be `none` and allocated.
 */
public final function Text GetFormattedText(string string)
{
    local int   i;
    local Text  result;
    //  Check if we have already cached `string`
    for (i = 0; i < formattedStrings.length; i += 1)
    {
        //  Skip all other `string`s
        if (formattedStrings[i] != string) continue;
        //  Replace cached `string` if it was deallocated externally
        if (formattedTexts[i].GetLifeVersion() != formattedLifeVersions[i]) {
            break;
        }
        return formattedTexts[i];
    }
    //      `i` is equal to array index where `string` must be cached.
    //      Normally it's an index of the new element (`formattedTexts.length`),
    //  but can also contain already existing index if cached `Text`
    //  was invalidated.
    result = _.text.FromFormattedString(string);
    formattedStrings[i]         = string;
    formattedTexts[i]           = result;
    formattedLifeVersions[i]    = result.GetLifeVersion();
    return result;
}

public final function TextCache AddIndexedText(string string)
{
    local Text newText;
    indexedStrings[indexedStrings.length] = string;
    newText = _.text.FromFormattedString(string);
    indexedTexts[indexedTexts.length]               = newText;
    indexedLifeVersions[indexedLifeVersions.length] = newText.GetLifeVersion();
    return self;
}

public final function Text GetIndexedText(int index)
{
    local Text newText;
    if (index < 0)                      return none;
    if (index >= indexedTexts.length)   return none;

    if (indexedLifeVersions[index] == indexedTexts[index].GetLifeVersion()) {
        return indexedTexts[index];
    }
    newText = __().text.FromFormattedString(indexedStrings[index]);
    indexedLifeVersions[index] = newText.GetLifeVersion();
    indexedTexts[index] = newText;
    return newText;
}

defaultproperties
{
}