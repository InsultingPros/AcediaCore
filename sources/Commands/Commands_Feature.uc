/**
 *      This feature provides a mechanism to define commands that automatically
 *  parse their arguments into standard Acedia collection. It also allows to
 *  manage them (and specify limitation on how they can be called) in a
 *  centralized manner.
 *      Copyright 2021 - 2022 Anton Tarasenko
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
class Commands_Feature extends Feature;

//  Delimiters that always separate command name from it's parameters
var private array<Text> commandDelimiters;
//  Registered commands, recorded as (<command_name>, <command_instance>) pairs.
//  Keys should be deallocated when their entry is removed.
var private HashTable   registeredCommands;
//  `HashTable` of "<command_group_name>" <-> `ArrayList` of commands pairs
//  to allow quick fetch of commands belonging to a single group
var private HashTable   groupedCommands;

//  When this flag is set to true, mutate input becomes available
//  despite `useMutateInput` flag to allow to unlock server in case of an error
var private bool emergencyEnabledMutate;

//  Setting this to `true` enables players to input commands right in the chat
//  by prepending them with `chatCommandPrefix`.
//  Default is `true`.
var private /*config*/ bool useChatInput;
//  Setting this to `true` enables players to input commands with "mutate"
//  console command.
//  Default is `true`.
var private /*config*/ bool useMutateInput;
//  Chat messages, prepended by this prefix will be treated as commands.
//  Default is "!". Empty values are also treated as "!".
var private /*config*/ Text chatCommandPrefix;
//  List of steam IDs of players allowed to use commands.
//  Temporary measure until a better solution is finished.
var private /*config*/ array<string> allowedPlayers;

var LoggerAPI.Definition errCommandDuplicate;

protected function OnEnabled()
{
    registeredCommands  = _.collections.EmptyHashTable();
    groupedCommands     = _.collections.EmptyHashTable();
    RegisterCommand(class'ACommandHelp');
    //  Macro selector
    commandDelimiters[0] = _.text.FromString("@");
    //  Key selector
    commandDelimiters[1] = _.text.FromString("#");
    //  Player array (possibly JSON array)
    commandDelimiters[2] = _.text.FromString("[");
    //  Negation of the selector
    commandDelimiters[3] = _.text.FromString("!");
}

protected function OnDisabled()
{
    if (useChatInput) {
        _.chat.OnMessage(self).Disconnect();
    }
    if (useMutateInput) {
        _server.unreal.mutator.OnMutate(self).Disconnect();
    }
    useChatInput    = false;
    useMutateInput  = false;
    _.memory.Free(registeredCommands);
    _.memory.Free(groupedCommands);
    _.memory.Free(chatCommandPrefix);
    _.memory.FreeMany(commandDelimiters);
    registeredCommands  = none;
    groupedCommands     = none;
    chatCommandPrefix   = none;
    commandDelimiters.length = 0;
}

protected function SwapConfig(FeatureConfig config)
{
    local Commands newConfig;

    newConfig = Commands(config);
    if (newConfig == none) {
        return;
    }
    _.memory.Free(chatCommandPrefix);
    chatCommandPrefix = _.text.FromString(newConfig.chatCommandPrefix);
    allowedPlayers = newConfig.allowedPlayers;
    if (useChatInput != newConfig.useChatInput)
    {
        useChatInput = newConfig.useChatInput;
        if (newConfig.useChatInput) {
            _.chat.OnMessage(self).connect = HandleCommands;
        }
        else {
            _.chat.OnMessage(self).Disconnect();
        }
    }
    //  Do not make any modifications here in case "mutate" was
    //  emergency-enabled
    if (useMutateInput != newConfig.useMutateInput && !emergencyEnabledMutate)
    {
        useMutateInput = newConfig.useMutateInput;
        if (newConfig.useMutateInput) {
            _server.unreal.mutator.OnMutate(self).connect = HandleMutate;
        }
        else {
            _server.unreal.mutator.OnMutate(self).Disconnect();
        }
    }
}

/**
 *  `Command_Feature` is a critical command to have running on your server and,
 *  if disabled by accident, there will be no way of starting it again without
 *  restarting the level or even editing configs.
 *
 *  This method allows to enable it along with "mutate" input in case something
 *  goes wrong.
 */
public final static function EmergencyEnable()
{
    local Text              autoConfig;
    local Commands_Feature  feature;

    if (!IsEnabled())
    {
        autoConfig = GetAutoEnabledConfig();
        EnableMe(autoConfig);
        __().memory.Free(autoConfig);
    }
    feature = Commands_Feature(GetEnabledInstance());
    if (    !feature.emergencyEnabledMutate
        &&  !feature.IsUsingMutateInput() && !feature.IsUsingChatInput())
    {
        default.emergencyEnabledMutate = true;
        feature.emergencyEnabledMutate = true;
        __server().unreal.mutator.OnMutate(feature).connect = HandleMutate;
    }
}

