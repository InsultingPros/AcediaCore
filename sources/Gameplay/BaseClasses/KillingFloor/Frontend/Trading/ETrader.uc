/**
 *      Class, objects of which are expected to represent traders located on
 *  the map. In classic KF game mode it would represent areas behind closed
 *  doors that open during trader time and allow to purchase weapons and ammo.
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
class ETrader extends EInterface
    abstract;

/**
 *  Returns location of the trader.
 *
 *      Trader is usually associated with an area where players can trade and
 *  not just one point. Value returned by this method is merely expected to
 *  return position that "makes sense" for the trader.
 *      It can be used to calculate distance and/or path to the trader.
 *
 *  @return Location of the caller trader.
 */
public function Vector GetLocation();

/**
 *  Returns name of the trader.
 *
 *      Trader name can be any non-empty `Text`.
 *      The only requirement is that after map's initialization every trader
 *  should have a unique name. It is not forbidden to break this invariant later
 *  by `SetName()` method.
 *      If `none` or empty name is passed, this method should do nothing.
 *
 *      This is not the hard requirement, but explanation of purpose.
 *      Name does not have to be player-friendly, but it must be human-readable:
 *  it is not expected to be seen by regular players, but admins might use it
 *  to tweak their server.
 *
 *  @return Current name of the trader.
 */
public function Text GetName();

/**
 *  Changes name of the trader.
 *
 *  @see `GetName()` for more details.
 *
 *  @param  newName New name of the caller trader.
 *  @return `true` if trader is currently enabled and `false` otherwise.
 */
public function ETrader SetName(BaseText newName);

/**
 *  Checks if caller trader is currently enabled.
 *
 *  Trader being enabled means that it can be opened and used for trading.
 *  Trader being disabled means that it cannot open for trading.
 *
 *  This should override opened and auto-opened status.
 *
 *  Marking disabled trader as selected is discouraged, especially for classic
 *  KF game mode, but should be allowed.
 *
 *  @return `true` if trader is currently enabled and `false` otherwise.
 */
public function bool IsEnabled();

/**
 *  Sets whether caller `ETrader`'s is currently enabled.
 *
 *  Disabling the trader should automatically "boot" players out
 *  (see `BootPlayers()`).
 *
 *  @see `IsEnabled()` for more info.
 *
 *  @param  doEnable    `true` if trader is currently enabled and
 *      `false` otherwise.
 *  @return Caller `ETrader` to allow for method chaining.
 */
public function ETrader SetEnabled(bool doEnable);

/**
 *  Checks whether caller `ETrader` will auto-open when trading gets activated.
 *
 *  This setting must be ignored if trader is disabled, but disabling `ETrader`
 *  should not reset it.
 *
 *  @return `true` if trader is marked to always auto-open upon activating
 *      trading (unless it is also disabled) and `false` otherwise.
 */
public function bool IsAutoOpen();

/**
 *  Checks whether caller `ETrader` will auto-open when trading gets activated.
 *
 *  @see `IsAutoOpen()` for more info.
 *
 *  @param  doAutoOpen  `true` if trader should be marked to always auto-open
 *      upon activating trading and `false` otherwise.
 *  @return Caller `ETrader` to allow for method chaining.
 */
public function ETrader SetAutoOpen(bool doAutoOpen);

/**
 *  Checks whether caller `ETrader` is currently open.
 *
 *  `ETrader` being open means that players can "enter" (whatever that means for
 *  an implementation) and use `ETrader` to buy/sell equipment.
 *
 *  @return `true` if it is open and `false` otherwise.
 */
public function bool IsOpen();

/**
 *  Changes whether caller `ETrader` is open.
 *
 *  Closing the trader should not automatically "boot" players out
 *  (see `BootPlayers()`).
 *
 *  @see `IsOpen()` for more details.
 *
 *  @param  doOpen  `true` if it is open and `false` otherwise.
 *  @return Caller `ETrader` to allow for method chaining.
 */
public function ETrader SetOpen(bool doOpen);

/**
 *  Checks whether caller `ETrader` is currently marked as selected.
 *
 *  @see `ATradingComponent.GetSelectedTrader()` for more details.
 *
 *  @return `true` if caller `ETrader` is selected and `false` otherwise.
 */
public function bool IsSelected();

/**
 *  Marks caller `ETrader` as a selected trader.
 *
 *  @see `ATradingComponent.GetSelectedTrader()` for more details.
 *
 *  @return Caller `ETrader` to allow for method chaining.
 */
public function ETrader Select();

/**
 *  Removes players from the trader's place.
 *
 *  In classic KF game mode it teleported them right outside the doors.
 *
 *  This method's goal is to make sure players are not stuck in trader's place
 *  after it is closed. If that is impossible (for traders resembling
 *  KF2's one), then this method should do nothing.
 *
 *  @return Caller `ETrader` to allow for method chaining.
 */
public function ETrader BootPlayers();

/**
 *  Shortcut method to open the caller trader, guaranteed to be equivalent to
 *  `SetOpen(true)`. Provided for better interface.
 *
 *  @return Caller `ETrader` to allow for method chaining.
 */
public final function ETrader Open()
{
    SetOpen(true);
    return self;
}

/**
 *  Shortcut method to close the caller trader, guaranteed to be equivalent to
 *  `SetOpen(false)`. Provided for better interface.
 *
 *  @return Caller `ETrader` to allow for method chaining.
 */
public final function ETrader Close()
{
    SetOpen(false);
    return self;
}

defaultproperties
{
}