---@meta
--- Trailmakers Modding API


---Table of Enum types
---@class ModApiEnums
tm.enums = {}

---@enum ModRespawnReason
tm.enums.respawnReason = {
    death = "DEATH",
    respawn = "RESPAWN",
    killed = "KILLED",
    ejectedFromSeat = "EJECTEDFROMSEAT",
    teleport = "TELEPORT"
}

---@enum ModDamageType
tm.enums.damageType = {
    generic = "Generic",
    impact = "Impact",
    explosion = "Explosion",
    lava = "Lava",
    projectile = "Projectile",
    electric = "Electric",
    jointTear= "JointTear",
    exitSeat = "ExitSeat",
    emp = "Emp",
    spaceBlaster = "SpaceBlaster",
    mechanicalFailure = "MechanicalFailure",
    harvestBasic = "HarvestBasic",
    harvestMineral = "HarvestMineral",
    harvestMineralTwo = "HarvestMineral2",
    harvestOrganic = "HarvestOrganic"
}

---@enum ModPhysicalMaterial
tm.enums.physicsMaterial = {
    metal = "Metal",
    sand = "Sand",
    stone = "Stone",
    gravel = "Gravel",
    grass = "Grass",
    mud = "Mud",
    lava = "Lava",
    asphalt = "Asphalt",
    snow = "Snow",
    wood = "Wood",
    yellowSand = "YellowSand",
    witheredGrass = "WitheredGrass",
    iceSlippery = "IceSlippery",
    tundra = "Tundra",
    snowHard = "SnowHard",
    grassYellow = "GrassYellow"
}

---OS-level functionality
---@class ModApiTmOs
tm.os = {}

---Loads and executes a Lua file from the mod's static data directory (data_static) using Lua's native dofile. The filename must NOT include the .lua extension. Subdirectory paths are not supported.
---@param filename string
---@return any
function tm.os.DoFile(filename) end


---Read all text of a file in the mods static data directory. Files in the static data directory can only be read and NOT written to.
---@param path string
---@return string
function tm.os.ReadAllText_Static(path) end


---Read all text of a file in the mods dynamic data directory. Files in the dynamic data directory can be both read and written to. The dynamic data directory will NOT be uploaded, to the steam workshop, when you upload your mod. When a mod is run through the steam workshop, the dynamic data, unlike static data, is not located in the steam workshop directory but is located in the stream user data directory instead.
---@param path string
---@return string
function tm.os.ReadAllText_Dynamic(path) end


---Create or overwrite a file in the mods dynamic data directory. Files in the dynamic data directory can be both read and written to. The dynamic data directory will NOT be uploaded, to the steam workshop, when you upload your mod. When a mod is run through the steam workshop, the dynamic data, unlike static data, is not located in the steam workshop directory, but is located in the stream user data directory instead.
---@param path string
---@param stringToWrite string
---@return nil
function tm.os.WriteAllText_Dynamic(path, stringToWrite) end


---Emit a log message
---@param message string
---@return nil
function tm.os.Log(message) end


---Get time game has been playing in seconds. Equivalent to 'UnityEngine.Time.time'
---@return number
function tm.os.GetTime() end


---Get the time since the game has started in seconds. Equivalent to 'UnityEngine.Time.realtimeSinceStartup'
---@return number
function tm.os.GetRealtimeSinceStartup() end


---Get the time since last update
---@return number
function tm.os.GetModDeltaTime() end


---Determines how often the mod gets updated. "1/60" means 60 times per second. Can't update faster than the game
---@param targetDeltaTime number
---@return nil
function tm.os.SetModTargetDeltaTime(targetDeltaTime) end


---Returns the target delta time for the mod
---@return number
function tm.os.GetModTargetDeltaTime() end


---Returns true if session is in singleplayer
---@return boolean
function tm.os.IsSingleplayer() end


---Environment, Physics, Time, Assets and Objects.
---@class ModApiPhysics
tm.physics = {}

---Set the physics timescale
---@param speed number
---@return nil
function tm.physics.SetTimeScale(speed) end


---Get the physics timescale
---@return number
function tm.physics.GetTimeScale() end


---Deprecated: Set the physics gravity in the down direction
---@param strength number
---@return nil
function tm.physics.SetGravity(strength) end


---Set the gravity multiplier. Has no effect in zero G locations. For example, setting the multiplier to 2 doubles gravity
---@param multiplier number
---@return nil
function tm.physics.SetGravityMultiplier(multiplier) end


---Deprecated: Set the physics gravity as per the provided vector
---@param gravity ModVector3
---@return nil
function tm.physics.SetGravity(gravity) end


---Deprecated: Get the physics gravity
---@return ModVector3
function tm.physics.GetGravity() end


---Get the gravity multiplier
---@return number
function tm.physics.GetGravityMultiplier() end


---Spawn a spawnable at the position, e.g. PFB_Barrel
---@param position ModVector3
---@param name string
---@return ModGameObject
function tm.physics.SpawnObject(position, name) end


---Despawn all spawned objects from this mod
---@return nil
function tm.physics.ClearAllSpawns() end


---Despawn a spawnable e.g. PFB_Barrel
---@param gameObject ModGameObject
---@return nil
function tm.physics.DespawnObject(gameObject) end


---Get a list of all possible spawnable names
---@return string[]
function tm.physics.SpawnableNames() end


---@class ModBlockMetaData
---@field GetName fun(): string
---@field GetGuid fun(): string
---@field GetDescription fun(): string

---Returns all block metadata
---@return ModBlockMetaData[]
function tm.physics.GetAllBlockMetaData() end


---Removes the physics timescale
---@return nil
function tm.physics.RemoveTimeScale() end


---Add a mesh to all clients, note this will have to be sent to the client when they join
---@param filename string
---@param resourceName string
---@return nil
function tm.physics.AddMesh(filename, resourceName) end


---Add a texture to all clients, note this will have to be sent to the client when they join
---@param filename string
---@param resourceName string
---@return nil
function tm.physics.AddTexture(filename, resourceName) end


---Spawn a custom physics object where mesh and texture have to be set by AddMesh and AddTexture.
---@param position ModVector3
---@param meshName string
---@param textureName string
---@param isKinematic boolean
---@param mass number
---@param physicsMaterial string
---@return ModGameObject
function tm.physics.SpawnCustomObjectRigidbody(position, meshName, textureName, isKinematic, mass, physicsMaterial) end


---Spawn a custom object where mesh and texture have to be set by AddMesh and AddTexture.
---@param position ModVector3
---@param meshName string
---@param textureName string
---@param physicsMaterial string
---@return ModGameObject
function tm.physics.SpawnCustomObject(position, meshName, textureName, physicsMaterial) end


---Same as SpawnCustomObject BUT adds concave collision support.
---@param position ModVector3
---@param meshName string
---@param textureName string
---@param physicsMaterial string
---@return ModGameObject
function tm.physics.SpawnCustomObjectConcave(position, meshName, textureName, physicsMaterial) end


---Spawn a box trigger that will detect overlap but will not interact with physics.
---@param position ModVector3
---@param size ModVector3
---@return ModGameObject
function tm.physics.SpawnBoxTrigger(position, size) end


---Sets the build complexity value. Default value is 700 and values above it can make the game unstable
---@param value number
---@return nil
function tm.physics.SetBuildComplexity(value) end


