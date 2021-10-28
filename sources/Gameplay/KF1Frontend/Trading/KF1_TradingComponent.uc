/**
 *  `ATradingComponent`'s implementation for `KF1_Frontend`.
 *  Only supports `KF1_Trader` as a possible trader class.
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
class KF1_TradingComponent extends ATradingComponent;

//  Variables for enforcing a trader time pause by repeatedly setting
//  `waveCountDown`'s value to `pausedCountDownValue`
var protected bool  tradingCountDownPaused;
var protected int   pausedCountDownValue;

//  For detecting events of trading becoming active/inactive and selecting
//  a different trader, to account for these changing through non-Acedia means
var protected bool      wasActiveLastCheck;
var protected Atrader   lastSelectedTrader;

//  All known traders on map
var protected array<ATrader> registeredTraders;

protected function Constructor()
{
    super.Constructor();
    _.unreal.OnTick(self).connect = Tick;
    registeredTraders   = class'KF1_Trader'.static.WrapVanillaShops();
    lastSelectedTrader  = GetSelectedTrader();
    wasActiveLastCheck  = IsTradingActive();
}

protected function Finalizer()
{
    super.Finalizer();
    _.unreal.OnTick(self).Disconnect();
    _.memory.Free(lastSelectedTrader);
    _.memory.FreeMany(registeredTraders);
    lastSelectedTrader = none;
    registeredTraders.length = 0;
}

public function array<ATrader> GetTraders()
{
    return registeredTraders;
}

public function bool IsTradingActive()
{
    local KFGameType kfGame;
    kfGame = _.unreal.GetKFGameType();
    return kfGame.IsInState('MatchInProgress') && kfGame.bTradingDoorsOpen;
}

public function SetTradingStatus(bool makeActive)
{
    local bool                  isCurrentlyActive;
    local KFGameType            kfGame;
    local KFGameReplicationInfo kfGameRI;
    local KFMonster             nextZed;
    isCurrentlyActive = IsTradingActive();
    if (isCurrentlyActive == makeActive) {
        return;
    }
    if (!makeActive && isCurrentlyActive)
    {
        SetCountDown(0);
        return;
    }
    kfGame      = _.unreal.GetKFGameType();
    kfGameRI    = _.unreal.GetKFGameRI();
    foreach kfGame.DynamicActors(class'KFMonster', nextZed)
    {
        if (nextZed == none)        continue;
        if (nextZed.health <= 0)    continue;
        nextZed.Suicide();
    }
    kfGame.totalMaxMonsters = 0;
    kfGameRI.maxMonsters = 0;
}

public function ATrader GetSelectedTrader()
{
    local int i;
    for (i = 0; i < registeredTraders.length; i += 1)
    {
        if (registeredTraders[i].IsSelected()) {
            return registeredTraders[i];
        }
    }
    return none;
}

public function SelectTrader(ATrader newSelection)
{
    local ATrader               oldSelection;
    local KFGameReplicationInfo kfGameRI;
    if (newSelection != none) {
        newSelection.Select();
    }
    else
    {
        kfGameRI = _.unreal.GetKFGameRI();
        if (kfGameRI != none) {
            kfGameRI.currentShop = none;
        }
    }
    //  Emit signal, but first record new trader inside `lastSelectedTrader`
    //  in case someone decides it would be a grand idea to call `SelectTrader`
    //  during `onTraderSelectSignal` signal.
    oldSelection = lastSelectedTrader;
    lastSelectedTrader = newSelection;
    if (lastSelectedTrader != newSelection) {
        onTraderSelectSignal.Emit(oldSelection, newSelection);
    }
}

public function int GetTradingInterval()
{
    return _.unreal.GetKFGameType().timeBetweenWaves;
}

public function SetTradingInterval(int newTradingInterval)
{
    if (newTradingInterval > 0) {
        _.unreal.GetKFGameType().timeBetweenWaves = Max(newTradingInterval, 1);
    }
}

public function int GetCountDown()
{
    if (!IsTradingActive()) {
        return 0;
    }
    return _.unreal.GetKFGameType().waveCountDown;
}

public function SetCountDown(int newCountDownValue)
{
    local KFGameType kfGame;
    if (!IsTradingActive()) {
        return;
    }
    kfGame = _.unreal.GetKFGameType();
    if (kfGame.waveCountDown >= 5 && newCountDownValue < 5) {
        _.unreal.GetKFGameRI().waveNumber = kfGame.waveNum;
    }
    kfGame.waveCountDown = Max(newCountDownValue, 1);
    pausedCountDownValue = newCountDownValue;
}

public function bool IsCountDownPaused()
{
    if (!IsTradingActive()) {
        return false;
    }
    return tradingCountDownPaused;
}

public function SetCountDownPause(bool doPause)
{
    tradingCountDownPaused  = doPause;
    if (doPause) {
        pausedCountDownValue = _.unreal.GetKFGameType().waveCountDown;
    }
}

protected function Tick(float delta, float timeScaleCoefficient)
{
    local bool      isActiveNow;
    local ATrader   newSelectedTrader;
    //  Enforce pause
    if (tradingCountDownPaused) {
        _.unreal.GetKFGameType().waveCountDown = pausedCountDownValue;
    }
    //  Selected trader check
    newSelectedTrader = GetSelectedTrader();
    if (lastSelectedTrader != newSelectedTrader)
    {
        onTraderSelectSignal.Emit(lastSelectedTrader, newSelectedTrader);
        lastSelectedTrader = newSelectedTrader;
    }
    //  Active status check
    isActiveNow = IsTradingActive();
    if (wasActiveLastCheck != isActiveNow)
    {
        wasActiveLastCheck = isActiveNow;
        if (isActiveNow)
        {
            onStartSignal.Emit();
        }
        else
        {
            onEndSignal.Emit();
            //  Reset pause after trading time has ended
            tradingCountDownPaused = false;
        }
    }
}

defaultproperties
{
}