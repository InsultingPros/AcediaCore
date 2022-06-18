/**
 *      This class IS NOT an implementation for `Database` interface and
 *  simply exists to store config information about some local database.
 *  Name is chosen to make user configs more readable.
 *      This class is considered an internal object and should only be referred
 *  to inside AcediaCore package.
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
class LocalDatabase extends AcediaObject
    perobjectconfig
    config(AcediaDB);

var config private string   root;
var config private bool     createIfMissing;

public final function Text GetPackageName()
{
    return __().text.FromString(string(name));
}

public final function bool HasDefinedRoot()
{
    return root != "";
}

public final function Text GetRootName()
{
    return __().text.FromString(root);
}

/**
 *  Changes caller's root name.
 *
 *  Only makes changes if root is not already defined.
 */
public final function SetRootName(BaseText rootName)
{
    if (HasDefinedRoot()) {
        return;
    }
    if (rootName != none) {
        root = rootName.ToString();
    }
    else {
        root = "";
    }
}

public final static function LocalDatabase Load(BaseText databaseName)
{
    if (!__().text.IsEmpty(databaseName)) {
        return new(none, databaseName.ToString()) class'LocalDatabase';
    }
    return none;
}

/**
 *  Updates `LocalDatabase` record inside it's config file. If caller
 *  `LocalDatabase` does not have defined root `HasDefinedRoot() == none`,
 *  then this method will erase its record from the config.
 */
public final function Save()
{
    if (HasDefinedRoot()) {
        SaveConfig();
    }
    else {
        ClearConfig();
    }
}

public final function bool ShouldCreateIfMissing()
{
    return createIfMissing;
}

/**
 *  Forgets all information stored in the caller `LocalDatabase` and erases it
 *  from the config files. After this call, creating `LocalDatabase` object
 *  with the same name will produce an object that can be treated as "blank":
 *  one will be able to use it to store information about new database.
 */
public final function DeleteSelf()
{
    root = "";
    ClearConfig();
}

defaultproperties
{
    createIfMissing = false
}