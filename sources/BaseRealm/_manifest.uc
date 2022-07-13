/**
 *  `Manifest` is meant to describe contents of the Acedia's package.
 *  This is the base class, every package's `Manifest` must directly extend it.
 *      Copyright 2020 Anton Tarasenko
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
 class _manifest extends Object
    abstract;

//  List of alias sources in this manifest's package.
var public const array< class<AliasSource> >    aliasSources;

//  List of features in this manifest's package.
var public const array< class<Feature> >        features;

//  List of test cases in this manifest's package.
var public const array< class<TestCase> >       testCases;

defaultproperties
{
}