---Registers a function to the collision enter callback of a game object
---@param targetObject ModGameObject
---@param functionName string
---@return function
function tm.physics.RegisterFunctionToCollisionEnterCallback(targetObject, functionName) end


---Registers a function to the collision exit callback of a game object
---@param targetObject ModGameObject
---@param functionName string
---@return function
function tm.physics.RegisterFunctionToCollisionExitCallback(targetObject, functionName) end


---Returns a bool if raycast hit something. arguments get overwritten with raycast data
---@param origin ModVector3
---@param direction ModVector3
---@param hitPositionOut ModVector3
---@param maxDistance number
---@param ignoreTriggers boolean
---@return boolean
function tm.physics.Raycast(origin, direction, hitPositionOut, maxDistance, ignoreTriggers) end


---Returns a ModRaycastHit
---@param origin ModVector3
---@param direction ModVector3
---@param maxDistance number
---@param ignoreTriggers boolean
---@return ModRaycastHit
function tm.physics.RaycastData(origin, direction, maxDistance, ignoreTriggers) end


---Returns the internal name for the current map
---@return string
function tm.physics.GetMapName() end


---Deprecated: Returns the wind velocity at a position
---@param position ModVector3
---@return ModVector3
function tm.physics.GetWindVelocityAtPosition(position) end


---Represents an in-game player.
---@class ModApiPlayers
---Event triggered when a player joins the server
---@class OnPlayerJoinedEvent
---@field add fun(callback: fun(player: ModPlayer)): nil
---@field remove fun(callback: fun(player: ModPlayer)): nil
tm.players.OnPlayerJoined = {}

---Event triggered when a player leaves the server
---@class OnPlayerLeftEvent
---@field add fun(callback: fun(player: ModPlayer)): nil
---@field remove fun(callback: fun(player: ModPlayer)): nil
tm.players.OnPlayerLeft = {}

---Event triggered when a player dies
---@class OnPlayerDiedEvent
---@field add fun(callback: fun(player: ModPlayer, damage: ModDamage)): nil
---@field remove fun(callback: fun(player: ModPlayer, damage: ModDamage)): nil
tm.players.OnPlayerDied = {}

---Event triggered when a player exits a structure
---@class OnPlayerExitSeatEvent
---@field add fun(callback: fun(player: ModPlayer)): nil
---@field remove fun(callback: fun(player: ModPlayer)): nil
tm.players.OnPlayerExitSeat = {}

---Event triggered when a player enters a structure
---@class OnPlayerEnterSeatEvent
---@field add fun(callback: fun(player: ModPlayer)): nil
---@field remove fun(callback: fun(player: ModPlayer)): nil
tm.players.OnPlayerEnterSeat = {}

---Event triggered when a player spawns
---@class OnPlayerSpawnedEvent
---@field add fun(callback: fun(player: ModPlayer, respawnReason: ModRespawnReason)): nil
---@field remove fun(callback: fun(player: ModPlayer, respawnReason: ModRespawnReason)): nil
tm.players.OnPlayerSpawned = {}

---Event triggered when a player flips a structure
---@class OnPlayerFlipStructureEvent
---@field add fun(callback: fun(player: ModPlayer, structure: ModStructure)): nil
---@field remove fun(callback: fun(player: ModPlayer, structure: ModStructure)): nil
tm.players.OnPlayerFlipStructure = {}

---Event triggered when a player repairs a structure
---@class OnPlayerRepairStructureEvent
---@field add fun(callback: fun(player: ModPlayer, structure: ModStructure)): nil
---@field remove fun(callback: fun(player: ModPlayer, structure: ModStructure)): nil
tm.players.OnPlayerRepairStructure = {}

---Event triggered when a player kills another player
---@class OnPlayerKilledPlayerEvent
---@field add fun(callback: fun(player: ModPlayer, damage: ModDamage, killedPlayer: ModPlayer)): nil
---@field remove fun(callback: fun(player: ModPlayer, damage: ModDamage, killedPlayer: ModPlayer)): nil
tm.players.OnPlayerKilledPlayer = {}

---Event triggered when a player changes to another team
---@class OnPlayerTeamChangedEvent
---@field add fun(callback: fun(player: ModPlayer, newTeamId: number)): nil
---@field remove fun(callback: fun(player: ModPlayer, newTeamId: number)): nil
tm.players.OnPlayerTeamChanged = {}

---Event triggered when a player enters the builder
---@class OnPlayerEnterBuilder
---@field add fun(callback: fun(player: ModPlayer)): nil
---@field remove fun(callback: fun(player: ModPlayer)): nil
tm.players.OnPlayerEnterBuilder = {}

---Event triggered when a player exits the builder
---@class OnPlayerExitBuilder
---@field add fun(callback: fun(player: ModPlayer)): nil
---@field remove fun(callback: fun(player: ModPlayer)): nil
tm.players.OnPlayerExitBuilder = {}

tm.players = {}

---Get all players currently connected to the server
---@return ModPlayer[]
function tm.players.CurrentPlayers() end


---Forcefully disconnect a given player
---@param playerId number
---@return nil
function tm.players.Kick(playerId) end


---Is player administrator
---@param playerId number
---@return boolean
function tm.players.IsPlayerAdministrator(playerId) end


---Get players unique profile id
---@param playerId number
---@return string
function tm.players.GetPlayerProfileId(playerId) end


---Get the transform of a player
---@param playerId number
---@return ModTransform
function tm.players.GetPlayerTransform(playerId) end


---Get the GameObject of a player
---@param playerId number
---@return ModGameObject
function tm.players.GetPlayerGameObject(playerId) end


---Returns true if the player is in a seat
---@param playerId number
---@return boolean
function tm.players.IsPlayerInSeat(playerId) end


---Forces a player to exit their seat
---@param playerId number
---@return nil
function tm.players.ForceExitSeat(playerId) end


---Returns ModStructure of the seat the player is in, or null if not in a seat
---@param playerId number
---@return ModStructure
function tm.players.OccupiedStructure(playerId) end


---Kills a player
---@param playerId number
---@return nil
function tm.players.KillPlayer(playerId) end


---Checks if player can be killed
---@param playerId number
---@return boolean
function tm.players.CanKillPlayer(playerId) end


---Sets the invincibility status of a player
---@param playerId number
---@param enabled boolean
---@return nil
function tm.players.SetPlayerIsInvincible(playerId, enabled) end


---Enables and disables the jetpack
---@param playerId number
---@param enabled boolean
---@return nil
function tm.players.SetJetpackEnabled(playerId, enabled) end


---Get all structure(s) owned by that player
---@param playerId number
---@return ModStructure[]
function tm.players.GetPlayerStructures(playerId) end


---Get structure by Id
---@param structureId string
---@return ModStructure[]
function tm.players.GetSpawnedStructureById(structureId) end


---Get the structure(s) currently in build mode for a player
---@param playerId number
---@return ModStructure[]
function tm.players.GetPlayerStructuresInBuild(playerId) end


---Get the last selected block in the builder for that player. Returns `nil` if the player hasn't selected a block in the current session. Dragging blocks doesn't count as selecting them. When multiple blocks are selected, only the first selected block is returned
---@param playerId number
---@return ModBlock
function tm.players.GetPlayerSelectBlockInBuild(playerId) end


---Get the player's name
---@param playerId number
---@return string
function tm.players.GetPlayerName(playerId) end


---Get the player's team index
---@param playerId number
---@return number
function tm.players.GetPlayerTeam(playerId) end


