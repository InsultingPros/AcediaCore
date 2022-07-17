/**
 *  Acedia's interaction class that allows it access to drawing and user input.
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
class AcediaInteraction extends Interaction;

#exec OBJ LOAD FILE=KillingFloorHUD.utx
#exec OBJ LOAD FILE=KillingFloor2HUD.utx

var private Global          _;
var private ClientGlobal    _client;
var private AcediaInteraction myself;
var Texture shield;

var private Interaction_OnRender_Signal onPreRenderSignal;
var private Interaction_OnRender_Signal onPostRenderSignal;

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
public function Interaction_OnRender_Slot OnPreRender(AcediaObject receiver)
{
    return Interaction_OnRender_Slot(onPreRenderSignal.NewSlot(receiver));
}

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
public function Interaction_OnRender_Slot OnPostRender(AcediaObject receiver)
{
    return Interaction_OnRender_Slot(onPostRenderSignal.NewSlot(receiver));
}

/**
 *  Initializes newly created `Interaction`.
 */
public final function InitializeInteraction()
{
    if (default.myself != none) {
        return;
    }
    default.myself = self;
    _       = class'Global'.static.GetInstance();
    _client = class'ClientGlobal'.static.GetInstance();
    onPreRenderSignal = Interaction_OnRender_Signal(
        _.memory.Allocate(class'Interaction_OnRender_Signal'));
    onPostRenderSignal = Interaction_OnRender_Signal(
        _.memory.Allocate(class'Interaction_OnRender_Signal'));
}

event NotifyLevelChange()
{
    _.environment.ShutDown();
    default.myself  = none;
    _               = none;
    _client         = none;
    master.RemoveInteraction(self);
}

/**
 *  Returns instance to the added `AcediaInteraction`'s instance.
 *
 *  @return Instance added to interaction master.
 */
public static function AcediaInteraction GetInstance()
{
    return default.myself;
}

public function PreRender(Canvas canvas)
{
    if (onPreRenderSignal != none) {
        onPreRenderSignal.Emit(canvas);
    }
}

public function PostRender(Canvas canvas)
{
    Log("dsfsdfs");
    canvas.SetPos(500, 500);
    canvas.DrawTile(shield, 16, 16, 0, 0, shield.MaterialUSize(), shield.MaterialVSize());
    if (onPostRenderSignal != none) {
        onPostRenderSignal.Emit(canvas);
    }
}

defaultproperties
{
    shield = Texture'KillingFloorHUD.HUD.Hud_Shield'
    bVisible = true
}