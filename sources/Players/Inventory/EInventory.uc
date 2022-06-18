/**
 *  Abstract interface that represents inventory system. Inventory system is
 *  supposed to represent a way to handle items in players inventory -
 *  in Killing Floor it is a simple set of items with total weight limitations.
 *  But any other kind of inventory can be implemented as long as it follows
 *  limitations of this interface.
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
class EInventory extends EInterface
    abstract;

/**
 *  Initializes `EInventory` for a given `player`.
 *
 *  This method should not be called manually, unless you implement your own
 *  game interface.
 *
 *  Cannot fail for any connected player and will assume it will not be called
 *  for not connected ones.
 *
 *  @param  player  `EPlayer` for which to initialize this inventory.
 */
public function Initialize(EPlayer player) {}

/**
 *  Adds passed `EItem` to the caller inventory system.
 *
 *  If adding `newItem` is not currently possible for the caller
 *  inventory system - it can refuse it.
 *
 *  @param  newItem         New item to add to the caller inventory system.
 *      Can be destroyed as a result of this call, if it gets merged with
 *      another weapon inside the inventory.
 *  @param  forceAddition   This parameter is only relevant when `newItem`
 *      cannot be added in the caller inventory system. If it cannot be added
 *      because of the conflict with other items - setting this flag to `true`
 *      allows caller inventory system to get rid of such items to make room for
 *      `newItem`. Removing items is only allowed if it will actually let us add
 *      `newItem`. How removal will be done is up to the implementation.
 *  @return `EItem` added as a result. Can be different from `newItem` in case
 *      inventory made it "merge" with another weapon. This can happen,
 *      for example, if we add a single pistol when inventory already contains
 *      pistol of the same type.
 *      `none` if we have failed to add `newItem` to the inventory.
 */
public function EItem Add(EItem newItem, optional bool forceAddition)
{
    return none;
}

/**
 *  Adds new `EItem` of template `newItemTemplate` to the caller
 *  inventory system.
 *
 *  If adding new item is not currently possible for the caller
 *  inventory system - it can refuse it.
 *
 *  @param  newItemTemplate Template of the new item to add to
 *      the caller inventory system.
 *  @param  forceAddition   This parameter is only relevant when new item
 *      cannot be added in the caller inventory system. If it cannot be added
 *      because of the conflict with other items - setting this flag to `true`
 *      allows caller inventory system to get rid of such items to make room for
 *      new item. Removing items is only allowed if it will actually let us add
 *      new item. How removal will be done is up to the implementation.
 *  @return Reference to `EItem` interface to the added item entity,
 *      `none` iff adding item has failed.
 */
public function EItem AddTemplate(
    BaseText        newItemTemplate,
    optional bool   forceAddition)
{
    return none;
}

/**
 *  Checks whether given item `itemToCheck` can be added to the caller
 *  inventory system.
 *
 *  See also `CanAddExplain()`.
 *
 *  @param  itemToCheck     Item to check for whether we can add it to
 *      the caller `EInventory`.
 *  @param  forceAddition   New items can be added with or without
 *      `forceAddition` flag. This parameter allows you to check whether we
 *      test for addition with or without it.
 *  @return `true` if given `itemToCheck` can be added to the caller
 *      inventory system with given flag `forceAddition` and `false` otherwise.
 */
public final function bool CanAdd(
    EItem           itemToCheck,
    optional bool   forceAddition)
{
    local bool success;
    local Text explanation;
    explanation = CanAddExplain(itemToCheck, forceAddition);
    success = (explanation == none);
    _.memory.Free(explanation);
    return success;
}

/**
 *  Checks whether item with given template `itemToCheck` can be added to
 *  the caller inventory system.
 *
 *  See also `CanAddTemplateExplain()`.
 *
 *  @param  itemTemplateToCheck Template of the item to check for whether we can
 *      add it to the caller `EInventory`.
 *  @param  forceAddition       New items can be added with or without
 *      `forceAddition` flag. This parameter allows you to check whether we
 *      test for addition with or without it.
 *  @return `true` if item with given template `itemTemplateToCheck` can be
 *      added to the caller inventory system with given flag `forceAddition` and
 *      `false` otherwise.
 */
public function bool CanAddTemplate(
    BaseText        itemTemplateToCheck,
    optional bool   forceAddition)
{
    local bool success;
    local Text explanation;
    explanation = CanAddTemplateExplain(itemTemplateToCheck, forceAddition);
    success = (explanation == none);
    _.memory.Free(explanation);
    return success;
}

/**
 *  Checks whether given item `itemToCheck` can be added to the caller
 *  inventory system and provides short explanation (dependent on
 *  implementation) if item cannot be added.
 *
 *  See also `CanAdd()`.
 *
 *  @param  itemToCheck     Item to check for whether we can add it to
 *      the caller `EInventory`.
 *  @param  forceAddition   New items can be added with or without
 *      `forceAddition` flag. This parameter allows you to check whether we
 *      test for addition with or without it.
 *  @return `none` if given `itemToCheck` can be added to the caller
 *      inventory system with given flag `forceAddition` and `Text` with
 *      description of reason why not otherwise.
 */