---Set the player's team index
---@param playerId number
---@param teamID number
---@return nil
function tm.players.SetPlayerTeam(playerId, teamID) end


---Returns the highest team index allowed
---@return number
function tm.players.GetMaxTeamIndex() end


---Returns true if the player is in build mode
---@param playerId number
---@return boolean
function tm.players.GetPlayerIsInBuildMode(playerId) end


---Set block limit for a specific block type, 0 means the block will be banned
---@param blockTypeGuid string
---@param limit number
---@return nil
function tm.players.SetBlockLimit(blockTypeGuid, limit) end


---Remove any ban and limit for a specific block type, restoring it to unlimited
---@param blockTypeGuid string
---@return nil
function tm.players.UnbanBlock(blockTypeGuid) end


---Add a camera. THERE CAN ONLY BE 1 CAMERA PER PLAYER!
---@param playerId number
---@param position ModVector3
---@param rotation ModVector3
---@param priority number
---@return nil
function tm.players.AddCamera(playerId, position, rotation, priority) end


---Remove a camera. THERE CAN ONLY BE 1 CAMERA PER PLAYER!
---@param playerId number
---@return nil
function tm.players.RemoveCamera(playerId) end


---Set camera position.
---@param playerId number
---@param position ModVector3
---@return nil
function tm.players.SetCameraPosition(playerId, position) end


---Set camera rotation.
---@param playerId number
---@param rotation ModVector3
---@return nil
function tm.players.SetCameraRotation(playerId, rotation) end


---Activate a camera with fade-in.
---@param playerId number
---@param fadeInDuration number
---@return nil
function tm.players.ActivateCamera(playerId, fadeInDuration) end


---Deactivate a camera with fade-out.
---@param playerId number
---@param fadeOutDuration number
---@return nil
function tm.players.DeactivateCamera(playerId, fadeOutDuration) end


---Spawn a structure for a player with given blueprint, position and rotation.
---@param playerId number
---@param blueprint string
---@param structureId string
---@param position ModVector3
---@param rotation ModVector3
---@return nil
function tm.players.SpawnStructure(playerId, blueprint, structureId, position, rotation) end


---Despawn a structure
---@param structureId string
---@return nil
function tm.players.DespawnStructure(structureId) end


---Places the player in the seat of a structure.
---@param playerId number
---@param structureId string
---@return nil
function tm.players.PlacePlayerInSeat(playerId, structureId) end


---Set if the builder for a player should be enabled.
---@param playerId number
---@param isEnabled boolean
---@return nil
function tm.players.SetBuilderEnabled(playerId, isEnabled) end


---Set if repairing for a player should be enabled. Also enables/disables transform.
---@param playerId number
---@param isEnabled boolean
---@return nil
function tm.players.SetRepairEnabled(playerId, isEnabled) end


---Checks if building is enabled for a player.
---@param playerId number
---@return boolean
function tm.players.GetBuilderEnabled(playerId) end


---Checks if repairing is enabled for a player.
---@param playerId number
---@return boolean
function tm.players.GetRepairEnabled(playerId) end


---Returns the block the player is seated in.
---@param playerId number
---@return ModBlock
function tm.players.GetPlayerSeatBlock(playerId) end


---Sets the spawn location the player should use when respawning. Will be overwritten if another spawn location is set, eg checkpoints on the map.
---@param playerId number
---@param spawnLocationId string
---@return nil
function tm.players.SetPlayerSpawnLocation(playerId, spawnLocationId) end


---Sets the position and rotation of the spawn point for a player ID at a given spawn location. Each spawn location is a group of spawn points, one for each player ID. spawnLocationId = id of the spawn location. playerId = player ID for which the spawn point will be used when respawning at the location
---@param playerIndex number
---@param spawnLocationId string
---@param position ModVector3
---@param rotation ModVector3
---@return nil
function tm.players.SetSpawnPoint(playerIndex, spawnLocationId, position, rotation) end


---Spawns a player to the selected spawn point holder to the specific spawn point id provided. To teleport all players use "TeleportAllPlayersToSpawnPoint". Set "keepStructure" to true and it will try to keep the structure when teleporting.
---@param playerId number
---@param spawnPointId string
---@param keepStructure boolean
---@return nil
function tm.players.TeleportPlayerToSpawnPoint(playerId, spawnPointId, keepStructure) end


---Spawns ALL players to the selected spawn point holder to the specific spawn point id provided. Use this to move up to 8 players to their spawn position. Set "keepStructure" to true and it will try to keep the structure when teleporting.
---@param spawnPointId string
---@param keepStructure boolean
---@return nil
function tm.players.TeleportAllPlayersToSpawnPoint(spawnPointId, keepStructure) end


---Gets the primary block color of a player.
---@param playerId number
---@return ModColor
function tm.players.GetPrimaryBlockColor(playerId) end


---Gets the secondary block color of a player.
---@param playerId number
---@return ModColor
function tm.players.GetSecondaryBlockColor(playerId) end


---Returns the structure the player is currently targeting or standing near. Returns nil if no structure.
---@param playerId number
---@return ModStructure
function tm.players.GetPlayerSelectedStructure(playerId) end


---UI Window.
---@class ModApiPlayerUI
---Event triggered when a player sends a chat message
---@class OnChatMessageEvent
---@field add fun(callback: fun(senderName: string, message: string, color: ModColor)): nil
---@field remove fun(callback: fun(senderName: string, message: string, color: ModColor)): nil
tm.playerUI.OnChatMessage = {}

tm.playerUI = {}

---Send a message to chat. The message will be sent to all players in the game. Ignored in singleplayer.
---@param senderName string
---@param message string
---@param color ModColor
---@return nil
function tm.playerUI.SendChatMessage(senderName, message, color) end


---Add a button to the clients mod UI
---@param playerId number
---@param id string
---@param defaultValue string
---@param callback function
---@param data any
---@return nil
function tm.playerUI.AddUIButton(playerId, id, defaultValue, callback, data) end


---Add a text field to the clients mod UI
---@param playerId number
---@param id string
---@param defaultValue string
---@param callback function
---@param data any
---@return nil
function tm.playerUI.AddUIText(playerId, id, defaultValue, callback, data) end


---Add a label to the clients mod UI
---@param playerId number
---@param id string
---@param defaultValue string
---@return nil
function tm.playerUI.AddUILabel(playerId, id, defaultValue) end


---Remove an UI element
---@param playerId number
---@param id string
---@return nil
function tm.playerUI.RemoveUI(playerId, id) end


---Set the value of a clients ui element
---@param playerId number
---@param id string
---@param value string
---@return nil
function tm.playerUI.SetUIValue(playerId, id, value) end


---Remove all UI elements for that player
---@param playerId number
---@return nil
function tm.playerUI.ClearUI(playerId) end


---Adds a subtle message for a specific player. Optional duration of the message and path to custom sprite icon can be added <spriteAssetName>. String limits 32 characters.
---@param playerId number
---@param header string
---@param message string
---@param duration number
---@param spriteAssetName string
---@return string
function tm.playerUI.AddSubtleMessageForPlayer(playerId, header, message, duration, spriteAssetName) end


---Adds a subtle message for ALL player. Optional duration of the message and path to custom sprite icon can be added <spriteAssetName>. String limits 32 characters.
---@param header string
---@param message string
---@param duration number
---@param spriteAssetName string
---@return string
function tm.playerUI.AddSubtleMessageForAllPlayers(header, message, duration, spriteAssetName) end


