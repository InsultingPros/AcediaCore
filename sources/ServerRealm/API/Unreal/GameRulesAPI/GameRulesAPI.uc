/**
 *      Low-level API that provides set of utility methods for working with
 *  `GameRule`s.
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
class GameRulesAPI extends AcediaObject
    abstract;

/**
 *  Called when game decides on a player's spawn point. If a `NavigationPoint`
 *  is returned, signal propagation will be interrupted and returned value will
 *  be used as the player start.
 *
 *  [Signature]
 *  NavigationPoint <slot>(
 *      Controller      player,
 *      optional byte   inTeam,
 *      optional string incomingName)
 *
 *  @param  player          Player for whom we are picking a spawn point.
 *  @param  inTeam          Player's team number.
 *  @param  incomingName    `Portal` parameter from `GameInfo.Login()` event.
 *  @return `NavigationPoint` that will player must be spawned at.
 *      `none` means that slot does not want to modify it.
 */
/* SIGNAL */
public function GameRules_OnFindPlayerStart_Slot OnFindPlayerStart(
    AcediaObject receiver);

/**
 *  Called in `GameInfo`'s `RestartGame()` method and allows to prevent
 *  game's restart.
 *
 *  This signal will always be propagated to all registered slots.
 *
 *  [Signature]
 *  bool <slot>()
 *
 *  @return `true` if you want to prevent game restart and `false` otherwise.
 *      `true` returned by one of the handlers overrides `false` values returned
 *      by others.
 */
/* SIGNAL */
public function GameRules_OnHandleRestartGame_Slot OnHandleRestartGame(
    AcediaObject receiver);

/**
 *  Allows modification of game ending conditions.
 *  Return `false` to prevent game from ending.
 *
 *  This signal will always be propagated to all registered slots.
 *
 *  [Signature]
 *  bool <slot>(PlayerReplicationInfo winner, string reason)
 *
 *  @param  winner  Replication info of the supposed winner of the game.
 *  @param  reason  String with a description about how/why `winner` has won.
 *  @return `false` if you want to prevent game from ending
 *      and `true` otherwise. `false` returned by one of the handlers overrides
 *      `true` values returned by others.
 */
/* SIGNAL */
public function GameRules_OnCheckEndGame_Slot OnCheckEndGame(
    AcediaObject receiver);

/**
 *  Check if this score means the game ends.
 *
 *  Return `true` to override `GameInfo`'s `CheckScore()`, or if game was ended
 *  (with a call to `Level.Game.EndGame()`).
 *
 *  This signal will always be propagated to all registered slots.
 *
 *  [Signature]
 *  bool <slot>(PlayerReplicationInfo scorer)
 *
 *  @param  scorer  For whom to do a score check.
 *  @return `true` to override `GameInfo`'s `CheckScore()`, or if game was ended
 *      and `false` otherwise. `true` returned by one of the handlers overrides
 *      `false` values returned by others.
 */
/* SIGNAL */
public function GameRules_OnCheckScore_Slot OnCheckScore(
    AcediaObject receiver);

/**
 *      When pawn wants to pick something up, `GameRule`s are given a chance to
 *  modify it. If one of the `Slot`s returns `true`, `allowPickup` will
 *  determine if the object can be picked up.
 *      Overriding via this method allows to completely bypass check against
 *  `Pawn`'s inventory's `HandlePickupQuery()` method.
 *
 *  [Signature]
 *  bool <slot>(Pawn other, Pickup item, out byte allowPickup)
 *
 *  @param  other       Pawn which will potentially pickup `item`.
 *  @param  item        Pickup which `other` might potentially pickup.
 *  @param  allowPickup `true` if you want to force `other` to pickup an item
 *      and `false` otherwise. This parameter is ignored if returned value of
 *      your slot call is `false`.
 *  @return `true` if you wish to override decision about pickup with
 *      `allowPickup` and `false` if you do not want to make that decision.
 *      If you do decide to override decision by returning `true` - this signal
 *      will not be propagated to the rest of the slots.
 */
/* SIGNAL */
public function GameRules_OnOverridePickupQuery_Slot
    OnOverridePickupQuery(AcediaObject receiver);

