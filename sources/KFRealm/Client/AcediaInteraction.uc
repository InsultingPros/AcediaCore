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

var private Global          _;
var private ClientGlobal    _client;
var private AcediaInteraction myself;

var private Unreal_OnTick_Signal        onTickSignal;
var private Interaction_OnRender_Signal onPreRenderSignal;
var private Interaction_OnRender_Signal onPostRenderSignal;

/**
 *  Signal that will be emitted every tick.
 *
 *  [Signature]
 *  void <slot>(float delta, float dilationCoefficient)
 *
 *  @param  delta               In-game time in seconds that has passed since
 *      the last tick. To obtain real time passed from the last tick divide
 *      `delta` by `dilationCoefficient`.
 *  @param  dilationCoefficient How fast is in-game time flow compared to
 *      the real world's one? `2` means twice as fast and
 *      `0.5` means twice as slow.
 */
/* SIGNAL */
public function Unreal_OnTick_Slot OnTick(AcediaObject receiver)
{
    return Unreal_OnTick_Slot(onTickSignal.NewSlot(receiver));
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
    onTickSignal = Unreal_OnTick_Signal(
        _.memory.Allocate(class'Unreal_OnTick_Signal'));
    onPreRenderSignal = Interaction_OnRender_Signal(
        _.memory.Allocate(class'Interaction_OnRender_Signal'));
    onPostRenderSignal = Interaction_OnRender_Signal(
        _.memory.Allocate(class'Interaction_OnRender_Signal'));
}

event NotifyLevelChange()
{
    _.memory.Free(onTickSignal);
    _.memory.Free(onPreRenderSignal);
    _.memory.Free(onPostRenderSignal);
    onTickSignal        = none;
    onPreRenderSignal   = none;
    onPostRenderSignal  = none;
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
    if (onPostRenderSignal != none) {
        onPostRenderSignal.Emit(canvas);
    }
}

public function Tick(float delta)
{
    local float dilationCoefficient;

    if (onTickSignal != none)
    {
        dilationCoefficient = _client.unreal.GetLevel().timeDilation / 1.1;
        onTickSignal.Emit(delta, dilationCoefficient);
    }
}

defaultproperties
{
    bVisible        = true
    bRequiresTick   = true
}