---Shows an intrusive message for a specific player. Optional duration of the message can be added, default is 3 seconds.
---@param playerId number
---@param header string
---@param message string
---@param duration number
---@return nil
function tm.playerUI.ShowIntrusiveMessageForPlayer(playerId, header, message, duration) end


---Shows an intrusive message for ALL players. Optional duration of the message can be added, default is 3 seconds.
---@param header string
---@param message string
---@param duration number
---@return nil
function tm.playerUI.ShowIntrusiveMessageForAllPlayers(header, message, duration) end


---Removes a subtle message for a player
---@param playerId number
---@param id string
---@return nil
function tm.playerUI.RemoveSubtleMessageForPlayer(playerId, id) end


---Removes a subtle message for ALL players
---@param id string
---@return nil
function tm.playerUI.RemoveSubtleMessageForAll(id) end


---Update the header of a subtle message for a player
---@param playerId number
---@param id string
---@param newHeader string
---@return nil
function tm.playerUI.SubtleMessageUpdateHeaderForPlayer(playerId, id, newHeader) end


---Update the header of a subtle message for all players
---@param id string
---@param newHeader string
---@return nil
function tm.playerUI.SubtleMessageUpdateHeaderForAll(id, newHeader) end


---Update the message of a subtle message
---@param playerId number
---@param id string
---@param newMessage string
---@return nil
function tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, id, newMessage) end


---Update the message of a subtle message for ALL players
---@param id string
---@param newMessage string
---@return nil
function tm.playerUI.SubtleMessageUpdateMessageForAll(id, newMessage) end


---Registers a function callback to get the world position of the cursor when left mouse button is clicked
---@param playerId number
---@param callback function
---@return function
function tm.playerUI.RegisterMouseDownPositionCallback(playerId, callback) end


---Deregisters a function callback to get the world position of the cursor when left mouse button is clicked
---@param playerId number
---@param callback function
---@return function
function tm.playerUI.DeregisterMouseDownPositionCallback(playerId, callback) end


---Show cursor world position in the UI
---@return nil
function tm.playerUI.ShowCursorWorldPosition() end


---Hide cursor world position in the UI
---@return nil
function tm.playerUI.HideCursorWorldPosition() end


---Audio played in-game world.
---@class ModApiAudio
tm.audio = {}

---Play audio at a position. This is more cost friendly but you can not stop or move the sound
---@param audioName string
---@param position ModVector3
---@param keepObjectDuration number
---@return nil
function tm.audio.PlayAudioAtPosition(audioName, position, keepObjectDuration) end


---Play audio on a Gameobject
---@param audioName string
---@param modGameObject ModGameObject
---@return nil
function tm.audio.PlayAudioAtGameobject(audioName, modGameObject) end


---Stop all audio on a Gameobject
---@param modGameObject ModGameObject
---@return nil
function tm.audio.StopAllAudioAtGameobject(modGameObject) end


---Returns a list of all playable audio names
---@return string[]
function tm.audio.GetAudioNames() end


---Input interaction from players.
---@class ModApiInput
---Event triggered when a player presses a key
---@class OnPlayerKeyDownEvent
---@field add fun(callback: fun(player: ModPlayer, keyName: string)): nil
---@field remove fun(callback: fun(player: ModPlayer, keyName: string)): nil
tm.input.OnPlayerKeyDown = {}

---Event triggered when a player releases a key
---@class OnPlayerKeyUpEvent
---@field add fun(callback: fun(player: ModPlayer, keyName: string)): nil
---@field remove fun(callback: fun(player: ModPlayer, keyName: string)): nil
tm.input.OnPlayerKeyUp = {}

tm.input = {}

---Registers a function to the callback of when the given player presses the given key
---@param playerId number
---@param functionName string
---@param keyName string
---@return function
function tm.input.RegisterFunctionToKeyDownCallback(playerId, functionName, keyName) end


---Registers a function to the callback of when the given player releases the given key
---@param playerId number
---@param functionName string
---@param keyName string
---@return function
function tm.input.RegisterFunctionToKeyUpCallback(playerId, functionName, keyName) end


---A 3-axis vector (position, rotation, scale, etc.)
---@class ModVector3
---@field x number
---@field y number
---@field z number
tm.vector3 = {}

---Creates a vector3 from a string. String should be formatted as "(x, y, z)". Example input: "(4.5, 6, 10.8)" 
---@param input string
---@return ModVector3
function tm.vector3.Create(input) end


---Creates a vector3 with specified values
---@param x number
---@param y number
---@param z number
---@return ModVector3
function tm.vector3.Create(x, y, z) end


---Creates a vector3 with values defaulted to zero
---@return ModVector3
function tm.vector3.Create() end


---Creates a vector3 pointing right. 1,0,0
---@return ModVector3
function tm.vector3.Right() end


---Creates a vector3 pointing left. -1,0,0
---@return ModVector3
function tm.vector3.Left() end


---Creates a vector3 pointing up. 0,1,0
---@return ModVector3
function tm.vector3.Up() end


---Creates a vector3 pointing down. 0,-1,0
---@return ModVector3
function tm.vector3.Down() end


---Creates a vector3 pointing forward. 0,0,1
---@return ModVector3
function tm.vector3.Forward() end


---Creates a vector3 pointing back. 0,0,-1
---@return ModVector3
function tm.vector3.Back() end


---No description
---@param vector3 ModVector3
---@return ModVector3
function tm.vector3.op_UnaryNegation(vector3) end


---No description
---@param first ModVector3
---@param second ModVector3
---@return ModVector3
function tm.vector3.op_Addition(first, second) end


---No description
---@param first ModVector3
---@param second ModVector3
---@return ModVector3
function tm.vector3.op_Subtraction(first, second) end


---No description
---@param vector3 ModVector3
---@param scaler number
---@return ModVector3
function tm.vector3.op_Multiply(vector3, scaler) end


---No description
---@param vector3 ModVector3
---@param divisor number
---@return ModVector3
function tm.vector3.op_Division(vector3, divisor) end


---No description
---@param first ModVector3
---@param second ModVector3
---@return boolean
function tm.vector3.op_Equality(first, second) end


---No description
---@param obj Object
---@return boolean
function tm.vector3.Equals(obj) end


---No description
---@param first ModVector3
---@param second ModVector3
---@return boolean
function tm.vector3.op_Inequality(first, second) end


---No description
---@return number
function tm.vector3.GetHashCode() end


---No description
---@return string
function tm.vector3.ToString() end


---returns the dot product of two vector3
---@param otherVector ModVector3
---@return number
function tm.vector3.Dot(otherVector) end


---returns the cross product of two vector3
---@param otherVector ModVector3
---@return ModVector3
function tm.vector3.Cross(otherVector) end


---returns the magnitude/length
---@return number
function tm.vector3.Magnitude() end


---Calculate a position between the points specified by current and target, moving no farther than the distance specified by maxDistanceDelta.
---@param vector ModVector3
---@param otherVector ModVector3
---@param maxDistanceDelta number
---@return ModVector3
function tm.vector3.MoveTowards(vector, otherVector, maxDistanceDelta) end


---Calculates the angle in degrees between the vector from and another vector.
---@param vector ModVector3
---@param otherVector ModVector3
---@return number
function tm.vector3.Angle(vector, otherVector) end


---Returns the distance between the ModVector and another vector.
---@param vector ModVector3
---@param otherVector ModVector3
---@return number
function tm.vector3.Distance(vector, otherVector) end