/**
 *  Checks if `Commands_Feature` currently uses chat as input.
 *  If `Commands_Feature` is not enabled, then it does not use anything
 *  as input.
 *
 *  @return `true` if `Commands_Feature` is currently enabled and is using chat
 *      as input and `false` otherwise.
 */
public final static function bool IsUsingChatInput()
{
    local Commands_Feature instance;

    instance = Commands_Feature(GetEnabledInstance());
    if (instance != none) {
        return instance.useChatInput;
    }
    return false;
}

/**
 *  Checks if `Commands_Feature` currently uses mutate command as input.
 *  If `Commands_Feature` is not enabled, then it does not use anything
 *  as input.
 *
 *  @return `true` if `Commands_Feature` is currently enabled and is using
 *      mutate command as input and `false` otherwise.
 */
public final static function bool IsUsingMutateInput()
{
    local Commands_Feature instance;

    instance = Commands_Feature(GetEnabledInstance());
    if (instance != none) {
        return instance.useMutateInput;
    }
    return false;
}

/**
 *  Returns prefix that will indicate that chat message is intended to be
 *  a command. By default "!".
 *
 *  @return Prefix that indicates that chat message is intended to be a command.
 *      If `Commands_Feature` is disabled, always returns `false`.
 */
public final static function Text GetChatPrefix()
{
    local Commands_Feature instance;

    instance = Commands_Feature(GetEnabledInstance());
    if (instance != none && instance.chatCommandPrefix != none) {
        return instance.chatCommandPrefix.Copy();
    }
    return none;
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
    local Text      commandName, groupName;
    local ArrayList groupArray;
    local Command   newCommandInstance, existingCommandInstance;

    if (commandClass == none)       return;
    if (registeredCommands == none) return;

    newCommandInstance  = Command(_.memory.Allocate(commandClass, true));
    commandName         = newCommandInstance.GetName();
    groupName           = newCommandInstance.GetGroupName();
    //  Check for duplicates and report them
    existingCommandInstance = Command(registeredCommands.GetItem(commandName));
    if (existingCommandInstance != none)
    {
        _.logger.Auto(errCommandDuplicate)
            .ArgClass(existingCommandInstance.class)
            .Arg(commandName)
            .ArgClass(commandClass);
        _.memory.Free(groupName);
        _.memory.Free(newCommandInstance);
        _.memory.Free(existingCommandInstance);
        return;
    }
    //  Otherwise record new command
    //  `commandName` used as a key, do not deallocate it
    registeredCommands.SetItem(commandName, newCommandInstance);
    //  Add to grouped collection
    groupArray = groupedCommands.GetArrayList(groupName);
    if (groupArray == none) {
        groupArray = _.collections.EmptyArrayList();
    }
    groupArray.AddItem(newCommandInstance);
    groupedCommands.SetItem(groupName, groupArray);
    _.memory.Free(groupArray);
    _.memory.Free(groupName);
    _.memory.Free(commandName);
    _.memory.Free(newCommandInstance);
}

/**
 *  Removes command of class `commandClass` from the list of
 *  registered commands.
 *
 *  WARNING: removing once registered commands is not an action that is expected
 *  to be performed under normal circumstances and it is not efficient.
 *  It is linear on the current amount of commands.
 *
 *  @param  commandClass    Class of command to remove from being registered.
 */
public final function RemoveCommand(class<Command> commandClass)
{
    local int                   i;
    local CollectionIterator    iter;
    local Command               nextCommand;
    local Text                  nextCommandName;
    local array<Text>           commandGroup;          
    local array<Text>           keysToRemove;

    if (commandClass == none)       return;
    if (registeredCommands == none) return;

    for (iter = registeredCommands.Iterate(); !iter.HasFinished(); iter.Next())
    {
        nextCommand     = Command(iter.Get());
        nextCommandName = Text(iter.GetKey());
        if (    nextCommand == none || nextCommandName == none
            ||  nextCommand.class != commandClass)
        {
            _.memory.Free(nextCommand);
            _.memory.Free(nextCommandName);
            continue;
        }
        keysToRemove[keysToRemove.length] = nextCommandName;
        commandGroup[commandGroup.length] = nextCommand.GetGroupName();
        _.memory.Free(nextCommand);
    }
    iter.FreeSelf();
    for (i = 0; i < keysToRemove.length; i += 1)
    {
        registeredCommands.RemoveItem(keysToRemove[i]);
        _.memory.Free(keysToRemove[i]);
    }

    for (i = 0; i < commandGroup.length; i += 1) {
        RemoveClassFromGroup(commandClass, commandGroup[i]);
    }
    _.memory.FreeMany(commandGroup);
}

