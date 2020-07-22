/**
 *      JSON is an open standard file format, and data interchange format,
 *  that uses human-readable text to store and transmit data objects
 *  consisting of name–value pairs and array data types.
 *      For more information refer to https://en.wikipedia.org/wiki/JSON
 *      This is a base class for implementation of JSON data storage for Acedia.
 *      It does not implement parsing and printing from/into human-readable
 *  text representation, just provides means to store such information.
 *
 *      JSON data is stored as an object (represented via `JSONObject`) that
 *  contains a set of name-value pairs, where value can be
 *  a number, string, boolean value, another object or
 *  an array (represented by `JSONArray`).
 *      Copyright 2020 Anton Tarasenko
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
class JSON extends AcediaActor
    abstract;

//  Enumeration for possible types of JSON values.
enum JType
{
    //  Technical type, used to indicate that requested value is missing.
    //  Undefined values are not part of JSON format.
    JSON_Undefined,
    //  An empty value, in teste representation defined by a single word "null".
    JSON_Null,
    //  A number, recorded as a float.
    //  JSON itself doesn't specify whether number is an integer or float.
    JSON_Number,
    //  A string.
    JSON_String,
    //  A bool value.
    JSON_Boolean,
    //  Array of other JSON values, stored without names;
    //  Single array can contain any mix of value types.
    JSON_Array,
    //  Another JSON object, i.e. associative array of name-value pairs
    JSON_Object
};

//  Stores a single JSON value
struct JStorageAtom
{
    //  What type is stored exactly?
    //  Depending on that, uses one of the other fields as a storage.
    var protected JType         type;
    var protected float         numberValue;
    var protected string        stringValue;
    var protected bool          booleanValue;
    //  Used for storing both JSON objects and arrays.
    var protected JSON          complexValue;
    //  Numeric value might not fit into a `float` very well, so we will store
    //  them as both `float` and `integer` and allow user to request any version
    //  of them
    var protected int           numberValueAsInt;
    //  Some `string` values might be actually used to represent classes,
    //  so we will give users an ability to request `string` value as a class.
    var protected class<Object> stringValueAsClass;
    //  To avoid several unsuccessful attempts to load `class` object from
    //  a `string`, we will record whether we've already tied that.
    var protected bool          classLoadingWasAttempted;
};

enum JComparisonResult
{
    JCR_Incomparable,
    JCR_SubSet,
    JCR_Overset,
    JCR_Equal
};

public function JSON Clone()
{
    return none;
}

public function bool IsSubsetOf(JSON rightJSON)
{
    return false;
}

public final function JComparisonResult Compare(JSON rightJSON)
{
    local bool firstIsSubset, secondIsSubset;
    if (rightJSON == none) return JCR_Incomparable;
    firstIsSubset   = IsSubsetOf(rightJSON);
    secondIsSubset  = rightJSON.IsSubsetOf(self);
    if (firstIsSubset)
    {
        if (secondIsSubset) {
            return JCR_Equal;
        }
        else {
            return JCR_SubSet;
        }
    }
    else {
        if (secondIsSubset) {
            return JCR_Overset;
        }
        else {
            return JCR_Incomparable;
        }
    }
}

public final function bool IsEqual(JSON rightJSON)
{
    return (Compare(rightJSON) == JCR_Equal);
}

protected final function bool AreAtomsEqual(
    JStorageAtom atom1,
    JStorageAtom atom2)
{
    if (atom1.type != atom2.type)       return false;
    if (atom1.type == JSON_Undefined)   return true;
    if (atom1.type == JSON_Null)        return true;
    if (atom1.type == JSON_Number) {
        return (    atom1.numberValue       == atom2.numberValue
                &&  atom1.numberValueAsInt  == atom2.numberValueAsInt);
    }
    if (atom1.type == JSON_Boolean) {
        return (atom1.booleanValue == atom2.booleanValue);
    }
    if (atom1.type == JSON_String) {
        return (atom1.stringValue == atom2.stringValue);
    }
    if (atom1.complexValue == none && atom2.complexValue == none) {
        return true;
    }
    if (atom1.complexValue == none || atom2.complexValue == none) {
        return false;
    }
    return atom1.complexValue.IsEqual(atom2.complexValue);
}

protected final function TryLoadingStringAsClass(out JStorageAtom atom)
{
    if (atom.classLoadingWasAttempted) return;
    atom.classLoadingWasAttempted = true;
    atom.stringValueAsClass =
        class<Object>(DynamicLoadObject(atom.stringValue, class'Class', true));
}

defaultproperties
{
}