---Linearly interpolates between two vectors.
---@param vector ModVector3
---@param otherVector ModVector3
---@param t number
---@return ModVector3
function tm.vector3.Lerp(vector, otherVector, t) end


---A quaternion rotation.
---@class ModQuaternion
---@field x number
---@field y number
---@field z number
---@field w number
tm.quaternion = {}

---Creates a quaternion by manually defining its components
---@param x number
---@param y number
---@param z number
---@param w number
---@return ModQuaternion
function tm.quaternion.Create(x, y, z, w) end


---Creates a quaternion using euler angle components
---@param x number
---@param y number
---@param z number
---@return ModQuaternion
function tm.quaternion.Create(x, y, z) end


---Creates a quaternion using a euler angle vector3
---@param eulerAngle ModVector3
---@return ModQuaternion
function tm.quaternion.Create(eulerAngle) end


---Creates a quaternion using an angle and an axis to rotate around
---@param angle number
---@param axis ModVector3
---@return ModQuaternion
function tm.quaternion.Create(angle, axis) end


---returns a vector3 representing the euler angles of the quaternion
---@return ModVector3
function tm.quaternion.GetEuler() end


---Multiplies this quaternion with another quaternion and returns the resulting rotation
---@param otherQuaternion ModQuaternion
---@return ModQuaternion
function tm.quaternion.Multiply(otherQuaternion) end


---Returns the resulting quaternion from a lerp between two quaternions
---@param firstQuaternion ModQuaternion
---@param secondQuaternion ModQuaternion
---@param t number
---@return ModQuaternion
function tm.quaternion.Lerp(firstQuaternion, secondQuaternion, t) end


---Returns the resulting quaternion from a slerp between two quaternions
---@param firstQuaternion ModQuaternion
---@param secondQuaternion ModQuaternion
---@param t number
---@return ModQuaternion
function tm.quaternion.Slerp(firstQuaternion, secondQuaternion, t) end


---Returns a quaternion with all components negated
---@return ModQuaternion
function tm.quaternion.Negate() end


---Adds together two quaternions component-wise
---@param other ModQuaternion
---@return ModQuaternion
function tm.quaternion.Add(other) end


---Subtracts two quaternions from each other component-wise
---@param other ModQuaternion
---@return ModQuaternion
function tm.quaternion.Subtract(other) end


---Multiplies all quaternion components by a scalar
---@param scalar number
---@return ModQuaternion
function tm.quaternion.Multiply(scalar) end


---Divides all quaternion components by a scalar
---@param scalar number
---@return ModQuaternion
function tm.quaternion.Divide(scalar) end


---Returns the inverse rotation of this quaternion
---@return ModQuaternion
function tm.quaternion.Inverse() end


---Converts this quaternion to a quaternion with the same orientation but with a magnitude of 1.0.
---@return ModQuaternion
function tm.quaternion.Normalize() end


---No description
---@param a ModQuaternion
---@param b ModQuaternion
---@return boolean
function tm.quaternion.op_Equality(a, b) end


---No description
---@param a ModQuaternion
---@param b ModQuaternion
---@return boolean
function tm.quaternion.op_Inequality(a, b) end


---No description
---@param obj Object
---@return boolean
function tm.quaternion.Equals(obj) end


---No description
---@return number
function tm.quaternion.GetHashCode() end


---No description
---@return string
function tm.quaternion.ToString() end


---Represents a color
---@class ModColor
tm.color = {}

---No description
---@return ModColor
function tm.color.Create() end


---No description
---@param r number
---@param g number
---@param b number
---@param a number
---@return ModColor
function tm.color.Create(r, g, b, a) end


---No description
---@return string
function tm.color.ToString() end


---Returns the red channel of the ModColor
---@return number
function tm.color.R() end


---Returns the green channel of the ModColor
---@return number
function tm.color.G() end


---Returns the blue channel of the ModColor
---@return number
function tm.color.B() end


---Returns the alpha channel of the ModColor
---@return number
function tm.color.A() end


---Returns a ModColor set to white (1, 1, 1)
---@return ModColor
function tm.color.White() end


---Returns a ModColor set to black (0, 0, 0)
---@return ModColor
function tm.color.Black() end


---Returns a ModColor set to red (1, 0, 0)
---@return ModColor
function tm.color.Red() end


---Returns a ModColor set to green (0, 1, 0)
---@return ModColor
function tm.color.Green() end


---Returns a ModColor set to blue (0, 0, 1)
---@return ModColor
function tm.color.Blue() end


---Returns a ModColor set to yellow (1, 0.92, 0.016)
---@return ModColor
function tm.color.Yellow() end


---Returns a ModColor set to cyan (0, 1, 1)
---@return ModColor
function tm.color.Cyan() end


---Returns a ModColor set to magenta (1, 0, 1)
---@return ModColor
function tm.color.Magenta() end


---Returns a ModColor set to gray (0.5, 0.5, 0.5)
---@return ModColor
function tm.color.Gray() end


---Returns a ModColor set to gray (0, 0, 0, 0)
---@return ModColor
function tm.color.Clear() end


---Linear interpolation between two ModColor
---@param a ModColor
---@param b ModColor
---@param t number
---@return ModColor
function tm.color.Lerp(a, b, t) end


---No description
---@param hue number
---@param saturation number
---@param value number
---@return ModColor
function tm.color.HSVToRGB(hue, saturation, value) end


---No description
---@param first ModColor
---@param second ModColor
---@return boolean
function tm.color.op_Equality(first, second) end


---No description
---@param obj Object
---@return boolean
function tm.color.Equals(obj) end


---No description
---@param first ModColor
---@param second ModColor
---@return boolean
function tm.color.op_Inequality(first, second) end


---No description
---@return number
function tm.color.GetHashCode() end


---Callback data for when user is interacting with UI elements.
---@class UICallbackData
---@field playerId number number
---@field id string string
---@field type string string
---@field value string string
---@field data any any
tm.UICallbackData = {}

---Represents the current world.
---@class ModApiWorld
tm.world = {}

---Set a global wind velocity. The wind velocity is a vector in world space, where the x, y and z components represent the wind direction and speed
---@param windVelocity ModVector3
---@return nil
function tm.world.SetGlobalWind(windVelocity) end


---Returns the wind velocity at a position
---@param position ModVector3
---@return ModVector3
function tm.world.GetWindVelocityAtPosition(position) end


---Set time of day. (0-100). No effect if time is paused.
---@param percentage number
---@return nil
function tm.world.SetTimeOfDay(percentage) end


---Get time of day. (0-100)
---@return number
function tm.world.GetTimeOfDay() end


---Set if time of day should be paused or not.
---@param isPaused boolean
---@return nil
function tm.world.SetPausedTimeOfDay(isPaused) end


---Set the cycle duration (seconds how fast a day goes by) for time of day.
---@param duration number
---@return nil
function tm.world.SetCycleDurationTimeOfDay(duration) end


---Returns if the time of day is currently paused
---@return boolean
function tm.world.IsTimeOfDayPaused() end


tm = {}

---Generates Trailmakers Mods API Lua Docs
---@return string
function tm.GetDocs() end


---Class representing a player
---@class ModPlayer
---@field connectionId string
---@field playerId number
---@field playerProfileId string
---@field playerName string
---@field teamId number
ModPlayer = {}

---GameObjects in the game environment.
---@class ModGameObject
ModGameObject = {}

