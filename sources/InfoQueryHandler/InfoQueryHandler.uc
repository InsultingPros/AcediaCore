/**
 *      Utility that help AcediaCore and its `Feature`s to add information to
 *  console queries like "help", "status", etc. in a more unified way.
 *  In Killing Floor this corresponds to "mutate" command.
 *      Copyright 2022 Anton Tarasenko
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
class InfoQueryHandler extends AcediaObject
    abstract;

var private ServiceAnchor anchor;
var private ConsoleWriter currentOutput;
var private InfoQueryHandler_OnQuery_Signal onHelpSignal;
var private InfoQueryHandler_OnQuery_Signal onStatusSignal;
var private InfoQueryHandler_OnQuery_Signal onVersionSignal;
var private InfoQueryHandler_OnQuery_Signal onCreditsSignal;

var private const int TACEDIA_HEADER, TACEDIA_SUBHEADER, TACEDIA_HELP;
var private const int TACEDIA_HELP_COMMANDS_CHAT, TACEDIA_HELP_COMMANDS_CONSOLE;
var private const int TACEDIA_HELP_COMMANDS_CHAT_AND_CONSOLE;
var private const int TACEDIA_HELP_COMMANDS_NO, TACEDIA_HELP_COMMANDS_USELESS;
var private const int TACEDIA_RUNNING, TACEDIA_VERSION, TACEDIA_CREDITS;
var private const int TACEDIA_ACKNOWLEDGMENT, TPREFIX, TSEPARATOR;

public static function StaticConstructor()
{
    if (StaticConstructorGuard()) {
        return;
    }
    default.anchor = ServiceAnchor(__().memory.Allocate(class'ServiceAnchor'));
    default.onHelpSignal    = InfoQueryHandler_OnQuery_Signal(
        __().memory.Allocate(class'InfoQueryHandler_OnQuery_Signal'));
    default.onStatusSignal  = InfoQueryHandler_OnQuery_Signal(
        __().memory.Allocate(class'InfoQueryHandler_OnQuery_Signal'));
    default.onVersionSignal = InfoQueryHandler_OnQuery_Signal(
        __().memory.Allocate(class'InfoQueryHandler_OnQuery_Signal'));
    default.onCreditsSignal = InfoQueryHandler_OnQuery_Signal(
        __().memory.Allocate(class'InfoQueryHandler_OnQuery_Signal'));
    //  We cannot make an instance of an abstract `InfoQueryHandler` class,
    //  use created `ConsoleWriter` to connect
    __server().unreal.mutator.OnMutate(default.anchor).connect = HandleMutate;
}

/**
 *  Called when user uses appropriate tools to request "help" via console query.
 *
 *  [Signature]
 *  <slot>()
 */
/* SIGNAL */
public final static function InfoQueryHandler_OnQuery_Slot OnHelp(
    AcediaObject    receiver,
    Text            header)
{
    local InfoQueryHandler_OnQuery_Slot newSlot;

    StaticConstructor();
    newSlot = InfoQueryHandler_OnQuery_Slot(
        default.onHelpSignal.NewSlot(receiver));
    newSlot.InitializeHeader(header);
    return newSlot;
}

/**
 *  Called when user uses appropriate tools to request "status" via console
 *  query.
 *
 *  [Signature]
 *  <slot>()
 */
/* SIGNAL */
public final static function InfoQueryHandler_OnQuery_Slot OnStatus(
    AcediaObject    receiver,
    Text            header)
{
    local InfoQueryHandler_OnQuery_Slot newSlot;

    StaticConstructor();
    newSlot = InfoQueryHandler_OnQuery_Slot(
        default.onStatusSignal.NewSlot(receiver));
    newSlot.InitializeHeader(header);
    return newSlot;
}


/**
 *  Called when user uses appropriate tools to request "version" via console
 *  query.
 *
 *  [Signature]
 *  <slot>()
 */
