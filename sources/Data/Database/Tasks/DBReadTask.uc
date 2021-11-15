/**
 *  Variant of `DBTask` for `ReadData()` query.
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
class DBReadTask extends DBTask;

var private AcediaObject queryDataResponse;

delegate connect(
    Database.DBQueryResult  result,
    AcediaObject            data,
    Database                source) {}

protected function Finalizer()
{
    super.Finalizer();
    queryDataResponse   = none;
    connect             = none;
}

public function SetReadData(AcediaObject data)
{
    queryDataResponse = data;
}

protected function CompleteSelf(Database source)
{
    connect(GetResult(), queryDataResponse, source);
}

defaultproperties
{
}