---Despawns the object. This can not be done on players
---@return nil
function ModGameObject.Despawn() end


---Returns the gameObjects transform
---@return ModTransform
function ModGameObject.GetTransform() end


---Sets visibility of the gameObject
---@param isVisible boolean
---@return nil
function ModGameObject.SetIsVisible(isVisible) end


---Gets visibility of the gameObject
---@return boolean
function ModGameObject.GetIsVisible() end


---Returns true if the gameObject or any of its children are rigidbodies
---@return boolean
function ModGameObject.GetIsRigidbody() end


---Sets the gameObjects, and its childrens, rigidbodies to be static or not
---@param isStatic boolean
---@return nil
function ModGameObject.SetIsStatic(isStatic) end


---Returns true if the gameObject, and all of its children, are static
---@return boolean
function ModGameObject.GetIsStatic() end


---Determines whether the gameObject lets other gameobjects pass through its colliders or not
---@param isTrigger boolean
---@return nil
function ModGameObject.SetIsTrigger(isTrigger) end


---Returns true if the gameObject exists
---@return boolean
function ModGameObject.Exists() end


---Sets the texture on the gameobject (Custom meshes only)
---@param textureName string
---@return nil
function ModGameObject.SetTexture(textureName) end


---Add a force to the game object as an impulse. See https://docs.unity3d.com/ScriptReference/ForceMode.html
---@param x number
---@param y number
---@param z number
---@return nil
function ModGameObject.AddForceImpulse(x, y, z) end


---Add a force to the game object as a force. See https://docs.unity3d.com/ScriptReference/ForceMode.html
---@param x number
---@param y number
---@param z number
---@return nil
function ModGameObject.AddForce(x, y, z) end


---Add a force to the game object as an Acceleration. See https://docs.unity3d.com/ScriptReference/ForceMode.html
---@param x number
---@param y number
---@param z number
---@return nil
function ModGameObject.AddForceAcceleration(x, y, z) end


---Add a force to the game object as a VelocityChange. See https://docs.unity3d.com/ScriptReference/ForceMode.html
---@param x number
---@param y number
---@param z number
---@return nil
function ModGameObject.AddForceVelocityChange(x, y, z) end


---Add a torque to the game object as an impulse. See https://docs.unity3d.com/ScriptReference/ForceMode.html
---@param x number
---@param y number
---@param z number
---@return nil
function ModGameObject.AddTorqueImpulse(x, y, z) end


---Add a torque to the game object as a force. See https://docs.unity3d.com/ScriptReference/ForceMode.html
---@param x number
---@param y number
---@param z number
---@return nil
function ModGameObject.AddTorqueForce(x, y, z) end


---Add a torque to the game object as an Acceleration. See https://docs.unity3d.com/ScriptReference/ForceMode.html
---@param x number
---@param y number
---@param z number
---@return nil
function ModGameObject.AddTorqueAcceleration(x, y, z) end


---Add a torque to the game object as a VelocityChange. See https://docs.unity3d.com/ScriptReference/ForceMode.html
---@param x number
---@param y number
---@param z number
---@return nil
function ModGameObject.AddTorqueVelocityChange(x, y, z) end


---Represents a Transform (position, rotation, scale) of a GameObject.
---@class ModTransform
ModTransform = {}

---Sets the position of the transform (world space)
---@param position ModVector3
---@return nil
function ModTransform.SetPosition(position) end


---Sets the position of the transform (world space)
---@param x number
---@param y number
---@param z number
---@return nil
function ModTransform.SetPosition(x, y, z) end


---Gets the position of the transform (world space)
---@return ModVector3
function ModTransform.GetPosition() end


---Sets the rotation of the transform (world space)
---@param rotation ModVector3
---@return nil
function ModTransform.SetRotation(rotation) end


---Sets the rotation of the transform (world space)
---@param x number
---@param y number
---@param z number
---@return nil
function ModTransform.SetRotation(x, y, z) end


---Gets the rotation of the transform (local space)
---@return ModVector3
function ModTransform.GetRotation() end


---Sets the rotation of the transform using a quaternion (world space)
---@param rotation ModQuaternion
---@return nil
function ModTransform.SetRotation(rotation) end


---Gets the rotation quaternions of the transform (world space)
---@return ModQuaternion
function ModTransform.GetRotationQuaternion() end


---Sets the scale of the transform (local space)
---@param scale ModVector3
---@return nil
function ModTransform.SetScale(scale) end


---Sets the scale of the transform (local space). Setting a non-uniform scale may, among other things, break the objects physics.
---@param x number
---@param y number
---@param z number
---@return nil
function ModTransform.SetScale(x, y, z) end


---Sets the scale of the transform (local space)
---@param scale number
---@return nil
function ModTransform.SetScale(scale) end


---Gets the scale of the transform (local space)
---@return ModVector3
function ModTransform.GetScale() end


---Returns the points local position (world space)
---@param point ModVector3
---@return ModVector3
function ModTransform.TransformPoint(point) end


---Returns the directions world space direction
---@param direction ModVector3
---@return ModVector3
function ModTransform.TransformDirection(direction) end


---Returns a normalized vector Forward (world space)
---@return ModVector3
function ModTransform.Forward() end


---Returns a normalized vector Back (world space)
---@return ModVector3
function ModTransform.Back() end


---Returns a normalized vector Left (world space)
---@return ModVector3
function ModTransform.Left() end


---Returns a normalized vector Right (world space)
---@return ModVector3
function ModTransform.Right() end


---Returns a normalized vector Up (world space)
---@return ModVector3
function ModTransform.Up() end


---Returns a normalized vector Down (world space)
---@return ModVector3
function ModTransform.Down() end


---Gets the position of the transform (world space)
---@return ModVector3
function ModTransform.GetPositionWorld() end


---Gets the euler angles rotation of the transform (world space)
---@return ModVector3
function ModTransform.GetEulerAnglesWorld() end


---Gets the quaternion rotation of the transform (world space)
---@return ModQuaternion
function ModTransform.GetRotationWorld() end


---Sets the position of the transform (world space)
---@param position ModVector3
---@return nil
function ModTransform.SetPositionWorld(position) end


---Sets the position of the transform (world space)
---@param x number
---@param y number
---@param z number
---@return nil
function ModTransform.SetPositionWorld(x, y, z) end


---Sets the euler angles rotation of the transform (world space)
---@param eulerAngles ModVector3
---@return nil
function ModTransform.SetEulerAnglesWorld(eulerAngles) end


---Sets the euler angles rotation of the transform (world space)
---@param x number
---@param y number
---@param z number
---@return nil
function ModTransform.SetEulerAnglesWorld(x, y, z) end


---Sets the quaternion rotation of the transform (world space)
---@param rotation ModQuaternion
---@return nil
function ModTransform.SetRotationWorld(rotation) end


---Sets the quaternion rotation of the transform (world space)
---@param x number
---@param y number
---@param z number
---@param w number
---@return nil
function ModTransform.SetRotationWorld(x, y, z, w) end


---Gets the position of the transform (local space)
---@return ModVector3
function ModTransform.GetPositionLocal() end


---Gets the euler angles rotation of the transform (local space)
---@return ModVector3
function ModTransform.GetEulerAnglesLocal() end


---Gets the quaternion rotation of the transform (local space)
---@return ModQuaternion
function ModTransform.GetRotationLocal() end


---Gets the scale of the transform (local space)
---@return ModVector3
function ModTransform.GetScaleLocal() end


