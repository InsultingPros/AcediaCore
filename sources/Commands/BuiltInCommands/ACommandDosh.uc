/**
 *  Command for changing amount of money players have.
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
class ACommandDosh extends Command;

//'dosh' for giving dosh (subcommand for setting it, options for min/max resulting value, silent)
protected function BuildData(CommandDataBuilder builder)
{
    builder.RequireTarget();
    builder.ParamInteger(P("amount"))
        .Describe(P("Gives (takes if negative) players a specified <amount>"
            @ "of money."));
    builder.SubCommand(P("set"))
        .ParamInteger(P("amount"))
        .Describe(P("Sets players' money to a specified <amount>."));
    builder.Option(P("silent"))
        .Describe(P("If specified - players won't receive a notification about"
            @ "obtaining/losing dosh."));
    builder.Option(P("min"))
        .ParamInteger(P("minValue"))
        .Describe(F("Players will retain at least this amount of dosh after"
            @ "the command's execution. In case of conflict overrides"
            @ "'{$TextEmphasis --max}' option. `0` is assumed by default."));
    builder.Option(P("max"), P("M"))
        .ParamInteger(P("maxValue"))
        .Describe(F("Players will have at most this amount of dosh after"
            @ "the command's execution. In case of conflict is overridden by"
            @ "'{$TextEmphasis --min}' option."));
}

protected function ExecutedFor(APlayer player, CommandCall result)
{
    local int                   oldAmount, newAmount;
    local int                   amount, minValue, maxValue;
    local AssociativeArray      commandOptions;
    //  Find min and max value boundaries
    minValue = 0;
    maxValue = MaxInt;
    commandOptions = result.GetOptions();
    if (commandOptions.HasKey(P("min")))
    {
        minValue = IntBox(AssociativeArray(commandOptions.GetItem(P("min")))
            .GetItem(P("minValue"))).Get();
    }
    if (commandOptions.HasKey(P("max"))) {
        minValue = IntBox(AssociativeArray(commandOptions.GetItem(P("max")))
            .GetItem(P("maxValue"))).Get();
    }
    if (minValue > maxValue) {
        maxValue = minValue;
    }
    //  Change dosh
    oldAmount = player.GetDosh();
    amount = IntBox(result.GetParameters().GetItem(P("amount"))).Get();
    if (result.GetSubCommand().IsEmpty()) {
        newAmount = oldAmount + amount;
    }
    else {
        newAmount = amount;
    }
    //  Enforce min/max bounds
    if (newAmount > maxValue) {
        newAmount = maxValue;
    }
    if (newAmount < minValue) {
        newAmount = minValue;
    }
    if (!commandOptions.HasKey(P("silent")))
    {
        if (newAmount > oldAmount)
        {
            player.Console().WriteLine(P("You've gotten"
                @ newAmount - oldAmount @ "dosh!"));
        }
        if (newAmount < oldAmount)
        {
            player.Console().WriteLine(P("You've lost"
            @ oldAmount - newAmount @ "dosh!"));
        }
    }
    player.SetDosh(newAmount);  
}

defaultproperties
{
    commandName = "dosh"
}