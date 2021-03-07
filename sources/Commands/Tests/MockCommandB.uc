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
class MockCommandB extends Command;

protected function BuildData(CommandDataBuilder builder)
{
    builder.ParamArray(P("just_array"))
        .ParamText(P("just_text"));
    builder.Option(P("values"))
        .ParamIntegerList(P("types"));
    builder.Option(P("long"))
        .ParamInteger(P("num"))
        .ParamNumberList(P("text"))
        .ParamBoolean(P("huh"));
    builder.Option(P("type"), P("t"))
        .ParamText(P("type"));
    builder.Option(P("Test"))
        .ParamText(P("to_test"));
    builder.Option(P("silent"))
        .Option(P("forced"))
        .Option(P("verbose"), P("V"))
        .Option(P("actual"));
    builder.SubCommand(P("do"))
        .OptionalParams()
        .ParamNumberList(P("numeric list"), P("list"))
        .ParamBoolean(P("maybe"));
    builder.Option(P("remainder"))
        .ParamRemainder(P("everything"));
}

defaultproperties
{
}