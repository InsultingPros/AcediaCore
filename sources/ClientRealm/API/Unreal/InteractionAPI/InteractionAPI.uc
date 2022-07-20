/**
 *  API that provides `Interaction` events and auxiliary methods.
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
class InteractionAPI extends AcediaObject;

/**
 *  Called before rendering, when `Interaction`s receive their `PreRender()`
 *  events
 *
 *  [Signature]
 *  <slot>(Canvas canvas)
 *
 *  @param  Canvas  `Actor` that attempts to broadcast next text message.
 */
/* SIGNAL */
public function Interaction_OnRender_Slot OnPreRender(AcediaObject receiver);

/**
 *  Called before rendering, when `Interaction`s receive their `PreRender()`
 *  events
 *
 *  [Signature]
 *  <slot>(Canvas canvas)
 *
 *  @param  Canvas  `Actor` that attempts to broadcast next text message.
 */
/* SIGNAL */
public function Interaction_OnRender_Slot OnPostRender(AcediaObject receiver);

/**
 *  Adds new interaction of class `interactionClass` to the local interaction
 *  master.
 *
 *  @see    `AddInteraction_S()`
 *
 *  @param  interactionClass    Textual representation of interaction class
 *      to add.
 *  @return Newly added interaction. `none` if we've failed to add it to
 *      the interaction master.
 */
public function Interaction AddInteraction(BaseText interactionClass);

/**
 *  Adds new interaction of class `interactionClass` to the local interaction
 *  master.
 *
 *  @see    `AddInteraction()`
 *
 *  @param  interactionClass    Textual representation of interaction class
 *      to add.
 *  @return Newly added interaction. `none` if we've failed to add it to
 *      the interaction master.
 */
public function Interaction AddInteraction_S(string interactionClass);

defaultproperties
{
}