/* SIGNAL */
public final static function InfoQueryHandler_OnQuery_Slot OnVersion(
    AcediaObject    receiver,
    Text            header)
{
    local InfoQueryHandler_OnQuery_Slot newSlot;

    StaticConstructor();
    newSlot = InfoQueryHandler_OnQuery_Slot(
        default.onVersionSignal.NewSlot(receiver));
    newSlot.InitializeHeader(header);
    return newSlot;
}


/**
 *  Called when user uses appropriate tools to request "credits" via console
 *  query.
 *
 *  [Signature]
 *  <slot>()
 */
/* SIGNAL */
public final static function InfoQueryHandler_OnQuery_Slot OnCredits(
    AcediaObject    receiver,
    Text            header)
{
    local InfoQueryHandler_OnQuery_Slot newSlot;

    StaticConstructor();
    newSlot = InfoQueryHandler_OnQuery_Slot(
        default.onCreditsSignal.NewSlot(receiver));
    newSlot.InitializeHeader(header);
    return newSlot;
}

/**
 *  Adds header for a component of Acedia named `headerText` to the current
 *  output. Implemented to only work during `InfoQueryHandler`'s signals'
 *  propagation.
 *
 *  @param  headerText  Name of the Acedia's component to print header for.
 */
public final static function AddHeader(Text headerText)
{
    if (default.currentOutput == none) {
        return;
    }
    AddSeparator();
    default.currentOutput
        .Write(T(default.TACEDIA_SUBHEADER))
        .UseColorOnce(__().color.yellow)
        .WriteLine(headerText);
    AddSeparator();
}


/**
 *  Adds standard line separator to the current output. Implemented to only work
 *  during `InfoQueryHandler`'s signals' propagation.
 */
public final static function AddSeparator()
{
    if (default.currentOutput == none) {
        return;
    }
    default.currentOutput
        .Flush()
        .UseColorOnce(__().color.white)
        .WriteLine(T(default.TSEPARATOR));
}

private final static function HandleMutate(
    string              command,
    PlayerController    sendingPlayer)
{
    if (!(  command ~= "help"
        ||  command ~= "status"
        ||  command ~= "version"
        ||  command ~= "credits"))
    {
        return;
    }
    StartOutput(sendingPlayer);
    AddSeparator();
    default.currentOutput.WriteLine(T(default.TACEDIA_HEADER));
    AddSeparator();
    if (command ~= "help")
    {
        OutAcediaHelp();
        default.onHelpSignal.Emit(default.currentOutput);
    }
    else if (command ~= "status")
    {
        OutAcediaStatus();
        default.onStatusSignal.Emit(default.currentOutput);
    }
    else if (command ~= "version")
    {
        OutAcediaVersion();
        default.onVersionSignal.Emit(default.currentOutput);
    }
    else if (command ~= "credits")
    {
        OutAcediaCredits();
        default.onCreditsSignal.Emit(default.currentOutput);
    }
    AddSeparator();
    StopOutput();
}

private final static function StartOutput(PlayerController targetPlayer)
{
    default.currentOutput = __().console.ForController(targetPlayer);
}

private final static function StopOutput()
{
    __().memory.Free(default.currentOutput);
    default.currentOutput = none;
}