/**
 *      When pawn gets damaged, `GameRule`s are given a chance to modify that
 *  damage.
 *
 *  [Signature]
 *  int <slot>(
 *      int                 originalDamage,
 *      int                 damage,
 *      Pawn                injured,
 *      Pawn                instigatedBy,
 *      Vector              hitLocation,
 *      out Vector          momentum,
 *      class<DamageType>   damageType)
 *
 *  @param  originalDamage  Damage that was originally meant to be dealt to
 *      the `Pawn`, before any of th `GameRules`' modifications.
 *  @param  damage          Damage value to be dealt to the `Pawn` as it was
 *      modified so fat by other `GameRules` and `OnNetDamage()`'s handlers.
 *  @param  injured         `Pawn` that will be dealt damage in question.
 *  @param  instigatedBy    `Pawn` that deals this damage.
 *  @param  hitLocation     "Location of the damage", e.g. place where `injured`
 *      was hit by a bullet.
 *  @param  momentum        Momentum that this damage source should inflict on
 *      the `injured`. Can also be modified.
 *  @param  damageType      Type of the damage that will be dealt to
 *      the `injured`.
 *  @return Damage value you want to be dealt to the `injured` instead of
 *      `damage`, given all of  he above parameters. Note that it can be further
 *      modified by other handlers or `GameRules`.
 */
/* SIGNAL */
public function GameRules_OnNetDamage_Slot OnNetDamage(AcediaObject receiver);

/**
 *      When pawn is about to die, `GameRule`s are given a chance to
 *  prevent that.
 *
 *  [Signature]
 *  bool <slot>(
 *      Pawn                killed,
 *      Controller          killer,
 *      class<DamageType>   damageType,
 *      Vector              hitLocation)
 *
 *  @param  killed      `Pawn` that is about to be killed.
 *  @param  killer      `Pawn` that dealt the blow that has caused death.
 *  @param  damageType  `DamageType` with which finishing blow was dealt.
 *  @param  hitLocation "Location of the damage", e.g. place where `injured`
 *      was hit by a bullet that caused death.
 *  @return Return `true` if you want to prevent death of the `killed` and
 *      `false` otherwise.
 *      If you do decide to prevent death by returning `true` - this signal
 *      will not be propagated to the rest of the slots.
 */
/* SIGNAL */
public function GameRules_OnPreventDeath_Slot OnPreventDeath(
    AcediaObject receiver);

/**
 *  Called when one `Pawn` kills another.
 *
 *  [Signature]
 *  void <slot>(Controller killer, Controller killed)
 *
 *  @param  killer  `Pawn` that caused death.
 *  @param  killed  Killed `Pawn`.
 */
/* SIGNAL */
public function GameRules_OnScoreKill_Slot OnScoreKill(
    AcediaObject receiver);

/**
 *  Adds new `GameRules` class to the current `GameInfo`.
 *  Does nothing if given `GameRules` class was already added before.
 *
 *  @param  newRulesClass   Class of rules to add.
 *  @return `GameRules` instance if it was added and `none` otherwise
 *      (can happen if rules of this class were already added).
 */
public function GameRules Add(class<GameRules> newRulesClass);

/**
 *  Removes given `GameRules` class from the current `GameInfo`,
 *  if they are active. Does nothing otherwise.
 *
 *  @param  rulesClassToRemove  Class of rules to try and remove.
 *  @return `true` if `GameRules` were removed and `false` otherwise
 *      (if they were not active in the first place).
 */
public function bool Remove(class<GameRules> rulesClassToRemove);

/**
 *  Finds given class of `GameRules` if it's currently active in `GameInfo`.
 *  Returns `none` otherwise.
 *
 *  @param  rulesClassToFind    Class of rules to find.
 *  @return `GameRules` instance of given class `rulesClassToFind`, that is
 *      added to `GameInfo`'s records and `none` if no such rules are
 *      currently added.
 */
public function GameRules FindInstance(class<GameRules> rulesClassToFind);

/**
 *  Checks if given class of `GameRules` is currently active in `GameInfo`.
 *
 *  @param  rulesClassToCheck   Class of rules to check for.
 *  @return `true` if `GameRules` are active and `false` otherwise.
 */
public function bool AreAdded(class<GameRules> rulesClassToCheck);

defaultproperties
{
}