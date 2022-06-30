/**
 *      Object for parsing what converting textual description of a group of
 *  players into array of `EPlayer`s. Depends on the game context.
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
class PlayersParser extends AcediaObject
    dependson(Parser);

/**
 *      This parser is supposed to parse player set definitions as they
 *  are used in commands.
 *      Basic use is to specify one of the selectors:
 *      1. Key selector: "#<integer>" (examples: "#1", "#5").
 *          This one is used to specify players by their key, assigned to
 *          them when they enter the game. This type of selectors can be used
 *          when players have hard to type names.
 *      2. Macro selector: "@self", "@me", "@all", "@admin" or just "@".
 *          "@", "@me", and "@self" are identical and can be used to
 *          specify player that called the command.
 *          "@admin" can be used to specify all admins in the game at once.
 *          "@all" specifies all current players.
 *          In future it is planned to make macros extendable by allowing to
 *          bind more names to specific groups of players.
 *      3. Name selectors: quoted strings and any other types of string that
 *          do not start with either "#" or "@".
 *          These specify name prefixes: any player with specified prefix
 *          will be considered to match such selector.
 *
 *      Negated selectors: "!<selector>". Specifying "!" in front of selector
 *      will select all players that do not match it instead.
 *
 *      Grouped selectors: "['<selector1>', '<selector2>', ... '<selectorN>']".
 *  Specified selectors are process in order: from left to right.
 *  First selector works as usual and selects a set of players.
 *  All the following selectors either
 *  expand that list (additive ones, without "!" prefix)
 *  or remove specific players from the list (the ones with "!" prefix).
 *      Examples of that:
 *      *. "[@admin, !@self]" - selects all admins, except the one who called
 *          the command (whether he is admin or not).
 *      *. "[dkanus, 'mate']" - will select players "dkanus" and "mate".
 *      Order also matters, since:
 *      *. "[@admin, !@admin]" - won't select anyone, since it will first
 *          add all the admins and then remove them.
 *      *. "[!@admin, @admin]" - will select everyone, since it will first
 *          select everyone who is not an admin and then adds everyone else.
 */

//  Player for which "@", "@me", and "@self" macros will refer
var private EPlayer         selfPlayer;
//  Copy of the list of current players at the moment of allocation of
//  this `PlayersParser`.
var private array<EPlayer>  playersSnapshot;
//  Players, selected according to selectors we have parsed so far
var private array<EPlayer>  currentSelection;
//  Have we parsed our first selector?
//  We need this to know whether to start with the list of
//  all players (if first selector removes them) or
//  with empty list (if first selector adds them).
var private bool            parsedFirstSelector;
//  Will be equal to a single-element array [","], used for parsing
var private array<Text>     selectorDelimiters;

var const int TSELF, TME, TADMIN, TALL, TNOT, TKEY, TMACRO, TCOMMA;
var const int TOPEN_BRACKET, TCLOSE_BRACKET;

protected function Finalizer()
{
    //  No need to deallocate `currentSelection`,
    //  since it has `EPlayer`s from `playersSnapshot` or `selfPlayer`
    _.memory.Free(selfPlayer);
    _.memory.FreeMany(playersSnapshot);
    selfPlayer              = none;
    parsedFirstSelector     = false;
    playersSnapshot.length  = 0;
    currentSelection.length = 0;
}

/**
 *  Set a player who will be referred to by "@", "@me" and "@self" macros.
 *
 *  @param  newSelfPlayer   Player who will be referred to by "@", "@me" and
 *      "@self" macros. Passing `none` will make it so no one is
 *      referred by them.
 */
public final function SetSelf(EPlayer newSelfPlayer)
{
    _.memory.Free(selfPlayer);
    if (newSelfPlayer != none) {
        selfPlayer = EPlayer(newSelfPlayer.Copy());
    }
}

//      Insert a new player into currently selected list of players
//  (`currentSelection`) such that there will be no duplicates.
//      `none` values are auto-discarded.
private final function InsertPlayer(EPlayer toInsert)
{
    local int i;

    if (toInsert == none) {
        return;
    }
    for (i = 0; i < currentSelection.length; i += 1)
    {
        if (currentSelection[i] == toInsert) {
            return;
        }
    }
    currentSelection[currentSelection.length] = toInsert;
}

//  Adds all the players with specified key (`key`) to the current selection.
private final function AddByKey(int key)
{
    local int i;

    for (i = 0; i < playersSnapshot.length; i += 1)
    {
        if (playersSnapshot[i].GetIdentity().GetKey() == key) {
            InsertPlayer(playersSnapshot[i]);
        }
    }
}

