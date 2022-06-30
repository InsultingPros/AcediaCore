/**
 *  Subset of functionality for dealing with everything related to traders.
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
class ATradingComponent extends AcediaObject
    abstract;

var protected SimpleSignal              onStartSignal;
var protected SimpleSignal              onEndSignal;
var protected Trading_OnSelect_Signal   onTraderSelectSignal;

protected function Constructor()
{
    onStartSignal   = SimpleSignal(_.memory.Allocate(class'SimpleSignal'));
    onEndSignal     = SimpleSignal(_.memory.Allocate(class'SimpleSignal'));
    onTraderSelectSignal = Trading_OnSelect_Signal(
        _.memory.Allocate(class'Trading_OnSelect_Signal'));
}

protected function Finalizer()
{
    _.memory.Free(onStartSignal);
    _.memory.Free(onEndSignal);
    _.memory.Free(onTraderSelectSignal);
    onStartSignal           = none;
    onEndSignal             = none;
    onTraderSelectSignal    = none;
}

/**
 *  Signal that will be emitted whenever trading time starts.
 *
 *  [Signature]
 *  void <slot>()
 */
/* SIGNAL */
public final function SimpleSlot OnStart(AcediaObject receiver)
{
    return SimpleSlot(onStartSignal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted whenever trading time ends.
 *
 *  [Signature]
 *  void <slot>(ETrader oldTrader, ETrader newTrader)
 *
 *  @param  oldTrader   Trader that was selected before this event.
 *  @param  newTrader   Trader that will be selected after this event.
 */
/* SIGNAL */
public final function SimpleSlot OnEnd(AcediaObject receiver)
{
    return SimpleSlot(onEndSignal.NewSlot(receiver));
}

/**
 *  Signal that will be emitted whenever a new trader is selected.
 *
 *  [Signature]
 *  void <slot>()
 */
/* SIGNAL */
public final function Trading_OnSelect_Slot OnTraderSelected(
    AcediaObject receiver)
{
    return Trading_OnSelect_Slot(onTraderSelectSignal.NewSlot(receiver));
}

/**
 *  Returns array with all existing traders (including disabled once) on
 *  the level.
 *
 *  @return Array of existing traders on the level. Guaranteed to not contain
 *      `none`-references. None of them should be deallocated,
 *      otherwise Acedia's behavior is undefined.
 */
public function array<ETrader> GetTraders();

/**
 *  Returns a trader with a given name `traderName`.
 *  If several traders are assigned the same name - returns any arbitrary one.
 *
 *  @param  traderName  Name of the trader to return. Case-sensitive.
 *  @return `ETrader` with a given `traderName`. `none` if either `traderName`
 *      is `none` or there is no trader with such a name.
 */
public function ETrader GetTrader(BaseText traderName);

/**
 *  Checks whether trading is currently active.
 *
 *      For classic KF game mode it means that it is trader time and one
 *  (or several) traders are open.
 *      This interface does not impose such limitation on trading: it is
 *  allowed to be active at any time, independent of anything else. However
 *  trading should only be permitted while trading is active.
 *
 *  @return `true` if trading is active and `false` otherwise.
 */
public function bool IsTradingActive();

/**
 *  Changes current status of trading.
 *
 *  @see `IsTradingActive()` for more details.
 */
public function SetTradingStatus(bool makeActive);

/**
 *  Returns the amount of time (in seconds) trading period will last for.
 *
 *      For classic KF game mode it refers to how long trader time is
 *  (`60` seconds by default).
 *
 *  @return Amount of time (in seconds) trading period will last for.
 */
public function int GetTradingInterval();

/**
 *  Changes the amount of time (in seconds) trading period will last for.
 *
 *  Changing this setting only affect current round (until the end of the map).
 *
 *      For classic KF game mode it refers to how long trader time is
 *  (`60` seconds by default).
 *
 *  @param  newTradingInterval  New length of the trading period.
 */
public function SetTradingInterval(int newTradingInterval);

/**
 *  Return amount of time remaining in the current trading period.
 *
 *  For classic KF game mode this refers to remaining trading time.
 *
 *  @return Amount of time remaining in the current trading period.
 *      `0` if trading is currently inactive.
 */
public function int GetCountdown();

/**
 *  Changes amount of time remaining in the current trading period.
 *
 *  For classic KF game mode this refers to remaining trading time.
 *
 *  @param  newTradingInterval  New amount of time that should remain in the
 *      current trading period. Values `<= 0` will lead to trading time ending
 *      immediately.
 */
public function SetCountdown(int newTradingInterval);

/**
 *  Checks whether trading countdown was paused.
 *
 *  Pause only affects current trading period and will be reset after
 *  the next starts.
 *
 *  @return `true` if trading countdown was paused and `false` otherwise.
 *      If trading is inactive - returns `false`.
 */
public function bool IsCountdownPaused();

/**
 *  Changes whether trading countdown should be paused.
 *
 *  Pause set by this method only affects current trading period and will be
 *  reset after the next starts.
 *
 *  @return doPause `true` to pause trading countdown and `false` to resume.
 *      If trading time is currently inactive - does nothing.
 */
public function SetCountdownPause(bool doPause);

/**
 *  Returns currently selected trader.
 *
 *      For classing KF game mode selected trader means the trader currently
 *  pointed at by the arrow in the top left corner on HUD and by the red wisp
 *  during trading time.
 *      This interface allows to generalize the concept of select trader to any
 *  specially marked trader or even not make use of it at all.
 *      Changing a selected trader in any way should always be followed
 *  by emitting `OnTraderSelected()` signal.
 *      After `SelectTrader()` call `GetSelectedTrader()` should return
 *  specified `ETrader`. If selected trader changes in some other way, it should
 *  first result in emitted `OnTraderSelected()` signal.
 *
 *  @return Currently selected trader.
 */
public function ETrader GetSelectedTrader();

/**
 *  Changes currently selected trader.
 *
 *  @see `GetSelectedTrader()` for more details.
 */
public function SelectTrader(ETrader newSelection);

defaultproperties
{
}