---Sets the position of the transform (local space)
---@param position ModVector3
---@return nil
function ModTransform.SetPositionLocal(position) end


---Sets the position of the transform (local space)
---@param x number
---@param y number
---@param z number
---@return nil
function ModTransform.SetPositionLocal(x, y, z) end


---Sets the euler angles rotation of the transform (local space)
---@param eulerAngles ModVector3
---@return nil
function ModTransform.SetEulerAnglesLocal(eulerAngles) end


---Sets the euler angles rotation of the transform (local space)
---@param x number
---@param y number
---@param z number
---@return nil
function ModTransform.SetEulerAnglesLocal(x, y, z) end


---Sets the quaternion rotation of the transform (local space)
---@param rotation ModQuaternion
---@return nil
function ModTransform.SetRotationLocal(rotation) end


---Sets the quaternion rotation of the transform (local space)
---@param x number
---@param y number
---@param z number
---@param w number
---@return nil
function ModTransform.SetRotationLocal(x, y, z, w) end


---Sets the scale of the transform (local space)
---@param scale ModVector3
---@return nil
function ModTransform.SetScaleLocal(scale) end


---Sets the scale of the transform (local space)
---@param x number
---@param y number
---@param z number
---@return nil
function ModTransform.SetScaleLocal(x, y, z) end


---Represents a block in a structure.
---@class ModBlock
ModBlock = {}

---Gets the position of the transform (world space)
---@return ModVector3
function ModBlock.GetPosition() end


---Gets the rotation of the transform (local space)
---@return ModVector3
function ModBlock.GetRotation() end


---Gets the scale of the transform (local space)
---@return ModVector3
function ModBlock.GetScale() end


---Returns the points position in world space
---@param point ModVector3
---@return ModVector3
function ModBlock.TransformPoint(point) end


---Returns the directions world space direction
---@param direction ModVector3
---@return ModVector3
function ModBlock.TransformDirection(direction) end


---Returns a normalized vector Forward in world space
---@return ModVector3
function ModBlock.Forward() end


---Returns a normalized vector Back in world space
---@return ModVector3
function ModBlock.Back() end


---Returns a normalized vector Left in world space
---@return ModVector3
function ModBlock.Left() end


---Returns a normalized vector Right in world space
---@return ModVector3
function ModBlock.Right() end


---Returns a normalized vector Up in world space
---@return ModVector3
function ModBlock.Up() end


---Returns a normalized vector Down in world space
---@return ModVector3
function ModBlock.Down() end


---Get the name of the blocks type
---@return string
function ModBlock.GetName() end


---[DEPRECATED] Use `SetPrimaryColor` instead
---@param r number
---@param g number
---@param b number
---@return nil
function ModBlock.SetColor(r, g, b) end


---Set the blocks primary color
---@param r number
---@param g number
---@param b number
---@return nil
function ModBlock.SetPrimaryColor(r, g, b) end


---Set the blocks primary color
---@param color ModColor
---@return nil
function ModBlock.SetPrimaryColor(color) end


---Set the blocks secondary color
---@param r number
---@param g number
---@param b number
---@return nil
function ModBlock.SetSecondaryColor(r, g, b) end


---Set the blocks secondary color
---@param color ModColor
---@return nil
function ModBlock.SetSecondaryColor(color) end


---[In buildmode only] Set the blocks mass
---@param mass number
---@return nil
function ModBlock.SetMass(mass) end


---Get the blocks mass
---@return number
function ModBlock.GetMass() end


---Get the blocks primary color
---@return ModColor
function ModBlock.GetPrimaryColor() end


---Get the blocks secondary color
---@return ModColor
function ModBlock.GetSecondaryColor() end


---[In buildmode only] Set the blocks buoyancy
---@param buoyancy number
---@return nil
function ModBlock.SetBuoyancy(buoyancy) end


---get the blocks buoyancy
---@return number
function ModBlock.GetBuoyancy() end


---[Deprecated] Use `SetStartHealth` instead
---@param hp number
---@return nil
function ModBlock.SetHealth(hp) end


---Set the blocks start health
---@param hp number
---@return nil
function ModBlock.SetStartHealth(hp) end


---Reset the blocks start health to its original value
---@return nil
function ModBlock.ResetStartHealth() end


---Get the blocks start health
---@return number
function ModBlock.GetStartHealth() end


---Get the blocks full health
---@return number
function ModBlock.GetFullHealth() end


---Fully revives the block to its full health
---@return nil
function ModBlock.Revive() end


---Give damage to a block. 
---@param damageAmount number The amount of damage to deal.
---@param damageDealerPlayerId number The player that dealt the damage, -1 for no player.
---@param damageType ModDamageType The type of damage to deal, defaults to Generic.

---@param damageAmount number
---@param damageDealerPlayerId number
---@param damageType string
---@return nil
function ModBlock.DoDamageAmount(damageAmount, damageDealerPlayerId, damageType) end


---Instant kill the block
---@return nil
function ModBlock.InstantKill() end


---Returns true if the block has been damaged.
---@return boolean
function ModBlock.IsDamaged() end


---Returns true if the block is dead.
---@return boolean
function ModBlock.IsDead() end


---Get the blocks current health
---@return number
function ModBlock.GetCurrentHealth() end


---Get the block health fraction normalised from 0 to its full health
---@return number
function ModBlock.GetHealthFraction() end


---Get the block's BlockMetaData
---@return ModBlockMetaData
function ModBlock.GetBlockMetaData() end


---Manual AerodynamicBox definition
---@class AerodynamicBox
---@field forward number 
---@field back number
---@field up number 
---@field down number
---@field left number 
---@field right number

---Get the drag values of an aerodynamic box
---@return AerodynamicBox
---@param aerodynamicBoxIndex number
---@return Table
function ModBlock.GetDrag(aerodynamicBoxIndex) end


---Get the drag values for all aerodynamic boxes
---@return AerodynamicBox[]
---@return Table
function ModBlock.GetDragAll() end


---Expensive operation! Set the drag values of an aerodynamic box
---@param aerodynamicBoxIndex number
---@param forward number
---@param back number
---@param up number
---@param down number
---@param left number
---@param right number
---@return nil
function ModBlock.SetDrag(aerodynamicBoxIndex, forward, back, up, down, left, right) end


---Expensive operation! Set all of the aerodynamic boxes to the defined drag values
---@param forward number
---@param back number
---@param up number
---@param down number
---@param left number
---@param right number
---@return nil
function ModBlock.SetDragAll(forward, back, up, down, left, right) end


---Reset the drag of a aerodynamic box to default values
---@param aerodynamicBoxIndex number
---@return nil
function ModBlock.ResetDrag(aerodynamicBoxIndex) end


---Reset the drag values of all aerodynamic boxes to default values
---@return nil
function ModBlock.ResetDragAll() end


---Get the default drag values of a aerodynamic box
---@return AerodynamicBox
---@param aerodynamicBoxIndex number
---@return Table
function ModBlock.GetDefaultDrag(aerodynamicBoxIndex) end


---Get the default drag values of all aerodynamic boxex
---@return AerodynamicBox[]
---@return Table
function ModBlock.GetDefaultDragAll() end


---Get number of aerodynamic boxes
---@return number
function ModBlock.GetNumberOfAerodynamicBoxes() end


---Add a force to the given block as an impulse
---@param x number
---@param y number
---@param z number
---@return nil
function ModBlock.AddForce(x, y, z) end


