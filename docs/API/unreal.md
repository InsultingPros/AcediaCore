# `UnrealAPI`

Acedia tries to wrap a lot of base UnrealScript into its own types and classes
and avoids using classes like `PlayerController`, `Pawn` or types like `string`
as much as possible.
However sometimes it is necessary to work with those classes
(e.g. the needs of AcediaFixes module)
and `UnrealAPI` is an API that collects inside itself various convenience
methods for working with them.

While ideally this API would cover all the facets relevant to base UnrealScript
functionality, it's not really feasible to set this goal at any of the Acedia's
milestones.
It covers what it covers and will be expanded little-by-little along
the development, driven mostly by the needs of Acedia itself.
Whoever is reading this is also welcome to suggest adding functionality
they need.

## Connection service

While not exactly a part of an API, a related `Service` is `ConnectionService`
that is responsible for tracking player connections to the server.
You can use this `Service` to obtain a list of current connections with
`GetActiveConnections()` method or track getting or losing connection with
`OnConnectionEstablished()` / `OnConnectionLost()` signal functions.
Appropriate handlers only take `Connection` struct as a parameter,
that describes connection in question (stores `PlayerController`, ip address
and hash - usually steam ID).

You can get a link to an instance of `ConnectionService` the same way as with
any regular `Service`:
`ConnectionService(class'ConnectionService'.static.Require())`.

## Functions and signal methods defined directly in `UnrealAPI`

### Signals for `UnrealAPI`

| Signal | Description |
|--------|-------------|
|`OnTick(float, float)` | Called every. Its parameters are in-game time, passed since last tick, and current game's speed (default value is always `1.0`, not `1.1`). |
|`OnDestructionFor()` | This signal method takes an additional `Actor` parameter. Handler added with `OnDestructionFor()` will be called when that `Atcor` is destroyed. |

### Functions for `UnrealAPI`

| Function | Description |
|----------|-------------|
|`GetLevel()` | Returns current game's `LevelInfo`. |
|`GetGameRI()` | Returns current game's `GameReplicationInfo`. |
|`GetKFGameRI()` | Returns current game's `GameReplicationInfo` as `KFGameReplicationInfo`. |
|`GetGameType()` | Returns current game's `GameInfo`. |
|`GetKFGameType()` | Returns current game's `GameInfo` as `KFGameType`. |
|`FindActorInstance(class<Actor>)` | Searches all `Actor`s on the level for an instance of specific class and returns it. |
|`GetLocalPlayer()` | Returns current local player's `Controller`. |
|`GetInventoryFrom(class<Inventory>, Inventory, optional bool)` | Convenience method for finding a first inventory entry of the given class in the given inventory chain. |
|`GetAllInventoryFrom(class<Inventory>, Inventory, optional bool)` | Convenience method for finding a all inventory entries of the given class in the given inventory chain. |
|`ActorRef(optional Actor)` | Creates reference object to store a `Actor` value. |

## Functions and signal related to `GameRules`

`UnrealAPI` provides sub-API that can be accessed through `_.unreal.gameRules.`.
That API provides convenience methods for working with `GameRules` as well as
several signal functions for the `GameRules`'s events.

### Signals for `GameRules`

| Signal | Description |
|--------|-------------|
|`NavigationPoint OnFindPlayerStart(Controller, optional byte, optional string)` | Called when game decides on a player's spawn point. If a `NavigationPoint` is returned, signal propagation will be interrupted and returned value will be used as the player start. |
|`bool OnHandleRestartGame()` | Called in `GameInfo`'s `RestartGame()` method and allows to prevent game's restart. |
|`bool OnCheckEndGame(PlayerReplicationInfo, string)` | Allows modification of game ending conditions. Return `false` to prevent game from ending. |
|`bool OnCheckScore(PlayerReplicationInfo)` | Check if this score means the game ends. Return `true` to override `GameInfo`'s `CheckScore()`, or if game was ended (with a call to `Level.Game.EndGame()`). |
|`bool OnOverridePickupQuery(Pawn, Pickup, out byte)` | When pawn wants to pick something up, `GameRule`s are given a chance to modify it. If one of the `Slot`s returns `true`, `allowPickup` will determine if the object can be picked up. |
|`int OnNetDamage(int, int, Pawn, Pawn, Vector, out Vector, class<DamageType>)` | When pawn gets damaged, `GameRule`s are given a chance to modify that damage. |
|`bool OnPreventDeath(Pawn, Controller, class<DamageType>, Vector)` | When pawn is about to die, `GameRule`s are given a chance to prevent that. |
|`void OnScoreKill(Controller, Controller)` | Called when one `Pawn` kills another. |

