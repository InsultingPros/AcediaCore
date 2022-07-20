/**
 *  Acedia's default implementation for `ClientUnrealAPI.
 *      Copyright 2021-2022 Anton Tarasenko
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
class KF1_ClientUnrealAPI extends ClientUnrealAPI;

var private LoggerAPI.Definition fatalNoStalker;

/* SIGNAL */
public function Unreal_OnTick_Slot OnTick(AcediaObject receiver)
{
    local AcediaInteraction acediaInteraction;

    //  Simple redirect to `AcediaInteraction`
    acediaInteraction = class'AcediaInteraction'.static.GetInstance();
    if (acediaInteraction != none) {
        return acediaInteraction.OnTick(receiver);
    }
    return none;
}

/* SIGNAL */
public function SimpleSlot OnDestructionFor(
    AcediaObject    receiver,
    Actor           targetToStalk)
{
    local ActorStalker stalker;

    if (receiver == none)       return none;
    if (targetToStalk == none)  return none;

    //  Failing to spawn this actor without any collision flags is considered
    //  completely unexpected and grounds for fatal failure on Acedia' part
    stalker = ActorStalker(class'ClientLevelCore'.static
        .GetInstance()
        .Allocate(class'ActorStalker'));
    if (stalker == none)
    {
        _.logger.Auto(fatalNoStalker);
        return none;
    }
    //  This will not fail, since we have already ensured that
    //  `targetToStalk == none`
    stalker.Initialize(targetToStalk);
    return stalker.OnActorDestruction(receiver);
}

public function LevelInfo GetLevel()
{
    return class'ClientLevelCore'.static.GetInstance().level;
}

public function GameReplicationInfo GetGameRI()
{
    return class'ClientLevelCore'.static.GetInstance().level.GRI;
}

public function KFGameReplicationInfo GetKFGameRI()
{
    return KFGameReplicationInfo(GetGameRI());
}

public function GameInfo GetGameType()
{
    return class'ClientLevelCore'.static.GetInstance().level.game;
}

public function KFGameType GetKFGameType()
{
    return KFGameType(GetGameType());
}

public function Actor FindActorInstance(class<Actor> classToFind)
{
    local Actor     result;
    local LevelCore core;

    core = class'ClientLevelCore'.static.GetInstance();
    foreach core.AllActors(classToFind, result)
    {
        if (result != none) {
            break;
        }
    }
    return result;
}

public function PlayerController GetLocalPlayer()
{
    return class'ClientLevelCore'.static.GetInstance().level
        .GetLocalPlayerController();
}

public function NativeActorRef ActorRef(optional Actor value)
{
    local NativeActorRef ref;

    ref = NativeActorRef(_.memory.Allocate(class'NativeActorRef'));
    ref.Set(value);
    return ref;
}

defaultproperties
{
    fatalNoStalker = (l=LOG_Fatal,m="Cannot spawn `PawnStalker`")
}