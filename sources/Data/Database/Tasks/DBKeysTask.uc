/**
 *  Variant of `DBTask` for `GetDataKeys()` query.
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
class DBKeysTask extends DBTask;

var private DynamicArray queryKeysResponse;

delegate connect(Database.DBQueryResult result, DynamicArray keys) {}

protected function Finalizer()
{
    super.Finalizer();
    queryKeysResponse   = none;
    connect             = none;
}

public function SetDataKeys(DynamicArray keys)
{
    queryKeysResponse = keys;
}

protected function CompleteSelf()
{
    connect(GetResult(), queryKeysResponse);
}

defaultproperties
{
}