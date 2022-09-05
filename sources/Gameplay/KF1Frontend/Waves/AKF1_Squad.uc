/**
 *  `ASquad`'s implementation for `KF1_Frontend`.
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
class AKF1_Squad extends ASquad;

struct KF1_ZedCountPair
{
    var class<KFMonster>    zedClass;
    var int                 count;
};
var array<KF1_ZedCountPair> squadZeds;

protected function Finalizer()
{
    Reset();
}

public function Reset()
{
    squadZeds.length = 0;
}

public function ChangeCount(BaseText template, int delta)
{
    local int               pairIndex;
    local class<KFMonster>  templateClass;

    templateClass = class<KFMonster>(_.memory.LoadClass(template));
    if (templateClass == none) {
        return;
    }
    pairIndex = FindPairIndex(templateClass, true);
    squadZeds[pairIndex].count += delta;
    if (squadZeds[pairIndex].count <= 0) {
        squadZeds.Remove(pairIndex, 1);
    }
}

private function int FindPairIndex(
    class<KFMonster>    zedClass,
    optional bool       createIfMissing)
{
    local int               i;
    local KF1_ZedCountPair  newPair;

    for (i = 0; i < squadZeds.length; i += 1)
    {
        if (squadZeds[i].zedClass == zedClass) {
            return i;
        }
    }
    if (createIfMissing)
    {
        newPair.zedClass = zedClass;
        squadZeds[squadZeds.length] = newPair;
        return (squadZeds.length - 1);
    }
    return -1;
}

public function AddFromDefinition(BaseText definition)
{
    local int           index, nextCount;
    local Text          nextTemplate;
    local MutableText   numericPart, idPart;
    local BaseText.Character nextCharacter;

    if (definition == none) {
        return;
    }
    while (index < definition.GetLength())
    {
        numericPart = _.text.Empty();
        idPart      = _.text.Empty();
        nextCharacter = definition.GetCharacter(index);
        while ( index < definition.GetLength()
            &&  _.text.IsDigit(nextCharacter))
        {
            numericPart.AppendCharacter(nextCharacter);
            index += 1;
            nextCharacter = definition.GetCharacter(index);
        }
        while ( index < definition.GetLength()
            &&  _.text.IsDigit(nextCharacter))
        {
            idPart.AppendCharacter(nextCharacter);
            index += 1;
            nextCharacter = definition.GetCharacter(index);
        }
        nextTemplate = ReadTemplateFromZedID(idPart);
        nextCount = int(numericPart.ToString());
        ChangeCount(nextTemplate, nextCount);
        _.memory.Free(nextTemplate);
        _.memory.Free(idPart);
        _.memory.Free(numericPart);
    }
}

private function Text ReadTemplateFromZedID(BaseText zedID)
{
    local Text result;

    if (zedID == none) {
        return none;
    }
    result = _.alias.ResolveEntity(zedID);
    if (result == none) {
        result = TryLoadingFromMID(zedID);
    }
    return result; 
}

private function Text TryLoadingFromMID(BaseText zedID)
{
    if (_server.unreal.GetKFGameType().kfGameLength != 3) { // `GL_Custom == 3`
        return TryLoadingFromMID_Collection(zedId);
    }
    return TryLoadingFromMID_GameType(zedId);
}

//  Assumes `zedID != none`.
private function Text TryLoadingFromMID_Collection(BaseText zedID)
{
    local int       i;
    local string    zedIDasString;
    local array<KFMonstersCollection.MClassTypes> monsterClasses;

    zedIDasString = zedID.ToString();
    if (zedIDasString == "") {
        return none;
    }
    monsterClasses = _server.unreal
        .GetKFGameType()
        .monsterCollection.default.monsterClasses;
    for (i = 0; i < monsterClasses.Length; i += 1)
    {
        if (monsterClasses[i].mid == zedIDasString) {
            return _.text.FromString(monsterClasses[i].mClassName);
        }
    }
    return none;
}

//  Assumes `zedID != none`.
private function Text TryLoadingFromMID_GameType(BaseText zedID)
{
    local int       i;
    local string    zedIDasString;
    local array<KFGameType.MClassTypes> monsterClasses;

    zedIDasString = zedID.ToString();
    if (zedIDasString == "") {
        return none;
    }
    monsterClasses = _server.unreal
        .GetKFGameType()
        .monsterClasses;
    for (i = 0; i < monsterClasses.Length; i += 1)
    {
        if (monsterClasses[i].mid == zedIDasString) {
            return _.text.FromString(monsterClasses[i].mClassName);
        }
    }
    return none;
}

/**
 *  Returns list of zeds inside caller squad in a native for KF1 format:
 *  as pairs of `class<KFMonster>` and their counts.
 *
 *  @return Array of pairs `class<KFMonster>` and corresponding zed count inside
 *      a squad. Guaranteed that there cannot be two array elements with
 *      the same class.
 */
public function array<KF1_ZedCountPair> GetNativeZedList()
{
    return squadZeds;
}

public function array<ZedCountPair> GetZedList()
{
    local int                   i;
    local ZedCountPair          nextPair;
    local array<ZedCountPair>   result;

    for (i = 0; i < squadZeds.length; i += 1)
    {
        nextPair.template   = _.text.FromClass(squadZeds[i].zedClass);
        nextPair.count      = squadZeds[i].count;
        result[result.length] = nextPair;
    }
    return result;
}

public function int GetZedCount(BaseText template)
{
    local int               pairIndex;
    local class<KFMonster>  templateClass;

    templateClass = class<KFMonster>(_.memory.LoadClass(template));
    pairIndex = FIndPairIndex(templateClass);
    if (pairIndex < 0) {
        return 0;
    }
    return squadZeds[pairIndex].count;
}

public function int GetTotalZedCount()
{
    local int i;
    local int totalCount;

    for (i = 0; i < squadZeds.length; i += 1) {
        totalCount += squadZeds[i].count;
    }
    return totalCount;
}

defaultproperties
{
}