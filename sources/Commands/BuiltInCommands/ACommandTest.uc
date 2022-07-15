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
class ACommandTest extends Command;

protected function BuildData(CommandDataBuilder builder)
{
    builder.Name(P("test")).Summary(P("Tests various stuff. Simply call it."))
        .OptionalParams()
        .ParamText(P("option"));
}

protected function Executed(Command.CallData result, EPlayer callerPlayer)
{
    local Parser    parser;
    local HashTable root;
    /*local int i;
    local WeaponLocker lol;
    local array<WeaponLocker> aaa;
    local Text message;
    local Timer testTimer;
    message = _.text.FromString("Is lobby?" @ _.kf.IsInLobby() @
        "Is pre game?" @ _.kf.IsInPreGame() @
        "Is trader?" @ _.kf.IsTraderActive() @
        "Is wave?" @ _.kf.IsWaveActive() @
        "Is finished?" @ _.kf.IsGameFinished() @
        "Is wipe?" @ _.kf.IsWipe());
    _.console.ForAll().WriteLine(message);
    testTimer = Timer(_.memory.Allocate(class'Timer'));
    testTimer.SetInterval(result.GetParameters().GetInt(P("add")));
    testTimer.Start();
    testTimer.OnElapsed(self).connect = OnTick;
    testTimer.SetAutoReset(true);
    for (i = 0; i < 100; i += 1) {
        class'WeaponLocker'.default.bCollideWorld   = false;
        class'WeaponLocker'.default.bBlockActors    = false;
        lol = WeaponLocker(_.memory.Allocate(class'WeaponLocker'));
        aaa[i] = lol;
        Log("HUH" @ lol.Destroy());
        class'WeaponLocker'.default.bCollideWorld   = true;
        class'WeaponLocker'.default.bBlockActors    = true;
    }
    for (i = 0; i < 100; i += 1) {
        if (aaa[i] != none)
        {
            Log("UMBRA" @ aaa[i]);
        }
    }*/
    parser = _.text.ParseString("{\"innerObject\":{\"my_bool\":true,\"array\":[\"Engine.Actor\",false,null,{\"something \\\"here\\\"\":\"yes\",\"maybe\":0.003},56.6],\"one more\":{\"nope\":324532,\"whatever\":false,\"o rly?\":\"ya rly\"},\"my_int\":-9823452},\"some_var\":-7.32,\"another_var\":\"aye!\"}");
    root = _.json.ParseHashTableWith(parser);
    callerPlayer.BorrowConsole().WriteLine(_.json.PrettyPrint(root));
}

defaultproperties
{
}