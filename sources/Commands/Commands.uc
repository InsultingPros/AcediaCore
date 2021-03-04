/**
 *      This feature provides a mechanism to define commands that automatically
 *  parse their arguments into standard Acedia collection. It also allows to
 *  manage them (and specify limitation on how they can be called) in a
 *  centralized manner.
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
class Commands extends Feature
    config(AcediaSystem);

//  Delimiters that always separate command name from it's parameters
var private array<Text>         commandDelimiters;
//  Registered commands, recorded as (<command_name>, <command_instance>) pairs
var private AssociativeArray    registeredCommands;

//  Setting this to `true` enables players to input commands right in the chat
//  by prepending them with "!" character.
var public config bool useChatInput;

var LoggerAPI.Definition errCommandDuplicate;

protected function OnEnabled()
{
    registeredCommands = _.collections.EmptyAssociativeArray();
    //  Macro selector
    commandDelimiters[0] = P("@");
    //  Key selector
    commandDelimiters[1] = P("#");
    //  Player array (possibly JSON array)
    commandDelimiters[2] = P("[");
    //  Negation of the selector
    commandDelimiters[3] = P("!");
}

protected function OnDisabled()
{
    _.memory.Free(registeredCommands);
    registeredCommands          = none;
    commandDelimiters.length    = 0;
}

/**
 *  Registers given command class, making it available for usage.
 *
 *  If `commandClass` provides command with a name that is already taken
 *  (comparison is case-insensitive) by a different command - a warning will be
 *  logged and newly passed `commandClass` discarded.
 *
 *  @param  commandClass    New command class to register.
 */
public final function RegisterCommand(class<Command> commandClass)
{
    local Text      commandName;
    local Command   commandInstance;
    if (commandClass == none)       return;
    if (registeredCommands == none) return;

    commandName = commandClass.static.GetName();
    commandInstance = Command(registeredCommands.GetItem(commandName));
    if (commandInstance != none)
    {
        _.logger.Auto(errCommandDuplicate)
            .ArgClass(commandInstance.class)
            .Arg(commandName.Copy())
            .ArgClass(commandClass);
        commandName.FreeSelf();
        return;
    }
    commandInstance = Command(_.memory.Allocate(commandClass, true));
    //  `commandName` used as a key, do not deallocate it
    registeredCommands.SetItem(commandName, commandInstance, true);
}

/**
 *  Returns command based on a given name.
 *
 *  @param  commandName Name of the registered `Command` to return.
 *      Case-insensitive.
 *  @return Command, registered with a given name `commandName`.
 *      If no command with such name was registered - returns `none`.
 */
public final function Command GetCommand(Text commandName)
{
    local Text      commandNameLowerCase;
    local Command   commandInstance;
    if (commandName == none)        return none;
    if (registeredCommands == none) return none;
    commandNameLowerCase = commandName.LowerCopy();
    commandInstance = Command(registeredCommands.GetItem(commandNameLowerCase));
    commandNameLowerCase.FreeSelf();
    return commandInstance;
}

/**
 *  Returns array of names of all available commands.
 *
 *  @return Array of names of all available (registered) commands.
 */
public final function array<Text> GetCommandNames()
{
    local int i;
    local array<AcediaObject>   keys;
    local Text                  nextKeyAsText;
    local array<Text>           keysAsText;
    if (registeredCommands == none) return keysAsText;
    
    keys = registeredCommands.GetKeys();
    for (i = 0; i < keys.length; i += 1)
    {
        nextKeyAsText = Text(keys[i]);
        if (nextKeyAsText != none) {
            keysAsText[keysAsText.length] = nextKeyAsText.Copy();
        }
    }
    return keysAsText;
}

/**
 *  Handles user input: finds appropriate command and passes the rest of
 *  the arguments to it for further processing.
 *
 *  @param  parser          Parser filled with user input that is expected to
 *      contain command's name and it's parameters.
 *  @param  callerPlayer    Player that caused this command call.
 */
public final function HandleInput(Parser parser, APlayer callerPlayer)
{
    local Command       commandInstance;
    local MutableText   commandName;
    if (parser == none) return;
    if (!parser.Ok())   return;

    parser.MUntilMany(commandName, commandDelimiters, true, true);
    commandInstance = GetCommand(commandName);
    commandName.FreeSelf();
    if (parser.Ok() && commandInstance != none) {
        commandInstance.ProcessInput(parser, callerPlayer).FreeSelf();
    }
}

defaultproperties
{
    useChatInput = true
    requiredListeners(0) = class'BroadcastListener_Commands'
    errCommandDuplicate = (l=LOG_Error,m="Command `%1` with name '%2' is already registered. Command `%3` will be ignored.")
}