/**
 *  Command for changing nickname of the player.
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
class ACommandNick extends Command;

//'dosh' for giving dosh (subcommand for setting it, options for min/max resulting value, silent)
protected function BuildData(CommandDataBuilder builder)
{
    builder.RequireTarget();
    builder.ParamText(P("nick"))
        .Describe(P("Sets new nickname to the targeted players."));
}

protected function ExecutedFor(APlayer player, CommandCall result)
{
    player.SetName(Text(result.GetParameters().GetItem(P("nick"))));
}

defaultproperties
{
    commandName = "nick"
}