/**
 *      Class for representing a JSON pointer (see
 *  https://tools.ietf.org/html/rfc6901).
 *      Allows quick and simple access to components of it's path:
 *  Path "/a/b/c" will be stored as a sequence of components "a", "b" and "c",
 *  path "/" will be stored as a singular empty component ""
 *  and empty path "" would mean that there is not components at all.
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

//  Component of the pointer (the part, separated by slash character '/').
struct Component
{
    //  For arrays, a component is specified by a numeric index;
    //  To avoid parsing `asText`  multiple times we record whether we
    //  have already done so.
    var bool        testedForBeingNumeric;
    //  Numeric index, represented by `asText`;
    //  `-1` if it was already tested and found to be equal to not be a number
    //  (valid index values are always `>= 0`).
    var int         asNumber;
    //  `Text` representation of the component.
    //  Can be equal to `none` only if this component was specified via
    //  numeric index (guarantees `testedForBeingNumeric == true`).
    var MutableText asText;
};
//  Segments of the path this JSON pointer was initialized with
var private array<Component> components;

var protected const int TSLASH, TJSON_ESCAPE, TJSON_ESCAPED_SLASH;
var protected const int TJSON_ESCAPED_ESCAPE;

protected function Finalizer()
{
    Empty();
}

/**
 *  Checks whether caller `JSONPointer` is empty (points at the root value).
 *
 *  @return `true` iff caller `JSONPointer` points at the root value.
 */
public final function bool IsEmpty()
{
    return components.length == 0;
}


/**
 *  Resets caller `JSONPointer`, erasing all of it's components.
 *
 *  @return Caller `JSONPointer` to allow for method chaining.
 */
public final function JSONPointer Empty()
{
    local int i;
    for (i = 0; i < components.length; i += 1) {
        _.memory.Free(components[i].asText);
    }
    components.length = 0;
    return self;
}

/**
 *  Sets caller `JSONPointer` to correspond to a given path in
 *  JSON pointer format (https://tools.ietf.org/html/rfc6901).
 *
 *      If provided `Text` value is an incorrect pointer, then it will be
 *  treated like an empty pointer.
 *      However, if given pointer can be fixed by prepending "/" - it will be
 *  done automatically. This means that "foo/bar" is treated like "/foo/bar",
 *  "path" like "/path", but empty `Text` "" is treated like itself.
 *
 *  @param  pointerAsText   `Text` representation of the JSON pointer.
 *  @return Reference to the caller `JSONPointer` to allow for method chaining.
 */
public final function JSONPointer Set(BaseText pointerAsText)
{
    local int               i;
    local bool              hasEscapedSequences;
    local Component         nextComponent;
    local MutableText       nextPart;
    local array<BaseText>   parts;
    Empty();
    if (pointerAsText == none) {
        return self;
    }
    hasEscapedSequences = (pointerAsText.IndexOf(T(TJSON_ESCAPE)) >= 0);
    parts = pointerAsText.SplitByCharacter(T(TSLASH).GetCharacter(0),, true);
    //  First element of the array is expected to be empty, so throw it away;
    //  If it is not empty - then `pointerAsText` does not start with "/" and
    //  we will pretend that we have already removed first element, thus
    //  "fixing" path (e.g. effectively turning "foo/bar" into "/foo/bar").
    if (parts[0].IsEmpty())
    {
        _.memory.Free(parts[0]);
        parts.Remove(0, 1);
    }
    if (hasEscapedSequences)
    {
        //  Replace escaped sequences "~0" and "~1".
        //  Order is specific, necessity of which is explained in
        //  JSON Pointer's documentation:
        //  https://tools.ietf.org/html/rfc6901
        for (i = 0; i < parts.length; i += 1)
        {
            nextPart = MutableText(parts[i]);
            nextPart.Replace(T(TJSON_ESCAPED_SLASH), T(TSLASH));
            nextPart.Replace(T(TJSON_ESCAPED_ESCAPE), T(TJSON_ESCAPE));
        }
    }
    for (i = 0; i < parts.length; i += 1)
    {
        nextComponent.asText = MutableText(parts[i]);
        components[components.length] = nextComponent;
    }
    return self;
}

