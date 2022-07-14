/**
 *  `ATradingComponent`'s implementation for `KF1_Frontend`.
 *  Only supports `KF1_Trader` as a possible trader class.
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
class KF1_TradingComponent extends ATradingComponent;

//  Variables for enforcing a trader time pause by repeatedly setting
//  `waveCountDown`'s value to `pausedCountDownValue`
var protected bool  tradingCountDownPaused;
//  Non-negative values mean at what point to freeze time,
//  negative values mean that we should check current trader timer as soon as
//  trading resumes
var protected int   pausedCountDownValue;

//  For detecting events of trading becoming active/inactive and selecting
//  a different trader, to account for these changing through non-Acedia means
var protected bool      wasActiveLastCheck;
var protected ETrader   lastSelectedTrader;

var protected array<ETrader> registeredTraders;

protected function Constructor()
{
    local LevelInfo     level;
    local KFGameType    kfGame;
    local KF1_Trader    nextTrader;
    local ShopVolume    nextShopVolume;
    super.Constructor();
    _server.unreal.OnTick(self).connect = Tick;
    //  Build `registeredTraders` cache to avoid looking through
    //  all actors each time
    level   = __server().unreal.GetLevel();
    kfGame  = __server().unreal.GetKFGameType();
    foreach level.AllActors(class'ShopVolume', nextShopVolume)
    {
        if (nextShopVolume == none) {
            continue;
        }
        if (nextShopVolume.bObjectiveModeOnly && !kfGame.bUsingObjectiveMode) {
            continue;
        }
        nextTrader = KF1_Trader(__().memory.Allocate(class'KF1_Trader'));
        if (nextTrader.Initialize(nextShopVolume)) {
            registeredTraders[registeredTraders.length] = nextTrader;
        }
        else {
            _.memory.Free(nextTrader);
        }
    }
    lastSelectedTrader  = GetSelectedTrader();
    wasActiveLastCheck  = IsTradingActive();
}

protected function Finalizer()
{
    super.Finalizer();
    _server.unreal.OnTick(self).Disconnect();
    _.memory.Free(lastSelectedTrader);
    _.memory.FreeMany(registeredTraders);
    lastSelectedTrader = none;
    registeredTraders.length = 0;
}

public function array<ETrader> GetTraders()
{
    local int               i;
    local array<ETrader>    result;
    for (i = 0; i < registeredTraders.length; i += 1) {
        result[i] = ETrader(registeredTraders[i].Copy());
    }
    return result;
}

public function ETrader GetTrader(BaseText traderName)
{
    local int   i;
    local Text  nextTraderName;
    if (traderName == none) {
        return none;
    }
    for (i = 0; i < registeredTraders.length; i += 1)
    {
        nextTraderName = registeredTraders[i].GetName();
        if (traderName.Compare(nextTraderName))
        {
            _.memory.Free(nextTraderName);
            return ETrader(registeredTraders[i].Copy());
        }
        _.memory.Free(nextTraderName);
    }
    return none;
}

public function bool IsTradingActive()
{
    local KFGameType kfGame;
    kfGame = _server.unreal.GetKFGameType();
    return kfGame.IsInState('MatchInProgress') && !kfGame.bWaveInProgress;
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
    kfGame      = _server.unreal.GetKFGameType();
    kfGameRI    = _server.unreal.GetKFGameRI();
    foreach kfGame.DynamicActors(class'KFMonster', nextZed)
    {
        if (nextZed == none)        continue;
        if (nextZed.health <= 0)    continue;
        nextZed.Suicide();
    }
    kfGame.totalMaxMonsters = 0;
    kfGameRI.maxMonsters = 0;
}

public function ETrader GetSelectedTrader()
{
    local int i;
    for (i = 0; i < registeredTraders.length; i += 1)
    {
        if (registeredTraders[i].IsSelected()) {
            return ETrader(registeredTraders[i].Copy());
        }
    }
    return none;
}

public function SelectTrader(ETrader newSelection)
{
    local bool                  traderChanged;
    local ETrader               oldSelection;
    local KFGameReplicationInfo kfGameRI;
    if (newSelection != none) {
        newSelection.Select();
    }
    else
    {
        kfGameRI = _server.unreal.GetKFGameRI();
        if (kfGameRI != none) {
            kfGameRI.currentShop = none;
        }
    }
    //  Emit signal, but first record new trader inside `lastSelectedTrader`
    //  in case someone decides it would be a grand idea to call `SelectTrader`
    //  during `onTraderSelectSignal` signal.
    oldSelection = lastSelectedTrader;
    if (newSelection != none)
    {
        lastSelectedTrader = ETrader(newSelection.Copy());
        traderChanged = !lastSelectedTrader.SameAs(oldSelection);
    }
    else
    {
        lastSelectedTrader = none;
        traderChanged = (oldSelection != none);
    }
    if (traderChanged) {
        onTraderSelectSignal.Emit(oldSelection, newSelection);
    }
    _.memory.Free(oldSelection);
}

public function int GetTradingInterval()
{
    return _server.unreal.GetKFGameType().timeBetweenWaves;
}

public function SetTradingInterval(int newTradingInterval)
{
    if (newTradingInterval > 0) {
        _server.unreal.GetKFGameType().timeBetweenWaves = Max(newTradingInterval, 1);
    }
}

public function int GetCountDown()
{
    if (!IsTradingActive()) {
        return 0;
    }
    return _server.unreal.GetKFGameType().waveCountDown;
}

public function SetCountDown(int newCountDownValue)
{
    local KFGameType kfGame;
    if (!IsTradingActive()) {
        return;
    }
    kfGame = _server.unreal.GetKFGameType();
    if (kfGame.waveCountDown >= 5 && newCountDownValue < 5) {
        _server.unreal.GetKFGameRI().waveNumber = kfGame.waveNum;
    }
    kfGame.waveCountDown = Max(newCountDownValue, 1);
    pausedCountDownValue = newCountDownValue;
}

public function bool IsCountDownPaused()
{
    return tradingCountDownPaused;
}

public function SetCountDownPause(bool doPause)
{
    if (tradingCountDownPaused == doPause) {
        return;
    }
    tradingCountDownPaused = doPause;
    if (doPause) {
        if (IsTradingActive()) {
            //  `+1` makes client counter stop closer to the moment
            //  `SetCountDownPause()` was called
            pausedCountDownValue =
                _server.unreal.GetKFGameType().waveCountDown + 1;
        }
        else {
            //  If trading time isn't active, then we do not yet know how long
            //  trading time will last (it can be changed during the wave),
            //  so set it to negative until we find out
            pausedCountDownValue = -1;
        }
    }
    //  These values are problematic because `KFGameType` either plays a message
    //  or updates its state during these
    if (    pausedCountDownValue == 30
        ||  pausedCountDownValue == 10
        ||  pausedCountDownValue == 5)
    {
        pausedCountDownValue -= 1;
    }
    //  Also a special value (ends wave), but decreasing it will simply
    //  end trading time
    if (pausedCountDownValue == 1) {
        pausedCountDownValue = 2;
    }
}

protected function Tick(float delta, float timeScaleCoefficient)
{
    local bool isActiveNow;
    //  Selected trader check
    CheckNativeTraderSwap();
    //  Active status check
    isActiveNow = IsTradingActive();
    if (wasActiveLastCheck != isActiveNow)
    {
        wasActiveLastCheck = isActiveNow;
        if (isActiveNow) {
            onStartSignal.Emit();
        }
        else
        {
            onEndSignal.Emit();
            //  Reset pause after trading time has ended
            tradingCountDownPaused = false;
        }
    }
    //  Enforce pause
    //  Do this *after* check if `tradingCountDownPaused` should be reset
    if (isActiveNow && tradingCountDownPaused)
    {
        if (pausedCountDownValue >= 0) {
            _server.unreal.GetKFGameType().waveCountDown = pausedCountDownValue;
        }
        else {
            pausedCountDownValue = _server.unreal.GetKFGameType().waveCountDown;
        }
    }
}

//  Detect when selected trader is swapped be swapped by non-Acedia means
protected function CheckNativeTraderSwap()
{
    local ETrader newSelectedTrader;
    if (    lastSelectedTrader == none
        &&  _server.unreal.GetKFGameRI().currentShop == none) {
        return;
    }
    if (lastSelectedTrader != none && lastSelectedTrader.IsSelected()) {
        return;
    }
    //  Currently selected trader actually differs from `lastSelectedTrader`
    newSelectedTrader = GetSelectedTrader();
    onTraderSelectSignal.Emit(lastSelectedTrader, newSelectedTrader);
    _.memory.Free(lastSelectedTrader);
    lastSelectedTrader = newSelectedTrader;
}

defaultproperties
{
}