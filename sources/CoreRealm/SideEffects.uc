/**
 *  This object is meant purely as a dummy class to load config values about
 *  side effects in AcediaCore. Class name is chosen to make config more
 *  readable.
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
 * but WITHOUT ANY WARRANTY *  without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Acedia.  If not, see <https://www.gnu.org/licenses/>.
 */
class SideEffects extends AcediaObject
    dependson(BroadcastAPI)
    abstract
    config(AcediaSystem);

/**
 *      Acedia requires adding its own `GameRules` to listen to many different
 *  game events.
 *      It's normal for a mod to add its own game rules: game rules are
 *  implemented in such a way that they form a linked list and, after
 *  first (root) rules object receives a message it tells about said message to
 *  the next rules object, which does the same, propagating messages through
 *  the whole list.
 *      This is the least offensive side effect of AcediaCore and there should
 *  be no reason to prevents its `GameRules` from being added.
 */
var public const config bool allowAddingGameRules;

/**
 *      If allowed, AcediaCore can provide some additional information about
 *  itself and other packages through "help" / "status" / "version" / "credits"
 *  mutate commands, as well as allow to use "mutate acediacommands" to
 *  emergency-enable `Commands` feature.
 *      However that required access to "mutate" command events, which might not
 *  always be desirable from `AcediaCore` library. This setting allows you to
 *  disable such hooks.
 *      NOTE: setting this to `false` will not prevent `Commands` feature from
 *  hooking into mutate on its own.
 */
var public const config bool allowHookingIntoMutate;

/**
 *      Unfortunately, thanks to the TWI's code, there's no way to catch events
 *  of when certain kinds of damage are dealt: from welder, bloat's bile and
 *  siren's scream. At least not without something drastic, like replacing game
 *  type class.
 *      As a workaround, Acedia can optionally replace bloat and siren damage
 *  type to at least catch damage dealt by zeds (as being dealt welder damage is
 *  pretty rare and insignificant). This change has several unfortunate
 *  side-effects:
 *      1. Potentially breaking mods that are looking for `DamTypeVomit` and
 *          `SirenScreamDamage` damage types specifically. Fixing this issue
 *          would require these mods to either also try and catch Acedia's
 *          replacements `AcediaCore.Dummy_DamTypeVomit` and
 *          `AcediaCore.Dummy_SirenScreamDamage` or to catch any child classes
 *          of `DamTypeVomit` and `SirenScreamDamage` (as Acedia's replacements
 *          are also their child classes).
 *      2. Breaking some achievements that rely on
 *          `KFSteamStatsAndAchievements`'s `KilledEnemyWithBloatAcid()` method
 *          being called. This is mostly dealt with by Acedia calling it
 *          manually. However it relies on killed pawn to have
 *          `lastDamagedByType` set to `DamTypeVomit`, which sometimes might not
 *          be the case. Achievements should still be obtainable.
 *      3. A lot of siren's visual damage effects code does direct checks for
 *          `SirenScreamDamage` class. These can also break, stopping working as
 *          intended.
 */
var public const config bool allowReplacingDamageTypes;

/**
 *      Acedia requires injecting its own `BroadcastHandler` to listen to
 *  the broadcasted messages.
 *      It's normal for a mod to add its own broadcast handler: broadcast
 *  handlers are implemented in such a way that they form a linked list and,
 *  after first (root) handler receives a message it tells about said message to
 *  the next handler, which does the same, propagating messages through
 *  the whole list.
 *      If you do not wish Acedia to add its own handler, you should specify
 *  `BHIJ_None` as `broadcastHandlerInjectionLevel`'s value. If you want to
 *  allow it to simply add its broadcast handler to the end of the handler's
 *  linked list, as described above, set it to `BHIJ_Registered`.
 *      However, more information can be obtained if Acedia's broadcast handler
 *  is inserted at the root of the whole chain. This is the preferred way for
 *  Acedia and if you do not have a reason to forbid that (for example, for mod
 *  compatibility reasons), you should set this value at `BHIJ_Root`.
 */
var public const config BroadcastAPI.InjectionLevel broadcastHandlerInjectionLevel;

defaultproperties
{
    allowAddingGameRules            = true
    allowHookingIntoMutate          = true
    allowReplacingDamageTypes       = true
    broadcastHandlerInjectionLevel  = BHIJ_Root
}