### Functions for `GameRules`

| Function | Description |
|----------|-------------|
|`bool Add(class<GameRules>)` | Adds new `GameRules` class to the current `GameInfo`. Does nothing if give `GameRules` class was already added before. |
|`bool Remove(class<GameRules>)` | Removes given `GameRules` class from the current `GameInfo`, if they are active. Does nothing otherwise. |
|`GameRules FindInstance(class<GameRules>)` | Finds given class of `GameRules` if it's currently active in `GameInfo`. Returns `none` otherwise. |
|`bool AreAdded(class<GameRules>)` | Checks if given class of `GameRules` is currently active in `GameInfo`. |

## Functions and signal related to `BroadcastHandler`

`UnrealAPI` provides sub-API that can be accessed through `_.unreal.broadcast.`.
That API provides convenience methods for working with `BroadcastHandler`s
as well as several signal functions for the `BroadcastHandler`'s events.

This API also defines auxiliary struct `LocalizedMessage` that consists of all
the parameters usually sent along with localized messages and
enum `InjectionLevel` that describes way of adding another `BroadcastHandler`
into the game.

### Signals for `BroadcastHandler`

| Signal | Description |
|--------|-------------|
|`bool OnBroadcastCheck(Actor, int)` | Called before text message is sent to any player, during the check for whether it is at all allowed to be broadcasted. Corresponds to the `HandlerAllowsBroadcast()` method from `BroadcastHandler`. Return `false` to prevent message from being broadcast. |
|`bool OnHandleText(Actor, out string, name, bool)` | Called before text message is sent to any player, but after the check for whether it is at all allowed to be broadcasted. Corresponds to the `Broadcast()` or `BroadcastTeam()` method from `BroadcastHandler` if `BHIJ_Root` injection method was used and to `BroadcastText()` for `BHIJ_Registered`. Return `false` to prevent message from being broadcast. |
|`bool OnHandleTextFor(PlayerController receiver, Actor sender, string, name)` | Called before text message is sent to a particular player. Corresponds to the `BroadcastText()` method from `BroadcastHandler`. Return `false` to prevent message from being broadcast to a specified player. |
|`bool OnHandleLocalized(Actor, LocalizedMessage)` | Called before localized message is sent to any player. Corresponds to the `AllowBroadcastLocalized()` method from `BroadcastHandler` if `BHIJ_Root` injection method was used and to `BroadcastLocalized()` for `BHIJ_Registered`. Return `false` to prevent message from being broadcast. |
|`bool OnHandleLocalizedFor(PlayerController receiver, Actor sender, LocalizedMessage)` | Called before localized message is sent to a particular player. Corresponds to the `BroadcastLocalized()` method from `BroadcastHandler`. Return `false` to prevent message from being broadcast to a specified player. |

### Functions for `BroadcastHandler`

| Function | Description |
|----------|-------------|
|`bool Add(class<BroadcastHandler>, optional InjectionLevel)` | Adds new `BroadcastHandler` class to the current `GameInfo`. Does nothing if given `BroadcastHandler` class was already added before. |
|`bool Remove(class<BroadcastHandler>)` | Removes given `BroadcastHandler` class from the current `GameInfo`, if it is active. Does nothing otherwise. |
|`BroadcastHandler FindInstance(class<BroadcastHandler>)` | Finds given class of `BroadcastHandler` if it's currently active in `GameInfo`. Returns `none` otherwise. |
|`bool IsAdded(class<GameRules>)` | Checks if given class of `BroadcastHandler` is currently active in `GameInfo`. |

## Functions and signal related to `Mutator`

`UnrealAPI` provides sub-API that can be accessed through `_.unreal.mutator.`.
That API provides a couple  signal functions for the `Mutator`'s events.

### Signals for `Mutator`

| Signal | Description |
|--------|-------------|
|`bool OnCheckReplacement(Actor, out byte)` | Called whenever mutators (Acedia's mutator) is asked to check whether an `Actor` should be replaced. This check is done right after that `Actor` has spawned. |
|`OnMutate(string, PlayerController)` | Called on a server whenever a player uses a "mutate" console command. |
