/**
 *  Default Acedia implementation for `InteractionAPI`.
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
class KF1_InteractionAPI extends InteractionAPI;

/* SIGNAL */
public function Interaction_OnRender_Slot OnPreRender(AcediaObject receiver)
{
    local AcediaInteraction interaction;

    //  Simple redirect to `AcediaInteraction`
    interaction = class'AcediaInteraction'.static.GetInstance();
    if (interaction != none) {
        return interaction.OnPreRender(receiver);
    }
    return none;
}

/* SIGNAL */
public function Interaction_OnRender_Slot OnPostRender(AcediaObject receiver)
{
    local AcediaInteraction interaction;

    //  Simple redirect to `AcediaInteraction`
    interaction = class'AcediaInteraction'.static.GetInstance();
    if (interaction != none) {
        return interaction.OnPostRender(receiver);
    }
    return none;
}

public function Interaction AddInteraction(BaseText interactionClass)
{
    local string classAsString;

    if (interactionClass == none) {
        return none;
    }
    classAsString = interactionClass.ToString();
    return AddInteraction_S(classAsString);
}

public function Interaction AddInteraction_S(string interactionClass)
{
    local Interaction       newInteraction;
    local Player            player;
    local PlayerController  localPlayerController;

    localPlayerController = _client.unreal.GetLocalPlayer();
    if (localPlayerController == none)      return none;
    player = localPlayerController.player;
    if (player == none)                     return none;
    if (player.interactionMaster == none)   return none;

    newInteraction = player.interactionMaster.AddInteraction(
        "AcediaCore.AcediaInteraction",
        player);
    return newInteraction;
}

defaultproperties
{
}