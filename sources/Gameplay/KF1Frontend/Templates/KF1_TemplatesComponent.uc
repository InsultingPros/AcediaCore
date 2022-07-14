/**
 *  `ATemplatesComponent`'s implementation for `KF1_Frontend`.
 *  Lists weapons available at the trader, provides support for per-perk lists,
 *  derived from the `KFLevelRules`.
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
class KF1_TemplatesComponent extends ATemplatesComponent;

var private bool listsAreReady;
var private array<Text> availableWeaponLists;
var private array<Text> allWeaponsList;
var private array<Text> medicWeaponsList;
var private array<Text> supportWeaponsList;
var private array<Text> sharpshooterWeaponsList;
var private array<Text> commandoWeaponsList;
var private array<Text> berserkerWeaponsList;
var private array<Text> firebugWeaponsList;
var private array<Text> demolitionWeaponsList;
var private array<Text> neutralWeaponsList;
var private array<Text> toolWeaponsList;

protected function Finalizer()
{
    _.memory.FreeMany(allWeaponsList);
    _.memory.FreeMany(medicWeaponsList);
    _.memory.FreeMany(supportWeaponsList);
    _.memory.FreeMany(sharpshooterWeaponsList);
    _.memory.FreeMany(commandoWeaponsList);
    _.memory.FreeMany(berserkerWeaponsList);
    _.memory.FreeMany(firebugWeaponsList);
    _.memory.FreeMany(demolitionWeaponsList);
    _.memory.FreeMany(neutralWeaponsList);
    _.memory.FreeMany(toolWeaponsList);
    _.memory.FreeMany(availableWeaponLists);
    if (allWeaponsList.length > 0) {
        allWeaponsList.length = 0;
    }
    if (medicWeaponsList.length > 0) {
        medicWeaponsList.length = 0;
    }
    if (supportWeaponsList.length > 0) {
        supportWeaponsList.length = 0;
    }
    if (sharpshooterWeaponsList.length > 0) {
        sharpshooterWeaponsList.length = 0;
    }
    if (commandoWeaponsList.length > 0) {
        commandoWeaponsList.length = 0;
    }
    if (berserkerWeaponsList.length > 0) {
        berserkerWeaponsList.length = 0;
    }
    if (firebugWeaponsList.length > 0) {
        firebugWeaponsList.length = 0;
    }
    if (demolitionWeaponsList.length > 0) {
        demolitionWeaponsList.length = 0;
    }
    if (neutralWeaponsList.length > 0) {
        neutralWeaponsList.length = 0;
    }
    if (availableWeaponLists.length > 0) {
        availableWeaponLists.length = 0;
    }
    if (toolWeaponsList.length > 0) {
        toolWeaponsList.length = 0;
    }
    listsAreReady = false;
}

private function BuildKFWeaponLists()
{
    local LevelInfo     level;
    local KFLevelRules  kfLevelRules;
    if (listsAreReady)          return;
    level = _server.unreal.GetLevel();
    if (level == none)          return;
    foreach level.DynamicActors(class'KFMod.KFLevelRules', kfLevelRules) break;
    if (kfLevelRules == none)   return;

    medicWeaponsList        = MakeWeaponList(kfLevelRules.mediItemForSale);
    supportWeaponsList      = MakeWeaponList(kfLevelRules.suppItemForSale);
    sharpshooterWeaponsList = MakeWeaponList(kfLevelRules.shrpItemForSale);
    commandoWeaponsList     = MakeWeaponList(kfLevelRules.commItemForSale);
    berserkerWeaponsList    = MakeWeaponList(kfLevelRules.bersItemForSale);
    firebugWeaponsList      = MakeWeaponList(kfLevelRules.fireItemForSale);
    demolitionWeaponsList   = MakeWeaponList(kfLevelRules.demoItemForSale);
    neutralWeaponsList      = MakeWeaponList(kfLevelRules.neutItemForSale);
    toolWeaponsList[0]      = _.text.FromString("kfmod.syringe");
    toolWeaponsList[1]      = _.text.FromString("kfmod.welder");
    availableWeaponLists[0]     = _.text.FromString("all weapons");
    availableWeaponLists[1]     = _.text.FromString("trading weapons");
    availableWeaponLists[2]     = _.text.FromString("medic weapons");
    availableWeaponLists[3]     = _.text.FromString("support weapons");
    availableWeaponLists[4]     = _.text.FromString("sharpshooter weapons");
    availableWeaponLists[5]     = _.text.FromString("commando weapons");
    availableWeaponLists[6]     = _.text.FromString("berserk weapons");
    availableWeaponLists[7]     = _.text.FromString("firebug weapons");
    availableWeaponLists[8]     = _.text.FromString("demolition weapons");
    availableWeaponLists[9]     = _.text.FromString("tools");
    availableWeaponLists[10]    = _.text.FromString("neutral weapons");
    listsAreReady = true;
}

private function array<Text> MakeWeaponList(array< class<Pickup> > shopList)
{
    local int           i;
    local Text          nextTemplate;
    local class<Weapon> nextWeaponClass;
    local array<Text>   resultArray;
    if (listsAreReady) {
        return resultArray;
    }
    for (i = 0; i < shopList.length; i += 1)
    {
        if (shopList[i] == none)        continue;
        nextWeaponClass = class<Weapon>(shopList[i].default.inventoryType);
        if (nextWeaponClass == none)    continue;
    
        nextTemplate = _.text.FromString(string(nextWeaponClass));
        resultArray[resultArray.length] = nextTemplate.Copy();
        allWeaponsList[allWeaponsList.length] = nextTemplate;
    }
    return resultArray;
}

private function array<Text> CopyList(array<Text> inputList)
{
    local int i;
    local array<Text> outputList;
    //  `inputList` is guaranteed to not contain invalid `Text` objects
    for (i = 0; i < inputList.length; i += 1) {
        outputList[outputList.length] = inputList[i].Copy();
    }
    return outputList;
}

public function bool ItemListExists(BaseText listName)
{
    local string listNameAsString;
    if (listName == none) return false;
    listNameAsString = listName.ToString();
    if (listNameAsString == "weapons")              return true;
    if (listNameAsString == "all weapons")          return true;
    if (listNameAsString == "trading weapons")      return true;
    if (listNameAsString == "medic weapons")        return true;
    if (listNameAsString == "support weapons")      return true;
    if (listNameAsString == "sharpshooter weapons") return true;
    if (listNameAsString == "commando weapons")     return true;
    if (listNameAsString == "berserker weapons")    return true;
    if (listNameAsString == "firebug weapons")      return true;
    if (listNameAsString == "demolition weapons")   return true;
    if (listNameAsString == "tools")                return true;
    if (listNameAsString == "neutral weapons")      return true;

    return false;
}

public function array<Text> GetItemList(BaseText listName)
{
    local string        listNameAsString;
    local array<Text>   emptyArray;
    if (listName == none) {
        return emptyArray;
    }
    listNameAsString = listName.ToString();
    BuildKFWeaponLists();
    if (    listNameAsString == "weapons"
        ||  listNameAsString == "all weapons"
        ||  listNameAsString == "trading weapons")
    {
        return CopyList(allWeaponsList);
    }
    if (listNameAsString == "medic weapons") {
        return CopyList(medicWeaponsList);
    }
    if (listNameAsString == "support weapons") {
        return CopyList(supportWeaponsList);
    }
    if (listNameAsString == "sharpshooter weapons") {
        return CopyList(sharpshooterWeaponsList);
    }
    if (listNameAsString == "commando weapons") {
        return CopyList(commandoWeaponsList);
    }
    if (listNameAsString == "berserker weapons") {
        return CopyList(berserkerWeaponsList);
    }
    if (listNameAsString == "firebug weapons") {
        return CopyList(firebugWeaponsList);
    }
    if (listNameAsString == "demolition weapons") {
        return CopyList(demolitionWeaponsList);
    }
    if (listNameAsString == "tools") {
        return CopyList(toolWeaponsList);
    }
    if (listNameAsString == "neutral weapons") {
        return CopyList(neutralWeaponsList);
    }
    return emptyArray;
}

public function array<Text> GetAvailableLists()
{
    BuildKFWeaponLists();
    return CopyList(availableWeaponLists);
}

defaultproperties
{
}