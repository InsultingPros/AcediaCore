/**
 *  `ATrader`'s implementation for `KF1_Frontend`.
 *  Wrapper for KF1's `ShopVolume`s.
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
class KF1_Trader extends ATrader;

//  We do not use any vanilla value as a name, instead storing and tracking it
//  entirely as our own value.
var protected Text              myName;
//  Reference to `ShopVolume` actor that this `KF1_Trader` represents.
var protected NativeActorRef    myShopVolume;

protected function Finalizer()
{
    _.memory.Free(myName);
    _.memory.Free(myShopVolume);
    myShopVolume = none;
    myName = none;
}

/**
 *  Detect all existing traders on the level and created a `KF1_Trader` for
 *  each of them.
 *
 *  @return Array of created `KF1_Trader`s. All of them are guaranteed to not
 *      be `none`.
 */
public static function array<KF1_Trader> WrapVanillaShops()
{
    local int           shopCounter;
    local MutableText   textBuilder;
    local LevelInfo     level;
    local KFGameType    kfGame;
    local KF1_Trader    nextTrader;
    local array<KF1_Trader> allTraders;
    local ShopVolume    nextShopVolume;
    level   = __().unreal.GetLevel();
    kfGame  = __().unreal.GetKFGameType();
    textBuilder = __().text.Empty();
    foreach level.AllActors(class'ShopVolume', nextShopVolume)
    {
        if (nextShopVolume == none) continue;
        if (!nextShopVolume.bObjectiveModeOnly || kfGame.bUsingObjectiveMode)
        {
            nextTrader = KF1_Trader(__().memory.Allocate(class'KF1_Trader'));
            nextTrader.myShopVolume = __().unreal.ActorRef(nextShopVolume);
            textBuilder.Clear().AppendPlainString("trader" $ shopCounter);
            nextTrader.myName = textBuilder.Copy();
            allTraders[allTraders.length] = nextTrader;
            shopCounter += 1;
        }
    }
    textBuilder.FreeSelf();
    return allTraders;
}

public function Text GetName()
{
    if (myName == none) {
        return _.text.Empty();
    }
    return myName.Copy();
}

public function ATrader SetName(Text newName)
{
    if (newName == none)    return self;
    if (newName.IsEmpty())  return self;

    myName.FreeSelf();
    newName = newName.Copy();
    return self;
}

public function Vector GetLocation()
{
    local ShopVolume vanillaShopVolume;
    vanillaShopVolume = ShopVolume(myShopVolume.Get());
    if (vanillaShopVolume != none) {
        return vanillaShopVolume.location;
    }
    return Vect(0, 0, 0);
}

public function bool IsEnabled()
{
    local ShopVolume vanillaShopVolume;
    vanillaShopVolume = ShopVolume(myShopVolume.Get());
    if (vanillaShopVolume != none) {
        return !vanillaShopVolume.bAlwaysClosed;
    }
    return false;
}

public function ATrader SetEnabled(bool doEnable)
{
    local ShopVolume vanillaShopVolume;
    vanillaShopVolume = ShopVolume(myShopVolume.Get());
    if (vanillaShopVolume == none) {
        return self;
    }
    if (doEnable) {
        vanillaShopVolume.bAlwaysClosed = false;
    }
    else
    {
        vanillaShopVolume.bAlwaysClosed = true;
        Close();
        BootPlayers();
    }
    UpdateShopList();
    return self;
}

/**
 *  This method re-fills `KFGameType.shopList` to contain only currently
 *  enabled traders.
 */
protected function UpdateShopList()
{
    local int               i;
    local ShopVolume        nextShopVolume;
    local KF1_Trader        nextTrader;
    local array<ShopVolume> shopVolumes;
    local array<ATrader>    availableTraders;
    availableTraders = _.kf.trading.GetTraders();
    for (i = 0; i < availableTraders.length; i += 1)
    {
        nextTrader = KF1_Trader(availableTraders[i]);
        if (nextTrader == none)         continue;
        if (!nextTrader.IsEnabled())    continue;
        nextShopVolume = ShopVolume(nextTrader.myShopVolume.Get());
        if (nextShopVolume == none)     continue;

        shopVolumes[shopVolumes.length] = nextShopVolume;
    }
    _.unreal.GetKFGameType().shopList = shopVolumes;
}

public function bool IsAutoOpen()
{
    local ShopVolume vanillaShopVolume;
    vanillaShopVolume = ShopVolume(myShopVolume.Get());
    if (vanillaShopVolume != none) {
        return vanillaShopVolume.bAlwaysEnabled;
    }
    return false;
}

public function ATrader SetAutoOpen(bool doAutoOpen)
{
    local ShopVolume vanillaShopVolume;
    vanillaShopVolume = ShopVolume(myShopVolume.Get());
    if (vanillaShopVolume == none) {
        return self;
    }
    if (doAutoOpen) {
        vanillaShopVolume.bAlwaysEnabled = true;
    }
    else {
        vanillaShopVolume.bAlwaysEnabled = false;
    }
    return self;
}

public function bool IsOpen()
{
    local ShopVolume vanillaShopVolume;
    vanillaShopVolume = ShopVolume(myShopVolume.Get());
    if (vanillaShopVolume != none) {
        return vanillaShopVolume.bCurrentlyOpen;
    }
    return false;
}

public function ATrader SetOpen(bool doOpen)
{
    local ShopVolume vanillaShopVolume;
    if (doOpen && !IsEnabled())     return self;
    vanillaShopVolume = ShopVolume(myShopVolume.Get());
    if (vanillaShopVolume == none)  return self;

    if (doOpen) {
        vanillaShopVolume.OpenShop();
    }
    else {
        vanillaShopVolume.CloseShop();
    }
    return self;
}

public function bool IsSelected()
{
    local ShopVolume            vanillaShopVolume;
    local KFGameReplicationInfo kfGameRI;
    vanillaShopVolume = ShopVolume(myShopVolume.Get());
    if (vanillaShopVolume == none) {
        return false;
    }
    kfGameRI = _.unreal.GetKFGameRI();
    if (kfGameRI != none) {
        return (kfGameRI.currentShop == vanillaShopVolume);
    }
    return false;
}

public function ATrader Select()
{
    local ShopVolume            vanillaShopVolume;
    local KFGameReplicationInfo kfGameRI;
    vanillaShopVolume = ShopVolume(myShopVolume.Get());
    if (vanillaShopVolume == none) {
        return self;
    }
    kfGameRI = _.unreal.GetKFGameRI();
    if (kfGameRI != none) {
        kfGameRI.currentShop = vanillaShopVolume;
    }
    return self;
}

public function ATrader BootPlayers()
{
    local ShopVolume vanillaShopVolume;
    vanillaShopVolume = ShopVolume(myShopVolume.Get());
    if (vanillaShopVolume != none) {
        vanillaShopVolume.BootPlayers();
    }
    return self;
}

defaultproperties
{
}