//  Removes all the players with specified key (`key`) from
//  the current selection.
private final function RemoveByKey(int key)
{
    local int i;

    while (i < currentSelection.length)
    {
        if (currentSelection[i].GetIdentity().GetKey() == key) {
            currentSelection.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
}

//  Adds all the players with specified name (`name`) to the current selection.
private final function AddByName(BaseText name)
{
    local int   i;
    local Text  nextPlayerName;

    if (name == none) {
        return;
    }
    for (i = 0; i < playersSnapshot.length; i += 1)
    {
        nextPlayerName = playersSnapshot[i].GetName();
        if (nextPlayerName.StartsWith(name, SCASE_INSENSITIVE)) {
            InsertPlayer(playersSnapshot[i]);
        }
        nextPlayerName.FreeSelf();
    }
}

//  Removes all the players with specified name (`name`) from
//  the current selection.
private final function RemoveByName(BaseText name)
{
    local int   i;
    local Text  nextPlayerName;

    while (i < currentSelection.length)
    {
        nextPlayerName = currentSelection[i].GetName();
        if (nextPlayerName.StartsWith(name, SCASE_INSENSITIVE)) {
            currentSelection.Remove(i, 1);
        }
        else {
            i += 1;
        }
        nextPlayerName.FreeSelf();
    }
}

//  Adds all the admins to the current selection.
private final function AddAdmins()
{
    local int i;

    for (i = 0; i < playersSnapshot.length; i += 1)
    {
        if (playersSnapshot[i].IsAdmin()) {
            InsertPlayer(playersSnapshot[i]);
        }
    }
}

//  Removes all the admins from the current selection.
private final function RemoveAdmins()
{
    local int i;

    while (i < currentSelection.length)
    {
        if (currentSelection[i].IsAdmin()) {
            currentSelection.Remove(i, 1);
        }
        else {
            i += 1;
        }
    }
}

//  Add all the players specified by `macroText` (from macro "@<macroText>").
//  Does nothing if there is no such macro.
private final function AddByMacro(BaseText macroText)
{
    if (macroText.Compare(T(TADMIN), SCASE_INSENSITIVE))
    {
        AddAdmins();
        return;
    }
    if (macroText.Compare(T(TALL), SCASE_INSENSITIVE))
    {
        currentSelection = playersSnapshot;
        return;
    }
    if (    macroText.IsEmpty()
        ||  macroText.Compare(T(TSELF), SCASE_INSENSITIVE)
        ||  macroText.Compare(T(TME), SCASE_INSENSITIVE))
    {
        InsertPlayer(selfPlayer);
    }
}

//      Removes all the players specified by `macroText`
//  (from macro "@<macroText>").
//      Does nothing if there is no such macro.
private final function RemoveByMacro(BaseText macroText)
{
    local int i;

    if (macroText.Compare(T(TADMIN), SCASE_INSENSITIVE))
    {
        RemoveAdmins();
        return;
    }
    if (macroText.Compare(T(TALL), SCASE_INSENSITIVE))
    {
        currentSelection.length = 0;
        return;
    }
    if (macroText.IsEmpty() || macroText.Compare(T(TSELF), SCASE_INSENSITIVE))
    {
        while (i < currentSelection.length)
        {
            if (currentSelection[i] == selfPlayer) {
                currentSelection.Remove(i, 1);
            }
            else {
                i += 1;
            }
        }
    }
}

//  Parses one selector from `parser`, while accordingly modifying current
//  player selection list.
private final function ParseSelector(Parser parser)
{
    local bool                  additiveSelector;
    local Parser.ParserState    confirmedState;

    if (parser == none) return;
    if (!parser.Ok())   return;

    confirmedState = parser.GetCurrentState();
    if (!parser.Match(T(TNOT)).Ok())
    {
        additiveSelector = true;
        parser.RestoreState(confirmedState);
    }
    //  Determine whether we stars with empty or full player list
    if (!parsedFirstSelector)
    {
        parsedFirstSelector = true;
        if (additiveSelector) {
            currentSelection.length = 0;
        }
        else {
            currentSelection = playersSnapshot;
        }
    }
    //  Try all selector types
    confirmedState = parser.GetCurrentState();
    if (parser.Match(T(TKEY)).Ok())
    {
        ParseKeySelector(parser, additiveSelector);
        return;
    }
    parser.RestoreState(confirmedState);
    if (parser.Match(T(TMACRO)).Ok())
    {
        ParseMacroSelector(parser, additiveSelector);
        return;
    }
    parser.RestoreState(confirmedState);
    ParseNameSelector(parser, additiveSelector);
}

//  Parse key selector (assuming "#" is already consumed), while accordingly
//  modifying current player selection list.
private final function ParseKeySelector(Parser parser, bool additiveSelector)
{
    local int key;

    if (parser == none)             return;
    if (!parser.Ok())               return;
    if (!parser.MInteger(key).Ok()) return;

    if (additiveSelector) {
        AddByKey(key);
    }
    else {
        RemoveByKey(key);
    }
}

//  Parse macro selector (assuming "@" is already consumed), while accordingly
//  modifying current player selection list.
private final function ParseMacroSelector(Parser parser, bool additiveSelector)
{
    local MutableText           macroName;
    local Parser.ParserState    confirmedState;

    if (parser == none) return;
    if (!parser.Ok())   return;

    confirmedState = parser.GetCurrentState();
    macroName = ParseLiteral(parser);
    if (!parser.Ok())
    {
        _.memory.Free(macroName);
        return;
    }
    if (additiveSelector) {
        AddByMacro(macroName);
    }
    else {
        RemoveByMacro(macroName);
    }
    _.memory.Free(macroName);
}

//  Parse name selector, while accordingly modifying current player
//  selection list.
private final function ParseNameSelector(Parser parser, bool additiveSelector)
{
    local MutableText           playerName;
    local Parser.ParserState    confirmedState;

    if (parser == none) return;
    if (!parser.Ok())   return;

    confirmedState = parser.GetCurrentState();
    playerName = ParseLiteral(parser);
    if (!parser.Ok() || playerName.IsEmpty())
    {
        _.memory.Free(playerName);
        return;
    }
    if (additiveSelector) {
        AddByName(playerName);
    }
    else {
        RemoveByName(playerName);
    }
    _.memory.Free(playerName);
}

//      Reads a string that can either be a body of name selector
//  (some player's name prefix) or of a macro selector (what comes after "@").
//      This is different from `parser.MString()` because it also uses
//  "," as a separator.
private final function MutableText ParseLiteral(Parser parser)
{
    local MutableText           literal;
    local Parser.ParserState    confirmedState;

    if (parser == none) return none;
    if (!parser.Ok())   return none;

    confirmedState = parser.GetCurrentState();
    if (!parser.MStringLiteral(literal).Ok())
    {
        parser.RestoreState(confirmedState);
        parser.MUntilMany(literal, selectorDelimiters, true);
    }
    return literal;
}

/**
 *  Returns players parsed by the last `ParseWith()` or `Parse()` call.
 *  If neither were yet called - returns an empty array.
 *
 *  @return players parsed by the last `ParseWith()` or `Parse()` call.
 */
public final function array<EPlayer> GetPlayers()
{
    local int               i;
    local array<EPlayer>    result;

    for (i = 0; i < currentSelection.length; i += 1)
    {
        if (currentSelection[i].IsExistent()) {
            result[result.length] = EPlayer(currentSelection[i].Copy());
        }
    }
    return result;
}

/**
 *  Parses players from `parser` according to the currently present players.
 *
 *  Array of parsed players can be retrieved by `self.GetPlayers()` method.
 *
 *  @param  parser  `Parser` from which to parse player list.
 *      It's state will be set to failed in case the parsing fails.
 *  @return `true` if parsing was successful and `false` otherwise.
 */
public final function bool ParseWith(Parser parser)
{
    local Parser.ParserState confirmedState;

    if (parser == none)         return false;
    if (!parser.Ok())           return false;
    if (parser.HasFinished())   return false;

    Reset();
    confirmedState = parser.Skip().GetCurrentState();
    if (!parser.Match(T(TOPEN_BRACKET)).Ok())
    {
        ParseSelector(parser.RestoreState(confirmedState));
        if (parser.Ok()) {
            return true;
        }
        return false;
    }
    while (parser.Ok() && !parser.HasFinished())
    {
        confirmedState = parser.Skip().GetCurrentState();
        if (parser.Match(T(TCLOSE_BRACKET)).Ok()) {
            return true;
        }
        parser.RestoreState(confirmedState);
        if (parsedFirstSelector) {
            parser.Match(T(TCOMMA)).Skip();
        }
        ParseSelector(parser);
        parser.Skip();
    }
    parser.Fail();
    return false;
}

//  Resets this object to initial state before parsing and update
//  `playersSnapshot` to contain current players. 
private final function Reset()
{
    parsedFirstSelector     = false;
    currentSelection.length = 0;
    _.memory.FreeMany(playersSnapshot);
    playersSnapshot.length  = 0;
    playersSnapshot = _.players.GetAll();
    selectorDelimiters.length = 0;
    selectorDelimiters[0] = T(TCOMMA);
    selectorDelimiters[1] = T(TCLOSE_BRACKET);
}

/**
 *  Parses players from `toParse` according to the currently present players.
 *
 *  Array of parsed players can be retrieved by `self.GetPlayers()` method.
 *
 *  @param  toParse `Text` from which to parse player list.
 *  @return `true` if parsing was successful and `false` otherwise.
 */
public final function bool Parse(BaseText toParse)
{
    local bool      wasSuccessful;
    local Parser    parser;

    if (toParse == none) {
        return false;
    }
    parser = _.text.Parse(toParse);
    wasSuccessful = ParseWith(parser);
    parser.FreeSelf();
    return wasSuccessful;
}

defaultproperties
{
    TSELF           = 0
    stringConstants(0) = "self"
    TADMIN          = 1
    stringConstants(1) = "admin"
    TALL            = 2
    stringConstants(2) = "all"
    TNOT            = 3
    stringConstants(3) = "!"
    TKEY            = 4
    stringConstants(4) = "#"
    TMACRO          = 5
    stringConstants(5) = "@"
    TCOMMA          = 6
    stringConstants(6) = ","
    TOPEN_BRACKET   = 7
    stringConstants(7)  = "["
    TCLOSE_BRACKET  = 8
    stringConstants(8)  = "]"
    TME                 = 9
    stringConstants(9) = "me"
}