/**
 *  Variant of `DBTask` for `CheckDataType()` query.
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
class DBCheckTask extends DBTask;

var private Database.DataType queryTypeResponse;

delegate connect(
    Database.DBQueryResult  result,
    Database.DataType       type,
    Database                source) {}

protected function Finalizer()
{
    super.Finalizer();
    queryTypeResponse   = JSON_Undefined;
    connect             = none;
}

public function SetDataType(Database.DataType type)
{
    queryTypeResponse = type;
}

protected function CompleteSelf(Database source)
{
    connect(GetResult(), queryTypeResponse, source);
}

defaultproperties
{
}