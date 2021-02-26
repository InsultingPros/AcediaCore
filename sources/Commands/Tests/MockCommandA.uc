/**
 *  Mock command class for testing.
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
class MockCommandA extends Command;

protected function BuildData(CommandDataBuilder builder)
{
    builder.ParamObject(P("just_obj"))
        .ParamArrayList(P("manyLists"))
        .OptionalParams()
        .ParamObject(P("last_obj"));
    builder.SubCommand(P("simple"))
        .ParamBooleanList(P("isItSimple?"))
        .ParamInteger(P("integer variable"), P("int"))
        .OptionalParams()
        .ParamNumberList(P("numeric list"), P("list"))
        .ParamTextList(P("another list"));
}

defaultproperties
{
}