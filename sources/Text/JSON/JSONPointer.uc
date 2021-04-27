/**
 *      Class for representing a JSON pointer (see
 *  https://tools.ietf.org/html/rfc6901).
 *      Allows quick and simple access to parts/segments of it's path.
 *      Objects of this class should only be used after initialization.
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
class JSONPointer extends AcediaObject;

var private bool                initialized;
//  Segments of the path this JSON pointer was initialized with
var private array<MutableText>  keys;

var protected const int TSLASH, TJSON_ESCAPE, TJSON_ESCAPED_SLASH;
var protected const int TJSON_ESCAPED_ESCAPE;

protected function Finalizer()
{
    _.memory.FreeMany(keys);
    keys.length = 0;
    initialized = false;
}

/**
 *  Initializes caller `JSONPointer` with a given path.
 *
 *  @param  pointerAsText   Treated as a JSON pointer if it starts with "/"
 *      character or is an empty `Text`, otherwise treated as an item's
 *      name / identificator inside the caller collection (without resolving
 *      escaped sequences "~0" and "~1").
 *  @return `true` if caller `JSONPointer` was correctly initialized with this
 *      call. `false` otherwise: can happen if `none` was passed as a parameter
 *      or caller `JSONPointer` was already initialized.
 */
public final function bool Initialize(Text pointerAsText)
{
    local int   i;
    local bool  hasEscapedSequences;
    if (initialized)            return false;
    if (pointerAsText == none)  return false;

    initialized = true;
    if (!pointerAsText.StartsWith(T(TSLASH)) && !pointerAsText.IsEmpty()) {
        keys[0] = pointerAsText.MutableCopy();
    }
    else
    {
        hasEscapedSequences = (pointerAsText.IndexOf(T(TJSON_ESCAPE)) >= 0);
        keys = pointerAsText.SplitByCharacter(T(TSLASH).GetCharacter(0));
        //  First elements of the array will be empty, so throw it away
        _.memory.Free(keys[0]);
        keys.Remove(0, 1);
    }
    if (!hasEscapedSequences) {
        return true;
    }
    //  Replace escaped sequences "~0" and "~1".
    //  Order is specific, necessity of which is explained in
    //  JSON Pointer's documentation:
    //  https://tools.ietf.org/html/rfc6901
    for (i = 0; i < keys.length; i += 1)
    {
        keys[i].Replace(T(TJSON_ESCAPED_SLASH), T(TSLASH));
        keys[i].Replace(T(TJSON_ESCAPED_ESCAPE), T(TJSON_ESCAPE));
    }
    return true;
}

/**
 *  Returns a segment of the path by it's index.
 *
 *  For path "/a/b/c":
 *      `GetSegment(0) == "a"`
 *      `GetSegment(1) == "b"`
 *      `GetSegment(2) == "c"`
 *      `GetSegment(3) == none`
 *  For path "/":
 *      `GetSegment(0) == ""`
 *      `GetSegment(1) == none`
 *  For path "":
 *      `GetSegment(0) == none`
 *  For path "abc":
 *      `GetSegment(0) == "abc"`
 *      `GetSegment(1) == none`
 *
 *  @param  index   Index of the segment to return. Must be inside
 *      `[0; GetLength() - 1]` segment.
 *  @return Path's segment as a `Text`. If passed `index` is outside of
 *      `[0; GetLength() - 1]` segment - returns `none`.
 */
public final function Text GetSegment(int index)
{
    if (index < 0)              return none;
    if (index >= keys.length)   return none;
    if (keys[index] == none)    return none;
    return keys[index].Copy();
}

/**
 *  Amount of path segments in this JSON pointer.
 *
 *  For more details see `GetSegment()`.
 *
 *  @return Amount of segments in the caller `JSONPointer`.
 */
public final function int GetLength()
{
    return keys.length;
}

defaultproperties
{
    TSLASH                  = 0
    stringConstants(0)      = "/"
    TJSON_ESCAPE            = 1
    stringConstants(1)      = "~"
    TJSON_ESCAPED_SLASH     = 2
    stringConstants(2)      = "~1"
    TJSON_ESCAPED_ESCAPE    = 3
    stringConstants(3)      = "~0"
}