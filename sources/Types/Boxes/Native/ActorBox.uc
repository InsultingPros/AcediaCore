/**
 *  This file either was manually edited with minimal changes from the template
 *  for value boxes.
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
class ActorBox extends ValueBox
    dependson(ActorService);

var protected int                           boxHashCode;
var protected bool                          hasValue;
var protected ActorService.ActorReference   valueRef;

protected function Finalizer()
{
    local ActorService service;
    if (hasValue) {
        service = ActorService(class'ActorService'.static.Require());
    }
    if (service != none) {
        service.RemoveActor(valueRef);
    }
    hasValue = false;
}

/**
 *  Returns stored value.
 *
 *  @return Value, stored in this reference.
 */
public final function AcediaActor Get()
{
    local ActorService service;
    if (!hasValue) {
        return none;
    }
    service = ActorService(class'ActorService'.static.Require());
    if (service != none) {
        return AcediaActor(service.GetActor(valueRef));
    }
    return none;
}

/**
 *  Initialized box value. Can only be called once.
 *
 *  @param  boxValue    Value to store in this reference.
 *  @return Reference to the caller `ActorBox` to allow for method chaining.
 */
public final function ActorBox Initialize(AcediaActor boxValue)
{
    local ActorService service;
    if (IsInitialized()) {
        return self;
    }
    service = ActorService(class'ActorService'.static.Require());
    if (service == none) {
        return self;
    }
    valueRef = service.AddActor(boxValue);
    hasValue = true;
    MarkInitialized();
    if (boxValue != none) {
        boxHashCode = boxValue.GetHashCode();
    }
    else {
        boxHashCode = super.GetHashCode();
    }
    return self;
}

public function bool IsEqual(Object other)
{
    local ActorBox    otherBox;
    local ActorService      service;
    otherBox = ActorBox(other);
    if (otherBox == none)   return false;
    service = ActorService(class'ActorService'.static.Require());
    if (service == none)    return false;

    return Get() == otherBox.Get();
}

protected function int CalculateHashCode()
{
    return boxHashCode;
}

defaultproperties
{
}