public function Text CanAddExplain(
    EItem           itemToCheck,
    optional bool   forceAddition)
{
    return none;
}

/**
 *  Checks whether item with given template `itemToCheck` can be added to
 *  the caller inventory system and provides short explanation (dependent on
 *  implementation) if item cannot be added.
 *
 *  See also `CanAddTemplate()`.
 *
 *  @param  itemTemplateToCheck Template of the item to check for whether we can
 *      add it to the caller `EInventory`.
 *  @param  forceAddition       New items can be added with or without
 *      `forceAddition` flag. This parameter allows you to check whether we
 *      test for addition with or without it.
 *  @return `none` if given `itemToCheck` can be added to the caller
 *      inventory system with given flag `forceAddition` and `Text` with
 *      description of reason why not otherwise.
 */
public function Text CanAddTemplateExplain(
    BaseText        itemTemplateToCheck,
    optional bool   forceAddition)
{
    return none;
}

/**
 *  Removes given item `itemToRemove` from the caller `EInventory`.
 *
 *  Based on gameplay considerations, inventory system can refuse removing
 *  `EItem`s for which `IsRemovable()` returns `false`. But removal of any item
 *  can be enforced with optional third parameter.
 *
 *  @param  itemToRemove    Item that needs to be removed.
 *  @param  keepItem        By default removed item is destroyed.
 *      Setting this flag to `true` will make caller `EInventory` try to
 *      preserve it in some way. For Killing Floor it means dropping the item.
 *  @param  forceRemoval    Set this to `true` if item must be removed
 *      no matter what. Otherwise inventory system can refuse removal of items,
 *      whose `IsRemovable()` returns `false`.
 *  @return `true` if `EItem` was removed and `false` otherwise
 *      (including the case where `EItem` was not kept in the caller
 *      `EInventory` in the first place).
 */
public function bool Remove(
    EItem           itemToRemove,
    optional bool   keepItem,
    optional bool   forceRemoval)
{
    return false;
}

/**
 *  Removes item with given template `itemTemplateToRemove` from the caller
 *  `EInventory`.
 *
 *  By default removes one arbitrary (can be based on simple convenience of
 *  implementation) item, but optional parameter can make it remove all items
 *  of that type.
 *
 *  Based on gameplay considerations, inventory system can refuse removing any
 *  `EItem` if `IsRemovable()` returns `false` for all stored items of
 *  given type `itemTemplateToRemove`. But removal of any item can be enforced
 *  with optional third parameter.
 *
 *  @param  itemTemplateToRemove    Type of item that needs to be removed.
 *  @param  keepItem        By default removed item is destroyed.
 *      Setting this flag to `true` will make caller `EInventory` try to
 *      preserve it in some way. For Killing Floor it means dropping the item.
 *  @param  forceRemoval            Set this to `true` if item must be removed
 *      no matter what. Otherwise inventory system can refuse removal if
 *      `IsRemovable()` returns `false` for all items of given type.
 *  @param  removeAll       Set this to `true` if all items of the given type
 *      must be removed from the caller `EInventory` and keep `false` to remove
 *      only one. With `forceRemoval == false` it is possible that only items
 *      that return `false` for `IsRemovable()` will be removed, while others
 *      will be retained.
 *  @return `true` if any `EItem`s was removed and `false` otherwise
 *      (including the case where `EItem` of given type were not kept in the
 *      caller `EInventory` in the first place).
 */
public function bool RemoveTemplate(
    BaseText        itemTemplateToRemove,
    optional bool   keepItem,
    optional bool   forceRemoval,
    optional bool   removeAll)
{
    return false;
}

/**
 *  Removes all items from the caller `EInventory`.
 *
 *  By default this method should only remove items with "visible" tag,
 *  i.e. the items player can see and interact with. This behavior can be
 *  changed with `includeHidden` parameter.
 *
 *  Based on gameplay considerations, inventory system can refuse removing
 *  `EItem`s for which `IsRemovable()` returns `false`. But removal of any item
 *  can be enforced with optional second parameter.
 *
 *  @param  keepItem        By default removed item is destroyed.
 *      Setting this flag to `true` will make caller `EInventory` try to
 *      preserve it in some way. For Killing Floor it means dropping the item.
 *  @param  forceRemoval    Set this to `true` if item must be removed
 *      no matter what. Otherwise inventory system can refuse removal of items,
 *      whose `IsRemovable()` returns `false`.
 *  @param  forceRemoval    Set this to `true` if even invisible to the player
 *      items have to be removed. In Killing Floor only weapons are visible to
 *      the player (ammunition items are considered to be just
 *      their parameters).
 *  @param  includeHidden   Set this to `true` to also affect items without
 *      "visible" tag.
 *  @return `true` if any `EItem` was removed and `false` otherwise
 *      (including the case where no `EItem`s were kept in the caller
 *      `EInventory` in the first place).
 */
