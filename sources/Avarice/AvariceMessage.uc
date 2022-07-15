/**
 *      Object that represents a message received from Avarice.
 *      For performance's sake it does not provide a getter/setter interface and
 *  exposes public fields instead. However, for Acedia to correctly function
 *  you are not supposed modify those fields in any way, only using them to
 *  read necessary data.
 *      All `AvariceMessage`'s fields will be automatically deallocated, so if
 *  you need their data - you have to make a copy, instead of simply storing
 *  a reference to them.
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
class AvariceMessage extends AcediaObject;

//  Every message from Avarice has following structure:
//  { "s": "<service_name>", "t": "<command_type>", "p": <any_json_value> }
//  Value of the "s" field
var public Text         service;
//  Value of the "t" field
var public Text         type;
//  Value of the "p" field
var public AcediaObject parameters;

var private HashTable messageTemplate;

var private const int TS, TT, TP;

public static function StaticConstructor()
{
    if (StaticConstructorGuard()) return;
    super.StaticConstructor();

    default.messageTemplate = __().collections.EmptyHashTable();
    ResetTemplate(default.messageTemplate);
}

protected function Finalizer()
{
    __().memory.Free(type);
    __().memory.Free(service);
    __().memory.Free(parameters);
    type = none;
    service = none;
    parameters = none;
}

private static final function ResetTemplate(HashTable template)
{
    if (template == none) {
        return;
    }
    template.SetItem(T(default.TS), none);
    template.SetItem(T(default.TT), none);
    template.SetItem(T(default.TP), none);
}

public final function MutableText ToText()
{
    local MutableText   result;
    local HashTable     template;
    if (type == none)       return none;
    if (service == none)    return none;

    template = default.messageTemplate;
    ResetTemplate(template);
    template.SetItem(T(TT), type);
    template.SetItem(T(TS), service);
    if (parameters != none) {
        template.SetItem(T(TP), parameters);
    }
    result = _.json.Print(template);
    return result;
}

defaultproperties
{
    TS = 0
    stringConstants(0) = "s"
    TT = 1
    stringConstants(1) = "t"
    TP = 2
    stringConstants(2) = "p"
}