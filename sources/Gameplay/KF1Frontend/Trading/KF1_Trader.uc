/**
 *  `ETrader`'s implementation for `KF1_Frontend`.
 *  Wrapper for KF1's `ShopVolume`s.
 *      Copyright 2021 - 2022 Anton Tarasenko
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
class KF1_Trader extends ETrader;

//  We do not use any vanilla value as a name, instead storing and tracking it
//  entirely as our own value.
var protected Text              myName;
//  Reference to `ShopVolume` actor that this `KF1_Trader` represents.
var protected NativeActorRef    myShopVolume;

//      We want to assign each trader (`ShopVolume`) a unique name that does
//  not change. For that we will use `namedShopVolumes` array's default value to
//  store `ShopVolume`-`Text` pairs.
//      Whenever new `KF1_Trader` is created we check with this list to see if
//  appropriate name was already assigned.
struct NamedShopVolume
{
    var public Text             name;
    var public NativeActorRef   reference;
};
var private array<NamedShopVolume> namedShopVolumes;

protected function Constructor()
{
    //  We only care about `default` value of this array variable,
    //  so do not bother storing needless references in each object
    if (namedShopVolumes.length > 0) {
        namedShopVolumes.length = 0;
    }
}

protected function Finalizer()
{
    _.memory.Free(myName);
    _.memory.Free(myShopVolume);
    myShopVolume = none;
    myName = none;
}

protected static function StaticFinalizer()
{
    local int i;
    if (default.namedShopVolumes.length <= 0) {
        return;
    }
    for (i = 0; i < default.namedShopVolumes.length; i += 1)
    {
        __().memory.Free(default.namedShopVolumes[i].name);
        __().memory.Free(default.namedShopVolumes[i].reference);
    }
    default.namedShopVolumes.length = 0;
}

private static function Text GetShopVolumeName(ShopVolume newShopVolume)
{
    local int                       i;
    local NamedShopVolume           newRecord;
    local array<NamedShopVolume>    namedShopVolumesCopy;
    if (newShopVolume == none) {
        return none;
    }
    namedShopVolumesCopy = default.namedShopVolumes;
    for (i = 0; i < namedShopVolumesCopy.length; i += 1)
    {
        if (namedShopVolumesCopy[i].reference.Get() == newShopVolume) {
            return namedShopVolumesCopy[i].name.Copy();
        }
    }
    newRecord.reference = __server().unreal.ActorRef(newShopVolume);
    newRecord.name =
        __().text.FromString("trader" $ namedShopVolumesCopy.length);
    default.namedShopVolumes[default.namedShopVolumes.length] = newRecord;
    return newRecord.name.Copy();
}

/**
 *  Initializes caller `KF1_Trader`. Should be called right after `KF1_Trader`
 *  was allocated.
 *
 *  Every `KF1_Trader` must be initialized, using non-initialized `KF1_Trader`
 *  instances is invalid.
 *
 *  Initialization can fail if:
 *      1.  `initShopVolume == none`;
 *      2.  Caller `KF1_Trader` already was successfully initialized.
 *      3.  `initShopVolume` is objective-mode only `ShopVolume` and we are
 *          not running an objective mode right now.
 *
 *  @param  initShopVolume  `ShopVolume` that caller `KF1_Trader` will
 *      correspond to.
 *  @return `true` if initialization was successful and `false` otherwise.
 */
public final /* unreal */ function bool Initialize(ShopVolume initShopVolume)
{
    if (initShopVolume == none) {
        return false;
    }
    if (    initShopVolume.bObjectiveModeOnly
        &&  !__server().unreal.GetKFGameType().bUsingObjectiveMode) {
        return false;
    }
    myName          = GetShopVolumeName(initShopVolume);
    myShopVolume    = _server.unreal.ActorRef(initShopVolume);
    return true;
}

/**
 *  Returns `ShopVolume`, associated with the caller `KF1_Trader`.
 *
 *  @return `ShopVolume`, associated with the caller `KF1_Trader`.
 */
public final /* unreal */ function ShopVolume GetShopVolume()
{
    if (myShopVolume == none) {
        return none;
    }
    return ShopVolume(myShopVolume.Get());
}

public function Text GetName()
{
    if (myName == none) {
        return P("");
    }
    return myName.Copy();
}

//  TODO: it is broken, needs fixing
public function ETrader SetName(BaseText newName)
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

public function ETrader SetEnabled(bool doEnable)
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
    local array<ETrader>    availableTraders;
    availableTraders = _server.kf.trading.GetTraders();
    for (i = 0; i < availableTraders.length; i += 1)
    {
        nextTrader = KF1_Trader(availableTraders[i]);
        if (nextTrader == none)         continue;
        if (!nextTrader.IsEnabled())    continue;
        nextShopVolume = ShopVolume(nextTrader.myShopVolume.Get());
        if (nextShopVolume == none)     continue;

        shopVolumes[shopVolumes.length] = nextShopVolume;
    }
    _server.unreal.GetKFGameType().shopList = shopVolumes;
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

public function ETrader SetAutoOpen(bool doAutoOpen)
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

public function ETrader SetOpen(bool doOpen)
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
    kfGameRI = _server.unreal.GetKFGameRI();
    if (kfGameRI != none) {
        return (kfGameRI.currentShop == vanillaShopVolume);
    }
    return false;
}

public function ETrader Select()
{
    local ShopVolume            vanillaShopVolume;
    local KFGameReplicationInfo kfGameRI;
    vanillaShopVolume = ShopVolume(myShopVolume.Get());
    if (vanillaShopVolume == none) {
        return self;
    }
    kfGameRI = _server.unreal.GetKFGameRI();
    if (kfGameRI != none) {
        kfGameRI.currentShop = vanillaShopVolume;
    }
    return self;
}

public function ETrader BootPlayers()
{
    local ShopVolume vanillaShopVolume;
    vanillaShopVolume = ShopVolume(myShopVolume.Get());
    if (vanillaShopVolume != none) {
        vanillaShopVolume.BootPlayers();
    }
    return self;
}

/**
 *  Makes a copy of the caller interface, producing a new `EInterface` of
 *  the exactly the same class (`EWeapon` will produce another `EWeapon`).
 *
 *  This should never fail. Even if referred entity is already gone.
 *
 *  @return Copy of the caller `EInterface`, of the exactly the same class.
 *      Guaranteed to not be `none`.
 */
public function EInterface Copy()
{
    local KF1_Trader traderCopy;
    traderCopy = KF1_Trader(_.memory.Allocate(class'KF1_Trader'));
    if (myShopVolume == none)
    {
        //  Should not really happen, since then caller `KF1_Trader` was
        //  not initialized
        return traderCopy;
    }
    traderCopy.Initialize(ShopVolume(myShopVolume.Get()));
    return traderCopy;
}

public function bool IsExistent()
{
    if (myShopVolume == none) {
        return false;
    }
    return (myShopVolume.Get() != none);
}

public function bool SameAs(EInterface other)
{
    local KF1_Trader        asTrader;
    local NativeActorRef    otherShopVolume;
    if (other == none)              return false;
    if (myShopVolume == none)       return false;
    asTrader = KF1_Trader(other);
    if (asTrader == none)           return false;
    otherShopVolume = asTrader.myShopVolume;
    if (otherShopVolume == none)    return false;
    
    return (myShopVolume.Get() == otherShopVolume.Get());
}

defaultproperties
{
}