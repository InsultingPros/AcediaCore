/**
 *  Iterator for tracing entities inside the game world.
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
class TracingIterator extends EntityIterator
    abstract;

/**
 *  Returns position from which tracing is started.
 *
 *  @return Position from which tracing has started.
 */
public function Vector GetTracingStart();

/**
 *  Returns position at which tracing has ended.
 *
 *  @return Position at which tracing has ended.
 */
public function Vector GetTracingEnd();

/**
 *  Returns hit location for the `EPlaceable` that `TracingIterator` is
 *  currently at.
 *
 *  @return Hit location for the `EPlaceable` that `TracingIterator` is
 *      currently at. Origin vector (with all coordinates set to `0.0`) if
 *      iteration has already finished.
 */
public function Vector GetHitLocation();

/**
 *  Returns hit normal for the `EPlaceable` that `TracingIterator` is
 *  currently at.
 *
 *  @return Hit normal for the `EPlaceable` that `TracingIterator` is
 *      currently at. Origin vector (with all coordinates set to `0.0`) if
 *      iteration has already finished.
 */
public function Vector GetHitNormal();

defaultproperties
{
}