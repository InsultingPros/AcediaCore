/**
 *  Class for an object that will provide an access to a Acedia's functionality
 *  by giving a reference to this object to all Acedia's objects and actors,
 *  emulating a global API namespace.
 *      Copyright 2020 - 2021 Anton Tarasenko
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
class Global extends Object;

//  `Global` is expected to behave like a singleton and will store it's
//  main instance in this variable's default value.
var protected Global myself;

var public RefAPI           ref;
var public BoxAPI           box;
var public LoggerAPI        logger;
var public CollectionsAPI   collections;
var public UnrealAPI        unreal;
var public TimeAPI          time;
var public AliasesAPI       alias;
var public TextAPI          text;
var public MemoryAPI        memory;
var public ConsoleAPI       console;
var public ColorAPI         color;
var public UserAPI          users;
var public PlayersAPI       players;
var public JSONAPI          json;

public final static function Global GetInstance()
{
    if (default.myself == none) {
        //  `Global` is special and exists outside main Acedia's
        //  object infrastructure, so we allocate it without using API methods.
        default.myself = new class'Global';
        default.myself.Initialize();
    }
    return default.myself;
}

protected function Initialize()
{
    //  Special case that we cannot spawn with memory API since it obviously
    //  does not exist yet!
    memory      = new class'MemoryAPI';
    //  `TextAPI` and `CollectionsAPI` need to be loaded before `LoggerAPI`
    ref         = RefAPI(memory.Allocate(class'RefAPI'));
    box         = BoxAPI(memory.Allocate(class'BoxAPI'));
    text        = TextAPI(memory.Allocate(class'TextAPI'));
    collections = CollectionsAPI(memory.Allocate(class'CollectionsAPI'));
    unreal      = UnrealAPI(memory.Allocate(class'UnrealAPI'));
    time        = TimeAPI(memory.Allocate(class'TimeAPI'));
    logger      = LoggerAPI(memory.Allocate(class'LoggerAPI'));
    alias       = AliasesAPI(memory.Allocate(class'AliasesAPI'));
    console     = ConsoleAPI(memory.Allocate(class'ConsoleAPI'));
    color       = ColorAPI(memory.Allocate(class'ColorAPI'));
    users       = UserAPI(memory.Allocate(class'UserAPI'));
    players     = PlayersAPI(memory.Allocate(class'PlayersAPI'));
    json        = JSONAPI(memory.Allocate(class'JSONAPI'));
    json.StaticConstructor();
}