/**
 *  Adds new component to the caller `JSONPointer`.
 *
 *  Adding component "new" to the pointer representing path "/a/b/c" would
 *  result in it representing a path "/a/b/c/new".
 *
 *  Although this method can be used to add numeric components, `PushNumeric()`
 *  should be used for that if possible.
 *
 *  @param  newComponent    Component to add. If passed `none` value -
 *      no changes will be made at all.
 *  @return Reference to the caller `JSONPointer` to allow for method chaining.
 */
public final function JSONPointer Push(BaseText newComponent)
{
    local Component newComponentRecord;
    if (newComponent == none) {
        return self;
    }
    newComponentRecord.asText       = newComponent.MutableCopy();
    components[components.length]   = newComponentRecord;
    return self;
}

/**
 *  Adds new numeric component to the caller `JSONPointer`.
 *
 *  Adding component `7` to the pointer representing path "/a/b/c" would
 *  result in it representing a path "/a/b/c/7".
 *
 *  @param  newComponent    Numeric component to add. If passed negative value -
 *      no changes will be made at all.
 *  @return Reference to the caller `JSONPointer` to allow for method chaining.
 */
public final function JSONPointer PushNumeric(int newComponent)
{
    local Component newComponentRecord;
    if (newComponent < 0) {
        return self;
    }
    newComponentRecord.asNumber                 = newComponent;
    //  Obviously this component is going to be numeric
    newComponentRecord.testedForBeingNumeric    = true;
    components[components.length] = newComponentRecord;
    return self;
}

/**
 *  Removes and returns last component from the caller `JSONPointer`.
 *
 *  In `JSONPointer` corresponding to "/ab/c/d" this method would return "d"
 *  and leave caller `JSONPointer` to correspond to "/ab/c".
 *
 *  @param  doNotRemove Set this to `true` if you want to return last component
 *      without changing caller pointer.
 *  @return Last component of the caller `JSONPointer`.
 *      `none` iff caller `JSONPointer` is empty.
 */
public final function Text Pop(optional bool doNotRemove)
{
    local int   lastIndex;
    local Text  result;
    if (components.length <= 0) {
        return none;
    }
    lastIndex = components.length - 1;
    //  Do not use `GetComponent()` to avoid unnecessary `Text` copying
    if (components[lastIndex].asText == none) {
        result = _.text.FromInt(components[lastIndex].asNumber);
    }
    else {
        result = components[lastIndex].asText.Copy();
    }
    if (!doNotRemove)
    {
        _.memory.Free(components[lastIndex].asText);
        components.length = components.length - 1;
    }
    return result;
}

/**
 *  Removes and returns last numeric component from the caller `JSONPointer`.
 *
 *  In `JSONPointer` corresponding to "/ab/c/7" this method would return `7`
 *  and leave caller `JSONPointer` to correspond to "/ab/c".
 *
 *  Component is removed regardless of whether it was actually numeric.
 *
 *  @param  doNotRemove Set this to `true` if you want to return last component
 *      without changing caller pointer.
 *  @return Last component of the caller `JSONPointer`.
 *      `-1` iff caller `JSONPointer` is empty or last component is not numeric.
 */
public final function int PopNumeric(optional bool doNotRemove)
{
    local int lastIndex;
    local int result;
    if (components.length <= 0) {
        return -1;
    }
    lastIndex = components.length - 1;
    result = GetNumericComponent(lastIndex);
    if (!doNotRemove)
    {
        _.memory.Free(components[lastIndex].asText);
        components.length = components.length - 1;
    }
    return result;
}

/**
 *  Returns a component of the path by it's index, starting from `0`.
 *
 *  @param  index   Index of the component to return. Must be inside
 *      `[0; GetLength() - 1]` segment.
 *  @return Path's component as a `Text`. If passed `index` is outside of
 *      `[0; GetLength() - 1]` segment - returns `none`.
 */
public final function Text GetComponent(int index)
{
    if (index < 0)                  return none;
    if (index >= components.length) return none;

    //  `asText` will store `none` only if we have added this component as
    //  numeric one
    if (components[index].asText == none) {
        components[index].asText = _.text.FromIntM(components[index].asNumber);
    }
    return components[index].asText.Copy();
}