private final function RemoveClassFromGroup(
    class<Command>  commandClass,
    BaseText        commandGroup)
{
    local int       i;
    local ArrayList groupArray;
    local Command   nextCommand;

    groupArray = groupedCommands.GetArrayList(commandGroup);
    if (groupArray == none) {
        return;
    }
    while (i < groupArray.GetLength())
    {
        nextCommand = Command(groupArray.GetItem(i));
        if (nextCommand != none && nextCommand.class == commandClass) {
            groupArray.RemoveIndex(i);
        }
        else {
            i += 1;
        }
        _.memory.Free(nextCommand);
    }
    if (groupArray.GetLength() == 0) {
        groupedCommands.RemoveItem(commandGroup);
    }
    _.memory.Free(groupArray);
}

/**
 *  Returns command based on a given name.
 *
 *  @param  commandName Name of the registered `Command` to return.
 *      Case-insensitive.
 *  @return Command, registered with a given name `commandName`.
 *      If no command with such name was registered - returns `none`.
 */
public final function Command GetCommand(BaseText commandName)
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
    local array<Text> emptyResult;

    if (registeredCommands != none) {
        return registeredCommands.GetTextKeys();
    }
    return emptyResult;
}

/**
 *  Returns array of names of all available commands belonging to the group
 *      `groupName`.
 *
 *  @return Array of names of all available (registered) commands, belonging to
 *      the group `groupName`.
 */
public final function array<Text> GetCommandNamesInGroup(BaseText groupName)
{
    local int           i;
    local ArrayList     groupArray;
    local Command       nextCommand;
    local array<Text>   result;

    if (groupedCommands == none)    return result;
    groupArray = groupedCommands.GetArrayList(groupName);
    if (groupArray == none)         return result;

    for (i = 0; i < groupArray.GetLength(); i += 1)
    {
        nextCommand = Command(groupArray.GetItem(i));
        if (nextCommand != none) {
            result[result.length] = nextCommand.GetName();
        }
        _.memory.Free(nextCommand);
    }
    return result;
}

/**
 *  Returns all available command groups' names.
 *
 *  @return Array of all available command groups' names.
 */
public final function array<Text> GetGroupsNames()
{
    local array<Text> emptyResult;

    if (groupedCommands != none) {
        return groupedCommands.GetTextKeys();
    }
    return emptyResult;
}

/**
 *  Handles user input: finds appropriate command and passes the rest of
 *  the arguments to it for further processing.
 *
 *  @param  parser          Parser filled with user input that is expected to
 *      contain command's name and it's parameters.
 *  @param  callerPlayer    Player that caused this command call.
 */
public final function HandleInput(Parser parser, EPlayer callerPlayer)
{
    local int               i;
    local bool              foundID;
    local string            steamID;
    local PlayerController  controller;
    local Command           commandInstance;
    local Command.CallData  callData;
    local MutableText       commandName;

    if (parser == none)     return;
    if (!parser.Ok())       return;
    controller = callerPlayer.GetController();
    if (controller == none) return;

    steamID = controller.GetPlayerIDHash();
    for (i = 0; i < allowedPlayers.length; i += 1)
    {
        if (allowedPlayers[i] == steamID)
        {
            foundID = true;
            break;
        }
    }
    if (!foundID) {
        return;
    }
    parser.MUntilMany(commandName, commandDelimiters, true, true);
    commandInstance = GetCommand(commandName);
    if (    commandInstance == none
        &&  callerPlayer != none && callerPlayer.IsExistent())
    {
        callerPlayer
            .BorrowConsole()
            .Flush()
            .Say(F("{$TextFailure Command not found!}"));
    }
    commandName.FreeSelf();
    if (parser.Ok() && commandInstance != none)
    {
        callData = commandInstance.ParseInputWith(parser, callerPlayer);
        commandInstance.Execute(callData, callerPlayer);
        commandInstance.DeallocateCallData(callData);
    }
}

private function bool HandleCommands(
    EPlayer     sender,
    MutableText message,
    bool        teamMessage)
{
    local Parser parser;

    //  We are only interested in messages that start with `chatCommandPrefix`
    parser = _.text.Parse(message);
    if (!parser.Match(chatCommandPrefix).Ok())
    {
        parser.FreeSelf();
        return true;
    }
    //  Pass input to command feature
    HandleInput(parser, sender);
    parser.FreeSelf();
    return false;
}

private function HandleMutate(string command, PlayerController sendingPlayer)
{
    local Parser    parser;
    local EPlayer   sender;

    //  A lot of other mutators use these commands
    if (command ~= "help")      return;
    if (command ~= "version")   return;
    if (command ~= "status")    return;
    if (command ~= "credits")   return;

    parser = _.text.ParseString(command);
    sender = _.players.FromController(sendingPlayer);
    HandleInput(parser, sender);
    sender.FreeSelf();
    parser.FreeSelf();
}

defaultproperties
{
    configClass = class'Commands'
    errCommandDuplicate = (l=LOG_Error,m="Command `%1` is already registered with name '%2'. Command `%3` with the same name will be ignored.")
}