private final static function OutAcediaHelp()
{
    local MutableText prefix, builder;

    default.currentOutput
        .Flush()
        .WriteLine(T(default.TACEDIA_HELP));
    if (!class'Commands_Feature'.static.IsEnabled())
    {
        default.currentOutput.WriteLine(T(default.TACEDIA_HELP_COMMANDS_NO));
        return;
    }
    prefix = class'Commands_Feature'.static
        .GetChatPrefix()
        .IntoMutableText()
        .ChangeDefaultColor(__().color.TextEmphasis);
    if (   class'Commands_Feature'.static.IsUsingChatInput()
            &&  class'Commands_Feature'.static.IsUsingMutateInput())
    {
        builder =
            T(default.TACEDIA_HELP_COMMANDS_CHAT_AND_CONSOLE).MutableCopy();
        builder.Replace(T(default.TPREFIX), prefix);
        default.currentOutput.WriteLine(builder);
        __().memory.Free(builder);
    }
    else if (class'Commands_Feature'.static.IsUsingChatInput())
    {
        builder =
            T(default.TACEDIA_HELP_COMMANDS_CHAT).MutableCopy();
        builder.Replace(T(default.TPREFIX), prefix);
        default.currentOutput.WriteLine(builder);   
        __().memory.Free(builder);
    }
    else if (class'Commands_Feature'.static.IsUsingMutateInput())
    {
        default.currentOutput
            .WriteLine(T(default.TACEDIA_HELP_COMMANDS_CONSOLE));
    }
    else
    {
        default.currentOutput
            .WriteLine(T(default.TACEDIA_HELP_COMMANDS_USELESS));
    }
    __().memory.Free(prefix);
}

private final static function OutAcediaStatus()
{
    default.currentOutput.WriteLine(T(default.TACEDIA_RUNNING));
}

private final static function OutAcediaVersion()
{
    default.currentOutput.WriteLine(T(default.TACEDIA_VERSION));
}

private final static function OutAcediaCredits()
{
    default.currentOutput.WriteLine(T(default.TACEDIA_CREDITS));
    default.currentOutput.WriteLine(T(default.TACEDIA_ACKNOWLEDGMENT));
}

defaultproperties
{
    TACEDIA_HEADER                          = 0
    stringConstants(0)  = "{$red Acedia Framework}"
    TACEDIA_SUBHEADER                       = 1
    stringConstants(1)  = "{$red Acedia Framework}{$white  / }"
    TACEDIA_HELP                            = 2
    stringConstants(2)  = "Acedia always supports four commands: {$TextEmphasis help}, {$TextEmphasis status}, {$TextEmphasis version} and {$TextEmphasis credits}"
    TACEDIA_HELP_COMMANDS_CHAT              = 3
    stringConstants(3)  = "To get detailed information about available to you commands, please type {$TextEmphasis %PREFIX%help} in chat"
    TACEDIA_HELP_COMMANDS_CONSOLE           = 4
    stringConstants(4)  = "To get detailed information about available to you commands, please type {$TextEmphasis mutate help -l} in console"
    TACEDIA_HELP_COMMANDS_CHAT_AND_CONSOLE  = 5
    stringConstants(5)  = "To get detailed information about available to you commands, please type {$TextEmphasis %PREFIX%help} in chat or {$TextEmphasis mutate help -l} in console"
    TACEDIA_HELP_COMMANDS_NO                = 6
    stringConstants(6)  = "Unfortunately other commands aren't available right now. To enable them please type {$TextEmphasis mutate acediacommands} in console if you have enough rights to reenable them."
    TACEDIA_HELP_COMMANDS_USELESS           = 7
    stringConstants(7)  = "Unfortunately every known way to access other commands is disabled on this server. To enable them please type {$TextEmphasis mutate acediacommands} in console if you have enough rights to reenable them."
    TACEDIA_RUNNING                         = 8
    stringConstants(8)  = "AcediaCore is running"
    TACEDIA_VERSION                         = 9
    stringConstants(9)  = "AcediaCore version 0.1.dev8 - this is a development version, bugs and issues are expected"
    TACEDIA_CREDITS                         = 10
    stringConstants(10) = "AcediaCore was developed by dkanus, 2019 - 2022"
    TACEDIA_ACKNOWLEDGMENT                  = 11
    stringConstants(11) = "Special thanks for NikC- and Chaos for suggestions, testing and discussion"
    TPREFIX                                 = 12
    stringConstants(12) = "%PREFIX%"
    TSEPARATOR                              = 13
    stringConstants(13) = "============================="
}