public function bool RemoveAll(
    optional bool keepItems,
    optional bool forceRemoval,
    optional bool includeHidden)
{
    return false;
}

/**
 *  Checks whether caller `EInventory` contains given `itemToCheck`.
 *
 *  @param  itemToCheck `EItem` we want to check for belonging to the caller
 *      `EInventory`.
 *  @result `true` if item does belong to the inventory and `false` otherwise.
 */
public function bool Contains(EItem itemToCheck)
{
    return false;
}

/**
 *  Checks whether caller `EInventory` contains item with given template
 *  `itemTemplateToCheck`.
 *
 *  @param  itemTemplateToCheck Template we want to check for belonging to
 *      the caller `EInventory`.
 *  @result `true` if item with a given template does belong to the inventory
 *      and `false` otherwise.
 */
public function bool ContainsTemplate(BaseText itemTemplateToCheck)
{
    return false;
}

/**
 *  Returns array with all `EItem`s contained inside the caller `EInventory`.
 *
 *  @return Array with all `EItem`s contained inside the caller `EInventory`.
 */
public function array<EItem> GetAllItems()
{
    local array<EItem> emptyArray;
    return emptyArray;
}

/**
 *  Returns array with all `EItem`s contained inside the caller `EInventory`
 *  that support interface of class `interfaceClass`.
 *
 *  @return Array with all `EItem`s that support interface of
 *      class `interfaceClass` contained inside the caller `EInventory`.
 *      Guaranteed to not contain `none` references of interfaces to
 *      inexistent entities.
 */
public function array<EItem> GetItemsSupporting(class<EItem> interfaceClass)
{
    local array<EItem> emptyArray;
    return emptyArray;
}

/**
 *  Returns array with all `EItem`s contained inside the caller `EInventory`
 *  that has specified tag `tag`.
 *
 *  @param  tag Tag, which items we want to get.
 *  @return Array with all `EItem`s contained inside the caller `EInventory`
 *      that has specified tag `tag`.
 *      Guaranteed to not contain `none` references of interfaces to
 *      inexistent entities.
 */
public function array<EItem> GetTagItems(BaseText tag)
{
    local array<EItem> emptyArray;
    return emptyArray;
}

/**
 *  Returns `EItem` contained inside the caller `EInventory` that has specified
 *  tag `tag`.
 *
 *  If several `EItem`s inside caller `EInventory` have specified tag,
 *  inventory system can pick one arbitrarily (can be based on simple
 *  convenience of implementation). Returned value does not have to
 *  be stable (the same after repeated calls).
 *
 *  @param  tag   Tag, which item we want to get.
 *  @return `EItem` contained inside the caller `EInventory` that belongs to
 *      the specified tag `tag`.
 *      Guaranteed to not be `none` or refer to non-existent entity.
 */
public function EItem GetTagItem(BaseText tag) { return none; }

/**
 *  Returns array with all `EItem`s contained inside the caller `EInventory`
 *  that originated from the specified template `template`.
 *
 *  @param  template    Template, that items we want to get originated from.
 *  @return Array with all `EItem`s contained inside the caller `EInventory`
 *      that originated from the specified template `template`.
 *      Guaranteed to not contain `none` references or interfaces to
 *      inexistent entities.
 */
public function array<EItem> GetTemplateItems(BaseText template)
{
    local array<EItem> emptyArray;
    return emptyArray;
}

/**
 *  Returns `EItem`s contained inside the caller `EInventory`
 *  that originated from the specified template `template`.
 *
 *  If several `EItem`s inside caller `EInventory` originated from
 *  that template, inventory system can pick one arbitrarily (can be based on
 *  simple convenience of implementation). Returned value does not have to
 *  be stable (the same after repeated calls).
 *
 *  @param  template    Template, that item we want to get originated from.
 *  @return `EItem`s contained inside the caller `EInventory` that originated
 *      from the specified template `template`.
 *      Guaranteed to not be `none` or refer to non-existent entity.
 */
public function EItem GetTemplateItem(BaseText template) { return none; }

/**
 *  Returns array of caller `EInventory`'s items that are currently equipped by
 *  its owner player.
 *
 *  @return Array with all `EItem`s contained inside the caller `EInventory`
 *      that are equipped by its owner.
 *      Guaranteed to not contain `none` references or interfaces to
 *      inexistent entities.
 */
public function array<EItem> GetEquippedItems()
{
    local array<EItem> emptyArray;
    return emptyArray;
}

public function EItem GetEquippedItem() { return none; }

defaultproperties
{
}