/**
 *  Returns a numeric component of the path by it's index, starting from `0`.
 *
 *  @param  index   Index of the component to return. Must be inside
 *      `[0; GetLength() - 1]` segment and correspond to numeric comonent.
 *  @return Path's component as a `Text`. If passed `index` is outside of
 *      `[0; GetLength() - 1]` segment or does not correspond to
 *      a numeric component - returns `-1`.
 */
public final function int GetNumericComponent(int index)
{
    local Parser parser;
    if (index < 0)                  return -1;
    if (index >= components.length) return -1;

    if (!components[index].testedForBeingNumeric)
    {
        components[index].testedForBeingNumeric = true;
        parser = _.text.Parse(components[index].asText);
        parser.MUnsignedInteger(components[index].asNumber);
        if (!parser.Ok() || !parser.HasFinished()) {
            components[index].asNumber = -1;
        }
        parser.FreeSelf();
    }
    return components[index].asNumber;
}

/**
 *  Converts caller `JSONPointer` into it's `Text` representation.
 *
 *  For the method, but returning `MutableText` see `ToTextM()`.
 *
 *  @return `Text` that represents caller `JSONPointer`.
 */
public final function Text ToText()
{
    local Text          result;
    local MutableText   builder;
    builder = ToTextM();
    result = builder.Copy();
    builder.FreeSelf();
    return result;
}

/**
 *  Converts caller `JSONPointer` into it's `MutableText` representation.
 *
 *  For the method, but returning `Text` see `ToTextM()`.
 *
 *  @return `MutableText` that represents caller `JSONPointer`.
 */
public final function MutableText ToTextM()
{
    local int           i;
    local Text          nextComponent;
    local MutableText   nextMutableComponent;
    local MutableText   result;
    result = _.text.Empty();
    if (GetLength() <= 0) {
        return result;
    }
    for (i = 0; i < GetLength(); i += 1)
    {
        nextComponent = GetComponent(i);
        nextMutableComponent = nextComponent.MutableCopy();
        //  Replace (order is important)
        nextMutableComponent.Replace(T(TJSON_ESCAPE), T(TJSON_ESCAPED_ESCAPE));
        nextMutableComponent.Replace(T(TSLASH), T(TJSON_ESCAPED_SLASH));
        result.Append(T(TSLASH)).Append(nextMutableComponent);
        //  Get rid of temporary values
        nextMutableComponent.FreeSelf();
        nextComponent.FreeSelf();
    }
    return result;
}

/**
 *  Amount of path components in the caller `JSONPointer`.
 *
 *  Also see `GetFoldsAmount()` method.
 *
 *  @return Amount of components in the caller `JSONPointer`.
 */
public final function int GetLength()
{
    return components.length;
}

/**
 *  Amount of path components in the caller `JSONPointer` that do not directly
 *  correspond to a pointed value.
 *
 *  Equal to the `Max(0, GetLength() - 1)`.
 *
 *  For example, path "/user/Ivan/records/5/count" refers to the value named
 *  "value" that is _folded_ inside  `4` objects named "users", "Ivan",
 *  "records" and "5". Therefore it's folds amount if `4`.
 *
 *  @return Amount of components in the caller `JSONPointer` that do not
 *  directly correspond to a pointed value.
 */
public final function int GetFoldsAmount()
{
    return Max(0, components.length - 1);
}

/**
 *  Makes an exact copy of the caller `JSONPointer`.
 *
 *  @return Copy of the caller `JSONPointer`.
 */
public final function JSONPointer Copy()
{
    local int               i;
    local JSONPointer       newPointer;
    local array<Component>  newComponents;
    newComponents = components;
    for (i = 0; i < newComponents.length; i += 1)
    {
        if (newComponents[i].asText != none) {
            newComponents[i].asText = newComponents[i].asText.MutableCopy();
        }
    }
    newPointer = JSONPointer(_.memory.Allocate(class'JSONPointer'));
    newPointer.components = newComponents;
    return newPointer;
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