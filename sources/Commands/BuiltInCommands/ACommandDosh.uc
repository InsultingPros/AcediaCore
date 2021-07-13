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

var protected const int TGOTTEN, TLOST, TDOSH;

protected function BuildData(CommandDataBuilder builder)
{
    builder.Name(P("dosh")).Summary(P("Changes amount of money."));
    builder.RequireTarget();
    builder.ParamInteger(P("amount"))
        .Describe(P("Gives (or takes if negative) players a specified <amount>"
            @ "of money."));
    builder.SubCommand(P("set"))
        .ParamInteger(P("amount"))
        .Describe(P("Sets player's money to a specified <amount>."));
    builder.Option(P("silent"))
        .Describe(P("If specified - players won't receive a notification about"
            @ "obtaining/losing dosh."));
    builder.Option(P("min"))
        .ParamInteger(P("minValue"))
        .Describe(F("Players will retain at least this amount of dosh after"
            @ "the command's execution. In case of conflict, overrides"
            @ "'{$TextEmphasis --max}' option. `0` is assumed by default."));
    builder.Option(P("max"), P("M"))
        .ParamInteger(P("maxValue"))
        .Describe(F("Players will have at most this amount of dosh after"
            @ "the command's execution. In case of conflict, it is overridden"
            @ "by '{$TextEmphasis --min}' option."));
}

protected function ExecutedFor(APlayer player, CommandCall result)
{
    local int                   oldAmount, newAmount;
    local int                   amount, minValue, maxValue;
    local AssociativeArray      commandOptions;
    //  Find min and max value boundaries
    commandOptions = result.GetOptions();
    minValue = commandOptions.GetIntBy(P("/min/minValue"), 0);
    maxValue = commandOptions.GetIntBy(P("/max/maxValue"), MaxInt);
    if (minValue > maxValue) {
        maxValue = minValue;
    }
    //  Change dosh
    oldAmount = player.GetDosh();
    amount = result.GetParameters().GetInt(P("amount"));
    if (result.GetSubCommand().IsEmpty()) {
        newAmount = oldAmount + amount;
    }
    else {
        //  This has to be "dosh set"
        newAmount = amount;
    }
    newAmount = Clamp(newAmount, minValue, maxValue);
    //  Announce dosh change, if necessary
    if (!commandOptions.HasKey(P("silent"))) {
        AnnounceDoshChange(player.Console(), oldAmount, newAmount);
    }
    player.SetDosh(newAmount);  
}

protected function AnnounceDoshChange(
    ConsoleWriter   console,
    int             oldAmount,
    int             newAmount)
{
    local Text amountDeltaAsText;
    if (newAmount > oldAmount)
    {
        amountDeltaAsText = _.text.FromInt(newAmount - oldAmount);
        console.Write(T(TGOTTEN))
            .Write(amountDeltaAsText)
            .WriteLine(T(TDOSH));
    }
    if (newAmount < oldAmount)
    {
        amountDeltaAsText = _.text.FromInt(oldAmount - newAmount);
        console.Write(T(TLOST))
            .Write(amountDeltaAsText)
            .WriteLine(T(TDOSH));
    }
    _.memory.Free(amountDeltaAsText);
}

defaultproperties
{
    TGOTTEN = 0
    stringConstants(0)  = "You've {$TextPositive gotten} "
    TLOST   = 1
    stringConstants(1)  = "You've {$TextNegative lost} "
    TDOSH   = 2
    stringConstants(2)  = " dosh!"
}