---Add a torque to the given block as an impulse
---@param x number
---@param y number
---@param z number
---@return nil
function ModBlock.AddTorque(x, y, z) end


---Sets Engine power, (only works on engine blocks)
---@param power number
---@return nil
function ModBlock.SetEnginePower(power) end


---Gets Engine power, (only works on engine blocks)
---@return number
function ModBlock.GetEnginePower() end


---Sets Jet power, (only works on jet blocks)
---@param power number
---@return nil
function ModBlock.SetJetPower(power) end


---Gets jet power, (only works on jet blocks)
---@return number
function ModBlock.GetJetPower() end


---Sets Propeller power, (only works on propeller blocks)
---@param power number
---@return nil
function ModBlock.SetPropellerPower(power) end


---Gets propeller power, (only works on propeller blocks)
---@return number
function ModBlock.GetPropellerPower() end


---Sets gyro power, (only works on gyro blocks)
---@param power number
---@return nil
function ModBlock.SetGyroPower(power) end


---Gets gyro power, (only works on gyro blocks)
---@return number
function ModBlock.GetGyroPower() end


---Whether a block is an Engine block or not.
---@return boolean
function ModBlock.IsEngineBlock() end


---Whether a block is an Jet block or not.
---@return boolean
function ModBlock.IsJetBlock() end


---Whether a block is an Propeller block or not.
---@return boolean
function ModBlock.IsPropellerBlock() end


---Whether a block is a seat block or not.
---@return boolean
function ModBlock.IsPlayerSeatBlock() end


---Whether a block is a gyro block or not.
---@return boolean
function ModBlock.IsGyroBlock() end


---Returns true if the block exists. Keep in mind that when you repair your structure, your destroyed blocks will be replaced with different ones, making the old ones useless
---@return boolean
function ModBlock.Exists() end


---Returns structure a block belongs to.
---@return ModStructure
function ModBlock.GetStructure() end


---No description
---@param other ModBlock
---@return boolean
function ModBlock.Equals(other) end


---Represents a Structure
---@class ModStructure
ModStructure = {}

---Gets the position of the transform (world space)
---@return ModVector3
function ModStructure.GetPosition() end


---Gets the rotation of the transform (local space)
---@return ModVector3
function ModStructure.GetRotation() end


---Gets the scale of the transform (local space)
---@return ModVector3
function ModStructure.GetScale() end


---Returns the points position in world space
---@param point ModVector3
---@return ModVector3
function ModStructure.TransformPoint(point) end


---Returns the directions world space direction
---@param direction ModVector3
---@return ModVector3
function ModStructure.TransformDirection(direction) end


---Returns a normalized vector Forward in world space
---@return ModVector3
function ModStructure.Forward() end


---Returns a normalized vector Back in world space
---@return ModVector3
function ModStructure.Back() end


---Returns a normalized vector Left in world space
---@return ModVector3
function ModStructure.Left() end


---Returns a normalized vector Right in world space
---@return ModVector3
function ModStructure.Right() end


---Returns a normalized vector Up in world space
---@return ModVector3
function ModStructure.Up() end


---Returns a normalized vector Down in world space
---@return ModVector3
function ModStructure.Down() end


---Destroy the structure
---@return nil
function ModStructure.Destroy() end


---Gets all blocks in structure
---@return ModBlock[]
function ModStructure.GetBlocks() end


---Add a force to the given structure as an impulse
---@param x number
---@param y number
---@param z number
---@return nil
function ModStructure.AddForce(x, y, z) end


---Gets the velocity of the player inside of the structure in world space.
---@return ModVector3
function ModStructure.GetSeatedPlayerVelocity() end


---Gets the velocity of the structure's center of mass in world space.
---@return ModVector3
function ModStructure.GetVelocity() end


---Gets the speed of the player inside of the structure (m/s).
---@return number
function ModStructure.GetSpeed() end


---Get player index who owns this structure. Returns -1 if player is gone.
---@return number
function ModStructure.GetOwnedByPlayerId() end


---Returns the number of power cores of the structure.
---@return number
function ModStructure.GetPowerCores() end


---Returns the Center of Mass of the structure in world space.
---@return ModVector3
function ModStructure.GetWorldCenterOfMass() end


---No description
---@return nil
function ModStructure.Dispose() end


---Represents a raycast
---@class ModRaycastHit
ModRaycastHit = {}

---Returns if the raycast hit something
---@return boolean
function ModRaycastHit.DidHit() end


---Returns the hit normal
---@return ModVector3
function ModRaycastHit.GetHitNormal() end


---Returns the hit position
---@return ModVector3
function ModRaycastHit.GetHitPosition() end


---Returns the distance to the hit
---@return number
function ModRaycastHit.GetHitDistance() end


---Represents a color
---@class ModColor
ModColor = {}

---No description
---@return ModColor
function ModColor.Create() end


---No description
---@param r number
---@param g number
---@param b number
---@param a number
---@return ModColor
function ModColor.Create(r, g, b, a) end


---No description
---@return string
function ModColor.ToString() end


---Returns the red channel of the ModColor
---@return number
function ModColor.R() end


---Returns the green channel of the ModColor
---@return number
function ModColor.G() end


---Returns the blue channel of the ModColor
---@return number
function ModColor.B() end


---Returns the alpha channel of the ModColor
---@return number
function ModColor.A() end


---Returns a ModColor set to white (1, 1, 1)
---@return ModColor
function ModColor.White() end


---Returns a ModColor set to black (0, 0, 0)
---@return ModColor
function ModColor.Black() end


---Returns a ModColor set to red (1, 0, 0)
---@return ModColor
function ModColor.Red() end


---Returns a ModColor set to green (0, 1, 0)
---@return ModColor
function ModColor.Green() end


---Returns a ModColor set to blue (0, 0, 1)
---@return ModColor
function ModColor.Blue() end


---Returns a ModColor set to yellow (1, 0.92, 0.016)
---@return ModColor
function ModColor.Yellow() end


---Returns a ModColor set to cyan (0, 1, 1)
---@return ModColor
function ModColor.Cyan() end


---Returns a ModColor set to magenta (1, 0, 1)
---@return ModColor
function ModColor.Magenta() end


---Returns a ModColor set to gray (0.5, 0.5, 0.5)
---@return ModColor
function ModColor.Gray() end


---Returns a ModColor set to gray (0, 0, 0, 0)
---@return ModColor
function ModColor.Clear() end


---Linear interpolation between two ModColor
---@param a ModColor
---@param b ModColor
---@param t number
---@return ModColor
function ModColor.Lerp(a, b, t) end


---No description
---@param hue number
---@param saturation number
---@param value number
---@return ModColor
function ModColor.HSVToRGB(hue, saturation, value) end


---No description
---@param first ModColor
---@param second ModColor
---@return boolean
function ModColor.op_Equality(first, second) end


---No description
---@param obj Object
---@return boolean
function ModColor.Equals(obj) end


---No description
---@param first ModColor
---@param second ModColor
---@return boolean
function ModColor.op_Inequality(first, second) end


---No description
---@return number
function ModColor.GetHashCode() end


---Some type and amount of damage that has been dealt by a player at given position and direction
---@class ModDamage
---@field damageType ModDamageType
---@field damageAmount number
---@field damagePosition ModVector3
---@field damageDirection ModVector3
---@field damageDealerPlayer ModPlayer
ModDamage = {}
